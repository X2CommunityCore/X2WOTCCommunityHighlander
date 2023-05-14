//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_AcademySlot.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_AcademySlot extends UIFacility_StaffSlot
	dependson(UIPersonnel);

var localized string m_strTrainRookieDialogTitle;
var localized string m_strTrainRookieDialogText;
var localized string m_strStopTrainRookieDialogTitle;
var localized string m_strStopTrainRookieDialogText;
var localized string m_strNoRookiesTooltip;
var localized string m_strRookiesAvailableTooltip;


simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	super.InitStaffSlot(OwningContainer, LocationRef, SlotIndex, onStaffUpdatedDel);
	
	return self;
}

//-----------------------------------------------------------------------------
simulated function ShowDropDown()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectTrainRookie TrainProject;
	local string StopTrainingText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlot.IsSlotEmpty())
	{
		StaffContainer.ShowDropDown(self);
	}
	else // Ask the user to confirm that they want to empty the slot and stop training
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		UnitState = StaffSlot.GetAssignedStaff();
		TrainProject = XComHQ.GetTrainRookieProject(UnitState.GetReference());

		StopTrainingText = m_strStopTrainRookieDialogText;
		StopTrainingText = Repl(StopTrainingText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));
		StopTrainingText = Repl(StopTrainingText, "%CLASSNAME", TrainProject.GetTrainingClassTemplate().DisplayName);

		ConfirmEmptyProjectSlotPopup(m_strStopTrainRookieDialogTitle, StopTrainingText);
	}
}

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_Unit Unit;
	local UICallbackData_StateObjectReference CallbackData;

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);
	LocTag.StrValue1 = class'X2ExperienceConfig'.static.GetRankName((Unit.GetRank() + 1 + XComHQ.BonusTrainingRanks), '');

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = TrainRookieDialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strTrainRookieDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strTrainRookieDialogText);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function TrainRookieDialogCallback(Name eAction, UICallbackData xUserData)
{
	local UICallbackData_StateObjectReference CallbackData;
	
	CallbackData = UICallbackData_StateObjectReference(xUserData);
	
	if (eAction == 'eUIAction_Accept')
	{
		`HQPRES.UIChooseClass(CallbackData.ObjectRef);
	}
}

//==============================================================================

defaultproperties
{
	width = 370;
	height = 65;
}
