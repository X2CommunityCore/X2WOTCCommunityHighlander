//---------------------------------------------------------------------------------------
//  FILE:    X2ChosenActionTemplate.uc
//  AUTHOR:  Mark Nauta - 1/19/2017
//  PURPOSE: Define Chosen Monthly Actions
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChosenActionTemplate extends X2StrategyCardTemplate config(GameData);

// Requirements for choosing
var config int MaxPerMonth; // How many Chosen can take this action each month (if 0, no limit)
var config int IndividualCooldown; // How many months before the same Chosen can perform this action again (0 = can perform next month)
var config int GlobalCooldown; // How many months before any Chosen can perform this action again (0 = can perform next month)
var config int MinForceLevel; // Force Level gate on activation
var config int MinXComKnowledge; // XCom knowledge gate on activation
var config bool bCanPerformIfUnmet; // True if Unmet Chosen can perform this action

// Choice priority
var config int ActionPriority; // Higher number means higher priority

// Specifications for activating
var config MinMaxDays ActivationTime; // Min/Max amount of time for action to be performed (should be under 21 days)
var config bool bPauseGeoscapeBeforeActivation; // Does the Geoscape need to be paused before this action is activated
var config bool bPerformImmediately; // Does this action activate immediately upon choosing
var config bool bPerformAtMonthEnd; // Does this action activate at the end of the current resistance month
var config int MinKnowledgeGain; // Min value of knowledge gain upon activation
var config int MaxKnowledgeGain; // Max value of knowledge gain upon activation

// Delegate functions
var Delegate<OnChooseActionDelegate> OnChooseActionFn; // Called when the action is chosen
var Delegate<PostActionPerformedDelegate> PostActionPerformedFn; // Called immediately after the action is performed (after gamestate submission)
var Delegate<GetActionPriorityDelegate> GetActionPriorityFn; // Called when ordering the actions by priority

delegate OnChooseActionDelegate(XComGameState NewGameState, XComGameState_ChosenAction ActionState);
delegate PostActionPerformedDelegate(StateObjectReference InRef);
delegate int GetActionPriorityDelegate();

//---------------------------------------------------------------------------------------
function bool CanPerformAction(XComGameState_AdventChosen ChosenState, array<XComGameState_AdventChosen> AllChosen, array<name> UsedActions, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_AdventChosen Chosen;
	local int MonthUses, ICooldown, GCooldown;
	local name ActionName;

	// Check for met XCom req
	if(!bCanPerformIfUnmet && !ChosenState.bMetXCom)
	{
		return false;
	}

	// Check for uses this month req (Unmet don't obey this)
	if(ChosenState.bMetXCom)
	{
		if(MaxPerMonth > 0)
		{
			MonthUses = 0;
			foreach UsedActions(ActionName)
			{
				if(ActionName == DataName)
				{
					MonthUses++;
				}
			}

			if(MonthUses >= MaxPerMonth)
			{
				return false;
			}
		}
	}

	// Check for knowledge req
	if(ChosenState.GetKnowledgeLevel() < MinXComKnowledge)
	{
		return false;
	}

	// Check for force level req
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(AlienHQ.GetForceLevel() < MinForceLevel)
	{
		return false;
	}

	// Check for individual cooldown req
	ICooldown = ChosenState.GetMonthsSinceAction(DataName);

	if(ICooldown > 0 && ICooldown <= IndividualCooldown)
	{
		return false;
	}

	// Check for global cooldown req
	GCooldown = 0;

	foreach AllChosen(Chosen)
	{
		ICooldown = ChosenState.GetMonthsSinceAction(DataName);

		if(ICooldown > 0 && (ICooldown < GCooldown || GCooldown <= 0))
		{
			GCooldown = ICooldown;
		}
	}

	if(GCooldown > 0 && GCooldown <= GlobalCooldown)
	{
		return false;
	}

	// Check for custom reqs
	if(CanBePlayedFn != none)
	{
		return CanBePlayedFn(ChosenState.GetReference(), NewGameState);
	}

	return true;
}

//---------------------------------------------------------------------------------------
function int GetActionPriority()
{
	if(GetActionPriorityFn != none)
	{
		return GetActionPriorityFn();
	}

	return ActionPriority;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}