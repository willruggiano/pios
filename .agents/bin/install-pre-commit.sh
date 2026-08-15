#!/usr/bin/env bash
set -euo pipefail

nix_bin=/nix/var/nix/profiles/default/bin
project_dir="$PWD"

log() { printf '[pre-commit] %s\n' "$*" >&2; }

# setup.sh installs Nix and must have run first; skip rather than fail if not.
if [ ! -x "$nix_bin/nix" ]; then
  log "Nix not found; setup.sh must run first -- skipping"
  exit 0
fi

# Mirror setup.sh: nix on PATH, accept the flake's nixConfig (binary cache), and
# inherit the proxy CA the environment configured.
export PATH="$nix_bin:$PATH"
export NIX_CONFIG="accept-flake-config = true"
: "${NIX_SSL_CERT_FILE:=${SSL_CERT_FILE:-}}"
[ -n "${NIX_SSL_CERT_FILE:-}" ] && export NIX_SSL_CERT_FILE

log "installing git hooks (nix run .#install-pre-commit)"
(cd "$project_dir" && nix run ".#install-pre-commit")
log "done"
