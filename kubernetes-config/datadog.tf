
resource "datadog_integration_azure" "sandbox" {
  tenant_name   = var.spec.tenant_name
  client_id     = var.spec.client_id
  client_secret = var.spec.client_secret
}

resource "helm_release" "datadog_agent" {
  namespace = "default"
  name       = "datadog-agent"
  chart      = "datadog"
  repository = "https://helm.datadoghq.com"

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.spec.api_key
  }

  set_sensitive {
    name  = "datadog.appKey"
    value = var.spec.app_key
  }

  values = [
    file("datadog.yaml")
  ]
}

resource "datadog_monitor" "cpumonitor" {
  name = "cpu monitor"
  type = "metric alert"
  message = "CPU usage alert"
  query = "avg(last_1m):avg:system.cpu.system{*} by {host} > 60"
}




resource "datadog_dashboard" "ordered_dashboard" {
  title        = "Pollinate Kubernetes Dashboard"
  description  = "Created using the Datadog provider in Terraform"
  layout_type  = "ordered"
  is_read_only = true
  depends_on = [datadog_monitor.cpumonitor]

  widget {
    query_value_definition {
      request {
        q          = "avg:kubernetes.pods.running{*}"
        aggregator = "avg"
      }

      autoscale   = true

      precision   = "2"
      text_align  = "right"
      title       = "Average Kubernetes Pods Running"
      title_align = "left"
      title_size = "16"
    }
    widget_layout {
      x= 0
      y= 0
      width= 4
      height= 4
    }
  }
  widget {
    layout = {
      x= 6
      y= 0
      width= 4
      height= 4
    }
    query_value_definition {
      request {
        q          = "avg:kubernetes_state.node.memory_allocatable{*}"
        aggregator = "avg"
      }

      autoscale   = true

      precision   = "2"
      text_align  = "right"
      title       = "Remaining Allocatable Memory"
      title_align = "left"
      title_size = "16"
    }
  }

  widget {
    layout = {
      x= 0
      y= 5
      width= 4
      height= 4
    }
    query_value_definition {
      request {
        q          = "avg:system.cpu.user{*}"
        aggregator = "avg"
      }

      autoscale   = true

      precision   = "2"
      text_align  = "right"
      title       = "Avg CPU Usage Percentage"
      title_align = "left"
      title_size = "16"
    }
  }
  widget {
    widget_layout {
      x= 6
      y= 5
      width= 4
      height= 4
    }
    query_value_definition {
      request {
        q          = "avg:kubernetes.containers.restarts{*}"
        aggregator = "avg"
      }

      autoscale   = true

      precision   = "2"
      text_align  = "right"
      title       = "Number Of Restarts"
      title_align = "left"
      title_size = "16"
    }
  }

  widget {
    layout = {
      x= 0
      y= 5
      width= 4
      height= 4
    }
    query_value_definition {
      request {
        q          = "avg:kubernetes_state.pdb.pods_healthy{*}"
        aggregator = "avg"
      }

      autoscale   = true

      precision   = "2"
      text_align  = "right"
      title_align = "left"
      title_size = "16"
    }
  }

  widget {
    layout = {
      x= 6
      y= 34
      width= 4
      height= 4
    }
    query_value_definition {
      request {
        q          = "avg:kubernetes.rest.client.latency.sum{*}/avg:kubernetes.rest.client.latency.count{*}"
        aggregator = "avg"
      }

      autoscale   = true

      precision   = "2"
      text_align  = "right"
      title       = "(APP Latency Sample) K8S Rest Client Latency Per Second"
      title_align = "left"
      title_size = "16"
    }
  }
}
