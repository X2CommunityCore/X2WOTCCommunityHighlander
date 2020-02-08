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



//Start issue #647
/// <summary>
/// This method is run when the player loads a saved game directly into Tactical while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToTactical()
{

}
//#end issue #647

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

/// start Issue #114: added XComGameState_Item as something that can be passed down for disabled reason purposes
/// basically the inventory hook wtih an added paramter to pass through
/// we leave the old one alone for compatibility reasons, as we call it through here for those mods.
///
static function bool CanAddItemToInventory_CH_Improved(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason, optional XComGameState_Item ItemState)
{

	return CanAddItemToInventory_CH(bCanAddItem, Slot, ItemTemplate, Quantity, UnitState, CheckGameState, DisabledReason); //for mods not using item state, we can just by default, go straight to here. Newer mods can handle implementaion using the item state.
	
}
//end Issue #114

/// start Issue #50
/// <summary>
/// Called from XComGameState_Unit:CanAddItemToInventory & UIArmory_Loadout:GetDisabledReason
/// defaults to using the wrapper function below for calls from XCGS_U. Return false with a non-empty string in this function to show the disabled reason in UIArmory_Loadout
/// Note: due to how UIArmory_Loadout does its check, expect only Slot, ItemTemplate, and UnitState to be filled when trying to fill out a disabled reason. Hence the check for CheckGameState == none
/// </summary>
static function bool CanAddItemToInventory_CH(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason)
{
	if(CheckGameState == none)
		return true;

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

// Start Issue #171
/// Calls to override item image shown in UIArmory_Loadout
/// For example it allows you to show multiple grenades on grenade slot for someone with heavy ordnance
/// Just change the value of imagePath
static function OverrideItemImage(out array<string> imagePath, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, XComGameState_Unit UnitState)
{
}

/// Also Issue #64
/// Allows override number of utility slots
static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
}

/// Allows override number of heavy weapons slots
/// These are the only base game slots that can be safely unrestricted since they are optional and not expected by class perks, if you want other multi slots use the CHItemSlot feature
static function GetNumHeavyWeaponSlotsOverride(out int NumHeavySlots, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
}
// End Issue #171

//start Issue #112
/// <summary>
/// Called from XComGameState_HeadquartersXCom
/// lets mods add their own events to the event queue when the player is at the Avenger or the Geoscape
/// </summary>

static function bool GetDLCEventInfo(out array<HQEvent> arrEvents)
{
	return false; //returning true will tell the game to add the events have been added to the above array
}
//end issue #112

//start Issue #148
/// <summary>
/// Called from UIShellDifficulty
/// lets mods change the new game options when changing difficulty
/// </summary>
static function UpdateUIOnDifficultyChange(UIShellDifficulty UIShellDifficulty)
{

}
//end Issue #148


// Start Issue #136
/// <summary>
/// Called from XComGameState_MissionSite:CacheSelectedMissionData
/// Encounter Data is modified immediately prior to being added to the SelectedMissionData, ported from LW2
/// </summary>
static function PostEncounterCreation(out name EncounterName, out PodSpawnInfo Encounter, int ForceLevel, int AlertLevel, optional XComGameState_BaseObject SourceObject)
{

}
// End Issue #136

