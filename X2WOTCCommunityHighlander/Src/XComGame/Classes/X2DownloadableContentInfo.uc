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

//Start issue #647
/// <summary>
/// This method is run when the player loads a saved game directly into Tactical while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToTactical()
{

}
//#end issue #647

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

// Start Issue #962
/// HL-Docs: feature:OverrideItemImage_Improved; issue:962; tags:
/// The `OverrideItemImage_Improved` X2DLCInfo method is called from `XComGameState_Item::GetWeaponPanelImages()`.
/// It allows mods to conditionally override item's inventory image. 
/// It can be used to replace the original image entirely
/// or to overlay an additional icon on top of it to mark the specific item.
/// To do so replace the contents of the `imagePath` array or add more image paths to it.
static function OverrideItemImage_Improved(out array<string> imagePath, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, XComGameState_Unit UnitState, const XComGameState_Item ItemState)
{
	OverrideItemImage(imagePath, Slot, ItemTemplate, UnitState);
}
// End Issue #962

// Start Issue #171
/// Calls to override item image shown in UI.
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
/// HL-Docs: feature:GetNumHeavyWeaponSlotsOverride; issue:171; tags:loadoutslots,strategy
/// The `GetNumHeavyWeaponSlotsOverride()` X2DLCInfo method allows mods to override 
/// the base game logic that determines how many Heavy Weapon Slots a Unit has.
/// To do so, simply interact with the `NumHeavySlots` argument by increasing,
/// decreasing or setting its value directly.
/// Note that this X2DLCInfo method is executed 
/// after the [OverrideHasHeavyWeapon](../strategy/OverrideHasHeavyWeapon.md) event, and may override its result.
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

/// HL-Docs: feature:UpdateHumanPawnMeshMaterial; issue:169; tags:customization,pawns
///
/// Adds a DLC hook to update a given material applied to a human pawn mesh component
/// that can be used to set custom parameters on materials.
///
/// ```unrealscript
/// static function UpdateHumanPawnMeshMaterial(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp, name ParentMaterialName, MaterialInstanceConstant MIC);
/// ```
///
/// This is called by [`UpdateHumanPawnMeshComponent`](UpdateHumanPawnMeshComponent.md) if not overridden.
/// `UpdateHumanPawnMeshComponent` allows more control over the materials, like being able to use
/// `MaterialInstanceTimeVarying` or outright replacing materials.
///
/// The following simplified example is taken from the [Warhammer 40,000: Armours of the Imperium](https://steamcommunity.com/sharedfiles/filedetails/?id=1562717298)
/// mod. Its armor uses custom material names *and* requires that the eye color is passed to the material using
/// `EmissiveColor` instead of `EyeColor`:
///
/// ```unrealscript
/// static function UpdateHumanPawnMeshMaterial(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp, name ParentMaterialName, MaterialInstanceConstant MIC)
/// {
/// 	local XComLinearColorPalette Palette;
/// 	local LinearColor ParamColor;
///
/// 	if (MaterialInstanceConstant(MIC.Parent).Name == 'Mat_SpaceMarine_Eyes')
/// 	{
/// 		Palette = `CONTENT.GetColorPalette(ePalette_EyeColor);
/// 		ParamColor = Palette.Entries[Pawn.m_kAppearance.iEyeColor].Primary;
/// 		MIC.SetVectorParameterValue('EmissiveColor', ParamColor);
/// 	}
/// }
/// ```
///
/// Note that a subset of this functionality (specifically if the material parameter names match) can
/// be implemented with config only (no code) using the [`TintMaterialConfigs`](TintMaterialConfigs.md) feature.

/// <summary>
/// Called from XComHumanPawn:UpdateMeshMaterials; lets mods manipulate pawn materials.
/// This hook is called for each standard attachment for each MaterialInstanceConstant.
/// </summary>
static function UpdateHumanPawnMeshMaterial(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp, name ParentMaterialName, MaterialInstanceConstant MIC)
{

}
// End Issue #169

// Start Issue #216
/// HL-Docs: feature:UpdateHumanPawnMeshComponent; issue:216; tags:customization,pawns
///
/// Adds a DLC hook to update a given human pawn mesh component's materials.
///
/// ```unrealscript
/// static function UpdateHumanPawnMeshComponent(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp);
/// ```
///
/// This can be used to apply custom materials to meshes, or set custom parameters.
/// If not overridden, this calls [`UpdateHumanPawnMeshMaterial`](UpdateHumanPawnMeshMaterial.md) for every
/// MaterialInstanceConstant. Call `super.UpdateHumanPawnMeshComponent(UnitState, Pawn, MeshComp);` if you
/// rely on both hooks.

