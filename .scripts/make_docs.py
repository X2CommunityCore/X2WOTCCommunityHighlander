import argparse
import errno
from itertools import chain
import sys
import os
import shutil

from collections import OrderedDict
from enum import Enum
from typing import List, Optional, Tuple

from make_docs import event_tuples

HL_DOCS_KEYWORD = "HL-Docs:"
HL_INCLUDE_FOLLOWING = "HL-Include:"
# "Bugfixes" is a feature owned by the documentation script.
# It does not need an owning feature declaration in the code,
# and exclusively consists of `HL-Docs: ref:Bugfixes` lines.
HL_FEATURE_FIX = "Bugfixes"
HL_BRANCH = "master"
HL_REPO = "https://github.com/X2CommunityCore/X2WOTCCommunityHighlander"


class Session:
    def __init__(self):
        self.exit_code = 0
        self.doc_items = []
        self.templates = {}
        self.documented_issues = []

    def err(self, msg: str):
        print(f"error: {msg}")
        self.exit_code = 1

    def fatal(self, msg: str):
        print(f"fatal error: {msg}")
        sys.exit(1)


def parse_args(sess) -> Tuple[List[str], str, str, str, bool]:
    parser = argparse.ArgumentParser(
        description='Generate HL docs from source files.')
    parser.add_argument('indirs',
                        metavar='indir',
                        type=str,
                        nargs='*',
                        help='input file directories')
    parser.add_argument('--outdir', dest='outdir', help='output directories')

    parser.add_argument(
        '--docsdir',
        dest='docsdir',
        help='directory from which to copy index, mkdocs.yml, tag files')

    parser.add_argument(
        '--dumpelt',
        dest='dump_elt',
        help='target compile test file for event listener templates')

    parser.add_argument(
        '--indirsfile',
        dest='indirsfile',
        help='text file of newline-separated directories for which to generate documentation')

    parser.add_argument(
        '--printissues',
        dest='print_issues',
        action='store_true',
        help='print all documented issue numbers')

    args = parser.parse_args()

    if args.outdir and os.path.isfile(args.outdir):
        sess.fatal(f"Output dir {args.outdir} is existing file")

    if not os.path.exists(args.docsdir) or os.path.isfile(args.docsdir):
        sess.fatal(f"Docs src dir {args.outdir} does not exist or is file")

    parsed_indirs = []
    if args.indirsfile:
        if not os.path.isfile(args.indirsfile):
            sess.fatal(f"Docs input directory list file {args.indirsfile} does not exist or isn't file")
        with open(args.indirsfile, 'r') as f:
            parsed_indirs = filter(None, [l.strip() for l in f if not l.strip().startswith('#')])

    indirs = []
    for indir in chain(args.indirs, parsed_indirs):
        if not os.path.isdir(indir):
            sess.fatal(f"Input directory {indir} does not exist or is file")
        indirs.append(indir)

    if len(indirs) == 0:
        sess.fatal(f"No input directories specified")

    return indirs, args.outdir, args.docsdir, args.dump_elt, args.print_issues


def link_to_source(ref) -> str:
    start = ref.span[0] + 1
    end = ref.span[1]
    urlpath = ref.file.replace('\\', '/').replace('./', '')
    file = os.path.split(ref.file)[1]

    if start == end:
        text = f"{file}:{start}"
        line_anchor = f"#L{start}"
    else:
        text = f"{file}:{start}-{end}"
        line_anchor = f"#L{start}-L{end}"
    return f"[{text}]({HL_REPO}/blob/{HL_BRANCH}/{urlpath}{line_anchor})"


def link_to_issue(iss: int) -> str:
    return f"[#{iss}]({HL_REPO}/issues/{iss})"


class DocItem:
    def __init__(self, d):
        self.__dict__ = d

    def is_feat(self) -> bool:
        return hasattr(self, 'feature')


class Ref:
    def __init__(self, text, file, span, issue):
        self.text = text
        self.file = file
        self.span = span
        self.issue = issue


