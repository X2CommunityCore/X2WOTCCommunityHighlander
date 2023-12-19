//---------------------------------------------------------------------------------------
//  FILE:    X2StatusEffects.uc
//  AUTHOR:  Joshua Bouscher  --  5/7/2014
//  PURPOSE: Provides static functions that create X2Effects which can be applied to
//           ability templates. Allows for effect reuse across different abilities.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2StatusEffects extends Object config(GameCore);

var config array<name> REMOVE_EFFECTS_ON_TEAM_SWAP_SOURCE;
var config array<name> REMOVE_EFFECTS_ON_TEAM_SWAP_TARGET;

var localized string ConcealedFriendlyName;
var localized string RevealedFriendlyName;
var localized string SpottedConcealedUnitFriendlyName;
var localized string SpottedFlankedConcealedUnitFriendlyName;

var name BleedingOutName;
var config int BLEEDINGOUT_TURNS;
var config int BLEEDOUT_BASE;
var config int BLEEDOUT_SIGHT_RADIUS;
var config int BLEEDOUT_ROLL, BLEEDOUT_BONUS_ROLL;
var localized string BleedingOutFriendlyName;
var localized string BleedingOutFriendlyDesc;
var localized string BleedingOutEffectAcquiredString;
var localized string BleedingOutEffectTickedString;
var localized string BleedingOutEffectLostString;

var name BurningName;
var config int BURNING_TURNS;
var config int BURNING_INFECT_DISTANCE;
var config int BURNING_INFECT_PERCENTAGE;
var config array<name> BURNING_SPREAD_ALLOWED_UNIT_TYPES;
var localized string BurningFriendlyName;
var localized string BurningFriendlyDesc;
var localized string BurningEffectAcquiredString;
var localized string BurningEffectTickedString;
var localized string BurningEffectLostString;

var config string RuptureIcon;
var localized string RupturedFriendlyName;
var localized string RupturedFriendlyDesc;
var localized string RupturedEffectAcquiredString;

var name AcidBurningName;
var config int ACID_BURNING_TURNS;
var localized string AcidBurningFriendlyName;
var localized string AcidBurningFriendlyDesc;
var localized string AcidBurningEffectAcquiredString;
var localized string AcidBurningEffectTickedString;
var localized string AcidBurningEffectLostString;

var config int CONFUSED_MOBILITY_ADJUST;
var config int CONFUSED_WILL_ADJUST;
var localized string ConfusedFriendlyName;
var localized string ConfusedLostFriendlyName;
var localized string ConfusedFriendlyDesc;
var localized string ConfusedEffectAcquiredString;
var localized string ConfusedEffectTickedString;
var localized string ConfusedEffectLostString;

var config int DISORIENTED_TURNS;
var config int DISORIENTED_MOBILITY_ADJUST;
var config int DISORIENTED_AIM_ADJUST;
var config int DISORIENTED_WILL_ADJUST;
var localized string DisorientedFriendlyName;
var localized string DisorientedLostFriendlyName;
var localized string DisorientedFriendlyDesc;
var localized string DisorientedEffectAcquiredString;
var localized string DisorientedEffectTickedString;
var localized string DisorientedEffectLostString;

var localized string MindControlFriendlyName;
var localized string MindControlLostFriendlyName;
var localized string MindControlFriendlyDesc;
var localized string MindControlEffectAcquiredString;
var localized string MindControlEffectTickedString;
var localized string MindControlEffectLostString;
var localized string MindControlSourceFriendlyName;
var localized string MindControlSourceFriendlyDesc;

var localized string HackedUnitFriendlyName;
var localized string HackedUnitLostFriendlyName;
var localized string HackedUnitFriendlyDesc;
var localized string HackedUnitEffectAcquiredString;
var localized string HackedUnitEffectTickedString;
var localized string HackedUnitEffectLostString;

var name PoisonedName;
var config int POISONED_TURNS;
var config int POISONED_MOBILITY_ADJUST;
var config int POISONED_AIM_ADJUST;
var config int POISONED_INITIAL_SHED;
var config int POISONED_PER_TURN_SHED;
var config int POISONED_DAMAGE;
var config int POISONED_INFECT_DISTANCE;
var config int POISONED_INFECT_PERCENTAGE;
var config bool POISONED_IGNORES_SHIELDS; // Issue #89
var localized string PoisonedFriendlyName;
var localized string PoisonedFriendlyDesc;
var localized string PoisonedEffectAcquiredString;
var localized string PoisonedEffectTickedString;
var localized string PoisonedEffectLostString;

var localized string StunnedFriendlyName;
var localized string StunnedFriendlyDesc;
var localized string StunnedEffectAcquiredString;
var localized string StunnedEffectTickedString;
var localized string StunnedEffectLostString;
var localized string StunnedPerActionFriendlyName;

var localized string RoboticStunnedFriendlyName;
var localized string RoboticStunnedFriendlyDesc;
var localized string RoboticStunnedEffectAcquiredString;
var localized string RoboticStunnedEffectTickedString;
var localized string RoboticStunnedEffectLostString;
var localized string RoboticStunnedPerActionFriendlyName;

var name UnconsciousName;
var localized string UnconsciousFriendlyName;
var localized string UnconsciousFriendlyDesc;
var localized string UnconsciousEffectAcquiredString;
var localized string UnconsciousEffectTickedString;
var localized string UnconsciousEffectLostString;

var config int BOUND_MOBILITY_ADJUST;
var localized string BoundFriendlyName;
var localized string BoundFriendlyDesc;
var localized string BoundEffectAcquiredString;
var localized string BoundEffectTickedString;
var localized string BoundEffectLostString;

var name MarkedName;
var localized string MarkedFriendlyName;
var localized string MarkedFriendlyDesc;
var localized string MarkedEffectAcquiredString;
var localized string MarkedEffectTickedString;
var localized string MarkedEffectLostString;

var config int PANIC_WILL_ADJUST;
var config int STUNNED_WILL_ADJUST;

var config int PANICKED_TURNS;								// Number of turns the panic effect removes control of the unit.
var config int PANICKED_AIM_ADJUST;							// Stat adjustment for panic aim (Stat_Offense)
var config int PANICKED_AIM_ADJUST_BERSERK;					// Stat adjustment for panic-berserk aim (Stat_Offense)
var config int PANIC_SUCCESS_WILL_MOD;                      // Improves Will after panicking

var config int PANIC_STRENGTH_TAKE_DAMAGE;					// Panic Event Strength on unit taking damage.
var config int PANIC_STRENGTH_LOS_FRIENDLY_DEATH;			// Panic Event Strength on LoS to friendly unit's death
var config int PANIC_STRENGTH_LOS_HIGHER_FRIENDLY_DEATH;	// Panic Event Strength on LoS to higher ranking friendly unit's death
var config int PANIC_STRENGTH_ALLY_PANICS;                  // Panic Event Strength when a friendly unit panics
var config int MAX_PANICKING_UNITS;                         // Per team number, for non AI 
var config int PANIC_HIGHER_RANK;                           // If dying unit's rank >= your rank + this number, use HIGHER_FRIENDLY_DEATH
var config int PANIC_LOWER_RANK;                            // If dying unit's rank - this number >= your rank, use FRIENDLY_DEATH (unless above applies)

var localized string GatekeeperClosedEffectName;
var localized string GatekeeperClosedEffectDesc;

var name StasisLanceName;
var localized string StasisLanceEffectName;
var localized string StasisLanceEffectDesc;
var localized string StasisLanceFailed;
var config int STASIS_LANCE_TURNS;

var config int DISORIENTED_HIERARCHY_VALUE;
var config int PANICKED_HIERARCHY_VALUE;
var config int FRENZY_HIERARCHY_VALUE;
var config int CONFUSED_HIERARCHY_VALUE;
var config int RAGE_HIERARCHY_VALUE;
var config int STUNNED_HIERARCHY_VALUE;
var config int MINDCONTROL_HIERARCHY_VALUE;
var config int PSYCHOSIS_HIERARCHY_VALUE;
var config int BIND_HIERARCHY_VALUE;
var config int UNCONCIOUS_HIERARCHY_VALUE;

var config string AcidEnteredParticle_Name;
var config name AcidEnteredSocket_Name;
var config name AcidEnteredSocketsArray_Name;
var config string PoisonEnteredParticle_Name;
var config name PoisonEnteredSocket_Name;
var config name PoisonEnteredSocketsArray_Name;
var config string FireEnteredParticle_Name;
var config name FireEnteredSocket_Name;
var config name FireEnteredSocketsArray_Name;
var config string DisorientedParticle_Name;
var config name DisorientedSocket_Name;
var config name DisorientedSocketsArray_Name;
var config string StunnedParticle_Name;
var config name StunnedSocket_Name;
var config name StunnedSocketsArray_Name;
var config name BleedingSocket_Name;
var config name BleedingSocketsArray_Name;
var config string BlindedParticle_Name;
var config name BlindedSocket_Name;
var config name BlindedSocketsArray_Name;

var config string AcidEnteredPerk_Name;
var config string BleedingPerk_Name;
var config string FireEnteredPerk_Name;
var config string PoisonEnteredPerk_Name;

var localized string HackDefenseDecreasedFriendlyName;
var localized string HackDefenseDecreasedFriendlyDesc;
var localized string HackDefenseIncreasedFriendlyName;
var localized string HackDefenseIncreasedFriendlyDesc;
var localized string HackDefenseChangeEffectAcquiredString;

var name UnblockPathingName;

var name BleedingName;
var localized string BleedingFriendlyName;
var localized string BleedingFriendlyDesc;
var localized string BleedingEffectAcquiredString;
var localized string BleedingEffectTickedString;
var localized string BleedingEffectLostString;
var config bool BLEEDING_IGNORES_SHIELDS; // Single variable for Issue #629

var config int ULTRASONICLURE_TURNS;
var name UltrasonicLureName;
var localized string UltrasonicLureFriendlyName;
var localized string UltrasonicLureFriendlyDesc;

var localized string ResistedMindControlText;

