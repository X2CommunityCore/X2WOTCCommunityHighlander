//---------------------------------------------------------------------------------------
//  FILE:    X2Ability.uc
//  AUTHOR:  Ryan McFall  --  11/11/2013
//  PURPOSE: Interface for adding new abilities to X-Com 2. Extend this class and then
//           implement CreateAbilityTemplates to produce one or more ability templates
//           defining new abilities.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability extends X2DataSet
	config(GameCore)
	native(Core)
	dependson(XComGameStateContext_Ability);

// Maximum angle at which a missed shot will angle its projectile visuals
var private const config float MaxProjectileMissOffset_Standard; // Maximum distance from the shoot at location for misses, in meters (1.0f = 64 unreal units)
var private const config float MaxProjectileMissOffset_Close;	 // Maximum distance from the shoot at location for misses at close range ( < 2 tiles ), in meters (1.0f = 64 unreal units)
var private const config float MinProjectileMissOffset;			 // Minimum distance from the target that a miss trajectory should take - safeguard against misses that don't visually miss
var private const config float MaxProjectileHalfAngle;			 // Controls the arc where misses can happen

//---------------------------------------------------------------------------------------
//      Careful, these objects should NEVER be modified - only constructed by default.
//      They can be freely used by any ability template, but NEVER modified by them.
var protected X2AbilityToHitCalc_DeadEye    DeadEye;
var protected X2AbilityToHitCalc_StandardAim SimpleStandardAim;
var protected X2Condition_UnitProperty      LivingShooterProperty;
var protected X2Condition_UnitProperty      LivingHostileTargetProperty, LivingHostileUnitOnlyProperty, LivingTargetUnitOnlyProperty, LivingTargetOnlyProperty, LivingHostileUnitDisallowMindControlProperty;
var protected X2AbilityTrigger_PlayerInput  PlayerInputTrigger;
var protected X2AbilityTrigger_UnitPostBeginPlay UnitPostBeginPlayTrigger;
var protected X2AbilityTarget_Self          SelfTarget;
var protected X2AbilityTarget_Bondmate      BondmateTarget;
var protected X2AbilityTarget_Single        SimpleSingleTarget;
var protected X2AbilityTarget_Single        SimpleSingleMeleeTarget;
var protected X2AbilityTarget_Single        SingleTargetWithSelf;
var protected X2Condition_Visibility        GameplayVisibilityCondition;
var protected X2Condition_Visibility        MeleeVisibilityCondition;
var protected X2AbilityCost_ActionPoints    FreeActionCost, WeaponActionTurnEnding;
var protected X2Effect_ApplyWeaponDamage    WeaponUpgradeMissDamage;
//---------------------------------------------------------------------------------------

//General ability values
//---------------------------------------------------------------------------------------
var name CounterattackDodgeEffectName;
var int CounterattackDodgeUnitValue;
//---------------------------------------------------------------------------------------

//This method generates a miss location that attempts avoid hitting other units, obstacles near to the shooter, etc.
native static function Vector FindOptimalMissLocation(XComGameStateContext AbilityContext, bool bDebug);
native static function Vector GetTargetShootAtLocation(XComGameStateContext_Ability AbilityContext);
static function UpdateTargetLocationsFromContext(XComGameStateContext_Ability AbilityContext)
{
	local XComGameStateHistory History;
	local XComLevelActor LevelActor;
	local XComGameState_Ability ShootAbilityState;
	local X2AbilityTemplate AbilityTemplate;	
	local X2VisualizerInterface PrimaryTargetVisualizer;
	local vector MissLocation;
	local int TargetIndex;
	local vector TargetShootAtLocation;

	History = `XCOMHISTORY;

	ShootAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = ShootAbilityState.GetMyTemplate();

	// Generate a list of locations in the world to effect	
	if(AbilityTemplate.AbilityTargetEffects.Length > 0 && AbilityContext.InputContext.PrimaryTarget.ObjectID != 0)
	{
		PrimaryTargetVisualizer = X2VisualizerInterface(History.GetVisualizer(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		if(PrimaryTargetVisualizer != none)
		{
			//Always have a target location that matches the primary target
			TargetShootAtLocation = GetTargetShootAtLocation(AbilityContext);
			AbilityContext.InputContext.TargetLocations.AddItem(TargetShootAtLocation);

			//Here we set projectile hit locations. These locations MUST represent the stopping point of the projectile or else 
			//severe issues will result in the projectile system.
			if(AbilityContext.IsResultContextMiss() || AbilityTemplate.bIsASuppressionEffect)
			{
				if(`CHEATMGR != none && `CHEATMGR.ForceMissedProjectileHitActorTag != "")
				{
					foreach `BATTLE.AllActors(class'XComLevelActor', LevelActor)
					{
						if(string(LevelActor.Tag) == `CHEATMGR.ForceMissedProjectileHitActorTag)
						{
							MissLocation = LevelActor.Location;
							AbilityContext.ResultContext.ProjectileHitLocations.AddItem(MissLocation);
							break;
						}
					}
				}
				if (`CHEATMGR != none && `CHEATMGR.UseForceMissedProjectileHitTile)
				{
					if (!`XWORLD.GetFloorPositionForTile( `CHEATMGR.ForceMissedProjectileHitTile, MissLocation ))
					{
						MissLocation = `XWORLD.GetPositionFromTileCoordinates( `CHEATMGR.ForceMissedProjectileHitTile );
					}

					AbilityContext.ResultContext.ProjectileHitLocations.AddItem( MissLocation );
				}
				else
				{
					if(AbilityTemplate.IsMelee() == false)
					{
						AbilityContext.ResultContext.ProjectileHitLocations.AddItem(FindOptimalMissLocation(AbilityContext, false));

						if(AbilityTemplate.bIsASuppressionEffect) // Add a bunch of target locations for suppression
						{
							for(TargetIndex = 0; TargetIndex < 5; ++TargetIndex)
							{
								AbilityContext.ResultContext.ProjectileHitLocations.AddItem(FindOptimalMissLocation(AbilityContext, false));
							}
						}
					}
				}
			}
			else
			{
				AbilityContext.ResultContext.ProjectileHitLocations.AddItem(AbilityContext.InputContext.TargetLocations[0]);
			}
		}		
	}
	else if(AbilityContext.InputContext.TargetLocations.Length > 0)
	{
		//This indicates an ability that was free-aimed. Copy the target location into the projectile hit locations for this type of ability.
		AbilityContext.ResultContext.ProjectileHitLocations.AddItem(AbilityContext.InputContext.TargetLocations[0]);
	}
}

//This function will analyze a game state and generate damage events based on the touch event list
static function GenerateDamageEvents(XComGameState NewGameState, XComGameStateContext_Ability AbilityContext)
{
	local XComGameStateHistory History;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_Ability AbilityStateObject;
	local XComGameState_Unit SourceStateObject;
	local XComGameState_Item SourceItemStateObject;
	local X2WeaponTemplate WeaponTemplate;
	local XComInteractiveLevelActor InteractActor;
	local XComGameState_InteractiveObject InteractiveObject;
	local name SocketName;
	local Vector SocketLocation;
	local float AbilityRadius;
	local int Index;

	local int PhysicalImpulseAmount;
	local name DamageTypeTemplateName;
	local PrimitiveComponent HitComponent;
	
	//If this damage effect has an associated position, it does world damage
	if(AbilityContext.ResultContext.ProjectileHitLocations.Length > 0)
	{
		History = `XCOMHISTORY;
		SourceStateObject = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		SourceItemStateObject = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
		if(SourceItemStateObject != None)
		{
			WeaponTemplate = X2WeaponTemplate(SourceItemStateObject.GetMyTemplate());
		}
			
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));		

		if((SourceStateObject != none && AbilityStateObject != none))
		{
			AbilityRadius = AbilityStateObject.GetAbilityRadius();

			if(WeaponTemplate != none)
			{
				PhysicalImpulseAmount = WeaponTemplate.iPhysicsImpulse;
				DamageTypeTemplateName = WeaponTemplate.DamageTypeTemplateName;
			}
			else
			{
				PhysicalImpulseAmount = 0;
				DamageTypeTemplateName = 'Explosion';
			}

			//The touch list includes a start and end point. Do not apply travelling damage to these points
			for(Index = 1; Index < AbilityContext.InputContext.ProjectileEvents.Length; ++Index)
			{
				if(AbilityContext.InputContext.ProjectileEvents[Index].bEntry)
				{
					DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));
					DamageEvent.DEBUG_SourceCodeLocation = "UC: X2Ability:GenerateProjectileTouchEvents";
					DamageEvent.DamageTypeTemplateName = DamageTypeTemplateName;
					DamageEvent.HitLocation = AbilityContext.InputContext.ProjectileEvents[Index].HitLocation;
					DamageEvent.Momentum = (AbilityRadius == 0.0f) ? -AbilityContext.InputContext.ProjectileEvents[Index].HitNormal : vect(0, 0, 0);
					DamageEvent.PhysImpulse = PhysicalImpulseAmount;
					DamageEvent.DamageRadius = 16.0f;					
					DamageEvent.DamageCause = SourceStateObject.GetReference();
					DamageEvent.DamageSource = DamageEvent.DamageCause;
					DamageEvent.bRadialDamage = AbilityRadius > 0;

					HitComponent = AbilityContext.InputContext.ProjectileEvents[Index].TraceInfo.HitComponent;

					if (HitComponent != none && XComTileFracLevelActor(HitComponent.Owner) != none )
					{
						DamageEvent.DamageAmount = 20;
						DamageEvent.bAffectFragileOnly = false;
						DamageEvent.DamageDirection = AbilityContext.InputContext.ProjectileTouchEnd - AbilityContext.InputContext.ProjectileTouchStart;
					}
					else
					{
						DamageEvent.DamageAmount = 1;
						DamageEvent.bAffectFragileOnly = true;
					}

					InteractActor = HitComponent != none ? XComInteractiveLevelActor(HitComponent.Owner) : none;
					if (InteractActor != none && InteractActor.IsDoor() && InteractActor.GetInteractionCount() % 2 == 0 && WeaponTemplate.Name != 'Flamethrower' )
					{
						//Special handling for doors. They are knocked open by projectiles ( if the projectiles don't destroy them first )
						InteractiveObject = XComGameState_InteractiveObject(InteractActor.GetState(NewGameState));
						InteractActor.GetClosestSocket(AbilityContext.InputContext.ProjectileEvents[Index].HitLocation, SocketName, SocketLocation);
						InteractiveObject.Interacted(SourceStateObject, NewGameState, SocketName);
					}

					//`SHAPEMGR.DrawSphere(DamageEvent.HitLocation, vect(10, 10, 10), MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f), true);
				}
			}
			
		}
	}
}

