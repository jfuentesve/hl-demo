# HL Deals – Technical Blueprint (v2, revised, US English)

> Status: **MVP-ready**  
> Last updated: 2025-09-20  
> Scope: **SPA frontend + .NET 8 API on ECS Fargate + RDS (SQL Server)**, IaC via **Terraform**, CI/CD via **GitHub Actions** (OIDC to AWS).  
> Goal: **Professional demo** showcasing security, observability, and cost discipline with ≤ **$10/month per environment** (dev/stg/prod).

---

## 0) Key decisions (confirmed)
- **Domain & TLS**: Subdomain with **ACM (us-east-1)**, ALB listener **:443**, **80→443** redirect, **HSTS**.
- **RBAC**: `viewer`, `user`, `admin` (see Authorization Policy).
- **Tokens**: **RS256** (private key in **Secrets Manager** with **KMS**); **refresh tokens** with rotation and revocation.
- **SLOs (MVP)**: **99%** availability, latency **P50/P90** targets (below), **RTO 1h**, **RPO 1 day**.
- **Cost**: ≤ $10/month per environment.
- **Backups**: RDS **daily**, retention **10 days**, **restore drills** **quarterly** (monthly is also fine; quarterly fits a demo).
- **Rate limit (public API)**: **1,000 req/day** per client (demo/anti-abuse).
- **Admin**: No IP allow-list; **bastion** host for DB administration.
- **i18n**: **EN/ES** in MVP; additional languages in **roadmap**.
- **CI/CD**: **GitHub Actions** + **OIDC** to AWS (no static AWS keys in GitHub).

---

## 1) Requirements

### 1.1 Functional (MVP)
- **Authentication** with RS256 JWT and **role-based authorization**: `viewer` (read-only), `user` (limited CRUD), `admin` (full management).
- **Deals CRUD** with **pagination**, **filtering**, and **sorting**.
- **Views**: table + detail; **public landing** without sensitive data.
- **i18n** EN/ES. Accessibility **WCAG AA**.
- **API v1** documented via **OpenAPI** with sample payloads and error contracts.

### 1.2 Non-functional
- **Availability SLO**: 99% (monthly).
- **Latency targets** (ALB → 200 OK): **P50 < 200 ms**, **P90 < 500 ms** (us-east-1).
- **RTO 1h**, **RPO 24h**.
- **Performance**: LCP < **2.5s** (P50) and TTI < **3s** on a mid-tier device, 4G.
- **Security**: OWASP ASVS L1/L2 (MVP), security headers, secret rotation.
- **Cost**: ≤ $10/month per environment.
- **Privacy/PII**: Mark PII fields, **mask in logs**, and default to minimization.

---

## 2) Architecture (high level)

```mermaid
flowchart LR
  U[User/Browser] --> CF[CloudFront (TLS, OAC, optional WAF)]
  CF -->|/api| ALB[(ALB :443 HSTS \n 80→443 redirect)]
  CF -->|/static| S3[(S3 PRIVATE \n OAC - no public access)]
  ALB --> ECS[ECS Fargate \n .NET 8 API]
  ECS --> RDS[(RDS SQL Server \n private subnets)]
  Admin[Admin/DevOps] --> Bastion[Bastion host] --> RDS
  subgraph Observability
    CW[CloudWatch Logs/Metrics]
    OTEL[OpenTelemetry Traces]
  end
  ECS --> CW
  ECS --> OTEL
```

**Highlights**  
- **CloudFront + OAC**: S3 is **private**; CloudFront is the only origin consumer.  
- **ALB 443 + ACM** with **HSTS**; :80 only for redirects.  
- **ECS Fargate** tasks in private subnets, least-privilege SGs.  
- **RDS** private, no public endpoints.  
- **Bastion** with time-bound, audited access for DB ops.  
- **WAF** (managed) is optional for baseline hardening (SQLi/XSS/rate).

---

## 3) Security

