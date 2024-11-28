//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_PsiWitch extends X2Ability
	config(GameData_SoldierSkills);

var config int CONFUSE_LOCAL_COOLDOWN;
var config int CONFUSE_GLOBAL_COOLDOWN;
var config int CONFUSE_LASTS_NUM_TURNS;
var config int DIMENSIONAL_RIFT_RADIUS;
var config int DIMENSIONAL_RIFT_RANGE;
var config int DIMENSIONAL_RIFT_ENVDAMAGE;
var config int DIMENSIONAL_RIFT_LOCAL_COOLDOWN;
var config int DIMENSIONAL_RIFT_GLOBAL_COOLDOWN;
var config int DIMENSIONAL_RIFT_DISORIENTED2_LASTS_NUMBER_TURNS;
var config int DIMENSIONAL_RIFT_DISORIENTED1_LASTS_NUMBER_TURNS;
var config float DIMENSIONAL_RIFT_STAGE1_START_WARNING_FX_SEC;
var config float DIMENSIONAL_RIFT_STAGE1_NOTIFY_TARGETS_SEC;
var config float DIMENSIONAL_RIFT_STAGE2_START_EXPLOSION_FX_SEC;
var config float DIMENSIONAL_RIFT_STAGE2_NOTIFY_TARGETS_SEC;
var config int MIND_CONTROL_LOCAL_COOLDOWN_PLAYER;
var config int MIND_CONTROL_LOCAL_COOLDOWN_AI;
var config int MIND_CONTROL_GLOBAL_COOLDOWN_AI;
var config int MIND_CONTROL_AI_TURNS_DURATION;
var config int MIND_CONTROL_PLAYER_TURNS_DURATION;
var config int AVATAR_REGENERATION_HEAL_VALUE;
var config int TELEPORT_MIN_TILE_RADIUS;
var config int TELEPORT_MAX_TILE_RADIUS;

var name DelayedDimensionalRiftEffectName;
var name DimensionalRiftTriggerName;
var name MindControlAbilityName;
var name DimensionalRiftStage2Name;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateDimensionalRiftStage1Ability());
	Templates.AddItem(CreateDimensionalRiftStage2Ability());
	Templates.AddItem(CreatePsiMindControlAbility());
	Templates.AddItem(CreateAvatarInitializationAbility());
	Templates.AddItem(PurePassive('AvatarImmunities', "img:///UILibrary_PerkIcons.UIPerk_mentalfortress"));
	Templates.AddItem(CreateTriggerDamagedTeleportListenerAbility());
	Templates.AddItem(CreateTriggerDamagedTeleportAbility());
	Templates.AddItem(PurePassive('AvatarDamagedTeleport', "img:///UILibrary_PerkIcons.UIPerk_codex_teleport"));
	Templates.AddItem(PurePassive('AvatarRegeneration', "img:///UILibrary_PerkIcons.UIPerk_regeneration"));

	return Templates;
}

