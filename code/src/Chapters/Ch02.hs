-- | The reader's @src/Example/Project.hs@ at the end of chapter 2.
--
-- @plus@ is gone: the template's example has served its purpose, and the file
-- holds nothing but the design from here on.
module Chapters.Ch02 where

import Clash.Explicit.Prelude

-- ANCHOR: next-cell
nextCell :: Bool -> Unsigned 4 -> Bool
nextCell alive n = case (alive, n) of
  (True,  2) -> True
  (_,     3) -> True
  _          -> False
-- ANCHOR_END: next-cell
