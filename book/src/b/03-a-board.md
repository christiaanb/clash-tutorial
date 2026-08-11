# A board, and a picture

Chapter 2 wrote the rule for one cell.
This chapter builds the thing that rule will run on: eight rows of eight cells, sixty-four in all, with a starting pattern written in the source as a picture of itself.
Nothing here computes anything.
We declare a type, seed it, and arrange to look at it, because for the rest of the tutorial "did that work" means "does the board look right", and that question needs a board and a way of looking.

## A type for the board

Leave `nextCell` where it is and add this underneath it:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:board}}
```

`Vec 8 Bool` is a row: eight cells, each alive or dead.
`Vec 8 (Vec 8 Bool)` is eight of those rows, and that is the board.
`type` introduces a synonym rather than a new type, so `Board` and the thing on the right of the `=` are interchangeable everywhere, and writing one of them is exactly writing the other.

The eight is inside the type, which is the part worth slowing down for, and we come back to it at the end of the chapter.

## A seed you can read

Sixty-four booleans written out one after another is not something anyone can check by eye.
Eight rows of eight bits is a picture.
So we write the seed as eight binary literals and turn them into a board:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:from-rows}}
```

A `BitVector 8` is eight bits, which is one row of the board written as one number.
`unpack` reinterprets those bits as whatever the surrounding types require, here the eight `Bool`s of a row, and `map` applies it to all eight rows at once.
`map` is doing very little work here and a great deal of it in chapter 4.

Now the seed itself:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:glider}}
```

That shape is a glider, which is the smallest pattern in Life that moves.
It does not move yet, and it will not until chapter 5.
What `:>` and `Nil` are, and how the vector they build differs from the lists that Haskell resources describe, is explained in [A Vec is not a list](../explanation/vec-and-lists.md).

## Three questions and a row

Edit, `:r`, evaluate.
The prompt is the one still open from chapter 2:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
```

Ask what `Board` is:

```
clashi> :i Board
type Board :: Type
type Board = Vec 8 (Vec 8 Bool)
  	-- Defined at src/Example/Project.hs:11:1
```

The first line says that `Board` is a type, and the second is the synonym we wrote, reported back unchanged.

Ask what `fromRows` is:

```
clashi> :i fromRows
fromRows :: Vec 8 (BitVector 8) -> Board
  	-- Defined at src/Example/Project.hs:14:1
```

Eight rows of eight bits in, a board out.

Ask what `glider` is:

```
clashi> :i glider
glider :: Board 	-- Defined at src/Example/Project.hs:17:1
```

Then ask for its first row.
`head` takes the first element of a `Vec`, and the first element of a board is a row:

```
clashi> head glider
False :> True :> False :> False :> False :> False :> False :> False :> Nil
```

That is `0b0100_0000`, one bit at a time, in the order it was written.

## A picture

One row costs seventy-four characters to print and the board has eight of them, so a whole board at the prompt is a wall of `False` with a glider hidden in it somewhere.
From chapter 4 onwards we look at boards constantly, so we give ourselves something to look at them with.

Add this at the bottom of the file:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:render}}
```

There is nothing in `render` to learn and nothing in it that will be turned into hardware.
It takes a board and produces text, one character per cell, `#` for a live cell and `.` for a dead one.

Reload, and ask what it is:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :i render
render :: Board -> String
  	-- Defined at src/Example/Project.hs:29:1
```

`render glider` is an expression rather than a name, so we ask it with `:t`:

```
clashi> :t render glider
render glider :: String
```

And `putStr` puts a string on the screen:

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
```

There is the board, and there is the seed we wrote, in the same shape we wrote it.

## Notice that

**The seed is a picture in the source and sixty-four bits in the hardware.**
`0b0100_0000` and `False :> True :> False :> False :> False :> False :> False :> False :> Nil` are the same eight bits, and `unpack` is what stands between them.
Reinterpreting a word as a collection of fields is something you already do several times a day.
The only new part is that here it is one function applied to a whole row rather than a slice expression you have to get right.

**Which reinterpretation `unpack` performs is settled by the type around it.**
Nothing at the point where `unpack` is written says that the answer should be eight `Bool`s.
`fromRows`'s signature says that the result is a `Board`, `Board` is eight rows of eight `Bool`s, and that is enough for the compiler to know which unpacking is meant.
This is worth knowing now, because it is the first of many places where a signature you wrote once decides something a long way away from where you wrote it.
How a signature written on `fromRows` can decide what `unpack` does is explained in [How the compiler knows a type you did not write](../explanation/type-inference.md).

**A length is in the type, and it is checked.**
`Vec 8` is not a list that happens to hold eight things at the moment.
The eight is fixed when the program is compiled, a function that wants a `Vec 8` cannot be handed a `Vec 7`, and the compiler is the one enforcing it rather than a comment, an assertion or a simulation that happens to notice.
Nothing in this design ever asks a row how long it is, because the answer was settled before the program ran.

**`unpack` is handed to `map` with none of its arguments supplied.**
Chapter 1 left `plus 3` sitting there and chapter 2 left `nextCell True`, both of them functions with some of their arguments given and the rest still wanted.
`map unpack` is the same idea taken to zero arguments: `unpack` is not called in `fromRows`, it is passed to `map`, and `map` is what calls it, eight times.
Chapter 4 does almost nothing else.

**`render` produces a `String`, and a `String` is not a circuit.**
It is the first thing in this tutorial that is not, and chapter 4 adds the only other one.
It exists to make the prompt useful to us, it never reaches the VHDL generator, and it costs nothing in hardware because there is no hardware for it.
Everything else we write is a description of something that ends up as gates.

## Where this goes

The board can be seen, and nothing has yet looked at it.
Chapter 4 counts the live neighbours of all sixty-four cells at once, without writing a single index expression, by moving the whole board eight times.
Leave `clashi` running.