/// <summary>
/// Called from XComHumanPawn:UpdateMeshMaterials. This function acts as a wrapper for
/// UpdateHumanPawnMeshMaterial to still support that hook.
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
// End Issue #216


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
/// HL-Docs: feature:DLCAppendWeaponSockets; issue:281; tags:pawns
/// Allows mods to add, move and rescale sockets on the skeletal mesh of any weapon, which can be used to position visual weapon attachments,
/// using different position/scale of the same attachment's skeletal mesh for different weapons. Example use:
/// ```unrealscript
/// static function DLCAppendWeaponSockets(out array<SkeletalMeshSocket> NewSockets, XComWeapon Weapon, XComGameState_Item ItemState)
/// {
/// 	local SkeletalMeshSocket    Socket;
///     local vector                RelativeLocation;
/// 	local rotator				RelativeRotation;
/// 	local vector				RelativeScale;   
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
/// 		//	Socket rotation is recorded as an int value [-65535; 65535], which corresponds with [-360 degrees; 360 degrees]
/// 		//	If we want to specify the rotation in degrees, the value must be converted using DegToUnrRot, a const in the Object class.
/// 		RelativeRotation.Pitch = 5 * DegToUnrRot;	//	Pitch of five degrees.
/// 		RelativeRotation.Yaw = 10 * DegToUnrRot;
/// 		RelativeRotation.Roll = 15 * DegToUnrRot;
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
///
/// Sockets that have the name of an existing socket will replace the original socket. This can be used to move, rotate,
/// and rescale existing sockets.
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
/// </summary>
/// HL-Docs: feature:ModifyEarnedSoldierAbilities; issue:409; tags:
/// This allows mods to add to or otherwise modify earned abilities for units.
/// For example, the Officer Pack can use this to attach learned officer abilities to the unit.
///
/// Note: abilities added this way will **not** be picked up by `XComGameState_Unit::HasSoldierAbility()`
///
/// Elements of the `EarnedAbilities` array are structs of type `SoldierClassAbilityType`.
/// Each element has the following parameters:
///  * AbilityName - template name of the ability that should be added to the unit.
///  * ApplyToWeaponSlot - inventory slot of the item that this ability should be attached to.
/// Being attached to the correct item is critical for abilities that rely on the source item, 
/// for example abilities that deal damage of the weapon they are attached to.
/// * UtilityCat - used only if `ApplyToWeaponSlot = eInvSlot_Utility`. Optional. 
/// If specified, the ability will be initialized for the unit when they enter tactical combat 
/// only if they have a weapon with the specified weapon category in one of their utility slots.
///
///```unrealscript
/// local SoldierClassAbilityType NewAbility;
///
/// NewAbility.AbilityName = 'PrimaryWeapon_AbilityTemplateName';
/// NewAbility.ApplyToWeaponSlot = eInvSlot_Primary;
///
/// EarnedAbilities.AddItem(NewAbility);
///
/// NewAbility.AbilityName = 'UtilityItem_AbilityTemplateName';
/// NewAbility.ApplyToWeaponSlot = eInvSlot_Utility;
/// NewAbility.UtilityCat = 'UtilityItemWeaponCategory';
///
/// EarnedAbilities.AddItem(NewAbility);
///```
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

// Start Issue #783
// <summary>
/// Called from XGCharacterGenerator:CreateTSoldier
/// Has no return value, just modify the CharGen.kSoldier directly.
/// HL-Docs: feature:ModifyGeneratedUnitAppearance; issue:783; tags:customization,compatibility
/// ## Usage
/// This DLC hook allows mods to make arbitrary changes to unit appearance 
/// after it has been generated by `XGCharacterGenerator::CreateTSoldier()`.
/// The generated appearance is stored in `CharGen.kSoldier.kAppearance`, which you can modify directly.
///
/// Other arguments are provided to for reference, as they were given to the `CreateTSoldier()` function.
///
/// The UnitState and the GameState will be passed to this hook 
/// only if the `CreateTSoldier()` function was called from `CreateTSoldierFromUnit()`, 
/// which normally happens only in the Shell code (TQL / Challenge Mode / Character Pool),
/// and will be `none` otherwise.
///
/// If you wish to "redo" some parts of the process of generating unit's appearance, 
/// you can call various methods in the Character Generator, 
/// but you must avoid calling the `CreateTSoldier()` and `CreateTSoldierFromUnit()` methods,
/// as that will retrigger the hook, potentially causing an inception loop and crashing the game.
///
/// # Issue #1140 Addendum
/// This hook is triggered twice for faction heroes. 
/// Reapers and Templars run this hook the first time after initial character generation,
/// and the second time after their faction-specific country and class-specific nickname
/// have been generated.
/// Skirmishers additionally get their faction-specific name after the first time the hook is triggered.
///
/// ## Compatibility
/// Custom `XGCharacterGenerator` classes used by mods to generate appearance of custom units
/// can potentially interfere with the normal operation of this hook for themselves.
///
/// If the Character Generator implements a custom `CreateTSoldier()` function that
/// does not call `super.CreateTSoldier()`, then this DLC hook will not be called for that class.
///
/// If `super.CreateTSoldier()` *is* called, but the custom `CreateTSoldier()` function 
/// makes changes to the generated appearance afterwards, it can potentially override
/// changes made by this hook.
///
/// For best compatibility with this hook, mod-added `XGCharacterGenerator` classes
/// should avoid making any appearance changes after calling `super.CreateTSoldier()`.
/// Ideally, that function should not be overridden at all, and the Character Generator
/// should rely on overriding other methods called by `CreateTSoldier()` as much as possible.
// </summary>
static function ModifyGeneratedUnitAppearance(XGCharacterGenerator CharGen, const name CharacterTemplateName, const EGender eForceGender, const name nmCountry, const int iRace, const name ArmorName, XComGameState_Unit UnitState, XComGameState UseGameState)
{}
/// End Issue #783

