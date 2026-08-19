module CivilTests exposing (suite)

{-| The conversion `elm/time` does not ship, so it is the one this
project has to prove. The zone cases matter most: every date the
planner prints, and every timestamp in an exported calendar, is
downstream of `toPosix`.
-}

import Civil
import Expect
import Test exposing (Test, describe, test)
import Time


{-| A fixed offset — no daylight saving anywhere in it.
-}
utcMinus5 : Time.Zone
utcMinus5 =
    Time.customZone -300 []


{-| UTC−5 that becomes UTC−4 at 2026-03-08T07:00Z: North American
spring-forward, the case a single-pass conversion gets wrong by an
hour.
-}
springForward : Time.Zone
springForward =
    Time.customZone -300 [ { start = 29549220, offset = -240 } ]


suite : Test
suite =
    describe "Civil"
        [ describe "fromIso"
            [ test "reads the datetime-local shape" <|
                \_ ->
                    Civil.fromIso "2026-09-01T20:00"
                        |> Expect.equal (Just (Civil.Civil 2026 9 1 20 0 0))
            , test "reads it with seconds too" <|
                \_ ->
                    Civil.fromIso "2026-09-01T20:00:30"
                        |> Expect.equal (Just (Civil.Civil 2026 9 1 20 0 30))
            , test "rejects a day the month does not have" <|
                \_ -> Civil.fromIso "2026-02-31T08:00" |> Expect.equal Nothing
            , test "accepts 29 February in a leap year" <|
                \_ ->
                    Civil.fromIso "2028-02-29T08:00"
                        |> Expect.equal (Just (Civil.Civil 2028 2 29 8 0 0))
            , test "rejects 29 February in a common year" <|
                \_ -> Civil.fromIso "2026-02-29T08:00" |> Expect.equal Nothing
            , test "rejects hour 24" <|
                \_ -> Civil.fromIso "2026-09-01T24:00" |> Expect.equal Nothing
            , test "rejects a half-typed value" <|
                \_ -> Civil.fromIso "2026-09-01" |> Expect.equal Nothing
            , test "rejects an empty field" <|
                \_ -> Civil.fromIso "" |> Expect.equal Nothing
            ]
        , describe "toIso round-trips at minute precision"
            [ test "back to the value the input gave" <|
                \_ ->
                    Civil.fromIso "2026-09-01T20:00"
                        |> Maybe.map Civil.toIso
                        |> Expect.equal (Just "2026-09-01T20:00")
            , test "pads single digits" <|
                \_ ->
                    Civil.fromIso "2026-1-2T3:04"
                        |> Maybe.map Civil.toIso
                        |> Expect.equal (Just "2026-01-02T03:04")
            ]
        , describe "toPosix"
            [ test "UTC reads the fields as they stand" <|
                \_ ->
                    Civil.toPosix Time.utc (Civil.Civil 2026 9 1 20 0 0)
                        |> Time.posixToMillis
                        |> Expect.equal 1788292800000
            , test "a fixed offset shifts the instant, not the clock" <|
                \_ ->
                    Civil.toPosix utcMinus5 (Civil.Civil 2026 9 1 20 0 0)
                        |> Time.posixToMillis
                        |> Expect.equal 1788310800000
            , test "the second pass catches a spring-forward boundary" <|
                -- 03:00 local is 07:00Z on the far side of the change;
                -- one pass would answer 08:00Z, an hour late
                \_ ->
                    Civil.toPosix springForward (Civil.Civil 2026 3 8 3 0 0)
                        |> Time.posixToMillis
                        |> Expect.equal 1772953200000
            , test "round-trips through the zone it was read in" <|
                \_ ->
                    let
                        wall =
                            Civil.Civil 2026 11 3 6 30 0
                    in
                    Civil.toPosix springForward wall
                        |> Civil.fromPosix springForward
                        |> Expect.equal wall
            ]
        , describe "offsetMinutes"
            [ test "is zero in UTC" <|
                \_ ->
                    Civil.offsetMinutes Time.utc (Time.millisToPosix 1788292800000)
                        |> Expect.equal 0
            , test "reads a fixed zone's own offset back" <|
                \_ ->
                    Civil.offsetMinutes utcMinus5 (Time.millisToPosix 1788292800000)
                        |> Expect.equal -300
            , test "follows the zone across its own boundary" <|
                \_ ->
                    ( Civil.offsetMinutes springForward (Time.millisToPosix (1772953200000 - 60000))
                    , Civil.offsetMinutes springForward (Time.millisToPosix (1772953200000 + 60000))
                    )
                        |> Expect.equal ( -300, -240 )
            ]
        , describe "elapsed hours are elapsed, not wall clock"
            [ test "72 h across a spring-forward lands an hour later on the clock" <|
                -- the whole reason offsets are added in Posix: 72 real
                -- hours from 20:00 on the Friday is 21:00, not 20:00
                \_ ->
                    Civil.toPosix springForward (Civil.Civil 2026 3 6 20 0 0)
                        |> Civil.shift (72 * 60)
                        |> Civil.formatTime springForward
                        |> Expect.equal "21:00"
            ]
        , describe "rendering"
            [ test "a date leads with the weekday" <|
                \_ ->
                    Civil.formatDate Time.utc (Time.millisToPosix 1788292800000)
                        |> Expect.equal "Tue 01 Sep"
            , test "the year form carries it" <|
                \_ ->
                    Civil.formatDateYear Time.utc (Time.millisToPosix 1788292800000)
                        |> Expect.equal "Tue 01 Sep 2026"
            , test "time is 24-hour and padded" <|
                \_ ->
                    Civil.formatTime utcMinus5 (Time.millisToPosix 1788310800000)
                        |> Expect.equal "20:00"
            , test "an ics stamp is UTC, whatever the reader's zone" <|
                \_ ->
                    Civil.icsStamp (Time.millisToPosix 1788310800000)
                        |> Expect.equal "20260902T010000Z"
            , test "an ics all-day date is local, so a priming day is a local day" <|
                \_ ->
                    Civil.icsDate utcMinus5 (Time.millisToPosix 1788310800000)
                        |> Expect.equal "20260901"
            ]
        ]
