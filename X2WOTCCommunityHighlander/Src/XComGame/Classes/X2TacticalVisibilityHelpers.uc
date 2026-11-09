//---------------------------------------------------------------------------------------
//  FILE:    X2TacticalHelpers.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: Container class that holds methods specific to tactical that help filter / 
//           serve queries for tactical mechanics.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TacticalVisibilityHelpers extends object native(Core);

var X2Condition_Visibility GameplayVisibilityCondition;
var X2Condition_Visibility BasicVisibilityCondition;
var X2Condition_Visibility LOSVisibilityCondition;
var X2Condition_HackingTarget HackableObjectCondition;
var X2Condition_HackingTarget HackableObjectIntrusionProtocolCondition;
var X2Condition_UnitProperty AliveUnitPropertyCondition;

var array<X2Condition> LivingGameplayVisibleFilter;
var array<X2Condition> LivingBasicVisibleFilter;
var array<X2Condition> GameplayVisibleFilter;
var array<X2Condition> LivingLOSVisibleFilter; // For Yellow alert AI checks
var array<X2Condition> BasicVisibleFilter; // Allows dead units, basic visibility.   Used for red alert / spotted units, to check against fatal damage taken.

simulated static function X2GameRulesetVisibilityManager GetVisibilityMgr()
{
	return `TACTICALRULES.VisibilityMgr;
}

/// <summary>
/// Given a team enum, return a state object reference to the corresponding player state object
/// </summary>
simulated static function StateObjectReference GetPlayerFromTeamEnum(ETeam PlayerTeam)
{
	local StateObjectReference PlayerStateObjectRef;
	local XComGameState_Player PlayerStateObject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Player', PlayerStateObject)
	{
		if( PlayerStateObject.TeamFlag == PlayerTeam )
		{
			PlayerStateObjectRef = PlayerStateObject.GetReference();
			break;
		}
	}

	return PlayerStateObjectRef;
}

simulated static function bool CanSquadSeeLocation(int PlayerStateObjectID, const out TTile TestLocation, optional array<X2Condition> RequiredConditions)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<GameRulesCache_VisibilityInfo> VisInfos;
	local int Idx;

	History = `XCOMHISTORY;

	if (RequiredConditions.Length == 0)
	{
		RequiredConditions.AddItem(default.AliveUnitPropertyCondition);
	}

	GetVisibilityMgr().GetAllViewersOfLocation(TestLocation, VisInfos, class'XComGameState_Unit',, RequiredConditions);

	for (Idx = 0; Idx < VisInfos.Length; ++Idx)
	{
		if (VisInfos[Idx].bVisibleBasic)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(VisInfos[Idx].SourceID));
			if (UnitState != none && UnitState.ControllingPlayer.ObjectID == PlayerStateObjectID)
				return true;
		}		
	}
	return false;
}

simulated static function bool CanXComSquadSeeTarget(int TargetStateObjectID, optional array<X2Condition> RequiredConditions)
{
	local StateObjectReference PlayerStateRef;

	PlayerStateRef = GetPlayerFromTeamEnum(eTeam_XCom);

	return CanSquadSeeTarget(PlayerStateRef.ObjectID, TargetStateObjectID, RequiredConditions);
}

simulated static function bool CanSquadSeeTarget(int PlayerStateObjectID, int TargetStateObjectID, optional array<X2Condition> RequiredConditions)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<StateObjectReference> ViewersOfTarget;
	local StateObjectReference ViewerOfTarget;

	History = `XCOMHISTORY;

	if (RequiredConditions.Length == 0)
	{
		RequiredConditions.AddItem(default.AliveUnitPropertyCondition);
		RequiredConditions.AddItem(default.GameplayVisibilityCondition);
	}

	GetVisibilityMgr().GetAllViewersOfTarget(TargetStateObjectID, ViewersOfTarget, class'XComGameState_Unit',, RequiredConditions);

	foreach ViewersOfTarget(ViewerOfTarget)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ViewerOfTarget.ObjectID));
		if (UnitState != none && UnitState.ControllingPlayer.ObjectID == PlayerStateObjectID)
			return true;
	}
	return false;
}

simulated static function bool CanUnitSeeLocation(int UnitID, const out TTile TestLocation, optional array<X2Condition> RequiredConditions)
{
	local XComGameState_Unit ViewingUnit;
	local GameRulesCache_VisibilityInfo OutVisInfo;
	local int SightRadiusUnitsSq;
	local bool bIsInSightRadius;
	local XComGameStateHistory History;

	local array<GameRulesCache_VisibilityInfo> OutSquadsightVisInfos;
	local int Idx;
	local XComGameState_Unit OtherUnit;

	History = `XCOMHISTORY;
	ViewingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));

	if( ViewingUnit.IsAlive() ) //Need to be alive to see...
	{
		`XWORLD.CanSeeTileToTile(ViewingUnit.TileLocation, TestLocation, OutVisInfo);

		SightRadiusUnitsSq = `METERSTOUNITS(ViewingUnit.GetVisibilityRadius());
		SightRadiusUnitsSq = SightRadiusUnitsSq * SightRadiusUnitsSq;
		bIsInSightRadius = SightRadiusUnitsSq >= OutVisInfo.DefaultTargetDist;
		if( bIsInSightRadius )
		{
			return true;
		}

		//Here we do the very expensive check for squad sight. This grants sight of the location if A. the unit has LOS and B. any other
		//unit on the team can see the location
		if( OutVisInfo.bClearLOS && ViewingUnit.HasSquadsight() )
		{
			//See whether any other member of Unit's team can see the location
			GetVisibilityMgr().GetAllViewersOfLocation(TestLocation, OutSquadsightVisInfos, class'XComGameState_Unit');
			for (Idx = 0; Idx < OutSquadsightVisInfos.Length; ++Idx)
			{
				if (OutSquadsightVisInfos[Idx].SourceID != UnitID && OutSquadsightVisInfos[Idx].bVisibleBasic)
				{
					OtherUnit = XComGameState_Unit(History.GetGameStateForObjectID(OutSquadsightVisInfos[Idx].SourceID));
					if (OtherUnit.ControllingPlayer.ObjectID == ViewingUnit.ControllingPlayer.ObjectID)
					{
						return true;
					}
				}		
			}
		}
	}

	return false;
}

