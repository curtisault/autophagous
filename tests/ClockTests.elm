module ClockTests exposing (suite)

{-| The clock is the one thing on the site that tells a reader
something about _themselves_, so every boundary it draws is worth
holding: the hour priming starts, the hour the switch flips, the hour
the fast ends and the refeed begins.

All of it is pure — a target and a number of minutes — which is the
whole reason these cases can be written down at all.

-}

import Clock exposing (Stance(..))
import Cycle exposing (Target(..))
import Expect
import Test exposing (Test, describe, test)


stanceAt : Target -> Int -> Stance
stanceAt target minutes =
    (Clock.reading target minutes).stance


label : Target -> Int -> String
label target minutes =
    Clock.stanceLabel (stanceAt target minutes)


titleAt : Target -> Int -> Maybe String
titleAt target minutes =
    (Clock.reading target minutes).current |> Maybe.map .title


nextAt : Target -> Int -> Maybe String
nextAt target minutes =
    (Clock.reading target minutes).next |> Maybe.map .title


suite : Test
suite =
    describe "Clock"
        [ describe "the stance at each boundary"
            [ test "before priming, the cycle has not begun" <|
                \_ -> stanceAt T72 (Cycle.days -4) |> Expect.equal Waiting
            , test "priming opens exactly three days out" <|
                \_ -> stanceAt T72 (Cycle.days -3) |> Expect.equal (Priming 1)
            , test "the last minute before hour 0 is still priming day 3" <|
                \_ -> stanceAt T72 -1 |> Expect.equal (Priming 3)
            , test "hour 0 is the fast, not priming" <|
                \_ -> label T72 0 |> Expect.equal "Stage I — glycogen draw-down"
            , test "the switch flips at hour 16, not a minute before" <|
                \_ ->
                    ( label T72 (Cycle.hours 16 - 1), label T72 (Cycle.hours 16) )
                        |> Expect.equal ( "Stage I — glycogen draw-down", "Stage II — the switch" )
            , test "a 72 h fast ends at 72 h and the refeed starts there" <|
                \_ ->
                    ( label T72 (Cycle.hours 72 - 1), label T72 (Cycle.hours 72) )
                        |> Expect.equal ( "Stage IV — sustained", "Refeed — day 1 of 2" )
            , test "a 96 h fast is still fasting at hour 72" <|
                \_ -> label T96 (Cycle.hours 72) |> Expect.equal "Stage V — optional extension"
            , test "and breaks at 96" <|
                \_ -> label T96 (Cycle.hours 96) |> Expect.equal "Refeed — day 1 of 2"
            , test "the refeed runs two days, then the rebuild" <|
                \_ ->
                    ( label T72 (Cycle.hours 72 + Cycle.days 1)
                    , label T72 (Cycle.hours 72 + Cycle.days 2)
                    )
                        |> Expect.equal ( "Refeed — day 2 of 2", "Rebuild — day 2" )
            , test "the cycle is complete at the earliest next hour 0" <|
                \_ ->
                    ( stanceAt T72 (Cycle.days 28 - 1), stanceAt T72 (Cycle.days 28) )
                        |> Expect.equal ( Rebuilding 24, Complete )
            , test "in flight means priming, fasting or refeeding — not planning" <|
                \_ ->
                    List.map (stanceAt T72 >> Clock.inFlight)
                        [ Cycle.days -4, Cycle.days -1, Cycle.hours 41, Cycle.hours 73, Cycle.days 10, Cycle.days 40 ]
                        |> Expect.equal [ False, True, True, True, True, False ]
            ]
        , describe "what you are standing on"
            [ test "at hour 0 exactly it is the last meal, not the band beside it" <|
                -- both sit at offset 0; the moment has to win, or the
                -- reader is told to take their electrolytes at the
                -- moment they are told to stop eating
                \_ -> titleAt T72 0 |> Expect.equal (Just "Hour 0 — the last meal ends")
            , test "mid-fast it is the stage you are in" <|
                \_ -> titleAt T72 (Cycle.hours 41) |> Expect.equal (Just "Stage III — climbing")
            , test "before anything has started, nothing" <|
                \_ -> titleAt T72 (Cycle.days -5) |> Expect.equal Nothing
            , test "in the last half hour it is the thiamine dose" <|
                \_ ->
                    titleAt T72 (Cycle.hours 72 - 10)
                        |> Expect.equal (Just "Thiamine, before any food")
            ]
        , describe "what is next"
            [ test "waiting, it is the first priming day" <|
                \_ -> nextAt T72 (Cycle.days -5) |> Expect.equal (Just "Go low-carbohydrate")
            , test "mid-fast, it is the next crossing" <|
                \_ -> nextAt T72 (Cycle.hours 41) |> Expect.equal (Just "Stage IV — sustained")
            , test "a 72 h fast is next told to take thiamine, not to enter Stage V" <|
                \_ ->
                    nextAt T72 (Cycle.hours 50)
                        |> Expect.equal (Just "Thiamine, before any food")
            , test "a 96 h fast is told about Stage V" <|
                \_ -> nextAt T96 (Cycle.hours 50) |> Expect.equal (Just "Stage V — optional extension")
            , test "past the whole cycle there is nothing left to announce" <|
                \_ -> nextAt T72 (Cycle.days 40) |> Expect.equal Nothing
            ]
        , describe "the figure"
            [ test "reads hours and minutes inside two days" <|
                \_ -> Clock.elapsedFigure (Cycle.hours 41 + 20) |> Expect.equal "41:20"
            , test "pads the minutes" <|
                \_ -> Clock.elapsedFigure (Cycle.hours 6 + 5) |> Expect.equal "6:05"
            , test "is signed before hour 0" <|
                \_ -> Clock.elapsedFigure -100 |> Expect.equal "−1:40"
            , test "switches to days once it stops being readable" <|
                \_ -> Clock.elapsedFigure (Cycle.days 3 + Cycle.hours 4) |> Expect.equal "3 d 4 h"
            , test "a countdown is never negative" <|
                \_ -> Clock.countdown -100 |> Expect.equal "1:40"
            , test "zero is zero, not blank" <|
                \_ -> Clock.elapsedFigure 0 |> Expect.equal "0:00"
            ]
        ]
