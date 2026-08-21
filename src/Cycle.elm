module Cycle exposing
    ( Entry
    , Phase
    , Span(..)
    , Stage
    , Target(..)
    , Weight(..)
    , days
    , hours
    , plan
    , scaleHours
    , stageHours
    , stages
    , targetFromParam
    , targetHours
    , targetLabel
    , targetParam
    , targets
    , window
    )

{-| The cycle as data: the stage boundaries, and the schedule the
planner dates.

**Why this module exists.** The stage boundaries (0 / 16 / 24 / 48 /
72 / 96 h) were written three times over — the stage cards, the
ruler's percentages, and now the planner. Three copies of one number
is a number that will drift, which is the same argument
DESIGN-PRINCIPLES makes about hard-coded offsets in the shell. They
live here once; `Page.Protocol` and `Page.Plan` both read them.

**The boundary.** This module is offsets and text — no `Posix`, no
`Zone`, no `Html`. Offsets are minutes from hour 0 (the end of the
last meal), negative through priming. `Page.Plan` turns them into
instants, `Ics` turns them into events, and neither can disagree with
the other about when Stage III starts.

The content is `Page.Protocol`'s, compressed to schedule length. It
never _replaces_ a protocol section — every phase carries the anchor
of the section it came from, and the planner links back to it. Safety
content is not summarised away: the thiamine order, the divided
potassium dose and the refeeding warning ride in the schedule at the
hour they apply (DESIGN-REQUIREMENTS §5).

-}

-- OFFSET HELPERS


{-| Whole hours as minutes.
-}
hours : Int -> Int
hours n =
    n * 60


{-| Whole days as minutes.
-}
days : Int -> Int
days n =
    n * 1440



-- THE TARGET


{-| How long the fast runs. The protocol's Stage V is an optional
fourth day, so the cycle has exactly two honest lengths — and every
downstream offset (the refeed, the rebuild, the next cycle) is
measured from whichever one is chosen.
-}
type Target
    = T72
    | T96


targets : List Target
targets =
    [ T72, T96 ]


targetHours : Target -> Int
targetHours target =
    case target of
        T72 ->
            72

        T96 ->
            96


targetLabel : Target -> String
targetLabel target =
    String.fromInt (targetHours target) ++ " h"


{-| The `?target=` value.
-}
targetParam : Target -> String
targetParam target =
    String.fromInt (targetHours target)


{-| An unrecognised parameter reads as the 72 h minimum, never the
extension: a shared link that has lost its query should propose the
shorter fast, not the longer one.
-}
targetFromParam : Maybe String -> Target
targetFromParam raw =
    case raw of
        Just "96" ->
            T96

        _ ->
            T72



-- THE STAGES


{-| One stage of the fast, in whole hours from hour 0. Two names: the
`label` is the ruler's, cut to fit a band 8% of a track wide; the
`title` is the stage card's and the planner's.
-}
type alias Stage =
    { numeral : String
    , from : Int
    , to : Int
    , label : String
    , title : String
    }


{-| Rev. 3, §08 "Stages, by the clock".
-}
stages : List Stage
stages =
    [ Stage "I" 0 16 "Draw-down" "Glycogen draw-down"
    , Stage "II" 16 24 "Switch" "The switch"
    , Stage "III" 24 48 "Climbing" "Climbing"
    , Stage "IV" 48 72 "Sustained" "Sustained"
    , Stage "V" 72 96 "Optional extension" "Optional extension"
    ]


{-| The full width of the clock the stages are drawn on — the ruler's
scale, and the longest fast the protocol will countenance.
-}
scaleHours : Int
scaleHours =
    List.foldl (\s acc -> max acc s.to) 0 stages


{-| A stage's span in the protocol's own notation: `16–24 h`.
-}
stageHours : Stage -> String
stageHours s =
    String.fromInt s.from ++ "–" ++ String.fromInt s.to ++ " h"



-- THE SCHEDULE


{-| A phase of the cycle, with the protocol section it is drawn from.
-}
type alias Phase =
    { num : String
    , anchor : String -- this page's section anchor
    , source : String -- the protocol section it compresses
    , title : String
    , tocLabel : String
    , duration : String
    , intent : String
    , entries : List Entry
    }


{-| One dated line. `at` is minutes from hour 0.
-}
type alias Entry =
    { at : Int
    , span : Span
    , mark : String
    , title : String
    , detail : String
    , weight : Weight
    }


