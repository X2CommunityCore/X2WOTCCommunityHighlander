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

// Begin Issue #1138
/// HL-Docs: feature:PrioritizeRightClickMelee; issue:1138; tags:tactical
/// This feature allows mods to override the logic for selecting the ability
/// that should be used when the player triggers a right-click melee action on a target.
///
/// ## How to use
///
/// Implement the following code in your mod's class that `extends X2DownloadableContentInfo`:
/// ```unrealscript
/// static event OnPostTemplatesCreated()
/// {
/// 	local CHHelpers CHHelpersObj;
/// 
/// 	CHHelpersObj = class'CHHelpers'.static.GetCDO();
/// 	if (CHHelpersObj != none)
/// 	{
/// 		CHHelpersObj.AddPrioritizeRightClickMeleeCallback(PrioritizeRightClickMelee);
/// 	}
/// }
///
/// // To avoid crashes associated with garbage collection failure when transitioning between Tactical and Strategy,
/// // this function must be bound to the ClassDefaultObject of your class. Having this function in a class that 
/// // `extends X2DownloadableContentInfo` is the easiest way to ensure that.
/// static private function EHLDelegateReturn PrioritizeRightClickMelee(XComGameState_Unit UnitState, out XComGameState_Ability PrioritizedMeleeAbility, optional XComGameState_BaseObject TargetObject)
/// {
//      // 'PrioritizedMeleeAbility' will store the ability selected by the game's default logic.
///     // Replace it with a different ability if needed.
///
///     // Important! `TargetObject` can be `none`, if other mods call the original `GetAvailableEndOfMoveAbilityForUnit()`
///     // instead of `GetAvailableEndOfMoveAbilityForUnit_CH()` or do not pass a target object to it.
///
///     // Return EHLDR_NoInterrupt if you want to allow other delegates to run after yours
///     // and potentially set a different PrioritizedMeleeAbility (recommended).
///     // Return EHLDR_InterruptDelegates if you want your decision to be final.
///     return EHLDR_NoInterrupt;
///}
/// ```
static function XComGameState_Ability GetAvailableEndOfMoveAbilityForUnit(XComGameState_Unit UnitState)
{
	return GetAvailableEndOfMoveAbilityForUnit_Internal(UnitState);
}

// Issue #1138 - new version of the GetAvailableEndOfMoveAbilityForUnit() that takes TargetObject as an argument.
static final function XComGameState_Ability GetAvailableEndOfMoveAbilityForUnit_CH(XComGameState_Unit UnitState, optional XComGameState_BaseObject TargetObject)
{
	return GetAvailableEndOfMoveAbilityForUnit_Internal(UnitState, TargetObject);
}

// Issue #1138 - original implementation of GetAvailableEndOfMoveAbilityForUnit with support for the delegate and optional TargetObject
// Responsible for finding the ability that should be activated by right-clicking a target.
static private final function XComGameState_Ability GetAvailableEndOfMoveAbilityForUnit_Internal(XComGameState_Unit UnitState, optional XComGameState_BaseObject TargetObject)
{
	local XComGameStateHistory  History;
	local GameRulesCache_Unit   UnitCache;
	local XComGameState_Ability AbilityState;
	local AvailableAction       AvAction;

	// Variables for Issue #1138
	local CHHelpers             CHHelpersObj;
	local XComGameState_Ability PrioritizedMeleeAbility;

	// Otherwise use the original logic for selecting the ability
	if (`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))
	{
		History = `XCOMHISTORY;

		// Issue #1138 - optimization: replaced for() with faster foreach()
		foreach UnitCache.AvailableActions(AvAction)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AvAction.AbilityObjectRef.ObjectID));
			if (AbilityState != none && AbilityHasEndOfMoveTrigger(AbilityState.GetMyTemplate()))
			{
				PrioritizedMeleeAbility = AbilityState;
				break;
			}
		}
	}

	// Issue #1138 - Trigger the override
	CHHelpersObj = class'CHHelpers'.static.GetCDO();
	CHHelpersObj.TriggerPrioritizeRightClickMelee(UnitState, PrioritizedMeleeAbility, TargetObject);

	return PrioritizedMeleeAbility;
}
// End Issue #1138
