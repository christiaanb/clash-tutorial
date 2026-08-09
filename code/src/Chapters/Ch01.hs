-- | The reader's @src/Example/Project.hs@ at the end of chapter 1.
--
-- Chapter 1 changes nothing, so this is the project template's own module under
-- a name that lets every chapter's end state live in one package.
module Chapters.Ch01 where

import Clash.Explicit.Prelude

-- ANCHOR: definitions
plus :: Signed 8 -> Signed 8 -> Signed 8
plus a b = a + b
-- ANCHOR_END: definitions
