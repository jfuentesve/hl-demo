# HL-API: Deal Management System

## Overview

HL-API is a comprehensive ASP.NET Core 8.0 RESTful API for managing business deals. It provides full CRUD operations for deal entities with JWT-based authentication, deployed on AWS infrastructure using modern DevOps practices.

**Production URL**: http://hl-api-alb-1496841054.us-east-1.elb.amazonaws.com

## Technology Stack

### Backend
- **Framework**: ASP.NET Core 8.0
- **ORM**: Entity Framework Core 8.0
- **Authentication**: JWT Bearer Tokens
- **Database**: SQL Server (AWS RDS)
- **Documentation**: Swagger/OpenAPI

### Infrastructure & DevOps
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: AWS ECS Fargate
- **Infrastructure as Code**: Terraform
- **Load Balancing**: AWS ALB
- **Container Registry**: Amazon ECR
- **Networking**: AWS VPC with private/public subnets

### Security
- **Password Hashing**: BCrypt.Net-Next
- **CORS**: Configured for cross-origin requests
- **HTTPS**: Enforced on production

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   AWS ALB       │    │   AWS ECS        │    │   AWS RDS       │
│   (Port 80)     │────│   Fargate Task   │────│   SQL Server    │
│                 │    │   (hl-api)       │    │   Database      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                         │                        │
         │                         │                        │
         ▼                         ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Internet      │    │   Containerized  │    │   Relational    │
│   Clients       │    │   .NET Core API  │    │   Database      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Key Components

#### API Layer
- **Controllers**: RESTful endpoints with proper HTTP methods
- **Authentication**: JWT token-based security
- **Authorization**: Role-based access control
- **Health Checks**: `/healthz` endpoint for load balancer

#### Data Layer
- **Entity Framework**: Database access and migrations
- **SQL Server**: Relational data persistence
- **Connection Pooling**: Efficient database connections

#### Infrastructure Layer
- **Docker**: Containerization for consistent deployment
- **ECR**: Private container registry
- **ECS Fargate**: Serverless container orchestration
- **RDS**: Managed SQL Server database

## Project Structure

```
firstDemo/
├── hl-api/                    # ASP.NET Core API Project
│   ├── Controllers/
│   │   ├── AuthController.cs      # JWT Authentication
│   │   └── DealsController.cs     # Deal CRUD Operations
│   ├── Data/
│   │   └── AppDbContext.cs        # EF Core Database Context
│   ├── Dtos/
│   │   ├── DealDto.cs            # Response Data Transfer Objects
│   │   ├── DealCreateDto.cs      # Create Request DTO
│   │   └── DealUpdateDto.cs      # Update Request DTO
│   ├── Models/
│   │   └── Deal.cs               # Domain Model
│   ├── Services/
│   │   ├── JwtOptions.cs         # JWT Configuration
│   │   └── TokenService.cs       # JWT Token Generation
│   ├── .dockerignore             # Docker ignore configuration
│   ├── appsettings.json          # Application settings
│   ├── Dockerfile                # Multi-stage container build
│   ├── Dockerfile.runtime        # Runtime-only container
│   └── HLApi.csproj              # Project configuration
├── terraform/
│   └── hl-infra/                 # Infrastructure as Code
│       ├── main.tf               # Primary infrastructure config
│       ├── variables.tf          # Terraform variables
│       ├── terraform.tfvars      # Variable values
│       ├── outputs.tf            # Infrastructure outputs
│       └── README.md             # Infrastructure documentation
├── postman/                      # API Testing Collections
│   ├── HL-API-Deals.postman_collection.json
│   └── HL-API-Local.postman_environment.json
├── .gitignore                    # Git ignore rules
├── build-push-local.sh           # Local build and push script
├── deploy-api-image-from-ecr.sh  # Deployment automation
├── dotnet-install.sh             # .NET SDK installer
├── firstDemo.sln                 # Solution file
├── is-api-running.sh             # Health check script
├── jwt-key-setup.sh              # JWT key configuration
├── login.json                    # Docker registry credentials
├── push-api.sh                   # Docker push automation
└── rds-db-url-updater.sh         # Database URL update script
```

