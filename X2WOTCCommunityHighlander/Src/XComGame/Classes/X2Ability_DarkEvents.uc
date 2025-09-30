class X2Ability_DarkEvents extends X2Ability
	config(GameCore);

var config int DARK_EVENT_BENDING_REED_CHANCE;
var config int DARK_EVENT_UNDYING_LOYALTY_CHANCE;
var config float DARK_EVENT_BARRIER_BONUS_SCALAR;
var config int DARK_EVENT_COUNTERATTACK_CHANCE;

var localized string UndyingLoyaltyFlyoverText;
var localized string BarrierFriendlyName;
var localized string BarrierFriendlyDesc;
var localized string SealedArmorFriendlyName;
var localized string SealedArmorFriendlyDesc;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(DarkEventAbility_LightningReflexes());
	Templates.AddItem(DarkEventAbility_ReturnFire());
	Templates.AddItem(DarkEventAbility_BendingReed());
	Templates.AddItem(DarkEventAbility_SealedArmor());
	Templates.AddItem(DarkEventAbility_UndyingLoyalty());
	Templates.AddItem(DarkEventAbility_Barrier());
	Templates.AddItem(DarkEventAbility_Counterattack());

	// additional abilities needed for unique visualization flyovers
	Templates.AddItem(DarkEventAbility_PistolReturnFire());
	Templates.AddItem(DarkEventAbility_Overwatch());

	return Templates;
}

static function X2AbilityTemplate DarkEventAbility_LightningReflexes()
{
	local X2AbilityTemplate						Template;
	local X2Condition_GameplayTag				GameplayCondition;

	Template = class'X2Ability_AdvancedWarfareCenter'.static.LightningReflexes('DarkEventAbility_LightningReflexes');

	GameplayCondition = new class'X2Condition_GameplayTag';
	GameplayCondition.RequiredGameplayTag = 'DarkEvent_LightningReflexes';
	Template.AbilityShooterConditions.AddItem(GameplayCondition);

	return Template;
}

static function X2AbilityTemplate DarkEventAbility_ReturnFire()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_ReturnFire                   FireEffect;
	local X2Condition_GameplayTag				GameplayCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DarkEventAbility_ReturnFire');
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
	FireEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	FireEffect.bOnlyWhenAttackMisses = true;
	FireEffect.AbilityToActivate = 'DarkEventAbility_PistolReturnFire';
	Template.AddTargetEffect(FireEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.bCrossClassEligible = true;

	GameplayCondition = new class'X2Condition_GameplayTag';
	GameplayCondition.RequiredGameplayTag = 'DarkEvent_ReturnFire';
	Template.AbilityShooterConditions.AddItem(GameplayCondition);

	Template.AdditionalAbilities.AddItem('DarkEventAbility_PistolReturnFire');

	return Template;
}

static function X2AbilityTemplate DarkEventAbility_PistolReturnFire()
{
	local X2AbilityTemplate Template;

	Template = class'X2Ability_DefaultAbilitySet'.static.PistolReturnFire('DarkEventAbility_PistolReturnFire');
	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;

	return Template;
}

