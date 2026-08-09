# An entity

Eight chapters have built a design that nothing outside Haskell can see.
Clash will not generate anything until it is told which function is the top of that design, and it has nothing to call the entity or its ports until it is told that too.
This chapter says both of those things in the source, generates the VHDL, and then draws one boundary inside the design and generates it again.

## Naming the entity, and naming its ports

Add this directly above `life`:

```haskell
{{#include ../../../code/src/Chapters/Ch09.hs:synthesize}}
```

It is not a definition, and `life` itself does not change: it is a note attached to `life` that Clash reads and the rest of the file ignores.
`t_name` is what the entity will be called.
`t_inputs` is one name per argument, in the order the arguments come, which is why the clock, the reset and the enable each need one: each of them is an argument, and has been since chapter 6.
`t_output` is the one name for what comes back.

Reload, and then the one command that turns the loaded module into VHDL:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :vhdl
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, src/Example/Project.o )
Ok, one module reloaded.
GHC: Setting up GHC took: 0.140s
GHC: Compiling and loading modules took: 3.083s
Clash: Parsing and compiling primitives took 0.352s
GHC+Clash: Loading modules cumulatively took 6.003s
Clash: Compiling Example.Project.life
Clash: Normalization took 0.255s
Clash: Netlist generation took 0.009s
Clash: Compiling Example.Project.life took 0.368s
Clash: Total compilation took 6.375s
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
```

`:vhdl` was given nothing to work on, because a binder carrying that annotation is what it goes looking for.
It compiled the module to object code rather than interpreting it, generated from that, and put the interpreted module back afterwards, which is what the two `Compiling` lines around the timings are.
Those timings are the capture machine's and yours will be different; what they are worth reading for is the order of magnitude, which is seconds.

Four files were written, into `vhdl/Example.Project.life/` under the project directory:

- `life.vhdl`, 548 lines, the entity and its architecture;
- `life_types.vhdl`, 227 lines, a package declaring every type those two use;
- `life.sdc`, one line, the clock constraint;
- `clash-manifest.json`, which lists the other three.

Three of those four file names are the one we wrote in `t_name`.
Open `life.vhdl`, and the first thing in it is the reason this chapter exists:

```vhdl
entity life is
  port(-- clock
       clk   : in life_types.clk_System;
       -- reset
       rst   : in life_types.rst_System;
       -- enable
       en    : in life_types.en_System;
       cmd   : in life_types.Maybe;
       cells : out std_logic_vector(63 downto 0));
