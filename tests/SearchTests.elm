module SearchTests exposing (suite)

{-| The index is hand-written, so it is held to the pages in both
directions: every `term` has to be in the section it claims, and every
`alias` has to not be.

The second half is the one that matters. An alias is a word a reader
would type that the prose does not use — "ozempic" for §04, "salt" for
§07 — and the moment one of them turns out to be in the text, it is
not an alias, it is a term, and the distinction has stopped meaning
anything. That is how a curated index rots.

-}

import Cycle
import Doc
import Html.Attributes as Attr
import Dose
import Expect
import Page.Dosing
import Page.Legal
import Page.Plan
import Page.Protocol
import Page.Resources
import Search
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Time


chrome : Doc.Chrome ()
chrome =
    { active = Nothing, query = "", onQuery = always () }


{-| The protocol page as it renders while a search is open.
-}
searched : String -> Query.Single ()
searched query =
    Query.fromHtml (Page.Protocol.view { chrome | query = query })


pageAt : String -> Query.Single ()
pageAt path =
    Query.fromHtml <|
        case path of
            "/plan" ->
                Page.Plan.view
                    { zone = Time.utc
                    , start = Nothing
                    , now = Nothing
                    , startValue = ""
                    , target = Cycle.T72
                    , download = Nothing
                    , doseSource = Dose.Kcl
                    , doseServings = 4
                    , dosingHref = "/dosing?k=kcl&per=4"
                    , chrome = chrome
                    , onStart = always ()
                    , onTarget = always ()
                    }

            "/dosing" ->
                Page.Dosing.view
                    { source = Dose.Kcl
                    , servings = 4
                    , chrome = chrome
                    , onSource = always ()
                    , onServings = always ()
                    }

            "/resources" ->
                Page.Resources.view chrome

            "/legal" ->
                Page.Legal.view chrome

            _ ->
                Page.Protocol.view chrome


{-| `Selector.text` matches a substring of one text node, case
sensitively — so a term is present if it reads as written or with its
first letter capitalised, which is how the same word appears in a
table heading and in the prose under it.
-}
appearsIn : Query.Single () -> String -> Bool
appearsIn section term =
    List.any
        (\form -> Query.has [ Selector.text form ] section == Expect.pass)
        [ term, capitalise term, String.toLower term ]


capitalise : String -> String
capitalise word =
    String.toUpper (String.left 1 word) ++ String.dropLeft 1 word


sectionOf : Search.Entry -> Query.Single ()
sectionOf entry =
    Query.find [ Selector.id entry.anchor ] (pageAt entry.path)


