terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_image" "imagen_backend" {
  name = var.image_name
 
  build {
    context    = var.docker_context
    dockerfile = var.dockerfile_path
  }
}

data "docker_network" "shared" {
  name = var.nombre_red
}

resource "docker_container" "contenedor_backend" {
  name  = var.container_name
  image = docker_image.imagen_backend.image_id

  ports {
    internal = var.app_port
    external = var.app_port
  }
  networks_advanced {
    name = data.docker_network.shared.name
  }
  env = var.env_vars

  restart        = "no"
  remove_volumes = true
  must_run       = true
  start          = true
}

output "nombre_contenedor" {
    description = "nombre del contenedor"
    value = var.container_name
}