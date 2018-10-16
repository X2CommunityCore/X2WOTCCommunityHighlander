//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITLE_LadderModeMenu.uc
//  AUTHOR:  Joe Cortese
//----------------------------------------------------------------------------
//  Copyright (c) 2018 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITLE_LadderModeMenu extends UITLEScreen
	Native(UI);

var UINavigationHelp NavHelp;
var UIList List;
var UIList NarrativeList;
var UIList ClickedList;
var UIPanel NarrativeHeader;
var UIPanel RandomLadderHeader;
var int clickedIndex;

var int m_HeadshotsRecieved;
var array<string> m_LadderList;
var array<int> m_LadderDifficulties;

var array<OnlineSaveGame> m_arrSaveGames;

var UIPanel MissionInfo;
var array<UIPanel> SoldierInfoPanels;
var array<UIButton> LadderSoldierInfoButtons;
var UIPanel LeftColumn;

var localized string m_ScreenTitle;
var localized string m_strAbandonLadder;
var localized string m_strDeleteLadder;
var localized string m_strBeginLadder;
var localized string m_strContinueLadder;
var localized string m_PreviousLadder;
var localized string m_LockedLabel;
var localized string m_LockedValue;
var localized string m_Medals;
var localized string m_ScoreLabel;
var localized string m_DifficultyLabel;
var localized string m_ProgressLabel;
var localized string m_MissionLabel;
var localized string m_ObjectiveLabel;
var localized string m_RandomObjective;
var localized string m_RandomLadderHeader;
var localized string m_StartNewRandomLadder;
var localized string m_NarrativeLaddersHeader;
var localized string m_DestructiveActionTitle;
var localized string m_DestructiveActionBody;
var localized string m_DeleteDestructiveActionTitle;
var localized string m_DeleteDestructiveActionBody;
var localized string m_MedalProgress;
var localized array<String> m_MedalTypes;
var localized array<String> m_arrDifficultyTypeStrings;
var localized array<String> m_arrNarrativeStrings;

struct native LadderSaveData
{
	var string Filename;
	var int SaveID;

	var int LadderIndex;
	var int MissionIndex;
};

var array<LadderSaveData> m_LadderSaveData;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i;
	local String soldiername;

	super.InitScreen(InitController, InitMovie, InitName);

	LeftColumn = Spawn(class'UIPanel', self);
	LeftColumn.bIsNavigable = true; 
	LeftColumn.InitPanel('LeftColumnContainer');	
	Navigator.SetSelected(LeftColumn);
	LeftColumn.Navigator.LoopSelection = true; 

	NarrativeList = Spawn(class'UIList', LeftColumn);
	NarrativeList.bSelectFirstAvailable = true;
	NarrativeList.bStickyClickyHighlight = false;
	NarrativeList.InitList('NarrativeList', 396, 152, 450, 400);
	NarrativeList.bPermitNavigatorToDefocus = true;
	NarrativeList.Navigator.LoopSelection = false;
	NarrativeList.Navigator.LoopOnReceiveFocus = true;
	NarrativeList.OnItemClicked = OnSelectedChange; // todo @bsteiner this is need for both control schemes
	LeftColumn.Navigator.SetSelected(NarrativeList);

	List = Spawn(class'UIList', LeftColumn);
	List.InitList('BrowserList', 396, 520, 450, 500);
	List.bStickyClickyHighlight = false;
	List.bPermitNavigatorToDefocus = true;
	List.Navigator.LoopSelection = false;
	List.Navigator.LoopOnReceiveFocus = true;
	List.OnItemClicked = OnSelectedChange;

	ClickedList = NarrativeList;
	clickedIndex = 0;

	for (i = 0; i < 6; i++)
	{
		soldiername = "MissionInfo.Soldier" $ i;
		SoldierInfoPanels.AddItem(Spawn(class'UIPanel', self));
		SoldierInfoPanels[i].bIsNavigable = false;
		SoldierInfoPanels[i].InitPanel(name(soldiername), 'TLE_SoldierInfoWidget');
	}

	for (i = 0; i < 6; i++)
	{
		soldiername = "SoldierInfoButton" $ i;
		LadderSoldierInfoButtons.AddItem(Spawn(class'UIButton', self));
		LadderSoldierInfoButtons[i].bIsNavigable = false; 
		LadderSoldierInfoButtons[i].InitButton(name(soldiername), , , , 'X2InfoButton');
		LadderSoldierInfoButtons[i].ProcessMouseEvents(OnClickSoldierInfo);
		//SoldierInfoPanels[i].AddChild(LadderSoldierInfoButtons[i]);
		if (i < 3)
		{
			LadderSoldierInfoButtons[i].SetPosition(950 + (i*200), 645);
		}
		else
		{

			LadderSoldierInfoButtons[i].SetPosition(950 + ((i%3)*200), 805);
		}
		//LadderSoldierInfoButtons[i].AnchorBottomLeft();
	}

	NarrativeHeader = Spawn(class'UIPanel', self);
	NarrativeHeader.bIsNavigable = false;
	NarrativeHeader.bAnimateOnInit = false;
	NarrativeHeader.InitPanel('NarrativeHeader');

	RandomLadderHeader = Spawn(class'UIPanel', self);
	RandomLadderHeader.bIsNavigable = false;
	RandomLadderHeader.bAnimateOnInit = false;
	RandomLadderHeader.InitPanel('RandomLadderHeader');

	//MissionInfo = Spawn(class'UIPanel', self);
	//MissionInfo.InitPanel('LadderMissionInfoPanel', 'LadderMissionInfoPanel');

	NavHelp = GetNavHelp();
	UpdateNavHelp();
}

