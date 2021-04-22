#Azure Region
variable "location" {
  type    = string
  default = "westus2"
}

#ENV datadogApiKey https://app.datadoghq.com/account/settings#api
variable "datadog_api_key" {
  type = string
}

#ENV datadogAppKey https://app.datadoghq.com/access/application-keys
variable "datadog_app_key" {
  type = string
}

#ENV armTenantId 
variable "tenant_name" {
  type = string
}

#ENV armClientId 
variable "client_id" {
  type = string
}

#ENV armClientSecret
variable "client_secret" {
  type = string
}

#ENV uniqueStorage
variable "unique_storage" {
   type = string
  #change default with correct storage for local apply
  default = "tfpollinatestorage"
  }


locals {
  cluster_name = "tf-k8s-pollinate"
}

