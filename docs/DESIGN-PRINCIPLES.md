# AUTOPHAGOUS — Design Principles

Layout structure and implementation rules. Sibling doc:
DESIGN-REQUIREMENTS.md (look/feel/color/type).

## 1. The surface

*(Revised 2026-08-16 — owner: the original centered "sheet on a bench"
read like a permanent print preview. Full-bleed now, dimensioned as
below.)*

The page IS the document: the frost `--paper` runs edge to edge, the
site nav is a full-width ink strip, and the document grid takes the
whole viewport — a 13rem contents rail holding the left margin, the
document body filling the rest (3.5rem outer gutters).

Inside the body, **rules span the full width; text does not.** Section
heads, the masthead, and the footer rule run edge to edge of the
content column, with the intent label at the far right. Body content
(clause bodies and panel blocks) is indented past the 3.4rem
clause-mark column and capped at a 56rem reading measure — the open
right side is deliberate, exactly the handbook's geometry. `--measure`
(44rem) survives only as the standfirst's cap and legacy references.

Components live in `src/protocol.css` and consume tokens from
`src/theme.css` only. Pages never define their own colors.

## 2. Page anatomy

masthead (kicker / h1 / standfirst) → numbered sections
(`.sec-head`: chip + condensed h2) → footer (disclaimer). Content
blocks: `.slab` (bordered, stenciled title) for mandatory/safety
content, `.note` (tinted, left-ruled) for asides and consequences,
tables for anything with columns of fact.

The hierarchy is semantic: **slab = binding**, **note = commentary**,
**hero row = the load-bearing fact in a table**.

## 2a. The document format (`Doc.elm`)

Adopted 2026-08-16. Every broadsheet page
wears the shared chrome: masthead, contents rail (side nav),
`§`-numbered sections, clause marks, footer.

- **The boundary: `Doc` numbers and frames; the page renders.** A page
  hands over body content and gets it back inside the chrome. `Doc`
  never learns what a stage card or citation entry is.
- **Sections are one ordered list; the rail and the numbers derive
  from it** — they cannot disagree. In-prose cross-references
  ("see §09") are the one hand-maintained thing: reordering sections
  means grepping the page for `§`.
- `Clauses` bodies give each top-level block a citable `§N.M` margin
  mark; `Panel` bodies (apparatus with its own structure — stage
  cards, the log grid, the reference list) are numbered at section
  level only.
- The rail is sticky beside the sheet on desktop; below 960px it
  becomes a sticky ink jump-strip; clause marks and intents drop at
  640px; print hides the rail entirely.
- `#anchor` jumps are performed by the shell (`Main.jumpTo`, via
  `Browser.Dom`) because `Browser.application` swallows the browser's
  default fragment scroll.

*(Amended 2026-08-16 — the sticky chrome. Owner: navigation must be
reachable at any scroll depth.)*

- **The site nav is sticky too** (`top: 0`, z-index 30), so the route
  links and the theme control never scroll away. Its height is the
  `--nav-h` token applied as a hard `height`, not a by-product of
  padding — everything that has to clear the nav measures from that
  token, so the token and the rendered bar cannot disagree.
- The desktop rail's sticky offset is `--nav-h + 1rem`; the ≤960px
  jump-strip parks at exactly `--nav-h` (z-index 20, under the nav) so
  the two read as one chrome band rather than overlapping.
- **The rail cell stretches** (`align-self: stretch`). The layout's
  `align-items: start` had been sizing the cell to the rail's own
  height, which left `position: sticky` no travel and silently made
  the desktop rail scroll away — sticky needs a containing block
  taller than itself.
- The rail scrolls inside its own sticky box
  (`max-height: 100vh - --nav-h - 2rem`), so a short viewport can
  still reach the last section.
- `Main.jumpTo` **measures** the sticky chrome (the nav, plus the rail
  when it is in strip form) instead of carrying a hard-coded offset.
  It tells the rail's two forms apart by width against the viewport,
  not by knowing the breakpoint — the breakpoint stays in the
  stylesheet. A number in the Elm that has to match a number in the
  CSS is a number that will drift.

## 3. Elm structure

- `src/Main.elm` — the TEA shell: URL wiring, nav, page dispatch.
  All state lives here.
- `src/Route.elm` — pure routing (no Cmd, no ports); unit-tested.
  Adding a route = adding a line to `public/_redirects` (scoped
  redirects, no wildcard — the friction is the point; see DEPLOY.md's
  404 contract for what a wildcard would break).
  `parse` returns `Maybe Route` (the honest answer); `fromUrl` is the
  total version that falls back to the protocol sheet. The shell needs
  both — see the asset-link rule below.

*(Amended 2026-08-17 — links to static assets.)*

- **A same-origin link that is not a route must reach the browser.**
  `Browser.application` intercepts every same-origin `<a>` click, so
  `LinkClicked (Internal url)` branches on `Route.parse`: a real route
  pushes, anything else (`/downloads/*.pdf`) gets `Nav.load`. Pushing
  an asset URL instead silently swaps the address bar and re-renders
  the protocol sheet while the file never loads — which is exactly how
  the cycle-log download was broken.
- Download links additionally carry `download` — it names the saved
  file, and Elm's click handler skips any `<a>` that has the
  attribute, so the click never enters the app at all.
- `src/Page/*.elm` — pure views, one module per route. No state of
  their own until a page genuinely needs it.
- Content lives in Elm view code for now. If a second long-form page
  appears, revisit extracting a content model — not before.

## §print — the print strategy

Priority artifact: **the cycle log.**

- The live site is never forced to be printable. `@media print` CSS is
  a courtesy fallback, not a contract.
- Printable artifacts are authored in **typst** (`typst/*.typ`) and
  compiled to `public/downloads/*.pdf` via `npm run print`. The site
  links to the compiled PDFs.
- typst sources use only fonts typst embeds (Libertinus Serif, DejaVu
  Sans Mono) so artifacts compile identically everywhere.
- Long-term direction (owner, 2026-08-16): typst may become the single
  source for content that exists both live and printed. Until a
  generator exists, the protocol content is maintained in
  `src/Page/Protocol.elm` and the cycle log in `typst/cycle-log.typ`;
  a content change to the log means editing the typst source and
  recompiling — the Elm log table mirrors it manually.

## 5. The source index

Policy doc: RESOURCES-POLICY.md. The manifest in
`src/Page/Resources.elm` is the single source of truth for citation
metadata and access state.

*(Revised 2026-08-16 — owner: link-first, never rehost. The local PDF
archive under `public/resources/pdf/` is retired; read access on a
repository was never redistribution permission, and a frozen copy
cannot report a paper's later correction. Full reasoning in the policy
doc.)*

- Every entry links out. Nothing is served from this repo.
- `Access` states come from Unpaywall, DOIs from CrossRef, and both
  are verified per entry — a title-only CrossRef match returns
  commentaries and corrigenda ahead of papers.
- Slugs survive as per-entry anchors: `/resources#<slug>` is a
  permanent public address for one citation.
