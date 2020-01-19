import argparse
import sys
import os

from enum import Enum
from typing import List, Optional

HL_DOCS_KEYWORD = "HL-Docs:"
HL_INCLUDE_FOLLOWING = "HL-Include:"
# "Bugfixes" is a feature owned by the documentation script.
# It does not need an owning feature declaration in the code,
# and exclusively consists of `HL-Docs: ref:Bugfixes` lines.
HL_FEATURE_FIX = "Bugfixes"
HL_BRANCH = "master"
HL_ISSUES_URL = "https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/%i"
HL_SOURCE_URL = "https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/%s/%s#L%s-L%s" % (
    HL_BRANCH, "%s", "%i", "%i")

HL_INDEX_PAGE = """# X2WOTCCommunityHighlander Documentation

## Current status of the Documentation

The documentation is freshly introduced. It will take us a while
to document all old features, but it is expected that new features all come
with their documentation page.

## How to read

The nav bar has a list of features. Click on a feature to view that feature's
documentation. Every feature has:

* A GitHub tracking issue for discussion
* A documented way to use it, for example with an event tuple (TODO: Document Tuples)
* Code references that link to HL source code where the documentation is

## Contribute

Documentation is placed inside of source code (`.uc` and `.ini`) files. Click any
source code reference on an existing page for examples. We're especially happy to
accept pull requests that add documentation for old features.
"""

HL_MKDOCS_YAML = """site_name: X2WOTCCommunityHighlander
site_description: Online documentation for the X2WOTCCommunityHighlander
repo_url: https://github.com/X2CommunityCore/X2WOTCCommunityHighlander
edit_uri: ""
theme:
  name: readthedocs
  highlightjs: true
  hljs_languages:
    - ini
    - unrealscript
"""


def parse_args() -> (List[str], Optional[str]):
    parser = argparse.ArgumentParser(
        description='Generate HL docs from source files.')
    parser.add_argument('indirs',
                        metavar='indir',
                        type=str,
                        nargs='+',
                        help='input file directories')
    parser.add_argument('--outdir',
                        dest='outdir',
                        help='output directorys (default: None, check only)')

    args = parser.parse_args()

    if args.outdir != None and os.path.isfile(args.outdir):
        print("%s: error: Output dir %s is existing file" %
              (sys.argv[0], args.outdir))
        sys.exit(1)

    for indir in args.indirs:
        if not os.path.isdir(indir):
            print("%s: error: Input directory %s does not exist or is file" %
                  (sys.argv[0], indir))
            sys.exit(1)

    return args.indirs, args.outdir


def make_ref(file: str, span: (int, int)) -> dict:
    return {"file": file, "span": span}


"""
dict:
    feature: str, feature name
    issue: int, issue number
    tags: [str], tags
    text: str
    links: [{file: str, span: (int, int)}]
or
    ref: str, feature name
    text: str
    links: [{file: str, span: (int, int)}]
"""


def make_doc_item(lines: List[str], file: str,
                  span: (int, int)) -> Optional[dict]:
    item = {}
    # first line: meta info
    for pair in lines[0].split(';'):
        k, v = pair.strip().split(':')
        if k == 'feature' or k == 'ref':
            item[k] = v
        elif k == 'issue':
            item[k] = int(v)
        elif k == 'tags':
            item[k] = v.split(',')
        else:
            print("%s: error: %s: unknown key `%s`" % (sys.argv[0], file, k))

    item["links"] = []
    item["links"].append(make_ref(file, span))
    item["text"] = "\n".join(lines[1:])
    return item


"""
Process file, extract documentation
"""


