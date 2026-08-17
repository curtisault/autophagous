# autophagous

A field manual for achieving autophagy through cyclic prolonged
fasting. Elm + Vite. Structure follows cryovault
(`../cryovault/`) — palette inherited from it, design language its own.

## Doc map

| Doc | Owns |
|-----|------|
| `docs/autophagy-protocol.html` | The source content (Rev. 3) — `src/Page/Protocol.elm` is its faithful translation |
| `docs/DESIGN-REQUIREMENTS.md` | Look, feel, voice, type, color, hard constraints |
| `docs/DESIGN-PRINCIPLES.md` | Layout structure, Elm structure, the print strategy (§print) |
| `docs/RESOURCES-POLICY.md` | The source index: link-first policy, access states, slugs |
| `docs/20260816-theme-plan.md` | Light/dark system-theme plan (Acid Y2K dark) — **closed**, Phases 0–3 shipped 2026-08-16; only the optional volt glow (§5) is still an owner call. DESIGN-REQUIREMENTS §2 is now the palette authority |

## Commands

Toolchain pinned in `mise.toml` (`mise install`): node 26, elm 0.19.1,
typst.

- `npm run dev` — Vite dev server
- `npm run build` — production build to `dist/`
- `npm test` — elm-test
- `npm run print` — compile `typst/cycle-log.typ` → `public/downloads/cycle-log.pdf` (commit the PDF; the site links to it)

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
  browser's own fragment jumps — and the theme preference
  (System/Light/Dark), applied to `<html>` by boot.js via the
  `saveTheme` port because Elm owns only `<body>`.
- CSS: `theme.css` = tokens only; `protocol.css` = components. Raw hex
  outside theme.css is a bug.
- The manifest in `src/Page/Resources.elm` is the single source of
  truth for citation metadata and access state; nothing is rehosted —
  link-first policy in RESOURCES-POLICY.md.
- Safety content (contraindications, abort signals, potassium warning,
  refeeding syndrome, the disclaimer footer) is never cut, collapsed,
  or softened — DESIGN-REQUIREMENTS §5.
- Printables are typst-generated (`typst/`), never forced through the
  site's CSS — DESIGN-PRINCIPLES §print.
