class X2Ability_HackRewards extends X2Ability config(GameData_SoldierSkills);

Enum EffectTargetSelection
{
	EETS_Self,					// Target only the Hack instigator
	EETS_Target,				// Target only the Hack target
	EETS_AllAllies,				// Target the allies of the instigator
	EETS_AllEnemies,			// Target the enemies of the instigator
	EETS_AllRoboticEnemies,		// Target all robotic enemies
	EETS_SingleEnemy,			// Target a single enemy
	EETS_SingleRoboticEnemy,	// Target a single robotic enemy
	EETS_AllADVENTEnemies,		// Target all ADVENT enemies
};

var localized string ControlRobotStatName;
var localized string ControlRobotStatDesc;
var localized string DamageImmunityName;
var localized string DamageImmunityDesc;

var config int CONTROL_ROBOT_DURATION, CONTROL_ROBOT_AIM_BONUS, CONTROL_ROBOT_CRIT_BONUS, CONTROL_ROBOT_MOBILITY_BONUS;
var config int CONTROL_TURRET_DURATION;
var config WeaponDamageValue SKULLOuch_DAMAGE;

var config float BuffEnemy_DefenseBonus;
var config float BuffEnemy_AimBonus;

var config int TargetingAimAndCrit_AimBonus;
var config int TargetingAimAndCrit_CritBonus;
var config int TargetingDodge_DodgeBonus;
var config int TargetingCrit_CritBonus;
var config float Hypnography_WillBonus;
var config float VideoFeed_SightBonus;
var config float Distortion_WillBonus;
var config int Blitz_Charges;
var config int Override_Charges;
var config float Jammed_DefenseBonus;
var config float Jammed_MobilityBonus;
var config float ReduceDetection_DetectionModifierBonus;
var config float IncreaseDetection_DetectionModifierBonus;
var config float AlloyPadding_ArmorBonus;
var config int AlloyPadding_ApplicationChance;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(BuildStatModifyingAbility('HackRewardBuffEnemy', "img:///UILibrary_PerkIcons.UIPerk_hack_reward", EETS_Target, , ePerkBuff_Bonus, eStat_Defense, default.BuffEnemy_DefenseBonus, , , eHit_Success, default.BuffEnemy_AimBonus));
	Templates.AddItem(HackRewardControlRobot());
	Templates.AddItem(HackRewardControlRobotWithStatBoost());
	Templates.AddItem(HackRewardShutdownRobot());
	Templates.AddItem(HackRewardShutdownTurret());
	Templates.AddItem(HackRewardControlTurret());
	Templates.AddItem(HackRewardControlTurretWithStatBoost());
	Templates.AddItem(SKULLOuch());

	// New Spec Hack Rewards
	Templates.AddItem(BuildStatModifyingAbility('TargetingAimAndCrit', "img:///UILibrary_PerkIcons.UIPerk_hack_reward", EETS_Self, , ePerkBuff_Bonus, , , , , eHit_Success, default.TargetingAimAndCrit_AimBonus, eHit_Crit, default.TargetingAimAndCrit_CritBonus));
	Templates.AddItem(BuildStatModifyingAbility('TargetingDodge', "img:///UILibrary_PerkIcons.UIPerk_hack_reward", EETS_Self, , ePerkBuff_Bonus, eStat_Dodge, default.TargetingDodge_DodgeBonus));
	Templates.AddItem(BuildStatModifyingAbility('TargetingCrit', "img:///UILibrary_PerkIcons.UIPerk_hack_reward", EETS_Self, , ePerkBuff_Bonus, , , , , eHit_Crit, default.TargetingCrit_CritBonus));

	Templates.AddItem(BuildStatModifyingAbility('Hypnography', "img:///UILibrary_PerkIcons.UIPerk_hack_reward_debuff", EETS_AllEnemies, , ePerkBuff_Penalty, eStat_Will, default.Hypnography_WillBonus));

	Templates.AddItem(HackRewardBlitz());

	Templates.AddItem(HackRewardIntegratedComms());

	Templates.AddItem(BuildStatModifyingAbility('VideoFeed', "img:///UILibrary_PerkIcons.UIPerk_hack_reward", EETS_Self, , ePerkBuff_Bonus, eStat_SightRadius, default.VideoFeed_SightBonus));

	Templates.AddItem(HackRewardDisguisedSignals());
	
	Templates.AddItem(HackRewardDistortionWill());
	Templates.AddItem(HackRewardDistortion());

	Templates.AddItem(BuildMindControlAbility('Deception', EETS_SingleEnemy));
	
	Templates.AddItem(BuildMindControlAbility('Intrusion', EETS_SingleRoboticEnemy));
	
	Templates.AddItem(BuildMindControlAbility('CentralCommand', EETS_AllRoboticEnemies));

	Templates.AddItem(BuildDisorientAbility('Disorient', EETS_AllEnemies));

	Templates.AddItem(BuildDamageImmunityAbility('Override', EETS_Self));


	Templates.AddItem(BuildStatModifyingAbility('Jammed', "img:///UILibrary_PerkIcons.UIPerk_hack_reward", EETS_AllEnemies, , ePerkBuff_Bonus, eStat_Defense, default.Jammed_DefenseBonus, eStat_Mobility, default.Jammed_MobilityBonus));

	Templates.AddItem(BuildStatModifyingAbility('AlloyPadding', "img:///UILibrary_PerkIcons.UIPerk_extrapadding", EETS_AllADVENTEnemies, default.AlloyPadding_ApplicationChance, ePerkBuff_Bonus, eStat_ArmorMitigation, default.AlloyPadding_ArmorBonus, eStat_ArmorChance, 100));

	Templates.AddItem(BuildStatModifyingAbility('ReduceDetection', "img:///UILibrary_PerkIcons.UIPerk_hack_reward", EETS_AllAllies, , ePerkBuff_Bonus, eStat_DetectionModifier, default.ReduceDetection_DetectionModifierBonus));
	Templates.AddItem(BuildStatModifyingAbility('IncreaseDetection', "img:///UILibrary_PerkIcons.UIPerk_hack_reward_debuff", EETS_AllAllies, , ePerkBuff_Penalty, eStat_DetectionModifier, default.IncreaseDetection_DetectionModifierBonus));

	return Templates;
}


