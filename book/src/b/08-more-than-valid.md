# More than valid

Chapter 7's input says one of two things: a board is arriving, or nothing is.
That is everything a valid bit can say, and a design that can also be told to advance a single generation, to run on its own, and to stop, needs an input with more in it than a bit.
This chapter replaces the board inside that input with four commands of our own, one of which carries a board and three of which carry nothing at all.

## Four things the outside can say

Every type in this design so far was assembled out of types that already existed: `Board` is a `Vec` of `Vec`s of `Bool`, and `Maybe Board` is a `Board` inside something the prelude supplies.
A command set is not like that, because no type already in existence has load, step, run and pause as its values.
So we declare one, directly under `step`:

```haskell
{{#include ../../../code/src/Chapters/Ch08.hs:command}}
```

`data` introduces a type and lists every value it can have.
A `Command` is a `Load`, a `Step`, a `Run` or a `Pause`, and there is no fifth thing for one to be.
`Load` has a `Board` written after it, so it is not a value by itself: it takes a board and becomes one.
The other three take nothing and are values already.

`Step` and `step` are two different names, and the capital letter is the whole of the difference between them.
Haskell requires a type or a constructor to begin with a capital and a function to begin with a lower case letter, which is how it always knows which of the two is meant.
In VHDL they would be the same name.

The `deriving` line asks the compiler to work five things out about the type instead of our writing them by hand.
`Generic` is the shape of the type, which is to say how many constructors it has and what each of them carries.
`NFDataX` and `BitPack` are worked out from that shape: `NFDataX` is what a value needs before a register will hold it, and `BitPack` is what it needs before it can be a bundle of wires.
`Eq` and `Show` are what let one be compared and printed at the prompt.

Reload, and ask about two of the four:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i Load
type Command :: Type
data Command = Load Board | ...
  	-- Defined at src/Example/Project.hs:88:5
clashi> :i Step
type Command :: Type
data Command = ... | Step | ...
  	-- Defined at src/Example/Project.hs:89:5
