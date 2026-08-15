.DEFAULT_GOAL := help

TOOLCHAIN_CONFIG := Config/Toolchain.env
TOOLCHAIN_KEYS := MACOS_MINIMUM_VERSION MACOS_VERSION MACOS_BUILD XCODE_VERSION XCODE_BUILD SWIFT_VERSION SWIFT_LANGUAGE_MODE IOS_SDK_VERSION IOS_DEPLOYMENT_TARGET DEVICE_ARCHITECTURE SIMULATOR_RUNTIME_IDENTIFIER SIMULATOR_DEVICE_TYPE_IDENTIFIER

.PHONY: help build check check-apple test fix fix-apple cov

help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n", $$1, $$2}'

build: ## Build the iOS app
	@printf 'error: %s is unavailable until the iOS qualification app Task is complete\n' "$@" >&2
	@exit 2

check: ## Validate Apple toolchain configuration
	@bash -n "$(TOOLCHAIN_CONFIG)"
	@python3 -c 'import sys; from pathlib import Path; rows = [line.split("=", 1) for line in Path("$(TOOLCHAIN_CONFIG)").read_text().splitlines() if line and not line.startswith("#")]; keys = [row[0] for row in rows]; expected = set("$(TOOLCHAIN_KEYS)".split()); malformed = [row[0] for row in rows if len(row) != 2 or not row[0] or not row[1]]; duplicates = sorted({key for key in keys if keys.count(key) > 1}); missing = sorted(expected - set(keys)); unknown = sorted(set(keys) - expected); errors = ([f"malformed={malformed}"] if malformed else []) + ([f"duplicates={duplicates}"] if duplicates else []) + ([f"missing={missing}"] if missing else []) + ([f"unknown={unknown}"] if unknown else []); sys.exit("; ".join(errors)) if errors else None'

test: ## Run portable iOS package tests
	@printf 'error: %s is unavailable until the iOS qualification app Task is complete\n' "$@" >&2
	@exit 2

fix: check ## Apply fixable changes, then validate configuration

cov: ## Run portable iOS package tests with coverage
	@printf 'error: %s is unavailable until the iOS qualification app Task is complete\n' "$@" >&2
	@exit 2
