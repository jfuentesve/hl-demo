#!/usr/bin/env bash
set -euo pipefail

############################################
# Defaults (puedes cambiarlos aquí o vía flags)
############################################
REGION="us-east-1"
PROFILE=""                  # ej: "default" o "juanops" (vacío = por defecto del AWS CLI)
CLUSTER="hl-ecs-cluster"
SERVICE="hl-api-service"
REPO="hl-api"
API_DIR="hl-api"            # carpeta del backend con el Dockerfile
LOG_GROUP="/ecs/hl-api"     # si configuraste awslogs en la Task Definition
TAIL_LOGS=0                 # 1 = tail logs al final
TEMP_DOCKER_CONFIG=0        # 1 = usar DOCKER_CONFIG temporal para saltar el keychain

############################################
# Helpers
############################################
usage() {
  cat <<EOF
push-api - build, push a ECR y redeploy ECS

USO:
  ./push-api [opciones]

Opciones:
  -r <region>        Región AWS (default: ${REGION})
  -p <profile>       AWS profile (por defecto el del CLI)
  -c <cluster>       Nombre del ECS cluster (default: ${CLUSTER})
  -s <service>       Nombre del ECS service (default: ${SERVICE})
  -n <repo>          Nombre del repo en ECR (default: ${REPO})
  -d <dir>           Directorio del backend (default: ${API_DIR})
  --tail             Hace tail de CloudWatch Logs del grupo ${LOG_GROUP}
  --temp-docker-config  Usa DOCKER_CONFIG temporal (workaround credstore)

Ejemplos:
  ./push-api
  ./push-api -p juanops -r us-east-1 --tail
  ./push-api -n hl-api -d hl-api --temp-docker-config
EOF
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

die() { echo "❌ $*" >&2; exit 1; }
info() { echo "➜ $*"; }
ok()   { echo "✅ $*"; }

############################################
# Parse flags
############################################
while (( "$#" )); do
  case "${1}" in
    -h|--help) usage; exit 0 ;;
    -r) REGION="${2}"; shift 2 ;;
    -p) PROFILE="${2}"; shift 2 ;;
    -c) CLUSTER="${2}"; shift 2 ;;
    -s) SERVICE="${2}"; shift 2 ;;
    -n) REPO="${2}"; shift 2 ;;
    -d) API_DIR="${2}"; shift 2 ;;
    --tail) TAIL_LOGS=1; shift ;;
    --temp-docker-config) TEMP_DOCKER_CONFIG=1; shift ;;
    *) die "Flag desconocida: ${1} (usa -h para ayuda)" ;;
  esac
done

############################################
# Pre-checks
############################################
have_cmd aws    || die "AWS CLI no está instalado."
have_cmd docker || die "Docker no está instalado."
have_cmd awk    || die "awk no disponible."
have_cmd sed    || die "sed no disponible."

# Docker daemon
if ! docker info >/dev/null 2>&1; then
  die "Docker daemon no está corriendo. Abre Docker Desktop y espera que esté 'running'."
fi

# API dir
[[ -d "${API_DIR}" ]] || die "No existe el directorio ${API_DIR}. Ejecuta este script desde la raíz del repo (arriba de ${API_DIR})."
[[ -f "${API_DIR}/Dockerfile" ]] || die "No encuentro ${API_DIR}/Dockerfile."

AWS_ARGS=(--region "${REGION}")
[[ -n "${PROFILE}" ]] && AWS_ARGS+=(--profile "${PROFILE}")

############################################
# Resolver URI de ECR
############################################
info "Obteniendo URI del repo ECR '${REPO}' en ${REGION} ..."
set +e
ECR_URI=$(aws ecr describe-repositories --repository-names "${REPO}" "${AWS_ARGS[@]}" \
  --query 'repositories[0].repositoryUri' --output text 2>/dev/null)
