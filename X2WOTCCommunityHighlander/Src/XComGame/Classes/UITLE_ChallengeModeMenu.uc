//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITLE_LadderModeMenu.uc
//  AUTHOR:  Joe Cortese
//----------------------------------------------------------------------------
//  Copyright (c) 2018 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITLE_ChallengeModeMenu extends UITLEScreen
	implements(IUISortableScreen)
	Native(UI);

var UINavigationHelp NavHelp;
var UIList List;

var int m_HeadshotsRecieved;
var array<string> m_ChallengeList;

var array<OnlineSaveGame> m_arrSaveGames;

var localized string m_ScreenTitle;
var localized string m_PreviousLadder;
var localized string m_ProgressTitle;
var localized string m_ProgressText;

var localized string m_Header_OpName;
var localized string m_Header_Objective;
var localized string m_Header_Map;
var localized string m_Header_Squad;
var localized string m_Header_Enemies;

var localized array<string> m_OpNames;

var int m_iItemsLoaded;

struct native ChallengeSaveData
{
	var string Filename;
	var int SaveID;

	var int LadderIndex;
	var int MissionIndex;
};

var array<ChallengeSaveData> m_LadderSaveData;

enum EChallengeModeMenuSortType
{
	eChallengeModeMenuSortType_MissionName,
	eChallengeModeMenuSortType_Objective,
	eChallengeModeMenuSortType_Map,
	eChallengeModeMenuSortType_Squad,
	eChallengeModeMenuSortType_Enemies
};
var localized string m_strButtonLabels[EChallengeModeMenuSortType.EnumCount]<BoundEnum = EChallengeModeMenuSortType>;

// these are set in UIFlipSortButton
var bool m_bFlipSort;

var EChallengeModeMenuSortType m_eSortType;

struct native ChallengeListItemData
{
	var int ChallengeListDataIndex;

	var string MissionName;
	var string MissionObjective;
	var string MapName;
	var string MapImagePath;
	var string Squad;
	var string Enemies;
	var string LeaderboardSuffix;
	var string StartString;
};

var array<ChallengeListItemData> m_LadderListItemData;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	GetChallengeListSize();
	SortChallengeList();
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

simulated native function int GetChallengeListSize();

simulated function SortChallengeList()
{
	local string LadderFilename;
	local array<int> LadderIndicies;
	local int LadderIndex;
	local int i, j;

	// convert all the file names to ladder indicies
	foreach m_ChallengeList(LadderFilename)
	{
		LadderFilename = Left(LadderFilename, InStr(LadderFilename, ".x2hist"));
		LadderFilename = Mid(LadderFilename, 7);
		LadderIndicies.AddItem(int(LadderFilename));
	}

	// order the ladder names in ascending order by ladder index
	// do a super simple bubble sort, the ladder list isn't usually going to be too big
	// and string manipulation in C++ (required for better sort algorithms
	for (i = 0; i < m_ChallengeList.Length - 1; ++i)
	{
		for (j = i + 1; j < m_ChallengeList.Length; ++j)
		{
			if (LadderIndicies[j] < LadderIndicies[i])
			{
				LadderIndex = LadderIndicies[j];
				LadderFilename = m_ChallengeList[j];

				LadderIndicies[j] = LadderIndicies[i];
				m_ChallengeList[j] = m_ChallengeList[i];

				LadderIndicies[i] = LadderIndex;
				m_ChallengeList[i] = LadderFilename;
			}
		}
	}
}

function CreateListItemData(int ChallengeIndex)
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;
	local array<PlotDefinition> ValidPlots;
	local XComParcelManager ParcelManager;
	local int MapIndex;
	local ChallengeListItemData ItemData; 
	local XComGameState_ChallengeData ChallengeData;
	local string ChallengeStartString;

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	History = class'XComGameStateHistory'.static.GetGameStateHistory();

	ItemData.ChallengeListDataIndex = ChallengeIndex;
	ChallengeStartString = Left(m_ChallengeList[ChallengeIndex], 23);

	History.ReadHistoryFromFile("Challenges/", ChallengeStartString);

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	ChallengeData = XComGameState_ChallengeData(History.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData'));
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(BattleData.MapData.ActiveMission.MissionName);

	ParcelManager = `PARCELMGR;
	ParcelManager.GetValidPlotsForMission(ValidPlots, BattleData.MapData.ActiveMission);

	for( MapIndex = 0; MapIndex < ValidPlots.Length; MapIndex++ )
	{
		if( ValidPlots[MapIndex].MapName == BattleData.MapData.PlotMapName )
		{
			ItemData.MapName = class'UITLE_SkirmishModeMenu'.static.GetLocalizedMapTypeName(ValidPlots[MapIndex].strType);
			ItemData.MapImagePath = `MAPS.SelectMapImage(ValidPlots[MapIndex].strType);
			continue;
		}
	}
	
	ItemData.MissionObjective = MissionTemplate.DisplayName;
	ItemData.MissionName = m_OpNames[ChallengeIndex];//BattleData.m_strOpName;
	ItemData.Squad = GetSquadInfo(ChallengeData);
	ItemData.Enemies = GetEnemyInfo(ChallengeData);

	m_LadderListItemData.AddItem(ItemData); 
}

