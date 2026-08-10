# A case expression is a multiplexer

Chapter 2 wrote the whole of Conway's rule as three rows:

```haskell
{{#include ../../../code/src/Chapters/Ch02.hs:next-cell}}
```

and called it a truth table.
It is one, and the chapter left it there: three rows, read left to right, the cell, the count and the answer.
Then it checked the rows one at a time, and the second row answered twice:

```
clashi> nextCell True 3
True
clashi> nextCell False 3
True
```

Three things about that construct were left standing.
It sits to the right of an `=`, where a value belongs.
The shapes to the left of each `->` are not expressions, and one of them is a single underscore.
And the thing after the word `case` is a pair in parentheses, of a kind nothing in the file declared.
This page is all three.

## The reading that does not survive

A `case` in VHDL is a statement.
It appears inside a process, it assigns to a signal or a variable, and its choices must be mutually exclusive and must between them cover every value the selector can take.
The compiler holds you to both, and chapter 2 told the reader that the first of the two is not true here: the rows may overlap, and the first one that matches wins.

That leaves the rest of the reading in place, and the rest of the reading does more damage than the part chapter 2 corrected.
Under it a `case` is something that runs and does something to a target, so chapter 7's `lifeT` is a statement written where a value was wanted.
`Just seed` is a comparison against an object called `Just seed`, and nothing declared any such object.
`case (alive, n) of` selects on something with two things in it, which no selector may be.
All three compile, and none of them is doing what that reading says it does.

## A case has a value

`nextCell`'s definition is a name, two arguments, an `=`, and then the `case`.
Nothing follows the `case`, so the `case` is the whole of the right hand side, and a definition's right hand side is not a body that computes a value but [the value itself](currying.md#a-definition-is-an-equation).
Something that ran and assigned could not stand in that position at all.

Being a value has one consequence worth stating on its own: every row must produce the same type.
Chapter 2's three rows all produce a `Bool` and chapter 8's five all produce an `St`, and the `case` has the type that its rows have.
There is no row that produces nothing, and no row that produces something of another shape to be sorted out later.

In hardware this is the multiplexer and not the process around it.
The value after `case` is the select input, the rows are the inputs being selected between, and the value of the whole expression is what leaves the multiplexer.
Nothing is assigned, so nothing can be assigned twice on one pass and nothing can be left unassigned on a path through the logic.
The branch that mentions no target and quietly leaves a latch behind has nothing to work on here, because there is no target to mention and no branch that produces less than a value.

## A pattern is a shape with holes

Left of each `->` is a pattern.
A pattern is matched rather than evaluated, and chapter 2's three rows use three kinds of it.

A literal matches itself and nothing else: the `2` in the first row matches the count 2, and the `True` beside it matches a cell that is alive.
An underscore matches anything and binds nothing, which is how the second row says that three live neighbours settle the question and the cell's own state is not consulted.
A lowercase name matches anything and gives it that name, and this is the kind that is not in the `case` at all: it is in the line above.
`nextCell alive n` puts two patterns to the left of the `=`, and `alive` and `n` are names for whatever arrived.

Chapter 7 adds the fourth kind, and it is the one the tutorial gets the most out of:

```haskell
{{#include ../../../code/src/Chapters/Ch07.hs:life-t}}
```

A constructor pattern matches a value built with that constructor, and whatever is written after the constructor matches what it carries.
`Just seed` therefore tests the tag and names the payload in one expression, which is chapter 7's sentence for it, and `seed` is the name of the board that was inside the `Just`.

How far that name reaches is a property of patterns rather than a property of `Maybe`: a name a pattern binds exists in its own row and nowhere else.
Chapter 7 leans on exactly that, and reports that writing the `Nothing` row in terms of `seed` is `Variable not in scope` before anything runs.
The reason is that `Nothing` is a different row, and there is no point at which both rows' names are in scope, because there is no moment at which both rows happened.

## Rows are tried in order, and patterns nest

Chapter 8 is the same construct with more in it:

```haskell
{{#include ../../../code/src/Chapters/Ch08.hs:life-t}}
```

`Just (Load b)` is a pattern inside a pattern.
The outer one tests that something arrived, the inner one tests that what arrived is a `Load`, and `b` names the board that `Load` carries.
Two tests and a binding, nested the way the value was built, and a pattern may go as deep as the value does.
Chapter 8 puts the VHDL beside it: test the valid line, decode the tag, slice the payload, three steps in which nothing stops you doing the third without the first two.

