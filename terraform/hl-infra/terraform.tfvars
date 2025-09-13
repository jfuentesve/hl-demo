aws_region   = "us-east-1"
environment  = "dev"

db_name      = "hldeals"
db_username  = "hladmin"
db_password  =***REDACTED***"StrongP4ssw0rd123!" # ⚠️ Nunca incluir esto en Git

db_connection_string = "Server=hl-deals-db-dev.cav0kksicv9i.us-east-1.rds.amazonaws.com;Database=hldeals;User Id=hladmin;Password=***REDACTED***!;"
jwt_key      = "supersecretkeyforhldevjwt"
jwt_issuer   = "hl-api"
jwt_audience = "hl-client"

major_engine_version = "15"
family               = "sqlserver-se-15.0"

