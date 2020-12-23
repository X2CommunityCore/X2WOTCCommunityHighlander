//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ApplyPoisonToWorld.uc
//  AUTHOR:  Ryan McFall
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ApplyPoisonToWorld extends X2Effect_World 
	config(GameData) 
	native(Core);

var config string PoisonParticleSystemFill_Name;
var config int Duration;

// Called from native code to get a list of effects to apply, as well as by the effect system based on EffectRefs
event array<X2Effect> GetTileEnteredEffects()
{
	local array<X2Effect> TileEnteredEffectsUncached;

	TileEnteredEffectsUncached.AddItem(class'X2StatusEffects'.static.CreatePoisonedStatusEffect());

	return TileEnteredEffectsUncached;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
}

event array<ParticleSystem> GetParticleSystem_Fill()
{
	local array<ParticleSystem> ParticleSystems;
	ParticleSystems.AddItem( none );
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(PoisonParticleSystemFill_Name, class'ParticleSystem')));
	return ParticleSystems;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_UpdateWorldEffects_Poison AddPoisonAction;
	if( ActionMetadata.StateObject_NewState.IsA('XComGameState_WorldEffectTileData') )
	{
		AddPoisonAction = X2Action_UpdateWorldEffects_Poison(class'X2Action_UpdateWorldEffects_Poison'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		AddPoisonAction.bCenterTile = bCenterTile;
		AddPoisonAction.SetParticleSystems(GetParticleSystem_Fill());
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
}

static simulated function bool FillRequiresLOSToTargetLocation( ) { return !class'CHHelpers'.default.DisableExtraLOSCheckForPoison; /* Issue #669 */ }
static simulated function int GetTileDataDynamicFlagValue() { return 16; }  //TileDataContainsPoison

static simulated event AddEffectToTiles(Name EffectName, X2Effect_World Effect, XComGameState NewGameState, array<TilePosPair> Tiles, vector TargetLocation, float Radius, float Coverage, optional XComGameState_Unit SourceStateObject = none, optional XComGameState_Item SourceWeaponState = none, optional bool bUseFireChance)
{
	local XComGameState_WorldEffectTileData GameplayTileUpdate;
	local array<TileIsland> TileIslands;
	local array<TileParticleInfo> TileParticleInfos;
	local VolumeEffectTileData InitialTileData;

	GameplayTileUpdate = XComGameState_WorldEffectTileData(NewGameState.CreateNewStateObject(class'XComGameState_WorldEffectTileData'));
	GameplayTileUpdate.WorldEffectClassName = EffectName;

	InitialTileData.EffectName = EffectName;
	InitialTileData.NumTurns = GetTileDataNumTurns();
	InitialTileData.DynamicFlagUpdateValue = GetTileDataDynamicFlagValue();
	if( SourceStateObject != none )
		InitialTileData.SourceStateObjectID = SourceStateObject.ObjectID;
	if( SourceWeaponState != none )
		InitialTileData.ItemStateObjectID = SourceWeaponState.ObjectID;

	FilterForLOS( Tiles, TargetLocation, Radius );

	TileIslands = CollapseTilesToPools(Tiles);
	DetermineFireBlocks(TileIslands, Tiles, TileParticleInfos);

	GameplayTileUpdate.SetInitialTileData(Tiles, InitialTileData, TileParticleInfos);

	`XEVENTMGR.TriggerEvent('GameplayTileEffectUpdate', GameplayTileUpdate, SourceStateObject, NewGameState);
}

static simulated function int GetTileDataNumTurns() 
{ 
	return default.Duration; 
}

defaultproperties
{
	bCenterTile = false;
	DamageTypes.Add("Poison");
}
