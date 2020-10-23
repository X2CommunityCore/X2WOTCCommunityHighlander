"""Script accompanying .github/workflows/post_patch.yml
   to extract the diff and issue number from a workflow
   that modifies event listener definitions.
"""

import sys
import requests
import zipfile

from io import BytesIO

def handle_art_url(artifact):
    r = requests.get(artifact,
                     headers={'Authorization': 'token ' + sys.argv[2]})
    if r.status_code == 200:
        zip = zipfile.ZipFile(BytesIO(r.content))
        zip.extract('pr_number.txt')
        patch = zip.open('new_contents.diff')
        with open('msg.txt', 'w', encoding = 'utf-8') as f:
            f.write('**Pull request modifies event listener templates**\n\n')
            f.write('<details><summary>Difference (click to expand)</summary>\n\n```diff\n')
            f.write(patch.read().decode('utf-8'))
            f.write('\n```\n</details>\n\n<details><summary>What? (click to expand)</summary>\n\n')
            f.write('The Highlander documentation tool generates event listener examples from event specifications. ')
            f.write('This comment contains the modifications that would be made to event ',)
            f.write('listeners for PR authors and reviewers to inspect for correctness and will ',)
            f.write('automatically be kept up-to-date whenever this PR is updated.</details>\n\n',)
            f.write('<!-- GHA-event-listeners-diff -->',)
        # early exit
        sys.exit(0)


def main():
    url = sys.argv[1]
    r = requests.get(url)
    if r.status_code == 200:
        js = r.json()
        for art in js['artifacts']:
            if art['name'] == 'new_contents.diff':
                handle_art_url(art['archive_download_url'])
    sys.exit(1)


if __name__ == '__main__':
    main()