{-| A point in the schedule, or a day-shaped band running to a later
offset. `Until` carries the end rather than a day count because only
the dated layer knows how many calendar days a 72-hour window touches
— a fast that starts at 20:00 crosses four dates, one that starts at
06:00 crosses three.
-}
type Span
    = Moment
    | Until Int


{-| The minutes a band covers, half-open. `Nothing` for a moment: a
point has no inside to stand in.

**A band that ends where it starts is one day long.** That is what
`Until` means for the priming days and the refeed days, where the
offset names a date rather than a stretch — `Page.Plan` already reads
them that way, rendering one date instead of a range. A band with a
genuinely later end runs to that end and no further: the fast's daily
minimum stops when the fast does, not a day after it.

The convention lives here because `Span` does. `Clock` asks whether
the reader is inside a band and must not re-derive the answer.

-}
window : Entry -> Maybe ( Int, Int )
window entry =
    case entry.span of
        Moment ->
            Nothing

        Until end ->
            Just
                ( entry.at
                , if end == entry.at then
                    entry.at + days 1

                  else
                    end
                )


{-| `Key` rows are the load-bearing ones — hour 0, the switch, the
thiamine dose, the break. They take the hero treatment in the table,
the same as the protocol's own tables.
-}
type Weight
    = Normal
    | Key


{-| The whole cycle, in reading order within each phase.
-}
plan : Target -> List Phase
plan target =
    [ priming, fast target, refeed target, rebuild target ]



-- PHASE 1


priming : Phase
priming =
    { num = "Phase 1"
    , anchor = "sec-prime"
    , source = "/#sec-prime"
    , title = "Priming"
    , tocLabel = "Priming"
    , duration = "3 d"
    , intent = "Arrive already switched"
    , entries =
        [ { at = days -3
          , span = Until (days -3)
          , mark = "D−3"
          , title = "Go low-carbohydrate"
          , detail = "Under ~50 g/day, moderate protein, generous fat. Zero alcohol from here: it depletes the thiamine you need intact for the refeed."
          , weight = Normal
          }
        , { at = days -2
          , span = Until (days -2)
          , mark = "D−2"
          , title = "Load the inducers"
          , detail = "Spermidine — wheat germ, natto, aged cheese, mushrooms, legumes, broccoli. Polyphenols — green tea, coffee, extra-virgin olive oil, berries, dark chocolate."
          , weight = Normal
          }
        , { at = days -1
          , span = Until (days -1)
          , mark = "D−1"
          , title = "Taper protein, start salting"
          , detail = "Keep the last day's protein light: no large steak, no shake, no leucine-heavy final meal. Extra sodium through the final 24 hours, ahead of the natriuresis rather than chasing it."
          , weight = Normal
          }
        ]
    }



-- PHASE 2


fast : Target -> Phase
fast target =
    { num = "Phase 2"
    , anchor = "sec-fast"
    , source = "/#sec-fast"
    , title = "The fast"
    , tocLabel = "The fast"
    , duration = targetLabel target
    , intent = "Electrolytes in · calories out"
    , entries = hourZero :: dailyMinimum target :: crossings target
    }


hourZero : Entry
hourZero =
    { at = 0
    , span = Moment
    , mark = "0 h"
    , title = "Hour 0 — the last meal ends"
    , detail = "The clock starts when you finish eating, not when you wake up. Stage I is glycogen draw-down; priming has already spent most of it."
    , weight = Key
    }


dailyMinimum : Target -> Entry
dailyMinimum target =
    { at = 0
    , span = Until (hours (targetHours target))
    , mark = "Daily"
    , title = "Mandatory every day of the fast"
    , detail = "Sodium 3,000–5,000 mg · potassium 1,000–3,000 mg in small divided doses, never one large dose · magnesium 300–500 mg at night · thiamine 50–100 mg · 2–3 L of salted water. Black coffee is recommended, not merely permitted. Easy walking 30–60 min on days 1–2, tapering after; no hard training."
    , weight = Key
    }


{-| A stage boundary is worth dating only if the fast actually reaches
it: at the 72 h target, Stage V's crossing never arrives, and a
calendar that announced it would be lying about the plan.
-}
crossings : Target -> List Entry
crossings target =
    stages
        |> List.filter (\s -> s.from > 0 && s.from < targetHours target)
        |> List.map crossing


crossing : Stage -> Entry
crossing s =
    { at = hours s.from
    , span = Moment
    , mark = String.fromInt s.from ++ " h"
    , title = "Stage " ++ s.numeral ++ " — " ++ String.toLower s.title
    , detail = stageDetail s.numeral
    , weight =
        if s.numeral == "II" then
            Key

        else
            Normal
    }


