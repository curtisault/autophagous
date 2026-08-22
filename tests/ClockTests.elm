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


standingAt : Target -> Int -> List String
standingAt target minutes =
    (Clock.reading target minutes).standing |> List.map .title


breakAt : Target -> Int -> Maybe Int
breakAt target minutes =
    (Clock.reading target minutes).toBreak


{-| Depth as the page states it: hours into the stage, the stage's own
length, and whole percent of the target.
-}
depthAt : Target -> Int -> Maybe ( String, Int, Int )
depthAt target minutes =
    (Clock.reading target minutes).depth
        |> Maybe.map
            (\d -> ( d.stage.numeral, d.into // 60, d.percent ))


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
            , test "priming has no moments, so nothing has happened yet" <|
                -- the priming days are bands; they answer `standing`
                \_ -> titleAt T72 (Cycle.days -2) |> Expect.equal Nothing
            ]
        , describe "what is in force"
            -- the regression this whole distinction exists for: a band
            -- is somewhere you are standing, not something that has
            -- happened, and "the last line passed" cannot express it
            [ test "mid-fast the electrolytes are still compulsory" <|
                \_ ->
                    standingAt T72 (Cycle.hours 41)
                        |> Expect.equal [ "Mandatory every day of the fast" ]
            , test "and still are one minute before the break" <|
                \_ ->
                    standingAt T72 (Cycle.hours 72 - 1)
                        |> Expect.equal [ "Mandatory every day of the fast" ]
            , test "but not at the break itself — the fast is over" <|
                \_ ->
                    standingAt T72 (Cycle.hours 72)
                        |> Expect.equal [ "Liquid and pureed textures only" ]
            , test "a band that ends where it starts covers its day" <|
                \_ ->
                    ( standingAt T72 (Cycle.days -2)
                    , standingAt T72 (Cycle.days -2 + Cycle.hours 23)
                    )
                        |> Expect.equal
                            ( [ "Load the inducers" ], [ "Load the inducers" ] )
            , test "and stops at the next day, not a minute later" <|
                \_ ->
                    standingAt T72 (Cycle.days -1)
                        |> Expect.equal [ "Taper protein, start salting" ]
            , test "the 96 h fast holds the daily line eight hours longer" <|
                \_ ->
                    ( standingAt T96 (Cycle.hours 80), standingAt T96 (Cycle.hours 96) )
                        |> Expect.equal
                            ( [ "Mandatory every day of the fast" ]
                            , [ "Liquid and pureed textures only" ]
                            )
            , test "refeed day 2 is inside the rebuild window as well" <|
                -- two bands at once is the normal case, not an edge one
                \_ ->
                    standingAt T72 (Cycle.hours 72 + Cycle.days 1 + Cycle.hours 3)
                        |> Expect.equal
                            [ "Normal meals, carbohydrate last", "The rebuild window" ]
            , test "before anything has started, nothing is in force" <|
                \_ -> standingAt T72 (Cycle.days -5) |> Expect.equal []
            , test "and nothing is, once the cycle is behind you" <|
                \_ -> standingAt T72 (Cycle.days 40) |> Expect.equal []
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
            , test "a minute before hour 0, it is hour 0 — not the band beside it" <|
                -- both sit at offset 0; the moment has to win, or the
                -- reader about to eat their last meal is told the next
                -- thing to happen is a standing electrolyte requirement
                \_ -> nextAt T72 -1 |> Expect.equal (Just "Hour 0 — the last meal ends")
            , test "and at the break it is the break, not the texture rule" <|
                \_ ->
                    nextAt T72 (Cycle.hours 72 - 1)
                        |> Expect.equal (Just "Break the fast")
            , test "past the whole cycle there is nothing left to announce" <|
                \_ -> nextAt T72 (Cycle.days 40) |> Expect.equal Nothing
            ]
        , describe "the countdown to the break"
            -- the number `next` cannot carry: across the fast it is
            -- announcing stage crossings, and the reader is waiting to eat
            [ test "runs from hour 0" <|
                \_ -> breakAt T72 0 |> Expect.equal (Just (Cycle.hours 72))
            , test "and counts the whole fast down" <|
                \_ -> breakAt T72 (Cycle.hours 41) |> Expect.equal (Just (Cycle.hours 31))
            , test "measures the target that is set, not the shortest one" <|
                \_ ->
                    ( breakAt T72 (Cycle.hours 50), breakAt T96 (Cycle.hours 50) )
                        |> Expect.equal ( Just (Cycle.hours 22), Just (Cycle.hours 46) )
            , test "is silent before hour 0 — the fast has no length yet" <|
                \_ ->
                    ( breakAt T72 (Cycle.days -2), breakAt T72 -1 )
                        |> Expect.equal ( Nothing, Nothing )
            , test "is silent at the break itself and after it" <|
                -- not "in 0:00": at the break, `current` is the break,
                -- with the protocol's own instructions attached
                \_ ->
                    ( breakAt T72 (Cycle.hours 72), breakAt T72 (Cycle.hours 80) )
                        |> Expect.equal ( Nothing, Nothing )
            , test "stands down for the last half hour, where `next` says it" <|
                \_ ->
                    ( nextAt T72 (Cycle.hours 72 - 20), breakAt T72 (Cycle.hours 72 - 20) )
                        |> Expect.equal ( Just "Break the fast", Nothing )
            , test "but is still speaking a minute before that" <|
                \_ ->
                    breakAt T72 (Cycle.hours 72 - 31)
                        |> Expect.equal (Just 31)
            ]
        , describe "how far in"
            [ test "counts from the stage's own start, not from hour 0" <|
                -- Stage III opens at 24 h, so hour 41 is 17 h into it
                \_ ->
                    depthAt T72 (Cycle.hours 41)
                        |> Expect.equal (Just ( "III", 17, 56 ))
            , test "a stage's first minute is zero hours in, not one" <|
                \_ ->
                    depthAt T72 (Cycle.hours 24)
                        |> Expect.equal (Just ( "III", 0, 33 ))
            , test "the stage's length is the stage's, whichever it is" <|
                \_ ->
                    (Clock.reading T72 (Cycle.hours 20)).depth
                        |> Maybe.map (\d -> ( d.stage.numeral, d.span ))
                        |> Expect.equal (Just ( "II", Cycle.hours 8 ))
            , test "the percentage is of the target that is set" <|
                \_ ->
                    ( depthAt T72 (Cycle.hours 36), depthAt T96 (Cycle.hours 36) )
                        |> Expect.equal
                            ( Just ( "III", 12, 50 ), Just ( "III", 12, 37 ) )
            , test "99% has to mean still fasting, so it floors" <|
                -- rounding would print 100% with the better part of an
                -- hour still to run
                \_ ->
                    depthAt T72 (Cycle.hours 72 - 1)
                        |> Expect.equal (Just ( "IV", 23, 99 ))
            , test "hour 0 is 0%, not blank" <|
                \_ -> depthAt T72 0 |> Expect.equal (Just ( "I", 0, 0 ))
            , test "the stances that count themselves do not get one" <|
                -- priming, refeed and rebuild all say "day N of M"
                \_ ->
                    List.map (depthAt T72)
                        [ Cycle.days -2, Cycle.hours 72, Cycle.days 10, Cycle.days 40 ]
                        |> Expect.equal [ Nothing, Nothing, Nothing, Nothing ]
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
