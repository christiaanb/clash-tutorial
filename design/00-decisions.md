# Decisions

Each entry records what was decided and why. Reopening one is allowed; doing it
silently is not.

---

## D1. Diátaxis, strictly

The document is a tutorial in the Diátaxis sense: the reader learns by doing,
under the guidance of the author, and every step produces a result they can see.
It is not a how-to guide, reference or explanation, and material belonging to
those modes is moved out rather than annotated.

Consequences that bite in practice: no alternatives, no troubleshooting sections,
ruthlessly minimal explanation, and no step that fails.

---

## D2. Two tracks, Track B first

- **Track B**: hardware background (VHDL or SystemVerilog), no Haskell. Primary.
- **Track A**: neither background. A scaffolding variant, written later.

Both tracks lack Haskell, so the difference between them is digital design, not
the language. Track A adds a short prologue and denser step granularity; it does
not change the artifact or the chapter boundaries.

The honest cost: Track A roughly doubles authoring effort for the population least
likely to become Clash users. If the budget is one track, Track B is the one that
ships.

---

## D3. Artifact: Conway's Life on an 8×8 grid, with a command input

Chosen over a seven-segment display spine and a UART transmitter because:

- It prints as ASCII from `sampleN` immediately, so results are visible from the
  first working version without hardware.
- It needs `Vec` of `Vec`, `map`, `zipWith`, pattern matching, registers and
  feedback, and nothing else.
- Sixty-four instantiations of one combinational function is the Clash argument
  made physical rather than rhetorical.
- A known start state has a known state after *n* generations, so the test bench
  writes itself.

The weakness — no input ports, a thin top entity — is fixed by the command input,
which restores the port interface and carries the algebraic data type lesson.

Life is not useful for anything. It does not need to be useful, it needs to be
*representative*, and an array of identical combinational cells with a control
FSM, a valid-signalled input and a scanned output is the shape of a great many
real designs. Say this once in the introduction and do not defend it again.

---

## D4. `Clash.Explicit.Prelude` throughout, hidden prelude as chapter 13

Explicit clock, reset and enable for chapters 1–12; chapter 13 switches to
`Clash.Prelude` as an exercise the reader performs.

In favour of explicit:

- `:i register` returns something actionable. Under `Clash.Prelude` it leads to
  `HiddenClockResetEnable`, which bottoms out in implicit parameters — a reader
  sees `?clk :: Clock dom` and cannot parse or search for it. Since `:i` is the
  reader's primary instrument, that is a broken promise.
- Errors degrade to ordinary type errors instead of unresolved constraints.
- It removes `@System` type applications from the tutorial entirely: the domain is
  fixed by passing `systemClockGen`, an ordinary value.
- The top of the design stops being a discontinuity. No `exposeClockResetEnable`
  appearing once and doing something invisible: the entity's ports are the
  arguments the function already had.
- One style end to end. `Clash.Explicit.Testbench` is used either way, so the
  hidden route forces a style switch mid-tutorial.
- It keeps chapter 1's promise that nothing is inferred behind the reader's back.

Against it, and the reason chapter 13 exists: the explicit style is not what the
reader will meet in any real Clash project, the plumbing compounds with hierarchy,
and `enableGen` is pure ritual. Chapter 13 pays that debt by having the reader
make the switch themselves and diff the generated VHDL.

Explicit narrows the bad-error surface; it does not eliminate it. `KnownDomain`
and `NFDataX` still appear.

**Shipped 2026-08-09, and the claim held in the form it was made.** Chapter 13's
diff is in V35: the two entity declarations are byte identical between the
chapters, both `step` entities and the whole test bench directory are byte
identical, and the four files that differ do so in generated identifiers. So
"notation, not semantics" is something the reader watches rather than something
this entry asserts. Two things it did not anticipate are in D25, and one number
is worth recording here because it is the honest size of the win in this design:
the reader's file goes from 219 lines to 218. The plumbing compounds with
hierarchy and this design has one level of it, so chapter 13 shows the shape of
the saving and says plainly that the size of it is one line.

---

## D5. Simulator: NVC, not GHDL

NVC 1.20.1. Windows installer on the releases page and `winget install
NickGasson.NVC`; `brew install nvc` on macOS. Linux may require
`configure`/`make`, which this audience is used to and Windows users are not.

The single-command form `nvc -a … -e testBench -r` gives one command and one
result. NVC states plainly that it is not a synthesizer, which usefully draws the
line between the test bench chapter and the optional board chapter.

---

## D6. Waveform viewing: Surfer's browser build

`https://app.surfer-project.org/`. No install, and the reader is already in a
browser. The dependency is isolated to one chapter, so if it becomes unavailable
one chapter degrades rather than the spine.

The waveform is its own chapter, not folded into the test bench chapter, so the
reliable binary result (it passes) does not depend on a third-party web
application.

Division of labour: the REPL shows the data (64 cells as ASCII), the waveform
shows the control (clock, reset, command bus). The command bus is where the reader
*sees* the algebraic data type as a tag and a payload.

---

## D7. Installation: Stack, and a dedicated project template

The reader uses Stack. One invocation, no Cabal alternative offered.

