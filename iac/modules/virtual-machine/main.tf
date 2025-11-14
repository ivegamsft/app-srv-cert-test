# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "nic-vm-${var.prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name                = "vm-${var.prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    name                 = "osdisk-vm-${var.prefix}-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable automatic updates
  patch_mode = "AutomaticByPlatform"
  
  # Enable boot diagnostics
  boot_diagnostics {
    storage_account_uri = null  # Uses managed storage account
  }
}

# VM Extension to install IIS
resource "azurerm_virtual_machine_extension" "iis" {
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.main.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<-EOT
      powershell -ExecutionPolicy Unrestricted -Command "
        # Install IIS
        Install-WindowsFeature -name Web-Server -IncludeManagementTools;
        
        # Install ASP.NET 4.8
        Install-WindowsFeature Web-Asp-Net45;
        
        # Create a simple default page
        Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value '<html><head><title>Welcome</title></head><body><h1>IIS Server on Azure</h1><p>Server: $env:COMPUTERNAME</p><p>Time: $(Get-Date)</p></body></html>';
        
        # Configure firewall
        New-NetFirewallRule -DisplayName 'Allow HTTP' -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow;
        New-NetFirewallRule -DisplayName 'Allow HTTPS' -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow;
        
        # Start IIS
        Start-Service W3SVC;
        Set-Service W3SVC -StartupType Automatic;
      "
    EOT
  })

  tags = var.tags
}

# Grant VM access to Key Vault secrets
resource "azurerm_role_assignment" "vm_kv_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.main.identity[0].principal_id
}
