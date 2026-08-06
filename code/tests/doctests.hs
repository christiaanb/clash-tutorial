-- `import Prelude` is needed because common-options turns on NoImplicitPrelude,
-- which leaves `IO` out of scope here. The template carries the same line, for
-- the same reason; see V19 in design/03-verification-queue.md.
import Prelude
import Test.DocTest (mainFromCabal)
import System.Environment (getArgs)

main :: IO ()
main = mainFromCabal "clash-tutorial-chapters" =<< getArgs
