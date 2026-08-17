module Doc exposing (Body(..), Config, Section, view)

{-| The document format (DESIGN-PRINCIPLES §2a), after cryovault's
`Doc.elm`: the shared chrome every broadsheet page wears — the
masthead, the contents rail, section numbering, clause marks, and the
footer.

**The boundary: this module numbers and frames; the page renders.**
`Doc` knows nothing about rulers, cycle bars, or citation entries — a
page hands over its own body content and gets it back inside the
chrome. The moment `Doc` learns what a stage card is, it stops being a
format and starts being a page.

**Sections are one ordered list, and the contents rail is derived from
it.** A section number derived from a list cannot disagree with that
list — which is the point (cryovault learned this the hard way,
DECISIONS §14 over there). In-prose cross-references ("see §09") are
the one thing still maintained by hand, so reordering sections means
grepping for `§`.

Pure view: no `Cmd`, no scroll tracking. The rail's `#anchor` jumps
are carried out by the shell (`Main.elm` owns the viewport, because
`Browser.application` intercepts every internal link click).

-}

import Html exposing (Html, a, br, div, footer, h1, h2, header, nav, p, section, span, text)
import Html.Attributes exposing (attribute, class, href, id)


type alias Config msg =
    { tag : String -- the volt kicker tag (left)
    , kicker : String -- the kicker's middle line
    , rev : String -- the revision mark (right)
    , titleLines : List String -- the masthead h1, one entry per line
    , standfirst : String
    , sections : List (Section msg)
    , footNote : List (Html msg) -- the footer (the disclaimer, on content pages)
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
    div [ class "doc-layout" ]
        [ viewToc config
        , div [ class "sheet" ]
            (viewMasthead config
                :: List.indexedMap viewSection config.sections
                ++ [ footer [] config.footNote ]
            )
        ]



-- MASTHEAD


viewMasthead : Config msg -> Html msg
viewMasthead config =
    header [ class "masthead" ]
        [ div [ class "kicker u" ]
            [ span [ class "tag-volt" ] [ text config.tag ]
            , span [] [ text config.kicker ]
            , span [] [ text config.rev ]
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
            :: viewBody (i + 1) s.body
        )


viewBody : Int -> Body msg -> List (Html msg)
viewBody n body =
    case body of
        Panel items ->
            items

        Clauses items ->
            List.indexedMap (viewClause n) items


viewClause : Int -> Int -> Html msg -> Html msg
viewClause n i item =
    div [ class "doc-clause-row" ]
        [ span [ class "doc-clause-mark mono", attribute "aria-hidden" "true" ]
            [ text ("§" ++ String.fromInt n ++ "." ++ String.fromInt (i + 1)) ]
        , div [ class "doc-clause-body" ] [ item ]
        ]



-- THE CONTENTS RAIL


viewToc : Config msg -> Html msg
viewToc config =
    nav [ id "doc-toc", class "doc-toc", attribute "aria-label" "Contents" ]
        [ div [ class "doc-toc-inner" ]
            (span [ class "doc-toc-head u" ] [ text "Contents" ]
                :: List.indexedMap tocLink config.sections
            )
        ]


tocLink : Int -> Section msg -> Html msg
tocLink i s =
    a [ class "doc-toc-link", href ("#" ++ s.anchor) ]
        [ span [ class "doc-toc-num mono" ] [ text (sectionNum i) ]
        , span [ class "doc-toc-label u" ] [ text s.tocLabel ]
        ]
