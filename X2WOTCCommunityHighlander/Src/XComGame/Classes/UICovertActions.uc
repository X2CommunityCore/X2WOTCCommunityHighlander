
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UICovertActionsScreen.uc
//  AUTHOR:  Brit Steiner -- 12/16/2016
//  PURPOSE: This file controls the covert actions view
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UICovertActions extends UIScreen;

var localized string CovertActions_ScreenHeader;
var localized string CovertActions_ListHeader;
var localized string CovertActions_Duration;
var localized string CovertActions_Cost;
var localized string CovertActions_RiskTitle;
var localized string CovertActions_AddSoldier;
var localized string CovertActions_Clear;
var localized string CovertActions_RewardHeader;
var localized string CovertActions_RequiredLabel;
var localized string CovertActions_OptionalLabel;
var localized string CovertActions_FamousLabel;
var localized string CovertActions_SoldierReward;
var localized string CovertActions_ActionInProgressTooltip;
var localized string CovertActions_InfluenceRequiredTooltip;
var localized string CovertActions_LaunchAction; 
var localized string CovertActions_NewAction;
var localized string CovertActions_InProgress;
var localized string CovertActions_TimeRemaining;
var localized string CovertActions_CurrentActiveHeader;
var localized string CovertActions_WarningAmbush;
var localized string CovertActions_LocationHeader;
var localized string CovertActions_Unavailable;
var localized string CovertActions_InfluenceLabel;

var StateObjectReference ActionRef;
var array<XComGameState_CovertAction> arrActions;
var array<XComGameState_ResistanceFaction> NewActionFactions;
var bool bActionInProgress;

var public bool				bInstantInterp;

var bool bShowCosts; 
var bool bHasRewards; // Does this Covert Action have any rewards?
var bool bHasRisks; // Does this Covert Action have any risks?

var bool bIsSelectingSlots; // bsg-nlong (1.20.17): a bool to determined whetehr selecting missions or slots

var UIList List;
var UILargeButton LaunchButton;
var UICovertActionSlotContainer SlotContainer;

// When intros pop up, this causes the screen-open sound to play the next time UICovertActions receives focus instead of when it is built
var private transient bool bTutorialPopupDisplayed;

var public delegate<OnStaffUpdated> onStaffUpdatedDelegate;
delegate onStaffUpdated();

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	if( `SCREENSTACK.IsInStack(class'UIStrategyMap') )
	{
		`HQPRES.CAMSaveCurrentLocation();
	}

	//TODO: bsteiner: remove this when the strategy map handles it's own visibility
	if( Package != class'UIScreen'.default.Package )
		`HQPRES.StrategyMap2D.Hide();
	
	PlayTutorial();
}

function PlayTutorial()
{
	// Trigger the tutorial intros if it has never been seen and the appropriate objectives are active
	if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP2_M0_FirstCovertActionTutorial') == eObjectiveState_InProgress)
	{
		bTutorialPopupDisplayed = `HQPRES.UICovertActionIntro();
	}
	else if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP2_M1_SecondCovertActionTutorial') == eObjectiveState_InProgress)
	{
		bTutorialPopupDisplayed = `HQPRES.UICovertActionRiskIntro();
	}
}

simulated function OnInit()
{
	super.OnInit();

	FindActions();

	AS_SetHeaderData(CovertActions_ScreenHeader, CovertActions_ListHeader);

	BuildScreen();
	UpdateData();
	MC.FunctionVoid("AnimateIn");

	//bsg-jneal (2.17.17): select first appropriate list item when using controller
	if(`ISCONTROLLERACTIVE)
		List.Navigator.SelectFirstAvailable();
	//bsg-jneal (2.17.17): end

	if (!bTutorialPopupDisplayed)
	{
		TriggerCovertActionNarrativeEvents();
	}
}

simulated function FindActions()
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_CovertAction ActionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		// Only display actions which are actually stored by the Faction. Safety check to prevent
		// actions which were supposed to have been deleted from showing up in the UI and being accessed.
		FactionState = ActionState.GetFaction();
		if (FactionState.CovertActions.Find('ObjectID', ActionState.ObjectID) != INDEX_NONE ||
			FactionState.GoldenPathActions.Find('ObjectID', ActionState.ObjectID) != INDEX_NONE)
		{
			if (ActionState.bStarted)
			{
				arrActions.InsertItem(0, ActionState); // Always place any currently running Covert Action at the top of the list
				bActionInProgress = true;
			}
			else if (ActionState.CanActionBeDisplayed() && (ActionState.GetMyTemplate().bGoldenPath || FactionState.bSeenFactionHQReveal))
			{
				arrActions.AddItem(ActionState);
				if (ActionState.bNewAction)
				{
					NewActionFactions.AddItem(ActionState.GetFaction());
				}
			}
		}
	}

	arrActions.Sort(SortActionsByFactionName);
	arrActions.Sort(SortActionsByFarthestFaction);
	arrActions.Sort(SortActionsByFactionMet);
	arrActions.Sort(SortActionsStarted);

	ActionRef = arrActions[0].GetReference();
}

