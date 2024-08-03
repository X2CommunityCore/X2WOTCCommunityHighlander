//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_DLC_Day60AlienRulers.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Ability_DLC_Day60AlienRulers extends X2Ability;

var const name CallForEscapeEffectName;
var const name AlienRulerActionSystemAbilityName;
var const name ViperNeonateBindAbilityName;
var const name ViperNeonateBindSustainedAbilityName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AlienRulerPassive());
	Templates.AddItem(CreateViperKingInitialize());
	Templates.AddItem(CreateAlienRulerCallForEscapeAbility());
	Templates.AddItem(CreateAlienRulerEscapeAbility());
	Templates.AddItem(CreateAlienRulerActionSystem());  // Immediate reactions
	Templates.AddItem(CreateInitialStateAbility());		// Disables standard action points when revealed.

	// Neonate abilities, if more are needed move these to a new file
	Templates.AddItem(CreateViperNeonateBind());
	Templates.AddItem(CreateViperNeonateBindSustained());

	return Templates;
}

static function X2AbilityTemplate AlienRulerPassive()
{
	return PurePassive('AlienRulerPassive', , , , false);
}

static function X2AbilityTemplate CreateViperKingInitialize()
{
	local X2AbilityTemplate	Template;
	local X2Effect_PerkAttachForFX FXEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ViperKingInitialState');

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Set initial action point per turn.
	FXEffect = new class'X2Effect_PerkAttachForFX';
	FXEffect.BuildPersistentEffect(1, true, false, true);
	Template.AddTargetEffect(FXEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2DataTemplate CreateAlienRulerCallForEscapeAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_PersistentStatChange EscapeEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AlienRulerCallForEscape');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_escape"; // TODO: Change this icon
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	Template.AdditionalAbilities.AddItem('AlienRulerEscape');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 0;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = 0;
	Cooldown.NumGlobalTurns = 0;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Escape may be used if disoriented, burning, or confused.  Not bound though.
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.ConfusedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
 
	Template.TargetingMethod = class'X2TargetingMethod_Teleport';

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.CallForEscapeEffectName);
	Template.AddShooterEffect(RemoveEffects);

	EscapeEffect = new class'X2Effect_PersistentStatChange';
	EscapeEffect.BuildPersistentEffect(1, true, true, true);
	EscapeEffect.EffectName = default.CallForEscapeEffectName;
	EscapeEffect.AddPersistentStatChange(eStat_Dodge, 25);
	EscapeEffect.AddPersistentStatChange(eStat_Mobility, 1.25, MODOP_Multiplication);
	EscapeEffect.VisualizationFn = EscapeEffectVisualization;
	Template.AddShooterEffect(EscapeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = CallForEscape_BuildVisualization;

	Template.CustomFireAnim = 'HL_Escape';
	Template.bSkipPerkActivationActions = true;
	Template.bSkipPerkActivationActionsSync = false;
	Template.CinescriptCameraType = "AlienRulers_CallForEscape";

	return Template;
}

simulated function CallForEscape_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability AbilityContext;	
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;

	TypicalAbility_BuildVisualization(VisualizeGameState);

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObjectRef = AbilityContext.InputContext.SourceObject;
	class'X2Action_AbilityPerkStart'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);
	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);
}

static function X2DataTemplate CreateAlienRulerEscapeAbility()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent EscapeEffect;
	local X2Condition_UnitEffects EffectsCondition;
	local X2AbilityTrigger_EventListener Trigger;
	local X2Effect_RemoveEffects RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AlienRulerEscape');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_escape";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddRequireEffect(default.CallForEscapeEffectName, 'AA_UnitIsEscaping');
	Template.AbilityShooterConditions.AddItem(EffectsCondition);

	Template.AbilityTargetConditions.AddItem(new class'X2Condition_DLC_2_UnitInEscapePortal');

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	//Trigger on movement - interrupt the move
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'ObjectMoved';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.CallForEscapeEffectName);
	Template.AddShooterEffect(RemoveEffects);

	EscapeEffect = new class'X2Effect_Persistent';
	EscapeEffect.EffectName = 'Escaped';
	EscapeEffect.EffectAddedFn = AlienRulerEscape_AddedFn;
	EscapeEffect.VisualizationFn = AlienRulerEscape_Visualization;
	Template.AddShooterEffect(EscapeEffect);	

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	Template.CinescriptCameraType = "AlienRulers_Escape";
	
	return Template;
}

static function AlienRulerEscape_AddedFn( X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState )
{
	local XComGameState_Unit RulerState;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	RulerState = XComGameState_Unit(kNewTargetState);
	EventManager.TriggerEvent('UnitRemovedFromPlay', RulerState, RulerState, NewGameState);
}

static function AlienRulerEscape_Visualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_SpecialTurnOverlay TurnOverlayAction;

	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}

	class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
	TurnOverlayAction = X2Action_SpecialTurnOverlay(class'X2Action_SpecialTurnOverlay'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	TurnOverlayAction.bHideOverlay = true;
}

