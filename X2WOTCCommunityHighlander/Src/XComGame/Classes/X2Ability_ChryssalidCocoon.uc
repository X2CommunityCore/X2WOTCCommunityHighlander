//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_ChryssalidCocoon extends X2Ability
	config(GameData_SoldierSkills);

var config int GESTATION_TURNS;

var name GestationStage1EffectName;
var name GestationStage2EffectName;

var private name GestationEffectName;
var private name GestationTriggerName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateGestationStage1Ability());
	Templates.AddItem(CreateGestationStage2Ability());
	Templates.AddItem(CreateGestationStage3Ability());
	Templates.AddItem(CreateSpawnChryssalidAbility());
	Templates.AddItem(PurePassive('ChryssalidCocoonImmunities', "img:///UILibrary_PerkIcons.UIPerk_immunities"));
	Templates.AddItem(CreateSpawnChryssalidAbilityMP());
	
	return Templates;
}

static function X2AbilityTemplate CreateGestationStage1Ability()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent GestationEffect;
	local X2Effect_DelayedAbilityActivation DelayedGestationEffect;
	local X2Effect_DamageImmunity DamageImmunity;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_OverrideDeathAction DeathActionEffect;
	local X2AbilityTrigger_EventListener EventListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CocoonGestationTimeStage1');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_cocoon"; 

	Template.AdditionalAbilities.AddItem('CocoonGestationTimeStage2');
	Template.AdditionalAbilities.AddItem('CocoonGestationTimeStage3');
	Template.AdditionalAbilities.AddItem('SpawnChryssalid');
	Template.AdditionalAbilities.AddItem('ChryssalidCocoonImmunities');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// This ability fires when the ParthenogenicPoisonCocoonSpawnedName event occurs
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = class'X2Effect_ParthenogenicPoison'.default.ParthenogenicPoisonCocoonSpawnedName;
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChryssalidCocoonSpawnedListener;
	Template.AbilityTriggers.AddItem(EventListener);

	GestationEffect = new class'X2Effect_Persistent';
	GestationEffect.BuildPersistentEffect(default.GESTATION_TURNS, false, true, false, eGameRule_PlayerTurnEnd);
	GestationEffect.EffectName = default.GestationEffectName;
	GestationEffect.VisualizationFn = GestationStage1PawnSwapVisualization;
	Template.AddTargetEffect(GestationEffect);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_ParthenogenicPoison'.default.EffectName);
	Template.AddMultiTargetEffect(RemoveEffects);

	//Delayed Effect to cause the second gestation stage to occur
	DelayedGestationEffect = new class 'X2Effect_DelayedAbilityActivation';
	DelayedGestationEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	DelayedGestationEffect.EffectName = default.GestationStage1EffectName;
	DelayedGestationEffect.TriggerEventName = default.GestationTriggerName;
	DelayedGestationEffect.bBringRemoveVisualizationForward = true;
	Template.AddTargetEffect(DelayedGestationEffect);

	// Build the immunities
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, false, true);
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.KnockbackDamageType);
	DamageImmunity.ImmuneTypes.AddItem('Poison');
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType);
	DamageImmunity.ImmuneTypes.AddItem('stun');
	DamageImmunity.EffectName = 'ChryssalidCocoonImmunity';
	Template.AddTargetEffect(DamageImmunity);	

	DeathActionEffect = new class'X2Effect_OverrideDeathAction';
	DeathActionEffect.DeathActionClass = class'X2Action_ChryssalidCocoonDeathAction';
	DeathActionEffect.EffectName = 'CocoonDeathActionOverride';
	Template.AddTargetEffect(DeathActionEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;

	//We re-run the X2Action_CreateDoppelganger on load, to restore the appearance.
	Template.BuildAffectedVisualizationSyncFn = Cocoon_BuildVisualizationSyncDelegate;

	return Template;
}

