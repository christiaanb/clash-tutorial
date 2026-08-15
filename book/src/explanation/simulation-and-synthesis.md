# What runs, and what is hardware

Chapter 6 got the design running with one line, and said one sentence about the three names that made it possible: "the clock, the reset and the enable have to come from somewhere, and in simulation they come from `systemClockGen`, `resetGen` and `enableGen`".
Those three are then typed in that order every time a design is run at the prompt, from there to chapter 12, and they never vary.
That is a rule the reader follows rather than a thing the reader knows, and it is the third of four the tutorial hands out one at a time.
Chapter 3 gave the first: `render` produces a `String`, "and a `String` is not a circuit".
Chapter 7 gave the second: "`fromList` belongs to simulation, alongside `sampleN` and the three generators."
Chapter 10 gave the fourth from the other end, in the generated VHDL: "What is not a circuit sits between `-- pragma translate_off` and `-- pragma translate_on`."

Four rules, in four chapters, none of them argued.
There is one model underneath all four, and this page is that model.

## The reading that does not survive

In VHDL, simulation and synthesis are the same language, and often the same file.
What separates them is convention held up by three things: the subset of the language a given synthesis tool accepts, a pragma that tool has agreed to honour, and the discipline of the person writing it.
A test bench is not a different kind of VHDL; it is VHDL that nobody is going to synthesise, and what stops it reaching a netlist is that nobody asks.

The habit that comes over is to look for the pragma and the discipline, and to treat the border as something to be careful about.
Here it is mostly something to be told about, and the thing doing the telling is the type.
`Board -> Board`, `Signal System Board` and `IO ()` are three different types, and no value of the third kind can turn up inside the first two without a type saying so.

The near miss is worth naming, because the pragmas really are there.
Chapter 10's `testBench.vhdl` has six pairs of them.
They are output rather than input: the split was settled in Haskell, and Clash wrote the comments a VHDL tool needs afterwards.
There is one place where the type does not settle it, and it is this page's last section.

## Three layers, and one file

The whole design is one Haskell file, and three different kinds of thing live in it.
Chapter 5's generation is the first:

```haskell
{{#include ../../../code/src/Chapters/Ch05.hs:step}}
```

A board in, a board out, and, as chapter 5 said of its type, "nothing in that type mentions time".
It becomes logic.

Chapter 6's `life` is the second:

```haskell
{{#include ../../../code/src/Chapters/Ch06.hs:life}}
```

Its arguments and its result are `Signal`s, and a `register` sits in the middle of it.
It becomes logic with registers in it.

The third is the line the reader retypes in chapters 6, 7, 8 and 10, and it is not in the file at all: `mapM_ (\b -> putStr (render b)) (sampleN 5 (life systemClockGen resetGen enableGen))`.
It becomes nothing.
Nothing in it is generated, nothing in it is a wire, and the only reason it exists is that a person wants to see something.

That third layer never entered the reader's file, and the check is cheap: `sampleN`, `fromList`, `putStr` and `mapM_` do not appear in any of the thirteen chapters' end states.
Two definitions in the file are not circuits either, `render` from chapter 3 and `renderCounts` from chapter 4, and both of them make text.
What keeps them out of the VHDL is not that Clash inspected them: chapter 9's rule is that "a binder carrying that annotation is what it goes looking for", so `render` was never a candidate for generation in the first place.

