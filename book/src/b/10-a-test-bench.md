# A test bench that leaves Haskell

Chapter 9 turned the design into VHDL, and we read it.
Reading VHDL is not the same as knowing that it still does what the prompt did, and the instrument that settles it is a simulator: a program that has never heard of Haskell and does exactly what the file says.
This chapter writes a test bench in Haskell, generates it beside the entity, and runs both in NVC.

The stimulus is a list of commands, which is how the last three chapters have driven this design.
The expected results come from the instrument we have had since chapter 1: we ask the prompt what the design does, and write the answer down.

## Eight boards

Chapter 8 drove the design with eleven commands.
This is the same exercise with eight, which is short enough that every board it produces can be written down:

```
clashi> mapM_ (\b -> putStr (render b)) (sampleN 8 (life systemClockGen resetGen enableGen (fromList [Nothing, Nothing, Just Step, Just Run, Nothing, Just Pause, Just (Load blinker), Nothing])))
.#......
..#.....
###.....
........
........
........
........
........
.#......
..#.....
###.....
........
........
........
........
........
.#......
..#.....
###.....
........
........
........
........
........
........
#.#.....
.##.....
.#......
........
........
........
........
........
#.#.....
.##.....
.#......
........
........
........
........
........
..#.....
#.#.....
.##.....
........
........
........
........
........
..#.....
#.#.....
.##.....
........
........
........
........
........
........
........
..###...
........
........
........
........
```

Reading down: the glider three times, the first generation twice, the second generation twice, and the blinker.
The first two are the reset holding the register at the seed and the third is the seed again, because no command has reached the state yet.
After that every repeat has a reason: `Step` produces the first generation, `Run` sets the design going without stepping it, and `Pause` leaves the second generation where it is.

Three distinct pictures, and two of them are new.
Write those two down, under `blinker`:

```haskell
{{#include ../../../code/src/Chapters/Ch10.hs:generations}}
```

