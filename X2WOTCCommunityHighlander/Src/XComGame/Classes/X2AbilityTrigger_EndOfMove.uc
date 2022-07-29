//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTrigger_EndOfMove.uc
//  AUTHOR:  DavidBurchanowski  --  9/3/2015
//  PURPOSE: Sentinal object to indicate that a given ability can be activated from the pathing pawn melee UI
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2AbilityTrigger_EndOfMove extends X2AbilityTrigger;

static function bool AbilityHasEndOfMoveTrigger(X2AbilityTemplate Template)
{
	local X2AbilityTrigger Trigger;

	if (Template == none)
		return false;

	foreach Template.AbilityTriggers(Trigger)
	{
		if(X2AbilityTrigger_EndOfMove(Trigger) != none)
		{
			return true;
		}
	}

	return false;
}

static function XComGameState_Ability GetAvailableEndOfMoveAbilityForUnit(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local GameRulesCache_Unit UnitCache;
	local XComGameState_Ability AbilityState;
	local int ActionIndex;

	if(`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))
	{
		History = `XCOMHISTORY;
		for(ActionIndex = 0; ActionIndex < UnitCache.AvailableActions.Length; ActionIndex++)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitCache.AvailableActions[ActionIndex].AbilityObjectRef.ObjectID));
			if(AbilityState != none && AbilityHasEndOfMoveTrigger(AbilityState.GetMyTemplate()))
			{
				return AbilityState;
			}
		}
	}

	return None;
}