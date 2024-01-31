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

# Application Insightsを作成
