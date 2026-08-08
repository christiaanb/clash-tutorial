# Track B: chapter outlines

Reader: digital design background (VHDL or SystemVerilog), no Haskell.

Conventions are fixed in `CLAUDE.md` and rationale is in `00-decisions.md`. Every
transcript below is **indicative**. None ships without being pasted from a
terminal.

The indicative transcripts below write the prompt as `*Example.Project>`. That is
wrong: the observed prompt is `clashi>`, in every case. See D12. An outline is
corrected as its chapter ships, so chapters 1 to 7 are right; chapters 8 onward
still say `*Example.Project>`, and it should be read as `clashi>` when they are
drafted.

---

## Chapter 1: The instrument

**What we do.** Install Stack, create the project from our template, open the
REPL, and interrogate code that already exists.

```
stack --version
stack new life christiaanb/clash-tutorial
cd life
stack build
stack run clashi -- src/Example/Project.hs
```

The path argument to `clashi` is not optional: without it the prompt comes up
with nothing loaded and `:i plus` is an error (V7).

**Code state.** Untouched template. `Example.Project` contains `plus` and a
`topEntity`. The reader edits nothing in this chapter.

**Transcript.** Captured 2026-08-06; see V7's addendum.

```
clashi> :i plus
plus :: Signed 8 -> Signed 8 -> Signed 8
  	-- Defined at src/Example/Project.hs:6:1
clashi> :t plus 3
plus 3 :: Signed 8 -> Signed 8
clashi> plus 3 5
8
```

**Notice that.**

- Asking a name what it is (`:i`) and asking an expression what its type is (`:t`)
  are different questions with different commands. Establish the habit here, on
  code simple enough that the answers are unsurprising.
- `plus 3` is a legal thing to have. Supplying one of two arguments leaves
  something that still wants the other. Do not name this; let it sit.
- There is no entity, no architecture, no port map. `plus` is a component, and
  writing `plus 3 5` instantiates it.

**Pre-flag.**

- The first `stack build` downloads a GHC and compiles Clash from source: roughly
  ten to fifteen minutes, measured (V15). Say so with a number *before* the reader
  runs it. This is the most likely abandonment point in the whole tutorial.
- Corporate proxies and antivirus interfere with Stack on Windows. One sentence
  pointing at Stack's documentation. No troubleshooting inline.
Two things that used to need pre-flagging here no longer happen, and must not be
written back in. The template hard-codes an author and a maintainer instead of
taking them from mustache variables, so `stack new` no longer prints the
`author-email`/`author-name` note (V14 addendum). The template's `bin/Clashi.hs`
passes `-fno-unoptimized-core-for-interpreter`, so `clashi` no longer prints the
`[GHC-74335] [-Winconsistent-flags]` warning before its banner (V7 addendum).
Both were noise the reader had to be told to ignore; suppressing them at the
source is better than explaining them.

**Also here.** State what is being built and where it ends, in three sentences.
The reader should be able to picture chapter 13 from chapter 1.

**Out of scope.** Cabal, the project layout tour, the test suites, IDE setup.

---

## Chapter 2: A cell

**What we do.** Replace `plus` with the rule for a single cell, and delete
`topEntity` along with it (D17).

```haskell
nextCell :: Bool -> Unsigned 4 -> Bool
nextCell alive n = case (alive, n) of
  (True,  2) -> True
  (_,     3) -> True
  _          -> False
```

**Transcript.** Captured 2026-08-08; see V21. Six evaluations rather than three, one
per row of the `case` and three for the fall-through, so that the "first match wins"
beat below has something on screen to point at.

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i nextCell
nextCell :: Bool -> Unsigned 4 -> Bool
  	-- Defined at src/Example/Project.hs:6:1
