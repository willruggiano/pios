---
paths:
  - "**/*.md"
---

# Documentation conventions

- Internal references between documents use wiki-link style and always include
  the file extension: `[[architecture.md]]`,
  `[[posture.md#1. Think Before Coding]]`. Use `[[page.md|display text]]` only
  when the file name is not the desired display.
- External URLs use standard markdown link syntax:
  `[label](https://example.com)` or `<https://example.com>`.
- Use ASCII only. Do not use typographic punctuation, Unicode symbols, or emoji.
- Fenced code blocks always declare a language identifier (`rust`, `sql`, `sh`,
  `text`, ...).
- One H1 per document at the top. Section headings start at H2 and do not skip
  levels. Top-level documents use the standard header defined in
  [[documentation.md#Standard Header]]; [[index.md]] is exempt.
- Never duplicate content. If another doc already says it, link to it. Sources
  of truth:
  - [[architecture.md]] for system design.
  - [[posture.md]] for engineering posture and working principles.
  - [[contributing.md]] for setup, conventions, and tracking.
  - `docs/rules/` for code rules.
- One topic per document. Be concise and precise; cut sentences that do not add
  information.
- Write for progressive disclosure. Use [[index.md]] as the entry point, begin
  each document with enough purpose and scope for readers to decide whether to
  continue, order content from essential concepts and common workflows to
  specialized detail, and link to deeper material instead of duplicating it.
- No breadcrumbs or tombstones. Don't annotate code or prose with pointers to
  where something now lives or that it is generated elsewhere (e.g. "generated
  in `/some/file`", "bindings live in ...", "moved to ..."). File layout and the
  `// Code generated ... DO NOT EDIT.` header already convey this; such notes
  carry no information and go stale. When you move or delete code, delete its
  comment too. (A wiki-link to a doc that explains _why_ is different, and is
  encouraged above.)

Where mechanically checkable, these conventions are enforced by the
`markdownlint-cli2` pre-commit hook (see [[nix.md]]), plus custom rules for
ASCII-only text and the wiki-link form. "Never duplicate content" and "one topic
per document" remain review matters.
