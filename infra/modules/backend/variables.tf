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

variable "docker_context" {
  description = "Ruta del contexto de build para Docker"
  type        = string
  default     = "/home/esau/Edge-Cache-Local/src/app"
}

variable "dockerfile_path" {
  description = "Ruta al Dockerfile"
  type        = string
  default     = "/home/esau/Edge-Cache-Local/infra/modules/backend/Dockerfile"
}

variable "app_port" {
  description = "Puerto interno y externo del contenedor"
  type        = number
  default     = 8080
}

variable "env_vars" {
  description = "Variables de entorno del contenedor"
  type        = list(string)
  default     = ["APP_ENV=local", "CACHE_BYPASS=false"]
}
