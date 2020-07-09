//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext.uc
//  AUTHOR:  Ryan McFall  --  11/20/2013
//  PURPOSE: This is the base class and interface for XComGameStateContext related to an XComGameState.
//           
//           Examples of Input context data are: 
//              1. What ability was selected?
//              2. What unit initiated the ability
//              3. What were the intended targets?
//              4. If a move was performed, what was the intended destination?
//
//           Examples of Result context data are: 
//              1. Information about interrupts - how an interrupt occurred and what state
//                 objects were affected or caused the interrupt?
//              2. What vectors, hit locations were used to generate the changed object
//                 states via projectile impacts?
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_Ability extends XComGameStateContext dependson(XComPathData) native(core);

var AbilityInputContext     InputContext;
var AbilityResultContext    ResultContext;

// if true, skip the validation step on this ability context
var bool bSkipValidation;

var bool bSkipAdditionalVisualizationSteps;

struct native ActionSelection
{
	var AvailableAction PerformAction; 	// Encapsulates most of the information about what ability to perform, what entity is performing it, etc.
	var int AvailableTargetsIndex;	// An index into the AvailableTargets array inside PerformAction indicating which target to perform the action on
	var array<Vector> TargetLocations; // Some actions operate on 3d locations in-addition-to or instead-of targets, and this array sets them
	var X2TargetingMethod TargetingMethod;
	var array<TTile> PathTiles;
	var array<TTile> WaypointTiles;

	structdefaultproperties
	{
		AvailableTargetsIndex=INDEX_NONE
	}
};

var delegate<MergeVisualizationDelegate> MergeVisualizationFn;
delegate MergeVisualizationDelegate(X2Action BuildTree, out X2Action VisualizationTree);

function bool ShouldImmediateSelectNextTarget()
{
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local XComGameState_Unit TargetUnit;
	local StateObjectReference EffectRef;

	History = `XCOMHISTORY;

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(InputContext.PrimaryTarget.ObjectID));
	if( TargetUnit != None )
	{
		foreach TargetUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if( EffectState != None )
			{
				if( EffectState.GetX2Effect().ImmediateSelectNextTarget(self, TargetUnit) )
				{
					return true;
				}
			}
		}
	}

	return false;
}

//XComGameStateContext interface
//***************************************************
/// <summary>
/// Should return true if ContextBuildGameState can return a game state, false if not. Used internally and externally to determine whether a given context is
/// valid or not.
/// </summary>
function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	local XComGameState_Unit    AbilityUnit;
	local XComGameState_Unit    AbilityTargetUnit;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate     AbilityTemplate;
	local bool Revalidation;

	AbilityUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(InputContext.SourceObject.ObjectID));
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID));
	if( AbilityUnit != none && AbilityState != none )
	{
		if( AbilityState.CanActivateAbility(AbilityUnit, InInterruptionStatus) == 'AA_Success' )
		{
			AbilityTargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(InputContext.PrimaryTarget.ObjectID));
			AbilityTemplate = AbilityState.GetMyTemplate();

			Revalidation = InInterruptionStatus != eInterruptionStatus_None;
			if( AbilityTargetUnit != none && AbilityTemplate.CheckTargetConditions(AbilityState, AbilityUnit, AbilityTargetUnit, Revalidation) != 'AA_Success' )
			{
				return false;
			}
			
			if( AbilityTemplate.AbilityToHitCalc != none && AbilityTemplate.AbilityToHitCalc.NoGameStateOnMiss() )
			{
				return IsResultContextHit();
			}

			return true;
		}
	}

	return false;
}

/// <summary>
/// Handles housekeeping tasks after an ability's game-state delegate is called - fires events, increments counts, etc.
/// Called from either ContextBuildGameState for non-interrupted abilities, or from ContextBuildInterruptedGameState upon resuming an interrupted ability.
/// </summary>
function AbilityPostActivationUpdates(XComGameState NewGameState)
{
	local XComGameState_Player  SourcePlayerState;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit    SourceUnitState, TargetUnitState;
	local UnitValue             AttacksThisTurn, NonMoveActionsThisTurn, HitsTakenThisTurn;
	local X2AbilityTemplate     AbilityTemplate;
	local name                  PostActivationEventName;
	local int                   TargetIndex;
	local XComGameStateHistory  History;

	History = `XCOMHISTORY;

	SourceUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(InputContext.SourceObject.ObjectID));
	if (SourceUnitState == None)
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(InputContext.SourceObject.ObjectID));

	AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID));
	if (AbilityState == None)
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID));

	//This function is for successful activations of an ability - there really should be a source and ability!
	`assert(SourceUnitState != None);
	`assert(AbilityState != None);

	AbilityTemplate = AbilityState.GetMyTemplate();
	`assert(AbilityTemplate != None);

	//Increment counts of attacks / non-move-actions
	if (AbilityState.GetMyTemplate().Hostility == eHostility_Offensive && AbilityState.IsAbilityInputTriggered())
	{
		SourceUnitState.GetUnitValue('AttacksThisTurn', AttacksThisTurn);
		AttacksThisTurn.fValue += 1;
		SourceUnitState.SetUnitFloatValue('AttacksThisTurn', AttacksThisTurn.fValue, eCleanup_BeginTurn);

		//	increment hits this turn for all targets
		if (IsHitResultHit(ResultContext.HitResult) && (InputContext.PrimaryTarget.ObjectID > 0) && (InputContext.PrimaryTarget != InputContext.SourceObject))
		{
			TargetUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', InputContext.PrimaryTarget.ObjectID));
			if (TargetUnitState != none)
			{
				TargetUnitState.GetUnitValue('HitsTakenThisTurn', HitsTakenThisTurn);
				TargetUnitState.SetUnitFloatValue('HitsTakenThisTurn', HitsTakenThisTurn.fValue + 1, eCleanup_BeginTurn);
				HitsTakenThisTurn.fValue = 0;
			}
		}
		for (TargetIndex = 0; TargetIndex < ResultContext.MultiTargetHitResults.Length; ++TargetIndex)
		{
			if (IsHitResultHit(ResultContext.MultiTargetHitResults[TargetIndex]) && (InputContext.MultiTargets[TargetIndex] != InputContext.SourceObject))
			{
				TargetUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', InputContext.MultiTargets[TargetIndex].ObjectID));
				if (TargetUnitState != none)
				{
					TargetUnitState.GetUnitValue('HitsTakenThisTurn', HitsTakenThisTurn);
					TargetUnitState.SetUnitFloatValue('HitsTakenThisTurn', HitsTakenThisTurn.fValue + 1, eCleanup_BeginTurn);
					HitsTakenThisTurn.fValue = 0;
				}
			}
		}

	}
	if (AbilityState.GetMyTemplate().Hostility != eHostility_Movement && AbilityState.IsAbilityInputTriggered())
	{
		SourceUnitState.GetUnitValue('NonMoveActionsThisTurn', NonMoveActionsThisTurn);
		NonMoveActionsThisTurn.fValue += 1;
		SourceUnitState.SetUnitFloatValue('NonMoveActionsThisTurn', NonMoveActionsThisTurn.fValue, eCleanup_BeginTurn);
	}
		
	//Trigger post-activation events
	`XEVENTMGR.TriggerEvent('AbilityActivated', AbilityState, SourceUnitState, NewGameState);
	foreach AbilityTemplate.PostActivationEvents(PostActivationEventName)
	{
		`XEVENTMGR.TriggerEvent(PostActivationEventName, AbilityState, SourceUnitState, NewGameState);
	}

	// Codex/avatar golden path narrative triggers - any non passive, non post begin play triggered, ability used
	if (SourceUnitState.GetMyTemplate().CharacterGroupName == 'Cyberus' && !AbilityTemplate.bIsPassive && !AbilityTemplate.HasTrigger('X2AbilityTrigger_UnitPostBeginPlay'))
	{
		`XEVENTMGR.TriggerEvent('CodexFirstAction', AbilityState, SourceUnitState, NewGameState);
	}
	else if ((SourceUnitState.GetMyTemplate().CharacterGroupName == 'AdvPsiWitchM3' || SourceUnitState.GetMyTemplate().CharacterGroupName == 'AdvPsiWitchM2') && !AbilityTemplate.bIsPassive && !AbilityTemplate.HasTrigger('X2AbilityTrigger_UnitPostBeginPlay'))
	{
		`XEVENTMGR.TriggerEvent('AvatarFirstAction', AbilityState, SourceUnitState, NewGameState);
	}

	SourcePlayerState = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', SourceUnitState.GetAssociatedPlayerID()));
	if( AbilityState.IsAbilityInputTriggered() )
	{
		++SourcePlayerState.ActionsTakenThisTurn;
	}

	// update Miss Streak on the player if the ability missed
	if (AbilityTemplate.Hostility == eHostility_Offensive)
	{
		if (SourceUnitState != None)
		{
			if (IsHitResultHit(ResultContext.HitResult))
			{
				// reset the miss streak on a hit
				SourcePlayerState.MissStreak = 0;

				// increment the hit streak on a hit
				++SourcePlayerState.HitStreak;
			}
			else
			{
				// increment the miss streak on a miss
				if( ResultContext.CalculatedHitChance >= class'X2AbilityToHitCalc_StandardAim'.default.ReasonableShotMinimumToEnableAimAssist )
				{
					++SourcePlayerState.MissStreak;
				}

				// reset hit streak on a miss
				SourcePlayerState.HitStreak = 0;
			}
		}
	}

	//  look for lightning reflexes to unflag the unit
	if (ResultContext.HitResult == eHit_LightningReflexes)
	{
		TargetUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', InputContext.PrimaryTarget.ObjectID));
		TargetUnitState.bLightningReflexes = false;
	}
	//  look for multi target lightning reflexes (unlikely!)
	for (TargetIndex = 0; TargetIndex < ResultContext.MultiTargetHitResults.Length; ++TargetIndex)
	{
		if (ResultContext.MultiTargetHitResults[TargetIndex] == eHit_LightningReflexes)
		{
			TargetUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', InputContext.MultiTargets[TargetIndex].ObjectID));
			TargetUnitState.bLightningReflexes = false;
		}
	}

	//  look for untouchable to countdown the unit
	if (ResultContext.HitResult == eHit_Untouchable)
	{
		TargetUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', InputContext.PrimaryTarget.ObjectID));
		TargetUnitState.Untouchable -= 1;
	}
	//  look for multi target untouchables
	for (TargetIndex = 0; TargetIndex < ResultContext.MultiTargetHitResults.Length; ++TargetIndex)
	{
		if (ResultContext.MultiTargetHitResults[TargetIndex] == eHit_Untouchable)
		{
			TargetUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', InputContext.MultiTargets[TargetIndex].ObjectID));
			TargetUnitState.Untouchable -= 1;
		}
	}
}

/// <summary>
/// Override in concrete classes to converts the InputContext into an XComGameState
/// </summary>
function XComGameState ContextBuildGameState()
{	
	//The state and results associated with this context object
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate     AbilityTemplate;
	local XComGameState         NewGameState;
	local XComGameStateHistory	History;

	if( bSkipValidation || Validate() )
	{
		History = `XCOMHISTORY;
	
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();
		NewGameState = AbilityTemplate.BuildNewGameStateFn(self);

		// additional state manipulation for all ability-constructed game states
		AbilityPostActivationUpdates(NewGameState);
	}

	return NewGameState;
}

