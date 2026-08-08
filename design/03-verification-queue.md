# Verification queue

The list of claims that had to be checked against a real toolchain before the
corresponding chapter could be drafted. **All twenty items are closed.** What
remains here is the *findings* — what was observed, and what each chapter must
therefore do. Do not re-derive these; do not contradict them without re-running
the check and rewriting the entry.

Toolchain for every entry unless stated otherwise: Stack 3.11.1, resolver
lts-24.38, GHC 9.10.3, Clash 1.10.0, NVC 1.20.1, on the fixed project template.
Checked 2026-08-05 unless a date is given.

Mark any future item `[x]` with the date and the observed result, not just a
tick. A verified item that records *what was seen* is worth ten times one that
records that someone looked.

---

## Blocking (were required before drafting)

- [x] **V1 — Chapter 12 is buildable.** *Ship chapter 12 as designed.*
      `type Board n = Vec n (Vec n Bool)` compiles with `KnownNat n` added to
      `step`, `neighbourCounts`, `countBoard`, `addCounts` and the four shifts —
      no other structural change, as D9 predicted. `neighbourBoards` stays
      `Vec 8` (eight directions), returning `Vec 8 (Board n)`.

      One snag, which *is* the chapter's pre-flagged pitfall: plain
      `deriving (Generic, NFDataX, BitPack, Eq, Show)` on
      `data Command n = Load (Board n) | Step | Run | Pause` fails with
      `[GHC-95822] solveWanteds: too many iterations (limit = 4)` — generics
      can't resolve `KnownNat (BitSize (Command n))` when `BitSize` depends on
      `n`. Fix is standalone deriving with an explicit context:

      ```haskell
      data Command n = Load (Board n) | Step | Run | Pause
        deriving (Generic, Eq, Show)

      deriving instance KnownNat n => NFDataX (Command n)
      deriving instance KnownNat n => BitPack (Command n)
      ```

      `StandaloneDeriving` is already in the template, so no new pragma.
      Omitting `KnownNat n` from a plain function gives a readable
      `[GHC-39999] No instance for 'KnownNat n'` with a "add (KnownNat n) to the
      context" fix, not a generics wall.

      Two `topEntity`s from one `life` work: `clash Example.Project -main-is
      topEntity8 --vhdl` and `-main-is topEntity16` each elaborate in under two
      seconds and give different port widths (64 vs 256 `out boolean` ports).
      Note `-main-is` — not a bare module argument — is how Clash 1.10.0 picks a
      binder not literally named `topEntity`. *Blocks: ch. 12. Unblocked.*

- [x] **V2 — Test bench generation route.** *`-main-is testBench` is chapter
      10's one route; the `TestBench` annotation is unneeded.* No `ANNOTATE`
      pragma and no Template Haskell: plain `Vec` literals (`1 :> 2 :> 3 :> Nil`)
      work directly with `stimuliGenerator`/`outputVerifier'`, so
      `$(listToVecTH …)` isn't needed either.

      `stack run clash -- Example.Project -main-is testBench --vhdl` produces
      `vhdl/Example.Project.testBench/{testBench.vhdl,
      Example_Project_testBench_types.vhdl, testBench_slv2string_<hash>.vhdl}`.
      NVC exits 0 against a correct expected vector and 1 against a deliberately
      wrong one, printing
      `** Error: 130ns+1: outputVerifier, expected: 00000111, actual: 00000110`.
      *Blocks: ch. 10. Unblocked.*

