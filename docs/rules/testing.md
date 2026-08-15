---
# TODO: define testing standards once packages exist
# paths:
#   - "**/*.rs"
---

# Test conventions

Procedures for running tests and conventions for writing them. Design rationale
lives in the linked ADRs; this document records the rules. The strictness
posture is in [[contributing.md#Strictness]]; engineering principles in
[[posture.md]].

## What to test

- Exercise behavior through interfaces and public methods, not internals.
