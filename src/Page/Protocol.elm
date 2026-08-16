module Page.Protocol exposing (view)

{-| The protocol broadsheet — the full content of
`docs/autophagy-protocol.html` (Rev. 3), worn as a house document
(`Doc.elm`). Pure view: no state, no Cmd.

The section list below is the single source of truth: the contents
rail and the `§` numbers derive from its order. In-prose
cross-references ("see §09") are hand-written — reordering sections
means grepping this file for `§`.

-}

import Doc
import Html exposing (Html, a, b, div, em, h3, h4, i, li, ol, p, span, sup, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (class, href, style)



-- HELPERS


ref : String -> Html msg
ref label =
    sup [ class "ref" ] [ text label ]


bT : String -> Html msg
bT s =
    b [] [ text s ]


emT : String -> Html msg
emT s =
    em [] [ text s ]


note : List (Html msg) -> Html msg
note =
    div [ class "note" ]


thW : String -> String -> Html msg
thW w label =
    th [ style "width" w ] [ text label ]


tightList : List (List (Html msg)) -> Html msg
tightList items =
    ul [ class "tight" ] (List.map (li []) items)



-- VIEW


view : Html msg
view =
    Doc.view
        { tag = "Autophagy Protocol"
        , kicker = "Cyclic · 72–96 h"
        , rev = "Rev. 3"
        , titleLines = [ "Demolition", "and rebuild" ]
        , standfirst = "A cycle-based protocol for maximising autophagic signalling: how to prime for it, what is mandatory during the fast, and why the refeed is half the intervention."
        , sections =
            [ { anchor = "sec-limits"
              , tocLabel = "The limits"
              , title = "What you can and cannot know"
              , intent = "Epistemic ground rules"
              , body = Doc.Clauses secLimits
              }
            , { anchor = "sec-switches"
              , tocLabel = "Two switches"
              , title = "The two switches"
              , intent = "mTORC1 off · AMPK on"
              , body = Doc.Clauses secSwitches
              }
            , { anchor = "sec-safety"
              , tocLabel = "Safety"
              , title = "Read this before anything else"
              , intent = "Contraindications · abort signals"
              , body = Doc.Clauses secSafety
              }
            , { anchor = "sec-glp1"
              , tocLabel = "GLP-1"
              , title = "If you are on a GLP-1"
              , intent = "Not self-managed anymore"
              , body = Doc.Clauses secGlp1
              }
            , { anchor = "sec-cycle"
              , tocLabel = "The cycle"
              , title = "The cycle"
              , intent = "Repeat monthly · never stacked"
              , body = Doc.Clauses secCycle
              }
            , { anchor = "sec-prime"
              , tocLabel = "Priming"
              , title = "Phase 1 — priming, 3 days"
              , intent = "Arrive already switched"
              , body = Doc.Clauses secPrime
              }
            , { anchor = "sec-fast"
              , tocLabel = "The fast"
              , title = "Phase 2 — hard requirements"
              , intent = "Electrolytes in · calories out"
              , body = Doc.Clauses secFast
              }
            , { anchor = "sec-stages"
              , tocLabel = "By the clock"
              , title = "Stages, by the clock"
              , intent = "0–96 h · linear"
              , body = Doc.Panel secStages
              }
            , { anchor = "sec-refeed"
              , tocLabel = "The refeed"
              , title = "Phase 3 — the refeed"
              , intent = "The dangerous 48 hours"
              , body = Doc.Clauses secRefeed
              }
            , { anchor = "sec-rebuild"
              , tocLabel = "The rebuild"
              , title = "Phase 4 — the rebuild"
              , intent = "Three weeks of construction"
              , body = Doc.Clauses secRebuild
              }
            , { anchor = "sec-log"
              , tocLabel = "Cycle log"
              , title = "Cycle log"
              , intent = "One sheet per cycle"
              , body = Doc.Panel secLog
              }
            , { anchor = "sec-refs"
              , tocLabel = "References"
              , title = "References"
              , intent = "Evidence classes marked"
              , body = Doc.Panel secRefs
              }
            ]
        , footNote =
            [ p [ style "margin" "0" ]
                [ bT "This is general information, not medical advice, and I'm not a doctor."
                , text " Prolonged fasting carries real risk that varies enormously with your individual health, medications and history. Talk to a physician before your first cycle, and get baseline bloodwork — electrolytes, kidney function, glucose — if you intend to repeat this monthly."
                ]
            ]
        }



-- §01 THE LIMITS


secLimits : List (Html msg)
secLimits =
    [ p [ class "lede" ] [ text "You cannot measure your own autophagy. Nobody can, easily." ]
    , p []
        [ text "Autophagy is measured by tissue biopsy and immunoblotting for markers like LC3B lipidation and p62 clearance — and even in laboratories, distinguishing genuine autophagic "
        , emT "flux"
        , text " from a backed-up pipeline requires careful controls."
        , ref "[1]"
        , text " There is no blood test, no wearable, no home assay. Ketone meters measure ketosis, which is a correlated but separate process."
        ]
    , p []
        [ text "This matters for how you should read every number below. Most autophagy timing data comes from rodents, whose metabolic rate is several times faster than ours; a 24-hour mouse fast is not a 24-hour human fast. Claims that \u{201C}autophagy peaks at hour 72\u{201D} are extrapolation presented as fact. What follows optimises the "
        , emT "mechanisms known to switch autophagy on"
        , text ", which is the honest version of the goal."
        ]
    , note
        [ bT "The practical consequence."
        , text " Since you can't verify the output, choose the approach with the best risk-adjusted mechanistic case rather than the most extreme one. That single principle is why this protocol recommends repeated 3-to-4 day cycles instead of one seven-day fast."
        ]
    ]



-- §02 THE TWO SWITCHES


secSwitches : List (Html msg)
secSwitches =
    [ p []
        [ text "Every rule in this document derives from two nutrient sensors. Yoshinori Ohsumi's mapping of the autophagy machinery won the 2016 Nobel Prize in Physiology or Medicine;"
        , ref "[2]"
        , text " what follows is the applied edge of it."
        ]
    , table []
        [ thead []
            [ tr []
                [ thW "20%" "Sensor"
                , thW "34%" "Autophagy is ON when"
                , th [] [ text "What flips it the wrong way" ]
                ]
            ]
        , tbody []
            [ tr [ class "hero" ]
                [ td [] [ text "mTORC1" ]
                , td [] [ text "It is ", bT "inhibited", text " — no growth signal present" ]
                , td []
                    [ text "Amino acids, "
                    , bT "especially leucine"
                    , text ". Sestrin2 binds leucine directly and releases its brake on mTORC1 at concentrations around 20\u{00A0}µM."
                    , ref "[3]"
                    , text " Also insulin and IGF-1."
                    ]
                ]
            , tr []
                [ td [] [ text "AMPK" ]
                , td [] [ text "It is ", bT "activated", text " — cellular energy is low" ]
                , td [] [ text "Available calories of any kind. Fat included." ]
                ]
            ]
        ]
    , note
        [ bT "The single most important consequence."
        , text " mTORC1 senses "
        , emT "amino acids directly"
        , text ", not just calories. A small amount of protein suppresses autophagic signalling far more effectively than the same calories as fat. This is why bone broth, collagen, BCAAs and \u{201C}fasting-safe\u{201D} protein products are excluded below, and it is the biggest change from a general-purpose fasting protocol."
        ]
    ]



-- §03 SAFETY


secSafety : List (Html msg)
secSafety =
    [ div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Do not attempt without a doctor" ]
        , div [ class "cols" ]
            [ div []
                [ h4 [] [ text "Hard contraindications" ]
                , tightList
                    [ [ text "Type 1 diabetes, or Type 2 on insulin or sulfonylureas" ]
                    , [ bT "SGLT2 inhibitors", text " — risk of euglycemic ketoacidosis" ]
                    , [ text "Pregnancy or breastfeeding" ]
                    , [ text "Any history of an eating disorder" ]
                    , [ text "BMI under 18.5, or currently underweight" ]
                    , [ text "Under 18, or frail / elderly" ]
                    ]
                ]
            , div []
                [ h4 [] [ text "Clear it first" ]
                , tightList
                    [ [ text "Diuretics, ACE inhibitors, ARBs, spironolactone" ]
                    , [ text "Lithium — levels shift with sodium and fluid" ]
                    , [ text "Kidney disease of any stage" ]
                    , [ text "Arrhythmia or known heart condition" ]
                    , [ text "Gout — uric acid rises during a fast" ]
                    , [ text "Blood pressure medication — doses often need reducing", ref "[4]" ]
                    , [ bT "GLP-1 receptor agonists", text " — substantial changes required, see §04" ]
                    ]
                ]
            ]
        ]
    , div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Break the fast immediately if" ]
        , div [ class "cols" ]
            [ tightList
                [ [ text "Heart palpitations or irregular heartbeat" ]
                , [ text "Chest pain" ]
                , [ text "Fainting, or near-fainting that doesn't resolve on sitting" ]
                , [ text "Confusion, slurred speech, or disorientation" ]
                ]
            , tightList
                [ [ text "Persistent vomiting, or you can't keep water down" ]
                , [ text "Visual disturbance" ]
                , [ text "Severe weakness — can't climb stairs" ]
                , [ text "Numbness or tingling that spreads" ]
                ]
            ]
        , p [ class "slab-foot" ]
            [ text "None of these are \u{201C}push through\u{201D} symptoms. Eat something, salt it, and reassess. A cycle abandoned early costs you almost nothing; you have another one next month." ]
        ]
    , note
        [ bT "On the safety literature."
        , text " The largest prolonged-fasting safety study — 1,422 people fasting 4 to 21 days, adverse events under 1% — is frequently cited as evidence that long fasts are safe."
        , ref "[5]"
        , text " Two caveats worth knowing: it was conducted at a specialist clinic with medical supervision, and the protocol was "
        , emT "not"
        , text " water-only. Participants received roughly 200–250 kcal per day. Unsupervised water fasting is a different intervention with a different risk profile."
        ]
    ]



