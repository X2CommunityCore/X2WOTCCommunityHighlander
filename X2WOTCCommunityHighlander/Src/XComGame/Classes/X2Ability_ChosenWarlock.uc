//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_ChosenWarlock extends X2Ability
	config(GameData_SoldierSkills);

var const config int WARLOCKLEVEL_M1;
var const config int WARLOCKLEVEL_M2;
var const config int WARLOCKLEVEL_M3;
var const config int WARLOCKLEVEL_M4;
var const config int CORRUPT_ACTIONPOINTCOST;
var const config int CORRUPT_COOLDOWN_LOCAL;
var const config int CORRUPT_COOLDOWN_GLOBAL;
var const config int MINDSCORCH_ACTIONPOINTCOST;
var const config int MINDSCORCH_COOLDOWN_LOCAL;
var const config int MINDSCORCH_COOLDOWN_GLOBAL;
var const config int MINDSCORCH_DISORIENTED_MAX_ALLOWED;
var const config int MINDSCORCH_STUNNED_MAX_ALLOWED;
var const config int MINDSCORCH_UNCONSCIOUS_MAX_ALLOWED;
var const config int MINDSCORCH_DAZE1_TURNS;
var const config int MINDSCORCH_DAZE2_TURNS;
var const config int POSSESS_ACTIONPOINTCOST;
var const config int POSSESS_COOLDOWN_LOCAL;
var const config int POSSESS_COOLDOWN_GLOBAL;
var const config int SPECTRALARMY_ACTIONPOINTCOST;
var const config int SPECTRALARMY_COOLDOWN_LOCAL;
var const config int SPECTRALARMY_COOLDOWN_GLOBAL;
var const config int SPECTRALARMY_NUM_TURNS;
var const config float SPECTRALARMY_STOP_BLEND_TIME_S;
var const config int TELEPORTALLY_ACTIONPOINTCOST;
var const config int TELEPORTALLY_COOLDOWN_LOCAL;
var const config int TELEPORTALLY_COOLDOWN_GLOBAL;
var const config float TELEPORTALLY_IN_DELAY;
var const config float PSI_DEATH_EXPLOSION_RADIUS_METERS;
var const config int PSI_EXPLOSION_ENV_DMG;
var const config int CORRESS_ACTIONPOINTCOST;
var const config int CORRESS_COOLDOWN_LOCAL;
var const config int CORRESS_COOLDOWN_GLOBAL;
var const config float CORRESS_LOOKAT_DURATION;
var const config int SPECTRALARMY_IMPAIR_DAZE1_TURNS;
var const config int SPECTRALARMY_IMPAIR_DAZE2_TURNS;

var privatewrite name SpectralArmyLinkName;
var privatewrite name SpawnSpectralArmyRemovedTriggerName;
var privatewrite name SpectralArmyLinkRemovedTriggerName;
var privatewrite name SpectralArmyImpairingAbilityName;
var privatewrite name PsiSelfDestructEffectName;
var privatewrite name SpectralZombieLinkName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	// Each level of Warlock gets its own WarlockLevel effect
	Templates.AddItem(CreateWarlockLevel('WarlockLevelM1', default.WARLOCKLEVEL_M1));
	Templates.AddItem(CreateWarlockLevel('WarlockLevelM2', default.WARLOCKLEVEL_M2));
	Templates.AddItem(CreateWarlockLevel('WarlockLevelM3', default.WARLOCKLEVEL_M3));
	Templates.AddItem(CreateWarlockLevel('WarlockLevelM4', default.WARLOCKLEVEL_M4));
	Templates.AddItem(CreateWarlockFocus());

	Templates.AddItem(CreateCorrupt());
	Templates.AddItem(CreateMindScorch());
	Templates.AddItem(CreatePossess());
	Templates.AddItem(CreateSpectralArmy('SpectralArmy', 'SpectralStunLancerM1'));
	Templates.AddItem(CreateSpectralArmy('SpectralArmyM2', 'SpectralStunLancerM2'));
	Templates.AddItem(CreateSpectralArmy('SpectralArmyM3', 'SpectralStunLancerM3'));
	Templates.AddItem(CreateSpectralArmy('SpectralArmyM4', 'SpectralStunLancerM4'));
	Templates.AddItem(CreateSpectralArmyLink());
	Templates.AddItem(CreateEndSpectralArmy());
	Templates.AddItem(CreateTeleportAlly());
	Templates.AddItem(CreateCorress('Corress', 'SpectralZombieM1'));
	Templates.AddItem(CreateCorress('CorressM2', 'SpectralZombieM2'));
	Templates.AddItem(CreateCorress('CorressM3', 'SpectralZombieM3'));
	Templates.AddItem(CreateCorress('CorressM4', 'SpectralZombieM4'));
	Templates.AddItem(CreateRemoveSpectralZombies());

	Templates.AddItem(CreateSpectralArmyUnitInitialize());
	Templates.AddItem(CreateSpectralZombieInitialize());

	Templates.AddItem(class'X2Ability_Sectoid'.static.AddLinkedEffectAbility(default.SpectralZombieLinkName, default.SpectralZombieLinkName, none));

	Templates.AddItem(CreateEngagePsiSelfDestruct());
	Templates.AddItem(CreateTriggerPsiSelfDestruct());
	Templates.AddItem(ExplodingPsiInit());
	Templates.AddItem(PsiDeathExplosion());

	Templates.AddItem(CreateSpectralArmLanceAbility());
	Templates.AddItem(CreateSpectralArmyImpairingEffectAbility());
	
	return Templates;
}

