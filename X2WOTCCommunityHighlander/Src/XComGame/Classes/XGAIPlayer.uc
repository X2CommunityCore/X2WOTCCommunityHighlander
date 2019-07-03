class XGAIPlayer extends XGPlayer
	native(AI)
	config(AI);

struct native reinforcements_info
{
	var bool bUnavailable;
	var int iCountdown;
	var int iCooldown;
	var int iCallerID; // Unit who called in reinforcements. 

	structdefaultproperties
	{
		bUnavailable=false
		iCountdown=-1
		iCooldown=0
	}
};

var bool m_bSkipAI; // For debugging/testing

// List of visible enemies, updated at start of AI turn and after each alien moves.
var array<XGUnit> m_arrAllEnemies;      // All enemies (living)
var array<XGUnit> m_arrCachedSquad;     // All units on our team.

var bool    m_bPauseAlienTurn;      //  for kismet

var array<box> m_arrDangerZones; // pending explosions happening here, avoid.
var int m_iTurnInit;

var XGAIPlayerNavigator m_kNav;
var int m_iDataID;
struct native unit_ai_id
{
	var int UnitObjectID;
	var int AIDataObjectID;
};
var array<unit_ai_id> m_arrUnitAIID;

struct native TargetSetCounter // Struct to track number of times this turn a unit has been selected as a primary target.
{
	var int ObjectID;
	var int Count;
};
var array<TargetSetCounter> TargetSetCounts; // Track number of times a unit is set as a primary target for an ability.
//------------------------------------------------------------------------------------------------
//debugging
var array<string> TurnLog, LastTurnLog;

//=======================================================================================
//X-Com 2 Refactoring
//
var StateObjectReference CurrentAIGroupRef;	// The current AIGroup that is acting
var int DecisionIteration;      //Keeps track of how many times the AI Player has considered moves for its units. IE. if each unit has two moves, the count should not surpass two.
var int MaxDecisionIterations;  //if DecisionIteration goes past this figure, the AI is stuck and should skip its turn
var GameRulesCache_Unit CurrentMoveUnit;    //GameRulesCache info for the currently 'selected' unit that the AI is moving
var array<GameRulesCache_Unit> UnitsToMove; //A list of units and their available actions
var int BTRunsThisTurn;
//var bool m_bOnDelayMove;

var reinforcements_info m_kReinforcements;
var array<int> m_arrWaitForScamper;
var bool m_bWaitingForScamper/*, m_bWaitForVisualizer*/;

enum ai_activity_phase
{
	eAAP_Inactive,
	eAAP_GreenPatrolMovement,
	eAAP_SequentialMovement,
	eAAP_ScamperSetUp,			// Interrupting Phase: Waiting for units in group to finish their group movement after alerted.
	eAAP_Scampering,			// Units running their scamper Behavior Trees and performing resultant actions.
};
var ai_activity_phase m_ePhase;

var bool bCiviliansTargetedByAliens;		// Cache bool if active mission is a terror mission.

var bool bAIHasKnowledgeOfAllUnconcealedXCom; // Ignore knowledge data.

var array<TTile> AoETargetedThisTurn; // Keep track of AoE targets to prevent attacking the same place multiple times in a turn.

var array<int> FacelessCivilians; // Cache the list of faceless civilians to keep track of units to avoid attacking.

var array<StateObjectReference> TwoTurnAttackTargets; // List of targets being attacked with a two-turn ability (Rift, PsiBomb, Wrath Cannon, BlazingPinions)
													// Used for AI to coordinate with overwatch / suppression.
var array<TTile> TwoTurnAttackTiles;   // List of tiles being attacked with a two-turn ability (Rift, PsiBomb, Wrath Cannon, BlazingPinions).
								     // Used for AI to avoid these destinations.

// List of all 'last resort' effects.  These effects specify targets that can not be attacked,
struct native LastResortEffect
{
	var Name EffectName;
	var bool ApplyToAlliesOnly; // If true, only allies with this effect are last-resort targets.
};
var config array<LastResortEffect> LastResortTargetEffects; //   unless they are the only ones remaining.

var array<int> LastResortTargetList; // Updated prior to each behavior tree run
var array<int> ValidTargetsBasedOnLastResortEffects; // Updated prior to each behavior tree run

var array<int> AggressiveUnitTracker; // List of units that have taken an aggressive action this turn.

var bool bWaitOnVisUpdates; 
native function AddTwoTurnData(X2AbilityMultiTargetStyle MultiTargetStyle, XComGameState_Ability AbilityState, array<vector> TargetLocations);
native function bool IsInTwoTurnAttackTiles(TTile Tile);
function AddTwoTurnAttackTargets(array<vector> TargetLocations, XComGameState_Ability AbilityState)
{
	local X2AbilityMultiTargetStyle MultiTargetStyle;
	MultiTargetStyle = AbilityState.GetMyTemplate().AbilityMultiTargetStyle;
	if( MultiTargetStyle != None )
	{
		AddTwoTurnData(MultiTargetStyle, AbilityState, TargetLocations);
	}
	`LogAIBT("AddTwoTurnAttackTargets: TargetCount="$TwoTurnAttackTargets.Length@"TileCount="$TwoTurnAttackTiles.Length);
}

// Update valid target list prior to every Behavior Tree run.
function OnBTRunInit()
{
	UpdateValidAndLastResortTargetList();
}
function OnBTRunCompletePreExecute(int UnitID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit ScamperUnit;
	local XComGameState_AIGroup ScamperGroup;
	local X2AIBTBehaviorTree BTMgr;
	BTMgr = `BEHAVIORTREEMGR;

	//If the current scampering unit is the first in its group to process its behavior, push a reveal begin state into the history 
	//to signal that a reveal is starting
	if( BTMgr.IsFirstScamperUnitActive() )
	{
		`Assert(BTMgr.ActiveQueueID == UnitID);
		History = `XCOMHISTORY;
		ScamperUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitID));
		ScamperGroup = ScamperUnit.GetGroupMembership();
		ScamperGroup.OnScamperBegin();		
	}
}

function OnBTRunCompletePostExecute(int UnitID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit ScamperUnit;
	local XComGameState_AIGroup ScamperGroup;
	local bool bWaitingForOtherScamperGroupMembers;
	local X2AIBTBehaviorTree BTMgr;
	BTMgr = `BEHAVIORTREEMGR;

	if( `TACTICALRULES.UnitActionPlayerIsAI() )
	{
		if( m_arrWaitForScamper.RemoveItem(UnitID) > 0 )
		{
			GatherUnitsToMove();
		}
	}

	//Perform special logic so that scamper moves can be bookended by the proper game states
	if( BTMgr.IsScampering(UnitID, false) )
	{		
		//See if anyone else from our scamper group is still scampering
		History = `XCOMHISTORY;
		ScamperUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitID));
		ScamperGroup = ScamperUnit.GetGroupMembership();
		bWaitingForOtherScamperGroupMembers = BTMgr.IsGroupScampering(ScamperGroup) || BTMgr.ActiveBTQueueEntry.RunCount > 0;

		//If not, then mark our scamper group as done!
		if(!bWaitingForOtherScamperGroupMembers)
		{
			SetTimer(0.1f, false, 'DelayedOnScamperComplete', ScamperGroup);
		}
	}
	BTRunsThisTurn++;
}

function bool IsScampering(int ScamperID = -1, bool LookInQueue=true)
{
	local X2AIBTBehaviorTree BTMgr;
	BTMgr = `BEHAVIORTREEMGR;

	if( BTMgr.IsScampering(ScamperID, LookInQueue) || m_bWaitingForScamper )
	{
		return true;
	}
	return false;
}

