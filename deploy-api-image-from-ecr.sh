#!/usr/bin/env bash
set -euo pipefail

# =========================
# Defaults (puedes sobreescribir con flags)
# =========================
REGION="us-east-1"
PROFILE=""                     # ej: "juanops" (vacío = default del CLI)
CLUSTER="hl-ecs-cluster"
SERVICE="hl-api-service"
REPO="hl-api"
CONTAINER_NAME="hl-api"        # nombre del contenedor en tu task definition
LOG_GROUP="/ecs/hl-api"        # si tu task usa awslogs
TAIL_LOGS=0                    # --tail para seguir logs al final

usage() {
  cat <<EOF
deploy-api-image-from-ecr.sh - Despliega la última imagen de ECR en ECS

Uso:
  ./deploy-api-image-from-ecr.sh [opciones]

Opciones:
  -r <region>        Región AWS (default: ${REGION})
  -p <profile>       AWS profile del CLI (por defecto el actual)
  -c <cluster>       Nombre del ECS cluster (default: ${CLUSTER})
  -s <service>       Nombre del ECS service (default: ${SERVICE})
  -n <repo>          Nombre del repo ECR (default: ${REPO})
  -k <container>     Nombre del contenedor en la Task Definition (default: ${CONTAINER_NAME})
  --tail             Tail de logs de CloudWatch al final (${LOG_GROUP})

Notas:
- Este script registra una nueva revisión de la Task Definition con la imagen pineda por digest.
- Requiere 'jq' y AWS CLI v2.
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }
die()  { echo "❌ $*" >&2; exit 1; }
info() { echo "➜ $*"; }
ok()   { echo "✅ $*"; }

# Parse flags
while (( "$#" )); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -r) REGION="$2"; shift 2 ;;
    -p) PROFILE="$2"; shift 2 ;;
    -c) CLUSTER="$2"; shift 2 ;;
    -s) SERVICE="$2"; shift 2 ;;
    -n) REPO="$2"; shift 2 ;;
    -k) CONTAINER_NAME="$2"; shift 2 ;;
    --tail) TAIL_LOGS=1; shift ;;
    -t|--tag) TAG="$2"; shift 2 ;;
    *) die "Flag desconocida: $1 (usa -h)";;
  esac
done

have aws || die "AWS CLI no está instalado."
have jq  || die "jq no está instalado (brew install jq)."

AWS_ARGS=(--region "$REGION")
[[ -n "$PROFILE" ]] && AWS_ARGS+=(--profile "$PROFILE")

# 1) Resolver URI del repo y el digest de la imagen 'latest'
info "Obteniendo URI del repo ECR '$REPO'…"
ECR_URI=$(aws ecr describe-repositories --repository-names "$REPO" "${AWS_ARGS[@]}" \
  --query 'repositories[0].repositoryUri' --output text)
[[ -z "$ECR_URI" || "$ECR_URI" == "None" ]] && die "No existe el repo ECR '$REPO'."

if [[ -n "${TAG:-}" ]]; then
  info "Obteniendo digest de la imagen con tag '${TAG}'…"
  DIGEST=$(aws ecr describe-images --repository-name "$REPO" "${AWS_ARGS[@]}" \
    --image-ids imageTag="$TAG" --query 'imageDetails[0].imageDigest' --output text 2>/dev/null || true)
  [[ -z "$DIGEST" || "$DIGEST" == "None" ]] && die "No encontré imagen con tag '${TAG}' en $REPO'."
else
  info "Obteniendo digest de la imagen más reciente…"
  DIGEST=$(aws ecr describe-images --repository-name "$REPO" "${AWS_ARGS[@]}" \
    --query 'reverse(sort_by(imageDetails,& imagePushedAt))[0].imageDigest' --output text)
  [[ -z "$DIGEST" || "$DIGEST" == "None" ]] && die "No hay imágenes en $REPO."
fi

IMAGE_REF="${ECR_URI}@${DIGEST}"
ok "Usando imagen: $IMAGE_REF"

# 2) Obtener Task Definition actual del servicio
info "Leyendo Task Definition del servicio $SERVICE  …"
TASK_DEF_ARN=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" "${AWS_ARGS[@]}" \
  --query 'services[0].taskDefinition' --output text)