### 3.1 AuthN/Z
- **JWT RS256**: private key in **Secrets Manager** (KMS-encrypted); **public key** embedded for validation.
- **Refresh tokens**: rotate per session, **revocation list** in a fast store (e.g., DynamoDB/Redis) — *MVP: in-memory + short TTL; evolve to DynamoDB*.
- **Roles**: `viewer` → GET; `user` → GET + POST/PUT/PATCH on owned resources; `admin` → full CRUD + admin endpoints.
- **Scopes** (future): finer-grained endpoint access for third parties.

### 3.2 Web protections
- **TLS-only** (HSTS). **CSP**, `X-Content-Type-Options`, `Referrer-Policy`, `X-Frame-Options`, `Permissions-Policy`.
- **Rate limiting**: 1,000 req/day/client; small **burst** (e.g., 5 rps) via WAF/ALB + middleware.
- **CORS**: per-environment allowlist (dev/stg/prod).
- **Credentials**: Argon2/BCrypt hashing, password policy, lockout and optional MFA for admin.

### 3.3 Secrets
- Stored in **Secrets Manager**; injected into **ECS Task** via **TaskRole**.  
- **Rotation**: semiannual (MVP) with dual-signing window for JWT rollover.

---

## 4) API standards

- **Versioning**: `/api/v1`  
- **Schema**: **OpenAPI** (Swagger UI disabled in prod)  
- **Validation**: FluentValidation/DataAnnotations; **Problem Details** (`application/problem+json`)  
- **Pagination**: `page`, `size` (max 100); **Sorting**: `sort=field,asc|desc`; **Filtering**: `q` plus specific fields  
- **Idempotency**: `Idempotency-Key` for sensitive creates  
- **Errors**: consistent codes, `X-Request-ID` for correlation  
- **CORS** and **Rate limit** enforced at gateway/middleware

---

## 5) Data & PII

- **RDS SQL Server**: encrypted at rest; **daily backups**, **10-day** retention.  
- **Restore drills**: **quarterly** (MVP). Document timings vs **RTO 1h**.  
- **PII**: catalog (`email`, `phone`, etc.), **log masking** (`***`), trace scrubbing; anonymized dumps for dev.  
- **EF Core migrations**: run from CI/CD (pre-deploy step), verified in `stg` before `prod`.

---

## 6) Observability

- **Structured logs** (JSON) → CloudWatch Logs; keep 7–14 days (MVP).  
- **Metrics**: ALB (latency, 4xx/5xx), ECS (CPU/Mem), RDS (CPU/Conns/IOPS).  
- **Traces**: **OpenTelemetry** exported to X-Ray/OTLP backend.  
- **Dashboards**: P50/P90 latency, error rate, throughput, infra health.  
- **Alerts**: spikes in 5xx, latency breaches, RDS connection exhaustion/cpu.

---

## 7) Delivery & CI/CD

- **GitHub Actions**: OIDC → **assume-role** in AWS (no static keys).  
- **Pipelines**:  
  1. **App**: .NET 8 build + tests + SAST → Docker image → **ECR** (by **digest**).  
  2. **IaC**: `terraform fmt`/`validate`/`tflint` → `plan` → `apply` (env-gated).  
  3. **DB**: **EF migrations** on `stg` → verification → `prod`.  
- **Deploy**: ECS Fargate **rolling updates**; optional **blue/green** via CodeDeploy.  
- **Artifacts**: SemVer + **digest**; optional SBOM (Syft/Grype).

---

## 8) Infrastructure (Terraform)

- **Remote state**: **S3** + **DynamoDB** locking.  
- **Workspaces**: `dev`, `stg`, `prod`.  
- **Naming/Tagging**: `<proj>-<env>-<component>`; tags: `owner`, `cost-center`, `env`, `confidentiality`.  
- **Modules**: VPC, ALB, ECS Service/Task, ECR, RDS, S3+CloudFront(OAC), WAF (opt), IAM roles/policies, Secrets.  
- **Least privilege** for `taskRole` and `taskExecutionRole`.  
- **Outputs**: endpoints, key ARNs, resource names (no secrets).