static function GestationStage1PawnSwapVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_CreateDoppelganger CopyDeadUnitAction;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;

	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}

	if (ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		History = `XCOMHISTORY;
		Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

		// Copy the dead unit's appearance to the zombie
		CopyDeadUnitAction = X2Action_CreateDoppelganger(class'X2Action_CreateDoppelganger'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		CopyDeadUnitAction.bWaitForOriginalUnitMessage = false;
		CopyDeadUnitAction.bAllowNewAnimationsOnDoppelganger = false;

		// The unit that died with parthenogenic poison and is host to the cocoon is stored in the
		// first index of the multi targets
		`assert(Context.InputContext.MultiTargets.Length == 1);
		CopyDeadUnitAction.OriginalUnit = XGUnit(History.GetVisualizer(Context.InputContext.MultiTargets[0].ObjectID));

		CopyDeadUnitAction.ReanimatorAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
		CopyDeadUnitAction.ShouldCopyAppearance = true;

		class'X2Action_AbilityPerkStart'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
		class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	}
}

simulated function Cocoon_BuildVisualizationSyncDelegate(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit CocoonUnitState;
	local XComGameState_Unit DeadUnitState;
	local XComGameState_Ability CocoonAbility;
	local X2Action_CreateDoppelganger DoppelgangerAction;
	local X2Action_SyncOnLoadChryssalidCocoon SyncAction;

	//Only run on the Immunity effect
	if( `XENGINE.IsMultiplayerGame() || EffectName != 'ChryssalidCocoonImmunity' )
	{
		return;
	}
	
	//Find the context and unit states associated with the cocoon ability used
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if( AbilityContext == None )
	{
		return;
	}

	// The unit that died with parthenogenic poison and is host to the cocoon is stored in the
	// first index of the multi targets
	`assert(AbilityContext.InputContext.MultiTargets.Length == 1);
	CocoonUnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	DeadUnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.MultiTargets[0].ObjectID));
	if( (CocoonUnitState == None || DeadUnitState == None) )
	{
		return;
	}

	CocoonAbility = XComGameState_Ability(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if( CocoonAbility == none )
	{
		return;
	}

	//Perform X2Action_CreateDoppelganger
	DoppelgangerAction = X2Action_CreateDoppelganger(class'X2Action_CreateDoppelganger'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	DoppelgangerAction.OriginalUnitState = DeadUnitState;
	DoppelgangerAction.ReanimatorAbilityState = CocoonAbility;
	DoppelgangerAction.ShouldCopyAppearance = true;
	DoppelgangerAction.bIgnorePose = true;
	DoppelgangerAction.bReplacingOriginalUnit = false;
	DoppelgangerAction.bAllowNewAnimationsOnDoppelganger = false;

	SyncAction = X2Action_SyncOnLoadChryssalidCocoon(class'X2Action_SyncOnLoadChryssalidCocoon'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	SyncAction.OriginalUnitState = DeadUnitState;
}

static function GestationRemoval_VisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlayEffect PlayEffectAction;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	// The Dead VFX should only play if this is removed and the unit is dead
	if(UnitState == None || UnitState.IsAlive() )
	{
		return;
	}
	
	PlayEffectAction = X2Action_PlayEffect( class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()/*, false, ActionMetadata.LastActionAdded*/));

	PlayEffectAction.AttachToUnit = true;
	PlayEffectAction.EffectName = class'X2Effect_ChryssalidCocoonGestationStage3'.default.COCOONSTAGETHREEPARTICLE_NAME;
	PlayEffectAction.AttachToSocketName = class'X2Effect_ChryssalidCocoonGestationStage3'.default.COCOONSTAGETHREESOCKET_NAME;
	PlayEffectAction.AttachToSocketsArrayName = class'X2Effect_ChryssalidCocoonGestationStage3'.default.COCOONSTAGETHREESOCKETSARRAY_NAME;
}

static function X2AbilityTemplate CreateGestationStage2Ability()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent GestationEffect_Stage2;

	local X2AbilityTrigger_EventListener EventListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CocoonGestationTimeStage2');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_cocoon"; 

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// This ability fires when the event GestationTriggerName fires on this unit
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = default.GestationTriggerName;
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChryssalidCocoonSpawnedListener;
	Template.AbilityTriggers.AddItem(EventListener);

	GestationEffect_Stage2 = new class'X2Effect_Persistent';
	GestationEffect_Stage2.EffectName = default.GestationStage2EffectName;
	GestationEffect_Stage2.BuildPersistentEffect(1, true, false, true);
	GestationEffect_Stage2.bBringRemoveVisualizationForward = true;
	Template.AddTargetEffect(GestationEffect_Stage2);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;

	return Template;
}

