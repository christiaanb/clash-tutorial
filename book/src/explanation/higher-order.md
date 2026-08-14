# The thing you instantiate is an argument

Chapter 4 described sixty-four adders and wrote one `+`:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:add-counts}}
```

The chapter said what the line does and went on.
The inner `zipWith (+)` adds a row of eight to a row of eight, the outer one hands the rows to it in pairs, and there is one `+` in that line and no loop counter anywhere.
What it did not say is what kind of thing `zipWith` is, or what `(+)` is doing in parentheses in a place where an argument goes.

The same question was open a chapter earlier and the tutorial noticed it out loud.
Chapter 3's `fromRows` is `map unpack`, and the chapter's own words for that were that `unpack` is not called there, it is passed to `map`, and `map` is what calls it, eight times.
This page is what `map`, `zipWith` and `foldl1` are, and how far the idea they are built on goes.

## The reading that does not survive

`for … generate` is a construct.
It may appear in an architecture and not in an expression, what it instantiates is written out inside its own body, and there is nothing you can do with it except write one where one is allowed.
A reader carrying that over will look for the construct, find three letters that look like a function call, and settle on the reading that `map` is a keyword of some kind with a special argument position in it.

That reading survives chapter 3 and then costs more with every chapter.
`zipWith (zipWith (+))` becomes a call inside a call, when neither of them calls anything.
`(+)` in parentheses becomes an addition with its operands left out.
`foldl1 addCounts` becomes a function invoked on a function, and `map (\r -> rotateLeftS r d1) b` becomes a construct with a fragment of syntax where its first argument belongs.
Chapter 7 then quotes `(s -> i -> (s, o))` as one of `mealy`'s arguments, and under this reading that type has no reading at all.

None of those is special syntax.
`map` is an ordinary function, `(+)` is an ordinary value, and what looks like a construct is the first applied to the second.

## The first argument is a function

Ask the prompt about the two functions chapter 4 leans on, neither of which the chapter stopped to interrogate:

```
clashi> :i map
map :: (a -> b) -> Vec n a -> Vec n b
  	-- Defined in ‘Clash.Sized.Vector’
clashi> :i zipWith
zipWith :: (a -> b -> c) -> Vec n a -> Vec n b -> Vec n c
  	-- Defined in ‘Clash.Sized.Vector’
```

Each of them takes something with arrows inside it, and the parentheses are the whole of what makes that an argument rather than more of the chain.
`(a -> b) -> Vec n a -> Vec n b` wants a function and then a vector.
`a -> b -> Vec n a -> Vec n b` would want two values and then a vector, and it is a different type, because [the arrow groups to the right](currying.md#one-argument-at-a-time) and a parenthesised arrow on the left of another is the one shape that grouping never produces.
Reading those parentheses is most of reading a signature in this book.

Nothing in either type marks the function argument as unusual, and nothing needs to.
A function is a value, in the sense that it can be named, passed and returned, and `map`'s first argument is a value of a type that happens to have an arrow in it.
There is no second kind of function that may be passed and no annotation that permits it.

What `map` does with the value it is given is instantiate it, once per element, and the type says how many times without saying which number.
`Vec n a` and `Vec n b` have the same `n`, so eight elements in is eight instances and eight results out.
The count never appears as a value: `map` does the same thing to every element whatever the number of elements is, which is chapter 12's sentence for why `countBoard` and `addCounts` need nothing added to them when the board becomes sixteen by sixteen.

## `(+)` is the adder, not the addition

An operator is a function that is written between its two arguments rather than in front of them.
Parenthesising it stops it being written that way and leaves the function:

```
clashi> :t (+)
(+) :: Num a => a -> a -> a
```

Two numbers in and a number out, which is exactly the shape `zipWith` wants first.
Handing it over gives back the rest of `zipWith`'s type:

```
clashi> :t zipWith (+)
zipWith (+) :: Num c => Vec n c -> Vec n c -> Vec n c
```

That is one adder handed to something that will place a row of them, and what comes back is a function of two vectors that has not been given any yet.
`addCounts = zipWith (zipWith (+))` is that once more, one level up: `zipWith (+)` is itself a function of two arguments, so it goes where `zipWith`'s first argument goes, and what comes back adds two vectors of vectors element by element.
`addCounts`'s signature is what fixes the sizes: `Counts -> Counts -> Counts`, eight rows of eight four-bit numbers on both sides.
The `Num c` in front of the `=>` is a requirement rather than an argument, and chapter 4 needed no part of [what those are](type-classes.md).

Chapter 9 is where handing `(+)` over is paid out.
The generated VHDL for this design has three `for … generate` blocks nested inside each other, seven by eight by eight, and one `+` at the centre of them, which is the four hundred and forty-eight additions chapter 4 counted.
The construct is still in the output.
What changed is that it is no longer what we wrote: we wrote a function applied to an argument, and the construct is what that came to.

## A function with no name

Chapter 4's four shifts contain the only function in the reader's file that is written where it is used:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:shifts}}
```

