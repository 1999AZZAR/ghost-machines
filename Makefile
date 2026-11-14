# ==============================================================================
# GHOST MACHINES — DEVELOPER WORKFLOW RUNNER
# ==============================================================================

.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help test lint docs docs-check build-ubuntu build-debian build-alpine build-arch build-all start stop status logs restart prebuilt clean snapshot restore setup-host

help: ## Show this help message
	@echo "=================================================="
	@echo " GHOST MACHINES: TASK RUNNER"
	@echo "=================================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

test: ## Run master automated test suite (all milestones)
	@./tests/run_all.sh

lint: ## Run static analysis & ShellCheck linting
	@./tests/test_lint.sh

docs: ## Regenerate the static documentation site from docs/*.md
	@python3 tools/build_site.py

docs-check: ## Verify docs links, examples, facts and generated site
	@./tests/test_docs.sh

build-ubuntu: ## Build Ubuntu Master Template
	docker build -t ubuntu-template:latest -f Dockerfile .

build-debian: ## Build Debian Slim Template
	docker build -t debian-template:latest -f Dockerfile.debian .

build-alpine: ## Build Alpine Linux Template
	docker build -t alpine-template:latest -f Dockerfile.alpine .

build-arch: ## Build Arch Linux Template
	docker build -t arch-template:latest -f Dockerfile.arch .

build-all: build-ubuntu build-debian build-alpine build-arch ## Build all 4 OS engine images

start: ## Launch interactive engine & mode deployment
	@./start.sh

stop: ## Stop and remove containers (work in mounts/ is kept)
	@./start.sh stop

status: ## Show container state, SSH ports and image in use
	@./start.sh status

logs: ## Follow container logs
	@./start.sh logs

restart: ## Restart existing containers
	@./start.sh restart

prebuilt: ## Pull and run a GHCR image (make prebuilt ENGINE=debian MODE=single)
	@./start.sh --prebuilt "$(or $(ENGINE),ubuntu)" -m "$(or $(MODE),single)"

clean: ## Interactive or headless environment cleanup
	@./clean.sh

snapshot: ## Create smart snapshot with cache exclusions & SHA-256
	@./snapshot.sh

restore: ## Restore workspace snapshot with integrity check & atomic rollback
	@./restore.sh

setup-host: ## Install host system dependencies (LXCFS, Docker)
	@./setup-host.sh

tenant-list: ## List all configured multi-tenant workspaces
	@./tenant.sh list

tenant-stats: ## Live CPU/RAM metrics for active tenant workspaces
	@./tenant.sh stats

