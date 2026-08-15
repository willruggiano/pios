# NOTE: the Makefile should not invoke `nix`.
# `nix` defines the environment in which `make` executes.
.DEFAULT_GOAL := help

.PHONY: help check

help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-8s %s\n", $$1, $$2}'

build: ## Build the binary
	@echo "not yet implemented"

check: ## Run formatter, linter, supply-chain, and dedup gates
	@pre-commit run --all-files

test: ## Run the test suite
	@echo "not yet implemented"

fix: ## Apply the fixable variants of the check gates
	@echo "not yet implemented"

cov: cov-collect ## Run the test suite under coverage and enforce the floor
	@echo "not yet implemented"

cov-html: cov-collect ## Run the test suite under coverage and write an HTML report
	@echo "not yet implemented"

# Instrument and run both test configurations, accumulating profile data without
# emitting a report; `cov`/`cov-html` then merge it.
cov-collect:
	@echo "not yet implemented"

bench: ## Run benchmarks
	@echo "not yet implemented"
