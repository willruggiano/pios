# NOTE: the Makefile should not invoke `nix`.
# `nix` defines the environment in which `make` executes.
.DEFAULT_GOAL := help

PIOS_DEVCTL ?= pios-devctl
DURATION ?= 2h

.PHONY: \
	help build check test fix cov \
	namespace-doctor dev-up dev-status dev-shell dev-vnc dev-extend dev-down dev-gc \
	test-devctl-live build-ios test-ios release-inputs release-preflight release-testflight

help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-22s %s\n", $$1, $$2}'

build: ## Build all deliverables available on this system
	@$(MAKE) -C packages/devctl build
	@$(MAKE) -C packages/ios build

check: ## Run all read-only repository and package checks
	@pre-commit run --all-files
	@$(MAKE) -C packages/devctl check
	@$(MAKE) -C packages/ios check

test: ## Run all test suites available on this system
	@$(MAKE) -C packages/devctl test
	@$(MAKE) -C packages/ios test

fix: ## Apply fixable formatting and lint changes, then run checks
	@treefmt
	@$(MAKE) -C packages/devctl fix
	@$(MAKE) -C packages/ios fix
	@$(MAKE) check

cov: ## Run all test suites with coverage
	@$(MAKE) -C packages/devctl cov
	@$(MAKE) -C packages/ios cov

namespace-doctor: ## Validate Namespace access without creating an instance
	@$(PIOS_DEVCTL) doctor

dev-up: ## Create or adopt the managed development Mac
	@$(PIOS_DEVCTL) up

dev-status: ## Show managed development Mac status
	@$(PIOS_DEVCTL) status

dev-shell: ## Open a private shell on the managed development Mac
	@$(PIOS_DEVCTL) shell

dev-vnc: ## Open a private VNC session on the managed development Mac
	@$(PIOS_DEVCTL) vnc

dev-extend: ## Extend the managed development Mac lease
	@test -n "$(DURATION)" || { printf '%s\n' 'error: DURATION is required' >&2; exit 2; }
	@$(PIOS_DEVCTL) extend --duration "$(DURATION)"

dev-down: ## Retrieve pending logs and destroy the managed development Mac
	@$(PIOS_DEVCTL) down

dev-gc: ## Show expired or orphaned managed instances
	@$(PIOS_DEVCTL) gc

test-devctl-live: ## Run the explicit billable controller lifecycle test
	@$(MAKE) -C packages/devctl test-live

build-ios: ## Build the iOS app on a one-shot managed Mac
	@$(PIOS_DEVCTL) with --operation build-ios

test-ios: ## Test the iOS app on a one-shot managed Mac
	@$(PIOS_DEVCTL) with --operation test-ios

release-inputs:
	@test -n "$(VERSION)" || { printf '%s\n' 'error: VERSION is required' >&2; exit 2; }
	@test -n "$(BUILD)" || { printf '%s\n' 'error: BUILD is required' >&2; exit 2; }

release-preflight: release-inputs ## Validate release inputs without creating an instance
	@$(PIOS_DEVCTL) release preflight --version "$(VERSION)" --build "$(BUILD)"

release-testflight: release-inputs ## Archive and upload a one-shot internal TestFlight build
	@$(PIOS_DEVCTL) release testflight --version "$(VERSION)" --build "$(BUILD)"
