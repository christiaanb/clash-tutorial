-- | The reader's @src/Example/Project.hs@ at the end of chapter 8.
--
-- Chapters 2 to 6 are unchanged. Chapter 7's @Maybe Board@ input is replaced by
-- a command set of our own, @Command@, whose four constructors carry different
-- payloads: @Load@ carries a board and the other three carry nothing. The state
-- grows a second field, so @lifeT@ works on a record rather than on a board.
module Chapters.Ch08 where

import Clash.Explicit.Prelude
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

-- ANCHOR: life
life ::
  Clock System -> Reset System -> Enable System ->
  Signal System (Maybe Command) -> Signal System Board
life clk rst en = mealy clk rst en lifeT (St glider False)
-- ANCHOR_END: life
