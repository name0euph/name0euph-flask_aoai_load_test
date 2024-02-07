# 仮想ネットワークを作成
resource "azurerm_virtual_network" "vnet" {
  # リソース名を vnet-{リージョン}-{会社名}-{環境名} とする
  # 例: vnet-japaneast-jfesi-dev
  name                = "vnet-${var.location}-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name

  # 仮想ネットワークのアドレス空間を定義
  address_space = ["10.0.0.0/16"]

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# App Serviceの仮想ネットワーク統合用のサブネットを作成
resource "azurerm_subnet" "vnetint_subnet" {
  # リソース名を snet-vnetintegration とする
  name                = "snet-vnetintegration"
  resource_group_name = var.rg_name

  # 仮想ネットワークと紐づけ
  virtual_network_name = azurerm_virtual_network.vnet.name

  # サブネットのアドレス空間を定義
  address_prefixes = ["10.0.0.0/24"]

  #App Serviceへ委任
  delegation {
    name = "delegation"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      name    = "Microsoft.Web/serverFarms"
    }
  }
}

# プライベートエンドポイント用のサブネットを作成
resource "azurerm_subnet" "pep_subnet" {
  # リソース名を snet-pepとする
  name                = "snet-pep"
  resource_group_name = var.rg_name

  # 仮想ネットワークと紐づけ
  virtual_network_name = azurerm_virtual_network.vnet.name

  # サブネットのアドレス空間を定義
  address_prefixes = ["10.0.1.0/24"]
}