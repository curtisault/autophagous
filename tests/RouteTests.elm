module RouteTests exposing (suite)

import Expect
import Route exposing (Route(..))
import Test exposing (Test, describe, test)
import Url


urlAt : String -> Url.Url
urlAt path =
    { protocol = Url.Https
    , host = "example.test"
    , port_ = Nothing
    , path = path
    , query = Nothing
    , fragment = Nothing
    }


urlWith : String -> String -> Url.Url
urlWith path query =
    { protocol = Url.Https
    , host = "example.test"
    , port_ = Nothing
    , path = path
    , query = Just query
    , fragment = Nothing
    }


suite : Test
suite =
    describe "Route"
        [ describe "fromUrl"
            [ test "root is the protocol sheet" <|
                \_ -> Route.fromUrl (urlAt "/") |> Expect.equal Protocol
            , test "/plan is the cycle planner" <|
                \_ -> Route.fromUrl (urlAt "/plan") |> Expect.equal Plan
            , test "a shared plan still routes with its query attached" <|
                \_ ->
                    Route.fromUrl (urlWith "/plan" "start=2026-09-01T20:00&target=96")
                        |> Expect.equal Plan
            , test "/resources is the archive" <|
                \_ -> Route.fromUrl (urlAt "/resources") |> Expect.equal Resources
            , test "/legal is the terms and disclaimers" <|
                \_ -> Route.fromUrl (urlAt "/legal") |> Expect.equal Legal
            , test "unknown paths fall back to the protocol sheet" <|
                \_ -> Route.fromUrl (urlAt "/no-such-page") |> Expect.equal Protocol
            ]
        , describe "parse tells routes from static assets"
            -- the shell branches on this: a same-origin link that is not a
            -- route must be handed back to the browser, or Browser.application
            -- swallows the click and the file never downloads
            [ test "a downloadable asset is not a route" <|
                \_ -> Route.parse (urlAt "/downloads/cycle-log.pdf") |> Expect.equal Nothing
            , test "fromUrl still falls back for that same path" <|
                \_ -> Route.fromUrl (urlAt "/downloads/cycle-log.pdf") |> Expect.equal Protocol
            , test "real routes still parse" <|
                \_ -> Route.parse (urlAt "/legal") |> Expect.equal (Just Legal)
            ]
        , describe "toPath round-trips through fromUrl"
            (List.map
                (\route ->
                    test (Route.title route) <|
                        \_ ->
                            Route.fromUrl (urlAt (Route.toPath route))
                                |> Expect.equal route
                )
                -- every Route variant belongs here; the compiler cannot
                -- check a hand-written list, so adding a route means
                -- adding it below as well
                [ Protocol, Plan, Resources, Legal ]
            )
        , describe "queryParam reads the planner's state off a URL"
            [ test "finds a parameter" <|
                \_ ->
                    Route.queryParam "target" (urlWith "/plan" "start=2026-09-01T20:00&target=96")
                        |> Expect.equal (Just "96")
            , test "decodes the value" <|
                \_ ->
                    Route.queryParam "start" (urlWith "/plan" "start=2026-09-01T20%3A00")
                        |> Expect.equal (Just "2026-09-01T20:00")
            , test "an absent parameter is Nothing, not empty" <|
                -- the shell branches on this: absent keeps whatever the
                -- form already holds, empty clears it
                \_ ->
                    Route.queryParam "start" (urlWith "/plan" "target=72")
                        |> Expect.equal Nothing
            , test "no query at all is Nothing" <|
                \_ -> Route.queryParam "start" (urlAt "/plan") |> Expect.equal Nothing
            , test "an empty value reads as empty" <|
                \_ ->
                    Route.queryParam "start" (urlWith "/plan" "start=")
                        |> Expect.equal (Just "")
            , test "a key that only prefixes another is not a match" <|
                \_ ->
                    Route.queryParam "start" (urlWith "/plan" "started=yes")
                        |> Expect.equal Nothing
            ]
        , describe "withQuery builds the shareable address"
            [ test "carries the state" <|
                \_ ->
                    Route.withQuery Plan [ ( "start", "2026-09-01T20:00" ), ( "target", "72" ) ]
                        |> Expect.equal "/plan?start=2026-09-01T20%3A00&target=72"
            , test "drops empty values rather than writing ?start=" <|
                \_ ->
                    Route.withQuery Plan [ ( "start", "" ), ( "target", "96" ) ]
                        |> Expect.equal "/plan?target=96"
            , test "with nothing to carry it is just the path" <|
                \_ -> Route.withQuery Plan [ ( "start", "" ) ] |> Expect.equal "/plan"
            , test "round-trips back through queryParam" <|
                \_ ->
                    Route.withQuery Plan [ ( "start", "2026-09-01T20:00" ) ]
                        |> (++) "https://example.test"
                        |> Url.fromString
                        |> Maybe.andThen (Route.queryParam "start")
                        |> Expect.equal (Just "2026-09-01T20:00")
            ]
        ]
