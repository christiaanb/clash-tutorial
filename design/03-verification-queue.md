# Verification queue

All thirty-five items are closed and chapters 1 to 13 are drafted, so the
transcripts that used to be quoted here now live in the book. What is left is
the short list of facts a redraft must not have to rediscover: the traps, the
shapes the toolchain actually prints, and the things that are not reproducible
and must never be quoted exactly. Every entry is tagged with the item it came
from; the full observations, with their transcripts, are in this file's history
if a number is ever disputed.

Toolchain unless stated: Stack 3.11.1, resolver lts-24.38, GHC 9.10.3, Clash
1.10.0, NVC 1.20.1, devcontainer, on a project freshly generated from
`template/clash-tutorial.hsfiles`. Checked 2026-08-05 to 2026-08-09.

Mark any future item `[x]` with the date and the observed result, not just a
tick. Do not contradict an entry below without re-running the check and
rewriting it.

---

## What a redraft owes

- **A changed chapter is a re-captured chapter.** Every transcript in the book
  came out of a pty through `tools/clashi_capture.py`, and
  `tools/check_transcripts.py` replays them. Edit the code and re-capture;
  never edit a transcript by hand to match.
- **Every number the book quotes about generated VHDL is downstream of the
  code** — line counts, file counts, port widths, the byte-identity claims in
  chapters 9, 12 and 13. Change chapter N's code and re-derive them in N
  through 13. CI asserts a subset: chapter 10's six-file NVC run against
  `Chapters.Ch10`, and chapter 12's and 13's identity claims and 211/595 line
  counts (V18, V31, V34, V35).
- **Run the whole spine end to end on one machine before drafting prose for any
  chapter after the first.** The chapters are cumulative and a surprise in
  chapter 8 can invalidate the code shown in chapter 4.
- **Capture by copying from the terminal, not by retyping.** Trailing
  whitespace and exact spacing matter when the reader is comparing their screen
  to the page.
- **Where a claim in `design/` turns out to be wrong, fix `design/` in the same
  commit as the chapter.** A design document that has silently drifted from the
  built code is worse than none, because the next person will trust it.

---

## Failures the chapters describe but never show

No step may fail, so each of these is stated in prose and kept off the screen.
The text is what was observed; quote it, do not paraphrase it into something
plausible.

- **Ch. 4, `d1`.** `rotateLeftS b 1` gives `[GHC-39999] No instance for 'Num
  (SNat d0)' arising from the literal '1'`. The chapter pre-flags it by showing
  `:i rotateLeftS` — short enough to print — rather than by describing it (V23).
- **Ch. 5, argument order.** Swapping `step`'s two arguments gives `[GHC-83865]
  Couldn't match type 'Unsigned 4' with 'Bool'`, twice, with
  `Expected`/`Actual` naming `Board` and `Counts` (V25).
- **Ch. 6, printing a `Signal`.** It typechecks and never ends: `:t print (life
  systemClockGen resetGen enableGen)` is `IO ()`, and evaluating the signal
  produced 9 MB of `:>` in fifteen seconds without finishing. The pre-flag says
  that, not that it is rejected (V26).
- **Ch. 7, the enforcement is a scope error.** Writing the `Nothing` row in
  terms of `seed` gives `[GHC-88464] Variable not in scope: seed :: Board`
  (V27).
- **Ch. 10, a wrong expected board.** `** Error: 180ns+1: outputVerifier,
  expected: <64 bits>, actual: <64 bits>` and exit 1 (V31).
- **Ch. 12, the generics wall.** Plain `deriving (Generic, NFDataX, BitPack,
  Eq, Show)` on `Command n` gives `[GHC-95822] solveWanteds: too many
  iterations (limit = 4)`: generics cannot resolve `KnownNat (BitSize (Command
  n))` when `BitSize` depends on `n`. Standalone deriving with an explicit
  `KnownNat n` context is the fix, and `StandaloneDeriving` is already on.
  Omitting `KnownNat n` from a plain function is *not* this wall — it gives a
  readable `[GHC-39999] No instance for 'KnownNat n'` with an "add (KnownNat n)
  to the context" suggestion (V1, V34).
- **The template with no `topEntity` (D17).** `stack run clash --
  Example.Project --vhdl` on a fresh project fails with `No top-level function
  called 'topEntity' or 'testBench' found, nor any function annotated with a
  'Synthesize' or 'TestBench' annotation`, which is why both places the
  template writes that command carry `-main-is plus` (V29).

---

## Language and configuration

