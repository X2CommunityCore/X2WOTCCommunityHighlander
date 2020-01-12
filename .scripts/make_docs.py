import argparse
import sys
import os

from typing import List, Optional, Union

HL_DOCS_KEYWORD = "HL-Docs:"
HL_BRANCH = "beta"
HL_ISSUES_URL = "https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/%i"
HL_SOURCE_URL = "https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/%s/%s#L%s-L%s" % (HL_BRANCH, "%s", "%i", "%i")
HL_DOCS_INTRO = """# X2WOTCCommunityHighlander Documentation

Welcome to the [X2WOTCCommunityHighlander](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/) documentation.

## Documentation Items

"""

def parse_args() -> (List[str], Optional[str]):
    parser = argparse.ArgumentParser(description='Generate HL docs from source files.')
    parser.add_argument('indirs', metavar='indir', type=str, nargs='+',
                    help='input file directories')
    parser.add_argument('--outfile', dest='outfile',
                    help='output file (default: None, check only)')

    args = parser.parse_args()

    if args.outfile != None and os.path.isdir(args.outfile):
        print("%s: error: Output file %s is existing directory" % (sys.argv[0], args.outfile))
        sys.exit(1)

    for indir in args.indirs:
        if not os.path.isdir(indir):
            print("%s: error: Input directory %s does not exist or is file" % (sys.argv[0], indir))
            sys.exit(1)

    return args.indirs, args.outfile

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
    links: [{file: str, span: (int, int)}]
"""
def make_doc_item(lines: List[str], file: str, span: (int, int)) -> Optional[dict]:
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
def process_file(file) -> List[dict]:
    lines = []
    doc_items = []
    startline = -1

    with open(file) as infile:
        for num, line in enumerate(infile):
            line = line.strip()
            if len(line) >=3 and line[0:3] == '///' or line[0:3] == ";;;":
                line = line[3:]
                if line.startswith(' '):
                    line = line[1:]
                if line.startswith(HL_DOCS_KEYWORD):
                    if len(lines) != 0:
                        print("%s: error: %s: multiple `%s` in one item" % (sys.argv[0], file, HL_DOCS_KEYWORD))
                    lines.append(line[(len(HL_DOCS_KEYWORD) + 1):])
                    startline = num
                elif len(lines) > 0:
                    lines.append(line)
            elif len(lines) > 0:
                item = make_doc_item(lines, file, (startline, num))
                if item != None:
                    doc_items.append(item)
                else:
                    print("...while processing %s:%i" % (file, num))
                lines = []
    return doc_items    

def render_file(doc_items: List[dict], outfile: str):
    with open(outfile, 'w') as file:
        file.write(HL_DOCS_INTRO)
        for item in doc_items:
            file.write("### %s ([#%i](%s))\n\n"
                        % ( item["feature"],
                            item["issue"], HL_ISSUES_URL % (item["issue"])))
            file.write("Tags: " + ", ".join(item["tags"]) + "\n\n")
            file.write(item["text"])
            file.write("\n\n")
            file.write("#### Source code references\n\n")
            for ref in item["links"]:
                urlpath = ref["file"].replace('\\', '/').replace('./', '')
                file_url = HL_SOURCE_URL % (urlpath, ref["span"][0], ref["span"][1])
                file.write("* [%s:%i-%i](%s)\n" % (os.path.split(ref["file"])[1], ref["span"][0], ref["span"][1], file_url))
            file.write("\n")

def merge_doc_refs(doc_items: List[dict]) -> List[dict]:
    items = dict((i["feature"], i) for i in doc_items if not "ref" in i)
    refs = [i for i in doc_items if "ref" in i]

    for ref in refs:
        if ref["ref"] in items:
            items[ref["ref"]]["links"].extend(ref["links"])
        else:
            print("%s: error: missing base doc item for ref %s" % (sys.argv[0], ref["ref"]))

    return items.values()


def main():
    indirs, outfile = parse_args()
    doc_items = []
    for docdir in indirs:
        for root, subdirs, files in os.walk(docdir):
            for file in files:
                infile = os.path.join(root, file)
                ext = os.path.splitext(infile)[1]
                if ext == '.uc' or ext == '.ini':
                    doc_items.extend(process_file(infile))

    doc_items = merge_doc_refs(doc_items)

    if outfile != None:
        render_file(doc_items, outfile)

if __name__ == "__main__":
    main()