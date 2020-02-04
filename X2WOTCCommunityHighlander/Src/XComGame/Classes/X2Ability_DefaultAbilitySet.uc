//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_DefaultAbilitySet.uc
//  AUTHOR:  Ryan McFall  --  11/11/2013
//  PURPOSE: Defines basic abilities that support tactical game play in X-Com 2. 
//           Movement, firing weapons, overwatch, etc.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_DefaultAbilitySet extends X2Ability 
	dependson (XComGameStateContext_Ability) 
	native(Core)
	config(GameCore);

var array<name> DefaultAbilitySet;
var name EvacThisTurnName;
var name ConcealedOverwatchTurn;

var config const float LOOT_RANGE;
var config const float EXPANDED_LOOT_RANGE;
var config const int MEDIKIT_STABILIZE_AMMO;
var config const int MEDIKIT_PERUSEHP, NANOMEDIKIT_PERUSEHP;
var config const int MAX_EVAC_PER_TURN;
var config const int STEADY_AIM_BONUS;
var config const float KNOCKOUT_RANGE;
var config const int REVIVE_DISORIENT_PERCENT_CHANCE;
var config const int REVIVE_RANGE_UNITS;

var config const int HUNKERDOWN_DEFENSE, HUNKERDOWN_DODGE;

var config array<name> MedikitHealEffectTypes;      //  Medikits and gremlin healing abilities use this array of damage types to remove persistent effects.
var config array<name> OverwatchExcludeEffects;
var config array<name> OverwatchExcludeReasons;
var config array<name> OverwatchIgnoreAbilities;	//	Abilities that TypicalOverwatchListener will not respond to
var config const bool bAllowPeeksForNonCoverUnits;

var config string TutorialEvacBink;

var name ImmobilizedValueName;

var localized string EnemyHackAttemptFailureString;
var localized string EnemyHackAttemptSuccessString;

var config float TypicalMoveDelay;

/// <summary>
/// Creates the set of default abilities every unit should have in X-Com 2
/// </summary>
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(AddStandardMoveAbility());	
	Templates.AddItem(AddOverwatchShotAbility());
	Templates.AddItem(PistolOverwatchShot());
	Templates.AddItem(PistolReturnFire());
	Templates.AddItem(AddOverwatchAbility());
	Templates.AddItem(PistolOverwatch());
	Templates.AddItem(SniperRifleOverwatch());
	Templates.AddItem(AddReloadAbility());
	Templates.AddItem(AddInteractAbility());
	Templates.AddItem(AddInteractAbility('Interact_OpenDoor'));
	Templates.AddItem(AddInteractAbility('Interact_OpenChest'));
	Templates.AddItem(CreateMarkSupplyCrateAbility());
	Templates.AddItem(CreateActivateAscensionGateAbility());
	Templates.AddItem(AddPlantBombAbility());
	Templates.AddItem(AddObjectiveInteractAbility('Interact_TakeVial'));
	Templates.AddItem(AddObjectiveInteractAbility('Interact_StasisTube'));
	Templates.AddItem(AddHackAbility());
	Templates.AddItem(AddHackAbility('Hack_Chest'));
	Templates.AddItem(AddObjectiveHackAbility('Hack_Workstation'));
	Templates.AddItem(AddObjectiveHackAbility('Hack_ObjectiveChest'));
	Templates.AddItem(FinalizeHack());
	Templates.AddItem(CancelHack());
	Templates.AddItem(AddLootAbility());
	Templates.AddItem(AddGatherEvidenceAbility());
	Templates.AddItem(AddPlantExplosiveMissionDeviceAbility());
	Templates.AddItem(AddHunkerDownAbility());
	Templates.AddItem(AddMedikitHeal('MedikitHeal', default.MEDIKIT_PERUSEHP));
	Templates.AddItem(AddMedikitHeal('NanoMedikitHeal', default.NANOMEDIKIT_PERUSEHP));
	Templates.AddItem(AddMedikitStabilize());
	Templates.AddItem(AddEvacAbility());
	Templates.AddItem(AddGrapple());
	Templates.AddItem(AddGrapplePowered());	
	Templates.AddItem(WallBreaking());
	Templates.AddItem(HotLoadAmmo());
	Templates.AddItem(AddKnockoutAbility());
	Templates.AddItem(AddKnockoutSelfAbility());
	Templates.AddItem(AddPanicAbility('Panicked'));
	Templates.AddItem(AddBerserkAbility());
	Templates.AddItem(AddObsessedAbility());
	Templates.AddItem(AddShatteredAbility());
	Templates.AddItem(PurePassive('ShakenPassive', "img:///UILibrary_PerkIcons.UIPerk_shaken", , 'eAbilitySource_Debuff'));
	Templates.AddItem(TacticalRigging());
	Templates.AddItem(AddDisableConsumeAllPointsAbility());
	Templates.AddItem(AddRevive());

	// Challenge mode ability
	Templates.AddItem(AddChallengeHackAbility('ChallengeMode_Hack', 'Hack', true));
	Templates.AddItem(AddChallengeHackAbility('ChallengeMode_Hack_Workstation', 'Hack_Workstation', false));
	Templates.AddItem(AddChallengeHackAbility('ChallengeMode_Hack_ObjectiveChest', 'Hack_ObjectiveChest', false));

	// Ladder mode ability
	Templates.AddItem(AddObjectiveInteractAbility('Interact_SweaterTube'));
	Templates.AddItem(AddObjectiveHackAbility('Hack_Scan'));

	return Templates;
}

//******** Standard Move & Dash Move **********
static function X2AbilityTemplate AddStandardMoveAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2AbilityTarget_Path              PathTarget;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2Condition_UnitValue				IsNotImmobilized;
	local X2Condition_UnitStatCheck         UnitStatCheckCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'StandardMove');
	
	Template.bDontDisplayInAbilitySummary = true;
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bMoveCost = true;
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
	ActionPointCost.AllowedTypes.RemoveItem(class'X2CharacterTemplateManager'.default.RunAndGunActionPoint);
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);
	Template.bDisplayInUITooltip = false;
	
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeCosmetic = false; //Cosmetic units are allowed movement
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	IsNotImmobilized = new class'X2Condition_UnitValue';
	IsNotImmobilized.AddCheckValue(default.ImmobilizedValueName, 0);
	Template.AbilityShooterConditions.AddItem(IsNotImmobilized);

	// Unit might not be mobilized but have zero mobility
	UnitStatCheckCondition = new class'X2Condition_UnitStatCheck';
	UnitStatCheckCondition.AddCheckStat(eStat_Mobility, 0, eCheck_GreaterThan);
	Template.AbilityShooterConditions.AddItem(UnitStatCheckCondition);

	PathTarget = new class'X2AbilityTarget_Path';
	Template.AbilityTargetStyle = PathTarget;

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Movement;

	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.BuildNewGameStateFn = MoveAbility_BuildGameState;
	Template.BuildVisualizationFn = MoveAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = MoveAbility_BuildInterruptGameState;
	Template.AssociatedPlayTiming = SPT_AfterSequential;

	Template.CinescriptCameraType = "StandardMovement"; 

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentMoveLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.MoveChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MoveLostSpawnIncreasePerUse;

	return Template;
}

//(Similar to TypicalAbility_BuildGameState/FillOutGameState separation)
static function XComGameState MoveAbility_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);

	MoveAbility_FillOutGameState(NewGameState, true);

	return NewGameState;
}

simulated static function XComGameState MoveAbility_FillOutGameState( XComGameState NewGameState, bool bApplyCosts )
{
	local XComGameState_Unit MovingUnitState, MovingSubsystem;	
	local array<XComGameState_Unit> arrSubSystems;
	local int ComponentId;
	local XComGameState_Ability MoveAbilityState;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	
	//Discovery and creation of interactive level actor states
	local int PrevActions, MovesSpent;
	local UnitValue MovesThisTurn;
	local TTile UnitTile, PrevUnitTile;
	local XComGameStateHistory History;
	local Vector TilePos, PrevTilePos, TilePosDiff;

	local int MovingUnitIndex;
	local int NumMovementTiles;
	local int idx;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());	
	MoveAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));	
	AbilityTemplate = MoveAbilityState.GetMyTemplate();

	AbilityContext.ResultContext.bPathCausesDestruction = false;

	//Set the unit's new location
	for(MovingUnitIndex = 0; MovingUnitIndex < AbilityContext.InputContext.MovementPaths.Length; ++MovingUnitIndex)
	{
		`assert(AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovementTiles.Length > 0);
		MovingUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovingUnitRef.ObjectID));
		// Moving a unit with subsystems will also move the subsystems to the same base tile.
		foreach MovingUnitState.ComponentObjectIds(ComponentId)
		{
			if(History.GetGameStateForObjectID(ComponentId).IsA('XComGameState_Unit'))
			{
				MovingSubsystem = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ComponentId));
				if(MovingSubsystem != None)
				{
					arrSubSystems.AddItem(MovingSubsystem);
				}
			}
		}

		NumMovementTiles = AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovementTiles.Length;

		// Don't end on a tile that has lost it's floor.
		for (idx = NumMovementTiles - 1; idx >= 0; --idx)
		{
			UnitTile = AbilityContext.InputContext.MovementPaths[ MovingUnitIndex ].MovementTiles[ idx ];
			if (MovingUnitState.GetMyTemplate().bCanUse_eTraversal_Flying || `XWORLD.IsFloorTile(UnitTile))
			{
				break;
			}
		}

		MovingUnitState.SetVisibilityLocation(UnitTile);

		if (idx > 0)
		{
			PrevUnitTile = AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovementTiles[idx - 1];

			TilePos = `XWORLD.GetPositionFromTileCoordinates(UnitTile);
			PrevTilePos = `XWORLD.GetPositionFromTileCoordinates(PrevUnitTile);
			TilePosDiff = TilePos - PrevTilePos;
			TilePosDiff.Z = 0;

			MovingUnitState.MoveOrientation = Rotator(TilePosDiff);
		}

		//Apply the cost of the ability, track MovesThisTurn based on action points consumed
		PrevActions = MovingUnitState.NumAllActionPoints();

		if (bApplyCosts)
		{
			AbilityTemplate.ApplyCost(AbilityContext, MoveAbilityState, MovingUnitState, none, NewGameState);
		}

		MovesSpent = PrevActions - MovingUnitState.NumAllActionPoints();
		if(MovingUnitState.GetUnitValue('MovesThisTurn', MovesThisTurn))
		{
			MovesSpent += MovesThisTurn.fValue;
		}
		MovingUnitState.SetUnitFloatValue('MovesThisTurn', MovesSpent, eCleanup_BeginTurn);

		// Handle subsystems
		foreach arrSubSystems(MovingSubsystem)
		{
			MovingSubsystem.SetVisibilityLocation(UnitTile);
			MovingSubsystem.MoveOrientation = MovingUnitState.MoveOrientation;

			// TO DO - apply movement cost to treads-only on ACV!  ???
		}

		AbilityContext.ResultContext.bPathCausesDestruction = AbilityContext.ResultContext.bPathCausesDestruction || MoveAbility_StepCausesDestruction(MovingUnitState, AbilityContext.InputContext, MovingUnitIndex, NumMovementTiles - 1);

		MoveAbility_AddTileStateObjects(NewGameState, MovingUnitState, AbilityContext.InputContext, MovingUnitIndex, NumMovementTiles - 1);
		MoveAbility_AddNewlySeenUnitStateObjects(NewGameState, MovingUnitState, AbilityContext.InputContext, MovingUnitIndex);

		`XEVENTMGR.TriggerEvent('ObjectMoved', MovingUnitState, MovingUnitState, NewGameState);
		`XEVENTMGR.TriggerEvent('UnitMoveFinished', MovingUnitState, MovingUnitState, NewGameState);
	}	

	//Return the game state we have created
	return NewGameState;	
}

