# Voice, and the Diátaxis constraints

Two separate things govern the prose. Diátaxis says what may be in a chapter. The
voice guide says how it reads. Both are binding.

---

## Part 1: Diátaxis constraints

Derived from <https://diataxis.fr/tutorials/>.

### The reader is doing, not reading

The tutorial is a lesson conducted by an author who has taken responsibility for
what the reader does. The reader is not expected to understand what they are
doing, and does not need to. Understanding follows later, from explanation.

This has an uncomfortable consequence that must be respected: **unexplained ritual
is acceptable.** The reader types `systemClockGen resetGen enableGen` for several
chapters without knowing what those are. That is fine, provided it never varies
and never fails.

### What may not appear

| Not allowed | Where it goes instead |
|---|---|
| Alternatives ("or you could use Cabal") | How-to guide |
| Explanation of why a thing works | Explanation page, linked |
| Lists of restrictions, options, flags | Reference |
| Troubleshooting sections | Fix the chapter |
| Discussion of edge cases we chose against | Nowhere. Delete it. |
| Any step that produces an error | Nowhere. Redesign the step. |

The last row is not negotiable. If the reader is asked to run something that
prints a failure and is then told the failure is expected, the tutorial has taught
them that its instructions cannot be trusted.

### What must appear

- **A visible result, in every chapter.** Preferably early in the chapter as well
  as at its end.
- **The whole picture, up front.** The reader should know from chapter 1 what they
  are building and roughly where it ends.
- **Pre-flagged failure modes.** Not troubleshooting after the fact — a sentence
  *before* the step, saying what is about to happen. "This will take fifteen
  minutes the first time" is the single highest-value sentence in chapter 1.
- **Repetition.** Concepts recur across chapters rather than being covered once.
- **Actions that produce results, not questions.** Never ask the reader to decide
  anything.

### The hardest distinction

Diátaxis is explicit that separating *what is done* from *what is learned* is the
difficult part of tutorial design. The outlines separate them per chapter. Keep
them separate when drafting: the "what we do" is instructions, and the "notice
that" beats are the learning, and they are written differently. Instructions are
imperative and short. "Notice that" beats are observations the reader can verify
in front of them, not claims they must accept.

---

## Part 2: Voice

The tutorial is written in Christiaan Baaij's voice. Characteristics, drawn from
his doctoral thesis and subsequent technical writing:

### Structure

**Motivate first, then explain.** Sections open by establishing why something
matters — often with a concrete measurement, or a deliberately imperfect example —
before introducing the mechanism. Never open with a definition.

**Signal the road map explicitly.** "We will come back to this in chapter 9" is in
voice. Leaving the reader to wonder is not.

### Person and tense

Plural "we" for the work. Present tense for claims. State a claim, then
immediately qualify its scope in its own sentence rather than hedging inside the
first one.

### Honesty about trade-offs — the most distinctive feature

Almost every advantage claimed is followed by its cost, in its own sentence.
Limitations in our own tools are flagged as readily as limitations in others'.
Where an example contains a deliberate flaw, it is marked as deliberate.

In this tutorial that means, concretely:

- `Maybe Board` is 65 bits wide either way. The type system removes a class of
  mistake, not wires.
- In the `Nothing` case the payload wires are still driven with meaningless values
  and the multiplexer discards them. Nothing is switched off.
- The explicit prelude is not what the reader will meet in real projects. Chapter
  13 exists because of that.

These are one-line remarks, not paragraphs, and they buy more trust than omitting
them would.

### Precision habits

- Acronyms expanded on first use, abbreviation in parentheses.
- Terms defined before use.
- Numbers given concretely rather than gestured at. "Fifteen minutes", not "a
  while". "Sixty-four cells", not "many cells".
- **Careful separation of "cannot" from "not currently".** A fundamental
  limitation and a missing feature are different claims and must not be conflated.
  This is the most consistently observed habit in the source material and the
  easiest to violate by accident.

### Restraint

No superlatives without evidence. Where something is genuinely good, understate
it: "on par with hand-written VHDL", not "better than". Understated humour appears
only in asides, never in instructions.

### Sentence rhythm

Medium-length declaratives. A mid-sentence colon introducing the actual content is
characteristic. Em-dash asides are used, sparingly. Semicolons for tight contrast.
Bulleted lists are used heavily and introduced by a colon-terminated stem sentence.

### Punctuation restriction

Commas, colons, periods and parentheses. Avoid other punctuation in body prose.

---

## Part 3: Track B specifically

The reader knows VHDL or SystemVerilog. Two consequences.

**They need unteaching as much as teaching.** They arrive with `signal` already
meaning something, and Clash's `Signal` is not it. They will look for a process, a
sensitivity list, a `posedge`. They will read `f x` as a subroutine call rather
than an instantiation. They will assume registers are inferred the way a synthesis
tool infers them. Each of these is a specific, predictable misreading, and the
device for handling it is a "notice that" placed at the moment the reader does the
thing — not an explanation section.

The unteaching beats, distributed across chapters:

| Ch | The misreading to head off |
|---|---|
| 1 | `f x` is a call. It is an instantiation; there is no entity/architecture split. |
| 2 | `case` choices must be exclusive. They need not be; first match wins. |
| 3 | A vector length is a convention. It is in the type and checked. |
| 4 | `map` is a loop over time. It is `for … generate` over space. |
| 5 | A generation needs a process. It is combinational, and there is no clock yet. |
| 6 | `Signal` is VHDL's `signal`. It is not. Feedback is a self-referring binding. |
| 7 | Valid and data are two things by convention. Here they are one, checked. |
| 8 | A tagged union is read by convention. Here it cannot be read any other way. |
| 9 | `topEntity` is new machinery. It is the entity declaration, named at last. |
| 13 | The hidden prelude changes the circuit. It changes the notation. |

**Do not write a VHDL-to-Clash phrasebook.** It would be easy and popular, and it
teaches translation instead of the language. Rosetta-stone material belongs in a
linked explanation page.
