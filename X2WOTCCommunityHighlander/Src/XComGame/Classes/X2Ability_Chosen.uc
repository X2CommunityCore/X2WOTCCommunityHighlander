//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_Chosen extends X2Ability
	config(GameData_SoldierSkills);

var localized string HoloTargetEffectName;
var localized string HoloTargetEffectDesc;

var localized string KidnapHeader;
var localized string KidnapTargetHeader;
var localized string KidnapMessageBody;
var localized string ExtractHeader;
var localized string ExtractTargetHeader;
var localized string ExtractMessageBody;
var localized string DefeatedHeader;
var localized string DefeatedTargetHeader;
var localized string DefeatedMessageBody;

var config float SOULSTEALER_HP_MOD;
var config int AGILE_CHANCE;
var config int ACHILLES_TO_HIT;
var config float ACHILLES_DMG_MOD;
var config int HOLOTARGET_BONUS;
var config int BRUTAL_WILL_MOD;
var config float NEARSIGHTED_DMG_MOD;
var config float BEWILDERED_DMG_MOD;
var config int BEWILDERED_NUM_HITS;
var config int KINETIC_PLATING_MAX;
var config int KINETIC_PLATING_PER_MISS;
var config float ADVERSARY_REAPER_DMG_MOD;
var config float ADVERSARY_SKIRMISHER_DMG_MOD;
var config float ADVERSARY_TEMPLAR_DMG_MOD;
var config float IMPATIENT_DMG_MOD;
var config int GROUNDLING_MOD;
var config float OBLIVIOUS_DMG_MOD;
var config int KIDNAP_DISTANCE_UNITS;
var config float EASYTARGET_DEFENSE_MOD;
var config float BRITTLE_BONUS_MOD;
var config int BRITTLE_WITHIN_DISTANCE;
var config int SLOW_ACTIVATION_THRESHOLD_CHANGE;
var config int REVENGE_CHANCE_PERCENT;
var config float LOWPROFILE_DEFENSE_INCREASE_AMOUNT;
var config float CORNERED_PERCENT_HEALTH_ACTIVATION;
var config float CORNERED_ACTIVATION_THRESHOLD_CHANGE;
var config array<name> ZONEOFCONTROL_REACT_TO_ABILITIES;
var config int ZONEOFCONTROL_CHOSEN_ACTIVATION_INCREASE_PER_USE;
var config int CHOSEN_WARNING_MARK_UP_TILE_DISTANCE;
var config array<name> CHOSEN_WEAK_EXPLOSION_DMG_TYPES;
var config float CHOSEN_WEAK_EXPLOSION_DMG_MULTIPLIER;
var config array<name> CHOSEN_WEAK_PSI_DMG_TYPES;
var config float CHOSEN_WEAK_PSI_DMG_MULTIPLIER;
var config array<name> CHOSEN_WEAK_FIRE_DMG_TYPES;
var config float CHOSEN_WEAK_FIRE_DMG_MULTIPLIER;
var config array<name> CHOSEN_WEAK_POISON_DMG_TYPES;
var config float CHOSEN_WEAK_POISON_DMG_MULTIPLIER;
var config array<name> CHOSEN_WEAK_ACID_DMG_TYPES;
var config float CHOSEN_WEAK_ACID_DMG_MULTIPLIER;
var config array<name> CHOSEN_WEAK_MELEE_DMG_TYPES;
var config float CHOSEN_WEAK_MELEE_DMG_MULTIPLIER;
var config array<name> CHOSEN_IMMUNE_PSI_DMG_TYPES;
var config array<name> CHOSEN_IMMUNE_EXPLOSION_DMG_TYPES;
var config array<name> CHOSEN_IMMUNE_MELEE_DMG_TYPES;
var config array<name> CHOSEN_IMMUNE_ENVIRONMENTAL_DMG_TYPES;
var config int CHOSEN_REGENERATION_HEAL_VALUE;
var config int WATCHFUL_ACTIVATION_CHANCE;
var config array<StatChange> CHOSEN_INCREASE_STAT_DODGE_CHANGES;
var config array<StatChange> CHOSEN_INCREASE_STAT_CRIT_CHANGES;
var config array<StatChange> CHOSEN_INCREASE_STAT_HP_CHANGES;
var config array<StatChange> CHOSEN_INCREASE_MOBILITY_CHANGES;
var config array<StatChange> CHOSEN_INCREASE_ARMOR_CHANGES;
// Configurable X% chance to choose 'ChosenKidnapMove' ability over 'ChosenExtractKnowledgeMove' ability.
var config int ChanceToUseCapture;
var config float EngagedRevealCameraDuration;
var config float CompleteSequenceCameraDuration;

var config array<name> BeastmasterEncounterGroupsPerChosenLevel;
var config array<name> ShogunEncounterGroupsPerChosenLevel;
var config array<name> GeneralEncounterGroupsPerChosenLevel;
var config array<name> MechlordEncounterGroupsPerChosenLevel;
var config array<name> PrelateEncounterGroupsPerChosenLevel;

var private name KidnapMarkSourceEffectName, KidnapMarkTargetEffectName, ExtractKnowledgeMarkSourceEffectName, ExtractKnowledgeMarkTargetEffectName;
var privatewrite name SoulstealUnitValue;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateChosenInit());
	Templates.AddItem(CreateChosenKidnapMove());
	Templates.AddItem(CreateChosenKidnap());
	Templates.AddItem(CreateChosenExtractKnowledgeMove());
	Templates.AddItem(CreateChosenExtractKnowledge());
	Templates.AddItem(CreateChosenWarningMarkUp());
	Templates.AddItem(CreateKeen());

	Templates.AddItem(CreateChosenActivation());
	Templates.AddItem(CreateChosenReveal());
	Templates.AddItem(CreateChosenEngaged());
	Templates.AddItem(CreateChosenDirectedAttack());
	Templates.AddItem(CreateChosenSummonFollowers());
	Templates.AddItem(CreateChosenDefeatedSustain());
	Templates.AddItem(CreateChosenDefeatedEscape());

	Templates.AddItem(CreateChosenDamagedTeleportAtHalfHealthAbility());

	// Strengths
	// Lightning Reflexes
	Templates.AddItem(ChosenShadowstep());
	Templates.AddItem(CreateChosenRevenge());	// ReturnFire
	Templates.AddItem(CreateChosenLowProfile());
	Templates.AddItem(CreateChosenLowProfileTrigger());
	//Templates.AddItem(CreateChosenCornered());
	Templates.AddItem(CreateChosenAllSeeing());
	//Templates.AddItem(CreateChosenZoneOfControl());
	Templates.AddItem(CreateImmunityAbility('ChosenImmunePsi', "UILibrary_XPACK_Common.PerkIcons.str_immunetopsionics", default.CHOSEN_IMMUNE_PSI_DMG_TYPES));
	Templates.AddItem(BlastShield());
	Templates.AddItem(CreateMeleeImmunity());
	Templates.AddItem(CreateImmunityAbility('ChosenImmuneEnvironmental', "img:///UILibrary_XPACK_Common.PerkIcons.str_immunetoenvironmental", default.CHOSEN_IMMUNE_ENVIRONMENTAL_DMG_TYPES));
	Templates.AddItem(CreateChosenRegenerate());
	Templates.AddItem(CreateChosenModifyStat('ChosenIncreaseDodge', "img:///UILibrary_XPACK_Common.PerkIcons.str_highdodge", ePerkBuff_Bonus, default.CHOSEN_INCREASE_STAT_DODGE_CHANGES, 'StatBoost'));
	Templates.AddItem(CreateChosenModifyStat('ChosenIncreaseCrit', "img:///UILibrary_XPACK_Common.PerkIcons.str_highcrit", ePerkBuff_Bonus, default.CHOSEN_INCREASE_STAT_CRIT_CHANGES, 'StatBoost'));
	Templates.AddItem(CreateChosenModifyStat('ChosenIncreaseHP', "img:///UILibrary_XPACK_Common.PerkIcons.str_highhealth", ePerkBuff_Bonus, default.CHOSEN_INCREASE_STAT_HP_CHANGES, 'StatBoost'));
	Templates.AddItem(CreateChosenModifyStat('ChosenIncreaseMobility', "img:///UILibrary_XPACK_Common.PerkIcons.str_highmobility", ePerkBuff_Bonus, default.CHOSEN_INCREASE_MOBILITY_CHANGES, 'StatBoost'));
	Templates.AddItem(CreateChosenModifyStat('ChosenIncreaseArmor', "img:///UILibrary_XPACK_Common.PerkIcons.str_higharmor", ePerkBuff_Bonus, default.CHOSEN_INCREASE_ARMOR_CHANGES, 'StatBoost'));
	Templates.AddItem(CreateBeastmasterAbility());
	Templates.AddItem(CreatePrelateAbility());
	Templates.AddItem(CreateMechlordAbility());
	Templates.AddItem(CreateGeneralAbility());
	Templates.AddItem(CreateShogunAbility());
	Templates.AddItem(CreateChosenDamagedTeleportAbility());
	Templates.AddItem(ChosenWatchful());
	Templates.AddItem(ChosenKineticPlating());
	Templates.AddItem(ChosenBrutal());
	Templates.AddItem(ChosenHoloTargeting());
	Templates.AddItem(ChosenAgile());
	Templates.AddItem(ChosenSoulstealer());

	// Weaknesses
	Templates.AddItem(ChosenAchilles());
	Templates.AddItem(ChosenNearsighted());
	Templates.AddItem(ChosenBewildered());
	Templates.AddItem(ChosenReaperAdversary());
	Templates.AddItem(ChosenTemplarAdversary());
	Templates.AddItem(ChosenSkirmisherAdversary());
	Templates.AddItem(ChosenImpatient());
	Templates.AddItem(ChosenOblivious());
	Templates.AddItem(ChosenGroundling());
	Templates.AddItem(CreateChosenBrittle());
	//Templates.AddItem(CreateChosenSlow());
	Templates.AddItem(CreateWeakExplosionAbility('ChosenWeakExplosion', "img:///UILibrary_XPACK_Common.PerkIcons.weak_weaktoexplosives", default.CHOSEN_WEAK_EXPLOSION_DMG_TYPES, default.CHOSEN_WEAK_EXPLOSION_DMG_MULTIPLIER));
	Templates.AddItem(CreateWeakAbility('ChosenWeakPsi', "img:///UILibrary_XPACK_Common.PerkIcons.weak_weaktopsionics", default.CHOSEN_WEAK_PSI_DMG_TYPES, default.CHOSEN_WEAK_PSI_DMG_MULTIPLIER));
	Templates.AddItem(CreateWeakAbility('ChosenWeakFire', "img:///UILibrary_XPACK_Common.PerkIcons.weak_weaktofire", default.CHOSEN_WEAK_FIRE_DMG_TYPES, default.CHOSEN_WEAK_EXPLOSION_DMG_MULTIPLIER));
	Templates.AddItem(CreateWeakAbility('ChosenWeakPoison', "img:///UILibrary_XPACK_Common.PerkIcons.weak_weaktopoison", default.CHOSEN_WEAK_POISON_DMG_TYPES, default.CHOSEN_WEAK_EXPLOSION_DMG_MULTIPLIER));
	Templates.AddItem(CreateWeakAbility('ChosenWeakAcid', "img:///UILibrary_XPACK_Common.PerkIcons.weak_weaktoacid", default.CHOSEN_WEAK_ACID_DMG_TYPES, default.CHOSEN_WEAK_EXPLOSION_DMG_MULTIPLIER));
	Templates.AddItem(CreateWeakAbility('ChosenWeakMelee', "img:///UILibrary_XPACK_Common.PerkIcons.weak_weaktomelee", default.CHOSEN_WEAK_MELEE_DMG_TYPES, default.CHOSEN_WEAK_MELEE_DMG_MULTIPLIER));
	
	return Templates;
}

