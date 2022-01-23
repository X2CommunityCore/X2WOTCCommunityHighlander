//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_ReaperAbilitySet.uc
//  AUTHOR:  Joshua Bouscher  --  7/6/2016
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_ReaperAbilitySet extends X2Ability 
	native(Core)							//	some native code needs to access config values for Remote Start
	config(GameData_SoldierSkills);

var config int		InfiltrationHackBonus;
var config float    ShadowMobilityMod;
var config int      ShadowCooldown;
var config int		ShadowCharges;
var config int		ShadowRisingCharges;
var config int      ClaymoreCharges;
var config int		ClaymoreRange;
var config int      HighlandsCharges;
var config float	HomingMineRadius, HomingShrapnelBonusRadius;
var config WeaponDamageValue HomingMineDamage, HomingShrapnelDamage;
var config int		HomingMineEnvironmentDamage, HomingShrapnelEnvironmentDamage;
var config string	HomingMineExplosionFX, HomingShrapnelExplosionFX, HomingMineImpactArchetype;
var config float	RemoteStartDamageMultiplier, RemoteStartRadiusMultiplier;
var config int		StingCooldown;
var config int		StingCharges;
var config float	ImprovisedSilencerShadowBreakScalar;
var config array<name> ImprovisedSilencerAffectedAbilities;
var config int		BloodTrailDamage;
var config int		NeedlePierce;
var config int		RemoteStartCooldown;
var config float	ShadowRollCameraDelay;
var config float	ShadowRollBlipDuration;
var config string	ClaymoreDestructibleArchetype, ShrapnelDestructibleArchetype;
var config int		PaleHorseCritBoost, PaleHorseMax;
var config int		BanishFirstShotAimMod, BanishSubsequentShotsAimMod;

var localized string HomineMinePenaltyDescription;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(ShadowPassive());
	Templates.AddItem(Shadow());
	Templates.AddItem(ShadowRising());
	Templates.AddItem(SilentKiller());
	Templates.AddItem(Executioner());
	Templates.AddItem(TargetDefinition());
	Templates.AddItem(TargetDefinitionPassive());
	Templates.AddItem(ThrowClaymore('ThrowClaymore'));
	Templates.AddItem(Highlands());
	Templates.AddItem(Distraction());
	Templates.AddItem(DistractionShadow());
	Templates.AddItem(BloodTrail());
	Templates.AddItem(Needle());
	Templates.AddItem(Shrapnel());
	Templates.AddItem(ThrowClaymore('ThrowShrapnel'));
	Templates.AddItem(PaleHorse());
	Templates.AddItem(HomingMine());
	Templates.AddItem(HomingMineDetonation());
	Templates.AddItem(RemoteStart());
	Templates.AddItem(SoulReaper());
	Templates.AddItem(SoulReaperContinue());
	Templates.AddItem(SoulHarvester());
	Templates.AddItem(Sting());
	Templates.AddItem(ImprovisedSilencer());
	Templates.AddItem(Infiltration());
	
	return Templates;
}

static function X2AbilityTemplate ShadowPassive()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Persistent                   Effect;
	local X2Effect_PersistentStatChange         StatEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ShadowPassive');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_StayConcealed';
	Effect.BuildPersistentEffect(1, true, false);
	Effect.EffectAddedFn = ShadowPassiveEffectAdded;
	Template.AddTargetEffect(Effect);

	//  mobility increased while initially concealed ... added again with each activation of Shadow
	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	StatEffect.bRemoveWhenTargetConcealmentBroken = true;
	StatEffect.AddPersistentStatChange(eStat_Mobility, default.ShadowMobilityMod, MODOP_Multiplication);
	StatEffect.EffectRemovedFn = ShadowEffectRemoved;
	Template.AddTargetEffect(StatEffect);

	Template.AddTargetEffect(ShadowAnimEffect());

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

function ShadowPassiveEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	XComGameState_Unit(kNewTargetState).bHasSuperConcealment = true;
}

static function X2Effect ShadowAnimEffect()
{
	local X2Effect_AdditionalAnimSets			Effect;

	Effect = new class'X2Effect_AdditionalAnimSets';
	Effect.EffectName = 'ShadowAnims';
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	Effect.bRemoveWhenTargetConcealmentBroken = true;
	Effect.AddAnimSetWithPath("Reaper.Anims.AS_ReaperShadow");

	return Effect;
}