- [x] **V3 — NVC file ordering.** Checked against the real chapter 9/10 circuit,
      not the template's toy `plus`. *Three files, maximum.*

      Plain `topEntity` (no test bench) emits `Example_Project_topEntity_types.vhdl`,
      `topEntity.sdc`, `topEntity.vhdl`. `.sdc` is clock constraints, not VHDL;
      NVC never sees it. Only two files need analysing, types first. A plain
      glob happens to order that pair correctly (uppercase `E` sorts before
      lowercase `t`) — coincidence, not a rule, and not to be written as one.

      The test bench is the case that matters, and the file count stays at three
      however large the circuit is (`topEntity` is flattened into the same
      netlist; no separate `topEntity.vhdl` appears). An alphabetical glob
      **fails**: `testBench.vhdl` sorts before the `slv2string` file it depends
      on and NVC stops with `no visible declaration for TESTBENCH_SLV2STRING_…`.
      The chapter's command names the two stable files and globs the
      hash-suffixed one in its correct middle position — a glob in one argument
      slot preserves argument order, so this keeps dependency order without
      asking the reader to copy a hash:

      ```
      nvc -a Example_Project_testBench_types.vhdl \
             testBench_slv2string_*.vhdl \
             testBench.vhdl \
          -e testBench -r
      ```

      (The hash is deterministic for a given source — it depends only on the
      types involved, not the expected-output values — but the reader's file will
      hash differently, so never print it literally.)

      Two further facts for chapter 10: `Clash.Explicit.Prelude` alone does
      **not** bring `stimuliGenerator`, `outputVerifier'` or `tbSystemClockGen`
      into scope — `import Clash.Explicit.Testbench` is required. And the
      harmless metavalue warning is not one line: the real circuit's `Unsigned 4`
      comparisons before reset settles produce 513 `NUMERIC_STD."=": metavalue
      detected` warnings. Say "many warnings, all harmless, ignore them" rather
      than quoting one line. *Blocks: ch. 10. Unblocked.*

- [x] **V4 — VHDL standard.** *Omit `--std` entirely.* Clash emits
      `-- Automatically generated VHDL-93`; NVC's default with no flag is
      VHDL-2008 (determined by a differentiating test — the 2008-only `?=`
      operator analyses with no flag and with `--std=2008`, fails under
      `--std=1993`). The mismatch is harmless: 2008 is a superset of 93 for
      everything Clash's netlists use. Confirmed on all three shapes exercised
      by V1–V3 — with and without `--std=1993`, same exit codes and same
      warnings. Pinning the flag would change nothing observed and the reader
      could not derive it themselves. *Blocks: ch. 10. Unblocked.*

- [x] **V5 — Waveform format.** *Ship FST.* NVC's default with no `--format`
      flag is FST: `nvc -a counter.vhdl -e counter -r -w` prints `Note: writing
      FST waveform data to counter.fst` and writes real FST bytes (header
      inspected). `-w`/`--wave` alone turns dumping on. VCD needs one added flag
      (`--format=vcd`).

      Gotcha to pre-flag in chapter 11: **NVC does not infer the format from the
      filename.** `--wave=counter.vcd` with no `--format` writes FST bytes into a
      file named `.vcd`. `--format` is the only control; the `--wave` name is
      just a name.

      Surfer reads VCD, FST and GHW through the same pure-Rust `wellen` backend
      in both native and WASM builds — no browser carve-out. Closed out by hand:
      the generated `counter.fst` was dropped onto `app.surfer-project.org` in a
      real browser and displayed correctly, with no conversion step. (One
      WASM-specific restriction, relevant to V6: the `load_file <PATH>` *command*
      does not work in the browser build; `load_url` is its documented
      replacement. That is about the scripting command reading a filesystem path,
      not the Open-file/drag-and-drop control. Chapter 11 uses neither.)
      *Blocks: ch. 11. Unblocked.*

- [x] **V6 — Surfer locality.** *Chapter 11's locality sentence stands.*
      Confirmed from Surfer's source (`surfer-project/surfer`, `main`) rather
      than a live network trace, as no packet-capture tooling was available.
      `libsurfer/src/file_dialog.rs`: the browser build's Open-file picker goes
      through `rfd`'s `AsyncFileDialog`, which on `wasm32` is
      `<input type="file">` plus the `File` API — `pick_file().await` then
      `file.read().await`, nothing constructing an HTTP request.
      `libsurfer/src/wave_source.rs`: drag-and-drop calls `load_from_bytes` on
      bytes egui already read. The only network call in that file is
      `reqwest::get(&url)`, used solely by the opt-in `load_url` command.
      *Blocks: ch. 11. Unblocked.*

---

## Shaping (answered before the chapter is finalised)