- **Two imports beyond the prelude in the whole spine**, both in code that
  prints rather than in the circuit: `Clash.Explicit.Testbench` (ch. 10) and
  `Data.Char (intToDigit)` (ch. 4). Expect any third to follow that pattern
  (V12).
- **In scope from `Clash.Explicit.Prelude` alone:** `Vec`, `:>`, `Nil`, `map`,
  `zipWith`, `toList`, `head`, `foldl1`, `rotateLeftS`, `rotateRightS`, `d1`,
  `BitVector`, `pack`, `unpack`, `Signed`, `Unsigned`,
  `Clock`/`Reset`/`Enable`/`System`, `systemClockGen`/`resetGen`/`enableGen`,
  `register`, `mealy`, `sampleN`, `fromList`, `fmap`, `mapM_`, `putStr`,
  `Generic`/`NFDataX`/`BitPack`, `KnownNat`, `String`, `unlines`. Chapter 13's
  `Clash.Prelude` exports every one of them and both added imports survive the
  swap (V12, V35).
- **The `NoImplicitPrelude` trap:** `concatMap`, `(++)` and `head` are the
  `Vec` versions, so a list-based spelling fails with `Couldn't match expected
  type 'Vec n2 a0' with actual type '[a]'` (V12).
- **No per-file `LANGUAGE` pragma is required anywhere in chapters 1 to 13.**
  `GHC2024` supplies `BinaryLiterals`, `NumericUnderscores`, `DeriveGeneric`
  and `FlexibleContexts`; `common-options` adds `DeriveAnyClass`, first needed
  in chapter 8, and `TemplateHaskell`, first needed in chapter 9 and covering
  `{-# ANN #-}` in 9, 10, 12 and 13. `{-# OPAQUE #-}` needs nothing.
  `MonoLocalBinds` has rejected nothing and `NoMonomorphismRestriction` was
  never put back (V16, V24, V30, V31, V35).
- **`KnownNat n` goes where the compiler asks, and nowhere else.** In chapter
  12 that is `fromRows`, the four shifts, `neighbourBoards`, `neighbourCounts`,
  `step` and `lifeT` — and *not* `countBoard`, `addCounts`, `render` or
  `renderCounts`, because `map`, `zipWith` and `toList` never ask a vector its
  length. Standalone deriving is needed for `NFDataX` and `BitPack` on `Command
  n` and `NFDataX` on `St n`; `Generic`, `Eq` and `Show` stay in the plain
  clause (V34).
- **`numConvert`, never `fromIntegral` (D18).** `numConvert (3 :: Unsigned 4)
  :: Int` is `3`, and under `GHC2024` it needs no `where`-clause signature
  (V23, V24).
- **`unpack` resolves for `fromRows` from the top-level signature alone** — no
  annotation, no `TypeApplications` (V10). Passing `systemClockGen` pins the
  domain, so no `@System` is needed either (V8, D4).
- **`life` takes its seed as an argument from chapter 12 on (D24)**, because
  `mealy`'s initial state cannot name an 8×8 `glider` once the board is `Board
  n` (V34).
- **The prime on `outputVerifier'` is partial application, and that is checked
  rather than assumed.** In `clash-prelude-1.10.0`'s
  `Clash/Explicit/Testbench.hs`, `outputVerifier` takes a `Clock testDom` and a
  `Clock circuitDom`, and `outputVerifier' clk = outputVerifier clk clk`. The
  explanation page `currying.md` states this; chapter 10 shows only the primed
  signature's single `Clock dom`. Re-read that module if the pin moves.
- **The two pattern warnings, and where each of them shows.** Checked
  2026-08-10, GHC 9.10.3. A row that cannot be reached (chapter 2's `_` moved
  above the other two) gives `[GHC-53633] Pattern match is redundant` with no
  flags at all, at the `clashi` prompt included. A `case` with a row missing
  gives `[GHC-62161] Pattern match(es) are non-exhaustive`, listing the
  unmatched values, only under `-Wall`: `common-options` supplies it and the
  `clashi` executable stanza does not, so `stack build` reports it and `:r`
  answers `Ok, one module reloaded.` and nothing else. The explanation page
  `pattern-matching.md` states both, and no chapter shows either. Re-run both if
  the resolver moves.
