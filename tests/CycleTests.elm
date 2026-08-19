module CycleTests exposing (suite)

{-| The schedule is shared apparatus — the protocol's stage cards, the
ruler, the planner's tables and the calendar export all read it. These
tests hold the boundaries that all four depend on, and the two rules
that a target change has to respect.
-}

import Cycle exposing (Span(..), Target(..))
import Expect
import Test exposing (Test, describe, test)


entriesOf : Target -> List Cycle.Entry
entriesOf target =
    List.concatMap .entries (Cycle.plan target)


titlesOf : Target -> List String
titlesOf target =
    List.map .title (entriesOf target)


suite : Test
suite =
    describe "Cycle"
        [ describe "the stages"
            [ test "run 0 to 96 h without a gap or an overlap" <|
                \_ ->
                    List.map (\s -> ( s.from, s.to )) Cycle.stages
                        |> Expect.equal [ ( 0, 16 ), ( 16, 24 ), ( 24, 48 ), ( 48, 72 ), ( 72, 96 ) ]
            , test "the scale is the last boundary, not a second copy of it" <|
                \_ -> Cycle.scaleHours |> Expect.equal 96
            , test "hours read in the protocol's own notation" <|
                \_ ->
                    List.map Cycle.stageHours Cycle.stages
                        |> Expect.equal [ "0–16 h", "16–24 h", "24–48 h", "48–72 h", "72–96 h" ]
            ]
        , describe "the target"
            [ test "72 h is the shorter, 96 h the extension" <|
                \_ ->
                    List.map Cycle.targetHours Cycle.targets |> Expect.equal [ 72, 96 ]
            , test "an unknown parameter falls back to the shorter fast" <|
                -- never propose the longer one on a link that lost its query
                \_ ->
                    List.map Cycle.targetFromParam [ Nothing, Just "", Just "120", Just "96" ]
                        |> Expect.equal [ T72, T72, T72, T96 ]
            , test "the parameter round-trips" <|
                \_ ->
                    List.map (Cycle.targetParam >> Just >> Cycle.targetFromParam) Cycle.targets
                        |> Expect.equal Cycle.targets
            ]
        , describe "the crossings a fast actually reaches"
            [ test "a 72 h fast is never told about Stage V" <|
                \_ ->
                    titlesOf T72
                        |> List.filter (String.startsWith "Stage")
                        |> Expect.equal
                            [ "Stage II — the switch"
                            , "Stage III — climbing"
                            , "Stage IV — sustained"
                            ]
            , test "a 96 h fast is" <|
                \_ ->
                    titlesOf T96
                        |> List.filter (String.startsWith "Stage")
                        |> Expect.equal
                            [ "Stage II — the switch"
                            , "Stage III — climbing"
                            , "Stage IV — sustained"
                            , "Stage V — optional extension"
                            ]
            ]
        , describe "everything downstream measures from the target"
            [ test "the fast ends where the refeed begins" <|
                \_ ->
                    List.map breakOffset [ T72, T96 ]
                        |> Expect.equal [ Just (Cycle.hours 72), Just (Cycle.hours 96) ]
            , test "the thiamine dose comes before the first food, not after" <|
                \_ ->
                    List.map (\t -> Maybe.map2 (<) (thiamineOffset t) (breakOffset t)) [ T72, T96 ]
                        |> Expect.equal [ Just True, Just True ]
            , test "the daily minimum band covers the whole fast" <|
                \_ ->
                    List.map dailySpan [ T72, T96 ]
                        |> Expect.equal [ Just ( 0, Cycle.hours 72 ), Just ( 0, Cycle.hours 96 ) ]
            , test "the next cycle is monthly from hour 0, not from the refeed" <|
                -- otherwise the extra day of a 96 h fast would quietly
                -- push the cadence out
                \_ ->
                    List.map nextCycleOffset [ T72, T96 ]
                        |> Expect.equal [ Just (Cycle.days 28), Just (Cycle.days 28) ]
            ]
        , describe "the phases"
            [ test "are the four the protocol names, in order" <|
                \_ ->
                    List.map .num (Cycle.plan T72)
                        |> Expect.equal [ "Phase 1", "Phase 2", "Phase 3", "Phase 4" ]
            , test "each links back to the protocol section it compresses" <|
                \_ ->
                    List.map .source (Cycle.plan T72)
                        |> Expect.equal [ "/#sec-prime", "/#sec-fast", "/#sec-refeed", "/#sec-rebuild" ]
            , test "priming runs the three days before hour 0" <|
                \_ ->
                    List.map .at (List.concatMap .entries (List.take 1 (Cycle.plan T72)))
                        |> Expect.equal [ Cycle.days -3, Cycle.days -2, Cycle.days -1 ]
            , test "no band ends before it starts" <|
                \_ ->
                    entriesOf T96
                        |> List.filterMap
                            (\e ->
                                case e.span of
                                    Until end ->
                                        Just (end >= e.at)

                                    Moment ->
                                        Nothing
                            )
                        |> List.all identity
                        |> Expect.equal True
            , test "every line carries a mark and a detail" <|
                \_ ->
                    entriesOf T96
                        |> List.all (\e -> e.mark /= "" && e.detail /= "" && e.title /= "")
                        |> Expect.equal True
            ]
        ]


offsetOf : String -> Target -> Maybe Int
offsetOf title target =
    entriesOf target
        |> List.filter (\e -> e.title == title)
        |> List.head
        |> Maybe.map .at


breakOffset : Target -> Maybe Int
breakOffset =
    offsetOf "Break the fast"


thiamineOffset : Target -> Maybe Int
thiamineOffset =
    offsetOf "Thiamine, before any food"


nextCycleOffset : Target -> Maybe Int
nextCycleOffset =
    offsetOf "Earliest next hour 0"


dailySpan : Target -> Maybe ( Int, Int )
dailySpan target =
    entriesOf target
        |> List.filter (\e -> e.title == "Mandatory every day of the fast")
        |> List.head
        |> Maybe.andThen
            (\e ->
                case e.span of
                    Until end ->
                        Just ( e.at, end )

                    Moment ->
                        Nothing
            )
