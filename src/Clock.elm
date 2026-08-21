module Clock exposing
    ( Reading
    , Stance(..)
    , countdown
    , elapsedFigure
    , inFlight
    , reading
    , stanceLabel
    )

{-| Where the reader is in the cycle right now.

Pure: it takes a target and the minutes elapsed since hour 0, and
answers. No `Posix`, no `Zone`, no `Html` — the shell knows what time
it is, `Civil` knows how to subtract, and this module knows what the
answer means. That is what makes every case below testable without a
wall clock.

**Nothing here is new content.** The current and next lines are looked
up in `Cycle.plan` — the same schedule the planner's tables and the
calendar export are built from, so the clock cannot tell the reader
something the sheet below it disagrees with. The only thing this
module adds is _which_ of those lines is the one you are standing on.

-}

import Cycle exposing (Entry, Span(..), Target)


{-| The shape of the moment.
-}
type Stance
    = -- the cycle has not begun; priming is still ahead
      Waiting
      -- priming, day 1 to 3
    | Priming Int
      -- the fast, in the stage the hour falls in
    | Fasting Cycle.Stage
      -- the refeed, day 1 or 2
    | Refeeding Int
      -- the rebuild, counted in days since the fast broke
    | Rebuilding Int
      -- past the earliest next hour 0
    | Complete


type alias Reading =
    { elapsed : Int
    , stance : Stance

    -- the last *moment* at or before now: the thing that has most
    -- recently happened to the reader
    , current : Maybe Entry

    -- every band whose window is open right now: the things that are
    -- not happening but are in force. A schedule has both, and only
    -- one of them can be "the last line passed"
    , standing : List Entry

    -- the next line the reader has not reached, band or moment. Bands
    -- count: on the day before priming starts, "go low-carbohydrate"
    -- is the honest answer to what happens next, and hour 0 is not
    , next : Maybe Entry
    }


{-| **Why `current` and `standing` are two questions.**

They were one, and the answer was wrong for the whole fast. `current`
took the last line at or before now, which is right for a moment and
useless for a band: the mandatory-daily line sits at hour 0 and runs
to the break, so a minute past hour 0 the next crossing displaces it
and it never comes back. The one `Key` entry that is a _standing
obligation_ — electrolytes, thiamine, water, every day — was the only
line the live clock could not show.

So a moment is something that has happened, and a band is somewhere
you are standing. `Cycle.window` says which is which, and where a band
ends.

-}
reading : Target -> Int -> Reading
reading target elapsed =
    { elapsed = elapsed
    , stance = stanceAt target elapsed
    , current =
        schedule target
            |> List.filter (\e -> isMoment e && e.at <= elapsed)
            |> last
    , standing =
        schedule target
            |> List.filter (holds elapsed)
    , next =
        schedule target
            |> List.filter (\e -> e.at > elapsed)
            |> List.head
    }


isMoment : Entry -> Bool
isMoment entry =
    case entry.span of
        Moment ->
            True

        Until _ ->
            False


{-| Whether the reader is inside a band. Half-open, so the minute a
band ends belongs to whatever comes next and no line is in force
twice.
-}
holds : Int -> Entry -> Bool
holds elapsed entry =
    case Cycle.window entry of
        Just ( from, to ) ->
            from <= elapsed && elapsed < to

        Nothing ->
            False


{-| Every line of the plan in time order.

Ties are broken **moments first**, which only `next` now reads: at
23:59 on the last priming day, what happens next is "hour 0 — the last
meal ends", not the electrolyte band that opens beside it. The band is
not lost — it is in force one minute later and `standing` says so.

(This ordering was bands-first, for the opposite reason: `current`
took the last line at or before now, so the moment had to sort last to
win the tie. `current` reads only moments now, so the tie is `next`'s
alone and falls the other way.)

-}
schedule : Target -> List Entry
schedule target =
    Cycle.plan target
        |> List.concatMap .entries
        |> List.sortWith
            (\a c ->
                case compare a.at c.at of
                    EQ ->
                        compare (rank a) (rank c)

                    order ->
                        order
            )


