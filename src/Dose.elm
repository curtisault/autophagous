module Dose exposing
    ( Range
    , Sheet
    , Source(..)
    , clampServings
    , grams
    , gramsPerTspKcl
    , gramsPerTspLite
    , gramsPerTspSalt
    , litePotassiumFraction
    , litres
    , magnesium
    , maxServings
    , milligrams
    , millilitres
    , minServings
    , perServing
    , potassium
    , potassiumInKcl
    , servingsFromParam
    , sheet
    , sodium
    , sodiumInSalt
    , sourceFromParam
    , sourceLabel
    , sourceParam
    , sources
    , stickCalories
    , stickPotassium
    , stickSodium
    , stickSugar
    , sticks
    , sticksFor
    , teaspoons
    , thiamine
    , water
    )

{-| §07's daily requirements, converted into things you can measure.

**This module invents no doses.** Every target is `Page.Protocol`
§07's, unchanged; all this does is unit conversion — milligrams of an
element into grams of the salt that carries it, and a day's total into
the divided doses the protocol requires. If a number here disagrees
with §07, this module is wrong.

**Ranges move together.** §07 states ranges, not points, so the sheet
reports ranges — but the low column is the low end of _every_ range
and the high column the high end of every one. You do not mix the top
of the potassium range with the bottom of the sodium range: those are
two different days, and interval arithmetic across independent choices
would produce a spread wide enough to be useless.

**The teaspoon masses are derived, not looked up.** 6.0 g of fine salt
and 5.7 g of potassium chloride per level teaspoon are the values that
reproduce §07's own "1¼–2 tsp" and "⅓–1 tsp" — so the sheet cannot
contradict the section it converts. `DoseTests` holds them to it.

-}


{-| Both ends of one of §07's stated ranges.
-}
type alias Range =
    { low : Float, high : Float }


{-| Milligrams per day, from §07's mandatory table.
-}
sodium : Range
sodium =
    Range 3000 5000


potassium : Range
potassium =
    Range 1000 3000


magnesium : Range
magnesium =
    Range 300 500


thiamine : Range
thiamine =
    Range 50 100


{-| Litres per day. Salted — see the hyponatremia warning, which is
not optional reading (`Safety.saltedWater`).
-}
water : Range
water =
    Range 2 3



-- CONSTANTS


{-| Sodium is 39.34% of sodium chloride by mass (Na 22.99 / NaCl
58.44), potassium 52.45% of potassium chloride (K 39.10 / KCl 74.55).
These are the only two facts here that come from outside the protocol,
and they are arithmetic, not advice.
-}
sodiumInSalt : Float
sodiumInSalt =
    0.3934


potassiumInKcl : Float
potassiumInKcl =
    0.5245


{-| Grams in a level teaspoon. Chosen to reproduce §07's own teaspoon
figures — see the module note.
-}
gramsPerTspSalt : Float
gramsPerTspSalt =
    6.0


gramsPerTspKcl : Float
gramsPerTspKcl =
    5.7


{-| A 50/50 blend, so a teaspoon of it weighs between the two.
-}
gramsPerTspLite : Float
gramsPerTspLite =
    (gramsPerTspSalt + gramsPerTspKcl) / 2


{-| How much of a "lite salt" is potassium chloride. The rest is
ordinary table salt, which is the whole reason this module tracks the
distinction: a teaspoon of it carries barely half the potassium a
teaspoon of potassium chloride does, and §07's "⅓–1 tsp" is the
figure for the pure salt.
-}
litePotassiumFraction : Float
litePotassiumFraction =
    0.5


{-| One stick of Liquid I.V. Hydration Multiplier, from the label.

Formulations change and the sugar-free line differs; a reader should
check the packet in front of them. Any stick mix can be read through
these four numbers.

-}
stickSodium : Float
stickSodium =
    500


stickPotassium : Float
stickPotassium =
    370


{-| Grams of sugar per stick — **the number that decides it.**

§07 excludes "anything with calories, including 'just a splash'" and
sweeteners along with it, so a stick mix is not a fasting electrolyte
at any dose. It is not one of the `Source` options for that reason;
these constants exist so the page can show what reaching for one
would actually cost, which is a better answer than silence.

-}
stickSugar : Float
stickSugar =
    11