static function X2AbilityTemplate DarkEventAbility_BendingReed()
{
	local X2AbilityTemplate						Template;
	local X2AbilityToHitCalc_PercentChance		HitChance;
	local X2AbilityTrigger_EventListener		EventListener;
	local X2Condition_GameplayTag				GameplayCondition;

	Template = class'X2Ability_ChosenAssassin'.static.CreateBendingReed( 'DarkEventAbility_BendingReed' );

	// change the ToHitCalc from what BendingReed does by default
	HitChance = new class'X2AbilityToHitCalc_PercentChance';
	HitChance.PercentToHit = default.DARK_EVENT_BENDING_REED_CHANCE;
	HitChance.bNoGameStateOnMiss = true;
	Template.AbilityToHitCalc = HitChance;

	// Remove any existing ability triggers and replace with an trigger on the StunLancer's StunLance ability
	Template.AbilityTriggers.Length = 0;
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.EventID = 'StunLanceActivated';
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	GameplayCondition = new class'X2Condition_GameplayTag';
	GameplayCondition.RequiredGameplayTag = 'DarkEvent_BendingReed';
	Template.AbilityShooterConditions.AddItem(GameplayCondition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bShowActivation = true;

	return Template;
}

static function X2AbilityTemplate DarkEventAbility_SealedArmor()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTarget_Self					TargetStyle;
	local X2AbilityTrigger_UnitPostBeginPlay	Trigger;
	local X2Condition_GameplayTag				GameplayCondition;
	local X2Effect_DamageImmunity				ImmunityEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DarkEventAbility_SealedArmor');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	GameplayCondition = new class'X2Condition_GameplayTag';
	GameplayCondition.RequiredGameplayTag = 'DarkEvent_SealedArmor';
	Template.AbilityShooterConditions.AddItem(GameplayCondition);

	ImmunityEffect = new class'X2Effect_DamageImmunity';
	ImmunityEffect.ImmuneTypes.AddItem( 'Frost' );
	ImmunityEffect.ImmuneTypes.AddItem( 'Fire' );
	ImmunityEffect.ImmuneTypes.AddItem( 'Poison' );
	ImmunityEffect.SetDisplayInfo(ePerkBuff_Bonus, default.SealedArmorFriendlyName, default.SealedArmorFriendlyDesc, "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_sealedarmor", , , Template.AbilitySourceName);
	Template.AddTargetEffect(ImmunityEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate DarkEventAbility_UndyingLoyalty( )
{
	local X2AbilityTemplate						Template;
	local X2AbilityTarget_Self					TargetStyle;
	local X2AbilityToHitCalc_PercentChance		HitChance;
	local X2AbilityTrigger_EventListener		EventListener;
	local X2Condition_GameplayTag				GameplayCondition;
	local X2Effect_SpawnPsiZombie				SwitchToZombieEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DarkEventAbility_UndyingLoyalty');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	HitChance = new class'X2AbilityToHitCalc_PercentChance';
	HitChance.PercentToHit = default.DARK_EVENT_UNDYING_LOYALTY_CHANCE;
	HitChance.bNoGameStateOnMiss = true;
	Template.AbilityToHitCalc = HitChance;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.EventID = 'UnitDied';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.Priority = 45;  //This ability must get triggered after the rest of the on-death listeners (namely, after mind-control effects get removed)
	Template.AbilityTriggers.AddItem(EventListener);

	GameplayCondition = new class'X2Condition_GameplayTag';
	GameplayCondition.RequiredGameplayTag = 'DarkEvent_UndyingLoyalty';
	Template.AbilityShooterConditions.AddItem(GameplayCondition);

	// The target will now be turned into a robot
	SwitchToZombieEffect = new class'X2Effect_SpawnPsiZombie';
	SwitchToZombieEffect.BuildPersistentEffect(1);
	SwitchToZombieEffect.ZombieFlyoverText = default.UndyingLoyaltyFlyoverText;
	Template.AddTargetEffect(SwitchToZombieEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = SwitchPsiZombie_BuildVisualization;
	Template.MergeVisualizationFn = SwitchPsiZombie_VisualizationMerge;

	return Template;
}

simulated function SwitchPsiZombie_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability Context;
	local XComGameStateHistory History;
	local VisualizationActionMetadata EmptyTrack, SpawnedUnitTrack, DeadUnitTrack;
	local XComGameState_Unit SpawnedUnit, DeadUnit;
	local UnitValue SpawnedUnitValue;
	local X2Effect_SpawnPsiZombie SwitchToZombieEffect;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	History = `XCOMHISTORY;

	DeadUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	`assert(DeadUnit != none);

	DeadUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);

	// The Spawned unit should appear and play its change animation
	DeadUnitTrack = EmptyTrack;
	DeadUnitTrack.StateObject_OldState = DeadUnit;
	DeadUnitTrack.StateObject_NewState = DeadUnitTrack.StateObject_OldState;
	DeadUnitTrack.VisualizeActor = History.GetVisualizer(DeadUnit.ObjectID);

	// The Spawned unit should appear and play its change animation
	SpawnedUnitTrack = EmptyTrack;
	SpawnedUnitTrack.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	SpawnedUnitTrack.StateObject_NewState = SpawnedUnitTrack.StateObject_OldState;
	SpawnedUnit = XComGameState_Unit(SpawnedUnitTrack.StateObject_NewState);
	`assert(SpawnedUnit != none);
	SpawnedUnitTrack.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

	// Only first target effect is X2Effect_SwitchToRobot
	SwitchToZombieEffect = X2Effect_SpawnPsiZombie(Context.ResultContext.TargetEffectResults.Effects[0]);

	if( SwitchToZombieEffect == none )
	{
		// This can happen due to replays. In replays, when moving Context visualizations forward the Context has not
		// been fully filled in.
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();
		SwitchToZombieEffect = X2Effect_SpawnPsiZombie(AbilityTemplate.AbilityTargetEffects[0]);
	}

	if( SwitchToZombieEffect == none )
	{
		`RedScreenOnce("SwitchPsiZombie_BuildVisualization: Missing X2Effect_SpawnPsiZombie @gameplay");
	}
	else
	{
		SwitchToZombieEffect.AddSpawnVisualizationsToTracks(Context, SpawnedUnit, SpawnedUnitTrack, DeadUnit, DeadUnitTrack);
	}
}

