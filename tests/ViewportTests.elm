module ViewportTests exposing (suite)

{-| The whole table, because the guard has now been got wrong twice.

First version: no guard at all, so every URL change scrolled to the
top — including the planner mirroring a keystroke into the address
bar. Second version: guarded the scroll-to-top and forgot the anchor
jump, so a control click re-ran whatever fragment the URL happened to
be carrying, and on the dosing sheet that meant being yanked to §01
every time.

-}

import Expect
import Test exposing (Test, describe, test)
import Viewport exposing (Action(..))


at : Bool -> Bool -> Maybe String -> Action
at mirroring arrived fragment =
    Viewport.actionFor
        { mirroring = mirroring, arrived = arrived, fragment = fragment }


suite : Test
suite =
    describe "Viewport.actionFor"
        [ describe "a real navigation"
            [ test "a new page starts at the top" <|
                \_ -> at False True Nothing |> Expect.equal ToTop
            , test "unless it names a section" <|
                \_ -> at False True (Just "sec-fast") |> Expect.equal (ToAnchor "sec-fast")
            ]
        , describe "a fragment on the page you are already reading"
            [ test "jumps — this is what a rail link is" <|
                \_ -> at False False (Just "sec-refeed") |> Expect.equal (ToAnchor "sec-refeed")
            , test "and without one, nothing moves" <|
                \_ -> at False False Nothing |> Expect.equal Stay
            ]
        , describe "the shell's own echo moves nobody"
            [ test "not to the top" <|
                \_ -> at True True Nothing |> Expect.equal Stay
            , test "and not to an anchor the URL is still carrying" <|
                -- the dosing sheet's bug: a rail click leaves
                -- `#sec-dose-set` in the URL, and every later control
                -- click re-jumped to it — which is the top of the page
                \_ -> at True False (Just "sec-dose-set") |> Expect.equal Stay
            , test "even on arrival, when the shell writes the URL back" <|
                \_ -> at True True (Just "sec-dose-each") |> Expect.equal Stay
            ]
        ]