//Used by charging melee attacks to perform a move and an attack.
static function XComGameState TypicalMoveEndAbility_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);

	// finalize the movement portion of the ability
	class'X2Ability_DefaultAbilitySet'.static.MoveAbility_FillOutGameState(NewGameState, false); //Do not apply costs at this time.

	// build the "fire" animation for the slash
	TypicalAbility_FillOutGameState(NewGameState); //Costs applied here.

	return NewGameState;
}

//Used by charging melee attacks - needed to handle the case where no movement occurs first, which isn't handled by MoveAbility_BuildInterruptGameState.
static function XComGameState TypicalMoveEndAbility_BuildInterruptGameState(XComGameStateContext Context, int InterruptStep, EInterruptionStatus InterruptionStatus)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local int MovingUnitIndex, NumMovementTiles;

	AbilityContext = XComGameStateContext_Ability(Context);
	`assert(AbilityContext != None);

	if (AbilityContext.InputContext.MovementPaths.Length == 0) //No movement - use the trivial case in TypicalAbility_BuildInterruptGameState
	{
		return TypicalAbility_BuildInterruptGameState(Context, InterruptStep, InterruptionStatus);
	}
	else //Movement - MoveAbility_BuildInterruptGameState can handle
	{
		NewGameState = class'X2Ability_DefaultAbilitySet'.static.MoveAbility_BuildInterruptGameState(Context, InterruptStep, InterruptionStatus);
		if (NewGameState == none && InterruptionStatus == eInterruptionStatus_Interrupt)
		{
			//  all movement has processed interruption, now allow the ability to be interrupted for the attack
			for(MovingUnitIndex = 0; MovingUnitIndex < AbilityContext.InputContext.MovementPaths.Length; ++MovingUnitIndex)
			{
				NumMovementTiles = Max(NumMovementTiles, AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovementTiles.Length);
			}
			//  only interrupt when movement is completed, and not again afterward
			if(InterruptStep == (NumMovementTiles - 1))			
			{
				NewGameState = `XCOMHISTORY.CreateNewGameState(true, AbilityContext);
				AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
				//  setup game state as though movement is fully completed so that the unit state's location is up to date
				class'X2Ability_DefaultAbilitySet'.static.MoveAbility_FillOutGameState(NewGameState, false); //Do not apply costs at this time.
				AbilityContext.SetInterruptionStatus(InterruptionStatus);
				AbilityContext.ResultContext.InterruptionStep = InterruptStep;
			}
		}
		return NewGameState;
	}
}

static function XComGameState TypicalAbility_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);

	TypicalAbility_FillOutGameState(NewGameState);

	return NewGameState;
}

