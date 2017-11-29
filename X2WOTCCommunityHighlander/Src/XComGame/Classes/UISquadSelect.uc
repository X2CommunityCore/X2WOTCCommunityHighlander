//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: This file controls the squad select screen. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISquadSelect extends UIScreen
	config(UI)
	dependson(XComGameState_HeadquartersXCom);

const LIST_ITEM_PADDING = 6;

var int m_iSelectedSlot; // used when selecting a new soldier, set by UISquadSelect_UnitSlot
var int m_iSlotIndex;

var UISquadSelectMissionInfo m_kMissionInfo;
var UIList_SquadEditor m_kSlotList; // bsg-jrebar (5/18/17): It is never a List alone
var UILargeButton LaunchButton;

var UIPawnMgr m_kPawnMgr;
var XComGameState UpdateState;
var XComGameState_HeadquartersXCom XComHQ;
var array<XComUnitPawn> UnitPawns;
var SkeletalMeshActor Cinedummy;
var int SoldierSlotCount;
var int SquadCount;
var array<int> SquadMinimums;

var bool bLaunched;
var bool bReceivedWalkupEvent;
var bool bHasSeenWoundedNotice;
var bool bHasSeenStrongholdWarning;

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
var localized string m_strNextSquadLine1;
var localized string m_strNextSquadLine2;
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
var localized string m_strBoostSoldier;

var localized string m_strTooltipStripWeapons;
var localized string m_strTooltipStripGear;
var localized string m_strTooltipStripItems;
var localized string m_strTooltipNeedsSoldiers;
var localized string m_strTooltipBuildItems;
var localized string m_strTooltipBoostSoldier;
var localized string m_strTooltipSoldierAlreadyBoosted;
var localized string m_strTooltipNoSoldierToBoost;
var localized string m_strTooltipCantAffordBoost;
var localized string m_strBoostSoldierDialogTitle;
var localized string m_strBoostSoldierDialogText;

var string UIDisplayCam;
var string m_strPawnLocationIdentifier;

var array<int> SlotListOrder; //The slot list is not 0->n for cinematic reasons ( ie. 0th and 1st soldier are in a certain place )
var config int MaxDisplayedSlots; // The maximum number of slots displayed to the player on the screen
var config array<name> SkulljackObjectives; // Objectives which require a skulljack equipped
//Set this to 'true' before leaving screen, will set back to false on focus regain
var bool m_bNoRefreshOnLoseFocus;
var bool bBlockSkulljackEvent;

var bool bHasRankLimits;
var int MinRank;
var int MaxRank;

var bool bGearStrippedFromSoldiers;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int listX, listWidth;
	local XComGameState NewGameState;
	local GeneratedMissionData MissionData;
	local XComGameState_MissionSite MissionState;
	local X2SitRepTemplate SitRepTemplate;
	local XComNarrativeMoment SitRepNarrative;

	super.InitScreen(InitController, InitMovie, InitName);
	
	Navigator.HorizontalNavigation = true;

	m_kMissionInfo = Spawn(class'UISquadSelectMissionInfo', self).InitMissionInfo();
	m_kPawnMgr = Spawn(class'UIPawnMgr', Owner);
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);	
	MissionState = GetMissionState();

	SoldierSlotCount = class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(MissionState);
	SquadCount = MissionData.Mission.SquadCount;
	SquadMinimums = MissionData.Mission.SquadSizeMin;

	if (SquadCount == 0)
	{
		SquadCount = 1;
	}

	while (SquadMinimums.Length < SquadCount) // fill in minimums that don't exist with minimum's of 1
	{
		SquadMinimums.AddItem( 1 );
	}

	// Check for a SITREP template, used for possible narrative line
	if (MissionData.SitReps.Length > 0)
	{
		SitRepTemplate = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager().FindSitRepTemplate(MissionData.SitReps[0]);
		
		if (SitRepTemplate.DataName == 'TheHorde')
		{
			// Do not trigger a skulljack event on these missions, since no ADVENT will spawn
			bBlockSkulljackEvent = true;
		}
	}

	// Enter Squad Select Event
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Enter Squad Select Event Hook");
	`XEVENTMGR.TriggerEvent('EnterSquadSelect', , , NewGameState);	
	if (IsRecoveryBoostAvailable())
	{
		`XEVENTMGR.TriggerEvent('OnRecoveryBoostSquadSelect', , , NewGameState);
	}

	if (MissionData.Mission.MissionName == 'LostAndAbandonedA')
	{
		`XEVENTMGR.TriggerEvent('OnLostAndAbandonedSquadSelect', , , NewGameState);
	}
	else if (MissionData.Mission.MissionName == 'ChosenAvengerDefense')
	{
		`XEVENTMGR.TriggerEvent('OnAvengerAssaultSquadSelect', , , NewGameState);
	}
	else if (SitRepTemplate != none && SitRepTemplate.SquadSelectNarrative != "" && !MissionState.bHasPlayedSITREPNarrative)
	{
		SitRepNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(SitRepTemplate.SquadSelectNarrative));
		if (SitRepNarrative != None)
		{
			`HQPRES.UINarrative(SitRepNarrative);
		}

		MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
		MissionState.bHasPlayedSITREPNarrative = true;
	}
	else if (SoldierSlotCount <= 3)
	{
		`XEVENTMGR.TriggerEvent('OnSizeLimitedSquadSelect', , , NewGameState);
	}
	else if (SoldierSlotCount > 5 && SquadCount > 1)
	{
		`XEVENTMGR.TriggerEvent('OnSuperSizeSquadSelect', , , NewGameState);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Force only the max displayed slots to be created, even if more soldiers are allowed
	if (SoldierSlotCount > MaxDisplayedSlots)
		SoldierSlotCount = MaxDisplayedSlots;

	if (XComHQ.Squad.Length > SoldierSlotCount || XComHQ.AllSquads.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Squad size adjustment from mission parameters");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.Squad.Length = SoldierSlotCount;
		XComHQ.AllSquads.Length = 0;
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
	UpdateSitRep();

	CreateOrUpdateLaunchButton();
	
	//Delay by a slight amount to let pawns configure. Otherwise they will have Giraffe heads.
	SetTimer(0.1f, false, nameof(StartPreMissionCinematic));
	XComHeadquartersController(`HQPRES.Owner).SetInputState('None');
}

