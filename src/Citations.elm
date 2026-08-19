module Citations exposing
    ( Access(..)
    , Citation
    , Site
    , all
    , byId
    , citedBy
    , cites
    , href
    , line
    , sites
    )

{-| The sources, once.

Until 2026-08-18 these existed twice: as a manifest in
`Page.Resources` and again, hand-written in a different format, as the
protocol's §12 reference list. Two copies of nineteen citations that
had to agree, and had already drifted — the corrigendum notes on [15]
and [19] read differently in each. They live here now, in parts
(`authors` / `journal` / `locus`), because the journal name is
italicised in both renderings and a flat string cannot carry that.

`line` is here for the same reason: two pages must write a citation
down identically, so there is one function that does it.

**This module is also what makes the markers work.** `[13]` in the
protocol is a link to `/resources#<slug>`, and `/resources` says which
sections cite each source — see `sites` for how that index is kept
honest.

-}

import Html exposing (Html, i, text)


{-| How a reader actually reaches this source.

Two of these are free-to-read but carry no open licence, which is the
distinction that killed the archive plan: readable is not the same as
redistributable, and only `Open` entries would ever have been ours to
serve (docs/RESOURCES-POLICY.md).

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


{-| One source. `authors` runs up to the journal name, `journal` is
set in italic, `locus` is the year, volume and pages after it — and
`note` is the thing a frozen PDF could never have told you, which is
why nothing here is rehosted.
-}
type alias Citation =
    { id : Int
    , slug : String
    , authors : String
    , journal : String
    , locus : String
    , note : Maybe String
    , evidence : String
    , doi : Maybe String
    , access : Access
    }


{-| Every DOI was verified against CrossRef on title, journal, volume
and page range; every access state came from Unpaywall on 2026-08-16
and every repository link was checked to resolve. Slugs are permanent
public addresses — `/resources#<slug>` — so they are not renamed.
-}
all : List Citation
all =
    [ { id = 1
      , slug = "klionsky-autophagy-assay-guidelines-2021"
      , authors = "Klionsky DJ, et al. Guidelines for the use and interpretation of assays for monitoring autophagy (4th edition). "
      , journal = "Autophagy."
      , locus = " 2021;17(1):1–382."
      , note = Nothing
      , evidence = "Methods"
      , doi = Just "10.1080/15548627.2020.1797280"
      , access = FreeAtPublisher
      }
    , { id = 2
      , slug = "nobel-2016-ohsumi"
      , authors = "The Nobel Assembly at Karolinska Institutet. The Nobel Prize in Physiology or Medicine 2016 — Yoshinori Ohsumi, for discoveries of mechanisms for autophagy."
      , journal = ""
      , locus = ""
      , note = Nothing
      , evidence = "Prize citation"
      , doi = Nothing
      , access = Web "https://www.nobelprize.org/prizes/medicine/2016/summary/"
      }
    , { id = 3
      , slug = "wolfson-sestrin2-leucine-2016"
      , authors = "Wolfson RL, Chantranupong L, Saxton RA, et al. Sestrin2 is a leucine sensor for the mTORC1 pathway. "
      , journal = "Science."
      , locus = " 2016;351(6268):43–48."
      , note = Nothing
      , evidence = "Cell"
      , doi = Just "10.1126/science.aab2674"
      , access = Manuscript "https://hdl.handle.net/1721.1/107960"
      }
    , { id = 4
      , slug = "grundler-blood-pressure-fasting-2020"
      , authors = "Grundler F, Mesnage R, Michalsen A, Wilhelmi de Toledo F. Blood pressure changes in 1610 subjects with and without antihypertensive medication during long-term fasting. "
      , journal = "J Am Heart Assoc."
      , locus = " 2020;9(23)."
      , note = Nothing
      , evidence = "Human"
      , doi = Just "10.1161/JAHA.120.018649"
      , access = Open "CC BY-NC-ND"
      }
    , { id = 5
      , slug = "wilhelmi-de-toledo-fasting-safety-2019"
      , authors = "Wilhelmi de Toledo F, Grundler F, Bergouignan A, Drinda S, Michalsen A. Safety, health improvement and well-being during a 4 to 21-day fasting period in an observational study including 1422 subjects. "
      , journal = "PLoS ONE."
      , locus = " 2019;14(1):e0209353."
      , note = Nothing
      , evidence = "Human, observational"
      , doi = Just "10.1371/journal.pone.0209353"
      , access = Open "CC BY"
      }
    , { id = 6
      , slug = "brandhorst-fmd-regeneration-2015"
      , authors = "Brandhorst S, Choi IY, Wei M, et al. A periodic diet that mimics fasting promotes multi-system regeneration, enhanced cognitive performance, and healthspan. "
      , journal = "Cell Metab."
      , locus = " 2015;22(1):86–99."
      , note = Nothing
      , evidence = "Mouse + human"
      , doi = Just "10.1016/j.cmet.2015.05.012"
      , access = FreeAtPublisher
      }
    , { id = 7
      , slug = "wei-fmd-markers-2017"
      , authors = "Wei M, Brandhorst S, Shelehchi M, et al. Fasting-mimicking diet and markers/risk factors for aging, diabetes, cancer, and cardiovascular disease. "
      , journal = "Sci Transl Med."
      , locus = " 2017;9(377):eaai8700."
      , note = Nothing
      , evidence = "Human RCT"
      , doi = Just "10.1126/scitranslmed.aai8700"
      , access = Manuscript "https://pmc.ncbi.nlm.nih.gov/articles/PMC6816332/"
      }
    , { id = 8
      , slug = "cheng-fasting-hsc-regeneration-2014"
      , authors = "Cheng CW, Adams GB, Perin L, et al. Prolonged fasting reduces IGF-1/PKA to promote hematopoietic-stem-cell-based regeneration and reverse immunosuppression. "
      , journal = "Cell Stem Cell."
      , locus = " 2014;14(6):810–823."
      , note = Nothing
      , evidence = "Mouse + phase I"
      , doi = Just "10.1016/j.stem.2014.04.014"
      , access = Manuscript "https://pmc.ncbi.nlm.nih.gov/articles/PMC4102383/"
      }
    , { id = 9
      , slug = "eisenberg-spermidine-longevity-2009"
      , authors = "Eisenberg T, Knauer H, Schauer A, et al. Induction of autophagy by spermidine promotes longevity. "
      , journal = "Nat Cell Biol."
      , locus = " 2009;11(11):1305–1314."
      , note = Nothing
      , evidence = "Yeast, fly, mouse"
      , doi = Just "10.1038/ncb1975"
      , access = FreeAtPublisher
      }
    , { id = 10
      , slug = "eisenberg-spermidine-cardioprotection-2016"
      , authors = "Eisenberg T, Abdellatif M, Schroeder S, et al. Cardioprotection and lifespan extension by the natural polyamine spermidine. "
      , journal = "Nat Med."
      , locus = " 2016;22(12):1428–1438."
      , note = Nothing
      , evidence = "Mouse + epidemiology"
      , doi = Just "10.1038/nm.4222"
      , access = Manuscript "https://pmc.ncbi.nlm.nih.gov/articles/PMC5806691/"
      }
    , { id = 11
      , slug = "madeo-spermidine-health-2018"
      , authors = "Madeo F, Eisenberg T, Pietrocola F, Kroemer G. Spermidine in health and disease. "
      , journal = "Science."
      , locus = " 2018;359(6374):eaan2788."
      , note = Nothing
      , evidence = "Review"
      , doi = Just "10.1126/science.aan2788"
      , access = Paywalled
      }
    , { id = 12
      , slug = "pietrocola-polyphenols-acetylation-2012"
      , authors = "Pietrocola F, Mariño G, Lissa D, et al. Pro-autophagic polyphenols reduce the acetylation of cytoplasmic proteins. "
      , journal = "Cell Cycle."
      , locus = " 2012;11(20):3851–3860."
      , note = Nothing
      , evidence = "Cell"
      , doi = Just "10.4161/cc.22027"
      , access = FreeAtPublisher
      }
    , { id = 13
      , slug = "mehanna-refeeding-syndrome-2008"
      , authors = "Mehanna HM, Moledina J, Travis J. Refeeding syndrome: what it is, and how to prevent and treat it. "
      , journal = "BMJ."
      , locus = " 2008;336(7659):1495–1498."
      , note = Nothing
      , evidence = "Clinical review"
      , doi = Just "10.1136/bmj.a301"
      , access = Paywalled
      }
    , { id = 14
      , slug = "pietrocola-coffee-autophagy-2014"
      , authors = "Pietrocola F, Malik SA, Mariño G, et al. Coffee induces autophagy in vivo. "
      , journal = "Cell Cycle."
      , locus = " 2014;13(12):1987–1994."
      , note = Nothing
      , evidence = "Mouse"
      , doi = Just "10.4161/cc.28929"
      , access = FreeAtPublisher
      }
    , { id = 15
      , slug = "he-exercise-autophagy-2012"
      , authors = "He C, Bassik MC, Moresi V, et al. Exercise-induced BCL2-regulated autophagy is required for muscle glucose homeostasis. "
      , journal = "Nature."
      , locus = " 2012;481(7382):511–515."
      , note = Just "A corrigendum accompanies this paper and should be read alongside it: Nature. 2013;503:146."
      , evidence = "Mouse"
      , doi = Just "10.1038/nature10758"
      , access = Paywalled
      }
    , { id = 16
      , slug = "de-cabo-intermittent-fasting-2019"
      , authors = "de Cabo R, Mattson MP. Effects of intermittent fasting on health, aging, and disease. "
      , journal = "N Engl J Med."
      , locus = " 2019;381(26):2541–2551."
      , note = Nothing
      , evidence = "Review"
      , doi = Just "10.1056/NEJMra1905136"
      , access = Paywalled
      }
    , { id = 17
      , slug = "cahill-fuel-metabolism-starvation-2006"
      , authors = "Cahill GF Jr. Fuel metabolism in starvation. "
      , journal = "Annu Rev Nutr."
      , locus = " 2006;26:1–22."
      , note = Nothing
      , evidence = "Human, classic"
      , doi = Just "10.1146/annurev.nutr.26.061505.111258"
      , access = Paywalled
      }
    , { id = 18
      , slug = "asa-glp1-preoperative-guidance-2023"
      , authors = "American Society of Anesthesiologists. Consensus-based guidance on preoperative management of patients (adults and children) on glucagon-like peptide-1 (GLP-1) receptor agonists. ASA; 2023."
      , journal = ""
      , locus = ""
      , note = Nothing
      , evidence = "Clinical guidance"
      , doi = Nothing
      , access = Web "https://www.asahq.org/about-asa/newsroom/news-releases/2023/06/american-society-of-anesthesiologists-consensus-based-guidance-on-preoperative"
      }
    , { id = 19
      , slug = "look-surmount1-body-composition-2025"
      , authors = "Look M, et al. Body composition changes during weight reduction with tirzepatide in the SURMOUNT-1 study of adults with obesity or overweight. "
      , journal = "Diabetes Obes Metab."
      , locus = " 2025."
      , note = Just "A published correction accompanies this paper and should be read alongside it."
      , evidence = "Human RCT substudy"
      , doi = Just "10.1111/dom.16275"
      , access = Open "CC BY-NC-ND"
      }
    ]


byId : Int -> Maybe Citation
byId id =
    List.head (List.filter (\c -> c.id == id) all)


{-| A citation's permanent public address. An id with no citation
behind it lands on the index rather than a dead anchor — but it should
not happen, and `CitationTests` holds every marker in the protocol to
a real source.
-}
href : Int -> String
href id =
    case byId id of
        Just c ->
            "/resources#" ++ c.slug

        Nothing ->
            "/resources"


{-| A citation written down: authors, the journal in italic, the
locus, then whatever the record has since had to say about itself.
Both the protocol's reference list and the source index render this,
so the two cannot disagree about a corrigendum again.
-}
line : Citation -> List (Html msg)
line c =
    [ text c.authors ]
        ++ (if c.journal == "" then
                []

            else
                [ i [] [ text c.journal ] ]
           )
        ++ (if c.locus == "" then
                []

            else
                [ text c.locus ]
           )
        ++ (case c.note of
                Just note ->
                    [ text " ", i [] [ text note ] ]

                Nothing ->
                    []
           )



-- WHERE EACH SOURCE IS CITED


{-| A place in the protocol that cites something.

The number is written here rather than derived because `Doc` numbers
sections by their position in a list this module cannot see — the same
hand-maintained cross-reference the protocol's own "see §09" already
is (DESIGN-PRINCIPLES §2a). The anchor is the load-bearing half, and
`CitationTests` checks it resolves.

-}
type alias Site =
    { anchor : String
    , number : String
    , label : String
    }


{-| Which protocol sections cite which sources.

Hand-maintained, and **checked in both directions**: `CitationTests`
renders the protocol and asserts that each section links exactly the
sources listed here — no marker missing from this table, and no entry
here that the prose does not actually cite.

-}
sites : List ( Site, List Int )
sites =
    [ ( Site "sec-limits" "§01" "What you can and cannot know", [ 1 ] )
    , ( Site "sec-switches" "§02" "The two switches", [ 2, 3 ] )
    , ( Site "sec-safety" "§03" "Read this before anything else", [ 4, 5 ] )
    , ( Site "sec-glp1" "§04" "If you are on a GLP-1", [ 13, 18, 19 ] )
    , ( Site "sec-cycle" "§05" "The cycle", [ 6, 7, 8 ] )
    , ( Site "sec-prime" "§06" "Priming", [ 3, 9, 10, 11, 12 ] )
    , ( Site "sec-fast" "§07" "The fast", [ 13, 14, 15 ] )
    , ( Site "sec-stages" "§08" "Stages, by the clock", [ 8, 16, 17 ] )
    , ( Site "sec-refeed" "§09" "The refeed", [ 13 ] )
    , ( Site "sec-rebuild" "§10" "The rebuild", [ 9, 10, 11 ] )
    ]


{-| The sections that cite this source, in document order.
-}
citedBy : Int -> List Site
citedBy id =
    sites
        |> List.filter (\( _, ids ) -> List.member id ids)
        |> List.map Tuple.first


{-| The sources this section cites.
-}
cites : String -> List Int
cites anchor =
    sites
        |> List.filter (\( site, _ ) -> site.anchor == anchor)
        |> List.concatMap Tuple.second
