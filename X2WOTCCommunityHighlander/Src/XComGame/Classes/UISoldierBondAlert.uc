//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISoldierBondAlert.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Soldier bond information screen.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISoldierBondAlert extends UIScreen;

var localized string BondAlertLabelBetweenSoldiers_And;
var localized string BondAlertTitle;
var localized string BondAlertDescription;
var localized string BondAlertDetails;
var localized string BondAlertDetailsHigherLevel;
var localized string BondAlertContinueToGTS;
var localized string BondAlertContinueToRecoveryCenter;
var localized string BondAlertLackingGTS;
var localized string BondAlertLackingRecoveryCenter;
var localized string BondAlertDisabledGeneric;

var StateObjectReference UnitRef1;
var StateObjectReference UnitRef2;

var private int BondLevel; 

simulated function OnInit()
{
	super.OnInit();
	UpdateData();
	MC.FunctionVoid("AnimateIn");
}

function UpdateData()
{
	local XComGameState_Unit Unit1, Unit2;
	local string ClassIcon1, ClassIcon2, RankIcon1, RankIcon2;
	local X2SoldierClassTemplate SoldierClass1, SoldierClass2;
	local SoldierBond BondData;
	local XGParamTag kTag;
	local UIButton OKButton, CancelButton;
	local string Details;
	
	Unit1 = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef1.ObjectID));
	Unit2 = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef2.ObjectID));

	SoldierClass1 = Unit1.GetSoldierClassTemplate();
	RankIcon1 = class'UIUtilities_Image'.static.GetRankIcon(Unit1.GetRank(), SoldierClass1.DataName);
	ClassIcon1 = SoldierClass1.IconImage;

	SoldierClass2 = Unit2.GetSoldierClassTemplate();
	RankIcon2 = class'UIUtilities_Image'.static.GetRankIcon(Unit2.GetRank(), SoldierClass2.DataName);
	ClassIcon2 = SoldierClass2.IconImage;

	Unit1.GetBondData(UnitRef2, BondData);
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = string(BondData.BondLevel + 1); //Offsetting by one, because "bond level zero" is weird to read, player-facing. 

	BondLevel = BondData.BondLevel;

	if(BondLevel == 0)
	{
		Details = BondAlertDetails;
	}
	else
	{
		Details = BondAlertDetailsHigherLevel;
	}

	TriggerBondAlertEvents(BondData);

	SetBondLevelData(BondLevel + 1,//adding one more so we are showing the next level icon that you will be promoted to instead of the current level icon
					 `XEXPAND.ExpandString(BondAlertTitle),
					 RankIcon1,
					 ClassIcon1,
					 Caps(Unit1.GetName(eNameType_Full)),
					 RankIcon2,
					 ClassIcon2,
					 Caps(Unit2.GetName(eNameType_Full)),
					 BondAlertDescription,
					 Details); 

	OKButton = Spawn(class'UIButton', self);
	OKButton.ResizeToText = false; 
	OKButton.InitButton('OKButton', , ConfirmCallback);
	OKButton.SetDisabled(!CanContinue());
	OKButton.SetText(GetContinueButtonLabel());

	CancelButton = Spawn(class'UIButton', self);
	CancelButton.ResizeToText = false;
	CancelButton.InitButton('CancelButton', class'UISimpleScreen'.default.m_strIgnore, CancelCallback);
	
	//bsg-crobinson (5.18.17): Remove navigation, move to traditional controller button prompts
	if (`ISCONTROLLERACTIVE)
	{
		OkButton.SetStyle(eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		OKButton.SetGamepadIcon("");
		OKButton.SetText(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetAdvanceButtonIcon(),20,20,-10) @ GetContinueButtonLabel());
		OKButton.DisableNavigation();

		CancelButton.SetStyle(eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		CancelButton.SetGamepadIcon("");
		CancelButton.SetPosition(450, 695);
		CancelButton.SetText(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetBackButtonIcon(),20,20,-10) @ class'UISimpleScreen'.default.m_strIgnore);
		CancelButton.DisableNavigation();
	}
	//bsg-crobinson (5.18.17): end
}

