-- | The reader's @src/Example/Project.hs@ at the end of chapter 3.
--
-- Chapter 2's @nextCell@ is unchanged. What is new is the board it will run on,
-- a seed written as a picture, and @render@, which exists only so that the
-- prompt can print a board; it is not part of the circuit.
module Chapters.Ch03 where

import Clash.Explicit.Prelude

nextCell :: Bool -> Unsigned 4 -> Bool
nextCell alive n = case (alive, n) of
  (True,  2) -> True
  (_,     3) -> True
  _          -> False

-- ANCHOR: board
type Board = Vec 8 (Vec 8 Bool)
-- ANCHOR_END: board

-- ANCHOR: from-rows
fromRows :: Vec 8 (BitVector 8) -> Board
fromRows = map unpack
-- ANCHOR_END: from-rows

-- ANCHOR: glider
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
-- ANCHOR_END: glider

-- ANCHOR: render
render :: Board -> String
render b = unlines (toList (map row b))
  where
    row r = toList (map cell r)
    cell x = if x then '#' else '.'
-- ANCHOR_END: render
