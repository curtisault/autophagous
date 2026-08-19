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

The planner (`Page.Plan`) adds the shell's other two pieces of state:
the reader's time zone, and the start instant they typed. **The URL is
where the plan lives** — `Nav.replaceUrl` mirrors the form into
`?start=&target=` on every change, so the address bar is a shareable
plan and nothing has to be stored. That mirroring is why `UrlChanged`
now asks whether the _route_ changed rather than treating every URL
change as a navigation: a replaced query is the shell hearing its own
echo, and must not scroll the page to the top or re-read the form out
from under the reader.

-}

import Browser
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Civil
import Cycle exposing (Target)
import Html exposing (Html, a, button, div, nav, span, text)
import Html.Attributes exposing (attribute, class, classList, href, id, type_)
import Html.Events exposing (onClick)
import Ics
import Page.Legal
import Page.Plan
import Page.Protocol
import Page.Resources
import Route exposing (Route)
import Task
import Time
import Url exposing (Url)


port saveTheme : String -> Cmd msg


{-| Which section the reader is currently inside, reported by boot.js.

This is a port because `elm/browser` has no scroll subscription — it
offers resize, visibility, keys, clicks and animation frames, and
nothing for the one event a contents rail needs. The alternative was
polling `Browser.Dom.getViewport` every animation frame to answer a
question that changes a few times a minute.

-}
port sectionSeen : (String -> msg) -> Sub msg


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
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

    -- the planner's state. `zone` is UTC and `now` is Nothing until
    -- `Time.here`/`Time.now` land, which is one frame; until then the
    -- planner renders its schedule in relative offsets and its clock
    -- not at all, so nothing false is ever on screen.
    , zone : Time.Zone
    , now : Maybe Time.Posix
    , planStart : String
    , planTarget : Target

    -- the section under the reader's eye, marked in the contents rail.
    -- Reported by boot.js through `sectionSeen`; cleared on navigation
    -- so a stale anchor cannot mark the wrong row on the next page —
    -- `sec-fast` exists on both the protocol and the planner
    , active : Maybe String

    -- the section the reader is parked on, so mirroring the form into
    -- the URL cannot silently drop their `#anchor`
    , fragment : Maybe String

    -- this site's own base URL, kept for the calendar export: every
    -- event links back to the protocol section it came from, and a
    -- relative link is meaningless once the file has left the browser
    , origin : String
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , route = Route.fromUrl url
      , theme = themeFromFlag flags.theme
      , zone = Time.utc
      , now = Nothing
      , planStart = Maybe.withDefault "" (Route.queryParam "start" url)
      , planTarget = Cycle.targetFromParam (Route.queryParam "target" url)
      , fragment = url.fragment
      , active = Nothing
      , origin = originOf url
      }
    , Cmd.batch
        [ Task.perform identity (Task.map2 GotContext Time.here Time.now)

        -- a cold load with a fragment (a shared deep link) still owes a
        -- jump — the browser can't do it because Elm renders after load
        , case url.fragment of
            Just anchor ->
                jumpTo anchor

            Nothing ->
                Cmd.none
        ]
    )


originOf : Url -> String
originOf url =
    Url.toString { url | path = "", query = Nothing, fragment = Nothing }



