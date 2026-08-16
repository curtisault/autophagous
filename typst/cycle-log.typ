// AUTOPHAGOUS — CYCLE LOG (print artifact)
//
// The canonical printable log. Compile with:
//   typst compile typst/cycle-log.typ public/downloads/cycle-log.pdf
// (wired as `npm run print`). The live site links to the compiled PDF
// at /downloads/cycle-log.pdf — the site itself is never the print
// surface (docs/DESIGN-PRINCIPLES.md §print).
//
// Fonts are limited to what typst embeds (Libertinus Serif, DejaVu
// Sans Mono) so the artifact compiles identically on any machine.

#let ink = rgb("111214")
#let tint = rgb("dddddb")
#let hairline = 0.5pt + ink

#set page(paper: "a4", margin: (x: 16mm, top: 16mm, bottom: 16mm))
#set text(font: "Libertinus Serif", size: 10pt, fill: ink)

#let caps(body, size: 7pt, tracking: 1.1pt, weight: 700) = text(
  size: size,
  tracking: tracking,
  weight: weight,
  upper(body),
)
#let mono(body, size: 9pt) = text(font: "DejaVu Sans Mono", size: size, body)
#let cbox = box(width: 3.5mm, height: 3.5mm, stroke: 0.6pt + ink)
#let blank(w) = box(width: w, height: 4.2mm, stroke: (bottom: 0.6pt + ink))

// ---------- masthead ----------

#grid(
  columns: (1fr, auto, auto),
  column-gutter: 8mm,
  caps[Autophagy Protocol],
  caps[Cyclic · 72–96 h],
  caps[Rev. 3],
)
#v(-1mm)
#line(length: 100%, stroke: hairline)
#v(1.5mm)

#text(size: 30pt, weight: 800, tracking: -0.3pt)[#upper[Cycle log]]
#v(-2mm)

#grid(
  columns: (auto, auto, auto, 1fr),
  column-gutter: 8mm,
  align: bottom,
  [#caps(size: 6.5pt)[Cycle no.] #blank(14mm)],
  [#caps(size: 6.5pt)[Start date] #blank(26mm)],
  [#caps(size: 6.5pt)[Target] #blank(12mm) #caps(size: 6.5pt)[h]],
  align(right)[#caps(size: 6.5pt)[One sheet per cycle]],
)
#v(1mm)
#line(length: 100%, stroke: 2.2pt + ink)
#v(3mm)

// ---------- the log ----------

#block(stroke: 1.2pt + ink)[
  #table(
    columns: (13mm, 17mm, 15mm, 15mm, 9.5mm, 9.5mm, 9.5mm, 10mm, 1fr),
    rows: (9mm, 11.5mm),
    stroke: hairline,
    inset: (x: 1.8mm, y: 1.6mm),
    fill: (x, y) => if y >= 4 and y <= 7 { tint },
    align: (x, y) => if x == 0 or (x >= 4 and x <= 7) {
      center + horizon
    } else if y == 0 {
      left + bottom
    } else {
      left + top
    },
    table.header(
      caps(size: 6pt)[Day],
      caps(size: 6pt)[Weight],
      caps(size: 6pt)[Water L],
      caps(size: 6pt)[Salt tsp],
      caps(size: 6pt)[K⁺],
      caps(size: 6pt)[Mg],
      caps(size: 6pt)[B1],
      caps(size: 6pt)[Walk],
      caps(size: 6pt)[Energy, symptoms, notes],
    ),
    mono[P−3], [], [], [], cbox, cbox, cbox, cbox, [],
    mono[P−2], [], [], [], cbox, cbox, cbox, cbox, [],
    mono[P−1], [], [], [], cbox, cbox, cbox, cbox, [],
    mono[F1], [], [], [], cbox, cbox, cbox, cbox, [],
    mono[F2], [], [], [], cbox, cbox, cbox, cbox, [],
    mono[F3], [], [], [], cbox, cbox, cbox, cbox, [],
    mono[F4], [], [], [], cbox, cbox, cbox, cbox, [],
    mono[R1], [], [], [], cbox, cbox, cbox, cbox, text(size: 8pt)[First meal:],
    mono[R2], [], [], [], cbox, cbox, cbox, cbox, [],
  )
]
#v(1.5mm)
#caps(size: 6pt, weight: 500)[Key] #h(2mm) #text(size: 8pt)[P = prime · F = fast · R = refeed · shaded rows are the fast itself · tick each box when done]
#v(4mm)

// ---------- bench references ----------

#grid(
  columns: (1fr, 1fr),
  column-gutter: 6mm,
  [
    #caps(size: 7pt)[Daily targets during the fast]
    #v(-1.5mm)
    #line(length: 100%, stroke: hairline)
    #v(0.5mm)
    #set text(size: 8.5pt)
    #table(
      columns: (auto, 1fr),
      column-gutter: 2.5mm,
      stroke: none,
      inset: (x: 0mm, y: 0.9mm),
      [#mono(size: 8pt)[3,000–5,000 mg]], [Sodium — 1¼–2 tsp fine salt, divided, in water],
      [#mono(size: 8pt)[1,000–3,000 mg]], [Potassium — small doses only, never one large dose],
      [#mono(size: 8pt)[300–500 mg]], [Magnesium — glycinate or malate, at night],
      [#mono(size: 8pt)[50–100 mg]], [Thiamine (B1) — refeeding insurance, daily],
      [#mono(size: 8pt)[2–3 L]], [Water — salted; plain volume alone risks hyponatremia],
      [#mono(size: 8pt)[30–60 min]], [Easy walking, days 1–2, tapering after],
    )
  ],
  [
    #caps(size: 7pt)[Break the fast immediately if]
    #v(-1.5mm)
    #line(length: 100%, stroke: hairline)
    #v(0.5mm)
    #set text(size: 8.5pt)
    #set list(marker: [–], tight: true, spacing: 1.1em)
    - Heart palpitations, irregular heartbeat, or chest pain
    - Fainting, or near-fainting that doesn't resolve on sitting
    - Confusion, slurred speech, or disorientation
    - Persistent vomiting, or you can't keep water down
    - Visual disturbance, or severe weakness (can't climb stairs)
    - Numbness or tingling that spreads

    #text(size: 8pt)[None of these are "push through" symptoms. Eat something, salt it, reassess. A cycle abandoned early costs almost nothing.]
  ],
)

#v(1fr)
#line(length: 100%, stroke: 2.2pt + ink)
#v(1mm)
#text(size: 7.5pt)[*General information, not medical advice.* Refeed order: thiamine first, then small cooked vegetables, protein at +3 h, starch and sugar last. Full protocol: the AUTOPHAGOUS protocol sheet, §07–§09.]