-- §04 GLP-1


secGlp1 : List (Html msg)
secGlp1 =
    [ p [ class "lede" ]
        [ text "Semaglutide, tirzepatide, liraglutide and their relatives change this protocol enough that it stops being a self-managed proposition." ]
    , p []
        [ text "This is not a caution added out of an abundance of care. Four specific mechanisms interact badly with prolonged fasting, and two of them affect the refeed — already the most dangerous part of the cycle." ]
    , div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Discuss with your prescriber before cycle 1" ]
        , table [ style "margin-bottom" "0" ]
            [ thead []
                [ tr []
                    [ thW "30%" "Interaction"
                    , th [] [ text "What it means for this protocol" ]
                    ]
                ]
            , tbody []
                [ tr [ class "hero" ]
                    [ td [] [ text "Delayed gastric emptying" ]
                    , td []
                        [ text "GLP-1s slow gastric emptying roughly two- to four-fold. The anesthesia literature records patients with substantial solid gastric contents despite correct fasting — in some cases after more than a day without food and weeks off the drug."
                        , ref "[18]"
                        , text " The refeed schedule in §09 assumes food moves through on a normal clock. Yours may not."
                        ]
                    ]
                , tr [ class "hero" ]
                    [ td [] [ text "You may already meet a refeeding risk criterion" ]
                    , td []
                        [ text "Standard clinical criteria flag unintentional weight loss above 10–15% over 3–6 months as elevated refeeding-syndrome risk"
                        , ref "[13]"
                        , text " — a threshold many GLP-1 users cross. Months of reduced intake can also leave phosphate, magnesium and thiamine stores low invisibly. The \u{201C}3–4 days is safer than 7\u{201D} reasoning assumed a well-nourished, weight-stable baseline."
                        ]
                    ]
                , tr []
                    [ td [] [ text "Lean mass is already under pressure" ]
                    , td []
                        [ text "In the SURMOUNT-1 DXA substudy roughly 25% of weight lost was lean mass; semaglutide substudies have reported higher fractions."
                        , ref "[19]"
                        , text " Stacking prolonged fasting compounds precisely what Phase 4 exists to counteract."
                        ]
                    ]
                , tr []
                    [ td [] [ text "You cannot time around it" ]
                    , td []
                        [ text "Semaglutide's half-life is about a week — roughly five weeks to clear. Skipping a single injection resets nothing. Whatever you decide, you are fasting on the drug." ]
                    ]
                ]
            ]
        ]
    , div []
        [ h3 [ class "sub-head" ] [ text "Modifications, if you get the green light" ]
        , table []
            [ thead []
                [ tr []
                    [ thW "26%" "Section"
                    , thW "30%" "Standard"
                    , th [] [ text "On a GLP-1" ]
                    ]
                ]
            , tbody []
                [ tr [ class "hero" ]
                    [ td [] [ text "Fast length" ]
                    , td [] [ text "72–96 h" ]
                    , td [] [ bT "Cap at 72 h.", text " Drop the optional fourth day entirely." ]
                    ]
                , tr []
                    [ td [] [ text "Cycle spacing" ]
                    , td [] [ text "Monthly" ]
                    , td [] [ text "Every 6–8 weeks. More recovery, fewer cumulative deficits." ]
                    ]
                , tr []
                    [ td [] [ text "Timing" ]
                    , td [] [ text "Any time" ]
                    , td [] [ bT "Never during dose escalation", text " or in the weeks after a dose increase — GI effects and emptying delay are worst then." ]
                    ]
                , tr []
                    [ td [] [ text "Refeed (§09)" ]
                    , td [] [ text "2 days" ]
                    , td [] [ bT "3–4 days.", text " See modified sequence below." ]
                    ]
                , tr []
                    [ td [] [ text "Protein & training (§10)" ]
                    , td [] [ text "Recommended" ]
                    , td [] [ bT "Mandatory.", text " Hit the protein target and lift. This is the only lever against compounded lean mass loss." ]
                    ]
                , tr []
                    [ td [] [ text "Hydration" ]
                    , td [] [ text "2–3 L salted" ]
                    , td [] [ text "Same targets, higher vigilance. GI losses plus fasting natriuresis plus blunted thirst is a real volume-depletion and kidney risk." ]
                    ]
                , tr []
                    [ td [] [ text "Hunger as a signal" ]
                    , td [] [ text "Fades ~36–48 h" ]
                    , td [] [ text "Meaningless. Your appetite is already suppressed, so you lose that feedback channel. Rely on the log, not on how you feel." ]
                    ]
                ]
            ]
        ]
    , div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Modified refeed sequence" ]
        , ul [ class "tight", style "margin-bottom" "0" ]
            [ li [] [ bT "Thiamine first", text ", before anything else, exactly as in §09." ]
            , li [] [ bT "Clear liquids only for the first 6–8 hours.", text " Vegetable broth, thin soup. Amino acids are no longer a concern once the fast has ended." ]
            , li [] [ bT "Liquid and pureed textures for the first 24 hours.", text " Solids are what get retained. Soups, purees, yoghurt — not salad, not meat." ]
            , li [] [ bT "Very small volumes, frequently.", text " A quarter of what seems reasonable, every 2–3 hours." ]
            , li [] [ bT "Stay upright for an hour after eating.", text " Do not eat and lie down." ]
            , li [] [ bT "If you feel full, stop.", text " Fullness on a GLP-1 after a fast means food is sitting, not that you have eaten enough. Pushing more in on top is the failure mode." ]
            , li [] [ bT "Solids only from day 2", text ", and only if day 1 passed without nausea." ]
            ]
        ]
    , div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Additional abort signals" ]
        , div [ class "cols" ]
            [ tightList
                [ [ text "Any vomiting — not just persistent vomiting" ]
                , [ text "Severe abdominal distension or pain" ]
                , [ text "Inability to pass stool or gas" ]
                ]
            , tightList
                [ [ text "Reflux or regurgitation, especially lying down" ]
                , [ text "Dark urine or no urine output" ]
                , [ text "Dizziness that persists after salt and fluid" ]
                ]
            ]
        , p [ class "slab-foot" ]
            [ text "Bowel obstruction and ileus appear in GLP-1 labelling as recognised risks. Distension with absent bowel movements is an urgent-care symptom, not a fasting symptom." ]
        ]
    , div []
        [ h3 [ class "sub-head" ] [ text "Bloodwork to request beforehand" ]
        , div [ class "cols" ]
            [ div []
                [ h4 [] [ text "Directly relevant" ]
                , tightList
                    [ [ bT "Phosphate", text " — the refeeding-syndrome marker, rarely on a standard panel unless asked" ]
                    , [ bT "Magnesium", text " — also frequently omitted" ]
                    , [ text "Potassium and sodium" ]
                    , [ text "Creatinine and eGFR — kidney baseline" ]
                    ]
                ]
            , div []
                [ h4 [] [ text "Useful context" ]
                , tightList
                    [ [ text "Full blood count and albumin — nutritional status" ]
                    , [ text "HbA1c or fasting glucose" ]
                    , [ text "Liver function" ]
                    , [ text "Repeat phosphate and magnesium after the first refeed" ]
                    ]
                ]
            ]
        ]
    , note
        [ bT "One honest gap."
        , text " Whether GLP-1 agonists themselves raise or blunt autophagic signalling is not settled. There is preclinical work pointing both directions and no clean human answer. So the interaction with the specific thing you are targeting is unknown — the risks above are well characterised, the benefit side is not."
        ]
    ]



