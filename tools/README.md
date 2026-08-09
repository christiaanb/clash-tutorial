# Capture tools

`CLAUDE.md` says nothing goes into the book that has not been run. These three
modules are how that is met in practice, and they exist because the alternative
is a chapter that is *almost* what the terminal said.

| Module | What it is for |
|---|---|
| `clashi_capture.py` | Drives `clashi` through a pty and records what a reader sees |
| `reader_file.py` | Derives the reader's `src/Example/Project.hs` from `code/src/Chapters/ChNN.hs` |
| `chapter_source.py` | Fills a prose template from real generated files, by line range |
| `check_transcripts.py` | Re-runs every transcript in the book and diffs it against what ships |

Each has a docstring covering the details worth knowing. What follows is the
recipe they fit into.

## The recipe

**1. A project the reader would have.** Generate one from the template rather
than reusing `code/`, because the reader's module is `Example.Project` and
`code/`'s is `Chapters.ChNN`. Generated identifiers carry the module name, so
excerpts taken from `code/` are the wrong length and sometimes the wrong name.

```
stack new life template/clash-tutorial.hsfiles
cd life && stack build
```

Call it `life`: chapter 1 quotes `Registering library for life-0.1.0.0...` as the
marker that the long first build has finished.

**2. The previous chapter's end state, on disk.** The session has to start where
the last chapter left the reader.

```
python3 tools/reader_file.py code/src/Chapters/Ch08.hs life/src/Example/Project.hs
```

**3. The states each edit produces.** A chapter that edits twice needs the file
as it stands after each edit. Where the edits are additions, derive them from the
end state:

```
python3 tools/reader_file.py code/src/Chapters/Ch09.hs first.hs --without opaque-step
python3 tools/reader_file.py code/src/Chapters/Ch09.hs second.hs
```

**4. Capture.** A driver script, kept beside the chapter while it is in review:

```python
import sys; sys.path.insert(0, "tools")
import clashi_capture

session = clashi_capture.run("life", [
    ("edit", "first.hs"),
    ":r",
    ":vhdl",
    ("save", "run1"),
    ("edit", "second.hs"),
    ":r",
    ":vhdl",
    ("save", "run2"),
], "session.txt")

print(session.listing())
```

`session.listing()` prints the commands with the numbers `session.join` uses.
Only commands are numbered; `edit`, `save` and `clean` produce no output.

**5. Assemble.** The prose is written; every fenced block is filled in.

```python
from chapter_source import cut, render

render(TEMPLATE, dict(
    first_run=session.join(0, 1),
    entity=cut("run1/Example.Project.life/life.vhdl", 10, 19),
), "book/src/b/09-an-entity.md")
```

**6. Run it twice.** Capture the same session again and diff the generated files.
Clash's output is deterministic and the transcripts are not — the timing lines
`:vhdl` prints differ every run — so a chapter that quotes timings has to say
they are the capture machine's.

**7. Then the ordinary checks.** `stack build` and `stack test` in `code/`,
`mdbook build` in `book/`, and the definition of done in `CLAUDE.md`.

## Checking what already shipped

The chapters are cumulative: a rename in chapter 4 reaches chapter 13, and a
`-- Defined at` line number moves when anything above it does. `code/` being
green proves the chapters still compile, not that the book still prints what it
says it prints.

```
python3 tools/check_transcripts.py                       # every chapter
python3 tools/check_transcripts.py --chapter 8
python3 tools/check_transcripts.py --project /tmp/life   # reuse a build
```

It replays each chapter and compares two kinds of block: a fenced block whose
first line is `clashi> …`, command by command, and a ```vhdl block, which must
appear as a contiguous run of lines in one of the files Clash generated during
that chapter. Eight chapters take about eighty seconds against a project that is
already built. CI runs it on every push and pull request.

Nothing configures it. A chapter's `{{#include …:anchor}}` directives say which
regions of its module are on screen and its `clashi> :r` lines say when the
reader reloads, so the file at each reload is derived the same way step 3 above
derives it. That works because the tutorial's habit does not vary: edit, `:r`,
evaluate, one edit per reload. **A chapter that reloads without showing the `:r`
would be staged wrongly here** — and would be wrong in the book for the same
reason, so the constraint is one worth having.

`:vhdl` reports how long it took, which is a fact about the machine rather than
about the design, so those numbers are blanked before comparing. A missing or
extra timing line still fails. The same goes for the unique in chapter 10's
`Not specializing TopEntity: Example.Project.life[…]`: it is GHC's internal
number for that binder and it moves if the session allocated a different number
of names before Clash ran, so the line is checked and the number in it is not.

## What these do not do

**Intermediate states that replace rather than add**, without help. `--without`
drops anchored regions, and `--revert` puts an earlier chapter's version of a
region back, which between them cover every chapter so far. A chapter that
rewrites a region with something in no committed module would need that state
written by hand.

**Prove a chapter teaches anything.** Everything here checks that the book
matches the terminal. Whether the terminal was worth showing is the reviewer's
problem, and `design/02-voice-and-diataxis.md` is what they read.