simulated function OnClickSoldierInfo(UIPanel Panel, int Cmd)
{
	local int index;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitStateRef;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> unitArray;

	History = class'XComGameStateHistory'.static.GetGameStateHistory();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	switch (Panel)
	{
	case LadderSoldierInfoButtons[0]:
		index = 0;
		break;
	case LadderSoldierInfoButtons[1]:
		index = 1;
		break;
	case LadderSoldierInfoButtons[2]:
		index = 2;
		break;
	case LadderSoldierInfoButtons[3]:
		index = 3;
		break;
	case LadderSoldierInfoButtons[4]:
		index = 4;
		break;
	case LadderSoldierInfoButtons[5]:
		index = 5;
		break;
	};
	
	if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		foreach XComHQ.Squad(UnitStateRef)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateRef.ObjectID));
			if (UnitState.bMissionProvided) // don't show stats for mission units like VIPs
				continue;

			unitArray.AddItem(UnitState);
		}
		Movie.Pres.UITLEUnitStats(unitArray, index, XComHQ.GetParentGameState());
	}
}

simulated function UINavigationHelp GetNavHelp()
{
	local UINavigationHelp Result;
	Result = PC.Pres.GetNavHelp();
	if (Result == None)
	{
		if (`PRES != none) // Tactical
		{
			Result = Spawn(class'UINavigationHelp', self).InitNavHelp();
			Result.SetX(-500); //offset to match the screen. 
		}
		else if (`HQPRES != none) // Strategy
			Result = `HQPRES.m_kAvengerHUD.NavHelp;
	}
	return Result;
}

simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnCancel);

	if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddLeftHelp(class'UITacticalHUD_MouseControls'.default.m_strSoldierInfo, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	}
	NavHelp.Show();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local UIList TargetList;


	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if( !bIsInited )
		return true;

	bHandled = false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
		TargetList = UIList( LeftColumn.Navigator.GetSelected() );
		if( TargetList != none )
		{
			OnLadderClicked(TargetList, TargetList.SelectedIndex);
		}
		return true;
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		OnCancel();
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_Y :
		OnClickSoldierInfo(SoldierInfoPanels[0], class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_X :
		if(HasLadderSave(GetCurrentLadderIndex()))
			AbandonLadderPopup();
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_R3 :
		if (GetCurrentLadderIndex() >= 10)
			DeleteLadderPopup();
		return true;


	case class'UIUtilities_Input'.const.FXS_DPAD_UP :
	case class'UIUtilities_Input'.const.FXS_ARROW_UP :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP :
	case class'UIUtilities_Input'.const.FXS_KEY_W :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_UP, arg);

		TargetList = UIList(LeftColumn.Navigator.GetSelected());
		if( TargetList != none )
		{
			OnSelectedChange(TargetList, TargetList.SelectedIndex);
		}
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN :
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN :
	case class'UIUtilities_Input'.const.FXS_KEY_S :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_DOWN, arg);

		TargetList = UIList(LeftColumn.Navigator.GetSelected());
		if( TargetList != none )
		{
			OnSelectedChange(TargetList, TargetList.SelectedIndex);
		}
		break;

	default:
		bHandled = false;
		break;
	}

	if( !bHandled && Navigator.GetSelected() != none && Navigator.GetSelected().OnUnrealCommand(cmd, arg) )
	{
		bHandled = true;
	}

	// always give base class a chance to handle the input so key input is propogated to the panel's navigator
	return (bHandled || super.OnUnrealCommand(cmd, arg));
}

simulated function OnLadderClicked(UIList ContainerList, int ItemIndex)
{
	local int LadderIndex;
	local LadderSaveData SaveData;	
	local XComOnlineEventMgr OnlineEventMgr;
	
	if (ContainerList == NarrativeList && UITLENarrativeLadder_ListItem(NarrativeList.GetItem(ItemIndex)).bDisabled)
	{
		return;
	}

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	if (ClickedList == List)
	{
		clickedIndex += NarrativeList.GetItemCount() - 1;
	}
	LadderIndex = int(m_LadderList[clickedIndex]);

	OnlineEventMgr = `ONLINEEVENTMGR;
	OnlineEventMgr.ClearUpdateSaveListCompleteDelegate(OnReadSaveGameListComplete);

	if (ItemIndex != 0 || ContainerList != List)
	{
		// selected a ladder with an in progress savegame, just launch it
		foreach m_LadderSaveData(SaveData)
		{
			if (SaveData.LadderIndex == LadderIndex)
			{			
				OnlineEventMgr.LoadGame(SaveData.SaveID);
				return;
			}
		}
	}

	Movie.Pres.UITLE_LadderDifficulty();
}

simulated function bool IsNarrativeLadderSelected()
{
	return ClickedList == NarrativeList;
}

simulated function int GetRequiredLadderDifficulty()
{
	if ((clickedIndex == NarrativeList.GetItemCount() - 1) && (ClickedList == List)) // Selected new procedural ladder
	{
		return -1;
	}

	// return the difficulty for the selected procedural ladder
	return m_LadderDifficulties[ clickedIndex ];
}

simulated function bool HasLadderSave(int LadderID)
{
	local LadderSaveData SaveData;
	
	foreach m_LadderSaveData(SaveData)
	{
		if (SaveData.LadderIndex == LadderID)
		{
			return true;
		}
	}

	return false;
}

simulated function OnDifficultySelectionCallback(name eAction, int selectedDifficulty, bool NarrativesOn)
{
	local int LadderIndex;

	if (eAction != 'eUIAction_Accept')
	{
		return;
	}

	if ((clickedIndex == NarrativeList.GetItemCount() - 1) && (ClickedList == List)) // Selected new procedural ladder
	{
		CreateNewLadder(selectedDifficulty, NarrativesOn);
		return;
	}
	else
	{
		LadderIndex = int(m_LadderList[clickedIndex]);

		StartLadder(LadderIndex, selectedDifficulty, NarrativesOn);
	}
}

simulated function StartLadder(int LadderIndex, int DifficultySelection, bool NarrativesOn)
{
	local XComGameStateHistory History;	
	local XComGameState_CampaignSettings CurrentCampaign;
	local XComGameState_LadderProgress LadderData;
	local int SoldierIndex;
	local XComGameState_Unit GameUnit;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitStateRef;

	History = class'XComGameStateHistory'.static.GetGameStateHistory();

	if (LadderIndex >= 10) // replaying a procedural ladder, difficulty is locked to what was generated
	{
		History.ReadHistoryFromFile("Ladders/", "Ladder_" $ LadderIndex);

		CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		DifficultySelection = CurrentCampaign.DifficultySetting;
	}
	
	// starting an existing ladder from scratch
	XComCheatManager(GetALocalPlayerController().CheatManager).StartLadder(LadderIndex, DifficultySelection);
	
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	LadderData = XComGameState_LadderProgress(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));

	SoldierIndex = 0;
	foreach XComHQ.Squad(UnitStateRef)
	{
		// pull the unit from the archives, and add it to the start state
		GameUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateRef.ObjectID));

		if(LadderIndex <= 4)
			class'XComGameState_LadderProgress'.static.LocalizeUnitName(GameUnit, SoldierIndex, LadderIndex);

		++SoldierIndex;
	}

	CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	CurrentCampaign.BizAnalyticsCampaignID = `FXSLIVE.GetGUID();

	`FXSLIVE.BizAnalyticsLadderStart(CurrentCampaign.BizAnalyticsCampaignID, LadderIndex, true, DifficultySelection, LadderData.SquadProgressionName);
}

