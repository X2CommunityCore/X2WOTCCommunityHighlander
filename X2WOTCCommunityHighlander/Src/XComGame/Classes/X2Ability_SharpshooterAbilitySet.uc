//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_SharpshooterAbilitySet.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    15 Jul 2014
//  PURPOSE: Defines abilities used by the Sharpshooter class.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_SharpshooterAbilitySet extends X2Ability
	config(GameData_SoldierSkills);

var config int HITWHEREITHURTS_CRIT;

var localized string SteadyHandsBonusDesc;
var localized string SharpshooterAimBonusName;
var localized string SharpshooterAimBonusDesc;

var config int STEADYHANDS_AIM_BONUS, STEADYHANDS_CRIT_BONUS;
var config int DEADEYE_COOLDOWN;
var config float DEADEYE_AIM_MULTIPLIER;
var config int FACEOFF_COOLDOWN;
var config int FANFIRE_COOLDOWN;
var config int KILLZONE_COOLDOWN;
var config int SERIAL_COOLDOWN;
var config int SHARPSHOOTERAIM_BONUS;
var config int LIGHTNINGHANDS_COOLDOWN;
var Name KillZoneReserveType;           //  Type of action point to reserve for KillZone ability.

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(AddSquadsightAbility());
	Templates.AddItem(LongWatch());
	Templates.AddItem(LongWatchShot());
	Templates.AddItem(DeadeyeAbility());
	Templates.AddItem(DeadeyeDamage());
	Templates.AddItem(DeathFromAbove());
	Templates.AddItem(ReturnFire());
	Templates.AddItem(AddHitWhereItHurtsAbility());
	Templates.AddItem(PurePassive('Quickdraw', "img:///UILibrary_PerkIcons.UIPerk_quickdraw"));
	Templates.AddItem(FanFire());
	Templates.AddItem(SteadyHands());
	Templates.AddItem(LightningHands());
	Templates.AddItem(InTheZone());
	Templates.AddItem(KillZone());
	Templates.AddItem(KillZoneShot());
	Templates.AddItem(Faceoff());
	Templates.AddItem(PurePassive('SharpshooterAim', "img:///UILibrary_PerkIcons.UIPerk_aim", true));

	return Templates;
}

//******** Squadsight Ability **********
static function X2AbilityTemplate AddSquadsightAbility()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_Squadsight                   Squadsight;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Squadsight');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_squadsight";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	Squadsight = new class'X2Effect_Squadsight';
	Squadsight.BuildPersistentEffect(1, true, true, true);
	Squadsight.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	Template.AddTargetEffect(Squadsight);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate LongWatch()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;
	local array<name>                       SkipExclusions;
	local X2Effect_CoveringFire             CoveringFireEffect;
	local X2Condition_AbilityProperty       CoveringFireCondition;
	local X2Condition_UnitProperty          ConcealedCondition;
	local X2Effect_SetUnitValue             UnitValueEffect;
	local X2Condition_UnitEffects           SuppressedCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LongWatch');
	
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true;                  //  ammo is consumed by the shot, not by this, but this should verify ammo is available
	Template.AbilityCosts.AddItem(AmmoCost);
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	ActionPointCost.AllowedTypes.RemoveItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);
	
	ReserveActionPointsEffect = new class'X2Effect_ReserveOverwatchPoints';
	Template.AddTargetEffect(ReserveActionPointsEffect);

	CoveringFireEffect = new class'X2Effect_CoveringFire';
	CoveringFireEffect.AbilityToActivate = 'OverwatchShot';
	CoveringFireEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	CoveringFireCondition = new class'X2Condition_AbilityProperty';
	CoveringFireCondition.OwnerHasSoldierAbilities.AddItem('CoveringFire');
	CoveringFireEffect.TargetConditions.AddItem(CoveringFireCondition);
	Template.AddTargetEffect(CoveringFireEffect);

	ConcealedCondition = new class'X2Condition_UnitProperty';
	ConcealedCondition.ExcludeFriendlyToSource = false;
	ConcealedCondition.IsConcealed = true;
	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = class'X2Ability_DefaultAbilitySet'.default.ConcealedOverwatchTurn;
	UnitValueEffect.CleanupType = eCleanup_BeginTurn;
	UnitValueEffect.NewValueToSet = 1;
	UnitValueEffect.TargetConditions.AddItem(ConcealedCondition);
	Template.AddTargetEffect(UnitValueEffect);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_CannotAfford_ActionPoints');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_long_watch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_DefaultAbilitySet'.static.OverwatchAbility_BuildVisualization;
	Template.CinescriptCameraType = "Overwatch";

	Template.Hostility = eHostility_Defensive;

	Template.OverrideAbilities.AddItem('SniperRifleOverwatch');
	Template.AdditionalAbilities.AddItem('LongWatchShot');

	Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_Y;
	Template.bNoConfirmationWithHotKey = true;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;
	
	return Template;	
}

