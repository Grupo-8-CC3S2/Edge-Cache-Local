variable "imagen_monitor" {
    description = "imagen monitor"
    type = string 
    default = "alpine:latest"
}

variable "nombre_contenedor" {
    description = "nombre contenedor"
    type = string 
    default = "edge-cache-monitor"
}

variable "nombre_red" {
    description = "nombre red para monitor"
    type        = string
}

variable "politica_reinicio" {
    description = " politica de reinicio"
    type = string
    default = "unless-stopped"
}