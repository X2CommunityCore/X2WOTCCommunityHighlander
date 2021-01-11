//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectRespecSoldier.uc
//  AUTHOR:  Joe Weinhoffer  --  06/05/2015
//  PURPOSE: This object represents the instance data for an XCom HQ respec soldier project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectRespecSoldier extends XComGameState_HeadquartersProject native(Core);

//---------------------------------------------------------------------------------------
// Call when you start a new project, NewGameState should be none if not coming from tactical
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility
	
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	//UnitState.PsiTrainingRankReset();
	UnitState.SetStatus(eStatus_Training);
	
	// Start Issue #624
	ProjectPointsRemaining = TriggerOverrideRespecSoldierProjectPoints(UnitState, CalculatePointsToRespec());
	// End Issue #624
	InitialProjectPoints = ProjectPointsRemaining;

	UpdateWorkPerHour(NewGameState);
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}

	if (MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

// Start Issue #624
/// HL-Docs: feature:OverrideRespecSoldierProjectPoints; issue:624; tags:strategy
/// The 'OverrideRespecSoldierProjectPoints' event that allows mods to 
/// override the number of project points, i.e. time required to respec a given soldier.
///
/// The listener is passed the Unit State of the soldier that is to be respecced
/// and the current amount of project points required, either from the base game's config,
/// or from a listener that has fired earlier. To override the project points, 
/// the listener simply needs to provide a new value for the ProjectPoints element of the tuple.
///
///```event
///EventID: OverrideRespecSoldierProjectPoints,
///EventData: [in XComGameState_Unit Unit, inout int ProjectPoints],
///EventSource: XComGameState_HeadquartersProjectRespecSoldier (RespecProject),
///NewGameState: none
///```
function int TriggerOverrideRespecSoldierProjectPoints(XComGameState_Unit UnitState, int ProjectPoints)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideRespecSoldierProjectPoints';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVObject;
	OverrideTuple.Data[0].o = UnitState;
	OverrideTuple.Data[1].kind = XComLWTVInt;
	OverrideTuple.Data[1].i = ProjectPoints;

	`XEVENTMGR.TriggerEvent('OverrideRespecSoldierProjectPoints', OverrideTuple, self);

	return OverrideTuple.Data[1].i;
}
// End Issue #624

//---------------------------------------------------------------------------------------
function int CalculatePointsToRespec()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	return XComHQ.GetRespecSoldierDays() * 24;
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return 1;
}

//---------------------------------------------------------------------------------------
// Remove the project
function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	
	OrderInput.OrderType = eHeadquartersOrderType_RespecSoldierCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	`HQPRES.UITrainingComplete(ProjectFocus);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}
