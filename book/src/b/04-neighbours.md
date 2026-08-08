# Neighbours, by moving the whole board

Chapter 2 wrote a rule that takes a count of live neighbours, and chapter 3 built the board those neighbours live on.
This chapter computes the count: for every one of the sixty-four cells, how many of its eight neighbours are alive.

The obvious way to do that is to visit each cell and look around it.
That is five hundred and twelve neighbours to fetch, each one an index expression that can be written down wrong, and twenty-eight of the cells sit on an edge, where three of those indices point off the board, or five if the cell is in a corner.
We write none of them.
Nothing in the code in this chapter picks a cell out of the board by its position.
Instead we move the whole board, once in each of the eight directions, and add the copies up.

## A type for the answer

The answer is a number for every cell, in the same shape as the board.
Add this under `render`, at the bottom of the file:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:counts}}
```

`Unsigned 4` is the type chapter 2 gave `nextCell` for its count, four bits wide because the count reaches eight.
`Counts` arranges sixty-four of them exactly as `Board` arranges its sixty-four `Bool`s, and chapter 5 will lay one on top of the other.

## Moving the whole board

Moving the elements of a `Vec` along by one is `rotateLeftS`, and moving them back is `rotateRightS`.
Ask the prompt what `rotateLeftS` wants, before writing anything that uses it:

```
clashi> :i rotateLeftS
rotateLeftS :: KnownNat n => Vec n a -> SNat d -> Vec n a
  	-- Defined in `Clash.Sized.Vector'
```

A vector in, a vector of the same length out, and between them the amount to move by, which is an `SNat d` rather than a number.
A length lives in the type, as chapter 3 established, and so does a distance to move by: `SNat` is how a number that has to be known at compile time is written, and the one we want is written `d1`.
Writing `1` there instead is the one mistake this chapter invites, and the compiler answers it by saying that `SNat` is not a `Num`, which is true and no help at all.
It is `d1`.

Now the four moves.
Add them under `Counts`:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:shifts}}
```

`shiftN` moves the board's eight rows along by one, so every row ends up where the row above it was, and the board has moved north.
`shiftS` moves it back the other way.
`shiftW` and `shiftE` do that to the eight cells within each row rather than to the eight rows, and they do it with `map`, because moving every row west by one is what moving the board west by one means.
`\r -> rotateLeftS r d1` is a function written where it is needed instead of being given a name of its own, and the backslash is there to look like a lambda.

Four definitions under one signature is four functions, all of type `Board -> Board`.
Reload and ask:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i shiftN
shiftN :: Board -> Board 	-- Defined at src/Example/Project.hs:37:1
```

Here is the seed again, and here it is moved:

```
clashi> putStr (render glider)
.#......
..#.....
###.....
........
........
........
........
........
clashi> putStr (render (shiftN glider))
..#.....
###.....
........
........
........
........
........
.#......
```

Every row has come up by one, and the row that was at the top is now at the bottom.
West does the same thing sideways:

```
clashi> putStr (render (shiftW glider))
#.......
.#......
##.....#
........
........
........
........
........
```

The third row was `###.....` and is now `##.....#`: the cell that went off the left edge came back on the right.
The board wraps, on all four edges, and every cell has eight neighbours whether it is in the middle or in a corner.

## Eight boards

Move the board north and every position holds what the position below it held.
Move it in all eight directions and each position has, across the eight copies, exactly the eight cells that surround it.

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:neighbour-boards}}
```

The four diagonals are the moves already written, applied one after the other: `shiftN (shiftW b)` is the board moved north and then west.
Nothing new is needed for them, and nothing new is needed for the corners either.

## Adding the copies up

Eight boards of `Bool` have to become numbers before they can be added, so we turn each one into a `Counts` of zeroes and ones:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:count-board}}
```

`map (map toCount)` is two levels: the inner `map` turns a row of eight `Bool`s into a row of eight numbers, and the outer one does that to all eight rows.

Adding two `Counts` together is the same two levels, with `zipWith`, which takes two vectors and combines them element by element:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:add-counts}}
```

The inner `zipWith (+)` adds a row of eight to a row of eight.
The outer one hands the rows to it in pairs.
There is one `+` in that line and no loop counter anywhere, and `addCounts` takes no arguments at all: it is `zipWith (zipWith (+))`, and that is the whole definition.

And then the count itself:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:neighbour-counts}}
```