- [x] **V7 — `:i` output under the explicit prelude.** *The
      `:i`-as-instrument argument holds; D4 needs no revisiting.* With the module
      loaded, `:i register` and `:i mealy` print ordinary function types with
      `Clock`, `Reset` and `Enable` as plain arguments — no
      `HiddenClockResetEnable`, no implicit parameter — reported as `Defined in
      'Clash.Explicit.Signal'` / `'Clash.Explicit.Mealy'`.

      Two infrastructure findings, now settled as decisions: `clashi` with no
      argument loads *no project module*, so `:i plus` there is
      `[GHC-76037] Not in scope` and `:i register` resolves to `Clash.Prelude`'s
      hidden-argument version — chapter 1 passes the module on the command line
      (D13). And the prompt stays `clashi>`, never `*Example.Project>` (D12).

      **Chapter 1's verified transcript** (2026-08-06, captured through a pty
      against a project freshly generated from the template; 2026-08-07 re-run
      after the `bin/Clashi.hs` fix below):

      ```
      $ stack run clashi -- src/Example/Project.hs
      Clashi, version 1.10.0 (using clash-lib, version 1.10.0):
      https://clash-lang.org/  :? for help
      [1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
      Ok, one module loaded.
      clashi> :i plus
      plus :: Signed 8 -> Signed 8 -> Signed 8
        	-- Defined at src/Example/Project.hs:6:1
      clashi> :t plus 3
      plus 3 :: Signed 8 -> Signed 8
      clashi> plus 3 5
      8
      ```

      Note the `-- Defined at` line the outline omitted — `:i` reports the source
      location, indented by two spaces followed by a **tab**. Chapter 1
      reproduces it byte for byte.

      The `[GHC-74335] -Winconsistent-flags` warning that used to print before
      the banner is **gone** as of 2026-08-07: `bin/Clashi.hs` in the template
      and in `code/` now prepends `-fno-unoptimized-core-for-interpreter`
      alongside `--interactive`, which is exactly what the warning asked for.
      Chapter 1's pre-flagging sentences were deleted.

      `stack build`'s last line is `Registering library for life-0.1.0.0...`,
      confirmed incremental and after deleting `.stack-work`. Chapter 1 quotes it
      as the marker that the long build finished: short, path-free, stable.
      *Shapes: ch. 1, 6, 7. Chapter 1 drafted against this.*

- [x] **V8 — No type application needed.** *Confirmed as designed.*
      `:t sampleN 5 (life systemClockGen resetGen enableGen)` gives `[Board]`
      with no `@System` anywhere — the domain is pinned by passing
      `systemClockGen`, an ordinary value, exactly as D4 claims. *Shapes: ch. 6.*

- [x] **V9 — Reset behaviour in the first samples.** *Confirmed; paste this
      transcript verbatim — two repeats, then evolution.* Against the chapter 6
      `register`-based `life` with `glider` as the initial value:

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
      `resetGen` asserts reset for the first two cycles of `System`, and
      `register` holds its initial value while reset is asserted. The third
      sample is `step glider` — and it is *not* the shape an unbounded board
      would give, because the glider sits one cell from the corner and the board
      wraps (D11), so column and row `-1` fold back to 7. Pre-flag it in chapter
      6 or leave it strictly unexplained per D11, but do not "fix" it: it is the
      correct output of the actual circuit. *Shapes: ch. 6.*

- [x] **V10 — `unpack` resolves for `fromRows`.** *Confirmed as designed.*
      `map unpack` resolves `unpack`'s `BitPack` instance purely from
      `fromRows`'s top-level signature — no annotation on `unpack`, no
      `TypeApplications`, no ambiguity error. Held in this session and in every
      chapters 3–13 build run for this queue. *Shapes: ch. 3.*

- [x] **V11 — Widths.** *66 and 67 confirmed exactly; ship the outline's
      numbers.* Against chapter 8's exact `Command` and `St`, all still
      monomorphic:

      ```
      clashi> import Data.Proxy
      clashi> natVal (Proxy @(BitSize Command))
      66
      clashi> natVal (Proxy @(BitSize (Maybe Command)))
      67
      clashi> natVal (Proxy @(BitSize Board))
      64
      ```

      `Command` is `CLog 2 4 = 2` tag bits plus `Load`'s 64-bit `Board` payload;
      `Maybe Command` adds one more tag bit. **`:kind!` is the wrong command
      here** — the solver plugins that normalise `CLog`/`Max` fire during
      constraint solving, not during `:kind!` pretty-printing, so
      `:kind! BitSize Command` prints `CLog 2 4 + 64` unreduced. If chapter 11
      shows the derivation it must go through `natVal` or another forcing
      context. `BitSize St` was not checked: `St` doesn't derive `BitPack` and
      asking fails with `No instance for (KnownNat (BitSize St))`, which is
      expected and not something chapter 8 does. *Shapes: ch. 8, 11.*

