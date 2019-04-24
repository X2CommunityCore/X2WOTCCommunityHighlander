//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_TacticalGameRule.uc
//  AUTHOR:  Ryan McFall  --  11/21/2013
//  PURPOSE: XComGameStateContexts for game rule state changes in the tactical game. Examples
//           of this sort of state change are: Units added, changes in turn phase, etc.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_TacticalGameRule extends XComGameStateContext native(Core);

enum GameRuleStateChange
{
	eGameRule_TacticalGameStart,
	eGameRule_RulesEngineStateChange,   //Called when the turn changes over to a new phase. See X2TacticalGameRuleset and its states.
	eGameRule_UnitAdded,
	eGameRule_UnitChangedTeams,
	eGameRule_ReplaySync,               //This informs the system sync all visualizers to an arbitrary state
	eGameRule_SkipTurn,
	eGameRule_SkipUnit,
	eGameRule_PlayerTurnBegin,
	eGameRule_PlayerTurnEnd,
	eGameRule_TacticalGameEnd,
	eGameRule_DemoStart,
	eGameRule_ClaimCover,
	eGameRule_UpdateAIPlayerData,
	eGameRule_UpdateAIRemoveAlertTile,
	eGameRule_UnitGroupTurnBegin,
	eGameRule_UnitGroupTurnEnd,
	eGameRule_UNUSED_3,
	eGameRule_MarkCorpseSeen,
	eGameRule_UseActionPoint,
	eGameRule_AIRevealWait,				// On AI patrol unit's move, Patroller is alerted to an XCom unit.   Waits for other group members to catch up before reveal.
	eGameRule_SyncTileLocationToCorpse, // Special handling for XCOM units. The only case where a visualizer sequence can push data to the game state
	eGameRule_UNUSED_5,
	eGameRule_ForceSyncVisualizers,
};

var GameRuleStateChange     GameRuleType;
var StateObjectReference    PlayerRef;      //Player associated with this game rule state change, if any
var StateObjectReference    UnitRef;		//Unit associated with this game rule state change, if any
var StateObjectReference    AIRef;			//AI associated with this game rule state chance, if any
var name RuleEngineNextState;               //The name of the new state that the rules engine is entering. Can be used for error checking or actually implementing GotoState
var bool bSkipVisualization;				// if true, the context still needs to build for event processing, but the special viaulization associated with this state change should be skipped

											
//XComGameStateContext interface
//***************************************************
/// <summary>
/// Should return true if ContextBuildGameState can return a game state, false if not. Used internally and externally to determine whether a given context is
/// valid or not.
/// </summary>
function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