//	NOTE: any changes here should probably be reflected in DistractionShadow 
static function X2AbilityTemplate Shadow()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Shadow                       StealthEffect;
	local X2Effect_PersistentStatChange         StatEffect;
	local X2AbilityCost_ActionPoints            ActionPointCost;
	local X2AbilityCharges						Charges;
	local X2AbilityCost_Charges					ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Shadow');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost =  new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_Stealth');
	Template.AddShooterEffectExclusions();

	ChargeCost = new class'X2AbilityCost_Charges';
	Template.AbilityCosts.AddItem(ChargeCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.ShadowCharges;
	Charges.AddBonusCharge('ShadowRising', default.ShadowRisingCharges);
	Template.AbilityCharges = Charges;

	StealthEffect = new class'X2Effect_Shadow';
	StealthEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	StealthEffect.bRemoveWhenTargetConcealmentBroken = true;
	StealthEffect.EffectRemovedFn = ShadowEffectRemoved;
	Template.AddTargetEffect(StealthEffect);

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	StatEffect.bRemoveWhenTargetConcealmentBroken = true;
	StatEffect.AddPersistentStatChange(eStat_Mobility, default.ShadowMobilityMod, MODOP_Multiplication);
	Template.AddTargetEffect(StatEffect);

	Template.AddTargetEffect(ShadowAnimEffect());
	Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipExitCoverWhenFiring = true;
//BEGIN AUTOGENERATED CODE: Template Overrides 'Shadow'
	Template.bSkipFireAction = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.CustomFireAnim = 'NO_ShadowStart';
	Template.ActivationSpeech = 'Shadow';
//END AUTOGENERATED CODE: Template Overrides 'Shadow'
	Template.AdditionalAbilities.AddItem('ShadowPassive');
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;
	
	return Template;
}

//  start cooling down the ability once the effect is removed (it is removed when concealment is lost)
function ShadowEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit SourceUnit;
	local XComGameState_Ability ShadowAbility;
	local StateObjectReference ShadowRef;

	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
	{
		SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		if (SourceUnit == none)
		{
			`RedScreen("Shadow effect could not find source unit. Cooldown will not start for the ability. @jbouscher @gameplay");
			return;
		}
	}
	ShadowRef = SourceUnit.FindAbility('Shadow');		//	we explicitly look for Shadow because this effect can come from other abilities
	if (ShadowRef.ObjectID > 0)
	{
		ShadowAbility = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ShadowRef.ObjectID));
		if (ShadowAbility == none)
		{
			ShadowAbility = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', ShadowRef.ObjectID));
		}
	}
	else
	{
		`RedScreen("Could not find shadow ability to trigger its cooldown. @jbouscher @gameplay");
		return;
	}
	
	ShadowAbility.iCooldown = default.ShadowCooldown;
}

static function X2AbilityTemplate ShadowRising()
{
	local X2AbilityTemplate AbilityTemplate;
	AbilityTemplate = PurePassive('ShadowRising', "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadowrising", false, 'eAbilitySource_Perk', true);
	AbilityTemplate.ActivationSpeech = 'ShadowRising';
	return AbilityTemplate;
}