static function X2AbilityTemplate LongWatchShot()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ReserveActionPoints ReserveActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2Condition_UnitProperty          ShooterCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_EventListener	Trigger;
	local array<name>                       SkipExclusions;
	local X2Condition_Visibility            TargetVisibilityCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LongWatchShot');
	
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;	
	Template.AbilityCosts.AddItem(AmmoCost);
	
	ReserveActionPointCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveActionPointCost.iNumPoints = 1;
	ReserveActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint);
	Template.AbilityCosts.AddItem(ReserveActionPointCost);
	
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bReactionFire = true;
	Template.AbilityToHitCalc = StandardAim;
	Template.AbilityToHitOwnerOnMissCalc = StandardAim;

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bDisablePeeksOnMovement = true;
	TargetVisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(new class'X2Condition_EverVigilant');
	Template.AbilityTargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);	
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;
	
	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	//Trigger on movement - interrupt the move
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'ObjectMoved';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalOverwatchListener;
	Template.AbilityTriggers.AddItem(Trigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.DisplayTargetHitChance = false;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bAllowFreeFireWeaponUpgrade = false;	

	//  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	// Damage Effect
	//
	Template.AddTargetEffect(default.WeaponUpgradeMissDamage);

	Template.OverrideAbilities.AddItem('OverwatchShot');

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'LongWatchShot'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'LongWatchShot'
	
	return Template;	
}

static function X2AbilityTemplate DeadeyeAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCooldown                 Cooldown;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Deadeye');

	Template.AdditionalAbilities.AddItem('DeadeyeDamage');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_deadeye";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	Template.bUsesFiringCamera = true;
	Template.CinescriptCameraType = "StandardGunFiring";

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.DEADEYE_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.FinalMultiplier = default.DEADEYE_AIM_MULTIPLIER;
	Template.AbilityToHitCalc = ToHitCalc;

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	//  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.AddTargetEffect(default.WeaponUpgradeMissDamage);

	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bCrossClassEligible = true;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.ActivationSpeech = 'DeadEye';

	return Template;
}