static function X2AbilityTemplate CreateChosenInit()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_UnitPostBeginPlay Trigger;
	local X2Effect_DamageImmunity DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenImmunities');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_mechanicalchassis";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	// Build the immunities
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, false, true);
	DamageImmunity.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	DamageImmunity.ImmuneTypes.AddItem('Panic');
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.DisorientDamageType);
	DamageImmunity.ImmuneTypes.AddItem('stun');
	DamageImmunity.ImmuneTypes.AddItem('Unconscious');
	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2DataTemplate CreateChosenDirectedAttack()
{
	local X2AbilityTemplate Template;
	local X2Condition_UnitValue EngagedValueSet;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenDirectedAttack');
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	EngagedValueSet = new class'X2Condition_UnitValue';
	EngagedValueSet.AddCheckValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ENGAGED);
	Template.AbilityShooterConditions.AddItem(EngagedValueSet);


	Template.bSkipPerkActivationActions = true;
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = ChosenDirectedAttack_BuildVisualization;
	Template.MergeVisualizationFn = ChosenDirectedAttact_MergeVisualization;

	return Template;
}

simulated function ChosenDirectedAttack_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_CameraLookAt LookAtAction;
	local X2Action_BeginTurnSignals SignalAction;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID);

	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	LookAtAction.LookAtObject = ActionMetadata.StateObject_NewState;
	LookAtAction.UseTether = false;
	LookAtAction.BlockUntilActorOnScreen = true;

	SignalAction = X2Action_BeginTurnSignals(class'X2Action_BeginTurnSignals'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,, LookAtAction));
	SignalAction.Target = XGUnit(History.GetVisualizer(AbilityContext.InputContext.PrimaryTarget.ObjectID));
}

simulated function ChosenDirectedAttact_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr LocalVisualizationMgr;
	local array<X2Action> Nodes;
	local X2Action MarkerAction, BuildTreeEndNode, SignalAction;
	local XComGameStateContext_Ability AbilityContext;

	LocalVisualizationMgr = `XCOMVISUALIZATIONMGR;
		
	BuildTreeEndNode = LocalVisualizationMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd');
	SignalAction = LocalVisualizationMgr.GetNodeOfType(BuildTree, class'X2Action_BeginTurnSignals');
	AbilityContext = XComGameStateContext_Ability(SignalAction.StateChangeContext);
	
	LocalVisualizationMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerTreeInsertBegin', Nodes,, AbilityContext.InputContext.MultiTargets[0].ObjectID, true);
	if( Nodes.Length > 0 )
	{
		MarkerAction = Nodes[0];
	}
	Nodes.Length = 0;

	// disconnect the tree being interrupted
	LocalVisualizationMgr.DisconnectAction(MarkerAction);

	if( VisualizationTree == MarkerAction )
	{
		VisualizationTree = None;
	}

	// gather all leaf nodes remaining in the tree
	LocalVisualizationMgr.GetAllLeafNodes(VisualizationTree, Nodes);

	// parent the interjecting sequence to all existing leaf nodes
	LocalVisualizationMgr.ConnectAction(BuildTree, VisualizationTree, false, , Nodes);

	// re-add the interrupted sequence to the tail of the interjected sequence
	LocalVisualizationMgr.ConnectAction(MarkerAction, VisualizationTree, false, BuildTreeEndNode);
}

static function SetChosenKidnapExtractBaseConditions(out X2AbilityTemplate Template, int iRange=-1)
{
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_UnitType ExcludeVolunteerArmyCondition;
	local X2Condition_UnitEffects ExcludeEffects;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// The Target must be alive and a humanoid
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeAlien = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.FailOnNonUnits = true;
	UnitPropertyCondition.RequireUnitSelectedFromHQ = true;
	UnitPropertyCondition.ExcludeAdvent = true;
	if (iRange > 0)
	{
		UnitPropertyCondition.RequireWithinRange = true;
		UnitPropertyCondition.WithinRange = iRange;
	}
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	ExcludeVolunteerArmyCondition = new class'X2Condition_UnitType';
	ExcludeVolunteerArmyCondition.ExcludeTypes.AddItem('CivilianMilitia');
	Template.AbilityTargetConditions.AddItem(ExcludeVolunteerArmyCondition);

	// Cannot target units being carried.
	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_UnitIsImmune');
	ExcludeEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName, 'AA_UnitIsImmune');
	ExcludeEffects.AddRequireEffect(class'X2AbilityTemplateManager'.default.DazedName, 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);
}

static function X2DataTemplate CreateChosenKidnapMove()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent MarkForKidnapEffect;
	local X2AbilityCost_ActionPoints ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenKidnapMove');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_kidnap";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = new class'X2AbilityTarget_MovingMelee';
	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_EndOfMove');

	Template.AdditionalAbilities.AddItem('ChosenKidnap');

	MarkForKidnapEffect = new class'X2Effect_Persistent';
	MarkForKidnapEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	MarkForKidnapEffect.DuplicateResponse = eDupe_Allow;
	MarkForKidnapEffect.EffectName = default.KidnapMarkSourceEffectName;
	Template.AddShooterEffect(MarkForKidnapEffect);

	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);

	SetChosenKidnapExtractBaseConditions(Template);

	MarkForKidnapEffect = new class'X2Effect_Persistent';
	MarkForKidnapEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	MarkForKidnapEffect.DuplicateResponse = eDupe_Allow;
	MarkForKidnapEffect.EffectName = default.KidnapMarkTargetEffectName;
	Template.AddTargetEffect(MarkForKidnapEffect);

	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildVisualizationFn = ChosenMoveToEscape_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;

	Template.bSkipFireAction = true;
	Template.bShowActivation = false;

//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenKidnapMove'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CinescriptCameraType = "";
//END AUTOGENERATED CODE: Template Overrides 'ChosenKidnapMove'

	Template.PostActivationEvents.AddItem('ChosenKidnapTrigger');

	return Template;
}

simulated function ChosenMoveToEscape_BuildVisualization(XComGameState VisualizeGameState)
{
	// Trigger the Chosen's kidnap or extract preparation line
	class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'ChosenMoveToEscape');

	TypicalAbility_BuildVisualization(VisualizeGameState);
}

static function X2DataTemplate CreateChosenKidnap()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent KidnapEffect;
	local X2Condition_UnitEffectsWithAbilitySource UnitEffectsCondition;
	local X2Effect_SetUnitValue SetUnitValue;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Condition_UnitEffects MultiTargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenKidnap');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_kidnap";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenKidnap'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.CustomFireAnim = 'HL_Kidnap';
//END AUTOGENERATED CODE: Template Overrides 'ChosenKidnap'

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChosenKidnapListener;
	EventListener.ListenerData.EventID = 'ChosenKidnapTrigger';
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	SetChosenKidnapExtractBaseConditions(Template, default.KIDNAP_DISTANCE_UNITS);

	// Source must be targeting
	UnitEffectsCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	UnitEffectsCondition.AddRequireEffect(default.KidnapMarkSourceEffectName, 'AA_MissingRequiredEffect');
	Template.AbilityShooterConditions.AddItem(UnitEffectsCondition);

	KidnapEffect = new class'X2Effect_Persistent';
	KidnapEffect.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
	KidnapEffect.bPersistThroughTacticalGameEnd = true;
	KidnapEffect.DuplicateResponse = eDupe_Allow;
	KidnapEffect.EffectName = 'ChosenKidnap';
	KidnapEffect.EffectAddedFn = ChosenKidnap_AddedFn;
	Template.AddShooterEffect(KidnapEffect);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue;
	SetUnitValue.NewValueToSet = class'XComGameState_AdventChosen'.const.CHOSEN_STATE_DISABLED;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValue);

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = true;
	Template.AddShooterEffect(MissionTimerEffect);

	// Target must be targeted
	UnitEffectsCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	UnitEffectsCondition.AddRequireEffect(default.KidnapMarkTargetEffectName, 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	KidnapEffect = new class'X2Effect_Persistent';
	KidnapEffect.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
	KidnapEffect.bPersistThroughTacticalGameEnd = true;
	KidnapEffect.DuplicateResponse = eDupe_Allow;
	KidnapEffect.EffectName = 'ChosenKidnapTarget';
	KidnapEffect.EffectAddedFn = ChosenKidnapTarget_AddedFn;
	Template.AddTargetEffect(KidnapEffect);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DazedName);
	Template.AddTargetEffect(RemoveEffects);

	// Multi Targets - Remove all Daze status effects
	MultiTargetCondition = new class'X2Condition_UnitEffects';
	MultiTargetCondition.AddRequireEffect(class'X2AbilityTemplateManager'.default.DazedName, 'AA_MissingRequiredEffect');
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetCondition);
	
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DazedName);
	RemoveEffects.bCleanse = true;
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = ChosenKidnap_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	Template.CinescriptCameraType = "Chosen_Kidnap";

	Template.PostActivationEvents.AddItem('ChosenKidnap');
	
	return Template;
}

static function ChosenKidnap_AddedFn(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit ChosenUnitState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	ChosenUnitState = XComGameState_Unit(kNewTargetState);
	EventManager.TriggerEvent('UnitRemovedFromPlay', ChosenUnitState, ChosenUnitState, NewGameState);

	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien', true));
	if( AlienHQ != none )
	{
		ChosenState = AlienHQ.GetChosenOfTemplate(ChosenUnitState.GetMyTemplateGroupName());
		ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ChosenState.ObjectID));
		ChosenState.CaptureSoldier(NewGameState, ApplyEffectParameters.AbilityInputContext.PrimaryTarget);
	}
}

static function ChosenKidnapTarget_AddedFn(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit KidnappedUnitState;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	KidnappedUnitState = XComGameState_Unit(kNewTargetState);
	EventManager.TriggerEvent('UnitRemovedFromPlay', KidnappedUnitState, KidnappedUnitState, NewGameState);
	EventManager.TriggerEvent('UnitCaptured', KidnappedUnitState, KidnappedUnitState, NewGameState);
}

simulated function ChosenKidnap_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata SourceMetadata, TargetMetadata, ActionMetadata;
	local XComGameState_Ability Ability;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local Array<X2Action> ParentActions;
	local X2Action_ChosenTargetInteraction KidnapAction;
	local X2Action_MarkerNamed JoinActions;
	local int EffectIndex;
	local X2Action_PlayMessageBanner MessageAction;
	local XGParamTag kTag;
	local XComGameState_HeadquartersXCom XComHQ;
	local string DisplayMessageString;
	local int i, j;
	local StateObjectReference InteractingUnitRef;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	// Create the target metadata
	TargetMetadata = EmptyTrack;
	TargetMetadata.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	TargetMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID);
	TargetMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.PrimaryTarget.ObjectID);

	//Configure the visualization track for the shooter
	//****************************************************************************************
	SourceMetadata = EmptyTrack;
	SourceMetadata.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID);
	SourceMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.SourceObject.ObjectID);
	SourceMetadata.AdditionalVisualizeActors.AddItem(TargetMetadata.VisualizeActor);

	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = Ability.GetMyTemplate();

	class'X2Action_ExitCover'.static.AddToVisualizationTree(SourceMetadata, Context);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if( XComHQ.TacticalGameplayTags.Find('DarkEvent_TheCollectors') != INDEX_NONE )
	{
		DisplayMessageString = class'XLocalizedData'.default.DarkEvent_TheCollectorsMessage;
	}
	else
	{
		DisplayMessageString = AbilityTemplate.LocFlyOverText;
	}

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, DisplayMessageString, '', eColor_Bad, , , true);
	
	// Trigger the Chosen's narrative line before they start the capture
	class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'ChosenTacticalEscape', SourceMetadata.LastActionAdded);

	KidnapAction = X2Action_ChosenTargetInteraction(class'X2Action_ChosenTargetInteraction'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	KidnapAction.ChosenAnimName = 'HL_Kidnap';
	KidnapAction.TargetAnimName = 'HL_Kidnap';

	ParentActions.Length = 0;
	ParentActions.AddItem(class'X2Action_RemoveUnit'.static.AddToVisualizationTree(SourceMetadata, Context, false, KidnapAction));
	//****************************************************************************************
	
	//Configure the visualization track for the target
	//****************************************************************************************
	ParentActions.AddItem(class'X2Action_RemoveUnit'.static.AddToVisualizationTree(TargetMetadata, Context, false, KidnapAction));
	//****************************************************************************************

	JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(TargetMetadata, VisualizeGameState.GetContext(), false, , ParentActions));
	JoinActions.SetName("Join");

	// Get the visualization for the effect that was removed
	for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex )
	{
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, TargetMetadata, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
	}

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = XComGameState_Unit(SourceMetadata.StateObject_NewState).GetFullName(); // chosen name
	kTag.StrValue1 = XComGameState_Unit(TargetMetadata.StateObject_NewState).GetFullName(); // chosen target

	MessageAction = X2Action_PlayMessageBanner(class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree(SourceMetadata, Context, false, JoinActions));
	MessageAction.AddMessageBanner(`XEXPAND.ExpandString(KidnapHeader), , `XEXPAND.ExpandString(KidnapTargetHeader), `XEXPAND.ExpandString(KidnapMessageBody), eUIState_Bad);

	// Multitargets
	for (i = 0; i < Context.InputContext.MultiTargets.Length; ++i)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[i];
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
		ActionMetadata.LastActionAdded = MessageAction;

		for (j = 0; j < Context.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j)
		{
			Context.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}
	}
}