function FillEffectsForReplay()
{
	local X2AbilityTemplate AbilityTemplate;
	local int x, y;

	// these effect references are not maintained across the save/load boundry.  Regular save/load doesn't really need them but replay really does
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager( ).FindAbilityTemplate( InputContext.AbilityTemplateName );
	if (AbilityTemplate != none)
	{
		ResultContext.ShooterEffectResults.Effects.Length = AbilityTemplate.AbilityShooterEffects.Length;
		for (x = 0; x < AbilityTemplate.AbilityShooterEffects.Length; ++x)
		{
			ResultContext.ShooterEffectResults.Effects[x] = AbilityTemplate.AbilityShooterEffects[x];
		}

		ResultContext.TargetEffectResults.Effects.Length = AbilityTemplate.AbilityTargetEffects.Length;
		for (x = 0; x < AbilityTemplate.AbilityTargetEffects.Length; ++x)
		{
			ResultContext.TargetEffectResults.Effects[ x ] = AbilityTemplate.AbilityTargetEffects[ x ];
		}

		for (y = 0; y < ResultContext.MultiTargetEffectResults.Length; ++y)
		{
			ResultContext.MultiTargetEffectResults[y].Effects.Length = AbilityTemplate.AbilityMultiTargetEffects.Length;
			for (x = 0; x < AbilityTemplate.AbilityMultiTargetEffects.Length; ++x)
			{
				ResultContext.MultiTargetEffectResults[y].Effects[x] = AbilityTemplate.AbilityMultiTargetEffects[x];
			}
		}
	}
}

function OnSubmittedToReplay(XComGameState SubmittedGameState)
{
	local XComTacticalController TacticalController;
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Concealment must be updated on ability use
	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	TacticalController.m_kPathingPawn.MarkAllConcealmentCachesDirty();

	FillEffectsForReplay();

	foreach SubmittedGameState.IterateByClassType( class'XComGameState_Unit', UnitState )
	{
		if (!UnitState.GetMyTemplate( ).bIsCosmetic)
		{
			if (!UnitState.bRemovedFromPlay && (!UnitState.IsDead() || UnitState.BlocksPathingWhenDead()))
			{
				`XWORLD.SetTileBlockedByUnitFlag(UnitState);
			}
			else
			{
				`XWORLD.ClearTileBlockedByUnitFlag(UnitState);
			}
		}
	}

	if (InputContext.AbilityTemplateName == 'StandardMove')
	{
		AbilityState = XComGameState_Ability(SubmittedGameState.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID));
		if (AbilityState == None)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID));
		}

		// In the interest of not breaking anything, adding this here so the X2Camera_FollowMouseCursor can be made aware of moves during the tutorial
		`XEVENTMGR.TriggerEvent('AbilityActivated', AbilityState, UnitState, SubmittedGameState);
	}
}

/// <summary>
/// Override in concrete classes to support interruptions which occur mid state change. 
///
/// For example: 
/// 1. Some abilities, when interrupted, might apply the cost of performing the ability but not apply the effects. An ability of this type might have 1
///    interrupt step.
/// 2. Other abilities, like movement, have many interrupt steps - one for each tile the unit enters during the move. The output of each interrupt step
///    (provided by the move ability delegate 'InterruptHandlingFn') is a game state where the unit is located at the interruption tile instead of its 
///    intended destination.
/// </summary>
///<param name="InterruptStep"></param>
function XComGameState ContextBuildInterruptedGameState(int InterruptStep, EInterruptionStatus InInterruptionStatus)
{
	local XComGameState_Ability         AbilityState;
	local X2AbilityTemplate             AbilityTemplate;		
	local XComGameState                 InterruptGameState;	
	local XComGameState_Unit            SourceUnitState;
	local XComGameStateHistory          History;

	if( bSkipValidation || Validate(InInterruptionStatus) )
	{
		History = `XCOMHISTORY;
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();

		//If the ability does not implement InterruptHandlingFn, it cannot be interrupted
		if( AbilityTemplate.BuildInterruptGameStateFn != none )
		{
			InterruptGameState = AbilityTemplate.BuildInterruptGameStateFn(self, InterruptStep, InInterruptionStatus);

			if (InterruptGameState != None)
			{
				if (InInterruptionStatus == eInterruptionStatus_Resume)
				{
					AbilityPostActivationUpdates(InterruptGameState);
				}
				else
				{
					//We need to trigger AbilityActivated on each step, because that could cause interrupts in the first place
					SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(InputContext.SourceObject.ObjectID));
					`XEVENTMGR.TriggerEvent('AbilityActivated', AbilityState, SourceUnitState, InterruptGameState);
				}
			}
		}
	}

	return InterruptGameState;
}

/// <summary>
/// Adds a track to play an artist defined Cinescript camera during the ability, if one exists.
/// </summary>
private function InsertCinescriptCamera(X2AbilityTemplate AbilityTemplate, out VisualizationActionMetadata ActionMetaData, XComGameStateContext Context,
	out X2Action InOutStartNode, out X2Action InOutEndNode)
{
	local XComGameStateHistory History;
	local XComGameState_Unit SourceUnit;
	local XGUnit UnitVisualizer;
	local X2Camera_Cinescript CinescriptCamera;
	local X2Action_StartCinescriptCamera CinescriptStartAction;
	local X2Action_EndCinescriptCamera CinescriptEndAction;
	local XComWorldData WorldData;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local array<X2Action> OutActions;
	local X2Action_ExitCover ExitCoverAction;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(InputContext.SourceObject.ObjectID));
	if(SourceUnit.GetMyTemplate().bIsCosmetic) return; // cosmetic units should rely on their owner's camera

	// civilians don't need camera actions and it's easy to get some bad start/stops messing with the camera we do want for our xcom soldier.
	if (SourceUnit.GetTeam() == eTeam_Neutral && !SourceUnit.GetMyTemplate().bIsAlien) //But allow faceless through
		return;

	UnitVisualizer = XGUnit(ActionMetaData.VisualizeActor);
	if (UnitVisualizer == none || !UnitVisualizer.IsVisibleToTeam(eTeam_XCom))
	{
		// If we have a movement path and its not visible to XCom, we don't want to do a glam cam.
		if (InputContext.MovementPaths.Length > 0)
		{
			if (!MovementPathVisible())
			{
				// We have movement, but none of the path is visible to us, no glam cam for you
				return;
			}
		}
		else
		{
			WorldData = `XWORLD;

			// We're not visible, and there is no movement, check if the tile is visible
			if (!WorldData.IsLocationVisibleToTeam(UnitVisualizer.Location, eTeam_XCom))
			{
				// No glam cam for you
				return;
			}
		}
	}

	// hacky; see note in ExitCover
	if( AbilityTemplate.DataName == 'LostAttack' )
	{
		return;
	}

	// try to find a cinescript camera for this ability
	CinescriptCamera = class'X2Camera_Cinescript'.static.CreateCinescriptCameraForAbility(self);
	
	// if the unit will stepout, then by default stop the targeting camera/start cinescript when it is done	
	if (CinescriptCamera == none)
	{	
		// no cinescript camera, so just remove the targeting camera. Parent to the root of the tree
		class'X2Action_RemoveTargetingCamera'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutStartNode);
	}
	else
	{	
		VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_ExitCover', OutActions, ActionMetaData.VisualizeActor);
		if (OutActions.Length > 0)
		{
			ExitCoverAction = X2Action_ExitCover(OutActions[0]);

			// if the cinescript camera requests an early start, allow it to go before the stepout completes 			
			if (CinescriptCamera.CameraDefinition.StartBeforeStepout)
			{
				//Parent to the step out's parents if we should occur prior
				CinescriptStartAction = X2Action_StartCinescriptCamera(class'X2Action_StartCinescriptCamera'.static.AddToVisualizationTree(ActionMetaData, Context, true, none, ExitCoverAction.ParentActions));
			}
			else
			{
				//Parent to the step out if we should occur after
				CinescriptStartAction = X2Action_StartCinescriptCamera(class'X2Action_StartCinescriptCamera'.static.AddToVisualizationTree(ActionMetaData, Context, true, ExitCoverAction));
			}			
		}
		else
		{	
			CinescriptStartAction = X2Action_StartCinescriptCamera(class'X2Action_StartCinescriptCamera'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutStartNode));
			InOutStartNode = CinescriptStartAction;
		}
				
		CinescriptEndAction = X2Action_EndCinescriptCamera(class'X2Action_EndCinescriptCamera'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutEndNode));

		CinescriptStartAction.CinescriptCamera = CinescriptCamera;
		CinescriptEndAction.CinescriptCamera = CinescriptCamera;
	}
}

