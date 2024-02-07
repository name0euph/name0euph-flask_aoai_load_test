# Log Analyticsワークスペースを作成
resource "azurerm_log_analytics_workspace" "log" {
  # リソース名を log-aoaiapp-{会社名} とする
  # 例: log-aoaiapp-jfest
  name                = "log-aoaiapp-${var.company}"
  location            = var.location
  resource_group_name = var.rg_name

  retention_in_days = 90

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# App ServiceのLog Analyticsへの転送設定
resource "azurerm_monitor_diagnostic_setting" "app_console_logs" {
  name = "Console and HTTP Logs"

  target_resource_id         = var.app_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id

  # App ServiceのAppServiceConcoleLogをLog Analyticsに転送
  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  # App ServiceのHTTPログをLog Analyticsに転送
  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  # Metricsは転送しない
  metric {
    category = "AllMetrics"
    enabled  = false
  }
}

# JFE管理者通知用のアクショングループを作成
resource "azurerm_monitor_action_group" "admin_mail" {
  name                = "ag-jfesi-admin"
  resource_group_name = var.rg_name

  short_name = "JFE-SI Admin"

  email_receiver {
    email_address = "ryouta-arisaka@jfe-systems.com"
    name          = "ryouta-arisaka_-EmailAction-"
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# サブスクリプションIDを取得するためのdataを宣言
data "azurerm_subscription" "current" {
}

# サービスヘルスアラートの設定
resource "azurerm_monitor_activity_log_alert" "service_health" {
  name                = "alert-service-health"
  resource_group_name = var.rg_name

  # サブスクリプションIDをスコープ対象とする
  scopes = ["${data.azurerm_subscription.current.id}"]

  action {
    action_group_id = azurerm_monitor_action_group.admin_mail.id
  }
  criteria {
    category = "ServiceHealth"
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}