static function X2AbilityTemplate SilentKiller()
{
	local X2AbilityTemplate						Template;
	local X2Effect_SilentKiller                 Effect;

	// Icon Properties
	`CREATE_X2ABILITY_TEMPLATE(Template, 'SilentKiller');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_silentkiller";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_SilentKiller';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate Executioner()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Executioner                  Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Executioner');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_executioner";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_Executioner';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate TargetDefinition()
{
	local X2AbilityTemplate					Template;
	local X2Effect_TargetDefinition			Effect;
	local X2Condition_UnitEffects			EffectsCondition;
	local X2Condition_UnitProperty			CivilianProperty;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Condition_UnitProperty			TargetCondition;
	local X2Condition_Visibility			VisibilityCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TargetDefinition');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_targetdefinition";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_UnitSeesUnit;
	Trigger.ListenerData.EventID = 'UnitSeesUnit';
	Template.AbilityTriggers.AddItem(Trigger);
	
	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddExcludeEffect(class'X2Effect_TargetDefinition'.default.EffectName, 'AA_DuplicateEffectIgnored');
	Template.AbilityTargetConditions.AddItem(EffectsCondition);

	TargetCondition = new class'X2Condition_UnitProperty';	
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = true;
	TargetCondition.ExcludeHostileToSource = false;
	Template.AbilityTargetConditions.AddItem(TargetCondition);

	//Can only apply this to targets we can see
	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bRequireGameplayVisible = true;
	VisibilityCondition.bRequireBasicVisibility = true;	
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	//Target definition is not necessary for friendlies, as they are always visible to the player

	Effect = new class'X2Effect_TargetDefinition';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.TargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Template.AddTargetEffect(Effect);

	Effect = new class'X2Effect_TargetDefinition';
	Effect.BuildPersistentEffect(1, true, false, false);
	CivilianProperty = new class'X2Condition_UnitProperty';
	CivilianProperty.ExcludeNonCivilian = true;
	CivilianProperty.ExcludeHostileToSource = false;
	CivilianProperty.ExcludeFriendlyToSource = false;
	Effect.TargetConditions.AddItem(CivilianProperty);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;

	Template.AdditionalAbilities.AddItem('TargetDefinitionPassive');
//BEGIN AUTOGENERATED CODE: Template Overrides 'TargetDefinition'
	Template.ActivationSpeech = 'TargetDefinition';
//END AUTOGENERATED CODE: Template Overrides 'TargetDefinition'

	Template.ConcealmentRule = eConceal_AlwaysEvenWithObjective;

	return Template;
}

static function X2AbilityTemplate TargetDefinitionPassive()
{
	return PurePassive('TargetDefinitionPassive', "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_targetdefinition", , 'eAbilitySource_Perk', true);
}

static function X2AbilityTemplate ThrowClaymore(name TemplateName)
{
	local X2AbilityTemplate						Template;	
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2AbilityMultiTarget_ClaymoreRadius	RadiusMultiTarget;
	local X2Effect_Claymore						ClaymoreEffect;
	local X2AbilityCharges						Charges;
	local X2AbilityCost_Charges					ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);	
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.SharedAbilityCharges.AddItem('HomingMine');
	Template.AbilityCosts.AddItem(ChargeCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.ClaymoreCharges;
	Charges.AddBonusCharge('Highlands', default.HighlandsCharges);
	Template.AbilityCharges = Charges;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = default.ClaymoreRange;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_ClaymoreRadius';
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ClaymoreEffect = new class'X2Effect_Claymore';
	ClaymoreEffect.BuildPersistentEffect(1, true, false, false);
	
	if (TemplateName == 'ThrowShrapnel')
		ClaymoreEffect.DestructibleArchetype = default.ShrapnelDestructibleArchetype;
	else
		ClaymoreEffect.DestructibleArchetype = default.ClaymoreDestructibleArchetype;
			
	Template.AddShooterEffect(ClaymoreEffect);

	if (TemplateName != 'ThrowClaymore')
		Template.OverrideAbilities.AddItem('ThrowClaymore');
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;
	
	Template.HideErrors.AddItem('AA_CannotAfford_Charges');

	Template.ConcealmentRule = eConceal_Always;

	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = ThrowClaymore_BuildVisualization;
	Template.TargetingMethod = class'X2TargetingMethod_GrenadePerkWeapon';
	Template.CinescriptCameraType = "StandardGrenadeFiring";

	Template.Hostility = eHostility_Neutral;
	Template.bAllowUnderhandAnim = true;

//BEGIN AUTOGENERATED CODE: Template Overrides 'ThrowClaymore'
//BEGIN AUTOGENERATED CODE: Template Overrides 'ThrowShrapnel'
	Template.bFrameEvenWhenUnitIsHidden = true;
	if (TemplateName == 'ThrowShrapnel')
	{
		Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shrapnel";		
	}
	else
	{
		Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_claymore";
	}
	Template.ActivationSpeech = 'claymore';
//END AUTOGENERATED CODE: Template Overrides 'ThrowShrapnel'
//END AUTOGENERATED CODE: Template Overrides 'ThrowClaymore'

	Template.BuildAppliedVisualizationSyncFn = ClaymoreVisualizationSync;
	Template.DamagePreviewFn = ClaymoreDamagePreview;

	return Template;	
}

function bool ClaymoreDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	//	Conveniently, the homing mine damage is exactly the same as the claymore damage, so we'll just use those easily grabbed values.
	if (AbilityState.GetMyTemplateName() == 'ThrowShrapnel')
	{
		MinDamagePreview = default.HomingShrapnelDamage;
	}
	else
	{
		MinDamagePreview = default.HomingMineDamage;
	}
	MaxDamagePreview = MinDamagePreview;
	return true;
}

function ClaymoreVisualizationSync(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local XComGameState_Destructible DestructibleState;
	local XComDestructibleActor DestructibleInstance;
	local X2Effect_Claymore ClaymoreEffect;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		ClaymoreEffect = X2Effect_Claymore(EffectState.GetX2Effect());
		if (ClaymoreEffect != none)
		{
			DestructibleState = XComGameState_Destructible(History.GetGameStateForObjectID(EffectState.CreatedObjectReference.ObjectID));
			DestructibleInstance = XComDestructibleActor(DestructibleState.FindOrCreateVisualizer());
			if (DestructibleInstance != none)
			{
				DestructibleInstance.TargetingIcon = ClaymoreEffect.TargetingIcon;
			}
		}
	}
}

function ThrowClaymore_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameState_Destructible DestructibleState;
	local VisualizationActionMetadata ActionMetadata;

	TypicalAbility_BuildVisualization(VisualizeGameState);

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Destructible', DestructibleState)
	{
		break;
	}
	`assert(DestructibleState != none);

	ActionMetadata.StateObject_NewState = DestructibleState;
	ActionMetadata.StateObject_OldState = DestructibleState;
	ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer(DestructibleState.ObjectID);

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
	class'X2Action_ShowSpawnedDestructible'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
}

