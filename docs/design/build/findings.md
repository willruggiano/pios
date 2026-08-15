# Namespace macOS host findings

Observed results from the live Namespace macOS development-host spike.

Browse [[index.md]] for the full documentation set.

## Result

The spike succeeded without control-host `nix`. The exact final scripts created
a Namespace Mac, transferred a clean Git bundle, installed verified Nix on the
host, materialized `devShells.aarch64-darwin.namespace`, ran all repository
checks, re-entered the shell over a second SSH connection, and destroyed the
instance.

The successful strict run used temporary source commit
`fdbb600d829805a28eb060209a3f8563ba152685`, containing the exact
`tools/namespace-spike.sh`, `tools/namespace-spike-remote.sh`, and development
shell configuration in this change. The control environment had no `nix`
executable.

## Run ledger

All requests used `macos/arm64:6x14`, selectors
`macos.version=26.x,image.with=xcode-26`, bare mode, and a two-hour deadline.

| Instance        | Source       | Result                                      | Cleanup   |
| --------------- | ------------ | ------------------------------------------- | --------- |
| `97fl7ftnhck4e` | `6a9881c...` | `/work` was read-only                       | Confirmed |
| `008cihaac6vr2` | `6a9881c...` | Generated pre-commit config was unavailable | Confirmed |
| `okqv2h1hlg3u4` | `4890cd9...` | Hook fix worked; Statix rejected its shape  | Confirmed |
| `cudu7056d7sbi` | `eb71dbb...` | Checks passed; forced PTY lacked a console  | Confirmed |
| `lq342cvovm0qi` | `99a9a2d...` | Pre-ShellCheck scripts passed               | Confirmed |
| `seub7j7co3r8a` | `4d92a3a...` | ShellCheck found SC1090 and SC2251          | Confirmed |
| `ajcpc5n4iqjiq` | `5b2e85b...` | ShellCheck found SC1091                     | Confirmed |
| `0pmi8t8vbm9ko` | `fdbb600...` | Final strict scripts passed                 | Confirmed |

The final `nsc list --output json` result was `null`. No instance remains.

## Provider image

The image was consistent across the runs:

| Fact              | Observed value                                           |
| ----------------- | -------------------------------------------------------- |
| SSH user          | `runner`, UID 501                                        |
| System            | Darwin arm64                                             |
| macOS             | 26.3.1, build 25D2128                                    |
| Xcode             | 26.1.1, build 17B100                                     |
| Developer path    | `/Applications/Xcode_26.1.1.app/Contents/Developer`      |
| Swift             | 6.2.1, target `arm64-apple-macosx26.0`                   |
| iPhoneOS SDK      | 26.1                                                     |
| Writable checkout | `/Users/runner/pios`, expressed by the script as `$HOME` |

The root `/work` path is read-only. The provider user has non-interactive
`sudo`, which the installer used to create the encrypted APFS Nix store and
configure the daemon.

The metadata written by `nsc create --output_json_to` includes service
credentials. The final script creates that file under a `077` umask, reads only
the deadline, never prints the document, and deletes it during cleanup.

## Nix bootstrap

The Mac downloaded the installer directly. This removed all control-host
requirements for `curl`, a local installer artifact, checksum tools, and Nix.
Before execution, the host verified SHA-256:

```text
26dabfc07aaa7c5ece7a872b37e73099a6dc3b091b6b648fe812b04e3a8f1e84
```

Determinate Nix Installer v3.22.0 completed without interaction. The installed
command reported `nix (Determinate Nix 3.22.0) 2.35.1`, and
`builtins.currentSystem` reported `aarch64-darwin`.

Cold shell materialization built substantial Rust and Node dependency graphs,
including Pi and jscpd. A Darwin binary cache is an optimization, not an
operational prerequisite for the spike.

## Development shell

The original Namespace shell copied `devshells.minimal.packages` but did not
copy its startup actions. As a result, `pre-commit` was on `PATH` while its
generated configuration was absent. Attaching the git-hooks startup action to
`devshells.namespace` fixed the failure. The grouped assignment in
`nix/checks/pre-commit/default.nix` is the Statix-clean form.

The successful shell exposed:

- unwrapped Pi 0.84.2;
- pre-commit 4.5.1;
- treefmt; and
- the common development tools.

`make check` passed actionlint, deadnix, markdownlint, ShellCheck, Statix, and
treefmt. ShellCheck first rejected a dynamic profile source and a negated
command under `errexit`; the final script uses the fixed Nix profile binary path
and an explicit conditional without lint suppressions. The source remained at
the expected detached commit, the worktree remained clean, and `flake.lock`
retained SHA-256:

```text
aaf4b6490b9ead0577a5206b7194873e83233b94e10ddb6e8b2fee0060462a6d
```

A second non-PTY `nsc ssh` invocation re-entered `nix develop .#namespace` and
resolved Pi. A forced-PTY test could not be run through the coding harness
because its stdin is a pipe; `nsc` reported that stdin was not a console. This
is a control-harness limitation, not evidence for an interactive session.

Nix emitted deprecation warnings for `stdenv.isDarwin` and `stdenv.isLinux`, and
a devshell string-context warning. Neither warning originated in the changed
Namespace shell expressions, and neither blocked materialization or checks.

## Reproduction

From a clean committed checkout with an authenticated `nsc`:

```sh
tools/namespace-spike.sh
```

The control script requires no local `nix`. It always attempts exact-instance
destruction on exit or signal, falls back to its unique run label if create did
not write an instance ID, and verifies that no matching instance remains. The
provider deadline remains the final cleanup boundary.

The implementation is the primary evidence for the procedure:
`tools/namespace-spike.sh`, `tools/namespace-spike-remote.sh`, and
`nix/checks/pre-commit/default.nix`. Provider and installer source references
are cataloged in [[research.md#Sources]].