The two types that carry the second and third layers have the same shape as each other, which is easier to see with [the command another page introduces for asking about a type](type-level-numbers.md#the-eight-is-in-the-type-and-the-type-is-not-a-number):

```
clashi> :k IO
IO :: Type -> Type
clashi> :k Signal
Signal :: Domain -> Type -> Type
```

Each of them takes a type and gives back a type.
`Signal System Board` is a board for every cycle of a clock domain, and `IO ()` is an action that produces nothing when something performs it.
Neither is a board, and the difference between them is the whole of this page.

## `putStr` does not print

The most useful thing the prompt says about printing is what `putStr` is:

```
clashi> :i putStr
putStr :: String -> IO () 	-- Defined in ‘GHC.Internal.System.IO’
```

A string in, and an `IO ()` out.
That is a function like any other, and applying it prints nothing:

```
clashi> :t putStr (render glider)
putStr (render glider) :: IO ()
```

`putStr (render glider)` is a value, of a type that describes an action, and building it is as inert as building a board.
Values of that type can be collected like any others:

```
clashi> :t [putStr (render glider), putStr (render blinker)]
[putStr (render glider), putStr (render blinker)] :: [IO ()]
```

Two actions in a list, and neither of them has happened.
What performs one is the prompt: an expression of type `IO ()` typed at `clashi` is run rather than printed, which is why chapter 3's `putStr (render glider)` put a board on the screen and why the same expression inside brackets does not.

`mapM_` is what turns a list of boards into one such action:

```
clashi> :i mapM_
mapM_ :: (Foldable t, Monad m) => (a -> m b) -> t a -> m ()
  	-- Defined in ‘GHC.Internal.Data.Foldable’
```

The two names before the `=>` are [requirements rather than arguments](type-classes.md#-is-not--), and which types meet them is settled at the use site, so chapter 6's line makes `t` a list and `m` an `IO`.
Read it that way and the first argument is a function from a board to an action, the second is a list of boards, and the result is one action that produces `()`.
Both halves are worth naming.
The first argument is [a function handed to a function](higher-order.md#a-function-with-no-name), exactly as `unpack` is handed to `map`, and the prompt agrees about its type:

```
clashi> :t (\b -> putStr (render b))
(\b -> putStr (render b)) :: Board -> IO ()
```

And `()` is a type with one value in it and no information, which is what the underscore in the name is about.
The version without the underscore keeps the results:

```
clashi> :i mapM
type Traversable :: (Type -> Type) -> Constraint
class (Functor t, Foldable t) => Traversable t where
  ...
  mapM :: Monad m => (a -> m b) -> t a -> m (t b)
  ...
  	-- Defined in ‘GHC.Internal.Data.Traversable’
```

`m (t b)` against `m ()`: one gives back a collection of whatever the actions produced, and the other throws it away.
Printing produces nothing worth keeping, so chapter 6 wants the underscore, and what comes out is a single action:

```
clashi> :t mapM_ (\b -> putStr (render b)) [glider, blinker]
mapM_ (\b -> putStr (render b)) [glider, blinker] :: IO ()
```

One action, built out of two, and still nothing has been printed.

## The two crossings the prompt uses

A design is signals and a screen is not, so something has to cross between them, and the tutorial uses exactly two names for it.
`sampleN` comes out:

```
clashi> :i sampleN
sampleN :: (Foldable f, NFDataX a) => Int -> f a -> [a]
  	-- Defined in ‘Clash.Signal.Internal’
```

An ordinary `Int` decides how many cycles are looked at, and what comes back is [a list rather than a vector](vec-and-lists.md#the-bridges-and-the-one-that-is-not-one), because how long a person watches is not a fact about the circuit.
There is no `Signal` in the result, which is what makes the boards printable.

`fromList` goes in:

```
clashi> :i fromList
fromList :: NFDataX a => [a] -> Signal dom a
  	-- Defined in ‘Clash.Signal.Internal’
```

Chapter 7 introduced it with the sentence this page is here to justify: it "belongs to simulation, alongside `sampleN` and the three generators", and "it is how a signal is made to drive a design at the prompt".

The evidence that both of them are outside the design is chapter 10, which needed those same two jobs done by hardware.
Its stimulus is not a `fromList` and its check is not a `sampleN`: they are `stimuliGenerator` and `outputVerifier'`, both of which take a clock and a reset, and both of which came out of `:vhdl` as counters, a constant array and a comparison.
Two ways to drive eight commands into a design, one of which exists only while the prompt is running, and nothing but the types says which is which.

## The generators are the simulator standing in for a board

The three names chapter 6 asks for without explaining have unremarkable types:

```
clashi> :i systemClockGen
systemClockGen :: Clock System
  	-- Defined in ‘Clash.Explicit.Signal’
clashi> :i resetGen
resetGen :: KnownDomain dom => Reset dom
  	-- Defined in ‘Clash.Signal.Internal’
clashi> :i enableGen
enableGen :: Enable dom 	-- Defined in ‘Clash.Signal.Internal’
```

A `Clock System`, a `Reset dom` and an `Enable dom`, which are the types of the first three ports chapter 9 named `clk`, `rst` and `en`.
Nothing in them says simulation.
What they are is the simulator agreeing to stand where a crystal, a reset controller and whatever drives the enable will stand later, and the reason they can is that a clock is a value in this language rather than a construct.

Chapter 11 is where the last of the three turned out to be worth reading once.
`en` is `true` for the whole run of the waveform, and the generated file says why in one line: `en_0 <= true;`.
The enable that has been typed since chapter 6 is a constant, and it always was.

The fourth generator is the one chapter 10 needs, and its type is not like the others:

```
clashi> :i tbSystemClockGen
tbSystemClockGen :: Signal System Bool -> Clock System
  	-- Defined in ‘Clash.Explicit.Testbench’
```

A clock computed from a signal.
That is what lets chapter 10's simulation stop itself, and it is also a thing with no meaning whatsoever in hardware: a clock that exists while a boolean says so is a statement about a simulator's time, not about a net.

## The border, written into the VHDL

Chapter 10's test bench is where all of this is on one page, in one `where` clause:

```haskell
{{#include ../../../code/src/Chapters/Ch10.hs:test-bench}}
```

Five bindings, and the border runs between the third and the fourth.
`commands`, `expected` and `done` are circuit, and chapter 10 says so in as many words: a test bench "is a circuit, and it is one on purpose".
`clk` and `rst` are the simulator, by the argument of the section above.
Nothing about the layout separates them, and nothing has to, because `Signal System Bool` and `Clock System` are different types.

`'life` on the first line is the other thing to read.
It is a quoted name: a reference to the binder called `life`, not an application of it, which is what lets one annotation say which entity this test bench belongs to and one `:vhdl` generate both.

What Clash then does with the two halves is visible in the file it writes.
The entity is 781 lines across three files and does not contain the word `pragma` anywhere.
The test bench is one file of 629 lines with six pairs of pragmas in it, and they wrap exactly the things that are not circuit.
The reset is one:

```vhdl
  -- resetGen begin
  resetGen : block
    constant reset_delay : time := 100000 ps - 1 ps + (integer'(1) * 10000 ps);
  begin
  -- pragma translate_off
  \c$Example.Project.testBench_app_arg_0\
    <= '1',
       '0' after reset_delay;
  -- pragma translate_on
  end block;
  -- resetGen end
```

`resetGen` in the Haskell, `resetGen` in the VHDL, and the only thing driving that reset is between the comments.
The clock is the second, and chapter 10 already read it as the reason the simulation ends: the whole `clkGen` process, with its `wait for` statements, sits inside one such pair.
The comparison is the third:

```vhdl
  -- assert begin
  r_assert : block
    -- pragma translate_off
    signal actual : Example_Project_testBench_types.array_of_array_of_8_boolean(0 to 7);
    signal expected : Example_Project_testBench_types.array_of_array_of_8_boolean(0 to 7);
    -- pragma translate_on
  begin
```

Even the two signals holding the boards being compared are declared inside the pair, and the `assert` itself and its `report` follow them in a second one.
The counter that decides which board to compare is outside, because a counter is a circuit.

The two remaining pairs are smaller and say the same thing about a detail.
Each of the two counters indexes a constant array of eight elements, and each index is taken modulo eight inside a pair of pragmas and not outside it.
The counter is three bits wide, so in hardware there is no value it could take that is out of range; a simulator evaluating that conversion before anything has driven the counter is the case the `mod 8` is there for.

## An undefined value is a value only simulation has

Chapter 8 printed a value that is partly not there:

```
clashi> pack Step
0b01_...._...._...._...._...._...._...._...._...._...._...._...._...._...._...._....
```

Chapter 10 found those same bits in the generated stimulus, where `Just Step` is "a `1`, then the tag `01`, then sixty-four don't-cares where the board of a `Load` would go", and chapter 11 found them on a waveform as sixty-four `-` on seven cycles out of eight.
Those are three notations for one thing, and the fourth is what happens when something asks for such a value rather than carrying it.
`errorX "no value" :: Unsigned 4` at the prompt is `*** Exception: X: no value`, and it is an exception rather than a number because there is no number to give.

That is why the test bench's requirements include one the reader has otherwise never met.
Chapter 10's `:i outputVerifier'` lists `ShowX a` among five [requirements the compiler settles](type-classes.md#a-requirement-can-hand-over-a-value), and `ShowX` is `Show` for values that may not be there:

```
clashi> :i showX
type ShowX :: Type -> Constraint
class ShowX a where
  ...
  showX :: a -> String
  ...
  	-- Defined in ‘Clash.XException’
```

`showX (errorX "no value" :: Unsigned 4)` is `"undefined"`, where typing the same value at the prompt throws the exception above, and a verifier that has to report what it got needs the version that cannot fail.

The same phenomenon crosses into VHDL with the design, and NVC counts it.
Chapter 10 turns off 257 warnings with a flag, and this is what they are.
256 of them read `NUMERIC_STD."=": metavalue detected, returning FALSE` and come from the two comparisons chapter 2's truth table makes, once for each of the sixty-four cells, in each of two delta cycles; the remaining one is a `">"` from the test bench's own counter.
A metavalue is a bit that is neither `0` nor `1`, which at time zero is every bit that nothing has driven yet, and the standard numeric package is complaining that it was asked to compare one.
None of that is a fault in the design, and there is nothing for a circuit to report in the same place: a wire carries a level whether or not anything reads it.
It is the same undefined-ness as the `.` and the `-`, wearing the notation the simulator has for it.

## What it costs

**All three layers are the same language, and only the type says which is which.**
`step`, `life` and the prompt line are all Haskell, all in the same session, and all written the same way.
Nothing about the look of a definition says whether it becomes gates, and a reader who has not read its signature cannot tell.
That is the price of not having an entity and architecture to put things in, and the tutorial pays it deliberately: every top level definition in the book carries a signature, and the signature is where the answer is.

**The generators are the place where the type does not say, and Clash's answer is a warning rather than a refusal.**
`systemClockGen` has the type of a port, so nothing stops it being applied inside a binder that carries a `Synthesize` annotation.
Doing that generates: Clash prints `Dubious primitive instantiation for Clash.Signal.Internal.tbClockGen: Clash.Signal.Internal.tbClockGen is not synthesizable!` and writes the entity anyway, with the clock and the reset driven between `-- pragma translate_off` and `-- pragma translate_on` and no clock port at all:

```vhdl
entity lifeGen is
  port(cmd   : in lifeGen_types.Maybe;
       cells : out std_logic_vector(63 downto 0));
end;
```

What a synthesis tool reads there is a design whose clock net has no driver.
The warning is easy to miss in a run that prints twenty other lines, and it is the one thing on this page that a reader has to watch for rather than be told by a type.

**Crossing the other way is refused, and the refusal is not phrased as a border.**
Putting a `Synthesize` annotation on a definition of type `IO ()` and generating produces several hundred lines about a binder the reader never wrote, opening `Clash.Normalize(243): Callgraph after normalization contains following recursive components`, with `GHC.Prim.State# RealWorld` inside the type it prints out.
What Clash met is the recursion inside `mapM_` and the token GHC uses to sequence actions, and what it says is about those.
The border holds, and the message is in the compiler's vocabulary rather than in the one this page has been using.

**The pragma is still a comment, and it still depends on the tool honouring it.**
`-- pragma translate_off` is a convention of exactly the kind VHDL has always had, and deciding the split in Haskell has not replaced the mechanism at the bottom.
What it replaces is the discipline: the author no longer keeps the two apart by being careful, and the tool at the far end does what it always did.

**Turning the noise off turns all of it off.**
`--ieee-warnings=off` silences the 257 warnings at time zero, and it silences the same class of warning for the rest of the run, so a metavalue reaching a comparison at 150 nanoseconds would go unmentioned too.
Chapter 10 can afford that because what decides whether the run passed is the assertion, which reports on its own, and a design whose checking leans on those warnings needs the flag reconsidered rather than copied.

## Where you met this

- Chapter 3, [A board, and a picture](../b/03-a-board.md): `render`, a `String`, and the first thing in the book that is not a circuit.
- Chapter 6, [It runs by itself](../b/06-it-runs.md): the three generators, `sampleN`, and `mapM_` with a lambda in front of it.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `fromList`, named as belonging to simulation.
- Chapter 8, [More than valid](../b/08-more-than-valid.md): sixty-four bits of `.` behind a tag that says they mean nothing.
- Chapter 9, [An entity](../b/09-an-entity.md): the annotation that decides what `:vhdl` looks for, and 781 lines with no pragma in them.
- Chapter 10, [A test bench that leaves Haskell](../b/10-a-test-bench.md): five bindings with the border running through them, `'life` as a quoted name, the pragmas in the generated file, and 257 warnings at time zero.
- Chapter 11, [The waveform](../b/11-the-waveform.md): `en_0 <= true;` for the whole run, and the don't cares on the bus.
