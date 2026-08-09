# The waveform

Chapter 10's simulation printed nothing and exited 0.
That is one bit of information, and it is the right bit to want, but it is one bit: the design agreed with itself, and nothing on screen says how.

This chapter asks the same run to write down what its signals did, and then looks at it.
The REPL has been a good instrument for the boards and a poor one for everything around them: `sampleN` prints sixty-four cells per cycle, which is the right shape for data and the wrong shape for a clock, a reset, and a command that arrives one cycle before it takes effect.
Those are what a waveform is for, and the two instruments divide this design between them.

## One more flag

Leave `clashi` running and go back to the second terminal, in `vhdl/`, where chapter 10 left off.
The command is chapter 10's with `-w` on the end:

```
$ nvc --ieee-warnings=off --work=life \
      -a Example.Project.life/life_types.vhdl \
         Example.Project.life/Example_Project_life_step.vhdl \
         Example.Project.life/life.vhdl \
         Example.Project.testBench/Example_Project_testBench_types.vhdl \
         Example.Project.testBench/testBench_slv2string_*.vhdl \
         Example.Project.testBench/testBench.vhdl \
      -e testBench -r -w
** Note: writing FST waveform data to testBench.fst
** Note: arrays of composite types such as ARRAY_OF_ARRAY_OF_8_BOOLEAN are not dumped by default, pass --dump-arrays to include these in the waveform dump
```

The first note is the result.
`testBench.fst` is beside the two generated directories, about four kilobytes of it, and it covers the whole run: 190 nanoseconds, from time zero to a little after the test bench stopped its own clock.
FST is the compressed binary waveform format GTKWave introduced, and NVC writes it without being asked, which is why turning the dump on is a flag with nothing after it.

The second note is worth a sentence, because it is telling us something true about the design rather than something to scroll past.
`ARRAY_OF_ARRAY_OF_8_BOOLEAN` is our `Board`, and a dump does not hold an array of arrays unless it is asked to, so every signal in the design that is a board is left out of it: the two ports of the `step` entity, the field the state record holds, and the ones in between.
That is not the loss it sounds like, and the reason is a decision from chapter 9: the output port is called `cells`, Clash packed it into a single 64-bit vector, and that is the same board and is in the file.

## Surfer