static function X2AbilityTemplate CreateGestationStage3Ability()
{
	local X2AbilityTemplate Template;
	local X2Condition_UnitEffects ExcludeEffects;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_ChryssalidCocoonGestationStage3 GestationEffect_Stage3;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Effect_KillUnit KillUnitEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CocoonGestationTimeStage3');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_cocoon"; 

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Effect_ChryssalidCocoonGestationStage3'.default.EffectName, 'AA_UnitIsDead');
	Template.AbilityShooterConditions.AddItem(ExcludeEffects);

	// This ability fires when the ability is out of charges
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'ExhaustedAbilityCharges';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChryssalidCocoonSpawnedListener;
	Template.AbilityTriggers.AddItem(EventListener);

	// This ability fires when the unit dies
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitDied';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChryssalidCocoonSpawnedListener;
	Template.AbilityTriggers.AddItem(EventListener);

	KillUnitEffect = new class'X2Effect_KillUnit';
	KillUnitEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	KillUnitEffect.EffectName = 'KillCocoon';
	KillUnitEffect.TargetConditions.AddItem(default.LivingShooterProperty);
	Template.AddTargetEffect(KillUnitEffect);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.GestationStage1EffectName);
	RemoveEffects.EffectNamesToRemove.AddItem(default.GestationStage2EffectName);
	Template.AddTargetEffect(RemoveEffects);

	GestationEffect_Stage3 = new class'X2Effect_ChryssalidCocoonGestationStage3';
	GestationEffect_Stage3.BuildPersistentEffect(1, true, true, true);
	Template.AddTargetEffect(GestationEffect_Stage3);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.MergeVisualizationFn = GestationStage3_MergeVisualization;

	Template.bSkipFireAction = true;
	Template.bShowActivation = false;
	Template.bFrameEvenWhenUnitIsHidden = false;
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	return Template;
}

static function GestationStage3EffectAdded( X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState )
{
	local XComGameState_Unit CocoonUnit;
	local float PreviousHealth;
	
	CocoonUnit = XComGameState_Unit(kNewTargetState);

	PreviousHealth = CocoonUnit.GetCurrentStat(eStat_HP);

	CocoonUnit.SetCurrentStat(eStat_HP, 0);
	if( PreviousHealth > 0)
	{
		// The Cocoon had health which means it hatched its final Chryssalid pup, so it killed itself
		CocoonUnit.OnUnitBledOut(NewGameState, PersistentEffect, ApplyEffectParameters.SourceStateObjectRef, ApplyEffectParameters);
	}
}

