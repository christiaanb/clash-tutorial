"""Re-run every transcript in the book and diff it against what ships.

The chapters are cumulative: a rename in chapter 4 propagates through chapter 13,
and a `-- Defined at` line number moves when anything above it does. `code/`
being green proves the chapters still compile. It does not prove the book still
prints what it says it prints, and until now nothing did.

This runs each chapter the way a reader would and compares.

    python3 tools/check_transcripts.py                  # every chapter
    python3 tools/check_transcripts.py --chapter 8
    python3 tools/check_transcripts.py --project /tmp/life   # reuse a build

Two kinds of block are checked:

- a fenced block whose first line is `clashi> …` is a session. Its commands are
  replayed in order and each command's output must match.
- a ```vhdl block must appear, as a contiguous run of lines, in one of the files
  Clash generated during that chapter. Line numbers are not recorded, so a block
  that moves within its file still passes and a block that changed does not.

## Where the chapter's edits come from

Nothing is configured. A chapter's `{{#include …:anchor}}` directives say which
regions of its module are on screen, and its `clashi> :r` lines say when the
reader reloads, so the file at the *k*th reload is the chapter's module with
every region it has not shown yet taken back out. Taken back out means reverted
to the previous chapter's version where there is one — chapter 8's first reload
is chapter 7's `lifeT` and `life` with `Command` added above them — and dropped
where there is not.

That works because the tutorial's habit does not vary: edit, `:r`, evaluate, one
edit per reload. A chapter that reloads without showing the `:r` would be
mis-staged here, and would be wrong in the book for the same reason.
"""

import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import clashi_capture
import reader_file

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOOK = os.path.join(ROOT, "book", "src", "b")
TEMPLATE = os.path.join(ROOT, "template", "clash-tutorial.hsfiles")

FENCE = re.compile(r"^```(\w*)\s*$")
INCLUDE = re.compile(r"^\{\{#include\s+\S*?Ch(\d+)\.hs:(\S+)\}\}\s*$")

# `:vhdl` reports how long it took, which is a fact about the machine that ran
# it. The numbers are replaced so that a missing or extra timing line still
# fails while a different number does not.
TIMING = re.compile(r"^(GHC|Clash|GHC\+Clash): .*\btook:? [0-9.]+s$")
SECONDS = re.compile(r"[0-9]+\.[0-9]+s")

# Chapter 10's `:vhdl` prints "Not specializing TopEntity: Example.Project.life
# [8214565720323891532]", and the number is GHC's unique for that binder. It
# depends on how many names the session allocated before Clash ran, so typing
# one extra command at the prompt changes it. The line is checked; the unique in
# it is not, for the same reason the timings are not.
UNIQUE = re.compile(r"^(Not specializing TopEntity: \S+)\[[0-9]+\]$")


class Mismatch(Exception):
    pass


def chapters():
    """(number, path) for every chapter file in the book, in order."""
    found = []
    for path in sorted(glob.glob(os.path.join(BOOK, "*.md"))):
        match = re.match(r"(\d+)-", os.path.basename(path))
        if match:
            found.append((int(match.group(1)), path))
    return found


def parse(path):
    """The chapter as an ordered list of ('include', anchor) and blocks.

    A block is ('session', [(command, output)]) or ('vhdl', text).
    """
    with open(path) as handle:
        lines = handle.read().split("\n")

    items, i = [], 0
    while i < len(lines):
        fence = FENCE.match(lines[i])
        if not fence:
            i += 1
            continue

        language, body, i = fence.group(1), [], i + 1
        while i < len(lines) and not FENCE.match(lines[i]):
            body.append(lines[i])
            i += 1
        i += 1  # closing fence

        # An mdBook include sits inside a fenced block: the fence is what the
        # reader sees, and the include is how the code got there.
        includes = [INCLUDE.match(line) for line in body]
        if any(includes):
            items.extend(("include", m.group(2)) for m in includes if m)
        elif language == "vhdl":
            items.append(("vhdl", "\n".join(body)))
        elif not language and body and body[0].startswith("clashi> "):
            items.append(("session", split_commands(body)))
    return items


def split_commands(body):
    """A transcript block as [(command, output)]."""
    pairs = []
    for line in body:
        if line.startswith("clashi> "):
            pairs.append((line[len("clashi> "):], []))
        elif pairs:
            pairs[-1][1].append(line)
    return [(cmd, "\n".join(out)) for cmd, out in pairs]


def stage(number, items):
    """The reader's file before the chapter, and after each of its reloads."""
    module = "Ch%02d" % number
    previous = "Ch%02d" % (number - 1) if number > 1 else module

    owned = [anchor for kind, anchor in items if kind == "include"]
    earlier = reader_file.regions(open(reader_file.chapter_path(previous)).read())

    shown, states = [], []
    for kind, value in items:
        if kind == "include":
            shown.append(value)
        elif kind == "session":
            for command, _ in value:
                if command == ":r":
                    pending = [a for a in owned if a not in shown]
                    states.append(dict(
                        module=module,
                        without=[a for a in pending if a not in earlier],
                        revert={a: previous for a in pending if a in earlier},
                    ))
    return dict(module=previous, without=[], revert={}), states