static function X2AbilityTemplate Highlands()
{
	return PurePassive('Highlands', "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_highlands", false, 'eAbilitySource_Perk', true);
}

static function X2AbilityTemplate Distraction()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Distraction                  Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Distraction');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_distraction";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_Distraction';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.AdditionalAbilities.AddItem('DistractionShadow');
//BEGIN AUTOGENERATED CODE: Template Overrides 'Distraction'
	Template.ActivationSpeech = 'Distraction';
//END AUTOGENERATED CODE: Template Overrides 'Distraction'

	return Template;	
}

// NOTE: This should effectively be a free, conditionless copy of Shadow.
static function X2AbilityTemplate DistractionShadow()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Shadow                       StealthEffect;
	local X2Effect_PersistentStatChange         StatEffect;
	local X2Condition_Stealth					StealthCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DistractionShadow');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
//BEGIN AUTOGENERATED CODE: Template Overrides 'DistractionShadow'
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_distraction";
	Template.bSkipExitCoverWhenFiring = true;
	Template.FrameAbilityCameraType = eCameraFraming_Always;
	Template.CustomFireAnim = 'NO_ShadowStart';
	Template.ActivationSpeech = 'Shadow';
//END AUTOGENERATED CODE: Template Overrides 'DistractionShadow'

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	StealthCondition = new class'X2Condition_Stealth';
	StealthCondition.bCheckFlanking = false;
	Template.AbilityShooterConditions.AddItem(StealthCondition);
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	StealthEffect = new class'X2Effect_Shadow';
	StealthEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	StealthEffect.bRemoveWhenTargetConcealmentBroken = true;
	StealthEffect.EffectRemovedFn = ShadowEffectRemoved;
	Template.AddTargetEffect(StealthEffect);

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	StatEffect.bRemoveWhenTargetConcealmentBroken = true;
	StatEffect.AddPersistentStatChange(eStat_Mobility, default.ShadowMobilityMod, MODOP_Multiplication);
	Template.AddTargetEffect(StatEffect);

	Template.AddTargetEffect(ShadowAnimEffect());
	Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;

	return Template;
}

static function X2AbilityTemplate BloodTrail()
{
	local X2AbilityTemplate						Template;
	local X2Effect_BloodTrail					Effect;

	// Icon Properties
	`CREATE_X2ABILITY_TEMPLATE(Template, 'BloodTrail');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_BloodTrail";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_BloodTrail';
	Effect.BonusDamage = default.BloodTrailDamage;
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate Needle()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Needle						Effect;

	// Icon Properties
	`CREATE_X2ABILITY_TEMPLATE(Template, 'Needle');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Needle";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_Needle';
	Effect.ArmorPierce = default.NeedlePierce;
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate Shrapnel()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Shrapnel', "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Shrapnel");
	Template.AdditionalAbilities.AddItem('ThrowShrapnel');

	return Template;
}

