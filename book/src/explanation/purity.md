# One value, read in two places

Chapter 5 wrote a generation of Life as one line:

```haskell
{{#include ../../../code/src/Chapters/Ch05.hs:step}}
```

`b` is written twice on the right of the `=`, once as the board whose cells are being paired up and once inside `neighbourCounts b`, and the chapter said one thing about that and moved on.
That is one board read in two places, not two boards.

The claim is not about this line.
Chapter 8's `lifeT` reads `board st` five times in a definition of eight lines, and chapter 9's generated `step` entity has one port for the board that chapter 5's two reads share.
Both of those are the same rule as this one, and the rule is what this page is: what makes reading a value twice safe, what it buys once the design is hardware, and what the language gave up to have it.

## The reading that does not survive

Inside a process, what a name gives back depends on where the read is, and on which of two kinds of object the name is.
A variable takes its new value at the assignment, so two reads on either side of one give two different values.
A signal does not: it keeps the value it had until the process suspends, so two reads on either side of an assignment to it give the same value, and that value is the old one.
Neither rule is difficult, and both have to be carried to every read.

Carried over to `step`, `b` twice is two reads of something that may have moved between them, and the question worth asking about the line is what happens in between.
The answer is that nothing does.
`step` contains no assignment, and neither does any other definition in this design: there is no statement anywhere in the file, so there is no before and after for two reads to fall on either side of.

The habit that comes over with the reading is copying.
Where a value can be changed by whatever is handed it, handing the same one to two places is a decision, and taking a copy is how the decision is avoided.
`step (step glider)` in chapter 5 looks like exactly that, a board handed to something twice, with the first application's effect on it left to be worked out.

## A name has one definition, and nothing can give it a second