static function X2DataTemplate CreateChosenExtractKnowledgeMove()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent MarkForExtractKnowledgeEffect;
	local X2AbilityCost_ActionPoints ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenExtractKnowledgeMove');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_extractknowledge";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = new class'X2AbilityTarget_MovingMelee';
	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_EndOfMove');

	Template.AdditionalAbilities.AddItem('ChosenExtractKnowledge');

	MarkForExtractKnowledgeEffect = new class'X2Effect_Persistent';
	MarkForExtractKnowledgeEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	MarkForExtractKnowledgeEffect.DuplicateResponse = eDupe_Allow;
	MarkForExtractKnowledgeEffect.EffectName = default.ExtractKnowledgeMarkSourceEffectName;
	Template.AddShooterEffect(MarkForExtractKnowledgeEffect);

	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);

	SetChosenKidnapExtractBaseConditions(Template);

	MarkForExtractKnowledgeEffect = new class'X2Effect_Persistent';
	MarkForExtractKnowledgeEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	MarkForExtractKnowledgeEffect.DuplicateResponse = eDupe_Allow;
	MarkForExtractKnowledgeEffect.EffectName = default.ExtractKnowledgeMarkTargetEffectName;
	Template.AddTargetEffect(MarkForExtractKnowledgeEffect);

	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildVisualizationFn = ChosenMoveToEscape_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;

	Template.bSkipFireAction = true;
	Template.bShowActivation = false;

//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenExtractKnowledgeMove'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CinescriptCameraType = "";
//END AUTOGENERATED CODE: Template Overrides 'ChosenExtractKnowledgeMove'

	Template.PostActivationEvents.AddItem('ChosenExtractKnowledgeTrigger');

	return Template;
}

static function X2DataTemplate CreateChosenExtractKnowledge()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent ExtractKnowledgeEffect;
	local X2Effect_SetUnitValue SetUnitValue;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Condition_UnitEffects MultiTargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenExtractKnowledge');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_extractknowledge";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenExtractKnowledge'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.CustomFireAnim = 'HL_ExtractKnowledge';
	Template.CinescriptCameraType = "Chosen_Extract";
//END AUTOGENERATED CODE: Template Overrides 'ChosenExtractKnowledge'

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChosenKidnapListener;
	EventListener.ListenerData.EventID = 'ChosenExtractKnowledgeTrigger';
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	SetChosenKidnapExtractBaseConditions(Template, default.KIDNAP_DISTANCE_UNITS);

	ExtractKnowledgeEffect = new class'X2Effect_Persistent';
	ExtractKnowledgeEffect.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
	ExtractKnowledgeEffect.bPersistThroughTacticalGameEnd = true;
	ExtractKnowledgeEffect.DuplicateResponse = eDupe_Allow;
	ExtractKnowledgeEffect.EffectName = 'ChosenExtractKnowledge';
	ExtractKnowledgeEffect.EffectAddedFn = ChosenExtractKnowledge_AddedFn;
	Template.AddShooterEffect(ExtractKnowledgeEffect);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue;
	SetUnitValue.NewValueToSet = class'XComGameState_AdventChosen'.const.CHOSEN_STATE_DISABLED;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValue);

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = true;
	Template.AddShooterEffect(MissionTimerEffect);

	ExtractKnowledgeEffect = new class'X2Effect_Persistent';
	ExtractKnowledgeEffect.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
	ExtractKnowledgeEffect.bPersistThroughTacticalGameEnd = true;
	ExtractKnowledgeEffect.DuplicateResponse = eDupe_Allow;
	ExtractKnowledgeEffect.EffectName = 'ChosenExtractKnowledgeTarget';
	Template.AddTargetEffect(ExtractKnowledgeEffect);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DazedName);
	Template.AddTargetEffect(RemoveEffects);

	// Multi Targets - Remove all Daze status effects
	MultiTargetCondition = new class'X2Condition_UnitEffects';
	MultiTargetCondition.AddRequireEffect(class'X2AbilityTemplateManager'.default.DazedName, 'AA_MissingRequiredEffect');
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DazedName);
	RemoveEffects.bCleanse = true;
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = ChosenExtractKnowledge_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;


	Template.PostActivationEvents.AddItem('ChosenInterrogation');
	
	return Template;
}

static function ChosenExtractKnowledge_AddedFn(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit ChosenUnitState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	ChosenUnitState = XComGameState_Unit(kNewTargetState);
	EventManager.TriggerEvent('UnitRemovedFromPlay', ChosenUnitState, ChosenUnitState, NewGameState);

	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien', true));
	if( AlienHQ != none )
	{
		ChosenState = AlienHQ.GetChosenOfTemplate(ChosenUnitState.GetMyTemplateGroupName());
		ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ChosenState.ObjectID));
		ChosenState.ExtractKnowledge();
	}
}


simulated function ChosenExtractKnowledge_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr VisMgr;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata, TargetMetaData;
	local XComGameState_Ability Ability;
	local X2Action_MoveTurn MoveTurnAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_PlayAnimation PlayAnimation;	
	local XComGameState_Unit TargetState;
	local X2Action_MarkerNamed JoinActions;
	local Array<X2Action> ParentActions;
	local X2Action_ChosenTargetInteraction KidnapAction;
	local XComGameState_Unit TargetUnit;
	local int EffectIndex, i, j;
	local X2Action_PlayMessageBanner MessageAction;
	local XGParamTag kTag;
	local Array<X2Action> FoundActions;
	local StateObjectReference InteractingUnitRef;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));

	// Create the target metadata
	TargetMetadata = EmptyTrack;
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	TargetMetadata.StateObject_OldState = TargetUnit;
	TargetMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID);
	TargetMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.PrimaryTarget.ObjectID);

	//Create Chosen metadata
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.SourceObject.ObjectID);
	ActionMetadata.AdditionalVisualizeActors.AddItem(TargetMetadata.VisualizeActor);

	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = Ability.GetMyTemplate();

	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	MoveTurnAction.m_vFacePoint = `XWORLD.GetPositionFromTileCoordinates(TargetState.TileLocation);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Bad, , , true);

	// Play Chosen Start anim
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	PlayAnimation.Params.AnimName = 'HL_ExtractKnowledge_Start';

	// Play joint action for the Extract Knowledge
	KidnapAction = X2Action_ChosenTargetInteraction(class'X2Action_ChosenTargetInteraction'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	KidnapAction.ChosenAnimName = 'HL_ExtractKnowledge';
	KidnapAction.TargetAnimName = 'HL_ExtractKnowledge';
	KidnapAction.bUseSourceLocationForTarget = true;

	// Trigger the Chosen's narrative line now that extraction is complete
	class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, true, 'ChosenTacticalEscape', KidnapAction);

	// Play Chosen End anim
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, KidnapAction));
	PlayAnimation.Params.AnimName = 'HL_ExtractKnowledge_End';

	// Remove the Chosen
	class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, PlayAnimation);

	// Play Target Pose Anim
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(TargetMetadata, Context, false, KidnapAction));
	PlayAnimation.Params.AnimName = 'HL_ExtractKnowledge_Pose';
	PlayAnimation.Params.BlendTime = 0.0f;
	
	// Get the visualization for the effect that was removed
	for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex )
	{
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, TargetMetadata, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
	}

	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_PlayAnimation', FoundActions, TargetMetadata.VisualizeActor);
	for( i = 0; i < FoundActions.Length; ++i )
	{
		PlayAnimation = X2Action_PlayAnimation(FoundActions[i]);
		PlayAnimation.Params.BlendTime = 0.0f;
	}

	// The join will hold until the two units have completed their actions
	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, ParentActions);
	JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(TargetMetadata, Context, false, , ParentActions));
	JoinActions.SetName("Join");

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = XComGameState_Unit(ActionMetadata.StateObject_NewState).GetFullName(); // chosen name
	kTag.StrValue1 = XComGameState_Unit(TargetMetadata.StateObject_NewState).GetFullName(); // chosen target

	MessageAction = X2Action_PlayMessageBanner(class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree(ActionMetadata, Context, false, JoinActions));
	MessageAction.AddMessageBanner(`XEXPAND.ExpandString(ExtractHeader), , `XEXPAND.ExpandString(ExtractTargetHeader), `XEXPAND.ExpandString(ExtractMessageBody), eUIState_Bad);

	// Multitargets
	for (i = 0; i < Context.InputContext.MultiTargets.Length; ++i)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[i];
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
		ActionMetadata.LastActionAdded = MessageAction;

		for (j = 0; j < Context.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j)
		{
			Context.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}
	}
}

