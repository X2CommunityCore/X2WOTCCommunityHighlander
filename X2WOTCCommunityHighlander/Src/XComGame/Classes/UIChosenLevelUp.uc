//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChosenLevelUp.uc
//  AUTHOR:  Joe Weinhoffer -- 4/11/2017
//  PURPOSE: This file displays information about a Chosen who recently leveled up
//---------------------------------------------------------------------------------------
//  Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChosenLevelUp extends UIScreen;

var public localized String ChosenLevelUpTitle;
var public localized String ChosenLevelUpBody;
var public localized String StrengthsLabel;
var public localized String WeaknessesLabel;
var public localized String AbilityLabel;
var public localized String AbilityList;

var StateObjectReference ChosenRef;

var DynamicPropertySet DisplayPropertySet;

//----------------------------------------------------------------------------
// MEMBERS

simulated function OnInit()
{
	super.OnInit();

	BuildScreen();
}

simulated function BuildScreen()
{
	local XComGameState NewGameState;
	local XComGameState_AdventChosen ChosenState;
	local array<X2AbilityTemplate> ChosenStrengths;
	local X2AbilityTemplate NewStrength;
	local String strChosenType, strChosenName, strChosenNickname, strBody;
	local String strStrengthName, strStrengthIcon, strStrengthDesc;
	local String strWeaknessName, strWeaknessIcon, strWeaknessDesc;
	local XComGameStateHistory History;
	local XGParamTag ParamTag;
	local String strChosenFanfare;

	History = `XCOMHISTORY;
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ChosenRef.ObjectID));

	if (ChosenState != None)
	{
		strChosenType = "";
		strChosenName = ChosenState.GetChosenName();
		strChosenNickname = ChosenState.GetChosenClassName();

		ChosenStrengths = ChosenState.GetChosenStrengths();
		NewStrength = ChosenStrengths[ChosenStrengths.Length - 1];
		strStrengthName = NewStrength.LocFriendlyName;
		strStrengthIcon = NewStrength.IconImage;
		strStrengthDesc = NewStrength.LocLongDescription;

		strWeaknessName = "";
		strWeaknessIcon = "";
		strWeaknessDesc = "";

		if (ChosenState.GetFanfareSound(strChosenFanfare))
		{
			`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent(strChosenFanfare);
		}
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = ChosenState.GetChosenClassName();
	strBody = `XEXPAND.ExpandString(ChosenLevelUpBody);
	
	AS_UpdateData(
		""/*InspectingChosen.GetChosenIcon()*/,
		string(ChosenState.Level),
		Caps(strChosenType),
		strChosenName,
		Caps(strChosenNickname),
		strBody,
		strStrengthName, strStrengthIcon, strStrengthDesc,
		strWeaknessName, strWeaknessIcon, strWeaknessDesc);

	AS_SetChosenImage(ChosenState.GetChosenPortraitImage());

	`HQPRES.m_kAvengerHUD.NavHelp.AddContinueButton(OnContinue);
	MC.FunctionVoid("AnimateIn");

	AS_SetInfoPanelIcon(ChosenState.GetChosenIcon());

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Chosen Leveled Up");
	`XEVENTMGR.TriggerEvent(ChosenState.GetLeveledUpEvent(), , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

public function AS_UpdateData(
	string ChosenIcon,
	string ChosenLevel,
	string ChosenType,
	string ChosenName,
	string ChosenNickname,
	string Description,
	string StrengthTitle,
	string StrengthIcon,
	string StrengthValue,
	optional string WeaknessTitle,
	optional string WeaknessIcon,
	optional string WeaknessValue)
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(ChosenLevelUpTitle); //default text
	MC.QueueString(ChosenIcon);
	MC.QueueString(ChosenLevel);
	MC.QueueString(ChosenType);
	MC.QueueString(ChosenName);
	MC.QueueString(ChosenNickname);
	MC.QueueString(Description);
	MC.QueueString(StrengthsLabel);
	MC.QueueString(StrengthIcon);
	MC.QueueString(StrengthTitle);
	MC.QueueString(StrengthValue);
	MC.QueueString(WeaknessesLabel);
	MC.QueueString(WeaknessIcon);
	MC.QueueString(WeaknessTitle);
	MC.QueueString(WeaknessValue);
	MC.QueueString(AbilityLabel);
	MC.QueueString(AbilityList);
	MC.EndOp();
}

public function AS_SetInfoPanelIcon(StackedUIIconData IconInfo)
{
	local int i;

	MC.BeginFunctionOp("SetChosenIcon");
	MC.QueueBoolean(IconInfo.bInvert);
	for (i = 0; i < IconInfo.Images.Length; i++)
	{
		MC.QueueString("img:///" $ IconInfo.Images[i]);
	}

	MC.EndOp();
}

public function AS_SetChosenImage(string ChosenImage)
{
	MC.FunctionString("SetChosenImage", ChosenImage);
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

	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated public function OnContinue()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	CloseScreen();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	`HQPRES.m_kAvengerHUD.NavHelp.AddContinueButton(OnContinue);
}

simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ChosenPopupClose");
	super.CloseScreen();
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxXPACK_ChosenFavored/XPACK_ChosenFavored";
	InputState = eInputState_Consume;
}