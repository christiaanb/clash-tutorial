# An input that cannot be misread

Chapter 6's design runs by itself, and it runs one thing: `glider`, because that board is the value the register was given and nothing else can ever get in.
A design that can be told what to work on has an input, and an input that carries a board on some cycles and not on others has to say which of the two is happening.
This chapter gives `life` that input, as one value that carries the board and the answer to that question together.

## A second board to load

There has to be something to load, so add a second seed directly under `glider`:

```haskell
{{#include ../../../code/src/Chapters/Ch07.hs:blinker}}
```

Reload and look at it:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> putStr (render blinker)
........
........
........
..###...
........
........
........
........
```

Three live cells in a row, on the fourth row of the board.
What a generation does to them is worth working out before watching it happen: the two ends have one live neighbour each and die, the middle has two and survives, and the dead cells directly above and below the middle have three each and are born.
Three in a row becomes three in a column, and three in a column becomes three in a row again.

## An input with its valid bit inside it

The thing arriving from outside is a board on some cycles and nothing on the rest, and `Maybe` is that pair of possibilities as a single type:

```
clashi> :t Just blinker
Just blinker :: Maybe Board
```

A `Maybe Board` is either `Nothing`, which is no board, or `Just b`, which is the board `b`.
That is a valid bit and a payload welded together: the tag is not a separate wire that the logic reading the payload has to remember to consult, and there is no way to reach `b` without having matched `Just` first.

It costs what it always cost.
A `Maybe Board` is sixty-five bits, one for the tag and sixty-four for the board, and on the cycles when the tag says `Nothing` those sixty-four wires still carry a value and the logic downstream still throws it away.
Nothing is switched off, and nothing is saved; what the type removes is a class of mistake.
Chapter 11 puts an input of this shape on a waveform and reads the tag and the payload off it.

## A function of a state and an input

Chapter 6 handed `register` the signal it takes next, and `fmap step boards` was what made it: the register's output, a generation of logic, and back to its input, with nothing else in the loop.
The board arriving from outside has to get into that loop, and `mealy` is `register` with the whole of the loop taken out and passed in as a function.
Ask it what it wants before writing anything that uses it:

```
clashi> :i mealy
mealy ::
  (KnownDomain dom, NFDataX s) =>
  Clock dom
  -> Reset dom
  -> Enable dom
  -> (s -> i -> (s, o))
  -> s
  -> Signal dom i
  -> Signal dom o
  	-- Defined in `Clash.Explicit.Mealy'
```

After the `=>` it is chapter 6's `register` with a function inserted into it: a clock, a reset and an enable, then `(s -> i -> (s, o))`, then an `s`, and then a `Signal dom i` becomes a `Signal dom o`.
The function is everything between the register's output and its input: given the state `s` the register holds and the input `i` arriving this cycle, it says what the register takes next and what comes out now.
The `s` after it is the state the register holds while the reset is asserted, which is where `glider` goes.

Replace `life` with these two definitions:

```haskell
{{#include ../../../code/src/Chapters/Ch07.hs:life-t}}

{{#include ../../../code/src/Chapters/Ch07.hs:life}}
```

`lifeT` is that function written for this design.
`current` is the board the register holds, `input` is the `Maybe Board` arriving this cycle, and the pair returned is the board the register takes next and the board on the output now.
The output is allowed to depend on the input as well as on the state; this one does not, and returns `current` untouched, so what comes out is the board the register is holding.

The `case` has one row for each of the input's two shapes.
`Just seed` tests the tag and names the payload `seed` in the same expression, and `seed` exists in that row and nowhere else in the file.
`Nothing` has no payload to name, so that row does what chapter 6 did on every cycle: another generation of the board we already have.

`life` gives `mealy` the three things every clocked function in this tutorial takes, then `lifeT`, then `glider`, and stops there.
What `mealy` still wants is the `Signal dom i`, so that is what `life` still wants, in the same way that chapter 1's `plus 3` still wanted the other number.

Reload, and ask about both:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i lifeT
lifeT :: Board -> Maybe Board -> (Board, Board)
  	-- Defined at src/Example/Project.hs:88:1
