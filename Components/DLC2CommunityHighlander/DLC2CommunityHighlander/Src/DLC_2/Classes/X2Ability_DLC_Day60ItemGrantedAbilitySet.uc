//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_DLC_Day60ItemGrantedAbilitySet.uc
//  AUTHOR:  Joe Weinhoffer  --  1/26/2016
//  PURPOSE: Defines abilities made available to XCom soldiers through their equipped inventory items in X-Com 2. 
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_DLC_Day60ItemGrantedAbilitySet extends X2Ability
	dependson(XComGameStateContext_Ability) config(GameCore);

var config int MEDIUM_ALIEN_HEALTH_BONUS;
var config int MEDIUM_ALIEN_MOBILITY_BONUS;
var config int MEDIUM_ALIEN_MITIGATION_AMOUNT;
var config int MEDIUM_ALIEN_MITIGATION_CHANCE;

var config int HEAVY_ALIEN_HEALTH_BONUS;
var config int HEAVY_ALIEN_MOBILITY_BONUS;
var config int HEAVY_ALIEN_MITIGATION_AMOUNT;
var config int HEAVY_ALIEN_MITIGATION_CHANCE;

var config int HEAVY_ALIEN_MK2_HEALTH_BONUS;
var config int HEAVY_ALIEN_MK2_MOBILITY_BONUS;
var config int HEAVY_ALIEN_MK2_MITIGATION_AMOUNT;
var config int HEAVY_ALIEN_MK2_MITIGATION_CHANCE;

var config int LIGHT_ALIEN_HEALTH_BONUS;
var config int LIGHT_ALIEN_MOBILITY_BONUS;
var config int LIGHT_ALIEN_DODGE_BONUS;

var config int LIGHT_ALIEN_MK2_HEALTH_BONUS;
var config int LIGHT_ALIEN_MK2_MOBILITY_BONUS;
var config int LIGHT_ALIEN_MK2_DODGE_BONUS;

var config int HEAVY_ALIEN_PANIC_CHANCE;
var config int MEDIUM_ALIEN_PANIC_CHANCE;
var config int LIGHT_ALIEN_PANIC_CHANCE;

var config int HEAVY_ALIEN_PANIC_PER_POD;
var config int MEDIUM_ALIEN_PANIC_PER_POD;
var config int LIGHT_ALIEN_PANIC_PER_POD;

var name HEAVY_ALIEN_PANIC_TESTED;
var name MEDIUM_ALIEN_PANIC_TESTED;
var name LIGHT_ALIEN_PANIC_TESTED;

var config int ICARUS_JUMP_CHARGES;
var config int SHADOWFALL_CHARGES;

var config int FREEZINGLASH_MAX_RANGE;
var config int FREEZINGLASH_MIN_RULER_FREEZE_DURATION;
var config int FREEZINGLASH_MAX_RULER_FREEZE_DURATION;

/// <summary>
/// Creates the set of abilities granted to units through their equipped items in X-Com 2
/// </summary>
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2AbilityTemplate AbilityTemplate;
		
	Templates.AddItem(MediumAlienArmorStats());
	Templates.AddItem(HeavyAlienArmorStats());
	Templates.AddItem(HeavyAlienArmorMk2Stats());
	Templates.AddItem(LightAlienArmorStats());
	Templates.AddItem(LightAlienArmorMk2Stats());
	Templates.AddItem(Shadowfall());
	Templates.AddItem(ShadowfallConcealment());
	Templates.AddItem(ThrowAxe());
	Templates.AddItem(AddRagestrikeAbility());
	Templates.AddItem(AddVaultAbility());
	Templates.AddItem(PurePassive('VaultAbilityPassive', "img:///UILibrary_DLC2Images.UIPerk_icarusvault"));
	Templates.AddItem(AddRagePanicAbility());
	Templates.AddItem(AddIcarusPanicAbility());
	Templates.AddItem(AddSerpentPanicAbility());
	Templates.AddItem(FreezingLash());
	Templates.AddItem(IcarusJump());

	AbilityTemplate = class'X2Ability_DefaultAbilitySet'.static.AddObjectiveInteractAbility('Interact_DLC2Transmitter');
	AbilityTemplate.RemoveTemplateAvailablility(AbilityTemplate.BITFIELD_GAMEAREA_Multiplayer);
	Templates.AddItem(AbilityTemplate);
	return Templates;
}