static function X2AbilityTemplate PaleHorse()
{
	local X2AbilityTemplate						Template;
	local X2Effect_PaleHorse					Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PaleHorse');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_PaleHorse";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_PaleHorse';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Effect.CritBoostPerKill = default.PaleHorseCritBoost;
	Effect.MaxCritBoost = default.PaleHorseMax;
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate HomingMine()
{
	local X2AbilityTemplate							Template;
	local X2Effect_HomingMine						MineEffect;
	local X2AbilityCost_ActionPoints				ActionPointCost;
	local X2AbilityCost_Charges						ChargeCost;
	local X2AbilityCharges							Charges;
	local X2AbilityMultiTarget_Radius	            RadiusMultiTarget;	//	purely for visualization of the AOE
	local X2Condition_UnitEffects					EffectCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HomingMine');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_HomingMine";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.fTargetRadius = default.HomingMineRadius;
	RadiusMultiTarget.AddAbilityBonusRadius('Shrapnel', default.HomingShrapnelBonusRadius);
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.SharedAbilityCharges.AddItem('ThrowClaymore');
	ChargeCost.SharedAbilityCharges.AddItem('ThrowShrapnel');
	Template.AbilityCosts.AddItem(ChargeCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.ClaymoreCharges;
	Charges.AddBonusCharge('Highlands', default.HighlandsCharges);
	Template.AbilityCharges = Charges;

	Template.AddShooterEffectExclusions();
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	EffectCondition = new class'X2Condition_UnitEffects';
	EffectCondition.AddExcludeEffect(class'X2Effect_HomingMine'.default.EffectName, 'AA_UnitHasHomingMine');
	Template.AbilityTargetConditions.AddItem(EffectCondition);

	MineEffect = new class'X2Effect_HomingMine';
	MineEffect.BuildPersistentEffect(1, true, false);
	MineEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, default.HomineMinePenaltyDescription, Template.IconImage, true);
	MineEffect.AbilityToTrigger = 'HomingMineDetonation';
	Template.AddTargetEffect(MineEffect);

//BEGIN AUTOGENERATED CODE: Template Overrides 'HomingMine'
	Template.bSkipPerkActivationActions = false;
	Template.bHideWeaponDuringFire = false;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_homingmine";
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'HomingMine';
//END AUTOGENERATED CODE: Template Overrides 'HomingMine'
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.TargetingMethod = class'X2TargetingMethod_HomingMine';
	Template.bAllowUnderhandAnim = true;
	Template.AdditionalAbilities.AddItem('HomingMineDetonation');

	return Template;
}

static function X2AbilityTemplate HomingMineDetonation()
{
	local X2AbilityTemplate							Template;
	local X2AbilityToHitCalc_StandardAim			ToHit;
	local X2AbilityMultiTarget_Radius	            RadiusMultiTarget;
	local X2Condition_UnitProperty					UnitPropertyCondition;
	local X2Effect_ApplyWeaponDamage				WeaponDamage;
	local X2Effect_HomingMineDamage					MineDamage;
	local X2Condition_AbilityProperty				ShrapnelCondition;	

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HomingMineDetonation');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_HomingMine";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	ToHit = new class'X2AbilityToHitCalc_StandardAim';
	ToHit.bIndirectFire = true;
	Template.AbilityToHitCalc = ToHit;

	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.bAddPrimaryTargetAsMultiTarget = true;
	RadiusMultiTarget.fTargetRadius = default.HomingMineRadius;
	RadiusMultiTarget.AddAbilityBonusRadius('Shrapnel', default.HomingShrapnelBonusRadius);
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = false; //The grenade can affect interactive objects, others
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	//	special damage effect handles shrapnel vs regular damage
	MineDamage = new class'X2Effect_HomingMineDamage';
	MineDamage.EnvironmentalDamageAmount = default.HomingMineEnvironmentDamage;
	Template.AddMultiTargetEffect(MineDamage);

	//	bonus environmental damage for shrapnel because enviro damage is not as fancy as unit damage, we have to do it like this
	WeaponDamage = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamage.bExplosiveDamage = true;
	WeaponDamage.bIgnoreBaseDamage = true;
	WeaponDamage.EnvironmentalDamageAmount = default.HomingShrapnelEnvironmentDamage;
	ShrapnelCondition = new class'X2Condition_AbilityProperty';
	ShrapnelCondition.OwnerHasSoldierAbilities.AddItem('Shrapnel');
	WeaponDamage.TargetConditions.AddItem(ShrapnelCondition);
	Template.AddMultiTargetEffect(WeaponDamage);

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = HomingMineDetonation_BuildVisualization;
	Template.MergeVisualizationFn = HomingMineDetonation_MergeVisualization;
	Template.PostActivationEvents.AddItem('HomingMineDetonated');

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.GrenadeLostSpawnIncreasePerUse;

	return Template;
}

function HomingMineDetonation_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability AbilityContext;	
	local VisualizationActionMetadata VisTrack;
	local X2Action_PlayEffect EffectAction;
	local X2Action_SpawnImpactActor ImpactAction;
	//local X2Action_CameraLookAt LookAtAction;
	//local X2Action_Delay DelayAction;
	local X2Action_StartStopSound SoundAction;
	local XComGameState_Unit ShooterUnit;
	local Array<X2Action> ParentActions;
	local X2Action_MarkerNamed JoinAction;
	local XComGameStateHistory History;
	local X2Action_WaitForAbilityEffect WaitForFireEvent;
	local XComGameStateVisualizationMgr VisMgr;
	local Array<X2Action> NodesToParentToWait;
	local int ScanAction;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());	

	VisTrack.StateObjectRef = AbilityContext.InputContext.SourceObject;
	VisTrack.VisualizeActor = History.GetVisualizer(VisTrack.StateObjectRef.ObjectID);
	History.GetCurrentAndPreviousGameStatesForObjectID(VisTrack.StateObjectRef.ObjectID,
													   VisTrack.StateObject_OldState, VisTrack.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);	

	WaitForFireEvent = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(VisTrack, AbilityContext));
	//Camera comes first
