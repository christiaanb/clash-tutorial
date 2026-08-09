# One description, two sizes

Every board in this design is eight cells by eight, and the eight has been in the source since chapter 3.
It is in `Board`, in `Counts`, in the board a `Load` carries, in the state register and in the width of every port chapter 9 named.
This chapter takes it out of the description and puts two of them back at the top, so that one `:vhdl` writes an 8×8 entity and a 16×16 one from the same code.

You have done this in VHDL with a generic, and the shape of the answer is the same.
What is new is that the size is checked: a `Vec n` and a `Vec 8` are different types, and neither one can quietly turn up where the other belongs.

## A number the type takes

Start at the top of the file, where `Board` is:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:board}}
```

`Board` used to be a type; `Board n` is a type with a number in it, and `Board 8` is what the last nine chapters were writing.
`fromRows` builds one from `n` rows of `n` bits, and it has picked up the first `KnownNat n` of the chapter, which is the constraint the rest of this section is about.

Every signature in the file names `Board` or `Counts`, so every signature in the file changes, in one of two ways.

The four seeds are 8×8 boards and now say so: `glider :: Board 8`, and `blinker`, `glider1` and `glider2` the same.
The two functions that print take a board, or a table of counts, of any size at all: `render :: Board n -> String` and `renderCounts :: Counts n -> String`.

Everything that computes over a board takes the size and a constraint with it:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:counting}}
```

`KnownNat n` says that `n` is a number whose value is known when the design is compiled, which is what lets a shift of one position know how far round to wrap.
Where it goes is not a matter of taste: the compiler asks for it by name, at the definition that needs it, and its message suggests the words to add.
`rotateLeftS` has to know the length of what it rotates, so the four shifts carry it; `neighbourBoards` calls the shifts and `neighbourCounts` calls `neighbourBoards`, so each of those carries it in turn.

`countBoard` and `addCounts` do not, and that is not an oversight.
`map` and `zipWith` do the same thing to every element of a vector whatever the number of elements is, so neither of them ever asks how many there are.

Then `step`, which is where the counts and the rule meet:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:step}}
```

The `{-# OPAQUE step #-}` above it is chapter 9's and does not change.

## The one edit that is not mechanical

A `Load` carries a board, so `Command` takes the size too, and so does the state record that holds one:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:command}}
```

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:st}}
```

Three `deriving instance` lines have appeared below the declarations, and what they have in common is the context `KnownNat n =>`.
The reason is `BitPack`: it is what decides that a `Command` is sixty-six bits, and sixty-six is now `n * n + 2`, so the width cannot be worked out until `n` is.
Inside a `deriving` clause there is nowhere to say that, and GHC's answer is `solveWanteds: too many iterations`, which is the derivation giving up rather than a mistake it can point at.
Written standalone, `KnownNat n =>` is the thing there was nowhere to say.
`NFDataX` needs a context for the same kind of reason and gets the same one; `Generic`, `Eq` and `Show` need none and stay where they were.

## The seed becomes an argument

`lifeT` changes in its signature and nowhere else:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:life-t}}
```

`life` changes in one more place:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:life}}
```

`mealy`'s initial state was `St glider False`, and `glider` is a `Board 8`.
A description that does not know its size cannot name the board it starts from either, so the seed arrives as an argument.
That is a fifth argument added to the design for the sake of a parameter, and it is the plainest thing in this chapter about generality not being free.

## Two names at the top

Chapter 9's annotation has to come off `life`, and this is the first time the tutorial has asked you to unmake something you made.
Delete the whole `{-# ANN life (Synthesize …) #-}` block above `life`'s signature, all nine lines of it.
A port list is a fixed number of wires and `life` no longer has a fixed number of them; left where it is, it would also be a third entity.

