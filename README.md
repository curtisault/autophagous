# autophagous

A field manual for achieving autophagy through cyclic prolonged fasting —
published as an Elm document with a cycle planner, a companion source index
and a printable cycle log.

> **Not medical advice.** The protocol carries contraindications, abort
> signals, an electrolyte warning, and a refeeding-syndrome section for a
> reason. The medical disclaimer ships in the footer of every content page
> and is a hard constraint of this repo, not decoration.

## What's here

Five routes, all worn as the same house document (masthead → numbered
sections → contents rail → disclaimer footer):

| Route | Module | Contents |
|---|---|---|
| `/` | `src/Page/Protocol.elm` | The protocol broadsheet, Rev. 3 — 12 numbered sections: epistemic limits, the two switches (mTORC1/AMPK), safety, GLP-1, the cycle, priming, the fast, the five stages by the clock (0–96 h), the refeed, the rebuild, the cycle log, references |
| `/plan` | `src/Page/Plan.elm` | The cycle planner — enter the moment your last meal ends and the protocol's elapsed hours become dates: priming D−3 to D−1, hour 0, every stage crossing, the refeed windows, the rebuild weeks, the earliest next cycle. §02 is a **live clock**: hours elapsed, the stage you are standing in, the countdown to the next line, a needle on the 0–96 h ruler, and the abort signals in full. Exports the schedule as an `.ics` calendar. The plan rides in the URL (`?start=&target=`), so it is shareable and nothing is stored |
| `/dosing` | `src/Page/Dosing.elm` | The electrolyte sheet — §07's milligram targets converted into grams of salt, teaspoons, and the divided doses the protocol requires. Handles the trap that a "lite salt" is half table salt, so it takes twice the spoonfuls and brings sodium that has to come off the salt you were also going to add. A "what not to reach for" section costs out the things people use instead — Liquid I.V., sports drinks, coconut water, bone broth — with the §07 clause each one breaks |
| `/resources` | `src/Page/Resources.elm` | The source index — 19 citations, each routed to the best copy a reader can legally reach; DOI + access state, nothing rehosted. Every entry names the protocol sections that cite it |
| `/legal` | `src/Page/Legal.elm` | Terms and disclaimers — the long form of the footer warning: no medical advice, absolute exclusions, emergencies, assumption of risk, no warranty, liability, privacy, reuse |

Plus one print artifact: `typst/cycle-log.typ` → `/downloads/cycle-log.pdf`,
linked from §11 of the protocol.

Both themes ship. Light and dark follow the system preference, and a
three-state control (System / Light / Dark) in the site nav overrides it,
persisting to `localStorage`.

## Quick start

```sh
mise install     # deno 2, elm 0.19.1, elm-test-rs, typst — pinned in mise.toml
deno install     # dependencies, from deno.json
deno task dev
```

**There is no Node here, and no npm.** Deno is the only JavaScript
runtime — it runs Vite, wrangler, and the compiled Elm test bundle.
Dependencies and tasks live in `deno.json`. A `package.json` survives,
carrying one `overrides` block and nothing else — see *Notes for
contributors*.

`mise install` is not optional. The Elm compiler and the test runner
are not packages of any kind — `deno task build` and `deno task test`
resolve the bare names `elm` and `elm-test-rs` off PATH, and
`mise.toml` is the only place their versions are written down,
including for CI. The first install compiles `elm-test-rs` from source
(~40 s); see the note in `mise.toml` for why it comes from a fork.

| Command | Does |
|---|---|
| `deno task dev` | Vite dev server |
| `deno task build` | Production build to `dist/` |
| `deno task preview` | Serve the built output |
| `deno task test` | elm-test-rs (routing, wall-clock conversion, the schedule, the calendar export) |
| `deno task deploy` | Build and push `dist/` to Cloudflare Pages (skips the test gate — prefer pushing to `main`) |
| `deno task print` | Compile `typst/cycle-log.typ` → `public/downloads/cycle-log.pdf` — **commit the PDF**, the site links to it |

## Layout