/// <summary>
/// Called by the rules engine when the unit action phase has started for this player in "NextPlayer()". This event is called once for each player
/// during the unit actions phase.
/// </summary>
simulated function OnUnitActionPhaseBegun_NextPlayer()
{
	super.OnUnitActionPhaseBegun_NextPlayer();
	
	`TACTICALRULES.UpdateAIActivity(true);


}

simulated function OnUnitActionPhase_NextGroup(StateObjectReference InAIGroupRef)
{
	m_ePhase = eAAP_GreenPatrolMovement;
	//Fill out our UnitsToMove list
	DecisionIteration = 0; //Reset our decision iteration count
	MaxDecisionIterations = 10; //Hard-coded to 10 for now. If a unit can perform more than 10 actions per turn, this should be elevated.
	InitTurn(); // Call init turn first to ensure our groups have been refreshed.
				//m_bOnDelayMove = false;

	CurrentAIGroupRef = InAIGroupRef;
	GatherUnitsToMove();
	BTRunsThisTurn = 0;

}

/// <summary>
/// Called by the rules engine when the unit action phase has ended for this player in "NextPlayer()". This event is called once for each player
/// during the unit actions phase.
/// </summary>
simulated function OnUnitActionPhaseFinished_NextPlayer()
{
	local GameRulesCache_Unit EmptyCacheElement;
	local array<XComGameState_Unit> PlayableUnits;

	super.OnUnitActionPhaseFinished_NextPlayer();

	CurrentMoveUnit = EmptyCacheElement;
	OnEndTurn();
	m_ePhase = eAAP_Inactive;

	// Check if any game states have been added since the beginning of the turn.  If not, and we have living units, dump AI logs.
	if( `TACTICALRULES.UnitActionPlayerIsAI() && BTRunsThisTurn == 0 )
	{
		GetPlayableUnits(PlayableUnits);
		if( PlayableUnits.Length > 0 ) // Debugging - Dump AI logs when we have living units that don't do anything.
		{
			`Log("Possible Error - AI has"@PlayableUnits.Length@"playable units but no behavior trees have run during AI's turn!  Dumping AI Logs.");
			DumpAILog();
		}
	}

}

/// <summary>
/// Called by the rules engine each time it evaluates whether any units have available actions "ActionsAvailable()".
///
///The passed-in Unit state is not used by the AI player. Instead, it works from a list of units which are available to perform actions. The list only
///contains units which have available actions. In each call to 'OnUnitActionPhase_ActionsAvailable', the first element in the list is removed and 
///processed. Processing the element entails running that unit's behavior logic which should submit an action to the tactical rule set. 
///
///This process whittles the list of units to move down to 0. When the list reaches zero it means that all the AI units have had a chance to run 
///their behavior logic, and the DecisionIteration variable is incremented. At this point, the list of units to move is repopulated based on the
///current state of the game and the process repeats.
///
///The process will repeat until either no units remain which can take moves or the iteration count climbs too high. If the iteration count climbs too
///hight it indicates that there are errors in the action logic which are allowing actions to be used indefinitely.
/// </summary>
/// <param name="bWithAvailableActions">The first unit state with available actions</param>
simulated function OnUnitActionPhase_ActionsAvailable(XComGameState_Unit UnitState)
{	
	local GameRulesCache_Unit DummyCachedActionData;
	local XComGameState_Unit CheatUnitState;

	if( (`CHEATMGR != None && `CHEATMGR.bAllowSelectAll) )
	{
		super.OnUnitActionPhase_ActionsAvailable(UnitState); //Pretend we are a normal human player
		return;
	}

	if (m_bSkipAI)
	{		
		`LogAI("Skipping AI turn"@self);
		EndTurn(ePlayerEndTurnType_AI);
		return;
	}

	// Cheat to force only a specific unit to run their behavior this turn.  Everyone else skips their turn.
	if (`CHEATMGR != None && `CHEATMGR.SkipAllAIExceptUnitID > 0)
	{
		CheatUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(`CHEATMGR.SkipAllAIExceptUnitID));

		if (!(CheatUnitState.bRemovedFromPlay
			|| CheatUnitState.IsDead()
			|| CheatUnitState.IsUnconscious()
			|| CheatUnitState.IsBleedingOut()
			|| CheatUnitState.IsStasisLanced()
			|| CheatUnitState.bDisabled)
			&& CheatUnitState.NumAllActionPoints() > 0)
		{
			DummyCachedActionData.UnitObjectRef.ObjectID = `CHEATMGR.SkipAllAIExceptUnitID;
			UnitsToMove.Length = 0;
			UnitsToMove.AddItem(DummyCachedActionData);
			TryBeginNextUnitTurn();
		}
		else
		{
			EndTurn(ePlayerEndTurnType_AI);
			return;
		}
	}

	if( m_ePhase != eAAP_SequentialMovement && UnitsToMove.Length == 0 )
	{		
		++DecisionIteration;
		GatherUnitsToMove();
	}

	if (UnitsToMove.Length == 0 && !IsScampering())
	{		
		`LogAI("Found no more units to move.  Skipping AI turn"@self);
		EndTurn(ePlayerEndTurnType_AI);
		return;
	}

	TryBeginNextUnitTurn();
}

function bool WaitingOnVisUpdates()
{
	if( bWaitOnVisUpdates )
	{
		if( `XWORLD.HasPendingVisibilityUpdates() )
		{
			// If the wait timer hasn't been started yet, start it now.
			if( !IsTimerActive(nameof(WaitOnVisUpdateTimer)) )
			{
				SetTimer(3.0f, false, nameof(WaitOnVisUpdateTimer));
			}
			else
			{
				// Otherwise ensure timer is running.
				PauseTimer(false, nameof(WaitOnVisUpdateTimer));
			}
			return true;
		}
		else
		{
			// If the wait timer is active, stop it.
			if( IsTimerActive(nameof(WaitOnVisUpdateTimer)) )
			{
				PauseTimer(true, nameof(WaitOnVisUpdateTimer));
			}
		}
	}
	return false;
}

// If it enters this function, then 3 seconds have elapsed waiting on the pending visibility updates.  Time to stop waiting.
function WaitOnVisUpdateTimer()
{
	bWaitOnVisUpdates = false; // Gets reset next AI turn.
}

function bool IsReadyForNextUnit()
{
	local XGAIBehavior kBehavior;
	if( WaitingOnVisUpdates() )
	{
		return false;
	}
	if( (IsScampering() && !WaitingForScamperSetup()) )
	{
		return false;
	}
	if (CurrentMoveUnit.UnitObjectRef.ObjectID > 0)
	{
		kBehavior = XGUnit(`XCOMHISTORY.GetVisualizer(CurrentMoveUnit.UnitObjectRef.ObjectID)).m_kBehavior;
		if (kBehavior != None && !kBehavior.IsInState('Inactive'))
		{
			return false;
		}
	}
	return `BEHAVIORTREEMGR.IsReady();
}

// Stop processing the AI if we are waiting for a scamper action to complete.
function bool WaitingForScamperSetup()
{
	if (m_bWaitingForScamper)
	{
		return m_arrWaitForScamper.Length > 0;
	}
	return false;
}

// Step through history and find last enemy that used an ability.
function int GetLastActiveEnemyID()
{
	local XComGameStateHistory History;	
	local XComGameStateContext_Ability Context;
	local XComGameState_Unit kUnitState;
	History = `XCOMHISTORY;
	foreach History.IterateContextsByClassType(class'XComGameStateContext_Ability', Context)
	{
		kUnitState = XComGameState_Unit(History.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
		if (kUnitState.GetTeam() == eTeam_XCom)
		{
			return Context.InputContext.SourceObject.ObjectID;
		}
	}
	`Warn("ERROR - cannot find last acting enemy ID!!!");
	return 0;
}

/// <summary>
/// If we are notified by the rules engine to move a unit and the reflex action state of that unit is set to 
/// AI scamper - it means we have been given a free move by the reflex mechanics and need to decide a move right away
/// </summary>
simulated function QueueScamperBehavior(XComGameState_Unit ScamperUnitState, XComGameState_Unit AlertSourceState, bool bSurprisedScamper, bool bFirstScamper)
{
	local XGUnit UnitVisualizer;		
	local int iIndex, NumScamperActionPoints, ID;
	local X2CharacterTemplate Template;
	local X2AIBTBehaviorTree BTMgr;
	local XGPlayer EnemyPlayer;
	local XComGameState_Player EnemyPlayerState;
	local XComGameState_AIGroup Group;
	local array<int> MemberIDs;

	BTMgr = `BEHAVIORTREEMGR;

	`assert(ScamperUnitState != none);
	if (`CHEATMGR != None && `CHEATMGR.bAbortScampers)
	{
		return;
	}

	if (ScamperUnitState.CanScamper())
	{
		// Early out if this team is TheLost and we already have a scampering unit.  
		// Only one unit per group needs to scamper for TheLost, since the one unit kicks off a mass-group move.  
		if (ScamperUnitState.GetTeam() == eTeam_TheLost)
		{
			Group = ScamperUnitState.GetGroupMembership();
			if (Group.GetLivingMembers(MemberIDs))
			{
				foreach MemberIDs(ID)
				{
					if (BTMgr.IsScampering(ID, true))
					{
						return;
					}
				}
			}
		}

		UnitVisualizer = XGUnit(ScamperUnitState.GetVisualizer());
		if (UnitVisualizer != none)
		{
			// Force patrol group to update alertness values.
			if (UnitVisualizer.m_kBehavior.m_kPatrolGroup != None)
			{
				UnitVisualizer.m_kBehavior.m_kPatrolGroup.UpdateLastAlertLevel();
			}
		}

		Template = ScamperUnitState.GetMyTemplate();

		EnemyPlayer = `BATTLE.GetEnemyPlayer(self);
		EnemyPlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(EnemyPlayer.ObjectID));

		// Update - only wait for squad concealment if this unit was alerted to a unit on the concealed team.
		if( EnemyPlayerState.bSquadIsConcealed && AlertSourceState.ControllingPlayer.ObjectID == EnemyPlayerState.ObjectID 
			&& (ScamperUnitState.GetTeam() != eTeam_TheLost)  // Update - Scampering Lost do not wait for squad concealment to break.
			&& !ScamperUnitState.IsChosen()) // Also Chosen does not wait for squad concealment when activated.
		{
			BTMgr.bWaitingOnSquadConcealment = true;
		}
		NumScamperActionPoints = ScamperUnitState.GetNumScamperActionPoints();
		BTMgr.QueueBehaviorTreeRun(ScamperUnitState, Template.strScamperBT, NumScamperActionPoints, `XCOMHISTORY.GetCurrentHistoryIndex()+1, true, bFirstScamper, bSurprisedScamper);

		// Remove this unit from our UnitsToMove array, if it is in there.
		iIndex = UnitsToMove.Find('UnitObjectRef', ScamperUnitState.GetReference());
		if( iIndex != -1 )
		{
			`LogAI("Removing unit"@UnitsToMove[iIndex].UnitObjectRef.ObjectID@"from UnitsToMove list - QueueBehaviorTreeRun.");
			UnitsToMove.Remove(iIndex, 1);
		}

	}
	else
	{
		`LogAI("No scamper action chosen - Unit Character Template marked as Does Not Scamper.  UnitID#"$ScamperUnitState.ObjectID);
	}
}

// Ensure everyone in this list is alive.
function ValidateUnitsToMoveList()
{
	local GameRulesCache_Unit UnitOption;
	local XComGameState_Unit kUnitState;
	local array<GameRulesCache_Unit> DeleteList;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;
	foreach UnitsToMove(UnitOption)
	{
		kUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitOption.UnitObjectRef.ObjectID));
		if (!kUnitState.IsAlive() || kUnitState.NumAllActionPoints() == 0)
		{
			DeleteList.AddItem(UnitOption);
		}
	}

	foreach DeleteList(UnitOption)
	{
		`LogAI("Removing unit"@UnitOption.UnitObjectRef.ObjectID@"from UnitsToMove list - ValidateUnitsToMoveList.");
		UnitsToMove.RemoveItem(UnitOption);
	}

	// End turn if the AI is done.
	if( UnitsToMove.Length == 0 && `TACTICALRULES.UnitActionPlayerIsAI() )
	{
		GatherUnitsToMove(); // Update units to move list, and advance phase out of green alert movement if necessary.
	}
}

