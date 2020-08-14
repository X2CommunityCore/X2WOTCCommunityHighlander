import argparse
import sys
import os
import shutil

from enum import Enum
from typing import List, Optional, Iterable

HL_DOCS_KEYWORD = "HL-Docs:"
HL_INCLUDE_FOLLOWING = "HL-Include:"
# "Bugfixes" is a feature owned by the documentation script.
# It does not need an owning feature declaration in the code,
# and exclusively consists of `HL-Docs: ref:Bugfixes` lines.
HL_FEATURE_FIX = "Bugfixes"
HL_BRANCH = "master"
HL_REPO = "https://github.com/X2CommunityCore/X2WOTCCommunityHighlander"

exit_code = 0


def err(msg: str):
    global exit_code
    print(f"error: {msg}")
    exit_code = 1


def fatal(msg: str):
    print(f"fatal error: {msg}")
    sys.exit(1)


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
        fatal(f"Output dir {args.outdir} is existing file")

    if not os.path.exists(args.docsdir) or os.path.isfile(args.docsdir):
        fatal(f"Docs src dir {args.outdir} does not exist or is file")

    for indir in args.indirs:
        if not os.path.isdir(indir):
            fatal(f"Input directory {indir} does not exist or is file")

    return args.indirs, args.outdir, args.docsdir


def link_to_source(ref: dict) -> str:
    start = ref["span"][0] + 1
    end = ref["span"][1]
    urlpath = ref["file"].replace('\\', '/').replace('./', '')
    file = os.path.split(ref["file"])[1]

    if start == end:
        text = f"{file}:{start}"
        line_anchor = f"#L{start}"
    else:
        text = f"{file}:{start}-{end}"
        line_anchor = f"#L{start}-L{end}"
    return f"[{text}]({HL_REPO}/blob/{HL_BRANCH}/{urlpath}{line_anchor})"


def link_to_issue(iss: int) -> str:
    return f"[#{iss}]({HL_REPO}/issues/{iss})"


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
            err(f"{file}:{span[0]+1}: duplicate key `{k}`")
        if k == "feature" or k == "ref":
            item[k] = v
        elif k == "issue":
            item[k] = int(v)
        elif k == "tags":
            tags = v.split(',')
            item[k] = tags if tags != [''] else []
        else:
            err(f"{file}:{span[0]+1}: unknown key `{k}`")

    # Check some things
    if not ("feature" in item or "ref" in item):
        err(f"{file}:{span[0]+1}: missing key `feature` or `ref`")
        return None
    if not "issue" in item and ("feature" in item
                                or item.get("ref") == HL_FEATURE_FIX):
        err(f"{file}:{span[0]+1}: missing key `issue`")
        item["issue"] = 99999
    if not "tags" in item and "feature" in item:
        err(f"{file}:{span[0]+1}: missing key `tags`")
        print("note: use `tags:` to specify an empty tag list")
        item["tags"] = []

    ref = make_ref("\n".join(lines[1:]), file, span, item.get("issue"))
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
            self.indent = None
            self.state = ParserState.TEXT
            self.filename = filename

        def read_doc_line(self, line, lnum):
            if line.startswith(HL_DOCS_KEYWORD):
                err(f"{self.filename}:{lnum+1}: multiple `{HL_DOCS_KEYWORD}` in one item"
                    )
            elif line.startswith(HL_INCLUDE_FOLLOWING):
                self.lines.append(f"\n```{lang}")
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
                if line.startswith(' ') or line.startswith('\t'):
                    line = line[1:]

                if self.state == ParserState.TEXT:
                    if is_doc_comment and line.startswith(HL_DOCS_KEYWORD):
                        startline = lnum
                        self.lines.append(line[len(HL_DOCS_KEYWORD) + 1:])
                        self.state = ParserState.DOC
                elif self.state == ParserState.DOC:
                    if is_doc_comment:
                        self.read_doc_line(line, lnum)
                    else:
                        item = make_doc_item(self.lines, self.filename,
                                             (startline, lnum))
                        if item != None:
                            self.doc_items.append(item)

                        self.state = ParserState.TEXT
                        self.lines = []
                elif self.state == ParserState.INCLUDE:
                    if is_doc_comment:
                        self.state = ParserState.DOC
                        self.indent = None
                        self.lines.append("```\n")
                        self.read_doc_line(line, lnum)
                    else:
                        if self.indent == None:
                            self.indent = orig_line[:len(orig_line) -
                                                    len(orig_line.lstrip())]
                            line = orig_line.lstrip()
                            self.lines.append(line)
                        else:
                            if not orig_line.startswith(self.indent):
                                err(f"{self.filename}:{lnum+1}: bad indentation for {HL_INCLUDE_FOLLOWING}"
                                    )
                            else:
                                self.lines.append(orig_line[len(self.indent):])
            # If the file ended with a doc item...
            if self.state == ParserState.DOC:
                item = make_doc_item(self.lines, self.filename,
                                     (startline, lnum))
                if item != None:
                    self.doc_items.append(item)
            if self.state == ParserState.INCLUDE:
                err(f"{self.filename}:{startline+1}: unclosed {HL_INCLUDE_FOLLOWING}"
                    )

    doc_items = []

    parser = Parser(doc_items)
    with open(file, errors='replace') as infile:
        parser.parse_file(infile, file)

    return doc_items