private function ProcessGameplayEffects(XComGameState VisualizeState)
{
	local int Index;
	local XComGameStateContext_Ability VisualizeAbilityContext;
	local XComGameStateHistory LocalHistory;
	local VisualizationActionMetadata EmptyMetaData;
	local VisualizationActionMetadata ActionMetaData;

	VisualizeAbilityContext = XComGameStateContext_Ability(VisualizeState.GetContext());
	if (VisualizeAbilityContext == None)
	{
		VisualizeAbilityContext = self;
	}

	LocalHistory = `XCOMHISTORY;
	
	//Add visualizers for effects applied to the primary target
	ActionMetaData = EmptyMetaData;
	ActionMetaData.VisualizeActor = LocalHistory.GetVisualizer(VisualizeAbilityContext.InputContext.PrimaryTarget.ObjectID);
	if (ActionMetaData.VisualizeActor != none)
	{
		ActionMetaData.StateObject_NewState = LocalHistory.GetGameStateForObjectID(VisualizeAbilityContext.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference, VisualizeAbilityContext.AssociatedState.HistoryIndex);
		ActionMetaData.StateObject_OldState = LocalHistory.GetGameStateForObjectID(VisualizeAbilityContext.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference, VisualizeAbilityContext.AssociatedState.HistoryIndex - 1);
		ActionMetaData.StateObjectRef = VisualizeAbilityContext.InputContext.PrimaryTarget;
		EffectsModifyTracks(VisualizeState, VisualizeAbilityContext.ResultContext.TargetEffectResults, ActionMetaData);
	}

	//Add visualizers for effects applied to the source of the ability
	ActionMetaData = EmptyMetaData;
	ActionMetaData.VisualizeActor = LocalHistory.GetVisualizer(VisualizeAbilityContext.InputContext.SourceObject.ObjectID);
	if (ActionMetaData.VisualizeActor != none)
	{
		ActionMetaData.StateObject_NewState = LocalHistory.GetGameStateForObjectID(VisualizeAbilityContext.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeAbilityContext.AssociatedState.HistoryIndex);
		ActionMetaData.StateObject_OldState = LocalHistory.GetGameStateForObjectID(VisualizeAbilityContext.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeAbilityContext.AssociatedState.HistoryIndex - 1);
		ActionMetaData.StateObjectRef = VisualizeAbilityContext.InputContext.SourceObject;
		EffectsModifyTracks(VisualizeState, VisualizeAbilityContext.ResultContext.ShooterEffectResults, ActionMetaData);
	}

	//Add visualizers for effects applied to multiple targets
	for (Index = 0; Index < VisualizeAbilityContext.ResultContext.MultiTargetEffectResults.Length; ++Index)
	{
		ActionMetaData = EmptyMetaData;
		ActionMetaData.VisualizeActor = LocalHistory.GetVisualizer(VisualizeAbilityContext.InputContext.MultiTargets[Index].ObjectID);
		if (ActionMetaData.VisualizeActor != none)
		{
			ActionMetaData.StateObject_NewState = LocalHistory.GetGameStateForObjectID(VisualizeAbilityContext.InputContext.MultiTargets[Index].ObjectID, eReturnType_Reference, VisualizeAbilityContext.AssociatedState.HistoryIndex);
			ActionMetaData.StateObject_OldState = LocalHistory.GetGameStateForObjectID(VisualizeAbilityContext.InputContext.MultiTargets[Index].ObjectID, eReturnType_Reference, VisualizeAbilityContext.AssociatedState.HistoryIndex - 1);
			ActionMetaData.StateObjectRef = VisualizeAbilityContext.InputContext.MultiTargets[Index];
			EffectsModifyTracks(VisualizeState, VisualizeAbilityContext.ResultContext.MultiTargetEffectResults[Index], ActionMetaData);
		}
	}	
}

private function EffectsModifyTracks(XComGameState VisualizeState, EffectResults ResultEffects, out VisualizationActionMetadata ActionMetaData)
{
	local int Index;
	local X2Effect_Persistent PersistentEffect;

	for( Index = 0; Index < ResultEffects.Effects.Length; ++Index )
	{
		PersistentEffect = X2Effect_Persistent(ResultEffects.Effects[Index]); 
		if( (PersistentEffect != None) && (PersistentEffect.ModifyTracksFn != none))
		{
			PersistentEffect.ModifyTracksFn(VisualizeState, ActionMetaData, ResultEffects.ApplyResults[Index]);
		}
	}
}

/// <summary>
/// Adds a track to play an artist defined Cinescript camera during the ability, if one exists.
/// </summary>
private function InsertAbilityPerkEvents(X2AbilityTemplate AbilityTemplate, out VisualizationActionMetadata ActionMetaData, XComGameStateContext Context,
	out X2Action InOutStartNode, out X2Action InOutEndNode)
{
	local XComGameStateVisualizationMgr VisualizationMgr;
	local array<X2Action> Nodes; //Node storage
	local X2Action_AbilityPerkStart PerkStart;
	
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	if (AbilityTemplate.bSkipPerkActivationActions || ActionMetaData.VisualizeActor == none)
	{
		return;
	}

	InOutStartNode = class'X2Action_AbilityPerkStart'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutStartNode);
	VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_Fire', Nodes);
	PerkStart = X2Action_AbilityPerkStart(InOutStartNode);
	PerkStart.TrackHasNoFireAction = Nodes.Length == 0;

	//Since this is the first of the "bookend" actions to be added, we are parented to whatever parents the end node has. Subsequent actions will use this node a their parent
	InOutEndNode = class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTree(ActionMetaData, Context, true, none, InOutEndNode.ParentActions);
}

/// <summary>
/// Adds a track that removes fog around the ability initiator before the ability begins
/// </summary>
private function X2Action InsertAbilityFOWRevealArea(X2AbilityTemplate AbilityTemplate, out VisualizationActionMetadata ActionMetaData, XComGameStateContext Context,
	out X2Action InOutStartNode, out X2Action InOutEndNode)
{
	local XGUnit UnitVisualizer;
	local X2Action_RevealArea RevealAreaAction; 
	local XComGameStateContext_Ability VisualizeAbilityContext;
	local int Index;
	local XComGameStateHistory LocalHistory;
	local bool bIsTeleporting;
	local array<X2Action> Nodes;
	local XComGameStateVisualizationMgr VisualizationMgr;

	UnitVisualizer = XGUnit(ActionMetaData.VisualizeActor);

	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	VisualizationMgr.GetNodesOfType(VisualizationMgr.BuildVisTree, class'X2Action_MoveTeleport', Nodes);
	bIsTeleporting = Nodes.Length > 0;

	if( AbilityTemplate.bFrameEvenWhenUnitIsHidden && !bIsTeleporting)
	{
		if( UnitVisualizer != none && !UnitVisualizer.IsVisible() )
		{
			InOutStartNode = class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutStartNode);
			RevealAreaAction = X2Action_RevealArea(InOutStartNode);
			RevealAreaAction.bUseCurrentVisualizerLoc = true;
			RevealAreaAction.AssociatedObjectID = UnitVisualizer.ObjectID;
			RevealAreaAction.ScanningRadius = class'XComWorldData'.const.WORLD_StepSize * 4;
			RevealAreaAction.bDestroyViewer = false;

			InOutEndNode = class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutEndNode);
			RevealAreaAction = X2Action_RevealArea(InOutEndNode);
			RevealAreaAction.AssociatedObjectID = UnitVisualizer.ObjectID;
			RevealAreaAction.bDestroyViewer = true;
		}

		VisualizeAbilityContext = XComGameStateContext_Ability(Context);
		if( VisualizeAbilityContext == None )
		{
			VisualizeAbilityContext = self;
		}
		LocalHistory = `XCOMHISTORY;

		if( VisualizeAbilityContext.InputContext.PrimaryTarget.ObjectID > 0 )
		{
			UnitVisualizer = XGUnit(LocalHistory.GetVisualizer(VisualizeAbilityContext.InputContext.PrimaryTarget.ObjectID));

			if( UnitVisualizer != none && !UnitVisualizer.IsVisible() )
			{
				InOutStartNode = class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutStartNode);
				RevealAreaAction = X2Action_RevealArea(InOutStartNode);
				RevealAreaAction.bUseCurrentVisualizerLoc = true;
				RevealAreaAction.AssociatedObjectID = UnitVisualizer.ObjectID;
				RevealAreaAction.ScanningRadius = class'XComWorldData'.const.WORLD_StepSize * 4;
				RevealAreaAction.bDestroyViewer = false;

				InOutEndNode = class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutEndNode);
				RevealAreaAction = X2Action_RevealArea(InOutEndNode);
				RevealAreaAction.AssociatedObjectID = UnitVisualizer.ObjectID;
				RevealAreaAction.bDestroyViewer = true;
			}
		}

		for( Index = 0; Index < VisualizeAbilityContext.ResultContext.MultiTargetEffectResults.Length; ++Index )
		{
			UnitVisualizer = XGUnit(LocalHistory.GetVisualizer(VisualizeAbilityContext.InputContext.MultiTargets[Index].ObjectID));

			if( UnitVisualizer != none && !UnitVisualizer.IsVisible() )
			{
				InOutStartNode = class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutStartNode);
				RevealAreaAction = X2Action_RevealArea(InOutStartNode);
				RevealAreaAction.bUseCurrentVisualizerLoc = true;
				RevealAreaAction.AssociatedObjectID = UnitVisualizer.ObjectID;
				RevealAreaAction.ScanningRadius = class'XComWorldData'.const.WORLD_StepSize * 4;
				RevealAreaAction.bDestroyViewer = false;

				InOutEndNode = class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutEndNode);
				RevealAreaAction = X2Action_RevealArea(InOutEndNode);
				RevealAreaAction.AssociatedObjectID = UnitVisualizer.ObjectID;
				RevealAreaAction.bDestroyViewer = true;
			}
		}
	}

	return RevealAreaAction;
}

