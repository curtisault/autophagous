module Viewport exposing (Action(..), actionFor)

{-| Whether a URL change should move the reader, and where to.

Three things change the URL here and only one of them is a
navigation:

1.  a real navigation — a nav link, a rail link, a shared address;
2.  a fragment jump within the page;
3.  **the shell mirroring a control into the address bar** — the
    planner's start date, the dosing sheet's doses per day.

The third is an echo. `Browser.application` reports it through
`onUrlChange` exactly like the other two, and treating it like them is
how the dosing sheet came to yank the reader up the page on every
click of a control: the URL carried `#sec-dose-set` from an earlier
rail click, so each echo re-ran that jump, and §01 is the top of the
document.

Pure, and separated out precisely because the guard is easy to get
half-right — the first version guarded the scroll-to-top and forgot
the anchor jump. `ViewportTests` holds the whole table.

-}


type Action
    = -- leave the reader where they are
      Stay
      -- a new page starts at the top, like a page load
    | ToTop
      -- a fragment: put this anchor under the sticky chrome
    | ToAnchor String


{-| `mirroring` is the shell's own echo — nothing it produces has
moved the reader, so nothing about it should move them either.
-}
actionFor : { mirroring : Bool, arrived : Bool, fragment : Maybe String } -> Action
actionFor context =
    if context.mirroring then
        Stay

    else
        case context.fragment of
            Just anchor ->
                ToAnchor anchor

            Nothing ->
                if context.arrived then
                    ToTop

                else
                    Stay