/// <summary>
/// Returns an out param, VisibleUnits, containing all the units (and, optionally, destructibles) that a given player can see
/// </summary>
simulated static function GetAllVisibleObjectsForPlayer(int PlayerStateObjectID, 
													  out array<StateObjectReference> VisibleUnits,
													  optional array<X2Condition> RequiredConditions,
													  int HistoryIndex = -1,
													  bool IncludeNonUnits = false)
{
	local XComGameState_Unit kUnit;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	//Set default conditions (visible units need to be alive and game play visible) if no conditions were specified
	if( RequiredConditions.Length == 0 )
	{
		RequiredConditions = default.LivingGameplayVisibleFilter;
	}

	foreach History.IterateByClassType(class'XComGameState_Unit', kUnit, eReturnType_Reference, , HistoryIndex)
	{
		if( kUnit.ControllingPlayer.ObjectID == PlayerStateObjectID )
		{
			VisibilityMgr.GetAllVisibleToSource(kUnit.ObjectID, VisibleUnits, IncludeNonUnits?class'XComGameState_BaseObject':class'XComGameState_Unit', HistoryIndex, RequiredConditions);
		}
	}
}

/// <summary>
/// Given a target ID and a player ID, return TRUE / FALSE whether the target is visible to that player
/// </summary>
simulated static function bool GetTargetIDVisibleForPlayer(int TargetStateObjectID, 
														   int PlayerStateObjectID,
														   optional array<X2Condition> RequiredConditions)
{
	local int Index;
	local array<StateObjectReference> OutVisibleToSource;
	
	GetAllVisibleObjectsForPlayer(PlayerStateObjectID, OutVisibleToSource, RequiredConditions);

	for( Index = 0; Index < OutVisibleToSource.Length; ++Index )
	{
		if( OutVisibleToSource[Index].ObjectID == TargetStateObjectID )
		{
			return true;
		}
	}

	return false;
}

/// <summary>
/// Given a viewer ID, and a team, return a list of visible targets that are on the specified team
/// </summary>
simulated static function GetAllVisibleUnitsOnTeamForSource(int SourceStateObjectID, ETeam Team,
															out array<StateObjectReference> VisibleToSource,
															optional array<X2Condition> RequiredConditions)
{
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local XComGameState_unit    UnitState;
	local XComGameState_Player  UnitControllingPlayerState;
	local array<StateObjectReference> AllVisible;
	local StateObjectReference UnitRef;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	//Set default conditions (visible units need to be alive and game play visible) if no conditions were specified
	if( RequiredConditions.Length == 0 )
	{
		RequiredConditions = default.LivingGameplayVisibleFilter;
	}

	VisibilityMgr.GetAllVisibleToSource(SourceStateObjectID, AllVisible, class'XComGameState_Unit', -1, RequiredConditions);

	//Iterate the output list, adding units that are on the specified team.
	foreach AllVisible( UnitRef )
	{
		if( VisibleToSource.Find('ObjectID', UnitRef.ObjectID) == INDEX_NONE ) // Skip if already on the list.
		{
			UnitState = XComGameState_unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			`assert(UnitState != none);

			UnitControllingPlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
			`assert(UnitControllingPlayerState != none);

			if( UnitControllingPlayerState.TeamFlag == Team )
			{
				VisibleToSource.AddItem(UnitRef);
			}
		}
	}
}


/// <summary>
/// Returns an out param, VisibleUnits, containing all the enemy units (and, optionally, destructibles) that a given player can see
/// </summary>
static event GetAllVisibleEnemiesForPlayer(int PlayerStateObjectID, 
														out array<StateObjectReference> VisibleUnits,
														int HistoryIndex = -1,
														bool IncludeNonUnits = false)
{
	local int Index;
	local XComGameState_Unit PlayerUnit;
	local XComGameStateHistory History;	

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', PlayerUnit, , , HistoryIndex)
	{
		if( PlayerUnit.ControllingPlayer.ObjectID == PlayerStateObjectID )
		{
			break;
		}
	}

	//The player must have at least one unit to see enemies
	if( PlayerUnit != none )
	{
		GetAllVisibleObjectsForPlayer(PlayerStateObjectID, VisibleUnits, , HistoryIndex, IncludeNonUnits);

		for( Index = VisibleUnits.Length - 1; Index > -1; --Index )
		{
			//Remove non-enemies from the list
			if(!PlayerUnit.TargetIsEnemy(VisibleUnits[Index].ObjectID, HistoryIndex))
			{
				VisibleUnits.Remove(Index, 1);
			}
		}
	}
}

/// <summary>
/// Returns an out param, VisibleUnits, containing all the enemy units that a given unit can see.
/// </summary>
simulated static function GetAllVisibleEnemyUnitsForUnit(int SourceStateObjectID, 
													  out array<StateObjectReference> VisibleUnits,
													  optional array<X2Condition> RequiredConditions,
													  int HistoryIndex = -1)
{
	local int Index;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;	
	local XComGameState_unit SourceState;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	SourceState = XComGameState_Unit(History.GetGameStateForObjectID(SourceStateObjectID, , HistoryIndex));

	//Set default conditions (visible units need to be alive and game play visible) if no conditions were specified
	if( RequiredConditions.Length == 0 )
	{
		RequiredConditions = default.LivingGameplayVisibleFilter;
	}

	VisibilityMgr.GetAllVisibleToSource(SourceStateObjectID, VisibleUnits, class'XComGameState_Unit', HistoryIndex, RequiredConditions);

	for( Index = VisibleUnits.Length - 1; Index > -1; --Index )
	{
		//Remove non-enemies from the list
		if( !SourceState.TargetIsEnemy(VisibleUnits[Index].ObjectID, HistoryIndex) )
		{
			VisibleUnits.Remove(Index, 1);
		}
	}
}

