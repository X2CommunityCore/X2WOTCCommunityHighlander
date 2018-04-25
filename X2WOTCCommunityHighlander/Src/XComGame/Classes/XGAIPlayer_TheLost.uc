//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGAIPlayer_TheLost.uc    
//  AUTHOR:  Dan Kaplan  --  7/27/2016
//  PURPOSE: For spawning and controlling The Lost behaviors
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XGAIPlayer_TheLost extends XGAIPlayer
	native(AI)
	dependson(XGGameData)
	config(AI);

////////////////////////////////////////////////////////////////////////////////////////
// AI data for handling the Lost.  Used to track AI decisions between BT runs- not saved.

// Lost Keeps track of last PlayerTurnCount it moved toward a target enemy.
var private native Map_Mirror       LostAILastMove{TMap<INT, INT>};        //  maps Group id to last turn moved value.
var int LastTargetInitTurn;
var int CurrentAttackTargetIndex;

var config float DistributionPercentToXCom; // Percent of lost units per group to attack XCom. Remainder attacks active AI.


struct native TargetAssignment
{
	var int TargetID;
	var TTile TargetLocation; // For sounds.  Not yet in use.
	var array<int> AssignedUnitIDs;
};
var array<TargetAssignment> LostAITargetAssignments;

struct native MoveAssignment
{
	var int MoverID;
	var TTile Destination;
};
var array<MoveAssignment> LostAIMoveAssignments;

struct native AttackAssignment
{
	var int AttackerID;
	var AvailableTarget SelectedTarget;
	var ActionSelection SelectAction;
};

var array<AttackAssignment> LostAIAttackAssignments;
var array<AttackAssignment> LostAvailableAttackActions;

struct native VisibleEnemyDistanceList
{
	var XComGameState_Unit MemberState;
	var init array<int> EnemyList;
	var init array<float> DistanceList;
};

const LOST_TARGET_ASSIGNMENT_QUOTA = 2;
const MAIN_LOST_GROUP_ID = 'THE_LOST_GROUP';
const ATTACK_UNSET = 0;
const ATTACK_XCOM = 1;
const ATTACK_AI = 2;
const ATTACK_RESISTANCE = 3;
const ATTACK_ASSIGNMENT_NAME = 'TeamAssignment';

var array<X2Condition> LostEnemyFilter;
var array<Name> GroupEffectExclusions;

// Keep track of which lost units we cleared the tile blocking data on, so we know which ones we still need to restore.
var array<int> ClearedBlockingIDs;
var array<TTile> CurrTileOccupancy; // Keep track of currently-occupied tiles, to avoid pathing to these in case a lost unit chooses to stay put.

var int SimultaneousMoveVisIndex;
var int SimultaneousMoveGroupStateObjectId;

// This function returns a list of sorted distances of visible enemies around us.  Used to help distribute lost units, to the closest enemy first, then randomly for the rest.
native function GetVisibleDistanceMatrix(out array<VisibleEnemyDistanceList> DistanceMatrix, array<XComGameState_Unit> Members, array<X2Condition> RequiredConditions, array<StateObjectReference> VisibleEnemies);

// Each group tracks when the last time they initiated a move, so other units in the group don't clear the already-initialized data.
native function SetLastMoveTurn(int GroupObjectID, int Turn);
native function int GetLastMoveTurn(int GroupObjectID);

function bool HasGroupAlreadyMovedThisTurn(int GroupObjectID)
{
	local XComGameState_Player PlayerState;
	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	return 	(GetLastMoveTurn(GroupObjectID) >= PlayerState.PlayerTurnCount);
}

// Apply all selected LOST attack abilities against an individual target.
function LostActivateAttacks()
{
	local array<ActionSelection> SelectedAbilities;
	local ActionSelection SelectAction;
	local AttackAssignment Attack;

	foreach LostAIAttackAssignments(Attack)
	{
		SelectAction = Attack.SelectAction;
		SelectedAbilities.AddItem(SelectAction);
	}

	if( SelectedAbilities.Length > 0 )
	{
		class'XComGameStateContext_Ability'.static.ActivateAbilityList(SelectedAbilities,,true);
	}
	else
	{
		`RedScreen(GetFuncName()@ "error - acheng");
		`LogAI("Error - attempted to activate lost attacks, but nothing was queued up.");
	}
	LostAIAttackAssignments.Length = 0;
}