static function X2AbilityTemplate MediumAlienArmorStats()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MediumAlienArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	// giving health here; medium plated doesn't have mitigation
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.MEDIUM_ALIEN_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.MEDIUM_ALIEN_MOBILITY_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, default.MEDIUM_ALIEN_MITIGATION_CHANCE);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.MEDIUM_ALIEN_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate HeavyAlienArmorStats()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HeavyAlienArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.HEAVY_ALIEN_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.HEAVY_ALIEN_MOBILITY_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, default.HEAVY_ALIEN_MITIGATION_CHANCE);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.HEAVY_ALIEN_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate HeavyAlienArmorMk2Stats()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HeavyAlienArmorMk2Stats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.HEAVY_ALIEN_MK2_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.HEAVY_ALIEN_MK2_MOBILITY_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, default.HEAVY_ALIEN_MK2_MITIGATION_CHANCE);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.HEAVY_ALIEN_MK2_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate LightAlienArmorStats()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LightAlienArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	// light armor has dodge and mobility as well as health
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.LIGHT_ALIEN_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.LIGHT_ALIEN_MOBILITY_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Dodge, default.LIGHT_ALIEN_DODGE_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate LightAlienArmorMk2Stats()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LightAlienArmorMk2Stats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	// light armor has dodge and mobility as well as health
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.LIGHT_ALIEN_MK2_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.LIGHT_ALIEN_MK2_MOBILITY_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Dodge, default.LIGHT_ALIEN_MK2_DODGE_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate Shadowfall()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityCharges                  Charges;
	local X2AbilityCost_Charges             ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Shadowfall');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.SHADOWFALL_CHARGES;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.bGuaranteedHit = true;
	ToHitCalc.bAllowCrit = false;
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	Template.AddTargetEffect(new class'X2Effect_ApplyWeaponDamage');
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;
	Template.ConcealmentRule = eConceal_KillShot;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_shadowfall";
//BEGIN AUTOGENERATED CODE: Template Overrides 'Shadowfall'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "";
//END AUTOGENERATED CODE: Template Overrides 'Shadowfall'

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	Template.CinescriptCameraType = "Shadowkeeper_Shadowfall";
	Template.bUsesFiringCamera = true;
	Template.AdditionalAbilities.AddItem('ShadowfallConcealment');
	Template.CustomFireAnim = 'FF_Fire_Shadowfall';

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	return Template;
}