stageDetail : String -> String
stageDetail numeral =
    case numeral of
        "II" ->
            "Glycogen runs out. mTORC1 goes quiet, AMPK activates — autophagic upregulation begins here, not at hour 72. The worst stretch: hunger waves, irritability, headache. Salt now."

        "III" ->
            "Ketones climb from roughly 0.5 toward 2–3 mmol/L and IGF-1 reaches its floor. Sustained induction; every hour here is doing work. Hunger usually fades around hour 36–48, often abruptly."

        "IV" ->
            "Deep ketosis, near-exclusive fat oxidation, protein sparing engaged. The plateau you came for. Weaker, cold, low stamina: stand up slowly every time, keep the room warm, no saunas or hot baths."

        "V" ->
            "A steady state; little changes mechanistically. Take this day only if the fast has gone smoothly and you are experienced. Past roughly day five the refeeding risk climbs steeply while the mechanistic case flattens."

        _ ->
            ""



-- PHASE 3


refeed : Target -> Phase
refeed target =
    let
        t =
            hours (targetHours target)
    in
    { num = "Phase 3"
    , anchor = "sec-refeed"
    , source = "/#sec-refeed"
    , title = "The refeed"
    , tocLabel = "The refeed"
    , duration = "2 d"
    , intent = "The dangerous 48 hours"
    , entries =
        [ { at = t - 30
          , span = Moment
          , mark = "First"
          , title = "Thiamine, before any food"
          , detail = "50–100 mg, before the first bite — not after. Thiamine is consumed as carbohydrate metabolism restarts, and deficiency at this moment is the mechanism behind the worst refeeding outcomes."
          , weight = Key
          }
        , { at = t
          , span = Moment
          , mark = targetLabel target
          , title = "Break the fast"
          , detail = "A small portion of cooked vegetables, or vegetable broth with olive oil. Tiny — half of what looks reasonable. Clear liquids only for the first 6–8 hours."
          , weight = Key
          }
        , { at = t + hours 3
          , span = Moment
          , mark = "+3 h"
          , title = "First protein"
          , detail = "Eggs, fish, or soft-cooked meat, modest portion. This is the anabolic signal that starts the rebuild, so it belongs here — just not first and not large."
          , weight = Normal
          }
        , { at = t
          , span = Until t
          , mark = "Day 1"
          , title = "Liquid and pureed textures only"
          , detail = "Very small volumes, frequently: a quarter of what seems reasonable, every 2–3 hours. Stay upright for an hour after eating. Solids are what get retained."
          , weight = Normal
          }
        , { at = t + days 1
          , span = Until (t + days 1)
          , mark = "Day 2"
          , title = "Normal meals, carbohydrate last"
          , detail = "Reintroduce starch, fruit and sugar last, and keep carbohydrate deliberately low through the first 24–48 hours. Keep magnesium and potassium going — the requirement goes up, not down, as insulin returns."
          , weight = Normal
          }
        ]
    }



-- PHASE 4


rebuild : Target -> Phase
rebuild target =
    let
        t =
            hours (targetHours target)
    in
    { num = "Phase 4"
    , anchor = "sec-rebuild"
    , source = "/#sec-rebuild"
    , title = "The rebuild"
    , tocLabel = "The rebuild"
    , duration = "~3 wk"
    , intent = "Three weeks of construction"
    , entries =
        [ { at = t + days 1
          , span = Until (t + days 22)
          , mark = "3 wk"
          , title = "The rebuild window"
          , detail = "Roughly 1.2–1.6 g of protein per kg bodyweight daily, and sleep. Fasting cleared damaged components; this window replaces them, and wasting it undoes much of the point."
          , weight = Key
          }
        , { at = t + days 2
          , span = Until (t + days 2)
          , mark = "+2 d"
          , title = "First resistance session"
          , detail = "Start within 2–3 days of refeeding, then 2–3 sessions weekly. Without a mechanical stimulus the returning anabolic signal is untargeted — nothing sends it into muscle rather than fat."
          , weight = Normal
          }
        , { at = days 28
          , span = Until (days 28)
          , mark = "Next"
          , title = "Earliest next hour 0"
          , detail = "Monthly cadence: this is hour 0 of the next cycle, so its priming starts three days before this date. Cycles are never stacked back to back — more cumulative cycles beats one heroic effort."
          , weight = Normal
          }
        ]
    }
