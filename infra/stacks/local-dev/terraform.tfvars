# Variables para el stack de desarrollo local

# General
app_version    = "1.0.0"
network_name   = "edge-cache-network"
restart_policy = "unless-stopped"

# Backend
backend_container_name = "edge-backend"
backend_image          = "edge-cache-backend:latest"
backend_build_context  = "../../../" # Path relativo al root del proyecto
backend_internal_port  = 8080
backend_external_port  = 8080

backend_environment = {
  HOST = "0.0.0.0"
  PORT = 8080
}

# Proxy
proxy_container_name = "edge-cache-proxy"
nginx_image          = "nginx:alpine"
nginx_config_path    = "/home/esau/Edge-Cache-Local/proxy/nginx.conf"  # Ruta al nginx.conf que usaremos
proxy_external_port  = 80