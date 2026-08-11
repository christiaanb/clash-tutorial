# What the lowercase letters in a type mean

Chapter 4 asked what `rotateLeftS` wanted before writing anything that used it:

```
clashi> :i rotateLeftS
rotateLeftS :: KnownNat n => Vec n a -> SNat d -> Vec n a
  	-- Defined in ‘Clash.Sized.Vector’
```

Every signature the book had shown until that line was made of capitalised names and nothing else.
`plus :: Signed 8 -> Signed 8 -> Signed 8` in chapter 1, `nextCell :: Bool -> Unsigned 4 -> Bool` in chapter 2, `fromRows :: Vec 8 (BitVector 8) -> Board` in chapter 3: every name in them is a type, and each one can be looked up.
This one has three names that nothing anywhere declares, each of them a single letter.

The chapter said what to write and went on, which is what a chapter is for.
It then wrote four functions directly underneath with no such letters in them at all, `shiftN, shiftS, shiftW, shiftE :: Board -> Board`, and the two facts sit oddly next to each other: a signature made entirely of constants, defined in terms of one made mostly of variables.
That arrangement holds for eight more chapters, and chapter 12 ends it by taking the eight out of `Board` and having the reader write the letters.

This page is what the letters are, what the compiler does with them, and what is left of them once hardware comes out.

## The reading that does not survive

VHDL parameterises, and it does it twice over.
A generic is declared in a clause of its own above the ports, with a name and a type and often a default, and its value arrives when the entity is instantiated.
An unconstrained array type is declared with `natural range <>` where its bounds would go, and the bounds arrive when an object of that type is declared.
Both of those are declarations, both are written before anything uses them, and both are read as part of the interface.

Carried over, `Vec n a` becomes an unconstrained array with a generic in it, `n` becomes the generic, and `a` becomes an oddity to be skipped.
That reading gets one thing right, and it is the important thing: `n` is a size that is not settled here, and something settles it later.
It gets `a` wrong, because `a` is the same kind of name as `n` and stands for a type rather than for a number, which is how `map :: (a -> b) -> Vec n a -> Vec n b` describes changing the element type of a vector without saying which two types.
It gets the declaration wrong, because there is no clause anywhere that introduces `n`, `a` or `d`, and the letter's presence in the signature is the whole of its introduction.

And it gets one thing wrong that stays hidden until chapter 12.
A generic belongs to an entity: there is one entity, it carries a parameter, and each instantiation settles the parameter.
Here there is no entity at all while a letter is still standing, and chapter 12's generated tree has two 343-line `step` components in it rather than one with a number on it.

## A lowercase name is a variable

The case of the first letter is the whole of the rule.
A name beginning with a capital is a constant: `Board` is one type, `Bool` is one type, `System` is one clock domain, and each means the same thing everywhere it appears.
A name beginning with a lowercase letter is a variable, standing for something the signature does not name.
It needs no declaration because writing it is the declaration, and it means nothing outside the signature it appears in.