- **What `Vec`, its constructors and the two crossings actually print.** Checked
  2026-08-10 in `clashi` 1.10.0 started from `code/`, with names qualified where
  `Clash.Prelude` and `Clash.Explicit.Prelude` both export them. `:i Vec` gives
  the constructors `Nil :: Vec 0 b` and `Cons :: b -> Vec n b -> Vec (n + 1) b`;
  `:i (:>)` gives `pattern (:>) :: a -> Vec n a -> Vec (n + 1) a` and `infixr 5
  :>`, so `:>` is a pattern synonym for `Cons` rather than a constructor of its
  own. `toList :: Vec n a -> [a]`, `fromList :: NFDataX a => [a] -> Signal dom
  a`, and `Clash.Explicit.Prelude.sampleN :: (Foldable f, NFDataX a) => Int -> f
  a -> [a]`, which is what makes `fromList` a list-to-`Signal` crossing and not
  `toList`'s inverse. `map`, `head`, `zipWith` and `foldl1` are the `Vec` ones;
  `unlines :: [String] -> String` comes from `GHC.Internal.Data.OldList` and
  `:i map` reports `Clash.Sized.Vector`. `:i String` prints `type String =
  [Char]`. The explanation page `vec-and-lists.md` states all of these, and no
  chapter shows any of them.
- **Two `[GHC-83865]`s the page describes, both run rather than reasoned about.**
  Checked 2026-08-10, GHC 9.10.3. A seed with its fourth row deleted fails to
  load with `Couldn't match type '1' with '2'`, `Expected: Vec 2 (BitVector 8)`
  and `Actual: Vec (0 + 1) (BitVector 8)`, reported at the *last* `:>` rather
  than at the deleted row, because the count runs out at the tail. `map` applied
  to a list gives the same code with `Couldn't match expected type: Vec n b`
  above `with actual type: [Int]`. Re-run both if the resolver moves.
- **What the three vector functions, `(+)` and four partial applications
  print.** Captured 2026-08-10 through `tools/clashi_capture.py` against
  `code/`, with `clashi_capture.READER_FILE` set to `src/Chapters/Ch04.hs`, so
  the session is a pty at the pinned width and locale. `:i map` gives `map ::
  (a -> b) -> Vec n a -> Vec n b`, `:i zipWith` gives `zipWith :: (a -> b -> c)
  -> Vec n a -> Vec n b -> Vec n c` and `:i foldl1` gives `foldl1 :: (a -> a ->
  a) -> Vec (n + 1) a -> a`, all three from `Clash.Sized.Vector`. `:t (+)` gives
  `Num a => a -> a -> a`; `:t zipWith (+)` gives `Num c => Vec n c -> Vec n c ->
  Vec n c`; `:t map countBoard` gives `Vec n Board -> Vec n Counts`; `:t foldl1
  addCounts` gives `Vec (n + 1) Counts -> Counts`; `:t map countBoard
  (neighbourBoards glider)` gives `Vec 8 Counts`; `:t (\r -> rotateLeftS r d1)`
  gives `KnownNat n => Vec n a -> Vec n a`. The explanation page
  `higher-order.md` quotes all of these and no chapter shows any of them.
- **A function handed over one argument short is not an error.** `:t map
  nextCell` answers `Vec n Bool -> Vec n (Unsigned 4 -> Bool)` and `:t map (map
  nextCell) glider` answers `Vec 8 (Vec 8 (Unsigned 4 -> Bool))`, both captured
  the same way on 2026-08-10. Where it is rejected was captured too: `:t render
  (map (map nextCell) glider)` gives `[GHC-83865]`, `Couldn't match type
  ‘Unsigned 4 -> Bool’ with ‘Bool’`, `Probable cause: ‘nextCell’ is applied to
  too few arguments`, and three `In the first argument of` lines naming
  `nextCell`, `(map nextCell)` and `(map (map nextCell) glider)`.
  `higher-order.md` quotes those three fragments inline rather than the block,
  following `vec-and-lists.md`. What the page says about the same mistake split
  across two definitions is a statement about the types and not a message
  anybody printed. Re-run if the resolver moves.
- **What inference leaves open, and what closes it.** Captured 2026-08-11 the
  same way as the two entries above, `tools/clashi_capture.py` against `code/`
  with `clashi_capture.READER_FILE` set to `src/Chapters/Ch04.hs`. `:t map
  unpack` gives `BitPack b => Vec n (BitVector (BitSize b)) -> Vec n b` and `:t
  unpack 0b1110_0000` gives `BitPack a => a`. Annotated, the same literal gives
  three answers: `:: Vec 8 Bool` is `True :> True :> True :> False :> False :>
  False :> False :> False :> Nil`, `:: Unsigned 8` is `224` and `:: Signed 8` is
  `-32`. `:t 1` gives `Num a => a`, `:t (\x -> if x then 1 else 0)` gives `Num a
  => Bool -> a`, `:t map (map (\x -> if x then 1 else 0)) glider` gives `Num b
  => Vec 8 (Vec 8 b)` and `:t countBoard glider` gives `Counts`. `:i numConvert`
  gives `NumConvert a b => a -> b` from
  `Clash.Class.NumConvert.Internal.NumConvert` and `:i intToDigit` gives `Int ->
  Char` from `GHC.Internal.Show`. `intToDigit (numConvert (head (head
  (neighbourCounts glider))))` evaluates to `'1'`, which is chapter 4's top left
  count. `type-inference.md` quotes all of these. Two commands were run and are
  quoted nowhere, deliberately: `:i unpack` prints the whole `BitPack` class
  including its `default` method and its `Generic` constraints, which is
  unquotable at this point in the book, and bare `unpack 0b1110_0000` prints
  `()`, because the prompt's extended defaulting picks a type where the page's
  point is that nothing does. The page uses `:t map unpack` and `:t unpack
  0b1110_0000` instead, which are expressions rather than bare names and so keep
  the `:i`-for-names rule.
