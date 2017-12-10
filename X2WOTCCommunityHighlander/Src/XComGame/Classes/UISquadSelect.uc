//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: This file controls the squad select screen. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISquadSelect extends UIScreen
	config(UI);

const LIST_ITEM_PADDING = 6;

var int m_iSelectedSlot; // used when selecting a new soldier, set by UISquadSelect_UnitSlot
var int m_iSlotIndex;

var UISquadSelectMissionInfo m_kMissionInfo;
var UIList m_kSlotList;
var UILargeButton LaunchButton;

var UIPawnMgr m_kPawnMgr;
var XComGameState UpdateState;
var XComGameState_HeadquartersXCom XComHQ;
var array<XComUnitPawn> UnitPawns;
var SkeletalMeshActor Cinedummy;
var int SoldierSlotCount;

var bool bLaunched;

var bool bDirty;
var bool bNoCancel;
var bool bDisableEdit;
var bool bDisableDismiss;
var bool bDisableLoadout;

// Because game state changes happen when we call UpdateData, 
// we need to wait until the new XComHQ is created before adding Soldiers to the squad.
var StateObjectReference PendingSoldier; 

var localized string m_strLaunch;
var localized string m_strMission;
var localized string m_strStripGear;
var localized string m_strStripGearConfirm;
var localized string m_strStripGearConfirmDesc;
var localized string m_strStripWeapons;
var localized string m_strStripWeaponsConfirm;
var localized string m_strStripWeaponsConfirmDesc;
var localized string m_strStripItems;
var localized string m_strStripItemsConfirm;
var localized string m_strStripItemsConfirmDesc;
var localized string m_strBuildItems; 
var localized string m_strClearSquad;

var localized string m_strTooltipStripWeapons;
var localized string m_strTooltipStripGear;
var localized string m_strTooltipStripItems;
var localized string m_strTooltipNeedsSoldiers;
var localized string m_strTooltipBuildItems;

var string UIDisplayCam;
var string m_strPawnLocationIdentifier;

var array<int> SlotListOrder; //The slot list is not 0->n for cinematic reasons ( ie. 0th and 1st soldier are in a certain place )
var config int MaxDisplayedSlots; // The maximum number of slots displayed to the player on the screen
var config array<name> SkulljackObjectives; // Objectives which require a skulljack equipped
//Set this to 'true' before leaving screen, will set back to false on focus regain
var bool m_bNoRefreshOnLoseFocus;

// PI Added: Configure auto remove equipment. These have two different senses to ensure that all false values
// maintains baseline behavior.
var config bool NoStripWoundedInventory;	// If true, suppress the normal behavior of stripping utility items from wounded soldiers.
var config bool NoStripOnTraining;			// If true, suppress the normal behavior of stripping items when a soldier is put
											// in a training slot. Note that this is not referenced in this class but is 
											// added here for consistency and back-compatibility to keep related flags together.
var config bool AutoStripWoundedAllItems;	// If true, also strip other equipment slots on wounded soldiers.

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int listX, listWidth;
	local XComGameState NewGameState;
	local GeneratedMissionData MissionData;

	super.InitScreen(InitController, InitMovie, InitName);
	
	Navigator.HorizontalNavigation = true;

	m_kMissionInfo = Spawn(class'UISquadSelectMissionInfo', self).InitMissionInfo();
	m_kPawnMgr = Spawn( class'UIPawnMgr', Owner );

	// Enter Squad Select Event
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Enter Squad Select Event Hook");
	`XEVENTMGR.TriggerEvent('EnterSquadSelect', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	SoldierSlotCount = class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(MissionData.Mission);

	// Force only the max displayed slots to be created, even if more soldiers are allowed
	if (SoldierSlotCount > MaxDisplayedSlots)
		SoldierSlotCount = MaxDisplayedSlots;

	if (XComHQ.Squad.Length > SoldierSlotCount)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Squad size adjustment from mission parameters");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.Squad.Length = SoldierSlotCount;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	listWidth = GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + LIST_ITEM_PADDING);
	listX = Clamp((Movie.UI_RES_X / 2) - (listWidth / 2), 10, Movie.UI_RES_X / 2);

	//m_kSlotList = Spawn(class'UIList', self);
	m_kSlotList = Spawn(class'UIList_SquadEditor', self);
	m_kSlotList.InitList('', listX, -435, Movie.UI_RES_X - 20, 310, true).AnchorBottomLeft();
	m_kSlotList.itemPadding = LIST_ITEM_PADDING;

	`XSTRATEGYSOUNDMGR.PlaySquadSelectMusic();

	bDisableEdit = class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M3_WelcomeToHQ') == eObjectiveState_InProgress;
	bDisableDismiss = bDisableEdit; // disable both buttons for now
	bDisableLoadout = false;

	//Make sure the kismet variables are up to date
	WorldInfo.MyKismetVariableMgr.RebuildVariableMap();

	UpdateData(true);
	UpdateNavHelp();
	UpdateMissionInfo();

	LaunchButton = Spawn(class'UILargeButton', self);
	LaunchButton.bAnimateOnInit = false;

	if( `ISCONTROLLERACTIVE )
	{
		LaunchButton.InitLargeButton(,class'UIUtilities_Text'.static.InjectImage(
				class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -13) @ m_strLaunch @ m_strMission,, OnLaunchMission);
	}
	else
	{
		LaunchButton.InitLargeButton(, m_strMission, m_strLaunch, OnLaunchMission);
	}

	LaunchButton.AnchorBottomRight();
	LaunchButton.DisableNavigation();
	LaunchButton.ShowBG(true);

	if (MissionData.Mission.AllowDeployWoundedUnits)
	{
		`HQPRES.UIWoundedSoldiersAllowed();
	}

	//Delay by a slight amount to let pawns configure. Otherwise they will have Giraffe heads.
	SetTimer(0.1f, false, nameof(StartPreMissionCinematic));
	XComHeadquartersController(`HQPRES.Owner).SetInputState('None');
}

function StartPreMissionCinematic()
{
	`GAME.GetGeoscape().m_kBase.SetPreMissionSequenceVisibility(true);

	//Link the cinematic pawns to the matinee	
	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true);

	Hide();

	WorldInfo.RemoteEventListeners.AddItem(self);
	GotoState('Cinematic_PawnsWalkingUp');

	`XCOMGRI.DoRemoteEvent('CIN_HideArmoryStaff'); //Hide the staff in the armory so tha tthey don't overlap with the soldiers

	`XCOMGRI.DoRemoteEvent('PreM_Begin');
}