// this function exists outside of TypicalAbility_BuildGameState so that you can do typical ability state 
// modifications to an existing game state. Useful for building compound game states 
// (such as adding an attack to the end of a move)
static function TypicalAbility_FillOutGameState(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Ability ShootAbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameStateContext_Ability AbilityContext;
	local int TargetIndex;	

	local XComGameState_BaseObject AffectedTargetObject_OriginalState;	
	local XComGameState_BaseObject AffectedTargetObject_NewState;
	local XComGameState_BaseObject SourceObject_OriginalState;
	local XComGameState_BaseObject SourceObject_NewState;
	local XComGameState_Item       SourceWeapon, SourceWeapon_NewState;
	local X2AmmoTemplate           AmmoTemplate;
	local X2GrenadeTemplate        GrenadeTemplate;
	local X2WeaponTemplate         WeaponTemplate;
	local EffectResults            MultiTargetEffectResults, EmptyResults;
	local EffectTemplateLookupType MultiTargetLookupType;
	local OverriddenEffectsByType OverrideEffects, EmptyOverride;

	History = `XCOMHISTORY;	

	//Build the new game state frame, and unit state object for the acting unit
	`assert(NewGameState != none);
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	ShootAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));	
	AbilityTemplate = ShootAbilityState.GetMyTemplate();
	SourceObject_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);	
	SourceWeapon = ShootAbilityState.GetSourceWeapon();
	ShootAbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(ShootAbilityState.Class, ShootAbilityState.ObjectID));

	//Any changes to the shooter / source object are made to this game state
	SourceObject_NewState = NewGameState.ModifyStateObject(SourceObject_OriginalState.Class, AbilityContext.InputContext.SourceObject.ObjectID);

	if (SourceWeapon != none)
	{
		SourceWeapon_NewState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', SourceWeapon.ObjectID));
	}

	if (AbilityTemplate.bRecordValidTiles && AbilityContext.InputContext.TargetLocations.Length > 0)
	{
		AbilityTemplate.AbilityMultiTargetStyle.GetValidTilesForLocation(ShootAbilityState, AbilityContext.InputContext.TargetLocations[0], AbilityContext.ResultContext.RelevantEffectTiles);
	}

	//If there is a target location, generate a list of projectile events to use if a projectile is requested
	if(AbilityContext.InputContext.ProjectileEvents.Length > 0)
	{
		GenerateDamageEvents(NewGameState, AbilityContext);
	}

	//  Apply effects to shooter
	if (AbilityTemplate.AbilityShooterEffects.Length > 0)
	{
		AffectedTargetObject_OriginalState = SourceObject_OriginalState;
		AffectedTargetObject_NewState = SourceObject_NewState;				
			
		ApplyEffectsToTarget(
			AbilityContext, 
			AffectedTargetObject_OriginalState, 
			SourceObject_OriginalState, 
			ShootAbilityState, 
			AffectedTargetObject_NewState, 
			NewGameState, 
			AbilityContext.ResultContext.HitResult,
			AbilityContext.ResultContext.ArmorMitigation,
			AbilityContext.ResultContext.StatContestResult,
			AbilityTemplate.AbilityShooterEffects, 
			AbilityContext.ResultContext.ShooterEffectResults, 
			AbilityTemplate.DataName, 
			TELT_AbilityShooterEffects);
	}

	//  Apply effects to primary target
	if (AbilityContext.InputContext.PrimaryTarget.ObjectID != 0)
	{
		AffectedTargetObject_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference);
		AffectedTargetObject_NewState = NewGameState.ModifyStateObject(AffectedTargetObject_OriginalState.Class, AbilityContext.InputContext.PrimaryTarget.ObjectID);
		
		if (AbilityTemplate.AbilityTargetEffects.Length > 0)
		{
			if (ApplyEffectsToTarget(
				AbilityContext, 
				AffectedTargetObject_OriginalState, 
				SourceObject_OriginalState, 
				ShootAbilityState, 
				AffectedTargetObject_NewState, 
				NewGameState, 
				AbilityContext.ResultContext.HitResult,
				AbilityContext.ResultContext.ArmorMitigation,
				AbilityContext.ResultContext.StatContestResult,
				AbilityTemplate.AbilityTargetEffects, 
				AbilityContext.ResultContext.TargetEffectResults, 
				AbilityTemplate.DataName, 
				TELT_AbilityTargetEffects))

			{
				if (AbilityTemplate.bAllowAmmoEffects && SourceWeapon_NewState != none && SourceWeapon_NewState.HasLoadedAmmo())
				{
					AmmoTemplate = X2AmmoTemplate(SourceWeapon_NewState.GetLoadedAmmoTemplate(ShootAbilityState));
					if (AmmoTemplate != none && AmmoTemplate.TargetEffects.Length > 0)
					{
						ApplyEffectsToTarget(
							AbilityContext, 
							AffectedTargetObject_OriginalState, 
							SourceObject_OriginalState, 
							ShootAbilityState, 
							AffectedTargetObject_NewState, 
							NewGameState, 
							AbilityContext.ResultContext.HitResult,
							AbilityContext.ResultContext.ArmorMitigation,
							AbilityContext.ResultContext.StatContestResult,
							AmmoTemplate.TargetEffects, 
							AbilityContext.ResultContext.TargetEffectResults, 
							AmmoTemplate.DataName,  //Use the ammo template for TELT_AmmoTargetEffects
							TELT_AmmoTargetEffects);
					}
				}
				if (AbilityTemplate.bAllowBonusWeaponEffects && SourceWeapon_NewState != none)
				{
					WeaponTemplate = X2WeaponTemplate(SourceWeapon_NewState.GetMyTemplate());
					if (WeaponTemplate != none && WeaponTemplate.BonusWeaponEffects.Length > 0)
					{
						ApplyEffectsToTarget(
							AbilityContext,
							AffectedTargetObject_OriginalState, 
							SourceObject_OriginalState, 
							ShootAbilityState, 
							AffectedTargetObject_NewState, 
							NewGameState, 
							AbilityContext.ResultContext.HitResult,
							AbilityContext.ResultContext.ArmorMitigation,
							AbilityContext.ResultContext.StatContestResult,
							WeaponTemplate.BonusWeaponEffects, 
							AbilityContext.ResultContext.TargetEffectResults, 
							WeaponTemplate.DataName,
							TELT_WeaponEffects);
					}
				}
			}
		}

		if (AbilityTemplate.Hostility == eHostility_Offensive && AffectedTargetObject_NewState.CanEarnXp() && XComGameState_Unit(AffectedTargetObject_NewState).IsEnemyUnit(XComGameState_Unit(SourceObject_NewState)))
		{
			`TRIGGERXP('XpGetShotAt', AffectedTargetObject_NewState.GetReference(), SourceObject_NewState.GetReference(), NewGameState);
		}
	}

	if (AbilityTemplate.bUseLaunchedGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetLoadedAmmoTemplate(ShootAbilityState));
		MultiTargetLookupType = TELT_LaunchedGrenadeEffects;
	}
	else if (AbilityTemplate.bUseThrownGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());
		MultiTargetLookupType = TELT_ThrownGrenadeEffects;
	}
	else
	{
		MultiTargetLookupType = TELT_AbilityMultiTargetEffects;
	}

	//  Apply effects to multi targets
	if( (AbilityTemplate.AbilityMultiTargetEffects.Length > 0 || GrenadeTemplate != none) && AbilityContext.InputContext.MultiTargets.Length > 0)
	{		
		for( TargetIndex = 0; TargetIndex < AbilityContext.InputContext.MultiTargets.Length; ++TargetIndex )
		{
			AffectedTargetObject_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.MultiTargets[TargetIndex].ObjectID, eReturnType_Reference);
			AffectedTargetObject_NewState = NewGameState.ModifyStateObject(AffectedTargetObject_OriginalState.Class, AbilityContext.InputContext.MultiTargets[TargetIndex].ObjectID);

			OverrideEffects = AbilityContext.ResultContext.MultiTargetEffectsOverrides.Length > TargetIndex ? AbilityContext.ResultContext.MultiTargetEffectsOverrides[TargetIndex] : EmptyOverride;
			
			MultiTargetEffectResults = EmptyResults;        //  clear struct for use - cannot pass dynamic array element as out parameter
			if (ApplyEffectsToTarget(
				AbilityContext, 
				AffectedTargetObject_OriginalState, 
				SourceObject_OriginalState, 
				ShootAbilityState, 
				AffectedTargetObject_NewState, 
				NewGameState, 
				AbilityContext.ResultContext.MultiTargetHitResults[TargetIndex],
				AbilityContext.ResultContext.MultiTargetArmorMitigation[TargetIndex],
				AbilityContext.ResultContext.MultiTargetStatContestResult[TargetIndex],
				AbilityTemplate.bUseLaunchedGrenadeEffects ? GrenadeTemplate.LaunchedGrenadeEffects : (AbilityTemplate.bUseThrownGrenadeEffects ? GrenadeTemplate.ThrownGrenadeEffects : AbilityTemplate.AbilityMultiTargetEffects), 
				MultiTargetEffectResults, 
				GrenadeTemplate == none ? AbilityTemplate.DataName : GrenadeTemplate.DataName, 
				MultiTargetLookupType ,
				OverrideEffects))
			{
				AbilityContext.ResultContext.MultiTargetEffectResults[TargetIndex] = MultiTargetEffectResults;  //  copy results into dynamic array
			}
		}
	}
	
	//Give all effects a chance to make world modifications ( ie. add new state objects independent of targeting )
	ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, AbilityTemplate.AbilityShooterEffects, AbilityTemplate.DataName, TELT_AbilityShooterEffects);
	ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, AbilityTemplate.AbilityTargetEffects, AbilityTemplate.DataName, TELT_AbilityTargetEffects);	
	if (GrenadeTemplate != none)
	{
		if (AbilityTemplate.bUseLaunchedGrenadeEffects)
		{
			ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, GrenadeTemplate.LaunchedGrenadeEffects, GrenadeTemplate.DataName, TELT_LaunchedGrenadeEffects);
		}
		else if (AbilityTemplate.bUseThrownGrenadeEffects)
		{
			ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, GrenadeTemplate.ThrownGrenadeEffects, GrenadeTemplate.DataName, TELT_ThrownGrenadeEffects);
		}
	}
	else
	{
		ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, AbilityTemplate.AbilityMultiTargetEffects, AbilityTemplate.DataName, TELT_AbilityMultiTargetEffects);
	}

	//Apply the cost of the ability
	AbilityTemplate.ApplyCost(AbilityContext, ShootAbilityState, SourceObject_NewState, SourceWeapon_NewState, NewGameState);
}

static function ApplyEffectsToWorld(XComGameStateContext_Ability AbilityContext,
											  XComGameState_BaseObject kSource, 
											  XComGameState_Ability kSourceAbility, 											  
											  XComGameState NewGameState,
											  array<X2Effect> Effects,
											  Name SourceTemplateName,
											  EffectTemplateLookupType EffectLookupType)
{
	local EffectAppliedData ApplyData;
	local int EffectIndex;
	local StateObjectReference NoWeapon;
	local XComGameState_Unit SourceUnit;
	local StateObjectReference DefaultPlayerStateObjectRef;
	local bool bHit, bMiss;
	
	bHit = class'XComGameStateContext_Ability'.static.IsHitResultHit(AbilityContext.ResultContext.HitResult);
	bMiss = class'XComGameStateContext_Ability'.static.IsHitResultMiss(AbilityContext.ResultContext.HitResult);
	//  Check to see if this was a multi target.
	`assert(bHit || bMiss);     //  Better be one or the other!

	ApplyData.AbilityInputContext = AbilityContext.InputContext;
	ApplyData.AbilityResultContext = AbilityContext.ResultContext;
	ApplyData.AbilityStateObjectRef = kSourceAbility.GetReference();
	ApplyData.SourceStateObjectRef = kSource.GetReference();	
	ApplyData.ItemStateObjectRef = kSourceAbility.GetSourceWeapon() == none ? NoWeapon : kSourceAbility.GetSourceWeapon().GetReference();	
	ApplyData.EffectRef.SourceTemplateName = SourceTemplateName;
	ApplyData.EffectRef.LookupType = EffectLookupType;

	DefaultPlayerStateObjectRef = `TACTICALRULES.GetCachedUnitActionPlayerRef();
	for (EffectIndex = 0; EffectIndex < Effects.Length; ++EffectIndex)
	{
		// Only Apply the effect if the result meets the effect's world application criteria.
		if ( (Effects[EffectIndex].bApplyToWorldOnHit && bHit) ||
			 (Effects[EffectIndex].bApplyToWorldOnMiss && bMiss) )
		{
			ApplyData.PlayerStateObjectRef = DefaultPlayerStateObjectRef;

			if (Effects[EffectIndex].bUseSourcePlayerState)
			{
				// If the source unit's controlling player needs to be saved in
				// ApplyData.PlayerStateObjectRef
				SourceUnit = XComGameState_Unit(kSource);
			
				if (SourceUnit != none)
				{
					ApplyData.PlayerStateObjectRef = SourceUnit.ControllingPlayer;
				}
			}

			ApplyData.EffectRef.TemplateEffectLookupArrayIndex = EffectIndex;
			Effects[EffectIndex].ApplyEffectToWorld(ApplyData, NewGameState);
		}
	}
}

static function bool ApplyEffectsToTarget( XComGameStateContext_Ability AbilityContext,
												XComGameState_BaseObject kOriginalTarget, 
												XComGameState_BaseObject kSource, 
												XComGameState_Ability kSourceAbility, 
												XComGameState_BaseObject kNewTargetState,
												XComGameState NewGameState,
												EAbilityHitResult Result,
												ArmorMitigationResults ArmorMitigated,
												int StatContestResult,
												array<X2Effect> Effects,
												out EffectResults EffectResults,
												Name SourceTemplateName,
												EffectTemplateLookupType EffectLookupType,
												optional OverriddenEffectsByType TargetEffectsOverrides)
{
	local XComGameState_Unit UnitState, SourceUnit, RedirectUnit;
	local EffectAppliedData ApplyData, RedirectData;
	local int EffectIndex;
	local StateObjectReference NoWeapon;
	local bool bHit, bMiss, bRedirected;
	local StateObjectReference DefaultPlayerStateObjectRef;
	local name AffectingRedirectorName, OverrideRedirectResult;
	local XComGameState_Effect RedirectorEffectState;
	local EffectRedirect Redirection, EmptyRedirection;

	UnitState = XComGameState_Unit(kNewTargetState);
	SourceUnit = XComGameState_Unit(kSource);

	if (UnitState != none)
		`XEVENTMGR.TriggerEvent('UnitAttacked', UnitState, UnitState, NewGameState);

	bHit = class'XComGameStateContext_Ability'.static.IsHitResultHit(Result);
	bMiss = class'XComGameStateContext_Ability'.static.IsHitResultMiss(Result);
	//  Check to see if this was a multi target.
	`assert(bHit || bMiss);     //  Better be one or the other!

	ApplyData.AbilityInputContext = AbilityContext.InputContext;
	ApplyData.AbilityResultContext = AbilityContext.ResultContext;
	ApplyData.AbilityResultContext.HitResult = Result;                      //  fixes result with multi target result so that effects don't have to dig into the multi target info
	ApplyData.AbilityResultContext.ArmorMitigation = ArmorMitigated;        //  as above
	ApplyData.AbilityResultContext.StatContestResult = StatContestResult;   //  as above
	ApplyData.AbilityResultContext.TargetEffectsOverrides = TargetEffectsOverrides;   //  as above
	ApplyData.AbilityStateObjectRef = kSourceAbility.GetReference();
	ApplyData.SourceStateObjectRef = kSource.GetReference();
	ApplyData.TargetStateObjectRef = kOriginalTarget.GetReference();	
	ApplyData.ItemStateObjectRef = kSourceAbility.GetSourceWeapon() == none ? NoWeapon : kSourceAbility.GetSourceWeapon().GetReference();	
	ApplyData.EffectRef.SourceTemplateName = SourceTemplateName;
	ApplyData.EffectRef.LookupType = EffectLookupType;

	DefaultPlayerStateObjectRef = UnitState == none ? `TACTICALRULES.GetCachedUnitActionPlayerRef() : UnitState.ControllingPlayer;
	for (EffectIndex = 0; EffectIndex < Effects.Length; ++EffectIndex)
	{
		ApplyData.PlayerStateObjectRef = DefaultPlayerStateObjectRef;

		EffectResults.Effects.AddItem( Effects[ EffectIndex ] );

		// Only Apply the effect if the result meets the effect's application criteria.
		if ( (Effects[EffectIndex].bApplyOnHit && bHit) ||
			 (Effects[EffectIndex].bApplyOnMiss && bMiss))
		{	
			if (Effects[EffectIndex].bUseSourcePlayerState)
			{
				// If the source unit's controlling player needs to be saved in
				// ApplyData.PlayerStateObjectRef							
				if (SourceUnit != none)
				{
					ApplyData.PlayerStateObjectRef = SourceUnit.ControllingPlayer;
				}
			}
			ApplyData.EffectRef.TemplateEffectLookupArrayIndex = EffectIndex;

			//  Check for a redirect
			bRedirected = false;
			if (UnitState != none)
			{
				foreach class'X2AbilityTemplateManager'.default.AffectingEffectRedirectors(AffectingRedirectorName)
				{
					RedirectorEffectState = UnitState.GetUnitAffectedByEffectState(AffectingRedirectorName);
					if (RedirectorEffectState != None)
					{
						Redirection = EmptyRedirection;
						Redirection.OriginalTargetRef = kOriginalTarget.GetReference();
						OverrideRedirectResult = 'AA_Success';        //  assume the redirected effect will apply normally
						if (RedirectorEffectState.GetX2Effect().EffectShouldRedirect(AbilityContext, kSourceAbility, RedirectorEffectState, Effects[EffectIndex], SourceUnit, UnitState, Redirection.RedirectedToTargetRef, Redirection.RedirectReason, OverrideRedirectResult))
						{
							RedirectUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(Redirection.RedirectedToTargetRef.ObjectID));
							if (RedirectUnit == None)
							{
								RedirectUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Redirection.RedirectedToTargetRef.ObjectID));
								if (RedirectUnit == None)
								{
									`RedScreen("Attempted effect redirection wanted to redirect to unit ID" @ Redirection.RedirectedToTargetRef.ObjectID @ "but no such unit was found. @gameplay @jbouscher");
									break;
								}
								RedirectUnit = XComGameState_Unit(NewGameState.ModifyStateObject(RedirectUnit.Class, RedirectUnit.ObjectID));
							}
							bRedirected = true;
							break;
						}
					}
				}
			}
			
			if (bRedirected)
			{
				EffectResults.ApplyResults.AddItem(Redirection.RedirectReason);
				
				RedirectData = ApplyData;
				RedirectData.TargetStateObjectRef = Redirection.RedirectedToTargetRef;
				Redirection.RedirectResults.Effects.AddItem(Effects[EffectIndex]);
				Redirection.RedirectResults.TemplateRefs.AddItem(ApplyData.EffectRef);
				if (OverrideRedirectResult == 'AA_Success')
					Redirection.RedirectResults.ApplyResults.AddItem(Effects[EffectIndex].ApplyEffect(RedirectData, RedirectUnit, NewGameState));
				else
					Redirection.RedirectResults.ApplyResults.AddItem(OverrideRedirectResult);
				AbilityContext.ResultContext.EffectRedirects.AddItem(Redirection);
			}
			else
			{				
				EffectResults.ApplyResults.AddItem(Effects[EffectIndex].ApplyEffect(ApplyData, kNewTargetState, NewGameState));
			}
		}
		else
		{
			EffectResults.ApplyResults.AddItem( 'AA_HitResultFailure' );
		}

		EffectResults.TemplateRefs.AddItem(ApplyData.EffectRef);
	}
	return true;
}

static function TypicalAbility_BuildVisualization(XComGameState VisualizeGameState)
{	
	//general
	local XComGameStateHistory	History;
	local XComGameStateVisualizationMgr VisualizationMgr;

	//visualizers
	local Actor	TargetVisualizer, ShooterVisualizer;

	//actions
	local X2Action							AddedAction;
	local X2Action							FireAction;
	local X2Action_MoveTurn					MoveTurnAction;
	local X2Action_PlaySoundAndFlyOver		SoundAndFlyover;
	local X2Action_ExitCover				ExitCoverAction;
	local X2Action_MoveTeleport				TeleportMoveAction;
	local X2Action_Delay					MoveDelay;
	local X2Action_MoveEnd					MoveEnd;
	local X2Action_MarkerNamed				JoinActions;
	local array<X2Action>					LeafNodes;
	local X2Action_WaitForAnotherAction		WaitForFireAction;

	//state objects
	local XComGameState_Ability				AbilityState;
	local XComGameState_EnvironmentDamage	EnvironmentDamageEvent;
	local XComGameState_WorldEffectTileData WorldDataUpdate;
	local XComGameState_InteractiveObject	InteractiveObject;
	local XComGameState_BaseObject			TargetStateObject;
	local XComGameState_Item				SourceWeapon;
	local StateObjectReference				ShootingUnitRef;

	//interfaces
	local X2VisualizerInterface			TargetVisualizerInterface, ShooterVisualizerInterface;

	//contexts
	local XComGameStateContext_Ability	Context;
	local AbilityInputContext			AbilityContext;

	//templates
	local X2AbilityTemplate	AbilityTemplate;
	local X2AmmoTemplate	AmmoTemplate;
	local X2WeaponTemplate	WeaponTemplate;
	local array<X2Effect>	MultiTargetEffects;

	//Tree metadata
	local VisualizationActionMetadata   InitData;
	local VisualizationActionMetadata   BuildData;
	local VisualizationActionMetadata   SourceData, InterruptTrack;

	local XComGameState_Unit TargetUnitState;	
	local name         ApplyResult;

	//indices
	local int	EffectIndex, TargetIndex;
	local int	TrackIndex;
	local int	WindowBreakTouchIndex;

	//flags
	local bool	bSourceIsAlsoTarget;
	local bool	bMultiSourceIsAlsoTarget;
	local bool  bPlayedAttackResultNarrative;
			
	// good/bad determination
	local bool bGoodAbility;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityContext = Context.InputContext;
	/// HL-Docs: ref:Bugfixes; issue:879
	/// Use HistoryIndex to access the AbilityState as it was when the ability was activated rather than getting the most recent version.
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.AbilityRef.ObjectID,, VisualizeGameState.HistoryIndex));
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.AbilityTemplateName);
	ShootingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter, part I. We split this into two parts since
	//in some situations the shooter can also be a target
	//****************************************************************************************
	ShooterVisualizer = History.GetVisualizer(ShootingUnitRef.ObjectID);
	ShooterVisualizerInterface = X2VisualizerInterface(ShooterVisualizer);

	SourceData = InitData;
	SourceData.StateObject_OldState = History.GetGameStateForObjectID(ShootingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceData.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(ShootingUnitRef.ObjectID);
	if (SourceData.StateObject_NewState == none)
		SourceData.StateObject_NewState = SourceData.StateObject_OldState;
	SourceData.VisualizeActor = ShooterVisualizer;	

	/// HL-Docs: ref:Bugfixes; issue:879
	/// Use HistoryIndex to access the WeaponState as it was when the ability was activated rather than getting the most recent version.
	SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.ItemObject.ObjectID,, VisualizeGameState.HistoryIndex));
	if (SourceWeapon != None)
	{
		WeaponTemplate = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
		AmmoTemplate = X2AmmoTemplate(SourceWeapon.GetLoadedAmmoTemplate(AbilityState));
	}

	bGoodAbility = XComGameState_Unit(SourceData.StateObject_NewState).IsFriendlyToLocalPlayer();

	if( Context.IsResultContextMiss() && AbilityTemplate.SourceMissSpeech != '' )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.SourceMissSpeech, bGoodAbility ? eColor_Bad : eColor_Good);
	}
	else if( Context.IsResultContextHit() && AbilityTemplate.SourceHitSpeech != '' )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.SourceHitSpeech, bGoodAbility ? eColor_Good : eColor_Bad);
	}

	if( !AbilityTemplate.bSkipFireAction || Context.InputContext.MovementPaths.Length > 0 )
	{
		ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover'.static.AddToVisualizationTree(SourceData, Context));
		ExitCoverAction.bSkipExitCoverVisualization = AbilityTemplate.bSkipExitCoverWhenFiring;

		// if this ability has a built in move, do it right before we do the fire action
		if(Context.InputContext.MovementPaths.Length > 0)
		{			
			// note that we skip the stop animation since we'll be doing our own stop with the end of move attack
			class'X2VisualizerHelpers'.static.ParsePath(Context, SourceData, AbilityTemplate.bSkipMoveStop);

			//  add paths for other units moving with us (e.g. gremlins moving with a move+attack ability)
			if (Context.InputContext.MovementPaths.Length > 1)
			{
				for (TrackIndex = 1; TrackIndex < Context.InputContext.MovementPaths.Length; ++TrackIndex)
				{
					BuildData = InitData;
					BuildData.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.MovementPaths[TrackIndex].MovingUnitRef.ObjectID);
					BuildData.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.MovementPaths[TrackIndex].MovingUnitRef.ObjectID);
					MoveDelay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(BuildData, Context));
					MoveDelay.Duration = class'X2Ability_DefaultAbilitySet'.default.TypicalMoveDelay;
					class'X2VisualizerHelpers'.static.ParsePath(Context, BuildData, AbilityTemplate.bSkipMoveStop);	
				}
			}

			if( !AbilityTemplate.bSkipFireAction )
			{
				MoveEnd = X2Action_MoveEnd(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_MoveEnd', SourceData.VisualizeActor));				

				if (MoveEnd != none)
				{
					// add the fire action as a child of the node immediately prior to the move end
					AddedAction = AbilityTemplate.ActionFireClass.static.AddToVisualizationTree(SourceData, Context, false, none, MoveEnd.ParentActions);

					// reconnect the move end action as a child of the fire action, as a special end of move animation will be performed for this move + attack ability
					VisualizationMgr.DisconnectAction(MoveEnd);
					VisualizationMgr.ConnectAction(MoveEnd, VisualizationMgr.BuildVisTree, false, AddedAction);
				}
				else
				{
					//See if this is a teleport. If so, don't perform exit cover visuals
					TeleportMoveAction = X2Action_MoveTeleport(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_MoveTeleport', SourceData.VisualizeActor));
					if (TeleportMoveAction != none)
					{
						//Skip the FOW Reveal ( at the start of the path ). Let the fire take care of it ( end of the path )
						ExitCoverAction.bSkipFOWReveal = true;
					}

					AddedAction = AbilityTemplate.ActionFireClass.static.AddToVisualizationTree(SourceData, Context, false, SourceData.LastActionAdded);
				}
			}
		}
		else
		{
			//If we were interrupted, insert a marker node for the interrupting visualization code to use. In the move path version above, it is expected for interrupts to be 
			//done during the move.
			if (Context.InterruptionStatus != eInterruptionStatus_None)
			{
				//Insert markers for the subsequent interrupt to insert into
				class'X2Action'.static.AddInterruptMarkerPair(SourceData, Context, ExitCoverAction);
			}

			if (!AbilityTemplate.bSkipFireAction)
			{
				// no move, just add the fire action. Parent is exit cover action if we have one
				AddedAction = AbilityTemplate.ActionFireClass.static.AddToVisualizationTree(SourceData, Context, false, SourceData.LastActionAdded);
			}			
		}

		if( !AbilityTemplate.bSkipFireAction )
		{
			FireAction = AddedAction;

			class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'AttackBegin', FireAction.ParentActions[0]);

			if( AbilityTemplate.AbilityToHitCalc != None )
			{
				X2Action_Fire(AddedAction).SetFireParameters(Context.IsResultContextHit());
			}
		}
	}

	//If there are effects added to the shooter, add the visualizer actions for them
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, SourceData, Context.FindShooterEffectApplyResult(AbilityTemplate.AbilityShooterEffects[EffectIndex]));		
	}
	//****************************************************************************************

	//Configure the visualization track for the target(s). This functionality uses the context primarily
	//since the game state may not include state objects for misses.
	//****************************************************************************************	
	bSourceIsAlsoTarget = AbilityContext.PrimaryTarget.ObjectID == AbilityContext.SourceObject.ObjectID; //The shooter is the primary target
	if (AbilityTemplate.AbilityTargetEffects.Length > 0 &&			//There are effects to apply
		AbilityContext.PrimaryTarget.ObjectID > 0)				//There is a primary target
	{
		TargetVisualizer = History.GetVisualizer(AbilityContext.PrimaryTarget.ObjectID);
		TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

		if( bSourceIsAlsoTarget )
		{
			BuildData = SourceData;
		}
		else
		{
			BuildData = InterruptTrack;        //  interrupt track will either be empty or filled out correctly
		}

		BuildData.VisualizeActor = TargetVisualizer;

		TargetStateObject = VisualizeGameState.GetGameStateForObjectID(AbilityContext.PrimaryTarget.ObjectID);
		if( TargetStateObject != none )
		{
			History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.PrimaryTarget.ObjectID, 
															   BuildData.StateObject_OldState, BuildData.StateObject_NewState,
															   eReturnType_Reference,
															   VisualizeGameState.HistoryIndex);
			`assert(BuildData.StateObject_NewState == TargetStateObject);
		}
		else
		{
			//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
			//and show no change.
			BuildData.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.PrimaryTarget.ObjectID);
			BuildData.StateObject_NewState = BuildData.StateObject_OldState;
		}

		// if this is a melee attack, make sure the target is facing the location he will be melee'd from
		if(!AbilityTemplate.bSkipFireAction 
			&& !bSourceIsAlsoTarget 
			&& AbilityContext.MovementPaths.Length > 0
			&& AbilityContext.MovementPaths[0].MovementData.Length > 0
			&& XGUnit(TargetVisualizer) != none)
		{
			MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(BuildData, Context, false, ExitCoverAction));
			MoveTurnAction.m_vFacePoint = AbilityContext.MovementPaths[0].MovementData[AbilityContext.MovementPaths[0].MovementData.Length - 1].Position;
			MoveTurnAction.m_vFacePoint.Z = TargetVisualizerInterface.GetTargetingFocusLocation().Z;
			MoveTurnAction.UpdateAimTarget = true;

			// Jwats: Add a wait for ability effect so the idle state machine doesn't process!
			WaitForFireAction = X2Action_WaitForAnotherAction(class'X2Action_WaitForAnotherAction'.static.AddToVisualizationTree(BuildData, Context, false, MoveTurnAction));
			WaitForFireAction.ActionToWaitFor = FireAction;
		}

		//Pass in AddedAction (Fire Action) as the LastActionAdded if we have one. Important! As this is automatically used as the parent in the effect application sub functions below.
		if (AddedAction != none && AddedAction.IsA('X2Action_Fire'))
		{
			BuildData.LastActionAdded = AddedAction;
		}
		
		//Add any X2Actions that are specific to this effect being applied. These actions would typically be instantaneous, showing UI world messages
		//playing any effect specific audio, starting effect specific effects, etc. However, they can also potentially perform animations on the 
		//track actor, so the design of effect actions must consider how they will look/play in sequence with other effects.
		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			ApplyResult = Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]);

			// Target effect visualization
			if( !Context.bSkipAdditionalVisualizationSteps )
			{
				AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);
			}

			// Source effect visualization
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
		}

		//the following is used to handle Rupture flyover text
		TargetUnitState = XComGameState_Unit(BuildData.StateObject_OldState);
		if (TargetUnitState != none &&
			XComGameState_Unit(BuildData.StateObject_OldState).GetRupturedValue() == 0 &&
			XComGameState_Unit(BuildData.StateObject_NewState).GetRupturedValue() > 0)
		{
			//this is the frame that we realized we've been ruptured!
			class 'X2StatusEffects'.static.RuptureVisualization(VisualizeGameState, BuildData);
		}

		if (AbilityTemplate.bAllowAmmoEffects && AmmoTemplate != None)
		{
			for (EffectIndex = 0; EffectIndex < AmmoTemplate.TargetEffects.Length; ++EffectIndex)
			{
				ApplyResult = Context.FindTargetEffectApplyResult(AmmoTemplate.TargetEffects[EffectIndex]);
				AmmoTemplate.TargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);
				AmmoTemplate.TargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
			}
		}
		if (AbilityTemplate.bAllowBonusWeaponEffects && WeaponTemplate != none)
		{
			for (EffectIndex = 0; EffectIndex < WeaponTemplate.BonusWeaponEffects.Length; ++EffectIndex)
			{
				ApplyResult = Context.FindTargetEffectApplyResult(WeaponTemplate.BonusWeaponEffects[EffectIndex]);
				WeaponTemplate.BonusWeaponEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);
				WeaponTemplate.BonusWeaponEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
			}
		}

		if (Context.IsResultContextMiss() && (AbilityTemplate.LocMissMessage != "" || AbilityTemplate.TargetMissSpeech != ''))
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context, false, BuildData.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocMissMessage, AbilityTemplate.TargetMissSpeech, bGoodAbility ? eColor_Bad : eColor_Good);
		}
		else if( Context.IsResultContextHit() && (AbilityTemplate.LocHitMessage != "" || AbilityTemplate.TargetHitSpeech != '') )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context, false, BuildData.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocHitMessage, AbilityTemplate.TargetHitSpeech, bGoodAbility ? eColor_Good : eColor_Bad);
		}

		if (!bPlayedAttackResultNarrative)
		{
			class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'AttackResult');
			bPlayedAttackResultNarrative = true;
		}

		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildData);
		}

		if( bSourceIsAlsoTarget )
		{
			SourceData = BuildData;
		}
	}

	if (AbilityTemplate.bUseLaunchedGrenadeEffects)
	{
		MultiTargetEffects = X2GrenadeTemplate(SourceWeapon.GetLoadedAmmoTemplate(AbilityState)).LaunchedGrenadeEffects;
	}
	else if (AbilityTemplate.bUseThrownGrenadeEffects)
	{
		MultiTargetEffects = X2GrenadeTemplate(SourceWeapon.GetMyTemplate()).ThrownGrenadeEffects;
	}
	else
	{
		MultiTargetEffects = AbilityTemplate.AbilityMultiTargetEffects;
	}

	//  Apply effects to multi targets - don't show multi effects for burst fire as we just want the first time to visualize
	if( MultiTargetEffects.Length > 0 && AbilityContext.MultiTargets.Length > 0 && X2AbilityMultiTarget_BurstFire(AbilityTemplate.AbilityMultiTargetStyle) == none)
	{
		for( TargetIndex = 0; TargetIndex < AbilityContext.MultiTargets.Length; ++TargetIndex )
		{	
			bMultiSourceIsAlsoTarget = false;
			if( AbilityContext.MultiTargets[TargetIndex].ObjectID == AbilityContext.SourceObject.ObjectID )
			{
				bMultiSourceIsAlsoTarget = true;
				bSourceIsAlsoTarget = bMultiSourceIsAlsoTarget;				
			}

			TargetVisualizer = History.GetVisualizer(AbilityContext.MultiTargets[TargetIndex].ObjectID);
			TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

			if( bMultiSourceIsAlsoTarget )
			{
				BuildData = SourceData;
			}
			else
			{
				BuildData = InitData;
			}
			BuildData.VisualizeActor = TargetVisualizer;

			// if the ability involved a fire action and we don't have already have a potential parent,
			// all the target visualizations should probably be parented to the fire action and not rely on the auto placement.
			if( (BuildData.LastActionAdded == none) && (FireAction != none) )
				BuildData.LastActionAdded = FireAction;

			TargetStateObject = VisualizeGameState.GetGameStateForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID);
			if( TargetStateObject != none )
			{
				History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID, 
																	BuildData.StateObject_OldState, BuildData.StateObject_NewState,
																	eReturnType_Reference,
																	VisualizeGameState.HistoryIndex);
				`assert(BuildData.StateObject_NewState == TargetStateObject);
			}			
			else
			{
				//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
				//and show no change.
				BuildData.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID);
				BuildData.StateObject_NewState = BuildData.StateObject_OldState;
			}
		
			//Add any X2Actions that are specific to this effect being applied. These actions would typically be instantaneous, showing UI world messages
			//playing any effect specific audio, starting effect specific effects, etc. However, they can also potentially perform animations on the 
			//track actor, so the design of effect actions must consider how they will look/play in sequence with other effects.
			for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
			{
				ApplyResult = Context.FindMultiTargetEffectApplyResult(MultiTargetEffects[EffectIndex], TargetIndex);

				// Target effect visualization
				MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);

				// Source effect visualization
				MultiTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
			}			

			//the following is used to handle Rupture flyover text
			TargetUnitState = XComGameState_Unit(BuildData.StateObject_OldState);
			if (TargetUnitState != none && 
				XComGameState_Unit(BuildData.StateObject_OldState).GetRupturedValue() == 0 &&
				XComGameState_Unit(BuildData.StateObject_NewState).GetRupturedValue() > 0)
			{
				//this is the frame that we realized we've been ruptured!
				class 'X2StatusEffects'.static.RuptureVisualization(VisualizeGameState, BuildData);
			}
			
			if (!bPlayedAttackResultNarrative)
			{
				class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'AttackResult');
				bPlayedAttackResultNarrative = true;
			}

			if( TargetVisualizerInterface != none )
			{
				//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
				TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildData);
			}

			if( bMultiSourceIsAlsoTarget )
			{
				SourceData = BuildData;
			}			
		}
	}
	//****************************************************************************************

	//Finish adding the shooter's track
	//****************************************************************************************
	if( !bSourceIsAlsoTarget && ShooterVisualizerInterface != none)
	{
		ShooterVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, SourceData);				
	}	

	//  Handle redirect visualization
	TypicalAbility_AddEffectRedirects(VisualizeGameState, SourceData);

	//****************************************************************************************

	//Configure the visualization tracks for the environment
	//****************************************************************************************

	if (ExitCoverAction != none)
	{
		ExitCoverAction.ShouldBreakWindowBeforeFiring( Context, WindowBreakTouchIndex );
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{
		BuildData = InitData;
		BuildData.VisualizeActor = none;
		BuildData.StateObject_NewState = EnvironmentDamageEvent;
		BuildData.StateObject_OldState = EnvironmentDamageEvent;

		// if this is the damage associated with the exit cover action, we need to force the parenting within the tree
		// otherwise LastActionAdded with be 'none' and actions will auto-parent.
		if ((ExitCoverAction != none) && (WindowBreakTouchIndex > -1))
		{
			if (EnvironmentDamageEvent.HitLocation == AbilityContext.ProjectileEvents[WindowBreakTouchIndex].HitLocation)
			{
				BuildData.LastActionAdded = ExitCoverAction;
			}
		}

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');		
		}

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');
		}

		for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
		{
			MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');	
		}
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldDataUpdate)
	{
		BuildData = InitData;
		BuildData.VisualizeActor = none;
		BuildData.StateObject_NewState = WorldDataUpdate;
		BuildData.StateObject_OldState = WorldDataUpdate;

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');		
		}

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');
		}

		for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
		{
			MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');	
		}
	}
	//****************************************************************************************

	//Process any interactions with interactive objects
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		// Add any doors that need to listen for notification. 
		// Move logic is taken from MoveAbility_BuildVisualization, which only has special case handling for AI patrol movement ( which wouldn't happen here )
		if ( Context.InputContext.MovementPaths.Length > 0 || (InteractiveObject.IsDoor() && InteractiveObject.HasDestroyAnim()) ) //Is this a closed door?
		{
			BuildData = InitData;
			//Don't necessarily have a previous state, so just use the one we know about
			BuildData.StateObject_OldState = InteractiveObject;
			BuildData.StateObject_NewState = InteractiveObject;
			BuildData.VisualizeActor = History.GetVisualizer(InteractiveObject.ObjectID);

			class'X2Action_BreakInteractActor'.static.AddToVisualizationTree(BuildData, Context);
		}
	}
	
	//Add a join so that all hit reactions and other actions will complete before the visualization sequence moves on. In the case
	// of fire but no enter cover then we need to make sure to wait for the fire since it isn't a leaf node
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

	if (!AbilityTemplate.bSkipFireAction)
	{
		if (!AbilityTemplate.bSkipExitCoverWhenFiring)
		{			
			LeafNodes.AddItem(class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceData, Context, false, FireAction));
		}
		else
		{
			LeafNodes.AddItem(FireAction);
		}
	}
	
	if (VisualizationMgr.BuildVisTree.ChildActions.Length > 0)
	{
		JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SourceData, Context, false, none, LeafNodes));
		JoinActions.SetName("Join");
	}
}

static function TypicalAbility_AddEffectRedirects(XComGameState VisualizeGameState, out VisualizationActionMetadata SourceData)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local Actor                     TargetVisualizer;
	local X2VisualizerInterface     TargetVisualizerInterface;
	local VisualizationActionMetadata    BuildData, InitData;
	local XComGameState_BaseObject  TargetStateObject;
	//local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local name ApplyResult;
	local X2AbilityTemplate AbilityTemplate;
	local int RedirectIndex, EffectIndex;
	local array<int> RedirectTargets;
	local string RedirectText;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (Context.ResultContext.EffectRedirects.Length == 0)
		return;

	History = `XCOMHISTORY;
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
		
    for (RedirectIndex = 0; RedirectIndex < Context.ResultContext.EffectRedirects.Length; ++RedirectIndex)
	{
		//  need to make a new track
		BuildData = InitData;
		TargetVisualizer = History.GetVisualizer(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID);
		TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);
		BuildData.VisualizeActor = TargetVisualizer;
		TargetStateObject = VisualizeGameState.GetGameStateForObjectID(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID);
		if( TargetStateObject != none )
		{
			History.GetCurrentAndPreviousGameStatesForObjectID(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID, 
																BuildData.StateObject_OldState, BuildData.StateObject_NewState,
																eReturnType_Reference,
																VisualizeGameState.HistoryIndex);
			`assert(BuildData.StateObject_NewState == TargetStateObject);
		}			
		else
		{
			//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
			//and show no change.
			BuildData.StateObject_OldState = History.GetGameStateForObjectID(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID);
			BuildData.StateObject_NewState = BuildData.StateObject_OldState;
		}
		

		//Make the target wait until signaled by the shooter that the projectiles are hitting
		if (!AbilityTemplate.bSkipFireAction)
		{
			X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(BuildData, Context));
		}

		//  add the redirect effects
		for (EffectIndex = 0; EffectIndex < Context.ResultContext.EffectRedirects[RedirectIndex].RedirectResults.Effects.Length; ++EffectIndex)
		{
			ApplyResult = Context.ResultContext.EffectRedirects[RedirectIndex].RedirectResults.ApplyResults[EffectIndex];

			// Target effect visualization
			Context.ResultContext.EffectRedirects[RedirectIndex].RedirectResults.Effects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);

			// Source effect visualization
			Context.ResultContext.EffectRedirects[RedirectIndex].RedirectResults.Effects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
		}

		//  Do other typical visualization if this track wasn't created before		
		//the following is used to handle Rupture flyover text
		if (XComGameState_Unit(BuildData.StateObject_OldState).GetRupturedValue() == 0 &&
			XComGameState_Unit(BuildData.StateObject_NewState).GetRupturedValue() > 0)
		{
			//this is the frame that we realized we've been ruptured!
			class 'X2StatusEffects'.static.RuptureVisualization(VisualizeGameState, BuildData);
		}

		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildData);
		}
		

		//  only visualize a flyover once for any given target
		if (RedirectTargets.Find(Context.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID) != INDEX_NONE)
			continue;
		RedirectTargets.AddItem(Context.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID);

		//  Look for an existing track for the original target - this should be guaranteed to exist
		RedirectText = class'X2AbilityTemplateManager'.static.GetDisplayStringForAvailabilityCode(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectReason);
		if (RedirectText != "")
		{
			SoundAndFlyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context));
			SoundAndFlyover.SetSoundAndFlyOverParameters(none, RedirectText, '', eColor_Good);			
		}
	}
}

function DesiredVisualizationBlock_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action_MarkerTreeInsertBegin MarkerStart;
	local X2Action_MarkerTreeInsertEnd FoundEndMarker;
	local XComGameStateContext_Ability Context;
	local Array<X2Action> FoundActions;
	local int ActionIndex;

	VisMgr = `XCOMVISUALIZATIONMGR;

	MarkerStart = X2Action_MarkerTreeInsertBegin(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin'));
	Context = XComGameStateContext_Ability(MarkerStart.StateChangeContext);

	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerTreeInsertEnd', FoundActions);
	for( ActionIndex = 0; ActionIndex < FoundActions.Length; ++ActionIndex )
	{
		if( FoundActions[ActionIndex].StateChangeContext.AssociatedState.HistoryIndex == Context.DesiredVisualizationBlockIndex )
		{
			FoundEndMarker = X2Action_MarkerTreeInsertEnd(FoundActions[ActionIndex]);
			break;
		}
	}

	if( FoundEndMarker != None )
	{
		VisMgr.DisconnectAction(MarkerStart);
		VisMgr.ConnectAction(MarkerStart, VisualizationTree, false, FoundEndMarker);
	}
	else
	{
		Context.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
	}
}

function FuseMergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action_MarkerTreeInsertBegin MarkerStart;
	local X2Action_Fire FoundFireAction;
	local XComGameStateContext_Ability Context;
	local Array<X2Action> FoundActions;
	local int ActionIndex;
	local X2Action_ExitCover MyExitCover;

	VisMgr = `XCOMVISUALIZATIONMGR;

		MarkerStart = X2Action_MarkerTreeInsertBegin(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin'));
	MyExitCover = X2Action_ExitCover(VisMgr.GetNodeOfType(BuildTree, class'X2Action_ExitCover'));
	Context = XComGameStateContext_Ability(MarkerStart.StateChangeContext);

	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_Fire', FoundActions);
	for( ActionIndex = 0; ActionIndex < FoundActions.Length; ++ActionIndex )
	{
		if( FoundActions[ActionIndex].StateChangeContext.AssociatedState.HistoryIndex == Context.DesiredVisualizationBlockIndex )
		{
			FoundFireAction = X2Action_Fire(FoundActions[ActionIndex]);
			MarkerStart.AddInputEvent('Visualizer_AbilityHit');
			MyExitCover.AddInputEvent('Visualizer_AbilityHit');
			break;
		}
	}

	if( FoundFireAction != None )
	{
		VisMgr.DisconnectAction(MarkerStart);
		VisMgr.ConnectAction(MarkerStart, VisualizationTree, false, FoundFireAction);

		VisMgr.DisconnectAction(MyExitCover);
		VisMgr.ConnectAction(MyExitCover, VisualizationTree, false, FoundFireAction);
	}
	else
	{
		Context.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
	}
}

//	e.g. Rapid Fire, Chain Shot, Banish
simulated function SequentialShot_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisMgr;
	local Array<X2Action> arrActions;
	local X2Action_MarkerTreeInsertBegin MarkerStart;
	local X2Action_MarkerNamed MarkerNamed, JoinMarker, TrackerMarker;
	local X2Action_ExitCover ExitCoverAction, FirstExitCoverAction;
	local X2Action_EnterCover EnterCoverAction, LastEnterCoverAction;
	local X2Action_WaitForAnotherAction WaitAction;
	local VisualizationActionMetadata ActionMetadata;
	local int i;
	// Variable for Issue #20
	local int iBestHistoryIndex;

	VisMgr = `XCOMVISUALIZATIONMGR;
	MarkerStart = X2Action_MarkerTreeInsertBegin(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin'));
	// Start Issue #20
	/// HL-Docs: ref:Bugfixes; issue:20
	/// Reaper's Banish now properly visualizes subsequent shots.
	// This function breaks 3+ subsequent shots. Somehow, the actions filled out by GetNodesOfType are sorted so that our
	// "get the last join marker" actually sometimes finds us the FIRST join marker. This causes all these shot contexts to
	// try and visualize themselves alongside each other, which is definitely not intended.
	// Further investigations made it seem that the additional parameter bSortByHistoryIndex=true does not seem to have the desired effect
	// but generally push it *somewhat* in the right direction
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerNamed', arrActions, , , true);
	// End Issue #20

	//	get the last Join marker
	// Start Issue #20
	// GetNodesOfType() does not seem to produce a consistent ordering
	// We will just manually get the "latest" one by comparing history indices
	iBestHistoryIndex = -1;
	for (i = 0; i < arrActions.Length; ++i)
	{
		MarkerNamed = X2Action_MarkerNamed(arrActions[i]);
		if (MarkerNamed.MarkerName == 'Join' && (JoinMarker == None || MarkerNamed.StateChangeContext.AssociatedState.HistoryIndex > iBestHistoryIndex))
		{
			iBestHistoryIndex = MarkerNamed.StateChangeContext.AssociatedState.HistoryIndex;
			// End Issue #20
			JoinMarker = MarkerNamed;
		}
		else if (MarkerNamed.MarkerName == 'SequentialShotTracker')
		{
			TrackerMarker = MarkerNamed;
		}
		// Comment out for Issue #20
		// We can't bail out early because we may need to compare more join markers :(
		//if (JoinMarker != none && TrackerMarker != none)
		//	break;
	}

	`assert(JoinMarker != none);

	//	all other enter cover actions need to skip entering cover	
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_EnterCover', arrActions);
	for (i = 0; i < arrActions.Length; ++i)
	{
		//	@TODO - Ideally we need to check our ExitCover action to see if the step out it wants (from our original
		//			location) is different from the previous ExitCover, in which case we'd need to go ahead
		//			and allow the EnterCover to run, as well as not skip our ExitCover.

		EnterCoverAction = X2Action_EnterCover(arrActions[i]);
		EnterCoverAction.bSkipEnterCover = true;
	}
	LastEnterCoverAction = X2Action_EnterCover(VisMgr.GetNodeOfType(BuildTree, class'X2Action_EnterCover'));

	//	have our exit cover not visualize since the unit is already out from the first shot
	ExitCoverAction = X2Action_ExitCover(VisMgr.GetNodeOfType(BuildTree, class'X2Action_ExitCover'));
	ExitCoverAction.bSkipExitCoverVisualization = true;

	// Single Line for Issue #273 Line moved to end so that there will only be one EnterCover is the VisualizationTree so the GetNodesOfType() can't get the wrong one
	/// HL-Docs: ref:Bugfixes; issue:273
	/// Fix an issue causing Rapid Fire/Chain Shot/Banish/... entering cover early
	//VisMgr.ConnectAction(MarkerStart, VisualizationTree, true, JoinMarker);
	
	//	now we have to make sure there's a wait parented to the first exit cover, which waits for the last enter cover
	//	this will prevent the idle state machine from taking over and putting the unit back in cover
		
	if (TrackerMarker == none)
	{
		VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_ExitCover', arrActions);
		FirstExitCoverAction = X2Action_ExitCover(arrActions[0]);
		`assert(FirstExitCoverAction != none);
		ActionMetadata = FirstExitCoverAction.Metadata;
		TrackerMarker = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, FirstExitCoverAction.StateChangeContext, , FirstExitCoverAction));
		TrackerMarker.SetName("SequentialShotTracker");
		WaitAction = X2Action_WaitForAnotherAction(class'X2Action_WaitForAnotherAction'.static.AddToVisualizationTree(ActionMetadata, FirstExitCoverAction.StateChangeContext, , TrackerMarker));
	}
	else
	{
		arrActions = TrackerMarker.ChildActions;
		for (i = 0; i < arrActions.Length; ++i)
		{
			WaitAction = X2Action_WaitForAnotherAction(arrActions[i]);
			if (WaitAction != none)
				break;
		}
		`assert(WaitAction != none);		//	should have been created along with the marker action
	}

	WaitAction.ActionToWaitFor = LastEnterCoverAction;
	// Single Line for Issue #273 Line moved from earlier
	VisMgr.ConnectAction(MarkerStart, VisualizationTree, true, JoinMarker);
}

function OverwatchShot_BuildVisualization(XComGameState VisualizeGameState)
{	
	TypicalAbility_BuildVisualization(VisualizeGameState);
}

static function XComGameStateContext_Ability FindCounterAttackGameState(XComGameStateContext_Ability InitiatingAbilityContext, XComGameState_Unit OriginalAttacker)
{
	local int Index;
	local XComGameStateContext_Ability IterateAbility;
	local XComGameStateHistory History;
	
	//Check if we are the original shooter in a counter attack sequence, meaning that we are now being attacked. The
	//target of a counter attack just plays a different flinch/reaction anim
	if (InitiatingAbilityContext.InputContext.SourceObject.ObjectID == OriginalAttacker.ObjectID)
	{
		History = `XCOMHISTORY;
		//In this situation we need to update ability context so that it is from the counter attack game state
		for (Index = InitiatingAbilityContext.AssociatedState.HistoryIndex; Index < History.GetNumGameStates(); ++Index)
		{
			//The counter attack ability context will have its targets / sources reversed
			IterateAbility = XComGameStateContext_Ability(History.GetGameStateFromHistory(Index).GetContext());
			if (IterateAbility != none &&
				IterateAbility.InputContext.PrimaryTarget.ObjectID == OriginalAttacker.ObjectID &&
				InitiatingAbilityContext.InputContext.PrimaryTarget.ObjectID == IterateAbility.InputContext.SourceObject.ObjectID)
			{
				break;
			}
		}
	}

	return IterateAbility;
}