// Start issue #808
/// HL-Docs: feature:OnLoadedSavedGameWithDLCExisting; issue:808; tags:
/// When loading a save the game makes a distinction between "existing" and "new" mods/DLCs.
/// The list of the "existing" mods is stored inside the save and is used as "source of truth" during the loading process.
/// 
/// First, the game checks if any of the "existing" mods are currently not active. If such exist, the player gets
/// the "missing mods" popup.
/// 
/// Then, the game checks whether any of the currently active mods are not listed as "existing". Such
/// mods are considered "new" and the `OnLoadedSavedGame` hook is called on their DLCInfos.
/// 
/// Finally, the "new" mods are marked as "existing" to prevent the previous step from occurring again the next
/// time the same campaign is loaded and to facilitate the popup, should any of them be removed.
/// 
/// The above process misses an important aspect - what happens if the mod is "existing" but wants to make
/// state changes before the save is loaded? An example use case would be adjusting existing campaigns due to
/// updates in the mod code. `OnLoadedSavedGameWithDLCExisting` fills that gap - it is called on the "existing"
/// mods every time a save is loaded.
///
/// Important note 1: `OnLoadedSavedGameWithDLCExisting` is exclusive with `OnLoadedSavedGame`. If the mod was just
/// added (it is "new") then only `OnLoadedSavedGame` will be called. On subsequent loads of saves from that
/// campaign (the mod is now "existing") only `OnLoadedSavedGameWithDLCExisting` will be called.
/// 
/// Important note 2: this (and the base game OnLoadedSavedGame) is called before the ruleset of the save is initialized.
/// This is great as any state changes done here will be picked up automatically (no need to refresh anything anywhere),
/// however it imposes several limitations:
///
/// 1. You cannot use `SubmitGameStateContext`/`SubmitGameState`. Use `XComGameStateHistory::AddGameStateToHistory` instead
/// 2. Event listener templates should be assumed as not registered
/// 3. In fact, due to (1), only `ELD_Immediate` listeners (that are registered on state objects) will be triggered.
///    Therefore, you are advised to not trigger any events at all.
///
/// If the above is too limiting for your use case, consider using `OnLoadedSavedGameToStrategy`/`OnLoadedSavedGameToTactical`,
/// which are called after the relevant listener templates are registered and most of the presentation has loaded.
///
/// Important note 3: in case the save is loaded mid-tactical, some strategy state objects will be **missing** from the history.
/// This is intended behaviour and you must account for it when using this hook. You can read more about it here: 
/// https://robojumper.github.io/too-real/history/#archived
///
/// Important note 4: the list of "existing" mods is not cleared when the mod is removed (in order to facilitate the popup).
/// This means that add -> save -> remove -> load -> save -> add -> load will trigger `OnLoadedSavedGameWithDLCExisting`
/// as the mod will be considered "existing". However, any state objects which are instances of class(es) added by the mod
/// **will be gone** as they will fail to deserialize when the save is loaded without the mod active. The only exception to
/// this is the "Remove Missing Mods" mod which removes the missing mods from the list of the "existing" ones. In that case,
/// the mod will be considered "new" (again).
///
/// *While any mod can potentially manipulate that list, the "Remove Missing Mods" mod is currently the only known way of
/// removing entries from said list*
///
/// Important note 5: the decision to consider a mod either "new" or "existing" is made using its `DLCName`.
/// See [`ModDependencyCheck`](./ModDependencyCheck.md) for an explanation.
static function OnLoadedSavedGameWithDLCExisting ()
{
}
// End issue #808
