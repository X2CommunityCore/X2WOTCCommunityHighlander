//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Knockback.uc
//  AUTHOR:  Ryan McFall  --  5/5/2015
//  PURPOSE: This effect implements a game mechanic that moves units based on incoming 
//			 damage or attacks. This is done with a rag doll similar to what was done with
//			 kinetic strike in EW.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_Knockback extends X2Effect config(GameCore);

struct KnockbackDistanceOverride
{
	var name OverrideReason;
	var int NewKnockbackDistance_Meters;
};

/** Distance that the target will be thrown backwards, in meters */
var() int KnockbackDistance;

/** Used to step the knockback forward along the movement vector until either knock back distance is reached, or there are no more valid tiles*/
var() private float IncrementalStepSize;

/** If true, the knocked back unit will cause non fragile destruction ( like kinetic strike ) */
var() bool bKnockbackDestroysNonFragile;

/** Distance that the target will be thrown backwards, in meters */
var() float OverrideRagdollFinishTimerSec;

/** Knockback effects can happen on every attack or only killing attacks */
var() bool OnlyOnDeath;

var config	float DefaultDamage;
var config	float DefaultRadius;
var config  array<KnockbackDistanceOverride> KnockbackDistanceOverrides;

function name WasTargetPreviouslyDead(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	// A unit that was dead before this game state should not get a knockback, they are already a corpse
	local name AvailableCode;
	local XComGameState_Unit TestUnitState;
	local XComGameStateHistory History;

	AvailableCode = 'AA_Success';

	History = `XCOMHISTORY;

	TestUnitState = XComGameState_Unit(History.GetGameStateForObjectID(kNewTargetState.ObjectID));
	if( (TestUnitState != none) && TestUnitState.IsDead() )
	{
		return 'AA_UnitIsDead';
	}

	if( OnlyOnDeath )
	{
		TestUnitState = XComGameState_Unit(kNewTargetState);
		if( TestUnitState != None && (TestUnitState.IsAlive() || TestUnitState.IsIncapacitated()) )
		{
			return 'AA_UnitIsAlive';
		}
	}

	return AvailableCode;
}

private function bool CanBeDestroyed(XComInteractiveLevelActor InteractiveActor, float DamageAmount)
{
	//make sure the knockback damage can destroy this actor.
	//check the number of interaction points to prevent larger objects from being destroyed.
	return InteractiveActor != none && DamageAmount >= InteractiveActor.Health && InteractiveActor.InteractionPoints.Length <= 8;
}

private function int GetKnockbackDistance(XComGameStateContext_Ability AbilityContext, XComGameState_BaseObject kNewTargetState)
{
	local int UpdatedKnockbackDistance_Meters, ReasonIndex;
	local XComGameState_Unit TargetUnitState;
	local name UnitTypeName;

	UpdatedKnockbackDistance_Meters = KnockbackDistance;

	TargetUnitState = XComGameState_Unit(kNewTargetState);
	if (TargetUnitState != none)
	{
		UnitTypeName = TargetUnitState.GetMyTemplate().CharacterGroupName;
	}

	// For now, the only OverrideReason is CharacterGroupName. If otheres are desired, add extra checks here.
	ReasonIndex = KnockbackDistanceOverrides.Find('OverrideReason', UnitTypeName);

	if (ReasonIndex != INDEX_NONE)
	{
		UpdatedKnockbackDistance_Meters = KnockbackDistanceOverrides[ReasonIndex].NewKnockbackDistance_Meters;
	}

	return UpdatedKnockbackDistance_Meters;
}

//Returns the list of tiles that the unit will pass through as part of the knock back. The last tile in the array is the final destination.
private function GetTilesEnteredArray(XComGameStateContext_Ability AbilityContext, XComGameState_BaseObject kNewTargetState, out array<TTile> OutTilesEntered, out Vector OutAttackDirection, float DamageAmount, XComGameState NewGameState)
{
	local XComWorldData WorldData;
	local XComGameState_Unit SourceUnit;
	local XComGameState_Unit TargetUnit;
	local Vector SourceLocation;
	local Vector TargetLocation;
	local Vector StartLocation;
	local TTile  TempTile, StartTile;
	local TTile  LastTempTile;
	local Vector KnockbackToLocation;	
	local float  StepDistance;
	local Vector TestLocation;
	local float  TestDistanceUnits;
	local TTile  MoveToTile;
	local XGUnit TargetVisualizer;
	local XComUnitPawn TargetUnitPawn;
	local Vector Extents;
	local XComGameStateHistory History;

	local ActorTraceHitInfo TraceHitInfo;
	local array<ActorTraceHitInfo> Hits;
	local Actor FloorTileActor;

	local X2AbilityTemplate AbilityTemplate;
	local bool bCursorTargetFound;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;

	local int UpdatedKnockbackDistance_Meters;
	local array<StateObjectReference> TileUnits;

	WorldData = `XWORLD;
	History = `XCOMHISTORY;
	if(AbilityContext != none)
	{
		AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

		TargetUnit = XComGameState_Unit(kNewTargetState);
		TargetUnit.GetKeystoneVisibilityLocation(StartTile);
		TargetLocation = WorldData.GetPositionFromTileCoordinates(StartTile);

		ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
		if (ToHitCalc != none && ToHitCalc.bReactionFire)
		{
			//If this was reaction fire, just drop the unit where they are. The physics of their motion may move them a few tiles
			WorldData.GetFloorTileForPosition(TargetLocation, MoveToTile, true);
			OutTilesEntered.AddItem(MoveToTile);
		}
		else
		{
			if (AbilityTemplate != none && AbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Cursor'))
			{
				//attack source is at cursor location
				`assert( AbilityContext.InputContext.TargetLocations.Length > 0 );
				SourceLocation = AbilityContext.InputContext.TargetLocations[0];

				TempTile = WorldData.GetTileCoordinatesFromPosition(SourceLocation);
				SourceLocation = WorldData.GetPositionFromTileCoordinates(TempTile);

				//Need to produce a non-zero vector
				bCursorTargetFound = (SourceLocation.X != TargetLocation.X || SourceLocation.Y != TargetLocation.Y);
			}

			if (!bCursorTargetFound)
			{
				//attack source is from a Unit
				SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
				SourceUnit.GetKeystoneVisibilityLocation(TempTile);
				SourceLocation = WorldData.GetPositionFromTileCoordinates(TempTile);
			}

			OutAttackDirection = Normal(TargetLocation - SourceLocation);
			OutAttackDirection.Z = 0.0f;
			StartLocation = TargetLocation;

			UpdatedKnockbackDistance_Meters = GetKnockbackDistance(AbilityContext, kNewTargetState);

			KnockbackToLocation = StartLocation + (OutAttackDirection * float(UpdatedKnockbackDistance_Meters) * 64.0f); //Convert knockback distance to meters

			TargetVisualizer = XGUnit(History.GetVisualizer(TargetUnit.ObjectID));
			if( TargetVisualizer != None )
			{
				TargetUnitPawn = TargetVisualizer.GetPawn();
				if( TargetUnitPawn != None )
				{
					Extents.X = TargetUnitPawn.CylinderComponent.CollisionRadius;
					Extents.Y = TargetUnitPawn.CylinderComponent.CollisionRadius; 
					Extents.Z = TargetUnitPawn.CylinderComponent.CollisionHeight;
				}
			}

			if( WorldData.GetAllActorsTrace(StartLocation, KnockbackToLocation, Hits, Extents) )
			{
				foreach Hits(TraceHitInfo)
				{
					TempTile = WorldData.GetTileCoordinatesFromPosition(TraceHitInfo.HitLocation);
					FloorTileActor = WorldData.GetFloorTileActor(TempTile);

					if( TraceHitInfo.HitActor == FloorTileActor )
					{
						continue;
					}

					if ((!CanBeDestroyed(XComInteractiveLevelActor(TraceHitInfo.HitActor), DamageAmount) && XComFracLevelActor(TraceHitInfo.HitActor) == none) || !bKnockbackDestroysNonFragile)
					{
						//We hit an indestructible object
						KnockbackToLocation = TraceHitInfo.HitLocation + (-OutAttackDirection * 16.0f); //Scoot the hit back a bit and use that as the knockback location
						break;
					}
				}
			}

			//Walk in increments down the attack vector. We will stop if we can't find a floor, or have reached the knock back distance, or we encounter another unit.
			TestDistanceUnits = VSize2D(KnockbackToLocation - StartLocation);
			StepDistance = 0.0f;
			OutTilesEntered.Length = 0;
			LastTempTile = StartTile;
			while (StepDistance < TestDistanceUnits)
			{
				TestLocation = StartLocation + (OutAttackDirection * StepDistance);			

				if (!WorldData.GetFloorTileForPosition(TestLocation, TempTile, true))
				{
					break;
				}

				if (TempTile != StartTile)		//	don't check the start tile, since the target unit would be on it
				{
					TileUnits = WorldData.GetUnitsOnTile(TempTile);
					if (TileUnits.Length > 0)
						break;
				}

				if (LastTempTile != TempTile)
				{
					OutTilesEntered.AddItem(TempTile);
					LastTempTile = TempTile;
				}

				StepDistance += IncrementalStepSize;
			}

			//Move the target unit to the knockback location			
			if (OutTilesEntered.Length == 0 || OutTilesEntered[OutTilesEntered.Length - 1] != LastTempTile)
				OutTilesEntered.AddItem(LastTempTile);
		}
	}
}

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_BaseObject kNewTargetState;
	local int Index;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComWorldData WorldData;
	local TTile HitTile;
	local array<TTile> TilesEntered;
	local Vector AttackDirection;
	local XComGameState_Item SourceItemStateObject;
	local XComGameStateHistory History;
	local X2WeaponTemplate WeaponTemplate;
	local array<StateObjectReference> Targets;
	local StateObjectReference CurrentTarget;
	local XComGameState_Unit TargetUnit;
	local TTile NewTileLocation;
	local float KnockbackDamage;
	local float KnockbackRadius;
	local int EffectIndex, MultiTargetIndex;
	local X2Effect_Knockback KnockbackEffect;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if(AbilityContext != none)
	{
		if (AbilityContext.InputContext.PrimaryTarget.ObjectID > 0)
		{
			// Check the Primary Target for a successful knockback
			for (EffectIndex = 0; EffectIndex < AbilityContext.ResultContext.TargetEffectResults.Effects.Length; ++EffectIndex)
			{
				KnockbackEffect = X2Effect_Knockback(AbilityContext.ResultContext.TargetEffectResults.Effects[EffectIndex]);
				if (KnockbackEffect != none)
				{
					if (AbilityContext.ResultContext.TargetEffectResults.ApplyResults[EffectIndex] == 'AA_Success')
					{
						Targets.AddItem(AbilityContext.InputContext.PrimaryTarget);
						break;
					}
				}
			}
		}

		for (MultiTargetIndex = 0; MultiTargetIndex < AbilityContext.InputContext.MultiTargets.Length; ++MultiTargetIndex)
		{
			// Check the MultiTargets for a successful knockback
			for (EffectIndex = 0; EffectIndex < AbilityContext.ResultContext.MultiTargetEffectResults[MultiTargetIndex].Effects.Length; ++EffectIndex)
			{
				KnockbackEffect = X2Effect_Knockback(AbilityContext.ResultContext.MultiTargetEffectResults[MultiTargetIndex].Effects[EffectIndex]);
				if (KnockbackEffect != none)
				{
					if (AbilityContext.ResultContext.MultiTargetEffectResults[MultiTargetIndex].ApplyResults[EffectIndex] == 'AA_Success')
					{
						Targets.AddItem(AbilityContext.InputContext.MultiTargets[MultiTargetIndex]);
						break;
					}
				}
			}
		}

		foreach Targets(CurrentTarget)
		{
			History = `XCOMHISTORY;
				SourceItemStateObject = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
			if (SourceItemStateObject != None)
				WeaponTemplate = X2WeaponTemplate(SourceItemStateObject.GetMyTemplate());

			if (WeaponTemplate != none)
			{
				KnockbackDamage = WeaponTemplate.fKnockbackDamageAmount >= 0.0f ? WeaponTemplate.fKnockbackDamageAmount : DefaultDamage;
				KnockbackRadius = WeaponTemplate.fKnockbackDamageRadius >= 0.0f ? WeaponTemplate.fKnockbackDamageRadius : DefaultRadius;
			}
			else
			{
				KnockbackDamage = DefaultDamage;
				KnockbackRadius = DefaultRadius;
			}

			kNewTargetState = NewGameState.GetGameStateForObjectID(CurrentTarget.ObjectID);
			TargetUnit = XComGameState_Unit(kNewTargetState);
			if(TargetUnit != none) //Only units can be knocked back
			{
				TilesEntered.Length = 0;
				GetTilesEnteredArray(AbilityContext, kNewTargetState, TilesEntered, AttackDirection, KnockbackDamage, NewGameState);

				//Only process the code below if the target went somewhere
				if(TilesEntered.Length > 0)
				{
					WorldData = `XWORLD;

					if(bKnockbackDestroysNonFragile)
					{
						for(Index = 0; Index < TilesEntered.Length; ++Index)
						{
							HitTile = TilesEntered[Index];
							HitTile.Z += 1;

							DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));
							DamageEvent.DEBUG_SourceCodeLocation = "UC: X2Effect_Knockback:ApplyEffectToWorld";
							DamageEvent.DamageAmount = KnockbackDamage;
							DamageEvent.DamageTypeTemplateName = 'Melee';
							DamageEvent.HitLocation = WorldData.GetPositionFromTileCoordinates(HitTile);
							DamageEvent.Momentum = AttackDirection;
							DamageEvent.DamageDirection = AttackDirection; //Limit environmental damage to the attack direction( ie. spare floors )
							DamageEvent.PhysImpulse = 100;
							DamageEvent.DamageRadius = KnockbackRadius;
							DamageEvent.DamageCause = ApplyEffectParameters.SourceStateObjectRef;
							DamageEvent.DamageSource = DamageEvent.DamageCause;
							DamageEvent.bRadialDamage = false;
						}
					}

					NewTileLocation = TilesEntered[TilesEntered.Length - 1];
					TargetUnit.SetVisibilityLocation(NewTileLocation);
				}
			}			
		}
	}
}

