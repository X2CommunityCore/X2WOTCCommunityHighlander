class XGPlayer extends XGPlayerNativeBase
	native(Core);


const END_TURN_CANCEL_TARGETING_ACTIONS_TIMEOUT_SECONDS = 5.0f;

//=======================================================================================
//X-Com 2 Refactoring
//
//Member variables go in here, everything else will be re-evaluated to see whether it 
//needs to be moved, kept, or removed.

var transient privatewrite int ObjectID; //Unique identifier for this object - used for network serialization and game state searches
var transient privatewrite X2Camera AssociatedCamera; //Storage for any X2Camera that is associate with a player. Example: AI patrol group reveal camera
var transient privatewrite Actor FOWViewer; //Used to store a FOW viewer for AI reveal actions
//=======================================================================================

var	            XGSquad			        m_kSquad;
var	protectedwrite   array<XGUnit>      m_arrEnemiesSeen;	// What enemy units has this player seen?
var	protected   array<name>             m_arrPawnsSeen;	// What characters has this player seen?
var protected   XGUnit                  m_kActiveUnit;
var protected   int                     m_iTurn;
var	            int                     m_iHitCounter;	    
var	            int                     m_iMissCounter;	
var             int                     m_iNumOneShots;     // # of 1-shot kills this player has scored
var             bool                    m_bCantLose;

var protected int                                   m_iClientBeginTurn;
var protected int                                   m_iClientEndTurn;

var protected bool                                  m_bAcknowledgedSound;
var protected bool									m_bLoadedFromCheckpoint;

var repnotify bool                                  m_bPushStatePanicking;
var bool                                            m_bPopStatePanicking;

var EPlayerEndTurnType                              m_ePlayerEndTurnType;

var array<int>                                      m_arrTechHistory;
var XComUIBroadcastWorldMessage                     m_kBroadcastWorldMessage;       //  for panic message at start of turn
var bool                                            m_bCheckForEndTurnOnLoad;

/*  jbouscher - REFACTORING CHARACTERS
struct native PendingSpawnUnit         //  used for kismet spawned units
{
	var XGCharacter_Soldier kNewChar;
	var XComSpawnPoint kSpawnPoint;
	var int iContentRequests;
	var Delegate<UnitSpawnCallback> Callback;
	var bool bVIP;
};

var private PendingSpawnUnit                        m_kPendingSpawnUnit;
*/

var bool                                            m_bKismetControlledCombatMusic;     // For the tutorial, we control the combat music.

//  BeginningTurn state variables
var protected int m_iLoop;    
var protected XGUnit m_kLoopUnit;

// cancel any remaining fire actions when this timeout expires.   -tsmith 
var privatewrite float                              m_fEndTurnCancelTargetingActionsTimeoutSeconds;

delegate UnitSpawnCallback(XGUnit SpawnedUnit);

replication
{
	if( bNetDirty && Role == ROLE_Authority )
		m_kSquad, m_bPushStatePanicking, m_bPopStatePanicking;
}

simulated event ReplicatedEvent(Name VarName)
{
	if(VarName == 'm_kBeginTurnRepData') 
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(m_iClientBeginTurn) @ "m_kBeginTurnRepData=" $ XGPlayer_TurnRepData_ToString(m_kBeginTurnRepData), true, 'XCom_Net');
		if((m_kBeginTurnRepData.m_kActiveUnit != none || m_kBeginTurnRepData.m_bActiveUnitNone) && 
			m_iClientBeginTurn != m_kBeginTurnRepData.m_iTurn)
		{
			m_iClientBeginTurn = m_kBeginTurnRepData.m_iTurn;
			m_iTurn = m_iClientBeginTurn;
			GotoState('BeginningTurn');
		}
	}
	else if(VarName == 'm_kEndTurnRepData' )
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(m_iClientEndTurn) @ `ShowVar(m_iTurn) @ "m_kEndTurnRepData=" $ XGPlayer_TurnRepData_ToString(m_kEndTurnRepData), true, 'XCom_Net');
		if(m_iClientEndTurn != m_kEndTurnRepData.m_iTurn)
		{
			assert(m_iTurn == m_kEndTurnRepData.m_iTurn);
			m_iClientEndTurn = m_kEndTurnRepData.m_iTurn;
			m_bClientCheckForEndTurn = true;
			// change the UI here because the player can locally do the EndTurn() code before the turn rep data comes down and we dont want premature UI. -tsmith 
			if(WorldInfo.NetMode != NM_Standalone && m_kPlayerController != none && m_kPlayerController.IsLocalPlayerController())
			{
				`BATTLE.PushState('PlayerEndTurnUI');
			}
			// pass in a none unit because we want to check ALL units  -tsmith 
			CheckForEndTurn(none);
		}
	}

	super.ReplicatedEvent(VarName);
}