// Start Issue #278
/// <summary>
/// Called from XComGameState_AIReinforcementSpawner:OnReinforcementSpawnerCreated
/// SourceObject is the calling function's BattleData, as opposed to the original hook, which passes MissionSiteState. BattleData contains MissionSiteState
/// Added optional ReinforcementState to modify reinforcement conditions
/// Encounter Data is modified immediately after being generated, before validation is performed on spawn visualization based on pod conditions
/// </summary>
static function PostReinforcementCreation(out name EncounterName, out PodSpawnInfo Encounter, int ForceLevel, int AlertLevel, optional XComGameState_BaseObject SourceObject, optional XComGameState_BaseObject ReinforcementState)
{
	PostEncounterCreation(EncounterName, Encounter, ForceLevel, AlertLevel, `XCOMHISTORY.GetGameStateForObjectID(XComGameState_BattleData(SourceObject).m_iMissionID));
}
// End Issue #278

// Start Issue #157
/// <summary>
/// Called from XComGameState_Missionsite:SetMissionData
/// lets mods add SitReps with custom spawn rules to newly generated missions
/// Advice: Check for present Strategy game if you dont want this to affect TQL/Multiplayer/Main Menu 
/// Example: If (`HQGAME  != none && `HQPC != None && `HQPRES != none) ...
/// </summary>
static function PostSitRepCreation(out GeneratedMissionData GeneratedMission, optional XComGameState_BaseObject SourceObject)
{
	
}
// End Issue #157

// Start Issue #169
/// <summary>
/// Called from XComHumanPawn:UpdateMeshMaterials; lets mods manipulate pawn materials.
/// This hook is called for each standard attachment for each MaterialInstanceConstant.
/// Superseded by UpdateHumanPawnMeshComponent, which provides a more universal hook.
/// </summary>
static function UpdateHumanPawnMeshMaterial(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp, name ParentMaterialName, MaterialInstanceConstant MIC)
{

}
// End Issue #157

/// Start Issue #216
/// <summary>
/// Called from XComHumanPawn:UpdateMeshMaterials. This function acts as a wrapper for
/// UpdateHumanPawnMeshMaterial to still support that hook.
/// This hook is called after the base game has updated the materials on this mesh component:
/// - MaterialInstanceConstants will be "instancified" to make sure that pawns' materials don't conflict
/// - Materials / MaterialInstanceTimeVaryings will not be touched
/// </summary>
static function UpdateHumanPawnMeshComponent(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp)
{
	local int Idx;
	local MaterialInterface Mat, ParentMat;
	local MaterialInstanceConstant MIC, ParentMIC;
	local name ParentName;

	for (Idx = 0; Idx < MeshComp.GetNumElements(); ++Idx)
	{
		Mat = MeshComp.GetMaterial(Idx);
		MIC = MaterialInstanceConstant(Mat);

		if (MIC != none)
		{
			// Calling code has already "instancified" the MIC -- just make sure we find the correct parent
			ParentMat = MIC.Parent;
			while (!ParentMat.IsA('Material'))
			{
				ParentMIC = MaterialInstanceConstant(ParentMat);
				if (ParentMIC != none)
					ParentMat = ParentMIC.Parent;
				else
					break;
			}
			ParentName = ParentMat.Name;

			UpdateHumanPawnMeshMaterial(UnitState, Pawn, MeshComp, ParentName, MIC);
		}
	}
}
/// End Issue #216


/// Start Issue #239
/// <summary>
/// Called from SeqAct_GetPawnFromSaveData.Activated
/// It delegates the randomly chosen pawn, unitstate and gamestate from the shell screen matinee.
/// 
static function MatineeGetPawnFromSaveData(XComUnitPawn UnitPawn, XComGameState_Unit UnitState, XComGameState SearchState)
{}
/// End Issue #239

/// Start Issue #240
/// Called from XComGameState_Item:UpdateMeshMaterials:GetWeaponAttachments.
/// This function gets called when the weapon attachemets are loaded for an item.
static function UpdateWeaponAttachments(out array<WeaponAttachment> Attachments, XComGameState_Item ItemState)
{}
/// End Issue #240

/// Start Issue #245
/// Called from XGWeapon:Init.
/// This function gets called when the weapon archetype is initialized.
static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item ItemState=none)
{}
/// End Issue #245

/// Start Issue #246
/// Called from XGWeapon:UpdateWeaponMaterial.
/// This function gets called when the weapon material is updated.
static function UpdateWeaponMaterial(XGWeapon WeaponArchetype, MeshComponent MeshComp)
{}
/// End Issue #246

/// Start Issue #260
/// Called from XComGameState_Item:CanWeaponApplyUpgrade.
/// Allows weapons to specify whether or not they will accept a given upgrade.
/// Should be used to answer the question "is this upgrade compatible with this weapon in general?"
/// For whether or not other upgrades conflict or other "right now" concerns, X2WeaponUpgradeTemplate:CanApplyUpgradeToWeapon already exists
/// It is suggested you explicitly check for your weapon templates, so as not to accidentally catch someone else's templates.
/// - e.g. Even if you have a unique weapon category now, someone else may add items to that category later.
static function bool CanWeaponApplyUpgrade(XComGameState_Item WeaponState, X2WeaponUpgradeTemplate UpgradeTemplate)
{
	return true;
}
/// End Issue #260

