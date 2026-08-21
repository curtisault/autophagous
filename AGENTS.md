# autophagous

A field manual for achieving autophagy through cyclic prolonged
fasting. Elm + Vite. The design language is set out in full in
`docs/DESIGN-REQUIREMENTS.md` and `docs/DESIGN-PRINCIPLES.md` — those
two docs are the authority on how this looks and why.

## Doc map

| Doc | Owns |
|-----|------|
| `docs/autophagy-protocol.html` | The source content (Rev. 3) — `src/Page/Protocol.elm` is its faithful translation |
| `docs/DESIGN-REQUIREMENTS.md` | Look, feel, voice, type, color, hard constraints |
| `docs/DESIGN-PRINCIPLES.md` | Layout structure, Elm structure, the print strategy (§print) |
| `docs/RESOURCES-POLICY.md` | The source index: link-first policy, access states, slugs |
| `docs/DEPLOY.md` | CI (PR test workflow + the deploy pipeline), the 404/SPA-fallback contract, cache policy, one-time setup |
| `docs/20260821-plan-page.md` | The eight planner changes (A–H) — **open**, drafted 2026-08-21; build order A→B→C→D→E→F→G, H after E |
| `docs/20260816-theme-plan.md` | Light/dark system-theme plan (Acid Y2K dark) — **closed**, Phases 0–3 shipped 2026-08-16; only the optional volt glow (§5) is still an owner call. DESIGN-REQUIREMENTS §2 is now the palette authority |

## Commands

Toolchain pinned in `mise.toml` (`mise install`): deno 2, elm 0.19.1,
elm-test-rs, typst. `mise.toml` is the **single source of truth** for
every tool version — CI installs from the same file via
`jdx/mise-action`.

**There is no Node and no npm.** Deno is the only JavaScript runtime:
it runs Vite, wrangler, and the compiled Elm test bundle. Dependencies
and tasks live in `deno.json`. The surviving `package.json` holds one
`overrides` block and must hold nothing else — it is the only way to
force a transitive npm version, and deleting it silently reinstates a
`cross-spawn` ReDoS advisory. If
something will not run under Deno, fix that — do not reintroduce node.
`elm-test-rs` comes from a **fork** because upstream's Deno support
still calls three APIs Deno 2 removed; `mise.toml` documents it and
says when to drop back to upstream.

Neither the Elm compiler nor the test runner is a package; both
resolve off PATH, so `mise install` is required before
`deno task build` or `deno task test` will work.

- `deno task dev` — Vite dev server
- `deno task build` — production build to `dist/`
- `deno task test` — elm-test-rs under Deno
- `deno task print` — compile `typst/cycle-log.typ` → `public/downloads/cycle-log.pdf` (commit the PDF; the site links to it)

## Architecture rules

- `src/Route.elm` — pure routing; adding a route means adding a line
  to `public/_redirects` (scoped, no wildcard — that friction is
  deliberate).
- `src/Doc.elm` — the document format (DESIGN-PRINCIPLES §2a): shared
  chrome (masthead, contents rail, § numbering, clause marks, footer).
  It numbers and frames; pages render. Never teach it page content.
- `src/Page/*.elm` — pure views, one per route; each hands `Doc.view`
  one ordered section list (the rail and numbering derive from it).
- `src/Main.elm` — the TEA shell; all state lives here, including
  `#anchor` scrolling (`jumpTo`) — Browser.application swallows the
  browser's own fragment jumps — the theme preference
  (System/Light/Dark), applied to `<html>` by boot.js via the
  `saveTheme` port because Elm owns only `<body>`, and the planner's
  form. `UrlChanged` branches on whether the **route** changed, not
  the URL: the planner mirrors its form into `?start=&target=` with
  `replaceUrl`, and that echo must not scroll or reset the form
  (DESIGN-PRINCIPLES §3a).
- `src/Search.elm` — the site index. Hand-written, machine-checked:
  `terms` must appear in the section they claim, `aliases` must not
  (DESIGN-PRINCIPLES §5a). Citations are derived from `Citations.all`,
  not written. The query lives in the model, never the URL, and any
  real navigation clears it.
- `src/Doc.elm` takes a `Chrome` (active section + query + handler);
  a non-empty query replaces the sheet's sections with results.
- `src/Viewport.elm` — whether a URL change moves the reader, as one
  pure tested function. Do not inline this decision again: it has been
  got wrong twice, most recently by guarding the scroll-to-top and
  forgetting the anchor jump. An echo of the shell's own write moves
  nobody.
