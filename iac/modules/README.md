# Terraform Modules

This folder contains reusable Terraform modules for managing various Azure resources. Each module is designed to be self-contained and configurable.

## Modules

1. **App Gateway**:
   - Path: `app-gateway/`
   - Manages Azure Application Gateway resources.

2. **App Service**:
   - Path: `app-service/`
   - Manages Azure App Service resources.

3. **Key Vault**:
   - Path: `key-vault/`
   - Manages Azure Key Vault resources.

4. **Monitoring**:
   - Path: `monitoring/`
   - Manages Azure Monitor and Application Insights resources.

5. **Networking**:
   - Path: `networking/`
   - Manages Azure Virtual Network and related resources.

6. **Virtual Machine**:
   - Path: `virtual-machine/`
   - Manages Azure Virtual Machine resources.

## Usage

1. Navigate to the desired module folder.
2. Review the `README.md` file in the module folder for specific instructions.
3. Include the module in your Terraform configuration using the `module` block.

## Notes
- Ensure that `variables.tf` and `outputs.tf` are configured correctly for each module.
- Refer to the root `README.md` for overall project setup.