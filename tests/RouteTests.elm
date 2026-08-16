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
            , test "unknown paths fall back to the protocol sheet" <|
                \_ -> Route.fromUrl (urlAt "/no-such-page") |> Expect.equal Protocol
            ]
        , describe "toPath round-trips through fromUrl"
            (List.map
                (\route ->
                    test (Route.title route) <|
                        \_ ->
                            Route.fromUrl (urlAt (Route.toPath route))
                                |> Expect.equal route
                )
                [ Protocol, Resources ]
            )
        ]