static function X2AbilityTemplate DeadeyeDamage()
{
	local X2AbilityTemplate						Template;
	local X2Effect_DeadeyeDamage                DamageEffect;

	// Icon Properties
	`CREATE_X2ABILITY_TEMPLATE(Template, 'DeadeyeDamage');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_momentum";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	DamageEffect = new class'X2Effect_DeadeyeDamage';
	DamageEffect.BuildPersistentEffect(1, true, false, false);
	DamageEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false,,Template.AbilitySourceName);
	Template.AddTargetEffect(DamageEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate DeathFromAbove()
{
	local X2AbilityTemplate						Template;
	local X2Effect_DeathFromAbove               DeathEffect;

	// Icon Properties
	`CREATE_X2ABILITY_TEMPLATE(Template, 'DeathFromAbove');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_DeathFromAbove";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bCrossClassEligible = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	DeathEffect = new class'X2Effect_DeathFromAbove';
	DeathEffect.BuildPersistentEffect(1, true, false, false);
	DeathEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(DeathEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.bCrossClassEligible = true;

	return Template;
}

static function X2AbilityTemplate ReturnFire(name TemplateName = 'ReturnFire')
{
	local X2AbilityTemplate						Template;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_ReturnFire                   FireEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_returnfire";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	FireEffect = new class'X2Effect_ReturnFire';
	FireEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnBegin);
	FireEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	Template.AddTargetEffect(FireEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.bCrossClassEligible = false;       //  this can only work with pistols, which only sharpshooters have

	return Template;
}

//******** Hit Where It Hurts Ability **********
static function X2AbilityTemplate AddHitWhereItHurtsAbility()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_ToHitModifier                ToHitModifier;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HitWhereItHurts');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hithurts";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	ToHitModifier = new class'X2Effect_ToHitModifier';
	ToHitModifier.BuildPersistentEffect(1, true, true, true);
	ToHitModifier.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	ToHitModifier.AddEffectHitModifier(eHit_Crit, default.HITWHEREITHURTS_CRIT, Template.LocFriendlyName, /*StandardAim*/, false, true, true, true);
	Template.AddTargetEffect(ToHitModifier);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate FanFire()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2AbilityMultiTarget_BurstFire    BurstFireMultiTarget;
	local X2AbilityCooldown                 Cooldown;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;

	// Macro to do localisation and stuffs
	`CREATE_X2ABILITY_TEMPLATE(Template, 'FanFire');

	// Icon Properties
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_fanfire";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.DisplayTargetHitChance = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	
	// Activated by a button press; additionally, tells the AI this is an activatable
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// *** VALIDITY CHECKS *** //
	Template.AddShooterEffectExclusions();

	// Targeting Details
	// Can only shoot visible enemies
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	// Can't target dead; Can't target friendlies
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	// Can't shoot while dead
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	// Only at single targets that are in range.
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	// Action Point
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);	

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.FANFIRE_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	// Ammo
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	Template.bAllowAmmoEffects = true; // 	
	Template.bAllowBonusWeaponEffects = true;

	// Weapon Upgrade Compatibility
	Template.bAllowFreeFireWeaponUpgrade = true;                                            // Flag that permits action to become 'free action' via 'Hair Trigger' or similar upgrade / effects

	// Damage Effect
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	Template.AddTargetEffect(WeaponDamageEffect);
	Template.AddMultiTargetEffect(WeaponDamageEffect);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

	BurstFireMultiTarget = new class'X2AbilityMultiTarget_BurstFire';
	BurstFireMultiTarget.NumExtraShots = 2;
	Template.AbilityMultiTargetStyle = BurstFireMultiTarget;
		
	// Targeting Method
	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	Template.CinescriptCameraType = "StandardGunFiring";

	// Voice events
	Template.ActivationSpeech = 'FanFire';

	// MAKE IT LIVE!
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'FanFire'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'FanFire'

	return Template;	
}

static function X2AbilityTemplate SteadyHands()
{
	local X2AbilityTemplate             Template;
	local X2Effect_Persistent           PersistentEffect;
	local X2Effect_PersistentStatChange StatChangeEffect;
	local X2Condition_UnitValue         ValueCondition;
	local X2Condition_PlayerTurns       TurnsCondition;
	local X2AbilityTag                  AbilityTag;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SteadyHands');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_steadyhands";
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	//  this effect stays on the unit indefinitely
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.EffectName = 'SteadyHands';
	PersistentEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName);

	//  each turn this effect is applied
	StatChangeEffect = new class'X2Effect_PersistentStatChange';
	StatChangeEffect.EffectName = 'SteadyHandsStatBoost';
	StatChangeEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	StatChangeEffect.AddPersistentStatChange(eStat_Offense, default.STEADYHANDS_AIM_BONUS);
	StatChangeEffect.AddPersistentStatChange(eStat_CritChance, default.STEADYHANDS_CRIT_BONUS);

	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = StatChangeEffect;

	StatChangeEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, `XEXPAND.ExpandString(default.SteadyHandsBonusDesc), Template.IconImage, true);

	// bsg-dforrest (7.27.17): need to clear out ParseObject
	AbilityTag.ParseObj = none;
	// bsg-dforrest (7.27.17): end

	//  this condition check guarantees the unit did not move last turn before allowing the bonus to be applied
	ValueCondition = new class'X2Condition_UnitValue';
	ValueCondition.AddCheckValue('MovesLastTurn', 0, eCheck_Exact);
	StatChangeEffect.TargetConditions.AddItem(ValueCondition);
	//  this condition guarantees the player has started more than 1 turn. the first turn of the game does not count for steady hands, as there was no "previous" turn.
	TurnsCondition = new class'X2Condition_PlayerTurns';
	TurnsCondition.NumTurnsCheck.CheckType = eCheck_GreaterThan;
	TurnsCondition.NumTurnsCheck.Value = 1;
	StatChangeEffect.TargetConditions.AddItem(TurnsCondition);

	PersistentEffect.ApplyOnTick.AddItem(StatChangeEffect);
	Template.AddShooterEffect(PersistentEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate LightningHands()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo                AmmoCost;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local array<name>                       SkipExclusions;
	local X2AbilityCooldown					Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LightningHands');

	// Icon Properties
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_lightninghands";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.DisplayTargetHitChance = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	// Activated by a button press; additionally, tells the AI this is an activatable
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.LIGHTNINGHANDS_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	// *** VALIDITY CHECKS *** //
	//  Normal effect restrictions (except disoriented)
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Targeting Details
	// Can only shoot visible enemies
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	// Can't target dead; Can't target friendlies
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	// Can't shoot while dead
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	// Only at single targets that are in range.
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	// Ammo
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	Template.bAllowAmmoEffects = true; // 	
	Template.bAllowBonusWeaponEffects = true;

	Template.AbilityCosts.AddItem(default.FreeActionCost);

	// Damage Effect
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	Template.AddTargetEffect(WeaponDamageEffect);

	// Hit Calculation (Different weapons now have different calculations for range)
	Template.AbilityToHitCalc = default.SimpleStandardAim;
	Template.AbilityToHitOwnerOnMissCalc = default.SimpleStandardAim;

	// Targeting Method
	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	Template.bUsesFiringCamera = true;
	Template.CinescriptCameraType = "StandardGunFiring";

	// MAKE IT LIVE!
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'LightningHands'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.ActivationSpeech = 'LightningHands';
//END AUTOGENERATED CODE: Template Overrides 'LightningHands'

	return Template;
}

