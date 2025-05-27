# LabCharles/outputs.tf

# Output for the public IP of your first VM
output "vm1_public_ip" {
  description = "The public IP address of the first VM."
  value       = azurerm_public_ip.main[0].ip_address
}

# Output for the public IP of your second VM
output "vm2_public_ip" {
  description = "The public IP address of the second VM."
  value       = azurerm_public_ip.main[1].ip_address
}
