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


suite : Test
suite =
    describe "Route"
        [ describe "fromUrl"
            [ test "root is the protocol sheet" <|
                \_ -> Route.fromUrl (urlAt "/") |> Expect.equal Protocol
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
                [ Protocol, Resources, Legal ]
            )
        ]
