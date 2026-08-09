-- | The reader's @src/Example/Project.hs@ at the end of chapter 13.
--
-- Chapter 12's module under @Clash.Prelude@ rather than
-- @Clash.Explicit.Prelude@. Three lines change and nothing else does: the
-- import, @life@'s signature and @life@'s definition. The clock, the reset and
-- the enable come off @life@ and become the constraint
-- @HiddenClockResetEnable System@; @exposeClockResetEnable@ puts them back on
-- @life8@ and @life16@, which is the only place in the file those three are
-- still written out.
--
-- The two @Synthesize@ annotations are chapter 12's, unchanged, and so are
-- their signatures: an annotated binder describes real ports, so it cannot
-- have a hidden clock, reset or enable. That is what makes this chapter's
-- claim checkable rather than asserted — the generated port lists do not move.
--
-- @Clash.Explicit.Testbench@ stays. @stimuliGenerator@, @outputVerifier'@ and
-- @tbSystemClockGen@ take their clock and reset as arguments either way, and
-- @testBench@ drives @life8@, which still takes all three.
--
-- @{-\# OPAQUE step #-}@ and @{-\# OPAQUE life8 \#-}@ are untouched: neither
-- binder has a clock.
module Chapters.Ch13 where

-- ANCHOR: imports
import Clash.Prelude
import Clash.Explicit.Testbench
import Data.Char (intToDigit)
-- ANCHOR_END: imports

nextCell :: Bool -> Unsigned 4 -> Bool
nextCell alive n = case (alive, n) of
  (True,  2) -> True
  (_,     3) -> True
  _          -> False

-- ANCHOR: board
type Board n = Vec n (Vec n Bool)

fromRows :: KnownNat n => Vec n (BitVector n) -> Board n
fromRows = map unpack
-- ANCHOR_END: board

-- ANCHOR: glider
glider :: Board 8
-- ANCHOR_END: glider
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

blinker :: Board 8
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

glider1 :: Board 8
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

glider2 :: Board 8
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

-- ANCHOR: glider16
glider16 :: Board 16
glider16 = fromRows
  (  0b0100_0000_0000_0000
  :> 0b0010_0000_0000_0000
  :> 0b1110_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> 0b0000_0000_0000_0000
  :> Nil )
-- ANCHOR_END: glider16

-- ANCHOR: render
render :: Board n -> String
render b = unlines (toList (map row b))
  where
    row r = toList (map cell r)
    cell x = if x then '#' else '.'
-- ANCHOR_END: render

-- ANCHOR: counting
type Counts n = Vec n (Vec n (Unsigned 4))

shiftN, shiftS, shiftW, shiftE :: KnownNat n => Board n -> Board n
shiftN b = rotateLeftS b d1
shiftS b = rotateRightS b d1
shiftW b = map (\r -> rotateLeftS r d1) b
shiftE b = map (\r -> rotateRightS r d1) b

neighbourBoards :: KnownNat n => Board n -> Vec 8 (Board n)
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

countBoard :: Board n -> Counts n
countBoard b = map (map toCount) b
  where
    toCount x = if x then 1 else 0

addCounts :: Counts n -> Counts n -> Counts n
addCounts = zipWith (zipWith (+))

neighbourCounts :: KnownNat n => Board n -> Counts n
neighbourCounts b = foldl1 addCounts (map countBoard (neighbourBoards b))
-- ANCHOR_END: counting

renderCounts :: Counts n -> String
renderCounts cs = unlines (toList (map row cs))
  where
    row r = toList (map digit r)
    digit n = intToDigit (numConvert n)

{-# OPAQUE step #-}
-- ANCHOR: step
step :: KnownNat n => Board n -> Board n
step b = zipWith (zipWith nextCell) b (neighbourCounts b)
-- ANCHOR_END: step

-- ANCHOR: command
data Command n
  = Load (Board n)
  | Step
  | Run
  | Pause
  deriving (Generic, Eq, Show)

deriving instance KnownNat n => NFDataX (Command n)
deriving instance KnownNat n => BitPack (Command n)
-- ANCHOR_END: command

-- ANCHOR: st
data St n = St { board :: Board n, running :: Bool }
  deriving (Generic)

deriving instance KnownNat n => NFDataX (St n)
-- ANCHOR_END: st

-- ANCHOR: life-t
lifeT :: KnownNat n => St n -> Maybe (Command n) -> (St n, Board n)
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
life :: (KnownNat n, HiddenClockResetEnable System) =>
  Board n ->
  Signal System (Maybe (Command n)) -> Signal System (Board n)
life seed = mealy lifeT (St seed False)
-- ANCHOR_END: life

-- ANCHOR: life8
{-# ANN life8
  (Synthesize
    { t_name   = "life8"
    , t_inputs = [ PortName "clk"
                 , PortName "rst"
                 , PortName "en"
                 , PortName "cmd" ]
    , t_output = PortName "cells"
    }) #-}
{-# OPAQUE life8 #-}
life8 ::
  Clock System -> Reset System -> Enable System ->
  Signal System (Maybe (Command 8)) -> Signal System (Board 8)
life8 = exposeClockResetEnable (life glider)
-- ANCHOR_END: life8

-- ANCHOR: life16
{-# ANN life16
  (Synthesize
    { t_name   = "life16"
    , t_inputs = [ PortName "clk"
                 , PortName "rst"
                 , PortName "en"
                 , PortName "cmd" ]
    , t_output = PortName "cells"
    }) #-}
life16 ::
  Clock System -> Reset System -> Enable System ->
  Signal System (Maybe (Command 16)) -> Signal System (Board 16)
life16 = exposeClockResetEnable (life glider16)
-- ANCHOR_END: life16

-- ANCHOR: test-bench
{-# ANN testBench (TestBench 'life8) #-}
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
    done = expected (life8 clk rst enableGen commands)
    clk = tbSystemClockGen (fmap not done)
    rst = resetGen
-- ANCHOR_END: test-bench
