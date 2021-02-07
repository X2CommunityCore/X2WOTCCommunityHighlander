
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComGameState_AIGroup.uc    
//  AUTHOR:  Alex Cheng  --  12/10/2014
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AIGroup extends XComGameState_BaseObject
	dependson(XComAISpawnManager, XComGameState_AIUnitData)
	native(AI)
	config(AI);

// The Name of this encounter, used for determining when a specific group has been engaged/defeated
var Name EncounterID;

// If specified, allows encounters to be searched for and found by tag in kismet, instead of just by EncounterID
var Name PrePlacedEncounterTag;

// How wide should this group's encounter band be?
var float MyEncounterZoneWidth;

// How deep should this group's encounter band be?
var float MyEncounterZoneDepth;

// The offset from the LOP for this group.
var float MyEncounterZoneOffsetFromLOP;

// The index of the encounter zone that this group should attempt to roam around within
var float MyEncounterZoneOffsetAlongLOP;

// If specified, the encounter zone should be defined by finding a tagged volume in the level instead of offsetting one using the previous fields.
var Name MyEncounterZoneVolumeTag;

var privatewrite array<StateObjectReference> m_arrMembers; // Current list of group members
var	array<TTile> m_arrGuardLocation;

var array<StateObjectReference> m_arrDisplaced; // Reference to unit that is not currently a member due to mind-control.
												// Keeping track of unit to be able to restore the unit if mind-control wears off.

var float InfluenceRange;

// Patrol group data. TODO- keep track of this here.
//var TTile kCurr; // Tile location of current node
//var TTile kLast; // Tile location of last node.
//var array<TTile> kLoc;

var bool bObjective; // Objective Guard?
var bool bPlotPath;

var bool bInterceptObjectiveLocation;
var bool bProcessedScamper; //TRUE if this AI group has scampered
var bool bPendingScamper;	//TRUE if this AI group has been told to scamper, but has not started to scamper yet ( can happen during group moves that reveal XCOM )

// the current destination that this group will attempt to be moving towards while in green alert
var Vector		CurrentTargetLocation;
var int			TurnCountForLastDestination;

struct native ai_group_stats
{
	var int m_iInitialMemberCount;
	var array<StateObjectReference> m_arrDead;		// Keeping track of units that have died.
};
var ai_group_stats m_kStats;

var int InitiativePriority;	// in what relative initiative order should this group be processed compared to other groups for the same player.  Higher # = process initiative later

////////////////////////////////////////////////////////////////////////////////////////
// Reveal/Scamper data

// The alert data which instigated the reveal/scamper.
var EAlertCause DelayedScamperCause;

// The object Id of the unit who was the source of the alert data causing this reveal/scamper.
var int RevealInstigatorUnitObjectID;

// The Object IDs of all units that were concealed prior to this reveal, but had their concealment broken.
var array<int> PreviouslyConcealedUnitObjectIDs;

// The Object IDs of the revealed units who are surprised by the reveal.
var array<int> SurprisedScamperUnitIDs;

// If this group is mid-move, this is the step along the pre-calculated movement path at which the reveal will take place.
var int FinalVisibilityMovementStep;

// If this group is mid-move, this is the list of units within this group that still need to process some of their move before the group can reveal.
var array<int> WaitingOnUnitList;

// True while this group is in the process of performing a reveal/scamper.
var bool SubmittingScamperReflexGameState;

// if non-none, this specifies a non-standard reveal type
var name SpecialRevealType;

////////////////////////////////////////////////////////////////////////////////////////
// Ever Sighted

// Until true, this group has not been sighted by enemies, so the first sighting should show a camera look at.
var protectedwrite bool EverSightedByEnemy;

var int SightedByUnitID;

////////////////////////////////////////////////////////////////////////////////////////

var config float SURPRISED_SCAMPER_CHANCE;
var config float DESTINATION_REACHED_SIZE_SQ;
var config float MAX_TURNS_BETWEEN_DESTINATIONS;

////////////////////////////////////////////////////////////////////////////////////////
// Fallback behavior variables
var bool bHasCheckedForFallback;	// true if the decision to fallback or not has already been made.
var bool bFallingBack;				// true if Fallback is active. 
var bool bPlayedFallbackCallAnimation;		// Flag if the call animation has happened already.
var StateObjectReference FallbackGroup;		// Fallback group reference.  
var config array<Name> FallbackExclusionList; // List of unit types that are unable to fallback
var config float FallbackChance;			  // Chance to fallback, currently set to 50%.

// Config variables to determine when to disable fallback.
// Fallback is disabled at the start of the AI turn when either of the following conditions are filled:
//   1) XCom has caused the fallback-to-group to scamper, and no other groups can be set as an alternate fallback, or
//   2) the Unit is in range of the fallback group, as defined by the config value below, at which time the unit joins the group at green alert
var config int UnitInFallbackRangeMeters;  // Distance from fallback destination to be considered "In Fallback Area"
var int FallbackMaximumOverwatchCount;	// Any more overwatchers than this will prevent fallback from activating.
////////////////////////////////////////////////////////////////////////////////////////
const Z_TILE_RANGE = 3;

////////////////////////////////////////////////////////////////////////////////////////
// Group Initiative

// If true, the initiative of this group has been interrupted; when resuming initiative, 
// this group should not reinitialize action points or perform start-of-turn behaviors
var bool bInitiativeInterrupted;

// If true, this group should be removed from the initiative order after it's initiative has been processed.  
// Primarily used for groups that interrupt the initiative order (like the Chosen)
var bool bShouldRemoveFromInitiativeOrder;

// The name of the team this group should be associated with (currently ETeam enum; TODO replace with FName)
var ETeam TeamName;

// The display name for this group in any UI
var string FriendlyGroupName;

// until summoning sickness is cleared (at the start of the player turn for the leader of this group), 
// this group will not activate as part of the initiative order
var bool bSummoningSicknessCleared;

// debug tracking variables
var name m_mergeGroupMoveVizStage;


////////////////////////////////////////////////////////////////////////////////////////
// Group membership

native function AddUnitToGroup(int UnitID, XComGameState NewGameState);
native function RemoveUnitFromGroup(int UnitID, XComGameState NewGameState);

////////////////////////////////////////////////////////////////////////////////////////

function OnUnitDeath( StateObjectReference DeadUnit, bool bIsAIUnit )
{
	if (bIsAIUnit)
	{
		if (m_arrMembers.Find('ObjectID', DeadUnit.ObjectID) != -1 && m_kStats.m_arrDead.Find('ObjectID', DeadUnit.ObjectID) == -1)
		{
			m_kStats.m_arrDead.AddItem(DeadUnit);
		}
	}
}

function bool GetLivingMembers(out array<int> arrMemberIDs, optional out array<XComGameState_Unit> LivingMemberStates)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Member;
	local StateObjectReference Ref;

	History = `XCOMHISTORY;
	foreach m_arrMembers(Ref)
	{
		Member = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Member != None && Member.IsAlive())
		{
			arrMemberIDs.AddItem(Ref.ObjectID);
			LivingMemberStates.AddItem(Member);
		}
	}
	return arrMemberIDs.Length > 0;
}

function Vector GetGroupMidpoint(optional int HistoryIndex = -1)
{
	local TTile GroupMidpointTile;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	GetUnitMidpoint(GroupMidpointTile, HistoryIndex);
	return WorldData.GetPositionFromTileCoordinates(GroupMidpointTile);
}

// Get midpoint of all living members in this group.
function bool GetUnitMidpoint(out TTile Midpoint, optional int HistoryIndex = -1)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Member;
	local StateObjectReference Ref;
	local TTile MinTile, MaxTile;
	local bool bInited;

	History = `XCOMHISTORY;
	foreach m_arrMembers(Ref)
	{
		Member = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID, , HistoryIndex));
		if (Member != None && Member.IsAlive())
		{
			if (!bInited)
			{
				MinTile = Member.TileLocation;
				MaxTile = Member.TileLocation;
				bInited = true;
			}
			else
			{
				MinTile.X = Min(MinTile.X, Member.TileLocation.X);
				MinTile.Y = Min(MinTile.Y, Member.TileLocation.Y);
				MinTile.Z = Min(MinTile.Z, Member.TileLocation.Z);
				MaxTile.X = Max(MaxTile.X, Member.TileLocation.X);
				MaxTile.Y = Max(MaxTile.Y, Member.TileLocation.Y);
				MaxTile.Z = Max(MaxTile.Z, Member.TileLocation.Z);
			}
		}
	}

	if( bInited )
	{
		Midpoint.X = (MinTile.X + MaxTile.X)*0.5f;
		Midpoint.Y = (MinTile.Y + MaxTile.Y)*0.5f;
		Midpoint.Z = (MinTile.Z + MaxTile.Z)*0.5f;
		return true;
	}
	else
	{
		//Failsafe, look for any member, don't care if they are alive
		foreach m_arrMembers(Ref)
		{
			Member = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID, , HistoryIndex));
			if (Member != None)
			{
				Midpoint = Member.TileLocation;
			}
		}
	}

	return false;
}