static function X2AbilityTemplate CreateWarlockLevel(name AbilityName, int FocusLevel)
{
	local X2AbilityTemplate Template;
	local X2Effect_ModifyTemplarFocus FocusEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_templarFocus";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Template.AddTargetEffect(new class'X2Effect_TemplarFocus');

	FocusEffect = new class'X2Effect_ModifyTemplarFocus';
	FocusEffect.ModifyFocus = FocusLevel;
	Template.AddTargetEffect(FocusEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!

	return Template;
}

static function X2AbilityTemplate CreateWarlockFocus()
{
	return PurePassive('WarlockFocusM4', , , 'eAbilitySource_Psionic', false);
}

static function X2DataTemplate CreateCorrupt()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_UnitValue UnitValue;
	local X2Effect_SpawnPsiZombie SpawnZombieEffect;
	local X2Effect_KillUnit KillUnitEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Corrupt');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Corrupt";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	Template.AdditionalAbilities.AddItem('KillSiredZombies');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.CORRUPT_ACTIONPOINTCOST;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.CORRUPT_COOLDOWN_LOCAL;
	Cooldown.NumGlobalTurns = default.CORRUPT_COOLDOWN_GLOBAL;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	//
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Target Conditions
	//
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeNonCivilian = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	// This effect is only valid if the target has not yet been turned into a zombie
	UnitValue = new class'X2Condition_UnitValue';
	UnitValue.AddCheckValue(class'X2Effect_SpawnPsiZombie'.default.TurnedZombieName, 1, eCheck_LessThan);
	Template.AbilityTargetConditions.AddItem(UnitValue);

	KillUnitEffect = new class'X2Effect_KillUnit';
	KillUnitEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	KillUnitEffect.DeathActionClass = class'X2Action_CorruptDeath';
	KillUnitEffect.bPersistThroughTacticalGameEnd = true;
	Template.AddTargetEffect(KillUnitEffect);

	// DO NOT CHANGE THE ORDER OF THE KILL EFFECT AND THIS EFFECT
	// Apply this effect to the target if it died
	SpawnZombieEffect = new class'X2Effect_SpawnPsiZombie';
	SpawnZombieEffect.BuildPersistentEffect(1);
	SpawnZombieEffect.DamageTypes.AddItem('psi');
	SpawnZombieEffect.AnimationName = 'HL_ResurrectRise';
	Template.AddTargetEffect(SpawnZombieEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Corrupt_BuildVisualization;

//BEGIN AUTOGENERATED CODE: Template Overrides 'Corrupt'
	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CustomFireAnim = 'HL_Corrupt';
	Template.CinescriptCameraType = "ChosenWarlock_Corrupt";
//END AUTOGENERATED CODE: Template Overrides 'Corrupt'

	//	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MeleeLostSpawnIncreasePerUse;

	return Template;
}

simulated function Corrupt_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local StateObjectReference InteractingUnitRef;

	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata SourceTrack, BuildTrack, ZombieTrack;
	local XComGameState_Unit SpawnedUnit, DeadUnit;
	local UnitValue SpawnedUnitValue;
	local X2Effect_SpawnPsiZombie SpawnPsiZombieEffect;
	local int j;
	local name SpawnPsiZombieEffectResult;
	local X2VisualizerInterface TargetVisualizerInterface;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local X2Action FireAction, DeathAction, ExitCoverAction;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	SourceTrack = EmptyTrack;
	SourceTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	SourceTrack.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	// Trigger the Chosen's narrative line for the ability
	class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'AttackBegin');

	ExitCoverAction = class'X2Action_ExitCover'.static.AddToVisualizationTree(SourceTrack, Context);

	//If we were interrupted, insert a marker node for the interrupting visualization code to use. In the move path version above, it is expected for interrupts to be 
	//done during the move.
	if (Context.InterruptionStatus != eInterruptionStatus_None)
	{
		//Insert markers for the subsequent interrupt to insert into
		class'X2Action'.static.AddInterruptMarkerPair(SourceTrack, Context, ExitCoverAction);
	}

	FireAction = class'X2Action_Fire'.static.AddToVisualizationTree(SourceTrack, Context);
	class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceTrack, Context);

	// Configure the visualization track for the psi zombie
	//******************************************************************************************
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(BuildTrack, Context, false, FireAction);

	for (j = 0; j < Context.ResultContext.TargetEffectResults.Effects.Length; ++j)
	{
		SpawnPsiZombieEffect = X2Effect_SpawnPsiZombie(Context.ResultContext.TargetEffectResults.Effects[j]);
		SpawnPsiZombieEffectResult = 'AA_UnknownError';

		if (SpawnPsiZombieEffect != none)
		{
			SpawnPsiZombieEffectResult = Context.ResultContext.TargetEffectResults.ApplyResults[j];
		}
		else
		{
			// Target effect visualization
			Context.ResultContext.TargetEffectResults.Effects[j].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.ResultContext.TargetEffectResults.ApplyResults[j]);

			// Source effect visualization
			Context.ResultContext.TargetEffectResults.Effects[j].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceTrack, Context.ResultContext.TargetEffectResults.ApplyResults[j]);
		}
	}

	TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.VisualizeActor);
	if (TargetVisualizerInterface != none)
	{
		//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
		TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
	}

	if (SpawnPsiZombieEffectResult == 'AA_Success')
	{
		DeadUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID));
		`assert(DeadUnit != none);
		DeadUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);

		// Find Death, put in a wait with Death as Parent, continue
		DeathAction = VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_CorruptDeath', BuildTrack.VisualizeActor);

		ZombieTrack = EmptyTrack;
		ZombieTrack.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
		ZombieTrack.StateObject_NewState = ZombieTrack.StateObject_OldState;
		SpawnedUnit = XComGameState_Unit(ZombieTrack.StateObject_NewState);
		`assert(SpawnedUnit != none);
		ZombieTrack.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ZombieTrack, Context, false, DeathAction);

		SpawnPsiZombieEffect.AddSpawnVisualizationsToTracks(Context, SpawnedUnit, ZombieTrack, DeadUnit, BuildTrack);		
	}
}

static function X2AbilityTemplate CreateMindScorch()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2Condition_UnitProperty TargetCondition;
	local X2Effect_Dazed DazedEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MindScorch');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_mindscorch";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.MINDSCORCH_ACTIONPOINTCOST;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.MINDSCORCH_COOLDOWN_LOCAL;
	Cooldown.NumGlobalTurns = default.MINDSCORCH_COOLDOWN_GLOBAL;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StatCheck_UnitVsUnit';

	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_Volt';

	Template.TargetingMethod = class'X2TargetingMethod_Volt';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	//	NOTE: visibility is NOT required for multi targets as it is required between each target (handled by multi target class)
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = true;
	TargetCondition.ExcludeHostileToSource = false;
	TargetCondition.TreatMindControlledSquadmateAsHostile = false;
	TargetCondition.FailOnNonUnits = true;
	TargetCondition.ExcludeCivilian = true;
	TargetCondition.ExcludeCosmetic = true;
	TargetCondition.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(TargetCondition);
	Template.AbilityMultiTargetConditions.AddItem(TargetCondition);

	// On hit effects
	//  Dazed effect for 1 to 4 unblocked hit
	DazedEffect = class'X2StatusEffects_XPack'.static.CreateDazedStatusEffect(default.MINDSCORCH_DAZE1_TURNS, 100);
	DazedEffect.MinStatContestResult = 1;
	DazedEffect.MaxStatContestResult = 4;
	DazedEffect.bRemoveWhenSourceDies = true;
	Template.AddTargetEffect(DazedEffect);
	Template.AddMultiTargetEffect(DazedEffect);

	//  Dazed effect for 5 unblocked hits
	DazedEffect = class'X2StatusEffects_XPack'.static.CreateDazedStatusEffect(default.MINDSCORCH_DAZE2_TURNS, 100);
	DazedEffect.MinStatContestResult = 5;
	DazedEffect.MaxStatContestResult = 0;
	DazedEffect.bRemoveWhenSourceDies = true;
	Template.AddTargetEffect(DazedEffect);
	Template.AddMultiTargetEffect(DazedEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
		
//BEGIN AUTOGENERATED CODE: Template Overrides 'MindScorch'
	Template.ActionFireClass = class'XComGame.X2Action_Fire_MindScorch';
	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CustomFireAnim = 'HL_MindScorch';
	Template.CinescriptCameraType = "ChosenWarlock_MindScorch";
//END AUTOGENERATED CODE: Template Overrides 'MindScorch'

	return Template;
}