simulated function OnHoverChange(UIList ContainerList, int ItemIndex)
{
	RefreshButtonHelpLabels(0);
}

simulated function OnSelectedChange(UIList ContainerList, int ItemIndex)
{
	local int i;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	ClickedList = ContainerList;
	clickedIndex = ItemIndex;

	if (ContainerList == List && ItemIndex == 0)
	{
		MC.FunctionVoid("SetLayoutRandom");
		MC.FunctionVoid("HideMissionTimeline");
		for (i = 0; i < 6; i++)
		{
			if (i < 3)
			{
				LadderSoldierInfoButtons[i].SetPosition(950 + (i * 200), 425);
			}
			else
			{

				LadderSoldierInfoButtons[i].SetPosition(950 + ((i % 3) * 200), 585);
			}
		}

		mc.BeginFunctionOp("SetMissionObjective");
		mc.QueueString("");
		mc.QueueString("");
		MC.EndOp();

		mc.BeginFunctionOp("SetMissionDifficulty");
		mc.QueueString("");
		mc.QueueString("");
		mc.EndOp();

		mc.BeginFunctionOp("SetMissionInfo");
		mc.QueueString("");
		MC.EndOp();

		mc.BeginFunctionOp("SetCurrentLadderScore");
		mc.QueueNumber(0);
		mc.QueueString(m_ScoreLabel);
		mc.EndOp();

		mc.BeginFunctionOp("SetLadderLock");
		mc.QueueBoolean(false);
		mc.QueueString("");
		mc.QueueString("");
		MC.EndOp();

		RefreshButtonHelpLabels(-1);
		m_HeadshotsRecieved = 0;
		while (m_HeadshotsRecieved < 6)
		{
			LadderSoldierInfoButtons[m_HeadshotsRecieved].Hide();
			
			MC.BeginFunctionOp("HideSoldierData");
			MC.QueueNumber(m_HeadshotsRecieved++);
			MC.EndOp();
		}
	}
	else
	{
		MC.FunctionVoid("ShowMissionTimeline");
		if (ContainerList == List)
		{
			MC.FunctionVoid("SetLayoutRandom");
			for (i = 0; i < 6; i++)
			{
				if (i < 3)
				{
					LadderSoldierInfoButtons[i].SetPosition(950 + (i * 200), 425);
				}
				else
				{

					LadderSoldierInfoButtons[i].SetPosition(950 + ((i % 3) * 200), 585);
				}
			}
			ItemIndex += NarrativeList.GetItemCount() - 1;
		}
		else
		{
			MC.FunctionVoid("SetLayoutNarrative");
			for (i = 0; i < 6; i++)
			{
				if (i < 3)
				{
					LadderSoldierInfoButtons[i].SetPosition(950 + (i * 200), 645);
				}
				else
				{

					LadderSoldierInfoButtons[i].SetPosition(950 + ((i % 3) * 200), 805);
				}
			}
		}

		UpdateData(ItemIndex);
	}
}