simulated function bool IsInitialReplicationComplete()
{
	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_kSightMgr.IsInitialReplicationComplete()) @ `ShowVar(m_kSquad.IsInitialReplicationComplete()));
	return  m_kSquad != none && m_kSquad.IsInitialReplicationComplete();
}

// called on the very first turn of the game. this is not necessarily the first turn for the player, its the first global turn. -tsmith 
reliable client function ClientOnFirstGameTurn(bool bActivePlayer);

simulated function InitBehavior( XGUnit kUnit, XComGameState_Unit UnitState )
{
	local class<XGAIBehavior> kClass;
	if (kUnit.m_kBehavior == none)
	{
		kClass = UnitState.GetBehaviorClass();
		if (kClass == None)
		{
			`LogAI("Error- Template class"@UnitState.GetMyTemplateName()@"behavior class invalid.  Using default, XGAIBehavior class.");
			kClass = class'XGAIBehavior';
		}
		kUnit.m_kBehavior = Spawn(kClass);
		kUnit.m_kBehavior.Init( kUnit );
	}
	else
	{
		`LogAI("Current state = "@GetStateName());
		kUnit.m_kBehavior.LoadInit( kUnit );
	}
}

function OnBeginTacticalPlay();

function SetAssociatedCamera(X2Camera SetCamera)
{
	local XComCamera Cam;
					
	Cam = XComCamera(GetALocalPlayerController().PlayerCamera);
	if(Cam == none) return;

	//Remove the existing camera if one exists
	if( AssociatedCamera != none )
	{
		Cam.CameraStack.RemoveCamera(AssociatedCamera);
	}

	AssociatedCamera = SetCamera;
}

function SetFOWViewer(Actor InFOWViewer)
{
	FOWViewer = InFOWViewer;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
function SetPlayerController( XComTacticalController playerController )
{
	m_kPlayerController = playerController;
}

function int GetLastAlertTurn() { return -1; } // Overwritten in AIPlayer.
function SetLastAlertTurn(int iTurn, vector vAlertLoc) {}         // "

//------------------------------------------------------------------------------------------------
protected native function bool TestUnitCoverExposure( XComCoverPoint kTestCover, XGUnitNativeBase kEnemy, optional out float fDot, bool bDrawLines=false);
//------------------------------------------------------------------------------------------------
/** kEnemy, if NONE, tests against all visible enemies.  Otherwise tests only the one. **/
function bool IsCoverExposed(XComCoverPoint kTestCover, XGUnit kEnemy, const out array<XGUnit> arrEnemies, optional out float fDot,  optional bool bDrawLines=false)
{
	if (kEnemy != none)
	{
		return TestUnitCoverExposure(kTestCover, kEnemy, fDot, bDrawLines);
	}
	else if (arrEnemies.Length > 0)
	{
		foreach arrEnemies(kEnemy)
		{
			if (TestUnitCoverExposure(kTestCover, kEnemy, fDot, bDrawLines))
				return true;
		}
	}

	return false;
}

//------------------------------------------------------------------------------------------------
simulated function GetAllEnemies(out array<XGUnit> arrEnemies)
{
	local XGUnit kUnit;
	kUnit = m_kSquad.GetNextGoodMember(,,false);
	arrEnemies.Length = 0;
	while (kUnit != none)
	{
		arrEnemies.AddItem(kUnit);
		kUnit = m_kSquad.GetNextGoodMember(kUnit,,false);
	}
}

simulated function UpdateVisibility()
{
	
}

// ---------------------------------------------------------------------------
// changes the current unit and maintains the internal representations
// for the Controller and Input classes
// ---------------------------------------------------------------------------
simulated function SetActiveUnit( XGUnit kNewActive)
{
	if (m_kActiveUnit != None)
	{
		m_kActiveUnit.m_kReachableTilesCache.ForceCacheUpdate();
	}

	m_kActiveUnit = kNewActive;

	if( m_kPlayerController != none)
	{
		if (m_kPlayerController.GetActiveUnit() != none )
		{
			m_kPlayerController.GetActiveUnit().Deactivate();
		}
		
		m_kPlayerController.ActiveUnitChanged();
	}

	if( kNewActive != none )
	{
		kNewActive.Activate();
	}

	if (XComCheatManager(GetALocalPlayerController().CheatManager) != none)
	{
		XComCheatManager(GetALocalPlayerController().CheatManager).m_kVisDebug = kNewActive;
	}

}

simulated function XGUnit GetActiveUnit()
{
	return m_kActiveUnit;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
simulated function bool IsTurnDone()
{
	return IsInState( 'Inactive' );
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
simulated function XGSquad GetSquad()
{
	return m_kSquad;
}

event XGSquadNativeBase GetNativeSquad()
{
	return m_kSquad;
}

event XGSquadNativeBase GetEnemySquad()
{
	return `BATTLE.GetEnemySquad(self);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
simulated function bool HasSeenEnemy( XGUnit kEnemy )
{
	return m_arrEnemiesSeen.Find( kEnemy ) != -1;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
simulated function AddSeenEnemy( XGUnit kEnemy )
{
	if( !HasSeenEnemy( kEnemy ) )
		m_arrEnemiesSeen.AddItem( kEnemy );
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
simulated function bool HasSeenCharacter( name CharTemplate )
{
	return m_arrPawnsSeen.Find( CharTemplate ) != -1;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
simulated function AddSeenCharacter( name CharTemplate )
{
	if( !HasSeenCharacter( CharTemplate ) )
		m_arrPawnsSeen.AddItem( CharTemplate );
}

//------------------------------------------------------------------------------------------------
simulated function XGUnit GetNearestEnemy(Vector vPoint, optional out float fClosestDist)
{
	local XGSquad kEnemySquad;
	local XGUnit kEnemy, kClosest;
	local float fDist;
	kEnemySquad = `BATTLE.GetEnemySquad(Self);
	kEnemy = kEnemySquad.GetNextGoodMember(kEnemy,,false);
	fClosestDist = -1;
	// Iterate through all units.
	while (kEnemy != None)
	{   
		fDist = VSizeSq(kEnemy.GetLocation() - vPoint);
		if (kClosest == none || fDist < fClosestDist)
		{
			kClosest = kEnemy;
			fClosestDist = fDist;
		}
		kEnemy = kEnemySquad.GetNextGoodMember(kEnemy,,false);
	}
	return kClosest;
}

function OnHearEnemy( XGUnit kUnit, XGUnit kEnemy )
{
	// only used by AI
}

function OnUnitSeen(XGUnit MyUnit, XGUnit EnemyUnit)
{
	
}

// jboswell: need to do this for any killed unit, as each killed unit changes the
// visibility status of the world
function OnUnitKilled(XGUnit DeadUnit, XGUnit Killer)
{
	
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function XGUnit SpawnUnit( XComGameState_Unit UnitState, PlayerController kPlayerController, Vector kLocation, Rotator kRotation, XGSquad kSquad, optional bool bDestroyOnBadLocation = false, optional XComSpawnPoint kSpawnPoint, optional bool bSnapToGround=true, optional bool bLoadingSave, optional const XComGameState_Unit ReanimatedFromUnit = None)
{
	local XGUnit kUnit;

	if (kLocation.Z <= WorldInfo.KillZ)
	{
		`warn( "ERROR: **** XCom Unit wants to spawn below WorldInfo::killZ, will immediately die.  Move spawn point higher or set killZ lower. ****" );
	}

	kUnit = Spawn(class'XGUnit', kPlayerController,, kLocation, kRotation,,, m_eTeam);
	kUnit.SetObjectIDFromState(UnitState);

	if (!kUnit.Init(self, kSquad, UnitState, bDestroyOnBadLocation, bSnapToGround, ReanimatedFromUnit ))
	{
		kUnit.Destroy();
		return none;
	}
	
	if (kSpawnPoint != none)
	{
		kSpawnPoint.m_kLastActorSpawned = kUnit;
	}

	return kUnit;
}

//------------------------------------------------------------------------------------------------
function RemoveUnit(XGUnit kUnit, optional bool bUninitOnly=false)
{
	local XGSquad kSquad;
	kSquad = kUnit.GetSquad();

	// Uninit called first to ensure that unit ring is removed ~khirsch
	kUnit.Uninit();

	if (!bUninitOnly)
	{
		if (kSquad != none)
			kSquad.RemoveUnit(kUnit);

		kUnit.Destroy();
	}
}
//------------------------------------------------------------------------------------------------

function Uninit()
{
	m_kSquad.Uninit();
	m_kSquad.Destroy();
	m_kSquad = None;
}

//------------------------------------------------------------------------------------------------
function Init( bool bLoading=false )
{
}
//------------------------------------------------------------------------------------------------
// MHU - Save/Load requirement, primarily for AIPlayer to override and do custom load work.
function LoadInit()
{
	SetOwner(m_kPlayerController);
	m_kSquad.SetOwner(m_kPlayerController);
	m_kSquad.InitLoadedMembers();
}

//------------------------------------------------------------------------------------------------
simulated function BeginTurn()
{
	`LogAI("XGPlayer::BeginTurn::"$GetStateName() @m_eTeam);
	m_iHitCounter = 0;
}

simulated function bool EndTurn(EPlayerEndTurnType eEndTurnType)
{
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateContext_TacticalGameRule EndTurnContext;
	if (m_eTeam == eTeam_Alien)
	{
		`LogAIActions("Calling XGPlayer::EndTurn()");
	}

	`LogAI("XGPlayer::EndTurn::"$GetStateName() @m_eTeam@ eEndTurnType);

	// deselect the current unit immediately, to prevent players exploiting a one frame window
	// where they would still be able to activate abilities
	XComTacticalController(GetALocalPlayerController()).Visualizer_ReleaseControl();

	TacticalRules = `TACTICALRULES;
	if( (eEndTurnType == ePlayerEndTurnType_PlayerInput && (TacticalRules.GetLocalClientPlayerObjectID() == TacticalRules.GetCachedUnitActionPlayerRef().ObjectID || `CHEATMGR != none && `CHEATMGR.bAllowSelectAll)) ||
		eEndTurnType == ePlayerEndTurnType_AI )
	{
		EndTurnContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
		EndTurnContext.GameRuleType = eGameRule_SkipTurn;
		EndTurnContext.PlayerRef = TacticalRules.GetCachedUnitActionPlayerRef();
		EndTurnContext.SetSendGameState(true);

		`XCOMGAME.GameRuleset.SubmitGameStateContext(EndTurnContext);
		EndTurnContext.SetSendGameState(false);
	}

	return false;
}

//------------------------------------------------------------------------------------------------
function vector GetRandomValidPoint(XGUnit kUnit, vector vCenter, float fMaxRadius, optional float fMinRadius = 0.0f, optional vector vDir=vect(0,0,0) )
{
	local Vector vRandPoint;
	vRandPoint = GetRandomPoint(vCenter, fMaxRadius, fMinRadius, vDir);
	vRandPoint = XComTacticalGRI(WorldInfo.GRI).GetClosestValidLocation(vRandPoint, kUnit,,false);
	return vRandPoint;
}
//------------------------------------------------------------------------------------------------
simulated function bool DropLocationToGround( out vector vLocation, optional float Distance = 128.0f )
{
	local vector HitLocation, HitNormal;

	if ( Trace( HitLocation, HitNormal, vLocation + vect(0,0,-1) * Distance, vLocation, false ) != none )
	{
		vLocation = HitLocation;
		return true;
	}

	return false;
}

//------------------------------------------------------------------------------------------------
function vector GetRandomPoint( vector vCenter, float fMaxRadius, optional float fMinRadius = 0.0f, optional vector vDir=vect(0,0,0))
{
	local Vector vDestination;
	local float fRange, fScalar;

	if (VSizeSq(vDir) < 0.0001f)
	{
		vDir = VRand();
	}
	vDestination = vDir;                     
	vDestination.Z = 0;                         // Make it a 2D vector
	fRange = fMaxRadius - fMinRadius;
	fScalar = `SYNC_FRAND()*fRange + fMinRadius;
	vDestination = Normal(vDestination);
	vDestination *= fScalar;
	vDestination += vCenter; // move to center
//	DropLocationToGround(vDestination);
	return vDestination;
}
//------------------------------------------------------------------------------------------------
simulated function bool WaitingForSquadActions()
{
	local XGUnit kUnit;
	kUnit = m_kSquad.GetNextGoodMember();
	
	while (kUnit != none)
	{
		kUnit = m_kSquad.GetNextGoodMember(kUnit,,false);
	}
	return false;
}

function bool CheckAllClientsHaveEndedTurn(bool bCountPathActionsAsIdle)
{
	local bool bAllClientsHaveEndedTurn;
	local bool bPlayerEndedTurn;
	local bool bIsSquadNetworkIdle;

	bPlayerEndedTurn = m_ePlayerEndTurnType != ePlayerEndTurnType_TurnNotOver;
	
	// check for squad members being network idle -tsmith 
	bIsSquadNetworkIdle = m_kSquad.IsNetworkIdle(bCountPathActionsAsIdle);

	`log(self $ "::" $ GetFuncName() @ `ShowVar(m_ePlayerEndTurnType) @ `ShowVar(bPlayerEndedTurn) @ `ShowVar(bIsSquadNetworkIdle) @ "IsLocalPlayer=" $ m_kPlayerController.IsLocalPlayerController(), true, 'XCom_Net');

	bAllClientsHaveEndedTurn = bPlayerEndedTurn && bIsSquadNetworkIdle;

	return bAllClientsHaveEndedTurn;
}
//-------------------------------------------------------
simulated function bool CanOneShot( int iDamage, int iUnitHP, XGUnit kDamageDealer )
{
	return true;
}

//------------------------------------------------------------------------------------------------

simulated function bool RemainingAvailableUnitsArePanicked(XGUnit kNext)
{
	local XGUnit kStart;
	kStart = kNext;

	do
	{
		if ( kNext.IsPanicked() )
		{
			kNext = GetSquad().GetNextGoodMember(kNext, false);
		}
		else
		{
			// At least one remaining unit has not panicked and can be commanded
			return false;
		}
	} until (kNext == kStart);

	// All remaining available units are panicked and cannot be commanded this turn.
	// Please note: This does not mean all units in the squad have panicked. There
	// may be other units in the squad that have not panicked, but have already been
	// issued commands. We are simply saying there are no units left that can be commanded.
	return true;
}

//=======================================================================================
//X-Com 2 Refactoring
//

simulated static function CreateVisualizer(XComGameState_Player SyncPlayerState)
{
	local XComTacticalController kLocalPC;
	local class<actor> PlayerClassObject;
	local XGPlayer PlayerVisualizer;
	
	kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());

	PlayerClassObject = class<actor>(class'Engine'.static.FindClassType(string( SyncPlayerState.PlayerClassName) ));

	PlayerVisualizer = XGPlayer(kLocalPC.Spawn( PlayerClassObject, kLocalPC,,,,,,SyncPlayerState.TeamFlag ));
	PlayerVisualizer.ObjectID = SyncPlayerState.ObjectID;
	PlayerVisualizer.m_kSquad = kLocalPC.Spawn( class'XGSquad',PlayerVisualizer,,,,,,SyncPlayerState.TeamFlag );	
	PlayerVisualizer.m_kSquad.m_kPlayer = PlayerVisualizer;	
	PlayerVisualizer.Init();
	PlayerVisualizer.SetPlayerController( kLocalPC );
	
	`XCOMHISTORY.SetVisualizer(SyncPlayerState.ObjectID, PlayerVisualizer);
	//RAM - we need to figure out what / how to deal with Unreal's crazy ETeam assumptions. If this is not set up 
	//correctly EVERYTHING falls apart.
	`BATTLE.AddPlayer(PlayerVisualizer);
	// If the player state is the local player, then setup the visualizer as the local player.
	if( !(IsRemotePlayer(SyncPlayerState.ObjectID) || SyncPlayerState.IsAIPlayer()) )
	{
		kLocalPC.SetControllingPlayer( SyncPlayerState );
		kLocalPC.SetTeamType( SyncPlayerState.TeamFlag );
	}
}

/// <summary>
/// Gets a list of all units that belong to any player
/// </summary>
simulated function GetUnitsForAllPlayers(out array<XComGameState_Unit> Units)
{
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit OutCacheData;
	local XComGameState_Unit CurrentUnitState;		

	Ruleset = `XCOMGAME.GameRuleset;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', CurrentUnitState, eReturnType_Reference)
	{
		if( !CurrentUnitState.bRemovedFromPlay && CurrentUnitState.IsAlive() && CurrentUnitState.ControllingPlayer.ObjectID > 0 && !CurrentUnitState.GetMyTemplate().bIsCosmetic )
		{
			Ruleset.GetGameRulesCache_Unit(CurrentUnitState.GetReference(), OutCacheData);
			Units.AddItem(CurrentUnitState);
		}
	}
}

/// <summary>
/// Gets a list of all units that belong to this player
/// </summary>
simulated function GetUnits(out array<XComGameState_Unit> Units, bool bSkipTurrets=false, bool bSkipPanicked=false, bool bSkipUnselectable=false)
{
	local XComGameState_Unit CurrentUnitState;		

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', CurrentUnitState, eReturnType_Reference)
	{
		if( CurrentUnitState.ControllingPlayer.ObjectID == ObjectID )
		{			
			if( CurrentUnitState.IsTurret() && bSkipTurrets )
			{
				continue;
			}
			if (CurrentUnitState.bPanicked && bSkipPanicked)
			{
				continue;
			}
			if( bSkipUnselectable && CurrentUnitState.GetMyTemplate().bNeverSelectable ) // Currently includes only mimic beacons.
			{
				continue;
			}
			Units.AddItem(CurrentUnitState);
		}
	}
}

//  Checks for mind control and hands back all units that originally belonged to this player.
//  Hands back the CURRENT state of the unit (e.g. mind controlled units will reflect that they are on another team)
simulated function GetOriginalUnits(out array<XComGameState_Unit> Units, bool bSkipTurrets=false, bool bSkipCosmetic=true, bool bSkipMindControlledUnits=false)
{
	local XComGameStateHistory History;
	local XComGameState_Unit CurrentUnitState, OldUnitState;
	local XComGameState_Effect MindControlEffect, OriginalEffect;
	local array<StateObjectReference> UnitRefs;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', CurrentUnitState, eReturnType_Reference)
	{
		if (CurrentUnitState.GetMyTemplate().bIsCosmetic && bSkipCosmetic)
			continue;

		if (CurrentUnitState.GetMyTemplateName() == 'MimicBeacon')
			continue;

		if (CurrentUnitState.IsTurret() && bSkipTurrets)
			continue;

		MindControlEffect = CurrentUnitState.GetUnitAffectedByEffectState(class'X2Effect_MindControl'.default.EffectName);

		if (MindControlEffect != none && bSkipMindControlledUnits)
			continue;

		if (MindControlEffect != none)
		{
			OriginalEffect = XComGameState_Effect(History.GetOriginalGameStateRevision(MindControlEffect.ObjectID));
			OldUnitState = XComGameState_Unit(History.GetGameStateForObjectID(CurrentUnitState.ObjectID,,OriginalEffect.GetParentGameState().HistoryIndex - 1));
			if(OldUnitState.ControllingPlayer.ObjectID == ObjectID && UnitRefs.Find('ObjectID', CurrentUnitState.ObjectID) == INDEX_NONE)
			{
				Units.AddItem(CurrentUnitState);
				UnitRefs.AddItem(CurrentUnitState.GetReference());
			}
		}
		else if(CurrentUnitState.ControllingPlayer.ObjectID == ObjectID && UnitRefs.Find('ObjectID', CurrentUnitState.ObjectID) == INDEX_NONE)
		{
			Units.AddItem(CurrentUnitState);
			UnitRefs.AddItem(CurrentUnitState.GetReference());
		}
	}
}

/// <summary>
/// Gets a list of all units that are alive and belong to this player
/// </summary>
simulated function GetAliveUnits(out array<XComGameState_Unit> Units, bool bSkipTurrets=false, bool bSkipUnselectable=false)
{
	local array<XComGameState_Unit> AllUnits;
	local XComGameState_Unit Unit;

	GetUnits(AllUnits, bSkipTurrets, , bSkipUnselectable);
	foreach AllUnits(Unit)
	{
		if(Unit.IsAlive())
		{
			Units.AddItem(Unit);
		}
	}
}

/// <summary>
/// Gets a list of all units that are dead and belong to this player
/// </summary>
simulated function GetDeadUnits(out array<XComGameState_Unit> Units, bool bSkipTurrets=false, bool bSkipUnselectable=false)
{
	local array<XComGameState_Unit> AllUnits;
	local XComGameState_Unit Unit;

	GetUnits(AllUnits, bSkipTurrets,, bSkipUnselectable);
	foreach AllUnits(Unit)
	{
		if(Unit.IsDead())
		{
			Units.AddItem(Unit);
		}
	}
}

/// <summary>
/// Gets a list of all units that are alive, but incapacitated, and belong to this player
/// </summary>
simulated function GetIncapacitatedUnits(out array<XComGameState_Unit> Units, bool bSkipTurrets=false)
{
	local array<XComGameState_Unit> AllUnits;
	local XComGameState_Unit Unit;

	GetUnits(AllUnits, bSkipTurrets);
	foreach AllUnits(Unit)
	{
		if(Unit.IsIncapacitated())
		{
			Units.AddItem(Unit);
		}
	}
}

/// <summary>
/// Gets a list of all units that are confused and belong to this player
/// </summary>
simulated function GetConfusedUnits(out array<XComGameState_Unit> Units, bool bSkipTurrets=false)
{
	local array<XComGameState_Unit> AllUnits;
	local XComGameState_Unit Unit;

	GetUnits(AllUnits, bSkipTurrets);
	foreach AllUnits(Unit)
	{
		if(Unit.IsConfused())
		{
			Units.AddItem(Unit);
		}
	}
}

/// <summary>
/// Gets a list of all units that still on the map and belong to this player
/// </summary>
simulated function GetUnitsOnMap(out array<XComGameState_Unit> Units, bool bSkipTurrets=false, bool bSkipUnselectable=false)
{
	local array<XComGameState_Unit> AllUnits;
	local XComGameState_Unit Unit;

	GetUnits(AllUnits, bSkipTurrets, , bSkipUnselectable);
	foreach AllUnits(Unit)
	{
		if(!Unit.bRemovedFromPlay)
		{
			Units.AddItem(Unit);
		}
	}
}

/// <summary>
/// Gets a list of all units that a player may be able to use, even if they have no actions left
/// </summary>
simulated function GetPlayableUnits(out array<XComGameState_Unit> Units, bool bSkipTurrets=false)
{
	local array<XComGameState_Unit> AllUnits;
	local XComGameState_Unit Unit;
	local X2CharacterTemplate Template;

	GetUnits(AllUnits, bSkipTurrets);
	foreach AllUnits(Unit)
	{
		if(!( Unit.bRemovedFromPlay 
			  || Unit.IsDead() 
			  || Unit.IsUnconscious() 
			  || Unit.IsBleedingOut() 
			  || Unit.IsStasisLanced() 
			  || Unit.bDisabled ))
		{
			Template = Unit.GetMyTemplate();
			// Skip cosmetic units.   And Unselectable units (mimic beacons).
			if( !(Template.bIsCosmetic || Template.bNeverSelectable) )
			{
				Units.AddItem(Unit);
			}
		}
	}
}

/// <summary>
/// Gets a list of all units that belong to this player and have moves remaining
/// </summary>
simulated function GetUnitsWithMovesRemaining(out array<XComGameState_Unit> OutUnits, bool bSkipTurrets=false, bool bSkipPanicked=false)
{
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit OutCacheData;
	local array<XComGameState_Unit> AllUnits;
	local XComGameState_Unit Unit;
	local AvailableAction CheckAction;
	local int ActionIndex;

	Ruleset = `XCOMGAME.GameRuleset;

	GetUnits(AllUnits, bSkipTurrets, bSkipPanicked);
	foreach AllUnits(Unit)
	{
		if (Unit.m_bSubsystem) // Don't consider subsystems.
			continue;
		Ruleset.GetGameRulesCache_Unit(Unit.GetReference(), OutCacheData);

		for( ActionIndex = 0; ActionIndex < OutCacheData.AvailableActions.Length; ++ActionIndex )
		{
			CheckAction = OutCacheData.AvailableActions[ActionIndex];
			if( CheckAction.bInputTriggered && CheckAction.AvailableCode == 'AA_Success' )
			{
				OutUnits.AddItem(Unit);
				break;
			}
		}
	}
}

// <summary>
// Gets a list of all units that are active - Living, not in green alert & Revealed AI.
// </summary>
simulated function GetAllActiveUnits(out array<XComGameState_Unit> Units, bool bSkipTurrets = false, bool bSkipUnselectable = false)
{
	local array<XComGameState_Unit> AllUnits;
	local XComGameState_Unit Unit;

	GetUnits(AllUnits, bSkipTurrets, , bSkipUnselectable);
	foreach AllUnits(Unit)
	{
		if (Unit.IsAlive() && !Unit.IsUnrevealedAI())
		{
			Units.AddItem(Unit);
		}
	}
}

/// <summary>
/// Called by the visualizer on begin turns
/// </summary>
simulated function OnBeginTurnVisualized(int InitiativeObjectID)
{
	local ETurnOverlay OverlayType;
	local XComGameState_AIGroup GroupState;
	local XComGameState_Unit UnitState;
	local array<int> GroupMemberIDs;
	local bool IsModTeam; //issue #188 variable
	
	IsModTeam = `XENGINE.IsSinglePlayerGame() && (m_eTeam == eTeam_One || m_eTeam == eTeam_Two); //issue #188 - check if this is a mod added team
	GroupState = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(InitiativeObjectID));
	if(( GroupState != None && GroupState.bSummoningSicknessCleared && GroupState.GetLivingMembers(GroupMemberIDs)) || `REPLAY.bInTutorial)  // only change Turn Banner when the first initiative group with valid members activates on each turn.
	{
		if( IsRemote() || IsModTeam) //issue #188 - let eTeam_One and eTeam_Two auto pass in singleplayer to this, we use our new overlay type for eTeam_One
		{
			if( m_eTeam == eTeam_Two){
				OverlayType = eTurnOverlay_Remote;
			}
			if( m_eTeam == eTeam_One){
				OverlayType = eTurnOverlay_OtherTeam;
			}
		}
		else if( m_eTeam == eTeam_Alien )
		{
			OverlayType = eTurnOverlay_Alien;

			// special case for engaged chosen
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GroupState.m_arrMembers[0].ObjectID));
			if( UnitState != None && UnitState.IsChosen() && UnitState.IsAlive() && !UnitState.IsIncapacitated() && !UnitState.bRemovedFromPlay )
			{
				OverlayType = eTurnOverlay_Chosen;
			}

		}
		else if( m_eTeam == eTeam_TheLost )
		{
			OverlayType = eTurnOverlay_TheLost;
		}
		else if( m_eTeam == eTeam_Resistance )
		{
			OverlayType = eTurnOverlay_Resistance;
		}
		else
		{
			OverlayType = eTurnOverlay_Local;
		}

		`PRES.UIEndTurn(OverlayType);
	}
}

simulated function OnEndTurnVisualized()
{
	// Release visualizer control here helps sort out demo/tutorial/replay issues.
	if (m_kPlayerController != none)
	{
		m_kPlayerController.Visualizer_ReleaseControl();
	}
}

/// <summary>
/// Called by the rules engine when the unit action phase has started for this player in "NextPlayer()". This event is called once for each player
/// during the unit actions phase.
/// </summary>
simulated function OnUnitActionPhaseBegun_NextPlayer();

simulated function OnUnitActionPhase_NextGroup(StateObjectReference AIGroupRef);


/// <summary>
/// Called by the rules engine when the unit action phase has ended for this player in "NextPlayer()". This event is called once for each player
/// during the unit actions phase.
/// </summary>
simulated function OnUnitActionPhaseFinished_NextPlayer()
{
	`assert(m_kPlayerController != none);
	m_kPlayerController.Visualizer_ReleaseControl(); 
	class'XGAIPlayer_TheLost'.static.UpdateLostOnPlayerTurnEnd();
}