private simulated function GetNumSoldiersAndAliens(out int NumSoldiers, out int NumAliens)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = class'XComGameStateHistory'.static.GetGameStateHistory();

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom && !UnitState.GetMyTemplate().bIsCosmetic )
		{
			if( UnitState.IsSoldier() )
			{
				NumSoldiers++;
			}
			else
			{
				NumAliens++;
			}
		}
	}
}

simulated function string GetSquadInfo(XComGameState_ChallengeData ChallengeData)
{
	local X2ChallengeTemplateManager TemplateManager;
	local X2ChallengeSoldierClass SoldierTemplate;
	local X2ChallengeSquadAlien AlienTemplate;
	local int NumSoldiers, NumAliens;
	local string LocData;
	local bool bUseSquadConnector;

	TemplateManager = class'X2ChallengeTemplateManager'.static.GetChallengeTemplateManager();
	SoldierTemplate = X2ChallengeSoldierClass(TemplateManager.FindChallengeTemplate(ChallengeData.ClassSelectorName));
	AlienTemplate = X2ChallengeSquadAlien(TemplateManager.FindChallengeTemplate(ChallengeData.AlienSelectorName));
	NumSoldiers = 0;
	NumAliens = 0;
	bUseSquadConnector = false;

	GetNumSoldiersAndAliens(NumSoldiers, NumAliens);

	if( NumSoldiers > 0 )
	{
		if( SoldierTemplate != none )
		{
			bUseSquadConnector = (NumAliens > 0);
			LocData $= (SoldierTemplate.DisplayName != "") ? SoldierTemplate.DisplayName : "IMPLEMENT_SOLDIER'" $ SoldierTemplate.DataName $ "'";
		}
		else if( ChallengeData.ClassSelectorName != '' )
		{
			bUseSquadConnector = (NumAliens > 0);
			LocData $= "TODO[" $ ChallengeData.ClassSelectorName $ "]";
		}
	}

	if( NumAliens > 0 )
	{
		if( AlienTemplate != none )
		{
			if( bUseSquadConnector )
			{
				LocData @= class'UIChallengeMode_SquadSelect'.default.m_strSquadConnector $ " ";
			}

			LocData $= (AlienTemplate.DisplayName != "") ? AlienTemplate.DisplayName : "IMPLEMENT_ALIEN'" $ AlienTemplate.DataName $ "'";
		}
		else if( ChallengeData.AlienSelectorName != '' )
		{
			if( bUseSquadConnector )
			{
				LocData @= class'UIChallengeMode_SquadSelect'.default.m_strSquadConnector $ " ";
			}

			LocData $= "TODO[" $ ChallengeData.AlienSelectorName $ "]";
		}
	}

	`log(`location @ `ShowVar(ChallengeData.SquadSizeSelectorName) @ `ShowVar(ChallengeData.ClassSelectorName) @ `ShowVar(ChallengeData.AlienSelectorName) @ `ShowVar(SoldierTemplate.DisplayName) @ `ShowVar(AlienTemplate.DisplayName) @ `ShowVar(LocData));
	return LocData;
}

simulated function string GetEnemyInfo(XComGameState_ChallengeData ChallengeData)
{
	local X2ChallengeTemplateManager TemplateManager;
	local X2ChallengeEnemyForces EnemyTemplate;

	TemplateManager = class'X2ChallengeTemplateManager'.static.GetChallengeTemplateManager();
	EnemyTemplate = X2ChallengeEnemyForces(TemplateManager.FindChallengeTemplate(ChallengeData.EnemyForcesSelectorName));
	`log(`location @ `ShowVar(ChallengeData.EnemyForcesSelectorName) @ `ShowVar(EnemyTemplate.DataName) @ `ShowVar(EnemyTemplate.DisplayName));

	return EnemyTemplate.DisplayName;
}

simulated function UpdateNavHelp()
{
	//Issue #295 - Add a 'none' check before accessing NavHelp and attempt to Get it if it's 'none'.
	if (NavHelp == none)
	{
		NavHelp = GetNavHelp();
	}
	if (NavHelp != none)
	{
		NavHelp.ClearButtonHelp();
		NavHelp.AddBackButton(OnCancel);

		if( `ISCONTROLLERACTIVE )
		{
			NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericConfirm, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
		}

		NavHelp.Show();
	}
}