event OnRemoteEvent(name RemoteEventName)
{
	local int i, j;
	local UISquadSelect_ListItem ListItem, SelectedListItem;

	super.OnRemoteEvent(RemoteEventName);

	// Only show screen if we're at the top of the state stack
	if(RemoteEventName == 'PreM_LineupUI' && `SCREENSTACK.GetCurrentScreen() == self)
	{
		Show();
		UpdateNavHelp();

		SelectedListItem = UIList_SquadEditor(m_kSlotList).GetActiveListItem();
		// Animate the slots in from left to right
		for(i = 0; i < SlotListOrder.Length; ++i)
		{
			for(j = 0; j < m_kSlotList.ItemCount; ++j)
			{
				ListItem = UISquadSelect_ListItem(m_kSlotList.GetItem(j));
				if(ListItem.bIsVisible && ListItem.SlotIndex == SlotListOrder[i])
				{
					ListItem.AnimateIn(float(i));
					if( `ISCONTROLLERACTIVE )
					{
					if(SelectedListItem == ListItem)
						ListItem.RefreshFocus();

					//disabling Navigators because the system doesn't work well with the mouse-highlight based navigation system on the PC-version
					Navigator.Clear();
					}
				}
			}
		}
	}
	else if(RemoteEventName == 'PreM_Exit')
	{
		GoToGeoscape();
	}
	else if(RemoteEventName == 'PreM_StartIdle' || RemoteEventName == 'PreM_SwitchToLineup')
	{
		GotoState('Cinematic_PawnsIdling');
	}
	else if(RemoteEventName == 'PreM_SwitchToSoldier')
	{
		GotoState('Cinematic_PawnsCustomization');
	}
	else if(RemoteEventName == 'PreM_StopIdle_S2')
	{
		GotoState('Cinematic_PawnsWalkingAway');    
	}		
	else if(RemoteEventName == 'PreM_CustomizeUI_Off')
	{
		UpdateData();
	}
}

