//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectRecoverWill.uc
//  AUTHOR:  Mark Nauta  --  08/31/2016
//  PURPOSE: This object represents the instance data for an XCom HQ recover will project
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectRecoverWill extends XComGameState_HeadquartersProject;

var int PointsPerBlock;
var int OriginalWorkPerHour;

//---------------------------------------------------------------------------------------
// Call when you start a new project, NewGameState should be none if not coming from tactical
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;
	local int TotalHours;

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef;
	bIncremental = true;
	bProgressesDuringFlight = true;
	bNoInterruptOnComplete = true;

	if(NewGameState != none)
	{
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	}
	else
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
	}

	
	BlocksRemaining = UnitState.GetMaxWillForMentalState(UnitState.GetMentalState()) - UnitState.GetCurrentStat(eStat_Will);

	if(UnitState.GetMentalState() != eMentalState_Ready)
	{
		BlocksRemaining++;
	}

	TotalHours = GetTotalProjectHours(UnitState);
	ProjectPointsRemaining = OriginalWorkPerHour * TotalHours;
	PointsPerBlock = Round(float(ProjectPointsRemaining) / float(BlocksRemaining));

	// Get rid of possible differences caused by rounding
	BlockPointsRemaining = PointsPerBlock;
	ProjectPointsRemaining = PointsPerBlock * BlocksRemaining;
	InitialProjectPoints = ProjectPointsRemaining;

	UpdateWorkPerHour(NewGameState);
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if(`STRATEGYRULES != none)
	{
		if(class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
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
		BlockCompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;

	History = `XCOMHISTORY;
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	// Issue #650 - added call to TriggerWillRecoveryTimeModifier
	return Round(float(OriginalWorkPerHour) * ResHQ.GetWillRecoveryRateScalar() * TriggerWillRecoveryTimeModifier(StartState, bAssumeActive));
}

// Issue #650 Start
/// HL-Docs: feature:WillRecoveryTimeModifier; issue:650; tags:strategy
/// Allows mods to apply a multiplier to the Will recovery project time, where a
/// value of 1.0 makes no change, 2.0 doubles the duration, etc. Listeners can
/// get the recovering unit from the Will project's `ProjectFocus` property.
///
/// ```event
/// EventID: WillRecoveryTimeModifier,
/// EventData: [
///   inout float TimeMultiplier,
///   in bool bAssumeActive
/// ],
/// EventSource: XComGameState_HeadquartersProjectRecoverWill (ProjectState),
/// NewGameState: maybe
/// ```
///
/// The `NewGameState` and `bAssumeActive` will be whatever caller to CalculateWorkPerHour() passes. Note that
/// both arguments are optional.
///
/// If you want to modify the `TimeMultiplier`, you **must** subscribe with `ELD_Immediate` deferral
private function float TriggerWillRecoveryTimeModifier (optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'WillRecoveryTimeModifier';
	Tuple.Data.Add(2);

	Tuple.Data[0].kind = XComLWTVFloat;
	Tuple.Data[0].f = 1.0; // Default no modifier
	Tuple.Data[1].kind = XComLWTVBool;
	Tuple.Data[1].b = bAssumeActive;

	`XEVENTMGR.TriggerEvent('WillRecoveryTimeModifier', Tuple, self, StartState);

	return Tuple.Data[0].f;
}
// Issue #650 End

//---------------------------------------------------------------------------------------
private function int GetTotalProjectHours(XComGameState_Unit UnitState)
{
	local int MinValue, MaxValue, Total, Diff;
	local float PercentToRecover, Days;
	local EMentalState eState;

	// Grab the soldier's mental state
	eState = UnitState.GetMentalState(true);

	// Calculate the percent of our current mental state that needs recovering
	MinValue = UnitState.GetMinWillForMentalState(eState);
	MaxValue = UnitState.GetMaxWillForMentalState(eState);

	Total = MaxValue - MinValue;
	Diff = UnitState.GetCurrentStat(eStat_Will) - MinValue;
	PercentToRecover = 1.0f - (float(Diff) / float(Total));

	// Apply this percent to scale between min and max days recovering
	MinValue = class'X2StrategyGameRulesetDataStructures'.default.WillRecoveryDays[eState].MinDays;
	MaxValue = class'X2StrategyGameRulesetDataStructures'.default.WillRecoveryDays[eState].MaxDays;
	Total = MaxValue - MinValue;
	Days = float(MinValue);
	Days += (PercentToRecover * float(Total));

	return Round(Days * 24.0f);
}

//---------------------------------------------------------------------------------------
// Heal the unit by one block, and check if the healing is complete
function OnBlockCompleted()
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectRecoverWill WillProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Recovered Will - 1 Block");
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));

	if(UnitState != none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		UnitState.SetCurrentStat(eStat_Will, UnitState.GetCurrentStat(eStat_Will) + 1);

		WillProject = XComGameState_HeadquartersProjectRecoverWill(NewGameState.ModifyStateObject(class' XComGameState_HeadquartersProjectRecoverWill', self.ObjectID));
		WillProject.BlocksRemaining--;

		if(WillProject.BlocksRemaining > 0)
		{
			WillProject.BlockPointsRemaining = WillProject.PointsPerBlock;
			WillProject.ProjectPointsRemaining = WillProject.BlocksRemaining * WillProject.BlockPointsRemaining;
			WillProject.UpdateWorkPerHour();
			WillProject.StartDateTime = `STRATEGYRULES.GameTime;

			if(WillProject.MakingProgress())
			{
				WillProject.SetProjectedCompletionDateTime(WillProject.StartDateTime);
			}
			else
			{
				// Set completion time to unreachable future
				WillProject.CompletionDateTime.m_iYear = 9999;
				WillProject.BlockCompletionDateTime.m_iYear = 9999;
			}
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
// Remove the project and the engineer from the room's repair slot
function OnProjectCompleted()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local array<StrategyCostScalar> CostScalars;
	local EMentalState StartingState;
	
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Recover Will Project Completed");

	// Remove the project
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.Projects.RemoveItem(self.GetReference());

	// Set soldier will to max
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ProjectFocus.ObjectID));
	StartingState = UnitState.GetMentalState(true);
	UnitState.SetCurrentStat(eStat_Will, UnitState.GetMaxStat(eStat_Will));
	UnitState.UpdateMentalState();
	
	// Check if soldier is boosted and no longer needs the boost
	if(UnitState.bRecoveryBoosted && !UnitState.IsInjured())
	{
		UnitState.UnBoostSoldier(true);

		// HQ refund cost of boosting
		CostScalars.Length = 0;
		XComHQ.RefundStrategyCost(NewGameState, class'X2StrategyElement_XpackFacilities'.default.BoostSoldierCost, CostScalars);
	}

	NewGameState.RemoveStateObject(self.ObjectID);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if(StartingState == eMentalState_Shaken)
	{
		`HQPRES.Notify(Repl(ProjectCompleteNotification, "%UNIT", UnitState.GetName(eNameType_RankFull)), class'UIUtilities_Image'.const.EventQueue_Staff);
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	OriginalWorkPerHour=10
}