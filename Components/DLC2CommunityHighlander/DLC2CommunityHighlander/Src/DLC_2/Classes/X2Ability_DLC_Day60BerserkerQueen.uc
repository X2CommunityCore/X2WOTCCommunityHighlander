class X2Ability_DLC_Day60BerserkerQueen extends X2Ability
	config(GameData_SoldierSkills);

var const config int QUAKE_AP_COST;
var const config int QUAKE_LOCAL_COOLDOWN;
var const config float QUAKE_DAMAGE_RADIUS_METERS;
var const config float QUAKE_KNOCKBACK_DISTANCE;
var const config int QUAKE_DISORIENTED_MAX_ALLOWED;
var const config int QUAKE_STUNNED_MAX_ALLOWED;
var const config int QUAKE_UNCONSCIOUS_MAX_ALLOWED;
var const config WeaponDamageValue QUAKE_DAMAGE;
var const config int FAITHBREAKER_COOLDOWN, FAITHBREAKER_INCREASE_PER_HP_LOST;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateQuakeAbility());
	Templates.AddItem(Faithbreaker());
	Templates.AddItem(CreateQueenDevastatingPunchAbility('QueenDevastatingPunch', 0));

	return Templates;
}

// Updated Devastating Punch ability to not consume all points.
static function X2AbilityTemplate CreateQueenDevastatingPunchAbility(optional Name AbilityName='DevastatingPunch', int MovementRangeAdjustment=1)
{
	local X2AbilityTemplate AbilityTemplate;
	local int				AbilityCostIndex;
	AbilityTemplate = class'X2Ability_Berserker'.static.CreateDevastatingPunchAbility(AbilityName, MovementRangeAdjustment);
	// Set to not end the turn.
	for( AbilityCostIndex = 0; AbilityCostIndex < AbilityTemplate.AbilityCosts.Length; ++AbilityCostIndex )
	{
		if( AbilityTemplate.AbilityCosts[AbilityCostIndex].IsA('X2AbilityCost_ActionPoints') )
		{
			X2AbilityCost_ActionPoints(AbilityTemplate.AbilityCosts[AbilityCostIndex]).bConsumeAllPoints = false;
		}
	}
	class'X2Ability_DLC_Day60AlienRulers'.static.RemoveMimicBeaconsFromTargets(AbilityTemplate);
	return AbilityTemplate;
}

static function X2AbilityTemplate CreateQuakeAbility()
{
	local X2AbilityTemplate						Template;	
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2AbilityMultiTarget_Radius			RadiusMultiTarget;
	local X2AbilityTrigger_PlayerInput			InputTrigger;
	local X2AbilityCooldown						Cooldown;
	local X2Effect_Knockback					KnockbackEffect;
	local X2Effect_ApplyWeaponDamage			DamageEffect;
	local X2AbilityToHitCalc_StatCheck_UnitVsUnit    StatContest;
	local X2Effect_Persistent					DisorientedEffect;
	local X2Effect_Stunned						StunnedEffect;
	local X2Effect_Persistent					UnconsciousEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Quake');
	Template.bDontDisplayInAbilitySummary = false;
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_beserker_quake";
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.QUAKE_AP_COST;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// This will be a stat contest
	StatContest = new class'X2AbilityToHitCalc_StatCheck_UnitVsUnit';
	StatContest.AttackerStat = eStat_Strength;
	Template.AbilityToHitCalc = StatContest;

	// On hit effects
	//  Stunned effect for 1 or 2 unblocked hit
	DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect(, , false);
	DisorientedEffect.MinStatContestResult = 1;
	DisorientedEffect.MaxStatContestResult = 2;
	DisorientedEffect.MultiTargetStatContestInfo.MaxNumberAllowed = default.QUAKE_DISORIENTED_MAX_ALLOWED;
	DisorientedEffect.bRemoveWhenSourceDies = false;
	Template.AddMultiTargetEffect(DisorientedEffect);

	//  Stunned effect for 3 or 4 unblocked hit
	StunnedEffect = class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 100, false);
	StunnedEffect.MinStatContestResult = 3;
	StunnedEffect.MaxStatContestResult = 4;
	StunnedEffect.MultiTargetStatContestInfo.MaxNumberAllowed = default.QUAKE_STUNNED_MAX_ALLOWED;  // Max number of stunned units allowed from this ability
	StunnedEffect.MultiTargetStatContestInfo.EffectIdxToApplyOnMaxExceeded = 0;    // After the max allowed, targets become disoriented
	StunnedEffect.bRemoveWhenSourceDies = false;
	Template.AddMultiTargetEffect(StunnedEffect);

	//  Unconscious effect for 5 unblocked hits
	UnconsciousEffect = class'X2StatusEffects'.static.CreateUnconsciousStatusEffect();
	UnconsciousEffect.MinStatContestResult = 5;
	UnconsciousEffect.MaxStatContestResult = 0;
	UnconsciousEffect.MultiTargetStatContestInfo.MaxNumberAllowed = default.QUAKE_UNCONSCIOUS_MAX_ALLOWED;  // Max number of the multitargets that may become unconscious
	UnconsciousEffect.MultiTargetStatContestInfo.EffectIdxToApplyOnMaxExceeded = 1;    // After the max allowed, targets become stunned
	UnconsciousEffect.bRemoveWhenSourceDies = false;
	Template.AddMultiTargetEffect(UnconsciousEffect);

	// damage effect
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.EffectDamageValue = default.QUAKE_DAMAGE;
	Template.AddMultiTargetEffect(DamageEffect);

	// knockback effect
	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = default.QUAKE_KNOCKBACK_DISTANCE;
	Template.AddMultiTargetEffect(KnockbackEffect);

	// Multi Targets
	Template.AbilityMultiTargetConditions.AddItem(default.LivingTargetUnitOnlyProperty);

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.fTargetRadius = default.QUAKE_DAMAGE_RADIUS_METERS;
	RadiusMultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_PathTarget';

	// shooter conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// trigger
	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_viper_frostbite";

	// Cooldown on the ability
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.QUAKE_LOCAL_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	Template.bSkipMoveStop = true;
	Template.CustomFireAnim = 'FF_Quake';
	Template.CustomMovingFireAnim = 'MV_Quake';
	Template.CustomMovingTurnLeftFireAnim = 'MV_RunTun90LeftQuake';
	Template.CustomMovingTurnRightFireAnim = 'MV_RunTun90RightQuake';

	// This action is considered 'hostile' and can be interrupted!
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "BerserkerQueen_Quake";

	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.HeavyWeaponLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'Quake'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'Quake'

	return Template;
}

