# X2WOTCCommunityHighlander

Welcome to the X2WOTCCommunityHighlander Github project. This is where the work happens.

[Download the latest release](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/releases)

[View Highlander documentation](https://x2communitycore.github.io/X2WOTCCommunityHighlander/)

## What version are we at?

There are two published Steam versions: One infrequently updated
[stable](https://steamcommunity.com/workshop/filedetails/?id=1134256495) version that matches the
[latest GitHub release](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/releases)
has been tested a fair amount, and a [beta](https://steamcommunity.com/sharedfiles/filedetails/?id=1796402257)
version that is updated more frequently with changes from the master branch. The main menu text
tells you which commit the beta version is based on.

## What IS the X2WOTCCommunityHighlander?

A **Highlander** replaces the XComGame package. That means it replaces the code of the Vanilla
game, without requiring any ModClassOverrides to do so. As implied by the name,
there can only be one Highlander. Therefore, it's important to make a highlander address
as many modding use-cases as possible, and incorporate bugfixes that
would otherwise require class overrides to implement.

The original X2CommunityHighlander is an extension of the Long War 2 Highlander, which was built by the hard-working Pavonis
Interactive team.

The X2WOTCCommunityHighlander provides a Highlander for the XCOM 2 expansion *War of the Chosen*.


## Development

### Discussion channel

For the most part, discussion happens in a [Discord channel](https://discordapp.com/invite/vvsXvs3). It's our platform of choice for lengthy discussions that don't fit GitHub issues.

### Code style

The code style is what is generally in use for the XCOM 2 codebase:

* Tabs (width: 4 spaces)
* Braces always on a new line
* Liberal use of space between blocks
* Braces even for one-line if/else bodies
  
The following code should illustrate all of this:

```unrealscript
static function CompleteStrategyFromTacticalTransfer()
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	UpdateSkyranger();
	CleanupProxyVips();
	ProcessMissionResults();
	SquadTacticalToStrategyTransfer();

	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPostMission();
	}
}
```

### Documenting your Contributions

Generally, Highlander changes will be weaved into vanilla code in ways that
require us to keep close track of what code changes what vanilla behaviour, and
for what purpose. To do this, we comment code precisely to match with issues
created on Github at:

https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues

Every change has a *tracking issue*, where the problem is described along with a use case
for the Highlander change. This applies to bugs, enhancements, and new features.

Any code you write should be documented to include the issue it addresses, either as
a single line comment, or as a start and end block. Don't forget to mark any
variables added for that issue, as well.

We should be able to find every line of code related to an issue by searching
for "Issue #928" (or whatever) in the codebase. In addition, any commits
related to that issue should also have the issue number marked in the same way.

Additionally, every feature should be documented with *inline documentation* that will
be published via GitHub Pages (at [https://x2communitycore.github.io/X2WOTCCommunityHighlander/](https://x2communitycore.github.io/X2WOTCCommunityHighlander/)).
That online documentation also has [instructions](https://x2communitycore.github.io/X2WOTCCommunityHighlander/#documentation-for-the-documentation-tool) for how to write your documentation
and run the documentation tool.

## Building

XComGame replacements, like this highlander, can only be loaded successfully into XCOM 2 in one of two ways:

1. As a cooked package (a .upk file). This is how the unmodified vanilla game works.
2. With the `-noseekfreeloading` switch, which is designed for debugging purposes.

Most of the information here about building the game comes from Abe Clancy's excellent post on the Nexus
Forums:

https://forums.nexusmods.com/index.php?/topic/3868395-highlander-mods-modding-native-classes-and-core-packages-xcomgameupk-etc/

His post goes into far more detail than this guide, if you're interested.

### Cooking a Final Release (Automated method)

1. Make sure you have the complete SDK installed (`full_content` branch in Properties->Betas->`full_content`). This requires about 90 GB of disk space.
2. Build the mod using `Default`/`Final release` (ModBuddy) or `cooked`/`final release` (VSCode) profiles

### Cooking a Final Release (Manual method)

#### One-time preparation


The following instructions are functionally the same as those of a vanilla Highlander mod. All the below references to the root Steam directory are made as %STEAMLIBRARY%. You should replace them with your actual Steam directory folder, such as: "D:/SteamLibrary", or whatever. 

A few files need to be copied into the SDK for you to successfully cook the
Highlander. Check the folder
`%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\CookedPCConsole` 
and copy the following files to
`%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole`:

```
GuidCache.upk
GlobalPersistentCookerData.upk
PersistentCookerShaderData.bin
*.tfc
```

Additionally, you need to install the complete SDK (`full_content` branch in Properties->Betas->`full_content`). This requires about 90 GB of disk space.

#### Cooking

Start by building the mod through ModBuddy, as you normally would. Then, enter the command line and run the following commands:

```
"%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\Binaries\Win64\XComGame.exe" make -final_release -full
"%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\Binaries\Win64\XComGame.exe" CookPackages -platform=pcconsole -final_release -quickanddirty -modcook -sha -multilanguagecook=INT+FRA+ITA+DEU+RUS+POL+KOR+ESN -singlethread
```

If a message like "Scripts are outdated. Would you like to rebuild now?" pops up, click "No".

The commands above create cooked files for your `XComGame`, `Engine`, and `Core` package replacements in
`%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole`: 
```
XComGame.upk
XComGame.upk.uncompressed_size
Engine.upk
Engine.upk.uncompressed_size
Core.upk
Core.upk.uncompressed_size
```

Copy those files into a folder called `CookedPCConsole` inside the mod's output 
folder. You will need to delete `Script\XComGame.u`, `Script\Engine.u` and `Script\Core.u`,
now that we've put the cooked script file in it's place.

Once you've done all that, the mod should now run in vanilla XCOM. Note that all
logging statements will be stripped from the Cooked version, so don't expect to
see any of your script logs.


### Using noseekfreeloading

Before using noseekfreeloading, a few things need to be done to ensure the game
actually runs without crashing.

You need to install the XCOM 2 War of the Chosen SDK obviously, and also opt-in to
download the 'full content' for it (54 GB). You opt-in by using the 'Betas' menu
in Steam. It doesn't require a code to download the content.

After you've installed the XCOM 2 War of the Chosen SDK, it's important you ensure symlinks from
the main WOTC folder point to the same folders within the SDK. Delete the following folders/links if they exist:

```
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Content
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Script
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\__Trashcan
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Engine\Content
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Engine\EditorResources
```

...and then open a command line as an administrator and run the following
commands:

```
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Content" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Content"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Script" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Script"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\__Trashcan" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\__Trashcan"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Engine\Content" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\Engine\Content"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Engine\EditorResources" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\Engine\EditorResources"
```


Build the mod through ModBuddy, as usual. The Highlander mod can be loaded uncooked by running XCOM
with the following command (in the command prompt):

```
"%STEAMLIBRARY%\steamapps\common\XCOM 2\Binaries\Win64\Launcher\ModLauncherWPF.exe" -allowconsole -log -autodebug -noseekfreeloading
```

You can also use Alternative Mod Launcher with the same launch arguments.

If all goes well, the XCOM Launcher will run. Enable X2WOTCCommunityHighlander and start the game.


## Building Against the Highlander

Making new mods that use the Highlander requires one change, to
ensure you can use any new classes or methods it implemented. The SDK uses the
contents of `XCOM 2 War of the Chosen SDK\Development\SrcOrig` to compile against files not included in the
mod.

Backup that folder, as it contains the vanilla source files, and then copy the
highlander's Src folder into it. Be aware that if you make a mod that uses any
new functions or variables, it will crash Vanilla XCOM 2, guaranteed.

If your mod uses the methods or functions provided by Long War 2's Highlander,
things should still work fine.

## Recruiting Maintainers

We are currently recruiting maintainers.

The Community Highlander mod is the backbone of the XCOM 2 modding community, providing essential functionality that powers many of the most popular mods, but it cannot evolve without active maintainers, which means new mods are unable to get the functionality they need into the Highlander.

So we are looking to recruit as many maintainers as possible.

### Required qualifications

* Experience making XCOM 2 mods and coding in Unreal Script.
* Being familiar with Git or at least willingness to learn using it.
* Perfectionism and attention to detail.
* Knowledge of different XCOM 2 systems, such as visualization, state code, effects, and history, is welcome, but not a hard requirement.

### Responsibilities

* Reviewing Pull Requests and suggesting changes to ensure compliance with Highlander's requirements and guidelines.
* Updating the workshop version of Highlander when enough Pull Requests are approved.

### Compensation

* A sense of pride and accomplishment associated with doing useful things for hundreds of thousands of people.
* First row seat to contributing your own changes to the Highlander.
