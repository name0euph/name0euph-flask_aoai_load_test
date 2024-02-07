output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
output "vnetint_subnet_id" {
  value = azurerm_subnet.vnetint_subnet.id
}
output "pep_subnet_id" {
  value = azurerm_subnet.pep_subnet.id
}