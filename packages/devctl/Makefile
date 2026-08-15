.DEFAULT_GOAL := help

NAMESPACE_CONFIG := Config/namespace.toml

.PHONY: help build check test fix cov test-live

help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n", $$1, $$2}'

build: ## Build the controller and remote helper
	@printf 'error: %s is unavailable until the controller implementation Task is complete\n' "$@" >&2
	@exit 2

check: ## Validate controller configuration
	@python3 -c 'import sys, tomllib; config = tomllib.load(open("$(NAMESPACE_CONFIG)", "rb")); schemas = (("root", config, {"schema_version", "workspace", "machine_type", "selectors", "default_ttl", "maximum_ttl", "purpose", "remote_root", "artifact_expiry", "release", "cache"}), ("release", config.get("release", {}), {"machine_type", "ttl"}), ("cache", config.get("cache", {}), {"enabled", "tag", "minimum_size", "mount_point"})); errors = [f"{name}: missing={sorted(expected - set(actual))}, unknown={sorted(set(actual) - expected)}" for name, actual, expected in schemas if set(actual) != expected] + ([] if config.get("schema_version") == 1 else ["root: schema_version must be 1"]); sys.exit("; ".join(errors)) if errors else None'

test: ## Run controller tests without creating an instance
	@printf 'error: %s is unavailable until the controller implementation Task is complete\n' "$@" >&2
	@exit 2

fix: check ## Apply fixable changes, then validate configuration

cov: ## Run controller tests with coverage
	@printf 'error: %s is unavailable until the controller implementation Task is complete\n' "$@" >&2
	@exit 2

test-live: ## Run the explicit billable controller lifecycle test
	@printf 'error: %s is unavailable until the controller implementation Task is complete\n' "$@" >&2
	@exit 2
