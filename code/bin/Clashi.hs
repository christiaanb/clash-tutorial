import Prelude
import System.Environment (getArgs)
import Clash.Main (defaultMain)

main :: IO ()
main = getArgs >>= defaultMain . (\l -> "--interactive":"-fno-unoptimized-core-for-interpreter":"-Wno-inconsistent-flags":l)