- `src/Cycle.elm` — the cycle as data: stage boundaries and the
  schedule, offsets in minutes from hour 0. No `Posix`, no `Html`.
  `Page.Protocol` (stage cards, ruler) and `Page.Plan` both read it —
  the boundaries are one list, not three copies (DESIGN-PRINCIPLES §3).
- `src/Civil.elm` — wall clock ↔ `Posix`, the direction `elm/time`
  does not ship. Offsets are added in `Posix` because elapsed hours
  are elapsed; rendering goes back through the `Zone`.
- `src/Ics.elm` — the calendar export as a string on a `data:` URL.
- `src/Clock.elm` — where the reader is in the cycle, from a target
  and elapsed minutes. Pure; adds no content, only which line of
  `Cycle.plan` you are standing on.
- `src/Ruler.elm` — the 0–96 h clock. Plain on the protocol, with a
  needle on the planner.
- `src/Dose.elm` — §07's requirements as arithmetic (mg of an element
  → g of the salt that carries it → divided doses). Invents no doses;
  the teaspoon masses are chosen to reproduce §07's own tsp figures,
  and `DoseTests` holds them there. A derived surface may tighten a
  constraint (the three-dose floor) but must say the judgement is its
  own — DESIGN-REQUIREMENTS §5.
- `src/Safety.elm` — safety content two surfaces render. Rendering the
  same values is how the clock shows the abort signals in full without
  paraphrasing them (DESIGN-PRINCIPLES §3b).
- One subscription exists: `Time.every 60000`, only on `/plan`. A
  value that changes is not motion — DESIGN-REQUIREMENTS §1, amended
  2026-08-18. There are no transitions or animations anywhere, and
  that is a rule, not an accident.
- Derived surfaces (the planner, anything generated from it) compress
  only what has a time attached, link back to the protocol section
  they compressed, and never paraphrase safety content —
  DESIGN-PRINCIPLES §3b, DESIGN-REQUIREMENTS §5.
- CSS: `theme.css` = tokens only; `fonts.css` = `@font-face` only;
  `protocol.css` = components. **Breakpoints are in `rem`, never `px`,
  and there is no device detection anywhere** — a narrow window is a
  narrow layout (DESIGN-PRINCIPLES §2b). Nothing may clip and nothing
  hides behind a gesture. **60rem is the one narrow tier**: the rail
  drops to its search box and the site nav's routes move into a
  disclosure panel, positioned absolutely so `--nav-h` never changes
  and opening it shifts no layout. Nothing about it moves. Bar items
  are `flex: none` — a shrinking flex child prints through its
  neighbour inside a fixed-height bar. Raw hex outside theme.css is a bug, and
  so is `font-stretch` or `font-weight: 800` on the display voice —
  only one 700 cut ships (DESIGN-REQUIREMENTS §3).
- `src/Citations.elm` is the single source of truth for citation
  metadata and access state; nothing is rehosted — link-first policy
  in RESOURCES-POLICY.md. Both the protocol's §12 list and the source
  index render `Citations.line`, so they cannot drift apart (they had:
  the corrigendum notes disagreed). It also holds `sites`, the
  hand-maintained table of which section cites what — checked in both
  directions by `CitationTests` against the rendered protocol.
- Citation markers are links (`Citations.href`), clause marks are
  links to their own clause (id built from the **anchor**, not the §
  number — reordering must not repoint a shared link), and the
  contents rail marks the active section.
- Two ports exist: `saveTheme` (out) and `sectionSeen` (in). The
  second is a port because `elm/browser` has no scroll subscription;
  boot.js reads the active section on scroll, resize and DOM mutation,
  rAF-throttled. The active style must never affect layout, or marking
  a section could move it.
- Safety content (contraindications, abort signals, potassium warning,
  refeeding syndrome, the disclaimer footer) is never cut, collapsed,
  or softened — DESIGN-REQUIREMENTS §5.
- Printables are typst-generated (`typst/`), never forced through the
  site's CSS — DESIGN-PRINCIPLES §print.
- `public/404.html` must exist and `public/_redirects` must stay
  wildcard-free: together they keep Cloudflare Pages' SPA fallback off.
  Deleting either serves `index.html` as `text/html` for missing hashed
  assets and caches that mistake for a year — docs/DEPLOY.md. CI fails
  the build if you break it.
