class X2Ability_CarryUnit extends X2Ability
	config(GameCore);

var config float CARRY_UNIT_RANGE;
var config int CARRY_UNIT_MOBILITY_ADJUST;
var localized string CarryUnitEffectFriendlyName;
var localized string CarryUnitEffectFriendlyDesc;
var name CarryUnitEffectName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CarryUnit());
	Templates.AddItem(PutDownUnit());

	return Templates;
}

static function X2AbilityTemplate CarryUnit()
{
	local X2AbilityTemplate             Template;
	local X2Condition_UnitProperty      TargetCondition, ShooterCondition;
	local X2AbilityTarget_Single        SingleTarget;
	local X2AbilityTrigger_PlayerInput  PlayerInput;
	local X2Effect_PersistentStatChange CarryUnitEffect;
	local X2Effect_Persistent           BeingCarriedEffect;
	local X2Condition_UnitEffects       ExcludeEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CarryUnit');

	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); // Do not allow "Carrying" in MP!

	Template.AbilityCosts.AddItem(default.FreeActionCost);

	Template.AbilityToHitCalc = default.DeadEye;

	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	Template.AddShooterEffectExclusions();

	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.CanBeCarried = true;
	TargetCondition.ExcludeAlive = false;               
	TargetCondition.ExcludeDead = false;
	TargetCondition.ExcludeFriendlyToSource = false;
	TargetCondition.ExcludeHostileToSource = false;     
	TargetCondition.RequireWithinRange = true;
	TargetCondition.WithinRange = default.CARRY_UNIT_RANGE;
	Template.AbilityTargetConditions.AddItem(TargetCondition);

	// The target must not have a cocoon on top of it
	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Ability_ChryssalidCocoon'.default.GestationStage1EffectName, 'AA_UnitHasCocoonOnIt');
	ExcludeEffects.AddExcludeEffect(class'X2Ability_ChryssalidCocoon'.default.GestationStage2EffectName, 'AA_UnitHasCocoonOnIt');
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	PlayerInput = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(PlayerInput);

	Template.Hostility = eHostility_Neutral;

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_carry_unit";
	Template.CinescriptCameraType = "Soldier_CarryPickup";

	Template.ActivationSpeech = 'PickingUpBody';

	Template.BuildNewGameStateFn = CarryUnit_BuildGameState;
	Template.BuildVisualizationFn = CarryUnit_BuildVisualization;
	Template.BuildAppliedVisualizationSyncFn = CarryUnit_BuildAppliedVisualization;
	Template.BuildAffectedVisualizationSyncFn = CarryUnit_BuildAffectedVisualization;

	CarryUnitEffect = new class'X2Effect_PersistentStatChange';
	CarryUnitEffect.BuildPersistentEffect(1, true, true);
	CarryUnitEffect.SetDisplayInfo(ePerkBuff_Penalty, default.CarryUnitEffectFriendlyName, default.CarryUnitEffectFriendlyDesc, Template.IconImage, true);
	CarryUnitEffect.AddPersistentStatChange(eStat_Mobility, default.CARRY_UNIT_MOBILITY_ADJUST);
	CarryUnitEffect.DuplicateResponse = eDupe_Ignore;
	CarryUnitEffect.EffectName = default.CarryUnitEffectName;
	Template.AddShooterEffect(CarryUnitEffect);

	BeingCarriedEffect = new class'X2Effect_Persistent';
	BeingCarriedEffect.BuildPersistentEffect(1, true, true);
	BeingCarriedEffect.DuplicateResponse = eDupe_Ignore;
	BeingCarriedEffect.EffectName = class'X2AbilityTemplateManager'.default.BeingCarriedEffectName;
	BeingCarriedEffect.EffectAddedFn = BeingCarried_EffectAdded;
	Template.AddTargetEffect(BeingCarriedEffect);

	Template.AddAbilityEventListener('UnitMoveFinished', class'XComGameState_Ability'.static.CarryUnitMoveFinished, ELD_OnStateSubmitted);
	
	Template.bLimitTargetIcons = true; //When selected, show carry-able units, rather than typical targets

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