static function X2AbilityTemplate InTheZone()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCooldown				Cooldown;
	local X2Effect_Serial               SerialEffect;
	local X2AbilityCost_ActionPoints    ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'InTheZone');

	// Icon Properties
	Template.DisplayTargetHitChance = false;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_InTheZone";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.SERIAL_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	class'X2Ability_RangerAbilitySet'.static.SuperKillRestrictions(Template, 'Serial_SuperKillCheck');
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	SerialEffect = new class'X2Effect_Serial';
	SerialEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	SerialEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(SerialEffect);

	Template.AbilityTargetStyle = default.SelfTarget;	
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	Template.ActivationSpeech = 'InTheZone';
	Template.bCrossClassEligible = true;
		
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

simulated function XComGameState InTheZone_BuildGameState(XComGameStateContext Context)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit ShooterState, TargetState;
	local XComGameState_Ability AbilityState;
	local array<name> PreActionPoints;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;

	//Build the new game state frame, and unit state object for the moving unit
	AbilityContext = XComGameStateContext_Ability(Context);
	ShooterState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	`assert(ShooterState != none);

	PreActionPoints = ShooterState.ActionPoints;
	NewGameState = TypicalAbility_BuildGameState(Context);
	
	TargetState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	`assert(TargetState != none);
	if (TargetState.IsDead())
	{
		//	restore action points to shooter
		ShooterState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ShooterState.ObjectID));
		`assert(ShooterState != none);
		ShooterState.ActionPoints = PreActionPoints;
		//	reset cooldown
		AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
		`assert(AbilityState != none);
		AbilityState.iCooldown = 0;
	}
	return NewGameState;
}

