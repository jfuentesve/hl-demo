############################################
# variables.tf (añadidos nuevos)
############################################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "hldeals"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
}

variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "db_connection_string" {
  description = "Full connection string for SQL Server"
  type        = string
}

variable "jwt_key" {
  description = "Secret key used to sign JWT tokens"
  type        = string
  sensitive   = true
}

variable "jwt_issuer" {
  description = "JWT token issuer"
  type        = string
  default     = "hl-api"
}

variable "jwt_audience" {
  description = "JWT token audience"
  type        = string
  default     = "hl-client"
}


variable "major_engine_version" {
  description = "Major engine version of the DB engine (e.g., 15 for SQL Server)"
  type        = string
  default     = "15"
}

variable "family" {
  description = "DB parameter group family (depends on engine type)"
  type        = string
  default     = "sqlserver-se-15.0"
}

variable "license_model" {
  description = "SQL Server License Model"
  type        = string
  default     = "license-included"
}