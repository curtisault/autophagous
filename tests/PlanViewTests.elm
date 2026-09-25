module PlanViewTests exposing (suite)

{-| The planner rendered, not just computed.

These exist because the live clock cannot be checked in a headless
text browser — Elm renders on `requestAnimationFrame`, which such a
browser never drives, so the only DOM it ever shows is the first
frame. Rendering the view directly is both more durable than a
screenshot and the only way to hold the safety invariant: **the abort
signals are on the clock in every state it can be in.**

-}

import Civil
import Cycle exposing (Target(..))
import Dose
import Expect
import Html.Attributes as Attr
import Page.Plan
import Ruler
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector exposing (class, text)
import Time


expectAll : List Expect.Expectation -> Expect.Expectation
expectAll expectations =
    Expect.all (List.map always expectations) ()


{-| UTC−5 that becomes UTC−4 at 2026-03-08T07:00Z — the same zone
`CivilTests` uses, so the planner's backwards arithmetic is checked
against a boundary rather than only in UTC.
-}
springForward : Time.Zone
springForward =
    Time.customZone -300 [ { start = 29549220, offset = -240 } ]


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
    , anchorValue = "2026-09-01T20:00"
    , from = Page.Plan.FromStart
    , target = target
    , download = Just { href = "data:text/calendar,x", name = "cycle.ics" }
    , doseSource = Dose.Kcl
    , doseServings = 4
    , dosingHref = "/dosing?k=kcl&per=4"
    , chrome = { active = Nothing, query = "", onQuery = always () }
    , onAnchor = always ()
    , onFrom = always ()
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
    { base | start = Nothing, anchorValue = "", download = Nothing }