- [x] **V12 — `Clash.Explicit.Prelude` completeness.** *It alone carries
      chapters 1 through 9 and 12 with no added import.* Confirmed across every
      build run for this queue — the chapter 1–9 spine and the chapter 12
      polymorphic rewrite — from a single `import Clash.Explicit.Prelude` line.

      Present with no extra import: `Vec`, `:>`, `Nil`, `map`, `zipWith`,
      `toList`, `foldl1`, `rotateLeftS`, `rotateRightS`, `d1`, `BitVector`,
      `unpack`, `Signed`, `Unsigned`, `Clock`/`Reset`/`Enable`/`System`,
      `systemClockGen`/`resetGen`/`enableGen`, `register`, `mealy`, `sampleN`,
      `Generic`/`NFDataX`/`BitPack` (plain and standalone deriving forms),
      `KnownNat`. The one necessary addition anywhere in the spine is
      `Clash.Explicit.Testbench` for chapter 10 (see V3). *Shapes: all chapters.*

- [x] **V13 — Chapter 13 diff.** *Equivalent, not byte-identical — chapter 13
      must say so plainly.* Chapter 12's `topEntity8` and a chapter 13 rewrite of
      identical logic (`import Clash.Prelude`, `HiddenClockResetEnable`,
      `topEntity8 = exposeClockResetEnable life`) were built in separate project
      instances. All three generated files differ, and the two `topEntity8.vhdl`
      differ in 342 of 761 lines — but they are the same circuit under different
      names:

      - The entity port list is identical line for line except one input, which
        differs only in *name*: `carg` (direct-argument style) vs `eta`
        (`exposeClockResetEnable`-composed style). Same position, type, width.
      - One clocked process each, same `rising_edge(clk)` shape:
        `st_register` vs `cds_app_arg_register`.
      - Same state record fields under two names: `St_0`/`St_0_sel0_board`/
        `St_0_sel1_running` vs `St`/`St_sel0_board`/`St_sel1_running`.
      - Same line count (761 each).

      Every difference traces to Clash's name-mangling of the polymorphic `St n`
      and the mealy machine's initial-state signal. Behavioural equivalence was
      not separately re-simulated: `lifeT`/`step` are the same unchanged Haskell
      in both, and the structural comparison accounts for every observed byte
      difference. If the chapter shows a diff, point at the port-name and
      type-name differences specifically rather than asserting "identical" or
      leaving 342 changed lines unexplained. *Shapes: ch. 13.*

- [x] **V21 — chapter 2's session.** *Captured 2026-08-08, in the devcontainer:
      Stack 3.11.1, resolver lts-24.38, GHC 9.10.3, Clash 1.10.0, against a
      project freshly generated from `template/clash-tutorial.hsfiles` and built
      with `stack build`. The session ran through a pty (`script`), with the file
      on disk replaced while `clashi` was still holding the old module, so the
      `:r` below is a real reload of a real edit rather than a restart dressed up
      as one.*

      The transcript now in chapter 2 is that session, in order and unedited. Two
      details worth recording separately from it:

      - `:r` answers `Ok, one module reloaded.`, not `Ok, one module loaded.`,
        which is what the same prompt says on startup. The chapter quotes the
        reload wording.
      - `:i nextCell`'s `-- Defined at src/Example/Project.hs:6:1` has the same
        two-spaces-then-tab indentation V7 recorded for `plus`, and it names line
        6 for the same reason: with `plus` and `topEntity` deleted (D17) and
        `nextCell` written in their place, the defining equation lands on line 6
        exactly as `plus`'s did.

      One claim in the chapter's prose that is not in the transcript was checked
      separately in the same project: `nextCell True 12` evaluates to `False`.
      The chapter uses it to say that the type checks the width and not the
      range, and it is stated rather than shown, because showing it would mean
      putting a count on screen that the finished design cannot produce.

      *Shapes: ch. 2. Chapter 2 drafted against this.*

---

## Infrastructure

