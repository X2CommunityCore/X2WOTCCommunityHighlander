"""Script accompanying .github/workflows/post_patch.yml
   to extract the diff and issue number from a workflow
   that modifies event listener definitions.
"""

import sys
import requests
import zipfile

from io import BytesIO

COMMENT_PRE = """**Pull request modifies event listener templates**

<details><summary>Difference (click to expand)</summary>

```diff
"""

COMMENT_POST = """
```
</details>

<details><summary>What? (click to expand)</summary>

The Highlander documentation tool generates event listener examples from event specifications.
This comment contains the modifications that would be made to event \
listeners for PR authors and reviewers to inspect for correctness and will \
automatically be kept up-to-date whenever this PR is updated.</details>

<!-- GHA-event-listeners-diff -->"""


def handle_art_url(artifact):
    r = requests.get(artifact,
                     headers={'Authorization': 'token ' + sys.argv[2]})
    if r.status_code == 200:
        zip = zipfile.ZipFile(BytesIO(r.content))
        zip.extract('pr_number.txt')
        patch = zip.open('new_contents.diff')
        with open('msg.txt', 'w', encoding='utf-8') as f:
            f.write(COMMENT_PRE)
            f.write(patch.read().decode('utf-8'))
            f.write(COMMENT_POST)
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