static function X2AbilityTemplate Faithbreaker()
{
	local X2AbilityTemplate     Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown     Cooldown;
	local X2AbilityMultiTarget_AllUnits MultiTarget;
	local X2Effect_Panicked     PanicEffect;
	local X2Condition_UnitProperty UnitPropertyCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Faithbreaker');

	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_beserker_faithbreaker";
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.FAITHBREAKER_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = default.SelfTarget;
	MultiTarget = new class'X2AbilityMultiTarget_AllUnits';
	MultiTarget.bAcceptEnemyUnits = true;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AbilityMultiTargetConditions.AddItem(new class'X2Condition_Panic');

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeAlive=false;
	UnitPropertyCondition.ExcludeDead=true;
	UnitPropertyCondition.ExcludeFriendlyToSource=true;
	UnitPropertyCondition.ExcludeHostileToSource=false;
	UnitPropertyCondition.TreatMindControlledSquadmateAsHostile=false;
	UnitPropertyCondition.FailOnNonUnits=true;
	UnitPropertyCondition.ExcludeRobotic = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	PanicEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
	PanicEffect.ApplyChanceFn = FaithbreakerApplyChance;
	PanicEffect.VisualizationFn = FaithBreaker_PanickedVisualization;
	Template.AddMultiTargetEffect(PanicEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Berserker_Rage";
	Template.bShowPostActivation = true;

	Template.CustomFireAnim = 'NO_Faithbreaker';

	class'X2Ability_DLC_Day60AlienRulers'.static.RemoveMimicBeaconsFromTargets(Template);

//BEGIN AUTOGENERATED CODE: Template Overrides 'Faithbreaker'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'Faithbreaker'
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	return Template;
}

function name FaithbreakerApplyChance(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	//  this mimics the panic hit roll without actually BEING the panic hit roll
	local XComGameState_Unit TargetUnit;
	local name ImmuneName;
	local float MaxHealth, CurrentHealth, HealthLost;
	local int TargetRoll, RandRoll;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit != none)
	{
		foreach class'X2AbilityToHitCalc_PanicCheck'.default.PanicImmunityAbilities(ImmuneName)
		{
			if (TargetUnit.FindAbility(ImmuneName).ObjectID != 0)
			{
				return 'AA_UnitIsImmune';
			}
		}
		
		MaxHealth = TargetUnit.GetMaxStat(eStat_HP);
		CurrentHealth = TargetUnit.GetCurrentStat(eStat_HP);
		HealthLost = MaxHealth - CurrentHealth;

		TargetRoll = HealthLost * default.FAITHBREAKER_INCREASE_PER_HP_LOST;
		RandRoll = `SYNC_RAND(100);
		if (RandRoll < TargetRoll)
		{
			return 'AA_Success';
		}
	}

	return 'AA_EffectChanceFailed';
}

static function FaithBreaker_PanickedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
	{
		return;
	}

	if (!UnitState.IsCivilian() && EffectApplyResult != 'AA_Success')
	{
		class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), class'X2Effect_Panicked'.default.EffectFailedFriendlyName, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Panicked);
	}
}

DefaultProperties
{
}