simulated static function XComGameState MoveAbility_BuildInterruptGameState( XComGameStateContext Context, int InterruptStep, EInterruptionStatus InterruptionStatus)
{
	local XComGameState NewGameState;
	local XComGameState_Unit MovingUnitState, MovingSubsystem;	
	local array<XComGameState_Unit> arrSubSystems;
	local int ComponentID;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local Vector TilePos, PrevTilePos, TilePosDiff;
	local TTile Tile, PrevTile;
	local XComGameStateHistory History;
	local XComGameState_AIGroup AIGroup; //Used to see if this move should be cancelled due to scampering
	local array<TTile> ValidTileList, OccupiedTiles;
	local PathingInputData PathData;

	local int MovingUnitIndex;
	local int NumMovementTiles;
	local int UseInterruptStep;

	History = `XCOMHISTORY;

	//See if this is a group move that should end due to scampering
	AbilityContext = XComGameStateContext_Ability(Context);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	if(AbilityContext.InputContext.SourceObject.ObjectID > 0 && AbilityState.GetMyTemplate().Hostility == eHostility_Movement)
	{
		MovingUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		if(MovingUnitState != none)
		{
			AIGroup = MovingUnitState.GetGroupMembership();
			if(AIGroup != none)
			{
				if(AIGroup.bPendingScamper && MovingUnitState.ReflexActionState != eReflexActionState_AIScamper)
				{
					//A scamper has been queued, but we are still processing the move that got us to the scamper location. Cancel this move.
					return none;
				}
			}

			if (!MovingUnitState.GetMyTemplate().bCanUse_eTraversal_Flying)
			{
				// don't end on a tile that has lost it's floor
				foreach AbilityContext.InputContext.MovementPaths(PathData)
				{
					if (PathData.MovingUnitRef == MovingUnitState.GetReference())
					{
						if( InterruptStep < PathData.MovementTiles.Length )
						{
							Tile = PathData.MovementTiles[InterruptStep];
						}
						else
						{
							// Why would we be exceeding the length of the array here?!?
							Tile = PathData.MovementTiles[PathData.MovementTiles.Length-1];
						}

						if ((InterruptStep == (PathData.MovementTiles.Length - 1)) && !`XWORLD.IsFloorTile(Tile))
						{
							return none;
						}

						break;
					}
				}
			}
		}
	}

	if( InterruptionStatus == eInterruptionStatus_Resume )
	{
		//The resume state for movement is the same as the base one
		NewGameState = AbilityState.GetMyTemplate().BuildNewGameStateFn(Context);
		AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
		AbilityContext.SetInterruptionStatus(InterruptionStatus);
		AbilityContext.ResultContext.InterruptionStep = InterruptStep;
		return NewGameState;
	}
	else
	{
		`assert(InterruptionStatus == eInterruptionStatus_Interrupt);
		AbilityContext = XComGameStateContext_Ability(Context);
		
		//Find the longest path in tiles
		for(MovingUnitIndex = 0; MovingUnitIndex < AbilityContext.InputContext.MovementPaths.Length; ++MovingUnitIndex)
		{
			NumMovementTiles = Max(NumMovementTiles, AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovementTiles.Length);
		}

		AbilityContext.ResultContext.bPathCausesDestruction = false;

		if(InterruptStep < (NumMovementTiles - 1))
		{
			//Build the new game state frame, and unit state object for the moving unit
			NewGameState = History.CreateNewGameState(true, Context);		
			AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
			AbilityContext.SetInterruptionStatus(InterruptionStatus);
			AbilityContext.ResultContext.InterruptionStep = InterruptStep;

			//Set the unit's new location
			for(MovingUnitIndex = 0; MovingUnitIndex < AbilityContext.InputContext.MovementPaths.Length; ++MovingUnitIndex)
			{	
				MovingUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovingUnitRef.ObjectID));
				// Moving a unit with components will also move the components to the same base tile.
				foreach MovingUnitState.ComponentObjectIds(ComponentID)
				{
					if(History.GetGameStateForObjectID(ComponentID).IsA('XComGameState_Unit'))
					{
						MovingSubsystem = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ComponentID));
						if(MovingSubsystem != None)
						{
							arrSubSystems.AddItem(MovingSubsystem);
						}
					}
				}

				// Prevent units being interrupted on the same tile as other units in the group.  Remove occupied tiles from tile list.
				ValidTileList = AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovementTiles;
				if( OccupiedTiles.Length > 0 )
				{
					class'Helpers'.static.RemoveTileSubset(ValidTileList, ValidTileList, OccupiedTiles);
				}

				// Start Issue #644
				//
				// Borrowed this implementation from the original LW2, which fixed the bug with patrolling
				// units teleporting behind XCOM here. See this Reddit comment for some more info:
				//
				//  https://www.reddit.com/r/Xcom/comments/5qnob0/lw2_particularly_deadly_teleport_bug_on_supply/dd0uhjk/
				//
				// Old LWS comment: handle use case where ValidTileList has been reduced to 0 elements.
				// Allow units to occupy same tile in this case reset the ValidTilesList back to the default,
				// so that a tile will be selected instead of allowing a (0,0,0) tiles to be entered by default
				/// HL-Docs: ref:Bugfixes; issue:644
				/// Allow patrolling units to occupy the same tile instead of teleporting to `(0,0,0)` when out of space, potentially revealing XCOM
				if (ValidTileList.Length == 0)
				{
					ValidTileList = AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovementTiles;
				}
				// End Issue #644

				NumMovementTiles = ValidTileList.Length;
				UseInterruptStep = Min(InterruptStep, NumMovementTiles - 1);

				//If return a location corresponding to the incoming 'step' parameter
				Tile = ValidTileList[UseInterruptStep];
				MovingUnitState.SetVisibilityLocation(Tile);

				// Keep track of all tiles occupied from this interrupted move location.
				MovingUnitState.GetVisibilityForLocation(Tile, OccupiedTiles);

				if( UseInterruptStep >= 1 )
				{
					PrevTile = ValidTileList[UseInterruptStep - 1];

					if(Tile != PrevTile)
					{
						TilePos = `XWORLD.GetPositionFromTileCoordinates(Tile);
						PrevTilePos = `XWORLD.GetPositionFromTileCoordinates(PrevTile);
						TilePosDiff = TilePos - PrevTilePos;
						TilePosDiff.Z = 0;

						MovingUnitState.MoveOrientation = Rotator(TilePosDiff);
					}
				}
				
				// Handle subsystems
				foreach arrSubSystems(MovingSubsystem)
				{
					MovingSubsystem.SetVisibilityLocation(Tile);
					MovingSubsystem.MoveOrientation = MovingUnitState.MoveOrientation;
				}

				AbilityContext.ResultContext.bPathCausesDestruction = (AbilityContext.ResultContext.bPathCausesDestruction || MoveAbility_StepCausesDestruction(MovingUnitState, AbilityContext.InputContext, MovingUnitIndex, UseInterruptStep));

				// Jwats: Commented out after discussing with McFall.  We would get multiple interacts when kicking down doors.
				//MoveAbility_AddTileStateObjects( NewGameState, MovingUnitState, AbilityContext.InputContext, UseInterruptStep );

				`XEVENTMGR.TriggerEvent('ObjectMoved', MovingUnitState, MovingUnitState, NewGameState);
			}
		}
	}

	//Return the game state we have created
	return NewGameState;	
}

simulated static function MoveAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local StateObjectReference MovingUnitRef;	
	local XGUnit MovingUnitVisualizer;
	local VisualizationActionMetadata EmptyMetaData;
	local VisualizationActionMetadata ActionMetaData;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_InteractiveObject InteractiveObject;
	local X2Action_PlaySoundAndFlyOver CharSpeechAction;
	local XComGameState_EnvironmentDamage DamageEvent;    
	local X2Action_Delay DelayAction;
	local bool bMoveContainsTeleport;
	local int MovingUnitIndex;
	local X2Action_UpdateUI UpdateUIAction;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local array<X2Action> Nodes;
	local X2Action_MarkerNamed JoinActions;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	for(MovingUnitIndex = 0; MovingUnitIndex < AbilityContext.InputContext.MovementPaths.Length; ++MovingUnitIndex)
	{
		MovingUnitRef = AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovingUnitRef;

		ActionMetaData = EmptyMetaData;
		ActionMetaData.StateObject_OldState = History.GetGameStateForObjectID(MovingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetaData.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(MovingUnitRef.ObjectID);
		ActionMetaData.VisualizeActor = History.GetVisualizer(MovingUnitRef.ObjectID);
		MovingUnitVisualizer = XGUnit(ActionMetaData.VisualizeActor);
		
		//The next two actions are parented to the Build Tree, as they are the beginning of the move sequence for an individual unit. Each move sequence will run in parallel with the 
		//others, being joined at the end of this function by the tree insert end node.

		// pause a few seconds
		if(MovingUnitVisualizer.GetTeam() == eTeam_XCom)
		{
			DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false, VisualizationMgr.BuildVisTree));
			DelayAction.Duration = default.TypicalMoveDelay;
		}

		CharSpeechAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false, DelayAction != none ? DelayAction : VisualizationMgr.BuildVisTree));

		//Civilians on the neutral team are not allowed to have sound + flyover for moving
		if(AbilityContext.InputContext.AbilityTemplateName == 'StandardMove' && XComGameState_Unit(ActionMetaData.StateObject_NewState).GetTeam() != eTeam_Neutral)
		{
			if (XComGameState_Unit(ActionMetaData.StateObject_NewState).IsPanicked())
			{
				//CharSpeechAction.SetSoundAndFlyOverParameters(None, "", 'Panic', eColor_Good);
			}
			else
			{
				if(AbilityContext.InputContext.MovementPaths[MovingUnitIndex].CostIncreases.Length == 0)
					CharSpeechAction.SetSoundAndFlyOverParameters(None, "", 'Moving', eColor_Good);
				else
					CharSpeechAction.SetSoundAndFlyOverParameters(None, "", 'Dashing', eColor_Good);
			}
		}

		class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, ActionMetaData );

		// update the unit flag to show the new cover state/moves remaining
		UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetaData, AbilityContext));
		UpdateUIAction.SpecificID = MovingUnitRef.ObjectID;
		UpdateUIAction.UpdateType = EUIUT_UnitFlag_Moves;

		UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetaData, AbilityContext));
		UpdateUIAction.SpecificID = MovingUnitRef.ObjectID;
		UpdateUIAction.UpdateType = EUIUT_UnitFlag_Cover;
		
		// Add "civilian sighted" and/or "advent sighted" VO cues.
		// Removed per Jake
		//MoveAbility_BuildVisForNewUnitVOCallouts(VisualizeGameState, ActionMetaData);
		bMoveContainsTeleport = VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_MoveTeleport', ActionMetaData.VisualizeActor) != none;
	}		

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		ActionMetaData = EmptyMetaData;
		//Don't necessarily have a previous state, so just use the one we know about
		ActionMetaData.StateObject_OldState = InteractiveObject; 
		ActionMetaData.StateObject_NewState = InteractiveObject;
		ActionMetaData.VisualizeActor = History.GetVisualizer(InteractiveObject.ObjectID);		

		// Allow alien units to move through locked doors at will, but politely shut them behind
		if( InteractiveObject.MustBeHacked() && !InteractiveObject.HasBeenHacked() && MovingUnitVisualizer.GetTeam() == eTeam_Alien && !bMoveContainsTeleport )
		{
			class'X2Action_InteractOpenClose'.static.AddToVisualizationTree(ActionMetaData, AbilityContext);	
		}
		else
		{
			class'X2Action_BreakInteractActor'.static.AddToVisualizationTree(ActionMetaData, AbilityContext);		
		}		
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', DamageEvent)
	{
		ActionMetaData = EmptyMetaData;
		//Don't necessarily have a previous state, so just use the one we know about
		ActionMetaData.StateObject_OldState = DamageEvent; 
		ActionMetaData.StateObject_NewState = DamageEvent;
		ActionMetaData.VisualizeActor = none;		
		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(ActionMetaData, AbilityContext); //This is my weapon, this is my gun
	}

	//Add an end node that waits for all leaf nodes, as they may represent separate moving units moving as a group
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, Nodes);
	ActionMetaData = EmptyMetaData;
	JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false, none, Nodes));
	JoinActions.SetName("Join");	
}

