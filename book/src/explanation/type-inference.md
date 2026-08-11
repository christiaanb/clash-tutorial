# How the compiler knows a type you did not write

Chapter 3's `fromRows` is one line, and the chapter said in as many words that one of the two names in it is settled from somewhere else:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:from-rows}}
```

Nothing at the point where `unpack` is written says that the answer should be eight `Bool`s.
`fromRows`'s signature says that the result is a `Board`, and the chapter's claim was that this is enough for the compiler to know which unpacking is meant.

A chapter later there is a definition with no signature anywhere in it at all:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:render-counts}}
```

`row` and `digit` are the fourth and fifth definitions in the reader's file with no type written on them, after the two inside `render` and the one inside `countBoard`, and every chapter from here adds more.
They have types all the same, as fixed and as checked as `renderCounts`'s.
This page is what works them out, and why the tutorial goes on writing top-level signatures that the same machinery would supply for nothing.

## The reading that does not survive

In VHDL nothing is used before it is declared.
A signal has a type because a line near the top of the architecture gave it one, and the compiler's job is to check the uses against that line rather than to have an opinion of its own.
A reader carrying that habit over has two ways to account for a definition with no declaration, and both are wrong in a way that costs something later.

The first is that what is left out gets a default.
Every language that has allowed a declaration to be omitted has had one, and it is always a general-purpose type: an integer of the machine's width, or a real.
Under that reading the `1` in chapter 4's `toCount` is a machine integer.
It is four bits wide, and no default produces four.

The second is that there is no type until something runs.
That reading lasts about a minute at the prompt, because a `Vec 7` handed to something that wants a `Vec 8` is rejected before anything runs, and [the length is part of the type](vec-and-lists.md#the-length-is-in-one-of-them-and-not-the-other) rather than a property of a value in memory.

The idea neither reading has is that a type can be worked out after the fact, from the uses, with the information travelling in whichever direction it happens to be travelling.
Including backwards: out of a signature written on the line above, and into an expression that has no opinion of its own.

## Solving, not guessing

`map unpack` is the whole of `fromRows`'s right hand side.
Ask what it is on its own, with no signature over it:

```
clashi> :t map unpack
map unpack :: BitPack b => Vec n (BitVector (BitSize b)) -> Vec n b
```

Two lowercase names in that answer, `n` and `b`, and nothing has decided either.
Chapter 3 then wrote a line above it:

```
clashi> :i fromRows
fromRows :: Vec 8 (BitVector 8) -> Board
  	-- Defined at src/Example/Project.hs:14:1
```

Matching those two types against each other is the whole of what the compiler did.
`Vec n (BitVector (BitSize b))` has to be `Vec 8 (BitVector 8)`, so `n` is 8.
`Vec n b` has to be `Board`, and `Board` is `Vec 8 (Vec 8 Bool)`, so `b` is `Vec 8 Bool`.
Those two conclusions then have to agree with each other: `BitSize (Vec 8 Bool)` is 8, which is the width the argument side asked for, so they do.

Naming that as a procedure is worth the sentence it takes, because the rest of this page is consequences of it.
The compiler walks the definition and writes down an equation wherever two types have to be the same, then solves the set of them.
One solution and the definition is accepted.
No solution and it is rejected, quoting the equation that failed.
A variable that no equation constrains is left standing as a variable, which is a case with a section of its own below.
Nothing in that is a guess, and nothing in it is a default.

## The information runs backwards

`unpack` is the sharpest case in the book, because its argument says nothing about its answer:

```
clashi> :t unpack 0b1110_0000
unpack 0b1110_0000 :: BitPack a => a
```

Eight bits in hand and the result is still a variable.
Say what the result is and the same eight bits come back as three unrelated values:

```
clashi> unpack 0b1110_0000 :: Vec 8 Bool
True :> True :> True :> False :> False :> False :> False :> False :> Nil
clashi> unpack 0b1110_0000 :: Unsigned 8
224
clashi> unpack 0b1110_0000 :: Signed 8
-32
```

That is the third row of the glider, `###.....`, read three ways.
The bits are identical in all three; what differs is what was asked for, and `unpack` did as it was told each time.

This is the one place where the VHDL habit is not merely absent but inverted.
There, a conversion names its own target: `to_integer(x)`, `signed(x)`, `unsigned(x)`, one function per destination, chosen at the point of use, and the type of the result follows from the function that was picked.
Here there is one function and the destination picks it.
`unpack` in `fromRows` is the eight-`Bool` one because the line above ends in `-> Board`, and the same three letters would be the `Unsigned 8` conversion under a signature that ended differently, with nothing inside `fromRows` changed.

## A literal has no type of its own

Chapter 4 turns booleans into numbers, and writes the numbers as `1` and `0`:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:count-board}}
```

Nothing in `toCount` says how wide those are, and no literal anywhere says how wide it is:

```
clashi> :t 1
1 :: Num a => a
```

`toCount` itself, typed at the prompt as [a function with no name](higher-order.md#a-function-with-no-name) so that it has nothing above it to serve, is the same variable with a `Bool` put in front of it:

```
clashi> :t (\x -> if x then 1 else 0)
(\x -> if x then 1 else 0) :: Num a => Bool -> a
```

and the whole of `countBoard`'s body still has not settled it, two `map`s and a board later:

```
clashi> :t map (map (\x -> if x then 1 else 0)) glider
map (map (\x -> if x then 1 else 0)) glider
  :: Num b => Vec 8 (Vec 8 b)
