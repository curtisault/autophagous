module Search exposing (Entry, address, curated, index, run)

{-| Finding a thing in a document that is twelve sections long before
you count the four instruments around it.

**Why an index and not a text scan.** The protocol's prose lives in
Elm view code as `Html msg`, which is opaque — there is no way to read
the words back out of a rendered tree. Extracting them would mean
either parsing Elm source at build time or restructuring the whole
document into a content model, and neither is worth what it costs
here.

So the index is written by hand, and then **checked against the
prose**: `SearchTests` renders every page and asserts each `terms`
entry actually appears in the section it claims. The same test asserts
the opposite for `aliases` — the words a reader is likely to type that
are _not_ in the text at all. "Ozempic" appears nowhere in §04, which
names semaglutide and tirzepatide; a reader searching for their own
prescription should still land there. Splitting the two lists is what
keeps the second kind honest: an alias that turns out to be in the
prose belongs in `terms`, and the test says so.

Citations are not hand-written — they come straight off
`Citations.all`, so searching an author or a journal reaches the
source with no index to maintain.

-}

import Citations


type alias Entry =
    { path : String
    , anchor : String
    , page : String
    , label : String
    , blurb : String

    -- words that appear in this section, verbatim. Checked.
    , terms : List String

    -- words that do not appear and should still find it. Checked, in
    -- the other direction.
    , aliases : List String
    }


{-| Where a hit goes.
-}
address : Entry -> String
address entry =
    if entry.anchor == "" then
        entry.path

    else
        entry.path ++ "#" ++ entry.anchor



-- MATCHING


{-| Every word in the query has to match something, so a second word
narrows rather than widens. Ranked by how exact the matches were: a
whole term first, then a term that starts with it, then anything the
entry says at all.
-}
run : String -> List Entry
run raw =
    case words (String.toLower raw) of
        [] ->
            []

        needles ->
            index
                |> List.filterMap (score needles)
                |> List.sortBy (\( points, _ ) -> negate points)
                |> List.map Tuple.second


words : String -> List String
words =
    String.words >> List.filter (\word -> String.length word > 1)


score : List String -> Entry -> Maybe ( Int, Entry )
score needles entry =
    let
        hay =
            haystack entry

        points =
            List.map (scoreWord hay) needles
    in
    if List.any (\p -> p == 0) points then
        Nothing

    else
        Just ( List.sum points, entry )


scoreWord : { fields : List String, blob : String } -> String -> Int
scoreWord hay needle =
    if List.any (\field -> field == needle) hay.fields then
        4

    else if List.any (\field -> String.startsWith needle field) hay.fields then
        3

    else if List.any (\field -> String.contains needle field) hay.fields then
        2

    else if String.contains needle hay.blob then
        1

    else
        0


{-| `fields` are the words worth ranking on — the terms and the title.
`blob` is everything the entry says, for the loosest kind of hit.
-}
haystack : Entry -> { fields : List String, blob : String }
haystack entry =
    let
        fields =
            List.map String.toLower (entry.terms ++ entry.aliases)
                ++ words (String.toLower entry.label)
    in
    { fields = fields
    , blob =
        String.toLower
            (String.join " " [ entry.page, entry.label, entry.blurb, String.join " " entry.terms, String.join " " entry.aliases ])
    }



-- THE INDEX


index : List Entry
index =
    curated ++ List.map fromCitation Citations.all


{-| Every source, searchable by author, journal or title, straight off
the manifest.
-}
fromCitation : Citations.Citation -> Entry
fromCitation c =
    { path = "/resources"
    , anchor = c.slug
    , page = "Sources"
    , label = "[" ++ String.fromInt c.id ++ "] " ++ firstClause c.authors
    , blurb =
        if c.journal == "" then
            c.evidence

        else
            c.journal ++ " · " ++ c.evidence
    , terms = [ c.authors, c.journal, c.evidence ]
    , aliases = []
    }


firstClause : String -> String
firstClause authors =
    case String.split ". " authors of
        first :: _ ->
            first

        [] ->
            authors


{-| Hand-written, machine-checked. Terms are words in the section;
aliases are words that are not.
-}
curated : List Entry
curated =
    protocol ++ plan ++ dosing ++ elsewhere


