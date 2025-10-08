aws_region  = "us-east-1"
environment = "dev"

codepipeline_github_connection_arn = "arn:aws:codeconnections:us-east-1:144776104140:connection/107b6b8d-2d15-4022-bc13-e69a3af5131d" # jmcalydar-gh-conn
codepipeline_github_repo           = "jmcalydar/firstDemo"

db_name = "hldeals"

jwt_issuer   = "hl-api"
jwt_audience = "hl-client"

major_engine_version = "15"
family               = "sqlserver-se-15.0"

# 🔐 Secrets (db_username, db_password, db_connection_string, jwt_key, etc.) now live in terraform/hl-infra/secrets.auto.tfvars (ignored from VCS).