static function X2Effect_BleedingOut CreateBleedingOutStatusEffect()
{
	local X2Effect_BleedingOut   PersistentEffect;

	PersistentEffect = new class'X2Effect_BleedingOut';
	PersistentEffect.EffectName = default.BleedingOutName;
	PersistentEffect.DuplicateResponse = eDupe_Ignore;
	PersistentEffect.BuildPersistentEffect(default.BLEEDINGOUT_TURNS,,,,eGameRule_PlayerTurnBegin);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, default.BleedingOutFriendlyName, default.BleedingOutFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_willtosurvive");
	PersistentEffect.EffectAddedFn = BleedingOutEffectAdded;
	PersistentEffect.EffectRemovedFn = BleedingOutEffectRemoved;
	PersistentEffect.CleansedVisualizationFn = BleedingOutCleansedVisualization;
	PersistentEffect.VisualizationFn = none;        //  NOTE: bleeding out is added directly by the system and not in a way that uses this. visualization is handled by XGUnitNativeBase:BuildAbilityEffectsVisualization
	PersistentEffect.EffectTickedVisualizationFn = BleedingOutVisualizationTicked;
	PersistentEffect.EffectRemovedVisualizationFn = BleedingOutVisualizationRemoved;
	PersistentEffect.bIsImpairing = true;

	return PersistentEffect;
}

static function BleedingOutEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local vector Position;

	UnitState = XComGameState_Unit(kNewTargetState);
	UnitState.bBleedingOut = true;
	UnitState.SetCurrentStat(eStat_HP, 1);
	UnitState.LowestHP = 1;
	
	//need to insert fake viewer to hide the sight_radius change before the visualization has happened
	Position = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);
	XGUnit(UnitState.GetVisualizer()).TempFOWViewer = `XWORLD.CreateFOWViewer(Position, UnitState.GetCurrentStat(eStat_SightRadius) * 64/*class'XComWorldData'.const.WORLD_StepSize*/);
	
	`XEVENTMGR.TriggerEvent( 'UnitBleedingOut', UnitState, UnitState, NewGameState );			
}

static function BleedingOutEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameStateContext_Ability AbilityContext;
	local StateObjectReference SourceRef;
	local XComGameState_Unit UnitState, SourceUnit;
	local int SourceObjectID, TargetObjectID;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (!bCleansed)
	{
		if (UnitState.IsAlive())
		{
			UnitState.SetCurrentStat(eStat_HP, 0);
			UnitState.OnUnitBledOut(NewGameState, PersistentEffect, ApplyEffectParameters.SourceStateObjectRef, ApplyEffectParameters);
		}
	}
	else
	{
		AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
		if (AbilityContext != none)
		{
			SourceRef = AbilityContext.InputContext.SourceObject;
			TargetObjectID = UnitState.ObjectID;
			SourceObjectID = SourceRef.ObjectID;
			SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SourceObjectID));
			if (SourceObjectID != TargetObjectID && SourceUnit.CanEarnSoldierRelationshipPoints(UnitState)) // pmiller - so that you can't have a relationship with yourself
			{
				SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', SourceObjectID));
				if ( SourceUnit.CanEarnSoldierRelationshipPoints(UnitState) && !AbilityContext.IsEvacContext() )
				{
					UnitState.AddToSquadmateScore(SourceUnit.ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_Stabilize);
					SourceUnit.AddToSquadmateScore(UnitState.ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_Stabilize);
				}
			}
		}
	}

	`XEVENTMGR.TriggerEvent('UnitBleedingOutRemoved', UnitState, UnitState, NewGameState);

	UnitState.bBleedingOut = false;
}

static function BleedingOutCleansedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameStateContext_Ability  Context;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2AbilityTemplate AbilityTemplate;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good);
}

static function BleedingOutVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());
	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.BleedingOutFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_BleedingOut);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.BleedingOutEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BleedingOutTitle,
		"img:///UILibrary_PerkIcons.UIPerk_willtosurvive",
		eUIState_Bad);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function BleedingOutVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	// dead units should not be reported
	if( UnitState == None || UnitState.IsDead() )
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.BleedingOutEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BleedingOutTitle,
		"img:///UILibrary_PerkIcons.UIPerk_willtosurvive",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function int GetBleedOutChance(XComGameState_Unit UnitState, int OverkillDamage)
{
	return UnitState.GetCurrentStat(eStat_Will) - default.BLEEDOUT_BASE;
}

//this just adds the rupture flyover text, any sort of checking if this should happen, should happen elsewhere.
static function RuptureVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	if (!ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
		return;

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.RupturedFriendlyName, 'Ruptured', eColor_Bad);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.RupturedEffectAcquiredString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BleedingTitle,
		"img:///UILibrary_XPACK_Common.UIPerk_bleeding",
		eUIState_Bad);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function X2Effect_Burning CreateBurningStatusEffect(int DamagePerTick, int DamageSpreadPerTick)
{
	local X2Effect_Burning BurningEffect;
	local X2Condition_UnitProperty UnitPropCondition;

	BurningEffect = new class'X2Effect_Burning';
	BurningEffect.EffectName = default.BurningName;
	BurningEffect.BuildPersistentEffect(default.BURNING_TURNS,, false,,eGameRule_PlayerTurnBegin);
	BurningEffect.SetDisplayInfo(ePerkBuff_Penalty, default.BurningFriendlyName, default.BurningFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_burn");
	BurningEffect.SetBurnDamage(DamagePerTick, DamageSpreadPerTick, 'Fire');
	BurningEffect.VisualizationFn = BurningVisualization;
	BurningEffect.EffectTickedVisualizationFn = BurningVisualizationTicked;
	BurningEffect.EffectRemovedVisualizationFn = BurningVisualizationRemoved;
	BurningEffect.bRemoveWhenTargetDies = true;
	BurningEffect.DamageTypes.AddItem('Fire');
	BurningEffect.DuplicateResponse = eDupe_Refresh;
	BurningEffect.bCanTickEveryAction = true;
	BurningEffect.EffectAppliedEventName = class'X2Effect_Burning'.default.BurningEffectAddedEventName;

	if (default.FireEnteredParticle_Name != "")
	{
		BurningEffect.VFXTemplateName = default.FireEnteredParticle_Name;
		BurningEffect.VFXSocket = default.FireEnteredSocket_Name;
		BurningEffect.VFXSocketsArrayName = default.FireEnteredSocketsArray_Name;
	}
	BurningEffect.PersistentPerkName = default.FireEnteredPerk_Name;

	BurningEffect.EffectTickedFn = BurningTicked;

	UnitPropCondition = new class'X2Condition_UnitProperty';
	UnitPropCondition.ExcludeFriendlyToSource = false;
	BurningEffect.TargetConditions.AddItem(UnitPropCondition);

	return BurningEffect;
}

static function X2Effect CreateBurningSpreadEffect()
{
	local X2Effect BurningSpreadEffect;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_Visibility TargetVisibilityCondition;

	// TODO: DISCUSS WITH DESIGN ON WHAT THE SPREAD BURNING DAMAGE SHOULD BE
	BurningSpreadEffect = CreateBurningStatusEffect(1, 0);

	BurningSpreadEffect.ApplyChance = default.BURNING_INFECT_PERCENTAGE;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeCivilian = true;
	UnitPropertyCondition.FailOnNonUnits = true;
	BurningSpreadEffect.TargetConditions.AddItem(UnitPropertyCondition);

	// don't allow burning to infect through walls
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bCannotPeek = true;
	BurningSpreadEffect.TargetConditions.AddItem(TargetVisibilityCondition);

	return BurningSpreadEffect;
}

// At start of each turn, burning units can set fire to nearby units.
function bool BurningTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit TargetUnit;
	local XComGameState_Unit PlayerUnit;

	local EffectAppliedData BurningEffectAppliedData;
	local X2Effect BurningSpreadEffect;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
		return true; // effect is done

	// create the burning effect template
	BurningSpreadEffect = CreateBurningSpreadEffect();
	if (BurningSpreadEffect == none)
		return true; // effect is done

	// iterate thorugh all player units
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', PlayerUnit)
	{
		// skip if it's the same unit
		if (PlayerUnit.ObjectID == TargetUnit.ObjectID)
			continue;

		// skip if unit is not within range
		if (PlayerUnit.TileDistanceBetween(TargetUnit) > default.BURNING_INFECT_DISTANCE)
			continue;

		// skip if the unit is not an allowed type
		if (default.BURNING_SPREAD_ALLOWED_UNIT_TYPES.Find(PlayerUnit.GetMyTemplate().CharacterGroupName) == INDEX_NONE)
			continue;

		// make a copy of the ApplyEffectParameters, and set the source and target appropriately
		BurningEffectAppliedData = ApplyEffectParameters;
		BurningEffectAppliedData.SourceStateObjectRef = TargetUnit.GetReference();
		BurningEffectAppliedData.TargetStateObjectRef = PlayerUnit.GetReference();

		if (BurningSpreadEffect.ApplyEffect(BurningEffectAppliedData, PlayerUnit, NewGameState) == 'AA_Success')
		{
			if (NewGameState.GetContext().PostBuildVisualizationFn.Find(BurningSpreadVisualization) == INDEX_NONE)
				NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BurningSpreadVisualization);
		}
	}

	return false; // effect persists
}


static function BurningSpreadVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local XComGameState_Effect OldEffectState;
	local XComGameState_Unit EffectTarget;
	local X2VisualizerInterface VisualizerInterface;
	local VisualizationActionMetadata BuildTrack;
	local VisualizationActionMetadata EmptyTrack;

	History = `XCOMHISTORY;

	//Find any newly-applied burning effects and visualize them here.
	//(the normal Context_TickEffect doesn't handle these, because they're not in EffectTemplate.ApplyOnTick - and they get applied to other units) 
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		EffectTarget = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		if (EffectTarget == None)
			continue;

		OldEffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectState.ObjectID, , VisualizeGameState.HistoryIndex - 1));
		if (OldEffectState != None) //Not a new effect - don't visualize here
			continue;

		BuildTrack = EmptyTrack;
		BuildTrack.VisualizeActor = History.GetVisualizer(EffectTarget.ObjectID);
		VisualizerInterface = X2VisualizerInterface(BuildTrack.VisualizeActor);

		History.GetCurrentAndPreviousGameStatesForObjectID(EffectTarget.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
		if (BuildTrack.StateObject_NewState == none)
			BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
		else if (BuildTrack.StateObject_OldState == none)
			BuildTrack.StateObject_OldState = BuildTrack.StateObject_NewState;

		//Add the normal "burning" visualization
		EffectState.GetX2Effect().AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');

		//Allow for target being killed/etc
		if (VisualizerInterface != none)
			VisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
	}

}

static function BurningVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{

	if (EffectApplyResult != 'AA_Success')
		return;
	if (!ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
		return;

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.BurningFriendlyName, 'Burning', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Burning);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.BurningEffectAcquiredString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BurningTitle,
		"img:///UILibrary_PerkIcons.UIPerk_burn",
		eUIState_Bad);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function BurningVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	// dead units should not be reported
	if(UnitState == None || UnitState.IsDead() )
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.BurningEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BurningTitle,
		"img:///UILibrary_PerkIcons.UIPerk_burn",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function BurningVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	// dead units should not be reported
	if(UnitState == None || UnitState.IsDead() )
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.BurningEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BurningTitle,
		"img:///UILibrary_PerkIcons.UIPerk_burn",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}


