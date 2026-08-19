module Safety exposing (abortSignals, potassiumDose, saltedWater)

{-| Safety content that more than one surface has to carry.

The rule for derived surfaces (DESIGN-PRINCIPLES §3b) is that they
link to safety sections rather than paraphrasing them — a summarised
contraindication is a way of missing one. The live clock is the one
place that rule needs an exception, and this module is how it gets one
**without** paraphrasing: the abort signals are not restated for the
clock, they are the same values, rendered in both places.

A reader at hour 41 with a spreading numbness is not going to follow a
link. That is exactly the reader these eight lines exist for, so they
appear on the clock in full, at body legibility, never behind an
interaction (DESIGN-REQUIREMENTS §5).

Anything added here is added to every surface that renders it. That is
the point; it is also the thing to think about before adding.

-}

import Html exposing (Html, a, b, div, li, p, text, ul)
import Html.Attributes exposing (class, href)


{-| Rev. 3, §03 — "Break the fast immediately if". Rendered by
`Page.Protocol` in the safety section and by `Page.Plan` on the live
clock.

`source` is where a reader should go for the rest of the section; the
protocol renders it without one, being already there.

-}
abortSignals : Maybe String -> Html msg
abortSignals source =
    div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Break the fast immediately if" ]
        , div [ class "cols" ]
            [ tightList
                [ "Heart palpitations or irregular heartbeat"
                , "Chest pain"
                , "Fainting, or near-fainting that doesn't resolve on sitting"
                , "Confusion, slurred speech, or disorientation"
                ]
            , tightList
                [ "Persistent vomiting, or you can't keep water down"
                , "Visual disturbance"
                , "Severe weakness — can't climb stairs"
                , "Numbness or tingling that spreads"
                ]
            ]
        , p [ class "slab-foot" ]
            (text "None of these are \u{201C}push through\u{201D} symptoms. Eat something, salt it, and reassess. A cycle abandoned early costs you almost nothing; you have another one next month."
                :: (case source of
                        Just href_ ->
                            [ text " ", a [ href href_ ] [ text "The full safety section" ], text "." ]

                        Nothing ->
                            []
                   )
            )
        ]


tightList : List String -> Html msg
tightList items =
    ul [ class "tight" ] (List.map (\item -> li [] [ text item ]) items)


{-| Rev. 3, §07 — the potassium warning. Rendered by `Page.Protocol`
in the fast's requirements and by `Page.Dosing`, which converts the
dose this warning is about and therefore cannot be read without it.

"The one item here with a genuinely narrow margin" is the protocol's
own assessment, and it is the reason the dosing sheet will not divide
a day into fewer than three.

-}
potassiumDose : Html msg
potassiumDose =
    div [ class "note" ]
        [ b [] [ text "Potassium warning." ]
        , text " Never take potassium as a single large dose — it can trigger arrhythmia. Divide it across the day in water. Skip potassium supplementation entirely if you have any kidney impairment or take ACE inhibitors, ARBs, or potassium-sparing diuretics. This is the one item here with a genuinely narrow margin."
        ]


{-| Rev. 3, §07 — why the water is salted. An inline fragment rather
than a block, because in the protocol it lives inside a table cell.
-}
saltedWater : List (Html msg)
saltedWater =
    [ b [] [ text "Salted." ]
    , text " Drinking large volumes of plain water while sodium-depleted causes hyponatremia. Thirst plus salt, not volume for its own sake."
    ]