simulated function OnChallengeClicked(UIList ContainerList, int ListItemIndex)
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleDataState;
	local XComChallengeModeManager ChallengeModeManager;
	local XComGameState_ChallengeData ChallengeData;
	local string historyFilename;
	local int ItemIndex; 

	ItemIndex = UITLEChallenge_ListItem(ContainerList.GetItem(ListItemIndex)).Data.ChallengeListDataIndex; 

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	historyFilename = Left(m_ChallengeList[ItemIndex], InStr(m_ChallengeList[ItemIndex], ".x2hist"));
	History = class'XComGameStateHistory'.static.GetGameStateHistory();
	History.ReadHistoryFromFile("Challenges/", historyFilename);

	ChallengeModeManager = XComEngine(Class'GameEngine'.static.GetEngine()).ChallengeModeManager;
	ChallengeModeManager.BootstrapDebugChallenge();

	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`ONLINEEVENTMGR.bIsChallengeModeGame = true;
	`ONLINEEVENTMGR.bIsLocalChallengeModeGame = true;

	ChallengeData = XComGameState_ChallengeData(History.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData'));
	ChallengeData.OfflineID = ItemIndex;

	ConsoleCommand(BattleDataState.m_strMapCommand);
}

simulated function OnSelectedChange(UIList ContainerList, int ItemIndex)
{
	local XComOnlineProfileSettings Profile;
	local ChallengeListItemData Data;

	Profile = `XPROFILESETTINGS;

	Data = UITLEChallenge_ListItem(ContainerList.GetItem(ItemIndex)).Data;

	mc.BeginFunctionOp("SetChallengeDetails");
	mc.QueueString("img:///" $ Data.MapImagePath);
	mc.QueueString(Data.MissionName);
	mc.QueueString(m_Header_Squad);
	mc.QueueString(Data.Squad);
	mc.QueueString(m_Header_Enemies);
	mc.QueueString(Data.Enemies);
	mc.QueueString(m_Header_Objective);
	mc.QueueString(Data.MissionObjective);

	mc.QueueString(class'UITLEHub'.default.m_VictoryLabel);
	mc.QueueString(string(Profile.Data.HubStats.NumOfflineChallengeVictories));
	mc.QueueString("");

	mc.QueueString(class'UITLEHub'.default.m_HighestScore);
	mc.QueueString(string(Profile.Data.HubStats.OfflineChallengeHighScore));

	mc.QueueString(class'UITLEHub'.default.m_CompletedLabel);
	mc.QueueString(string(Profile.Data.HubStats.OfflineChallengeCompletion.length));

	mc.QueueString("");
	mc.QueueString("");

	mc.EndOp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
	RefreshData();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function RefreshData()
{
	SortData();
	UpdateList();
}

simulated function UpdateList()
{
	local int SelIdx, ItemIndex;
	
	SelIdx = List.SelectedIndex;
	
	for( ItemIndex = 0; ItemIndex < m_LadderListItemData.length; ItemIndex++ )
	{
		UITLEChallenge_ListItem(List.GetItem(ItemIndex)).Refresh(m_LadderListItemData[ItemIndex]);
	}

	// Always select first option if using controller (and last selection is invalid)
	// bsg-dforrest (5.16.17): also reset the index if above the list size, this can happen with delete
	if( (SelIdx < 0 || SelIdx >= List.itemCount) && List.itemCount > 0 && `ISCONTROLLERACTIVE)
	   // bsg-dforrest (5.16.17): end
	{
		SelIdx = 0;
	}

	List.SetSelectedIndex(SelIdx);
	List.Navigator.SetSelected(List.GetItem(SelIdx));

	Navigator.SetSelected(List);
}
simulated function int SortAlphabetically(string A, string B)
{
	if( A < B )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( A > B )
	{
		return m_bFlipSort ? 1 : -1;
	}
	else // Names match
	{
		return 0;
	}
}

simulated function int SortByMissionName(ChallengeListItemData A, ChallengeListItemData B)
{
	return SortAlphabetically(A.MissionName, B.MissionName);
}
simulated function int SortByObjective(ChallengeListItemData A, ChallengeListItemData B)
{
	return SortAlphabetically(A.MissionObjective, B.MissionObjective);
}
simulated function int SortByMap(ChallengeListItemData A, ChallengeListItemData B)
{
	return SortAlphabetically(A.MapName, B.MapName);
}
simulated function int SortBySquad(ChallengeListItemData A, ChallengeListItemData B)
{
	return SortAlphabetically(A.Squad, B.Squad);
}
simulated function int SortByEnemies(ChallengeListItemData A, ChallengeListItemData B)
{
	return SortAlphabetically(A.Enemies, B.Enemies);
}