static function X2Effect_Burning CreateAcidBurningStatusEffect(int DamagePerTick, int DamageSpreadPerTick)
{
	local X2Effect_Burning BurningEffect;
	local X2Condition_UnitProperty UnitPropCondition;

	BurningEffect = new class'X2Effect_Burning';
	BurningEffect.EffectName = default.AcidBurningName;
	BurningEffect.BuildPersistentEffect(default.ACID_BURNING_TURNS, , false, , eGameRule_PlayerTurnBegin);
	BurningEffect.SetDisplayInfo(ePerkBuff_Penalty, default.AcidBurningFriendlyName, default.AcidBurningFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_burn");
	BurningEffect.SetBurnDamage(DamagePerTick, DamageSpreadPerTick, 'Acid');
	BurningEffect.VisualizationFn = AcidBurningVisualization;
	BurningEffect.EffectTickedVisualizationFn = AcidBurningVisualizationTicked;
	BurningEffect.EffectRemovedVisualizationFn = AcidBurningVisualizationRemoved;
	BurningEffect.bRemoveWhenTargetDies = true;
	BurningEffect.DamageTypes.Length = 0;   // By default X2Effect_Burning has a damage type of fire, but acid is not fire
	BurningEffect.DamageTypes.InsertItem(0, 'Acid');
	BurningEffect.DuplicateResponse = eDupe_Refresh;
	BurningEffect.bCanTickEveryAction = true;

	if (default.AcidEnteredParticle_Name != "")
	{
		BurningEffect.VFXTemplateName = default.AcidEnteredParticle_Name;
		BurningEffect.VFXSocket = default.AcidEnteredSocket_Name;
		BurningEffect.VFXSocketsArrayName = default.AcidEnteredSocketsArray_Name;
	}
	BurningEffect.PersistentPerkName = default.AcidEnteredPerk_Name;

	UnitPropCondition = new class'X2Condition_UnitProperty';
	UnitPropCondition.ExcludeFriendlyToSource = false;
	BurningEffect.TargetConditions.AddItem(UnitPropCondition);

	return BurningEffect;
}

static function AcidBurningVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	if (EffectApplyResult != 'AA_Success')
		return;
	if (!ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
		return;

	class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), class'X2StatusEffects'.default.AcidBurningFriendlyName, 'Acid', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Burning);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.AcidBurningEffectAcquiredString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.AcidBurningTitle,
		"img:///UILibrary_PerkIcons.UIPerk_burn",
		eUIState_Bad);
	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function AcidBurningVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if (UnitState == None || UnitState.IsDead())
		return;

	AddEffectMessageToTrack(
		ActionMetadata,
		default.AcidBurningEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.AcidBurningTitle,
		"img:///UILibrary_PerkIcons.UIPerk_burn",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function AcidBurningVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if (UnitState == None || UnitState.IsDead())
		return;

	AddEffectMessageToTrack(
		ActionMetadata,
		default.AcidBurningEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.AcidBurningTitle,
		"img:///UILibrary_PerkIcons.UIPerk_burn",
		eUIState_Good);
	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}


static function X2Effect_PersistentStatChange CreateConfusedStatusEffect(int NumTurns)
{
	local X2Effect_Confused			PersistentStatChangeEffect;
	local X2Condition_UnitProperty	UnitPropCondition;

	PersistentStatChangeEffect = new class'X2Effect_Confused';
	PersistentStatChangeEffect.EffectName = class'X2AbilityTemplateManager'.default.ConfusedName;
	PersistentStatChangeEffect.DuplicateResponse = eDupe_Refresh;
	PersistentStatChangeEffect.BuildPersistentEffect(NumTurns,, false,,eGameRule_PlayerTurnBegin);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Penalty, default.ConfusedFriendlyName, default.ConfusedFriendlyDesc, "UILibrary_XPACK_Common.PerkIcons.UIPerk_chosendazed");
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.CONFUSED_MOBILITY_ADJUST);
	PersistentStatChangeEffect.VisualizationFn = ConfusedVisualization;
	PersistentStatChangeEffect.EffectTickedVisualizationFn = ConfusedVisualizationTicked;
	PersistentStatChangeEffect.EffectRemovedVisualizationFn = ConfusedVisualizationRemoved;
	PersistentStatChangeEffect.EffectHierarchyValue = default.CONFUSED_HIERARCHY_VALUE;
	PersistentStatChangeEffect.bRemoveWhenTargetDies = true;
	PersistentStatChangeEffect.bCanTickEveryAction = true;

	UnitPropCondition = new class'X2Condition_UnitProperty';
	UnitPropCondition.ExcludeFriendlyToSource = false;
	PersistentStatChangeEffect.TargetConditions.AddItem(UnitPropCondition);

	return PersistentStatChangeEffect;
}

static function ConfusedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.ConfusedFriendlyName, 'Confused', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Confused);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.ConfusedEffectAcquiredString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.ConfusedTitle,
		"UILibrary_XPACK_Common.PerkIcons.UIPerk_chosendazed",
		eUIState_Bad);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function ConfusedVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	// dead units should not be reported
	if( UnitState == None || UnitState.IsDead() )
	{
		return;
	}

	AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());
	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.ConfusedFriendlyName, 'Confused', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Confused);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.ConfusedEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.ConfusedTitle,
		"UILibrary_XPACK_Common.PerkIcons.UIPerk_chosendazed",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function ConfusedVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	// dead units should not be reported
	if(UnitState == None || UnitState.IsDead() )
	{
		return;
	}

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.ConfusedLostFriendlyName, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Confused, 2.0f);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.ConfusedEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.ConfusedTitle,
		"UILibrary_XPACK_Common.PerkIcons.UIPerk_chosendazed",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}


static function X2Effect_PersistentStatChange CreateDisorientedStatusEffect(optional bool bExcludeFriendlyToSource=false, float DelayVisualizationSec=0.0f, optional bool bIsMentalDamage = true)
{
	local X2Effect_PersistentStatChange     PersistentStatChangeEffect;
	local X2Condition_UnitProperty			UnitPropCondition;

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.EffectName = class'X2AbilityTemplateManager'.default.DisorientedName;
	PersistentStatChangeEffect.DuplicateResponse = eDupe_Refresh;
	PersistentStatChangeEffect.BuildPersistentEffect(default.DISORIENTED_TURNS,, false,,eGameRule_PlayerTurnBegin);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Penalty, default.DisorientedFriendlyName, default.DisorientedFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_disoriented");
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.DISORIENTED_MOBILITY_ADJUST);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Offense, default.DISORIENTED_AIM_ADJUST);
	PersistentStatChangeEffect.VisualizationFn = DisorientedVisualization;
	PersistentStatChangeEffect.EffectTickedVisualizationFn = DisorientedVisualizationTicked;
	PersistentStatChangeEffect.EffectRemovedVisualizationFn = DisorientedVisualizationRemoved;
	PersistentStatChangeEffect.EffectHierarchyValue = default.DISORIENTED_HIERARCHY_VALUE;
	PersistentStatChangeEffect.bRemoveWhenTargetDies = true;
	PersistentStatChangeEffect.bIsImpairingMomentarily = true;

	// Start Issue #475
	PersistentStatChangeEffect.bForceReapplyOnRefresh = true;
	// End Issue #475

	PersistentStatChangeEffect.DamageTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.DisorientDamageType);
	if( bIsMentalDamage )
	{
		PersistentStatChangeEffect.DamageTypes.AddItem('Mental');
	}
	PersistentStatChangeEffect.EffectAddedFn = DisorientedAdded;
	PersistentStatChangeEffect.DelayVisualizationSec = DelayVisualizationSec;
	PersistentStatChangeEffect.bCanTickEveryAction = true;

	if (default.DisorientedParticle_Name != "")
	{
		PersistentStatChangeEffect.VFXTemplateName = default.DisorientedParticle_Name;
		PersistentStatChangeEffect.VFXSocket = default.DisorientedSocket_Name;
		PersistentStatChangeEffect.VFXSocketsArrayName = default.DisorientedSocketsArray_Name;
	}

	UnitPropCondition = new class'X2Condition_UnitProperty';
	UnitPropCondition.ExcludeFriendlyToSource = bExcludeFriendlyToSource;
	UnitPropCondition.ExcludeRobotic = true;
	PersistentStatChangeEffect.TargetConditions.AddItem(UnitPropCondition);

	return PersistentStatChangeEffect;
}

static function DisorientedAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	//Being disoriented removes overwatch.
	if (XComGameState_Unit(kNewTargetState) != None)
	{
		XComGameState_Unit(kNewTargetState).ReserveActionPoints.Length = 0;
	}
		
}

static function DisorientedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	if (EffectApplyResult != 'AA_Success')
	{
		return;
	}

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if (UnitState != none && !UnitState.IsRobotic())
	{
		AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.DisorientedFriendlyName, 'Confused', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Disoriented);
		AddEffectMessageToTrack(
			ActionMetadata,
			default.DisorientedEffectAcquiredString,
			VisualizeGameState.GetContext(),
			class'UIEventNoticesTactical'.default.DisorientedTitle,
			"img:///UILibrary_PerkIcons.UIPerk_disoriented",
			eUIState_Bad);
		UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
	}
}

