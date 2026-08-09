import Prelude
import System.Environment (getArgs)
import Clash.Main (defaultMain)

-- Two of these suppress a warning that says nothing about your design, and the
-- third fixes the order in which Clash reports what it is compiling: without it
-- a design with more than one entity in it prints its progress lines in
-- whichever order the two compilations happen to finish, which differs from run
-- to run.
flags :: [String]
flags =
  [ "--interactive"
  , "-fno-unoptimized-core-for-interpreter"
  , "-Wno-inconsistent-flags"
  , "-fclash-no-concurrent-topentity-compilation"
  ]

main :: IO ()
main = getArgs >>= defaultMain . (flags ++)
