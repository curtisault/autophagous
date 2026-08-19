module Page.Legal exposing (view)

{-| The legal notices — terms of use, the medical disclaimer at full
length, and what this site collects. Worn as a house document
(`Doc.elm`). Pure view: no state, no Cmd.

This page does not replace the footer disclaimer, which still ships on
every content page (DESIGN-REQUIREMENTS §5) — it is the long form the
footer points at. Safety content here is subject to the same rule as
the protocol's: never cut, collapsed, or softened.

Deliberately absent: a governing-law/venue clause (owner's call,
2026-08-16 — this is an informational site with no accounts, no sales,
and no user submissions, so there is nothing to litigate over). Legal
notices go to the repository's issue tracker rather than a personal
address.

-}

import Doc
import Html exposing (Html, a, b, div, em, h4, li, p, span, text, ul)
import Html.Attributes exposing (class, href, style, target)



-- HELPERS


bT : String -> Html msg
bT s =
    b [] [ text s ]


emT : String -> Html msg
emT s =
    em [] [ text s ]


note : List (Html msg) -> Html msg
note =
    div [ class "note" ]


tightList : List (List (Html msg)) -> Html msg
tightList items =
    ul [ class "tight" ] (List.map (li []) items)



-- VIEW


view : Maybe String -> Html msg
view active =
    Doc.view
        { tag = "Legal Notices"
        , kicker = "Read in full"
        , rev = "Rev. 3"
        , revDate = "2026-08-16"
        , titleLines = [ "Terms and", "disclaimers" ]
        , standfirst = "The long form of the warning in every footer: what this document is, what it is not, who must not attempt it, and what you are agreeing to by reading on."
        , sections =
            [ { anchor = "sec-not-advice"
              , tocLabel = "Not advice"
              , title = "This is not medical advice"
              , intent = "No clinical relationship"
              , body = Doc.Clauses secNotAdvice
              }
            , { anchor = "sec-exclusions"
              , tocLabel = "Who must not"
              , title = "Who must not attempt this"
              , intent = "Absolute exclusions"
              , body = Doc.Clauses secExclusions
              }
            , { anchor = "sec-emergency"
              , tocLabel = "Emergencies"
              , title = "If something is going wrong"
              , intent = "Stop · seek care"
              , body = Doc.Clauses secEmergency
              }
            , { anchor = "sec-risk"
              , tocLabel = "Assumed risk"
              , title = "The risk is real, and it is yours"
              , intent = "Assumption of risk"
              , body = Doc.Clauses secRisk
              }
            , { anchor = "sec-evidence"
              , tocLabel = "Evidence"
              , title = "What the evidence does not say"
              , intent = "No outcome is claimed"
              , body = Doc.Clauses secEvidence
              }
            , { anchor = "sec-warranty"
              , tocLabel = "No warranty"
              , title = "No warranty"
              , intent = "Provided as it is"
              , body = Doc.Clauses secWarranty
              }
            , { anchor = "sec-liability"
              , tocLabel = "Liability"
              , title = "Limitation of liability"
              , intent = "So far as law allows"
              , body = Doc.Clauses secLiability
              }
            , { anchor = "sec-links"
              , tocLabel = "Sources"
              , title = "Third-party sources and links"
              , intent = "No endorsement"
              , body = Doc.Clauses secLinks
              }
            , { anchor = "sec-privacy"
              , tocLabel = "Privacy"
              , title = "What this site collects"
              , intent = "One key · no server"
              , body = Doc.Clauses secPrivacy
              }
            , { anchor = "sec-reuse"
              , tocLabel = "Reuse"
              , title = "Copyright and reuse"
              , intent = "The text · the sources"
              , body = Doc.Clauses secReuse
              }
            , { anchor = "sec-changes"
              , tocLabel = "Changes"
              , title = "Changes to this document"
              , intent = "Revision-marked"
              , body = Doc.Clauses secChanges
              }
            ]
        , active = active
        , footNote =
            [ p [ style "margin" "0" ]
                [ bT "This is general information, not medical advice, and I'm not a doctor."
                , text " Prolonged fasting carries real risk that varies enormously with your individual health, medications and history. Talk to a physician before your first cycle, and get baseline bloodwork — electrolytes, kidney function, glucose — if you intend to repeat this monthly."
                ]
            ]
        }



