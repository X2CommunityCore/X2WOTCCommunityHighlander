//---------------------------------------------------------------------------------------
//  FILE:    X2Effect.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect extends Object
	abstract
	native(Core)
	dependson(XComGameStateContext_Ability)
	editinlinenew
	hidecategories(Object);

struct native OverrideEffectInfo
{
	var int MaxNumberAllowed;
	var int EffectIdxToApplyOnMaxExceeded;

	structdefaultproperties
	{
		MaxNumberAllowed=0
		EffectIdxToApplyOnMaxExceeded=INDEX_NONE
	}
};

var array<X2Condition>  TargetConditions;
var bool                bApplyOnHit;
var bool                bApplyOnMiss;
var bool                bApplyToWorldOnHit;
var bool                bApplyToWorldOnMiss;
var bool                bUseSourcePlayerState;             // If true, the source player's reference will be saved in PlayerStateObjectRef when the effect is applied
var int                 ApplyChance;
var delegate<ApplyChanceCheck> ApplyChanceFn;
var int                 MinStatContestResult;              // The AbilityResultContext (in the EffectAppliedData) StatContestResult must be >= this number for the effect to apply.
var int                 MaxStatContestResult;              // The AbilityResultContext (in the EffectAppliedData) StatContestResult must be <= this number for the effect to apply. Ignored if value < Min.
var OverrideEffectInfo  MultiTargetStatContestInfo;
var array<name>         DamageTypes;     // Units immune to any damage type listed here will resist the effect. For persistent effects, cleansing effects might look for a damage type to know to remove it.
var bool                bIsImpairing;                      // If this effect impairs the unit, then an event must be sent out
var bool                bIsImpairingMomentarily;           // Sends event but does not continue to report unit as impaired
var bool                bBringRemoveVisualizationForward;         // If this effect's visualization needs to be moved forward, the context's whole visualization is moved
var bool                bShowImmunity;                  //  Default visualization will show a flyover to indicate a unit's immunity to this effect when applicable (effect application was AA_UnitIsImmune)
var bool                bShowImmunityAnyFailure;        //  Default visualization will show a flyover to indicate a unit's immunity if the effect fails for any reason (effect application was not AA_Success)
var float               DelayVisualizationSec;
var bool				bAppliesDamage;					// if this effect should be considered as damage to control stats and some generic ability damage event generation
var bool                bCanBeRedirected;               //  Indicates if an effect is appropriate to ever potentially redirect
var String				OverrideMissMessage;		// Jwats: Allows a different message to be displayed on miss.
var bool				bHideDeathWorldMessage;			//	If this effect is the cause of a unit's death, allows the normal death world message to be hidden

delegate name ApplyChanceCheck(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState);

static native function X2Effect GetX2Effect( const out X2EffectTemplateRef EffectRef );

simulated function bool IsExplosiveDamage() { return false; }

simulated function SetupEffectOnShotContextResult(optional bool _bApplyOnHit=true, optional bool _bApplyOnMiss=true)
{
	bApplyOnHit = _bApplyOnHit;
	bApplyOnMiss = _bApplyOnMiss;
}

event name ApplyEffectNative(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	return ApplyEffect( ApplyEffectParameters, kNewTargetState,  NewGameState );
}