/// <summary>
/// Returns an out param, VisibleTargets, containing all the enemy targets that a given unit can see.
/// This includes all units, destructible items, etc
/// </summary>
simulated static function GetAllVisibleEnemyTargetsForUnit(int SourceStateObjectID, 
													  out array<StateObjectReference> VisibleTargets,
													  optional array<X2Condition> RequiredConditions,
													  int HistoryIndex = -1)
{
	local int Index;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;	
	local XComGameState_Unit SourceState;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	SourceState = XComGameState_Unit(History.GetGameStateForObjectID(SourceStateObjectID, , HistoryIndex));

	//Set default conditions (visible units need to be alive and game play visible) if no conditions were specified
	if( RequiredConditions.Length == 0 )
	{
		RequiredConditions = default.LivingGameplayVisibleFilter;
	}

	VisibilityMgr.GetAllVisibleToSource(SourceStateObjectID, VisibleTargets, class'XComGameState_BaseObject', HistoryIndex, RequiredConditions);

	for( Index = VisibleTargets.Length - 1; Index > -1; --Index )
	{
		//Remove non-enemies from the list
		if( !SourceState.TargetIsEnemy(VisibleTargets[Index].ObjectID, HistoryIndex) )
		{
			VisibleTargets.Remove(Index, 1);
		}
	}
}


/// <summary>
/// Returns an out param, VisibleUnits, containing all the hackable objects that a given unit can see
/// </summary>
simulated static function GetHackableObjectsInRangeOfUnit(int SourceStateObjectID, 
													  out array<StateObjectReference> VisibleUnits,
													  optional array<X2Condition> RequiredConditions,
													  int HistoryIndex = -1,
													  bool bIntrusionProtocol = false)
{
	local X2GameRulesetVisibilityManager VisibilityMgr;	

	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	//Set default conditions (visible units need to be alive and game play visible) if no conditions were specified
	if( RequiredConditions.Length == 0 )
	{
		RequiredConditions.AddItem( default.BasicVisibilityCondition );
		if( bIntrusionProtocol )
		{
			RequiredConditions.AddItem(default.HackableObjectIntrusionProtocolCondition);
		}
		else
		{
			RequiredConditions.AddItem(default.HackableObjectCondition);
		}
	}

	//HAAAAALP @dkaplan
	//DebugBreak();
	VisibilityMgr.GetAllVisibleToSource(SourceStateObjectID, VisibleUnits, class'XComGameState_InteractiveObject', HistoryIndex, RequiredConditions);
}

/// <summary>
/// Returns an out param, VisibleUnits, containing only the enemy units visible to the source through squadsight (e.g. does not include those he can see on his own)
/// </summary>
simulated static function GetAllSquadsightEnemiesForUnit(int SourceStateObjectID,
														 out array<StateObjectReference> VisibleUnits,
														 int HistoryIndex = -1,
														 bool IncludeNonUnits = false)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisMan;
	local GameRulesCache_VisibilityInfo VisInfo;
	local array<StateObjectReference> VisibleToPlayer, VisibleToUnit;
	local int i, j;
	local bool bFound;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(SourceStateObjectID, , HistoryIndex));
	if (UnitState != none)
	{
		VisMan = `TACTICALRULES.VisibilityMgr;
		GetAllVisibleEnemiesForPlayer(UnitState.ControllingPlayer.ObjectID, VisibleToPlayer, HistoryIndex, IncludeNonUnits);
		GetAllVisibleEnemyTargetsForUnit(SourceStateObjectID, VisibleToUnit,, HistoryIndex);
		for (i = 0; i < VisibleToPlayer.Length; ++i)
		{
			bFound = false;
			for (j = 0; j < VisibleToUnit.Length; ++j)
			{
				if (VisibleToUnit[j] == VisibleToPlayer[i])
				{
					bFound = true;
					break;
				}
			}
			if (!bFound)
			{
				if( VisMan.GetVisibilityInfo(SourceStateObjectID, VisibleToPlayer[i].ObjectID, VisInfo, HistoryIndex) )
				{
					if (VisInfo.bClearLOS)
						VisibleUnits.AddItem(VisibleToPlayer[i]);
				}				
			}
		}
	}
}

/// <summary>
/// Returns an out param, VisibilityInfos, containing visibility infos for each enemy unit that can see the test location. 
/// </summary>
simulated static function GetAllEnemiesForLocation(vector TestLocation, 
												   int PlayerStateObjectID,
												   out array<GameRulesCache_VisibilityInfo> VisibilityInfos,
												   bool bExcludeDead=true)
{
	local ETeam MyTeam;
	MyTeam = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(PlayerStateObjectID)).GetTeam();
	GetAllTeamUnitsForLocation(TestLocation, PlayerStateObjectID, MyTeam, VisibilityInfos, true, bExcludeDead);
}

simulated static function GetAllAlliesForLocation( vector TestLocation,
												  int PlayerStateObjectID,
												  out array<GameRulesCache_VisibilityInfo> VisibilityInfos,
												  bool bExcludeDead=true)
{
	local ETeam MyTeam;
	MyTeam = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(PlayerStateObjectID)).GetTeam();
	GetAllTeamUnitsForLocation(TestLocation, PlayerStateObjectID, MyTeam, VisibilityInfos,, bExcludeDead );
}

simulated static function GetAllTeamUnitsForLocation(vector TestLocation,
													 int PlayerStateObjectID,
													 ETeam Team,
													 out array<GameRulesCache_VisibilityInfo> VisibilityInfos,
													 bool bInvertTeam = false,  // bInvertTeam=TRUE => any units not on this team are added to array.
													 bool bExcludeDead = true)
{
	local TTile TileLocation;

	//Try to get a floor location, and if that fails just convert into a tile location
	if( !`XWORLD.GetFloorTileForPosition(TestLocation, TileLocation) )
	{
		TileLocation = `XWORLD.GetTileCoordinatesFromPosition(TestLocation);
	}

	GetAllTeamUnitsForTileLocation(TileLocation,
							   PlayerStateObjectID,
							   Team,
							   VisibilityInfos,
							   bInvertTeam,
							   bExcludeDead);
}

simulated static function GetAllTeamUnitsForTileLocation(const out TTile TileLocation,
													  int PlayerStateObjectID,
													  ETeam Team,
													  out array<GameRulesCache_VisibilityInfo> VisibilityInfos,
													  bool bInvertTeam=false,  // bInvertTeam=TRUE => any units not on this team are added to array.
													  bool bExcludeDead=true)  
{
	local int Index;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;	
	local XComGameState_Unit    UnitState;
	local XComGameState_SquadViewer SquadViewer;
	local XComGameState_Player PlayerState;
	local XComGameState_Unit    PlayerUnit;
	local XComGameState_BaseObject ViewerState;
	local bool bValidUnit;
	local bool bValidSquadViewer;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	foreach History.IterateByClassType(class'XComGameState_Unit', PlayerUnit)
	{
		if( PlayerUnit.ControllingPlayer.ObjectID == PlayerStateObjectID )
		{
			break;
		}
	}

	//The player must have at least one unit to see enemies
	if( PlayerUnit != none )
	{
		VisibilityMgr.GetAllViewersOfLocation(TileLocation, VisibilityInfos, class'XComGameState_Unit', -1);
		VisibilityMgr.GetAllViewersOfLocation(TileLocation, VisibilityInfos, class'XComGameState_SquadViewer', -1); //Add in squad viewers

		for( Index = VisibilityInfos.Length - 1; Index > -1; --Index )
		{
			if( !VisibilityInfos[Index].bVisibleGameplay )
			{
				// Remove this info because there is no Gameplay Visibility
				VisibilityInfos.Remove(Index, 1);
			}
			else
			{
				ViewerState = History.GetGameStateForObjectID(VisibilityInfos[Index].SourceID);
				`assert(ViewerState != none);
				UnitState = XComGameState_Unit(ViewerState);
				bValidUnit = UnitState != none && ((!bInvertTeam && UnitState.GetTeam() == Team) || (bInvertTeam && UnitState.GetTeam() != Team));
								
				SquadViewer = XComGameState_SquadViewer(ViewerState);
				if(SquadViewer != none)
				{
					PlayerState = XComGameState_Player(History.GetGameStateForObjectID(SquadViewer.AssociatedPlayer.ObjectID));
					bValidSquadViewer = SquadViewer != none && ((!bInvertTeam && PlayerState.GetTeam() == Team) || (bInvertTeam && PlayerState.GetTeam() != Team));
				}

				//Remove non-team viewers from the list
				if(!bValidUnit && !bValidSquadViewer)
				{
					VisibilityInfos.Remove(Index, 1);
				}
				// Remove dead if desired.
				else if(bValidUnit && bExcludeDead && !UnitState.IsAlive())
				{
					VisibilityInfos.Remove(Index, 1);
				}
			}
		}
	}
}

