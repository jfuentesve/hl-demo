# terraform/hl-infra/modules/app_secrets/outputs.tf

output "identifier" {
  description = "Name or ARN to identify the secret from the application"
  value       = var.use_secrets_manager ? aws_secretsmanager_secret.secret[0].name : aws_ssm_parameter.secret[0].name
}

output "arn" {
  description = "ARN of the underlying secret"
  value       = var.use_secrets_manager ? aws_secretsmanager_secret.secret[0].arn : aws_ssm_parameter.secret[0].arn
}
