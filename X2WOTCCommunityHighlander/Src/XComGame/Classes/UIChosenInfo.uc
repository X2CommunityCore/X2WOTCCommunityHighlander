
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChosenInfo.uc
//  AUTHOR:  Brit Steiner -- 1/25/2017
//  PURPOSE: This file controls the Chosen Info screen 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChosenInfo extends UIScreen;

var localized string ChosenInfo_ListTitle;
var localized string ChosenInfo_ListSubtitle;
var localized string ChosenInfo_JobLabel;
var localized string ChosenInfo_EncountersLabel;
var localized string ChosenInfo_KillsLabel;
var localized string ChosenInfo_CapturesLabel;
var localized string ChosenInfo_HuntXComLabel;
var localized string ChosenInfo_XComAwarenessLabel;
var localized string ChosenInfo_ChosenAwarenessLabel;
var localized string ChosenInfo_StrengthsLabel;
var localized string ChosenInfo_WeaknessesLabel;
var localized string ChosenInfo_FactionLabel;
var localized string ChosenInfo_UnknownChosenTraitName;
var localized string ChosenInfo_UnknownChosenTraitDescription;
var localized string ChosenInfo_MonthActionPrefix;
var localized string ChosenInfo_DefeatedLabel;

var string UnknownChosenTraitIcon;

var int CurrentChosenIndex; //bsg-crobinson (5.10.17): Remember what chosen we're looking at

var array<XComGameState_AdventChosen> AllActiveChosen;
var XComGameState_AdventChosen SelectedChosen;

//----------------------------------------------------------------------------
// MEMBERS

