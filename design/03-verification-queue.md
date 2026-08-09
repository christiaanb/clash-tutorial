# Verification queue

Findings from checking every claim against a real toolchain. **All thirty-five
items are closed.** What is recorded here is *what was observed* and what each
chapter must therefore do. Do not re-derive these; do not contradict one without
re-running the check and rewriting the entry.

Toolchain unless stated: Stack 3.11.1, resolver lts-24.38, GHC 9.10.3, Clash
1.10.0, NVC 1.20.1, devcontainer, on a project freshly generated from
`template/clash-tutorial.hsfiles`. Checked 2026-08-05 to 2026-08-09.

Chapters 1 to 13 are drafted against these entries and their transcripts now live
in the book; only the durable facts are kept below. Mark any future item `[x]`
with the date and the observed result, not just a tick.

---

## Toolchain and commands

- [x] **V2 — Test bench route.** `-main-is testBench` was chapter 10's one route.
      No `ANNOTATE` pragma and no Template Haskell beyond the quoted name: plain
      `Vec` literals work with `stimuliGenerator`/`outputVerifier'`, so
      `$(listToVecTH …)` is not needed. NVC exits 0 on a correct expected vector
      and 1 on a wrong one, printing
      `** Error: 130ns+1: outputVerifier, expected: 00000111, actual: 00000110`.

      **Closed by V31, on the route as well as the naming.** `-main-is testBench`
      is not what chapter 10 does: `{-# ANN testBench (TestBench 'life) #-}` puts
      the choice in the source, and one `:vhdl` generates both entities into two
      directories named for their binders. The two things this entry left open
      are settled there and recorded as D21. The error line above still holds in
      shape; the one this circuit produces is
      `** Error: 180ns+1: outputVerifier, expected: …, actual: …` with both
      boards as sixty-four bits. *Ch. 10. Drafted.*

- [x] **V3 — NVC file ordering.** Checked on the real ch. 9/10 circuit. Three
      generated files, whatever the circuit size. **An alphabetical glob fails**:
      `testBench.vhdl` sorts before the `slv2string` file it depends on
      (`no visible declaration for TESTBENCH_SLV2STRING_…`). Name the two stable
      files and glob the hash-suffixed one in its correct middle slot — argument
      order is preserved, so the reader never copies a hash:

      ```
      nvc -a Example_Project_testBench_types.vhdl \
             testBench_slv2string_*.vhdl \
             testBench.vhdl \
          -e testBench -r
      ```

      **The ordered command above is void and was re-derived by V31.** It was
      checked against a `topEntity` that no longer exists, on a flat netlist that
      chapter 9 splits in two with `{-# OPAQUE step #-}` and chapter 10 splits
      again with `{-# OPAQUE life #-}`. Six files across two directories now, in
      the order V31 records, and `.sdc` is clock constraints that NVC never sees.
      The trick of naming the stable files and globbing the hash-suffixed one in
      its correct slot survives unchanged. Two further facts, both confirmed by
      V31: `Clash.Explicit.Prelude` does **not** export `stimuliGenerator`,
      `outputVerifier'` or `tbSystemClockGen` — `import Clash.Explicit.Testbench`
      is required; and the harmless metavalue warnings are 257 of them, 771 lines
      (`NUMERIC_STD."=": metavalue detected`), all at time zero, which is why
      chapter 10 turns them off with `--ieee-warnings=off` rather than telling
      the reader to scroll past them. *Ch. 10. Drafted.*

- [x] **V4 — VHDL standard.** Omit `--std` entirely. Clash emits VHDL-93, NVC
      defaults to 2008, and the mismatch is harmless for everything Clash's
      netlists use — same exit codes and warnings with and without `--std=1993`
      on all three shapes exercised by V1–V3. *Ch. 10.*

