//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGAIPatrolGroup.uc    
//  AUTHOR:  Alex Cheng  --  11/6/2013
//  PURPOSE: XGAIPatrolGroup:   Alien Pod with tabs on prev and next nodes to path to.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XGAIPatrolGroup extends XGAIGroup
	native(AI);

var	  array<vector> m_arrNextDest; // Immediate destination list, rebuilt every turn.
var	  array<vector> m_arrActualDest;
var   TTile m_kRegroupDest; // Central location to have units regroup at before resuming green alert movement.
var	  bool m_bRegrouping;

var	  bool m_bRebuildDestinations; // Set on turn init, and after these destinations have been moved to.
var   vector m_vCurrNode; // Location of next centralized group destination.  (may be offset from actual node due to interference.)

var	  array<int> m_arrUnitsToMove;
var	  array<TTile> m_arrGroupPath; // the path that the group leader will take

var bool bDisableGroupMove;
//------------------------------------------------------------------------------------------------
event NativeInit()
{
	SetTickIsDisabled(false);// debug only
}

function Init(array<int> arrObjIDs, float InInfluenceRange, bool bRefresh=false )
{
	BaseInit(arrObjIDs, bRefresh);
	NativeInit();
	InfluenceRange = InInfluenceRange;
}

event InitializePostSpawn(XComGameState NewGameState, bool bRefresh=false)
{
	Super.InitializePostSpawn( NewGameState, bRefresh );

	if (m_kPlayer != None && m_kPlayer.m_kNav.m_arrPatrolGroups.Find(self) == -1)
	{
		m_kPlayer.m_kNav.m_arrPatrolGroups.AddItem(self);
	}
}

//------------------------------------------------------------------------------------------------
function InitTurn()
{
	super.InitTurn();
	m_bRebuildDestinations=true;
	UpdateRegroup();
	m_arrGroupPath.Length = 0;
	bDisableGroupMove = false;
}