// bsg-jrebar (5/16/17): Select First item and lose/gain focus on first list item
simulated function OnInit()
{
	super.OnInit();

	SetTimer(0.2f, false, nameof(SelectFirstListItem));
}

simulated function SelectFirstListItem()
{
	if(m_kSlotList.GetItemCount() <= 0 || !m_kSlotList.GetItem(0).bIsInited)
	{
		SetTimer(0.2f, false, nameof(SelectFirstListItem)); // Keep trying till we are inited
	}

	if(m_kSlotList != none)
	{
		m_kSlotList.OnLoseFocus(); // Deselect and unvis the whole list
		m_kSlotList.SelectFirstListItem(); // reselect the selection but go through the lose and receive loop
		m_kSlotList.OnReceiveFocus(); // refocus the list and its selection
	}
}
// bsg-jrebar (5/16/17): end

function CreateOrUpdateLaunchButton()
{
	local string SingleLineLaunch;
	
	// TTP14257 - loc is locked down, so, I'm making the edit. No space in Japanese. -bsteiner 
	if( GetLanguage() == "JPN" )
		SingleLineLaunch = m_strNextSquadLine1 $ m_strNextSquadLine2;
	else 
		SingleLineLaunch = m_strNextSquadLine1 @ m_strNextSquadLine2;

	if(LaunchButton == none)
	{
		LaunchButton = Spawn(class'UILargeButton', self);
		LaunchButton.bAnimateOnInit = false;
	}

	if(XComHQ.AllSquads.Length < (SquadCount - 1))
	{
		if( `ISCONTROLLERACTIVE )
		{
			LaunchButton.InitLargeButton(,class'UIUtilities_Text'.static.InjectImage(
					class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -10) @ SingleLineLaunch,, OnNextSquad);
		}
		else
		{
			LaunchButton.InitLargeButton(, m_strNextSquadLine2, m_strNextSquadLine1, OnNextSquad);
		}

		LaunchButton.SetDisabled(false); //bsg-hlee (05.12.17): The button should not be disabled if set to OnNextSquad function.
	}
	else
	{
		if( `ISCONTROLLERACTIVE )
		{
			LaunchButton.InitLargeButton(,class'UIUtilities_Text'.static.InjectImage(
					class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -10) @ m_strLaunch @ m_strMission,, OnLaunchMission);
		}
		else
		{
			LaunchButton.InitLargeButton(, m_strMission, m_strLaunch, OnLaunchMission);
		}
	}

	LaunchButton.AnchorBottomRight();
	LaunchButton.DisableNavigation();
	LaunchButton.ShowBG(true);

	UpdateNavHelp();
}

