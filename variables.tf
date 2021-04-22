variable "location" {
  type    = string
  default = "westus2"
}
variable "datadog_api_key" {
  type = string
}

variable "datadog_app_key" {
  type = string
}

variable "tenant_name" {
  type = string
}

variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}

variable "unique_storage" {
   type = string
  default = "tfpollinatestorage"
  }


locals {
  cluster_name = "tf-k8s-pollinate"
}