```
src/
  boot.js            styles, then Elm; applies the stored theme pre-boot
  Main.elm           the TEA shell — all state, URL wiring, #anchor scrolling, theme
  Route.elm          pure routing + query params (no Cmd, no ports), unit-tested
  Doc.elm            the document format: masthead, rail, § numbering, clause marks, footer
  Citations.elm      the sources, once — manifest, addresses, and who cites what
  Cycle.elm          the cycle as data: stage boundaries + the schedule, in offsets
  Civil.elm          wall clock <-> Posix, the direction elm/time doesn't ship
  Clock.elm          where the reader is in the cycle right now — pure, from elapsed minutes
  Search.elm         the site index — hand-written, checked against the prose both ways
  Dose.elm           §07's requirements as arithmetic — mg of an element to g of salt
  Ruler.elm          the 0-96 h clock; plain on the protocol, needled on the planner
  Safety.elm         safety content two surfaces render — the same values, never a summary
  Ics.elm            the calendar export — a string on a data: URL, no port, no deps
  Page/*.elm         pure views, one per route
  theme.css          tokens only
  fonts.css          @font-face only (hand-maintained)
  protocol.css       components
public/
  404.html           keeps Pages' SPA fallback OFF — see docs/DEPLOY.md
  _headers           cache policy (immutable only where names are stable)
  _redirects         client routes — scoped, one line per route, no wildcard
  downloads/         compiled print artifacts (committed)
  fonts/             self-hosted woff2 + their OFL licence texts
typst/               print sources
docs/                the specs — see below
```

`index.html` has no mount node on purpose: `Browser.application` takes the
whole `<body>`, and `Route.title` owns the document title once Elm boots.

## Architecture rules

These are load-bearing. Breaking one is a bug, not a style difference.

- **`Doc` numbers and frames; pages render.** A page hands `Doc.view` one
  ordered section list; the contents rail and the `§` numbers both derive
  from that list, so they cannot disagree. `Doc` never learns what a stage
  card or a citation entry is. In-prose cross-references (`see §09`) are the
  one hand-maintained thing — reordering sections means grepping for `§`.
- **Adding a route means adding a line to `public/_redirects`.** Scoped
  redirects, no wildcard. The friction is deliberate.
- **The cycle's numbers live in `Cycle.elm`, once.** The stage boundaries
  (0/16/24/48/72/96 h) had been written three times over — the stage cards,
  the ruler's percentages, the planner. Three copies of one number is a
  number that will drift.
- **No transitions, no animations, anywhere.** The live clock re-renders
  once a minute; a value that changes is not motion (DESIGN-REQUIREMENTS
  §1). `prefers-reduced-motion` has nothing to reduce, and if that stops
  being true something was broken.
- **No device detection; breakpoints in `rem`.** A narrow window is a narrow
  layout, and a reader with a raised default font size reaches it sooner —
  which only a rem query delivers. Nothing may clip, and nothing hides
  behind a gesture: below 60rem — one narrow tier for all of the chrome —
  the site nav's routes move into a disclosure panel — absolutely positioned, so the bar's height never changes and the
  sticky rail below it keeps working off a token that cannot go stale. It
  does not slide, fade or dim (DESIGN-PRINCIPLES §2b).
- **Search is in the rail, and results replace the sheet.** The index is
  hand-written but checked against the rendered pages in both directions:
  a `term` must appear in the section it claims, an `alias` must not. The
  query lives in the model, not the URL — a plan is a document you keep, a
  search is a way of looking at one.
- **Citations are one system.** `Citations.elm` holds the sources; the
  protocol's §12 list and the source index both render `Citations.line`.
  The backlink table (`sites`) is hand-maintained but checked against the
  rendered protocol in both directions — a marker without a table entry
  fails, and so does a table entry with no marker.
- **A derived surface may tighten, never loosen.** The dosing sheet won't
  divide a day into fewer than three doses; §07 gives no number. That floor
  is the sheet's judgement and the page says so — adding your own number
  silently, or attributing it to the protocol, is the failure this names.
- **A derived surface is not the protocol.** The planner compresses only
  what has a time attached, links back to the section it compressed, and
  never paraphrases a contraindication — it links to it, at full strength
  (DESIGN-PRINCIPLES §3b). That holds for anything generated from it: every
  event in the exported calendar carries its protocol link too.
