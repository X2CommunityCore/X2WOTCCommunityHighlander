
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComGameState_AIUnitData.uc    
//  AUTHOR:  Alex Cheng  --  1/27/2014
//  PURPOSE: XComGameState_AIUnitData, container for persistent data needed by each AI Unit.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AIUnitData extends XComGameState_BaseObject
	dependson(X2AIBTBehavior)
	config(AI)
	native(AI);

var private config int RemoveAlertDataOlderThanAge;

var()   int			 m_iUnitObjectID;
var()   TTile		 m_kRegroupTile;
var()   array<int>	 m_arrCorpsesSeen; // Keep track of corpses seen - only kick off red alert when first seen.

// For debugging
var bool bDoDebug;
// For debugging

enum EAlertCause
{
	eAC_None,
	eAC_UNUSED_1,
	eAC_UNUSED_2,
	// Map Control - Scary
	// These do not trigger red alert
	// These do not cause scamper matinee
	// These cause yellow alert (UNLESS NOTED)
	eAC_MapwideAlert_Hostile,			// Kicked off by Kismet.
	eAC_ThrottlingBeacon,				// Group-specific trigger to influence activity-balancing from the FightManager. DOES NOT CAUSE YELLOW ALERT
	eAC_XCOMAchievedObjective,
	eAC_AlertedByCommLink,				// Repurposed this enum to a Chosen alert (wasn't previously being used).

	// Map Control - Routine
	// These do not trigger red alert
	// These do not cause scamper matinee
	// These do not cause yellow alert (UNLESS NOTED)
	eAC_MapwideAlert_Peaceful,          // No alert trigger, kicked off by Kismet

	// Personal Knowledge
	// These cause enemies to go into red alert
	// These cause scamper matinee
	eAC_TookDamage,						// Conditional red alert trigger (with LOS to damage instigator)  TODO: IS THIS TRUE
	eAC_TakingFire,						// Conditional red alert trigger (with LOS to shot instigator and within sound range)   TODO: IS THIS TRUE
	eAC_SeesSpottedUnit,

	eAC_Allow_Nonvisible_Cutoff_DO_NOT_SET_TO_THIS, // Causes above this line are allowed for nonvisible units

	// Indirect
	// These cause yellow alert
	eAC_DetectedNewCorpse,
	eAC_DetectedAllyTakingDamage,
	eAC_DetectedSound,
	eAC_AlertedByYell,
	eAC_SeesExplosion,
	eAC_SeesSmoke,
	eAC_SeesFire,
	eAC_SeesAlertedAllies,
	eAC_UNUSED_3,
	eAC_UNUSED_4,
};

enum EAlertKnowledgeType
{
	eAKT_None,
	eAKT_Absolute,
	eAKT_FormerAbsolute,
	eAKT_Implied,
};

struct native AlertData
{
	var TTile AlertLocation;
	//var TTile UnitLocationAtTimeOfAlert; // dkaplan: removed 3/23/15
	var int PlayerTurn;
	var int HistoryIndex;
	var EAlertCause AlertCause;
	var int AlertSourceUnitID;
	var int AlertRadius;
	var EAlertKnowledgeType AlertKnowledgeType;
	var bool bWasAggressive;
	var String KismetTag; // Kismet-assigned tag
	var bool bUseUnitLocation; // Used to avoid excessive teammate alert updates (eAC_SeesAlertedAllies)
};
var() array<AlertData> m_arrAlertData;

struct native AlertAbilityInfo
{
	var TTile AlertTileLocation;
	var int AlertRadius;
	var int AlertUnitSourceID;
	var int AnalyzingHistoryIndex;
};

var() array<float> m_arrAlertDistSq;

var int JobIndex;				 // Assigned from the Job Manager.
var int JobOrderPlacementNumber; // Corresponds to which place this job is on the mission jobs list.

var EAlertCause RedAlertCause;
var EAlertCause YellowAlertCause;

var int			iRedAlertTurn;   // Keep track of turn this unit was first engaged in combat.

function Init(int iUnitID)
{
	m_iUnitObjectID = iUnitID;
}

function int GetAlertCount()
{
	return m_arrAlertData.Length;
}

function RemoveAlertDataAtIndex(int Index)
{
	if ( Index < m_arrAlertData.Length )
	{
		m_arrAlertData.Remove(Index, 1);
	}
}
function TTile GetAlertLocation(int Index)
{
	local XComGameState_Unit TargetUnitState;
	local TTile Tile;
	if( Index < m_arrAlertData.Length )
	{
		if( m_arrAlertData[Index].bUseUnitLocation )
		{
			TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrAlertData[Index].AlertSourceUnitID));
			if( TargetUnitState != None )
			{
				return TargetUnitState.TileLocation;
			}
		}
		return m_arrAlertData[Index].AlertLocation;
	}
	`RedScreen("Bad index passed into function"@GetFuncName()@ "acheng");
	return Tile;
}

function AlertData GetAlertData(int Index)
{
	local AlertData DataOut;
	if( Index < m_arrAlertData.Length )
	{
		DataOut = m_arrAlertData[Index];
		DataOut.AlertLocation = GetAlertLocation(Index);
		return DataOut;
	}
	`RedScreen("Bad index passed into function"@GetFuncName()@ "acheng");
	return DataOut;
}

function int GetAlertDataSourceID(int Index, bool bRequiresAggressive=true)
{
	local int SourceID;
	SourceID = INDEX_NONE;
	if( Index < m_arrAlertData.Length )
	{
		if( !bRequiresAggressive || IsCauseAggressive(m_arrAlertData[Index].AlertCause) )
		{
			SourceID = m_arrAlertData[Index].AlertSourceUnitID;
		}
	}
	return SourceID;
}