-- §05 THE CYCLE


secCycle : List (Html msg)
secCycle =
    [ p [ class "lede" ] [ text "One fast is an event. Cycles are the intervention." ]
    , p []
        [ text "Autophagic signalling begins upregulating early — around the 16-to-24 hour mark as glycogen depletes — and the marginal gain from hour 120 to hour 168 is speculative while the risk curve is not. The published regenerative work is built on "
        , emT "repeated cycles"
        , text ": fasting-mimicking protocols run five days monthly for three months, not one long fast."
        , ref "[6][7]"
        , text " More cumulative cycles beats one heroic effort, and it keeps you clear of the window where refeeding syndrome becomes serious."
        ]
    , div []
        [ div [ class "cycle" ]
            [ div []
                [ span [ class "ph" ] [ text "Phase 1" ]
                , span [ class "dy" ] [ text "3 d" ]
                , span [ class "ds" ] [ text "Prime. Deplete glycogen, load inducers." ]
                ]
            , div [ class "fast-phase" ]
                [ span [ class "ph" ] [ text "Phase 2" ]
                , span [ class "dy" ] [ text "3–4 d" ]
                , span [ class "ds" ] [ text "Fast. Water, salt, minerals only." ]
                ]
            , div []
                [ span [ class "ph" ] [ text "Phase 3" ]
                , span [ class "dy" ] [ text "2 d" ]
                , span [ class "ds" ] [ text "Refeed. Careful, ordered reintroduction." ]
                ]
            , div []
                [ span [ class "ph" ] [ text "Phase 4" ]
                , span [ class "dy" ] [ text "~3 wk" ]
                , span [ class "ds" ] [ text "Rebuild. Eat and train normally." ]
                ]
            ]
        , p [ class "u", style "font-size" ".6rem", style "margin" "0 0 1rem" ]
            [ text "Repeat monthly · do not stack cycles back to back" ]
        ]
    , note
        [ bT "Autophagy is only the demolition half."
        , text " The rebuild — stem-cell repopulation, mitochondrial biogenesis — happens on "
        , emT "refeeding"
        , text ", not during the fast. In the hematopoietic stem cell work, the regenerative signal appeared in the fasting/refeeding cycle, not in starvation alone."
        , ref "[8]"
        , text " A fast without a well-executed refeed is half an intervention performed badly."
        ]
    ]