- [x] **V5 — Waveform format.** Ship FST. `-w`/`--wave` alone turns dumping on
      and NVC's default format is FST (`Note: writing FST waveform data to
      counter.fst`). Gotcha to pre-flag: **NVC does not infer format from the
      filename** — `--wave=counter.vcd` with no `--format` writes FST bytes into a
      `.vcd` file. Surfer reads FST natively through `wellen` in the WASM build;
      the generated `counter.fst` was dropped onto `app.surfer-project.org` in a
      real browser and displayed with no conversion step. *Ch. 11.*

      **Confirmed on the real chapter 10 circuit by V32**, which also records the
      one thing this entry did not: `--wave=FILE` is the only spelling that takes
      a file name. `-w FILE` reads the name as the design unit to run
      (`** Fatal: '…/space.fst' is not a valid design unit name`) and `-w=FILE`
      reads it as one too (`** Fatal: =…: Inappropriate ioctl for device`). The
      chapter uses bare `-w` and the default name, so no reader meets either.
      *Ch. 11. Drafted.*

- [x] **V6 — Surfer locality.** Chapter 11's locality sentence stands. From
      Surfer's source (`main`): the browser build's Open-file picker is `rfd`'s
      `AsyncFileDialog`, i.e. `<input type="file">` plus the `File` API, and
      drag-and-drop calls `load_from_bytes` on bytes egui already read. The only
      network call is `reqwest::get(&url)`, used solely by the opt-in `load_url`
      command — which the WASM build offers *instead of* `load_file <PATH>`.
      Chapter 11 uses neither. *Ch. 11.*

- [x] **V17 — NVC on Debian and Ubuntu.** Split by distro; `apt install nvc`
      works on **neither**. Ubuntu 22.04/24.04 amd64: upstream's prebuilt `.deb`
      from `github.com/nickg/nvc` releases — the route the devcontainer uses and
      that every NVC check here exercised. Debian: no package in any suite and no
      Debian `.deb` in r1.20.1, so build from source per upstream's README
      (`./autogen.sh`, `../configure && make && sudo make install`; needs
      `build-essential automake autoconf flex check llvm-dev pkg-config
      zlib1g-dev libdw-dev libffi-dev libzstd-dev` and LLVM 8–21). *Ch. 10.*

---

## Language, libraries and code shape

- [x] **V12 — `Clash.Explicit.Prelude` completeness.** It carries chapters 1 to 9
      and 12 with **two** added imports in the whole spine, both in code that
      prints rather than in the circuit: `Clash.Explicit.Testbench` (ch. 10, V3)
      and `Data.Char (intToDigit)` (ch. 4, V23). Expect any third to follow that
      pattern.

      Chapter 8 needs no third: `pack`, `Generic`, `NFDataX`, `BitPack`, `Eq` and
      `Show` are all in scope for a `deriving` clause, and none of `Load`, `Step`,
      `Run`, `Pause`, `St`, `board` or `running` collides with anything the
      prelude exports (V28).

      In scope from the single import: `Vec`, `:>`, `Nil`, `map`, `zipWith`,
      `toList`, `head`, `foldl1`, `rotateLeftS`, `rotateRightS`, `d1`,
      `BitVector`, `pack`, `unpack`, `Signed`, `Unsigned`,
      `Clock`/`Reset`/`Enable`/`System`, `systemClockGen`/`resetGen`/`enableGen`,
      `register`, `mealy`, `sampleN`, `fromList`, `fmap`, `mapM_`, `putStr`,
      `Generic`/`NFDataX`/`BitPack` (plain and standalone deriving), `KnownNat`,
      `String`, `unlines`.

      The trap under `NoImplicitPrelude`: `concatMap`, `(++)` and `head` are the
      `Vec` versions, so list-based spellings fail with `Couldn't match expected
      type 'Vec n2 a0' with actual type '[a]'`. *Ch. 1 to 12.*

      Chapter 13 swaps the prelude for `Clash.Prelude` and the list above
      survives it unchanged: every name in it is exported by both, and the two
      added imports both stay (V35). *All chapters.*

- [x] **V16 — `default-extensions` sufficiency.** No per-file pragma is required
      in chapters 1 to 13. After D19, `GHC2024` supplies `BinaryLiterals`,
      `NumericUnderscores`, `DeriveGeneric` and `FlexibleContexts`;
      `common-options` still lists `DeriveAnyClass` and `TemplateHaskell`
      (`TemplateHaskellQuotes` dropped as implied). Chapters 1 to 4 verified
      (V24); 5 to 9 verified since. Chapter 8 is the first to need
      `DeriveAnyClass`, which is what lets `NFDataX` and `BitPack` sit in a plain
      `deriving` clause alongside `Generic` (V28), and chapter 9 is the first to
      need `TemplateHaskell`, which is what lets `{-# ANN life (Synthesize …) #-}`
      compile; `{-# OPAQUE step #-}` needs nothing (V30). Chapter 10 needs the same
      extension for `{-# ANN testBench (TestBench 'life) #-}`, and the quoted
      name in it needs nothing further (V31). Chapter 13 needs none of its own
      either: switching to `Clash.Prelude` and using `exposeClockResetEnable`
      compiles under the same set (V35). *All chapters.*

- [x] **V24 — the template under `GHC2024`.** D19 is buildable as written.
      `default-language: GHC2024` configures under `cabal-version: 2.4` with
      Stack's Cabal 3.12.1.0, in `code/` and in a generated project — no spec
      bump, no fallback. `FlexibleContexts` is what frees chapter 4's `digit`
      (differential compile: `-XNoFlexibleContexts` fails with `[GHC-80003] Non
      type-variable argument`); the monomorphism restriction never applied, since
      `digit n = …` is a function binding. `code/` builds all four chapter modules
      `-Wall -Wcompat` clean, `stack test` passes, and CI's `template` job passes
      by hand. Chapter 4's sixty transcript lines survived a from-scratch
      re-capture byte-identical.

      **The risk D19 accepts, discharged:** `MonoLocalBinds` has rejected
      nothing in chapters 5 to 13, every one of which builds `-Wall -Wcompat`
      clean in `code/`. `NoMonomorphismRestriction` was never put back.
      *All chapters.*

- [x] **V10 — `unpack` resolves for `fromRows`.** `map unpack` takes its
      `BitPack` instance from `fromRows`'s top-level signature alone — no
      annotation, no `TypeApplications`, no ambiguity. Held in the shipped chapter
      3 file and in every build run for this queue. *Ch. 3.*

- [x] **V8 — No type application needed.**
      `:t sampleN 5 (life systemClockGen resetGen enableGen)` gives `[Board]` with
      no `@System`: the domain is pinned by passing `systemClockGen`, an ordinary
      value, exactly as D4 claims. Re-observed in V26's session and shipped in the
      chapter. *Ch. 6. Drafted.*

- [x] **V11 — Widths.** 66 and 67 confirmed exactly, against chapter 8's
      monomorphic `Command` and `St`:

      ```
      clashi> import Data.Proxy
      clashi> natVal (Proxy @(BitSize Command))
      66
      clashi> natVal (Proxy @(BitSize (Maybe Command)))
      67
      clashi> natVal (Proxy @(BitSize Board))
      64
      ```

      `Command` is `CLog 2 4 = 2` tag bits plus `Load`'s 64-bit payload; `Maybe`
      adds one. **`:kind!` is the wrong command** — the plugins that normalise
      `CLog`/`Max` fire during constraint solving, not `:kind!` printing, so
      `:kind! BitSize Command` prints `CLog 2 4 + 64` unreduced. Any derivation
      shown must go through `natVal` or another forcing context. `BitSize St` is
      not available (`St` derives no `BitPack`) and no chapter asks for it.
      *Ch. 8, 11.*

- [x] **V1 — Chapter 12 is buildable.** `type Board n = Vec n (Vec n Bool)`
      compiles with `KnownNat n` added to `step`, `neighbourCounts`, `countBoard`,
      `addCounts` and the four shifts — no other structural change, as D9
      predicted. `neighbourBoards` stays `Vec 8` (eight directions), returning
      `Vec 8 (Board n)`.

      The chapter's pre-flagged pitfall: plain
      `deriving (Generic, NFDataX, BitPack, Eq, Show)` on `Command n` fails with
      `[GHC-95822] solveWanteds: too many iterations (limit = 4)` — generics
      cannot resolve `KnownNat (BitSize (Command n))` when `BitSize` depends on
      `n`. Fix is standalone deriving with an explicit context:

      ```haskell
      data Command n = Load (Board n) | Step | Run | Pause
        deriving (Generic, Eq, Show)

      deriving instance KnownNat n => NFDataX (Command n)
      deriving instance KnownNat n => BitPack (Command n)
      ```

      `StandaloneDeriving` is already on. Omitting `KnownNat n` from a plain
      function gives a readable `[GHC-39999] No instance for 'KnownNat n'` with an
      "add (KnownNat n) to the context" fix, not a generics wall.

      Two `topEntity`s from one `life` work: `-main-is topEntity8` and `-main-is
      topEntity16` each elaborate in under two seconds with different port widths
      (64 vs 256 `out boolean`). Note **`-main-is`**, not a bare module argument,
      is how 1.10.0 picks a binder not named `topEntity`.

      **That paragraph is superseded by D17 and is not chapter 12's route.**
      `-main-is` remains true as a fact about the compiler; what changed is that
      there is no `topEntity` to need it. Chapter 12 puts a `Synthesize`
      annotation on each of `life8` and `life16`, and one `:vhdl` generates both,
      so its command is chapter 9's unchanged. The port widths comparison also
      moves: with `t_output` named it is one `std_logic_vector(63 downto 0)`
      against one `(255 downto 0)`, not 64 `out boolean` against 256. The
      `KnownNat n` and standalone-deriving findings above are untouched.

      **The two things this entry owed are answered by V34.** `{-# OPAQUE step #-}`
      survives `step` becoming polymorphic and gives **two specialised
      components**, one per size, in the two entities' own directories. One
      correction to the paragraph above: `countBoard` and `addCounts` do **not**
      need `KnownNat n` — `map` and `zipWith` never ask a vector its length — and
      chapter 12 leaves them without it, which is what makes "put it where the
      compiler asks" a rule the reader can follow rather than a slogan.
      *Ch. 12. Drafted.*

- [x] **V13 — Chapter 13 diff.** Equivalent, not byte-identical — say so plainly.
      Chapter 12's `topEntity8` and a chapter 13 rewrite of identical logic
      (`import Clash.Prelude`, `HiddenClockResetEnable`,
      `topEntity8 = exposeClockResetEnable life`) differ in 342 of 761 lines, all
      of it Clash's name-mangling of the polymorphic `St n` and the mealy
      machine's initial-state signal:

      - port list identical line for line except one input's *name*, `carg` vs
        `eta` — same position, type, width;
      - one clocked process each, same `rising_edge(clk)` shape:
        `st_register` vs `cds_app_arg_register`;
      - same state record fields renamed: `St_0`/`St_0_sel0_board`/
        `St_0_sel1_running` vs `St`/`St_sel0_board`/`St_sel1_running`;
      - same line count (761).

      Behaviour was not re-simulated: `lifeT`/`step` are the same unchanged
      Haskell and the structural comparison accounts for every byte. If the
      chapter shows a diff, point at the port and type names rather than asserting
      "identical".

      **The numbers are void and the check must be re-run (V30).** Both sides of
      that diff were `topEntity`s, un-annotated and flat; chapter 12's output is
      now two entities, each with named ports and each split by
      `{-# OPAQUE step #-}`, so "same line count (761)" measures nothing that
      still exists. Re-run it as a directory to directory diff. The conclusion —
      equivalent, not byte-identical, and say which — is what stands. Two
      predictions worth testing rather than asserting: the port list should now be
      identical including names, since the annotation supplies them on both sides,
      and the step file should be byte-identical between the two chapters, leaving
      only the wrapper's file to differ.

      **Re-run 2026-08-09 as V35, and both predictions held.** The entity
      declarations are byte identical, both step entities are byte identical and
      so is the whole test bench directory; four files of eleven differ and every
      difference in them is an identifier. The conclusion stands as written and
      the chapter says "equivalent" rather than "identical". *Ch. 13. Drafted.*

---

## REPL and transcript conventions

- [x] **V7 — `:i` under the explicit prelude.** With the module loaded,
      `:i register` and `:i mealy` print ordinary function types with `Clock`,
      `Reset` and `Enable` as plain arguments — no `HiddenClockResetEnable`, no
      implicit parameter. D4 needs no revisiting. `clashi` with no argument loads
      no project module, so chapter 1 passes the module on the command line (D13),
      and the prompt stays `clashi>` (D12). `stack build`'s last line is
      `Registering library for life-0.1.0.0...` — chapter 1's marker that the long
      build finished. The old `[GHC-74335] -Winconsistent-flags` warning is gone
      since 2026-08-07: `bin/Clashi.hs` now prepends
      `-fno-unoptimized-core-for-interpreter`. *Ch. 1, 6, 7. Ch. 1 drafted.*

- [x] **V21 — chapter 2's session.** Captured 2026-08-08 through a pty, with the
      file swapped on disk while `clashi` held the old module, so `:r` is a real
      reload. `:r` answers `Ok, one module reloaded.`, not the startup wording.
      One prose claim checked outside the transcript: `nextCell True 12` is
      `False` — stated, not shown, because showing it would put a count on screen
      the finished design cannot produce. *Ch. 2. Drafted.*

- [x] **V22 — chapter 3's session.** Captured 2026-08-08, two real reloads.
      Durable findings:

      - **`:i` on a type synonym prints a kind line first** — `:i Board` gives
        `type Board :: Type`, the synonym, then `-- Defined at`.
      - `head glider` prints one 74-character line; the whole `glider` is one
        unbroken 646-character line, which is why `render` exists.
      - `putStr (render glider)` ends in a newline (`unlines` terminates every
        row), so the next prompt starts at column 0.

- [x] **V23 — chapter 4's session.** Captured 2026-08-08, three real reloads, run
      twice byte-identically. Durable findings:

      - **`numConvert`, not `fromIntegral` (D18).**
        `numConvert (3 :: Unsigned 4) :: Int` is `3`; the conversion exists in
        1.10.0 and resolves to `Int`. It once cost a `where`-clause signature; D19
        removed that (`GHC2024` supplies `FlexibleContexts`) and the error is no
        longer reachable by a reader following the shipped configuration (V24).
      - **`:i rotateLeftS` is short enough to print** —
        `rotateLeftS :: KnownNat n => Vec n a -> SNat d -> Vec n a` — which is how
        chapter 4 pre-flags `d1` by showing rather than describing.
      - **The `d1` pitfall's error**, from building with `rotateLeftS b 1`:
        `[GHC-39999] No instance for 'Num (SNat d0)' arising from the literal
        '1'`. Described in half a sentence, never put on screen: no step may fail.
      - `neighbourCounts` for `glider` is
        `11210000 / 35320001 / 13220001 / 23210001 / 0 / 0 / 0 / 11100000`; the
        corner `1`, the `5` at row 1 column 1, and the `1`s in column 7 and row 7
        are the wrap, all three checked by hand against chapter 3's picture.
      - `stack run clash -- Chapters.Ch04 -main-is neighbourCounts --vhdl`
        elaborates with no `topEntity` and no `Signal`: 656 lines, 64 `in boolean`
        and 64 `out unsigned(3 downto 0)` ports, no clock, no process, the `map`s
        and `zipWith`s as nested `for … generate` blocks labelled `-- map begin`,
        and exactly one `+`.

      **The check owed by chapter 9, discharged 2026-08-09.** Chapter 4's last
      "notice that" promises the reader will see these `map`s as `for … generate`
      in chapter 9. What was checked here is chapter 4's code elaborated alone;
      V30 checked chapter 9's real output and the promise holds there too, single
      `+` included, in `Example_Project_life_step.vhdl` rather than in the top
      entity's own file. Chapter 4's sentence stands as written.

- [x] **V25 — chapter 5's session.** Captured 2026-08-08, one real reload, the
      file swapped on disk while `clashi` held the old module. Durable findings:

      - **`:i step` uses the same-line `-- Defined at` form** —
        `step :: Board -> Board 	-- Defined at src/Example/Project.hs:73:1` —
        which is the short-signature form already seen for `glider` and `shiftN`.
        Line 73 is where `step`'s definition lands for a reader who has followed
        chapters 2 to 4 in order, appended under `renderCounts`.
      - **`-- Defined at` reports the definition, not the signature.** Chapter 4
        quotes `shiftN` at 37 and `neighbourCounts` at 63 because at that point in
        the chapter `import Data.Char (intToDigit)` has not been added yet; it
        quotes `renderCounts` at 67 because by then it has. Both are right, and
        the rule that makes them right is that the number moves with the reader.
      - **Four generations of `glider` are the seed displaced by one cell
        diagonally**, `(+1,+1)`, and the intermediate three are
        `#.# / .## / .#` at rows 1 to 3, then `..# / #.# / .##`, then
        `.# / ..## / .##`. Checked against a 32×32 unbounded simulation: identical
        for all four (this is what corrects V9).
      - **A generation elaborates as combinational logic.**
        `stack run clash -- Chapters.Ch05 -main-is step --vhdl` gives a 688-line
        `step.vhdl` plus a 185-line types package: 64 `in boolean`, 64
        `out boolean`, **zero** occurrences of `clk`, `rising_edge` or `process`,
        seven `-- map begin` blocks and exactly one `+`. This is what the
        chapter's "no clock, and there has not been one for five chapters" beat
        rests on.
      - **The argument order is checked, and stating it is safe.** Swapping
        `step`'s two arguments gives `[GHC-83865] Couldn't match type 'Unsigned 4'
        with 'Bool'`, twice, with `Expected`/`Actual` naming `Board` and `Counts`.
        Stated in the chapter, never put on screen: no step may fail. *Ch. 5.
        Drafted.*

- [x] **V26 — chapter 6's session.** Captured 2026-08-08, one real reload, the
      file swapped on disk while `clashi` held the old module. Durable findings:

      - **`:i register` prints in five lines**, the signature broken after
        `Clock dom`, byte-identical to the one V7 captured two days and one
        template change earlier. `-- Defined in` takes the next-line form.
      - **`:i life` uses the same next-line form**, its signature broken after
        `Clock System`, and reports `src/Example/Project.hs:78:1`: signature at
        75, definition at 78, for a reader who has followed chapters 2 to 6 in
        order with both imports present.
      - **Printing a `Signal` is not a type error.**
        `:t print (life systemClockGen resetGen enableGen)` is `IO ()`, and
        evaluating the signal at the prompt produced 9 MB of `:>` in fifteen
        seconds without finishing. The chapter's pre-flag therefore says that it
        typechecks and never ends, not that it is rejected. Never put on screen:
        no step may fail.
      - **The five samples are V9's, unchanged**, and the first two are the seed.
      - **`life` elaborates with a clock and exactly one register.**
        `stack run clash -- Chapters.Ch06 -main-is life --vhdl` gives a 707-line
        `life.vhdl` plus a 199-line types package: `clk`, `rst` and `en` ports,
        64 `out boolean` and **no** `in boolean`, since the board now comes from
        the register rather than from outside; one process `boards_8_register`
        with one `rising_edge(clk)`; the glider written out in full as what the
        reset branch assigns; `en` gating the clocked assignment; and the same
        seven `-- map begin` blocks and single `+` chapter 5 counted. Not shown
        in the chapter, which stays at the prompt, but it is what makes the
        chapter's "exactly one register, because `register` was written once"
        beat safe to state. *Ch. 6. Drafted.*

- [x] **V27 — chapter 7's session.** Captured 2026-08-08, two real reloads, the
      file swapped on disk while `clashi` held the old module, and run twice
      byte-identically. Durable findings:

      - **The reset swallows the input on cycle 0.** `resetGen` holds the reset
        for the first two cycles, and the first input a `mealy` machine acts on is
        the one arriving in cycle 1, whose effect is visible in sample 2. So
        `fromList [Just blinker, Nothing, …]` prints chapter 6's boards and the
        blinker never appears — checked, not reasoned. Chapter 7 therefore loads
        on the fourth element of a seven-element stimulus, which also lets the
        glider run two generations first.
      - **`fromList` is in scope from `Clash.Explicit.Prelude`** and needs no
        annotation: `:t fromList [Nothing, Nothing, Nothing, Just blinker,
        Nothing, Nothing, Nothing]` is `Signal dom (Maybe Board)`, with `dom` left
        open. The list must be at least as long as the `sampleN`, and the chapter
        matches the two at seven so the reader never reaches the end.
      - **`:i mealy` prints in ten lines**, one argument per line, with
        `-- Defined in `Clash.Explicit.Mealy'` in the next-line form. `:i lifeT`
        takes the next-line form at `src/Example/Project.hs:88:1` and `:i life`
        the one-argument-per-line form at `97:1`, for a reader who has followed
        chapters 2 to 7 in order.
      - **`Maybe Board` is 65 bits, and it is one port.**
        `natVal (Proxy @(BitSize (Maybe Board)))` is `65` and
        `natVal (Proxy @(BitSize Board))` is `64` (method as in V11). In the
        generated VHDL the types package has
        `subtype Maybe is std_logic_vector(64 downto 0)` and `life`'s input is the
        single port `carg : in …Maybe`. The payload is decoded unconditionally —
        `seed <= …fromSLV(carg(63 downto 0))` — and discarded by
        `with (carg(64 downto 64)) select`, which is what makes the chapter's
        "nothing is switched off" sentence true rather than plausible.
      - **The enforcement is a scope error, not a type error.** Writing the
        `Nothing` row in terms of `seed` gives `[GHC-88464] Variable not in scope:
        seed :: Board`. Stated in the chapter, never put on screen: no step may
        fail.
      - **`lifeT` alone is combinational.**
        `stack run clash -- Chapters.Ch07 -main-is lifeT --vhdl` gives a 923-line
        `lifeT.vhdl` plus a 211-line types package with **zero** occurrences of
        `clk`, `rising_edge` or `process`: 64 `in boolean` and one `in Maybe` for
        the input, 128 `out boolean` for the returned pair. `life` itself is 716
        lines with one process, `current_8_register`, and one `rising_edge(clk)`,
        so the state is still exactly one register. Not shown in the chapter,
        which stays at the prompt. *Ch. 7. Drafted.*

- [x] **V28 — chapter 8's session.** Captured 2026-08-08, two real reloads, the
      file swapped on disk while `clashi` held the old module, and run twice
      byte-identically. Durable findings:

      - **`pack` is how the widths go on screen, and `:t pack` is not.**
        `pack Step` prints
        `0b01_...._...._...._...._...._...._...._...._...._...._...._...._...._...._...._....`,
        which is two tag bits and sixty-four payload bits countable in one
        84-character line, and `pack (Load blinker)` prints the same shape with
        the blinker in the payload. The tags run in declaration order: `Load` is
        `00`, `Step` `01`, `Run` `10`, `Pause` `11`. `pack (Just Step)` is
        sixty-seven bits, `0b101_…`. This confirms V11's 66 and 67 by a second
        method and, unlike `natVal`, needs neither `Data.Proxy` nor a type
        application, so it does not reopen what D4 closed.

        **`:t pack Step` is useless here** and must not be shown: it prints
        `BitVector (CLog 2 4 + 64)`, and `:t pack (Just Step)` prints
        `BitVector (CLog 2 2 + Max 0 (CLog 2 4 + 64))`. Same cause as V11's
        `:kind!` finding: the normalising plugins fire during constraint solving,
        not when a type is printed. Evaluating the value forces it; asking for its
        type does not.

      - **`:i Command` is unshowable; `:i` on a constructor is the instrument.**
        `:i Command` prints the declaration, five `instance` lines, and then the
        `BitSize Command` type family instance unreduced through
        `GConstructorCount`/`GFieldSize`/`Rep`, eleven lines of generics the
        reader cannot parse. `:i Load` prints three lines,
        `data Command = Load Board | ...`, and `:i Step` prints
        `data Command = ... | Step | ...`, each with the other constructors
        elided and `-- Defined at src/Example/Project.hs:88:5` and `:89:5` in the
        next-line form. `:i St` is clean at five lines, declaration plus
        `instance Generic St` and `instance NFDataX St`, and is shown.

      - **The line numbers a reader following chapters 2 to 8 in order sees:**
        `Command` at 87, its constructors at 88:5 and 89:5, `St` at 94, `lifeT`
        at 98, `life` at 110. `:i lifeT` takes the next-line form and `:i life`
        the one-argument-per-line form, as in V27.

      - **The eleven-cycle stimulus and what it prints.** With
        `[Nothing, Nothing, Just Step, Nothing, Just Run, Nothing, Nothing, Just
        Pause, Just (Load blinker), Nothing, Nothing]` the eleven boards are
        `glider` three times, the first generation three times, then the second,
        the third twice, and `blinker` twice. Two of the leading three are
        `resetGen` as ever; the third is the new beat, and it is the seed rather
        than the first generation because `mealy`'s initial state is
        `St glider False`. A command is taken in on the cycle it arrives and its
        effect is one board later, exactly as V27 established for chapter 7.

      - **`life` elaborates with one register and one port for the input.**
        `stack run clash -- Chapters.Ch08 -main-is life --vhdl` gives a 761-line
        `life.vhdl` plus a 226-line types package. The types package has
        `subtype Command is std_logic_vector(65 downto 0)` and
        `subtype Maybe is std_logic_vector(66 downto 0)`, which is V11's 66 and
        67 a third time. One process, `st_register`, one `rising_edge(clk)`, one
        `eta : in …Maybe`, 64 `out boolean` and no `in boolean`; the same seven
        `-- map begin` blocks and single `+` counted since chapter 5. The state
        is `type St_0 is record St_0_sel0_board … St_0_sel1_running : boolean`,
        so the record survives into the hardware as a record, which is what makes
        the chapter's "it stays a record" sentence safe. The tag decode is two
        nested selects, `with (eta(66 downto 66)) select` and
        `with (…(65 downto 64)) select`, and the payload is decoded
        unconditionally by `b <= …fromSLV(eta(63 downto 0))` and discarded by the
        select, which is V27's "nothing is switched off" holding for a four-way
        command rather than for `Maybe`. Not shown in the chapter, which stays at
        the prompt. *Ch. 8. Drafted.*

- [x] **V29 — the template with no `topEntity` (D17).** Checked 2026-08-09
      against a project generated from the edited `.hsfiles`. Durable findings:

      - **The shipped module is `plus` and nothing else**, and the project still
        builds and tests: `stack build` ends on
        `Registering library for life-0.1.0.0...` and `stack test` passes, so
        chapter 1's marker for the end of the long build is unchanged.
      - **`-main-is plus` is what makes the template's documented command work.**
        `stack run clash -- Example.Project --vhdl` on a fresh project now fails
        with `No top-level function called 'topEntity' or 'testBench' found, nor
        any function annotated with a 'Synthesize' or 'TestBench' annotation`, so
        both places the template writes that command — the comment above the
        `clash` stanza and the generated `README.md` — carry `-main-is plus`.
        With it, `Clash: Compiling Example.Project.plus` and three files under
        `vhdl/Example.Project.plus/`.
      - **Chapters 1 and 2's sessions survive the deletion byte-identically**,
        re-captured on a project from the edited template: the `clashi` banner
        and `Ok, one module loaded.`, `:i plus` at
        `src/Example/Project.hs:6:1`, `:t plus 3`, `plus 3 5`, then chapter 2's
        `:r`, `:i nextCell` at `6:1` and its six evaluations. `plus` and
        `nextCell` both sit above the deleted lines, which is why nothing moved
        — confirmed rather than assumed. *Ch. 1, 2. Drafted.*

- [x] **V30 — chapter 9's session, and the two generations it produces.**
      Captured 2026-08-09 on a project generated from the edited template, two
      real reloads, run three times with every generated `.vhdl` byte-identical
      across runs. Durable findings:

      - **`:vhdl` needs no argument, finds the annotated binder, and prints no
        warning after one template change.** It compiles the module to object
        code, generates, and reloads the interpreted module, which is the pair of
        `Compiling` lines around its dozen timing lines. It used to print
        `[GHC-74335] [-Winconsistent-flags] -dynamic-too is ignored when using
        -dynamic` first; `bin/Clashi.hs` now prepends `-Wno-inconsistent-flags`
        as well as `-fno-unoptimized-core-for-interpreter`, and it is gone. Same
        precedent and reasoning as V7's addendum. `bin/Clash.hs` needs no such
        flag — `stack run clash -- … --vhdl` never printed it. The timing lines
        vary run to run, so the chapter says the numbers are the capture
        machine's and that the order of magnitude is seconds.
      - **The port names come out exactly as written**, `en` included:
        `clk`, `rst`, `en`, `cmd : in life_types.Maybe` and
        `cells : out std_logic_vector(63 downto 0)`, with Clash's `-- clock`,
        `-- reset` and `-- enable` comments over the first three. Naming the
        output collapses the board from sixty-four `out boolean` to one 64-bit
        port; naming the arguments of a point-free `topEntity` never did anything
        at all, which is what the withdrawn draft had to say instead.
      - **`cmd` and `cells` are chosen to avoid collisions, and they work.**
        With `command` and `board` the types package comes out with
        `subtype Command_0` and `St_0_sel0_board_2`, because VHDL is case
        insensitive and Clash renames the generated identifier rather than the
        port. With `cmd` and `cells` it reads `subtype Command is
        std_logic_vector(65 downto 0)`, `subtype Maybe is
        std_logic_vector(66 downto 0)` and `St_0_sel0_board`, which is V28's
        chapter 8 output unchanged.
      - **Run one, annotation only: four files** into
        `vhdl/Example.Project.life/` — `life.vhdl` (548 lines),
        `life_types.vhdl` (227), `life.sdc` and `clash-manifest.json`. The
        directory is named for the module and the binder; the three file names
        come from `t_name`.
      - **Run two, after `{-# OPAQUE step #-}`: five files.** `life.vhdl` drops
        to 211 and `Example_Project_life_step.vhdl` (343) appears. Nothing stale
        survives run one. **The entity declaration is byte identical between the
        two runs**, which is the chapter's beat: the interface did not move.
      - **All the combinational logic crosses the boundary.** `life.vhdl` has
        **zero** `+`, zero `-- map begin` and zero `-- zipWith begin`; the step
        file has one `+`, seven `-- map begin` and five `-- zipWith begin`. The
        step entity is `b : in …array_of_array_of_8_boolean(0 to 7)` and
        `result : out` the same, ports Clash named. It is instantiated **once**,
        `Example_Project_life_step_result_0`, feeding both the `"01"` row and the
        running case, which is what makes chapter 6's "one copy of `step`" claim
        showable at last.
      - **Chapter 4's promise holds, in the step file.** `zipWith_3`/
        `zipWith_2_0` are two nested `for … generate` over sixty-four copies of
        the cell rule, with `to_unsigned(2,4)`, `to_unsigned(3,4)` and a
        `when … else` chain in chapter 2's row order, reading the port directly
        as `b(i_10)(i_9_2)`. `zipWith_1`/`zipWith_0`/`zipWith_4` are three deep,
        seven by eight by eight, around the single `+`: chapter 4's four hundred
        and forty-eight additions exactly. This is what V23 left owed.
      - **`life.vhdl` still holds the state.** One process `st_register`, one
        `rising_edge(clk)`, `en` gating the assignment, sixty-five lines of reset
        value of which sixty-four are board literals with five `true`; the two
        selects on `cmd(66 downto 66)` and `cmd(65 downto 64)` with `Load`,
        `Step`, `Run`, `Pause` at `"00"` to `"11"`; and
        `b <= …fromSLV(cmd(63 downto 0))` with no condition on it.
      - **`{-# ANN #-}` needs no per-file `LANGUAGE` pragma** and neither does
        `OPAQUE`: `TemplateHaskell` in `default-extensions` is enough, and
        `code/` builds `Chapters.Ch09` `-Wall -Wcompat` clean with both. V16's
        claim holds for chapter 9.
      - **`:i` adds nothing to this chapter and is not shown.** `:i life` prints
        chapter 8's signature at a new line number and says nothing about the
        annotation; `:i step` prints `step :: Board -> Board` in the same-line
        form and says nothing about the pragma.
      - **`clash-manifest.json`'s `hash` field differs between otherwise
        identical runs.** Every `.vhdl` file is byte identical; only that field
        moves. Nothing in any chapter reads it, and nothing should start.
      - **The output analyses, in dependency order.**
        `nvc -a life_types.vhdl Example_Project_life_step.vhdl life.vhdl` exits
        0. Alphabetical order does not: `life.vhdl` sorts before
        `life_types.vhdl`. Not shown in chapter 9, which stops at reading the
        files, but it is the chapter-9 half of V3 and it is why chapter 10's
        ordering pre-flag got sharper. *Ch. 9. Drafted.*

- [x] **V31 — chapter 10's session, the two entities and the simulation.**
      Captured 2026-08-09 on a project generated from the edited template, two
      real reloads, and the session re-run three times. Durable findings:

      - **A `TestBench` annotation is enough, and one `:vhdl` generates both.**
        `{-# ANN testBench (TestBench 'life) #-}` needs no per-file `LANGUAGE`
        pragma beyond the `TemplateHaskell` already in `default-extensions`, and
        the output is two directories named for their binders:
        `vhdl/Example.Project.life/` and `vhdl/Example.Project.testBench/`. The
        test bench directory gets no `.sdc`.
      - **A `Synthesize` annotation is not a boundary.** Without
        `{-# OPAQUE life #-}` the whole of `life` is inlined into
        `testBench.vhdl`, which then holds its own `step.vhdl` and its own types
        package, mentions `life` nowhere, and is self-contained in one directory
        and one library. With the pragma, `testBench.vhdl` has
        `life_cExampleProjecttestBench_app_arg : entity life.life` and a port map
        of `clk_0, rst_0, en_0, cmd_0, cells_0`. The three files in
        `Example.Project.life/` are **byte identical either way**, and byte
        identical to chapter 9's second run: 211, 227 and 343 lines. This is D21.
      - **The pragma costs two trace lines.**
        `Not specializing TopEntity: Example.Project.life[8214565720323891532]`,
        printed twice, between `Clash: Compiling Example.Project.testBench` and
        the normalisation timings. Not suppressible: `-fclash-debug DebugNone`,
        `-v0` and `-fclash-spec-limit=0` all leave it. The bracketed number is
        GHC's unique for the binder and it is **not stable across session
        shapes** — `stack run clash` gives `…787780`, the captured session
        `…891532`, and adding two commands at the prompt before `:vhdl` moved it
        again. `tools/check_transcripts.py` blanks it, and the chapter says it
        will differ.
      - **Two top entities compile concurrently and print out of order.** Two
        captures of the identical session produced two different interleavings of
        the `Compiling`/`Normalization`/`Netlist generation` lines, and the
        `Not specializing` lines appeared once in one run and twice in another.
        `-fclash-no-concurrent-topentity-compilation` in `bin/Clashi.hs` fixes
        the order; with it, two full captures are byte identical apart from the
        timings, and every generated `.vhdl` is byte identical. This is D22, and
        chapter 12 will need it for the same reason.
      - **The eight-command stimulus and what it produces.** With
        `[Nothing, Nothing, Just Step, Just Run, Nothing, Just Pause,
        Just (Load blinker), Nothing]` the eight boards are `glider` three times,
        the first generation twice, the second twice, and `blinker`. `Run` sets
        the mode without stepping, which is what puts the second repeat there,
        and the rule that a command arriving on a cycle shows up one board later
        is V28's, unchanged. The two new pictures go into the source as `glider1`
        and `glider2`.
      - **`sampleN 12 testBench` is nine `False` then three `True`**, and prints
        nothing else: the test bench passes in Haskell before it leaves it.
        `:i stimuliGenerator` prints in four lines and `:i outputVerifier'` in
        five, both ending `-- Defined in ‘Clash.Explicit.Testbench’` in the
        same-line form.
      - **One `nvc` invocation, six files, and it prints nothing.** From `vhdl/`:

        ```
        nvc --ieee-warnings=off --work=life \
            -a Example.Project.life/life_types.vhdl \
               Example.Project.life/Example_Project_life_step.vhdl \
               Example.Project.life/life.vhdl \
               Example.Project.testBench/Example_Project_testBench_types.vhdl \
               Example.Project.testBench/testBench_slv2string_*.vhdl \
               Example.Project.testBench/testBench.vhdl \
            -e testBench -r
        ```

        Exit 0 and no output, so the chapter asks with `echo $?`. `--work=life`
        is load bearing: `entity life.life` is library qualified, and without the
        flag the run fails with `design unit depends on WORK.TESTBENCH which was
        analysed with errors`. Analysing the entity into its own library in a
        separate `nvc --work=life -a …` and then elaborating with `-L .` also
        works, and is not what the chapter does, because one command is the
        convention. `--std` is still omitted (V4).
      - **`--ieee-warnings=off` must be a global option**, before `-a`. After
        `-r` NVC answers `the --ieee-warnings option may have no effect as the
        IEEE packages have already been initialised`. What it suppresses is 257
        warnings in 771 lines, all `NUMERIC_STD."=": metavalue detected` and all
        at `0ms+0` or `0ms+4`, from the neighbour counts before any signal has
        settled.
      - **A wrong expected board fails visibly.** Replacing the eighth expected
        board gives `** Error: 180ns+1: outputVerifier, expected: <64 bits>,
        actual: <64 bits>` and exit 1. Quoted in the chapter in prose, never put
        on screen: no step may fail.
      - **`testBench.vhdl` is 629 lines from `clashi` and holds three things
        worth reading.** The same source through `stack run clash` gives 632
        lines and a different set of generated signal names, with or without the
        concurrency flag; each route is reproducible on its own, and the book
        quotes the interactive one because that is what the chapter runs.
        The stimulus is one `array_of_Maybe` aggregate at lines 103 to 173, of
        which the `Load` entry alone is sixty-four lines; a `Nothing` is
        `"0" & "---…"` and `Just Step` is `"1" & ("01" & "---…")`, which is
        chapter 8's `pack` output as a VHDL literal. The instantiation is at 605.
        The clock generator's `while (not \c$result_rec\) loop` is at 207, and it
        is what `tbSystemClockGen (fmap not done)` compiles to. There are six
        `-- pragma translate_off` regions: two index guards, the clock, the reset
        and the assertion.
      - **Clash caches generated results, and a replay must not inherit them.**
        A second `:vhdl` over an unchanged source answers `Clash: Using cached
        result for: Example.Project.life` instead of the normalisation timings,
        so `tools/check_transcripts.py` deletes the HDL tree before replaying a
        chapter. No chapter is affected — every `:vhdl` in the book follows an
        edit — but running the checker twice in a row was, which is how this was
        found.
      - **CI runs the same command against `code/`**, where the module name
        changes the generated file names and nothing else. *Ch. 10. Drafted.*

- [x] **V32 — chapter 11's waveform, and everything in it.** Captured
      2026-08-09 on a project generated from the edited template, holding
      chapter 10's end state, with the VHDL generated by `clashi`'s `:vhdl` so
      that the signal names are the ones chapter 10 quotes. Durable findings:

      - **The command is chapter 10's with `-w` on the end**, and that is the
        whole edit. Exit 0, and it prints exactly two notes:
        `** Note: writing FST waveform data to testBench.fst` and
        `** Note: arrays of composite types such as ARRAY_OF_ARRAY_OF_8_BOOLEAN
        are not dumped by default, pass --dump-arrays to include these in the
        waveform dump`. The file lands in `vhdl/`, beside the two generated
        directories. Re-running in place, over the `life` library chapter 10
        left there, prints the same two notes and nothing else.
      - **The second note is about our `Board`.** `ARRAY_OF_ARRAY_OF_8_BOOLEAN`
        is `Vec 8 (Vec 8 Bool)`: the `step` entity's two ports and ten of its
        internal signals have that type, `life.vhdl` declares four more, and
        `St_0`'s first field is one, so what the dump leaves out is every board
        in the design. The chapter says that rather than counting them.
        `--dump-arrays` suppresses the note and takes the
        file from 4004 bytes to 11232; the chapter does not pass it, because
        `cells` is the same board packed into one 64-bit vector and the flag
        buys sixty-four more names in a hierarchy that already has 4800.
      - **The size is not byte stable and no exact figure may be quoted.** Four
        runs gave 4005, 4004, 4004, 4004 bytes with four different checksums:
        the file holds a timestamp. The *value-change data* is deterministic —
        two runs dumped as VCD are byte identical below `$enddefinitions` — so
        the chapter quotes times and values exactly and says "about four
        kilobytes".
      - **The note wraps, and the book quotes it unwrapped.** At 80 columns NVC
        breaks the second note into three lines with a nine-space continuation
        indent and a trailing space on each break; at 200 it is one line. The
        wrap is a fact about the reader's terminal rather than about NVC, and
        trailing whitespace in a fenced block is not worth shipping, so the
        chapter shows the single-line form. Nothing checks it:
        `tools/check_transcripts.py` compares `clashi> …` blocks and ```vhdl
        blocks, and a `$ …` shell block is neither.
      - **The hierarchy, read out of the file rather than out of a viewer.** The
        FST is one `ZWRAPPER` block holding a gzip stream; inside it the
        hierarchy block is gzip again, 108348 bytes of it, and it holds the same
        names the same run dumps as VCD. Root scope `testbench` with 19
        variables, among them `clk_0`, `rst_0`, `en_0`, `cmd_0[66:0]` and
        `cells_0[63:0]`; one scope below it,
        `life_cexampleprojecttestbench_app_arg`, holding exactly `clk`, `rst`,
        `en`, `cmd[66:0]`, `cells[63:0]`, a record scope `st` with
        `st_0_sel1_running` in it, three more record scopes with the same one
        field (`result`, `\c$ds_case_alt\`, `\c$ds_case_alt_0\`), and two
        `\c$ds_case_alt_selection…` variables; and last,
        `example_project_life_step_result_0`, holding 1890 nested
        `for … generate` and block scopes and 768 of the dump's 800 variables.
        3197 scopes in the file and 4800 name strings in its hierarchy block.
        Every record of type `St_0` shows one field where the record has two,
        which is the second note again: the other field is a board.
      - **Names are folded to lower case.** A VHDL identifier is case
        insensitive and NVC writes the dump in lower case unless
        `--preserve-case` is passed, so chapter 10's
        `\Example.Project.testBench_clk\` appears as
        `\example.project.testbench_clk\`. Chapter 9's five port names were
        lower case already and arrive unchanged, which is worth one sentence
        and is the second time those names have paid for themselves.
      - **VHDL `BOOLEAN` is dumped as a string-typed variable**, values `true`
        and `false`: `en`, `st_0_sel1_running` and `\c$result_rec\` are all of
        them. This is the one shape in chapter 11 whose *rendering* is the
        viewer's business rather than the file's, which is why V33 names it.
      - **The times, exact and reproducible.** `clk` is low until 100 ns and
        toggles every 5, so the rising edges are at 100 to 180 ns, ten apart,
        and the last fall is at 185 ns; the dump's last timestamp is 190 ns.
        `rst` is high from zero and falls at 110 ns. `en` is `true` throughout.
        `cmd` is `0` and sixty-six `-` until 120 ns, then `101` at 120, `110` at
        130, `0` again at 140, `111` at 150, `100` followed by the blinker at
        160, and `0` again at 170 — chapter 10's eight-element stimulus, with
        `Load`, `Step`, `Run` and `Pause` at `00`, `01`, `10` and `11` exactly
        as V28's `pack` printed them. `cells` is `glider` until 130,
        `glider1` from 130, `glider2` from 150 and `blinker` from 170.
        `st_0_sel1_running` is `true` from 140 to 160. `\c$result_rec\`, which
        is `done`, goes `true` at 180, and the clock stops after it.
      - **`pack` on a board is the dictionary between the pictures and the
        bus**, and needs nothing chapter 8 did not already introduce:
        `pack glider` is
        `0b0100_0000_0010_0000_1110_0000_0000_…`, two groups of four to a row,
        and the four boards `cells` takes are `glider`, `glider1`, `glider2`
        and `blinker`. This is the chapter's only REPL block and the only thing
        `tools/check_transcripts.py` can check in it.
      - **Filtering the dump was tried and rejected.** `--include`/`--exclude`
        match colon-separated paths, so `--include=':testbench:*'` keeps
        everything and `--include='*cmd*'` keeps one variable; `/testbench/*`
        and `testbench.*` match nothing, and a dump with nothing in it kills
        the run with `** Fatal: 190ns+0: fstReaderOpen failed for temporary FST
        file`. A glob that fails fatally is not something to put in front of a
        reader, and the composite-array note is cheaper to explain than to
        suppress. This is D23.
      - **The FST embeds the absolute path of the VHDL source** as a source
        attribute, so the file carries the reader's directory layout. Not
        mentioned in the chapter: the locality sentence there is about what
        Surfer sends, which is nothing (V6), and the chapter never suggests
        sending the file anywhere. *Ch. 11. Drafted.*

- [x] **V34 — chapter 12's session, and the two entities it produces.** Captured
      2026-08-09 on a project generated from the edited template, holding chapter
      11's end state, two real reloads and one `:vhdl`. Durable findings:

      - **`Board n` costs less than V1 predicted.** `code/` builds
        `Chapters.Ch12` `-Wall -Wcompat` clean with `KnownNat n` on `fromRows`,
        the four shifts, `neighbourBoards`, `neighbourCounts`, `step` and
        `lifeT`, and on **neither** `countBoard` nor `addCounts`. `render` and
        `renderCounts` need no constraint either: `map`, `zipWith` and `toList`
        never ask a vector its length. Standalone deriving is needed exactly
        where V1 said, for `NFDataX` and `BitPack` on `Command n` and `NFDataX`
        on `St n`; `Generic`, `Eq` and `Show` stay in the plain clause.
      - **`life` takes its seed as an argument, and this was not on paper.**
        `mealy`'s initial state was `St glider False` and `glider` is a
        `Board 8`, so a `life` that does not know `n` cannot name its seed.
        `life seed clk rst en = mealy clk rst en lifeT (St seed False)` is the
        whole change, and it is a fifth argument added to the 8×8 design for the
        16×16 design's sake. This is D24.
      - **A point-free binder does get its port names.** `life8 = life glider`
        with a `Synthesize` annotation on it generates
        `clk`, `rst`, `en`, `cmd : in life8_types.Maybe` and
        `cells : out std_logic_vector(63 downto 0)`, exactly as written. V30's
        remark that naming the arguments of a point-free `topEntity` "never did
        anything at all" was about a binder with no annotation of its own to
        take names from, and does not generalise: `t_inputs` matches the type's
        arguments, not syntactic lambdas.
      - **One `:vhdl`, three binders, fourteen files in three directories.**
        `Example.Project.life8/` and `Example.Project.life16/` hold five each
        (`.vhdl`, `_types.vhdl`, the step entity, `.sdc`, manifest) and
        `Example.Project.testBench/` holds four. With
        `-fclash-no-concurrent-topentity-compilation` (D22) the order is fixed:
        `life16`, then `life8`, then `testBench`, with the two
        `Not specializing TopEntity: Example.Project.life8[…]` lines in the
        third. Three top entities rather than two is the reason D22 matters more
        here than it did in chapter 10.
      - **`{-# OPAQUE step #-}` gives two specialised components.** This is what
        V1 left owed. `Example_Project_life8_step.vhdl` and
        `Example_Project_life16_step.vhdl` are **343 lines each**; every line of
        one has a line of the other in the same position; 55 lines per side
        differ in a number (`0 to 7`/`0 to 15`, `1 mod 8`/`1 mod 16`) and 7 more
        differ only in alignment, because `array_of_array_of_16_boolean` is one
        character longer than `array_of_array_of_8_boolean`. Normalising every
        digit run and ignoring whitespace makes them identical. Each carries one
        `+`, seven `-- map begin` and five `-- zipWith begin`, as chapter 9's did.
      - **The 8×8 entity did not move.** `life8.vhdl` is 211 lines and is chapter
        9's `life.vhdl` with `life` renamed to `life8`: `diff -w` after that one
        substitution is empty, and the same holds for the step file. So the
        chapter's claim that the 8×8 design is untouched is checked rather than
        asserted.
      - **The 16×16 numbers.** `cells : out std_logic_vector(255 downto 0)`
        against `(63 downto 0)`; `subtype Command is std_logic_vector(257 downto
        0)` and `subtype Maybe is std_logic_vector(258 downto 0)`, which are
        chapter 8's 66 and 67 with `n * n` at 256. `life16.vhdl` is 595 lines
        against `life8.vhdl`'s 211, and the 384-line difference is the seed
        written out twice, once as the signal's initial value (lines 22 to 278
        against 22 to 86) and once as the reset value (296 to 552 against 104 to
        168). The two types packages are 227 lines each but differ in
        declaration order as well as in numbers, so no "differ only in numbers"
        claim may be made about them; the chapter quotes two of their lines and
        nothing structural.
      - **The test bench is retargeted, not rewritten.** Two lines change:
        `{-# ANN testBench (TestBench 'life8) #-}` and
        `done = expected (life8 clk rst enableGen commands)`. The eight commands
        and eight boards are untouched, `sampleN 12 testBench` is chapter 10's
        nine `False` and three `True`, and `testBench.vhdl` is 629 lines and
        instantiates `entity life8.life8`. `{-# OPAQUE life8 #-}` carries chapter
        10's pragma across; `life16` gets none, because nothing instantiates it.
      - **NVC is not re-run in the chapter, and is run in CI.** The command
        would be chapter 10's with three file names changed and `--work=life8`,
        which is a how-to repeated rather than a step learned, and
        `sampleN 12 testBench` already says the 8×8 behaviour did not move. The
        chapter says the test bench passes in Haskell and claims nothing about
        the simulator. CI makes the claim anyway, because nothing else would
        notice the retargeted test bench breaking: against `code/`'s
        `Chapters.Ch12` the six-file command exits 0, and
        `nvc --work=life16 -a life16_types.vhdl … life16.vhdl -e life16`
        elaborates the 16×16 entity, which is the strongest available support
        for the chapter's "never tested and works".
      - **The REPL beats.** `:i step` is
        `step :: KnownNat n => Board n -> Board n` with `-- Defined at
        src/Example/Project.hs:111:1` in the same-line form;
        `putStr (render (step glider))` is chapter 5's first generation
        unchanged; and `step glider16` and `step (step glider16)` give chapter
        5's two shapes in the same rows and columns of a 16×16 board, checked
        against chapter 5's shipped transcript. *Ch. 12. Drafted.*

- [x] **V35 — chapter 13's session, and the diff V13 owed.** Captured
      2026-08-09 on a project generated from the edited template, holding
      chapter 12's end state, one real reload and one `:vhdl`. Durable findings:

      - **The edit is four hunks and the file gets one line shorter**, 219 to
        218. The import line, `life`'s signature, `life`'s definition and the
        two wrappers' right-hand sides; nothing else in the module moves.
        `HiddenClockResetEnable System` goes on `life` and on nothing else,
        because `life` is the only binder in the file that had a clock.
      - **`Clash.Prelude` needs no third import and no per-file pragma.**
        `Clash.Explicit.Testbench` stays and does not collide with anything
        `Clash.Prelude` exports — `Clash.Prelude` re-exports no testbench module
        — and `numConvert`, `resetGen`, `systemClockGen`, `enableGen`,
        `fromList`, `foldl1` and the rest of V12's list are all in scope from it
        too. `code/` builds `Chapters.Ch13` `-Wall -Wcompat` clean at the first
        attempt, which is V16 and V24's remaining "chapters 11 to 13 inherit the
        claim, not the check" discharged for 13.
      - **`exposeClockResetEnable` appears twice, not once.** The outline
        predicted one occurrence, from before chapter 12 made two entities.
        There is one per annotated binder, `life8` and `life16`, and the two
        signatures are chapter 12's byte for byte: an annotated binder describes
        real ports, so it is exactly where the three have to be arguments again.
      - **The REPL beats.** `:i mealy` prints in four lines ending
        `-- Defined in ‘Clash.Prelude.Mealy’`, against the ten chapter 7 shows
        for the explicit one. `:i life` is
        `(KnownNat n, HiddenClockResetEnable System) =>` at
        `src/Example/Project.hs:161:1` and `:i life8` is chapter 12's five-line
        signature unchanged at `176:1`, both in the one-argument-per-line form.
        `sampleN 12 testBench` is chapter 10's nine `False` and three `True`.
      - **One `:vhdl`, three binders, fourteen files**, in D22's fixed order
        `life16`, `life8`, `testBench`, with the two `Not specializing` lines in
        the third. Chapter 12's output unchanged in shape.
      - **Seven of the eleven generated files are byte identical to chapter
        12's.** Both step entities (343 lines each), both `.sdc`, and all three
        generated files in `Example.Project.testBench/`: `testBench.vhdl` at 629
        lines, its types package at 213 and the 24-line `slv2string` file. The
        four that differ are `life8.vhdl` (211 lines either way), `life16.vhdl`
        (595), and the two 227-line types packages. `clash-manifest.json`
        differs in all three directories, which is V30's unstable field and a
        genuinely different input at once, so the chapter's `diff` excludes it.
      - **The types packages differ in one identifier.** Eight lines each, all
        of them `St_0`/`St_0_sel0_board`/`St_0_sel1_running` becoming
        `St`/`St_sel0_board`/`St_sel1_running`; after that rename the two files
        are identical. Both are Clash's name for our `St` and no mechanism for
        which suffix it lands on was established, so the chapter does not claim
        one.
      - **The two entities differ in names and in the position of one
        statement.** Lines 1 to 19, the entity declaration, are byte identical in
        both files. In the architecture, `st` becomes `result`, `result` becomes
        `result_0`, `result_0` becomes `result_1`, `st_register` becomes
        `result_register`, the instance label `…_step_result_0` becomes
        `…_step_result_1`, and the four signals named `\c$ds_case_alt…` lose
        `ds_`. Apply those renames and the two files hold the same multiset of
        lines; the only ordering difference is
        `cells_0 <= result.St_sel0_board;`, which sits below the register
        process in chapter 13's file and above it in chapter 12's. One
        `rising_edge(clk)`, one `en` gate, one 65-line reset value and one
        instantiation of the step entity, in both.
      - **The chapter's method is `mv` then `diff`.** `mv vhdl vhdl-12` before
        the edit, because `:vhdl` overwrites the tree, then
        `diff -r -q --exclude=clash-manifest.json vhdl-12 vhdl`, which prints
        exactly the four lines above. `-q` rather than a full diff because the
        two `.vhdl` files are 211 and 595 lines of mostly board literal.
      - **NVC is not re-run in the chapter, and is run in CI**, on the same
        grounds as chapter 12: the command would be chapter 10's with the file
        names changed. Against `code/`'s `Chapters.Ch13` the six-file command
        exits 0 and `nvc --work=life16 -a … -e life16` elaborates. In `code/`
        the module name is inside three of the generated identifiers, so the
        byte-identity claims hold there after `sed 's/Ch13/Ch12/g'`; CI asserts
        them in that form, together with the two entity declarations and the 211
        and 595 line counts. *Ch. 13. Drafted.*

- [x] **V33 — Surfer's browser build, against this file.** Confirmed in a real
      browser on 2026-08-09: `testBench.fst` opens at
      <https://app.surfer-project.org/> and all five checks below hold as
      chapter 11 describes them, so the chapter's `UNVERIFIED` marker is gone
      and nothing in the book is now unrun. Two things about this entry are
      worth keeping. It was drafted from V6's reading of Surfer's source and
      from the documented command set at
      <https://docs.surfer-project.org/book/> rather than from a run, because
      the authoring container has no browser; and the browser build is
      continuously deployed and carries no version, so unlike every other entry
      here this one has a shelf life and is the first thing to re-run if a
      reader reports that chapter 11 does not match their screen. The five
      checks, in the order they were made, because a failure early would have
      made the rest moot:

      1. **It loads.** Dropping the file on the window loads it: the
         ZWRAPPER-wrapped FST that NVC writes is one `wellen` reads, which V5
         had established for a `counter.fst` from the same NVC version and
         which now holds for a file with this one's size and hierarchy.
      2. **The hierarchy reads as the chapter says.** One root scope
         `testbench`, one scope `life_cexampleprojecttestbench_app_arg` under
         it, and selecting that one lists `clk`, `rst`, `en`, `cmd` and
         `cells`. Clicking a variable adds it to the display.
      3. **`item_set_format binary` is the command, and `binary` is an accepted
         format name.** Commands are typed after pressing space, as the guide
         says, and `item_set_format` acts on the focused item, which clicking a
         variable's name is enough to focus. This was the item most likely to
         need rewording, since the guide's "e.g. hex, binary, decimal, signed"
         is an example list rather than the accepted set; it did not.
      4. **A `std_logic_vector` holding `-` shows its `-`.** The chapter's
         central beat is sixty-four don't cares on the payload for seven cycles
         out of eight, and they appear as don't cares rather than as `x` or as
         blank.
      5. **A string-typed `BOOLEAN` is legible.** `st_0_sel1_running` and `en`
         are dumped as strings with the values `true` and `false` (V32), and
         they read as that, which is what the "one bit of the state" section
         needs. *Ch. 11. Drafted.*

- [x] **`-- Defined at` placement, from V7, V21, V22 and V23.** Two forms, and
      both are to be reproduced as observed, never normalised. `:i glider` and
      `:i shiftN` put it on the **same** line after a space and a tab; `plus`,
      `nextCell`, `fromRows`, `render`, `neighbourCounts` and `renderCounts` put
      it on the **next** line, indented by two spaces and a tab. `:i rotateLeftS`
      does the next-line form with `-- Defined in` and the module in quotes. Not
      a terminal-width artefact: byte-identical at `stty cols` 40, 80 and 200.
      Line numbers quoted in a chapter are the ones a reader following it in
      order sees.

      **Which quotes, corrected 2026-08-09.** GHC picks them from the locale, not
      from the terminal: `‘Clash.Explicit.Signal’` under any UTF-8 locale and
      `` `Clash.Explicit.Signal' `` under `LC_ALL=C`. Chapters 4, 6 and 7 shipped
      the second, which is what a capture piped through `grep` in a C locale
      prints and not what a reader sees; all three were corrected to the first
      and `tools/clashi_capture.py` now pins `LC_ALL=C.UTF-8` so a capture cannot
      pick up whichever locale it happened to run under. Found by
      `tools/check_transcripts.py` on its first run, which is the case for having
      it. Only these three lines are affected: `-- Defined at`, which is what
      `:i` gives for the reader's own definitions, quotes nothing.

- [x] **V9 — Reset behaviour in the first samples.** Paste this verbatim in
      chapter 6 — two repeats, then evolution. Against the `register`-based `life`
      with `glider` as the initial value:

      ```
      clashi> mapM_ (putStr . render) (sampleN 5 (life systemClockGen resetGen enableGen))
      .#......
      ..#.....
      ###.....
      ........
      ........
      ........
      ........
      ........
      .#......
      ..#.....
      ###.....
      ........
      ........
      ........
      ........
      ........
      ........
      #.#.....
      .##.....
      .#......
      ........
      ........
      ........
      ........
      ........
      ..#.....
      #.#.....
      .##.....
      ........
      ........
      ........
      ........
      ........
      .#......
      ..##....
      .##.....
      ........
      ........
      ........
      ........
      ```

      The first two boards are byte-identical to `glider` and to each other:
      `resetGen` asserts reset for the first two cycles of `System` and `register`
      holds its initial value meanwhile.

      **Corrected 2026-08-08 by V25.** This entry used to say that the third
      sample, `step glider`, is *not* the shape an unbounded board would give.
      It is. All four generations of the wrapped board are byte-identical to the
      same four generations simulated on a 32×32 board with the glider placed
      away from every edge. The wrap does reach: chapter 4's counts show `1`s in
      column 7 and row 7 that an unbounded board would not have. No cell there
      ever reaches three, so no cell is ever born there, and the boards agree.
      Say nothing about it in either chapter (D11), and do not "fix" the samples:
      they are the correct output of the actual circuit.

      **Re-captured 2026-08-08 by V26**, with
      `mapM_ (\b -> putStr (render b)) …` rather than the `putStr . render` above.
      Both spellings were run in the same session and the forty lines are
      byte-identical; the chapter ships the lambda, because function composition
      is otherwise never introduced and the lambda is the one from chapter 4.
      *Ch. 6. Drafted.*

---

## Infrastructure (closed; nothing here shapes a chapter)

- [x] **V14 — Template mirroring.** `stack new life christiaanb/clash-tutorial`
      resolves, downloads and expands into a working project. Keeping the mirror
      current is CI's job (D15, `publish-template`), which relies on two facts:
      the mirror holds one file on one branch, so a force-push destroys nothing;
      and `git hash-object` on the local file equals the blob `sha` the GitHub
      contents API reports, which decides whether a push is needed without going
      through the CDN. Since 2026-08-07 the `.hsfiles` has no mustache variables
      (author and maintainer are hard-coded), so `stack new` prints two lines and
      stops, and chapter 1's pre-flag about them is gone. **Known state:** the
      mirror is one change behind (V19's `import Prelude`); `publish-template`
      runs on the first push to `main` and needs `STACK_TEMPLATES_DEPLOY_KEY`
      first. No chapter is affected — none runs `stack test`.

- [x] **V15 — Template builds.** Chapter 1 says "roughly ten to fifteen minutes",
      not an exact figure. Three build-breaking template bugs were fixed first:
      missing `extra-deps`, `common-options`'s `NoImplicitPrelude` on the
      `IO`-using executables, and `defaultMain`'s signature. A genuinely cold
      build — `~/.stack/snapshots` moved aside, GHC installed, i.e. a fresh
      devcontainer after `postCreateCommand` — is `real 12m14s` on 12 cores,
      dominated by compiling `clash-lib` and `clash-ghc` from source. Hardware
      dependent, so never quoted as exact.

- [x] **V18 — CI.** `nickg/setup-nvc@v1` with `version: '1.20.1'` needs no
      change: the input validates, resolves to tag `r1.20.1`, and that release
      ships `nvc_1.20.1-1_amd64_ubuntu-24.04.deb`, which `ubuntu-latest` (still
      24.04) matches. **Closed by V31:** the `simulate` job's `exit 1`
      placeholder is gone, and the job now runs chapter 10's command against
      `code/`'s `Chapters.Ch10`. The module name is the only difference, and it
      is in the generated file names rather than in the shape of the command:
      `Chapters_Ch10_life_step.vhdl` and `Chapters_Ch10_testBench_types.vhdl` for
      the reader's `Example_Project_…`. Run by hand from `code/vhdl/`, it exits
      0.

- [x] **V19 — the template's `doctests` suite did not compile.** Fixed
      2026-08-06: the suite imports `common-options`, which turns on
      `NoImplicitPrelude`, and `tests/doctests.hs` used `IO` without importing
      `Prelude`. Two guards added, since the interesting part was why nothing
      caught it: CI's `template` job now runs `stack test` too, and
      `publish-template` ends by generating a project from the mirror and diffing
      it against one from this repository — *projects*, not `.hsfiles`, because
      Stack caches its download as a GitHub API response and the files never match
      byte for byte.

- [x] **V20 — pull request previews.** Checked against scratch repositories and
      end to end on pull request #3: preview up, served, and removed on merge, the
      root unaffected. `MDBOOK_OUTPUT__HTML__SITE_URL` reaches
      `output.html.site-url`, so `book.toml` stays the one place that value is
      written. `.github/gh-pages-publish.sh` was exercised for branch creation,
      per-PR removal, no-op republish, refusal of destinations outside the branch,
      and push-retry give-up. The switch away from `peaceiris/actions-gh-pages` is
      content neutral (identical 52-file tree). Deliberately not pinned:
      `peaceiris/actions-mdbook@v2` installs `latest`; if a future release renders
      `404.html` differently, the preview's 404 page is where it shows.

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