static function X2DataTemplate CreatePossess()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Possess');
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_possess";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.POSSESS_ACTIONPOINTCOST;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.POSSESS_COOLDOWN_LOCAL;
	Cooldown.NumGlobalTurns = default.POSSESS_COOLDOWN_GLOBAL;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	//
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Target Conditions
	//
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.IsAdvent = true;
	UnitPropertyCondition.ExcludeAlien = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	Template.AddTargetEffect(new class'X2Effect_Possessed');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

//BEGIN AUTOGENERATED CODE: Template Overrides 'Possess'
	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CustomFireAnim = 'HL_Possess';
	Template.CinescriptCameraType = "ChosenWarlock_Possess";
//END AUTOGENERATED CODE: Template Overrides 'Possess'

	//	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MeleeLostSpawnIncreasePerUse;

	return Template;
}

static function X2DataTemplate CreateSpectralArmy(name AbilityTemplateName, name UnitToSpawnName)
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2Effect_Stasis StasisEffect;
	local X2Effect_SpawnSpectralArmy SpawnArmyEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityTemplateName);

	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_spectralarmy";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.AdditionalAbilities.AddItem('EndSpectralArmy');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.SPECTRALARMY_ACTIONPOINTCOST;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.SPECTRALARMY_COOLDOWN_LOCAL;
	Cooldown.NumGlobalTurns = default.SPECTRALARMY_COOLDOWN_GLOBAL;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	//
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_UnblockedNeighborTile');

	SpawnArmyEffect = new class'X2Effect_SpawnSpectralArmy';
	SpawnArmyEffect.UnitToSpawnName = UnitToSpawnName;
	Template.AddTargetEffect(SpawnArmyEffect);

	StasisEffect = new class'X2Effect_Stasis';
	StasisEffect.BuildPersistentEffect(default.SPECTRALARMY_NUM_TURNS, false, false, false, eGameRule_PlayerTurnBegin);
	StasisEffect.bUseSourcePlayerState = true;
	StasisEffect.bRemoveWhenTargetDies = true;          //  probably shouldn't be possible for them to die while in stasis, but just in case
	StasisEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
	StasisEffect.StunStartAnim = 'HL_SpectralArmy_Stop';
	StasisEffect.StartAnimBlendTime = default.SPECTRALARMY_STOP_BLEND_TIME_S;
	StasisEffect.StunStopAnim = 'HL_SpectralArmy_End';
	StasisEffect.CustomIdleOverrideAnim = 'HL_SpectralArmy_Idle';
	StasisEffect.bSkipFlyover = true;
	StasisEffect.EffectRemovedFn = SpawnSpectralArmyEffect_Removed;
	Template.AddTargetEffect(StasisEffect);

	Template.PostActivationEvents.AddItem(class'X2Effect_Sustain'.default.SustainTriggeredEvent);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

//BEGIN AUTOGENERATED CODE: Template Overrides 'SpectralArmy'
//BEGIN AUTOGENERATED CODE: Template Overrides 'SpectralArmyM2'
//BEGIN AUTOGENERATED CODE: Template Overrides 'SpectralArmyM3'
//BEGIN AUTOGENERATED CODE: Template Overrides 'SpectralArmyM4'
	Template.bShowActivation = true;
	Template.bSkipExitCoverWhenFiring = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.ActionFireClass = class'XComGame.X2Action_Fire_SpectralArmy';
	Template.CinescriptCameraType = "ChosenWarlock_SpectralArmy";
//END AUTOGENERATED CODE: Template Overrides 'SpectralArmyM4'
//END AUTOGENERATED CODE: Template Overrides 'SpectralArmyM3'
//END AUTOGENERATED CODE: Template Overrides 'SpectralArmyM2'
//END AUTOGENERATED CODE: Template Overrides 'SpectralArmy'

	return Template;
}

static function SpawnSpectralArmyEffect_Removed(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;

	if (!bCleansed)
	{
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		if (UnitState == none)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
			if (UnitState == none)
			{
				`RedScreen("SpawnSpectralArmyEffect could not find source unit. @dslonneger @gameplay");
				return;
			}
		}

		// Trigger the removal of 
		`XEVENTMGR.TriggerEvent(default.SpawnSpectralArmyRemovedTriggerName, UnitState, UnitState, NewGameState);
	}
}

// Place holder ability to grab the Sire-Zombie link effect
static function X2AbilityTemplate CreateSpectralArmyLink()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent SpectralArmyLinkEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.SpectralArmyLinkName);
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_spectralarmy";

	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	// Create an effect that will be attached to the spawned zombie
	SpectralArmyLinkEffect = new class'X2Effect_Persistent';
	SpectralArmyLinkEffect.BuildPersistentEffect(1, true, false, true);
	SpectralArmyLinkEffect.bRemoveWhenTargetDies = true;
	SpectralArmyLinkEffect.EffectName = default.SpectralArmyLinkName;
	SpectralArmyLinkEffect.EffectRemovedFn = SpectralArmyLinkEffect_Removed;
	Template.AddTargetEffect(SpectralArmyLinkEffect);

	Template.BuildNewGameStateFn = Empty_BuildGameState;
	Template.BuildVisualizationFn = none;

	return Template;
}