static function X2AbilityTemplate HackRewardControlRobot()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    Listener;
	local X2Effect_MindControl              ControlEffect;
	local bool								bInfiniteDuration;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HackRewardControlRobot');

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.HackTriggerTargetListener;
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	bInfiniteDuration = default.CONTROL_ROBOT_DURATION <= 0;
	ControlEffect = class'X2StatusEffects'.static.CreateMindControlStatusEffect(default.CONTROL_ROBOT_DURATION, true, bInfiniteDuration);
	Template.AddTargetEffect(ControlEffect);

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateMindControlRemoveEffects());

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	return Template;
}

static function X2AbilityTemplate HackRewardControlRobotWithStatBoost()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    Listener;
	local X2Effect_MindControl              ControlEffect;
	local X2Effect_PersistentStatChange     StatEffect;
	local bool								bInfiniteDuration;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HackRewardControlRobotWithStatBoost');

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.HackTriggerTargetListener;
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	bInfiniteDuration = default.CONTROL_ROBOT_DURATION <= 0;

	ControlEffect = class'X2StatusEffects'.static.CreateMindControlStatusEffect(default.CONTROL_ROBOT_DURATION, true, bInfiniteDuration);
	Template.AddTargetEffect(ControlEffect);

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateMindControlRemoveEffects());

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(default.CONTROL_ROBOT_DURATION, bInfiniteDuration, false, false, eGameRule_PlayerTurnBegin);
	StatEffect.SetDisplayInfo(ePerkBuff_Bonus, default.ControlRobotStatName, default.ControlRobotStatDesc, Template.IconImage, true);
	StatEffect.AddPersistentStatChange(eStat_Offense, default.CONTROL_ROBOT_AIM_BONUS);
	StatEffect.AddPersistentStatChange(eStat_CritChance, default.CONTROL_ROBOT_CRIT_BONUS);
	StatEffect.AddPersistentStatChange(eStat_Mobility, default.CONTROL_ROBOT_MOBILITY_BONUS);
	Template.AddTargetEffect(StatEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	return Template;
}

