//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIRewardsRecap
//  AUTHOR:  Sam Batista
//  PURPOSE: Shows a list of rewards obtained during last mission.
//           Part of the post mission flow.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIInventory_VIPRecovered extends UIPanel;

enum EVIPStatus
{
	eVIPStatus_Unknown,
	eVIPStatus_Recovered,
	eVIPStatus_Awarded,
	eVIPStatus_Killed,
	eVIPStatus_Lost
};

var name PawnLocationTag;
var localized string m_strVIPStatus[eVIPStatus.EnumCount]<BoundEnum=eVIPStatus>;
var localized string m_strEnemyVIPStatus[eVIPStatus.EnumCount]<BoundEnum=eVIPStatus>;
var XComUnitPawn ActorPawn;
var StateObjectReference RewardUnitRef;

simulated function UIInventory_VIPRecovered InitVIPRecovered()
{
	InitPanel();
	PopulateData();
	return self;
}

simulated function PopulateData()
{
	local bool bDarkVIP;
	local string VIPIcon, StatusLabel;
	local EUIState VIPState;
	local EVIPStatus VIPStatus;
	local XComGameState_Unit Unit;
	local XComGameState_MissionSite Mission;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState NewGameState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	Mission = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	RewardUnitRef = Mission.GetRewardVIP();
	
	if(RewardUnitRef.ObjectID <= 0)
	{
		`RedScreen("UIInventory_VIPRecovered did not get a valid Unit Reference.");
		return;
	}

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(RewardUnitRef.ObjectID));
	VIPStatus = EVIPStatus(Mission.GetRewardVIPStatus(Unit));
	bDarkVIP = Unit.GetMyTemplateName() == 'HostileVIPCivilian';

	if(Unit.IsEngineer() || Unit.GetMyTemplateName() == 'Engineer_VIP')
	{
		VIPIcon = class'UIUtilities_Image'.const.EventQueue_Engineer;
	}
	else if(Unit.IsScientist() || Unit.GetMyTemplateName() == 'Scientist_VIP')
	{
		VIPIcon = class'UIUtilities_Image'.const.EventQueue_Science;
	}
	else if(bDarkVIP)
	{
		VIPIcon = class'UIUtilities_Image'.const.EventQueue_Advent;
	}

	switch(VIPStatus)
	{
	case eVIPStatus_Awarded:
	case eVIPStatus_Recovered:
		VIPState = eUIState_Good;
		CreateVIPPawn(Unit);
		break;
	default:
		VIPState = eUIState_Bad;
		break;
	}

	if(bDarkVIP)
		StatusLabel = m_strEnemyVIPStatus[VIPStatus];
	else
		StatusLabel = m_strVIPStatus[VIPStatus];

	AS_UpdateData(class'UIUtilities_Text'.static.GetColoredText(StatusLabel, VIPState), 
		class'UIUtilities_Text'.static.GetColoredText(Unit.GetFullName(), bDarkVIP ? eUIState_Bad : eUIState_Normal),
		VIPIcon, ResistanceHQ.VIPRewardsString);

	if (XComHQ.GetObjectiveStatus('XP0_M6_MoxReturns') == eObjectiveState_InProgress)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Mox VIP Recovered");
		if (VIPStatus == eVIPStatus_Awarded || VIPStatus == eVIPStatus_Recovered)
		{
			`XEVENTMGR.TriggerEvent('MoxRescuedVIPRecovered', , , NewGameState);
		}		
		`XEVENTMGR.TriggerEvent('MoxRescuedComplete', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

simulated function CreateVIPPawn(XComGameState_Unit Unit)
{
	local PointInSpace PlacementActor;
	local XComLWTuple OverrideTuple; //for issue #229
	local float CustomScale; // issue #229
	
	// Don't do anything if we don't have a valid UnitReference
	if(Unit == none) return;

	foreach WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if (PlacementActor != none && PlacementActor.Tag == PawnLocationTag)
			break;
	}

	
	ActorPawn = `HQPRES.GetUIPawnMgr().RequestPawnByState(self, Unit, PlacementActor.Location, PlacementActor.Rotation);
	ActorPawn.GotoState('CharacterCustomization');
	ActorPawn.EnableFootIK(false);

	if (Unit.IsSoldier())
	{
		ActorPawn.CreateVisualInventoryAttachments(`HQPRES.GetUIPawnMgr(), Unit);
	}

	//start issue #229: instead of boolean check, always trigger event to check if we should use custom unit scale.
	CustomScale = Unit.UseLargeArmoryScale() ? class'UIArmory'.default.LargeUnitScale : 1.0f;

	//set up a Tuple for return value
	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideUIVIPScale';
	OverrideTuple.Data.Add(3);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;
	OverrideTuple.Data[1].kind = XComLWTVFloat;
	OverrideTuple.Data[1].f = CustomScale;
	OverrideTuple.Data[2].kind = XComLWTVObject;
	OverrideTuple.Data[2].o = Unit;
	`XEVENTMGR.TriggerEvent('OverrideUIVIPScale', OverrideTuple, Unit, none);
	
	//if the unit should use the large armory scale by default, then either they'll use the default scale
	//or a custom one given by a mod according to their character template
	if(OverrideTuple.Data[0].b || Unit.UseLargeArmoryScale()) 
	{
		CustomScale = OverrideTuple.Data[1].f;
		ActorPawn.Mesh.SetScale(CustomScale);
	}
	//end issue #229
}

simulated function Cleanup()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	if (ActorPawn == none)
		return;

	`HQPRES.GetUIPawnMgr().ReleasePawn(self, RewardUnitRef.ObjectID);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear VIP Reward Data");
	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	ResistanceHQ.ClearVIPRewardsData();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function AS_UpdateData(string Title, string VIPName, string VIPIcon, string VIPReward)
{
	MC.BeginFunctionOp("updateData");
	MC.QueueString(Title);
	MC.QueueString(VIPName);
	MC.QueueString(VIPIcon);
	MC.QueueString(VIPReward);
	MC.EndOp();
}

//------------------------------------------------------

defaultproperties
{
	LibID = "VIPRecovered";
	PawnLocationTag = "UIPawnLocation_VIP_0";
}
