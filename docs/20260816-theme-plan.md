# Theme plan — system-driven light/dark

**Status: Phases 0–3 EXECUTED 2026-08-16 (owner-approved same day).
Phase 4's main item — the DESIGN-REQUIREMENTS §2 dual-palette
rewrite — landed with Phase 2. This plan is CLOSED except the
optional volt glow (§5), still an owner call.**

Phase 3 as built: three-state control (System / Light / Dark) in the
site nav, worn like the nav links on the stencil. Elm owns the state;
`boot.js` applies `data-theme` on `<html>` via the `saveTheme` port
and persists to localStorage (`autophagous-theme`), applying the
stored value before Elm boots so the page never flashes the wrong
theme. "System" is represented by absence — no attribute, no key —
which hands control to `prefers-color-scheme`, so System tracks live
OS changes by construction. Verified in-browser: toggle loop,
aria-pressed, reload persistence, and reset-to-system all pass.

Implementation notes (deviations from the tables below, all recorded
in DESIGN-REQUIREMENTS §2, which is now the authority):

- `--mark` light is `#4d545b`, not `#111214` — the marks were already
  dim, and Phase 1's zero-visual-diff rule outranks the draft table.
- Two roles were added during the split: `--stencil-mark` (accents on
  the stencil field — volt on ink in light, `#4a7000` on frost in
  dark, since the inverted stencil is a light field) and
  `--data-accent` (section chips, phase/stage numerals, citation ids:
  ink in the light, volt in the dark).
- `.sec-num` borders with `currentColor`, so the chip's frame follows
  its number into volt.
- AA audit passed, worst pairing 5.12:1 (small bold caps).
- The optional volt glow (§5) was NOT added — still an owner call.

Owner direction (2026-08-16): support the system theme with a light
and a dark theme; keep light for now; the target register is **Acid
Y2K cyberpunk** — the dark theme is where the acids come out.

---

## 1. The two looks

One design language ("clinical broadsheet — an issued technical
document"), two lightings, following cryovault's field arc:

- **Light — the lit facility.** What ships today: frost surface, ink
  everywhere, acid only as applied blocks and marks. Unchanged.
- **Dark — the lights go out.** Cryovault stratum-4/5 physics: near-void
  surface, text flips to frost, the stencil inverts (frost blocks,
  near-black text), and **the acids resume as data colors** — volt
  section numbers, volt clause marks, volt rail numbers, orange
  warnings — the OPERATOR'S HANDBOOK look. The dazzle stays in
  decoration and marks, never in body prose.

Acid discipline is theme-dependent, exactly as in cryovault: on light
ground acid never carries small text; on dark ground it may carry
*marks and data*, still never body copy.

## 2. Mechanism (the three-state contract)

CSS-first, so the system theme works with zero JS:

1. Bare `:root` carries the complete **light** role-token set (the
   default — never only inside a media query).
2. `@media (prefers-color-scheme: dark)` redefines role tokens,
   guarded as `:root:not([data-theme="light"])`.
3. `:root[data-theme="dark"]` repeats the dark set verbatim, so a
   future manual toggle wins in both directions.

Phase 2 ships with nothing setting `data-theme` — the OS preference
governs. Phase 3 adds the manual toggle (System / Light / Dark) on
top without touching the palette. `index.html` meta `color-scheme`
flips from `light` to `light dark` in Phase 2 so form controls and
scrollbars follow.

**Print is themeless.** The `@media print` block already forces
ink-on-white with raw hex — that is deliberate and stays. Typst
artifacts are a separate surface and never theme.

## 3. Token refactor (the prerequisite)

Today `--ink` and `--paper` each play several roles (text vs stencil
fill vs hatch lines; surface vs stencil text vs label chip). Dark
inverts those roles *differently*, so Phase 1 splits **primitives**
(never swapped) from **role tokens** (swapped per theme) and re-points
`protocol.css` usage by usage — audited counts: 22 `--rule`,
12 `--ink`, 6 `--paper`, plus singles.

Primitives (constant): `--ink #111214`, `--frost #edf1f2`,
`--acid-volt #c8ff00`, `--acid-cyan #4de8ff`, `--acid-orange #ff7a1a`,
`--acid-mag-deep #d4006f`, the font stacks.

| Role token | Used for | Light | Dark |
|---|---|---|---|
| `--surface` | page ground, `.rlbl b` chip | `#edf1f2` | `#0b0e11` |
| `--tx` | body text | `#111214` | `#edf1f2` |
| `--tx-dim` | secondary text, intents | `#4d545b` | `#8b949b` |
| `--rule` | structural rules, borders, hatch lines, `.box` | `#111214` | `#edf1f2` |
| `--hairline` | toc row separators | `#b7bab2` | `#2a2f36` |
| `--tint` | hero table rows | `#dddddb` | `#1c2229` |
| `--panel` | note panels (now `--tint-2`) | `#e6ebea` | `#12171c` |
| `--stencil-bg` / `--stencil-tx` | slab titles, site nav, mobile strip | `#111214` / `#edf1f2` | `#edf1f2` / `#0b0d0f` |
| `--mark` | `§N.M` marks, `sec-num`, rail numbers | `#111214` | `var(--acid-volt)` |
| `--wash` | optional-zone fill (now `--cyan-wash`) | `#d9f7fe` | `#10333c` |
| `--volt-tx` | volt-family text (archived tag) | `#4a7000` | `var(--acid-volt)` |
| `--warn-tx` | warning text (not-archived tag) | `#9a3412` | `var(--acid-orange)` |

`.tag-volt` (volt block, ink text) is theme-invariant — volt holds ink
at ~6:1 on both grounds. The volt fast-phase underscore and the 72 h
target marker likewise carry across unchanged.

## 4. Phases

- **Phase 0 — this plan.** Exit: owner approval.
- **Phase 1 — role-token split.** Rename/re-point only; **zero visual
  diff** (light values identical). Exit: build green, side-by-side
  eyeball identical, no raw hex outside the print block, no
  primitive consumed directly where a role exists.
- **Phase 2 — the dark palette.** Add guarded dark blocks per §2,
  `color-scheme: light dark`. Exit: OS toggle flips the site live;
  every text/ground pairing in §3 passes AA (spot-check `--tx-dim` on
  `--tint`/`--panel` in both themes — the known tight pairs); ruler,
  hatch, log boxes, and slabs legible in dark; safety content
  (DESIGN-REQ §5) audited in both themes.
- **Phase 3 — manual toggle (optional, later).** Three-state control
  in the site nav; persisted in localStorage; a port sets `data-theme`
  on `<html>` (Elm owns only `<body>`, so this is boot.js's job, same
  shape as cryovault's calm/save ports). Exit: pref survives reload;
  "System" tracks live OS changes.
- **Phase 4 — docs.** Rewrite DESIGN-REQUIREMENTS §2 as the dual
  palette table; record the inverted acid discipline; dated amendment
  closing this plan.

## 5. Acid Y2K notes (for Phase 2 taste calls)

- Volt is THE acid; cyan stays the "optional/extension" accent; keep
  the dark theme two-acid unless a real role appears for magenta.
- A restrained static glow on volt marks (`text-shadow`, no animation)
  is in-register for Y2K and legal under DESIGN-REQ §5 (which bans
  motion, not glow) — propose at Phase 2, owner call.
- No new hues: everything comes from the existing primitives. The
  cyberpunk reads through lighting and acid placement, not palette
  sprawl.
