# Verification queue

Everything in `design/` was written without a Clash or NVC installation to hand.
Nothing here has been run. This file is the list of claims that must be checked
before the corresponding chapter can be drafted, ordered by how much rework an
unexpected answer causes.

Mark items `[x]` with the date and the observed result, not just a tick. A
verified item that records *what was seen* is worth ten times one that records
that someone looked.

---

## Blocking: answer before drafting the chapter

- [ ] **V1 — Chapter 12 is buildable at all.** Parameterising `Board n` propagates
      `KnownNat n` through `step`, `neighbourCounts` and the four shifts. Confirm
      it compiles with explicit signatures throughout, and capture the error the
      reader gets if they omit one. If the constraint plumbing is worse than a
      chapter can carry, invoke the D9 fallback and ship thirteen chapters.
      *Blocks: ch. 12.*

- [ ] **V2 — Test bench generation route.** Does `-main-is testBench` on the
      command line work, avoiding the `TestBench` annotation and Template Haskell
      entirely? If not, the annotation is unavoidable and chapter 10 gains a
      ritual step. *Blocks: ch. 10.*

- [ ] **V3 — NVC file ordering.** Capture the exact list of files Clash 1.10.0
      emits for `topEntity`, in dependency order, and the exact `nvc` invocation.
      Decide whether the list is short enough to print in the chapter.
      *Blocks: ch. 10.*

- [ ] **V4 — VHDL standard.** Does Clash's output analyse under NVC's default
      (VHDL-2008), or does it need `--std=1993`? Pin one and write it into the
      command. *Blocks: ch. 10.*

- [ ] **V5 — Waveform format.** Does Surfer's browser build accept NVC's FST
      output, or should NVC be asked for VCD? Capture the exact NVC flag.
      *Blocks: ch. 11.*

- [ ] **V6 — Surfer locality.** Confirm the browser build processes the file
      locally and nothing is uploaded. One sentence in the chapter depends on it,
      and that sentence removes an objection we would otherwise never hear about.
      *Blocks: ch. 11.*

---

## Shaping: answer before the chapter is finalised

- [ ] **V7 — `:i` output under the explicit prelude.** Capture verbatim for
      `register` and `mealy`. The whole `:i`-as-instrument argument rests on these
      being readable. If they are not, D4 needs revisiting.
      *Shapes: ch. 1, 6, 7.*

- [ ] **V8 — No type application needed.** Confirm `sampleN 5 (life
      systemClockGen resetGen enableGen)` needs no `@System`. This is one of the
      stated benefits of the explicit prelude. *Shapes: ch. 6.*

- [ ] **V9 — Reset behaviour in the first samples.** Capture the actual sequence
      under `resetGen`. Chapter 6 points at it, so it must be right.
      *Shapes: ch. 6.*

- [ ] **V10 — `unpack` resolves for `fromRows`.** Confirm `map unpack ::
      Vec 8 (BitVector 8) -> Vec 8 (Vec 8 Bool)` works with only the top-level
      signature to guide it. *Shapes: ch. 3.*

- [ ] **V11 — Widths.** Actual `BitSize` of `Command` and `Maybe Command`. The
      outline guesses 66 and 67. The reader hunts for these in the waveform, so a
      wrong number is a failed chapter. *Shapes: ch. 8, 11.*

- [ ] **V12 — `Clash.Explicit.Prelude` completeness.** Does it re-export
      everything the spine needs — `Vec` operations, `rotateLeftS`/`rotateRightS`,
      `foldl1`, the test bench primitives — or do extra imports creep in? Every
      extra import is a line the reader types without meaning.
      *Shapes: all chapters.*

- [ ] **V13 — Chapter 13 diff.** Are the two VHDL trees byte-identical, or merely
      equivalent? If names differ, note which and why. *Shapes: ch. 13.*

---

## Infrastructure

- [ ] **V14 — Template mirroring.** `stack new life christiaanb/clash-tutorial`
      resolves to `github.com/christiaanb/stack-templates/clash-tutorial.hsfiles`.
      Create that repository and confirm the command works end to end from a clean
      machine. Until it does, chapter 1's first command is wrong.

- [ ] **V15 — Template builds.** `stack new` from the template, then `stack build`,
      then `stack run clashi`, on a clean machine. Time the first build and put the
      real number in chapter 1.

- [ ] **V16 — `default-extensions` sufficiency.** Confirm the template's set covers
      `BinaryLiterals`, `NumericUnderscores`, `DeriveGeneric`, `DeriveAnyClass`,
      and Template Haskell if V2 comes back needing the annotation. Anything
      missing becomes a per-file pragma, which is a thing the reader must be told
      about and would rather not be.

- [ ] **V17 — NVC on Debian and Ubuntu.** Is there a usable package, or is
      `configure`/`make` the honest instruction? Sizes one sentence in chapter 10.

- [ ] **V18 — CI.** `nickg/setup-nvc` action reference and version. The workflow in
      `.github/workflows/ci.yml` guesses.

---

## Notes on method

Run the whole spine end to end on one machine before drafting prose for any
chapter after the first. The chapters are cumulative, and a surprise in chapter 8
can invalidate the code shown in chapter 4.

Capture transcripts by copying from the terminal, not by retyping. Trailing
whitespace and exact spacing matter when the reader is comparing their screen to
the page.

Where a claim in `design/` turns out to be wrong, fix `design/` in the same commit
as the chapter. A design document that has silently drifted from the built code is
worse than none, because the next person will trust it.