static function BeingCarried_EffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	`XWORLD.ClearTileBlockedByUnitFlag(XComGameState_Unit(kNewTargetState));
}

static function XComGameState CarryUnit_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameState_Unit SourceUnit, TargetUnit;
	local XComGameStateContext_Ability AbilityContext;
	local array<XComGameState_BaseObject> ComponentObjs;
	local int i;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);

	TypicalAbility_FillOutGameState(NewGameState);

	//	check for the target unit to be a mission objective, and if so, break concealment
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	`assert(SourceUnit != none && TargetUnit != none);

	if (SourceUnit.IsConcealed())
	{
		TargetUnit.GetAllComponentObjects(ComponentObjs);
		for (i = 0; i < ComponentObjs.Length; ++i)
		{
			if (XComGameState_ObjectiveInfo(ComponentObjs[i]) != none)
			{
				`XEVENTMGR.TriggerEvent('EffectBreakUnitConcealment', SourceUnit, SourceUnit, NewGameState);
				break;
			}
		}
	}

	return NewGameState;
}

simulated function CarryUnit_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local VisualizationActionMetadata	EmptyTrack;
	local VisualizationActionMetadata	ActionMetadata;

	local XComGameState_Ability Ability;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local XComGameState_Unit CarriedUnit;	

	local XComGameStateVisualizationMgr VisMgr;
	local X2Action_MarkerNamed JoinActions;
	local array<X2Action> LeafNodes;

	History = `XCOMHISTORY;
	VisMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());


	//Configure the visualization track for the target - target comes first since it sets the picked up unit into the correct animation state
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.PrimaryTarget.ObjectID);

	class'X2Action_GetPickedUp'.static.AddToVisualizationTree(ActionMetadata, Context, false, VisMgr.BuildVisTree);
	//****************************************************************************************

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.SourceObject.ObjectID);
	ActionMetadata.AdditionalVisualizeActors.AddItem(History.GetVisualizer(Context.InputContext.PrimaryTarget.ObjectID));

	class'X2Action_CarryUnitPickUp'.static.AddToVisualizationTree(ActionMetadata, Context, false, VisMgr.BuildVisTree);

	CarriedUnit = XComGameState_Unit(History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));

	if (CarriedUnit.GetMyTemplateName() == 'HostileVIPCivilian')
	{
		// The HostileVIP is a special case sound cue, eg "We've got the target in custody."
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HostileVip', eColor_Good);
	}
	else
	{
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", Ability.GetMyTemplate().ActivationSpeech, eColor_Good);
	}
	//****************************************************************************************

	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, LeafNodes);

	if( VisMgr.BuildVisTree.ChildActions.Length > 0 )
	{
		JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, none, LeafNodes));
		JoinActions.SetName("Join");
	}
}

