output "kubeconfig_path" {
  value = abspath("${path.root}/kubeconfig")
}

output "cluster_name" {
  value = local.cluster_name
}
output "datadog_app_key" {
  value = var.datadog_app_key
  sensitive = true
}
output "datadog_api_key" {
  value = var.datadog_api_key
  sensitive = true
}