clashi> nextCell True 2
True
clashi> nextCell True 3
True
clashi> nextCell False 3
True
clashi> nextCell False 2
False
clashi> nextCell True 1
False
clashi> nextCell True 4
False
clashi> :t nextCell True
nextCell True :: Unsigned 4 -> Bool
```

**Notice that.**

- This is a truth table and it reads as one.
- Branches are tried in order and the first match wins. A VHDL `case` demands
  mutually exclusive choices; this does not, and the wildcard rows do real work.
  First place the reader's existing habits will mislead them.
- `Unsigned 4` holds a count that never exceeds eight. The width is part of the
  type, therefore part of the contract, therefore checked.

**Pre-flag.** `:r` reloads after an edit. Establish edit → `:r` → evaluate here and
never vary it. A reader who edits without reloading sees stale results and
concludes their edit was wrong.

---

## Chapter 3: A board, and a picture

**What we do.** Introduce the board type, write a seed that looks like what it is,
and render it.

```haskell
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
```

Supplied, not written by the reader, and labelled simulation only:

```haskell
render :: Board -> String
render b = unlines (toList (map row b))
  where row r = toList (map cell r)
        cell x = if x then '#' else '.'
```

**Transcript.** Captured 2026-08-08; see V22. Two edits and two reloads rather than
one: the board and the seed go in first and are interrogated with `:i`, and
`render` is added afterwards, so the chapter has a result the reader can see
before the picture arrives.

```
clashi> head glider
False :> True :> False :> False :> False :> False :> False :> False :> Nil
clashi> putStr (render glider)
.#......
..#.....
###.....
........
........
........
........
........
```

**Notice that.**

- The seed is a picture in the source and a `BitVector` in the hardware. `unpack`
  is the same reinterpretation the reader does daily.
- Which reinterpretation `unpack` performs is settled by `fromRows`'s signature
  and nothing local to `unpack`. First place a signature written once decides
  something a long way from where it was written.
- `Vec 8` is not a list. The length is in the type, fixed at compile time, and a
  function taking a `Vec 8` cannot be handed a `Vec 7`.
- `render` produces a `String`, which is the first and last thing in this tutorial
  that is not a circuit. Say so plainly and move on.

**Depends on.** `BinaryLiterals` and `NumericUnderscores`. Both are guaranteed by
the `GHC2024` language edition the template sets (D19); before that they were two
of the thirty-two entries in its `default-extensions`. Either way the template is
what fixes them, which is why it exists.

---

## Chapter 4: Neighbours, by moving the whole board

**What we do.** Count neighbours without writing a single index expression.

```haskell
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
  where toCount x = if x then 1 else 0

addCounts :: Counts -> Counts -> Counts
addCounts = zipWith (zipWith (+))

