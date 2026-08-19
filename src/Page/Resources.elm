module Page.Resources exposing (view)

{-| The source index, worn as a house document (`Doc.elm`). One entry
per reference in the protocol, each routed to the best copy a reader
can legally reach.

**Link-first, never rehost** (policy: docs/RESOURCES-POLICY.md,
owner's call 2026-08-16). The project used to plan a local PDF archive
under `public/resources/pdf/`; that plan is retired. Nothing here is
redistributed, so there is no licence to audit and no way to serve a
copy the publisher never permitted. Two things pushed the decision:
being free to _read_ on PMC is not permission to _rehost_, and a
frozen PDF cannot tell a reader that its paper was later corrected —
this list already contains two corrected papers.

The manifest itself moved to `Citations.elm` on 2026-08-18: the
protocol's §12 reference list had been a second hand-written copy of
these nineteen entries, and the two had already drifted apart on which
papers carry corrections. This module is now a view over that data —
plus the one thing it owns, which is what each access state means for
a reader about to click.

Slugs survive as per-entry anchors: `/resources#<slug>` is a permanent
public address for a single citation, which is what the slugs were
always promising — and now also where every `[13]` in the protocol
points.

-}

import Citations exposing (Access(..), Citation)
import Doc
import Html exposing (Html, a, b, div, h3, p, span, text)
import Html.Attributes exposing (class, href, id, style, target)



-- COUNTS


{-| Free to reach without a subscription — everything but `Paywalled`.
-}
isReachable : Citation -> Bool
isReachable c =
    case c.access of
        Paywalled ->
            False

        _ ->
            True


reachableCount : Int
reachableCount =
    List.length (List.filter isReachable Citations.all)



-- VIEW


view : Maybe String -> Html msg
view active =
    Doc.view
        { tag = "Source Index"
        , kicker = String.fromInt reachableCount ++ " of " ++ String.fromInt (List.length Citations.all) ++ " free to read"
        , rev = "Rev. 3"
        , revDate = "2026-08-16"
        , titleLines = [ "Primary", "sources" ]
        , standfirst = "Every citation in the protocol, routed to the best copy you can legally reach — the open version of record where one exists, a repository manuscript where it does not, and the publisher's own page for the rest. Nothing is rehosted here."
        , sections =
            [ { anchor = "sec-policy"
              , tocLabel = "Policy"
              , title = "How this index works"
              , intent = "Linked, never rehosted"
              , body = Doc.Clauses secPolicy
              }
            , { anchor = "sec-index"
              , tocLabel = "The sources"
              , title = "The sources"
              , intent = String.fromInt (List.length Citations.all) ++ " entries · access marked"
              , body = Doc.Panel (List.map viewCitation Citations.all)
              }
            ]
        , active = active
        , footNote =
            -- the medical disclaimer ships on every content page
            -- (DESIGN-REQUIREMENTS §5), the index note after it
            [ p [ style "margin" "0 0 .4rem" ]
                [ b [] [ text "This is general information, not medical advice, and I'm not a doctor." ]
                , text " Prolonged fasting carries real risk that varies enormously with your individual health, medications and history. Talk to a physician before your first cycle. Full "
                , a [ href "/legal" ] [ text "terms and disclaimers" ]
                , text "."
                ]
            , p [ style "margin" "0" ]
                [ text "Each entry has a permanent address of its own — "
                , span [ class "mono", style "font-size" ".8rem" ] [ text "/resources#<slug>" ]
                , text ". Full policy: docs/RESOURCES-POLICY.md."
                ]
            ]
        }


secPolicy : List (Html msg)
secPolicy =
    [ p [ style "font-size" ".9rem" ]
        [ b [] [ text "Nothing on this page is a rehosted copy." ]
        , text " Every entry links out to the publisher, a repository, or the document's own page. That is a deliberate position, not a gap waiting to be filled: a link carries no redistribution question, and it always resolves to the "
        , span [ style "font-style" "italic" ] [ text "current" ]
        , text " state of the record — including corrections. Two papers below have been corrected since publication, which a frozen local copy would quietly hide."
        ]
    , p [ style "font-size" ".9rem" ]
        [ text "The access mark on each entry says what you will actually hit. "
        , span [ class "access-tag is-open" ] [ text "Open access" ]
        , text " is the version of record under an open licence. "
        , span [ class "access-tag is-free" ] [ text "Free at publisher" ]
        , text " is readable today but carries no licence, so it can be withdrawn without notice. "
        , span [ class "access-tag is-free" ] [ text "Manuscript" ]
        , text " is a repository copy — free, but usually the author's accepted version rather than the typeset paper. "
        , span [ class "access-tag is-closed" ] [ text "Paywalled" ]
        , text " means no free copy exists and the DOI is the only route."
        ]
    , p [ style "font-size" ".9rem" ]
        [ text "DOIs were verified against CrossRef on title, journal, volume and page range — not by title match alone, which returns commentaries and corrigenda as readily as papers. Access states came from Unpaywall. Both were checked on 2026-08-16 and neither is guaranteed to stay true: publishers move things. If a link here is dead, "
        , a [ href "https://github.com/curtisault/autophagous/issues", target "_blank" ] [ text "say so" ]
        , text "."
        ]
    ]


viewCitation : Citation -> Html msg
viewCitation c =
    div [ class "resource", id c.slug ]
        [ span [ class "rid" ] [ text ("[" ++ String.padLeft 2 '0' (String.fromInt c.id) ++ "]") ]
        , div []
            [ h3 [] (Citations.line c)
            , p [ class "meta" ] [ text ("Evidence class: " ++ c.evidence) ]
            , citedIn c
            , div [ class "links" ] (accessLinks c)
            ]
        ]


{-| Which claims this source is holding up.

The markers in the protocol point here; this points back. A citation
list that only goes one way tells a reader what was read, not what it
was read _for_ — and "cited in the refeed section" is the fastest way
to see whether a source is load-bearing for the part you are standing
in.

-}
citedIn : Citation -> Html msg
citedIn c =
    case Citations.citedBy c.id of
        [] ->
            text ""

        places ->
            p [ class "cited-in u" ]
                (text "Cited in "
                    :: List.intersperse (text " · ") (List.map placeLink places)
                )


placeLink : Citations.Site -> Html msg
placeLink site =
    a [ href ("/#" ++ site.anchor) ]
        [ span [ class "mono" ] [ text site.number ]
        , text ("\u{00A0}" ++ site.label)
        ]


{-| The tag and the routes out, in the order a reader wants them: what
kind of access this is, then the fastest way to the full text, then
the DOI as the durable address.
-}
accessLinks : Citation -> List (Html msg)
accessLinks c =
    let
        doiLink =
            case c.doi of
                Just doi ->
                    [ a [ href ("https://doi.org/" ++ doi), target "_blank" ] [ text ("doi:" ++ doi) ] ]

                Nothing ->
                    []
    in
    case c.access of
        Open license ->
            span [ class "access-tag is-open" ] [ text ("Open access · " ++ license) ] :: doiLink

        FreeAtPublisher ->
            span [ class "access-tag is-free" ] [ text "Free at publisher" ] :: doiLink

        Manuscript url ->
            span [ class "access-tag is-free" ] [ text "Manuscript" ]
                :: a [ href url, target "_blank" ] [ text "Free full text" ]
                :: doiLink

        Web url ->
            [ span [ class "access-tag is-open" ] [ text "Free" ]
            , a [ href url, target "_blank" ] [ text "Read it" ]
            ]

        Paywalled ->
            span [ class "access-tag is-closed" ] [ text "Paywalled" ] :: doiLink
