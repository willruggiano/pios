# Namespace macOS host research

Evidence and constraints for the minimum Namespace macOS development-host spike.

Browse [[index.md]] for the full documentation set.

## Scope

This research narrows the Namespace portion of [[build.md]] to one outcome:
create a time-limited macOS host, transfer the current repository revision, and
enter the repository's Nix development environment on that host.

The spike does not build the iOS app, qualify signing or TestFlight, implement
the Compute API client, retain build artifacts, or implement the complete
`pios-devctl` lifecycle.

Research was performed on 2026-08-15 against:

- repository commit `62057696a6bbaff3b2933e0a2d75255fcfa7b716`;
- Namespace CLI `0.0.556`, from the locked Nixpkgs revision;
- Namespace Foundation tag `v0.0.556` at commit
  `da630dcd8e336f91e186bdae2d81aefe0e835492`;
- Namespace Integrations commit `6a8135624a35139cb70c5d74be1323beed7f8275`; and
- Determinate Nix Installer `v3.22.0` at commit
  `766baaa81e72c2e1014313019970f97d2e529650`.

## Conclusion

The minimum path is CLI-driven creation followed by an SSH bootstrap:

```text
NixOS control host
  |
  | nsc create --machine_type macos/arm64:6x14 --duration 2h ...
  v
Namespace macOS host
  |
  | nsc instance upload: Git bundle + pinned Nix installer
  | nsc ssh: clone bundle, install Nix, enter flake
  v
Detached repository revision in devShells.aarch64-darwin.namespace
```

This path uses provider-supported lifecycle, transfer, and private SSH
interfaces without introducing the Go SDK, an application image, a registry
push, or a daemon. The Compute API application path is valid but unnecessary for
this outcome. [NS-CREATE] [NS-SSH] [NS-UPLOAD] [NS-MACOS] [NS-MACRUN]

The provider and workspace can supply the required host. The repository cannot
yet supply its development environment on that host because the flake exposes
only `x86_64-linux`, and the default Pi wrapper is built around Linux
bubblewrap. [REPO-FLAKE] [REPO-DEV-PI] [JAIL]

## Provider contract

### Compute and image selection

Namespace documents native Apple Silicon macOS compute, Xcode and iOS tooling,
SSH, and VNC. macOS image selectors choose an image family, not an immutable
image. The required spike request is therefore:

```text
machine type: macos/arm64:6x14
selectors:    macos.version=26.x,image.with=xcode-26
duration:     2h
mode:         bare
```

