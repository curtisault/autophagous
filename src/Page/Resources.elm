module Page.Resources exposing (view)

{-| The citations archive, worn as a house document (`Doc.elm`). One
entry per reference in the protocol, each carrying a slot for a
locally-archived PDF so the sources outlive link rot. The manifest
below is the single source of truth: the `archived` flag flips to True
when the PDF lands in `public/resources/pdf/<slug>.pdf` (policy:
docs/RESOURCES-ARCHIVE.md).
-}

import Doc
import Html exposing (Html, a, b, div, h3, p, span, text)
import Html.Attributes exposing (class, href, style, target)



-- MANIFEST


type alias Citation =
    { id : Int
    , slug : String
    , citation : String
    , evidence : String
    , doi : Maybe String
    , archived : Bool
    }


citations : List Citation
citations =
    [ Citation 1 "klionsky-autophagy-assay-guidelines-2021" "Klionsky DJ, et al. Guidelines for the use and interpretation of assays for monitoring autophagy (4th edition). Autophagy. 2021;17(1):1–382." "Methods" Nothing False
    , Citation 2 "nobel-2016-ohsumi" "The Nobel Assembly at Karolinska Institutet. The Nobel Prize in Physiology or Medicine 2016 — Yoshinori Ohsumi, for discoveries of mechanisms for autophagy." "Prize citation" Nothing False
    , Citation 3 "wolfson-sestrin2-leucine-2016" "Wolfson RL, Chantranupong L, Saxton RA, et al. Sestrin2 is a leucine sensor for the mTORC1 pathway. Science. 2016;351(6268):43–48." "Cell" Nothing False
    , Citation 4 "grundler-blood-pressure-fasting-2020" "Grundler F, Mesnage R, Michalsen A, Wilhelmi de Toledo F. Blood pressure changes in 1610 subjects with and without antihypertensive medication during long-term fasting. J Am Heart Assoc. 2020;9(23)." "Human" Nothing False
    , Citation 5 "wilhelmi-de-toledo-fasting-safety-2019" "Wilhelmi de Toledo F, Grundler F, Bergouignan A, Drinda S, Michalsen A. Safety, health improvement and well-being during a 4 to 21-day fasting period in an observational study including 1422 subjects. PLoS ONE. 2019;14(1):e0209353." "Human, observational" Nothing False
    , Citation 6 "brandhorst-fmd-regeneration-2015" "Brandhorst S, Choi IY, Wei M, et al. A periodic diet that mimics fasting promotes multi-system regeneration, enhanced cognitive performance, and healthspan. Cell Metab. 2015;22(1):86–99." "Mouse + human" Nothing False
    , Citation 7 "wei-fmd-markers-2017" "Wei M, Brandhorst S, Shelehchi M, et al. Fasting-mimicking diet and markers/risk factors for aging, diabetes, cancer, and cardiovascular disease. Sci Transl Med. 2017;9(377):eaai8700." "Human RCT" Nothing False
    , Citation 8 "cheng-fasting-hsc-regeneration-2014" "Cheng CW, Adams GB, Perin L, et al. Prolonged fasting reduces IGF-1/PKA to promote hematopoietic-stem-cell-based regeneration and reverse immunosuppression. Cell Stem Cell. 2014;14(6):810–823." "Mouse + phase I" Nothing False
    , Citation 9 "eisenberg-spermidine-longevity-2009" "Eisenberg T, Knauer H, Schauer A, et al. Induction of autophagy by spermidine promotes longevity. Nat Cell Biol. 2009;11(11):1305–1314." "Yeast, fly, mouse" Nothing False
    , Citation 10 "eisenberg-spermidine-cardioprotection-2016" "Eisenberg T, Abdellatif M, Schroeder S, et al. Cardioprotection and lifespan extension by the natural polyamine spermidine. Nat Med. 2016;22(12):1428–1438." "Mouse + epidemiology" Nothing False
    , Citation 11 "madeo-spermidine-health-2018" "Madeo F, Eisenberg T, Pietrocola F, Kroemer G. Spermidine in health and disease. Science. 2018;359(6374):eaan2788." "Review" Nothing False
    , Citation 12 "pietrocola-polyphenols-acetylation-2012" "Pietrocola F, Mariño G, Lissa D, et al. Pro-autophagic polyphenols reduce the acetylation of cytoplasmic proteins. Cell Cycle. 2012;11(20):3851–3860." "Cell" Nothing False
    , Citation 13 "mehanna-refeeding-syndrome-2008" "Mehanna HM, Moledina J, Travis J. Refeeding syndrome: what it is, and how to prevent and treat it. BMJ. 2008;336(7659):1495–1498." "Clinical review" Nothing False
    , Citation 14 "pietrocola-coffee-autophagy-2014" "Pietrocola F, Malik SA, Mariño G, et al. Coffee induces autophagy in vivo. Cell Cycle. 2014;13(12):1987–1994." "Mouse" Nothing False
    , Citation 15 "he-exercise-autophagy-2012" "He C, Bassik MC, Moresi V, et al. Exercise-induced BCL2-regulated autophagy is required for muscle glucose homeostasis. Nature. 2012;481(7382):511–515." "Mouse" Nothing False
    , Citation 16 "de-cabo-intermittent-fasting-2019" "de Cabo R, Mattson MP. Effects of intermittent fasting on health, aging, and disease. N Engl J Med. 2019;381(26):2541–2551." "Review" Nothing False
    , Citation 17 "cahill-fuel-metabolism-starvation-2006" "Cahill GF Jr. Fuel metabolism in starvation. Annu Rev Nutr. 2006;26:1–22." "Human, classic" Nothing False
    , Citation 18 "asa-glp1-preoperative-guidance-2023" "American Society of Anesthesiologists. Consensus-based guidance on preoperative management of patients (adults and children) on glucagon-like peptide-1 (GLP-1) receptor agonists. ASA; 2023." "Clinical guidance" Nothing False
    , Citation 19 "look-surmount1-body-composition-2025" "Look M, et al. Body composition changes during weight reduction with tirzepatide in the SURMOUNT-1 study of adults with obesity or overweight. Diabetes Obes Metab. 2025. (Read alongside its published correction.)" "Human RCT substudy" (Just "10.1111/dom.16275") False
    ]


