# CosmosDBアカウントを作成
resource "azurerm_cosmosdb_account" "cosmosdb_account" {
  # リソース名を cosmos-{会社名}-{環境名} とする
  # 例: cosmos-jfest-dev
  name                = "cosmos-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name

  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = false

  ip_range_filter               = "153.143.185.32/27,101.143.241.144/27,104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26"
  public_network_access_enabled = true

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # 整合性レベルの定義
  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# SQLデータベースを定義
resource "azurerm_cosmosdb_sql_database" "cosmosdb_sql" {
  name                = "db_conversation_history"
  resource_group_name = var.rg_name

  account_name = azurerm_cosmosdb_account.cosmosdb_account.name
  depends_on   = [azurerm_cosmosdb_account.cosmosdb_account]
}

# 会話を保管するSQL DBのコンテナを定義
resource "azurerm_cosmosdb_sql_container" "conversations" {
  name                = "conversations"
  resource_group_name = var.rg_name

  account_name       = azurerm_cosmosdb_account.cosmosdb_account.name
  database_name      = azurerm_cosmosdb_sql_database.cosmosdb_sql.name
  partition_key_path = "/userId"
  depends_on         = [azurerm_cosmosdb_sql_database.cosmosdb_sql]
}

# ログ保管するSQL DBのコンテナを定義
resource "azurerm_cosmosdb_sql_container" "logging" {
  name                = "logging"
  resource_group_name = var.rg_name

  account_name          = azurerm_cosmosdb_account.cosmosdb_account.name
  database_name         = azurerm_cosmosdb_sql_database.cosmosdb_sql.name
  partition_key_version = 2
  partition_key_path    = "/userId"
  depends_on            = [azurerm_cosmosdb_sql_database.cosmosdb_sql]
}

# プライベートDNSゾーンを作成
resource "azurerm_private_dns_zone" "dns_zone_cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.rg_name

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# プライベートDNSゾーンと仮想ネットワークを接続
resource "azurerm_private_dns_zone_virtual_network_link" "dns_attach_cosmos" {
  name                = "dnsvnet-cosmos-${var.env}"
  resource_group_name = var.rg_name

  private_dns_zone_name = azurerm_private_dns_zone.dns_zone_cosmos.name
  virtual_network_id    = var.vnet_id

  depends_on = [
    azurerm_private_dns_zone.dns_zone_cosmos,
  ]
}


# CosmosDBのプライベートエンドポイントを作成
resource "azurerm_private_endpoint" "pep_cosmos" {
  # リソース名を pep-cosmos-{会社名}-{環境名} とする
  # 例: pep-cosmos-jfest-dev
  name                = "pep-cosmos-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.pep_subnet_id
  custom_network_interface_name = "nic-pep-cosmos-${var.company}-${var.env}"

  private_service_connection {
    name                           = azurerm_cosmosdb_account.cosmosdb_account.name
    private_connection_resource_id = azurerm_cosmosdb_account.cosmosdb_account.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "pepdns-cosmos-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone_cosmos.id]
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }

  depends_on = [
    azurerm_cosmosdb_account.cosmosdb_account
  ]
}