static function X2AbilityTemplate CreateChosenWarningMarkUp()
{
	local X2AbilityTemplate             Template;
	local X2Effect_Aura					Effect;
	local X2AbilityMultiTarget_AllUnits	EnemyMultiTarget;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_ChosenWarningMarkUp ChosenWarningMarkUpCondition;
	local X2Effect_PerkAttachForFX VisualEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenWarningMarkUp');

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	EnemyMultiTarget = new class'X2AbilityMultiTarget_AllUnits';
	EnemyMultiTarget.bAcceptEnemyUnits = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.AbilityMultiTargetStyle = EnemyMultiTarget;

	ChosenWarningMarkUpCondition = new class'X2Condition_ChosenWarningMarkUp';
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.RequireWithinRange = true;
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.WithinRange = default.CHOSEN_WARNING_MARK_UP_TILE_DISTANCE * class'XComWorldData'.const.WORLD_StepSize;

	VisualEffect = new class'X2Effect_PerkAttachForFX';
	VisualEffect.EffectName = 'ChosenTargetAura';
	VisualEffect.BuildPersistentEffect(1, true, true);
	VisualEffect.DuplicateResponse = eDupe_Ignore;
	VisualEffect.bRemoveWhenTargetDies = true;
	VisualEffect.TargetConditions.AddItem(UnitPropertyCondition);
	VisualEffect.TargetConditions.AddItem(ChosenWarningMarkUpCondition);
	Template.AddMultiTargetEffect(VisualEffect);

	Effect = new class'X2Effect_Aura';
	Effect.BuildPersistentEffect(1, true, true);
	Effect.EffectName = 'ChosenWarningAura';
	Effect.EventsToUpdate.AddItem('UnitStunned');
	Effect.EventsToUpdate.AddItem('UnitStunnedRemoved');
	Effect.EventsToUpdate.AddItem('UnitBleedingOut');
	Effect.EventsToUpdate.AddItem('UnitBleedingOutRemoved');
	Effect.EventsToUpdate.AddItem('UnitUnconscious');
	Effect.EventsToUpdate.AddItem('UnitUnconsciousRemoved');
	Effect.EventsToUpdate.AddItem('StasisLanceAdded');
	Effect.EventsToUpdate.AddItem('StasisLanceRemoved');
	Template.AddShooterEffect(Effect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenWarningMarkUp'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'ChosenWarningMarkUp'

	return Template;
}

static function X2DataTemplate CreateKeen()
{
	local X2AbilityTemplate Template;
	local X2Effect_ChosenKeen KeenEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenKeen');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_keen";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.bDontDisplayInAbilitySummary = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	KeenEffect = new class'X2Effect_ChosenKeen';
	KeenEffect.BuildPersistentEffect(1, true, true, true);
	KeenEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddTargetEffect(KeenEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

// Mark Chosen as activated when any AI unit becomes alerted to XCom.
static function X2AbilityTemplate CreateChosenActivation()
{
	local X2AbilityTemplate Template;
	local X2Condition_UnitEffects ExcludeEffectsCondition;
	local X2Effect_Persistent ActivatedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenActivation');
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	ExcludeEffectsCondition = new class'X2Condition_UnitEffects';
	ExcludeEffectsCondition.AddExcludeEffect('ChosenActivated', 'AA_DuplicateEffectIgnored');
	Template.AbilityShooterConditions.AddItem(ExcludeEffectsCondition);

	ActivatedEffect = new class'X2Effect_Persistent';
	ActivatedEffect.EffectName = 'ChosenActivated';
	ActivatedEffect.BuildPersistentEffect(1, true, false, true);
	ActivatedEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	ActivatedEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(ActivatedEffect);

	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.bSkipFireAction = true;

	Template.PostActivationEvents.AddItem('ChosenSpawnedIn');

	Template.AdditionalAbilities.AddItem('ChosenReveal');
	Template.AdditionalAbilities.AddItem('ChosenEngaged');
	Template.AdditionalAbilities.AddItem('ChosenDirectedAttack');
	Template.AdditionalAbilities.AddItem('ChosenSummonFollowers');
	//Template.AdditionalAbilities.AddItem('ChosenDefeatedSustain');
	Template.AdditionalAbilities.AddItem('ChosenDefeatedEscape');
	//Template.AdditionalAbilities.AddItem('ChosenHalfDamageTeleport');
//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenActivation'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'ChosenActivation'

	return Template;
}

// Added an ability to kick off the Chosen reveal on the start of the AI turn if activated.
// Chosen Reveal : When any enemy unit is activated on the map, at the start of the next AI turn :
// -The camera should pan to the Chosen location and reveal the fog.
// -The Chosen should play their reveal animation
// -The Chosen should begin their “Mission Behavior”
static function X2AbilityTemplate CreateChosenReveal()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitEffects UnitEffectsCondition;
	local X2Condition_UnitValue ActivatedValueNotSet;
	local X2Effect_SetUnitValue SetUnitValue;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenReveal');
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Apply at the start of the player turn.  
	// This trigger checks for other requirements, i.e. activated already.
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'ChosenSpawnedIn';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ActivateChosenReveal;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	ActivatedValueNotSet = new class'X2Condition_UnitValue';
	ActivatedValueNotSet.AddCheckValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, class'XComGameState_AdventChosen'.const.CHOSEN_STATE_UNACTIVATED);
	Template.AbilityShooterConditions.AddItem(ActivatedValueNotSet);

	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddRequireEffect('ChosenActivated', 'AA_MissingRequiredEffect');
	Template.AbilityShooterConditions.AddItem(UnitEffectsCondition);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue;
	SetUnitValue.NewValueToSet = class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ACTIVATED;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValue);

	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Always;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;

}

// Mark Chosen as Engaged when a non-concealed XCom unit has LoS to the Chosen unit.
static function X2AbilityTemplate CreateChosenEngaged()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitValue ActivatedValueNotSet;
	local X2Effect_SetUnitValue SetUnitValue;
	//local X2Effect_ModifyInitiativeOrder RemoveFromInitiativeEffect;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenEngaged');
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Activate trigger when the chosen unit can see an xcom unit.
	// Custom event function checks xcom unit is unconcealed and has LoS.  Also removes unit from Initiative Order.
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitSeesUnit';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ActivateChosenEngaged;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	ActivatedValueNotSet = new class'X2Condition_UnitValue';
	ActivatedValueNotSet.AddCheckValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ENGAGED, eCheck_LessThan);
	Template.AbilityShooterConditions.AddItem(ActivatedValueNotSet);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue;
	SetUnitValue.NewValueToSet = class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ENGAGED;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValue);

	// TODO: re-add if chosen activation system should be enabled
	//RemoveFromInitiativeEffect = new class'X2Effect_ModifyInitiativeOrder';
	//RemoveFromInitiativeEffect.bRemoveGroupFromInitiativeOrder = true;
	//Template.AddShooterEffect(RemoveFromInitiativeEffect);

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = false;
	Template.AddShooterEffect(MissionTimerEffect);

	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Always;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Engaged_BuildVisualization;

	Template.AssociatedPlayTiming = SPT_AfterSequential;

	return Template;
}

simulated function Engaged_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local VisualizationActionMetadata EmptyTrack, ActionMetadata;
	local StateObjectReference InteractingUnitRef;
	local XComGameStateContext_Ability  AbilityContext;
	local X2Action_UpdateUI UpdateUIAction;
	local X2Action_CameraLookAt LookAtAction;
	local XComGameState_Unit UnitState;
	local XComGameState_AIGroup GroupState;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;
	UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID));
	GroupState = UnitState.GetGroupMembership(VisualizeGameState, VisualizeGameState.HistoryIndex);
	if( GroupState.bProcessedScamper && !GroupState.bPendingScamper ) // skip visualization of the engaged state if the chosen has not yet scampered
	{
		TypicalAbility_BuildVisualization(VisualizeGameState);

		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		// Pan to Chosen if not already there.
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
		LookAtAction.UseTether = false;
		LookAtAction.LookAtObject = ActionMetadata.StateObject_NewState;
		LookAtAction.BlockUntilActorOnScreen = true;

		// Update Chosen UI and play fanfare audio (via UI code on first time).
		UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
		UpdateUIAction.SpecificID = InteractingUnitRef.ObjectID;
		UpdateUIAction.UpdateType = EUIUT_ChosenHUD;

		class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, true, 'ChosenEngaged');

		// Keep Camera on Chosen while fancy UI reveal appears.  
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
		LookAtAction.UseTether = false;
		LookAtAction.LookAtObject = ActionMetadata.StateObject_NewState;
		LookAtAction.BlockUntilFinished = true;
		LookAtAction.LookAtDuration = EngagedRevealCameraDuration;
	}
}

static function X2AbilityTemplate CreateChosenSummonFollowers()
{
	local X2AbilityTemplate Template;
	local X2Condition_UnitValue UnitValueCheck;
	local X2Effect_SetUnitValue SetUnitValue;
	local X2Condition_BattleState BattleCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenSummonFollowers');
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	BattleCondition = new class'X2Condition_BattleState';
	BattleCondition.MaxEngagedEnemies = 1;
	Template.AbilityShooterConditions.AddItem(BattleCondition);

	UnitValueCheck = new class'X2Condition_UnitValue';
	UnitValueCheck.AddCheckValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ENGAGED, eCheck_Exact);
	Template.AbilityShooterConditions.AddItem(UnitValueCheck);

	UnitValueCheck = new class'X2Condition_UnitValue';
	UnitValueCheck.AddCheckValue('FollowersSummoned', 1, eCheck_LessThan);
	Template.AbilityShooterConditions.AddItem(UnitValueCheck);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = 'FollowersSummoned';
	SetUnitValue.NewValueToSet = 1;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValue);


	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Always;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = ChosenSummonFollowers_BuildGameState;
	Template.BuildVisualizationFn = ChosenSummonFollowers_BuildVisualization;
//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenSummonFollowers'
	Template.bShowActivation = true;
	Template.CinescriptCameraType = "Chosen_Summon";
//END AUTOGENERATED CODE: Template Overrides 'ChosenSummonFollowers'

	return Template;
}

