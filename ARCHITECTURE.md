# Architecture Decision Record (ADR)

## Context and Problem Statement

We need to deploy a public-facing web application on Azure with the following requirements:
- App Service for the main application
- Virtual Machine for backend services
- Custom domain with SSL certificates
- Centralized certificate management
- SSL expiration monitoring
- Infrastructure as Code (Terraform)

## Decision Drivers

1. **Security**: HTTPS-only, secure certificate storage, managed identities
2. **Reliability**: High availability, health monitoring, auto-renewal
3. **Cost Optimization**: Appropriate SKU sizing, managed services where possible
4. **Maintainability**: Infrastructure as Code, modular design
5. **Monitoring**: Comprehensive alerting for SSL expiration and health

## Considered Options

### Option 1: All resources in single module (NOT CHOSEN)
- **Pros**: Simpler structure, fewer files
- **Cons**: Hard to maintain, reuse, and test

### Option 2: Modular Terraform structure (CHOSEN) ✅
- **Pros**: Reusable modules, easier testing, clear separation of concerns
- **Cons**: More files to manage, requires planning

### Option 3: Bicep instead of Terraform (NOT CHOSEN)
- **Pros**: Native Azure language, tight integration
- **Cons**: Azure-only, less community support than Terraform

## Decision Outcome

**Chosen Option**: Modular Terraform structure

### Architecture Components

#### 1. App Service
- **Choice**: Azure App Service (PaaS)
- **Rationale**: 
  - Managed service (less operational overhead)
  - Built-in auto-scaling
  - Native support for Node.js
  - Free managed SSL certificates with auto-renewal
- **SKU**: S1 (Standard)
  - Production-ready
  - Custom domain support
  - SSL/TLS support
  - Always-on capability

#### 2. Virtual Machine
- **Choice**: Windows Server 2022 with IIS
- **Rationale**:
  - Requirement specified IIS
  - Full control over configuration
  - System-assigned managed identity
- **SKU**: Standard_DS2_v2
  - 2 vCPUs, 7 GB RAM
  - Premium SSD support
  - Good balance of cost/performance
  - Matches requirement

#### 3. Application Gateway
- **Choice**: Application Gateway v2
- **Rationale**:
  - Layer 7 load balancing
  - SSL termination
  - WAF capability (can be enabled later)
  - Integration with Key Vault
  - HTTP to HTTPS redirect
- **SKU**: Standard_v2
  - Auto-scaling support
  - Better performance than v1
  - Zone redundancy support

#### 4. Key Vault
- **Choice**: Azure Key Vault with RBAC
- **Rationale**:
  - Centralized secret management
  - RBAC instead of access policies (modern approach)
  - Purge protection enabled (security best practice)
  - Soft delete with 90-day retention
  - Integration with managed identities

#### 5. DNS
- **Choice**: Azure DNS Zone
- **Rationale**:
  - Native Azure integration
  - Terraform can manage DNS records automatically
  - High availability (99.99% SLA)
  - Global anycast network

#### 6. Monitoring
- **Choice**: Application Insights + Log Analytics
- **Rationale**:
  - Native Azure monitoring solution
  - Deep integration with App Service
  - Centralized log storage
  - Query language (KQL) for analysis
  - Action Groups for notifications

### Security Decisions

1. **Managed Identities over Service Principals**
   - No credential management
   - Automatic rotation
   - Azure AD integration

2. **RBAC over Access Policies for Key Vault**
   - Consistent with Azure RBAC model
   - Centralized access management
   - Future-proof (Microsoft recommendation)

3. **Network Isolation**
   - VM in private subnet (no public IP)
   - NSGs with least privilege rules
   - Application Gateway as the only public entry point

4. **HTTPS Enforcement**
   - App Service: HTTPS-only setting
   - Application Gateway: HTTP→HTTPS redirect
   - Minimum TLS 1.2

### Cost Optimization Decisions

1. **App Service S1 instead of P-series**
   - S1 sufficient for dev/test
   - Can scale up easily
   - ~$75/month savings vs P1v2