- **Where a missing signature moves the error to.** Captured 2026-08-11, GHC
  9.10.3, by editing `renderCounts`'s `digit` to `digit n = intToDigit n` and
  reloading. As the book writes it, with no local signature, the failure is
  `[GHC-83865]` reported at `renderCounts cs = unlines (toList (map row cs))`,
  three lines above the edit, with the caret under `cs`, `Couldn't match type
  ‘Unsigned 4’ with ‘Int’`, `Expected: Vec 8 (Vec 8 Int)` and `Actual: Counts`.
  Adding `digit :: Unsigned 4 -> Char` above the same wrong line moves it onto
  that line: `Couldn't match expected type ‘Int’ with actual type ‘Unsigned 4’`,
  `In the first argument of ‘intToDigit’, namely ‘n’`, `In an equation for
  ‘digit’: digit n = intToDigit n`. The same shape was confirmed a third time in
  `render`, with `row r = toList r`, which reports at `render b = unlines (toList
  (map row b))` with `Couldn't match type ‘Bool’ with ‘Char’` and `Actual:
  Board`; the page does not quote it. `type-inference.md` quotes the first two
  as inline fragments and never their line numbers, which are `code/`'s and not
  the reader's. Re-run if the resolver moves.
- **What the two worlds print, and the one instrument that had to be added.**
  Captured 2026-08-11 through `tools/clashi_capture.py` against `code/`, twice:
  with `clashi_capture.READER_FILE` set to `src/Chapters/Ch04.hs` and again with
  it set to `src/Chapters/Ch12.hs`. `:k Vec` gives `Vec :: Nat -> Type -> Type`,
  `:k Signed` gives `Signed :: Nat -> Type`, `:k Vec 8` gives `Vec 8 :: Type ->
  Type`, `:k Bool` and `:k Unsigned 4` give `Type`, and `:k Board` gives `Board
  :: Type` on chapter 4's file and `Board :: Nat -> Type` on chapter 12's, as do
  `Counts`, `Command` and `St` there. `:k` is the third REPL command the book
  shows and `type-level-numbers.md` is the only page that uses it: `:i Vec`
  prints the kind and then forty lines of instances, so there was no other way
  to show what `Vec` is. `:t d1` gives `d1 :: SNat 1`; `:i SNat` is nine lines,
  `data SNat n where SNat :: KnownNat n => SNat n` with `ShowX`, `Lift` and
  `Show` instances and no `Num`; `:i snatToNum` gives `Num a => SNat n -> a` from
  `Clash.Promoted.Nat` and `snatToNum d1 :: Int` is `1`. `:t rotateLeftS glider`
  gives `SNat d -> Vec 8 (Vec 8 Bool)`. `:t (5 :: Signed (4 + 4))` gives `Signed
  8`. `natVal d8` also answers `8` and is quoted nowhere: one way to do each
  thing, and `snatToNum` is Clash's. Re-run if the resolver moves.
- **The four failures `type-level-numbers.md` quotes, none of them in a
  chapter.** Captured the same way on 2026-08-11, GHC 9.10.3. `:t rotateLeftS
  glider 1` gives `[GHC-39999]`, `No instance for ‘Num (SNat d0)’ arising from
  the literal ‘1’` and `In the second argument of ‘rotateLeftS’, namely ‘1’`,
  which is the entry above under Ch. 4 confirmed a second time. `:t d1 + d1`
  gives `No instance for ‘Num (SNat 1)’ arising from a use of ‘+’`. `:t
  (glider :: Vec 7 (Vec 8 Bool))` gives `[GHC-83865]`, `Couldn't match type ‘8’
  with ‘7’`, `Expected: Vec 7 (Vec 8 Bool)` and `Actual: Board`. `:t
  outputVerifier' systemClockGen resetGen Nil` gives `[GHC-64725]` and `Cannot
  satisfy: 1 <= 0`, which is the only place in the book where a type-level
  predicate is shown failing. On chapter 12's file, `:t glider16 :: Board 8`
  gives `Couldn't match type ‘16’ with ‘8’` over `Expected: Board 8` and
  `Actual: Board 16`. The page quotes all five as inline fragments rather than as
  blocks, following `vec-and-lists.md`.
