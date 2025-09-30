#!/usr/bin/env bash
set -euo pipefail

############################################
# HL Deals – Frontend build & S3 deployment
############################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_DIR="${SCRIPT_DIR}/hl-web"
DIST_DIR="${UI_DIR}/dist/hl-web/browser"

REGION="${REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
S3_BUCKET="${S3_BUCKET:-hl-deals-web-${ENVIRONMENT}}"

info()  { printf '\033[1;34m[info]\033[0m %s\n' "$*"; }
success(){ printf '\033[1;32m[done]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[error]\033[0m %s\n' "$*"; }

[[ -d "${UI_DIR}" ]] || { error "No se encontró hl-web (buscado en ${UI_DIR})"; exit 1; }
command -v npm >/dev/null || { error "npm no está instalado en PATH"; exit 1; }
command -v aws >/dev/null || { error "AWS CLI no está instalado"; exit 1; }

AWS_ARGS=(--region "${REGION}")
if [[ -n "${AWS_PROFILE:-}" ]]; then
  AWS_ARGS+=(--profile "${AWS_PROFILE}")
fi

info "Instalando dependencias (npm ci)…"
(
  cd "${UI_DIR}"
  npm ci >/dev/null
)
success "Dependencias instaladas"

info "Construyendo Angular (configuración production)…"
(
  cd "${UI_DIR}"
  npm run build -- --configuration production >/dev/null
)
[[ -d "${DIST_DIR}" ]] || { error "No se encontró el build en ${DIST_DIR}"; exit 1; }
success "Build generado en ${DIST_DIR}"

info "Sincronizando assets estáticos a s3://${S3_BUCKET}/"
aws s3 sync "${DIST_DIR}" "s3://${S3_BUCKET}/" \
  "${AWS_ARGS[@]}" \
  --delete \
  --exclude "index.html" \
  --cache-control "public, max-age=31536000, immutable"
success "Assets cargados"

info "Publicando index.html sin caché agresiva"
aws s3 cp "${DIST_DIR}/index.html" "s3://${S3_BUCKET}/index.html" \
  "${AWS_ARGS[@]}" \
  --cache-control "no-cache, no-store, must-revalidate" \
  --content-type "text/html"
success "index.html actualizado"

PUBLIC_URL="http://${S3_BUCKET}.s3-website-${REGION}.amazonaws.com"
cat <<MSG

Despliegue completado.
Bucket : s3://${S3_BUCKET}
Región : ${REGION}
URL    : ${PUBLIC_URL}

MSG
