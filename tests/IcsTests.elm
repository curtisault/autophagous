module IcsTests exposing (suite)

{-| A calendar file is written once and read by software that will not
tell you it gave up. These cover the two things that silently break
one — escaping and line length — plus the structural invariants of the
export as a whole.
-}

import Cycle exposing (Target(..))
import Expect
import Ics
import Test exposing (Test, describe, test)
import Time


start : Time.Posix
start =
    -- 2026-09-01T20:00Z
    Time.millisToPosix 1788292800000


export : Target -> String
export target =
    Ics.calendar
        { zone = Time.utc
        , now = Time.millisToPosix 1787000000000
        , start = start
        , target = target
        , origin = "https://autophagous.test"
        }


lines : String -> List String
lines =
    String.split "\u{000D}\n"


countOf : String -> String -> Int
countOf needle haystack =
    List.length (String.indexes needle haystack)


{-| The longest line as UTF-8 octets, which is what the 75-octet limit
counts and what a character-based fold would get wrong.
-}
longestLine : String -> Int
longestLine ics =
    lines ics
        |> List.map (String.foldl (\c n -> n + octets c) 0)
        |> List.maximum
        |> Maybe.withDefault 0


octets : Char -> Int
octets c =
    let
        code =
            Char.toCode c
    in
    if code < 0x80 then
        1

    else if code < 0x0800 then
        2

    else
        3


suite : Test
suite =
    describe "Ics"
        [ describe "escape"
            [ test "escapes the three TEXT specials and the newline" <|
                \_ ->
                    Ics.escape "a,b;c\\d\ne"
                        |> Expect.equal "a\\,b\\;c\\\\d\\ne"
            , test "does not double-escape its own backslashes" <|
                \_ -> Ics.escape "," |> Expect.equal "\\,"
            ]
        , describe "fold"
            [ test "leaves a short line alone" <|
                \_ -> Ics.fold "SUMMARY:short" |> Expect.equal "SUMMARY:short"
            , test "breaks a long line with CRLF and a leading space" <|
                \_ ->
                    Ics.fold (String.repeat 100 "a")
                        |> String.contains "\u{000D}\n "
                        |> Expect.equal True
            , test "unfolding returns the original" <|
                \_ ->
                    let
                        original =
                            String.repeat 40 "ab·"
                    in
                    Ics.fold original
                        |> String.replace "\u{000D}\n " ""
                        |> Expect.equal original
            ]
        , describe "the exported calendar"
            [ test "is a single well-closed VCALENDAR" <|
                \_ ->
                    ( countOf "BEGIN:VCALENDAR" (export T72)
                    , countOf "END:VCALENDAR" (export T72)
                    )
                        |> Expect.equal ( 1, 1 )
            , test "opens and closes every event" <|
                \_ ->
                    countOf "END:VEVENT" (export T72)
                        |> Expect.equal (countOf "BEGIN:VEVENT" (export T72))
            , test "carries one event per scheduled line" <|
                \_ ->
                    countOf "BEGIN:VEVENT" (export T96)
                        |> Expect.equal
                            (List.length (List.concatMap .entries (Cycle.plan T96)))
            , test "no line exceeds the 75-octet limit" <|
                \_ -> longestLine (export T96) |> Expect.atMost 75
            , test "ends with a line break, as the RFC requires" <|
                \_ ->
                    String.endsWith "END:VCALENDAR\u{000D}\n" (export T72)
                        |> Expect.equal True
            , test "gives every event a distinct UID" <|
                \_ ->
                    let
                        uids =
                            lines (export T96) |> List.filter (String.startsWith "UID:")
                    in
                    List.length uids
                        |> Expect.equal (List.length (dedupe (List.sort uids)))
            , test "derives UIDs from the start, so a re-export updates rather than duplicates" <|
                \_ ->
                    lines (export T72)
                        |> List.filter (String.startsWith "UID:")
                        |> List.head
                        |> Expect.equal (Just "UID:ap-1788292800000-0@autophagous")
            , test "dates the fast from the start instant" <|
                \_ ->
                    String.contains "DTSTART:20260901T200000Z" (export T72)
                        |> Expect.equal True
            , test "breaks a 72 h fast 72 hours later, to the minute" <|
                \_ ->
                    String.contains "DTSTART:20260904T200000Z" (export T72)
                        |> Expect.equal True
            , test "sends the reader back to the protocol, not just to a summary" <|
                \_ ->
                    String.contains "https://autophagous.test/#sec-refeed" (export T72)
                        |> Expect.equal True
            , test "keeps the potassium instruction intact through escaping and folding" <|
                \_ ->
                    export T72
                        |> String.replace "\u{000D}\n " ""
                        |> String.contains "potassium 1\\,000–3\\,000 mg in small divided doses\\, never one large dose"
                        |> Expect.equal True
            ]
        ]


dedupe : List String -> List String
dedupe sorted =
    case sorted of
        a :: b :: rest ->
            if a == b then
                dedupe (b :: rest)

            else
                a :: dedupe (b :: rest)

        _ ->
            sorted
