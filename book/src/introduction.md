# Introduction

[Clash](https://clash-lang.org/) is a functional hardware description language.
You write a circuit as a Haskell program, and Clash compiles it to VHDL or Verilog that a synthesis tool will accept.

This is a tutorial, in the [Diátaxis](https://diataxis.fr/tutorials/) sense: a lesson you are led through by doing.
Over thirteen chapters we build one design, a Conway's Game of Life on an eight by eight grid with a command input, and we finish by generating VHDL for it, simulating it in an open source simulator and reading its waveform.
You will not be asked to decide anything, and no step is meant to fail.

Life is not useful for anything.
It does not need to be: an array of identical combinational cells, a small control machine, a valid-signalled input and a scanned output is the shape of a great many real designs, and it is small enough to print on a screen.
We say that once and do not defend it again.

The tutorial teaches the language, not the reasons behind it.
Where you want to know why something works the way it does, that belongs in an explanation, and we link to one rather than stopping to argue the point.

## Which track to read

There are two lines through the same material:

- **Track B**, for readers with a hardware background (VHDL or SystemVerilog) and no Haskell.
  It assumes you know what a register, a multiplexer and a test bench are, and it spends its effort on the language.
- **Track A**, for readers with neither background.
  It covers the same design in smaller steps.

Track B is written first.
If you have designed hardware before, start there.

## What is pinned

Every command and every transcript in this book was captured from a terminal running exactly this toolchain:

| Tool | Version |
|---|---|
| Stack | 3.11.1 |
| GHC | 9.10.3, via Stack resolver `lts-24.38` |
| Clash | 1.10.0 |
| NVC | 1.20.1 |

Newer versions will very probably work.
Their output will not always match the page, which matters here more than it usually does, because comparing your screen to the page is how you check your own progress.