function StartPreMissionCinematic()
{
	//bsg-jneal (5.10.17): wait to start the cinematics until we are focused back on the screen
	if(!bIsFocused)
	{
		SetTimer(0.1f, false, nameof(StartPreMissionCinematic));
		return;
	}
	//bsg-jneal (5.10.17): end

	`GAME.GetGeoscape().m_kBase.SetPreMissionSequenceVisibility(true);

	//Link the cinematic pawns to the matinee	
	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true);

	Hide();
	UpdateNavHelp(); // bsg-jneal (4.4.17): force a navhelp update to correctly fix wide icon sizing issues when first entering squad select

	WorldInfo.RemoteEventListeners.AddItem(self);
	GotoState('Cinematic_PawnsWalkingUp');

	`XCOMGRI.DoRemoteEvent('CIN_HideArmoryStaff'); //Hide the staff in the armory so tha tthey don't overlap with the soldiers

	`XCOMGRI.DoRemoteEvent('PreM_Begin');
}

function CheckForWalkupAlerts()
{
	local GeneratedMissionData MissionData;

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	if( !bHasSeenWoundedNotice && MissionData.Mission.AllowDeployWoundedUnits )
	{
		`HQPRES.UIWoundedSoldiersAllowed();
		bHasSeenWoundedNotice = true;
	}

	if (!bHasSeenStrongholdWarning && (MissionData.Mission.MissionName == 'ChosenStrongholdShort' || MissionData.Mission.MissionName == 'ChosenStrongholdLong'))
	{
		`HQPRES.UIStrongholdMissionWarning();
		bHasSeenStrongholdWarning = true;
	}
}

event OnRemoteEvent(name RemoteEventName)
{
	local int i, j;
	local UISquadSelect_ListItem ListItem, SelectedListItem;

	super.OnRemoteEvent(RemoteEventName);

	// Only show screen if we're at the top of the state stack
	if(RemoteEventName == 'PreM_LineupUI' && 
		(`SCREENSTACK.GetCurrentScreen() == self || `SCREENSTACK.GetCurrentScreen().IsA('UIAlert') || `SCREENSTACK.IsCurrentClass(class'UIRedScreen') || `SCREENSTACK.HasInstanceOf(class'UIProgressDialogue'))) //bsg-jneal (5.10.17): allow remote events to call through even with dialogues up
	{
		bReceivedWalkupEvent = true; 
		CheckForWalkupAlerts();

		Show();
		UpdateNavHelp();

		SelectedListItem = m_kSlotList.GetActiveListItem();
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
	
	MissionState = GetMissionState();
	bHasRankLimits = MissionState.HasRankLimits(MinRank, MaxRank);

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
			XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Squad.Length = 0;

			foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				// If this unit is one of the required special soldiers, add them to the squad
				if (RequiredSpecialSoldiers.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
				{
					UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
					
					// safety catch: somehow Central has no appearance in the alien nest mission. Not sure why, no time to figure it out - dburchanowski
					if(UnitState.GetMyTemplate().bHasFullDefaultAppearance && UnitState.kAppearance.nmTorso == '')
					{
						`Redscreen("Special Soldier " $ UnitState.ObjectID $ " with template " $ UnitState.GetMyTemplateName() $ " has no appearance, restoring default!");
						UnitState.kAppearance = UnitState.GetMyTemplate().DefaultAppearance;
					}

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
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		// Remove tired soldiers from the squad, and remove soldiers that don't fit the rank limits (if they exist)
		for(i = 0; i < XComHQ.Squad.Length; i++)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));

			if(UnitState != none && (UnitState.GetMentalState() != eMentalState_Ready || 
				(bHasRankLimits && (UnitState.GetRank() < MinRank || UnitState.GetRank() > MaxRank))))
			{
				XComHQ.Squad[i].ObjectID = 0;
			}
		}

		for(i = 0; i < SoldierSlotCount; i++)
		{
			if(XComHQ.Squad.Length == i || XComHQ.Squad[i].ObjectID == 0)
			{
				if(bHasRankLimits)
				{
					UnitState = XComHQ.GetBestDeployableSoldier(true, bAllowWoundedSoldiers, MinRank, MaxRank);
				}
				else
				{
					UnitState = XComHQ.GetBestDeployableSoldier(true, bAllowWoundedSoldiers);
				}

				if(UnitState != none)
					XComHQ.Squad[i] = UnitState.GetReference();
			}
		}
		StoreGameStateChanges();

		TriggerEventsForWillStates();

		if (!bBlockSkulljackEvent)
		{
			SkulljackEvent();
		}
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
	
	UnitPawns.Length = SoldierSlotCount;
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