// Add "civilian sighted" and/or "advent sighted" VO callouts to the given Metadata.
simulated static function MoveAbility_BuildVisForNewUnitVOCallouts(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameState_Unit CurrUnit;    
	local XComGameState_Unit PrevUnit;    
	local bool bPrevUnitIsSeen;
	local bool bCurrUnitIsSeen;
	local XGUnit MovingUnitVisualizer;

	History = `XCOMHISTORY;
	MovingUnitVisualizer = XGUnit(ActionMetadata.VisualizeActor);
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', CurrUnit)
	{
		if (CurrUnit.IsAdvent())
		{
			bCurrUnitIsSeen = (CurrUnit.m_iTeamsThatAcknowledgedMeByVO & ( int(MovingUnitVisualizer.GetTeam()) )) != 0;
			if (bCurrUnitIsSeen)
			{
				PrevUnit = XComGameState_Unit(History.GetGameStateForObjectID(CurrUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));

				if (PrevUnit != none )
				{
					bPrevUnitIsSeen = (PrevUnit.m_iTeamsThatAcknowledgedMeByVO & ( int(MovingUnitVisualizer.GetTeam()) )) != 0;

					if (!bPrevUnitIsSeen)
					{
						SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
						SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'ADVENTsighting', eColor_Good);
						break;
					}
				}
			}
		}
	}
}


//******** Overwatch Shot **********
static function X2AbilityTemplate AddOverwatchShotAbility()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ReserveActionPoints ReserveActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2Condition_UnitProperty          ShooterCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Knockback				KnockbackEffect;
	local X2Condition_Visibility			TargetVisibilityCondition;
	local array<name>                       SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'OverwatchShot');
	
	Template.bDontDisplayInAbilitySummary = true;
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
	TargetVisibilityCondition.bRequireBasicVisibility = true;
	TargetVisibilityCondition.bDisablePeeksOnMovement = true; //Don't use peek tiles for over watch shots	
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	Template.AbilityTargetConditions.AddItem(new class'X2Condition_EverVigilant');
	Template.AbilityTargetConditions.AddItem(OverwatchTargetEffectsCondition());

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);	
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);
	
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
	Template.BuildVisualizationFn = OverwatchShot_BuildVisualization;
	Template.bAllowFreeFireWeaponUpgrade = false;	
	Template.bAllowAmmoEffects = true;
	Template.AssociatedPassives.AddItem('HoloTargeting');

	//  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
	Template.AddTargetEffect(class'X2Ability_Chosen'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowBonusWeaponEffects = true;

	// Damage Effect
	//
	Template.AddTargetEffect(default.WeaponUpgradeMissDamage);

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.AddTargetEffect(KnockbackEffect);

	class'X2StrategyElement_XpackDarkEvents'.static.AddStilettoRoundsEffect(Template);

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'OverwatchShot'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'OverwatchShot'
	
	return Template;	
}

static function X2AbilityTemplate PistolOverwatchShotHelper(X2AbilityTemplate	Template)
{
	local X2AbilityCost_ReserveActionPoints ReserveActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2Condition_UnitProperty          ShooterCondition;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Knockback				KnockbackEffect;
	local array<name>                       SkipExclusions;
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2AbilityCost_Ammo				AmmoCost;

	Template.bDontDisplayInAbilitySummary = true;
	ReserveActionPointCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveActionPointCost.iNumPoints = 1;
	ReserveActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint);
	ReserveActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.ReturnFireActionPoint);
	Template.AbilityCosts.AddItem(ReserveActionPointCost);

	//	pistols are typically infinite ammo weapons which will bypass the ammo cost automatically.
	//  but if this ability is attached to a weapon that DOES use ammo, it should use it.
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bReactionFire = true;
	Template.AbilityToHitCalc = StandardAim;
	Template.AbilityToHitOwnerOnMissCalc = StandardAim;

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);	
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bRequireBasicVisibility = true;
	TargetVisibilityCondition.bDisablePeeksOnMovement = true; //Don't use peek tiles for over watch shots	
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	Template.AbilityTargetConditions.AddItem(new class'X2Condition_EverVigilant');
	Template.AbilityTargetConditions.AddItem(OverwatchTargetEffectsCondition());

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);	
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);
	
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

	Template.CinescriptCameraType = "StandardGunFiring";	
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PISTOL_OVERWATCH_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.DisplayTargetHitChance = false;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bAllowFreeFireWeaponUpgrade = false;	
	Template.bAllowAmmoEffects = true;

	// Damage Effect
	//
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	Template.AddTargetEffect(WeaponDamageEffect);
	Template.bAllowBonusWeaponEffects = true;
	
	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.AddTargetEffect(KnockbackEffect);

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	return Template;
}

static function X2AbilityTemplate PistolReturnFire(name TemplateName = 'PistolReturnFire')
{
	local X2AbilityTemplate                 Template;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	PistolOverwatchShotHelper(Template);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_returnfire";
	Template.bShowPostActivation = TRUE;
//BEGIN AUTOGENERATED CODE: Template Overrides 'PistolReturnFire'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'PistolReturnFire'

	return Template;
}

static function X2AbilityTemplate PistolOverwatchShot()
{
	local X2AbilityTemplate                 Template;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'PistolOverwatchShot');	
	PistolOverwatchShotHelper(Template);
//BEGIN AUTOGENERATED CODE: Template Overrides 'PistolOverwatchShot'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'PistolOverwatchShot'

	return Template;
}

static function X2Condition_UnitEffects OverwatchTargetEffectsCondition()
{
	local X2Condition_UnitEffects Condition;
	local int i;

	Condition = new class'X2Condition_UnitEffects';
	for (i = 0; i < default.OverwatchExcludeEffects.Length; ++i)
	{
		Condition.AddExcludeEffect(default.OverwatchExcludeEffects[i], default.OverwatchExcludeReasons[i]);
	}

	return Condition;
}

//******** Overwatch **********
static function X2AbilityTemplate AddOverwatchAbility(name TemplateName = 'Overwatch')
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

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	
	Template.bDontDisplayInAbilitySummary = true;
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true;                  //  ammo is consumed by the shot, not by this, but this should verify ammo is available
	Template.AbilityCosts.AddItem(AmmoCost);
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	ActionPointCost.AllowedTypes.RemoveItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);
	
	ReserveActionPointsEffect = new class'X2Effect_ReserveOverwatchPoints';
	Template.AddTargetEffect(ReserveActionPointsEffect);
	Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_Y;

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
	UnitValueEffect.UnitName = default.ConcealedOverwatchTurn;
	UnitValueEffect.CleanupType = eCleanup_BeginTurn;
	UnitValueEffect.NewValueToSet = 1;
	UnitValueEffect.TargetConditions.AddItem(ConcealedCondition);
	Template.AddTargetEffect(UnitValueEffect);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideIfOtherAvailable;
	Template.HideIfAvailable.AddItem('LongWatch');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY;
	Template.bNoConfirmationWithHotKey = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = OverwatchAbility_BuildVisualization;
	Template.CinescriptCameraType = "Overwatch";

	Template.Hostility = eHostility_Defensive;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;	
}

static simulated function OverwatchAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;

	local X2Action_CameraFrameAbility FrameAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_CameraRemove RemoveCameraAction;
	local UnitValue EverVigilantValue;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate AbilityTemplate;
	local string FlyOverText, FlyOverImage;
	local XGUnit UnitVisualizer;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	// Only turn the camera on the overwatcher if it is visible to the local player.
	if( !`XENGINE.IsMultiPlayerGame() || class'X2TacticalVisibilityHelpers'.static.IsUnitVisibleToLocalPlayer(UnitState.ObjectID, VisualizeGameState.HistoryIndex) )
	{
		FrameAction = X2Action_CameraFrameAbility(class'X2Action_CameraFrameAbility'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		FrameAction.AbilitiesToFrame.AddItem(Context);
		FrameAction.CameraTag = 'OverwatchCamera';
	}
					
	if (UnitState != none && UnitState.GetUnitValue(class'X2Ability_SpecialistAbilitySet'.default.EverVigilantEffectName, EverVigilantValue) && EverVigilantValue.fValue > 0)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('EverVigilant');
		if (UnitState.HasSoldierAbility('CoveringFire'))
			FlyOverText = class'XLocalizedData'.default.EverVigilantWithCoveringFire;
		else
			FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	else if (UnitState != none && UnitState.HasSoldierAbility('CoveringFire'))
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('CoveringFire');
		FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	else if (UnitState != none && UnitState.HasSoldierAbility('SkirmisherAmbush'))
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('SkirmisherAmbush');
		FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	else
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
		FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));

	if (UnitState != none)
	{
		UnitVisualizer = XGUnit(UnitState.GetVisualizer());
		if( (UnitVisualizer != none) && !UnitVisualizer.IsMine())
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundUI.OverwatchCue', FlyOverText, 'Overwatch', eColor_Bad, FlyOverImage);
		}
		else
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(none, FlyOverText, 'Overwatch', eColor_Good, FlyOverImage);
		}
	}

	if( FrameAction != none )
	{
		RemoveCameraAction = X2Action_CameraRemove(class'X2Action_CameraRemove'.static.AddToVisualizationTree(ActionMetaData, Context));
		RemoveCameraAction.CameraTagToRemove = 'OverwatchCamera';
	}

	//****************************************************************************************
}

static function X2AbilityTemplate PistolOverwatch()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;
	local array<name>                       SkipExclusions;
	local X2Effect_CoveringFire             CoveringFireEffect;
	local X2Condition_AbilityProperty       CoveringFireCondition;
	local X2Condition_UnitProperty          ConcealedCondition;
	local X2Effect_SetUnitValue             UnitValueEffect;
	local X2Condition_UnitEffects           SuppressedCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PistolOverwatch');
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	ActionPointCost.AllowedTypes.RemoveItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);
	
	ReserveActionPointsEffect = new class'X2Effect_ReserveOverwatchPoints';
	Template.AddTargetEffect(ReserveActionPointsEffect);

	CoveringFireEffect = new class'X2Effect_CoveringFire';
	CoveringFireEffect.AbilityToActivate = 'PistolOverwatchShot';
	CoveringFireEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	CoveringFireCondition = new class'X2Condition_AbilityProperty';
	CoveringFireCondition.OwnerHasSoldierAbilities.AddItem('CoveringFire');
	CoveringFireEffect.TargetConditions.AddItem(CoveringFireCondition);
	Template.AddTargetEffect(CoveringFireEffect);

	ConcealedCondition = new class'X2Condition_UnitProperty';
	ConcealedCondition.ExcludeFriendlyToSource = false;
	ConcealedCondition.IsConcealed = true;
	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = default.ConcealedOverwatchTurn;
	UnitValueEffect.CleanupType = eCleanup_BeginTurn;
	UnitValueEffect.NewValueToSet = 1;
	UnitValueEffect.TargetConditions.AddItem(ConcealedCondition);
	Template.AddTargetEffect(UnitValueEffect);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_pistoloverwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PISTOL_OVERWATCH_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = OverwatchAbility_BuildVisualization;
	Template.CinescriptCameraType = "Overwatch";

	Template.Hostility = eHostility_Defensive;

	Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_Y;
	Template.bNoConfirmationWithHotKey = true;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;
}

static function X2AbilityTemplate SniperRifleOverwatch()
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

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SniperRifleOverwatch');
	
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

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);
	
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
	UnitValueEffect.UnitName = default.ConcealedOverwatchTurn;
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
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = OverwatchAbility_BuildVisualization;
	Template.CinescriptCameraType = "Overwatch";

	Template.Hostility = eHostility_Defensive;

	Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_Y;
	Template.bNoConfirmationWithHotKey = true;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;	
}

//******** Reload **********
static function X2AbilityTemplate AddReloadAbility(name TemplateName = 'Reload')
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          ShooterPropertyCondition;
	local X2Condition_AbilitySourceWeapon   WeaponCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local array<name>                       SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	
	Template.bDontDisplayInAbilitySummary = true;
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	Template.AbilityCosts.AddItem(ActionPointCost);

	ShooterPropertyCondition = new class'X2Condition_UnitProperty';	
	ShooterPropertyCondition.ExcludeDead = true;                    //Can't reload while dead
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);
	WeaponCondition = new class'X2Condition_AbilitySourceWeapon';
	WeaponCondition.WantsReload = true;
	Template.AbilityShooterConditions.AddItem(WeaponCondition);
	Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_R;

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.AbilityToHitCalc = default.DeadEye;
	
	Template.AbilityTargetStyle = default.SelfTarget;
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_reload";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.RELOAD_PRIORITY;
	Template.bNoConfirmationWithHotKey = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.DisplayTargetHitChance = false;

	Template.ActivationSpeech = 'Reloading';

	Template.BuildNewGameStateFn = ReloadAbility_BuildGameState;
	Template.BuildVisualizationFn = ReloadAbility_BuildVisualization;

	ActionPointCost.iNumPoints = 1;
	Template.Hostility = eHostility_Neutral;

	Template.CinescriptCameraType = "GenericAccentCam";
	Template.OverrideAbilityAvailabilityFn = Reload_OverrideAbilityAvailability;

	return Template;	
}

function Reload_OverrideAbilityAvailability(out AvailableAction Action, XComGameState_Ability AbilityState, XComGameState_Unit OwnerState)
{
	if (Action.AvailableCode == 'AA_Success')
	{
		if (AbilityState.GetSourceWeapon().Ammo == 0)
			Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.MUST_RELOAD_PRIORITY;
	}
}