// Returns true if any living units are red or orange alert.
function bool IsEngaged() 
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_AIUnitData AIData;
	local StateObjectReference Ref, KnowledgeRef;
	local int AlertLevel, DataID;

	History = `XCOMHISTORY;
	foreach m_arrMembers(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if( Unit != None && Unit.IsAlive() )
		{
			AlertLevel = Unit.GetCurrentStat(eStat_AlertLevel);
			if (AlertLevel == `ALERT_LEVEL_RED)
			{
				return true;
			}
			if(AlertLevel == `ALERT_LEVEL_GREEN )
			{
				continue;
			}
			// Orange alert check.  
			DataID = Unit.GetAIUnitDataID();
			if( DataID > 0 )
			{
				AIData = XComGameState_AIUnitData(History.GetGameStateForObjectID(DataID));
				if( AIData.HasAbsoluteKnowledge(KnowledgeRef) )  
				{
					return true;
				}
			}
		}
	}
	return false;
}

function MarkGroupSighted(XComGameState_Unit SightingUnit, XComGameState NewGameState)
{
	local Object SelfObj;

	`assert(SightingUnit != none);

	if(!EverSightedByEnemy)
	{
		EverSightedByEnemy = true;
		SightedByUnitID = SightingUnit.ObjectID;

		SelfObj = self;
		`XEVENTMGR.TriggerEvent('EnemyGroupSighted', SelfObj, SightingUnit, NewGameState);
	}
}

function float GetMaxMobility()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Member;
	local StateObjectReference Ref;
	local float MaxMobility;

	History = `XCOMHISTORY;
	foreach m_arrMembers(Ref)
	{
		Member = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if( Member != None && Member.IsAlive() )
		{
			MaxMobility = Max(MaxMobility, Member.GetCurrentStat(eStat_Mobility));
		}
	}
	return MaxMobility;
}

// Determine if this AI Group should currently be moving towards an intercept location
function bool ShouldMoveToIntercept(out Vector TargetInterceptLocation, XComGameState NewGameState, XComGameState_AIPlayerData PlayerData)
{
	local XComGameState_BattleData BattleData;
	local Vector CurrentGroupLocation;
	local EncounterZone MyEncounterZone;
	local XComAISpawnManager SpawnManager;
	local XComTacticalMissionManager MissionManager;
	local MissionSchedule ActiveMissionSchedule;
	local array<Vector> EncounterCorners;
	local int CornerIndex;
	local XComGameState_AIGroup NewGroupState;
	local XComGameStateHistory History;
	local Vector CurrentXComLocation;
	local XComWorldData World;
	local TTile Tile;

	World = `XWORLD;
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if( XComSquadMidpointPassedGroup() && !BattleData.bKismetDisabledInterceptMovement )
	{
		if( !GetNearestEnemyLocation(GetGroupMidpoint(), TargetInterceptLocation) )
		{
			// If for some reason the nearest enemy can't be found, send these units to the objective.
			TargetInterceptLocation = BattleData.MapData.ObjectiveLocation;
		}
		return true;
	}

	// This flag is turned on if XCom is unengaged, and the SeqAct_CompleteMissionObjective has fired, and this is the closest group -or cheatmgr setting bAllPodsConvergeOnMissionComplete is on.
	if( bInterceptObjectiveLocation )
	{
		TargetInterceptLocation = BattleData.MapData.ObjectiveLocation;
		return true;
	}

	// Start Issue #507
	//
	// Mod override for AI patrol behavior. If the event returns `true`, then
	// leave the mod to handle it and just quit out of this method.
	if (TriggerOverridePatrolBehavior())
	{
		return false;
	}
	// End Issue #507
	
	// TODO: otherwise, try to patrol around within the current encounter zone
	CurrentGroupLocation = GetGroupMidpoint();
	Tile = World.GetTileCoordinatesFromPosition(CurrentTargetLocation);
	if( PlayerData.StatsData.TurnCount - TurnCountForLastDestination > MAX_TURNS_BETWEEN_DESTINATIONS || 
		World.IsTileOutOfRange(Tile) ||
	   VSizeSq(CurrentGroupLocation - CurrentTargetLocation) < DESTINATION_REACHED_SIZE_SQ )
	{
		// choose new target location
		SpawnManager = `SPAWNMGR;
		MissionManager = `TACTICALMISSIONMGR;
		MissionManager.GetActiveMissionSchedule(ActiveMissionSchedule);
		// Start Issue #500
		/// HL-Docs: ref:OverrideEncounterZoneAnchorPoint
		/// This allows mods to override the LoP anchor point for the encounter zone. By
		/// default, the encounter zone adjusts to the current location of the XCOM
		/// squad.
		///
		/// As an example, a mod could use the XCOM's spawn location instead so that
		/// the encounter zones remain the same regardless of where the XCOM squad is
		/// currently.
		CurrentXComLocation = SpawnManager.GetCurrentXComLocation();
		TriggerOverrideEncounterZoneAnchorPoint(CurrentXComLocation);
		// End Issue #500
		MyEncounterZone = SpawnManager.BuildEncounterZone(
			BattleData.MapData.ObjectiveLocation,
			CurrentXComLocation,
			MyEncounterZoneDepth,
			MyEncounterZoneWidth,
			MyEncounterZoneOffsetFromLOP,
			MyEncounterZoneOffsetAlongLOP,
			MyEncounterZoneVolumeTag);

		EncounterCorners[0] = SpawnManager.CastVector(MyEncounterZone.Origin);
		EncounterCorners[0].Z = CurrentGroupLocation.Z;
		EncounterCorners[1] = EncounterCorners[0] + SpawnManager.CastVector(MyEncounterZone.SideA);
		EncounterCorners[2] = EncounterCorners[1] + SpawnManager.CastVector(MyEncounterZone.SideB);
		EncounterCorners[3] = EncounterCorners[0] + SpawnManager.CastVector(MyEncounterZone.SideB);

		for( CornerIndex = EncounterCorners.Length - 1; CornerIndex >= 0; --CornerIndex )
		{
			// Start Issue #508
			//
			// Ensure the potential patrol locations are on-map, otherwise the alert will fail to set.
			/// HL-Docs: ref:Bugfixes; issue:508
			/// Patrol logic now ensures units do not attempt to patrol outside of the map which would cause them to stop patrolling
			EncounterCorners[CornerIndex] = World.FindClosestValidLocation(EncounterCorners[CornerIndex], false, false);
			// End Issue #508
			if( VSizeSq(CurrentGroupLocation - EncounterCorners[CornerIndex]) < DESTINATION_REACHED_SIZE_SQ )
			{
				EncounterCorners.Remove(CornerIndex, 1);
			}
		}

		if( EncounterCorners.Length > 0 )
		{
			TargetInterceptLocation = EncounterCorners[`SYNC_RAND_STATIC(EncounterCorners.Length)];
			Tile = World.GetTileCoordinatesFromPosition(TargetInterceptLocation);
			if (World.IsTileOutOfRange(Tile))
			{
				World.ClampTile(Tile);
				TargetInterceptLocation = World.GetPositionFromTileCoordinates(Tile);
			}

			NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', ObjectID));
			NewGroupState.CurrentTargetLocation = TargetInterceptLocation;
			NewGroupState.TurnCountForLastDestination = PlayerData.StatsData.TurnCount;

			return true;
		}
	}

	return false;
}