/// Start Issue #281
/// <summary>
/// Called from XGWeapon.CreateEntity
/// Allows DLC/Mods to append sockets to weapons
/// NOTE: To create new sockets from script you need to unconst SocketName and BoneName in SkeletalMeshSocket
/// </summary>
/// HL-Docs: feature:DLCAppendWeaponSockets; issue:281; tags:misc
/// Allows mods to add sockets to the skeletal mesh of any weapon, which can be used to position visual weapon attachments,
/// using different position/scale of the same attachment's skeletal mesh for different weapons. Example use:
/// ```unrealscript
/// static function DLCAppendWeaponSockets(out array<SkeletalMeshSocket> NewSockets, XComWeapon Weapon, XComGameState_Item ItemState)
/// {
/// 	local SkeletalMeshSocket    Socket;
///     local vector                RelativeLocation;
/// 	local rotator				RelativeRotation;
/// 	local vector				RelativeScale;
/// 	local float					RAD_INTO_DEG;
///    
/// 	RAD_INTO_DEG = 182.0416f;	//	Local "constant"
/// 	
/// 	if (ItemState != none)
/// 	{
/// 		Socket = new class'SkeletalMeshSocket';
/// 
/// 		Socket.SocketName = 'NewSocket';
/// 		Socket.BoneName = 'root';
/// 
/// 		//	Location offsets are in Unreal Units; 1 unit is roughly equal to a centimeter.
/// 		RelativeLocation.X = 5;
/// 		RelativeLocation.Y = 10;
/// 		RelativeLocation.Z = 15;
/// 		Socket.RelativeLocation = RelativeLocation;
/// 
/// 		//	In code, socket rotation is recorded as an int value [-65536; 65536].
/// 		//	If we want to specify the rotation in degrees, the value must be converted.
/// 		RelativeRotation.Pitch = 5 * default.RAD_INTO_DEG;
/// 		RelativeRotation.Yaw = 10 * default.RAD_INTO_DEG;
/// 		RelativeRotation.Roll = 15 * default.RAD_INTO_DEG;
/// 		Socket.RelativeRotation = RelativeRotation;
/// 
/// 		//	Scaling a socket will scale any mesh attached to it.
/// 		RelativeScale.X = 0.25f;
/// 		RelativeScale.Y = 0.5f;
/// 		RelativeScale.Z = 1.0f;
/// 		Socket.RelativeScale = RelativeScale;
/// 
/// 		NewSockets.AddItem(Socket);
/// 	}
/// }
/// ```
static function DLCAppendWeaponSockets(out array<SkeletalMeshSocket> NewSockets, XComWeapon Weapon, XComGameState_Item ItemState)
{
	return;
}
/// End Issue #281

/// Start issue #412
/// Called before any X2DataSet is invoked, allowing to modify default properties
/// Warning: this is called quite early in startup process and not all game systems are bootstrapped yet (but all DLCs/mods are guranteed to be loaded)
static function OnPreCreateTemplates()
{
}
/// End issue #412

/// Start Issue #419
/// <summary>
/// Called from X2AbilityTag.ExpandHandler
/// Expands vanilla AbilityTagExpandHandler to allow reflection
/// </summary>
static function bool AbilityTagExpandHandler_CH(string InString, out string OutString, Object ParseObj, Object StrategyParseOb, XComGameState GameState)
{
	return false;
}

/// Start Issue #409
/// <summary>
/// Called from XComGameState_Unit:GetEarnedSoldierAbilities
/// Allows DLC/Mods to add to and modify a unit's EarnedSoldierAbilities
/// Has no return value, just modify the EarnedAbilities out variable array
static function ModifyEarnedSoldierAbilities(out array<SoldierClassAbilityType> EarnedAbilities, XComGameState_Unit UnitState)
{}
/// End Issue #409

// Start Issue #388
/// <summary>
/// Called from X2TacticalGameRuleset:state'CreateTacticalGame':UpdateTransitionMap / 
/// XComPlayerController:SetupDropshipMatinee for both PreMission/PostMission.
/// You may fill out the `OverrideMapName` parameter to override the transition map.
/// If `UnitState != none`, return whether this unit should have cosmetic attachments (gear) on the transition map.
/// </summary> 
static function bool LoadingScreenOverrideTransitionMap(optional out string OverrideMapName, optional XComGameState_Unit UnitState)
{
	return false;
}
// End Issue #388