So `Vec n a` is not a particular type: it is the shape every vector type has, and `Vec 8 Bool` is one of the types it becomes when both letters are filled in.
`Vec` with neither of them is not a type at all, which is [what its kind says](type-level-numbers.md#the-eight-is-in-the-type-and-the-type-is-not-a-number).
`rotateLeftS`'s signature is a description of every rotation of every vector, and chapter 4 used exactly one of them.
`glider` is a `Board`, which is `Vec 8 (Vec 8 Bool)`, so `n` is eight and `a` is `Vec 8 Bool` at that use site, and `d` is one because `d1` is what was handed over.
Not one of those three is written at the use site, and the prompt reports the result with all of them gone:

```
clashi> :t rotateLeftS glider d1
rotateLeftS glider d1 :: Vec 8 (Vec 8 Bool)
```

Which letter is used for what is convention and nothing more.
`n` and `d` here are numbers, `a`, `b` and `c` are types, `dom` is a clock domain, and `mealy`'s `s`, `i` and `o` are a state, an input and an output.
The language does not read the names: what makes `n` a number is [its kind](type-level-numbers.md#the-eight-is-in-the-type-and-the-type-is-not-a-number), which is `Nat`, and the kind is worked out from how the letter is used rather than written down.
A variable need not be a single letter either, and `dom` is the one the book shows most often.

## The same letter twice is a promise

Count the occurrences, because that is where the information is.
In `Vec n a -> SNat d -> Vec n a`, `n` and `a` each appear twice, once in the argument and once in the result, and `d` appears once.
A letter written once says only that something goes in that position.
A letter written twice says that the two positions hold the same thing, and that is a promise the compiler holds the definition to: `rotateLeftS` returns a vector of the same length and the same element type as the one it was given, and no definition carrying that signature could do anything else.
The distance is unrelated to either, and `d` being written once is how that is said.

`zipWith` is the same rule over three vectors, `(a -> b -> c) -> Vec n a -> Vec n b -> Vec n c`, with one `n` in three places: two vectors of the same length in, one of that length out, and three element types free of each other.
Chapter 4's `addCounts :: Counts -> Counts -> Counts` is that signature with every letter filled in, and it is why nothing in chapter 5 has to check that a board and its table of counts are the same shape before laying one on the other.

Chapter 12's file is the only place in the book where two sizes exist at once, so it is the only place where that promise can be watched failing.
Adding a table of counts for the 8×8 glider to one for the 16×16 board is rejected: `[GHC-83865]`, `Couldn't match type ‘16’ with ‘8’`, over `Expected: Board 8` and `Actual: Board 16`.
Where it is rejected is the part worth reading.
The message names `In the first argument of ‘countBoard’, namely ‘glider16’`, and `countBoard` is not where the promise was made.
`addCounts :: Counts n -> Counts n -> Counts n` had its `n` settled at eight by its first argument, so its second argument has to be a `Counts 8`, so `countBoard` has to have been given a `Board 8`, and `glider16` is not one.
The requirement travelled from one argument of `addCounts` into the inside of the other.

## Filling a signature in

Reading a signature with letters in it means doing by hand what the compiler does anyway, which is [solving for what they have to be](type-inference.md#solving-not-guessing).
`mealy` is the one worth doing in full, because the tutorial asks about it in chapter 7 and reads it left to right rather than filling it in:

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

Four variables, `dom`, `s`, `i` and `o`, and chapter 7's one line of `life` settles all four.
The clock decides `dom`: `life`'s signature declares a `Clock System`, so `dom` is `System` everywhere below it.
`lifeT` goes in the parenthesised position, and chapter 7's `lifeT :: Board -> Maybe Board -> (Board, Board)` lines up against `(s -> i -> (s, o))` position by position: `s` is `Board`, `i` is `Maybe Board`, and `(s, o)` against `(Board, Board)` makes `o` a `Board` too, with the first half of the pair agreeing with what `s` already had to be.
Everything below that follows without a decision: the bare `s` is where `glider` goes, `Signal dom i` is `Signal System (Maybe Board)`, and `Signal dom o` is `Signal System Board`.

That is what the prompt answers, with the seed not yet supplied:

```
clashi> :t mealy systemClockGen resetGen enableGen lifeT
mealy systemClockGen resetGen enableGen lifeT
  :: Board -> Signal System (Maybe Board) -> Signal System Board
```

Chapter 8 replaces `lifeT` with a version over a record and a command set of its own, and the same command at the prompt answers differently:

```
clashi> :t mealy systemClockGen resetGen enableGen lifeT
mealy systemClockGen resetGen enableGen lifeT
  :: St -> Signal System (Maybe Command) -> Signal System Board
```

`s` is now `St` and `i` is `Maybe Command`, because chapter 8's `lifeT :: St -> Maybe Command -> (St, Board)` filled the same three positions with its own types.
`mealy` was not edited, copied or told anything between those two lines, and neither was the register inside it.
That is what the letters buy: the state of chapter 8's machine is a record that did not exist when the library was written, and the library holds it without knowing what it is.

The same reading works on every library signature the book shows.
Chapter 6's `:i register` has `a` and `dom` in it and the chapter says in prose what this section does by substitution.
Chapter 10's `outputVerifier'` has `l`, `dom` and `a`, and `l` is settled at eight by the vector of expected boards it is handed.

## A variable in your own signature is a promise you make

Chapter 12 is where the reader writes the letters rather than reading them, and it is where the direction of the promise reverses.
Its central line is one signature:

```
clashi> :i step
step :: KnownNat n => Board n -> Board n
  	-- Defined at src/Example/Project.hs:111:1
```

Read as a generic, that says `step` may be used at any size, and it does say that.
What it adds is when the claim is settled: a definition of that type has to work for every `n`, so its body may only do things that work for every `n`, and the compiler checks it against the claim once rather than checking it again at each size somebody uses.

The claim is strict, and it is easy to see how strict by making it falsely.
`glider` is a `Board 8`, and annotating it as a `Board n` says it is a board of every size at once:
`[GHC-25897]`, `Couldn't match type ‘n’ with ‘8’`, and under it `‘n’ is a rigid type variable bound by an expression type signature: forall (n :: Nat). Board n`.
Rigid means the compiler is not allowed to pick a value for it, because the signature said every value.
`forall` is the quantifier that a signature always has and never has to write, and it is what the message is spelling out: `Board n` means for every `n` there is, and `glider` is one board of one size.

The other half of the promise is what the body may ask.
A body written for every `n` cannot ask what `n` is, because at the point where it is written there is no answer, and `KnownNat n` is [the requirement that brings the number back down](type-level-numbers.md#knownnat-is-the-way-back-down) for a body that needs to count.
Chapter 12's rule for where it goes is the compiler's rather than a matter of style: the four shifts carry it because rotation counts and everything that calls them carries it in turn, and `countBoard` and `addCounts` do not, because `map` and `zipWith` [never ask how many elements there are](higher-order.md#the-first-argument-is-a-function).

One more thing shows up as soon as the reader's own signatures have letters in them, and it is worth knowing before it is met.
A letter belongs to one signature, so two signatures may use the same letter for different things, and the prompt renames them apart when it has to print both:

```
clashi> :t map countBoard
map countBoard :: Vec n1 (Board n2) -> Vec n1 (Counts n2)
```

`map`'s own signature and chapter 12's `countBoard` both use the letter `n`, and the two are not the same variable: `n1` is how many boards there are and `n2` is how wide each one is.
Nothing in the file was renamed and nothing in it is wrong; the prompt needed two names for two things and the file only ever needed one.

## What synthesis does with a variable

Nothing at all, and chapter 12's last section is that fact in a generated tree.
The description at the top of that design is the one the reader wrote with a letter in it:

```haskell
{{#include ../../../code/src/Chapters/Ch12.hs:life}}
```

`life` has no entity anywhere under `vhdl/`, because a `Synthesize` annotation names a port list, a port list is a fixed number of wires, and a number of wires is exactly what a letter is not.
What reaches the VHDL are `life8` and `life16`, and both of them are that description with a seed of a definite size handed over:

```
clashi> :t life glider
life glider
  :: Clock System
     -> Reset System
     -> Enable System
     -> Signal System (Maybe (Command 8))
     -> Signal System (Board 8)
clashi> :t life glider16
life glider16
  :: Clock System
     -> Reset System
     -> Enable System
     -> Signal System (Maybe (Command 16))
     -> Signal System (Board 16)
```

Those two answers are the signatures chapter 12 writes above `life8` and `life16`, arrived at by supplying one argument to one description.
Every number in them came from the seed and from nowhere else: the command widened because the state holds a board, and the output widened because the output is a board.

What Clash does next is specialise, and chapter 12 puts the result on the page.
There are two `step` components in the tree rather than one, `Example_Project_life8_step.vhdl` and `Example_Project_life16_step.vhdl`, 343 lines each, and every difference between them is a number: `0 to 7` against `0 to 15`, `1 mod 8` against `1 mod 16`.
A generic goes the other way about it, keeping one entity with the parameter in it and settling the parameter per instantiation.
Both routes end at two circuits, because two sizes are two circuits, and what differs is which artefact carries the parameter: the entity in one case, and nothing at all in the other, because by the time there is an entity the number is a literal.

Where they differ in what they promise is worth separating from that.
A generic is checked when the instantiation is elaborated, and a size that does not fit is a message from the tool that elaborated it.
Here `Board 8` and `Board 16` are different types, a `Command 16` cannot be handed to `life8`, and the module does not compile, so there is nothing to elaborate and nothing generated to elaborate it from.
That is the check chapter 12 claims in its own notice-that beat, and it sits upstream of the HDL rather than in it.

Chapter 13 is the last evidence for the letters costing nothing at the boundary.
It changes how the clock, the reset and the enable reach `life`, which is a change to `life`'s type, and `life8` and `life16` keep chapter 12's signatures byte for byte, so both generated entity declarations are byte identical across the chapter.

## What it costs

Two sizes cost two of everything below the description, and chapter 12 says so in its own words rather than presenting the parameter as free.
Two entities, two `step` components, two types packages and two registers, because two sizes are two circuits.
The source is the thing that is shared, and in the generated tree nothing is.

What the 8×8 design paid for the parameter is one argument, and it is visible in the source rather than in the output.
`mealy`'s initial state was `St glider False`, and a description that does not know its size cannot name the board it starts from, so the seed became `life`'s first argument and both wrappers supply it.
The output paid nothing: `life8.vhdl` is 211 lines, which is chapter 9's `life.vhdl` with the name changed and nothing else touched.
Making a description general did not make the specific circuit worse, and that is the strongest thing this page has to say for the letters.

The costs that are left are all about messages.
A variable the reader never wrote can turn up in one, because the compiler numbers letters apart and invents names of its own where a signature had none.
`n1` and `n2` above are the mild case, and the sharper one is the `d0` in [`No instance for ‘Num (SNat d0)’`](type-level-numbers.md#d1-is-a-value-whose-type-is-the-number), which is the compiler's name for a distance nobody supplied.
A message about a rigid type variable is the most ambiguous of the three, because what it reports is a disagreement between a claim and a definition and nothing in it says which of the two is wrong: `glider :: Board n` is a wrong signature over a right value, and it reads exactly like a right signature over a wrong value.

The last cost is the one the tutorial put off until chapter 12, and it is why the reader met the letters in library signatures long before writing one.
A signature with variables in it says less about the design than a signature without them, and it says nothing about the design that will actually be built.
`step :: Board -> Board` is a component with sixty-four wires in and sixty-four out.
`step :: KnownNat n => Board n -> Board n` is a description of that component and of every other size of it, and the number of wires is somewhere else entirely: in a wrapper, at the bottom of the file, where a seed of a definite size is handed over.

## Where you met this

- Chapter 4, [Neighbours, by moving the whole board](../b/04-neighbours.md): `:i rotateLeftS`, the first signature in the book with a lowercase letter in it.
- Chapter 6, [It runs by itself](../b/06-it-runs.md): `:i register`, and `a` and `dom` settled by the value and the clock handed to it.
- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `:i mealy`, and `s`, `i` and `o` filled in by `lifeT`.
- Chapter 8, [More than valid](../b/08-more-than-valid.md): the same three letters filled in again, by a record and a command set of our own.
- Chapter 10, [A test bench that leaves Haskell](../b/10-a-test-bench.md): `outputVerifier'`'s `l`, settled at eight by the boards it is given.
- Chapter 12, [One description, two sizes](../b/12-two-sizes.md): `Board n` written by the reader, `KnownNat n` where the compiler asked for it, and the two entities the letters came out as.
- Chapter 13, [What the rest of the world writes](../b/13-hidden.md): `life` changing type while `life8` and `life16` keep theirs.
