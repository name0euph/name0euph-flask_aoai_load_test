# Log Analyticsワークスペースを作成
resource "azurerm_log_analytics_workspace" "log" {
  # リソース名を log-aoaiapp-{会社名} とする
  # 例: log-aoaiapp-jfest
  name                = "log-aoaiapp-${var.company}"
  location            = var.location
  resource_group_name = var.rg_name

  # データ保持期間を90日に設定
  retention_in_days = 90

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

# App ServiceのLog Analyticsへの転送設定
resource "azurerm_monitor_diagnostic_setting" "applog_to_logs" {
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