Order decides, and it decides differently in the two chapters.
Chapter 2's rows overlap on purpose, so `nextCell True 3` matches the second row and the third one as well, and the second wins because it is written first:

```
clashi> nextCell True 1
False
clashi> nextCell True 4
False
```

Both of those answers come from the third row, and what that row means is everything the two rows above it did not take.
That is what lets three rows say what a table of thirty-two would otherwise have to.
Chapter 8's five rows do not overlap at all, because a `Maybe Command` is exactly one of `Nothing`, `Just (Load b)`, `Just Step`, `Just Run` and `Just Pause`.
Reordering them would change nothing, and first match wins is a licence rather than an obligation.

## The thing after the word `case`

`(alive, n)` is a tuple.
Two values in parentheses with a comma between them are one value holding both, and nothing had to be declared for it: the type is `(Bool, Unsigned 4)`, written the same way as the value.
It is there because a `case` selects on one value while the rule depends on two, so the two are put together and taken apart again in the same expression.

The same shape appears on the way out of `lifeT`, which returns `(next, current)` and has `(Board, Board)` at the end of its type.
That is also why `mealy`'s signature has a pair inside it.
Chapter 7 quotes `(s -> i -> (s, o))` as the function `mealy` wants, and the pair in it is how one function says two things: what the register takes next, and what comes out now.

A tuple is not storage and not a component.
Chapter 7's `lifeT` returns two boards and chapter 7's design has one register in it, the same width as chapter 6's, because the two halves of that pair go to two different places and neither of them is a box around anything.

## `if` is the two row case

The first `if` in the book is in the one block chapter 3 said had nothing in it to learn:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:render}}
```

`if x then '#' else '.'` has both branches, and both of them are a `Char`.
Neither of those is a style rule.
The whole expression must have a value, so there has to be a branch for `False`, and the value has to have one type, so the two branches have to agree on it.
There is no `if` with only a `then`, and chapter 4's `toCount x = if x then 1 else 0` is the same two rows deciding between two numbers instead of two characters.

That is the difference worth carrying away, and chapter 8's `Nothing` row is where it shows, in the two words `else st`.
A VHDL process would write nothing at all in that branch and let the register keep what it had.
Here keeping it is a value like any other, and `st` is that value: the state as it stands, handed back unchanged.
There is no branch in which nothing happens, because a branch is not a place where things happen.

## What it costs

The compiler has two opinions about a `case`, both of them warnings rather than rejections, and they are switched on differently.

A row that cannot be reached is reported wherever the module is compiled, the prompt included.
Moving chapter 2's `_` row above the other two gets `[GHC-53633] Pattern match is redundant`, naming the row that can no longer happen.
A `case` that does not cover its type is reported only where the warning has been asked for.
The project chapter 1 generates asks for it, so `stack build` answers a missing row with `[GHC-62161] Pattern match(es) are non-exhaustive` and lists the values that have no row to go to, while `:r` at the prompt says `Ok, one module reloaded.` and nothing more.

Neither warning has anything to say about the code in this book, and that is the cost rather than the reassurance it sounds like.
Every `case` in the tutorial ends in a row that matches everything, so none of them is incomplete and none of them can be.
The fall through row is what makes three rows do the work of thirty-two, and it is also what turns a row you meant to write and did not into an answer that looks deliberate.
Chapter 2 shows the shape of that without the mistake in it: `nextCell True 12` answers `False`, which is correct here because twelve is neither two nor three.
Four bits hold twelve, nothing in `Unsigned 4` says the count stops at eight, and the third row answers for twelve exactly as confidently as it answers for five.
What makes it safe is chapter 4, where the count is eight one bit values added together and cannot be larger, and that argument lives in the design rather than in the `case`.

This one is not a difference between the two languages.
VHDL makes the coverage check compulsory and makes it an error, and `when others` is the same escape from it, bought at the same price.
It is worth saying on a page that has spent its length on what the construct does well.

## Where you met this

- Chapter 2, [A cell](../b/02-a-cell.md): three rows, six evaluations, and the first match winning.
- Chapter 3, [A board, and a picture](../b/03-a-board.md): `if x then '#' else '.'`, in `render`.
- Chapter 4, [Neighbours, by moving the whole board](../b/04-neighbours.md): the same `if` in `toCount`, between two numbers.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `Just seed`, a pattern that names what it matched, and a pair returned.
- Chapter 8, [More than valid](../b/08-more-than-valid.md): `Just (Load b)`, five rows that do not overlap, and `else st`.