A dedicated template lives in `template/clash-tutorial.hsfiles` so that we control
what the reader's project turns on — originally `default-extensions`, and
specifically `NumericUnderscores`, which the seed literals depend on for
legibility. That particular extension now arrives with the language edition
instead (D19), which does not weaken the argument: the template is still the only
thing that fixes the edition, the type-level solver plugins, the pinned
`extra-deps` and the flags `bin/Clashi.hs` passes.

**Mirroring requirement.** Stack resolves `username/template-name` to a repository
literally named `stack-templates` under that username. So `stack new life
christiaanb/clash-tutorial` requires the file at
`github.com/christiaanb/stack-templates/clash-tutorial.hsfiles`. The source of
truth stays in this repository; CI mirrors it. The alternative is a raw
`githubusercontent.com` URL in chapter 1's first command, which is long, ugly and
the first thing the reader ever types.

---

## D8. Module name stays `Example.Project`

Matches `clash-starters`, so file paths in existing how-to guides and blog posts
transfer to the reader's project unchanged. The cost is that the reader writes a
Game of Life in a module called `Example.Project`. Mildly absurd, entirely
survivable, and a five-minute change if you disagree.

The original entry claimed the reader also sees `*Example.Project>` as their prompt
for thirteen chapters. They do not: the prompt is `clashi>`. See D12.

---

## D9. Chapter 12 replaced — `foldl1` versus `fold` is out

**Superseded decision.** The original chapter 12 had the reader replace `foldl1`
with `fold` in the neighbour summation, turning a seven-deep adder chain into a
three-deep tree, and observe the difference in the generated VHDL.

**Why it is out.** The difference is very hard to see. Clash emits the fold as
nested expressions rather than distinguishable structure, and without a synthesis
tool in the spine there is nothing that reports path depth. Asking a reader to
look for a difference they cannot find is worse than not making the point.

**Replacement: "One description, two sizes".** Make the board size a type
parameter and generate two entities from one description — 8×8 and 16×16 — with
visibly different port widths in the generated VHDL.

Why this works better:

- The result is unmissable. Two entities, different widths, one source.
- It lands on familiar ground. This reader writes VHDL generics; the new part is
  that vector lengths are checked at compile time against the parameter.
- It puts polymorphism exactly where our conventions want it: in the one chapter
  where it is the subject.

The risk, and it is real: this is the chapter most likely to generate type errors
the reader cannot decode. Mitigation is that every signature is given explicitly
and the reader never relies on inference. If it proves fragile in practice, the
safe fallback is to drop chapter 12 entirely and ship thirteen chapters — the
abstraction argument is already carried by chapter 4 (`map` and `zipWith` as
`for … generate`) and chapter 13 (same circuit, shorter description).

The `fold` depth argument should move to an explanation page, where it can be
stated rather than discovered.

**Shipped 2026-08-09, and the risk did not materialise.** The chapter is drafted,
`code/src/Chapters/Ch12.hs` builds `-Wall -Wcompat` clean and every block in the
chapter replays (V34). The fallback above — drop chapter 12 and ship thirteen —
is withdrawn. Two things the chapter had to settle that this entry did not
anticipate are in D24.

---

## D10. Debouncing: not mentioned

Development kits debounce at board level. The word does not appear.

---

## D11. Edge behaviour: wrapping, silently

The board wraps. This is a choice; the tutorial makes it without mentioning that
there was one.

---

## D12. The prompt in every transcript is `clashi>`

Observed, not chosen: `clashi` sets its own prompt and keeps it whatever module is
loaded. The outlines were written expecting GHCi's module-qualified
`*Example.Project>`, which never appears (V7).

We take the prompt as it comes. Getting the module-qualified form would mean
having the reader type `:set prompt "%s> "`, which is a line of ritual that buys
nothing, or shipping a `.ghci` file in the template, which hides a setting inside
the thing chapter 1 promises does not hide anything.

The cost is that the prompt no longer tells the reader which module is loaded, and
loading is a step they can forget. Chapter 1 covers it by making the module path an
argument to the one `clashi` invocation, so being loaded is not a separate action
that can be skipped.

---

## D13. Chapter 1 loads the module on the command line

`stack run clashi` on its own comes up with nothing loaded, and `:i plus` there is
an error (V7). Worse than the error: `:i register` in that state answers about
`Clash.Prelude`'s hidden-argument version, which is the opposite of what D4 built
the whole tutorial around.

So the one invocation is `stack run clashi -- src/Example/Project.hs`, from the
project directory, and it never varies. `:load` inside the prompt does the same
thing and is not offered.

---

## D14. One sentence per line in the book's Markdown

In `book/`, a sentence occupies exactly one line of source.
The line break comes at the end of the sentence and nowhere else, however long or short the sentence is.
No hard wrap at eighty columns, and no reflowing a paragraph to make it look tidy in a plain editor.

The reason is the diff.
Editing one sentence in a hard-wrapped paragraph rewrites every line after it, so a review cannot see what changed, and two people editing different sentences in the same paragraph conflict.
One sentence per line makes a changed sentence exactly one changed line.

The cost is real: the source is ragged, some lines run long, and a reader of the raw Markdown loses the visual paragraph.
Rendered output is identical either way, since Markdown joins consecutive lines, so the cost falls entirely on whoever opens the source.

