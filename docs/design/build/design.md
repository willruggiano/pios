# Namespace macOS host design

Minimum design for creating and bootstrapping an operational Namespace macOS
development host.

Browse [[index.md]] for the full documentation set.

**Status:** spike qualified; live evidence and deviations from this pre-spike
design are recorded in [[findings.md]] and [[summary.md]].

## Decision

Implement a narrow shell harness over the pinned `nsc` CLI. It creates one
`macos/arm64:6x14` host, transfers a clean Git revision and bootstrap script,
installs a remotely downloaded and verified Nix, enters the repository's
Namespace-specific Darwin development shell, and leaves the host running until
explicit destruction.

The harness is not `pios-devctl`. It has no provider SDK, application image,
worktree overlay, cache, artifact transport, extension, adoption, garbage
collection, release operation, or arbitrary non-interactive command interface.
Those remain in [[build.md#7. pios-devctl: the remote-development controller]].

The design assumes:

- an operational host means command-line development through private SSH;
- the source input is one clean, committed `HEAD`;
- one operator controls at most one spike host from a workstation; and
- the host receives no Apple, Git, model-provider, or application credentials.

VNC and iOS build execution are not required for this outcome.

## System boundary

```text
+----------------------- NixOS control host ------------------------+
|                                                                   |
| make dev-up                                                       |
|   |                                                               |
|   +-- verify auth, source, and cost confirmation                  |
|   +-- nsc create                                                  |
|   +-- nsc instance upload: pios.bundle, bootstrap script          |
|   `-- nsc ssh: clone + bootstrap                                  |
|                                                                   |
| make dev-status   make dev-shell   make dev-down                  |
+-----------------------------+-------------------------------------+
                              | private Namespace transport
                              v
+-------------------- Namespace macOS host -------------------------+
| $HOME/pios: detached exact commit                                 |
| /nix: pinned installer output                                     |
| Xcode: provider image                                             |
| shell: nix develop .#namespace                                    |
+-------------------------------------------------------------------+
```

The NixOS checkout and `flake.lock` remain the source of truth. Namespace
supplies mutable macOS and Xcode system software. The host records those image
facts but does not convert Xcode into a Nix input. This follows the boundary
established by [[build.md#4.2 What Nix does and does not guarantee]].

## Repository changes

The implementation changes only these surfaces:

| Path                                | Change                                                      |
| ----------------------------------- | ----------------------------------------------------------- |
| `flake.nix`                         | Add `aarch64-darwin` to `systems`.                          |
| `nix/dev/default.nix`               | Add the Darwin-only `namespace` shell.                      |
| `nix/dev/pi/default.nix`            | Add unwrapped Pi to the `namespace` shell.                  |
| `nix/checks/pre-commit/default.nix` | Add repository checks to the `namespace` shell.             |
| `tools/namespace-host`              | Implement local lifecycle and remote bootstrap subcommands. |
| `Makefile`                          | Expose `dev-up`, `dev-status`, `dev-shell`, and `dev-down`. |

`tools/namespace-host` is repository-wide development tooling, not a package.
The Make targets are the operator interface. They invoke shell and Nix-provided
tools directly and never invoke `nix`, consistent with
[[contributing.md#Makefile Interface]]. Nix itself is invoked only by the remote
bootstrap to materialize the development environment.

## Namespace development shell

The flake must expose `devShells.aarch64-darwin.namespace` without weakening the
Linux default shell:

1. Keep portable tools in a common development-shell package list.
2. Keep `namespace-cli`, `procps`, and the bubblewrap jail in the Linux shell.
3. Add the common tools to the Darwin-only `namespace` shell.
4. Add `packages.pi-unwrapped` directly to that shell. The locked upstream
   package supports `aarch64-darwin`; the jail does not.
5. Add the repository formatter and pre-commit check environment to that shell.
6. Keep Xcode, Apple SDKs, and simulator tools outside Nix. They come from the
   selected Namespace image.

These changes directly close the gaps in [[research.md#Repository gaps]]. The
Linux default remains the control-host and coding-agent environment; the
Namespace Mac enters its explicitly named shell.

The control host does not evaluate the shell and does not require `nix`. The
Namespace host supplies the native evaluation and build proof:

```sh
nix develop .#namespace --command make check
```

Neither command may update `flake.lock`.

## Instance contract

`dev-up` uses this fixed specification:

| Field                 | Value                                    |
| --------------------- | ---------------------------------------- |
| Machine type          | `macos/arm64:6x14`                       |
| Selectors             | `macos.version=26.x,image.with=xcode-26` |
| Duration              | `2h`                                     |
| Mode                  | `--bare`                                 |
| Purpose               | `pios macOS development host spike`      |
| Unique tag            | `pios-macos-<commit>-<run-id>`           |
| Label `managed-by`    | `pios-namespace-host`                    |
| Label `project`       | `pios`                                   |
| Label `role`          | `development`                            |
| Label `source-commit` | Full Git commit                          |
| Label `run-id`        | Unique non-secret invocation ID          |

No volume, ingress, Kubernetes feature, SSH key, secret, or application image is
attached. The fixed shape and selectors are supported by the provider and the
current workspace, as established in [[research.md#Compute and image selection]]
and [[research.md#Environment findings]].

The provider duration is the hard cost ceiling. Explicit destroy remains
mandatory.

## Local state

The harness stores one JSON file at:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/pios/namespace-macos.json
```

It contains only:

```json
{
  "schemaVersion": 1,
  "instanceId": "...",
  "runId": "...",
  "gitCommit": "...",
  "createdAt": "...",
  "deadline": "..."
}
```

The parent directory and file use modes `0700` and `0600`. Writes use a private
temporary file followed by an atomic rename. The Namespace token, source path,
workspace identity, and SSH material are never copied into state.

`dev-up` refuses an existing state file. It does not adopt an instance. A lost
state file is recovered manually with the printed `run-id` label and `nsc list`;
automatic reconciliation belongs to the controller.

## `dev-up`

### Preflight

All failures before create are free:

1. Require `nsc`, `git`, `curl`, `jq`, `sha256sum`, and `mktemp` from the
   default development shell.
2. Require a valid authenticated `nsc list --output json` request.
3. Print `nsc workspace concurrency` and require the operator to confirm that
   the `6x14` macOS allocation is available.
4. Refuse existing local state.
5. Require a clean worktree with no untracked files and resolve the full `HEAD`
   commit.
6. Create a Git bundle containing `HEAD`, clone it into a temporary directory,
   and require the cloned commit to equal the source commit.
7. Download Determinate Nix Installer `v3.22.0` for `aarch64-darwin` from the
   [pinned release artifact](https://install.determinate.systems/nix/tag/v3.22.0/nix-installer-aarch64-darwin).
   Require SHA-256
   `26dabfc07aaa7c5ece7a872b37e73099a6dc3b091b6b648fe812b04e3a8f1e84`.
8. Print the exact shape, selectors, duration, purpose, commit, and create
   command. Require an interactive `yes` response.

The pinned installer and rationale are established in
[[research.md#Nix bootstrap]]. A hash mismatch is an environmental or upstream
blocker; the harness must not use another URL or installer.

### Create and bootstrap

After confirmation:

1. Install a cleanup trap before invoking `nsc create`.
2. Generate the run ID and pass it as both a unique tag component and label.
3. Invoke `nsc create` with the fixed specification, a private `--cidfile`, and
   a private `--output_json_to` metadata file.
4. Persist the returned instance ID and deadline immediately in local state.
5. Upload the verified installer and Git bundle to distinct files under
   `/var/tmp/pios-bootstrap/`.
6. Run one fixed SSH command that creates `/work`, clones the bundle to
   `/work/pios`, checks out the exact detached commit, and invokes
   `tools/namespace-host remote-bootstrap` from that checkout.
7. Run the remote doctor once more through SSH.
8. Disable failure cleanup and print the instance ID, deadline,
   `make dev-shell`, and `make dev-down`.

`nsc create` writes its cidfile only after its readiness waiter returns. If
create fails before that write, the cleanup trap lists instances by the unique
`run-id` label. It destroys the result only if exactly one matching instance
exists. Zero or multiple results are reported without guessing; the provider TTL
remains the final cleanup boundary. This behavior follows the CLI details in
[[research.md#Compute and image selection]].

Any failure after an instance ID is known destroys that exact instance. A failed
destroy preserves state and prints the ID, deadline, and exact manual command.
No alternate image, shape, installer, transport, or bootstrap action is
attempted.

## Remote bootstrap

`remote-bootstrap` is a fixed, non-interactive operation:

1. Require `Darwin`, `arm64`, `/usr/bin/git`, `/usr/bin/curl`, and
   `/usr/bin/xcrun`.
2. Record `sw_vers`, `uname -m`, `xcodebuild -version`, `xcrun swift --version`,
   and the iPhoneOS SDK version.
3. Require macOS 26, non-beta Xcode 26, and a usable iPhoneOS SDK. Do not accept
   an Xcode license or run first-launch mutation automatically.
4. Require the remote repository `HEAD` to equal the expected commit and the
   worktree to be clean.
5. Require Nix to be absent before installation. An unexpected preinstalled Nix
   is image drift and stops the run rather than being replaced or adopted.
6. Download the pinned installer on the host, verify its hash, then execute:

   ```sh
   /var/tmp/pios-bootstrap/nix-installer \
     install macos \
     --determinate \
     --no-confirm \
     --diagnostic-endpoint=""
   ```

7. Load the installed daemon profile and require `builtins.currentSystem` to be
   `aarch64-darwin`.
8. Save `flake.lock`'s hash, run `nix develop .#namespace --command make check`,
   and require the lock hash and Git worktree to remain unchanged.
9. Print the recorded non-secret host facts. `dev-status` obtains fresh facts by
   running the same doctor.

The script treats provider software as an inspected prerequisite and Nix as the
only software it bootstraps. Missing Xcode tools, license state, unsupported
macOS, installer failure, flake evaluation failure, or a changed lockfile are
blockers. It does not use Homebrew, accept licenses, update dependencies, or
repair the image.

## Remaining commands

### `dev-status`

`dev-status` is read-only. It reads local state, obtains the matching instance
from `nsc list --output json`, verifies the instance ID and all management
labels, prints provider metadata, and runs the remote doctor. Missing or
mismatched provider state is an error.

### `dev-shell`

`dev-shell` verifies status, allocates a TTY through `nsc ssh`, changes to
`$HOME/pios`, and executes the installed `nix develop .#namespace`. It does not
forward the local SSH agent or inject environment credentials.

### `dev-down`

`dev-down` verifies that the provider instance ID and every management label
match local state, asks for confirmation, and invokes `nsc destroy` for that
exact ID. It clears local state only after `nsc list` no longer returns the
instance. Repeated `dev-down` clears matching stale state if the provider
already reports the instance absent.

## Failure and security properties

```text
failure before create       -> no paid resource
create fails, no cidfile     -> run-id lookup; exact single match only
bootstrap or doctor fails    -> destroy known exact instance
control process is killed    -> provider deadline destroys instance
destroy fails                -> retain state and report exact recovery command
identity or labels mismatch  -> refuse destruction
```

The design uploads only public source and a verified public installer. The
Namespace user token and generated SSH key remain inside `nsc`. The clean-commit
requirement excludes untracked credentials. No SSH agent, persistent volume,
provider secret, or Apple credential reaches the host.

The harness must use argument vectors for local commands. The only remote shell
text is a constant command with a validated hexadecimal commit and
provider-generated instance ID; source paths and user input are not
interpolated. ShellCheck and `shfmt` gate the script.

## Tasks

### Task 1 - Restore the control environment

Correct agent environment provisioning so `nix` and `direnv` are available from
the default development shell. Do not install them from inside the session.

**Verify:** `command -v nix direnv`, `nix --version`, and `make check` succeed.

### Task 2 - Expose the Namespace development shell

Add the Darwin-only shell, its unwrapped Pi binary, and the repository check and
formatter dependencies.

**Verify:** Linux `make check` remains green and
`nix eval .#devShells.aarch64-darwin.namespace.drvPath` succeeds without
changing `flake.lock`.

### Task 3 - Implement the minimum host harness

Add `tools/namespace-host` and the four Make targets. Exercise all preflight,
hash, clean-source, identity, label, and cleanup branches without a paid create
where possible. The create command remains behind explicit confirmation.

**Verify:** `make check` passes, declining confirmation invokes no create, and
the printed create specification exactly matches this document.

### Task 4 - Qualify one live host

With explicit cost approval, run `make dev-up`, `make dev-status`, and
`make dev-shell`. Record the provider image facts, then run `make dev-down` and
verify the managed instance is absent.

**Verify:** every acceptance criterion below has command output from the same
instance ID and commit.

## Acceptance criteria

The spike is complete when:

1. `devShells.aarch64-darwin.namespace` evaluates on NixOS and materializes on
   the Namespace Mac.
2. `dev-up` creates exactly one labelled `macos/arm64:6x14` instance with the
   two-hour provider deadline and requested selectors.
3. The host reports Darwin arm64, macOS 26, non-beta Xcode 26, Swift, and an
   iPhoneOS SDK.
4. `$HOME/pios` is a clean detached checkout of the exact local commit.
5. The remote installer matches the pinned SHA-256 and produces working Nix for
   `aarch64-darwin`.
6. `nix develop .#namespace --command make check` passes without changing source
   or `flake.lock`.
7. `make dev-shell` opens an interactive Namespace development shell on the same
   host.
8. No secret or persistent volume is attached to the host.
9. `make dev-down` destroys the exact labelled instance and clears local state.
10. The final labelled `nsc list --output json` result is empty.

A successful Xcode build is the next Task M0 gate, not part of this host spike.