Two annotations go in its place, and the first one goes below `life`:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:life8}}
```

That is chapter 9's annotation with one word changed.
The only eight in it is inside a name, and a name is not a width: `t_name` says what the entity is called and `t_inputs` says what its ports are called, and how wide those ports are is settled by `life8`'s signature and nowhere else.
`life8 = life glider` is `life` with its seed supplied, and the four arguments left over are the four ports the annotation names.
`{-# OPAQUE life8 #-}` is chapter 10's pragma, moved to the binder the test bench is about to instantiate.

The test bench follows the name.
Its annotation becomes `{-# ANN testBench (TestBench 'life8) #-}` and the line that drives the design becomes `done = expected (life8 clk rst enableGen commands)`.
The eight commands and the eight boards below them are untouched.

Reload, and ask whether the 8×8 design still does what it did:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i step
step :: KnownNat n => Board n -> Board n
  	-- Defined at src/Example/Project.hs:111:1
clashi> putStr (render (step glider))
........
#.#.....
.##.....
.#......
........
........
........
........
clashi> sampleN 12 testBench
[False,False,False,False,False,False,False,False,False,True,True,True]
```

`:i step` is the whole edit in one line: the rule for a generation of Life, on a board of any size, and the size gone from the type.
The picture below it is chapter 5's first generation of the glider, and the list below that is chapter 10's test bench passing, in Haskell, with every board it expects unchanged.

## A second size

Now there is something to write that could not have been written before.
Under `glider2`, a 16×16 board with the same glider in its corner:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:glider16}}
```

And under `life8`, a second entity:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:life16}}
```

Identical to `life8` apart from `t_name`, the seed and the two numbers in the signature.
There is no `OPAQUE` pragma on it, because nothing instantiates it: the test bench drives `life8`, and a `Command 16` will not go into it.

Reload, and run a 16×16 board through code that has never seen one:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> putStr (render glider16)
.#..............
..#.............
###.............
................
................
................
................
................
................
................
................
................
................
................
................
................
clashi> putStr (render (step glider16))
................
#.#.............
.##.............
.#..............
................
................
................
................
................
................
................
................
................
................
................
................
clashi> putStr (render (step (step glider16)))
................
..#.............
#.#.............
.##.............
................
................
................
................
................
................
................
................
................
................
................
................
```

The seed reads back as the picture it was written as, and the two generations after it are the two chapter 5 printed for the 8×8 glider, in the same rows and the same columns.
Nothing in `step`, `neighbourCounts` or the four shifts was changed to make that happen, and nothing in them was written for sixteen.
`render` never knew either size: its body is the one written in chapter 3, and it printed sixteen rows because it was handed sixteen.

## One command, three directories

Generate:

```
clashi> :vhdl
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, src/Example/Project.o )
Ok, one module reloaded.
GHC: Setting up GHC took: 0.051s
GHC: Compiling and loading modules took: 1.593s
Clash: Parsing and compiling primitives took 0.160s
GHC+Clash: Loading modules cumulatively took 3.016s
Clash: Compiling Example.Project.life16
Clash: Normalization took 0.944s
Clash: Netlist generation took 0.007s
Clash: Compiling Example.Project.life16 took 1.010s
Clash: Compiling Example.Project.life8
Clash: Normalization took 0.107s
Clash: Netlist generation took 0.006s
Clash: Compiling Example.Project.life8 took 0.160s
Clash: Compiling Example.Project.testBench
Not specializing TopEntity: Example.Project.life8[8214565720323897895]
Not specializing TopEntity: Example.Project.life8[8214565720323897895]
Clash: Normalization took 0.061s
Clash: Netlist generation took 0.015s
Clash: Compiling Example.Project.testBench took 0.161s
Clash: Total compilation took 4.354s
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
```

Three binders in the file carry an annotation, so `:vhdl` compiled three, one after another, and wrote fourteen files into three directories under `vhdl/`.
`Example.Project.life8/` and `Example.Project.life16/` hold five each, named for their `t_name`s, and `Example.Project.testBench/` holds chapter 10's four.
The two `Not specializing` lines are the `OPAQUE` pragma on `life8` again, and the number in them is an internal name that will differ from this one.

Open `life8.vhdl` and `life16.vhdl` and read the first thing in each:

```vhdl
entity life8 is
  port(-- clock
       clk   : in life8_types.clk_System;
       -- reset
       rst   : in life8_types.rst_System;
       -- enable
       en    : in life8_types.en_System;
       cmd   : in life8_types.Maybe;
       cells : out std_logic_vector(63 downto 0));
end;
```

