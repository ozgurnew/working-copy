terraform {
  backend "azurerm" {
    resource_group_name  = "tf-pollinate-rg"
    #change this account name for the local unique apply
    storage_account_name = var.unique_storage
    container_name       = "tf-datadog-k8s-pollinate"
    key                  = "tf.state"
  }

  required_providers {

    datadog = {
      source = "DataDog/datadog"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.42"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
  }
}

module "aks-cluster" {
  source       = "./aks-cluster"
  cluster_name = local.cluster_name
  location     = var.location
}

module "kubernetes-config" {
  depends_on   = [module.aks-cluster]
  source       = "./kubernetes-config"

  spec = {
    api_key   = var.datadog_api_key
    app_key   = var.datadog_app_key
    cluster_name = local.cluster_name
    kubeconfig   = data.azurerm_kubernetes_cluster.default.kube_config_raw
    tenant_name = var.tenant_name
    client_secret = var.client_secret
    client_id = var.client_id
  }

}
data "azurerm_kubernetes_cluster" "default" {
  depends_on          = [module.aks-cluster] # refresh cluster state before reading
  name                = local.cluster_name
  resource_group_name = local.cluster_name
}