-- UPDATE


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | SetTheme Theme
    | GotContext Time.Zone Time.Posix
    | PlanStartChanged String
    | PlanTargetChanged Target
    | Tick Time.Posix
    | SectionSeen String
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            let
                route =
                    Route.fromUrl url

                -- a replaced query on the page you are already reading is
                -- not a navigation: it is this shell mirroring the
                -- planner's form into the address bar
                arrived =
                    route /= model.route

                landed =
                    { model
                        | route = route
                        , fragment = url.fragment
                        , active =
                            if route /= model.route then
                                Nothing

                            else
                                model.active
                    }

                updated =
                    if arrived then
                        applyQuery url landed

                    else
                        landed
            in
            ( updated
            , Cmd.batch
                [ case url.fragment of
                    Just anchor ->
                        jumpTo anchor

                    Nothing ->
                        if arrived then
                            -- a page change starts at the top, like a page load
                            Task.perform (\_ -> NoOp) (Dom.setViewport 0 0)

                        else
                            Cmd.none
                , if arrived && route == Route.Plan then
                    -- arriving from the nav carries no query, so put the
                    -- form's own state back into the URL: the planner
                    -- promises the address bar is the plan
                    syncPlanUrl updated

                  else
                    Cmd.none
                ]
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

        GotContext zone now ->
            let
                updated =
                    { model
                        | zone = zone
                        , now = Just now
                        , planStart =
                            if model.planStart == "" then
                                -- an empty planner is a worse teacher than a
                                -- populated one, so it proposes the next whole
                                -- hour. It is a proposal: the reader's real
                                -- hour 0 is whenever their last meal ends.
                                nextWholeHour zone now

                            else
                                model.planStart
                    }
            in
            ( updated
            , if model.route == Route.Plan then
                syncPlanUrl updated

              else
                Cmd.none
            )

        PlanStartChanged raw ->
            let
                updated =
                    { model | planStart = raw }
            in
            ( updated, syncPlanUrl updated )

        PlanTargetChanged target ->
            let
                updated =
                    { model | planTarget = target }
            in
            ( updated, syncPlanUrl updated )

        Tick now ->
            ( { model | now = Just now }, Cmd.none )

        SectionSeen anchor ->
            ( { model
                | active =
                    if anchor == "" then
                        Nothing

                    else
                        Just anchor
              }
            , Cmd.none
            )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


{-| The live clock, and the only subscription this site has.

A minute, not a second: the clock reads in hours and minutes, so a
faster tick would re-render the same string. Only while the planner is
on screen — the protocol sheet has nothing that changes, and a
background timer on a document is a battery cost with no reader.

This is not motion. The figure does not travel from one value to the
next, it is simply a different fact the next time the minute changes
(DESIGN-REQUIREMENTS §1, amended 2026-08-18).

-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ sectionSeen SectionSeen
        , if model.route == Route.Plan then
            Time.every 60000 Tick

          else
            Sub.none
        ]



-- THE PLANNER'S URL


{-| Read the planner's state off a URL, keeping what the URL does not
mention. A nav click carries no query and must not wipe a form the
reader has already filled in; a shared link carries both and must win.
-}
applyQuery : Url -> Model -> Model
applyQuery url model =
    { model
        | planStart = Maybe.withDefault model.planStart (Route.queryParam "start" url)
        , planTarget =
            case Route.queryParam "target" url of
                Just raw ->
                    Cycle.targetFromParam (Just raw)

                Nothing ->
                    model.planTarget
    }


{-| Mirror the form into the address bar, keeping whichever section
the reader is parked on — `replaceUrl`, not `pushUrl`, so typing a
date does not fill the back button with keystrokes.
-}
syncPlanUrl : Model -> Cmd Msg
syncPlanUrl model =
    Nav.replaceUrl model.key
        (Route.withQuery Route.Plan
            [ ( "start", model.planStart )
            , ( "target", Cycle.targetParam model.planTarget )
            ]
            ++ (case model.fragment of
                    Just anchor ->
                        "#" ++ anchor

                    Nothing ->
                        ""
               )
        )


{-| The top of the next hour, on the reader's own clock. Computed
through the zone rather than by rounding the epoch: not every offset
is a whole number of hours.
-}
nextWholeHour : Time.Zone -> Time.Posix -> String
nextWholeHour zone now =
    let
        wall =
            Civil.fromPosix zone now
    in
    Civil.shift 60 (Civil.toPosix zone { wall | minute = 0, second = 0 })
        |> Civil.fromPosix zone
        |> Civil.toIso


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
                Page.Protocol.view model.active

            Route.Plan ->
                Page.Plan.view (planContext model)

            Route.Resources ->
                Page.Resources.view model.active

            Route.Legal ->
                Page.Legal.view model.active
        ]
    }


{-| Everything the planner renders from. The start instant is derived
here rather than stored: the field is a string the reader is halfway
through typing, and `Nothing` — not a stale instant — is the honest
reading of a half-typed date.
-}
planContext : Model -> Page.Plan.Context Msg
planContext model =
    let
        start =
            Civil.fromIso model.planStart
                |> Maybe.map (Civil.toPosix model.zone)
    in
    { zone = model.zone
    , start = start
    , now = model.now
    , startValue = model.planStart
    , target = model.planTarget
    , download = Maybe.map (calendarFile model) start
    , active = model.active
    , onStart = PlanStartChanged
    , onTarget = PlanTargetChanged
    }


calendarFile : Model -> Time.Posix -> { href : String, name : String }
calendarFile model start =
    { href =
        Ics.dataUri
            (Ics.calendar
                { zone = model.zone

                -- DTSTAMP is when the file was produced; before the
                -- clock lands, the start instant stands in. Never the
                -- epoch — a 1970 stamp is a file some calendars bin
                , now = Maybe.withDefault start model.now
                , start = start
                , target = model.planTarget
                , origin = model.origin
                }
            )
    , name = Ics.fileName model.zone start
    }


siteNav : Model -> Html Msg
siteNav model =
    nav [ id "site-nav", class "site-nav" ]
        [ span [ class "brand u" ] [ text "Autophagous" ]
        , div [ class "nav-right" ]
            [ div [ class "nav-links u" ]
                [ navLink model.route Route.Protocol "Protocol"
                , navLink model.route Route.Plan "Plan"
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