static function SpectralArmyLinkEffect_Removed(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		if (UnitState == none)
		{
			`RedScreen("SpectralArmyLinkEffect could not find source unit. @dslonneger @gameplay");
			return;
		}
	}

	// Trigger the removal of 
	`XEVENTMGR.TriggerEvent(default.SpectralArmyLinkRemovedTriggerName, UnitState, UnitState, NewGameState);
}

simulated function XComGameState Empty_BuildGameState(XComGameStateContext Context)
{
	//	This is an explicit placeholder so that ValidateTemplates doesn't think something is wrong with the ability template.
	`RedScreen("This function should never be called.");
	return none;
}

static function X2DataTemplate CreateEndSpectralArmy()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener AbilityEventListener;
	local X2Condition_UnitEffectsWithAbilitySource TargetEffectCondition;
	local X2Effect_RemoveEffects RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'EndSpectralArmy');

	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_spectralarmy";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// This ability fires when the associated Stasis gets removed
	AbilityEventListener = new class'X2AbilityTrigger_EventListener';
	AbilityEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	AbilityEventListener.ListenerData.EventID = default.SpawnSpectralArmyRemovedTriggerName;
	AbilityEventListener.ListenerData.Filter = eFilter_Unit;
	AbilityEventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(AbilityEventListener);

	// This ability fires when the associated Stasis gets removed
	AbilityEventListener = new class'X2AbilityTrigger_EventListener';
	AbilityEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	AbilityEventListener.ListenerData.EventID = default.SpectralArmyLinkRemovedTriggerName;
	AbilityEventListener.ListenerData.Filter = eFilter_Unit;
	AbilityEventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.ChosenWarlockSpectralArmyLinkRemovedListener;
	Template.AbilityTriggers.AddItem(AbilityEventListener);

	// Shooter Conditions
	//
	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddRequireEffect(class'X2Effect_SpawnSpectralArmy'.default.EffectName, 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(TargetEffectCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnSpectralArmy'.default.EffectName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_Stasis'.default.EffectName);
	RemoveEffects.bCleanse = true;
	RemoveEffects.bApplyOnMiss = true;
	Template.AddShooterEffect(RemoveEffects);

	// Multi Targets
	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddRequireEffect(default.SpectralArmyLinkName, 'AA_MissingRequiredEffect');
	Template.AbilityMultiTargetConditions.AddItem(TargetEffectCondition);
	
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.SpectralArmyLinkName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpectralArmyUnit'.default.EffectName);
	RemoveEffects.bCleanse = true;
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bSkipFireAction = true;
	Template.CinescriptCameraType = "ChosenWarlock_EndSpectralArmy";

	return Template;
}

static function X2DataTemplate CreateTeleportAlly()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2AbilityTrigger_PlayerInput InputTrigger;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TeleportAlly');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	// This is an AI only ability, it does special target unit and target tile setup
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_teleportally";

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.TELEPORTALLY_ACTIONPOINTCOST;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.TELEPORTALLY_COOLDOWN_LOCAL;
	Cooldown.NumGlobalTurns = default.TELEPORTALLY_COOLDOWN_GLOBAL;
	Template.AbilityCooldown = Cooldown;

	Template.TargetingMethod = class'X2TargetingMethod_Teleport';

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Target Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.FailOnNonUnits = true;
	UnitPropertyCondition.ExcludeLargeUnits = true;
	UnitPropertyCondition.ExcludeTurret = true;
	UnitPropertyCondition.RequireSquadmates = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	Template.ModifyNewContextFn = TeleportAlly_ModifyActivatedAbilityContext;
	Template.BuildNewGameStateFn = TeleportAlly_BuildGameState;
	Template.BuildVisualizationFn = TeleportAlly_BuildVisualization;
//BEGIN AUTOGENERATED CODE: Template Overrides 'TeleportAlly'
	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CinescriptCameraType = "ChosenWarlock_TeleportAlly";
//END AUTOGENERATED CODE: Template Overrides 'TeleportAlly'

	return Template;
}

static simulated function TeleportAlly_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateHistory History;
	local PathPoint NextPoint, EmptyPoint;
	local PathingInputData InputData;
	local XComWorldData World;
	local vector NewLocation;
	local TTile NewTileLocation;

	History = `XCOMHISTORY;
	World = `XWORLD;

	AbilityContext = XComGameStateContext_Ability(Context);
	`assert(AbilityContext.InputContext.TargetLocations.Length > 0);

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

	// Build the MovementData for the path
	// First posiiton is the current location
	InputData.MovementTiles.AddItem(UnitState.TileLocation);

	NextPoint.Position = World.GetPositionFromTileCoordinates(UnitState.TileLocation);
	NextPoint.Traversal = eTraversal_Teleport;
	NextPoint.PathTileIndex = 0;
	InputData.MovementData.AddItem(NextPoint);

	// Second posiiton is the cursor position
	`assert(AbilityContext.InputContext.TargetLocations.Length == 1);

	NewLocation = AbilityContext.InputContext.TargetLocations[0];
	NewTileLocation = World.GetTileCoordinatesFromPosition(NewLocation);
	NewLocation = World.GetPositionFromTileCoordinates(NewTileLocation);

	NextPoint = EmptyPoint;
	NextPoint.Position = NewLocation;
	NextPoint.Traversal = eTraversal_Landing;
	NextPoint.PathTileIndex = 1;
	InputData.MovementData.AddItem(NextPoint);
	InputData.MovementTiles.AddItem(NewTileLocation);

	//Now add the path to the input context
	InputData.MovingUnitRef = UnitState.GetReference();
	AbilityContext.InputContext.MovementPaths.AddItem(InputData);
}

static simulated function XComGameState TeleportAlly_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local vector NewLocation;
	local TTile NewTileLocation;
	local XComWorldData World;
	local X2EventManager EventManager;
	local int LastElementIndex;

	World = `XWORLD;
	EventManager = `XEVENTMGR;

	//Build the new game state frame
	NewGameState = TypicalAbility_BuildGameState(Context);

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.PrimaryTarget.ObjectID));

	LastElementIndex = AbilityContext.InputContext.MovementPaths[0].MovementData.Length - 1;

	// Set the unit's new location
	// The last position in MovementData will be the end location
	`assert(LastElementIndex > 0);
	NewLocation = AbilityContext.InputContext.MovementPaths[0].MovementData[LastElementIndex].Position;
	NewTileLocation = World.GetTileCoordinatesFromPosition(NewLocation);
	UnitState.SetVisibilityLocation(NewTileLocation);

	AbilityContext.ResultContext.bPathCausesDestruction = MoveAbility_StepCausesDestruction(UnitState, AbilityContext.InputContext, 0, AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1);
	MoveAbility_AddTileStateObjects(NewGameState, UnitState, AbilityContext.InputContext, 0, AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1);

	EventManager.TriggerEvent('ObjectMoved', UnitState, UnitState, NewGameState);
	EventManager.TriggerEvent('UnitMoveFinished', UnitState, UnitState, NewGameState);

	//Return the game state we have created
	return NewGameState;
}

simulated function TeleportAlly_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr VisMgr;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationActionMetadata SourceTrack, EmptyTrack, ActionMetadata;
	local int i;
	local XComGameState_WorldEffectTileData WorldDataUpdate;
	local X2Action_PlayAnimation AnimAction;
	local X2Action_MoveVisibleTeleport TargetTeleport;
	local X2Action_PlayEffect EffectAction;
	local X2Action_MarkerNamed JoinActions;
	local Array<X2Action> LeafNodes;
	local X2Action_CameraLookAt LookAtAction;
	local X2Action_Delay DelayAction;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	//Configure the visualization track for the shooter
	//****************************************************************************************
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;

	SourceTrack = EmptyTrack;
	SourceTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	SourceTrack.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	// Have the camera look at the Warlock
	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(SourceTrack, AbilityContext));
	LookAtAction.LookAtActor = SourceTrack.VisualizeActor;
	LookAtAction.BlockUntilActorOnScreen = true;

	// Exit Cover, Play anim, enter cover
	class'X2Action_ExitCover_TeleportAlly'.static.AddToVisualizationTree(SourceTrack, AbilityContext);

	AnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(SourceTrack, AbilityContext));
	AnimAction.Params.AnimName = 'HL_TeleportAlly';

	class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceTrack, AbilityContext);

	//****************************************************************************************
	//Configure the visualization track for the Target
	//****************************************************************************************
	// Wait for notify, Play FX out, Delay, Play FX in
	InteractingUnitRef = AbilityContext.InputContext.PrimaryTarget;

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, AnimAction));
	LookAtAction.LookAtActor = ActionMetadata.VisualizeActor;
	LookAtAction.BlockUntilActorOnScreen = true;
	LookAtAction.AddInputEvent('Visualizer_AbilityHit');

	// move action
	class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, ActionMetadata);

	TargetTeleport = X2Action_MoveVisibleTeleport(VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_MoveVisibleTeleport', ActionMetadata.VisualizeActor));
	TargetTeleport.PlayAnim = false;
	TargetTeleport.bLookAtEndPos = true;

	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, , TargetTeleport.ParentActions));
	EffectAction.EffectName = "FX_Chosen_Teleport.P_Chosen_Teleport_Out_w_Sound";
	EffectAction.EffectLocation = AbilityContext.InputContext.MovementPaths[0].MovementData[0].Position;

	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, true, TargetTeleport));
	EffectAction.EffectName = "FX_Chosen_Teleport.P_Chosen_Teleport_In_w_Sound";
	EffectAction.EffectLocation = AbilityContext.InputContext.MovementPaths[0].MovementData[1].Position;

	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, true, EffectAction));
	DelayAction.Duration = default.TELEPORTALLY_IN_DELAY;

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

	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, LeafNodes);
	JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SourceTrack, AbilityContext, false, , LeafNodes));
	JoinActions.SetName("Join_TeleportAlly");
}

