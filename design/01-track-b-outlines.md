# Track B: chapter outlines

Reader: digital design background (VHDL or SystemVerilog), no Haskell.

Conventions are fixed in `CLAUDE.md` and rationale is in `00-decisions.md`. Every
transcript below is **indicative**. None ships without being pasted from a
terminal.

The indicative transcripts below write the prompt as `*Example.Project>`. That is
wrong: the observed prompt is `clashi>`, in every case. See D12. An outline is
corrected as its chapter ships, so chapters 1 to 11 are right; chapters 12 onward
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

**Code state.** Untouched template. `Example.Project` contains `plus` and nothing
else (D17). The reader edits nothing in this chapter.

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

**What we do.** Replace `plus` with the rule for a single cell. That is the whole
edit: the template ships nothing else to delete (D17).

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

`life` takes `St glider False` as `mealy`'s initial state, so the design comes out
of reset stopped. That is a change of behaviour from chapters 6 and 7, and it is
the chapter's clearest single result: the third sampled board used to be the first
generation and is now still the seed.

**Transcript.** Captured 2026-08-08; see V28. Two edits and two reloads: `Command`
goes in first and is interrogated on its own, so the chapter has a result before
any logic changes; then `St`, `lifeT` and `life` together. The stimulus is eleven
elements for eleven cycles:

```
clashi> mapM_ (\b -> putStr (render b)) (sampleN 11 (life systemClockGen resetGen enableGen (fromList [Nothing, Nothing, Just Step, Nothing, Just Run, Nothing, Nothing, Just Pause, Just (Load blinker), Nothing, Nothing])))
```

**The sizes are shown, not stated.** `pack` prints a `Command` as two tag bits and
sixty-four payload bits, with `Load`'s payload holding the blinker and the other
three printing sixty-four `.`, and `pack (Just Step)` prints sixty-seven. That is
the whole "tag and union payload" argument on screen, countable, and it needs
neither `Data.Proxy` nor a type application (V28, correcting the note below that
said the widths would be stated). `:i Command` is **not** shown: it prints the
unreduced `BitSize` type family instance through `Generic`, which is eleven lines
the reader cannot read. `:i Load` and `:i Step` print three lines each and are
what the chapter uses.

**Notice that.**

- `Load` carries a board; `Step`, `Run` and `Pause` carry nothing. This is a tag
  and a union payload, which the reader builds by hand with nothing checking that
  the union is read according to the tag. Here it cannot be read any other way.
- `Just (Load b)` matches two levels in one expression and binds the payload in
  the same breath. There is no VHDL construct for this.
- `St` is a record, which VHDL also has. Familiar. Say so and spend no time on it.
  It stays a record in the generated hardware, which is worth the half sentence it
  costs (V28).

**Sizes.** `Command` is a two-bit tag plus a 64-bit payload, 66 in all; `Maybe
Command` adds one, 67. Confirmed twice over: by `pack` at the prompt (V28) and by
`natVal` (V11). They are what the reader looks for in chapter 11.

---

## Chapter 9: An entity

**What we do.** Name the top of the design and each of its ports, generate VHDL,
then draw one boundary inside the design and generate it again.

There is no `topEntity` anywhere in this tutorial (D17). The first edit is an
annotation attached to `life`:

```haskell
{-# ANN life
  (Synthesize
    { t_name   = "life"
    , t_inputs = [ PortName "clk"
                 , PortName "rst"
                 , PortName "en"
                 , PortName "cmd" ]
    , t_output = PortName "cells"
    }) #-}
```

and the second is a pragma above `step`:

```haskell
{-# OPAQUE step #-}
```

**Port names are chosen, not obvious.** `cmd` rather than `command`, and `cells`
rather than `board`: VHDL is case insensitive, so a port called `command` pushes
the generated `Command` subtype to `Command_0`, and a port called `board` pushes
the state record's field to `St_0_sel0_board_2`. Both would contradict chapter 8
one chapter after it shipped. The chapter does not mention the workaround; D17
and V30 record why it is one.

**Transcript.** Captured 2026-08-09; see V30. Two edits, two reloads and two
`:vhdl` runs, which is what makes "Clash inlines the whole design into one file"
something the reader watches happen rather than a claim:

```
clashi> :r
clashi> :vhdl
```

The first run writes four files into `vhdl/Example.Project.life/` and
`life.vhdl` is 548 lines. The second writes five and `life.vhdl` is 211, beside a
343-line `Example_Project_life_step.vhdl`. The entity declaration is byte
identical between the two, which is the beat: the interface did not move, only
the logic behind it did.

**The three things to find**, and they are excerpts from the generated files
rather than transcripts. Each is introduced by the file it is in, because with
two files a reader searching the wrong one finds nothing:

1. **`life_types.vhdl`** — `subtype Command is std_logic_vector(65 downto 0)`,
   `subtype Maybe is std_logic_vector(66 downto 0)`, and the `St_0` record with
   the fields it was declared with. Chapter 8's 66 and 67 in the file.
2. **`Example_Project_life_step.vhdl`** — `zipWith_3`/`zipWith_2_0`, two nested
   `for … generate` holding sixty-four copies of the cell rule with
   `to_unsigned(2,4)` and `to_unsigned(3,4)`; and `zipWith_1`/`zipWith_0`/
   `zipWith_4`, three deep around the only `+` in the design. Chapter 4's
   inherited promise, and it lands harder here than it would have in one flat
   file: `life.vhdl` has no `+` in it at all.
3. **`life.vhdl`** — one `st_register` process, one `rising_edge(clk)`, `en`
   gating the assignment, the glider as the reset value; the two selects on
   `cmd(66 downto 66)` and `cmd(65 downto 64)`; the unconditional
   `b <= … fromSLV(cmd(63 downto 0))`; and the single instantiation of the step
   entity, which is what finally shows the "one copy of `step`" claim made since
   chapter 6.

**Notice that.**

- The annotation wrote down what was already true. The ports are the arguments
  `life` already had, in order, and clock, reset and enable have been arguments
  since chapter 6. Nothing was added to give the design a top.
- Clash flattens unless told not to, and telling it costs something: it does not
  optimise across the boundary, and the `OPAQUE` component's own ports are
  Clash's to name rather than ours.
- A port list is a fixed number of wires, so this is where the design stops being
  general. Chapter 12 writes two of these annotations and gets two entities from
  one `:vhdl`.
- The chosen names are what chapters 10 and 11 read. That is what they were for;
  chapter 9 is where they are cheapest to introduce.

**Pre-flag.** Tell the reader to look for three specific things and to ignore the
rest. A reader who tries to read all of it will conclude the output is
unreadable.

**Inherited promise, discharged.** Chapter 4 closes by saying that its `map`s
appear in this chapter's VHDL as `for … generate`. It holds, in the step file
rather than in `life.vhdl`, and it is the second of the three things to look for
(V30). Chapter 4's sentence stands as written.

---

## Chapter 10: A test bench that leaves Haskell

**What we do.** Write a self-checking test bench in Haskell, generate it beside
the entity, and run both under NVC.

The expected boards are obtained by asking the REPL — the same instrument, used
the way a verification engineer bootstraps golden vectors — and written into the
source as pictures. The stimulus is eight commands rather than chapter 8's
eleven, because eight is short enough that every board it produces can be shown
and the two new ones written down.

Three edits' worth of new source, in two edits:

```haskell
import Clash.Explicit.Testbench

{-# OPAQUE life #-}

{-# ANN testBench (TestBench 'life) #-}
testBench :: Signal System Bool
testBench = done
  where
    commands = stimuliGenerator clk rst (…eight commands…)
    expected = outputVerifier'  clk rst (…eight boards…)
    done = expected (life clk rst enableGen commands)
    clk  = tbSystemClockGen (fmap not done)
    rst  = resetGen
```

plus `glider1` and `glider2`, the two new pictures, under `blinker`.

**Transcript.** Captured 2026-08-09; see V31. Two edits, two reloads, one
`:vhdl` and one shell command. The REPL beats are the eight boards, the two new
ones rendered back, `:i` on both new names, and `sampleN 12 testBench`, which is
`False` nine times and then `True`: the test bench passing before it leaves
Haskell.

**The two decisions this chapter made** are D21 and D22, and neither was on
paper before it. The test bench is annotated rather than reached with `-main-is`,
and `life` is marked `OPAQUE` so that the simulation exercises the entity rather
than a second copy of its logic. The second of those also puts two
`Not specializing TopEntity: Example.Project.life[…]` lines in the transcript,
which the chapter explains in two sentences.

