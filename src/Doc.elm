module Doc exposing (Body(..), Chrome, Config, Section, view)

{-| The document format (DESIGN-PRINCIPLES §2a): the shared chrome
every broadsheet page wears — the
masthead, the contents rail, section numbering, clause marks, and the
footer.

**The boundary: this module numbers and frames; the page renders.**
`Doc` knows nothing about rulers, cycle bars, or citation entries — a
page hands over its own body content and gets it back inside the
chrome. The moment `Doc` learns what a stage card is, it stops being a
format and starts being a page.

**Sections are one ordered list, and the contents rail is derived from
it.** A section number derived from a list cannot disagree with that
list — which is the point, and was learned the hard way. In-prose
cross-references ("see §09") are
the one thing still maintained by hand, so reordering sections means
grepping for `§`.

Pure view: no `Cmd`, no scroll tracking. The rail's `#anchor` jumps
are carried out by the shell (`Main.elm` owns the viewport, because
`Browser.application` intercepts every internal link click).

-}

import Html exposing (Html, a, br, button, div, footer, h1, h2, header, input, nav, p, section, span, text)
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Search


type alias Config msg =
    { tag : String -- the volt kicker tag (left)
    , kicker : String -- the kicker's middle line
    , rev : String -- the revision mark (right)
    , revDate : String -- when that revision landed, ISO — set in the data voice
    , titleLines : List String -- the masthead h1, one entry per line
    , standfirst : String
    , sections : List (Section msg)
    , footNote : List (Html msg) -- the footer (the disclaimer, on content pages)
    , chrome : Chrome msg
    }


{-| The state the shell owns and every page wears: which section the
reader is in, and what they are searching for.

`active` arrives from boot.js through a port — Elm has no scroll
subscription. `query` turns the sheet into a result list, which is why
it lives here rather than on any one page: search is chrome, the same
as the contents rail it sits in.

-}
type alias Chrome msg =
    { active : Maybe String
    , query : String
    , onQuery : String -> msg
    }


{-| One numbered section: a jump anchor, a short label for the rail,
the section header proper, and the body. `intent` is the header's
small right-hand line — what this section is for, in a few words.
-}
type alias Section msg =
    { anchor : String
    , tocLabel : String
    , title : String
    , intent : String
    , body : Body msg
    }


{-| How a section's body is numbered.

  - `Clauses` — prose and rulings, so each top-level block earns a
    `§N.M` margin mark you can cite ("the potassium warning is §7.4").
  - `Panel` — apparatus with its own internal structure (the stage
    cards, the log grid, the reference list): numbered at section
    level only. Clause marks on a numbered list would be numbering
    for its own sake.

-}
type Body msg
    = Clauses (List (Html msg))
    | Panel (List (Html msg))


view : Config msg -> Html msg
view config =
    let
        searching =
            String.trim config.chrome.query /= ""

        hits =
            Search.run config.chrome.query
    in
    div [ class "doc-layout" ]
        [ viewToc config searching (List.length hits)
        , div [ class "sheet" ]
            (viewMasthead config
                :: (if searching then
                        [ viewResults hits ]

                    else
                        List.indexedMap viewSection config.sections
                   )
                ++ [ footer [] config.footNote ]
            )
        ]


{-| Searching replaces the sheet's sections rather than floating a
panel over them. The document is what is being searched, so the
document becomes the answer — and the results get the full measure
instead of the rail's 13rem.
-}
viewResults : List Search.Entry -> Html msg
viewResults hits =
    section [ id "sec-results" ]
        (div [ class "sec-head" ]
            [ span [ class "sec-num u" ]
                [ text (String.padLeft 2 '0' (String.fromInt (List.length hits))) ]
            , h2 []
                [ text
                    (if List.isEmpty hits then
                        "Nothing found"

                     else
                        "Results"
                    )
                ]
            , span [ class "sec-intent u" ] [ text "Across every page" ]
            ]
            :: (if List.isEmpty hits then
                    [ p [ class "hit-none" ]
                        [ text "No section, instrument or source matches that. The contents rail comes back when the box is empty." ]
                    ]

                else
                    List.map viewHit hits
               )
        )


viewHit : Search.Entry -> Html msg
viewHit hit =
    a [ class "hit", href (Search.address hit) ]
        [ span [ class "hit-page u" ] [ text hit.page ]
        , div []
            [ span [ class "hit-label" ] [ text hit.label ]
            , span [ class "hit-blurb" ] [ text hit.blurb ]
            ]
        ]



-- MASTHEAD