function LostAcivationCallback(XComGameState ResultState)
{
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;

	History = `XCOMHISTORY;
		
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(ObjectID));
	SetLastMoveTurn(SimultaneousMoveGroupStateObjectId, PlayerState.PlayerTurnCount);
	LostAIMoveAssignments.Length = 0;
	SimultaneousMoveVisIndex = INDEX_NONE;
}


// Activate all LOST movement abilities to all preselected destinations.
function LostActivateMove( XComGameState_AIGroup GroupState )
{
	local array<TTile> DestinationList;
	local array<XComGameState_Unit> MoverList;
	local MoveAssignment Move;
	local XComGameState_Unit Mover;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach LostAIMoveAssignments(Move)
	{
		Mover = XComGameState_Unit(History.GetGameStateForObjectID(Move.MoverID));
		MoverList.AddItem(Mover);
		DestinationList.AddItem(Move.Destination);
	}
	SimultaneousMoveVisIndex = History.GetNumGameStates();
	SimultaneousMoveGroupStateObjectId = GroupState.ObjectID;
	GroupState.MoveGroupMembersToPoints(MoverList, DestinationList, true, LostAcivationCallback);

}

// Lost units should always be moving simultaneously.
function GetSimultaneousMoveVisualizeIndex(XComGameState_Unit UnitState, XGUnit UnitVisualizer,
	out int OutVisualizeIndex, out int bInsertFenceAfterMove)
{
	local XGAIBehavior kBehavior;

	super.GetSimultaneousMoveVisualizeIndex(UnitState, UnitVisualizer, OutVisualizeIndex, bInsertFenceAfterMove);
	// BT Simultaneous movement only if from the lost player's turn.
	// Skip this if activated from Burning effect.
	if (OutVisualizeIndex == INDEX_NONE && UnitVisualizer != None && !UnitVisualizer.m_kBehavior.bBTInitiatedFromEffect)
	{
		OutVisualizeIndex = SimultaneousMoveVisIndex;
		if (OutVisualizeIndex == INDEX_NONE)
		{
			//Get the decision start index for the currently running unit on the player
			kBehavior = XGUnit(`XCOMHISTORY.GetVisualizer(CurrentMoveUnit.UnitObjectRef.ObjectID)).m_kBehavior;
			`Assert(kBehavior != None);

			if (kBehavior != None)
			{
				OutVisualizeIndex = kBehavior.DecisionStartHistoryIndex + 1;
			}
			else
			{
				`RedScreen("No active lost unit behavior? @acheng");
				OutVisualizeIndex = UnitVisualizer.m_kBehavior.DecisionStartHistoryIndex + 1;
			}
		}
	}
}

function bool HasLostAttackAssignments(XComGameState_AIGroup GroupState)
{
	local array<int> IDs;
	local int ID;
	if( LostAIAttackAssignments.Length > 0 )
	{ 
		GroupState.GetLivingMembers(IDs);
		foreach IDs(ID)
		{
			if( LostAIAttackAssignments.Find('AttackerID', ID) != INDEX_NONE )
			{
				return true;
			}
		}
	}
	return false;
}

function bool HasLostMoveAssignments( XComGameState_AIGroup GroupState)
{
	local array<int> IDs;
	local int ID;
	if( LostAIMoveAssignments.Length > 0 )
	{
		GroupState.GetLivingMembers(IDs);
		foreach IDs(ID)
		{
			if( LostAIMoveAssignments.Find('MoverID', ID) != INDEX_NONE )
			{
				return true;
			}
		}
	}
	return false;
}

function AddGroupEffectExclusion(Name EffectName)
{
	if ( GroupEffectExclusions.Find(EffectName) == INDEX_NONE)
	{
		GroupEffectExclusions.AddItem(EffectName);
	}
}


// This function checks if this lost group has already done their mass move.  If so, fail.  
// Otherwise distribute the members among all visible targets to each. Then assign destinations.
function bool InitLostGroupMove(XGUnit SourceUnit, XComGameState_AIGroup MyGroupState, bool bScamperMove)
{
	local XComGameState_Player PlayerState;
	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));

	// Check if the last AI lost move was before this turn started.  If so, proceed to assign destinations.
	if( bScamperMove || !HasGroupAlreadyMovedThisTurn(MyGroupState.ObjectID) )
	{
		LostAITargetAssignments.Length = 0;
		LostAIMoveAssignments.Length = 0;
		ClearedBlockingIDs.Length = 0; 
		CurrTileOccupancy.Length = 0;

		ClearTileBlocking(SourceUnit, MyGroupState);

		DistributeLostUnitsAmongTargets(MyGroupState); // Also restore blocking on units that won't move.

		AssignLostUnitDestinations(); // Also restore blocking on units that haven't moved.

		SetLastMoveTurn(MyGroupState.ObjectID, PlayerState.PlayerTurnCount);
		return HasLostMoveAssignments(MyGroupState);
	}
	else
	{
		`LogAIBT("HasGroupAlreadyMovedThisTurn fn returned true.");
	}
	return false;
}

function ClearTileBlocking(XGUnit SourceUnit, XComGameState_AIGroup MyGroupState)
{
	local XComGameState_Unit MemberState;
	local array<XComGameState_Unit> MemberStates;
	local array<int> IDs;
	local XComWorldData XWorld;
	XWorld = `XWORLD;
	if (GetGroupMoveUnitList(IDs, MemberStates, MyGroupState))
	{
		foreach MemberStates(MemberState)
		{
			XWorld.ClearTileBlockedByUnitFlag(MemberState);
			ClearedBlockingIDs.AddItem(MemberState.ObjectID);
			CurrTileOccupancy.AddItem(MemberState.TileLocation);
		}
		SourceUnit.m_kReachableTilesCache.ForceCacheUpdate();
	}
}