static function X2DataTemplate CreateAlienRulerActionSystem()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_DLC_Day60OnAbilityActivated	Trigger;
	local X2Effect_RunBehaviorTree RunBehaviorEffect;
	local X2Effect_DLC_2RulerActionPoint GrantActionPoints;
	local X2Effect_ReduceCooldowns ReduceCooldownsEffect;
	local X2Condition_UnitProperty UnitProperty;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.AlienRulerActionSystemAbilityName);
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Apply upon any ability activation.  This trigger checks for other requirements, i.e. unconcealed XCom action, exclusions.
	Trigger = new class'X2AbilityTrigger_DLC_Day60OnAbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.OnAbilityActivated;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.Priority = 20;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Only apply ability when this ruler has already been revealed.
	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeUnrevealedAI = true;
	Template.AbilityShooterConditions.AddItem(UnitProperty);

	// Add 1 action points whenever ActionPoint count == 0.
	GrantActionPoints = new class'X2Effect_DLC_2RulerActionPoint';
	GrantActionPoints.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	GrantActionPoints.NumActionPoints = 1;
	GrantActionPoints.SkipWithEffect.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	GrantActionPoints.SkipWithEffect.AddItem(class'X2Effect_DLC_Day60Freeze'.default.EffectName);
	GrantActionPoints.bApplyOnlyWhenOut = true;
	Template.AddTargetEffect(GrantActionPoints);

	RunBehaviorEffect = new class'X2Effect_RunBehaviorTree';
	RunBehaviorEffect.BehaviorTreeName = 'RulerBehavior'; // Defined in XComAI.ini
	RunBehaviorEffect.bInitFromPlayer = true;
	Template.AddTargetEffect(RunBehaviorEffect);

	ReduceCooldownsEffect = new class'X2Effect_ReduceCooldowns';
	ReduceCooldownsEffect.Amount = 1;
	Template.AddTargetEffect(ReduceCooldownsEffect);

	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization; // Required for visualization of stun-removal.
	Template.AssociatedPlayTiming = SPT_AfterSequential;

	Template.bSkipFireAction = true;
	Template.bTickPerActionEffects = true;
//BEGIN AUTOGENERATED CODE: Template Overrides 'AlienRulerActionSystem'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'AlienRulerActionSystem'

	return Template;
}

// Apply an effect to all rulers where they only get action points for the Alien turn before they are revealed.
static function X2AbilityTemplate CreateInitialStateAbility()
{
	local X2AbilityTemplate					Template;
	local X2Effect_DLC_Day60TurnStartRemoveActionPoints NoActionPoints;
	local X2Effect_DamageImmunity           DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AlienRulerInitialState');

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Set initial action point per turn.
	NoActionPoints = new class'X2Effect_DLC_Day60TurnStartRemoveActionPoints';
	NoActionPoints.bApplyToRevealedAIOnly = true;
	Template.AddTargetEffect(NoActionPoints);

	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, true, true);
	DamageImmunity.ImmuneTypes.AddItem('Unconscious');
	DamageImmunity.EffectName = 'RulerImmunity';
	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function EscapeEffectVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameStateContext_Ability  AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Bad);
}

static function X2AbilityTemplate CreateViperNeonateBind()
{
	local X2AbilityTemplate	Template;
	local X2Effect TargetEffect;
	local X2Effect_ApplyWeaponDamage DamageEffect;

	Template = class'X2Ability_Viper'.static.CreateBindAbility(true, default.ViperNeonateBindAbilityName, default.ViperNeonateBindSustainedAbilityName);

	foreach Template.AbilityTargetEffects(TargetEffect)
	{
		DamageEffect = X2Effect_ApplyWeaponDamage(TargetEffect);

		if( DamageEffect!= none )
		{
			DamageEffect.EffectDamageValue = class'X2Item_DLC_Day60Weapons'.default.VIPERNEONATE_BIND_BASEDAMAGE;
			break;
		}
	}

	// The base Viper Bind adds the base Bind Sustained ability, this will be replaced by the Neonate's Sustain
	Template.AdditionalAbilities.RemoveItem('BindSustained');
	Template.AdditionalAbilities.AddItem(default.ViperNeonateBindSustainedAbilityName);
//BEGIN AUTOGENERATED CODE: Template Overrides 'BindSustained'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'BindSustained'

	return Template;
}

static function X2AbilityTemplate CreateViperNeonateBindSustained()
{
	local X2AbilityTemplate	Template;
	local X2Effect TargetEffect;
	local X2Effect_ApplyWeaponDamage DamageEffect;

	Template = class'X2Ability_Viper'.static.CreateBindSustainedAbility(default.ViperNeonateBindSustainedAbilityName);

	foreach Template.AbilityTargetEffects(TargetEffect)
	{
		DamageEffect = X2Effect_ApplyWeaponDamage(TargetEffect);

		if( DamageEffect!= none )
		{
			DamageEffect.EffectDamageValue = class'X2Item_DLC_Day60Weapons'.default.VIPERNEONATE_BIND_SUSTAINDAMAGE;
			break;
		}
	}

	return Template;
}

static function RemoveMimicBeaconsFromTargets(out X2AbilityTemplate AbilityTemplate)
{
	local X2Condition_UnitType UnitTypeCondition;
	UnitTypeCondition = new class'X2Condition_UnitType';
	UnitTypeCondition.ExcludeTypes.AddItem('MimicBeacon');
	AbilityTemplate.AbilityTargetConditions.AddItem(UnitTypeCondition);
}

defaultproperties
{
	CallForEscapeEffectName="CallForEscapeEffect"
	AlienRulerActionSystemAbilityName="AlienRulerActionSystem"
	ViperNeonateBindAbilityName="ViperNeonateBindAbility"
	ViperNeonateBindSustainedAbilityName="ViperNeonateBindSustainedAbility"
}