`\r -> rotateLeftS r d1` is a function and nothing else.
The backslash starts it, `r` is its argument, what follows the arrow is its result, and it has no name because nothing needs to refer to it twice.
The prompt reports it as the kind of value the two signatures above ask for:

```
clashi> :t (\r -> rotateLeftS r d1)
(\r -> rotateLeftS r d1) :: KnownNat n => Vec n a -> Vec n a
```

Why one is needed here is worth a moment, because `shiftN` did not need one.
`shiftN b = rotateLeftS b d1` has a name for the board, so the distance can simply be written after it.
Inside `shiftW` there is no name for the row, and supplying an argument to `rotateLeftS` supplies [the first one](currying.md#what-plus-3-is), which is the vector.
The argument we want to fix is the second, partial application cannot reach past the first, and the lambda is how a function with the distance already in it and the vector still to come is built instead.

The other lambda in the book is at the prompt rather than in the file, in `mapM_ (\b -> putStr (render b))`, which the reader retypes in chapters 6, 7, 8 and 10.
It is the same three parts, and `mapM_` takes it the way `map` takes `unpack`.
`mapM_` is not `map`, and what it does with what it is handed belongs with the border between what runs and what becomes hardware rather than here.

## The functions we wrote go in the same slot

Nothing about the argument position prefers library functions.
`countBoard` is ours, and handing it over reads exactly as `unpack` did:

```
clashi> :t map countBoard
map countBoard :: Vec n Board -> Vec n Counts
```

The difference between calling `countBoard` and passing it is the argument after it and nothing else.
`countBoard b` is a `Counts`, and `countBoard` on its own is the function, which is the value `map` wants.

`foldl1` is the third of chapter 4's three, and it takes the way to combine two things:

```
clashi> :i foldl1
foldl1 :: (a -> a -> a) -> Vec (n + 1) a -> a
  	-- Defined in ‘Clash.Sized.Vector’
```

Two of something and one of the same something, which `addCounts` is, and a vector with at least one element in it, which is what `n + 1` says.
`foldl1 addCounts` is therefore the whole of chapter 4's summation with nothing to sum yet:

```
clashi> :t foldl1 addCounts
foldl1 addCounts :: Vec (n + 1) Counts -> Counts
```

How the seven additions that reduce eight boards are arranged, in a chain or in a tree, is a question about `fold` rather than about handing a function over, and this page does not settle it.

Chapter 5's whole generation is one more of these:

```haskell
{{#include ../../../code/src/Chapters/Ch05.hs:step}}
```

`zipWith (zipWith nextCell)` is `addCounts`'s shape with chapter 2's rule in the place where `(+)` was, and it works for the same reason: `nextCell` takes a cell and a count and gives back a cell, which is what `zipWith`'s first argument has to be.
Chapter 6's `fmap step boards` hands `step` over in the same way, to something that applies it inside a `Signal` rather than inside a vector, and what `fmap` itself is takes an answer this page does not have.

## `mealy` takes the entire loop

Chapter 7 asked what `mealy` wanted before using it, and one of its arguments is a type with arrows in it:

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
  	-- Defined in ‘Clash.Explicit.Mealy’
```

`(s -> i -> (s, o))` is `zipWith`'s first argument again, in parentheses for the same reason and in an argument position for the same reason.
What lands there in chapter 7 is `lifeT`, a function of a board and a `Maybe Board` that gives back [a pair](pattern-matching.md#the-thing-after-the-word-case) of boards.
That function is the entire path from the register's output round to its input, handed over as one value.

Chapter 6's `register` took the signal that would arrive at its input, and the loop was closed by a binding that mentions itself.
`mealy` takes the logic that makes that signal instead, and closes the loop itself.
Nothing inside `mealy` knows that there is a board in it, an eight by eight board, or a `Maybe` on its input; it knows that something arrives, that a function turns it and the state into a new state and an output, and that a register goes between.
That is `map`'s arrangement with a clock in it.

## What it costs

A description built this way has no fixed shape in the source to point at, and the netlist takes its shape only when the arguments land.
`map` on its own instantiates nothing and is not a circuit.
`map countBoard` is one `countBoard` per board, each of them sixty-four copies of an `if`, and how many boards there are is not in it at all.
The number arrives from somewhere else entirely:

```
clashi> :t map countBoard (neighbourBoards glider)
map countBoard (neighbourBoards glider) :: Vec 8 Counts
```

The eight in that answer is not written in `map`, in `countBoard` or at the use site.
It comes from `neighbourBoards`, which is where somebody decided there were eight directions, and it reaches `map` as part of the type of a value.
A `for … generate` says how many times in its own header, where it can be read; this says it in the type of an argument, and reading it means following the argument back.

The names do not survive either, and chapter 9 shows exactly how far.
The generated VHDL is full of `zipWith_3`, `zipWith_0` and `fun_0`, all of them Clash's names for the instances that a passed function came to, and `addCounts` is not in the file.
That is why chapter 9 has to mark `step` before a boundary appears in the output at all: a hierarchy of higher-order descriptions is not a hierarchy of components, and nothing preserves the correspondence unless it is asked for.

The sharpest edge is that a function handed over one argument short is not an error.
Chapter 2's rule takes a cell and a count, and handing it to `map` as though it took one thing has a perfectly good type:

```
clashi> :t map nextCell
map nextCell :: Vec n Bool -> Vec n (Unsigned 4 -> Bool)
```

A vector of functions is a type like any other, nothing about that expression is ill formed, and it is not what anybody wanted.
What is rejected is the moment such a value meets something that wants cells, and where the whole mistake sits inside one expression the compiler is direct about it.
Handing `render` a board built with `map (map nextCell)` is `[GHC-83865]`, `Couldn't match type ‘Unsigned 4 -> Bool’ with ‘Bool’`, and under it the words `Probable cause: ‘nextCell’ is applied to too few arguments`.
It can say that because it has three lines of context to walk out through, from `nextCell` to the inner `map` to `render`, all of them in the expression that was typed.

Split the same mistake across two definitions and there is nothing to walk.
`map nextCell` on its own is a legal definition with a legal type, so what arrives at the use site is a wrong type rather than a missing argument, and it arrives somewhere the count is never mentioned.
A `for … generate` cannot be given a component with a port left off, so this is a mistake with no counterpart in the language the reader came from.

What the whole arrangement buys is on the other side of the same coin.
Four hundred and forty-eight four-bit additions are one `+`, sixty-four copies of the cell rule are one `nextCell`, the eight moved boards are four shifts and a lambda, and none of those lines mentions eight, sixty-four or four hundred and forty-eight.
That is also why chapter 12 changes the size of the board without rewriting any of them.

## Where you met this

- Chapter 3, [A board, and a picture](../b/03-a-board.md): `map unpack`, the first function in the book handed to a function.
- Chapter 4, [Neighbours, by moving the whole board](../b/04-neighbours.md): `map`, `zipWith` and `foldl1`, the lambda in `shiftW`, and one `+` describing sixty-four adders.
- Chapter 5, [A generation](../b/05-a-generation.md): `zipWith (zipWith nextCell)`, the same shape with the rule in it.
- Chapter 6, [It runs by itself](../b/06-it-runs.md): `fmap step boards`, and the lambda typed at the prompt.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `mealy`, and the loop handed to it as an argument.
- Chapter 9, [An entity](../b/09-an-entity.md): the `for … generate` blocks these lines became, and the names they came out under.
