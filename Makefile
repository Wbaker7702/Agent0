.PHONY: help explore build validate test debug audit deploy integrate

help:
	@echo "Agent0 Series - Development Commands"
	@echo "===================================="
	@echo ""
	@echo "Exploration & Search:"
	@echo "  make explore          - Explore codebase structure"
	@echo "  make explore-all      - Full codebase exploration"
	@echo "  make explore-training - Explore training components"
	@echo "  make explore-tools    - Explore tool servers"
	@echo ""
	@echo "Build & Setup:"
	@echo "  make build            - Validate build environment"
	@echo "  make install          - Install dependencies"
	@echo "  make setup            - Run comprehensive setup script"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make test             - Run unit tests"
	@echo "  make test-quick       - Run quick tests"
	@echo "  make test-all         - Run all tests"
	@echo "  make validate         - Full validation check"
	@echo ""
	@echo "Debugging:"
	@echo "  make debug-gpu        - Check GPU status"
	@echo "  make debug-ray        - Check Ray cluster"
	@echo "  make debug-config     - Validate configuration"
	@echo "  make debug-memory     - Profile memory usage"
	@echo ""
	@echo "Code Quality:"
	@echo "  make audit            - Run all audits"
	@echo "  make audit-security   - Security audit"
	@echo "  make audit-quality    - Code quality audit"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-check     - Check deployment readiness"
	@echo ""
	@echo "Integration:"
	@echo "  make integrate-check  - Check integration points"
	@echo ""

# Exploration
explore:
	@bash scripts/explore_codebase.sh all

explore-all:
	@bash scripts/explore_codebase.sh all

explore-training:
	@bash scripts/explore_codebase.sh training

explore-tools:
	@bash scripts/explore_codebase.sh tools

explore-eval:
	@bash scripts/explore_codebase.sh evaluation

explore-deps:
	@bash scripts/explore_codebase.sh dependencies

# Build
build:
	@bash scripts/validate_build.sh

install:
	@echo "Installing dependencies..."
	@cd Agent0 && pip install -r requirements.txt
	@cd Agent0/curriculum_train && pip install -r requirements.txt
	@cd Agent0/executor_train/verl && pip install -e .
	@echo "Installing Flash Attention..."
	@pip install "flash-attn==2.8.3" --no-build-isolation || echo "Flash Attention installation may require CUDA"

setup:
	@bash scripts/setup.sh

# Testing
test:
	@bash scripts/run_tests.sh unit

test-quick:
	@bash scripts/run_tests.sh quick

test-all:
	@bash scripts/run_tests.sh all

validate: build test-quick
	@echo "✅ Validation complete"

# Debugging
debug-gpu:
	@bash scripts/debug_helper.sh gpu-status

debug-ray:
	@bash scripts/debug_helper.sh ray-status

debug-config:
	@bash scripts/debug_helper.sh check-config

debug-memory:
	@bash scripts/debug_helper.sh memory-profile

debug-logs:
	@bash scripts/debug_helper.sh check-logs

debug-sandbox:
	@bash scripts/debug_helper.sh test-sandbox

debug-vllm:
	@bash scripts/debug_helper.sh test-vllm

# Auditing
audit:
	@bash scripts/audit_code.sh all

audit-security:
	@bash scripts/audit_code.sh security

audit-quality:
	@bash scripts/audit_code.sh quality

audit-deps:
	@bash scripts/audit_code.sh dependencies

# Deployment
deploy-check: build test-quick audit-security
	@echo "✅ Deployment readiness check complete"

# Integration
integrate-check:
	@echo "Checking integration points..."
	@python3 -c "import torch; import transformers; import ray; print('✅ Core integrations OK')" || echo "❌ Integration check failed"
	@bash scripts/debug_helper.sh check-config
