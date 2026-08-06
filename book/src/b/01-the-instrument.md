# The instrument

By the end of this tutorial we will have described Conway's Game of Life on an eight by eight grid, with a command input that loads a new board, steps it once, runs it or pauses it.
We will generate VHDL from that description, simulate the generated code in NVC (an open source VHDL simulator), and look at the command input on a waveform.
The last chapter rewrites the same circuit in the shorter style you will meet in every real Clash project, and diffs the VHDL to show that only the notation changed.

None of that happens here.
This chapter installs the tool, creates a project from a template, and spends its remaining effort on one habit: asking the compiler what things are.
Clash's interactive prompt answers that question about every name and every expression in your design, and the twelve chapters after this one lean on it constantly.
We practise it now, on code short enough that the answers hold no surprises.

## Stack

Clash is a Haskell library together with a compiler that drives GHC's front end, so it is installed the way Haskell packages are installed.
We use Stack, which fetches the exact compiler a project asks for into a directory of its own rather than using one already on your machine.

Install it by following the instructions on [Stack's install page](https://docs.haskellstack.org/en/stable/install_and_upgrade/), then check that it is on your path:

```
$ stack --version
Version 3.11.1, Git revision 2352d78a8ac5b42d021c8064b8f64ac1c8b8b3d5 x86_64 hpack-0.39.6
```

Your version will differ.
Everything in this book was captured with 3.11.1.

Two things get in Stack's way, most often on Windows and most often on a machine your employer manages: an HTTP proxy, which Stack does not pick up from your system settings, and antivirus software, which may need to be told that Stack is trusted.
Stack's [FAQ](https://docs.haskellstack.org/en/stable/faq/) and [install page](https://docs.haskellstack.org/en/stable/install_and_upgrade/) cover both.
If nothing downloads, that is where to look.

## A project

Our template pins the Clash version, turns on the language extensions the later chapters need, and gives the project two small executables for running Clash.
Ask Stack for it:

```
$ stack new life christiaanb/clash-tutorial
Downloading template christiaanb/clash-tutorial to create project life in directory life/...
```

Stack then prints a note saying that `author-email` and `author-name` were needed by the template and not provided, and suggests how to supply them.
Ignore it.
The template fills in placeholder text, nothing in this tutorial reads those fields, and it is a note rather than an error, even though it arrives on the same channel as one.

Change into the project:

```
$ cd life
```

## The build

This is the longest step in the tutorial.
Stack now downloads GHC 9.10.3 and compiles Clash from source, which on a recent machine takes roughly ten to fifteen minutes and prints several hundred lines while it works.
It is quicker on more cores and slower on a thin network connection.
Start it and leave it alone:

```
$ stack build
```

The last line names the library it registered:

```
Registering library for life-0.1.0.0...
```

Every later build in this tutorial takes seconds.
The wait was for Clash itself, and it happens once.

## The prompt

The template gave us a module at `src/Example/Project.hs` holding two definitions:

```haskell
{{#include ../../../code/src/Chapters/Ch01.hs:definitions}}
```

We work on the first one in this chapter and leave the second alone until chapter 9, where it turns out to be the entity declaration.

The file's one import is `Clash.Explicit.Prelude`.
Explicit is the operative word: through chapter 12 nothing in this design is supplied behind your back, and clocks, resets and enables are arguments you pass by hand.
Chapter 13 switches to the shorter style and shows what the short form was short for.

Now open Clash's interactive prompt, `clashi`, with that module loaded.
It prints a warning about optimization flags before its banner.
The warning is harmless, it has nothing to do with your code, and it will be there every time:

```
$ stack run clashi -- src/Example/Project.hs
when making flags consistent: warning: [GHC-74335] [-Winconsistent-flags]
    Ignoring optimization flags since they are experimental for the byte-code interpreter. Pass -fno-unoptimized-core-for-interpreter to enable this feature.

Clashi, version 1.10.0 (using clash-lib, version 1.10.0):
https://clash-lang.org/  :? for help
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module loaded.
clashi>
```

`Ok, one module loaded` is the line that matters: `plus` is in scope.
The path on that command line is not optional.
Without it, `clashi` comes up with nothing loaded and knows nothing about your project, so we pass it every time.

## Three questions

Ask what `plus` is:

```
clashi> :i plus
plus :: Signed 8 -> Signed 8 -> Signed 8
  	-- Defined at src/Example/Project.hs:6:1
```

Ask what `plus 3` is:

```
clashi> :t plus 3
plus 3 :: Signed 8 -> Signed 8
```

And add two numbers:

```
clashi> plus 3 5
8
```

## Notice that

**`:i` and `:t` are two different questions.**
`:i` takes a name and reports what that name is and where it came from.
`:t` takes an expression and reports its type, and it never reports where the expression is defined, because an expression is not defined anywhere: you just wrote it.
We use `:i` for names and `:t` for expressions throughout, and the line `:i` adds about where a name comes from starts earning its keep in chapter 6, when the name is one of Clash's rather than one of yours.

**`plus 3` is a legal thing to have.**
`plus` takes two arguments and we supplied one, and what came back is not an error: it is something that still wants a `Signed 8` and will give you a `Signed 8`.
Leave that where it is.
It comes back in chapter 4, and by then it is doing real work.

**Nothing here has an entity, an architecture or a port map.**
`plus` is a component, its type is its port list, and `plus 3 5` is not a subroutine call: it is that component instantiated with both of its inputs driven.
This is the first place your VHDL reflexes will mislead you, and it will not be the last.
There is no separate declaration to keep in step with the body, because the type signature is the declaration.

**The width is in the type.**
`Signed 8` is an eight bit signed number, and it is eight bits in the type rather than in a comment or a constant.
A function that takes a `Signed 8` cannot be handed anything else, and the compiler is the one checking.

## Where this goes

Leave `clashi` running.
In chapter 2 we replace `plus` with the rule for a single cell of the board, and we reload rather than restart.