/// <summary>
/// Called by the rules engine each time it evaluates whether any units have available actions in "ActionsAvailable()". The first unit with available actions
/// is passed into the method.
/// </summary>
/// <param name="bWithAvailableActions">The first unit state with available actions</param>
simulated function OnUnitActionPhase_ActionsAvailable(XComGameState_Unit UnitState)
{
	// Don't select units if we are in tutorial mode, unit selection is done from the replay
	if( !class'XComGameStateVisualizationMgr'.static.VisualizerBusy() && !`REPLAY.bInTutorial ) 
	{
		`assert(m_kPlayerController != none);
		if( m_kPlayerController.ControllingUnit.ObjectID != UnitState.ObjectID )
		{
			m_kPlayerController.Visualizer_SelectUnit(UnitState);
		}
	}
}

/// <summary>
/// Returns true if this player visualizer is associated with a remote network player.
/// </summary>
simulated function bool IsRemote()
{
	return IsRemotePlayer(ObjectID);
}

simulated static function bool IsRemotePlayer(int PlayerObjectID)
{
	local XComGameState_Player PlayerState;
	local UniqueNetId LocalUid, GameStateUid, EmptyUid;
	local bool bIsLocalPlayer;

	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(PlayerObjectID));

	LocalUid = class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().PlayerReplicationInfo.UniqueId;
	GameStateUid = PlayerState.GetGameStatePlayerNetId();

	bIsLocalPlayer = ((GameStateUid.Uid == EmptyUid.Uid) || (LocalUid == GameStateUid));

	return !(bIsLocalPlayer || PlayerState.IsAIPlayer());
}

