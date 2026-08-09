# Verification queue

Findings from checking every claim against a real toolchain. **All twenty-nine
items are closed.** What is recorded here is *what was observed* and what each
chapter must therefore do. Do not re-derive these; do not contradict one without
re-running the check and rewriting the entry.

Toolchain unless stated: Stack 3.11.1, resolver lts-24.38, GHC 9.10.3, Clash
1.10.0, NVC 1.20.1, devcontainer, on a project freshly generated from
`template/clash-tutorial.hsfiles`. Checked 2026-08-05 to 2026-08-09.

Chapters 1 to 8 are drafted against these entries and their transcripts now live
in the book; only the durable facts are kept below. Mark any future item `[x]`
with the date and the observed result, not just a tick.

---

## Toolchain and commands

- [x] **V2 — Test bench route.** `-main-is testBench` is chapter 10's one route.
      No `TestBench` annotation, no `ANNOTATE` pragma, no Template Haskell: plain
      `Vec` literals work with `stimuliGenerator`/`outputVerifier'`, so
      `$(listToVecTH …)` is not needed. NVC exits 0 on a correct expected vector
      and 1 on a wrong one, printing
      `** Error: 130ns+1: outputVerifier, expected: 00000111, actual: 00000110`.
      *Ch. 10.*

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

      Plain `topEntity` (no test bench) emits types, `.vhdl` and a `.sdc`; `.sdc`
      is clock constraints, NVC never sees it. Two further facts for ch. 10:
      `Clash.Explicit.Prelude` does **not** export `stimuliGenerator`,
      `outputVerifier'` or `tbSystemClockGen` — `import Clash.Explicit.Testbench`
      is required; and the harmless metavalue warning is not one line but 513
      (`NUMERIC_STD."=": metavalue detected`, from `Unsigned 4` comparisons before
      reset settles) — say "many warnings, all harmless" rather than quoting one.
      *Ch. 10.*

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
      type 'Vec n2 a0' with actual type '[a]'`. *All chapters.*

- [x] **V16 — `default-extensions` sufficiency.** No per-file pragma is required
      in chapters 1 to 13. After D19, `GHC2024` supplies `BinaryLiterals`,
      `NumericUnderscores`, `DeriveGeneric` and `FlexibleContexts`;
      `common-options` still lists `DeriveAnyClass` and `TemplateHaskell`
      (`TemplateHaskellQuotes` dropped as implied). Chapters 1 to 4 verified
      (V24); 5 to 8 verified since, and chapter 8 is the first to need
      `DeriveAnyClass`, which is what lets `NFDataX` and `BitPack` sit in a plain
      `deriving` clause alongside `Generic` (V28). Chapters 9 to 13 inherit the
      claim, not the check. *All chapters.*

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

      **The risk D19 accepts, partly discharged:** `MonoLocalBinds` has rejected
      nothing in chapters 5 to 8, which are built `-Wall -Wcompat` clean in
      `code/`. Chapters 9 to 13 are still unchecked. *All chapters.*

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
      is how 1.10.0 picks a binder not named `topEntity`. *Ch. 12.*

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
      "identical". *Ch. 13.*

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

      **One check owed by chapter 9.** Chapter 4's last "notice that" promises the
      reader will see these `map`s as `for … generate` in chapter 9. What was
      checked is chapter 4's code elaborated alone, not chapter 9's `topEntity`.
      Confirm against chapter 9's real output and change the sentence if it does
      not hold.

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

- [x] **`-- Defined at` placement, from V7, V21, V22 and V23.** Two forms, and
      both are to be reproduced as observed, never normalised. `:i glider` and
      `:i shiftN` put it on the **same** line after a space and a tab; `plus`,
      `nextCell`, `fromRows`, `render`, `neighbourCounts` and `renderCounts` put
      it on the **next** line, indented by two spaces and a tab. `:i rotateLeftS`
      does the next-line form with `-- Defined in` and the module in GHC's
      asymmetric quotes. Not a terminal-width artefact: byte-identical at `stty
      cols` 40, 80 and 200. Line numbers quoted in a chapter are the ones a reader
      following it in order sees.

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
      24.04) matches. **Still open, as part of the chapter 10 work:** the
      `V3`-tagged `exit 1` placeholder in the `simulate` job must be replaced by
      V3's ordered `nvc -a` command.

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