//------------------------------------------------------------------------------------------------
function UpdateRegroup()
{
	local XComGameState_Unit kUnitState;
	local int iObjID, iIdx, iMaxTileRadius;
	local TTile kDest;
	local vector vLoc;
	iIdx = 0;
	if (m_arrLastAlertLevel.Length == m_arrUnitIDs.Length)
	{
		// Check alert levels if it is time to start regrouping.
		if (!m_bRegrouping)
		{
			foreach m_arrUnitIDs(iObjID)
			{
				kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iObjID));	
				if (kUnitState.GetCurrentStat(eStat_AlertLevel) == 0 && m_arrLastAlertLevel[iIdx] == 2)
				{
					m_bRegrouping = true;
				}
				kDest.X += kUnitState.TileLocation.X;
				kDest.Y += kUnitState.TileLocation.Y;
				kDest.Z += kUnitState.TileLocation.Z;
			}
			if (m_bRegrouping)
			{
				kDest.X /= m_arrUnitIDs.Length;
				kDest.Y /= m_arrUnitIDs.Length;
				kDest.Z /= m_arrUnitIDs.Length;
				vLoc = `XWORLD.GetPositionFromTileCoordinates(kDest);
				vLoc = XComTacticalGRI(WorldInfo.GRI).GetClosestValidLocation(vLoc, None, false, false, true);
				m_kRegroupDest = `XWORLD.GetTileCoordinatesFromPosition(vLoc);
				`LogAI("Patrol Group began regrouping at central tile:("$m_kRegroupDest.X$","$m_kRegroupDest.Y$","$m_kRegroupDest.Z$")"@`ShowVar(vLoc));
			}
		}
		else
		{
			// Regrouping is done when all units are within a 3 tile radius of regroup location.
			foreach m_arrUnitIDs(iObjID)
			{
				kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iObjID));
				iMaxTileRadius = Max( iMaxTileRadius, abs(m_kRegroupDest.X-kUnitState.TileLocation.X) );
				iMaxTileRadius = Max( iMaxTileRadius, abs(m_kRegroupDest.Y-kUnitState.TileLocation.Y) );
				iMaxTileRadius = Max( iMaxTileRadius, abs(m_kRegroupDest.Z-kUnitState.TileLocation.Z) );
				if (iMaxTileRadius > 3)
				{
					break;
				}
			}
			if (iMaxTileRadius <= 3)
			{
				m_bRegrouping = false;
				`LogAI("Patrol Group finished regrouping!  Continuing to patrol.");
			}
		}
	}
	else
	{
		UpdateLastAlertLevel();
	}

}
//------------------------------------------------------------------------------------------------
// Attempt to override the current patrol path with any Throttling Beacons or Mapwide Alert locations.
function bool CheckForOverrideDestination(out vector CurrDestination, int ObjectID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_AIUnitData AIData;
	local int AIDataID;
	local AlertData AlertData;
	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
	AIDataID = Unit.GetAIUnitDataID();
	if( AIDataID > 0 )
	{
		AIData = XComGameState_AIUnitData(History.GetGameStateForObjectID(AIDataID));
		if( AIData.GetPriorityAlertData(AlertData) )
		{
			if( AlertData.AlertCause == eAC_ThrottlingBeacon ||
				AlertData.AlertCause == eAC_MapwideAlert_Hostile ||
				AlertData.AlertCause == eAC_MapwideAlert_Peaceful)
			{
				CurrDestination = `XWORLD.GetPositionFromTileCoordinates(AlertData.AlertLocation);
				return true;
			}
		}
	}
	return false;
}
//------------------------------------------------------------------------------------------------
function vector GetNextDestination( XGUnit kUnit )
{
	local vector vLoc;
	vLoc = kUnit.Location;
	if (CheckForOverrideDestination(m_vCurrNode, kUnit.ObjectID))
	{
		if( !kUnit.m_kBehavior.HasValidDestinationToward(m_vCurrNode, vLoc) )
		{
			vLoc = m_vCurrNode;
		}
		vLoc = ValidateDestination(vLoc, kUnit);
	}
	return vLoc;
}
//------------------------------------------------------------------------------------------------
function SetNextActualDest( vector vDest )
{
	m_arrActualDest.AddItem(vDest);
	if (m_arrActualDest.Length >= m_arrNextDest.Length)
	{
		m_bRebuildDestinations = true;
	}
}
native function float GetSpawnWeightForDistance(float Distance);

//------------------------------------------------------------------------------------------------
function vector ValidateDestination(vector vDestination, XGUnit kUnit)
{
	// To do: return alternate location that have been taken by other units.
	return vDestination;
}
//------------------------------------------------------------------------------------------------
 //Kick off all units in the group moving to the next location.
