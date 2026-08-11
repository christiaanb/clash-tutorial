# Two worlds of numbers

Chapter 4 moved the whole board rather than indexing into it, and before writing anything that did so it asked what to move it with:

```
clashi> :i rotateLeftS
rotateLeftS :: KnownNat n => Vec n a -> SNat d -> Vec n a
  	-- Defined in ‘Clash.Sized.Vector’
```

A vector in, a vector of the same length out, and between them the distance to move by, which is an `SNat d` rather than a number.
The chapter said what to write there and pre-flagged the one mistake it invites: the distance of one is `d1`, and writing `1` instead is answered by the compiler saying that `SNat` is not a `Num`, which is true and no help at all.

Three numbers have been on screen since chapter 1 and nothing has said that they are not the same kind of thing.
The `8` in `plus :: Signed 8 -> Signed 8 -> Signed 8` is one, the `3` in `plus 3 5` is another, and the `1` that has to be written `d1` is the third.
Two of those live in one world and one lives in the other, and the grouping is not the one a VHDL reader would pick.

## The reading that does not survive

VHDL has one integer world.
A generic is a `natural`, a port can be an `integer`, `natural range <>` is what leaves an array's bounds to whoever instantiates it, and every one of those numbers is a value: the tool adds them, compares them, prints them in a message, and the same `8` can be a generic on one line and an index on the next.
VHDL does draw a line near this one, between what is settled at elaboration and what arrives while the design runs, but that line is about when a number is known rather than about what kind of thing the number is.

Carried over, that reading makes the `8` in `Vec 8` a parameter that happens to be written inside the type, `d1` a spelling of `1` that one library function is fussy about, and "`SNat` is not a `Num`" a missing conversion, to be fixed by finding the function that converts.
Nothing in the library converts a value into an `SNat`, and that is not an omission: what such a function would have to do, and why nobody wants it, is the subject of the section on `d1` below.

The reading survives eleven chapters, because until chapter 12 every number in a type in the reader's file is a literal that never moves: the `8` in `Board`, the `4` in `Counts` and the `1` in `d1`.
Chapter 12 is where it breaks.
The eight comes out of the types and becomes an `n`, every number on a wire stays exactly where it was, and the edit each of those needed has nothing in common with the other.

## The eight is in the type, and the type is not a number

Chapter 3 asked what `Board` was, and the answer had a line in it above the one the chapter had written:

```
clashi> :i Board
type Board :: Type
type Board = Vec 8 (Vec 8 Bool)
  	-- Defined at src/Example/Project.hs:11:1
```

`type Board :: Type` is a statement about `Board` itself rather than about any board: whatever else it is, it is a type, which is the kind of thing a value can have.
The prompt answers that question on its own too, and `:k` is how it is asked, standing to a type as `:t` stands to an expression:

```
clashi> :k Vec
Vec :: Nat -> Type -> Type
clashi> :k Signed
Signed :: Nat -> Type
```

Neither answer is `Type`, and the gap between those two lines and the one above them is the whole of what this page is about.
`Vec` is not a type: it is something that becomes one when it is given a number and a type, and `Signed` becomes one when it is given a number alone.
`Nat` is what the kind of such a number is called, and every number this page calls a type-level number is one with that kind.

Giving one of the two and not the other does what it does everywhere else in this language:

```
clashi> :k Vec 8
Vec 8 :: Type -> Type
```

