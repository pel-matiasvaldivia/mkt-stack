# mkt-stack — atajos de operacion
# Uso: make <target>
.DEFAULT_GOAL := help
SHELL := /bin/bash
COMPOSE := docker compose

.PHONY: help secrets config up down restart pull ps logs backup restore wa-qr prune

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

secrets: ## Genera .env con secretos aleatorios (no pisa si ya existe)
	./scripts/gen-secrets.sh

config: ## Valida el docker-compose.yml
	$(COMPOSE) config -q && echo "compose OK"

up: ## Levanta todo el stack en segundo plano
	$(COMPOSE) up -d --remove-orphans

down: ## Baja el stack (conserva volumenes/datos)
	$(COMPOSE) down

restart: ## Reinicia el stack
	$(COMPOSE) restart

pull: ## Baja las imagenes pineadas (footprint minimo)
	$(COMPOSE) pull

ps: ## Estado de los servicios
	$(COMPOSE) ps

logs: ## Sigue los logs (make logs S=n8n para uno solo)
	$(COMPOSE) logs -f --tail=100 $(S)

wa-qr: ## Muestra el QR de WhatsApp de open-wa para escanear en el 1er arranque
	$(COMPOSE) logs -f openwa

prune: ## Limpia imagenes colgadas para recuperar disco
	docker image prune -f

backup: ## Dump de todas las bases + volumenes de datos a ./backups
	@mkdir -p backups
	$(COMPOSE) exec -T postgres pg_dumpall -U $$(grep '^POSTGRES_USER=' .env | cut -d= -f2) \
	  | gzip > backups/postgres-$$(date +%F_%H%M).sql.gz
	$(COMPOSE) exec -T twenty-db pg_dumpall -U postgres \
	  | gzip > backups/twenty-$$(date +%F_%H%M).sql.gz
	@echo "Backups en ./backups (agregar clickhouse/plausible si se necesita historico de analytics)"

restore: ## Restaura Postgres compartido desde FILE=backups/xxx.sql.gz
	@test -n "$(FILE)" || (echo "Uso: make restore FILE=backups/postgres-....sql.gz" && exit 1)
	gunzip -c $(FILE) | $(COMPOSE) exec -T postgres psql -U $$(grep '^POSTGRES_USER=' .env | cut -d= -f2) -d postgres