2. **Application Gateway Standard_v2 instead of WAF_v2**
   - Can enable WAF later if needed
   - ~$180/month savings
   - WAF can be added without downtime

3. **Managed Certificates**
   - Free for App Service
   - Automatic renewal
   - No certificate purchase cost

### Module Structure

```
modules/
├── networking/       # VNet, subnets, NSGs, public IPs
├── key-vault/       # Key Vault, certificates, managed identity
├── app-service/     # App Service Plan, App Service, SSL
├── virtual-machine/ # VM, NIC, IIS installation
├── app-gateway/     # Application Gateway, SSL termination
└── monitoring/      # App Insights, Log Analytics, Alerts
```

**Rationale**:
- Each module has single responsibility
- Modules are reusable
- Clear dependencies between modules
- Easy to test individually

### Naming Convention

**Pattern**: `<type>-<random-prefix>-<project>-<environment>`

**Rationale**:
- Type prefix for resource identification
- Random prefix for global uniqueness
- Project name for logical grouping
- Environment for multi-stage deployments

**Examples**:
- `rg-abc12345-webapp-dev`
- `app-abc12345-webapp-dev`
- `kv-abc12345-dev`

## Consequences

### Positive

✅ **Maintainability**: Modular structure makes updates easier
✅ **Security**: Best practices implemented (RBAC, managed identities, HTTPS)
✅ **Monitoring**: Comprehensive alerting for SSL and health
✅ **Cost-effective**: Optimized SKUs with upgrade path
✅ **Scalability**: Can scale each component independently
✅ **Automation**: Full IaC with Terraform
✅ **Documentation**: Well-documented with README files

### Negative

⚠️ **Complexity**: More files to manage than single module
⚠️ **Learning Curve**: Team needs Terraform knowledge
⚠️ **State Management**: Need to manage Terraform state
⚠️ **Cost**: ~$446/month operational cost

### Mitigation Strategies

1. **Complexity**: Comprehensive documentation and README files
2. **Learning Curve**: Provided example configurations and deployment checklist
3. **State Management**: Can add remote backend (Azure Storage) later
4. **Cost**: Used appropriate SKUs with clear upgrade path

## Alternatives Considered

### For SSL Certificates

1. **Let's Encrypt via Certbot** (rejected)
   - More operational overhead
   - Need renewal automation
   - App Service has built-in managed certificates

2. **Third-party Certificate Authority** (rejected for initial setup)
   - Additional cost
   - Manual renewal process
   - Can be added later if needed

3. **App Service Managed Certificate** (chosen for App Service)
   - Free
   - Automatic renewal
   - Native integration

### For Monitoring

1. **Third-party APM (Datadog, New Relic)** (rejected)
   - Additional cost
   - Extra integration needed
   - App Insights is native and sufficient

2. **Azure Monitor only** (rejected)
   - Lacks detailed application telemetry
   - No distributed tracing

3. **Application Insights + Log Analytics** (chosen)
   - Native Azure solution
   - Comprehensive monitoring
   - Good query capabilities

## Future Considerations

1. **Multi-region deployment**: Can replicate modules in another region
2. **WAF enablement**: Easy upgrade to WAF_v2 SKU
3. **Auto-scaling**: Configure rules for App Service and Application Gateway
4. **CI/CD**: Add GitHub Actions or Azure DevOps pipelines
5. **Backup strategy**: Implement backup for VM and databases
6. **Disaster recovery**: Document and test DR procedures
7. **Remote backend**: Move Terraform state to Azure Storage
8. **Certificate automation**: Integrate with external CA if required

## References

- [Azure Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure App Service Best Practices](https://docs.microsoft.com/azure/app-service/app-service-best-practices)
- [Application Gateway Best Practices](https://docs.microsoft.com/azure/application-gateway/application-gateway-best-practices)

---

**Status**: Accepted  
**Date**: November 13, 2025  
**Decision Makers**: Engineering Team  
**Last Updated**: November 13, 2025