simulated function XComGameState ReloadAbility_BuildGameState( XComGameStateContext Context )
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Item WeaponState, NewWeaponState;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local bool bFreeReload;
	local int i;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);	
	AbilityContext = XComGameStateContext_Ability(Context);	
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.AbilityRef.ObjectID ));

	WeaponState = AbilityState.GetSourceWeapon();
	NewWeaponState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', WeaponState.ObjectID));

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));	

	//  check for free reload upgrade
	bFreeReload = false;
	WeaponUpgrades = WeaponState.GetMyWeaponUpgradeTemplates();
	for (i = 0; i < WeaponUpgrades.Length; ++i)
	{
		if (WeaponUpgrades[i].FreeReloadCostFn != none && WeaponUpgrades[i].FreeReloadCostFn(WeaponUpgrades[i], AbilityState, UnitState))
		{
			bFreeReload = true;
			break;
		}
	}
	if (!bFreeReload)
		AbilityState.GetMyTemplate().ApplyCost(AbilityContext, AbilityState, UnitState, NewWeaponState, NewGameState);	

	//  refill the weapon's ammo	
	NewWeaponState.Ammo = NewWeaponState.GetClipSize();
	
	return NewGameState;	
}

simulated function ReloadAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          ShootingUnitRef;	
	local X2Action_PlayAnimation		PlayAnimation;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;

	local XComGameState_Ability Ability;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	ShootingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(ShootingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(ShootingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(ShootingUnitRef.ObjectID);
					
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	PlayAnimation.Params.AnimName = 'HL_Reload';

	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", Ability.GetMyTemplate().ActivationSpeech, eColor_Good);

		//****************************************************************************************
}
//****************************************

//******** Interact Ability **********
static function X2AbilityTemplate AddInteractAbility(optional name TemplateName = 'Interact')
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2Condition_UnitProperty          UnitPropertyCondition;	
	local X2Condition_Interactive			InteractionCondition;
	local array<name>                       SkipExclusions;
	//local X2Condition_Visibility			VisibilityCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2AbilityTarget_Single            SingleTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.bDontDisplayInAbilitySummary = true;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_interact";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.INTERACT_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_V;
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	//Disabled until we can fix the visiblity self blocking issues 
	//VisibilityCondition = new class'X2Condition_Visibility';
	//VisibilityCondition.bRequireLOS = true;
	//Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	InteractionCondition = new class'X2Condition_Interactive';
	InteractionCondition.InteractionType = eInteractionType_Normal;
	InteractionCondition.RequiredAbilityName = Template.DataName;
	Template.AbilityTargetConditions.AddItem(InteractionCondition);

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	Template.BuildNewGameStateFn = InteractAbility_BuildGameState;
	Template.BuildVisualizationFn = InteractAbility_BuildVisualization;

	//  cannot perform interaction when unit is out of action points, however it does not use up an action point
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.Hostility = eHostility_Neutral;

	return Template;
}

simulated function XComGameState InteractAbility_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;
	local XComGameState_InteractiveObject ObjectState;
	local int InteractionPointID;
	local int i;
	local array<XComInteractPoint> InteractionPoints;
	History = `XCOMHISTORY;

	//Build the new game state frame
	NewGameState = History.CreateNewGameState(true, Context);	

	AbilityContext = XComGameStateContext_Ability(Context);	
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	InteractionPoints = class'X2Condition_UnitInteractions'.static.GetUnitInteractionPoints(UnitState, eInteractionType_Normal);

	// add a blank copy of the unit state so that this visualization blocks until he is finished doing any previous changes
	NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID);

	// get the previous object state
	`assert(InteractionPoints.Length > 0); // if this has changed since the condition was checked, something scary is happening
	InteractionPointID = 0;
	for( i = 0; i < InteractionPoints.Length; i++)
	{
		if( InteractionPoints[i].InteractiveActor.ObjectID == XComGameStateContext_Ability(Context).InputContext.PrimaryTarget.ObjectID )
		{
			InteractionPointID = i;
		}
	}

	ObjectState = InteractionPoints[InteractionPointID].InteractiveActor.GetInteractiveState();

	// create a new object state with the updated object state
	ObjectState = XComGameState_InteractiveObject(NewGameState.ModifyStateObject(class'XComGameState_InteractiveObject', ObjectState.ObjectID));
	ObjectState.Interacted(UnitState, NewGameState, InteractionPoints[InteractionPointID].InteractSocketName);

	// award all loot on the opened/interacted with object to the interacting unit
	ObjectState.MakeAvailableLoot(NewGameState);
	class'Helpers'.static.AcquireAllLoot(ObjectState, AbilityContext.InputContext.SourceObject, NewGameState);

	//Return the game state we have created
	return NewGameState;	
}

simulated function InteractAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local XComGameState_InteractiveObject InteractiveObject;
	local StateObjectReference          InteractingUnitRef;	

	local VisualizationActionMetadata       EmptyTrack;
	local VisualizationActionMetadata       ActionMetadata;
	local VisualizationActionMetadata		DoorMetadata;

	local X2Action_Interact InteractAction;
	local XComInteractiveLevelActor InteractiveVisualizer;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	
	InteractiveObject = XComGameState_InteractiveObject(Context.AssociatedState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	InteractAction = X2Action_Interact(class'X2Action_Interact'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));

	if( InteractiveObject.IsDoor() && InteractiveObject.HasDestroyAnim() )
	{
		InteractiveVisualizer = XComInteractiveLevelActor(History.GetVisualizer(InteractiveObject.ObjectID));
		if( InteractiveVisualizer != None && InteractiveVisualizer.IsOpenDoor() )
		{
			DoorMetadata = EmptyTrack;
			DoorMetadata.StateObject_OldState = InteractiveObject;
			DoorMetadata.StateObject_NewState = InteractiveObject;
			DoorMetadata.VisualizeActor = InteractiveVisualizer;

			class'X2Action_BreakInteractActor'.static.AddToVisualizationTree(DoorMetadata, Context, false, InteractAction);
		}
	}
	
	class'X2Action_Loot'.static.AddToVisualizationTreeIfLooted(InteractiveObject, Context, ActionMetadata);
	//****************************************************************************************
}

//******** Interact With Objective Ability **********
static function X2AbilityTemplate AddObjectiveInteractAbility(optional name TemplateName)
{
	local X2AbilityTemplate AbilityTemplate;

	AbilityTemplate = AddInteractAbility(TemplateName);
	AbilityTemplate.AbilityIconColor = class'UIUtilities_Colors'.const.OBJECTIVEICON_HTML_COLOR;
	AbilityTemplate.ShotHUDPriority = class'UIUtilities_Tactical'.const.OBJECTIVE_INTERACT_PRIORITY;
	AbilityTemplate.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_V;

	return AbilityTemplate;
}

//******** Hack Ability **********
static function X2AbilityTemplate FinalizeHack()
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2AbilityTarget_Single            SingleTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FinalizeHack');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hack";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.HACK_PRIORITY;
	Template.bDisplayInUITooltip = false;
	
	// successfully completing the hack requires and costs an action point
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_Hacking';
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');      //  This will be activated automatically by the hacking UI.

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.CinescriptCameraType = "Hack";

	Template.BuildNewGameStateFn = FinalizeHackAbility_BuildGameState;
	Template.BuildVisualizationFn = FinalizeHackAbility_BuildVisualization;
	Template.MergeVisualizationFn = FinalizeHackAbility_MergeVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

static function X2AbilityTemplate CancelHack()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTarget_Single            SingleTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CancelHack');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hack";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.HACK_PRIORITY;
	Template.bDisplayInUITooltip = false;

	// canceling a hack does not cost any action points

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');      //  This will be activated automatically by the hacking UI.

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.CinescriptCameraType = "Hack";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = None;

	Template.bDontDisplayInAbilitySummary = true;
	Template.ConcealmentRule = eConceal_AlwaysEvenWithObjective;

	return Template;
}

static function X2AbilityTemplate AddHackAbility(optional name TemplateName = 'Hack')
{
	local X2AbilityTemplate             Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2AbilityTarget_Single            SingleTarget;
	local X2Condition_HackingTarget         HackCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.HACK_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_V;
	Template.bUniqueSource = true;
	
	// beginning a hack requires an action point to be available, so that it can be consumed if the hack is finalized
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;                   //  the FinalizeHack ability will consume the action point
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;        //  the FinalizeHack ability will make the actual roll
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	HackCondition = new class'X2Condition_HackingTarget';
	HackCondition.RequiredAbilityName = TemplateName;
	Template.AbilityTargetConditions.AddItem(HackCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.FinalizeAbilityName = 'FinalizeHack';
	Template.CancelAbilityName = 'CancelHack';
	Template.AdditionalAbilities.AddItem('FinalizeHack');
	Template.AdditionalAbilities.AddItem('CancelHack');
	Template.ConcealmentRule = eConceal_AlwaysEvenWithObjective;

	Template.CinescriptCameraType = "Hack";

	Template.BuildNewGameStateFn = HackAbility_BuildGameState;
	Template.BuildVisualizationFn = HackAbility_BuildVisualization;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

static function XComGameState HackAbility_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;

	//Build the new game state frame
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);

	HackAbility_FillOutGameState(NewGameState);

	return NewGameState;
}

static function XComGameState HackAbility_FillOutGameState(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_BaseObject TargetState;
	local array<name> PossibleHackRewards;
	local array<int> HackRollMods;
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate HackRewardTemplate;
	local name HackRewardName;
	local int RollMod;
	local Hackable HackableObject;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit TargetUnit;
	local X2AbilityTemplate AbilityTemplate;
	local X2EventManager EventManager;

	History = `XCOMHISTORY;

	TypicalAbility_FillOutGameState(NewGameState);

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));
	AbilityTemplate = AbilityState.GetMyTemplate();

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);

	HackableObject = Hackable(TargetState);
	`assert(HackableObject != none);     //  if we don't have an interactive object or a unit, what is going on?

	HackRollMods = HackableObject.GetHackRewardRollMods();

	if( HackRollMods.Length == 0 )
	{
		HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

		TargetState = NewGameState.ModifyStateObject(TargetState.Class, TargetState.ObjectID);

		HackableObject = Hackable(TargetState);

		PossibleHackRewards = HackableObject.GetHackRewards(AbilityTemplate.FinalizeAbilityName);
		foreach PossibleHackRewards(HackRewardName)
		{
			HackRewardTemplate = HackRewardTemplateManager.FindHackRewardTemplate(HackRewardName);

			RollMod = `SYNC_RAND_STATIC(HackRewardTemplate.HackSuccessVariance * 2) - HackRewardTemplate.HackSuccessVariance;

			HackRollMods.AddItem(RollMod);
		}

		HackableObject.SetHackRewardRollMods(HackRollMods);
	}

	TargetUnit = XComGameState_Unit(TargetState);
	if( AbilityContext.ResultContext.HitResult != eHit_Miss && 
	    (AbilityTemplate.DataName == 'SKULLJACKAbility' || AbilityTemplate.DataName == 'SKULLMINEAbility') &&
	   TargetUnit != None &&
	   (TargetUnit.IsAdvent() || TargetUnit.GetMyTemplate().CharacterGroupName == 'Cyberus') )
	{
		EventManager = `XEVENTMGR;
			
		// Golden Path special triggers - only on SKULLJACK, not SKULLMINE.
		if (AbilityTemplate.DataName == 'SKULLJACKAbility')
		{
			if (TargetUnit.GetMyTemplate().CharacterGroupName == 'AdventCaptain')
			{
				EventManager.TriggerEvent('HackedACaptain', TargetUnit, TargetUnit, NewGameState);
				`ONLINEEVENTMGR.UnlockAchievement(AT_SkulljackAdventOfficer);
			}
			else if (TargetUnit.GetMyTemplate().CharacterGroupName == 'Cyberus')
			{
				EventManager.TriggerEvent('HackedACodex', TargetUnit, TargetUnit, NewGameState);
			}
		}

		// Achievement is applicable to SKULLJACK or SKULLMINE.
		`XACHIEVEMENT_TRACKER.OnUnitSkulljacked(TargetUnit);
	}

	//Return the game state we have created
	return NewGameState;
}

simulated function XComGameState FinalizeHackAbility_BuildGameState(XComGameStateContext Context)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit UnitState, TargetUnit;
	local XComGameState_InteractiveObject ObjectState;
	local XComGameState_Item SourceWeaponState;
	local XComGameState_BattleData BattleData;
	local X2AbilityTemplate AbilityTemplate;
	local array<XComInteractPoint> InteractionPoints;
	local X2EventManager EventManager;
	local bool bHackSuccess;
	local array<int> HackRollMods;
	local Hackable HackableObject;
	local UIHackingScreen HackingScreen;
	local int UserSelectedReward;

	EventManager = `XEVENTMGR;
	History = `XCOMHISTORY;

	//Build the new game state frame
	NewGameState = TypicalAbility_BuildGameState(Context);	

	AbilityContext = XComGameStateContext_Ability(Context);	
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));	
	AbilityTemplate = AbilityState.GetMyTemplate();
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	SourceWeaponState = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	InteractionPoints = class'X2Condition_UnitInteractions'.static.GetUnitInteractionPoints(UnitState, eInteractionType_Hack);

	// add a copy of the unit and update apply the costs of the ability to him
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	if (SourceWeaponState != none)
		SourceWeaponState = XComGameState_Item(NewGameState.ModifyStateObject(SourceWeaponState.Class, SourceWeaponState.ObjectID));

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);
	TargetState = NewGameState.ModifyStateObject(TargetState.Class, TargetState.ObjectID);

	HackableObject = Hackable(TargetState);

	ObjectState = XComGameState_InteractiveObject(TargetState);
	if (ObjectState == none)
		TargetUnit = XComGameState_Unit(TargetState);

	`assert(ObjectState != none || TargetUnit != none);     //  if we don't have an interactive object or a unit, what is going on?

	HackingScreen = UIHackingScreen(`SCREENSTACK.GetScreen(class'UIHackingScreen'));

	// The bottom values of 0 and 100.0f are for when the HackingScreen is not available.
	// When this is the case, the hack should always succeed and award the lowest valued reward, index 0.
	bHackSuccess = class'X2HackRewardTemplateManager'.static.AcquireHackRewards(
		HackingScreen,
		UnitState, 
		TargetState, 
		AbilityContext.ResultContext.StatContestResult, 
		NewGameState, 
		AbilityTemplate.DataName,
		UserSelectedReward,
		0,
		100.0f);

	if( ObjectState != none )
	{
		ObjectState.bHasBeenHacked = bHackSuccess;
		ObjectState.UserSelectedHackReward = UserSelectedReward;
		if( ObjectState.bHasBeenHacked )
		{
			// award all loot on the hacked object to the hacker
			ObjectState.MakeAvailableLoot(NewGameState);
			class'Helpers'.static.AcquireAllLoot(ObjectState, AbilityContext.InputContext.SourceObject, NewGameState);

			EventManager.TriggerEvent('ObjectHacked', UnitState, ObjectState, NewGameState);
			`TRIGGERXP('XpSuccessfulHack', UnitState.GetReference(), ObjectState.GetReference(), NewGameState);

			// automatically interact with the hacked object as well
			if( InteractionPoints.Length > 0 )
				ObjectState.Interacted(UnitState, NewGameState, InteractionPoints[0].InteractSocketName);
		}

		if( ObjectState.bOffersTacticalHackRewards )
		{
			BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
			BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
			BattleData.bTacticalHackCompleted = true;
		}
	}
	else if( TargetUnit != none )
	{
		TargetUnit.bHasBeenHacked = bHackSuccess;
		TargetUnit.UserSelectedHackReward = UserSelectedReward;
		if( TargetUnit.bHasBeenHacked )
		{
			`TRIGGERXP('XpSuccessfulHack', UnitState.GetReference(), TargetUnit.GetReference(), NewGameState);

		}
	}

	HackableObject.SetHackRewardRollMods(HackRollMods);

	//Return the game state we have created
	return NewGameState;	
}