set -e
if [[ -z "${ECR_URI}" || "${ECR_URI}" == "None" ]]; then
  info "Repo ECR '${REPO}' no existe. Creándolo..."
  aws ecr create-repository --repository-name "${REPO}" "${AWS_ARGS[@]}" >/dev/null
  ECR_URI=$(aws ecr describe-repositories --repository-names "${REPO}" "${AWS_ARGS[@]}" \
    --query 'repositories[0].repositoryUri' --output text)
fi
ok "ECR_URI = ${ECR_URI}"

REGISTRY_HOST="$(echo "${ECR_URI}" | awk -F/ '{print $1}')"

############################################
# Login a ECR
############################################
if [[ "${TEMP_DOCKER_CONFIG}" -eq 1 ]]; then
  info "Usando DOCKER_CONFIG temporal para evitar credstore issues..."
  export DOCKER_CONFIG
  DOCKER_CONFIG="$(mktemp -d)"
fi

info "Haciendo login a ${REGISTRY_HOST} ..."
aws ecr get-login-password "${AWS_ARGS[@]}" \
  | docker login --username AWS --password-stdin "${REGISTRY_HOST}" >/dev/null
ok "Login a ECR ok."

############################################
# Build & push (linux/amd64 con buildx)
############################################
# Detectar mutabilidad del repo y resolver TAG *antes* de construir
MUTABILITY=$(aws ecr describe-repositories --repository-names "${REPO}" "${AWS_ARGS[@]}" \
  --query 'repositories[0].imageTagMutability' --output text 2>/dev/null || echo "MUTABLE")

if [[ -z "${TAG:-}" ]]; then
  if [[ "${MUTABILITY}" == "IMMUTABLE" ]]; then
    TAG="$(date +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD 2>/dev/null || echo local)"
    info "Repo IMMUTABLE: usando tag autogenerado ${TAG}"
  else
    TAG="latest"
    info "Repo MUTABLE: usando tag ${TAG}"
  fi
fi

IMAGE="${ECR_URI}:${TAG}"

# Asegurar builder y compilar para amd64 (evita el 'exec format error' en Fargate x86_64)
info "Construyendo y subiendo imagen (linux/amd64) -> ${IMAGE}"
docker buildx inspect hlbuilder >/dev/null 2>&1 || docker buildx create --use --name hlbuilder
docker buildx inspect hlbuilder --bootstrap >/dev/null


info "Construyendo y subiendo imagen (linux/amd64) -> ${IMAGE}"
docker buildx build \
  --platform linux/amd64 \
  --progress=plain \
  --cache-from=type=registry,ref="${ECR_URI}:buildcache" \
  --cache-to=type=registry,ref="${ECR_URI}:buildcache",mode=max \
  -t "${IMAGE}" \
  -f "${API_DIR}/Dockerfile" "${API_DIR}" \
  --push

ok "Imagen publicada en ECR con tag=${TAG}"
echo "${TAG}" > .last-image-tag



############################################
# Actualizar Task Definition al nuevo digest y desplegar
############################################

have_cmd jq || die "jq no está instalado (brew install jq / choco install jq)."

CONTAINER_NAME="${CONTAINER_NAME:-hl-api}"   # nombre del contenedor dentro de la TD

# 1) Obtener el digest (sha256) de la imagen que acabamos de pushear
info "Obteniendo digest del tag recien publicado (${TAG}) ..."
DIGEST=$(aws ecr describe-images \
  --repository-name "${REPO}" \
  --image-ids imageTag="${TAG}" \
  "${AWS_ARGS[@]}" \
  --query 'imageDetails[0].imageDigest' --output text)

[[ -z "${DIGEST}" || "${DIGEST}" == "None" ]] && die "No pude resolver el digest en ECR para ${REPO}:${TAG}"

IMAGE_WITH_DIGEST="${ECR_URI}@${DIGEST}"
ok "Usando imagen: ${IMAGE_WITH_DIGEST}"

# 2) Clonar la Task Definition actual y reemplazar la imagen del contenedor
info "Leyendo Task Definition actual del servicio ${SERVICE} ..."
CURRENT_TD_ARN=$(aws ecs describe-services \
  --cluster "${CLUSTER}" --services "${SERVICE}" "${AWS_ARGS[@]}" \
  --query 'services[0].taskDefinition' --output text)