// 	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, WaitForFireEvent));
// 	LookAtAction.LookAtLocation = AbilityContext.InputContext.TargetLocations[0];
// 	LookAtAction.BlockUntilFinished = true;
// 	LookAtAction.LookAtDuration = 2.0f;
	
	ImpactAction = X2Action_SpawnImpactActor( class'X2Action_SpawnImpactActor'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, WaitForFireEvent) );
	ParentActions.AddItem(ImpactAction);

	ImpactAction.ImpactActorName = default.HomingMineImpactArchetype;
	ImpactAction.ImpactLocation = AbilityContext.InputContext.TargetLocations[0];
	ImpactAction.ImpactLocation.Z = `XWORLD.GetFloorZForPosition( ImpactAction.ImpactLocation );
	ImpactAction.ImpactNormal = vect(0, 0, 1);

	//Do the detonation
	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, WaitForFireEvent));
	ParentActions.AddItem(EffectAction);

	ShooterUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(VisTrack.StateObjectRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex));
	if (ShooterUnit.HasSoldierAbility('Shrapnel'))
		EffectAction.EffectName = default.HomingShrapnelExplosionFX;		
	else 
		EffectAction.EffectName = default.HomingMineExplosionFX;
	`CONTENT.RequestGameArchetype(EffectAction.EffectName);

	EffectAction.EffectLocation = AbilityContext.InputContext.TargetLocations[0];
	EffectAction.EffectRotation = Rotator(vect(0, 0, 1));
	EffectAction.bWaitForCompletion = false;
	EffectAction.bWaitForCameraCompletion = false;

	SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, WaitForFireEvent));
	ParentActions.AddItem(SoundAction);
	SoundAction.Sound = new class'SoundCue';

	if (ShooterUnit.HasSoldierAbility('Shrapnel'))
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Proximity_Mine_Explosion';	//	@TODO - update sound
	else 
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Proximity_Mine_Explosion';	//	@TODO - update sound

	SoundAction.bIsPositional = true;
	SoundAction.vWorldPosition = AbilityContext.InputContext.TargetLocations[0];

	JoinAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, None, ParentActions));
	JoinAction.SetName("Join");

	TypicalAbility_BuildVisualization(VisualizeGameState);
	
	// Jwats: Reparent all of the apply weapon damage actions to the wait action since this visualization doesn't have a fire anim
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', NodesToParentToWait);
	for( ScanAction = 0; ScanAction < NodesToParentToWait.Length; ++ScanAction )
	{
		VisMgr.DisconnectAction(NodesToParentToWait[ScanAction]);
		VisMgr.ConnectAction(NodesToParentToWait[ScanAction], VisMgr.BuildVisTree, false, WaitForFireEvent);
		VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree, false, NodesToParentToWait[ScanAction]);
	}

	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToTerrain', NodesToParentToWait);
	for( ScanAction = 0; ScanAction < NodesToParentToWait.Length; ++ScanAction )
	{
		VisMgr.DisconnectAction(NodesToParentToWait[ScanAction]);
		VisMgr.ConnectAction(NodesToParentToWait[ScanAction], VisMgr.BuildVisTree, false, WaitForFireEvent);
		VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree, false, NodesToParentToWait[ScanAction]);
	}	

	//Keep the camera there after things blow up
// 	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(VisTrack, AbilityContext));
// 	DelayAction.Duration = 0.5;
}