function InvalidateUnitToMove( int iID )
{
	local GameRulesCache_Unit UnitOption;
	local array<GameRulesCache_Unit> DeleteList;
	local X2AIBTBehaviorTree BTMgr;
	BTMgr = `BEHAVIORTREEMGR;

	m_arrWaitForScamper.RemoveItem(iID);
	BTMgr.RemoveFromBTQueue(iID);

	foreach UnitsToMove(UnitOption)
	{
		if (UnitOption.UnitObjectRef.ObjectID == iID)
		{
			DeleteList.AddItem(UnitOption);
		}
	}

	foreach DeleteList(UnitOption)
	{
		`LogAI("Removing unit"@UnitOption.UnitObjectRef.ObjectID@"from UnitsToMove list - INValidateUnitsToMoveList.");
		UnitsToMove.RemoveItem(UnitOption);
	}

	// End turn if the AI is done.
	if( UnitsToMove.Length == 0  && `TACTICALRULES.UnitActionPlayerIsAI() ) 
	{
		GatherUnitsToMove();
		if( UnitsToMove.Length == 0 && !IsScampering() )
		{
			`LogAI("Found no more units to move.  Skipping AI turn"@self);
			EndTurn(ePlayerEndTurnType_AI);
			return;
		}
	}
}

function TryBeginNextUnitTurn()
{
	if( !IsReadyForNextUnit() )
	{
		SetTimer(0.1f, false, nameof(TryBeginNextUnitTurn));
	}
	else
	{
		BeginNextUnitTurn();
	}
}

function BeginNextUnitTurn( int iPriorityUnitID=0, bool bForcePriorityMovement=false )
{
	local XGAIBehavior MoveUnitBehavior;
	local XComGameState_Unit kUnitState;
	local XGUnit kUnit;
	local GameRulesCache_Unit UnitOption;
	local int iID;
	local bool bFound, bUpdatedCache, bInputActionsAvailable;
	local XComTacticalCheatManager kCheatMgr;
	kCheatMgr = `CHEATMGR;

	ValidateUnitsToMoveList();
	bFound=false;
	if (iPriorityUnitID != 0)
	{
		// Look for this id in our unit options.
		foreach UnitsToMove(UnitOption)
		{
			if (UnitOption.UnitObjectRef.ObjectID == iPriorityUnitID)
			{
				CurrentMoveUnit = UnitOption;
				bFound = true;
				`LogAI("PriorityID BeginNextUnitTurn:	BeginNextUnitTurn found next unit to move:"$iPriorityUnitID);
				break;
			}
		}
		// Force ability info update.
		if (!bFound)
		{
			if (bForcePriorityMovement)
			{
				`LogAI("PriorityBeginNextUnitTurn: BeginNextUnitTurn could not find unit to move in list:"$iPriorityUnitID);
				kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iPriorityUnitID));
				if (`TACTICALRULES.GetGameRulesCache_Unit(kUnitState.GetReference(), CurrentMoveUnit)
					&&  ( CurrentMoveUnit.bAnyActionsAvailable && InputActionsAvailableForUnit(CurrentMoveUnit) ))
				{
					XGUnit(kUnitState.GetVisualizer()).m_kBehavior.UpdateAbilityInfo(CurrentMoveUnit);
					bFound = true;
				}
				else
				{
					`LogAI("PriorityBeginNextUnitTurn: BeginNextUnitTurn could force unit to be next unit to move! "$iPriorityUnitID);
					if (`TACTICALRULES.GetGameRulesCache_Unit(kUnitState.GetReference(), CurrentMoveUnit)
						&&  ( CurrentMoveUnit.bAnyActionsAvailable && InputActionsAvailableForUnit(CurrentMoveUnit) ))
					{
						`LogAI("Second attempt for debugging only.");
					}
				}
			}
			else
				return;
		}
	}
	//Pop the first element from the list, and move it
	if( !bFound )
	{
		if (UnitsToMove.Length > 0 )
		{	
			if (m_bWaitingForScamper && m_arrWaitForScamper.Find(UnitsToMove[0].UnitObjectRef.ObjectID) == -1)
			{
				// Find next unit we're waiting for in this list, make this next.
				foreach m_arrWaitForScamper(iID)
				{
					// Look for this id in our unit options.
					foreach UnitsToMove(UnitOption)
					{
						if (UnitOption.UnitObjectRef.ObjectID == iID)
						{
							CurrentMoveUnit = UnitOption;
							bFound=true;
							`LogAI("SCAMPER:	BeginNextUnitTurn found next unit to move:"$iID);
							break;
						}
					}
					if (bFound)
						break;
				}
				if (!bFound)
				{
					CurrentMoveUnit = UnitsToMove[0];
					`LogAI("SCAMPER: ERROR- BeginNextUnitTurn could not find any unit-to-scamper in UnitsToMove list.  Continuing with unit "$CurrentMoveUnit.UnitObjectRef.ObjectID);
					bFound=true;
				}
			}
			else
			{
				CurrentMoveUnit = UnitsToMove[0];
				`LogAI("BeginNextUnitTurn selected next unit to move:"$CurrentMoveUnit.UnitObjectRef.ObjectID@"--------------------------------------------------------------------------");
				bFound=true;
			}
		}

	}

	if (bFound)
	{
		kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(CurrentMoveUnit.UnitObjectRef.ObjectID));
		kUnit = XGUnit(`XCOMHISTORY.GetVisualizer(CurrentMoveUnit.UnitObjectRef.ObjectID));
		MoveUnitBehavior = kUnit.m_kBehavior;
		// TODO - update this so terror units can still move and attack in green alert.
		//if( m_ePhase == eAAP_GreenPatrolMovement ) // Current non-green unit now removed from list in ValidateUnitsToMoveList, when actionpoints == 0.
		//{
		//	`LogAI("Removing unit"@CurrentMoveUnit.UnitObjectRef.ObjectID@"from UnitsToMove list - Green patrol.");
		//	UnitsToMove.RemoveItem(CurrentMoveUnit);
		//}

		//Get the up to date info on this unit and only launch its behavior if it has input abilities available
		bUpdatedCache = `TACTICALRULES.GetGameRulesCache_Unit(CurrentMoveUnit.UnitObjectRef, CurrentMoveUnit);
		if (bUpdatedCache)
		{
			bInputActionsAvailable = InputActionsAvailableForUnit(CurrentMoveUnit);
		}
		else
		{
			bInputActionsAvailable = false;
		}
		if ( bUpdatedCache && CurrentMoveUnit.bAnyActionsAvailable && bInputActionsAvailable)
		{
			`assert(MoveUnitBehavior != none); //AI units should always have a behavior object
			MoveUnitBehavior.UpdateAbilityInfo(CurrentMoveUnit);
			MoveUnitBehavior.BeginTurn(); //Start the latent process of selecting a move
		}
		else
		{
			if ( !bUpdatedCache )
			{
				kCheatMgr.AIStringsUpdateString(kUnitState.ObjectID, "Error- failed to get Game Rules Cache!");
			}
			else if (CurrentMoveUnit.bAnyActionsAvailable == false)
			{
				if (kUnitState.IsDead())
				{
					kCheatMgr.AIStringsUpdateString(kUnitState.ObjectID, "dead.  No abilities available.");
				}
				else
				{
					kCheatMgr.AIStringsUpdateString(kUnitState.ObjectID, "Error- AnyActionsAvailable == FALSE!");
				}
			}
			else
			{
				kCheatMgr.AIStringsUpdateString(kUnitState.ObjectID, "-no input actions available! (or skipped turn).");
			}

			// Remove this unit from our UnitsToMove list if not already.
			UnitsToMove.RemoveItem(CurrentMoveUnit);
			MoveUnitBehavior.SkipTurn("Removed from AIPlayer::BeginNextUnitTurn- No more actions available or cache not updated.");
		}
	}

	//If the DecisionIteration has gone past 10, then it means that one or more of the AI units is reporting that it always has actions available.
	if( DecisionIteration > 10 )
	{
		`LogAIActions("Exceeded DecisionIteration @"$DecisionIteration$"!  Calling EndTurn()");
		EndTurn(ePlayerEndTurnType_AI);
	}
	else if (!bFound && m_ePhase == eAAP_SequentialMovement && UnitsToMove.Length == 0)
	{
		`LogAI("BeginNextUnitTurn with no more units to move. Calling EndTurn()");
		EndTurn(ePlayerEndTurnType_AI);
	}
}

simulated function bool InputActionsAvailableForUnit(GameRulesCache_Unit UnitInfo)
{
	local int ActionIndex;

	//GameRulesCache_Unit.bAnyActionsAvailable includes actions that are triggered by non-input events ( such as over watch fire ). Only
	//add units if they have input actions available.				
	for( ActionIndex = 0; ActionIndex < UnitInfo.AvailableActions.Length; ++ActionIndex )
	{
		if( UnitInfo.AvailableActions[ActionIndex].bInputTriggered )
		{	
			return true;
		}
	}

	return false;
}

static function bool IsMindControlled(XComGameState_Unit UnitState)
{
	return UnitState.IsUnitAffectedByEffectName(class'X2Effect_MindControl'.default.EffectName);
}

// Update - green alert units and units that have not yet revealed should do their patrol movement.
function bool ShouldUnitPatrol( XComGameState_Unit UnitState )
{
	if( IsMindControlled(UnitState) )
	{
		return false;
	}
	if( UnitState.IsUnrevealedAI() && !IsScampering(UnitState.ObjectID) )
	{
		// For now only allow group leaders to direct movement when unrevealed.
		if( UnitState.GetGroupMembership().m_arrMembers[0].ObjectID == UnitState.ObjectID )
		{
			return true;
		}
	}
	return false;
}

