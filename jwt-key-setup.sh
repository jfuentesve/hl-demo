#!/usr/bin/env bash
set -euo pipefail

REGION=us-east-1
CLUSTER=hl-ecs-cluster
SERVICE=hl-api-service
CONTAINER=hl-api

# Pega tu nueva clave aquí:
JWT_KEY=$(openssl rand -base64 32)
echo "$JWT_KEY"

TD_ARN=$(aws ecs describe-services --region "$REGION" \
  --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].taskDefinition' --output text)

echo "TD_ARN: $TD_ARN"

TD=$(aws ecs describe-task-definition --region "$REGION" \
  --task-definition "$TD_ARN" --query 'taskDefinition' --output json)

echo "TD: $TD" ##| jq . >/dev/null  

NEW=$(echo "$TD" | jq --arg K "$JWT_KEY" --arg NAME "$CONTAINER" '
  del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
  | .containerDefinitions = (.containerDefinitions
      | map(if .name==$NAME then
              .environment = (.environment
                | (map(select(.name=="Jwt__Key")) | length) as $has
                | if $has>0
                    then map(if .name=="Jwt__Key" then .value=$K else . end)
                    else . + [{ "name":"Jwt__Key", "value":$K }]
                  end)
            else . end))
')


echo "NEW: $NEW" #| jq . >/dev/null

NEW_TD_ARN=$(aws ecs register-task-definition --region "$REGION" \
  --cli-input-json "$NEW" --query 'taskDefinition.taskDefinitionArn' --output text)

echo "NEW_TD_ARN: $NEW_TD_ARN"

echo "Forzando redeploy… 1"
aws ecs update-service --region "$REGION" \
  --cluster "$CLUSTER" --service "$SERVICE" \
  --task-definition "$NEW_TD_ARN" #>/dev/null

echo "Forzando redeploy… 2"

aws ecs update-service --region "$REGION" \
  --cluster "$CLUSTER" --service "$SERVICE" \
  --force-new-deployment #>/dev/null

echo "Forzando redeploy… 2"

aws ecs wait services-stable --region "$REGION" \
  --cluster "$CLUSTER" --services "$SERVICE" || true

echo "✅ Servicio actualizado a TD: $NEW_TD_ARN"