-- §01 NOT MEDICAL ADVICE


secNotAdvice : List (Html msg)
secNotAdvice =
    [ p []
        [ bT "I am not a doctor, a dietitian, or any other licensed clinician."
        , text " Nothing on this site is medical advice, diagnosis, or treatment, and nothing here is individualised to you. It is a written account of a protocol and the published literature behind it — general information, offered for reading, not a prescription to act on."
        ]
    , p []
        [ text "Reading this document does not create a doctor-patient relationship, a duty of care, or a professional relationship of any kind between you and the author. No one here is monitoring your health, and no one here knows your history, your medications, or your labs." ]
    , p []
        [ bT "Consult a physician before your first cycle."
        , text " That is not a formality to skim past. Prolonged fasting interacts with prescription medication, existing conditions, and individual physiology in ways a general document cannot anticipate. If you take any prescription drug — particularly insulin, sulfonylureas, "
        , a [ href "/#sec-glp1" ] [ text "GLP-1 receptor agonists" ]
        , text ", diuretics, antihypertensives, lithium, or anticoagulants — the protocol may require dose changes that only your prescriber can make safely."
        ]
    , note
        [ p [ style "margin" "0" ]
            [ text "Where this document and a clinician who has examined you disagree, "
            , bT "the clinician is right"
            , text ". They have your bloodwork. This page does not."
            ]
        ]
    ]



-- §02 WHO MUST NOT ATTEMPT THIS


secExclusions : List (Html msg)
secExclusions =
    [ p []
        [ text "The protocol's full contraindication list is "
        , a [ href "/#sec-safety" ] [ text "§03 of the protocol" ]
        , text " and it is the operative one. The categories below are repeated here because they are absolute, and because a legal page is the last place a reader might look before starting."
        ]
    , div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "Do not attempt this protocol at all" ]
        , div [ class "cols" ]
            [ div []
                [ h4 [] [ text "Absolute exclusions" ]
                , tightList
                    [ [ text "Anyone under 18" ]
                    , [ text "Pregnancy, or breastfeeding" ]
                    , [ text "Any current or past eating disorder" ]
                    , [ text "Type 1 diabetes, or Type 2 on insulin or sulfonylureas" ]
                    , [ text "Being underweight (BMI under 18.5)" ]
                    ]
                ]
            , div []
                [ h4 [] [ text "Not without a physician's supervision" ]
                , tightList
                    [ [ text "Kidney disease of any stage" ]
                    , [ text "Liver disease" ]
                    , [ text "Any cardiac history or arrhythmia" ]
                    , [ text "Adrenal insufficiency or thyroid disease" ]
                    , [ text "Any prescription medication at all" ]
                    ]
                ]
            ]
        , p [ class "slab-foot" ]
            [ text "This list is a floor, not a ceiling. Read "
            , a [ href "/#sec-safety" ] [ text "§03" ]
            , text " in full before your first cycle."
            ]
        ]
    , p []
        [ bT "On eating disorders specifically."
        , text " Structured fasting can function as a vector for restriction, and a protocol that supplies rules, targets, and a log sheet supplies exactly the scaffolding a relapse uses. If you have ever had anorexia, bulimia, binge-eating disorder, or a pattern of restriction you would not describe to a doctor, "
        , bT "this document is not for you"
        , text ", and no amount of interest in autophagy changes that. Please speak to your physician or a local eating-disorder support service instead."
        ]
    ]



-- §03 EMERGENCIES


secEmergency : List (Html msg)
secEmergency =
    [ div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "This page is not an emergency service" ]
        , p [ style "margin" "0" ]
            [ text "If you are experiencing chest pain, an irregular heartbeat, fainting, confusion, severe weakness, or any symptom that frightens you — "
            , bT "stop the fast, eat, and contact emergency services or your physician immediately"
            , text ". Do not wait to finish a stage, do not consult this document first, and do not let a completed-cycle checkbox weigh against a symptom."
            ]
        ]
    , p []
        [ text "The protocol's abort signals are listed at "
        , a [ href "/#sec-fast" ] [ text "§07" ]
        , text ", and the refeeding-syndrome signals at "
        , a [ href "/#sec-refeed" ] [ text "§09" ]
        , text ". Both lists are non-exhaustive. A symptom that is not on either list is still a reason to stop."
        ]
    , p []
        [ bT "Breaking a fast early is never a failure."
        , text " It is the protocol working as designed. Nothing in this document should be read as encouragement to push past a warning sign, and any reading of it that produces that conclusion is a misreading."
        ]
    ]



