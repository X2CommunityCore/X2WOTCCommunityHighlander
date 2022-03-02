//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTrigger_EndOfMove.uc
//  AUTHOR:  DavidBurchanowski  --  9/3/2015
//  PURPOSE: Sentinal object to indicate that a given ability can be activated from the pathing pawn melee UI
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2AbilityTrigger_EndOfMove extends X2AbilityTrigger;

// Properties for Issue #1138.
// Adds priority weighting identical to Shot HUD Priority so that the left-most HUD melee
// ability can be picked up and prioritized for use. 

// 0 is the highest priority as that corresponds to the left-most slot in the Shot HUD.

// Each priority bucket is base 100_000 so that when Shot HUD priority is included it should not push into the next bucket
const HIGH_PRIORITY_MELEE		= 100000;
const STANDARD_PRIORITY_MELEE	= 200000;
const LOW_PRIORITY_MELEE		= 300000;

// Custom priorities can be set manually using RightClickMeleePriority;
var int RightClickMeleePriority;

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

// Start Issue #1138
/// HL-Docs: feature:GetAvailableEndOfMoveAbilityForUnit; issue:1138; tags:ui,tactical
/// By default the game was using a greedy algorithm for selecting which melee
/// skill to use when the user right-clicks on the mouse to do a dash-melee attack
/// on an enemy unit. This upgrades the logic for that selection process to now
/// prioritize all melee skills based upon the Ability Template's Shot HUD Priority.
///
/// Custom prioritization can also be granted by modifying `RightClickMeleePriority` when
/// using `Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_EndOfMove');`
/// to enable an ability to be a dashing melee ability.
///
/// ```unrealscript
/// local X2AbilityTrigger_EndOfMove EndOfMoveTrigger;
///
/// EndOfMoveTrigger = new class'X2AbilityTrigger_EndOfMove';
/// EndOfMoveTrigger.RightClickMeleePriority = <<CUSTOM INT VALUE>>;
///
/// Template.AbilityTriggers.AddItem(EndOfMoveTrigger);
/// ```
static function XComGameState_Ability GetAvailableEndOfMoveAbilityForUnit(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local GameRulesCache_Unit UnitCache;
	local XComGameState_Ability AbilityState;
	// local int ActionIndex;

	// Variables for Issue #1138;
	local AvailableAction Action;
	local XComGameState_Ability PriorityAbility;
	local X2AbilityTrigger_EndOfMove EndOfMoveTrigger;
	local int CurrentPriority, AbilityPriority;

	if(`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))
	{
		History = `XCOMHISTORY;
		foreach UnitCache.AvailableActions(Action)
		{
			// Is the action even available?
			if(Action.AvailableCode != 'AA_Success')
			{
				continue;
			}

			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
			// Unknown ability, so move on
			if(AbilityState == none)
			{
				continue;
			}

			EndOfMoveTrigger = GetPriorityEndOfMoveTrigger(AbilityState.GetMyTemplate());
			// Not right-click enabled, so move on
			if(EndOfMoveTrigger == none)
			{
				continue;
			}

			// Calculate priority
			// If default value then use STANDARD_PRIORITY_MELEE, otherwise grab its priority
			AbilityPriority = EndOfMoveTrigger.RightClickMeleePriority >= 0 ? EndOfMoveTrigger.RightClickMeleePriority : const.STANDARD_PRIORITY_MELEE;
			
			// Apply the shot HUD's priority weight
			AbilityPriority += Action.ShotHUDPriority;

			// If this is the first melee ability, or it is higher priority, take it
			if(PriorityAbility == none || AbilityPriority < CurrentPriority)
			{
				PriorityAbility = AbilityState;
				CurrentPriority = AbilityPriority;
			}
		}
	}

	return PriorityAbility;
}

static private function X2AbilityTrigger_EndOfMove GetPriorityEndOfMoveTrigger(X2AbilityTemplate Template)
{
	local X2AbilityTrigger Trigger;
	local X2AbilityTrigger_EndOfMove EndOfMoveTrigger, PriorityEndOfMoveTrigger;
	local int TriggerPriority, CurrentPriority;

	if (Template == none)
		return none;
		
	// If there are multiple sentinels, find the one with the best priority.
	// Makes patching melee abilities with mods easier.
	foreach Template.AbilityTriggers(Trigger)
	{
		EndOfMoveTrigger = X2AbilityTrigger_EndOfMove(Trigger);
		if(EndOfMoveTrigger != none)
		{
			// If default value then use STANDARD_PRIORITY_MELEE, otherwise grab its priority
			TriggerPriority = EndOfMoveTrigger.RightClickMeleePriority >= 0 ? EndOfMoveTrigger.RightClickMeleePriority : const.STANDARD_PRIORITY_MELEE;
			if(PriorityEndOfMoveTrigger == none || PriorityEndOfMoveTrigger.RightClickMeleePriority < 0 || TriggerPriority < CurrentPriority)
			{
				PriorityEndOfMoveTrigger = EndOfMoveTrigger;
				CurrentPriority = TriggerPriority;
			}
		}
	}

	return PriorityEndOfMoveTrigger;
}

defaultproperties
{
	RightClickMeleePriority=-1
}
// End Issue #1138