- **What one library signature answers at four use sites, and the two ways a
  type variable is refused.** Captured 2026-08-11 through
  `tools/clashi_capture.py` against `code/`, four times, with
  `clashi_capture.READER_FILE` set to `src/Chapters/Ch04.hs`, `Ch07.hs`,
  `Ch08.hs` and `Ch12.hs` in turn. On chapter 4's file, `:t rotateLeftS glider
  d1` gives `Vec 8 (Vec 8 Bool)`. `:t mealy systemClockGen resetGen enableGen
  lifeT` is the same command against two files and gives two answers: `Board ->
  Signal System (Maybe Board) -> Signal System Board` on chapter 7's and `St ->
  Signal System (Maybe Command) -> Signal System Board` on chapter 8's. On
  chapter 12's file, `:t life glider` and `:t life glider16` print the five-line
  types that are `life8`'s and `life16`'s signatures, `:t step glider16` gives
  `Board 16`, `:t render glider16` gives `String`, `:t life8 systemClockGen
  resetGen enableGen` gives `Signal System (Maybe (Command 8)) -> Signal System
  (Board 8)`, and `:t map countBoard` gives `Vec n1 (Board n2) -> Vec n1 (Counts
  n2)` — the same command that `higher-order.md` quotes as `Vec n Board -> Vec n
  Counts` against chapter 4's file, renamed apart because two signatures use `n`.
  Two failures, quoted as inline fragments: `:t addCounts (countBoard glider)
  (countBoard glider16)` gives `[GHC-83865]`, `Couldn't match type ‘16’ with
  ‘8’`, `Expected: Board 8`, `Actual: Board 16` and `In the first argument of
  ‘countBoard’, namely ‘glider16’`, so the report lands inside the second
  argument rather than on `addCounts`; and `:t (glider :: Board n)` gives
  `[GHC-25897]`, `Couldn't match type ‘n’ with ‘8’` and `‘n’ is a rigid type
  variable bound by an expression type signature: forall (n :: Nat). Board n`,
  which is the only place in the book where the quantifier is printed. Two more
  were run and are quoted nowhere: `:t (step glider16 :: Board n)` is the same
  `[GHC-25897]` with 16 in place of 8, and `:t (glider :: Vec n (Vec 8 Bool))` on
  chapter 4's file is the same code again with `Actual: Board`.
  `polymorphism.md` quotes the rest, and no chapter shows any of them. Also
  checked by reading chapters 1 to 3 rather than assumed: chapter 4's `:i
  rotateLeftS` is the first signature in the book with a lowercase letter in it,
  because `plus`, `nextCell`, `Board`, `fromRows`, `glider` and `render` are all
  monomorphic. Re-run if the resolver moves.
- **A second `=` is refused, a second row is not, and substituting a definition
  changes nothing.** Captured 2026-08-11 through `tools/clashi_capture.py`
  against `code/`, with `clashi_capture.READER_FILE` set to
  `src/Chapters/Ch08.hs`, so the session is a pty at the pinned width and
  locale. `step glider == zipWith (zipWith nextCell) glider (neighbourCounts
  glider)` is `True`, so is the same equality with both sides inside another
  `step`, and `board (St glider False) == glider` is `True`. Two edits, each
  reloaded and each undone: appending `glider = blinker` to a file that already
  defines `glider` fails to load with `[GHC-29916]`, `Multiple declarations of
  ‘glider’` and a `Declared at:` naming both lines; adding `step b = b` directly
  under `step`'s own definition *loads*, with `[GHC-53633]
  [-Woverlapping-patterns]`, `Pattern match is redundant`, `In an equation for
  ‘step’`, at the `clashi` prompt and with no flag asked for, which confirms the
  redundancy half of the two pattern warnings above a second time. With that
  second row in place `step glider == glider` is `False`: the first row answers
  everything and the second is unreachable, so a second equation is not an
  update of the first. `purity.md` quotes the two evaluations as blocks, which
  is safe because neither prints a file name, and the two messages as inline
  fragments. Re-run if the resolver moves.
- **What order a `where` clause has, what runs out, and what hangs.** Captured
  2026-08-11 through `tools/clashi_capture.py` against `code/`, in three
  sessions, with `clashi_capture.READER_FILE` set to `src/Chapters/Ch10.hs`,
  `Ch07.hs` and `Ch06.hs` in turn. **Order.** Chapter 10's five `where` bindings
  written in the reverse order (`rst`, `clk`, `done`, `expected`, `commands`)
  load, `sampleN 12 testBench` is the same nine `False` and three `True`, and
  `:vhdl` writes both entities' trees byte for byte identically: all six
  `.vhdl` files, `life.sdc`, and the same 16 hexadecimal digits in
  `testBench_slv2string_B426B45701B03559.vhdl`. The only difference under
  `diff -r` is the `hash` field of each `clash-manifest.json`, which moves
  between identical runs anyway (see "Not reproducible" below). Counted while
  writing that: the clause has *five* bindings, and chapter 10 said four until
  2026-08-11. **Running out.**
  `sampleN 3 (fromList [Nothing, Nothing, Nothing] :: Signal System (Maybe
  Board))` is `[Nothing,Nothing,Nothing]`; at `sampleN 4` the prompt prints
  `[Nothing,Nothing,Nothing` and then `*** Exception: X: finite list` with a
  `CallStack` naming `src/Clash/Signal/Internal.hs` inside a hashed
  `clash-prelude-1.10.0-…` unit id, so the page quotes the first line as an
  inline fragment and never the block. `stimuliGenerator` does not run out:
  `sampleN 12 (stimuliGenerator systemClockGen resetGen (True :> False :> Nil))`
  is `[True,True,False,False,…]`, holding its last element, which is why chapter
  10 may sample twelve cycles of eight commands while every `fromList` in
  chapters 7, 8 and 10 matches its `sampleN` exactly. Also run and quoted
  nowhere: with `fromList []` as the input, `sampleN 2` of chapter 7's `life`
  prints the seed once and then throws the same `finite list`, so the *first*
  cycle demands nothing of the input and the second already does. **Hanging.**
  With `register` removed from chapter 6's line, leaving `boards = fmap step
  boards`, the module loads with no warning and `sampleN 1 (life systemClockGen
  resetGen enableGen)` printed nothing in 152 seconds, with the process resident
  set flat at 330 MB after an initial 36 MB. It is a hang and not `<<loop>>`,
  not an `XException` and not a compile error; nothing was observed about what
  `:vhdl` would do with it and the page says nothing about that. `laziness.md`
  states all of the above. Re-run if the resolver moves.
- **What NVC does with a delta cycle loop.** Checked 2026-08-11, NVC 1.20.1, on
  a four line entity outside the book's tree whose whole architecture is
  `s <= not s;`: `** Fatal: 0ms+10000: limit of 10000 delta cycles reached`,
  a caret under the signal declaration reading `driver for signal S is active`,
  a note about `--stop-delta`, and exit 1. `laziness.md` quotes the fragment
  `limit of 10000 delta cycles reached` in its VHDL contrast and uses it again
  in its cost section, where the point is that the VHDL simulator reports the
  loop and `clashi` reports nothing.
- **Widths.** `BitSize Board` is 64, `Command` 66 (two tag bits plus a 64-bit
  payload) and `Maybe Command` 67; at 16×16 they are 256, 258 and 259. Tags run
  in declaration order, `Load` `00` through `Pause` `11` (V11, V28, V34). This
  entry said 257 and 258 for the 16×16 command and its `Maybe` until 2026-08-11,
  which was the `downto` index of each rather than its width and contradicted
  chapter 12's own prose. Re-checked with chapter 12's file loaded: `:t pack
  (Step :: Command 8)` is `BitVector (CLog 2 4 + 64)` and the value is 66 bits,
  `:t pack (Step :: Command 16)` is `BitVector (CLog 2 4 + 256)` and the value is
  258 bits. A type prints as the unreduced sum in both cases, as the entry below
  on `:t pack Step` says it does.

---

## The REPL, exactly as it prints

- **`-- Defined at` has two forms and both are reproduced as observed, never
  normalised.** `:i glider`, `:i shiftN` and `:i step` put it on the *same*
  line after a space and a tab; `plus`, `nextCell`, `fromRows`, `render`,
  `neighbourCounts`, `renderCounts`, `lifeT` and `life` put it on the *next*
  line, indented by two spaces and a tab. `-- Defined in` takes the next-line
  form with the module in quotes. Not a terminal-width artefact: byte-identical
  at `stty cols` 40, 80 and 200 (V7, V21, V22, V23, V25).
- **The quotes come from the locale, not the terminal:**
  `‘Clash.Explicit.Signal’` under any UTF-8 locale and
  `` `Clash.Explicit.Signal' `` under `LC_ALL=C`. `tools/clashi_capture.py`
  pins `LC_ALL=C.UTF-8` so a capture cannot inherit whichever locale it ran
  under. `-- Defined at` quotes nothing
  and is unaffected.
- **Line numbers move with the reader.** Every number a chapter quotes is the
  one a reader who has followed chapters 2 to N in order sees, and it reports
  the *definition*, not the signature. Re-derive them whenever anything above
  them in the file changes (V23, V25, V26, V27, V28).
- **Asking for a type does not normalise it.** `:t pack Step` prints `BitVector
  (CLog 2 4 + 64)` and `:kind! BitSize Command` prints it unreduced: the
  plugins fire during constraint solving, not when a type is printed. Widths go
  on screen by evaluating — `pack Step`, or `natVal (Proxy @…)` — never by
  `:t` or `:kind!` (V11, V28).
- **`:i Command` is unshowable** — eleven lines of `GConstructorCount`/
  `GFieldSize`/`Rep` after the declaration. `:i` on a *constructor* is the
  instrument: `:i Load` is three lines with the others elided. `:i St` is clean
  at five lines and is shown (V28).
- **`:i` on a type synonym prints a kind line first:** `:i Board` gives `type
  Board :: Type`, then the synonym, then `-- Defined at` (V22).
- **`:r` answers `Ok, one module reloaded.`**, not the startup wording; a
  transcript with a reload in it must be captured with the file swapped on disk
  while `clashi` holds the old module (V21).
- **`clashi` with no argument loads no project module**, so chapter 1 passes it
  on the command line (D13) and the prompt stays `clashi>` (D12). `stack
  build`'s last line, chapter 1's marker that the long build finished, is
  `Registering library for life-0.1.0.0...` (V7, V29).
- **`putStr (render …)` ends in a newline** — `unlines` terminates every row —
  so the next prompt starts at column 0 (V22).

---

## Simulation behaviour the stimuli depend on

- **`resetGen` asserts reset for the first two cycles**, so the first two
  samples are the seed repeated, and a `mealy` machine's first input is the one
  arriving in cycle 1, visible in sample 2. A command is therefore taken in on
  the cycle it arrives and its effect is one board later. Every stimulus in
  chapters 6 to 12 is built around this, which is why chapter 7 loads on the
  fourth of seven elements (V9, V27, V28, V31).
- **The stimulus list must be at least as long as the `sampleN`.** The chapters
  match the two so the reader never reaches the end (V27).
- **The wrap does not show, and nothing may be said about it (D11).** All four
  generations of `glider` on the wrapped 8×8 board are byte-identical to the
  same four on an unbounded 32×32 board: the counts in column 7 and row 7 never
  reach three, so no cell is born there. Do not "fix" the samples — they are
  the correct output of the actual circuit (V9, V25).
- **The test bench passes in Haskell before it leaves it.** `sampleN 12
  testBench` is nine `False` then three `True`, in chapters 10, 12 and 13 alike
  (V31, V34, V35).

---

## NVC and the generated tree

- **File order is argument order, and an alphabetical glob fails.** Name the
  stable files and glob the hash-suffixed one in its correct middle slot, so
  the reader never copies a hash. Chapter 10's is one invocation over six files
  across two directories: the entity's types package, its step entity, the
  entity, then the test bench's types package, `testBench_slv2string_*.vhdl`
  and `testBench.vhdl` (V3, V30, V31).
- **`--work=life` is load bearing** once `{-# OPAQUE life #-}` makes
  `testBench.vhdl` instantiate `entity life.life`; without it the run fails
  with `design unit depends on WORK.TESTBENCH which was analysed with errors`
  (V31).
- **`--ieee-warnings=off` must be a global option, before `-a`.** After `-r`,
  NVC answers that it `may have no effect as the IEEE packages have already
  been initialised`. What it suppresses is 257 `NUMERIC_STD."=": metavalue
  detected` warnings in 771 lines, all at time zero (V3, V31).
- **Omit `--std` entirely.** Clash emits VHDL-93 and NVC defaults to 2008; the
  mismatch is harmless for everything Clash's netlists use — same exit codes
  and warnings either way (V4).
- **`--wave=FILE` is the only spelling that names a file.** `-w FILE` reads the
  name as a design unit (`** Fatal: … is not a valid design unit name`) and
  `-w=FILE` fails too. Chapter 11 uses bare `-w` and the default name, so no
  reader meets either. The format is FST by default and **NVC does not infer
  format from the filename** (V5, V32).
- **The dump prints two notes and nothing else**, the second being that arrays
  of composite types are not dumped by default — which is every `Board` in the
  design. The chapter does not pass `--dump-arrays`, because `cells` is the
  same board packed into one 64-bit vector. Filtering was tried and rejected
  (D23): the path globs are colon-separated, and a dump with nothing in it
  kills the run with `** Fatal: … fstReaderOpen failed for temporary FST file`
  (V32).
- **The waveform's times, exact and reproducible.** `clk` is low until 100 ns
  then toggles every 5, so rising edges run 100 to 180 ns ten apart and the
  last fall is 185; the dump's last timestamp is 190. `rst` falls at 110, `en`
  is `true` throughout, `cmd` changes at 120 through 170, and `cells` is
  `glider` until 130, `glider1` from 130, `glider2` from 150 and `blinker` from
  170. `st_0_sel1_running` is `true` from 140 to 160 and `done` goes `true` at
  180 (V32).
- **Names are folded to lower case** unless `--preserve-case` is passed, and
  VHDL `BOOLEAN` is dumped as a string-typed variable with the values `true`
  and `false` (V32).
- **Installing NVC splits by distro; `apt install nvc` works on neither.**
  Ubuntu 22.04/24.04 amd64: upstream's prebuilt `.deb` from
  `github.com/nickg/nvc` releases, which is what the devcontainer and every
  check here used. Debian: no package in any suite, so build from source per
  upstream's README (V17).

---

## Not reproducible — never quote it exactly

- **`clash-manifest.json`'s `hash` field differs between otherwise identical
  runs.** Every `.vhdl` file is byte identical; only that field moves. Nothing
  in any chapter reads it and nothing should start; chapter 13's `diff`
  excludes it (V30, V35).
- **The FST holds a timestamp**, so its size and checksum move run to run —
  four runs gave 4005, 4004, 4004, 4004 bytes. The value-change data *is*
  deterministic, so chapter 11 quotes times and values exactly and says "about
  four kilobytes" (V32).
- **Clash's timing lines vary run to run.** The chapters say the numbers are
  the capture machine's and that the order of magnitude is seconds (V30).
- **`Not specializing TopEntity: Example.Project.life[…]` is printed twice and
  is not suppressible** — `-fclash-debug DebugNone`, `-v0` and
  `-fclash-spec-limit=0` all leave it. The bracketed unique is not stable
  across session shapes; `tools/check_transcripts.py` blanks it and the chapter
  says it will differ (V31).
- **Top entities compile concurrently and print out of order**, which is what
  `-fclash-no-concurrent-topentity-compilation` in `bin/Clashi.hs` fixes (D22).
  With it, two captures of the same session are byte identical apart from the
  timings, and chapter 12's three binders come out in the fixed order `life16`,
  `life8`, `testBench` (V31, V34, V35).
- **Clash caches generated results.** A second `:vhdl` over an unchanged source
  answers `Clash: Using cached result for: …` instead of the normalisation
  timings, so `tools/check_transcripts.py` deletes the HDL tree before
  replaying. No chapter is affected — every `:vhdl` in the book follows an edit
  (V31).
- **`clashi` and `stack run clash` do not generate the same file.** Chapter
  10's `testBench.vhdl` is 629 lines from `clashi` and 632 with a different set
  of generated signal names from `stack run clash`. Each route is reproducible
  on its own; the book quotes the interactive one, because that is what the
  chapter runs (V31).

---

## Shelf life

**V33, Surfer's browser build, is the one entry here that can go stale.** It is
continuously deployed and carries no version, and it was checked in a real
browser on 2026-08-09: the file loads by drag and drop, the hierarchy reads as
chapter 11 says, `item_set_format binary` is an accepted command on a clicked
variable, `-` shows as `-`, and a string-typed `BOOLEAN` reads as `true`/
`false`. Nothing is sent anywhere — the browser build's only network call is
the opt-in `load_url`, which chapter 11 does not use (V6). This is the first
thing to re-run if a reader reports that chapter 11 does not match their
screen.

---

## Retired items

V2, V13, V14, V15, V18, V19 and V20 are closed and nothing above descends from
them: V2 and V13 were superseded by V31 and V35, and their conclusions are in
D21 and D25; V14, V15, V18, V19 and V20 recorded template, CI and preview
infrastructure that no chapter reads. One thing from them still needs doing:
`publish-template` cannot push the mirror until `STACK_TEMPLATES_DEPLOY_KEY`
exists (D15). Chapter 1 says the first build takes "roughly ten to fifteen
minutes" and never an exact figure — a cold build measured 12m14s on 12 cores,
and it is hardware dependent (V15).
