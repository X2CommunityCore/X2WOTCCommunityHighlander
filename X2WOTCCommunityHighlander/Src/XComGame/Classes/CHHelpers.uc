class CHHelpers extends Object config(Game);

//issue #188 - creating a struct and usable array for modders
struct TeamRequest
{
	var name XGAIPlayerUsed; //when eTeam_One or eTeam_Two is requested to be activated by a mod, we need to assign a XGAIPlayer class to that player state made for the team
	var ETeam Team; //eTeam_One and eTeam_Two should be the only ones here.
	var bool AlertsAreVerified; 
};

var config array<TeamRequest> ModAddedTeams;
//end issue #188

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

//start issue #188 - functions for checking the config array
static function bool TeamOneRequired()
{
	local TeamRequest CheckedRequest;
	
	foreach ModAddedTeams(CheckedRequest)
	{
		if(CheckedRequest.Team == eTeam_One){
			return true;
		}
	}
	
	return false;
}

static function bool TeamTwoRequired()
{
	local TeamRequest CheckedRequest;
	
	foreach ModAddedTeams(CheckedRequest)
	{
		if(CheckedRequest.Team == eTeam_Two){
			return true;
		}
	}
	
	return false;
}

static function XGAIPlayer GetTeamOnePlayer()
{
	local XComGameState_Player PlayerState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.TeamFlag == eTeam_One)
		{
			break;
		}
	}

	return PlayerState != none ? XGAIPlayer(PlayerState.GetVisualizer()) : none;

}

static function XGAIPlayer GetTeamTwoPlayer()
{
	local XComGameState_Player PlayerState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.TeamFlag == eTeam_Two)
		{
			break;
		}
	}

	return PlayerState != none ? XGAIPlayer(PlayerState.GetVisualizer()) : none;

}
//end issue #188

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
		for(Index = 0; Index < ProfileSettings.Data.PartPackPresets.Length; ++Index)
		{
			if(ProfileSettings.Data.PartPackPresets[Index].PartPackName == PartPackNames[PartPackIndex])
			{
				bHasSetting = true;
				if (
					`SYNC_FRAND_STATIC() <= ProfileSettings.Data.PartPackPresets[Index].ChanceToSelect &&
					ProfileSettings.Data.PartPackPresets[Index].ChanceToSelect > 0.02f
					//0.02 so sliders being set to the minimum actually do something
				)
				{
					DLCNames.AddItem(ProfileSettings.Data.PartPackPresets[Index].PartPackName);
					break;
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