static function X2AbilityTemplate ShadowfallConcealment()
{
	local X2AbilityTemplate						Template;
	local X2Effect_DLC_Day60Shadowfall          ConcealEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ShadowfallConcealment');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shadowfall";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	ConcealEffect = new class'X2Effect_DLC_Day60Shadowfall';
	ConcealEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(ConcealEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate ThrowAxe()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local array<name>                       SkipExclusions;
	local X2AbilityCost_Ammo                AmmoCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ThrowAxe');

	// Icon Properties
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_throwaxe";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailableOrNoTargets;
	Template.DisplayTargetHitChance = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	Template.bUseAmmoAsChargesForHUD = true;

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

	Template.bAllowBonusWeaponEffects = true;

	Template.AbilityCosts.AddItem(default.FreeActionCost);

	// Damage Effect
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	Template.AddTargetEffect(WeaponDamageEffect);

	Template.AbilityToHitCalc = default.SimpleStandardAim;
	Template.AbilityToHitOwnerOnMissCalc = default.SimpleStandardAim;

	Template.bHideWeaponDuringFire = true;
	Template.SkipRenderOfTargetingTemplate = true;
	Template.TargetingMethod = class'X2TargetingMethod_DLC_2ThrowAxe';
	Template.CinescriptCameraType = "Huntman_ThrowAxe";
	Template.bUsesFiringCamera = true;

	// Disabling standard VO for now, until we get axe specific stuff
	Template.TargetKilledByAlienSpeech='';
	Template.TargetKilledByXComSpeech='';
	Template.MultiTargetsKilledByAlienSpeech='';
	Template.MultiTargetsKilledByXComSpeech='';
	Template.TargetWingedSpeech='';
	Template.TargetArmorHitSpeech='';
	Template.TargetMissedSpeech='';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
		
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MeleeLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'ThrowAxe'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'ThrowAxe'

	return Template;
}

static function X2AbilityTemplate AddRagestrikeAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;
	local X2AbilityCooldown Cooldown;
	local X2AbilityToHitCalc_StandardAim StandardAim;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local X2Effect_ImmediateAbilityActivation BrainDamageAbilityEffect;
	local X2AbilityTarget_MovingMelee MovingMeleeTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ragestrike');
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_ragestrike";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	Template.AdditionalAbilities.AddItem(class'X2Ability_Impairing'.default.ImpairingAbilityName);

	Template.AbilityCosts.AddItem(default.FreeActionCost);

	Charges = new class 'X2AbilityCharges';
	Charges.InitialCharges = 1;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	Template.AbilityCosts.AddItem(default.FreeActionCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 3;
	Template.AbilityCooldown = Cooldown;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bGuaranteedHit = true;
	Template.AbilityToHitCalc = StandardAim;

	MovingMeleeTarget = new class'X2AbilityTarget_MovingMelee';
	Template.AbilityTargetStyle = MovingMeleeTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DLC_Day60Weapons'.default.RAGESUIT_RAGESTRIKE_BASEDAMAGE;
	Template.AddTargetEffect(PhysicalDamageEffect);

	//Impairing effects need to come after the damage. This is needed for proper visualization ordering.
	//Effect on a successful melee attack is triggering the BrainDamage Ability
	BrainDamageAbilityEffect = new class 'X2Effect_ImmediateAbilityActivation';
	BrainDamageAbilityEffect.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	BrainDamageAbilityEffect.EffectName = 'ImmediateBrainDamage';
	// NOTICE: For now StunLancer, Muton, and Berserker all use this ability. This may change.
	BrainDamageAbilityEffect.AbilityName = class'X2Ability_Impairing'.default.ImpairingAbilityName;
	BrainDamageAbilityEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	BrainDamageAbilityEffect.bRemoveWhenTargetDies = true;
	BrainDamageAbilityEffect.VisualizationFn = class'X2Ability_Impairing'.static.ImpairingAbilityEffectTriggeredVisualization;
	Template.AddTargetEffect(BrainDamageAbilityEffect);

	Template.CustomFireAnim = 'FF_RageStrike';
	Template.CustomMovingFireAnim = 'MV_RageStrike';
	Template.CustomMovingTurnLeftFireAnim = 'MV_RunTun90LeftRageStrike';
	Template.CustomMovingTurnRightFireAnim = 'MV_RunTun90RightRageStrike';
	Template.bSkipMoveStop = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.bOverrideMeleeDeath = true;
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.CinescriptCameraType = "Soldier_RageStrike";

	Template.PostActivationEvents.AddItem('RulerArmorAbilityActivated');

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	return Template;
}

static function X2AbilityTemplate AddVaultAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentTraversalChange	JumpUpEffect;
	local X2Condition_AbilityProperty		VaultConditional;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'VaultAbility');
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_icarusvault";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	// Bonus to hacking stat Effect
	//
	JumpUpEffect = new class'X2Effect_PersistentTraversalChange';
	JumpUpEffect.BuildPersistentEffect(1, true, true, false);
	JumpUpEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	JumpUpEffect.AddTraversalChange(eTraversal_JumpUp, true);
	JumpUpEffect.EffectName = 'JumpUpEffect';
	JumpUpEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(JumpUpEffect);

	VaultConditional = new class'X2Condition_AbilityProperty';
	VaultConditional.OwnerHasSoldierAbilities.AddItem('VaultAbility');
	Template.AbilityShooterConditions.AddItem(VaultConditional);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate AddRagePanicAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitValue				TargetAlreadyTestedCondition;
	local X2Condition_UnitType				UnitTypeCondition;
	local X2Condition_PanicOnPod            PanicOnPodCondition;
	local X2Effect_SetUnitValue				SetUnitValEffect;
	local X2Condition_UnitProperty          ShooterCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Panicked					PanickedEffect;
	local X2AbilityToHitCalc_PercentChance	PercentChanceToHit;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RagePanic');

	Template.bDontDisplayInAbilitySummary = true;

	PercentChanceToHit = new class'X2AbilityToHitCalc_PercentChance';
	PercentChanceToHit.PercentToHit = default.HEAVY_ALIEN_PANIC_CHANCE;
	Template.AbilityToHitCalc = PercentChanceToHit;

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);

	TargetAlreadyTestedCondition = new class'X2Condition_UnitValue';
	TargetAlreadyTestedCondition.AddCheckValue(default.HEAVY_ALIEN_PANIC_TESTED, 0, eCheck_Exact);
	Template.AbilityTargetConditions.AddItem(TargetAlreadyTestedCondition);

	UnitTypeCondition = new class'X2Condition_UnitType';
	UnitTypeCondition.IncludeTypes.AddItem('Muton');
	UnitTypeCondition.IncludeTypes.AddItem('Berserker');
	Template.AbilityTargetConditions.AddItem(UnitTypeCondition);

	PanicOnPodCondition = new class'X2Condition_PanicOnPod';
	PanicOnPodCondition.MaxPanicUnitsPerPod = default.HEAVY_ALIEN_PANIC_PER_POD;
	Template.AbilityTargetConditions.AddItem(PanicOnPodCondition);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = false;
	Template.AbilityTargetStyle = SingleTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_UnitSeesUnit;
	Trigger.ListenerData.EventID = 'UnitSeesUnit';
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.ARMOR_ACTIVE_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.DisplayTargetHitChance = false;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.bAllowFreeFireWeaponUpgrade = false;
	Template.bAllowAmmoEffects = false;

	// Damage Effect
	//
	PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
	PanickedEffect.VisualizationFn = ArmorPanickedVisualization; // Overwriting Default Panic
	Template.AddTargetEffect(PanickedEffect);

	SetUnitValEffect = new class'X2Effect_SetUnitValue';
	SetUnitValEffect.UnitName = default.HEAVY_ALIEN_PANIC_TESTED;
	SetUnitValEffect.NewValueToSet = 1;
	SetUnitValEffect.CleanupType = eCleanup_BeginTactical;
	SetUnitValEffect.bApplyOnHit = true;
	SetUnitValEffect.bApplyOnMiss = true;
	Template.AddTargetEffect(SetUnitValEffect);

	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
