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

The weakness — no input ports, thin `topEntity` — is fixed by the command input,
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
- `topEntity` stops being a discontinuity. No `exposeClockResetEnable` appearing
  once and doing something invisible.
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
`default-extensions` — specifically `NumericUnderscores`, which the seed literals
depend on for legibility.

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

## Open, deliberately

**Chapter 14, the optional board chapter.** An 8×8 display is not standard on
cheap development kits, which is the one place this artifact is weaker than a
seven-segment spine would have been. Options are eight LEDs scanned through eight
rows (weak visual), an external matrix module (adds SPI and soldering), or a board
with a display connector (much longer chapter). Settle it after chapters 1–13
exist and work, rather than letting the board decide the tutorial.