function OnPlayerAbilityCooldown( name strAbility, int iCooldown );

//This method is responsible for letting the movement ability submission code know whether the move should be 
//visualized simultaneously with another move or not. If a value of -1 is assigned to OutVisualizeIndex then the 
//unit will not move simultaneously.
function GetSimultaneousMoveVisualizeIndex(XComGameState_Unit UnitState, XGUnit UnitVisualizer,
										   out int OutVisualizeIndex, out int bInsertFenceAfterMove)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;

	History = `XCOMHISTORY;
	OutVisualizeIndex = -1; //By default, no simultaneous move

	//Check whether this move is a follow action. If so, search backward in the history until we find another move
	//and sync our move with it
	if(UnitVisualizer.bNextMoveIsFollow)
	{
		foreach History.IterateContextsByClassType( class'XComGameStateContext_Ability', AbilityContext )
		{
			if(AbilityContext.InputContext.MovementPaths.Length > 0)
			{	
				OutVisualizeIndex = AbilityContext.GetFirstStateInEventChain().HistoryIndex - 1;
				break;
			}
		}
	}
}

//=======================================================================================

defaultproperties
{
	m_eTeam = eTeam_XCom;
	//bAlwaysRelevant=true
	//RemoteRole=ROLE_SimulatedProxy
	RemoteRole=ROLE_None
	bAlwaysRelevant=false
	m_iMissCounter=1
	m_bLoadedFromCheckpoint=false
}
