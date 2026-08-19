module Route exposing (Route(..), fromUrl, parse, queryParam, title, toPath, withQuery)

{-| Client routes. Pure: no Cmd, no ports — fully unit-testable
(`tests/RouteTests.elm`).

Adding a route here means adding a line to `public/_redirects`, by
name. That friction is deliberate: see the 404 contract in
docs/DEPLOY.md for what a wildcard rule would break.

-}

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, oneOf, s, top)


type Route
    = -- the protocol broadsheet (`Page.Protocol`) — the home page
      Protocol
      -- the cycle planner (`Page.Plan`), dated from `?start=`
    | Plan
      -- §07's requirements converted into grams (`Page.Dosing`)
    | Dosing
      -- the source index (`Page.Resources`)
    | Resources
      -- the terms and disclaimers (`Page.Legal`)
    | Legal


{-| The address of a page. Lowercase, hyphenated.
-}
toPath : Route -> String
toPath route =
    case route of
        Protocol ->
            "/"

        Plan ->
            "/plan"

        Dosing ->
            "/dosing"

        Resources ->
            "/resources"

        Legal ->
            "/legal"


{-| The document title. `Browser.application` owns the title, so
`index.html`'s `<title>` is only what shows before Elm boots — the
protocol page's title matches it so the swap is invisible.
-}
title : Route -> String
title route =
    case route of
        Protocol ->
            "AUTOPHAGOUS — DEMOLITION AND REBUILD"

        Plan ->
            "AUTOPHAGOUS — CYCLE PLANNER"

        Dosing ->
            "AUTOPHAGOUS — ELECTROLYTE DOSING"

        Resources ->
            "AUTOPHAGOUS — SOURCE INDEX"

        Legal ->
            "AUTOPHAGOUS — TERMS AND DISCLAIMERS"


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Protocol top
        , Parser.map Plan (s "plan")
        , Parser.map Dosing (s "dosing")
        , Parser.map Resources (s "resources")
        , Parser.map Legal (s "legal")
        ]


{-| Read a route off a URL, or `Nothing` if the path is not one of
ours.

The shell needs the honest answer, not the fallback: a same-origin link
that is _not_ a route is a static asset (`/downloads/cycle-log.pdf`),
and `Browser.application` intercepts its click like any other. Told
`Nothing`, the shell hands the click back to the browser instead of
pushing a URL that would silently re-render the protocol sheet.

-}
parse : Url -> Maybe Route
parse url =
    Parser.parse parser url


{-| Read a route off a URL. Unknown paths fall back to the protocol
sheet rather than erroring — the right behaviour for an address typed
or shared by hand. Use `parse` when the difference matters.
-}
fromUrl : Url -> Route
fromUrl url =
    parse url
        |> Maybe.withDefault Protocol


{-| One query parameter, decoded — the planner's `?start=` and
`?target=`, which is what makes a plan a shareable address rather
than a thing living in one browser's storage.

Hand-rolled rather than `Url.Parser.Query`, which only reads a query
as part of parsing a whole URL: the shell needs the parameters off a
URL it has already routed. The last `=` is not special (values are
rejoined), and a value that fails to decode reads as empty rather
than absent — either way the planner falls back to its own default.

-}
queryParam : String -> Url -> Maybe String
queryParam key url =
    url.query
        |> Maybe.map (String.split "&")
        |> Maybe.withDefault []
        |> List.filterMap (matchParam key)
        |> List.head


matchParam : String -> String -> Maybe String
matchParam key raw =
    case String.split "=" raw of
        k :: rest ->
            if k == key then
                Just (Maybe.withDefault "" (Url.percentDecode (String.join "=" rest)))

            else
                Nothing

        [] ->
            Nothing


{-| A route's address carrying state. Empty values are dropped, so a
half-filled form produces a clean URL rather than `?start=&target=`.
-}
withQuery : Route -> List ( String, String ) -> String
withQuery route params =
    case List.filter (\( _, v ) -> v /= "") params of
        [] ->
            toPath route

        kept ->
            toPath route
                ++ "?"
                ++ String.join "&"
                    (List.map (\( k, v ) -> k ++ "=" ++ Url.percentEncode v) kept)