static function X2DataTemplate CreateCorress(name AbilityTemplateName, name UnitToSpawn)
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2Effect_SpawnSpectralZombies SpawnZombieEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityTemplateName);

	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_corrupt";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;
	
	Template.AdditionalAbilities.AddItem('RemoveSpectralZombies');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.CORRESS_ACTIONPOINTCOST;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.CORRESS_COOLDOWN_LOCAL;
	Cooldown.NumGlobalTurns = default.CORRESS_COOLDOWN_GLOBAL;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	//
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_UnblockedNeighborTile');

	SpawnZombieEffect = new class'X2Effect_SpawnSpectralZombies';
	SpawnZombieEffect.UnitToSpawnName = UnitToSpawn;
	Template.AddTargetEffect(SpawnZombieEffect);

	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Corress_BuildVisualization;

	//BEGIN AUTOGENERATED CODE: Template Overrides 'Corress'
	//BEGIN AUTOGENERATED CODE: Template Overrides 'CorressM2'
	//BEGIN AUTOGENERATED CODE: Template Overrides 'CorressM3'
	//BEGIN AUTOGENERATED CODE: Template Overrides 'CorressM4'
	Template.CustomFireAnim = 'HL_Corrupt';
	//END AUTOGENERATED CODE: Template Overrides 'CorressM4'
	//END AUTOGENERATED CODE: Template Overrides 'CorressM3'
	//END AUTOGENERATED CODE: Template Overrides 'CorressM2'
	//END AUTOGENERATED CODE: Template Overrides 'Corress'

	Template.CinescriptCameraType = "Warlock_SpectralZombie";

	return Template;
}

