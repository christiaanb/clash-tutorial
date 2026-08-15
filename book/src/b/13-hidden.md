# What the rest of the world writes

Every version of `life` in this book has taken a clock, a reset and an enable, and has done nothing with them except hand them on.
`register` wanted them in chapter 6 and `mealy` has wanted them since chapter 7, so `life` has carried three arguments for seven chapters to give them somewhere to come from.
At the prompt they have been three words typed without meaning for just as long: `systemClockGen resetGen enableGen`, in that order, never varying.

`Clash.Prelude` is the same library with those three hidden.
It is what every Clash project, example and blog post you read after this one imports, including the template this project was generated from, and this chapter is where we switch to it.
The switch changes an import, one function and the two definitions at the top of the design, and it changes no part of the circuit.
The second half of the chapter is spent establishing the second of those rather than asserting it.

## Keep what chapter 12 generated

`:vhdl` writes into `vhdl/` and overwrites what it finds there, so before touching the source, move chapter 12's output out of its way.
In the shell, from the project directory:

```
$ mv vhdl vhdl-12
```

Those are the fourteen files chapter 12's one `:vhdl` produced, and they are what the second half of this chapter compares against.
It is the one step here that cannot be undone from inside the chapter: getting that directory back once it is gone means putting chapter 12's source back first.

## One import, and two edits that go with it

At the top of the file:

```haskell
{{#include ../../../code/src/Chapters/Ch13.hs:imports}}
```

`Clash.Prelude` in place of `Clash.Explicit.Prelude`, and the two imports below it stay exactly as they are.
`Clash.Explicit.Testbench` staying is not an oversight: `stimuliGenerator`, `outputVerifier'` and `tbSystemClockGen` take a clock and a reset as arguments under either prelude, and chapter 10's test bench is untouched by this chapter.

That line on its own leaves the file not compiling, because `mealy` under this prelude does not take a clock.
Make the two edits below before reloading, so that there is one `:r` at the end of them rather than one after each.

## `life` loses three arguments

```haskell
{{#include ../../../code/src/Chapters/Ch13.hs:life}}
```

Three arguments are gone from the signature and three names are gone from the definition, and `HiddenClockResetEnable System` has arrived in the context beside `KnownNat n`.
It is a constraint, which is the device chapter 12 spent its first section on: `KnownNat n` says that a number `n` is available here, and `HiddenClockResetEnable System` says that a clock, a reset and an enable for `System` are available here.
`mealy` asks for it, `life` calls `mealy`, so `life` carries it, which is chapter 12's rule of putting the constraint where the compiler asks, applied to a second constraint.

Nothing has been inferred and nothing has been switched off.
The three are still handed to `mealy`, and the constraint is how they reach it; what has gone is the writing down.

## Where the three come back

```haskell
{{#include ../../../code/src/Chapters/Ch13.hs:life8}}
```

```haskell
{{#include ../../../code/src/Chapters/Ch13.hs:life16}}
```

The two annotations are chapter 12's, unchanged, and so are the two signatures.
`Clock System -> Reset System -> Enable System ->` is still written out in both, and after this edit those are the only two places in the file where it appears at all.

That is not a matter of taste.
A `Synthesize` annotation describes real ports on a real entity, a port is a wire and a wire cannot be hidden, so an annotated binder is precisely where the three have to be arguments again.
`exposeClockResetEnable` is what turns the constraint back into them: `life glider` wants a clock, a reset and an enable from somewhere, and `exposeClockResetEnable (life glider)` takes them from whoever calls it, in that order, in front of the argument it already had.
It appears twice in the file, once per entity, and it is the price of the shorter body.

`{-# OPAQUE step #-}` and `{-# OPAQUE life8 #-}` are both untouched.
`step` has no clock and never had one, so nothing in this chapter reaches it.

Reload, and ask what moved:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i mealy
mealy ::
  (HiddenClockResetEnable dom, NFDataX s) =>
  (s -> i -> (s, o)) -> s -> Signal dom i -> Signal dom o
  	-- Defined in ‘Clash.Prelude.Mealy’
clashi> :i life
life ::
  (KnownNat n, HiddenClockResetEnable System) =>
  Board n
  -> Signal System (Maybe (Command n)) -> Signal System (Board n)
  	-- Defined at src/Example/Project.hs:161:1
clashi> :i life8
life8 ::
  Clock System
  -> Reset System
  -> Enable System
  -> Signal System (Maybe (Command 8))
  -> Signal System (Board 8)
  	-- Defined at src/Example/Project.hs:176:1