**The command**, from `vhdl/`, and it is one:

```
nvc --ieee-warnings=off --work=life \
    -a Example.Project.life/life_types.vhdl \
       Example.Project.life/Example_Project_life_step.vhdl \
       Example.Project.life/life.vhdl \
       Example.Project.testBench/Example_Project_testBench_types.vhdl \
       Example.Project.testBench/testBench_slv2string_*.vhdl \
       Example.Project.testBench/testBench.vhdl \
    -e testBench -r
```

It prints nothing and exits 0, so the chapter asks the shell with `echo $?`.

**Three excerpts from `testBench.vhdl`**, and they are what the chapter reads:
the stimulus as an `array_of_Maybe` of tags and don't-cares, which is chapter
8's `pack` output in a file; the instantiation of `entity life.life` with the
five port names chapter 9 chose; and the clock generator, whose
`while (not …) loop` is what `tbSystemClockGen (fmap not done)` asked for and
why the simulation ends.

**Notice that.**

- The stimulus and the expected results were written in Haskell, and they are now
  running in a simulator that has never heard of Haskell.
- A test bench is a circuit: two counters, a lookup table and a comparison, all
  taking a clock and a reset as arguments. What is not a circuit sits between
  `-- pragma translate_off` and `-- pragma translate_on`.
- Being the top of a design does not make something a boundary inside another
  one. Chapter 9's lesson, in the one place where forgetting it changes what is
  simulated.
- NVC is not a synthesizer and says so itself. This chapter answers "does it
  behave". The optional board chapter answers "can it be built".

**Pre-flag.**

- **File ordering is the hazard, and chapter 9 made it worse.** Six files across
  two directories, with a real chain: `life_types` before the step entity before
  `life` before the test bench's types package before `slv2string` before the
  test bench. Alphabetical globbing is not dependency order and visibly is not —
  `life.vhdl` sorts before `life_types.vhdl`. The files are listed explicitly,
  except the one whose name ends in a content hash, which is globbed in its
  correct slot so that nobody copies sixteen hexadecimal digits. CI runs the same
  command against `code/`.
- Linux readers may need `configure`/`make`. One sentence, not a section (V17).

---

## Chapter 11: The waveform

**What we do.** Ask NVC for a waveform, open it in Surfer's browser build, find
the command encoding.

The chapter edits no Haskell. `code/src/Chapters/Ch11.hs` is chapter 10's module
byte for byte, and D23 says why it exists anyway.

**Transcript.** Captured 2026-08-09; see V32. One shell command, which is chapter
10's with `-w` on the end, and one REPL block, which is `pack` on the four boards
`cells` takes. Everything else the chapter quotes — names, times and values — is
read out of the dump rather than out of a viewer, which is why V33, the browser,
could be checked separately and afterwards.

**The five things to find**, in this order, because each is a name from an
earlier chapter arriving somewhere new:

1. The scope `life_cexampleprojecttestbench_app_arg` and the five variables in
   it: `clk`, `rst`, `en`, `cmd` and `cells`, which are chapter 9's port names
   folded to lower case by NVC and otherwise unchanged.
2. `cmd` as bits: `0` and sixty-six don't cares, then `101`, `110`, `111` and
   `100` with the blinker, which is chapter 8's tag and payload and chapter 10's
   stimulus at once.
3. The one-cycle rule as a picture: `Just Step` on the bus at 120 ns, `cells`
   changing at 130.
4. `st_0_sel1_running`, chapter 8's record field, `true` from 140 ns to 160.
5. `cells` against `pack`, which is the dictionary between the ASCII pictures and
   the bus.

**Notice that.**

- The board is legible as ASCII in the REPL; the control is legible as a waveform.
  Use each for what it is good at, and say why.
- The command input is a single bus. Find the tag bits. Watch the payload field
  hold meaningless values while the tag says no command is present, and watch the
  design ignore them. The algebraic data type is not an abstraction that
  disappears at the boundary. It is a tag and a payload, and here it is.

**Pre-flag.**