This applies to `book/` only.
The files in `design/` stay wrapped as they are; they are not the tutorial, they are not reviewed sentence by sentence, and rewrapping them now would bury the history of the decisions they record.

---

## D15. The template mirror is pushed by CI, not by hand

`template/clash-tutorial.hsfiles` is the source of truth, and D7's mirroring requirement is met by a CI job that force pushes it to `christiaanb/stack-templates` on every push to `main` that changes it.
Editing the template in this repository is therefore allowed and normal.

Before this existed, the two copies were kept in step by hand, which meant any fix to the template was a fix the reader would not receive until someone remembered to push it.
V19 is exactly that failure: a bug found in the template, correct fix known, left unapplied because applying it would have made the book describe a template the reader does not get.

The mirror is a rendered copy, not a fork: the job builds a single-commit repository containing only the `.hsfiles` and force pushes it, so the mirror's history is disposable by design.
That is safe only because the mirror holds nothing else.
It holds one file today; if it ever holds a second, this job overwrites it, and the job must be changed before that happens.

The job needs a deploy key with write access to the mirror, held in this repository as the secret `STACK_TEMPLATES_DEPLOY_KEY`.
It fails loudly when the secret is missing rather than skipping the push, because a silently skipped push is the state D15 exists to prevent.

---

## D16. Every pull request publishes a preview of the rendered book

A pull request gets its book published to `pr/<number>/` on the same `gh-pages` branch that serves `main`, and the URL is written into the run's job summary.
The preview is removed when the pull request closes.

A chapter is prose, and prose is reviewed by reading it.
Before this, the only rendered copy of a change was the one that appeared after the change had already merged, so a reviewer either built the book locally or read Markdown source and imagined the rest.
Reviewing the source is exactly the way to miss a heading level, a broken `{{#include}}` that renders as literal text, or a transcript whose alignment collapses.

The cost is `force_orphan`.
The `gh-pages` branch used to be replaced by a single commit on every push to `main`, which is incompatible with the branch holding anything else, so it now keeps ordinary history and the publish deletes the root while leaving `pr/` alone.
That rule is small and it is load bearing, so it lives in `.github/gh-pages-publish.sh`, in this repository, rather than in the flags of a third party action.
The same script publishes `main`, publishes a preview and removes a preview; there is one thing that writes to that branch and one place to read what it deletes.

A pull request from a fork gets no preview.
Its token is read only, and the way to give it a write token is `pull_request_target`, which runs the workflow against unreviewed content — and `book.toml` can name a preprocessor command, so that is arbitrary code holding the token that publishes the site.
A fork's pull request still builds the book, and CI says in the summary why no URL followed.

---

## D17. `topEntity` does not appear; chapter 9 annotates `life`

**This replaces the original D17**, which had the template ship `topEntity = plus`,
chapter 2 delete it and chapter 9 write it again. That decision was about *when*
the name gets written. This one is about whether the name should be the mechanism
at all, and it concludes that it should not.

`topEntity` is a magic name. It means something only because Clash goes looking
for a binder called that, which is a fact about the compiler rather than about the
design. A `Synthesize` annotation says the same thing about a function that
already has a name of its own, and it says three more things the magic name
cannot: what the entity is called, what each of its ports is called, and both of
those in the reader's own source where they can be read and changed.

So the template holds `plus` and nothing else, chapter 2 replaces `plus` rather
than deleting two things, and chapter 9 annotates `life` where it already stands.

What it buys:

- Chapters 1 and 2 each lose a forward reference and an unexplained name. Chapter
  1 introduces one definition instead of two; chapter 2's edit is a replacement
  rather than two deletions with an explanation attached to the second.
- Chapters 10 and 11 read a test bench and a waveform whose ports carry the
  reader's names rather than `carg`, `carg_0`, `carg_1`, `carg_2` and sixty-four
  `result_N_M`. That is worth more in those two chapters than it is in chapter 9.
- Chapter 12 gets two entities from one `:vhdl`, because Clash generates every
  annotated binder in one invocation. The `-main-is topEntity8`/`-main-is
  topEntity16` route it used to plan is withdrawn with V1.

What it costs, and none of it is free:

- Seven lines of record syntax the reader types in a chapter that is otherwise
  about reading VHDL, without record syntax having been taught. Chapter 8's `St`
  is the nearest thing to preparation and it is not much.
- One rule that has to be stated rather than discovered: `t_inputs` takes one
  entry per argument, in argument order, and the clock, the reset and the enable
  each need one because each of them is an argument.
- The template's `stack run clash -- Example.Project --vhdl` stops working on its
  own, since nothing in a fresh project is named `topEntity` or annotated. It
  gains `-main-is plus` in both places the template writes it.

---

## D18. `fromIntegral` does not appear; numbers change type with `numConvert`

A reader who meets `fromIntegral` in a tutorial will use it in a circuit, and it
is the wrong instrument there: it converts through `Integer`, which Clash gives
64 bits in the generated HDL, so anything wider is silently truncated, and it
will turn a `Signed 8` of -1 into an `Unsigned 8` of 255 without a word. Neither
failure is visible at the call site, and both are exactly the kind of thing this
reader would expect a type system to be for. The argument in full is in
<https://clash-lang.org/blog/2026-05-19-numconvert/>.

