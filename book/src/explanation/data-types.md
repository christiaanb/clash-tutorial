# A type that lists every value it can have

Chapter 8 needed an input that could say four things, and nothing that already existed said them, so the chapter declared a type of its own:

```haskell
{{#include ../../../code/src/Chapters/Ch08.hs:command}}
```

`data` introduces a type and lists every value it can have, the chapter said, and then it said the other half: there is no fifth thing for one to be.
Both of those were left standing, and by then the reader had been using a type of exactly this kind for a chapter already, because chapter 7's `Maybe Board` is one and its declaration was never shown.
One chapter later, chapter 9 writes a record whose fields are given by name, in a shape chapter 8's record never used and the chapter never connected to it.

This page is the declaration itself: what a `data` line makes, what the compiler does with the fact that the list is complete, why `Maybe` needed nothing special to be chapter 7's input, and why the two records are built two different ways.

## The reading that does not survive

All three pieces of a `Command` exist in VHDL, and each of them is declared separately.
There is an enumeration type for the tag, with four values in it.
There is something to carry the payload, a record field or a vector wide enough for a board.
And there is the rule that the payload is a board when the tag says load and is meaningless otherwise, which lives in a comment, or in a specification, or in the head of whoever wrote it.

The first two of those are enforced and the third one is not.
Nothing in the language connects the tag to the payload, so nothing objects when the payload is read on a cycle when the tag says step, and keeping the three in step is work done by hand every time the type is used or changed.
A reader carrying that over reads `data Command` as the enumeration, `Load Board` as the first of its values with a note attached about the payload beside it, and the `deriving` line as a request for something like an image function.
What is on the page is one declaration where those were three, and the rule that used to be the comment is the part the compiler has taken over.

## Four constructors, and nothing else

The list after the `=` is what the type is.
`Load`, `Step`, `Run` and `Pause` are the four values a `Command` can be, and asking the compiler about any one of them answers with the type it belongs to and the others left out, which is what chapter 8's `:i Load` and `:i Step` do.
A `data` declaration is closed: there is no way to add a fifth value from elsewhere in the file, from another module, or from a value that arrived on a port.

That closedness is not a remark, and chapter 8 read the first consequence of it off `pack`.
Four constructors need a two-bit tag, and `Load` is `00` through `Pause` is `11`, so each of the four codes that two bits have names a constructor and none is left over.
The second consequence is that the compiler knows the whole list at every point where the type is used, which is what lets it check that a `case` covers it, and what makes reading sixty-six bits back as a `Command` a question with an answer for every input:

```
clashi> (unpack (pack Step) :: Command) == Step
True
```

`unpack` is not a hole in the closure.
It lands on one of the four because the type holds nothing else for it to land on.
The sixty-four payload bits that arrive with it are read as a board or discarded according to the tag, which is the rule a hand-built decode has to be given, and this one has no way of being given a different one.