static function DisorientedVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.DisorientedFriendlyName, 'TurnWhileConfused', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Disoriented);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.DisorientedEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.DisorientedTitle,
		"img:///UILibrary_PerkIcons.UIPerk_disoriented",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function DisorientedVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.DisorientedLostFriendlyName, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Disoriented, 2.0f);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.DisorientedEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.DisorientedTitle,
		"img:///UILibrary_PerkIcons.UIPerk_disoriented",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function X2Effect_MindControl CreateMindControlStatusEffect(int NumTurns, bool bRobotic=false, bool bIsInfinite=false, float DelayVisualizationSec=0.0f)
{
	local X2Effect_MindControl MindControlEffect;
	local X2Condition_UnitEffects	EffectCondition;

	MindControlEffect = new class'X2Effect_MindControl';
	`Log("Setting MindControlStatus with NumTurns="$NumTurns,,'XCom_Templates');
	MindControlEffect.iNumTurns = NumTurns;
	MindControlEffect.bInfiniteDuration = bIsInfinite;
	MindControlEffect.SetDisplayInfo(ePerkBuff_Penalty, 
									 bRobotic?default.HackedUnitFriendlyName:default.MindControlFriendlyName, 
									 bRobotic?default.HackedUnitFriendlyDesc:default.MindControlFriendlyDesc, 
									 "img:///UILibrary_PerkIcons.UIPerk_domination",
									 true,
									 class'UIUtilities_Image'.const.UnitStatus_MindControlled);
	if(!bRobotic)
	{
		MindControlEffect.SetSourceDisplayInfo(ePerkBuff_Bonus, default.MindControlSourceFriendlyName, default.MindControlSourceFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_domination");
	}

	EffectCondition = new class'X2Condition_UnitEffects';
	EffectCondition.AddExcludeEffect(class'X2Effect_Battlelord'.default.EffectName, 'AA_UnitIsImmune');
	EffectCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_UnitIsImmune');
	MindControlEffect.TargetConditions.AddItem(EffectCondition);

	MindControlEffect.DelayVisualizationSec = DelayVisualizationSec;
	MindControlEffect.VisualizationFn = MindControlVisualization;
	MindControlEffect.EffectTickedVisualizationFn = MindControlVisualizationTicked;
	MindControlEffect.EffectRemovedVisualizationFn = MindControlVisualizationRemoved;
	MindControlEffect.EffectHierarchyValue = default.MINDCONTROL_HIERARCHY_VALUE;

	return MindControlEffect;
}

static function X2Effect_RemoveEffects CreateMindControlRemoveEffects()
{
	local X2Effect_RemoveEffects RemoveEffects;

	// remove other impairing mental effects
	RemoveEffects = new class'X2Effect_RemoveEffects'; 
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.ConfusedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DazedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.ObsessedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.BerserkName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.ShatteredName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Ability_AdvPriest'.default.HolyWarriorEffectName);
	RemoveEffects.DamageTypes.AddItem('mental'); 

	return RemoveEffects;
}

static function MindControlVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit kUnit;

	if (EffectApplyResult != 'AA_Success')
	{
		AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.ResistedMindControlText, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_MindControlled);
		return;
	}
	
	kUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (kUnit != none)
	{
		class'X2Action_MindControlled'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);

		if(kUnit.IsRobotic())
		{
			AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.HackedUnitFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Haywire);
			AddEffectMessageToTrack(
				ActionMetadata,
				default.HackedUnitEffectAcquiredString,
				VisualizeGameState.GetContext(),
				class'UIEventNoticesTactical'.default.DominationTitle,
				"img:///UILibrary_PerkIcons.UIPerk_domination",
				eUIState_Bad);
		}
		else
		{
			AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.MindControlFriendlyName, 'SoldierControlled', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_MindControlled);
			AddEffectMessageToTrack(
				ActionMetadata,
				default.MindControlEffectAcquiredString,
				VisualizeGameState.GetContext(),
				class'UIEventNoticesTactical'.default.DominationTitle,
				"img:///UILibrary_PerkIcons.UIPerk_domination",
				eUIState_Bad);
		}

		UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());		
	}
}

static function MindControlVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Effect MindControlState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	// infinite-duration mind-control effects should not be reported every turn
	MindControlState = UnitState.GetUnitAffectedByEffectState(class'X2Effect_MindControl'.default.EffectName);
	if (MindControlState != None && MindControlState.GetX2Effect().bInfiniteDuration)
	{
		return;
	}

	AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());
	if(UnitState.IsRobotic() ) 
	{
		AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.HackedUnitFriendlyName, 'SoldierControlled', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Haywire);
		AddEffectMessageToTrack(
			ActionMetadata,
			default.HackedUnitEffectTickedString,
			VisualizeGameState.GetContext(),
			class'UIEventNoticesTactical'.default.DominationTitle,
			"img:///UILibrary_PerkIcons.UIPerk_domination",
			eUIState_Warning);
	}
	else
	{
		AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.MindControlFriendlyName, 'SoldierControlled', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_MindControlled);
		AddEffectMessageToTrack(
			ActionMetadata,
			default.MindControlEffectTickedString,
			VisualizeGameState.GetContext(),
			class'UIEventNoticesTactical'.default.DominationTitle,
			"img:///UILibrary_PerkIcons.UIPerk_domination",
			eUIState_Warning);
	}
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function MindControlVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	class'X2Action_SwapTeams'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);

	if( UnitState.IsRobotic() )
	{
		AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.HackedUnitLostFriendlyName, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Haywire, 2.0f);
		AddEffectMessageToTrack(
			ActionMetadata,
			default.HackedUnitEffectLostString,
			VisualizeGameState.GetContext(),
			class'UIEventNoticesTactical'.default.DominationTitle,
			"img:///UILibrary_PerkIcons.UIPerk_domination",
			eUIState_Good);
	}
	else
	{
		AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.MindControlLostFriendlyName, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_MindControlled, 2.0f);
		AddEffectMessageToTrack(
			ActionMetadata,
			default.MindControlEffectLostString,
			VisualizeGameState.GetContext(),
			class'UIEventNoticesTactical'.default.DominationTitle,
			"img:///UILibrary_PerkIcons.UIPerk_domination",
			eUIState_Good);
	}
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}



static function X2Effect_PersistentStatChange CreatePoisonedStatusEffect()
{
	local X2Effect_PersistentStatChange     PersistentStatChangeEffect;
	local X2Effect_ApplyWeaponDamage              DamageEffect;
	local X2Condition_UnitProperty UnitPropCondition;

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.EffectName = default.PoisonedName;
	PersistentStatChangeEffect.DuplicateResponse = eDupe_Refresh;
	PersistentStatChangeEffect.BuildPersistentEffect(default.POISONED_TURNS,, false,,eGameRule_PlayerTurnBegin);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Penalty, default.PoisonedFriendlyName, default.PoisonedFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_poisoned");
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.POISONED_MOBILITY_ADJUST);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Offense, default.POISONED_AIM_ADJUST);
	PersistentStatChangeEffect.iInitialShedChance = default.POISONED_INITIAL_SHED;
	PersistentStatChangeEffect.iPerTurnShedChance = default.POISONED_PER_TURN_SHED;
	PersistentStatChangeEffect.VisualizationFn = PoisonedVisualization;
	PersistentStatChangeEffect.EffectTickedVisualizationFn = PoisonedVisualizationTicked;
	PersistentStatChangeEffect.EffectRemovedVisualizationFn = PoisonedVisualizationRemoved;
	PersistentStatChangeEffect.DamageTypes.AddItem('Poison');
	PersistentStatChangeEffect.bRemoveWhenTargetDies = true;
	PersistentStatChangeEffect.bCanTickEveryAction = true;
	PersistentStatChangeEffect.EffectAppliedEventName = 'PoisonedEffectAdded';

	if (default.PoisonEnteredParticle_Name != "")
	{
		PersistentStatChangeEffect.VFXTemplateName = default.PoisonEnteredParticle_Name;
		PersistentStatChangeEffect.VFXSocket = default.PoisonEnteredSocket_Name;
		PersistentStatChangeEffect.VFXSocketsArrayName = default.PoisonEnteredSocketsArray_Name;
	}
	PersistentStatChangeEffect.PersistentPerkName = default.PoisonEnteredPerk_Name;

	UnitPropCondition = new class'X2Condition_UnitProperty';
	UnitPropCondition.ExcludeFriendlyToSource = false;
	UnitPropCondition.ExcludeRobotic = true;
	PersistentStatChangeEffect.TargetConditions.AddItem(UnitPropCondition);

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.EffectDamageValue.Damage = default.POISONED_DAMAGE;
	DamageEffect.EffectDamageValue.DamageType = 'Poison';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTypes.AddItem('Poison');
	DamageEffect.bAllowFreeKill = false;
	DamageEffect.bIgnoreArmor = true;
	/// HL-Docs: feature:BurningAndPoisonedDamageBypassesShields; issue:89; tags:tactical
	/// In base game, shields (eStat_ShieldHP) absorb damage from typical damage over time effects, 
	/// such as burning or poisoned. Mods can override this behavior by setting the following
	/// flags in `XComGameCore.ini`:
	///
	///```ini
	///[XComGame.X2Effect_Burning]
	///BURNED_IGNORES_SHIELDS=true ; Make burn and acid DOT ignore shields
	///
	///[XComGame.X2StatusEffects]
	///POISONED_IGNORES_SHIELDS=true ; Make poison DOT ignore shields
	///```
	/// Note that `BURNED_IGNORES_SHIELDS` will apply to all instances of `X2Effect_Burning` that
	/// use its `SetBurnDamage()` helper method to set up the burn damage effect.
	///
	/// `POISONED_IGNORES_SHIELDS` will apply to all instances of posioned effect created using 
	/// the `X2StatusEffect::CreatePoisonedStatusEffect()` helper method.
	///
	/// This should cover all instance of these effects in the base game, but mods can potentially
	/// disregard these helper methods.
	///
	/// [Refer to this feature](../tactical/BleedingDamageBypassesShields.md) to apply similar change to bleeding damage over time.
	DamageEffect.bBypassShields = default.POISONED_IGNORES_SHIELDS; // Issue #89
	PersistentStatChangeEffect.ApplyOnTick.AddItem(DamageEffect);

	PersistentStatChangeEffect.EffectTickedFn = PoisonTicked;

	return PersistentStatChangeEffect;
}

static function X2Effect CreatePoisonedSpreadEffect()
{
	local X2Effect PoisonSpreadEffect;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_Visibility TargetVisibilityCondition;
		
	PoisonSpreadEffect = CreatePoisonedStatusEffect();

	PoisonSpreadEffect.ApplyChance = default.POISONED_INFECT_PERCENTAGE;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeCivilian = true;
	UnitPropertyCondition.FailOnNonUnits = true;
	PoisonSpreadEffect.TargetConditions.AddItem(UnitPropertyCondition);

	// don't allow poison to infect through walls
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bCannotPeek = true;
	PoisonSpreadEffect.TargetConditions.AddItem(TargetVisibilityCondition);

	return PoisonSpreadEffect;
}