-- §06 PRIMING


secPrime : List (Html msg)
secPrime =
    [ p []
        [ text "Two goals: arrive at the fast with liver glycogen already low, so you reach the metabolic switch in hours rather than a full day; and load compounds with independent pro-autophagic evidence." ]
    , table []
        [ thead []
            [ tr []
                [ thW "26%" "Do this"
                , thW "32%" "Specifically"
                , th [] [ text "Why" ]
                ]
            ]
        , tbody []
            [ tr [ class "hero" ]
                [ td [] [ text "Go low-carbohydrate" ]
                , td [] [ text "Under ~50 g/day for three days. Moderate protein, generous fat." ]
                , td [] [ text "Empties glycogen ahead of time. You start the fast most of the way through Stage I instead of at hour zero." ]
                ]
            , tr []
                [ td [] [ text "Load spermidine" ]
                , td [] [ text "Wheat germ (richest common source), natto, aged cheese, mushrooms, legumes, broccoli." ]
                , td []
                    [ text "Spermidine induces autophagy via EP300 inhibition — a route independent of mTOR — and extends lifespan across species."
                    , ref "[9][10][11]"
                    ]
                ]
            , tr []
                [ td [] [ text "Load polyphenols" ]
                , td [] [ text "Green tea, coffee, extra-virgin olive oil, berries, dark chocolate." ]
                , td []
                    [ text "Pro-autophagic polyphenols reduce cytoplasmic protein acetylation, the same signature nutrient depletion produces."
                    , ref "[12]"
                    ]
                ]
            , tr []
                [ td [] [ text "Taper protein on day −1" ]
                , td [] [ text "Keep the last day's protein light. No large steak, no protein shake, no leucine-heavy final meal." ]
                , td []
                    [ text "Reduces the amino acid signal you carry into the fast. Leucine is the specific molecule mTORC1 is listening for."
                    , ref "[3]"
                    ]
                ]
            , tr []
                [ td [] [ text "Start salting early" ]
                , td [] [ text "Extra sodium through the final 24 hours." ]
                , td [] [ text "Gets ahead of the natriuresis rather than chasing it. Prevents most of day one's misery." ]
                ]
            , tr []
                [ td [] [ text "Stop alcohol" ]
                , td [] [ text "Zero for the full priming window." ]
                , td [] [ text "Depletes thiamine — the exact reserve you need intact for the refeed." ]
                ]
            ]
        ]
    ]



-- §07 THE FAST


