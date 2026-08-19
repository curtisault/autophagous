module Page.Dosing exposing (Context, view)

{-| §07's daily requirements, converted into things you can measure.

The protocol states what has to go in: sodium 3,000–5,000 mg,
potassium 1,000–3,000 mg, and so on. What a reader actually handles is
a spoon, a scale and a glass of water — and the conversion between the
two is where a fast goes wrong quietly. Two mistakes in particular:

  - **A "lite salt" is half table salt.** §07's "⅓–1 tsp" is the
    figure for pure potassium chloride; a teaspoon of a 50/50 blend
    carries barely half the potassium — and brings sodium with it,
    which has to come off the salt you were also going to add.
  - **A day's potassium is not a dose.** It is several, and the
    protocol is unambiguous about why.

Pure view. The arithmetic is `Dose`, which invents nothing: every
target here is §07's, and the warnings are §07's own values through
`Safety` rather than a summary of them (DESIGN-PRINCIPLES §3b).

-}

import Doc
import Dose exposing (Range, Source(..))
import Html exposing (Html, a, b, button, div, p, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (attribute, class, classList, href, style, type_)
import Html.Events exposing (onClick)
import Safety


type alias Context msg =
    { source : Source
    , servings : Int
    , chrome : Doc.Chrome msg
    , onSource : Source -> msg
    , onServings : Int -> msg
    }


view : Context msg -> Html msg
view ctx =
    Doc.view
        { tag = "Electrolytes"
        , kicker = "§07 converted · per day and per dose"
        , rev = "Rev. 3"
        , revDate = "2026-08-18"
        , titleLines = [ "What goes", "in the water" ]
        , standfirst = "The protocol asks for milligrams of an element. A kitchen has grams of a salt and a spoon of uncertain size. This converts the one into the other, states every constant it uses, and divides the day the way §07 requires."
        , sections =
            [ { anchor = "sec-dose-set"
              , tocLabel = "Your salts"
              , title = "What you are working with"
              , intent = "Where your potassium comes from"
              , body = Doc.Clauses (secSet ctx)
              }
            , { anchor = "sec-dose-day"
              , tocLabel = "Per day"
              , title = "Every day of the fast"
              , intent = "§07's targets, weighed"
              , body = Doc.Panel (secDay ctx)
              }
            , { anchor = "sec-dose-each"
              , tocLabel = "Per dose"
              , title = "Divided across the day"
              , intent = String.fromInt ctx.servings ++ " doses"
              , body = Doc.Panel (secEach ctx)
              }
            , { anchor = "sec-dose-avoid"
              , tocLabel = "What not to use"
              , title = "What not to reach for"
              , intent = "Excluded · and why"
              , body = Doc.Panel (secAvoid ctx)
              }
            , { anchor = "sec-dose-working"
              , tocLabel = "The working"
              , title = "What these numbers assume"
              , intent = "Constants · rounding"
              , body = Doc.Clauses (secWorking ctx)
              }
            ]
        , chrome = ctx.chrome
        , footNote =
            -- the medical disclaimer ships on every content page
            -- (DESIGN-REQUIREMENTS §5)
            [ p [ style "margin" "0 0 .4rem" ]
                [ b [] [ text "This is general information, not medical advice, and I'm not a doctor." ]
                , text " Prolonged fasting carries real risk that varies enormously with your individual health, medications and history. Talk to a physician before your first cycle. Full "
                , a [ href "/legal" ] [ text "terms and disclaimers" ]
                , text "."
                ]
            , p [ style "margin" "0" ]
                [ text "This sheet converts "
                , a [ href "/#sec-fast" ] [ text "§07, the fast" ]
                , text ". It adds no dose the protocol does not ask for, and it is not a substitute for reading that section."
                ]
            ]
        }



-- §01 WHAT YOU ARE WORKING WITH


secSet : Context msg -> List (Html msg)
secSet ctx =
    [ div [ class "plan-set" ]
        [ div [ class "plan-field" ]
            [ span [ class "u" ] [ text "Your potassium" ]
            , div
                [ class "plan-seg"
                , attribute "role" "group"
                , attribute "aria-label" "Potassium source"
                ]
                (List.map (sourceButton ctx) Dose.sources)
            ]
        ]
    , Safety.potassiumDose
    , div [ class "note" ] Safety.saltedWater
    , p []
        [ b [] [ text "Check the label before you trust the left-hand column." ]
        , text " Products sold as \u{201C}lite salt,\u{201D} \u{201C}low-sodium salt\u{201D} or \u{201C}salt substitute\u{201D} are usually a 50/50 blend of table salt and potassium chloride; products sold as \u{201C}NoSalt\u{201D} or \u{201C}Nu-Salt\u{201D} are usually the pure chloride. §07's "
        , span [ class "mono" ] [ text "⅓–1 tsp" ]
        , text " is the figure for the pure salt: a teaspoon of a blend carries barely half as much potassium, and brings sodium with it."
        ]
    , p []
        [ b [] [ text "Only three things are on that list for a reason." ]
        , text " Liquid I.V., a sports drink, coconut water and bone broth are the four people usually reach for instead, and §07 excludes all of them — "
        , a [ href "#sec-dose-avoid" ] [ text "with the arithmetic" ]
        , text "."
        ]
    ]


sourceButton : Context msg -> Source -> Html msg
sourceButton ctx source =
    button
        [ type_ "button"
        , class "plan-btn u"
        , classList [ ( "active", source == ctx.source ) ]
        , attribute "aria-pressed" (ariaBool (source == ctx.source))
        , onClick (ctx.onSource source)
        ]
        [ text (Dose.sourceLabel source) ]


servingButton : Context msg -> Int -> Html msg
servingButton ctx n =
    button
        [ type_ "button"
        , class "plan-btn u mono"
        , classList [ ( "active", n == ctx.servings ) ]
        , attribute "aria-pressed" (ariaBool (n == ctx.servings))
        , onClick (ctx.onServings n)
        ]
        [ text (String.fromInt n) ]


ariaBool : Bool -> String
ariaBool yes =
    if yes then
        "true"

    else
        "false"



-- §02 EVERY DAY


secDay : Context msg -> List (Html msg)
secDay ctx =
    let
        s =
            Dose.sheet ctx.source
    in
    [ table [ class "plan dose" ]
        [ headRow "Per day" "Low end" "High end"
        , tbody []
            (saltRows ctx s
                ++ [ row False
                        "Magnesium"
                        (Dose.milligrams Dose.magnesium.low)
                        (Dose.milligrams Dose.magnesium.high)
                        "Glycinate or malate, taken at night — a single dose, not divided. Citrate works but loosens the bowels."
                   , row True
                        "Thiamine (B1)"
                        (Dose.milligrams Dose.thiamine.low)
                        (Dose.milligrams Dose.thiamine.high)
                        "Your refeeding insurance. Take it daily through the fast, and again before the first bite when you break it."
                   , row False
                        "Water"
                        (Dose.litres Dose.water.low)
                        (Dose.litres Dose.water.high)
                        "Salted, and to thirst. Volume for its own sake is the hyponatremia risk above."
                   ]
            )
        ]
    , div [ class "note" ]
        [ b [] [ text "A day is a day." ]
        , text " Nothing in this table changes with how many doses you divide it into — that is the next section. What changes here is where your potassium comes from."
        ]
    , sourceLine
    ]


{-| The two rows the source changes. Potassium excluded is not a blank
row: it is the exclusion, in words, where the dose would have been.
-}
saltRows : Context msg -> Dose.Sheet -> List (Html msg)
saltRows ctx s =
    case ctx.source of
        Excluded ->
            [ weighed True "Sodium" "Na" s.sodium s.fineSalt Dose.gramsPerTspSalt "As fine salt. Nothing else here carries sodium, so all of it comes from the spoon."
            , tr []
                [ td [] [ span [ class "plan-t" ] [ text "Potassium" ] ]
                , td [ class "mono" ] [ text "—" ]
                , td [ class "mono" ] [ text "—" ]
                , td []
                    [ b [] [ text "Excluded, on the protocol's own instruction." ]
                    , text " §07 says to skip potassium supplementation entirely with any kidney impairment, or on ACE inhibitors, ARBs or potassium-sparing diuretics. This sheet will not convert a dose it has been told not to give."
                    ]
                ]
            ]

        Kcl ->
            [ weighed True "Sodium" "Na" s.sodium s.fineSalt Dose.gramsPerTspSalt "As fine salt, divided across the day in water."
            , weighed True "Potassium" "K" s.potassium s.kcl Dose.gramsPerTspKcl "As pure potassium chloride. Divided into small doses — never one."
            ]

        Lite ->
            [ weighed True "Potassium" "K" s.potassium s.liteSalt Dose.gramsPerTspLite "As 50/50 lite salt. Roughly twice the spoonfuls the pure chloride would need, because half of what you are measuring is table salt."
            , weighed True
                "Sodium"
                "Na"
                s.sodium
                s.fineSalt
                Dose.gramsPerTspSalt
                "As fine salt — on top of what the lite salt already brought. That is why this number is smaller than it would be otherwise: the lite salt is doing part of the salting."
            ]


{-| A row that reports both the element §07 asked for and the salt you
weigh to deliver it — the milligrams so the conversion can be checked
against the protocol, the grams so it can be acted on.
-}
weighed : Bool -> String -> String -> Range -> Range -> Float -> String -> Html msg
weighed hero label symbol element salt perTsp note =
    tr [ classList [ ( "hero", hero ) ] ]
        [ td [] [ span [ class "plan-t" ] [ text label ] ]
        , td [ class "mono" ] [ amount symbol element.low salt.low perTsp ]
        , td [ class "mono" ] [ amount symbol element.high salt.high perTsp ]
        , td [] [ text note ]
        ]


{-| A stick count, with the potassium it delivers above it.
-}
stickCell : Float -> Float -> Html msg
stickCell potassiumMg count =
    span []
        [ span [ class "dose-mg" ] [ text (Dose.milligrams potassiumMg ++ " K") ]
        , span [ class "dose-g" ] [ text (Dose.sticks count) ]
        ]


{-| What those sticks cost, which is the whole answer to whether they
belong in a fast.
-}
sugarCell : Float -> Html msg
sugarCell count =
    span []
        [ span [ class "dose-mg" ]
            [ text (Dose.grams (count * Dose.stickSugar) ++ " sugar") ]
        , span [ class "dose-g" ]
            [ text (String.fromInt (round (count * Dose.stickCalories)) ++ " kcal") ]
        ]


{-| The three answers to "how much": the element §07 asked for, the
salt you weigh, the spoon you have. The element is named on every
figure — a row headed "Fine salt" showing "1,000 mg" would otherwise
read as a gram of salt rather than a gram of sodium.
-}
amount : String -> Float -> Float -> Float -> Html msg
amount symbol elementMg saltGrams perTsp =
    span []
        [ span [ class "dose-mg" ] [ text (Dose.milligrams elementMg ++ " " ++ symbol) ]
        , span [ class "dose-g" ] [ text (Dose.grams saltGrams) ]
        , span [ class "dose-tsp" ] [ text (Dose.teaspoons (saltGrams / perTsp)) ]
        ]


headRow : String -> String -> String -> Html msg
headRow first low high =
    thead []
        [ tr []
            [ th [ style "width" "16%" ] [ text first ]
            , th [ style "width" "20%" ] [ text low ]
            , th [ style "width" "20%" ] [ text high ]
            , th [] [ text "Notes" ]
            ]
        ]


row : Bool -> String -> String -> String -> String -> Html msg
row hero label low high note =
    tr [ classList [ ( "hero", hero ) ] ]
        [ td [] [ span [ class "plan-t" ] [ text label ] ]
        , td [ class "mono" ] [ text low ]
        , td [ class "mono" ] [ text high ]
        , td [] [ text note ]
        ]


assumption : String -> String -> String -> Html msg
assumption label value source =
    tr []
        [ td [] [ span [ class "plan-t" ] [ text label ] ]
        , td [ class "mono" ] [ text value ]
        , td [] [ text source ]
        ]


sourceLine : Html msg
sourceLine =
    p [ class "plan-source u" ]
        [ a [ href "/#sec-fast" ] [ text "§07, the fast — the targets these convert" ] ]



-- §03 DIVIDED


secEach : Context msg -> List (Html msg)
secEach ctx =
    let
        each =
            Dose.perServing ctx.servings (Dose.sheet ctx.source)
    in
    [ div [ class "plan-set" ]
        [ div [ class "plan-field" ]
            [ span [ class "u" ] [ text "Doses across the day" ]
            , div
                [ class "plan-seg"
                , attribute "role" "group"
                , attribute "aria-label" "Doses per day"
                ]
                (List.map (servingButton ctx) (List.range Dose.minServings 6))
            ]
        ]
    , p [ class "lede" ]
        [ text ("One of " ++ String.fromInt ctx.servings ++ " doses, taken across the waking day, each stirred into water.") ]
    , table [ class "plan dose" ]
        [ headRow "Per dose" "Low end" "High end"
        , tbody []
            (eachRows ctx each
                ++ [ row False
                        "Water"
                        (Dose.millilitres each.water.low)
                        (Dose.millilitres each.water.high)
                        "Roughly. Drink to thirst, and keep the salt with the water rather than chasing a volume."
                   ]
            )
        ]
    , p [ class "plan-source u" ]
        [ a [ href "/plan" ] [ text "The planner — which days these apply to" ] ]
    ]


eachRows : Context msg -> Dose.Sheet -> List (Html msg)
eachRows ctx each =
    case ctx.source of
        Excluded ->
            [ weighed True "Fine salt" "Na" each.sodium each.fineSalt Dose.gramsPerTspSalt "" ]

        Kcl ->
            [ weighed True "Fine salt" "Na" each.sodium each.fineSalt Dose.gramsPerTspSalt ""
            , weighed True "Potassium chloride" "K" each.potassium each.kcl Dose.gramsPerTspKcl ""
            ]

        Lite ->
            [ weighed True "Lite salt" "K" each.potassium each.liteSalt Dose.gramsPerTspLite ""
            , weighed True "Fine salt" "Na" each.sodium each.fineSalt Dose.gramsPerTspSalt ""
            ]



-- §04 WHAT NOT TO REACH FOR


{-| The four things people reach for instead, and the §07 clause each
one breaks.

Leaving these off the page would not stop anyone using them; it would
only mean they never saw the arithmetic. So the stick mix is costed
out in full — the constants are in `Dose` and tested — and the rest
are named with the mechanism that rules them out, which is the part
that generalises to whatever is on the shelf next year.

-}
secAvoid : Context msg -> List (Html msg)
secAvoid _ =
    [ p [ class "lede" ]
        [ text "Every one of these carries real electrolytes. That is exactly why they are worth naming: the electrolytes are not the problem." ]
    , table [ class "plan" ]
        [ thead []
            [ tr []
                [ th [ style "width" "22%" ] [ text "What people reach for" ]
                , th [ style "width" "34%" ] [ text "What it brings" ]
                , th [] [ text "Why it is out" ]
                ]
            ]
        , tbody []
            [ tr [ class "hero" ]
                [ td [] [ span [ class "plan-t" ] [ text "Liquid I.V. and other stick mixes" ] ]
                , td []
                    [ text "Per stick: "
                    , span [ class "mono" ] [ text (Dose.milligrams Dose.stickSodium ++ " Na") ]
                    , text ", "
                    , span [ class "mono" ] [ text (Dose.milligrams Dose.stickPotassium ++ " K") ]
                    , text " — and "
                    , span [ class "mono" ] [ text (Dose.grams Dose.stickSugar) ]
                    , text " of sugar. §07's daily potassium would take "
                    , span [ class "mono" ] [ text (stickRange ++ " sticks") ]
                    , text ": "
                    , b [] [ text (sugarRange ++ " of sugar") ]
                    , text ", "
                    , span [ class "mono" ] [ text calorieRange ]
                    , text "."
                    ]
                , td []
                    [ text "§07 excludes anything with calories. There is no dose of this compatible with the fast — but it is a reasonable thing to drink during the "
                    , a [ href "/#sec-refeed" ] [ text "refeed" ]
                    , text ", when carbohydrate is coming back anyway and §09 asks you to keep potassium going."
                    ]
                ]
            , tr []
                [ td [] [ span [ class "plan-t" ] [ text "Sports drinks" ] ]
                , td [] [ text "Sugar in the same range as a stick mix, and less sodium than you would guess — a large bottle carries under half of what a quarter-teaspoon of salt does." ]
                , td [] [ text "Same clause, same reason. It is a rehydration drink built for someone still eating." ]
                ]
            , tr []
                [ td [] [ span [ class "plan-t" ] [ text "Coconut water" ] ]
                , td [] [ text "Genuinely high in potassium, and almost no sodium — which is backwards. Sodium is what a fast actually strips out, through the natriuresis §07 describes." ]
                , td [] [ text "Sugar, so the same clause; and it does not solve the shortfall you have." ]
                ]
            , tr [ class "hero" ]
                [ td [] [ span [ class "plan-t" ] [ text "Bone broth" ] ]
                , td [] [ text "Sodium, and amino acids with it. This is the one people reach for believing it is the fasting-safe option." ]
                , td []
                    [ text "§07 names it first among the exclusions: "
                    , b [] [ text "standard fasting advice, wrong for this goal" ]
                    , text ". Amino acids are what mTORC1 is listening for, so this breaks the target the fast exists to hit — not the calorie rule, the mechanism itself."
                    ]
                ]
            , tr []
                [ td [] [ span [ class "plan-t" ] [ text "Zero-sugar sweetened sticks" ] ]
                , td [] [ text "The right electrolyte profile and no calories at all. This is the closest call on the list, and worth stating plainly rather than lumping in with the rest." ]
                , td [] [ text "§07 excludes sweeteners and gum for the cephalic-phase insulin response — a sweet taste with no sugar behind it still asks the pancreas a question. The mechanism is less certain than the calorie rule; the protocol takes the conservative side and so does this sheet." ]
                ]
            ]
        ]
    , div [ class "note" ]
        [ b [] [ text "Figures other than the stick mix are approximate." ]
        , text " They are label values from memory of the category, not a measurement, and formulations change. The stick numbers are computed from the constants in §05 and hold to whatever label you put in. What does not change is the clause each one breaks."
        ]
    , p [ class "plan-source u" ]
        [ a [ href "/#sec-fast" ] [ text "§07 — the exclusions in full" ] ]
    ]


{-| Sticks needed for §07's potassium range, and what they cost.
-}
stickRange : String
stickRange =
    round1 (Dose.sticksFor Dose.potassium.low) ++ "–" ++ round1 (Dose.sticksFor Dose.potassium.high)


sugarRange : String
sugarRange =
    round0 (Dose.sticksFor Dose.potassium.low * Dose.stickSugar)
        ++ "–"
        ++ round0 (Dose.sticksFor Dose.potassium.high * Dose.stickSugar)
        ++ " g"


calorieRange : String
calorieRange =
    round0 (Dose.sticksFor Dose.potassium.low * Dose.stickCalories)
        ++ "–"
        ++ round0 (Dose.sticksFor Dose.potassium.high * Dose.stickCalories)
        ++ " kcal"


round0 : Float -> String
round0 =
    round >> String.fromInt


round1 : Float -> String
round1 value =
    let
        tenths =
            round (value * 10)
    in
    String.fromInt (tenths // 10) ++ "." ++ String.fromInt (modBy 10 tenths)



-- §05 THE WORKING


secWorking : Context msg -> List (Html msg)
secWorking ctx =
    [ p []
        [ text "Nothing here is a dose this sheet chose. §07 states the targets; these are the two arithmetic facts and one measurement convention that turn them into grams." ]
    , table []
        [ thead []
            [ tr []
                [ th [ style "width" "34%" ] [ text "Assumption" ]
                , th [ style "width" "16%" ] [ text "Value" ]
                , th [] [ text "Where it comes from" ]
                ]
            ]
        , tbody []
            [ assumption "Sodium in table salt" "39.34%" "Na 22.99 ÷ NaCl 58.44. Arithmetic, not advice."
            , assumption "Potassium in potassium chloride" "52.45%" "K 39.10 ÷ KCl 74.55."
            , assumption "A level teaspoon of fine salt" (Dose.grams Dose.gramsPerTspSalt) "Chosen so that §07's 3,000–5,000 mg comes out at its own stated 1¼–2 tsp. A spoon is a rough instrument; a scale is not."
            , assumption "A level teaspoon of potassium chloride" (Dose.grams Dose.gramsPerTspKcl) "Chosen the same way, against §07's ⅓–1 tsp."
            , assumption "A lite salt" "50/50" "Table salt and potassium chloride by mass — the usual blend. Read your label; if it says something else, the left-hand column is wrong for you."
            ]
        ]
    , div [ class "note" ]
        [ b [] [ text "The low and high columns move together." ]
        , text " The low column is the bottom of every one of §07's ranges and the high column the top of every one. They describe two different days — do not take the top of the potassium range with the bottom of the sodium range because each looked reasonable on its own."
        ]
    , div [ class "note" ]
        [ b [] [ text "Three doses is this sheet's floor, not the protocol's." ]
        , text " §07 requires potassium \u{201C}divided into small doses across the day\u{201D} and gives no number. Fewer than three is not a day divided, and a single large dose is the failure mode the warning above names — so the control starts at three. It is a judgement, and it is stated rather than passed off as the source's."
        ]
    , Safety.abortSignals (Just "/#sec-safety")
    ]