simulated function int CalculateDamageAmount(const out EffectAppliedData ApplyEffectParameters, out int ArmorMitigation, out int NewShred)
{
	return 0;
}

simulated function bool PlusOneDamage(int Chance)
{
	return false;
}

simulated function bool IsExplosiveDamage() 
{ 
	return false; 
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_Knockback KnockbackAction;

	if (EffectApplyResult == 'AA_Success')
	{
		if( ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit') )
		{
			KnockbackAction = X2Action_Knockback(class'X2Action_Knockback'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			if( OverrideRagdollFinishTimerSec >= 0 )
			{
				KnockbackAction.OverrideRagdollFinishTimerSec = OverrideRagdollFinishTimerSec;
			}
		}
		else if (ActionMetadata.StateObject_NewState.IsA('XComGameState_EnvironmentDamage') || ActionMetadata.StateObject_NewState.IsA('XComGameState_Destructible'))
		{
			//This can be added by other effects, so check to see whether this track already has one of these
			class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext());//auto-parent to damage initiating action
		}
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
	
}

defaultproperties
{
	IncrementalStepSize=8.0

	Begin Object Class=X2Condition_UnitProperty Name=UnitPropertyCondition
		ExcludeTurret = true
		ExcludeDead = false
		FailOnNonUnits = true
	End Object

	TargetConditions.Add(UnitPropertyCondition)

	DamageTypes.Add("KnockbackDamage");

	OverrideRagdollFinishTimerSec=-1

	OnlyOnDeath=true

	ApplyChanceFn=WasTargetPreviouslyDead
}