secFast : List (Html msg)
secFast =
    [ p [ class "lede" ]
        [ text "Non-negotiable. Electrolytes determine whether you finish; the exclusions determine whether it counts." ]
    , table []
        [ thead []
            [ tr []
                [ thW "22%" "Required daily"
                , thW "22%" "Target"
                , th [] [ text "Source and notes" ]
                ]
            ]
        , tbody []
            [ tr [ class "hero" ]
                [ td [] [ text "Sodium" ]
                , td [ class "amt mono" ] [ text "3,000–5,000 mg" ]
                , td [] [ text "1¼–2 tsp fine salt, divided across the day in water. Falling insulin makes the kidneys dump sodium; this is the cause of most \u{201C}fasting fatigue,\u{201D} headache and cramping." ]
                ]
            , tr []
                [ td [] [ text "Potassium" ]
                , td [ class "amt mono" ] [ text "1,000–3,000 mg" ]
                , td [] [ text "Potassium chloride \u{201C}lite salt,\u{201D} ⅓–1 tsp ", bT "divided into small doses across the day", text ". See warning below." ]
                ]
            , tr []
                [ td [] [ text "Magnesium" ]
                , td [ class "amt mono" ] [ text "300–500 mg" ]
                , td [] [ text "Glycinate or malate, taken at night. Citrate works but loosens the bowels." ]
                ]
            , tr [ class "hero" ]
                [ td [] [ text "Thiamine (B1)" ]
                , td [ class "amt mono" ] [ text "50–100 mg" ]
                , td []
                    [ text "Stores run only weeks and are consumed rapidly when carbohydrate returns. This is your refeeding insurance."
                    , ref "[13]"
                    ]
                ]
            , tr []
                [ td [] [ text "Water" ]
                , td [ class "amt mono" ] [ text "2–3 L" ]
                , td [] [ bT "Salted.", text " Drinking large volumes of plain water while sodium-depleted causes hyponatremia. Thirst plus salt, not volume for its own sake." ]
                ]
            , tr []
                [ td [] [ text "Black coffee" ]
                , td [ class "amt mono" ] [ text "1–3 cups" ]
                , td []
                    [ text "Promoted from \u{201C}permitted\u{201D} to \u{201C}recommended.\u{201D} Coffee raised autophagic flux in liver, muscle and heart within 1–4 hours and inhibited mTORC1 — and the effect held for decaffeinated coffee, implicating the polyphenols rather than caffeine."
                    , ref "[14]"
                    ]
                ]
            , tr []
                [ td [] [ text "Walking" ]
                , td [ class "amt mono" ] [ text "30–60 min" ]
                , td []
                    [ text "Easy pace, days 1–2, tapering after. Exercise is an independent autophagy inducer across muscle, liver, pancreas and adipose tissue."
                    , ref "[15]"
                    , text " No hard training."
                    ]
                ]
            ]
        ]
    , div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Excluded — these defeat the purpose" ]
        , div [ class "cols" ]
            [ div []
                [ h4 [] [ text "Breaks the mTORC1 target" ]
                , tightList
                    [ [ bT "Bone broth", text " — standard fasting advice, wrong for this goal" ]
                    , [ text "Collagen, BCAAs, EAAs, any protein powder" ]
                    , [ text "\u{201C}Fasting-safe\u{201D} supplements containing amino acids" ]
                    , [ text "Gelatin capsules in quantity" ]
                    ]
                ]
            , div []
                [ h4 [] [ text "Breaks the AMPK target" ]
                , tightList
                    [ [ bT "MCT oil, butter, cream", text " — \u{201C}fat doesn't break a fast\u{201D} is false here" ]
                    , [ text "Exogenous ketones" ]
                    , [ text "Anything with calories, including \u{201C}just a splash\u{201D}" ]
                    , [ text "Sweeteners and gum — cephalic-phase insulin response" ]
                    ]
                ]
            ]
        , p [ class "slab-foot", style "margin-top" ".5rem" ]
            [ text "Permitted without qualification: water, salt, the minerals above, black coffee, plain and green tea, sparkling water." ]
        ]
    , note
        [ bT "Potassium warning."
        , text " Never take potassium as a single large dose — it can trigger arrhythmia. Divide it across the day in water. Skip potassium supplementation entirely if you have any kidney impairment or take ACE inhibitors, ARBs, or potassium-sparing diuretics. This is the one item here with a genuinely narrow margin."
        ]
    , note
        [ bT "Also required:"
        , text " stand up slowly every time, keep the room warm, don't drive while lightheaded, and skip saunas and hot baths entirely — fainting risk is real and peaks on days 2–3."
        ]
    ]



-- §08 BY THE CLOCK


secStages : List (Html msg)
secStages =
    [ ruler
    , stage "I" "0–16 h" "Glycogen draw-down" <|
        [ p []
            [ text "Insulin falls, the liver releases stored glucose. Roughly 100 g of glycogen is spent. Autophagy remains at baseline — nutrient sensors still read \u{201C}fed.\u{201D}" ]
        , p [ class "feel" ]
            [ bT "Autophagy"
            , text " — Baseline. Nothing yet. "
            , bT "This is the stage your priming phase shortens"
            , text ", potentially to a few hours."
            ]
        ]
    , stage "II" "16–24 h" "The switch" <|
        [ p []
            [ text "Glycogen runs out. Lipolysis accelerates, ketogenesis begins, and as insulin, IGF-1 and amino acid availability all fall together, mTORC1 goes quiet and AMPK activates."
            , ref "[16]"
            ]
        , p [ class "feel" ]
            [ bT "Autophagy", text " — Upregulation begins here. This is the entry point, not hour 72." ]
        , p [ class "feel" ]
            [ bT "How it feels", text " — The worst stretch. Hunger waves, irritability, headache. Salt now." ]
        ]
    , stage "III" "24–48 h" "Climbing" <|
        [ p []
            [ text "Ketones rise from roughly 0.5 toward 2–3 mmol/L. Gluconeogenesis supplies what glucose is still needed from glycerol, lactate and amino acids. Insulin and IGF-1 reach their floor — and it is the IGF-1 drop that drives the regenerative signalling downstream."
            , ref "[8]"
            ]
        , p [ class "feel" ]
            [ bT "Autophagy", text " — Sustained induction. Every hour here is doing work." ]
        , p [ class "feel" ]
            [ bT "How it feels", text " — Hunger usually fades around hour 36–48, often abruptly. Clarity frequently improves." ]
        ]
    , stage "IV" "48–72 h" "Sustained" <|
        [ p []
            [ text "Deep ketosis, near-exclusive fat oxidation, nitrogen loss falling as protein sparing engages."
            , ref "[17]"
            , text " Growth hormone is markedly elevated. All the upstream conditions for autophagy are maximally satisfied and stay that way."
            ]
        , p [ class "feel" ]
            [ bT "Autophagy", text " — Held at the induced state. The plateau you came for." ]
        , p [ class "feel" ]
            [ bT "How it feels", text " — Weaker, cold, low stamina. Standing fast will grey your vision." ]
        ]
    , stage "V" "72–96 h" "Optional extension" <|
        [ p []
            [ text "A steady state; little changes mechanistically. Take this day if the fast has gone smoothly and you're experienced, skip it freely if not." ]
        , p [ class "feel" ]
            [ bT "Autophagy", text " — No clear additional induction, just more time at the plateau. Diminishing returns begin." ]
        , p [ class "feel" ]
            [ bT "Stop here."
            , text " Past roughly day five, refeeding syndrome risk climbs steeply while the mechanistic case flattens. That trade is the reason this protocol caps at four days."
            ]
        ]
    ]