Read it from the inside out: the eight moved boards, each turned into numbers, all added together.
`foldl1` is what "all added together" is called: given a vector and a way to combine two of its elements, it combines them until one is left.

Reload, and ask what the pieces are:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :t neighbourBoards glider
neighbourBoards glider :: Vec 8 Board
clashi> :i neighbourCounts
neighbourCounts :: Board -> Counts
  	-- Defined at src/Example/Project.hs:63:1
```

Eight boards from one, and a board of counts from a board of cells.
`head` took the first row of a board in chapter 3, so applying it twice takes the first cell of the first row, which is the cell in the top left corner:

```
clashi> head (head (neighbourCounts glider))
1
```

Look back at the picture.
The cell in the top left corner is dead, the cell to its right is alive, and its other seven neighbours, five of which are on the far side of an edge, are all dead.
One.

## All sixty-four at once

Checking sixty-four counts one at a time is not checking them.
`render` turned a board into something we could look at; this does the same for the counts, and it is the second and last thing in this tutorial that is not a circuit.

It needs one function that Clash does not supply, so add a second import directly under the first:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:import-data-char}}
```

and put this at the bottom of the file:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:render-counts}}
```

It has the same shape as `render`, one character per cell, except that the character is the digit for the count rather than `#` or `.`.
[`numConvert`](https://clash-lang.org/blog/2026-05-19-numconvert/) changes a number from one numeric type to another, here from the four-bit count to the plain `Int` that `intToDigit` wants, and it will only do it when it can show at compile time that nothing is lost.
`intToDigit` itself is ordinary Haskell from the standard library, available here for the same reason `String` was: this part is a program that prints things, not a description of hardware.

Reload, and look at all sixty-four:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i renderCounts
renderCounts :: Counts -> String
  	-- Defined at src/Example/Project.hs:67:1
clashi> putStr (renderCounts (neighbourCounts glider))
11210000
35320001
13220001
23210001
00000000
00000000
00000000
11100000
```

That is the result of the chapter, and it is worth reading against chapter 3's picture for a moment.
The `5` in the second row is the cell at the centre of the glider: it is dead, and all five of the glider's live cells touch it.
The `1`s at the right hand end of the second, third and fourth rows, and the three of them along the bottom row, are the wrap: those cells are on an edge, their neighbours are on the other one, and nothing in the code treats them differently.

## Notice that

**`map` over a `Vec 8` is a `for … generate` with eight instances.**
It is not a loop that runs eight times.
The sixty-four copies of `toCount` in `countBoard` exist at the same moment, in different places, and so do the sixty-four adders that one `zipWith (zipWith (+))` describes.
You have written this loop many times and each time it was a construct in the language; here it is a function, taking the thing to instantiate as an argument, and that is why the same three letters do the job in `fromRows`, in `countBoard` and in `shiftW`.
Chapter 9 generates the VHDL for this design, and these `map`s are in it as `for … generate`.

**Every cell's count is computed at once, and that costs what parallelism costs.**
Eight copies of the board reduced by seven additions over sixty-four cells is four hundred and forty-eight four-bit additions, described by a single `+` and laid out in space rather than repeated over time.
Nothing here is amortised over time, because there is no time here: still no clock, still no process, still nothing that runs.

**The edges are not a special case.**
There is no boundary condition in this chapter, no clamped index and no `if` asking whether a cell is on the border.
The board wraps because moving a `Vec` along by one is a rotation, and a rotation has nowhere to put the element that falls off except back at the other end.

**A `Board` and a `Counts` are the same shape, and the compiler knows it.**
`addCounts` combines two `Counts` element by element, and it can only be given two of them: eight rows of eight, checked, on both sides.
Chapter 5 pairs a `Board` with a `Counts` the same way, and the fact that both are eight by eight is not a comment or a convention but the thing that makes it compile.

## Where this goes

There is a rule for one cell, from chapter 2, and now a count for every cell.
Chapter 5 puts them together in one line and gets a generation of Life, which is still, and this is the surprising part, a single combinational block.
Leave `clashi` running.