// Start Issue #500
/// HL-Docs: feature:OverrideEncounterZoneAnchorPoint; issue:500; tags:tactical
/// The `OverrideEncounterZoneAnchorPoint` event allows mods to override 
/// the anchor point for determining encounter zones for patrolling pods.
///
/// X, Y and Z components of the tuple should be treated as components 
/// of the Anchor Point's vector coordinates.
///    
///```event
///EventID: OverrideEncounterZoneAnchorPoint,
///EventData: [inout float X, inout float Y, inout float Z],
///EventSource: XComGameState_AIGroup (AIGroup),
///NewGameState: none
///```
function TriggerOverrideEncounterZoneAnchorPoint(out Vector Anchor)
{
	   local XComLWTuple OverrideTuple;

	   OverrideTuple = new class'XComLWTuple';
	   OverrideTuple.Id = 'OverrideEncounterZoneAnchorPoint';
       OverrideTuple.Data.Add(3);
       OverrideTuple.Data[0].kind = XComLWTVFloat;
       OverrideTuple.Data[0].f = Anchor.X;
       OverrideTuple.Data[1].kind = XComLWTVFloat;
       OverrideTuple.Data[1].f = Anchor.Y;
       OverrideTuple.Data[2].kind = XComLWTVFloat;
       OverrideTuple.Data[2].f = Anchor.Z;

	   `XEVENTMGR.TriggerEvent('OverrideEncounterZoneAnchorPoint', OverrideTuple, self);

       Anchor.X = OverrideTuple.Data[0].f;
       Anchor.Y = OverrideTuple.Data[1].f;
       Anchor.Z = OverrideTuple.Data[2].f;
}
// End Issue #500

// Start Issue #507
/// HL-Docs: feature:OverridePatrolBehavior; issue:507; tags:tactical
/// The `OverridePatrolBehavior` event allows mods to override pods' patrol behavior.
/// The `bOverridePatrolBehavior` component of the tuple should be set to `true` 
/// if the mod *is* overriding the patrol behavior and wants to bypass 
/// the default base game patrol logic.
///    
///```event
///EventID: OverridePatrolBehavior,
///EventData: [out bool bOverridePatrolBehavior],
///EventSource: XComGameState_AIGroup (AIGroup),
///NewGameState: none
///```
// The method returns `true` if the mod *is* overriding the patrol
// behavior and wants to bypass the default base game patrol logic.
function bool TriggerOverridePatrolBehavior()
{
	   local XComLWTuple OverrideTuple;

	   OverrideTuple = new class'XComLWTuple';
	   OverrideTuple.Id = 'OverridePatrolBehavior';
       OverrideTuple.Data.Add(1);
       OverrideTuple.Data[0].kind = XComLWTVBool;
       OverrideTuple.Data[0].b = false;

	   `XEVENTMGR.TriggerEvent('OverridePatrolBehavior', OverrideTuple, self);

		return OverrideTuple.Data[0].b;
}
// End Issue #507

// Return true if XCom units have passed our group location.
function bool XComSquadMidpointPassedGroup()
{
	local vector GroupLocationToEnemy;
	local vector GroupLocationToEnemyStart;
	local vector GroupLocation;
	local vector GroupLocationOnAxis;

	local TwoVectors CurrentLineOfPlay;
	local XGAIPlayer AIPlayer;

	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	AIPlayer.m_kNav.UpdateCurrentLineOfPlay(CurrentLineOfPlay);
	GroupLocation = GetGroupMidpoint();
	GroupLocationOnAxis = AIPlayer.m_kNav.GetNearestPointOnAxisOfPlay(GroupLocation);

	GroupLocationToEnemy = CurrentLineOfPlay.v1 - GroupLocationOnAxis;
	GroupLocationToEnemyStart = AIPlayer.m_kNav.m_kAxisOfPlay.v1 - GroupLocationOnAxis;

	if( GroupLocationToEnemyStart dot GroupLocationToEnemy < 0 )
	{
		return true;
	}
	return false;
}

function bool GetNearestEnemyLocation(vector TargetLocation, out vector ClosestLocation)
{
	local float fDistSq, fClosest;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int ClosestID;
	local vector UnitLocation;
	local XComWorldData World;
	local bool EnemyUnit;

	World = `XWORLD;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		EnemyUnit = class'XGPlayerNativeBase'.static.AreEnemyTeams( TeamName, UnitState.GetTeam() );

		if( EnemyUnit && !UnitState.bRemovedFromPlay && UnitState.IsAlive() && !UnitState.IsBleedingOut() )
		{
			UnitLocation = World.GetPositionFromTileCoordinates(UnitState.TileLocation);
			fDistSq = VSizeSq(UnitLocation - TargetLocation);

			if( ClosestID <= 0 || fDistSq < fClosest )
			{
				ClosestID = UnitState.ObjectID;
				fClosest = fDistSq;
				ClosestLocation = UnitLocation;
			}
		}
	}

	if( ClosestID > 0 )
	{
		return true;
	}
	return false;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function GatherBrokenConcealmentUnits()
{
	local XComGameStateHistory History;
	local int EventChainStartHistoryIndex;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	PreviouslyConcealedUnitObjectIDs.Length = 0;
	EventChainStartHistoryIndex = History.GetEventChainStartIndex();

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( !UnitState.IsConcealed() && UnitState.WasConcealed(EventChainStartHistoryIndex) )
		{
			PreviouslyConcealedUnitObjectIDs.AddItem(UnitState.ObjectID);
		}
	}
}

function bool IsWaitingOnUnitForReveal(XComGameState_Unit JustMovedUnitState)
{
	return WaitingOnUnitList.Find(JustMovedUnitState.ObjectID) != INDEX_NONE;
}

function StopWaitingOnUnitForReveal(XComGameState_Unit JustMovedUnitState)
{
	WaitingOnUnitList.RemoveItem(JustMovedUnitState.ObjectID);

	// just removed the last impediment to performing the reveal
	if( WaitingOnUnitList.Length == 0 )
	{
		ProcessReflexMoveActivate();
	}
}

function InitiateReflexMoveActivate(XComGameState_Unit TargetUnitState, EAlertCause eCause, optional name InSpecialRevealType)
{
	DelayedScamperCause = eCause;
	RevealInstigatorUnitObjectID = TargetUnitState.ObjectID;
	GatherBrokenConcealmentUnits();

	ProcessReflexMoveActivate(InSpecialRevealType);
}

private function bool CanScamper(XComGameState_Unit UnitStateObject)
{
	return UnitStateObject.IsAlive() &&
		(!UnitStateObject.IsIncapacitated()) &&
		UnitStateObject.bTriggerRevealAI &&
		!UnitStateObject.IsPanicked() &&
		!UnitStateObject.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.PanickedName) &&
		!UnitStateObject.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.BurrowedName) &&
		!UnitStateObject.IsPlayerControlled() && // Player-controlled units do not scamper.
	    (`CHEATMGR == None || !`CHEATMGR.bAbortScampers);
}

function ApplyAlertAbilityToGroup(EAlertCause eCause)
{
	local StateObjectReference Ref;
	local XComGameState_Unit UnitStateObject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach m_arrMembers(Ref)
	{
		UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));

		UnitStateObject.ApplyAlertAbilityForNewAlertData(eCause);
	}
}

