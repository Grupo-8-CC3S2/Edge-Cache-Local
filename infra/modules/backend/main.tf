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

resource "docker_container" "contenedor_backend" {
  name  = var.container_name
  image = docker_image.imagen_backend.image_id

  ports {
    internal = var.app_port
    external = var.app_port
  }

  env = var.env_vars

  restart        = "no"
  remove_volumes = true
  must_run       = true
  start          = true
}