clashi> sampleN 12 testBench
[False,False,False,False,False,False,False,False,False,True,True,True]
```

Chapter 7 asked `:i mealy` and got ten lines with `Clock dom`, `Reset dom` and `Enable dom` on three of them.
This is the same function from the other prelude, in four lines: the three argument lines have become one word in the context.

`:i life8` is the answer that matters, and it is chapter 12's answer.
Five arguments, in the same order, with the same types: the binder Clash generates an entity from did not move, and the body behind it is the only thing that did.
Below it, chapter 10's test bench passing in Haskell, on a design whose clock is now arriving by a route nobody wrote down.

## Generate

The command is chapter 9's, which is chapter 12's, unchanged:

```
clashi> :vhdl
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, src/Example/Project.o )
Ok, one module reloaded.
GHC: Setting up GHC took: 0.047s
GHC: Compiling and loading modules took: 1.470s
Clash: Parsing and compiling primitives took 0.164s
GHC+Clash: Loading modules cumulatively took 3.000s
Clash: Compiling Example.Project.life16
Clash: Normalization took 1.187s
Clash: Netlist generation took 0.010s
Clash: Compiling Example.Project.life16 took 1.266s
Clash: Compiling Example.Project.life8
Clash: Normalization took 0.126s
Clash: Netlist generation took 0.006s
Clash: Compiling Example.Project.life8 took 0.181s
Clash: Compiling Example.Project.testBench
Not specializing TopEntity: Example.Project.life8[8214565720323895899]
Not specializing TopEntity: Example.Project.life8[8214565720323895899]
Clash: Normalization took 0.078s
Clash: Netlist generation took 0.016s
Clash: Compiling Example.Project.testBench took 0.189s
Clash: Total compilation took 4.643s
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
```

Three binders, three directories, fourteen files, and the same two `Not specializing` lines chapter 12 explained.
The timings are this machine's and the number in the brackets is an internal name that will differ from this one.

## What changed

Back in the shell, ask which files are not what they were:

```
$ diff -r -q --exclude=clash-manifest.json vhdl-12 vhdl
Files vhdl-12/Example.Project.life16/life16.vhdl and vhdl/Example.Project.life16/life16.vhdl differ
Files vhdl-12/Example.Project.life16/life16_types.vhdl and vhdl/Example.Project.life16/life16_types.vhdl differ
Files vhdl-12/Example.Project.life8/life8.vhdl and vhdl/Example.Project.life8/life8.vhdl differ
Files vhdl-12/Example.Project.life8/life8_types.vhdl and vhdl/Example.Project.life8/life8_types.vhdl differ
```

`-q` asks for the names of the files that differ rather than for the differences, and `-r` walks the three directories.
`clash-manifest.json` is left out because it records a hash of what Clash was given, and what Clash was given did change.

Eleven files remain, and seven of them are byte for byte what chapter 12 wrote.
Both `step` entities are among them, 343 lines each, unchanged: every piece of combinational logic in this design, on both board sizes, came out identical.
So is the whole of `Example.Project.testBench/`: the 629-line test bench, its types package and the file that prints a board when a check fails, still instantiating `entity life8.life8` through the same port map.

Four files differ, and they are the two entities and their two types packages.
Take the smaller pair first:

```
$ diff vhdl-12/Example.Project.life8/life8_types.vhdl vhdl/Example.Project.life8/life8_types.vhdl
16,18c16,18
<   type St_0 is record
<     St_0_sel0_board : array_of_array_of_8_boolean(0 to 7);
<     St_0_sel1_running : boolean;
---
>   type St is record
>     St_sel0_board : array_of_array_of_8_boolean(0 to 7);
>     St_sel1_running : boolean;
42,43c42,43
<   function toSLV (p : St_0) return std_logic_vector;
<   function fromSLV (slv : in std_logic_vector) return St_0;
---
>   function toSLV (p : St) return std_logic_vector;
>   function fromSLV (slv : in std_logic_vector) return St;
181c181
<   function toSLV (p : St_0) return std_logic_vector is
---
>   function toSLV (p : St) return std_logic_vector is
183c183
<     return (toSLV(p.St_0_sel0_board) & toSLV(p.St_0_sel1_running));
---
>     return (toSLV(p.St_sel0_board) & toSLV(p.St_sel1_running));
185c185
<   function fromSLV (slv : in std_logic_vector) return St_0 is
---
>   function fromSLV (slv : in std_logic_vector) return St is
```

Five places, one identifier.
The state record is called `St_0` in chapter 12's file and `St` in this one, and its two fields carry whichever name it has.
Both are Clash's name for our `St`, which it makes unique against every other identifier it writes into the same file.
That the suffix went away is a fact about a generated name rather than about the record: the two fields are the two fields, in the order they were declared, with the types they were declared with.
Nothing else in the 227 lines moved, including the two subtypes chapters 8 and 9 counted: `Command` at sixty-six bits and `Maybe` at sixty-seven, on the lines they were on.

## The same circuit, renamed

`life8.vhdl` is 211 lines, which is what chapter 9 printed and what chapter 12 printed.
The differences are the same kind of thing as in the types package and there are more of them, so the way to read this file is to go back to what chapter 9 read in it.

The register is still one process, and it still starts like this:

```vhdl
  -- register begin
  result_register : process(clk,rst)
  begin
    if rst =  '1'  then