function OnBeginTacticalPlay(XComGameState NewGameState)
{
	local Object ThisObj;
	local X2EventManager EventManager;

	super.OnBeginTacticalPlay(NewGameState);

	ThisObj = self;
	EventManager = `XEVENTMGR;

	EventManager.RegisterForEvent( ThisObj, 'UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted );
}

function OnEndTacticalPlay(XComGameState NewGameState)
{
	local Object ThisObj;
	local X2EventManager EventManager;

	super.OnEndTacticalPlay(NewGameState);

	ThisObj = self;
	EventManager = `XEVENTMGR;

	EventManager.UnRegisterFromEvent( ThisObj, 'UnitMoveFinished' );
}

function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit AlertedUnit, MovedUnit;
	local XComGameState_Player MovedUnitPlayer;
	local XComGameStateHistory History;
	local int AlertDataIndex, i;
	local XComGameStateContext_Ability MoveContext;
	local XComGameState NewGameState;
	local XComGameState_AIUnitData NewAIUnitData;
	local AlertAbilityInfo AlertInfo;
	local TTile TestTile;
	local int PathIndex;

	`BEHAVIORTREEMGR.bWaitingOnEndMoveEvent = false;

	History = `XCOMHISTORY;
	AlertedUnit = XComGameState_Unit(History.GetGameStateForObjectID(m_iUnitObjectID));

	// Create new game state, add the alert data, submit
	MovedUnit = XComGameState_Unit(EventData);
	if( MovedUnit == none || AlertedUnit == none || AlertedUnit.IsDead() )
	{
		return ELR_NoInterrupt;
	}

	MovedUnitPlayer = XComGameState_Player(History.GetGameStateForObjectID(MovedUnit.ControllingPlayer.ObjectID));

	// Is the moved unit XCom
	if (MovedUnitPlayer.TeamFlag == eTeam_XCom)
	{
		// If the AI Unit can see the moved unit, then normal spotting updates will handle the post move update
		// If the unit is not visible, the AI must have known about it at some point prior so that it will
		// have tracked it
		if (!class'X2TacticalVisibilityHelpers'.static.CanUnitSeeLocation(m_iUnitObjectID, MovedUnit.TileLocation)
			&& IsKnowledgeAboutUnitAbsolute(MovedUnit.ObjectID, AlertDataIndex))
		{
			// The unit is not visible to the this AI's unit and previously had Absolute knowledge
			// Process the moved unit's path backwards until it can see a tile that the moved
			// unit passed through
			MoveContext = XComGameStateContext_Ability(GameState.GetContext());
			if( (MoveContext != None) && (MoveContext.GetMovePathIndex(MovedUnit.ObjectID) >= 0)) 
			{
				// If the unit is not visible, currently the last known position was at the
				// previous Absolute AlertData location
				AlertInfo.AlertTileLocation = GetAlertLocation(AlertDataIndex);
				AlertInfo.AlertUnitSourceID = MovedUnit.ObjectID;
				AlertInfo.AnalyzingHistoryIndex = GameState.HistoryIndex;

				PathIndex = MoveContext.GetMovePathIndex(MovedUnit.ObjectID);

				// TODO: Might need to check for interruption and use the InterruptionStep
				// Find the last tile along the movement path that the AI could have seen the
				// moving Unit
				i = (MoveContext.InputContext.MovementPaths[PathIndex].MovementTiles.Length - 1);
				while( i >= 0 )
				{
					TestTile = MoveContext.InputContext.MovementPaths[PathIndex].MovementTiles[i];
					if( class'X2TacticalVisibilityHelpers'.static.CanUnitSeeLocation(m_iUnitObjectID, TestTile) )
					{
						AlertInfo.AlertTileLocation = TestTile;
						i = INDEX_NONE;
					}

					--i;
				}
			}
			else // Move finished can happen from other contexts, like XComGameStateContext_Falling
			{
				// For all other contexts that cause a UnitMoveFinished, just assume the AI can figure out where the unit would be.
				// Set the alert info with the current moved unit location.  
				AlertInfo.AlertUnitSourceID = MovedUnit.ObjectID;
				AlertInfo.AnalyzingHistoryIndex = GameState.HistoryIndex;
				AlertInfo.AlertTileLocation = MovedUnit.TileLocation;
			}

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
			NewAIUnitData = XComGameState_AIUnitData(NewGameState.ModifyStateObject(class'XComGameState_AIUnitData', ObjectID));
			if( NewAIUnitData.AddAlertData(m_iUnitObjectID, eAC_SeesSpottedUnit, AlertInfo, NewGameState) )
			{
				`TACTICALRULES.SubmitGameState(NewGameState);
			}
			else
			{
				NewGameState.PurgeGameStateForObjectID(NewAIUnitData.ObjectID);
				History.CleanupPendingGameState(NewGameState);
			}
		}
	}

	return ELR_NoInterrupt;
}

function bool IsDownThrottlingActive()
{
	local XComGameState_AIPlayerData AIPlayerData;
	local XGAIPlayer AIPlayer;

	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	AIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(AIPlayer.GetAIDataID()));
	return AIPlayerData.bDownThrottlingActive;
}

// Returns true if the AlertCause was successfully added as AlertData to the AI unit
function bool AddAlertData( int AlertedUnitID, EAlertCause NewAlertCause, AlertAbilityInfo AlertInfo, XComGameState NewGameState, optional String KismetTag, optional bool bSingleton=false )
{
	local int AlertDataIndex, ExistingAlertDataIndex, SavedSourceUnitID;
	local XComGameStateHistory History;
	local XComGameState_Unit AlertedUnit, AlertSourceUnit;
	local bool bIsAggressive, bIsCauseAbsolute;
	local EAlertKnowledgeType NewKnowledgeType, ExistingKnowledgeType;
	local TTIle TileLocation;
	local XComGameState_Player ControllingPlayer;

	`assert(NewAlertCause != eAC_None);
	History = `XCOMHISTORY;

	AlertedUnit = XComGameState_Unit(History.GetGameStateForObjectID(AlertedUnitID));
	if(AlertedUnit == none || AlertedUnit.IsDead())
	{
		return false;
	}

	if( !IsCauseAllowedForNonvisibleUnits(NewAlertCause) 
	   && ( class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(AlertedUnit.ObjectID)==0 ) )
	{
		// The passed in cause may not be put on nonvisible AI Units and the unit is not visible to the enemy
		`LogAI("AlertData - This Alert Cause cannot be added to nonvisible units:" @NewAlertCause);
		return false;
	}

	// When down-throttling is active, only absolute knowledge alerts or throttling alerts from the Fight Mgr, or kismet alerts can be added.
	if( IsDownThrottlingActive() && !(IsCauseAbsoluteKnowledge(NewAlertCause) || NewAlertCause == eAC_ThrottlingBeacon ||
									  NewAlertCause == eAC_MapwideAlert_Hostile || NewAlertCause == eAC_MapwideAlert_Peaceful))
	{
		`LogAI("Down-Throttling in effect!  Ignoring indirect knowledge alert:" @NewAlertCause);
		return false;
	}

	`LogAI("AlertData - Incoming AlertData:" @NewAlertCause$"Alerted Unit: " @AlertedUnitID);

	AlertSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AlertInfo.AlertUnitSourceID));
	if( AlertSourceUnit != none && AlertSourceUnit.GetMyTemplate().bIsCosmetic )
	{
		`LogAI("Discarding alert data from cosmetic units.");
		return false;
	}
	ControllingPlayer = XComGameState_Player(History.GetGameStateForObjectID(AlertedUnit.ControllingPlayer.ObjectID));
	SavedSourceUnitID = 0;
	bIsAggressive = false;
	NewKnowledgeType = eAKT_Implied;
	TileLocation = AlertInfo.AlertTileLocation;
	AlertDataIndex = INDEX_NONE;

	if (AlertSourceUnit != None)
	{
		ExistingKnowledgeType = GetKnowledgeTypeAboutUnit(AlertSourceUnit.ObjectID, AlertDataIndex);
		SavedSourceUnitID = AlertSourceUnit.ObjectID;
	}
	bIsCauseAbsolute = IsCauseAbsoluteKnowledge(NewAlertCause);

	if( (AlertDataIndex != INDEX_NONE) )
	{
		// There is existing knowledge about this unit
		if( (ExistingKnowledgeType == eAKT_Absolute) && (AlertInfo.AnalyzingHistoryIndex <= m_arrAlertData[AlertDataIndex].HistoryIndex)
			&& (NewAlertCause != eAC_DetectedNewCorpse))
		{
			// Already have existing Absolute knowledge about this source unit
			// AND
			// The incoming data is not newer than what is already known
			// AND
			// The AlertCause is NOT that the associated unit is now a corpse
			`LogAI("AlertData - Existing Alert Data for the unit");
			return false;
		}
	}

	if ((NewAlertCause == eAC_DetectedSound)
		&& AlertSourceUnit != None
		&& class'X2TacticalVisibilityHelpers'.static.CanUnitSeeLocation(AlertedUnitID, AlertSourceUnit.TileLocation)
		&& (ControllingPlayer.TeamFlag == AlertSourceUnit.GetTeam()))
	{
		// The incoming data was caused by a sound
		// AND
		// The source tile is visible to the alerted Unit
		// AND
		// The alerted Unit and the source Unit are on the same team
		// Do not store this AlertData
		`LogAI("AlertData - Sound alert from visible teammate");
		return false;
	}

	if ((AlertDataIndex != INDEX_NONE) && (NewAlertCause == eAC_DetectedNewCorpse))
	{
		// There is existing knowledge on this unit AND it is now a corpse
		// Downgrade the existing knowledge to be implied and no longer save the associated ID
		SavedSourceUnitID = 0;
	}
	else if ((AlertSourceUnit != none)
			 && ((ExistingKnowledgeType == eAKT_Absolute) || (bIsCauseAbsolute && ExistingKnowledgeType != eAKT_Absolute)))
	{
		// The AlertSourceUnit exists
		// AND
		// If there is an existing AlertData with the Source ID whose knowledge is Absolute
		// or the new cause is Absolute knowledge and there isn't an associated AlertData with
		// Absolute knowledge
		bIsAggressive = IsCauseAggressive(NewAlertCause);
		NewKnowledgeType = eAKT_Absolute;

		// If the new alert's associated Unit is not longer visible, then the knowledge becomes eAKT_FormerAbsolute
		if (!class'X2TacticalVisibilityHelpers'.static.CanUnitSeeLocation(AlertedUnitID, AlertSourceUnit.TileLocation))
		{
			NewKnowledgeType = eAKT_FormerAbsolute;
		}
		else
		{
			TileLocation = AlertSourceUnit.TileLocation;
		}
	}
	else if( NewAlertCause == eAC_ThrottlingBeacon )
	{
		// Find existing mapwide alert.  Check HistoryFrame if we should exit early or overwrite.
		AlertDataIndex = m_arrAlertData.Find('AlertCause', NewAlertCause);
		if (AlertDataIndex != INDEX_NONE)
		{
			// Skip overwrite if this is not a newer history frame.
			if( AlertInfo.AnalyzingHistoryIndex <= m_arrAlertData[AlertDataIndex].HistoryIndex )
			{
				`LogAI("AlertData - Older mapwide alert");
				return false;
			}
		}
	}
	else if( (NewAlertCause == eAC_MapwideAlert_Hostile || NewAlertCause == eAC_MapwideAlert_Peaceful) && bSingleton )
	{
		AlertDataIndex = m_arrAlertData.Find('KismetTag', KismetTag); // Overwrite any matching kismet tag.
	}
	else if (!bIsCauseAbsolute && IsAlertDataKnowledgeTypeOnTile(eAKT_Implied, TileLocation, AlertDataIndex))
	{
		// TODO: This might need to only be for certain implied data: Corpses and other things
		// An existing AlertData with implied knowledge exists. Update this AlertData.
	}
	else
	{
		AlertDataIndex = INDEX_NONE;
	}

	// if any existing knowledge matches the incoming alert data - don't perform an update
	for( ExistingAlertDataIndex = 0; ExistingAlertDataIndex < m_arrAlertData.Length; ++ExistingAlertDataIndex )
	{
		if( (m_arrAlertData[ExistingAlertDataIndex].bUseUnitLocation || // This flag ignores the alert location.
				m_arrAlertData[ExistingAlertDataIndex].AlertLocation == TileLocation)		   &&
			m_arrAlertData[ExistingAlertDataIndex].PlayerTurn == ControllingPlayer.PlayerTurnCount &&
			m_arrAlertData[ExistingAlertDataIndex].AlertCause == NewAlertCause &&
			m_arrAlertData[ExistingAlertDataIndex].AlertSourceUnitID == SavedSourceUnitID &&
			m_arrAlertData[ExistingAlertDataIndex].AlertRadius == AlertInfo.AlertRadius &&
			m_arrAlertData[ExistingAlertDataIndex].AlertKnowledgeType == NewKnowledgeType &&
			m_arrAlertData[ExistingAlertDataIndex].bWasAggressive == bIsAggressive &&
			m_arrAlertData[ExistingAlertDataIndex].KismetTag == KismetTag )
		{
			`LogAI("AlertData - Ignoring known Alert Data");
			return false;
		}
	}

	if (`XWORLD.IsTileOutOfRange(TileLocation))
	{
		`LogAI("AlertData - Ignoring Tile Location outside world bounds");
		return false;
	}

	if( AlertDataIndex == INDEX_NONE )
	{
		// No Alert Data with absolute knowledge was found for the associated Unit
		// Add a new Alert Data
		AlertDataIndex = m_arrAlertData.Length;
		m_arrAlertData.Add(1);
	}

	m_arrAlertData[AlertDataIndex].AlertLocation = TileLocation;
	//m_arrAlertData[AlertDataIndex].UnitLocationAtTimeOfAlert = AlertedUnit.TileLocation;
	m_arrAlertData[AlertDataIndex].PlayerTurn = ControllingPlayer.PlayerTurnCount;
	m_arrAlertData[AlertDataIndex].HistoryIndex = AlertInfo.AnalyzingHistoryIndex;
	m_arrAlertData[AlertDataIndex].AlertCause = NewAlertCause;
	m_arrAlertData[AlertDataIndex].AlertSourceUnitID = SavedSourceUnitID;
	m_arrAlertData[AlertDataIndex].AlertRadius = AlertInfo.AlertRadius;  // TODO: Might want to not always set this, for example when updating a known Alert Data
	m_arrAlertData[AlertDataIndex].AlertKnowledgeType = NewKnowledgeType;
	m_arrAlertData[AlertDataIndex].bWasAggressive = bIsAggressive;
	m_arrAlertData[AlertDataIndex].KismetTag = KismetTag;
	if( NewAlertCause == eAC_SeesAlertedAllies )
	{
		// Help prevent history spam.  Don't update every move of every alerted ally visible to this unit.
		// This should only be updated once now - the first time the alerted ally is seen.
		m_arrAlertData[AlertDataIndex].bUseUnitLocation = true;
	}

	`assert(m_arrAlertData[AlertDataIndex].AlertCause != eAC_None);

	// Update the associated unit's Alert Level
	ApplyAlertAbilityForNewAlertData(AlertedUnit, NewAlertCause, NewGameState);

	if( NewAlertCause != eAC_MapwideAlert_Hostile &&
		NewAlertCause != eAC_MapwideAlert_Peaceful &&
		NewAlertCause != eAC_ThrottlingBeacon) // This gets added to all units within the SeqAct_DropAlert activate fn.
	{
		// Inform anyone in the this AI's group that new AlertData has come in and add it
		AddGroupAlertData(m_arrAlertData[AlertDataIndex], AlertedUnit, AlertInfo, NewGameState);
	}

	return true;
}

private function AddGroupAlertData(AlertData AIAlertData, XComGameState_Unit AIUnit, AlertAbilityInfo AIAlertInfo, XComGameState NewGameState)
{
	local array<int> OutPatrolGroupObjectIDs; //ObjectIDs for the patrol group the AIUnit is part of
	local XComGameState_AIPlayerData AIPlayerData;
	local int i, j, GroupAlertDataArrayIndex, AIUnitID;
	local XComGameStateHistory History;
	local XComGameState_Unit GroupAIUnit;
	local XComGameState_AIUnitData GroupAIUnitData_NewState;
	local AlertData GroupAIAlertData;
	local bool bAddAlert;

	History = `XCOMHISTORY;

	//Find the AI player data object
	foreach History.IterateByClassType(class'XComGameState_AIPlayerData', AIPlayerData)
	{
		//if (AIPlayerData.m_iPlayerObjectID == AIUnit.ControllingPlayer.ObjectID)
		if(AIPlayerData.m_iPlayerObjectID > 0) //issue #226 - grab the first AIPlayerData, since there should only be one
		{
			break;
		}
	}

	if (AIPlayerData != None && AIPlayerData.GetGroupMembersFromUnitObjectID(AIUnit.ObjectID, OutPatrolGroupObjectIDs))
	{
		// This unit has an associated group so add so loop over the units in this AI's group
		for (i = 0; i < OutPatrolGroupObjectIDs.Length; ++i)
		{
			if ((AIAlertInfo.AlertUnitSourceID != OutPatrolGroupObjectIDs[i]) && (AIUnit.ObjectID != OutPatrolGroupObjectIDs[i]))
			{
				// The AlertData's source is not the same as the Unit being updated
				// AND
				// The AI Unit sharing the knowledge is not the same as the Unit being updated
				GroupAIUnit = XComGameState_Unit(History.GetGameStateForObjectID(OutPatrolGroupObjectIDs[i]));
				if (!GroupAIUnit.IsDead())
				{
					// If this GroupAIUnit is alive, process the AlertData on it
					AIUnitID = GroupAIUnit.GetAIUnitDataID();
					if ( AIUnitID > 0 )
					{
						GroupAIUnitData_NewState = XComGameState_AIUnitData(NewGameState.ModifyStateObject(class'XComGameState_AIUnitData', AIUnitID));
					}
					else
					{
						// Create a new ai unit and clear the alert updates
						GroupAIUnitData_NewState = XComGameState_AIUnitData(NewGameState.CreateNewStateObject(class'XComGameState_AIUnitData'));
					}
				
					j = 0;
					GroupAlertDataArrayIndex = INDEX_NONE;
					bAddAlert = true;
					while ((j < GroupAIUnitData_NewState.m_arrAlertData.Length) && bAddAlert && (GroupAlertDataArrayIndex == INDEX_NONE))
					{
						// Decide if this AlertData should be added and how
						GroupAIAlertData = GroupAIUnitData_NewState.m_arrAlertData[j];

						if (AIAlertData.AlertKnowledgeType == eAKT_Absolute)
						{
							// Update if there is existing knowledge on this unit
							if ((AIAlertData.AlertSourceUnitID != 0) && (AIAlertData.AlertSourceUnitID == GroupAIAlertData.AlertSourceUnitID))
							{
								// The incoming knowledge is Absolute and there is existing known data, so update this index no matter what
								// TODO: Possibly ignore if existing is Absolute and incoming info is not older
								GroupAlertDataArrayIndex = j;
							}
							// Add this Absolute knowledge if no existing knowledge for the Unit exists
						}
						else if (AIAlertData.AlertKnowledgeType == eAKT_FormerAbsolute)
						{
							// Possibly update if there is existing knowledge on this unit
							if ((AIAlertData.AlertSourceUnitID != 0) && (AIAlertData.AlertSourceUnitID == GroupAIAlertData.AlertSourceUnitID))
							{
								// The incoming knowledge is Formerly Absolute and there is existing known data
								if (GroupAIAlertData.AlertKnowledgeType != eAKT_Absolute)
								{
									// The existing knowledge is not Absolute so update
									GroupAlertDataArrayIndex = j;
								}
								else
								{
									// The existing knowledge is Absolute, so don't update
									bAddAlert = false;
								}
							}						
							// Add this Formerly Absolute knowledge if no existing knowledge for the Unit exists
						}
						else
						{
							// The incoming knowledge is Implied
							if ((AIAlertInfo.AlertUnitSourceID != 0) && (AIAlertInfo.AlertUnitSourceID == GroupAIAlertData.AlertSourceUnitID)
								&& (AIAlertData.AlertCause == eAC_DetectedNewCorpse))
							{
								// Update if there is existing knowledge on this unit AND the cause of the alert allows that to be downgraded
								GroupAlertDataArrayIndex = j;
							}
							else if (AIAlertData.AlertLocation == GroupAIAlertData.AlertLocation)
							{
								// The AlertDatas are not the same unit but are on the same tile
								if (GroupAIAlertData.AlertKnowledgeType == eAKT_Implied)
								{
									// The stored AlertData is implied
									if ((AIAlertInfo.AnalyzingHistoryIndex > GroupAIAlertData.HistoryIndex))
									{
										// Replace with the newer incoming AlertData
										GroupAlertDataArrayIndex = j;
									}
									else
									{
										// TODO: This might need to only be for certain implied data: Corpses and other things
										// The new implied knowledge is not newer, so don't update
										bAddAlert = false;
									}
								}
							}
							// Add this Implied knowledge if no existing knowledge on the tile exists
						}

						++j;
					}

					if (bAddAlert && GroupAlertDataArrayIndex == INDEX_NONE)
					{
						// This GroupAIUnitData has no knowledge at all. The incoming AlertData should be added.
						GroupAlertDataArrayIndex = GroupAIUnitData_NewState.m_arrAlertData.Length;
						GroupAIUnitData_NewState.m_arrAlertData.Add(1);
					}

					if (GroupAlertDataArrayIndex != INDEX_NONE)
					{
						// The incoming AlertData has been added to this Unit's AI Data
						GroupAIUnitData_NewState.m_arrAlertData[GroupAlertDataArrayIndex] = AIAlertData;
						//GroupAIUnitData_NewState.m_arrAlertData[GroupAlertDataArrayIndex].UnitLocationAtTimeOfAlert = GroupAIUnit.TileLocation;

						`assert(GroupAIUnitData_NewState.m_arrAlertData[GroupAlertDataArrayIndex].AlertCause != eAC_None);

						// Update the associated unit's Alert Level
						GroupAIUnitData_NewState.ApplyAlertAbilityForNewAlertData(GroupAIUnit, AIAlertData.AlertCause, NewGameState);
					}
					else
					{
						// The incoming AlertData has not been added to this Unit's AI Data
						NewGameState.PurgeGameStateForObjectID(GroupAIUnitData_NewState.ObjectID);
					}
				}
			}
		}
	}
}