simulated function OnLadderAbandoned( UIList ContainerList, int ItemIndex )
{
	local int LadderIndex;
	local XComGameStateHistory History;
	local XComGameState_LadderProgress LadderData;
	local XComGameState_CampaignSettings CurrentCampaign;
	local LadderSaveData SaveData;

	LadderIndex = GetCurrentLadderIndex();

	// selected a ladder with an in progress savegame
	foreach m_LadderSaveData( SaveData )
	{
		if (SaveData.LadderIndex == LadderIndex)
		{
			History = class'XComGameStateHistory'.static.GetGameStateHistory();

			History.ReadHistoryFromFile( "Ladders/", "Ladder_" $ LadderIndex );
			
			CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
			LadderData = XComGameState_LadderProgress(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));

			`FXSLIVE.BizAnalyticsLadderEnd( CurrentCampaign.BizAnalyticsCampaignID, LadderIndex, 0, 0, LadderData.SquadProgressionName, CurrentCampaign.DifficultySetting );

			`ONLINEEVENTMGR.DeleteSaveGame( SaveData.SaveID );
			`ONLINEEVENTMGR.UpdateSaveGameList();

			XComCheatManager(GetALocalPlayerController().CheatManager).CreateLadder( LadderIndex, LadderData.LadderSize, CurrentCampaign.DifficultySetting );

			if(ContainerList == NarrativeList)
				UpdateData(ItemIndex);
			else
				UpdateData(ItemIndex + 4);

			return;
		}
	}

	// shouldn't be able to get here as we should only be able to abandon an in progress ladder which means there's a matching save
}

simulated function OnInit()
{
	local XComOnlineEventMgr OnlineEventMgr;

	super.OnInit();

	mc.FunctionString("SetScreenTitle", m_ScreenTitle);
	mc.FunctionString("SetMedalProgressLabel", m_MedalProgress);

	NarrativeHeader.MC.FunctionString("SetLabel", m_NarrativeLaddersHeader);
	RandomLadderHeader.MC.FunctionString("SetLabel", m_RandomLadderHeader);

	OnlineEventMgr = `ONLINEEVENTMGR;
	OnlineEventMgr.AddUpdateSaveListCompleteDelegate(OnReadSaveGameListComplete);
	OnlineEventMgr.UpdateSaveGameList();
}


simulated function OnReadSaveGameListComplete(bool bWasSuccessful)
{
	local int SaveIdx;
	local bool IsLadder;
	local SaveGameHeader Header;
	local LadderSaveData LadderSave;

	m_LadderSaveData.Length = 0;

	if( bWasSuccessful )
		`ONLINEEVENTMGR.GetSaveGames( m_arrSaveGames );
	else
		m_arrSaveGames.Remove( 0, m_arrSaveGames.Length );

	class'UILoadGame'.static.FilterSaveGameList( m_arrSaveGames, , false );

	SaveIdx = 0;
	while (SaveIdx < m_arrSaveGames.Length)
	{
		Header = m_arrSaveGames[ SaveIdx ].SaveGames[ 0 ].SaveGameHeader;
		IsLadder = Header.bLadder;

		if (!IsLadder)
			m_arrSaveGames.Remove( SaveIdx, 1 );
		else
		{
			LadderSave.Filename = m_arrSaveGames[ SaveIdx ].Filename;
			LadderSave.SaveID = `ONLINEEVENTMGR.SaveNameToID( LadderSave.Filename );

			LadderSave.LadderIndex = Header.GameNum;
			LadderSave.MissionIndex = Header.Mission;

			m_LadderSaveData.AddItem( LadderSave );

			++SaveIdx;
		}
	}
	
	InitializeLadderList();

	UpdateData(0);
}

simulated native function int GetLadderListSize();
simulated native function DeleteLadderFiles(int DeletedLadder);

simulated function SortLadderList( )
{
	local string LadderFilename;
	local array<int> LadderIndicies;
	local int LadderIndex;
	local int i, j;

	// convert all the file names to ladder indicies
	foreach m_LadderList( LadderFilename )
	{
		LadderFilename = Left(LadderFilename, InStr(LadderFilename, ".x2hist"));
		LadderFilename = Mid(LadderFilename, 7);
		LadderIndicies.AddItem( int(LadderFilename) );
	}

	// order the ladder names in ascending order by ladder index
	// do a super simple bubble sort, the ladder list isn't usually going to be too big
	// and string manipulation in C++ (required for better sort algorithms
	for (i = 0; i < m_LadderList.Length - 1; ++i)
	{
		for (j = i + 1; j < m_LadderList.Length; ++j)
		{
			if (LadderIndicies[j] < LadderIndicies[i])
			{
				LadderIndex = LadderIndicies[j];
				LadderFilename = m_LadderList[j];

				LadderIndicies[j] = LadderIndicies[i];
				m_LadderList[j] = m_LadderList[i];

				LadderIndicies[i] = LadderIndex;
				m_LadderList[i] = LadderFilename;
			}
		}
	}
}