`numConvert` is the replacement, and it is in Clash 1.10.0, which is what the
tutorial pins. It converts only when it can show at compile time that nothing is
lost, and `maybeNumConvert` is there for when it cannot. The tutorial names
`numConvert` once, in chapter 4's `renderCounts`, and links the post rather than
making the argument itself.

It costs nothing at the point of use, which was not true when this entry was
first written. `numConvert`'s inferred constraints are not type variables, so a
`where` binding using it needs `FlexibleContexts`, and under the template's
former `Haskell2010` that meant writing `digit :: Unsigned 4 -> Char` to keep the
binding monomorphic. D19 moved the template to `GHC2024`, which supplies
`FlexibleContexts`, and the signature was deleted.

`fromIntegral` is not mentioned anywhere, including to warn against it: naming it
would teach it. A grep for it in `code/` and `book/` should stay empty.

---

## D19. The template's language edition is `GHC2024`

`common-options` said `default-language: Haskell2010` and then listed
thirty-two extensions, inherited from `clash-starters`. Twenty-one of those
thirty-two are in the `GHC2024` language edition, which GHC 9.10.3 supports, so
most of the list restated the default and buried the entries that decide
something. Naming the edition and deleting what it implies leaves eight:
`DefaultSignatures`, `DeriveAnyClass`, `QuasiQuotes`, `TemplateHaskell`,
`TypeFamilies`, `MagicHash`, `NoImplicitPrelude` and `NoStarIsType`. The last two
must be there precisely because `GHC2024` turns their positive forms on; Cabal
applies `default-extensions` after the edition, so the override wins.

Three more went that `GHC2024` does not imply. `TemplateHaskellQuotes` is implied
by `TemplateHaskell`. `NoStrictData` restated the default, since the edition does
not enable `StrictData`. `NoMonomorphismRestriction` is the one with a cost:
dropping it means the monomorphism restriction is on, which is a divergence from
the set `clash-starters` ships. It is inert for this tutorial, because every
top-level definition carries an explicit signature by convention and the
restriction applies only to bindings written without arguments, and no local
binding in chapters 1 to 4 is one. It is nevertheless the first entry to put back
if a later chapter meets an inference error it should not have.

The two `clash` and `clashi` executables keep `Haskell2010`. They do not import
`common-options`, and each is `import Prelude` and a two-line `main`.

**What the edition changes, and why now.** `GHC2024` brings on `FlexibleContexts`
and `MonoLocalBinds`, which is to say it changes type inference and not just
syntax. `FlexibleContexts` is a straight gain and paid for itself immediately:
chapter 4's `renderCounts` had carried `digit :: Unsigned 4 -> Char` for no other
reason, and that line is now gone (D18, V23). `MonoLocalBinds` is the risk, since
it can reject a local binding that used to generalise. Nothing in chapters 1 to 4
relied on that, and chapters 5 to 13 will be written under it — which is the
argument for making this change now rather than after thirteen chapters and their
transcripts exist.

Checked rather than assumed: `Cabal-syntax-3.12.1.0` accepts
`default-language: GHC2024` under `cabal-version: 2.4` with no spec bump, the
reader's project builds and tests from the edited template, and chapter 4's
captured session is byte-identical under the new edition, line numbers included
(V24).

---

## D20. Chapter 9 marks `step` `OPAQUE`, and hierarchy is opt-in

Clash inlines everything into one entity unless a binder is marked, and for a
reader who writes VHDL that is the single most surprising thing in the generated
output: the function hierarchy they wrote does not survive, and there is no
component where they expected one. Chapter 9 shows this rather than asserting it.
It generates once with the design flat, then adds `{-# OPAQUE step #-}` and
generates again, and the reader watches one 548-line file become a 211-line one
and a 343-line one (V30).

`step` is the right binder to mark. It is the one function the reader has been
told since chapter 6 exists in exactly one copy, and the instantiation in
`life.vhdl` is what finally shows that. It is also fully representable, so the
boundary costs nothing structurally.

What it costs, and the chapter says both out loud:

- Clash does not optimise across the boundary. Nothing in this design suffers
  from that, and the sentence is there because the next design might.
- An `OPAQUE` component's ports are named by Clash, not by the reader. `b` and
  `result` appear in the step entity, one chapter after the reader chose five
  names for the top. `Synthesize` names the top of a design and this is not the
  top of one, so the two facts sit side by side and the chapter says so.

The alternative was to state the flattening in a sentence and generate once.
That is cheaper by one edit and one transcript, and it turns a "notice that" into
a claim the reader has to accept, which is what the voice guide exists to
prevent.

---

## D21. Chapter 10 annotates the test bench and marks `life` `OPAQUE`

V2 left chapter 10 two things to settle against a capture: whether the test
bench should carry an annotation of its own, and which directory the reader
works in. Both are settled by V31, and a third thing turned up that neither the
outline nor V2 had anticipated.

**The test bench is annotated.** `{-# ANN testBench (TestBench 'life) #-}` names
the entity it tests, and one `:vhdl` then generates both. The withdrawn
alternative was `-main-is testBench`, which is a flag used in exactly one
chapter and a second invocation of the compiler; the annotation keeps chapter
10's command byte identical to chapter 9's, which is the same argument D17 made
for chapter 12.