simulated function CarryUnit_BuildAppliedVisualization(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
{
	if (EffectName == class'X2AbilityTemplateManager'.default.BeingCarriedEffectName)
	{
		class'X2Action_CarryUnitPickUp'.static.AddToVisualizationTree( ActionMetadata, VisualizeGameState.GetContext() );
	}
}

simulated function CarryUnit_BuildAffectedVisualization(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
{
	if (EffectName == class'X2AbilityTemplateManager'.default.BeingCarriedEffectName)
	{
		class'X2Action_GetPickedUp'.static.AddToVisualizationTree( ActionMetadata, VisualizeGameState.GetContext() );
	}
}

static function X2DataTemplate PutDownUnit()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2Condition_UnitProperty      TargetCondition, ShooterCondition;
	local X2AbilityTarget_Single        SingleTarget;
	local X2AbilityTrigger_PlayerInput  PlayerInput;
	local X2Effect_RemoveEffects        RemoveEffects;
	local array<name>                   SkipExclusions;
	local X2Condition_UnitValue			UnitValueCondition;
	local X2Effect_SetUnitValue         UnitValueEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PutDownUnit');

	ActionPointCost = new class 'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_UnblockedNeighborTile');

	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.BeingCarriedBySource = true;
	TargetCondition.ExcludeAlive = false;               
	TargetCondition.ExcludeDead = false;
	TargetCondition.ExcludeFriendlyToSource = false;
	TargetCondition.ExcludeHostileToSource = false;     
	Template.AbilityTargetConditions.AddItem(TargetCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	PlayerInput = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(PlayerInput);

	Template.Hostility = eHostility_Neutral;
	Template.CinescriptCameraType = "Soldier_CarryPutdown";

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_drop_unit";

	Template.ActivationSpeech = 'DroppingBody';

	Template.BuildNewGameStateFn = PutDownUnit_BuildGameState;
	Template.BuildVisualizationFn = PutDownUnit_BuildVisualization;

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.CarryUnitEffectName);
	Template.AddShooterEffect(RemoveEffects);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.bCleanse = true;
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
	Template.AddTargetEffect(RemoveEffects);

	// Special effects that get removed when being put down
	UnitValueCondition = new class'X2Condition_UnitValue';
	UnitValueCondition.AddCheckValue(class'X2Effect_SpawnShadowbindUnit'.default.ShadowbindUnconciousCheckName, 0, eCheck_GreaterThan);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.bCleanse = true;
	RemoveEffects.bDoNotVisualize = true;
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.UnconsciousName);
	RemoveEffects.TargetConditions.AddItem(UnitValueCondition);
	Template.AddTargetEffect(RemoveEffects);

	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = class'X2Effect_SpawnShadowbindUnit'.default.ShadowbindUnconciousCheckName;
	UnitValueEffect.NewValueToSet = 0;
	UnitValueEffect.TargetConditions.AddItem(UnitValueCondition);
	Template.AddTargetEffect(UnitValueEffect);
	// Special effects that get removed when being put down

	SkipExclusions.AddItem(default.CarryUnitEffectName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	Template.bLimitTargetIcons = true; //When selected, show only the unit we can put down, rather than typical targets

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

simulated function XComGameState PutDownUnit_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Unit SourceUnitState, TargetUnitState;
	local TTile NewTargetLocation;
	local Vector TargetedDirection;

	AbilityContext = XComGameStateContext_Ability(Context);
	`assert(AbilityContext != None);

	//Do all the normal effect processing
	NewGameState = TypicalAbility_BuildGameState(Context);

	SourceUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	`assert(SourceUnitState != None);

	//Find the targeted direction, to influence preferred tile
	//(currently not meaningful, but it's looking like this ability might need targeting)
	TargetedDirection = Normal(AbilityContext.InputContext.TargetLocations[0] - `XWORLD.GetPositionFromTileCoordinates(SourceUnitState.TileLocation));

	//Try to find a neighbor tile to drop the unit on - fall back to our own (shouldn't happen - we have a source condition for it)
	NewTargetLocation = SourceUnitState.TileLocation;
	if (!SourceUnitState.FindAvailableNeighborTileWeighted(TargetedDirection, NewTargetLocation)) //Try finding a weighted cardinal neighbor first, fall back to any neighbor otherwise
		SourceUnitState.FindAvailableNeighborTile(NewTargetLocation);

	//Move the target to their new tile
	TargetUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	`assert(TargetUnitState != None);

	TargetUnitState.SetVisibilityLocation(NewTargetLocation);

	return NewGameState;
}

simulated function PutDownUnit_BuildVisualization(XComGameState VisualizeGameState)
{

	local XComGameStateHistory History;
	local VisualizationActionMetadata	EmptyTrack;
	local VisualizationActionMetadata	ActionMetadata;
	local X2Action_MoveTurn MoveTurnAction;
	local XComGameState_Unit TargetUnitState;
	local int EffectIndex;
	local XComGameStateContext_Ability Context;
	local XComGameState_Ability Ability;
	local X2AbilityTemplate AbilityTemplate;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = Ability.GetMyTemplate();

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.SourceObject.ObjectID);

	//Face the desired target location first
	TargetUnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	MoveTurnAction.m_vFacePoint = `XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
	MoveTurnAction.ForceSetPawnRotation = true;

	//Then drop them there
	class'X2Action_CarryUnitPutDown'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", Ability.GetMyTemplate().ActivationSpeech, eColor_Good);
	//****************************************************************************************


	//Configure the visualization track for the target
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.PrimaryTarget.ObjectID);

	class'X2Action_GetPutDown'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

	// Get the visualization for the effect that was removed
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
	}
	//****************************************************************************************
}

DefaultProperties
{
	CarryUnitEffectName="CarryUnit"
}