// Insert the other members of this unit's group to the list of units to move.  Used primarily to 
// allow an entire group of chryssalids to burrow, whereas normally in green alert, only the leader 
// would be able to act.
simulated function AddGroupToMoveList( XComGameState_Unit UnitState )
{
	local XComGameStateHistory History;
	local XComGameState_Unit GroupUnit;
	local GameRulesCache_Unit DummyCachedActionData;
	local XGAIBehavior kBehavior;
	local XComGameState_AIPlayerData kAIPlayerData;
	local bool bDead;
	local XComGameState_AIGroup GroupState;
	local StateObjectReference UnitRef;

	kAIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(GetAIDataID()));

	History = `XCOMHISTORY;
	GroupState = UnitState.GetGroupMembership();

	//Loop through every unit, if it is ours, add it to the list
	foreach GroupState.m_arrMembers(UnitRef)
	{
		if( UnitsToMove.Find('UnitObjectRef', UnitRef) != INDEX_NONE )
		{
			continue;
		}
		if( UnitState.ObjectID == UnitRef.ObjectID )
		{
			continue;
		}
		GroupUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));

		// Initialize dummy cached action data.  This isn't actually updated until just before the unit begins its turn.
		DummyCachedActionData.UnitObjectRef.ObjectID = GroupUnit.ObjectID;
		bDead = GroupUnit.IsDead();
		kBehavior = (XGUnit(GroupUnit.GetVisualizer())).m_kBehavior;

		// Check if this unit has already moved this turn.  (Compare init history index to last turn start) 
		// Also skip units that have currently no action points available.   They shouldn't be added to any lists.
		if( bDead 
		   || GroupUnit.NumAllActionPoints() == 0 
		   || (kBehavior != None && kBehavior.DecisionStartHistoryIndex > kAIPlayerData.m_iLastEndTurnHistoryIndex) )
		{
			continue;
		}

		if( UnitsToMove.Length > 0 && UnitsToMove[0].UnitObjectRef.ObjectID == UnitState.ObjectID )
		{
			UnitsToMove.InsertItem(1, DummyCachedActionData);
		}
		else
		{
			UnitsToMove.InsertItem(0, DummyCachedActionData);
		}
	}
}

function bool UnitIsFallingBack(XComGameState_Unit UnitState)
{
	local XComGameState_AIGroup Group;
	if( UnitState.IsAbleToAct() )
	{
		Group = UnitState.GetGroupMembership();
		if( Group.IsFallingBack() )
		{
			return true;
		}
	}
	return false;
}

simulated function GatherUnitsToMove()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local GameRulesCache_Unit DummyCachedActionData;
	local array<GameRulesCache_Unit> arrGreenPatrollers;
	local array<GameRulesCache_Unit> arrOthers;
	local array<GameRulesCache_Unit> arrToSkip;
	local array<GameRulesCache_Unit> ScamperSetup;
	local array<GameRulesCache_Unit> Scampering;
	local array<int> OrderPriorityList;
	local XComTacticalCheatManager kCheatMgr;
	// Start Issue #510 - variables no longer used
	// local XGAIBehavior kBehavior;
	// local XComGameState_AIPlayerData kAIPlayerData;
	// End Issue #510
	local bool bDead, bGroupUnitAdded;
	local X2AIBTBehaviorTree BTMgr;
	local XComGameState_AIGroup AIGroupState;
	local StateObjectReference UnitStateObjRef;
	local X2CharacterTemplate CharTemplate;

	// kAIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(GetAIDataID())); // Issue #510 - no longer used

	kCheatMgr = `CHEATMGR;
	BTMgr = `BEHAVIORTREEMGR;

	if (m_bSkipAI || (`CHEATMGR != None && `CHEATMGR.bAllowSelectAll) || (CurrentAIGroupRef.ObjectID <= 0))
		return;
	History = `XCOMHISTORY;

	AIGroupState = XComGameState_AIGroup(History.GetGameStateForObjectID(CurrentAIGroupRef.ObjectID));
	if (self.IsA('XGAIPlayer_TheLost') && HasGroupAlreadyMovedThisTurn(CurrentAIGroupRef.ObjectID)
		&& (AIGroupState.EncounterID != class'XGAIPlayer_TheLost'.const.MAIN_LOST_GROUP_ID)) // Main group excluded from this check.
	{
		// For TheLost groups, we only need to add one unit to process per group.  
		// The one unit per Lost group will kick off a mass move and mass attack.
		bGroupUnitAdded = true;
	}
	`assert(AIGroupState != None);

	//Loop through every unit, if it is ours, add it to the list
	foreach AIGroupState.m_arrMembers(UnitStateObjRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateObjRef.ObjectID));

		// Initialize dummy cached action data.  This isn't actually updated until just before the unit begins its turn.
		DummyCachedActionData.UnitObjectRef.ObjectID = UnitState.ObjectID;
		bDead = UnitState.IsDead();
		if (kCheatMgr != None)
		{
			kCheatMgr.AIStringsAddUnit(UnitState.ObjectID, bDead);
		}

		// kBehavior = (XGUnit(UnitState.GetVisualizer())).m_kBehavior; // Issue #510 - no longer used

		// Check if this unit has already moved this turn.  (Compare init history index to last turn start) 
		// Also skip units that have currently no action points available.   They shouldn't be added to any lists.
		//
		// Issue #510 - Removed the DecisionStartHistoryIndex check as it prevents pod leaders from using
		// any reflex actions they may have been granted.
		if(bDead || UnitState.bRemovedFromPlay || UnitState.NumAllActionPoints() == 0) // || kBehavior == None || kBehavior.DecisionStartHistoryIndex > kAIPlayerData.m_iLastEndTurnHistoryIndex)
		{
			continue;
		}

		if (self.IsA('XGAIPlayer_TheLost') && bGroupUnitAdded )
		{
			arrToSkip.AddItem(DummyCachedActionData);
			kCheatMgr.AIStringsUpdateString(UnitState.ObjectID, "Additional Lost units in AI Group- Skipping.");
			continue;
		}


		// Add units to scamper setup list.
		if( m_arrWaitForScamper.Find(UnitState.ObjectID) != INDEX_NONE )
		{
			ScamperSetup.AddItem(DummyCachedActionData);
			kCheatMgr.AIStringsUpdateString(UnitState.ObjectID, "ScamperSetup");
			bGroupUnitAdded = true;
		}
		else if( BTMgr.IsQueued(UnitState.ObjectID) )
		{
			Scampering.AddItem(DummyCachedActionData);
			kCheatMgr.AIStringsUpdateString(UnitState.ObjectID, "Scampering");
			bGroupUnitAdded = true;
		}
		else if( UnitIsFallingBack(UnitState) )
		{
			arrGreenPatrollers.InsertItem(0,DummyCachedActionData); // Fallback units get priority to move first.
			kCheatMgr.AIStringsUpdateString(UnitState.ObjectID, "Falling Back");
			bGroupUnitAdded = true;
		}
		else if (ShouldUnitPatrol(UnitState)) // && m_kNav.IsPatrol(UnitState.ObjectID))
		{
			arrGreenPatrollers.AddItem(DummyCachedActionData);
			kCheatMgr.AIStringsUpdateString(UnitState.ObjectID, "Green Alert Patrol");
			bGroupUnitAdded = true;
		}
		else if (UnitState.GetCurrentStat(eStat_AlertLevel)>0 || IsMindControlled(UnitState))
		{
			CharTemplate = UnitState.GetMyTemplate();
			AddToOrderedCharacterList(arrOthers, DummyCachedActionData, OrderPriorityList, CharTemplate.AIOrderPriority);
			bGroupUnitAdded = true;
		}
		else
		{
			arrToSkip.AddItem(DummyCachedActionData);
			kCheatMgr.AIStringsUpdateString(UnitState.ObjectID, "Green Alert non-patrol- Skipping.");
		}
	}

	if( IsScampering() )
	{
		if( WaitingForScamperSetup() )
		{
			if( m_ePhase != eAAP_ScamperSetUp )
			{
				m_ePhase = eAAP_ScamperSetUp;
				`LogAI(" AI Player : Entering phase ScamperSetup");
			}
			UnitsToMove = ScamperSetup;
		}
		else
		{
			if( m_ePhase != eAAP_Scampering )
			{
				m_ePhase = eAAP_Scampering;
				`LogAI(" AI Player : Entering phase Scampering");
			}
			UnitsToMove = Scampering;
		}
	}
	else
	{
		if( arrGreenPatrollers.Length > 0 )
		{
			if(m_ePhase != eAAP_GreenPatrolMovement )
			{
				m_ePhase = eAAP_GreenPatrolMovement;
				`LogAI(" AI Player : Entering phase GreenPatrolMovement");
			}
			UnitsToMove = arrGreenPatrollers;
		}
		else
		{
			if( m_ePhase != eAAP_SequentialMovement )
			{
				m_ePhase = eAAP_SequentialMovement;
				`LogAI(" AI Player : Entering phase Sequential Movement");
			}
			// TODO: Sort units to move here.
			UnitsToMove = arrOthers;
		}
	}
	`logAI(self$"::GatherUnitsToMove found "@UnitsToMove.Length@" units to move.");
	if (arrToSkip.Length > 0)
	{
		`logAI(self$"::GatherUnitsToMove found "@arrToSkip.Length@" units to skip.");
	}
}

function AddToOrderedCharacterList(out array<GameRulesCache_Unit> OrderedList, GameRulesCache_Unit UnitToAdd, out array<int> OrderPriorityList, int UnitPriority)
{
	local int i, NumInList;
	if (OrderedList.Length != OrderPriorityList.Length)
	{
		`RedScreen("AI: AddToOrderedCharacterList error! Array length mismatch. @acheng");
		OrderedList.AddItem(UnitToAdd);
		OrderPriorityList.AddItem(UnitPriority);
		return;
	}
	NumInList = OrderedList.Length;
	for (i = 0; i < NumInList; ++i)
	{
		if (UnitPriority < OrderPriorityList[i])
		{
			OrderedList.InsertItem(i, UnitToAdd);
			OrderPriorityList.InsertItem(i, UnitPriority);
			return;
		}
	}
	OrderedList.AddItem(UnitToAdd);
	OrderPriorityList.AddItem(UnitPriority);
}
//=======================================================================================
function OnTimedOut()
{
	local GameRulesCache_Unit kUnit;
	if (`CHEATMGR != None)
	{
		if (UnitsToMove.Find('UnitObjectRef', CurrentMoveUnit.UnitObjectRef) == -1)
		{
			`CHEATMGR.AIStringsUpdateString(CurrentMoveUnit.UnitObjectRef.ObjectID, "...timed out!");
		}

		foreach UnitsToMove(kUnit)
		{
			`CHEATMGR.AIStringsUpdateString(kUnit.UnitObjectRef.ObjectID, "...timed out!");
		}
		if( m_ePhase != eAAP_SequentialMovement )
		{		
			// Update AI Last Action strings for other units not yet updated.
			m_ePhase = eAAP_SequentialMovement;
			GatherUnitsToMove();
			foreach UnitsToMove(kUnit)
			{
				`CHEATMGR.AIStringsUpdateString(kUnit.UnitObjectRef.ObjectID, "...timed out!");
			}
		}
	}
}
//------------------------------------------------------------------------------------------------
function Init( bool bLoading=false )
{
	super.Init();
	if (!IsA('XGAIPlayer_Civilian'))
	{
		if (m_kNav == none)
		{
			m_kNav = Spawn( class'XGAIPlayerNavigator' );
			m_kNav.Init(self);
		}
		`BEHAVIORTREEMGR.ClearQueue();
	}
}

//------------------------------------------------------------------------------------------------
// MHU - Save/Load requirement, primarily for AIPlayer to override and do custom load work.
simulated function LoadInit()
{
	super.LoadInit();
	m_bLoadedFromCheckpoint = false; // Turning this off as it has no purpose except for in XGPlayer.uc
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
simulated function bool IsInSameTile( TTile v1, TTile v2, int Z_fudge=1)
{
	if (v1.x==v2.x && v1.y==v2.y && abs(v1.z-v2.z) <= Z_fudge)
		return true;
	return false;
}

//------------------------------------------------------------------------------------------------
// Fill the cached visible list with all enemies.
simulated function CollectEnemiesDelegate(XGUnit kUnit)
{
	m_arrAllEnemies.AddItem(kUnit);
}
//------------------------------------------------------------------------------------------------
simulated function UpdateEnemiesList()
{
	m_arrAllEnemies.Length = 0;
	`BATTLE.GetEnemySquad(self).VisitUnit(CollectEnemiesDelegate,,,false);
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
simulated function GetAllEnemies(out array<XGUnit> arrEnemies)
{
	arrEnemies = m_arrAllEnemies;
}
//------------------------------------------------------------------------------------------------
native simulated function bool IsInDangerousArea( vector vLoc, optional out string strDebug );
//------------------------------------------------------------------------------------------------
simulated function GetSquadLocation( out Vector vSquadLoc, optional out float fRadius) 
{
	local XGSquad kSquad;
	local Box BBox;
	local Vector vDiameter;

	kSquad = XGBattle_SP(`BATTLE).GetHumanPlayer().GetSquad();
	BBox = kSquad.GetBoundingBox();
	vDiameter = BBox.Max - BBox.Min;
	vSquadLoc = (BBox.Min + BBox.Max)*0.5f;
	// Force location to the ground.
	vSquadLoc.Z = `XWORLD.GetFloorZForPosition(vSquadLoc, true);
	fRadius = VSize2D(vDiameter)*0.5f;
}
//------------------------------------------------------------------------------------------------
function UpdateDataToAIGameState( bool bStartState=false, bool bAISpawning=false )
{
	local XComGameState StartState, NewGameState;
	local XComGameState_AIPlayerData AIState, AIData;
	local XComGameState_AIUnitData AIUnitState;
	local XComGameState_AIBlackboard AIBlackboard;
	local XComGameStateContext_TacticalGameRule NewContext;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local unit_ai_id kAILink;

	if (m_eTeam != eTeam_Neutral)
	{
		History = `XCOMHISTORY;
		if (bStartState)
		{
			// Update game state AI data.
			StartState = History.GetStartState();
			//issue #226 - grab the first possible AI data state if it exists. If not, make a new one.
			//this is done because the game is generally set up to expect one XComGameState_AIPlayerData to exist, when it comes to mechanics like Alien Rulers or the Chosen
			//and we know the few exceptions to that rule expect eTeam_Alien, which will always be the first team to get here (and thus create the AIPlayerData state)
			foreach History.IterateByClassType(class'XComGameState_AIPlayerData', AIData)
			{
				AIState = AIData;
				break;
			}
			if(AIState == none)
			{
				AIState = XComGameState_AIPlayerData(StartState.CreateNewStateObject(class'XComGameState_AIPlayerData'));
				AIState.Init(ObjectID, StartState);
			}
			//end issue #226
			m_iDataID = AIState.ObjectID;

			//Loop through every unit, if it is ours and it has actions available add it to the list
			m_arrUnitAIID.Length = 0;
			foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				if (UnitState.ControllingPlayer.ObjectID == ObjectID) // My units
				{
					AIUnitState = XComGameState_AIUnitData(StartState.CreateNewStateObject(class'XComGameState_AIUnitData'));
					AIUnitState.Init(UnitState.ObjectID);
					kAILink.UnitObjectID = UnitState.ObjectID;
					kAILink.AIDataObjectID = AIUnitState.ObjectID;
					m_arrUnitAIID.AddItem(kAILink);
				}
			}

			// Add the AI Blackboard, assuming it isn't already a thing.
			AIBlackboard = XComGameState_AIBlackboard(History.GetSingleGameStateObjectForClass(class'XComGameState_AIBlackboard', true));
			if( AIBlackboard == None )
			{
				AIBlackboard = XComGameState_AIBlackboard(StartState.CreateNewStateObject(class'XComGameState_AIBlackboard'));
			}

		}
		else
		{
			NewContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UpdateAIPlayerData);
			NewContext.PlayerRef.ObjectID = ObjectID;
			NewGameState = NewContext.ContextBuildGameState();
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}
//------------------------------------------------------------------------------------------------
function AddNewSpawnAIData( XComGameState NewGameState )
{
	local XComGameState_AIUnitData AIUnitState;
	local XComGameState_Unit UnitState;
	local XComGameState_AIGroup GroupState;
	local XComGameState_AIPlayerData AIPlayerDataState;
	local unit_ai_id kAILink;
	local int iIdx, iGroupID, PlayerID;

	//Loop through every unit, if it is ours and is missing an AI Unit Data gamestate, add it here.
	m_arrUnitAIID.Length = 0;
	RebuildUnitAIIDList();
	AIPlayerDataState = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(GetAIDataID()));
	foreach NewGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (UnitState.ControllingPlayer.ObjectID == ObjectID) // My units
		{
			iIdx = m_arrUnitAIID.Find('UnitObjectID', UnitState.ObjectID);
			if (iIdx == -1) // Missing entry.
			{
				AIUnitState = XComGameState_AIUnitData(NewGameState.CreateNewStateObject(class'XComGameState_AIUnitData'));
				AIUnitState.Init(UnitState.ObjectID);
				kAILink.UnitObjectID = UnitState.ObjectID;
				kAILink.AIDataObjectID = AIUnitState.ObjectID;
				m_arrUnitAIID.AddItem(kAILink);

				iGroupID = AIPlayerDataState.GetGroupObjectIDFromUnit(UnitState.GetReference());
				if (iGroupID <= 0)
				{
					// Add to a new group.
					GroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
					GroupState.AddUnitToGroup(UnitState.ObjectID, NewGameState);
					PlayerID = GetAIDataID();
					if( PlayerID <= 0 )
					{
						// Initialize AIPlayerDataState if it doesn't already exist.  (Fixes Editor PIE crash)
						AIPlayerDataState = XComGameState_AIPlayerData(NewGameState.CreateNewStateObject(class'XComGameState_AIPlayerData'));
						AIPlayerDataState.Init(ObjectID, NewGameState);
						m_iDataID = AIPlayerDataState.ObjectID;
					}
					else
					{
						AIPlayerDataState = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', PlayerID));
					}
					AIPlayerDataState.UpdateGroupData(NewGameState);
					`TACTICALRULES.AddGroupToInitiativeOrder(GroupState, NewGameState);
				}
			}
		}
	}
}

