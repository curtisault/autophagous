module Expectations exposing (expectAll)

{-| The one helper more than one suite wanted. `Expect.all` takes
functions; a list of already-made expectations is what a `List.map`
over cases produces, so this closes the gap once instead of once per
test file.
-}

import Expect


expectAll : List Expect.Expectation -> Expect.Expectation
expectAll expectations =
    Expect.all (List.map always expectations) ()
