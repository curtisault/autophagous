module Route exposing (Route(..), fromUrl, parse, title, toPath)

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

        Resources ->
            "AUTOPHAGOUS — SOURCE INDEX"

        Legal ->
            "AUTOPHAGOUS — TERMS AND DISCLAIMERS"


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Protocol top
        , Parser.map Resources (s "resources")
        , Parser.map Legal (s "legal")
        ]


{-| Read a route off a URL, or `Nothing` if the path is not one of
ours.

The shell needs the honest answer, not the fallback: a same-origin link
that is *not* a route is a static asset (`/downloads/cycle-log.pdf`),
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
