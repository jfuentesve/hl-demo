#!/usr/bin/env bash
set -euo pipefail


REGION=us-east-1
CLUSTER=hl-ecs-cluster
SERVICE=hl-api-service
CONTAINER=hl-api

RDS_HOST=$(aws rds describe-db-instances --region "$REGION" \
  --db-instance-identifier hl-deals-db-dev \
  --query 'DBInstances[0].Endpoint.Address' --output text)

CONN_STR="Server=tcp:${RDS_HOST},1433;Database=hldeals;User ID=hladmin;Password=***REDACTED***!;Encrypt=True;TrustServerCertificate=True;MultipleActiveResultSets=True;"

TD_ARN=$(aws ecs describe-services --region "$REGION" \
  --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].taskDefinition' --output text)

TD=$(aws ecs describe-task-definition --region "$REGION" \
  --task-definition "$TD_ARN" --query 'taskDefinition' --output json)

NEW=$(echo "$TD" | jq --arg NAME "$CONTAINER" --arg V "$CONN_STR" '
  del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
  | .containerDefinitions = (.containerDefinitions
      | map(if .name==$NAME then
              .environment = (.environment
                | (map(select(.name=="ConnectionStrings__DefaultConnection")) | length) as $has
                | if $has>0 then map(if .name=="ConnectionStrings__DefaultConnection" then .value=$V else . end)
                             else . + [{ "name":"ConnectionStrings__DefaultConnection", "value":$V }] end)
            else . end))
')

NEW_TD_ARN=$(aws ecs register-task-definition --region "$REGION" \
  --cli-input-json "$NEW" --query 'taskDefinition.taskDefinitionArn' --output text)

echo "forzando redeploy… 1"
aws ecs update-service --region "$REGION" \
  --cluster "$CLUSTER" --service "$SERVICE" \
  --task-definition "$NEW_TD_ARN" #>/dev/null


echo "forzando redeploy… 2"
aws ecs update-service --region "$REGION" \
  --cluster "$CLUSTER" --service "$SERVICE" \
  --force-new-deployment #>/dev/null

aws ecs wait services-stable --region "$REGION" --cluster "$CLUSTER" --services "$SERVICE" || true

echo "✅ Servicio actualizado a RDS HOST: $RDS_HOST"