---

## 9) Cost controls (≤ $10/month/env)

- **ECS**: minimal **cpu/memory** (e.g., 0.25 vCPU/0.5GB) + **scheduled scaling** to **min=0** nights/weekends if the demo permits.  
- **RDS**: schedule **stop/start** (if supported) or use the smallest dev/test SKU; as a demo, consider **RDS only in `stg/prod`**, and **SQL Server Developer container** for `dev`.  
- **CloudFront**: aggressive caching for static assets; limited invalidations.  
- **Logs**: short retention and targeted filters.  
- **Budgets & Alerts**: AWS Budgets at **$8/month/env** for early signal.

> **Note**: Hitting $10/month with always-on RDS is tight. If needed, shift to the hybrid plan above.

---

## 10) Roadmap

- Additional locales (IT/DE/FR/PT).  
- OAuth/OIDC (Google/GitHub) and MFA for admin.  
- Managed WAF with advanced rules and bot control.  
- Canary releases and API contract tests.  
- Multi-AZ and stricter SLOs as the system scales.

---

## 11) Runbooks

### 11.1 JWT rotation (RS256)
1) Generate new key (KMS/Secrets); publish **new public key** to app.  
2) Enable **dual validation** (old+new) for a grace window.  
3) Revoke old tokens; disable old key.  
4) Record the event and update docs.

### 11.2 RDS restore drill (quarterly)
1) Bring up an instance from yesterday’s snapshot.  
2) Run smoke tests.  
3) Measure end-to-end timing (compare with **RTO 1h**).  
4) Document and file corrective actions as needed.

---

## 12) MVP Checklist

- [ ] Domain + **ACM** + ALB :443 + 80→443 + **HSTS**  
- [ ] **CloudFront + OAC** with **private S3** (no public access)  
- [ ] **JWT RS256** + refresh + rotation plan  
- [ ] **OpenAPI v1** + validation + standard errors + pagination/filtering/sorting  
- [ ] **CORS** per environment + **rate limit** (1,000 req/day)  
- [ ] **OpenTelemetry** traces + metrics + dashboards + alerts  
- [ ] **Terraform remote state** (S3+DynamoDB), workspaces, tflint, naming/tagging  
- [ ] **CI/CD** via GH Actions (OIDC) with split pipelines (App/IaC/DB)  
- [ ] **Daily backups** (10 days) + **quarterly restore drill**  
- [ ] **Budgets** & cost alerts per environment  
- [ ] **PII masking** in logs and trace scrubbing  
- [ ] **Bastion** for DB with time-bound, audited access

---

## 13) Tagged TODOs

- TODO(i18n): Keep EN/ES in MVP; plan IT/DE/FR/PT in roadmap with localization files.  
- TODO(cost): Review actual AWS bill; tune scheduled scaling.  
- TODO(waf): Evaluate managed WAF baseline vs advanced after first release.  
- TODO(db-dev): Document **SQL Server Developer** container for `dev` and **SQLite** for tests.  
- TODO(otlp): Choose trace backend (X-Ray vs generic OTLP) and configure exporters.

---

## 14) Annex A – Authorization policy (example)
- **viewer**: `GET /api/v1/deals`, `GET /api/v1/deals/{id}`  
- **user**: viewer + `POST /api/v1/deals` (own), `PUT/PATCH/DELETE /api/v1/deals/{id}` (own)  
- **admin**: full CRUD and admin maintenance endpoints

## 15) Annex B – Security headers (CF/ALB + app)
- `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`  
- `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'`  
- `Referrer-Policy: no-referrer`  
- `X-Content-Type-Options: nosniff`  
- `X-Frame-Options: DENY`  
- `Permissions-Policy: geolocation=(), microphone=()`

---

## 16) Glossary
- **RTO/RPO**: Recovery Time / Recovery Point Objectives.  
- **OAC**: CloudFront Origin Access Control.  
- **OpenTelemetry**: Open standard for traces and metrics.  
- **RS256**: JWT with RSA SHA-256 (public/private key).