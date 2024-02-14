# コグニティブサービスアカウントの作成
resource "azurerm_cognitive_account" "cogac" {
  # リソース名を aoai-{会社名}-{環境名} とする
  # 例: aoai-jfest-dev
  name                = "aoai-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name

  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "aoai-${var.company}-${var.env}"

  #外部ネットワークからのアクセスを拒否
  public_network_access_enabled = false

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# gpt-35-turboのモデルを作成
resource "azurerm_cognitive_deployment" "aoai_35-turbo" {
  # モデルの名前を定義
  name = "ChatGPT-35-turbo"

  cognitive_account_id = azurerm_cognitive_account.cogac.id

  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0613"
  }

  scale {
    capacity = 120
    type     = "Standard"
  }

  rai_policy_name = "Microsoft.Default"

  depends_on = [
    azurerm_cognitive_account.cogac,
  ]
}

resource "azurerm_cognitive_deployment" "aoai_35-turbo-16k" {
  name = "ChatGPT-35-turbo-16k"

  cognitive_account_id = azurerm_cognitive_account.cogac.id

  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo-16k"
    version = "0613"
  }

  scale {
    capacity = 120
    type     = "Standard"
  }

  rai_policy_name = "Microsoft.Default"

  depends_on = [
    azurerm_cognitive_account.cogac,
  ]
}

# gpt-4のモデルを作成
resource "azurerm_cognitive_deployment" "aoai_gpt-4" {
  # モデルの名前を定義
  name = "ChatGPT-4"

  cognitive_account_id = azurerm_cognitive_account.cogac.id

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = "0613"
  }

  scale {
    capacity = 10
    type     = "Standard"
  }

  rai_policy_name = "Microsoft.Default"

  depends_on = [
    azurerm_cognitive_account.cogac,
  ]
}

# プライベートDNSゾーンを作成
resource "azurerm_private_dns_zone" "dns_zone_aoai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.rg_name

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# プライベートDNSゾーンと仮想ネットワークを接続
resource "azurerm_private_dns_zone_virtual_network_link" "dns_attach_aoai" {
  name                = "dnsvnet-aoai-${var.env}"
  resource_group_name = var.rg_name

  private_dns_zone_name = azurerm_private_dns_zone.dns_zone_aoai.name
  virtual_network_id    = var.vnet_id

  depends_on = [
    azurerm_private_dns_zone.dns_zone_aoai,
  ]
}

# Azure OpenAIのプライベートエンドポイントを作成
resource "azurerm_private_endpoint" "pep_aoai" {
  # リソース名を pep-aoai-{会社名}-{環境名} とする
  # 例: pep-aoai-jfest-dev
  name                = "pep-aoai-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.pep_subnet_id
  custom_network_interface_name = "nic-pep-aoai-${var.company}-${var.env}"

  private_service_connection {
    name                           = azurerm_cognitive_account.cogac.name
    private_connection_resource_id = azurerm_cognitive_account.cogac.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "pepdns-aoai-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone_aoai.id]
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }

  depends_on = [
    azurerm_cognitive_account.cogac,
  ]
}