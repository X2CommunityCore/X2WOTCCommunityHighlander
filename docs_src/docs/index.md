# X2WOTCCommunityHighlander Documentation

## Current status of the Documentation

The documentation is freshly introduced. It will take us a while
to document all old features, but it is expected that new features all come
with their documentation page.

## How to read

The nav bar has a list of features. Click on a feature to view that feature's
documentation. Every feature has:

* A GitHub tracking issue for discussion
* A documented way to use it, for example with an [event tuple](events.md)
* Code references that link to HL source code where the documentation is

## Documentation for the documentation tool

We place our documentation inside of the source code next to where the main change
for the given feature is. `make_docs.py` extracts this documentation and renders
MarkDown pages, which `MkDocs` in turn renders to a web page.

You can run the documentation tool locally by installing Python (recommended version 3.7)
and running

    python .\\.scripts\\make_docs.py .\\X2WOTCCommunityHighlander\\Src\\ .\\X2WOTCCommunityHighlander\\Config\\ --outdir .\\target\\ --docsdir .\\docs_src\\

or the `makeDocs` task in VS Code. This creates Markdown files for the documentation; rendering HTML documentation requires
`MkDocs`:

```powershell
pip install mkdocs
cd .\target\
mkdocs serve
```

Whenever the `master` branch is committed to, the documentation is built and deployed here.
Additionally, upon opening or updating a Pull Request, the documentation is built and uploaded as a GitHub artifact.
This can be used to easily check the resulting documentation for a Pull Request.

### Inline Documentation

The core concept of the documentation script is "features". Documentation always relates to a given
feature, and usually the feature name is the name of the function or event that is added. Every feature
needs exactly one *definition*, and may have additional documentation scattered throughout other source files.

#### Syntax

Every block of comments starting with triple comment characters (`///` for UnrealScript files and `;;;` for Ini files)
and an optional whitespace character (space or tab) will be considered for documentation. Additionally,
the first line must begin with `HL-Docs:`. All directly following lines that start with the same triple comment
will be included until the first line that does not have that triple comment. Standard MarkDown syntax is expected
and supported.
You may include source code fragments directly from the game code by placing a single `HL-Include:`
in an otherwise empty triple comment line; all following lines until the next triple comment line will
be included as source code in the documentation.

##### Feature definitions

A feature definition has the following syntax:

    HL-Docs: feature:<string>; issue:<int>; tags:<string>,<string>...

##### Feature references

If you have defined a feature somewhere but want to reference other parts of the source code, or want to
spread the documentation for a feature across different files, you may place a reference:

    HL-Docs: ref:<string>

All text from the reference block will be appended to the main documentation as well.

##### Complete example

(Taken from [ArmorEquipRollDLCPartChance](misc/ArmorEquipRollDLCPartChance.md))

`XComGameState_Unit.uc`:
```unrealscript
/// HL-Docs: feature:ArmorEquipRollDLCPartChance; issue:155; tags:customization,compatibility
/// When a unit equips new armor, the game rolls from all customization options, even the ones where
/// the slider for the `DLCName` is set to `0`. The HL change fixes this, but if your custom armor only
/// has customization options with a `DLCName` set, the game may discard that `DLCName` (default: in 85% of cases)
/// which results in soldiers without torsos. If you want to keep having `DLCName`-only armor
/// (for example to display mod icons in `UICustomize`), you must disable that behavior
/// by creating the following lines in `XComGame.ini`:
///
/// ```ini
/// [XComGame.CHHelpers]
/// +CosmeticDLCNamesUnaffectedByRoll=MyDLCName
/// ```
```

`XComGame.ini`:
```ini
;;; HL-Docs: ref:ArmorEquipRollDLCPartChance
```

#### Tags

You may tag your documentation with a number of built-in and custom tags.
`strategy` and `tactical` are built-in tags used to categorize features in
the navigation bar. If a feature has one tag and not the other, it'll land
in that category. Otherwise, it'll land in the `misc` category.

Custom tags can be used, but need a custom page that serves as an index page
for that tag; for example the `compatibility` tag has a page `docs_src/compatibility.md`
that describes what the tag is supposed to mean and (automatically generated) links
to all features with that tag.

#### Bugfixes

The [`Bugfixes`](Bugfixes.md) feature is owned by the documentation script and as such has
no definition in the game code. It is used for generating a page listing all
bugfixes that can be explained by a single line. It uses a slightly modified
reference syntax:

    HL-Docs: ref:Bugfixes; issue:<int>
    <string>

for example:

```unrealscript
/// HL-Docs: ref:Bugfixes; issue:70
/// `CharacterPoolManager:CreateCharacter` now honors ForceCountry
```
