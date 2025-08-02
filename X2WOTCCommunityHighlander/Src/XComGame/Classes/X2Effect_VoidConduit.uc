//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Effect_VoidConduit.uc    
//  AUTHOR:  Joshua Bouscher
//	DATE:    2/1/2017
//  PURPOSE: Applied with each tick of the persistent effect.
//			 Deals damage to the target and returns that amount as HP to the caster.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Effect_VoidConduit extends X2Effect;

var int DamagePerAction;
var float HealthReturnMod;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit, SourceUnit;
	local int StartingHP, DamagedHP, DifferenceHP, i;
	local UnitValue ConduitValue;
	local int ActionsToTick, ActionsLeft;
	local DamageResult DmgResult;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	
	TargetUnit.GetUnitValue(class'X2Effect_PersistentVoidConduit'.default.VoidConduitActionsLeft, ConduitValue);
	if (ConduitValue.fValue > 0)
	{
		//	make an assumption here that the unit would otherwise have the full amount of actions this turn
		//	this effect should pre-empt other similar effects, so hopefully this is "safe" but I guess we'll find out.
		ActionsToTick = TargetUnit.GetMyTemplate().bCanTickEffectsEveryAction ? 1 : class'X2CharacterTemplateManager'.default.StandardActionsPerTurn;
		if (ActionsToTick > ConduitValue.fValue)
			ActionsToTick = ConduitValue.fValue;
		ActionsLeft = ConduitValue.fValue - ActionsToTick;

		TargetUnit.SetUnitFloatValue(class'X2Effect_PersistentVoidConduit'.default.StolenActionsThisTick, ActionsToTick, eCleanup_BeginTurn);
		TargetUnit.SetUnitFloatValue(class'X2Effect_PersistentVoidConduit'.default.VoidConduitActionsLeft, ActionsLeft, eCleanup_BeginTactical);
	}
	else
	{
		TargetUnit.ClearUnitValue(class'X2Effect_PersistentVoidConduit'.default.StolenActionsThisTick);
		TargetUnit.ClearUnitValue(class'X2Effect_PersistentVoidConduit'.default.VoidConduitActionsLeft);
		return;
	}

	if (ActionsToTick > 0)
	{
		SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		if (SourceUnit == none)
		{
			SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		}

		`assert(SourceUnit != none && TargetUnit != none);

		for (i = 0; i < ActionsToTick; ++i)
		{
			StartingHP = TargetUnit.GetCurrentStat(eStat_HP);
			TargetUnit.TakeEffectDamage(self, DamagePerAction, 0, 0, ApplyEffectParameters, NewGameState);
			DamagedHP = TargetUnit.GetCurrentStat(eStat_HP);
			DifferenceHP = StartingHP - DamagedHP;
			DifferenceHP *= HealthReturnMod;
			if (DifferenceHP > 0)
			{
				SourceUnit.ModifyCurrentStat(eStat_HP, DifferenceHP);
			}
			if (i > 0)
			{
				//	kind of gnarly but this should get the visualization correct
				//	store the damage info for what just happened
				DmgResult = TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1];
				//	take it off the unit
				TargetUnit.DamageResults.Remove(TargetUnit.DamageResults.Length - 1, 1);
				//	add it back on to the previous damage result (the first tick of damage)
				TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1].Shred += DmgResult.Shred;
				TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1].DamageAmount += DmgResult.DamageAmount;
				TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1].MitigationAmount += DmgResult.MitigationAmount;
				TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1].ShieldHP += DmgResult.ShieldHP;
			}
		}
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
	local X2Action_ApplyWeaponDamageToUnit UnitAction;
	local XComGameStateContext Context;
	local X2Action ParentAction;
	local X2Action_PlayEffect EffectAction;
	local XComGameStateVisualizationMgr VisMgr;
	local Array<X2Action> SourceNodes;
	local XGUnit SourceUnit;
	local VisualizationActionMetadata SourceMetadata;
	local XComGameStateHistory History;
	local Array<X2Action> ParentActions;
	local X2Action_Death DeathAction;
	local X2Action_PersistentEffect PersistentAction;
	local X2Action_PlaySoundAndFlyOver HealedFlyover;
	local int HealedAmount;
	local string HealedMsg;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	SourceUnit = XGUnit(`XCOMHISTORY.GetVisualizer(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action', SourceNodes, SourceUnit);
	if( SourceNodes.Length > 0 )
	{
		SourceMetadata = SourceNodes[0].Metadata;
	}
	else
	{
		SourceMetadata.StateObjectRef.ObjectID = SourceUnit.ObjectID;
		SourceMetadata.VisualizeActor = SourceUnit;
		SourceMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		SourceMetadata.StateObject_NewState = History.GetGameStateForObjectID(SourceUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	}

	if (ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		Context = VisualizeGameState.GetContext();
		ParentAction = ActionMetadata.LastActionAdded;
		
		// Jwats: If Death happened then we need to move the death/persistent effect to after our visualization
		DeathAction = X2Action_Death(ParentAction);
		if( DeathAction != None && DeathAction.ParentActions.Length != 0 )
		{
			PersistentAction = X2Action_PersistentEffect(DeathAction.ParentActions[0]);
			if( PersistentAction != None )
			{
				ParentAction = PersistentAction;
			}

			DeathAction.bForceMeleeDeath = true;
		}

		// Jwats: If ParentAction is none (or death) we don't want them to auto parent to each other
		//			so create a join so they all start at the same time
		if( ParentAction == None || DeathAction != None )
		{
			ParentActions = ParentAction != None ? ParentAction.ParentActions : None;
			ParentAction = class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, true, None, ParentActions);
			X2Action_MarkerNamed(ParentAction).SetName("Join");
			ParentActions.Length = 0;
		}

		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain_Tether";
		EffectAction.AttachToSocketName = 'Root';
		EffectAction.TetherToSocketName = 'Root';
		EffectAction.TetherToUnit = SourceUnit;
		EffectAction.bWaitForCompletion = true;
		ParentActions.AddItem(EffectAction);

		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain";
		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'FX_Chest';
		EffectAction.AttachToSocketsArrayName = 'BoneSocketActor';
		EffectAction.bWaitForCompletion = true;
		ParentActions.AddItem(EffectAction);

		UnitAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		UnitAction.OriginatingEffect = self;
		ParentActions.AddItem(UnitAction);

		// Jwats: Now Play an effect on the source
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(SourceMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain_Templar";
		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'FX_Chest';
		EffectAction.AttachToSocketsArrayName = 'BoneSocketActor';
		EffectAction.bWaitForCompletion = true;
		ParentActions.AddItem(EffectAction);

		//	Show flyover for healed HP
		HealedAmount = XComGameState_Unit(SourceMetadata.StateObject_NewState).GetCurrentStat(eStat_HP) - XComGameState_Unit(SourceMetadata.StateObject_OldState).GetCurrentStat(eStat_HP);
		if (HealedAmount > 0)
		{
			HealedMsg = Repl(class'X2Effect_SoulSteal'.default.HealedMessage, "<Heal/>", HealedAmount);
			HealedFlyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(SourceMetadata, Context, false, ParentAction));
			HealedFlyover.SetSoundAndFlyOverParameters(none, HealedMsg, '', eColor_Good, , , true);		
			ParentActions.AddItem(HealedFlyover);
		}

		if( PersistentAction != None )
		{
			// Jwats: Death is now moved and is a single action to end with
			VisMgr.DisconnectAction(PersistentAction);
			VisMgr.ConnectAction(PersistentAction, VisMgr.BuildVisTree, false, None, ParentActions);
		}
		else if( DeathAction != None )
		{
			// Jwats: Death is now moved and is a single action to end with
			VisMgr.DisconnectAction(DeathAction);
			VisMgr.ConnectAction(DeathAction, VisMgr.BuildVisTree, false, None, ParentActions);
		}
		else
		{
			// Jwats: Make sure we end with a single action so nothing interupts
			ParentAction = class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, None, ParentActions);
			X2Action_MarkerNamed(ParentAction).SetName("Join");
		}
	}
}

DefaultProperties
{
	DamageTypes(0) = "Psi"
}