/// <summary>
/// Adds a track that Adds a flyover on the source unit, captioning the ability
/// </summary>
private function InsertAbilityFlyoverCaption(X2AbilityTemplate AbilityTemplate, out VisualizationActionMetadata ActionMetaData, XComGameStateContext Context,
													 out X2Action InOutStartNode, out X2Action InOutEndNode)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameState_Item SourceWeapon;
	local X2GrenadeTemplate GrenadeTemplate;
	local XComGameStateHistory History;
	local XComGameState_Unit SourceUnit;
	local bool bGoodAbility;

	if( ActionMetaData.VisualizeActor == none )
	{
		return;
	}

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ActionMetaData.StateObjectRef.ObjectID));
	bGoodAbility = SourceUnit.IsFriendlyToLocalPlayer();

	if( AbilityTemplate.bShowActivation || AbilityTemplate.ActivationSpeech != '' )
	{
		InOutStartNode = class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutStartNode);
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(InOutStartNode);

		SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(XComGameStateContext_Ability(Context).InputContext.ItemObject.ObjectID));
		if( SourceWeapon != None )
		{
			GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());
		}

		if( GrenadeTemplate != none )
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", GrenadeTemplate.OnThrowBarkSoundCue, bGoodAbility ? eColor_Good : eColor_Bad);
		}
		else
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.bShowActivation ? AbilityTemplate.LocFriendlyName : "", AbilityTemplate.ActivationSpeech, bGoodAbility ? eColor_Good : eColor_Bad, AbilityTemplate.bShowActivation ? AbilityTemplate.IconImage : "");
		}
	}

	if( AbilityTemplate.bShowPostActivation )
	{
		InOutEndNode = class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutEndNode);
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(InOutEndNode);

		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFriendlyName, '', bGoodAbility ? eColor_Good : eColor_Bad, AbilityTemplate.IconImage);
	}
}

/// <summary>
/// Adds a track that ensures the ability initiator is in view before the ability begins
/// </summary>
private function InsertSourceUnitLookAtAction(X2AbilityTemplate AbilityTemplate, out VisualizationActionMetadata ActionMetaData, XComGameStateContext Context,
	out X2Action InOutStartNode, out X2Action InOutEndNode)
{
	local XGUnit UnitVisualizer;
	local X2Action_CameraLookAt LookAtAction;
	local XComGameState_Unit SourceUnitState;	

	SourceUnitState = XComGameState_Unit(AssociatedState.GetGameStateForObjectID(InputContext.SourceObject.ObjectID));
	if( SourceUnitState.IsPlayerControlled() || !ShouldFrameAbility() )
	{
		return;
	}

	// If we don't have a visualizer at this point, we want to focus on the source unit
	if (UnitVisualizer == none)
	{
		UnitVisualizer = XGUnit(SourceUnitState.GetVisualizer());
	}

	if(UnitVisualizer != none && (UnitVisualizer.IsVisible() || AbilityTemplate.bFrameEvenWhenUnitIsHidden))
	{		
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetaData, Context, true, InOutStartNode));
		InOutStartNode = LookAtAction;
		LookAtAction.LookAtActor = UnitVisualizer;
		LookAtAction.BlockUntilActorOnScreen = true;

		if (UnitVisualizer.TargetingCamera != none && UnitVisualizer.TargetingCamera.IsA('X2Camera_OTSTargeting'))
		{
			LookAtAction.BlockUntilFinished = false;
		}
		else
		{
			LookAtAction.BlockUntilFinished = true;
		}

		LookAtAction.UseTether = false;

		// self-targeted abilities don't need as much (if any) delay as abilities where the camera is
		// going to move again to frame the ability
		if (InputContext.TargetLocations.Length == 0
			&& InputContext.MultiTargets.Length == 0
			&& (InputContext.PrimaryTarget.ObjectID <= 0 || InputContext.PrimaryTarget.ObjectID == InputContext.SourceObject.ObjectID))
		{
			// this ability has no non-source targets, so use the self target delay
			LookAtAction.LookAtDuration = class'X2Action_CameraLookAt'.default.SelfTargetLookAtDuration;
		}
		else
		{
			// the camera is going to move again to frame the ability, so use the multitarget delay
			LookAtAction.LookAtDuration = class'X2Action_CameraLookAt'.default.MultiTargetLookAtDuration;
		}
	}
}

simulated function bool MovementPathVisible()
{
	local int NumPathTiles;
	local bool bMoveVisible;
	local int TileIndex;
	local int LocalPlayerID;
	local int MovementPathIndex; //Index in the MovementPaths array - supporting multiple paths for a single ability context
	local XComGameState_Unit UnitState, MovingUnitState;
	local XComGameState_Item ItemState;
	local XGUnit Unit;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(InputContext.SourceObject.ObjectID, , AssociatedState.HistoryIndex));
	Unit = XGUnit(UnitState.GetVisualizer());

	if (Unit != none)
	{
		LocalPlayerID = `TACTICALRULES.GetLocalClientPlayerObjectID();
		MovementPathIndex = GetMovePathIndex(Unit.ObjectID);

		// Handle movement of other units (i.e. TeleportAlly ability)
		if (MovementPathIndex == -1)
		{
			MovingUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(InputContext.MovementPaths[0].MovingUnitRef.ObjectID, , AssociatedState.HistoryIndex));
			if (MovingUnitState != None)
			{
				UnitState = MovingUnitState;
				MovementPathIndex = 0;
			}
		}

		if (MovementPathIndex == -1) // if the source isn't there, maybe the item used is (such as in the case of Gremlins)
		{
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(InputContext.ItemObject.ObjectID, , AssociatedState.HistoryIndex));
			MovementPathIndex = GetMovePathIndex(ItemState.CosmeticUnitRef.ObjectID);
			`assert( MovementPathIndex != -1 );
		}

		NumPathTiles = ResultContext.PathResults[MovementPathIndex].PathTileData.Length;
		bMoveVisible = UnitState.ControllingPlayer.ObjectID == LocalPlayerID; //If this is the local player, the moves are always visible
		for (TileIndex = 0; TileIndex < NumPathTiles && !bMoveVisible; ++TileIndex)
		{
			if (ResultContext.PathResults[MovementPathIndex].PathTileData[TileIndex].NumLocalViewers > 0)
			{
				bMoveVisible = true;
			}
		}
	}

	return bMoveVisible;
}