// At start of each turn, poisoned units can infect nearby units.
function bool PoisonTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit TargetUnit;
	local XComGameState_Unit PlayerUnit;

	local EffectAppliedData PoisonEffectAppliedData;
	local X2Effect PoisonSpreadEffect;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
		return true; // effect is done

	// create the poison effect template
	PoisonSpreadEffect = CreatePoisonedSpreadEffect();
	if (PoisonSpreadEffect == none)
		return true; // effect is done

	// iterate thorugh all player units
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', PlayerUnit)
	{
		// skip if it's the same unit
		if (PlayerUnit.ObjectID == TargetUnit.ObjectID)
			continue;

		// skip if unit is not within range
		if (PlayerUnit.TileDistanceBetween(TargetUnit) > default.POISONED_INFECT_DISTANCE)
			continue;

		// make a copy of the ApplyEffectParameters, and set the source and target appropriately
		PoisonEffectAppliedData = ApplyEffectParameters; 
		PoisonEffectAppliedData.SourceStateObjectRef = TargetUnit.GetReference();
		PoisonEffectAppliedData.TargetStateObjectRef = PlayerUnit.GetReference();

		if (PoisonSpreadEffect.ApplyEffect(PoisonEffectAppliedData, PlayerUnit, NewGameState) == 'AA_Success')
		{
			if (NewGameState.GetContext().PostBuildVisualizationFn.Find(PoisonSpreadVisualization) == INDEX_NONE)
				NewGameState.GetContext().PostBuildVisualizationFn.AddItem(PoisonSpreadVisualization);
		}
	}

	return false; // effect persists
}

static function PoisonSpreadVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local XComGameState_Effect OldEffectState;
	local XComGameState_Unit EffectTarget;
	local X2VisualizerInterface VisualizerInterface;
	local VisualizationActionMetadata ActionMetadata;
	local VisualizationActionMetadata EmptyTrack;

	History = `XCOMHISTORY;

	//Find any newly-applied poison effects and visualize them here.
	//(the normal Context_TickEffect doesn't handle these, because they're not in EffectTemplate.ApplyOnTick - and they get applied to other units) 
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		EffectTarget = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		if (EffectTarget == None)
			continue;

		OldEffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectState.ObjectID, , VisualizeGameState.HistoryIndex - 1));
		if (OldEffectState != None) //Not a new effect - don't visualize here
			continue;

		ActionMetadata = EmptyTrack;
		ActionMetadata.VisualizeActor = History.GetVisualizer(EffectTarget.ObjectID);
		VisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);

		History.GetCurrentAndPreviousGameStatesForObjectID(EffectTarget.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
		if (ActionMetadata.StateObject_NewState == none)
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
		else if (ActionMetadata.StateObject_OldState == none)
			ActionMetadata.StateObject_OldState = ActionMetadata.StateObject_NewState;

		//Add the normal "poisoned" visualization
		EffectState.GetX2Effect().AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');

		//Allow for target being killed/etc
		if (VisualizerInterface != none)
			VisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
	}
}

static function PoisonedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}

	if (ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.PoisonedFriendlyName, 'Poison', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Poisoned);
		AddEffectMessageToTrack(
			ActionMetadata,
			default.PoisonedEffectAcquiredString,
			VisualizeGameState.GetContext(),
			class'UIEventNoticesTactical'.default.PoisonedTitle,
			"img:///UILibrary_PerkIcons.UIPerk_poisoned",
			eUIState_Bad);
		UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
	}
}

static function PoisonedVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.PoisonedEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.PoisonedTitle,
		"img:///UILibrary_PerkIcons.UIPerk_poisoned",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function PoisonedVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.PoisonedEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.PoisonedTitle,
		"img:///UILibrary_PerkIcons.UIPerk_poisoned",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}


static function X2Effect_Stunned CreateStunnedStatusEffect(int StunLevel, int Chance, optional bool bIsMentalDamage = true)
{
	local X2Effect_Stunned StunnedEffect;
	local X2Condition_UnitProperty UnitPropCondition;

	StunnedEffect = new class'X2Effect_Stunned';
	StunnedEffect.BuildPersistentEffect(1, true, true, false, eGameRule_UnitGroupTurnBegin);
	StunnedEffect.ApplyChance = Chance;
	StunnedEffect.StunLevel = StunLevel;
	StunnedEffect.bIsImpairing = true;
	StunnedEffect.EffectHierarchyValue = default.STUNNED_HIERARCHY_VALUE;
	StunnedEffect.EffectName = class'X2AbilityTemplateManager'.default.StunnedName;
	StunnedEffect.VisualizationFn = StunnedVisualization;
	StunnedEffect.EffectTickedVisualizationFn = StunnedVisualizationTicked;
	StunnedEffect.EffectRemovedVisualizationFn = StunnedVisualizationRemoved;
	StunnedEffect.EffectRemovedFn = StunnedEffectRemoved;
	StunnedEffect.bRemoveWhenTargetDies = true;
	StunnedEffect.bCanTickEveryAction = true;

	if( bIsMentalDamage )
	{
		StunnedEffect.DamageTypes.AddItem('Mental');
	}

	if (default.StunnedParticle_Name != "")
	{
		StunnedEffect.VFXTemplateName = default.StunnedParticle_Name;
		StunnedEffect.VFXSocket = default.StunnedSocket_Name;
		StunnedEffect.VFXSocketsArrayName = default.StunnedSocketsArray_Name;
	}

	UnitPropCondition = new class'X2Condition_UnitProperty';
	UnitPropCondition.ExcludeFriendlyToSource = false;
	UnitPropCondition.FailOnNonUnits = true;
	StunnedEffect.TargetConditions.AddItem(UnitPropCondition);

	return StunnedEffect;
}

static function StunnedEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	EventManager.TriggerEvent('UnitStunnedRemoved', UnitState, UnitState, NewGameState);
}

static function X2Effect_StunRecover CreateStunRecoverEffect()
{
	local X2Effect_StunRecover StunRecover;

	StunRecover = new class'X2Effect_StunRecover';

	return StunRecover;
}

private static function string GetStunnedFlyoverText(XComGameState_Unit TargetState, bool FirstApplication)
{
	local XComGameState_Effect EffectState;
	local X2AbilityTag AbilityTag;
	local bool bRobotic;
	local string ExpandedString; // bsg-dforrest (7.27.17): need to clear out ParseObject

	bRobotic = TargetState.IsRobotic();
	EffectState = TargetState.GetUnitAffectedByEffectState('Stunned');
	if(FirstApplication || (EffectState != none && EffectState.GetX2Effect().IsTickEveryAction(TargetState)))
	{
		AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
		AbilityTag.ParseObj = TargetState;
		// bsg-dforrest (7.27.17): need to clear out ParseObject
		ExpandedString = `XEXPAND.ExpandString(bRobotic ? default.RoboticStunnedPerActionFriendlyName : default.StunnedPerActionFriendlyName);
		AbilityTag.ParseObj = none;
		return ExpandedString;
		// bsg-dforrest (7.27.17): end
	}
	else
	{
		return bRobotic ? default.RoboticStunnedFriendlyName : default.StunnedFriendlyName;
	}
}

static function StunnedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit TargetState;
	local bool bRobotic;

	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}

	TargetState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(ActionMetadata.StateObject_NewState.ObjectID));
	if (TargetState == none)
		return;

	bRobotic = TargetState.IsRobotic();
	
	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), GetStunnedFlyoverText(TargetState, true), '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Stunned);
	AddEffectMessageToTrack(
		ActionMetadata,
		bRobotic ? default.RoboticStunnedEffectAcquiredString : default.StunnedEffectAcquiredString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.StunnedTitle,
		"img:///UILibrary_Common.status_stunned",
		eUIState_Bad);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function StunnedVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local bool bRobotic;

	UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(ActionMetadata.StateObject_NewState.ObjectID));
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	bRobotic = UnitState.IsRobotic();

	AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());
	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), GetStunnedFlyoverText(UnitState, false), '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Stunned);
	AddEffectMessageToTrack(
		ActionMetadata,
		bRobotic ? default.RoboticStunnedEffectTickedString : default.StunnedEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.StunnedTitle,
		"img:///UILibrary_Common.status_stunned",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function StunnedVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local bool bRobotic;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	bRobotic = UnitState.IsRobotic();

	AddEffectMessageToTrack(
		ActionMetadata,
		bRobotic ? default.RoboticStunnedEffectLostString : default.StunnedEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.StunnedTitle,
		"img:///UILibrary_Common.status_stunned",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}


static function X2Effect_Persistent CreateUnconsciousStatusEffect(bool bIsMentalDamage = false, bool bNoDamageType = false)
{
	local X2Effect_Persistent   PersistentEffect;

	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.EffectName = default.UnconsciousName;
	PersistentEffect.DuplicateResponse = eDupe_Ignore;
	PersistentEffect.BuildPersistentEffect(1, true, false);
	PersistentEffect.bRemoveWhenTargetDies = true;
	PersistentEffect.bIsImpairing = true;
	PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, default.UnconsciousFriendlyName, default.UnconsciousFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_stun", true, class'UIUtilities_Image'.const.UnitStatus_Unconscious);
	PersistentEffect.EffectAddedFn = UnconsciousEffectAdded;
	PersistentEffect.EffectRemovedFn = UnconsciousEffectRemoved;
	PersistentEffect.VisualizationFn = UnconsciousVisualization;
	PersistentEffect.EffectTickedVisualizationFn = UnconsciousVisualizationTicked;
	PersistentEffect.EffectRemovedVisualizationFn = UnconsciousVisualizationRemoved;
	PersistentEffect.CleansedVisualizationFn = UnconsciousCleansedVisualization;
	PersistentEffect.EffectHierarchyValue = default.UNCONCIOUS_HIERARCHY_VALUE;

	if (!bNoDamageType)
	{
		PersistentEffect.DamageTypes.AddItem('Unconscious');
		if (bIsMentalDamage)
		{
			PersistentEffect.DamageTypes.AddItem('Mental');
		}
	}

	return PersistentEffect;
}

static function UnconsciousVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local bool bTriggeredByFireAction;

	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}
	if (XComGameState_Unit(ActionMetadata.StateObject_NewState) == none)
		return;

	bTriggeredByFireAction = ActionMetadata.LastActionAdded.IsA(class'X2Action_Fire'.Name);

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.UnconsciousFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Unconscious);

	if (bTriggeredByFireAction)
	{
		//Make it so that this will trigger off of the ability hit message
		ActionMetadata.LastActionAdded.AddInputEvent('Visualizer_AbilityHit');
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.UnconsciousEffectAcquiredString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.UnconsciousTitle,
		"img:///UILibrary_PerkIcons.UIPerk_stun",
		eUIState_Bad);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function UnconsciousVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());
	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.UnconsciousFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Unconscious);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.UnconsciousEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.UnconsciousTitle,
		"img:///UILibrary_PerkIcons.UIPerk_stun",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function UnconsciousVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local X2Action_Knockback KnockBackAction;	
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XGUnit Unit;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	//Don't visualize if the unit is dead or still incapacitated.
	if( UnitState == none || UnitState.IsDead() || UnitState.IsIncapacitated() || UnitState.bRemovedFromPlay )
		return;

	//Don't add duplicate knockback actions.
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	KnockBackAction = X2Action_Knockback(VisualizationMgr.GetNodeOfType(VisualizationMgr.VisualizationTree, class'X2Action_Knockback', ActionMetadata.VisualizeActor));
	if(KnockBackAction == none)
	{
		KnockBackAction = X2Action_Knockback(class'X2Action_Knockback'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	}
	
	KnockBackAction.OnlyRecover = true;

	AddEffectMessageToTrack(
		ActionMetadata,
		default.UnconsciousEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.UnconsciousTitle,
		"img:///UILibrary_PerkIcons.UIPerk_stun",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());

	// Need to reinit the behavior since this is destroyed upon adding the Unconscious effect (via X2Action_Death).
	Unit = XGUnit(UnitState.GetVisualizer());
	if (Unit != None && Unit.m_kBehavior == None)
	{
		Unit.InitBehavior();
	}
}

