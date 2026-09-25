module Page.Plan exposing (Context, From(..), recast, resolveStart, view)

{-| The cycle planner, worn as a house document (`Doc.elm`).

The protocol counts in elapsed hours because that is what the biology
counts in. Everything a reader actually has to do, though, happens on
a date: priming starts three days before a meal they have not skipped
yet, and "hour 36–48, often abruptly" is a Thursday afternoon. This
page is the only place the two notations meet.

Pure view. The schedule itself is `Cycle`, the arithmetic is `Civil`,
and the state (the start instant, the target, the zone) is the
shell's — this module receives a `Context` and renders it.

**It is a schedule, not a copy of the protocol.** Every phase links
back to the section it compresses, and §01 carries the safety slab
that says so in as many words. Nothing here is a summary that could
be mistaken for the contraindications (DESIGN-REQUIREMENTS §5).

-}

import Civil
import Clock
import Cycle exposing (Entry, Phase, Target, Weight(..))
import Doc
import Dose
import Html exposing (Html, a, b, button, div, input, label, li, p, span, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (attribute, class, classList, download, href, id, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Ruler
import Safety
import Time exposing (Posix, Zone)


{-| Which end of the fast the reader is naming.

Nobody decides to stop eating at 20:00 on Thursday. They decide they
want to eat lunch on Sunday and work backwards, and until now this
page made them do that arithmetic themselves — across a daylight-saving
boundary, in their head.

**The field holds one string either way.** The mode says what that
string *means*; it is not a second value, because two values that must
agree are two values that will not. Hour 0 is derived when the reader
is naming the break, and the break is derived when they are naming
hour 0.

-}
type From
    = FromStart
    | FromBreak


{-| The field, read as hour 0.

Unparseable is `Nothing` in both modes — a half-typed date is not an
instant, and the planner says so rather than guessing at one.

-}
resolveStart :
    { zone : Zone, target : Target, from : From, value : String }
    -> Maybe Posix
resolveStart cfg =
    Civil.fromIso cfg.value
        |> Maybe.map (Civil.toPosix cfg.zone)
        |> Maybe.map
            (\t ->
                case cfg.from of
                    FromStart ->
                        t

                    FromBreak ->
                        Civil.shift (negate (fastMinutes cfg.target)) t
            )


{-| The same moment, rewritten for the mode being switched **to**.

Toggling the control must not move the schedule: a reader who has set
hour 0 and then asks to work backwards should see the break they have
already chosen, not a blank field or a different plan. So the value is
converted once, here, at the moment the meaning changes — and never
again, which is what keeps the reader's typing out of the arithmetic.

An unparseable value is handed back untouched. There is nothing to
convert, and eating what someone is halfway through typing is worse
than leaving it.

**So is a value whose meaning has not changed.** The control takes
`from` as well as `to` because the button for the mode already
selected is still a button: clicking it must be a no-op, and a shift
applied to a field that was never on the other side is a plan moved
by a whole fast for nothing.

-}
recast : { zone : Zone, target : Target, from : From, to : From, value : String } -> String
recast cfg =
    case ( cfg.from == cfg.to, Civil.fromIso cfg.value ) of
        ( False, Just civil ) ->
            let
                offset =
                    case cfg.to of
                        FromBreak ->
                            fastMinutes cfg.target

                        FromStart ->
                            negate (fastMinutes cfg.target)
            in
            Civil.toPosix cfg.zone civil
                |> Civil.shift offset
                |> Civil.fromPosix cfg.zone
                |> Civil.toIso

        _ ->
            cfg.value


fastMinutes : Target -> Int
fastMinutes target =
    Cycle.hours (Cycle.targetHours target)


{-| What the shell hands over. `start` is `Nothing` until the field
holds a real instant — the page renders its whole schedule either
way, in relative offsets, because a planner that shows nothing until
it is filled in teaches the reader nothing.
-}
type alias Context msg =
    { zone : Zone
    , start : Maybe Posix

    -- the shell's clock, ticking once a minute while this page is on
    -- screen. `Nothing` until `Time.now` lands, which is one frame —
    -- and a frame is long enough to show a reading of "−20682 d",
    -- so §02 waits rather than counting from the epoch
    , now : Maybe Posix
    -- the field verbatim, and what it currently means. Verbatim so
    -- that typing is never rewritten underneath the reader
    , anchorValue : String
    , from : From
    , target : Target
    , download : Maybe { href : String, name : String }

    -- the dosing sheet's two preferences, so the clock can hand over
    -- the day in the reader's own terms and send them somewhere that
    -- has not forgotten them
    , doseSource : Dose.Source
    , doseServings : Int
    , dosingHref : String

    -- the rail's state: where the reader is, and what they are
    -- searching for. The shell owns both
    , chrome : Doc.Chrome msg
    , onAnchor : String -> msg
    , onFrom : From -> msg
    , onTarget : Target -> msg
    }


view : Context msg -> Html msg
view ctx =
    let
        read =
            reading ctx
    in
    Doc.view
        { tag = "Cycle Planner"
        , kicker = Cycle.targetLabel ctx.target ++ " cycle · local time"
        , rev = "Rev. 3"
        , revDate = "2026-08-18"
        , titleLines = [ "Plan", "the cycle" ]
        , standfirst = "The protocol counts in elapsed hours. Set the moment your last meal ends and it counts in dates instead: when priming starts, when the switch flips, when to break the fast, and when the rebuild window closes."
        , sections =
            { anchor = "sec-start"
            , tocLabel = "The start"
            , title = "Set hour 0"
            , intent = "Local time · shareable"
            , body = Doc.Clauses (secStart ctx)
            }
                :: { anchor = "sec-now"
                   , tocLabel = "Now"
                   , title = "Where you are now"
                   , intent = "Live · your device clock"
                   , body = Doc.Clauses (secNow ctx read)
                   }
                :: List.map (phaseSection ctx read) (Cycle.plan ctx.target)
                ++ [ { anchor = "sec-carry"
                     , tocLabel = "Carry it"
                     , title = "Take it with you"
                     , intent = "Calendar · cycle log"
                     , body = Doc.Clauses (secCarry ctx)
                     }
                   ]
        , chrome = ctx.chrome
        , marked = markedPhase ctx read
        , footNote =
            -- the medical disclaimer ships on every content page
            -- (DESIGN-REQUIREMENTS §5)
            [ p [ style "margin" "0 0 .4rem" ]
                [ b [] [ text "This is general information, not medical advice, and I'm not a doctor." ]
                , text " Prolonged fasting carries real risk that varies enormously with your individual health, medications and history. Talk to a physician before your first cycle. Full "
                , a [ href "/legal" ] [ text "terms and disclaimers" ]
                , text "."
                ]
            , p [ style "margin" "0" ]
                [ text "This sheet dates the protocol. It does not replace it — read "
                , a [ href "/#sec-safety" ] [ text "§03, before anything else" ]
                , text "."
                ]
            ]
        }



{-| The reading, taken once for the whole page.

§02 renders it, the phase tables mark themselves against it, and the
section header takes its "you are here" from it. Three readers of one
answer: computing it three times would be three chances for the clock
at the top of the page to disagree with the table halfway down it.

-}
reading : Context msg -> Maybe Clock.Reading
reading ctx =
    Maybe.map2
        (\start now -> Clock.reading ctx.target (Civil.minutesBetween start now))
        ctx.start
        ctx.now


{-| The phase section the reader is standing in, by anchor.

The stance names a `Cycle.Kind` and the plan is searched for it, so
the four slugs are spelled once — in `Cycle`, beside the sections they
name.

-}
markedPhase : Context msg -> Maybe Clock.Reading -> Maybe String
markedPhase ctx read =
    read
        |> Maybe.andThen (.stance >> Clock.stanceKind)
        |> Maybe.andThen
            (\kind ->
                Cycle.plan ctx.target
                    |> List.filter (\phase -> phase.kind == kind)
                    |> List.head
            )
        |> Maybe.map .anchor


{-| Whether a row is a line the reader is standing on right now —
either the moment last passed or a band still in force.

**Both, not just the moment.** At hour 41 the moment is the Stage III
crossing and the band is the mandatory daily line; §02 says both are
in force, and a table that marked only the first would have the
compulsory row sitting unmarked two inches under the section that
calls it compulsory.

-}
isNow : Maybe Clock.Reading -> Entry -> Bool
isNow read entry =
    case read of
        Just r ->
            r.current == Just entry || List.member entry r.standing

        Nothing ->
            False



-- §01 SET HOUR 0


secStart : Context msg -> List (Html msg)
secStart ctx =
    [ div [ class "plan-set" ]
        [ div [ class "plan-field" ]
            [ label [ class "u", Html.Attributes.for "plan-start" ]
                [ text (anchorLabel ctx.from) ]
            , input
                [ id "plan-start"
                , type_ "datetime-local"
                , class "mono"
                , value ctx.anchorValue
                , onInput ctx.onAnchor
                ]
                []
            ]
        , div [ class "plan-field" ]
            [ span [ class "u" ] [ text "Count from" ]
            , div
                [ class "plan-seg"
                , attribute "role" "group"
                , attribute "aria-label" "Which end of the fast you are setting"
                ]
                [ fromButton ctx FromStart "Hour 0"
                , fromButton ctx FromBreak "The break"
                ]
            ]
        , div [ class "plan-field" ]
            [ span [ class "u" ] [ text "Target" ]
            , div
                [ class "plan-seg"
                , attribute "role" "group"
                , attribute "aria-label" "Fast target"
                ]
                (List.map (targetButton ctx) Cycle.targets)
            ]
        ]
    , startState ctx
    , div [ class "slab" ]
        [ div [ class "slab-title u" ] [ text "A schedule is not the protocol" ]
        , p [ style "margin" "0 0 .7rem", style "font-size" ".92rem" ]
            [ text "This page compresses the protocol to the lines that have a time attached. It leaves out everything that decides whether you should be doing this at all — those sections are not summarised here because a summary of a contraindication is a way of missing one." ]
        , ul [ class "tight" ]
            [ li [] [ a [ href "/#sec-safety" ] [ text "Contraindications" ], text " — the absolute exclusions, and the list to clear with a doctor first. (The abort signals are below, in full.)" ]
            , li [] [ a [ href "/#sec-glp1" ] [ text "If you are on a GLP-1" ], text " — this stops being self-managed." ]
            , li [] [ a [ href "/#sec-fast" ] [ text "The potassium warning" ], text " — never one large dose; the one item with a genuinely narrow margin." ]
            , li [] [ a [ href "/#sec-refeed" ] [ text "Refeeding syndrome" ], text " — more people are harmed breaking a long fast than doing one." ]
            ]
        ]
    , div [ class "note" ]
        [ b [] [ text "How these dates are computed." ]
        , text " In your device's time zone, from real elapsed hours: hour 48 is forty-eight hours later, which across a daylight-saving change is "
        , Html.em [] [ text "not" ]
        , text " the same clock time two days on. The single case this cannot resolve is a start inside the repeated hour of an autumn fall-back, where the earlier of the two readings is taken."
        ]
    , div [ class "note" ]
        [ b [] [ text "Counting backwards." ]
        , text " Setting the break instead runs the same arithmetic the other way, with one consequence worth expecting: if the fast crosses a daylight-saving change, holding the meal you have chosen moves hour 0 to a clock time you did not pick. The elapsed hours are what the protocol counts, so the wall clock is what gives."
        ]
    , div [ class "note" ]
        [ b [] [ text "The address bar is the plan." ]
        , text " Your start and target ride in the URL, so copying it keeps or shares this exact schedule. A link always names hour 0, whichever end you set it from — the schedule is built from that one moment, and a second way to say it is a second thing that can disagree. Nothing is stored, on this device or anywhere else."
        ]
    ]


{-| The field names a different moment in each mode, so it says which.
-}
anchorLabel : From -> String
anchorLabel from =
    case from of
        FromStart ->
            "Hour 0 — when the last meal ends"

        FromBreak ->
            "The break — when you want to eat"


fromButton : Context msg -> From -> String -> Html msg
fromButton ctx from label_ =
    segButton (from == ctx.from) (ctx.onFrom from) label_


targetButton : Context msg -> Target -> Html msg
targetButton ctx target =
    segButton (target == ctx.target) (ctx.onTarget target) (Cycle.targetLabel target)


{-| One button of a segmented control. Two controls wear this now, and
a second hand-rolled copy is how `aria-pressed` gets forgotten on one
of them.
-}
segButton : Bool -> msg -> String -> Html msg
segButton selected msg label_ =
    button
        [ type_ "button"
        , class "plan-btn u"
        , Html.Attributes.classList [ ( "active", selected ) ]
        , attribute "aria-pressed"
            (if selected then
                "true"

             else
                "false"
            )
        , onClick msg
        ]
        [ text label_ ]


{-| What the field is currently worth, always as hour 0 — that is the
moment the whole schedule hangs off, and in break mode it is the one
the reader has *not* typed, so it is the one worth stating back.

An unparsed value is called out rather than silently ignored: the
schedule below would otherwise go back to relative offsets with no
stated reason.

-}
startState : Context msg -> Html msg
startState ctx =
    case ( ctx.start, String.trim ctx.anchorValue ) of
        ( Just t, _ ) ->
            p [ class "plan-state u" ]
                [ text "Hour 0 · "
                , span [ class "mono" ]
                    [ text (Civil.formatDateYear ctx.zone t ++ " · " ++ Civil.formatTime ctx.zone t) ]
                , case ctx.from of
                    FromBreak ->
                        span [ class "plan-state-derived" ]
                            [ text " — stop eating then to break when you asked" ]

                    FromStart ->
                        text ""
                ]

        ( Nothing, "" ) ->
            p [ class "plan-state u" ]
                [ text "Nothing set — the schedule below is in elapsed hours" ]

        ( Nothing, _ ) ->
            p [ class "plan-state u is-bad" ]
                [ text "That is not a date the calendar has — the schedule below is in elapsed hours" ]



-- §02 WHERE YOU ARE NOW


{-| The clock. Everything in it is looked up in `Cycle.plan` through
`Clock`, so it cannot disagree with the tables further down the page,
and the abort signals are the protocol's own values (`Safety`) rather
than a summary of them — the one reader who needs them most is at
hour 41 and will not follow a link.
-}
secNow : Context msg -> Maybe Clock.Reading -> List (Html msg)
secNow ctx taken =
    case ( ctx.start, taken ) of
        ( Just start, Just read ) ->
            [ clockHead ctx start read
            , Ruler.view
                { target = ctx.target
                , now = Just read.elapsed

                -- `depth` exists exactly while the reader is fasting,
                -- which is exactly when a stage is theirs to stand in
                , here = Maybe.map .stage read.depth
                , linkTo = stageLink
                }
            , countdowns ctx start read
            ]
                ++ currentLine read
                ++ doseLine ctx read
                ++ [ Safety.abortSignals (Just "/#sec-safety") ]

        ( Nothing, _ ) ->
            idle ctx "Set hour 0 above and this becomes a clock — hours elapsed, the stage you are standing in, and what is next"

        ( Just _, Nothing ) ->
            -- a start is set but `Time.now` has not landed; one frame,
            -- and long enough to show a reading counted from the epoch
            idle ctx "Reading your device clock"


idle : Context msg -> String -> List (Html msg)
idle ctx message =
    [ p [ class "plan-state u" ] [ text message ]
    , Ruler.view
        { target = ctx.target
        , now = Nothing
        , here = Nothing
        , linkTo = stageLink
        }
    , Safety.abortSignals (Just "/#sec-safety")
    ]


{-| A stage segment leaves the planner. The stage's content is the
protocol's §08 card — this page compressed it and links back to it,
the same as every phase table below (DESIGN-PRINCIPLES §3b). Pointing
all five segments at this page's own `#sec-fast` would be five
segments with one destination and nothing new at the end of any of
them.
-}
stageLink : Cycle.Stage -> String
stageLink s =
    "/#" ++ s.anchor


clockHead : Context msg -> Posix -> Clock.Reading -> Html msg
clockHead ctx start read =
    div
        [ class "clock"
        , classList [ ( "is-live", Clock.inFlight read.stance ) ]
        ]
        [ span [ class "clock-figure mono" ] [ text (Clock.elapsedFigure read.elapsed) ]
        , div [ class "clock-read" ]
            (span [ class "clock-stance u" ] [ text (Clock.stanceLabel read.stance) ]
                :: depthLine read
                ++ [ span [ class "clock-since u" ]
                        [ text
                            ((if read.elapsed < 0 then
                                "Until hour 0 · "

                              else
                                "Since hour 0 · "
                             )
                                ++ stamp ctx start
                            )
                        ]
                   ]
            )
        ]


{-| How far in, in the clock's own block rather than a clause of its
own — it is part of the reading, not a ruling about it, and a `§N.M`
mark on it would be numbering for its own sake.

The stage is named directly above, so this does not repeat it: "17 of
24 h into the stage" reads under "Stage III — climbing" and nowhere
else. The hours are floored to whole hours on purpose — the exact
minute is already the headline figure beside it, and this is the
coarse question, whether you have just arrived or are nearly through.

-}
depthLine : Clock.Reading -> List (Html msg)
depthLine read =
    case read.depth of
        Just depth ->
            [ span [ class "clock-depth u" ]
                [ span [ class "mono" ]
                    [ text
                        (String.fromInt (depth.into // 60)
                            ++ " of "
                            ++ String.fromInt (depth.span // 60)
                            ++ " h"
                        )
                    ]
                , text " into the stage · "
                , span [ class "mono" ] [ text (String.fromInt depth.percent ++ "%") ]
                , text " of the target"
                ]
            ]

        Nothing ->
            []


{-| What is coming, as one clause: the line the schedule reaches next,
and — through the fast — the number the reader is actually waiting
for. One clause and not two, because a `§N.M` mark should address a
piece of apparatus, not each line of one.
-}
countdowns : Context msg -> Posix -> Clock.Reading -> Html msg
countdowns ctx start read =
    div [ class "clock-when" ]
        (nextLine ctx start read :: breakLine ctx start read)


{-| The break, held from hour 0 until it arrives.

The instant is `read.elapsed + minutes` — the countdown's own two ends
added back together. The target's offset is not re-derived here: it is
`Cycle`'s, and the view knowing it a second time is how the numbers
come apart.

-}
breakLine : Context msg -> Posix -> Clock.Reading -> List (Html msg)
breakLine ctx start read =
    case read.toBreak of
        Just minutes ->
            [ p [ class "clock-next is-break u" ]
                [ text "Break the fast in "
                , span [ class "mono" ] [ text (Clock.countdown minutes) ]
                , text " · "
                , span [ class "mono" ]
                    [ text (stamp ctx (Civil.shift (read.elapsed + minutes) start)) ]
                ]
            ]

        Nothing ->
            []


stamp : Context msg -> Posix -> String
stamp ctx t =
    Civil.formatDate ctx.zone t ++ " " ++ Civil.formatTime ctx.zone t


nextLine : Context msg -> Posix -> Clock.Reading -> Html msg
nextLine ctx start read =
    case read.next of
        Just entry ->
            p [ class "clock-next is-next u" ]
                [ text "Next — "
                , b [] [ text entry.title ]
                , text " in "
                , span [ class "mono" ] [ text (Clock.countdown (entry.at - read.elapsed)) ]
                , text " · "
                , span [ class "mono" ]
                    [ text (Civil.formatDate ctx.zone (Civil.shift entry.at start)) ]
                ]

        Nothing ->
            p [ class "clock-next is-next u" ]
                [ text "Nothing scheduled after this — the cycle is behind you" ]


{-| What the reader is in the middle of: the moment last passed, then
every band still in force underneath it. A list, not a `Html`: before
priming starts there is neither, and an empty note would still take a
`§N.M` clause mark — a number pointing at nothing.

The bands are why this is not one lookup. The mandatory-daily line
runs the length of the fast, and as "the last line passed" it stopped
being current a minute after hour 0 — so the reader at hour 41 was
told which stage they were in and never that the electrolytes were
still compulsory. Rendered in full, never summarised
(DESIGN-REQUIREMENTS §5).

-}
currentLine : Clock.Reading -> List (Html msg)
currentLine read =
    List.map noteFor (asList read.current ++ read.standing)


noteFor : Entry -> Html msg
noteFor entry =
    div [ class "note" ]
        [ b [] [ text entry.title ]
        , text (" — " ++ entry.detail)
        ]


asList : Maybe a -> List a
asList maybe =
    case maybe of
        Just x ->
            [ x ]

        Nothing ->
            []



-- WHAT GOES IN THE GLASS


{-| The standing daily line states §07's requirement in milligrams of
an element. A kitchen has a spoon. `/dosing` already does that
conversion and the clock already knows which day it is, and until now
neither knew the other existed.

**Nothing here is a dose this page chose.** Every figure is `Dose`
converting §07, at the source and division the reader picked on the
dosing sheet — carried in the shell's state and handed back in the
link, so following it does not lose their choices.

**Only while fasting.** §07's targets are the fast's. The refeed's
requirement is real and it is *higher* — "the requirement goes up, not
down, as insulin returns" — so printing the fast's numbers over the
refeed would understate the one thing this is for. The refeed says so
in the protocol's own words already: it is a standing band, and
`currentLine` renders it.

-}
doseLine : Context msg -> Clock.Reading -> List (Html msg)
doseLine ctx read =
    case read.depth of
        Just _ ->
            let
                each =
                    Dose.perServing ctx.doseServings (Dose.sheet ctx.doseSource)
            in
            [ div [ class "plan-dose" ]
                [ p [ class "plan-dose-head u" ]
                    [ text
                        ("One of "
                            ++ String.fromInt ctx.doseServings
                            ++ " doses today · "
                            ++ Dose.sourceLabel ctx.doseSource
                        )
                    ]
                , div [ class "plan-dose-rows" ] (doseRows ctx.doseSource each)
                , p [ class "plan-dose-foot u" ]
                    [ a [ href ctx.dosingHref ] [ text "The dosing sheet" ]
                    , text " — every constant it uses, and the day undivided."
                    ]
                ]

            -- the sheet renders this for the same reason: a surface
            -- that converts the dose cannot be read without the
            -- warning the dose is about
            , Safety.potassiumDose
            ]

        Nothing ->
            []


{-| Sodium always; potassium in whichever salt carries it. `Excluded`
is a real answer — a reader on ACE inhibitors is told so by the
warning below — and it leaves one row, not a blank one.
-}
doseRows : Dose.Source -> Dose.Sheet -> List (Html msg)
doseRows source each =
    doseRow "Fine salt" each.fineSalt Dose.gramsPerTspSalt
        :: (case source of
                Dose.Kcl ->
                    [ doseRow "Potassium chloride" each.kcl Dose.gramsPerTspKcl ]

                Dose.Lite ->
                    [ doseRow "Lite salt" each.liteSalt Dose.gramsPerTspLite ]

                Dose.Excluded ->
                    []
           )


{-| A range, in grams and in spoons. Both, because a spoon is a rough
instrument and a scale is not — the same pairing the dosing sheet
shows, for the same reason. And a range in both: the sheet prints a
spoon figure for each end, and one spoon beside two gram figures was
the upper bound wearing no label.
-}
doseRow : String -> Dose.Range -> Float -> Html msg
doseRow label range perTsp =
    div [ class "plan-dose-row" ]
        [ span [ class "plan-dose-what u" ] [ text label ]
        , span [ class "plan-dose-g mono" ]
            [ text (Dose.grams range.low ++ "–" ++ Dose.grams range.high) ]
        , span [ class "plan-dose-tsp mono" ]
            [ text (Dose.teaspoonRange (range.low / perTsp) (range.high / perTsp)) ]
        ]



-- THE PHASE SECTIONS


phaseSection : Context msg -> Maybe Clock.Reading -> Phase -> Doc.Section msg
phaseSection ctx read phase =
    { anchor = phase.anchor
    , tocLabel = phase.tocLabel
    , title = phase.num ++ " — " ++ String.toLower phase.title
    , intent = phase.duration ++ " · " ++ phase.intent
    , body =
        Doc.Panel
            [ table [ class "plan" ]
                [ thead []
                    [ tr []
                        [ th [ style "width" "9%" ] [ text "Mark" ]
                        , th [ style "width" "24%" ] [ text "When" ]
                        , th [] [ text "What" ]
                        ]
                    ]
                , tbody [] (List.map (entryRow ctx read) phase.entries)
                ]
            , p [ class "plan-source u" ]
                [ a [ href phase.source ] [ text "Read the full section" ] ]
            ]
    }


entryRow : Context msg -> Maybe Clock.Reading -> Entry -> Html msg
entryRow ctx read entry =
    tr
        [ Html.Attributes.classList
            [ ( "hero", entry.weight == Key )
            , ( "is-now", isNow read entry )
            ]
        ]
        [ td [ class "mono" ] [ text entry.mark ]
        , td [ class "mono plan-when" ] (whenCell ctx entry)
        , td []
            [ span [ class "plan-t" ] [ text entry.title ]
            , text entry.detail
            ]
        ]


{-| The dated cell: two lines for a moment (date over time), one range
for a band, and an em dash until there is a start to count from.

A band's dates are the dates it is in force, read off `Cycle.window`
— the same half-open window the clock stands in — so a day that
begins at 20:00 shows both dates it touches, and the row `isNow`
marks at 10:00 the next morning is a row that says so.

-}
whenCell : Context msg -> Entry -> List (Html msg)
whenCell ctx entry =
    case ctx.start of
        Nothing ->
            -- most marks *are* their own offset ("16 h", "D−1"), so
            -- repeating it here would fill the column with a copy of the
            -- one beside it. Only the named marks — First, Daily, Day 2 —
            -- have an offset worth stating.
            [ span [ class "plan-rel" ]
                [ text
                    (if relative entry.at == entry.mark then
                        "—"

                     else
                        relative entry.at
                    )
                ]
            ]

        Just start ->
            let
                at offset =
                    Civil.shift offset start

                day =
                    dayText ctx.zone start
            in
            case Cycle.window entry of
                Nothing ->
                    [ span [ class "plan-d" ] [ text (day (at entry.at)) ]
                    , span [ class "plan-h" ] [ text (Civil.formatTime ctx.zone (at entry.at)) ]
                    ]

                Just ( opens, closes ) ->
                    let
                        from =
                            day (at opens)

                        to =
                            -- the window is half-open: the last minute
                            -- in force is the one before it closes
                            day (at (closes - 1))
                    in
                    if from == to then
                        [ span [ class "plan-d" ] [ text from ] ]

                    else
                        [ span [ class "plan-d" ] [ text from ]
                        , span [ class "plan-d" ] [ text ("→ " ++ to) ]
                        ]


{-| Dates carry the year only when the row has left the start's year —
otherwise every line would repeat it, and a schedule that crosses New
Year would silently read as a duplicate of itself.
-}
dayText : Zone -> Posix -> Posix -> String
dayText zone start t =
    if Time.toYear zone t == Time.toYear zone start then
        Civil.formatDate zone t

    else
        Civil.formatDateYear zone t


{-| The offset itself, for the undated state, in whichever unit the
protocol uses at that distance: days before hour 0, hours across the
fast and the refeed, days again past the end of the clock — "672 h" is
a true statement about the next cycle and a useless one.
-}
relative : Int -> String
relative minutes =
    if minutes < 0 then
        "D−" ++ String.fromInt (abs minutes // 1440)

    else if minutes > Cycle.hours Cycle.scaleHours then
        String.fromInt (minutes // 1440) ++ " d"

    else if modBy 60 minutes == 0 then
        String.fromInt (minutes // 60) ++ " h"

    else
        String.fromInt (minutes // 60)
            ++ ":"
            ++ String.padLeft 2 '0' (String.fromInt (modBy 60 minutes))
            ++ " h"



-- §06 CARRY IT


secCarry : Context msg -> List (Html msg)
secCarry ctx =
    [ p []
        [ text "Two artifacts leave this page. The calendar is generated here, in the browser, from the schedule above; the cycle log is the printable sheet that records what actually happened." ]
    , div [ class "plan-carry" ] [ calendarLink ctx, logLink ]
    , div [ class "note" ]
        [ b [] [ text "The calendar file." ]
        , text " One event per line above — timed events in UTC so they land correctly wherever you open them, priming and rebuild days as all-day bands. Each event carries a link back to the protocol section it came from. Re-exporting the same start date updates those events rather than duplicating them."
        ]
    ]


calendarLink : Context msg -> Html msg
calendarLink ctx =
    case ctx.download of
        Just file ->
            a
                [ class "plan-dl u"
                , href file.href
                , download file.name
                ]
                [ span [] [ text "Download the calendar" ]
                , span [ class "mono" ] [ text ".ics" ]
                ]

        Nothing ->
            span [ class "plan-dl u is-off" ]
                [ span [] [ text "Set hour 0 to export a calendar" ]
                , span [ class "mono" ] [ text ".ics" ]
                ]


logLink : Html msg
logLink =
    a
        [ class "plan-dl u"
        , href "/downloads/cycle-log.pdf"
        , download "autophagous-cycle-log.pdf"
        ]
        [ span [] [ text "Download the cycle log" ]
        , span [ class "mono" ] [ text "PDF · A4" ]
        ]
