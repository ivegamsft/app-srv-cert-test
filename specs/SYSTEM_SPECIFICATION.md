# System Specification Document

**Project**: Azure App Service & VM Infrastructure with SSL Certificates  
**Version**: 1.0.0  
**Last Updated**: November 13, 2025  
**Purpose**: Validate functionality and guide test creation

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Application Requirements](#application-requirements)
3. [Infrastructure Requirements](#infrastructure-requirements)
4. [Security Requirements](#security-requirements)
5. [Networking Requirements](#networking-requirements)
6. [Monitoring & Alerting Requirements](#monitoring--alerting-requirements)
7. [Deployment Requirements](#deployment-requirements)
8. [Performance Requirements](#performance-requirements)
9. [Compliance & Best Practices](#compliance--best-practices)
10. [Testing Requirements](#testing-requirements)
11. [Missing Requirements Identified](#missing-requirements-identified)

---

## System Overview

### Architecture Pattern
- **Type**: Hybrid PaaS/IaaS Multi-tier Web Application
- **Cloud Provider**: Microsoft Azure
- **Infrastructure Management**: Terraform (Infrastructure as Code)
- **Deployment Model**: Modular, Reusable Terraform Modules

### System Components
1. **App Service (PaaS)** - Public-facing Node.js web application
2. **Virtual Machine (IaaS)** - Windows Server 2022 with IIS
3. **Application Gateway** - Layer 7 load balancer with SSL termination
4. **Key Vault** - Centralized secrets and certificate management
5. **Azure DNS** - Custom domain management
6. **Monitoring Stack** - Application Insights + Log Analytics

---

## Application Requirements

### APP-001: Node.js Web Application

#### Functional Requirements
- **APP-001-FR-01**: Application MUST run on Node.js 18 LTS or higher
- **APP-001-FR-02**: Application MUST use Express.js framework version 4.18.2+
- **APP-001-FR-03**: Application MUST listen on port specified by `PORT` environment variable (default: 3000)
- **APP-001-FR-04**: Application MUST support graceful shutdown on SIGTERM signal
- **APP-001-FR-05**: Application MUST run in production mode when `NODE_ENV=production`

#### Endpoint Requirements
- **APP-001-EP-01**: Health check endpoint at `GET /health`
  - MUST return HTTP 200
  - MUST return JSON: `{"status": "healthy", "timestamp": "<ISO8601>", "environment": "<env>"}`
  - Response time SHOULD be < 100ms

- **APP-001-EP-02**: Root endpoint at `GET /`
  - MUST return HTTP 200
  - MUST display HTML page with SSL/TLS information
  - MUST show connection security status (HTTP/HTTPS)
  - MUST show TLS version
  - MUST show SSL cipher suite
  - MUST show hostname and DNS binding information
  - MUST show request details (IP, User-Agent, timestamp)
  - MUST detect and display forwarded headers (x-forwarded-proto, x-forwarded-host, x-forwarded-for)
  - MUST show Azure-specific headers (X-ARR-ClientCert, X-ARR-SSL-Cipher)

- **APP-001-EP-03**: API info endpoint at `GET /api/info`
  - MUST return HTTP 200
  - MUST return JSON with: application name, version, Node.js version, platform, uptime, memory usage, timestamp
  
- **APP-001-EP-04**: 404 Handler
  - MUST return HTTP 404 for non-existent routes
  - MUST return JSON: `{"error": "Not Found", "path": "<requested_path>"}`

#### Error Handling Requirements
- **APP-001-ERR-01**: Global error handler MUST catch all unhandled errors
- **APP-001-ERR-02**: Error responses MUST return HTTP 500
- **APP-001-ERR-03**: Error messages MUST be sanitized in production (no stack traces)
- **APP-001-ERR-04**: Error messages MAY include details in development mode
- **APP-001-ERR-05**: All errors MUST be logged to console

#### Dependencies
- **APP-001-DEP-01**: Production dependencies MUST include only `express` (^4.18.2)
- **APP-001-DEP-02**: Development dependencies MAY include `nodemon` (^3.0.1)
- **APP-001-DEP-03**: Application MUST NOT have any critical or high vulnerability dependencies

---

## Infrastructure Requirements

### INF-001: Azure App Service

#### Configuration Requirements
- **INF-001-CFG-01**: MUST use Linux-based App Service Plan
- **INF-001-CFG-02**: MUST use S1 (Standard) SKU or higher
- **INF-001-CFG-03**: MUST enable "Always On" feature
- **INF-001-CFG-04**: MUST use Node.js 18-lts runtime stack
- **INF-001-CFG-05**: MUST enable HTTP/2 protocol
- **INF-001-CFG-06**: MUST set minimum TLS version to 1.2
- **INF-001-CFG-07**: MUST enforce HTTPS-only (https_only = true)
- **INF-001-CFG-08**: MUST enable System-assigned Managed Identity

#### Environment Variables
- **INF-001-ENV-01**: MUST set `WEBSITE_NODE_DEFAULT_VERSION` = "~18"
- **INF-001-ENV-02**: MUST set `NODE_ENV` based on environment (production/development)
- **INF-001-ENV-03**: MUST set `SCM_DO_BUILD_DURING_DEPLOYMENT` = "true"
- **INF-001-ENV-04**: MUST set `WEBSITE_RUN_FROM_PACKAGE` = "1"
- **INF-001-ENV-05**: MUST set `WEBSITE_TIME_ZONE` = "UTC"
- **INF-001-ENV-06**: SHOULD set Application Insights keys when available

#### Logging Requirements
- **INF-001-LOG-01**: MUST enable detailed error messages
- **INF-001-LOG-02**: MUST enable failed request tracing
- **INF-001-LOG-03**: MUST enable HTTP logs to file system
- **INF-001-LOG-04**: HTTP log retention MUST be 7 days
- **INF-001-LOG-05**: HTTP log size limit MUST be 35 MB

#### Custom Domain Requirements
- **INF-001-DOM-01**: MUST support custom domain binding
- **INF-001-DOM-02**: MUST create DNS CNAME record pointing to default hostname
- **INF-001-DOM-03**: MUST create DNS TXT record for domain verification (asuid.<subdomain>)
- **INF-001-DOM-04**: DNS TTL MUST be 300 seconds
- **INF-001-DOM-05**: MUST wait minimum 180 seconds after DNS creation before binding
- **INF-001-DOM-06**: MUST use App Service Managed Certificate (free SSL)
- **INF-001-DOM-07**: MUST enable SNI SSL binding
- **INF-001-DOM-08**: Managed certificate MUST auto-renew before expiration

#### RBAC Requirements
- **INF-001-RBAC-01**: App Service identity MUST have "Key Vault Secrets User" role on Key Vault

### INF-002: Virtual Machine

#### Configuration Requirements
- **INF-002-CFG-01**: MUST use Windows Server 2022 Datacenter image
- **INF-002-CFG-02**: MUST use Standard_DS2_v2 SKU (2 vCPU, 7 GB RAM)
- **INF-002-CFG-03**: MUST use Premium_LRS storage for OS disk
- **INF-002-CFG-04**: MUST enable System-assigned Managed Identity
- **INF-002-CFG-05**: MUST enable AutomaticByPlatform patch mode
- **INF-002-CFG-06**: MUST enable boot diagnostics with managed storage
- **INF-002-CFG-07**: MUST have dynamic private IP allocation
- **INF-002-CFG-08**: MUST NOT have public IP address (isolated)

#### Credentials Management
- **INF-002-CRED-01**: Admin username MUST be randomly generated (12 chars, alphanumeric, no uppercase)
- **INF-002-CRED-02**: Admin username MUST be prefixed with "vm-"
- **INF-002-CRED-03**: Admin password MUST be randomly generated (24 chars)
- **INF-002-CRED-04**: Admin password MUST include min 2 lowercase, 2 uppercase, 2 numeric, 2 special chars
- **INF-002-CRED-05**: Admin password special chars MUST be from set: !@#$%&*()-_=+[]{}:?
- **INF-002-CRED-06**: Admin username MUST be stored in Key Vault secret "vm-admin-username"
- **INF-002-CRED-07**: Admin password MUST be stored in Key Vault secret "vm-admin-password"

#### IIS Configuration
- **INF-002-IIS-01**: IIS MUST be installed via CustomScriptExtension
- **INF-002-IIS-02**: IIS MUST include Management Tools
- **INF-002-IIS-03**: ASP.NET 4.5 MUST be installed
- **INF-002-IIS-04**: Default page MUST be created at C:\inetpub\wwwroot\index.html
- **INF-002-IIS-05**: Default page MUST display server name and timestamp
- **INF-002-IIS-06**: Windows Firewall MUST allow inbound TCP port 80
- **INF-002-IIS-07**: Windows Firewall MUST allow inbound TCP port 443
- **INF-002-IIS-08**: W3SVC service MUST be started
- **INF-002-IIS-09**: W3SVC service MUST be set to Automatic startup

#### RBAC Requirements
- **INF-002-RBAC-01**: VM identity MUST have "Key Vault Secrets User" role on Key Vault

### INF-003: Application Gateway

#### Configuration Requirements
- **INF-003-CFG-01**: MUST use Standard_v2 SKU
- **INF-003-CFG-02**: MUST have capacity of 2 units (or auto-scale enabled)
- **INF-003-CFG-03**: MUST use User-assigned Managed Identity
- **INF-003-CFG-04**: MUST use predefined SSL policy "AppGwSslPolicy20220101" (TLS 1.2+)
- **INF-003-CFG-05**: MUST have dedicated subnet (minimum /24)
- **INF-003-CFG-06**: MUST have public IP address (Standard SKU, Static allocation)

#### Frontend Configuration
- **INF-003-FE-01**: MUST have frontend port 80 for HTTP
- **INF-003-FE-02**: MUST have frontend port 443 for HTTPS
- **INF-003-FE-03**: MUST have public frontend IP configuration

#### Backend Configuration
- **INF-003-BE-01**: Backend pool MUST contain VM private IP address
- **INF-003-BE-02**: Backend HTTP settings MUST use port 80
- **INF-003-BE-03**: Backend HTTP settings MUST use HTTP protocol
- **INF-003-BE-04**: Backend HTTP settings MUST disable cookie-based affinity
- **INF-003-BE-05**: Backend HTTP settings MUST have 60-second request timeout
- **INF-003-BE-06**: Backend HTTP settings MUST reference health probe

#### Health Probe Requirements
- **INF-003-HP-01**: Health probe MUST use HTTP protocol
- **INF-003-HP-02**: Health probe MUST check path "/"
- **INF-003-HP-03**: Health probe interval MUST be 30 seconds
- **INF-003-HP-04**: Health probe timeout MUST be 30 seconds
- **INF-003-HP-05**: Unhealthy threshold MUST be 3 failures
- **INF-003-HP-06**: Health probe MUST check status codes 200-399
- **INF-003-HP-07**: Health probe host MUST be 127.0.0.1

#### SSL Configuration
- **INF-003-SSL-01**: MUST retrieve SSL certificate from Key Vault
- **INF-003-SSL-02**: SSL certificate MUST be referenced by Key Vault secret ID
- **INF-003-SSL-03**: HTTPS listener MUST use SSL certificate
- **INF-003-SSL-04**: HTTPS listener MUST listen on port 443

#### Routing Rules
- **INF-003-ROUTE-01**: MUST have HTTP listener on port 80
- **INF-003-ROUTE-02**: HTTP listener MUST redirect to HTTPS listener (permanent redirect)
- **INF-003-ROUTE-03**: Redirect MUST include original path
- **INF-003-ROUTE-04**: Redirect MUST include original query string
- **INF-003-ROUTE-05**: MUST have HTTPS listener on port 443
- **INF-003-ROUTE-06**: HTTPS routing rule MUST have priority 110
- **INF-003-ROUTE-07**: HTTP routing rule MUST have priority 100
- **INF-003-ROUTE-08**: HTTPS traffic MUST be routed to backend pool

#### DNS Configuration
- **INF-003-DNS-01**: MUST create DNS A record for custom domain
- **INF-003-DNS-02**: DNS A record MUST point to Application Gateway public IP
- **INF-003-DNS-03**: DNS TTL MUST be 300 seconds

#### RBAC Requirements
- **INF-003-RBAC-01**: User-assigned identity MUST have "Key Vault Secrets User" role on Key Vault

### INF-004: Key Vault

#### Configuration Requirements
- **INF-004-CFG-01**: MUST use Standard SKU
- **INF-004-CFG-02**: MUST enable RBAC authorization (not access policies)
- **INF-004-CFG-03**: MUST enable soft delete with 90-day retention
- **INF-004-CFG-04**: MUST enable purge protection
- **INF-004-CFG-05**: Network ACLs MUST allow Azure services bypass
- **INF-004-CFG-06**: Network ACLs default action SHOULD be "Deny" in production

#### Certificate Requirements
- **INF-004-CERT-01**: MUST contain SSL certificate named "ssl-certificate"
- **INF-004-CERT-02**: Initial certificate MAY be self-signed for development
- **INF-004-CERT-03**: Certificate MUST be exportable
- **INF-004-CERT-04**: Certificate MUST use 2048-bit RSA key
- **INF-004-CERT-05**: Certificate MUST allow key reuse
- **INF-004-CERT-06**: Certificate MUST have 12-month validity
- **INF-004-CERT-07**: Certificate MUST auto-renew 30 days before expiry
- **INF-004-CERT-08**: Certificate MUST be in PKCS12 format
- **INF-004-CERT-09**: Certificate MUST have Server Authentication extended key usage (1.3.6.1.5.5.7.3.1)
- **INF-004-CERT-10**: Certificate MUST include required key usages (digitalSignature, keyEncipherment, etc.)
- **INF-004-CERT-11**: Certificate MUST include Subject Alternative Names (SANs)

#### Secrets Requirements
- **INF-004-SEC-01**: MUST store VM admin username as secret
- **INF-004-SEC-02**: MUST store VM admin password as secret
- **INF-004-SEC-03**: Secrets MUST be created after RBAC assignments

#### RBAC Requirements
- **INF-004-RBAC-01**: Current user/service principal MUST have "Key Vault Administrator" role
- **INF-004-RBAC-02**: Application Gateway identity MUST have "Key Vault Secrets User" role
- **INF-004-RBAC-03**: App Service identity MUST have "Key Vault Secrets User" role
- **INF-004-RBAC-04**: VM identity MUST have "Key Vault Secrets User" role

---

## Security Requirements

### SEC-001: Transport Layer Security

- **SEC-001-TLS-01**: All public endpoints MUST enforce HTTPS
- **SEC-001-TLS-02**: Minimum TLS version MUST be 1.2
- **SEC-001-TLS-03**: HTTP requests MUST redirect to HTTPS (permanent 301)
- **SEC-001-TLS-04**: Application Gateway MUST use modern SSL policy (AppGwSslPolicy20220101)
- **SEC-001-TLS-05**: App Service MUST enforce HTTPS-only
- **SEC-001-TLS-06**: SSL certificates MUST be valid and trusted
- **SEC-001-TLS-07**: Self-signed certificates are acceptable only for development/testing

### SEC-002: Identity and Access Management

- **SEC-002-IAM-01**: MUST use Managed Identities (no service principals with passwords)
- **SEC-002-IAM-02**: MUST use System-assigned identities for App Service and VM
- **SEC-002-IAM-03**: MUST use User-assigned identity for Application Gateway
- **SEC-002-IAM-04**: MUST use RBAC (Role-Based Access Control) not access policies
- **SEC-002-IAM-05**: MUST follow principle of least privilege
- **SEC-002-IAM-06**: Secrets MUST NOT be stored in code or version control
- **SEC-002-IAM-07**: Secrets MUST be stored in Key Vault
- **SEC-002-IAM-08**: Terraform state MUST mark sensitive outputs as sensitive

### SEC-003: Network Security

- **SEC-003-NET-01**: VM MUST NOT have public IP address
- **SEC-003-NET-02**: VM MUST be in isolated subnet
- **SEC-003-NET-03**: Application Gateway MUST be in separate subnet from VM
- **SEC-003-NET-04**: Network Security Groups MUST restrict traffic to required ports only
- **SEC-003-NET-05**: VM NSG MUST allow HTTP only from Application Gateway subnet
- **SEC-003-NET-06**: App Gateway NSG MUST allow inbound ports 80, 443 from Internet
- **SEC-003-NET-07**: App Gateway NSG MUST allow Gateway Manager traffic (65200-65535)
- **SEC-003-NET-08**: App Gateway NSG MUST allow Azure Load Balancer traffic
- **SEC-003-NET-09**: Internal traffic between subnets MUST be controlled by NSG rules

### SEC-004: Data Protection

- **SEC-004-DATA-01**: VM OS disk MUST use Premium_LRS (encrypted at rest by default)
- **SEC-004-DATA-02**: Key Vault MUST have purge protection enabled
- **SEC-004-DATA-03**: Key Vault MUST have soft delete enabled (90 days)
- **SEC-004-DATA-04**: Passwords MUST be randomly generated with high entropy
- **SEC-004-DATA-05**: Passwords MUST meet complexity requirements (mixed case, numbers, special chars)

### SEC-005: Patch Management

- **SEC-005-PATCH-01**: VM MUST use AutomaticByPlatform patch mode
- **SEC-005-PATCH-02**: VM MUST use latest Windows Server image version
- **SEC-005-PATCH-03**: Application dependencies MUST be kept up to date
- **SEC-005-PATCH-04**: MUST regularly scan for dependency vulnerabilities

---

## Networking Requirements

### NET-001: Virtual Network

- **NET-001-VNET-01**: MUST create dedicated VNet with address space 10.0.0.0/16
- **NET-001-VNET-02**: MUST have subnet for Application Gateway (10.0.1.0/24)
- **NET-001-VNET-03**: MUST have subnet for Virtual Machines (10.0.2.0/24)
- **NET-001-VNET-04**: Subnets MUST NOT overlap
- **NET-001-VNET-05**: VNet MUST support future subnet expansion

### NET-002: DNS Management

- **NET-002-DNS-01**: MUST use Azure DNS Zone for domain management
- **NET-002-DNS-02**: DNS zone MUST exist in rg-core-services resource group
- **NET-002-DNS-03**: MUST create CNAME record for App Service subdomain
- **NET-002-DNS-04**: MUST create TXT record for App Service domain verification
- **NET-002-DNS-05**: MUST create A record for Application Gateway custom domain
- **NET-002-DNS-06**: DNS records MUST have 300-second TTL
- **NET-002-DNS-07**: DNS zone nameservers MUST be configured at domain registrar
- **NET-002-DNS-08**: MUST support separate subdomains for App Service and VM/App Gateway

### NET-003: Public IP Addresses

- **NET-003-PIP-01**: Application Gateway MUST have public IP (Standard SKU)
- **NET-003-PIP-02**: Public IP MUST use Static allocation
- **NET-003-PIP-03**: Public IP MUST be created before Application Gateway
- **NET-003-PIP-04**: VM MUST NOT have public IP (internal only)

### NET-004: Network Security Groups

- **NET-004-NSG-01**: Each subnet MUST have associated NSG
- **NET-004-NSG-02**: NSG rules MUST be documented and justified
- **NET-004-NSG-03**: NSG rules MUST use specific ports (not wildcards when possible)
- **NET-004-NSG-04**: NSG rules MUST have unique priorities
- **NET-004-NSG-05**: NSG rules MUST be ordered by priority (100, 110, 120, etc.)

---

## Monitoring & Alerting Requirements

### MON-001: Application Insights

- **MON-001-AI-01**: MUST deploy Application Insights for App Service
- **MON-001-AI-02**: Application Insights MUST use workspace-based model
- **MON-001-AI-03**: Application type MUST be "web"
- **MON-001-AI-04**: MUST provide instrumentation key to App Service
- **MON-001-AI-05**: MUST provide connection string to App Service
- **MON-001-AI-06**: App Service SHOULD automatically instrument telemetry

### MON-002: Log Analytics

- **MON-002-LA-01**: MUST deploy Log Analytics Workspace
- **MON-002-LA-02**: MUST use PerGB2018 pricing tier
- **MON-002-LA-03**: Log retention MUST be 30 days minimum
- **MON-002-LA-04**: Application Insights MUST be linked to Log Analytics

### MON-003: Action Groups

- **MON-003-AG-01**: MUST create Action Group for alert notifications
- **MON-003-AG-02**: Action Group MUST have email receiver
- **MON-003-AG-03**: Email address MUST be derived from domain (alerts@{domain})
- **MON-003-AG-04**: MUST use common alert schema
- **MON-003-AG-05**: Action Group short name MUST be ≤12 characters

### MON-004: Alerts

#### Certificate Expiry Alerts
- **MON-004-CERT-01**: MUST monitor Key Vault certificate expiration
- **MON-004-CERT-02**: MUST use scheduled query rule with daily frequency
- **MON-004-CERT-03**: Alert severity MUST be 1 (Warning)
- **MON-004-CERT-04**: Query MUST check CertificateNearExpiry operation in AzureDiagnostics
- **MON-004-CERT-05**: Alert MUST trigger when count > 0
- **MON-004-CERT-06**: Auto-mitigation MUST be disabled for daily checks

#### Application Gateway Health Alerts
- **MON-004-AGW-01**: MUST monitor Application Gateway backend health
- **MON-004-AGW-02**: MUST use metric alert on UnhealthyHostCount
- **MON-004-AGW-03**: Alert MUST trigger when average > 0
- **MON-004-AGW-04**: Evaluation frequency MUST be 5 minutes
- **MON-004-AGW-05**: Window size MUST be 5 minutes
- **MON-004-AGW-06**: Alert severity MUST be 1 (Warning)

#### App Service HTTP Error Alerts
- **MON-004-APP-01**: MUST monitor App Service HTTP 5xx errors
- **MON-004-APP-02**: Alert threshold and configuration MUST be defined
- **MON-004-APP-03**: MUST link to Action Group for notifications

### MON-005: Metrics Collection

- **MON-005-MET-01**: MUST collect Application Gateway metrics (backend health, throughput, response time)
- **MON-005-MET-02**: MUST collect App Service metrics (HTTP requests, errors, response time, memory)
- **MON-005-MET-03**: MUST collect VM metrics (CPU, memory, disk, network)
- **MON-005-MET-04**: MUST retain metrics per Azure default retention policies

---

## Deployment Requirements

### DEP-001: Terraform Configuration

- **DEP-001-TF-01**: MUST use Terraform 1.5 or higher
- **DEP-001-TF-02**: MUST use Azure Provider (azurerm) version 3.117+
- **DEP-001-TF-03**: MUST use Random Provider version 3.7+
- **DEP-001-TF-04**: MUST use Time Provider version 0.13+
- **DEP-001-TF-05**: MUST use modular structure (separate modules for each component)
- **DEP-001-TF-06**: MUST properly declare module dependencies using depends_on
- **DEP-001-TF-07**: MUST use consistent naming convention: {type}-{prefix}-{project}-{environment}
- **DEP-001-TF-08**: MUST generate random 8-character prefix for uniqueness
- **DEP-001-TF-09**: Random prefix MUST be lowercase alphanumeric only
- **DEP-001-TF-10**: MUST apply tags to all resources (at minimum: ManagedBy=Terraform)

### DEP-002: Variable Management

- **DEP-002-VAR-01**: MUST provide terraform.tfvars.example file
- **DEP-002-VAR-02**: MUST document all variables with descriptions
- **DEP-002-VAR-03**: MUST provide sensible defaults where applicable
- **DEP-002-VAR-04**: Required variables MUST NOT have defaults (location, domain_name)
- **DEP-002-VAR-05**: MUST support environment-specific configurations (dev, staging, prod)
- **DEP-002-VAR-06**: MUST validate variable values where possible

### DEP-003: State Management

- **DEP-003-STATE-01**: Terraform state SHOULD be stored remotely (Azure Storage backend)
- **DEP-003-STATE-02**: State file MUST NOT contain unencrypted secrets (use sensitive = true)
- **DEP-003-STATE-03**: State locking SHOULD be enabled
- **DEP-003-STATE-04**: State file MUST be excluded from version control

### DEP-004: Application Deployment

- **DEP-004-APP-01**: MUST support ZIP deployment method
- **DEP-004-APP-02**: MUST support GitHub Actions CI/CD
- **DEP-004-APP-03**: MUST build deployment package with production dependencies only
- **DEP-004-APP-04**: MUST run health check after deployment
- **DEP-004-APP-05**: Deployment MUST verify HTTP 200 response from /health endpoint
- **DEP-004-APP-06**: MUST use App Service publish profile for authentication
- **DEP-004-APP-07**: Publish profile MUST be stored as GitHub secret
- **DEP-004-APP-08**: MUST cache Node.js dependencies in CI/CD pipeline

### DEP-005: Deployment Sequence

- **DEP-005-SEQ-01**: Resource Group MUST be created first
- **DEP-005-SEQ-02**: Networking MUST be created before resources that depend on subnets
- **DEP-005-SEQ-03**: Key Vault MUST be created before resources that need certificates
- **DEP-005-SEQ-04**: Public IP for App Gateway MUST be created before Application Gateway
- **DEP-005-SEQ-05**: VM MUST be created before Application Gateway backend pool
- **DEP-005-SEQ-06**: DNS records MUST be created before custom domain binding
- **DEP-005-SEQ-07**: MUST wait 180 seconds after DNS creation before domain binding
- **DEP-005-SEQ-08**: Monitoring MUST be created to provide Application Insights to App Service
- **DEP-005-SEQ-09**: Custom domain binding SHOULD be enabled only after DNS delegation verification

### DEP-006: Outputs

- **DEP-006-OUT-01**: MUST output resource group name
- **DEP-006-OUT-02**: MUST output random resource prefix
- **DEP-006-OUT-03**: MUST output DNS zone nameservers
- **DEP-006-OUT-04**: MUST output App Service default hostname
- **DEP-006-OUT-05**: MUST output App Service custom domain
- **DEP-006-OUT-06**: MUST output Application Gateway public IP
- **DEP-006-OUT-07**: MUST output VM custom domain
- **DEP-006-OUT-08**: MUST output Key Vault name and URI
- **DEP-006-OUT-09**: MUST output generated credentials as sensitive
- **DEP-006-OUT-10**: MUST output Application Insights keys as sensitive
- **DEP-006-OUT-11**: SHOULD output deployment instructions

---

## Performance Requirements

### PERF-001: Response Time

- **PERF-001-RT-01**: Health endpoint SHOULD respond in < 100ms (p95)
- **PERF-001-RT-02**: Main page SHOULD respond in < 500ms (p95)
- **PERF-001-RT-03**: API endpoint SHOULD respond in < 200ms (p95)
- **PERF-001-RT-04**: Application Gateway health probe timeout is 30 seconds

### PERF-002: Availability

- **PERF-002-AV-01**: App Service MUST have "Always On" enabled
- **PERF-002-AV-02**: System uptime target SHOULD be 99.9% monthly
- **PERF-002-AV-03**: Application Gateway MUST have auto-scaling capability (v2 SKU)
- **PERF-002-AV-04**: MUST support health probe recovery within 90 seconds (3 failed probes at 30s interval)

### PERF-003: Scalability

- **PERF-003-SCALE-01**: App Service Plan SHOULD support scale-out (multiple instances)
- **PERF-003-SCALE-02**: Application Gateway capacity MUST be 2 units minimum
- **PERF-003-SCALE-03**: Application MUST be stateless (session affinity disabled)
- **PERF-003-SCALE-04**: Application MUST gracefully handle SIGTERM for zero-downtime deployments

### PERF-004: Resource Sizing

- **PERF-004-SIZE-01**: App Service S1 provides: 1 core, 1.75 GB RAM, 50 GB storage
- **PERF-004-SIZE-02**: VM Standard_DS2_v2 provides: 2 vCPU, 7 GB RAM
- **PERF-004-SIZE-03**: Resource sizes MUST be appropriate for expected load
- **PERF-004-SIZE-04**: MUST monitor resource utilization to guide right-sizing

---

## Compliance & Best Practices

### COMP-001: Azure Best Practices

- **COMP-001-BP-01**: MUST use managed services where possible (PaaS over IaaS)
- **COMP-001-BP-02**: MUST use managed identities instead of service principals
- **COMP-001-BP-03**: MUST use RBAC instead of legacy access controls
- **COMP-001-BP-04**: MUST enable diagnostic logging
- **COMP-001-BP-05**: MUST tag all resources for cost tracking and governance
- **COMP-001-BP-06**: MUST use Standard SKU for production workloads
- **COMP-001-BP-07**: MUST enable soft delete and purge protection for Key Vault
- **COMP-001-BP-08**: MUST use zone-redundant resources where available

### COMP-002: Infrastructure as Code Best Practices

- **COMP-002-IAC-01**: MUST use version control for all IaC code
- **COMP-002-IAC-02**: MUST document architecture decisions (ADR)
- **COMP-002-IAC-03**: MUST use modules for reusability
- **COMP-002-IAC-04**: MUST validate Terraform code before apply
- **COMP-002-IAC-05**: MUST review terraform plan before apply
- **COMP-002-IAC-06**: SHOULD use terraform fmt for consistent formatting
- **COMP-002-IAC-07**: SHOULD use terraform validate to check configuration
- **COMP-002-IAC-08**: MUST NOT commit sensitive values to version control

### COMP-003: Security Best Practices

- **COMP-003-SEC-01**: MUST follow principle of least privilege
- **COMP-003-SEC-02**: MUST encrypt data in transit (TLS 1.2+)
- **COMP-003-SEC-03**: MUST encrypt data at rest (default Azure encryption)
- **COMP-003-SEC-04**: MUST use strong password policies
- **COMP-003-SEC-05**: MUST regularly rotate secrets and certificates
- **COMP-003-SEC-06**: MUST monitor for security events and anomalies
- **COMP-003-SEC-07**: MUST have incident response plan
- **COMP-003-SEC-08**: SHOULD enable Azure Defender/Security Center

### COMP-004: Operational Best Practices

- **COMP-004-OPS-01**: MUST have monitoring and alerting configured
- **COMP-004-OPS-02**: MUST have backup and disaster recovery plan
- **COMP-004-OPS-03**: MUST document deployment procedures
- **COMP-004-OPS-04**: MUST document rollback procedures
- **COMP-004-OPS-05**: MUST maintain runbooks for common operations
- **COMP-004-OPS-06**: MUST log all administrative actions
- **COMP-004-OPS-07**: SHOULD implement automated testing
- **COMP-004-OPS-08**: SHOULD implement automated deployments

---

## Testing Requirements

### TEST-001: Unit Testing

- **TEST-001-UNIT-01**: MUST test all application endpoints
- **TEST-001-UNIT-02**: MUST test health check endpoint returns correct JSON
- **TEST-001-UNIT-03**: MUST test root endpoint returns HTML with expected content
- **TEST-001-UNIT-04**: MUST test API info endpoint returns correct JSON structure
- **TEST-001-UNIT-05**: MUST test 404 handler for non-existent routes
- **TEST-001-UNIT-06**: MUST test error handler catches exceptions
- **TEST-001-UNIT-07**: MUST verify environment variable handling

### TEST-002: Integration Testing

- **TEST-002-INT-01**: MUST verify App Service deployment succeeds
- **TEST-002-INT-02**: MUST verify application starts successfully
- **TEST-002-INT-03**: MUST verify health check endpoint accessibility over HTTPS
- **TEST-002-INT-04**: MUST verify custom domain resolves correctly
- **TEST-002-INT-05**: MUST verify SSL certificate is valid and trusted
- **TEST-002-INT-06**: MUST verify HTTP redirects to HTTPS
- **TEST-002-INT-07**: MUST verify Application Gateway backend health is healthy
- **TEST-002-INT-08**: MUST verify VM is accessible from Application Gateway
- **TEST-002-INT-09**: MUST verify IIS is running on VM
- **TEST-002-INT-10**: MUST verify managed identities can access Key Vault

### TEST-003: Infrastructure Testing

- **TEST-003-INFRA-01**: MUST validate Terraform configuration (terraform validate)
- **TEST-003-INFRA-02**: MUST format Terraform code (terraform fmt -check)
- **TEST-003-INFRA-03**: MUST review Terraform plan before apply
- **TEST-003-INFRA-04**: MUST verify all required resources are created
- **TEST-003-INFRA-05**: MUST verify resource naming follows convention
- **TEST-003-INFRA-06**: MUST verify tags are applied to all resources
- **TEST-003-INFRA-07**: MUST verify network security groups have correct rules
- **TEST-003-INFRA-08**: MUST verify DNS records are created correctly
- **TEST-003-INFRA-09**: MUST verify RBAC assignments are correct

### TEST-004: Security Testing

- **TEST-004-SEC-01**: MUST verify HTTPS enforcement (reject HTTP without redirect)
- **TEST-004-SEC-02**: MUST verify TLS version is 1.2 or higher
- **TEST-004-SEC-03**: MUST verify SSL certificate validity
- **TEST-004-SEC-04**: MUST verify VM has no public IP address
- **TEST-004-SEC-05**: MUST verify credentials are stored in Key Vault, not code
- **TEST-004-SEC-06**: MUST verify managed identities are used (no passwords)
- **TEST-004-SEC-07**: MUST verify NSG rules block unauthorized access
- **TEST-004-SEC-08**: MUST scan for dependency vulnerabilities
- **TEST-004-SEC-09**: SHOULD perform penetration testing on public endpoints

### TEST-005: Monitoring Testing

- **TEST-005-MON-01**: MUST verify Application Insights is collecting telemetry
- **TEST-005-MON-02**: MUST verify Log Analytics is receiving logs
- **TEST-005-MON-03**: MUST verify alerts are configured correctly
- **TEST-005-MON-04**: MUST test alert notifications are delivered
- **TEST-005-MON-05**: MUST verify metrics are being collected
- **TEST-005-MON-06**: MUST verify health probe monitoring is active

### TEST-006: Performance Testing

- **TEST-006-PERF-01**: MUST measure health endpoint response time
- **TEST-006-PERF-02**: MUST measure main page load time
- **TEST-006-PERF-03**: MUST verify Application Gateway health probe succeeds
- **TEST-006-PERF-04**: SHOULD perform load testing to verify scalability
- **TEST-006-PERF-05**: SHOULD verify graceful shutdown behavior

### TEST-007: Disaster Recovery Testing

- **TEST-007-DR-01**: MUST verify terraform destroy works without errors
- **TEST-007-DR-02**: MUST verify terraform apply can recreate infrastructure
- **TEST-007-DR-03**: SHOULD test backup and restore procedures
- **TEST-007-DR-04**: SHOULD test failover scenarios
- **TEST-007-DR-05**: SHOULD verify recovery time objectives (RTO)
- **TEST-007-DR-06**: SHOULD verify recovery point objectives (RPO)

---

## Missing Requirements Identified

### MISSING-001: Application Testing

**Gap**: No test suite exists for the application
- **MISSING-001-01**: Need automated tests for all endpoints
- **MISSING-001-02**: Need integration tests for deployment scenarios
- **MISSING-001-03**: Need test script in package.json (currently exits with error)
- **MISSING-001-04**: Need test coverage reporting
- **Priority**: HIGH

### MISSING-002: Error Handling & Logging

**Gap**: Limited structured logging
- **MISSING-002-01**: No structured logging framework (e.g., Winston, Pino)
- **MISSING-002-02**: No request ID tracking for tracing
- **MISSING-002-03**: No correlation IDs for distributed tracing
- **MISSING-002-04**: Console.log should be replaced with proper logger
- **Priority**: MEDIUM

### MISSING-003: Application Insights Integration

**Gap**: Application Insights not integrated in app code
- **MISSING-003-01**: No Application Insights SDK in application
- **MISSING-003-02**: Manual instrumentation not configured
- **MISSING-003-03**: Custom events/metrics not tracked
- **MISSING-003-04**: Dependency tracking not enabled
- **Priority**: HIGH

### MISSING-004: Health Check Enhancement

**Gap**: Health check is basic
- **MISSING-004-01**: Health check doesn't verify dependencies (database, external services)
- **MISSING-004-02**: No liveness vs readiness probe distinction
- **MISSING-004-03**: No detailed health status for troubleshooting
- **MISSING-004-04**: No dependency timeout handling
- **Priority**: MEDIUM

### MISSING-005: Configuration Management

**Gap**: Configuration is environment variable based only
- **MISSING-005-01**: No configuration validation on startup
- **MISSING-005-02**: No centralized configuration (Azure App Configuration)
- **MISSING-005-03**: No feature flags support
- **MISSING-005-04**: No configuration reload without restart
- **Priority**: LOW

### MISSING-006: Security Headers

**Gap**: Missing security headers in responses
- **MISSING-006-01**: No Content Security Policy (CSP) headers
- **MISSING-006-02**: No X-Frame-Options header
- **MISSING-006-03**: No X-Content-Type-Options header
- **MISSING-006-04**: No Strict-Transport-Security (HSTS) header
- **MISSING-006-05**: Consider using helmet.js middleware
- **Priority**: HIGH

### MISSING-007: Rate Limiting

**Gap**: No rate limiting or throttling
- **MISSING-007-01**: No request rate limiting per IP
- **MISSING-007-02**: No protection against DDoS
- **MISSING-007-03**: No API quota management
- **MISSING-007-04**: Consider express-rate-limit middleware
- **Priority**: MEDIUM

### MISSING-008: VM Monitoring

**Gap**: VM monitoring is incomplete
- **MISSING-008-01**: No Application Insights for VM/IIS
- **MISSING-008-02**: No IIS logs integration with Log Analytics
- **MISSING-008-03**: No VM performance monitoring alerts
- **MISSING-008-04**: No disk space monitoring
- **Priority**: MEDIUM

### MISSING-009: Backup Strategy

**Gap**: No backup configuration
- **MISSING-009-01**: No App Service backup configured
- **MISSING-009-02**: No VM backup (Azure Backup)
- **MISSING-009-03**: No Key Vault backup strategy documented
- **MISSING-009-04**: No backup retention policy defined
- **MISSING-009-05**: No backup testing procedures
- **Priority**: HIGH (for production)

### MISSING-010: Cost Management

**Gap**: No cost optimization or monitoring
- **MISSING-010-01**: No cost alerts configured
- **MISSING-010-02**: No budget limits set
- **MISSING-010-03**: No cost allocation tags
- **MISSING-010-04**: No resource right-sizing analysis
- **MISSING-010-05**: No auto-shutdown for non-production environments
- **Priority**: MEDIUM

### MISSING-011: Certificate Management Process

**Gap**: Production certificate deployment not documented
- **MISSING-011-01**: No process for replacing self-signed certificate with real certificate
- **MISSING-011-02**: No documentation for certificate renewal process
- **MISSING-011-03**: No certificate validation testing
- **MISSING-011-04**: App Service uses managed certificate (good), but App Gateway uses Key Vault cert (needs process)
- **Priority**: HIGH (for production)

### MISSING-012: Disaster Recovery Plan

**Gap**: No formal DR plan
- **MISSING-012-01**: No documented RTO (Recovery Time Objective)
- **MISSING-012-02**: No documented RPO (Recovery Point Objective)
- **MISSING-012-03**: No multi-region failover strategy
- **MISSING-012-04**: No DR testing schedule
- **MISSING-012-05**: No runbook for disaster scenarios
- **Priority**: MEDIUM (for production)

### MISSING-013: CI/CD Pipeline Testing

**Gap**: GitHub Actions workflow not fully tested
- **MISSING-013-01**: Workflow tested locally but not triggered from GitHub
- **MISSING-013-02**: No automated terraform plan in PR workflow
- **MISSING-013-03**: No infrastructure validation in CI
- **MISSING-013-04**: No environment segregation (dev/staging/prod)
- **MISSING-013-05**: No approval gates for production deployments
- **Priority**: MEDIUM

### MISSING-014: Documentation Gaps

**Gap**: Some operational documentation missing
- **MISSING-014-01**: No troubleshooting guide
- **MISSING-014-02**: No runbook for common operations
- **MISSING-014-03**: No monitoring dashboard setup guide
- **MISSING-014-04**: No incident response procedures
- **MISSING-014-05**: No onboarding guide for new team members
- **Priority**: MEDIUM

### MISSING-015: API Versioning

**Gap**: No API versioning strategy
- **MISSING-015-01**: No version in API endpoints
- **MISSING-015-02**: No backward compatibility strategy
- **MISSING-015-03**: No API deprecation process
- **Priority**: LOW (for current scope)

### MISSING-016: Input Validation

**Gap**: No request validation
- **MISSING-016-01**: No request body validation
- **MISSING-016-02**: No query parameter validation
- **MISSING-016-03**: No request size limits (beyond Express defaults)
- **MISSING-016-04**: No content-type validation
- **Priority**: MEDIUM

### MISSING-017: WAF (Web Application Firewall)

**Gap**: Application Gateway WAF not enabled
- **MISSING-017-01**: Using Standard_v2 SKU, not WAF_v2
- **MISSING-017-02**: No OWASP protection rules
- **MISSING-017-03**: No bot protection
- **MISSING-017-04**: No geo-filtering
- **Priority**: HIGH (for production with public traffic)

### MISSING-018: VNet Integration

**Gap**: App Service not VNet integrated
- **MISSING-018-01**: App Service has no VNet integration
- **MISSING-018-02**: App Service cannot privately access VM
- **MISSING-018-03**: All traffic is over public internet
- **MISSING-018-04**: Consider VNet integration for secure backend communication
- **Priority**: LOW (current architecture doesn't require it)

### MISSING-019: Container Support

**Gap**: Not containerized
- **MISSING-019-01**: Application not containerized (Docker)
- **MISSING-019-02**: No container registry
- **MISSING-019-03**: Could consider Azure Container Apps for modernization
- **Priority**: LOW (not a requirement, but a consideration)

### MISSING-020: Terraform Backend

**Gap**: Using local state
- **MISSING-020-01**: Terraform state is local, not remote
- **MISSING-020-02**: No state locking (could cause corruption)
- **MISSING-020-03**: No state versioning/history
- **MISSING-020-04**: State not shared across team
- **MISSING-020-05**: Should configure Azure Storage backend
- **Priority**: HIGH (for team collaboration)

---

## Summary Statistics

### Requirements Coverage
- **Application Requirements**: 29 requirements (4 functional areas)
- **Infrastructure Requirements**: 120+ requirements (6 major components)
- **Security Requirements**: 35 requirements (5 categories)
- **Networking Requirements**: 22 requirements (4 areas)
- **Monitoring Requirements**: 32 requirements (5 categories)
- **Deployment Requirements**: 43 requirements (6 areas)
- **Performance Requirements**: 15 requirements (4 categories)
- **Compliance Requirements**: 28 requirements (4 areas)
- **Testing Requirements**: 36 requirements (7 test types)

**Total Defined Requirements**: ~360

### Missing Requirements
- **Critical Gaps**: 20 categories identified
- **High Priority**: 6 items (testing, App Insights, security headers, backup, certificates, WAF, Terraform backend)
- **Medium Priority**: 9 items (logging, health checks, rate limiting, VM monitoring, cost, DR, CI/CD, docs, validation)
- **Low Priority**: 5 items (config mgmt, API versioning, VNet integration, containerization)

### Next Steps for Implementation

1. **Immediate Actions (High Priority)**:
   - Add application test suite (MISSING-001)
   - Integrate Application Insights SDK (MISSING-003)
   - Add security headers via helmet.js (MISSING-006)
   - Configure Terraform remote backend (MISSING-020)
   - Document certificate replacement process (MISSING-011)
   - Define backup strategy (MISSING-009)

2. **Short-term Actions (Medium Priority)**:
   - Implement structured logging (MISSING-002)
   - Add rate limiting (MISSING-007)
   - Configure VM monitoring (MISSING-008)
   - Set up cost alerts (MISSING-010)
   - Complete CI/CD testing (MISSING-013)
   - Create operational documentation (MISSING-014)

3. **Long-term Considerations (Low Priority)**:
   - Evaluate configuration management service (MISSING-005)
   - Consider API versioning strategy (MISSING-015)
   - Assess containerization benefits (MISSING-019)

---

## Document Control

- **Version**: 1.0.0
- **Status**: Initial Draft
- **Last Review**: November 13, 2025
- **Next Review**: Upon implementation of critical gaps or major architecture changes
- **Approved By**: Pending
- **Change History**:
  - 2025-11-13: Initial specification created based on code analysis

---

*This specification document is a living document and should be updated as the system evolves.*