{-| The needle's own cases, drawn on its own. Where the segments point
is `RulerTests`.
-}
ruler : Maybe Int -> Query.Single ()
ruler now =
    Ruler.view
        { target = T72
        , now = now
        , here = Nothing
        , linkTo = \s -> "/#" ++ s.anchor
        }
        |> Query.fromHtml


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
            , test "says how far into the stage, which the stance does not" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.find [ class "clock-depth" ]
                        |> Query.has [ text "17 of 24 h", text "56%" ]
            , test "and says nothing of the sort outside the fast" <|
                \_ ->
                    rendered (context (Just (at (Cycle.days 10))) T72)
                        |> Query.hasNot [ class "clock-depth" ]
            , test "counts down to the next line, with its date" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.findAll [ class "clock-next" ]
                        |> Query.index 0
                        |> Query.has [ text "Stage IV — sustained", text "7:00" ]
            , test "and to the break, which the next line is not carrying" <|
                -- the reader at hour 41 is waiting to eat, not waiting
                -- for Stage IV
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.find [ class "is-break" ]
                        |> Query.has [ text "Break the fast in", text "31:00" ]
            , test "with the break's own wall clock, not just its date" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.find [ class "is-break" ]
                        |> Query.has [ text "20:00" ]
            , test "says it once when the break is also the next line" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 72 - 20))) T72)
                        |> Query.hasNot [ class "is-break" ]
            , test "and not at all outside the fast" <|
                \_ ->
                    rendered (context (Just (at (Cycle.days -2))) T72)
                        |> Query.hasNot [ class "is-break" ]
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
        , describe "counting backwards from the break"
            -- nobody decides to stop eating at 20:00 on Thursday; they
            -- decide to eat lunch on Sunday. `?start=` still carries
            -- hour 0 either way, so a link has one reading
            [ test "the field read as a break gives hour 0 a target earlier" <|
                \_ ->
                    Page.Plan.resolveStart
                        { zone = Time.utc
                        , target = T72
                        , from = Page.Plan.FromBreak
                        , value = "2026-09-04T20:00"
                        }
                        |> Expect.equal (Just start)
            , test "and the same field read as a start is itself" <|
                \_ ->
                    Page.Plan.resolveStart
                        { zone = Time.utc
                        , target = T72
                        , from = Page.Plan.FromStart
                        , value = "2026-09-01T20:00"
                        }
                        |> Expect.equal (Just start)
            , test "the target decides how far back, so 96 h reaches further" <|
                \_ ->
                    Page.Plan.resolveStart
                        { zone = Time.utc
                        , target = T96
                        , from = Page.Plan.FromBreak
                        , value = "2026-09-04T20:00"
                        }
                        |> Expect.equal (Just (at (Cycle.hours -24)))
            , test "a half-typed date is no instant in either direction" <|
                \_ ->
                    [ Page.Plan.FromStart, Page.Plan.FromBreak ]
                        |> List.map
                            (\from ->
                                Page.Plan.resolveStart
                                    { zone = Time.utc
                                    , target = T72
                                    , from = from
                                    , value = "2026-09-0"
                                    }
                                    |> Expect.equal Nothing
                            )
                        |> expectAll
            , test "switching the mode keeps the schedule where it was" <|
                -- the reader changed how they are describing the plan,
                -- not the plan: the break they had implies the same
                -- hour 0 once the field is recast to name it
                \_ ->
                    let
                        asBreak =
                            Page.Plan.recast
                                { zone = Time.utc
                                , target = T72
                                , from = Page.Plan.FromStart
                                , to = Page.Plan.FromBreak
                                , value = "2026-09-01T20:00"
                                }
                    in
                    ( asBreak
                    , Page.Plan.resolveStart
                        { zone = Time.utc
                        , target = T72
                        , from = Page.Plan.FromBreak
                        , value = asBreak
                        }
                    )
                        |> Expect.equal ( "2026-09-04T20:00", Just start )
            , test "and switching back returns the string it started from" <|
                \_ ->
                    "2026-09-01T20:00"
                        |> (\v ->
                                Page.Plan.recast
                                    { zone = Time.utc, target = T72, from = Page.Plan.FromStart, to = Page.Plan.FromBreak, value = v }
                           )
                        |> (\v ->
                                Page.Plan.recast
                                    { zone = Time.utc, target = T72, from = Page.Plan.FromBreak, to = Page.Plan.FromStart, value = v }
                           )
                        |> Expect.equal "2026-09-01T20:00"
            , test "a value it cannot read is handed back untouched" <|
                -- eating what someone is halfway through typing is
                -- worse than leaving it alone
                \_ ->
                    Page.Plan.recast
                        { zone = Time.utc
                        , target = T72
                        , from = Page.Plan.FromStart
                        , to = Page.Plan.FromBreak
                        , value = "2026-09-0"
                        }
                        |> Expect.equal "2026-09-0"
            , test "the mode already selected is a no-op, not a shift" <|
                -- the button stays clickable once it is pressed, and
                -- a click on it must not move the plan by a whole fast
                \_ ->
                    [ Page.Plan.FromStart, Page.Plan.FromBreak ]
                        |> List.map
                            (\mode ->
                                Page.Plan.recast
                                    { zone = Time.utc
                                    , target = T72
                                    , from = mode
                                    , to = mode
                                    , value = "2026-09-01T20:00"
                                    }
                                    |> Expect.equal "2026-09-01T20:00"
                            )
                        |> expectAll
            , test "across a spring-forward, the wall clock is what gives" <|
                -- §01 promises this in as many words. UTC−5 becomes
                -- UTC−4 at 2026-03-08T07:00Z, so holding a Tuesday
                -- 12:00 break puts hour 0 at 11:00 on the Saturday,
                -- not 12:00: 72 elapsed hours is 72 elapsed hours, and
                -- an hour of the reader's Sunday did not happen
                \_ ->
                    Page.Plan.recast
                        { zone = springForward
                        , target = T72
                        , from = Page.Plan.FromBreak
                        , to = Page.Plan.FromStart
                        , value = "2026-03-10T12:00"
                        }
                        |> Expect.equal "2026-03-07T11:00"
            , test "and the schedule still lands on the break that was asked for" <|
                \_ ->
                    let
                        break =
                            Civil.fromIso "2026-03-10T12:00"
                                |> Maybe.map (Civil.toPosix springForward)
                    in
                    Page.Plan.resolveStart
                        { zone = springForward
                        , target = T72
                        , from = Page.Plan.FromBreak
                        , value = "2026-03-10T12:00"
                        }
                        |> Maybe.map (Civil.shift (Cycle.hours 72))
                        |> Expect.equal break
            , test "the field says which end of the fast it is naming" <|
                \_ ->
                    let
                        ctx =
                            context (Just (at (Cycle.hours 41))) T72
                    in
                    ( rendered ctx |> Query.has [ text "Hour 0 — when the last meal ends" ]
                    , rendered { ctx | from = Page.Plan.FromBreak }
                        |> Query.has [ text "The break — when you want to eat" ]
                    )
                        |> (\( a, b ) -> expectAll [ a, b ])
            , test "and states hour 0 back, since counting backwards nobody typed it" <|
                \_ ->
                    let
                        ctx =
                            context (Just (at (Cycle.hours 41))) T72
                    in
                    rendered { ctx | from = Page.Plan.FromBreak }
                        |> Query.find [ class "plan-state" ]
                        |> Query.has [ text "Hour 0", text "stop eating then" ]
            ]
        , describe "where you are, in the sheet"
            [ test "the phase you are in says so, and only that one" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.findAll [ text "You are here" ]
                        |> Query.count (Expect.equal 1)
            , test "and it is the section the stance names" <|
                \_ ->
                    [ ( Cycle.days -2, "sec-prime" )
                    , ( Cycle.hours 41, "sec-fast" )
                    , ( Cycle.hours 72 + Cycle.hours 3, "sec-refeed" )
                    , ( Cycle.days 10, "sec-rebuild" )
                    ]
                        |> List.map
                            (\( m, anchor ) ->
                                rendered (context (Just (at m)) T72)
                                    |> Query.find [ Selector.id anchor ]
                                    |> Query.has [ text "You are here" ]
                            )
                        |> expectAll
            , test "nothing is marked outside the cycle, or before the clock lands" <|
                \_ ->
                    [ context (Just (at (Cycle.days -5))) T72
                    , context (Just (at (Cycle.days 40))) T72
                    , context Nothing T72
                    , unset
                    ]
                        |> List.map (rendered >> Query.hasNot [ text "You are here" ])
                        |> expectAll
            , test "the row in force is marked, not only the moment passed" <|
                -- at hour 41 the moment is the Stage III crossing and
                -- the band is the mandatory daily line; §02 calls both
                -- current, so the table has to agree
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.findAll [ Selector.class "is-now" ]
                        |> Query.count (Expect.equal 2)
            , test "a row can be load-bearing and current at once" <|
                -- hour 0 is a Key row and the line you are standing on
                \_ ->
                    rendered (context (Just (at 5)) T72)
                        |> Query.findAll [ Selector.class "is-now", Selector.class "hero" ]
                        |> Query.count (Expect.equal 2)
            , test "no row is marked before there is a clock to mark it from" <|
                \_ ->
                    rendered (context Nothing T72)
                        |> Query.hasNot [ Selector.class "is-now" ]
            ]
        , describe "what goes in the glass"
            [ test "converts §07 into the units a kitchen has" <|
                -- 3,000–5,000 mg of sodium over 4 doses, as fine salt
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.find [ class "plan-dose" ]
                        |> Query.has [ text "Fine salt", text "One of 4 doses today" ]
            , test "divides by the reader's own choice, not a default" <|
                \_ ->
                    let
                        ctx =
                            context (Just (at (Cycle.hours 41))) T72
                    in
                    rendered { ctx | doseServings = 6 }
                        |> Query.find [ class "plan-dose" ]
                        |> Query.has [ text "One of 6 doses today" ]
            , test "names the salt the reader's source actually carries" <|
                \_ ->
                    let
                        ctx =
                            context (Just (at (Cycle.hours 41))) T72
                    in
                    rendered { ctx | doseSource = Dose.Lite }
                        |> Query.find [ class "plan-dose" ]
                        |> Query.has [ text "Lite salt" ]
            , test "an excluded potassium leaves one row, not an empty one" <|
                \_ ->
                    let
                        ctx =
                            context (Just (at (Cycle.hours 41))) T72
                    in
                    rendered { ctx | doseSource = Dose.Excluded }
                        |> Query.findAll [ class "plan-dose-row" ]
                        |> Query.count (Expect.equal 1)
            , test "keeps the reader's preferences in the link out" <|
                -- arriving at /dosing with the source reset would be
                -- this shell forgetting a choice made two minutes ago
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.find [ class "plan-dose-foot" ]
                        |> Query.has
                            [ Selector.attribute (Attr.href "/dosing?k=kcl&per=4") ]
            , test "carries the potassium warning, because it converts that dose" <|
                \_ ->
                    rendered (context (Just (at (Cycle.hours 41))) T72)
                        |> Query.has [ text "Potassium warning." ]
            , test "is absent outside the fast — §07's targets are the fast's" <|
                -- the refeed requirement is real and it is higher, so
                -- the fast's numbers would understate it. The refeed
                -- says so itself, in the standing band
                \_ ->
                    [ Cycle.days -2, Cycle.hours 72 + Cycle.hours 3, Cycle.days 10 ]
                        |> List.map
                            (\m ->
                                rendered (context (Just (at m)) T72)
                                    |> Query.hasNot [ class "plan-dose" ]
                            )
                        |> expectAll
            ]
        , describe "the needle"
            [ test "is on the ruler during the fast" <|
                \_ ->
                    ruler (Just (Cycle.hours 48))
                        |> Query.has [ class "needle" ]
            , test "is absent before hour 0 — it would claim a position the reader is not in" <|
                \_ ->
                    ruler (Just (Cycle.days -1))
                        |> Query.hasNot [ class "needle" ]
            , test "is absent past the end of the drawn clock" <|
                \_ ->
                    ruler (Just (Cycle.hours 97))
                        |> Query.hasNot [ class "needle" ]
            , test "the protocol's ruler never has one" <|
                \_ ->
                    ruler Nothing
                        |> Query.hasNot [ class "needle" ]
            ]
        ]