static function SwitchPsiZombie_VisualizationMerge(X2Action BuildTree, out X2Action VisualizationTree)
{
	local X2Action_Death DeathAction;		
	local X2Action BuildTreeStartNode, BuildTreeEndNode;	
	local XComGameStateVisualizationMgr LocalVisualizationMgr;

	LocalVisualizationMgr = `XCOMVISUALIZATIONMGR;

	DeathAction = X2Action_Death(LocalVisualizationMgr.GetNodeOfType(VisualizationTree, class'X2Action_Death'));
	BuildTreeStartNode = LocalVisualizationMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin');	
	BuildTreeEndNode = LocalVisualizationMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd');	
	LocalVisualizationMgr.InsertSubtree(BuildTreeStartNode, BuildTreeEndNode, DeathAction);
}

static function X2AbilityTemplate DarkEventAbility_Barrier()
{
	local X2AbilityTemplate						Template;
	local X2Condition_GameplayTag				GameplayCondition;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_PersistentStatChange			DefenseChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DarkEventAbility_Barrier');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	DefenseChangeEffect = new class'X2Effect_PersistentStatChange';
	DefenseChangeEffect.BuildPersistentEffect(1, true, false, true);
	DefenseChangeEffect.AddPersistentStatChange(eStat_HackDefense, default.DARK_EVENT_BARRIER_BONUS_SCALAR, MODOP_Multiplication);
	DefenseChangeEffect.AddPersistentStatChange(eStat_Will, default.DARK_EVENT_BARRIER_BONUS_SCALAR, MODOP_Multiplication);
	DefenseChangeEffect.SetDisplayInfo(ePerkBuff_Bonus, default.BarrierFriendlyName, default.BarrierFriendlyDesc, "UILibrary_XPACK_Common.PerkIcons.UIPerk_barrierdarkevent");
	DefenseChangeEffect.DuplicateResponse = eDupe_Ignore;

	Template.AddTargetEffect( DefenseChangeEffect );

	GameplayCondition = new class'X2Condition_GameplayTag';
	GameplayCondition.RequiredGameplayTag = 'DarkEvent_Barrier';
	Template.AbilityShooterConditions.AddItem(GameplayCondition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate DarkEventAbility_Counterattack()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTarget_Self					TargetStyle;
	local X2AbilityToHitCalc_PercentChance		HitChance;
	local X2Condition_GameplayTag				GameplayCondition;
	local X2Effect_ImmediateAbilityActivation	OverwatchActivation;
	local X2Effect_GrantActionPoints			ActionPointsEffect;
	local X2Condition_UnitProperty				AdventCondition;
	local X2Condition_UnitType					AdventExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DarkEventAbility_Counterattack');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	HitChance = new class'X2AbilityToHitCalc_PercentChance';
	HitChance.PercentToHit = default.DARK_EVENT_COUNTERATTACK_CHANCE;
	HitChance.bNoGameStateOnMiss = true;
	Template.AbilityToHitCalc = HitChance;

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	GameplayCondition = new class'X2Condition_GameplayTag';
	GameplayCondition.RequiredGameplayTag = 'DarkEvent_Counterattack';
	Template.AbilityShooterConditions.AddItem(GameplayCondition);

	// Only advent AI.
	AdventCondition = new class'X2Condition_UnitProperty';
	AdventCondition.IsAdvent = true;
	Template.AbilityShooterConditions.AddItem(AdventCondition);

	// Exclude purifier and MEC.
	AdventExclusions = new class'X2Condition_UnitType';
	AdventExclusions.ExcludeTypes.AddItem('AdventPurifier');
	AdventExclusions.ExcludeTypes.AddItem('AdventMEC');
	Template.AbilityShooterConditions.AddItem(AdventExclusions);

	OverwatchActivation = new class'X2Effect_ImmediateAbilityActivation';
	OverwatchActivation.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	OverwatchActivation.EffectName = 'ImmediateOverwatch';
	OverwatchActivation.AbilityName = 'DarkEventAbility_Overwatch';
	OverwatchActivation.bRemoveWhenTargetDies = true;
	Template.AddTargetEffect(OverwatchActivation);

	// The shooter gets a free point that can be used to overwatch
	ActionPointsEffect = new class'X2Effect_GrantActionPoints';
	ActionPointsEffect.NumActionPoints = 1;
	ActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	Template.AddShooterEffect(ActionPointsEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.AdditionalAbilities.AddItem('DarkEventAbility_Overwatch');

	return Template;
}

static function X2AbilityTemplate DarkEventAbility_Overwatch()
{
	local X2AbilityTemplate Template;

	Template = class'X2Ability_DefaultAbilitySet'.static.AddOverwatchAbility('DarkEventAbility_Overwatch');

	return Template;
}