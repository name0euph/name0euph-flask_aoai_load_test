variable "env" {
  type        = string
  description = "環境名 dev/stg/prod"
}

variable "company" {
  type        = string
  description = "案件の発注会社名"
}

variable "location" {
  type        = string
  default     = "japaneast"
  description = "リソースのリージョン"
}

variable "auth_client_secret" {
  type        = string
  default     = ""
  description = "Enterprise ApplicantionのClient Secret"
}

variable "app_client_id" {
  type        = string
  default     = ""
  description = "Enterprise ApplicantionのClient ID"
}