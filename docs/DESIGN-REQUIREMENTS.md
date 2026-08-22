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

*(Amended 2026-08-18 — the first input surface. Owner: the cycle
planner (`/plan`) takes a start date and a target, which the site had
never had to ask for. It does not introduce a widget language.)*

- **A control is drawn the way the document is drawn.** A field is a
  ruled cell — 1.5px `--rule`, square corners, the data voice inside
  it. A chosen option is *stencilled*: the same ink-block inversion
  the site nav and slab titles already use to say "this is the state
  you are in". No fills that aren't tokens, no borders that aren't
  rules, no rounding, no transitions.
- **Focus is visible and it is ink**, not a browser default halo: a
  3px `--data-accent` outline, offset 1px.
- Still no motion. A control that responds to a click by *being*
  different is in the language; one that animates into it is not.

*(Amended 2026-08-18 — the live clock, and what the motion clause
means. Owner: the planner's §02 shows a reader inside a fast how many
hours they are into it, which is a figure that has to change.)*

- **A value that changes is not motion.** The clock re-renders once a
  minute; the figure does not travel from one reading to the next, and
  nothing fades, slides or eases. The rule this section has always
  meant is intact: **no transitions, no animations, no
  transforms-over-time, anywhere.** Grep for `transition`, `animation`
  or `@keyframes` in `protocol.css` — there should continue to be
  none.
- Therefore `prefers-reduced-motion` has nothing to reduce. If that
  ever stops being true, this clause is the thing that was broken.
- The tick is a minute, matching the coarsest unit displayed. A
  second-by-second clock would re-render the same string 59 times out
  of 60 and would read as a device rather than a document.
- **The volt block motif gains a fourth sanctioned use**: `.clock` in
  its live state carries a `--acid-volt` rule down its left edge. It
  means one thing — you are inside the cycle right now — and like the
  rest of the motif it is theme-invariant. The full sanctioned list is
  `.tag-volt`, the 72 h ruler target, the legend's mark swatch, and
  this.

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
the legend's mark swatch, and — from 2026-08-18 — the live clock's
`.clock.is-live` rule) uses `--acid-volt` + `--ink` directly and
renders identically in both themes.

**Amended 2026-08-21 — the block motif takes two more acids.** The
planner's two countdowns (`.clock-when .clock-next`) are applied
blocks under the same rules as the volt block: acid field, `--ink`
text, theme-invariant.

| Block | Field | vs `--ink` | Means |
|---|---|---|---|
| `.is-next` | `--acid-cyan` | 12.76:1 | what the schedule reaches next |
| `.is-break` | `--acid-orange` | 7.19:1 | the number the reader is waiting for |

Both are firsts: orange had been text-only (`--warn-tx`), and cyan had
appeared only as `--wash`, its pale tint. Ink and never frost — frost
is 2.29:1 on orange and 1.29:1 on cyan, both failing.

**Why cyan and not volt for the pair.** Volt is the higher contrast
against ink (15.85:1) and is THE acid, so it is the obvious second
block and the wrong one: volt sits beside orange on the wheel, and
stacked they read as one family. Cyan is orange's complement, the
widest hue separation this palette holds. When two acid blocks are
adjacent, **separation of hue outranks contrast against the text** —
each field already clears AA on its own.

**Hierarchy is carried by size, not by adding hues.** The break block
is louder than the next block because its figure is set larger, not
because a third colour entered.

**One orange field at rest.** A screen shows a single standing orange
block: the number you are waiting for while you are inside the cycle.
Orange is not a general highlight. The one exception is **transient
state** — the ruler segment's hover and focus chip
(`.rlbl:hover b`) fills orange while the pointer or focus is on it and
is gone the moment it leaves, so it never competes with the standing
block for the same glance.

**Orange fills, it does not draw lines.** At `#ff7a1a` an orange
hairline is 2.29:1 on the light chip field and 1.92:1 on the spent
band — under the 3:1 floor for non-text contrast (WCAG 1.4.11), which
is what `theme.css` means by "dark-field text only". Ink on an orange
field is 7.19:1 in both themes. Where orange has to mark something on
light ground it takes the block motif — acid fill, `--ink` edge — or
it uses `--warn-tx`, the role token that holds AA on whichever field
is current.

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
  *(Amended 2026-08-18: this now also governs **derived surfaces** —
  anything that compresses the protocol, like the planner's schedule
  or a calendar file generated from it. A derived surface may not
  paraphrase a contraindication: it links to the section, in full
  strength, and says outright that it is not the protocol. The
  planner's §01 slab is the pattern. A summarised warning is a way of
  missing one.)*
  *(Amended 2026-08-18, again: a derived surface may **add a
  constraint** the protocol does not state — the dosing sheet will not
  divide a day into fewer than three doses, and §07 gives no number —
  but only where it says on the page that the constraint is its own
  judgement. Tightening in the safe direction is allowed; attributing
  your own number to the source is not. The corollary: a derived
  surface never loosens one.)*
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