- **The planner's plan lives in the URL**, mirrored with `replaceUrl` — no
  storage, no port, and `UrlChanged` branches on the route changing rather
  than the URL changing so that echo doesn't reset the form
  (DESIGN-PRINCIPLES §3a).
- **`theme.css` is tokens; `protocol.css` is components.** Raw hex outside
  `theme.css` is a bug, and so is consuming a primitive where a role token
  exists.
- **Safety content is never cut, collapsed, or softened** —
  contraindications, abort signals, the potassium warning, refeeding
  syndrome, the disclaimer footer (DESIGN-REQUIREMENTS §5).
- **The live site is not the print surface.** Printables are typst-generated
  and never forced through the site's CSS (DESIGN-PRINCIPLES §print). The
  `@media print` rules are an emergency fallback carrying no design
  obligation.
- **Self-hosted assets only.** No CDNs. The two webfonts (Archivo Expanded
  700 for display, JetBrains Mono 400/700 for data) are committed under
  `public/fonts/` with their OFL licences. Body type stays a system serif on
  purpose — see DESIGN-REQUIREMENTS §3. Never set `font-stretch` or
  `font-weight: 800` on the display voice; only one 700 cut ships.

## The source index

`src/Citations.elm` is the single source of truth for citation metadata
and access state. **Link-first: nothing is rehosted.** Every entry carries a
CrossRef-verified DOI (17 of 19 — the Nobel citation and the ASA guidance
aren't journal articles and have none) plus an `Access` state from Unpaywall,
so a reader can see before clicking whether they'll hit free full text or a
paywall. 14 of 19 are free to reach.

The local PDF archive this replaced was retired 2026-08-16 for two reasons:
being free to *read* on PMC is not permission to *rehost* — only 3 of 19 are
under an open licence — and a frozen PDF can't report that its paper was
later corrected, which two of these were. Full reasoning, the access-state
table, and the per-entry procedure for adding one are in
`docs/RESOURCES-POLICY.md`.

Slugs survive as anchors: `/resources#<slug>` is a permanent address for a
single citation — and since 2026-08-18 that is where every `[13]` in the
protocol points. The index points back: each entry names the sections that
cite it, so you can see what a source is holding up rather than only that it
was read. The manifest moved out of the page into `src/Citations.elm` at the
same time, because §12's reference list had been a second hand-written copy
of the same nineteen entries and the two had drifted on which papers carry
corrections.

## Docs

| Doc | Owns |
|---|---|
| `docs/autophagy-protocol.html` | The source content (Rev. 3) — `src/Page/Protocol.elm` is its faithful translation |
| `docs/DESIGN-REQUIREMENTS.md` | Look, feel, voice, type, color, hard constraints |
| `docs/DESIGN-PRINCIPLES.md` | Layout structure, Elm structure, the print strategy |
| `docs/RESOURCES-POLICY.md` | The source index: link-first policy, access states, slugs |
| `docs/DEPLOY.md` | Cloudflare Pages pipeline, the 404 contract, cache policy, one-time setup |
| `docs/20260816-theme-plan.md` | The light/dark theme plan — closed, except the optional volt glow |
| `AGENTS.md` (`CLAUDE.md`) | The condensed brief for coding agents |

Design decisions are amended in place, dated, in the doc that owns them.

## Notes for contributors

- `vite.config.js` carries two deliberate workarounds: an HMR-accept rewrite
  for `vite-plugin-elm` under Vite 8, and a pinned `cssTarget` so minified
  range media queries stay parseable on pre-16.4 iOS WebKit. Both are
  commented at the source.
- `package.json` exists **only** to force `cross-spawn@^6.0.6` through
  `overrides`, clearing a ReDoS advisory that `vite-plugin-elm`'s dependency
  chain hard-pins with no upstream release to move to. `deno.json` has no
  equivalent mechanism, and Deno does read the field — without that file the
  vulnerable 6.0.5 is what gets installed. Do not delete it, and do not put
  dependencies or scripts in it; those live in `deno.json`.
- `elm-test-rs` is pinned to a **fork**. Upstream's Deno support dates from
  2021 and calls three APIs Deno 2 removed, so `--deno` fails outright on
  stock 3.2.0. The fork is that fix and nothing else — see `mise.toml`.