```

Chapter 9 read that process under the name `st_register`, and the sixty-five lines below it are still the glider followed by `St_sel1_running => false`.
The end of it:

```vhdl
    elsif rising_edge(clk) then
      if en then
        result <= result_0;
      end if;
    end if;
  end process;
  -- register end
```

One `rising_edge`, on `clk`, with `en` gating the assignment: chapter 9's process with `st <= result` spelled `result <= result_0`.
The clock reached it as a constraint rather than as an argument, and it arrived at the same port and drives the same edge.

Further down, the boundary chapter 9 drew:

```vhdl
  Example_Project_life8_step_result_1 : entity Example_Project_life8_step
    port map
      (result => result_1, b      => result_fun_arg);
```

Still one instantiation.
`lifeT` names `step` twice and there is one copy of it here feeding both, which is the claim chapter 6 made and chapter 9 first put on screen.

That is the whole of the difference, and it is a list of names.
`st` became `result`, `result` became `result_0`, `result_0` became `result_1`, and the four signals whose names began `\c$ds_case_alt` lost three characters each.
Rename those back and the two files hold the same lines, with one of them in a different place: the assignment that drives the output port sits below the register process now and sat above it before, and a concurrent assignment does not care which.
`life16.vhdl` is the same story told over 595 lines.

## Notice that

**The two entity declarations did not move at all.**
`life8` and `life16` still declare `clk`, `rst`, `en`, `cmd` and `cells`, with the same widths, byte for byte as chapter 12 generated them.
That is the strongest form of the claim this chapter set out to make: the annotation did not change, the signature it describes did not change, and the notation behind it did.

**Equivalent, not identical, and it is worth saying which.**
Four of the eleven files differ, and the differences in them are identifiers Clash generated, together with one concurrent assignment that changed position.
The circuit is the same circuit, and the files are not the same files, and a claim of byte-for-byte sameness would have been wrong in a way this chapter could not have hidden.

**The saving is one line, in this design.**
The file went from 219 lines to 218.
`life` was the only function in it that took a clock, a reset and an enable, and all it did with them was pass them to `mealy`, so there was one place to save and one line to save there.
In a design where a clock has to reach several levels of hierarchy, the three arguments are in every signature on the way down and in every call site along it; this chapter shows the shape of the saving rather than its size.

**What the shorter notation costs is the instrument this book has been using.**
`:i mealy` under `Clash.Explicit.Prelude` printed a clock, a reset and an enable as three ordinary arguments, and that is what chapter 7 read to find out what a `mealy` machine wanted.
Under `Clash.Prelude` those three lines are `HiddenClockResetEnable dom`, and what that is takes another question to answer.
It is answered in [Constraints are arguments the compiler writes](../explanation/type-classes.md), where the three wires are followed back to the constraint that delivers them.
Reading a signature was the first thing chapter 1 taught, and this is the one place in the book where the shorter form makes it harder rather than easier.

## Where this goes

The design is finished, and so is the tutorial's spine.
It is one description of Conway's Life that runs at the prompt, generates two entities at two board sizes, and carries a test bench you watched pass in a simulator that has never heard of Haskell and then read as a waveform.

You have now written it both ways.
The explicit prelude is what the first twelve chapters used, so that nothing in the design arrived without you passing it and every signature answered `:i` with something you could act on.
The hidden prelude is what you will meet everywhere else, and it is the same circuit with three arguments left unwritten.
Knowing what the short form is short for is the whole reason for having done it in that order.
