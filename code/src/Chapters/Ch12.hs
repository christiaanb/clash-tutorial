-- | The reader's @src/Example/Project.hs@ at the end of chapter 12.
--
-- Chapter 11's module with the board size taken out of it. @Board@, @Counts@,
-- @Command@ and @St@ all take a size, every function that computes over a board
-- carries a @KnownNat n@, and @life@ takes the seed it starts from as an
-- argument, because a description that does not know the size cannot know what
-- an 8x8 glider is either.
--
-- @Command n@ and @St n@ derive @NFDataX@ and @BitPack@ standalone. A plain
-- @deriving@ clause on @Command n@ fails with @solveWanteds: too many
-- iterations@, because @BitSize (Command n)@ depends on @n@ and generics cannot
-- resolve the @KnownNat@ that follows from it; an explicit context can.
--
-- Chapter 9's @Synthesize@ annotation has come off @life@ and there are two in
-- its place, on @life8@ and on @life16@, which differ in @t_name@ and in
-- nothing else: the size is in the signature. One @:vhdl@ generates both, and
-- the test bench beside them.
--
-- @{-\# OPAQUE life8 \#-}@ is chapter 10's pragma on the binder the test bench
-- now instantiates. @life16@ needs none, because nothing instantiates it.
module Chapters.Ch12 where

import Clash.Explicit.Prelude
import Clash.Explicit.Testbench
import Data.Char (intToDigit)

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
life :: KnownNat n =>
  Board n ->
  Clock System -> Reset System -> Enable System ->
  Signal System (Maybe (Command n)) -> Signal System (Board n)
life seed clk rst en = mealy clk rst en lifeT (St seed False)
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
life8 = life glider
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
life16 = life glider16
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