**`life` is marked `{-# OPAQUE life #-}`, and this is the part nobody predicted.**
A `Synthesize` annotation names the top of a design. It does not stop that
design being inlined into something else that uses it, and a test bench uses it:
without the pragma, Clash copies the whole of `life` into `testBench.vhdl` and
what NVC runs is a second copy of the logic rather than the entity chapter 9
generated. The generated `Example.Project.testBench/` directory then holds its
own `step.vhdl` and its own types package, and `life.vhdl` is never analysed at
all.

What the pragma buys, and it is why it is worth its costs:

- The simulation exercises the entity chapter 9 read. The three files in
  `Example.Project.life/` are byte identical with the pragma and without it, so
  the entity being simulated is provably the one that chapter 9 shows (V31).
- `testBench.vhdl` instantiates `entity life.life` with `clk`, `rst`, `en`,
  `cmd` and `cells` in its port map. Chapter 9 closes by saying those names are
  what chapters 10 and 11 read; without the pragma they appear nowhere in the
  simulation and that sentence would have to be withdrawn, along with most of
  the reason for choosing them.
- Chapter 11 gets a hierarchy to open. The command bus is a port on an instance
  rather than a signal called `\c$ds_app_arg_0\` inside a flattened test bench.

What it costs, and the chapter says the first of these out loud:

- Two lines of `Not specializing TopEntity: Example.Project.life[…]` in the
  `:vhdl` output, which is Clash saying it declined to fold a specialised copy
  of `life` into the test bench. The bracketed number is GHC's unique for the
  binder and it moves if the reader types anything extra at the prompt before
  generating, so the chapter says it will differ and
  `tools/check_transcripts.py` blanks it the way it blanks the timings.
- The `nvc` command names two directories and six files, and needs
  `--work=life`, because `entity life.life` is a library-qualified reference and
  the library has to exist. That is one flag and one more thing to explain,
  against a test bench that would otherwise be self-contained in one directory.

**One `nvc` invocation, and it prints nothing.** `--ieee-warnings=off` is the
other flag: without it the run prints 257 warnings, all of them at time zero,
from `NUMERIC_STD."="` being handed values no signal has driven yet. Showing
771 lines of warning and telling the reader to ignore them is exactly the thing
D1 forbids, so they are turned off and the chapter says in one sentence what was
turned off and why. A passing run then prints nothing at all, and the visible
result is `echo $?`.

---

## D22. The template fixes the order of Clash's progress lines

`bin/Clashi.hs` gains `-fclash-no-concurrent-topentity-compilation`, beside the
two flags V7 and V30 put there.

Clash compiles top entities concurrently, and from chapter 10 there are two of
them. The `Clash: Compiling …`, `Clash: Normalization took …` and
`Clash: Netlist generation took …` lines then interleave in whichever order the
two compilations finish, which differs from run to run: two captures of the same
session produced two different orderings, and the `Not specializing` lines
appeared once in one and twice in another. A chapter cannot quote that, and
`tools/check_transcripts.py` cannot check it.

The cost is real and falls on the reader rather than on us: their `:vhdl` is
sequential, so a design with several entities in it takes longer than it needs
to. This design has two, each of which normalises in under half a second, and
the flag is in the template rather than in the book so that no chapter has to
mention it.

---

## D23. Chapter 11 dumps everything, and ships one unverified marker

Three things chapter 11 settled, none of which was on paper before it (V32).

**The dump is not filtered.** `nvc … -r -w` prints two notes rather than one: the
second says that arrays of composite types are not dumped without
`--dump-arrays`, and it means our `Board`, in the `step` entity's two ports and
in the state record's board field. Two ways to make it go away were tried and
both are worse. `--dump-arrays` suppresses it and adds sixty-four names to a
hierarchy that already has 4800, for a board that is already on screen as `cells`
because chapter 9 named that port. `--include`/`--exclude` filter on
colon-separated paths, which is a glob to explain, and a glob that matches
nothing does not warn: the run dies with `** Fatal: 190ns+0: fstReaderOpen failed
for temporary FST file`. So the note stays and the chapter spends one sentence on
it. That sentence is not "ignore this": the note is telling the reader something
true about the design, which is the test D1 applies to output a chapter cannot
prevent.

**`code/src/Chapters/Ch11.hs` exists and is chapter 10's module byte for byte.**
Chapter 11 edits nothing — it reads a waveform of chapter 10's run — so the
duplication buys no new code. It buys the rule in `CLAUDE.md` holding without an
exception: `ChNN.hs` is the reader's file at the end of chapter NN, and both
`tools/reader_file.py` and `tools/check_transcripts.py` derive every state from
that. Concretely, chapter 11's `pack` block is replayed against this module, and
chapter 12's edits will be staged as a diff from it; without the file the
checker skips chapter 11 with `no module in code/` and crashes on chapter 12.
The cost is 207 duplicated lines and one more module in CI.

**Surfer is driven by a typed command.** The chapter tells the reader to press
space and type `item_set_format binary` rather than to find a menu entry, because
a documented command is something we can quote and a menu is a screenshot we are
not allowed to take. The outline forbids click-by-click for the same reason, and
a command is also the thing least likely to move under a web application that
ships continuously.

**Chapter 11 was drafted with an `UNVERIFIED` marker over those paragraphs, and
the marker lasted one review round.** There is no browser in the authoring
container, so what Surfer does with the file was written from V6's reading of its
source and from its documented command set, and V33 held it open until it was
confirmed in a browser. Both halves of that are worth keeping as precedent. A
chapter may ship a marker rather than wait, because the alternative here was to
block chapters 12 and 13 on a third-party web application, and D6 split the
waveform into its own chapter precisely so that it could not do that; and the
marker comes out in the same commit as the confirmation, not later. V33 also
notes the one way this differs from every other closed item: the browser build
carries no version, so that check has a shelf life and the rest do not.

---

## D24. `life` takes its seed as an argument, and chapter 12 generates three entities

Three things chapter 12 settled, none of which was on paper before it (V34).

**The seed becomes an argument to `life`.** `mealy`'s initial state has been
`St glider False` since chapter 8, and `glider` is an 8×8 board. A `life` that
does not know its size cannot name the board it starts from, so the seed arrives
as a fifth argument and `life8` and `life16` are `life glider` and
`life glider16`.

The alternative was an initial state that needs no seed — an empty board of any
size, filled by the reader with `Load` — and it is worse in three ways. Chapter
9's reset value is the glider written out in the VHDL, and chapter 11 reads
`cells` holding the glider from time zero, so both chapters would have to be
withdrawn or re-captured. The 16×16 half of the chapter would have nothing to
show at the prompt without typing a command first. And "the design comes out of
reset holding a seed" is a fact about this design that chapter 6 established and
nothing since has needed to change.

The cost is one argument added to the 8×8 design for the 16×16 design's benefit,
and the chapter says so in its own sentence rather than presenting the parameter
as free.

**`{-# OPAQUE step #-}` on a polymorphic `step` gives two specialised
components.** This was V1's open question and the outline's "second risk,
unverified". Neither of the bad answers happened: the boundary is not refused,
and it is not one shared component either. Each entity gets a `step` of its own,
343 lines apiece, differing in 55 lines that are all numbers.

That is where Clash and a VHDL generic genuinely part company, and the chapter
says which is which rather than claiming the outcome is the better one. A
generic gives one entity with a `generic` on it and two instantiations; Clash
specialises and writes the entity out per size. What is shared here is the
source, and nothing in the generated tree is.

**The test bench is retargeted rather than dropped.** Two lines change,
`{-# ANN testBench (TestBench 'life8) #-}` and the line that drives the design,
and `{-# OPAQUE life8 #-}` carries chapter 10's pragma to the binder that is now
instantiated. `life16` gets no pragma, because nothing instantiates it, and the
asymmetry is stated in one sentence rather than smoothed over with a pragma that
does nothing.

Chapter 12 does not re-run NVC. The command would be chapter 10's with three
file names changed, which repeats a how-to instead of teaching a step, and
`sampleN 12 testBench` already shows that the 8×8 behaviour did not move. The
chapter therefore claims that the test bench passes in Haskell and claims
nothing about the simulator.

**What this leaves chapter 13.** Its outline writes
`life8 = exposeClockResetEnable life`; with the seed argument that becomes
`life8 = exposeClockResetEnable (life glider)`, and there are two of them. The
annotation is still unchanged between the two chapters, which is what D4's claim
rested on.

---

## D25. Chapter 13 is a diff, and the reader keeps chapter 12's tree to make it

Three things chapter 13 settled, none of which was on paper before it (V35).

**The chapter's result is a comparison, so its first instruction is `mv`.**
`:vhdl` overwrites `vhdl/`, and what chapter 13 has to show is that the tree it
writes is chapter 12's tree. So the chapter opens in the shell with
`mv vhdl vhdl-12`, before a line of source is touched, and closes with
`diff -r -q --exclude=clash-manifest.json vhdl-12 vhdl`.

That `-q` is a decision rather than a convenience. A full diff of the two files
that differ is 211 and 595 lines of mostly board literal, and the four names
`-q` prints are the result: seven of the eleven generated files are byte
identical, including both `step` entities and the whole test bench directory.
The exclusion is a decision too, and the chapter says what it is in one
sentence: `clash-manifest.json` records a hash of what Clash was given, and what
Clash was given did change. Suppressing it without saying so would be hiding a
difference in a chapter whose subject is which differences there are.

The cost is that a reader who forgets the `mv` cannot recover it later in the
chapter; regenerating chapter 12's tree means putting chapter 12's source back.
That is the one step in the tutorial that is not recoverable from within its own
chapter, and it is pre-flagged in its own paragraph rather than dropped into the
middle of one.

**One `:r` at the end of three edits.** Every chapter since chapter 2 has been
edit, `:r`, evaluate, one edit per reload. Chapter 13 cannot be: changing the
import alone leaves `mealy` taking a clock it no longer takes, so the file does
not compile until `life` and both wrappers have changed too. The chapter says
that before the first edit rather than letting the reader find it, and the habit
is stretched exactly once, in the last chapter, on a reader who has done it
eleven times.

The alternative was to reorder the edits so that each intermediate state
compiles, and there is no such order: the import is what changes `mealy`'s type,
and every use of `mealy` breaks the moment it lands.

**`exposeClockResetEnable` appears twice, and the two signatures do not move.**
The outline predicted one occurrence, which was written before chapter 12 turned
one entity into two. There is one per annotated binder, and that is the shape of
the answer rather than an accident: an annotated binder describes real ports, a
port is a wire, and a wire cannot be hidden. `life8` and `life16` keep chapter
12's signatures byte for byte, which is what makes D4's claim checkable — the
two generated entity declarations are byte identical between the chapters, so
the port list demonstrably did not move while the body did.

---

## D26. Explanation pages, under `book/src/explanation/`, linked at first bare use

The introduction promises that where the reader wants to know why, "we link to
one [an explanation] rather than stopping to argue the point." This decision
gives that promise a structure. Outlines are in `04-explanation-outlines.md`:
twelve pages, Haskell-language topics plus one on the simulation/synthesis
model, scoped to what the Track B reader meets in chapters 1–13.

**Where they live.** `book/src/explanation/<slug>.md`, one theme per file, under
a `# Explanation` part header in `SUMMARY.md` placed after the Track B list and
before the closing suffix. Not under `book/src/b/`: `tools/check_transcripts.py`
replays every numerically prefixed file there, and explanation pages are
track-agnostic — Track A links to the same pages when it exists.

**No stubs.** A page enters `SUMMARY.md` in the pull request that writes it, and
not before. The publish script serves exactly what `SUMMARY.md` lists, and an
empty page damages the same confidence a failed step would.

**How chapters link.** One sentence at the concept's first bare use, usually in
or immediately after a "notice that" beat, of the shape "why X works this way is
explained in [title]". One sentence is the budget; a second link from a later
chapter is allowed only where the concept visibly escalates, and each outline
names its insertion points. The link lands in the same pull request as the page,
so no link ever points at nothing and no shipped chapter waits on an unwritten
page.

**What a page may do that a chapter may not.** State claims, weigh costs, argue.
D20's principle stands untouched — a chapter only shows — and this is the other
half of it: the place where "notice that" material can finally be asserted.
The voice guide binds explanation prose exactly as it binds chapters.

**What a page inherits unchanged.** One sentence per line (D14). The name D18
bans stays banned, greps and all. Code is pulled from existing `code/` anchors,
and transcripts are reused from what the chapters already captured; a page that
wants a new demonstration takes an `UNVERIFIED` marker and a queue entry like
anything else in `book/`.

**`currying.md` shipped first, and it settled two things this entry did not
say.** A page is not replayed: `tools/check_transcripts.py` globs
`book/src/b/*.md` for a numeric prefix, so a transcript quoted on an
explanation page is checked by nobody. The page therefore keeps quoted output
to the two chapter 1 blocks that are the moment it names, byte for byte
including the tab in `-- Defined at`, and takes every code block from a `code/`
anchor through `{{#include}}`, which the build does check. Prefer includes over
quotation on every later page for that reason. And the two secondary links in
the outline's table were not added: chapter 1's link is the budget D26 sets,
the chapter 3 row was conditional on the chapter 1 link proving too early, and
nothing yet says it has. The page's "Where you met this" list still names
chapters 3, 4, 8, 10 and 13, so the back-links run ahead of the forward ones by
design.

**`pattern-matching.md` shipped second, and it corrected its own outline.** The
outline's cost beat said "nothing checks completeness for you by default here",
and that is wrong for the project the reader generates: `-Wall` is in
`common-options`, so `stack build` does report a `case` with a row missing, and
the redundant-row check needs no flag at all. What is asymmetric is *where* each
one shows, because the `clashi` executable stanza does not import
`common-options`. Both were run rather than reasoned about, and the queue entry
records what they print. The general lesson for the pages still to come: an
outline beat that asserts compiler behaviour is a claim to check, not a claim to
transcribe. Like `currying.md`, the page took only its primary link (chapter 2)
and left the two secondaries in the outline's table unbuilt, and its "Where you
met this" list names chapters 3, 4, 7 and 8 as well.

**`vec-and-lists.md` shipped third, and one of its outline beats was wrong.** The
outline listed `toList` and `fromList` together as "the bridges", one in each
direction. They are not a pair: `toList :: Vec n a -> [a]` leaves the vector and
`fromList :: NFDataX a => [a] -> Signal dom a` enters the *signal*, so the list
sits outside both types rather than between them, and nothing in the book crosses
from a list back to a `Vec`. The page says so, and the reason is the length. Two
smaller corrections came from running things: `:>` is a pattern synonym for the
constructor `Cons` rather than a constructor in its own right, which the page
states without dwelling on it, and the outline's "`<...>` never appears" beat was
dropped rather than asserted, because 1.10.0's `Show` instance was only observed
printing `:>` chains and a claim about what a library never prints needs more
than one observation. Like the two pages before it, this one took only its
primary link (chapter 3, after the `glider` block); the chapter 6 and 7
secondaries stay unbuilt, and the "Where you met this" list names both anyway.

**`higher-order.md` shipped fourth, and it took its evidence from a real
capture rather than from the chapters.** Chapters 3, 4 and 5 use `map`,
`zipWith` and `foldl1` without ever asking the prompt what they are, so unlike
the three pages before it this one had no chapter transcript to reuse for its
central claim. It was captured instead, through `tools/clashi_capture.py`
against `code/` with `READER_FILE` pointed at `Chapters/Ch04.hs`, which is a pty
session under the same pinned locale and width the chapters use and is the
cheapest way to get bytes worth quoting when no reader project is to hand. The
two queue entries list every line. Two beats moved as a result of running things:
`map nextCell` typechecks and gives `Vec n (Unsigned 4 -> Bool)`, which is a
better cost beat than the outline's general "the netlist only takes shape when
the arguments land" and is now the page's sharpest edge, and the outline's
lambda beat gained the reason a lambda is needed at all in `shiftW`, which is
that `rotateLeftS` wants the distance second and partial application cannot
reach past the first argument. The `fold` depth question is named and refused in
one sentence, per the deferred list below. Like the three pages before it, this
one took only its primary link (chapter 4, after the "one `+` in that line"
sentence); the chapter 3 and 7 secondaries stay unbuilt and the "Where you met
this" list names chapters 3, 5, 6, 7 and 9 as well.

**`type-inference.md` shipped fifth, and running it turned the outline's last
beat into its argument for signatures.** The outline listed the cost as "a wrong
definition with no signature produces a correctly inferred wrong type, and the
error appears at the use site instead of the mistake", which is true and was
worth more than a sentence once it had been run. Dropping `numConvert` from
chapter 4's `digit` was captured twice, once as the book writes it and once with
a local signature added, and the report moves from `renderCounts`'s own line
onto `digit`'s. That pair is now the whole of the page's second reason for
writing signatures, and the first reason (a signature is the port list) is
argued in three sentences rather than asserted. Two other things came out of the
capture. `:t map unpack` gives `BitPack b => Vec n (BitVector (BitSize b)) ->
Vec n b`, so `fromRows`'s two type variables can be solved on the page, by hand,
against the `:i fromRows` chapter 3 already shows, which is a better opening than
restating the chapter's claim. And `unpack 0b1110_0000` under three annotations
gives a `Vec 8 Bool`, 224 and -32, the third row of the glider read three ways,
which is the beat the outline wanted and had no evidence for. The page takes the
one VHDL contrast every page is allowed on the conversion functions, which name
their own target where `unpack` is named by its target. Like the four pages
before it, it took only its primary link (chapter 3, after the `unpack` beat);
the chapter 4 secondary stays unbuilt and the "Where you met this" list names
chapters 3, 4 and 7.

**`type-level-numbers.md` shipped sixth, and it needed an instrument the book
did not have.** The outline asks for the kind line decoded, and there was no way
to put `Vec`'s kind on the page with the two commands the tutorial uses: `:i
Vec` prints the kind and then forty lines of instances, which is unquotable.
`:k` is therefore the third REPL command the book shows, introduced in one
sentence as standing to a type as `:t` stands to an expression, and used three
times (`Vec`, `Signed`, `Vec 8`) plus once on chapter 12's `Board`. It is worth
the exception because it is the only way to show, rather than assert, that `Vec`
is not a type. Everything else on the page was quotable because of a property
worth naming for later pages: `:k` and `:t` output carries no file name, so a
block captured against `code/` is byte-identical to what a reader sees, whereas
`:i` on anything the reader defined prints `-- Defined at
src/Chapters/ChNN.hs`, which is why the page's two `:i` blocks on reader names
(`Board`, `outputVerifier'`) are cut from chapters 3 and 10 rather than
captured. Two beats came out of running things. The width of a `Command` prints
as a sum and not as a number, `BitVector (CLog 2 4 + 64)` at 8×8 and `BitVector
(CLog 2 4 + 256)` at 16×16, which is a better demonstration of type-level
arithmetic than the outline's "chapter 12's bus is `n * n + 2` wide" and pays
chapter 8's hand count back in the same breath. And the outline's reason for
rejecting `1` where `d1` belongs stopped at "no `Num` instance can cross that
gap", which is the mechanism rather than the reason: an instance would have to
turn every literal into the single value of `SNat 1`, so `fromInteger 5` would
be one, and the page says that instead. The page also corrected a wrong number
in `03-verification-queue.md`: a `Command 16` is 258 bits and a `Maybe (Command
16)` 259, as chapter 12's prose has always said, and the queue's widths entry
said 257 and 258. Like the five pages before it, this one took only its primary
link (chapter 4, after the `SNat`/`d1` paragraph); the chapter 3, 10 and 12
secondaries stay unbuilt and the "Where you met this" list names chapters 1, 3,
8, 10 and 12 as well.

**Deferred but owed.** The `fold` depth argument (D9 assigned it here when
chapter 12 was replaced) and the VHDL-to-Clash rosetta stone (the voice guide
assigns it here) are explanation pages, and they are not in this first batch:
the batch stays about reading Haskell rather than designing circuits. Neither
earmark is withdrawn.

---

## Open, deliberately

**Chapter 14, the optional board chapter.** An 8×8 display is not standard on
cheap development kits, which is the one place this artifact is weaker than a
seven-segment spine would have been. Options are eight LEDs scanned through eight
rows (weak visual), an external matrix module (adds SPI and soldering), or a board
with a display connector (much longer chapter). Settle it after chapters 1–13
exist and work, rather than letting the board decide the tutorial.
