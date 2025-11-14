# Azure App Service & VM Infrastructure with Terraform

Complete infrastructure-as-code solution for deploying a public-facing application on Azure with SSL certificates, custom domains, and comprehensive monitoring.

## 🏗️ Project Structure

```
app-srv-cert-test/
├── app/                    # Sample Node.js application
│   ├── server.js          # Express.js server
│   ├── package.json       # NPM dependencies
│   └── README.md          # App documentation
│
├── iac/                    # Infrastructure as Code (Terraform)
│   ├── main.tf            # Main configuration
│   ├── providers.tf       # Provider configuration
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   ├── terraform.tfvars.example  # Example variables
│   │
│   └── modules/           # Terraform modules
│       ├── networking/    # VNet, Subnets, NSGs, Public IPs
│       ├── key-vault/     # Key Vault with RBAC
│       ├── app-service/   # App Service with custom domain
│       ├── virtual-machine/  # Windows VM with IIS
│       ├── app-gateway/   # Application Gateway with SSL
│       └── monitoring/    # Azure Monitor & Alerts
│
├── specs/                  # Specifications (empty)
└── tests/                  # Tests (empty)
```

## 🎯 What Gets Deployed

### Core Infrastructure

1. **App Service**
   - Node.js 18 LTS runtime
   - S1 (Standard) tier
   - Custom domain with managed SSL certificate
   - Auto-renewal enabled
   - System-assigned managed identity

2. **Virtual Machine**
   - Windows Server 2022 Datacenter
   - Standard_DS2_v2 (2 vCPU, 7 GB RAM)
   - IIS web server pre-installed
   - Private network (isolated subnet)
   - System-assigned managed identity

3. **Application Gateway**
   - Standard_v2 tier
   - SSL termination
   - HTTP to HTTPS redirect
   - Health probes
   - Backend pool pointing to VM

4. **Key Vault**
   - RBAC-based access control
   - Purge protection enabled
   - 90-day soft delete retention
   - SSL certificates storage
   - Secrets management

5. **Azure DNS Zone**
   - Custom domain management
   - Automatic DNS record creation
   - CNAME records for App Service
   - A records for Application Gateway

6. **Monitoring & Alerts**
   - Application Insights
   - Log Analytics Workspace
   - SSL expiration alerts (30, 14, 7 days)
   - Application health alerts
   - Email notifications

7. **Networking**
   - Virtual Network (10.0.0.0/16)
   - Application Gateway subnet (10.0.1.0/24)
   - VM subnet (10.0.2.0/24)
   - Network Security Groups
   - Public IP for Application Gateway

## 🚀 Quick Start

### Prerequisites

- Azure subscription
- Terraform 1.5+
- Azure CLI
- Domain name (to be purchased)

### Deployment

1. **Configure variables**:
   ```powershell
   cd iac
   Copy-Item terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Login to Azure**:
   ```powershell
   az login
   ```

3. **Deploy infrastructure**:
   ```powershell
   terraform init
   terraform validate
   terraform plan
   terraform apply
   ```

4. **Configure DNS** at your registrar with the output nameservers

5. **Deploy application**:
   ```powershell
   cd ../app
   npm install
   # Deploy to Azure App Service (see app/README.md)
   ```

6. **Setup CI/CD (Optional)**:
   ```powershell
   # Automated deployment with GitHub Actions
   .\setup-github-actions.ps1
   ```
   See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for detailed instructions.

Full documentation: [iac/README.md](iac/README.md)

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet                                │
└───────────┬─────────────────────────────────┬───────────────────┘
            │                                 │
            │                                 │
    ┌───────▼──────────┐              ┌──────▼────────────┐
    │   Azure DNS      │              │  Azure DNS        │
    │ app.domain.com   │              │  api.domain.com   │
    └───────┬──────────┘              └──────┬────────────┘
            │                                 │
            │                                 │
    ┌───────▼──────────┐              ┌──────▼────────────┐
    │   App Service    │              │ Application       │
    │   (Node.js)      │              │ Gateway           │
    │                  │              │ (Standard_v2)     │
    │  • Managed SSL   │              │                   │
    │  • Auto-renewal  │              │  • SSL Cert from  │
    │  • S1 Tier       │              │    Key Vault      │
    └──────────────────┘              │  • HTTP→HTTPS     │
                                      │  • Health Probes  │
                                      └──────┬────────────┘
                                             │
                                      ┌──────▼────────────┐
                                      │   Virtual         │
                                      │   Network         │
                                      │                   │
                                      │  ┌─────────────┐  │
                                      │  │ Windows VM  │  │
                                      │  │ (IIS)       │  │
                                      │  │ Private IP  │  │
                                      │  └─────────────┘  │
                                      └───────────────────┘

    ┌─────────────────────────────────────────────────────┐
    │              Shared Services                        │
    ├─────────────────────────────────────────────────────┤
    │  • Key Vault (certificates, secrets)                │
    │  • Application Insights (monitoring)                │
    │  • Log Analytics (logs & metrics)                   │
    │  • Azure Monitor (alerts)                           │
    └─────────────────────────────────────────────────────┘
```

## 🔐 Security Features

- ✅ HTTPS enforced on all endpoints
- ✅ Managed identities (no passwords in code)
- ✅ Key Vault with RBAC
- ✅ Network isolation for VM
- ✅ Network Security Groups with least privilege
- ✅ Purge protection on Key Vault
- ✅ TLS 1.2 minimum
- ✅ Auto-patching enabled on VM

## 💰 Estimated Costs

~$446/month (West Europe):
- App Service S1: $70
- VM Standard_DS2_v2: $100
- Application Gateway v2: $250
- Other services: $26

See [iac/README.md](iac/README.md) for detailed breakdown.

## 📝 Configuration

All configuration is in `iac/terraform.tfvars`:

```hcl
location     = "westeurope"
domain_name  = "yourdomain.com"
alert_email  = "alerts@yourdomain.com"
vm_admin_password = "SecurePassword123!"
```

## 🔍 Monitoring

### SSL Certificate Alerts

Automatic email alerts at:
- 30 days before expiration
- 14 days before expiration
- 7 days before expiration

### Application Monitoring

- Application Insights for App Service
- Health probes on Application Gateway
- Log Analytics for all resources
- Email notifications via Action Groups

## 🛠️ Operations

### View Outputs

```powershell
terraform output
```

### Update Infrastructure

```powershell
terraform plan
terraform apply
```

### Scale Resources

Edit `terraform.tfvars` and apply:
```hcl
app_service_sku_name = "P1v2"  # Upgrade to Premium
vm_size = "Standard_D4s_v3"     # Larger VM
```

### Destroy

```powershell
terraform destroy
```

## 📚 Documentation

- [Infrastructure README](iac/README.md) - Complete deployment guide
- [Application README](app/README.md) - Node.js app documentation
- [GitHub Actions Setup](GITHUB_ACTIONS_SETUP.md) - CI/CD deployment guide
- [Terraform Modules](iac/modules/) - Individual module docs

## 🤝 Contributing

1. Make changes in a feature branch
2. Test with `terraform plan`
3. Submit pull request

## 📄 License

MIT License - See LICENSE file

## 🆘 Support

For issues:
1. Check [iac/README.md](iac/README.md) troubleshooting section
2. Review Azure Portal logs
3. Check Terraform state: `terraform show`

---

**Generated**: November 2025  
**Terraform Version**: >= 1.5.0  
**Azure Provider**: ~> 3.80
