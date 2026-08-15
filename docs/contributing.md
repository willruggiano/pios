# Contributing

Repository strictness and commit conventions are defined in
[[rules/contributing.md]]. Engineering decisions follow [[rules/posture.md]],
and Nix-specific work follows [[rules/nix.md]]. This document defines repository
layout and the command interface.

## Development Environment

Nix defines the development environment; it is not the command runner. Human
operators enter the environment with `direnv` or `nix develop`. Coding agents
already run inside the default development shell and invoke repository commands
and tools directly.

Do not prefix commands with `nix develop -c`, use `nix shell` to obtain a tool,
or use `nix run` as a substitute for a command supplied by the development
shell. If a documented command is unavailable, report the command and error. A
missing command is a development-shell defect; do not install it or bypass the
check.

Use `make` as the repository command interface:

```sh
make check
make -C packages/gateway test
```

Use Nix commands directly only when the operation itself evaluates or builds Nix
configuration.

## Repository Layout

Keep the repository root minimal. Documentation belongs in `docs/`, deployable
or generated products in `packages/`, shared Nix modules in `nix/`, and
repository-wide development tools in `tools/`.

The repository MUST converge on this layout:

```text
.
|-- .agents/
|   |-- agents.md
|   |-- bin/
|   `-- rules/ -> docs/rules
|-- AGENTS.md -> .agents/agents.md
|-- README.md
|-- Makefile
|-- flake.nix
|-- flake.lock
|-- docs/
|   |-- architecture.md
|   |-- build.md
|   |-- contributing.md
|   `-- rules/
|-- packages/
|   |-- protocol/
|   |   |-- default.nix
|   |   |-- Makefile
|   |   |-- pi_mobile.proto
|   |   |-- buf.yaml
|   |   `-- fixtures/
|   |-- gateway/
|   |   |-- default.nix
|   |   |-- Makefile
|   |   |-- package.json
|   |   |-- package-lock.json
|   |   |-- upstream/
|   |   |   `-- pi.lock.json
|   |   |-- src/
|   |   `-- test/
|   |-- ios/
|   |   |-- default.nix
|   |   |-- Makefile
|   |   |-- Config/
|   |   |-- PiMobile.xcodeproj/
|   |   |-- PiMobileApp/
|   |   |-- Packages/
|   |   |   |-- PiMobileCore/
|   |   |   `-- PiMobileApple/
|   |   |-- TestPlans/
|   |   `-- Tests/
|   `-- devctl/
|       |-- default.nix
|       |-- Makefile
|       |-- Config/
|       |   `-- namespace.toml
|       |-- go.mod
|       |-- go.sum
|       |-- cmd/
|       |-- internal/
|       |-- scripts/
|       |-- .state/
|       `-- artifacts/
|-- nix/
`-- tools/
```

`packages/devctl/.state/` and `packages/devctl/artifacts/` MUST be ignored and
MUST never be source inputs. Package source, tests, configuration, and build
output remain inside their package. Root entries are limited to repository entry
points, repository-wide orchestration, and files required at an exact root path
by repository-wide tools.

## Package Layout

Every package is self-contained under `packages/<name>/` and owns its source,
tests, package-specific configuration, and Nix definition.
`packages/<name>/default.nix` is the package's Nix definition. `flake.nix`
imports each package directly:

```nix
imports = [
  ./packages/<name>
];
```

Do not define package derivations under `nix/`. That directory contains only
repository-wide Nix modules and support code.

## Makefile Interface

The root `Makefile` and every package expose the same five required targets:

| Target  | Contract                                                                                                      |
| ------- | ------------------------------------------------------------------------------------------------------------- |
| `build` | Build the deliverable.                                                                                        |
| `check` | Run all read-only formatting, lint, static-analysis, and validation checks. It must not modify tracked files. |
| `test`  | Run the test suite.                                                                                           |
| `fix`   | Apply fixable formatting and lint changes, then run `check`.                                                  |
| `cov`   | Run tests with coverage enabled and produce the coverage report.                                              |
| `bench` | (optional) Run benchmarks where appropriate                                                                   |

The root targets aggregate package targets that can run in the current
environment. Paid remote-mac and release operations use explicit additional root
targets and are never part of `check`.

Makefiles invoke tools supplied by the development shell directly. They must not
invoke Nix, install tools, or rewrite dependency locks. Package-specific targets
are allowed when the common interface does not describe the operation, for
example:

```sh
make -C packages/protocol generate
make build-ios
```