neighbourCounts :: Board -> Counts
neighbourCounts b = foldl1 addCounts (map countBoard (neighbourBoards b))
```

**Transcript.** Captured 2026-08-08; see V23. Three edits and three reloads: the
four shifts go in first and are shown moving the glider with chapter 3's
`render`, so the chapter has a picture in it before any arithmetic; then the
eight boards and the sum, checked at one cell with `head (head …)`; then
`renderCounts`, and all sixty-four counts at once.

`renderCounts` is the second supplied helper, and chapter 3's prose commits to it
being the *only* other one that is not a circuit, so there is one of them and no
more. It needs `import Data.Char (intToDigit)`, which is the chapter's one
departure from the single-import file the reader has had since chapter 1 — the
list functions that would avoid it are shadowed by their `Vec` versions (V23,
correcting V12). The count reaches `intToDigit` through `numConvert`, which is
the tutorial's only way of changing a number's type (D18).

**Notice that.**

- `map` over a `Vec 8` is a `for … generate` with eight instances. `zipWith` is
  the same over two arrays. The reader has written this loop many times; here it
  is a value.
- Every cell's neighbour count is computed at once, in parallel, because that is
  what eight shifted copies and an adder tree are.
- The board wraps at the edges. Silently. Do not mention that there was a choice.

**Pre-flag.** `rotateLeftS` takes its rotation as `d1`, an `SNat`, not the number
`1`. This will bite and the error is not friendly: `No instance for
'Num (SNat d0)' arising from the literal '1'`. The device is `:i rotateLeftS`,
which prints in one line and puts `SNat d` in front of the reader before they
have to write it.

---

## Chapter 5: A generation

**What we do.** Combine the previous two chapters.

```haskell
step :: Board -> Board
step b = zipWith (zipWith nextCell) b (neighbourCounts b)
```

**Transcript.** Captured 2026-08-08; see V25. One edit and one reload, then the
seed and four generations, each application written out rather than accumulated in
a binding:

```
clashi> putStr (render (step glider))
clashi> putStr (render (step (step glider)))
clashi> putStr (render (step (step (step glider))))
clashi> putStr (render (step (step (step (step glider)))))
```

Four applications return the glider translated one cell diagonally. That is the
chapter's result and it is worth arriving at explicitly. The third generation is
shown as well as the second and the fourth: it costs three lines and it makes the
displacement something the reader watches happen rather than a claim about the
last picture.

**Notice that.**

- `:i step` is `Board -> Board`. There is no clock anywhere in this design and
  there has not been one for five chapters. A full generation of a 64-cell
  automaton is combinational logic, and it elaborates as one: 64 `in boolean`, 64
  `out boolean`, no clock and no process (V25). In VHDL the reader would already
  have written a process and would already be thinking about edges.
- `step (step b)` is two instances of the same block in series, not two cycles.
  Say what that costs — four applications is four copies of the logic — and say
  that at the prompt it costs nothing, because the prompt is evaluating a
  function.
- `zipWith` is what makes `Board` and `Counts` line up, in both length and order.
  Chapter 4's closing "notice that" promises this, so it is paid off here.

---

## Chapter 6: It runs by itself

**What we do.** Add a register and close the loop.

```haskell
life ::
  Clock System -> Reset System -> Enable System ->
  Signal System Board
life clk rst en = boards
  where
    boards = register clk rst en glider (fmap step boards)
```

**Transcript.** Captured 2026-08-08; see V26. One edit and one reload, then
`:i register` before the edit rather than after it, and the five samples printed
with a lambda rather than with function composition:

```
clashi> mapM_ (\b -> putStr (render b)) (sampleN 5 (life systemClockGen resetGen enableGen))
```

`putStr . render` says the same thing in fewer characters and was captured too,
byte-identically, but `.` would be the chapter's only new operator and the lambda
is the one chapter 4 already wrote.

**Notice that.**

- `boards` is defined in terms of itself. That is a feedback path, and the reader
  has drawn it a thousand times. The language lets it be written as one line.
- `:i register` shows clock, reset and enable as ordinary arguments. Nothing is
  implicit and nothing is inferred: the clock is there because it was passed.
- `step` is `Board -> Board`; `life systemClockGen resetGen enableGen` is
  `Signal System Board`. The type says which side of the register you are on, and
  `fmap` is what crosses between them. Both are asked with `:t` on an application,
  never on a bare name.
- One copy of `step`, used again every cycle, against chapter 5's four copies in
  series. This is the beat this reader came for.
- Reset is asserted at the start, so the first samples repeat. Point at it. Do not
  explain it away.

**Pre-flag.**

- Never print a `Signal` directly. It typechecks and does not terminate (V26), so
  the sentence says that rather than promising an error. `sampleN` appears in the
  same breath as the first `Signal`, always.
- `systemClockGen`, `resetGen`, `enableGen`: three values typed without meaning for
  now. Acceptable ritual, provided it never varies.

---

## Chapter 7: An input that cannot be misread

**What we do.** Let the board be reseeded from outside.

```haskell
lifeT :: Board -> Maybe Board -> (Board, Board)
lifeT current input = (next, current)
  where
    next = case input of
      Just seed -> seed
      Nothing   -> step current

life ::
  Clock System -> Reset System -> Enable System ->
  Signal System (Maybe Board) -> Signal System Board
