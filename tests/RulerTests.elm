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
    Query.fromHtml
        (Ruler.view
            { target = Cycle.T96
            , now = Just (Cycle.hours 41)
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
                                (Attr.attribute "aria-label" "Stage III — Climbing, 24–48 h")
                            ]
            , test "a segment is drawn for every stage, at both targets" <|
                -- the 72 h ruler still draws Stage V: the scale is the
                -- protocol's whole clock, not the target
                \_ ->
                    planner
                        |> Query.findAll [ Selector.class "rlbl" ]
                        |> Query.count (Expect.equal (List.length Cycle.stages))
            ]
        ]


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
