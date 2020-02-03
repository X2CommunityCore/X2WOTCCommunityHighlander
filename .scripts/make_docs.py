import argparse
import sys
import os
import shutil

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


def parse_args() -> (List[str], str, str):
    parser = argparse.ArgumentParser(
        description='Generate HL docs from source files.')
    parser.add_argument('indirs',
                        metavar='indir',
                        type=str,
                        nargs='+',
                        help='input file directories')
    parser.add_argument('--outdir', dest='outdir', help='output directories')

    parser.add_argument(
        '--docsdir',
        dest='docsdir',
        help='directory from which to copy index, mkdocs.yml, tag files')

    args = parser.parse_args()

    if os.path.isfile(args.outdir):
        print("%s: error: Output dir %s is existing file" %
              (sys.argv[0], args.outdir))
        sys.exit(1)

    if not os.path.exists(args.docsdir) or os.path.isfile(args.docsdir):
        print("%s: error: Docs src dir %s does not exist or is file" %
              (sys.argv[0], args.outdir))
        sys.exit(1)

    for indir in args.indirs:
        if not os.path.isdir(indir):
            print("%s: error: Input directory %s does not exist or is file" %
                  (sys.argv[0], indir))
            sys.exit(1)

    return args.indirs, args.outdir, args.docsdir


def make_ref(text: str, file: str, span: (int, int),
             issue: Optional[int]) -> dict:
    ref = {"text": text, "file": file, "span": span}
    if issue != None:
        ref["issue"] = issue
    return ref


def make_doc_item(lines: List[str], file: str,
                  span: (int, int)) -> Optional[dict]:
    """
    dict:
        feature: str,
        issue: int?,
        tags: [str],
        texts: [{text: str, file: str, span: (int, int), issue: int?}]
    or
        ref: str,
        text: {text: str, file: str, span: (int, int), issue: int?}
    """
    item = {}
    # first line: meta info
    for pair in lines[0].split(';'):
        k, v = pair.strip().split(':')
        if k in item:
            print("%s: error: %s: dupe key `%s`" % (sys.argv[0], file, k))
        if k == 'feature' or k == 'ref':
            item[k] = v
        elif k == 'issue':
            item[k] = int(v)
        elif k == 'tags':
            item[k] = v.split(',')
        else:
            print("%s: error: %s: unknown key `%s`" % (sys.argv[0], file, k))

    ref = make_ref("\n".join(lines[1:]), file, span, item.get('issue'))
    if "ref" in item:
        item["text"] = ref
    else:
        item["texts"] = []
        item["texts"].append(ref)
    return item


def generate_builtin_features(doc_items):
    bugfix_item = {"feature": HL_FEATURE_FIX, "tags": [], "texts": []}
    doc_items.append(bugfix_item)


def process_file(file, lang) -> List[dict]:
    """
    Process file, extract documentation
    """
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
            # If the file ended with a doc item...
            if self.state == ParserState.DOC:
                item = make_doc_item(self.lines, self.filename,
                                     (startline, lnum))
                if item != None:
                    self.doc_items.append(item)
                else:
                    print("...while processing %s:%i" % (file, lnum))

    doc_items = []

    generate_builtin_features(doc_items)

    parser = Parser(doc_items)
    with open(file, errors='replace') as infile:
        parser.parse_file(infile, file)

    return doc_items


def merge_doc_refs(doc_items: List[dict]) -> List[dict]:
    items = dict((i["feature"], i) for i in doc_items if not "ref" in i)
    refs = [i for i in doc_items if "ref" in i]

    for ref in refs:
        if ref["ref"] in items:
            items[ref["ref"]]["texts"].append(ref["text"])
        else:
            print("%s: error: missing base doc item for ref %s" %
                  (sys.argv[0], ref["ref"]))

    return items.values()


def ensure_dir(dir):
    if not os.path.exists(dir):
        try:
            os.makedirs(dir)
        except OSError as exc:  # Guard against race condition
            if exc.errno != errno.EEXIST:
                raise