clashi> :i life
life ::
  Clock System
  -> Reset System
  -> Enable System
  -> Signal System (Maybe Board)
  -> Signal System Board
  	-- Defined at src/Example/Project.hs:97:1
```

There is no clock in `lifeT` and no `Signal`: a board and a `Maybe Board` in, a pair of boards out, and that is combinational logic.
`life` has one more argument than it had in chapter 6, the input, and nothing else about it has changed.

## Seven cycles

The clock, the reset and the enable come from where they have come from since chapter 6, and what they leave behind is the new argument:

```
clashi> :t life systemClockGen resetGen enableGen
life systemClockGen resetGen enableGen
  :: Signal System (Maybe Board) -> Signal System Board
```

A signal is one value for every cycle, so driving that input means saying what arrives on each of them.
`fromList` takes a list and makes it a signal, one element per cycle, in order:

```
clashi> :t fromList [Nothing, Nothing, Nothing, Just blinker, Nothing, Nothing, Nothing]
fromList [Nothing, Nothing, Nothing, Just blinker, Nothing, Nothing, Nothing]
  :: Signal dom (Maybe Board)
```

Seven elements, because we are about to look at seven cycles: nothing arrives on any of them except the fourth, which loads the blinker.
`fromList` belongs to simulation, alongside `sampleN` and the three generators: it is how a signal is made to drive a design at the prompt.

```
clashi> mapM_ (\b -> putStr (render b)) (sampleN 7 (life systemClockGen resetGen enableGen (fromList [Nothing, Nothing, Nothing, Just blinker, Nothing, Nothing, Nothing])))
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
........
........
..###...
........
........
........
........
........
........
...#....
...#....
...#....
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

Fifty-six rows, which is seven boards of eight.
The first two are the seed, because the reset is asserted for the first two cycles and the register holds what it was given.
The third and fourth are the first two generations of the glider, and they are chapter 6's third and fourth pictures unchanged, because on those cycles the input said `Nothing` and the `Nothing` row of `lifeT` is chapter 6's design.
The fifth is the blinker.
The glider is gone, and it is gone because a board arrived on the input rather than because anything in the file changed.
The sixth is three in a column and the seventh is three in a row, which is the blinker doing what the top of this chapter said it would.

`Just blinker` is the fourth element of the list and the blinker is the fifth picture, one cycle later.
The input is read on the cycle it arrives and the board it produces appears on the next, because the register is between them.

That is the result of this chapter: a design that runs on its own until it is told otherwise, and takes a whole board from outside on the cycle it is offered one.

## Notice that

**The payload cannot be read unless the tag says there is one.**
`seed` is a name that exists only inside the `Just seed` row, so writing the `Nothing` row in terms of it is not a mistake the compiler can miss: it is `Variable not in scope`, before anything runs.
You have built this by hand many times, as a valid line beside a bus, and the discipline that the bus is only meaningful while the valid line is high has been yours to keep.
Here it is not a discipline: it is the only way the value can be taken apart.

**It is sixty-five bits either way.**
The tag is a bit, the board is sixty-four, and both of them are on the port whether a board is arriving or not.
On a `Nothing` cycle the payload wires are driven with whatever the outside is putting on them and a multiplexer discards it, exactly as your hand-built version does.
The type has not saved a wire or a gate, and that was never what it was for.

**`lifeT` is combinational, and `mealy` is the register around it.**
Its type has boards and a `Maybe Board` in it and no `Signal` anywhere, which is what `:i step` said in chapter 5 and means the same thing here: a block of logic, settling between one edge and the next.
The state is one board, so this design still has exactly one register in it, the same width as chapter 6's.
What chapter 6 wrote as a binding that mentions itself is now a function that is handed its own previous answer, and `mealy` is what closes that loop and puts the clock cycle into it.

## Where this goes

The input can load a board, and that is the only thing it can say.
A design that could also be stepped one generation, run, and paused would need an input with four things in it, three of which carry no board at all.
Chapter 8 replaces `Maybe Board` with a command set of our own, where each command carries what it needs and nothing carries what it does not.
Leave `clashi` running.
