# モジュールを呼び出してリソースを作成するmainファイル
# リソースグループの定義
resource "azurerm_resource_group" "rg" {
  # リソース名を rg-{会社名}-{リージョン} とする
  name     = "rg-${var.company}-${var.env}"
  location = var.location

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# 仮想ネットワークを作成
resource "azurerm_virtual_network" "vnet" {
  # リソース名を vnet-{リージョン}-{会社名}-{環境名} とする
  # 例: vnet-japaneast-jfesi-dev
  name                = "vnet-${var.location}-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # 仮想ネットワークのアドレス空間を定義
  address_space = ["10.0.0.0/16"]

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

locals {
  subnets = {
    snet-appint = {
      address_prefixes = "10.0.0.0/24"
      service_name = "Microsoft.Web/serverFarms"
      service_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    },
    snet-apiint = {
      address_prefixes = "10.0.1.0/24"
      service_name = "Microsoft.ApiManagement/service"
      service_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action","Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

# 仮想ネットワーク統合用のサブネットを作成
resource "azurerm_subnet" "appint_subnet" {
  for_each = local.subnets

  # リソース名をkeyから取得
  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
  # 仮想ネットワークと紐づけ
  virtual_network_name = azurerm_virtual_network.vnet.name
  # サブネットのアドレス空間を定義
  address_prefixes = [each.value.address_prefixes]

  #App Serviceへ委任
  delegation {
    name = "delegation"
    service_delegation {
      actions = each.value.service_actions
      name    = each.value.service_name
    }
  }
}

# プライベートエンドポイント用のサブネットを作成
resource "azurerm_subnet" "pep_subnet" {
  # リソース名を snet-pepとする
  name                = "snet-pep"
  resource_group_name = azurerm_resource_group.rg.name
  # 仮想ネットワークと紐づけ
  virtual_network_name = azurerm_virtual_network.vnet.name
  # サブネットのアドレス空間を定義
  address_prefixes = ["10.0.2.0/24"]
}


locals {
  aoai_location = {
    japaneast = {
      location = "japaneast"
      model_version = "0613"
    },
    westus = {
      location = "westus"
      model_version = "1106"
    }
  }
}

# Azure OpenAI Serviceを作成
# コグニティブサービスアカウントの作成
resource "azurerm_cognitive_account" "cogac" {
  for_each = local.aoai_location

  # リソース名を aoai-{会社名}-{場所名} とする
  # 例: aoai-jfest-japaneast
  name                = "aoai-${var.company}-${each.value.location}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name

  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "aoai-${var.company}-${each.value.location}"

  #外部ネットワークからのアクセスを拒否
  public_network_access_enabled = false

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# gpt-35-turboのモデルを作成
resource "azurerm_cognitive_deployment" "aoai_35-turbo" {
  for_each = local.aoai_location

  # モデルの名前を定義
  name = "ChatGPT-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.cogac[each.key].id

  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = each.value.model_version
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
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# プライベートDNSゾーンと仮想ネットワークを接続
resource "azurerm_private_dns_zone_virtual_network_link" "dns_attach_aoai" {
  name                = "dnsvnet-aoai-${var.env}"
  resource_group_name = azurerm_resource_group.rg.name

  private_dns_zone_name = azurerm_private_dns_zone.dns_zone_aoai.name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  depends_on = [
    azurerm_private_dns_zone.dns_zone_aoai,
  ]
}

# Azure OpenAIのプライベートエンドポイントを作成
resource "azurerm_private_endpoint" "pep_aoai" {
  for_each = local.aoai_location

  # リソース名を pep-aoai-{会社名}-{リージョン} とする
  # 例: pep-aoai-jfest-japaneast
  name                = "pep-aoai-${var.company}-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pep_subnet.id
  custom_network_interface_name = "nic-pep-aoai-${var.company}-${each.key}"

  private_service_connection {
    name                           = azurerm_cognitive_account.cogac[each.key].name
    private_connection_resource_id = azurerm_cognitive_account.cogac[each.key].id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "pepdns-aoai-${each.key}"
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

# App Serviceを作成
module "app_service" {
  source = "../modules/host"

  env = var.env
  company = var.company
  location = var.location
  rg_name = azurerm_resource_group.rg.name
  vnetint_subnet_id = azurerm_subnet.appint_subnet["snet-appint"].id
  aoai_name = ""
  aoai_key = ""
  cosmosdb_name = ""
  cosmosdb_key = ""
  trsl_name = ""
  trsl_key = ""
}

# API Managementを作成
resource "azurerm_api_management" "apim" {
  name                = "apim-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "My Company"
  publisher_email     = "ryouta-arisaka@jfe-systems.com"

  sku_name = "Developer_1"
  virtual_network_type = "Internal"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.appint_subnet["snet-apiint"].id
  }
}

# Log Analyticsを作成
module "log_analytics" {
  source = "../modules/log"

  env     = var.env
  company = var.company
  location = var.location
  rg_name = azurerm_resource_group.rg.name
  app_id = module.app_service.app_id
}

# Application Insightsを作成
resource "azurerm_application_insights" "app_insights" {
  # リソース名を ai-{会社名}-{環境名} とする。
  name                = "ai-${var.company}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # Log Analyticsと連携
  workspace_id = module.log_analytics.log_id
  # Application Insightsの種類をotherにする
  application_type = "other"

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}