A `1` where the picture has a `#`, exactly as the glider and the blinker were written in chapters 3 and 7.
Reload and check both against what the prompt printed a moment ago:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> putStr (render glider1)
........
#.#.....
.##.....
.#......
........
........
........
........
clashi> putStr (render glider2)
........
..#.....
#.#.....
.##.....
........
........
........
........
```

Those two are the only new data this chapter needs; the other pictures in the sequence are the seed and the blinker, which have been in the file since chapters 3 and 7.
All four were obtained rather than worked out, and that is worth being plain about, because it is also the limit of what this test bench can tell us: it says that the VHDL agrees with the Haskell, and it says nothing about whether the Haskell was right.

## A test bench, in Haskell

A test bench needs three things `Clash.Explicit.Prelude` does not export, so add a third import, directly under the first:

```haskell
{{#include ../../../code/src/Chapters/Ch10.hs:import-testbench}}
```

Then one line directly above `life`'s type signature, under the annotation from chapter 9:

```haskell
{{#include ../../../code/src/Chapters/Ch10.hs:opaque-life}}
```

That is chapter 9's pragma again, on a different function and for a different reason.
A `Synthesize` annotation says what the top of a design is called; it does not stop that design being copied into something else that uses it, and a test bench is something else.
Without the pragma, Clash inlines the whole of `life` into the test bench, and what NVC then runs is a second copy of the design rather than the entity we generated.

Now the test bench itself, at the bottom of the file:

```haskell
{{#include ../../../code/src/Chapters/Ch10.hs:test-bench}}
```

The annotation on the first line ties the test bench to the entity it tests, and `'life` there is a quoted name rather than a call: it is why one `:vhdl` will generate both.

Below it are five bindings.
`commands` is the stimulus, one element per cycle, the same eight we sampled with.
`expected` is the eight boards, in the order the design produces them.
`done` is the comparison, and it is the test bench: `outputVerifier'` takes the boards it expects and the signal it gets, and hands back a signal that goes high once the last of them has been checked.
`clk` is a clock that runs until `done` says otherwise, which is what makes the simulation stop, and `rst` is the reset the prompt has been supplying since chapter 6.

Reload, and ask what the two new names are:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i stimuliGenerator
stimuliGenerator ::
  (KnownNat l, KnownDomain dom) =>
  Clock dom -> Reset dom -> Vec l a -> Signal dom a
  	-- Defined in ‘Clash.Explicit.Testbench’
clashi> :i outputVerifier'
outputVerifier' ::
  (KnownNat l, KnownDomain dom, Eq a, ShowX a, 1 <= l) =>
  Clock dom
  -> Reset dom -> Vec l a -> Signal dom a -> Signal dom Bool
  	-- Defined in ‘Clash.Explicit.Testbench’
```

`stimuliGenerator` turns a `Vec` into a signal, one element per cycle, and `outputVerifier'` does the same in reverse and compares.
Neither of them is special: both take a clock and a reset as arguments, like everything else in this design.

The test bench is a `Signal System Bool`, so the prompt can run it.
Sample twelve cycles, four more than the eight we gave it:

```
clashi> sampleN 12 testBench
[False,False,False,False,False,False,False,False,False,True,True,True]
```

It turns `True` on the tenth cycle, once the eighth board has been checked, and it says nothing at all before that, because nothing disagreed.

## Two entities, one command

Generate:

```
clashi> :vhdl
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, src/Example/Project.o )
Ok, one module reloaded.
GHC: Setting up GHC took: 0.055s
GHC: Compiling and loading modules took: 1.697s
Clash: Parsing and compiling primitives took 0.169s
GHC+Clash: Loading modules cumulatively took 3.115s
Clash: Compiling Example.Project.life
Clash: Normalization took 0.112s
Clash: Netlist generation took 0.006s
Clash: Compiling Example.Project.life took 0.173s
Clash: Compiling Example.Project.testBench
Not specializing TopEntity: Example.Project.life[8214565720323891532]
Not specializing TopEntity: Example.Project.life[8214565720323891532]
Clash: Normalization took 0.074s
Clash: Netlist generation took 0.016s
Clash: Compiling Example.Project.testBench took 0.183s
Clash: Total compilation took 3.478s
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
```

Two lines there are new, and they are the `OPAQUE` pragma taking effect: Clash is saying that it left `life` alone rather than folding a specialised copy of it into the test bench.
The number in brackets is an internal name for `life`, and yours may well be a different one: it moves if the session allocated a different number of names before Clash ran.

There are two directories under `vhdl/` now, one per entity, and nine files between them:

- `Example.Project.life/` holds `life.vhdl`, `life_types.vhdl` and `Example_Project_life_step.vhdl`, all three byte for byte the ones chapter 9 generated, plus `life.sdc` and `clash-manifest.json`;
- `Example.Project.testBench/` holds `testBench.vhdl` at 629 lines, `Example_Project_testBench_types.vhdl` at 213, a 24-line package whose name ends in a hash, and a manifest of its own.

The entity did not change because nothing about the entity changed.
What we added was a second thing to generate, and Clash generated it.

## What the test bench turned into

The eight commands are the first thing to find, and they are near the top of `testBench.vhdl`:

```vhdl
  \c$vec_0\ <= Example_Project_testBench_types.array_of_Maybe'( std_logic_vector'("0" & "------------------------------------------------------------------")
                                                              , std_logic_vector'("0" & "------------------------------------------------------------------")
                                                              , std_logic_vector'("1" & (std_logic_vector'("01" & "----------------------------------------------------------------")))
                                                              , std_logic_vector'("1" & (std_logic_vector'("10" & "----------------------------------------------------------------")))
                                                              , std_logic_vector'("0" & "------------------------------------------------------------------")
                                                              , std_logic_vector'("1" & (std_logic_vector'("11" & "----------------------------------------------------------------")))
```

Six of the eight entries, and every one of them is chapter 8's tag and payload written out as bits.
A `Nothing` is a `0` followed by sixty-six don't-cares.
`Just Step` is a `1`, then the tag `01`, then sixty-four don't-cares where the board of a `Load` would go.
The seventh entry is the `Load`, and it spells the blinker out one cell at a time over sixty-four lines, which is why it is not on this page.

The second thing to find is what those commands are driven into:

```vhdl
  clk_0 <= \Example.Project.testBench_clk\;

  rst_0 <= \c$Example.Project.testBench_app_arg_0\;

  en_0 <= true;

  cmd_0 <= \c$ds_app_arg_0\;

  life_cExampleProjecttestBench_app_arg : entity life.life
    port map
      (clk_0, rst_0, en_0, cmd_0, cells_0);
```

That is the entity from chapter 9, instantiated, with the five port names we chose there.
`entity life.life` names a library and an entity in it, and the library is called `life` because Clash generated that entity as a design of its own rather than as part of this one.
That library name is about to turn up in the command we type.

The third is why the simulation ever ends:

```vhdl
  clkGen : process is
    constant half_periodH : time := 10000000 fs / 2;
    constant half_periodL : time := 10000000 fs - half_periodH;
  begin
    \Example.Project.testBench_clk\ <= '0';
    wait for 100000 ps;
    while (not \c$result_rec\) loop
      \Example.Project.testBench_clk\ <= not \Example.Project.testBench_clk\;
      wait for half_periodH;
      \Example.Project.testBench_clk\ <= not \Example.Project.testBench_clk\;
      wait for half_periodL;
    end loop;
    wait;
  end process;
```

A clock that toggles every 5 ns while `\c$result_rec\` is false, and then waits forever.
`\c$result_rec\` is `done`, and that loop is what `tbSystemClockGen (fmap not done)` asked for.
Nothing tells NVC how long to run: the test bench stops its own clock, and a simulation with no clock left to run has finished.

## NVC

[NVC](https://github.com/nickg/nvc) is an open source VHDL simulator.
Its README covers installation on Windows, macOS and Linux; everything here was run with 1.20.1.
On Ubuntu the quickest route is the `.deb` on the releases page rather than the distribution's own package, and on Debian there is no package at all, so NVC is built from source with the recipe in that README.

Leave `clashi` running and open a second terminal in the project directory.
Everything from here happens in the generated tree:

```
$ cd vhdl
```

One command analyses all six files, elaborates the test bench and runs it:

```
$ nvc --ieee-warnings=off --work=life \
      -a Example.Project.life/life_types.vhdl \
         Example.Project.life/Example_Project_life_step.vhdl \
         Example.Project.life/life.vhdl \
         Example.Project.testBench/Example_Project_testBench_types.vhdl \
         Example.Project.testBench/testBench_slv2string_*.vhdl \
         Example.Project.testBench/testBench.vhdl \
      -e testBench -r
```

The order of those six files is the one thing in this chapter that has to be right.
VHDL has no include statement and no dependency solver: a file may only mention things that have already been analysed, so the types package comes before the entity that uses it, `step` comes before `life`, and `life` comes before the test bench that instantiates it.
Sorting the names alphabetically gets this wrong, which is why they are listed rather than globbed — except for the one whose name ends in a hash, which is globbed in its correct place so that nobody has to copy sixteen hexadecimal digits.

`--work=life` is what makes `entity life.life` resolvable: it puts everything into a library called `life` rather than into the default one called `work`, and leaves a directory of that name beside the two Clash wrote.
`--ieee-warnings=off` suppresses 257 warnings, all of them at time zero, from the standard numeric package being asked to compare values that no signal has driven yet.

It printed nothing.
That is the result, and it is the one to want, so ask the shell what it thought:

```
$ echo $?
0
```

Eight boards were compared against eight boards and every one of them matched.
Had one not, NVC would have said so on the cycle it happened, in a line of the form `** Error: 180ns+1: outputVerifier, expected: …, actual: …` with both boards spelled out as sixty-four bits, and it would have exited 1 rather than 0.

## Notice that

**The stimulus and the expected results were written in Haskell, and they are not in Haskell any more.**
They are a `std_logic_vector` array and a pile of boolean literals in a file that a VHDL simulator read without knowing anything about where it came from.
The description, the test bench and the golden data came out of one `:vhdl`, from one source file, and the program that checked them knows nothing about Haskell or Clash.

**A test bench is a circuit, and it is one on purpose.**
`stimuliGenerator` came out as a counter indexing a constant array and `outputVerifier'` as a second counter and a comparison, and both took a clock and a reset as arguments because everything in this design does.
What is not a circuit sits between `-- pragma translate_off` and `-- pragma translate_on`: the clock, the reset and the assertion, marked so that a synthesis tool skips them.

**Being the top of a design does not make something a boundary inside another one.**
Chapter 9 marked `step` so that it would survive into the VHDL as an entity, and this chapter marked `life` for the same reason and got the same result.
The annotation names the top of the design; it decides what the ports are called, not who is allowed to copy the logic.

**NVC answers "does it behave", and nothing else.**
It is not a synthesis tool and does not claim to be one, so nothing here says the design fits in an FPGA, or how fast it would run, or whether the adder tree is too deep.
It says that the entity in `life.vhdl` produces those eight boards from those eight commands, which is the question this chapter asked.

## Where this goes

The design is checked, and the check told us one bit: it agreed.
Chapter 11 asks NVC for a waveform of the same run and opens it in a browser, where the command bus stops being sixty-seven bits of don't-care and becomes something to look at.
The tag and the payload we have been describing since chapter 7 are on that waveform, side by side, and so is the design ignoring the payload on the seven cycles out of eight where it means nothing.