TD_JSON=$(aws ecs describe-task-definition \
  --task-definition "${CURRENT_TD_ARN}" "${AWS_ARGS[@]}" \
  --query 'taskDefinition' --output json)

# Limpiar campos no permitidos y actualizar la imagen del contenedor indicado
NEW_TD_JSON=$(echo "${TD_JSON}" | jq \
  --arg IMG "${IMAGE_WITH_DIGEST}" \
  --arg NAME "${CONTAINER_NAME}" '
    del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
    | .containerDefinitions = (
        .containerDefinitions
        | (map(select(.name == $NAME)) | length) as $has
        | if $has > 0
            then map(if .name == $NAME then .image = $IMG else . end)
            else (.[0].image = $IMG) # fallback: primer contenedor
          end
      )
  ')

# 3) Registrar nueva revisión de la TD
info "Registrando nueva Task Definition ..."
NEW_TD_ARN=$(aws ecs register-task-definition \
  --cli-input-json "${NEW_TD_JSON}" "${AWS_ARGS[@]}" \
  --query 'taskDefinition.taskDefinitionArn' --output text)

ok "Nueva Task Definition: ${NEW_TD_ARN}"

# 4) Actualizar el servicio para usar la nueva TD
info "Actualizando servicio ${SERVICE} a la nueva Task Definition ..."
aws ecs update-service \
  --cluster "${CLUSTER}" \
  --service "${SERVICE}" \
  --task-definition "${NEW_TD_ARN}" \
  "${AWS_ARGS[@]}" >/dev/null

# (Opcional) Forzar rollout y esperar estable
info "Forzando nuevo deployment y esperando a STABLE (puede tardar) ..."
aws ecs update-service \
  --cluster "${CLUSTER}" \
  --service "${SERVICE}" \
  --force-new-deployment \
  "${AWS_ARGS[@]}" >/dev/null

# Esperar a estable (timeout interno del waiter ~10 min). Si prefieres no esperar, comenta esta línea.
aws ecs wait services-stable --cluster "${CLUSTER}" --services "${SERVICE}" "${AWS_ARGS[@]}" \
  && ok "Servicio estable." \
  || info "Waiter terminó sin éxito, pero el despliegue puede seguir avanzando en segundo plano."


# ############################################
# # Redeploy ECS service
# ############################################
# info "Forzando nuevo deployment en ECS (${CLUSTER}/${SERVICE}) ..."
# aws ecs update-service \
#   --cluster "${CLUSTER}" \
#   --service "${SERVICE}" \
#   --force-new-deployment \
#   "${AWS_ARGS[@]}" >/dev/null
# ok "Deployment solicitado."

############################################
# Tail logs (opcional)
############################################
if [[ "${TAIL_LOGS}" -eq 1 ]]; then
  info "Esperando logs de CloudWatch en ${LOG_GROUP} (Ctrl+C para salir)..."
  if have_cmd aws; then
    # aws logs tail requiere AWS CLI v2 reciente
    if aws logs help 2>/dev/null | grep -q 'tail'; then
      aws logs tail "${LOG_GROUP}" --follow --since 5m "${AWS_ARGS[@]}"
    else
      info "Tu AWS CLI no tiene 'aws logs tail'. Mostrando el último stream:"
      STREAM=$(aws logs describe-log-streams --log-group-name "${LOG_GROUP}" \
                  --order-by LastEventTime --descending --max-items 1 \
                  --query 'logStreams[0].logStreamName' --output text "${AWS_ARGS[@]}" || true)
      if [[ -n "${STREAM}" && "${STREAM}" != "None" ]]; then
        aws logs get-log-events --log-group-name "${LOG_GROUP}" --log-stream-name "${STREAM}" \
          --limit 100 --query 'events[*].message' --output text "${AWS_ARGS[@]}"
      else
        info "Aún no hay streams. Intenta de nuevo en 30-60s."
      fi
    fi
  fi
fi

ok "Todo listo. Imagen desplegada y servicio actualizado."