def partition_items(doc_items: List[dict]) -> int:
    """
    Partition the array and check for duplicates, returning the start index
    of the refs (where features end)
    """
    def cmp_doc_item(doc_item: dict) -> (bool, str):
        is_feat = "feature" in doc_item
        return (not is_feat,
                doc_item["feature"] if is_feat else doc_item["ref"])

    doc_items.sort(key=lambda i: cmp_doc_item(i))

    first_def = None
    seen = False
    for idx, it in enumerate(doc_items):
        if not "feature" in it:
            break

        def make_loc(it: dict) -> str:
            if "texts" in it and len(it["texts"]) > 0:
                file = it["texts"][0]["file"]
                line = it["texts"][0]["span"][0] + 1
                return f"at {file}:{line}"
            else:
                return "due to builtin feature"

        curr_feat = it["feature"]
        if first_def != None and curr_feat == first_def["feature"]:
            # Report duplicate feature definition
            if not seen:
                err(f"duplicate feature definition `{curr_feat}`")
                print(f"note: first definition {make_loc(first_def)}")
                seen = True
            print(f"note: this definition {make_loc(it)}")

        else:
            first_def = it
            seen = False

    return idx


def merge_doc_refs(doc_items: List[dict], refs_start: int) -> Iterable[dict]:
    items = dict((i["feature"], i) for i in doc_items[:refs_start])
    refs = doc_items[refs_start:]

    # sort refs for predictable order (by file name, then by line)
    def cmp_ref(ref: dict) -> (str, int):
        return (ref["text"]["file"], ref["text"]["span"][0])

    refs.sort(key=lambda r: cmp_ref(r))

    for ref in refs:
        ref_name = ref["ref"]
        if ref_name in items:
            items[ref_name]["texts"].append(ref["text"])
        else:
            err(f"missing base doc item for ref `{ref_name}`")

    return items.values()


def ensure_dir(dir):
    if not os.path.exists(dir):
        try:
            os.makedirs(dir)
        except OSError as exc:  # Guard against race condition
            if exc.errno != errno.EEXIST:
                raise


def render_bugfix_page(item: dict, outdir: str):
    feat_name = item["feature"]
    fname = os.path.join(outdir, feat_name + ".md")
    with open(fname, 'w') as file:
        print(f"ok: {fname}")

        file.write(f"Title: {feat_name}\n\n")
        file.write(f"<h1>{feat_name}</h1>\n\n")
        file.write(
            "This page accomodates all bug fixes that do not deserve " +
            "their own documentation page, as they are simple enough to " +
            "be entirely explained by a single line.")
        file.write("\n\n")
        refs = sorted(item["texts"], key=lambda r: r["issue"])
        for ref in refs:
            issue = ref["issue"]
            file.write(f"* {link_to_issue(issue)} - {link_to_source(ref)}: ")
            file.write(ref["text"])
            file.write("\n")


def render_full_feature_page(item: dict, outdir: str):
    feat_name = item["feature"]

    if "strategy" in item["tags"] and not "tactical" in item["tags"]:
        folder = "strategy"
    elif "tactical" in item["tags"] and not "strategy" in item["tags"]:
        folder = "tactical"
    else:
        folder = "misc"

    fname = os.path.join(outdir, folder, feat_name + ".md")
    # Always a relative path, so backslash with os.path.join not necessary on Windows
    item["__filepath"] = folder + "/" + feat_name + ".md"
    with open(fname, 'w') as file:
        print(f"ok: {fname}")
        file.write(f"Title: {feat_name}\n\n")
        file.write(f"<h1>{feat_name}</h1>\n\n")
        issue = item["issue"]
        file.write(f"Tracking Issue: {link_to_issue(issue)}\n\n")

        def link_tag(tag: str) -> str:
            # Always a relative path, so backslash with os.path.join not necessary on Windows
            path = "../" + tag + ".md"
            return f"[{tag}]({path})"

        linked_tags = list(
            map(
                link_tag,
                filter(lambda t: not t in ["strategy", "tactical"],
                       item["tags"])))
        if len(linked_tags) > 0:
            file.write("Tags: " + ", ".join(linked_tags) + "\n\n")
        file.write("\n".join([t["text"] for t in item["texts"]]))
        file.write("\n\n")
        file.write("## Source code references\n\n")
        for ref in item["texts"]:
            file.write(f"* {link_to_source(ref)}\n")


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

    try:
        with open(fname, 'r'):
            pass
    except FileNotFoundError:
        err(f"file {fname} not found (`{tag}` is an unknown tag)")
        referrers = ", ".join(map(lambda i: "`" + i["feature"] + "`", items))
        print(f"note: referred to by {referrers}")
        return

    with open(fname, 'a+') as file:
        print(f"ok: {fname}")
        for item in items:
            issue = item["issue"]
            feat_name = item["feature"]
            path = item["__filepath"]
            file.write(f"* {link_to_issue(issue)} - ")
            file.write(f"[{feat_name}]({path})")
            file.write("\n")


def render_docs(doc_items: Iterable[dict], outdir: str):
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
    ensure_dir(dst)
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s):
            copytree(s, d)
        else:
            shutil.copy2(s, d)


def main():
    global exit_code
    indirs, outdir, docsdir = parse_args()
    copytree(docsdir, outdir)

    doc_items = []
    generate_builtin_features(doc_items)

    for docdir in indirs:
        for root, subdirs, files in os.walk(docdir):
            for file in files:
                infile = os.path.join(root, file)
                ext = os.path.splitext(infile)[1]
                known_exts = {".uc": "unrealscript", ".ini": "ini"}
                if ext in known_exts:
                    doc_items.extend(process_file(infile, known_exts[ext]))

    refs_start = partition_items(doc_items)
    doc_items = merge_doc_refs(doc_items, refs_start)

    if outdir != None:
        render_docs(doc_items, outdir)

    if exit_code != 0:
        print("note: the docs script found documentation errors")
        print(
            "note: see https://x2communitycore.github.io/X2WOTCCommunityHighlander/#documentation-for-the-documentation-tool for documentation on the docs script"
        )
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