/// <summary>
/// Returns an out param, VisibilityInfos, containing visibility infos for each enemy unit that can see the test location AND is visible to PlayerStateObjectID. 
/// </summary>
simulated static function GetAllVisibleEnemiesForLocation(vector TestLocation, 
														  int PlayerStateObjectID,
														  out array<GameRulesCache_VisibilityInfo> VisibilityInfos,
														  bool bExcludeDead=true,
														  int HistoryIndex=-1)
{
	local int Index;
	local TTile TileLocation;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;	
	local XComGameState_Unit    UnitState;
	local XComGameState_Unit    PlayerUnit;
	local array<StateObjectReference> UnitsVisibleToPlayer;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	foreach History.IterateByClassType(class'XComGameState_Unit', PlayerUnit)
	{
		if( PlayerUnit.ControllingPlayer.ObjectID == PlayerStateObjectID )
		{
			break;
		}
	}

	//The player must have at least one unit to see enemies
	if( PlayerUnit != none )
	{
		//Try to get a floor location, and if that fails just convert into a tile location
		if( !`XWORLD.GetFloorTileForPosition(TestLocation, TileLocation) )
		{   
			TileLocation = `XWORLD.GetTileCoordinatesFromPosition(TestLocation);
		}	

		// cache all of the units that are visible to this player
		GetAllVisibleObjectsForPlayer(PlayerStateObjectID, UnitsVisibleToPlayer, , HistoryIndex);

		// grab all units that are visible to the location
		VisibilityMgr.GetAllViewersOfLocation(TileLocation, VisibilityInfos, class'XComGameState_Unit', HistoryIndex);
		
		// now remove all visibility infos that cannot see both or are not an enemy
		for( Index = VisibilityInfos.Length - 1; Index > -1; --Index )
		{
			if( VisibilityInfos[Index].bVisibleBasic ) 
			{
				UnitState = XComGameState_unit(History.GetGameStateForObjectID(VisibilityInfos[Index].SourceID,, HistoryIndex));				

				//Remove non-enemies from the list, and units that PlayerStateObjectID cannot see
				if(UnitState == none || !UnitState.TargetIsEnemy(PlayerUnit.ObjectID) || UnitsVisibleToPlayer.Find('ObjectId', UnitState.ObjectID) == INDEX_NONE)
				{
					VisibilityInfos.Remove(Index, 1);
				}
				// Remove dead if desired.
				else if (bExcludeDead && !UnitState.IsAlive( ))
				{
					VisibilityInfos.Remove( Index, 1 );
				}
			}
			else
			{
				VisibilityInfos.Remove(Index, 1);
			}
		}
	}
}

