# Wishlist

Things I want someday. Not actionable unless explicitly directed.

**Namespace billing details:** When `devctl` comes together, it should be easy
to track my Namespace usage without having to visit the namespace console.

**Exact Apple toolchain selection:** Qualification currently accepts Xcode 26.x,
Swift 6.x, and iOS SDK 26.x. Pin an exact provider image and toolchain once
Namespace exposes a stable selector for them.

**Remote macOS bootstrap is gross:** The [[remote/SKILL.md]] guidance is a
cluster fuck of gross oneliners. This skill is a temporary measure while we
build out `devctl` ahead of product development, however it HAS to be cleaned
up. Ideally this remote bootstrap process should use Nix. We can and should set
everything up through Nix, short of Xcode (but even that we can still _automate_
through Nix). The remote bootstrap process should be a "deploy nixos
configuration" action, not a "run a bunch of scripts and pray" action. We
probably even want to integrate something like sops-nix at some point -- maybe
that even solves Pi authentication?

**Binary cache:** The macOS bootstrap process is slow. We can speed it up by
adding a binary cache and/or a Namespace cache volume, which is automatically
updated via CI.

**Pi extension:** This is somewhat unrelated to PiOS itself, but is nonetheless
a fun thought experiment. The idea is that, within `pi`, I can @-mention a
_remote `pi` agent_ to have `pi` execute remotely, eg.
`@namespace implement <some iOS feature>` to run `pi` from my remote Namespace
macOS instance. This turns a local `pi` into something resembling a group chat!
Pretty neat. This would also work well with a `pi --remote=namespace` option,
which would enable the local `pi` to perform remote actions. So I could say "do
this on the namespace remote" and the local `pi` would orchestrate through the
remote instance. This _should be_ async/non-blocking, ie. I should be able to
continue my local `pi` conversation while remote agents are executing (similar
to `claude`'s ability to run tasks in the background).