simulated function InitializeLadderList()
{
	local int i, LadderIndex, LadderScore, BronzeScore;
	local XComGameStateHistory History;
	local XComGameState_LadderProgress LadderData;
	local UITLENarrativeLadder_ListItem ListItem;
	local XComOnlineProfileSettings ProfileSettings;
	local UIListItemString ListItemString;
	local XComGameState_CampaignSettings CampaignSettings;

	ProfileSettings = `XPROFILESETTINGS;

	List.ClearItems();
	NarrativeList.ClearItems();
	m_LadderList.Remove(0, m_LadderList.Length);

	GetLadderListSize();
	SortLadderList();
	History = class'XComGameStateHistory'.static.GetGameStateHistory();

	Spawn(class'UIListItemString', List.itemContainer).InitListItem(m_StartNewRandomLadder);
	
	m_LadderDifficulties.Length = m_LadderList.Length;
	for (i = 0; i < m_LadderList.Length; i++)
	{
		ListItem = none;
		ListItemString = none;

		m_LadderList[i] = Left(m_LadderList[i], InStr(m_LadderList[i], ".x2hist"));
		History.ReadHistoryFromFile("Ladders/", m_LadderList[i]);

		m_LadderList[i] = Mid(m_LadderList[i], 7);
		LadderData = XComGameState_LadderProgress(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));
		LadderIndex = int( m_LadderList[ i ] );

		CampaignSettings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', false));
		m_LadderDifficulties[i] = CampaignSettings.DifficultySetting;
		
		if (LadderIndex < 10)
		{
			ListItem = Spawn(class'UITLENarrativeLadder_ListItem', NarrativeList.itemContainer).InitTLENarrativeLadderListItem(LadderData);
			if( NarrativeList.GetSelectedItem() == none )
				NarrativeList.SetSelectedIndex(0);
		}
		else
		{
			ListItemString = Spawn(class'UIListItemString', List.itemContainer).InitListItem(LadderData.LadderName);
		}

		//Hackity sax! Default highlighting jiggle the handle. -bsteiner
		if( i == 0 && `ISCONTROLLERACTIVE)
		{
			if( ListItem != none )
				ListItem.SetSelectedNavigation();
			else if( ListItemString != none )
				ListItemString.SetSelectedNavigation();
		}
		
		if ((LadderIndex > 1) && (LadderIndex < 10)) // is this a narrative ladder?
		{
			LadderScore = ProfileSettings.Data.GetLadderHighScore( LadderIndex - 1 );
			BronzeScore = class'XComGameState_LadderProgress'.static.GetLadderMedalThreshold( LadderIndex - 1, 0 );

			if (LadderScore < BronzeScore)
				ListItem.SetDisabled(true);
		}
	}
}

simulated function string GetObjectivesDesc(XComGameState_ObjectivesList ObjectivesList)
{
	local int Index;

	for( Index = 0; Index < ObjectivesList.ObjectiveDisplayInfos.Length; Index++ )
	{
		if( ObjectivesList.ObjectiveDisplayInfos[Index].DisplayLabel != ""  && ObjectivesList.ObjectiveDisplayInfos[Index].ShowCheckbox)
		{
			return ObjectivesList.ObjectiveDisplayInfos[Index].DisplayLabel;
		}
	}

	//No objective info found 
	return "";
}

