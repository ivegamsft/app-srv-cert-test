output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "appgw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = azurerm_subnet.appgw.id
}

output "vm_subnet_id" {
  description = "ID of the VM subnet"
  value       = azurerm_subnet.vm.id
}

output "appgw_public_ip_id" {
  description = "ID of the Application Gateway public IP"
  value       = azurerm_public_ip.appgw.id
}

output "appgw_public_ip_address" {
  description = "IP address of the Application Gateway public IP"
  value       = azurerm_public_ip.appgw.ip_address
}
