# A definition that refers to itself

Chapter 6 turned four chapters of combinational logic into a design that runs by itself, and the whole of the change was one line inside a `where` clause:

```haskell
{{#include ../../../code/src/Chapters/Ch06.hs:life}}
```

`boards` is the name being defined, and `boards` is in the expression that defines it.
The chapter said what that is, and said it in one beat: the wire running from the register's output, through the logic, back to the register's input.
Chapter 10 does something that looks harder still.
Its test bench defines `done` in terms of `clk` and `clk` in terms of `done`, on two consecutive lines, and neither of the two could have been written first.

Both of those load, and both of them run.
This page is why: what a definition that mentions its own name means, what decides whether it has an answer, and what stops a value with no end in it from taking forever the first time anything looks at it.

## The reading that does not survive

A name on both sides of one line is not new to the reader, and there are two established readings of it to leave behind.
Inside a process, `b := f(b)` reads what the variable holds at that statement and gives it something else, so the two occurrences of `b` are two values at two times, and which is which is decided by where the statement sits among the others.
As a concurrent statement, `s <= not s` is legal too and means the other thing: no statement order applies, the assignment runs again every time its input changes, and NVC gives up on it at time zero with `limit of 10000 delta cycles reached`.

The second reading is close enough to be the dangerous one.
It is order free, it is about a wire rather than a variable, and it is a loop with nothing in it, which is very nearly the right picture.
What does not carry over is the machinery underneath: there is no assignment here, nothing is scheduled, and there is no delta cycle for a new value to arrive in.
`boards` is one signal, its definition is a claim about the whole of it, and whether that claim says anything is decided by what producing one cycle of it needs.

A third habit goes with those two.
In VHDL an object is declared before it is used, and the declaration is above the use in the file.
A `where` clause does not work that way, and the indentation that makes it a clause says nothing whatever about order.

## A `where` clause has no order in it

Chapter 10's test bench is the case worth reading, because it has five bindings and they are written in an order that no reading by sequence survives:

```haskell
{{#include ../../../code/src/Chapters/Ch10.hs:test-bench}}
```

