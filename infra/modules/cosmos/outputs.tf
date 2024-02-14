output "cosmosdb_key" {
  value = azurerm_cosmosdb_account.cosmosdb_account.primary_key
}
output "cosmosdb_name" {
  value = azurerm_cosmosdb_account.cosmosdb_account.name
}