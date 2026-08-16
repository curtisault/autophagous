# AUTOPHAGOUS — Design Principles

Layout structure and implementation rules. Sibling doc:
DESIGN-REQUIREMENTS.md (look/feel/color/type).

## 1. The surface

*(Revised 2026-08-16 — owner: the original centered "sheet on a bench"
read like a permanent print preview. Full-bleed now, dimensioned like
cryovault's handbook.)*

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

Adopted 2026-08-16 from cryovault's `Doc.elm`. Every broadsheet page
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

## 3. Elm structure

- `src/Main.elm` — the TEA shell: URL wiring, nav, page dispatch.
  All state lives here.
- `src/Route.elm` — pure routing (no Cmd, no ports); unit-tested.
  Adding a route = adding a line to `public/_redirects` (scoped
  redirects, no wildcard — cryovault's policy, kept).
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

## 5. Resources archive

Policy doc: RESOURCES-ARCHIVE.md. The manifest in
`src/Page/Resources.elm` is the single source of truth for citation
metadata and archive status; PDFs land at
`public/resources/pdf/<slug>.pdf` and the entry's `archived` flag
flips to `True` in the same change.