simulated function Corress_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr VisMgr;
	local XComWorldData WorldData;
	local XComGameStateContext_Ability Context;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_CameraLookAt LookAtAction;
	local Array<X2Action> FoundActions;
	local X2Action FireAction;
	local XComGameState_Unit GameStateUnit;
	local X2Action_CameraRemove RemoveCamera;

	// Build the basic ability visualization
	TypicalAbility_BuildVisualization(VisualizeGameState);

	VisMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	//Add a look at camera to the spawned units
	//****************************************************************************************
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ShowSpawnedUnit', FoundActions);
	FireAction = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_Fire', , Context.InputContext.SourceObject.ObjectID);

	if( (FoundActions.Length > 0) &&
		(FireAction != none) )
	{
		ActionMetadata.StateObject_OldState = FoundActions[0].MetaData.StateObject_OldState;
		ActionMetadata.StateObject_NewState = FoundActions[0].MetaData.StateObject_NewState;
		ActionMetadata.VisualizeActor = FoundActions[0].MetaData.VisualizeActor;

		GameStateUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);

		if( GameStateUnit != none )
		{
			WorldData = `XWORLD;

			LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, true, FireAction));
			LookAtAction.LookAtLocation = WorldData.GetPositionFromTileCoordinates(GameStateUnit.TileLocation);
			LookAtAction.LookAtDuration = default.CORRESS_LOOKAT_DURATION * (`XPROFILESETTINGS.Data.bEnableZipMode ? class'X2TacticalGameRuleset'.default.ZipModeDelayModifier : 1.0);;
			LookAtAction.BlockUntilActorOnScreen = true;
			LookAtAction.AddInputEvent('Visualizer_AbilityHit');

			ActionMetadata.StateObject_NewState = `XCOMHISTORY.GetGameStateForObjectID( Context.InputContext.SourceObject.ObjectID );
			ActionMetadata.StateObject_OldState = ActionMetadata.StateObject_NewState.GetPreviousVersion( );
			ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer( Context.InputContext.SourceObject.ObjectID );

			RemoveCamera = X2Action_CameraRemove( class'X2Action_CameraRemove'.static.AddToVisualizationTree( ActionMetadata, Context, true, ActionMetadata.LastActionAdded ) );
			RemoveCamera.CameraTagToRemove = 'AbilityFraming';
		}
	}
}

static function X2DataTemplate CreateRemoveSpectralZombies()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Condition_UnitEffects MultiTargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RemoveSpectralZombies');

	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_corrupt";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';

	// This ability fires when the unit takes damage
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitRemovedFromPlay';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.Priority = 75;	// We need this to happen before the unit is actually removed from play
	Template.AbilityTriggers.AddItem(EventListener);

	// Multi Targets - Remove all Daze status effects
	MultiTargetCondition = new class'X2Condition_UnitEffects';
	MultiTargetCondition.AddRequireEffect(class'X2Effect_SpectralZombie'.default.EffectName, 'AA_MissingRequiredEffect');
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpectralZombie'.default.EffectName);
	RemoveEffects.bCleanse = true;
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

// Spectral Army units init
static function X2AbilityTemplate CreateSpectralArmyUnitInitialize()
{
	local X2AbilityTemplate Template;
	local X2Effect_SpectralArmyUnit SpectralArmyUnitEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SpectralArmyUnitInitialize');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	SpectralArmyUnitEffect = new class'X2Effect_SpectralArmyUnit';
	SpectralArmyUnitEffect.BuildPersistentEffect(1, true, true, true);
	SpectralArmyUnitEffect.bRemoveWhenTargetDies = true;
	Template.AddShooterEffect(SpectralArmyUnitEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate CreateSpectralZombieInitialize()
{
	local X2AbilityTemplate Template;
	local X2Effect_SpectralZombie SpectralZombieEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SpectralZombieInitialize');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AdditionalAbilities.AddItem('EngagePsiSelfDestruct');

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	SpectralZombieEffect = new class'X2Effect_SpectralZombie';
	SpectralZombieEffect.BuildPersistentEffect(1, true, true, true);
	SpectralZombieEffect.bRemoveWhenTargetDies = true;
	Template.AddShooterEffect(SpectralZombieEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate CreateEngagePsiSelfDestruct()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Persistent                   SelfDestructEffect;
	local X2Effect_DamageImmunity               DamageImmunity;
	local X2Condition_UnitEffects				EffectConditions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'EngagePsiSelfDestruct');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.UIPerk_warlock_kamikaze";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideIfOtherAvailable;
	Template.HideIfAvailable.AddItem('TriggerPsiSelfDestruct');

	Template.AdditionalAbilities.AddItem('TriggerPsiSelfDestruct');
	Template.AdditionalAbilities.AddItem('PsiDeathExplosion');
	Template.AdditionalAbilities.AddItem('ExplodingPsiInitialState');

	Template.AbilityCosts.AddItem(default.FreeActionCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	EffectConditions = new class'X2Condition_UnitEffects';
	EffectConditions.AddExcludeEffect(default.PsiSelfDestructEffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(EffectConditions);

	SelfDestructEffect = new class'X2Effect_Persistent';
	SelfDestructEffect.BuildPersistentEffect(1, true, false, true);
	SelfDestructEffect.EffectName = default.PsiSelfDestructEffectName;
	Template.AddShooterEffect(SelfDestructEffect);

	// Build the immunities
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, true, true);
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.KnockbackDamageType);
	DamageImmunity.EffectName = 'SelfDestructEngagedImmunities';
	Template.AddShooterEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildAppliedVisualizationSyncFn = EngagePsiSelfDestruct_BuildVisualizationSync;
	
	Template.bShowActivation = true;
	Template.CustomFireAnim = 'FF_Self_Destruct_Start';

	Template.TwoTurnAttackAbility = 'TriggerPsiSelfDestruct'; // AI using this ability triggers more AI overwatchers.
	return Template;
}
static function EngagePsiSelfDestruct_Visualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_SetRagdoll SetRagdollAction;

	if (EffectApplyResult != 'AA_Success')
	{
		return;
	}

	SetRagdollAction = X2Action_SetRagdoll(class'X2Action_SetRagdoll'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SetRagdollAction.RagdollFlag = ERagdoll_Never;
}

simulated function EngagePsiSelfDestruct_BuildVisualizationSync(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate AbilityTemplate;
	local int EffectIndex;

	if (EffectName == default.PsiSelfDestructEffectName)
	{
		Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

		AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.ResultContext.ShooterEffectResults.ApplyResults[EffectIndex]);
		}
	}
}

static function X2AbilityTemplate CreateTriggerPsiSelfDestruct()
{
	local X2AbilityTemplate					Template;
	local X2Condition_UnitEffects           EffectConditions;
	local X2Effect_KillUnit                 KillUnitEffect;
	local X2AbilityTarget_Cursor			CursorTarget;
	local X2AbilityMultiTarget_Radius		RadiusMultiTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TriggerPsiSelfDestruct');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.Hostility = eHostility_Offensive;
	Template.IconImage = "img:///UILibrary_XPACK_Common.UIPerk_warlock_kamikaze";

	Template.AbilityCosts.AddItem(default.FreeActionCost);

	Template.AbilityToHitCalc = default.DeadEye;
	//	Template.AbilityTargetStyle = default.SelfTarget; // Update - APC- changed to MultiTarget_Radius for use with AI AoEs
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	EffectConditions = new class'X2Condition_UnitEffects';
	EffectConditions.AddRequireEffect(default.PsiSelfDestructEffectName, 'AA_MissingRequiredEffect');
	Template.AbilityShooterConditions.AddItem(EffectConditions);

	KillUnitEffect = new class'X2Effect_KillUnit';
	KillUnitEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	KillUnitEffect.EffectName = 'TriggerPsiSelfDestruct';
	Template.AddShooterEffect(KillUnitEffect);

	// APC- Added cursor targeting to enable run & self-destruct combo.
	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.fTargetRadius = default.PSI_DEATH_EXPLOSION_RADIUS_METERS;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_PathTarget';
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	//	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;  // APC- Updated to use Movement.  Allow Dash + Overload for AI.
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.DamagePreviewFn = TriggerPsiSelfDestruct_DamagePreview;
//BEGIN AUTOGENERATED CODE: Template Overrides 'TriggerPsiSelfDestruct'
	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'TriggerPsiSelfDestruct'

	return Template;
}

function bool TriggerPsiSelfDestruct_DamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	MinDamagePreview = class'X2Item_XPackWeapons'.default.PSI_DEATH_EXPLOSION_BASEDAMAGE;
	MaxDamagePreview = MinDamagePreview;
	return true;
}

simulated function TriggerPsiSelfDestruct_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          UnitRef;
	local X2VisualizerInterface			PsiVisualizerInterface;
	local VisualizationActionMetadata			EmptyTrack;
	local VisualizationActionMetadata			ActionMetadata;
	local XComGameStateHistory			History;
	local X2AbilityTemplate             AbilityTemplate;
	local X2Action_PlaySoundAndFlyOver  SoundAndFlyover;
	//local int TrackActionIndex, NumActions;

	// Added for move option.
	TypicalAbility_BuildVisualization(VisualizeGameState);

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	History = `XCOMHISTORY;
		UnitRef = Context.InputContext.SourceObject;
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(UnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(UnitRef.ObjectID);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFriendlyName, AbilityTemplate.ActivationSpeech, eColor_Bad, AbilityTemplate.IconImage);

	PsiVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
	PsiVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);

}