//------------------------------------------------------------------------------------------------

function RebuildUnitAIIDList(bool bLogAll=false)
{
	local XComGameState_AIUnitData kAIGameState;
	local XComGameStateHistory History;
	local unit_ai_id kAILink;
	History = `XCOMHISTORY;
	m_arrUnitAIID.Length = 0;
	foreach History.IterateByClassType(class'XComGameState_AIUnitData', kAIGameState)
	{
		if (m_arrUnitAIID.Find('AIDataObjectID', kAIGameState.ObjectID) == -1)
		{
			kAILink.UnitObjectID   = kAIGameState.m_iUnitObjectID;
			kAILink.AIDataObjectID = kAIGameState.ObjectID;
			m_arrUnitAIID.AddItem(kAILink);
			if (bLogAll)
			{
				`LogAI("RebuildUnitAIIDList: Added link (Unit, AI) : ("$kAILink.UnitObjectID$", "$kAILink.AIDataObjectID$")");
			}
		}
	}
	`LogAI("RebuildUnitAIIDList: Added"@m_arrUnitAIID.Length@"Unit-to-AI ObjectID links to list.");
}

//------------------------------------------------------------------------------------------------
function int GetAIUnitDataID( int iUnitObjID )
{
	local int iIdx;

	iIdx = m_arrUnitAIID.Find('UnitObjectID', iUnitObjID);
	if ( iIdx == INDEX_NONE ) // Rebuild List?
	{
		RebuildUnitAIIDList();
		iIdx = m_arrUnitAIID.Find('UnitObjectID', iUnitObjID);
	}

	if( iIdx != INDEX_NONE )
	{
		return m_arrUnitAIID[iIdx].AIDataObjectID;
	}

	if ( XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( iUnitObjID ) ).GetTeam() == eTeam_Alien)
		`Warn("ERROR: Could not find data id for Unit ObjID:"$iUnitObjID);

	RebuildUnitAIIDList(true);
	return INDEX_NONE; //Indicates a new AI data object should be made
}

//------------------------------------------------------------------------------------------------
function OnPlayerAbilityCooldown( name strAbility, int iCooldown )
{
	if (strAbility == 'CallReinforcements')
		FlagReinforcements();
}

//------------------------------------------------------------------------------------------------
function bool CanCallReinforcements()
{
	// When Down Throttling is active, we cannot call for new reinforcements.
	local XComGameState_AIPlayerData kAIPlayerData;
	kAIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(GetAIDataID()));
	if( kAIPlayerData.bDownThrottlingActive )
	{
		return false;
	}

	return m_kReinforcements.bUnavailable == false;
}
//------------------------------------------------------------------------------------------------
function FlagReinforcements()
{
	m_kReinforcements.bUnavailable = true;
}

