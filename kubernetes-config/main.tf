terraform {

  required_providers {

    datadog = {
      source = "DataDog/datadog"
    }
  }
}


resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}

resource "kubernetes_deployment" "test" {
  metadata {
    name = "test"
    namespace= kubernetes_namespace.test.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "test"
      }
    }
    template {
      metadata {
        labels = {
          app  = "test"
        }
      }
      spec {
        container {
          image = "nginx:1.19.4"
          name  = "nginx"

          resources {
            limits = {
              memory = "512M"
              cpu = "1"
            }
            requests = {
              memory = "256M"
              cpu = "50m"
            }
          }
        }
      }
    }
  }
}



resource "local_file" "kubeconfig" {
  content = var.spec.kubeconfig
  filename = "${path.root}/kubeconfig"
}