stage : String -> String -> String -> List (Html msg) -> Html msg
stage numeral hours title body =
    div [ class "stage" ]
        [ div [ class "stage-meta" ]
            [ span [ class "no" ] [ text numeral ]
            , span [ class "hrs" ] [ text hours ]
            ]
        , div [] (h3 [] [ text title ] :: body)
        ]


ruler : Html msg
ruler =
    div [ class "ruler-wrap" ]
        [ div [ class "flagrow" ]
            [ span [ style "left" "75%" ] [ text "▼ 72 h — target" ] ]
        , div [ class "ruler" ]
            [ div [ class "zone tint", style "left" "75%", style "width" "25%" ] []
            , div [ class "zone hatch", style "left" "0", style "width" "16.667%" ] []
            , div [ class "vdiv", style "left" "16.667%" ] []
            , div [ class "vdiv", style "left" "25%" ] []
            , div [ class "vdiv", style "left" "50%" ] []
            , div [ class "rlbl", style "left" "0", style "width" "16.667%" ] [ b [] [ text "I" ] ]
            , div [ class "rlbl", style "left" "16.667%", style "width" "8.333%" ] [ b [] [ text "II" ] ]
            , div [ class "rlbl", style "left" "25%", style "width" "25%" ] [ b [] [ text "III" ] ]
            , div [ class "rlbl", style "left" "50%", style "width" "25%" ] [ b [] [ text "IV" ] ]
            , div [ class "rlbl", style "left" "75%", style "width" "25%" ] [ b [] [ text "V" ] ]
            , div [ class "target", style "left" "75%" ] []
            ]
        , div [ class "ticks" ]
            [ div [ class "tick first", style "left" "0" ] [ text "0h" ]
            , div [ class "tick", style "left" "16.667%" ] [ text "16" ]
            , div [ class "tick", style "left" "25%" ] [ text "24" ]
            , div [ class "tick", style "left" "50%" ] [ text "48" ]
            , div [ class "tick", style "left" "75%" ] [ text "72" ]
            , div [ class "tick last", style "left" "100%" ] [ text "96" ]
            ]
        , div [ class "names" ]
            [ div [ class "nm", style "left" "0", style "width" "16.667%" ] [ text "Draw-down" ]
            , div [ class "nm low", style "left" "16.667%", style "width" "8.333%" ] [ text "Switch" ]
            , div [ class "nm", style "left" "25%", style "width" "25%" ] [ text "Climbing" ]
            , div [ class "nm", style "left" "50%", style "width" "25%" ] [ text "Sustained" ]
            , div [ class "nm", style "left" "75%", style "width" "25%" ] [ text "Optional extension" ]
            ]
        , div [ class "legend" ]
            [ span [] [ i [ class "swatch hatched" ] [], text "Shortened by priming" ]
            , span [] [ i [ class "swatch mark" ] [], text "Minimum target" ]
            , span [] [ i [ class "swatch tint" ] [], text "Optional 4th day" ]
            ]
        , p [ class "u", style "font-size" ".6rem", style "margin" ".5rem 0 0" ]
            [ text "Linear scale · band width is true to duration" ]
        ]



-- §09 THE REFEED


secRefeed : List (Html msg)
secRefeed =
    [ div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Refeeding syndrome" ]
        , p [ style "margin" "0 0 .7rem", style "font-size" ".92rem" ]
            [ text "More people are harmed breaking a long fast than doing one. A large carbohydrate load spikes insulin, which drives phosphate, potassium and magnesium rapidly out of the bloodstream into cells. The resulting hypophosphataemia can cause arrhythmia, respiratory failure and death."
            , ref "[13]"
            ]
        , p [ style "margin" "0", style "font-size" ".92rem" ]
            [ text "At 3–4 days in a well-nourished adult the risk is meaningfully lower than at seven — but \u{201C}lower\u{201D} is not \u{201C}absent,\u{201D} and the protective steps are trivial to take." ]
        ]
    , table []
        [ thead []
            [ tr []
                [ thW "16%" "Order"
                , thW "26%" "What"
                , th [] [ text "Notes" ]
                ]
            ]
        , tbody []
            [ tr [ class "hero" ]
                [ td [ class "mono" ] [ text "First" ]
                , td [] [ text "Thiamine, before any food" ]
                , td []
                    [ text "Not after. Thiamine is consumed as carbohydrate metabolism restarts; deficiency at this moment is the mechanism behind the worst outcomes."
                    , ref "[13]"
                    ]
                ]
            , tr []
                [ td [ class "mono" ] [ text "Hour 0" ]
                , td [] [ text "Small portion of cooked vegetables, or vegetable broth with olive oil" ]
                , td [] [ text "Tiny. Half of what looks reasonable. Digestive enzyme output is reduced and your stomach has shrunk." ]
                ]
            , tr []
                [ td [ class "mono" ] [ text "+3 h" ]
                , td [] [ text "Protein — eggs, fish, or soft-cooked meat" ]
                , td [] [ text "Modest portion. This is the anabolic signal that starts the rebuild, so it belongs here — just not first and not large." ]
                ]
            , tr []
                [ td [ class "mono" ] [ text "Day 2" ]
                , td [] [ text "Normal meals; reintroduce starch, fruit and sugar last" ]
                , td [] [ text "Keep carbohydrate deliberately low for the first 24–48 hours." ]
                ]
            , tr []
                [ td [ class "mono" ] [ text "Throughout" ]
                , td [] [ text "Keep magnesium and potassium going" ]
                , td [] [ text "Requirement goes ", emT "up", text ", not down, as insulin returns and drives them intracellularly." ]
                ]
            ]
        ]
    , note
        [ bT "Expect the scale to jump."
        , text " Several pounds return within days. That is glycogen, sodium and water — not fat, and not failure."
        ]
    ]



