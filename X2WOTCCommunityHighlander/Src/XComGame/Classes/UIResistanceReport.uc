
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIResistanceReport
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Shows end of month information summary.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 


class UIResistanceReport extends UIX2SimpleScreen;

var localized String m_strReportTitle;
var localized String m_strResistanceActivity;
var localized String m_strAlienActivity;
var localized String m_strSupplyTitle;
var localized String m_strSupplyLossTitle; 
var localized String m_strBonusSupply;
var localized String m_strResistanceReportGreeble;
var localized String m_strAvatarProgressLabel;
var localized String m_strStaffingHelp; 
var localized String m_strDarkEventPenalty; 
var localized String m_strStaffAvailable;

var UILargeButton ContinueButton;

var name DisplayTag;
var string CameraTag;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	UpdateNavHelp();
	BuildScreen();

	class'UIUtilities_Sound'.static.PlayOpenSound();
	
	//TODO: Leave geoscape? 

	class'UIUtilities'.static.DisplayUI3D(DisplayTag, name(CameraTag), `SCREENSTACK.IsInStack(class'UIStrategyMap') ? 0.0 : `HQINTERPTIME);
	
	if (TriggerShouldShowCouncil()) // Issue #663
	{
		`XCOMGRI.DoRemoteEvent('CIN_ShowCouncil');
		TriggerResistanceMoraleVO(); // Trigger the council spokesman's remarks
	}
	else
	{
		`XCOMGRI.DoRemoteEvent('CIN_ShowResistance');
	}

	`HQPRES.m_kAvengerHUD.FacilityHeader.Hide();
}

// Start issue #663
/// HL-Docs: feature:UIResistanceReport_ShowCouncil; issue:663; tags:strategy,ui
/// Allows overriding whether to show the council guy and his remarks in the background
/// at the end of month.
///
///
/// ```event
/// EventID: UIResistanceReport_ShowCouncil,
/// EventData: [inout bool ShouldShow],
/// EventSource: UIResistanceReport (Screen),
/// NewGameState: none
/// ```
protected simulated function bool TriggerShouldShowCouncil ()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Data.Add(1);
	Tuple.Data[0].Kind = XComLWTVBool;
	Tuple.Data[0].b = class'UIUtilities_Strategy'.static.GetXComHQ().GetObjectiveStatus('T5_M1_AutopsyTheAvatar') != eObjectiveState_Completed; // Vanilla logic

	`XEVENTMGR.TriggerEvent('UIResistanceReport_ShowCouncil', Tuple, self);

	return Tuple.Data[0].b;
}
// End issue #663

function TriggerResistanceMoraleVO()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Monthly Report Event");
	`XEVENTMGR.TriggerEvent(RESHQ().GetResistanceMoodEvent(), , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

//-------------- UI LAYOUT --------------------------------------------------------

simulated function BuildScreen()
{
	AS_UpdateCouncilReportCardInfo(m_strReportTitle, GetDateString(), m_strResistanceReportGreeble);

	UpdateCouncilReportCardRewards();
	UpdateResistanceActivity();
	UpdateCouncilReportCardStaff();
	UpdateAlienActivity();
	UpdateAvatarProgress();
	
	MC.FunctionVoid("AnimateIn");
}

simulated function UpdateCouncilReportCardRewards()
{
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local bool bIsPositiveMonthly; 
	// Vars for Issue #539
	local string SupplyLossReason, SupplyLossAmount;
	// End vars

	ResistanceHQ = RESHQ();
	bIsPositiveMonthly = (ResistanceHQ.GetSuppliesReward(true) > 0);

	MC.BeginFunctionOp("UpdateCouncilReportCardRewards");
	MC.QueueString(bIsPositiveMonthly ? m_strSupplyTitle : m_strSupplyLossTitle);
	MC.QueueString(GetSupplyRewardString());
	MC.QueueBoolean(bIsPositiveMonthly);

	// All In Bonus
	if( ResistanceHQ.SupplyDropPercentIncrease > 0 )
	{
		MC.QueueString(m_strBonusSupply);
		MC.QueueString("+" $ ResistanceHQ.SupplyDropPercentIncrease $ "%");
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
	}

	// Start Issue #539
	//
	// Allow mods to replace or extend the display string for supply losses at
	// the end of the month. Rather than queue the display strings right away,
	// we save them to two local variables that can be overridden by an event.
	// Then we queue their values at the end.

	// Rural Checkpoints Dark Event
	if( ResistanceHQ.SavedSupplyDropPercentDecrease > 0 )
	{
		SupplyLossReason = m_strDarkEventPenalty;
		SupplyLossAmount = Round(ResistanceHQ.SavedSupplyDropPercentDecrease * 100.0) $ "%";
	}
	else
	{
		SupplyLossReason = "";
		SupplyLossAmount = "";
	}

	TriggerOverrideSupplyLossStrings(SupplyLossReason, SupplyLossAmount);

	MC.QueueString(SupplyLossReason);
	MC.QueueString(SupplyLossAmount != "" ? ("-" $ SupplyLossAmount ): "");
	// End Issue #539

	MC.EndOp();
}

// Start Issue #539
//
// Fires an 'OverrideSupplyLossStrings' event that allows listeners to override
// the "supplies lost" text in the resistance report. They can either change the
// source of or reason for the supply loss or they can change the amount lost, or
// they can do both.
//
// The event takes the form:
//
//  {
//     ID: OverrideSupplyLossStrings,
//     Data: [inout string SupplyLossReason, inout string SupplyLossAmount],
//     Source: self (UIResistanceReport)
//  }
//
function TriggerOverrideSupplyLossStrings(out string SupplyLossReason, out string SupplyLossAmount)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideSupplyLossStrings';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].Kind = XComLWTVString;
	OverrideTuple.Data[0].s = SupplyLossReason;
	OverrideTuple.Data[1].Kind = XComLWTVString;
	OverrideTuple.Data[1].s = SupplyLossAmount;

	`XEVENTMGR.TriggerEvent('OverrideSupplyLossStrings', OverrideTuple, self);

	SupplyLossReason = OverrideTuple.Data[0].s;
	SupplyLossAmount = OverrideTuple.Data[1].s;
}
// End Issue #539

simulated function UpdateCouncilReportCardStaff()
{
	//local XComGameStateHistory History;
	//local array<StateObjectReference> PersonnelRewards;
	//local XComGameState_Reward ResReward;
	//local array<string> arrNewStaffNames;
	//local string strStaffName;
	//local int idx;
	//
	//arrNewStaffNames.Length = 3;
	//
	//History = `XCOMHISTORY;
	//PersonnelRewards = RESHQ().PersonnelGoods;
	//for (idx = 0; idx < PersonnelRewards.Length; idx++)
	//{
	//	ResReward = XComGameState_Reward(History.GetGameStateForObjectID(PersonnelRewards[idx].ObjectID));
	//	strStaffName = class'X2StrategyElement_DefaultRewards'.static.GetPersonnelName(ResReward);
	//	arrNewStaffNames[idx] = strStaffName;
	//}
	//
	//AS_UpdateCouncilReportCardStaff(m_strStaffAvailable, arrNewStaffNames[0], arrNewStaffNames[1], arrNewStaffNames[2], m_strStaffingHelp);

	AS_UpdateCouncilReportCardStaff("", "", "", "", "");
}

