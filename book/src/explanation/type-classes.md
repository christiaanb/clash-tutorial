# Constraints are arguments the compiler writes

Chapter 6 asked a register what it wanted before writing anything that used it:

```
clashi> :i register
register ::
  (KnownDomain dom, NFDataX a) =>
  Clock dom
  -> Reset dom -> Enable dom -> a -> Signal dom a -> Signal dom a
  	-- Defined in ‘Clash.Explicit.Signal’
```

The chapter read the arguments off the lines after the `=>` and dealt with everything before it in one sentence: the two constraints are "requirements the compiler settles on its own here, and there is nothing to type for them."
That is true, and it was all a reader needed in order to write `life`.
It also put off the largest question the book leaves standing.

The reader had already walked past a `=>` in chapter 4, in `rotateLeftS`'s signature.
Chapter 10's `outputVerifier'` has five requirements standing in front of a single one of them, chapter 12 spends its first section putting one requirement into seven signatures, and chapter 13 ends on one: `HiddenClockResetEnable System` where three arguments used to be, and an admission that what that is "takes another question to answer."

This page is that answer.
Three things that do not look related to it are the same mechanism underneath: the five words in chapter 8's `deriving` line, the bare `1` chapter 2 wrote in a truth table, and the clock that reaches `mealy` in chapter 13 without being passed to it.

## The reading that does not survive

VHDL has nothing in this shape, so there is no single wrong reading to correct, and three near neighbours are each close enough to mislead.

A generic is the first.
It is declared above the ports, it parameterises the entity, and its value arrives at instantiation, so reading the context as a generic clause gets the position on the page right and the supplier exactly wrong: nothing at the call site supplies a constraint.

An overloaded subprogram is the second, and it is the closest thing VHDL has.
Two functions may share a name and be told apart by the types of their arguments, which is what a class method does.
What VHDL has no way to write is the *requirement*: a signature cannot say that it works for any type that has a `+`, so a subprogram that needs one is written per type or written once and copied, and the compiler is never asked to check that the operation exists before the call is allowed.

The third is to read `=>` as another arrow with odd punctuation.
That reading makes `register` a function of seven things, and chapter 6 hands it five.

The reading that costs the most is the mildest one: that a context is documentation, a note about what the function assumes.
It is not a note.
It is the reason the definition below it is able to do anything at all, and something is really handed over to make it so.

## A class is a promise, and an instance is a type keeping it

The smallest class in the book is the one chapter 12 puts into seven signatures:

```
clashi> :i KnownNat
type KnownNat :: Nat -> Constraint
class KnownNat n where
  natSing :: GHC.Internal.TypeNats.SNat n
  {-# MINIMAL natSing #-}
  	-- Defined in ‘GHC.Internal.TypeNats’
```

The first line is the one to read twice.
[Every kind line the reader has seen](type-level-numbers.md#the-eight-is-in-the-type-and-the-type-is-not-a-number) ended in `Type`, because `Board` is a type and `Vec` becomes one; this one ends in `Constraint`.
`KnownNat 8` is not a type and nothing can have it: it is a claim about a type, and the only thing to do with a claim is require it, prove it or fail to.

What follows the claim is what it promises.
A class lists operations, `natSing` is the one operation `KnownNat` has, and `{-# MINIMAL natSing #-}` is the compiler saying what an instance is obliged to supply.

An instance is a type keeping that promise, and chapter 8 printed two of them with the word never defined:

```
clashi> :i St
type St :: Type
data St = St {board :: Board, running :: Bool}
  	-- Defined at src/Example/Project.hs:94:1
instance Generic St -- Defined at src/Example/Project.hs:95:13
instance NFDataX St -- Defined at src/Example/Project.hs:95:22
```

Read the last two lines aloud and they are a record of two promises: `St` keeps `Generic`'s and keeps `NFDataX`'s.
Both were made at line 95, columns 13 and 22, and those are the two words in `deriving (Generic, NFDataX)`.

A promise that was not made cannot be called on.
Chapter 8's `pack Step` printed sixty-six bits; the state beside it will not pack at all, and the refusal names the missing promise rather than anything about the value: `[GHC-39999]`, `No instance for ‘BitPack St’ arising from a use of ‘pack’`, over `In the expression: pack (St glider False)`.
Nothing is wrong with that value.
It is the state chapter 8's `mealy` holds while the reset is asserted, and every run of that design starts from it.
What it does not have is one word in a `deriving` line, and `pack` is the operation that word promises.

The prompt's own printing works the same way, which is why a value can be perfectly good and still not be printable:

```
clashi> :i show
type Show :: Type -> Constraint
class Show a where
  ...
  show :: a -> String
  ...
  	-- Defined in ‘GHC.Internal.Show’
```

Typing `St glider False` at the prompt is `[GHC-39999]`, `No instance for ‘Show St’ arising from a use of ‘print’`, and under it `In a stmt of an interactive GHCi command: print it`.
`print` is the prompt's, not the reader's: everything typed at it is printed by calling `show`, so a type that never promised one cannot be looked at, however well the design runs on it.

In VHDL the equivalent is writing a `to_string` for the record and calling it, and overload resolution picking it out from the argument type is genuinely the same idea.
What has no VHDL spelling is the `Show a =>` in front of that function: a way of demanding, in a signature, that the operation exist for whatever type turns up there.

## `=>` is not `->`

Chapter 6's `life` is the whole of the argument.
It hands `register` five things, in the order the signature lists them after the `=>`, and there is no sixth or seventh.
There is no `=>` anywhere in chapter 6's file, and the words `KnownDomain` and `NFDataX` do not appear in it at all.

So what happens to the two requirements is not that they are met somewhere else in the file.
The compiler works out, from the types at the use site, which instance is meant, and hands the definition of `register` what that instance promised.
A constraint is an argument in the sense that something really is passed; it is not an argument in the sense the reader cares about, because the caller does not write it and cannot choose it.

An unsettled requirement can be watched waiting:

```
clashi> :t unpack (pack Step)
unpack (pack Step) :: (BitSize a ~ 66, BitPack a) => a
```

Sixty-six bits go in, and what comes out is *whatever type* keeps `BitPack`'s promise in sixty-six bits.
The requirement is still standing because nothing has said which type that is, and `(unpack (pack Step) :: Command)` — [the annotated form another page asks about](data-types.md#four-constructors-and-nothing-else) — settles it: the annotation picks the type, the type picks the instance, and the constraint goes away.
That is the ordinary case rather than a curiosity: the type is [solved for](type-inference.md#solving-not-guessing) first, and the instance follows from the type.

## A requirement can hand over a value

`KnownNat`'s one method returns an `SNat n`, and the type it returns is worth following:

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

`SNat` is a constructor with a requirement written in front of it, which is a `data` declaration storing a constraint where another declaration would store a value.
That is the plainest evidence on this page that a constraint is a thing and not a checkbox: it can be put in a box and carried around.

What `KnownNat n` carries is the number, and [reading it as the trip back down](type-level-numbers.md#knownnat-is-the-way-back-down) is what makes chapter 12's edit make sense.
It also decides where the words go, which chapter 12 states as a rule and does not explain: `rotateLeftS` has to count, so it demands the number, so everything that calls it has to be able to produce one, and the demand travels up the file until a signature carries it.
Leaving it off is not a matter of style, and the compiler says so at the definition that broke.
Chapter 12's `step` with `KnownNat n` taken out of its signature and nothing else changed does not load: `[GHC-39999]`, `No instance for ‘KnownNat n’ arising from a use of ‘neighbourCounts’`.
Under that comes `Possible fix: add (KnownNat n) to the context of the type signature for: step :: forall (n :: Nat). Board n -> Board n`, and under that the line of `step` that used the requirement, with `neighbourCounts` underlined in it.
The message names the function that demanded the number, the signature that has to carry the demand, and the words to add, in that order.
`KnownNat n` is written ten times in chapter 12's file, and every one of those ten is downstream of one library function that needs to know how long a vector is.

What is carried around is carried while the design is being simulated at the prompt, and it is worth saying plainly that none of it survives into hardware.
The instance is chosen while the program is being compiled, so by the time Clash writes VHDL the number is a literal — chapter 12's two `step` components differ by `1 mod 8` against `1 mod 16` and by nothing else — and chapter 13's entity declarations came out byte for byte identical to chapter 12's while the clock changed route.
A constraint is a compile-time argument, and the price of one is paid in messages rather than in wires.

## Three wires, delivered the same way

Chapter 13 is where a constraint delivers something a hardware engineer can point at.
The name it introduces is not a class at all:

```
clashi> :i HiddenClockResetEnable
type HiddenClockResetEnable :: Domain -> Constraint
type HiddenClockResetEnable dom =
  (HiddenClock dom, HiddenReset dom, HiddenEnable dom) :: Constraint
  	-- Defined in ‘Clash.Signal’
```

It is a synonym for three requirements at once, of the kind chapter 6's `register` had two of, and the kind line says `Constraint` for the same reason `KnownNat`'s did.
Each of the three delivers one thing, and `hasClock` is the one to look at:

```
clashi> :i hasClock
hasClock :: HiddenClock dom => Clock dom
  	-- Defined in ‘Clash.Signal’
```

A `Clock dom`, and no arguments whatsoever.
There is exactly one place a clock could come from in that signature, and it is on the left of the `=>`.
`hasReset :: HiddenReset dom => Reset dom` and `hasEnable :: HiddenEnable dom => Enable dom` sit beside it and say the same thing about the other two.

The function chapter 13 has the reader write is the conversion in the other direction, and its signature is the whole chapter in three lines:

```
clashi> :i exposeClockResetEnable
exposeClockResetEnable ::
  (HiddenClockResetEnable dom => r)
  -> KnownDomain dom => Clock dom -> Reset dom -> Enable dom -> r
  	-- Defined in ‘Clash.Signal’
```

Something that requires the three, in, and a function of three arguments, out.
A constraint and an argument list are interchangeable here, and this is the library function that does the exchanging, which is why an annotated binder can have real ports on it while the body above it names no clock.
Chapter 13's sentence that "the constraint is how they reach it" is not a figure of speech, and neither is its claim that nothing was switched off: the generated entity declarations came out byte for byte identical across that chapter.

What the shorter notation costs is what chapter 13 says it costs, and it is a cost about reading rather than about circuits.
`:i mealy` printed ten lines under the explicit prelude and prints four under this one, and the three argument lines that went missing are the ones chapter 7 read to find out what a state machine wanted.

## A literal is a class method

The same mechanism explains something that has been going on since chapter 2, where a truth table matched on `2` and `3`.
A literal is a call:

```
clashi> :i fromInteger
type Num :: Type -> Constraint
class Num a where
  ...
  fromInteger :: Integer -> a
  	-- Defined in ‘GHC.Internal.Num’
```

Writing `1` is writing `fromInteger 1`, so a literal has no type of its own and takes the one the context asks for, by running that type's `fromInteger`.
In a pattern the literal is built the same way and then compared, which is why matching on a number asks for `Eq` as well.
The numbers in chapter 2's rows are `Unsigned 4`s because `nextCell`'s signature says so, and the `1` and `0` in chapter 4's `toCount` are four bits wide because `Counts` says so; [how the context decides](type-inference.md#a-literal-has-no-type-of-its-own) is a separate question from what does the converting once it has.

`+` is a method of the same class, and the prompt answers about it twice over:

```
clashi> :i (+)
type Num :: Type -> Constraint
class Num a where
  (+) :: a -> a -> a
  ...
  	-- Defined in ‘GHC.Internal.Num’
infixl 6 +

type (+) :: Natural -> Natural -> Natural
type family (+) a b
  	-- Defined in ‘GHC.Internal.TypeNats’
infixl 6 +
```

Two answers because there are two `+`s and they live in [the two worlds of numbers](type-level-numbers.md#arithmetic-happens-up-there-too): the class method is the adder, and the type family is the one that adds `4 + 4` while types are being settled.
Which adder the method is depends on the instance, and the instances do not agree:

```
clashi> (maxBound :: Unsigned 4) + 1
0
clashi> (maxBound :: Signed 8) + 1
-128
```

One token, two instances, two different wrap-arounds, both of them decided by a type and neither of them written down.
The four hundred and forty-eight additions chapter 4 counted are the `Unsigned 4` instance's, and that is where their width and their behaviour on overflow both come from.

Chapter 4's error is this page's mechanism from the other side.
`rotateLeftS b 1` answers that `SNat` is not a `Num`, and what that means exactly is that no instance exists, so there is no `fromInteger` to make the literal with, and there is [a good reason no such instance should exist](type-level-numbers.md#d1-is-a-value-whose-type-is-the-number).

## `fmap` is a class method too

Chapter 6 needed a function put to work on what a signal carries, and used a name that belongs to a class:

```
clashi> :i fmap
type Functor :: (Type -> Type) -> Constraint
class Functor f where
  fmap :: (a -> b) -> f a -> f b
  ...
  	-- Defined in ‘GHC.Internal.Base’
```

`f` is not a type but something that becomes one, so what keeps this promise is a `Vec`, a `Maybe` or a `Signal` rather than a `Board`.
One function, and the container left open:

```
clashi> :t (\b -> fmap step b)
(\b -> fmap step b) :: Functor f => f Board -> f Board
clashi> :t fmap step (Just glider)
fmap step (Just glider) :: Maybe Board
clashi> :t fmap step (fromList [glider])
fmap step (fromList [glider]) :: Signal dom Board
```

Chapter 6's `fmap step boards` is the third of those, and the reason it worked is that `Signal dom` keeps `Functor`'s promise.
Nothing in chapter 6 said so, nothing had to, and the same four letters would have been the `Maybe` version if `boards` had been one.

## `deriving` is a request for instances

Chapter 8's five words are five requests, and the chapter says what each one promises: the shape of the type, what a register needs, what a bundle of wires needs, and what comparing and printing need.
What the chapter does not say is who writes them.
`Generic` is the shape itself, and the other four are worked out from that shape by the compiler rather than by the reader, which is what makes a five-word line a fair swap for four hand-written instances.

Chapter 12 splits the same request in two and the split is visible in the answer:

```
clashi> :i St
type role St nominal
type St :: Nat -> Type
data St n = St {board :: Board n, running :: Bool}
  	-- Defined at src/Example/Project.hs:143:1
instance Generic (St n) -- Defined at src/Example/Project.hs:144:13
instance KnownNat n => NFDataX (St n)
  -- Defined at src/Example/Project.hs:146:1
```

Two instances of one type, one asked for inside the `deriving` clause at line 144 and one asked for on a line of its own at 146, and only the second has a `=>` in it.
An instance can need a requirement, and this one does: `NFDataX`'s promise includes producing a value of the type with nothing in it yet, and how many cells that is depends on `n`.
A `deriving` clause has nowhere to write `KnownNat n =>`, so the request moves to a line where there is somewhere to write it.
Chapter 12 makes the same point about `BitPack`, whose width is `n * n + 2`, and the message that comes back from asking the other way is [the worst one the tutorial meets](type-level-numbers.md#what-it-costs).

`deriving` is a request and not an instruction, which is the honest way to read that failure.
The compiler may decline, and when it declines it does so in the vocabulary of its own solver rather than in the reader's.

## What it costs

**The message names something you did not type, and the fix is somewhere you were not looking.**
`No instance for ‘Show St’ arising from a use of ‘print’` is a complaint about a function the reader never wrote, from a prompt that called it on their behalf, about a promise that is missing from a `deriving` line somewhere else in the file.
There is no suggested fix in that message at all, and the word that would fix it is one the reader has to know is available.

**Where a suggestion does come, it is the best tool in the language, and it is not always there.**
The `KnownNat n` message above prints the signature and the words to add to it, and following it mechanically is what chapter 12 asks the reader to do.
Chapter 12's other message, from a plain `deriving` clause on a type whose width depends on `n`, is `solveWanteds: too many iterations (limit = 4)`, which contains no name of the reader's and no fix.

**One type keeps a promise one way, and no use site may ask for another.**
Adding `Show` to chapter 8's `St` and also writing an instance for it by hand stops the module loading, with `[GHC-59692]`, `Duplicate instance declarations:` and two `instance Show St` lines under it, one pointing at the word in the `deriving` clause and the other at the hand-written instance two lines below.
In VHDL two functions with one name are ordinary, and a third with a different name is how a second way of printing a record is had.
Here the type chooses, once, for the whole program, so a second way of packing or printing something means declaring a second type to hang it on.
That is what makes the choice checkable and predictable at a distance, and it is the same fact viewed from either side.

**A requirement travels, and every signature on the way pays for it.**
Chapter 12 wrote `KnownNat n` ten times for one library function that counts, and chapter 13 added a second constraint to the line that already had that one.
A demand introduced at the bottom of a design appears as edits to signatures all the way up, and the compiler will name each of them in turn as they are reached.

## Where you met this

- Chapter 2, [A cell](../b/02-a-cell.md): literals in a truth table, four bits wide because a signature said so.
- Chapter 4, [Neighbours, by moving the whole board](../b/04-neighbours.md): the first `=>` in the book, and the `Num` instance that does not exist.
- Chapter 6, [It runs by itself](../b/06-it-runs.md): `:i register`'s two requirements, settled without a word in the file, and `fmap` on a `Signal`.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `:i mealy`, and `NFDataX s` beside the state it holds.
- Chapter 8, [More than valid](../b/08-more-than-valid.md): five words asking for five instances, and two of them reported back by `:i St`.
- Chapter 10, [A test bench that leaves Haskell](../b/10-a-test-bench.md): five requirements at once in `outputVerifier'`'s signature.
- Chapter 12, [One description, two sizes](../b/12-two-sizes.md): `KnownNat n` where the compiler asked for it, and two requests moved out of the clause to carry a context.
- Chapter 13, [What the rest of the world writes](../b/13-hidden.md): a clock, a reset and an enable arriving as a constraint, and `exposeClockResetEnable` turning them back into arguments.