- [x] **V14 — Template mirroring.** *Ship as designed.*
      `github.com/christiaanb/stack-templates/clash-tutorial.hsfiles` exists and
      matched `template/clash-tutorial.hsfiles` byte for byte;
      `stack new life christiaanb/clash-tutorial` resolves the shorthand,
      downloads from that URL and expands into a working project.

      **Keeping it current is now CI's job** (D15, `publish-template`). Two facts
      that job relies on: the mirror holds exactly one file on one branch
      (`main`), so force-pushing a single-commit repository over it destroys
      nothing; and `git hash-object template/clash-tutorial.hsfiles` equals the
      blob `sha` the GitHub contents API reports for the mirrored file
      (`dab5f2ef0acd8932c8daadcfd13e671801661532` on both sides), which is what
      lets the job decide whether a push is needed without going through the CDN.

      **2026-08-07 — the author-name/email note is gone, and chapter 1's pre-flag
      with it.** The `.hsfiles` no longer uses `{{author-name}}`/`{{author-email}}`;
      the cabal file hard-codes `author: Tutorial student` and `maintainer:
      student@clash-tutorial.me`. With no unsupplied mustache variables, `stack
      new` prints two lines and stops:

      ```
      $ stack new life /path/to/template/clash-tutorial.hsfiles
      Loading local template /path/to/template/clash-tutorial to create project life in
      directory life/...
      ```

      Nothing in the tutorial reads the author fields.

      **Known state:** the mirror is deliberately one change behind — V19's
      `import Prelude` is in `template/clash-tutorial.hsfiles` and
      `publish-template` has not run yet. It runs on the first push to `main` and
      needs `STACK_TEMPLATES_DEPLOY_KEY` to exist first. Chapter 1 is unaffected:
      the change touches `tests/doctests.hs` and no chapter runs `stack test`.
      *Blocks: ch. 1. Unblocked.*

- [x] **V15 — Template builds.** *Closed. Chapter 1 says "roughly ten to fifteen
      minutes", not an exact figure.* Three build-breaking template bugs were
      fixed first: missing `extra-deps`, `common-options`'s `NoImplicitPrelude`
      on the `IO`-using executables, and `defaultMain`'s `[String] -> IO ()`
      signature. `stack new` → `stack build` → `stack run clash -- …
      -main-is topEntity8 --vhdl` then succeeds.

      Timing needed care: Stack keys its snapshot cache by resolver +
      `extra-deps`, not project path, so a plain `stack build` from a fresh
      `life/` took a meaningless 14.5s off work already done for V1. Moving
      `~/.stack/snapshots` aside — leaving GHC installed, exactly a fresh
      devcontainer's state after `postCreateCommand` — gave `real 12m14s` on 12
      cores. That is a real measurement of the actual bottleneck (compiling
      `clash-lib`'s ~120 modules and `clash-ghc`'s GHC-API-heavy backend from
      source), but it varies with hardware, so do not quote it as exact. The
      cache was restored afterward. *Blocks: ch. 1. Unblocked.*

- [x] **V16 — `default-extensions` sufficiency.** *No per-file pragma is required
      anywhere in chapters 1 through 13.* All five are present in the template's
      `common-options`: `BinaryLiterals`, `NumericUnderscores`, `DeriveGeneric`,
      `DeriveAnyClass`, `TemplateHaskell` (alongside `TemplateHaskellQuotes`).
      V2 removed the need for Template Haskell in chapter 10, but the extension
      is on regardless. *Shapes: all chapters.*

- [x] **V17 — NVC on Debian and Ubuntu.** *Split by distro; both routes real.*
      Ubuntu 22.04/24.04 amd64 readers install upstream's prebuilt `.deb` from
      `github.com/nickg/nvc` releases — the exact route this repository's
      `.devcontainer/Dockerfile` uses and that every NVC command in V2–V6
      exercised. Ubuntu's own archives do **not** package NVC:
      `apt-cache policy nvc` after a real `apt-get update` shows only the
      manually-installed `1.20.1-1` from `/var/lib/dpkg/status`, and
      `apt-cache madison nvc` returns nothing. Debian has no `nvc` package in any
      suite either, and the r1.20.1 release ships no Debian `.deb` — so Debian
      readers build from source per upstream's README (`./autogen.sh` from Git,
      then `../configure && make && sudo make install`, needing
      `build-essential automake autoconf flex check llvm-dev pkg-config
      zlib1g-dev libdw-dev libffi-dev libzstd-dev` and LLVM 8–21).

      Chapter 10's sentence must name both routes rather than imply
      `apt install nvc` works — it works on neither distro. *Shapes: ch. 10.*