//BEGIN AUTOGENERATED CODE: Template Overrides 'RagePanic'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'RagePanic'

	return Template;
}

static function X2AbilityTemplate AddIcarusPanicAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitValue				TargetAlreadyTestedCondition;
	local X2Condition_UnitType				UnitTypeCondition;
	local X2Condition_PanicOnPod            PanicOnPodCondition;
	local X2Effect_SetUnitValue				SetUnitValEffect;
	local X2Condition_UnitProperty          ShooterCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Panicked					PanickedEffect;
	local X2AbilityToHitCalc_PercentChance	PercentChanceToHit;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IcarusPanic');

	Template.bDontDisplayInAbilitySummary = true;

	PercentChanceToHit = new class'X2AbilityToHitCalc_PercentChance';
	PercentChanceToHit.PercentToHit = default.MEDIUM_ALIEN_PANIC_CHANCE;
	Template.AbilityToHitCalc = PercentChanceToHit;

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);

	TargetAlreadyTestedCondition = new class'X2Condition_UnitValue';
	TargetAlreadyTestedCondition.AddCheckValue(default.MEDIUM_ALIEN_PANIC_TESTED, 0, eCheck_Exact);
	Template.AbilityTargetConditions.AddItem(TargetAlreadyTestedCondition);

	UnitTypeCondition = new class'X2Condition_UnitType';
	UnitTypeCondition.IncludeTypes.AddItem('Archon');
	Template.AbilityTargetConditions.AddItem(UnitTypeCondition);

	PanicOnPodCondition = new class'X2Condition_PanicOnPod';
	PanicOnPodCondition.MaxPanicUnitsPerPod = default.MEDIUM_ALIEN_PANIC_PER_POD;
	Template.AbilityTargetConditions.AddItem(PanicOnPodCondition);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = false;
	Template.AbilityTargetStyle = SingleTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_UnitSeesUnit;
	Trigger.ListenerData.EventID = 'UnitSeesUnit';
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.ARMOR_ACTIVE_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.DisplayTargetHitChance = false;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.bAllowFreeFireWeaponUpgrade = false;
	Template.bAllowAmmoEffects = false;

	// Damage Effect
	//
	PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
	PanickedEffect.VisualizationFn = ArmorPanickedVisualization; // Overwriting Default Panic
	Template.AddTargetEffect(PanickedEffect);

	SetUnitValEffect = new class'X2Effect_SetUnitValue';
	SetUnitValEffect.UnitName = default.MEDIUM_ALIEN_PANIC_TESTED;
	SetUnitValEffect.NewValueToSet = 1;
	SetUnitValEffect.CleanupType = eCleanup_BeginTactical;
	SetUnitValEffect.bApplyOnHit = true;
	SetUnitValEffect.bApplyOnMiss = true;
	Template.AddTargetEffect(SetUnitValEffect);

	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