life clk rst en = mealy clk rst en lifeT glider
```

A second seed, `blinker`, goes in under `glider`: three cells in a row, an
oscillator of period two, so that a load is unmistakable against the glider and
the two generations after it prove the design is still running.

**Transcript.** Captured 2026-08-08; see V27. Two edits and two reloads: `blinker`
goes in first and is rendered, so the chapter has a picture before the input type
arrives; then `lifeT` and the rewritten `life`. The stimulus is seven elements
long for seven cycles, with the load on the fourth:

```
clashi> mapM_ (\b -> putStr (render b)) (sampleN 7 (life systemClockGen resetGen enableGen (fromList [Nothing, Nothing, Nothing, Just blinker, Nothing, Nothing, Nothing])))
```

Not `Just blinker` on the first cycle: reset is asserted for the first two, and
the input on cycle 0 is never taken, so that stimulus prints chapter 6's boards
and the blinker never appears (V27). Loading on the fourth cycle also lets the
glider run first, which makes the load a change the reader watches happen.

**Notice that.**

- `Maybe Board` is the valid bit and the payload welded into one thing. The reader
  has built this pair by convention many times and has at least once read the
  payload while valid was low. Here the payload is unreachable without matching on
  `Just`, and the compiler enforces it.
- It is 65 bits wide either way. The type system removes a class of mistake, not
  wires.
- `lifeT` takes a state and an input and returns a new state and an output, and it
  is combinational; `mealy` puts the register around it. Do not call it a Mealy
  machine: `mealy`'s output may depend on the input, and this one returns the
  state untouched. Say what it does instead.

---

## Chapter 8: More than valid

**What we do.** Replace the input with a command set whose constructors carry
different payloads.

```haskell
data Command
  = Load Board
  | Step
  | Run
  | Pause
  deriving (Generic, NFDataX, BitPack, Eq, Show)

data St = St { board :: Board, running :: Bool }
  deriving (Generic, NFDataX)

