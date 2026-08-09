-- | The reader's @src/Example/Project.hs@ at the end of chapter 11.
--
-- Byte for byte chapter 10's module, and deliberately so: chapter 11 asks NVC
-- for a waveform of chapter 10's run and reads it in a viewer, which changes
-- what the reader knows and not what the reader has written. The one thing it
-- types at the prompt, @pack@ on a board, needs nothing that is not here.
--
-- It exists rather than being skipped because the rule that
-- @code\/src\/Chapters\/ChNN.hs@ is the reader's file at the end of chapter NN
-- is what @tools\/reader_file.py@ and @tools\/check_transcripts.py@ derive every
-- state from: chapter 11's session is replayed against this module, and chapter
-- 12's edits are staged as a diff from it.
module Chapters.Ch11 where

import Clash.Explicit.Prelude
-- ANCHOR: import-testbench
import Clash.Explicit.Testbench
-- ANCHOR_END: import-testbench
import Data.Char (intToDigit)

nextCell :: Bool -> Unsigned 4 -> Bool
nextCell alive n = case (alive, n) of
  (True,  2) -> True
  (_,     3) -> True
  _          -> False

type Board = Vec 8 (Vec 8 Bool)

fromRows :: Vec 8 (BitVector 8) -> Board
fromRows = map unpack

glider :: Board
glider = fromRows
  (  0b0100_0000
  :> 0b0010_0000
  :> 0b1110_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> Nil )

blinker :: Board
blinker = fromRows
  (  0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0011_1000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> Nil )

-- ANCHOR: generations
glider1 :: Board
glider1 = fromRows
  (  0b0000_0000
  :> 0b1010_0000
  :> 0b0110_0000
  :> 0b0100_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> Nil )

glider2 :: Board
glider2 = fromRows
  (  0b0000_0000
  :> 0b0010_0000
  :> 0b1010_0000
  :> 0b0110_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> 0b0000_0000
  :> Nil )
-- ANCHOR_END: generations

render :: Board -> String
render b = unlines (toList (map row b))
  where
    row r = toList (map cell r)
    cell x = if x then '#' else '.'

type Counts = Vec 8 (Vec 8 (Unsigned 4))

shiftN, shiftS, shiftW, shiftE :: Board -> Board
shiftN b = rotateLeftS b d1
shiftS b = rotateRightS b d1
shiftW b = map (\r -> rotateLeftS r d1) b
shiftE b = map (\r -> rotateRightS r d1) b

neighbourBoards :: Board -> Vec 8 Board
neighbourBoards b =
     shiftN b
  :> shiftS b
  :> shiftW b
  :> shiftE b
  :> shiftN (shiftW b)
  :> shiftN (shiftE b)
  :> shiftS (shiftW b)
  :> shiftS (shiftE b)
  :> Nil

countBoard :: Board -> Counts
countBoard b = map (map toCount) b
  where
    toCount x = if x then 1 else 0

addCounts :: Counts -> Counts -> Counts
addCounts = zipWith (zipWith (+))

neighbourCounts :: Board -> Counts
neighbourCounts b = foldl1 addCounts (map countBoard (neighbourBoards b))

renderCounts :: Counts -> String
renderCounts cs = unlines (toList (map row cs))
  where
    row r = toList (map digit r)
    digit n = intToDigit (numConvert n)

-- ANCHOR: opaque-step
{-# OPAQUE step #-}
-- ANCHOR_END: opaque-step
step :: Board -> Board
step b = zipWith (zipWith nextCell) b (neighbourCounts b)

-- ANCHOR: command
data Command
  = Load Board
  | Step
  | Run
  | Pause
  deriving (Generic, NFDataX, BitPack, Eq, Show)
-- ANCHOR_END: command

-- ANCHOR: st
data St = St { board :: Board, running :: Bool }
  deriving (Generic, NFDataX)
-- ANCHOR_END: st

-- ANCHOR: life-t
lifeT :: St -> Maybe Command -> (St, Board)
lifeT st cmd = (st', board st)
  where
    st' = case cmd of
      Just (Load b) -> St b False
      Just Step     -> St (step (board st)) False
      Just Run      -> St (board st) True
      Just Pause    -> St (board st) False
      Nothing       -> if running st then St (step (board st)) True else st
-- ANCHOR_END: life-t

-- ANCHOR: synthesize
{-# ANN life
  (Synthesize
    { t_name   = "life"
    , t_inputs = [ PortName "clk"
                 , PortName "rst"
                 , PortName "en"
                 , PortName "cmd" ]
    , t_output = PortName "cells"
    }) #-}
-- ANCHOR_END: synthesize
-- ANCHOR: opaque-life
{-# OPAQUE life #-}
-- ANCHOR_END: opaque-life
life ::
  Clock System -> Reset System -> Enable System ->
  Signal System (Maybe Command) -> Signal System Board
life clk rst en = mealy clk rst en lifeT (St glider False)

-- ANCHOR: test-bench
{-# ANN testBench (TestBench 'life) #-}
testBench :: Signal System Bool
testBench = done
  where
    commands = stimuliGenerator clk rst
      (  Nothing
      :> Nothing
      :> Just Step
      :> Just Run
      :> Nothing
      :> Just Pause
      :> Just (Load blinker)
      :> Nothing
      :> Nil )
    expected = outputVerifier' clk rst
      (  glider
      :> glider
      :> glider
      :> glider1
      :> glider1
      :> glider2
      :> glider2
      :> blinker
      :> Nil )
    done = expected (life clk rst enableGen commands)
    clk = tbSystemClockGen (fmap not done)
    rst = resetGen
-- ANCHOR_END: test-bench
