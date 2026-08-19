module PlanViewTests exposing (suite)

{-| The planner rendered, not just computed.

These exist because the live clock cannot be checked in a headless
text browser — Elm renders on `requestAnimationFrame`, which such a
browser never drives, so the only DOM it ever shows is the first
frame. Rendering the view directly is both more durable than a
screenshot and the only way to hold the safety invariant: **the abort
signals are on the clock in every state it can be in.**

-}

import Cycle exposing (Target(..))
import Page.Plan
import Ruler
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (class, text)
import Time


{-| 2026-09-01T20:00Z — the same instant the calendar tests use.
-}
start : Time.Posix
start =
    Time.millisToPosix 1788292800000


at : Int -> Time.Posix
at minutes =
    Time.millisToPosix (1788292800000 + minutes * 60000)


context : Maybe Time.Posix -> Target -> Page.Plan.Context ()
context now target =
    { zone = Time.utc
    , start = Just start
    , now = now
    , startValue = "2026-09-01T20:00"
    , target = target
    , download = Just { href = "data:text/calendar,x", name = "cycle.ics" }
    , onStart = always ()
    , onTarget = always ()
    }


rendered : Page.Plan.Context () -> Query.Single ()
rendered =
    Page.Plan.view >> Query.fromHtml


{-| Every state §02 can be in, including the two where there is no
clock to show.
-}
everyState : List ( String, Page.Plan.Context () )
everyState =
    [ ( "no start set", { unset | now = Just (at 0) } )
    , ( "clock not yet read", context Nothing T72 )
    , ( "waiting", context (Just (at (Cycle.days -5))) T72 )
    , ( "priming", context (Just (at (Cycle.days -1))) T72 )
    , ( "fasting", context (Just (at (Cycle.hours 41))) T72 )
    , ( "refeeding", context (Just (at (Cycle.hours 73))) T72 )
    , ( "rebuilding", context (Just (at (Cycle.days 10))) T72 )
    , ( "complete", context (Just (at (Cycle.days 40))) T72 )
    ]


unset : Page.Plan.Context ()
unset =
    let
        base =
            context (Just (at 0)) T72
    in
    { base | start = Nothing, startValue = "", download = Nothing }


suite : Test
suite =
    describe "Page.Plan"
        [ describe "the abort signals are on the clock in every state"
            -- DESIGN-REQUIREMENTS §5: never truncated, never behind an
            -- interaction. A reader at hour 41 with spreading numbness
            -- is not going to follow a link, so this is the one place
            -- safety content is repeated rather than referred to
            (List.map
                (\( name, ctx ) ->
                    test name <|
                        \_ ->
                            rendered ctx
                                |> Query.has
                                    [ text "Break the fast immediately if"
                                    , text "Numbness or tingling that spreads"
                                    , text "Chest pain"
                                    ]
                )
                everyState
            )
        , describe "the reading"
            [ test "leads with the elapsed figure" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41 + 20))) T72)
                        |> Query.find [ class "clock-figure" ]
                        |> Query.has [ text "41:20" ]
            , test "names the stage the reader is in" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.find [ class "clock-stance" ]
                        |> Query.has [ text "Stage III — climbing" ]
            , test "counts down to the next line, with its date" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.find [ class "clock-next" ]
                        |> Query.has [ text "Stage IV — sustained", text "7:00" ]
            , test "marks itself live while the reader is in the cycle" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.has [ class "is-live" ]
            , test "and does not once the cycle is behind them" <|
                \_ ->
                    rendered (context (Just (at (Cycle.days 40))) T72)
                        |> Query.hasNot [ class "is-live" ]
            , test "shows no clock at all before the device clock is read" <|
                -- a reading counted from the epoch would say "−20682 d"
                \_ ->
                    rendered (context Nothing T72)
                        |> Query.hasNot [ class "clock-figure" ]
            , test "and none before a start is set" <|
                \_ -> rendered unset |> Query.hasNot [ class "clock-figure" ]
            ]
        , describe "the needle"
            [ test "is on the ruler during the fast" <|
                \_ ->
                    Ruler.view { target = T72, now = Just (Cycle.hours 48) }
                        |> Query.fromHtml
                        |> Query.has [ class "needle" ]
            , test "is absent before hour 0 — it would claim a position the reader is not in" <|
                \_ ->
                    Ruler.view { target = T72, now = Just (Cycle.days -1) }
                        |> Query.fromHtml
                        |> Query.hasNot [ class "needle" ]
            , test "is absent past the end of the drawn clock" <|
                \_ ->
                    Ruler.view { target = T72, now = Just (Cycle.hours 97) }
                        |> Query.fromHtml
                        |> Query.hasNot [ class "needle" ]
            , test "the protocol's ruler never has one" <|
                \_ ->
                    Ruler.view { target = T72, now = Nothing }
                        |> Query.fromHtml
                        |> Query.hasNot [ class "needle" ]
            ]
        ]