viewMasthead : Config msg -> Html msg
viewMasthead config =
    header [ class "masthead" ]
        [ div [ class "kicker u" ]
            [ span [ class "tag-volt" ] [ text config.tag ]
            , span [] [ text config.kicker ]
            , span [ class "rev" ]
                [ text config.rev
                , span [ class "rev-date mono" ] [ text config.revDate ]
                ]
            ]
        , h1 []
            (config.titleLines
                |> List.map text
                |> List.intersperse (br [] [])
            )
        , p [ class "standfirst" ] [ text config.standfirst ]
        ]



-- SECTIONS


sectionNum : Int -> String
sectionNum i =
    String.padLeft 2 '0' (String.fromInt (i + 1))


viewSection : Int -> Section msg -> Html msg
viewSection i s =
    section [ id s.anchor ]
        (div [ class "sec-head" ]
            [ span [ class "sec-num u" ] [ text (sectionNum i) ]
            , h2 [] [ text s.title ]
            , span [ class "sec-intent u" ] [ text s.intent ]
            ]
            :: viewBody s.anchor (i + 1) s.body
        )


viewBody : String -> Int -> Body msg -> List (Html msg)
viewBody anchor n body =
    case body of
        Panel items ->
            items

        Clauses items ->
            List.indexedMap (viewClause anchor n) items


{-| A clause, and its own address.

The `§N.M` mark was decorative — `aria-hidden`, unlinked — while the
prose beside it invited readers to cite "the potassium warning is
§7.4". It is a link now, so that sentence has somewhere to point.

**The id is built from the anchor, not the number.** `§7.4` is derived
from where the section sits in a list, so reordering the document
would silently repoint every link ever shared; `sec-fast-4` survives
it. What the reader copies is the address bar, the same as everywhere
else here — no clipboard, no port, no permission prompt.

-}
viewClause : String -> Int -> Int -> Html msg -> Html msg
viewClause anchor n i item =
    let
        mark =
            "§" ++ String.fromInt n ++ "." ++ String.fromInt (i + 1)

        address =
            anchor ++ "-" ++ String.fromInt (i + 1)
    in
    div [ class "doc-clause-row", id address ]
        [ a
            [ class "doc-clause-mark mono"
            , href ("#" ++ address)
            , title ("Link to " ++ mark)
            , attribute "aria-label" ("Link to " ++ mark)
            ]
            [ text mark ]
        , div [ class "doc-clause-body" ] [ item ]
        ]



-- THE CONTENTS RAIL


viewToc : Config msg -> Bool -> Int -> Html msg
viewToc config searching found =
    nav [ id "doc-toc", class "doc-toc", attribute "aria-label" "Contents" ]
        [ div [ class "doc-toc-inner" ]
            (viewSearch config.chrome
                :: (if searching then
                        -- the results are in the sheet, at full width;
                        -- repeating them here would be the same list twice
                        [ span [ class "doc-toc-head u" ]
                            [ text (String.fromInt found ++ " found") ]
                        ]

                    else
                        span [ class "doc-toc-head u" ] [ text "Contents" ]
                            :: List.indexedMap (tocLink config.chrome.active) config.sections
                   )
            )
        ]


{-| The box, in the rail, because searching is navigation and the rail
is where navigation lives. It is a ruled cell like every other control
here (DESIGN-REQUIREMENTS §1).

Below 60rem the rail keeps this and drops everything else: the section
list became a horizontal scroller nobody wanted, and on a phone the
box does its job (DESIGN-PRINCIPLES §2b).

-}
viewSearch : Chrome msg -> Html msg
viewSearch chrome =
    div [ class "doc-search" ]
        [ input
            [ type_ "search"
            , class "doc-search-input"
            , value chrome.query
            , placeholder "Search"
            , attribute "aria-label" "Search the document"
            , onInput chrome.onQuery
            ]
            []
        , if String.trim chrome.query == "" then
            text ""

          else
            button
                [ type_ "button"
                , class "doc-search-clear u"
                , attribute "aria-label" "Clear the search"
                , onClick (chrome.onQuery "")
                ]
                [ text "Clear" ]
        ]


{-| A rail row, marked when the reader is inside its section. The mark
is the persistent form of the row's own hover — a volt bar under the
label — because "where you are" and "where this would take you" are
the same fact.
-}
tocLink : Maybe String -> Int -> Section msg -> Html msg
tocLink active i s =
    let
        here =
            active == Just s.anchor
    in
    a
        [ class "doc-toc-link"
        , classList [ ( "is-active", here ) ]
        , href ("#" ++ s.anchor)
        , attribute "aria-current"
            (if here then
                "true"

             else
                "false"
            )
        ]
        [ span [ class "doc-toc-num mono" ] [ text (sectionNum i) ]
        , span [ class "doc-toc-label u" ] [ text s.tocLabel ]
        ]
