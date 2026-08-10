# Why a two-input function has three arrows

Chapter 1 asked the compiler what `plus` was:

```
clashi> :i plus
plus :: Signed 8 -> Signed 8 -> Signed 8
  	-- Defined at src/Example/Project.hs:6:1
```

Two numbers in and one number out, written with three arrows, and nothing in the type saying which side the result is on.
Then the chapter supplied one of the two arguments, and the compiler did not object:

```
clashi> :t plus 3
plus 3 :: Signed 8 -> Signed 8
```

`plus 3` is a legal thing to have, chapter 1 said, and left it there.
This page is why it is legal, and why the type is a chain of arrows rather than something shaped like a port list.

## The reading that does not survive

A function in VHDL is declared in one piece: a parameter list, a return type, and a body that ends in `return`.
The parameters are named and declared together, and there is no expression anywhere in the language that stands for the function with some of its parameters bound and the rest still wanted.
Read `Signed 8 -> Signed 8 -> Signed 8` in that spirit and the arrows are punctuation between parameters, with a convention that the last one is the result.

That reading gets chapter 1 right, and then fails on almost everything after it.
`plus 3` is a call with an argument missing.
`fromRows = map unpack`, in chapter 3, is a function defined without naming the thing it works on.
`life8 = life glider`, in chapter 12, supplies one of five arguments.
`life8 = exposeClockResetEnable (life glider)`, in chapter 13, supplies one and then hands what is left to something else.
All four are errors under the port list reading, and all four compile.

## One argument at a time

The rule is the whole of this page: every function takes exactly one argument and gives back exactly one result.

`Signed 8 -> Signed 8 -> Signed 8` is two of those in a chain, because the arrow groups to the right:

```
Signed 8 -> (Signed 8 -> Signed 8)
```

`plus` takes a `Signed 8`, and what it gives back is a function that takes a `Signed 8` and gives back a `Signed 8`.
Application groups the other way, to the left, so `plus 3 5` is:

```
(plus 3) 5
```

Two applications, not one call with two operands.
`plus 3` is the value in between, and the type wrote it down before we asked: it is everything after the first arrow.

Chapter 1's sentence, that `plus`'s type is its port list, is still the right thing to read off a use that supplies every argument.
It is the answer rather than the mechanism, and the mechanism is what lets a use supply fewer.

## What `plus 3` is

`plus` is a component with two inputs and one output.
`plus 3` is that component with one input held at 3, and one input and one output left over, which is what `Signed 8 -> Signed 8` says.
The 3 is inside it.
There is no half filled port map sitting somewhere waiting to be completed, and nothing to keep in step with anything: the value is captured, and what remains is a thing whose type is its remaining ports.

Nothing has been built.
At the prompt, `plus 3` is a value being evaluated rather than logic being elaborated, in the same way that chapter 5's four applications of `step` cost four copies of the logic in a design and four times almost nothing at the prompt.
Where a partial application does reach the VHDL generator, the arguments already supplied are constants in the generated logic and the ones still missing are its ports.

## A definition is an equation

```haskell
{{#include ../../../code/src/Chapters/Ch01.hs:definitions}}
```

Left of the `=` is the name and then its arguments, in order.
Right of the `=` is what comes out.
There is no `return`, and there is nothing for one to do, because the right hand side is not a value the body computes and then reports: it is the value.

Two names to the left is shorthand for the chain the type describes: one argument, and then the other.
How few of those names have to be written down at all is the next section.

## Arguments you can leave off both sides

Chapter 3 defines `fromRows` without mentioning a row:

```haskell
{{#include ../../../code/src/Chapters/Ch03.hs:from-rows}}
```

Written the other way it is `fromRows rows = map unpack rows`, and the two definitions are the same definition.
The rule is mechanical: if the same name is the last thing on both sides of the `=`, delete it from both.
It is legal because `map unpack` is already a function of one argument, so applying it to `rows` and then handing `rows` in is a round trip that says nothing.

Chapter 12's `life8 = life glider` is the same rule with four names deleted instead of one, and chapter 13's `life8 = exposeClockResetEnable (life glider)` is the same rule again with a function wrapped around the result.
The style has a name, point free, and the name is worth having because it is what other people's Clash is written in and what an answer to a question you search for will use.

The cost is a name.
`fromRows = map unpack` says what the function is; `fromRows rows = map unpack rows` says what it does to something, and the second is easier for a reader who has not yet internalised the arrow rule.
The tutorial writes both, per definition, and nothing in the type distinguishes them: chapter 3's `:i fromRows` prints `Vec 8 (BitVector 8) -> Board` either way.

## Four names, one signature

Chapter 4 declares four functions on one line:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:shifts}}
```

Those are four separate functions of one argument each, all of type `Board -> Board`, and the comma is shorthand for writing the signature four times.
No chain is involved and nothing is shared.
It is here because a run of names is the other thing a signature line can carry, and reading those commas as one more way of separating arguments is an easy mistake to make once.

## A prime is part of the name

Chapter 8's `lifeT` has a `where` binding called `st'` beside its argument `st`, and chapter 10 calls `outputVerifier'`.
The `'` is an ordinary character that a name may contain after its first character.
It is not an operator and it does nothing: `st'` is one name, three characters long.

What it means is a convention, and the convention is a variant of the name without it.
`st'` is the next state, beside `st`, the current one.
`outputVerifier'` is a variant of a function called `outputVerifier`, and currying is how the variant is made: `outputVerifier` takes two clocks, one the test bench is synchronised to and one the circuit under test is, and `outputVerifier'` is `outputVerifier` with the same clock handed to both.
That is why chapter 10's `:i outputVerifier'` shows one `Clock dom` where the unprimed function has two.

One thing that is not this: the `'life` in chapter 10's annotation carries its quote in front of the name rather than after it, and that is a different device with a different job.

## What it costs

An argument left off is a value rather than a complaint.
A VHDL call that names too few actuals is wrong where it is written, and the compiler says so there.
Here it typechecks, produces a function, and the objection arrives wherever that function is finally used, which may be a different definition several lines away.
`map unpack` and a `fromRows` that has lost its argument are the same shape, and only the types around them tell the two apart.

Position is all an application has.
Where two arguments have different types a swap is caught at once, which is what chapter 5 says about handing `zipWith` the counts before the board.
Where two arguments have the same type a swap typechecks, and then the circuit is wrong rather than rejected.
A port map names its ports and can therefore be written in any order; an application cannot, and nothing in the notation will help.

Both costs are paid for something specific.
Chapter 4 describes four hundred and forty-eight additions by handing functions to functions, and `map countBoard`, `foldl1 addCounts` and `addCounts = zipWith (zipWith (+))` are each a function with some of its arguments supplied and the rest left for something else to fill.
None of those lines can be written at all without the rule this page describes.

## Where you met this

- Chapter 1, [The instrument](../b/01-the-instrument.md): `:i plus`, `:t plus 3`, and a type read as a port list.
- Chapter 3, [A board, and a picture](../b/03-a-board.md): `fromRows = map unpack`, and `unpack` handed over with none of its arguments supplied.
- Chapter 4, [Neighbours, by moving the whole board](../b/04-neighbours.md): four shift functions under one signature.
- Chapters 8 and 10, [More than valid](../b/08-more-than-valid.md) and [A test bench that leaves Haskell](../b/10-a-test-bench.md): `st'` and `outputVerifier'`.
- Chapter 13, [What the rest of the world writes](../b/13-hidden.md): `exposeClockResetEnable (life glider)`, in front of the argument it already had.
