# Coding Agent Instructions

- Tone: professional, succinct, blunt, precise, technical
- The user is: highly technical, not fucking around, and does not appreciate
  unsolicited recommendations
- Use ASCII diagrams to explain flow and/or relationships
- Prefer diagrams to prose
- Always cite your sources
- Plans must not leave unanswered "research" questions; primary evidence is
  required for all claims
- Code and documentation are the only acceptable form of primary evidence
  - Do: read a project's public documentation and/or clone and explore its
    source code
  - Don't: present data obtained from the web (via WebSearch, curl, mcp, or
    otherwise) as primary evidence

## Remote macOS Git Bundles

Transfer committed source through verified Git bundles:

```text
local clean commit -> upload bundle -> remote Mac -> return bundle -> local fast-forward
```

Send a clean local `HEAD`:

```sh
test -z "$(git status --porcelain=v1 --untracked-files=all)"
git bundle create /tmp/pios-source.bundle HEAD
git bundle verify /tmp/pios-source.bundle
sha256sum /tmp/pios-source.bundle
nsc instance upload --mkdir "$instance_id" /tmp/pios-source.bundle \
  /var/tmp/pios-source.bundle
```

On the Mac, clone the bundle, check out the expected commit, and commit all
remote work before return. Then create and verify the return bundle:

```sh
git -C "$HOME/pios" bundle create /var/tmp/pios-return.bundle HEAD
git -C "$HOME/pios" bundle verify /var/tmp/pios-return.bundle
shasum -a 256 /var/tmp/pios-return.bundle
git -C "$HOME/pios" status --porcelain=v1 --untracked-files=all
```

Require an empty final status. Record the remote `HEAD` and SHA-256, then
retrieve and integrate from a clean local worktree:

```sh
base=$(git rev-parse HEAD)
nsc instance download "$instance_id" /var/tmp/pios-return.bundle \
  /tmp/pios-return.bundle
sha256sum /tmp/pios-return.bundle
git bundle verify /tmp/pios-return.bundle
git fetch /tmp/pios-return.bundle HEAD
remote_head=$(git rev-parse FETCH_HEAD)
test "$remote_head" = "$expected_remote_head"
git merge-base --is-ancestor "$base" "$remote_head"
git log --oneline "$base..$remote_head"
git diff --stat "$base..$remote_head"
git merge --ff-only "$remote_head"
```

Compare the downloaded checksum with the recorded remote checksum before
fetching. Use `FETCH_HEAD`; do not create a transport-only
`refs/remotes/namespace/*` ref, which appears in colocated Jujutsu repositories
as a persistent `*@namespace` remote bookmark. Run local checks before deleting
the bundle or destroying the exact Namespace instance.

Source: `tools/namespace-spike.sh` and [[research.md#Access and transfer]].