function TriggerCovertActionNarrativeEvents()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_AdventChosen ChosenState;
	local bool bTriggeredFactionEvent;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Events: Covert Actions Facility");

	if (bActionInProgress)
	{
		`XEVENTMGR.TriggerEvent('CovertActionInProgress', , , NewGameState);
	}
	else
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
		{
			if (FactionState.bMetXCom && FactionState.bNewFragmentActionAvailable)
			{
				ChosenState = FactionState.GetRivalChosen();
				if (ChosenState.bMetXCom && !ChosenState.bDefeated)
				{
					FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionState.ObjectID));
					FactionState.bNewFragmentActionAvailable = false; // Reset the flag on all of the Factions, but only play VO once
					
					if (!bTriggeredFactionEvent)
					{
						bTriggeredFactionEvent = true;

						if (FactionState.GetInfluence() > eFactionInfluence_Minimal)
						{
							`XEVENTMGR.TriggerEvent('NewFragmentActionAvailable', , , NewGameState);
						}
						else if (!bTriggeredFactionEvent && FactionState.GetInfluence() == eFactionInfluence_Minimal)
						{
							`XEVENTMGR.TriggerEvent('FirstChosenFragmentAvailable', , , NewGameState);
						}
					}
				}
			}
		}

		// No Hunt Chosen moments were played, so trigger a generic moment for the Faction having new Actions
		if (!bTriggeredFactionEvent)
		{
			FactionState = NewActionFactions[`SYNC_RAND(NewActionFactions.Length)];
			if (FactionState != None)
			{
				`XEVENTMGR.TriggerEvent(FactionState.GetNewCovertActionAvailableEvent(), , , NewGameState);
			}

			if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M4_RescueMoxComplete') == eObjectiveState_InProgress)
			{
				`XEVENTMGR.TriggerEvent('ViewCovertActionMoxCaptured', , , NewGameState);
			}
		}
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function int SortActionsByFactionName(XComGameState_CovertAction ActionA, XComGameState_CovertAction ActionB)
{
	local string FactionAName, FactionBName;

	FactionAName = ActionA.GetFaction().GetFactionTitle();
	FactionBName = ActionB.GetFaction().GetFactionTitle();

	if (FactionAName < FactionBName)
	{
		return 1;
	}
	else if (FactionAName > FactionBName)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortActionsByFactionMet(XComGameState_CovertAction ActionA, XComGameState_CovertAction ActionB)
{
	local bool bFactionAMet, bFactionBMet;
	local bool bLostAndAbandonedActive;
	
	bLostAndAbandonedActive = (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M4_RescueMoxComplete') == eObjectiveState_InProgress);

	bFactionAMet = ActionA.GetFaction().bMetXCom;
	bFactionBMet = ActionB.GetFaction().bMetXCom;

	if (!bFactionAMet && bFactionBMet)
	{
		return bLostAndAbandonedActive ? -1 : 1;
	}
	else if (bFactionAMet && !bFactionBMet)
	{
		return bLostAndAbandonedActive ? 1 : -1;
	}
	else
	{
		return 0;
	}
}

function int SortActionsByFarthestFaction(XComGameState_CovertAction ActionA, XComGameState_CovertAction ActionB)
{
	local bool bFactionAFarthest, bFactionBFarthest;
	local bool bLostAndAbandonedActive;

	bLostAndAbandonedActive = (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M4_RescueMoxComplete') == eObjectiveState_InProgress);
	
	bFactionAFarthest = ActionA.GetFaction().bFarthestFaction;
	bFactionBFarthest = ActionB.GetFaction().bFarthestFaction;

	if (!bFactionAFarthest && bFactionBFarthest)
	{
		return bLostAndAbandonedActive ? -1 : 1;
	}
	else if (bFactionAFarthest && !bFactionBFarthest)
	{
		return bLostAndAbandonedActive ? 1 : -1;
	}
	else
	{
		return 0;
	}
}

function int SortActionsStarted(XComGameState_CovertAction ActionA, XComGameState_CovertAction ActionB)
{
	if (ActionA.bStarted && !ActionB.bStarted)
	{
		return 1;
	}
	else if (!ActionA.bStarted && ActionB.bStarted)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

simulated function SelectAction(XComGameState_CovertAction actionToSelect)
{
	local int missionNum;
	missionNum = arrActions.Find(actionToSelect);

	ClearSlots(); // Clear staff slots before setting the new action
	if( missionNum >= 0 )
	{
		ActionRef = arrActions[missionNum].GetReference();
		UpdateData();
	}
}

function BuildScreen()
{
	local name LastFactionName;
	local int idx;
	local UIListItemString Item;
	local UICovertOpsFactionListItem listHeader;

	if( !bTutorialPopupDisplayed )
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("UI_CovertOps_Open");
	}
	
	CreateSlotContainer();

	if( List == None )
	{
		List = Spawn(class'UIList', self);
		List.InitList('stageListMC'); 
		List.bStickyClickyHighlight = true;
		List.bStickyHighlight = false;
		List.OnSetSelectedIndex = SelectedItemChanged;

		//bsg-jneal (2.17.17): selection changed update for controller
		if(`ISCONTROLLERACTIVE)
			List.OnSelectionChanged = SelectedItemChanged;
		else
			List.OnItemClicked = SelectedItemChanged;
		//bsg-jneal (2.17.17): end

		Navigator.SetSelected(List);
		List.SetSize(438, 638);
	}

	for( idx = 0; idx < arrActions.Length; idx++ )
	{
		if (arrActions[idx].GetFaction().GetMyTemplateName() != LastFactionName)
		{
			listHeader = Spawn(class'UICovertOpsFactionListItem', List.itemContainer);
			if (idx == 0 && arrActions[idx].bStarted)
			{
				listHeader.InitCovertOpsListItem(arrActions[idx].GetFaction().FactionIconData, CovertActions_CurrentActiveHeader, class'UIUtilities_Colors'.const.COVERT_OPS_HTML_COLOR);
			}
			else
			{
				LastFactionName = arrActions[idx].GetFaction().GetMyTemplateName();
				
				listHeader.InitCovertOpsListItem(arrActions[idx].GetFaction().FactionIconData, Caps(arrActions[idx].GetFaction().GetFactionTitle()), class'UIUtilities_Colors'.static.GetColorForFaction(LastFactionName));
			}

			listHeader.DisableNavigation(); //bsg-jneal (2.17.17): disable faction headers in the list so they get skipped over for navigation
		}
		Item = Spawn(class'UIListItemString', List.itemContainer);
		Item.InitListItem(GetActionLocString(idx));
		Item.metadataInt = arrActions[idx].ObjectID;

		if( IsCovertActionInProgress() && !arrActions[idx].bStarted)
		{
			Item.SetDisabled(true, CovertActions_ActionInProgressTooltip);
		}
		else if (!IsActionInfluenceMet(idx)) // If the covert action requires a higher influence level, disable the button
		{
			Item.SetDisabled(true, CovertActions_InfluenceRequiredTooltip);
		}
		if( List.GetSelectedItem() == None )
		{
			List.SetSelectedItem(Item);
		}
	}
}

function UpdateData()
{
	// Update data values before the UI panels are refreshed
	bHasRewards = DoesActionHaveRewards();
	bHasRisks = DoesActionHaveRisks();

	RefreshMainPanel();
	RefreshFactionPanel();
	RefreshRisksPanel();

	RealizeSlots();

	RefreshNavigation();
	
	// bsg-jrebar (3/30/17) : Disable buttons 
	if (IsCovertActionInProgress() || !IsInfluenceMet()) 
	{
		//Disable Slots
		SlotContainer.DisableAllSlots();
		LaunchButton.Hide();
	}
	else
	{
		// Enable Slots
		SlotContainer.EnableAllSlots();
		LaunchButton.Show();
	}
	// bsg-jrebar (3/30/17) : end 
}

function RefreshConfirmPanel()
{
	if( LaunchButton == none )
	{
		LaunchButton = Spawn(class'UILargeButton', self);
		LaunchButton.bAnimateOnInit = false;

		if( `ISCONTROLLERACTIVE )
		{
			LaunchButton.InitLargeButton(, class'UIUtilities_Text'.static.InjectImage(
				class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -10) @ CovertActions_LaunchAction, , OnLaunchClicked);
		}
		else
		{
			LaunchButton.InitLargeButton(, CovertActions_LaunchAction, "", OnLaunchClicked);
		}

		LaunchButton.AnchorBottomRight();
		LaunchButton.DisableNavigation();
		LaunchButton.ShowBG(true);
	}

	LaunchButton.SetDisabled( !CanBeginAction() );
}

simulated function RefreshNavigation()
{
	local UINavigationHelp NavHelp;

	//bsg-jedwards (3.3.17) : Used to allow the tutorial to be initialized before the navhelp and screen data.
	if(!bIsFocused)
		return;
	//bsg-jedwards (3.3.17) : end

	RefreshConfirmPanel();

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();

	//bsg-jneal (3.10.17): adding select navhelp for controller
	if(`ISCONTROLLERACTIVE)
	{
		NavHelp.AddSelectNavHelp();
	}
	//bsg-jneal (3.10.17): end

	NavHelp.AddBackButton(CloseScreen);

	//bsg-jneal (3.10.17): add edit loadout navhelp if on an editable soldier
	if( `ISCONTROLLERACTIVE && bIsSelectingSlots && SlotContainer.ActionSlots.Length > 0)
	{
		/// HL-Docs: ref:Bugfixes; issue:1035
		/// Use `SlotContainer.Navigator.SelectedIndex` instead of `Navigator.SelectedIndex` to allow controller users editing all soldiers' loadouts.
		if( SlotContainer.ActionSlots[SlotContainer.Navigator.SelectedIndex].CanEditLoadout() )
		{
			NavHelp.AddLeftHelp(class'UICovertActionStaffSlot'.default.m_strEditLoadout, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
		}
	}
	//bsg-jneal (3.10.17): end
}

simulated function RefreshMainPanel()
{
	local string Duration; 

	if( bHasRewards )
		AS_SetInfoData(GetActionImage(), GetActionName(), GetActionDescription(), CovertActions_RewardHeader, GetRewardString(), GetRewardDetailsString(), Caps(GetWorldLocation()));
	else
		AS_SetInfoData(GetActionImage(), GetActionName(), GetActionDescription(), "", "", "", "");

	if (IsCovertActionInProgress() && !GetAction().bStarted)
	{
		AS_SetLockData(CovertActions_Unavailable, CovertActions_ActionInProgressTooltip);
	}
	else if (!IsInfluenceMet()) // If the covert action requires a higher influence level, disable the button
	{
		AS_SetLockData(CovertActions_Unavailable, CovertActions_InfluenceRequiredTooltip);
	}
	else
	{
		AS_SetLockData("", "");
	}

	Duration = GetDurationString();
	AS_UpdateCost(Duration);
}

simulated function RefreshRisksPanel()
{
	local array<string> Labels, Values; 
	local int idx; 

	if (!class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('XP2_M0_FirstCovertActionTutorial'))
	{
		// If the tutorial Action hasn't been completed, risks are not enabled, so do not display them
		MC.FunctionString("SetRiskTitle", "");
		for (idx = 0; idx < 4; idx++)
		{
			AS_SetRiskRow(idx, "", "");
		}
	}
	else
	{
		MC.FunctionString("SetRiskTitle", DoesActionHaveRisks() ? CovertActions_RiskTitle : "");

		//TODO: Need a clear risks function? 

		GetActionRisks(Labels, Values);

		for (idx = 0; idx < 4; idx++)
		{
			if (idx < arrActions.Length)
				AS_SetRiskRow(idx, Caps(Labels[idx]), Caps(Values[idx]));
			else
				AS_SetRiskRow(idx, "", "");
		}

		if( HasAmbushRisk() )
		{
			AS_SetRiskWarning(CovertActions_WarningAmbush);
		}
		else
		{
			AS_SetRiskWarning("");
		}
	}
}

simulated function CreateSlotContainer()
{
	if( SlotContainer == none )
	{
		SlotContainer = Spawn(class'UICovertActionSlotContainer', self);
		SlotContainer.InitSlotContainer();
	}
}

simulated function RealizeSlots()
{
	onStaffUpdatedDelegate = UpdateData;

	if( SlotContainer != none )
	{
		SlotContainer.Refresh(ActionRef, onStaffUpdatedDelegate);
	}
}

// -------------------------------------------------------------------------

function AS_SetHeaderData(string ScreenHeader, string ListHeader)
{
	MC.BeginFunctionOp("SetHeaderData");
	MC.QueueString(ScreenHeader);
	MC.QueueString(ListHeader);
	MC.EndOp();
}

function RefreshFactionPanel()
{
	local name FactionName;
	local string FrameLabel, Image, Title, Subtitle, DisplayString;

	FactionName = GetFactionTemplateName();
	FrameLabel = class'UIUtilities_Image'.static.GetFlashLabelForFaction(FactionName);
	Image = GetFactionLeaderImage();
	Title = Caps(GetFactionTitle());
	Subtitle = "<font color='#" $ class'UIUtilities_Colors'.static.GetColorForFaction(FactionName) $"'>" $ Caps(GetFactionName()) $"</font>";

	DisplayString = Caps(GetAction().GetFaction().GetInfluenceString());

	AS_SetFactionData(FrameLabel, Image, Title, Subtitle, DisplayString);
	AS_SetFactionIcon(GetAction().GetFaction().GetFactionIcon());
}

// ----------------------------------------------------------------------
function AS_SetFactionData(string FrameLabel, string Image, string TItle, string Subtitle, string Influence)
{
	MC.BeginFunctionOp("SetFactionData");
	MC.QueueString(FrameLabel);
	MC.QueueString(Image);
	MC.QueueString(Title);
	MC.QueueString(Subtitle);
	MC.QueueString(CovertActions_InfluenceLabel);
	MC.QueueString(Influence);
	MC.EndOp();
}

function AS_UpdateCost(string Duration)
{
	MC.BeginFunctionOp("SetCostData");
	if( bShowCosts )
	{
		MC.QueueString((GetAction().bStarted) ? CovertActions_TimeRemaining : CovertActions_Duration);
		MC.QueueString(Duration);
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
	}
	MC.EndOp();
}

function AS_SetRiskRow(int Index, string RiskLabel, string RiskValue)
{
	MC.BeginFunctionOp("SetRiskRow");
	MC.QueueNumber(Index);
	MC.QueueString(RiskLabel);
	MC.QueueString(RiskValue); //Intended to be HTML colored going in
	MC.EndOp();
}

function AS_SetInfoData(string Image, string Title, string Description, string RewardLabel, string RewardTitle, string RewardDesc, string WorldLocation)
{
	MC.BeginFunctionOp("SetInfoData");
	MC.QueueString(Image);
	MC.QueueString(Title);
	MC.QueueString(Description);
	MC.QueueString(RewardLabel);
	MC.QueueString(RewardTitle);
	MC.QueueString(RewardDesc);
	MC.QueueString( WorldLocation ==  "" ? "" : CovertActions_LocationHeader);
	MC.QueueString(WorldLocation);
	MC.EndOp();
}

function AS_ClearSlotData(int Index)
{
	if( Index > -1 ) 
		MC.FunctionNum("ClearSlotData", Index);
}

function AS_SetSlotData(int Index, int NumState, string Image, string RankImage, string ClassImage, string Label, string Value, string ButtonLabel, string ButtonLabel2)
{
	MC.BeginFunctionOp("SetSlotData");
	MC.QueueNumber(Index);
	MC.QueueNumber(NumState);
	MC.QueueString(Image);
	MC.QueueString(RankImage);
	MC.QueueString(ClassImage);
	MC.QueueString(Label);
	MC.QueueString(Value); //Intended to be HTML colored going in
	MC.QueueString(ButtonLabel);
	MC.QueueString(ButtonLabel2);
	MC.EndOp();
}

function AS_SetRiskWarning(string Desc)
{
	MC.FunctionString("SetRiskWarning", Desc);
}

function AS_SetLockData(string Title, string Desc)
{
	MC.BeginFunctionOp("SetLockData");
	MC.QueueString(Title);
	MC.QueueString(Desc);
	MC.EndOp();
}

simulated function AS_SetFactionIcon(StackedUIIconData IconInfo)
{
	local int i;

	MC.BeginFunctionOp("SetFactionIcon");
	MC.QueueBoolean(IconInfo.bInvert);
	for (i = 0; i < IconInfo.Images.Length; i++)
	{
		MC.QueueString("img:///" $ IconInfo.Images[i]);
	}

	MC.EndOp();

}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function XComGameState_CovertAction GetAction()
{
	return XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(ActionRef.ObjectID));
}
simulated function String GetActionObjective()
{
	return GetAction().GetObjective();
}
simulated function String GetActionImage()
{
	return GetAction().GetImage();
}
simulated function String GetActionName()
{
	return GetAction().GetDisplayName();
}
simulated function String GetActionDescription()
{
	return GetAction().GetNarrative();
}
simulated function GetActionRisks(out array<string> Labels, out array<string> Values)
{
	GetAction().GetRisksStrings(Labels, Values);
}
simulated function Name GetFactionTemplateName()
{
	return GetAction().GetFaction().GetMyTemplateName();
}
simulated function string GetFactionName()
{
	return GetAction().GetFaction().FactionName;
}
simulated function String GetFactionTitle()
{
	return GetAction().GetFaction().GetFactionTitle();
}
simulated function String GetFactionLeaderImage()
{
	return GetAction().GetFaction().GetLeaderImage();
}
simulated function String GetRewardString()
{
	return GetAction().GetRewardDescriptionString();
}
simulated function String GetRewardDetailsString()
{
	return GetAction().GetRewardDetailsString();
}
simulated function String GetRewardIcon()
{
	return GetAction().GetRewardIconString();
}
simulated function string GetWorldLocation()
{
	return GetAction().GetLocationDisplayString();
}
simulated function String GetDurationString()
{
	return GetAction().GetDurationString();
}
simulated function bool HasAmbushRisk()
{
	return GetAction().HasAmbushRisk();
}
simulated function bool IsInfluenceMet()
{
	local XComGameState_CovertAction ActionState;

	ActionState = GetAction();
	return (ActionState.RequiredFactionInfluence <= ActionState.GetFaction().GetInfluence());
}
simulated function int GetNumActions()
{
	return arrActions.Length;
}

simulated function bool IsActionInfluenceMet(int iAction)
{
	local XComGameState_CovertAction CurrentAction;

	if (iAction >= arrActions.Length) return false;

	CurrentAction = arrActions[iAction];

	return (CurrentAction.RequiredFactionInfluence <= CurrentAction.GetFaction().GetInfluence());
}

simulated function String GetActionLocString(int iAction)
{
	local XComGameState_CovertAction CurrentAction;
	local string PrefixStr;

	if (iAction >= arrActions.Length) return "";

	CurrentAction = arrActions[iAction];

	if(CurrentAction.bNewAction)
	{
		PrefixStr = CovertActions_NewAction;
	}

	return PrefixStr $ CurrentAction.GetObjective();
}

simulated function bool DoesActionHaveRisks()
{
	return (GetAction().Risks.Length > 0);
}
simulated function bool DoesActionHaveRewards()
{
	return (GetAction().RewardRefs.Length > 0);
}
simulated function bool DoesActionRequireVeteran()
{
	return GetAction().IsVeteranRequired();
}

function bool CanBeginAction()
{
	return GetAction().CanBeginAction();
}

simulated function bool IsCovertActionInProgress()
{
	local XComGameState_HeadquartersResistance ResHQ;

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	return ResHQ.IsCovertActionInProgress();
}

simulated function ClearSlots()
{
	local XComGameState NewGameState;
	local XComGameState_CovertAction ActionState;
	local int i; 

	// Only clear slots for non-started Actions
	if( ActionRef.ObjectID != 0 && !GetAction().bStarted)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Covert Action Staff Slots");
		ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionRef.ObjectID));
		ActionState.EmptyAllStaffSlots(NewGameState); // Empty all of the staff slots for the current covert action
		ActionState.ResetAllCostSlots(NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}

	for (i = 0; i <= 4; i++)
	{
		AS_SetSlotData(i, 0, "", "", "", "", "", "", "");
	}
}

// Called when screen is removed from Stack
simulated function OnRemoved()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_CovertAction ActionState;
	local bool bModified;

	super.OnRemoved();

	ClearSlots(); // Empty the slots if the current action was not started

	// Turn off the "Now Available" flag for any new covert actions
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Turn off new Covert Action Now Available flag");
	foreach arrActions(ActionState)
	{
		if( ActionState.bNewAction && ActionState.CanActionBeDisplayed())
		{
			ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));
			ActionState.bNewAction = false;
			bModified = true;
		}
	}

	if( bModified )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	class'UIUtilities_Sound'.static.PlayCloseSound();
}