def make_doc_item(sess, lines: List[str], file: str, span: Tuple[int, int],
                  events: bool) -> Optional[DocItem]:
    """
    DocItem:
        feature: str,
        issue: int?,
        tags: [str],
        texts: [{text: str, file: str, span: (int, int), issue: int?}]
    or Ref:
        ref: str,
        tags: [str],
        text: {text: str, file: str, span: (int, int), issue: int?}
    """
    item = {}
    # first line: meta info
    for pair in lines[0].split(';'):
        k, v = pair.strip().split(':')
        if k in item:
            sess.err(f"{file}:{span[0]+1}: duplicate key `{k}`")
        if k == "feature" or k == "ref":
            item[k] = v
        elif k == "issue":
            item[k] = int(v)
        elif k == "tags":
            tags = v.split(',')
            item[k] = tags if tags != [''] else []
        else:
            sess.err(f"{file}:{span[0]+1}: unknown key `{k}`")

    # Check some things
    if not ("feature" in item or "ref" in item):
        sess.err(f"{file}:{span[0]+1}: missing key `feature` or `ref`")
        return None
    if not "issue" in item and ("feature" in item
                                or item.get("ref") == HL_FEATURE_FIX):
        sess.err(f"{file}:{span[0]+1}: missing key `issue`")
        item["issue"] = 99999
    if "tags" in item and "ref" in item:
        sess.err(f"{file}:{span[0]+1}: `ref` incompatible with `tags`")
        print("note: specify tags in the feature declaration")
        item.pop("tags")
    if not "tags" in item and "feature" in item:
        sess.err(f"{file}:{span[0]+1}: missing key `tags`")
        print("note: use `tags:` to specify an empty tag list")
        item["tags"] = []

    if events:
        if "tags" not in item:
            item["tags"] = []
        item["tags"].append("events")

    ref = Ref("\n".join(lines[1:]), file, span, item.get("issue"))
    if "ref" in item:
        item["text"] = ref
        if item["ref"] != HL_FEATURE_FIX and ref.issue is not None:
            sess.err(f"{file}:{span[0]+1}: invalid `issue` metadata in `ref`")
            print(f"note: only `{HL_FEATURE_FIX}` refs have their own issues")
            print(f"note: other refs inherit issue from their owning feature definition")
    else:
        item["texts"] = []
        item["texts"].append(ref)

    return DocItem(item)


def generate_builtin_features(sess):
    bugfix_item = DocItem({
        "feature": HL_FEATURE_FIX,
        "tags": [],
        "texts": [],
        "issue": None
    })
    sess.doc_items.append(bugfix_item)


def make_event_spec_table(sess, spec: dict) -> str:
    event_id = spec.id
    data_type = spec.data.type
    source_type = spec.source.type

    newgamestate = spec.newgs

    buf = "| Param | Value |\n"
    buf += "| - | - |\n"
    buf += f"| EventID | {event_id} |\n"
    buf += f"| EventData | {data_type} |\n"
    buf += f"| EventSource | {source_type} |\n"
    buf += f"| NewGameState | {str(newgamestate)} |\n"

    def hacky_escape(s: str) -> str:
        return s.replace("<", "&lt;").replace(">", "&gt;")

    tup = spec.data.tuple if spec.data.type == "XComLWTuple" else None
    if tup:
        buf += "\n### Tuple contents\n\n"
        buf += "| Index | Name | Type | Direction|\n"
        buf += "| - | - | - | - |\n"
        for idx, (inoutness, tup_type, name, local_type) in enumerate(tup):
            ty_desc = f"{tup_type}"
            if local_type:
                ty_desc += f" ({local_type})"
            ty_desc = hacky_escape(ty_desc)
            buf += f"| {idx} | {name} | {ty_desc} | {str(inoutness)} |\n"

    return buf


TYPE_TO_STRUCT_PROP = {
    "bool": "b",
    "int": "i",
    "enum": "i",
    "float": "f",
    "string": "s",
    "name": "n",
    "vector": "v",
    "rotator": "r",
    "ttile": "t",
    "class": "o",
    "array<int>": "ai",
    "array<float>": "af",
    "array<string>": "as",
    "array<name>": "an",
    "array<vector>": "av",
    "array<rotator>": "ar",
    "array<ttile>": "at",
}