simulated function TriggerEventsForWillStates()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local int idx;
		
	History = `XCOMHISTORY;

	for (idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

		if (UnitState != None)
		{
			if (UnitState.GetMentalState() == eMentalState_Shaken)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Shaken Soldier on Squad Select");
				`XEVENTMGR.TriggerEvent('OnShakenSoldierSquadSelect', , , NewGameState);
				`GAMERULES.SubmitGameState(NewGameState);
			}
			else if (UnitState.GetMentalState() == eMentalState_Tired)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tired Soldier on Squad Select");
				`XEVENTMGR.TriggerEvent('OnTiredSoldierSquadSelect', , , NewGameState);
				`GAMERULES.SubmitGameState(NewGameState);
			}
		}
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
			UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', XComHQ.Crew[iCrew].ObjectID));

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
			UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
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
	local bool bIgnoreInjuries;
	local int idx;

	History = `XCOMHISTORY;
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Make Wounded Soldier Items Available");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	RelevantSlots.AddItem(eInvSlot_Utility);
	RelevantSlots.AddItem(eInvSlot_GrenadePocket);
	RelevantSlots.AddItem(eInvSlot_AmmoPocket);

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));
		
		// If the Resistance Order to allow lightly wounded soldiers is active, or the unit ignores injuries, do not drop their items
		bIgnoreInjuries = UnitState.IgnoresInjuries() || (XComHQ.bAllowLightlyWoundedOnMissions && UnitState.IsLightlyInjured());
		
		// Do not drop items for any unit on Covert Actions. Items should have been dropped already when the Action began.		
		if(UnitState != None && UnitState.IsSoldier() && !UnitState.IsOnCovertAction() &&
			((UnitState.IsInjured() && !bIgnoreInjuries && !UnitState.bRecoveryBoosted) || UnitState.IsTraining()))
		{
			UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.MakeItemsAvailable(UpdateState, false, RelevantSlots);
		}
	}

	`GAMERULES.SubmitGameState(UpdateState);
}

simulated function CreatePendingStates()
{
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Squad Selection");
	XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	local XComHeadquartersCheatManager CheatMgr;
	local string BoostTooltip;

	//bsg-jneal (5.18.17): do not update the navhelp if we are not focused
	if(!bIsFocused)
	{
		return;
	}
	//bsg-jneal (5.18.17): end

	if( LaunchButton != none )
	{
		LaunchButton.SetDisabled(!CanLaunchMission());
		LaunchButton.SetTooltipText(GetTooltipText(), , , , ,class'UIUtilities'.const.ANCHOR_TOP_RIGHT, , 0.0);
		Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(LaunchButton.CachedTooltipId, true);
	}

	if(`HQPRES != none)
	{
		NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
		CheatMgr = XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager);
		NavHelp.ClearButtonHelp();

		if( !bNoCancel || (XComHQ.AllSquads.Length > 0 && XComHQ.AllSquads.Length < (SquadCount) ) ) // even if we can't cancel, we still need to be able to edit previous squads
			NavHelp.AddBackButton(CloseScreen);

		if(`ISCONTROLLERACTIVE)
		   NavHelp.AddSelectNavHelp();

		//bsg-jedwards (5.15.17) : Added ability to clear squad with a controller on PC
		if(XComHQ != None && XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ') && XComHQ.Squad.Length > 0 && `ISCONTROLLERACTIVE)
			`HQPRES.m_kAvengerHUD.NavHelp.AddCenterHelp(m_strClearSquad, class'UIUtilities_Input'.const.ICON_BACK_SELECT); //bsg-jedwards (5.19.17) Changed to Center Nav Help to prevent crowding
		//bsg-jedwards (5.15.17) : end

		if(CheatMgr == none || !CheatMgr.bGamesComDemo)
		{
			//bsg-jedwards (3.21.17) : Set conditional for console or PC for Manage Eqipment Menu
			if(!`ISCONTROLLERACTIVE)
			{
				NavHelp.AddCenterHelp(m_strStripItems, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LT_L2,
					OnStripItems, false, m_strTooltipStripItems);
				NavHelp.AddCenterHelp(m_strStripWeapons, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RSCLICK_R3,
					OnStripWeapons, false, m_strTooltipStripWeapons);
				NavHelp.AddCenterHelp(m_strStripGear, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RT_R2,
					OnStripGear, false, m_strTooltipStripGear);
				
			}
			else
			{
				`HQPRES.m_kAvengerHUD.NavHelp.AddCenterHelp(Caps(class'UIManageEquipmentMenu'.default.m_strTitleLabel), class'UIUtilities_Input'.const.ICON_LT_L2);
			}
			//bsg-jedwards (3.21.17) : end
		}

		if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M5_WelcomeToEngineering'))
		{

			NavHelp.AddLeftHelp(m_strBuildItems, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE,
								  OnBuildItems, false, m_strTooltipBuildItems);
		}

		// Add the button for the Recovery Booster if it is available	
		if(ShowRecoveryBoostButton())
		{
			// bsg-jrebar (5/3/17): Adding a button for the controls
			if (IsRecoveryBoostAvailable(BoostTooltip) || `ISCONTROLLERACTIVE)
				`HQPRES.m_kAvengerHUD.NavHelp.AddCenterHelp(m_strBoostSoldier, class'UIUtilities_Input'.const.ICON_RT_R2, OnBoostSoldier, false, BoostTooltip);
			else
				`HQPRES.m_kAvengerHUD.NavHelp.AddCenterHelp(m_strBoostSoldier, "", , true, BoostTooltip);
		}
		

		// Re-enabling this option for Steam builds to assist QA testing, TODO: disable this option before release
		`if(`notdefined(FINAL_RELEASE))
		if(CheatMgr == none || !CheatMgr.bGamesComDemo)
		{
			//bsg-crobinson (5.23.17): Moved sim combat to R3
			NavHelp.AddCenterHelp("SIM COMBAT", class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RSCLICK_R3,
								  OnSimCombat, !CanLaunchMission(), GetTooltipText());
		}
		`endif

		NavHelp.Show();
	}
}

//bsg-jedwards (3.21.17) : Function used to bring up the temp screen
simulated function OnManageEquipmentPressed()
{
	local UIManageEquipmentMenu TempScreen;

	TempScreen = Spawn(class'UIManageEquipmentMenu', Movie.Pres);
	TempScreen.AddItem(m_strStripItems, OnStripItems);
	TempScreen.AddItem(m_strStripGear, OnStripGear);
	TempScreen.AddItem(m_strStripWeapons, OnStripWeapons);

	m_bNoRefreshOnLoseFocus = true;

	Movie.Pres.ScreenStack.Push(TempScreen);
}
//bsg-jedwards (3.21.17) : end

simulated function bool ShowRecoveryBoostButton()
{
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	return (XComHQ.HasFacilityUpgradeByName('Infirmary_RecoveryChamber'));
}

simulated function bool IsRecoveryBoostAvailable(optional out string BoostTooltip)
{
	local array<StrategyCostScalar> CostScalars;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (!XComHQ.HasFacilityUpgradeByName('Infirmary_RecoveryChamber'))
	{
		return false;
	}

	BoostTooltip = m_strTooltipBoostSoldier;
	CostScalars.Length = 0;

	if(XComHQ.HasBoostedSoldier())
	{
		BoostTooltip = m_strTooltipSoldierAlreadyBoosted;
		return false;
	}
	else if(!XComHQ.HasBoostableSoldiers())
	{
		BoostTooltip = m_strTooltipNoSoldierToBoost;
		return false;
	}
	else if(!XComHQ.CanAffordAllStrategyCosts(class'X2StrategyElement_XpackFacilities'.default.BoostSoldierCost, CostScalars))
	{
		BoostTooltip = m_strTooltipCantAffordBoost;
		return false;
	}
	
	return true;
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
	XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	bAllowWoundedSoldiers = MissionData.Mission.AllowDeployWoundedUnits;
	
	// add extra soldiers to the squad if possible
	for (idx = MaxDisplayedSlots; idx < (MaxDisplayedSlots + NumSoldiersToAdd); idx++)
	{
		if (XComHQ.Squad.Length == idx || XComHQ.Squad[idx].ObjectID == 0)
		{
			if(bHasRankLimits)
			{
				UnitState = XComHQ.GetBestDeployableSoldier(true, bAllowWoundedSoldiers, MinRank, MaxRank);
			}
			else
			{
				UnitState = XComHQ.GetBestDeployableSoldier(true, bAllowWoundedSoldiers);
			}
			
			if (UnitState != none)
			{
				UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
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
	local string FailReason;

	if(CanLaunchMission())
		return "";

	if(!CurrentSquadHasEnoughSoldiers())
		return m_strTooltipNeedsSoldiers;
	
	if (!GetMissionState().CanLaunchMission(FailReason))
	{
		return FailReason;
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
simulated function OnStripItemsDialogCallback(Name eAction)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	if(eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Items");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		Soldiers = XComHQ.GetSoldiers(true, true);

		RelevantSlots.AddItem(eInvSlot_Utility);
		RelevantSlots.AddItem(eInvSlot_GrenadePocket);
		RelevantSlots.AddItem(eInvSlot_AmmoPocket);

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
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
simulated function OnStripGearDialogCallback(Name eAction)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	if(eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Items");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		Soldiers = XComHQ.GetSoldiers(true, true);

		RelevantSlots.AddItem(eInvSlot_Armor);
		RelevantSlots.AddItem(eInvSlot_HeavyWeapon);

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UnitState.MakeItemsAvailable(UpdateState, true, RelevantSlots);
		}

		`GAMERULES.SubmitGameState(UpdateState);

		bGearStrippedFromSoldiers = true;
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
simulated function OnStripWeaponsDialogCallback(Name eAction)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	if (eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Items");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		Soldiers = XComHQ.GetSoldiers(true, true);

		RelevantSlots.AddItem(eInvSlot_PrimaryWeapon);
		RelevantSlots.AddItem(eInvSlot_SecondaryWeapon);
		RelevantSlots.AddItem(eInvSlot_HeavyWeapon);

		for (idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UnitState.MakeItemsAvailable(UpdateState, true, RelevantSlots);
		}

		`GAMERULES.SubmitGameState(UpdateState);

		bGearStrippedFromSoldiers = true;
	}
	UpdateNavHelp();
}

simulated function OnBuildItems()
{
	// This is a screen jump, but NOT a hotlink, so we DO NOT clear down to the HUD. 
	bDirty = true; // Force a refresh of the pawns when you come back, in case the user purchased new weapons or armor
	if(m_kSlotList != None)
	{
		m_kSlotList.MarkAllListItemsAsDirty(); //Necessary for possible upgrades to weapons that affect all soldiers
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

simulated function OnBoostSoldier()
{
	local string BoostTooltip;
	if( IsRecoveryBoostAvailable(BoostTooltip) )
		`HQPRES.UIPersonnel_BoostSoldier(OnBoostSoldierSelected, XComHQ);
}