`=` is not assignment.
[The right hand side is the value](currying.md#a-definition-is-an-equation), and it stays the value for as long as the module is loaded.

What a reader will reach for at some point is a second `=` on the same name, and what happens is worth seeing once.
Writing `glider = blinker` at the bottom of chapter 8's file, under a `glider` that was defined at the top, does not replace the first definition and does not hide it.
The module stops loading: `[GHC-29916]`, `Multiple declarations of ‘glider’`, and under that a `Declared at:` line naming both places.

A definition written in several rows is a different thing, and the difference is worth having straight.
Adding `step b = b` directly under `step`'s own definition is accepted, because it makes `step` a two row definition, and rows are [tried in order](pattern-matching.md#rows-are-tried-in-order-and-patterns-nest) exactly as a `case`'s are.
A lowercase name matches anything, so the first row answers everything and the second can never be reached.
The compiler says so at the prompt, with no flag asked for: `[GHC-53633]`, `Pattern match is redundant`, `In an equation for ‘step’`.
What the design does is the part worth checking:

```
clashi> step glider == glider
False
```

`step` is still a generation of Life.
The second row did not update the first, replace it, or run after it; it sat below a row that had already answered, which is what a row below another row is.

The names bound inside a definition work the same way.
`b` in `step b = ...` is bound once, by the application that supplied it, and chapter 8's `st'` is bound once, by the `where` clause that defines it.
There is nothing in the language that assigns to either of them, which is why nothing in this book ever has to say when a name was last written.

## The name and the right hand side are interchangeable

The rule earns its keep in the other direction.
`step`'s definition says that wherever `step` is applied to something, the right hand side with that something in place of `b` is the same thing, and that is a claim the prompt will settle:

```
clashi> step glider == zipWith (zipWith nextCell) glider (neighbourCounts glider)
True
```

That is `step`'s definition written out at a use site, with `glider` put in for `b` in both of the places `b` appears.
The answer is the board chapter 5 printed, and nothing downstream can tell which of the two spellings was written, because a definition has nothing else about it to tell.

The property has a name worth knowing, referential transparency, and a function that has it is called pure.
It is a property of the language rather than of the way this design happens to be written: no definition in the file can read or change anything except what it was handed.
Printing is not the exception it looks like, and the reason is worth one sentence: `putStr (render b)` is a value that describes an action rather than the action taking place, and which side of that border a definition falls on is a question of its own.
So the substitution runs both ways, and this is where the rest of the page starts: an expression that occurs twice may be given one name, a name may be written out where it is used, and neither changes what the design is.
A compiler that is allowed both will use both.

## Fan out costs nothing to write

Chapter 9 drew a boundary around `step` and Clash generated an entity for it:

```vhdl
entity Example_Project_life_step is
  port(b      : in life_types.array_of_array_of_8_boolean(0 to 7);
       result : out life_types.array_of_array_of_8_boolean(0 to 7));
end;
```

One board in and one board out, and both of the reads that chapter 5's line makes are inside it: the cell rule reads `b(i_10)(i_9_2)` and the counting reads the eight shifted copies that `neighbourCounts b` made of the same port.
Two reads in the source, one port, sixty-four wires.

Chapter 8 does it at a larger size, and over a register rather than over an argument:

```haskell
{{#include ../../../code/src/Chapters/Ch08.hs:life-t}}
```

`board st` appears five times in eight lines: in four of the five rows of the `case`, and once in the pair `lifeT` returns.
The row that does not read it is `Just (Load b)`, which is the one row that replaces the board rather than keeping or advancing it.
Chapter 9's generated file is where those reads land:

```vhdl
  with (\c$ds_case_alt_selection_1\(65 downto 64)) select
    \c$ds_case_alt\ <= ( St_0_sel0_board => b
                       , St_0_sel1_running => false ) when "00",
                       ( St_0_sel0_board => result_0
                       , St_0_sel1_running => false ) when "01",
                       ( St_0_sel0_board => st.St_0_sel0_board
                       , St_0_sel1_running => true ) when "10",
                       ( St_0_sel0_board => st.St_0_sel0_board
                       , St_0_sel1_running => false ) when others;
```

`st` is the register, and `st.St_0_sel0_board` is `board st`.
The last two rows are `Run` and `Pause`, and both of them route the register's own board back into the register's input, which is what keeping a value for another cycle is in hardware.
The `"01"` row is `Step`, and `result_0` arrives from the one `step` instantiation, whose input is that same field again.
One register, five reads of the board it holds, and no board copied anywhere, because a read of a register is a wire off it and there is nothing else for it to be.

## Clash substitutes in both directions

Chapter 9 generated this design twice, and the first time it produced one file of 548 lines with everything in it: the register, the command decode, the four shifts, the adder tree and all sixty-four copies of the cell rule.
Clash inlines everything unless it is told where not to, and inlining is this page's rule used as hard as it can be used, on every name in the design at once.

The second generation added `{-# OPAQUE step #-}` and produced 211 lines and 343 lines in two files instead.
What chapter 9 says about the pair is the sentence this page needs: the entity declaration is byte for byte the same one.
A definition substituted in and a definition left standing behind a boundary are the same design, and the only difference the pragma made is where Clash wrote the logic down.

The other direction is in the same file:

```vhdl
  Example_Project_life_step_result_0 : entity Example_Project_life_step
    port map
      (result => result_0, b      => result_fun_arg);
```

`lifeT` names `step` twice, in the `Just Step` row and in the running case of the `Nothing` row, and there is one instantiation here feeding both.
Two occurrences of the same expression were replaced by one name, which is legal for the same reason the `==` above answered `True`.
Chapter 13 checks that the pair survives a change of notation: after the switch to the hidden prelude, both `step` entities are byte for byte what chapter 12 wrote, and there is still one instantiation of each.

What the rule hands out is permission, and both of these are decisions Clash took with that permission rather than promises the language makes.

## Order stops mattering

Chapter 5 said that `step (step glider)` is two blocks in series and never two cycles, and this is why.
The inner application leaves nothing behind for the outer one to find, so there is nothing to sequence and no order to get wrong.
The only thing connecting the two is that one's result is the other's argument, and in hardware that is a wire.

The same fact is what makes a `where` clause readable in any order.
`lifeT` above returns `(st', board st)` two lines before the clause that defines `st'`, and that is not a forward reference the compiler has to be clever about.
A `where` clause is a set of equations rather than a list of steps, so the order they are written in is ours to choose and the order they are worked out in is decided by which of them needs which.
Chapter 10's test bench is the sharper case: `done` is defined in terms of `clk` and `clk` in terms of `done`, on two consecutive lines, and there is no order in which either could have come first.

One shape this rule does not settle on its own is a definition that mentions its own name, which is what chapter 6's `boards` does.
That one has an answer of its own, and it is [A definition that refers to itself](laziness.md): the name on both sides is the wire from the register's output back to its input, and what decides whether such an equation says anything is a separate question.

## What it costs

State has to be somewhere, and it has to be written down.
A variable in a clocked process holds its value across an edge with nothing said about it, and there is no equivalent here: nothing survives a cycle except what was handed to a register, and a design that remembers something has to carry that something as a value through the function that computes the next one.
That is chapter 7's `mealy` and chapter 8's `St`, and the two halves of `lifeT`'s returned pair are the price in full, the next state and the output written separately because they are separate things.
What is bought with it is chapter 6's other claim: the registers in the design are exactly the ones that were written down, and no tool read the shape of anything and decided that a register is what we must have meant.

Reading a value twice saves no wires.
A fan out is a fan out in any language, and `b` reaching two places costs in VHDL what it costs here.
What the rule removes is the question of whether the two reads agree, and every answer to that question in this book is yes, before anything is run.

Sharing is a permission and not a guarantee.
One instantiation for two named uses is a fact about the file chapter 9 generated rather than something the language undertakes, and a design that needs a boundary to exist has to ask for it.
`{-# OPAQUE #-}` is the one instrument the tutorial uses for that, it asks about inlining rather than about sharing, and chapter 9 states its price: Clash does not optimise across the boundary it creates.

The hierarchy that is written is not the hierarchy that comes out.
548 lines with every definition of the design flattened into them is the default, and it is what a rule this strong looks like when a compiler is left to use it.
The names in the source are still the way the design is read and changed; they are not, without a pragma, the way it is generated.

## Where you met this

- Chapter 5, [A generation](../b/05-a-generation.md): `b` twice on one line, and `step (step glider)` as two blocks in series.
- Chapter 6, [It runs by itself](../b/06-it-runs.md): the first register, asked for by name, and nothing about it inferred.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `mealy`, and state as a value handed in and handed back.
- Chapter 8, [More than valid](../b/08-more-than-valid.md): `board st` five times in eight lines, and `st'` used above the clause that defines it.
- Chapter 9, [An entity](../b/09-an-entity.md): one port for two reads, one register for five, one instantiation for two uses, and 548 lines of everything inlined into one entity.
- Chapter 13, [What the rest of the world writes](../b/13-hidden.md): both `step` entities byte for byte across a change of notation.