//-----------------------------------------------------------------------


simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIPanel ListItem;
	local XComGameState NewGameState;
	local StateObjectReference NewRef;
	local int i;

	ListItem = ContainerList.GetItem(ItemIndex);
	if( ListItem != none )
	{
		for (i = 0; i < arrActions.length; i++)
		{
			if (arrActions[i].ObjectID == UIListItemString(ListItem).metadataInt)
			{
				NewRef = arrActions[i].GetReference();
			}
		}

		if( ActionRef != NewRef )
		{
			ClearSlots(); // Clear staff slots before setting the new action
			ActionRef = NewRef;
			SlotContainer.HardReset(); 
			UpdateData();
			//UpdateStickyButton(button);

			if (DoesActionRequireVeteran() && !IsCovertActionInProgress() && IsInfluenceMet())
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Covert Action Requires Vet");
				`XEVENTMGR.TriggerEvent('CovertActionVetRequired', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}
}

//bsg-jneal (3.10.17): adding controller navigation support for staff slots
function SelectStaffSlots()
{
	//bsg-jneal (4.25.17): fixes for navigator on staff/cost slots while using controller
	local int i, numSlots;
	local XComGameState_CovertAction Action;
	
	bIsSelectingSlots = true;

	List.OnLoseFocus();
	Navigator.Clear();
	Navigator.OnlyUsesNavTargets = true;
	Navigator.AddControl(SlotContainer);
	SlotContainer.Navigator.Clear();

	Action = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(ActionRef.ObjectID));
	numSlots = Action.StaffSlots.Length + Action.CostSlots.Length; //get the total number of slots

	for (i = 0; i < numSlots; i++)
	{
		if(!Action.GetStaffSlot(i).IsHidden())
		{
			SlotContainer.Navigator.AddControl(SlotContainer.ActionSlotPanels[i]);

			//use navtarget navigation set below, specific for each slot
			switch(i)
			{
				case 0:
					if(numSlots > 1)
					{
						SlotContainer.ActionSlotPanels[i].Navigator.AddNavTargetRight(SlotContainer.ActionSlotPanels[1]);
					}
					if(numSlots > 2)
					{
						SlotContainer.ActionSlotPanels[i].Navigator.AddNavTargetDown(SlotContainer.ActionSlotPanels[2]);
					}
					break;
				case 1:
					if(numSlots > 0)
					{
						SlotContainer.ActionSlotPanels[i].Navigator.AddNavTargetLeft(SlotContainer.ActionSlotPanels[0]);
					}
					if(numSlots > 3)
					{
						SlotContainer.ActionSlotPanels[i].Navigator.AddNavTargetDown(SlotContainer.ActionSlotPanels[3]);
					}
					break;
				case 2:
					if(numSlots > 3)
					{
						SlotContainer.ActionSlotPanels[i].Navigator.AddNavTargetRight(SlotContainer.ActionSlotPanels[3]);
					}
					if(numSlots > 0)
					{
						SlotContainer.ActionSlotPanels[i].Navigator.AddNavTargetUp(SlotContainer.ActionSlotPanels[0]);
					}
					break;
				case 3:
					if(numSlots > 2)
					{
						SlotContainer.ActionSlotPanels[i].Navigator.AddNavTargetLeft(SlotContainer.ActionSlotPanels[2]);
					}
					if(numSlots > 1)
					{
						SlotContainer.ActionSlotPanels[i].Navigator.AddNavTargetUp(SlotContainer.ActionSlotPanels[1]);
					}
					break;
			}
		}
	}
	//bsg-jneal (4.25.17): end

	Navigator.SelectFirstAvailable();

	RefreshNavigation();
}

function UnselectStaffSlots()
{
	//bsg-jneal (4.25.17): clear navigation targets since they can be different from action to action, they will be refreshed when staff slots are selected again
	local int i;

	bIsSelectingSlots = false;
	Navigator.GetSelected().OnLoseFocus(); //bsg-jneal (3.30.17): clear focus on selected staff slot before clearing navigator

	for (i = 0; i < SlotContainer.ActionSlotPanels.Length; i++)
	{
		SlotContainer.ActionSlotPanels[i].Navigator.ClearAllNavigationTargets();
	}

	Navigator.Clear();
	Navigator.OnlyUsesNavTargets = false;
	Navigator.AddControl(List);
	List.OnReceiveFocus();
	//bsg-jneal (4.25.17): end

	Navigator.SetSelected(List);

	RefreshNavigation();
}

function EditSoldierLoadout()
{
	// only edit loadout if action slot allows
	if(bIsSelectingSlots && SlotContainer.ActionSlots.Length > 0)
	{
		/// HL-Docs: ref:Bugfixes; issue:1035
		/// Use `SlotContainer.Navigator.SelectedIndex` instead of `Navigator.SelectedIndex` to allow controller users editing all soldiers' loadouts.
		if( SlotContainer.ActionSlots[SlotContainer.Navigator.SelectedIndex].CanEditLoadout() )
		{
			/// HL-Docs: ref:Bugfixes; issue:1035
			/// Use `SlotContainer.Navigator.SelectedIndex` instead of `Navigator.SelectedIndex` to allow controller users editing all soldiers' loadouts.
			SlotContainer.ActionSlots[SlotContainer.Navigator.SelectedIndex].HandleClick("theButton2");
		}
	}
}
//bsg-jneal (3.10.17): end

//-----------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true; //bsg-jneal (4.25.17): conume the input if repeating

	bHandled = true;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		//bsg-jneal (3.10.17): adding controller navigation support for staff slots
		if( bIsSelectingSlots )
		{
			UnselectStaffSlots();
		}
		else
		{
			CloseScreen();
		}
		//bsg-jneal (3.10.17): end
		break;


	case class'UIUtilities_Input'.const.FXS_BUTTON_A : //bsg-cballinger (2.8.17): Button swapping should only be handled in XComPlayerController, to prevent double-swapping back to original value.
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		//bsg-jneal (3.10.17): adding controller navigation support for staff slots
		if(SlotContainer.ActionSlots.Length > 0 && !bActionInProgress )
		{
			if( bIsSelectingSlots )
			{
				SlotContainer.ActionSlots[SlotContainer.Navigator.SelectedIndex].HandleClick("theButton"); //bsg-jneal (4.25.17): use slot container navigator since navtargets are only reference direct parents and not parents of parents
			}
			else
			{
				SelectStaffSlots();
			}
		}

		bHandled = true;
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_Y :
		EditSoldierLoadout();
		bHandled = true;
		break;
	//bsg-jneal (3.10.17): end
	// bsg-nlong (1.20.17): Impliment X/Square activating the mission
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		OnLaunchClicked(none);
		bHandled = true;
		break;
	// bsg-nlong (1.20.17): end
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}


//==============================================================================
//		MOUSE HANDLING:
//==============================================================================
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string callbackObj, tmp, interiorButton;
	local int buttonIndex;

	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		callbackObj = args[args.Length - 2];
		interiorButton = args[args.Length - 1];
		if (InStr(callbackObj, "slot") == -1)
			return;

		tmp = GetRightMost(callbackObj);
		if (tmp != "")
			buttonIndex = int(tmp);
		else
			buttonIndex = -1;

		// This can never ever happen.
		`assert(buttonIndex >= 0);

		SlotContainer.ActionSlots[buttonIndex].HandleClick(interiorButton);
	}
	else if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN
		|| cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER
		|| cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER)
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("Play_Mouseover");
	}
	super.OnMouseEvent(cmd, args);
}

