module Page.Resources exposing (view)

{-| The source index, worn as a house document (`Doc.elm`). One entry
per reference in the protocol, each routed to the best copy a reader
can legally reach.

**Link-first, never rehost** (policy: docs/RESOURCES-POLICY.md,
owner's call 2026-08-16). The project used to plan a local PDF archive
under `public/resources/pdf/`; that plan is retired. Nothing here is
redistributed, so there is no licence to audit and no way to serve a
copy the publisher never permitted. Two things pushed the decision:
being free to *read* on PMC is not permission to *rehost*, and a
frozen PDF cannot tell a reader that its paper was later corrected —
this list already contains two corrected papers.

The manifest below is the single source of truth. Every DOI was
verified against CrossRef on title, journal, volume and page range;
every access state came from Unpaywall on 2026-08-16 and every
repository link was checked to resolve. Slugs survive the pivot as
per-entry anchors: `/resources#<slug>` is a permanent public address
for a single citation, which is what the slugs were always promising.

-}

import Doc
import Html exposing (Html, a, b, div, h3, p, span, text)
import Html.Attributes exposing (class, href, id, style, target)



-- MANIFEST


{-| How a reader actually reaches this source.

Two of these are free-to-read but carry no open licence, which is the
distinction that killed the archive plan: readable is not the same as
redistributable, and only `Open` entries would ever have been ours to
serve.

-}
type Access
    = -- version of record, free under an open licence; the DOI lands on it
      Open String
      -- free to read at the publisher, but under no open licence.
      -- "Bronze" access: the publisher can withdraw it without notice,
      -- so it is marked differently from a licensed copy on purpose.
    | FreeAtPublisher
      -- a free repository copy (PMC, an institutional archive) — usually
      -- the author manuscript, not the typeset version of record
    | Manuscript String
      -- a free document with no DOI at all (a prize citation, a society
      -- guidance page): its own page is the only address it has
    | Web String
      -- no free copy exists; the DOI is the only route
    | Paywalled


type alias Citation =
    { id : Int
    , slug : String
    , citation : String
    , evidence : String
    , doi : Maybe String
    , access : Access
    }


citations : List Citation
citations =
    [ Citation 1 "klionsky-autophagy-assay-guidelines-2021" "Klionsky DJ, et al. Guidelines for the use and interpretation of assays for monitoring autophagy (4th edition). Autophagy. 2021;17(1):1–382." "Methods" (Just "10.1080/15548627.2020.1797280") FreeAtPublisher
    , Citation 2 "nobel-2016-ohsumi" "The Nobel Assembly at Karolinska Institutet. The Nobel Prize in Physiology or Medicine 2016 — Yoshinori Ohsumi, for discoveries of mechanisms for autophagy." "Prize citation" Nothing (Web "https://www.nobelprize.org/prizes/medicine/2016/summary/")
    , Citation 3 "wolfson-sestrin2-leucine-2016" "Wolfson RL, Chantranupong L, Saxton RA, et al. Sestrin2 is a leucine sensor for the mTORC1 pathway. Science. 2016;351(6268):43–48." "Cell" (Just "10.1126/science.aab2674") (Manuscript "https://hdl.handle.net/1721.1/107960")
    , Citation 4 "grundler-blood-pressure-fasting-2020" "Grundler F, Mesnage R, Michalsen A, Wilhelmi de Toledo F. Blood pressure changes in 1610 subjects with and without antihypertensive medication during long-term fasting. J Am Heart Assoc. 2020;9(23)." "Human" (Just "10.1161/JAHA.120.018649") (Open "CC BY-NC-ND")
    , Citation 5 "wilhelmi-de-toledo-fasting-safety-2019" "Wilhelmi de Toledo F, Grundler F, Bergouignan A, Drinda S, Michalsen A. Safety, health improvement and well-being during a 4 to 21-day fasting period in an observational study including 1422 subjects. PLoS ONE. 2019;14(1):e0209353." "Human, observational" (Just "10.1371/journal.pone.0209353") (Open "CC BY")
    , Citation 6 "brandhorst-fmd-regeneration-2015" "Brandhorst S, Choi IY, Wei M, et al. A periodic diet that mimics fasting promotes multi-system regeneration, enhanced cognitive performance, and healthspan. Cell Metab. 2015;22(1):86–99." "Mouse + human" (Just "10.1016/j.cmet.2015.05.012") FreeAtPublisher
    , Citation 7 "wei-fmd-markers-2017" "Wei M, Brandhorst S, Shelehchi M, et al. Fasting-mimicking diet and markers/risk factors for aging, diabetes, cancer, and cardiovascular disease. Sci Transl Med. 2017;9(377):eaai8700." "Human RCT" (Just "10.1126/scitranslmed.aai8700") (Manuscript "https://pmc.ncbi.nlm.nih.gov/articles/PMC6816332/")
    , Citation 8 "cheng-fasting-hsc-regeneration-2014" "Cheng CW, Adams GB, Perin L, et al. Prolonged fasting reduces IGF-1/PKA to promote hematopoietic-stem-cell-based regeneration and reverse immunosuppression. Cell Stem Cell. 2014;14(6):810–823." "Mouse + phase I" (Just "10.1016/j.stem.2014.04.014") (Manuscript "https://pmc.ncbi.nlm.nih.gov/articles/PMC4102383/")
    , Citation 9 "eisenberg-spermidine-longevity-2009" "Eisenberg T, Knauer H, Schauer A, et al. Induction of autophagy by spermidine promotes longevity. Nat Cell Biol. 2009;11(11):1305–1314." "Yeast, fly, mouse" (Just "10.1038/ncb1975") FreeAtPublisher
    , Citation 10 "eisenberg-spermidine-cardioprotection-2016" "Eisenberg T, Abdellatif M, Schroeder S, et al. Cardioprotection and lifespan extension by the natural polyamine spermidine. Nat Med. 2016;22(12):1428–1438." "Mouse + epidemiology" (Just "10.1038/nm.4222") (Manuscript "https://pmc.ncbi.nlm.nih.gov/articles/PMC5806691/")
    , Citation 11 "madeo-spermidine-health-2018" "Madeo F, Eisenberg T, Pietrocola F, Kroemer G. Spermidine in health and disease. Science. 2018;359(6374):eaan2788." "Review" (Just "10.1126/science.aan2788") Paywalled
    , Citation 12 "pietrocola-polyphenols-acetylation-2012" "Pietrocola F, Mariño G, Lissa D, et al. Pro-autophagic polyphenols reduce the acetylation of cytoplasmic proteins. Cell Cycle. 2012;11(20):3851–3860." "Cell" (Just "10.4161/cc.22027") FreeAtPublisher
    , Citation 13 "mehanna-refeeding-syndrome-2008" "Mehanna HM, Moledina J, Travis J. Refeeding syndrome: what it is, and how to prevent and treat it. BMJ. 2008;336(7659):1495–1498." "Clinical review" (Just "10.1136/bmj.a301") Paywalled
    , Citation 14 "pietrocola-coffee-autophagy-2014" "Pietrocola F, Malik SA, Mariño G, et al. Coffee induces autophagy in vivo. Cell Cycle. 2014;13(12):1987–1994." "Mouse" (Just "10.4161/cc.28929") FreeAtPublisher
    , Citation 15 "he-exercise-autophagy-2012" "He C, Bassik MC, Moresi V, et al. Exercise-induced BCL2-regulated autophagy is required for muscle glucose homeostasis. Nature. 2012;481(7382):511–515. (A corrigendum accompanies this paper and should be read alongside it: Nature. 2013;503:146.)" "Mouse" (Just "10.1038/nature10758") Paywalled
    , Citation 16 "de-cabo-intermittent-fasting-2019" "de Cabo R, Mattson MP. Effects of intermittent fasting on health, aging, and disease. N Engl J Med. 2019;381(26):2541–2551." "Review" (Just "10.1056/NEJMra1905136") Paywalled
    , Citation 17 "cahill-fuel-metabolism-starvation-2006" "Cahill GF Jr. Fuel metabolism in starvation. Annu Rev Nutr. 2006;26:1–22." "Human, classic" (Just "10.1146/annurev.nutr.26.061505.111258") Paywalled
    , Citation 18 "asa-glp1-preoperative-guidance-2023" "American Society of Anesthesiologists. Consensus-based guidance on preoperative management of patients (adults and children) on glucagon-like peptide-1 (GLP-1) receptor agonists. ASA; 2023." "Clinical guidance" Nothing (Web "https://www.asahq.org/about-asa/newsroom/news-releases/2023/06/american-society-of-anesthesiologists-consensus-based-guidance-on-preoperative")
    , Citation 19 "look-surmount1-body-composition-2025" "Look M, et al. Body composition changes during weight reduction with tirzepatide in the SURMOUNT-1 study of adults with obesity or overweight. Diabetes Obes Metab. 2025. (Read alongside its published correction.)" "Human RCT substudy" (Just "10.1111/dom.16275") (Open "CC BY-NC-ND")
    ]


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
    List.length (List.filter isReachable citations)



-- VIEW


view : Html msg
view =
    Doc.view
        { tag = "Source Index"
        , kicker = String.fromInt reachableCount ++ " of " ++ String.fromInt (List.length citations) ++ " free to read"
        , rev = "Rev. 3"
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
              , intent = "19 entries · access marked"
              , body = Doc.Panel (List.map viewCitation citations)
              }
            ]
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
            [ h3 [] [ text c.citation ]
            , p [ class "meta" ] [ text ("Evidence class: " ++ c.evidence) ]
            , div [ class "links" ] (accessLinks c)
            ]
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