static function UnconsciousCleansedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	UnconsciousVisualizationRemoved(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

static function UnconsciousEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		UnitState.bUnconscious = true;
		EventManager.TriggerEvent('UnitUnconscious', UnitState, UnitState, NewGameState);
	}
}

static function UnconsciousEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	UnitState.bUnconscious = false;
	UnitState.ClearUnitValue('LadderKilledScored');

	EventManager.TriggerEvent('UnitUnconsciousRemoved', UnitState, UnitState, NewGameState);
}

static function X2Effect_PersistentStatChange CreateBoundStatusEffect(int NumTurns, bool bIsInfinite, bool bOnUnitBeingBound)
{
	local X2Effect_PersistentStatChange     PersistentStatChangeEffect;

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.EffectName = class'X2AbilityTemplateManager'.default.BoundName;
	PersistentStatChangeEffect.DuplicateResponse = eDupe_Refresh;
	PersistentStatChangeEffect.BuildPersistentEffect(NumTurns, bIsInfinite, true,,eGameRule_PlayerTurnBegin);
	if( bOnUnitBeingBound )
	{
		PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Penalty, default.BoundFriendlyName, default.BoundFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_viper_bind");
	}
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.BOUND_MOBILITY_ADJUST, MODOP_PostMultiplication);
	PersistentStatChangeEffect.VisualizationFn = BoundVisualization;
	PersistentStatChangeEffect.EffectTickedVisualizationFn = BoundVisualizationTicked;
	PersistentStatChangeEffect.EffectRemovedVisualizationFn = BoundVisualizationRemoved;
	PersistentStatChangeEffect.EffectHierarchyValue = default.BIND_HIERARCHY_VALUE;
	PersistentStatChangeEffect.bRemoveWhenTargetDies = true;
	PersistentStatChangeEffect.EffectAddedFn = BoundEffectAdded;
	PersistentStatChangeEffect.EffectRemovedFn = BountEffectRemoved;
	PersistentStatChangeEffect.bCanTickEveryAction = true;

	return PersistentStatChangeEffect;
}

static function BoundEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit BindingUnit;
	local XComGameState_Unit BoundUnit;

	BindingUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	BoundUnit = XComGameState_Unit(kNewTargetState);
	if (BindingUnit == none || BoundUnit == none)
		return;

	// Immobilize to prevent scamper, panic, or movement from enabling this unit to move again.
	BoundUnit.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 1, eCleanup_BeginTactical);

	`XEVENTMGR.TriggerEvent('UnitBound', BoundUnit, BindingUnit, NewGameState);
}

static function BountEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	UnitState.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 0);
}

static function BoundVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}

	if (XComGameState_Unit(ActionMetadata.StateObject_NewState) == none)
		return;

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.BoundFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Bound);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.BoundEffectAcquiredString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BoundTitle,
		"img:///UILibrary_PerkIcons.UIPerk_viper_bind",
		eUIState_Bad);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function BoundVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// We have to skip the viper for these visualizations because, although Vipers can never actually be bound through gameplay;,
	// the Viper's Bind ability binds itself for animation visualization reasons.
	if( (UnitState.GetMyTemplateName() == 'Viper') ||
		(UnitState.GetMyTemplateName() == 'ViperMP') )
	{
		return;
	}

	AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());
	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.BoundFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Bound);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.BoundEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BoundTitle,
		"img:///UILibrary_PerkIcons.UIPerk_viper_bind",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function BoundVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	// We have to skip the viper for these visualizations because, although Vipers can never actually be bound through gameplay;,
	// the Viper's Bind ability binds itself for animation visualization reasons.
	if( (UnitState.GetMyTemplateName() == 'Viper') ||
		(UnitState.GetMyTemplateName() == 'ViperMP') )
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.BoundEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BoundTitle,
		"img:///UILibrary_PerkIcons.UIPerk_viper_bind",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}


static function X2Effect_Persistent CreateMarkedEffect(int NumTurns, bool bIsInfinite)
{
	local X2Effect_Persistent PersistentEffect;

	PersistentEffect = new class 'X2Effect_Marked';
	PersistentEffect.EffectName = default.MarkedName;
	PersistentEffect.DuplicateResponse = eDupe_Ignore;
	PersistentEffect.BuildPersistentEffect(NumTurns, bIsInfinite, true,,eGameRule_PlayerTurnEnd);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, default.MarkedFriendlyName, default.MarkedFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_mark");
	PersistentEffect.VisualizationFn = MarkedVisualization;
	PersistentEffect.EffectTickedVisualizationFn = MarkedVisualizationTicked;
	PersistentEffect.EffectRemovedVisualizationFn = MarkedVisualizationRemoved;
	PersistentEffect.bRemoveWhenTargetDies = true;

	return PersistentEffect;
}

static function MarkedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}
	if (XComGameState_Unit(ActionMetadata.StateObject_NewState) == none)
		return;

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.MarkedFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Marked);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.MarkedEffectAcquiredString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.MarkedTitle,
		"img:///UILibrary_PerkIcons.UIPerk_mark",
		eUIState_Bad);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function MarkedVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.MarkedFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Marked);
	AddEffectMessageToTrack(
		ActionMetadata,
		default.MarkedEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.MarkedTitle,
		"img:///UILibrary_PerkIcons.UIPerk_mark",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function MarkedVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if( !UnitState.IsAlive() )
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.MarkedEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.MarkedTitle,
		"img:///UILibrary_PerkIcons.UIPerk_mark",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}


static function X2Effect_Panicked CreatePanickedStatusEffect()
{
	local X2Effect_Panicked     PanickedEffect;

	PanickedEffect = new class'X2Effect_Panicked';
	PanickedEffect.EffectName = class'X2AbilityTemplateManager'.default.PanickedName;
	PanickedEffect.BuildPersistentEffect(default.PANICKED_TURNS, , , , eGameRule_PlayerTurnBegin);  // Because the effect is removed at Begin turn, we add 1 to duration.
	PanickedEffect.AddPersistentStatChange(eStat_Offense, default.PANICKED_AIM_ADJUST);
	PanickedEffect.EffectHierarchyValue = default.PANICKED_HIERARCHY_VALUE;
	PanickedEffect.EffectAppliedEventName = 'PanickedEffectApplied';

	return PanickedEffect;
}

static function X2Effect_Panicked CreateBerserkStatusEffect()
{
	local X2Effect_Panicked     PanickedEffect;

	PanickedEffect = new class'X2Effect_Berserk';
	PanickedEffect.EffectName = class'X2AbilityTemplateManager'.default.BerserkName;
	PanickedEffect.BuildPersistentEffect(default.PANICKED_TURNS, , , , eGameRule_PlayerTurnBegin);  // Because the effect is removed at Begin turn, we add 1 to duration.
	PanickedEffect.AddPersistentStatChange(eStat_Offense, default.PANICKED_AIM_ADJUST_BERSERK);
	PanickedEffect.EffectHierarchyValue = default.PANICKED_HIERARCHY_VALUE;
	PanickedEffect.EffectAppliedEventName = 'PanickedEffectApplied';

	return PanickedEffect;
}

static function X2Effect_Panicked CreateObsessedStatusEffect()
{
	local X2Effect_Panicked     PanickedEffect;

	PanickedEffect = new class'X2Effect_Obsessed';
	PanickedEffect.EffectName = class'X2AbilityTemplateManager'.default.ObsessedName;
	PanickedEffect.BuildPersistentEffect(default.PANICKED_TURNS, , , , eGameRule_PlayerTurnBegin);  // Because the effect is removed at Begin turn, we add 1 to duration.
	PanickedEffect.AddPersistentStatChange(eStat_Offense, default.PANICKED_AIM_ADJUST);
	PanickedEffect.EffectHierarchyValue = default.PANICKED_HIERARCHY_VALUE;
	PanickedEffect.EffectAppliedEventName = 'PanickedEffectApplied';

	return PanickedEffect;
}

static function X2Effect_Panicked CreateShatteredStatusEffect()
{
	local X2Effect_Panicked     PanickedEffect;

	PanickedEffect = new class'X2Effect_Shattered';
	PanickedEffect.EffectName = class'X2AbilityTemplateManager'.default.ShatteredName;
	PanickedEffect.BuildPersistentEffect(default.PANICKED_TURNS, , , , eGameRule_PlayerTurnBegin);  // Because the effect is removed at Begin turn, we add 1 to duration.
	PanickedEffect.AddPersistentStatChange(eStat_Offense, default.PANICKED_AIM_ADJUST);
	PanickedEffect.EffectHierarchyValue = default.PANICKED_HIERARCHY_VALUE;
	PanickedEffect.EffectAppliedEventName = 'PanickedEffectApplied';

	return PanickedEffect;
}

static function X2Effect_Panicked CreateCivilianPanickedStatusEffect()
{
	local X2Effect_Panicked     PanickedEffect;

	PanickedEffect = new class'X2Effect_Panicked';
	PanickedEffect.EffectName = class'X2AbilityTemplateManager'.default.PanickedName;
	PanickedEffect.BuildPersistentEffect(-1, true); // Civilian panic is permanent.
	PanickedEffect.EffectHierarchyValue = default.PANICKED_HIERARCHY_VALUE;

	return PanickedEffect;
}

static function X2Effect_UnblockPathing CreateCivilianUnblockedStatusEffect()
{
	local X2Effect_UnblockPathing     UnblockPathingEffect;
	UnblockPathingEffect = new class'X2Effect_UnblockPathing';
	UnblockPathingEffect.EffectName = default.UnblockPathingName;
	UnblockPathingEffect.DuplicateResponse = eDupe_Ignore;
	UnblockPathingEffect.BuildPersistentEffect(-1, true); // Unblocked is permanent.
	UnblockPathingEffect.SetDisplayInfo(ePerkBuff_Passive, "", "", "", false);
	UnblockPathingEffect.bRemoveWhenTargetDies = true;
	return UnblockPathingEffect;
}

static function X2Effect_PersistentStatChange CreateGatekeeperClosedEffect()
{
	local X2Effect_PersistentStatChange GatekeeperClosedEffect;

	GatekeeperClosedEffect = new class 'X2Effect_GatekeeperClosed';
	GatekeeperClosedEffect.EffectName = class'X2Ability_Gatekeeper'.default.ClosedEffectName;
	GatekeeperClosedEffect.DuplicateResponse = eDupe_Ignore;
	GatekeeperClosedEffect.BuildPersistentEffect(1, true);
	GatekeeperClosedEffect.SetDisplayInfo(ePerkBuff_Bonus, default.GatekeeperClosedEffectName, default.GatekeeperClosedEffectDesc, "img:///UILibrary_PerkIcons.UIPerk_gatekeeper_shut");
	GatekeeperClosedEffect.AddPersistentStatChange(eStat_ArmorMitigation,  class'X2Ability_Gatekeeper'.default.GATEKEEPER_CLOSED_ARMOR_ADJUST);
	GatekeeperClosedEffect.AddPersistentStatChange(eStat_ArmorChance,  class'X2Ability_Gatekeeper'.default.GATEKEEPER_CLOSED_ARMORCHANCE_ADJUST);
	GatekeeperClosedEffect.AddPersistentStatChange(eStat_SightRadius, class'X2Ability_Gatekeeper'.default.GATEKEEPER_CLOSED_SIGHT_ADJUST);
	GatekeeperClosedEffect.AddPersistentStatChange(eStat_Defense, class'X2Ability_Gatekeeper'.default.GATEKEEPER_CLOSED_DEFENSE_ADJUST);

	return GatekeeperClosedEffect;
}

static function X2Effect_Persistent CreateStasisLanceEffect()
{
	local X2Effect_Persistent           Effect;

	Effect = new class'X2Effect_Persistent';
	Effect.EffectName = default.StasisLanceName;
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(default.STASIS_LANCE_TURNS, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.bUseSourcePlayerState = true;
	Effect.bIsImpairing = true;
	Effect.SetDisplayInfo(ePerkBuff_Penalty, default.StasisLanceEffectName, default.StasisLanceEffectDesc, "img:///UILibrary_PerkIcons.UIPerk_stun", true);
	Effect.EffectAddedFn = StasisLanceEffectAdded;
	Effect.EffectRemovedFn = StasisLanceEffectRemoved;
	Effect.VisualizationFn = StasisLanceVisualization;

	return Effect;
}

static function StasisLanceEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState == none)
		return;

	UnitState.bStasisLanced = true;

	// Golden Path special triggers
	if( UnitState.GetMyTemplate().CharacterGroupName == 'AdventCaptain' )
	{
		`XEVENTMGR.TriggerEvent('StasisLanceHitACaptain', UnitState, UnitState, NewGameState);
	}
	else if( UnitState.GetMyTemplate().CharacterGroupName == 'Cyberus' )
	{
		`XEVENTMGR.TriggerEvent('StasisLanceHitACodex', UnitState, UnitState, NewGameState);
	}

	`XEVENTMGR.TriggerEvent('StasisLanceAdded', UnitState, UnitState, NewGameState);

	`TRIGGERXP('XpKillShot', ApplyEffectParameters.SourceStateObjectRef, UnitState.GetReference(), NewGameState);	
}

static function StasisLanceEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	UnitState.SetCurrentStat(eStat_HP, 0);		
	UnitState.OnUnitBledOut(NewGameState, PersistentEffect, ApplyEffectParameters.SourceStateObjectRef, ApplyEffectParameters);
	UnitState.bStasisLanced = false;
	`XEVENTMGR.TriggerEvent('StasisLanceRemoved', UnitState, UnitState, NewGameState);
}