/// <summary>
/// GetEnemyViewersOfTarget returns an out param list of enemies that can see the target object specified by TargetStateObjectID
/// </summary>
simulated static function GetEnemyViewersOfTarget(int TargetStateObjectID, 
												  out array<StateObjectReference> OutEnemyViewers, 
												  optional int StartAtHistoryIndex = -1,
												  optional array<X2Condition> RequiredConditions)
{
	local int Index;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	//Set default conditions (visible units need to be alive and game play visible) if no conditions were specified
	if( RequiredConditions.Length == 0 )
	{
		RequiredConditions = default.LivingGameplayVisibleFilter;
	}

	VisibilityMgr.GetAllViewersOfTarget(TargetStateObjectID, OutEnemyViewers, class'XComGameState_Unit', StartAtHistoryIndex, RequiredConditions);

	for( Index = OutEnemyViewers.Length - 1; Index > -1; --Index )
	{
		UnitState = XComGameState_unit(History.GetGameStateForObjectID(OutEnemyViewers[Index].ObjectID,, StartAtHistoryIndex));
		`assert(UnitState != none);

		if( !UnitState.TargetIsEnemy(TargetStateObjectID, StartAtHistoryIndex) )
		{
			OutEnemyViewers.Remove(Index, 1);
		}
	}	
}

/// <summary>
/// GetNumEnemyViewersOfTarget returns the number of enemies flanking the specified TargetStateObjectID
/// </summary>
simulated static function int GetNumEnemyViewersOfTarget(int TargetStateObjectID, 
														    optional int StartAtHistoryIndex = -1)
{
	local array<StateObjectReference> OutEnemyViewers;
	GetEnemyViewersOfTarget(TargetStateObjectID, OutEnemyViewers, StartAtHistoryIndex);
	return OutEnemyViewers.Length;
}

/// <summary>
/// GetFlankingEnemiesOfTarget returns an out param list of enemies that are flanking the target ID
/// </summary>
simulated static function GetFlankingEnemiesOfTarget(int TargetStateObjectID, 
													 out array<StateObjectReference> OutFlankingEnemies, 
													 optional int StartAtHistoryIndex = -1,
													 optional array<X2Condition> RequiredConditions,
													 optional bool bAllowMeleeFlankers = false)
{
	local ETeam FlankingTeam;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetStateObjectID,,StartAtHistoryIndex));

	if (UnitState != none) // unit may not exist at that history index (psizombies, robots, etc)
	{
		FlankingTeam = UnitState.GetTeam();
		GetFlankersOfTarget( TargetStateObjectID, FlankingTeam, OutFlankingEnemies, StartAtHistoryIndex, RequiredConditions, true, bAllowMeleeFlankers);
	}
}

simulated static function GetFlankersOfTarget(int TargetStateObjectID, 
											  ETeam FlankingTeam,
											  out array<StateObjectReference> OutFlankingEnemies, 
											  optional int StartAtHistoryIndex = -1,
											  optional array<X2Condition> RequiredConditions,
											  optional bool bInvertTeam,
											  optional bool bAllowMeleeFlankers = false)
{
	local int Index;
	local XComGameState_Unit TargetState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;
	local bool bIsEnemyTeam;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(TargetStateObjectID,, StartAtHistoryIndex));
	if( TargetState != None && TargetState.CanTakeCover() ) //Can only have flankers if we can take cover
	{
		//Set default conditions if no conditions were specified
		if( RequiredConditions.Length == 0 )
		{
			//  require only basic visibility, otherwise concealed units can't be seen and would be unflankable
			RequiredConditions = default.LivingBasicVisibleFilter;
		}

		VisibilityMgr.GetAllViewersOfTarget(TargetStateObjectID, OutFlankingEnemies, class'XComGameState_Unit', StartAtHistoryIndex, RequiredConditions);

		for( Index = OutFlankingEnemies.Length - 1; Index > -1; --Index )
		{
			UnitState = XComGameState_unit(History.GetGameStateForObjectID(OutFlankingEnemies[Index].ObjectID,, StartAtHistoryIndex));
			`assert(UnitState != none);

			bIsEnemyTeam = UnitState.IsEnemyTeam(FlankingTeam);

			if( (bInvertTeam == bIsEnemyTeam) && UnitState.CanFlank(bAllowMeleeFlankers) && UnitState.GetMyTemplate().CanFlankUnits )
			{
				VisibilityMgr.GetVisibilityInfo(UnitState.ObjectID, TargetStateObjectID, OutVisibilityInfo, StartAtHistoryIndex);
				if( OutVisibilityInfo.TargetCover != CT_None )
				{
					OutFlankingEnemies.Remove(Index, 1);
				}
			}
			else
			{
				OutFlankingEnemies.Remove(Index, 1);
			}
		}
	}	
}

/// <summary>
/// Returns results similar to GetFlankingEnemiesOfTarget, except that target must be able to see the flanking enemies
/// </summary>
simulated static function GetVisibleFlankingEnemiesOfTarget(int TargetStateObjectID, 
															out array<StateObjectReference> OutFlankingEnemies, 
															optional int StartAtHistoryIndex = -1,
															optional array<X2Condition> RequiredConditions)
{
	local ETeam FlankingTeam;
	FlankingTeam = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetStateObjectID,, StartAtHistoryIndex)).GetTeam();
	GetVisibleFlankersOfTarget(TargetStateObjectID, FlankingTeam, OutFlankingEnemies, StartAtHistoryIndex, RequiredConditions, true);
}

/// <summary>
/// Returns results similar to GetFlankersOfTarget, except that target must be able to see the flanking enemies
/// </summary>
simulated static function GetVisibleFlankersOfTarget(int TargetStateObjectID, 
													 ETeam FlankingTeam,
															out array<StateObjectReference> OutFlankingEnemies, 
															optional int StartAtHistoryIndex = -1,
															optional array<X2Condition> RequiredConditions,
															optional bool bInvertTeam)
{
	local int Index;	
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;


	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	//Set default conditions (visible units need to be alive and game play visible) if no conditions were specified
	if( RequiredConditions.Length == 0 )
	{
		RequiredConditions = default.LivingGameplayVisibleFilter;
	}

	GetFlankersOfTarget(TargetStateObjectID, FlankingTeam, OutFlankingEnemies, StartAtHistoryIndex, RequiredConditions, bInvertTeam);	

	for( Index = OutFlankingEnemies.Length - 1; Index > -1; --Index )
	{
		VisibilityMgr.GetVisibilityInfo(TargetStateObjectID, OutFlankingEnemies[Index].ObjectID, OutVisibilityInfo, StartAtHistoryIndex);

		//Remove any flankers that the target cannot see
		if( !OutVisibilityInfo.bVisibleGameplay )	
		{
			OutFlankingEnemies.Remove(Index, 1);
		}
	}
}

