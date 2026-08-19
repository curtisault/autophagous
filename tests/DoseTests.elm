module DoseTests exposing (suite)

{-| The dosing sheet converts a safety-critical dose, so the tests
that matter are the ones that hold it to the protocol rather than to
itself.

The first group is the important one: run §07's own milligram targets
through the conversion and check the answer comes back as §07's own
teaspoon figures. If those ever disagree, the sheet is telling readers
something the section it claims to convert does not say.

-}

import Dose exposing (Source(..))
import Expect
import Test exposing (Test, describe, test)


{-| Teaspoons of a salt for one end of a range.
-}
spoons : Float -> Float -> Float
spoons gramsOfSalt perTsp =
    gramsOfSalt / perTsp


kcl : Dose.Sheet
kcl =
    Dose.sheet Kcl


lite : Dose.Sheet
lite =
    Dose.sheet Lite


excluded : Dose.Sheet
excluded =
    Dose.sheet Excluded


suite : Test
suite =
    describe "Dose"
        [ describe "it agrees with §07's own teaspoon figures"
            -- §07: sodium 3,000–5,000 mg is "1¼–2 tsp fine salt";
            -- potassium 1,000–3,000 mg is "⅓–1 tsp" potassium chloride
            [ test "the sodium range comes out at 1¼–2 tsp of fine salt" <|
                \_ ->
                    ( spoons kcl.fineSalt.low Dose.gramsPerTspSalt
                    , spoons kcl.fineSalt.high Dose.gramsPerTspSalt
                    )
                        |> Expect.all
                            [ Tuple.first >> Expect.within (Expect.Absolute 0.1) 1.25
                            , Tuple.second >> Expect.within (Expect.Absolute 0.15) 2.0
                            ]
            , test "the potassium range comes out at ⅓–1 tsp of potassium chloride" <|
                \_ ->
                    ( spoons kcl.kcl.low Dose.gramsPerTspKcl
                    , spoons kcl.kcl.high Dose.gramsPerTspKcl
                    )
                        |> Expect.all
                            [ Tuple.first >> Expect.within (Expect.Absolute 0.05) (1 / 3)
                            , Tuple.second >> Expect.within (Expect.Absolute 0.05) 1.0
                            ]
            , test "and the salts deliver the milligrams the section asked for" <|
                \_ ->
                    ( kcl.fineSalt.high * Dose.sodiumInSalt * 1000
                    , kcl.kcl.high * Dose.potassiumInKcl * 1000
                    )
                        |> Expect.all
                            [ Tuple.first >> Expect.within (Expect.Absolute 1) 5000
                            , Tuple.second >> Expect.within (Expect.Absolute 1) 3000
                            ]
            ]
        , describe "a lite salt is half table salt"
            [ test "it takes roughly twice the spoonfuls for the same potassium" <|
                \_ ->
                    (spoons lite.liteSalt.high Dose.gramsPerTspLite
                        / spoons kcl.kcl.high Dose.gramsPerTspKcl
                    )
                        |> Expect.within (Expect.Absolute 0.1) 2.0
            , test "and the sodium it brings comes off the fine salt, not on top" <|
                -- the mistake this exists to prevent: salting a day twice
                \_ ->
                    (lite.fineSalt.high < kcl.fineSalt.high)
                        |> Expect.equal True
            , test "the two together still deliver §07's sodium target" <|
                \_ ->
                    let
                        fromLite =
                            lite.liteSalt.high * (1 - Dose.litePotassiumFraction) * Dose.sodiumInSalt * 1000

                        fromSalt =
                            lite.fineSalt.high * Dose.sodiumInSalt * 1000
                    in
                    fromLite + fromSalt |> Expect.within (Expect.Absolute 1) 5000
            , test "and still deliver the potassium target" <|
                \_ ->
                    lite.liteSalt.high
                        * Dose.litePotassiumFraction
                        * Dose.potassiumInKcl
                        * 1000
                        |> Expect.within (Expect.Absolute 1) 3000
            ]
        , describe "a stick mix is costed, never offered"
            -- §07 excludes anything with calories, so it is not one of
            -- the sources. The page still answers "how much would it
            -- take?", because that answer is more use than silence
            [ test "it is not a potassium source" <|
                \_ ->
                    List.map Dose.sourceLabel Dose.sources
                        |> Expect.equal [ "Potassium chloride", "50/50 lite salt", "Not taking it" ]
            , test "and no parameter can make it one" <|
                \_ ->
                    List.map Dose.sourceFromParam [ Just "stick", Just "liquidiv" ]
                        |> Expect.equal [ Kcl, Kcl ]
            , test "hitting §07's potassium would take between two and nine sticks" <|
                \_ ->
                    ( Dose.sticksFor Dose.potassium.low, Dose.sticksFor Dose.potassium.high )
                        |> Expect.all
                            [ Tuple.first >> Expect.within (Expect.Absolute 0.1) 2.7
                            , Tuple.second >> Expect.within (Expect.Absolute 0.1) 8.1
                            ]
            , test "which is a day's worth of sugar, not a splash" <|
                \_ ->
                    (Dose.sticksFor Dose.potassium.high * Dose.stickSugar > 50)
                        |> Expect.equal True
            ]
        , describe "excluded means excluded"
            [ test "no potassium chloride" <|
                \_ -> ( excluded.kcl.low, excluded.kcl.high ) |> Expect.equal ( 0, 0 )
            , test "no lite salt either — it is a potassium source too" <|
                \_ -> ( excluded.liteSalt.low, excluded.liteSalt.high ) |> Expect.equal ( 0, 0 )
            , test "no potassium delivered at all" <|
                \_ -> ( excluded.potassium.low, excluded.potassium.high ) |> Expect.equal ( 0, 0 )
            , test "the sodium target is still met, all of it from fine salt" <|
                \_ ->
                    excluded.fineSalt.high
                        * Dose.sodiumInSalt
                        * 1000
                        |> Expect.within (Expect.Absolute 1) 5000
            ]
        , describe "the day is divided, never taken at once"
            [ test "a dose is the day over the number of doses" <|
                \_ ->
                    (Dose.perServing 4 kcl).kcl.high
                        |> Expect.within (Expect.Absolute 0.001) (kcl.kcl.high / 4)
            , test "the floor is three — fewer is not a day divided" <|
                \_ -> Dose.clampServings 1 |> Expect.equal Dose.minServings
            , test "and it holds against anything the URL carries" <|
                \_ ->
                    List.map Dose.servingsFromParam [ Just "1", Just "0", Just "-4", Just "99", Just "x", Nothing ]
                        |> Expect.equal [ 3, 3, 3, 8, 4, 4 ]
            , test "four doses of potassium are each well under a day's worth" <|
                \_ ->
                    ((Dose.perServing 4 kcl).potassium.high < 1000)
                        |> Expect.equal True
            ]
        , describe "the source round-trips through the URL"
            [ test "every source has a parameter that reads back" <|
                \_ ->
                    List.map (Dose.sourceParam >> Just >> Dose.sourceFromParam) Dose.sources
                        |> Expect.equal Dose.sources
            , test "an unreadable one falls back to the pure salt §07 describes" <|
                \_ ->
                    List.map Dose.sourceFromParam [ Nothing, Just "", Just "salt" ]
                        |> Expect.equal [ Kcl, Kcl, Kcl ]
            ]
        , describe "numbers are rendered in the register §07 uses"
            [ test "milligrams carry a thousands separator" <|
                \_ -> Dose.milligrams 3000 |> Expect.equal "3,000 mg"
            , test "small ones do not" <|
                \_ -> Dose.milligrams 50 |> Expect.equal "50 mg"
            , test "grams read to a tenth, the resolution of a kitchen scale" <|
                \_ -> Dose.grams 5.72 |> Expect.equal "5.7 g"
            , test "teaspoons come out as kitchen fractions" <|
                \_ ->
                    List.map Dose.teaspoons [ 0.33, 0.5, 1.0, 1.25, 2.12 ]
                        |> Expect.equal [ "≈ ⅓ tsp", "≈ ½ tsp", "≈ 1 tsp", "≈ 1¼ tsp", "≈ 2⅛ tsp" ]
            , test "a rounded-up fraction carries into the whole number" <|
                \_ -> Dose.teaspoons 0.97 |> Expect.equal "≈ 1 tsp"
            , test "nothing is an em dash, not a zero" <|
                \_ -> Dose.teaspoons 0 |> Expect.equal "—"
            , test "a trace still shows as a trace" <|
                \_ -> Dose.teaspoons 0.01 |> Expect.equal "≈ ⅛ tsp"
            ]
        ]