def write_state(spec, path):
    with open(path, "w") as handle:
        handle.write(reader_file.build(**spec))


def normalise(text):
    out = []
    for line in text.split("\n"):
        if TIMING.match(line):
            line = SECONDS.sub("…s", line)
        else:
            line = UNIQUE.sub(r"\1[…]", line)
        out.append(line)
    return "\n".join(out)


def check_chapter(number, path, project, work):
    items = parse(path)
    sessions = [value for kind, value in items if kind == "session"]
    if not sessions:
        return 0, "no transcript"
    if not os.path.exists(reader_file.chapter_path("Ch%02d" % number)):
        return 0, "no module in code/"

    base, states = stage(number, items)
    write_state(base, os.path.join(project, clashi_capture.READER_FILE))
    subprocess.run(
        ["stack", "build"], cwd=project, check=True,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    # Clash caches what it generated and answers `Clash: Using cached result
    # for: …` when the source has not moved since, which is a different
    # transcript from the one a chapter shows. Replaying a chapter twice against
    # the same project is exactly that case, so the tree goes before each replay
    # rather than the checker being idempotent only by luck.
    steps, expected, saves, reload_at, run = [("clean",)], [], [], 0, 0
    for pairs in sessions:
        for command, output in pairs:
            if command == ":r":
                state_path = os.path.join(work, "state-%d.hs" % reload_at)
                write_state(states[reload_at], state_path)
                steps.append(("edit", state_path))
                reload_at += 1
            steps.append(command)
            expected.append((command, output))
            if command == ":vhdl":
                run += 1
                saves.append(os.path.join(work, "run-%d" % run))
                steps.append(("save", saves[-1]))

    session = clashi_capture.run(project, steps, os.path.join(work, "session.txt"))

    problems = []
    for index, (command, want) in enumerate(expected):
        got = session.blocks[index]
        head = "clashi> " + command + "\n"
        assert got.startswith(head), (got[:60], head)
        got = got[len(head):].rstrip("\n")
        if normalise(got) != normalise(want.rstrip("\n")):
            problems.append(report(command, want, got))

    generated = []
    for save in saves:
        for name in sorted(glob.glob(os.path.join(save, "*", "*.vhdl"))):
            with open(name) as handle:
                generated.append((os.path.basename(name), handle.read()))

    for kind, value in items:
        if kind != "vhdl":
            continue
        if not any(value in text for _, text in generated):
            where = ", ".join(sorted({name for name, _ in generated})) or "nothing"
            problems.append(
                "a ```vhdl block is in no generated file (searched: %s)\n%s"
                % (where, indent(value.split("\n")[:4] + ["..."]))
            )

    return len(problems), problems


def report(command, want, got):
    want_lines, got_lines = want.rstrip("\n").split("\n"), got.split("\n")
    detail = ["clashi> " + command]
    for i in range(max(len(want_lines), len(got_lines))):
        a = want_lines[i] if i < len(want_lines) else None
        b = got_lines[i] if i < len(got_lines) else None
        if a != b:
            detail.append("  book  %s" % ("<nothing>" if a is None else repr(a)))
            detail.append("  ran   %s" % ("<nothing>" if b is None else repr(b)))
    return "\n".join(detail)


def indent(lines):
    return "\n".join("    " + line for line in lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--chapter", type=int, action="append", default=[])
    parser.add_argument(
        "--project",
        help="a project generated from the template; one is made if omitted, "
             "and reusing one across runs saves the build",
    )
    parser.add_argument("--keep", action="store_true", help="keep the work directory")
    args = parser.parse_args(argv)

    work = tempfile.mkdtemp(prefix="transcript-check-")
    project = args.project
    try:
        if project is None:
            project = os.path.join(work, "life")
            subprocess.run(
                ["stack", "new", "life", TEMPLATE],
                cwd=work, check=True, stdout=subprocess.DEVNULL,
            )

        failures = 0
        for number, path in chapters():
            if args.chapter and number not in args.chapter:
                continue
            count, problems = check_chapter(number, path, project, work)
            name = os.path.basename(path)
            if isinstance(problems, str):
                print("  --  %s (%s)" % (name, problems))
                continue
            if count:
                failures += count
                print("FAIL  %s, %d block(s)" % (name, count))
                for problem in problems:
                    print(indent(problem.split("\n")))
            else:
                print("ok    %s" % name)

        if failures:
            print("\n%d block(s) no longer match the book." % failures)
        return 1 if failures else 0
    finally:
        if args.keep:
            print("work kept in %s" % work)
        else:
            shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
