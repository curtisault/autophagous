module Civil exposing
    ( Civil
    , formatDate
    , formatDateYear
    , formatTime
    , fromIso
    , fromPosix
    , icsDate
    , icsStamp
    , minutesBetween
    , offsetMinutes
    , shift
    , toIso
    , toPosix
    )

{-| Wall-clock time, and the conversion `elm/time` deliberately does
not ship.

`elm/time` goes one way: a `Posix` instant plus a `Zone` renders as
civil fields. The planner needs the other direction — the reader types
"1 Sep, 20:00" into a `datetime-local` input, which is a _local_ wall
clock with no offset attached, and the schedule is elapsed hours from
that instant.

**Why the round trip and not plain civil arithmetic.** "Hour 48" is 48
real hours, not "the same clock time two days later" — across a DST
boundary those differ by an hour, and it is the elapsed one the
protocol means. So local civil → `Posix` once, all offsets added in
`Posix`, and every rendering back through the `Zone`, which knows
where the boundaries fall.

**Local → Posix, without a zone-offset API.** `Time.Zone` is opaque;
there is no `offsetAt`. But the offset is recoverable: render an
instant in the zone, read the same fields back as if they were UTC,
and the difference _is_ the offset at that instant. Converting then
takes two passes — guess with the offset at the naive instant, then
re-read the offset where that guess landed — which is exact except
inside the one ambiguous hour a fall-back repeats, where the earlier
of the two readings wins. That hour is the only case this module
cannot answer honestly, and no library can: the wall clock genuinely
names two instants.

-}

import Time exposing (Month(..), Posix, Weekday(..), Zone)


{-| Wall-clock fields with no zone attached — what the reader typed,
or what an instant looks like from inside some zone. Meaningless on
its own; it needs a `Zone` to name an instant.
-}
type alias Civil =
    { year : Int
    , month : Int
    , day : Int
    , hour : Int
    , minute : Int
    , second : Int
    }



-- ISO LOCAL STRINGS (the `datetime-local` value, and the URL param)


{-| Read `YYYY-MM-DDTHH:MM`, seconds optional — the value shape a
`datetime-local` input produces and the shape the `?start=` parameter
carries. Rejects impossible dates (31 February) rather than rolling
them over, because a rolled-over date would silently plan a different
cycle than the one asked for.
-}
fromIso : String -> Maybe Civil
fromIso raw =
    case String.split "T" (String.trim raw) of
        [ d, t ] ->
            case ( parseDate d, parseTime t ) of
                ( Just ( y, mo, dy ), Just ( h, mi, s ) ) ->
                    validate (Civil y mo dy h mi s)

                _ ->
                    Nothing

        _ ->
            Nothing


parseDate : String -> Maybe ( Int, Int, Int )
parseDate d =
    case List.map String.toInt (String.split "-" d) of
        [ Just y, Just mo, Just dy ] ->
            Just ( y, mo, dy )

        _ ->
            Nothing


parseTime : String -> Maybe ( Int, Int, Int )
parseTime t =
    case List.map String.toInt (String.split ":" t) of
        [ Just h, Just mi ] ->
            Just ( h, mi, 0 )

        [ Just h, Just mi, Just s ] ->
            Just ( h, mi, s )

        _ ->
            Nothing


validate : Civil -> Maybe Civil
validate c =
    if
        (c.year >= 1970 && c.year <= 9999)
            && (c.month >= 1 && c.month <= 12)
            && (c.day >= 1 && c.day <= daysInMonth c.year c.month)
            && (c.hour >= 0 && c.hour <= 23)
            && (c.minute >= 0 && c.minute <= 59)
            && (c.second >= 0 && c.second <= 59)
    then
        Just c

    else
        Nothing


{-| The inverse of `fromIso`, at minute precision — what goes back
into the input's `value` and the shareable URL.
-}
toIso : Civil -> String
toIso c =
    pad 4 c.year
        ++ "-"
        ++ pad 2 c.month
        ++ "-"
        ++ pad 2 c.day
        ++ "T"
        ++ pad 2 c.hour
        ++ ":"
        ++ pad 2 c.minute


pad : Int -> Int -> String
pad width n =
    String.padLeft width '0' (String.fromInt n)



-- CIVIL <-> POSIX


{-| How an instant reads from inside a zone.
-}
fromPosix : Zone -> Posix -> Civil
fromPosix zone t =
    { year = Time.toYear zone t
    , month = monthNumber (Time.toMonth zone t)
    , day = Time.toDay zone t
    , hour = Time.toHour zone t
    , minute = Time.toMinute zone t
    , second = Time.toSecond zone t
    }


{-| The instant these wall-clock fields name in this zone. See the
module note for the two-pass method and its one ambiguous hour.
-}
toPosix : Zone -> Civil -> Posix
toPosix zone c =
    let
        naive =
            toPosixUtc c

        firstPass =
            shift (negate (offsetMinutes zone naive)) naive
    in
    shift (negate (offsetMinutes zone firstPass)) naive


