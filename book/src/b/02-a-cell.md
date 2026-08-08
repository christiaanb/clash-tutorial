# A cell

Conway's Game of Life is one rule about one cell, applied to every cell at once.
A cell is either alive or dead, and it has eight neighbours: the four cells north, south, east and west of it, and the four on the diagonals.
A live cell with two or three live neighbours is alive in the next generation, a dead cell with exactly three live neighbours becomes alive, and every other cell is dead.
That is the whole game.

This chapter writes that rule for a single cell.
Counting a cell's neighbours is chapter 4's problem and doing all sixty-four cells at once is chapter 5's, so here the count arrives as an argument and the answer comes back as one bit.

## The edit

`plus` has done its job.
Open `src/Example/Project.hs` and delete it, and delete `topEntity` with it: `topEntity` names the top of the design, and nothing in this chapter is the top of anything.
We write it again in chapter 9, when there is a design for it to be the top of.

In their place, write the rule:

```haskell
{{#include ../../../code/src/Chapters/Ch02.hs:next-cell}}
```

The file is now four things: the module header, the import, that signature and that definition.

## The reload

One habit before we evaluate anything, and it does not vary for the rest of the book.
`clashi` holds the module it compiled when it started, not the file on disk, so after every edit we reload with `:r` before asking the prompt anything.
Edit, `:r`, evaluate.
Skip the middle step and the prompt answers about the previous version of your own code, which reads exactly like the edit having been wrong.

The prompt from chapter 1 is still open.
Reload it:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
```

## Six questions

Ask what `nextCell` is:

```
clashi> :i nextCell
nextCell :: Bool -> Unsigned 4 -> Bool
  	-- Defined at src/Example/Project.hs:6:1
```

A cell's state in, a four bit neighbour count in, the cell's next state out.

The first row of the `case` is a live cell with two live neighbours:

```
clashi> nextCell True 2
True
```

The second row is three live neighbours, and it does not care whether the cell was alive:

```
clashi> nextCell True 3
True
clashi> nextCell False 3
True
```

The third row is everything else, which is a dead cell that missed, a live cell with too few neighbours, and a live cell with too many:

```
clashi> nextCell False 2
False
clashi> nextCell True 1
False
clashi> nextCell True 4
False
```

Six answers, and they are the three sentences at the top of this chapter.

One more question, of the kind chapter 1 asked about `plus 3`:

```
clashi> :t nextCell True
nextCell True :: Unsigned 4 -> Bool
```

## Notice that

**This is a truth table and it reads as one.**
Three rows, left to right: the cell, the count, the answer.
There is no process, no sensitivity list and no clock, and there will not be one until chapter 6.

**Branches are tried in order and the first match wins.**
`nextCell True 3` matches the second row, `(_, 3)`, and it also matches the third row, which matches everything.
The second row wins because it is written first.
This is where your VHDL will mislead you: there, the choices of a `case` must be mutually exclusive and must cover every value, and the compiler holds you to both.
Here they need not be exclusive, and the overlap is what lets three rows say what a table of thirty-two would otherwise have to.

**The width is in the type, and the range is not.**
`Unsigned 4` is a four bit unsigned number, which is what a count that reaches eight needs, and those four bits are in the type rather than in a comment or a constant.
A caller cannot hand `nextCell` a `Signed 8` or a `Bool` in that position, and the compiler is the one checking.
It checks the width and not the range: four bits also hold 12, and `nextCell True 12` answers `False`, because 12 is neither 2 nor 3.
Nothing in this chapter promises the count stays below nine, and nothing needs to: in chapter 4 the count is eight one bit values added together, and it cannot be larger.

**`nextCell True` is a legal thing to have.**
Chapter 1 left `plus 3` sitting there and promised it would come back.
This is the same thing: supply the first of two arguments and what remains is something that still wants an `Unsigned 4` and will give you a `Bool`.
In chapter 4 we start handing functions around with none of their arguments supplied, and that is when this stops being a curiosity.

## Where this goes

`nextCell` is one cell's rule, and it is the only rule the design has.
Chapter 3 builds something for it to run on: eight rows of eight cells, written in the source as a picture of a board and printed at the prompt as one.
Leave `clashi` running.