function bool ShouldFrameAbility()
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit SourceUnitState;
	local StateObjectReference TargetObjectReference;
	local X2AbilityTemplate AbilityTemplate;
	local X2TacticalGameRuleset Rules;

	if( ShouldImmediateSelectNextTarget() )
	{
		return false;
	}

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(InputContext.AbilityRef.ObjectID));
	SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(InputContext.SourceObject.ObjectID));
	AbilityTemplate = AbilityState.GetMyTemplate();

	// if this ability has a movement portion, then don't frame it. Let the movement camera be in charge
 	if(InputContext.MovementPaths.Length > 0)
 	{
		// If the movement path is visible, the moving camera will frame, otherwise we might need to frame the ability if its happening to civilians in the FOW
		if (MovementPathVisible())
		{
			return false;
		}
 	}

	if(class'XComTacticalGRI'.static.GetReactionFireSequencer().IsReactionFire(self))
	{
		return false;
	}

	switch (AbilityTemplate.FrameAbilityCameraType)
	{
	case eCameraFraming_Never:
		return false;

	case eCameraFraming_IfNotNeutral:
		if(SourceUnitState.GetTeam() == eTeam_Neutral)
		{
			return false;
		}
		break;
	}

	// if the source unit and all target units are not actually visible to the local player in a multiplayer match, then don't frame the ability
	Rules = `TACTICALRULES;
	if(X2TacticalMPGameRuleset(Rules) != none) // not the cleanest, but safe. Can't break single player this way
	{
		History = `XCOMHISTORY;
		if(!class'X2TacticalVisibilityHelpers'.static.IsUnitVisibleToLocalPlayer(InputContext.SourceObject.ObjectID, AssociatedState.HistoryIndex))
		{
			return false;
		}

		if(XComGameState_Unit(History.GetGameStateForObjectID(InputContext.PrimaryTarget.ObjectID,, AssociatedState.HistoryIndex)) != none
			&& !class'X2TacticalVisibilityHelpers'.static.IsUnitVisibleToLocalPlayer(InputContext.PrimaryTarget.ObjectID, AssociatedState.HistoryIndex))
		{
			return false;
		}

		foreach InputContext.MultiTargets(TargetObjectReference)
		{
			if(TargetObjectReference.ObjectID != InputContext.PrimaryTarget.ObjectID
				&& XComGameState_Unit(History.GetGameStateForObjectID(TargetObjectReference.ObjectID,, AssociatedState.HistoryIndex)) != none
				&& !class'X2TacticalVisibilityHelpers'.static.IsUnitVisibleToLocalPlayer(TargetObjectReference.ObjectID, AssociatedState.HistoryIndex))
			{
				return false;
			}
		}
	}

	return true;
}

