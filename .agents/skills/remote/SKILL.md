---
name: remote
description:
  Runs approved Namespace macOS work through Git bundles, operator Pi
  authentication, serialized remote Pi agents, verified return, and exact
  cleanup.
compatibility:
  Requires nsc, jj, git, jq, sha256sum, and Namespace authentication.
---

# Remote macOS

```text
local commit -> Namespace Mac -> Pi agents -> remote commit -> local fast-forward
```

Require paid-operation approval, a two-hour deadline, toolchain-family matching,
serialized writers, and exact-instance cleanup. Freeze local source until
return.

## Send

```sh
test -z "$(jj diff --summary)"
jj bookmark set develop -r @-
test -z "$(git status --porcelain=v1 --untracked-files=all)"
base=$(git rev-parse HEAD)
printf '%s\n' "$base" >/tmp/pios-base
git bundle create /tmp/pios-source.bundle HEAD
git bundle verify /tmp/pios-source.bundle
sha256sum /tmp/pios-source.bundle

run_id=$(date -u +%Y%m%dT%H%M%SZ)-$$
nsc create --bare --machine_type=macos/arm64:6x14 \
  --selectors=macos.version=26.x,image.with=xcode-26 \
  --duration=2h --wait_timeout=10m \
  --unique_tag="pios-${base:0:12}-$run_id" \
  --label=managed-by=pios-manual --label=project=pios \
  --label=role=development --label="source-commit=$base" \
  --label="run-id=$run_id" --cidfile=/tmp/pios-instance-id
instance_id=$(</tmp/pios-instance-id)
nsc instance upload --mkdir "$instance_id" /tmp/pios-source.bundle \
  /var/tmp/pios-bootstrap/pios.bundle
nsc instance upload --mkdir "$instance_id" tools/namespace-spike-remote.sh \
  /var/tmp/pios-bootstrap/remote.sh
nsc instance upload --mkdir "$instance_id" /tmp/pios-base \
  /var/tmp/pios-bootstrap/expected-commit
nsc ssh --disable-pty "$instance_id" \
  '/bin/bash /var/tmp/pios-bootstrap/remote.sh bootstrap'
```

Require Xcode 26.x, Swift 6.x, and iOS SDK 26.x. Record exact observed facts;
destroy and stop on a major-version mismatch.

## Authenticate and Run

Operator:

```sh
nsc ssh "$instance_id"
cd "$HOME/pios"
export PATH=/nix/var/nix/profiles/default/bin:$PATH
nix develop .#remote
pi # /login, /model, /quit
```

Controller, once per implementation/review/correction prompt:

```sh
nsc instance upload --mkdir "$instance_id" /tmp/remote-prompt.md \
  /var/tmp/pios-prompts/task.md
nsc ssh --disable-pty "$instance_id" \
  'cd "$HOME/pios" && PATH=/nix/var/nix/profiles/default/bin:$PATH nix develop .#remote --command pi --approve --provider PROVIDER --model MODEL -p @/var/tmp/pios-prompts/task.md "Execute the attached prompt."'
```

Never expose credentials. Stop for operator Xcode GUI work; never handcraft
Xcode-owned files.

## Return

On the Mac:

```sh
cd "$HOME/pios"
make check
test -z "$(git status --porcelain=v1 --untracked-files=all)"
git bundle create /var/tmp/pios-return.bundle HEAD
git bundle verify /var/tmp/pios-return.bundle
git rev-parse HEAD
shasum -a 256 /var/tmp/pios-return.bundle
```

Record `expected_remote_head` and `expected_remote_sha256`. Locally:

```sh
base=$(</tmp/pios-base)
test -z "$(jj diff --summary)"
test "$(git rev-parse HEAD)" = "$base"
nsc instance download "$instance_id" /var/tmp/pios-return.bundle \
  /tmp/pios-return.bundle
test "$(sha256sum /tmp/pios-return.bundle | awk '{print $1}')" = \
  "$expected_remote_sha256"
git bundle verify /tmp/pios-return.bundle
git fetch /tmp/pios-return.bundle HEAD
remote_head=$(git rev-parse FETCH_HEAD)
test "$remote_head" = "$expected_remote_head"
git merge-base --is-ancestor "$base" "$remote_head"
git log --oneline "$base..$remote_head"
git diff --stat "$base..$remote_head"
jj bookmark set develop -r "$remote_head"
jj rebase -s @ -d develop
make check
```

Use `FETCH_HEAD`; never create a transport-only `refs/remotes/*` ref.

## Destroy

```sh
instance_id=$(</tmp/pios-instance-id)
nsc destroy --force "$instance_id"
test "$(nsc list --output json | jq --arg id "$instance_id" \
  '[.[]? | select(.cluster_id == $id)] | length')" -eq 0
rm -f /tmp/pios-{base,instance-id,source.bundle,return.bundle}
```

Sources: `tools/namespace-spike.sh`, `tools/namespace-spike-remote.sh`, and
[[research.md#Access and transfer]].
