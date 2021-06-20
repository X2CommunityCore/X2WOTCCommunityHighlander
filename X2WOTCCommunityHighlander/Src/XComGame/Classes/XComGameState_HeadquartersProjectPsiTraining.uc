//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectPsiTraining.uc
//  AUTHOR:  Mark Nauta  --  11/11/2014
//  PURPOSE: This object represents the instance data for an XCom HQ psi training project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectPsiTraining extends XComGameState_HeadquartersProject native(Core);

var int iAbilityRank;	// the rank of the ability the psi operative will learn upon completing the project
var int iAbilityBranch; // the branch of the ability the psi operative will learn upon completing the project

var bool bForcePaused;

//---------------------------------------------------------------------------------------
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_GameTime TimeState;

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
	}

	// If the soldier is not already a Psi Operative (if they are, the ability will be assigned from the player's choice)
	if (UnitState.GetSoldierClassTemplateName() != 'PsiOperative')
	{
		// Randomly choose a branch and ability from the starting two tiers of the Psi Op tree
		iAbilityRank = `SYNC_RAND(2);
		iAbilityBranch = `SYNC_RAND(2);
		// Issue #1016
		/// HL-Docs: ref:OverridePsiTrainingProjectPoints
		ProjectPointsRemaining = TriggerOverridePsiTrainingProjectPoints(UnitState, CalculatePointsToTrain(true));
	}
	else
	{
		// Issue #1016
		/// HL-Docs: ref:OverridePsiTrainingProjectPoints
		ProjectPointsRemaining = TriggerOverridePsiTrainingProjectPoints(UnitState, CalculatePointsToTrain());
	}

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

	if(MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function int CalculatePointsToTrain(optional bool bClassTraining = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local int RankDifference;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (bClassTraining)
	{
		return XComHQ.GetPsiTrainingDays() * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24;
	}
	else
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
		RankDifference = Max(iAbilityRank - Unit.GetRank(), 0);
		return (XComHQ.GetPsiTrainingDays() + Round(XComHQ.GetPsiTrainingScalar() * float(RankDifference))) * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24;
	}
}

// Start Issue #1016
/// HL-Docs: feature:OverridePsiTrainingProjectPoints; issue:1016; tags:strategy
/// Allows listeners to override psi training times by modifying the number of
/// project points required.
/// 
/// The default rate of project points completed (work) per hour is given by
/// `XComGameState_HeadquartersXCom.XComHeadquarters_DefaultPsiTrainingWorkPerHour`,
/// which is 5 by default in XCOM 2 and WOTC. So to convert number of days to
/// project points, multiply the work per hour by 24 and then by the number of
/// days you want, e.g. WorkPerHour * 24 * 10 for a training time of 10 days.
///
/// Don't forget that the work per hour is increased by staffed scientists.
///
/// ```event
/// EventID: OverridePsiTrainingProjectPoints,
/// EventData: [in XComGameState_Unit Unit, inout int ProjectPoints],
/// EventSource: XComGameState_HeadquartersProjectPsiTraining (PsiTrainingProject),
/// NewGameState: none
/// ```
private function int TriggerOverridePsiTrainingProjectPoints(XComGameState_Unit UnitState, int ProjectPoints)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverridePsiTrainingProjectPoints';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].o = UnitState;
	Tuple.Data[1].kind = XComLWTVInt;
	Tuple.Data[1].i = ProjectPoints;

	`XEVENTMGR.TriggerEvent(Tuple.Id, Tuple, self);

	return Tuple.Data[1].i;
}
// End Issue #1016

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int iTotalWork;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	iTotalWork = XComHQ.PsiTrainingRate;

	// Can't make progress when paused
	if (bForcePaused && !bAssumeActive)
	{
		return 0;
	}

	return iTotalWork;
}

//---------------------------------------------------------------------------------------
function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	local XComGameState_Unit Unit;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;

	OrderInput.OrderType = eHeadquartersOrderType_PsiTrainingCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
	AbilityName = Unit.GetAbilityName(iAbilityRank, iAbilityBranch);
	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);

	`HQPRES.UIPsiTrainingComplete(ProjectFocus, AbilityTemplate);
	
	// Start Issue #534
	TriggerPsiProjectCompleted(Unit, AbilityName);
	// End Issue #534
}

// Start Issue #534
/// HL-Docs: feature:PsiProjectCompleted; issue:534; tags:strategy
/// Triggers a `PsiProjectCompleted` event to inform mods that a 
/// Psi Operative has finished training in the Psi Lab.
///    
///```event
///EventID: PsiProjectCompleted,
///EventData: [in XComGameState_Unit Unit, in string AbilityName],
///EventSource: XComGameState_HeadquartersProjectPsiTraining (PsiTrainingProject),
///NewGameState: none
///```
function TriggerPsiProjectCompleted(XComGameState_Unit Unit, name AbilityName)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'PsiProjectCompleted';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].o = Unit;
	Tuple.Data[1].kind = XComLWTVObject;
	Tuple.Data[1].s = string(AbilityName);

	`XEVENTMGR.TriggerEvent('PsiProjectCompleted', Tuple, self);
}
// End Issue #534

//---------------------------------------------------------------------------------------
DefaultProperties
{
}