static function X2AbilityTemplate ExplodingPsiInit()
{
	local X2AbilityTemplate					Template;
	local X2Effect_OverrideDeathAction      DeathActionEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ExplodingPsiInitialState');

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	DeathActionEffect = new class'X2Effect_OverrideDeathAction';
	DeathActionEffect.DeathActionClass = class'X2Action_ExplodingPsiDeathAction';
	DeathActionEffect.EffectName = 'ExplodingPsiDeathActionEffect';
	DeathActionEffect.bPersistThroughTacticalGameEnd = true;
	Template.AddTargetEffect(DeathActionEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate PsiDeathExplosion()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    EventListener;
	local X2AbilityMultiTarget_Radius       MultiTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_UnitEffects           EffectConditions;
	local X2Effect_ApplyWeaponDamage        DamageEffect;
	local X2Effect_OverrideDeathAnimOnLoad  OverrideDeathAnimEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiDeathExplosion');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_deathexplosion";

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;

	EffectConditions = new class'X2Condition_UnitEffects';
	EffectConditions.AddRequireEffect(default.PsiSelfDestructEffectName, 'AA_MissingRequiredEffect');
	Template.AbilityShooterConditions.AddItem(EffectConditions);

	// This ability is only valid if there has not been another death explosion on the unit
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeDeadFromSpecialDeath = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitDied';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self_VisualizeInGameState;
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the unit so the blast center is its dead body
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;

	// Target everything in this blast radius
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = default.PSI_DEATH_EXPLOSION_RADIUS_METERS;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AddTargetEffect(new class'X2Effect_SetSpecialDeath');

	OverrideDeathAnimEffect = new class'X2Effect_OverrideDeathAnimOnLoad';
	OverrideDeathAnimEffect.EffectName = 'PsiDeathAnimOnLoad';
	OverrideDeathAnimEffect.OverrideAnimNameOnLoad = 'FF_Self_Destruct_Boom';
	OverrideDeathAnimEffect.BuildPersistentEffect(1, true, false, true);
	OverrideDeathAnimEffect.EffectRank = 10;
	Template.AddTargetEffect(OverrideDeathAnimEffect);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = false; //The grenade can affect interactive objects, others
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	// Everything in the blast radius receives physical damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.EffectDamageValue = class'X2Item_XPackWeapons'.default.PSI_DEATH_EXPLOSION_BASEDAMAGE;
	DamageEffect.EnvironmentalDamageAmount = default.PSI_EXPLOSION_ENV_DMG;
	Template.AddMultiTargetEffect(DamageEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_Death'.static.DeathExplosion_BuildVisualization;
	Template.MergeVisualizationFn = class'X2Ability_Death'.static.DeathExplostion_MergeVisualization;

	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'PsiDeathExplosion'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'PsiDeathExplosion'

	return Template;
}

static function X2AbilityTemplate CreateSpectralArmLanceAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2Condition_UnitProperty TargetPropertyCondition;
	local X2Condition_UnitProperty ShooterPropertyCondition;
	local X2AbilityTarget_MovingMelee MeleeTarget;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local X2Effect_ImmediateAbilityActivation ImpairingAbilityEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SpectralStunLance');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventstunlancer_stunlance";

	Template.AdditionalAbilities.AddItem(default.SpectralArmyImpairingAbilityName);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	MeleeTarget = new class'X2AbilityTarget_MovingMelee';
	Template.AbilityTargetStyle = MeleeTarget;

	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_PlayerInput');
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_EndOfMove');

	// Target Conditions
	//
	TargetPropertyCondition = new class'X2Condition_UnitProperty';
	TargetPropertyCondition.ExcludeDead = true;                     //Can't target dead
	TargetPropertyCondition.ExcludeFriendlyToSource = true;         //Can't target friendlies
	Template.AbilityTargetConditions.AddItem(TargetPropertyCondition);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);

	// Shooter Conditions
	//
	ShooterPropertyCondition = new class'X2Condition_UnitProperty';
	ShooterPropertyCondition.ExcludeDead = true;                    //Can't shoot while dead
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);

	Template.AddShooterEffectExclusions();

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StandardMelee';

	// Damage Effect
	//
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.DamageTypes.AddItem('Electrical');
	Template.AddTargetEffect(WeaponDamageEffect);

	//Impairing effects need to come after the damage. This is needed for proper visualization ordering.
	//Effect on a successful melee attack is triggering the Apply Impairing Effect Ability
	ImpairingAbilityEffect = new class 'X2Effect_ImmediateAbilityActivation';
	ImpairingAbilityEffect.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	ImpairingAbilityEffect.EffectName = 'ImmediateSpectralArmyImpair';
	ImpairingAbilityEffect.AbilityName = default.SpectralArmyImpairingAbilityName;
	ImpairingAbilityEffect.bRemoveWhenTargetDies = true;
	ImpairingAbilityEffect.VisualizationFn = SpectralArmyImpairingAbilityEffectTriggeredVisualization;
	Template.AddTargetEffect(ImpairingAbilityEffect);

	Template.bSkipMoveStop = true;

	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "AdvStunLancer_StunLancer";

	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MeleeLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'SpectralStunLance'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'SpectralStunLance'

	return Template;
}

