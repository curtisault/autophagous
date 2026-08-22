module Ruler exposing (view)

{-| The 0–96 h clock the stages are drawn on.

Every left and width here is `Cycle.stages` divided by its own scale,
so the bands cannot say one thing while the stage cards say another.

Two readers, one drawing (extracted from `Page.Protocol` 2026-08-18
when the second appeared):

  - the protocol's §08, plain, marked at the 72 h minimum;
  - the planner's live clock, marked at whichever target is set and
    carrying a **needle** at the hour the reader has actually reached.

The needle is the one thing here that is not a fact about the
protocol; it is a fact about the reader, so it is drawn differently —
elapsed time as a spent band behind the stage bands, and a rule at its
edge. It never animates: it is a position, and it is simply somewhere
else the next time the minute changes (DESIGN-REQUIREMENTS §1).

-}

import Cycle
import Html exposing (Html, a, b, div, i, p, span, text)
import Html.Attributes exposing (attribute, class, classList, href, style)


{-| `now` is minutes elapsed from hour 0, or `Nothing` for the plain
ruler. Outside the drawn clock — before hour 0, or past hour 96 — there
is no needle: a needle pinned to an end would claim a position the
reader is not in.

`linkTo` is where a segment sends the reader. Both readers link, and
both link to the same place — the protocol's stage card — but they
spell it differently: `#stage-iii` on the protocol, where the card is
on the page already, and `/#stage-iii` from the planner, which is a
navigation. The planner leaving itself is the point: it is a schedule,
and the stage's content is the section it compressed
(DESIGN-PRINCIPLES §3b).

`here` is the stage the reader is standing in. **Handed in, not worked
out.** Which stage contains an hour is `Clock`'s question and it has
answered it already (`Reading.depth`); asking it again here would be
the stage boundaries read a second way, which is the whole reason
`Cycle` exists. `Nothing` on the protocol's plain ruler, and `Nothing`
on the planner's whenever the reader is not fasting — outside the
fast no stage is theirs to be in.

-}
view :
    { target : Cycle.Target
    , now : Maybe Int
    , here : Maybe Cycle.Stage
    , linkTo : Cycle.Stage -> String
    }
    -> Html msg
view config =
    let
        target =
            Cycle.targetHours config.target

        needleAt =
            config.now
                |> Maybe.andThen
                    (\minutes ->
                        if minutes >= 0 && minutes <= Cycle.hours Cycle.scaleHours then
                            Just minutes

                        else
                            Nothing
                    )
    in
    div [ class "ruler-wrap" ]
        [ div [ class "flagrow" ]
            [ span [ style "left" (pct target) ]
                [ text ("▼ " ++ String.fromInt target ++ " h — target") ]
            ]
        , div [ class "ruler" ]
            -- painting order, back to front: time already spent, the
            -- optional fourth day, the stretch priming shortens, the
            -- boundaries, the cells that name them, then the marks
            (elapsedBand needleAt
                ++ [ band "zone tint" target Cycle.scaleHours ]
                ++ List.map (\s -> band "zone hatch" s.from s.to) (openingStage Cycle.stages)
                ++ List.map divider (dividedAt target Cycle.stages)
                ++ List.map (cell config.linkTo config.here) Cycle.stages
                ++ [ div [ class "target", style "left" (pct target) ] [] ]
                ++ needle needleAt
            )
        , div [ class "ticks" ] (List.indexedMap tick ticks)
        , div [ class "names" ] (List.map name Cycle.stages)
        , div [ class "legend" ]
            (span [] [ i [ class "swatch hatched" ] [], text "Shortened by priming" ]
                :: span [] [ i [ class "swatch mark" ] [], text "Minimum target" ]
                :: span [] [ i [ class "swatch tint" ] [], text "Optional 4th day" ]
                :: legendNeedle needleAt config.here
            )
        , p [ class "u", style "font-size" ".6rem", style "margin" ".5rem 0 0" ]
            [ text "Linear scale · band width is true to duration" ]
        ]



-- THE NEEDLE


elapsedBand : Maybe Int -> List (Html msg)
elapsedBand needleAt =
    case needleAt of
        Just minutes ->
            [ div
                [ class "zone spent"
                , style "left" "0"
                , style "width" (pctOf minutes)
                ]
                []
            ]

        Nothing ->
            []


