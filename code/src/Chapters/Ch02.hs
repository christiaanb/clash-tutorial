-- | The reader's @src/Example/Project.hs@ at the end of chapter 2.
--
-- @plus@ and @topEntity@ are gone: the template's example has served its
-- purpose, and @topEntity@ is written again in chapter 9, when there is a
-- design for it to be the top of.
module Chapters.Ch02 where

import Clash.Explicit.Prelude

-- ANCHOR: next-cell
nextCell :: Bool -> Unsigned 4 -> Bool
nextCell alive n = case (alive, n) of
  (True,  2) -> True
  (_,     3) -> True
  _          -> False
-- ANCHOR_END: next-cell