function TriggerBondAlertEvents(SoldierBond BondData)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Bond Alert");
	if (BondData.BondLevel > 0)
	{
		`XEVENTMGR.TriggerEvent('OnLevelUpBondAvailable', , , NewGameState);

		// Trigger reminder event if there have been multiple bonds leveled up and recovery center not build yet
		if (XComHQ.GetNumberOfPossibleLevelUpBonds() % 3 == 0 && !XComHQ.HasFacilityByName('RecoveryCenter'))
		{
			`XEVENTMGR.TriggerEvent('OnLevelUpBondReminder', , , NewGameState);
		}
	}
	else
	{
		`XEVENTMGR.TriggerEvent('OnBondAvailable', , , NewGameState);
	}
	`GAMERULES.SubmitGameState(NewGameState);
}

function SetBondLevelData(int iBondLevel,
						  string Title,
						  string RankIcon1,
						  string ClassIcon1,
						  string Name1,
						  string RankIcon2,
						  string ClassIcon2,
						  string Name2,
						  string Description,
						  string Details)
{

	MC.BeginFunctionOp("SetBondLevelData");
	MC.QueueNumber(iBondLevel);
	MC.QueueString(Title);
	MC.QueueString(RankIcon1);
	MC.QueueString(ClassIcon1);
	MC.QueueString(Name1);
	MC.QueueString(RankIcon2);
	MC.QueueString(ClassIcon2);
	MC.QueueString(Name2);
	MC.QueueString(BondAlertLabelBetweenSoldiers_And);
	MC.QueueString(Description);
	MC.QueueString(Details);
	MC.EndOp();
}

//==============================================================================

function bool CanContinue()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	if( BondLevel == 0 )
	{
		return true;
	}
	else if( BondLevel > 0 )
	{
		if( XComHQ.HasFacilityByName('RecoveryCenter') )
			return true; 
	}

	return false;
}

function string GetContinueButtonLabel()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if( BondLevel == 0 )
	{
		return BondAlertContinueToGTS;
	}
	else if( BondLevel > 0 )
	{
		if( XComHQ.HasFacilityByName('RecoveryCenter') )
			return BondAlertContinueToRecoveryCenter;
		else
			return BondAlertLackingRecoveryCenter;
	}

	return BondAlertDisabledGeneric;
}


simulated public function ConfirmCallback(UIButton ButtonControl)
{
	local XComGameState_HeadquartersXCom XComHQ;
	
	if( !CanContinue() )
		return; 

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if( BondLevel == 0 )
	{
		OpenConfirmBondScreen();
	}
	else if( BondLevel > 0 )
	{
		if( XComHQ.HasFacilityByName('RecoveryCenter') )
			GoToRecoveryCenter();
	}
	
	CloseScreen(); // Close screen needs to happen last, so other popups in the stack do not have time to receive focus and trigger incorrect VO
}

private function OpenConfirmBondScreen()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit1State, Unit2State;

	History = `XCOMHISTORY;
	Unit1State = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef1.ObjectID));
	Unit2State = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef2.ObjectID));

	`HQPRES.UISoldierBondConfirm(Unit1State, Unit2State);
}

private function GoToRecoveryCenter()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if( FacilityState.GetMyTemplateName() == 'RecoveryCenter' && !FacilityState.IsUnderConstruction() )
		{
			`HQPRES.m_kAvengerHUD.Shortcuts.SelectFacilityHotlink(FacilityState.GetReference());
			return;
		}
	}
}

simulated public function CancelCallback(UIButton ButtonControl)
{
	CloseScreen();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		CancelCallback(none);
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		ConfirmCallback(none);
		break;

	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxXPACK_SoldierBondAlert/XPACK_SoldierBondAlert";
	InputState = eInputState_Consume;
}
