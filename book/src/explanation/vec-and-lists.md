# A Vec is not a list

Chapter 3 wrote the seed as a picture of itself:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:glider}}
```

Eight numbers, eight `:>` and a `Nil`, and the chapter explained only the numbers.
Then it asked for the first row, and the other two came back:

```
clashi> head glider
False :> True :> False :> False :> False :> False :> False :> False :> Nil
```

Chapter 6 printed a collection of a different shape.
`sampleN 5` gave five boards, and what the prompt said about them was this:

```
clashi> :t sampleN 5 (life systemClockGen resetGen enableGen)
sampleN 5 (life systemClockGen resetGen enableGen) :: [Board]
```

Square brackets, no `:>` anywhere, and chapter 7 typed seven values inside brackets of its own and handed them to something called `fromList`.
Two notations have been in use since chapter 3, and this page is what each of them is.

## The reading that does not survive

The economical assumption is that there is one sequence type here with two ways of writing it down, and the reason it is wrong is not that it costs an error message.
It is that the reader who holds it will go looking for `map` and find the wrong `map`.
Every Haskell resource written outside Clash describes `map :: (a -> b) -> [a] -> [b]`, over the square bracket type, and the `map` in chapter 3's `fromRows` is a different function with the same name.
The answer found by searching will look right, will be right about the language, and will not compile in the file the reader has open.
Keeping self study from quietly contradicting the tutorial is most of what this page is for.

The VHDL habit that transfers is the array, and it transfers well.
`array (0 to 7) of bit` is a length fixed where it is written and `array (natural range <>) of bit` is a length fixed at elaboration, and there is no synthesisable array in VHDL whose length is settled while the circuit runs.
`Vec 8 Bool` is the first of those and `Vec n Bool` is the second, so the vector is the familiar thing.
The square bracket type is the unfamiliar one, and its distinguishing property is that it never becomes hardware at all.

## `:>` and `Nil` are data

Ask the compiler what a `Vec` is, and among what it prints are the two ways of making one:

```
data Vec a b where
  Nil :: Vec 0 b
  Cons :: b -> Vec n b -> Vec (n + 1) b
```

`Nil` is a vector of nothing, of length zero.
`Cons` takes one element and a vector, and gives back a vector one longer.
`:>` is a second name for `Cons`, declared so that it may be written between its two arguments rather than in front of them, and `:i (:>)` reports its type as `a -> Vec n a -> Vec (n + 1) a`.

Those are constructors, which makes them the same kind of thing as `Just`: data, not syntax, usable to build a value and usable as [a pattern](pattern-matching.md#a-pattern-is-a-shape-with-holes) to take one apart.
Nothing in the language knows that eight of them in a row is a special shape.

`:i (:>)` also reports `infixr 5 :>`, and that is what keeps the seed readable.
Associating to the right means `glider`'s chain groups as one number and then everything after it:

```
0b0100_0000 :> (0b0010_0000 :> ( ... :> (0b0000_0000 :> Nil)))
```

which is the only grouping that could typecheck, because `:>` wants a vector on its right and never on its left.
Eight of them therefore need no parentheses at all, and the parentheses that are in `glider` are doing something else: application binds tighter than any operator, so without them `fromRows 0b0100_0000 :> ...` would apply `fromRows` to the first row alone.

Counting the `:>` is counting the length, and the compiler does that counting.
Deleting one row from the seed is rejected before anything runs, with `[GHC-83865]` and a complaint that it could not match 1 with 2.
Those small numbers are worth a moment, because the row deleted to get them was the fourth of eight.
The mismatch is found at the tail, where the last `:>` needed two elements after it and had one, so the message points at the bottom of the chain rather than at the row that went missing.

## The length is in one of them and not the other

Chapter 3 said that a length is in the type and it is checked, and the two types are where that difference lives.
`Vec 8 Bool` has the eight in it, and `[Bool]` has nothing in the corresponding position, because there is no corresponding position.
A `[Bool]` is some number of booleans, and its type is the same type whether it holds three of them or three thousand.

The case of that worth knowing is `String`, because the reader has been holding a list since chapter 3 without seeing a bracket: `:i String` prints `type String = [Char]`.
A string is a list of characters, which is why `render`'s type is `Board -> String` and why that signature has a vector on one side and a list on the other.

The reason the hardware side gets the checked one is that a wire count is not allowed to be a surprise.
A `Vec 8 Bool` is eight wires, and it is eight wires while the program is still being compiled, which is what lets chapter 4 describe four hundred and forty-eight additions without anything in the source counting them.
The cost runs in the other direction, and it is absolute: a `Vec`'s length can never depend on data the circuit computes while it runs.
That is a cannot rather than a not currently, and it is the same cannot as a VHDL port whose width is decided by a signal.

Telling the two apart in what the prompt prints needs nothing beyond this.
Square brackets are a list, whatever is between them: chapter 6's `[Board]`, and the seven values chapter 7 typed for `fromList`.
A `Vec` prints as the constructors it is made of, a chain of `:>` ending in `Nil`, which is why one row of a board costs seventy-four characters at the prompt and why chapter 3 wrote `render` before it wrote anything that moves.

## The bridges, and the one that is not one

`toList` is the crossing the book uses most, and it is in the one block chapter 3 said had nothing in it to learn:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:render}}
```

