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
configuration" action. We probably even want to integrate something like
sops-nix at some point -- maybe that even solves Pi authentication?