```vhdl
entity life16 is
  port(-- clock
       clk   : in life16_types.clk_System;
       -- reset
       rst   : in life16_types.rst_System;
       -- enable
       en    : in life16_types.en_System;
       cmd   : in life16_types.Maybe;
       cells : out std_logic_vector(255 downto 0));
end;
```

Five ports and five names, twice, from two annotations that say the same thing.
`cells` is sixty-four bits in one entity and two hundred and fifty-six in the other, and that is the chapter in two numbers: two files, one description.

`cmd` widens with it, and the numbers are in `life16_types.vhdl`:

```vhdl
  subtype Command is std_logic_vector(257 downto 0);
  subtype Maybe is std_logic_vector(258 downto 0);
```

Chapter 8 counted a `Command` as a two-bit tag and a sixty-four-bit payload, sixty-six in all, and a `Maybe Command` as sixty-seven.
Two hundred and fifty-eight and two hundred and fifty-nine are the same two sums with a 16×16 board in the payload.

## The same description, twice

Chapter 9 drew one boundary inside the design, and it is still drawn.
Each entity has a `step` of its own beside it, and their declarations are worth putting side by side:

```vhdl
entity Example_Project_life8_step is
  port(b      : in life8_types.array_of_array_of_8_boolean(0 to 7);
       result : out life8_types.array_of_array_of_8_boolean(0 to 7));
end;
```

```vhdl
entity Example_Project_life16_step is
  port(b      : in life16_types.array_of_array_of_16_boolean(0 to 15);
       result : out life16_types.array_of_array_of_16_boolean(0 to 15));
end;
```

Two components rather than one, and this is where Clash and a VHDL generic part company.
A generic would have given you a single entity carrying a `generic` and two instantiations of it; Clash specialises instead, and writes the entity out once for each size it is used at.
That is worth saying plainly, because the count of copies is the argument this tutorial has been making since chapter 6, and here the count went up.

What is shared is the description, and the two files show it.
`Example_Project_life8_step.vhdl` and `Example_Project_life16_step.vhdl` are 343 lines each.
Every line of one has a line of the other in the same position, and every difference between them is a number: `0 to 7` against `0 to 15`, `1 mod 8` against `1 mod 16`.
Fifty-five lines of the three hundred and forty-three, and seven more where the only difference is how far across the page a comma sits, because one type name is a character longer than the other.

The top entities are less alike, and the reason is the seed.
`life8.vhdl` is 211 lines, which is chapter 9's `life.vhdl` with `life` renamed to `life8` and nothing else touched.
`life16.vhdl` is 595, and the 384 lines of difference are the 16×16 glider written out twice, once as the state signal's initial value and once as what the register takes while the reset is asserted: 256 boolean literals in the places where the 8×8 file has 64.

## Notice that

**One description, two entities, and the second one was never tested.**
The 16×16 design was written by adding a seed and a second annotation, and it works because nothing between `nextCell` and `life` was ever told a size.
That is what the `n` bought, and it is what a VHDL generic buys too.

**What the generic does not buy, and this does, is the check.**
`Board n` and `Board 8` are different types, and a `Command 16` cannot be handed to `life8`.
A VHDL tool would tell you that when it elaborated the instantiation; here the module does not compile, and nothing is generated to elaborate.

**Two sizes cost two of everything below the description.**
Two entities, two `step` components, two types packages and two registers, because there are two circuits, and a parameter does not make one circuit fit two widths of wire.
The source is the thing that is shared, and it is the only thing that is; no part of this chapter claims otherwise.

**A polymorphic function is not a component until something fixes its size.**
`life` has no entity of its own anywhere in the generated tree: it carries no annotation, and what it describes reaches the VHDL only through `life8` and `life16`.
That is chapter 9's sentence from the other side, a port list being a fixed number of wires, and it is why the two annotations sit where the number is fixed.

## Where this goes

Every version of `life` in this book has taken a clock, a reset and an enable as arguments and passed them down by hand, and `systemClockGen resetGen enableGen` has been ritual at the prompt since chapter 6.
Chapter 13 deletes all three from every signature in the file, adds one constraint where the compiler asks for it, and generates the same VHDL.
It is the style you will meet in every Clash project you read after this one, and it is worth arriving at last, with both halves of it in view.
