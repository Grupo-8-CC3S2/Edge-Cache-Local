PYTHON := python3
PIP := $(PYTHON) -m pip
HOST ?= 0.0.0.0
PORT ?= 8000
DOCKER := docker
DOCKER_COMPOSE := docker compose
TERRAFORM := terraform

INFRA_DIR := infra/stacks/local-dev

BACKEND_IMAGE := app-backend:latest

.PHONY: help tools run-backend build-backend-docker run-backend-docker tests plan apply destroy

help:
	@echo "Uso: make [comando] [opciones]"
	@echo
	@echo "Comandos disponibles:"
	@echo "  tools                  Instala dependencias"
	@echo "  run-backend            Ejecuta backend local (HOST=$(HOST) PORT=$(PORT))"
	@echo "  build-backend-docker   Construye imagen Docker del backend"
	@echo "  run-backend-docker     Ejecuta backend en Docker (HOST forzado a 0.0.0.0)"
	@echo "  tests                  Ejecuta los tests unitarios"
	@echo
	@echo "Terraform:"
	@echo "  tf-init                Inicializa el directorio de Terraform"
	@echo "  tf-validate            Valida la configuración de Terraform y formatea"
	@echo "  plan                   Genera plan de Terraform (archivo tfplan)"
	@echo "  apply                  Aplica el plan de Terraform (despliega infraestructura)"
	@echo "  destroy                Destruye la infraestructura desplegada"
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

tests:
	@echo "Ejecutando tests..."
	@export PYTHONPATH=$(PWD) && pytest -v

tf-init: # Inicializa Terraform
	@echo "Inicializando Terraform..."
	cd $(INFRA_DIR) && $(TERRAFORM) init
	@echo "Terraform inicializado"

tf-validate: tf-init # Valida configuración de Terraform
	@echo "Validando Terraform..."
	cd $(INFRA_DIR) && $(TERRAFORM) validate
	cd $(INFRA_DIR) && $(TERRAFORM) fmt -check -recursive
	@echo "Validación completada"

plan: tf-validate # Genera plan de Terraform
	@echo "Generando plan de Terraform..."
	cd $(INFRA_DIR) && $(TERRAFORM) plan -out=tfplan
	@echo "Plan generado: $(INFRA_DIR)/tfplan"

apply: plan # Aplica infraestructura con Terraform
	@echo "Aplicando infraestructura..."
	cd $(INFRA_DIR) && $(TERRAFORM) apply tfplan
	@echo "Infraestructura desplegada"
	@echo ""
	@echo "Servicios disponibles:"
	@echo "  Backend"
	@echo "  Proxy"

destroy: # Destruye infraestructura
	@echo "Destruyendo infraestructura..."
	cd $(INFRA_DIR) && $(TERRAFORM) destroy -auto-approve
	@echo "Infraestructura destruida"

lint:
	@echo "Lint..."
	python -m pyflakes src tests || true

cov:
	@echo "Tests with coverage gate..."
	@export PYTHONPATH=$(PWD) && pytest -vv --cov=src --cov-report=term-missing --cov-fail-under=85

parser:
	@echo "Reading logs from logs/nginx.access.log ..."
	@cat logs/nginx.access.log | python src/nginx_log_parser.py
