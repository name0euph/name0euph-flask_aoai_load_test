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
    },
    snet-apiint = {
      address_prefixes = "10.0.1.0/24"
      service_name = "Microsoft.ApiManagement/service"
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
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
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
    },
    westus2 = {
      location = "westus2"
    }
  }
}

# Azure OpenAI Serviceを作成
module "aoai" {
  source = "../modules/ai"
  for_each = local.aoai_location

  env = var.env
  company = var.company
  location = each.value.location
  rg_name = azurerm_resource_group.rg.name
  vnet_id = azurerm_virtual_network.vnet.id
  pep_subnet_id = azurerm_subnet.pep_subnet.id
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

