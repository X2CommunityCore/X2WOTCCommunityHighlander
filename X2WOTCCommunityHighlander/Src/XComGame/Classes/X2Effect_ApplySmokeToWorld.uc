//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ApplySmokeToWorld.uc
//  AUTHOR:  Ryan McFall
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ApplySmokeToWorld extends X2Effect_World config(GameData);

var config string SmokeParticleSystemFill_Name;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
}

event array<ParticleSystem> GetParticleSystem_Fill()
{
	local array<ParticleSystem> ParticleSystems;
	ParticleSystems.AddItem(none);
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(SmokeParticleSystemFill_Name, class'ParticleSystem')));
	return ParticleSystems;
}

static simulated function int GetTileDataDynamicFlagValue() { return 8; }  //TileDataContainsSmoke

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_UpdateWorldEffects_Smoke AddSmokeAction;
	if( ActionMetadata.StateObject_NewState.IsA('XComGameState_WorldEffectTileData') )
	{
		AddSmokeAction = X2Action_UpdateWorldEffects_Smoke(class'X2Action_UpdateWorldEffects_Smoke'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		AddSmokeAction.SetParticleSystems(GetParticleSystem_Fill());
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
}

static simulated function bool FillRequiresLOSToTargetLocation( ) { return !class'CHHelpers'.default.DisableExtraLOSCheckForSmoke; /* Issue #669 */ }
