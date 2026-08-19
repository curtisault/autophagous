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
- The rail is sticky beside the sheet on desktop; below 60rem it
  keeps only its search box (§2b); clause marks and intents drop at
  40rem; print hides the rail entirely.
- `#anchor` jumps are performed by the shell (`Main.jumpTo`, via
  `Browser.Dom`) because `Browser.application` swallows the browser's
  default fragment scroll.

*(Amended 2026-08-18 — the rail marks where you are, and clauses have
their own addresses.)*

- **Every clause is addressable.** The `§N.M` mark was `aria-hidden`
  decoration while the prose invited readers to cite "the potassium
  warning is §7.4"; it is a link now. Its id is built from the
  **anchor**, not the number — `sec-fast-4`, not `7-4` — because the
  number is derived from a section's position in a list, and
  reordering the document must not silently repoint a link someone
  has already shared. What the reader copies is the address bar, the
  same as the planner: no clipboard, no port, no permission prompt.
- **The rail marks the section under the reader** (`is-active`, the
  persistent form of the row's own hover). `Doc.Config` takes it;
  the shell owns it.
- It arrives through the `sectionSeen` **port**, because `elm/browser`
  has no scroll subscription — it offers resize, visibility, keys,
  clicks and animation frames, and nothing for scroll. The alternative
  was polling `Browser.Dom.getViewport` every animation frame to
  answer a question that changes a few times a minute.
- boot.js schedules its read on scroll, on resize, and on **DOM
  mutation** — a route change fires no scroll event, and Elm renders
  asynchronously, so the DOM is the only reliable signal that the
  section list changed. The read is rAF-throttled and sends nothing
  when the answer is unchanged. The active style must never affect
  layout (it is a box-shadow) or marking a section could move it.
- The shell **clears `active` on navigation**: `sec-fast` exists on
  both the protocol and the planner, so a stale anchor would mark the
  wrong row.

*(Amended 2026-08-19 — search, in the rail.)*

- **The box is in the contents rail** because searching is navigation
  and the rail is where navigation lives. It also costs no site-nav
  space, which five routes had already used up.
- **Results replace the sheet's sections rather than floating over
  them.** The document is what is being searched, so the document
  becomes the answer — and the results get the full measure instead of
  the rail's 13rem. While searching, the rail shows a count rather
  than repeating the same list at a quarter of the width.
- **The query is not in the URL**, unlike the planner's start date and
  the dosing sheet's settings. A plan is a document you keep; a search
  is a way of looking at one, and it should not survive the back
  button. It is also why the search needs no mirroring, and cannot
  produce the echo bug in §3a.
- **Any real navigation clears it.** Following a result with the query
  still set would render the destination as a result list too, with
  its sections gone and the anchor you followed pointing at nothing.
  A mirroring echo does not clear it, for the same reason it does not
  move the reader.

## §5a. The index

*(Added 2026-08-19.)*

`src/Search.elm` is hand-written and machine-checked, the same
arrangement as the citation backlinks in §3b — and for the same
reason: the prose lives in `Html msg`, which is opaque. Reading the
words back out would mean parsing Elm source at build time or
restructuring the document into a content model, and neither is worth
what it costs.

- Each entry carries **`terms`** (words that are in that section) and
  **`aliases`** (words that are not). `SearchTests` renders every page
  and checks both directions: a term must appear in the section it
  claims, an alias must not.
- The alias check is the one that matters. An alias is what a reader
  types when the document uses a different word — "ozempic" for a §04
  that names semaglutide, "salt" for a §07 that says sodium. The
  moment an alias turns out to be in the prose it is a term, and the
  distinction has stopped meaning anything. Writing the index the
  first time, that check caught fifteen of them.
- **Citations are not in the index.** They are derived from
  `Citations.all`, so an author, a journal or a title is searchable
  with nothing to maintain.
- `Selector.text` matches a substring of a single text node,
  case-sensitively, which is what makes the check possible at all —
  and what limits it to words rather than phrases spanning tags.

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

## 2b. Narrow layouts

*(Added 2026-08-19, adopting the mechanism from `../cryovault/`
DESIGN-PRINCIPLES §4 — the mechanism only; this project keeps its own
look, per the note in §1.)*

- **There is no device detection, and there will not be.** No
  user-agent sniffing, no touch or pointer test, no JS. A narrow window
  on a desktop is a narrow layout; that is the whole definition.
- **Breakpoints are authored in `rem`, never `px`.** A reader who has
  raised their default font size has less usable space and must reach
  the narrow layout sooner, and only a rem query delivers that. A wide
  window flipping to the stacked layout at a 32px default font is
  correct behaviour, not a bug. The tiers are 60rem (the contents rail
  keeps only its search box **and** the site nav's routes move into a
  disclosure panel) and 40rem (clause marks and intents go).
- **Breakpoints are for structural changes only.** When one row needs
  to reflow, use `flex-wrap` and a `flex-basis` so it reflows
  continuously; a media query that micro-manages a single row is a
  smell.
- **Nothing may clip, and nothing hides behind a gesture.** The site
  nav briefly took a horizontal scrollbar when five routes plus the
  theme control stopped fitting a phone, which put half the routes
  behind a swipe with no affordance. A wrapped second row replaced it
  and read as a compromise rather than a design.
- **Below 60rem the routes live in a disclosure panel** (`Menu` /
  `Close`), hung off the bottom of the bar. The bar keeps its one row.
- **The nav and the rail collapse at the same width — one narrow tier,
  not two.** They were 45rem and 60rem for a day, which left a band
  where the rail had already gone but the bar still tried to carry
  five routes plus the theme control: at ~790px the brand printed
  straight through PROTOCOL, and DOSING through RESOURCES. Two
  breakpoints for one idea is how you get a band nobody looked at.
- **Chrome is never squashed by text pressure** (cryovault §5): every
  route and theme button is `flex: none; white-space: nowrap`. A flex
  child that shrinks below its own label does not wrap inside a bar of
  fixed height — it prints through its neighbour, which is what the
  overlap above actually was.
- **Below 60rem the contents rail keeps only its search box.** The
  section list had become a horizontal scroller, which put half the
  document's sections behind a sideways swipe with no affordance and
  read as a mistake rather than a strip — and on a phone, scrolling to
  a section is cheap. *(Owner's call, 2026-08-19.)*
- What stays is the search box, and it stays **visible** rather than
  moving into the menu panel: it is the one thing the rail does that
  scrolling cannot replace — how you reach §09 of twelve without
  knowing where §09 is — and burying it behind a tap would make the
  cheapest way through the document the most hidden.

### Why the panel is positioned absolutely

- **`--nav-h` never changes.** The sticky contents rail hangs off that
  token, and a bar that grew when the menu opened would either shift
  the whole page or leave the rail overlapping. An absolutely
  positioned panel takes the bar's height out of the question
  entirely, and opening the menu shifts no layout at all.
- It is a child of the sticky `nav`, so it travels with it and paints
  above the search strip without needing a `z-index` of its own.
- It is `display: none` when closed, so nothing inside it is
  focusable while the button says it is shut.

### What the panel is not

- **It does not move.** No slide, no fade, no overlay dimming: the
  panel is either there or it is not (DESIGN-REQUIREMENTS §1). This is
  the same reading as the live clock — a thing that changes state is
  not a thing in motion.
- **The mark does not morph.** Three rules, the vocabulary the rest of
  the document is drawn in, unchanged between states; the word beside
  it carries the state. An icon that becomes a cross needs either a
  transform-over-time to read, or it reads as a different icon.
- **It is not a modal.** No scrim, no focus trap, no scroll lock —
  those are all things that would need motion or JS to feel right, and
  a navigation list needs neither.
- Rows are 2.6rem of target, and the active route is marked **down its
  left edge** rather than underneath: an underline in a stacked list
  reads as the row separator.
- Any real navigation closes it, the same rule that clears the search
  query (§3a) — tapping a route is the last thing a reader wants to do
  inside a panel that then stays open.

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
- `src/Dose.elm` — §07's daily requirements as arithmetic: milligrams
  of an element into grams of the salt that carries it, and a day into
  the divided doses the protocol requires. **It invents no doses.**
  The teaspoon masses (6.0 g fine salt, 5.7 g potassium chloride) are
  chosen so the conversion reproduces §07's own "1¼–2 tsp" and
  "⅓–1 tsp" — `DoseTests` runs the protocol's milligram targets
  through it and checks they come back as the protocol's teaspoons, so
  the sheet cannot contradict the section it converts.
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

*(Amended 2026-08-18 — `src/Viewport.elm`, after the guard was got
wrong twice.)*

- **Whether a URL change moves the reader is now one pure function**,
  `Viewport.actionFor`, with the whole table under test. It was two
  ad-hoc conditions inline, and the second one was wrong: `arrived`
  guarded the scroll-to-top but nothing guarded the **anchor jump**,
  so once a URL carried a fragment, every mirrored control click
  re-ran that jump. On the dosing sheet the fragment was usually
  `#sec-dose-set` — §01, the top of the page — so changing doses per
  day threw the reader to the top every time.
- The flag is `Model.mirroring`: set wherever this shell writes the
  URL itself, read by the next `UrlChanged`, cleared after. An
  arrival on a mirroring route sets it too, because that arrival
  writes the URL back in the same batch and the echo is still coming.
- The rule in one line: **an echo of our own write moves nobody.** If
  a control needs the address bar updated, that is a fact about the
  address bar, not about where the reader is standing.
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

*(Amended 2026-08-18 — the dosing sheet, and adding constraints.)*

- The dosing sheet (`/dosing`) is the third derived surface and takes
  the same shape: it converts §07 and links back to it, and it renders
  `Safety.potassiumDose` and `Safety.saltedWater` — the protocol's own
  values, now shared rather than duplicated.
- **A derived surface may tighten, never loosen.** The sheet refuses
  to divide a day into fewer than three doses; §07 says "divided into
  small doses across the day" and gives no number. That floor is the
  sheet's judgement and the page says so in as many words
  (DESIGN-REQUIREMENTS §5). Adding your own number silently, or
  attributing it to the protocol, is the failure this rule names.
- **It shows its working.** §04 of that page lists every constant and
  where it came from, including which ones were chosen to agree with
  §07 rather than looked up. A converter a reader cannot check is a
  converter they have to trust.

*(Amended 2026-08-18 — excluded options are costed, not omitted.)*

- Leaving a popular product off the page does not stop anyone using
  it; it only means they never see the arithmetic. So the sheet has a
  section for the things people reach for instead — Liquid I.V., a
  sports drink, coconut water, bone broth — with the §07 clause each
  one breaks.
- **An excluded thing is not a setting.** It was briefly a fourth
  option in the potassium control, which framed it as a choice a
  reader might legitimately make; it is a *section* now, titled what
  it is. The controls offer only what the protocol permits.
- **Cost it out where you can.** The stick mix is computed from
  constants in `Dose` and tested: §07's daily potassium would take
  2.7–8.1 sticks, which is 30–89 g of sugar. That is a better answer
  than an assertion. Where the numbers are label values rather than
  computed ones, the page says so and leads with the mechanism, which
  is the part that still holds when the product is reformulated.
- **Name the close call.** A zero-sugar sweetened stick has the right
  profile and no calories; §07 excludes it for the cephalic-phase
  insulin response, which is a less certain mechanism than the calorie
  rule. The page says exactly that rather than flattening it into the
  same verdict as bone broth.

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

Policy doc: RESOURCES-POLICY.md. The manifest in `src/Citations.elm`
is the single source of truth for citation metadata and access state.

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

*(Amended 2026-08-18 — the citation apparatus. Owner: the markers were
decorative and the reference list was a second copy.)*

- **The manifest moved to `src/Citations.elm`.** The protocol's §12
  reference list had been nineteen citations written out a second
  time, in a second format, and the two had already drifted on which
  papers carry corrections. Both pages render `Citations.line` now, so
  they cannot disagree again — which is why the entries are held in
  parts (`authors` / `journal` / `locus`): the journal is italicised
  in both renderings and a flat string cannot carry that.
- **`[13]` is a link** to `/resources#<slug>`. A run like `[9][10][11]`
  is three links, not one: the sources behind a claim are rarely
  interchangeable.
- **The index points back.** Each entry names the sections that cite
  it (`Citations.sites`), so a reader can see what a source is holding
  up rather than only that it was read.
- That table is hand-maintained — it is the same class of thing as the
  protocol's own "see §09" — but it is **checked in both directions**:
  `CitationTests` renders the protocol and asserts each section links
  exactly the sources the table claims, and no others. A marker added
  without a table entry fails; a table entry with no marker fails.
