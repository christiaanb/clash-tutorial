"""Assemble a chapter's Markdown from a prose template and real artefacts.

The rule this exists to enforce is `CLAUDE.md`'s: nothing goes into the book
that has not been run. A chapter written by hand can hold a transcript nobody
captured, and the mistake is invisible on the page — it reads exactly like one
that was. A chapter assembled from a template whose slots are filled by `cut`
from generated files and by blocks from a captured session cannot, because there
is no path by which a hand-typed line gets in.

The prose lives in the template, so it is still written rather than generated.
What is generated is every fenced block.

    from chapter_source import cut, render

    parts = dict(
        entity=cut("out/life.vhdl", 10, 19),
        widths=cut("out/life_types.vhdl", 16, 21),
        first_run=session.join(0, 1),
    )
    render(TEMPLATE, parts, "book/src/b/09-an-entity.md")

Two things to know about the template:

- It is filled with `str.format`, so a literal brace has to be doubled. mdBook's
  include directive is all braces, and it is the one that bites:
  `{{{{#include ../../../code/src/Chapters/Ch09.hs:synthesize}}}}` renders as
  `{{#include ...}}`.
- Line ranges are 1-based and inclusive, matching what an editor shows, so a
  range can be read off the file being quoted without arithmetic.

Keep the generator next to the chapter it builds while the chapter is in
review. Regenerating after a re-capture is then one command, and a transcript
that moved by a line is caught by the diff rather than by a reader.
"""


def lines(path):
    """Every line of `path`, without trailing newlines."""
    with open(path) as handle:
        return handle.read().split("\n")


def cut(path, first, last):
    """Lines `first` to `last` of `path`, 1-based and inclusive.

    Quote by range rather than by pattern: a range is checked by eye against the
    file once and then stays checked, whereas a pattern silently starts matching
    somewhere else when the generated output shifts.
    """
    text = lines(path)
    if not 1 <= first <= last <= len(text):
        raise SystemExit(
            "%s has %d lines; asked for %d to %d" % (path, len(text), first, last)
        )
    return "\n".join(text[first - 1:last])


def render(template, parts, out_path):
    """Fill `template` with `parts` and write it to `out_path`."""
    text = template.format(**parts)
    with open(out_path, "w") as handle:
        handle.write(text)
    return text
