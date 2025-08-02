//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Effect_PersistentVoidConduit.uc    
//  AUTHOR:  Joshua Bouscher
//	DATE:    2/1/2017
//  PURPOSE: Persistent effect for the target of Void Conduit,
//			 keeps the unit impaired, restricts action points, etc.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Effect_PersistentVoidConduit extends X2Effect_Persistent native(Core);

var int InitialDamage;
var privatewrite name VoidConduitActionsLeft, StolenActionsThisTick;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit, SourceUnit;
	local int Focus;

	TargetUnit = XComGameState_Unit(kNewTargetState);

	TargetUnit.TakeEffectDamage(self, InitialDamage, 0, 0, ApplyEffectParameters, NewGameState);

	//	get the previous version of the source unit to record the correct focus level
	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID, , NewGameState.HistoryIndex - 1));
	`assert(SourceUnit != none);	
	Focus = SourceUnit.GetTemplarFocusLevel();
	TargetUnit.SetUnitFloatValue(VoidConduitActionsLeft, Focus, eCleanup_BeginTactical);
	TargetUnit.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 1);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( TargetUnit != None )
	{
		TargetUnit.ClearUnitValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName);
	}
}

function bool TickVoidConduit(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit TargetUnit;
	local UnitValue ConduitValue;

	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	`assert(TargetUnit != none);

	TargetUnit.GetUnitValue(VoidConduitActionsLeft, ConduitValue);
	return ConduitValue.fValue <= 0;
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	local UnitValue ActionsValue;
	local int Limit;

	UnitState.GetUnitValue(StolenActionsThisTick, ActionsValue);
	Limit = ActionsValue.fValue;

	if (Limit > ActionPoints.Length)
	{
		`RedScreen("PersistentVoidConduit thought it restricted" @ Limit @ "actions, but the unit only has" @ ActionPoints.Length @ "this turn -- oops. @gameplay @jbouscher");
		ActionPoints.Length = 0;
	}
	else
	{
		ActionPoints.Remove(0, Limit);
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_PlayAnimation PlayAnimation;
	local X2Action_ApplyWeaponDamageToUnit DamageAction;
	local XGUnit Unit;
	local XComUnitPawn UnitPawn;

	if( EffectApplyResult == 'AA_Success' )
	{
		Unit = XGUnit(ActionMetadata.VisualizeActor);
		if( Unit != None )
		{
			UnitPawn = Unit.GetPawn();
			if( UnitPawn != None && UnitPawn.GetAnimTreeController().CanPlayAnimation('HL_VoidConduitTarget_Start') )
			{
				// Play the start stun animation
				PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
				PlayAnimation.Params.AnimName = 'HL_VoidConduitTarget_Start';
				PlayAnimation.bResetWeaponsToDefaultSockets = true;
			}
		}

		super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);

		DamageAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		DamageAction.OriginatingEffect = self;
	}
	else
	{
		super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
	}
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	//We assume 'AA_Success', because otherwise the effect wouldn't be here (on load) to get sync'd
	AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');
}

simulated private function AddX2ActionsForVisualization_Removed_Internal(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlayAnimation PlayAnimation;
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if( TargetUnit.IsAlive() && !TargetUnit.IsIncapacitated() ) //Don't play the animation if the unit is going straight to killed
	{
		// The unit is not a turret and is not dead/unconscious/bleeding-out
		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		PlayAnimation.Params.AnimName = 'HL_VoidConduitTarget_End';
	}
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);

	AddX2ActionsForVisualization_Removed_Internal(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

function bool AllowDodge(XComGameState_Unit Attacker, XComGameState_Ability AbilityState) { return false; }

DefaultProperties
{
	EffectName = "VoidConduit"
	DuplicateResponse = eDupe_Ignore
	bIsImpairing = true
	VoidConduitActionsLeft = "VoidConduitActionsLeft"
	StolenActionsThisTick = "StolenActionsThisTick"
	EffectTickedFn = TickVoidConduit
	DamageTypes(0) = "Psi"
	bCanTickEveryAction = true
	CustomIdleOverrideAnim = "HL_VoidConduitTarget_Loop"
}