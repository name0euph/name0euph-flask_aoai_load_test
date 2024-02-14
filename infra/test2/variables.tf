variable "env" {
  type        = string
  description = "環境名 dev/stg/prod"
}

variable "company" {
  type        = string
  description = ""
}

variable "location" {
  type        = string
  default     = "japaneast"
  description = "リソースのリージョン"
}