/// <summary>
/// Override in concrete classes to convert the ResultContext and AssociatedState into a set of visualization tracks
/// </summary>
protected function ContextBuildVisualization()
{
	local XComGameStateHistory History;
	local VisualizationActionMetadata ActionMetadata;

	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState VisualizeState;		
	local XComGameStateContext_Ability VisualizeAbilityContext;	
	local X2Action StartNode;
	local X2Action EndNode;
	local array<X2Action> Nodes;		
	local XComGameStateVisualizationMgr VisualizationMgr;	

	History = `XCOMHISTORY;	
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(InputContext.AbilityTemplateName);
	
	// This can happen legitimately if we are playing a replay, but abilities were modified/removed. Removed assert in favor of returning.
	if (AbilityTemplate == none)
		return;

	//Only the first state of an interrupt chain is expected to produce visualizations, as the visualization is the idealized "what this ability tried to do" 
	//sequence of actions. Subsequent interruption visualization processing will modify the visualization tree as needed.
	if (InterruptionHistoryIndex == -1 && AbilityTemplate.BuildVisualizationFn != none)
	{	
		StartNode = VisualizationMgr.BuildVisTree;
		EndNode = StartNode.ChildActions.Length > 0 ? StartNode.ChildActions[0] : none;

		//Choose which state to visualize based on interruption status. If we were interrupted, visualize the last state in the interrupt chain.
		if( InterruptionStatus !=  eInterruptionStatus_None )
		{			
			VisualizeState = GetLastStateInInterruptChain();
		}
		else
		{
			VisualizeState = AssociatedState;
		}

		// we may have changed the visualization state that will be used to construct the visualization, so we have to update the context as well
		VisualizeAbilityContext = XComGameStateContext_Ability(VisualizeState.GetContext());
		if( VisualizeAbilityContext == None )
		{
			VisualizeAbilityContext = self;
		}
		
		//Set up the meta data - will associate the actions created below with a visualization actor and state object
		ActionMetadata.StateObjectRef = VisualizeAbilityContext.InputContext.SourceObject;
		ActionMetadata.VisualizeActor = History.GetVisualizer(ActionMetadata.StateObjectRef.ObjectID);
		
		//Construct the visualization tree according to the build visualization function of the ability
		AbilityTemplate.BuildVisualizationFn(VisualizeState);
		
		//Special handling for persistent effects.---
		ProcessGameplayEffects(VisualizeState);

		//Only add the bookend actions if <BuildVisualizationFn> or <ModifyTracks> actually produced something
		// dkaplan 4/25 - or if the ability requires "Showing the activation" (a flyover or unit speech)
		if (VisualizationMgr.BuildVisTree.ChildActions.Length > 0 || 
			AbilityTemplate.bShowActivation || 
			AbilityTemplate.bShowPostActivation || 
			AbilityTemplate.ActivationSpeech != '')
		{
			//Find the end node. Add an end node if there isn't one already from the custom build visualization function.
			EndNode = X2Action_MarkerTreeInsertEnd(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_MarkerTreeInsertEnd'));
			if (EndNode == none)
			{
				VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, Nodes);
				//Nodes is sorted by depth, so assign the tree end to the deepest leaf node
				EndNode = class'X2Action_MarkerTreeInsertEnd'.static.AddToVisualizationTree(ActionMetadata, self, false, Nodes[Nodes.Length - 1]);
			}

			//Add "bookend" actions to the ability. These set up cinematic cameras, look at's, perk effects, etc.
			VisualizeAbilityContext.InsertAbilityPerkEvents(AbilityTemplate, ActionMetadata, VisualizeAbilityContext, StartNode, EndNode);
			VisualizeAbilityContext.InsertAbilityFOWRevealArea(AbilityTemplate, ActionMetadata, VisualizeAbilityContext, StartNode, EndNode);
			VisualizeAbilityContext.InsertSourceUnitLookAtAction(AbilityTemplate, ActionMetadata, VisualizeAbilityContext, StartNode, EndNode);
			VisualizeAbilityContext.InsertCinescriptCamera(AbilityTemplate, ActionMetadata, VisualizeAbilityContext, StartNode, EndNode);
			VisualizeAbilityContext.InsertAbilityFlyoverCaption(AbilityTemplate, ActionMetadata, VisualizeAbilityContext, StartNode, EndNode);
		}
	}
}

function SuperMergeIntoVisualizationTree(X2Action BuildTree, out X2Action VisualizationTree)
{
	super.MergeIntoVisualizationTree(BuildTree, VisualizationTree);
}

function MergeIntoVisualizationTree(X2Action ThisTree, out X2Action VisualizationTree)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;	

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(InputContext.AbilityTemplateName);

	// This can happen legitimately if we are playing a replay, but abilities were modified/removed. Removed assert in favor of returning.
	if (AbilityTemplate == none)
		return;

	//Allow the ability to specify a custom merge function if it wants
	if (AbilityTemplate.MergeVisualizationFn != none)
	{
		AbilityTemplate.MergeVisualizationFn(ThisTree, VisualizationTree);
	}
	else if( MergeVisualizationFn != none )
	{
		MergeVisualizationFn(ThisTree, VisualizationTree);
	}
	else
	{
		//Fall back to the base class implementation if the ability did not provide its own
		SuperMergeIntoVisualizationTree(ThisTree, VisualizationTree);
	}
}

/// <summary>
/// Returns a short description of this context object
/// </summary>
function string SummaryString()
{
	local string OutputString;

	OutputString = string(InputContext.AbilityTemplateName);
	OutputString = OutputString @ " (" @ `XCOMHISTORY.GetGameStateForObjectID(InputContext.SourceObject.ObjectID).SummaryString();
	OutputString = OutputString @  " ->" @ `XCOMHISTORY.GetGameStateForObjectID(InputContext.PrimaryTarget.ObjectID).SummaryString() @ ")";

	return OutputString;
}

/// <summary>
/// Returns a string representation of this object.
/// </summary>
native function string ToString() const;
//***************************************************

/// <summary>
/// Static helper method to construct an ability context given an ability state object and targeting information.
/// </summary>
static function XComGameStateContext_Ability BuildContextFromAbility(XComGameState_Ability AbilityState, int PrimaryTargetID, optional array<int> AdditionalTargetIDs, optional array<vector> TargetLocations, optional X2TargetingMethod TargetingMethod)
{
	local XComGameStateHistory History;
	local XComGameStateContext OldContext;
	local XComGameStateContext_Ability AbilityContext;	
	local XComGameState_BaseObject TargetObjectState;	
	local XComGameState_Unit SourceUnitState;	
	local XComGameState_Item SourceItemState;
	local X2AbilityTemplate AbilityTemplate;
	local int Index;
	local AvailableTarget kTarget;	

	History = `XCOMHISTORY;

	//RAM - if end up having available actions that are not based on abilities, they should probably have a separate static method
	`assert(AbilityState != none);
	AbilityContext = XComGameStateContext_Ability(class'XComGameStateContext_Ability'.static.CreateXComGameStateContext());
	OldContext = AbilityState.GetParentGameState().GetContext();
	if( OldContext != none && OldContext.bSendGameState )
	{
		AbilityContext.SetSendGameState( true );
	}
	
	AbilityContext.InputContext.AbilityRef = AbilityState.GetReference();
	AbilityContext.InputContext.AbilityTemplateName = AbilityState.GetMyTemplateName();

	//Set data that informs the rules engine / visualizer which unit is performing the ability
	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));		
	AbilityContext.InputContext.SourceObject = SourceUnitState.GetReference();

	//Set data that informs the rules engine / visualizer what item was used to perform the ability, if any	
	SourceItemState = AbilityState.GetSourceWeapon();
	if( SourceItemState != none )
	{
		AbilityContext.InputContext.ItemObject = SourceItemState.GetReference();
	}

	if( PrimaryTargetID > 0 )
	{
		TargetObjectState = History.GetGameStateForObjectID(PrimaryTargetID);
		AbilityContext.InputContext.PrimaryTarget = TargetObjectState.GetReference();
	}

	if( AdditionalTargetIDs.Length > 0 )
	{
		for( Index = 0; Index < AdditionalTargetIDs.Length; ++Index )
		{
			AbilityContext.InputContext.MultiTargets.AddItem( History.GetGameStateForObjectID(AdditionalTargetIDs[Index]).GetReference() );
			AbilityContext.InputContext.MultiTargetsNotified.AddItem( false );
		}
	}
	
	//Set data that informs the rules engine / visualizer what locations the ability is targeting. Movement, for example, will set a destination, and any forced waypoints
	if( TargetLocations.Length > 0 )
	{
		AbilityContext.InputContext.TargetLocations = TargetLocations;
	}

	//Calculate the chance to hit here - earliest use after this point is NoGameStateOnMiss
	AbilityTemplate = AbilityState.GetMyTemplate();
	if( AbilityTemplate.AbilityToHitCalc != none )
	{
		kTarget.PrimaryTarget = AbilityContext.InputContext.PrimaryTarget;
		kTarget.AdditionalTargets = AbilityContext.InputContext.MultiTargets;
		AbilityTemplate.AbilityToHitCalc.RollForAbilityHit(AbilityState, kTarget, AbilityContext.ResultContext);
		CheckTargetForHitModification(kTarget, AbilityContext, AbilityTemplate, AbilityState);
	}
	
	//Ensure we have a targeting method to use ( AIs for example don't pass one of these in so we need to make one )
	if(TargetingMethod == none)
	{
		TargetingMethod = new AbilityTemplate.TargetingMethod;
		TargetingMethod.InitFromState(AbilityState);
	}

	//Now that we know the hit result, generate target locations
	class'X2Ability'.static.UpdateTargetLocationsFromContext(AbilityContext);

	if ( (AbilityTemplate.TargetEffectsDealDamage(SourceItemState, AbilityState) && (AbilityState.GetEnvironmentDamagePreview() > 0)) ||
		AbilityTemplate.bUseLaunchedGrenadeEffects || AbilityTemplate.bUseThrownGrenadeEffects || AbilityTemplate.bForceProjectileTouchEvents )
	{
		TargetingMethod.GetProjectileTouchEvents(AbilityContext.InputContext.PrimaryTarget, AbilityContext.ResultContext.ProjectileHitLocations, AbilityContext.InputContext.ProjectileEvents, AbilityContext.InputContext.ProjectileTouchStart, AbilityContext.InputContext.ProjectileTouchEnd);
	}

	if ( X2TargetingMethod_Cone(TargetingMethod) != none )
	{
		X2TargetingMethod_Cone(TargetingMethod).GetReticuleTargets(AbilityContext.InputContext.VisibleTargetedTiles, AbilityContext.InputContext.VisibleNeighborTiles);
	}

	if( AbilityTemplate.AssociatedPlayTiming != SPT_None )
	{
		AbilityContext.SetAssociatedPlayTiming(AbilityTemplate.AssociatedPlayTiming);
	}

	return AbilityContext;
}

static function CheckTargetForHitModification(out AvailableTarget kTarget, XComGameStateContext_Ability ModifyContext, X2AbilityTemplate AbilityTemplate, XComGameState_Ability AbilityState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnitState;	
	local int MultiIndex;

	//Counter attack detection
	local X2AbilityToHitCalc_StandardAim ToHitCalc;
	local bool bValueFound;
	local UnitValue CounterattackCheck;
	local bool bIsResultHit;

	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	if (TargetUnitState != none)
	{
		bIsResultHit = ModifyContext.IsResultContextHit();

		if( bIsResultHit && !TargetUnitState.CanAbilityHitUnit(AbilityTemplate.DataName) )
		{
			ModifyContext.ResultContext.HitResult = eHit_Miss;
			`COMBATLOG("Effect on Target is forcing a miss against" @ TargetUnitState.GetName(eNameType_RankFull));
		}

		if (AbilityTemplate.AbilityToHitOwnerOnMissCalc != None 
			&& ModifyContext.ResultContext.HitResult == eHit_Miss
			&& TargetUnitState.OwningObjectID > 0)
		{
			kTarget.PrimaryTarget = History.GetGameStateForObjectID(TargetUnitState.OwningObjectId).GetReference();
			kTarget.AdditionalTargets.Length = 0;
			AbilityTemplate.AbilityToHitOwnerOnMissCalc.RollForAbilityHit(AbilityState, kTarget, ModifyContext.ResultContext);
			if (IsHitResultHit(ModifyContext.ResultContext.HitResult))
			{
				// Update the target to point to the owner.
				ModifyContext.InputContext.PrimaryTarget = kTarget.PrimaryTarget;
				// ToDo?  Possibly add some kind of flag or notification that our primary target has changed.
				`Log("Missed initial target, HIT main body!");
			}
			else
			{
				`Log("Missed initial target, missed main body.");
			}
		}

		ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
		if ( AbilityTemplate.Hostility == eHostility_Offensive && !AbilityTemplate.bIsASuppressionEffect && AbilityTemplate.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState) )
		{
			if (TargetUnitState.Untouchable > 0)                                       //  untouchable is used up from any attack
			{
				if (TargetUnitState.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID)
				{
					ModifyContext.ResultContext.HitResult = eHit_Untouchable;
					`COMBATLOG("*Untouchable preventing a hit against" @ TargetUnitState.GetName(eNameType_RankFull));
				}
			}
			else if (!TargetUnitState.IsImpaired() &&
					 ((ModifyContext.ResultContext.HitResult == eHit_Graze || ModifyContext.ResultContext.HitResult == eHit_Miss) ||
					 (ToHitCalc != None && ToHitCalc.bGuaranteedHit == true && class'Engine'.static.GetEngine().SyncRand(100, "CounterattackRoll") < class'X2Ability_Muton'.default.COUNTERATTACK_DODGE_AMOUNT )))
			{
				// The Target unit (unit that would counterattack) cannot be impaired
				//If this attack was a melee attack AND the target unit has a counter attack prepared turn this dodge into a counter attack							
				if (ToHitCalc != none && ToHitCalc.bMeleeAttack)
				{
					bValueFound = TargetUnitState.GetUnitValue(class'X2Ability'.default.CounterattackDodgeEffectName, CounterattackCheck);
					if (bValueFound && CounterattackCheck.fValue == class'X2Ability'.default.CounterattackDodgeUnitValue)
					{
						ModifyContext.ResultContext.HitResult = eHit_CounterAttack;
					}
				}
			}
		}

		//  jbouscher: I'm not a huge fan of this very specific check, but we don't have enough things to make this more general.
		//  @TODO - this was setup prior to the CanAbilityHitUnit stuff - let's convert scorch circuits to an effect and implement it that way
		if (AbilityTemplate.DataName == class'X2Ability_Viper'.default.GetOverHereAbilityName && TargetUnitState.HasScorchCircuits())
		{
			ModifyContext.ResultContext.HitResult = eHit_Miss;
			`COMBATLOG("*ScorchCircuits forcing a miss against" @ TargetUnitState.GetName(eNameType_RankFull));
		}
	}
	for (MultiIndex = 0; MultiIndex < kTarget.AdditionalTargets.Length; ++MultiIndex)
	{
		bIsResultHit = false;
		TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.AdditionalTargets[MultiIndex].ObjectID));
		if (TargetUnitState != none)
		{
			bIsResultHit = ModifyContext.IsResultContextMultiHit(MultiIndex);

			if( bIsResultHit && !TargetUnitState.CanAbilityHitUnit(AbilityTemplate.DataName) )
			{
				ModifyContext.ResultContext.MultiTargetHitResults[MultiIndex] = eHit_Miss;
				`COMBATLOG("Effect on MultiTarget is forcing a miss against" @ TargetUnitState.GetName(eNameType_RankFull));
			}

			if ( AbilityTemplate.Hostility == eHostility_Offensive )
			{
				if (TargetUnitState.Untouchable > 0)
				{
					if (TargetUnitState.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID)
					{
						ModifyContext.ResultContext.MultiTargetHitResults[MultiIndex] = eHit_Untouchable;
						`COMBATLOG("*Untouchable preventing a hit against" @ TargetUnitState.GetName(eNameType_RankFull));
					}
				}
			}
		}
	}
}