function ProcessReflexMoveActivate(optional name InSpecialRevealType)
{
	local XComGameStateHistory History;
	local int Index, NumScamperers, NumSurprised, i, NumActionPoints;
	local XComGameState_Unit UnitStateObject, TargetStateObject, NewUnitState;
	local XComGameState_AIGroup NewGroupState;
	local StateObjectReference Ref;
	local XGAIPlayer AIPlayer;
	local XComGameState NewGameState;
	local array<StateObjectReference> Scamperers;
	local float SurprisedChance;
	local bool bUnitIsSurprised;
	local X2TacticalGameRuleset Rules;

	History = `XCOMHISTORY;

	if( !bProcessedScamper ) // Only allow scamper once.
	{
		//First, collect a list of scampering units. Due to cheats and other mechanics this list could be empty, in which case we should just skip the following logic
		foreach m_arrMembers(Ref)
		{
			UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
			if(CanScamper(UnitStateObject))
			{	
				Scamperers.AddItem(Ref);
			}
		}

		NumScamperers = Scamperers.Length;
		if( NumScamperers > 0 )
		{
			//////////////////////////////////////////////////////////////
			// Kick off the BT scamper actions

			//Find the AI player data object
			AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
			`assert(AIPlayer != none);
			TargetStateObject = XComGameState_Unit(History.GetGameStateForObjectID(RevealInstigatorUnitObjectID));

			// Give the units their scamper action points
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Scamper Action Points");
			foreach Scamperers(Ref)
			{
				NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Ref.ObjectID));
				if( NewUnitState.IsAbleToAct() )
				{
					NewUnitState.ActionPoints.Length = 0;
					NumActionPoints = NewUnitState.GetNumScamperActionPoints();
					for (i = 0; i < NumActionPoints; ++i)
					{
						NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint); //Give the AI one free action point to use.
					}

					if (NewUnitState.GetMyTemplate().OnRevealEventFn != none)
					{
						NewUnitState.GetMyTemplate().OnRevealEventFn(NewUnitState);
					}
				}
				else
				{
					NewGameState.PurgeGameStateForObjectID(NewUnitState.ObjectID);
				}
			}

			NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', ObjectID));
			NewGroupState.bProcessedScamper = true;
			NewGroupState.bPendingScamper = true;
			NewGroupState.SpecialRevealType = InSpecialRevealType;
			NewGroupState.bSummoningSicknessCleared = false; 

			if(NewGameState.GetNumGameStateObjects() > 0)
			{
				// Now that we are kicking off a scamper Behavior Tree (latent), we need to handle the scamper clean-up on
				// an event listener that waits until after the scampering behavior decisions are made.
				for( Index = 0; Index < NumScamperers; ++Index )
				{
					UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Scamperers[Index].ObjectID));

					// choose which scampering units should be surprised
					// randomly choose half to be surprised
					if(PreviouslyConcealedUnitObjectIDs.Length > 0)
					{
						if( UnitStateObject.IsGroupLeader() )
						{
							bUnitIsSurprised = false;
						}
						else
						{
							NumSurprised = NewGroupState.SurprisedScamperUnitIDs.Length;
							SurprisedChance = (float(NumScamperers) * SURPRISED_SCAMPER_CHANCE - NumSurprised) / float(NumScamperers - Index);
							bUnitIsSurprised = `SYNC_FRAND() <= SurprisedChance;
						}

						if(bUnitIsSurprised)
						{
							NewGroupState.SurprisedScamperUnitIDs.AddItem(Scamperers[Index].ObjectID);
						}
					}

					AIPlayer.QueueScamperBehavior(UnitStateObject, TargetStateObject, bUnitIsSurprised, Index == 0);
				}

				// Start Issue #510
				//
				// Mods can't use the `OnScamperBegin` event to provide extra action points because it
				// happens too late, so we fire this custom event here instead.
				`XEVENTMGR.TriggerEvent('ProcessReflexMove', UnitStateObject, self, NewGameState);
				// End Issue #510

				Rules = `TACTICALRULES;
				Rules.SubmitGameState(NewGameState);
				`BEHAVIORTREEMGR.TryUpdateBTQueue();
			}
			else
			{
				History.CleanupPendingGameState(NewGameState);
			}
		}
	}
}

function OnScamperBegin()
{
	local XComGameStateHistory History;
	local XComGameStateContext_RevealAI ScamperContext;
	local StateObjectReference Ref;
	local XComGameState_Unit UnitStateObject;
	local X2GameRuleset Ruleset;
	local array<int> ScamperList;
	local XComGameState_Unit GroupLeaderUnitState;
	local XComGameState_AIGroup AIGroupState;


	History = `XCOMHISTORY;
	Ruleset = `XCOMGAME.GameRuleset;

	//////////////////////////////////////////////////////////////
	// Reveal Begin
	foreach m_arrMembers(Ref)
	{
		UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if( CanScamper(UnitStateObject) )
		{
			ScamperList.AddItem(Ref.ObjectID);
		}
	}

	// Prevent a red screen by only submitting this game state if we have units that are scampering.
	if(ScamperList.Length > 0 )
	{
		ScamperContext = XComGameStateContext_RevealAI(class'XComGameStateContext_RevealAI'.static.CreateXComGameStateContext());
		ScamperContext.RevealAIEvent = eRevealAIEvent_Begin;
		ScamperContext.CausedRevealUnit_ObjectID = RevealInstigatorUnitObjectID;
		ScamperContext.ConcealmentBrokenUnits = PreviouslyConcealedUnitObjectIDs;
		ScamperContext.SurprisedScamperUnitIDs = SurprisedScamperUnitIDs;

		//Mark this game state as a visualization fence (ie. we need to see whatever triggered the scamper fully before the scamper happens)
		ScamperContext.SetVisualizationFence(true);
		ScamperContext.RevealedUnitObjectIDs = ScamperList;
		ScamperContext.SpecialRevealType = SpecialRevealType;


		// determine if this is the first ever sighting of this type of enemy
		GroupLeaderUnitState = GetGroupLeader();
		
		AIGroupState = GroupLeaderUnitState.GetGroupMembership();

		if (AIGroupState != None && !AIGroupState.EverSightedByEnemy)
		{
			ScamperContext.bDoSoldierVO = true;
		}

		Ruleset.SubmitGameStateContext(ScamperContext);
	}
}

function XComGameState_Unit GetGroupLeader()
{
	if( m_arrMembers.Length > 0 )
	{
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrMembers[0].ObjectID));
	}

	return None;
}
function DelayedOnScamperComplete()
{
	if (`XCOMGAME.GameRuleset.IsDoingLatentSubmission())
	{
		`BATTLE.SetTimer(0.1f, false, nameof(DelayedOnScamperComplete), self);
	}
	else
	{
		OnScamperComplete();
	}
}

// After Scamper behavior trees have finished running, clean up all the scamper vars.
function OnScamperComplete()
{
	local XComGameStateContext_RevealAI ScamperContext;
	local XGAIPlayer AIPlayer;
	local StateObjectReference Ref;
	local XComGameStateContext_RevealAI AIRevealContext;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability AbilityContext;
	local Array<int> SourceObjects;
	local bool PreventSimultaneousVisualization;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	//Find the AI player data object, and mark the reflex action state done.
	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());

	ScamperContext = XComGameStateContext_RevealAI(class'XComGameStateContext_RevealAI'.static.CreateXComGameStateContext());
	ScamperContext.RevealAIEvent = eRevealAIEvent_End; // prevent from reflexing again.
	foreach m_arrMembers(Ref)
	{
		ScamperContext.RevealedUnitObjectIDs.AddItem(Ref.ObjectID);
	}
	ScamperContext.CausedRevealUnit_ObjectID = RevealInstigatorUnitObjectID;

	`XCOMGAME.GameRuleset.SubmitGameStateContext(ScamperContext);

	PreventSimultaneousVisualization = false;
	foreach History.IterateContextsByClassType(class'XComGameStateContext', Context)
	{
		AIRevealContext = XComGameStateContext_RevealAI(Context);
		if( AIRevealContext != None && AIRevealContext.RevealAIEvent == eRevealAIEvent_Begin )
		{
			break;
		}

		AbilityContext = XComGameStateContext_Ability(Context);
		if( AbilityContext != None && AbilityContext.InputContext.AbilityTemplateName != 'StandardMove' )
		{
			if( SourceObjects.Find(AbilityContext.InputContext.SourceObject.ObjectID) != INDEX_NONE )
			{
				PreventSimultaneousVisualization = true;
				break;
			}

			SourceObjects.AddItem(AbilityContext.InputContext.SourceObject.ObjectID);
		}
	}

	if( PreventSimultaneousVisualization )
	{
		foreach History.IterateContextsByClassType(class'XComGameStateContext', Context)
		{
			AIRevealContext = XComGameStateContext_RevealAI(Context);
			if( AIRevealContext != None && AIRevealContext.RevealAIEvent == eRevealAIEvent_Begin )
			{
				break;
			}

			Context.SetVisualizationStartIndex(-1);
		}
	}
	

	ClearScamperData();
	AIPlayer.ClearWaitForScamper();
}

function ClearScamperData()
{
	local XComGameState_AIGroup NewGroupState;
	local XComGameState NewGameState;

	// Mark the end of the reveal/scamper process
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIRevealComplete [" $ ObjectID $ "]");
	NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', ObjectID));

	NewGroupState.DelayedScamperCause = eAC_None;
	NewGroupState.RevealInstigatorUnitObjectID = INDEX_NONE;
	NewGroupState.FinalVisibilityMovementStep = INDEX_NONE;
	NewGroupState.WaitingOnUnitList.Length = 0;
	NewGroupState.PreviouslyConcealedUnitObjectIDs.Length = 0;
	NewGroupState.SurprisedScamperUnitIDs.Length = 0;
	NewGroupState.SubmittingScamperReflexGameState = false;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function bool IsFallingBack(optional out vector Destination)
{
	if( bFallingBack )
	{
		Destination = GetFallBackDestination();
		return true;
	}
	return false;
}

function vector GetFallBackDestination()
{
	local XComGameState_AIGroup GroupState;
	local vector Destination;
	GroupState = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(FallbackGroup.ObjectID));
	Destination = GroupState.GetGroupMidpoint();
	return Destination;
}

function bool ShouldDoFallbackYell()
{
	return !bPlayedFallbackCallAnimation;
}

// Update while fallback is active.  Disable fallback once XCom reaches the area.
function UpdateFallBack()
{
	local array<int> LivingUnits;
	local XComGameState_Unit UnitState;
	local bool bDisableFallback;
	local StateObjectReference AlternateGroup, TransferUnitRef;

	if( bFallingBack )
	{
		GetLivingMembers(LivingUnits);
		if( LivingUnits.Length > 0 )
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LivingUnits[0]));
			if( IsXComVisibleToFallbackArea() )
			{
				// Option A - Pick another group to fallback to, if any.
				if( HasRetreatLocation(XGUnit(UnitState.GetVisualizer()), AlternateGroup) )
				{
					`LogAI("FALLBACK- Changing fallback-to-group since original group has already scampered.");
					SetFallbackStatus(true, AlternateGroup);
					return;
				}
				else
				{
					`LogAI("FALLBACK- Disabling fallback due to XCom soldiers in the fallback zone.");
					bDisableFallback = true;
				}
			}

			// Disable fallback if this unit is already in the fallback area, and XCom is already within range.
			if( IsUnitInFallbackArea(UnitState) )
			{
				bDisableFallback = true;
				TransferUnitRef = UnitState.GetReference();
			}
		}
		else
		{
			`LogAI("FALLBACK- Disabling fallback due to no living units in group remaining.");
			bDisableFallback = true;
		}
		if( bDisableFallback )
		{
			SetFallbackStatus(false, FallbackGroup, TransferUnitRef);
		}
	}
}

