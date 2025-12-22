# Makefile for arxiv-rag
#
# NOTE: Make requires TABs (not spaces) before each recipe line.
#
# Usage examples:
#   make up
#   make fetch
#   make index
#   make ingest
#   make all
#   make reset

SHELL := /bin/bash

# ---- Config (edit as needed) ----
CONDA_ENV      ?= arxiv-rag-elk-env
PYTHON         ?= python
SCRIPT         ?= fetch_arxiv.py

ES_URL         ?= http://localhost:9200
KIBANA_URL     ?= http://localhost:5601
INDEX          ?= arxiv

JSONL_PATH     ?= corpus/corpus.jsonl
NDJSON_PATH    ?= corpus/arxiv.bulk.ndjson

# docker compose file (optional; docker compose will find compose.yml by default)
COMPOSE_FILE   ?= compose.yml

# ---- Helpers ----
.PHONY: help
help:
	@echo ""
	@echo "Targets:"
	@echo "  make env        - Create conda environment from environment.yml"
	@echo "  make up         - Start Elasticsearch + Kibana (docker compose up -d)"
	@echo "  make down       - Stop stack (docker compose down)"
	@echo "  make ps         - Show running containers (docker compose ps)"
	@echo "  make logs       - Follow logs (docker compose logs -f)"
	@echo "  make status     - Check ES and Kibana endpoints"
	@echo "  make fetch      - Run $(SCRIPT) to generate JSONL/NDJSON artifacts"
	@echo "  make index      - Create Elasticsearch index $(INDEX)"
	@echo "  make delete     - Delete Elasticsearch index $(INDEX)"
	@echo "  make reset      - Delete + recreate index $(INDEX)"
	@echo "  make ingest     - Bulk ingest NDJSON into $(INDEX)"
	@echo "  make count      - Show document count for $(INDEX)"
	@echo "  make all        - up -> index -> fetch -> ingest -> count"
	@echo ""

.PHONY: env
env:
	@test -f environment.yml || (echo "Missing environment.yml" && exit 1)
	conda env create -f environment.yml
	@echo "Created conda env: $(CONDA_ENV)"
	@echo "Activate with: conda activate $(CONDA_ENV)"

.PHONY: up
up:
	@test -f $(COMPOSE_FILE) || (echo "Missing $(COMPOSE_FILE)" && exit 1)
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "Elasticsearch: $(ES_URL)"
	@echo "Kibana:        $(KIBANA_URL)"

.PHONY: down
down:
	docker compose -f $(COMPOSE_FILE) down

.PHONY: ps
ps:
	docker compose -f $(COMPOSE_FILE) ps

.PHONY: logs
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

.PHONY: status
status:
	@echo "Checking Elasticsearch..."
	@curl -sS $(ES_URL) >/dev/null && echo "  ES OK: $(ES_URL)" || (echo "  ES NOT reachable: $(ES_URL)" && exit 1)
	@echo "Checking Kibana..."
	@curl -sS $(KIBANA_URL) >/dev/null && echo "  Kibana OK: $(KIBANA_URL)" || echo "  Kibana NOT reachable yet (may still be starting): $(KIBANA_URL)"

.PHONY: fetch
fetch:
	@test -f $(SCRIPT) || (echo "Missing $(SCRIPT)" && exit 1)
	$(PYTHON) $(SCRIPT)
	@echo "Expected outputs:"
	@echo "  JSONL : $(JSONL_PATH)"
	@echo "  NDJSON: $(NDJSON_PATH)"

.PHONY: index
index:
	curl -sS -X PUT "$(ES_URL)/$(INDEX)" \
		-H "Content-Type: application/json" \
		-d '{"mappings":{"dynamic":true}}' | cat
	@echo ""
	@echo "Created index: $(INDEX)"

.PHONY: delete
delete:
	curl -sS -X DELETE "$(ES_URL)/$(INDEX)" | cat
	@echo ""
	@echo "Deleted index: $(INDEX)"

.PHONY: reset
reset: delete index

.PHONY: ingest
ingest:
	@test -f $(NDJSON_PATH) || (echo "Missing NDJSON file: $(NDJSON_PATH). Run 'make fetch' first." && exit 1)
	curl --fail-with-body -sS \
		-H "Content-Type: application/x-ndjson" \
		-X POST "$(ES_URL)/_bulk?refresh=true" \
		--data-binary "@$(NDJSON_PATH)" | cat
	@echo ""
	@echo "Ingested: $(NDJSON_PATH)"

.PHONY: count
count:
	curl --fail-with-body -sS "$(ES_URL)/$(INDEX)/_count?pretty" | cat

.PHONY: all
all: up reset fetch ingest count
	@echo ""
	@echo "Done."