/// <summary>
/// Static helper method used by game play code to, based on an AvailableAction structure, submit changes to the rules engine
/// </summary>
/// <param name="PerformAction">Encapsulates most of the information about what ability to perform, what entity is performing it, etc.</param>
/// <param name="AvailableTargetsIndex">An index into the AvailableTargets array inside PerformAction indicating which target to perform the action on</param>
/// <param name="TargetLocations">Some actions operate on 3d locations in-addition-to or instead-of targets, and this array sets them </param>
/// return value indicates whether ability was successfully submitted (Tutorial/DemoDirect)
/// <param name="VisualizeAtHistoryIndex">If this ability should be visualized at a history index different from the associated game state's history
/// <param name="ActivationCallback">If specified, the ability will be submitted to the ruleset latently, and the callback called when it is complete
/// index, set this value to the desired history index.</param>
static function bool ActivateAbility(AvailableAction PerformAction, 
									 optional int AvailableTargetsIndex = -1, 
									 optional array<Vector> TargetLocations,
									 optional X2TargetingMethod TargetingMethod,
									 optional array<TTile> PathTiles,
									 optional array<TTile> WaypointTiles,
									 optional int VisualizeAtHistoryIndex = -1,
									 optional delegate<X2GameRuleset.LatentSubmitGameStateContextCallbackFn> ActivationCallback,
									 optional SequencePlayTiming InAssociatedPlayTiming)
{
	local X2GameRuleset RuleSet;
	local ActionSelection SelectAction;
	local XComGameStateContext_Ability NewContext;

	if( ActivationCallback == none || `REPLAY.bInTutorial )
	{
		return ActivateAbility_ReturnContext(PerformAction, AvailableTargetsIndex, TargetLocations, TargetingMethod, PathTiles, WaypointTiles, VisualizeAtHistoryIndex, InAssociatedPlayTiming) != None;
	}
	else
	{
		SelectAction.PerformAction = PerformAction;
		SelectAction.AvailableTargetsIndex = AvailableTargetsIndex;
		SelectAction.TargetLocations = TargetLocations;
		SelectAction.TargetingMethod = TargetingMethod;
		SelectAction.PathTiles = PathTiles;
		SelectAction.WaypointTiles = WaypointTiles;

		NewContext = ActivateAbility_Internal(SelectAction, VisualizeAtHistoryIndex, InAssociatedPlayTiming);
		if(NewContext != none)
		{
			//We're done - send it to the rules engine for processing and addition to the history
			RuleSet = `XCOMGAME.GameRuleset;
			`assert(RuleSet != none);
			RuleSet.LatentSubmitGameStateContext(NewContext, ActivationCallback);
			
			return true;
		}
		else
		{
			return false;
		}
	}
}

// Helper function to make activating an ability against a specific target simpler. There are tons of places in code
// that iterate over all available actions for a given unit, when really they could just call this function instead.
static function bool ActivateAbilityByTemplateName(StateObjectReference SourceUnit,
									 name AbilityTemplateName, 
									 optional StateObjectReference PrimaryTarget, 
									 optional array<Vector> TargetLocations,
									 optional X2TargetingMethod TargetingMethod,
									 optional array<TTile> PathTiles,
									 optional array<TTile> WaypointTiles,
									 optional int VisualizeAtHistoryIndex = -1)
{
	local XComGameStateHistory History; 
	local GameRulesCache_Unit UnitCache;
	local XComGameState_Ability AbilityState;
	local int ActionIndex;
	local int TargetIndex;

	History = `XCOMHISTORY;
	if (`TACTICALRULES.GetGameRulesCache_Unit(SourceUnit, UnitCache))
	{
		for(ActionIndex = 0; ActionIndex < UnitCache.AvailableActions.Length; ActionIndex++)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitCache.AvailableActions[ActionIndex].AbilityObjectRef.ObjectID));
			`assert(AbilityState != none);
			if(AbilityState.GetMyTemplateName() == AbilityTemplateName)
			{
				for(TargetIndex = 0; TargetIndex < UnitCache.AvailableActions[ActionIndex].AvailableTargets.Length; TargetIndex++)
				{
					if(UnitCache.AvailableActions[ActionIndex].AvailableTargets[TargetIndex].PrimaryTarget.ObjectID == PrimaryTarget.ObjectID)
					{
						return ActivateAbility(UnitCache.AvailableActions[ActionIndex], 
												TargetIndex, 
												TargetLocations, 
												TargetingMethod, 
												PathTiles,
												WaypointTiles, 
												VisualizeAtHistoryIndex);
					}
				}

				break; // we found the correct ability, so no need to consider more of them
			}
		}
	}

	return false;
}

static function XComGameStateContext_Ability ActivateAbility_ReturnContext(AvailableAction PerformAction,
									 optional int AvailableTargetsIndex = -1,
									 optional array<Vector> TargetLocations,
									 optional X2TargetingMethod TargetingMethod,
									 optional array<TTile> PathTiles,
									 optional array<TTile> WaypointTiles,
									 optional int VisualizeAtHistoryIndex = -1,
									 optional SequencePlayTiming InAssociatedPlayTiming)
{
	local X2GameRuleset RuleSet;
	local ActionSelection SelectAction;
	local XComGameStateContext_Ability NewContext;

	SelectAction.PerformAction = PerformAction;
	SelectAction.AvailableTargetsIndex = AvailableTargetsIndex;
	SelectAction.TargetLocations = TargetLocations;
	SelectAction.TargetingMethod = TargetingMethod;
	SelectAction.PathTiles = PathTiles;
	SelectAction.WaypointTiles = WaypointTiles;

	NewContext = ActivateAbility_Internal(SelectAction, VisualizeAtHistoryIndex, InAssociatedPlayTiming);

	//We're done - send it to the rules engine for processing and addition to the history
	RuleSet = `XCOMGAME.GameRuleset;
	`assert(RuleSet != none);
	if( RuleSet.SubmitGameStateContext(NewContext) )
	{
		return NewContext;
	}

	return None;
}


static function bool ActivateAbilityList( array<ActionSelection> ActionList, int VisualizeAtHistoryIndex=INDEX_NONE, bool bGroupVisualizations=false, optional SequencePlayTiming InAssociatedPlayTiming)
{
	local X2GameRuleset RuleSet;
	local XComGameStateContext_Ability NewContext;
	local ActionSelection SelectAction;
	local array<XComGameStateContext_Ability> Contexts;

	foreach ActionList(SelectAction)
	{
		NewContext = ActivateAbility_Internal(SelectAction, VisualizeAtHistoryIndex, InAssociatedPlayTiming);

		if( NewContext == None )
		{
			return false;
		}

		// mark all contexts to skip the extra vis step...
		NewContext.bSkipAdditionalVisualizationSteps = true;

		Contexts.AddItem(NewContext);
	}

	// ... except the first one
	if( Contexts.Length > 0 )
	{
		Contexts[0].bSkipAdditionalVisualizationSteps = false;
	}

	//We're done - send it to the rules engine for processing and addition to the history
	RuleSet = `XCOMGAME.GameRuleset;
	`assert(RuleSet != none);
	return RuleSet.SubmitGameStateContexts(Contexts,, bGroupVisualizations);
}