simulated function HackAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;	
	local XComGameState_Unit SourceUnit;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;

	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit TargetUnit;
	local XComGameState_InteractiveObject ObjectState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(InteractingUnitRef.ObjectID));

	TargetState = History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID);
	ObjectState = XComGameState_InteractiveObject(TargetState);
	TargetUnit = XComGameState_Unit(TargetState);

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	// Add a soldier bark for the hack attempt.
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	if (ObjectState != none)
	{
		if( ObjectState.IsDoor() )
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackDoor', eColor_Good);
		}
		else
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackWorkstation', eColor_Good);
		}
	}
	else if (TargetUnit != none)
	{
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackUnit', eColor_Good);
	}
	else
	{
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'AttemptingHack', eColor_Good);
	}

	// Only run the X2Action_hack on the player that is performing the hack.  The other player gets a flyover on the FinalizeHack visualization.
	if( SourceUnit.ControllingPlayer.ObjectID == `TACTICALRULES.GetLocalClientPlayerObjectID() )
	{
		class'X2Action_Hack'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	}
	
	}


// Hacking is split into two abilities, "Hack" and "FinalizeHack".
// This function is used for visualizing the second half of the hacking
// process, and is for letting the player know the results of the hack
// attempt.  mdomowicz 2015_06_30
simulated function FinalizeHackAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local StateObjectReference          InteractingUnitRef;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;

	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item ItemState;
	local XComGameState_InteractiveObject ObjectState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	local XComGameState_Unit SourceUnit;
	local String HackText;
	local bool bLocalUnit;
	local array<Name> HackRewards;
	local Hackable HackTarget;
	local X2HackRewardTemplateManager HackMgr;
	local int ChosenHackIndex;
	local X2HackRewardTemplate HackRewardTemplate;
	local EWidgetColor TextColor;
	local XGParamTag kTag;

	History = `XCOMHISTORY;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(InteractingUnitRef.ObjectID));

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);
	ObjectState = XComGameState_InteractiveObject(TargetState);
	TargetUnit = XComGameState_Unit(TargetState);
	ItemState = XComGameState_Item( VisualizeGameState.GetGameStateForObjectID( AbilityContext.InputContext.ItemObject.ObjectID ) );

	bLocalUnit = SourceUnit.ControllingPlayer.ObjectID == `TACTICALRULES.GetLocalClientPlayerObjectID();

	if( bLocalUnit )
	{
		if( ObjectState != none )
		{
			if( ObjectState.HasBeenHacked() )
			{
				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
				SoundAndFlyOver.BlockUntilFinished = true;
				SoundAndFlyOver.DelayDuration = 1.5f;

				if( ObjectState.IsDoor() )
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackDoorSuccess', eColor_Good);
				}
				else
				{
					// Can't use 'HackWorkstationSuccess', because it doesn't work for Advent Towers
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackSuccess', eColor_Good,,,true); //block so that the VO doesn't run into loot collected VO or other lines that may play after
				}

				if( ItemState.CosmeticUnitRef.ObjectID == 0 )
				{
					// if the hack was successful, we will also interact with it
					class'X2Action_Interact'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);

					// and show any looting we did
					class'X2Action_Loot'.static.AddToVisualizationTreeIfLooted(ObjectState, AbilityContext, ActionMetadata);
				}
			}
			else
			{
				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackFailed', eColor_Bad);
				SoundAndFlyOver.BlockUntilFinished = true;
				SoundAndFlyOver.DelayDuration = 1.5f;
			}
		}
		else if( TargetUnit != none )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));

			if ( AbilityContext.InputContext.AbilityTemplateName == 'FinalizeSKULLJACK' || AbilityContext.InputContext.AbilityTemplateName == 'FinalizeSKULLMINE' )
			{
				// 'StunnedAlien' and 'AlienNotStunned' VO lines are appropriate for skull jack activation (or failed activation),
				// but there are no good cues for the result.  So we just use the generic cues.
				if( TargetUnit.bHasBeenHacked )
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackSuccess', eColor_Good);
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackFailed', eColor_Bad);
				}
			}
			else if( TargetUnit.IsTurret() )
			{
				if( TargetUnit.bHasBeenHacked )
				{
					// Can't use 'HackTurretSuccess' here because all the VO lines are about taking control of the
					// turret, but sometimes the success result is shutting down the turret instead.
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackSuccess', eColor_Good);
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackTurretFailed', eColor_Bad);
				}
			}
			else
			{
				// If we got here, then the target unit must be a robot...
				if( TargetUnit.bHasBeenHacked )
				{
					// Can't use 'HackUnitSuccess' for the exact same reason we can't use 'HackTurretSuccess' above.
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackSuccess', eColor_Good);
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackUnitFailed', eColor_Bad);
				}
			}

			// This prevents a VO overlap that occurs when using skullmine or skulljack.  mdomowicz 2015_11_18
			if( AbilityContext.InputContext.AbilityTemplateName == 'FinalizeSKULLMINE' || AbilityContext.InputContext.AbilityTemplateName == 'FinalizeSKULLJACK' )
			{
				SoundAndFlyOver.DelayDuration = 1.5f;  // found empirically.
				SoundAndFlyOver.BlockUntilFinished = true;
			}
		}
		else
		{
			`assert(false);
		}
	}
	else
	{
		HackTarget = Hackable(TargetState);
		if( HackTarget != None )
		{
			HackRewards = HackTarget.GetHackRewards(AbilityContext.InputContext.AbilityTemplateName);
			HackMgr = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

			if( !HackTarget.HasBeenHacked() )
			{
				ChosenHackIndex = 0;
				HackText = EnemyHackAttemptFailureString;
				TextColor = eColor_Bad;
			}
			else
			{
				HackText = EnemyHackAttemptSuccessString;
				ChosenHackIndex = HackTarget.GetUserSelectedHackOption();
				TextColor = eColor_Good;
			}
			
			if( ChosenHackIndex >= HackRewards.Length )
			{
				`RedScreen("FinalizeHack Visualization Error- Selected Hack Option >= num hack reward options!  @acheng");
			}
			HackRewardTemplate = HackMgr.FindHackRewardTemplate(HackRewards[ChosenHackIndex]);

			kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			kTag.StrValue0 = HackRewardTemplate.GetFriendlyName();
			
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, `XEXPAND.ExpandString(HackText), '', TextColor);
		}
	}
}