-- §10 THE REBUILD


secRebuild : List (Html msg)
secRebuild =
    [ p []
        [ text "The three weeks after the fast are where regeneration actually occurs. Fasting cleared damaged components; this window replaces them. Wasting it undoes much of the point." ]
    , table []
        [ thead []
            [ tr []
                [ thW "26%" "Priority"
                , thW "32%" "Specifically"
                , th [] [ text "Why" ]
                ]
            ]
        , tbody []
            [ tr [ class "hero" ]
                [ td [] [ text "Resistance training" ]
                , td [] [ text "Start within 2–3 days of refeeding, then 2–3 sessions weekly." ]
                , td [] [ text "Directs the returning anabolic signal into muscle rather than fat. Without a mechanical stimulus, mTORC1 reactivation is untargeted." ]
                ]
            , tr []
                [ td [] [ text "Adequate protein" ]
                , td [] [ text "Roughly 1.2–1.6 g per kg bodyweight daily through the rebuild weeks." ]
                , td [] [ text "Regeneration is a construction project. Restricting protein now is fighting your own intervention." ]
                ]
            , tr []
                [ td [] [ text "Keep spermidine and polyphenols high" ]
                , td [] [ text "Same foods as the priming phase — wheat germ, natto, mushrooms, legumes, green tea, olive oil, berries." ]
                , td []
                    [ text "Sustains basal autophagic tone between cycles without requiring caloric restriction."
                    , ref "[9][10][11]"
                    ]
                ]
            , tr []
                [ td [] [ text "Fermented foods and fibre" ]
                , td [] [ text "Yoghurt, kefir, sauerkraut, kimchi, diverse plants." ]
                , td [] [ text "Prolonged fasting shifts the gut microbiome; the rebuild window is when you influence what recolonises." ]
                ]
            , tr []
                [ td [] [ text "Omega-3" ]
                , td [] [ text "Oily fish twice weekly, or supplement." ]
                , td [] [ text "Membrane reconstruction and inflammatory resolution." ]
                ]
            , tr []
                [ td [] [ text "Sleep" ]
                , td [] [ text "Protect it deliberately for the first week." ]
                , td [] [ text "Autophagy in the brain is sleep-dependent. Under-sleeping the rebuild is self-defeating." ]
                ]
            ]
        ]
    , note
        [ bT "Don't crash-diet between cycles."
        , text " Chronic restriction on top of monthly prolonged fasts is a different and more dangerous intervention than either alone, and there's no evidence the combination adds autophagic benefit. Eat normally."
        ]
    ]



-- §11 CYCLE LOG


secLog : List (Html msg)
secLog =
    [ p [ style "font-size" ".85rem" ]
        [ text "Fill in by hand. Tracking is how you catch a problem while it's still small — and how you compare cycle three to cycle one. A print-grade PDF of this log is generated from the typst source: "
        , a [ href "/downloads/cycle-log.pdf" ] [ text "download the cycle log" ]
        , text "."
        ]
    , table [ class "log" ]
        [ thead []
            [ tr []
                [ thW "11%" "Day"
                , thW "11%" "Weight"
                , thW "11%" "Water L"
                , thW "11%" "Salt tsp"
                , thW "8%" "K⁺"
                , thW "8%" "Mg"
                , thW "8%" "B1"
                , thW "8%" "Walk"
                , th [] [ text "Energy, symptoms, notes" ]
                ]
            ]
        , tbody []
            [ logRow False "P−3" ""
            , logRow False "P−2" ""
            , logRow False "P−1" ""
            , logRow True "F1" ""
            , logRow True "F2" ""
            , logRow True "F3" ""
            , logRow True "F4" ""
            , logRow False "R1" "First meal:"
            , logRow False "R2" ""
            ]
        ]
    , p [ style "font-size" ".75rem", style "margin" "0" ]
        [ span [ class "u", style "font-size" ".6rem" ] [ text "Key" ]
        , text "\u{00A0} P = prime · F = fast · R = refeed · shaded rows are the fast itself"
        ]
    ]


logRow : Bool -> String -> String -> Html msg
logRow hero day notes =
    let
        boxCell =
            td [ style "text-align" "center" ] [ span [ class "box" ] [] ]
    in
    tr
        (if hero then
            [ class "hero" ]

         else
            []
        )
        [ td [ class "mono", style "text-align" "center" ] [ text day ]
        , td [] []
        , td [] []
        , td [] []
        , boxCell
        , boxCell
        , boxCell
        , boxCell
        , td [] [ text notes ]
        ]