/// <summary>
/// GetVisibleFlankingEnemiesOfLocation returns an out param list of enemies that are flanking the target location, AND visible to the passed in player
/// </summary>
// Not visualizer-safe.  Only valid for current game state history. 
simulated static function GetFlankingEnemiesOfLocation(vector TestLocation, 
													   int PlayerStateObjectID,
													   out array<StateObjectReference> OutFlankingEnemies)
{
	local int Index;	
	local XComGameStateHistory History;	
	local XComGameState_Unit UnitState;
	local array<GameRulesCache_VisibilityInfo> OutVisibilityInfos;
		
	History = `XCOMHISTORY;

	GetAllEnemiesForLocation(TestLocation, PlayerStateObjectID, OutVisibilityInfos);

	for( Index = 0; Index < OutVisibilityInfos.Length; ++Index )
	{		
		//If the target location has no cover from this enemy, the enemy is flanking
		if( OutVisibilityInfos[Index].TargetCover == CT_None )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OutVisibilityInfos[Index].SourceID));
			OutFlankingEnemies.AddItem(UnitState.GetReference());
		}
	}
}

/// <summary>
/// GetVisibleFlankingEnemiesOfLocation returns an out param list of enemies that are flanking the target location, AND 
/// visible to the passed in player AND have a ranged attack.
/// </summary>
simulated static event GetVisibleFlankingEnemiesOfLocation(vector TestLocation, 
														      int PlayerStateObjectID,
															  out array<StateObjectReference> OutFlankingEnemies, 
															  optional int StartAtHistoryIndex = -1)
{
	local int Index;	
	local XComGameStateHistory History;	
	local XComGameState_Unit UnitState;
	local array<GameRulesCache_VisibilityInfo> OutVisibilityInfos;
		
	History = `XCOMHISTORY;

	GetAllVisibleEnemiesForLocation(TestLocation, PlayerStateObjectID, OutVisibilityInfos,,StartAtHistoryIndex);

	for( Index = 0; Index < OutVisibilityInfos.Length; ++Index )
	{		
		//If the target location has no cover from this enemy, the enemy is flanking
		if( OutVisibilityInfos[Index].TargetCover == CT_None )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OutVisibilityInfos[Index].SourceID,, StartAtHistoryIndex));
			//Make sure the unit has the ability to flank.
			if (UnitState.CanFlank() && UnitState.GetMyTemplate().CanFlankUnits)
			{
				OutFlankingEnemies.AddItem(UnitState.GetReference());
			}
		}
	}
}

/// <summary>
/// GetNumVisibleAlliesToSource returns the number of enemies flanking the specified TargetStateObjectID
/// </summary>
simulated static function int GetNumFlankingEnemiesOfTarget(int TargetStateObjectID, 
														    optional int StartAtHistoryIndex = -1)
{
	local array<StateObjectReference> OutFlankingEnemies;
	GetFlankingEnemiesOfTarget(TargetStateObjectID, OutFlankingEnemies, StartAtHistoryIndex);
	return OutFlankingEnemies.Length;
}

/// <summary>
/// GetNumEnemiesFlankedBySource returns a list of enemies flanked by source
/// </summary>
simulated static function GetEnemiesFlankedBySource( int SourceObjectID, 
													 out array<StateObjectReference> OutFlankingEnemies, 
													 optional int StartAtHistoryIndex = -1)
{
	local int Index;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	VisibilityMgr.GetAllVisibleToSource(SourceObjectID, OutFlankingEnemies, class'XComGameState_Unit', StartAtHistoryIndex, default.LivingGameplayVisibleFilter);

	for( Index = OutFlankingEnemies.Length - 1; Index > -1; --Index )
	{
		UnitState = XComGameState_unit(History.GetGameStateForObjectID(OutFlankingEnemies[Index].ObjectID, , StartAtHistoryIndex));
		`assert(UnitState != none);

		if( UnitState.CanTakeCover() && UnitState.TargetIsEnemy(SourceObjectID, StartAtHistoryIndex) )	
		{
			VisibilityMgr.GetVisibilityInfo(SourceObjectID, UnitState.ObjectID, OutVisibilityInfo, StartAtHistoryIndex);			
			if( OutVisibilityInfo.TargetCover != CT_None )
			{
				OutFlankingEnemies.Remove(Index, 1);
			}
		}
		else
		{
			OutFlankingEnemies.Remove(Index, 1);
		}
	}
}

/// <summary>
/// GetNumEnemiesFlankedBySource returns the number of enemies flanked by the specified SourceObjectID
/// </summary>
simulated static function int GetNumEnemiesFlankedBySource(int SourceObjectID, 
														   optional int StartAtHistoryIndex = -1)
{
	local array<StateObjectReference> OutFlankingEnemies;
	GetEnemiesFlankedBySource(SourceObjectID, OutFlankingEnemies, StartAtHistoryIndex);
	return OutFlankingEnemies.Length;
}

/// <summary>
/// GetOverwatchingEnemiesOfTarget returns an out param list of enemies that could take an over watch shot at the target ID
/// </summary>
// Added ValidReserveTypes filter.  Default empty array == 'overwatch' & 'pistoloverwatch' only.
// Only types in the game are currently overwatch, Suppression, and KillZone.
// Also, if using Suppression or Killzone, this function doesn't check if the target would be affected, only
// that there is a visible enemy using this ability.
simulated static function GetOverwatchingEnemiesOfTarget(int TargetStateObjectID, 
														 out array<StateObjectReference> OutOverwatchingEnemies, 
														 optional int StartAtHistoryIndex = -1,
														 bool bSkipConcealed=false,
														 optional array<Name> ValidReserveTypes)
{
	local X2GameRulesetVisibilityManager VisibilityMgr;	
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	VisibilityMgr.GetAllViewersOfTarget(TargetStateObjectID, OutOverwatchingEnemies, class'XComGameState_BaseObject', StartAtHistoryIndex, default.LivingGameplayVisibleFilter);
	class'Helpers'.static.GetOverwatchersFromList(TargetStateObjectID, OutOverwatchingEnemies, StartAtHistoryIndex, bSkipConcealed, ValidReserveTypes);
}

/// <summary>
/// GetNumOverwatchingEnemiesOfTarget returns the number of enemies that could take an over watch shot at the target ID
/// </summary>
simulated static function int GetNumOverwatchingEnemiesOfTarget(int TargetStateObjectID, 
															   optional int StartAtHistoryIndex = -1)
{
	local array<StateObjectReference> OutOverwatchingEnemies;
	GetOverwatchingEnemiesOfTarget(TargetStateObjectID, OutOverwatchingEnemies, StartAtHistoryIndex);
	return OutOverwatchingEnemies.Length;
}

simulated static function bool IsUnitVisibleToLocalPlayer(int TargetUnitObjectID, int HistoryIndex)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local EForceVisibilitySetting ForceVisibleSetting;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnitObjectID, , HistoryIndex));
	if( UnitState == None )
	{
		`RedScreen("Function IsUnitVisibleToLocalPlayer called with a non-unit object id!   @acheng");
		return false;
	}
	ForceVisibleSetting = UnitState.ForceModelVisible(); // Checks if local player, among other things.
	if( ForceVisibleSetting == eForceVisible )
	{
		return true;
	}
	else if( ForceVisibleSetting == eForceNotVisible || UnitState.IsConcealed() )
	{
		return false;
	}

	// Check if enemy can see this unit.
	return GetNumEnemyViewersOfTarget(TargetUnitObjectID, HistoryIndex) > 0;
}