[[ -z "$TASK_DEF_ARN" || "$TASK_DEF_ARN" == "None" ]] && die "No pude obtener taskDefinition del servicio (¿existe $SERVICE?)."

# 3) Descargar la Task Definition como JSON base
TD_JSON=$(aws ecs describe-task-definition --task-definition "$TASK_DEF_ARN" "${AWS_ARGS[@]}" \
  --query 'taskDefinition' --output json)

# 4) Limpiar campos no registrables y actualizar la imagen del contenedor
#    - Eliminamos: revision, status, taskDefinitionArn, requiresAttributes, compatibilities, registeredAt, registeredBy
#    - Actualizamos: containerDefinitions[].image (del contenedor CONTAINER_NAME; si no se halla por nombre, se modifica el primero)
TMP_ORIG=$(mktemp)
TMP_NEW=$(mktemp)
echo "$TD_JSON" > "$TMP_ORIG"

# Detectar si existe el contenedor por nombre
HAS_NAME=$(jq --arg n "$CONTAINER_NAME" '[.containerDefinitions[] | select(.name==$n)] | length' "$TMP_ORIG")

if [[ "$HAS_NAME" -gt 0 ]]; then
  JQ_UPDATE='.containerDefinitions |= (map(if .name==$n then .image=$img else . end))'
else
  info "No encontré contenedor '$CONTAINER_NAME' por nombre; actualizaré el primero."
  JQ_UPDATE='.containerDefinitions[0].image=$img'
fi

jq \
  'del(.revision,.status,.taskDefinitionArn,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
   | '"$JQ_UPDATE" \
  --arg n "$CONTAINER_NAME" --arg img "$IMAGE_REF" \
  "$TMP_ORIG" > "$TMP_NEW"

# 5) Registrar nueva revisión de la Task Definition
info "Registrando nueva revisión de Task Definition…"
REGISTER_OUT=$(aws ecs register-task-definition \
  --cli-input-json "file://$TMP_NEW" "${AWS_ARGS[@]}")
NEW_TD_ARN=$(echo "$REGISTER_OUT" | jq -r '.taskDefinition.taskDefinitionArn')
ok "Nueva Task Definition: $NEW_TD_ARN"

# 6) Actualizar el servicio para usar la nueva Task Definition y esperar estable
info "Actualizando servicio $SERVICE a la nueva Task Definition…"
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" \
  --task-definition "$NEW_TD_ARN" "${AWS_ARGS[@]}" >/dev/null

info "Esperando a que el servicio quede STABLE (esto puede tardar)…"
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE" "${AWS_ARGS[@]}"
ok "Servicio estable."

# 7) Resumen rápido
info "Resumen del servicio:"
aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" "${AWS_ARGS[@]}" \
  --query 'services[0].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,taskDef:taskDefinition}' \
  --output table

# 8) Mostrar últimos eventos
info "Últimos eventos:"
aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" "${AWS_ARGS[@]}" \
  --query 'services[0].events[0:10].[createdAt,message]' --output table || true

# 9) Tail de logs (opcional)
if [[ "$TAIL_LOGS" -eq 1 ]]; then
  info "Tail de CloudWatch Logs en ${LOG_GROUP} (Ctrl+C para salir)…"
  # requiere aws-cli v2 con 'logs tail'
  if aws logs help 2>/dev/null | grep -q 'tail'; then
    aws logs tail "$LOG_GROUP" --follow --since 5m "${AWS_ARGS[@]}"
  else
    info "Tu AWS CLI no tiene 'aws logs tail'. Mostrando el stream más reciente:"
    STREAM=$(aws logs describe-log-streams --log-group-name "$LOG_GROUP" "${AWS_ARGS[@]}" \
      --order-by LastEventTime --descending --max-items 1 \
      --query 'logStreams[0].logStreamName' --output text || true)
    if [[ -n "$STREAM" && "$STREAM" != "None" ]]; then
      aws logs get-log-events --log-group-name "$LOG_GROUP" --log-stream-name "$STREAM" \
        --limit 100 --query 'events[*].message' --output text "${AWS_ARGS[@]}"
    else
      info "No hay streams aún; intenta de nuevo en 30–60s."
    fi
  fi
fi

rm -f "$TMP_ORIG" "$TMP_NEW"
ok "Deploy desde ECR a ECS completado."