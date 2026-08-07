# clash-tutorial

A multi-chapter tutorial for [Clash](https://clash-lang.org/), written to the
[Diátaxis](https://diataxis.fr/tutorials/) definition of a tutorial: a lesson the
reader is led through by doing.

**Status: design complete, no chapters written.** Nothing in `design/` has been
verified against a real toolchain yet. See `design/03-verification-queue.md`.

## What the reader builds

Conway's Game of Life on an 8×8 grid, driven by a command interface, in thirteen
chapters. It begins in the interpreter with a single cell and ends with a design
whose generated VHDL passes a self-checking test bench under NVC, with the
waveform inspected in a browser. An optional fourteenth chapter puts it on an
FPGA.

The reader assumed is a digital design engineer who knows VHDL or SystemVerilog
and does not know Haskell. A second track for readers with neither background is
planned and not yet specified.

## Layout

| Path | Contents |
|---|---|
| `design/` | Decisions, chapter outlines, voice guide, verification queue |
| `book/` | mdBook source |
| `code/` | One Stack project holding every chapter's end state as a module |
| `template/` | The Stack project template used in chapter 1 |

## Working on this

Read `CLAUDE.md` first. The short version: nothing goes into the book that has not
been run, chapters are cumulative so a change in one propagates forward, and code
lives in `code/` and is pulled into the book by mdBook anchors so that CI can
prove the book compiles.

## The template

`template/clash-tutorial.hsfiles` is the source of truth. For chapter 1's command
to work, a copy must exist at
`github.com/christiaanb/stack-templates/clash-tutorial.hsfiles`, because Stack
resolves `username/template-name` only against a repository named
`stack-templates`. This mirror does not exist yet.

## Publishing

Every push to `main` rebuilds the book and force pushes the rendered output to the
`gh-pages` branch, which GitHub Pages serves at
`https://christiaanb.github.io/clash-tutorial/`. Nothing is authored on that
branch. Pages has to be pointed at it once, by hand, under Settings -> Pages.

## Building

    mdbook build book
    cd code && stack build && stack test