static function X2AbilityTemplate HackRewardShutdownRobot()
{
	return HackRewardShutdownRobotOrTurret(false, 'HackRewardShutdownRobot');
}

static function X2AbilityTemplate HackRewardShutdownTurret()
{
	return HackRewardShutdownRobotOrTurret(true, 'HackRewardShutdownTurret');
}

static function X2AbilityTemplate HackRewardShutdownRobotOrTurret( bool bTurret, Name AbilityName )
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    Listener;
	local X2Effect_Stunned                  StunEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.HackTriggerTargetListener;
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	StunEffect = class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 100, false);
	StunEffect.SetDisplayInfo(ePerkBuff_Penalty, class'X2StatusEffects'.default.RoboticStunnedFriendlyName, class'X2StatusEffects'.default.RoboticStunnedFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_stun");
	if( bTurret )
	{
		StunEffect.CustomIdleOverrideAnim = ''; // Clearing this prevents the anim tree controller from being locked down.  
	}											// Then the idle anim state machine can properly update the stunned anims.
	Template.AddTargetEffect(StunEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	return Template;
}

static function X2AbilityTemplate HackRewardControlTurret()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    Listener;
	local X2Effect_MindControl              ControlEffect;
	local bool								bInfiniteDuration;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HackRewardControlTurret');

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.HackTriggerTargetListener;
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	bInfiniteDuration = default.CONTROL_TURRET_DURATION <= 0;
	ControlEffect = class'X2StatusEffects'.static.CreateMindControlStatusEffect(default.CONTROL_TURRET_DURATION, true, bInfiniteDuration);
	Template.AddTargetEffect(ControlEffect);

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateMindControlRemoveEffects());

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	return Template;
}

static function X2AbilityTemplate HackRewardControlTurretWithStatBoost()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    Listener;
	local X2Effect_MindControl              ControlEffect;
	local X2Effect_PersistentStatChange     StatEffect;
	local bool								bInfiniteDuration;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HackRewardControlTurretWithStatBoost');

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.HackTriggerTargetListener;
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	bInfiniteDuration = default.CONTROL_TURRET_DURATION <= 0;

	ControlEffect = class'X2StatusEffects'.static.CreateMindControlStatusEffect(default.CONTROL_TURRET_DURATION, true, bInfiniteDuration);
	Template.AddTargetEffect(ControlEffect);

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateMindControlRemoveEffects());

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(default.CONTROL_TURRET_DURATION, bInfiniteDuration, false, false, eGameRule_PlayerTurnBegin);
	StatEffect.SetDisplayInfo(ePerkBuff_Bonus, default.ControlRobotStatName, default.ControlRobotStatDesc, Template.IconImage, true);
	StatEffect.AddPersistentStatChange(eStat_Offense, default.CONTROL_ROBOT_AIM_BONUS);
	StatEffect.AddPersistentStatChange(eStat_CritChance, default.CONTROL_ROBOT_CRIT_BONUS);
	Template.AddTargetEffect(StatEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	return Template;
}

