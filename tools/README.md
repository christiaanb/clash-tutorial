# Capture tools

`CLAUDE.md` says nothing goes into the book that has not been run. These three
modules are how that is met in practice, and they exist because the alternative
is a chapter that is *almost* what the terminal said.

| Module | What it is for |
|---|---|
| `clashi_capture.py` | Drives `clashi` through a pty and records what a reader sees |
| `reader_file.py` | Derives the reader's `src/Example/Project.hs` from `code/src/Chapters/ChNN.hs` |
| `chapter_source.py` | Fills a prose template from real generated files, by line range |

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

## What these do not do

**Intermediate states that replace rather than add.** `--without` drops anchored
regions from a chapter's end state, which builds the intermediate state whenever
the chapter's edits are additions. Where a later edit rewrites an earlier
definition, as chapter 8 rewrites chapter 7's `lifeT` and `life`, the
intermediate state is not a subset of the end state and has to be written by
hand.

**Checking what already shipped.** These build a chapter; nothing re-checks one.
The chapters are cumulative, so a change in chapter 4 can invalidate the
transcripts in chapter 9, and today the only thing standing between that and a
reader is whoever remembers to look. A tool that re-captures every fenced block
in `book/` and diffs it against what ships is the obvious next thing to build,
and it is a much larger job: it needs `clashi` and a generated project in CI, and
it would be slow.