static function X2AbilityTemplate KillZone(name AbilityName='KillZone', bool bDisplayZone=false)
{
	local X2AbilityTemplate             Template;
	local X2AbilityCooldown             Cooldown;
	local X2AbilityCost_Ammo            AmmoCost;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2AbilityTarget_Cursor        CursorTarget;
	local X2AbilityMultiTarget_Cone     ConeMultiTarget;
	local X2Effect_ReserveActionPoints  ReservePointsEffect;
	local X2Effect_MarkValidActivationTiles MarkTilesEffect;
	local X2Condition_UnitEffects           SuppressedCondition;
	local X2Effect_Persistent			KillZoneEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(AmmoCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	ActionPointCost.AllowedTypes.RemoveItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.KILLZONE_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	ConeMultiTarget = new class'X2AbilityMultiTarget_Cone';
	ConeMultiTarget.bUseWeaponRadius = true;
	ConeMultiTarget.ConeEndDiameter = 32 * class'XComWorldData'.const.WORLD_StepSize;
	ConeMultiTarget.ConeLength = 60 * class'XComWorldData'.const.WORLD_StepSize;
	Template.AbilityMultiTargetStyle = ConeMultiTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ReservePointsEffect = new class'X2Effect_ReserveActionPoints';
	ReservePointsEffect.ReserveType = default.KillZoneReserveType;
	Template.AddShooterEffect(ReservePointsEffect);

	MarkTilesEffect = new class'X2Effect_MarkValidActivationTiles';
	MarkTilesEffect.AbilityToMark = 'KillZoneShot';
	MarkTilesEffect.bVisualizeFlagsOnCursor = bDisplayZone;
	Template.AddShooterEffect(MarkTilesEffect);

	if (bDisplayZone)
	{
		// Add persistent effect on shooter to be able to have a callback on load, 
		// so the pathing pawn is notified to display a flag on Killzone tiles on load.
		KillZoneEffect = new class'X2Effect_Persistent';
		KillZoneEffect.EffectName = 'KillZoneSource';
		KillZoneEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
		Template.AddShooterEffect(KillZoneEffect);
	}

	Template.AdditionalAbilities.AddItem('KillZoneShot');
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.TargetingMethod = class'X2TargetingMethod_Cone';
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_killzone";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.Hostility = eHostility_Defensive;
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

	Template.ActivationSpeech = 'KillZone';
	
	Template.bCrossClassEligible = true;
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;
	
	return Template;
}

static function X2AbilityTemplate KillZoneShot()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityCost_ReserveActionPoints ReserveActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2Condition_AbilityProperty       AbilityCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Persistent               KillZoneEffect;
	local X2Condition_UnitEffectsWithAbilitySource  KillZoneCondition;
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2Condition_UnitProperty          ShooterCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'KillZoneShot');

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	ReserveActionPointCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveActionPointCost.iNumPoints = 1;
	ReserveActionPointCost.bFreeCost = true;
	ReserveActionPointCost.AllowedTypes.AddItem('KillZone');
	Template.AbilityCosts.AddItem(ReserveActionPointCost);

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bReactionFire = true;
	Template.AbilityToHitCalc = StandardAim;

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bDisablePeeksOnMovement = true;
	TargetVisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);
	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.TargetMustBeInValidTiles = true;
	Template.AbilityTargetConditions.AddItem(AbilityCondition);
	Template.AbilityTargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());

	//  Do not shoot targets that were already hit by this unit this turn with this ability
	KillZoneCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	KillZoneCondition.AddExcludeEffect('KillZoneTarget', 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(KillZoneCondition);
	//  Mark the target as shot by this unit so it cannot be shot again this turn
	KillZoneEffect = new class'X2Effect_Persistent';
	KillZoneEffect.EffectName = 'KillZoneTarget';
	KillZoneEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	KillZoneEffect.SetupEffectOnShotContextResult(true, true);      //  mark them regardless of whether the shot hit or missed
	Template.AddTargetEffect(KillZoneEffect);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);
	Template.AddShooterEffectExclusions();

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	//  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());

	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	//Trigger on movement - interrupt the move
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'ObjectMoved';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalOverwatchListener;
	Template.AbilityTriggers.AddItem(Trigger);
	//  trigger on an attack
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalAttackListener;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