static function XComGameState ChosenSummonFollowers_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local PodSpawnInfo SpawnInfo;
	local XComAISpawnManager SpawnManager;
	local int AlertLevel, ForceLevel;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionSiteState;
	local XComGameState_Unit UnitState;
	local XComGameState_AdventChosen ChosenState;
	local TTile ChosenTileLocation;
	local XComWorldData WorldData;
	local Name FollowerEncounterGroupID;
	local X2EventManager EventManager;
	local Object UnitObject;

	EventManager = `XEVENTMGR;
	History = `XCOMHISTORY;

	NewGameState = History.CreateNewGameState(true, Context);

	TypicalAbility_FillOutGameState(NewGameState);

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComGameStateContext_Ability(Context).InputContext.SourceObject.ObjectID));
	ChosenState = UnitState.GetChosenGameState();
	FollowerEncounterGroupID = ChosenState.GetReinforcementGroupName();

	if( FollowerEncounterGroupID != '' )
	{
		SpawnInfo.EncounterID = FollowerEncounterGroupID;

		WorldData = `XWORLD;
		UnitState.GetKeystoneVisibilityLocation(ChosenTileLocation);
		SpawnInfo.SpawnLocation = WorldData.GetPositionFromTileCoordinates(ChosenTileLocation);

		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		ForceLevel = BattleData.GetForceLevel();
		AlertLevel = BattleData.GetAlertLevel();

		if( BattleData.m_iMissionID > 0 )
		{
			MissionSiteState = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));

			if( MissionSiteState != None && MissionSiteState.SelectedMissionData.SelectedMissionScheduleName != '' )
			{
				AlertLevel = MissionSiteState.SelectedMissionData.AlertLevel;
				ForceLevel = MissionSiteState.SelectedMissionData.ForceLevel;
			}
		}

		// build a character selection that will work at this location
		SpawnManager = `SPAWNMGR;
		SpawnManager.SelectPodAtLocation(SpawnInfo, ForceLevel, AlertLevel, BattleData.ActiveSitReps);
		SpawnManager.SpawnPodAtLocation(NewGameState, SpawnInfo, false, false, true);

		if( SpawnInfo.SpawnedPod.m_arrUnitIDs.Length > 0 )
		{
			UnitObject = UnitState;
			EventManager.RegisterForEvent(UnitObject, 'ChosenSpawnReinforcementsComplete', UnitState.OnSpawnReinforcementsComplete, ELD_OnStateSubmitted, , UnitState);
			EventManager.TriggerEvent('ChosenSpawnReinforcementsComplete', SpawnInfo.SpawnedPod.GetGroupState(), UnitState, NewGameState);
		}
	}


	return NewGameState;
}

simulated function ChosenSummonFollowers_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local VisualizationActionMetadata EmptyTrack, ActionMetadata, NewUnitActionMetadata;
	local StateObjectReference InteractingUnitRef;
	local XComGameStateContext_Ability  AbilityContext;
	local X2Action_CameraLookAt LookAtAction;
	local XComGameState_Unit UnitState;
	local XComGameState_AdventChosen ChosenState;
	local array<XComGameState_Unit> FreshlySpawnedUnitStates;
	local TTile SpawnedUnitTile;
	local X2Action_RevealArea RevealAreaAction;
	local X2Action_PlayAnimation PlayAnimAction;
	local XComWorldData WorldData;
	local X2AbilityTemplate ReinforcementStrengthTemplate;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_PlayEffect SpawnEffectAction;
	local X2Action_Delay RandomDelay;
	local float OffsetVisDuration;
	local array<X2Action>					LeafNodes;
	local XComContentManager ContentManager;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local X2Action_MarkerNamed SyncAction;

	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	ContentManager = `CONTENT;
	History = `XCOMHISTORY;

	TypicalAbility_BuildVisualization(VisualizeGameState);

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(InteractingUnitRef.ObjectID));
	ChosenState = UnitState.GetChosenGameState();
	ReinforcementStrengthTemplate = ChosenState.GetReinforcementStrength();

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( History.GetGameStateForObjectID(UnitState.ObjectID, , VisualizeGameState.HistoryIndex - 1) == None )
		{
			FreshlySpawnedUnitStates.AddItem(UnitState);
		}
	}

	// if any units spawned in as part of this action, visualize the spawning as part of this sequence
	if( FreshlySpawnedUnitStates.Length > 0 )
	{
		WorldData = `XWORLD;

		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		// Pan to Chosen if not already there.
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
		LookAtAction.UseTether = false;
		LookAtAction.LookAtObject = ActionMetadata.StateObject_NewState;
		LookAtAction.BlockUntilActorOnScreen = true;

		if( ReinforcementStrengthTemplate != None )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, ReinforcementStrengthTemplate.LocFlyOverText, '', eColor_Bad);
		}

		RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
		RevealAreaAction.ScanningRadius = class'XComWorldData'.const.WORLD_StepSize * 5.0f;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(InteractingUnitRef.ObjectID));
		UnitState.GetKeystoneVisibilityLocation(SpawnedUnitTile);
		RevealAreaAction.TargetLocation = WorldData.GetPositionFromTileCoordinates(SpawnedUnitTile);
		RevealAreaAction.bDestroyViewer = false;
		RevealAreaAction.AssociatedObjectID = InteractingUnitRef.ObjectID;
		
		// Trigger the Chosen's narrative line for summoning
		class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'ChosenSummonBegin', ActionMetadata.LastActionAdded);

		// play an animation on the chosen showing them summoning in their followers
		PlayAnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, , ActionMetadata.LastActionAdded));
		PlayAnimAction.bFinishAnimationWait = true;
		PlayAnimAction.Params.AnimName = 'HL_Summon';

		SyncAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
		SyncAction.SetName("SpawningStart");
		SyncAction.AddInputEvent('Visualizer_AbilityHit');

		foreach FreshlySpawnedUnitStates(UnitState)
		{
			if( UnitState.GetVisualizer() == none )
			{
				UnitState.FindOrCreateVisualizer();
				UnitState.SyncVisualizer();

				//Make sure they're hidden until ShowSpawnedUnit makes them visible (SyncVisualizer unhides them)
				XGUnit(UnitState.GetVisualizer()).m_bForceHidden = true;
			}

			NewUnitActionMetadata = EmptyTrack;
			NewUnitActionMetadata.StateObject_OldState = None;
			NewUnitActionMetadata.StateObject_NewState = UnitState;
			NewUnitActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);

			// if multiple units are spawning, apply small random delays between each
			if( UnitState != FreshlySpawnedUnitStates[0] )
			{
				RandomDelay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(NewUnitActionMetadata, AbilityContext, false, SyncAction));
				OffsetVisDuration += 0.5f + `SYNC_FRAND() * 0.5f;
				RandomDelay.Duration = OffsetVisDuration;
			}
			
			X2Action_ShowSpawnedUnit(class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(NewUnitActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));

			UnitState.GetKeystoneVisibilityLocation(SpawnedUnitTile);

			SpawnEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(NewUnitActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
			SpawnEffectAction.EffectName = ContentManager.ChosenReinforcementsEffectPathName;
			SpawnEffectAction.EffectLocation = WorldData.GetPositionFromTileCoordinates(SpawnedUnitTile);
			SpawnEffectAction.bStopEffect = false;
		}

		VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

		RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, none, LeafNodes));
		RevealAreaAction.bDestroyViewer = true;
		RevealAreaAction.AssociatedObjectID = InteractingUnitRef.ObjectID;
	}
}

static function X2AbilityTemplate CreateChosenDefeatedSustain()
{
	local X2AbilityTemplate             Template;
	local X2Effect_Sustain              SustainEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenDefeatedSustain');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sustain";
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	SustainEffect = new class'X2Effect_Sustain';
	SustainEffect.BuildPersistentEffect(1, true, true);
	SustainEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	SustainEffect.EffectName = 'ChosenDefeatedSustain';
	Template.AddTargetEffect(SustainEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!

	return Template;
}

static function X2AbilityTemplate CreateChosenDefeatedEscape()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventTrigger;
	//local X2Effect_Stasis StasisEffect;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Condition_UnitEffects MultiTargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenDefeatedEscape');
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';

	EventTrigger = new class'X2AbilityTrigger_EventListener';
	EventTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventTrigger.ListenerData.EventID = 'UnitDied';
	EventTrigger.ListenerData.Filter = eFilter_Unit;
	EventTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(EventTrigger);

	//StasisEffect = new class'X2Effect_Stasis';
	//StasisEffect.EffectName = 'ChosenDefeatedEscape';
	//StasisEffect.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
	//StasisEffect.bPersistThroughTacticalGameEnd = true;
	//StasisEffect.bUseSourcePlayerState = true;
	//StasisEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
	//StasisEffect.StunStartAnim = 'HL_PsiSustainStart';
	//StasisEffect.bSkipFlyover = true;
	//StasisEffect.EffectAddedFn = ChosenDefeatedEscape_AddedFn;
	//Template.AddShooterEffect(StasisEffect);

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = true;
	Template.AddShooterEffect(MissionTimerEffect);

	// Multi Targets - Remove all Daze status effects
	MultiTargetCondition = new class'X2Condition_UnitEffects';
	MultiTargetCondition.AddRequireEffect(class'X2AbilityTemplateManager'.default.DazedName, 'AA_MissingRequiredEffect');
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DazedName);
	RemoveEffects.bCleanse = true;
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = ChosenDefeatedEscape_BuildGameState;
	Template.BuildVisualizationFn = ChosenDefeatedEscape_BuildVisualization;
	Template.AssociatedPlayTiming = SPT_AfterSequential;  // play after the chosen death that initiated this ability
//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenDefeatedEscape'
	Template.CinescriptCameraType = "Chosen_Escape";
//END AUTOGENERATED CODE: Template Overrides 'ChosenDefeatedEscape'

	return Template;
}

static function XComGameState ChosenDefeatedEscape_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;
	History = `XCOMHISTORY;

	NewGameState = History.CreateNewGameState(true, Context);

	TypicalAbility_FillOutGameState(NewGameState);

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComGameStateContext_Ability(Context).InputContext.SourceObject.ObjectID));

	EventManager.TriggerEvent('UnitRemovedFromPlay', UnitState, UnitState, NewGameState);

	return NewGameState;
}

simulated function ChosenDefeatedEscape_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameState_Ability Ability;
	local X2AbilityTemplate AbilityTemplate;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_PlayAnimation PlayAnimation;
	local XGUnit Unit;
	local XComUnitPawn UnitPawn;
	local X2Action_PlayMessageBanner MessageAction;
	local XGParamTag kTag;
	local X2Action_PlayEffect EffectAction;
	local X2Action_Delay DelayAction;
	local X2Action_CameraLookAt LookAtAction;
	local X2AdventChosenTemplate ChosenTemplate;
	local int i, j;
	local StateObjectReference InteractingUnitRef;
	
	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.SourceObject.ObjectID);

	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = Ability.GetMyTemplate();

	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	LookAtAction.UseTether = false;
	LookAtAction.LookAtObject = ActionMetadata.StateObject_NewState;
	LookAtAction.LookAtDuration = 10.0;
	LookAtAction.CameraTag = 'ChosenDefeatedEscape';

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Bad);
	
	if( ActionMetadata.VisualizeActor != None )
	{
		Unit = XGUnit(ActionMetadata.VisualizeActor);
		if( Unit != None )
		{
			UnitPawn = Unit.GetPawn();
			if( UnitPawn != None )
			{
				PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				PlayAnimation.Params.AnimName = Ability.GetFireAnimationName(UnitPawn, false, false, vector(UnitPawn.Rotation), vector(UnitPawn.Rotation), true, 0);
			}
		}
	}

	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, PlayAnimation));
	EffectAction.EffectName = "FX_Chosen_Teleport.P_Chosen_Teleport_Out_w_Sound";
	EffectAction.EffectLocation = ActionMetadata.VisualizeActor.Location;
	EffectAction.bWaitForCompletion = true;

	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, PlayAnimation));
	DelayAction.Duration = 0.25;

	class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, DelayAction);

	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, EffectAction));
	LookAtAction.bRemoveTaggedCamera = true;
	LookAtAction.CameraTag = 'ChosenDefeatedEscape';
	//****************************************************************************************

	// Trigger the Chosen's narrative line after they leave
	class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, true, 'ChosenTacticalEscape', ActionMetadata.LastActionAdded);

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ChosenTemplate = XComGameState_Unit(ActionMetadata.StateObject_NewState).GetChosenGameState().GetMyTemplate();
	kTag.StrValue0 = ChosenTemplate.ChosenTitle; // chosen name
	kTag.StrValue1 = ChosenTemplate.ChosenTitleWithArticle; // chosen name + article

	MessageAction = X2Action_PlayMessageBanner(class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	MessageAction.AddMessageBanner(`XEXPAND.ExpandString(DefeatedHeader), , `XEXPAND.ExpandString(DefeatedTargetHeader), `XEXPAND.ExpandString(DefeatedMessageBody), eUIState_Good);

	// Multitargets
	for( i = 0; i < Context.InputContext.MultiTargets.Length; ++i )
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[i];
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
		ActionMetadata.LastActionAdded = MessageAction;

		for( j = 0; j < Context.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			Context.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}
	}
}

