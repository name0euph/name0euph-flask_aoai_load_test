# モジュールを呼び出してリソースを作成するmainファイル

# リソースグループの定義
resource "azurerm_resource_group" "rg" {
  # リソース名を rg-{会社名}-{リージョン} とする
  # 例: rg-jfest-japaneeast
  name     = "rg-${var.company}-${var.env}"
  location = var.location

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# Azure Load testを作成
resource "azurerm_load_test" "load_test" {
  name                = "lt-jfest-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Configure other properties of the load test as needed
  # ...

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# 仮想ネットワークを作成
module "vitrual_network" {
  source = "../../modules/virtual-network"

  env      = var.env
  company  = var.company
  location = var.location
  rg_name  = azurerm_resource_group.rg.name
}

# Azure OpenAI Serviceを作成
module "azure_openai_service" {
  source = "../../modules/ai"

  env      = var.env
  company  = var.company
  location = var.location
  rg_name  = azurerm_resource_group.rg.name

  vnet_id       = module.vitrual_network.vnet_id
  pep_subnet_id = module.vitrual_network.pep_subnet_id
}


# App Service Plan/App Serviceを作成
module "app_service" {
  source = "../../modules/host"

  env      = var.env
  company  = var.company
  location = var.location
  rg_name  = azurerm_resource_group.rg.name

  vnetint_subnet_id  = module.vitrual_network.vnetint_subnet_id
  aoai_name          = module.azure_openai_service.aoai_name
  aoai_key           = module.azure_openai_service.aoai_key
  cosmosdb_name      = module.cosmos_db.cosmosdb_name
  cosmosdb_key       = module.cosmos_db.cosmosdb_key
  auth_client_secret = var.auth_client_secret
  app_client_id      = var.app_client_id
}

# Cosmos DBを作成
module "cosmos_db" {
  source = "../../modules/cosmos"

  env      = var.env
  company  = var.company
  location = var.location
  rg_name  = azurerm_resource_group.rg.name

  vnet_id       = module.vitrual_network.vnet_id
  pep_subnet_id = module.vitrual_network.pep_subnet_id
}