static function X2AbilityTemplate CreateDimensionalRiftStage1Ability()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2AbilityMultiTarget_Radius RadiusMultiTarget;
	local X2Effect_MarkValidActivationTiles MarkTilesEffect;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2Effect_DelayedAbilityActivation DelayedDimensionalRiftEffect;
	local X2Effect_ApplyWeaponDamage RiftDamageEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiDimensionalRiftStage1');

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventpsiwitch_dimensionrift";
	Template.bShowActivation = true;
	Template.TwoTurnAttackAbility = default.DimensionalRiftStage2Name;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.DIMENSIONAL_RIFT_LOCAL_COOLDOWN;
	Cooldown.NumGlobalTurns = default.DIMENSIONAL_RIFT_GLOBAL_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.fTargetRadius = default.DIMENSIONAL_RIFT_RADIUS;
	RadiusMultiTarget.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	MarkTilesEffect = new class'X2Effect_MarkValidActivationTiles';
	MarkTilesEffect.AbilityToMark = 'PsiDimensionalRiftStage2';
	MarkTilesEffect.OnlyUseTargetLocation = true;
	Template.AddShooterEffect(MarkTilesEffect);

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToSquadsightRange = true;
	CursorTarget.FixedAbilityRange = default.DIMENSIONAL_RIFT_RANGE;    //  @TODO - range might be tied to psi amp later
	Template.AbilityTargetStyle = CursorTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//Effect on a successful test is adding the delayed marked effect to the target
	DelayedDimensionalRiftEffect = new class 'X2Effect_DelayedAbilityActivation';
	DelayedDimensionalRiftEffect.BuildPersistentEffect(1, false, false, , eGameRule_PlayerTurnBegin);
	DelayedDimensionalRiftEffect.EffectName = default.DelayedDimensionalRiftEffectName;
	DelayedDimensionalRiftEffect.TriggerEventName = default.DimensionalRiftTriggerName;
	DelayedDimensionalRiftEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddShooterEffect(DelayedDimensionalRiftEffect);

	Template.TargetingMethod = class'X2TargetingMethod_VoidRift';

	Template.AbilityTargetConditions.AddItem(default.LivingTargetUnitOnlyProperty);

	RiftDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	RiftDamageEffect.bIgnoreBaseDamage = true;
	RiftDamageEffect.DamageTag = 'PsiDimensionalRiftStage1';
	RiftDamageEffect.bIgnoreArmor = true;
	Template.AddMultiTargetEffect(RiftDamageEffect);

	Template.CustomFireAnim = 'HL_Psi_SelfCast';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = DimensionalRiftStage1_BuildVisualization;
	Template.BuildAffectedVisualizationSyncFn = DimensionalRigt1_BuildAffectedVisualization;
	Template.CinescriptCameraType = "Psionic_FireAtLocation";
//BEGIN AUTOGENERATED CODE: Template Overrides 'PsiDimensionalRiftStage1'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'PsiDimensionalRiftStage1'

	return Template;
}