stickCalories : Float
stickCalories =
    45



-- WHERE THE POTASSIUM COMES FROM


type Source
    = -- pure potassium chloride: "NoSalt", "Nu-Salt", bulk KCl
      Kcl
      -- a 50/50 blend with table salt: "lite salt", "low-sodium salt"
    | Lite
      -- not taking it at all. §07: skip potassium supplementation
      -- entirely with any kidney impairment, or on ACE inhibitors,
      -- ARBs or potassium-sparing diuretics
    | Excluded


sources : List Source
sources =
    [ Kcl, Lite, Excluded ]


sourceLabel : Source -> String
sourceLabel source =
    case source of
        Kcl ->
            "Potassium chloride"

        Lite ->
            "50/50 lite salt"

        Excluded ->
            "Not taking it"


sourceParam : Source -> String
sourceParam source =
    case source of
        Kcl ->
            "kcl"

        Lite ->
            "lite"

        Excluded ->
            "none"


{-| An unreadable parameter reads as the pure salt — the case §07's
own teaspoon figures describe.
-}
sourceFromParam : Maybe String -> Source
sourceFromParam raw =
    case raw of
        Just "lite" ->
            Lite

        Just "none" ->
            Excluded

        _ ->
            Kcl



-- HOW MANY DOSES


{-| §07 requires potassium "divided into small doses across the day"
and gives no number.

The floor of three is this module's, not the protocol's: fewer than
three is not a day divided, and the one thing §07 is unambiguous about
is that a single large dose can trigger arrhythmia. Stated here, and
on the page, so it is visible as a judgement rather than passed off as
the source's.

-}
minServings : Int
minServings =
    3


maxServings : Int
maxServings =
    8


clampServings : Int -> Int
clampServings n =
    clamp minServings maxServings n


servingsFromParam : Maybe String -> Int
servingsFromParam raw =
    raw
        |> Maybe.andThen String.toInt
        |> Maybe.map clampServings
        |> Maybe.withDefault 4



-- THE SHEET


{-| A day's worth, in what you actually handle. Salt weights are
grams; `sodium` and `potassium` are the milligrams they deliver, so
the page can show that the conversion arrived where §07 asked.
-}
type alias Sheet =
    { fineSalt : Range
    , liteSalt : Range
    , kcl : Range
    , sodium : Range
    , potassium : Range
    , water : Range
    }


sheet : Source -> Sheet
sheet source =
    let
        low =
            day source sodium.low potassium.low

        high =
            day source sodium.high potassium.high
    in
    { fineSalt = Range low.fineSalt high.fineSalt
    , liteSalt = Range low.liteSalt high.liteSalt
    , kcl = Range low.kcl high.kcl
    , sodium = Range sodium.low sodium.high
    , potassium = Range low.potassiumMg high.potassiumMg
    , water = water
    }


{-| One end of the day: grams of each salt that deliver these
milligrams.

With a lite salt the potassium comes bundled with sodium, so the
sodium it brings is subtracted from the fine salt rather than added on
top — the mistake this exists to prevent is salting a day twice.

-}
day : Source -> Float -> Float -> { fineSalt : Float, liteSalt : Float, kcl : Float, potassiumMg : Float }
day source sodiumMg potassiumMg =
    case source of
        Kcl ->
            { fineSalt = saltFor sodiumMg
            , liteSalt = 0
            , kcl = potassiumMg / (potassiumInKcl * 1000)
            , potassiumMg = potassiumMg
            }

        Lite ->
            let
                lite =
                    potassiumMg / (litePotassiumFraction * potassiumInKcl * 1000)

                sodiumFromLite =
                    lite * (1 - litePotassiumFraction) * sodiumInSalt * 1000
            in
            { fineSalt = saltFor (max 0 (sodiumMg - sodiumFromLite))
            , liteSalt = lite
            , kcl = 0
            , potassiumMg = potassiumMg
            }

        Excluded ->
            { fineSalt = saltFor sodiumMg
            , liteSalt = 0
            , kcl = 0
            , potassiumMg = 0
            }