simulated function OnInit()
{
	super.OnInit();

	`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ChosenPopupOpen");

	`HQPRES.StrategyMap2D.Hide();

	InitData();

	RefreshHeaders();
	
	RefreshDisplay();

	`HQPRES.m_kAvengerHUD.NavHelp.AddContinueButton(OnContinue);
	MC.FunctionVoid("AnimateIn");
}


simulated function InitData()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AdventChosen ChosenState;

	History = `XCOMHISTORY;
	AllActiveChosen.Length = 0;

	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if ( ChosenState.bMetXCom )
		{
			AllActiveChosen.AddItem(ChosenState);
		}
	}

	// Screen can only appear when there is at least 1 chosen active
	SelectedChosen = AllActiveChosen[0];
	CurrentChosenIndex = 0; //bsg-crobinson (5.10.17): Set to first chosen

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: View Chosen Info");
	`XEVENTMGR.TriggerEvent('OnViewChosenInfo', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}


simulated function RefreshDisplay()
{
	local int i; 
	local array<X2AbilityTemplate> ChosenStrengths, ChosenWeaknesses;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_ResistanceFaction FactionState;
	local int FragmentLevel;
	local string ActionString;
	
	if( SelectedChosen == None ) return; 
	
	FactionState = SelectedChosen.GetRivalFaction();

	if(SelectedChosen.IsStrongholdMissionAvailable())
	{
		FragmentLevel = 3;
	}
	else
	{
		FragmentLevel = int(FactionState.GetInfluence());
	}

	ActionString = SelectedChosen.GetCurrentMonthActionName();

	if(ActionString != "")
	{
		ActionString = ChosenInfo_MonthActionPrefix @ ActionString;
	}
	
	// MAIN INFO PANEL -----------------------------------------------------------------

	AS_SetInfoPanel(SelectedChosen.GetChosenPortraitImage(),
		SelectedChosen.GetChosenClassName(),
		SelectedChosen.GetChosenName(),
		SelectedChosen.GetChosenNickname(),
		SelectedChosen.GetNumEncounters(),
		SelectedChosen.GetNumExtracts(),
		SelectedChosen.GetNumSoldiersCaptured(),
		SelectedChosen.GetKnowledgePercent(true), 
		ActionString, 
		FragmentLevel, 
		"");

	AS_SetInfoPanelIcon(SelectedChosen.GetChosenIcon());

	if(SelectedChosen.bDefeated)
	{
		MC.BeginFunctionOp("ShowChosenDefeat");
		MC.QueueString(ChosenInfo_DefeatedLabel);
		MC.EndOp();
	}
	else
	{
		MC.FunctionVoid("HideChosenDefeat");
	}
	
	// STENGTHS & WEAKNESSES ----------------------------------------------------------

	ChosenStrengths = SelectedChosen.GetChosenStrengths();
	for (i = 0; i < ChosenStrengths.length; i++) //MAX 6
	{
		if (ChosenStrengths[i].AbilityRevealEvent == '' || SelectedChosen.RevealedChosenTraits.Find(ChosenStrengths[i].DataName) != INDEX_NONE)
		{
			AbilityTemplate = ChosenStrengths[i];
			AS_SetStrengthData(i, AbilityTemplate.IconImage, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription);
		}
		else
		{
			AS_SetStrengthData(i, UnknownChosenTraitIcon, class'UIUtilities_Text'.static.GetColoredText(ChosenInfo_UnknownChosenTraitName, eUIState_Disabled), class'UIUtilities_Text'.static.GetColoredText(ChosenInfo_UnknownChosenTraitDescription, eUIState_Disabled));
		}
	}
	for( i = ChosenStrengths.length; i < 6;  i++ ) //MAX 6
	{
		AS_SetStrengthData(i, "", "", "");
	}

	ChosenWeaknesses = SelectedChosen.GetChosenWeaknesses();
	for (i = 0; i < ChosenWeaknesses.length; i++) //MAX 4
	{
		if (ChosenWeaknesses[i].AbilityRevealEvent == '' || SelectedChosen.RevealedChosenTraits.Find(ChosenWeaknesses[i].DataName) != INDEX_NONE)
		{
			AbilityTemplate = ChosenWeaknesses[i];
			AS_SetWeaknessData(i, AbilityTemplate.IconImage, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription);
		}
		else
		{
			AS_SetWeaknessData(i, UnknownChosenTraitIcon, class'UIUtilities_Text'.static.GetColoredText(ChosenInfo_UnknownChosenTraitName, eUIState_Disabled), class'UIUtilities_Text'.static.GetColoredText(ChosenInfo_UnknownChosenTraitDescription, eUIState_Disabled));
		}
	}
	for( i = ChosenWeaknesses.length; i < 4; i++ ) //MAX 4
	{
		AS_SetWeaknessData(i, "", "", "");
	}


	// RIVAL FACTION --------------------------------------------------------------------

	AS_SetWeaknessFaction(FactionState.GetFactionTitle(), FactionState.GetFactionName());
	AS_SetWeaknessFactionIcon(FactionState.GetFactionIcon());
}

//-----------------------------------------------------------------------
//-----------------------------------------------------------------------

function AS_SetButton(int Index, string ChosenName, string ChosenNickname)
{
	MC.BeginFunctionOp("SetButton");
	MC.QueueNumber(Index);
	MC.QueueString(ChosenName);
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ChosenNickname));
	MC.EndOp();
}
function AS_SetButtonIcon(int Index, StackedUIIconData IconInfo)
{
	local int i; 

	MC.BeginFunctionOp("SetButtonIcon");
	MC.QueueNumber(Index);
	MC.QueueBoolean(IconInfo.bInvert);
	for( i = 0; i < IconInfo.Images.Length; i++ )
	{
		MC.QueueString("img:///" $ IconInfo.Images[i]);
	}

	MC.EndOp();
}

function AS_SetInfoPanelIcon(StackedUIIconData IconInfo)
{
	local int i;

	MC.BeginFunctionOp("SetInfoPanelIcon");
	MC.QueueBoolean(IconInfo.bInvert);
	for( i = 0; i < IconInfo.Images.Length; i++ )
	{
		MC.QueueString("img:///" $ IconInfo.Images[i]);
	}

	MC.EndOp();
}

function RefreshHeaders()
{
	local int i;
	local XComGameState_AdventChosen InspectingChosen;
	local StackedUIIconData EmptyIcon;

	for (i = 0; i < AllActiveChosen.length; i++)
	{
		InspectingChosen = AllActiveChosen[i];
		AS_SetButton(i, InspectingChosen.GetChosenName(), InspectingChosen.GetChosenNickname());
		AS_SetButtonIcon(i, InspectingChosen.GetChosenIcon());
	}

	for (i = AllActiveChosen.length; i < 4; i++) //MAX: 4 on the flash stage. 
	{
		//Clear any unused buttons  
		AS_SetButton(i, class'UIResistanceReport_ChosenEvents'.default.UnknownChosenLabel, "");
		AS_SetButtonIcon(i, EmptyIcon);
	}


	MC.BeginFunctionOp("SetListHeader");
	MC.QueueString(ChosenInfo_ListTitle);
	MC.QueueString(ChosenInfo_ListSubtitle);
	MC.EndOp();

	MC.FunctionString("SetStrengthTitle", ChosenInfo_StrengthsLabel);
	MC.FunctionString("SetWeaknessTitle", ChosenInfo_WeaknessesLabel);
}

public function AS_SetInfoPanel(string Icon,
	string ChosenType,
	string ChosenName,
	string ChosenNickname,
	int	   EncountersValue,
	int	   SoldiersKilledValue,
	int	   SoldiersCapturedValue,
	int	   ChosenAwarenessMeterValue,
	string ChosenAwarenessMeterText,
	int    XComAwarenessMeterValue,
	string XComAwarenessMeterText)
{
	MC.BeginFunctionOp("SetInfoPanel");
	MC.QueueString(Icon);
	MC.QueueString(Caps(ChosenType));
	MC.QueueString(ChosenName);
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ChosenNickname));
	MC.QueueString(ChosenInfo_EncountersLabel);
	MC.QueueString(string(EncountersValue));
	MC.QueueString(ChosenInfo_KillsLabel);
	MC.QueueString(string(SoldiersKilledValue));
	MC.QueueString(ChosenInfo_CapturesLabel);
	MC.QueueString(string(SoldiersCapturedValue));
	MC.QueueString(ChosenInfo_ChosenAwarenessLabel);
	MC.QueueNumber(ChosenAwarenessMeterValue);
	MC.QueueString(ChosenAwarenessMeterText);
	MC.QueueString(ChosenInfo_XComAwarenessLabel);
	MC.QueueNumber(XComAwarenessMeterValue);
	MC.QueueString(XComAwarenessMeterText);
	MC.EndOp();
} 

function AS_SetWeaknessFaction(string FactionType, string FactionName)
{
	MC.BeginFunctionOp("SetWeaknessFaction");
	MC.QueueString(ChosenInfo_FactionLabel);
	MC.QueueString(Caps(FactionType));
	MC.QueueString(Caps(FactionName));
	MC.EndOp();
}

function AS_SetStrengthData(int Index, string ImagePath, string ItemName, string ItemDesc)
{
	MC.BeginFunctionOp("SetStrengthData");
	MC.QueueNumber(Index);
	MC.QueueString(ImagePath);
	MC.QueueString(ItemName);
	MC.QueueString(ItemDesc);
	MC.QueueBoolean(true);
	MC.EndOp();
}

function AS_SetWeaknessData(int Index, string IconPath, string ItemName, string ItemDesc)
{
	MC.BeginFunctionOp("SetWeaknessData");
	MC.QueueNumber(Index);
	MC.QueueString(IconPath);
	MC.QueueString(ItemName);
	MC.QueueString(ItemDesc);
	MC.QueueBoolean(true);
	MC.EndOp();
}

function AS_SetWeaknessFactionIcon(StackedUIIconData IconInfo)
{
	local int i;

	MC.BeginFunctionOp("SetWeaknessFactionIcon");
	MC.QueueBoolean(IconInfo.bInvert);
	for( i = 0; i < IconInfo.Images.Length; i++ )
	{
		MC.QueueString("img:///" $ IconInfo.Images[i]);
	}

	MC.EndOp();
}

//-----------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	bHandled = true;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :

	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :

		OnContinue();
		break;
	//bsg-crobinson (5.10.17): Move up and down through the chosen
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		SelectChosen(CurrentChosenIndex - 1); 
		break;
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		SelectChosen(CurrentChosenIndex + 1); 
		break;
	//bsg-crobinson (5.10.17): end
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
	local string callbackObj, tmp;
	local int buttonIndex;

	if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
	{
		callbackObj = args[args.Length - 2];
		if( InStr(callbackObj, "button") == -1 )
			return;

		tmp = GetRightMost(callbackObj);
		if( tmp != "" )
			buttonIndex = int(tmp);
		else
			buttonIndex = -1;

		SelectChosen(buttonIndex);
	}
	else if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN
		|| cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER
		|| cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER )
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("Play_Mouseover");
	}
	super.OnMouseEvent(cmd, args);
}


simulated function SelectChosen(int iChosen)
{
	`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("Generic_Mouse_Click");
	//bsg-crobinson (5.10.17): Swap through the chosen
	if (iChosen >= AllActiveChosen.Length)
		iChosen = 0;

	if (iChosen < 0)
		iChosen = AllActiveChosen.Length - 1;

	if( SelectedChosen != AllActiveChosen[iChosen] )
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ChosenPopupOpen");
		SelectedChosen = AllActiveChosen[iChosen];
		MC.ChildFunctionVoid("button_" $ CurrentChosenIndex, "onLoseFocus");
		CurrentChosenIndex = iChosen;
		MC.ChildFunctionVoid("button_" $ CurrentChosenIndex, "onReceieveFocus");
		RefreshDisplay();
	}
	//bsg-crobinson (5.10.17): end
}

simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ChosenPopupClose");
	super.CloseScreen();
}

simulated public function OnContinue()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	CloseScreen();
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxXPACK_ChosenInfo/XPACK_ChosenInfo";
	InputState = eInputState_Consume;
	UnknownChosenTraitIcon = "img:///UILibrary_PerkIcons.UIPerk_unknown"
}