function OnBoostSoldierSelected(StateObjectReference _UnitRef)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_Unit Unit;
	local UICallbackData_StateObjectReference CallbackData;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(_UnitRef.ObjectID));
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = BoostSoldierDialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strBoostSoldierDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strBoostSoldierDialogText);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function BoostSoldierDialogCallback(Name eAction, UICallbackData xUserData)
{
	local XComGameState_Unit UnitState;
	local array<StrategyCostScalar> CostScalars;
	local UICallbackData_StateObjectReference CallbackData;

	CallbackData = UICallbackData_StateObjectReference(xUserData);
	CostScalars.Length = 0;

	if (eAction == 'eUIAction_Accept')
	{
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Boost Soldier");
		UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', CallbackData.ObjectRef.ObjectID));
		if(UnitState != none)
		{
			// Boost the soldier
			UnitState.BoostSoldier();

			// Then pay the price
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
			XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.PayStrategyCost(UpdateState, class'X2StrategyElement_XpackFacilities'.default.BoostSoldierCost, CostScalars);
		}

		`GAMERULES.SubmitGameState(UpdateState);
		
		UpdateData(); // Refresh squad lineup after boosting a soldier
	}

	UpdateNavHelp();
}

simulated function UpdateMissionInfo()
{
	local XComGameState NewGameState;
	local GeneratedMissionData MissionData;
	local XComGameState_MissionSite MissionState;
	
	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	MissionState = GetMissionState();
	
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

	MissionState = GetMissionState();
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

	Movie.Pres.PlayUISound(eSUISound_MenuSelect); //bsg-crobinson (5.18.17): Add sound on select soldier
}

simulated function RefreshDisplay()
{
	local int SlotIndex, SquadIndex;
	local UISquadSelect_ListItem ListItem; 

	for( SlotIndex = 0; SlotIndex < SlotListOrder.Length; ++SlotIndex )
	{
		SquadIndex = SlotListOrder[SlotIndex];

		// The slot list may contain more information/slots than available soldiers, so skip if we're reading outside the current soldier availability. 
		if( SquadIndex >= SoldierSlotCount )
			continue;

		//We want the slots to match the visual order of the pawns in the slot list. 
		ListItem = UISquadSelect_ListItem(m_kSlotList.GetItem(SlotIndex));

		if (ListItem != none)
			ListItem.UpdateData(SquadIndex);
	}
}

simulated function OnSimCombat()
{
	local XGStrategy StrategyGame;
	local int MaxSoldiers;

	if(CanLaunchMission())
	{
		MaxSoldiers = class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(GetMissionState());
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

simulated function OnNextSquad(UIButton Button)
{
	local ReserveSquad ResSquad;

	if (CurrentSquadHasEnoughSoldiers( ))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);

		if (UpdateState == none)
			CreatePendingStates();

		ResSquad.SquadMembers = XComHQ.Squad;
		XComHQ.AllSquads.AddItem(ResSquad);

		// clear all squad entries so we refill them with different units
		XComHQ.Squad.Length = 0;
		XComHQ.Squad.Length = SoldierSlotCount;

		StoreGameStateChanges();

		UpdateData(true);

		CreateOrUpdateLaunchButton();
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

simulated function OnLaunchMission(UIButton Button)
{
	local int MaxSoldiers;

	if(CanLaunchMission())
	{
		MaxSoldiers = class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(GetMissionState());
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

// The user may have selected more than one squad in squad select, depending on the mission. This
// function will make sure the XComHQ.AllSquads reflects the squads the user chose, and that XComHQ.Squad
// is equal to the first squad the user chose.
simulated protected function FinalizeReserveSquads()
{
	// the most recently selected squad will be the current squad, but it should be
	// the last reserve squad. Switch it with the first reserve squad so the mission order
	// matches the order the user selected the squads in.
	if(UpdateState == none)
	{
		CreatePendingStates();
	}

	// push the main squad to the end of the reserve list
	XComHQ.AllSquads.Add(1);
	XComHQ.AllSquads[XComHQ.AllSquads.Length - 1].SquadMembers = XComHQ.Squad;
		
	// We start with the first squad the user chose
	XComHQ.Squad = XComHQ.AllSquads[0].SquadMembers;

	StoreGameStateChanges();
}

simulated function CloseScreen()
{
	local XComGameState_MissionSite MissionState;

	MissionState = GetMissionState();
	
	if (bLaunched)
	{
		if(!MissionState.GetMissionSource().bRequiresSkyrangerTravel)
		{
			// Play special departure if mission is Avenger Defense - commented out until sequence is properly hooked up
			`XCOMGRI.DoRemoteEvent('PreM_GoToAvengerDefense');
		}
		else
		{
			`XCOMGRI.DoRemoteEvent('PreM_GoToDeparture');
		}

		// We've been working on XComHQ.Squad directly, now move it to the XComHQ.AllSquads list.
		FinalizeReserveSquads();

		// Re-equip any gear which was stripped from soldiers not in the squad
		EquipStrippedSoldierGear();

		// Strategy map has its own button help
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		Hide();

		if( `CHEATMGR.bShouldAutosaveBeforeEveryAction )
		{
			`AUTOSAVEMGR.DoAutosave(, true, true);
		}
	}
	else if (XComHQ.AllSquads.Length > 0)
	{
		// don't close the screen, just back out the most recent reserve squad
		if(UpdateState == none)
		{
			CreatePendingStates();
		}

		XComHQ.Squad = XComHQ.AllSquads[XComHQ.AllSquads.Length - 1].SquadMembers;
		XComHQ.AllSquads.Length = XComHQ.AllSquads.Length - 1;

		StoreGameStateChanges();

		UpdateData(true);
		CreateOrUpdateLaunchButton();
	}
	else
	{
		`XCOMGRI.DoRemoteEvent('PreM_Cancel');

		MissionState.ClearSpecialSoldiers();
		
		// Re-equip any gear which was stripped from soldiers not in the squad
		EquipStrippedSoldierGear();

		// Strategy map has its own button help
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		Hide();
	}
}