simulated function UpdateData(optional bool bFillSquad)
{
	local XComGameStateHistory History;
	local int i;
	local int SlotIndex;	//Index into the list of places where a soldier can stand in the after action scene, from left to right
	local int SquadIndex;	//Index into the HQ's squad array, containing references to unit state objects
	local int ListItemIndex;//Index into the array of list items the player can interact with to view soldier status and promote

	local UISquadSelect_ListItem ListItem;
	local XComGameState_Unit UnitState;
	local XComGameState_MissionSite MissionState;
	local GeneratedMissionData MissionData;
	local bool bAllowWoundedSoldiers, bSpecialSoldierFound;
	local array<name> RequiredSpecialSoldiers;

	History = `XCOMHISTORY;
	ClearPawns();

	// update list positioning in case the number of total slots has changed since init was called
	//<workshop> This is handled in the UIList_SquadEditor.uc at InitPosition() - JTA 2016/2/22
	//DEL:
	//ListWidth = GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + LIST_ITEM_PADDING);
	//ListX = Clamp((Movie.UI_RES_X / 2) - (ListWidth / 2), 10, Movie.UI_RES_X / 2);
	//m_kSlotList.SetX(ListX); //this is definitely causing the problems
	//</workshop>

	// get existing states
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	bAllowWoundedSoldiers = MissionData.Mission.AllowDeployWoundedUnits;
	RequiredSpecialSoldiers = MissionData.Mission.SpecialSoldiers;
	
	// add a unit to the squad if there is one pending
	if (PendingSoldier.ObjectID > 0 && m_iSelectedSlot != -1)
		XComHQ.Squad[m_iSelectedSlot] = PendingSoldier;

	// if this mission requires special soldiers, check to see if they already exist in the squad
	if (RequiredSpecialSoldiers.Length > 0)
	{
		for (i = 0; i < RequiredSpecialSoldiers.Length; i++)
		{
			bSpecialSoldierFound = false;
			for (SquadIndex = 0; SquadIndex < XComHQ.Squad.Length; SquadIndex++)
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[SquadIndex].ObjectID));
				if (UnitState != none && UnitState.GetMyTemplateName() == RequiredSpecialSoldiers[i])
				{
					bSpecialSoldierFound = true;
					break;
				}
			}

			if (!bSpecialSoldierFound)
				break; // If a special soldier is missing, break immediately and reset the squad
		}

		// If no special soldiers are found, clear the squad, search for them, and add them
		if (!bSpecialSoldierFound)
		{
			UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add special soldier to squad");
			XComHQ = XComGameState_HeadquartersXCom(UpdateState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Squad.Length = 0;

			foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				// If this unit is one of the required special soldiers, add them to the squad
				if (RequiredSpecialSoldiers.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
				{
					UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
					
					// safety catch: somehow Central has no appearance in the alien nest mission. Not sure why, no time to figure it out - dburchanowski
					if(UnitState.GetMyTemplate().bHasFullDefaultAppearance && UnitState.kAppearance.nmTorso == '')
					{
						`Redscreen("Special Soldier " $ UnitState.ObjectID $ " with template " $ UnitState.GetMyTemplateName() $ " has no appearance, restoring default!");
						UnitState.kAppearance = UnitState.GetMyTemplate().DefaultAppearance;
					}

					UpdateState.AddStateObject(UnitState);
					UnitState.ApplyBestGearLoadout(UpdateState); // Upgrade the special soldier to have the best possible gear
					
					if (XComHQ.Squad.Length < SoldierSlotCount) // Only add special soldiers up to the squad limit
					{
						XComHQ.Squad.AddItem(UnitState.GetReference());
					}
				}
			}

			StoreGameStateChanges();
		}
	}

	// fill out the squad as much as possible
	if(bFillSquad)
	{
		// create change states
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fill Squad");
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		for(i = 0; i < SoldierSlotCount; i++)
		{
			if(XComHQ.Squad.Length == i || XComHQ.Squad[i].ObjectID == 0)
			{
				UnitState = XComHQ.GetBestDeployableSoldier(true, bAllowWoundedSoldiers);

				if(UnitState != none)
					XComHQ.Squad[i] = UnitState.GetReference();
			}
		}
		StoreGameStateChanges();

		SkulljackEvent();
	}

	// This method iterates all soldier templates and empties their backpacks if they are not already empty
	BlastBackpacks();

	// Everyone have their Xpad?
	ValidateRequiredLoadouts();

	// Clear Utility Items from wounded soldiers inventory
	if (!bAllowWoundedSoldiers)
	{
		MakeWoundedSoldierItemsAvailable();
	}

	// create change states
	CreatePendingStates();

	// Add slots in the list if necessary. 
	while( m_kSlotList.itemCount < GetTotalSlots() )
	{
		ListItem = UISquadSelect_ListItem(m_kSlotList.CreateItem(class'UISquadSelect_ListItem').InitPanel());
	}

	ListItemIndex = 0;

	// Disable first and last slots if user hasn't purchased upgrades to use them yet
	if(ShowExtraSlot1() && !UnlockedExtraSlot1())
		UISquadSelect_ListItem(m_kSlotList.GetItem(ListItemIndex++)).DisableSlot();

	if(ShowExtraSlot2() && !UnlockedExtraSlot2())
		UISquadSelect_ListItem(m_kSlotList.GetItem(m_kSlotList.ItemCount - 1)).DisableSlot();

	// HAX: If we show one extra slot, we add the other slot and hide it to keep the list aligned with the pawns - sbatista
	if(ShowExtraSlot1() && !ShowExtraSlot2())
 		UISquadSelect_ListItem(m_kSlotList.GetItem(m_kSlotList.ItemCount - 1)).Hide();
	
	for (SlotIndex = 0; SlotIndex < SlotListOrder.Length; ++SlotIndex)
	{
		SquadIndex = SlotListOrder[SlotIndex];

		// The slot list may contain more information/slots than available soldiers, so skip if we're reading outside the current soldier availability. 
		if (SquadIndex >= SoldierSlotCount)
			continue;

		if (SquadIndex < XComHQ.Squad.length && XComHQ.Squad[SquadIndex].ObjectID > 0)
		{
			if (UnitPawns[SquadIndex] != none)
			{
				//m_kPawnMgr.ReleaseCinematicPawn(self, UnitPawns[SquadIndex].ObjectID);
				m_kPawnMgr.ReleaseCinematicPawn(self, XComHQ.Squad[SquadIndex].ObjectID);
			}

			UnitPawns[SquadIndex] = CreatePawn(XComHQ.Squad[SquadIndex], SquadIndex);
		}

		// We want the slots to match the visual order of the pawns in the slot list.
		ListItem = UISquadSelect_ListItem(m_kSlotList.GetItem(ListItemIndex));
		if(ListItem.bDirty)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[SquadIndex].ObjectID));
			if (RequiredSpecialSoldiers.Length > 0 && UnitState != none && RequiredSpecialSoldiers.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
				ListItem.UpdateData(SquadIndex, true, true, false, UnitState.GetSoldierClassTemplate().CannotEditSlots); // Disable customization or removing any special soldier required for the mission
			else
				ListItem.UpdateData(SquadIndex, bDisableEdit, bDisableDismiss, bDisableLoadout);
		}
		++ListItemIndex;
	}

	StoreGameStateChanges();
	bDirty = false;

	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	if (MissionState.GetMissionSource().RequireLaunchMissionPopupFn != none && MissionState.GetMissionSource().RequireLaunchMissionPopupFn(MissionState))
	{
		// If the mission source requires a unique launch mission warning popup which has not yet been displayed, show it now
		if (!MissionState.bHasSeenLaunchMissionWarning)
		{
			`HQPRES.UILaunchMissionWarning(MissionState);
		}
	}
}

simulated function SkulljackEvent()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;
	local bool bSkullJackObjective;

	bSkullJackObjective = false;

	for(idx = 0; idx < default.SkulljackObjectives.Length; idx++)
	{
		if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus(default.SkulljackObjectives[idx]) == eObjectiveState_InProgress)
		{
			bSkullJackObjective = true;
			break;
		}
	}

	if(bSkullJackObjective)
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		for(idx = 0; idx < XComHQ.Squad.Length; idx++)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

			if(UnitState != None)
			{
				if(UnitState.HasItemOfTemplateType('SKULLJACK'))
				{
					return;
				}
			}
		}

		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Blast Backpack and MissionItems");
		`XEVENTMGR.TriggerEvent('NeedToEquipSkulljack', , , UpdateState);
		`GAMERULES.SubmitGameState(UpdateState);
	}
}

// Function to avoid a duping issue that occurs only in final release builds, was hack but should stay for safety anyway
simulated function BlastBackpacks()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> Items;
	local int iCrew;

	History = `XCOMHISTORY;
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Blast Backpack and MissionItems");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for (iCrew = 0; iCrew < XComHQ.Crew.Length; iCrew++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[iCrew].ObjectID));

		if (UnitState != None && UnitState.IsSoldier())
		{
			UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', XComHQ.Crew[iCrew].ObjectID));
			UpdateState.AddStateObject(UnitState);

			Items = UnitState.GetAllItemsInSlot(eInvSlot_Backpack, UpdateState);
			foreach Items(ItemState)
			{
				UnitState.RemoveItemFromInventory(ItemState, UpdateState);
			}
		}
	}

	if (UpdateState.GetNumGameStateObjects() > 0)
	{
		`GAMERULES.SubmitGameState(UpdateState);
	}
	else
	{
		History.CleanupPendingGameState(UpdateState);
	}
}

// Make sure everyone has their xpads
simulated function ValidateRequiredLoadouts()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Validate Required Loadouts");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if (UnitState != None && UnitState.IsSoldier() && 
			UnitState.GetMyTemplate().RequiredLoadout != '' && !UnitState.HasLoadout(UnitState.GetMyTemplate().RequiredLoadout))
		{
			UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UpdateState.AddStateObject(UnitState);
			UnitState.ApplyInventoryLoadout(UpdateState, UnitState.GetMyTemplate().RequiredLoadout);
		}
	}

	if (UpdateState.GetNumGameStateObjects() > 0)
	{
		`GAMERULES.SubmitGameState(UpdateState);
	}
	else
	{
		History.CleanupPendingGameState(UpdateState);
	}
}