// Get list of living units that should group move together, barring active Howlers and units with effects that prevent group movement.
function bool GetGroupMoveUnitList(out array<int> IDs, out array<XComGameState_Unit> MemberStates, XComGameState_AIGroup GroupState )
{
	local int MemberIndex;

	GroupState.GetLivingMembers(IDs, MemberStates);
	for (MemberIndex = MemberStates.Length - 1; MemberIndex >= 0; --MemberIndex)
	{
		if (!IsValidGroupMoveUnit(MemberStates[MemberIndex]))
		{
			IDs.RemoveItem(MemberStates[MemberIndex].ObjectID);
			MemberStates.Remove(MemberIndex, 1);
		}
	}
	return MemberStates.Length > 0;
}

// Active howlers and burning units are excluded from moving with the mass group move.
function bool IsValidGroupMoveUnit(XComGameState_Unit UnitState)
{
	local Name EffectName;

	// Prevent active howlers with a valid howl ability from moving with the group.
	if (!UnitState.IsUnrevealedAI() 
		&& UnitState.GetMyTemplate().AIOrderPriority > class'X2CharacterTemplate'.default.AIOrderPriority 
		&& !UnitState.IsUnrevealedAI()) // Only pull unalerted howlers.
	{
		if ( IsActiveHowler(XGUnit(UnitState.GetVisualizer())) )
		{
			return false; // Howlers 
		}
	}
	foreach GroupEffectExclusions(EffectName)
	{
		if (UnitState.IsUnitAffectedByEffectName(EffectName))
		{
			return false;
		}
	}
	return true;
}
// Insert members onto either team AI or team XCom for attacking distribution.
function InitTeamAssignments(array<int> MemberIDs)
{
	local int NumXComAttackers, IDIndex, NumMembers, MemberIndex;
	local array<XComGameState_Unit> Unassigned;
	local XComGameStateHistory History;
	local XComGameState_Unit MemberState;
	local XComGameState NewGameState;
	local eTeam TargetTeam;

	// First check if the units are already assigned.
	History = `XCOMHISTORY;
	foreach MemberIDs(IDIndex)
	{
		MemberState = XComGameState_Unit(History.GetGameStateForObjectID(IDIndex));
		if (IsValidGroupMoveUnit(MemberState))
		{
			TargetTeam = GetTargetTeamForLostUnit(MemberState);
			if (TargetTeam == eTeam_None)
			{
				Unassigned.AddItem(MemberState);
			}
		}
	}

	// Simple distribution - first % attack XCom, rest attack AI.
	NumMembers = Unassigned.Length;
	if (NumMembers > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Assign TheLost target enemy team");
		NumXComAttackers = Round(float(NumMembers) * (DistributionPercentToXCom / 100.0f));

		for (MemberIndex = 0; MemberIndex < NumMembers; ++MemberIndex)
		{
			if (MemberIndex < NumXComAttackers)
			{
				SetTeamAssignment(Unassigned[MemberIndex], eTeam_XCom, NewGameState);
			}
			else
			{
				SetTeamAssignment(Unassigned[MemberIndex], eTeam_Alien, NewGameState);
			}
		}
		if (!`TACTICALRULES.SubmitGameState(NewGameState))
		{
			`RedScreen("Error submitting team assignments for Lost units!");
		}
	}
}

static function eTeam GetTargetTeamForLostUnit(XComGameState_Unit UnitState)
{
	local UnitValue TeamAssignmentValue;
	if (UnitState.GetUnitValue(const.ATTACK_ASSIGNMENT_NAME, TeamAssignmentValue))
	{
		if (TeamAssignmentValue.fValue == ATTACK_AI)
		{
			return eTeam_Alien;
		}
		else if (TeamAssignmentValue.fValue == ATTACK_XCOM)
		{
			return eTeam_XCom;
		}
		else if (TeamAssignmentValue.fValue == ATTACK_RESISTANCE)
		{
			return eTeam_Resistance;
		}
	}
	return eTeam_None;
}

function DistributeLostUnitsAmongTargets(XComGameState_AIGroup MyGroupState)
{
	local array<VisibleEnemyDistanceList> DistanceMatrix, Unassigned;
	local VisibleEnemyDistanceList DistancesInfo;
	local array<int> MemberIDs;
	local array<XComGameState_Unit> MemberStates;
	local TargetAssignment Assignment;
	local int TargetID, AssignmentIndex, RandIndex;
	local bool bAssigned, bTargetsAI, bTargetIsAI;
	local float MeleeRange;
	local array<StateObjectReference> XComEnemies;
	local array<StateObjectReference> AIEnemies;
	local array<StateObjectReference> VisibleEnemies;
	local array<StateObjectReference> PriorityTargets;
	local XComGameState_Unit EnemyState;
	local XComWorldData XWorld;
	local XComGameStateHistory History;
	XWorld = `XWORLD;
	History = `XCOMHISTORY;

	LostAITargetAssignments.Length = 0;

	MeleeRange = `METERSTOUNITS_SQ(class'XComWorldData'.const.WORLD_Melee_Range_Meters);
	// Design spec: if enemies are visible, the lost will randomly choose which enemy to approach.
	//  Every Lost turn, the Lost will reevaluate their target. If an enemy is visible, and not 
	//  currently being engaged by a Lost, and the Lost's current target is engaged by multiple Lost, 
	// then the Lost has a high chance to move on to the unengaged target. This chance increases with 
	// every Lost engaging the current target.

	// First pass - assign units to nearest target.
	if (!GetGroupMoveUnitList(MemberIDs, MemberStates, MyGroupState))
	{
		return;
	}

	// Set team assignments if not already assigned.
	InitTeamAssignments(MemberIDs);

	// Only attack Aliens if they're active.   Also, prioritize units with the UltrasonicLure effect on them.
	foreach History.IterateByClassType(class'XComGameState_Unit', EnemyState, eReturnType_Reference)
	{
		if (EnemyState.IsUnitAffectedByEffectName(class'X2StatusEffects'.default.UltrasonicLureName))
		{
			PriorityTargets.AddItem(EnemyState.GetReference());
		}
		if (EnemyState.GetTeam() == eTeam_XCom 
			&& !EnemyState.IsConcealed() // Update - do not attack concealed XCom units.
			&& !EnemyState.GetMyTemplate().bIsCosmetic 
			&& EnemyState.IsAlive() 
			&& !EnemyState.IsIncapacitated()
			&& !EnemyState.bRemovedFromPlay)
		{
			XComEnemies.AddItem(EnemyState.GetReference());
			VisibleEnemies.AddItem(EnemyState.GetReference());
		}
		else if (EnemyState.GetTeam() == eTeam_Alien 
			&& EnemyState.IsAlive() 
			&& !EnemyState.IsUnrevealedAI()
			&& !EnemyState.bRemovedFromPlay ) // Only attack active AI.
		{
			// Only allow chosen to be attacked if in the engaged state.
			if (EnemyState.IsChosen() && !EnemyState.IsEngagedChosen())
			{
				continue;
			}
			AIEnemies.AddItem(EnemyState.GetReference());
			VisibleEnemies.AddItem(EnemyState.GetReference());
		}
	}

	// If we have priority targets, all LOST units will attack only them.
	if (PriorityTargets.Length > 0)
	{
		AIEnemies = PriorityTargets;
		XComEnemies.Length = 0;
		VisibleEnemies = PriorityTargets;
	}

	GetVisibleDistanceMatrix(DistanceMatrix, MemberStates, LostEnemyFilter, VisibleEnemies);

	foreach DistanceMatrix(DistancesInfo)
	{
		if (!IsValidGroupMoveUnit(DistancesInfo.MemberState))
		{
			continue;
		}

		bAssigned = false;
		if ( XComEnemies.Length > 0 )
		{
			bTargetsAI = GetTargetTeamForLostUnit(DistancesInfo.MemberState) == eTeam_Alien;
		}
		else
		{
			bTargetsAI = true;
		}

		if( DistancesInfo.EnemyList.Length > 0 )
		{
			// If this unit already has an attack target, skip. Don't move units that can already attack.
			if( DistancesInfo.DistanceList[0] <= MeleeRange )
			{
				bAssigned = true;
				// Restore blocked tiles for units already in range.  They will not move.
				XWorld.SetTileBlockedByUnitFlag(DistancesInfo.MemberState);
				ClearedBlockingIDs.RemoveItem(DistancesInfo.MemberState.ObjectID);
				TargetID = DistancesInfo.EnemyList[0];
				// Still need this target to be assign to this unit, for the attack step.
				AssignmentIndex = LostAITargetAssignments.Find('TargetID', TargetID);
				if( AssignmentIndex == INDEX_NONE )
				{
					Assignment.AssignedUnitIDs.Length = 0;
					Assignment.AssignedUnitIDs.AddItem(DistancesInfo.MemberState.ObjectID);
					Assignment.TargetID = TargetID;
					LostAITargetAssignments.AddItem(Assignment);
				}
				else
				{
					LostAITargetAssignments[AssignmentIndex].AssignedUnitIDs.AddItem(DistancesInfo.MemberState.ObjectID);
				}
				continue;
			}
			// Assign members to targets, closest first, until we hit our quotas.  Then randomly for the rest.
			foreach DistancesInfo.EnemyList(TargetID)
			{
				// First pass at enemies only looks at the assigned team.
				bTargetIsAI = (AIEnemies.Find('ObjectID', TargetID) != INDEX_NONE);
				`Assert( bTargetIsAI == (XComEnemies.Find('ObjectID', TargetID) == INDEX_NONE) );
				if (bTargetsAI != bTargetIsAI)
				{
					continue;
				}
				AssignmentIndex = LostAITargetAssignments.Find('TargetID', TargetID);
				if( AssignmentIndex == INDEX_NONE )
				{
					Assignment.AssignedUnitIDs.Length = 0;
					Assignment.AssignedUnitIDs.AddItem(DistancesInfo.MemberState.ObjectID);
					Assignment.TargetID = TargetID;
					LostAITargetAssignments.AddItem(Assignment);
					bAssigned = true;
					break;
				}
				else
				{
					if( LostAITargetAssignments[AssignmentIndex].AssignedUnitIDs.Length < LOST_TARGET_ASSIGNMENT_QUOTA )
					{
						LostAITargetAssignments[AssignmentIndex].AssignedUnitIDs.AddItem(DistancesInfo.MemberState.ObjectID);
						bAssigned = true;
						break;
					}
				}
			}
			if (!bAssigned)
			{
				// Repeat previous loop, this time without worrying about the team designation.
				foreach DistancesInfo.EnemyList(TargetID)
				{
					AssignmentIndex = LostAITargetAssignments.Find('TargetID', TargetID);
					if (AssignmentIndex == INDEX_NONE)
					{
						Assignment.AssignedUnitIDs.Length = 0;
						Assignment.AssignedUnitIDs.AddItem(DistancesInfo.MemberState.ObjectID);
						Assignment.TargetID = TargetID;
						LostAITargetAssignments.AddItem(Assignment);
						bAssigned = true;
						break;
					}
					else
					{
						if (LostAITargetAssignments[AssignmentIndex].AssignedUnitIDs.Length < LOST_TARGET_ASSIGNMENT_QUOTA)
						{
							LostAITargetAssignments[AssignmentIndex].AssignedUnitIDs.AddItem(DistancesInfo.MemberState.ObjectID);
							bAssigned = true;
							break;
						}
					}
				}
			}
			if( !bAssigned )
			{
				Unassigned.AddItem(DistancesInfo);
			}
		}
	}

	// Remainder of unassigned units are randomly assigned.
	foreach Unassigned(DistancesInfo)
	{
		RandIndex = `SYNC_RAND(DistancesInfo.EnemyList.Length);
		TargetID = DistancesInfo.EnemyList[RandIndex];
		AssignmentIndex = LostAITargetAssignments.Find('TargetID', TargetID);
		`Assert( AssignmentIndex != INDEX_NONE );
		LostAITargetAssignments[AssignmentIndex].AssignedUnitIDs.AddItem(DistancesInfo.MemberState.ObjectID);
	}
}

function AssignLostUnitDestinations()
{
	local TargetAssignment Assignment;
	local array<TTile> ValidAttackTiles, ReservedTiles;
	local XGAIBehavior Behavior;
	local XGUnit UnitVis;
	local XComGameStateHistory History;
	local TTile Tile;
	local XComGameState_Unit TargetState, MemberState;
	local int AssignedID;
	local MoveAssignment Move;
	local XComWorldData XWorld;
	local int TileIndex, iUnitNumber, LostPathFailures, LostPathSuccess;
	local array<int> UnitsBlockingAlternateTiles;
	History = `XCOMHISTORY;
	XWorld = `XWORLD;
	ReservedTiles.Length = 0;
	ReservedTiles = CurrTileOccupancy; // Avoid moving into a tile currently occupied by TheLost, in case a unit doesn't move.
	foreach LostAITargetAssignments(Assignment)
	{
		if( Assignment.AssignedUnitIDs.Length > 0 )
		{
			ValidAttackTiles.Length = 0;
			TargetState = XComGameState_Unit(History.GetGameStateForObjectID(Assignment.TargetID));
			class'Helpers'.static.FindTilesForMeleeAttack(TargetState, ValidAttackTiles);
			iUnitNumber = 0;
			foreach Assignment.AssignedUnitIDs(AssignedID)
			{
				if ( ClearedBlockingIDs.Find(AssignedID) == INDEX_NONE )
				{
					continue; // already in melee range - do not attempt to move from here.
				}
				MemberState = XComGameState_Unit(History.GetGameStateForObjectID(AssignedID));
				UnitVis = XGUnit(History.GetVisualizer(AssignedID));
				Behavior = UnitVis.m_kBehavior;
				if (Behavior != None)
				{
					if (Behavior.FindGroupDestinationToward(TargetState, Tile, ValidAttackTiles, ReservedTiles, iUnitNumber++))
					{
						`LogAI("FindGroupDestinationToward(..) on Unit"@AssignedID@ "returned ("$Tile.X@Tile.Y@Tile.Z$")");
						// Remove this unit's current tile location from the reserved tiles list.
						TileIndex = class'Helpers'.static.FindTileInList(MemberState.TileLocation, ReservedTiles);
						if (TileIndex != INDEX_NONE)
						{
							ReservedTiles.Remove(TileIndex, 1);
						}

						Move.MoverID = AssignedID;
						Move.Destination = Tile;
						LostAIMoveAssignments.AddItem(Move);
						XWorld.SetTileBlockedByUnitFlagAtLocation(MemberState, Tile);
						ClearedBlockingIDs.RemoveItem(AssignedID);
						UnitsBlockingAlternateTiles.AddItem(AssignedID);
						LostPathSuccess++;
					}
					else
					{
						LostPathFailures++;
					}
				}
			}
		}
	}
	`LogAI("XGAIPlayer_TheLost::AssignLostUnitDestinations - Lost Pathing Failures = "$LostPathFailures@ "/" @LostPathFailures+LostPathSuccess);
	// Remaining unassigned units need to reset their blocking, since it was cleared at the start.
	foreach ClearedBlockingIDs(AssignedID)
	{
		MemberState = XComGameState_Unit(History.GetGameStateForObjectID(AssignedID));
		XWorld.SetTileBlockedByUnitFlag(MemberState);
	}
	ClearedBlockingIDs.Length = 0;
	// Reset all blocking based on where the units actually are, instead of where they will be.
	foreach UnitsBlockingAlternateTiles(AssignedID)
	{
		MemberState = XComGameState_Unit(History.GetGameStateForObjectID(AssignedID));
		XWorld.SetTileBlockedByUnitFlag(MemberState);
	}
}

function bool LostAttackNextTarget(XComGameState_AIGroup MyGroupState)
{
	local TargetAssignment Target;
	// Step through each possible target until we find one that has valid attackers.
	while( LostUpdateNextTarget(MyGroupState) )
	{
		Target = LostAITargetAssignments[CurrentAttackTargetIndex];
		// Check if any of the assigned units can attack this target.
		if( GetTargetAttackAssignments(Target) )
		{
			return true;
		}
	}
	return false;
}

function bool GetTargetAttackAssignments(TargetAssignment Target)
{
	local AttackAssignment Assignment;
	local int AttackerID, Index, iTarget;
	local AvailableAction AvailableAttack;
	local AvailableTarget AttackTargetOption;

	LostAIAttackAssignments.Length = 0;
	foreach Target.AssignedUnitIDs(AttackerID)
	{
		Index = LostAvailableAttackActions.Find('AttackerID', AttackerID);
		if( Index != INDEX_NONE )
		{
			AvailableAttack = LostAvailableAttackActions[Index].SelectAction.PerformAction;
			for( iTarget = 0; iTarget < AvailableAttack.AvailableTargets.Length; iTarget++ )
			{
				AttackTargetOption = AvailableAttack.AvailableTargets[iTarget];
				if( AttackTargetOption.PrimaryTarget.ObjectID == Target.TargetID )
				{
					Assignment.AttackerID = AttackerID;
					Assignment.SelectAction.PerformAction = AvailableAttack;
					Assignment.SelectAction.AvailableTargetsIndex = iTarget;
					Assignment.SelectedTarget = AttackTargetOption;
					LostAIAttackAssignments.AddItem(Assignment);
				}
			}
		}
	}
	return LostAIAttackAssignments.Length > 0;
}

function bool LostUpdateNextTarget(XComGameState_AIGroup MyGroupState)
{
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	if( LastTargetInitTurn < PlayerState.PlayerTurnCount )
	{
		InitLostAttackTargets(MyGroupState);
	}
	CurrentAttackTargetIndex++;
	if( CurrentAttackTargetIndex >= LostAITargetAssignments.Length )
	{
		return false;
	}
	return true;
}

function InitLostAttackTargets( XComGameState_AIGroup MyGroupState)
{
	local XGUnit MemberUnitVis;
	local XGAIBehavior MemberBehavior;
	local array<XComGameState_Unit> MemberStates;
	local XComGameState_Unit MemberState;
	local array<int> MemberIDs;
	local AvailableAction AttackAction;
	local AttackAssignment AttackOption;
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	LastTargetInitTurn = PlayerState.PlayerTurnCount;
	CurrentAttackTargetIndex = INDEX_NONE;
	LostAvailableAttackActions.Length = 0;

	if (GetGroupMoveUnitList(MemberIDs, MemberStates, MyGroupState))
	{
		foreach MemberStates(MemberState)
		{
			MemberUnitVis = XGUnit(MemberState.GetVisualizer());
			MemberBehavior = MemberUnitVis.m_kBehavior;
			MemberBehavior.InitUnitAbilityInfo(); // Refreshes ability cache if dirty.
			AttackAction = MemberBehavior.FindAbilityByName('LostAttack');
			if (AttackAction.AvailableCode == 'AA_Success')
			{
				AttackOption.AttackerID = MemberState.ObjectID;
				AttackOption.SelectAction.PerformAction = AttackAction;
				LostAvailableAttackActions.AddItem(AttackOption);
			}
		}
	}
}

static function UpdateLostOnPlayerTurnEnd()
{
	local XComGameStateHistory History;
	local XComGameState_AIGroup LostGroup;
	local array<XComGameState_AIGroup> GroupsToAdd;
	History = `XCOMHISTORY;

	// Any lost groups that have already revealed but not already part of the main lost group need to merge.
	foreach History.IterateByClassType(class'XComGameState_AIGroup', LostGroup, eReturnType_Reference)
	{
		if (LostGroup.EncounterID == class'XGAIPlayer_TheLost'.const.MAIN_LOST_GROUP_ID || LostGroup.TeamName != eTeam_TheLost)
		{
			continue;
		}

		if ( LostGroup.bProcessedScamper )
		{
			GroupsToAdd.AddItem(LostGroup);
		}
	}

	foreach GroupsToAdd(LostGroup)
	{
		class'XGAIPlayer_TheLost'.static.AddToMainLostGroup(LostGroup);
	}
}