pdfPath : Citation -> String
pdfPath c =
    "/resources/pdf/" ++ c.slug ++ ".pdf"



-- VIEW


view : Html msg
view =
    Doc.view
        { tag = "Resources Archive"
        , kicker = "19 citations"
        , rev = "Rev. 3"
        , titleLines = [ "Primary", "sources" ]
        , standfirst = "Every citation in the protocol, archived locally as PDF so the evidence base outlives link rot, publisher moves, and dead DOIs."
        , sections =
            [ { anchor = "sec-policy"
              , tocLabel = "Policy"
              , title = "Archive policy"
              , intent = "Legal copies only"
              , body = Doc.Clauses secPolicy
              }
            , { anchor = "sec-archive"
              , tocLabel = "The archive"
              , title = "The archive"
              , intent = "19 reserved slots"
              , body = Doc.Panel (List.map viewCitation citations)
              }
            ]
        , footNote =
            -- the medical disclaimer ships on every content page
            -- (DESIGN-REQUIREMENTS §5), the archive note after it
            [ p [ style "margin" "0 0 .4rem" ]
                [ b [] [ text "This is general information, not medical advice, and I'm not a doctor." ]
                , text " Prolonged fasting carries real risk that varies enormously with your individual health, medications and history. Talk to a physician before your first cycle. Full "
                , a [ href "/legal" ] [ text "terms and disclaimers" ]
                , text "."
                ]
            , p [ style "margin" "0" ]
                [ text "Each slug is a permanent public URL — once assigned, it never changes. Full policy: docs/RESOURCES-ARCHIVE.md." ]
            ]
        }


secPolicy : List (Html msg)
secPolicy =
    [ p [ style "font-size" ".9rem" ]
        [ text "Each entry lists the full citation, the strongest identifier we have (DOI where one exists), and the archived copy. Entries marked \u{201C}not yet archived\u{201D} have a reserved slot at a stable path; the manifest in "
        , span [ class "mono", style "font-size" ".8rem" ] [ text "src/Page/Resources.elm" ]
        , text " is the single source of truth."
        ]
    , p [ style "font-size" ".9rem" ]
        [ text "Acquisition and licensing: open-access versions are archived verbatim; paywalled works are archived as author manuscripts where the publisher permits, and otherwise stay linked at their DOI until a shareable copy exists. Nothing is served that the license does not allow." ]
    ]


viewCitation : Citation -> Html msg
viewCitation c =
    div [ class "resource" ]
        [ span [ class "rid" ] [ text ("[" ++ String.padLeft 2 '0' (String.fromInt c.id) ++ "]") ]
        , div []
            [ h3 [] [ text c.citation ]
            , p [ class "meta" ] [ text ("Evidence class: " ++ c.evidence) ]
            , div [ class "links" ]
                (List.concat
                    [ case c.doi of
                        Just doi ->
                            [ a [ href ("https://doi.org/" ++ doi), target "_blank" ] [ text ("doi:" ++ doi) ] ]

                        Nothing ->
                            []
                    , if c.archived then
                        [ a [ href (pdfPath c) ] [ text "Archived PDF" ]
                        , span [ class "pdf-archived" ] [ text "Archived" ]
                        ]

                      else
                        [ span [ class "pdf-missing" ] [ text "Not yet archived" ]
                        , span [ class "mono", style "font-size" ".68rem", style "color" "var(--tx-dim)" ]
                            [ text (pdfPath c) ]
                        ]
                    ]
                )
            ]
        ]
