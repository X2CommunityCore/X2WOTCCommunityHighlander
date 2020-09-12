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

    python .\.scripts\make_docs.py .\X2WOTCCommunityHighlander\Src\ .\X2WOTCCommunityHighlander\Config\ --outdir .\target\ --docsdir .\docs_src\ --dumpelt .\X2WOTCCommunityHighlander\Src\X2WOTCCommunityHighlander\Classes\CHL_Event_Compiletest.uc

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

#### Events

The Highlander triggers some events to pass data to and receive data from mods. We document
these events with a special syntax and automatically generate a copy-pasteable listener template
that developers can simply copy into their mod and fill out. Additionally, that listener template is
printed into a CHL source file so that it can be tested whether it successfully compiles.

The syntax for events is the following

    ```event
    EventID: OverridePromotionUIClass,
    EventData: [in enum[CHLPromotionScreenType] PromotionScreenType, inout class[class<UIArmory_Promotion>] PromotionUIClass],
    EventSource: XComHQPresentationLayer (Pres),
    NewGameState: none
    ```

* Entries need to be comma-separated
* `EventData` or `EventSource` specify the type, and then optionally in parentheses the variable name.
* `EventData` can be an XComLWTuple. In that case, use `[ inout int a, ... ]`
* Tuple parameters can be `in`, `out`, or `inout`
    * In the template, `in` parameters will be copied from the tuple into a local property
    * `out` parameters will be copied from a local property into the tuple
    * `inout` parameters do both
* All [`XComLWTuple` types][misc/XComLWTuple.md] are supported
    * `enum`s can be typed with `enum[EnumType]`
    * `class`es can be typed with `class[class<Type>]`
    * If the type is not a primitive, it's assumed to be an object

The above example generates the following code

```unrealscript
static function EventListenerReturn OnOverridePromotionUIClass(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local XComHQPresentationLayer Pres;
	local XComLWTuple Tuple;
	local CHLPromotionScreenType PromotionScreenType;
	local class<UIArmory_Promotion> PromotionUIClass;

	Pres = XComHQPresentationLayer(EventSource);
	Tuple = XComLWTuple(EventData);

	PromotionScreenType = CHLPromotionScreenType(Tuple.Data[0].i);
	PromotionUIClass = class<UIArmory_Promotion>(Tuple.Data[1].o);

	// Your code here

	Tuple.Data[1].o = PromotionUIClass;

	return ELR_NoInterrupt;
}
```

All generated listeners will be dumped into [CHL_Event_Compiletest.uc](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/master/X2WOTCCommunityHighlander/Src/X2WOTCCommunityHighlander/Classes/CHL_Event_Compiletest.uc),
which will be excluded from normal compilation and only kept in "compiletest" tasks. If you documented a listener (or changed an existing listener documentation)
but did not run `makeDocs`, CI (automatic scripts running on GitHub servers when you open or update a pull request) will note that `CHL_Event_Compiletest` is
out of date and the `check-event-templates` check will fail! To fix, run `makeDocs` locally and commit the changes to `CHL_Event_Compiletest`.  
Future possibility: generate + upload patch file as artifact?
