class CHHelpers extends Object config(Game);

var config int SPAWN_EXTRA_TILE; // Issue #18 - Add extra ini config
var config int MAX_TACTICAL_AUTOSAVES; // Issue #53 - make configurable, only use if over 0

// Start Issue #41 
// allow chosen to ragdoll, and to collide via config.
// will have performance impacts as the physics will not turn off.
var config bool ENABLE_CHOSEN_RAGDOLL;
var config bool ENABLE_RAGDOLL_COLLISION;
// End Issue #41

// Start Issue #44
// Set to true to prevent Multi-part missions escaping the Will loss cap that is defined in most will rolls
var config bool MULTIPART_MISSION_WILL_LOSS_CAP;
// End Issue #44

//start issue #82
//allow factions to be filtered at game start so we don't have broken base game factions
var config array<name> EXCLUDED_FACTIONS;
//end issue #82

//start issue #85
//variable for controlling whether the game is allowed to track whether a unit has ever gotten a trait before
//this is kept disabled for balance reasons
var config bool CHECK_CURED_TRAITS;
//end issue #85

// Start Issue #80
// List of classes to exclude from rolling awc abilities
// These classes have bAllowAWCAbilities set to true just to participate in the ComInt / AP system
var config array<name> ClassesExcludedFromAWCRoll;
// End Issue #80

// Start Issue #123
// List of AbilityTemplateNames that have associated XComPerkContent
var config array<name> AbilityTemplatePerksToLoad;
// End Issue #123

// start issue #113
// list of classes to exclude from being considered "needed" by XComGameState_HeadquartersResistance
// these are for classes which are meant to be rarely acquired via rookie level up, though others may also be here for their own reasons
var config array<name> ClassesExcludedFromResHQ;
//end issue #113

// Start Issue #186
// This is a performance improvement, so we want the default setting to actually change the game behavior
// This change shouldn't break anything, but the logic is so tightly interfaced with native code I want to provide
// an easy opt-out in case it breaks anything, especially in combination with mods that relied on quirky behavior.
// If it turns out that this setting has any noticable effects with Materials, that should be considered a separate issue
// and fixed before touching this again.
var config bool UPDATE_MATERIALS_CONSTANTLY;
// End Issue #186

// Start Issue #155
// In the base game, XComGameState_Unit doesn't care about sliders all that much. However, the fix to
// handle sliders correctly has one problem -- mods may add part types for a specific armor and assign
// it a DLC Name. If those parts are the only valid ones, but the roll fails, we have invisible parts.
// Hence, we allow DLCNames to be specified here that are excluded by the chance roll and are always
// valid, effectively making them "vanilla" parts (parts without a DLCName)
var config array<name> CosmeticDLCNamesUnaffectedByRoll;
// End Issue #155

// Start Issue #171
var config bool GrenadeRespectUniqueRule;
var config bool AmmoSlotBypassUniqueRule;
// End Issue #171

// Start Issue #123
simulated static function RebuildPerkContentCache() {
	local XComContentManager		Content;
	local name						AbilityTemplateName;

	Content = `CONTENT;
	Content.BuildPerkPackageCache();
	foreach default.AbilityTemplatePerksToLoad(AbilityTemplateName) {
		Content.CachePerkContent(AbilityTemplateName);
	}
}
// End Issue #123

//start issue #155
static function array<name> GetAcceptablePartPacks()
{
	local int Index;
	local XComOnlineProfileSettings ProfileSettings;
	local X2BodyPartTemplateManager PartTemplateManager;
	local int PartPackIndex;
	local array<name> PartPackNames, DLCNames;
	local bool bHasSetting;

	ProfileSettings = `XPROFILESETTINGS;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartPackNames = PartTemplateManager.GetPartPackNames();
		
	DLCNames.Length = 0;
	DLCNames.AddItem(''); //this represents vanilla or otherwise unassigned parts
	for(PartPackIndex = 0; PartPackIndex < PartPackNames.Length; ++PartPackIndex)
	{
		bHasSetting = false;
		if (default.CosmeticDLCNamesUnaffectedByRoll.Find(PartPackNames[PartPackIndex]) != INDEX_NONE)
		{
			bHasSetting = true;
			DLCNames.AddItem(PartPackNames[PartPackIndex]);
		}
		else
		{
			for(Index = 0; Index < ProfileSettings.Data.PartPackPresets.Length; ++Index)
			{
				if(ProfileSettings.Data.PartPackPresets[Index].PartPackName == PartPackNames[PartPackIndex])
				{
					bHasSetting = true;
					if (`SYNC_FRAND_STATIC() <= ProfileSettings.Data.PartPackPresets[Index].ChanceToSelect &&
						ProfileSettings.Data.PartPackPresets[Index].ChanceToSelect > 0.02f) //0.02 so sliders being set to the minimum actually do something
					{
						DLCNames.AddItem(ProfileSettings.Data.PartPackPresets[Index].PartPackName);
						break;
					}
				}
			}
		}

		//Handle the case where a setting has not been specified in the options menu
		if(!bHasSetting && `SYNC_FRAND_STATIC() <= class'XGCharacterGenerator'.default.DLCPartPackDefaultChance)
		{
			DLCNames.AddItem(PartPackNames[PartPackIndex]);
		}
	}

	return DLCNames;
}
//end issue #155