function GestationStage3_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action_ChryssalidCocoonDeathAction DeathAction;
	local X2Action BuildTreeStartNode, BuildTreeEndNode;
	local XComGameStateContext_Ability Context;

	VisMgr = `XCOMVISUALIZATIONMGR;

	// Find the associated cocoon death action
	DeathAction = X2Action_ChryssalidCocoonDeathAction(VisMgr.GetNodeOfType(VisualizationTree, class'X2Action_ChryssalidCocoonDeathAction', BuildTree.Metadata.VisualizeActor));

	if (DeathAction != none)
	{
		BuildTreeStartNode = VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin');
		BuildTreeEndNode = VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd');

		VisMgr.InsertSubtree(BuildTreeStartNode, BuildTreeEndNode, DeathAction);
	}
	else
	{
		Context = XComGameStateContext_Ability(BuildTree.StateChangeContext);
		Context.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
	}
}
static function X2AbilityTemplate CreateSpawnChryssalidAbility(name AbilityName = 'SpawnChryssalid')
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2Condition_UnitEffects GestationEffectComplete;
	local X2Condition_UnblockedNeighborTile UnblockedNeighborTileCondition;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_Persistent GestationEffect_Stage2;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_cocoon"; // TODO: Change this icon
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Charges');
	Template.AbilityCosts.AddItem(default.FreeActionCost);
	Template.AbilityCharges = new class'X2AbilityCharges_CocoonSpawnChryssalid';

	// Action Point
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);	

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	// May spawn a pup if the unit is burning or disoriented
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	GestationEffectComplete = new class'X2Condition_UnitEffects';
	GestationEffectComplete.AddExcludeEffect(default.GestationEffectName, 'AA_UnitGestationComplete');
	Template.AbilityTargetConditions.AddItem(GestationEffectComplete);

	UnblockedNeighborTileCondition = new class'X2Condition_UnblockedNeighborTile';
	template.AbilityShooterConditions.AddItem(UnblockedNeighborTileCondition);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AddTargetEffect(new class'X2Effect_SpawnChryssalid');

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.GestationStage2EffectName);
	Template.AddTargetEffect(RemoveEffects);

	GestationEffect_Stage2 = new class'X2Effect_Persistent';
	GestationEffect_Stage2.EffectName = default.GestationStage2EffectName;
	GestationEffect_Stage2.BuildPersistentEffect(1, true, false, true);
	GestationEffect_Stage2.bBringRemoveVisualizationForward = true;
	GestationEffect_Stage2.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(GestationEffect_Stage2);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = SpawnChryssalid_BuildVisualization;
	Template.CinescriptCameraType = "ChryssalidCocoon_SpawnChryssalid";

	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'SpawnChryssalid'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'SpawnChryssalid'
	
	return Template;
}
static function X2AbilityTemplate CreateSpawnChryssalidAbilityMP( )
{
	local X2AbilityTemplate Template;
	local X2Effect TargetEffect;
	local X2Effect_SpawnChryssalid SpawnEffect;

	Template = CreateSpawnChryssalidAbility( 'SpawnChryssalidMP' );

	// override the basic and auto added spawn ability
	Template.OverrideAbilities.AddItem( 'SpawnChryssalid' );

	// Update the spawning effect to spawn the right unit
	foreach Template.AbilityTargetEffects( TargetEffect )
	{
		SpawnEffect = X2Effect_SpawnChryssalid( TargetEffect );
		SpawnEffect.UnitToSpawnName = 'ChryssalidMP';
	}

	return Template;
}

simulated function SpawnChryssalid_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local StateObjectReference InteractingUnitRef;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameState_Ability Ability;
	local XComGameState_Unit SpawnedUnit, CocoonUnit;
	local UnitValue SpawnedUnitValue;
	local X2Effect_SpawnChryssalid SpawnChryssalidEffect;
	local int j;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(InteractingUnitRef.ObjectID,
													   ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
					
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Bad);

	// Since the first effect is the spawn, skip it
	for( j = 1; j < Context.ResultContext.TargetEffectResults.Effects.Length; ++j )
	{
		// Target effect visualization
		Context.ResultContext.TargetEffectResults.Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.ResultContext.TargetEffectResults.ApplyResults[j]);
	}

	
	//Configure the visualization track for the new Chryssalid
	//****************************************************************************************
	CocoonUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	`assert(CocoonUnit != none);
	CocoonUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
	SpawnedUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	`assert(SpawnedUnit != none);
	ActionMetadata.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

	// First target effect is X2Effect_SpawnChryssalid
	SpawnChryssalidEffect = X2Effect_SpawnChryssalid(Context.ResultContext.TargetEffectResults.Effects[0]);
	
	if( SpawnChryssalidEffect == none )
	{
		`RedScreenOnce("SpawnChryssalid_BuildVisualization: Missing X2Effect_SpawnChryssalid -dslonneger @gameplay");
		return;
	}

	SpawnChryssalidEffect.AddSpawnVisualizationsToTracks(Context, SpawnedUnit, ActionMetadata, CocoonUnit);

	}

defaultproperties
{
	GestationEffectName="GestationEffect"
	GestationStage1EffectName="GestationEffect_Stage1"
	GestationStage2EffectName="GestationEffect_Stage2"
	GestationTriggerName="GestationTrigger"
}
