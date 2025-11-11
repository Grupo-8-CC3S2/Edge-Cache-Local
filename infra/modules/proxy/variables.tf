variable "contenedor_proxy" {
    description = "nombre de contenedor backend"
    type = string 
    default = "edge-backend-proxy"
}

variable "imagen_nginx" {
    description = "imagen nginx"
    type = string
    default = "nginx:alpine"
}

variable "puerto_externo" {
    description = "puerto backend"
    type = number
    default = 80
}

variable "ruta_nginx" {
    description = "ruta a nginx.conf"
    type = string
    default = "/home/esau/Edge-Cache-Local/proxy/nginx.conf"
}

variable "id_contenedor_backend" {
    description  = "Id del contenedor backend"
    type = string 
    default = ""
}

variable "nombre_red" {
    description = "nombre de la red compartida"
    type = string 
    default = "edge-cache-network" 
}