simulated function UpdateResistanceActivity()
{
	local array<TResistanceActivity> arrActions;
	local String strAction, strActivityList;
	local int iAction;

	arrActions = RESHQ().GetMonthlyActivity();
	
	for( iAction = 0; iAction < arrActions.Length; iAction++ )
	{
		strAction = class'UIUtilities_Text'.static.GetColoredText(arrActions[iAction].Title @ string(arrActions[iAction].Count), arrActions[iAction].Rating);
		strActivityList $= strAction;
		if (iAction < arrActions.Length - 1)
		{
			strActivityList $= ", ";
		}
	}

	AS_UpdateCouncilReportCardResistanceActivity(m_strResistanceActivity, class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strActivityList));
}

simulated function UpdateAlienActivity()
{
	local array<TResistanceActivity> arrActions;
	local String strAction, strActivityList;
	local int iAction;

	arrActions = RESHQ().GetMonthlyActivity(true);

	for (iAction = 0; iAction < arrActions.Length; iAction++)
	{ 
		strAction = class'UIUtilities_Text'.static.GetColoredText(arrActions[iAction].Title @ string(arrActions[iAction].Count), arrActions[iAction].Rating);
		
		strActivityList $= strAction;
		if (iAction < arrActions.Length - 1)
		{
			strActivityList $= ", ";
		}
	}

	AS_UpdateCouncilReportCardAlienActivity(m_strAlienActivity, class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strActivityList));
}
simulated function UpdateAvatarProgress()
{
	if (!ALIENHQ().bHasSeenDoomMeter)
	{
		AS_UpdateCouncilReportCardAvatarProgress("", -1);
	}
	else
	{
		AS_UpdateCouncilReportCardAvatarProgress(m_strAvatarProgressLabel, ALIENHQ().GetCurrentDoom());
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		OnContinue();
		return true;
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		return false;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//-------------- EVENT HANDLING ----------------------------------------------------------
simulated function OnContinue()
{
	CloseScreen();
}

simulated function UpdateNavHelp()
{
	if( HQPRES() != none )
	{
		HQPRES().m_kAvengerHUD.NavHelp.ClearButtonHelp();
		HQPRES().m_kAvengerHUD.NavHelp.AddContinueButton(OnContinue);
	}
}

simulated function CloseScreen()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	// Reset the monthly resistance activities
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Monthly Resistance Activities");
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', RESHQ().ObjectID));
	ResistanceHQ.ResetActivities();

	// Start Issue #539
	//
	// Allow mods to do extra end-of-month processing once the resistance
	// report is closed.
	`XEVENTMGR.TriggerEvent('PostEndOfMonth', , self, NewGameState);
	// End Issue #539

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	HQPRES().m_kAvengerHUD.NavHelp.ClearButtonHelp();
	super.CloseScreen();

	HQPRES().UIResistanceReport_ChosenEvents();
}

simulated function Remove()
{
	super.Remove();
	`XCOMGRI.DoRemoteEvent('CIN_HideCouncil');
	`XCOMGRI.DoRemoteEvent('CIN_HideResistance');
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------

simulated function String GetDateString()
{
	return class'X2StrategyGameRulesetDataStructures'.static.GetDateString(`GAME.GetGeoscape().m_kDateTime);
}