function bool IsUnitInFallbackArea(XComGameState_Unit Unit)
{
	local vector UnitLocation;
	UnitLocation = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);

	return IsInFallbackArea(UnitLocation);
}

function bool IsInFallbackArea( vector UnitLocation )
{
	local vector FallbackLocation;
	FallbackLocation = GetFallBackDestination();
	if( VSizeSq(UnitLocation - FallbackLocation) < Square(`METERSTOUNITS(UnitInFallbackRangeMeters) ))
	{
		return true;
	}
	return false;
}

// Once the target group has scampered, fallback should be disabled, or transferred to another group.
function bool IsXComVisibleToFallbackArea()
{
	local XComGameState_AIGroup TargetGroup;
	TargetGroup = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(FallbackGroup.ObjectID));
	return (TargetGroup != None && TargetGroup.bProcessedScamper);
}

// Update game state
function SetFallbackStatus(bool bFallback, optional StateObjectReference FallbackRef, optional StateObjectReference TransferUnitRef, optional XComGameState NewGameState)
{
	local XComGameState_AIGroup NewGroupState, TargetGroup;
	local XComGameState_AIPlayerData NewAIPlayerData;
	local XGAIPlayer AIPlayer;
	local XComGameStateHistory History;
	local XComGameState_Unit NewUnitState, LeaderState;
	local float LeaderAlert;
	local bool SubmitState;

	if( bFallback == bFallingBack && bHasCheckedForFallback && FallbackGroup == FallbackRef && TransferUnitRef.ObjectID <= 0)
	{
		// No change, early exit.
		return;
	}

	History = `XCOMHISTORY;

	if (NewGameState == none)
	{
		NewGameState = History.GetStartState(); // Fallback can be disabled when this group is spawned if it is a singleton.
		if( NewGameState == none )
		{
			// Create a new gamestate to update the fallback variables.
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Set Fallback Status");
			SubmitState = true;
		}
	}

	NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', ObjectID));
	NewGroupState.bHasCheckedForFallback = true;
	NewGroupState.bFallingBack = bFallback;
	NewGroupState.FallbackGroup = FallbackRef;

	if( bFallback )
	{
		// Add to fallback count in AIPlayerData.  
		AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
		NewAIPlayerData = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', AIPlayer.GetAIDataID()));
		NewAIPlayerData.StatsData.FallbackCount++;
	}
	
	if( TransferUnitRef.ObjectID > 0 ) // If this ref exists, we want to transfer the unit to the fallback-to group.
	{
		`Assert(bFallback == false && FallbackRef.ObjectID > 0); // Cannot be set to fallback and have a transfer unit.

		// We also want to make some changes to the unit to make him more ready to join the group.
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', TransferUnitRef.ObjectID));
		// Unit needs to have the same unrevealed pod status.
		NewUnitState.bTriggerRevealAI = true;
		TargetGroup = XComGameState_AIGroup(History.GetGameStateForObjectID(FallbackRef.ObjectID));
		LeaderState = XComGameState_Unit(History.GetGameStateForObjectID(TargetGroup.m_arrMembers[0].ObjectID));
		LeaderAlert = LeaderState.GetCurrentStat(eStat_AlertLevel);
		// Unit needs to have the same alert level as the rest of the pod.
		if( NewUnitState.GetCurrentStat(eStat_AlertLevel) != LeaderAlert )
		{
			NewUnitState.SetCurrentStat(eStat_AlertLevel, LeaderAlert);
		}

		// Now to transfer the unit out of its old group and into its new group.
		AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
		NewAIPlayerData = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', AIPlayer.GetAIDataID()));
		if( !NewAIPlayerData.TransferUnitToGroup(FallbackRef, TransferUnitRef, NewGameState) )
		{ 
			`RedScreen("Error in transferring fallback unit to new group. @acheng");
		}
	}

	if( SubmitState )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	// If a unit was transferred, update group listings in visualizers after the gamestates are updated.
	if( TransferUnitRef.ObjectID > 0 && AIPlayer != None && TargetGroup != None)
	{
		if( TargetGroup.m_arrMembers.Length > 0 )
		{
			AIPlayer.m_kNav.TransferUnitToGroup(TargetGroup.m_arrMembers[0].ObjectID, TransferUnitRef.ObjectID);
		}
		else
		{
			`RedScreen("TransferUnitGroup On Fallback failure - Target group has no units? @acheng");
		}
	}
}

// Do a fallback check.  Check if the last living unit qualifies and roll the dice.
function CheckForFallback()
{
	local array<int> LivingUnitIDs;
	local bool bShouldFallback;
	local float Roll;
	local StateObjectReference FallbackGroupRef;
	GetLivingMembers(LivingUnitIDs);

	if( LivingUnitIDs.Length != 1 )
	{
		`RedScreen("Error - XComGameState_AIGroup::CheckForFallback living unit length does not equal 1.  @acheng");
	}
	else
	{
		if( IsUnitEligibleForFallback(LivingUnitIDs[0], FallbackGroupRef) )
		{
			Roll = `SYNC_FRAND_STATIC();
			bShouldFallback =  Roll < FallbackChance;
			`LogAI("FALLBACK CHECK for unit"@LivingUnitIDs[0]@"- Rolled"@Roll@"on fallback check..." @(bShouldFallback ? "Passed, falling back." : "Failed.Not falling back."));
		}
		else
		{
			`LogAI("FALLBACK CHECK for unit"@LivingUnitIDs[0]@"- Failed in check IsUnitEligibleForFallback.");
		}
	}

	SetFallbackStatus(bShouldFallback, FallbackGroupRef);
}

function bool HasRetreatLocation(XGUnit RetreatUnit, optional out StateObjectReference RetreatGroupRef)
{
	local XGAIPlayer AIPlayer;
	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	return AIPlayer.HasRetreatLocation(RetreatUnit, RetreatGroupRef);
}

function bool HasHitRetreatCap()
{
	local XGAIPlayer AIPlayer;
	local XComGameState_AIPlayerData AIData;
	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	AIData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(AIPlayer.GetAIDataID()));
	if( AIData.RetreatCap < 0 ) // Unlimited retreating when retreat cap is negative.
	{
		return false;
	}
	return AIData.StatsData.FallbackCount >= AIData.RetreatCap;
}

// This sends the entire group toward a single destination.
function bool GroupMoveToPoint(vector Destination, out string FailText)
{
	local array<PathingInputData> GroupPaths;
	local XGUnit UnitVisualizer;
	
	if( GetGroupMovePaths(Destination, GroupPaths, UnitVisualizer) )
	{
		XComTacticalController(`BATTLE.GetALocalPlayerController()).GameStateMoveUnit(UnitVisualizer, GroupPaths);
		return true;
	}
	else
	{
		FailText = FailText @ GetFuncName() @ " failure.";
	}

	return false;
}

// this function is called to merge each StandardMove visualization as part of a group move
// 
// StandardMove 0 Begin -> BeginGroupMove -> MidpointFramingCamera -> StandardMove 0 -> RemoveMidpointFramingCamera -> EndGroupMove -> StandardMove 0 End
//																   -> StandardMove 1 ->
//																   -> StandardMove N ->
//
function MergeGroupMoveVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisMgr;
	local array<X2Action> MarkerActions;
	local X2Action TestMarkerAction;
	local X2Action_MarkerTreeInsertBegin MarkerBeginAction;
	local X2Action_MarkerTreeInsertEnd MarkerEndAction;
	local X2Action_MarkerNamed GroupBeginMarkerAction, GroupEndMarkerAction, CameraReplaceAction;
	local X2Action_RevealAIBegin RevealBeginAction;
	local X2Action_CameraFrameAbility FramingAction;
	local X2Action_CameraRemove CameraRemoveAction;
	local VisualizationActionMetadata Metadata;
	local XComGameStateContext Context;
	local X2Action_MarkerNamed SyncAction;
	local bool bScamperAlreadyFramed;
	local bool bMoveIsVisible;

	VisMgr = `XCOMVISUALIZATIONMGR;

	m_mergeGroupMoveVizStage = 'Setup';

	// grab the head and the tail of this StandardMove sequence
	MarkerActions.Length = 0;
	VisMgr.GetNodesOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin', MarkerActions);
	MarkerBeginAction = X2Action_MarkerTreeInsertBegin(MarkerActions[0]);
	Metadata = MarkerBeginAction.Metadata;
	Context = MarkerBeginAction.StateChangeContext;

	MarkerActions.Length = 0;
	VisMgr.GetNodesOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd', MarkerActions);
	MarkerEndAction = X2Action_MarkerTreeInsertEnd(MarkerActions[0]);

	m_mergeGroupMoveVizStage = 'X2Action_CameraFollowUnit';

	// as part of a group move, the camera framing actions need to be removed from this BuildTree
	VisMgr.GetNodesOfType(BuildTree, class'X2Action_CameraFollowUnit', MarkerActions);
	foreach MarkerActions(TestMarkerAction)
	{
		CameraReplaceAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.CreateVisualizationAction(Context));
		CameraReplaceAction.SetName("GroupMoveCameraFollowUnitReplacement");
		VisMgr.ReplaceNode(CameraReplaceAction, TestMarkerAction);
	}

	m_mergeGroupMoveVizStage = 'X2Action_CameraFrameAbility';

	VisMgr.GetNodesOfType(BuildTree, class'X2Action_CameraFrameAbility', MarkerActions);
	foreach MarkerActions(TestMarkerAction)
	{
		CameraReplaceAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.CreateVisualizationAction(Context));
		CameraReplaceAction.SetName("GroupMoveCameraFrameAbilityReplacement");
		VisMgr.ReplaceNode(CameraReplaceAction, TestMarkerAction);
	}

	m_mergeGroupMoveVizStage = 'X2Action_CameraRemove';

	VisMgr.GetNodesOfType(BuildTree, class'X2Action_CameraRemove', MarkerActions);
	foreach MarkerActions(TestMarkerAction)
	{
		CameraReplaceAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.CreateVisualizationAction(Context));
		CameraReplaceAction.SetName("GroupMoveCameraRemoveReplacement");
		VisMgr.ReplaceNode(CameraReplaceAction, TestMarkerAction);
	}

	m_mergeGroupMoveVizStage = 'X2Action_StartCinescriptCamera';

	VisMgr.GetNodesOfType(BuildTree, class'X2Action_StartCinescriptCamera', MarkerActions);
	foreach MarkerActions(TestMarkerAction)
	{
		CameraReplaceAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.CreateVisualizationAction(Context));
		CameraReplaceAction.SetName("GroupMoveCameraStartCinescriptReplacement");
		VisMgr.ReplaceNode(CameraReplaceAction, TestMarkerAction);
	}

	m_mergeGroupMoveVizStage = 'X2Action_EndCinescriptCamera';

	VisMgr.GetNodesOfType(BuildTree, class'X2Action_EndCinescriptCamera', MarkerActions);
	foreach MarkerActions(TestMarkerAction)
	{
		CameraReplaceAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.CreateVisualizationAction(Context));
		CameraReplaceAction.SetName("GroupMoveCameraEndCinescriptReplacement");
		VisMgr.ReplaceNode(CameraReplaceAction, TestMarkerAction);
	}


	m_mergeGroupMoveVizStage = 'GroupMoveBegin-GroupMoveEnd';

	// now find the existing GroupMove Begin/End nodes
	MarkerActions.Length = 0;
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerNamed', MarkerActions);
	foreach MarkerActions(TestMarkerAction)
	{
		if( X2Action_MarkerNamed(TestMarkerAction).MarkerName == 'GroupMoveBegin' )
		{
			GroupBeginMarkerAction = X2Action_MarkerNamed(TestMarkerAction);
		}
		if( X2Action_MarkerNamed(TestMarkerAction).MarkerName == 'GroupMoveEnd' )
		{
			GroupEndMarkerAction = X2Action_MarkerNamed(TestMarkerAction);
		}
	}

	m_mergeGroupMoveVizStage = 'X2Action_RevealAIBegin';

	//Check for whether this is part of a reveal sequence ( which has its own camera )
	bScamperAlreadyFramed = false;
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_RevealAIBegin', MarkerActions);
	foreach MarkerActions(TestMarkerAction)
	{
		RevealBeginAction = X2Action_RevealAIBegin(TestMarkerAction);

		// only consider reveals that frame the scamper
		if( RevealBeginAction.WantsToPlayTheLostCamera() && RevealBeginAction.CanPlayTheLostCamera() )
		{
			bScamperAlreadyFramed = true;
		}
	}

	m_mergeGroupMoveVizStage = 'not bScamperAlreadyFramed';

	// if there is no framed scamper, then we need to determine if any part of the move needs to be framed
	bMoveIsVisible = false;
	if( !bScamperAlreadyFramed )
	{
		VisMgr.GetNodesOfType(BuildTree, class'X2Action_Move', MarkerActions);
		foreach MarkerActions(TestMarkerAction)
		{
			// any move action that is not a MoveTeleport is a visible move action
			if( X2Action_MoveTeleport(TestMarkerAction) == none )
			{
				bMoveIsVisible = true;
				break;
			}
		}
	}

	// the group actions haven't been built yet; build them now
	if( GroupBeginMarkerAction == none )
	{
		m_mergeGroupMoveVizStage = 'GroupBeginMarkerAction eq none';

		GroupBeginMarkerAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(Metadata, Context, true, MarkerBeginAction));
		GroupBeginMarkerAction.SetName("GroupMoveBegin");
		
		if ( bScamperAlreadyFramed )
		{
			SyncAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(Metadata, Context, true, GroupBeginMarkerAction));
			SyncAction.SetName("SyncAction");			
		}
		else
		{
			FramingAction = X2Action_CameraFrameAbility(class'X2Action_CameraFrameAbility'.static.AddToVisualizationTree(Metadata, Context, true, GroupBeginMarkerAction));
			if( bMoveIsVisible )
			{
				FramingAction.AbilitiesToFrame.AddItem(XComGameStateContext_Ability(Context));
			}
			FramingAction.CameraTag = 'GroupMoveFramingCamera';
			FramingAction.bFollowMovingActors = true;
		}

		CameraRemoveAction = X2Action_CameraRemove(class'X2Action_CameraRemove'.static.AddToVisualizationTree(Metadata, Context, true, none, MarkerEndAction.ParentActions));
		CameraRemoveAction.CameraTagToRemove = 'GroupMoveFramingCamera';

		GroupEndMarkerAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(Metadata, Context, true, CameraRemoveAction));
		GroupEndMarkerAction.SetName("GroupMoveEnd");

		//Merge us into the tree at large using standard merge logic - additional moves will find the above marker nodes and attach to them
		XComGameStateContext_Ability(BuildTree.StateChangeContext).SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
	}
	// the group actions are already present, just need to merge this tree
	else
	{
		m_mergeGroupMoveVizStage = 'GroupBeginMarkerAction ne none';

		SyncAction = X2Action_MarkerNamed(GroupBeginMarkerAction.ChildActions[0]);			

		if( SyncAction == none )
		{
			FramingAction = X2Action_CameraFrameAbility(GroupBeginMarkerAction.ChildActions[0]);
			if( bMoveIsVisible )
			{
				FramingAction.AbilitiesToFrame.AddItem(XComGameStateContext_Ability(Context));
			}
		}

		VisMgr.DisconnectAction(MarkerBeginAction);
		VisMgr.ConnectAction(MarkerBeginAction, VisualizationTree, false, SyncAction == none ? FramingAction : SyncAction);

		CameraRemoveAction = X2Action_CameraRemove(GroupEndMarkerAction.ParentActions[0]);
		MarkerActions = CameraRemoveAction.ParentActions;
		MarkerActions.AddItem(MarkerEndAction);

		VisMgr.DisconnectAction(CameraRemoveAction);
		VisMgr.ConnectAction(CameraRemoveAction, VisualizationTree, false, none, MarkerActions);
	}
}

function GameStateMoveUnitCallback(XComGameState ResultState)
{

}

// This sends the specified units in the group each to specific destinations, respectively.
function bool MoveGroupMembersToPoints(array<XComGameState_Unit> Members, array<TTile> Destinations, bool bSeparateGameStates,
	optional delegate<X2GameRuleset.LatentSubmitGameStateContextCallbackFn> ActivationCallback)
{
	local int Index;
	local array<PathingInputData> GroupPathData;
	local XGUnit UnitVisualizer, LeaderVisualizer;
	local PathingInputData MemberPathData;
	local TTile TileDest;
	local array<TTile> MemberPath, StartingTiles, ActualDestList, ExclusionList;
	local array<XComGameState_Unit> MoveAbortedUnits;
	local XComWorldData WorldData;
	local TTile MemberDestination;
	local XComGameState_Unit MemberState;

	if (Destinations.Length != Members.Length)
	{
		`RedScreen("Destination list length does not match the number of group members!  @acheng");
		return false;
	}

	WorldData = `XWORLD;
	ActualDestList.Length = 0;
	// Clear all blocking, but track what tiles units started out in.
	foreach Members(MemberState)
	{
		WorldData.ClearTileBlockedByUnitFlag(MemberState);
		StartingTiles.AddItem(MemberState.TileLocation);
	}
	for( Index = 0; Index < Members.Length; ++Index )
	{
		UnitVisualizer = XGUnit(Members[Index].GetVisualizer());
		MemberDestination = Destinations[Index];
		MemberPath.Length = 0;
		if( UnitVisualizer != None )
		{
			TileDest = MemberDestination;
			TileDest.Z = WorldData.GetFloorTileZ(MemberDestination);
			if ( !WorldData.IsFloorTile(TileDest) )
			{
				TileDest = MemberDestination;
			}
			if( !UnitVisualizer.m_kReachableTilesCache.BuildPathToTile(TileDest, MemberPath) )
			{
				// Update exclusion list.  This includes both destinations and starting tiles of units that have not yet moved,
				// and destinations of units that have moved.
				ExclusionList.Length = 0;
				ExclusionList = Destinations;
				ExclusionList.Remove(0, Index); // Remove all destinations of units that already moved. (these are added in ActualDestList).
				class'Helpers'.static.GetTileUnion(ExclusionList, StartingTiles, ActualDestList, true);

				`LogAI("Unable to build a path to ("$TileDest.X@TileDest.Y@TileDest.Z$") for unit "$UnitVisualizer.ObjectID$"- Attempting alternate destination."@GetFuncName());
				TileDest = UnitVisualizer.m_kReachableTilesCache.GetClosestReachableDestination(TileDest, ExclusionList);
				// Abort movement on this unit if no valid closest reachable found.
				if ( class'Helpers'.static.FindTileInList(TileDest, ExclusionList) != INDEX_NONE ||
					   !UnitVisualizer.m_kReachableTilesCache.IsTileReachable(TileDest) ||
					   !UnitVisualizer.m_kReachableTilesCache.BuildPathToTile(TileDest, MemberPath))
				{
					`LogAI("Alternate destination for unit "$UnitVisualizer.ObjectID$"- FAILURE."@GetFuncName());
					// If this unit failed to move, mark this unit's actual destination as his starting location.
					ActualDestList.AddItem(Members[Index].TileLocation);
					StartingTiles.Remove(0, 1); // Remove the front tile.
					MoveAbortedUnits.AddItem(Members[Index]);
					continue;
				}
				else
				{
					`LogAI("Alternate destination for unit "$UnitVisualizer.ObjectID$"- Succeeded.  Moving to ("$TileDest.X@TileDest.Y@TileDest.Z$")"@GetFuncName());
				}
			}
			else
			{
				`LogAI("GroupMove Unit "$UnitVisualizer.ObjectID$" moving to ("$TileDest.X@TileDest.Y@TileDest.Z$") as expected."@GetFuncName());
			}
			if (LeaderVisualizer == None)
			{
				LeaderVisualizer = UnitVisualizer;
			}
			MemberPathData.MovingUnitRef = Members[Index].GetReference();
			MemberPathData.MovementTiles = MemberPath;
			GroupPathData.AddItem(MemberPathData);
			if (bSeparateGameStates)
			{
				// only do passed in callback on last move
				if( Index == Members.Length-1)
					XComTacticalController(`BATTLE.GetALocalPlayerController()).GameStateMoveUnit(UnitVisualizer, GroupPathData, , ActivationCallback, MergeGroupMoveVisualization);
				else
					XComTacticalController(`BATTLE.GetALocalPlayerController()).GameStateMoveUnit(UnitVisualizer, GroupPathData, , GameStateMoveUnitCallback, MergeGroupMoveVisualization);
				GroupPathData.Length = 0;
			}
			ActualDestList.AddItem(TileDest); // Update the exclusion list of tiles already claimed.
			StartingTiles.Remove(0, 1);		  // Remove the front tile.
		}
	}

	if (bSeparateGameStates)
	{
		// Reset blocking on any units that were supposed to move, but didn't.
		foreach MoveAbortedUnits(MemberState)
		{
			WorldData.SetTileBlockedByUnitFlag(MemberState);
		}
		return true; // Already submitted each individually.
	}

	if( GroupPathData.Length > 0)
	{
		XComTacticalController(`BATTLE.GetALocalPlayerController()).GameStateMoveUnit(LeaderVisualizer, GroupPathData);

		// Reset blocking on any units that were supposed to move, but didn't.
		foreach MoveAbortedUnits(MemberState)
		{
			WorldData.SetTileBlockedByUnitFlag(MemberState);
		}
		return true;
	}
	`RedScreen(GetFuncName()@"failure with no group path data! @ACHENG");
	return false;
}

function ComputeGroupPath(vector GroupDestination, array<int> LivingUnits, out array<TTile> GroupPath, out XGUnit LeaderVisualizer)
{ 
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local TTile TileDest;

	// get the patrol leader visualizer
	History = `XCOMHISTORY;
	`Assert(LivingUnits.Length > 0);
	LeaderVisualizer = XGUnit(History.GetVisualizer(LivingUnits[0]));
	if( LeaderVisualizer == none ) return; // couldn't find the group leader

	// and attempt to have him build a path to the destination
	WorldData = `XWORLD;
	if( !WorldData.GetFloorTileForPosition(GroupDestination, TileDest) )
	{
		TileDest = WorldData.GetTileCoordinatesFromPosition(GroupDestination);
	}
	if( !LeaderVisualizer.m_kReachableTilesCache.BuildPathToTile(TileDest, GroupPath) )
	{
		TileDest = LeaderVisualizer.m_kReachableTilesCache.GetClosestReachableDestination(TileDest);
		if( !LeaderVisualizer.m_kReachableTilesCache.BuildPathToTile(TileDest, GroupPath) )
		{
			`RedScreen("Unable to build a path to destination - "@GetFuncName()@" @ACHENG");
		}
	}
}

// Update me for AIGroup states.
function bool GetGroupMovePaths(vector GroupDestination, out array<PathingInputData> GroupPathData, out XGUnit LeaderVisualizerOut)
{
	local XComGameStateHistory History;
	local X2TacticalGameRuleset TacticalRules;
	local XGUnit UnitVisualizer;
	local TTile IdealTileDest, TileDest;
	local PathingInputData InputData;
	local int GroupProcessIndex;
	local XComGameState_Unit GroupMovingUnit, LeaderState;
	local GameRulesCache_Unit UnitActionsCache;
	local AvailableAction kAction;
	local name AbilityName;
	local bool bMoveActionAvailable;
	local array<TTile> ExclusionTiles, GroupPath;
	local array<int> LivingUnits;

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	GetLivingMembers(LivingUnits);

	if( LivingUnits.Length > 0 )
	{
		LeaderState = XComGameState_Unit(History.GetGameStateForObjectID(LivingUnits[0]));
		// always start by making sure the group path has been built
		ComputeGroupPath(GroupDestination, LivingUnits, GroupPath, LeaderVisualizerOut);

		//Only proceed if a valid move was possible
		if( GroupPath.Length > 0 )
		{
			//Setup the leader's input data
			InputData.MovingUnitRef = LeaderState.GetReference();
			InputData.MovementTiles = GroupPath;

			// Add the leader's path
			GroupPathData.AddItem(InputData);

			// add the leader's destination so the follower's don't end up on it
			ExclusionTiles.AddItem(GroupPath[GroupPath.Length - 1]);

			//Here, we make the assumption that group moving units follow the leader and will choose "group move" in their behavior tree if the
			//ability is available
			for( GroupProcessIndex = 1; GroupProcessIndex < LivingUnits.Length; ++GroupProcessIndex )
			{
				GroupMovingUnit = XComGameState_Unit(History.GetGameStateForObjectID(LivingUnits[GroupProcessIndex]));
				if( GroupMovingUnit == none )
				{
					continue; //Filter out invalid or unexpected errors in the game state or visualizers
				}

				UnitVisualizer = XGUnit(GroupMovingUnit.GetVisualizer());
				if( UnitVisualizer == none || UnitVisualizer.m_kBehavior == none )
				{
					continue; //Filter out invalid or unexpected errors in the game state or visualizers
				}

				//Setup the follower's input data
				InputData.MovingUnitRef = GroupMovingUnit.GetReference();

				//Now see if this unit can move - if so, set up their path
				if( TacticalRules.GetGameRulesCache_Unit(InputData.MovingUnitRef, UnitActionsCache) )
				{
					foreach UnitActionsCache.AvailableActions(kAction)
					{
						AbilityName = XComGameState_Ability(History.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID)).GetMyTemplateName();
						if( AbilityName == 'StandardMove' )
						{
							bMoveActionAvailable = kAction.AvailableCode == 'AA_Success';
							break;
						}
					}
				}

				if( bMoveActionAvailable )
				{
					// We have a valid follower: 
					// for the followers, compute a location in formation behind the leader and have them path there
					IdealTileDest = GetIdealFollowerDestinationTile(GroupMovingUnit, GroupProcessIndex, GroupPath);
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
					GroupPathData.AddItem(InputData);
				}
			}
			return GroupPathData.Length > 0;
		}
		else
		{
			`redscreenonce("Could not find a valid group move path for unit:"@LeaderState.ObjectID);
		}
	}
	return false;
}