```

Eight rows of eight of something numeric, and the signature is what says which:

```
clashi> :t countBoard glider
countBoard glider :: Counts
```

`Counts` is `Vec 8 (Vec 8 (Unsigned 4))`, so `b` is `Unsigned 4`, and the two literals in `toCount` are four bits wide.
Neither literal mentions a width and `countBoard`'s signature does not mention one either.
The four is in `Counts`, which chapter 4 wrote at the top of the chapter before anything used it, and it reaches those literals through `countBoard`'s signature and two `map`s, none of which say four.
The four hundred and forty-eight additions chapter 4 counted take their width from the same place.

`digit` is the case where the information arrives from both ends at once.
`row` maps it across a row of `Counts`, so its argument is an `Unsigned 4`; `renderCounts` promises a `String`, which is a list of `Char`, so its result is a `Char`.
Between those two ends is a conversion that names neither:

```
clashi> :i numConvert
numConvert :: NumConvert a b => a -> b
  	-- Defined in ‘Clash.Class.NumConvert.Internal.NumConvert’
```

`a` and `b`, both variables, and nothing inside `numConvert n` to fix `b`.
What fixes it is the next thing out:

```
clashi> :i intToDigit
intToDigit :: Int -> Char 	-- Defined in ‘GHC.Internal.Show’
```

`intToDigit` wants an `Int`, so `numConvert`'s target is `Int`, so the conversion in question is the one from a four-bit number to an `Int`, and that is the conversion Clash checks at compile time for anything lost.
Chapter 4 worked out the count in the top left corner by hand and got one.
Here is `digit` doing it, with each of the types in it settled and not one of them written down:

```
clashi> intToDigit (numConvert (head (head (neighbourCounts glider))))
'1'
```

## When nothing forces a choice

Sometimes nothing decides, and nothing has to.
Chapter 7 made a signal out of seven values and the prompt answered with a variable still in it:

```
clashi> :t fromList [Nothing, Nothing, Nothing, Just blinker, Nothing, Nothing, Nothing]
fromList [Nothing, Nothing, Nothing, Just blinker, Nothing, Nothing, Nothing]
  :: Signal dom (Maybe Board)