- [x] **V18 — CI.** *The existing `nickg/setup-nvc@v1` step with
      `version: '1.20.1'` needs no change.* Checked from the action's source and
      the GitHub API. `v1` is the repository's only tag, with a matching release.
      `action.yml` declares one relevant input, `version` (optional, default
      `latest`). `dist/index.js` validates it against `/^r?(\d+\.\d+\.\d+)$/` and
      resolves it to `nickg/nvc`'s tag `r${version}` — `r1.20.1` exists and ships
      `nvc_1.20.1-1_amd64_ubuntu-24.04.deb`. `ubuntu-latest` still resolves to
      24.04 (26.04 reached public preview in June 2026 but is not the default),
      so the `simulate` job's runner matches a shipped asset.

      The `V18` comment in `.github/workflows/ci.yml` was removed. The
      `V3`-tagged placeholder in the `simulate` job's "Analyse, elaborate and
      run" step is a separate open gap — V3's explicit ordered `nvc -a` command
      must replace the `exit 1` placeholder as part of the chapter 10 work.
      *Blocks: CI. Unblocked.*

- [x] **V19 — the template's `doctests` suite did not compile.** *Found and fixed
      2026-08-06.* `stack test` failed in `code/` and in the reader's project:
      the suite does `import: common-options`, that stanza turns on
      `NoImplicitPrelude`, and `tests/doctests.hs` uses `IO` without importing
      `Prelude` (`[GHC-76037] Not in scope: type constructor or class 'IO'`).
      Same bug V15 fixed on the two executables, in the one place it was missed —
      unnoticed because `stack build` does not build test suites and no chapter
      runs `stack test`. Fixed by adding `import Prelude` in
      `code/tests/doctests.hs` and `template/clash-tutorial.hsfiles`.

      Two guards added, since the interesting part was why nothing caught it:

      - CI's `template` job now runs `stack test` as well as `stack build`.
      - The `publish-template` job ends by running chapter 1's actual first
        command against the mirror and diffing the resulting *project* against
        one generated from this repository's copy. Comparing projects rather than
        `.hsfiles` is deliberate: Stack caches its download as a GitHub API
        response, so the files never match byte for byte even when identical.

      *Blocks: nothing. Closed.*

- [x] **V20 — pull request previews.** *Checked 2026-08-08, against scratch
      repositories seeded from the real `gh-pages`, and end to end on pull
      request #3. Closed — not to be re-derived.*

      - `MDBOOK_OUTPUT__HTML__SITE_URL=/clash-tutorial/pr/1/ mdbook build book`
        (mdBook 0.5.4) writes `<base href="/clash-tutorial/pr/1/">` into
        `book/book/404.html`; a plain build restores `/clash-tutorial/`. The env
        override reaches `output.html.site-url` as `preview-book` assumes, so
        `book.toml` stays the one place that value is written.
      - `.github/gh-pages-publish.sh`: starts the branch when there is none;
        publishing the root deletes a dropped page while leaving `pr/7` and
        `pr/9` untouched; removing `pr/7` leaves the rest alone; republishing
        unchanged output is a clean no-op, not an empty commit; destinations
        outside the branch (`/etc`, `../escape`) and missing source directories
        are refused; the retry loop recovers from one rejected push and gives up
        non-zero after three.
      - Over `file://` — the only way to exercise the shallow path, since
        `git clone --depth` is silently ignored for local clones — the clone is
        genuinely shallow and the push lands as an ordinary commit on top,
        leaving earlier history intact.
      - **The switch away from `peaceiris/actions-gh-pages` is content neutral.**
        Publishing over `gh-pages` at `7b96469` (52 files) with `mdbook build
        book` from that same commit reports "gh-pages already holds this. Nothing
        to push." — an identical tree, file for file, which also means local
        mdBook 0.5.4 and whatever `latest` resolved to produce the same hashed
        asset names.
      - `actionlint` 1.7.7 and `shellcheck` 0.10.0 clean on both workflows and
        the script.
      - On pull request #3: the preview went up, served, and came down on merge
        (`5a9497e` publish, `0a1d4a9` remove); `/clash-tutorial/pr/3/` now 404s
        and no `pr/` entry remains. The root was unaffected, still 52 files. The
        merge produced **no publish commit** — that pull request changed CI and
        `design/` but not the book, so the script took its no-op path, as the
        scratch runs predicted.

      Deliberately not pinned: `peaceiris/actions-mdbook@v2` installs `latest`,
      so CI's mdBook is whatever that resolves to on the day. If a future release
      renders `404.html` differently, the preview's 404 page is where it shows,
      and nothing else breaks. *Blocks: nothing. Closed.*

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
