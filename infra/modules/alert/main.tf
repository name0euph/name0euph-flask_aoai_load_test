# JFESI管理者通知用のアクショングループを作成
resource "azurerm_monitor_action_group" "jfesi_admin_mail" {
  # リソース名を ag-aoaiapp-{会社名} とする
  # 例: ag-aoaiapp-jfest
  name                = "ag-aoaiapp-${var.company}"
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

# サブスクリプション情報の取得
data "azurerm_subscription" "current" {
}

locals {
  category = [
    "ServiceHealth",
    "ResourceHealth",
  ]
}

# サービスヘルスおよびリソースヘルス アラートの設定
resource "azurerm_monitor_activity_log_alert" "alert_health" {
  count              = length(local.category)

  # リソース名を alert-{カテゴリ名}-{会社名} とする
  # 例: alert-ServiceHealth-jfest
  name                = "alert-${local.category[count.index]}-${var.company}"
  resource_group_name = var.rg_name

  # アラートの条件
  # サブスクリプションIDをスコープ対象とする
  scopes = ["${data.azurerm_subscription.current.id}"]
  # サービスヘルスおよびリソースヘルスのアラートを設定
  criteria {
    category = local.category[count.index]
  }

  # アラート動作
  # JFESI管理者通知用のアクショングループを設定
  action {
    action_group_id = azurerm_monitor_action_group.jfesi_admin_mail.id
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

locals {
  asp_metric_name = [
    "MemoryPercentage",
    "CpuPercentage",
  ]
  asp_threshold   = [
    80,
    80,
  ]
}

# App service planのメトリックアラートの設定
resource "azurerm_monitor_metric_alert" "asp_metric" {
  count = length(local.asp_metric_name)

  # リソース名を alert-{メトリック名}-{会社名} とする
  # 例: alert-MemoryPercentage-jfest
  name                = "alert-${local.asp_metric_name[count.index]}-${var.company}"
  resource_group_name = var.rg_name

  # アラートの条件
  # App Service Planをスコープ対象とする
  scopes = [var.asp_id]
  # メトリックの条件を設定
  # メモリは80%以上、CPUは80%以上の場合にアラートを発生させる
  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = local.asp_metric_name[count.index]
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = local.asp_threshold[count.index]
  }

  # 1分間隔、5分間のウィンドウで監視
  frequency = "PT1M"
  window_size = "PT5M"

  # アラート動作
  # JFESI管理者通知用のアクショングループを設定
  action {
    action_group_id = azurerm_monitor_action_group.jfesi_admin_mail.id
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}

locals {
  app_metric_name = [
    "Http5xx",
    "HttpResponseTime",
  ]
  app_threshold   = [
    1,
    10,
  ]
  app_window_size = [
    1,
    5
  ]
}
# App Serviceのアラートルールを作成
resource "azurerm_monitor_metric_alert" "app_metric" {
  count = length(local.app_metric_name)

  # リソース名を alert-{メトリック名}-{会社名} とする
  # 例: alert-MemoryPercentage-jfest
  name                = "alert-${local.app_metric_name[count.index]}-${var.company}"
  resource_group_name = var.rg_name

  # アラートの条件
  # App Serviceをスコープ対象とする
  scopes = [var.app_id]
  # メトリックの条件を設定
  # 5xxエラーが1回以上、レスポンスタイムが10秒以上の場合にアラートを発生させる
  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = local.app_metric_name[count.index]
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = local.app_threshold[count.index]
  }

  # 1分間隔、5xxは1分間、レスポンスタイムは5分間のウィンドウで監視
  frequency = "PT1M"
  window_size = "PT${local.app_window_size[count.index]}M"

  # アラート動作
  # JFESI管理者通知用のアクショングループを設定
  action {
    action_group_id = azurerm_monitor_action_group.jfesi_admin_mail.id
  }

  tags = {
    Environment = var.env,
    Company     = var.company
  }
}