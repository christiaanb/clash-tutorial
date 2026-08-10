# Explanation pages: outlines

Twelve pages in the Diátaxis explanation mode (<https://diataxis.fr/explanation/>),
answering the questions the tutorial deliberately refuses to stop for. The
introduction promises them in so many words: "that belongs in an explanation, and
we link to one rather than stopping to argue the point." No page currently
redeems that promise; these are the outlines for the pages that will.

Reader: the Track B reader, mid-tutorial. Digital design background, no Haskell,
and — unlike a chapter's reader — *not doing anything right now*. They followed a
link because something worked and they want to know why. Explanation may assume
any chapter before the linking one has been done.

Placement, linking and the rules pages inherit are settled in D26. In brief:
pages live at `book/src/explanation/<slug>.md`, they enter `SUMMARY.md` under a
`# Explanation` part header only once written (no stubs ship), and each is linked
from a tutorial chapter with one sentence at the concept's first bare use,
usually in or immediately after a "Notice that" beat.

Every draft link sentence below is **indicative**, like the transcripts in
`01-track-b-outlines.md`: it shows the intended shape and placement, and it is
tuned (and broken one-sentence-per-line, per D14) when it lands in a chapter.

---

## What every page shares

**The shape.**

- The title is a question or a claim, never a keyword. "Why a two-input function
  has three arrows", not "Currying".
- The opening paragraph names the moment in the tutorial where the reader met
  the thing, and quotes it. Motivate first; never open with a definition (voice
  guide, Part 2).
- The body may state claims, weigh alternatives and argue — that is the licence
  explanation has and a chapter does not (D1, D20). The voice rules still bind:
  every advantage is followed by its cost in its own sentence, "cannot" is kept
  separate from "not currently", numbers are concrete, punctuation is restricted.
- The page closes with a short "Where you met this" list linking back to each
  chapter location in the page's linked-from table. It is the reverse index of
  the links pointing in.

**What a page owes.** The book-wide rules apply unchanged: one sentence per line
(D14), the name D18 keeps out of the book stays out (a grep of `book/` and this
file must stay empty), the operator spelling of `fmap` is never typed, and
nothing ships that has not been run. Pages prefer code pulled from existing
`code/` anchors (`glider`, `from-rows`, `neighbour-counts`, `life-t`, `command`,
`st`, `test-bench` and the rest already exist) and quotations of transcripts
already captured for the chapters. A page that wants a *new* REPL demonstration
marks it `<!-- UNVERIFIED: ... -->` and adds a queue entry, exactly as a chapter
would. The outlines below are written so that a first draft of every page needs
no new capture.

**What a page must not do.** It must not become a how-to (no "if you want X, do
Y"), must not become reference (no tables of methods or flags), and must not
teach translation: the phrasebook stays out (voice guide, Part 3), even though
every page may and should use one VHDL contrast to land its point.

**Deferred, on purpose.** Two pages the design docs already earmark are not in
this batch, so that this set stays about reading Haskell rather than designing
circuits. They remain owed:

- The `fold` depth argument — chain versus tree, and what it costs in logic
  depth. D9 moved it here when chapter 12 was replaced: "stated rather than
  discovered."
- The VHDL-to-Clash rosetta stone, which the voice guide banishes from chapters
  and assigns to "a linked explanation page."

---

## `currying.md`: Why a two-input function has three arrows

**Question answered.** Why is `plus`'s type `Signed 8 -> Signed 8 -> Signed 8`
and not something shaped like a port list, and why is `plus 3` a legal thing to
have?

**The misreading.** A VHDL reader sees a function type as a signature: inputs on
one side, output on the other, all-or-nothing. They will read the arrow chain as
odd punctuation for that, and then `plus 3`, `life glider` and
`exposeClockResetEnable (life glider)` each look like errors that somehow
compile.

**Beats.**

- Every function takes exactly one argument. `plus 3 5` is two applications, not
  one call with two operands; the arrows associate to make that work.
- What `plus 3` *is*: a component with one port already tied off. The chapter 1
  beat ("something that still wants a `Signed 8`") restated as the general rule.
- Definition by equation: `plus a b = a + b` is not a procedure body, and there
  is no return statement because the right-hand side *is* the value.
- Dropping arguments from both sides: `fromRows = map unpack` and
  `life8 = life glider` are the same definitions with the last argument unwritten
  on both sides of the `=`. Why that is legal follows from one-at-a-time.
- Several names under one signature (`shiftN, shiftS, shiftW, shiftE ::
  Board -> Board`) as plain shorthand.
- The cost, stated honestly: argument-order mistakes typecheck further than they
  would in VHDL, and the error surfaces at a distance from the mistake.

**Absorbs.** Primed names: `st'` and `outputVerifier'` contain an ordinary
name character, not an operator.

**Material.** Ch01 anchor and chapter 1's captured `:t plus 3` transcript; Ch03
`from-rows`; Ch12 `life8`.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/01-the-instrument.md` | "Notice that", the `plus 3` beat | Why one argument at a time is enough, and why the type has three arrows, is explained in [Why a two-input function has three arrows](../explanation/currying.md). |
| `b/03-a-board.md` | "Notice that", the `fromRows` beat | (secondary, add only if the ch1 link proves too early) |
| `b/13-hidden.md` | "Where the three come back" | (secondary: `exposeClockResetEnable` in front of "the argument it already had") |

---

## `higher-order.md`: The thing you instantiate is an argument

**Question answered.** What kind of thing is `map`, if `map unpack` passes
`unpack` to it rather than calling it — and how far does that idea go?

**The misreading.** `for … generate` is a language construct in VHDL: it can
only appear in one place, and what it instantiates is written inside it. The
reader will look for the construct and find a function, and will read
`zipWith (zipWith (+))` as nested calls rather than a description built from
parts.

**Beats.**

- Chapter 4's beat, generalised: `map` over a `Vec 8` is eight instances in
  space, and the thing to instantiate arrives as an argument. A function that
  takes a function is ordinary, not a feature.
- A lambda is a function without a name, written where it is needed:
  `\r -> rotateLeftS r d1` from chapter 4, and the `\b -> putStr (render b)`
  typed at the prompt since chapter 6.
- `(+)` in parentheses is the adder *itself*, passed rather than applied. One
  `+`, sixty-four adders: the whole of chapter 4's tree hangs on this one token,
  and the chapter never says so.
- `foldl1 addCounts` reads the same way: a vector, and a way to combine two
  elements, handed over. (The depth of what `fold` builds is a different page,
  still owed: see the deferred list.)
- `mealy` receives the entire register-to-register loop as one argument, which
  is why its signature has a parenthesised arrow type inside it:
  `(s -> i -> (s, o))`. Same idea as `map`'s first argument, scaled up.
- The cost: a higher-order description has no fixed shape to point at in the
  source, and the netlist only takes shape when the arguments land.

**Material.** Ch04 `shifts`, `add-counts`, `count-board`; Ch07 `life-t`; chapter
4's captured transcripts.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/04-neighbours.md` | "Adding the copies up", after the "one `+` in that line" sentence | What it means to hand `(+)` to `zipWith`, and why a function that takes a function is the ordinary case here, is explained in [The thing you instantiate is an argument](../explanation/higher-order.md). |
| `b/03-a-board.md` | "Notice that", the `map unpack` beat | (secondary: the first function passed to a function) |
| `b/07-an-input.md` | "A function of a state and an input" | (secondary: `mealy`'s function-shaped argument) |

---

## `polymorphism.md`: What the lowercase letters in a type mean

**Question answered.** In `rotateLeftS :: KnownNat n => Vec n a -> SNat d ->
Vec n a`, what are `n`, `a` and `d` — and what happens to a definition written
in terms of them when hardware has to come out?

**The misreading.** The reader meets `Vec n a` in chapter 4 and has nothing to
map it to: VHDL's unconstrained arrays and generics are close but both are
declared, loudly. They will not guess that an undeclared lowercase name is a
variable ranging over types, and they consume such signatures for eight chapters
before chapter 12 has them write one.

**Beats.**

- A lowercase name in a type is a variable; a capitalised name is a constant.
  `Vec n a` is every vector type at once, and `Vec 8 Bool` is what it becomes
  when both variables are filled in.
- Reading a library signature by instantiating it mentally: `mealy`'s `s`, `i`,
  `o` become `St`, `Maybe Command`, `Board` at chapter 8's use site. Worked in
  full on the page, since the chapters never do it on paper.
- The same letter twice is a promise: the two `Vec n a` in `rotateLeftS` have
  the same length, and the compiler holds it.
- What synthesis does with a variable: nothing. A polymorphic function is not a
  component until something fixes its size (chapter 12's sentence, now argued):
  Clash specialises — one entity per size actually used — where a VHDL generic
  parameterises one entity. Must stay consistent with D24 and chapter 12's
  shipped prose.
- The cost, from chapter 12: two sizes cost two of everything below the
  description, and nothing is shared in the netlist.

**Material.** Chapter 4's captured `:i rotateLeftS`, chapter 7's `:i mealy`,
Ch12 `life8`/`life16`; chapter 12's generated-VHDL evidence.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/04-neighbours.md` | "Moving the whole board", after the `:i rotateLeftS` transcript | What the lowercase `n`, `a` and `d` in that signature are is explained in [What the lowercase letters in a type mean](../explanation/polymorphism.md). |
| `b/07-an-input.md` | "A function of a state and an input" | (secondary: instantiating `s`, `i`, `o`) |
| `b/12-two-sizes.md` | "The same description, twice" | (secondary: specialisation versus generics, argued rather than shown) |

---

## `type-classes.md`: Constraints are arguments the compiler writes

**Question answered.** What is everything to the left of a `=>` — and what is
the machinery behind `deriving`, behind a bare `1` becoming an `Unsigned 4`, and
behind chapter 13's `HiddenClockResetEnable`?

**The misreading.** VHDL has nothing in this shape at all. The reader has been
walking past `=>` since chapter 4 on the tutorial's instruction ("requirements
the compiler settles on its own"), and chapter 13 closes by admitting the debt:
what a constraint *is* "takes another question to answer." This page is that
answer, and it is the largest single gap the tutorial leaves.

**Beats.**

- A type class is a promise of operations; an instance is a type keeping that
  promise. `instance Generic St` — printed by `:i` in chapter 8 with the word
  never defined — read aloud: the compiler wrote down that `St` keeps
  `Generic`'s promise.
- `=>` versus `->`: what is left of `=>` is not an input, it is a requirement,
  and the caller does not supply it — the compiler proves it and passes the
  evidence. A constraint is an argument you do not write.
- That is why a constraint can carry a *value*: `KnownNat n` delivers the number
  `n` at runtime, and `HiddenClockResetEnable System` delivers three wires.
  Chapter 13's "the constraint is how they reach it" is literal.
- Numeric literals: `1` has no type of its own; `Num` is the class that turns it
  into whatever the context asks for, which is how the same `1` was an
  `Unsigned 4` in chapter 2 and a count in chapter 4. Chapter 4's error —
  "`SNat` is not a `Num`, which is true and no help at all" — decoded: it means
  no instance, so no conversion.
- `deriving` asks the compiler to write instances instead of us; chapter 8's
  five, one clause each (the chapter's own glosses, now connected to the
  mechanism). Chapter 12's standalone `deriving instance KnownNat n => BitPack
  (Command n)` is the same request made where a constraint has somewhere to
  stand.
- `fmap` is a class method: one name, many shapes, instance chosen by type —
  which is why the same `fmap` worked on a `Signal` in chapter 6 and would work
  elsewhere.
- The cost: an unsatisfied constraint produces the least local error messages in
  the language, and the compiler's suggestion (chapter 12: "its message suggests
  the words to add") is the practical tool.

**Material.** Chapter 6's captured `:i register`, chapter 8's `:i St` and
`pack` transcripts, Ch08 `st`/`command`, Ch12's standalone-deriving anchor,
Ch13 `life`.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/06-it-runs.md` | "What a register wants", after the "settles on its own" sentence | What the two requirements are, and what a constraint is generally, is explained in [Constraints are arguments the compiler writes](../explanation/type-classes.md). |
| `b/08-more-than-valid.md` | "A state with a mode in it", after the `instance` lines | (secondary: classes, instances and `deriving`) |
| `b/13-hidden.md` | "Notice that", the closing beat that concedes the question | (secondary, and the payoff: `HiddenClockResetEnable` as a value-carrying constraint) |

---

## `type-inference.md`: How the compiler knows a type you did not write

**Question answered.** Every definition in a `where` clause in the whole book is
unsigned, and in chapter 3 a signature written on `fromRows` decided what
`unpack` does. Who is working all this out, and from what?

**The misreading.** In VHDL every object is declared before use, so the reader
will assume the unsigned bindings are defaulted (dangerous) or dynamically typed
(wrong). They have no model for information flowing *backwards* from a result
type into an expression.

**Beats.**

- Inference is reconstruction, not guessing: the compiler solves for the one
  type that makes every use consistent, and rejects the program if there is none
  or more than one candidate survives.
- Direction does not matter. Chapter 3's beat — the result is a `Board`, "and
  that is enough for the compiler to know which unpacking is meant" — is
  information flowing from a signature into `unpack`, right to left.
- The same flow types every literal (`toCount x = if x then 1 else 0` lands at
  `Unsigned 4` because `Counts` says so) and is what lets `numConvert` check at
  compile time that nothing is lost.
- Why the tutorial still writes every top-level signature (and the project
  requires it): a signature is the port list, and it pins where an error is
  reported. Inferred types move; declared types are contracts. The `where`
  bindings go unsigned because their types are forced by the signed thing they
  serve.
- What it looks like when nothing forces a choice: chapter 7's
  `fromList [...] :: Signal dom (Maybe Board)` printed with `dom` still open.
- The cost: a wrong definition with no signature produces a *correctly inferred
  wrong type*, and the error appears at the use site instead of the mistake.

**Material.** Chapter 3's captured `:i` transcripts; Ch04 `counting` and
`render-counts`; chapter 7's captured `:t fromList` output.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/03-a-board.md` | "Notice that", the `unpack` beat | How a signature written on `fromRows` can decide what `unpack` does is explained in [How the compiler knows a type you did not write](../explanation/type-inference.md). |
| `b/04-neighbours.md` | "All sixty-four at once", at the unsigned `where` bindings | (secondary: why local definitions carry no signatures) |

---

## `type-level-numbers.md`: Two worlds of numbers

**Question answered.** The `8` in `Vec 8` cannot be added to anything, `1` will
not do where `d1` is wanted, and chapter 10's `outputVerifier'` demands
`1 <= l` in a place where types go. How many kinds of number are there, and
which one is which?

**The misreading.** VHDL has one integer world; `natural range <>` and a port
value live in the same universe. The reader will treat `Signed 8`'s `8`, `d1`
and a term-level `1` as the same thing spelled inconsistently, and chapter 4
pre-flags exactly this mistake without being able to say why it is one.

**Beats.**

- Two worlds: numbers in types (the `8` in `Signed 8` and `Vec 8`, checked at
  compile time, gone by run time) and numbers in values (what wires carry).
  They never mix silently.
- `SNat` is the bridge, and `d1` is how the type-level `1` is named in a place
  where a value is expected. The chapter 4 error, restated from the other side:
  `1` is a value, the slot wants a compile-time number, and no `Num` instance
  can cross that gap.
- `KnownNat n` is the other direction of the same bridge: it hands the value of
  a type-level `n` back down, which is why `rotateLeftS` needs it (it must count)
  and `map` does not (chapter 12's beat: it never asks how many).
- Arithmetic and predicates happen up there too: chapter 12's bus is
  `n * n + 2` wide, and `1 <= l` in `outputVerifier'`'s signature is a
  requirement on a number no wire ever carries.
- The `:i` output the reader has seen since chapter 3, decoded: `type Board ::
  Type` is a statement about what kind of thing `Board` is, and `Vec`'s kind
  says it wants one number and one type.
- The cost: errors from this machinery talk about types, not wires, and chapter
  12's `solveWanteds` message is the worst the tutorial meets.

**Material.** Chapter 3's `:i Board` transcript, chapter 4's `:i rotateLeftS`,
chapter 10's `:i outputVerifier'`, chapter 12's captured error; Ch12 anchors.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/04-neighbours.md` | "Moving the whole board", after the `SNat`/`d1` paragraph | Why there are two kinds of number here, and why no `1` can stand where a `d1` is wanted, is explained in [Two worlds of numbers](../explanation/type-level-numbers.md). |
| `b/03-a-board.md` | "Three questions and a row", the `type Board :: Type` line | (secondary: what the kind line says) |
| `b/10-a-test-bench.md` | "A test bench, in Haskell", the `outputVerifier'` signature | (secondary: `1 <= l` as a type-level requirement) |
| `b/12-two-sizes.md` | "A number the type takes" | (secondary: `KnownNat` as the bridge down) |

---

## `pattern-matching.md`: A case expression is a multiplexer

**Question answered.** What exactly is the construct chapter 2 called a truth
table — what may appear left of a `->`, what is `_`, and why does the whole
thing have a value?

**The misreading.** VHDL's `case` is a statement inside a process, its choices
must be exclusive and complete, and it assigns. The reader has been told the
exclusivity difference (chapter 2's beat); what they have not been told is that
`case` is an *expression*, that the rows are patterns with binding power, and
that the parenthesised things they have been matching on since chapter 2 are a
data structure.

**Beats.**

- An expression, not a statement: a `case` *is* its selected value, which is why
  it can sit on the right of an `=` and why every row must produce the same
  type. In hardware terms it is the multiplexer, not the process around one.
- A pattern is a shape with holes: literals match themselves, `_` matches
  anything and binds nothing, a lowercase name matches anything and binds it.
  Chapter 7's beat (`Just seed` "tests the tag and names the payload in the same
  expression") is the general mechanism, not a `Maybe` feature.
- Nesting composes: chapter 8's `Just (Load b)` is two tests and a binding in
  one row, and order still decides — first match wins, and the wildcard rows do
  real work.
- Tuples, named at last: `(alive, n)` builds an anonymous product so that one
  `case` can inspect two things, and `lifeT`'s `(next, current)` returns two
  results the same way. The parentheses-and-comma type is the same shape at the
  term and type level, and `mealy`'s `(s, o)` now reads.
- `if then else` as the two-row special case: both branches mandatory, same
  type, because an expression must have a value. Chapter 8's `else st` (keep the
  state) is the idiom that replaces "no assignment in this branch".
- The cost: nothing checks completeness for you by default here, and a
  fall-through wildcard silences the compiler's ability to warn.

**Material.** Ch02 `next-cell`, Ch07 `life-t`, Ch08 `life-t`; chapter 2's six
captured evaluations.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/02-a-cell.md` | "Notice that", after the first-match-wins beat | What kind of construct this is, and what may stand left of a `->`, is explained in [A case expression is a multiplexer](../explanation/pattern-matching.md). |
| `b/07-an-input.md` | "A function of a state and an input", the `Just seed` beat | (secondary: patterns that bind) |
| `b/08-more-than-valid.md` | "One row per command", the `Just (Load b)` row | (secondary: nested patterns) |

---

## `data-types.md`: A type that lists every value it can have

**Question answered.** What did `data Command = Load Board | Step | Run | Pause`
actually declare, how is `Maybe` the same thing, and why do records get built
two different ways in chapters 8 and 9?

**The misreading.** The reader will map `data` onto a VHDL enumeration plus a
record plus a discriminant convention, three things they keep in step by hand.
Chapter 8 shows them fused; this page says what the fusion is and what it rules
out.

**Beats.**

- A `data` declaration is closed: it lists every value, and "there is no fifth
  thing for one to be" (chapter 8) is a property the compiler enforces
  everywhere the type is used, not a comment.
- Constructors are the only way in: `Load` is a function that wants a `Board`,
  the other three are values already, and chapter 1's `plus 3` intuition covers
  a partially applied constructor too.
- `Maybe` is not special: `data Maybe a = Nothing | Just a` is two constructors
  and a variable, and chapter 7's valid-bit reading falls out of the shape.
- The capitalisation rule as the reader's compass: `Step` and `step`, `St` the
  type and `St` the constructor and `st` the variable — one chapter 8 beat,
  generalised to every name in the book since `True`.
- Records: fields are named, each field name is also the function that reads it,
  and there are two ways to build — positional (`St b False`, chapter 8) and by
  field name (`Synthesize { t_name = ... }`, chapter 9, never connected to the
  first). Also the third form the book never uses and real code will:
  `st { running = True }` builds a copy with one field changed.
- The cost, chapter 8's own: a sum is as wide as its widest constructor plus the
  tag, and nothing is switched off.

**Material.** Ch08 `command` and `st`, Ch09 `synthesize`, Ch07 `blinker`;
chapter 8's `:i Load` and `pack` transcripts.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/08-more-than-valid.md` | "Four things the outside can say", end of the section | What a `data` declaration is, and why nothing outside its list can ever turn up on the wires, is explained in [A type that lists every value it can have](../explanation/data-types.md). |
| `b/07-an-input.md` | "An input with its valid bit inside it" | (secondary: `Maybe` as an ordinary `data` type) |
| `b/09-an-entity.md` | "Naming the entity, and naming its ports", the `Synthesize { ... }` block | (secondary: building a record by field name) |

---

## `purity.md`: One value, read in two places

**Question answered.** Chapter 5 said `b` appearing twice is "one board read in
two places, not two boards." What rule makes that safe, and what does the
language give up to have it?

**The misreading.** In an imperative model a name can change under you, so
reading it twice is a hazard and copying is protection. The reader's habits
around aliasing, evaluation order and "when does this run" all assume mutation,
and none of them apply.

**Beats.**

- A definition is an equation: the name and the right-hand side are
  interchangeable, always, because nothing can reassign. That is the whole rule,
  and everything else on the page is consequence.
- Fan-out for free: `b` twice in chapter 5's `step`, `board st` in five rows of
  chapter 8's `case` — one register, many readers, no copies and no hazard.
- Order stops mattering: with no assignment there is nothing to sequence, which
  is why `step (step b)` is two blocks in series and never two cycles, and why a
  `where` clause is a set of equations rather than a script (taken further on
  the [self-reference](laziness.md) page).
- The equation survives substitution the other way too: chapter 13 replaces a
  name with its definition and the netlist is byte-identical, which is the
  property doing the work.
- The cost: state must now be somewhere explicit. The language's answer is
  chapter 7's — state is a value threaded through a function — and `mealy` is
  that answer packaged.

**Material.** Ch05 `step`, Ch08 `life-t`; chapter 13's diff evidence (already
captured for D25).

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/05-a-generation.md` | "One line", after the "one board read in two places" sentence | Why reading `b` twice is safe, here and everywhere, is explained in [One value, read in two places](../explanation/purity.md). |
| `b/08-more-than-valid.md` | "One row per command" | (secondary: `board st` in five rows, one register) |

---

## `laziness.md`: A definition that refers to itself

**Question answered.** Chapter 6 defines `boards` using `boards` and calls it a
feedback path. Chapter 10 defines `clk` using `done` and `done` using `clk`.
Why does the compiler accept either, and in what order does any of it happen?

**The misreading.** Read as statements, both definitions are uses of a variable
before it exists; a VHDL reader may instead reach for delta cycles and
elaboration order, which are closer but still wrong. The missing idea is that
bindings are equations solved together, not steps executed in order.

**Beats.**

- A `where` clause is simultaneous: chapter 10's `commands` uses `clk` defined
  two lines below it, and nothing about that is forward-reference trickery.
  Layout (the indentation rule) says what belongs to the clause; it says nothing
  about order.
- A recursive equation defines a fixed point: `boards = register ... (fmap step
  boards)` names the one signal equal to a register of its own stepped self.
  The wire metaphor from chapter 6 is exact, and this is why.
- Why it does not run away: nothing is computed until something asks. `sampleN
  5` asks for five cycles, so five cycles exist; the same `boards` typed bare
  "prints until you stop it" because printing never stops asking.
- `register` makes the knot productive: each demanded cycle needs only the
  *previous* one, and the initial value starts the chain. A self-reference with
  no register in the loop is the combinational loop it looks like, and it hangs
  the simulation rather than erroring — the sharp edge, stated plainly.
- Chapter 10's `clk`/`done` knot as the two-equation case: a clock that runs
  until the verifier says stop, written as mutual definition, resolved the same
  way.
- The cost: "when does this compute" has no simple answer under laziness, and
  reasoning about simulation performance needs tools the tutorial does not use.

**Material.** Ch06 `life`, Ch10 `test-bench`; chapter 6's endless-print beat and
chapter 10's captured transcripts.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/06-it-runs.md` | "Notice that", the feedback beat | Why a definition may use itself, and what decides how much of it ever runs, is explained in [A definition that refers to itself](../explanation/laziness.md). |
| `b/10-a-test-bench.md` | "A test bench, in Haskell", at the `where` block | (secondary: mutual definition, and order-independence inside `where`) |

---

## `vec-and-lists.md`: A Vec is not a list

**Question answered.** The reader has typed `:>` and `Nil` since chapter 3
without either being named, and has met `toList`, `fromList` and things printed
in square brackets. How many sequence types are in play, and which functions
belong to which?

**The misreading.** One collection type is the default assumption, and every
Haskell resource the reader searches will describe the *other* one: list
functions from the standard prelude, of which Clash's `map`, `zipWith`,
`foldl1` and `head` are the length-indexed namesakes. This is the page that
keeps self-study from silently contradicting the tutorial.

**Beats.**

- `:>` and `Nil` are `Vec`'s constructors, exactly as `Just` is `Maybe`'s:
  data, not syntax. `:>` associates to the right, which is why eight of them
  need no parentheses.
- `Vec n a` carries its length in its type (chapter 3's beat: "a length is in
  the type, and it is checked"); `[a]` does not, and a `String` is `[Char]`.
  One is hardware, the other is bookkeeping around it.
- Why hardware gets the checked one: a wire count is not allowed to be a
  surprise. The cost runs the other way — a `Vec`'s length can never depend on
  run-time data, and that is a cannot, not a not-currently.
- The bridges, named: `toList` (chapter 3, into `unlines`) drops the length to
  cross into printing; `fromList` (chapter 7) climbs the other way for
  simulation, and `sampleN`'s result is a list because how many you sample is
  not the circuit's business.
- Which `map` is this: the prelude the project imports replaces the standard
  one, so the vector functions arrive under the familiar names, and search
  results for "Haskell map" describe the list cousin. Import lists like
  `import Data.Char (intToDigit)` are how single names are borrowed.
- Square brackets in what the prompt prints (`[Board]`, chapter 6) versus angle
  output for `Vec` (`<...>` never appears; `:>` chains do) — reading each on
  sight.

**Absorbs.** Import-list syntax; the prelude-replacement note.

**Material.** Ch03 `glider` and `render`, Ch07 `blinker`; chapter 3's captured
`head glider` output, chapter 6's `sampleN` transcript.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/03-a-board.md` | "A seed you can read", after the `glider` block | What `:>` and `Nil` are, and how this vector differs from the lists Haskell resources talk about, is explained in [A Vec is not a list](../explanation/vec-and-lists.md). |
| `b/06-it-runs.md` | "Five cycles", the `sampleN` result | (secondary: why sampling produces a list) |
| `b/07-an-input.md` | "Seven cycles", at `fromList` | (secondary: the bridge in the other direction) |

---

## `simulation-and-synthesis.md`: What runs, and what is hardware

**Question answered.** The tutorial keeps a border the chapters state one rule
at a time: a `String` is not a circuit, three generators are typed as ritual,
`fromList` "belongs to simulation", part of the test bench sits between
`translate_off` pragmas. What is the single model behind all of those rules?

**The misreading.** VHDL puts simulation and synthesis in one language and one
file, separated by tool conventions and pragma folklore. The reader will assume
the same here — and here the border is a *type* border, checkable, with `Signal`
and `IO` marking the sides.

**Beats.**

- Three layers, one file: pure functions of values (`step`; becomes logic),
  signals (`life`; becomes logic with registers), and the code that pokes
  signals from outside (`sampleN`, the generators, `fromList`, printing; becomes
  nothing).
- The prompt line read at last: `mapM_ (\b -> putStr (render b)) (...)` — the
  most-retyped line in the book — decomposed clause by clause. `putStr` is an
  action, not a function returning text; `mapM_` runs one action per element and
  keeps no results, and the underscore in its name says so.
- Actions are values too, of type `IO`: which is how the border stays a type
  border, and why nothing marked `IO` can end up in the VHDL.
- The generators (`systemClockGen`, `resetGen`, `enableGen`) are the simulator
  standing where a board will stand: chapter 11's reveal (the enable was a
  constant all along) is this model paying off.
- Where the border prints: chapter 10's test bench is a circuit on purpose, and
  what is not a circuit is exactly what sits between `translate_off` and
  `translate_on`. The `'life` in the `TestBench` annotation is a quoted *name* —
  a reference to the binder, not a call — which is why one `:vhdl` finds both.
- Undefined values live on the simulation side of the border: the `.` bits of
  chapter 8, the `-` in chapter 10's VHDL, `ShowX` in `outputVerifier'`'s
  signature, and the 257 time-zero warnings NVC is told to suppress are one
  phenomenon wearing four coats.
- The cost: two of the layers look identical on the page (both are Haskell), and
  the type is the only thing that says which side a definition is on.

**Material.** Ch06 `life`, Ch10 `test-bench` and the captured generated-VHDL
excerpts, chapter 8's `pack` transcript, chapter 10's NVC transcript.

**Linked from.**

| Chapter | Where | Draft sentence |
|---|---|---|
| `b/06-it-runs.md` | "Five cycles", after the ritual sentence | What the three generators and `mapM_` are, and where the border between simulation and hardware runs, is explained in [What runs, and what is hardware](../explanation/simulation-and-synthesis.md). |
| `b/03-a-board.md` | "Notice that", the "a `String` is not a circuit" beat | (secondary: the border's first appearance) |
| `b/10-a-test-bench.md` | "What the test bench turned into", the `translate_off` sentence | (secondary: the border, printed in the VHDL) |

---

## Coverage check

Every concept the chapter scan rated blocking or central maps to exactly one
page:

| Concept | Page |
|---|---|
| Arrow chains, partial application, point-free | `currying.md` |
| `map`/`zipWith`/`foldl1`, lambdas, sections, `mealy`'s argument | `higher-order.md` |
| Type variables, reading library signatures, specialisation | `polymorphism.md` |
| Classes, instances, `=>`, `deriving`, literals, `KnownNat`/hidden as evidence | `type-classes.md` |
| Unsigned `where` bindings, backwards flow, `unpack`'s choice | `type-inference.md` |
| `Signed 8`/`Vec 8`, `SNat`/`d1`, kinds, `n * n + 2`, `1 <= l` | `type-level-numbers.md` |
| `case` as expression, patterns, tuples, `if` | `pattern-matching.md` |
| Sums, `Maybe`, constructors, capitalisation, records | `data-types.md` |
| Sharing, substitution, series-not-cycles | `purity.md` |
| Self-reference, mutual reference, `where` order, demand | `laziness.md` |
| `:>`/`Nil`, `Vec` versus list, bridges, which prelude | `vec-and-lists.md` |
| IO, `mapM_`, generators, `translate_off`, undefined bits, `'life` | `simulation-and-synthesis.md` |

Orphans distributed: primed names → `currying.md`; import lists and the prelude
note → `vec-and-lists.md`; kind signatures → `type-level-numbers.md`; the quoted
name → `simulation-and-synthesis.md`. Binary literals need no page: chapter 3
already glosses them at the point of use.

`Signal` itself gets no page: chapter 6's treatment was rated the strongest in
the book, and a page would restate it. The `fmap`-as-class-method thread lands
in `type-classes.md` instead.

## Suggested writing order

Dependency-light pages first, the two the chapters lean on hardest last, so the
links can land chapter by chapter from the front of the book:

1. `currying.md`, `pattern-matching.md`, `vec-and-lists.md` (unlock chapters 1–3)
2. `higher-order.md`, `type-inference.md`, `type-level-numbers.md`,
   `polymorphism.md` (unlock chapter 4)
3. `purity.md`, `laziness.md`, `data-types.md` (chapters 5–8)
4. `type-classes.md`, `simulation-and-synthesis.md` (the two big ones; they may
   cross-link to everything above)

One page per branch and pull request, like chapters. Inserting a page's link
sentences into shipped chapters happens in the same PR as the page, so no link
ever points at nothing.