simulated function MakeWoundedSoldierItemsAvailable()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local int idx;

	// PI Added: INI setting to prevent wounded soldiers from having their equipment stripped.
	if (NoStripWoundedInventory)
	{
		return;
	}

	History = `XCOMHISTORY;
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Make Wounded Soldier Items Available");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	RelevantSlots.AddItem(eInvSlot_Utility);
	RelevantSlots.AddItem(eInvSlot_GrenadePocket);
	RelevantSlots.AddItem(eInvSlot_AmmoPocket);

	// PI Added: new INI setting to strip *all* slots from wounded soldiers.
	if (AutoStripWoundedAllItems)
	{
		RelevantSlots.AddItem(eInvSlot_Armor);
		RelevantSlots.AddItem(eInvSlot_PrimaryWeapon);
		RelevantSlots.AddItem(eInvSlot_SecondaryWeapon);
		RelevantSlots.AddItem(eInvSlot_HeavyWeapon);
		RelevantSlots.AddItem(eInvSlot_TertiaryWeapon);
		RelevantSlots.AddItem(eInvSlot_QuaternaryWeapon);
		RelevantSlots.AddItem(eInvSlot_QuinaryWeapon);
		RelevantSlots.AddItem(eInvSlot_SenaryWeapon);
		RelevantSlots.AddItem(eInvSlot_SeptenaryWeapon);
	}

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != None && UnitState.IsSoldier() && ((UnitState.IsInjured() && !UnitState.IgnoresInjuries()) || UnitState.IsTraining()))
		{
			UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UpdateState.AddStateObject(UnitState);
			UnitState.MakeItemsAvailable(UpdateState, false, RelevantSlots);
		}
	}

	`GAMERULES.SubmitGameState(UpdateState);
}

simulated function CreatePendingStates()
{
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Squad Selection");
	XComHQ = XComGameState_HeadquartersXCom(UpdateState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	local XComHeadquartersCheatManager CheatMgr;

	LaunchButton.SetDisabled(!CanLaunchMission());
	LaunchButton.SetTooltipText(GetTooltipText());

	if( `HQPRES != none )
	{
		NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
		CheatMgr = XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager);
		NavHelp.ClearButtonHelp();
	
		if( !bNoCancel )
			NavHelp.AddBackButton(CloseScreen);

		if(`ISCONTROLLERACTIVE)
			NavHelp.AddSelectNavHelp();

		if(CheatMgr == none || !CheatMgr.bGamesComDemo)
		{
			NavHelp.AddCenterHelp(m_strStripItems, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LT_L2,
				OnStripItems, false, m_strTooltipStripItems);
			NavHelp.AddCenterHelp(m_strStripGear, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RT_R2,
				OnStripGear, false, m_strTooltipStripGear);
		}

		if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M5_WelcomeToEngineering'))
		{

			NavHelp.AddCenterHelp(m_strBuildItems, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, 
				OnBuildItems, false, m_strTooltipBuildItems);
		}

		// Re-enabling this option for Steam builds to assist QA testing, TODO: disable this option before release
`if(`notdefined(FINAL_RELEASE))
		if(CheatMgr == none || !CheatMgr.bGamesComDemo)
		{
			NavHelp.AddCenterHelp("SIM COMBAT", class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_BACK_SELECT,
				OnSimCombat, !CanLaunchMission(), GetTooltipText());
		}	
`endif
	}
}

simulated function PausePsiOperativeTraining()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	for (idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

		if (UnitState.GetStatus() == eStatus_PsiTraining)
		{
			UnitState.GetStaffSlot().EmptySlotStopProject();
		}
	}
}

simulated function AddHiddenSoldiersToSquad(int NumSoldiersToAdd)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local GeneratedMissionData MissionData;
	local bool bAllowWoundedSoldiers, bSquadModified;
	local int idx;
	
	History = `XCOMHISTORY;
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Extra Hidden Soldiers to Squad");

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(UpdateState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	UpdateState.AddStateObject(XComHQ);

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	bAllowWoundedSoldiers = MissionData.Mission.AllowDeployWoundedUnits;
	
	// add extra soldiers to the squad if possible
	for (idx = MaxDisplayedSlots; idx < (MaxDisplayedSlots + NumSoldiersToAdd); idx++)
	{
		if (XComHQ.Squad.Length == idx || XComHQ.Squad[idx].ObjectID == 0)
		{
			UnitState = XComHQ.GetBestDeployableSoldier(true, bAllowWoundedSoldiers);
			
			if (UnitState != none)
			{
				UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				UpdateState.AddStateObject(UnitState);
				UnitState.ApplyBestGearLoadout(UpdateState);
				XComHQ.Squad[idx] = UnitState.GetReference();
				bSquadModified = true;
			}
		}
	}
	
	if (bSquadModified)
	{
		`GAMERULES.SubmitGameState(UpdateState);
	}
	else
	{
		History.CleanupPendingGameState(UpdateState);
	}
}

simulated function string GetTooltipText()
{
	local XComGameState_MissionSite MissionState;

	if(CanLaunchMission())
		return "";

	if(!HasEnoughSoldiers())
		return m_strTooltipNeedsSoldiers;
	
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	if (MissionState.GetMissionSource().CanLaunchMissionFn != none && !MissionState.GetMissionSource().CanLaunchMissionFn(MissionState))
	{
		return MissionState.GetMissionSource().CannotLaunchMissionTooltip;
	}
}

simulated function OnStripItems()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = m_strStripItemsConfirm;
	DialogData.strText = m_strStripItemsConfirmDesc;
	DialogData.fnCallback = OnStripItemsDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
}
simulated function OnStripItemsDialogCallback(eUIAction eAction)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	if(eAction == eUIAction_Accept)
	{
		History = `XCOMHISTORY;
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Items");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		UpdateState.AddStateObject(XComHQ);
		Soldiers = XComHQ.GetSoldiers(true);

		RelevantSlots.AddItem(eInvSlot_Utility);
		RelevantSlots.AddItem(eInvSlot_GrenadePocket);
		RelevantSlots.AddItem(eInvSlot_AmmoPocket);

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UpdateState.AddStateObject(UnitState);
			UnitState.MakeItemsAvailable(UpdateState, false, RelevantSlots);
		}

		`GAMERULES.SubmitGameState(UpdateState);
	}
	UpdateNavHelp();
}

simulated function OnStripGear()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = m_strStripGearConfirm;
	DialogData.strText = m_strStripGearConfirmDesc;
	DialogData.fnCallback = OnStripGearDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}
simulated function OnStripGearDialogCallback(eUIAction eAction)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	if(eAction == eUIAction_Accept)
	{
		History = `XCOMHISTORY;
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Items");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		UpdateState.AddStateObject(XComHQ);
		Soldiers = XComHQ.GetSoldiers(true);

		RelevantSlots.AddItem(eInvSlot_Armor);
		RelevantSlots.AddItem(eInvSlot_HeavyWeapon);

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UpdateState.AddStateObject(UnitState);
			UnitState.MakeItemsAvailable(UpdateState, false, RelevantSlots);
		}

		`GAMERULES.SubmitGameState(UpdateState);
	}
	UpdateNavHelp();
}

simulated function OnStripWeapons()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = m_strStripWeaponsConfirm;
	DialogData.strText = m_strStripWeaponsConfirmDesc;
	DialogData.fnCallback = OnStripWeaponsDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}
simulated function OnStripWeaponsDialogCallback(eUIAction eAction)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	if (eAction == eUIAction_Accept)
	{
		History = `XCOMHISTORY;
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Items");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		UpdateState.AddStateObject(XComHQ);
		Soldiers = XComHQ.GetSoldiers(true);

		RelevantSlots.AddItem(eInvSlot_PrimaryWeapon);
		RelevantSlots.AddItem(eInvSlot_SecondaryWeapon);
		RelevantSlots.AddItem(eInvSlot_HeavyWeapon);

		for (idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UpdateState.AddStateObject(UnitState);
			UnitState.MakeItemsAvailable(UpdateState, false, RelevantSlots);
		}

		`GAMERULES.SubmitGameState(UpdateState);
	}
	UpdateNavHelp();
}

simulated function OnBuildItems()
{
	// This is a screen jump, but NOT a hotlink, so we DO NOT clear down to the HUD. 
	bDirty = true; // Force a refresh of the pawns when you come back, in case the user purchased new weapons or armor
	if(UIList_SquadEditor(m_kSlotList) != None)
	{
		UIList_SquadEditor(m_kSlotList).MarkAllListItemsAsDirty(); //Necessary for possible upgrades to weapons that affect all soldiers
	}	

	// Make sure the camera is set since we are leaving
	SnapCamera();

	// Wait a frame for camera set to complete
	SetTimer(0.1f, false, nameof(GoToBuildItemScreen));
}

simulated function GoToBuildItemScreen()
{
	`HQPRES.UIBuildItem();
}