function InitPatrolMovement()
{
	local XGUnit kUnit;
	local vector vInitialDest, vDestination, vLoc;
	local bool bFirst;
	local TTile kInitialTileDest, kTileDest, kOldLoc, kTileDir;
	if (m_bRebuildDestinations)
	{
		RefreshMembers();
		UnblockMemberTiles(); // Fixes a possible redscreen where a patrolling leader is blocked from moving
							  //  from being surrounded by the other members of the group and the world.
		m_arrNextDest.Length = 0;
		m_arrActualDest.Length = 0;

		bFirst=true;
		foreach m_arrMember(kUnit)
		{
			// Pathing
			if (bFirst)
			{
				kUnit.m_kReachableTilesCache.UpdateTileCacheIfNeeded();
				vInitialDest = GetNextDestination(kUnit);
				vLoc = kUnit.GetGameStateLocation();
				kOldLoc = `XWORLD.GetTileCoordinatesFromPosition(vLoc);
				kInitialTileDest = `XWORLD.GetTileCoordinatesFromPosition(vInitialDest);
				kTileDir.X = kInitialTileDest.X - kOldLoc.X;
				kTileDir.Y = kInitialTileDest.Y - kOldLoc.Y;
				if (kTileDir.X == 0 && kTileDir.Y == 0)
				{
					kTileDir.X = 1; // Ensure the units end up spaced apart.
				}
				kTileDir.Z = 0;
				if (Abs(kTileDir.X) > Abs(kTileDir.Y))
				{
					kTileDir.X = (kTileDir.X > 0) ? 1 : -1;
					kTileDir.Y = 0;
				}
				else
				{
					kTileDir.Y = (kTileDir.Y > 0) ? 1 : -1;
					kTileDir.X = 0;
				}

				vDestination = vInitialDest;
				bFirst = false;
			}
			else // Everyone else just picks the closest location to here to path to.
			{
				kTileDest.X = kInitialTileDest.X - kTileDir.X;
				kTileDest.Y = kInitialTileDest.Y - kTileDir.Y;
				kTileDest.Z = kInitialTileDest.Z;

				vDestination = `XWORLD.GetPositionFromTileCoordinates(kTileDest);
				kInitialTileDest = kTileDest;
			}
			m_arrNextDest.AddItem(vDestination);
		}
		m_bRebuildDestinations = false;
	}
}
//------------------------------------------------------------------------------------------------
function bool GetPatrolDestination(int iUnitID, out vector vDest )
{
	local int iIndex;
	iIndex = m_arrUnitIDs.Find(iUnitID);
	if (m_bRegrouping)
	{
		vDest = `XWORLD.GetPositionFromTileCoordinates(m_kRegroupDest);
		return true;
	}
	if (iIndex >= 0 && iIndex < m_arrNextDest.Length)
	{
		vDest = m_arrNextDest[iIndex];
		return true;
	}
	return false;
}
//------------------------------------------------------------------------------------------------
simulated function OnMoveFailure(int UnitID, string strFail="", bool bSkipOnMoveFailureAction=false)
{
	if (!bSkipOnMoveFailureAction)
	{
		`LogAI("Move failure due to: "@strFail);
	}
	// Re-block tiles if we initialized the group to unblock tiles.
	BlockMemberTiles();
}
//------------------------------------------------------------------------------------------------
event Tick( float fDeltaT )
{
	local int i;
	local SimpleShapeManager ShapeManager;
	local XComTacticalCheatManager CheatManager;

	CheatManager = `CHEATMGR;

	// don't draw debug info for this group at all if displaying detailed debugging and this is not the specific target
	if (CheatManager != None && 
		(CheatManager.DebugSpawnIndex < 0 || bDetailedDebugging) && 
		CheatManager.bDebugPatrols )
	{
		ShapeManager = `SHAPEMGR;
		ShapeManager.DrawSphere( m_vCurrNode, vect(5,5,64), MakeLinearColor(0,1,0,1));

		// Draw intermediate destinations.
		if (m_arrNextDest.Length == m_arrMember.Length)
		{
			for (i=0; i<m_arrMember.Length; i++)
			{				
				DrawDebugLine(m_arrMember[i].Location, m_arrNextDest[i], 255,200,0, false);
				ShapeManager.DrawSphere( m_arrNextDest[i], vect(5,5,32), MakeLinearColor(1,1,0,1));
			}
		}
	}
}

function bool HasUnitsWaitingToMove( out array<int> arrObjIDs )
{
	if (m_arrUnitsToMove.Length > 0)
	{
		arrObjIDs = m_arrUnitsToMove;
		return true;
	}
	return super.HasUnitsWaitingToMove(arrObjIDs);
}

function OnMoveBeginState( int iObjID )
{
	local int i;
	if (m_arrUnitsToMove.Length == 0)
	{
		m_arrUnitsToMove = m_arrUnitIDs;

		// This is only for green units.
		for (i= m_arrUnitsToMove.Length-1; i >= 0; --i)
		{
			if (GetLastAlertLevel(m_arrUnitsToMove[i]) != 0)
			{
				m_arrUnitsToMove.Remove(i, 1);
			}
		}
	}
}

function OnMoveEndState( int iObjID )
{
	m_arrUnitsToMove.RemoveItem(iObjID);

	// Update fallback status post move.
	UpdateFallbackStatus();
}

private function ComputeGroupPath(vector GroupDestination)
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local XGUnit Visualizer;
	local TTile TileDest;

	if(m_arrGroupPath.Length > 0)
	{
		return; // already computed
	}

	// get the patrol leader visualizer
	History = `XCOMHISTORY;
	Visualizer = XGUnit(History.GetVisualizer(m_arrUnitIDs[0]));
	if(Visualizer == none) return; // couldn't find the group leader

	// and attempt to have him build a path to the destination
	WorldData = `XWORLD;
	if(!WorldData.GetFloorTileForPosition(GroupDestination, TileDest))
	{
		TileDest = WorldData.GetTileCoordinatesFromPosition(GroupDestination);
	}
	if( !Visualizer.m_kReachableTilesCache.BuildPathToTile(TileDest, m_arrGroupPath) )
	{
		TileDest = Visualizer.m_kReachableTilesCache.GetClosestReachableDestination(TileDest);
		if( !Visualizer.m_kReachableTilesCache.BuildPathToTile(TileDest, m_arrGroupPath) )
		{
			`RedScreen("Unable to build a path to destination - XGAIPatrolGroup::ComputeGroupPath  @ACHENG");
		}
	}
}

// finds the ideal destination of the given follower unit
private function TTile GetIdealFollowerDestinationTile(XComGameState_Unit Unit, int UnitIndex)
{
	local XComWorldData WorldData;
	local TTile PathTile0;
	local TTile PathTile1;
	local vector PathStartVector;
	local vector PathStartRightVector;
	local vector UnitLocation;
	local float UnitDotPathStart;

	local TTile PathEndTile;
	local TTile PathOneFromEndTile;
	local vector PathEndVector;
	local vector UnitPlacementVector;
	local int TilesBack; // how many tiles behind the leader should we try for?

	//Check whether there is a valid path. If not, just return our starting tile
	if(m_arrGroupPath.Length < 2)
	{
		return Unit.TileLocation;
	}
	

	WorldData = `XWORLD;

	// figure out which side of the pathing line we are currently standing on. We'll try to have this unit
	// end up on the same side, since it looks strange and unnatural to have the units just crossing over
	// the main path line for no reason. This will also leave them in relatively the same positions relative 
	// to the leader at the end of the move.
	PathTile0 = m_arrGroupPath[0];
	PathTile1 = m_arrGroupPath[1];
	PathStartVector = WorldData.GetPositionFromTileCoordinates(PathTile1) - WorldData.GetPositionFromTileCoordinates(PathTile0);
	PathStartRightVector = PathStartVector cross vect(0,0,1);
	UnitLocation = WorldData.GetPositionFromTileCoordinates(Unit.TileLocation);
	UnitDotPathStart = PathStartRightVector dot (UnitLocation - WorldData.GetPositionFromTileCoordinates(PathTile0));

	// now decide how many tiles behind the leader this unit should go
	TilesBack = (UnitIndex - 1) / 2 + 1; // first two followers go one tile behind, next two go two tiles behind, etc.
	
	// now find our ideal destination tile. Fan out behind the leading unit using the parameters we just computed
	PathEndTile = m_arrGroupPath[m_arrGroupPath.Length - 1];
	PathOneFromEndTile = m_arrGroupPath[m_arrGroupPath.Length - 2];
	PathEndVector = WorldData.GetPositionFromTileCoordinates(PathEndTile) - WorldData.GetPositionFromTileCoordinates(PathOneFromEndTile);
	PathEndVector = Normal(PathEndVector);

	// get the offset from the end of the path to the side
	UnitPlacementVector = (PathEndVector cross vect(0,0,1)) * class'XComWorldData'.const.WORLD_StepSize * (UnitDotPathStart > 0 ? 1.0f : -1.0f);

	// slide it back
	UnitPlacementVector -= PathEndVector * (TilesBack * class'XComWorldData'.const.WORLD_StepSize);

	// scale it up a bit to add a bit of extra potential buffer from the lead unit. Because this get quantized to a tile,
	// it may or may not be enough to push us into the next tile. Which adds variety and visual interest.
	UnitPlacementVector *= 1.2f;

	// and offset it to the end of the path
	UnitPlacementVector += WorldData.GetPositionFromTileCoordinates(PathEndTile);

	// now figure out which tile that places us in
	return WorldData.GetTileCoordinatesFromPosition(UnitPlacementVector);
}

//Returns TRUE if the GroupPaths array will be filled out and a group move shouild be submitted
function bool GetGroupMovePaths(vector GroupDestination, out array<PathingInputData> GroupPaths, XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local X2TacticalGameRuleset TacticalRules;
	local XGUnit UnitVisualizer;
	local TTile IdealTileDest, TileDest;
	local int UnitGroupIndex;
	local PathingInputData InputData;
	local bool bPerformGroupMove;
	local int GroupProcessIndex;
	local XComGameState_Unit GroupMovingUnit;	
	local GameRulesCache_Unit UnitActionsCache;
	local AvailableAction kAction;
	local name AbilityName;
	local bool bMoveActionAvailable;
	local array<TTile> ExclusionTiles;
	local vector vDest;

	bPerformGroupMove = m_arrGroupPath.Length == 0; //If FALSE, this group has already moved
	if(bPerformGroupMove)
	{
		History = `XCOMHISTORY;
		TacticalRules = `TACTICALRULES;

		// find out location in the group
		UnitGroupIndex = m_arrUnitIDs.Find(UnitState.ObjectID);
		if(UnitGroupIndex == INDEX_NONE) return false; // not a member of this group!		

		// always start by making sure the group path has been built
		ComputeGroupPath(GroupDestination);

		//Only proceed if a valid move was possible
		if(m_arrGroupPath.Length > 0)
		{
			//Setup the leader's input data
			InputData.MovingUnitRef = UnitState.GetReference();
			InputData.MovementTiles = m_arrGroupPath;

			// Add the leader's path
			GroupPaths.AddItem(InputData);

			// add the leader's destination so the follower's don't end up on it
			ExclusionTiles.AddItem(m_arrGroupPath[m_arrGroupPath.Length - 1]);

			//Here, we make the assumption that group moving units follow the leader and will choose "group move" in their behavior tree if the
			//ability is available
			for(GroupProcessIndex = 0; GroupProcessIndex < m_arrUnitIDs.Length; ++GroupProcessIndex)
			{
				if(UnitGroupIndex == GroupProcessIndex)
				{
					continue; //Already processed the leader
				}

				GroupMovingUnit = XComGameState_Unit(History.GetGameStateForObjectID(m_arrUnitIDs[GroupProcessIndex]));
				if(GroupMovingUnit == none)
				{
					continue; //Filter out invalid or unexpected errors in the game state or visualizers
				}

				UnitVisualizer = XGUnit(GroupMovingUnit.GetVisualizer());
				if(UnitVisualizer == none || UnitVisualizer.m_kBehavior == none)
				{
					continue; //Filter out invalid or unexpected errors in the game state or visualizers
				}

				//Setup the follower's input data
				InputData.MovingUnitRef = GroupMovingUnit.GetReference();

				//Now see if this unit can move - if so, set up their path
				if(TacticalRules.GetGameRulesCache_Unit(InputData.MovingUnitRef, UnitActionsCache))
				{
					foreach UnitActionsCache.AvailableActions(kAction)
					{
						AbilityName = XComGameState_Ability(History.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID)).GetMyTemplateName();
						if(AbilityName == 'StandardMove')
						{
							bMoveActionAvailable = kAction.AvailableCode == 'AA_Success';
							break;
						}
					}
				}

				if(bMoveActionAvailable)
				{
					// We have a valid follower: 
					// for the followers, compute a location in formation behind the leader and have them path there
					IdealTileDest = GetIdealFollowerDestinationTile(GroupMovingUnit, GroupProcessIndex);
					TileDest = UnitVisualizer.m_kReachableTilesCache.GetClosestReachableDestination(IdealTileDest, ExclusionTiles);
					InputData.MovementTiles.Length = 0; //This input structure is being reused, reset the movement tiles length
					// Get closest can fail if the unit is in a bad tile.
					if( !UnitVisualizer.m_kReachableTilesCache.IsTileReachable(TileDest) )
					{
						`RedScreen(`Location@"\nUnit cannot reach 'closest reachable tile' - likely unit is stuck in an unpathable location! \nUnit #"$UnitVisualizer.ObjectID@GroupMovingUnit.GetMyTemplateName()$" \n@Tile ("$GroupMovingUnit.TileLocation.X@GroupMovingUnit.TileLocation.Y@GroupMovingUnit.TileLocation.Z$")\n @raasland or @dburchanowski or @acheng\n\n");
					}
					else
					{
						if( !UnitVisualizer.m_kReachableTilesCache.BuildPathToTile(TileDest, InputData.MovementTiles) )
						{
							`RedScreen(GetFuncName()@UnitVisualizer@"(ID#"$UnitVisualizer.ObjectID$") is unable to build a path to a 'reachable tile' ("$TileDest.X@TileDest.Y@TileDest.Z$").  @Burch");
						}
					}

					// Handle pathing failures.  Force the path with only the unit start and end points, or skip movement if that end tile is occupied.
					if( InputData.MovementTiles.Length < 2 )
					{
						// 'IdealTileDest' may be an occupied/invalid tile. Ensure it is valid before using it.
						vDest = `XWORLD.GetPositionFromTileCoordinates(IdealTileDest);
						vDest = XComTacticalGRI(WorldInfo.GRI).GetClosestValidLocation(vDest, UnitVisualizer, false, false, true);
						IdealTileDest = `XWORLD.GetTileCoordinatesFromPosition(vDest);
						if (GroupMovingUnit.TileLocation == IdealTileDest)
						{
							`LogAI("Unit is already at closest valid tile to ideal tile, so skipping movement.  Not adding to group move.");
							continue;
						}

						if( class'Helpers'.static.FindTileInList(IdealTileDest, ExclusionTiles) == INDEX_NONE )
						{
							`LogAI("Invalid movement path.  Forcing a fake path with unit start location and ideal tile destination.");
							InputData.MovementTiles[0] = GroupMovingUnit.TileLocation;
							InputData.MovementTiles[1] = IdealTileDest;
						}
						else if( class'Helpers'.static.FindTileInList(GroupMovingUnit.TileLocation, ExclusionTiles) == INDEX_NONE )
						{
							// Skip movement if the unit's current tile location is available.
							`LogAI("Invalid movement path.  Target destination is occupied, so skipping movement..  Not adding to group move.");
							continue;
						}
						else
						{
							`RedScreen("Error - Group Move failure, potential for multiple units in one tile.  No path found to ideal destination, and current tile is being moved into.  @acheng");
						}
					}

					if( InputData.MovementTiles.Length > 0 )
					{
						ExclusionTiles.AddItem(InputData.MovementTiles[InputData.MovementTiles.Length - 1]);
					}
					// Add the follower's path
					GroupPaths.AddItem(InputData);
				}
			}
		}
		else
		{
			`redscreenonce("Could not find a valid group move path for unit:"@UnitState.ObjectID);
		}
	}

	return bPerformGroupMove;
}

function bool HasOverrideAction(out Name OverrideActionName, int ObjectID)
{
	local XGAIBehavior LeaderBehavior;
	local string LeaderActionName;
	local int LeaderID;

	LeaderID = m_arrUnitIDs[0];
	if( LeaderID == ObjectID || bDisableGroupMove )
		return false;

	// On green alert, mimic leader movement to ensure the group stays together.
	if( GetLastAlertLevel( LeaderID ) == `ALERT_LEVEL_GREEN || bStartedUnrevealed)
	{
		LeaderBehavior = m_arrMember[0].m_kBehavior;
		LeaderActionName = LeaderBehavior.BT_GetLastAbilityName();
		if( LeaderActionName == "StandardMove" )
		{
			OverrideActionName = Name(LeaderActionName);
		}
		else
		{
			OverrideActionName = 'SkipMove';
		}
		return true;
	}

	return false;
}

//------------------------------------------------------------------------------------------------`
defaultproperties
{
}