static function XComGameStateContext_Ability ActivateAbility_Internal(ActionSelection SelectAction, optional int VisualizeAtHistoryIndex = -1, optional SequencePlayTiming InAssociatedPlayTiming)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit SourceUnitState;
	local XComGameStateContext_Ability NewContext;
	local TTile Destination;
	local array<TTile> MeleeDestinations;
	local int Index;
	local array<int> AdditionalTargetIDs;
	local X2AbilityTemplate AbilityTemplate;
	local PathingInputData PathData;
	local PathingResultData PathingResult;
	local array<XComGameState_Unit> AttachedUnits;
	local XGUnit CosmeticUnitVisualizer;

	NewContext = None;
	//Set data that informs the rules engine / visualizer which ability was activated
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectAction.PerformAction.AbilityObjectRef.ObjectID));

	if( SelectAction.PerformAction.AvailableCode != 'AA_Success' )
	{
		`RedScreen("Attempt to ActivateAbility" @ AbilityState.GetMyTemplate().LocFriendlyName @ "but it is not available" @ SelectAction.PerformAction.AvailableCode $ ". Calling code should prevent this!");
		return None;
	}

	//Build the ability context using the helper method
	if( SelectAction.AvailableTargetsIndex > -1 )
	{
		for( Index = 0; Index < SelectAction.PerformAction.AvailableTargets[SelectAction.AvailableTargetsIndex].AdditionalTargets.Length; ++Index )
		{
			AdditionalTargetIDs.AddItem(SelectAction.PerformAction.AvailableTargets[SelectAction.AvailableTargetsIndex].AdditionalTargets[Index].ObjectID);
		}

		NewContext = BuildContextFromAbility(AbilityState,
											 SelectAction.PerformAction.AvailableTargets[SelectAction.AvailableTargetsIndex].PrimaryTarget.ObjectID,
											 AdditionalTargetIDs,
											 SelectAction.TargetLocations,
											 SelectAction.TargetingMethod);
	}
	else
	{
		if( SelectAction.PerformAction.AvailableTargets.Length > 0 )
		{
			`RedScreen("Attempt to ActivateAbility" @ AbilityState.GetMyTemplate() @ "that has Targets but with no Target Index specified. I'll do it, but this is very naughty. -jbouscher @gameplay" @ GetScriptTrace());
		}
		//  An ability without targets - e.g. Grapple
		NewContext = BuildContextFromAbility(AbilityState, -1, , SelectAction.TargetLocations);
	}

	AbilityTemplate = AbilityState.GetMyTemplate();
	if( AbilityTemplate.ModifyNewContextFn != none )
	{
		AbilityTemplate.ModifyNewContextFn(NewContext);
	}

	if( VisualizeAtHistoryIndex != -1 )
	{
		NewContext.SetDesiredVisualizationBlockIndex(VisualizeAtHistoryIndex);
	}

	// give the ability template the opportunity to utilize a standard SPT merge rather than defining a unique merge or falling back on the weighting system
	if( InAssociatedPlayTiming != SPT_None )
	{
		NewContext.SetAssociatedPlayTiming(InAssociatedPlayTiming);
	}

	History = `XCOMHISTORY;
	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(NewContext.InputContext.SourceObject.ObjectID));

	// check if this ability requires a movement path but didn't provide one. This is probably because it's been
	// AI activated and so no path was determined up front
	if( SelectAction.PathTiles.Length == 0 &&
	   NewContext.InputContext.PrimaryTarget.ObjectID > 0 &&
	   AbilityTemplate.TargetingMethod != none &&
	   AbilityTemplate.TargetingMethod.default.ProvidesPath )
	{
		if( class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile(SourceUnitState,
																	   History.GetGameStateForObjectID(NewContext.InputContext.PrimaryTarget.ObjectID),
																	   AbilityTemplate,
																	   MeleeDestinations) )
		{
			XGUnit(SourceUnitState.GetVisualizer()).m_kReachableTilesCache.BuildPathToTile(MeleeDestinations[0], SelectAction.PathTiles);
		}
	}

	if( SelectAction.PathTiles.Length > 1 )
	{
		// we have a movement path as part of this ability, so add it
		PathData.MovementTiles = SelectAction.PathTiles;
		PathData.WaypointTiles = SelectAction.WaypointTiles;
		PathData.MovingUnitRef.ObjectID = NewContext.InputContext.SourceObject.ObjectID;
		class'XComTacticalController'.static.CreatePathDataForPathTiles(PathData);
		NewContext.InputContext.MovementPaths.AddItem(PathData);

		Destination = SelectAction.PathTiles[SelectAction.PathTiles.Length - 1];

		// Move gremlin if we have one (or two, specialist receieving aid protocol) attached to us 
		SourceUnitState.GetAttachedUnits(AttachedUnits);

		for( Index = 0; Index < AttachedUnits.Length; Index++ )
		{
			SelectAction.PathTiles.Remove(0, SelectAction.PathTiles.Length);
			CosmeticUnitVisualizer = XGUnit(AttachedUnits[Index].GetVisualizer());
			CosmeticUnitVisualizer.bNextMoveIsFollow = true;

			Destination.Z += AttachedUnits[Index].GetDesiredZTileOffsetForAttachedCosmeticUnit();

			CosmeticUnitVisualizer.m_kReachableTilesCache.BuildPathToTile(Destination, SelectAction.PathTiles);

			if( SelectAction.PathTiles.Length == 0 )
			{
				class'X2PathSolver'.static.BuildPath(AttachedUnits[Index], AttachedUnits[Index].TileLocation, Destination, SelectAction.PathTiles);
			}

			PathData.MovementTiles = SelectAction.PathTiles;
			PathData.MovingUnitRef.ObjectID = AttachedUnits[Index].ObjectID;
			class'XComTacticalController'.static.CreatePathDataForPathTiles(PathData);
			NewContext.InputContext.MovementPaths.AddItem(PathData);
		}
	}


	// While it's possible for ability firing code to setup their own movement result contexts, by default we just
	// fill them out here.
	while( NewContext.ResultContext.PathResults.Length < NewContext.InputContext.MovementPaths.Length )
	{
		class'X2TacticalVisibilityHelpers'.static.FillPathTileData(NewContext.InputContext.MovementPaths[NewContext.ResultContext.PathResults.Length].MovingUnitRef.ObjectID,
																   NewContext.InputContext.MovementPaths[NewContext.ResultContext.PathResults.Length].MovementTiles,
																   PathingResult.PathTileData);
		NewContext.ResultContext.PathResults.AddItem(PathingResult);
	}

	return NewContext;
}

native function bool IsResultContextHit();
/*
{
	return static.IsHitResultHit(ResultContext.HitResult);
}
*/

native function bool IsResultContextMiss();
/*
{
	return static.IsHitResultMiss(ResultContext.HitResult);
}
*/

function bool IsResultContextMultiHit(int index)
{
	return static.IsHitResultHit(ResultContext.MultiTargetHitResults[index]);
}

function bool IsResultContextMultiMiss(int index)
{
	return static.IsHitResultMiss(ResultContext.MultiTargetHitResults[index]);
}

function bool IsEvacContext()
{
	return InputContext.AbilityTemplateName == 'Evac';
}

static native function bool IsHitResultHit(EAbilityHitResult TestResult);
static native function bool IsHitResultMiss(EAbilityHitResult TestResult);

native function bool IsVisualHit(EAbilityHitResult TestResult);

function name FindShooterEffectApplyResult(const X2Effect Effect)
{
	local int i;

	for (i = 0; i < ResultContext.ShooterEffectResults.Effects.Length; ++i)
	{
		if (ResultContext.ShooterEffectResults.Effects[i] == Effect)
		{
			return ResultContext.ShooterEffectResults.ApplyResults[i];
		}
	}
	return 'AA_UnknownError';
}

function name FindTargetEffectApplyResult(const X2Effect Effect)
{
	local int i;

	for (i = 0; i < ResultContext.TargetEffectResults.Effects.Length; ++i)
	{
		if (ResultContext.TargetEffectResults.Effects[i] == Effect)
		{
			return ResultContext.TargetEffectResults.ApplyResults[i];
		}
	}
	return 'AA_UnknownError';
}

function name FindMultiTargetEffectApplyResult(const X2Effect Effect, const int TargetIndex)
{
	local int i;

	for (i = 0; i < ResultContext.MultiTargetEffectResults[TargetIndex].Effects.Length; ++i)
	{
		if (ResultContext.MultiTargetEffectResults[TargetIndex].Effects[i] == Effect)
		{
			return ResultContext.MultiTargetEffectResults[TargetIndex].ApplyResults[i];
		}
	}
	return 'AA_UnknownError';
}

function int GetMovePathIndex(int ObjectID)
{
	local int Index;

	for(Index = 0; Index < InputContext.MovementPaths.Length; ++Index)
	{
		if(ObjectID == InputContext.MovementPaths[Index].MovingUnitRef.ObjectID)
		{
			return Index;
		}
	}

	return -1;
}

// Debug-only function used in X2DebugHistory screen.
function bool HasAssociatedObjectID(int ID)
{
	if( InputContext.SourceObject.ObjectID == ID
	   || InputContext.PrimaryTarget.ObjectID == ID
	   || InputContext.MultiTargets.Find('ObjectID', ID) != INDEX_NONE )
	{
		return true;
	}
	return false;
}

function int GetPrimaryObjectRef()
{
	return InputContext.SourceObject.ObjectID;
}
