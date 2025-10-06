# terraform/hl-infra/modules/app_secrets/main.tf

locals {
  secret_name = var.name
}

resource "aws_ssm_parameter" "secret" {
  count = var.use_secrets_manager ? 0 : 1

  name        = local.secret_name
  description = var.description
  type        = "SecureString"
  value       = var.secret_value
  key_id      = var.kms_key_id == "" ? null : var.kms_key_id

  tags = {
    ManagedBy = "terraform"
  }
}

resource "aws_secretsmanager_secret" "secret" {
  count = var.use_secrets_manager ? 1 : 0

  name        = local.secret_name
  description = var.description
  kms_key_id  = var.kms_key_id == "" ? null : var.kms_key_id

  tags = {
    ManagedBy = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "secret" {
  count = var.use_secrets_manager ? 1 : 0

  secret_id     = aws_secretsmanager_secret.secret[0].id
  secret_string = var.secret_value
}

output "identifier" {
  description = "Name or ARN to identify the secret from the application"
  value       = var.use_secrets_manager ? aws_secretsmanager_secret.secret[0].name : aws_ssm_parameter.secret[0].name
}

output "arn" {
  description = "ARN of the underlying secret"
  value       = var.use_secrets_manager ? aws_secretsmanager_secret.secret[0].arn : aws_ssm_parameter.secret[0].arn
}