//BEGIN AUTOGENERATED CODE: Template Overrides 'IcarusPanic'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'IcarusPanic'

	return Template;
}

static function X2AbilityTemplate AddSerpentPanicAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitValue				TargetAlreadyTestedCondition;
	local X2Condition_UnitType				UnitTypeCondition;
	local X2Condition_PanicOnPod            PanicOnPodCondition;
	local X2Effect_SetUnitValue				SetUnitValEffect;
	local X2Condition_UnitProperty          ShooterCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Panicked					PanickedEffect;
	local X2AbilityToHitCalc_PercentChance	PercentChanceToHit;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SerpentPanic');

	Template.bDontDisplayInAbilitySummary = true;

	PercentChanceToHit = new class'X2AbilityToHitCalc_PercentChance';
	PercentChanceToHit.PercentToHit = default.LIGHT_ALIEN_PANIC_CHANCE;
	Template.AbilityToHitCalc = PercentChanceToHit;

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);

	TargetAlreadyTestedCondition = new class'X2Condition_UnitValue';
	TargetAlreadyTestedCondition.AddCheckValue(default.LIGHT_ALIEN_PANIC_TESTED, 0, eCheck_Exact);
	Template.AbilityTargetConditions.AddItem(TargetAlreadyTestedCondition);

	UnitTypeCondition = new class'X2Condition_UnitType';
	UnitTypeCondition.IncludeTypes.AddItem('Viper');
	Template.AbilityTargetConditions.AddItem(UnitTypeCondition);

	PanicOnPodCondition = new class'X2Condition_PanicOnPod';
	PanicOnPodCondition.MaxPanicUnitsPerPod = default.LIGHT_ALIEN_PANIC_PER_POD;
	Template.AbilityTargetConditions.AddItem(PanicOnPodCondition);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = false;
	Template.AbilityTargetStyle = SingleTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_UnitSeesUnit;
	Trigger.ListenerData.EventID = 'UnitSeesUnit';
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.ARMOR_ACTIVE_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.DisplayTargetHitChance = false;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.bAllowFreeFireWeaponUpgrade = false;
	Template.bAllowAmmoEffects = false;

	// Damage Effect
	//
	PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
	PanickedEffect.VisualizationFn = ArmorPanickedVisualization; // Overwriting Default Panic
	//PanickedEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(PanickedEffect);

	SetUnitValEffect = new class'X2Effect_SetUnitValue';
	SetUnitValEffect.UnitName = default.LIGHT_ALIEN_PANIC_TESTED;
	SetUnitValEffect.NewValueToSet = 1;
	SetUnitValEffect.CleanupType = eCleanup_BeginTactical;
	SetUnitValEffect.bApplyOnHit = true;
	SetUnitValEffect.bApplyOnMiss = true;
	Template.AddTargetEffect(SetUnitValEffect);

	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