`commands`, on the clause's first line, uses `clk`, which is defined twenty-one lines further down.
`done` uses `expected` and `commands` above it and `clk` below it.
Nothing here is a forward reference that a compiler has to be clever about, because there is no forward: five bindings are five equations about five names, and [there is nothing for an order to be about](purity.md#order-stops-mattering).
What the layout does is mark which lines belong to the clause, which it does by indenting them past the `where`.
That is the whole of its job.

The claim is checkable rather than something to take on trust, and checking it costs one edit.
Written in the reverse of that order the same five bindings load, and `clk` now asks for a `done` one line below it where before `commands` asked for a `clk` twenty-one lines below.
Chapter 10's question, put to the reversed file, gets chapter 10's answer:

```
clashi> sampleN 12 testBench
[False,False,False,False,False,False,False,False,False,True,True,True]
```

Nine `False` and three `True`, from a test bench that now reads bottom to top.
`:vhdl` says it more strongly than the prompt can.
All six of the VHDL files it writes are byte for byte the ones the book's order produces, and so is the timing constraint file beside them, down to the sixteen hexadecimal digits in the name of the one package whose name carries a hash.
The only difference anywhere in the two trees is the `hash` field inside a manifest, which moves between two runs of one unchanged file as well.

## A name is in scope on its own right hand side

That is the rule, and nothing in the book has had occasion to state it.
Every name a `where` clause defines is in scope in every right hand side in that clause, including its own.
So `boards = register clk rst en glider (fmap step boards)` mentions one `boards` and not two, and there is no earlier `boards` for the inner one to have meant.

What the line then says is an equation, in the sense the tutorial has used since chapter 1: [the right hand side is the value](currying.md#a-definition-is-an-equation), and here the value is a signal.
It says that `boards` is the signal holding `glider` while the reset is asserted and, on every cycle after that, `step` of what it held on the cycle before.
Exactly one signal satisfies that, and `boards` is a name for it.
An equation whose unknown appears on both sides may have a solution and may have none, and a name for the solution of one that has it is called a fixed point.

Chapter 6's wire is not a metaphor for this: it is the same statement in the other notation.
A wire is not computed before it is connected, and connecting a register's output back to its input through some logic does not compute anything either: it constrains what the values on that wire can be, and one set of values satisfies the constraint.
The recursion the word usually brings to mind, a function that calls itself, is not what is on the page.
`boards` is a value, and it refers to itself.

## Nothing is worked out until something asks

A `Signal System Board` is one board for every cycle there will ever be, and there is no last one.
Chapter 6 said what follows from that, and it is a surprising thing to be able to say: writing one at the prompt "typechecks, and it prints until you stop it".
A value with no end can be defined, named, passed to a function and asked for its type, and none of that costs anything.

One rule explains that and everything else on this page.
An expression is not worked out where it is written; it is worked out when something needs its value, and only as far as the need reaches.
`sampleN 5` needs five cycles of `boards`, so five of them come into existence and the sixth never does.
Printing the signal itself needs all of it, which is why chapter 6's warning is not about a slow computation but about a demand with no end in it.

Demand is easiest to see by asking for one cycle more than there is.
`fromList` is chapter 7's way of driving an input, and it [crosses from a list into a signal](vec-and-lists.md#the-bridges-and-the-one-that-is-not-one), one element per cycle.
Three elements answer three cycles:

```
clashi> sampleN 3 (fromList [Nothing, Nothing, Nothing] :: Signal System (Maybe Board))
[Nothing,Nothing,Nothing]
```

The same expression asked for four begins its answer before it reaches the trouble.
The prompt prints `[Nothing,Nothing,Nothing` and then, in place of the fourth element and the closing bracket, `*** Exception: X: finite list` and a call stack naming a line in `clash-prelude`'s own source.
Three elements were there and were printed as they were produced, and the fourth is where the list ran out.
Nothing compared the length of the list against the number four beforehand, because until the first three had been printed nothing had asked for a fourth element at all.

That is the rule chapters 7, 8 and 10 are quietly obeying every time a stimulus is typed: seven elements for seven cycles, eleven for eleven, eight for eight.
Chapter 10's test bench looks like the exception, and it is safe for a different reason.
Its eight commands reach the design through `stimuliGenerator` rather than `fromList`, and that holds its last element for every cycle after the last, so asking it for twelve is an ordinary thing to do.

## The register is what makes the knot productive

Not every definition that mentions its own name says something, and this is where the page stops being reassuring.
`register`'s first output is the value it was given, and nothing about it depends on the input; every output after that needs the input only as it stood one cycle earlier.
So each cycle of `boards` needs only cycles that already exist, the reset value is what starts the chain, and the demand for the fifth cycle reaches back four cycles and stops.
That property has a name, productive, and a hardware engineer demands it of a feedback path already, under another description: a register in the loop.

Take the register out of chapter 6's line, leaving `boards = fmap step boards`.
The type is unchanged, the module loads, and nothing warns.
Asking for one cycle of it prints nothing at all, and two and a half minutes later it has still printed nothing: no result, no error, and after the first few seconds no further memory taken either.
The equation says that every cycle of `boards` is `step` of that same cycle, which is a constraint that names no cycle, so there is nothing for a first demand to reach back to.
As hardware it is the combinational loop it looks like.
Chapter 6 presented having to ask for a register by name as a cost, and this is the other side of that: a loop with nothing in it takes a deliberate omission to write.

## Two equations that need each other

Chapter 10's `done` and `clk` are the two-equation case of the same thing.
`done` is what the verifier says about the design's output, and the design is clocked by `clk`; `clk` is a clock that runs until `done` says the checking is over.
Each of them is defined in terms of the other, and as a pair they are as legal as `boards` is.

What resolves them is worth seeing in the generated file, because there the loop is a piece of hardware rather than a puzzle.
Chapter 10 quotes the process that drives the clock, and its middle is this:

```vhdl
    while (not \c$result_rec\) loop
      \Example.Project.testBench_clk\ <= not \Example.Project.testBench_clk\;
      wait for half_periodH;
      \Example.Project.testBench_clk\ <= not \Example.Project.testBench_clk\;
      wait for half_periodL;
    end loop;
```

`\c$result_rec\` is `done`.
Every iteration reads it as it stands and then produces the next two edges, so nothing in the loop ever needs a value that does not exist yet, which is the productivity of `boards` again in another notation.

At the prompt the knot never has to be untied that far, and chapter 10's own transcript shows it.
Twelve cycles came out of `sampleN 12 testBench`, and `done` goes high on the tenth of them.
A clock that runs until `done` says stop did not prevent the eleventh and the twelfth: what asks for a cycle in Haskell is the sample, and stopping the clock is something the generated file does for a VHDL simulator.
That is the stop chapter 11 is looking at when its waveform ends at 190 nanoseconds.

## What it costs

When a value is worked out is not written anywhere.
A definition says what the value is, and demand decides how much of it is ever built, so how much work has happened at a given moment is a question the file does not answer.
That has not mattered once in this tutorial, and the honest price is that it says nothing about the cases where it does: a simulation that is slower or holds more memory than it should is a job for profiling tools this book does not use, and reading the source is a poor way to guess at either.

A missing register is not a compile error.
`boards = fmap step boards` is a well typed definition of a signal, and what it buys is a prompt that does not come back, with nothing printed and nothing said.
The comparison worth making is at the top of this page, where NVC stopped a delta cycle loop at time zero and pointed at the signal driving it: the VHDL tool reports the loop, and here nothing reports anything.

Endlessness is cut by hand, every time, and nothing in the types insists on it.
`sampleN` comes in the same breath as the signal because chapter 6 made it a habit, and not because anything would object.
A stimulus shorter than the sample taken from it is an exception on the cycle it runs out rather than a length anybody checked.
A `Signal` printed bare is a design that works perfectly and a terminal that has to be interrupted.

## Where you met this

- Chapter 6, [It runs by itself](../b/06-it-runs.md): `boards` on both sides of its own `=`, five cycles from `sampleN 5`, and a signal that prints until you stop it.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `fromList`, with seven elements for the seven cycles that are sampled from it.
- Chapter 8, [More than valid](../b/08-more-than-valid.md): the same rule at a larger size, eleven commands for eleven cycles.
- Chapter 10, [A test bench that leaves Haskell](../b/10-a-test-bench.md): `done` in terms of `clk` and `clk` in terms of `done`, twelve cycles sampled from eight commands, and the clock the test bench stops itself.
- Chapter 11, [The waveform](../b/11-the-waveform.md): 190 nanoseconds of dump, which is where stopping that clock leaves the run.