static function X2AbilityTemplate SKULLOuch()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    Listener;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SKULLOuch');

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	Template.AbilityTargetStyle = default.SelfTarget;
	//Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.EffectDamageValue = class'X2Ability_HackRewards'.default.SKULLOuch_DAMAGE;
	Template.AddTargetEffect(WeaponDamageEffect);
	//Template.AddMultiTargetEffect(AimEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	return Template;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// New Spec Hack Rewards
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Abilities which self target to affect modifications in Hit/Crit/Dodge/etc. chance
static function X2AbilityTemplate BuildStatModifyingAbility(
	Name TemplateName, 
	string TemplateIcon, 
	EffectTargetSelection TargetType, 
	optional int TargetApplicationChance, 
	optional EPerkBuffCategory BuffType, 
	optional ECharStatType StatModTypeA, 
	optional float StatModValueA, 
	optional ECharStatType StatModTypeB, 
	optional float StatModValueB, 
	optional EAbilityHitResult HitModTypeA, 
	optional int HitModValueA, 
	optional EAbilityHitResult HitModTypeB, 
	optional int HitModValueB)
{
	local X2AbilityTemplate                 Template;
	local array<X2Effect>					SelectedEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.IconImage = TemplateIcon;

	AddStatModifyingEffectsToTemplate(
		Template, 
		SelectedEffects, 
		BuffType, 
		StatModTypeA, 
		StatModValueA, 
		StatModTypeB, 
		StatModValueB, 
		HitModTypeA, 
		HitModValueA, 
		HitModTypeB, 
		HitModValueB);
	ApplyEffectsToTemplate(Template, TargetType, TargetApplicationChance, SelectedEffects);

	return Template;
}

static function AddStatModifyingEffectsToTemplate(
	X2AbilityTemplate Template, 
	out array<X2Effect> SelectedEffects, 
	optional EPerkBuffCategory BuffType, 
	optional ECharStatType StatModTypeA, 
	optional float StatModValueA, 
	optional ECharStatType StatModTypeB, 
	optional float StatModValueB, 
	optional EAbilityHitResult HitModTypeA, 
	optional int HitModValueA, 
	optional EAbilityHitResult HitModTypeB, 
	optional int HitModValueB)
{
	local X2Effect_ToHitModifier            AimEffect;
	local X2Effect_PersistentStatChange     StatChangeEffect;

	if( StatModValueA != 0.0 )
	{
		StatChangeEffect = new class'X2Effect_PersistentStatChange';
		StatChangeEffect.BuildPersistentEffect(1, true, false, , eGameRule_PlayerTurnBegin); // the duration will come from the hack reward's TurnsUntilExpiration
		StatChangeEffect.SetDisplayInfo(BuffType, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage);
		StatChangeEffect.AddPersistentStatChange(StatModTypeA, StatModValueA);
		if( StatModValueB != 0.0 )
		{
			StatChangeEffect.AddPersistentStatChange(StatModTypeB, StatModValueB);
		}
		StatChangeEffect.DuplicateResponse = eDupe_Ignore;
		StatChangeEffect.VisualizationFn = StatModVisualizationApplied;
		StatChangeEffect.EffectRemovedVisualizationFn = StatModVisualizationRemoved;

		SelectedEffects.AddItem(StatChangeEffect);
	}

	if( HitModValueA != 0 )
	{
		AimEffect = new class'X2Effect_ToHitModifier';
		AimEffect.BuildPersistentEffect(1, true, false, , eGameRule_PlayerTurnBegin); // the duration will come from the hack reward's TurnsUntilExpiration
		AimEffect.SetDisplayInfo(BuffType, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage);
		AimEffect.AddEffectHitModifier(HitModTypeA, HitModValueA, Template.LocFriendlyName);
		if( HitModValueB != 0 )
		{
			AimEffect.AddEffectHitModifier(HitModTypeB, HitModValueB, Template.LocFriendlyName);
		}
		AimEffect.DuplicateResponse = eDupe_Ignore;
		AimEffect.VisualizationFn = StatModVisualizationApplied;
		AimEffect.EffectRemovedVisualizationFn = StatModVisualizationRemoved;

		SelectedEffects.AddItem(AimEffect);
	}
}

