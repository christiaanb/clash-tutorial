# CLAUDE.md

Instructions for Claude Code working in this repository.

## What this repository is

A multi-chapter tutorial for [Clash](https://clash-lang.org/), written to the
Diátaxis definition of a tutorial: a lesson the reader is *led through by doing*,
not a how-to guide, not reference, not explanation.

It is a standalone project for now. It may later be proposed for
`docs.clash-lang.org`, so its structure should stay compatible with mdBook.

The repository contains five things:

| Path | What it is |
|---|---|
| `design/` | Decisions, outlines, voice guide, verification queue. Read before writing anything. |
| `book/` | The mdBook source. The tutorial itself. |
| `code/` | A single Stack project holding every chapter's end state as a module. Built in CI. |
| `template/` | The Stack project template the reader uses in chapter 1. |
| `tools/` | How transcripts are captured and chapters assembled. Not shipped to the reader. |

## Read these first, in order

1. `design/00-decisions.md` — every settled decision and its rationale. Do not
   reopen a decision recorded there without saying so explicitly.
2. `design/02-voice-and-diataxis.md` — how the prose must read, and the Diátaxis
   rules that constrain it.
3. `design/01-track-b-outlines.md` — the chapter-by-chapter specification.
4. `design/03-verification-queue.md` — what has been checked against a real
   toolchain and what has not.

## The single most important rule

**Nothing goes into the book that has not been run.** Every command, every code
block and every REPL transcript must be pasted from a terminal, not written from
reasoning about what Clash would do. If you cannot run it, write the surrounding
prose and leave a marker:

```
<!-- UNVERIFIED: transcript needs capturing on a machine with Clash 1.10.0 -->
```

and add an entry to `design/03-verification-queue.md`. Do not invent plausible
output. A tutorial that prints something other than what it promised has failed
at the only thing it had to do.

`tools/` is how this rule is met rather than merely intended: a session is driven
through a pty and recorded, the reader's file is derived from `code/` rather than
kept in step by hand, and a chapter's fenced blocks are filled in from the real
artefacts by line range. Read `tools/README.md` before capturing anything.

## Working rules

- **One chapter per branch, one chapter per pull request.** Chapters are ordered
  and cumulative; a change in chapter 4 can invalidate chapters 5 through 13.
- **Code lives in `code/`, never inline in the book.** The book pulls it in with
  mdBook anchors:

  ```
  {{#include ../../code/src/Chapters/Ch04.hs:neighbour-counts}}
  ```

  with `-- ANCHOR: neighbour-counts` and `-- ANCHOR_END: neighbour-counts` in the
  Haskell source. This is what makes CI able to prove the book compiles.
- **Each `code/src/Chapters/ChNN.hs` is the complete end state of the reader's
  file at the end of chapter NN.** They are standalone modules, not a diff chain.
  Duplication between them is intentional and correct.
- **When you change a chapter's code, check every later chapter.** A rename in
  `Ch04.hs` must propagate through `Ch13.hs` or CI will catch it late.
- **Never add an alternative.** If you find yourself writing "or you could", stop.
  Alternatives belong in a how-to guide, which this is not.

## Conventions fixed for all chapters

- **One sentence per line in `book/`'s Markdown.** The line break goes at the end
  of the sentence and nowhere else, however long the sentence is. No hard wrap, no
  reflowing a paragraph to tidy it. See D14. `design/` stays wrapped as it is.
- `Clash.Explicit.Prelude` until chapter 13, which switches to `Clash.Prelude` as
  the exercise.
- Every top-level definition has an explicit, monomorphic type signature.
- Polymorphism appears only in chapter 12, where it is the subject.
- `fmap` spelled out. `<$>` is mentioned once, in prose, and never typed.
- Numbers change type with `numConvert`. `fromIntegral` never appears, not even
  in a warning against it. See D18.
- `:i` for names, `:t` for expressions. Never `:t` on a bare identifier.
- One way to do each thing: one REPL invocation, one VHDL command, one NVC
  invocation.
- Pinned: Stack resolver `lts-24.38` (Clash 1.10.0), NVC 1.20.1.

## Two tracks

Track B — reader has a hardware background, no Haskell — is the primary line and
the only one specified so far. Track A — neither background — is a scaffolding
variant to be written after Track B is complete and known to work. Do not start
Track A unscheduled.

## Definition of done, per chapter

- [ ] Code builds in `code/`, and any doctests pass.
- [ ] Every transcript pasted from a real terminal.
- [ ] Chapter ends with a result the reader can see.
- [ ] No step asks the reader to run something that fails.
- [ ] Anticipated failure modes are pre-flagged before the reader hits them.
- [ ] No explanation that could be a link, no alternatives, no reference tables.
- [ ] Later chapters still build.

## What not to do

- Do not write the tutorial in one pass. Chapters are cheap to draft and expensive
  to verify; the verification is the work.
- Do not fix a Diátaxis violation by adding a note. Delete it or move it.
- Do not add troubleshooting sections. A tutorial that needs troubleshooting has a
  bug in it.
- Do not add screenshots of third-party interfaces. They rot, and a stale
  screenshot damages confidence more than none.
