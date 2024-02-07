# Azure_AI_Translaterの定義
resource "azurerm_cognitive_account" "trsl" {
  # リソース名を trsl-{会社名}-{環境名} とする
  # 例: trsl-jfest-dev
  name                = "trsl-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name

  kind                  = "TextTranslation"
  sku_name              = "S1"
  custom_subdomain_name = "trsl-${var.company}-${var.env}"

  #外部ネットワークからのアクセスを拒否
  public_network_access_enabled = false

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# プライベートDNSゾーンを作成
resource "azurerm_private_dns_zone" "dns_zone_trsl" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = var.rg_name

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# プライベートDNSゾーンと仮想ネットワークを接続
resource "azurerm_private_dns_zone_virtual_network_link" "dns_attach_trsl" {
  name                = "dnsvnet-trsl-${var.env}"
  resource_group_name = var.rg_name

  private_dns_zone_name = azurerm_private_dns_zone.dns_zone_trsl.name
  virtual_network_id    = var.vnet_id

  depends_on = [
    azurerm_private_dns_zone.dns_zone_trsl,
  ]
}

# AzureAITranslaterのプライベートエンドポイントを作成
resource "azurerm_private_endpoint" "pep_trsl" {
  # リソース名を pep-trsl-{会社名}-{環境名} とする
  # 例: pep-trsl-jfest-dev
  name                = "pep-trsl-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.pep_subnet_id
  custom_network_interface_name = "nic-pep-trsl-${var.company}-${var.env}"

  private_service_connection {
    name                           = azurerm_cognitive_account.trsl.name
    private_connection_resource_id = azurerm_cognitive_account.trsl.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "pepdns-trsl-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone_trsl.id]
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }

  depends_on = [
    azurerm_cognitive_account.trsl,
  ]
}