# autophagous

A field manual for achieving autophagy through cyclic prolonged fasting —
published as a single-page Elm document with a companion citations archive
and a printable cycle log.

> **Not medical advice.** The protocol carries contraindications, abort
> signals, an electrolyte warning, and a refeeding-syndrome section for a
> reason. The medical disclaimer ships in the footer of every content page
> and is a hard constraint of this repo, not decoration.

## What's here

Three routes, all worn as the same house document (masthead → numbered
sections → contents rail → disclaimer footer):

| Route | Module | Contents |
|---|---|---|
| `/` | `src/Page/Protocol.elm` | The protocol broadsheet, Rev. 3 — 12 numbered sections: epistemic limits, the two switches (mTORC1/AMPK), safety, GLP-1, the cycle, priming, the fast, the five stages by the clock (0–96 h), the refeed, the rebuild, the cycle log, references |
| `/resources` | `src/Page/Resources.elm` | The citations archive — 19 reserved entries, each with a slot for a locally-archived PDF so the sources outlive link rot |
| `/legal` | `src/Page/Legal.elm` | Terms and disclaimers — the long form of the footer warning: no medical advice, absolute exclusions, emergencies, assumption of risk, no warranty, liability, privacy, reuse |

Plus one print artifact: `typst/cycle-log.typ` → `/downloads/cycle-log.pdf`,
linked from §11 of the protocol.

Both themes ship. Light and dark follow the system preference, and a
three-state control (System / Light / Dark) in the site nav overrides it,
persisting to `localStorage`.

## Quick start

```sh
mise install     # node 26, elm 0.19.1, typst — pinned in mise.toml
npm install
npm run dev
```

| Command | Does |
|---|---|
| `npm run dev` | Vite dev server |
| `npm run build` | Production build to `dist/` |
| `npm run preview` | Serve the built output |
| `npm test` | elm-test (`tests/RouteTests.elm`) |
| `npm run print` | Compile `typst/cycle-log.typ` → `public/downloads/cycle-log.pdf` — **commit the PDF**, the site links to it |

## Layout

```
src/
  boot.js            styles, then Elm; applies the stored theme pre-boot
  Main.elm           the TEA shell — all state, URL wiring, #anchor scrolling, theme
  Route.elm          pure routing (no Cmd, no ports), unit-tested
  Doc.elm            the document format: masthead, rail, § numbering, clause marks, footer
  Page/*.elm         pure views, one per route
  theme.css          tokens only
  protocol.css       components
public/
  _redirects         client routes — scoped, one line per route, no wildcard
  downloads/         compiled print artifacts (committed)
  resources/pdf/     the citation archive, <slug>.pdf
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
- **Self-hosted assets only.** No webfonts, no CDNs.

## The citations archive

`src/Page/Resources.elm` is the single source of truth for citation metadata
and archive status. All 19 slugs are reserved; **none are archived yet** —
every entry currently renders as "not yet archived."

To flip one, in a single commit: drop the PDF at
`public/resources/pdf/<slug>.pdf` and set `archived = True`. Acquisition
order, licensing rules (only redistribute what the license permits — never
archive pirated copies), and the slug convention are in
`docs/RESOURCES-ARCHIVE.md`.

## Docs

| Doc | Owns |
|---|---|
| `docs/autophagy-protocol.html` | The source content (Rev. 3) — `src/Page/Protocol.elm` is its faithful translation |
| `docs/DESIGN-REQUIREMENTS.md` | Look, feel, voice, type, color, hard constraints |
| `docs/DESIGN-PRINCIPLES.md` | Layout structure, Elm structure, the print strategy |
| `docs/RESOURCES-ARCHIVE.md` | The citation archive: slugs, acquisition, licensing |
| `docs/20260816-theme-plan.md` | The light/dark theme plan — closed, except the optional volt glow |
| `AGENTS.md` (`CLAUDE.md`) | The condensed brief for coding agents |

Design decisions are amended in place, dated, in the doc that owns them.

## Notes for contributors

- Structure follows the sibling project `cryovault` (`../cryovault/`) — the
  palette is inherited from it, the design language is this project's own
  and drifts freely.
- `vite.config.js` carries two deliberate workarounds: an HMR-accept rewrite
  for `vite-plugin-elm` under Vite 8, and a pinned `cssTarget` so minified
  range media queries stay parseable on pre-16.4 iOS WebKit. Both are
  commented at the source.
- `package.json` forces `cross-spawn@^6.0.6` through `overrides` to clear a
  ReDoS advisory that `vite-plugin-elm`'s dependency chain hard-pins with no
  upstream release to move to.