-- §04 ASSUMPTION OF RISK


secRisk : List (Html msg)
secRisk =
    [ p []
        [ text "Prolonged fasting carries genuine, documented risk: electrolyte derangement, hypoglycaemia, orthostatic hypotension, cardiac arrhythmia, gallstone formation, and — on refeeding — "
        , a [ href "/#sec-refeed" ] [ text "refeeding syndrome" ]
        , text ", which can be fatal. These are not hypothetical. They are the reasons the protocol's mandatory elements are mandatory."
        ]
    , p []
        [ bT "If you choose to act on any part of this document, you do so voluntarily and at your own risk."
        , text " You accept responsibility for that decision and for its consequences, including the decision to proceed without consulting a physician, and including any decision made on a misreading of what is written here."
        ]
    , p []
        [ text "The severity of these risks varies enormously between individuals. A protocol that is uneventful for one person can hospitalise another with an undiagnosed condition, a prescription that was not adjusted, or an electrolyte deficit that went uncorrected. "
        , emT "You cannot know in advance which one you are"
        , text " — which is the entire argument for baseline bloodwork and a physician's sign-off."
        ]
    ]



-- §05 EVIDENCE


secEvidence : List (Html msg)
secEvidence =
    [ p []
        [ text "The epistemic position of this document is stated plainly in "
        , a [ href "/#sec-limits" ] [ text "§01" ]
        , text " and restated here because it is a legal matter as much as an intellectual one: "
        , bT "no health outcome is claimed."
        ]
    , p []
        [ text "Much of the autophagy literature is animal or cell work. That autophagy is induced by fasting is well characterised; that a particular fasting schedule produces a particular health outcome in a particular person is "
        , emT "not"
        , text " established, and this document does not assert it. Nothing here is a claim to prevent, treat, cure, or diagnose any disease, and no such claim should be inferred from the mechanistic detail, the citations, or the confidence of the prose."
        ]
    , p []
        [ text "Evidence classes are marked on every citation in the "
        , a [ href "/resources" ] [ text "source index" ]
        , text " precisely so a reader can see where the human data stops. Where the protocol makes a recommendation the evidence does not fully support, it says so."
        ]
    , note
        [ p [ style "margin" "0" ]
            [ text "These statements have not been evaluated by any food or drug regulator." ]
        ]
    ]



-- §06 NO WARRANTY


secWarranty : List (Html msg)
secWarranty =
    [ p []
        [ text "This site and its contents — including the protocol, the printable cycle log, and the source index — are provided "
        , bT "as they are, without warranty of any kind"
        , text ", express or implied, including any implied warranty of accuracy, completeness, fitness for a particular purpose, or non-infringement."
        ]
    , p []
        [ text "The content may contain errors. The literature moves, and a citation that was current at Rev. 3 may since have been corrected, retracted, or superseded — "
        , a [ href "/resources" ] [ text "citation 19" ]
        , text " already carries a published correction that must be read alongside it. No undertaking is given to keep any part of this document current, available, or online at all."
        ]
    ]



-- §07 LIABILITY


secLiability : List (Html msg)
secLiability =
    [ p []
        [ text "To the fullest extent permitted by applicable law, the author accepts no liability for any loss, injury, illness, or damage — direct, indirect, incidental, consequential, or otherwise — arising from the use of, or reliance on, anything published here." ]
    , p []
        [ text "Some jurisdictions do not allow the exclusion of certain warranties or the limitation of liability for personal injury. "
        , bT "Where that is the case, these limitations apply only to the extent that jurisdiction permits"
        , text ", and nothing on this page is intended to exclude any liability that cannot lawfully be excluded."
        ]
    ]