static function ApplyEffectsToTemplate(X2AbilityTemplate Template, EffectTargetSelection TargetType, int TargetApplicationChance, const out array<X2Effect> SelectedEffects)
{
	local X2AbilityTrigger_EventListener    Listener;
	local X2AbilityMultiTarget_AllUnits		MultiTargetStyle;
	local int								EffectIndex;

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	if( TargetType == EETS_Target )
	{
		Template.AbilityTargetStyle = default.SimpleSingleTarget;
		Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.HackTriggerTargetListener;
	}
	else
	{
		Template.AbilityTargetStyle = default.SelfTarget;
		Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	}
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	if( TargetType == EETS_Self || TargetType == EETS_Target )
	{
		for( EffectIndex = 0; EffectIndex < SelectedEffects.Length; ++EffectIndex )
		{
			Template.AddTargetEffect(SelectedEffects[EffectIndex]);
		}
	}
	else
	{
		for( EffectIndex = 0; EffectIndex < SelectedEffects.Length; ++EffectIndex )
		{
			Template.AddMultiTargetEffect(SelectedEffects[EffectIndex]);
		}

		MultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';
		MultiTargetStyle.RandomChance = TargetApplicationChance;
		if( TargetType == EETS_AllAllies )
		{
			MultiTargetStyle.bAllowSameTarget = true;
			MultiTargetStyle.bAcceptFriendlyUnits = true;
		}
		else if( TargetType == EETS_AllEnemies )
		{
			MultiTargetStyle.bAcceptEnemyUnits = true;
		}
		else if( TargetType == EETS_AllRoboticEnemies )
		{
			MultiTargetStyle.bAcceptEnemyUnits = true;
			MultiTargetStyle.bOnlyAcceptRoboticUnits = true;
		}
		else if( TargetType == EETS_AllADVENTEnemies )
		{
			MultiTargetStyle.bAcceptEnemyUnits = true;
			MultiTargetStyle.bOnlyAcceptAdventUnits = true;
		}
		else if( TargetType == EETS_SingleEnemy )
		{
			MultiTargetStyle.bAcceptEnemyUnits = true;
			MultiTargetStyle.bRandomlySelectOne = true;
		}
		else if( TargetType == EETS_SingleRoboticEnemy )
		{
			MultiTargetStyle.bAcceptEnemyUnits = true;
			MultiTargetStyle.bOnlyAcceptRoboticUnits = true;
			MultiTargetStyle.bRandomlySelectOne = true;
		}
		Template.AbilityMultiTargetStyle = MultiTargetStyle;
	}

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = false;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
}

static function StatModVisualizationApplied(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

static function StatModVisualizationRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}



static function X2AbilityTemplate HackRewardBlitz()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCharges                  Charges;
	local X2AbilityCost_Charges             ChargesCost;

	Template = class'X2Ability_RangerAbilitySet'.static.RunAndGunAbility('Blitz');

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.Blitz_Charges;
	Template.AbilityCharges = Charges;

	ChargesCost = new class'X2AbilityCost_Charges';
	ChargesCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargesCost);

	return Template;
}


static function X2AbilityTemplate HackRewardIntegratedComms()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTrigger_EventListener		Listener;
	local X2Effect_Squadsight                   Squadsight;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IntegratedComms');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_squadsight";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Template.AbilityTargetStyle = default.SelfTarget;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	Squadsight = new class'X2Effect_Squadsight';
	Squadsight.BuildPersistentEffect(1, true, , , eGameRule_PlayerTurnBegin); // the duration will come from the hack reward's TurnsUntilExpiration
	Squadsight.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	Squadsight.VisualizationFn = StatModVisualizationApplied;
	Squadsight.EffectRemovedVisualizationFn = StatModVisualizationRemoved;
	Template.AddTargetEffect(Squadsight);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.bCrossClassEligible = true;

	return Template;
}

