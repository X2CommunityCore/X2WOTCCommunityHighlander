# X2WOTCCommunityHighlander

Welcome to the X2 WOTC Community Highlander Github project. This is where the work happens.

* [Download the latest release](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/releases)

* [View Highlander documentation](https://x2communitycore.github.io/X2WOTCCommunityHighlander/)

## What version are we at?

We maintain two versions of the Highlander, published on the Steam Workshop: 

* [Stable](https://steamcommunity.com/workshop/filedetails/?id=1134256495) version that matches the
[latest GitHub release](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/releases) and has been tested a fair amount.
* [Beta](https://steamcommunity.com/sharedfiles/filedetails/?id=1796402257)
version that is updated more frequently with changes from the master branch.

When using the Beta version, the Highlander's version in the lower right corner of the game's main menu will tell you which commit the beta version is based on.

## What IS the X2WOTCCommunityHighlander?

Highlander replaces the game's main script package - XComGame. This allows the Highlander to alter portions of the game's code without using any [ModClassOverrides](https://www.reddit.com/r/xcom2mods/wiki/index/mod_class_overrides) to incorporate bugfixes and various ways for other mods to interact with the game's code without needing to use MCOs themselves, which would be bad for compatibility.

In other words, the purpose of the Highlander is to fix bugs and to improve compatibility between other mods.

As implied by the name, there can be only one Highlander. Therefore, it's important for the Highlander to address as many modding use-cases as possible, and incorporate bugfixes that would otherwise require Class Overrides to implement.

The original X2CommunityHighlander is an extension of the Long War 2 Highlander, which was built by the hard-working Pavonis Interactive team.

The X2WOTCCommunityHighlander provides a Highlander for the XCOM 2 *War of the Chosen* expansion.

## How does it work?

As a mod user, you can simply use Highlander as any other mod. 

As a modmaker and a potential contributor to the Highlander, learning the following could be beneficial. XComGame replacements can be loaded successfully into XCOM 2 only in one of two ways:

1. As a cooked package (a .upk file). This is how the unmodified vanilla game works, and this is the way normally used by the Highlander.
2. With the `-noseekfreeloading` switch, which is designed for debugging purposes.

You can learn more details from Abe Clancy's [excellent post on the Nexus Forums](https://forums.nexusmods.com/index.php?/topic/3868395-highlander-mods-modding-native-classes-and-core-packages-xcomgameupk-etc/).

## Building Against Highlander

### When is it necessary?

Building against Highlander is necessary when your mod intends to call a specific function or use a class that exists only in the Highlander, such as [CHEventListenerTemplate](https://x2communitycore.github.io/X2WOTCCommunityHighlander/misc/CHEventListenerTemplate/) or [XComGameState_Unit::HasAbilityFromAnySource\(\)](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/46c31a87e1ceef4d654138b9b33f70f21a895f96/X2WOTCCommunityHighlander/Src/XComGame/Classes/XComGameState_Unit.uc#L3918).

If the game attempts to execute code that uses these classes/functions, and the Highlander mod is not active, the game will hard crash, so Highlander will become a hard requirement for your mod.

If you build your mod against the Highlander, but don't use any of its features, your mod will not have Highlander as a hard requirement, so there are no downsides to building your mod against the Highlander in this regard.

Building against Highlander is NOT necessary if your mod:

* Implements X2DownloadableContentInfo methods that exist only in Highlander, such as [AbilityTagExpandHandler_CH](https://www.reddit.com/r/xcom2mods/wiki/index/localization#wiki_abilitytagexpandhandler_ch) or [CanAddItemToInventory_CH_Improved](https://www.reddit.com/r/xcom2mods/wiki/wotc_modding/canadditemtoinventory_ch_improved).
* Sets values for configuration variables that exist only in Highlander, such as [DLC Run Order](https://www.reddit.com/r/xcom2mods/wiki/index/dlcrunorder) or [Required/Incompatible Mods](https://www.reddit.com/r/xcom2mods/wiki/index/hlrequiredmods).

Highlander will still be required for your mod to work properly, but you don't need to build your mod against it.

### How to build your mod against the Highlander?

You need to replace the source code in the XCOM 2 SDK with the source code of the Highlander. Here's how:

1) [Subscribe to Highlander](https://steamcommunity.com/sharedfiles/filedetails/?id=1134256495), if you haven't already.

2) Close the Modbuddy, if it's open.

3) Locate the SDK folder that contains the source code: 

`..\steamapps\common\XCOM 2 War of the Chosen SDK\Development\`

4) Delete the `Src` folder. Yes, really.

5) Make a backup of the `SrcOrig` folder.

6) Locate the Highlander source code folder: 

`..\steamapps\workshop\content\268500\1134256495\Src\`

7) Copy the contents of Highlander's `Src` folder into the `SrcOrig` in the SDK source code folder, overriding duplicate files.

From here: `..\steamapps\workshop\content\268500\1134256495\Src\`

To here: `..\steamapps\common\XCOM 2 War of the Chosen SDK\Development\SrcOrig\`

8) [The result should look like this.](https://i.imgur.com/qa728WK.jpg)

Done. Now your mods can take full advantage of Highlander's features.

## Highlander Development

Highlander is a community project and everybody is welcome to contribute. Feel free to file a Pull Request for any of the open Issues and wait for a maintainer to review and merge it. You can also file new Issues.

### Discussion channel

For the most part, discussion happens in the #highlander [Discord channel](https://discordapp.com/invite/vvsXvs3) of the XCOM 2 modmaking Discord server. It is our platform of choice for lengthy discussions that don't fit GitHub issues.

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

### Building the Highlander

1. Make sure you have the full content SDK installed (`full_content` branch in Properties->Betas->`full_content`). This requires about 90 GB of disk space.
2. The custom version of the [X2ModBuildCommon](https://github.com/X2CommunityCore/X2ModBuildCommon) built into Highlander's mod project requires Git, so make sure you have Git installed. You can download the Git installer from the [official website](https://git-scm.com/downloads). Note that Git embedded into some of the Git GUI apps like Source Tree is not enough, it must be a separate Git installation.

Once you have satisfied these requirements, you should be able to build the Highlander like any other mod.

### Cooking a Final Release (Automated method)

Build the mod using `Default`/`Final release` (ModBuddy) or `cooked`/`final release` (VSCode) profiles

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

### Using NoSeekFreeLoading

Using the -NoSeekFreeLoading launch argument is required if you intend to use [Unreal Debugger](https://www.reddit.com/r/xcom2mods/wiki/wotc_modding/guides/unreal_debugger) to interact with classes in the XComGame script package. 

In order to be able to actually run the game with NoSeekFreeLoading without crashing, you must use it alongside an uncooked Highlander, and you must also provide the game with the uncooked Content files, which you can get from the full content SDK.

1. Install full_content version of the SDK.

2. Ensure symlinks from the main WOTC folder point to the same folders within the SDK. Delete the following folders/links if they exist:

```
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Content
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Script
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\__Trashcan
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Engine\Content
%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Engine\EditorResources
```

...and then open a command prompt as an administrator and run the following
commands:

```
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Content" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Content"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Script" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Script"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\__Trashcan" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\__Trashcan"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Engine\Content" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\Engine\Content"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Engine\EditorResources" "%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\Engine\EditorResources"
```

3. Build the Highlander using the "Debug" profile. 

4. You can now use the -NoSeekFreeLoading launch argument to start the game with the uncooked Highlander. This can be done by running XCOM with the following command (in the command prompt):

```
"%STEAMLIBRARY%\steamapps\common\XCOM 2\Binaries\Win64\Launcher\ModLauncherWPF.exe" -allowconsole -log -autodebug -noseekfreeloading -noStartUpMovies
```

If all goes well, the XCOM Launcher will run. Enable X2WOTCCommunityHighlander and start the game.

You can also use the same launch arguments in the Alternative Mod Launcher.

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