function HomingMineDetonation_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action_WaitForAbilityEffect WaitForFireEvent;
	local Array<X2Action> DamageActions;
	local int ScanAction;
	local X2Action_ApplyWeaponDamageToUnit TestDamage;
	local X2Action_ApplyWeaponDamageToUnit PlaceWithAction;
	local X2Action_MarkerTreeInsertBegin MarkerStart;
	local XComGameStateContext_Ability Context;

	VisMgr = `XCOMVISUALIZATIONMGR;

	MarkerStart = X2Action_MarkerTreeInsertBegin(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin'));
	Context = XComGameStateContext_Ability(MarkerStart.StateChangeContext);

	// Jwats: Find the apply weapon damage to unit that caused us to explode and put our visualization with it
	WaitForFireEvent = X2Action_WaitForAbilityEffect(VisMgr.GetNodeOfType(BuildTree, class'X2Action_WaitForAbilityEffect'));
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_ApplyWeaponDamageToUnit', DamageActions, , Context.InputContext.PrimaryTarget.ObjectID);
	for( ScanAction = 0; ScanAction < DamageActions.Length; ++ScanAction )
	{
		TestDamage = X2Action_ApplyWeaponDamageToUnit(DamageActions[ScanAction]);
		if( TestDamage.StateChangeContext.AssociatedState.HistoryIndex == Context.DesiredVisualizationBlockIndex )
		{
			PlaceWithAction = TestDamage;
			break;
		}
	}
	
	if( PlaceWithAction != None )
	{
		VisMgr.DisconnectAction(WaitForFireEvent);
		VisMgr.ConnectAction(WaitForFireEvent, VisualizationTree, false, None, PlaceWithAction.ParentActions);
	}
	else
	{
		Context.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
	}
}

static function X2AbilityTemplate RemoteStart()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2Effect_RemoteStart			RemoteStartEffect;
	local X2AbilityCost_Ammo			AmmoCost;
	local X2AbilityCooldown				Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RemoteStart');
		
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;

	Template.SuperConcealmentLoss = 0;
	Template.ConcealmentRule = eConceal_Always;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = new class'X2AbilityTarget_RemoteStart';
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AddShooterEffectExclusions();

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.RemoteStartCooldown;
	Template.AbilityCooldown = Cooldown;

	RemoteStartEffect = new class'X2Effect_RemoteStart';
	RemoteStartEffect.UnitDamageMultiplier = default.RemoteStartDamageMultiplier;
	RemoteStartEffect.DamageRadiusMultiplier = default.RemoteStartRadiusMultiplier;
	Template.AddTargetEffect(RemoteStartEffect);

	Template.bLimitTargetIcons = true;
	Template.DamagePreviewFn = RemoteStartDamagePreview;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.TargetingMethod = class'X2TargetingMethod_RemoteStart';

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'RemoteStart'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_remotestart";
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'RemoteStart';
//END AUTOGENERATED CODE: Template Overrides 'RemoteStart'

	return Template;
}

function bool RemoteStartDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComDestructibleActor DestructibleActor;
	local XComDestructibleActor_Action_RadialDamage DamageAction;
	local int i;

	DestructibleActor = XComDestructibleActor(`XCOMHISTORY.GetVisualizer(TargetRef.ObjectID));
	if (DestructibleActor != none)
	{
		for (i = 0; i < DestructibleActor.DestroyedEvents.Length; ++i)
		{
			if (DestructibleActor.DestroyedEvents[i].Action != None)
			{
				DamageAction = XComDestructibleActor_Action_RadialDamage(DestructibleActor.DestroyedEvents[i].Action);
				if (DamageAction != none)
				{
					MinDamagePreview.Damage += DamageAction.UnitDamage * default.RemoteStartDamageMultiplier;
					MaxDamagePreview.Damage += DamageAction.UnitDamage * default.RemoteStartDamageMultiplier;
				}
			}
		}
	}

	return true;
}

static function X2AbilityTemplate SoulReaper()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityCharges					Charges;
	local X2AbilityCost_Charges				ChargeCost;
	local X2AbilityToHitCalc_StandardAim	StandardAim;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'SoulReaper');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	//  require 2 ammo to be present so that multiple shots will be taken - otherwise it's a waste
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 2;
	AmmoCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(AmmoCost);
	//  actually charge 1 ammo for this shot. the 2nd shot will charge the extra ammo.
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = 1;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bAllowCrit = false;
	StandardAim.BuiltInHitMod = default.BanishFirstShotAimMod;
	Template.AbilityToHitCalc = StandardAim;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.SuperConcealmentLoss = 0;

	Template.AdditionalAbilities.AddItem('SoulReaperContinue');
	Template.PostActivationEvents.AddItem('SoulReaperContinue');

	//	this ability will always break concealment at the end and we don't want to roll on it
	Template.ConcealmentRule = eConceal_Always;
	Template.SuperConcealmentLoss = 0;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'SoulReaper'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_soulreaper";
	Template.ActivationSpeech = 'Banish';
//END AUTOGENERATED CODE: Template Overrides 'SoulReaper'

	return Template;
}