simulated function FinalizeHackAbility_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisualizationMgr;
	local array<X2Action> MarkerActions;
	local X2Action MarkerAction;
	local X2Action TargetParentAction;
	local X2Action TargetChildSequenceEndAction;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local name MergingAbilityName;

	// this is essentially doing an SPT_AfterSequential vis merge, but is not dependent on the parent, 
	// since the parent game state is not correctly set for the FinalizeAbility 
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	// for the finalize hack (of any type of hack) we want to find the end of the visualization for the hack ability that this ability is the FinalizeAbilityName of
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	VisualizationMgr.GetNodesOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd', MarkerActions);
	TargetChildSequenceEndAction = MarkerActions[0];

	AbilityContext = XComGameStateContext_Ability(TargetChildSequenceEndAction.StateChangeContext);
	`assert( AbilityContext != none );

	MergingAbilityName = AbilityContext.InputContext.AbilityTemplateName;

	VisualizationMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerTreeInsertEnd', MarkerActions);
	foreach MarkerActions(MarkerAction)
	{
		if( X2Action_MarkerTreeInsertEnd(MarkerAction) != none )
		{
			// have to see if this is the right end node
			AbilityContext = XComGameStateContext_Ability(MarkerAction.StateChangeContext);
			if( AbilityContext != none )
			{
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

				// out "parent" is the end node of the ability context that instigated this ability
				if( AbilityTemplate != none && AbilityTemplate.FinalizeAbilityName == MergingAbilityName )
				{
					TargetParentAction = MarkerAction;
				}
			}
		}
	}

	`assert(TargetChildSequenceEndAction != none);
	`assert(TargetParentAction != none);

	VisualizationMgr.InsertSubtree(BuildTree, TargetChildSequenceEndAction, TargetParentAction);

}

//******** Hack Objective Ability **********
static function X2AbilityTemplate AddObjectiveHackAbility(optional name TemplateName)
{
	local X2AbilityTemplate AbilityTemplate;

	AbilityTemplate = AddHackAbility(TemplateName);
	AbilityTemplate.AbilityIconColor = class'UIUtilities_Colors'.const.OBJECTIVEICON_HTML_COLOR;
	AbilityTemplate.ShotHUDPriority = class'UIUtilities_Tactical'.const.OBJECTIVE_INTERACT_PRIORITY;

	return AbilityTemplate;
}

//******** Plant Bomb Ability **********
static function X2AbilityTemplate AddPlantBombAbility()
{
	local X2AbilityTemplate Template;

	Template = AddObjectiveInteractAbility('Interact_PlantBomb');
	//Template.BuildVisualizationFn = PlantBombAbility_BuildVisualization;

	return Template;
}

simulated function PlantBombAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit SourceUnit;
	local X2Action_PlayAnimation PlayAnimAction;

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID,,VisualizeGameState.HistoryIndex));

	// soldiers play a matinee from kismet, non-soldiers just play a loot animation (since the skeleton won't match the matinee)
	if(SourceUnit.GetMyTemplateName() != 'Soldier')
	{
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceUnit.ObjectID,, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = SourceUnit;
		ActionMetadata.VisualizeActor = SourceUnit.GetVisualizer();

		class'X2Action_ExitCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);

		PlayAnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
		PlayAnimAction.bFinishAnimationWait = true;
		PlayAnimAction.Params.AnimName = 'HL_LootBodyStart';

		PlayAnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
		PlayAnimAction.bFinishAnimationWait = true;
		PlayAnimAction.Params.AnimName = 'HL_LootStop';

		class'X2Action_EnterCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);

	}
}

//*******************************************

//******** Gather Evidence Ability **********
static function X2AbilityTemplate AddGatherEvidenceAbility()
{
	local X2AbilityTemplate Template;

	// start with the interact ability as a base
	Template = AddInteractAbility('GatherEvidence');

	return Template;
}
//*******************************************

//******** PlantX4 Ability **********
static function X2AbilityTemplate AddPlantExplosiveMissionDeviceAbility()
{
	local X2AbilityTemplate Template;

	// start with the interact ability as a base
	Template = AddInteractAbility('PlantExplosiveMissionDevice');

	// and modify
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ConcealmentRule = eConceal_Never;

	return Template;
}
//*******************************************

//******** Loot Ability **********
static function X2AbilityTemplate AddLootAbility()
{
	local X2AbilityTemplate                 Template;		
	local X2Condition_UnitProperty          UnitPropertyCondition;	
	local X2Condition_Lootable              LootableCondition;
	local X2Condition_Visibility			VisibilityCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2AbilityTrigger_EventListener    EventTrigger;
	local X2AbilityMultiTarget_Radius       MultiTarget;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Condition_UnitEffects			UnitEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Loot');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_loot"; 
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.LOOT_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.bBypassAbilityConfirm = true;
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); // Do not allow "Looting" in MP!
		
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeImpaired = true;
	UnitPropertyCondition.ImpairedIgnoresStuns = true;
	UnitPropertyCondition.ExcludePanicked = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	UnitEffects = new class'X2Condition_UnitEffects';
	UnitEffects.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_CarryingUnit');
	Template.AbilityShooterConditions.AddItem(UnitEffects);

	LootableCondition = new class'X2Condition_Lootable';
	LootableCondition.LootableRange = default.LOOT_RANGE;
	LootableCondition.bRestrictRange = true;
	Template.AbilityTargetConditions.AddItem(LootableCondition);

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bRequireLOS = true;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	// loot will also automatically trigger at the end of a move if it is possible
	EventTrigger = new class'X2AbilityTrigger_EventListener';
	EventTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_EndOfMoveLoot;
	EventTrigger.ListenerData.EventID = 'UnitMoveFinished';
	EventTrigger.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventTrigger);

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;	

	MultiTarget = new class'X2AbilityMultiTarget_Loot';
	MultiTarget.bUseWeaponRadius = false;
	MultiTarget.fTargetRadius = default.EXPANDED_LOOT_RANGE;
	MultiTarget.bIgnoreBlockingCover = true; // UI doesn't/cant conform to cover so don't block the collection either
	Template.AbilityMultiTargetStyle = MultiTarget;

	LootableCondition = new class'X2Condition_Lootable';
	//  Note: the multi target handles restricting the range on these based on the primary target's location
	Template.AbilityMultiTargetConditions.AddItem(LootableCondition);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
		
	Template.BuildNewGameStateFn = LootAbility_BuildGameState;
	Template.BuildVisualizationFn = LootAbility_BuildVisualization;
	Template.AssociatedPlayTiming = SPT_AfterSequential;
	Template.Hostility = eHostility_Neutral;

	Template.CinescriptCameraType = "Loot";

	return Template;
}

simulated function XComGameState LootAbility_BuildGameState(XComGameStateContext Context)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_BaseObject TargetState;

	// first, build game state like normal
	NewGameState = TypicalAbility_BuildGameState(Context);

	// then complete the loot action
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(Context);

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);
	if( TargetState != none )
	{
		TargetState = NewGameState.ModifyStateObject(TargetState.Class, TargetState.ObjectID);

		// award all loot on the hacked object to the hacker
		Lootable(TargetState).MakeAvailableLoot(NewGameState);
		class'Helpers'.static.AcquireAllLoot(Lootable(TargetState), AbilityContext.InputContext.SourceObject, NewGameState);
	}

	return NewGameState;
}

simulated function LootAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;	
	local Lootable                      LootTarget;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;

	if( `TACTICALRULES.HasTacticalGameEnded() )
	{
		return;
	}

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	
	LootTarget = Lootable(History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	class'X2Action_Loot'.static.AddToVisualizationTreeIfLooted(LootTarget, Context, ActionMetadata);	
		//****************************************************************************************
}

//******** Hunker Down Ability **********
static function X2AbilityTemplate AddHunkerDownAbility(name TemplateName = 'HunkerDown')
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          PropertyCondition;
	local X2Effect_PersistentStatChange     PersistentStatChangeEffect;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local array<name>                       SkipExclusions;
	local X2Effect_RemoveEffects			RemoveEffects;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_takecover";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.HUNKER_DOWN_PRIORITY;
	Template.bDisplayInUITooltip = false;

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = HunkerDownAbility_BuildVisualization;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.DeepCoverActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	PropertyCondition = new class'X2Condition_UnitProperty';	
	PropertyCondition.ExcludeDead = true;                           // Can't hunkerdown while dead
	PropertyCondition.ExcludeFriendlyToSource = false;              // Self targeted
	PropertyCondition.ExcludeNoCover = true;                        // Unit must be in cover.
	Template.AbilityShooterConditions.AddItem(PropertyCondition);

	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	Template.AbilityTargetStyle = default.SelfTarget;

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.EffectName = 'HunkerDown';
	PersistentStatChangeEffect.BuildPersistentEffect(1 /* Turns */,,,,eGameRule_PlayerTurnBegin);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Dodge, default.HUNKERDOWN_DODGE);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Defense, default.HUNKERDOWN_DEFENSE);
	PersistentStatChangeEffect.DuplicateResponse = eDupe_Refresh;
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.AddTargetEffect(class'X2Ability_SharpshooterAbilitySet'.static.SharpshooterAimEffect());

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddTargetEffect(RemoveEffects);

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	Template.Hostility = eHostility_Defensive;
	Template.OverrideAbilityAvailabilityFn = HunkerDown_OverrideAbilityAvailability;
	Template.ConcealmentRule = eConceal_AlwaysEvenWithObjective;

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

function HunkerDown_OverrideAbilityAvailability(out AvailableAction Action, XComGameState_Ability AbilityState, XComGameState_Unit OwnerState)
{
	if (Action.AvailableCode == 'AA_Success')
	{
		if (OwnerState.IsBurning())
			Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.SHOULD_HUNKER_PRIORITY;
	}
}

simulated function HunkerDownAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;
	local X2AbilityTemplate             AbilityTemplate;
	local XComGameState_Unit            UnitState;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;
	local int EffectIndex;
	local name ApplyResult;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************	
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	
	//Civilians on the neutral team are not allowed to have sound + flyover for hunker down
	if( UnitState.GetTeam() != eTeam_Neutral )
	{
		
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		if (UnitState.HasSoldierAbility('SharpshooterAim'))
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('SharpshooterAim');
		}
		else if (UnitState.HasSoldierAbility('DeepCover') && XComGameState_Unit(ActionMetadata.StateObject_OldState).ActionPoints.Find(class'X2CharacterTemplateManager'.default.DeepCoverActionPoint) != INDEX_NONE)
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('DeepCover');
		}
		else
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
		}
		SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundUI.HunkerDownCue', AbilityTemplate.LocFlyOverText, 'HunkerDown', eColor_Good, AbilityTemplate.IconImage, 1.0, true);
	}
	//****************************************************************************************

	//	this visualization handles the removal of burning effects
	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		ApplyResult = Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]);
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, ApplyResult);
	}
}

static function X2AbilityTemplate AddMedikitHeal(name AbilityName, int HealAmount)
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityPassiveAOE_SelfRadius	PassiveAOEStyle;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2Effect_ApplyMedikitHeal         MedikitHeal;
	local X2Effect_RemoveEffectsByDamageType RemoveEffects;
	local array<name>                       SkipExclusions;
	local name                              HealType;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bReturnChargesError = true;
	Template.AbilityCosts.AddItem(AmmoCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityToHitCalc = default.DeadEye;

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	SingleTarget.bIncludeSelf = true;
	SingleTarget.bShowAOE = true;
	Template.AbilityTargetStyle = SingleTarget;

	PassiveAOEStyle = new class'X2AbilityPassiveAOE_SelfRadius';
	PassiveAOEStyle.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityPassiveAOEStyle = PassiveAOEStyle;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeFullHealth = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	MedikitHeal = new class'X2Effect_ApplyMedikitHeal';
	MedikitHeal.PerUseHP = HealAmount;
	Template.AddTargetEffect(MedikitHeal);

	RemoveEffects = new class'X2Effect_RemoveEffectsByDamageType';
	foreach default.MedikitHealEffectTypes(HealType)
	{
		RemoveEffects.DamageTypesToRemove.AddItem(HealType);
	}
	Template.AddTargetEffect(RemoveEffects);

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_medkit";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.MEDIKIT_HEAL_PRIORITY;
	Template.bUseAmmoAsChargesForHUD = true;
	Template.Hostility = eHostility_Defensive;
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;
	Template.ActivationSpeech = 'HealingAlly';

	Template.CustomSelfFireAnim = 'FF_FireMedkitSelf';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;
}

static function X2AbilityTemplate AddMedikitStabilize()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2Effect_RemoveEffects            RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MedikitStabilize');

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = default.MEDIKIT_STABILIZE_AMMO;
	AmmoCost.bReturnChargesError = true;
	Template.AbilityCosts.AddItem(AmmoCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityToHitCalc = default.DeadEye;

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	Template.AddShooterEffectExclusions();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.IsBleedingOut = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	Template.AddTargetEffect(RemoveEffects);
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateUnconsciousStatusEffect(, true));

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_stabilize";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STABILIZE_PRIORITY;
	Template.bUseAmmoAsChargesForHUD = true;
	Template.iAmmoAsChargesDivisor = default.MEDIKIT_STABILIZE_AMMO;
	Template.Hostility = eHostility_Defensive;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;

	Template.ActivationSpeech = 'StabilizingAlly';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;
}


static function X2DataTemplate AddEvacAbility()
{
	local X2AbilityTemplate             Template;
	local X2Condition_UnitProperty      UnitProperty;
	local X2Condition_UnitValue         UnitValue;
	local X2AbilityTrigger_PlayerInput  PlayerInput;
	local array<name>                   SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Evac');

	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); // Do not allow "Evac" in MP!

	Template.AbilityToHitCalc = default.DeadEye;

	SkipExclusions.AddItem(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeDead = true;
	UnitProperty.ExcludeFriendlyToSource = false;
	UnitProperty.ExcludeHostileToSource = true;
	//UnitProperty.IsOutdoors = true;           //  evac zone will take care of this now
	Template.AbilityShooterConditions.AddItem(UnitProperty);

	UnitValue = new class'X2Condition_UnitValue';
	UnitValue.AddCheckValue(default.EvacThisTurnName, default.MAX_EVAC_PER_TURN, eCheck_LessThan);
	Template.AbilityShooterConditions.AddItem(UnitValue);

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_UnitInEvacZone');

	Template.AbilityTargetStyle = default.SelfTarget;

	PlayerInput = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(PlayerInput);

	Template.AddAbilityEventListener('EvacActivated', class'XComGameState_Ability'.static.EvacActivated, ELD_OnStateSubmitted);

	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_evac";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.EVAC_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.HideErrors.AddItem('AA_AbilityUnavailable');
	Template.CinescriptCameraType = "Soldier_Evac";

	Template.bAllowedByDefault = false;

	Template.BuildNewGameStateFn = EvacAbility_BuildGameState;
	Template.BuildVisualizationFn = EvacAbility_BuildVisualization;

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

simulated function XComGameState EvacAbility_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit Source_OriginalState, Source_NewState;	
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;

	History = `XCOMHISTORY;
	//Build the new game state and context
	NewGameState = History.CreateNewGameState(true, Context);	
	AbilityContext = XComGameStateContext_Ability(Context);	
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = AbilityState.GetMyTemplate();	
	if (AbilityContext.InputContext.SourceObject.ObjectID != 0)
	{
		Source_OriginalState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		Source_NewState = XComGameState_Unit(NewGameState.ModifyStateObject(Source_OriginalState.Class, Source_OriginalState.ObjectID));

		//Trigger this ability here so that any the EvacActivated event is triggered before UnitRemovedFromPlay
		`XEVENTMGR.TriggerEvent('EvacActivated', AbilityState, Source_NewState, NewGameState); 

		AbilityTemplate.ApplyCost(AbilityContext, AbilityState, Source_NewState, none, NewGameState);		
		Source_NewState.EvacuateUnit(NewGameState);
	}

	//Return the game state we have created
	return NewGameState;
}

