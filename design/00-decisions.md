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

## Open, deliberately

**Chapter 14, the optional board chapter.** An 8×8 display is not standard on
cheap development kits, which is the one place this artifact is weaker than a
seven-segment spine would have been. Options are eight LEDs scanned through eight
rows (weak visual), an external matrix module (adds SPI and soldering), or a board
with a display connector (much longer chapter). Settle it after chapters 1–13
exist and work, rather than letting the board decide the tutorial.