// finds the ideal destination of the given follower unit
private function TTile GetIdealFollowerDestinationTile(XComGameState_Unit Unit, int UnitIndex, array<TTile> GroupPath)
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
	if( GroupPath.Length < 2 )
	{
		return Unit.TileLocation;
	}


	WorldData = `XWORLD;

	// figure out which side of the pathing line we are currently standing on. We'll try to have this unit
	// end up on the same side, since it looks strange and unnatural to have the units just crossing over
	// the main path line for no reason. This will also leave them in relatively the same positions relative 
	// to the leader at the end of the move.
	PathTile0 = GroupPath[0];
	PathTile1 = GroupPath[1];
	PathStartVector = WorldData.GetPositionFromTileCoordinates(PathTile1) - WorldData.GetPositionFromTileCoordinates(PathTile0);
	PathStartRightVector = PathStartVector cross vect(0, 0, 1);
	UnitLocation = WorldData.GetPositionFromTileCoordinates(Unit.TileLocation);
	UnitDotPathStart = PathStartRightVector dot(UnitLocation - WorldData.GetPositionFromTileCoordinates(PathTile0));

	// now decide how many tiles behind the leader this unit should go
	TilesBack = (UnitIndex - 1) / 2 + 1; // first two followers go one tile behind, next two go two tiles behind, etc.

	// now find our ideal destination tile. Fan out behind the leading unit using the parameters we just computed
	PathEndTile = GroupPath[GroupPath.Length - 1];
	PathOneFromEndTile = GroupPath[GroupPath.Length - 2];
	PathEndVector = WorldData.GetPositionFromTileCoordinates(PathEndTile) - WorldData.GetPositionFromTileCoordinates(PathOneFromEndTile);
	PathEndVector = Normal(PathEndVector);

	// get the offset from the end of the path to the side
	UnitPlacementVector = (PathEndVector cross vect(0, 0, 1)) * class'XComWorldData'.const.WORLD_StepSize * (UnitDotPathStart > 0 ? 1.0f : -1.0f);

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


function bool IsUnitEligibleForFallback(int UnitID, optional out StateObjectReference RetreatGroupRef)
{
	local XComGameState_Unit UnitState;
	local array<StateObjectReference> Overwatchers;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));

	if( !HasRetreatLocation(XGUnit(UnitState.GetVisualizer()), RetreatGroupRef) )
	{
		return false;
	}

	`LogAI("Found fallback group for unit"@UnitID@"at  group ID#"$RetreatGroupRef.ObjectID);

	if( UnitState != None )
	{
		if( FallbackExclusionList.Find(UnitState.GetMyTemplateName()) != INDEX_NONE )
		{
			`LogAI("Fallback failure: Ineligible for unit type: "$UnitState.GetMyTemplateName());
			return false;
		}
	}

	// Check if the number of overwatchers prevents fallback.
	class'X2TacticalVisibilityHelpers'.static.GetOverwatchingEnemiesOfTarget(UnitID, Overwatchers);
	if( Overwatchers.Length > FallbackMaximumOverwatchCount )
	{
		`LogAI("Fallback failure: Exceeded maximum overwatch count. Overwatcher count ="@Overwatchers.Length);
		return false;
	}

	// Check if under suppression.  
	if( UnitState.IsUnitAffectedByEffectName(class'X2Effect_Suppression'.default.EffectName) )
	{
		`LogAI("Fallback failure: Unit is being suppressed.");
		return false;
	}

	// Retreat cap - total number of retreats in this mission has reached the retreat cap (specified in AIPlayerData).
	if( HasHitRetreatCap() )
	{
		`LogAI("Fallback failure: Reached retreat cap!");
		return false;
	}

	return true;
}