-- §12 REFERENCES


secRefs : List (Html msg)
secRefs =
    [ p [ style "font-size" ".85rem" ]
        [ text "A note on evidence quality: much of the autophagy literature is animal or cell work. Where a finding has "
        , emT "not"
        , text " been demonstrated in humans, that is marked. Nothing below establishes that a particular fasting schedule produces a particular health outcome in a person — the mechanisms are well characterised, the clinical translation is still thin. Archived copies of every citation live in the "
        , a [ href "/resources" ] [ text "resources archive" ]
        , text "."
        ]
    , ol [ class "refs" ]
        [ refItem "Klionsky DJ, et al. Guidelines for the use and interpretation of assays for monitoring autophagy (4th edition). " "Autophagy." " 2021;17(1):1–382. " (Just "Methods")
        , refItem "The Nobel Assembly at Karolinska Institutet. The Nobel Prize in Physiology or Medicine 2016 — Yoshinori Ohsumi, for discoveries of mechanisms for autophagy." "" "" Nothing
        , refItem "Wolfson RL, Chantranupong L, Saxton RA, et al. Sestrin2 is a leucine sensor for the mTORC1 pathway. " "Science." " 2016;351(6268):43–48. " (Just "Cell")
        , refItem "Grundler F, Mesnage R, Michalsen A, Wilhelmi de Toledo F. Blood pressure changes in 1610 subjects with and without antihypertensive medication during long-term fasting. " "J Am Heart Assoc." " 2020;9(23). " (Just "Human")
        , refItem "Wilhelmi de Toledo F, Grundler F, Bergouignan A, Drinda S, Michalsen A. Safety, health improvement and well-being during a 4 to 21-day fasting period in an observational study including 1422 subjects. " "PLoS ONE." " 2019;14(1):e0209353. " (Just "Human, observational")
        , refItem "Brandhorst S, Choi IY, Wei M, et al. A periodic diet that mimics fasting promotes multi-system regeneration, enhanced cognitive performance, and healthspan. " "Cell Metab." " 2015;22(1):86–99. " (Just "Mouse + human")
        , refItem "Wei M, Brandhorst S, Shelehchi M, et al. Fasting-mimicking diet and markers/risk factors for aging, diabetes, cancer, and cardiovascular disease. " "Sci Transl Med." " 2017;9(377):eaai8700. " (Just "Human RCT")
        , refItem "Cheng CW, Adams GB, Perin L, et al. Prolonged fasting reduces IGF-1/PKA to promote hematopoietic-stem-cell-based regeneration and reverse immunosuppression. " "Cell Stem Cell." " 2014;14(6):810–823. " (Just "Mouse + phase I")
        , refItem "Eisenberg T, Knauer H, Schauer A, et al. Induction of autophagy by spermidine promotes longevity. " "Nat Cell Biol." " 2009;11(11):1305–1314. " (Just "Yeast, fly, mouse")
        , refItem "Eisenberg T, Abdellatif M, Schroeder S, et al. Cardioprotection and lifespan extension by the natural polyamine spermidine. " "Nat Med." " 2016;22(12):1428–1438. " (Just "Mouse + epidemiology")
        , refItem "Madeo F, Eisenberg T, Pietrocola F, Kroemer G. Spermidine in health and disease. " "Science." " 2018;359(6374):eaan2788. " (Just "Review")
        , refItem "Pietrocola F, Mariño G, Lissa D, et al. Pro-autophagic polyphenols reduce the acetylation of cytoplasmic proteins. " "Cell Cycle." " 2012;11(20):3851–3860. " (Just "Cell")
        , refItem "Mehanna HM, Moledina J, Travis J. Refeeding syndrome: what it is, and how to prevent and treat it. " "BMJ." " 2008;336(7659):1495–1498. " (Just "Clinical review")
        , refItem "Pietrocola F, Malik SA, Mariño G, et al. Coffee induces autophagy in vivo. " "Cell Cycle." " 2014;13(12):1987–1994. " (Just "Mouse")
        , refItem "He C, Bassik MC, Moresi V, et al. Exercise-induced BCL2-regulated autophagy is required for muscle glucose homeostasis. " "Nature." " 2012;481(7382):511–515. " (Just "Mouse")
        , refItem "de Cabo R, Mattson MP. Effects of intermittent fasting on health, aging, and disease. " "N Engl J Med." " 2019;381(26):2541–2551. " (Just "Review")
        , refItem "Cahill GF Jr. Fuel metabolism in starvation. " "Annu Rev Nutr." " 2006;26:1–22. " (Just "Human, classic")
        , refItem "American Society of Anesthesiologists. Consensus-based guidance on preoperative management of patients (adults and children) on glucagon-like peptide-1 (GLP-1) receptor agonists. ASA; 2023. " "" "" (Just "Clinical guidance")
        , li []
            [ text "Look M, et al. Body composition changes during weight reduction with tirzepatide in the SURMOUNT-1 study of adults with obesity or overweight. "
            , i [] [ text "Diabetes Obes Metab." ]
            , text " 2025. doi:10.1111/dom.16275. "
            , i [] [ text "Note: a published correction accompanies this paper and should be read alongside it." ]
            , text " "
            , span [ class "evidence" ] [ text "Human RCT substudy" ]
            ]
        ]
    ]


refItem : String -> String -> String -> Maybe String -> Html msg
refItem before journal after evidence =
    li []
        (List.concat
            [ [ text before ]
            , if journal == "" then
                []

              else
                [ i [] [ text journal ] ]
            , if after == "" then
                []

              else
                [ text after ]
            , case evidence of
                Just tag ->
                    [ span [ class "evidence" ] [ text tag ] ]

                Nothing ->
                    []
            ]
        )
