#!/usr/bin/env bash
set -euo pipefail

# ====== Config por defecto (puedes exportar estas vars antes de correr) ======
REGION="${REGION:-us-east-1}"
REPO="${REPO:-hl-api}"
CLUSTER="${CLUSTER:-hl-ecs-cluster}"
SERVICE="${SERVICE:-hl-api-service}"
CONTAINER_NAME="${CONTAINER_NAME:-hl-api}"

# ====== Rutas independientes del cwd ======
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="${SCRIPT_DIR}/hl-api"
DOCKERFILE="${API_DIR}/Dockerfile.runtime"
PUBLISH_DIR="${API_DIR}/publish/linux-x64"

# ====== Validaciones rápidas ======
[[ -d "$API_DIR" ]] || { echo "❌ No existe ${API_DIR}"; exit 1; }
[[ -s "$DOCKERFILE" ]] || { echo "❌ Falta o está vacío ${DOCKERFILE}"; exit 1; }
[[ -d "$PUBLISH_DIR" ]] || {
  echo "❌ Falta ${PUBLISH_DIR}."
  echo "   Corre primero:"
  echo "     (cd hl-api && dotnet restore -r linux-x64 -v minimal && dotnet publish -c Release -r linux-x64 --no-self-contained -o ./publish/linux-x64)"
  exit 1
}

# ====== ECR: resolver repo y login ======
ECR_URI="$(aws ecr describe-repositories --region "$REGION" --repository-names "$REPO" \
  --query 'repositories[0].repositoryUri' --output text 2>/dev/null || true)"
if [[ -z "$ECR_URI" || "$ECR_URI" == "None" ]]; then
  aws ecr create-repository --region "$REGION" --repository-name "$REPO" >/dev/null
  ECR_URI="$(aws ecr describe-repositories --region "$REGION" --repository-names "$REPO" \
    --query 'repositories[0].repositoryUri' --output text)"
fi

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "${ECR_URI%%/*}" >/dev/null
echo "✅ Login ECR ok: $ECR_URI"

# ====== Buildx (runtime-only) y push ======
TAG="${TAG:-$(date +%Y%m%d-%H%M%S)}"
IMAGE="${ECR_URI}:${TAG}"

docker buildx create --use >/dev/null 2>&1 || true
BUILDKIT_PROGRESS=plain docker buildx build \
  --platform linux/amd64 \
  -t "$IMAGE" \
  -f "$DOCKERFILE" \
  "$API_DIR" \
  --push

echo "✅ Imagen publicada: $IMAGE"

# ====== Actualizar la Task Definition en ECS ======
command -v jq >/dev/null || { echo "❌ Falta jq (instálalo)"; exit 1; }

TD_ARN="$(aws ecs describe-services --region "$REGION" \
  --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].taskDefinition' --output text)"

TD_JSON="$(aws ecs describe-task-definition --region "$REGION" \
  --task-definition "$TD_ARN" --query 'taskDefinition' --output json)"

NEW_TD_JSON="$(jq --arg IMG "$IMAGE" --arg NAME "$CONTAINER_NAME" '
  del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
  | .containerDefinitions = (.containerDefinitions
      | (map(select(.name==$NAME)) | length) as $has
      | if $has>0
          then map(if .name==$NAME then .image=$IMG else . end)
          else (.[0].image=$IMG)
        end)
' <<<"$TD_JSON")"

NEW_TD_ARN="$(aws ecs register-task-definition --region "$REGION" \
  --cli-input-json "$NEW_TD_JSON" \
  --query 'taskDefinition.taskDefinitionArn' --output text)"

aws ecs update-service --region "$REGION" \
  --cluster "$CLUSTER" --service "$SERVICE" \
  --task-definition "$NEW_TD_ARN" >/dev/null

echo "✅ Servicio actualizado a TD: $NEW_TD_ARN"
