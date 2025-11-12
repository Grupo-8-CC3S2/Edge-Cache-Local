terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_image" "monitor" { 
  name = var.imagen_monitor
}

resource "docker_container" "monitor" {
  name = var.nombre_contenedor
  image = docker_image.monitor.image_id
  restart = var.politica_reinicio
  
  networks_advanced {
    name = var.nombre_red
  }

  command = [ "sh","-c","while true; do echo 'monitor en marha: ....'; sleep 10; done"]

  labels {
    label = "module"
    value = "monitor"
  }
}

output "nombre_contenedor" {
    value = docker_container.monitor.name
}

output "id_contenedor" {
    value = docker_container.monitor.id
}