aws_region   = "us-east-1"
environment  = "dev"

db_name      = "hldeals"
db_username  = "hladmin"
db_password  =***REDACTED***"StrongP4ssw0rd123!" # ⚠️ Nunca incluir esto en Git

db_connection_string = "Server=hl-deals-db-dev.cav0kksicv9i.us-east-1.rds.amazonaws.com,1433;Database=hldeals;User Id=hladmin;Password=***REDACTED***!;TrustServerCertificate=True;MultipleActiveResultSets=True;Encrypt=False"

jwt_key      = "your-super-secure-jwt-signing-key-32chars-minimum!"
jwt_issuer   = "hl-api"
jwt_audience = "hl-client"

major_engine_version = "15"
family               = "sqlserver-se-15.0"