- Confirm the file never leaves the reader's machine, then say so in one sentence.
  A hardware engineer at a company will wonder and will not ask. V6 is the
  reading of Surfer's source that makes the sentence safe.
- No screenshots, no click-by-click instructions.
- The `step` entity's 1776 generate scopes are in the dump. Say what they are and
  say not to open them, the way chapter 9 said which three things to read.

**Decided.** FST, which is NVC's default, so the flag is a bare `-w` (V5, V32).
The dump is not filtered and the one note NVC prints about arrays of composite
types is explained rather than suppressed: D23.

**Closed after drafting.** V33, the browser: the chapter shipped with an
`UNVERIFIED` marker over the paragraphs that say what Surfer does with the file,
and it was confirmed in a browser and the marker removed. Nothing in chapters 1
to 11 is now unrun. The one thing to re-run rather than trust is V33 itself,
because the browser build ships continuously and carries no version.

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

Two entities, from one `life`, and **one `:vhdl` produces both**, because Clash
generates every binder carrying a `Synthesize` annotation in one invocation. The
withdrawn route was `-main-is topEntity8` and `-main-is topEntity16` (V1), two
shell invocations of a flag used in exactly one chapter; the annotation keeps
chapter 12's command byte identical to chapter 9's and the reader never leaves
`clashi`.

```haskell
life8  :: … Signal System (Maybe (Command 8))  -> Signal System (Board 8)
life16 :: … Signal System (Maybe (Command 16)) -> Signal System (Board 16)
```

with a `Synthesize` block on each, identical except for `t_name`, which is itself
worth a sentence: the annotation does not mention the size, because the size is
in the signature.

**The edit this costs.** Chapter 9's annotation has to come off `life`, or three
entities are generated. The reader unmakes something they made three chapters
ago, which is the first time this tutorial asks that of them, and the outline
should not pretend otherwise.

**Notice that.**

- One description, two entities, visibly different port widths in the generated
  VHDL. With `t_output` named, that is `cells : out std_logic_vector(63 downto 0)`
  against `(255 downto 0)`: two numbers on two lines rather than sixty-four ports
  to count against two hundred and fifty-six.
- The reader writes VHDL generics already. The new part is that vector lengths are
  checked against the parameter at compile time: a `Vec n` cannot silently meet a
  `Vec 8`.
- The 16×16 design was never tested and works, because the description never knew
  the size.

**Risk.** This is the chapter most likely to produce type errors the reader cannot
decode. Every signature is given explicitly and inference is never relied upon. If
it proves fragile in practice, drop the chapter and ship thirteen — the safe
fallback is recorded in D9.

**Second risk, unverified.** `{-# OPAQUE step #-}` on a `step` that is now
polymorphic in the board size: one shared component, two specialised ones, or a
refused boundary. Check it before drafting. If it does not hold, the fallback is
to drop chapter 12, not to unteach chapter 9.

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

**Where the annotation goes.** It stays exactly where chapter 12 put it. An
annotated binder describes real ports, so it cannot have hidden clock, reset and
enable, which makes `life8` and `life16` the `exposeClockResetEnable` wrappers and
the only places those three are still written out:

```haskell
life8 = exposeClockResetEnable life
```

The annotation is then unchanged between chapters 12 and 13, which is the
cleanest available demonstration of D4's claim that the hidden prelude is
notation rather than semantics: the port list did not move, only the body did.

**Pre-flag.** `exposeClockResetEnable` appears exactly once, on the binder the
annotation is attached to, and is the price of the shorter body.
`{-# OPAQUE step #-}` is untouched, because `step` has no clock — a free
reassurance in a chapter otherwise about clocks disappearing.

**Verify.** Whether the two VHDL outputs are byte-identical or merely equivalent.
Claim only what is true. V13's 342-of-761 figures are void, since chapter 12's
output is now two entities in two files; re-run it as a directory to directory
diff, and test the prediction that the step file is byte identical between the two
chapters and only the wrapper's file differs.

---

## Chapter 14 (optional): On a board

Unresolved by design. See the open item at the end of `00-decisions.md`. Buttons
for `Load`, `Step`, `Run` and `Pause` are straightforward on any kit, and
board-level debouncing means debouncing is never mentioned. The display is the
open question.

Settle this after chapters 1–13 exist and are known to work.
