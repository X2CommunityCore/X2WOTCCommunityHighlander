# X2WOTCCommunityHighlander

Welcome to the X2WOTCCommunityHighlander Github project. This is where the work happens.

# What version are we at?

[Check out the latest release here.](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/releases)

# The Job List

* Complete issues.

# What IS the X2WOTCCommunityHighlander?

A **Highlander** replaces the XComGame package. That means it replaces the code of the Vanilla
game, without requiring any ModClassOverrides to do so. As implied by the name,
there can only be one Highlander. Therefore, it's important to make a highlander address
as many modding use-cases as possible, and incorporate bugfixes that
would otherwise require class overrides to implement.

The original X2CommunityHighlander is an extension of the Long War 2 Highlander, which was built by the hard-working Pavonis
Interactive team.

The X2WOTCCommunityHighlander provides a Highlander for the XCOM 2 expansion *War of the Chosen*.


# Contributing

## When contributing, please

* use the code style that is generally used in the XCOM 2 codebase:
  * use tabs
  * use new lines for braces
  * use appropriate spacing
  * use braces even for one-line if/else bodies
  
The following code should illustrate all of this:

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

## Documenting your Contributions

Generally, Highlander changes will be weaved into vanilla code in ways that
require us to keep close track of what code changes what vanilla behaviour, and
for what purpose. To do this, we comment code precisely to match with issues
created on Github at:

https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues

Code must belong to an issue, before it's submitted as a pull request. Check if any open issues describe the change you want to make, or create a new issue, if that isn't the case.

Any code you write should be documented to include the issue it addresses, either as
a single line comment, or as a start and end block. Don't forget to mark any
variables added for that issue, as well.

    static function CompleteStrategyFromTacticalTransfer()
    {
    	// Variables for Issue #928
    	local XComOnlineEventMgr EventManager;
    	local array<X2DownloadableContentInfo> DLCInfos;
    	local int i;

    	UpdateSkyranger();
    	CleanupProxyVips();
    	ProcessMissionResults(); // Issue #345 - does an extra thing
    	SquadTacticalToStrategyTransfer();

    	EventManager = `ONLINEEVENTMGR;
    	// Start Issue #928
    	DLCInfos = EventManager.GetDLCInfos(false);
    	for (i = 0; i < DLCInfos.Length; ++i)
    	{
    		DLCInfos[i].OnPostMission();
    	}
    	// End Issue #928
    }

We should be able to find every line of code related to an issue by searching
for "Issue #928" (or whatever) in the codebase. In addition, any commits
related to that issue should also have the issue number marked in the same way.

# Building

XComGame replacements, like this highlander, can only be loaded successfully into XCOM 2 in one of two ways:
1. As a cooked package (a .upk file). This is how the unmodified vanilla game works.
2. With the `-noseekfreeloading` switch, which is designed for debugging purposes.

Most of the information here about building the game comes from Abe Clancy's excellent post on the Nexus
Forums:

https://forums.nexusmods.com/index.php?/topic/3868395-highlander-mods-modding-native-classes-and-core-packages-xcomgameupk-etc/

His post goes into far more detail than this guide, if you're interested.

## Cooking a Final Release (Automated method)

1. Copy 'CookCommunityHighlander.bat' to your SteamLibrary folder (the folder that
contains the steamapps subfolder). By default, this path is `C:\Program Files (x86)\Steam`. 
2. If XCOM 2 and the SDK are in the same Steam library, go to step 4. If they are in different libraries, go to the next step.
3. Open CookCommunityHighlander.bat in a text editor, modify the variables below, and save:
```
SET "SDKLocation=.\steamapps\common\XCOM 2 War of the Chosen SDK"
SET "GameLocation=.\steamapps\common\XCOM 2\XCom2-WarOfTheChosen"
```
4. Run CookCommunityHighlander.bat by double-clicking it.
5. If a message like "Scripts are outdated. Would you like to rebuild now?" pops up, click "No".

## Cooking a Final Release (Manual method)
### One-time preparation


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

### Cooking

Start by building the mod through ModBuddy, as you normally would. Then, enter the command line and run the following commands:

```
"%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\Binaries\Win64\XComGame.exe" make -final_release -full
"%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\Binaries\Win64\XComGame.exe" CookPackages -platform=pcconsole -final_release -quickanddirty -modcook -sha -multilanguagecook=INT+FRA+ITA+DEU+RUS+POL+KOR+ESN -singlethread
```

If a message like "Scripts are outdated. Would you like to rebuild now?" pops up, click "No".

The commands above create cooked files for your `XComGame` and `Engine` package replacements in
`%STEAMLIBRARY%\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole`: 
```
XComGame.upk
XComGame.upk.uncompressed_size
Engine.upk
Engine.upk.uncompressed_size
```

Copy those files into a folder called `CookedPCConsole` inside the mod's output 
folder. You will need to delete `Script\XComGame.u` and `Script\Engine.u`, now that we've put the
cooked script file in it's place.

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
"%STEAMLIBRARY%\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\Binaries\Win64\Launcher\ModLauncherWPF.exe" -allowconsole -log -autodebug -noseekfreeloading
```

If all goes well, the XCOM Launcher will run. Enable X2WOTCCommunityHighlander and start the game.


# Building Against the Highlander

Making new mods that use the Highlander requires one change, to
ensure you can use any new classes or methods it implemented. The SDK uses the
contents of `XCOM 2 War of the Chosen SDK\Development\SrcOrig` to compile against files not included in the
mod.

Backup that folder, as it contains the vanilla source files, and then copy the
highlander's Src folder into it. Be aware that if you make a mod that uses any
new functions or variables, it will crash Vanilla XCOM 2, guaranteed.

If your mod uses the methods or functions provided by Long War 2's Highlander,
things should still work fine.