def make_listener_template(sess, spec: dict) -> str:

    funcsig = f"static function EventListenerReturn On{spec.id}"
    funcsig += "(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)\n{"
    locals = ""
    casts = ""
    unwraps = ""
    your_code_here = "\t// Your code here\n"
    rewraps = ""
    footer = "\treturn ELR_NoInterrupt;\n}"

    src = spec.source
    data = spec.data

    if src.type.lower() != "none" and src.name:
        locals += f"\tlocal {src.type} {src.name};\n"
        casts += f"\t{src.name} = {src.type}(EventSource);\n"

    if data.type.lower() != "none" and data.name:
        locals += f"\tlocal {data.type} {data.name};\n"
        casts += f"\t{data.name} = {data.type}(EventData);\n"
    elif data.type == "XComLWTuple":
        locals += f"\tlocal XComLWTuple Tuple;\n"
        casts += f"\tTuple = XComLWTuple(EventData);\n"

        for idx, (inoutness, tup_type, name,
                  local_type) in enumerate(data.tuple):
            tup_prop = TYPE_TO_STRUCT_PROP.get(tup_type.lower())
            locals += f"\tlocal {local_type or tup_type} {name};\n"
            if inoutness.is_in():
                if tup_prop:
                    if local_type:
                        unwraps += f"\t{name} = {local_type}(Tuple.Data[{idx}].{tup_prop});\n"
                    else:
                        unwraps += f"\t{name} = Tuple.Data[{idx}].{tup_prop};\n"
                else:
                    unwraps += f"\t{name} = {tup_type}(Tuple.Data[{idx}].o);\n"

            if inoutness.is_out():
                if tup_prop:
                    rewraps += f"\tTuple.Data[{idx}].{tup_prop} = {name};\n"
                else:
                    rewraps += f"\tTuple.Data[{idx}].o = {name};\n"

    seq = [funcsig, locals, casts, unwraps, your_code_here, rewraps, footer]
    template = "\n".join(filter(None, seq))

    sess.templates[spec.id] = template
    return template


def process_file(sess, file, lang) -> List[dict]:
    """
    Process file, extract documentation
    """
    class ParserState(Enum):
        TEXT = 1
        DOC = 2
        INCLUDE = 3
        EVENT = 4

    class Parser:
        def __init__(self, sess):
            self.sess = sess

        def reset(self, filename):
            self.lines = []
            self.indent = None
            self.state = ParserState.TEXT
            self.filename = filename
            self.events = False
            self.maketemplate = False

        def read_doc_line(self, line, lnum):
            if line.startswith(HL_DOCS_KEYWORD):
                sess.err(
                    f"{self.filename}:{lnum+1}: multiple `{HL_DOCS_KEYWORD}` in one item"
                )
            elif line.startswith(HL_INCLUDE_FOLLOWING):
                self.lines.append(f"\n```{lang}")
                self.state = ParserState.INCLUDE
            elif line.startswith("```event"):
                self.maketemplate = "notemplate" not in line
                self.state = ParserState.EVENT
                self.eventstart = lnum
                self.eventlines = []
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
                        item = make_doc_item(sess, self.lines, self.filename,
                                             (startline, lnum), self.events)
                        if item != None:
                            sess.doc_items.append(item)
                        self.events = False
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
                                sess.err(
                                    f"{self.filename}:{lnum+1}: bad indentation for {HL_INCLUDE_FOLLOWING}"
                                )
                            else:
                                self.lines.append(orig_line[len(self.indent):])
                elif self.state == ParserState.EVENT:
                    if line.startswith("```"):
                        try:
                            spec = event_tuples.parse_event_spec("\n".join(
                                self.eventlines))
                            self.lines.append(f"## {spec.id} event")
                            self.lines.append("")
                            self.lines.append(make_event_spec_table(
                                sess, spec))
                            if self.maketemplate:
                                self.lines.append("\n### Listener template\n")
                                self.lines.append("```unrealscript")
                                self.lines.append(
                                    make_listener_template(sess, spec))
                                self.lines.append("```")
                        except event_tuples.ParseError as pe:
                            sess.err(
                                f"{self.filename}:{self.eventstart+1}: event block has error: {pe.msg}"
                            )

                        self.events = True
                        self.state = ParserState.DOC
                    else:
                        self.eventlines.append(line)
            # If the file ended with a doc item...
            if self.state == ParserState.DOC:
                item = make_doc_item(sess, self.lines, self.filename,
                                     (startline, lnum), self.events)
                if item != None:
                    sess.doc_items.append(item)
                self.events = False
            if self.state == ParserState.INCLUDE:
                sess.err(
                    f"{self.filename}:{startline+1}: unclosed {HL_INCLUDE_FOLLOWING}"
                )

    parser = Parser(sess)
    with open(file, errors='replace') as infile:
        parser.parse_file(infile, file)


