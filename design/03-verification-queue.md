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

- [x] **V1 — Chapter 12 is buildable at all.** *Checked 2026-08-05, Stack
      3.11.1, resolver lts-24.38, GHC 9.10.3, Clash 1.10.0, on the fixed
      project template (see the V14/V15/V16 note below).*

      `type Board n = Vec n (Vec n Bool)` with `KnownNat n` added to `step`,
      `neighbourCounts`, `countBoard`, `addCounts` and the four shifts
      compiles and elaborates as-is — no structural changes beyond adding the
      constraint, exactly as D9 predicted. `neighbourBoards` correctly stays
      `Vec 8` (eight directions) while returning `Vec 8 (Board n)`.

      One spot needs more than "add the constraint": deriving `BitPack` for
      `data Command n = Load (Board n) | Step | Run | Pause` via
      `deriving (Generic, NFDataX, BitPack, Eq, Show)` fails —

      ```
      Example/Project.hs:74:31: error: [GHC-95822]
          * solveWanteds: too many iterations (limit = 4)
              Unsolved: WC {wc_simple = [W] $dKnownNat_ahtP {0}:: KnownNat n (CNonCanonical) ...}
          * When deriving the instance for (BitPack (Command n))
          Suggested fix:
            Set limit with -fconstraint-solver-iterations=n; n=0 for no limit
      ```

      GHC's generics-based derivation can't resolve `KnownNat (BitSize (Command n))`
      within the default iteration limit when `BitSize` itself depends on `n`
      through `Board n`. The fix is one line, and it's a good chapter beat
      rather than a dead end — pull `BitPack` (and `NFDataX`, same reasoning)
      out into standalone deriving with an explicit context:

      ```haskell
      data Command n = Load (Board n) | Step | Run | Pause
        deriving (Generic, Eq, Show)

      deriving instance KnownNat n => NFDataX (Command n)
      deriving instance KnownNat n => BitPack (Command n)
      ```

      `StandaloneDeriving` is already in the template's `default-extensions`,
      so this costs the reader no new pragma.

      Omitting `KnownNat n` from a plain function (tried on `step`) gives a
      readable, actionable error, not a wall of generics:

      ```
      Example/Project.hs:67:40: error: [GHC-39999]
          * No instance for `KnownNat n'
              arising from a use of `neighbourCounts'
            Possible fix:
              add (KnownNat n) to the context of
                the type signature for:
                  step :: forall (n :: Nat). Board n -> Board n
      ```

      With both `topEntity8 :: … -> Signal System (Maybe (Command 8)) -> Signal
      System (Board 8)` and `topEntity16 :: … -> Signal System (Maybe (Command
      16)) -> Signal System (Board 16)` defined from one `life`, `clash
      Example.Project -main-is topEntity8 --vhdl` and `-main-is topEntity16`
      (note: `-main-is`, not a plain module argument, is how Clash 1.10.0
      picks a top-level binder that isn't literally named `topEntity`) each
      normalise and elaborate in under two seconds and produce genuinely
      different port widths — confirmed by counting `out boolean` ports in the
      generated VHDL: 64 for `topEntity8`, 256 for `topEntity16`. One
      description, two entities, visibly different widths, as D9's
      replacement chapter claims.

      **Verdict: ship chapter 12 as designed.** The constraint plumbing is not
      worse than a chapter can carry; the `BitPack`-deriving snag is small
      enough to *be* the chapter's pre-flagged pitfall rather than a reason to
      invoke the D9 fallback.
      *Blocks: ch. 12. Unblocked.*

- [x] **V2 — Test bench generation route.** *Checked 2026-08-05, same toolchain
      as V1: Stack 3.11.1, resolver lts-24.38, GHC 9.10.3, Clash 1.10.0, NVC
      1.20.1, on the fixed project template.*

      `-main-is testBench` works, with no `TestBench` annotation anywhere.
      Given

      ```haskell
      testBench :: Signal System Bool
      testBench = done
        where
          testInput      = stimuliGenerator clk rst (1 :> 2 :> 3 :> Nil :: Vec 3 (Signed 8))
          expectedOutput = outputVerifier' clk rst (2 :> 4 :> 6 :> Nil :: Vec 3 (Signed 8))
          done           = expectedOutput (topEntity <$> testInput <*> testInput)
          clk            = tbSystemClockGen (not <$> done)
          rst            = systemResetGen
      ```

      `stack run clash -- Example.Project -main-is testBench --vhdl` normalises
      and elaborates `testBench` directly, in under a second, producing
      `vhdl/Example.Project.testBench/{testBench.vhdl,
      Example_Project_testBench_types.vhdl,
      testBench_slv2string_<hash>.vhdl}`. No `{-# ANNOTATE #-}` pragma is
      needed at any point, and neither is Template Haskell: plain `Vec`
      literals (`1 :> 2 :> 3 :> Nil`) work directly with `stimuliGenerator` and
      `outputVerifier'`, so `$(listToVecTH …)` isn't needed either.

      Simulating with NVC confirms the test bench actually checks something,
      not just that it elaborates. `nvc -a Example_Project_testBench_types.vhdl
      testBench_slv2string_<hash>.vhdl testBench.vhdl -e testBench -r` exits 0
      against the correct expected-output vector, and on a deliberately wrong
      one (`6` changed to `7`) exits 1 with:

      ```
      ** Error: 130ns+1: outputVerifier, expected: 00000111, actual: 00000110
         Process :testbench:r_assert:_p2 at testBench.vhdl:95
      ```

      One ordering note that overlaps with V3: the three files must be
      analysed in dependency order — `*_types.vhdl`, then `*_slv2string_*`,
      then `testBench.vhdl`. A plain alphabetical glob sorts `testBench.vhdl`
      before the `slv2string` file it depends on, and NVC fails with "no
      visible declaration". Chapter 10's `nvc -a` command must list the files
      explicitly, not glob them.

      A harmless artifact to pre-flag in chapter 10: NVC prints `Warning:
      0ms+0: NUMERIC_STD.">": metavalue detected, returning FALSE` at time
      zero, before reset settles. It does not change the exit code.

      **Verdict: the `TestBench` annotation is unneeded. `-main-is testBench`
      is chapter 10's one route, and it costs the reader no new pragma or
      extension.**
      *Blocks: ch. 10. Unblocked.*

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

      *Partial, 2026-08-05, while working V1.* The template as written did not
      build: `extra-deps: []` left `clash-prelude`/`clash-ghc` unresolvable
      against lts-24.38, and the `executable clash`/`clashi` stanzas imported
      `common-options` (hence `NoImplicitPrelude`) while `bin/Clash.hs` and
      `bin/Clashi.hs` used the plain `Prelude`'s `IO` unqualified — `stack
      build` failed on `bin/Clashi.hs` with "Not in scope: type constructor or
      class `IO'" before ever reaching chapter 12's code. Separately,
      `defaultMain` in `clash-ghc-1.10.0` is `[String] -> IO ()`, not `IO ()`,
      so `bin/Clash.hs`'s `main = defaultMain` doesn't typecheck either. Fixed
      all three in `template/clash-tutorial.hsfiles`: `extra-deps` copied from
      `clash-lang/clash-starters/simple/stack.yaml` (the pinned versions for
      Clash 1.10.0 on lts-24.38); the two executables dropped
      `common-options` in favour of plain `default-language: Haskell2010`;
      `bin/Clash.hs`/`bin/Clashi.hs` now do `getArgs >>= defaultMain`, matching
      upstream `clash-starters`. Confirmed clean: `stack new` → `stack build`
      → `stack run clash -- Example.Project -main-is topEntity8 --vhdl`
      succeeded from a fresh template instance. Still open: this was not a
      literal clean machine (GHC 9.10.3 was already installed) and the first
      build was not timed — do both before writing chapter 1's number.

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