native static function bool MoveAbility_StepCausesDestruction(XComGameState_Unit MovingUnitState, const out AbilityInputContext InputContext, int PathIndex, int ToStep);
native static function MoveAbility_AddTileStateObjects(XComGameState NewGameState, XComGameState_Unit MovingUnitState, const out AbilityInputContext InputContext, int PathIndex, int ToStep);
native static function MoveAbility_AddNewlySeenUnitStateObjects(XComGameState NewGameState, XComGameState_Unit MovingUnitState, const out AbilityInputContext InputContext, int PathIndex);

static function XComGameState TypicalAbility_BuildInterruptGameState(XComGameStateContext Context, int InterruptStep, EInterruptionStatus InterruptionStatus)
{
	//  This "typical" interruption game state allows the ability to be interrupted with no game state changes.
	//  Upon resume from the interrupt, the ability will attempt to build a new game state like normal.

	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;

	AbilityContext = XComGameStateContext_Ability(Context);
	if (AbilityContext != none)
	{
		if (InterruptionStatus == eInterruptionStatus_Resume)
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
			NewGameState = AbilityState.GetMyTemplate().BuildNewGameStateFn(Context);
			AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
			AbilityContext.SetInterruptionStatus(InterruptionStatus);
			AbilityContext.ResultContext.InterruptionStep = InterruptStep;
		}		
		else if (InterruptStep == 0)
		{
			NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);
			AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
			AbilityContext.SetInterruptionStatus(InterruptionStatus);
			AbilityContext.ResultContext.InterruptionStep = InterruptStep;
		}				
	}
	return NewGameState;
}