lifeT :: St -> Maybe Command -> (St, Board)
lifeT st cmd = (st', board st)
  where
    st' = case cmd of
      Just (Load b) -> St b False
      Just Step     -> St (step (board st)) False
      Just Run      -> St (board st) True
      Just Pause    -> St (board st) False
      Nothing       -> if running st then St (step (board st)) True else st
```

**Notice that.**

- `Load` carries a board; `Step`, `Run` and `Pause` carry nothing. This is a tag
  and a union payload, which the reader builds by hand with nothing checking that
  the union is read according to the tag. Here it cannot be read any other way.
- `Just (Load b)` matches two levels in one expression and binds the payload in
  the same breath. There is no VHDL construct for this.
- `St` is a record, which VHDL also has. Familiar. Say so and spend no time on it.

**Sizes worth stating.** `Command` is a two-bit tag plus a 64-bit payload;
`Maybe Command` adds one. Verify the exact widths — they are what the reader looks
for in chapter 11.

---

## Chapter 9: An entity

**What we do.** Name the top of the design and generate VHDL.

```haskell
topEntity ::
  Clock System -> Reset System -> Enable System ->
  Signal System (Maybe Command) -> Signal System Board
topEntity = life
```

```
*Example.Project> :vhdl
```

**Notice that.**

- `topEntity` is the entity declaration. Its arguments are the ports, and clock,
  reset and enable are ports because they were arguments all along. Nothing new
  has been introduced; a name has been given.
- It is monomorphic. `System` and `Command` are fixed, because a port list is a
  fixed number of wires.
- The generated hierarchy has recognisable pieces in it. Find `step`. Find the
  types package. The reader is reading their own design in their own language,
  which for this reader is when the tool becomes credible.

**Pre-flag.** Tell the reader to look for three specific things and to ignore the
rest. A reader who tries to read all of it will conclude the output is
unreadable.

**Inherited promise.** Chapter 4 closes by saying that its `map`s appear in this
chapter's VHDL as `for … generate`. That holds for chapter 4's code elaborated on
its own (V23), so one of the three things to look for is that, and the sentence in
chapter 4 has to be checked against this chapter's actual output before it ships.

---

## Chapter 10: A test bench that leaves Haskell

**What we do.** Generate a self-checking test bench and run it under NVC.

Expected outputs are obtained by asking the REPL — the same instrument, used the
way a verification engineer bootstraps golden vectors — and pasted into the source.

```
nvc --std=<pinned> -a <files, in dependency order> -e testBench -r
```

**Notice that.**

- The stimulus and the expected results were written in Haskell, and they are now
  running in a simulator that has never heard of Haskell.
- NVC is not a synthesizer and says so itself. This chapter answers "does it
  behave". The optional board chapter answers "can it be built".

**Pre-flag.**

- **File ordering is the hazard.** Clash emits several files and the types package
  must be analysed first; alphabetical globbing is not dependency order. List the
  files explicitly, pinned to the pinned Clash version, and let CI catch drift.
- Linux readers may need `configure`/`make`. One sentence, not a section.

**Decide.** Test bench via `TestBench` annotation (needs Template Haskell and a
name quote) or via `-main-is testBench` on the command line. Prefer whichever
avoids the annotation: for this reader it is ritual with no payoff.

---

## Chapter 11: The waveform

**What we do.** Ask NVC for a waveform, open it in Surfer's browser build, find
the command encoding.

**Notice that.**

- The board is legible as ASCII in the REPL; the control is legible as a waveform.
  Use each for what it is good at, and say why.
- The command input is a single bus. Find the tag bits. Watch the payload field
  hold meaningless values while the tag says no command is present, and watch the
  design ignore them. The algebraic data type is not an abstraction that
  disappears at the boundary. It is a tag and a payload, and here it is.

**Pre-flag.**

- Confirm the file never leaves the reader's machine, then say so in one sentence.
  A hardware engineer at a company will wonder and will not ask.
- No screenshots, no click-by-click instructions.

**Decide.** FST (NVC's default) or VCD (universally understood, human readable).
Verify what Surfer's web build accepts.

---

## Chapter 12: One description, two sizes

**Replaces the withdrawn `foldl1`/`fold` chapter. See D9.**

**What we do.** Make the board size a type parameter, then generate two entities
from one description.

```haskell
type Board n = Vec n (Vec n Bool)
```

`step`, `neighbourCounts` and the shifts gain a `KnownNat n` constraint and
nothing else changes structurally. `neighbourBoards` stays `Vec 8` — eight
directions, regardless of board size — so the fold is unaffected.

Two top entities, from one `life`:

```haskell
topEntity8  :: … Signal System (Maybe (Command 8))  -> Signal System (Board 8)
topEntity16 :: … Signal System (Maybe (Command 16)) -> Signal System (Board 16)
```

**Notice that.**

- One description, two entities, visibly different port widths in the generated
  VHDL. Sixty-four bits and two hundred and fifty-six.
- The reader writes VHDL generics already. The new part is that vector lengths are
  checked against the parameter at compile time: a `Vec n` cannot silently meet a
  `Vec 8`.
- The 16×16 design was never tested and works, because the description never knew
  the size.

**Risk.** This is the chapter most likely to produce type errors the reader cannot
decode. Every signature is given explicitly and inference is never relied upon. If
it proves fragile in practice, drop the chapter and ship thirteen — the safe
fallback is recorded in D9.

---

## Chapter 13: What the rest of the world writes

**What we do.** Switch to `Clash.Prelude`, delete the clock, reset and enable
arguments, add the constraint where the compiler asks, expose them once at the
top, regenerate, diff against chapter 12's output.

**Notice that.**

- The code is shorter and the circuit is identical. `HiddenClockResetEnable` is
  notation, not semantics.
- This is the style the reader will meet in every Clash project, example and blog
  post from here on, including the template they started from. They have now seen
  both and know what the short form is short for.

**Pre-flag.** `exposeClockResetEnable` appears exactly once, at `topEntity`, and is
the price of the shorter body.

**Verify.** Whether the two VHDL outputs are byte-identical or merely equivalent.
Claim only what is true.

---

## Chapter 14 (optional): On a board

Unresolved by design. See the open item at the end of `00-decisions.md`. Buttons
for `Load`, `Step`, `Run` and `Pause` are straightforward on any kit, and
board-level debouncing means debouncing is never mentioned. The display is the
open question.

Settle this after chapters 1–13 exist and are known to work.