/// <summary>
/// Override in concrete classes to converts the InputContext into an XComGameState
/// </summary>
function XComGameState ContextBuildGameState()
{
	local XComGameState_Unit UnitState;
	local XComGameState_Unit UpdatedUnitState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_AIPlayerData AIState, UpdatedAIState;
	local XComGameState_AIUnitData AIUnitState;
	local bool bHadActionPoints;
	local int iComponentID;
	//local bool bClaimCoverAnyChanges;		//True if the claim cover game state contains meaningful changes
	local XComGameState_Player CurrentPlayer;
	local XComGameState_BattleData BattleData;
	local XComGameState_AIGroup GroupState;
	local XGUnit UnitVisualizer;
	local Vector TestLocation;
	local TTile FloorTile;

	History = `XCOMHISTORY;
	NewGameState = none;
	switch(GameRuleType)
	{
	case eGameRule_SkipTurn : 
		`assert(PlayerRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);
		//Clear all action points for this player's units
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.ControllingPlayer.ObjectID == PlayerRef.ObjectID )
			{					
				UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				UpdatedUnitState.SkippedActionPoints = UpdatedUnitState.ActionPoints;
				UpdatedUnitState.ActionPoints.Length = 0;
			}
		}
		break;
	case eGameRule_SkipUnit : 
		`assert(UnitRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);		
		UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		bHadActionPoints = UpdatedUnitState.ActionPoints.Length > 0;
		UpdatedUnitState.ActionPoints.Length = 0;//Clear all action points for this unit
		if( bHadActionPoints )
		{
			`XEVENTMGR.TriggerEvent('ExhaustedActionPoints', UpdatedUnitState, UpdatedUnitState, NewGameState);
		}
		else
		{
			`XEVENTMGR.TriggerEvent('NoActionPointsAvailable', UpdatedUnitState, UpdatedUnitState, NewGameState);
		}

		foreach UpdatedUnitState.ComponentObjectIds(iComponentID)
		{
			if (History.GetGameStateForObjectID(iComponentID).IsA('XComGameState_Unit'))
			{
				UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', iComponentID));
				if (UpdatedUnitState != None)
				{
					UpdatedUnitState.ActionPoints.Length = 0;//Clear all action points for this unit
				}
			}
		}
		break;
	case eGameRule_UseActionPoint:
		`assert(UnitRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);		
		UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		if (UpdatedUnitState.ActionPoints.Length > 0)
			UpdatedUnitState.ActionPoints.Remove(0, 1);
		break;

	case eGameRule_ClaimCover:
		//  jbouscher: new reflex system does not want to do this
		//NewGameState = History.CreateNewGameState(true, self);		
		//
		//UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));		
		//		
		//if( UpdatedUnitState.GetTeam() == eTeam_XCom )
		//{
		//	//This game state rule is used as an end cap for movement, so it is here that we manipulate the
		//	//reflex triggering state for AI units. Red-alert units need to have their reflex trigger flag cleared
		//	//but this needs to happen after any X-Com moves are complete
		//	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		//	{
		//		if( UnitState.GetCurrentStat(eStat_AlertLevel) > 1 && UnitState.bTriggersReflex )
		//		{				
		//			bClaimCoverAnyChanges = true;
		//			UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		//			UpdatedUnitState.bTriggersReflex = false;
		//		}
		//	}
		//}
		//
		//if( !bClaimCoverAnyChanges )
		//{
		//	History.CleanupPendingGameState(NewGameState);
		//	NewGameState = none;
		//}
		break;
	case eGameRule_UpdateAIPlayerData:
		`assert(PlayerRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);
		foreach History.IterateByClassType(class'XComGameState_AIPlayerData', AIState)
		{
			//if ( AIState.m_iPlayerObjectID == PlayerRef.ObjectID )
			if(AIState.m_iPlayerObjectID > 0) //issue #226 - just grab the first available AIState
			{
				UpdatedAIState = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', AIState.ObjectID));
				UpdatedAIState.UpdateData(PlayerRef.ObjectID);
				break;
			}
		}
	break;
	case eGameRule_UpdateAIRemoveAlertTile:
		// deprecated game rule
		`RedScreen("Called deprecated game rule:eGameRule_UpdateAIRemoveAlertTile. This should not happen.");
		//`assert(AIRef.ObjectID > 0);
		//NewGameState = History.CreateNewGameState(true, self);
		//AIUnitState = XComGameState_AIUnitData(NewGameState.ModifyStateObject(class'XComGameState_AIUnitData', AIRef.ObjectID));
		//if (AIUnitState.m_arrAlertTiles.Length > 0)
		//	AIUnitState.m_arrAlertTiles.Remove(0,1);
		break;
	case eGameRule_PlayerTurnBegin:
		NewGameState = History.CreateNewGameState(true, self);

		// Update this player's turn counter
		CurrentPlayer = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', PlayerRef.ObjectID));
		CurrentPlayer.PlayerTurnCount += 1;

		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', false));
		BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
		BattleData.UnitActionPlayerRef = CurrentPlayer.GetReference();
		BattleData.UnitActionInitiativeRef = BattleData.UnitActionPlayerRef;

		break;
	case eGameRule_PlayerTurnEnd:
		// simple placeholder states
		NewGameState = History.CreateNewGameState(true, self);
		CurrentPlayer = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', PlayerRef.ObjectID));
		CurrentPlayer.ChosenActivationsThisTurn = 0;
		CurrentPlayer.ActionsTakenThisTurn = 0;
		break;

	case eGameRule_UnitGroupTurnBegin:
		NewGameState = History.CreateNewGameState(true, self);
		break;
	case eGameRule_UnitGroupTurnEnd:
		// simple placeholder states
		NewGameState = History.CreateNewGameState(true, self);
		GroupState = XComGameState_AIGroup(History.GetGameStateForObjectID(UnitRef.ObjectID)); // Unit ref is actually the group ref here
		if( GroupState != None && GroupState.m_arrMembers.Length > 0 )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(GroupState.m_arrMembers[0].ObjectID));
			if( UnitState != None && UnitState.IsChosen() )
			{
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				UnitState.ActivationLevel = 0;
			}
		}
		break;

	case eGameRule_UnitAdded:
		// simple placeholder states
		NewGameState = History.CreateNewGameState(true, self);
		break;

	case eGameRule_TacticalGameEnd:
		NewGameState = BuildTacticalGameEndGameState();
		break;

	case eGameRule_UnitChangedTeams:
		NewGameState = BuildUnitChangedTeamGameState();
		break;

	case eGameRule_MarkCorpseSeen:
		`assert( AIRef.ObjectID > 0 && UnitRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);
		AIUnitState = XComGameState_AIUnitData(NewGameState.ModifyStateObject(class'XComGameState_AIUnitData', AIRef.ObjectID));
		AIUnitState.MarkCorpseSeen(UnitRef.ObjectID);
		break;

	case eGameRule_AIRevealWait:
		`assert(AIRef.ObjectID > 0 && UnitRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);		
		UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		UpdatedUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);//Add action point for this unit
		break;

	case eGameRule_DemoStart:
		// simple placeholder states
		NewGameState = History.CreateNewGameState(true, self);
		break;

	case eGameRule_ForceSyncVisualizers:
		NewGameState = History.CreateNewGameState(true, self);
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		}
		break;
	case eGameRule_SyncTileLocationToCorpse:
		NewGameState = History.CreateNewGameState(true, self);
		UnitVisualizer = XGUnit(History.GetVisualizer(UnitRef.ObjectID));
		if (UnitVisualizer != none)
		{
			TestLocation = UnitVisualizer.Location + vect(0, 0, 64);
			if (`XWORLD.GetFloorTileForPosition(TestLocation, FloorTile))
			{
				UpdatedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
				UpdatedUnitState.SetVisibilityLocation(FloorTile);
			}
		}
		break;
	}

	return NewGameState;
}

function XComGameState BuildTacticalGameEndGameState()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit IterateUnitState;
	local XComGameState_Unit NewUnitState;
	local XComGameState_Player VictoriousPlayer;
	local XComGameState_BattleData BattleData, NewBattleData;
	local StateObjectReference LocalPlayerRef;

	History = `XCOMHISTORY;

	NewGameState = History.CreateNewGameState(true, self);

	VictoriousPlayer = XComGameState_Player(History.GetGameStateForObjectID(PlayerRef.ObjectID));
	if (VictoriousPlayer == none)
	{
		`RedScreen("Battle ended without a winner. This should not happen.");
	}

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleData != none);

	LocalPlayerRef = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ControllingPlayer;
	NewBattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(BattleData.Class, BattleData.ObjectID));
	NewBattleData.SetVictoriousPlayer(VictoriousPlayer, VictoriousPlayer.ObjectID == LocalPlayerRef.ObjectID);
	NewBattleData.AwardTacticalGameEndBonuses(NewGameState);

	// Skip all turns 
	foreach History.IterateByClassType(class'XComGameState_Unit', IterateUnitState)
	{
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', IterateUnitState.ObjectID));
        NewUnitState.ActionPoints.Length = 0;
	}

	// notify of end game state
	`XEVENTMGR.TriggerEvent('TacticalGameEnd');

	return NewGameState;
}

function XComGameState BuildUnitChangedTeamGameState()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

	NewGameState = History.CreateNewGameState(true, self);
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
	UnitState.SetControllingPlayer(PlayerRef);
	UnitState.OnSwappedTeams(PlayerRef);

	// Give the switched unit action points so they are ready to go
	UnitState.GiveStandardActionPoints();

	return NewGameState;
}

/// <summary>
/// Convert the ResultContext and AssociatedState into a set of visualization tracks
/// </summary>
protected function ContextBuildVisualization()
{	
	local XComGameState_BattleData BattleState;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;

	if( bSkipVisualization )
	{
		return;
	}

	History = `XCOMHISTORY;

	//Process Units
	switch(GameRuleType)
	{			
	case eGameRule_TacticalGameStart :
		SyncAllVisualizers();

		BattleState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		
		//Use the battle state object for the following actions:
		ActionMetadata.StateObject_OldState = BattleState;
		ActionMetadata.StateObject_NewState = BattleState;
		ActionMetadata.VisualizeActor = none;

		class'X2Action_SyncMapVisualizers'.static.AddToVisualizationTree(ActionMetadata, self);
		class'X2Action_InitCamera'.static.AddToVisualizationTree(ActionMetadata, self);		
		class'X2Action_InitFOW'.static.AddToVisualizationTree(ActionMetadata, self);		
		class'X2Action_InitUI'.static.AddToVisualizationTree(ActionMetadata, self);
		class'X2Action_StartMissionSoundtrack'.static.AddToVisualizationTree(ActionMetadata, self);				

		// only run the mission intro in single player.
		//	we'll probably want an MP mission intro at some point...
		if( `XENGINE.IsSinglePlayerGame() && !class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode( ) )
		{
			//Only add the intro track(s) if this start state is current ( ie. we are not visualizing a saved game load )
			if( AssociatedState == History.GetStartState() && 
				BattleState.MapData.PlotMapName != "" &&
				`XWORLDINFO.IsPlayInEditor() != true &&
				BattleState.bIntendedForReloadLevel == false)
			{	
				class'X2Action_HideLoadingScreen'.static.AddToVisualizationTree(ActionMetadata, self);

				if(`TACTICALMISSIONMGR.GetActiveMissionIntroDefinition().MatineePackage != "")
				{
					class'X2Action_DropshipIntro'.static.AddToVisualizationTree(ActionMetadata, self);
					class'X2Action_UnstreamDropshipIntro'.static.AddToVisualizationTree(ActionMetadata, self);
				}
				else
				{
					// if there is no dropship intro, we need to manually clear the camera fade
					class'X2Action_ClearCameraFade'.static.AddToVisualizationTree(ActionMetadata, self);
				}
			}
		}
		else
		{			
			class'X2Action_HideLoadingScreen'.static.AddToVisualizationTree(ActionMetadata, self);
			class'X2Action_ClearCameraFade'.static.AddToVisualizationTree(ActionMetadata, self);
		}

		

		break;
	case eGameRule_ReplaySync:		
		SyncAllVisualizers();
		break;
	case eGameRule_UnitAdded:
		BuildUnitAddedVisualization();
		break;
	case eGameRule_UnitChangedTeams:
		BuildUnitChangedTeamVisualization();
		break;

	case eGameRule_PlayerTurnEnd:
		BuildPlayerTurnEndVisualization();
		break;
	case eGameRule_PlayerTurnBegin:
		BuildPlayerTurnBeginVisualization();
		break;
	case eGameRule_UnitGroupTurnEnd:
		BuildGroupTurnEndVisualization();
		break;
	case eGameRule_UnitGroupTurnBegin:
		BuildGroupTurnBeginVisualization();
		break;

	case eGameRule_ForceSyncVisualizers:
		SyncAllVisualizers();
		break;
	}
}