static function bool IsUnitAlwaysVisibleToLocalPlayer(XComGameState_Unit PathingUnitStateObject, optional bool bCheckPathingStateObject=true)
{
	local X2SitRepEffect_PerfectVisibility SitRepEffectTemplate;
	local XComGameState_BattleData BattleDataState;

	if(bCheckPathingStateObject)
	{
		if(PathingUnitStateObject.ControllingPlayer.ObjectID == `TACTICALRULES.GetLocalClientPlayerObjectID())
		{
			// The local player can always see their own units
			return true;
		}
	}

	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleDataState != none);
	foreach class'X2SitrepTemplateManager'.static.IterateEffects(class'X2SitRepEffect_PerfectVisibility', SitRepEffectTemplate, BattleDataState.ActiveSitReps)
	{
		return true;
	}

	return false;
}

/// <summary>
/// FillPathTileData takes an input object ID and outputs a list of GameplayTileData structures representing 
/// data for each tile in that unit's current path. The state object pointed to by PathingUnitObjectID must
/// be a unit with a valid pathing pawn for this to operate properly.
///
/// This method is expensive, the results should probably be added to a history frame based cache similar to
/// visibility info and the method itself made native. Until then do not call it in tight loops.
/// </summary>
simulated static function FillPathTileData(int PathingUnitObjectID, array<TTile> PathTiles, out array<GameplayTileData> TileData)
{
	local array<StateObjectReference> ObjectsVisibleToPlayer;

	FillPathTileDataAndVisibleObjects(PathingUnitObjectID, PathTiles, TileData, ObjectsVisibleToPlayer, false);
}

simulated static function FillPathTileDataAndVisibleObjects(
	int PathingUnitObjectID, 
	array<TTile> PathTiles, 
	out array<GameplayTileData> TileData, 
	out array<StateObjectReference> ObjectsVisibleToPlayer,
	bool bIncludeNonUnits )
{
	local XComGameStateHistory History;
	local XComGameState_Unit PathingUnitStateObject;
	local int Index;
	local GameplayTileData TempTileData;
	local Vector TileLocation;
	local array<GameRulesCache_VisibilityInfo> OutVisibleEnemies;
	local int EnemyIndex;
	local bool bCheckAgainstVisibleEnemies;
	local TTile kEventTile;
	local int LocalPlayerID;
	local XComGameState_Unit UnitState;
	local bool bCivilianMove;
	local XComGameState_SquadViewer SquadViewer;
	local bool AllTilesVisibileToLocalPlayer;
	local bool bCheckPathingStateObject;

	History = `XCOMHISTORY;
	PathingUnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(PathingUnitObjectID));
	if( PathingUnitStateObject != none )
	{
		if (XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(PathingUnitStateObject.ControllingPlayer.ObjectID)).GetTeam() == eTeam_Neutral)
		{
			bCivilianMove = true;
		}

		//Build the tile list
		TileData.Length = 0;		

		for( Index = 0; Index < PathTiles.Length; ++Index )
		{
			TempTileData.SourceObjectID = PathingUnitObjectID;
			TempTileData.EventTile = PathTiles[Index];
			TileData.AddItem(TempTileData);
		}

		
		if(`XENGINE.IsMultiPlayerGame())
		{
			// this code path is fundamentally broken in multiplayer as IsUnitAlwaysVisibleToLocalPlayer tries to check against this
			// pathing unit object which in calls to this function come from the pathing pawn. the pathing pawn only exists for the local
			// player and as such, IsUnitAlwaysVisibleToLocalPlayer will falsely return true.
			bCheckPathingStateObject = false;
		}
		else
		{
			bCheckPathingStateObject = true;
		}
		// If the pathing unit belongs to the local client, or a sitrep is forcing visibility,
		// then the entire path is automatically visible
		AllTilesVisibileToLocalPlayer = IsUnitAlwaysVisibleToLocalPlayer(PathingUnitStateObject, bCheckPathingStateObject);
		
		// AI units are visible when the enemy can see them.  AI player visibility is not a factor.
		bCheckAgainstVisibleEnemies = !PathingUnitStateObject.ControllingPlayerIsAI();

		// cache this so we don't have to call it repeatedly (it's extremely expensive)
		if (bCheckAgainstVisibleEnemies)
			GetAllVisibleObjectsForPlayer(PathingUnitStateObject.ControllingPlayer.ObjectID, ObjectsVisibleToPlayer,,, bIncludeNonUnits);

		LocalPlayerID = `TACTICALRULES.GetLocalClientPlayerObjectID();

		//Fill out interesting data for this tile
		for( Index = 0; Index < TileData.Length; ++Index )
		{
			kEventTile = TileData[Index].EventTile; // unreal doesn't like passing dynamic array elements as out parameters even when the out is const :(
			TileLocation = `XWORLD.GetPositionFromTileCoordinates(kEventTile);
			
			// find all enemies visible to the unit at this tile. We use GetAllEnemiesForLocation instead of 
			// GetAllVisibleEnemiesForLocation because the latter will rebuild ObjectsVisibleToPlayer every frame,
			// which is extremely expensive and uses about 20ms on my i7 per call in debug scripts. Instead, we do
			// our own visibility cull with our own cached array of units visible to the player. - dburchanowski
			if (!bCivilianMove)
			{
				GetAllEnemiesForLocation(TileLocation, PathingUnitStateObject.ControllingPlayer.ObjectID, OutVisibleEnemies);
			}
			else
			{
				// When a civilian is moving, we care about whether XCom can see the civilian movement tiles
				GetAllTeamUnitsForLocation(TileLocation, PathingUnitStateObject.ControllingPlayer.ObjectID, eTeam_XCom, OutVisibleEnemies, , true);
			}

			// If the entire path is visible to the local player, then this tile is too
			TileData[Index].NumLocalViewers = AllTilesVisibileToLocalPlayer ? 1 : 0;

			// remove any enemies not visible to the player
			for( EnemyIndex = OutVisibleEnemies.Length - 1; EnemyIndex >= 0; EnemyIndex-- )
			{
				if(!OutVisibleEnemies[EnemyIndex].bVisibleBasic)
				{
					OutVisibleEnemies.Remove(EnemyIndex, 1);					
				}
				else
				{
					//Record the total number of "local" units that can see the unit represented by PathingUnitObjectID
					UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OutVisibleEnemies[EnemyIndex].SourceID));
					SquadViewer = XComGameState_SquadViewer(History.GetGameStateForObjectID(OutVisibleEnemies[EnemyIndex].SourceID));

					if (`XENGINE.IsMultiPlayerGame() && UnitState != none)
					{
						TileData[Index].NumLocalViewers++;
					}
					else
					{
						if((UnitState != none && UnitState.ControllingPlayer.ObjectID == LocalPlayerID) || 
						   (SquadViewer != none && SquadViewer.AssociatedPlayer.ObjectID == LocalPlayerID))
						{
							TileData[Index].NumLocalViewers++;
						}
					}

					if(bCheckAgainstVisibleEnemies && ObjectsVisibleToPlayer.Find('ObjectId', OutVisibleEnemies[EnemyIndex].SourceID) == INDEX_NONE)
					{
						OutVisibleEnemies.Remove(EnemyIndex, 1);
					}
				}
			}
			
			TileData[Index].VisibleEnemies = OutVisibleEnemies;
			OutVisibleEnemies.Length = 0;
		}
	}
}