static function X2AbilityTemplate PurePassive(name TemplateName, optional string TemplateIconImage="img:///UILibrary_PerkIcons.UIPerk_standard", optional bool bCrossClassEligible=false, optional Name AbilitySourceName='eAbilitySource_Perk', optional bool bDisplayInUI=true)
{
	local X2AbilityTemplate             Template;
	local X2Effect_Persistent           PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.IconImage = TemplateIconImage;
	Template.AbilitySourceName = AbilitySourceName;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	//  This is a dummy effect so that an icon shows up in the UI.
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(1, true, false);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, TemplateIconImage, bDisplayInUI,, Template.AbilitySourceName);
	Template.AddTargetEffect(PersistentEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!

	Template.bCrossClassEligible = bCrossClassEligible;

	return Template;
}

DefaultProperties
{
	Begin Object Class=X2AbilityToHitCalc_DeadEye Name=DefaultDeadEye
	End Object
	DeadEye = DefaultDeadEye;

	Begin Object Class=X2AbilityToHitCalc_StandardAim Name=DefaultSimpleStandardAim
	End Object
	SimpleStandardAim = DefaultSimpleStandardAim;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingShooterProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=false
		ExcludeHostileToSource=true
	End Object
	LivingShooterProperty = DefaultLivingShooterProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingHostileTargetProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=true
		ExcludeHostileToSource=false
		TreatMindControlledSquadmateAsHostile=true
	End Object
	LivingHostileTargetProperty = DefaultLivingHostileTargetProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingHostileUnitOnlyProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=true
		ExcludeHostileToSource=false
		TreatMindControlledSquadmateAsHostile=true
		FailOnNonUnits=true
	End Object
	LivingHostileUnitOnlyProperty = DefaultLivingHostileUnitOnlyProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingHostileUnitDisallowMindControlProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=true
		ExcludeHostileToSource=false
		TreatMindControlledSquadmateAsHostile=false
		FailOnNonUnits=true
	End Object
	LivingHostileUnitDisallowMindControlProperty = DefaultLivingHostileUnitDisallowMindControlProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingTargetUnitOnlyProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=false
		ExcludeHostileToSource=false
		FailOnNonUnits=true
	End Object
	LivingTargetUnitOnlyProperty = DefaultLivingTargetUnitOnlyProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingTargetOnlyProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=false
		ExcludeHostileToSource=false
	End Object
	LivingTargetOnlyProperty = DefaultLivingTargetOnlyProperty;

	Begin Object Class=X2AbilityTrigger_PlayerInput Name=DefaultPlayerInputTrigger
	End Object
	PlayerInputTrigger = DefaultPlayerInputTrigger;

	Begin Object Class=X2AbilityTrigger_UnitPostBeginPlay Name=DefaultUnitPostBeginPlayTrigger
	End Object
	UnitPostBeginPlayTrigger = DefaultUnitPostBeginPlayTrigger;

	Begin Object Class=X2AbilityTarget_Self Name=DefaultSelfTarget
	End Object
	SelfTarget = DefaultSelfTarget;

	Begin Object Class=X2AbilityTarget_Bondmate Name=DefaultBondmateTarget
	End Object
	BondmateTarget = DefaultBondmateTarget;

	Begin Object Class=X2AbilityTarget_Single Name=DefaultSimpleSingleTarget
		bAllowDestructibleObjects=true
	End Object
	SimpleSingleTarget = DefaultSimpleSingleTarget;

	Begin Object Class=X2AbilityTarget_Single Name=DefaultSimpleSingleMeleeTarget
		bAllowDestructibleObjects=true
		OnlyIncludeTargetsInsideWeaponRange=true
	End Object
	SimpleSingleMeleeTarget = DefaultSimpleSingleMeleeTarget;

	Begin Object Class=X2AbilityTarget_Single Name=DefaultSingleTargetWithSelf
		bIncludeSelf=true
	End Object
	SingleTargetWithSelf = DefaultSingleTargetWithSelf;

	Begin Object Class=X2Condition_Visibility Name=DefaultGameplayVisibilityCondition
		bRequireGameplayVisible=true
		bRequireBasicVisibility=true
	End Object
	GameplayVisibilityCondition = DefaultGameplayVisibilityCondition;

	Begin Object Class=X2Condition_Visibility Name=DefaultMeleeVisibilityCondition
		bRequireGameplayVisible=true
		bVisibleToAnyAlly=true
	End Object
	MeleeVisibilityCondition = DefaultMeleeVisibilityCondition;

	Begin Object Class=X2AbilityCost_ActionPoints Name=DefaultFreeActionCost
		iNumPoints=1
		bFreeCost=true
	End Object
	FreeActionCost = DefaultFreeActionCost;

	Begin Object Class=X2AbilityCost_ActionPoints Name=DefaultWeaponActionTurnEnding
		bAddWeaponTypicalCost=true
		bConsumeAllPoints=true
	End Object
	WeaponActionTurnEnding = DefaultWeaponActionTurnEnding;

	Begin Object Class=X2Effect_ApplyWeaponDamage Name=DefaultWeaponUpgradeMissDamage
		bApplyOnHit=false
		bApplyOnMiss=true
		bIgnoreBaseDamage=true
		DamageTag="Miss"
		bAllowWeaponUpgrade=true
		bAllowFreeKill=false
	End Object
	WeaponUpgradeMissDamage = DefaultWeaponUpgradeMissDamage;

	CounterattackDodgeEffectName = "CounterattackDodgeEffect"
	CounterattackDodgeUnitValue = 1
}
