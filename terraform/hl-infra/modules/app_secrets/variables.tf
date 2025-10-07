# terraform/hl-infra/modules/app_secrets/variables.tf

variable "name" {
  description = "Base name for the secret"
  type        = string
}

variable "description" {
  description = "Description for the secret"
  type        = string
  default     = ""
}

variable "secret_value" {
  description = "Secret value to store"
  type        = string
  sensitive   = true
}

variable "use_secrets_manager" {
  description = "If true, create AWS Secrets Manager secret instead of SSM parameter"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "Optional KMS key for encryption"
  type        = string
  default     = ""
}
