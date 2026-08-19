module Ics exposing (calendar, dataUri, escape, fileName, fold)

{-| The cycle as an iCalendar file (RFC 5545), built as a string and
handed to the browser as a `data:` URL — the same trick as any other
download link, and no port, no dependency, no server.

Three decisions worth stating:

  - **Timed events are written in UTC** (`…T200000Z`), so the file
    needs no `VTIMEZONE` block to be read correctly anywhere. All-day
    bands are the exception: `VALUE=DATE` is a local date on purpose —
    a priming day is a day where the reader is, not a 24-hour window
    in Greenwich.
  - **UIDs are derived from the start instant**, not from a random
    seed or the clock. Re-exporting the same plan therefore _updates_
    those events in a calendar rather than duplicating them, and
    changing the start date produces a genuinely different set.
  - **Text is escaped and folded per the RFC** — commas, semicolons
    and backslashes escaped, lines folded at 73 octets (not
    characters: the schedule is full of en dashes and `·`, which cost
    two and three bytes). A calendar that silently drops the second
    half of the potassium line is worse than no calendar.

-}

import Civil
import Cycle exposing (Entry, Phase, Span(..), Target)
import Time exposing (Posix, Zone)
import Url


{-| The whole cycle as one `VCALENDAR`.

`origin` is the site's own base URL, so every event carries a link
back to the protocol section it was compressed from — the calendar is
a schedule, never a substitute for the document.

-}
calendar : { zone : Zone, now : Posix, start : Posix, target : Target, origin : String } -> String
calendar ctx =
    let
        stamp =
            Civil.icsStamp ctx.now

        body =
            Cycle.plan ctx.target
                |> List.concatMap (\phase -> List.map (Tuple.pair phase) phase.entries)
                |> List.indexedMap (event ctx stamp)
                |> List.concat
    in
    (List.map fold
        ([ "BEGIN:VCALENDAR"
         , "VERSION:2.0"
         , "PRODID:-//autophagous//cycle planner//EN"
         , "CALSCALE:GREGORIAN"
         , "METHOD:PUBLISH"
         , "X-WR-CALNAME:" ++ escape ("Autophagy cycle · " ++ Cycle.targetLabel ctx.target)
         ]
            ++ body
            ++ [ "END:VCALENDAR" ]
        )
        |> String.join crlf
    )
        -- RFC 5545: the file ends with a line break, not on the last
        -- character of END:VCALENDAR
        ++ crlf


event : { a | zone : Zone, start : Posix, origin : String } -> String -> Int -> ( Phase, Entry ) -> List String
event ctx stamp index ( phase, entry ) =
    let
        at offset =
            Civil.shift offset ctx.start

        uid =
            "ap-"
                ++ String.fromInt (Time.posixToMillis ctx.start)
                ++ "-"
                ++ String.fromInt index
                ++ "@autophagous"

        when =
            case entry.span of
                Moment ->
                    [ "DTSTART:" ++ Civil.icsStamp (at entry.at)
                    , "DTEND:" ++ Civil.icsStamp (at (entry.at + 30))
                    ]

                Until end ->
                    -- VALUE=DATE ranges are half-open: DTEND is the first
                    -- day NOT covered, so a single-day band still needs
                    -- the following date
                    [ "DTSTART;VALUE=DATE:" ++ Civil.icsDate ctx.zone (at entry.at)
                    , "DTEND;VALUE=DATE:" ++ Civil.icsDate ctx.zone (at (end + Cycle.days 1))
                    ]
    in
    [ "BEGIN:VEVENT"
    , "UID:" ++ uid
    , "DTSTAMP:" ++ stamp
    ]
        ++ when
        ++ [ "SUMMARY:" ++ escape (entry.mark ++ " · " ++ entry.title)
           , "DESCRIPTION:"
                ++ escape
                    (entry.detail
                        ++ "\n\n"
                        ++ phase.num
                        ++ " — "
                        ++ phase.title
                        ++ "\n"
                        ++ ctx.origin
                        ++ phase.source
                    )
           , "END:VEVENT"
           ]


{-| The saved file's name, dated so two plans never collide in a
downloads folder.
-}
fileName : Zone -> Posix -> String
fileName zone start =
    "autophagous-cycle-" ++ Civil.icsDate zone start ++ ".ics"


{-| The download target. `Url.percentEncode` covers the CRLFs and the
non-ASCII, and the anchor's `download` attribute keeps the click out
of Elm's hands entirely (DESIGN-PRINCIPLES §3).
-}
dataUri : String -> String
dataUri ics =
    "data:text/calendar;charset=utf-8," ++ Url.percentEncode ics


crlf : String
crlf =
    "\u{000D}\n"


{-| RFC 5545 TEXT escaping. Order matters: backslashes first, or the
backslashes this function introduces get escaped again.
-}
escape : String -> String
escape =
    String.replace "\\" "\\\\"
        >> String.replace ";" "\\;"
        >> String.replace "," "\\,"
        >> String.replace "\n" "\\n"


{-| Fold a content line to 73 octets, continuing with CRLF + space.

Octets, not characters — the schedule is full of `–`, `—` and `·`,
which are two and three bytes each, and a fold counted in characters
would sail past the 75-octet limit on exactly the longest lines.
Never folds immediately after a backslash: unfolding happens before
unescaping, so it would survive, but leaving an escape pair intact
costs one byte of slack and removes the question.

-}
fold : String -> String
fold raw =
    let
        step ch st =
            let
                width =
                    utf8Width ch

                broken =
                    st.bytes + width > 73 && not st.afterEscape
            in
            { bytes =
                if broken then
                    1 + width

                else
                    st.bytes + width
            , afterEscape = ch == '\\'
            , out =
                if broken then
                    String.fromChar ch :: (crlf ++ " ") :: st.out

                else
                    String.fromChar ch :: st.out
            }
    in
    String.foldl step { bytes = 0, afterEscape = False, out = [] } raw
        |> .out
        |> List.reverse
        |> String.concat


utf8Width : Char -> Int
utf8Width ch =
    let
        code =
            Char.toCode ch
    in
    if code < 0x80 then
        1

    else if code < 0x0800 then
        2

    else if code < 0x00010000 then
        3

    else
        4
