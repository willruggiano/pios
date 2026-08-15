.DEFAULT_GOAL := help

.PHONY: help check

help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-8s %s\n", $$1, $$2}'

check: ## Run formatter, linter, supply-chain, and dedup gates
	nix fmt
	cpd --no-tips --no-colors .
