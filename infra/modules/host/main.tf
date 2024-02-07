# App service planを作成
resource "azurerm_service_plan" "asp" {
  # リソース名を asp-{会社名}-{環境名} とする
  # 例: asp-jfest-dev
  name                = "asp-${var.company}-${var.env}"
  location            = var.location
  resource_group_name = var.rg_name

  os_type = "Linux"

  # App Service PlanのSKUを定義
  sku_name = "P1v2"

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

data "azuread_client_config" "current" {}

# App Serviceの名前定義用のローカル変数を定義
locals {
  # var.env = prodの場合、{会社名}aoaiapp とする
  # var.env = devの場合、{環境名}{会社名}aoaiapp とする
  app_name = var.env == "prod" ? "${var.company}aoaiapp" : "${var.env}${var.company}aoaiapp"
}

# App serviceを作成
resource "azurerm_linux_web_app" "app" {
  # リソース名を {環境名}{会社名}aoaiapp とする
  # 例: devjfestaoaiapp
  name                = local.app_name
  location            = var.location
  resource_group_name = var.rg_name

  service_plan_id = azurerm_service_plan.asp.id

  client_affinity_enabled = true
  https_only              = true

  # 仮想ネットワーク統合
  virtual_network_subnet_id = var.vnetint_subnet_id

  identity {
    type = "SystemAssigned"
  }
  site_config {
    always_on              = true
    ftps_state             = "FtpsOnly"
    http2_enabled          = true
    vnet_route_all_enabled = true
  }

  app_settings = {
    # アプリの環境変数の設定
    AZURE_COSMOSDB_ACCOUNT                   = var.cosmosdb_name
    AZURE_COSMOSDB_ACCOUNT_KEY               = var.cosmosdb_key
    AZURE_COSMOSDB_CONVERSATIONS_CONTAINER   = "conversations"
    AZURE_COSMOSDB_DATABASE                  = "db_conversation_history"
    AZURE_COSMOSDB_LOGGING_CONTAINER         = "logging"
    AZURE_OPENAI_EMBEDDING_ENDPOINT          = ""
    AZURE_OPENAI_EMBEDDING_KEY               = ""
    AZURE_OPENAI_ENDPOINT                    = ""
    AZURE_OPENAI_GPT_35_TURBO_16K_DEPLOYMENT = "ChatGPT-35-turbo-16k"
    AZURE_OPENAI_GPT_35_TURBO_DEPLOYMENT     = "ChatGPT-35-turbo"
    AZURE_OPENAI_GPT_4_32K_DEPLOYMENT        = ""
    AZURE_OPENAI_GPT_4_DEPLOYMENT            = "ChatGPT-4"
    AZURE_OPENAI_KEY                         = var.aoai_key
    AZURE_OPENAI_MODEL                       = "ChatGPT-35-turbo"
    AZURE_OPENAI_PREVIEW_API_VERSION         = "2023-06-01-preview"
    AZURE_OPENAI_RESOURCE                    = var.aoai_name
    AZURE_OPENAI_STOP_SEQUENCE               = ""
    AZURE_OPENAI_STREAM                      = ""
    SCM_DO_BUILD_DURING_DEPLOYMENT           = "True"
    TRANSLATE_ENDPOINT                       = "https://${var.trsl_name}.cognitiveservices.azure.com/translator/text/v3.0"
    TRANSLATE_KEY                            = var.trsl_key
  }
  # ログをアプリケーションコンテナーの/home配下に転送
  logs {
    detailed_error_messages = false
    failed_request_tracing  = false

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
 
  tags = {
    Environment = var.env,
    Company     = var.company
  }
}