simulated function UpdateData(int LadderIndex)
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleDataState;
	local XComGameState_LadderProgress LadderData;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitStateRef;
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate SoldierClass;
	local LadderSaveData currentSave;
	local int i, goldMedalProgress, currentMedalProgress, ladderHighScore;
	local float medalPercentage;
	local Texture2D SoldierPicture;
	local XComGameState_CampaignSettings CurrentCampaign;
	local string completePrevious;
	local string ObjectiveDesc; 
	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;

	History = class'XComGameStateHistory'.static.GetGameStateHistory();
	History.ReadHistoryFromFile("Ladders/", "Ladder_" $ m_LadderList[LadderIndex]);

	LadderData = XComGameState_LadderProgress(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	RefreshButtonHelpLabels(LadderData.LadderIndex);
	ladderHighScore = `XPROFILESETTINGS.data.GetLadderHighScore(LadderData.LadderIndex);

	if (LadderIndex < 10)
	{
		mc.BeginFunctionOp("SetLadderLock");
		mc.QueueBoolean(UITLENarrativeLadder_ListItem(NarrativeList.GetItem(LadderIndex)).bDisabled);
		mc.QueueString(m_LockedLabel);
		if (LadderIndex > 0)
		{
			completePrevious = Repl(m_LockedValue, "%sPREVIOUSLADDER", LadderData.NarrativeLadderNames[LadderData.LadderIndex - 1]);
			mc.QueueString(completePrevious);
		}
		else
		{
			mc.QueueString(m_LockedValue);
		}
		MC.EndOp();
	}

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(BattleDataState.MapData.ActiveMission.MissionName);

	ObjectiveDesc = MissionTemplate.DisplayName;
	mc.BeginFunctionOp("SetMissionObjective");
	if( ObjectiveDesc == "" )
	{
		mc.QueueString("");
		mc.QueueString("");
	}
	else
	{
		mc.QueueString(m_ObjectiveLabel);
		mc.QueueString(ObjectiveDesc);
	}
	MC.EndOp();

	mc.BeginFunctionOp("SetMissionInfo");
	mc.QueueString(`MAPS.SelectMapImage(BattleDataState.MapData.ParcelData[0].MapName));
	MC.EndOp();

	foreach m_LadderSaveData(currentSave)
	{
		if (currentSave.LadderIndex == LadderData.LadderIndex)
		{
			break;
		}
	}

	if (currentSave.LadderIndex != LadderData.LadderIndex)
	{
		currentSave.Filename = "";
		currentSave.MissionIndex = 0;
	}

	for (i = 0; i < LadderData.LadderSize; i++)
	{
		mc.BeginFunctionOp("SetMissionNode");
		mc.QueueNumber(i);

		/*
		NODE_LOCKED     = 0;
		NODE_READY      = 1;
		NODE_COMPLETE   = 2;
		NODE_BOSSLOCKED = 3;
		NODE_BOSS       = 4;
		*/
		if (currentSave.Filename == "")
		{
			if (ladderHighScore > 0)
			{
				mc.QueueNumber(2);
			}
			else
			{
				mc.QueueNumber(0);
			}
		}
		else
		{
			if (i < currentSave.MissionIndex - 1)
			{
				mc.QueueNumber(2);
			}
			else
			{
				if (i == currentSave.MissionIndex - 1)
				{
					mc.QueueNumber(1);
				}
				else
				{
					mc.QueueNumber(0);
				}
			}
		}
		mc.EndOp();
	}
	mc.BeginFunctionOp("SetMissionProgressText");
	MC.QueueString(m_ProgressLabel);
	MC.QueueString(m_MissionLabel);
	MC.QueueString(LadderData.LadderRung @ "/" @ LadderData.LadderSize);
	mc.EndOp();

	CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	m_HeadshotsRecieved = 0;
	foreach XComHQ.Squad(UnitStateRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateRef.ObjectID));
		SoldierClass = UnitState.GetSoldierClassTemplate();

		if (UnitState.bMissionProvided) // skip mission added units like VIPs
			continue;

		LadderSoldierInfoButtons[m_HeadshotsRecieved].Show();

		MC.BeginFunctionOp("SetSoldierData");
		MC.QueueNumber(m_HeadshotsRecieved++);

		SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(CurrentCampaign.GameIndex, UnitStateRef.ObjectID, 128, 128);
		if (SoldierPicture != none)
		{
			MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture))); // Picture Image
		}
		else
		{
			if (LadderData.LadderIndex < 10)
			{
				MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath("UILibrary_TLE_Common.TLE_Ladder_"$LadderData.LadderIndex$"_"$LadderData.FixedNarrativeUnits[LadderData.LadderIndex-1].LastNames[m_HeadshotsRecieved-1]));
			}
			else
			{
				MC.QueueString(""); // Picture Image
			}
		}

		MC.QueueString(SoldierClass.IconImage); //Class Icon Image
		MC.QueueString(class'UIUtilities_Image'.static.GetRankIcon(UnitState.GetRank(), UnitState.GetSoldierClassTemplateName())); //Rank image
		if (LadderData.LadderIndex < 10)
		{
			MC.QueueString(class'XComGameState_LadderProgress'.static.GetUnitName(m_HeadshotsRecieved - 1, LadderData.LadderIndex)); //Unit Name
		}
		else
		{
			MC.QueueString(UnitState.GetFullName());
		}
		MC.QueueString(SoldierClass.DisplayName); //Class Name
		MC.EndOp();

	}

	while (m_HeadshotsRecieved < 6)
	{
		LadderSoldierInfoButtons[m_HeadshotsRecieved].Hide();

		MC.BeginFunctionOp("HideSoldierData");
		MC.QueueNumber(m_HeadshotsRecieved++);
		MC.EndOp();
	}

	//force the medals to empty for now until we have code to support this
	//otherwise we need to check for narrative ladder 
	//select the correct medal to show 
	//check if it is unlocked or not
	goldMedalProgress = LadderData.GetLadderMedalThreshold(LadderData.LadderIndex, 2);
	for (i = 0; i < 3; i++)
	{
		currentMedalProgress = LadderData.GetLadderMedalThreshold(LadderData.LadderIndex, i);
		medalPercentage = float(currentMedalProgress) / float(goldMedalProgress);
		mc.BeginFunctionOp("SetMedalScoreMarker");
		mc.QueueNumber(i);
		mc.QueueNumber(medalPercentage);
		mc.QueueString(string(currentMedalProgress));
		mc.QueueString(m_MedalTypes[i]);
		mc.EndOp();

		mc.BeginFunctionOp("SetLadderMedal");
		mc.QueueNumber(i);
		mc.QueueNumber(LadderData.LadderIndex);
		if (currentMedalProgress > ladderHighScore)
		{
			mc.QueueNumber(0);
		}
		else
		{
			mc.QueueNumber(i + 1);
		}
		mc.EndOp();
	}

	if (ladderHighScore <= 0)
	{
		ladderHighScore = LadderData.CumulativeScore;
	}
	medalPercentage = float(ladderHighScore) / float(goldMedalProgress);

	mc.FunctionNum("SetMedalProgressMeter", medalPercentage);

	mc.BeginFunctionOp("SetCurrentLadderScore");
	mc.QueueNumber(ladderHighScore);
	mc.QueueString(m_ScoreLabel);
	mc.EndOp();

	mc.BeginFunctionOp("SetMissionDifficulty");
	mc.QueueString(m_DifficultyLabel);
	if(LadderData.LadderIndex < 10)
		mc.QueueString(m_arrDifficultyTypeStrings[CurrentCampaign.DifficultySetting]);
	else
		mc.QueueString(class'UIShellDifficulty'.default.m_arrDifficultyTypeStrings[CurrentCampaign.DifficultySetting]);
	mc.EndOp();

	mc.FunctionString("SetNarrativeLadderText", m_arrNarrativeStrings[LadderIndex]);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP :
		if( args[args.length-2] == "ContinueButton" )
		{
			OnLadderClicked(ClickedList, clickedIndex);
		}
		else if( args[args.length - 1] == "AbandonButton" )
		{
			AbandonLadderPopup();
		}
		else if (args[args.length - 1] == "DeleteButton")
		{
			DeleteLadderPopup();
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN :
		`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
		break;
	}
}

simulated function int GetCurrentLadderIndex()
{
	if(ClickedList == List)
		return int(m_LadderList[clickedIndex + NarrativeList.GetItemCount() - 1]);

	return  int(m_LadderList[clickedIndex]);
}

simulated function OnReceiveFocus()
{
	UpdateNavHelp();
	super.OnReceiveFocus();
}

simulated function CloseScreen()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local XComGameStateHistory History;

	History = class'XComGameStateHistory'.static.GetGameStateHistory();

	OnlineEventMgr = `ONLINEEVENTMGR;
	if( OnlineEventMgr != none )
	{
		OnlineEventMgr.ClearUpdateSaveListCompleteDelegate(OnReadSaveGameListComplete);
	}

	History.ResetToDefaults();

	super.CloseScreen();
}