//BEGIN AUTOGENERATED CODE: Template Overrides 'SerpentPanic'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'SerpentPanic'

	return Template;
}

static function ArmorPanickedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability  AbilityContext;
	local X2AbilityTemplate AbilityTemplate;

	if (EffectApplyResult != 'AA_Success')
	{
		return;
	}

	// pan to the panicking unit (but only if it isn't a civilian)
	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	class'X2StatusEffects'.static.AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());
	class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), AbilityTemplate.LocFlyOverText, '', eColor_Bad, , 1.0f);
	class'X2StatusEffects'.static.AddEffectMessageToTrack(ActionMetadata,
														  AbilityTemplate.LocFlyOverText,
														  VisualizeGameState.GetContext(),
														  class'UIEventNoticesTactical'.default.PanickedTitle,
														  "img:///UILibrary_StrategyImages.X2StrategyMap.MapPin_Generic",
														  eUIState_Bad);

	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

simulated function FreezingLash_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate;
	local StateObjectReference          InteractingUnitRef;
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyover;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;

	local int							EffectIndex;

	local X2Action_DLC_Day60FreezingLash FreezingLashAction;
	local X2VisualizerInterface Visualizer;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	InteractingUnitRef = Context.InputContext.SourceObject;
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	class'X2Action_ExitCover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	FreezingLashAction = X2Action_DLC_Day60FreezingLash(class'X2Action_DLC_Day60FreezingLash'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	FreezingLashAction.SetFireParameters(Context.IsResultContextHit());

	Visualizer = X2VisualizerInterface(ActionMetadata.VisualizeActor);
	if( Visualizer != none )
	{
		Visualizer.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
	}

	class'X2Action_EnterCover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

	
	//****************************************************************************************

	//Configure the visualization track for the target
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

	for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex )
	{
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
	}

	if( Context.IsResultContextMiss() && AbilityTemplate.LocMissMessage != "" )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocMissMessage, '', eColor_Bad);
	}

		//****************************************************************************************
}

static function X2AbilityTemplate FreezingLash()
{
	local X2AbilityTemplate Template;
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;
	local X2AbilityCooldown Cooldown;
	local X2Condition_UnitProperty UnitPropertyCondition, FreezingLashTargetConditions;
	local X2Condition_Visibility TargetVisibilityCondition;
	local X2AbilityTarget_Single SingleTarget;
	local X2AbilityToHitCalc_StandardAim StandardAim;
	local X2AbilityTrigger_PlayerInput InputTrigger;
	local X2Effect_DLC_Day60FreezingLash FreezingLashEffect;
	local X2Effect_DLC_Day60Freeze FreezeEffect;
	local X2Condition_UnitEffects FreezeExcludeEffects, FreezingLashExcludeEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FreezingLash');
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_freezinglash";

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;

	Charges = new class 'X2AbilityCharges';
	Charges.InitialCharges = 1;
	Template.AbilityCharges = Charges;
	
	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	ChargeCost.bOnlyOnHit = true;
	Template.AbilityCosts.AddItem(ChargeCost);
	
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 2;
	Cooldown.bDoNotApplyOnHit = true;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityCosts.AddItem(default.FreeActionCost);
	
	// Shooter must be alive
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target can't be dead and must be humanoid
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.RequireWithinMinRange = true;
	UnitPropertyCondition.RequireWithinRange = true;
	UnitPropertyCondition.WithinRange = default.FREEZINGLASH_MAX_RANGE;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	// Target must be visible and not in high cover
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	FreezeExcludeEffects = new class'X2Condition_UnitEffects';
	FreezeExcludeEffects.AddExcludeEffect(class'X2Effect_DLC_Day60Freeze'.default.EffectName, 'AA_UnitIsFrozen');
	Template.AbilityTargetConditions.AddItem(FreezeExcludeEffects);

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	// This will attack using the standard aim
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = StandardAim;

	// Apply the effect that pulls the unit to the soldier
	FreezingLashEffect = new class'X2Effect_DLC_Day60FreezingLash';
	FreezingLashTargetConditions = new class'X2Condition_UnitProperty';
	FreezingLashTargetConditions.ExcludeRobotic = true;
	FreezingLashTargetConditions.ExcludeAlien = true;
	FreezingLashTargetConditions.ExcludeStunned = true;
	FreezingLashEffect.TargetConditions.AddItem(FreezingLashTargetConditions);

	FreezingLashExcludeEffects = new class'X2Condition_UnitEffects';
	FreezingLashExcludeEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BoundName, 'AA_UnitIsBound');
	FreezingLashExcludeEffects.AddExcludeEffect(class'X2Effect_PersistentVoidConduit'.default.EffectName, 'AA_UnitIsBound');
	FreezingLashEffect.TargetConditions.AddItem(FreezingLashExcludeEffects);

	Template.AddTargetEffect(FreezingLashEffect);

	FreezeEffect = class'X2Effect_DLC_Day60Freeze'.static.CreateFreezeEffect(default.FREEZINGLASH_MIN_RULER_FREEZE_DURATION, default.FREEZINGLASH_MAX_RULER_FREEZE_DURATION);
	FreezeEffect.bAllowReorder = false;
	Template.AddTargetEffect(FreezeEffect);
	Template.AddTargetEffect(class'X2Effect_DLC_Day60Freeze'.static.CreateFreezeRemoveEffects());

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = FreezingLash_BuildVisualization;

	Template.CinescriptCameraType = "Viper_StranglePull";

	Template.PostActivationEvents.AddItem('RulerArmorAbilityActivated');

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MeleeLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'FreezingLash'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'FreezingLash'

	return Template;
}