static function X2DataTemplate CreateSpectralArmyImpairingEffectAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityToHitCalc_StatCheck_UnitVsUnit StatContest;
	local X2AbilityTarget_Single SingleTarget;
	local X2Effect_Dazed DazedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.SpectralArmyImpairingAbilityName);

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');      //  ability is activated by another ability that hits

	// Target Conditions
	//
	Template.AbilityTargetConditions.AddItem(default.LivingTargetUnitOnlyProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	// Shooter Conditions
	//
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	Template.AddShooterEffectExclusions();

	// This will be a stat contest
	StatContest = new class'X2AbilityToHitCalc_StatCheck_UnitVsUnit';
	StatContest.AttackerStat = eStat_Strength;
	Template.AbilityToHitCalc = StatContest;

	// On hit effects
	//  Dazed effect for 1 to 4 unblocked hit
	DazedEffect = class'X2StatusEffects_XPack'.static.CreateDazedStatusEffect(default.SPECTRALARMY_IMPAIR_DAZE1_TURNS, 100);
	DazedEffect.MinStatContestResult = 1;
	DazedEffect.MaxStatContestResult = 4;
	DazedEffect.bRemoveWhenSourceDies = false;
	Template.AddTargetEffect(DazedEffect);

	//  Dazed effect for 5 unblocked hits
	DazedEffect = class'X2StatusEffects_XPack'.static.CreateDazedStatusEffect(default.SPECTRALARMY_IMPAIR_DAZE2_TURNS, 100);
	DazedEffect.MinStatContestResult = 5;
	DazedEffect.MaxStatContestResult = 0;
	DazedEffect.bRemoveWhenSourceDies = false;
	Template.AddTargetEffect(DazedEffect);

	Template.bSkipPerkActivationActions = true;
	Template.bSkipPerkActivationActionsSync = false;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = SpectralArmyImpairing_BuildVisualization;
//BEGIN AUTOGENERATED CODE: Template Overrides 'SpectralArmyImpairingAbility'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'SpectralArmyImpairingAbility'

	return Template;
}

simulated function SpectralArmyImpairing_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference InteractingUnitRef;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	class'X2Action_AbilityPerkStart'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

}

static function SpectralArmyImpairingAbilityEffectTriggeredVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability TestAbilityContext;
	local int i, j, ChildIndex;
	local XComGameStateHistory History;
	local bool bAbilityWasSuccess;
	local X2AbilityTemplate AbilityTemplate;
	local X2VisualizerInterface TargetVisualizerInterface;
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action_ApplyWeaponDamageToUnit DamageAction;
	local X2Action TempAction;
	local X2Action_MarkerNamed HitReactAction;

	if ((EffectApplyResult != 'AA_Success') || (XComGameState_Unit(ActionMetadata.StateObject_NewState) == none))
	{
		return;
	}

	Context = VisualizeGameState.GetContext();
	AbilityContext = XComGameStateContext_Ability(Context);

	if (AbilityContext.EventChainStartIndex != 0)
	{
		History = `XCOMHISTORY;

		// This GameState is part of a chain, which means there may be a stun to the target
		for (i = AbilityContext.EventChainStartIndex; !Context.bLastEventInChain; ++i)
		{
			Context = History.GetGameStateFromHistory(i).GetContext();

			TestAbilityContext = XComGameStateContext_Ability(Context);
			bAbilityWasSuccess = (TestAbilityContext != none) && class'XComGameStateContext_Ability'.static.IsHitResultHit(TestAbilityContext.ResultContext.HitResult);

			if (bAbilityWasSuccess &&
				TestAbilityContext.InputContext.AbilityTemplateName == default.SpectralArmyImpairingAbilityName &&
				TestAbilityContext.InputContext.SourceObject.ObjectID == AbilityContext.InputContext.SourceObject.ObjectID &&
				TestAbilityContext.InputContext.PrimaryTarget.ObjectID == AbilityContext.InputContext.PrimaryTarget.ObjectID)
			{
				// The Melee Impairing Ability has been found with the same source and target
				// Move that ability's visualization forward to this track
				AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(TestAbilityContext.InputContext.AbilityTemplateName);

				for (j = 0; j < AbilityTemplate.AbilityTargetEffects.Length; ++j)
				{
					AbilityTemplate.AbilityTargetEffects[j].AddX2ActionsForVisualization(TestAbilityContext.AssociatedState, ActionMetadata, TestAbilityContext.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[j]));
				}

				TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
				if (TargetVisualizerInterface != none)
				{
					TargetVisualizerInterface.BuildAbilityEffectsVisualization(Context.AssociatedState, ActionMetadata);
				}

				VisMgr = `XCOMVISUALIZATIONMGR;

				DamageAction = X2Action_ApplyWeaponDamageToUnit(VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', ActionMetadata.VisualizeActor));

				if (DamageAction.ChildActions.Length > 0)
				{
					HitReactAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, true, DamageAction));
					HitReactAction.SetName("ImpairingReact");
					HitReactAction.AddInputEvent('Visualizer_AbilityHit');

					for (ChildIndex = 0; ChildIndex < DamageAction.ChildActions.Length; ++ChildIndex)
					{
						TempAction = DamageAction.ChildActions[ChildIndex];
						VisMgr.DisconnectAction(TempAction);
						VisMgr.ConnectAction(TempAction, VisMgr.BuildVisTree, false, , DamageAction.ParentActions);
					}

					VisMgr.DisconnectAction(DamageAction);
					VisMgr.ConnectAction(DamageAction, VisMgr.BuildVisTree, false, ActionMetadata.LastActionAdded);
				}

				break;
			}
		}
	}
}

defaultproperties
{
	SpectralArmyLinkName="SpectralArmyLink"
	SpawnSpectralArmyRemovedTriggerName="SpawnSpectralArmyRemovedTrigger"
	SpectralArmyLinkRemovedTriggerName="SpectralArmyLinkRemovedTrigger"
	SpectralArmyImpairingAbilityName="SpectralArmyImpairingAbility"
	PsiSelfDestructEffectName="PsiSelfDestructEffect"
	SpectralZombieLinkName="SpectralZombieLink"

}