def partition_items(sess) -> int:
    """
    Partition the array and check for duplicates, returning the start index
    of the refs (where features end)
    """
    def cmp_doc_item(doc_item) -> Tuple[bool, str]:
        return (not doc_item.is_feat(),
                doc_item.feature if doc_item.is_feat() else doc_item.ref)

    sess.doc_items.sort(key=lambda i: cmp_doc_item(i))

    first_def = None
    seen = False
    for idx, it in enumerate(sess.doc_items):
        if not it.is_feat():
            break

        def make_loc(it) -> str:
            if it.texts:
                file = it.texts[0].file
                line = it.texts[0].span[0] + 1
                return f"at {file}:{line}"
            else:
                return "due to builtin feature"

        curr_feat = it.feature
        if first_def != None and curr_feat == first_def.feature:
            # Report duplicate feature definition
            if not seen:
                sess.err(f"duplicate feature definition `{curr_feat}`")
                print(f"note: first definition {make_loc(first_def)}")
                seen = True
            print(f"note: this definition {make_loc(it)}")

        else:
            first_def = it
            seen = False

    return idx


def merge_doc_refs(sess, refs_start: int):
    items = dict((i.feature, i) for i in sess.doc_items[:refs_start])
    refs = sess.doc_items[refs_start:]

    # sort refs for predictable order (by file name, then by line)
    def cmp_ref(ref) -> Tuple[str, int]:
        return (ref.text.file, ref.text.span[0])

    refs.sort(key=lambda r: cmp_ref(r))

    for ref in refs:
        ref_name = ref.ref
        if ref_name in items:
            items[ref_name].texts.append(ref.text)
        else:
            sess.err(f"missing base doc item for ref `{ref_name}`")

    sess.doc_items = list(items.values())


def ensure_dir(dir):
    if not os.path.exists(dir):
        try:
            os.makedirs(dir)
        except OSError as exc:  # Guard against race condition
            if exc.errno != errno.EEXIST:
                raise


def render_bugfix_page(sess, item, outdir: str):
    feat_name = item.feature
    fname = os.path.join(outdir, feat_name + ".md")
    with open(fname, 'w') as file:
        print(f"ok: {fname}")

        file.write(f"Title: {feat_name}\n\n")
        file.write(f"# {feat_name}\n\n")
        file.write(
            "This page accomodates all bug fixes that do not deserve " +
            "their own documentation page, as they are simple enough to " +
            "be entirely explained by a single line.")
        file.write("\n\n")
        refs = sorted(item.texts, key=lambda r: r.issue)
        for ref in refs:
            sess.documented_issues.append(ref.issue)
            file.write(
                f"* {link_to_issue(ref.issue)} - {link_to_source(ref)}: ")
            file.write(ref.text)
            file.write("\n")