static function X2AbilityTemplate IcarusJump()
{
	local X2AbilityTemplate Template;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityMultiTarget_Radius RadiusMultiTarget;
	local X2AbilityCost_Charges ChargeCost;
	local X2AbilityCharges Charges;
	local X2AbilityCooldown Cooldown;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_Persistent IcarusJumpEffect;
	local X2Condition_UnitEffects UnitEffectsCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IcarusJump');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_icarusjump";

	Template.AbilityCosts.AddItem(default.FreeActionCost);

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.ICARUS_JUMP_CHARGES;
	Template.AbilityCharges = Charges;
	
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 2;
	Template.AbilityCooldown = Cooldown;

	Template.TargetingMethod = class'X2TargetingMethod_DLC_2IcarusJump';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityToHitCalc = default.DeadEye;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.fTargetRadius = 0.25; // small amount so it just grabs one tile
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_CarryingUnit');
	Template.AbilityShooterConditions.AddItem(UnitEffectsCondition);

	Template.AddShooterEffectExclusions();

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem('IcarusJumpEffect');
	Template.AddShooterEffect(RemoveEffects);

	IcarusJumpEffect = new class'X2Effect_Persistent';
	IcarusJumpEffect.BuildPersistentEffect(1, false, true);
	IcarusJumpEffect.DuplicateResponse = eDupe_Refresh;
	IcarusJumpEffect.EffectName = 'IcarusJumpEffect';
	IcarusJumpEffect.EffectAddedFn = IcarusJump_EffectAdded;
	Template.AddShooterEffect(IcarusJumpEffect);
	
	Template.PostActivationEvents.AddItem('RulerArmorAbilityActivated');

	Template.ModifyNewContextFn = class'X2Ability_Cyberus'.static.Teleport_ModifyActivatedAbilityContext;
	Template.BuildNewGameStateFn = class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.static.IcarusJump_BuildGameState;
	Template.BuildVisualizationFn = IcarusJump_BuildVisualization;
//BEGIN AUTOGENERATED CODE: Template Overrides 'IcarusJump'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'IcarusJump'

	return Template;
}

static simulated function XComGameState IcarusJump_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local X2EventManager EventManager;

	NewGameState = class'X2Ability_Cyberus'.static.Teleport_BuildGameState(Context);

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));

	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent('UnitIcarusJumped', UnitState, UnitState, NewGameState);

	return NewGameState;
}

