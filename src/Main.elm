port module Main exposing (main)

{-| The TEA shell: URL wiring, the site nav, the theme control, page
dispatch — and the viewport. `Browser.application` intercepts every
internal link click, including the contents rail's `#anchor` jumps, so
the default scroll-to-fragment never happens; the shell re-implements
it with `Browser.Dom`.

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
import Html.Attributes exposing (attribute, class, classList, href, id, type_)
import Html.Events exposing (onClick)
import Page.Legal
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
            case Route.parse url of
                Just _ ->
                    -- push only; the model's route is set by UrlChanged coming back
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Nothing ->
                    -- Same origin but not a route: a static asset, like the
                    -- compiled cycle log. `Browser.application` intercepts
                    -- every same-origin click, so pushing here would swap the
                    -- address bar and re-render the protocol sheet while the
                    -- file never loads. Hand it back to the browser.
                    ( model, Nav.load (Url.toString url) )

        LinkClicked (Browser.External href_) ->
            ( model, Nav.load href_ )

        SetTheme theme ->
            ( { model | theme = theme }, saveTheme (themeToString theme) )

        NoOp ->
            ( model, Cmd.none )


{-| Scroll the window to an anchor. `Dom.getElement` reports
scene-relative coordinates, so the element's y IS the viewport offset —
less whatever the sticky chrome covers, or the section head lands
underneath it. A missing anchor resolves to a no-op, not a crash.
-}
jumpTo : String -> Cmd Msg
jumpTo anchor =
    Task.map2 (\info chrome -> info.element.y - chrome - jumpGap)
        (Dom.getElement anchor)
        stickyChromeHeight
        |> Task.andThen (Dom.setViewport 0)
        |> Task.attempt (\_ -> NoOp)


{-| Air between the sticky chrome and the section head it reveals.
-}
jumpGap : Float
jumpGap =
    8


{-| How much of the viewport top the sticky chrome covers right now:
the site nav always, plus the contents rail when it is worn as the
jump-strip. Measured rather than hard-coded against the breakpoint, so
this number cannot drift from the CSS that produces it.
-}
stickyChromeHeight : Task.Task x Float
stickyChromeHeight =
    Task.map2 (+) (coveredHeight "site-nav") stripHeight


{-| An element's height, or nothing covered if it isn't on the page.
-}
coveredHeight : String -> Task.Task x Float
coveredHeight domId =
    Dom.getElement domId
        |> Task.map (.element >> .height)
        |> Task.onError (\_ -> Task.succeed 0)


{-| The rail overlays the text only in its jump-strip form (≤960px),
where it spans the viewport; as the desktop rail it holds the left
margin and covers nothing. Its width tells the two apart, which keeps
the breakpoint itself in the stylesheet where it belongs.
-}
stripHeight : Task.Task x Float
stripHeight =
    Dom.getElement "doc-toc"
        |> Task.map
            (\info ->
                if info.element.width > info.viewport.width * 0.9 then
                    info.element.height

                else
                    0
            )
        |> Task.onError (\_ -> Task.succeed 0)



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

            Route.Legal ->
                Page.Legal.view
        ]
    }


siteNav : Model -> Html Msg
siteNav model =
    nav [ id "site-nav", class "site-nav" ]
        [ span [ class "brand u" ] [ text "Autophagous" ]
        , div [ class "nav-right" ]
            [ div [ class "nav-links u" ]
                [ navLink model.route Route.Protocol "Protocol"
                , navLink model.route Route.Resources "Resources"
                , navLink model.route Route.Legal "Legal"
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