static function X2AbilityTemplate HackRewardDisguisedSignals()
{
	local X2AbilityTemplate						Template;
	local X2Effect_RangerStealth                StealthEffect;
	local X2AbilityCharges                      Charges;
	local X2AbilityTrigger_EventListener		Listener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DisguisedSignals');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_stealth";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Charges');

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Template.AbilityTargetStyle = default.SelfTarget;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Listener.ListenerData.EventID = class'X2HackRewardTemplateManager'.default.HackAbilityEventName;
	Listener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(Listener);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = 1;
	Template.AbilityCharges = Charges;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	StealthEffect = new class'X2Effect_RangerStealth';
	StealthEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	StealthEffect.bRemoveWhenTargetConcealmentBroken = true;
	Template.AddTargetEffect(StealthEffect);

	Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	Template.ActivationSpeech = 'ActivateConcealment';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;

	return Template;
}


static function X2DataTemplate HackRewardDistortion()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitProperty          Condition;

	Template = class'X2Ability_DefaultAbilitySet'.static.AddPanicAbility('Distortion');

	Condition = new class'X2Condition_UnitProperty';
	Condition.IsAdvent = true;
	Template.AbilityShooterConditions.AddItem(Condition);

	Template.AdditionalAbilities.AddItem('DistortionWill');

	return Template;
}

static function X2DataTemplate HackRewardDistortionWill()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitProperty          Condition;

	Template = BuildStatModifyingAbility('DistortionWill', "img:///UILibrary_PerkIcons.UIPerk_hack_reward", EETS_Self, , ePerkBuff_Bonus, eStat_Will, default.Distortion_WillBonus);

	Condition = new class'X2Condition_UnitProperty';
	Condition.IsAdvent = true;
	Template.AbilityShooterConditions.AddItem(Condition);

	return Template;
}



static function X2AbilityTemplate BuildMindControlAbility(Name TemplateName, EffectTargetSelection TargetType)
{
	local X2AbilityTemplate                 Template;
	local array<X2Effect>					SelectedEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	SelectedEffects.AddItem(class'X2StatusEffects'.static.CreateMindControlStatusEffect(1));
	SelectedEffects.AddItem(class'X2StatusEffects'.static.CreateMindControlRemoveEffects());

	ApplyEffectsToTemplate(Template, TargetType, 0, SelectedEffects);

	return Template;
}

static function X2AbilityTemplate BuildDisorientAbility(Name TemplateName, EffectTargetSelection TargetType)
{
	local X2AbilityTemplate                 Template;
	local array<X2Effect>					SelectedEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	SelectedEffects.AddItem(class'X2StatusEffects'.static.CreateDisorientedStatusEffect(, , false));

	ApplyEffectsToTemplate(Template, TargetType, 0, SelectedEffects);

	return Template;
}

static function X2AbilityTemplate BuildDamageImmunityAbility(Name TemplateName, EffectTargetSelection TargetType)
{
	local X2AbilityTemplate                 Template;
	local array<X2Effect>					SelectedEffects;
	local X2Effect_DamageImmunity			DamageImmunityEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	DamageImmunityEffect = new class'X2Effect_DamageImmunity';
	DamageImmunityEffect.DuplicateResponse = eDupe_Refresh;
	DamageImmunityEffect.BuildPersistentEffect(1, true, true, , eGameRule_PlayerTurnBegin);
	DamageImmunityEffect.SetDisplayInfo(ePerkBuff_Bonus, default.DamageImmunityName, default.DamageImmunityDesc, "img:///UILibrary_PerkIcons.UIPerk_immunities");
	DamageImmunityEffect.VisualizationFn = StatModVisualizationApplied;
	DamageImmunityEffect.EffectRemovedVisualizationFn = StatModVisualizationRemoved;
	DamageImmunityEffect.bRemoveWhenTargetDies = true;
	DamageImmunityEffect.RemoveAfterAttackCount = default.Override_Charges;
	DamageImmunityEffect.ImmueTypesAreInclusive = false; // all types of damage prevented

	SelectedEffects.AddItem(DamageImmunityEffect);

	ApplyEffectsToTemplate(Template, TargetType, 0, SelectedEffects);

	return Template;
}
