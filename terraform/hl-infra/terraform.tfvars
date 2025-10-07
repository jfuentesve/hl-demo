aws_region  = "us-east-1"
environment = "dev"

db_name = "hldeals"

jwt_issuer   = "hl-api"
jwt_audience = "hl-client"

major_engine_version = "15"
family               = "sqlserver-se-15.0"

# 🔐 Secrets (db_username, db_password, db_connection_string, jwt_key, etc.) now live in terraform/hl-infra/secrets.auto.tfvars (ignored from VCS).