{-| The zone's offset from UTC at this instant, in minutes — east of
Greenwich is positive. Recovered by re-reading the zone's own
rendering as though it were UTC.
-}
offsetMinutes : Zone -> Posix -> Int
offsetMinutes zone t =
    let
        ms =
            Time.posixToMillis t

        -- both sides at whole-second resolution, so a sub-second
        -- instant cannot round the offset off by a minute
        atSecond =
            ms - modBy 1000 ms
    in
    (Time.posixToMillis (toPosixUtc (fromPosix zone t)) - atSecond) // 60000


{-| Read the fields as UTC. Only meaningful paired with an offset —
`toPosix` is the one callers want.
-}
toPosixUtc : Civil -> Posix
toPosixUtc c =
    Time.millisToPosix
        ((((daysFromCivil c.year c.month c.day * 24 + c.hour) * 60 + c.minute) * 60 + c.second) * 1000)


{-| Days since 1970-01-01 for a proleptic Gregorian date — Howard
Hinnant's `days_from_civil`. The era shifts are what let it use
truncating division (Elm's `//`) and still floor correctly for dates
before the epoch.
-}
daysFromCivil : Int -> Int -> Int -> Int
daysFromCivil year month day =
    let
        y =
            if month <= 2 then
                year - 1

            else
                year

        era =
            (if y >= 0 then
                y

             else
                y - 399
            )
                // 400

        yoe =
            y - era * 400

        mp =
            if month > 2 then
                month - 3

            else
                month + 9

        doy =
            (153 * mp + 2) // 5 + day - 1

        doe =
            yoe * 365 + yoe // 4 - yoe // 100 + doy
    in
    era * 146097 + doe - 719468


daysInMonth : Int -> Int -> Int
daysInMonth year month =
    case month of
        2 ->
            if (modBy 4 year == 0 && modBy 100 year /= 0) || modBy 400 year == 0 then
                29

            else
                28

        4 ->
            30

        6 ->
            30

        9 ->
            30

        11 ->
            30

        _ ->
            31


{-| Whole minutes from one instant to another, negative if the second
comes first. Floored rather than truncated: Elm's `//` rounds toward
zero, which would put the minute before an instant and the minute
after it the same distance away.
-}
minutesBetween : Posix -> Posix -> Int
minutesBetween from to =
    let
        ms =
            Time.posixToMillis to - Time.posixToMillis from
    in
    if ms < 0 then
        -((-ms + 59999) // 60000)

    else
        ms // 60000


{-| Move an instant by whole minutes. Negative goes back.
-}
shift : Int -> Posix -> Posix
shift minutes t =
    Time.millisToPosix (Time.posixToMillis t + minutes * 60000)



-- RENDERING


{-| `TUE 01 SEP` — the day of the week first, because on a schedule
that is the field the eye is looking for.
-}
formatDate : Zone -> Posix -> String
formatDate zone t =
    weekdayAbbr (Time.toWeekday zone t)
        ++ " "
        ++ pad 2 (Time.toDay zone t)
        ++ " "
        ++ monthAbbr (Time.toMonth zone t)


{-| The same, carrying the year — used where a row could land in a
different year from the start date and quietly read as a duplicate.
-}
formatDateYear : Zone -> Posix -> String
formatDateYear zone t =
    formatDate zone t ++ " " ++ String.fromInt (Time.toYear zone t)


{-| 24-hour, zero-padded. This is a field manual; there is no am/pm
here.
-}
formatTime : Zone -> Posix -> String
formatTime zone t =
    pad 2 (Time.toHour zone t) ++ ":" ++ pad 2 (Time.toMinute zone t)


{-| An iCalendar UTC timestamp — `20260901T200000Z`. Timed events are
written in UTC so the file needs no `VTIMEZONE` block to be read
correctly anywhere.
-}
icsStamp : Posix -> String
icsStamp t =
    let
        c =
            fromPosix Time.utc t
    in
    pad 4 c.year
        ++ pad 2 c.month
        ++ pad 2 c.day
        ++ "T"
        ++ pad 2 c.hour
        ++ pad 2 c.minute
        ++ pad 2 c.second
        ++ "Z"


{-| An iCalendar `VALUE=DATE` day — `20260901`. All-day events are the
one place the _local_ date is the right answer: a priming day is a
day where the reader is, not a 24-hour window in UTC.
-}
icsDate : Zone -> Posix -> String
icsDate zone t =
    let
        c =
            fromPosix zone t
    in
    pad 4 c.year ++ pad 2 c.month ++ pad 2 c.day


monthNumber : Month -> Int
monthNumber m =
    case m of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


monthAbbr : Month -> String
monthAbbr m =
    case m of
        Jan ->
            "Jan"

        Feb ->
            "Feb"

        Mar ->
            "Mar"

        Apr ->
            "Apr"

        May ->
            "May"

        Jun ->
            "Jun"

        Jul ->
            "Jul"

        Aug ->
            "Aug"

        Sep ->
            "Sep"

        Oct ->
            "Oct"

        Nov ->
            "Nov"

        Dec ->
            "Dec"


weekdayAbbr : Weekday -> String
weekdayAbbr d =
    case d of
        Mon ->
            "Mon"

        Tue ->
            "Tue"

        Wed ->
            "Wed"

        Thu ->
            "Thu"

        Fri ->
            "Fri"

        Sat ->
            "Sat"

        Sun ->
            "Sun"