// Start Issue #395
/// <summary>
/// Called from XComTacticalMissionManager:GetActiveMissionIntroDefinition before it returns the Default.
/// Notable changes from LW2: Called even if the mission/plot/plot type has an override.
/// OverrideType is -1 for default, 0 for Mission override, 1 for Plot override, 2 for Plot Type override.
/// OverrideTag contains the Mission name / Plot name / Plot type, respectively
/// Return true to use.
/// </summary>
static function bool UseAlternateMissionIntroDefinition(MissionDefinition ActiveMission, int OverrideType, string OverrideTag, out MissionIntroDefinition MissionIntro)
{
	return false;
}
// End Issue #395

/// Start Issue #455
/// <summary>
/// Called from XComUnitPawnNativeBase.PostInitAnimTree
/// Allows patching the animtree template before its initialized.
/// </summary>
static function UnitPawnPostInitAnimTree(XComGameState_Unit UnitState, XComUnitPawnNativeBase Pawn, SkeletalMeshComponent SkelComp)
{
	return;
}
/// End Issue #455

/// Start Issue #511
/// <summary>
/// Allowes mod to define dlc run order dependencies
/// RunPriorityGroup can be STANDARD = 0, FIRST = 1 or LAST = 2
/// Only change load priority if you really sure that its needed for you mod.
/// RunBefore and RunAfter only work within the defined LoadPriority group
///
/// Should be specified in the mods XComGame.ini like
/// [ModSafeName CHDLCRunOrder]
/// +RunBefore=...
/// +RunAfter=...
/// RunPriorityGroup=...
///
/// </summary>
final function array<string> GetRunBeforeDLCIdentifiers()
{
	local CHDLCRunOrder RunOrder;

	RunOrder = new(none, DLCIdentifier)class'CHDLCRunOrder';
	// Equivalent to empty array if not specified in config
	return RunOrder.RunBefore;
}

final function array<string> GetRunAfterDLCIdentifiers()
{
	local CHDLCRunOrder RunOrder;

	RunOrder = new(none, DLCIdentifier)class'CHDLCRunOrder';
	// Equivalent to empty array if not specified in config
	return RunOrder.RunAfter;
}

final function int GetRunPriorityGroup()
{
	local CHDLCRunOrder RunOrder;

	RunOrder = new(none, DLCIdentifier)class'CHDLCRunOrder';
	// Equivalent to RUN_STANDARD if not specified in config
	return RunOrder.RunPriorityGroup;
}
/// End Issue #511

/// Start Issue #524
/// <summary>
/// Allow mods to specify array of incompatible and required mod.
/// Should be specified in the mods XComGame.ini like
/// [ModSafeName CHModDependency]
/// +IncompatibleMods=...
/// +IgnoreIncompatibleMods=...
/// +RequiredMods=...
/// +IgnoreRequiredMods=...
/// DisplayName="..."
/// </summary>
final function array<string> GetIncompatibleDLCIdentifiers()
{
	local CHModDependency ModDependency;

	ModDependency = new(none, DLCIdentifier)class'CHModDependency';
	// Equivalent to empty array if not specified in config
	return ModDependency.IncompatibleMods;
}

final function array<string> GetIgnoreIncompatibleDLCIdentifiers()
{
	local CHModDependency ModDependency;

	ModDependency = new(none, DLCIdentifier)class'CHModDependency';
	// Equivalent to empty array if not specified in config
	return ModDependency.IgnoreIncompatibleMods;
}

final function array<string> GetRequiredDLCIdentifiers()
{
	local CHModDependency ModDependency;

	ModDependency = new(none, DLCIdentifier)class'CHModDependency';
	// Equivalent to empty array if not specified in config
	return ModDependency.RequiredMods;
}

final function array<string> GetIgnoreRequiredDLCIdentifiers()
{
	local CHModDependency ModDependency;

	ModDependency = new(none, DLCIdentifier)class'CHModDependency';
	// Equivalent to empty array if not specified in config
	return ModDependency.IgnoreRequiredMods;
}

final function string GetDisplayName()
{
	local CHModDependency ModDependency;

	ModDependency = new(none, DLCIdentifier)class'CHModDependency';
	// Equivalent to empty string if not specified in localization
	return ModDependency.DisplayName;
}
/// End Issue #524