private function BuildPlayerTurnEndVisualization()
{
	local X2Action_UpdateUI UIUpdateAction;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local XComGameState_Player TurnEndingPlayer;

	History = `XCOMHISTORY;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(PlayerRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
	ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
	ActionMetadata.VisualizeActor = History.GetVisualizer(PlayerRef.ObjectID);

	// Try to do a soldier reaction, and if nothing to react to, check if there is any hidden movement
	if(!class'X2Action_EndOfTurnSoldierReaction'.static.AddReactionToBlock(self))
	{
		TurnEndingPlayer = XComGameState_Player(History.GetGameStateForObjectID(PlayerRef.ObjectID));
		if(TurnEndingPlayer != none 
			&& TurnEndingPlayer.GetTeam() == eTeam_XCom
			&& TurnEndingPlayer.TurnsSinceEnemySeen >= class'X2Action_HiddenMovement'.default.TurnsUntilIndicator)
		{
			class'X2Action_HiddenMovement'.static.AddHiddenMovementActionToBlock(AssociatedState);
		}
	}

	// only perform the start of turn signal if there is no engaged chosen calling out directions
	if( class'XComGameState_Unit'.static.GetEngagedChosen() == None )
	{
		class'X2Action_BeginTurnSignals'.static.AddBeginTurnSignalsToBlock(self);
	}

	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, self));
	UIUpdateAction.SpecificID = PlayerRef.ObjectID;
	UIUpdateAction.UpdateType = EUIUT_EndTurn;
}

private function BuildPlayerTurnBeginVisualization()
{
	local X2Action_UpdateUI UIUpdateAction;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;

	local XComGameState_Unit IterateUnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_WaitForAbilityEffect WaitAction;
	local XComGameState_Player TurnStartingPlayer;
	local float Radius;
	local float WaitDuration;


	History = `XCOMHISTORY;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(PlayerRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
	ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
	ActionMetadata.VisualizeActor = History.GetVisualizer(PlayerRef.ObjectID);

	if( class'XComGameState_Unit'.static.GetEngagedChosen() == None && XGUnit(class'XComGameState_Unit'.static.GetEngagedChosen().GetVisualizer()).IsVisible() )
	{
		class'X2Action_BeginTurnSignals'.static.AddBeginTurnSignalsToBlock(self);
	}

	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, self));
	UIUpdateAction.SpecificID = PlayerRef.ObjectID;
	UIUpdateAction.UpdateType = EUIUT_BeginTurn;


	// For each unit on the current player's team, test if that unit is next to a tile
	// that is on fire, and if so, show a flyover for that unit.  mdomowicz 2015_07_20
	TurnStartingPlayer = XComGameState_Player(History.GetGameStateForObjectID(PlayerRef.ObjectID));
	if ( TurnStartingPlayer != none && TurnStartingPlayer.GetTeam() == eTeam_XCom )
	{
		WaitDuration = 0.1f;

		foreach History.IterateByClassType(class'XComGameState_Unit', IterateUnitState)
		{
			if (IterateUnitState.IsImmuneToDamage('Fire') || IterateUnitState.bRemovedFromPlay)
				continue;

			if ( IterateUnitState.GetTeam() == eTeam_XCom )
			{
				Radius = 2.0;
				if ( IsFireInRadiusOfUnit( Radius, XGUnit(IterateUnitState.GetVisualizer())) )
				{
					// Setup a new track for the unit
					ActionMetadata = EmptyTrack;
					ActionMetadata.StateObject_OldState = IterateUnitState;
					ActionMetadata.StateObject_NewState = IterateUnitState;
					ActionMetadata.VisualizeActor = IterateUnitState.GetVisualizer();

					// Add a wait action to the Metadata.
					WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, self));
					WaitAction.ChangeTimeoutLength(WaitDuration);
					WaitDuration += 2.0f;

					// Then add a flyover to the Metadata.
					SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, self));
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'ObjectFireSpreading', eColor_Bad, "", 1.0f, true, eTeam_None);


					// Then submit the Metadata.
					
				}
			}
		}
	}
}