def process_file(file, lang) -> List[dict]:
    class ParserState(Enum):
        TEXT = 1
        DOC = 2
        INCLUDE = 3

    class Parser:
        def __init__(self, doc_items):
            self.doc_items = doc_items

        def reset(self, filename):
            self.lines = []
            self.startline = -1
            self.indent = None
            self.state = ParserState.TEXT
            self.filename = filename

        def read_doc_line(self, line):
            if line.startswith(HL_DOCS_KEYWORD):
                print("%s: error: %s: multiple `%s` in one item" %
                      (sys.argv[0], self.filename, HL_DOCS_KEYWORD))
            elif line.startswith(HL_INCLUDE_FOLLOWING):
                self.lines.append("\n```%s" % (lang))
                self.state = ParserState.INCLUDE
            else:
                self.lines.append(line)

        def parse_file(self, file, filename):
            self.reset(filename)

            for lnum, line in enumerate(infile):
                orig_line = line.rstrip()
                s_line = line.strip()
                is_doc_comment = len(s_line) >= 3 and (s_line[0:3] == '///'
                                                       or s_line[0:3] == ";;;")
                line = s_line[3:]
                if line.startswith(' '):
                    line = line[1:]

                if self.state == ParserState.TEXT:
                    if is_doc_comment and line.startswith(HL_DOCS_KEYWORD):
                        startline = lnum
                        self.lines.append(line[len(HL_DOCS_KEYWORD) + 1:])
                        self.state = ParserState.DOC
                elif self.state == ParserState.DOC:
                    if is_doc_comment:
                        self.read_doc_line(line)
                    else:
                        item = make_doc_item(self.lines, self.filename,
                                             (startline, lnum))
                        if item != None:
                            self.doc_items.append(item)
                        else:
                            print("...while processing %s:%i" % (file, lnum))
                        self.state = ParserState.TEXT
                        self.lines = []
                elif self.state == ParserState.INCLUDE:
                    if is_doc_comment:
                        self.state = ParserState.DOC
                        self.indent = None
                        self.lines.append("```\n")
                        self.read_doc_line(line)
                    else:
                        if self.indent == None:
                            self.indent = orig_line[:len(orig_line) -
                                                    len(orig_line.lstrip())]
                            line = orig_line.lstrip()
                            self.lines.append(line)
                        else:
                            if not orig_line.startswith(self.indent):
                                print("%s: error: %s: bad indentation" %
                                      (sys.argv[0], file))
                            else:
                                self.lines.append(orig_line[len(self.indent):])

    doc_items = []
    parser = Parser(doc_items)

    with open(file, errors='replace') as infile:
        parser.parse_file(infile, file)

    return doc_items


def ensure_dir(dir):
    if not os.path.exists(dir):
        try:
            os.makedirs(dir)
        except OSError as exc:  # Guard against race condition
            if exc.errno != errno.EEXIST:
                raise


def render_docs(doc_items: List[dict], outdir: str):
    ensure_dir(outdir)

    with open(os.path.join(outdir, "mkdocs.yml"), 'w') as file:
        file.write(HL_MKDOCS_YAML)

    outdir = os.path.join(outdir, "docs")

    ensure_dir(os.path.join(outdir, "strategy"))
    ensure_dir(os.path.join(outdir, "tactical"))
    ensure_dir(os.path.join(outdir, "misc"))

    with open(os.path.join(outdir, "index.md"), 'w') as file:
        file.write(HL_INDEX_PAGE)

    for item in doc_items:
        if "strategy" in item["tags"] and not "tactical" in item["tags"]:
            folder = "strategy"
        elif "tactical" in item["tags"] and not "strategy" in item["tags"]:
            folder = "tactical"
        else:
            folder = "misc"

        fname = os.path.join(outdir, folder, item["feature"] + ".md")
        with open(fname, 'w') as file:
            print(fname)
            file.write("Title: %s\n\n" % (item["feature"]))
            file.write("# %s\n\n" % (item["feature"]))
            file.write("Tracking Issue: [#%i](%s)\n\n" %
                       (item["issue"], HL_ISSUES_URL % (item["issue"])))
            file.write("Tags: " + ", ".join(item["tags"]) + "\n\n")
            file.write(item["text"])
            file.write("\n\n")
            file.write("## Source code references\n\n")
            for ref in item["links"]:
                urlpath = ref["file"].replace('\\', '/').replace('./', '')
                file_url = HL_SOURCE_URL % (urlpath, ref["span"][0],
                                            ref["span"][1])
                file.write("* [%s:%i-%i](%s)\n" %
                           (os.path.split(ref["file"])[1], ref["span"][0] + 1,
                            ref["span"][1] + 1, file_url))
            file.write("\n")


def merge_doc_refs(doc_items: List[dict]) -> List[dict]:
    items = dict((i["feature"], i) for i in doc_items if not "ref" in i)
    refs = [i for i in doc_items if "ref" in i]

    for ref in refs:
        if ref["ref"] in items:
            items[ref["ref"]]["links"].extend(ref["links"])
            if ref["text"] != "":
                items[ref["ref"]]["text"].extend("\n" + ref["text"])
        else:
            print("%s: error: missing base doc item for ref %s" %
                  (sys.argv[0], ref["ref"]))

    return items.values()


def main():
    indirs, outdir = parse_args()
    doc_items = []
    for docdir in indirs:
        for root, subdirs, files in os.walk(docdir):
            for file in files:
                infile = os.path.join(root, file)
                ext = os.path.splitext(infile)[1]
                known_exts = {".uc": "unrealscript", ".ini": "ini"}
                if ext in known_exts:
                    doc_items.extend(process_file(infile, known_exts[ext]))

    doc_items = merge_doc_refs(doc_items)

    if outdir != None:

        render_docs(doc_items, outdir)


if __name__ == "__main__":
    main()