The five names in the `deriving` line are requests rather than part of the declaration, and chapter 8 glosses all five.
One of them decides everything the cost section of this page counts: `BitPack` is what settles that a `Command` is sixty-six bits and which of them is the tag.
What a request of that kind is, and what the compiler does to answer it, is [a question of its own](type-classes.md#deriving-is-a-request-for-instances).

## A constructor is a function that has not been applied yet

`Load` has a `Board` written after it in the declaration, and chapter 8 read that as the difference between it and the other three: it is not a value by itself, it takes a board and becomes one.
That is chapter 1's `plus 3` again, and it is worth checking that the resemblance is not a figure of speech.
A function is a thing that goes in the slot where functions go:

```
clashi> :t map Load
map Load :: Vec n Board -> Vec n Command
```

`map` takes a function and a vector, and it accepted `Load` without anything being done to it first, which settles what `Load` is.
The answer it gives is the ordinary one: a vector of boards in, a vector of commands out, and [`map` knows nothing about either of those types](higher-order.md#the-first-argument-is-a-function).
`Step`, `Run` and `Pause` take nothing and so are values already, which is the whole of the difference between the two kinds of line in the declaration.

Constructors are the only way in.
There is no literal for a `Command` and no expression that produces one without naming one of the four, so every command anywhere in the design was written as one of those names applied to what it needs.
`unpack` is the nearest thing to an exception, which is why it was worth checking above that it lands inside the list as well.
Taking a value apart is the same fact read backwards, and that is [pattern matching](pattern-matching.md#a-pattern-is-a-shape-with-holes): the constructor that built the value is the pattern that opens it.

## `Maybe` is a declaration somebody else wrote

Chapter 7 introduced `Maybe Board` as a valid bit and a payload welded together, and never showed where it comes from.
It comes from a `data` line of the same shape as ours, and the compiler will print it a constructor at a time:

```
clashi> :i Just
type Maybe :: Type -> Type
data Maybe a = ... | Just a
  	-- Defined in ‘GHC.Internal.Maybe’
clashi> :i Nothing
type Maybe :: Type -> Type
data Maybe a = Nothing | ...
  	-- Defined in ‘GHC.Internal.Maybe’
```

Two constructors, one carrying and one not, which is the arrangement chapter 8 built four of.
`-- Defined in` names a module rather than the language, so `Maybe` is a declaration that somebody wrote and not a feature that had to be provided.
The lower case `a` is [a variable standing for a type](polymorphism.md#a-lowercase-name-is-a-variable), which is why one declaration serves chapter 7's `Maybe Board` and chapter 8's `Maybe Command` without either of them being anticipated.

`Just` is a function in the same way `Load` is, and it goes in the same slot:

```
clashi> :t map Just
map Just :: Vec n a -> Vec n (Maybe a)
```

Chapter 7's argument about it needs nothing beyond the shape.
`Just` is the only way to build a `Maybe Board` that has a board in it, matching `Just` is the only way to reach the board again, and the `Nothing` row has no name for a board because `Nothing` carries none.
Chapter 8's input is `Maybe Command`, which is our declaration inside theirs, and chapter 9 finds the two tags nested in that order on the port: `cmd(66 downto 66)` for the `Maybe` and `cmd(65 downto 64)` for the `Command`.

Chapter 12 puts a variable into a declaration of the reader's own.
`data Command n` with `Load (Board n)` in it is the same move `Maybe a` makes, and the reason chapter 12 needs it is that the board's size has stopped being eight.

## A capital letter says which kind of name it is

`Step` and `step` are two names, and chapter 8 said the capital is the whole of the difference.
The rule behind that beat is worth having in full, because it is the compass for every name in the book.
In everything this book writes, a name beginning with a capital is a type or a constructor, and the only way to make one is a `data` declaration or a synonym.
A name beginning with a lower case letter is a value, and the way to make one is an equation.

Types and constructors are counted separately, which is why `data St = St { board :: Board, running :: Bool }` names `St` twice without repeating itself.
The `St` on the left of the `=` is the type, the `St` on the right is the one constructor that builds it, and they are as unrelated as two names that happen to be spelled alike.
`st` in `lifeT` is a third name again, and it is an argument, so writing it where the constructor was meant is caught as a name that does not exist: `:t st glider False` gives `[GHC-88464]`, `Variable not in scope: st :: Board -> Bool -> t`, and a suggested fix naming the data constructor `St`.
The compiler could say which name was meant because the capital is not a convention: it is what tells the two kinds of name apart.

## A record is a constructor with names on its fields

Chapter 8's state is the second declaration in that file:

```haskell
{{#include ../../../code/src/Chapters/Ch08.hs:st}}
```

Chapter 8 calls a record the familiar part, and it is: VHDL has records, and the generated `St_0` in chapter 9 is one with the same two fields under the same two names.
One thing about it is not familiar, and the chapter states it in half a sentence.
Each field name is also a function from the record to that field, so `board st` is an application like every other application in the file, and `board` goes where a function goes:

```
clashi> :t map board
map board :: Vec n St -> Vec n Board
```

There are three ways to write a value of that type down, and the book uses two of them without saying they are the same construct.
Chapter 8 writes `St b False`, which gives the fields in the order they were declared.
Chapter 9 writes the other way:

```haskell
{{#include ../../../code/src/Chapters/Ch09.hs:synthesize}}
```

`Synthesize` is a constructor with named fields, exactly as `St` is, and the compiler will say so:

```
clashi> :i Synthesize
type TopEntity :: Type
data TopEntity = Synthesize {...} | ...
  	-- Defined in ‘Clash.Annotations.TopEntity’
clashi> :i TestBench
type TopEntity :: Type
data TopEntity = ... | TestBench Language.Haskell.TH.Syntax.Name
  	-- Defined in ‘Clash.Annotations.TopEntity’
```

`TopEntity` is an ordinary `data` type with two constructors, declared in a library rather than in our file, and the two `:i` answers are the two halves of one declaration: `Synthesize` with its fields elided as `{...}`, and `TestBench` carrying a name, which is the annotation chapter 10 writes.
So chapter 9's annotation is not a syntax for annotations.
It is a value, built by naming three fields, and the reason to build it that way is what the positional form would have been: a string, a list and a name written in a row, with nothing on the page to say which of the three each one is.

Both forms build the same value, which the prompt will confirm on the type this book declared:

```
clashi> running (St { board = glider, running = False })
False
clashi> board (St { board = glider, running = False }) == glider
True
```

That is `St glider False` written the other way.
The third form is the one the book never uses and real code uses constantly:

```
clashi> running ((St glider False) { running = True })
True
clashi> board ((St glider False) { running = True }) == glider
True
```

`st { running = True }` is a value with one field replaced and the rest copied from `st`.
Nothing was updated: [an equation cannot be undone](purity.md#a-name-has-one-definition-and-nothing-can-give-it-a-second), so what that expression produces is a second `St` standing beside the first.
Chapter 8's `case` writes exactly that out by hand, and `St (board st) True` in the `Just Run` row is a copy of the state with the flag changed, spelled without the shorthand.

## What it costs

**A tag is as wide as the number of constructors, and the payload as wide as the widest.**
Chapter 8 counted sixty-six bits for a `Command` and said what pays for them: `Step`, `Run` and `Pause` carry nothing and are sixty-six bits all the same.
What that count is made of shows when the declaration grows.
Adding a fifth constructor to chapter 8's `Command`, one called `Clear` that carries nothing, and reloading, gives this:

```
clashi> pack Clear
0b100_...._...._...._...._...._...._...._...._...._...._...._...._...._...._...._....
```

Sixty-seven bits, and the extra one is in the tag, because five constructors do not fit in two bits.
Every command in the design got a bit wider, including the four that were there before and the three that carry nothing at all, and the port carrying a `Maybe Command` gets the bit too.
Chapter 9's generated file is where the other half of the price is visible: the payload is sliced out of the port and turned into a board on every cycle, on a line with no condition on it, and the selects above throw the board away when the tags disagree.
This is not a way of building a union that is cheaper than the one you would build by hand, and it was never going to be.

**Closure is a promise the compiler keeps and does not remind you about.**
That fifth constructor makes `lifeT`'s `case` incomplete, since `Just Clear` has no row.
Reloading answers `Ok, one module reloaded.` and nothing else, and the failure waits until something reaches it, where it is `Non-exhaustive patterns in case` at run time rather than a type error at the edit.
The project chapter 1 generates asks for the warning that would have caught it, so `stack build` reports it and the prompt does not, which is [where the two of them differ](pattern-matching.md#what-it-costs).
What the closed list guarantees is that nothing outside it can ever arrive.
What it does not do is find the places that have to change when the list grows.

**A field name is a name in the module, not a name in the record.**
`board` and `running` are ordinary top-level functions, which is what makes `board st` an application, and the price of that is that no other record in the module may use either name.
Declaring a second record with a `board` field in chapter 8's file stops it loading, with `[GHC-29916]`, `Multiple declarations of ‘board’` and a `Declared at:` naming both lines.
In VHDL a field name belongs to its record type and two records may both have a `board`, so this is a restriction that the reader will meet and did not have before.
It is a property of the language's defaults rather than of records: there is a way to ask GHC to relax it, and the project chapter 1 generates does not, which makes this a not currently and not a cannot.

## Where you met this

- Chapter 7, [An input that cannot be misread](../b/07-an-input.md): `Maybe Board`, a tag and a payload welded together, and `Just blinker` built with the constructor.
- Chapter 8, [More than valid](../b/08-more-than-valid.md): the declaration this page is about, `:i Load` and `:i Step`, the four tags read off `pack`, and `St` with its two named fields.
- Chapter 9, [An entity](../b/09-an-entity.md): a record built by naming its fields, and the payload decoded on every cycle whatever the tag says.
- Chapter 10, [A test bench that leaves Haskell](../b/10-a-test-bench.md): the other constructor of that same annotation type.
- Chapter 12, [One description, two sizes](../b/12-two-sizes.md): the same two declarations with a size variable in them.