simulated function UpdateMissionInfo()
{
	local XComGameState NewGameState;
	local GeneratedMissionData MissionData;
	local XComGameState_MissionSite MissionState;
	
	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	
	m_kMissionInfo.UpdateData(MissionData.BattleOpName, 
		MissionState.GetMissionObjectiveText(), 
		MissionState.GetMissionDifficultyLabel(), 
		MissionState.GetRewardAmountString());

	if (MissionState.GetMissionSource().DataName == 'MissionSource_Broadcast')
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Enter Squad Select Event Hook for Broadcast");
		`XEVENTMGR.TriggerEvent('EnterSquadSelectBroadcast', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

simulated function ChangeSlot(optional StateObjectReference UnitRef)
{
	local bool PrevCanLaunchMission;
	local StateObjectReference PrevUnitRef;
	local XComGameState_MissionSite MissionState;

	// Make sure we create the update state before changing XComHQ
	if(UpdateState == none)
		CreatePendingStates();

	PrevUnitRef = XComHQ.Squad[m_iSelectedSlot];

	// remove modifications to previous selected unit
	if(PrevUnitRef.ObjectID > 0)
	{
		UpdateState.PurgeGameStateForObjectID(PrevUnitRef.ObjectID);
		m_kPawnMgr.ReleaseCinematicPawn(self, PrevUnitRef.ObjectID);
	}

	// we need to create a new XComHQ before adding this unit to the squad (done in UpdateData)
	PendingSoldier = UnitRef;
	
	// update state of "launch" button if it needs to change
	PrevCanLaunchMission = CanLaunchMission();
	
	XComHQ.Squad[m_iSelectedSlot] = UnitRef;

	StoreGameStateChanges();

	if(PrevCanLaunchMission != CanLaunchMission())
		UpdateNavHelp();

	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	if (MissionState.GetMissionSource().RequireLaunchMissionPopupFn != none && MissionState.GetMissionSource().RequireLaunchMissionPopupFn(MissionState))
	{
		// If the mission source requires a unique launch mission warning popup which has not yet been displayed, show it now
		if (!MissionState.bHasSeenLaunchMissionWarning)
		{
			`HQPRES.UILaunchMissionWarning(MissionState);
		}
	}
	
	if(PrevUnitRef.ObjectID == 0)
	{

		UpdateData();
		
		if (UnitPawns[m_iSelectedSlot] != none)
			m_kPawnMgr.ReleaseCinematicPawn(self, UnitPawns[m_iSelectedSlot].ObjectID);

		UnitPawns[m_iSelectedSlot] = CreatePawn(UnitRef, m_iSelectedSlot);
	}
}