suite : Test
suite =
    describe "Search"
        [ describe "every term is in the section it claims"
            (List.map
                (\entry ->
                    test (entry.page ++ " · " ++ entry.label) <|
                        \_ ->
                            entry.terms
                                |> List.filter (appearsIn (sectionOf entry) >> not)
                                |> Expect.equal []
                )
                Search.curated
            )
        , describe "and every alias is not — or it would be a term"
            (List.map
                (\entry ->
                    test (entry.page ++ " · " ++ entry.label) <|
                        \_ ->
                            entry.aliases
                                |> List.filter (appearsIn (sectionOf entry))
                                |> Expect.equal []
                )
                Search.curated
            )
        , describe "the matcher"
            [ test "a blank query finds nothing, rather than everything" <|
                \_ -> Search.run "   " |> Expect.equal []
            , test "a term finds its section" <|
                \_ ->
                    Search.run "spermidine"
                        |> List.head
                        |> Maybe.map .anchor
                        |> Expect.equal (Just "sec-prime")
            , test "an alias finds a section that never says the word" <|
                -- the reader knows the brand name, the protocol names
                -- the molecule
                \_ ->
                    Search.run "ozempic"
                        |> List.head
                        |> Maybe.map .anchor
                        |> Expect.equal (Just "sec-glp1")
            , test "it does not care about case" <|
                \_ ->
                    Search.run "AMPK"
                        |> List.map .anchor
                        |> Expect.equal (List.map .anchor (Search.run "ampk"))
            , test "a second word narrows rather than widens" <|
                \_ ->
                    let
                        loose =
                            List.length (Search.run "potassium")

                        tight =
                            List.length (Search.run "potassium divided")
                    in
                    (tight < loose && tight > 0) |> Expect.equal True
            , test "a word in nothing finds nothing" <|
                \_ -> Search.run "zzzzq" |> Expect.equal []
            , test "sources are searchable by author, with no index to keep" <|
                \_ ->
                    Search.run "mehanna"
                        |> List.head
                        |> Maybe.map .anchor
                        |> Expect.equal (Just "mehanna-refeeding-syndrome-2008")
            , test "and by journal" <|
                \_ ->
                    Search.run "BMJ"
                        |> List.map .anchor
                        |> List.member "mehanna-refeeding-syndrome-2008"
                        |> Expect.equal True
            , test "single letters are ignored, so a stray keystroke does not empty the results" <|
                \_ ->
                    Search.run "potassium x"
                        |> List.length
                        |> Expect.equal (List.length (Search.run "potassium"))
            ]
        , describe "searching replaces the sheet"
            -- the query lives in the model rather than the URL, so a
            -- headless browser cannot reach this state; rendering the
            -- view directly is the only way to hold it
            [ test "the results are in the sheet, at full measure" <|
                \_ ->
                    searched "spermidine"
                        |> Query.findAll [ Selector.class "hit" ]
                        |> Query.count (Expect.greaterThan 0)
            , test "and the document's own sections are not" <|
                -- a result list floating over the page it came from
                -- would be two documents at once
                \_ -> searched "spermidine" |> Query.hasNot [ Selector.id "sec-limits" ]
            , test "the first hit is the section that has the word" <|
                \_ ->
                    searched "spermidine"
                        |> Query.findAll [ Selector.class "hit" ]
                        |> Query.first
                        |> Query.has [ Selector.attribute (Attr.href "/#sec-prime") ]
            , test "a query that finds nothing says so, rather than showing an empty page" <|
                \_ ->
                    searched "zzzzq"
                        |> Query.has [ Selector.text "Nothing found" ]
            , test "the rail counts what was found instead of listing it twice" <|
                \_ ->
                    searched "spermidine"
                        |> Query.find [ Selector.id "doc-toc" ]
                        |> Query.hasNot [ Selector.class "doc-toc-link" ]
            , test "the box holds what was typed" <|
                \_ ->
                    searched "spermidine"
                        |> Query.find [ Selector.class "doc-search-input" ]
                        |> Query.has [ Selector.attribute (Attr.value "spermidine") ]
            , test "and offers a way out of it" <|
                \_ -> searched "spermidine" |> Query.has [ Selector.class "doc-search-clear" ]
            , test "an empty box leaves the document alone" <|
                \_ ->
                    searched ""
                        |> Expect.all
                            [ Query.has [ Selector.id "sec-limits" ]
                            , Query.hasNot [ Selector.class "hit" ]
                            , Query.hasNot [ Selector.class "doc-search-clear" ]
                            ]
            , test "whitespace is not a search" <|
                \_ -> searched "   " |> Query.has [ Selector.id "sec-limits" ]
            ]
        , describe "addresses"
            [ test "a section hit carries its anchor" <|
                \_ ->
                    Search.run "spermidine"
                        |> List.head
                        |> Maybe.map Search.address
                        |> Expect.equal (Just "/#sec-prime")
            , test "every entry names a page the site has" <|
                \_ ->
                    Search.index
                        |> List.map .path
                        |> List.filter (\path -> not (List.member path [ "/", "/plan", "/dosing", "/resources", "/legal" ]))
                        |> Expect.equal []
            ]
        ]
