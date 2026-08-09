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

That works when the chapter's edits are additions, which is the common case.
Where a later edit *replaces* an earlier definition rather than adding to it,
the intermediate state is not a subset of the end state and this cannot build
it; write that one out by hand and say so where it lives.
"""

import argparse
import re
import sys

MODULE_LINE = "module Example.Project where\n"
ANCHOR = re.compile(r"^\s*-- ANCHOR(_END)?:\s*(\S+)")


def derive(source, without=()):
    """Return the reader's file, as text, for the given chapter module."""
    without = set(without)
    seen = set()
    out, started, dropping = [], False, None

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
            if name in without:
                dropping = None if is_end else name
            continue

        if dropping is None:
            out.append(line)

    if dropping is not None:
        raise SystemExit("anchor %r is never closed" % dropping)

    missing = without - seen
    if missing:
        raise SystemExit("no such anchor: %s" % ", ".join(sorted(missing)))

    return "".join(out)


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
    args = parser.parse_args(argv)

    with open(args.chapter) as handle:
        text = derive(handle.read(), args.without)
    with open(args.output, "w") as handle:
        handle.write(text)


if __name__ == "__main__":
    sys.exit(main())
