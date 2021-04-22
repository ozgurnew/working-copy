
variable "spec" {
  type = object({
    kubeconfig = string
    cluster_name = string
    api_key   = string
    app_key   = string
    tenant_name = string
    client_id = string
    client_secret = string
  })
}