needle : Maybe Int -> List (Html msg)
needle needleAt =
    case needleAt of
        Just minutes ->
            [ div [ class "needle", style "left" (pctOf minutes) ] [] ]

        Nothing ->
            []


legendNeedle : Maybe Int -> Maybe Cycle.Stage -> List (Html msg)
legendNeedle needleAt here =
    case needleAt of
        Just minutes ->
            [ span []
                [ i [ class "swatch needle-swatch" ] []
                , text
                    ("Where you are — hour "
                        ++ String.fromInt (minutes // 60)
                        ++ (case here of
                                Just stage ->
                                    ", Stage " ++ stage.numeral

                                Nothing ->
                                    ""
                           )
                    )
                ]
            ]

        Nothing ->
            []



-- THE TRACK


{-| Hours as a position on the track. Rounded to three places: the
thirds (16 h of 96) are otherwise seventeen digits of noise in the
DOM, and a thousandth of this track is a fifth of a pixel.
-}
pct : Int -> String
pct hours =
    place (toFloat hours / toFloat Cycle.scaleHours)


{-| The same, from minutes — the needle moves within an hour.
-}
pctOf : Int -> String
pctOf minutes =
    place (toFloat minutes / toFloat (Cycle.hours Cycle.scaleHours))


place : Float -> String
place fraction =
    String.fromFloat (toFloat (round (fraction * 100000)) / 1000) ++ "%"


band : String -> Int -> Int -> Html msg
band cls from to =
    div
        [ class cls
        , style "left" (pct from)
        , style "width" (pct (to - from))
        ]
        []


{-| The stage that opens the clock — the one the hatch marks, because
it is the stretch priming shortens.
-}
openingStage : List Cycle.Stage -> List Cycle.Stage
openingStage =
    List.filter (\s -> s.from == 0)


{-| The boundaries that need a rule drawn. Not hour 0 — the ruler's own
border is that line — and not the target, where the volt mark already
is: a divider under it would be a rule nobody can see.
-}
dividedAt : Int -> List Cycle.Stage -> List Int
dividedAt target =
    List.map .from >> List.filter (\from -> from > 0 && from /= target)


divider : Int -> Html msg
divider from =
    div [ class "vdiv", style "left" (pct from) ] []


{-| A segment, and the way into the stage it draws.

The numeral alone is what the band has room for, so the name the
reader would click on is not in the accessible tree — hence the label.
It carries the numeral, the title and the hours, which is everything
the card underneath would tell them.

-}
cell : (Cycle.Stage -> String) -> Maybe Cycle.Stage -> Cycle.Stage -> Html msg
cell linkTo here s =
    let
        mine =
            here == Just s
    in
    a
        ([ class "rlbl"
         , classList [ ( "is-here", mine ) ]
         , href (linkTo s)
         , attribute "aria-label"
            ("Stage "
                ++ s.numeral
                ++ " — "
                ++ s.title
                ++ ", "
                ++ Cycle.stageHours s
                ++ (if mine then
                        " — where you are"

                    else
                        ""
                   )
            )
         , style "left" (pct s.from)
         , style "width" (pct (s.to - s.from))
         ]
            ++ (if mine then
                    -- the same word the contents rail uses for the
                    -- section you are in; it means the same thing
                    [ attribute "aria-current" "true" ]

                else
                    []
               )
        )
        [ b [] [ text s.numeral ] ]


{-| Every boundary, once: hour 0, then each stage's end.
-}
ticks : List Int
ticks =
    0 :: List.map .to Cycle.stages


tick : Int -> Int -> Html msg
tick i hours =
    div
        [ class
            (if i == 0 then
                "tick first"

             else if hours == Cycle.scaleHours then
                "tick last"

             else
                "tick"
            )
        , style "left" (pct hours)
        ]
        [ text
            (if i == 0 then
                "0h"

             else
                String.fromInt hours
            )
        ]


name : Cycle.Stage -> Html msg
name s =
    div
        [ class
            -- the narrow cells drop to a second row rather than
            -- colliding with their neighbours (protocol.css, .nm.low)
            (if s.to - s.from <= 8 then
                "nm low"

             else
                "nm"
            )
        , style "left" (pct s.from)
        , style "width" (pct (s.to - s.from))
        ]
        [ text s.label ]
