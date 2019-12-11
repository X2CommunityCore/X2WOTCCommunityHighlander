//---------------------------------------------------------------------------------------
//  FILE:    UIObjectiveList.uc
//  AUTHOR:  Brit Steiner --  11/13/2014
//  PURPOSE: This is an autoformatting list of objectives. . 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIObjectiveList extends UIPanel
	implements(X2VisualizationMgrObserverInterface);

var array<UIObjectiveListItem> Items; 
var public float MaskHeight; 

var vector2d InitPos;
var vector2d ReinforcementsPos;

var localized string m_strTitle;
var localized string m_strObjectivesCompleteTitle;
var localized string m_strObjectivesCompleteBody;

var int SyncedToState;

simulated function UIObjectiveList InitObjectiveList(optional name InitName, 
										  optional name InitLibID = '', 
										  optional int InitX = 10, 
										  optional int InitY = 10)  
{
	local XComGameStateHistory History;
	local XComGameState_ObjectivesList ObjectiveList;

	InitPanel(InitName, InitLibID);
	
	AnchorTopLeft();
	
	SetPosition(InitX, InitY);

	if( XComHQPresentationLayer(Movie.Pres) == none )
		XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).VisualizationMgr.RegisterObserver(self);

	//Save out this info 
	InitPos = vect2d(X, Y);
	ReinforcementsPos = vect2d(X, Y + class'UITacticalHUD_Countdown'.default.Height);

	//Debug square to show location:
	//Spawn(class'UIPanel', self).InitPanel('BGBoxSimpleHit', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(50, 50);

	// For debug testing only
	if(UIDynamicDebugScreen(Screen) != none)
	{
		RefreshObjectivesDisplay(none);
	}
	else
	{
		History = `XCOMHISTORY;
		
		// Use iterator here instead of GetSingleGameState, because we want tactical only or strategy only objectives
		foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
		{
			break;
		}
		
		if(ObjectiveList != none)
		{
			RefreshObjectivesDisplay(ObjectiveList);
			SyncedToState = XComGameState(ObjectiveList.Outer).HistoryIndex;
		}
	}
	return self;
}

// --------------------------------------

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState_ObjectivesList ObjectiveList;
	local XComGameState_AIReinforcementSpawner AISpawnerState; 
	local XComGameStateHistory History;
	local int spawningStates;
	local bool ForceShowReinforcementsAlert;
	
	//Exit early if the state being passed in is older than our latest sync'd state
	if (AssociatedGameState.HistoryIndex < SyncedToState)
	{
		return;
	}

	// See if any states we are interested in are in the associated state
	foreach AssociatedGameState.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
	{
		break;
	}

	foreach AssociatedGameState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
	{
		break;
	}

	// Start Issue #449
	ForceShowReinforcementsAlert = IsReinforcementsAlertForced(AssociatedGameState);

	// if this state has nothing for us to update, then just return
	if (ObjectiveList == none && AISpawnerState == none && !ForceShowReinforcementsAlert)
	{
		return;
	}
	// End Issue #449

	// if we update either, we need to grab the correct version of both or our SyncedToState might prevent us from updating correctly
	History = `XCOMHISTORY;
	
	foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
	{
		ObjectiveList = XComGameState_ObjectivesList(History.GetGameStateForObjectID(ObjectiveList.ObjectID,, AssociatedGameState.HistoryIndex));
		RefreshObjectivesDisplay(ObjectiveList);
		break;
	}

	// Start Issue #449
	//
	// Reposition the objective list if the reinforcements alert is being forced
	// to show.
	if (ForceShowReinforcementsAlert)
	{
		SetPosition(ReinforcementsPos.X, ReinforcementsPos.Y);
	}
	else
	{
		spawningStates = 0;
		foreach History.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
		{
			spawningStates++;
			AISpawnerState = XComGameState_AIReinforcementSpawner(History.GetGameStateForObjectID(AISpawnerState.ObjectID,, AssociatedGameState.HistoryIndex));
			RefreshPositionBasedOnCounter(AISpawnerState);
			break;
		}

		if (spawningStates == 0)
		{
			//objectives list needs to return to valid position after reinforcements
			RefreshPositionBasedOnCounter(none);
		}
	}
	// End Issue #449

	SyncedToState = AssociatedGameState.HistoryIndex;
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle();

simulated function RefreshObjectivesDisplay(XComGameState_ObjectivesList ObjectiveList, optional bool bForce = false)
{
	local array<ObjectiveDisplayInfo> SortedInfos;
	local ObjectiveDisplayInfo Info, Title;
	local bool bIsTactical;
	local XComGameStateHistory History;
	
	//Debug shell testing 
	if (XComTacticalController(PC) == None && XComHeadquartersController(PC) == None)
	{
		SortedInfos = DEBUG_CreateTestObjectives();
	}
	else
	{
		if(ObjectiveList == none) 
		{
			if( bIsVisible )
				Hide();
			return;
		}
		else
		{
			if( !bIsVisible )
				Show();
		}

		History = `XCOMHISTORY;
		bIsTactical = (XComGameStateContext_TacticalGameRule(History.GetGameStateFromHistory(History.FindStartStateIndex()).GetContext()) != None);
	
		//Normal gather info in game 
		foreach ObjectiveList.ObjectiveDisplayInfos(Info)
		{
			if(!Info.HideInTactical || !bIsTactical)
			{
				SortedInfos.AddItem(Info);
			}
		}
	}

	//Add a title item in here for the UI to use 
	if( ShowingRegularObjectives(SortedInfos) )
	{
		Title.MissionType = "TITLE";
		Title.GroupID = -1;  
		SortedInfos.AddItem(Title); 
	}

	if( ShowingDarkEvents(SortedInfos) )
	{
		Title.MissionType = "DARKEVENTTITLE";
		Title.GroupID = -1;
		Title.bIsDarkEvent = true;
		SortedInfos.AddItem(Title);
	}
	
	SortedInfos.Sort(SortObjectives); // Initial sort for groups and subrules. 
	//SortedInfos = GenerateGroupHeaders(SortedInfos); //Create headers from last item in groups. 
		
	RefreshDisplay(SortedInfos, bForce);
}

simulated function bool ShowingDarkEvents(array<ObjectiveDisplayInfo> Data)
{
	local ObjectiveDisplayInfo Info;

	foreach Data(Info)
	{
		if( Info.bIsDarkEvent ) return true;
	}
	return false; 
}

simulated function bool ShowingRegularObjectives(array<ObjectiveDisplayInfo> Data)
{
	local ObjectiveDisplayInfo Info;

	foreach Data(Info)
	{
		if( !Info.bIsDarkEvent ) return true;
	}
	return false;
}

simulated function array<ObjectiveDisplayInfo> DEBUG_CreateTestObjectives()
{
	local array<ObjectiveDisplayInfo> DisplayInfos; 
	local ObjectiveDisplayInfo CheckboxInfo, SimpleTextInfo, WarningInfo, TimerInfo, ClickableButtonInfo, CounterInfo;

	//Make the order intentionally not the final order, to check that the sorting algorithm works. 

	CheckboxInfo.ShowCheckBox = true; 
	CheckboxInfo.ShowCompleted = false; 
	CheckboxInfo.ShowFailed = true; 
	CheckboxInfo.DisplayLabel = "Checkbox";
	DisplayInfos.AddItem(CheckboxInfo);

	CheckboxInfo.ShowCheckBox = true; 
	CheckboxInfo.ShowCompleted = false; 
	CheckboxInfo.ShowFailed = false; 
	CheckboxInfo.DisplayLabel = "Checkbox";
	DisplayInfos.AddItem(CheckboxInfo);

	CheckboxInfo.ShowCheckBox = true; 
	CheckboxInfo.ShowCompleted = true; 
	CheckboxInfo.ShowFailed = false; 
	CheckboxInfo.DisplayLabel = "Checkbox";
	DisplayInfos.AddItem(CheckboxInfo);

	WarningInfo.ShowWarning = true; 
	WarningInfo.DisplayLabel = "Warning!";  
	DisplayInfos.AddItem(WarningInfo);

	SimpleTextInfo.DisplayLabel = "Simple Text";  
	DisplayInfos.AddItem(SimpleTextInfo);

	TimerInfo.Timer = 6; 
	TimerInfo.ShowCompleted = true; 
	TimerInfo.ShowFailed = false; 
	TimerInfo.DisplayLabel = "Timer";
	DisplayInfos.AddItem(TimerInfo);

	TimerInfo.Timer = 5; 
	TimerInfo.ShowCompleted = false; 
	TimerInfo.ShowFailed = false; 
	TimerInfo.DisplayLabel = "Timer"; 
	DisplayInfos.AddItem(TimerInfo);

	TimerInfo.Timer = 6; 
	TimerInfo.ShowCompleted = false; 
	TimerInfo.ShowFailed = true; 
	TimerInfo.DisplayLabel = "Timer"; 
	DisplayInfos.AddItem(TimerInfo);

	ClickableButtonInfo.ShowHeader = true;
	ClickableButtonInfo.DisplayLabel = "Clickable button";
	DisplayInfos.AddItem(ClickableButtonInfo);

	CounterInfo.CounterHaveImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Evidence_Recovered; 
	CounterInfo.CounterAvailableImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Evidence_Available; 
	CounterInfo.CounterLostImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Evidence_Destroyed; 
	CounterInfo.CounterHaveAmount = 1; 
	CounterInfo.CounterHaveMin = 2; 
	CounterInfo.CounterAvailableAmount = 3; 
	CounterInfo.CounterLostAmount = 4;  
	DisplayInfos.AddItem(CounterInfo);

	CounterInfo.CounterHaveImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Civilians_Rescued; 
	CounterInfo.CounterAvailableImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Civilians_Available; 
	CounterInfo.CounterLostImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Civilians_Dead; 
	CounterInfo.CounterHaveAmount = 11; 
	CounterInfo.CounterHaveMin = 22; 
	CounterInfo.CounterAvailableAmount = 33; 
	CounterInfo.CounterLostAmount = 44;
	DisplayInfos.AddItem(CounterInfo);

	// GROUP IDS -------------- 

	ClickableButtonInfo.ShowHeader = true;
	ClickableButtonInfo.DisplayLabel = "Clickable button"; 
	ClickableButtonInfo.GroupID = 0;  
	DisplayInfos.AddItem(ClickableButtonInfo);
	
	WarningInfo.ShowWarning = true; 
	WarningInfo.DisplayLabel = "Warning";
	WarningInfo.GroupID = 0;  
	DisplayInfos.AddItem(WarningInfo);

	SimpleTextInfo.DisplayLabel = "Simple Text";
	SimpleTextInfo.GroupID = 0;
	DisplayInfos.AddItem(SimpleTextInfo);

	SimpleTextInfo.DisplayLabel = "Simple Text";
	SimpleTextInfo.GroupID = 0;
	DisplayInfos.AddItem(SimpleTextInfo);
	
	CounterInfo.CounterHaveImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Civilians_Rescued; 
	CounterInfo.CounterAvailableImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Civilians_Available; 
	CounterInfo.CounterLostImage = class'UIUtilities_Image'.const.ObjectivesListCounter_Civilians_Dead; 
	CounterInfo.CounterHaveAmount = 11; 
	CounterInfo.CounterHaveMin = 22; 
	CounterInfo.CounterAvailableAmount = 33; 
	CounterInfo.CounterLostAmount = 44;
	CounterInfo.GroupID = 0;  
	DisplayInfos.AddItem(CounterInfo);

	ClickableButtonInfo.DisplayLabel = "Clickable button";  
	ClickableButtonInfo.GroupID = 1;
	DisplayInfos.AddItem(ClickableButtonInfo);

	SimpleTextInfo.DisplayLabel = "Simple Text";
	SimpleTextInfo.GroupID = 1;
	DisplayInfos.AddItem(SimpleTextInfo);

	SimpleTextInfo.DisplayLabel = "Simple Text";
	SimpleTextInfo.GroupID = 1;
	DisplayInfos.AddItem(SimpleTextInfo);

	ClickableButtonInfo.ShowHeader = true;
	ClickableButtonInfo.DisplayLabel = "Clickable Button 2";
	ClickableButtonInfo.GroupID = 2;  
	DisplayInfos.AddItem(ClickableButtonInfo);

	WarningInfo.ShowWarning = true; 
	WarningInfo.DisplayLabel = "Warning";
	WarningInfo.GroupID = 2;  
	DisplayInfos.AddItem(WarningInfo);

	SimpleTextInfo.DisplayLabel = "Simple Text";
	SimpleTextInfo.GroupID = 2;
	DisplayInfos.AddItem(SimpleTextInfo);
	
	CheckboxInfo.ShowCheckBox = true; 
	CheckboxInfo.ShowCompleted = false; 
	CheckboxInfo.ShowFailed = true; 
	CheckboxInfo.DisplayLabel = "Checkbox";
	CheckboxInfo.GroupID = 2; 
	DisplayInfos.AddItem(CheckboxInfo);

	CheckboxInfo.ShowCheckBox = true; 
	CheckboxInfo.ShowCompleted = false; 
	CheckboxInfo.ShowFailed = false; 
	CheckboxInfo.DisplayLabel = "Checkbox";
	CheckboxInfo.GroupID = 2; 
	DisplayInfos.AddItem(CheckboxInfo);

	CheckboxInfo.ShowCheckBox = true; 
	CheckboxInfo.ShowCompleted = true; 
	CheckboxInfo.ShowFailed = false; 
	CheckboxInfo.DisplayLabel = "Checkbox";
	CheckboxInfo.GroupID = 2; 
	DisplayInfos.AddItem(CheckboxInfo);

	return DisplayInfos;
}

simulated function int SortObjectives(ObjectiveDisplayInfo A, ObjectiveDisplayInfo B)
{
	if( A.bIsDarkEvent != B.bIsDarkEvent ) return A.bIsDarkEvent ? -1 : 1;
	if(A.GroupID != B.GroupID) return (B.GroupID < A.GroupID) ? -1 : 1;
	if(A.MissionType != B.MissionType) 
	{
		if(A.MissionType == "TITLE") return 1; 
		if(B.MissionType == "TITLE") return -1;

		if(A.MissionType == "DARKEVENTTITLE") return -1;
		if(B.MissionType == "DARKEVENTTITLE") return 1;

		return 1; 
	}
	if(A.ShowHeader != B.ShowHeader) return B.ShowHeader ? -1 : 1;
	if(A.CounterHaveAmount != B.CounterHaveAmount) return (B.CounterHaveAmount > a.CounterHaveAmount) ? -1 : 1;
	if(A.ShowWarning != B.ShowWarning) return B.ShowWarning ? -1 : 1;
	if(A.Timer != B.Timer) return (B.Timer > A.Timer) ? -1 : 1; // timers go at the top
	if(A.ShowCheckBox != B.ShowCheckBox) return (B.ShowCheckBox) ? -1 : 1;
	if(A.ShowFailed != B.ShowFailed) return B.ShowFailed ? -1 : 1;
	if(A.ShowCompleted != B.ShowCompleted) return B.ShowCompleted ? -1 : 1;

	return 0;
}

simulated function RefreshDisplay(array<ObjectiveDisplayInfo> Data, optional bool bForce = false)
{
	local UIObjectiveListItem Item; 
	local int i; 

	if( Data.length != Items.Length )
		ClearList();

	for( i = 0; i < Data.Length; i++ )
	{
		// Build new items if we need to. 
		if( i > Items.Length-1 )
		{
			Item = Spawn(class'UIObjectiveListItem', self).InitObjectiveListItem(self);
			Item.ID = i; 
			Items.AddItem(Item);
		}
		
		// Grab our target Item
		Item = Items[i]; 

		//Update Data 
		Item.RefreshDisplay(Data[i], bForce); 

		Item.Show();
	}
}
function ClearList()
{
	local int i;

	for( i = Items.length; i > -1; i-- )
	{
		Items[i].Remove();
	}
	Items.length = 0; 
}


simulated public function Show()
{
	local XComHeadquartersCheatManager CheatMgr;

	// If in Strategy check if objectives hidden by cheat
	if(XComHQPresentationLayer(Movie.Pres) != none)
	{
		CheatMgr = XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager);

		if(CheatMgr != none && CheatMgr.bHideObjectives)
		{
			return;
		}

		if (class'UIUtilities_Strategy'.static.GetXComHQ().bBlockObjectiveDisplay)
		{
			return;
		}
	}

	super.Show();
}

simulated function Hide()
{
	super.Hide();
}

simulated function OnItemChanged( UIObjectiveListItem Item )
{
	local int i; 
	local float currentYPosition; 

	//Update all positions, because of selective callbacks that may skip earlier items. 
	currentYPosition = Items[0].Y; 

	for( i = 0; i < Items.Length; i++ )
	{
		Item = Items[i]; 

		if( !Item.bIsVisible )
			continue;

		Item.SetY(currentYPosition);
		currentYPosition += Item.height; 
	}

	if( height != currentYPosition )
	{
		height = currentYPosition;
	}
}


simulated function OnClickGroup( int GroupID )
{
	local UIObjectiveListItem Item, FirstItem, LastItem; 
	local int i, IndexInGroup; 
	local float MaxWidth; 

	if( GroupID == -1 ) return;
	MaxWidth = 100; // set a minimum.
	IndexInGroup = -1; 

	for( i = 0; i < Items.Length; i++ )
	{
		Item = Items[i]; 

		if( Item.Data.GroupID != GroupID )
			continue;

		if(FirstItem == none ) 
			FirstItem = Item; 

		Item.ToggleVisibility(IndexInGroup++);

		if( Item.Width > MaxWidth ) 
			MaxWidth = Item.Width; 

		LastItem = Item; 
	}

	OnItemChanged(none); 
	//Draw BG rect around group 
	FirstItem.RefreshGroupBG( MaxWidth, LastItem.Y + LastItem.Height - FirstItem.Y ); 
}

simulated function CloseGroups()
{
	local UIObjectiveListItem Item; 
	local int i, GroupID; 

	GroupID = -1; 

	for( i = 0; i < Items.Length; i++ )
	{
		Item = Items[i]; 
		if( Item.Data.GroupID != GroupID )
		{
			GroupID = Item.Data.GroupID; 
			OnClickGroup(Item.Data.GroupID);
		}
	}
}

simulated function RefreshPositionBasedOnCounter(XComGameState_AIReinforcementSpawner AISpawnerState)
{
	if( AISpawnerState != none && AISpawnerState.Countdown > 0 )
	{
		SetPosition(ReinforcementsPos.X, ReinforcementsPos.Y);
	}
	else
	{
		SetPosition(InitPos.X, InitPos.Y);
	}
}


simulated function ShowCompletedObjectivesDialogue(XComGameState NewGameState)
{
	local TDialogueBoxData DialogData;
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	// reset any leftover values
	ParamTag.IntValue0 = 0;
	ParamTag.StrValue0 = "";

	DialogData.strTitle = m_strObjectivesCompleteTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strObjectivesCompleteBody);
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	PC.Pres.UIRaiseDialog(DialogData);
	
}

// Start Issue #449
function bool IsReinforcementsAlertForced(XComGameState AssociatedGameState)
{
	local UITacticalHUD TacticalHUD;
	local UITacticalHUD_Countdown Countdown;

	// Dummy variables for CheckForReinforcementsOverride as we're only interested
	// in the return value.
	local string sTitle, sBody, sColor;

	TacticalHUD = UITacticalHUD(GetParent(class'UITacticalHUD'));
	Countdown = TacticalHUD.m_kCountdown;

	// If the reinforcements alert is already visible, then don't bother checking
	// for the reinforcements override. It should save a bit of time, particularly
	// if there are a lot of listeners or slow listeners.
	return Countdown != none && (Countdown.bIsVisible || Countdown.CheckForReinforcementsOverride(sTitle, sBody, sColor, AssociatedGameState));
}
// End Issue #449

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	bIsNavigable = false; 
}