```

Asking about a constructor answers with the type it belongs to, that constructor in place, and the others left out.
`Load` comes back with the `Board` it takes and `Step` comes back with nothing after it, which is the difference between the two stated by the compiler rather than by us.

`Load` on its own is not a command, in the way that chapter 1's `plus 3` was not a number: it is something that still wants a board.
Give it one, and it is a command:

```
clashi> :t Load blinker
Load blinker :: Command
```

What a `data` declaration is, and why nothing outside its list can ever turn up on the wires, is explained in [A type that lists every value it can have](../explanation/data-types.md).

## A tag and a payload, both there on every cycle

Chapter 3 used `unpack` to read eight bits as eight `Bool`s.
`pack` is the other direction: it lays a value out as the bits that would carry it.
Ask it about all four commands, in the order they were declared:

```
clashi> pack (Load blinker)
0b00_0000_0000_0000_0000_0000_0000_0011_1000_0000_0000_0000_0000_0000_0000_0000_0000
clashi> pack Step
0b01_...._...._...._...._...._...._...._...._...._...._...._...._...._...._...._....
clashi> pack Run
0b10_...._...._...._...._...._...._...._...._...._...._...._...._...._...._...._....
clashi> pack Pause
0b11_...._...._...._...._...._...._...._...._...._...._...._...._...._...._...._....
```

Two bits at the front and sixty-four behind them, sixty-six in all.
The two at the front are the tag, and they count the constructors in the order the declaration lists them: `Load` is `00`, `Step` is `01`, `Run` is `10`, `Pause` is `11`.
The sixty-four behind are the payload, and on the first line they are the blinker, because `Load` is the constructor that put a board there.

A `.` is a bit whose value is not known.
`Step`, `Run` and `Pause` carry nothing, so nothing was put in the payload field, and the field is sixty-four bits wide regardless.
That is what a union costs in any language, and declaring it this way has not made it cheaper.
What it has made impossible is reading those sixty-four bits as a board while the tag says `01`.

A command arrives on some cycles and not on others, so the input is still a `Maybe`:

```
clashi> pack (Just Step)
0b101_...._...._...._...._...._...._...._...._...._...._...._...._...._...._...._....
```

Sixty-seven bits: one for the `Maybe`'s tag, then the sixty-six of the command inside it.
Chapter 11 finds those three fields on a waveform, and this is the line to have in mind when it does.

## A state with a mode in it

Chapter 7's state was a board, and the design took a generation on every cycle that brought no input.
Four commands need more than a board to work with.
`Run` has to still be in force on the cycles after the one it arrived on, or it does exactly what `Step` does, so the design has to remember whether it was last told to run or to stop.

Add this under `Command`:

```haskell
{{#include ../../../code/src/Chapters/Ch08.hs:st}}
```

`St` is a record with two fields, and a record is the part of this chapter you already have: VHDL has them and they behave the same way.
`board` and `running` are the field names, and each of them is also a function from an `St` to that field, so `board st` is the board and `running st` is the flag.
`St b False` builds one, taking the fields in the order they were declared.

It derives two of the five that `Command` derived, and `mealy` is the reason for both: the state goes through a register, a register wants `NFDataX`, and `Generic` is what `NFDataX` is worked out from.
Nothing packs an `St` into bits, because nothing sends one anywhere.

## One row per command

Replace `lifeT` and `life` with these:

```haskell
{{#include ../../../code/src/Chapters/Ch08.hs:life-t}}

{{#include ../../../code/src/Chapters/Ch08.hs:life}}
```

`lifeT` has the job it had in chapter 7: given the state the register is holding and whatever arrived this cycle, say what the register takes next and what comes out now.
What comes out is `board st`, the board of the state as it stands, so the output side is unchanged.

The `case` has one row for each thing the input can be, and every row builds the next state.
`Just (Load b)` is two tests and a name in a single expression: that something arrived, that what arrived is a `Load`, and that the board it carries is called `b`.
There is no VHDL construct for that.
You would test the valid line, decode the tag, and slice the payload, in three steps, and nothing in the language would stop you doing the third without the first two.

`Just Step` takes one generation and leaves the flag clear, `Just Run` sets the flag and leaves the board, and `Just Pause` clears the flag and leaves the board.
The `Nothing` row is the one that runs: with no command arriving, the design takes a generation if `running` says it is running, and holds the state exactly as it is if it does not.
That row is chapter 6's design with a switch on it.

`life` changes in two places, both of them small.
Its input is now `Signal System (Maybe Command)`, and the state `mealy` holds while the reset is asserted is `St glider False`: the seed from chapter 3, stopped.

Reload, and look at the three names that have changed:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i St
type St :: Type
data St = St {board :: Board, running :: Bool}
  	-- Defined at src/Example/Project.hs:94:1
instance Generic St -- Defined at src/Example/Project.hs:95:13
instance NFDataX St -- Defined at src/Example/Project.hs:95:22
clashi> :i lifeT
lifeT :: St -> Maybe Command -> (St, Board)
  	-- Defined at src/Example/Project.hs:98:1
clashi> :i life
life ::
  Clock System
  -> Reset System
  -> Enable System
  -> Signal System (Maybe Command)
  -> Signal System Board
  	-- Defined at src/Example/Project.hs:110:1
```

The two lines under `St` are the two things `deriving` asked for, reported back as what they are and pointing at the line that asked.
`lifeT` has no `Signal` in its type, exactly as in chapter 7, and is therefore a block of logic settling between one edge and the next.
`life` has gained no arguments: the fourth one has changed type, and that is the whole of the change to the interface.

## Eleven cycles

The three generators come first, as they have since chapter 6, and what they leave behind is the input:

```
clashi> :t life systemClockGen resetGen enableGen
life systemClockGen resetGen enableGen
  :: Signal System (Maybe Command) -> Signal System Board
```

Eleven cycles need eleven elements, and this is the sequence to drive them with:

```
clashi> :t fromList [Nothing, Nothing, Just Step, Nothing, Just Run, Nothing, Nothing, Just Pause, Just (Load blinker), Nothing, Nothing]
fromList [Nothing, Nothing, Just Step, Nothing, Just Run, Nothing, Nothing, Just Pause, Just (Load blinker), Nothing, Nothing]
  :: Signal dom (Maybe Command)
```

Read it as a schedule: nothing, nothing, step, nothing, run, nothing, nothing, pause, load the blinker, nothing, nothing.

```
clashi> mapM_ (\b -> putStr (render b)) (sampleN 11 (life systemClockGen resetGen enableGen (fromList [Nothing, Nothing, Just Step, Nothing, Just Run, Nothing, Nothing, Just Pause, Just (Load blinker), Nothing, Nothing])))
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
........
.#......
..##....
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
........
..###...
........
........
........
........
```

Eighty-eight rows, which is eleven boards of eight.
A command is read on the cycle it arrives and what it did appears on the next, because the register is between the two, so each board below is named by the command one cycle behind it.

The first three boards are the seed.
Two of them are the reset, as in every chapter since chapter 6, and the third one is new: in chapters 6 and 7 the third board was already the first generation.
Here it is the seed, because the state starts with `running` set to `False` and nothing has yet said otherwise.
The design is stopped, and staying stopped is something it now does.

The fourth, fifth and sixth boards are the first generation, three times over.
The fourth is `Just Step` having taken effect.
The fifth is the cycle after it, with nothing arriving and the design still stopped, which is `Step` having advanced one generation and started nothing.
The sixth is `Just Run` having taken effect, and the picture does not change, because `Run` sets the flag and leaves the board alone.

The seventh and eighth boards are the second and third generations, produced by two cycles of nothing arriving while `running` is `True`.
That is chapter 6 again, running this time because it was asked to.

The ninth board repeats the eighth, which is `Just Pause` having taken effect.
The tenth is the blinker, loaded by `Just (Load blinker)` on the cycle before.
The eleventh is the blinker still, and it is the last thing worth pointing at: in chapter 7 a loaded blinker began oscillating on the spot, and here it sits, because `Load` leaves the design stopped and nothing has said `Run`.

That is the result of this chapter: a design that is loaded, stepped, started and stopped from outside, over one port.

## Notice that

**The payload belongs to the tag, and nothing else can be made to reach it.**
You have built this many times as a tag field beside a payload field, and the rule that the payload means something only for certain tag values has lived in your head, or in a comment.
`Just (Load b)` is that rule written as the only way in: `b` exists in that one row and nowhere else in the file, so the three commands that carry no board have no name for one to misuse.
Underneath, the design still slices the payload out of the port on every cycle and discards it when the tag disagrees, which is what your hand-built version does too.

**It is sixty-six bits whichever command it is, and sixty-seven on the port.**
`Step`, `Run` and `Pause` carry nothing and are sixty-six bits all the same, because a union is as wide as its widest member and `Load` carries a board.
Wrapping it in `Maybe` adds the one bit that says whether anything arrived at all, and that sixty-seven-bit port is driven on every cycle whether a command is on it or not.
The type has not saved a wire and was never going to; what it takes away is a class of mistake, and chapter 11 is where the tag and the payload are found on a waveform.

**A record is the familiar part, and it stays a record.**
`St` is two named fields, VHDL has exactly that, and the state in the generated hardware is a record with the same two fields in it.
There is nothing here to learn and nothing here to translate.

**The design has a mode now, and the mode is one bit of state.**
Chapter 6's state was a board and chapter 7's still was; this one is a board and a flag, so the register is one bit wider than it was and nothing else about the loop has moved.
There is still one `step`, still one register, and still one combinational function between the register's output and its input.
A mode is not machinery: it is state, and it cost a field.

## Where this goes

Eight chapters in, this design has an input, an output, a clock, a reset and an enable, and nothing outside Haskell can see any of them.
Chapter 9 names the design and each of its ports, and turns it into VHDL you can read.
Leave `clashi` running.