//BEGIN AUTOGENERATED CODE: Template Overrides 'KillZoneShot'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'KillZoneShot'

	return Template;
}

static function X2AbilityTemplate Faceoff()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCooldown                 Cooldown;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityMultiTarget_AllUnits		MultiTargetUnits;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Faceoff');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_faceoff";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.FACEOFF_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.bOnlyMultiHitWithSuccess = false;
	Template.AbilityToHitCalc = ToHitCalc;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	MultiTargetUnits = new class'X2AbilityMultiTarget_AllUnits';
	MultiTargetUnits.bUseAbilitySourceAsPrimaryTarget = true;
	MultiTargetUnits.bAcceptEnemyUnits = true;
	Template.AbilityMultiTargetStyle = MultiTargetUnits;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);

	Template.AddTargetEffect(new class'X2Effect_ApplyWeaponDamage');
	Template.AddMultiTargetEffect(new class'X2Effect_ApplyWeaponDamage');

	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Faceoff_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'Faceoff'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.ActivationSpeech = 'Faceoff';
//END AUTOGENERATED CODE: Template Overrides 'Faceoff'

	return Template;
}

function Faceoff_BuildVisualization(XComGameState VisualizeGameState)
{
	local X2AbilityTemplate             AbilityTemplate;
	local XComGameStateContext_Ability  Context;
	local AbilityInputContext           AbilityContext;
	local StateObjectReference          ShootingUnitRef;
	local X2Action_Fire                 FireAction;
	local X2Action_Fire_Faceoff         FireFaceoffAction;
	local XComGameState_BaseObject      TargetStateObject;//Container for state objects within VisualizeGameState	

	local Actor                     TargetVisualizer, ShooterVisualizer;
	local X2VisualizerInterface     TargetVisualizerInterface;
	local int                       EffectIndex, TargetIndex;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;
	local VisualizationActionMetadata        SourceTrack;
	local XComGameStateHistory      History;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local name         ApplyResult;

	local X2Action_StartCinescriptCamera CinescriptStartAction;
	local X2Action_EndCinescriptCamera   CinescriptEndAction;
	local X2Camera_Cinescript            CinescriptCamera;
	local string                         PreviousCinescriptCameraType;
	local X2Effect                       TargetEffect;

	local X2Action_MarkerNamed				JoinActions;
	local array<X2Action>					LeafNodes;
	local XComGameStateVisualizationMgr		VisualizationMgr;
	local X2Action_ApplyWeaponDamageToUnit	ApplyWeaponDamageAction;


	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityContext = Context.InputContext;
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.AbilityTemplateName);
	ShootingUnitRef = Context.InputContext.SourceObject;

	ShooterVisualizer = History.GetVisualizer(ShootingUnitRef.ObjectID);

	SourceTrack = EmptyTrack;
	SourceTrack.StateObject_OldState = History.GetGameStateForObjectID(ShootingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(ShootingUnitRef.ObjectID);
	if( SourceTrack.StateObject_NewState == none )
		SourceTrack.StateObject_NewState = SourceTrack.StateObject_OldState;
	SourceTrack.VisualizeActor = ShooterVisualizer;

	if( AbilityTemplate.ActivationSpeech != '' )     //  allows us to change the template without modifying this function later
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(SourceTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.ActivationSpeech, eColor_Good);
	}


	// Add a Camera Action to the Shooter's Metadata.  Minor hack: To create a CinescriptCamera the AbilityTemplate 
	// must have a camera type.  So manually set one here, use it, then restore.
	PreviousCinescriptCameraType = AbilityTemplate.CinescriptCameraType;
	AbilityTemplate.CinescriptCameraType = "StandardGunFiring";
	CinescriptCamera = class'X2Camera_Cinescript'.static.CreateCinescriptCameraForAbility(Context);
	CinescriptStartAction = X2Action_StartCinescriptCamera(class'X2Action_StartCinescriptCamera'.static.AddToVisualizationTree(SourceTrack, Context, false, SourceTrack.LastActionAdded));
	CinescriptStartAction.CinescriptCamera = CinescriptCamera;
	AbilityTemplate.CinescriptCameraType = PreviousCinescriptCameraType;


	class'X2Action_ExitCover'.static.AddToVisualizationTree(SourceTrack, Context, false, SourceTrack.LastActionAdded);

	//  Fire at the primary target first
	FireAction = X2Action_Fire(class'X2Action_Fire'.static.AddToVisualizationTree(SourceTrack, Context, false, SourceTrack.LastActionAdded));
	FireAction.SetFireParameters(Context.IsResultContextHit(), , false);
	//  Setup target response
	TargetVisualizer = History.GetVisualizer(AbilityContext.PrimaryTarget.ObjectID);
	TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);
	ActionMetadata = EmptyTrack;
	ActionMetadata.VisualizeActor = TargetVisualizer;
	TargetStateObject = VisualizeGameState.GetGameStateForObjectID(AbilityContext.PrimaryTarget.ObjectID);
	if( TargetStateObject != none )
	{
		History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.PrimaryTarget.ObjectID,
														   ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState,
														   eReturnType_Reference,
														   VisualizeGameState.HistoryIndex);
		`assert(ActionMetadata.StateObject_NewState == TargetStateObject);
	}
	else
	{
		//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
		//and show no change.
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.PrimaryTarget.ObjectID);
		ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
	}

	for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex )
	{
		ApplyResult = Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]);

		// Target effect visualization
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, ApplyResult);

		// Source effect visualization
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceTrack, ApplyResult);
	}
	if( TargetVisualizerInterface != none )
	{
		//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
		TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
	}

	ApplyWeaponDamageAction = X2Action_ApplyWeaponDamageToUnit(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', TargetVisualizer));
	if ( ApplyWeaponDamageAction != None)
	{
		VisualizationMgr.DisconnectAction(ApplyWeaponDamageAction);
		VisualizationMgr.ConnectAction(ApplyWeaponDamageAction, VisualizationMgr.BuildVisTree, false, FireAction);
	}

	//  Now configure a fire action for each multi target
	for( TargetIndex = 0; TargetIndex < AbilityContext.MultiTargets.Length; ++TargetIndex )
	{
		// Add an action to pop the previous CinescriptCamera off the camera stack.
		CinescriptEndAction = X2Action_EndCinescriptCamera(class'X2Action_EndCinescriptCamera'.static.AddToVisualizationTree(SourceTrack, Context, false, SourceTrack.LastActionAdded));
		CinescriptEndAction.CinescriptCamera = CinescriptCamera;
		CinescriptEndAction.bForceEndImmediately = true;

		// Add an action to push a new CinescriptCamera onto the camera stack.
		AbilityTemplate.CinescriptCameraType = "StandardGunFiring";
		CinescriptCamera = class'X2Camera_Cinescript'.static.CreateCinescriptCameraForAbility(Context);
		CinescriptCamera.TargetObjectIdOverride = AbilityContext.MultiTargets[TargetIndex].ObjectID;
		CinescriptStartAction = X2Action_StartCinescriptCamera(class'X2Action_StartCinescriptCamera'.static.AddToVisualizationTree(SourceTrack, Context, false, SourceTrack.LastActionAdded));
		CinescriptStartAction.CinescriptCamera = CinescriptCamera;
		AbilityTemplate.CinescriptCameraType = PreviousCinescriptCameraType;

		// Add a custom Fire action to the shooter Metadata.
		TargetVisualizer = History.GetVisualizer(AbilityContext.MultiTargets[TargetIndex].ObjectID);
		FireFaceoffAction = X2Action_Fire_Faceoff(class'X2Action_Fire_Faceoff'.static.AddToVisualizationTree(SourceTrack, Context, false, SourceTrack.LastActionAdded));
		FireFaceoffAction.SetFireParameters(Context.IsResultContextMultiHit(TargetIndex), AbilityContext.MultiTargets[TargetIndex].ObjectID, false);
		FireFaceoffAction.vTargetLocation = TargetVisualizer.Location;


		//  Setup target response
		TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);
		ActionMetadata = EmptyTrack;
		ActionMetadata.VisualizeActor = TargetVisualizer;
		TargetStateObject = VisualizeGameState.GetGameStateForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID);
		if( TargetStateObject != none )
		{
			History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID,
															   ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState,
															   eReturnType_Reference,
															   VisualizeGameState.HistoryIndex);
			`assert(ActionMetadata.StateObject_NewState == TargetStateObject);
		}
		else
		{
			//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
			//and show no change.
			ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID);
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
		}

		for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityMultiTargetEffects.Length; ++EffectIndex )
		{
			TargetEffect = AbilityTemplate.AbilityMultiTargetEffects[EffectIndex];
			ApplyResult = Context.FindMultiTargetEffectApplyResult(TargetEffect, TargetIndex);

			// Target effect visualization
			AbilityTemplate.AbilityMultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, ApplyResult);

			// Source effect visualization
			AbilityTemplate.AbilityMultiTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceTrack, ApplyResult);
		}
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}

		ApplyWeaponDamageAction = X2Action_ApplyWeaponDamageToUnit(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', TargetVisualizer));
		if( ApplyWeaponDamageAction != None )
		{
			VisualizationMgr.DisconnectAction(ApplyWeaponDamageAction);
			VisualizationMgr.ConnectAction(ApplyWeaponDamageAction, VisualizationMgr.BuildVisTree, false, FireFaceoffAction);
		}
	}
	class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceTrack, Context, false, SourceTrack.LastActionAdded);

	// Add an action to pop the last CinescriptCamera off the camera stack.
	CinescriptEndAction = X2Action_EndCinescriptCamera(class'X2Action_EndCinescriptCamera'.static.AddToVisualizationTree(SourceTrack, Context, false, SourceTrack.LastActionAdded));
	CinescriptEndAction.CinescriptCamera = CinescriptCamera;

	//Add a join so that all hit reactions and other actions will complete before the visualization sequence moves on. In the case
	// of fire but no enter cover then we need to make sure to wait for the fire since it isn't a leaf node
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

	if( VisualizationMgr.BuildVisTree.ChildActions.Length > 0 )
	{
		JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SourceTrack, Context, false, none, LeafNodes));
		JoinActions.SetName("Join");
	}
}

static function X2Effect_Persistent SharpshooterAimEffect()
{
	local X2Effect_SharpshooterAim      AimEffect;
	local X2Condition_AbilityProperty   AbilityCondition;

	AimEffect = new class'X2Effect_SharpshooterAim';
	AimEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	AimEffect.SetDisplayInfo(ePerkBuff_Bonus, default.SharpshooterAimBonusName, default.SharpshooterAimBonusDesc, "img:///UILibrary_PerkIcons.UIPerk_aim");
	
	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('SharpshooterAim');
	AimEffect.TargetConditions.AddItem(AbilityCondition);

	return AimEffect;
}

defaultproperties
{
	KillZoneReserveType = "KillZone";
}
