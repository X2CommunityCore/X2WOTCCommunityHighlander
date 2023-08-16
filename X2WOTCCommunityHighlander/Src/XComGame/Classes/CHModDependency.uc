/// HL-Docs: feature:ModDependencyCheck; issue:524; tags:compatibility
/// Allows mods to declare required and incompatible mods. The Highlander
/// will show popups for missing requirements and detected incompatibilities.
///
/// ## Terminology
///
/// We'll need to distinguish a few identifiers in mod project setups to explain this feature,
/// so here's a short rundown.
///
/// * **`DLCName`** is the actual ID of the mod. It's always the base name of the `.XComMod` file,
/// so `YetAnotherF1.XComMod` has a DLCName of `YetAnotherF1`. This is also the name that mod launchers
/// specify in the `ActiveMods` list, and the way the game knows how to load that mod. Every mod has exactly
/// one DLCName. Mods with the same DLCName can only be enabled or disabled together.
/// The game stores the `DLCName` in the save file, and shows a warning upon attempting to load a save file
/// when it had recorded a mod that's no longer enabled. DLCNames are case-insensitive.
/// * **`DLCIdentifier`** is an identifier corresponding to a `X2DownloadableContentInfo` class.
/// Every mod has zero, one, or several `X2DownloadableContentInfo` classes, and the DLCIdentifier may be empty for
/// any of them. This DLCIdentifier is used for some customization aspects (like part icons or slider names) and
/// narrative content options (for the official DLCs). It's also used in CHL's [Run Order](../misc/DLCRunOrder.md)
/// since Run Order is all about `X2DownloadableContentInfo` classes. DLCIdentifiers are generally case-sensitive.
///
/// In the default ModBuddy mod project, the mod has exactly one `X2DownloadableContentInfo` subclass
/// with a DLCIdentifier identical to the DLCName. However, config-only mods have no `X2DownloadableContentInfo`
/// at all, and some mods may have one but misconfigured the class so that the `DLCIdentifier` is empty.
///
/// ## CHModDependency
/// 
/// Now for the actual feature: Let's call the information about a mod provided to
/// the dependency checker *dependency info*, or *DepInfo*. A mod declares dependency
/// info through configuration entries for a class of type `CHModDependency` in `XComGame.ini`.
/// Let's look at an example upfront (taken from [Musashi's RPG Overhaul](https://steamcommunity.com/sharedfiles/filedetails/?id=1280477867)):
///
/// ```ini
/// [XCOM2RPGOverhaul CHModDependency]
/// DisplayName="Musashis RPG Overhaul"
///
/// +IncompatibleMods="NewPromotionScreenbyDefault"
/// +IncompatibleMods="DetailedSoldierListWOTC"
/// +IncompatibleMods="ABetterBarracksTLE"
/// +IncompatibleMods="ABetterBarracks"
/// +IncompatibleMods="ViewLockedSkillsWotc"
/// +IncompatibleMods="AddMintToMyChocolate"
/// +IncompatibleMods="RevisedWeaponUpgrades"
///
/// +RequiredMods="WOTC_LW2SecondaryWeapons"
/// +RequiredMods="PrimarySecondaries"
/// +RequiredMods="BetterSecondWaveSupport"
///
/// +IgnoreRequiredMods="NewPromotionScreenbyDefault"
/// +IgnoreRequiredMods="ViewLockedSkillsWotc"
/// +IgnoreRequiredMods="DetailedSoldierListWOTC"
/// ```
///
/// `CHModDependency` is the class that contains our DepInfo. That class is
/// `perobjectconfig`, so we can provide unique configuration for differently
/// named instances of the class. In this case, since the DLCName of RPGO is
/// `XCOM2RPGOverhaul`, we use that in the header.
///
/// `DisplayName` is a human-readable name of the mod. This is used for the actual
/// popup that says for example "Musashis RPG Overhaul detected INCOMPATIBLE mods".
///
/// `IncompatibleMods` is a list of DLCNames that should not be enabled together
/// with this mod. For every mod with an enabled incompatible mod, there will be a popup
/// that lists all enabled incompatible mods.
///
/// `RequiredMods` is a list of DLCNames that should be enabled together with
/// this mod. For every mod with a missing required mod, there will be a popup
/// that lists all missing requirements.
///
/// `IgnoreRequiredMods` is a list of DLCNames that should be considered enabled if
/// this mod is enabled. For example, RPGO integrates `NewPromotionScreenbyDefault`,
/// so another mod should not consider `NewPromotionScreenbyDefault` missing if RPGO
/// is enabled.
///
/// There also is a `IgnoreIncompatibleMods` list of DLCNames that I am unfortunately
/// not qualified to present a use case for. What `+IgnoreIncompatibleMods="SomeDLCName"`
/// does is silence any warning that a third mod would throw if it listed 
/// `+IncompatibleMods="SomeDLCName"`. If you think this is useful in any way, please tell
/// us about it in [HL issue #967](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/967).
///
/// This is what the popup for missing requirements looks like:
/// ![Screenshot of RPGO's missing required mods](https://i.imgur.com/D1G6ZF7.png)
/// Since the missing requirements aren't enabled, we don't have any info about their
/// DisplayName.
///
/// ## How the dependency checker retrieves dependency info
///
/// The dependency checker looks at the config objects from
///
/// * All currently enabled DLCNames
/// * All non-empty DLCIdentifiers from found `X2DownloadableContentInfo` classes
/// 
/// while ignoring duplicates. Note that only DLCNames are supported for `IncompatibleMods`,
/// `RequiredMods` etc., you cannot specify a requirement on or incompatibility with a given DLCIdentifier!
///
///
/// This means that mods can easily provide dependency info for other mods --
/// the config object will be ignored if the corresponding DLCName isn't
/// enabled. This also allows mods to add friendly names for other mods so
/// that even if the mod isn't installed or doesn't set a `DisplayName`, the
/// popup doesn't only show an internal ID.
///
/// For example, `AddMintToMyChocolate` doesn't participate in the CHL depencency
/// checker at all, but this DLCName is kind of confusing and a reported incompatibility
/// would leave users unable to figure out what the actual conflict is.
///
/// RPGO could add this to its `XComGame.ini` so that the name becomes clearer:
///
/// ```ini
/// [AddMintToMyChocolate CHModDependency]
/// DisplayName="Classless XCOM: MINT"
/// ```
///
/// and the popup would display that incompatibility as "Classless XCOM: MINT (AddMintToMyChocolate)".
/// The same system can also be used to provide a DisplayName for requirements that may be missing
/// and as such can't inform the dependency checker about their DisplayName.
///
/// If the user presses "Do not show me this again", the Highlander will store the object
/// name (DLCName or DLCIdentifier, depending on how the dependency checker found it in
/// the first place) of the mod that provides this data in a user config file
/// (`%USERPROFILE%/Documents/My Games/XCOM 2 War of the Chosen/XComGame/Config/X2WOTCCommunityHighlander_NullConfig.ini`)
/// and won't show this popup again.

class CHModDependency extends Object perobjectconfig Config(Game);

var config array<string> IncompatibleMods;
var config array<string> IgnoreIncompatibleMods;
var config array<string> RequiredMods;
var config array<string> IgnoreRequiredMods;
var config string DisplayName;

// Start Issue #909
/// HL-Docs: feature:RequiredHighlanderVersion; issue:909; tags:compatibility
/// Mods can specify the required Highlander version in the mod's `XComGame.ini`, e.g.:
///```ini
/// [DLCName CHModDependency]
/// RequiredHighlanderVersion = (MajorVersion = 1, MinorVersion = 22, PatchVersion = 0)
///```
/// If the mod user has an older version of the Highlander installed, they will 
/// see a popup warning when they start the game. 
/// Note: this feature is disabled if the game is started without the `-review`
/// launch argument. 
struct CHLVersionStruct
{
	var int MajorVersion;
	var int MinorVersion;
	var int PatchVersion;

	structdefaultproperties
	{
		MajorVersion = -1
		MinorVersion = -1
		PatchVersion = -1
	}
};
var config CHLVersionStruct RequiredHighlanderVersion;
// End Issue #909