function bool AIBTFindAbility(string AbilityName, bool bRefreshAbilityCache=false, optional out XGAIBehavior MemberBehavior)
{
	local AvailableAction kAbility;
	local string strError;
	local array<int> GroupUnitIDs;
	local int UnitID;
	local XGUnit MemberUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	if (GetLivingMembers(GroupUnitIDs))
	{
		foreach GroupUnitIDs(UnitID)
		{
			MemberUnit = XGUnit(History.GetVisualizer(UnitID));
			if (MemberUnit != None && MemberUnit.m_kBehavior != None)
			{
				MemberBehavior = MemberUnit.m_kBehavior;
				if ( bRefreshAbilityCache )
				{
					MemberBehavior.RefreshUnitCache();
				}
				kAbility = MemberBehavior.GetAvailableAbility(AbilityName, , strError);
				if (kAbility.AbilityObjectRef.ObjectID > 0)
				{
					`LogAIBT("GroupState::FindAbility succeeded with unit# "$UnitID);
					return true;
				}
				`LogAIBT("Unit# "$UnitID@ ":"$strError);
			}
		}
	}
	return false;
}

defaultproperties
{
	bTacticalTransient=true
	RevealInstigatorUnitObjectID = -1
	FinalVisibilityMovementStep = -1
	TurnCountForLastDestination = -100
	FallbackMaximumOverwatchCount = 1;
}