simulated final function name ApplyEffect(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local X2Condition kCondition;
	local name AvailableCode;
	local XComGameState_Ability AbilityStateObject;
	local XComGameState_Unit SourceStateObject;
	local XComGameState_Unit TargetStateObject;
	local XComGameStateHistory History;
	local name DamageType;
	local X2EventManager EventManager;
	local XComGameState_Effect NewEffectState;
	local bool bDoStatContestResultCheck;
	local OverriddenEffectsInfo CurrentOverride;
	local int OverrideIndex;
	local Damageable DamageInterface;

	History = `XCOMHISTORY;

	AvailableCode = 'AA_Success';

	SourceStateObject = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if( SourceStateObject == none )
	{
		SourceStateObject = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	}

	TargetStateObject = XComGameState_Unit(kNewTargetState);

	if (TargetStateObject != none && TargetStateObject.bRemovedFromPlay)
	{
		return 'AA_NotAUnit';
	}

	//Begin Issue #1575
	if (TargetStateObject != none)
	{
		if (TargetStateObject.IsImmuneToEffect(self, SourceStateObject, AbilityStateObject))
		{
			return 'AA_UnitIsImmune';
		}
	}
	//End Issue #1575

	AbilityStateObject = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if( AbilityStateObject == none )
	{
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	}

	// Check to see if this Effect should be treated as normal or is involved with a StatContestResult Override
	bDoStatContestResultCheck = true;
	OverrideIndex = ApplyEffectParameters.AbilityResultContext.TargetEffectsOverrides.OverrideInfo.Find('OverrideType', 'EffectOverride_StatContest');
	if (OverrideIndex != INDEX_NONE)
	{
		CurrentOverride = ApplyEffectParameters.AbilityResultContext.TargetEffectsOverrides.OverrideInfo[OverrideIndex];
		if (CurrentOverride.OverriddenEffects.Length > 0)
		{
			// An Effect can be replaced by nothing, so there needn't be any Effects in OverriddingEffects
			if (CurrentOverride.OverriddenEffects.Find(self) != INDEX_NONE)
			{
				// This Effect has been replaced by another Effect due to StatContestResult modifications. Do not apply.
				return 'AA_EffectChanceFailed';
			}
			else if (CurrentOverride.OverriddingEffects.Find(self) != INDEX_NONE)
			{
				// This Effect is replacing another Effect due to StatContestResult modifications. Skip the StatContestResult Check.
				bDoStatContestResultCheck = false;
			}
		}
	}

	if (bDoStatContestResultCheck)
	{
		if (MinStatContestResult != 0 && ApplyEffectParameters.AbilityResultContext.StatContestResult < MinStatContestResult)
			return 'AA_EffectChanceFailed';
		if (MaxStatContestResult != 0 && ApplyEffectParameters.AbilityResultContext.StatContestResult > MaxStatContestResult)
			return 'AA_EffectChanceFailed';
	}

	foreach TargetConditions(kCondition)
	{		
		AvailableCode = kCondition.AbilityMeetsCondition(AbilityStateObject, kNewTargetState);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;

		AvailableCode = kCondition.MeetsCondition(kNewTargetState);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
		
		AvailableCode = kCondition.MeetsConditionWithSource(kNewTargetState, SourceStateObject);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;		
	}
	DamageInterface = Damageable(kNewTargetState);
	if (DamageInterface != none)
	{
		foreach DamageTypes(DamageType)
		{
			if (DamageInterface.IsImmuneToDamage(DamageType))
				return 'AA_UnitIsImmune';
		}
	}

	//Begin Issue #1575
	if (TargetStateObject != none)
	{
		if (TargetStateObject.IsImmuneToEffect(self, SourceStateObject, AbilityStateObject))
		{
			return 'AA_UnitIsImmune';
		}
	}
	//End Issue #1575

	if (ApplyChanceFn != none)
	{
		AvailableCode = ApplyChanceFn(ApplyEffectParameters, kNewTargetState, NewGameState);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
	}
	else if (ApplyChance > 0)
	{
		if (`SYNC_RAND(100) >= ApplyChance)
			return 'AA_EffectChanceFailed';
	}

	if( IsA('X2Effect_Persistent') )
	{
		AvailableCode = X2Effect_Persistent(self).HandleApplyEffect(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
		if (AvailableCode != 'AA_Success' && AvailableCode != 'AA_EffectRefreshed')
			return AvailableCode;
	}

	EventManager = `XEVENTMGR;
	// If this effect impairs the unit, then an event must be sent out
	if (bIsImpairing || bIsImpairingMomentarily)
	{		
		EventManager.TriggerEvent('ImpairingEffect', kNewTargetState, kNewTargetState);
	}

	if (AvailableCode != 'AA_EffectRefreshed')
	{
		OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

		if (IsA('X2Effect_Persistent'))
		{
			EventManager.TriggerEvent('PersistentEffectAdded', NewEffectState, kNewTargetState);
		}
	}
	
	return AvailableCode;
}

function bool TargetIsValidForAbility(XComGameState_Unit TargetState, XComGameState_Unit SourceStateObject, XComGameState_Ability AbilityStateObject)
{
	local X2Condition kCondition;
	local Name AvailableCode, DamageType;
	local Damageable DamageInterface;

	foreach TargetConditions(kCondition)
	{
		AvailableCode = kCondition.AbilityMeetsCondition(AbilityStateObject, TargetState);
		if (AvailableCode != 'AA_Success')
			return false;

		AvailableCode = kCondition.MeetsCondition(TargetState);
		if (AvailableCode != 'AA_Success')
			return false;

		AvailableCode = kCondition.MeetsConditionWithSource(TargetState, SourceStateObject);
		if (AvailableCode != 'AA_Success')
			return false;
	}
	DamageInterface = Damageable(TargetState);
	if (DamageInterface != none)
	{
		foreach DamageTypes(DamageType)
		{
			if (DamageInterface.IsImmuneToDamage(DamageType))
				return false;
		}
	}
	return true;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState);

/// <summary>
/// Override this method to apply changes this effect will have which are not associated with a target ( like OnEffectAdded ). An example might be world
/// damage where a new state object representing the damage event would be added to the game state.
/// </summary>
simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState);

/// <summary>
/// Override to associate X2Action classes with visualizer classes. When the visualizer requests a game state to construct a visualization block, this method is 
/// is called on any ability effects that contributed to the new game state. The types of visualization that effects need to perform depends highly on the
/// target of the effect, so this method provides a visualizer class so that the action created can be tailored to the target.
///
/// Example:
///     1. A unit fires its weapon at an enemy unit, resulting in a hit. When the visualizer mgr goes to create an action track to show this happening,
///        AddX2ActionForVisualization is called on X2Effect_ApplyWeaponDamageToUnit and creates an action X2Action_ApplyWeaponDamage. This action, when executed,
///        plays a hit animation on the enemy unit, pops up a UI world message showing the damage amount, starts bullet impact particle effects, rumbles
///        the controller if it was a player unit, etc.
///     2. A unit fires its weapon at an enemy unit, but MISSES and hits a car. In this case AddX2ActionForVisualization is called
///        and creates the action X2Action_ApplyWeaponDamageToTerrain. This action class manipulates the damage state in a way specific to 
///        destructible actors ( terrain visualizers ), showing the car taking damage and telegraphing that it will explode soon.
///
/// </summary>
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver FlyOverAction;
	local bool bIsFirstImmunityVisualized;
	local bool bShouldShowImmunity;
	local X2Action_TimedWait WaitAction;

	if (DelayVisualizationSec > 0.0f)
	{
		WaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		WaitAction.DelayTimeSec = DelayVisualizationSec;
	}

	bIsFirstImmunityVisualized = true;
	if (X2Effect_Persistent(self) != none)
	{
		bIsFirstImmunityVisualized = X2Effect_Persistent(self).IsFirstMatchingEffectInEventChain(VisualizeGameState);
	}
	bShouldShowImmunity = bIsFirstImmunityVisualized && ((bShowImmunity && EffectApplyResult == 'AA_UnitIsImmune') || (bShowImmunityAnyFailure && EffectApplyResult != 'AA_Success'));

	if (bShouldShowImmunity && XComGameState_Unit(ActionMetadata.StateObject_NewState) != none)
	{
		FlyOverAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		if (XGUnit(ActionMetadata.VisualizeActor) == None || XGUnit(ActionMetadata.VisualizeActor).IsMine())
			FlyOverAction.SetSoundAndFlyOverParameters(None, class'XLocalizedData'.default.UnitIsImmuneMsg, '', eColor_Good);
		else
			FlyOverAction.SetSoundAndFlyOverParameters(None, class'XLocalizedData'.default.UnitIsImmuneMsg, '', eColor_Bad);
	}
}

simulated function AddX2ActionsForVisualizationSource(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult);

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState);

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect);

function ApplyStatChangeToSubsystems( StateObjectReference OwnerRef, ECharStatType eStat, int iNewValue, XComGameState NewGameState )
{
	local XComGameState_Unit kTargetUnitState, kComponent;
	local int CompID;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	kTargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerRef.ObjectID));
	// Apply to subsystems as well.
	foreach kTargetUnitState.ComponentObjectIds(CompID)
	{
		if (History.GetGameStateForObjectID(CompID).IsA('XComGameState_Unit'))
		{
			kComponent = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', CompID));
			kComponent.SetCurrentStat(eStat, iNewValue);
		}
	}
}

//  Implement this function to add values for damage previewing in the UI 
simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimarytarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield);
simulated function GetAOETiles(XComGameState_Unit EffectSource, XComGameState_Unit EffectTarget, out array<TTile> AOETiles){}

function GetEffectDamageTypes(XComGameState GameState, EffectAppliedData EffectData, out array<name> EffectDamageTypes)
{
	EffectDamageTypes.Length = 0;
	EffectDamageTypes = DamageTypes;
}

// HACK - temporary solution to BleedingOut special case
static event X2Effect GetBleedOutEffect()
{
	return class'X2StatusEffects'.static.CreateBleedingOutStatusEffect();
}

cpptext
{
public:
	static UX2Effect* StaticGetX2Effect(const struct FX2EffectTemplateRef& EffectRef);
};

defaultproperties
{
	bApplyOnHit=true
	bApplyOnMiss=false
	bApplyToWorldOnHit=true
	bApplyToWorldOnMiss=true
	bUseSourcePlayerState=false
	bIsImpairing=false
	bIsImpairingMomentarily=false
	bShowImmunity=true
	bAppliesDamage=false
	bCanBeRedirected=true
}
