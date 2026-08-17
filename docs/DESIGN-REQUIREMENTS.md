# AUTOPHAGOUS — Design Requirements

Look, feel, voice, type, color, hard constraints. This document and
DESIGN-PRINCIPLES.md are the authority: the aesthetic here stands on
its own and answers to nothing outside these docs.

## 1. The design language: CLINICAL BROADSHEET

The site reads as an issued technical document: frost-paper surface,
true-ink typography, structural rules, tabular data. Dense, calm,
authoritative — a field manual, not a wellness blog.

*(Amended 2026-08-16: the surface is full-bleed — the page IS the
document. The original "sheet laid on a steel bench" framing read like
a permanent print preview and was retired; the layout is dimensioned
as the handbook geometry in DESIGN-PRINCIPLES §1.)*

*(Amended 2026-08-16, owner: the target register is **Acid Y2K
cyberpunk**. The clinical-broadsheet language stays; the style lands
through lighting and acid placement. Two themes are planned, driven by
the system theme — light (the lit facility, ships today) and dark
(stratum-4/5 lighting where the acids come out as data colors). Plan:
`docs/20260816-theme-plan.md`, pending approval; until it executes,
light is the only shipped theme.)*

- Content is the interface. No cards, no shadows, no rounded corners.
- Rules (borders) do the structural work: 3px for the masthead/footer,
  1.5px for section heads, 0.5px for table rows.
- Motion: none by default. Any future motion must be justified in a
  dated amendment here.

## 2. Color — two lightings, one language

*(Rewritten 2026-08-16, theme plan Phases 1–2: role tokens split from
primitives; the dark theme shipped, driven by the system theme via
`prefers-color-scheme`. Phase 3 shipped the same day: the manual
System / Light / Dark control in the site nav sets `data-theme` on
`<html>` through the `saveTheme` port and persists in localStorage;
"System" clears both and follows the OS live. Contract details:
`docs/20260816-theme-plan.md`.)*