// Strengths
static function X2AbilityTemplate ChosenShadowstep()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Persistent                   Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenShadowstep');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shadowstep";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_Persistent';
	Effect.EffectName = 'Shadowstep';
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.ChosenTraitType = 'Survivability';

	return Template;
}

static function X2AbilityTemplate CreateChosenRevenge()
{
	local X2AbilityTemplate Template;
	local X2Effect_CoveringFire CoveringEffect;

	Template = PurePassive('ChosenRevenge', "img:///UILibrary_XPACK_Common.PerkIcons.str_revenge", false, 'eAbilitySource_Perk', true);
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	CoveringEffect = new class'X2Effect_CoveringFire';
	CoveringEffect.BuildPersistentEffect(1, true, false, false);
	CoveringEffect.EffectName = 'RevengeFire';
	CoveringEffect.DuplicateResponse = eDupe_Ignore;
	CoveringEffect.AbilityToActivate = 'OverwatchShot';
	CoveringEffect.GrantActionPoint = 'overwatch';
	CoveringEffect.MaxPointsPerTurn = 0;	// Infinite
	CoveringEffect.bDirectAttackOnly = true;
	CoveringEffect.bPreEmptiveFire = false;
	CoveringEffect.bOnlyDuringEnemyTurn = true;
	CoveringEffect.bOnlyWhenAttackMisses = true;
	CoveringEffect.ActivationPercentChance = default.REVENGE_CHANCE_PERCENT;
	CoveringEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	Template.AddTargetEffect(CoveringEffect);

	Template.ChosenTraitType = 'General';

	return Template;
}

static function X2AbilityTemplate CreateChosenLowProfile()
{
	local X2AbilityTemplate Template;
	local X2Effect_CoveringFire CoveringEffect;

	Template = PurePassive('ChosenLowProfile', "img:///UILibrary_XPACK_Common.PerkIcons.str_lowprofile", false, 'eAbilitySource_Perk', true);
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	CoveringEffect = new class'X2Effect_CoveringFire';
	CoveringEffect.BuildPersistentEffect(1, true, false, false);
	CoveringEffect.AbilityToActivate = 'ChosenLowProfileTrigger';
	CoveringEffect.bPreEmptiveFire = false;
	CoveringEffect.bDirectAttackOnly = true;
	CoveringEffect.bOnlyDuringEnemyTurn = true;
	CoveringEffect.bUseMultiTargets = false;
	CoveringEffect.bSelfTargeting = true;
	CoveringEffect.EffectName = 'ChosenLowProfileWatchEffect';
	CoveringEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	Template.AddTargetEffect(CoveringEffect);

	Template.AdditionalAbilities.AddItem('ChosenLowProfileTrigger');

	Template.ChosenTraitType = 'Survivability';

	return Template;
}

static function X2DataTemplate CreateChosenLowProfileTrigger()
{
	local X2AbilityTemplate Template;
	local X2Condition_UnitEffects ExcludeEffectsCondition;
	local X2Effect_PersistentStatChange LowProfileEffect;
	local X2Effect_RemoveEffects RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenLowProfileTrigger');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_lowprofile";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	// Check to make sure ChosenLowProfile has not already been attached
	ExcludeEffectsCondition = new class'X2Condition_UnitEffects';
	ExcludeEffectsCondition.AddExcludeEffect('ChosenLowProfileBoost', 'AA_DuplicateEffectIgnored');
	Template.AbilityShooterConditions.AddItem(ExcludeEffectsCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem('ChosenLowProfileWatchEffect');
	Template.AddShooterEffect(RemoveEffects);

	LowProfileEffect = new class'X2Effect_PersistentStatChange';
	LowProfileEffect.EffectName = 'ChosenLowProfileBoost';
	LowProfileEffect.AddPersistentStatChange(eStat_Defense, default.LOWPROFILE_DEFENSE_INCREASE_AMOUNT, MODOP_Addition);
	LowProfileEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	LowProfileEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	LowProfileEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(LowProfileEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bSkipFireAction = true;
	Template.bShowPostActivation = true;
	//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenLowProfileTrigger'
	Template.bFrameEvenWhenUnitIsHidden = true;
	//END AUTOGENERATED CODE: Template Overrides 'ChosenLowProfileTrigger'

	return Template;
}

static function X2DataTemplate CreateChosenCornered()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitEffects ExcludeEffectsCondition;
	local X2Effect_Persistent CorneredEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenCornered');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_cornered";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	// This ability fires when the unit takes damage
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitTakeEffectDamage';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	// Check to make sure ChosenCornered has not already been attached
	ExcludeEffectsCondition = new class'X2Condition_UnitEffects';
	ExcludeEffectsCondition.AddExcludeEffect('ChosenCornered', 'AA_DuplicateEffectIgnored');
	Template.AbilityShooterConditions.AddItem(ExcludeEffectsCondition);

	CorneredEffect = new class'X2Effect_Persistent';
	CorneredEffect.EffectName = 'ChosenCornered';
	CorneredEffect.BuildPersistentEffect(1, true, false, true);
	CorneredEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	CorneredEffect.DuplicateResponse = eDupe_Ignore;
	CorneredEffect.ApplyChanceFn = ApplyChance_ChosenCornered;
	CorneredEffect.EffectAddedFn = ChosenCornered_AddedFn;
	Template.AddTargetEffect(CorneredEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	return Template;
}

static function name ApplyChance_ChosenCornered(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit ChosenState;
	
	ChosenState = XComGameState_Unit(kNewTargetState);
	if( (ChosenState.GetCurrentStat(eStat_HP) / ChosenState.GetMaxStat(eStat_HP)) <= default.CORNERED_PERCENT_HEALTH_ACTIVATION )
	{
		// If the current health is <= the given percentage, attach the ChosenCornered Effect
		return 'AA_Success';
	}

	return 'AA_EffectChanceFailed';
}

static function ChosenCornered_AddedFn(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit ChosenState;

	ChosenState = XComGameState_Unit(kNewTargetState);
	ChosenState.ActivationThreshold *= default.CORNERED_ACTIVATION_THRESHOLD_CHANGE;
}

static function X2AbilityTemplate CreateChosenAllSeeing()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent AllSeeingEffect;

	Template = PurePassive('ChosenAllSeeing', "img:///UILibrary_XPACK_Common.PerkIcons.str_allseeing", false, 'eAbilitySource_Perk', true);
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	AllSeeingEffect = new class'X2Effect_Persistent';
	AllSeeingEffect.BuildPersistentEffect(1, true, false, false);
	AllSeeingEffect.EffectName = 'ChosenAllSeeing';
	AllSeeingEffect.DuplicateResponse = eDupe_Ignore;
	AllSeeingEffect.GetModifyChosenActivationIncreasePerUseFn = GetModifyChosenActivationPoints_ZoneOfControl;
	AllSeeingEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	AllSeeingEffect.UnitBreaksConcealmentIgnoringDistanceFn = UnitBreaksConcealmentIgnoringDistance_AllSeeing;
	Template.AddShooterEffect(AllSeeingEffect);

	Template.ChosenTraitType = 'General';
	Template.ChosenExcludeTraits.AddItem('ChosenReaperAdversary');

	return Template;
}

static function bool UnitBreaksConcealmentIgnoringDistance_AllSeeing()
{
	return true;
}

static function X2AbilityTemplate CreateChosenZoneOfControl()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent ZoneOfControlEffect;

	Template = PurePassive('ChosenZoneOfControl', "img:///UILibrary_XPACK_Common.PerkIcons.str_zonecontrol", false, 'eAbilitySource_Perk', true);
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	ZoneOfControlEffect = new class'X2Effect_Persistent';
	ZoneOfControlEffect.BuildPersistentEffect(1, true, false, false);
	ZoneOfControlEffect.EffectName = 'ZoneOfControl';
	ZoneOfControlEffect.DuplicateResponse = eDupe_Ignore;
	ZoneOfControlEffect.GetModifyChosenActivationIncreasePerUseFn = GetModifyChosenActivationPoints_ZoneOfControl;
	ZoneOfControlEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	Template.AddShooterEffect(ZoneOfControlEffect);

	return Template;
}

static function bool GetModifyChosenActivationPoints_ZoneOfControl(XComGameState_Ability AbilityState, out ModifyChosenActivationIncreasePerUse ModifyChosenActivationPoints)
{
	if( default.ZONEOFCONTROL_REACT_TO_ABILITIES.Find(AbilityState.GetMyTemplateName()) != INDEX_NONE )
	{
		ModifyChosenActivationPoints.Amount = default.ZONEOFCONTROL_CHOSEN_ACTIVATION_INCREASE_PER_USE;
		ModifyChosenActivationPoints.ModOp = MODOP_Addition;
		return true;
	}
	
	return false;
}

static function X2DataTemplate CreateImmunityAbility(name ImmunityAbilityName, string ImmunityAbilityIcon, array<name> ImmuneDamageTypes)
{
	local X2AbilityTemplate Template;
	local X2Effect_DamageImmunity DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, ImmunityAbilityName);

	Template.IconImage = ImmunityAbilityIcon;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDontDisplayInAbilitySummary = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the immunities
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, true, true);
	DamageImmunity.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	DamageImmunity.ImmuneTypes = ImmuneDamageTypes;
	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.ChosenTraitType = 'Immunity';

	return Template;
}

static function X2DataTemplate CreateMeleeImmunity()
{
	local X2AbilityTemplate Template;

	Template = X2AbilityTemplate(CreateImmunityAbility('ChosenImmuneMelee', "img:///UILibrary_XPACK_Common.PerkIcons.str_immunetomelee", default.CHOSEN_IMMUNE_MELEE_DMG_TYPES));
	Template.ChosenExcludeTraits.AddItem('ChosenTemplarAdversary');

	return Template;
}