simulated function DimensionalRiftStage1_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XComGameStateContext_Ability Context;
	local StateObjectReference InteractingUnitRef;
	local X2VisualizerInterface Visualizer;
	local VisualizationActionMetadata ActionMetadata, AvatarBuildTrack;
	local X2Action_PlayEffect EffectAction;
	local X2Action_StartStopSound SoundAction;
	local XComGameState_Unit AvatarUnit;
	local XComWorldData World;
	local vector TargetLocation;
	local TTile TargetTile;
	local X2Action_TimedWait WaitAction;
	local X2Action_PlaySoundAndFlyOver SoundCueAction;
	local int i, j;
	local VisualizationActionMetadata EmptyTrack;
	local X2VisualizerInterface TargetVisualizerInterface;
	local X2Action ExitCoverAction;
	local array<X2Action> DamageActions;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	//Configure the visualization track for the shooter
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.SourceObject;
	AvatarBuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	AvatarBuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	AvatarBuildTrack.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	AvatarUnit = XComGameState_Unit(AvatarBuildTrack.StateObject_NewState);

	if( AvatarUnit != none )
	{
		World = `XWORLD;

		// Exit cover
		ExitCoverAction = class'X2Action_ExitCover'.static.AddToVisualizationTree(AvatarBuildTrack, Context);

		//If we were interrupted, insert a marker node for the interrupting visualization code to use. In the move path version above, it is expected for interrupts to be 
		//done during the move.
		if (Context.InterruptionStatus != eInterruptionStatus_None)
		{
			//Insert markers for the subsequent interrupt to insert into
			class'X2Action'.static.AddInterruptMarkerPair(AvatarBuildTrack, Context, ExitCoverAction);
		}

		class'X2Action_Fire_OpenUnfinishedAnim'.static.AddToVisualizationTree(AvatarBuildTrack, Context);

		// Wait to time the start of the warning FX
		WaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		WaitAction.DelayTimeSec = default.DIMENSIONAL_RIFT_STAGE1_START_WARNING_FX_SEC;

		// Display the Warning FX (covert to tile and back to vector because stage 2 is at the GetPositionFromTileCoordinates coord
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		EffectAction.EffectName = "FX_Psi_Dimensional_Rift.P_Psi_Dimensional_Rift_Warning";

		TargetLocation = Context.InputContext.TargetLocations[0];
		TargetTile = World.GetTileCoordinatesFromPosition(TargetLocation);

		EffectAction.EffectLocation = World.GetPositionFromTileCoordinates(TargetTile);

		// Play Target audio
		SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		SoundAction.Sound = new class'SoundCue';
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2AvatarFX.Avatar_Ability_Dimensional_Rift_Target_Activate';
		SoundAction.iAssociatedGameStateObjectId = AvatarUnit.ObjectID;
		SoundAction.bStartPersistentSound = true;
		SoundAction.bIsPositional = true;
		SoundAction.vWorldPosition = EffectAction.EffectLocation;

		// Play the sound cue
		SoundCueAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		SoundCueAction.SetSoundAndFlyOverParameters(SoundCue'SoundX2AvatarFX.Avatar_Ability_Dimensional_Rift_Target_Activate_Cue', "", '', eColor_Good);

		class'X2Action_Fire_CloseUnfinishedAnim'.static.AddToVisualizationTree(AvatarBuildTrack, Context);

		Visualizer = X2VisualizerInterface(AvatarBuildTrack.VisualizeActor);
		if( Visualizer != none )
		{
			Visualizer.BuildAbilityEffectsVisualization(VisualizeGameState, AvatarBuildTrack);
		}

		class'X2Action_EnterCover'.static.AddToVisualizationTree(AvatarBuildTrack, Context);

		// Wait to time the damage
		WaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(AvatarBuildTrack, Context, false, WaitAction));
		WaitAction.DelayTimeSec = default.DIMENSIONAL_RIFT_STAGE1_NOTIFY_TARGETS_SEC;
	}
	//****************************************************************************************

	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	for (i = 0; i < Context.InputContext.MultiTargets.Length; ++i)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[i];

		if( InteractingUnitRef == AvatarUnit.GetReference() )
		{
			ActionMetadata = AvatarBuildTrack;
		}
		else
		{
			ActionMetadata = EmptyTrack;
			ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
			ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
			ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
		}

		for( j = 0; j < Context.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			Context.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}

		TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}
	}

	TypicalAbility_AddEffectRedirects(VisualizeGameState, AvatarBuildTrack);

	VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', DamageActions);
	for (i = 0; i < DamageActions.Length; ++i)
	{
		VisualizationMgr.DisconnectAction(DamageActions[i]);
		VisualizationMgr.ConnectAction(DamageActions[i], VisualizationMgr.BuildVisTree, false, WaitAction);
	}
}

simulated function DimensionalRigt1_BuildAffectedVisualization(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
{
	local XComGameStateContext_Ability Context;
	local X2Action_PlayEffect EffectAction;
	local X2Action_StartStopSound SoundAction;
	local XComGameState_Unit AvatarUnit;
	local XComWorldData World;
	local vector TargetLocation;
	local TTile TargetTile;
	
	if( !`XENGINE.IsMultiplayerGame() && EffectName == default.DelayedDimensionalRiftEffectName )
	{
		Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
		AvatarUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);

		if( (Context == none) || (AvatarUnit == none) )
		{
			return;
		}

		World = `XWORLD;

		// Display the Warning FX (convert to tile and back to vector because stage 2 is at the GetPositionFromTileCoordinates coord
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		EffectAction.EffectName = "FX_Psi_Dimensional_Rift.P_Psi_Dimensional_Rift_Warning";

		TargetLocation = Context.InputContext.TargetLocations[0];
		TargetTile = World.GetTileCoordinatesFromPosition(TargetLocation);

		EffectAction.EffectLocation = World.GetPositionFromTileCoordinates(TargetTile);

		// Play Target Activate Sound
		SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		SoundAction.Sound = new class'SoundCue';
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2AvatarFX.Avatar_Ability_Dimensional_Rift_Target_Activate';
		SoundAction.iAssociatedGameStateObjectId = AvatarUnit.ObjectID;
		SoundAction.bStartPersistentSound = true;
		SoundAction.bIsPositional = true;
		SoundAction.vWorldPosition = EffectAction.EffectLocation;
	}
}

static function X2AbilityTemplate CreateDimensionalRiftStage2Ability()
{
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_Radius RadiusMultiTarget;
	local X2Condition_UnitProperty LivingTargetCondition;
	local X2AbilityCooldown Cooldown;
	local X2AbilityTrigger_EventListener DelayedEventListener;
	local X2Effect_ApplyWeaponDamage RiftDamageEffect;
	local X2Effect_PersistentStatChange DisorientedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.DimensionalRiftStage2Name);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.DIMENSIONAL_RIFT_LOCAL_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StatCheck_UnitVsUnit';

	LivingTargetCondition = new class'X2Condition_UnitProperty';
	LivingTargetCondition.ExcludeFriendlyToSource = false;
	LivingTargetCondition.ExcludeHostileToSource = false;
	LivingTargetCondition.ExcludeAlive = false;
	LivingTargetCondition.ExcludeDead = true;
	Template.AbilityMultiTargetConditions.AddItem(LivingTargetCondition);

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.fTargetRadius = default.DIMENSIONAL_RIFT_RADIUS;
	RadiusMultiTarget.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// This effect is here to attach perk FX to
	Template.AddShooterEffect(new class'X2Effect_PerkAttachForFX');

	// TODO: This doesn't actually target self but needs an AbilityTargetStyle
	Template.AbilityTargetStyle = default.SelfTarget;

	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.DimensionalRiftTriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_Unit;
	DelayedEventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_ValidAbilityLocation;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	RiftDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	RiftDamageEffect.bIgnoreBaseDamage = true;
	RiftDamageEffect.DamageTag = 'PsiDimensionalRiftStage2';
	RiftDamageEffect.bIgnoreArmor = true;
	RiftDamageEffect.EnvironmentalDamageAmount = default.DIMENSIONAL_RIFT_ENVDAMAGE;
	Template.AddMultiTargetEffect(RiftDamageEffect);

	//  Disorient effect for 1 unblocked psi hit
	DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
	DisorientedEffect.iNumTurns = default.DIMENSIONAL_RIFT_DISORIENTED1_LASTS_NUMBER_TURNS;
	DisorientedEffect.MinStatContestResult = 1;
	DisorientedEffect.MaxStatContestResult = 1;
	DisorientedEffect.DamageTypes.AddItem('Psi');
	Template.AddMultiTargetEffect(DisorientedEffect);

	//  Disorient effect for 2 unblocked psi hits
	DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
	DisorientedEffect.iNumTurns = default.DIMENSIONAL_RIFT_DISORIENTED2_LASTS_NUMBER_TURNS;
	DisorientedEffect.MinStatContestResult = 2;
	DisorientedEffect.MaxStatContestResult = 0;
	DisorientedEffect.DamageTypes.AddItem('Psi');
	Template.AddMultiTargetEffect(DisorientedEffect);

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = DimensionalRiftStage2_BuildVisualization;
	Template.CinescriptCameraType = "Avatar_DimensionalRift_Stage2";
//BEGIN AUTOGENERATED CODE: Template Overrides 'PsiDimensionalRiftStage2'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'PsiDimensionalRiftStage2'

	return Template;
}

simulated function DimensionalRiftStage2_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata AvatarBuildTrack, ActionMetadata;
	local int i, j;
	local X2VisualizerInterface TargetVisualizerInterface;
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_WorldEffectTileData WorldDataUpdate;
	local XComGameState_InteractiveObject InteractiveObject;
	local X2Action_PlayEffect EffectAction;
	local X2Action_StartStopSound SoundAction;
	local XComGameState_Unit AvatarUnit;
	local X2Action_TimedWait WaitAction;
	local array<X2Action> DamageActions;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	//****************************************************************************************
	//Configure the visualization track for the source
	//****************************************************************************************
	AvatarBuildTrack = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(InteractingUnitRef.ObjectID,
													   AvatarBuildTrack.StateObject_OldState, AvatarBuildTrack.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);
	AvatarBuildTrack.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	AvatarUnit = XComGameState_Unit(AvatarBuildTrack.StateObject_OldState);

	if( AvatarUnit != none )
	{
		// Stop the Loop audio
		SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		SoundAction.Sound = new class'SoundCue';
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2AvatarFX.Stop_AvatarDimensionalRiftLoop';
		SoundAction.iAssociatedGameStateObjectId = AvatarUnit.ObjectID;
		SoundAction.bIsPositional = true;
		SoundAction.bStopPersistentSound = true;

		// Stop the Warning FX
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		EffectAction.EffectName = "FX_Psi_Dimensional_Rift.P_Psi_Dimensional_Rift_Warning";
		EffectAction.EffectLocation = Context.InputContext.TargetLocations[0];
		EffectAction.bStopEffect = true;

		// Play the Collapsing audio
		SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		SoundAction.Sound = new class'SoundCue';
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2AvatarFX.Avatar_Ability_Dimensional_Rift_Collapse';
		SoundAction.bIsPositional = true;
		SoundAction.vWorldPosition = Context.InputContext.TargetLocations[0];

		// Play the Collapse FX
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		EffectAction.EffectName = "FX_Psi_Dimensional_Rift.P_Psi_Dimensional_Build_Up";
		EffectAction.EffectLocation = Context.InputContext.TargetLocations[0];
		EffectAction.bWaitForCompletion = false;
		EffectAction.bWaitForCameraCompletion = false;

		// Wait to time the start of the explosion FX
		WaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		WaitAction.DelayTimeSec = default.DIMENSIONAL_RIFT_STAGE2_START_EXPLOSION_FX_SEC;

		// Play the Explosion audio
		SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		SoundAction.Sound = new class'SoundCue';
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2AvatarFX.Avatar_Ability_Dimensional_Rift_Explode';
		SoundAction.bIsPositional = true;
		SoundAction.vWorldPosition = Context.InputContext.TargetLocations[0];

		// Play the Explosion FX
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		EffectAction.EffectName = "FX_Psi_Dimensional_Rift.P_Psi_Dimensional_Rift_Explosion";
		EffectAction.EffectLocation = Context.InputContext.TargetLocations[0];

		// Notify multi targets of explosion
		WaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(AvatarBuildTrack, Context));
		WaitAction.DelayTimeSec = default.DIMENSIONAL_RIFT_STAGE2_NOTIFY_TARGETS_SEC;
	}
	//****************************************************************************************

	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	for (i = 0; i < Context.InputContext.MultiTargets.Length; ++i)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[i];

		if( InteractingUnitRef == AvatarUnit.GetReference() )
		{
			ActionMetadata = AvatarBuildTrack;
		}
		else
		{
			ActionMetadata = EmptyTrack;
			ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
			ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
			ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
		}

		for( j = 0; j < Context.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			Context.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}

		TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}
	}

	//****************************************************************************************
	//Configure the visualization tracks for the environment
	//****************************************************************************************
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.VisualizeActor = none;
		ActionMetadata.StateObject_NewState = EnvironmentDamageEvent;
		ActionMetadata.StateObject_OldState = EnvironmentDamageEvent;

		//Wait until signaled by the shooter that the projectiles are hitting
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

		for( i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; ++i )
		{
			AbilityTemplate.AbilityMultiTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');	
		}

	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldDataUpdate)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.VisualizeActor = none;
		ActionMetadata.StateObject_NewState = WorldDataUpdate;
		ActionMetadata.StateObject_OldState = WorldDataUpdate;

		//Wait until signaled by the shooter that the projectiles are hitting
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

		for( i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; ++i )
		{
			AbilityTemplate.AbilityMultiTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');	
		}

	}
	//****************************************************************************************

	//Process any interactions with interactive objects
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		// Add any doors that need to listen for notification
		if( InteractiveObject.IsDoor() && InteractiveObject.HasDestroyAnim() && InteractiveObject.InteractionCount % 2 != 0 ) //Is this a closed door?
		{
			ActionMetadata = EmptyTrack;
			//Don't necessarily have a previous state, so just use the one we know about
			ActionMetadata.StateObject_OldState = InteractiveObject;
			ActionMetadata.StateObject_NewState = InteractiveObject;
			ActionMetadata.VisualizeActor = History.GetVisualizer(InteractiveObject.ObjectID);
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
			class'X2Action_BreakInteractActor'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

		}
	}

	TypicalAbility_AddEffectRedirects(VisualizeGameState, AvatarBuildTrack);

	VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', DamageActions);
	for (i = 0; i < DamageActions.Length; ++i)
	{
		VisualizationMgr.DisconnectAction(DamageActions[i]);
		VisualizationMgr.ConnectAction(DamageActions[i], VisualizationMgr.BuildVisTree, false, WaitAction);
	}

	DamageActions.Length = 0;
	VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToTerrain', DamageActions);
	for (i = 0; i < DamageActions.Length; ++i)
	{
		VisualizationMgr.DisconnectAction(DamageActions[i]);
		VisualizationMgr.ConnectAction(DamageActions[i], VisualizationMgr.BuildVisTree, false, WaitAction);
	}

	DamageActions.Length = 0;
	VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_BreakInteractActor', DamageActions);
	for (i = 0; i < DamageActions.Length; ++i)
	{
		VisualizationMgr.DisconnectAction(DamageActions[i]);
		VisualizationMgr.ConnectAction(DamageActions[i], VisualizationMgr.BuildVisTree, false, WaitAction);
	}
}

static function X2DataTemplate CreatePsiMindControlAbility(name AbilityName='PsiMindControl')
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_PerPlayerType Cooldown;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_UnitEffects EffectCondition;
	local X2Condition_UnitImmunities UnitImmunityCondition;
	local X2Effect_MindControl MindControlEffect;
	local X2Effect_RemoveEffects MindControlRemoveEffects;
	local X2AbilityTarget_Single SingleTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventpsiwitch_mindcontrol";
	Template.Hostility = eHostility_Offensive;
	Template.bShowActivation = true;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_PerPlayerType';
	Cooldown.iNumTurns = default.MIND_CONTROL_LOCAL_COOLDOWN_PLAYER;
	Cooldown.iNumTurnsForAI = default.MIND_CONTROL_LOCAL_COOLDOWN_AI;
	Cooldown.NumGlobalTurns = default.MIND_CONTROL_GLOBAL_COOLDOWN_AI;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StatCheck_UnitVsUnit';

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	EffectCondition = new class'X2Condition_UnitEffects';
	EffectCondition.AddExcludeEffect(class'X2Effect_MindControl'.default.EffectName, 'AA_UnitIsMindControlled');
	Template.AbilityShooterConditions.AddItem(EffectCondition);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	UnitImmunityCondition = new class'X2Condition_UnitImmunities';
	UnitImmunityCondition.AddExcludeDamageType('Mental');
	UnitImmunityCondition.bOnlyOnCharacterTemplate = true;
	Template.AbilityTargetConditions.AddItem(UnitImmunityCondition);

	EffectCondition = new class'X2Condition_UnitEffects';
	EffectCondition.AddExcludeEffect(class'X2Effect_MindControl'.default.EffectName, 'AA_UnitIsMindControlled');
	EffectCondition.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_CarryingUnit');
	Template.AbilityTargetConditions.AddItem(EffectCondition);

	// MindControl effect for 1 or more unblocked psi hit
	MindControlEffect = class'X2StatusEffects'.static.CreateMindControlStatusEffect(default.MIND_CONTROL_PLAYER_TURNS_DURATION);
	MindControlEffect.MinStatContestResult = 1;
	MindControlEffect.iNumTurnsForAI = default.MIND_CONTROL_AI_TURNS_DURATION;
	Template.AddTargetEffect(MindControlEffect);

	MindControlRemoveEffects = class'X2StatusEffects'.static.CreateMindControlRemoveEffects();
	MindControlRemoveEffects.MinStatContestResult = 1;
	Template.AddTargetEffect(MindControlRemoveEffects);
	// MindControl effect for 1 or more unblocked psi hit

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Unlike in other cases, in TypicalAbility_BuildVisualization, the MissSpeech is used on the Target!
	Template.TargetMissSpeech = 'SoldierResistsMindControl';

	Template.CustomFireAnim = 'HL_Psi_MindControl';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Psionic_FireAtUnit";

	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'PsiMindControl'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'PsiMindControl'

	return Template;
}

static function X2AbilityTemplate CreateAvatarInitializationAbility()
{
	local X2AbilityTemplate Template;
	local X2Effect_Regeneration RegenerationEffect;
	local X2Effect_DamageImmunity DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AvatarInitialization');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_mentalfortress"; 

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	
	Template.AdditionalAbilities.AddItem('AvatarImmunities');
	Template.AdditionalAbilities.AddItem('AvatarRegeneration');

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the regeneration effect
	RegenerationEffect = new class'X2Effect_Regeneration';
	RegenerationEffect.BuildPersistentEffect(1,  true, true, false, eGameRule_PlayerTurnBegin);
	RegenerationEffect.HealAmount = default.AVATAR_REGENERATION_HEAL_VALUE;
	RegenerationEffect.EventToTriggerOnHeal = 'AvatarInitializationHeal';
	Template.AddTargetEffect(RegenerationEffect);

	// Build the immunities
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, true, true);
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.DisorientDamageType);
	DamageImmunity.ImmuneTypes.AddItem('stun');
	DamageImmunity.ImmuneTypes.AddItem('Unconscious');
	DamageImmunity.EffectName = 'AvatarDamageImmunities';
	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreateTriggerDamagedTeleportListenerAbility( name TemplateName = 'TriggerDamagedTeleportListener', delegate<X2TacticalGameRulesetDataStructures.AbilityEventDelegate> EventListenerFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_DamagedTeleport)
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Effect_RunBehaviorTree DamageTeleportBehaviorEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.bDontDisplayInAbilitySummary = true;

	Template.AdditionalAbilities.AddItem('TriggerDamagedTeleport');

	// This ability fires when the unit takes damage
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitTakeEffectDamage';
	EventListener.ListenerData.EventFn = EventListenerFn;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AbilityTargetStyle = default.SelfTarget;

	DamageTeleportBehaviorEffect = new class'X2Effect_RunBehaviorTree';
	DamageTeleportBehaviorEffect.BehaviorTreeName = 'TryTriggerDamagedTeleport';
	Template.AddTargetEffect(DamageTeleportBehaviorEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreateTriggerDamagedTeleportAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local array<name> SkipExclusions;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'TriggerDamagedTeleport');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_codex_teleport";

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitMoveFinished';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_DamagedTeleport;
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.Priority = 10000;    // Really low priority to ensure other listeners occur before this one
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// The unit must be alive and not stunned
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeStunned = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	Template.bSkipFireAction = true;
	Template.ModifyNewContextFn = TriggerDamagedTeleport_ModifyActivatedAbilityContext;
	Template.BuildNewGameStateFn = TriggerDamagedTeleport_BuildGameState;
	Template.BuildVisualizationFn = TriggerDamagedTeleport_BuildVisualization;
	Template.CinescriptCameraType = "Avatar_TriggerDamagedTeleport";
//BEGIN AUTOGENERATED CODE: Template Overrides 'TriggerDamagedTeleport'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'TriggerDamagedTeleport'

	return Template;
}

simulated function TriggerDamagedTeleport_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateHistory History;
	local PathPoint NextPoint, EmptyPoint;
	local XGUnit UnitVisualizer;
	local PathingInputData InputData;
	local XComCoverPoint CoverPoint;
	local XComWorldData World;
	local TTile TempTile;
	local bool bCoverPointFound;

	History = `XCOMHISTORY;
	World = `XWORLD;

	AbilityContext = XComGameStateContext_Ability(Context);
	
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	// Build the MovementData for the path
	UnitVisualizer = XGUnit(UnitState.GetVisualizer());

	// First posiiton is the current location
	NextPoint.Position = UnitVisualizer.GetFootLocation();
	NextPoint.Traversal = eTraversal_Teleport;
	NextPoint.PathTileIndex = 0;
	InputData.MovementData.AddItem(NextPoint);

	TempTile = World.GetTileCoordinatesFromPosition(NextPoint.Position);
	InputData.MovementTiles.AddItem(TempTile);

	bCoverPointFound = UnitVisualizer.m_kBehavior.PickRandomCoverLocation(NextPoint.Position, default.TELEPORT_MIN_TILE_RADIUS, default.TELEPORT_MAX_TILE_RADIUS);
	TempTile = World.GetTileCoordinatesFromPosition(NextPoint.Position);

	if( !bCoverPointFound )
	{
		CoverPoint.TileLocation = World.FindClosestValidLocation(NextPoint.Position, false, false, false);
		TempTile = World.GetTileCoordinatesFromPosition(CoverPoint.TileLocation);
	}

	NextPoint = EmptyPoint;
	World.GetFloorPositionForTile(TempTile, NextPoint.Position);
	NextPoint.Traversal = eTraversal_Landing;
	NextPoint.PathTileIndex = 1;
	InputData.MovementData.AddItem(NextPoint);
	InputData.MovementTiles.AddItem(TempTile);

	//Now add the path to the input context
	InputData.MovingUnitRef = UnitState.GetReference();
	AbilityContext.InputContext.MovementPaths.AddItem(InputData);
}

simulated function XComGameState TriggerDamagedTeleport_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameState_Unit OldUnitState, UnitState;
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
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
	OldUnitState = UnitState;
	
	if( OldUnitState != none )
	{
		// Do TriggerDamagedTeleport
		LastElementIndex = AbilityContext.InputContext.MovementPaths[0].MovementData.Length - 1;

		// Set the unit's new location
		// The last position in MovementData will be the end location
		`assert(LastElementIndex > 0);
		NewLocation = AbilityContext.InputContext.MovementPaths[0].MovementData[LastElementIndex].Position;
		NewTileLocation = World.GetTileCoordinatesFromPosition(NewLocation);
		UnitState.SetVisibilityLocation(NewTileLocation);

		AbilityContext.ResultContext.bPathCausesDestruction = MoveAbility_StepCausesDestruction(UnitState, AbilityContext.InputContext, 0, LastElementIndex);
		MoveAbility_AddTileStateObjects(NewGameState, UnitState, AbilityContext.InputContext, 0, LastElementIndex);

		EventManager.TriggerEvent('ObjectMoved', UnitState, UnitState, NewGameState);
		EventManager.TriggerEvent('UnitMoveFinished', UnitState, UnitState, NewGameState);
	}

	//Return the game state we have created
	return NewGameState;
}

simulated function TriggerDamagedTeleport_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationActionMetadata EmptyTrack, ActionMetadata;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_MoveTurn MoveTurnAction;
	local int LastElementIndex;
	
	History = `XCOMHISTORY;

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
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Bad);

	// Turn to face the target action. The target location is the center of the ability's radius, stored in the 0 index of the TargetLocations
	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	LastElementIndex = AbilityContext.InputContext.MovementPaths[0].MovementData.Length - 1;
	MoveTurnAction.m_vFacePoint = AbilityContext.InputContext.MovementPaths[0].MovementData[LastElementIndex].Position;

	// move action
	class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, ActionMetadata);

	}

defaultproperties
{
	DelayedDimensionalRiftEffectName="DelayedDimensionalRiftEffect"
	DimensionalRiftTriggerName="DimensionalRiftTrigger"
	MindControlAbilityName="PsiMindControl"
	DimensionalRiftStage2Name="PsiDimensionalRiftStage2"
}
