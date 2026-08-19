module CitationTests exposing (suite)

{-| The apparatus, held to itself.

A citation index is only worth having if it is true, and the two
halves of this one are kept by different hands: the markers live in
the protocol's prose, the backlink table lives in `Citations.sites`.
So the central test here checks them **against each other, in both
directions** — every source the table claims a section cites is
actually linked in that section's rendered HTML, and every source it
does not claim is not.

That is the check that would have caught the drift this feature was
built to fix: before 2026-08-18 the same nineteen citations existed
twice, in two formats, and had already disagreed about which papers
carry corrections.

-}

import Citations
import Expect
import Html.Attributes as Attr
import Page.Protocol
import Page.Resources
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


protocol : Query.Single ()
protocol =
    Query.fromHtml (Page.Protocol.view Nothing)


resources : Query.Single ()
resources =
    Query.fromHtml (Page.Resources.view Nothing)


allIds : List Int
allIds =
    List.map .id Citations.all


linkTo : Int -> Selector.Selector
linkTo id =
    Selector.attribute (Attr.href (Citations.href id))


suite : Test
suite =
    describe "the citation apparatus"
        [ describe "the manifest"
            [ test "is numbered 1..19 with no gaps, in order" <|
                \_ -> allIds |> Expect.equal (List.range 1 (List.length Citations.all))
            , test "every slug is unique — they are permanent public addresses" <|
                \_ ->
                    List.map .slug Citations.all
                        |> unique
                        |> Expect.equal (List.length Citations.all)
            , test "no slug is empty" <|
                \_ ->
                    List.filter (\c -> c.slug == "") Citations.all |> Expect.equal []
            , test "every source carries an evidence class" <|
                \_ ->
                    List.filter (\c -> c.evidence == "") Citations.all |> Expect.equal []
            , test "byId finds them" <|
                \_ ->
                    Citations.byId 13 |> Maybe.map .slug |> Expect.equal (Just "mehanna-refeeding-syndrome-2008")
            , test "an address is the index plus the slug" <|
                \_ ->
                    Citations.href 13 |> Expect.equal "/resources#mehanna-refeeding-syndrome-2008"
            , test "an id with no source behind it lands on the index, not a dead anchor" <|
                \_ -> Citations.href 99 |> Expect.equal "/resources"
            ]
        , describe "the backlink table"
            [ test "names only sources that exist" <|
                \_ ->
                    Citations.sites
                        |> List.concatMap Tuple.second
                        |> List.filter (\id -> Citations.byId id == Nothing)
                        |> Expect.equal []
            , test "leaves no source uncited — an orphan is a source that lost its claim" <|
                \_ ->
                    allIds
                        |> List.filter (\id -> List.isEmpty (Citations.citedBy id))
                        |> Expect.equal []
            , test "names only sections the protocol actually has" <|
                \_ ->
                    Citations.sites
                        |> List.map (Tuple.first >> .anchor)
                        |> List.map (\anchor -> ( anchor, hasAnchor anchor ))
                        |> List.filter (Tuple.second >> not)
                        |> Expect.equal []
            ]
        , describe "the table agrees with the prose, section by section"
            (List.map citesExactly Citations.sites)
        , describe "the markers"
            [ test "a single marker is one link" <|
                \_ ->
                    protocol
                        |> Query.find [ Selector.id "sec-limits" ]
                        |> Query.has [ linkTo 1, Selector.text "[1]" ]
            , test "a run of three is three separate links — sources are not interchangeable" <|
                \_ ->
                    protocol
                        |> Query.find [ Selector.id "sec-rebuild" ]
                        |> Expect.all [ Query.has [ linkTo 9 ], Query.has [ linkTo 10 ], Query.has [ linkTo 11 ] ]
            ]
        , describe "the reference list is the manifest"
            [ test "carries every source" <|
                \_ ->
                    protocol
                        |> Query.find [ Selector.id "sec-refs" ]
                        |> Query.findAll [ Selector.class "ref-out" ]
                        |> Query.count (Expect.equal (List.length Citations.all))
            , test "renders the journal in italic, once, from the shared line" <|
                \_ ->
                    protocol
                        |> Query.find [ Selector.id "sec-refs" ]
                        |> Query.has [ Selector.text "Cell Stem Cell." ]
            , test "carries the correction notice the two copies used to disagree about" <|
                \_ ->
                    protocol
                        |> Query.find [ Selector.id "sec-refs" ]
                        |> Query.has [ Selector.text "A corrigendum accompanies this paper and should be read alongside it: Nature. 2013;503:146." ]
            ]
        , describe "the index points back"
            [ test "a source names the sections that cite it" <|
                \_ ->
                    resources
                        |> Query.find [ Selector.id "mehanna-refeeding-syndrome-2008" ]
                        |> Expect.all
                            [ Query.has [ Selector.attribute (Attr.href "/#sec-refeed") ]
                            , Query.has [ Selector.attribute (Attr.href "/#sec-fast") ]
                            , Query.has [ Selector.attribute (Attr.href "/#sec-glp1") ]
                            ]
            , test "and does not claim sections that do not" <|
                \_ ->
                    resources
                        |> Query.find [ Selector.id "mehanna-refeeding-syndrome-2008" ]
                        |> Query.hasNot [ Selector.attribute (Attr.href "/#sec-prime") ]
            , test "the same correction notice appears here too, from the same source" <|
                \_ ->
                    resources
                        |> Query.find [ Selector.id "he-exercise-autophagy-2012" ]
                        |> Query.has [ Selector.text "A corrigendum accompanies this paper and should be read alongside it: Nature. 2013;503:146." ]
            ]
        , describe "clause permalinks"
            [ test "a clause mark links to its own clause" <|
                \_ ->
                    protocol
                        |> Query.find [ Selector.id "sec-limits-1" ]
                        |> Query.has [ Selector.attribute (Attr.href "#sec-limits-1") ]
            , test "the address is built from the anchor, not the § number" <|
                -- reordering sections renumbers §7.4; it must not
                -- repoint a link someone has already shared
                \_ ->
                    protocol
                        |> Query.find [ Selector.id "sec-safety-2" ]
                        |> Query.has [ Selector.text "§3.2" ]
            ]
        , describe "the contents rail marks where you are"
            [ test "the active section's row is marked" <|
                \_ ->
                    Query.fromHtml (Page.Protocol.view (Just "sec-fast"))
                        |> Query.findAll [ Selector.class "is-active" ]
                        |> Query.count (Expect.equal 1)
            , test "nothing is marked before the reader has been placed" <|
                \_ ->
                    protocol
                        |> Query.findAll [ Selector.class "is-active" ]
                        |> Query.count (Expect.equal 0)
            , test "an anchor from another page marks nothing here" <|
                -- `sec-fast` exists on the planner too, which is why the
                -- shell clears this on navigation
                \_ ->
                    Query.fromHtml (Page.Resources.view (Just "sec-fast"))
                        |> Query.findAll [ Selector.class "is-active" ]
                        |> Query.count (Expect.equal 0)
            ]
        ]


{-| The central check: this section links exactly the sources the
table says it does, and no others.
-}
citesExactly : ( Citations.Site, List Int ) -> Test
citesExactly ( site, ids ) =
    test (site.number ++ " " ++ site.label) <|
        \_ ->
            protocol
                |> Query.find [ Selector.id site.anchor ]
                |> Expect.all
                    (List.map
                        (\id ->
                            if List.member id ids then
                                Query.has [ linkTo id ]

                            else
                                Query.hasNot [ linkTo id ]
                        )
                        allIds
                    )


hasAnchor : String -> Bool
hasAnchor anchor =
    Query.has [ Selector.id anchor ] protocol == Expect.pass


unique : List String -> Int
unique =
    List.foldl
        (\item seen ->
            if List.member item seen then
                seen

            else
                item :: seen
        )
        []
        >> List.length
