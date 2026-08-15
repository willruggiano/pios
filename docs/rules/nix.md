---
paths:
  - "**/*.nix"
  - ".agents/bin/*.sh"
---

# Nix

Nix is the single source of truth for tool versions and development-shell
provisioning. Agent command invocation is defined in
[[contributing.md#Development Environment]]. Nix modules MUST provision that
direct command interface, not an alternate wrapper workflow.

## Module Layout

`flake.nix` is a [flake-parts](https://flake.parts) tree with these
repository-wide modules:

```text
flake.nix
└── imports
    ├── nix/jailed.nix
    ├── nix/formatter.nix
    ├── nix/checks/
    └── nix/dev/
        └── pi/
```

Package derivations belong in `packages/<name>/default.nix`, as defined in
[[contributing.md#Package Layout]]. Modules under `nix/` provide only
repository-wide checks, formatting, development shells, and jail support.

## Development Shell

The default development shell supplies the tools used by Makefiles, hooks, and
coding agents. If a required executable is absent, add it to the appropriate
development-shell module; do not substitute an unpinned tool.

`.envrc` loads the default shell for interactive work. Agent bootstrap code may
install Nix and materialize the shell before the agent starts; those bootstrap
operations are environment provisioning, not the command interface agents use
while working.

## Checks and Formatting

`nix/checks/` defines repository-wide flake checks and pre-commit hooks.
`nix/formatter.nix` defines the treefmt wrapper. Keep check configuration in the
owning module and expose the corresponding executable in the development shell
when developers or agents must run it directly.