[Surfer](https://surfer-project.org/) is an open source waveform viewer with a build that runs in a browser.
Open <https://app.surfer-project.org/> and drop `testBench.fst` onto the window.

The file does not go anywhere.
The browser build reads the bytes through the browser's own file interface and never sends them: the one request Surfer can make over the network is the command that fetches a waveform from a URL, and we are not using it.

The panel on the left is the design hierarchy, and it has one scope at the root: `testbench`.
Inside it is one more, called `life_cexampleprojecttestbench_app_arg`, which is chapter 10's instantiation of `entity life.life` under the label Clash gave it.
Select that scope, and the first five variables in it are `clk`, `rst`, `en`, `cmd` and `cells`.
Those are the names we chose in chapter 9, in the order the port map has them, and they arrived here unchanged.
They are lower case because a VHDL identifier is case insensitive and NVC writes the dump in lower case, which is also why the test bench's own clock appears as `\example.project.testbench_clk\` rather than with the capitals chapter 10 read in the file.
Ours were lower case to begin with.

Below the five are seven more things, and it is worth knowing what they are before deciding not to open most of them.
Four are records: `st`, which is the state register and which we come back to, and `result`, `\c$ds_case_alt\` and `\c$ds_case_alt_0\`, which are the signals feeding it.
Two are Clash's own signals, both named `\c$ds_case_alt_selection…`.
The seventh is another scope, `example_project_life_step_result_0`, and it is chapter 9's `step` entity: inside it are the `for … generate` blocks that chapter read, one per cell and one per addition, and there are 1890 of them.
Everything this chapter looks at is in the level above.

Add `clk`, `rst`, `cmd` and `cells`.
`en` is worth looking at once and then leaving: it is held at `true` for the whole run, because chapter 6 passed `enableGen` and every chapter since has passed it too, and seeing that the ritual was a constant is the only thing it has to teach.

Four signals are now on screen, and the first two are the ones a hardware engineer reads first:

- `clk` is low until 100 nanoseconds and then toggles every 5, so its rising edges are at 100, 110, 120 and so on: nine of them, which are the eight cycles chapter 10 sampled and the one on which the test bench finished;
- `rst` is high from time zero and falls at 110 nanoseconds, which is `resetGen` asserting for the first two cycles: it is why chapter 6's first two boards were the seed, and why every chapter since has counted from the third.

## The command bus

`cmd` is one bus, 67 bits wide, and Surfer shows a bus in hexadecimal.
Sixty-seven bits of hexadecimal is not what we came for, so click `cmd` to focus it, press space to open Surfer's command prompt, and type `item_set_format binary`.

Now the whole of chapter 8 is on one line, and it changes six times:

- from 0 to 120 nanoseconds, `0` followed by sixty-six `-`;
- at 120, `101` followed by sixty-four `-`;
- at 130, `110` followed by sixty-four `-`;
- at 140, `0` followed by sixty-six `-`;
- at 150, `111` followed by sixty-four `-`;
- at 160, `100` followed by the blinker;
- at 170, `0` followed by sixty-six `-`.

Read the leading bits.
The first says whether there is a command at all, which is `Maybe`'s tag; the next two say which one, which is `Command`'s.
Chapter 8 counted those off with `pack` and they are in declaration order, so `Load` is `00`, `Step` is `01`, `Run` is `10` and `Pause` is `11`.
`101` is `Just Step`, `110` is `Just Run`, `111` is `Just Pause`, and the `100` at 160 nanoseconds is `Just (Load blinker)` with the board it carries.
That is chapter 10's stimulus, in order: the type this design has taken as its input since chapter 7 is three bits and a field, and here it is.

The `-` is a don't care, and it is the same one chapter 10 read in `testBench.vhdl` as `"0" & "------…"`.
Here it is on a wire, on seven cycles out of eight, and it is what `Nothing` and the three payload-free commands put on the sixty-four wires a board would have used.

Then watch the design ignore them.
`cells` changes at 130, 150 and 170 nanoseconds, and the payload holds a board only at 160: the state takes one when the tag says `Load` and at no other time.
It is worth being exact about what that costs, and chapter 9's VHDL was exact about it: `b <= … fromSLV(cmd(63 downto 0))` has no condition on it, so those sixty-four bits are turned into a board on every cycle and a multiplexer throws it away.
The type system removed a class of mistake, not a wire.

The one-cycle rule the last four chapters have described in prose is here as a picture.
`Just Step` is on the bus at 120 nanoseconds and `cells` changes at 130.
A command is what the register reads at the next edge, so its effect is one cycle later, every time.

## One bit of the state

Open the `st` scope and there is one variable in it, `st_0_sel1_running`.
That is `St`'s second field, the `Bool` chapter 8 added so that `Run` and `Pause` would have something to change, and it is one bit of the state register carrying the name it was declared with.

It is `false` until 140 nanoseconds, `true` from 140 to 160, and `false` after that.
`Just Run` is on the bus at 130 and `Just Pause` at 150, so both take effect one edge later: the same rule again, on a different field of the same register.

The field that is missing is the first one, the board, and it is the array the second note was about.
Nothing is hidden by that, because `lifeT` returns the current board as its output, so the state's board and `cells` are the same sixty-four bits by construction.
It is the reason all four of those record scopes hold one variable where the record has two fields.

## The board, as bits

`cells` is 64 bits wide and changes three times.
Read as bits it is the board, row 0 first, a `1` where a cell is alive, which means the pictures the REPL has printed since chapter 3 are on this waveform too and are merely harder to see.

Ask the prompt for the dictionary between the two.
`pack` is the function chapter 8 used to count the width of a `Command`; on a `Board` it gives the sixty-four bits in the order the port carries them:

```
clashi> pack glider
0b0100_0000_0010_0000_1110_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000
clashi> pack glider1
0b0000_0000_1010_0000_0110_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000
clashi> pack glider2
0b0000_0000_0010_0000_1010_0000_0110_0000_0000_0000_0000_0000_0000_0000_0000_0000
clashi> pack blinker
0b0000_0000_0000_0000_0000_0000_0011_1000_0000_0000_0000_0000_0000_0000_0000_0000
```

Two groups of four to a row, eight rows to a board.
`cells` holds `glider` from the start of the run, `glider1` from 130 nanoseconds, `glider2` from 150 and `blinker` from 170: chapter 10's eight expected boards, with the repeats collapsed into the three moments where something changed.

That is the division of labour, and it is worth stating once.
A board is a picture and belongs in the REPL, where `render` prints it as eight lines of `#` and `.`; a clock, a reset, a bus and a one-cycle latency are shapes in time and belong on a waveform.
Neither instrument is the better one.

## Notice that

**The algebraic data type did not disappear at the boundary.**
`Maybe Command` is a tag and a payload in Haskell, and on this waveform it is a tag and a payload: one bit, then two, then sixty-four.
Nothing was translated away and nothing was added, which is why the bits are countable against what `pack` printed at the prompt three chapters ago.

**The payload is driven with meaningless values, and the design decodes them anyway.**
On seven cycles out of eight, sixty-four wires carry don't cares into a `fromSLV` that turns them into a board, and a multiplexer discards it.
What chapter 7 bought is not fewer wires: it is that no Haskell in this design can read that board, because the payload is unreachable without matching on `Just` and the compiler is what enforces it.
Nothing is switched off.

**The names on the waveform are the ones we chose, except where we did not choose them.**
`clk`, `rst`, `en`, `cmd` and `cells` are chapter 9's `Synthesize` annotation, and `st_0_sel1_running` is chapter 8's record field with Clash's prefix on it; `life_cexampleprojecttestbench_app_arg` and `example_project_life_step_result_0` are Clash's alone, and so are the four `\c$` signals beside them.
A `Synthesize` annotation names the top of a design and nothing inside it, which is exactly what chapter 9 said it would cost.

**A dump is not the design.**
This one does not hold the boards inside the `step` entity, because they are arrays of arrays and NVC said so in a note.
It says nothing about how fast the design would run or whether it fits, because NVC is not a synthesis tool.
And it agrees with chapter 10's `sampleN` because both are the same circuit, not because either one checked the other.

## Where this goes

The design is written, checked, read as VHDL, simulated and now watched.
All of it has been an 8×8 board, and that 8 has been written into every type since chapter 3.

Chapter 12 takes the size out.
One description with the board size as a parameter, and one `:vhdl` that generates two entities from it: an 8×8 and a 16×16, with `cells` sixty-four bits wide in one file and two hundred and fifty-six in the other.