end;
```

Five ports, with the five names we chose, in the order we wrote them down.
Clash has put a comment over the first three, and they are ports for the same reason the others are: they were arguments.

One name buys one port, which is worth being plain about.
`cells` is a single port sixty-four bits wide rather than sixty-four ports of one bit, and `cmd` is a single port sixty-seven bits wide with the tag and the payload inside it.
That is what asking for one name gets, and it is the shape chapter 11 puts on a waveform.

## A boundary, and a second file

Those 548 lines are the whole design.
The register is in there, and so is the command decode, and so are the four shifts, the adder tree and all sixty-four copies of the cell rule, because Clash inlines everything into one entity unless it is told where not to.

Tell it, directly above `step`:

```haskell
{{#include ../../../code/src/Chapters/Ch09.hs:opaque-step}}
```

That says `step` is not to be inlined into whatever uses it.
Reload and generate again:

```
clashi> :r
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
clashi> :vhdl
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, src/Example/Project.o )
Ok, one module reloaded.
GHC: Setting up GHC took: 0.132s
GHC: Compiling and loading modules took: 3.025s
Clash: Parsing and compiling primitives took 0.870s
GHC+Clash: Loading modules cumulatively took 5.446s
Clash: Compiling Example.Project.life
Clash: Normalization took 0.692s
Clash: Netlist generation took 0.012s
Clash: Compiling Example.Project.life took 0.721s
Clash: Total compilation took 6.171s
[1 of 1] Compiling Example.Project  ( src/Example/Project.hs, interpreted )
Ok, one module reloaded.
```

There are five files now.
`life.vhdl` has gone from 548 lines to 211, and a file that was not there before, `Example_Project_life_step.vhdl`, is 343.
Nothing about the design changed, and nothing about the interface changed either: the entity declaration above is byte for byte the one that is in the file now.
What changed is where Clash put the logic.

## Three things to find

Between them the three `.vhdl` files are 781 lines, and reading all of them is not the exercise: it is the way to come away convinced the output is unreadable, which it is if you read it as prose.
There are three things worth finding, and the rest can be left alone.

### The widths, in `life_types.vhdl`

```vhdl
  type St_0 is record
    St_0_sel0_board : array_of_array_of_8_boolean(0 to 7);
    St_0_sel1_running : boolean;
  end record;
  subtype Command is std_logic_vector(65 downto 0);
  subtype Maybe is std_logic_vector(66 downto 0);
```

`65 downto 0` is sixty-six bits and `66 downto 0` is sixty-seven, which are the two numbers chapter 8 counted off the end of `pack`.
`St_0` is the state, a record with the two fields it was declared with under the names they were declared with.

### The cell rule, in `Example_Project_life_step.vhdl`

That file is an entity like any other, and it begins:

```vhdl
entity Example_Project_life_step is
  port(b      : in life_types.array_of_array_of_8_boolean(0 to 7);
       result : out life_types.array_of_array_of_8_boolean(0 to 7));
end;
```

Two ports, one in and one out, named `b` and `result`.
Those names are Clash's: we named the top's ports and only the top's, and a boundary drawn inside the design comes with whatever names Clash makes for it.

Further down is what chapter 2 wrote:

```vhdl
  -- zipWith begin
  zipWith_3 : for i_10 in result'range generate
  begin
    -- zipWith begin
    zipWith_2_0 : for i_9_2 in result(i_10)'range generate
    begin
      fun_0 : block
          signal result_1                   : boolean;
          signal \c$case_alt\               : boolean;
          signal \c$case_alt_0\             : boolean;
          signal \c$case_alt_selection_res\ : boolean;
        begin
          result(i_10)(i_9_2) <= result_1;

          result_1 <= \c$case_alt\ when b(i_10)(i_9_2) else
                      \c$case_alt_0\;

          \c$case_alt_selection_res\ <= \c$vec2_0\(i_10)(i_9_2) = to_unsigned(2,4);

          \c$case_alt\ <= true when \c$case_alt_selection_res\ else
                          \c$case_alt_0\;

          \c$case_alt_0\ <= \c$vec2_0\(i_10)(i_9_2) = to_unsigned(3,4);


        end block;
    end generate;
    -- zipWith end
  end generate;
  -- zipWith end
```

Two `for … generate` blocks, one inside the other, eight rows by eight columns, and inside them one copy of the cell rule per cell.
`b(i_10)(i_9_2)` is one cell of the board arriving on the port, `to_unsigned(2,4)` and `to_unsigned(3,4)` are the two counts chapter 2's `case` named, and the `when … else` nested inside each other are the order its rows were written in: alive with two survives, three regardless, otherwise dead.

The counts those two are compared against are higher up the same file:

```vhdl
  -- zipWith begin
  zipWith_1 : for i_4 in ws1'range generate
  begin
    r_block_4 : block
      signal \c$bb_res_res\ : life_types.array_of_array_of_8_unsigned_4(0 to 7);
    begin
      -- zipWith begin
      zipWith_0 : for i_3 in \c$bb_res_res\'range generate
      begin
        -- zipWith begin
        zipWith_4 : for i_2_1 in \c$bb_res_res\(i_3)'range generate
        begin
          \c$bb_res_res\(i_3)(i_2_1) <= \c$vec2\(i_4)(i_3)(i_2_1) + \c$vec1\(i_4)(i_3)(i_2_1);


        end generate;
        -- zipWith end
      end generate;
      -- zipWith end

      ws1(i_4) <= \c$bb_res_res\;


    end block;
  end generate;
  -- zipWith end
```

Three `for … generate` blocks this time, seven by eight by eight, and one `+` at the centre of them.
Seven, because summing eight shifted copies of the board takes seven additions; eight by eight, because each of those additions is done for every cell.
Chapter 4 said that was four hundred and forty-eight four-bit additions described by a single `+`, and this is that `+`.
There is exactly one in this file and there are none at all in `life.vhdl`: every piece of arithmetic in the design is inside the boundary we drew.

That is the promise chapter 4 made about this chapter, paid: the `map`s and `zipWith`s are here, and they are `for … generate`.

### The register and the decode, in `life.vhdl`

There is one process in the file, and it starts like this:

```vhdl
  -- register begin
  st_register : process(clk,rst)
  begin
    if rst =  '1'  then
```

The sixty-five lines after that are the value the register holds while the reset is asserted: the glider, as sixty-four `true`s and `false`s with five of them `true`, and then `St_0_sel1_running => false`, which is the mode chapter 8 started the design in.
Then the process ends:

```vhdl
    elsif rising_edge(clk) then
      if en then
        st <= result;
      end if;
    end if;
  end process;
  -- register end
```

One `rising_edge`, on `clk`.
`en` gates the assignment, so on a cycle when the enable is low the register keeps what it has.
`result` is what it takes otherwise, and just below the process is what decides `result`:

```vhdl
  with (cmd(66 downto 66)) select
    result <= \c$ds_case_alt_0\ when "0",
              \c$ds_case_alt\ when others;

  \c$ds_case_alt_selection_1\ <= cmd(65 downto 0);

  with (\c$ds_case_alt_selection_1\(65 downto 64)) select
    \c$ds_case_alt\ <= ( St_0_sel0_board => b
                       , St_0_sel1_running => false ) when "00",
                       ( St_0_sel0_board => result_0
                       , St_0_sel1_running => false ) when "01",
                       ( St_0_sel0_board => st.St_0_sel0_board
                       , St_0_sel1_running => true ) when "10",
                       ( St_0_sel0_board => st.St_0_sel0_board
                       , St_0_sel1_running => false ) when others;
```

`cmd(66 downto 66)` is the `Maybe`'s tag, the top bit of the port, and it picks between the branch for `Nothing` and the branch for a command that arrived.
`cmd(65 downto 64)` is the `Command`'s own tag, and its four rows are `Load`, `Step`, `Run` and `Pause` in the order they were declared, `00` through `11`, which is the numbering chapter 8 read off `pack`.
`b` in the `"00"` row is the board that `Load` carried, and it is decoded here:

```vhdl
  b <= life_types.array_of_array_of_8_boolean'(life_types.fromSLV(cmd(63 downto 0)));
```

That line has no condition on it.
The payload is sliced out of the port and turned into a board on every cycle, whatever the two tags say, and the selects above throw the result away when they disagree.
Chapters 7 and 8 both said that nothing is switched off; this is the line that makes it true.

`result_0` in the `"01"` row is a generation of Life, and it arrives from the other file:

```vhdl
  Example_Project_life_step_result_0 : entity Example_Project_life_step
    port map
      (result => result_0, b      => result_fun_arg);
```

One instantiation.
`lifeT` names `step` twice, in the `Just Step` row and in the running case of the `Nothing` row, and there is one copy of it here feeding both.

## Notice that

**The annotation wrote down what was already true.**
The entity's ports are the arguments `life` already had, in the order it already had them, and the clock, the reset and the enable have been arguments since chapter 6.
Nothing was added to the design to give it a top: a fact about it was recorded where Clash could read it, and the names in that record are ours rather than something the compiler chose.

**Clash flattens unless you tell it not to, and telling it costs something.**
One pragma made one boundary and one more file, and it is the only boundary anywhere in the design, because it is the only one we asked for.
The cost runs both ways: Clash does not optimise across that boundary, and `step`'s own ports are named by Clash rather than by us, because the annotation names the top of a design and this is not the top of one.

**A port list is a fixed number of wires, so this is where the design stops being general.**
Everything above the annotation could be written for a board of any size, and chapter 12 rewrites it that way; the annotation cannot be, because eight is what decides that `cells` is sixty-four bits wide rather than some other number.
Chapter 12 writes two of these annotations and gets two entities from one `:vhdl`, which is the whole of that chapter's result.

**The names you chose are the names you will keep meeting.**
`clk`, `rst`, `en`, `cmd` and `cells` are what chapter 10 hands to a simulator and what chapter 11 finds on a waveform.
That is why they were worth choosing, and it is why the two names in this chapter that we did not choose, `b` and `result`, sit inside a file neither of those chapters has to open.

## Where this goes

The design is VHDL now, and reading it is not the same as knowing it still works.
Chapter 10 has Clash generate a self-checking test bench beside this entity and runs both in NVC, a simulator that has never heard of Haskell.
Six files have to be handed over in the right order, which is the one thing about that chapter worth knowing in advance.
Leave `clashi` running.