//------------------------------------------------------------------------------------------------
// output fClosestDist is squared distance to nearest enemy.
simulated function XGUnit GetNearestEnemy(Vector vPoint, optional out float fClosestDist)
{
	local XGUnit kEnemy, kClosest;
	local float fDist;
	local array<XGUnit> arrEnemyList;
	if (m_arrAllEnemies.Length == 0)
	{
		UpdateEnemiesList();
	}
	arrEnemyList = m_arrAllEnemies;
	fClosestDist = -1;
	// Iterate through all units.
	foreach arrEnemyList(kEnemy)
	{   
		if (!kEnemy.IsCriticallyWounded())
		{
			fDist = VSizeSq(kEnemy.GetGameStateLocation() - vPoint);
			if (kClosest == none || fDist < fClosestDist)
			{
				kClosest = kEnemy;
				fClosestDist = fDist;
			}
		}
	}
	return kClosest;
}
//------------------------------------------------------------------------------------------------
simulated function XComPresentationLayer PRES()
{
	return `PRES;
}

//------------------------------------------------------------------------------------------------
function UpdateDangerousAreas()
{
	local XComDestructibleActor kActor;
	local box kBounds;
	m_arrDangerZones.Length = 0;
	foreach WorldInfo.AllActors(class'XComDestructibleActor', kActor)
	{
		if (kActor.IsReadyToExplode())
		{
			kActor.GetComponentsBoundingBox(kBounds);
			// Extend by about a tile's length to ensure we get the full area.
			kBounds.Min -= vect(48,48,0);
			kBounds.Max += vect(48,48,0);
			m_arrDangerZones.AddItem(kBounds);
		}
	}
}

function array<vector> GetAllVisibleEnemyLocations()
{
	local array<vector> arrLocs;
	local XComGameStateHistory kHistory;
	local StateObjectReference kUnitRef;
	local XComGameState_Unit kUnit;
	local XComWorldData kWorld;
	local array<StateObjectReference> VisibleUnits;
	kHistory = `XCOMHISTORY;
	kWorld = `XWORLD;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemiesForPlayer(ObjectID, VisibleUnits);
	foreach VisibleUnits(kUnitRef)
	{
		kUnit = XComGameState_Unit(kHistory.GetGameStateForObjectID(kUnitRef.ObjectID));
		arrLocs.AddItem(kWorld.GetPositionFromTileCoordinates(kUnit.TileLocation));
	}
	return arrLocs;
}
simulated function UpdateCachedSquad( bool bDebugLogging=false)
{
	local int iAlien;
	local XGUnit kAlien;
`if(`notdefined(FINAL_RELEASE))
	local string strNames;
`endif

	m_arrCachedSquad.Length = 0;
	// Init each alien
	for (iAlien = 0; iAlien < m_kSquad.GetNumMembers(); iAlien++)
	{
		kAlien = m_kSquad.GetMemberAt( iAlien );
		if (kAlien.IsAliveAndWell() && kAlien.m_kBehavior != None)
		{
			m_arrCachedSquad.AddItem(kAlien);
// 			// Reset mind-merge
// 			kAlien.PerformMindMergeReset();
			kAlien.m_kBehavior.InitFromPlayer();
		}
	}
`if(`notdefined(FINAL_RELEASE))
	if (bDebugLogging)
	{
		foreach m_arrCachedSquad(kAlien)
		{
			strNames @= kAlien;
			if (kAlien.IsDormant())
				strNames $="(D)";
			//if (!kAlien.m_kBehavior.m_bCanEngage)
			//	strNames $="(Inactive)";
		}
		`Log("Updated Cached Squad: "@strNames);
	}
`endif
}

//------------------------------------------------------------------------------------------------
simulated function InitTurn()
{
	local X2AIBTBehaviorTree kBehaviorTree;
	local XComGameState_AIPlayerData AIPlayerData;
	AIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(GetAIDataID()));
	if ( m_iTurnInit < 0 || m_iTurnInit < AIPlayerData.m_iLastEndTurnHistoryIndex)
	{
		kBehaviorTree = `BEHAVIORTREEMGR;
		`Log("kBehaviorTree="$kBehaviorTree);
		if (`CHEATMGR != None && m_eTeam != eTeam_XCom)
		{
			`CHEATMGR.AIResetLastAbilityStrings();
		}
		ResetLogCache();
		ResetTargetSetCounts();
		ResetBehaviors();
		ResetTwoTurnAttackData();
		UpdateTerror();

		if (m_eTeam != eTeam_XCom)
		{
			`AIJobMgr.InitTurn();
		}
		GameStateInitTurnUpdate();

		AoETargetedThisTurn.Length = 0;

		UpdateCachedSquad();

		m_iTurnInit = `XCOMHISTORY.GetCurrentHistoryIndex();

		// Reset units that have taken an aggressive action.
		AggressiveUnitTracker.Length = 0;

		ClearTimer(nameof(WaitOnVisUpdateTimer)); // Clear if already running.
		bWaitOnVisUpdates = true; // Reset every turn.


		if (m_arrCachedSquad.Length == 0) // game over?  or waiting on chryssalid egg.
			return;
	}
}

function RegisterOffensiveAbilityUsage(int UnitID)
{
	if( AggressiveUnitTracker.Find(UnitID) == INDEX_NONE )
	{
		AggressiveUnitTracker.AddItem(UnitID);
	}
}

function int GetNumAggressiveUnitsThisTurn()
{
	return AggressiveUnitTracker.Length;
}

//------------------------------------------------------------------------------------------------
function OnEndTurn()
{
	if (m_kReinforcements.iCountdown == 1) // About to drop to 1.
	{
		PlayAkEvent(m_kNav.ReinforcementsIn1Turn);
	}
	if (m_kNav != None) 
		m_kNav.OnEndTurn();
	//m_arrTakenDamage.Length = 0;
	//m_arrTakenFire.Length = 0;

	ForceClearWaitForScamper();
	UpdateGameStateDataOnEndTurn();
}

function XComGameState GetLastTurnGameState()
{
	local XComGameState_AIPlayerData kAIPlayerData;
	if (m_eTeam != eTeam_Neutral)
	{
		kAIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(GetAIDataID()));
		return `XCOMHISTORY.GetGameStateFromHistory(kAIPlayerData.m_iLastEndTurnHistoryIndex, eReturnType_Copy, false);
	}
	return None; // Not tracked for civilians.
}

function UpdateGameStateDataOnEndTurn()
{
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData kAIPlayerData;

	if (CanUpdateGameState()) 
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("EndOfTurnAIDataUpdate");
		kAIPlayerData = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', GetAIDataID()));
		kAIPlayerData.m_iLastEndTurnHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();

		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}


function RestartYellCooldown()
{
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData kAIPlayerData;

	if (CanUpdateGameState()) // Not saved for civilians. (overwritten in XGAIPlayerCivilian.uc)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Restart Yell Cooldown");
		kAIPlayerData = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', GetAIDataID()));
		kAIPlayerData.m_iYellCooldown = kAIPlayerData.GetYellCooldownDuration();

		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}

function int GetYellCooldown()
{
	local XComGameState_AIPlayerData kAIPlayerData;
	if (m_eTeam != eTeam_Neutral) // Not saved for civilians. (overwritten in XGAIPlayerCivilian.uc)
	{
		kAIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(GetAIDataID()));
		return kAIPlayerData.m_iYellCooldown;
	}
	return 0; 
}

function ForceClearWaitForScamper()
{
	// Safeguard to get out of a possible AI hang.
	if (m_arrWaitForScamper.Length > 0)
	{
		`Warn("AI exited without finishing scamper!  Clearing scamper arrays." );
		ClearWaitForScamper();
		m_arrWaitForScamper.Length = 0;
	}
	if (m_bWaitingForScamper)
	{
		m_bWaitingForScamper = false;
	}
}

function bool CanUpdateGameState()
{
	if (m_eTeam != eTeam_Neutral && GetAIDataID() > 0 && !XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay) 
		return true;
	return false;
}