Tokens live in `src/theme.css`. Components consume **role tokens**
only; raw hex in component styles is a bug, and so is consuming a
primitive where a role exists. Sanctioned exception: the
theme-invariant **volt-block motif** (`.tag-volt`, the 72 h target,
the legend's mark swatch) uses `--acid-volt` + `--ink` directly and
renders identically in both themes.

Primitives (never swapped): `--ink #111214`, `--frost #edf1f2`,
`--ground #a6afb2` (reserved), `--acid-volt #c8ff00`,
`--acid-cyan #4de8ff`, `--acid-orange #ff7a1a`,
`--acid-mag-deep #d4006f` (reserved).

| Role token | Used for | Light | Dark |
|---|---|---|---|
| `--surface` | page ground, ruler label chips | `#edf1f2` | `#0b0e11` |
| `--tx` | body text | `#111214` | `#edf1f2` |
| `--tx-dim` | secondary text, intents | `#4d545b` | `#8b949b` |
| `--rule` | structural rules, borders, hatch lines | `#111214` | `#edf1f2` |
| `--hairline` | rail row separators | `#b7bab2` | `#2a2f36` |
| `--tint` | hero table rows | `#dddddb` | `#1c2229` |
| `--panel` | note panels | `#e6ebea` | `#12171c` |
| `--stencil-bg` / `--stencil-tx` | site nav, slab titles, mobile strip | `#111214` / `#edf1f2` | `#edf1f2` / `#0b0d0f` |
| `--stencil-mark` | accents ON the stencil field | `--acid-volt` | `#4a7000` |
| `--mark` | `§N.M` clause marks, rail numbers | `#4d545b` | `--acid-volt` |
| `--data-accent` | section chips, phase/stage numerals, `[NN]` ids | `#111214` | `--acid-volt` |
| `--wash` | optional-zone fill | `#d9f7fe` | `#10333c` |
| `--volt-tx` | volt-family text (open/free access tag) | `#4a7000` | `--acid-volt` |
| `--warn-tx` | warning text (paywalled tag) | `#9a3412` | `--acid-orange` |

All pairings audited ≥ 5.1:1 (AA) in both themes, 2026-08-16.

**Acid discipline (theme-dependent):** on light ground, acid never
carries small text — data is ink; acid is blocks, bars, and marks. On dark ground the acids resume as data colors —
marks, numerals, warnings — but never body prose. The stencil is the
inverted field, so its accent swaps to whichever volt holds AA there.
The dazzle lives in decoration and marks, never in reading text.

## 3. Type

*(Amended 2026-08-17 — the webfont revisit this section asked for.
Two self-hosted faces adopted; the body voice stays a system stack.
Faces are declared in `src/fonts.css`, files in `public/fonts/`.)*

Three voices:

- **Body (reading):** Georgia / Times New Roman serif, 16px root, 1.5
  line-height. **System stack, deliberately.** No face in the adopted
  set can carry body text: they are all single-weight and upright, so
  every `<b>` and `<em>` in the protocol would be a browser-synthesised
  fake — including the safety bold — and Instrument Serif additionally
  lacks `µ` and `¼`, which the electrolyte dosing rows use. Georgia has
  a true bold, a true italic, and the full glyph set. Keeping it is a
  §5 legibility decision, not inertia.
- **Display (`.u`):** **Archivo Expanded 700**, uppercase, tracked —
  headers, labels, system voice.
- **Data (`.mono`):** **JetBrains Mono 400/700**, tabular-nums — every
  number: hours, doses, targets. Numbers never wobble.

**Display is now wide, not condensed.** This is the one real break with
the old look, and it cascades:

- `.u` tracking drops 0.14em → 0.10em; a wide face needs less air, and
  0.14em on it reads gappy rather than authoritative. The two 0.22em
  outliers (brand, rail heading) drop to 0.16em for the same reason.
- **Never set `font-stretch`.** Only the wide cut ships; asking for
  condensed makes a browser synthesise it.
- **The display face has one weight, 700.** `font-weight: 800` used to
  appear on `h1`, `h2` and the stage numeral; all three now say 700,
  because 800 against a single-cut face synthesises a heavier one on
  top of an already-bold design and smears it.
- Sizes were retuned against **measured advance widths**, not guessed:
  `h2` 1.3rem → 1.15rem, `.sub-head` 1rem → 0.9rem, `.sec-intent`
  0.54rem → 0.5rem, `.nm` 0.58rem → 0.52rem (its narrowest ruler cell
  was filling to within half a pixel). `h1` holds at 2.9rem — the
  longest line measures 401px against a 656px column at the narrowest
  desktop.
- Section heads fit on one line from ~1150px up. Between 960 and
  1150px the intent label wraps to its own right-aligned line, which is
  what `.sec-head`'s `flex-wrap` is for. Accepted, not overlooked.

Both families are SIL OFL 1.1; the licence text ships beside them in
`public/fonts/`, as the OFL requires. Latin and latin-ext subsets only
— the site is `lang="en"`, and `unicode-range` means latin-ext costs
nothing unless a document needs it.

Not adopted from the set: **Instrument Serif** (reasons above) and
**Inter** (single weight 500, and the body voice is serif).

Measure: `--measure: 44rem`.

## 4. Voice

Direct, mechanistic, honest about evidence limits. The source document
(docs/autophagy-protocol.html) is the register: no hype, no wellness
euphemism, uncertainty stated plainly ("one honest gap"). Safety
content is never softened for tone.

## 5. Hard constraints (never waived)

- AA contrast for all functional text.
- Safety-critical content (contraindications, abort signals, the
  potassium warning, refeeding syndrome) is never truncated,
  collapsed behind interaction, or restyled below body legibility.
- The medical disclaimer ships on every content page footer, and links
  to `/legal` for the long form. *(Amended 2026-08-16: `Page.Legal` is
  that long form — no-medical-advice, the absolute exclusions,
  emergencies, assumption of risk, no warranty, liability, third-party
  sources, privacy, reuse. It **supplements** the footer and the
  protocol's own safety sections; it never replaces them, and its
  safety content is bound by this section like any other. The same
  amendment added the disclaimer to the resources footer, which had
  been shipping only an archive note.)*
- No motion without a dated amendment; respect
  `prefers-reduced-motion` if any is ever added.
- Self-hosted assets only — no CDNs, no webfonts, no third-party
  scripts. *(Amended 2026-08-16: this governs the site's own assets.
  Cited sources are the opposite case — they are **linked, never
  rehosted**; see DESIGN-PRINCIPLES §5 and RESOURCES-POLICY.md.)*

## 6. Print

The live site is **not** the print surface. Printable artifacts are
generated from `typst/` sources (see DESIGN-PRINCIPLES.md §print). The
CSS `@media print` rules are an emergency fallback only and carry no
design obligation.