`Vec 8` is not a type yet, and it is short of the same argument [one argument at a time](currying.md#one-argument-at-a-time) leaves a function short of.

Chapter 1 had both worlds on one line and said nothing about it, which was the right decision at the time: `Signed 8` is eight bits of wire, and the `3` and the `5` in `plus 3 5` are values those wires can carry.
The eight is checked while the design is compiled and is not represented at run time at all.
What remains of it is the wires it fixed the number of, and chapter 12 printed them: `cells : out std_logic_vector(63 downto 0)` in one entity and `255 downto 0` in the other, with nothing in either file that could be asked how wide a board is.

Being checked is visible from the prompt.
Annotate chapter 3's seed as a board of seven rows and the failure is a type error whose two types are numbers: `[GHC-83865]`, `Couldn't match type ‘8’ with ‘7’`, over `Expected: Vec 7 (Vec 8 Bool)` and `Actual: Board`.
No value took part in that, and none had to: a length is [in the type](vec-and-lists.md#the-length-is-in-one-of-them-and-not-the-other), so disagreeing about a length is two types disagreeing.

## `d1` is a value whose type is the number

The other world is where `rotateLeftS`'s second argument has to come from, and `d1` is how something crosses:

```
clashi> :t d1
d1 :: SNat 1
```

That is the bridge in one line.
`d1` is a value, so it can be passed to a function; its type is `SNat 1`, so the number it carries is in a type where the compiler can use it.

```
clashi> :i SNat
type role SNat nominal
type SNat :: Nat -> Type
data SNat n where
  SNat :: KnownNat n => SNat n
  	-- Defined in ‘Clash.Promoted.Nat’
instance ShowX (SNat n) -- Defined in ‘Clash.Promoted.Nat’
instance Lift (SNat n) -- Defined in ‘Clash.Promoted.Nat’
instance Show (SNat n) -- Defined in ‘Clash.Promoted.Nat’
```

One constructor, and it has no fields.
`SNat 1` is a type with exactly one value in it, the number is in the type rather than in the value, and there is nothing to inspect at run time because nothing is there.
Three instances are listed and `Num` is not among them.

Chapter 4's four shifts are `d1` handed over four times:

```haskell
{{#include ../../../code/src/Chapters/Ch04.hs:shifts}}
```

and until it is handed over, the distance is an argument still wanted, like any other:

```
clashi> :t rotateLeftS glider
rotateLeftS glider :: SNat d -> Vec 8 (Vec 8 Bool)
```

The mistake the chapter pre-flagged now reads from the other side.
A literal has [no type of its own](type-inference.md#a-literal-has-no-type-of-its-own), and `Num` is the class that turns it into a value of whatever the context asked for.
The context here asks for an `SNat`, no instance produces one, and the message says exactly that: `[GHC-39999]`, `No instance for ‘Num (SNat d0)’ arising from the literal ‘1’`, `In the second argument of ‘rotateLeftS’, namely ‘1’`.
The `d0` in it is the compiler's name for the distance it never found out.

What the message does not say is what such an instance would have to do.
The number an `SNat` carries is its type, so an instance would have to turn any literal at all into the one value of `SNat 1`, and `1` and `5` would both come out as one.
A conversion that quietly returns a different number from the one written is worse than a rejection, and this is the rejection instead.
The same thing from the other direction: `d1 + d1` is `No instance for ‘Num (SNat 1)’ arising from a use of ‘+’`, and the `+` there is the one that describes an adder.

## `KnownNat` is the way back down

Chapter 4 leans on two library functions over vectors, and one of them carries a requirement the other does not:

```
clashi> :i map
map :: (a -> b) -> Vec n a -> Vec n b
  	-- Defined in ‘Clash.Sized.Vector’
```

`map` never asks how many elements there are: it does [the same thing to each of them](higher-order.md#the-first-argument-is-a-function), so the number can stay in the type where nothing reads it.
`rotateLeftS` has to count.
Moving every element along by one means knowing which element falls off the end and where it comes back on, and that is arithmetic on the length rather than on the contents.

`KnownNat n` is the requirement that `n` is known when the design is compiled, and what it delivers is that number as a value, at the point where a description needs to count.
Reading it as the return trip is the useful way round: `SNat`'s constructor above asks for `KnownNat n`, and `KnownNat n` is what hands the number back.
The function that fetches it is not one the reader's file ever calls, because the library functions that count do their counting inside:

```
clashi> :i snatToNum
snatToNum :: Num a => SNat n -> a
  	-- Defined in ‘Clash.Promoted.Nat’
clashi> snatToNum d1 :: Int
1
```

Chapter 12 is where the two directions become an edit.
Every function that computes over a board takes the size, and only some of them take the constraint:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:counting}}
```

The four shifts, `neighbourBoards` and `neighbourCounts` carry `KnownNat n` because the rotation underneath them counts; `countBoard` and `addCounts` do not, and chapter 12 says why in one sentence: `map` and `zipWith` never ask how many there are.
Where the constraint goes was not a matter of taste, and the chapter is plain about that too: the compiler asks for it by name, at the definition that needs it.

What arrives at the bottom is a constant.
Chapter 12 put the two generated `step` components side by side, 343 lines each, and every difference between them is a number: `0 to 7` against `0 to 15`, and `1 mod 8` against `1 mod 16`.
That `mod` is the rotation wrapping, and the eight beside it was a number in a type until something needed to count with it.

## Arithmetic happens up there too

Numbers in types are computed with, and the compiler is what does the computing:

```
clashi> :t (5 :: Signed (4 + 4))
(5 :: Signed (4 + 4)) :: Signed 8
```

`Signed (4 + 4)` and `Signed 8` are the same type, and no addition happened at run time to make them the same: the sum was done while the types were being settled.
The same arithmetic is in a signature the reader has already met, where it does the work of a requirement: [`foldl1` takes a `Vec (n + 1) a`](higher-order.md#the-functions-we-wrote-go-in-the-same-slot), which is how "at least one element" is said with a plus.

Chapter 8 read a `Command`'s width off the bits that `pack` printed, two for the tag and sixty-four for the payload, sixty-six in all.
With chapter 12's file loaded, where `Command` takes its size as a number, the prompt gives that count back as the sum it is:

```
clashi> :t pack (Step :: Command 8)
pack (Step :: Command 8) :: BitVector (CLog 2 4 + 64)
clashi> pack (Step :: Command 8)
0b01_...._...._...._...._...._...._...._...._...._...._...._...._...._...._...._....
```

`CLog 2 4` is the ceiling of the base two logarithm of four, which is the width four constructors need for a tag, and 64 is the board in the payload.
The type is printed as a sum rather than as 66 because asking for a type does not work it out, and the line below it is where the sixty-six bits are: two of tag and sixty-four of payload, exactly as chapter 8 printed them.

The same command at the other size is the same sum with one number changed:

```
clashi> :t pack (Step :: Command 16)
pack (Step :: Command 16) :: BitVector (CLog 2 4 + 256)
```

Two hundred and fifty-eight, which is chapter 12's `n * n + 2` and the `subtype Command is std_logic_vector(257 downto 0)` it read out of the generated types package.
Nobody wrote 258 anywhere, and nobody wrote 66 either.

`Board` itself changed kind between the two chapters:

```
clashi> :k Board
Board :: Nat -> Type
```

Chapter 3's `Board` was a type and chapter 12's is something that becomes one when it is given a number, exactly as `Vec` is.
The added `Nat ->` is chapter 12 in one line, and it is also why the `Synthesize` annotation could not stay on `life`: the annotation names a port list, a port list is a fixed number of wires, and the number is only fixed where a `Nat` has been supplied.

## A requirement about a number no wire carries

Numbers in types are compared as well as added, and chapter 10 walked past one:

```
clashi> :i outputVerifier'
outputVerifier' ::
  (KnownNat l, KnownDomain dom, Eq a, ShowX a, 1 <= l) =>
  Clock dom
  -> Reset dom -> Vec l a -> Signal dom a -> Signal dom Bool
  	-- Defined in ‘Clash.Explicit.Testbench’
```

Everything to the left of the `=>` is a requirement rather than an argument, and the last of the five is a comparison: `1 <= l` says that the vector of expected values has at least one element in it.
`outputVerifier'` finishes on the last value it was given, so there has to be a last one, and a vector of none of them is refused before anything runs: `[GHC-64725]`, `Cannot satisfy: 1 <= 0`.
Chapter 10 handed it eight boards and nobody had to think about it, which is what a satisfied requirement looks like.

That message is two words and a comparison.
It names no signal, no board and no wire, because `l` is not carried anywhere: it was the number of expected boards, it was eight in chapter 10, and it was gone before NVC saw anything.

## What it costs

The errors talk about types, and the mistake was about a wire.
`No instance for ‘Num (SNat d0)’` is a true statement about a missing instance and says nothing about there being two worlds of numbers.
`Cannot satisfy: 1 <= 0` is two numbers with nothing around them.
`Couldn't match type ‘16’ with ‘8’`, which is what the prompt answers when chapter 12's 16×16 seed is claimed to be a `Board 8`, is the friendliest of the three, and it is friendly because both of its numbers are the reader's.

The worst the tutorial meets is chapter 12's: `[GHC-95822]`, `solveWanteds: too many iterations (limit = 4)`, from a plain `deriving` clause on a type whose width depends on `n`.
There is no wire in that message, no type of the reader's, no line of theirs and no number of theirs, and the number it does have is an iteration limit, which is a fact about the solver.
What fixes it is one context written in one place, and nothing in the message points there.
That is why chapter 12 states the fix rather than letting the reader find it, and it is the honest end of this page's cost: the machinery is sound, and when it fails to convince itself, it says so in its own words rather than in the design's.

What the two worlds buy is that a width is a fact rather than a convention.
A `Vec 7` cannot arrive where a `Vec 8` is expected, chapter 12's two entities carry a 64-bit `cells` and a 256-bit one with no possibility of either being handed the other's command, and the compiler is what says so rather than an elaboration a tool performs later.
The cost is on the other side of the same coin: a number in a type is settled before the design runs, so the length of a `Vec` cannot depend on anything the design computes.
That is a cannot rather than a not currently, and it is the same cannot [that keeps a list out of the hardware](vec-and-lists.md#what-it-costs).

## Where you met this

- Chapter 1, [The instrument](../b/01-the-instrument.md): `Signed 8`, eight bits in the type rather than in a comment, and `plus 3 5`, where the numbers are values.
- Chapter 3, [A board, and a picture](../b/03-a-board.md): `type Board :: Type`, and a length that is in the type and checked.
- Chapter 4, [Neighbours, by moving the whole board](../b/04-neighbours.md): `SNat d` in `rotateLeftS`'s signature, `d1` in the four shifts, and the `1` that will not do.
- Chapter 8, [More than valid](../b/08-more-than-valid.md): `pack`, and the sixty-six bits this page's arithmetic adds up to.
- Chapter 10, [A test bench that leaves Haskell](../b/10-a-test-bench.md): `1 <= l` among `outputVerifier'`'s requirements.
- Chapter 12, [One description, two sizes](../b/12-two-sizes.md): `Board n`, `KnownNat n` where the compiler asked for it, and the two entities the numbers came out as.