protocol : List Entry
protocol =
    [ { path = "/"
      , anchor = "sec-limits"
      , page = "Protocol"
      , label = "What you can and cannot know"
      , blurb = "Why you cannot measure your own autophagy, and how to read every number that follows."
      , terms = [ "autophagy", "biopsy", "LC3B", "p62", "flux", "rodents", "measure", "test" ]
      , aliases = [ "evidence" ]
      }
    , { path = "/"
      , anchor = "sec-switches"
      , page = "Protocol"
      , label = "The two switches"
      , blurb = "mTORC1 off, AMPK on — the two levers everything here pulls."
      , terms = [ "mTORC1", "AMPK", "leucine", "protein" ]
      , aliases = [ "mechanism", "pathway" ]
      }
    , { path = "/"
      , anchor = "sec-safety"
      , page = "Protocol"
      , label = "Read this before anything else"
      , blurb = "Hard contraindications, what to clear with a doctor, and the signals that mean stop now."
      , terms = [ "diabetes", "SGLT2", "Pregnancy", "lithium", "Arrhythmia", "palpitations", "fainting", "gout", "safety", "abort", "contraindication" ]
      , aliases = [ "danger", "stop" ]
      }
    , { path = "/"
      , anchor = "sec-glp1"
      , page = "Protocol"
      , label = "If you are on a GLP-1"
      , blurb = "Semaglutide, tirzepatide and their relatives change this enough that it stops being self-managed."
      , terms = [ "Semaglutide", "tirzepatide", "liraglutide" ]
      , aliases = [ "ozempic", "wegovy", "mounjaro", "zepbound", "saxenda", "glp" ]
      }
    , { path = "/"
      , anchor = "sec-cycle"
      , page = "Protocol"
      , label = "The cycle"
      , blurb = "One fast is an event; cycles are the intervention. Monthly, never stacked."
      , terms = [ "cycles", "monthly", "repeat" ]
      , aliases = [ "how often", "frequency" ]
      }
    , { path = "/"
      , anchor = "sec-prime"
      , page = "Protocol"
      , label = "Phase 1 — priming"
      , blurb = "Three days of low carbohydrate, spermidine and polyphenols, so you arrive already switched."
      , terms = [ "spermidine", "polyphenols", "wheat germ", "natto", "glycogen", "alcohol" ]
      , aliases = [ "prepare", "before", "prime" ]
      }
    , { path = "/"
      , anchor = "sec-fast"
      , page = "Protocol"
      , label = "Phase 2 — hard requirements"
      , blurb = "Electrolytes in, calories out: sodium, potassium, magnesium, thiamine, water — and what is excluded."
      , terms = [ "Sodium", "Potassium", "Magnesium", "Thiamine", "coffee", "Walking", "broth", "BCAA", "MCT", "hyponatremia", "salt", "electrolytes", "supplements", "drink" ]
      , aliases = [ "allowed" ]
      }
    , { path = "/"
      , anchor = "sec-stages"
      , page = "Protocol"
      , label = "Stages, by the clock"
      , blurb = "0–96 h: glycogen draw-down, the switch, climbing, sustained, and the optional fourth day."
      , terms = [ "Ketones", "Gluconeogenesis", "hunger", "ketosis", "hours", "stage" ]
      , aliases = [ "timeline", "when" ]
      }
    , { path = "/"
      , anchor = "sec-refeed"
      , page = "Protocol"
      , label = "Phase 3 — the refeed"
      , blurb = "The dangerous 48 hours: refeeding syndrome, thiamine first, and the order food comes back in."
      , terms = [ "Refeeding syndrome", "hypophosphataemia", "phosphate", "Thiamine", "vegetables", "after" ]
      , aliases = [ "break the fast", "eating again" ]
      }
    , { path = "/"
      , anchor = "sec-rebuild"
      , page = "Protocol"
      , label = "Phase 4 — the rebuild"
      , blurb = "Three weeks of construction: resistance training, protein, and where the regeneration actually happens."
      , terms = [ "Resistance training", "protein", "muscle" ]
      , aliases = [ "exercise", "gym", "lifting", "recovery" ]
      }
    , { path = "/"
      , anchor = "sec-log"
      , page = "Protocol"
      , label = "Cycle log"
      , blurb = "One printable sheet per cycle, for what actually happened."
      , terms = [ "log", "print", "track" ]
      , aliases = [ "pdf", "record" ]
      }
    , { path = "/"
      , anchor = "sec-refs"
      , page = "Protocol"
      , label = "References"
      , blurb = "Every citation, with its evidence class marked."
      , terms = [ "evidence" ]
      , aliases = [ "sources", "papers", "studies", "citations" ]
      }
    ]


