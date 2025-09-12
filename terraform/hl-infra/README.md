############################################
# README.md (in repo root)
############################################


# HL Infrastructure (Terraform)


This module provisions AWS infrastructure for the HL Showcase Application. It includes:


- VPC with public and private subnets
- RDS (SQL Server)
- S3 bucket with static website hosting for frontend
- Security Groups


## 🚀 Usage


```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```


## 🔐 Sensitive Info
- Keep your `terraform.tfvars` out of version control.
- Add it to `.gitignore`.


## 📦 Outputs
- `rds_endpoint`: SQL Server endpoint
- `s3_bucket_name`: Frontend hosting bucket
- `vpc_id`, `subnet_ids`: for connecting ECS or Lambda backend


## 📁 Structure
```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── README.md
```


## ✅ Requirements
- Terraform ≥ 1.5
- AWS CLI configured with appropriate access


---