simulated function EvacAbility_BuildTutorialVisualization(XComGameState VisualizeGameState )
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local VisualizationActionMetadata            ActionMetadata;
	local X2Action_PlayNarrative        EvacBink;

	History = `XCOMHISTORY;

	// In replay, just play the end mission bink and nothing else
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID,, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID);

	EvacBink = X2Action_PlayNarrative(class'X2Action_PlayNarrative'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	EvacBink.bEndOfMissionNarrative = true;
	EvacBink.Moment = XComNarrativeMoment(DynamicLoadObject(TutorialEvacBink, class'XComNarrativeMoment'));

	}

simulated function EvacAbility_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory          History;
	local XComGameState_Unit            GameStateUnit;
	local VisualizationActionMetadata	EmptyTrack;
	local VisualizationActionMetadata	ActionMetadata;
	local X2Action_PlaySoundAndFlyOver  SoundAndFlyover;	
	local name                          nUnitTemplateName;
	local bool                          bIsVIP;
	local bool                          bNeedVIPVoiceover;
	local XComGameState_Unit            SoldierToPlayVoiceover;
	local array<XComGameState_Unit>     HumanPlayersUnits;
	local XComGameState_Effect          CarryEffect;



	if(`REPLAY.bInTutorial)
	{
		EvacAbility_BuildTutorialVisualization(VisualizeGameState );
	}
	else
	{
		History = `XCOMHISTORY;

		//Decide on which VO cue to play, and which unit says it
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', GameStateUnit)
		{
			if (!GameStateUnit.bRemovedFromPlay)
				continue;

			nUnitTemplateName = GameStateUnit.GetMyTemplateName();
			switch(nUnitTemplateName)
			{
			case 'Soldier_VIP':
			case 'Scientist_VIP':
			case 'Engineer_VIP':
			case 'FriendlyVIPCivilian':
			case 'HostileVIPCivilian':
			case 'CommanderVIP':
			case 'Engineer':
			case 'Scientist':
				bIsVIP = true;
				break;
			default:
				bIsVIP = false;
			}

			if (bIsVIP)
			{
				bNeedVIPVoiceover = true;
			}
			else
			{
				if (SoldierToPlayVoiceover == None)
					SoldierToPlayVoiceover = GameStateUnit;
			}
		}

		//Build tracks for each evacuating unit
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', GameStateUnit)
		{
			if (!GameStateUnit.bRemovedFromPlay)
				continue;

			//Start their track
			ActionMetadata = EmptyTrack;
			ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(GameStateUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
			ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(GameStateUnit.ObjectID);
			ActionMetadata.VisualizeActor = History.GetVisualizer(GameStateUnit.ObjectID);

			//Add this potential flyover (does this still exist in the game?)
			class'XComGameState_Unit'.static.SetUpBuildTrackForSoldierRelationship(ActionMetadata, VisualizeGameState, GameStateUnit.ObjectID);

			//Play the VO if this is the soldier we picked for it
			if (SoldierToPlayVoiceover == GameStateUnit)
			{
				SoundAndFlyOver = X2Action_PlaySoundAndFlyover(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
				if (bNeedVIPVoiceover)
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'VIPRescueComplete', eColor_Good);
					bNeedVIPVoiceover = false;
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'EVAC', eColor_Good);
				}
			}

			//Note: AFFECTED BY effect state (being carried)
			CarryEffect = XComGameState_Unit(ActionMetadata.StateObject_OldState).GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
			if (CarryEffect == None)
			{
				class'X2Action_Evac'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded); //Not being carried - rope out
			}				
			
			//Hide the pawn explicitly now - in case the vis block doesn't complete immediately to trigger an update
			class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		}

		//If a VIP evacuated alone, we may need to pick an (arbitrary) other soldier on the squad to say the VO line about it.
		if (bNeedVIPVoiceover)
		{
			XGBattle_SP(`BATTLE).GetHumanPlayer().GetUnits(HumanPlayersUnits);
			foreach HumanPlayersUnits(GameStateUnit)
			{
				if (GameStateUnit.IsSoldier() && !GameStateUnit.IsDead() && !GameStateUnit.bRemovedFromPlay)
				{
					ActionMetadata = EmptyTrack;
					ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(GameStateUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
					ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
					ActionMetadata.VisualizeActor = History.GetVisualizer(GameStateUnit.ObjectID);

					SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'VIPRescueComplete', eColor_Good);

										break;
				}
			}

		}
		
	}


	//****************************************************************************************
}

static function X2AbilityTemplate AddGrapple(Name TemplateName='Grapple')
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2AbilityCooldown             Cooldown;
	local X2Condition_UnitProperty      UnitProperty;
	local X2AbilityTarget_Cursor        CursorTarget;
	local X2AbilityTrigger_PlayerInput  InputTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.ARMOR_ACTIVE_PRIORITY;

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 3;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;

	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeDead = true;
	UnitProperty.ExcludeHostileToSource = true;
	UnitProperty.ExcludeFriendlyToSource = false;
	Template.AbilityShooterConditions.AddItem(UnitProperty);
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_HasGrappleLocation');

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.Hostility = eHostility_Movement;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_grapple";
	Template.TargetingMethod = class'X2TargetingMethod_Grapple';
	Template.CinescriptCameraType = "Soldier_Grapple";
	Template.bLimitTargetIcons = true;

	Template.AddShooterEffectExclusions();

	Template.BuildNewGameStateFn = Grapple_BuildGameState;
	Template.BuildVisualizationFn = Grapple_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate AddGrapplePowered()
{
	return AddGrapple('GrapplePowered'); // Jameson wants separate projectiles so he needs 2 perks
}

simulated native function BreakGrappleWindow(XComGameState NewGameState,
											 XComDestructibleActor Window, 
											 XComGameState_Unit BreakingUnit, 
											 const out TTile Destination, 
											 const out TTile OverhangTile);