function ApplyAlertAbilityForNewAlertData(XComGameState_Unit AssociatedUnitState, EAlertCause AlertCause, XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local XComGameState_Player ControllingPlayer;

	if( RedAlertCause == eAC_None &&
		class'XComGameState_AIUnitData'.static.IsCauseAggressive(AlertCause) &&
		(AssociatedUnitState.GetCurrentStat(eStat_AlertLevel) < `ALERT_LEVEL_RED) )
	{
		// go to red alert
		RedAlertCause = AlertCause;
		// Also keep track of what turn number this unit went into red alert.
		ControllingPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(AssociatedUnitState.ControllingPlayer.ObjectID));
		iRedAlertTurn = ControllingPlayer.PlayerTurnCount;
	}
	else if( YellowAlertCause == eAC_None &&
			 class'XComGameState_AIUnitData'.static.IsCauseSuspicious(AlertCause) &&
			 (AssociatedUnitState.GetCurrentStat(eStat_AlertLevel) < `ALERT_LEVEL_YELLOW) )
	{
		// go to yellow alert
		YellowAlertCause = AlertCause;
	}

	// process the alert ability
	if( (RedAlertCause != eAC_None) || (YellowAlertCause != eAC_None) )
	{
		EventManager = `XEVENTMGR;

		EventManager.TriggerEvent('AlertDataTriggerAlertAbility', , AssociatedUnitState, NewGameState);
	}
}

function RemoveOldAlertData()
{
	local XComGameState_Unit AIUnit;
	local XComGameState_Player AIUnitPlayer;
	local XComGameStateHistory History;
	local int i;

	History = `XCOMHISTORY;
	AIUnit = XComGameState_Unit(History.GetGameStateForObjectID(m_iUnitObjectID));
	AIUnitPlayer = XComGameState_Player(History.GetGameStateForObjectID(AIUnit.ControllingPlayer.ObjectID));

	for (i = (m_arrAlertData.Length - 1); i >= 0; --i)
	{
		if ( m_arrAlertData[i].KismetTag == "" 
			&& (AIUnitPlayer.PlayerTurnCount - m_arrAlertData[i].PlayerTurn) > default.RemoveAlertDataOlderThanAge)
		{
			m_arrAlertData.RemoveItem(m_arrAlertData[i]);
		}
	}
}

function bool DoesLocationContainExistingAlert( TTile AlertLocation, optional out int OutIndex )
{
	local bool bResult;
	local int i;

	// If there is an associated Alert Data with this location and
	// contains a source ID, then find it
	bResult = false;
	i = 0;
	OutIndex = INDEX_NONE;
	while (i < m_arrAlertData.Length && !bResult)
	{
		if ((m_arrAlertData[i].AlertLocation == AlertLocation) && (m_arrAlertData[i].AlertSourceUnitID != 0))
		{
			// Found an Alert Data entry with this associated Location
			// Check to see if it is an absolute knowledge entry

			`assert(m_arrAlertData[i].AlertKnowledgeType == eAKT_Absolute);

			if (IsCauseAbsoluteKnowledge(m_arrAlertData[i].AlertCause))
			{
				bResult = true;
				OutIndex = i;
			}
		}

		i++;
	}

	return bResult;
}

function GetAbsoluteKnowledgeUnitList( out array<StateObjectReference> arrKnownUnits, optional out array<XComGameState_Unit> UnitStateList, bool bSkipUndamageable=true, bool IncludeCiviliansOnTerror=true)
{
    local AlertData kData;
    local StateObjectReference kUnitRef;
    local XComGameState_Unit Unit;
    local XComGameStateHistory History;
    local XComGameState_BattleData Battle;
    local XGAIPlayer AIPlayer, EnemyAIPlayer;
    local XGPlayer EnemyPlayer;
    local XComGameState_Player EnemyPlayerState;
    local array<XComGameState_Player> EnemyPlayers;
    local array<XComGameState_Unit> AllEnemies;
 
    History = `XCOMHISTORY;
    Unit = XComGameState_Unit(History.GetGameStateForObjectID(m_iUnitObjectID));
    AIPlayer = XGAIPlayer(History.GetVisualizer(Unit.ControllingPlayer.ObjectID));
 
    if( AIPlayer != None && AIPlayer.bAIHasKnowledgeOfAllUnconcealedXCom )
    {
		// start issue #619: use our CHhelpers function to check *all* enemies of a unit
        EnemyPlayers = class'CHHelpers'.static.GetEnemyPlayers(AIPlayer);
        foreach EnemyPlayers(EnemyPlayerState)
        {
            if (EnemyPlayerState.GetTeam() == ETeam_XCom)
            {
                EnemyPlayer = XGPlayer(EnemyPlayerState.GetVisualizer());
           
                if( bSkipUndamageable )
                {
                    EnemyPlayer.GetPlayableUnits(AllEnemies);
                }
                else
                {
                    EnemyPlayer.GetUnits(AllEnemies);
                }
            }
            else
            {
                EnemyAIPlayer = XGAIPlayer(EnemyPlayerState.GetVisualizer());
       
                if( bSkipUndamageable )
                {
                    EnemyAIPlayer.GetPlayableUnits(AllEnemies);
                }
                else
                {
                    EnemyAIPlayer.GetUnits(AllEnemies);
                }
            }
        }
		// end issue #619
        UnitStateList.Length = 0;
        arrKnownUnits.Length = 0;
        foreach AllEnemies(Unit)
        {
            if( !Unit.IsConcealed() && !Unit.bRemovedFromPlay )
            {
                arrKnownUnits.AddItem(Unit.GetReference());
                UnitStateList.AddItem(Unit);
            }
        }
    }
    //bAIHasKnowledgeOfAllUnconcealedXCom defaults to true and is unused so this section wont ever apply
    else
    {
        arrKnownUnits.Length = 0;
        foreach m_arrAlertData(kData)
        {
            if( IsCauseAbsoluteKnowledge(kData.AlertCause) )
            {
                Unit = XComGameState_Unit(History.GetGameStateForObjectID(kData.AlertSourceUnitID));
                if( bSkipUndamageable &&
                   (Unit.bRemovedFromPlay
                   || Unit.IsDead()
                   || Unit.IsIncapacitated()
                   || Unit.bDisabled
                   || Unit.GetMyTemplate().bIsCosmetic)
                   )
                {
                    continue;
                }
 
                kUnitRef = Unit.GetReference();
                if( arrKnownUnits.Find('ObjectID', kUnitRef.ObjectID) == -1 )
                {
                    arrKnownUnits.AddItem(kUnitRef);
                    UnitStateList.AddItem(Unit);
                }
            }
        }
    }
 
    if( IncludeCiviliansOnTerror )
    {
        // Include civilians on terror maps.  These don't have alert data.
        Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
        if( Battle.AreCiviliansAlienTargets() )
        {
            class'X2TacticalVisibilityHelpers'.static.GetAllVisibleUnitsOnTeamForSource(m_iUnitObjectID, eTeam_Neutral, arrKnownUnits);
        }
    }
}

function bool HasAbsoluteKnowledge( out StateObjectReference kSpottedUnit, bool bConsiderFormerAbsolute=false )
{
	local int i;

	i = 0;
	while (i < m_arrAlertData.Length)
	{
		if (m_arrAlertData[i].AlertKnowledgeType == eAKT_Absolute)
		{
			// The unit has a data entry and it is absolute knowledge
			kSpottedUnit = `XCOMHISTORY.GetGameStateForObjectID(m_arrAlertData[i].AlertSourceUnitID).GetReference();
			return true;
		}
		else if (m_arrAlertData[i].AlertKnowledgeType == eAKT_FormerAbsolute)
		{
			kSpottedUnit = `XCOMHISTORY.GetGameStateForObjectID(m_arrAlertData[i].AlertSourceUnitID).GetReference();
		}

		i++;
	}

	return false;
}

function UpdatePriorityDistances()
{
	local AlertData kData;
	local float fDist;
	local vector vCurrLoc, vLoc;
	local XComWorldData World;

	World = `XWORLD;
	m_arrAlertDistSq.Length = 0;
	vCurrLoc = World.GetPositionFromTileCoordinates(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_iUnitObjectID)).TileLocation);
	foreach m_arrAlertData(kData)
	{
		vLoc = World.GetPositionFromTileCoordinates(kData.AlertLocation);
		fDist = VSizeSq(vLoc - vCurrLoc);
		m_arrAlertDistSq.AddItem(fDist);
	}
}

function bool GetPriorityAlertData(out AlertData kData_out, optional out float fDistSq, bool bIgnoreImpliedAlerts=false)
{
	local int i, iTop, Count;

	Count = m_arrAlertData.Length;
	iTop=-1;
	UpdatePriorityDistances();
	for( i = 0; i < Count; ++i )
	{
		if( bIgnoreImpliedAlerts && m_arrAlertData[i].AlertKnowledgeType == eAKT_Implied )
		{
			continue;
		}
		if (iTop == -1 || IsHigherPriorityAlert(i, iTop))
		{
			iTop = i;
		}
	}

	if (iTop > -1)
	{
		kData_out = GetAlertData(iTop);
		fDistSq = m_arrAlertDistSq[iTop];
		return true;
	}
	return false;
}

function bool IsHigherPriorityAlert(int iAlertA, int iAlertB)
{
	if (m_arrAlertData[iAlertA].AlertCause < m_arrAlertData[iAlertB].AlertCause)
		return true;

	if (m_arrAlertData[iAlertA].AlertCause == m_arrAlertData[iAlertB].AlertCause)
	{
		// Compare distances.  Closer alert takes higher priority(?)
		if (m_arrAlertDistSq[iAlertA] < m_arrAlertDistSq[iAlertB])
			return true;
	}
	// TODO- fill this out more for other factors.

	return false;
}

function bool IsKnowledgeAboutUnitAbsolute( int UnitID, optional out int OutIndex )
{
	local int i;

	// If there is an associated unit with this addition, then find it
	i = 0;
	OutIndex = INDEX_NONE;
	while (i < m_arrAlertData.Length && (OutIndex == INDEX_NONE))
	{
		if ((m_arrAlertData[i].AlertSourceUnitID == UnitID) && (m_arrAlertData[i].AlertKnowledgeType == eAKT_Absolute))
		{
			// The unit has a data entry and it is absolute knowledge
			OutIndex = i;
		}

		i++;
	}

	return (OutIndex != INDEX_NONE);
}

function EAlertKnowledgeType GetKnowledgeTypeAboutUnit( int UnitID, optional out int OutIndex )
{
	local int i;
	local EAlertKnowledgeType result;

	// If there is an associated unit with this addition, then find it
	i = 0;
	OutIndex = INDEX_NONE;
	result = eAKT_None;
	while (i < m_arrAlertData.Length && (OutIndex == INDEX_NONE))
	{
		if ((m_arrAlertData[i].AlertSourceUnitID == UnitID))
		{
			// The unit has a data entry and it is absolute knowledge
			OutIndex = i;
			result = m_arrAlertData[i].AlertKnowledgeType;
		}

		i++;
	}

	return result;
}

function bool IsAlertDataKnowledgeTypeOnTile( EAlertKnowledgeType AlertType, TTile TileLocation, optional out int OutIndex )
{
	local int i;

	// If there is a tile already with this type of AlertType, then find it
	i = 0;
	OutIndex = INDEX_NONE;
	while (i < m_arrAlertData.Length && (OutIndex == INDEX_NONE))
	{
		if ((m_arrAlertData[i].AlertKnowledgeType == AlertType) && (m_arrAlertData[i].AlertLocation == TileLocation))
		{
			// The unit has a data entry and it is absolute knowledge
			OutIndex = i;
		}

		i++;
	}

	return (OutIndex != INDEX_NONE);
}

static function bool IsCauseAbsoluteKnowledge( EAlertCause AlertCause )
{
	local bool bResult;

	bResult = false;
	switch (AlertCause)
	{
	case eAC_SeesSpottedUnit:
		bResult = true;
		break;
	}

	return bResult;
}

// these alert causes are allowed to change alert levels to yellow or red even if they occur outside the player's vision (offscreen) and are triggered by other AIs
static function bool ShouldEnemyFactionsTriggerAlertsOutsidePlayerVision(EAlertCause AlertCause)
{
	local bool bResult;

	bResult = false;
	switch( AlertCause )
	{
	case eAC_MapwideAlert_Hostile:
	case eAC_MapwideAlert_Peaceful:
	case eAC_AlertedByCommLink:
	case eAC_AlertedByYell:
	case eAC_TakingFire:
	case eAC_TookDamage:
	case eAC_DetectedAllyTakingDamage:
		bResult = true;
		break;
	}
	//Start Issue #1036
	bResult = TriggerOverrideEnemyFactionsAlertsOutsideVision(AlertCause, bResult);
	//End Issue #1036
	return bResult;
}

// Start Issue #1036
/// HL-Docs: feature:OverrideEnemyFactionsAlertsOutsideVision; issue:1036; tags:tactical
/// Fires an event that allows listeners to override whether a given alert cause
/// can be triggered by AI units outside of XCOM's vision. For example, you could
/// use this event to allow enemy pods to activate one another outside of XCOM
/// vision for a given set of alert causes.
///
/// Return `true` in `AllowThisCause` if the alert cause can be triggered in such
/// situations. Leave `AllowThisCause` untouched to retain the default behavior.
/// ```event
/// EventID: OverrideEnemyFactionsAlertsOutsideVision,
/// EventData: [ in enum[EAlertCause] AlertCause, inout bool AllowThisCause],
/// EventSource: none,
/// NewGameState: none
/// ```
static private function bool TriggerOverrideEnemyFactionsAlertsOutsideVision(EAlertCause AlertCause, bool AllowThisCause)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideEnemyFactionsAlertsOutsideVision';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].Kind = XComLWTVInt;
	OverrideTuple.Data[0].i = AlertCause;
	OverrideTuple.Data[1].Kind = XComLWTVBool;
	OverrideTuple.Data[1].b = AllowThisCause;

	`XEVENTMGR.TriggerEvent('OverrideEnemyFactionsAlertsOutsideVision', OverrideTuple);

	return OverrideTuple.Data[1].b;
}

static function bool IsCauseAllowedForNonvisibleUnits(EAlertCause AlertCause)
{
	// Start Issue #510
	//
	// Allow mods to override whether the given cause is allowed for
	// units outside of XCOM's vision. This allows them to enable
	// sound-based and other yellow alert activations.
	//
	// This event takes the form:
	//
	// {
	//    ID: OverrideAllowedAlertCause,
	//    Data: [in int AlertCause, inout bool AllowThisCause]
	// }
	//
	// Note that there is no event source in this case.
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideAllowedAlertCause';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].Kind = XComLWTVInt;
	OverrideTuple.Data[0].i = AlertCause;
	OverrideTuple.Data[1].Kind = XComLWTVBool;
	OverrideTuple.Data[1].b = AlertCause < eAC_Allow_Nonvisible_Cutoff_DO_NOT_SET_TO_THIS;

	`XEVENTMGR.TriggerEvent('OverrideAllowedAlertCause', OverrideTuple);

	return OverrideTuple.Data[1].b;
	// End Issue #510
}

// These alert causes trigger an alert level upgrade to Red Alert
static function bool IsCauseAggressive(EAlertCause AlertCause)
{
	local bool bResult;
	
	bResult = false;
	switch( AlertCause )
	{
	case eAC_TookDamage:
	case eAC_TakingFire:
	case eAC_SeesSpottedUnit:
		bResult = true;
		break;
	}

	return bResult;
}

// These alert causes trigger an alert level upgrade to Yellow Alert
static function bool IsCauseSuspicious(EAlertCause AlertCause)
{
	local bool bResult;

	bResult = false;
	switch( AlertCause )
	{
	case eAC_MapwideAlert_Hostile:
	case eAC_XCOMAchievedObjective:
	case eAC_AlertedByCommLink:
	case eAC_DetectedNewCorpse:
	case eAC_DetectedAllyTakingDamage:
	case eAC_DetectedSound:
	case eAC_AlertedByYell:
	case eAC_SeesExplosion:
	case eAC_SeesSmoke:
	case eAC_SeesFire:
	case eAC_SeesAlertedAllies:
		bResult = true;
		break;
	}

	return bResult;
}

// These alert causes are allowed to trigger a ReflexMoveActivate
static function bool DoesCauseReflexMoveActivate(EAlertCause AlertCause)
{
	local bool bResult;
	bResult = false;

	switch( AlertCause )
	{
	case eAC_TookDamage:
	case eAC_TakingFire:
	case eAC_SeesSpottedUnit:
		bResult = true;
		break;
	}

	return bResult;
}

function MarkCorpseSeen(int iCorpseID)
{
	if (m_arrCorpsesSeen.Find(iCorpseID) == -1)
	{
		m_arrCorpsesSeen.AddItem(iCorpseID);
	}
}

function bool HasSeenCorpse( int iCorpseID )
{
	return m_arrCorpsesSeen.Find(iCorpseID) != -1;
}


// For debugging
function Update()
{
	local XComWorldData World;
	local AlertData TestAlertData;
	local vector AlertLocation;
	local LinearColor SphereColor;
	local XComGameStateHistory History;
	local XComGameState_AIUnitData AIUnit;
	local float ZFloor;

	if (bDoDebug)
	{
		World = `XWORLD;
		History = `XCOMHISTORY;

		// Get the latest GameState
		AIUnit = XComGameState_AIUnitData(History.GetGameStateForObjectID(ObjectID));

		foreach AIUnit.m_arrAlertData(TestAlertData)
		{
			AlertLocation = World.GetPositionFromTileCoordinates(TestAlertData.AlertLocation);
			ZFloor = World.GetFloorZForPosition(AlertLocation);
			AlertLocation.Z = ZFloor;

			switch( TestAlertData.AlertKnowledgeType )
			{
			case eAKT_Absolute:
				SphereColor = MakeLinearColor(0.0f, 0.0f, 1.0f, 1.0f);
				break;
			case eAKT_FormerAbsolute:
				SphereColor = MakeLinearColor(0.0f, 1.0f, 0.0f, 1.0f);
				break;
			default:
				SphereColor = MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f);
				break;
			}

			`SHAPEMGR.DrawSphere(AlertLocation, vect(10,10,10), SphereColor, false);
		}

		bDoDebug = false;
		AIUnit.bDoDebug = true;
		`CHEATMGR.Outer.SetTimer(0.1f, false, 'Update', AIUnit);
	}
}
// For debugging

defaultproperties
{
	bTacticalTransient=true

	// For debugging
	bDoDebug = false

	JobIndex = INDEX_NONE
	JobOrderPlacementNumber = INDEX_NONE

	RedAlertCause=eAC_None;
	YellowAlertCause=eAC_None;
	iRedAlertTurn = INDEX_NONE;
}