simulated function OnSimCombat()
{
	local XGStrategy StrategyGame;
	local GeneratedMissionData MissionData;
	local int MaxSoldiers;

	if(CanLaunchMission())
	{
		MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
		MaxSoldiers = class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(MissionData.Mission);
		if (MaxSoldiers > MaxDisplayedSlots)
		{
			// Need to add extra soldiers to our squad before the mission starts
			AddHiddenSoldiersToSquad(MaxSoldiers - MaxDisplayedSlots);
		}

		PausePsiOperativeTraining();

		bLaunched = true;
		StrategyGame = `GAME;
		StrategyGame.SimCombatNextMission = true;
		CloseScreen();
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

simulated function OnLaunchMission(UIButton Button)
{
	local GeneratedMissionData MissionData;
	local int MaxSoldiers;

	if(CanLaunchMission())
	{
		MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
		MaxSoldiers = class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(MissionData.Mission);
		if (MaxSoldiers > MaxDisplayedSlots)
		{
			// Need to add extra soldiers to our squad before the mission starts
			AddHiddenSoldiersToSquad(MaxSoldiers - MaxDisplayedSlots);
		}

		PausePsiOperativeTraining();

		bLaunched = true;
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);		
		CloseScreen();
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

simulated function CloseScreen()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_MissionSite MissionState;
	local GeneratedMissionData MissionData;
	local array<name> RequiredSpecialSoldiers;
	local int idx;

	// Strategy map has its own button help
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	Hide();

	if (bLaunched)
	{
		MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
		if(!MissionState.GetMissionSource().bRequiresSkyrangerTravel)
		{
			// Play special departure if mission is Avenger Defense - commented out until sequence is properly hooked up
			`XCOMGRI.DoRemoteEvent('PreM_GoToAvengerDefense');
		}
		else
		{
			`XCOMGRI.DoRemoteEvent('PreM_GoToDeparture');
		}
	}
	else
	{
		`XCOMGRI.DoRemoteEvent('PreM_Cancel');

		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
		RequiredSpecialSoldiers = MissionData.Mission.SpecialSoldiers;

		// If special soldiers are required on this mission and they were placed in the squad, remove them
		if (RequiredSpecialSoldiers.Length > 0)
		{
			History = `XCOMHISTORY;
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove special soldier from squad");
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			NewGameState.AddStateObject(XComHQ);
			
			for (idx = 0; idx < XComHQ.Squad.Length; idx++)
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));
				if (UnitState != none && RequiredSpecialSoldiers.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
				{					
					XComHQ.Squad[idx].ObjectID = 0;					
				}
			}
			
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

function OnVolunteerMatineeIsVisible(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_a');
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_Hallway', none, OnVolunteerMatineeComplete);
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_b');
	CheckForFinalMissionLaunch();
}

function OnVolunteerMatineeComplete()
{
	`MAPS.RemoveStreamingMapByName("CIN_TP_Dark_Volunteer_pt2_Hallway_Narr", false);
}

function GoToGeoscape()
{	
	local StateObjectReference EmptyRef;
	local XComGameState_MissionSite MissionState;

	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	if(bLaunched)
	{
		if(MissionState.GetMissionSource().DataName == 'MissionSource_Final')
		{
			`MAPS.AddStreamingMap("CIN_TP_Dark_Volunteer_pt2_Hallway_Narr", vect(0, 0, 0), Rot(0, 0, 0), true, false, true, OnVolunteerMatineeIsVisible);
			return;
		}
		else if(!MissionState.GetMissionSource().bRequiresSkyrangerTravel) //Some missions, like avenger defense, may not require the sky ranger to go anywhere
		{			
			MissionState.ConfirmMission();
		}
		else
		{
			MissionState.SquadSelectionCompleted();
		}
	}
	else
	{
		XComHQ.MissionRef = EmptyRef;
		MissionState.SquadSelectionCancelled();
		`XSTRATEGYSOUNDMGR.PlayGeoscapeMusic();
	}

	`XCOMGRI.DoRemoteEvent('CIN_UnhideArmoryStaff'); //Show the armory staff now that we are done

	Movie.Stack.Pop(self);
}

function CheckForFinalMissionLaunch()
{
	local UINarrativeMgr Manager;
	local XComGameState_MissionSite MissionState;

	Manager = `HQPRES.m_kNarrativeUIMgr;
	if(Manager.m_arrConversations.Length == 0 && Manager.PendingConversations.Length == 0)
	{
		MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
		MissionState.ConfirmMission();
	}
	else
	{
		SetTimer(0.1f, false, nameof(CheckForFinalMissionLaunch), self);
	}
}

simulated function SnapCamera()
{
	`HQPRES.CAMLookAtNamedLocation(UIDisplayCam, 0);
}

simulated function OnReceiveFocus()
{
	//Don't reset the camera during the launch sequence.
	//This case occurs, for example, when closing the "reconnect controller" dialog.
	//INS:
	if(bLaunched)
		return;
	SnapCamera();

	super.OnReceiveFocus();
	m_bNoRefreshOnLoseFocus = false;

	UpdateNavHelp();

	if(bDirty) 
	{
		UpdateData();
	}
}

simulated function OnLoseFocus()
{
	local LocalPlayer LP;

	LP = class'UIInteraction'.static.GetLocalPlayer(0);
	if(!m_bNoRefreshOnLoseFocus && UIList_SquadEditor(m_kSlotList) != None && LP.ControllerID != -1)
	{
		bDirty = true;
				
		//marks the active listitem as 'dirty' so it will be forced to refresh when the screen gains focus again
		if(class'XComGameState_HeadquartersXCom'.static.NeedsToEquipMedikitTutorial())
			UIList_SquadEditor(m_kSlotList).MarkAllListItemsAsDirty(); //Tutorial modifies ALL listitems, so a full refresh is needed
		else
			UIList_SquadEditor(m_kSlotList).MarkActiveListItemAsDirty();
	}
	
	super.OnLoseFocus();
	StoreGameStateChanges(); // need to save the state of the screen when we leave it

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!bIsVisible)
	{
		return true;
	}
	
	if (bLaunched)
	{
		return false;
	}

	if (IsTimerActive(nameof(GoToBuildItemScreen)))
	{
		return false;
	}
	if ( m_kSlotList.OnUnrealCommand(cmd, arg) )
		return true;
		
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if(!bIsVisible)
		return true;

	bHandled = true;
	switch( cmd )
	{

		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			if(!bNoCancel)
			{
				CloseScreen();
				Movie.Pres.PlayUISound(eSUISound_MenuClose);
			}
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:
			OnStripItems();
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:
			OnStripGear();
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M5_WelcomeToEngineering'))
			{
				OnBuildItems();
			}
			break;

`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_BUTTON_SELECT:
			OnSimCombat();
			break;
`endif

		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			OnLaunchMission(LaunchButton);
			break;
			
		case class'UIUtilities_Input'.const.FXS_BUTTON_START: //Re-enabled this case for consistency, since we're not using start to launch anymore - BET 2016-06-23
			`HQPRES.UIPauseMenu( ,true );
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnRemoved()
{
	super.OnRemoved();
	ClearPawns();
	`GAME.GetGeoscape().m_kBase.SetPreMissionSequenceVisibility(false);
}

//------------------------------------------------------

simulated function bool CanLaunchMission()
{
	local XComGameState_MissionSite MissionState;
	
	if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress)
	{
		return false;
	}
	
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	if (MissionState.GetMissionSource().CanLaunchMissionFn != none && !MissionState.GetMissionSource().CanLaunchMissionFn(MissionState))
	{
		return false;
	}

	return HasEnoughSoldiers();
}

simulated function bool HasEnoughSoldiers()
{
	local int i;

	// make sure there's at least one unit in the squad
	for(i = 0; i < XComHQ.Squad.Length; ++i)
	{
		if(XComHQ.Squad[i].ObjectID > 0)
			return true;
	}

	return false;
}

simulated function bool ShowExtraSlot1()
{
	local GeneratedMissionData MissionData;

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);

	if (MissionData.Mission.AllowDeployWoundedUnits)
		return false;
	else if (MissionData.Mission.MaxSoldiers > 0 && MissionData.Mission.MaxSoldiers < class'X2StrategyGameRulesetDataStructures'.default.m_iMaxSoldiersOnMission)
		return false;
	else
		return XComHQ.HasFacilityByName('OfficerTrainingSchool') || XComHQ.HighestSoldierRank >= 3; // sergeant
}

simulated function bool ShowExtraSlot2()
{
	local GeneratedMissionData MissionData;

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);

	if (MissionData.Mission.AllowDeployWoundedUnits)
		return false;
	else if (MissionData.Mission.MaxSoldiers > 0 && MissionData.Mission.MaxSoldiers < class'X2StrategyGameRulesetDataStructures'.default.m_iMaxSoldiersOnMission)
		return false;
	else
		return XComHQ.HasFacilityByName('OfficerTrainingSchool') || XComHQ.HighestSoldierRank >= 5; // captain
}

simulated function bool UnlockedExtraSlot1()
{
	return XComHQ.SoldierUnlockTemplates.Find('SquadSizeIUnlock') != INDEX_NONE;
}

simulated function bool UnlockedExtraSlot2()
{
	return XComHQ.SoldierUnlockTemplates.Find('SquadSizeIIUnlock') != INDEX_NONE;
}

simulated function int GetTotalSlots()
{
	local int Result;

	Result = SoldierSlotCount;

	if(ShowExtraSlot1() && !UnlockedExtraSlot1()) Result++;
	if(ShowExtraSlot2() && !UnlockedExtraSlot2()) Result++;

	// HAX: If we show one extra slot, add the other slot to keep the list aligned with the pawns (it gets hidden in UpdateData) - sbatista
	if(ShowExtraSlot1() && !ShowExtraSlot2()) Result++;

	return Result;
}

simulated function StoreGameStateChanges()
{
	local int i;
	local bool bSquadChanged;
	local XComGameState_HeadquartersXCom PrevHQState;
	local XComGameStateHistory History;

	if(UpdateState == none)
		CreatePendingStates();

	History = `XCOMHISTORY;
	
	PendingSoldier.ObjectID = 0;
	bSquadChanged = false;
	PrevHQState = XComGameState_HeadquartersXCom(History.GetGameStateForObjectID(XComHQ.ObjectID));

	if(PrevHQState.Squad.Length != XComHQ.Squad.Length)
	{
		bSquadChanged = true;
	}
	else
	{
		for(i = 0; i < PrevHQState.Squad.Length; ++i)
		{
			if(PrevHQState.Squad[i].ObjectID != XComHQ.Squad[i].ObjectID)
			{
				bSquadChanged = true;
				break;
			}
		}
	}

	if(bSquadChanged)
	{
		UpdateState.AddStateObject(XComHQ);
		`GAMERULES.SubmitGameState(UpdateState);
	}
	else
		History.CleanupPendingGameState(UpdateState);

	UpdateState = none;
}

simulated function SetGremlinMatineeVariable(name GremlinName, XComUnitPawn GremlinPawn)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	WorldInfo.MyKismetVariableMgr.GetVariable(GremlinName, OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(None);
			SeqVarPawn.SetObjectValue(GremlinPawn);
		}
	}
}

simulated function XComUnitPawn CreatePawn(StateObjectReference UnitRef, int index)
{
	local name LocationName;
	local PointInSpace PlacementActor;
	local XComGameState_Unit UnitState;
	local XComUnitPawn UnitPawn, GremlinPawn;
	local array<AnimSet> GremlinHQAnims;

	LocationName = name(m_strPawnLocationIdentifier $ index);
	foreach WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if(PlacementActor != none && PlacementActor.Tag == LocationName)
			break;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));		
	UnitPawn = m_kPawnMgr.RequestCinematicPawn(self, UnitRef.ObjectID, PlacementActor.Location, PlacementActor.Rotation, name("Soldier"$(index + 1)), '', true);
	UnitPawn.GotoState('CharacterCustomization');

	UnitPawn.CreateVisualInventoryAttachments(m_kPawnMgr, UnitState, , , false); // spawn weapons and other visible equipment

	GremlinPawn = m_kPawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
	if (GremlinPawn != none)
	{
		SetGremlinMatineeVariable(name("Gremlin"$(index + 1)), GremlinPawn);
		GremlinPawn.SetLocation(PlacementActor.Location);
		GremlinPawn.SetRotation(PlacementActor.Rotation);

		GremlinHQAnims.AddItem(AnimSet'HQ_ANIM.Anims.AS_Gremlin');
		GremlinPawn.XComAddAnimSetsExternal(GremlinHQAnims);
	}

	return UnitPawn;
}

simulated function ClearPawns()
{
	local XComUnitPawn UnitPawn;
	foreach UnitPawns(UnitPawn)
	{
		if(UnitPawn != none)
		{
			m_kPawnMgr.ReleaseCinematicPawn(self, UnitPawn.ObjectID);
		}
	}
}

//Clears the entire squad
simulated function ClearSquad()
{
	local int i, PrevSelectedIndex;
	local UISquadSelect_ListItem ListItem;
	local UIList_SquadEditor SquadList;

	if(XComHQ != None && !XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ'))
		return;	

	SquadList = UIList_SquadEditor(m_kSlotList);
	if(SquadList == None)
		return;
	else `log("List must be a 'UIList_SquadEditor' to use this function");

	//used later to return focus back to where it started
	PrevSelectedIndex = SquadList.GetItemIndex(SquadList.GetActiveListItem());

	//cycles through each list item and simulates a 'dismiss' button click
	for(i = 0; i < m_kSlotList.ItemCount; i++)
	{
		ListItem = UISquadSelect_ListItem(m_kSlotList.GetItem(i));
		if(ListItem != None && !ListItem.bDisabled)
		{
			ListItem.OnLoseFocus();
			ListItem.OnClickedDismissButton();
		}
	}

	//Sets focus back to where it started
	//The list items will refresh after a short delay (that exists to give actionscript time to process the animations)	
	ListItem = UISquadSelect_ListItem(SquadList.GetItem(PrevSelectedIndex));
	if(ListItem != None)
	{
		ListItem.OnReceiveFocus();
	}
}
simulated function int GetSlotIndexForUnit(StateObjectReference UnitRef)
{
	local int SlotIndex;	//Index into the list of places where a soldier can stand in the after action scene, from left to right
	local int SquadIndex;	//Index into the HQ's squad array, containing references to unit state objects

	for(SlotIndex = 0; SlotIndex < SlotListOrder.Length; ++SlotIndex)
	{
		SquadIndex = SlotListOrder[SlotIndex];
		if(SquadIndex < XComHQ.Squad.Length)
		{
			if(XComHQ.Squad[SquadIndex].ObjectID == UnitRef.ObjectID)
				return SlotIndex;
		}
	}

	return -1;
}

state Cinematic_PawnControl
{
	//Similar to the after action report, the characters walk up to the camera
	function StartPawnAnimation(name AnimState, name GremlinAnimState)
	{
		local int PawnIndex;
		local XComGameState_Unit UnitState;
		local StateObjectReference UnitRef;
		local XComGameStateHistory History;
		local X2SoldierPersonalityTemplate PersonalityData;
		local XComHumanPawn HumanPawn;
		local XComUnitPawn Gremlin;
	
		History = `XCOMHISTORY;

		if(Cinedummy == none)
		{
			foreach WorldInfo.AllActors(class'SkeletalMeshActor', Cinedummy)
			{
				if(Cinedummy.Tag == 'Cin_PreMission1_Cinedummy')
					break;
			}
		}

		for(PawnIndex = 0; PawnIndex < XComHQ.Squad.Length; ++PawnIndex)
		{
			UnitRef = XComHQ.Squad[PawnIndex];
			if(UnitRef.ObjectID > 0)
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
				PersonalityData = UnitState.GetPersonalityTemplate();

				UnitPawns[PawnIndex].EnableFootIK(true);			

				if('SquadLineup_Walkaway' == AnimState)
				{
					UnitPawns[PawnIndex].SetHardAttach(true);
					UnitPawns[PawnIndex].SetBase(Cinedummy);

					//RAM - this combination of flags is necessary to correct an update order issue between the characters, the lift, and their body parts.
					UnitPawns[PawnIndex].SetTickGroup(TG_PostAsyncWork);
					UnitPawns[PawnIndex].Mesh.bForceUpdateAttachmentsInTick = false;
				}

				HumanPawn = XComHumanPawn(UnitPawns[PawnIndex]);
				if(HumanPawn != none)
				{
					HumanPawn.GotoState(AnimState);

					Gremlin = m_kPawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
					if (Gremlin != none && GremlinAnimState != '' && !Gremlin.IsInState(GremlinAnimState))
					{
						Gremlin.SetLocation(HumanPawn.Location);
						Gremlin.GotoState(GremlinAnimState);
					}
				}
				else
				{
					//If not human, just play the idle
					UnitPawns[PawnIndex].PlayFullBodyAnimOnPawn(PersonalityData.IdleAnimName, true);
				}
			}
		}
	}
}

//During the after action report, the characters walk up to the camera - this state represents that time
state Cinematic_PawnsWalkingUp extends Cinematic_PawnControl
{
	simulated event BeginState(name PreviousStateName)
	{
		StartPawnAnimation('SquadLineup_Walkup', 'Gremlin_WalkUp');
	}
}

state Cinematic_PawnsCustomization extends Cinematic_PawnControl
{
	simulated event BeginState(name PreviousStateName)
	{
		StartPawnAnimation('CharacterCustomization', '');		
	}
}

state Cinematic_PawnsIdling extends Cinematic_PawnControl
{
	simulated event BeginState(name PreviousStateName)
	{
		if(IsVisible() && Movie.Pres.ScreenStack.IsInStack(self.Class) && !bDirty)
		{
			SnapCamera();
		}

		StartPawnAnimation('CharacterCustomization', 'Gremlin_Idle');
	}
}

state Cinematic_PawnsWalkingAway extends Cinematic_PawnControl
{
	simulated event BeginState(name PreviousStateName)
	{		
		StartPawnAnimation('SquadLineup_Walkaway', 'Gremlin_WalkBack');
	}
}

DefaultProperties
{
	Package   = "/ package/gfxSquadList/SquadList";

	bCascadeFocus = false;
	bHideOnLoseFocus = true;
	bAutoSelectFirstNavigable = false;
	InputState = eInputState_Consume;

	m_strPawnLocationIdentifier = "PreM_UIPawnLocation_SquadSelect_";
	UIDisplayCam = "PreM_UIDisplayCam_SquadSelect";

	//Refer to the points / camera setup in CIN_PreMission to understand this array
	SlotListOrder[0] = 4
	SlotListOrder[1] = 1
	SlotListOrder[2] = 0
	SlotListOrder[3] = 2
	SlotListOrder[4] = 3
	SlotListOrder[5] = 5
}
