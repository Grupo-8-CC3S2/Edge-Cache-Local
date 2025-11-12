# Módulo Terraform para monitor

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Imagen Docker para monitor
resource "docker_image" "monitor" {
  name = var.imagen_monitor
}

# Contenedor monitor
resource "docker_container" "monitor" {
  name    = var.nombre_contenedor
  image   = docker_image.monitor.image_id
  restart = var.politica_reinicio

  # Red personalizada
  networks_advanced {
    name = var.nombre_red
  }

 volumes {
  host_path      = "/home/esau/Edge-Cache-Local/src/app"
  container_path = "/app"
}

volumes {
  host_path      = "/home/esau/Edge-Cache-Local/logs/nginx.access.log"
  container_path = "/logs/access.log"
}

  # Comando de scraping continuo
  command = [
    "sh", "-c",
    "while true; do python3 /app/analyze_logs.py /logs/access.log --container edge-cache-proxy; sleep ${var.scrape_interval}; done"
  ]

  labels {
    label = "module"
    value = "terraform-monitor"
  }
}

# Outputs
output "nombre_contenedor" {
  value = docker_container.monitor.name
}

output "id_contenedor" {
  value = docker_container.monitor.id
}