The shape and duration match the canonical development-host decision in
[[build.md#2.1 Instance profile]]. The image must be inspected after creation
because Namespace continuously updates selected images. [NS-MACOS]

`nsc create` directly supports the machine type, selectors, duration, bare mode,
labels, purpose, unique tag, and an instance-ID output file. Its implementation
waits for readiness before returning and writes the instance ID to `--cidfile`
without requiring output parsing. The deprecated `--ephemeral` flag has no
effect on the request and must not be used. [NS-CREATE] [NS-CREATE-SOURCE]

A provider duration is mandatory even though the host is also explicitly
destroyed. It is the cleanup boundary if the control process is lost.
`nsc destroy` destroys an exact instance ID, and `nsc extend` can enforce a
minimum remaining duration if later work needs it. [NS-DESTROY] [NS-EXTEND]

### Access and transfer

`nsc ssh` tunnels an end-to-end encrypted SSH connection without exposing the
host directly to the Internet. The CLI source defaults host SSH to `root`,
supports non-interactive commands, and obtains per-instance connection material
from Namespace. [NS-SSH] [NS-SSH-SOURCE]

`nsc instance upload` transfers one local file to one remote path. Its source
opens a regular local file and streams it over the same SSH facility. A Git
bundle is therefore the smallest source-transfer unit that preserves commit
identity and yields a real repository after cloning. A local proof created a
67,450-byte bundle for the researched revision, cloned it, and obtained the same
`HEAD`. [NS-UPLOAD] [NS-REMOTE-SOURCE]

VNC exists but is not required for a command-line development host. It remains a
diagnostic path for later Xcode GUI work. [NS-REMOTE-DISPLAY]

### Custom applications

Namespace also supports applications attached to a macOS Compute API request.
The official example cross-compiles a `darwin/arm64` Go binary, packages it as
an OCI layer, pushes it to the Namespace registry, creates the instance, and
waits for readiness. That path requires SDK code and registry handling. It does
not remove the need to make this repository's flake support Darwin, so it is not
the minimum bootstrap. [NS-MACOS] [NS-MACRUN]

The reviewed Namespace Devbox custom-image workflow builds Dockerfile base
images and does not document macOS hosts. It therefore does not establish Devbox
as a substitute for macOS Compute in this spike. [NS-DEVBOX-IMAGES]

## Nix bootstrap

Namespace's Nix integration instructs operators to create a bare instance and
install Nix after SSH connection. Its example is Linux-specific, but it
establishes post-create installation as the supported Namespace pattern.
[NS-NIX]

Determinate Nix Installer `v3.22.0` provides a macOS planner for Apple Silicon,
configures `launchd`, creates the macOS Nix store volume, enables flakes, and
supports non-interactive installation. Its source lists `aarch64-darwin` as a
supported system. [NIX-INSTALLER] [NIX-INSTALLER-FLAKE]

The bootstrap should not execute an unpinned `curl | sh` pipeline. The `v3.22.0`
`aarch64-darwin` installer artifact is 58,228,944 bytes with SHA-256:

```text
26dabfc07aaa7c5ece7a872b37e73099a6dc3b091b6b648fe812b04e3a8f1e84
```

The control host can download and verify that artifact before upload. The remote
host then executes only the verified file with the `macos` planner,
`--no-confirm`, and diagnostic reporting disabled. The installer version pins
its associated Nix distribution; the installed `nix --version` remains an
acceptance fact recorded from the host. [NIX-INSTALLER]

## Repository gaps

The current flake is not a Darwin development environment:

1. `flake.nix` declares only `x86_64-linux`. [REPO-FLAKE]
2. `nix/dev/pi/default.nix` always exposes the bubblewrap-jailed Pi package in
   the default shell. [REPO-DEV-PI]
3. The locked `jail.nix` implementation invokes `pkgs.bubblewrap` and Linux
   namespace flags. Its examples and tests expose only `x86_64-linux`. [JAIL]
4. The underlying locked Pi package explicitly supports `aarch64-darwin`. The
   incompatibility is the repository wrapper, not Pi. [PI-PACKAGE]
5. `nix/dev/default.nix` has one unconditional package list. Darwin-specific
   availability has not been evaluated because `nix` is absent from the active
   coding-agent environment. [REPO-DEV]

The direct correction is to add an `aarch64-darwin` Namespace shell, retain the
jailed Pi package on Linux, expose unwrapped Pi in the Namespace shell, and keep
platform-specific utilities out of the common package list. A successful Darwin
flake evaluation and remote `nix develop .#namespace` are required evidence;
source inspection alone does not claim they already work.

## Environment findings

Read-only provider checks produced this state:

| Check                    | Finding                                       |
| ------------------------ | --------------------------------------------- |
| Namespace authentication | Valid for workspace `pios`                    |
| macOS concurrency        | 6 vCPU and 14 GiB available, 0 in use         |
| Active instances         | None                                          |
| Paid create              | Not attempted                                 |
| Installed `nsc`          | Nix store package `namespace-cli-0.0.556`     |
| `nsc version`            | Fails because Go VCS build metadata is absent |
| `nix` on control host    | Missing                                       |
| `direnv` on control host | Missing                                       |

The workspace has exactly enough macOS concurrency for the selected `6x14`
shape. The first live create is still subject to provider capacity at request
time. [NS-CREATE]

The `nsc version` failure is explained by source: the command requires Go
`vcs.revision` build information, while the Nixpkgs derivation sets only the
release tag through linker flags. Authenticated create, list, SSH, transfer, and
destroy commands remain available. This is a provenance defect, not a host
lifecycle blocker. [NS-VERSION-SOURCE] [NIXPKGS-NSC]

The missing control-host `nix` and `direnv` commands violate
[[contributing.md#Development Environment]] and block local flake evaluation.
They must be reported and corrected by environment provisioning; installing an
alternate Nix inside the coding session would violate repository rules.

## Acceptance boundary

The first paid run must establish these facts through public command interfaces:

- the requested shape, labels, selectors, and deadline identify the instance;
- SSH reaches a Darwin `arm64` host as the provider-managed account;
- `xcodebuild`, `xcrun`, the iPhoneOS SDK, and a non-beta Xcode installation are
  usable;
- the uploaded Git bundle clones to the exact local commit;
- the verified installer produces working Nix on `aarch64-darwin`;
- `nix develop .#namespace` enters the repository's Namespace Darwin shell;
- `make check` passes from that shell;
- an interactive development shell can be reopened; and
- explicit destroy removes the exact instance from `nsc list`.

Exact Xcode build, SDK, Swift, macOS, and image values are recorded by this run.
Enforcement against `Toolchain.env`, iOS compilation, simulators, source
worktree overlays, artifacts, cache volumes, extension, adoption, garbage
collection, and interrupt-complete lifecycle handling belong to the later Task
M0 controller work in [[build.md#14. Inception-to-TestFlight tasks]].

## Sources

[REPO-FLAKE]: ../../../flake.nix
[REPO-DEV]: ../../../nix/dev/default.nix
[REPO-DEV-PI]: ../../../nix/dev/pi/default.nix
[NS-MACOS]: https://namespace.so/docs/architecture/compute/macos
[NS-CREATE]: https://namespace.so/docs/reference/cli/create
[NS-SSH]: https://namespace.so/docs/reference/cli/ssh
[NS-UPLOAD]: https://namespace.so/docs/reference/cli/instance-upload
[NS-DESTROY]: https://namespace.so/docs/reference/cli/destroy
[NS-EXTEND]: https://namespace.so/docs/reference/cli/extend
[NS-REMOTE-DISPLAY]:
  https://namespace.so/docs/architecture/compute/ssh-remote-display
[NS-NIX]: https://namespace.so/docs/integrations/nix
[NS-DEVBOX-IMAGES]: https://namespace.so/docs/devbox/images
[NS-CREATE-SOURCE]:
  https://github.com/namespacelabs/foundation/blob/da630dcd8e336f91e186bdae2d81aefe0e835492/internal/cli/cmd/cluster/create.go#L28-L176
[NS-SSH-SOURCE]:
  https://github.com/namespacelabs/foundation/blob/da630dcd8e336f91e186bdae2d81aefe0e835492/internal/cli/cmd/cluster/ssh.go#L199-L359
[NS-REMOTE-SOURCE]:
  https://github.com/namespacelabs/foundation/blob/da630dcd8e336f91e186bdae2d81aefe0e835492/internal/cli/cmd/cluster/remote.go#L64-L220
[NS-VERSION-SOURCE]:
  https://github.com/namespacelabs/foundation/blob/da630dcd8e336f91e186bdae2d81aefe0e835492/internal/cli/version/version.go#L18-L64
[NS-MACRUN]:
  https://github.com/namespacelabs/integrations/blob/6a8135624a35139cb70c5d74be1323beed7f8275/examples/macrun/macrun.go#L42-L171
[NIXPKGS-NSC]:
  https://github.com/NixOS/nixpkgs/blob/6b5e5b7a6631f065bf6908986990b37d845f847f/pkgs/by-name/na/namespace-cli/package.nix
[NIX-INSTALLER]:
  https://github.com/DeterminateSystems/nix-installer/blob/766baaa81e72c2e1014313019970f97d2e529650/README.md
[NIX-INSTALLER-FLAKE]:
  https://github.com/DeterminateSystems/nix-installer/blob/766baaa81e72c2e1014313019970f97d2e529650/flake.nix#L37-L53
[JAIL]:
  https://git.sr.ht/~alexdavid/jail.nix/tree/404e7da9da5ab9aa643666682b2ba1312fa5fbe8/item/lib/jail.nix
[PI-PACKAGE]:
  https://github.com/numtide/llm-agents.nix/blob/b4a645976fff76ef94dd60b7d4f9deaa216f40bd/packages/pi/package.nix#L20-L29
