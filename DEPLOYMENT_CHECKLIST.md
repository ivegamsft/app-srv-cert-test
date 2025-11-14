# Deployment Checklist

Use this checklist to ensure a successful deployment.

## Pre-Deployment

- [ ] Azure subscription is active and accessible
- [ ] Terraform is installed (`terraform --version`)
- [ ] Azure CLI is installed (`az --version`)
- [ ] Logged into Azure (`az login`)
- [ ] Selected correct subscription (`az account show`)
- [ ] Domain name is ready (or will purchase)
- [ ] Email address for alerts is configured

## Configuration

- [ ] Copied `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Updated `domain_name` in terraform.tfvars
- [ ] Updated `alert_email` in terraform.tfvars
- [ ] Set secure `vm_admin_password` in terraform.tfvars
- [ ] Reviewed and adjusted resource SKUs if needed
- [ ] Verified `location` is correct (default: westeurope)

## Initial Deployment

- [ ] Navigate to `iac/` directory
- [ ] Run `terraform init` successfully
- [ ] Run `terraform validate` - no errors
- [ ] Run `terraform plan` and review output
- [ ] Run `terraform apply` and approve
- [ ] Deployment completed (15-20 minutes)
- [ ] Captured output values (nameservers, URLs, etc.)

## DNS Configuration

- [ ] Noted the DNS zone nameservers from output
- [ ] Logged into domain registrar
- [ ] Updated nameservers at registrar
- [ ] Waited 24-48 hours for DNS propagation
- [ ] Verified DNS with `nslookup yourdomain.com`

## SSL Certificates

### App Service
- [ ] Managed certificate auto-created by Azure
- [ ] Custom domain binding successful
- [ ] HTTPS working on app.yourdomain.com

### Application Gateway
- [ ] Self-signed certificate created in Key Vault
- [ ] Application Gateway using certificate from Key Vault
- [ ] (Optional) Uploaded production certificate to Key Vault
- [ ] HTTPS working on api.yourdomain.com

## Application Deployment

### App Service
- [ ] Node.js application code ready
- [ ] Dependencies defined in package.json
- [ ] Deployed via ZIP, Git, or CI/CD
- [ ] Application running and accessible
- [ ] Tested https://app.yourdomain.com

### Virtual Machine
- [ ] RDP access tested (if needed)
- [ ] IIS is running
- [ ] Default page displays
- [ ] (Optional) Custom application deployed to IIS
- [ ] Tested https://api.yourdomain.com

## Monitoring & Alerts

- [ ] Application Insights receiving telemetry
- [ ] Log Analytics Workspace configured
- [ ] SSL expiration alerts configured
- [ ] Test email received (or verified Action Group)
- [ ] Health probe alerts working
- [ ] Reviewed logs in Azure Portal

## Security Verification

- [ ] Key Vault purge protection enabled
- [ ] Managed identities assigned to resources
- [ ] Network Security Groups in place
- [ ] HTTPS enforced (HTTP redirects to HTTPS)
- [ ] TLS 1.2 minimum enforced
- [ ] VM in private subnet (no public IP)
- [ ] No hardcoded credentials in code

## Testing

- [ ] App Service URL responds: https://app.yourdomain.com
- [ ] Application Gateway URL responds: https://api.yourdomain.com
- [ ] HTTP automatically redirects to HTTPS
- [ ] SSL certificates valid (no browser warnings)
- [ ] Health check endpoints responding
- [ ] Application functionality working
- [ ] Load test passed (optional)

## Documentation

- [ ] Documented resource names and IDs
- [ ] Saved Terraform outputs
- [ ] Recorded VM admin credentials (in Key Vault)
- [ ] Updated team documentation
- [ ] Saved DNS configuration details

## Post-Deployment

- [ ] Verified monthly cost estimates in Azure Portal
- [ ] Set up cost alerts (if needed)
- [ ] Configured backup strategy (if required)
- [ ] Scheduled maintenance windows
- [ ] Reviewed Application Insights dashboards
- [ ] Tested alert notifications

## Production Readiness

- [ ] Replace self-signed certificate with production cert
- [ ] Configure CI/CD pipeline
- [ ] Set up staging environment (optional)
- [ ] Document runbook for common operations
- [ ] Train team on Azure resources
- [ ] Establish monitoring schedule
- [ ] Plan for certificate renewal

## Rollback Plan

- [ ] Terraform state file backed up
- [ ] Previous configuration documented
- [ ] Rollback procedure tested
- [ ] Emergency contacts list created

---

## Quick Commands Reference

```powershell
# View all outputs
terraform output

# Get specific output
terraform output dns_zone_nameservers

# View resource group in portal
terraform output resource_group_name

# Tail App Service logs
az webapp log tail --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw app_service_name)

# View Key Vault
az keyvault show --name $(terraform output -raw key_vault_name)
```

## Troubleshooting Contacts

- **Azure Support**: [Azure Portal](https://portal.azure.com) → Help + Support
- **Terraform Issues**: [Terraform Registry](https://registry.terraform.io/)
- **DNS Issues**: Contact domain registrar support

---

**Last Updated**: November 2025  
**Version**: 1.0
