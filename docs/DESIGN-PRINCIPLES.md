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

*(Amended 2026-08-18 — the planner's three modules. Owner: the cycle
planner needed shared data, which the site had not had before.)*

- `src/Cycle.elm` — **the cycle as data**: the stage boundaries and
  the schedule, as offsets in minutes from hour 0 and plain text. No
  `Posix`, no `Zone`, no `Html`. The boundaries had been written three
  times over (stage cards, ruler percentages, planner); they live here
  once and `Page.Protocol` and `Page.Plan` both read them. Same
  argument as the sticky-chrome offsets above: a number duplicated
  across modules is a number that will drift.
- `src/Civil.elm` — wall clock ↔ `Posix`. `elm/time` only goes one
  way, and a `datetime-local` input is a local wall clock with no
  offset attached. Offsets are added in `Posix` (hour 48 is 48 *real*
  hours, which across a DST change is not the same clock time) and
  every rendering goes back through the `Zone`.
- `src/Ics.elm` — the calendar export, a string built in Elm and
  handed over as a `data:` URL. No port, no dependency, no server.
- `src/Page/Plan.elm` — the view, pure like every other page: it takes
  a `Context` and renders it.

*(Amended 2026-08-18 — the live clock. Owner: the planner should tell
a reader who is *inside* a fast where they are, not only where they
will be.)*

- `src/Clock.elm` — where the reader is, from a target and a number of
  minutes. Pure, so every boundary it draws (priming opens, the switch
  flips, the fast ends) is a test case rather than something you have
  to fast for three days to see. It adds **no content**: the current
  and next lines are looked up in `Cycle.plan`, so the clock cannot
  disagree with the tables below it.
- `src/Ruler.elm` — the 0–96 h clock, extracted from `Page.Protocol`
  when the second reader appeared. The protocol draws it plain; the
  planner draws it with a needle at the hour the reader has reached.
- `src/Safety.elm` — safety content more than one surface renders. See
  §3b: this is how the clock shows the abort signals **in full without
  paraphrasing them** — they are the same values, not a restatement.
- The shell's `now` is `Maybe Posix`, `Nothing` until `Time.now`
  lands. One frame is long enough to render a reading counted from the
  epoch ("−20682 d"), and §3a's rule is that nothing false is ever on
  screen. The clock waits instead.
- One subscription, `Time.every 60000`, only while the planner is the
  route. The tick matches the coarsest unit displayed; see
  DESIGN-REQUIREMENTS §1 (amended the same day) for why a changing
  value is not motion.

## §3a. The planner's state

*(Added 2026-08-18.)*

- **The URL is where the plan lives.** `Nav.replaceUrl` mirrors the
  form into `?start=&target=` on every change, so the address bar is a
  shareable plan and nothing is stored — no `localStorage`, no port,
  no persistence question. `replaceUrl`, never `pushUrl`: typing a
  date must not fill the back button with keystrokes.
- **`UrlChanged` therefore asks whether the *route* changed**, not
  whether the URL did. A replaced query on the page you are already
  reading is the shell hearing its own echo: it must not scroll to the
  top and must not re-read the form out from under the reader. Only a
  real arrival applies the query — and an arrival keeps whatever the
  URL does not mention, so a nav click cannot wipe a filled-in form.
- **The start instant is derived, never stored.** The model holds the
  raw field string; `Page.Plan` receives `Maybe Posix`. A half-typed
  date is `Nothing`, which the page states plainly and falls back to
  relative offsets for — not a stale instant left on screen.
- The zone arrives one frame late (`Time.here`). Until it does the
  planner renders in elapsed hours, so nothing false is ever shown.

## §3b. Derived surfaces

*(Added 2026-08-18.)*

The planner is the first thing here that is *about* the protocol
rather than part of it. The rule that makes that safe:

- A derived surface compresses only what has a time attached, links
  back to the section it compressed (`Cycle.Phase.source`), and says
  in its own first section that it is not the protocol.
- It never paraphrases safety content. It links to it — see
  DESIGN-REQUIREMENTS §5, amended the same day for exactly this.
- Whatever leaves the browser carries the link back too: every event
  in the exported `.ics` has the protocol section it came from in its
  description.

*(Amended 2026-08-18 — the one exception, and its shape.)*

- **The live clock may show safety content, because it cannot link
  it.** A reader at hour 41 with a spreading numbness will not follow
  a link. So the abort signals appear on the clock in full, at body
  legibility, in every state the section can be in — which
  `PlanViewTests` asserts, state by state.
- The exception is *rendering the same values twice*, never restating
  them: `Safety.elm` holds them once and both surfaces call it. A
  derived surface that finds itself needing to reword a warning has
  found the boundary, not a special case.

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
