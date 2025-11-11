PYTHON := python3
PIP := $(PYTHON) -m pip
HOST := $(HOST)
PORT := $(PORT)
HOST ?= 0.0.0.0
PORT ?= 8000
DOCKER := docker
DOCKER_COMPOSE := docker compose

BACKEND_IMAGE := app-backend:latest

.PHONY: help tools run-backend build-backend-docker run-backend-docker

help:
	@echo "Uso: make [comando] [opciones]"
	@echo
	@echo "Comandos disponibles:"
	@echo "  tools                  Instala dependencias"
	@echo "  run-backend            Ejecuta backend local (HOST=$(HOST) PORT=$(PORT))"
	@echo "  build-backend-docker   Construye imagen Docker del backend"
	@echo "  run-backend-docker     Ejecuta backend en Docker (HOST forzado a 0.0.0.0)"
	@echo
	@echo "Opciones:"
	@echo "  HOST=<host>            Cambiar host local (solo afecta run-backend)"
	@echo "  PORT=<puerto>          Cambiar puerto"
	@echo

tools:
	@echo "Instalando herramientas..."
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	@echo "Herramientas instaladas"

run-backend:
	@echo "Ejecutando backend..."
	uvicorn src.app.main:app --host $(HOST) --port $(PORT) --reload

build-backend-docker:
	@echo "Construyendo imagen Docker..."
	$(DOCKER) build -t $(BACKEND_IMAGE) -f Dockerfile .
	@echo "Imagen lista: $(BACKEND_IMAGE)"

run-backend-docker:
	@echo "Ejecutando backend en Docker..."
	HOST=0.0.0.0 PORT=$(PORT) $(DOCKER_COMPOSE) up --build