static function X2AbilityTemplate SoulReaperContinue()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityTrigger_EventListener    Trigger;
	local X2AbilityToHitCalc_StandardAim	StandardAim;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SoulReaperContinue');

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bAllowCrit = false;
	StandardAim.BuiltInHitMod = default.BanishSubsequentShotsAimMod;
	Template.AbilityToHitCalc = StandardAim;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'SoulReaperContinue';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.SoulReaperListener;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.MergeVisualizationFn = SequentialShot_MergeVisualization;
	Template.SuperConcealmentLoss = 0;

	Template.PostActivationEvents.AddItem('SoulReaperContinue');
	Template.bShowActivation = true;

	//	this ability will always break concealment at the end and we don't want to roll on it
	Template.ConcealmentRule = eConceal_Always;
	Template.SuperConcealmentLoss = 0;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'SoulReaperContinue'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_soulreaper";
//END AUTOGENERATED CODE: Template Overrides 'SoulReaperContinue'

	return Template;
}

static function X2AbilityTemplate SoulHarvester()
{
	local X2AbilityTemplate				Template;

	Template = PurePassive('SoulHarvester', "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_SoulHarvester");
	Template.PrerequisiteAbilities.AddItem('SoulReaper');
//BEGIN AUTOGENERATED CODE: Template Overrides 'SoulHarvester'	
	Template.ActivationSpeech = 'Annihilate';
//END AUTOGENERATED CODE: Template Overrides 'SoulHarvester'

	return Template;
}

static function X2AbilityTemplate Sting()
{
	local X2AbilityTemplate					Template;
	local X2Condition_UnitProperty          ConcealedCondition;
	local X2AbilityCooldown					Cooldown;
	local X2AbilityCharges					Charges;
	local X2AbilityCost_Charges				ChargeCost;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('Sting', false, false, false);
	Template.SuperConcealmentLoss = 0;
	Template.ConcealmentRule = eConceal_Always;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CAPTAIN_PRIORITY;

	ConcealedCondition = new class'X2Condition_UnitProperty';
	ConcealedCondition.ExcludeFriendlyToSource = false;
	ConcealedCondition.IsSuperConcealed = true;
	Template.AbilityShooterConditions.AddItem(ConcealedCondition);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.StingCooldown;
	Template.AbilityCooldown = Cooldown;

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.StingCharges;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	Template.AbilityCosts.AddItem(ChargeCost);

//BEGIN AUTOGENERATED CODE: Template Overrides 'Sting'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'Sting';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_sting";
//END AUTOGENERATED CODE: Template Overrides 'Sting'

	return Template;
}

static function X2AbilityTemplate ImprovisedSilencer()
{
	local X2AbilityTemplate					  Template;
	local X2Effect_SuperConcealModifier		  ConcealmentModifier;
	local X2AbilityTrigger_OnAbilityActivated ActivationTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ImprovisedSilencer');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	ActivationTrigger = new class'X2AbilityTrigger_OnAbilityActivated';
	ActivationTrigger.SetListenerData('Shadow');
	Template.AbilityTriggers.AddItem(ActivationTrigger);
	ActivationTrigger = new class'X2AbilityTrigger_OnAbilityActivated';
	ActivationTrigger.SetListenerData('DistractionShadow');
	Template.AbilityTriggers.AddItem(ActivationTrigger);

	ConcealmentModifier = new class'X2Effect_SuperConcealModifier';
	ConcealmentModifier.bRemoveWhenTargetConcealmentBroken = true;
	ConcealmentModifier.bRemoveWhenTargetDies = true;

	ConcealmentModifier.ConcealAmountScalar = default.ImprovisedSilencerShadowBreakScalar;

	ConcealmentModifier.AbilitiesAffectedFilter = default.ImprovisedSilencerAffectedAbilities;
	ConcealmentModifier.RemoveOnAbilityActivation = default.ImprovisedSilencerAffectedAbilities;

	Template.AddTargetEffect( ConcealmentModifier );

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
//BEGIN AUTOGENERATED CODE: Template Overrides 'ImprovisedSilencer'
	Template.bSkipFireAction = true;
//END AUTOGENERATED CODE: Template Overrides 'ImprovisedSilencer'

	return Template;
}

static function X2AbilityTemplate Infiltration()
{
	local X2AbilityTemplate             Template;
	local X2Effect_PersistentStatChange PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Infiltration');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Infiltration";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PersistentEffect = new class'X2Effect_PersistentStatChange';
	PersistentEffect.BuildPersistentEffect(1, true, false);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	PersistentEffect.AddPersistentStatChange(eStat_Hacking, default.InfiltrationHackBonus);
	Template.AddTargetEffect(PersistentEffect);

	Template.SetUIStatMarkup(class'XLocalizedData'.default.TechLabel, eStat_Hacking, default.InfiltrationHackBonus);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}