private function BuildGroupTurnEndVisualization()
{
	local X2Action_UpdateUI UIUpdateAction;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(PlayerRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
	ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
	ActionMetadata.VisualizeActor = History.GetVisualizer(PlayerRef.ObjectID);

	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, self));
	UIUpdateAction.SpecificID = PlayerRef.ObjectID;
	UIUpdateAction.UpdateType = EUIUT_EndTurn;
}

private function BuildGroupTurnBeginVisualization()
{
	local X2Action_UpdateUI UIUpdateAction;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(PlayerRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
	ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
	ActionMetadata.VisualizeActor = History.GetVisualizer(PlayerRef.ObjectID);

	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, self));
	UIUpdateAction.SpecificID = PlayerRef.ObjectID;
	UIUpdateAction.UpdateType = EUIUT_BeginTurn;
}

// This function is based off the implementation of TeamInRadiusOfUnit() in 
// XComWorlData.uc   mdomowicz 2015_07_20
function bool IsFireInRadiusOfUnit( int tile_radius, XGUnit Unit)
{
	local XComWorldData WorldData;
	local array<TilePosPair> OutTiles;
	local float Radius;
	local vector Location;
	local TilePosPair TilePair;
	local TTile TileLocation;

	WorldData = `XWORLD;

	Radius = tile_radius * WorldData.WORLD_StepSize;

	Location = Unit.Location;
	Location.Z += tile_radius * WorldData.WORLD_FloorHeight;

	TileLocation = WorldData.GetTileCoordinatesFromPosition( Unit.Location );

	WorldData.CollectFloorTilesBelowDisc( OutTiles, Location, Radius );

	foreach OutTiles( TilePair )
	{
		if (abs( TilePair.Tile.Z - TileLocation.Z ) > tile_radius)
		{
			continue;
		}

		if ( WorldData.TileContainsFire( TilePair.Tile ) )
		{
			return true;
		}
	}

	return false;
}

private function BuildUnitAddedVisualization()
{
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	
	History = `XCOMHISTORY;

	if( UnitRef.ObjectID != 0 )
	{
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
		ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
		ActionMetadata.VisualizeActor = History.GetVisualizer(UnitRef.ObjectID);
		class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(ActionMetadata, self);
		
	}
	else
	{
		`Redscreen("Added unit but no unit state specified! Talk to David B.");
	}
}

private function BuildUnitChangedTeamVisualization()
{
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	
	History = `XCOMHISTORY;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
	class'X2Action_SwapTeams'.static.AddToVisualizationTree(ActionMetadata, self);

	
}

private function SyncAllVisualizers()
{
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameState_BaseObject VisualizedObject;
	local XComGameStateHistory History;
	local XComGameState_AIPlayerData AIPlayerDataState;
	local XGAIPlayer kAIPlayer;
	local X2Action_SyncMapVisualizers MapVisualizer;
	local XComGameState_BattleData BattleState;

	History = `XCOMHISTORY;

	// Sync the map first so that the tile data is in the proper state for all the individual SyncVisualizer calls
	BattleState = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = BattleState;
	ActionMetadata.StateObject_NewState = BattleState;
	MapVisualizer = X2Action_SyncMapVisualizers( class'X2Action_SyncMapVisualizers'.static.AddToVisualizationTree( ActionMetadata, self ) );
	
	MapVisualizer.Syncing = true;

	// Jwats: First create all the visualizers so the sync actions have access to them for metadata
	foreach AssociatedState.IterateByClassType(class'XComGameState_BaseObject', VisualizedObject)
	{
		if( X2VisualizedInterface(VisualizedObject) != none )
		{
			X2VisualizedInterface(VisualizedObject).FindOrCreateVisualizer();
		}
	}

	foreach AssociatedState.IterateByClassType(class'XComGameState_BaseObject', VisualizedObject)
	{
		if(X2VisualizedInterface(VisualizedObject) != none)
		{
			ActionMetadata = EmptyTrack;
			ActionMetadata.StateObject_OldState = VisualizedObject;
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
			ActionMetadata.VisualizeActor = History.GetVisualizer(ActionMetadata.StateObject_NewState.ObjectID);
			class'X2Action_SyncVisualizer'.static.AddToVisualizationTree(ActionMetadata, self).ForceImmediateTimeout();
		}
	}

	// Jwats: Once all the visualizers are in their default state allow the additional sync actions run to manipulate them
	foreach AssociatedState.IterateByClassType(class'XComGameState_BaseObject', VisualizedObject)
	{
		if( X2VisualizedInterface(VisualizedObject) != none )
		{
			ActionMetadata = EmptyTrack;
			ActionMetadata.StateObject_OldState = VisualizedObject;
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
			ActionMetadata.VisualizeActor = History.GetVisualizer(ActionMetadata.StateObject_NewState.ObjectID);
			X2VisualizedInterface(VisualizedObject).AppendAdditionalSyncActions(ActionMetadata, self);
		}
	}

	kAIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if (kAIPlayer.m_iDataID == 0)
	{
		foreach AssociatedState.IterateByClassType(class'XComGameState_AIPlayerData', AIPlayerDataState)
		{
			kAIPlayer.m_iDataID = AIPlayerDataState.ObjectID;
			break;
		}
	}
}

/// <summary>
/// Override to return TRUE for the XComGameStateContexts to show that the associated state is a start state
/// </summary>
event bool IsStartState()
{
	return GameRuleType == eGameRule_TacticalGameStart;
}

native function bool NativeIsStartState();


/// <summary>
/// Returns a short description of this context object
/// </summary>
function string SummaryString()
{
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local XComGameState_Unit UnitState;
	local XComGameState_AIUnitData AIState;
	local string GameRuleString;

	History = `XCOMHISTORY;

	GameRuleString = string(GameRuleType);
	if( RuleEngineNextState != '' )
	{
		GameRuleString = string(RuleEngineNextState);
	}

	if( PlayerRef.ObjectID > 0 )
	{
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(PlayerRef.ObjectID));
		GameRuleString @= "'"$PlayerState.GetGameStatePlayerName()$"' ("$PlayerRef.ObjectID$")";
	}

	if( UnitRef.ObjectID > 0 )
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if(UnitState != none)
		{
			GameRuleString @= "'"$UnitState.GetFullName()$"' ("$UnitRef.ObjectID$")";
		}
	}

	if( AIRef.ObjectID > 0 )
	{
		AIState = XComGameState_AIUnitData(History.GetGameStateForObjectID(AIRef.ObjectID));
		if( AIState.m_iUnitObjectID > 0 )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIState.m_iUnitObjectID));
			GameRuleString @= "'"$UnitState.GetFullName()$"'["$UnitState.ObjectID$"] ("$AIRef.ObjectID$")";
		}
	}

	return GameRuleString;
}

