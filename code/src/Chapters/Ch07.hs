-- | The reader's @src/Example/Project.hs@ at the end of chapter 7.
--
-- Chapters 2 to 5 are unchanged. Chapter 6's @life@ is replaced: the board can
-- now be loaded from outside, through an input of type @Maybe Board@ that
-- carries its valid bit and its payload as one value. The transition function
-- is written on its own and @mealy@ puts the register around it.
module Chapters.Ch07 where

import Clash.Explicit.Prelude
-- ANCHOR: import-data-char
import Data.Char (intToDigit)
-- ANCHOR_END: import-data-char

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

-- ANCHOR: blinker
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
-- ANCHOR_END: blinker

render :: Board -> String
render b = unlines (toList (map row b))
  where
    row r = toList (map cell r)
    cell x = if x then '#' else '.'

-- ANCHOR: counts
type Counts = Vec 8 (Vec 8 (Unsigned 4))
-- ANCHOR_END: counts

-- ANCHOR: shifts
shiftN, shiftS, shiftW, shiftE :: Board -> Board
shiftN b = rotateLeftS b d1
shiftS b = rotateRightS b d1
shiftW b = map (\r -> rotateLeftS r d1) b
shiftE b = map (\r -> rotateRightS r d1) b
-- ANCHOR_END: shifts

-- ANCHOR: neighbour-boards
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
-- ANCHOR_END: neighbour-boards

-- ANCHOR: count-board
countBoard :: Board -> Counts
countBoard b = map (map toCount) b
  where
    toCount x = if x then 1 else 0
-- ANCHOR_END: count-board

-- ANCHOR: add-counts
addCounts :: Counts -> Counts -> Counts
addCounts = zipWith (zipWith (+))
-- ANCHOR_END: add-counts

-- ANCHOR: neighbour-counts
neighbourCounts :: Board -> Counts
neighbourCounts b = foldl1 addCounts (map countBoard (neighbourBoards b))
-- ANCHOR_END: neighbour-counts

-- ANCHOR: render-counts
renderCounts :: Counts -> String
renderCounts cs = unlines (toList (map row cs))
  where
    row r = toList (map digit r)
    digit n = intToDigit (numConvert n)
-- ANCHOR_END: render-counts

-- ANCHOR: step
step :: Board -> Board
step b = zipWith (zipWith nextCell) b (neighbourCounts b)
-- ANCHOR_END: step

-- ANCHOR: life-t
lifeT :: Board -> Maybe Board -> (Board, Board)
lifeT current input = (next, current)
  where
    next = case input of
      Just seed -> seed
      Nothing   -> step current
-- ANCHOR_END: life-t

-- ANCHOR: life
life ::
  Clock System -> Reset System -> Enable System ->
  Signal System (Maybe Board) -> Signal System Board
life clk rst en = mealy clk rst en lifeT glider
-- ANCHOR_END: life
