# Variables del módulo backend con defaults sensatos (patrón Factory)

variable "image_name" {
  description = "Nombre de la imagen Docker"
  type        = string
  default     = "backend-api-local:v1.0"
}

variable "container_name" {
  description = "Nombre del contenedor Docker"
  type        = string
  default     = "edge-backend"
}

variable "build_context" {
  description = "Path al contexto de build (si se construye localmente)"
  type        = string
  default     = ""
}

variable "dockerfile" {
  description = "Path al Dockerfile"
  type        = string
  default     = "Dockerfile"
}

variable "internal_port" {
  description = "Puerto interno del contenedor"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.internal_port > 0 && var.internal_port <= 65535
    error_message = "El puerto debe estar entre 1 y 65535."
  }
}

variable "external_port" {
  description = "Puerto expuesto al host"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.external_port > 0 && var.external_port <= 65535
    error_message = "El puerto debe estar entre 1 y 65535."
  }
}

variable "environment" {
  description = "Variables de entorno para el contenedor"
  type        = map(string)
  default = {
    HOST  = "0.0.0.0"
    PORT  = "8080"
  }
}

variable "network_name" {
  description = "Nombre de la red Docker"
  type        = string
  default     = "edge-cache-network"
}

variable "restart_policy" {
  description = "Política de reinicio del contenedor"
  type        = string
  default     = "unless-stopped"
  
  validation {
    condition     = contains(["no", "always", "on-failure", "unless-stopped"], var.restart_policy)
    error_message = "Política de reinicio debe ser: no, always, on-failure, o unless-stopped."
  }
}

variable "app_version" {
  description = "Versión de la aplicación"
  type        = string
  default     = "1.0.0"
}