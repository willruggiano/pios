# Task M0 implementation plan

Implementation order, gates, and verification criteria for the Task M0 build
spine.

Browse [[index.md]] for the full documentation set.

**Status:** in progress; Task 1 complete

## Scope and assumptions

The source of truth is [[build.md#14. Inception-to-TestFlight tasks]]. M0 adds
only the build spine and a minimal "Hello, Pi" qualification app. Gateway,
protocol, APNs, product UI, and production release work begin after M0.

The plan has four hard constraints:

- Qualification requires Xcode 26.x, Swift 6.x, and iOS SDK 26.x. Record the
  exact observed versions and builds as provenance; do not reject a matching
  major-version family.
- Apple enrollment, permanent identifiers, signing assets, App Store Connect
  access, and physical-device installation are operator inputs.
- Every paid operation requires separate approval, a provider deadline, and
  confirmed exact-instance destruction.
- The spike scripts remain qualification evidence; `pios-devctl` becomes the M0
  lifecycle interface.

Sources: [[build.md#2.1 Instance profile]],
[[build.md#5.3 Apple account setup]], [[findings.md]], and [[summary.md]].

## Execution order

```text
free/local
  package contracts
    -> minimal iOS project
    -> controller and remote helper
    -> Nix outputs, commands, and fake-provider tests

explicit cost approval
  -> live lifecycle qualification
  -> exact-image simulator build and test

operator Apple prerequisites and release approval
  -> archive, validate, retrieve, and upload
  -> internal TestFlight install
  -> confirm no managed instance remains
```

## Task 1 - Establish package contracts

- [x] Create `packages/devctl` and `packages/ios` using the layout in
      [[contributing.md#Repository Layout]].
- [x] Add required package Makefile targets and only the M0-specific root
      targets defined in [[build.md#6. One command surface]].
- [x] Add checked-in Namespace configuration and Apple toolchain configuration;
      keep provider-derived exact values fail closed until qualification.
- [x] Ignore `packages/devctl/.state/` and `packages/devctl/artifacts/` in the
      package-owned `.gitignore`, excluding both from Nix source inputs.
- [x] Keep Makefiles free of Nix invocation, dependency installation, lockfile
      updates, and paid work hidden behind ordinary checks.

**Verify:** Makefile help exposes the agreed commands, configuration parsing
rejects unknown fields, ignored state is absent from `git ls-files`, and
`make check` remains read-only.

## Task 2 - Add the minimal iOS qualification app

- [ ] Add a thin Xcode project containing one SwiftUI app target that renders
      "Hello, Pi" and one infrastructure smoke-test target.
- [ ] Commit project-owned `.xcconfig` files, a shared scheme, and empty shared
      pull-request, UI, and performance test plans. Run the smoke test directly
      from the scheme so future product plans remain empty.
- [ ] Pin deployment target, architecture, Swift language mode, strict
      concurrency, warnings-as-errors, bundle settings, and explicit
      version/build overrides.
- [ ] Add deterministic package-owned scripts for simulator creation, build,
      test, archive, export, and artifact collection. They must select only the
      configured runtime and device type and disable automatic package
      resolution.
- [ ] Commit Xcode-owned lock metadata produced by the qualified Xcode and
      require normal commands to leave it unchanged.

**Verify:** `xcodebuild -list` finds the project and shared scheme on the
qualified Mac; the app contains no gateway, protocol, external package, or
product behavior.

## Task 3 - Implement the controller and remote helper

- [ ] Create the Go module and pin Namespace Integrations commit
      `6a8135624a35139cb70c5d74be1323beed7f8275` plus generated API dependencies
      in `go.mod` and `go.sum`.
- [ ] Implement the typed `RemoteMac` boundary, lifecycle, state, labels, cost
      controls, exit codes, and redaction contract from
      [[build.md#7. pios-devctl: the remote-development controller]].
- [ ] Use the Compute API for lifecycle and argument-vector `nsc` processes for
      private SSH, VNC, upload, and download.
- [ ] Cross-build a pure-Go `darwin/arm64` helper, package it as an immutable
      OCI image, and expose only fixed doctor, build, test, archive, upload, and
      artifact operations.
- [ ] Transfer a verified clean Git bundle, verify exact remote source identity,
      and reject dirty release input.
- [ ] Generate checksummed artifacts and the provenance manifest from
      [[build.md#12. Build provenance and artifacts]] before download. Reject
      symlink escape, traversal, checksum mismatch, and sensitive retained
      output.
- [ ] Test lifecycle and process behavior through public commands with an
      in-memory `RemoteMac` and fake process runner.

**Verify:** tests cover every lifecycle failure edge, cancellation, duplicate
`up`, foreign labels, deadline bounds, atomic-state recovery, idempotent down,
redaction, command arguments, transfer integrity, and artifact extraction.

## Task 4 - Add Nix outputs, checks, and operator commands

- [ ] Import each package directly from `flake.nix`.
- [ ] Add Linux `packages.pios-devctl` and a pure-Go Darwin arm64
      `packages.pios-remote`, both with fixed dependency hashes.
- [ ] Provision all directly invoked Go and Swift tools through the appropriate
      development shell and add strict format, vet, static-analysis, test, and
      coverage gates.
- [ ] Keep `nsc` directly available for login and transport while keeping
      Linux-only controller dependencies out of the Darwin Namespace shell.
- [ ] Wire root commands to the packaged controller without `nix run` or shell
      command construction.

**Verify:** `make check`, package checks and tests, `nix flake check`,
controller build, remote-helper cross-build, and Darwin shell evaluation pass
without changing `flake.lock`.

## Task 5 - Complete free verification

- [ ] Prove `namespace-doctor` authenticates and reports workspace/capacity
      without a create request.
- [ ] Prove declining each cost confirmation calls no provider mutation.
- [ ] Run controller coverage against the fake provider and fake process runner.
- [ ] Hash every dependency lock before and after checks and require no change.
- [ ] Require a clean worktree and an empty M0-managed provider query.

**Verify:** all local gates pass with no paid operation and no source mutation.

## Task 6 - Qualify live lifecycle behavior

This Task requires explicit cost approval. Each instance uses a 15-minute
provider deadline and is destroyed immediately after its assertions.

- [ ] Instance A: create, wait, inspect metadata, run doctor, round-trip a
      random checksum fixture, extend within bounds, and run explicit down.
- [ ] Instance B: interrupt a blocked one-shot operation and prove deferred
      evidence collection and exact-instance destruction.
- [ ] Instance C: run label-scoped garbage collection with a test orphan
      threshold, refuse foreign labels, and destroy only the test instance.
- [ ] Record non-secret instance IDs, labels, deadlines, SDK revision, image
      facts, and cleanup results.

**Verify:** `make test-devctl-live` passes and both the Compute API and `nsc`
report no managed instance. Incomplete cleanup fails M0.

## Task 7 - Qualify simulator build and test

This Task requires explicit cost approval and an image matching the
major-version families in `Toolchain.env`.

- [ ] Run the doctor before build work, reject major-version mismatches, and
      record exact observed toolchain facts.
- [ ] Build with signing and automatic dependency resolution disabled.
- [ ] Run the infrastructure smoke test on the pinned simulator.
- [ ] Retrieve and verify the app, `.xcresult`, logs, checksums, and manifest
      before exact-instance destruction.
- [ ] Prove source and dependency locks remained unchanged.

**Verify:** `make build-ios` and `make test-ios` pass for one clean commit and
qualified image, and no managed instance remains.

## Task 8 - Qualify signing and internal TestFlight

This Task requires the operator prerequisites in
[[build.md#5.3 Apple account setup]] and explicit release approval.

- [ ] Make release preflight require the permanent identifiers, app record,
      internal group, matching distribution identity/profile, export-compliance
      data, and upload authorization without printing secret values.
- [ ] Materialize release inputs only in private runtime storage, import them
      into a temporary remote Keychain after doctor passes, and delete plaintext
      after import.
- [ ] On a fresh release instance, archive once, export once, and inspect
      identity, entitlements, signature, arm64 slice, profile, and dSYM UUIDs.
- [ ] Retrieve and verify the archive, IPA, dSYMs, test result, logs, checksums,
      and manifest before upload.
- [ ] Use Namespace VNC for first Organizer validation and upload as specified
      in [[build.md#11.3 Validate and upload]].
- [ ] Wait for processing, resolve compliance, add the build to the internal
      group, and install it on the physical test iPhone.
- [ ] Delete signing material and destroy the exact release instance on every
      exit path.

**Verify:** the retained archive and uploaded build have the same identity, the
app installs through internal TestFlight, retained output contains no secret,
and no managed instance remains. A Namespace signing or upload limitation stops
M0 and triggers the provider fallback in
[[build.md#2.2 Provider qualification and fallback]].

## Task 9 - Close M0

- [ ] Record command output, artifact hashes, image facts, TestFlight identity,
      and cleanup evidence in an M0 findings document.
- [ ] Update this plan from primary evidence and run all free checks on the
      completed commit.
- [ ] Confirm M1 behavior is absent and both provider query paths are empty.

**Verify:** all Task M0 exit conditions have evidence tied to one commit, the
TestFlight app installs, and every paid instance is absent.

## Completion criteria

| Criterion    | Evidence                                                                                                                     |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| Build spine  | Flake outputs, Makefiles, controller/helper builds, and local checks pass from a clean NixOS checkout.                       |
| Lifecycle    | Fake and live tests prove create, wait, transfer, extend, interrupt cleanup, down, and label-scoped garbage collection.      |
| Toolchain    | Doctor accepts only configured major-version families and records exact Xcode, Swift, SDK, runtime, device, and macOS facts. |
| Simulator    | The minimal app builds and its smoke test returns verified artifacts.                                                        |
| Distribution | One retrieved archive is uploaded without rebuilding, processed, assigned internally, and installed through TestFlight.      |
| Security     | Secrets enter no Git or Nix input, command argument, state, routine log, manifest, or retained result.                       |
| Cleanup      | Exact destroy succeeds and both provider query paths report no managed instance.                                             |
| Scope        | The app contains only qualification UI and its infrastructure test.                                                          |

## Stop conditions

Stop rather than substitute another path when the toolchain family, Apple
inputs, provider capacity, source identity, labels, lockfiles, checksums,
artifact paths, signature, or cleanup cannot be verified. A destroy failure
retains local state and reports the exact recovery command; the provider
deadline remains the final cost boundary.

## Sources

- M0 scope and exit: [[build.md#14. Inception-to-TestFlight tasks]].
- Controller and lifecycle contract:
  [[build.md#7. pios-devctl: the remote-development controller]].
- Apple build and distribution contract: [[build.md#8. Build procedures]],
  [[build.md#10. Signing and secret handling]], and
  [[build.md#11. Archive and TestFlight procedure]].
- Repository contract: [[contributing.md]].
- Spike and provider evidence: [[research.md]], [[findings.md]], and
  [[summary.md]].