function EquipStrippedSoldierGear()
{
	local XComGameStateHistory History;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit UnitState;
	local int idx;
	
	if (bGearStrippedFromSoldiers)
	{
		bGearStrippedFromSoldiers = false;

		History = `XCOMHISTORY;
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Re-equip Stripped Items");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		Soldiers = XComHQ.GetSoldiers(true, true);
				
		for (idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UnitState.EquipOldItems(UpdateState);
		}

		`GAMERULES.SubmitGameState(UpdateState);
	}
}

function OnVolunteerMatineeIsVisible(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_a');
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_Hallway', none, OnVolunteerMatineeComplete);
	class'Engine'.static.GetEngine().bDontSilenceGameAudioDuringBink = true; //Special case, since the wise event is played with GP_DarkVolunteerPT2_a
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

	MissionState = GetMissionState();

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

	Manager = `HQPRES.m_kNarrativeUIMgr;
	if(Manager.m_arrConversations.Length == 0 && Manager.PendingConversations.Length == 0)
	{
		GetMissionState().ConfirmMission();
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
	local float ListWidth, ListX;
	//Don't reset the camera during the launch sequence.
	//This case occurs, for example, when closing the "reconnect controller" dialog.
	//INS:
	if(bLaunched)
		return;

	ListWidth = GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + LIST_ITEM_PADDING);
	ListX = Clamp(-(ListWidth / 2), -(Movie.UI_RES_X / 2) + 10, 0);
	m_kSlotList.SetX(ListX);

	SnapCamera();

	super.OnReceiveFocus();
	m_bNoRefreshOnLoseFocus = false;
	
	// When the screen gains focus in some rare case, NavHelp needs something inside it before it clears, otherwise the clear is ignored (for some reason)
	`HQPRES.m_kAvengerHUD.NavHelp.AddLeftHelp("");
	
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
	if(!m_bNoRefreshOnLoseFocus && m_kSlotList != None && LP.ControllerID != -1)
	{
		bDirty = true;
				
		//marks the active listitem as 'dirty' so it will be forced to refresh when the screen gains focus again
		if(class'XComGameState_HeadquartersXCom'.static.NeedsToEquipMedikitTutorial())
			m_kSlotList.MarkAllListItemsAsDirty(); //Tutorial modifies ALL listitems, so a full refresh is needed
		else
			m_kSlotList.MarkActiveListItemAsDirty();
	}
	
	super.OnLoseFocus();
	StoreGameStateChanges(); // need to save the state of the screen when we leave it

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!bIsVisible || !bReceivedWalkupEvent)
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

	//bsg-jedwards (3.21.17) : Checking to see if the user has the installed packages and changes the Left Trigger to open the menu
	if (`ISCONTROLLERACTIVE)
	{
		switch ( cmd )
		{
			case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:
				OnManageEquipmentPressed();
				bHandled = true;
				break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:
				OnBoostSoldier();
				bHandled = true;
				break;
		}

	}
	//bsg-jedwards (3.21.17) : end

	switch( cmd )
	{

		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			if(!bNoCancel || XComHQ.AllSquads.Length > 0) // even if we can't cancel, we still need to be able to edit previous squads
			{
				CloseScreen();
				Movie.Pres.PlayUISound(eSUISound_MenuClose);
			}
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M5_WelcomeToEngineering'))
			{
				OnBuildItems();
			}
			break;

`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_BUTTON_R3:
			OnSimCombat();
			break;
`endif
		//bsg-crobinson (5.23.17): shifted sim to R3, moved clear squad to select
		case class'UIUtilities_Input'.const.FXS_BUTTON_SELECT:
			ClearSquad();
			break;
		//bsg-crobinson (5.23.17): end

		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			// bsg-nlong (1.11.17): Making the X button move to the next squad or launch the mission appropriately
			if(XComHQ.AllSquads.Length < (SquadCount - 1))
			{
				OnNextSquad(LaunchButton);
			}
			else
			{
				OnLaunchMission(LaunchButton);
			}
			// bsg-nlong (1.11.17): end
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

simulated function XComGameState_MissionSite GetMissionState()
{
	local XComGameState_MissionSite MissionState;
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	return MissionState;
}

simulated function bool CanLaunchMission()
{
	if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress)
	{
		return false;
	}
	
	if (!GetMissionState().CanLaunchMission())
	{
		return false;
	}

	return CurrentSquadHasEnoughSoldiers();
}

simulated function bool CurrentSquadHasEnoughSoldiers( )
{
	local int i, MinSize;

	MinSize = SquadMinimums[ XComHQ.AllSquads.Length ];

	for(i = 0; i < XComHQ.Squad.Length; ++i)
	{
		if(XComHQ.Squad[i].ObjectID > 0)
			--MinSize;
	}

	return MinSize <= 0;
}

simulated function bool ShowExtraSlotCommon()
{
	local X2SitRepEffect_SquadSize SitRepEffect;
	local GeneratedMissionData MissionData;

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);

	if (MissionData.Mission.AllowDeployWoundedUnits)
		return false;
	else if (MissionData.Mission.MaxSoldiers > 0 && MissionData.Mission.MaxSoldiers < class'X2StrategyGameRulesetDataStructures'.default.m_iMaxSoldiersOnMission)
		return false;
	else
	{
		// don't show squad upgrades if we are applying sitrep limits that shrink the squad size 
		foreach class'X2SitRepTemplateManager'.static.IterateEffects(class'X2SitRepEffect_SquadSize', SitRepEffect, GetMissionState().GeneratedMission.SitReps)
		{
			if(SitRepEffect.MaxSquadSize > 0 || SitRepEffect.SquadSizeAdjustment < 0)
			{
				return false;
			}
		}
	}

	return true;
}

simulated function bool ShowExtraSlot1()
{
	return ShowExtraSlotCommon() && (XComHQ.HasFacilityByName('OfficerTrainingSchool') || XComHQ.HighestSoldierRank >= 3); // sergeant
}

simulated function bool ShowExtraSlot2()
{
	return ShowExtraSlotCommon() && (XComHQ.HasFacilityByName('OfficerTrainingSchool') || XComHQ.HighestSoldierRank >= 5); // captain
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

	if(PrevHQState.Squad.Length != XComHQ.Squad.Length || PrevHQState.AllSquads.Length != XComHQ.AllSquads.Length)
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
	local int locationIndex;

	// This is gross, would be better off changing the walk up positions, but content has been locked.
	// if theres only 2 people max on the mission (lost and abandoned) they need specific walk up positions
	if (SoldierSlotCount == 2 )
	{
		if(index == 0)
			locationIndex = 2;
		else
			locationIndex = 0;
	}
	else
	{
		locationIndex = index;
	}

	LocationName = name(m_strPawnLocationIdentifier $ locationIndex);
	foreach WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if(PlacementActor != none && PlacementActor.Tag == LocationName)
			break;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));		
	UnitPawn = m_kPawnMgr.RequestCinematicPawn(self, UnitRef.ObjectID, PlacementActor.Location, PlacementActor.Rotation, name("Soldier"$(index + 1)), '', true);
	UnitPawn.GotoState('CharacterCustomization');

	UnitPawn.CreateVisualInventoryAttachments(m_kPawnMgr, UnitState, , , true); // spawn weapons and other visible equipment

	GremlinPawn = m_kPawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
	if (GremlinPawn != none)
	{
		SetGremlinMatineeVariable(name("Gremlin"$(locationIndex + 1)), GremlinPawn);
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

	if(XComHQ != None && !XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ'))
		return;	

	//used later to return focus back to where it started
	PrevSelectedIndex = m_kSlotList.GetItemIndex(m_kSlotList.GetActiveListItem());

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
	ListItem = UISquadSelect_ListItem(m_kSlotList.GetItem(PrevSelectedIndex));
	if(ListItem != None)
	{
		ListItem.OnReceiveFocus();
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Remove");	//bsg-crobinson(5.26.17): Play sound when clearing squad
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

simulated function UpdateSitRep()
{
	local XComGameState_MissionSite MissionState;
	local X2SitRepTemplateManager SitRepManager;
	local X2SitRepTemplate SitRepTemplate;
	local string SitRepInfo, SitRepTooltip;
	local name SitRepName;
	local EUIState eState;
	local int idx;
	local array<string> SitRepLines, SitRepTooltipLines;
	local GeneratedMissionData MissionData;

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	MissionState = GetMissionState();
	
	if (MissionData.SitReps.Length > 0 && !MissionState.GetMissionSource().bBlockSitrepDisplay)
	{
		SitRepManager = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();
		foreach MissionData.SitReps(SitRepName)
		{
			SitRepTemplate = SitRepManager.FindSitRepTemplate(SitRepName);

			if (SitRepTemplate != none)
			{
				if (SitRepTemplate.bExcludeFromStrategy)
					continue;

				if (SitRepTemplate.bNegativeEffect)
				{
					eState = eUIState_Bad;
				}
				else
				{
					eState = eUIState_Normal;
				}

				SitRepLines.AddItem(class'UIUtilities_Text'.static.GetColoredText(SitRepTemplate.GetFriendlyName(), eState));
				SitRepTooltipLines.AddItem(SitRepTemplate.Description);
			}
		}
	}

	for (idx = 0; idx < SitRepLines.Length; idx++)
	{
		SitRepInfo $= SitRepLines[idx];
		if (idx < SitRepLines.length - 1)
			SitRepInfo $= "\n";
		
		SitRepTooltip $= SitRepLines[idx] $ ":" @ SitRepTooltipLines[idx];
		if (idx < SitRepLines.length - 1)
			SitRepTooltip $= "\n";
	}

	m_kMissionInfo.UpdateSitRep(SitRepInfo, SitRepTooltip);
}

function bool IsUnitOnSquad( StateObjectReference UnitRef )
{
	local int i;
	//Use the current UpdateState to check status: 
	XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	// Remove tired soldiers from the squad, and remove soldiers that don't fit the rank limits (if they exist)
	for( i = 0; i < XComHQ.Squad.Length; i++ )
	{
		if( XComHQ.Squad[i].ObjectID == UnitRef.ObjectID ) return true; 
	}

	return false; 
}

DefaultProperties
{
	Package   = "/ package/gfxSquadList/SquadList";

	bCascadeFocus = false;
	bHideOnLoseFocus = true;
	bAutoSelectFirstNavigable = false;
	InputState = eInputState_Consume;
	bReceivedWalkupEvent = false; 
	bHasSeenWoundedNotice = false; 

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
