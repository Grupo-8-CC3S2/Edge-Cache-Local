# Módulo Terraform para el servicio backend

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Imagen Docker del backend
resource "docker_image" "backend" {
  name = var.image_name
  
  # Si build_context está definido, construir localmente
  dynamic "build" {
    for_each = var.build_context != "" ? [1] : []
    content {
      context    = var.build_context
      dockerfile = var.dockerfile
      tag        = [var.image_name]
    }
  }
}

# Contenedor del backend
resource "docker_container" "backend" {
  name  = var.container_name
  image = docker_image.backend.image_id
  
  # Reinicio automático
  restart = var.restart_policy
  
  # Puerto expuesto
  ports {
    internal = var.internal_port
    external = var.external_port
    protocol = "tcp"
  }
  
  # Variables de entorno
  env = [
    for key, value in var.environment : "${key}=${value}"
  ]

  # Red personalizada
  networks_advanced {
    name = var.network_name
  }
  
  # Labels para identificación
  labels {
    label = "app"
    value = "edge-cache-backend"
  }
  
  labels {
    label = "module"
    value = "terraform-backend"
  }
  
  labels {
    label = "version"
    value = var.app_version
  }
}

# Output del contenedor
output "container_id" {
  description = "ID del contenedor backend"
  value       = docker_container.backend.id
}

output "container_name" {
  description = "Nombre del contenedor"
  value       = docker_container.backend.name
}

output "internal_endpoint" {
  description = "Endpoint interno del backend"
  value       = "http://${var.container_name}:${var.internal_port}"
}

output "external_endpoint" {
  description = "Endpoint externo del backend"
  value       = "http://localhost:${var.external_port}"
}