static function StasisLanceVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

	if (EffectApplyResult == 'AA_Success')		
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.StasisLanceEffectName, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_StasisLanced);
	else
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.StasisLanceFailed, '', eColor_Bad);
}

// This function searches for the highest effect in the effect hierarchy
// returns true if the unit is affected by an effect in the hierarchy
// EffectName is the name of the highest effect, if one was found
static function bool GetHighestEffectOnUnit(const XComGameState_Unit TestUnit, out X2Effect_Persistent PersistentEffectTemplate, bool bMustHaveIdleOverrideAnim=false)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent CurrEffectTemplate, HighestRankTemplate;
	local XComGameStateHistory History;
	local int HighestRankTemplateHierarchyValue;

	History = `XCOMHISTORY;

	if( TestUnit != none )
	{
		HighestRankTemplateHierarchyValue = -1;

		foreach TestUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

			if( EffectState != none )
			{
				CurrEffectTemplate = EffectState.GetX2Effect();

				// Must be a persistent effect
				// AND
				// The current effect's hierarchy must be larGer than the saved effect's
				// AND
				// Do not require CustomIdleOverrideAnim OR CustomIdleOverrideAnim must not be blank
				if( (CurrEffectTemplate != none) &&
					(CurrEffectTemplate.EffectHierarchyValue > HighestRankTemplateHierarchyValue) &&
					(!bMustHaveIdleOverrideAnim || (CurrEffectTemplate.CustomIdleOverrideAnim != '')) )
				{
					// This template is ranked higher than the previously saved effect
					HighestRankTemplate = CurrEffectTemplate;
					HighestRankTemplateHierarchyValue = HighestRankTemplate.EffectHierarchyValue;
				}
			}
		}
	}

	PersistentEffectTemplate = none;
	if( HighestRankTemplate != none )
	{
		PersistentEffectTemplate = HighestRankTemplate;
	}

	return HighestRankTemplate != none;
}


static function AddEffectCameraPanToAffectedUnitToTrack(out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context, float Delay = 2.0)
{
	local X2Action_CameraLookAt CameraLookAt;

	CameraLookAt = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	CameraLookAt.LookAtObject = ActionMetadata.StateObject_NewState;
	CameraLookAt.LookAtDuration = Delay * (`XPROFILESETTINGS.Data.bEnableZipMode ? class'X2TacticalGameRuleset'.default.ZipModeDelayModifier : 1.0);
	CameraLookAt.BlockUntilActorOnScreen = true;
	CameraLookAt.UseTether = false;
	CameraLookAt.DesiredCameraPriority = eCameraPriority_GameActions; // increased camera priority so it doesn't get stomped
}

static function AddEffectSoundAndFlyOverToTrack(out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context, string EffectFriendlyName, name nSoldierSpeechCue, EWidgetColor WidgetColor = eColor_Bad, string FlyOverIcon = "", optional float LookAtDuration = 0.0f)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameState_Unit UnitState;
	local bool bInvertColors;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	bInvertColors = (UnitState.GetTeam() != eTeam_XCom && UnitState.GetTeam() != eTeam_Resistance);

	if( bInvertColors )
	{
		if( WidgetColor == eColor_Bad )
		{
			WidgetColor = eColor_Good;
		}
		else if( WidgetColor == eColor_Good )
		{
			WidgetColor = eColor_Bad;
		}
	}


	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, EffectFriendlyName, nSoldierSpeechCue, WidgetColor, FlyOverIcon, LookAtDuration);
}

static function AddEffectMessageToTrack(
	out VisualizationActionMetadata ActionMetadata, 
	string UnexpandedLocString, 
	XComGameStateContext Context, 
	string TitleString, 
	string IconPath, 
	EUIState UIStyleType,
	optional bool bDontPlaySoundEvent)
{
	local XComGameState_Unit UnitState;
	local XGParamTag kTag;
	local X2Action_PlayMessageBanner MessageAction;
	local X2Action_PlayWorldMessage WorldMessageAction;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none || UnitState.bRemovedFromPlay)
		return;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = UnitState.GetFullName();

	if(kTag.StrValue0 != "")
	{
		if( UIStyleType == eUIState_Warning || (UnitState.GetTeam() != eTeam_XCom && UnitState.GetTeam() != eTeam_Resistance) )
		{
			WorldMessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			WorldMessageAction.AddWorldMessage(`XEXPAND.ExpandString(UnexpandedLocString));
		}
		else
		{
			MessageAction = X2Action_PlayMessageBanner(class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			MessageAction.AddMessageBanner(TitleString,
										   ,  // IconPath - not used here b/c we want to always show the default icon for status effects
										   UnitState.GetName(eNameType_RankFull),
										   `XEXPAND.ExpandString(UnexpandedLocString),
										   UIStyleType);
			MessageAction.bDontPlaySoundEvent = bDontPlaySoundEvent;
		}
	}
}

static function UpdateUnitFlag(out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	local X2Action_UpdateUI UpdateUIAction;

	if (XComGameState_Unit(ActionMetadata.StateObject_NewState) == none)
		return;

	UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	UpdateUIAction.SpecificID = ActionMetadata.StateObject_NewState.ObjectID;
	UpdateUIAction.UpdateType = EUIUT_UnitFlag_Buffs;
}

static function X2Effect_PersistentStatChange CreateHackDefenseChangeStatusEffect(int HackDefenseChangeAmount, X2Condition Condition=none)
{
	local X2Effect_PersistentStatChange HackDefenseChangeEffect;
	local EPerkBuffCategory BuffCat;
	local string FriendlyName, FriendlyDesc;

	BuffCat = ePerkBuff_Penalty;
	FriendlyName = default.HackDefenseDecreasedFriendlyName;
	FriendlyDesc = default.HackDefenseDecreasedFriendlyDesc;

	if (HackDefenseChangeAmount > 0)
	{
		BuffCat = ePerkBuff_Bonus;
		FriendlyName = default.HackDefenseIncreasedFriendlyName;
		FriendlyDesc = default.HackDefenseIncreasedFriendlyDesc;
	}

	HackDefenseChangeEffect = new class'X2Effect_PersistentStatChange';
	HackDefenseChangeEffect.BuildPersistentEffect(1, true, false, true);
	HackDefenseChangeEffect.AddPersistentStatChange(eStat_HackDefense, HackDefenseChangeAmount);
	HackDefenseChangeEffect.SetDisplayInfo(BuffCat, FriendlyName, FriendlyDesc, "");
	HackDefenseChangeEffect.DuplicateResponse = eDupe_Ignore;
	HackDefenseChangeEffect.VisualizationFn = HackDefenseChangeVisualization;

	if (Condition != none)
	{
		HackDefenseChangeEffect.TargetConditions.AddItem(Condition);
	}

	return HackDefenseChangeEffect;
}