/// <summary>
/// GetNumVisibleEnemyTargetsToSource returns the number of Units considered to be enemies visible to SourceStateObjectID. Only considers source and targets which are units.
/// </summary>
native static function int GetNumVisibleEnemyTargetsToSource(int SourceStateObjectID, 
														optional int StartAtHistoryIndex = -1,
														optional array<X2Condition> RequiredConditions);

/// <summary>
/// GetClosestVisibleEnemy fills out a GameRulesCache_VisibilityInfo structure with the info pertaining to the closest visible enemy. The return value is TRUE if 
/// OutClosestInfo is filled out, FALSE if no visible enemies were found.
/// </summary>
native static function bool GetClosestVisibleEnemy( int SourceStateObjectID, 
													out GameRulesCache_VisibilityInfo OutClosestInfo,
													optional int StartAtHistoryIndex = -1,
													optional array<X2Condition> RequiredConditions);

/// <summary>
/// GetNumVisibleAlliesToSource returns the number of Units considered to be allies visible to SourceStateObjectID. Only considers source and targets which are units.
/// </summary>
native static function int GetNumVisibleAlliesToSource( int SourceStateObjectID, 
														optional int StartAtHistoryIndex = -1,
														optional array<X2Condition> RequiredConditions);

native static function GetVisibleTilesToSource(out array<TTile> VisibleSubset, array<TTile> TileList, int SourceStateObjectID, int TargetObjectID);

cpptext
{
public:
	static UBOOL EvaluateConditions(UXComGameStateHistory* History,
		AX2GameRulesetVisibilityManager* VisibilityMgr,
		INT HistoryFrameIndex,
		const FGameRulesCache_VisibilityInfo& VisibilityInfo,
		UXComGameState_BaseObject* SourceObject,
		UXComGameState_BaseObject* TargetObject,
		const TArray<class UX2Condition*>& RequiredConditions, 
		UBOOL bTargetCheckOnly = false);

	static UBOOL CanUnitPossiblySeeLocation(INT UnitID, const struct FTTile& TestLocation);
};

DefaultProperties
{	
	Begin Object Class=X2Condition_Visibility Name=DefaultGameplayVisibilityCondition
		bRequireLOS=TRUE
		bRequireBasicVisibility=TRUE
		bRequireGameplayVisible=TRUE
	End Object	
	GameplayVisibilityCondition = DefaultGameplayVisibilityCondition

	Begin Object Class=X2Condition_Visibility Name=DefaultBasicVisibilityCondition
		bRequireLOS=TRUE
		bRequireBasicVisibility=TRUE
		bRequireGameplayVisible=FALSE
	End Object
	BasicVisibilityCondition = DefaultBasicVisibilityCondition

	Begin Object Class=X2Condition_Visibility Name=DefaultLOSVisibilityCondition
		bRequireLOS=TRUE
		bRequireBasicVisibility=FALSE
		bRequireGameplayVisible=FALSE
	End Object
	LOSVisibilityCondition = DefaultLOSVisibilityCondition

	Begin Object Class=X2Condition_HackingTarget Name=DefaultHackableObjectIntrusionProtocolCondition
		bIntrusionProtocol=true
	End Object
	HackableObjectIntrusionProtocolCondition = DefaultHackableObjectIntrusionProtocolCondition

	Begin Object Class=X2Condition_HackingTarget Name=DefaultHackableObjectCondition
	End Object
	HackableObjectCondition = DefaultHackableObjectCondition

	Begin Object Class=X2Condition_UnitProperty Name=DefaultAliveUnitPropertyCondition
		ExcludeAlive=FALSE;
		ExcludeDead=TRUE;
		ExcludeRobotic=FALSE;
		ExcludeOrganic=FALSE;
		ExcludeHostileToSource=FALSE;
		ExcludeFriendlyToSource=FALSE;
	End Object
	AliveUnitPropertyCondition = DefaultAliveUnitPropertyCondition;

	LivingGameplayVisibleFilter(0)=DefaultGameplayVisibilityCondition
	LivingGameplayVisibleFilter(1)=DefaultAliveUnitPropertyCondition

	LivingBasicVisibleFilter(0)=DefaultBasicVisibilityCondition
	LivingBasicVisibleFilter(1)=DefaultAliveUnitPropertyCondition	

	GameplayVisibleFilter(0)=DefaultGameplayVisibilityCondition

	LivingLOSVisibleFilter(0)=DefaultLOSVisibilityCondition
	LivingLOSVisibleFilter(1)=DefaultAliveUnitPropertyCondition

	BasicVisibleFilter(0)=DefaultBasicVisibilityCondition
}