function SortData()
{
	switch( m_eSortType )
	{
	case eChallengeModeMenuSortType_MissionName: m_LadderListItemData.Sort(SortByMissionName);	break;
	case eChallengeModeMenuSortType_Objective:	 m_LadderListItemData.Sort(SortByObjective);	break;
	case eChallengeModeMenuSortType_Map:		 m_LadderListItemData.Sort(SortByMap);			break;
	case eChallengeModeMenuSortType_Squad:		 m_LadderListItemData.Sort(SortBySquad);		break;
	case eChallengeModeMenuSortType_Enemies:	 m_LadderListItemData.Sort(SortByEnemies);		break;
	}
	
	UpdateList();
}

function bool GetFlipSort()
{
	return m_bFlipSort;
}

function int GetSortType()
{
	return m_eSortType;
}

function SetFlipSort(bool bFlip)
{
	m_bFlipSort = bFlip; 
}

function SetSortType(int eSortType)
{
	m_eSortType = EChallengeModeMenuSortType(eSortType); 
	SortData();
}

simulated function BuildHeaders()
{
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header0",
															eChallengeModeMenuSortType_MissionName,
															m_strButtonLabels[eChallengeModeMenuSortType_MissionName]);
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header1",
															eChallengeModeMenuSortType_Objective,
															m_strButtonLabels[eChallengeModeMenuSortType_Objective]);
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header2",
															eChallengeModeMenuSortType_Map,
															m_strButtonLabels[eChallengeModeMenuSortType_Map]);
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header3",
															eChallengeModeMenuSortType_Squad,
															m_strButtonLabels[eChallengeModeMenuSortType_Squad]);
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header4",
															eChallengeModeMenuSortType_Enemies,
															m_strButtonLabels[eChallengeModeMenuSortType_Enemies]);
	
}


simulated function OnInit()
{
	super.OnInit();

	BuildHeaders();

	List = Spawn(class'UIList', self);
	List.bAnimateOnInit = false;
	List.InitList('BrowserList', 246, 487, 1410, 520, , true);
	List.bStickyHighlight = true;
	List.OnItemClicked = OnChallengeClicked;
	List.OnSelectionChanged = OnSelectedChange;

	mc.FunctionString("SetScreenTitle", m_ScreenTitle);

	ShowProgressDialogue();
	GotoState('LoadingItems');
}

function ShowProgressDialogue()
{
	local TProgressDialogData kDialogBoxData;

	// If we're going to spawn a dialog box that says we're fetching data, that means we don't want navhelp to display anything, since we aren't able to do anything(kmartinez)
	kDialogBoxData.strTitle = m_ProgressTitle;
	kDialogBoxData.strDescription = m_ProgressText;

	Movie.Pres.UIProgressDialog(kDialogBoxData);
}

state LoadingItems
{
	function bool LoadNextListItem()
	{
		if( m_iItemsLoaded < m_ChallengeList.Length )
		{
			CreateListItemData(m_iItemsLoaded);
			m_iItemsLoaded++;
			return true; 
		}
		else
		{
			LoadFinished();
			return false; 
		}
	}

Begin:
	while( LoadNextListItem() )
		Sleep(0.0001);
}

function LoadFinished()
{
	Movie.Pres.UICloseProgressDialog();

	BuildListItems();

	RefreshData();

	Navigator.SetSelected(List);
	List.Navigator.SelectFirstAvailable();

	NavHelp = GetNavHelp();
	UpdateNavHelp();
}

private function BuildListItems()
{
	local int i; 

	for( i= 0; i < m_LadderListItemData.length; i++ )
	{
		Spawn(class'UITLEChallenge_ListItem', List.itemContainer).InitPanel();
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP :
		
		
		break;
	}
}

simulated public function OnCancel()
{
	NavHelp.ClearButtonHelp();
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	Movie.Stack.Pop(self);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repreats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if( !bIsInited )
		return true;

	bHandled = false;

	switch( cmd )
	{
	case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
	case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		OnCancel();
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		OnChallengeClicked(List, List.SelectedIndex);
		return true; 

	case class'UIUtilities_Input'.const.FXS_DPAD_UP :
	//case class'UIUtilities_Input'.const.FXS_ARROW_UP :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP :
	case class'UIUtilities_Input'.const.FXS_KEY_W :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_UP, arg);
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN :
	//case class'UIUtilities_Input'.const.FXS_ARROW_DOWN :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN :
	case class'UIUtilities_Input'.const.FXS_KEY_S :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_DOWN, arg);
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

defaultproperties
{
	LibID = "TLEChallengeScreen";
	m_HeadshotsRecieved = 0
	Package = "/ package/gfxTLE_ChallengeMenu/TLE_ChallengeMenu";
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;
}