def render_full_feature_page(sess, item, outdir: str):

    if "strategy" in item.tags and not "tactical" in item.tags:
        folder = "strategy"
    elif "tactical" in item.tags and not "strategy" in item.tags:
        folder = "tactical"
    else:
        folder = "misc"

    fname = os.path.join(outdir, folder, item.feature + ".md")
    # Always a relative path, so backslash with os.path.join not necessary on Windows
    item.__filepath = folder + "/" + item.feature + ".md"
    with open(fname, 'w') as file:
        print(f"ok: {fname}")
        sess.documented_issues.append(item.issue)
        file.write(f"Title: {item.feature}\n\n")
        file.write(f"# {item.feature}\n\n")
        file.write(f"Tracking Issue: {link_to_issue(item.issue)}\n\n")

        def link_tag(tag: str) -> str:
            # Always a relative path, so backslash with os.path.join not necessary on Windows
            path = "../" + tag + ".md"
            return f"[{tag}]({path})"

        linked_tags = list(
            map(link_tag,
                filter(lambda t: not t in ["strategy", "tactical"],
                       item.tags)))
        if len(linked_tags) > 0:
            file.write("Tags: " + ", ".join(linked_tags) + "\n\n")
        file.write("\n".join([t.text for t in item.texts]))
        file.write("\n\n")
        file.write("## Source code references\n\n")
        for ref in item.texts:
            file.write(f"* {link_to_source(ref)}\n")


def record_tags(tag_lists: dict, item):
    if "strategy" in item.tags: item.tags.remove("strategy")
    if "tactical" in item.tags: item.tags.remove("tactical")

    for tag in item.tags:
        if not tag in tag_lists:
            tag_lists[tag] = []
        tag_lists[tag].append(item)


def render_tag_page(sess, tag: str, items: List[dict], outdir: str):
    items = sorted(items, key=lambda i: i.issue)
    fname = os.path.join(outdir, tag + ".md")

    try:
        with open(fname, 'r'):
            pass
    except FileNotFoundError:
        sess.err(f"file {fname} not found (`{tag}` is an unknown tag)")
        referrers = ", ".join(map(lambda i: "`" + i.feature + "`", items))
        print(f"note: referred to by {referrers}")
        return

    with open(fname, 'a+') as file:
        print(f"ok: {fname}")
        for item in items:
            file.write(f"* {link_to_issue(item.issue)} - ")
            file.write(f"[{item.feature}]({item.__filepath})")
            file.write("\n")


def render_docs(sess, outdir: str):
    ensure_dir(outdir)

    outdir = os.path.join(outdir, "docs")

    ensure_dir(os.path.join(outdir, "strategy"))
    ensure_dir(os.path.join(outdir, "tactical"))
    ensure_dir(os.path.join(outdir, "misc"))

    tag_lists = {}

    for item in sess.doc_items:
        if item.feature == HL_FEATURE_FIX:
            render_bugfix_page(sess, item, outdir)
        else:
            render_full_feature_page(sess, item, outdir)
            record_tags(tag_lists, item)

    for tag, items in tag_lists.items():
        render_tag_page(sess, tag, items, outdir)


def dump_templates(sess, dump_elt):
    with open(dump_elt, 'w') as file:
        clname = os.path.splitext(os.path.basename(dump_elt))[0]
        file.write(
            f"""// Do not manually edit! This class is automatically generated by `make_docs.py`.
// It tests that the event listener templates generated by the docs script actually compile.
// Run the `makeDocs` task (or run the script manually) to refresh.
class {clname} extends Object;\n\n""")

        for evt, tmp in sorted(sess.templates.items()):
            file.write(tmp)
            file.write("\n\n")


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
    sess = Session()

    indirs, outdir, docsdir, dump_elt, print_issues = parse_args(sess)

    generate_builtin_features(sess)

    for docdir in indirs:
        for root, subdirs, files in os.walk(docdir):
            for file in files:
                infile = os.path.join(root, file)
                ext = os.path.splitext(infile)[1]
                known_exts = {".uc": "unrealscript", ".ini": "ini"}
                if ext in known_exts:
                    process_file(sess, infile, known_exts[ext])

    refs_start = partition_items(sess)
    merge_doc_refs(sess, refs_start)

    if outdir is not None:
        copytree(docsdir, outdir)
        render_docs(sess, outdir)

    if dump_elt is not None:
        dump_templates(sess, dump_elt)

    if print_issues:
        for issue in sorted(sess.documented_issues):
            print(issue)

    if sess.exit_code != 0:
        print("note: the docs script found documentation errors")
        print(
            "note: see https://x2communitycore.github.io/X2WOTCCommunityHighlander/#documentation-for-the-documentation-tool for documentation on the docs script"
        )
    sys.exit(sess.exit_code)


if __name__ == "__main__":
    main()