rank : Entry -> Int
rank entry =
    case entry.span of
        Moment ->
            0

        Until _ ->
            1


stanceAt : Target -> Int -> Stance
stanceAt target elapsed =
    let
        fastEnds =
            Cycle.hours (Cycle.targetHours target)
    in
    if elapsed < Cycle.days -3 then
        Waiting

    else if elapsed < 0 then
        -- day 1 is the first of the three, so a start three days out
        -- reads "day 1" and the last day before hour 0 reads "day 3"
        Priming (4 + floorDiv elapsed 1440)

    else if elapsed < fastEnds then
        Fasting (stageAt elapsed)

    else if elapsed < fastEnds + Cycle.days 2 then
        Refeeding (1 + (elapsed - fastEnds) // 1440)

    else if elapsed < Cycle.days 28 then
        Rebuilding ((elapsed - fastEnds) // 1440)

    else
        Complete


{-| The stage an hour falls in: the first whose end it has not reached.

`stanceAt` only asks inside the fast, and the stage boundaries are
contiguous from 0 to 96 h (`CycleTests` holds them that way), so the
fallback is unreachable — it exists because the compiler cannot know
`Cycle.stages` is non-empty, and it falls back to the last stage
rather than to a blank.

-}
stageAt : Int -> Cycle.Stage
stageAt elapsed =
    case List.filter (\s -> elapsed < Cycle.hours s.to) Cycle.stages of
        stage :: _ ->
            stage

        [] ->
            Maybe.withDefault fallbackStage (last Cycle.stages)


fallbackStage : Cycle.Stage
fallbackStage =
    Cycle.Stage "V" 72 96 "Optional extension" "Optional extension"


{-| What the stance says out loud, in the display voice's register.
-}
stanceLabel : Stance -> String
stanceLabel stance =
    case stance of
        Waiting ->
            "Before priming"

        Priming day ->
            "Priming — day " ++ String.fromInt day ++ " of 3"

        Fasting stage ->
            "Stage " ++ stage.numeral ++ " — " ++ String.toLower stage.title

        Refeeding day ->
            "Refeed — day " ++ String.fromInt day ++ " of 2"

        Rebuilding day ->
            "Rebuild — day " ++ String.fromInt day

        Complete ->
            "Cycle complete"


{-| Whether the reader is inside the cycle rather than reading about
one. The clock leads with this, and it is the difference between a
schedule and an instrument.
-}
inFlight : Stance -> Bool
inFlight stance =
    case stance of
        Waiting ->
            False

        Complete ->
            False

        _ ->
            True


{-| The headline figure: hours and minutes since hour 0, signed. Past
two days in either direction it switches to days and hours, because
"−312:40" is a true statement nobody can read at a glance.
-}
elapsedFigure : Int -> String
elapsedFigure minutes =
    (if minutes < 0 then
        "−"

     else
        ""
    )
        ++ magnitude (abs minutes)


{-| How far off something still is. Always positive — a countdown to
something already past is not a countdown.
-}
countdown : Int -> String
countdown minutes =
    magnitude (abs minutes)


magnitude : Int -> String
magnitude minutes =
    if minutes >= Cycle.days 2 then
        String.fromInt (minutes // 1440)
            ++ " d "
            ++ String.fromInt (modBy 1440 minutes // 60)
            ++ " h"

    else
        String.fromInt (minutes // 60)
            ++ ":"
            ++ String.padLeft 2 '0' (String.fromInt (modBy 60 minutes))


{-| Elm's `//` truncates toward zero, which counts the priming days
wrong on the negative side of hour 0.
-}
floorDiv : Int -> Int -> Int
floorDiv a b =
    if a < 0 then
        -((-a + b - 1) // b)

    else
        a // b


last : List a -> Maybe a
last =
    List.reverse >> List.head