def render_bugfix_page(item: dict, outdir: str):
    fname = os.path.join(outdir, item["feature"] + ".md")
    with open(fname, 'w') as file:
        print(fname)

        file.write("Title: %s\n\n" % (item["feature"]))
        file.write("<h1>%s</h1>\n\n" % (item["feature"]))
        file.write(
            "This page accomodates all bug fixes that do not deserve " +
            "their own documentation page, as they are simple enough to " +
            "be entirely explained by a single line.")
        file.write("\n\n")
        refs = sorted(item["texts"], key=lambda r: r["issue"])
        for ref in refs:
            issuepath = HL_ISSUES_URL % (ref["issue"])
            urlpath = ref["file"].replace('\\', '/').replace('./', '')
            file_url = HL_SOURCE_URL % (urlpath, ref["span"][0] + 1,
                                        ref["span"][1])
            file.write("* ")
            file.write("[#%i](%s) - " % (ref["issue"], issuepath))
            file.write("[%s:%i-%i](%s): " % (os.path.split(
                ref["file"])[1], ref["span"][0] + 1, ref["span"][1], file_url))
            file.write(ref["text"])
            file.write("\n")


def render_full_feature_page(item: dict, outdir: str):
    if "strategy" in item["tags"] and not "tactical" in item["tags"]:
        folder = "strategy"
    elif "tactical" in item["tags"] and not "strategy" in item["tags"]:
        folder = "tactical"
    else:
        folder = "misc"

    fname = os.path.join(outdir, folder, item["feature"] + ".md")
    item["__filepath"] = os.path.join(folder, item["feature"] + ".md")
    with open(fname, 'w') as file:
        print(fname)
        file.write("Title: %s\n\n" % (item["feature"]))
        file.write("<h1>%s</h1>\n\n" % (item["feature"]))
        file.write("Tracking Issue: [#%i](%s)\n\n" %
                   (item["issue"], HL_ISSUES_URL % (item["issue"])))
        linked_tags = map(
            lambda t: "[%s](%s)" % (t, os.path.join("..", t + ".md")),
            filter(lambda t: not t in ["strategy", "tactical"], item["tags"]))
        file.write("Tags: " + ", ".join(linked_tags) + "\n\n")
        file.write("\n".join([t["text"] for t in item["texts"]]))
        file.write("\n\n")
        file.write("## Source code references\n\n")
        for ref in item["texts"]:
            urlpath = ref["file"].replace('\\', '/').replace('./', '')
            file_url = HL_SOURCE_URL % (urlpath, ref["span"][0] + 1,
                                        ref["span"][1])
            file.write("* [%s:%i-%i](%s)\n" % (os.path.split(
                ref["file"])[1], ref["span"][0] + 1, ref["span"][1], file_url))


def record_tags(tag_lists: dict, item: dict):
    item_tags = item["tags"]
    if "strategy" in item_tags: item_tags.remove("strategy")
    if "tactical" in item_tags: item_tags.remove("tactical")

    for tag in item_tags:
        if not tag in tag_lists:
            tag_lists[tag] = []
        tag_lists[tag].append(item)


def render_tag_page(tag: str, items: List[dict], outdir: str):
    items = sorted(items, key=lambda i: i["issue"])
    fname = os.path.join(outdir, tag + ".md")

    with open(fname, 'r'):
        pass

    with open(fname, 'a+') as file:
        print(fname)
        for item in items:
            file.write("* [#%i](%s) - " % (item["issue"], HL_ISSUES_URL %
                                           (item["issue"])))
            file.write("[%s](%s)" % (item["feature"], item["__filepath"]))
            file.write("\n")


def render_docs(doc_items: List[dict], outdir: str):
    ensure_dir(outdir)

    outdir = os.path.join(outdir, "docs")

    ensure_dir(os.path.join(outdir, "strategy"))
    ensure_dir(os.path.join(outdir, "tactical"))
    ensure_dir(os.path.join(outdir, "misc"))

    tag_lists = {}

    for item in doc_items:
        if item["feature"] == HL_FEATURE_FIX:
            render_bugfix_page(item, outdir)
        else:
            render_full_feature_page(item, outdir)
            record_tags(tag_lists, item)

    for tag, items in tag_lists.items():
        render_tag_page(tag, items, outdir)


def copytree(src, dst):
    """
    shutil.copytree has the annoying limitation that below python 3.8,
    it will error on existing directories with no way to turn the error off.
    Additionally, we can't delete the directory because mkdocs serve may be
    watching it. This function works around the issue and
    is cribbed from https://stackoverflow.com/a/12514470
    """
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s):
            ensure_dir(d)
            copytree(s, d)
        else:
            shutil.copy2(s, d)


def main():
    indirs, outdir, docsdir = parse_args()
    copytree(docsdir, outdir)
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