/// <summary>
/// Returns a string representation of this object.
/// </summary>
native function string ToString() const;
//***************************************************

static function XComGameStateContext_TacticalGameRule BuildContextFromGameRule(GameRuleStateChange GameRule)
{
	local XComGameStateContext_TacticalGameRule StateChangeContext;

	StateChangeContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	StateChangeContext.GameRuleType = GameRule;

	return StateChangeContext;
}

/// <summary>
/// This creates a minimal start state with a battle data object and three players - one Human and two AI(aliens, civilians). Returns the new game state
/// and also provides an optional out param for the battle data for use by the caller
/// </summary>
static function XComGameState CreateDefaultTacticalStartState_Singleplayer(optional out XComGameState_BattleData CreatedBattleDataObject)
{
	local XComGameStateHistory History;
	local XComGameState StartState;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState_BattleData BattleDataState;
	local XComGameState_Player XComPlayerState;
	local XComGameState_Player EnemyPlayerState;
	local XComGameState_Player CivilianPlayerState;
	local XComGameState_Player TheLostPlayerState;
	local XComGameState_Player ResistancePlayerState;
	local XComGameState_Player TeamOneState;
	local XComGameState_Player TeamTwoState;
	
	History = `XCOMHISTORY;

	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);

	BattleDataState = XComGameState_BattleData(StartState.CreateNewStateObject(class'XComGameState_BattleData'));
	BattleDataState.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );
	
	XComPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_XCom);
	XComPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());

	EnemyPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Alien);
	EnemyPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(EnemyPlayerState.GetReference());

	CivilianPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Neutral);
	CivilianPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.CivilianPlayerRef = CivilianPlayerState.GetReference();

	TheLostPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_TheLost);
	TheLostPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(TheLostPlayerState.GetReference());

	ResistancePlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Resistance);
	ResistancePlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(ResistancePlayerState.GetReference());

	TeamOneState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_One); //issue #188 - initing MP teams here for singleplayer
	TeamOneState.bPlayerReady = true;
	BattleDataState.PlayerTurnOrder.AddItem(TeamOneState.GetReference());
		
	TeamTwoState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Two);
	TeamTwoState.bPlayerReady = true;
	BattleDataState.PlayerTurnOrder.AddItem(TeamTwoState.GetReference());	//end #188
	
	// create a default cheats object
	StartState.CreateNewStateObject(class'XComGameState_Cheats');

	CreatedBattleDataObject = BattleDataState;
	return StartState;
}

/// <summary>
/// This creates a minimal start state with a battle data object and two players. Returns the new game state
/// and also provides an optional out param for the battle data for use by the caller
/// </summary>
static function XComGameState CreateDefaultTacticalStartState_Multiplayer(optional out XComGameState_BattleDataMP CreatedBattleDataObject)
{
	local XComGameStateHistory History;
	local XComGameState StartState;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState_BattleDataMP BattleDataState;
	local XComGameState_Player XComPlayerState;

	History = `XCOMHISTORY;

	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);

	BattleDataState = XComGameState_BattleDataMP(StartState.CreateNewStateObject(class'XComGameState_BattleDataMP'));
	BattleDataState.BizAnalyticsSessionID = `FXSLIVE.GetGUID( );
	
	XComPlayerState = XComGameState_Player(StartState.CreateNewStateObject(class'XComGameState_Player'));
	XComPlayerState.PlayerClassName = Name( "XGPlayer" );
	XComPlayerState.TeamFlag = eTeam_One;
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());

	XComPlayerState = XComGameState_Player(StartState.CreateNewStateObject(class'XComGameState_Player'));
	XComPlayerState.PlayerClassName = Name( "XGPlayer" );
	XComPlayerState.TeamFlag = eTeam_Two;
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());

	// create a default cheats object
	StartState.CreateNewStateObject(class'XComGameState_Cheats');
	
	CreatedBattleDataObject = BattleDataState;
	return StartState;
}

function OnSubmittedToReplay(XComGameState SubmittedGameState)
{
	local XComGameState_Unit UnitState;

	if (GameRuleType == eGameRule_ReplaySync)
	{
		foreach SubmittedGameState.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
		{
			UnitState.SetVisibilityLocation(UnitState.TileLocation);

			if (!UnitState.GetMyTemplate( ).bIsCosmetic && !UnitState.bRemovedFromPlay)
			{
				`XWORLD.SetTileBlockedByUnitFlag(UnitState);
			}
		}
	}
}

// Debug-only function used in X2DebugHistory screen.
function bool HasAssociatedObjectID(int ID)
{
	return UnitRef.ObjectID == ID;
}

function int GetPrimaryObjectRef()
{
	return ((UnitRef.ObjectID > 0) ? UnitRef.ObjectID : PlayerRef.ObjectID);
}
