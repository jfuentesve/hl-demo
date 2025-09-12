aws ecs describe-services \
  --cluster hl-ecs-cluster \
  --services hl-api-service \
  --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount,status:status,deployments:deployments[*].{id:id,status:status,rollout:rolloutState,desired:desiredCount,running:runningCount}}' \
  --output table