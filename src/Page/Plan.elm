module Page.Plan exposing (Context, view)

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
import Cycle exposing (Entry, Phase, Span(..), Target, Weight(..))
import Doc
import Html exposing (Html, a, b, button, div, input, label, li, p, span, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (attribute, class, download, href, id, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Time exposing (Posix, Zone)


{-| What the shell hands over. `start` is `Nothing` until the field
holds a real instant — the page renders its whole schedule either
way, in relative offsets, because a planner that shows nothing until
it is filled in teaches the reader nothing.
-}
type alias Context msg =
    { zone : Zone
    , start : Maybe Posix
    , startValue : String
    , target : Target
    , download : Maybe { href : String, name : String }
    , onStart : String -> msg
    , onTarget : Target -> msg
    }


view : Context msg -> Html msg
view ctx =
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
                :: List.map (phaseSection ctx) (Cycle.plan ctx.target)
                ++ [ { anchor = "sec-carry"
                     , tocLabel = "Carry it"
                     , title = "Take it with you"
                     , intent = "Calendar · cycle log"
                     , body = Doc.Clauses (secCarry ctx)
                     }
                   ]
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



-- §01 SET HOUR 0


secStart : Context msg -> List (Html msg)
secStart ctx =
    [ div [ class "plan-set" ]
        [ div [ class "plan-field" ]
            [ label [ class "u", Html.Attributes.for "plan-start" ]
                [ text "Hour 0 — when the last meal ends" ]
            , input
                [ id "plan-start"
                , type_ "datetime-local"
                , class "mono"
                , value ctx.startValue
                , onInput ctx.onStart
                ]
                []
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
            [ li [] [ a [ href "/#sec-safety" ] [ text "Contraindications and abort signals" ], text " — the absolute exclusions, and what makes you stop mid-fast." ]
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
        [ b [] [ text "The address bar is the plan." ]
        , text " Your start and target ride in the URL, so copying it keeps or shares this exact schedule. Nothing is stored, on this device or anywhere else."
        ]
    ]


targetButton : Context msg -> Target -> Html msg
targetButton ctx target =
    let
        selected =
            target == ctx.target
    in
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
        , onClick (ctx.onTarget target)
        ]
        [ text (Cycle.targetLabel target) ]


{-| What the field is currently worth. An unparsed value is called out
rather than silently ignored — the schedule below would otherwise go
back to relative offsets with no stated reason.
-}
startState : Context msg -> Html msg
startState ctx =
    case ( ctx.start, String.trim ctx.startValue ) of
        ( Just t, _ ) ->
            p [ class "plan-state u" ]
                [ text "Hour 0 · "
                , span [ class "mono" ]
                    [ text (Civil.formatDateYear ctx.zone t ++ " · " ++ Civil.formatTime ctx.zone t) ]
                ]

        ( Nothing, "" ) ->
            p [ class "plan-state u" ]
                [ text "No start set — the schedule below is in elapsed hours" ]

        ( Nothing, _ ) ->
            p [ class "plan-state u is-bad" ]
                [ text "That is not a date the calendar has — the schedule below is in elapsed hours" ]



-- THE PHASE SECTIONS


phaseSection : Context msg -> Phase -> Doc.Section msg
phaseSection ctx phase =
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
                , tbody [] (List.map (entryRow ctx) phase.entries)
                ]
            , p [ class "plan-source u" ]
                [ a [ href phase.source ] [ text "Read the full section" ] ]
            ]
    }


entryRow : Context msg -> Entry -> Html msg
entryRow ctx entry =
    tr
        [ Html.Attributes.classList [ ( "hero", entry.weight == Key ) ] ]
        [ td [ class "mono" ] [ text entry.mark ]
        , td [ class "mono plan-when" ] (whenCell ctx entry)
        , td []
            [ span [ class "plan-t" ] [ text entry.title ]
            , text entry.detail
            ]
        ]


{-| The dated cell: two lines for a moment (date over time), one range
for a band, and an em dash until there is a start to count from.
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
            case entry.span of
                Moment ->
                    [ span [ class "plan-d" ] [ text (day (at entry.at)) ]
                    , span [ class "plan-h" ] [ text (Civil.formatTime ctx.zone (at entry.at)) ]
                    ]

                Until end ->
                    let
                        from =
                            day (at entry.at)

                        to =
                            day (at end)
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