function GameStateInitTurnUpdate()
{
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData AIGameState;
	local XGAIGroup AIGroup;

	if( CanUpdateGameState() )
	{
		// Also update fight manager stats.  (Inactive turns tracker, num active engaged enemies tracker)
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AI FightMgr stats Update");
		AIGameState = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', GetAIDataID()));
		AIGameState.UpdateFightMgrStats(NewGameState);
		AIGameState.UpdateYellCooldowns();
		`TACTICALRULES.SubmitGameState(NewGameState);

		m_kNav.InitTurn(); // Moved to init after FightMgr stats are updated so the Fallback update can use the NumEngagedAI stat.
		if( AIGameState.StatsData.NumEngagedAI == 1 )
		{
			// Pull the engaged unit and check for fallback on that unit's group.
			m_kNav.GetGroupInfo(AIGameState.EngagedUnitRef.ObjectID, AIGroup);
			if( AIGroup != None )
			{
				AIGroup.CheckForFallback();
			}
		}
	}
}

//------------------------------------------------------------------------------------------------
function ResetBehaviors()
{
	local array<XComGameState_Unit> arrUnits;
	local XComGameState_Unit kUnit;
	local XGUnit kXGUnit;
	GetUnits(arrUnits);
	foreach arrUnits(kUnit)
	{
		kXGUnit = XGUnit(kUnit.GetVisualizer());
		if (kXGUnit != None && kXGUnit.m_kBehavior != None)
		{
			kXGUnit.m_kBehavior.m_bAbortMove = false;
		}
	}
}
function bool HasNoLivingUnits()
{
	local XComGameStateHistory History;
	local XComGameState_Unit kUnitState;

	// False if we have units incoming.
	if (m_kReinforcements.iCountdown > 0)
		return false;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', kUnitState)
	{
		if (kUnitState.IsAlive() && kUnitState.GetTeam() != eTeam_XCom)
		{
			return false;
		}
	}
	return true;
}
//------------------------------------------------------------------------------------------------

function bool HasRetreatLocation(XGUnit RetreatUnit, optional out StateObjectReference RetreatGroupRef)
{
	return m_kNav.HasRetreatLocation(RetreatUnit, RetreatGroupRef);
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string kStr;
	local int iX, iY;
	local XGUnit kUnit;
	local XComTacticalCheatManager kCheatMgr;
	local X2AIBTBehaviorTree BTMgr;
	kCheatMgr = `CHEATMGR;
	BTMgr = `BEHAVIORTREEMGR;
	if (kCheatMgr != None)
	{
		if (kCheatMgr.bDebugActiveAI)
		{
			iX= kCheatMgr.iRightSidePos; iY=100;
			kCanvas.SetPos(iX, iY);
			kCanvas.SetDrawColor(255,255,255);
			kStr = "Active:";
			kCanvas.DrawText(kStr);
			//kCanvas.SetDrawColor(0,255,0);
			//foreach m_arrActiveEngaged(kUnit)
			//{
			//	iY += 15;
			//	kCanvas.SetPos(iX, iY);
			//	kStr = ""$kUnit;
			//	kCanvas.DrawText(kStr);
			//}
			kCanvas.SetDrawColor(255,255,255);
			iX+= 80; iY = 100;
			kCanvas.SetPos(iX, iY);
			kStr = "Inactive:";
			kCanvas.DrawText(kStr);
			//kCanvas.SetDrawColor(255,255,128);
			//foreach m_arrInactive(kUnit)
			//{
			//	iY += 15;
			//	kCanvas.SetPos(iX, iY);
			//	kStr = ""$kUnit;
			//	kCanvas.DrawText(kStr);
			//}
		}
		iX=100;iY=400;
		if (kCheatMgr.bAIStates)
		{
			kCanvas.SetPos(iX, iY);
			iY += 15;
			kCanvas.SetDrawColor(255,255,255);
			kStr = "AI State:"@GetStateName()@"CurrUnitID="@CurrentMoveUnit.UnitObjectRef.ObjectID@"BTQueueCount="$BTMgr.ActiveBTQueue.Length@"Ready="$BTMgr.IsReady();
			kStr @="Phase="$m_ePhase;
			//if ( m_bWaitForVisualizer )
			//{
			//	kStr @= "Currently waiting for visualizer...";
			//}
			if (CurrentMoveUnit.UnitObjectRef.ObjectID != 0)
			{
				kUnit = XGUnit(`XCOMHISTORY.GetVisualizer(CurrentMoveUnit.UnitObjectRef.ObjectID));
				if (!kUnit.IsAlive())
				{
					kStr @= "-DEAD-";
				}
				if (kUnit.m_kBehavior == None)
				{
					kStr @= "AIBeh State= NULL BEHAVIOR";
				}
				else
				{
					kStr@="AIBeh State="$kUnit.m_kBehavior.GetStateName();
				}
			}
			if ( `BATTLE.IsPaused() )
			{
				kStr @= "  ---BATTLE IS PAUSED---";
			}

			kCanvas.DrawText(kStr);
		}

		//if (kCheatMgr.bShowTeamDestinations
		//	&& kCheatMgr.bShowTeamDestinationScores )
		//{
		//	ShowTeamDestinationScores(kCanvas);
		//}
		//else if (kCheatMgr.bShowTerrorDestinations
		//	&& kCheatMgr.bShowTerrorDestinationScores )
		//{
		//	ShowTeamDestinationScores(kCanvas, true);
		//}

		if (kCheatMgr.bAIShowLastAction)
		{
			kCheatMgr.ShowLastAIAction(kCanvas);
		}
		if( kCheatMgr.bDebugFightManager )
		{
			ShowFightManagerDebugInfo(kCanvas);
		}
		if( kCheatMgr.bDebugJobManager )
		{
			`AIJobMgr.ShowDebugInfo(kCanvas);
		}
		if( kCheatMgr.bDisplayAlertDataLabels )
		{
			kCheatMgr.DisplayAlertDataLabels(kCanvas);
		}
		if (kCheatMgr.bDebugChosen)
		{
			kCheatMgr.DisplayChosenInfo(kCanvas);
		}
		if (kCheatMgr.bDebugLostSpawning)
		{
			kCheatMgr.DisplayLostSpawningInfo(kCanvas);
		}
		// Draw destination scores text over debug spheres
		if( kCheatMgr.bDebugAIDestinations )
		{
			kUnit = XGUnit(`XCOMHISTORY.GetVisualizer(kCheatMgr.DebugMoveObjectID));
			if(kUnit != None && kUnit.m_kBehavior!=None)
			{
				kUnit.m_kBehavior.DebugDrawDestinationScoringText(kCanvas);
			}
		}
		if (kCheatMgr.bShowActiveBTNode)
		{
			BTMgr.ShowActiveBTNode(kCanvas);
		}
		if (kCheatMgr.bShowAoETargetResults)
		{
			foreach m_arrCachedSquad(kUnit)
			{
				if (kUnit != None && kUnit.m_kBehavior != None)
				{
					kUnit.m_kBehavior.DrawDebugAoETargets(kCanvas);
				}
			}

		}
	}
}

function ShowFightManagerDebugInfo(Canvas kCanvas)
{
	local XComGameState_AIPlayerData kPlayerData;
	kPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(GetAIDataID()));
	kPlayerData.ShowFightManagerDebugInfo(kCanvas);
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
simulated function XGUnit GetCloserUnit(XGUnit kActiveUnit, XGUnit kUnitA, XGUnit kUnitB)
{
	local float fDistSqA, fDistSqB;
	if (kUnitA == kUnitB || kUnitB == none || !kUnitB.IsAliveAndWell())
		return kUnitA;
	if (kUnitA == none || !kUnitA.IsAliveAndWell())
		return kUnitB;

	fDistSqA = VSizeSq(kUnitA.GetLocation() - kActiveUnit.GetLocation());
	fDistSqB = VSizeSq(kUnitB.GetLocation() - kActiveUnit.GetLocation());

	if (fDistSqA < fDistSqB)
		return kUnitA;
	
	return kUnitB;
}
//------------------------------------------------------------------------------------------------
// Store all logs from the last turn here.  Clears each turn begin.
static function LogAI(string strLog, name strLabel)
{
`if(`isdefined(AI_EXTRA_LOGGING))
`if(`notdefined(FINAL_RELEASE))

	local XGAIPlayer kPlayer;
	kPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if( kPlayer != None )
	{
		kPlayer.TurnLog.AddItem(strLog);
	}
	`Log(strLog,, strLabel);

`endif
`endif
}

// Add to AI log
static function LogAIBT(string strLog)
{
`if(`isdefined(AI_EXTRA_LOGGING))
	`if(`notdefined(FINAL_RELEASE))
		`BEHAVIORTREEMGR.LogNodeDetailText(strLog);
		LogAI(strLog, 'AI');
	`endif

`endif
}

function ResetLogCache()
{
	if (TurnLog.Length > 0)
	{
		LastTurnLog.Length = 0;
		LastTurnLog = TurnLog;
		TurnLog.Length = 0;
	}
}

static function DumpAILog(bool bBothTurns=false)
{
`if(`isdefined(AI_EXTRA_LOGGING))

	local string strLogLine;
	local XGAIPlayer kPlayer;

	kPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if (kPlayer != None)
	{
		if (bBothTurns)
		{
			`Log("************************** 2nd-to-LAST AI TURN LOG OUTPUT: **************************");
			foreach kPlayer.LastTurnLog(strLogLine)
			{
				`Log(strLogLine);
			}
		}
		`Log("************************** LAST AI TURN LOG OUTPUT: **************************");
		foreach kPlayer.TurnLog(strLogLine)
		{
			`Log(strLogLine);
		}
		`Log("************************** END OF AI LOGS **************************");
	}
`endif
}
//------------------------------------------------------------------------------------------------

function OnUnitKilled(XGUnit DeadUnit, XGUnit Killer)
{
	// AI unit died?
	if (DeadUnit.m_kPlayer == self) // one of ours
	{
		if (DeadUnit.m_kBehavior != None)
			DeadUnit.m_kBehavior.OnDeath(Killer);
	}
	else // XCom death
	{
		HandleEnemyDeath(DeadUnit);
	}
}

//------------------------------------------------------------------------------------------------
simulated function OnUnitWounded( XGUnit kUnit )
{
	// Treat as an enemy death.  Remove from bad cover list and from targetting lists.
	if (kUnit.GetPlayer() != self)
	{
		HandleEnemyDeath(kUnit);
	}
}
//------------------------------------------------------------------------------------------------
simulated function HandleEnemyDeath( XGUnit kUnit )
{
	// Remove from visible cached list.
	m_arrAllEnemies.RemoveItem(kUnit);
}
//------------------------------------------------------------------------------------------------
function OnMoveComplete( XGUnit kAlien)
{
	UpdateEnemiesList();
}
//------------------------------------------------------------------------------------------------
function OnUnitEndTurn(XGUnit Unit);
//------------------------------------------------------------------------------------------------

function ForceAbility(array<int> UnitIds, name AbilityName, int iTargetID=-1)
{	
	local XComGameStateHistory History;
	local int Index;
	local XComGameState_Unit kUnit;
	local XComGameState_Ability ViewerAbility;
	local XComGameStateContext AbilityContext;
	local StateObjectReference AbilityRef;
	History = `XCOMHISTORY;
	for( Index = 0; Index < UnitIds.Length; ++Index )
	{
		kUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitIds[Index]));
		//We are forcing the alert ability here, so we don't check conditions
		AbilityRef = kUnit.FindAbility(AbilityName);
		ViewerAbility = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		if( ViewerAbility != None && ViewerAbility.GetMyTemplateName() == AbilityName )
		{
			if ( ViewerAbility.GetMyTemplate().CheckShooterConditions(ViewerAbility, kUnit) == 'AA_Success' )
			{
				AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(ViewerAbility, iTargetID==-1?UnitIds[Index]:iTargetID);
				XComGameStateContext_Ability(AbilityContext).ResultContext.iCustomAbilityData = eAC_SeesSpottedUnit; // Passing alert cause through this var.
				if( AbilityContext.Validate() ) // May not validate due to chance to see.
					`XCOMGAME.GameRuleset.SubmitGameStateContext(AbilityContext);
			}
		}
	}
}

function RefreshDataID()
{
	local XComGameState_AIPlayerData kAIData;
	local XComGameStateHistory History;
	local int iAIPlayerID;
	local bool bFound;
	History = `XCOMHISTORY;
	iAIPlayerID = `BATTLE.GetAIPlayer().ObjectID;
	foreach History.IterateByClassType(class'XComGameState_AIPlayerData', kAIData)
	{
		if ( kAIData.m_iPlayerObjectID == iAIPlayerID )
		{
			m_iDataID = kAIData.ObjectID;
			bFound = true;
			break;
		}
	}
	if (!bFound)
	{
		`LogAI("No AI Player Data found for this unit!");
	}
}

event int GetAIDataID()
{
	if (m_iDataID <= 0)
	{
		RefreshDataID();
	}
	return m_iDataID;
}


function WaitForScamper( array<int> arrUnitsToWaitFor )
{
	local string strUnits;
	local int iID;
	m_arrWaitForScamper = arrUnitsToWaitFor;
	m_bWaitingForScamper = true;
	strUnits = "SCAMPER: Calling WaitForScamper on units: ";
	foreach arrUnitsToWaitFor(iID)
	{
		strUnits @= iID;
	}
	`LogAI(strUnits);
}


function ClearWaitForScamper()
{
	m_bWaitingForScamper = false;
	`LogAI("SCAMPER: Called ClearWaitForScamper.  arrWaitingForScamper.Length = "$m_arrWaitForScamper.Length);
}

// Reset TargetSetCounts at start of AI turn.  
function ResetTargetSetCounts()
{
	TargetSetCounts.Length=0;
}

function ResetTwoTurnAttackData()
{
	TwoTurnAttackTargets.Length = 0;
	TwoTurnAttackTiles.Length = 0;
}

// Retrieve number of times a unit was selected as a primary target this turn.
function int GetNumTimesUnitTargetedThisTurn(int TargetID)
{
	local int FindIndex;
	FindIndex = TargetSetCounts.Find('ObjectID', TargetID);
	// No entry means this unit was never targeted.
	if( FindIndex == INDEX_NONE )
	{
		return 0;
	}
	return TargetSetCounts[FindIndex].Count;
}

//This method is responsible for letting the movement ability submission code know whether the move should be 
//visualized simultaneously with another move or not. If a value of -1 is assigned to OutVisualizeIndex then the 
//unit will not move simultaneously. bInsertFenceAfterMove returns as 1 if a fence needs to be inserted after this
//move completes ( used for patrol / group moves )
function GetSimultaneousMoveVisualizeIndex(XComGameState_Unit UnitState, XGUnit UnitVisualizer,
										   out int OutVisualizeIndex, out int bInsertFenceAfterMove)
{
	local XComGameStateHistory History;			
	local XComGameStateContext TestContext;	

	History = `XCOMHISTORY;
	OutVisualizeIndex = -1; //By default, no simultaneous move	
	UnitVisualizer.bNextMoveIsFollow = false;

	//if we are scampering , we need to move simultaneously with prior moves
	if(UnitState.ReflexActionState == eReflexActionState_AIScamper)
	{
		OutVisualizeIndex = History.GetNumGameStates(); //Start at the current history index, the value will be decreased as the group is iterated

		//Loop backwards to find the AI reveal game state that started this scamper action, we go simultaneously with the action that is posted
		//immediately after
		foreach History.IterateContextsByClassType(class'XComGameStateContext', TestContext)
		{
			if (TestContext.IsA('XComGameStateContext_RevealAI'))
			{	
				break;
			}
			else if (TestContext.IsA('XComGameStateContext_Ability'))
			{
				OutVisualizeIndex = TestContext.AssociatedState.HistoryIndex;
			}
		}
	}
}

// Increment number of times a unit was targeted.
function IncrementUnitTargetedCount(int TargetID)
{
	local int FindIndex;
	FindIndex = TargetSetCounts.Find('ObjectID', TargetID);
	// Add entry for new target.
	if( FindIndex == INDEX_NONE )
	{
		FindIndex = TargetSetCounts.Length;
		TargetSetCounts.Add(1);
		TargetSetCounts[FindIndex].ObjectID = TargetID;
		TargetSetCounts[FindIndex].Count = 1;
	}	
	else
	{	
		TargetSetCounts[FindIndex].Count++;
	}
}

function UpdateTerror()
{
	local XComGameState_BattleData Battle;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	bCiviliansTargetedByAliens = Battle.AreCiviliansAlienTargets();
	History = `XCOMHISTORY;
	FacelessCivilians.Length = 0;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_Neutral && UnitState.IsAlien() && UnitState.IsCivilian() )
		{
			FacelessCivilians.AddItem(UnitState.ObjectID);
		}
	}
}

function RemoveFacelessFromList(out array<GameRulesCache_VisibilityInfo> EnemyList_out)
{
	local int ID, Index;
	if (EnemyList_out.Length > 0)
	{
		foreach FacelessCivilians(ID)
		{
			Index = EnemyList_out.Find('SourceID', ID);
			if( Index != INDEX_NONE )
			{
				EnemyList_out.Remove(Index, 1);
				if( EnemyList_out.Length == 0 )
				{
					return;
				}
			}
		}
	}
}

// Used in BehaviorTree checks as part of a condition to avoid attacking panicked and bound units.
function bool HasNonLastResortEnemies()
{
	if( ValidTargetsBasedOnLastResortEffects.Length > 0 )
	{
		if( LastResortTargetList.Length != ValidTargetsBasedOnLastResortEffects.Length
		   || LastResortTargetList[0] != ValidTargetsBasedOnLastResortEffects[0] )
		{
			return true;
		}
	}
	else
	{
		`LogAIBT("Possible AI Error?  No targets are valid based on last resort effects! ");
	}
	return false;
}

// Used in BehaviorTree checks and destination search to avoid moving toward panicked and bound units.
function bool IsTargetValidBasedOnLastResortEffects(int UnitID)
{
	if( !IsLastResortTarget(UnitID) )
	{
		return true;
	}

	if( ValidTargetsBasedOnLastResortEffects.Length > 0 )
	{
		return (ValidTargetsBasedOnLastResortEffects.Find(UnitID) != INDEX_NONE);
	}
	`LogAIBT("Possible AI Error?  No targets are valid based on last resort effects! ");
	return false;
}

// Used in behavior tree checks to avoid targeting panicked and bound units unless no one else is left.
function bool IsLastResortTarget( int UnitID )
{
	if( LastResortTargetList.Find(UnitID) != INDEX_NONE )
	{
		return true;
	}
	return false;
}

function bool IsAffectedByLastResortEffect(XComGameState_Unit UnitState, LastResortEffect Effect)
{
	local XComGameState_Effect EffectState;
	EffectState = UnitState.GetUnitAffectedByEffectState(Effect.EffectName);
	if( EffectState != None )
	{
		if( Effect.ApplyToAlliesOnly && UnitState.ControllingPlayer.ObjectID != ObjectID )
		{
			return false;
		}
		return true;
	}
	return false;
}

// Updated list of last resort and valid targets prior to each Behavior Tree run.
function UpdateValidAndLastResortTargetList()
{
	local XGPlayer kEnemyPlayer;
	local array<XComGameState_Unit> AllPlayableUnits, OriginalUnits;
	local XComGameState_Unit UnitState;
	local LastResortEffect LREffect;
	local bool bIsLastResortUnit;

	kEnemyPlayer = `BATTLE.GetEnemyPlayer(self);
	kEnemyPlayer.GetPlayableUnits(AllPlayableUnits);

	// Update - add mindcontrolled units to this list.  They are no longer playable units for the enemy, so we need to pull them from the original list.
	kEnemyPlayer.GetOriginalUnits(OriginalUnits);
	foreach OriginalUnits(UnitState)
	{
		if( AllPlayableUnits.Find(UnitState) == INDEX_NONE
		   && !(UnitState.bRemovedFromPlay || UnitState.IsDead() || UnitState.IsUnconscious() || UnitState.IsBleedingOut() || UnitState.IsStasisLanced() || UnitState.bDisabled) )
		{
			AllPlayableUnits.AddItem(UnitState);
		}
	}


	// Clear old lists.
	LastResortTargetList.Length = 0;
	ValidTargetsBasedOnLastResortEffects.Length = 0;

	foreach AllPlayableUnits(UnitState)
	{
		// Unit ID gets added to either the last resort list or the valid targets list.
		bIsLastResortUnit = false;
		foreach LastResortTargetEffects(LREffect)
		{
			if( IsAffectedByLastResortEffect(UnitState, LREffect))
			{
				LastResortTargetList.AddItem(UnitState.ObjectID);
				bIsLastResortUnit = true;
				break;
			}
		}

		if( bIsLastResortUnit )
		{
			continue;
		}
		ValidTargetsBasedOnLastResortEffects.AddItem(UnitState.ObjectID);
	}

	// If we have no other targets, our last resort targets become valid.
	if( ValidTargetsBasedOnLastResortEffects.Length == 0 && LastResortTargetList.Length > 0 )
	{
		ValidTargetsBasedOnLastResortEffects = LastResortTargetList;
	}
}

// The following code was moved to the bottom of the file since it misaligns the code from the debug step cursor when script debugging.
//------------------------------------------------------------------------------------------------
`if(`isdefined(FINAL_RELEASE))
	`define	DebugTickMacro
`else
	//------------------------------------------------------------------------------------------------
	simulated function DebugTick()
	{
		if (`CHEATMGR != None)
		{
			if (m_kNav != None)
				m_kNav.DebugDraw();
		}
	}
	`define	DebugTickMacro DebugTick();	
`endif
//------------------------------------------------------------------------------------------------
// Overwritten in the inactive state.  (this tick fn gets called when it is the AI player's turn.)
event Tick( float fDeltaT )
{
	`DebugTickMacro
}

//------------------------------------------------------------------------------------------------
// The Lost functions
function bool InitLostGroupMove(XGUnit SourceUnit, XComGameState_AIGroup MyGroupState, bool bScamperMove);
function bool HasLostMoveAssignments(XComGameState_AIGroup GroupState);
function LostActivateMove(XComGameState_AIGroup GroupState);
function bool LostAttackNextTarget(XComGameState_AIGroup MyGroupState);
function bool HasLostAttackAssignments(XComGameState_AIGroup GroupState);
function LostActivateAttacks();
function bool HasGroupAlreadyMovedThisTurn(int GroupObjectID);
function AddGroupEffectExclusion(Name EffectName);

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

defaultproperties
{
	m_eTeam = eTeam_Alien
	m_bPauseAlienTurn=false;
	m_iTurnInit=-1
	bAIHasKnowledgeOfAllUnconcealedXCom=true
}