static function HackDefenseChangeVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit OldUnit, NewUnit;
	local float HackDefenseChange;
	local string FriendlyName;
	local EWidgetColor WidgetColor;
	
	if (EffectApplyResult != 'AA_Success')
	{
		return;
	}

	OldUnit = XComGameState_Unit(ActionMetadata.StateObject_OldState);
	NewUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if ((OldUnit == none) || (NewUnit == none))
	{
		return;
	}

	HackDefenseChange = NewUnit.GetCurrentStat(eStat_HackDefense) - OldUnit.GetCurrentStat(eStat_HackDefense);

	FriendlyName = default.HackDefenseDecreasedFriendlyName;
	WidgetColor = eColor_Bad;
	if (HackDefenseChange > 0)
	{
		FriendlyName = default.HackDefenseIncreasedFriendlyName;
		WidgetColor = eColor_Good;
	}

	AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), FriendlyName, '', WidgetColor, class'UIUtilities_Image'.const.UnitStatus_Burning);
	AddEffectMessageToTrack(
		ActionMetadata, 
		default.HackDefenseChangeEffectAcquiredString, 
		VisualizeGameState.GetContext(), 
		class'UIEventNoticesTactical'.default.HackDefenseTitle, 
		class'UIUtilities_Image'.const.HackRewardIcon, 
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function X2Effect_Persistent CreateBleedingStatusEffect(int NumTurns, int TickDamageAmount)
{
	local X2Effect_Persistent PersistentEffect;
	local X2Effect_ApplyWeaponDamage DamageEffect;
	local X2Condition_UnitProperty UnitPropCondition;

	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.EffectName = default.BleedingName;
	PersistentEffect.DuplicateResponse = eDupe_Refresh;
	PersistentEffect.BuildPersistentEffect(NumTurns, , false, , eGameRule_PlayerTurnBegin);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, default.BleedingFriendlyName, default.BleedingFriendlyDesc, "img:///UILibrary_XPACK_Common.UIPerk_bleeding");
	PersistentEffect.VisualizationFn = BleedingVisualization;
	PersistentEffect.EffectSyncVisualizationFn = BleedingSyncVisualization;
	PersistentEffect.EffectTickedVisualizationFn = BleedingVisualizationTicked;
	PersistentEffect.EffectRemovedVisualizationFn = BleedingVisualizationRemoved;
	PersistentEffect.DamageTypes.AddItem('Bleeding');
	PersistentEffect.bRemoveWhenTargetDies = true;
	PersistentEffect.bCanTickEveryAction = true;
	PersistentEffect.bEffectForcesBleedout = true;

	PersistentEffect.PersistentPerkName = default.BleedingPerk_Name;

	UnitPropCondition = new class'X2Condition_UnitProperty';
	UnitPropCondition.ExcludeFriendlyToSource = false;
	UnitPropCondition.ExcludeRobotic = true;
	PersistentEffect.TargetConditions.AddItem(UnitPropCondition);

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.EffectDamageValue.Damage = TickDamageAmount;
	DamageEffect.EffectDamageValue.DamageType = 'Bleeding';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTypes.AddItem('Bleeding');
	DamageEffect.bAllowFreeKill = false;
	DamageEffect.bIgnoreArmor = true;

	/// HL-Docs: feature:BleedingDamageBypassesShields; issue:629; tags:tactical
	/// In base game, shields (eStat_ShieldHP) absorb damage from typical damage over time 
	/// bleeding effects, such as those applied by ADVENT Stiletto Rounds. 
	/// Mods can override this behavior by setting the `BLEEDING_IGNORES_SHIELDS` flag
	/// in `XComGameCore.ini`:
	///
	///```ini
	///[XComGame.X2StatusEffects]
	///BLEEDING_IGNORES_SHIELDS=true ; Make bleeding DOT ignore shields
	///```
	///
	/// Note that this will apply only to bleeding effects created using the
	/// `X2StatusEffect::CreateBleedingStatusEffect()` helper method, which
	/// should cover all instance of bleeding DOT effects in the base game, 
	/// but mods can potentially create their own bleeding effects, bypassing this helper method.
	///
	/// [Refer to this feature](../tactical/BurningAndPoisonedDamageBypassesShields.md) to apply similar change to burning, poisoned and acid damage over time.
	DamageEffect.bBypassShields = default.BLEEDING_IGNORES_SHIELDS; // Single line for Issue #629
	PersistentEffect.ApplyOnTick.AddItem(DamageEffect);

	return PersistentEffect;
}

static function BleedingVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XGUnit UnitVisualizer;
	local DamageTypeHitEffectContainer HitContainer;
	local X2Action_PlayEffect PlayEffectAction;
	if (EffectApplyResult != 'AA_Success')
	{
		return;
	}

	if (ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.BleedingFriendlyName, 'Bleeding', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Bleeding);
		AddEffectMessageToTrack(
			ActionMetadata,
			default.BleedingEffectAcquiredString,
			VisualizeGameState.GetContext(),
			class'UIEventNoticesTactical'.default.BleedingTitle,
			"img:///UILibrary_PerkIcons.UIPerk_bleeding",
			eUIState_Bad);
		UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
		UnitVisualizer = XGUnit(ActionMetadata.VisualizeActor);
		if( UnitVisualizer != None )
		{
			HitContainer = UnitVisualizer.GetPawn().GetDamageTypeHitEffectContainer();
			if( HitContainer != None && HitContainer.BleedingEffect != None )
			{
				PlayEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

				PlayEffectAction.AttachToUnit = true;
				PlayEffectAction.EffectName = PathName(HitContainer.BleedingEffect);
				PlayEffectAction.AttachToSocketName = default.BleedingSocket_Name;
				PlayEffectAction.AttachToSocketsArrayName = default.BleedingSocketsArray_Name;
			}
		}
	}
}

static function BleedingSyncVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XGUnit UnitVisualizer;
	local DamageTypeHitEffectContainer HitContainer;
	local X2Action_PlayEffect PlayEffectAction;

	UnitVisualizer = XGUnit(ActionMetadata.VisualizeActor);
	if( UnitVisualizer != None )
	{
		HitContainer = UnitVisualizer.GetPawn().GetDamageTypeHitEffectContainer();
		if( HitContainer != None && HitContainer.BleedingEffect != None )
		{
			PlayEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

			PlayEffectAction.AttachToUnit = true;
			PlayEffectAction.EffectName = PathName(HitContainer.BleedingEffect);
			PlayEffectAction.AttachToSocketName = default.BleedingSocket_Name;
			PlayEffectAction.AttachToSocketsArrayName = default.BleedingSocketsArray_Name;
		}
	}
}

static function BleedingVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if (!UnitState.IsAlive())
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.BleedingEffectTickedString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BleedingTitle,
		"img:///UILibrary_PerkIcons.UIPerk_bleeding",
		eUIState_Warning);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function BleedingVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local XGUnit UnitVisualizer;
	local DamageTypeHitEffectContainer HitContainer;
	local X2Action_PlayEffect PlayEffectAction;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units should not be reported
	if (!UnitState.IsAlive())
	{
		return;
	}

	AddEffectMessageToTrack(
		ActionMetadata,
		default.BleedingEffectLostString,
		VisualizeGameState.GetContext(),
		class'UIEventNoticesTactical'.default.BleedingTitle,
		"img:///UILibrary_PerkIcons.UIPerk_bleeding",
		eUIState_Good);
	UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());

	UnitVisualizer = XGUnit(ActionMetadata.VisualizeActor);
	if( UnitVisualizer != None )
	{
		HitContainer = UnitVisualizer.GetPawn().GetDamageTypeHitEffectContainer();
		if( HitContainer != None && HitContainer.BleedingEffect != None )
		{
			PlayEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

			PlayEffectAction.AttachToUnit = true;
			PlayEffectAction.EffectName = PathName(HitContainer.BleedingEffect);
			PlayEffectAction.AttachToSocketName = default.BleedingSocket_Name;
			PlayEffectAction.AttachToSocketsArrayName = default.BleedingSocketsArray_Name;
			PlayEffectAction.bStopEffect = true;
		}
	}
}

// Apply the persistent effect DoNotConsumeAllPoints to the unit for one turn.
static function X2Effect_Persistent CreateDoNotConsumeStatusEffect()
{
	local X2Effect_Persistent DoNotConsumeEffect;

	DoNotConsumeEffect = new class'X2Effect_Persistent';
	DoNotConsumeEffect.EffectName = 'DoNotConsumeAllPoints';
	DoNotConsumeEffect.DuplicateResponse = eDupe_Ignore;
	DoNotConsumeEffect.BuildPersistentEffect(1, , true, , eGameRule_PlayerTurnBegin);
	DoNotConsumeEffect.SetDisplayInfo(ePerkBuff_Passive, "", "", "", false);
	DoNotConsumeEffect.bRemoveWhenTargetDies = true;
	return DoNotConsumeEffect;
}

// Apply the persistent effect UltrasonicLureTargetAllPoints to the unit for N turns.
static function X2Effect_Persistent CreateUltrasonicLureTargetStatusEffect()
{
	local X2Effect_Persistent UltrasonicLureTargetEffect;

	UltrasonicLureTargetEffect = new class'X2Effect_Persistent';
	UltrasonicLureTargetEffect.EffectName = default.UltrasonicLureName;
	UltrasonicLureTargetEffect.DuplicateResponse = eDupe_Ignore;
	// Start Issue #1286
	/// HL-Docs: ref:Bugfixes; issue:1286
	/// Keep lure effect alive when source dies, tick on turn begin. Adjust icon and displayinfo to display as debuff rather than passive.
	UltrasonicLureTargetEffect.BuildPersistentEffect(default.ULTRASONICLURE_TURNS,false,false,,eGameRule_PlayerTurnBegin); 
	UltrasonicLureTargetEffect.SetDisplayInfo(ePerkBuff_Penalty, default.UltrasonicLureFriendlyName, default.UltrasonicLureFriendlyDesc, "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_ultrasoniclure" ); 
	// End Issue #1286
	UltrasonicLureTargetEffect.bRemoveWhenTargetDies = true;
	return UltrasonicLureTargetEffect;
}

DefaultProperties
{
	BleedingOutName="BleedingOut"
	BurningName="Burning"
	AcidBurningName="Acid"
	PoisonedName="Poisoned"
	UnconsciousName="Unconscious"
	MarkedName="MarkedTarget"
	StasisLanceName="StasisLance"
	UnblockPathingName="UnblockPathing"
	BleedingName="Bleeding"
	UltrasonicLureName="UltrasonicLureTarget"
}