`toList :: Vec n a -> [a]` keeps the elements and drops the length from the type.
`render` crosses nine times for every board it prints: once per row, turning eight characters into a `String`, and once for the eight rows themselves, so that `unlines` has a list to put newlines between.
`unlines` is why the crossing has to happen at all, and chapter 4's `renderCounts` does the same nine crossings for the same reason.

Sampling is a crossing of the same direction with a different reason.
`sampleN` takes an ordinary `Int` and gives back a list, and neither of those is careless: how many cycles are looked at is a question about the simulation rather than about the circuit, and a number the circuit never sees has no reason to be in a type.
Chapter 6's `[Board]` is that decision showing, and it is why a signal has to be cut to a length before a board can be printed.

`fromList` looks like the return trip, and it is not one:

```
clashi> :t fromList [Nothing, Nothing, Nothing, Just blinker, Nothing, Nothing, Nothing]
fromList [Nothing, Nothing, Nothing, Just blinker, Nothing, Nothing, Nothing]
  :: Signal dom (Maybe Board)
```

Its type carries a requirement of the kind chapter 6 said the compiler settles on its own, and what is left after it is `[a] -> Signal dom a`: the list becomes a signal, and never becomes a vector.
The two names cross two different borders: `toList` leaves the vector, and `fromList` enters the signal, with the list sitting outside both of them as the notation the prompt is comfortable in.
Nothing in this tutorial goes from a list to a `Vec`, and the length is the reason: a list's length is found by walking it, and a `Vec`'s has to be known before anything walks anywhere.
A crossing in that direction has to be told how long the result is, and no design in the book has a use for one.

## Which `map` is this

One import line settles it.
The project chapter 1 generates asks for `NoImplicitPrelude`, which turns off the standard prelude that Haskell would otherwise supply on its own, so every name in the file arrives from something written at the top of it.
The line that brings in almost all of them is `import Clash.Explicit.Prelude`, the file's first import from chapter 1 until chapter 13 changes it.

What that module does with the names it shares with the standard prelude is to keep them for the vector functions.
`map`, `head`, `zipWith` and `foldl1` are the vector ones, all four of which the reader has used, and the list functions of those names are not in scope under them.
Names the vector library does not want are passed through untouched, and `unlines` is one: `:i unlines` reports it as coming from the standard library, in the same session where `:i map` reports `Clash.Sized.Vector`.
So `render` calls two libraries in one expression and nothing in the source says which is which.

Handing `map` a list is therefore an error rather than a different overload, and it is `[GHC-83865]` again, the code the seed with a row missing produced: `Couldn't match expected type: Vec n b`, with the list named underneath it as the actual one.

A name is borrowed one at a time when the prelude does not have it, which is chapter 4's second import:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:import-data-char}}
```

The parenthesised list says which names to take from `Data.Char`, and taking one leaves everything else in that module alone.
`intToDigit` is not in the standard prelude either, so a Haskell program with no Clash in it would need the same line, in the same shape.

## What it costs

The vector functions arriving under the list functions' names is a decision with a price, and the price is not paid while writing the tutorial.
It is paid the first time the reader searches for something.
An answer about `zipWith` will be about the list one, will not say so, and will differ from the vector one in the place that matters most.
The list function takes two lengths that need not agree and produces the shorter of them; `zipWith` on vectors has `Vec n a` and `Vec n b` in its type, one length written twice, and two vectors of different lengths are rejected rather than shortened.
Reading `[a]` as the vector is the habit to unlearn, and it is worth unlearning early, because the two libraries agree about so much else that a disagreement is easy to miss.

What is bought with it is that there is one vocabulary rather than two.
`map` over a board and `map` over a row are the same word, `foldl1` over eight boards of counts reads the way the standard function of that name reads, and a reader coming the other way, from Haskell to Clash, has almost nothing to relearn.
The tutorial pays the price knowingly and does not pay it twice: `toList` appears in two definitions in the reader's file, both of them printing, and everything the design is made of is vectors from end to end.

## Where you met this

- Chapter 3, [A board, and a picture](../b/03-a-board.md): `:>` and `Nil` in the seed, `head glider` printing a chain, and `toList` in `render`.
- Chapter 4, [Neighbours, by moving the whole board](../b/04-neighbours.md): the same crossings in `renderCounts`, and the import list that borrows `intToDigit`.
- Chapter 6, [It runs by itself](../b/06-it-runs.md): `sampleN 5`, and the `[Board]` it has.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): seven values in square brackets, and `fromList` making a signal out of them.