plan : List Entry
plan =
    [ { path = "/plan"
      , anchor = "sec-start"
      , page = "Planner"
      , label = "Set hour 0"
      , blurb = "Enter when your last meal ends and the protocol's elapsed hours become dates."
      , terms = [ "hour 0", "start", "date", "schedule", "plan" ]
      , aliases = [ "calendar" ]
      }
    , { path = "/plan"
      , anchor = "sec-now"
      , page = "Planner"
      , label = "Where you are now"
      , blurb = "The live clock: hours elapsed, the stage you are standing in, and the countdown to the next line."
      , terms = [ "clock", "now", "elapsed" ]
      , aliases = [ "current", "timer", "how long" ]
      }
    , { path = "/plan"
      , anchor = "sec-carry"
      , page = "Planner"
      , label = "Take it with you"
      , blurb = "The cycle as a calendar file, and the printable cycle log."
      , terms = [ "calendar", "ics", "export", "download" ]
      , aliases = [ "reminder" ]
      }
    ]


dosing : List Entry
dosing =
    [ { path = "/dosing"
      , anchor = "sec-dose-day"
      , page = "Dosing"
      , label = "Every day of the fast"
      , blurb = "§07's milligram targets weighed out: grams of salt, teaspoons, and what each delivers."
      , terms = [ "Sodium", "Potassium", "Magnesium", "Water", "tsp", "salt", "dose" ]
      , aliases = [ "how much", "grams", "teaspoon" ]
      }
    , { path = "/dosing"
      , anchor = "sec-dose-each"
      , page = "Dosing"
      , label = "Divided across the day"
      , blurb = "One dose of several, because a day's potassium is never taken at once."
      , terms = [ "doses", "divided", "per dose" ]
      , aliases = [ "split", "how often" ]
      }
    , { path = "/dosing"
      , anchor = "sec-dose-avoid"
      , page = "Dosing"
      , label = "What not to reach for"
      , blurb = "Liquid I.V., sports drinks, coconut water, bone broth — and the clause each one breaks."
      , terms = [ "Coconut water", "Bone broth", "Sports drinks" ]
      , aliases = [ "liquid iv", "gatorade", "powerade", "lmnt", "electrolyte drink", "avoid" ]
      }
    , { path = "/dosing"
      , anchor = "sec-dose-working"
      , page = "Dosing"
      , label = "What these numbers assume"
      , blurb = "Every constant the conversion uses, and where it came from."
      , terms = [ "teaspoon", "constants" ]
      , aliases = [ "assumptions", "working", "conversion" ]
      }
    ]


elsewhere : List Entry
elsewhere =
    [ { path = "/resources"
      , anchor = "sec-policy"
      , page = "Sources"
      , label = "How this index works"
      , blurb = "Link-first, never rehosted — and what each access mark means before you click."
      , terms = [ "rehosted", "DOI", "CrossRef", "paywall", "open access" ]
      , aliases = [ "policy" ]
      }
    , { path = "/legal"
      , anchor = "sec-not-advice"
      , page = "Legal"
      , label = "Not medical advice"
      , blurb = "What this document is, and what it is not."
      , terms = [ "advice" ]
      , aliases = [ "disclaimer", "legal", "liability" ]
      }
    , { path = "/legal"
      , anchor = "sec-privacy"
      , page = "Legal"
      , label = "Privacy"
      , blurb = "What this site collects, which is nothing."
      , terms = [ "collects", "localStorage", "tracking", "analytics", "cookies" ]
      , aliases = [ "privacy", "data" ]
      }
    ]