```

`Maybe Board` is settled, because `Just blinker` is in the list and `blinker` is a board.
`dom` is not, because nothing in that expression is about a clock, and the prompt reports the variable rather than choosing a domain.
It is right to: the expression really is every domain's version of that signal, and one of the three outcomes of solving a set of equations is that a variable survives it.
That one was closed on the next line of the chapter, where the signal was handed to `life systemClockGen resetGen enableGen` and `systemClockGen`'s `System` filled it in.

An open variable in the middle of a design is not something this tutorial produces, and the reason is the subject of the next section.
A signature with no variables in it closes everything underneath it, and no signature in this book has a variable in it until chapter 12.

## Why the signatures are written anyway

Not one definition on this page needed the signature it has, and every top-level definition in the reader's file has one, on the tutorial's instruction, from chapter 1 onwards.
Two things are bought with that line, and the second is the one that shows up within an afternoon.

The first is that a signature is the port list.
`neighbourCounts :: Board -> Counts` is a statement about the design, made in one place, that can be read without reading anything else.
An inferred type is a conclusion drawn from a body, and a design whose interfaces can only be read off its implementations has no interfaces, only implementations.

The second is that a signature decides where a mistake is reported.
Make a real slip in `digit` and leave out `numConvert`, so that the line reads `digit n = intToDigit n`.
The compiler rejects the file, and the line it points at is this one:

```haskell
renderCounts cs = unlines (toList (map row cs))
```

three lines above the mistake, with the caret under `cs`, `Couldn't match type ‘Unsigned 4’ with ‘Int’`, and `Expected: Vec 8 (Vec 8 Int)` over `Actual: Counts`.

Every word of that is correct, which is the problem.
With no signature on `digit` its body is what defines it, its body says `Int -> Char`, and `row` and `renderCounts` are then obliged to agree with that.
The first place they cannot is the board of counts arriving at `renderCounts`, so `Counts` is named as the type that is wrong and a board of `Int` is named as the type that was wanted.
The reader wrote `Counts`, believes in `Counts`, and is being told it does not fit.

Write one line above the definition, `digit :: Unsigned 4 -> Char`, make the same mistake, and the report lands on the mistake: `Couldn't match expected type ‘Int’ with actual type ‘Unsigned 4’`, under `In the first argument of ‘intToDigit’, namely ‘n’`, under `In an equation for ‘digit’`.

A signature is a claim, and a claim gives the compiler something to check the body against, so a disagreement is found in the body.
Without one there is no claim, the body is the truth, and the disagreement surfaces at the first place that truth fails to fit something else.

The `where` bindings are where the tutorial takes the other side of the same trade, and it is a trade rather than an oversight.
`row`, `digit`, `toCount` and `cell` are each within four lines of the signature that forces them, none of them can be called from anywhere else, and a signature on one would repeat what the line above it has already decided.
A top-level signature is worth its line because the distance it covers is unbounded; a local one usually is not.

## What it costs

The cost is the distance, and in the reader's file the distance was three lines because `renderCounts` is five lines long.
Nothing bounds it in general.
Split the same mistake across two top-level definitions with no signatures and the wrong type is inferred, correctly, in one file and reported in another, at a use site that has nothing wrong with it.
The error will name a type the reader wrote deliberately as the thing that does not fit, because from where the compiler is standing it is.
This is the counterpart of what [a function handed over one argument short](higher-order.md#what-it-costs) does, and it has the same root: an expression can be well typed, and wrong, and there is nothing at the site of the mistake for a compiler to object to.

What is bought is that a width is stated in one place and reaches everywhere it is needed.
The four in `Counts` settles two literals, four hundred and forty-eight adders and the argument type of `digit`, none of which mention it.
The eight in `Board` settles which `unpack` runs, in a definition that names no type at all.
Chapter 12 then takes the eight out of both of those types and leaves the four where it is, and `countBoard`'s body, `toCount` and its two literals included, does not change a character: it never said what it was, so there was nothing in it to change.

## Where you met this

- Chapter 3, [A board, and a picture](../b/03-a-board.md): `unpack` in `fromRows`, decided by a signature one line above, and the two bindings inside `render` with no signature on them.
- Chapter 4, [Neighbours, by moving the whole board](../b/04-neighbours.md): the literals in `toCount`, the width they take from `Counts`, and `numConvert`'s target chosen by `intToDigit`.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `fromList` reported with `dom` still open, and closed a line later.