static function AddToMainLostGroup(XComGameState_AIGroup MyGroupState)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_AIPlayerData AIPlayerDataState;
	local StateObjectReference GroupReference;
	local XComGameState_AIGroup PreviousAIGroupState, NewGroupState, AIGroupState;
	local X2TacticalGameRuleset Rules;
	local array<XComGameState_Unit> Members;
	local array<int> IDs;
	local XGUnit Unit;
	
	if( MyGroupState.bShouldRemoveFromInitiativeOrder ) // This group has already been processed.
	{
		return;
	}
	History = `XCOMHISTORY;
	Rules = `TACTICALRULES;
	AIPlayerDataState = XComGameState_AIPlayerData(History.GetSingleGameStateObjectForClass(class'XComGameState_AIPlayerData', false));

	// find the Lost group.
	foreach AIPlayerDataState.GroupList(GroupReference)
	{
		AIGroupState = XComGameState_AIGroup(History.GetGameStateForObjectID(GroupReference.ObjectID));
		if( AIGroupState.EncounterID == class'XGAIPlayer_TheLost'.const.MAIN_LOST_GROUP_ID )
		{
			break;
		}
		else
		{
			AIGroupState = none;
		}
	}

	// Create one if DNE
	if( AIGroupState == none )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIGROUP:: Create Main Lost Group()");

		// create the new group state
		NewGroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
		NewGroupState.EncounterID = class'XGAIPlayer_TheLost'.const.MAIN_LOST_GROUP_ID;
		NewGroupState.TeamName = MyGroupState.TeamName;
		NewGroupState.bProcessedScamper = true;
		AIGroupState = NewGroupState;

		// add the group state to the ai data
		AIPlayerDataState = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', AIPlayerDataState.ObjectID));
		AIPlayerDataState.GroupList.AddItem(NewGroupState.GetReference());

		Rules.AddGroupToInitiativeOrder(NewGroupState, NewGameState);

		if( !Rules.SubmitGameState(NewGameState) )
		{
			`RedScreen("Error creating new group state from console in CreateAIGroup()");
		}
	}

	// create a the new state info
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIGROUP::Transfer to Main Lost Group - Step 1");
	NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', AIGroupState.ObjectID));
	PreviousAIGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', MyGroupState.ObjectID));

	// Move the members from the old to the new.
	MyGroupState.GetLivingMembers(IDs, Members);

	foreach Members(UnitState)
	{
		Unit = XGUnit(UnitState.GetVisualizer());
		Unit.m_kBehavior.bLostScampered = true;
		PreviousAIGroupState.RemoveUnitFromGroup(UnitState.ObjectID, NewGameState);
		NewGroupState.AddUnitToGroup(UnitState.ObjectID, NewGameState);
	}

	Rules.RemoveGroupFromInitiativeOrder(PreviousAIGroupState, NewGameState);
	PreviousAIGroupState.bProcessedScamper = true;

	if( !Rules.SubmitGameState(NewGameState) )
	{
		`RedScreen("Error transferring old Lost group to New group state from "@GetFuncName());
	}

	// and update all the group associations.
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIGROUP: Transfer to main lost group - Step 2");
	AIPlayerDataState = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', AIPlayerDataState.ObjectID));
	if( !Rules.SubmitGameState(NewGameState) )
	{
		`RedScreen("Error creating new group associations from "@GetFuncName());
	}
}

// Return true if the Unit is a Howler unit who hasn't used his Howl ability.
static function bool IsActiveHowler(XGUnit UnitVis)
{
	local XComGameState_Ability HowlAbility;
	local array<Name> ErrorList;

	UnitVis.m_kBehavior.RefreshUnitCache();
	UnitVis.m_kBehavior.FindAbilityByName('LostHowlerAbility', HowlAbility);
	// Check for howler ability.
	if (HowlAbility != None)
	{
		ErrorList = HowlAbility.GetAvailabilityErrors(UnitVis.m_kBehavior.UnitState);
		 // Check Howler ability to see if this ability has already been used.
		if (ErrorList.Find('AA_CannotAfford_Charges') == INDEX_NONE)
		{
			return true;
		}
	}
	return false;

}

static function SetTeamAssignment(XComGameState_Unit UnitState, eTeam TargetTeam, XComGameState NewGameState)
{
	local XComGameState_Unit NewUnitState;
	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
	if (TargetTeam == eTeam_XCom)
	{
		NewUnitState.SetUnitFloatValue(const.ATTACK_ASSIGNMENT_NAME, ATTACK_XCOM, eCleanup_BeginTactical );
	}
	else if (TargetTeam == eTeam_Alien)
	{
		NewUnitState.SetUnitFloatValue(const.ATTACK_ASSIGNMENT_NAME, ATTACK_AI, eCleanup_BeginTactical );
	}
	else if (TargetTeam == eTeam_Resistance)
	{
		NewUnitState.SetUnitFloatValue(const.ATTACK_ASSIGNMENT_NAME, ATTACK_RESISTANCE, eCleanup_BeginTactical );
	}
	else
	{
		`RedScreen("Error - Lost Unit was not preassigned a target team to attack. Now set to attack team XCom @ACHENG");
		NewUnitState.SetUnitFloatValue(const.ATTACK_ASSIGNMENT_NAME, ATTACK_XCOM, eCleanup_BeginTactical );
	}
}

defaultproperties
{
	Begin Object Class=X2Condition_Visibility Name=DefaultGameplayVisibilityCondition
	bRequireLOS=TRUE
	bRequireBasicVisibility=TRUE
	bRequireGameplayVisible=TRUE
	End Object
	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingHostileTargetProperty
	ExcludeAlive=false
	ExcludeDead=true
	ExcludeFriendlyToSource=true
	ExcludeHostileToSource=false
	TreatMindControlledSquadmateAsHostile=true
	ExcludeUnrevealedAI=true
	End Object
	LostEnemyFilter(0)=DefaultGameplayVisibilityCondition
	LostEnemyFilter(1)=DefaultLivingHostileTargetProperty

	LastTargetInitTurn=-1;

	m_eTeam = eTeam_TheLost
}
