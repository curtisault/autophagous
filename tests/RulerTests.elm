module RulerTests exposing (suite)

{-| The ruler is drawn twice — plain in the protocol's §08, and with a
needle on the planner — and from 2026-08-21 both are navigation.

The check worth having is not that an `href` is present but that it
**arrives**: a segment claims a stage card, and that card has to
exist, on the page the link names. Those two facts are written in
different files by different hands (`Cycle.stages` and
`Page.Protocol.stageCard`), which is the same shape of drift the
citation apparatus was built to catch.

-}

import Clock
import Cycle
import Doc
import Expect
import Html.Attributes as Attr
import Page.Protocol
import Ruler
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


chrome : Doc.Chrome ()
chrome =
    { active = Nothing, query = "", onQuery = always () }


protocol : Query.Single ()
protocol =
    Query.fromHtml (Page.Protocol.view chrome)


{-| The planner's ruler, rendered on its own — the page around it is
`PlanViewTests`' business.
-}
planner : Query.Single ()
planner =
    plannerAt (Just (Cycle.hours 41))


{-| The planner's ruler, marked where a reading at `now` would put the
reader — `here` comes from `Clock.Reading.depth` in the page itself.
-}
plannerAt : Maybe Int -> Query.Single ()
plannerAt now =
    Query.fromHtml
        (Ruler.view
            { target = Cycle.T96
            , now = now
            , here = Maybe.andThen (\m -> (Clock.reading Cycle.T96 m).depth) now |> Maybe.map .stage
            , linkTo = \s -> "/#" ++ s.anchor
            }
        )


suite : Test
suite =
    describe "the ruler"
        [ describe "the anchors"
            [ test "every stage names one, and no two name the same" <|
                \_ ->
                    let
                        anchors =
                            List.map .anchor Cycle.stages
                    in
                    ( List.length (List.filter String.isEmpty anchors)
                    , List.length (dedupe anchors)
                    )
                        |> Expect.equal ( 0, List.length Cycle.stages )
            , test "and the protocol carries a card at each one" <|
                -- the segments are links to these ids; an id that is
                -- not rendered is a segment that goes nowhere
                \_ ->
                    Cycle.stages
                        |> List.map
                            (\s ->
                                protocol
                                    |> Query.findAll [ Selector.id s.anchor ]
                                    |> Query.count (Expect.equal 1)
                            )
                        |> expectAll
            ]
        , describe "where a segment sends the reader"
            [ test "on the protocol, into the section it is already in" <|
                \_ ->
                    Cycle.stages
                        |> List.map
                            (\s ->
                                protocol
                                    |> Query.findAll
                                        [ Selector.class "rlbl"
                                        , Selector.attribute (Attr.href ("#" ++ s.anchor))
                                        ]
                                    |> Query.count (Expect.equal 1)
                            )
                        |> expectAll
            , test "on the planner, out to the protocol that holds the stage" <|
                -- the planner is a schedule; the stage's content is the
                -- section it compressed (DESIGN-PRINCIPLES §3b)
                \_ ->
                    Cycle.stages
                        |> List.map
                            (\s ->
                                planner
                                    |> Query.findAll
                                        [ Selector.attribute (Attr.href ("/#" ++ s.anchor)) ]
                                    |> Query.count (Expect.equal 1)
                            )
                        |> expectAll
            , test "the numeral alone is not the accessible name" <|
                -- "III" in a band 24% wide is what there is room for;
                -- the label carries what the card would have said
                \_ ->
                    planner
                        |> Query.has
                            [ Selector.attribute
                                (Attr.attribute "aria-label" "Stage II — The switch, 16–24 h")
                            ]
            , test "and the stage you are in says so in that name too" <|
                -- the volt underline is not in the accessible tree
                \_ ->
                    planner
                        |> Query.has
                            [ Selector.attribute
                                (Attr.attribute "aria-label"
                                    "Stage III — Climbing, 24–48 h — where you are"
                                )
                            ]
            , test "a segment is drawn for every stage, at both targets" <|
                -- the 72 h ruler still draws Stage V: the scale is the
                -- protocol's whole clock, not the target
                \_ ->
                    planner
                        |> Query.findAll [ Selector.class "rlbl" ]
                        |> Query.count (Expect.equal (List.length Cycle.stages))
            ]
        , describe "which stage is yours"
            [ test "exactly one segment is marked, and it is the one you are in" <|
                \_ ->
                    plannerAt (Just (Cycle.hours 41))
                        |> Query.find [ Selector.class "is-here" ]
                        |> Query.has
                            [ Selector.attribute (Attr.href "/#stage-iii")
                            , Selector.attribute (Attr.attribute "aria-current" "true")
                            ]
            , test "the mark moves with the hour, not with the target" <|
                \_ ->
                    [ Cycle.hours 8, Cycle.hours 20, Cycle.hours 41, Cycle.hours 80 ]
                        |> List.map
                            (\m ->
                                plannerAt (Just m)
                                    |> Query.find [ Selector.class "is-here" ]
                                    |> Query.has [ Selector.text (numeralAt m) ]
                            )
                        |> expectAll
            , test "nothing is marked outside the fast" <|
                -- priming and the rebuild are not stages; a mark there
                -- would claim a position on a clock the reader has left
                \_ ->
                    [ Just (Cycle.days -2), Just (Cycle.hours 97), Nothing ]
                        |> List.map
                            (\m -> plannerAt m |> Query.hasNot [ Selector.class "is-here" ])
                        |> expectAll
            , test "and nothing is marked on the protocol's plain ruler" <|
                \_ -> protocol |> Query.hasNot [ Selector.class "is-here" ]
            , test "the legend names the stage as well as the hour" <|
                \_ ->
                    planner
                        |> Query.find [ Selector.class "legend" ]
                        |> Query.has [ Selector.text "Where you are — hour 41, Stage III" ]
            ]
        , describe "the scale"
            [ test "draws a segment for every stage regardless of target" <|
                -- the 72 h ruler still draws Stage V: the scale is the
                -- protocol's whole clock, not the target
                \_ ->
                    planner
                        |> Query.findAll [ Selector.class "rlbl" ]
                        |> Query.count (Expect.equal (List.length Cycle.stages))
            ]
        ]


{-| The numeral of the stage an hour falls in, read off `Clock` rather
than restated — the point of the check is that the ruler agrees with
the clock, not that both agree with this test file.
-}
numeralAt : Int -> String
numeralAt minutes =
    (Clock.reading Cycle.T96 minutes).depth
        |> Maybe.map (.stage >> .numeral)
        |> Maybe.withDefault "—"


expectAll : List Expect.Expectation -> Expect.Expectation
expectAll expectations =
    Expect.all (List.map always expectations) ()


dedupe : List String -> List String
dedupe =
    List.foldl
        (\x acc ->
            if List.member x acc then
                acc

            else
                x :: acc
        )
        []
