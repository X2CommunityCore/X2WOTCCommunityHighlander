//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo.uc
//  AUTHOR:  Ryan McFall
//           
//	Mods and DLC derive from this class to define their behavior with respect to 
//  certain in-game activities like loading a saved game. Should the DLC be installed
//  to a campaign that was already started?
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo extends Object	
	Config(Game)
	native(Core);

//Backwards compatibility for mods
enum EUIAction
{
	eUIAction_Accept,   // User initiated
	eUIAction_Cancel,   // User initiated
	eUIAction_Closed    // Automatically closed by system
};

var config string DLCIdentifier; //The directory name that the DLC resides in
var config bool bHasOptionalNarrativeContent; // Does this DLC have optional narrative content, generates a checkbox in pre-campaign menu
var config array<string> AdditionalDLCResources;    // Resource paths for objects the game will load at startup and be synchronously accessible at runtime

var localized string PartContentLabel; // Label for use in the game play options menu allowing users to decide how this content pack is applied to new soldiers
var localized string PartContentSummary; // Tooltip for the part content slider

var localized string NarrativeContentLabel; // Label next to the checkbox in pre-campaign menu
var localized string NarrativeContentSummary; // Longer description of narrative content for pre-campaign menu

var localized string EnableContentLabel;
var localized string EnableContentSummary;
var localized string EnableContentAcceptLabel;
var localized string EnableContentCancelLabel;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{

}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{

}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{

}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// Allows dlcs/mods to modify the start state before launching into the mission
/// </summary>
static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{

}

/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
static event OnPostMission()
{

}

/// <summary>
/// Called when the player is doing a direct tactical->tactical mission transfer. Allows mods to modify the
/// start state of the new transfer mission if needed
/// </summary>
static event ModifyTacticalTransferStartState(XComGameState TransferStartState)
{

}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
static event OnExitPostMissionSequence()
{

}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{

}

/// <summary>
/// Called when the difficulty changes and this DLC is active
/// </summary>
static event OnDifficultyChanged()
{

}

/// <summary>
/// Called by the Geoscape tick
/// </summary>
static event UpdateDLC()
{

}

/// <summary>
/// Called after HeadquartersAlien builds a Facility
/// </summary>
static event OnPostAlienFacilityCreated(XComGameState NewGameState, StateObjectReference MissionRef)
{

}

/// <summary>
/// Called after a new Alien Facility's doom generation display is completed
/// </summary>
static event OnPostFacilityDoomVisualization()
{

}

/// <summary>
/// Called when viewing mission blades with the Shadow Chamber panel, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool UpdateShadowChamberMissionInfo(StateObjectReference MissionRef)
{
	return false;
}

/// <summary>
/// A dialogue popup used for players to confirm or deny whether new gameplay content should be installed for this DLC / Mod.
/// </summary>
static function EnableDLCContentPopup()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = default.EnableContentLabel;
	kDialogData.strText = default.EnableContentSummary;
	kDialogData.strAccept = default.EnableContentAcceptLabel;
	kDialogData.strCancel = default.EnableContentCancelLabel;

	kDialogData.fnCallback = EnableDLCContentPopupCallback_Ex;
	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated function EnableDLCContentPopupCallback(eUIAction eAction)
{
}

simulated function EnableDLCContentPopupCallback_Ex(Name eAction)
{	
	switch (eAction)
	{
	case 'eUIAction_Accept':
		EnableDLCContentPopupCallback(eUIAction_Accept);
		break;
	case 'eUIAction_Cancel':
		EnableDLCContentPopupCallback(eUIAction_Cancel);
		break;
	case 'eUIAction_Closed':
		EnableDLCContentPopupCallback(eUIAction_Closed);
		break;
	}
}

/// <summary>
/// Called when viewing mission blades, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool ShouldUpdateMissionSpawningInfo(StateObjectReference MissionRef)
{
	return false;
}

/// <summary>
/// Called when viewing mission blades, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool UpdateMissionSpawningInfo(StateObjectReference MissionRef)
{
	return false;
}

/// <summary>
/// Called when viewing mission blades, used to add any additional text to the mission description
/// </summary>
static function string GetAdditionalMissionDesc(StateObjectReference MissionRef)
{
	return "";
}

/// <summary>
/// Called from X2AbilityTag:ExpandHandler after processing the base game tags. Return true (and fill OutString correctly)
/// to indicate the tag has been expanded properly and no further processing is needed.
/// </summary>
static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	return false;
}

/// <summary>
/// Called from XComGameState_Unit:GatherUnitAbilitiesForInit after the game has built what it believes is the full list of
/// abilities for the unit based on character, class, equipment, et cetera. You can add or remove abilities in SetupData.
/// </summary>
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{

}

/// <summary>
/// Calls DLC specific popup handlers to route messages to correct display functions
/// </summary>
static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{

}

// -------------------------------------------------------------
// ------------ X2WOTCCommunityHighlander Additions ------------
// -------------------------------------------------------------

/// Start Issue #21
/// <summary>
/// Called from XComUnitPawn.DLCAppendSockets
/// Allows DLC/Mods to append sockets to units
/// </summary>
static function string DLCAppendSockets(XComUnitPawn Pawn)
{
	return "";
}
/// End Issue #21

/// Start Issue #24
/// <summary>
/// Called from XComUnitPawn.UpdateAnimations
/// CustomAnimSets will be added to the pawns animsets
/// </summary>
static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{

}
/// End Issue #24

/// Start Issue #18
/// <summary>
/// Calls DLC specific handlers to override spawn location
/// </summary>
static function bool GetValidFloorSpawnLocations(out array<Vector> FloorPoints, float SpawnSizeOverride, XComGroupSpawn SpawnPoint)
{
	return false;
}
/// End Issue #18


/// start Issue #50
/// <summary>
/// Called from XComGameState_Unit:CanAddItemToInventory & UIArmory_Loadout:GetDisabledReason
/// defaults to using the wrapper function below for calls from XCGS_U. Return false with a non-empty string in this function to show the disabled reason in UIArmory_Loadout
/// Note: due to how UIArmory_Loadout does its check, expect only Slot, ItemTemplate, and UnitState to be filled when trying to fill out a disabled reason. Hence the check for CheckGameState == none
/// </summary>
static function bool CanAddItemToInventory_CH(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason)
{
	if(CheckGameState == none)
		return false;

	return CanAddItemToInventory(bCanAddItem, Slot, ItemTemplate, Quantity, UnitState, CheckGameState);
}

/// <summary>
/// wrapper function: original function from base game LW/Community highlander
//  Return true to the actual DLC hook
/// </summary>
static private function bool CanAddItemToInventory(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	return false;
}

//end Issue #50

// Start Issue #64
/// <summary>
/// Called from XComGameState_Unit::RealizeNumUtilitySlots with what it believes is the number of utility slots it should have.
/// Mods can add to / remove from / overwrite the value of the out parameter
/// </summary>
static function ModifyNumUtilitySlots(out int iNumSlots, XComGameState_Unit UnitState, XComGameState NewGameState)
{

}
// End Issue #64
