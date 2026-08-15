# Contributing

Repository strictness and commit conventions are defined in
[[rules/contributing.md]]. Engineering decisions follow [[rules/posture.md]],
and Nix-specific work follows [[rules/nix.md]]. This document defines repository
layout and the package command interface.

## Repository Root

Keep the repository root minimal. A root entry must be one of:

- a repository entry point, such as `README.md` or `AGENTS.md`;
- repository-wide orchestration, such as `flake.nix`, `flake.lock`, or the root
  `Makefile`; or
- configuration required at an exact root path by a repository-wide tool.

Put documentation in `docs/`, packages in `packages/`, shared Nix modules in
`nix/`, and repository-wide development tools in `tools/`. Package source,
tests, configuration, and build output do not belong in the root.

## Package Layout

Every package is self-contained under `packages/<name>/`:

```text
packages/
└── <name>/
    ├── default.nix
    ├── Makefile
    └── ...
```

`packages/<name>/default.nix` is the package's Nix definition. `flake.nix`
imports each package directly:

```nix
imports = [
  ./packages/<name>
];
```

Do not define package derivations under `nix/`. That directory contains only
repository-wide Nix modules and support code.

## Package Makefile

Every package exposes the same five public targets:

| Target  | Contract                                                                                                      |
| ------- | ------------------------------------------------------------------------------------------------------------- |
| `build` | Build the package's deliverable.                                                                              |
| `check` | Run all read-only formatting, lint, static-analysis, and validation checks. It must not modify tracked files. |
| `test`  | Run the package's test suite.                                                                                 |
| `fix`   | Run the `check` toolchain in write/apply mode, then run `check` to verify the result.                         |
| `cov`   | Run tests with coverage enabled and produce the package's coverage report.                                    |

The targets run with tooling supplied by Nix and must not install tools or
rewrite dependency locks. Repository automation invokes packages only through
this interface, for example:

```sh
make -C packages/<name> check
```
