############################################
# outputs.tf
############################################


output "rds_endpoint" {
  description = "Endpoint of the RDS SQL Server instance"
  value       = module.rds.db_instance_endpoint
}


output "rds_db_name" {
  description = "Name of the RDS database"
  value       = var.db_name
}


output "s3_bucket_name" {
  description = "Name of the S3 bucket used for frontend hosting"
  value       = module.s3_frontend.s3_bucket_id
}


output "vpc_id" {
  description = "VPC ID for reference in backend module"
  value       = module.network.vpc_id
}


output "private_subnet_ids" {
  description = "Private subnet IDs used for RDS and ECS"
  value       = module.network.private_subnets
}


output "public_subnet_ids" {
  description = "Public subnet IDs used for load balancer, if needed"
  value       = module.network.public_subnets
}

output "alb_dns_name" {
  value = aws_lb.api_alb.dns_name
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "api_https_endpoint" {
  value = "https://hl-api.demopitch.click"
}

output "api_alb_zone_id" {
  value = aws_lb.api_alb.zone_id
}

output "frontend_https_endpoint" {
  value = "https://hl-web.demopitch.click"
}

output "secrets_backend" {
  description = "Code for the selected secrets backend (ps or sm)"
  value       = local.secrets_backend_code
}

output "jwt_secret_identifier" {
  description = "Identifier used by the API to locate the JWT secret"
  value       = module.jwt_secret.identifier
}

output "rds_secret_identifier" {
  description = "Identifier used by the API to locate the RDS credentials secret"
  value       = module.rds_credentials_secret.identifier
}