saltFor : Float -> Float
saltFor sodiumMg =
    sodiumMg / (sodiumInSalt * 1000)


{-| The same sheet, divided. Magnesium and thiamine are not here: §07
gives magnesium as a single dose at night and thiamine as a daily one,
so dividing them would be arithmetic the protocol did not ask for.
-}
perServing : Int -> Sheet -> Sheet
perServing servings s =
    let
        each range =
            Range (range.low / toFloat servings) (range.high / toFloat servings)
    in
    { fineSalt = each s.fineSalt
    , liteSalt = each s.liteSalt
    , kcl = each s.kcl
    , sodium = each s.sodium
    , potassium = each s.potassium
    , water = each s.water
    }



-- RENDERING NUMBERS


{-| Grams to one decimal — a kitchen scale's resolution, and the unit
this sheet would rather you used.
-}
grams : Float -> String
grams value =
    round1 value ++ " g"


{-| How many sticks of a mix it would take to reach a milligram
target of potassium. Used only to cost out an option the protocol
excludes — see `Page.Dosing`'s "what not to reach for".
-}
sticksFor : Float -> Float
sticksFor potassiumMg =
    potassiumMg / stickPotassium


{-| A count of sticks, to one decimal — they are not divisible, which
is part of the point.
-}
sticks : Float -> String
sticks value =
    if value <= 0 then
        "—"

    else
        round1 value
            ++ (if value < 2 then
                    " stick"

                else
                    " sticks"
               )


{-| Whole litres, for a day's total — 2,000 ml is a true statement
about a day and a strange way to say it.
-}
litres : Float -> String
litres value =
    round1 value ++ " L"


millilitres : Float -> String
millilitres value =
    String.fromInt (round (value * 1000)) ++ " ml"


milligrams : Float -> String
milligrams value =
    let
        whole =
            round value
    in
    if whole >= 1000 then
        String.fromInt (whole // 1000)
            ++ ","
            ++ String.padLeft 3 '0' (String.fromInt (modBy 1000 whole))
            ++ " mg"

    else
        String.fromInt whole ++ " mg"


{-| Teaspoons in the register §07 uses — `¼`, `⅓`, `1½` — because that
is what a reader with a spoon and no scale can act on. Always
approximate, and marked as such: the grams beside it are the honest
number.
-}
teaspoons : Float -> String
teaspoons value =
    if value <= 0 then
        "—"

    else
        "≈ " ++ spoonLabel value ++ " tsp"


spoonLabel : Float -> String
spoonLabel value =
    let
        whole =
            floor value

        part =
            value - toFloat whole

        ( fraction, carry ) =
            nearestFraction part
    in
    case ( whole + carry, fraction ) of
        ( 0, "" ) ->
            -- rounded away to nothing, but there is something there
            "⅛"

        ( 0, f ) ->
            f

        ( n, "" ) ->
            String.fromInt n

        ( n, f ) ->
            String.fromInt n ++ f


{-| The nearest fraction a kitchen spoon can be read at, and whether
rounding carried into the whole number.
-}
nearestFraction : Float -> ( String, Int )
nearestFraction part =
    let
        ladder =
            [ ( 0, ( "", 0 ) )
            , ( 0.125, ( "⅛", 0 ) )
            , ( 0.25, ( "¼", 0 ) )
            , ( 0.333, ( "⅓", 0 ) )
            , ( 0.5, ( "½", 0 ) )
            , ( 0.667, ( "⅔", 0 ) )
            , ( 0.75, ( "¾", 0 ) )
            , ( 1, ( "", 1 ) )
            ]
    in
    ladder
        |> List.sortBy (\( value, _ ) -> abs (value - part))
        |> List.head
        |> Maybe.map Tuple.second
        |> Maybe.withDefault ( "", 0 )


round1 : Float -> String
round1 value =
    let
        tenths =
            round (value * 10)
    in
    String.fromInt (tenths // 10) ++ "." ++ String.fromInt (modBy 10 tenths)
