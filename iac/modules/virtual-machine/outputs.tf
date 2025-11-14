output "vm_id" {
  description = "ID of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.main.name
}

output "private_ip_address" {
  description = "Private IP address of the Virtual Machine"
  value       = azurerm_network_interface.main.private_ip_address
}

output "vm_principal_id" {
  description = "Principal ID of the VM managed identity"
  value       = azurerm_windows_virtual_machine.main.identity[0].principal_id
}
