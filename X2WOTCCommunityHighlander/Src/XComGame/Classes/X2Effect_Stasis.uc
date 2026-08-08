class X2Effect_Stasis extends X2Effect_Persistent
	config(GameData_SoldierSkills);

var localized string StasisFlyover, StasisRemoved, StasisRemovedText;
var name StunStartAnim, StunStopAnim;
var bool bSkipFlyover;
var float StartAnimBlendTime;

var config array<name> STASIS_REMOVE_EFFECTS_SOURCE, STASIS_REMOVE_EFFECTS_TARGET;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	TargetUnit.bInStasis = true;
	TargetUnit.ActionPoints.Length = 0;
	TargetUnit.ReserveActionPoints.Length = 0;

	`XEVENTMGR.TriggerEvent('AffectedByStasis', kNewTargetState, kNewTargetState);

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		`assert(TargetUnit != none);
		TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));
	}
	
	TargetUnit.bInStasis = false;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}

function UnitEndedTacticalPlay(XComGameState_Effect EffectState, XComGameState_Unit UnitState)
{
	UnitState.bInStasis = false;
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	//  no actions allowed while in stasis
	ActionPoints.Length = 0;
}

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	return true;
}

function bool CanAbilityHitUnit(name AbilityName) 
{
	return false;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	// Empty because we will be adding all this at the end with ModifyTracksVisualization
}

simulated function ModifyTracksVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ModifyTrack, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_PlayAnimation PlayAnimation;

	if (EffectApplyResult == 'AA_Success' && ModifyTrack.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		if (!bSkipFlyover)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ModifyTrack, VisualizeGameState.GetContext()));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.StasisFlyover, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Stunned, 1.0, true);
		}

		if( XComGameState_Unit(ModifyTrack.StateObject_NewState).IsTurret() )
		{
			class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTree(ModifyTrack, VisualizeGameState.GetContext());
		}
		else
		{
			// Not a turret
			// Play the start stun animation
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ModifyTrack, VisualizeGameState.GetContext()));
			PlayAnimation.Params.AnimName = StunStartAnim;
			PlayAnimation.Params.BlendTime = StartAnimBlendTime;
		}
		class'X2StatusEffects'.static.UpdateUnitFlag(ModifyTrack, VisualizeGameState.GetContext());

		super.AddX2ActionsForVisualization(VisualizeGameState, ModifyTrack, EffectApplyResult);
	}
}

simulated function AddX2ActionsForVisualization_Sync( XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
{
	//We assume 'AA_Success', because otherwise the effect wouldn't be here (on load) to get sync'd
	ModifyTracksVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlayAnimation PlayAnimation;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);

	if (XComGameState_Unit(ActionMetadata.StateObject_NewState) != none)
	{
		if( XComGameState_Unit(ActionMetadata.StateObject_NewState).IsTurret() )
		{
			class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		}
		else
		{
			// The unit is not a turret
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			PlayAnimation.Params.AnimName = StunStopAnim;
		}
		class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());

		class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.StasisRemoved, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Stunned, 2.0f);
		class'X2StatusEffects'.static.AddEffectMessageToTrack(
			ActionMetadata,
			default.StasisRemovedText,
			VisualizeGameState.GetContext(),
			class'UIEventNoticesTactical'.default.StasisTitle,
			"img:///UILibrary_PerkIcons.UIPerk_stasis",
			eUIState_Good);
	}
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventMan;
	local Object EffectObj;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	EventMan = `XEVENTMGR;

	EffectObj = EffectGameState;
	EventMan.RegisterForEvent(EffectObj, 'AffectedByStasis', class'XComGameState_Effect'.static.AffectedByStasis_Listener, ELD_OnStateSubmitted, , UnitState);
}

DefaultProperties
{
	EffectName = "Stasis"
	DuplicateResponse = eDupe_Refresh
	CustomIdleOverrideAnim="HL_StunnedIdle"
	StunStartAnim="HL_StunnedStart"
	StunStopAnim="HL_StunnedStop"
	ModifyTracksFn=ModifyTracksVisualization
	EffectHierarchyValue=950
	StartAnimBlendTime=0.1f
}