simulated public function OnCancel()
{
	NavHelp.ClearButtonHelp();
	CloseScreen();

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function CreateNewLadder( int LadderDifficulty, bool NarrativesOn )
{
	local XComOnlineProfileSettings Profile;
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState TacticalStartState;
	local XComGameState_LadderProgress LadderData;
	local string MissionType;
	local XComGameState_CampaignSettings CampaignSettings;
	local array<name> SquadMembers;
	local XComGameState_HeadquartersXCom HeadquartersStateObject;
	local XComGameState_BattleData BattleDataState;
	local XComTacticalMissionManager  TacticalMissionManager;
	local MissionDefinition MissionDef;
	local XComParcelManager ParcelManager;
	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local X2MissionTemplate MissionTemplate;
	local X2MissionTemplateManager MissionTemplateManager;
	local XComGameState_Player AddPlayerState;
	local WorldInfo LocalWorldInfo;
	local int Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond;
	local string TimeStamp;
	local PlotTypeDefinition PlotType;
	local XComGameState_MissionSite MissionSite;

	`ONLINEEVENTMGR.ClearUpdateSaveListCompleteDelegate( OnReadSaveGameListComplete );

	LocalWorldInfo = class'Engine'.static.GetCurrentWorldInfo();

	LocalWorldInfo.GetSystemTime( Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond );
	class'XComOnlineEventMgr'.static.FormatTimeStampSingleLine12HourClock( TimeStamp, Year, Month, Day, Hour, Minute );

	Profile = `XPROFILESETTINGS;
	TacticalMissionManager = `TACTICALMISSIONMGR;
	ParcelManager = `PARCELMGR;
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();

	History = `XCOMHISTORY;
	History.ResetHistory(, false);

	// Grab the start state from the profile
	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	TacticalStartState = History.CreateNewGameState(false, TacticalStartContext);

	class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart( 
		TacticalStartState, 
		, 
		,
		,
		,
		`CampaignDifficultySetting,
		`TacticalDifficultySetting,
		`StrategyDifficultySetting,
		`GameLengthSetting);

	History.AddGameStateToHistory(TacticalStartState);

	//Add basic states to the start state ( battle, players, abilities, etc. )
	BattleDataState = XComGameState_BattleData(TacticalStartState.CreateNewStateObject(class'XComGameState_BattleData'));	
	BattleDataState.iLevelSeed = class'Engine'.static.GetEngine().GetSyncSeed();

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_XCom);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_Alien);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_Neutral);
	BattleDataState.CivilianPlayerRef = AddPlayerState.GetReference();

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_TheLost);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_Resistance);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());

	TacticalStartState.CreateNewStateObject(class'XComGameState_Cheats');

	++Profile.Data.m_Ladders;
	`ONLINEEVENTMGR.SaveProfileSettings();

	LadderData = XComGameState_LadderProgress( TacticalStartState.CreateNewStateObject( class'XComGameState_LadderProgress' ) );

	LadderData.bNewLadder = true;
	LadderData.bRandomLadder = true;
	LadderData.LadderSize = class'XComGameState_LadderProgress'.default.DefaultSize;
	LadderData.LadderRung = 1;
	LadderData.LadderIndex = Profile.Data.m_Ladders;
	LadderData.SquadProgressionName = class'XComGameState_LadderProgress'.default.SquadProgressions[ `SYNC_RAND_STATIC( class'XComGameState_LadderProgress'.default.SquadProgressions.Length ) ].SquadName;
	class'UITacticalQuickLaunch'.static.ResetLastUsedSquad( );
	LadderData.LadderName = class'XGMission'.static.GenerateOpName( false ) @ "-" @ TimeStamp;

	SquadMembers = class'XComGameState_LadderProgress'.static.GetSquadProgressionMembers( LadderData.SquadProgressionName, 1 );
	class'UITacticalQuickLaunch_MapData'.static.ApplySquad( SquadMembers );

	LadderData.PopulateUpgradeProgression( );

	MissionType = class'XComGameState_LadderProgress'.default.AllowedMissionTypes[ `SYNC_RAND_STATIC( class'XComGameState_LadderProgress'.default.AllowedMissionTypes.Length ) ];
	BattleDataState.m_iMissionType = TacticalMissionManager.arrMissions.Find( 'sType', MissionType );

	if(!TacticalMissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
	{
		`Redscreen("CreateNewLadder(): Mission Type " $ MissionType $ " has no definition!");
		return;
	}

	TacticalMissionManager.ForceMission = MissionDef;

	// pick our new map
	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef);
	if(ValidPlots.Length == 0)
	{
		`Redscreen("TransferToNewMission(): Could not find a plot to transfer to for mission type " $ MissionType $ "!");
		return;
	}

	Month = `SYNC_RAND(ValidPlots.Length);
	NewPlot = ValidPlots[ Month ];
	PlotType = ParcelManager.GetPlotTypeDefinition( NewPlot.strType );

	BattleDataState.MapData.PlotMapName = NewPlot.MapName;
	BattleDataState.MapData.ActiveMission = MissionDef;

	if (NewPlot.ValidBiomes.Length > 0)
		BattleDataState.MapData.Biome = NewPlot.ValidBiomes[ `SYNC_RAND(NewPlot.ValidBiomes.Length) ];

	BattleDataState.LostSpawningLevel = BattleDataState.SelectLostActivationCount();
	BattleDataState.m_strMapCommand = "open" @ BattleDataState.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";
	BattleDataState.SetForceLevel( class'XComGameState_LadderProgress'.default.RungConfiguration[ 0 ].ForceLevel );
	BattleDataState.SetAlertLevel( class'XComGameState_LadderProgress'.default.RungConfiguration[ 0 ].AlertLevel );
	BattleDataState.m_nQuestItem = class'XComGameState_LadderProgress'.static.SelectQuestItem( MissionType );
	BattleDataState.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );

	class'XComGameState_LadderProgress'.static.AppendNames( BattleDataState.ActiveSitReps, MissionDef.ForcedSitreps );
	class'XComGameState_LadderProgress'.static.AppendNames( BattleDataState.ActiveSitReps, PlotType.ForcedSitReps );

	MissionSite = class'XComGameState_LadderProgress'.static.SetupMissionSite( TacticalStartState, BattleDataState );

	MissionTemplate = MissionTemplateManager.FindMissionTemplate(MissionDef.MissionName);
	if( MissionTemplate != none )
	{
		BattleDataState.m_strDesc = MissionTemplate.Briefing;
	}
	else
	{
		BattleDataState.m_strDesc = "NO LOCALIZED BRIEFING TEXT!";
	}

	LadderData.PlayedMissionFamilies.AddItem( TacticalMissionManager.arrMissions[ BattleDataState.m_iMissionType ].MissionFamily );

	CampaignSettings = XComGameState_CampaignSettings( History.GetSingleGameStateObjectForClass( class'XComGameState_CampaignSettings' ) );
	CampaignSettings.SetSuppressFirstTimeNarrativeEnabled( true );
	CampaignSettings.SetTutorialEnabled( false );
	CampaignSettings.SetIronmanEnabled( true );
	CampaignSettings.SetStartTime( class'XComCheatManager'.static.GetCampaignStartTime() );
	CampaignSettings.SetDifficulty( LadderDifficulty );

	HeadquartersStateObject = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
	HeadquartersStateObject.bHasPlayedAmbushTutorial = true;
	HeadquartersStateObject.bHasPlayedMeleeTutorial = true;
	HeadquartersStateObject.bHasPlayedNeutralizeTargetTutorial = true;
	HeadquartersStateObject.SetGenericKeyValue( "NeutralizeTargetTutorial", 1 );

	MissionSite.UpdateSitrepTags( );
	HeadquartersStateObject.AddMissionTacticalTags( MissionSite );

	ConsoleCommand( BattleDataState.m_strMapCommand );

	`FXSLIVE.BizAnalyticsLadderStart( CampaignSettings.BizAnalyticsCampaignID, LadderData.LadderIndex, true, LadderDifficulty, LadderData.SquadProgressionName );
}

simulated function RefreshButtonHelpLabels(int LadderIndex)
{
	if (HasLadderSave(LadderIndex)) // We are continuing a ladder
	{
		if( `ISCONTROLLERACTIVE )
		{
			mc.FunctionString("SetContinueButton", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetAdvanceButtonIcon(), 26, 26, -10) @ m_strContinueLadder);
			mc.FunctionString("SetAbandonButton", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -10) @ m_strAbandonLadder);
		}
		else
		{
			mc.FunctionString("SetContinueButton", m_strContinueLadder);
			mc.FunctionString("SetAbandonButton", m_strAbandonLadder);
		}
	}
	else // Starting a fresh ladder 
	{
		mc.FunctionString("SetAbandonButton", "");

		if( `ISCONTROLLERACTIVE )
		{
			mc.FunctionString("SetContinueButton", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetAdvanceButtonIcon(), 26, 26, -10) @ m_strBeginLadder);
		}
		else
		{
			mc.FunctionString("SetContinueButton", m_strBeginLadder);
		}
	}
	
	if (LadderIndex >= 10)
	{
		if (`ISCONTROLLERACTIVE)
		{
			mc.FunctionString("SetDeleteButton", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_RSCLICK_R3, 26, 26, -10) @ m_strDeleteLadder);
		}
		else
		{
			mc.FunctionString("SetDeleteButton", m_strDeleteLadder);
		}
	}
	else
	{
		mc.FunctionString("SetDeleteButton", "");
	}
}

function AbandonLadderPopup()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.strTitle = m_DestructiveActionTitle;
	kConfirmData.strText = m_DestructiveActionBody;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnAbandonLadderPopupPopupExitDialog;

	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnAbandonLadderPopupPopupExitDialog(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);

		OnLadderAbandoned(ClickedList, clickedIndex);
	}
}

function DeleteLadderPopup()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.strTitle = m_DeleteDestructiveActionTitle;
	kConfirmData.strText = m_DeleteDestructiveActionBody;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnDeleteLadderPopupPopupExitDialog;

	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDeleteLadderPopupPopupExitDialog(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);

		OnLadderAbandoned(ClickedList, clickedIndex);
		DeleteLadderFiles(GetCurrentLadderIndex());

		`ONLINEEVENTMGR.UpdateSaveGameList();
	}
}

defaultproperties
{
	m_HeadshotsRecieved = 0
	Package = "/ package/gfxTLE_LadderMenu/TLE_LadderMenu";
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;
}
