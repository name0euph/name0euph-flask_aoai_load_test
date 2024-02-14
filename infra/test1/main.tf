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
module "vitrual_network" {
  source = "../modules/virtual-network"

  env      = var.env
  company  = var.company
  location = var.location
  rg_name  = azurerm_resource_group.rg.name
}

# Azure OpenAI Serviceを作成
module "azure_openai_service" {
  source = "../modules/ai"

  env           = var.env
  company       = var.company
  location      = var.location
  rg_name       = azurerm_resource_group.rg.name
  vnet_id       = module.vitrual_network.vnet_id
  pep_subnet_id = module.vitrual_network.pep_subnet_id
}

# Azure AI Translationを作成
module "azure_translater_service" {
  source = "../modules/translater"

  env           = var.env
  company       = var.company
  location      = var.location
  rg_name       = azurerm_resource_group.rg.name
  vnet_id       = module.vitrual_network.vnet_id
  pep_subnet_id = module.vitrual_network.pep_subnet_id
}

# App Service Plan/App Serviceを作成
module "app_service" {
  source = "../modules/host"

  env               = var.env
  company           = var.company
  location          = var.location
  rg_name           = azurerm_resource_group.rg.name
  vnetint_subnet_id = module.vitrual_network.vnetint_subnet_id
  aoai_name         = module.azure_openai_service.aoai_name
  aoai_key          = module.azure_openai_service.aoai_key
  cosmosdb_name     = module.cosmos_db.cosmosdb_name
  cosmosdb_key      = module.cosmos_db.cosmosdb_key
  trsl_name         = ""
  trsl_key          = ""
}

# Cosmos DBを作成
module "cosmos_db" {
  source = "../modules/cosmos"

  env           = var.env
  company       = var.company
  location      = var.location
  rg_name       = azurerm_resource_group.rg.name
  vnet_id       = module.vitrual_network.vnet_id
  pep_subnet_id = module.vitrual_network.pep_subnet_id
}

# Azure Load testを作成
resource "azurerm_load_test" "load_test" {
  # リソース名を lt-{会社名}-{環境名} とする
  # 例: lt-jfest-dev
  name                = "lt-${var.company}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

/*
# Application Insightsを作成
resource "azurerm_application_insights" "app_insights" {
  # リソース名を ai-{会社名}-{環境名} とする。
  name                = "ai-${var.company}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Application Insightsの種類をotherにする
  application_type = "other"

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}
*/