simulated function String GetSupplyRewardString()
{
	local int SuppliesReward;
	local string Prefix;

	SuppliesReward = RESHQ().GetSuppliesReward(true);
	
	if(SuppliesReward < 0)
	{
		// Start Issue #539
		//
		// Check with listeners whether negative supplies should be displayed
		// as is or displayed as 0.
		if (!TriggerOverrideDisplayNegativeIncome())
		{
			SuppliesReward = 0;
		}
		// End Issue #539
	}

	Prefix = (SuppliesReward < 0) ? "-" : "+";
	return Prefix $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ String(int(Abs(SuppliesReward)));
}

// Start Issue #539
//
// Fires an 'OverrideDisplayNegativeIncome' event that allows mods to determine
// how the monthly report should display negative income. If the bool property
// in the event data is `true`, then the income is displayed as a negative value.
// Otherwise, it is displayed as 0.
//
// The method returns `true` if the negative supplies can be displayed.
//
// The event takes the form:
//
//   {
//      ID: OverrideDisplayNegativeIncome,
//      Data: [out bool DisplayNegativeIncome],
//      Source: self (UIResistanceReport)
//   }
//
function bool TriggerOverrideDisplayNegativeIncome()
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideDisplayNegativeIncome';
	OverrideTuple.Data.Add(1);
	OverrideTuple.Data[0].Kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;

	`XEVENTMGR.TriggerEvent('OverrideDisplayNegativeIncome', OverrideTuple, self);

	return OverrideTuple.Data[0].b;
}
// End Issue #539

//-------------- FLASH DIRECT ACCESS --------------------------------------------------

simulated function AS_UpdateCouncilReportCardInfo(string strTitle, string strSubtitle, string strGreeble)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardInfo");
	MC.QueueString(strTitle);
	MC.QueueString(strSubtitle);
	MC.QueueString(strGreeble);
	MC.EndOp();
}

simulated function AS_UpdateCouncilReportCardAlienActivity(string strTitle, string strDescription)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardAlienActivity");
	MC.QueueString(strTitle);
	MC.QueueString(strDescription);
	MC.EndOp();
}

simulated function AS_UpdateCouncilReportCardResistanceActivity(string strTitle, string strDescription)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardResistanceActivity");
	MC.QueueString(strTitle);
	MC.QueueString(strDescription);
	MC.EndOp();
}

simulated function AS_UpdateCouncilReportCardStaff(string strTitle, string strStaff0, string strStaff1, string strStaff2, string strHelpText)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardStaff");
	MC.QueueString(strTitle);
	MC.QueueString(strStaff0);
	MC.QueueString(strStaff1);
	MC.QueueString(strStaff2);
	MC.QueueString(strHelpText);
	MC.EndOp();
}
simulated function AS_UpdateCouncilReportCardAvatarProgress(string strAvatarLabel, int numPips)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardAvatarProgress");
	MC.QueueString(strAvatarLabel);
	MC.QueueNumber(numPips);
	MC.EndOp();
}

//------------------------------------------------------

defaultproperties
{
	Package = "/ package/gfxCouncilScreen/CouncilScreen";
	LibID = "CouncilScreenReportCard";
	DisplayTag = "UIDisplay_Council"
	CameraTag = "UIDisplayCam_ResistanceScreen"
}