static function IcarusJump_EffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComWorldData World;
	local X2EventManager EventManager;
	local XComGameState_Unit UnitState;
	local TTile StartTileLocation, EndTileLocation, Tile;
	local XComGameState_EnvironmentDamage WorldDamage;

	World = `XWORLD;
	EventManager = `XEVENTMGR;

	UnitState = XComGameState_Unit(kNewTargetState);
	`assert(UnitState != none);

	StartTileLocation = UnitState.TileLocation;
	EndTileLocation = UnitState.TileLocation;
	EndTileLocation.Z = World.NumZ;

	Tile = StartTileLocation;
	while( Tile != EndTileLocation )
	{
		++Tile.Z;

		WorldDamage = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));

		WorldDamage.DamageTypeTemplateName = 'NoFireExplosion';
		WorldDamage.DamageCause = UnitState.GetReference();
		WorldDamage.DamageSource = WorldDamage.DamageCause;
		WorldDamage.bRadialDamage = false;
		WorldDamage.HitLocationTile = Tile;
		WorldDamage.DamageTiles.AddItem(WorldDamage.HitLocationTile);

		WorldDamage.DamageDirection.X = 0.0f;
		WorldDamage.DamageDirection.Y = 0.0f;
		WorldDamage.DamageDirection.Z = -1.0f;

		WorldDamage.DamageAmount = 30;
		WorldDamage.PhysImpulse = 10;
	}

	EventManager.TriggerEvent('ObjectMoved', UnitState, UnitState, NewGameState);
	EventManager.TriggerEvent('UnitMoveFinished', UnitState, UnitState, NewGameState);
}

simulated function IcarusJump_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationActionMetadata EmptyTrack, ActionMetadata;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local int i, j;
	local XComGameState_WorldEffectTileData WorldDataUpdate;
	local X2Action_MoveTurn MoveTurnAction;
	local X2VisualizerInterface TargetVisualizerInterface;
	local XComGameState_EnvironmentDamage DamageEventStateObject;
	local X2Action_CameraFollowUnit CameraAction;
	local XComGameStateVisualizationMgr VisualizationMgr;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	//****************************************************************************************
	//Configure the visualization track for the source
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good);

	// Turn to face the target action. The target location is the center of the ability's radius, stored in the 0 index of the TargetLocations
	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	MoveTurnAction.m_vFacePoint = AbilityContext.InputContext.TargetLocations[0];

	// move action
	class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, ActionMetadata);

	CameraAction = X2Action_CameraFollowUnit(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_MoveEnd', ActionMetadata.VisualizeActor));
	if (CameraAction != none)
	{
		CameraAction.bLockFloorZ = true;
	}

	//****************************************************************************************

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldDataUpdate)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.VisualizeActor = none;
		ActionMetadata.StateObject_NewState = WorldDataUpdate;
		ActionMetadata.StateObject_OldState = WorldDataUpdate;

		for (i = 0; i < AbilityTemplate.AbilityTargetEffects.Length; ++i)
		{
			AbilityTemplate.AbilityTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, AbilityContext.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[i]));
		}

			}

	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	for( i = 0; i < AbilityContext.InputContext.MultiTargets.Length; ++i )
	{
		InteractingUnitRef = AbilityContext.InputContext.MultiTargets[i];
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);
		for( j = 0; j < AbilityContext.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			AbilityContext.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, AbilityContext.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}

		TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}
	}

	// add visualization of environment damage
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', DamageEventStateObject)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = DamageEventStateObject;
		ActionMetadata.StateObject_NewState = DamageEventStateObject;
		ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer(DamageEventStateObject.ObjectID);
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);
		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);
			}
}

defaultproperties
{
	HEAVY_ALIEN_PANIC_TESTED="HeavyAlienPanicTested"
	MEDIUM_ALIEN_PANIC_TESTED="MediumAlienPanicTested"
	LIGHT_ALIEN_PANIC_TESTED="LightAlienPanicTested"
}
