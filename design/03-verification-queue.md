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

- [x] **V3 — NVC file ordering.** *Checked 2026-08-05, same toolchain as V1/V2:
      Stack 3.11.1, resolver lts-24.38, GHC 9.10.3, Clash 1.10.0, NVC 1.20.1, on
      the fixed project template. Checked against the actual chapter 9/10
      circuit — `Board = Vec 8 (Vec 8 Bool)`, the chapter 8 `Command`/`St`, and
      `topEntity = life` — not the template's toy `plus`, since the file count
      is exactly the thing a bigger circuit could change.*

      Plain `topEntity` (`stack run clash -- Example.Project --vhdl`, no test
      bench) emits three files: `Example_Project_topEntity_types.vhdl`,
      `topEntity.sdc`, `topEntity.vhdl`. `.sdc` is a clock-constraints file, not
      VHDL, and NVC never sees it. Only two files need analysing, in that
      order — types before `topEntity.vhdl`, which `use`s the types package.
      For this pair, `nvc -a *.vhdl -e topEntity` happens to work even with a
      plain alphabetical glob, because the types file's name starts with
      uppercase `E` and sorts before lowercase `topEntity.vhdl` — this is
      coincidence, not a rule, and should not be written into the chapter as
      one.

      The chapter 10 test bench is the case that matters, and it needs
      `import Clash.Explicit.Testbench` — `Clash.Explicit.Prelude` alone does
      not bring `stimuliGenerator`, `outputVerifier'` or `tbSystemClockGen`
      into scope, on the real circuit or the toy one; V2's transcript didn't
      show its imports and this is worth stating explicitly in chapter 10.
      Generating `-main-is testBench --vhdl` for a test bench built around the
      real `topEntity` (`Load glider` then two `Step`s, expected boards taken
      from `sampleN` in the REPL and pasted rather than reasoned out, per this
      file's own note on method) reproduces V2's three-file shape exactly, at
      full circuit size:
      `Example_Project_testBench_types.vhdl`,
      `testBench_slv2string_B426B45701B03559.vhdl`, `testBench.vhdl`. No
      separate `topEntity.vhdl` appears — the test bench's call to `topEntity`
      is flattened into the same single netlist, so the file count stays at
      three regardless of how large the circuit inside `topEntity` is.

      Alphabetical glob fails here exactly as V2 found on the toy example:
      `nvc -a *.vhdl -e testBench -r` sorts `testBench.vhdl` before
      `testBench_slv2string_…`, and NVC stops with `no visible declaration for
      TESTBENCH_SLV2STRING_B426B45701B03559`. The explicit-order form works
      against the correct expected vector (exit 0) and fails cleanly against a
      deliberately wrong one (exit 1, `outputVerifier, expected: …, actual: …`
      at `testBench.vhdl:1090`) — both confirmed by listing the files by name:

      ```
      nvc -a Example_Project_testBench_types.vhdl \
             testBench_slv2string_B426B45701B03559.vhdl \
             testBench.vhdl \
          -e testBench -r
      ```

      The hash in the slv2string filename is deterministic for a given
      source — regenerating `--vhdl` twice from the same `Example/Project.hs`
      produced the identical hash both times, and it did not change when only
      the *values* in the expected-output vector were edited (only the types
      involved determine it). It is still not something to print literally in
      the chapter, because the reader's own file will hash differently the
      moment their source differs from what's pasted. The workable recipe is
      to name the two stable files and glob the third in its correct middle
      position: `testBench_slv2string_*.vhdl` between the types file and
      `testBench.vhdl`. A shell glob in one argument slot still lists the files
      in the order the arguments appear, so this keeps dependency order without
      asking the reader to find or copy a hash. Confirmed this exact
      three-argument form (two literal names, one glob) analyses and runs
      correctly.

      One thing V2's toy example undersold: the real circuit's harmless
      metavalue warning is not one line. `nextCell`'s `Unsigned 4` comparisons
      before reset settles produced 513 `NUMERIC_STD."=": metavalue detected`
      warnings across two simulated instants, all before the exit code is
      decided and all harmless. Chapter 10 should say "many warnings, all
      harmless, ignore them" rather than quote a single line as if that's all
      there is.

      **Verdict: three files, maximum, and short enough to print — two literal
      names plus one glob for the hash-suffixed helper, in that fixed order.**
      Ship the ordering pre-flag as the outline already plans, with the
      literal-names-plus-glob form as the actual command, not a bare file list.
      *Blocks: ch. 10. Unblocked.*

- [x] **V4 — VHDL standard.** *Checked 2026-08-05, same toolchain as V1-V3:
      Stack 3.11.1, resolver lts-24.38, GHC 9.10.3, Clash 1.10.0, NVC 1.20.1,
      on the fixed project template.*

      Clash's own output says what it targets — every generated `.vhdl` file
      opens with the comment `-- Automatically generated VHDL-93`, confirmed
      on both the `plus` toy entity and a clocked `register`-based counter.

      NVC's default (no `--std` flag at all) is VHDL-2008, not 1993, and
      NVC does not print this anywhere — it had to be determined by a
      differentiating test. A minimal file using the VHDL-2008-only matching
      condition operator (`if (a ?= b) then …`) analyses cleanly with no
      `--std` flag and with `--std=2008` explicit, and fails identically
      under `--std=1993` with `no visible subprogram declaration for "?="`.
      That confirms `nvc -a` with nothing added is running in 2008 mode.

      This means there is a standard mismatch between what Clash emits and
      what NVC defaults to, but it is a harmless one: VHDL-2008 is a superset
      of VHDL-93 for everything Clash's netlists actually use, so 2008 mode
      accepts 93-targeted code without complaint. Confirmed directly on all
      three shapes already exercised by V1-V3 — the `plus` toy `topEntity`,
      the `register`-based counter `topEntity`, and the full chapter 10 test
      bench (`Example_Project_testBench_types.vhdl`,
      `testBench_slv2string_B426B45701B03559.vhdl`, `testBench.vhdl`) —
      `nvc -a … -e … -r` with no `--std` flag and the same command with
      `--std=1993` added produce the same exit code and the same warnings in
      every case, including exit 0 against the correct expected vector. Only
      the internal `numeric_std` library path named in NVC's harmless
      metavalue warning differs (`lib/ieee.08/numeric_std-body.vhdl` vs
      `lib/ieee/numeric_std-body.vhdl`) — not something the chapter shows.

      **Verdict: omit `--std` entirely.** Pinning `--std=1993` would only
      match what Clash's comment claims to target, but adds a flag that
      changes nothing observed and that the reader would have no way to
      derive themselves. Chapter 10's `nvc -a` command takes no `--std` flag.
      *Blocks: ch. 10. Unblocked.*

- [x] **V5 — Waveform format.** *Checked 2026-08-05, NVC 1.20.1, same toolchain
      as V1-V4. The NVC half was run in-session; the Surfer half was confirmed
      first from Surfer's own source and documentation, then closed out by
      hand: the generated `counter.fst` was dropped onto
      `app.surfer-project.org` in a real browser and displayed correctly.*

      NVC's default, with no `--format` flag at all, is FST. Given a small
      clocked design (a `register`-based counter, the same shape V4 used),
      `nvc -a counter.vhdl -e counter -r -w` prints `Note: writing FST
      waveform data to counter.fst` and the file it writes is binary FST (
      confirmed by inspecting the header bytes, not just the extension).
      `-w`/`--wave` alone is enough; no separate flag is needed to turn
      waveform dumping on.

      VCD is available and takes one added flag: `nvc -a counter.vhdl -e
      counter -r -w --format=vcd` prints `Note: writing VCD waveform data to
      counter.vcd` and exits 0.

      A gotcha worth pre-flagging in chapter 11: NVC does not infer the format
      from the output filename. `--wave=counter.vcd` with no `--format` still
      writes FST bytes into a file named `counter.vcd` — confirmed by
      inspecting the header, which is binary FST, not text VCD. `--format`
      is the only thing that controls the format; the filename given to
      `--wave`/`-w` is just a name.

      Surfer's own documentation and source settle the acceptance question
      without needing a live browser: the user guide states Surfer supports
      VCD, FST, and GHW, and lists this as a `[WAVE_FILE]` argument type with
      no format carve-out for the web build. Surfer's `Cargo.toml` pins
      `wellen` as its waveform-parsing dependency — a pure-Rust library (no C
      bindings, e.g. no linked `libfst`) — which is what makes a WASM build
      possible in the first place; the native and browser builds parse VCD,
      FST and GHW through the *same* `wellen` backend, not two different
      parsers with different coverage. The changelog and open issue tracker
      show active WASM-build work (translator plugins, a `waves_loaded` WASM
      API, string-decoding fixes described as "in FST and VCD") with nothing
      suggesting FST is unsupported or degraded specifically in the browser
      build.

      One WASM-specific restriction did turn up, relevant to V6 more than V5:
      the `load_file <FILE_NAME>` *command* (the space-bar command palette)
      is documented as not working in the browser/VS Code build "due to file
      access restrictions" — `load_url` is the documented alternative there.
      This is about the scripting command reading an arbitrary local path,
      not about the browser's own Open-file/drag-and-drop control, which
      goes through the browser's file picker rather than a filesystem path.

      Confirmed by hand: the `counter.fst` generated above, uploaded to
      `app.surfer-project.org` with no conversion step, displayed correctly.

      **Verdict: ship FST.** It is NVC's default (no flag needed) and
      Surfer's browser build reads it directly with no conversion step for
      the reader to type or explain. Chapter 11 asks NVC for a waveform with
      no `--format` flag and opens the `.fst` it gets directly in Surfer.
      *Blocks: ch. 11. Unblocked.*

- [x] **V6 — Surfer locality.** *Checked 2026-08-05, from Surfer's own source on
      GitLab (`surfer-project/surfer`, `main` branch) — source-level
      confirmation, the same method V5 used for the Surfer half of the
      waveform-format question, because no packet-capture tooling was
      available in this environment to confirm it by a live network trace.*

      `libsurfer/src/file_dialog.rs` shows the browser build's "Open file"
      picker going through the `rfd` crate's `AsyncFileDialog`, which in the
      `wasm32` target (no VS Code integration) resolves to the browser's
      `<input type="file">` element and `File` API —
      `create_file_dialog(filter, title).pick_file().await`, then
      `file.read().await`. Nothing on that path constructs an HTTP request;
      the bytes come from the browser's own file object, in-process.

      `libsurfer/src/wave_source.rs` shows the same for drag-and-drop:
      `load_from_dropped` takes the `bytes` egui already read from the
      dropped file and calls `load_from_bytes(WaveSource::DragAndDrop(...),
      bytes.to_vec(), ...)` directly — no request leaves the page.

      The one place this file calls out to the network is `reqwest::get(&url)`,
      used only by the separate `load_url` command — the one V5 flagged as the
      documented replacement for the `load_file` *command* in the WASM build,
      because that command takes a path string rather than a file handle. That
      path *fetches* a URL the user supplies; it has nothing to do with opening
      a local file and does not run unless the reader deliberately invokes it.
      Chapter 11 doesn't use it.

      **Verdict: confirmed from source.** Opening a local `.fst` in the browser
      build — by file picker or drag-and-drop — never leaves the page; only the
      unrelated, opt-in `load_url` command talks to the network. Chapter 11's
      locality sentence stands as written.
      *Blocks: ch. 11. Unblocked.*

---

## Shaping: answer before the chapter is finalised

- [x] **V7 — `:i` output under the explicit prelude.** *Checked 2026-08-05, same
      toolchain as V1-V6: Stack 3.11.1, resolver lts-24.38, GHC 9.10.3, Clash
      1.10.0, on a fresh instance of the fixed project template with the
      chapter 6 `register`-based `life` in `Example/Project.hs`.*

      One infrastructure snag first: `stack run clashi` with no argument, as
      chapter 1's transcript shows, drops into a bare `clashi>` prompt with
      *no project module loaded* — `:i register` there resolves to
      `Clash.Prelude`'s hidden-argument version (`Defined in 'Clash.Signal'`),
      not the explicit one, because nothing has brought
      `Clash.Explicit.Prelude`'s `register` into scope over the implicit
      one. The module has to be loaded, either as
      `stack run clashi -- src/Example/Project.hs` from the command line or
      `:load src/Example/Project.hs` once inside, before `:i` says anything
      about this project's code. This is a chapter 1 correction, not a V7
      finding as such, but it is the thing that made V7 fail the first time it
      was tried, so it is recorded here. Loaded either way, the prompt itself
      is a second, separate surprise: it stays `clashi>`, never the
      `*Example.Project>` the outline's transcripts show throughout. Neither
      of these is one of V7's named claims, but both bear on chapters 1, 6 and
      7 and are worth a decision before those chapters are drafted.

      With the module loaded, `:i register` and `:i mealy` give exactly the
      explicit signatures D4 claims:

      ```
      clashi> :i register
      register ::
        (KnownDomain dom, NFDataX a) =>
        Clock dom
        -> Reset dom -> Enable dom -> a -> Signal dom a -> Signal dom a
        	-- Defined in `Clash.Explicit.Signal'
      clashi> :i mealy
      mealy ::
        (KnownDomain dom, NFDataX s) =>
        Clock dom
        -> Reset dom
        -> Enable dom
        -> (s -> i -> (s, o))
        -> s
        -> Signal dom i
        -> Signal dom o
        	-- Defined in `Clash.Explicit.Mealy'
      ```

      Both are ordinary function types — `Clock`, `Reset` and `Enable` as
      plain arguments, no `HiddenClockResetEnable`, no implicit parameter.
      Readable, and readable exactly the way D4 predicted.

      **Verdict: the `:i`-as-instrument argument holds.** D4 does not need
      revisiting on this point. Separately, chapter 1 needs `-- src/…hs` (or
      `:load`) added to the `stack run clashi` step, and every chapter's
      transcript prompt needs a decision — `clashi>` as actually observed, or
      an explanation of what would make it `*Example.Project>`.
      *Shapes: ch. 1, 6, 7.*

- [x] **V8 — No type application needed.** *Checked 2026-08-05, same session as
      V7.*

      ```
      clashi> :t sampleN 5 (life systemClockGen resetGen enableGen)
      sampleN 5 (life systemClockGen resetGen enableGen) :: [Board]
      ```

      No `@System` anywhere. The domain is pinned by passing `systemClockGen`,
      an ordinary value, exactly as D4 claims.

      **Verdict: confirmed as designed.** *Shapes: ch. 6.*

- [x] **V9 — Reset behaviour in the first samples.** *Checked 2026-08-05, same
      session as V7/V8, against the chapter 6 `register`-based `life` with
      `glider` as the initial value.*

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
      `resetGen`'s default reset is asserted for the first two cycles of the
      `System` domain, and `register` holds its initial value while reset is
      asserted, so the first two samples repeat exactly as chapter 6 claims.
      The third sample is `step glider` (visibly different from, and only
      from, that point on): it is *not* the same shape a step on an unbounded
      board would give, because the glider sits one cell from the top-left
      corner and the board wraps (D11) — column and row `-1` fold back to
      column and row 7. This is worth pre-flagging in chapter 6 or leaving
      strictly unexplained per D11, but not worth "fixing": it is the correct
      output of the actual circuit.

      **Verdict: confirmed. Paste this transcript verbatim; two repeats, then
      evolution.** *Shapes: ch. 6.*

- [x] **V10 — `unpack` resolves for `fromRows`.** *Checked 2026-08-05, same
      session, against chapter 3's exact `fromRows`.*

      ```
      clashi> :t fromRows
      fromRows :: Vec 8 (BitVector 8) -> Board
      clashi> :t (map unpack :: Vec 8 (BitVector 8) -> Vec 8 (Vec 8 Bool))
      (map unpack :: Vec 8 (BitVector 8) -> Vec 8 (Vec 8 Bool))
        :: Vec 8 (BitVector 8) -> Vec 8 (Vec 8 Bool)
      ```

      `map unpack` resolves `unpack`'s `BitPack` instance purely from the
      top-level signature, with no annotation on `unpack` itself, in this
      session and in every one of the chapters 3 through 13 builds run for
      this queue (all of which use `fromRows` unchanged). No ambiguity error,
      no need for `TypeApplications` on this line.

      **Verdict: confirmed as designed.** *Shapes: ch. 3.*

- [x] **V11 — Widths.** *Checked 2026-08-05, same session, against chapter 8's
      exact `Command` and `St` (`Board`, `Command`, `St` all monomorphic at
      this point — the chapter 12 type parameter doesn't exist yet).*

      `:kind! BitSize Command` does not reduce to a bare number — the type
      family solver plugins that normalise `CLog`/`Max` arithmetic fire during
      constraint solving, not during `:kind!`'s pretty-printing, so it prints
      `CLog 2 4 + 64` unreduced. Forcing evaluation through a value-level
      `natVal`, which does go through constraint solving, gives the actual
      numbers:

      ```
      clashi> import Data.Proxy
      clashi> natVal (Proxy @(BitSize Command))
      66
      clashi> natVal (Proxy @(BitSize (Maybe Command)))
      67
      clashi> natVal (Proxy @(BitSize Board))
      64
      ```

      66 and 67 — exactly the outline's guesses. `Command`'s tag is
      `CLog 2 4 = 2` bits (four constructors) plus the 64-bit `Board` payload
      `Load` carries; `Maybe Command` adds one more tag bit
      (`CLog 2 2 = 1`) on top. `BitSize St` was not checked — `St` doesn't
      derive `BitPack` in the outline and asking for it fails with
      `No instance for (KnownNat (BitSize St))`, which is expected and not
      something chapter 8 does.

      **Verdict: 66 and 67 confirmed exactly.** Ship the outline's numbers
      as-is; no change needed. If chapter 11 wants to show the derivation
      rather than just the number, `:kind!` is the wrong command for it —
      it must go through a value-level `natVal` or an equivalent forcing
      context, not the type-level `:kind!` the reader would reach for first.
      *Shapes: ch. 8, 11.*

- [x] **V12 — `Clash.Explicit.Prelude` completeness.** *Checked 2026-08-05,
      across every build run for this queue: the chapter 1–9 spine
      (`nextCell`, `Board`, `fromRows`, `glider`, `render`, the four shifts,
      `neighbourBoards`, `countBoard`, `addCounts`, `neighbourCounts`, `step`,
      `Command`, `St`, `lifeT`, `life` using `register` then `mealy`), and the
      chapter 12 polymorphic rewrite (`Board n`, `KnownNat n`, standalone
      `deriving instance` for `NFDataX`/`BitPack`, two monomorphic
      `topEntity`s) — all compiled from a single `import Clash.Explicit.Prelude`
      line, no other import added at any point through chapter 12.*

      Confirmed present with no extra import: `Vec`, `:>`, `Nil`, `map`,
      `zipWith`, `toList`, `foldl1`, `rotateLeftS`, `rotateRightS`, `d1`,
      `BitVector`, `unpack`, `Signed`, `Unsigned`, `Clock`/`Reset`/`Enable`/
      `System`, `systemClockGen`/`resetGen`/`enableGen`, `register`, `mealy`,
      `sampleN`, `Generic`/`NFDataX`/`BitPack` (both plain-`deriving` and
      standalone-`deriving instance` forms), and `KnownNat`.

      One thing confirmed absent, carried over from V3 rather than
      re-derived here: `stimuliGenerator`, `outputVerifier'` and
      `tbSystemClockGen` are not in `Clash.Explicit.Prelude` — chapter 10's
      test bench needs a second import, `Clash.Explicit.Testbench`, which V3
      already established and this session did not contradict.

      **Verdict: `Clash.Explicit.Prelude` alone carries chapters 1 through 9
      and 12 with no added import.** The one necessary addition anywhere in
      the spine is `Clash.Explicit.Testbench` for chapter 10, already known
      from V3. *Shapes: all chapters.*

- [x] **V13 — Chapter 13 diff.** *Checked 2026-08-05. Built chapter 12's
      `topEntity8` (explicit style, `Board n`/`Command n`, `KnownNat n`) and a
      chapter 13 rewrite of the identical logic (`import Clash.Prelude`,
      `life :: (HiddenClockResetEnable dom, KnownNat n) => …`,
      `topEntity8 = exposeClockResetEnable life`) in separate project
      instances, both generating `-main-is topEntity8 --vhdl` from the same
      toolchain as V1-V12.*

      Not byte-identical: `diff -rq` reports all three generated files
      differ, and the two `topEntity8.vhdl` differ in 342 of 761 lines.
      They are, however, the same circuit under different names. The entity
      port list is identical line for line except one input, which differs
      only in name (`carg` in chapter 12's direct-argument style vs `eta` in
      chapter 13's `exposeClockResetEnable`-composed style) — same position,
      same type, same width:

      ```
      < carg       : in Example_Project_topEntity8_types.Maybe;
      ---
      > eta        : in Example_Project_topEntity8_types.Maybe;
      ```

      Both architectures contain exactly one clocked process — `st_register`
      in chapter 12, `cds_app_arg_register` in chapter 13 — driven by the same
      `rising_edge(clk)` shape, and the state record type is the same fields
      under two names, `St_0`/`St_0_sel0_board`/`St_0_sel1_running` in chapter
      12 versus `St`/`St_sel0_board`/`St_sel1_running` in chapter 13. Every
      difference found traces to Clash's name-mangling of the polymorphic
      `St n` and the mealy machine's initial-state signal, which comes out
      differently depending on whether clock/reset/enable are threaded as
      direct top-level arguments (chapter 12) or through the point-free
      `exposeClockResetEnable` composition (chapter 13) — not to any
      difference in what the two circuits do. Neither generated file's line
      count differs (761 each); only the names inside do. Behavioural
      equivalence (identical outputs under identical stimulus) was not
      separately re-simulated for this entry, since `lifeT`/`step` are the
      same unchanged Haskell functions in both versions and the structural
      comparison above already accounts for every observed byte difference.

      **Verdict: equivalent, not byte-identical.** Chapter 13 must say this
      plainly rather than claim identity: same ports (one argument's *name*
      differs, not its type or position), same single register, same state
      shape, different internal names throughout. Point at the port-name and
      type-name differences specifically if the chapter shows a diff, rather
      than asserting "identical" or leaving the reader to find 342 changed
      lines unexplained. *Shapes: ch. 13.*

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