-- §08 THIRD-PARTY SOURCES


secLinks : List (Html msg)
secLinks =
    [ p []
        [ text "The protocol cites published research and links out to it by DOI. Those works are the property of their authors and publishers, are reproduced here only where their licences permit, and their inclusion is neither an endorsement of this protocol by their authors nor a claim of their agreement with any conclusion drawn here." ]
    , p []
        [ text "No supplement, brand, product, or vendor mentioned anywhere on this site is endorsed, and nothing here is a paid placement. There are no affiliate links, no sponsorship, and no commercial relationship behind any recommendation in the protocol." ]
    , p []
        [ text "Links to third-party sites are provided for reference. Those sites are outside the author's control, and no responsibility is taken for their content, their accuracy, or their availability." ]
    ]



-- §09 PRIVACY


secPrivacy : List (Html msg)
secPrivacy =
    [ p []
        [ bT "This site has no backend, no accounts, and no analytics."
        , text " Nothing you do here is transmitted anywhere, because there is nowhere for it to be transmitted to. The pages are static files; there is no server-side code to receive anything."
        ]
    , p []
        [ text "One thing is stored, locally, in your own browser: a single "
        , span [ class "mono", style "font-size" ".8rem" ] [ text "localStorage" ]
        , text " key named "
        , span [ class "mono", style "font-size" ".8rem" ] [ text "autophagous-theme" ]
        , text ", holding the value "
        , span [ class "mono", style "font-size" ".8rem" ] [ text "light" ]
        , text " or "
        , span [ class "mono", style "font-size" ".8rem" ] [ text "dark" ]
        , text " when you set the theme by hand. It never leaves your device. Choosing "
        , bT "System"
        , text " deletes it. Clearing your browser storage deletes it. It contains nothing about you."
        ]
    , p []
        [ text "No cookies are set. No tracking pixels, fingerprinting, advertising identifiers, or third-party scripts are loaded — every asset is served from this site's own origin, which is a "
        , a [ href "/#sec-limits" ] [ text "design constraint" ]
        , text " of the project, not merely a current state of affairs."
        ]
    , note
        [ p [ style "margin" "0" ]
            [ text "Whoever hosts these files may keep their own server logs (IP addresses, timestamps, requested paths) as a normal part of serving a website. That is outside the author's control and is not read, analysed, or connected to anything else." ]
        ]
    ]



-- §10 REUSE


secReuse : List (Html msg)
secReuse =
    [ p []
        [ text "The protocol text, the site design, and the printable artifacts are the author's own work. You are welcome to read them, print them, and use them personally. Republishing them — in whole or in substantial part, and particularly with the safety content removed — is not permitted." ]
    , p []
        [ bT "The cited sources are a separate matter entirely, and none of them are hosted here."
        , text " Every entry in the "
        , a [ href "/resources" ] [ text "source index" ]
        , text " links out to the publisher, a repository, or the document's own page; nothing is rehosted, copied, or mirrored. Each work remains under its own licence and its publisher's terms, and none of it is the author's to relicense. The full policy is "
        , span [ class "mono", style "font-size" ".8rem" ] [ text "docs/RESOURCES-POLICY.md" ]
        , text "."
        ]
    , p []
        [ text "If you adapt this protocol, "
        , bT "carry the safety content with it"
        , text " — the contraindications, the abort signals, the electrolyte requirements, and the refeeding protocol. Those sections are what make the rest of it safe to publish at all."
        ]
    ]



-- §11 CHANGES


secChanges : List (Html msg)
secChanges =
    [ p []
        [ text "This document carries the same revision mark as the protocol it accompanies — currently "
        , bT "Rev. 3"
        , text ". It may be amended at any time without individual notice; the revision mark in the masthead is the only announcement you will get. Continued use of the site after a change constitutes acceptance of the amended terms."
        ]
    , p []
        [ text "Corrections, errors of fact, and safety concerns are genuinely welcome, and legal notices should go to the same place: "
        , a [ href "https://github.com/curtisault/autophagous/issues", target "_blank" ] [ text "the project's issue tracker" ]
        , text ". A safety error in a document like this one is worth more than a polite silence — please raise it."
        ]
    ]
