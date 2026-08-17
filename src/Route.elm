module Route exposing (Route(..), fromUrl, title, toPath)

{-| Client routes. Pure: no Cmd, no ports — fully unit-testable
(`tests/RouteTests.elm`).

Adding a route here means adding a line to `public/_redirects` —
that friction is deliberate (inherited policy from cryovault).

-}

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, oneOf, s, top)


type Route
    = -- the protocol broadsheet (`Page.Protocol`) — the home page
      Protocol
      -- the citations archive (`Page.Resources`)
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
            "AUTOPHAGOUS — RESOURCES ARCHIVE"

        Legal ->
            "AUTOPHAGOUS — TERMS AND DISCLAIMERS"


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Protocol top
        , Parser.map Resources (s "resources")
        , Parser.map Legal (s "legal")
        ]


{-| Read a route off a URL. Unknown paths fall back to the protocol
sheet rather than erroring.
-}
fromUrl : Url -> Route
fromUrl url =
    Parser.parse parser url
        |> Maybe.withDefault Protocol