## API Endpoints

### Authentication
```
POST /api/auth/login
```

**Request Body:**
```json
{
  "username": "admin",
  "password": "ChangeMe123!"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Deals Management (Requires Authentication)

```
GET    /api/deals          # Get all deals
GET    /api/deals/{id}     # Get deal by ID
POST   /api/deals          # Create new deal
PUT    /api/deals/{id}     # Update deal
DELETE /api/deals/{id}     # Delete deal
```

**Authentication:**
Include JWT token in `Authorization` header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Deal Schema:**
```json
{
  "id": 1,
  "name": "Enterprise Software Deal",
  "client": "TechCorp Inc.",
  "amount": 150000.00,
  "createdAt": "2025-09-13T12:00:00Z"
}
```

**Create/Update Deal Request:**
```json
{
  "name": "Enterprise Software Deal",
  "client": "TechCorp Inc.",
  "amount": 150000.00
}
```

### Health Check
```
GET /healthz
```
Returns `"ok"` when API is healthy.

## Database Schema

### Deal Table
```sql
CREATE TABLE [Deals] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max) NULL,
    [Client] nvarchar(max) NULL,
    [Amount] decimal(18,2) NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Deals] PRIMARY KEY ([Id])
)
```

## Configuration

### Application Settings (appsettings.json)
```json
{
  "Jwt": {
    "Key": "ReplaceThisWithAStrongSecretKey123!",
    "Issuer": "hl-api",
    "Audience": "hl-client"
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=...your-connection-string..."
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### Environment Variables (Production)
```bash
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:8080
ConnectionStrings__DefaultConnection=your-rds-connection-string
Jwt__Key=your-strong-jwt-secret
Jwt__Issuer=hl-api
Jwt__Audience=hl-client
```

## Development Setup

### Prerequisites
- .NET 8.0 SDK
- Docker
- Git
- AWS CLI (for deployment)
- Terraform (for infrastructure)

### Local Development

1. **Clone and Setup:**
```bash
git clone <repository-url>
cd firstDemo
```

2. **Install Dependencies:**
```bash
cd hl-api
dotnet restore
```

3. **Run Locally:**
```bash
dotnet run --environment Development
```

The API will be available at `https://localhost:5001`

4. **Swagger Documentation:**
Navigate to `https://localhost:5001/swagger` for interactive API documentation.

### Docker Development

1. **Build Image:**
```bash
cd hl-api
docker build -t hl-api:latest -f Dockerfile .
```

2. **Run Container:**
```bash
docker run -p 8080:8080 hl-api:latest
```

## Infrastructure Deployment

### AWS Resources Created by Terraform

- **VPC**: Virtual Private Cloud with public/private subnets
- **RDS**: SQL Server database instance
- **ECS**: Container orchestration service
- **ALB**: Application Load Balancer
- **ECR**: Elastic Container Registry
- **S3**: Static website hosting
- **Security Groups**: Network access rules

### Infrastructure Modules

#### Network Module
- 2 Availability Zones (us-east-1a, us-east-1b)
- Public subnets for load balancer
- Private subnets for RDS and ECS tasks
- NAT Gateway for outbound traffic

#### Database Module
- SQL Server Express Edition
- t3.micro instance class
- 20GB initial storage, auto-scaling to 100GB
- Private networking only

#### Compute Module
- ECS Fargate cluster
- Serverless container execution
- Auto-scaling configuration
- CloudWatch logs integration

#### Load Balancing
- Application Load Balancer with HTTP
- Health checks on `/healthz` endpoint
- Target group for ECS tasks

### Deploying to AWS

1. **Initialize Infrastructure:**
```bash
cd terraform/hl-infra
terraform init
terraform plan
terraform apply
```

2. **Build and Push Docker Image:**
```bash
cd hl-api
docker build -t hl-api .
docker tag hl-api:latest YOUR_ECR_URI:latest
docker push YOUR_ECR_URI:latest
```

3. **Update ECS Service:**
The service automatically deploys the new image version via CI/CD pipelines or manual update.

### Infrastructure Configuration Files

Location: `terraform/hl-infra/`
- `main.tf` - Primary infrastructure definition
- `variables.tf` - Input variables
- `terraform.tfvars` - Variable values (sensitive data)
- `outputs.tf` - Output values for other systems

## Automation Scripts

### Build & Deploy Scripts
- `build-push-local.sh` - Build Docker image and push to registry
- `deploy-api-image-from-ecr.sh` - Deploy new image to ECS
- `push-api.sh` - Push Docker image to ECR

### Utility Scripts
- `is-api-running.sh` - Check API health
- `jwt-key-setup.sh` - Generate JWT secrets
- `rds-db-url-updater.sh` - Update database connection strings

### Example Usage:
```bash
# Check if API is running
./is-api-running.sh

# Build and deploy new version
./build-push-local.sh
./deploy-api-image-from-ecr.sh
```

## Monitoring & Logging

### CloudWatch Logs
- ECS container logs available in `/ecs/hl-api` log group
- Application logs with structured logging
- 7-day log retention

### Health Monitoring
- ALB health checks on `/healthz`
- Automatic replacement of unhealthy containers
- CloudWatch alarms for infrastructure metrics

## Security Features

### Authentication
- JWT Bearer token validation
- 1-hour token expiration
- Secure token storage recommendations

### Network Security
- Private subnets for database and compute resources
- Security groups with minimal required access
- No public access to RDS or ECS tasks

### Best Practices
- Password hashing with BCrypt
- HTTPS enforcement in production
- Secret management via environment variables

## API Testing

### Postman Collections
Located in `postman/` directory:
- `HL-API-Deals.postman_collection.json` - Complete API test suite
- `HL-API-Local.postman_environment.json` - Local environment variables

### Manual Testing
```bash
# Get JWT token
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"ChangeMe123!"}'

# Use token to access protected endpoints
curl -X GET http://localhost:8080/api/deals \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Performance Considerations

### Database Optimization
- Connection pooling in EF Core
- Asynchronous database operations
- Proper indexing on query columns

### Container Performance
- Fargate task sizing (512 CPU, 1024 MB RAM)
- Multi-stage Docker builds for smaller images
- Health checks for graceful shutdowns

## Troubleshooting

### Common Issues

1. **Database Connection Timeout**
   - Check VPC security group rules
   - Verify subnet configurations
   - Ensure DB instance is running

2. **Load Balancer 502 Errors**
   - Check ECS task health checks
   - Review container logs in CloudWatch
   - Verify target group configuration

3. **JWT Authentication Failures**
   - Verify JWT configuration matches settings
   - Check token expiration
   - Validate token format and claims

## Future Enhancements

### Planned Features
- **Pagination** for large deal collections
- **API Versioning** for backward compatibility
- **Rate Limiting** for API protection
- **Caching** layer with Redis
- **API Gateway** for microservices expansion

### Infrastructure Improvements
- **HTTPS Certificate** via AWS ACM
- **Auto Scaling** based on CPU/memory usage
- **Multi-region** deployment for HA
- **Monitoring Dashboard** with CloudWatch insights

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following established patterns
4. Add/update relevant tests
5. Submit a pull request with detailed description

## License

[Specify license here]

## Contact

For questions or support, contact:
- **Project Lead**: [Contact Information]
- **DevOps Team**: [Contact Information]
- **Security Issues**: [Security Contact]

---

**Last Updated**: September 2025
**Version**: 1.0.0
**Environment**: AWS Production