static function X2DataTemplate BlastShield()
{
	local X2AbilityTemplate Template;
	local X2Effect_BlastShield ShieldEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BlastShield');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_immunetoexplosives";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDontDisplayInAbilitySummary = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	ShieldEffect = new class'X2Effect_BlastShield';
	ShieldEffect.BuildPersistentEffect(1, true, true, true);
	ShieldEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	Template.AddTargetEffect(ShieldEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.ChosenTraitType = 'Immunity';
	Template.ChosenExcludeTraits.AddItem('ChosenWeakExplosion');

	return Template;
}

static function X2AbilityTemplate CreateChosenRegenerate()
{
	local X2AbilityTemplate Template;
	local X2Effect_Regeneration RegenerationEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenRegenerate');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_regenerate";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the regeneration effect
	RegenerationEffect = new class'X2Effect_Regeneration';
	RegenerationEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	RegenerationEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	RegenerationEffect.HealAmount = default.CHOSEN_REGENERATION_HEAL_VALUE;
	Template.AddTargetEffect(RegenerationEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.ChosenTraitType = 'Survivability';
	Template.ChosenExcludeTraits.AddItem('ChosenSoulstealer');

	return Template;
}
// Strengths

// Strengths/Weaknesses
static function X2AbilityTemplate CreateChosenModifyStat(name AbilityName, string AbilityIcon, EPerkBuffCategory BuffCategory, array<StatChange> StatChanges, name TraitType)
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange ModifyStatEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = AbilityIcon;
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the regeneration effect
	ModifyStatEffect = new class'X2Effect_PersistentStatChange';
	ModifyStatEffect.BuildPersistentEffect(1, true, false);
	ModifyStatEffect.SetDisplayInfo(BuffCategory, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	ModifyStatEffect.m_aStatChanges = StatChanges;
	Template.AddTargetEffect(ModifyStatEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.ChosenTraitType = TraitType;

	return Template;
}

static function X2AbilityTemplate CreateChosenSummoningAbility(name AbilityName, string AbilityIcon, const out array<name> Encounters)
{
	local X2AbilityTemplate Template;

	Template = PurePassive(AbilityName, AbilityIcon, false, 'eAbilitySource_Perk', true);
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.ChosenTraitType = 'Summoning';
	Template.ChosenReinforcementGroupName = Encounters;
	Template.ChosenTraitForceLevelGate = 4;

	return Template;
}

static function X2AbilityTemplate CreateBeastmasterAbility()
{
	local X2AbilityTemplate Template;

	Template = CreateChosenSummoningAbility('Beastmaster', "img:///UILibrary_XPACK_Common.PerkIcons.str_beastmaster", default.BeastmasterEncounterGroupsPerChosenLevel);

	Template.ChosenExcludeTraits.AddItem('Prelate');
	Template.ChosenExcludeTraits.AddItem('Mechlord');
	Template.ChosenExcludeTraits.AddItem('General');
	Template.ChosenExcludeTraits.AddItem('Shogun');

	return Template;
}

static function X2AbilityTemplate CreatePrelateAbility()
{
	local X2AbilityTemplate Template;

	Template = CreateChosenSummoningAbility('Prelate', "img:///UILibrary_XPACK_Common.PerkIcons.str_holy", default.PrelateEncounterGroupsPerChosenLevel);

	Template.ChosenExcludeTraits.AddItem('Beastmaster');
	Template.ChosenExcludeTraits.AddItem('Mechlord');
	Template.ChosenExcludeTraits.AddItem('General');
	Template.ChosenExcludeTraits.AddItem('Shogun');

	return Template;
}

static function X2AbilityTemplate CreateMechlordAbility()
{
	local X2AbilityTemplate Template;

	Template = CreateChosenSummoningAbility('Mechlord', "img:///UILibrary_XPACK_Common.PerkIcons.str_mechlord", default.MechlordEncounterGroupsPerChosenLevel);

	Template.ChosenExcludeTraits.AddItem('Beastmaster');
	Template.ChosenExcludeTraits.AddItem('Prelate');
	Template.ChosenExcludeTraits.AddItem('General');
	Template.ChosenExcludeTraits.AddItem('Shogun');

	return Template;
}

static function X2AbilityTemplate CreateGeneralAbility()
{
	local X2AbilityTemplate Template;

	Template = CreateChosenSummoningAbility('General', "img:///UILibrary_XPACK_Common.PerkIcons.str_commander", default.GeneralEncounterGroupsPerChosenLevel);

	Template.ChosenExcludeTraits.AddItem('Beastmaster');
	Template.ChosenExcludeTraits.AddItem('Prelate');
	Template.ChosenExcludeTraits.AddItem('Mechlord');
	Template.ChosenExcludeTraits.AddItem('Shogun');

	return Template;
}

static function X2AbilityTemplate CreateShogunAbility()
{
	local X2AbilityTemplate Template;

	Template = CreateChosenSummoningAbility('Shogun', "img:///UILibrary_XPACK_Common.PerkIcons.str_shogun", default.ShogunEncounterGroupsPerChosenLevel);

	Template.ChosenExcludeTraits.AddItem('Beastmaster');
	Template.ChosenExcludeTraits.AddItem('Prelate');
	Template.ChosenExcludeTraits.AddItem('Mechlord');
	Template.ChosenExcludeTraits.AddItem('General');

	return Template;
}

static function X2AbilityTemplate CreateChosenDamagedTeleportAbility()
{
	local X2AbilityTemplate Template;

	Template = class'X2Ability_PsiWitch'.static.CreateTriggerDamagedTeleportListenerAbility('ChosenDamagedTeleport');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_teleportondamage";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.ChosenTraitType = 'Survivability';
	Template.ChosenTraitForceLevelGate = 4;
	Template.ChosenExcludeTraits.AddItem('ChosenAgile');
//BEGIN AUTOGENERATED CODE: Template Overrides 'ChosenDamagedTeleport'
	Template.bDontDisplayInAbilitySummary = false;
//END AUTOGENERATED CODE: Template Overrides 'ChosenDamagedTeleport'

	Template.bShowActivation = true;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate CreateChosenDamagedTeleportAtHalfHealthAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_Charges ChargeCost;

	Template = class'X2Ability_PsiWitch'.static.CreateTriggerDamagedTeleportListenerAbility('ChosenHalfDamageTeleport', class'XComGameState_Ability'.static.AbilityTriggerEventListener_DamagedTeleportAtHalfHealth);
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_teleportondamage";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityCharges = new class'X2AbilityCharges';
	Template.AbilityCharges.InitialCharges = 1;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	return Template;
}

static function X2AbilityTemplate ChosenWatchful()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    Trigger;
	local X2Effect_Persistent               VigilantEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenWatchful');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_freeoverwatch";
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'PlayerTurnEnded';
	Trigger.ListenerData.Filter = eFilter_Player;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.ChosenWatchfulListener;
	Template.AbilityTriggers.AddItem(Trigger);

	VigilantEffect = new class'X2Effect_Persistent';
	VigilantEffect.EffectName = 'ChosenWatchful';
	VigilantEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	Template.AddShooterEffect(VigilantEffect);

	Template.ChosenTraitType = 'General';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenKineticPlating()
{
	local X2AbilityTemplate			Template;
	local X2Effect_KineticPlating	PlatingEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenKineticPlating');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_kineticplating";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PlatingEffect = new class'X2Effect_KineticPlating';
	PlatingEffect.AddPersistentStatChange(eStat_ShieldHP, default.KINETIC_PLATING_MAX);
	PlatingEffect.ShieldPerMiss = default.KINETIC_PLATING_PER_MISS;
	PlatingEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(PlatingEffect);

	Template.ChosenTraitType = 'General';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenBrutal()
{
	local X2AbilityTemplate			Template;
	local X2AbilityTrigger_EventListener    Trigger;
	local X2Effect_Brutal			BrutalEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenBrutal');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_taxing";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.ChosenBrutalListener;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AbilityMultiTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityMultiTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	
	BrutalEffect = new class'X2Effect_Brutal';
	BrutalEffect.WillMod = default.BRUTAL_WILL_MOD;
	Template.AddTargetEffect(BrutalEffect);
	Template.AddMultiTargetEffect(BrutalEffect);

	Template.ChosenTraitType = 'General';

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate ChosenHoloTargeting()
{
	local X2AbilityTemplate             Template;
	local X2Effect_Persistent           PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenHoloTargeting');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_holotargeting";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	//  This is a dummy effect so that an icon shows up in the UI.
	//  Shot and Suppression abilities make use of HoloTargetEffect().
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(1, true, true);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(PersistentEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!
	
	return Template;
}

static function X2Effect_HoloTarget HoloTargetEffect()
{
	local X2Effect_HoloTarget           Effect;
	local X2Condition_AbilityProperty   AbilityCondition;
	local X2AbilityTag                  AbilityTag;

	Effect = new class'X2Effect_HoloTarget';
	Effect.EffectName = 'ChosenHoloTarget';
	Effect.HitMod = default.HOLOTARGET_BONUS;
	Effect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.bRemoveWhenTargetDies = true;
	Effect.bUseSourcePlayerState = true;

	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = Effect;

	Effect.SetDisplayInfo(ePerkBuff_Penalty, default.HoloTargetEffectName, `XEXPAND.ExpandString(default.HoloTargetEffectDesc), "img:///UILibrary_XPACK_Common.PerkIcons.str_holotargeting", true);

	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('ChosenHoloTargeting');
	Effect.TargetConditions.AddItem(AbilityCondition);

	// bsg-dforrest (7.27.17): need to clear out ParseObject
	AbilityTag.ParseObj = none;
	// bsg-dforrest (7.27.17): end

	return Effect;
}

static function X2AbilityTemplate ChosenAgile()
{
	local X2AbilityTemplate					Template;
	local X2AbilityToHitCalc_PercentChance	ToHit;
	local X2Effect_RunBehaviorTree			TreeEffect;
	local X2AbilityTrigger_EventListener	EventListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenAgile');

	ToHit = new class'X2AbilityToHitCalc_PercentChance';
	ToHit.PercentToHit = default.AGILE_CHANCE;
	ToHit.bNoGameStateOnMiss = true;
	Template.AbilityToHitCalc = ToHit;

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChosenAgileListener;
	EventListener.ListenerData.EventID = 'AbilityActivated';
	EventListener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AbilityTargetStyle = default.SelfTarget;
	
	TreeEffect = new class'X2Effect_RunBehaviorTree';
	TreeEffect.BehaviorTreeName = 'TryAgileMove';
	Template.AddTargetEffect(TreeEffect);

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_agile";
	Template.Hostility = eHostility_Defensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.ChosenTraitType = 'Survivability';
	Template.ChosenExcludeTraits.AddItem('ChosenDamagedTeleport');

	return Template;
}

static function X2AbilityTemplate ChosenSoulstealer()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    EventListener;
	local X2Condition_UnitProperty          ShooterProperty;
	local X2Effect_SoulSteal                StealEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenSoulstealer');

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.str_soulstealer";
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';

	ShooterProperty = new class'X2Condition_UnitProperty';
	ShooterProperty.ExcludeAlive = false;
	ShooterProperty.ExcludeDead = true;
	ShooterProperty.ExcludeFriendlyToSource = false;
	ShooterProperty.ExcludeHostileToSource = true;
	ShooterProperty.ExcludeFullHealth = true;
	Template.AbilityShooterConditions.AddItem(ShooterProperty);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChosenSoulStealListener;
	EventListener.ListenerData.EventID = 'UnitTakeEffectDamage';
	EventListener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(EventListener);

	StealEffect = new class'X2Effect_SoulSteal';
	StealEffect.UnitValueToRead = default.SoulstealUnitValue;
	Template.AddShooterEffect(StealEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	Template.ChosenTraitType = 'Survivability';
	Template.ChosenExcludeTraits.AddItem('ChosenRegenerate');

	return Template;
}

// Strengths/Weaknesses

// Weaknesses
static function X2AbilityTemplate ChosenAchilles()
{
	local X2AbilityTemplate		Template;
	local X2Effect_Achilles		TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenAchilles');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.weak_achilles";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_Achilles';
	TargetEffect.ToHitMin = default.ACHILLES_TO_HIT;
	TargetEffect.DmgMod = default.ACHILLES_DMG_MOD;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenNearsighted()
{
	local X2AbilityTemplate		Template;
	local X2Effect_Nearsighted	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenNearsighted');

	Template.IconImage = "img:///UILibrary_XPACK_Common.weak_nearsighted";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_Nearsighted';
	TargetEffect.DmgMod = default.NEARSIGHTED_DMG_MOD;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenBewildered()
{
	local X2AbilityTemplate		Template;
	local X2Effect_Bewildered	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenBewildered');

	Template.IconImage = "img:///UILibrary_XPACK_Common.weak_bewildered";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_Bewildered';
	TargetEffect.DmgMod = default.BEWILDERED_DMG_MOD;
	TargetEffect.NumHitsForMod = default.BEWILDERED_NUM_HITS;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenReaperAdversary()
{
	local X2AbilityTemplate		Template;
	local X2Effect_AdverseSoldierClasses	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenReaperAdversary');

	Template.IconImage = "img:///UILibrary_XPACK_Common.weak_adversaryreaper";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_AdverseSoldierClasses';
	TargetEffect.AdverseClasses.AddItem('Reaper');
	TargetEffect.DmgMod = default.ADVERSARY_REAPER_DMG_MOD;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);

	Template.ChosenTraitType = 'Adversary';
	Template.ChosenExcludeTraits.AddItem('ChosenAllSeeing');
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenSkirmisherAdversary()
{
	local X2AbilityTemplate		Template;
	local X2Effect_AdverseSoldierClasses	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenSkirmisherAdversary');

	Template.IconImage = "img:///UILibrary_XPACK_Common.weak_adversaryskirmisher";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_AdverseSoldierClasses';
	TargetEffect.AdverseClasses.AddItem('Skirmisher');
	TargetEffect.DmgMod = default.ADVERSARY_SKIRMISHER_DMG_MOD;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);

	Template.ChosenTraitType = 'Adversary';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenTemplarAdversary()
{
	local X2AbilityTemplate		Template;
	local X2Effect_AdverseSoldierClasses	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenTemplarAdversary');

	Template.IconImage = "img:///UILibrary_XPACK_Common.weak_adversarytemplar";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_AdverseSoldierClasses';
	TargetEffect.AdverseClasses.AddItem('Templar');
	TargetEffect.DmgMod = default.ADVERSARY_TEMPLAR_DMG_MOD;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);

	Template.ChosenTraitType = 'Adversary';
	Template.ChosenExcludeTraits.AddItem('ChosenImmuneMelee');
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenImpatient()
{
	local X2AbilityTemplate		Template;
	local X2Effect_Impatient	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenImpatient');

	Template.IconImage = "img:///UILibrary_XPACK_Common.weak_impatient";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_Impatient';
	TargetEffect.DmgMod = default.IMPATIENT_DMG_MOD;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenOblivious()
{
	local X2AbilityTemplate		Template;
	local X2Effect_Oblivious	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenOblivious');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.weak_oblivious";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_Oblivious';
	TargetEffect.DmgMod = default.OBLIVIOUS_DMG_MOD;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);
	
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate ChosenGroundling()
{
	local X2AbilityTemplate		Template;
	local X2Effect_Groundling	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenGroundling');

	Template.IconImage = "img:///UILibrary_XPACK_Common.weak_groundling";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	TargetEffect = new class'X2Effect_Groundling';
	TargetEffect.HeightBonus = default.GROUNDLING_MOD;
	TargetEffect.BuildPersistentEffect(1, true, false, false);
	TargetEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage);
	Template.AddTargetEffect(TargetEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2DataTemplate CreateChosenBrittle()
{
	local X2AbilityTemplate Template;
	local X2Effect_TargetDamageDistanceBonus BonusDamage;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenBrittle');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.weak_weaktocloserange";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	BonusDamage = new class'X2Effect_TargetDamageDistanceBonus';
	BonusDamage.EffectName = 'ChosenBrittle';
	BonusDamage.BuildPersistentEffect(1, true, false, true);
	BonusDamage.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	BonusDamage.DuplicateResponse = eDupe_Ignore;
	BonusDamage.BonusDmg = default.BRITTLE_BONUS_MOD;
	BonusDamage.BonusModType = MODOP_Multiplication;
	BonusDamage.WithinTileDistance = default.BRITTLE_WITHIN_DISTANCE;
	BonusDamage.bPrimaryTargetOnly = true;
	Template.AddTargetEffect(BonusDamage);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.AbilityRevealEvent = 'UnitTakeEffectDamage';
	Template.ShouldRevealChosenTraitFn = ShouldReveal_OnUnitTakeEffectDamage;

	return Template;
}

function bool ShouldReveal_OnUnitTakeEffectDamage(Object EventData, Object EventSource, XComGameState GameState, Object CallbackData)
{
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit DamageeUnit;
	local int Index;
	local int EffectID;
	local XComGameStateHistory History;
	local XComGameState_Effect SpecialDamageEffectState;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_Persistent PersistentEffect;

	DamageeUnit = XComGameState_Unit(EventData);
	AbilityState = XComGameState_Ability(CallbackData);

	// reveal if the Chosen who owns this ability received the damage
	if( AbilityState.OwnerStateObject.ObjectID == DamageeUnit.ObjectID && DamageeUnit.DamageResults.Length > 0 )
	{
		AbilityTemplate = AbilityState.GetMyTemplate();

		if( AbilityTemplate.AbilityTargetEffects.Length > 0 )
		{
			PersistentEffect = X2Effect_Persistent(AbilityTemplate.AbilityTargetEffects[0]);

			if( PersistentEffect != None )
			{
				History = `XCOMHISTORY;

				// ... and if the last hit contained special damage of type 'ChosenBrittle'
				for( Index = 0; Index < DamageeUnit.DamageResults[DamageeUnit.DamageResults.Length - 1].SpecialDamageFactors.Length; ++Index )
				{
					EffectID = DamageeUnit.DamageResults[DamageeUnit.DamageResults.Length - 1].SpecialDamageFactors[Index].SourceID;

					SpecialDamageEffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectID));

					if( SpecialDamageEffectState != None && SpecialDamageEffectState.GetX2Effect().EffectName == PersistentEffect.EffectName )
					{
						return true;
					}
				}
			}
		}
	}

	return false;
}

static function X2DataTemplate CreateChosenSlow()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent SlowEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChosenSlow');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_slow";
	Template.Hostility = eHostility_Neutral;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	SlowEffect = new class'X2Effect_Persistent';
	SlowEffect.EffectName = 'ChosenSlow';
	SlowEffect.BuildPersistentEffect(1, true, false, true);
	SlowEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	SlowEffect.DuplicateResponse = eDupe_Ignore;
	SlowEffect.EffectAddedFn = ChosenSlow_AddedFn;
	Template.AddTargetEffect(SlowEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.AbilityRevealEvent = 'AbilityActivated';
	Template.ShouldRevealChosenTraitFn = ShouldReveal_OnChosenEngaged;

	return Template;
}

static function ChosenSlow_AddedFn(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit ChosenState;
	
	ChosenState = XComGameState_Unit(kNewTargetState);
	ChosenState.ActivationThreshold += default.SLOW_ACTIVATION_THRESHOLD_CHANGE;
}

function bool ShouldReveal_OnChosenEngaged(Object EventData, Object EventSource, XComGameState GameState, Object CallbackData)
{
	local XComGameState_Ability AbilityState, InstigatingAbilityState;
	local XComGameState_Unit SourceUnitState;

	InstigatingAbilityState = XComGameState_Ability(EventData);
	SourceUnitState = XComGameState_Unit(EventSource);
	AbilityState = XComGameState_Ability(CallbackData);

	// reveal if the Chosen who owns this ability received the damage
	if( AbilityState.OwnerStateObject.ObjectID == SourceUnitState.ObjectID && InstigatingAbilityState.GetMyTemplateName() == 'ChosenEngaged' )
	{
		return true;
	}

	return false;
}

static function X2DataTemplate CreateWeakAbility(name WeakAbilityName, string WeakAbilityIcon, array<name> BonusDamageTypes, int BonusDamageMultiplyer)
{
	local X2AbilityTemplate Template;
	local X2Effect_TargetDamageTypeBonus VunerableDamage;

	`CREATE_X2ABILITY_TEMPLATE(Template, WeakAbilityName);

	Template.IconImage = WeakAbilityIcon;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDontDisplayInAbilitySummary = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	VunerableDamage = new class'X2Effect_TargetDamageTypeBonus';
	VunerableDamage.EffectName = WeakAbilityName;
	VunerableDamage.BuildPersistentEffect(1, true, false, true);
	VunerableDamage.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	VunerableDamage.DuplicateResponse = eDupe_Ignore;
	VunerableDamage.BonusDmg = BonusDamageMultiplyer;
	VunerableDamage.BonusModType = MODOP_Multiplication;
	VunerableDamage.BonusDamageTypes = BonusDamageTypes;
	Template.AddTargetEffect(VunerableDamage);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.AbilityRevealEvent = 'UnitTakeEffectDamage';
	Template.ShouldRevealChosenTraitFn = ShouldReveal_OnUnitTakeEffectDamage;

	return Template;
}

static function X2DataTemplate CreateWeakExplosionAbility(name WeakAbilityName, string WeakAbilityIcon, array<name> BonusDamageTypes, int BonusDamageMultiplyer)
{
	local X2AbilityTemplate Template;

	Template = X2AbilityTemplate(CreateWeakAbility(WeakAbilityName, WeakAbilityIcon, BonusDamageTypes, BonusDamageMultiplyer));
	Template.ChosenExcludeTraits.AddItem('BlastShield');
	return Template;
}
// Weaknesses

defaultproperties
{
	KidnapMarkSourceEffectName="KidnapMarkSourceEffect"
	KidnapMarkTargetEffectName="KidnapMarkTargetEffect"
	ExtractKnowledgeMarkSourceEffectName="ExtractKnowledgeMarkSourceEffect"
	ExtractKnowledgeMarkTargetEffectName="ExtractKnowledgeMarkTargetEffect"
	SoulstealUnitValue="ChosenSoulsteal"
}
