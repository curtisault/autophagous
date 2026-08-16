port module Main exposing (main)

{-| The TEA shell: URL wiring, the site nav, the theme control, page
dispatch — and the viewport. `Browser.application` intercepts every
internal link click, including the contents rail's `#anchor` jumps, so
the default scroll-to-fragment never happens; the shell re-implements
it with `Browser.Dom` (same problem cryovault's shell solves).

Theme (theme plan Phase 3): the shell owns the three-state preference
(System / Light / Dark). The palette itself is pure CSS — `theme.css`
reads `prefers-color-scheme` and the `data-theme` attribute on
`<html>`. Elm owns only `<body>`, so applying the attribute and
persisting the choice is boot.js's job, reached through the
`saveTheme` port; "system" clears both, which hands control back to
the media query and live OS changes.

-}

import Browser
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Html exposing (Html, a, button, div, nav, span, text)
import Html.Attributes exposing (attribute, class, classList, href, type_)
import Html.Events exposing (onClick)
import Page.Protocol
import Page.Resources
import Route exposing (Route)
import Task
import Url exposing (Url)


port saveTheme : String -> Cmd msg


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- THEME


type Theme
    = System
    | Light
    | Dark


themeToString : Theme -> String
themeToString theme =
    case theme of
        System ->
            "system"

        Light ->
            "light"

        Dark ->
            "dark"


themeFromFlag : Maybe String -> Theme
themeFromFlag stored =
    case stored of
        Just "light" ->
            Light

        Just "dark" ->
            Dark

        _ ->
            System


themeLabel : Theme -> String
themeLabel theme =
    case theme of
        System ->
            "System"

        Light ->
            "Light"

        Dark ->
            "Dark"



-- MODEL


type alias Flags =
    { theme : Maybe String }


type alias Model =
    { key : Nav.Key
    , route : Route
    , theme : Theme
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , route = Route.fromUrl url
      , theme = themeFromFlag flags.theme
      }
      -- a cold load with a fragment (a shared deep link) still owes a
      -- jump — the browser can't do it because Elm renders after load
    , case url.fragment of
        Just anchor ->
            jumpTo anchor

        Nothing ->
            Cmd.none
    )



-- UPDATE


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | SetTheme Theme
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            ( { model | route = Route.fromUrl url }
            , case url.fragment of
                Just anchor ->
                    jumpTo anchor

                Nothing ->
                    -- a page change starts at the top, like a page load
                    Task.perform (\_ -> NoOp) (Dom.setViewport 0 0)
            )

        LinkClicked (Browser.Internal url) ->
            -- push only; the model's route is set by UrlChanged coming back
            ( model, Nav.pushUrl model.key (Url.toString url) )

        LinkClicked (Browser.External href_) ->
            ( model, Nav.load href_ )

        SetTheme theme ->
            ( { model | theme = theme }, saveTheme (themeToString theme) )

        NoOp ->
            ( model, Cmd.none )


{-| Scroll the window to an anchor. `Dom.getElement` reports
scene-relative coordinates, so the element's y IS the viewport offset;
the small subtraction keeps the section head clear of the mobile rail,
which is sticky. A missing anchor resolves to a no-op, not a crash.
-}
jumpTo : String -> Cmd Msg
jumpTo anchor =
    Dom.getElement anchor
        |> Task.andThen (\info -> Dom.setViewport 0 (info.element.y - 56))
        |> Task.attempt (\_ -> NoOp)



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = Route.title model.route
    , body =
        [ siteNav model
        , case model.route of
            Route.Protocol ->
                Page.Protocol.view

            Route.Resources ->
                Page.Resources.view
        ]
    }


siteNav : Model -> Html Msg
siteNav model =
    nav [ class "site-nav" ]
        [ span [ class "brand u" ] [ text "Autophagous" ]
        , div [ class "nav-right" ]
            [ div [ class "nav-links u" ]
                [ navLink model.route Route.Protocol "Protocol"
                , navLink model.route Route.Resources "Resources"
                ]
            , themeControl model.theme
            ]
        ]


navLink : Route -> Route -> String -> Html msg
navLink current target label =
    a
        [ href (Route.toPath target)
        , classList [ ( "active", current == target ) ]
        ]
        [ text label ]


themeControl : Theme -> Html Msg
themeControl current =
    div
        [ class "theme-control"
        , attribute "role" "group"
        , attribute "aria-label" "Theme"
        ]
        (List.map (themeButton current) [ System, Light, Dark ])


themeButton : Theme -> Theme -> Html Msg
themeButton current theme =
    button
        [ type_ "button"
        , class "theme-btn u"
        , classList [ ( "active", theme == current ) ]
        , attribute "aria-pressed"
            (if theme == current then
                "true"

             else
                "false"
            )
        , onClick (SetTheme theme)
        ]
        [ text (themeLabel theme) ]