simulated function XComGameState Grapple_BuildGameState( XComGameStateContext Context )
{
	local XComWorldData WorldData;
	local XComGameState NewGameState;
	local XComGameState_Unit MovingUnitState;
	local XComDestructibleActor WindowToBreak;
	local XComGameState_Ability AbilityState;	
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	
	local TTile UnitTile;
	local TTile PrevUnitTile;
	local TTile OverhangTile;
	local XComGameStateHistory History;
	local Vector TilePos, PrevTilePos, TilePosDiff;
	local UnitPeekSide PeekSide;

	WorldData = `XWORLD;
	History = `XCOMHISTORY;

	//Build the new game state frame, and unit state object for the moving unit
	NewGameState = History.CreateNewGameState(true, Context);	

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());	
	AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', AbilityContext.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = AbilityState.GetMyTemplate();

	// create a new state for the grapple unit
	MovingUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));

	// get our tile destination
	`assert(AbilityContext.InputContext.TargetLocations.Length == 1);
	TilePos = AbilityContext.InputContext.TargetLocations[0];
	UnitTile = WorldData.GetTileCoordinatesFromPosition(TilePos);

	// fetch the overhang tile we are grappling to. If we had to grapple through a window to get there,
	// break the window. We need to make this check before we change the unit's location
	if(WorldData.IsValidGrappleDestination(UnitTile, MovingUnitState, PeekSide, OverhangTile, WindowToBreak))
	{
		if(WindowToBreak != none)
		{
			BreakGrappleWindow(NewGameState, WindowToBreak, MovingUnitState, UnitTile, OverhangTile);
			MovingUnitState.BreakConcealmentNewGameState(NewGameState);
		}
	}

	//Set the unit's new location
	PrevUnitTile = MovingUnitState.TileLocation;
	MovingUnitState.SetVisibilityLocation( UnitTile );

	if (UnitTile != PrevUnitTile)
	{
		TilePos = `XWORLD.GetPositionFromTileCoordinates( UnitTile );
		PrevTilePos = `XWORLD.GetPositionFromTileCoordinates( PrevUnitTile );
		TilePosDiff = TilePos - PrevTilePos;
		TilePosDiff.Z = 0;

		MovingUnitState.MoveOrientation = Rotator( TilePosDiff );
	}
	
	//Apply the cost of the ability
	AbilityTemplate.ApplyCost(AbilityContext, AbilityState, MovingUnitState, none, NewGameState);

	`XEVENTMGR.TriggerEvent( 'ObjectMoved', MovingUnitState, MovingUnitState, NewGameState );
	`XEVENTMGR.TriggerEvent( 'UnitMoveFinished', MovingUnitState, MovingUnitState, NewGameState );

	//Return the game state we have created
	return NewGameState;	
}

simulated function Grapple_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local StateObjectReference MovingUnitRef;	
	local VisualizationActionMetadata ActionMetadata;
	local VisualizationActionMetadata EmptyTrack;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_EnvironmentDamage EnvironmentDamage;
	local X2Action_PlaySoundAndFlyOver CharSpeechAction;
	local X2Action_Grapple GrappleAction;
	local X2Action_ExitCover ExitCoverAction;
	local X2Action_RevealArea RevealAreaAction;
	local X2Action_UpdateFOW FOWUpdateAction;
	
	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	MovingUnitRef = AbilityContext.InputContext.SourceObject;
	
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(MovingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(MovingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(MovingUnitRef.ObjectID);

	CharSpeechAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	CharSpeechAction.SetSoundAndFlyOverParameters(None, "", 'GrapplingHook', eColor_Good);

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	RevealAreaAction.TargetLocation = AbilityContext.InputContext.TargetLocations[0];
	RevealAreaAction.AssociatedObjectID = MovingUnitRef.ObjectID;
	RevealAreaAction.ScanningRadius = class'XComWorldData'.const.WORLD_StepSize * 4;
	RevealAreaAction.bDestroyViewer = false;

	FOWUpdateAction = X2Action_UpdateFOW(class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	FOWUpdateAction.BeginUpdate = true;

	ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	ExitCoverAction.bUsePreviousGameState = true;

	GrappleAction = X2Action_Grapple(class'X2Action_Grapple'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	GrappleAction.DesiredLocation = AbilityContext.InputContext.TargetLocations[0];

	// destroy any windows we flew through
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
	{
		ActionMetadata = EmptyTrack;

		//Don't necessarily have a previous state, so just use the one we know about
		ActionMetadata.StateObject_OldState = EnvironmentDamage;
		ActionMetadata.StateObject_NewState = EnvironmentDamage;
		ActionMetadata.VisualizeActor = History.GetVisualizer(EnvironmentDamage.ObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext());
	}

	FOWUpdateAction = X2Action_UpdateFOW(class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	FOWUpdateAction.EndUpdate = true;

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	RevealAreaAction.AssociatedObjectID = MovingUnitRef.ObjectID;
	RevealAreaAction.bDestroyViewer = true;
}

static function X2AbilityTemplate WallBreaking()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    EventTrigger;
	local X2Effect_WallBreaking             WallBreakEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'WallBreaking');

	Template.bDontDisplayInAbilitySummary = true;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	EventTrigger = new class'X2AbilityTrigger_EventListener';
	EventTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventTrigger.ListenerData.EventID = 'PlayerTurnBegun';
	EventTrigger.ListenerData.Filter = eFilter_Player;
	EventTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(EventTrigger);

	WallBreakEffect = new class'X2Effect_WallBreaking';
	WallBreakEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	WallBreakEffect.AddTraversalChange(eTraversal_BreakWall, true);
	WallBreakEffect.EffectName = class'X2Effect_WallBreaking'.default.WallBreakingEffectName;
	Template.AddTargetEffect(WallBreakEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	return Template;
}

static function X2DataTemplate HotLoadAmmo()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_UnitPostBeginPlay PostBeginPlayTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HotLoadAmmo');

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;

	PostBeginPlayTrigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	PostBeginPlayTrigger.Priority -= 10;        // Lower priority to guarantee ammo modifying effects (e.g. Deep Pockets) already run.
	Template.AbilityTriggers.AddItem(PostBeginPlayTrigger);

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = HotLoadAmmo_BuildGameState;
	Template.BuildVisualizationFn = none;

	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	return Template;
}

simulated function XComGameState HotLoadAmmo_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Item AmmoState, WeaponState, NewWeaponState;
	local array<XComGameState_Item> UtilityItems;
	local X2AmmoTemplate AmmoTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local bool FoundAmmo;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);
	AbilityContext = XComGameStateContext_Ability(Context);
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
	WeaponState = AbilityState.GetSourceWeapon();
	NewWeaponState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', WeaponState.ObjectID));
	WeaponTemplate = X2WeaponTemplate(WeaponState.GetMyTemplate());

	// Start Issue #393
	// Reset weapon's ammo before further modificiations
	NewWeaponState.Ammo = NewWeaponState.GetClipSize();
	// End Issue #393

	// Start Issue #171
	UtilityItems = UnitState.GetAllInventoryItems(, true);
	foreach UtilityItems(AmmoState)
	{
		AmmoTemplate = X2AmmoTemplate(AmmoState.GetMyTemplate());
		// Ignore looted/droppbale ammos as well
		if (AmmoTemplate != none && AmmoTemplate.IsWeaponValidForAmmo(WeaponTemplate) && AmmoState.InventorySlot != eInvSlot_Backpack && AmmoState.InventorySlot != eInvSlot_Loot)
		{
	// End Issue #171
			FoundAmmo = true;
			break;
		}
	}
	if (FoundAmmo)
	{
		NewWeaponState.LoadedAmmo = AmmoState.GetReference();
		NewWeaponState.Ammo += AmmoState.GetClipSize();
	}

	return NewGameState;
}

static function X2DataTemplate AddKnockoutAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitProperty          Condition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2AbilityCost_ActionPoints        ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Knockout');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.Hostility = eHostility_Offensive;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_coupdegrace";
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateUnconsciousStatusEffect());

	Condition = new class'X2Condition_UnitProperty';
	Condition.ExcludeCivilian = false;
	Condition.ExcludeNonCivilian = true;
	Condition.RequireWithinRange = true;
	Condition.WithinRange = default.KNOCKOUT_RANGE;
	Template.AbilityTargetConditions.AddItem(Condition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState; // just adds the unconscious status effect
	Template.BuildVisualizationFn = Knockout_BuildVisualization;
	Template.BuildAffectedVisualizationSyncFn = Knockout_BuildAffectedVisualizationSync;
//BEGIN AUTOGENERATED CODE: Template Overrides 'Knockout'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'Knockout'

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

simulated function Knockout_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;
	local StateObjectReference			TargetUnitRef;
	local XComGameState_Ability         Ability;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;
	local VisualizationActionMetadata		 TargetActionMetadata;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int EffectIndex;
	local X2AbilityTemplate AbilityTemplate;
	local name EffectApplyResult, UnconsciousEffectApplyResult;
	local X2Effect_Persistent TestEffect;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;
	TargetUnitRef = Context.InputContext.PrimaryTarget;
	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
					
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Good);

	for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex )
	{
		AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.FindShooterEffectApplyResult(AbilityTemplate.AbilityShooterEffects[EffectIndex]));
	}

	//Configure the visualization track for the target
	//****************************************************************************************
	TargetActionMetadata = EmptyTrack;
	TargetActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(TargetUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	TargetActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(TargetUnitRef.ObjectID);
	TargetActionMetadata.VisualizeActor = History.GetVisualizer(TargetUnitRef.ObjectID);

	for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex )
	{
		EffectApplyResult = Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]);
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, TargetActionMetadata, EffectApplyResult);
		
		TestEffect = X2Effect_Persistent(AbilityTemplate.AbilityTargetEffects[EffectIndex]);
		if( (TestEffect != none) &&
			(TestEffect.EffectName == class'X2StatusEffects'.default.UnconsciousName) &&
			(UnconsciousEffectApplyResult != 'AA_Success') )
		{
			UnconsciousEffectApplyResult = EffectApplyResult;
		}
	}

	if( UnconsciousEffectApplyResult == 'AA_Success' )
	{
		class'X2Action_ExitCover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
		class'X2Action_Knockout'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
		class'X2Action_EnterCover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	}
}

simulated function Knockout_BuildAffectedVisualizationSync(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	if (EffectName == class'X2StatusEffects'.default.UnconsciousName)
	{
		class'X2Action_Knockout'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
	}
}

static function X2DataTemplate AddKnockoutSelfAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_Placeholder      InputTrigger;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local array<name> SkipExclusions;
	local X2Effect_RemoveEffectsByDamageType RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'KnockoutSelf');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 0;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	InputTrigger = new class'X2AbilityTrigger_Placeholder';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// disorient and burning shouldn't prevent a unit from being knocked out (this is triggered systemically)
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2Ability_Viper'.default.BindSustainedEffectName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.BoundName);
	Template.AddShooterEffectExclusions( SkipExclusions );

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Defensive;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_coupdegrace";

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateUnconsciousStatusEffect());

	RemoveEffects = new class'X2Effect_RemoveEffectsByDamageType';
	RemoveEffects.DamageTypesToRemove.AddItem('stun');
	RemoveEffects.DamageTypesToRemove.AddItem('fire');
	RemoveEffects.DamageTypesToRemove.AddItem('poison');
	RemoveEffects.DamageTypesToRemove.AddItem(class'X2Effect_ParthenogenicPoison'.default.ParthenogenicPoisonType);
	RemoveEffects.DamageTypesToRemove.AddItem('acid');

	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.ConfusedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_MindControl'.default.EffectName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Ability_Viper'.default.BindSustainedEffectName);
	Template.AddTargetEffect( RemoveEffects );

	Template.bAllowedByDefault = false;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState; // just adds the unconscious status effect
	Template.BuildVisualizationFn = Knockout_BuildVisualization;

	Template.PostActivationEvents.AddItem('KnockSelfoutUnconscious');

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

static function X2AbilityTemplate AddPanicAbility(Name AbilityName, optional X2Effect_Panicked PanickedEffect)
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitProperty          Condition;
	local X2AbilityCost_ActionPoints        ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.CinescriptCameraType = "Panic";
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	Template.AbilityToHitCalc = class'X2Ability'.default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	Template.AddShooterEffectExclusions();
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_Panic');
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	if(PanickedEffect != none)
	{
		Template.AddShooterEffect(PanickedEffect);
	}
	else
	{
		Template.AddShooterEffect(class'X2StatusEffects'.static.CreatePanickedStatusEffect());
	}

	Condition = new class'X2Condition_UnitProperty';
	Condition.ExcludeRobotic = true;
	Condition.ExcludeImpaired = true;
	Condition.ExcludePanicked = true;
	Template.AbilityShooterConditions.AddItem(Condition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

static function X2AbilityTemplate AddBerserkAbility()
{
	local X2AbilityTemplate                 Template;

	Template = AddPanicAbility('Berserk', class'X2StatusEffects'.static.CreateBerserkStatusEffect());

	return Template;
}

static function X2AbilityTemplate AddObsessedAbility()
{
	local X2AbilityTemplate                 Template;

	Template = AddPanicAbility('Obsessed', class'X2StatusEffects'.static.CreateObsessedStatusEffect());

	return Template;
}

static function X2AbilityTemplate AddShatteredAbility()
{
	local X2AbilityTemplate                 Template;

	Template = AddPanicAbility('Shattered', class'X2StatusEffects'.static.CreateShatteredStatusEffect());

	return Template;
}

static function X2AbilityTemplate TacticalRigging()
{
	local X2AbilityTemplate         Template;

	Template = PurePassive('TacticalRigging', , , 'eAbilitySource_Perk', false);
	Template.SoldierAbilityPurchasedFn = TacticalRiggingPurchased;
//BEGIN AUTOGENERATED CODE: Template Overrides 'TacticalRigging'
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_tacticalrigging";
//END AUTOGENERATED CODE: Template Overrides 'TacticalRigging'

	return Template;
}

function TacticalRiggingPurchased(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	// Start Isse #171
	UnitState.RealizeItemSlotsCount(NewGameState);
	// End Isse #171
}

// Added DisableConsumeAllPoints ability to be kicked off for Panicking units.
static function X2DataTemplate AddDisableConsumeAllPointsAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitEffects			AlreadyAppliedEffectCondition;
	local X2AbilityTrigger_Placeholder		UseTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DisableConsumeAllPoints');

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	//System triggered.  Activated directly by the behavior tree for the Panic Berserk Condition.
	UseTrigger = new class'X2AbilityTrigger_Placeholder';
	Template.AbilityTriggers.AddItem(UseTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	AlreadyAppliedEffectCondition = new class'X2Condition_UnitEffects';
	AlreadyAppliedEffectCondition.AddExcludeEffect('DoNotConsumeAllPoints', 'AA_DuplicateEffectIgnored');
	Template.AbilityShooterConditions.AddItem(AlreadyAppliedEffectCondition);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateDoNotConsumeStatusEffect());

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState; // just adds the DoNotConsume status effect.
	Template.BuildVisualizationFn = None;

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

static function X2AbilityTemplate CreateMarkSupplyCrateAbility()
{
	local X2AbilityTemplate Template;
	local X2Condition ShooterCondition;

	Template = class'X2Ability_DefaultAbilitySet'.static.AddInteractAbility('Interact_MarkSupplyCrate');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	// No cost, allows it to be used anytime, even at end of turn if available
	Template.AbilityCosts.Length = 0;

	// You can mark supply crates even if you are carrying somebody
	foreach Template.AbilityShooterConditions(ShooterCondition)
	{
		if(X2Condition_UnitEffects(ShooterCondition) != none)
		{
			X2Condition_UnitEffects(ShooterCondition).RemoveExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
		}
	}

	return Template;
}

static function X2AbilityTemplate CreateActivateAscensionGateAbility()
{
	local X2AbilityTemplate Template;
	local X2Condition ShooterCondition;

	Template = class'X2Ability_DefaultAbilitySet'.static.AddInteractAbility('Interact_ActivateAscensionGate');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	// No cost, allows it to be used anytime, even at end of turn if available
	Template.AbilityCosts.Length = 0;

	// You can activate the chamber even if carrying a unit
	foreach Template.AbilityShooterConditions(ShooterCondition)
	{
		if(X2Condition_UnitEffects(ShooterCondition) != none)
		{
			X2Condition_UnitEffects(ShooterCondition).RemoveExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
		}
	}

	return Template;
}

static function X2AbilityTemplate AddRevive()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitProperty			TargetCondition;
	local X2Condition_UnitEffects           EffectsCondition;
	local X2Effect_RemoveEffects            RemoveEffects;
	local X2Effect_Persistent               DisorientedEffect;
	local array<name>                       SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Revive');

	Template.AbilitySourceName = 'eAbilitySource_Commander';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_chosenrevive";
	Template.DisplayTargetHitChance = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.MUST_RELOAD_PRIORITY;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Condition
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Target Condition
	Template.AbilityTargetConditions.AddItem(default.LivingTargetOnlyProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = false;
	TargetCondition.ExcludeHostileToSource = true;
	TargetCondition.FailOnNonUnits = true;
	TargetCondition.RequireWithinRange = true;
	TargetCondition.WithinRange = default.REVIVE_RANGE_UNITS;
	Template.AbilityTargetConditions.AddItem(TargetCondition);

	// Cannot target units being carried.
	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddRequireEffect(class'X2AbilityTemplateManager'.default.DazedName, 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(EffectsCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DazedName);
	Template.AddTargetEffect(RemoveEffects);

	DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect(, , false);
	DisorientedEffect.bRemoveWhenSourceDies = false;
	DisorientedEffect.ApplyChance = default.REVIVE_DISORIENT_PERCENT_CHANCE;
	Template.AddTargetEffect(DisorientedEffect);

	Template.ActivationSpeech = 'HealingAlly';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bShowPostActivation = true;
//BEGIN AUTOGENERATED CODE: Template Overrides 'Revive'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.CustomFireAnim = 'HL_Revive';
//END AUTOGENERATED CODE: Template Overrides 'Revive'

	return Template;
}

// Challenge mode ability
static function X2AbilityTemplate AddChallengeHackAbility(name TemplateName, name BaseHack_TemplateName, bool bMustBeDoor)
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Condition_HackingTarget         HackCondition;
	local X2AbilityToHitCalc_Hacking		ToHitHack;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.HACK_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_V;
	Template.bUniqueSource = true;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	ToHitHack = new class'X2AbilityToHitCalc_Hacking';
	ToHitHack.bAlwaysSucceed = true;
	Template.AbilityToHitCalc = ToHitHack;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	HackCondition = new class'X2Condition_HackingTarget';
	HackCondition.RequiredAbilityName = BaseHack_TemplateName;
	HackCondition.bMustBeDoor = bMustBeDoor;
	Template.AbilityTargetConditions.AddItem(HackCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = FinalizeHackAbility_BuildGameState;
	Template.BuildVisualizationFn = FinalizeHackAbility_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

defaultproperties
{
	DefaultAbilitySet(0)="StandardMove"
	DefaultAbilitySet(1)="Interact"	
	DefaultAbilitySet(2)="Interact_OpenDoor"
	DefaultAbilitySet(3)="Interact_OpenChest"

	EvacThisTurnName="EvacThisTurn"
	ImmobilizedValueName="Immobilized"
	ConcealedOverwatchTurn="ConcealedOverwatch"
}
