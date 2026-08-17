.DEFAULT_GOAL := help

PACKAGE_PATH := PiOSCore
SWIFT_FLAGS := -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
SWIFT_PATHS := PiOS/PiOSApp PiOS/PiOSInfrastructureTests PiOSCore/Sources PiOSCore/Tests

.PHONY: help build check check-apple test fix fix-apple cov

help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n", $$1, $$2}'

build: ## Build the portable PiOSCore package
	@swift build --package-path "$(PACKAGE_PATH)" $(SWIFT_FLAGS)

check: ## Validate package configuration
	@./scripts/check-configuration

check-apple: check ## Validate Swift formatting and compilation on macOS
	@swift package --package-path "$(PACKAGE_PATH)" dump-package >/dev/null
	@swift format lint --strict --recursive $(SWIFT_PATHS)
	@swift build --package-path "$(PACKAGE_PATH)" $(SWIFT_FLAGS)

test: ## Run portable PiOSCore package tests
	@swift test --package-path "$(PACKAGE_PATH)" $(SWIFT_FLAGS)

fix: check ## Apply platform-neutral fixes

fix-apple: ## Format Swift sources, then validate on macOS
	@swift format --in-place --recursive $(SWIFT_PATHS)
	@$(MAKE) check-apple

cov: ## Run portable PiOSCore tests and emit the coverage report path
	@swift test --package-path "$(PACKAGE_PATH)" $(SWIFT_FLAGS) --enable-code-coverage
	@swift test --package-path "$(PACKAGE_PATH)" --show-codecov-path