simulated public function OnLaunchClicked(UIButton button)
{
	if( CanBeginAction() )
	{
		GetAction().ConfirmAction();
	}
}
simulated function OnCancelClickedNavHelp()
{
	OnCancelClicked(none);
}
simulated public function OnCancelClicked(UIButton button)
{
	CloseScreen();
}

simulated function OnReceiveFocus()
{
	local UIFacility_CovertActions FacilityScreen; 

	super.OnReceiveFocus();
	FacilityScreen = UIFacility_CovertActions(`SCREENSTACK.GetLastInstanceOf(class'UIFacility_CovertActions'));
	if( FacilityScreen != none )
	{
		// Jump back to the facility immediately, no interp
		FacilityScreen.bInstantInterp = true;
		FacilityScreen.HQCamLookAtThisRoom();
	}

	if( `SCREENSTACK.IsInStack(class'UIStrategyMap') )
	{
		`HQPRES.CAMRestoreSavedLocation(0.0);
	}

	//bsg-jneal (3.10.17): update navhelp when returning to the screen
	if(`ISCONTROLLERACTIVE)
	{
		RefreshNavigation();
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
	}
	//bsg-jneal (3.10.17): end

	UpdateData(); //bsg-jedwards (3.2.17) : Called in case the tutorial populates the screen.
	
	if( bTutorialPopupDisplayed )
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("UI_CovertOps_Open");
		bTutorialPopupDisplayed = false;
		TriggerCovertActionNarrativeEvents();
	}
}

//bsg-hlee (05.03.17): Remove the extra nav help icons on the bottom left when this screen loses focus.
simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}
//bsg-hlee (05.03.17): End

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxXPACK_CovertOps/XPACK_CovertOps";
	LibID = "CovertOpsScreen";
	InputState = eInputState_Consume;
	bShowCosts = true; 
}