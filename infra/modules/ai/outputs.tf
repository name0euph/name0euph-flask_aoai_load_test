output "aoai_name" {
  value = azurerm_cognitive_account.cogac.name
}
output "aoai_key" {
  value = azurerm_cognitive_account.cogac.primary_access_key
}