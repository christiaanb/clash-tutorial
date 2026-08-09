"""Drive `clashi` through a pty and record exactly what a reader would see.

Every transcript in `book/` is pasted from a terminal rather than written from
reasoning about what Clash would do. This is the terminal.

A capture is a list of steps run against a project generated from `template/`:

    a string          typed at the prompt, and its output recorded
    ("edit", path)    overwrite src/Example/Project.hs with `path`

                      This stands in for the reader's edit. It happens while
                      `clashi` is still holding the module it compiled at
                      startup, so a following ":r" is a real reload rather than
                      a no-op, and the chapter's edit-reload-evaluate habit is
                      exercised rather than assumed.

    ("save", dir)     copy the generated HDL tree aside as `dir`
    ("clean",)        delete the generated HDL tree

`save` exists because a chapter may generate more than once in one session and
each run overwrites the last. Saving between runs is what lets a chapter quote
both, and what lets a rerun be diffed against the previous one to show the
output is deterministic.

Two details are load bearing and were arrived at the hard way:

- The pty is opened at a fixed width, `TERM` is `dumb` and `COLUMNS` is set to
  match, so a capture does not change shape with the terminal it was taken in.
  `:i` output was checked at 40, 80 and 200 columns and does not move, but the
  width is pinned rather than trusted.
- The locale is pinned to UTF-8, because GHC chooses its quoting from it.
  `:i register` ends `-- Defined in ‘Clash.Explicit.Signal’` under any UTF-8
  locale and `-- Defined in `Clash.Explicit.Signal'` under `LC_ALL=C`. A reader
  has a UTF-8 locale, so that is what a capture must have; leaving it to the
  environment means the book records whichever one the last capture happened to
  run under.
- haskeline redraws a command line longer than the terminal, so the *echo* of a
  long command is not the command. The echo is dropped and the line that was
  actually sent is written back in its place. Everything after it is verbatim.
  A mismatch between the two is reported on stderr rather than silently
  accepted.
"""

import fcntl
import os
import pty
import select
import shutil
import struct
import sys
import termios
import time

PROMPT = b"clashi> "
READER_FILE = "src/Example/Project.hs"


class Session:
    """A captured session: the whole transcript, and one block per command."""

    def __init__(self, blocks):
        self.blocks = blocks

    @property
    def text(self):
        return "".join(self.blocks)

    @property
    def commands(self):
        """The commands, in order, numbered as `join` numbers them."""
        return [block.split("\n", 1)[0][len("clashi> "):] for block in self.blocks]

    def listing(self):
        """The numbered commands, for putting a `join` call together."""
        return "\n".join(
            "%2d  %s" % (i, cmd) for i, cmd in enumerate(self.commands)
        )

    def join(self, *indices):
        """The given blocks, concatenated, in the order they were captured.

        A chapter rarely shows every command it ran. Interrogating something
        with `:i` to find out whether it is worth showing costs nothing and
        changes nothing, so captures tend to hold more than the chapter does.
        Blocks are independent: a reader typing only the shown commands sees
        only the shown output.

        Only commands are numbered. `edit`, `save` and `clean` steps produce no
        output and take no number, which is the easy thing to get wrong, so an
        index that does not exist prints the numbering rather than an IndexError.
        """
        for i in indices:
            if not 0 <= i < len(self.blocks):
                raise SystemExit(
                    "no block %d; this session captured %d:\n%s"
                    % (i, len(self.blocks), self.listing())
                )
        return "".join(self.blocks[i] for i in indices)

    def write(self, path):
        with open(path, "w") as handle:
            handle.write(self.text)
        return self.text


def run(project, steps, out_path=None, cols=80, hdl_dir="vhdl", timeout=900,
        locale="C.UTF-8"):
    """Run `steps` against `project` and return a Session.

    `project` is a directory generated from `template/clash-tutorial.hsfiles`,
    with `src/Example/Project.hs` already holding the previous chapter's end
    state, and already built. `clashi` is opened with that module on the command
    line, which is the one invocation the tutorial uses (D13).
    """
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(project)
        os.environ["TERM"] = "dumb"
        os.environ["COLUMNS"] = str(cols)
        os.environ["LC_ALL"] = locale
        os.environ["LANG"] = locale
        os.execvp("stack", ["stack", "run", "clashi", "--", READER_FILE])

    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 50, cols, 0, 0))

    buf = bytearray()

    def read_until_prompt(mark, need_newline):
        deadline = time.time() + timeout
        while time.time() < deadline:
            if bytes(buf).endswith(PROMPT) and len(buf) > mark:
                tail = bytes(buf[mark:])
                if not need_newline or b"\n" in tail:
                    # Give a beat for anything still in flight.
                    ready, _, _ = select.select([fd], [], [], 0.4)
                    if not ready:
                        return
            ready, _, _ = select.select([fd], [], [], min(1.0, deadline - time.time()))
            if not ready:
                continue
            try:
                data = os.read(fd, 65536)
            except OSError:
                return
            if not data:
                return
            buf.extend(data)
        raise SystemExit("timed out waiting for the prompt after byte %d" % mark)

    read_until_prompt(0, False)

    blocks, echoes = [], []
    for step in steps:
        if isinstance(step, tuple):
            _apply(step, project, hdl_dir)
            continue
        mark = len(buf)
        os.write(fd, step.encode() + b"\n")
        read_until_prompt(mark, True)
        chunk = bytes(buf[mark:]).decode("utf-8", "replace")
        chunk = chunk.replace("\r\n", "\n").replace("\r", "")
        echo, _, rest = chunk.partition("\n")
        assert rest.endswith("clashi> "), repr(rest[-40:])
        body = rest[: -len("clashi> ")]
        blocks.append("clashi> " + step + "\n" + body)
        echoes.append((step, echo.rstrip()))

    os.write(fd, b":q\n")
    time.sleep(0.5)
    os.close(fd)
    os.waitpid(pid, 0)

    for sent, echo in echoes:
        # A command at least as wide as the terminal is redrawn by haskeline, so
        # its echo is expected not to match and says nothing. A short one that
        # differs does: something ate or added characters, and the transcript
        # below it should not be trusted.
        if echo != sent and len(sent) + len(PROMPT) < cols:
            print(
                "echo differed for %r\n  terminal showed %r" % (sent[:60], echo[:60]),
                file=sys.stderr,
            )

    session = Session(blocks)
    if out_path is not None:
        session.write(out_path)
    return session


def _apply(step, project, hdl_dir):
    action = step[0]
    if action == "edit":
        shutil.copyfile(step[1], os.path.join(project, READER_FILE))
    elif action == "save":
        shutil.rmtree(step[1], ignore_errors=True)
        shutil.copytree(os.path.join(project, hdl_dir), step[1])
    elif action == "clean":
        shutil.rmtree(os.path.join(project, hdl_dir), ignore_errors=True)
    else:
        raise SystemExit("unknown step %r" % (step,))
