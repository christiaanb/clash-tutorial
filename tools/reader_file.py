"""Derive the reader's `src/Example/Project.hs` from a chapter's module.

`code/src/Chapters/ChNN.hs` is the complete end state of the reader's file at
the end of chapter NN, plus three things the reader never sees: a module haddock,
the module name, and the `ANCHOR` comments the book includes between. Stripping
those gives the file to capture a session against.

Deriving it rather than keeping a copy by hand is the point. A hand-kept copy
drifts from `code/`, and the drift is invisible until a reader follows the
chapter and gets output the book does not show. What CI builds and what the
transcript was captured against are then the same file by construction.

Usage:

    python3 tools/reader_file.py code/src/Chapters/Ch09.hs out/Project.hs

An intermediate state, for a chapter that edits more than once, drops the
anchored regions that arrive in a later edit:

    python3 tools/reader_file.py code/src/Chapters/Ch09.hs out/first.hs \\
        --without opaque-step

Where a later edit *replaces* an earlier definition rather than adding to it,
dropping is not enough: chapter 8's first state is chapter 7's `lifeT` and
`life` with `Command` added above them. Put the earlier chapter's version back
instead:

    python3 tools/reader_file.py code/src/Chapters/Ch08.hs out/first.hs \\
        --without st --revert life-t=Ch07 --revert life=Ch07

Both forms derive every line from a module that CI builds, so an intermediate
state cannot drift from the chapter it belongs to.
"""

import argparse
import os
import re
import sys

MODULE_LINE = "module Example.Project where\n"
ANCHOR = re.compile(r"^\s*-- ANCHOR(_END)?:\s*(\S+)")
CHAPTERS = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "code", "src", "Chapters",
)


def chapter_path(name):
    """`Ch07` or a path; a bare module name resolves under code/src/Chapters."""
    if os.path.sep in name or name.endswith(".hs"):
        return name
    return os.path.join(CHAPTERS, name + ".hs")


def regions(source):
    """Every anchored region of `source`, as {name: text}, anchors excluded."""
    found, open_at = {}, {}
    for line in source.splitlines(keepends=True):
        match = ANCHOR.match(line)
        if match:
            is_end, name = bool(match.group(1)), match.group(2)
            if is_end:
                if name not in open_at:
                    raise SystemExit("anchor %r closed but never opened" % name)
                found[name] = "".join(open_at.pop(name))
            else:
                open_at[name] = []
            continue
        for collecting in open_at.values():
            collecting.append(line)
    if open_at:
        raise SystemExit("anchor %r is never closed" % sorted(open_at)[0])
    return found


def derive(source, without=(), revert=None):
    """Return the reader's file, as text, for the given chapter module.

    `without` names anchored regions to drop. `revert` maps an anchor name to
    another chapter's module, whose region of that name is used instead.
    """
    without = set(without)
    revert = dict(revert or {})
    replacements = {}
    for name, module in revert.items():
        with open(chapter_path(module)) as handle:
            available = regions(handle.read())
        if name not in available:
            raise SystemExit("%s has no anchor %r to revert to" % (module, name))
        replacements[name] = available[name]

    seen = set()
    out, started, skipping = [], False, None

    for line in source.splitlines(keepends=True):
        if not started:
            # Everything above the module line is the haddock, which is ours.
            if line.startswith("module "):
                out.append(MODULE_LINE)
                started = True
            continue

        match = ANCHOR.match(line)
        if match:
            is_end, name = bool(match.group(1)), match.group(2)
            seen.add(name)
            if name in without or name in replacements:
                if is_end:
                    if name in replacements:
                        out.append(replacements[name])
                    skipping = None
                else:
                    skipping = name
            continue

        if skipping is None:
            out.append(line)

    if skipping is not None:
        raise SystemExit("anchor %r is never closed" % skipping)

    missing = (without | set(replacements)) - seen
    if missing:
        raise SystemExit("no such anchor: %s" % ", ".join(sorted(missing)))

    return _single_blanks("".join(out))


def _single_blanks(text):
    """Collapse runs of blank lines to one.

    Dropping a region leaves the blank line above it and the one below, and
    every definition in these modules is separated by exactly one. Without this
    an intermediate state has a spare line in it, which is invisible on the page
    and moves every `-- Defined at` line number below it.
    """
    out, blank = [], False
    for line in text.splitlines(keepends=True):
        if line.strip():
            out.append(line)
            blank = False
        elif not blank:
            out.append(line)
            blank = True
    return "".join(out)


def build(module, without=(), revert=None):
    """`derive` for a chapter module named `Ch07` or given as a path."""
    with open(chapter_path(module)) as handle:
        return derive(handle.read(), without, revert)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("chapter", help="path to code/src/Chapters/ChNN.hs")
    parser.add_argument("output", help="where to write the reader's file")
    parser.add_argument(
        "--without",
        action="append",
        default=[],
        metavar="ANCHOR",
        help="drop this anchored region; repeatable, for intermediate states",
    )
    parser.add_argument(
        "--revert",
        action="append",
        default=[],
        metavar="ANCHOR=MODULE",
        help="use MODULE's version of this region; repeatable",
    )
    args = parser.parse_args(argv)

    revert = {}
    for entry in args.revert:
        if "=" not in entry:
            parser.error("--revert wants ANCHOR=MODULE, got %r" % entry)
        name, module = entry.split("=", 1)
        revert[name] = module

    with open(args.chapter) as handle:
        text = derive(handle.read(), args.without, revert)
    with open(args.output, "w") as handle:
        handle.write(text)


if __name__ == "__main__":
    sys.exit(main())
