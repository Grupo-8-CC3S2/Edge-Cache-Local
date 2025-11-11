terraform {
    required_version = ">=1.0"
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~>3.0"
        }
    }
}

provider "docker" {}

resource "docker_image" "nginx" {
    name = var.imagen_nginx 
}

resource "docker_network" "shared" {
  name = var.nombre_red
}

resource "docker_container" "proxy" {
    name = var.contenedor_proxy
    image = docker_image.nginx.image_id
    ports {
        internal = 80
        external = var.puerto_externo
        protocol = "tcp"
    }
    volumes {
        host_path = var.ruta_nginx
        container_path = "/etc/nginx/nginx.conf"
        read_only = true
    }
    networks_advanced {
        name = docker_network.shared.name
    }
    depends_on = [var.id_contenedor_backend]
}

output "proxy_endpoint" {
    value = "http://localhost:${var.puerto_externo}/api/v1/health"
}

