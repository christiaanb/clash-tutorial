# It runs by itself

Chapter 5 asked for four generations by writing `step` four times, and as hardware that is four copies of the whole generation, one behind the other.
A design that produces a generation every cycle needs one copy of it and something that holds a board from one cycle to the next.
This chapter adds that something: one register, whose output is the board and whose input is the next generation of that same board.

## What a register wants

`register` is a function like any other, so ask it what it takes before writing anything that uses it:

```
clashi> :i register
register ::
  (KnownDomain dom, NFDataX a) =>
  Clock dom
  -> Reset dom -> Enable dom -> a -> Signal dom a -> Signal dom a
  	-- Defined in ‘Clash.Explicit.Signal’
```

After the `=>`, left to right: a clock, a reset, an enable, a value of type `a`, and a `Signal dom a`, giving back a `Signal dom a`.
The value of type `a` is the one the register holds while the reset is asserted, and the `Signal dom a` after it is what the register takes on every clock edge where the reset is not.
A `Signal dom a` is a value that has one `a` in it for every cycle of the clock domain `dom`, and the domain this tutorial uses is called `System`.
The two constraints before the `=>` are requirements the compiler settles on its own here, and there is nothing to type for them.

There is no process to open, no sensitivity list to get right and no edge to test.
The clock is an argument, and the register exists because `register` was applied to it.

## Closing the loop

Add this at the bottom of the file:

```haskell
{{#include ../../../code/src/Chapters/Ch06.hs:life}}
```

`life` takes the three things `register` wants first, in the order it wants them, and returns the board as it stands in each cycle.
The signature is spread over three lines because it is too long for one, and the line breaks mean nothing.

`boards` is the register's output, and `fmap step boards` is its input: the same boards, one generation on.
`step` is `Board -> Board`, from chapter 5, and `boards` is a `Signal System Board`, so the two do not fit together directly.
`fmap` is what puts a function to work on what a signal carries: `fmap step boards` is the signal that has `step b` in it wherever `boards` has `b`.
You will meet `fmap` written `<$>` in other people's code, which is the same function under a shorter name; we spell it out everywhere in this tutorial.

`glider` is the value the register is given for the reset, so the board starts as the seed from chapter 3 rather than as sixty-four cells of nothing.

Reload, and ask what has been added:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i life
life ::
  Clock System
  -> Reset System -> Enable System -> Signal System Board
  	-- Defined at src/Example/Project.hs:78:1
```

Three arguments and a signal of boards, with `System` in place of the `dom` that `register` left open.

## Five cycles

The clock, the reset and the enable have to come from somewhere, and in simulation they come from `systemClockGen`, `resetGen` and `enableGen`.
Those three are typed in that order every time a design is run at the prompt, from here to chapter 12, and they never vary:

```
clashi> :t life systemClockGen resetGen enableGen
life systemClockGen resetGen enableGen :: Signal System Board
```

A `Signal` is every cycle there will ever be, so writing one at the prompt asks for a value that has no end: it typechecks, and it prints until you stop it.
We never do that.
`sampleN` takes a fixed number of cycles from the front, and it comes in the same breath as the signal, always:

```
clashi> :t sampleN 5 (life systemClockGen resetGen enableGen)
sampleN 5 (life systemClockGen resetGen enableGen) :: [Board]
```

A list of five boards, which is what this design has on its output in its first five clock cycles.
`render` turns one board into a picture and `putStr` prints it, and `mapM_` does that to each board of the list in turn:

```
clashi> mapM_ (\b -> putStr (render b)) (sampleN 5 (life systemClockGen resetGen enableGen))
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
..#.....
#.#.....
.##.....
........
........
........
........
........
.#......
..##....
.##.....
........
........
........
........
```

Forty rows, which is five boards of eight.
The first two are the same, and both are the seed: `resetGen` asserts the reset for the first two cycles of `System`, and while it is asserted the register holds the value it was given.
The third, fourth and fifth are the first three generations, which are the first three pictures of chapter 5, produced this time by one instance of `step` on three successive edges rather than by three copies of it typed at the prompt.

That is the result of this chapter.
Nothing in that line asked for a generation, and five of them came out.

## Notice that

**There is one copy of `step` in this design, and time does the repeating.**
Chapter 5's `step (step (step (step glider)))` is four generations of logic in series, settling in one pass, and it costs four times the area and four times the delay.
Here a generation comes out of one instance of `step`, used again on every edge, so four of them cost four cycles instead of four copies of the logic.
That trade is the reason registers exist, and this chapter made it by adding one line.

**`boards` is defined in terms of itself, and that is the feedback path.**
The right hand side of `boards` mentions `boards`, and that is not a definition eating itself: it is the wire running from the register's output, through the logic, back to the register's input.
You have drawn this loop many times.
The register is what puts a clock cycle into it, and a `where` clause is what makes it one line of source.
Why a definition may use itself, and what decides how much of it ever runs, is explained in [A definition that refers to itself](../explanation/laziness.md).

**Nothing about the register is inferred.**
There is exactly one register in this design because `register` was written once, and the clock reaching it is the clock that was passed in.
Nowhere does a tool read the shape of a process and decide that a register is what you must have meant: it was asked for by name.
The cost is on the page, and it is that three arguments are carried through every clocked function from here on, which becomes tiresome by chapter 12.
Chapter 13 is where we stop paying it.

**`Signal` is not VHDL's `signal`, and the type says which side of the register you are on.**
A VHDL `signal` is a named wire that a process assigns to; a `Signal System Board` is one board for every cycle, all of them, as a single value.
`step` is `Board -> Board` and knows nothing about time, `boards` is a `Signal System Board` and is nothing but time, and `fmap` is the only thing in this chapter that crosses between them.
That is why `sampleN` was needed to look at the result: a board can be printed, and a signal of boards has to be cut to a length first.

## Where this goes

The design runs, and it runs the only thing it can: it always starts from `glider`, because that is the value welded into the register.
Chapter 7 gives it an input, so that a board can be loaded from outside while it runs, and the input carries its own valid bit in a way that cannot be read wrong.
Leave `clashi` running.
