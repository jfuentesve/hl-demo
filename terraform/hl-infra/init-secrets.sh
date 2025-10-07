#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_FILE="$(dirname "$0")/secrets.auto.tfvars.template"
TARGET_FILE="$(dirname "$0")/secrets.auto.tfvars"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Template file $TEMPLATE_FILE not found" >&2
  exit 1
fi

if [[ -f "$TARGET_FILE" ]]; then
  echo "Secrets file already exists at $TARGET_FILE. Skipping copy."
else
  cp "$TEMPLATE_FILE" "$TARGET_FILE"
  echo "Copied template to $TARGET_FILE"
fi

echo "Update $TARGET_FILE with real secret values before running terraform apply."
