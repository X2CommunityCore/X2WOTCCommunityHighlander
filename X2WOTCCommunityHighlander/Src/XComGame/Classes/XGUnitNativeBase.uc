class XGUnitNativeBase extends Actor
	implements(X2VisualizerInterface)
	native(Unit)
	nativereplication 
	config(GameCore);


// MHU - Ordering is important, enums below mapped according to
//       XComAnimNodeCover enums. If you make changes, make sure
//       the mapping is still valid.
enum ECoverState
{
	eCS_None,
	eCS_LowLeft,
	eCS_LowRight,
	eCS_HighLeft,
	eCS_HighRight,
	eCS_HighFront,
	eCS_HighBack,
	eCS_LowFront,
	eCS_LowBack,
};

// jboswell: used to dictate which way a unit should be facing as influenced
// by the interaction point they are standing on
enum EInteractionFacing
{
	eIF_None<DisplayName=None>, // Undefined
	eIF_Left<DisplayName=Left>, // Left shoulder is against cover
	eIF_Right<DisplayName=Right>, // Right shoulder is against cover
	eIF_Front<DisplayName=Front>, // Unit is facing interactive actor
};

enum EFavorDirection
{
	eFavor_None,
	eFavor_Left,
	eFavor_Right,
};

//=======================================================================================
//X-Com 2 Refactoring
//
//Member variables go in here, everything else will be re-evaluated to see whether it 
//needs to be moved, kept, or removed.

var transient privatewrite int ObjectID;    //Unique identifier for this object - used for network serialization and game state searches

var transient XComPath VisualizerUsePath;		//This is a local copy of the path that the unit is following. Set from X2Action_MoveBegin.
var transient PathingInputData CurrentMoveData;	//This is a cached copy of the move data that this unit is following during a chain of X2Action_Move actions. Set from X2Action_MoveBegin.
												//In some situations it may need to differ from what is stored in the history, such as during moves where 
												//portions of the path are not visible or where the path was cut short by an interruption where the mover survives
var transient PathingResultData CurrentMoveResultData; //Cached copy of the move result data for X2Action_Move to use

var transient int NumVisualizerTracks;      //Counts the number of active or pending visualizer tracks this unit is a part of
var transient int NumLocalPlayerViewers;    //Keeps track of the number of units that can see this

// Per unit reachable tile cache. This should be moved to the gamestate system once the AI gets moved over
var X2ReachableTilesCache m_kReachableTilesCache;

//Movement related variables.
var bool bNextMoveIsFollow; // Set to true when a cosmetic unit is told to move to the location of the unit it is following - instructs the visualizer to insert a small wait
var privatewrite EForceVisibilitySetting ForceVisibility; //Set primarily when a unit is moving
//=======================================================================================

var                                         XGPlayerNativeBase      m_kPlayerNativeBase;

var protected repnotify                     XComUnitPawnNativeBase  m_kPawn;
var protected                               XGInventoryNativeBase   m_kInventory;
var protected                               XGSquadNativeBase       m_kSquad;
var                                         ECoverState             m_eCoverState;
var                                         EFavorDirection         m_eFavorDir;        // Which direction to favor cover, set when moving.
var                                         int                     m_FavorCoverIndex;
var									        bool					m_bCriticallyWounded;
var                                         bool                    m_bStunned;
var                                         XGAIBehavior            m_kBehavior;
var                                         bool                    m_bHasMoved;  // have we moved this turn?
var repnotify                               bool                    m_bReactionFireStatus;
var		                                    int                     m_iLastTurnFireDamaged;
var transient                               array<Actor>            m_aCoverActors;
var                                         int                     m_iCurrentCoverValue;
var                                         bool                    m_bStabilized;              // This critically wounded unit has been stabilized.  No longer bleeding out.
var                                         int                     m_iPanicCounter;
var                                         bool                    m_bWasJustStrangling;
var                                         bool                    m_bStrangleStarted;
var                                         bool                    m_bSquadLeader;          

var EAlertLevel VisualizedAlertLevel;

// FLAGS---------------------------------------------------------
var bool                    DEPRECATED_m_bOffTheBattlefield;       // Causes the unit to be skipped when cycling units
var bool                    m_bIsFlying;
var bool                    m_bInAscent;
var bool                    m_bDebugUnitVis;
var bool                    m_bHasChryssalidEgg;        // True for zombies that haven't been killed by fire or explosion.
var bool 		            m_bForceHidden;	// set true when spawning as part of chryssalid birth sequence
var bool                    m_bHiding; // currently only used when ghosted, why is it not named as such? -tsmith 
var bool					m_bIsMoving;
// ------------------------------------------------------------------

var                                         XGUnit                  m_kConstantCombatUnitTargetingMe;
// ------------------------------------------------------------------

//  Cover BEGIN
var int CurrentCoverPointFlags;
var int CurrentCoverDirectionIndex;
var float FlankingAngle;
var float ClaimDistance;
var float CornerClaimDistance;

var XComIdleAnimationStateMachine IdleStateMachine;
var bool                m_bInCover;
// Cover END

var bool m_bVIP;                                 // Special designation for 'vip' units in Special Missions maps.

var protectedwrite bool  m_bInCinematicMode;
var private bool bTimeDilationSetByDeath;

//Used by the firing / exit / enter cover actions
//***********************************************
var X2Camera				        TargetingCamera;        // Camera used to frame the firing action
var X2Action_ExitCover				CurrentExitAction;      // Set by X2Action_ExitCover when it starts, cleared when it finishes
var X2Action_Fire				    CurrentFireAction;      // Set by X2Action_Fire when it starts, cleared when it finishes
var X2Action_AbilityPerkStart		CurrentPerkAction;		// Set by X2Action_AbilityPerkStart when it starts.  Cleared by X2Action_AbilityPerkEnd
var bool							m_bCelebrateAfterKill;  // Set by the fire action if it kills the target
var bool							bSteppingOutOfCover;    // Flag indicating that the unit is currently in a fire action and stepping out of cover
var bool							bShouldStepOut;			// Set when Exiting Cover to know if we should step out or turn
var Vector							RestoreLocation;        // Set by Exit cover, used in Enter cover to restore the unit's location when it is finished the enter cover animation
var Vector							RestoreHeading;         // Set by Exit cover, used in Enter cover at the beginning to put the unit into a rotation that will allow the get into cover RMA animation to work
var XGWeapon						PriorMecWeapon;         // RAM - hopefully can remove this once the inventory system is refactored or updated, but until then this stores the mec's default weapon

//This structure represents a transaction performed on the inventory system of this unit during the exit cover operation
struct native InventoryOperation
{
	var XGInventoryItem Item;
	var ELocation       LocationTo;
	var ELocation       LocationFrom;
	var bool            bUpdateGameInventory; //Set to true when the operation should equip / unequip items in the unit's XGInventory object
};
var array<InventoryOperation> InventoryOperations;    // Inventory transactions that have occurred in XGAction_ExitCover.
var bool                      bChangedWeapon;         // Set by exit cover - indicates the unit changed weapons when exiting cover

//Legacy (legacy variables used by Sectopod cluster bomb)
//----------------------------------------------
var ELocation           m_eEquipSlot;           // The weapon to be equipped
var ELocation           m_eReEquipSlot;         // The slot to re-equip after firing.
//----------------------------------------------

var protected                   ParticleSystemComponent     m_OnFirePSC;

// Alertness and Concealment vars
var                             int                         m_iLastAlertTurn;
var								bool						m_bSpotted; 

var                             bool                        m_DeadInVisualizer;

var int LastStateHistoryVisualized; // Jwats: This is an override for the VisualizationMgr.LastStateHistoryVisualized so actions that move can tell things to use the new locaiton

// DEBUGGING---------------------------------------------------------
var bool m_bForceWalk;

cpptext
{

	virtual INT* GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, UActorChannel* Channel );
}

replication
{
	if( bNetDirty && Role == ROLE_Authority )
		m_kInventory, 
		m_kBehavior,
		m_kPlayerNativeBase,
		m_iCurrentCoverValue,
		m_bStabilized,
		m_bHasChryssalidEgg,
		m_bForceHidden,
		m_iPanicCounter,		
		m_bWasJustStrangling,
		m_bSquadLeader;

	if( bNetDirty && !bNetOwner && Role == ROLE_Authority)
		m_bReactionFireStatus;

	if( bNetInitial && Role == ROLE_Authority )
		m_kPawn, m_kSquad;
}

simulated function InCinematicMode( bool bInCinematicMode)
{
	m_bInCinematicMode = bInCinematicMode;
}

simulated function bool IsInCinematicMode()
{
	return m_bInCinematicMode;
}

// Utility function to get the correct game state for queries about the state of the unit this XGUnit is visualizing.
// For example, if you want to add a function IsDead() to the visualizer, you should call this first to get the appropriate game state,
// and then ask the game state if it is dead. Otherwise you will be looking at the wrong point in the history and the unit may not
// yet be dead!
simulated native function XComGameState_Unit GetVisualizedGameState(optional out int HistoryIndex_out) const;

//@TODO - rmcfall - replace calls to these methods with direct access
//        jbouscher - looks like only old code is referencing this, and *shouldn't* be valid any more
simulated event int GetRemainingUnitActionPoints()
{	
	return 0;
}

//@TODO - rmcfall - replace calls to these methods with direct access
simulated event bool HasRemainingUnitActionPoints(optional int iNumActionPoints=1)
{
	return GetVisualizedGameState().NumActionPoints() >= iNumActionPoints;
}

//@TODO - rmcfall - replace calls to these methods with direct access
simulated event bool HaveAnyActionPointsBeenUsed()
{
	return GetVisualizedGameState().NumActionPoints() < class'X2CharacterTemplateManager'.default.StandardActionsPerTurn;
}

//------------------------------------------------------------------------------------------------

simulated native function bool IsInside();
simulated native function bool IsTurret();

simulated function XGInventory GetInventory();
simulated function XGPlayer GetPlayer();
simulated function bool IsEnemy( XGUnit kUnit );
simulated function bool IsMoving();
function OnChangedIndoorOutdoor( bool bWentInside );
simulated function SetDiscState( EDiscState eState );
/**
 * @param DamageCauser  - the actor (if any) that is physically causing the damage, i.e. XComProjectile_FragGrenade, XComProjectile_Shot
 */
function int OnTakeDamage( int iDamage, class<DamageType> DamageType, XGUnit kDamageDealer, vector HitLocation, vector Momentum, optional Actor DamageCauser );
simulated function HideCoverIcon();
function UnitSpeak( Name nCharSpeech, bool bDeadUnitSound=false);
event Speak(Name SpeechEvent)
{
	UnitSpeak(SpeechEvent);
}

simulated native function bool DoFlyingUnitToGroundVoxelTrace(out vector OutLocation);
simulated native function SetVisibleToTeams(byte eVisibleToTeamsFlags);
simulated native function AddFlagToVisibleToTeams(byte eAddTeamFlag);
simulated native function ClearFlagFromVisibleToTeams(byte eClearTeamFlag);
simulated native function int GetSightRadius();

// Cover Related
simulated native function PawnPerformPhysics(float deltaTime);

// Cover
simulated native final function Vector GetGameplayLocationForCoverQueries(optional int HistoryIndex = -1) const;
simulated native final function SetCoverDirectionIndex(int index);
simulated native final function int GetCoverDirectionIndex();
simulated native final function bool IsInCover();
simulated native final function bool UpdateCoverFlags(optional out Byte flagsChanged);
simulated native final function bool IsFlankedByLoc(Vector Loc) const;
simulated native final function float GetBestFlankingDot(Vector Loc) const;
simulated native final function Vector GetCoverDirection(optional int index=-1) const; // MHU - Index of -1 means just use CurrentCornerCoverIndex 
simulated native final function Vector GetShieldLocation(optional int index=-1) const;
simulated native final function ECoverType GetCoverType(optional int index=-1, optional int HistoryIndex = -1) const;
simulated native final function bool GetClosestCoverPoint(float SampleRadius, out XComCoverPoint Point, optional out float Distance, optional bool bTypeStanding=false) const;
simulated native final function XComCoverPoint GetCoverPoint(optional bool UsePawnLocation = false) const; // If false it uses the GetGameplayLocationForCoverQueries function
simulated native final private function FindCoverActors(const out XComCoverPoint CoverPoint);

// Flanking
simulated native function static bool DoesFlankCover( Vector PointA,XComCoverPoint kCover ) const;
simulated native function static bool DoesFlank(Vector PointA, Vector PointB, Vector DirOfPointB) const;

simulated function bool IsActiveUnit();

// Returns an ECoverState to use when moving into cover at hCoverPoint from vFromLoc
simulated function ECoverState PredictCoverState(Vector vFromLoc, XComCoverPoint hCoverPoint, float UsePeeksThreshold, optional out Vector vOutCoverDirection, optional out int OutCoverIndex, optional int HistoryIndex = -1)
{
	local Vector vFromDirRotated90;
	local Vector vFromDir;
	local float fDot;
	local float fDot90;
	local int iBestCoverIdx;
	local float fBestDot;
	local Vector fBestCoverDir;
	local ECoverState eBestCoverState;
	local int i;
	local int CoverDir;
	local bool bHasPeekLeft;
	local bool bHasPeekRight;
	local int bEnemiesOnLeftPeek;
	local int bEnemiesOnRightPeek;
	local Rotator LeftPeekRotator;
	local Rotator RightPeekRotator;
	local bool PickLeft;
	local bool CareAboutPeeks;
	local float AngleBetween;

	LeftPeekRotator.Pitch = 0;
	LeftPeekRotator.Roll = 0;
	LeftPeekRotator.Yaw = -90 * DegToUnrRot;

	RightPeekRotator.Pitch = 0;
	RightPeekRotator.Roll = 0;
	RightPeekRotator.Yaw = 90 * DegToUnrRot;

	iBestCoverIdx = -1;
	fBestDot = -1.0f;

	if (`IS_VALID_COVER(hCoverPoint) && CanUseCover())
	{
		vFromDir = hCoverPoint.ShieldLocation - vFromLoc;
		vFromDir = Normal(vFromDir);
		vFromDirRotated90 = TransformVectorByRotation(rot(0,16384,0), vFromDir);		

		for (i = 0; i < 4; i++)
		{
			CoverDir = `IDX_TO_DIR(i);
			if (`HAS_COVER_IN_DIR(hCoverPoint, CoverDir))
			{
				vOutCoverDirection = `XWORLD.GetWorldDirection(CoverDir, `IS_DIAGONAL_COVER(hCoverPoint));

				fDot = NoZDot(vFromDir, vOutCoverDirection);
				fDot90 = NoZDot(vFromDirRotated90, vOutCoverDirection);

				bHasPeekLeft = `HAS_LPEEK_IN_DIR(hCoverPoint, CoverDir);
				bHasPeekRight = `HAS_RPEEK_IN_DIR(hCoverPoint, CoverDir);

				//fDot += (bHasPeekLeft || bHasPeekRight) ? 3.0f : 0.0f; //Cover directions with peekarounds always trump those without

				// The closer fDot is to 1, the more straight on it is for us to be going into cover, which is more ideal if we are choosing from multiple directions.
				if (iBestCoverIdx == -1 || fDot > fBestDot)
				{
					iBestCoverIdx = i;
					fBestDot = fDot;
					fBestCoverDir = vOutCoverDirection;
					
					// Jwats: Only care about peeks if only 1 peek side is valid and we are within some degrees of running straight at cover (Or close to 180 from the cover like climbovers)
					AngleBetween = RadToDeg * acos(fDot);
					IdleStateMachine.TestEnemyUnitsForPeekSides(i, bEnemiesOnLeftPeek, bEnemiesOnRightPeek, HistoryIndex);
					CareAboutPeeks = (bHasPeekLeft != bHasPeekRight || bEnemiesOnLeftPeek != bEnemiesOnRightPeek) && (AngleBetween < UsePeeksThreshold || (180.0f - AngleBetween) < UsePeeksThreshold);
					if( CareAboutPeeks )
					{
						if( bEnemiesOnRightPeek != bEnemiesOnLeftPeek )
						{
							if( bEnemiesOnLeftPeek == 1 )
							{
								PickLeft = true;
							}
							else
							{
								PickLeft = false;
							}
						}
						else
						{
							if( bHasPeekLeft )
							{
								PickLeft = true;
							}
							else
							{
								PickLeft = false;
							}
						}
					}
					else if (fDot90 > 0.0f)
					{
						PickLeft = true;
					}
					else
					{
						PickLeft = false;
					}

					// Jwats: Peek left means right shoulder on wall
					if (PickLeft)
					{
						eBestCoverState = (`IS_LOW_COVER(hCoverPoint, CoverDir)) ? eCS_LowRight : eCS_HighRight;
						fBestCoverDir = QuatRotateVector(QuatFromRotator(LeftPeekRotator), vOutCoverDirection);
					}
					else
					{
						eBestCoverState = (`IS_LOW_COVER(hCoverPoint, CoverDir)) ? eCS_LowLeft : eCS_HighLeft;
						fBestCoverDir = QuatRotateVector(QuatFromRotator(RightPeekRotator), vOutCoverDirection);
					}
				}
			}
		}

		m_FavorCoverIndex = iBestCoverIdx;
		OutCoverIndex = iBestCoverIdx;
		vOutCoverDirection = fBestCoverDir;
		return eBestCoverState;
	}
	else
	{
		vOutCoverDirection = Vector(Rotation);
		OutCoverIndex = -1;
		return eCS_None;
	}
}

simulated event ReplicatedEvent(name VarName)
{
	super.ReplicatedEvent(VarName);
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();

	VisualizerUsePath = new(self) class'XComPath';
}

function bool Init( XGPlayer kPlayer, XGSquad kSquad, XComGameState_Unit UnitState, optional bool bDestroyOnBadLocation = false, optional bool bSnapToGround=true, optional const XComGameState_Unit ReanimatedFromUnit)
{
	m_kPlayerNativeBase = kPlayer;
	return true;
}

function bool LoadInit( XGPlayer kPlayer )
{
	m_kPlayerNativeBase = kPlayer;
	return true;
}

simulated function float GetDesiredZForLocation(Vector TestLocation, bool bGetFloorZ = true)
{
	return m_kPawn.GetDesiredZForLocation(TestLocation, bGetFloorZ);
}

simulated native function bool IsVisible();

//------------------------------------------------------------------------------------------------
// Return true if this unit has high cover over the target location.
// 	Used for testing concealment against AI units, similar to UpdateCoverBonuses(Enemy) check 
//   but ignores all other bonuses outside of the basic cover type.
native function bool HasHighCoverToShooter( vector vShooterLoc, optional out int bHasLowCover );
//------------------------------------------------------------------------------------------------

function SetSpotted( bool bSpotted )
{
	if (m_bSpotted != bSpotted)
	{
		m_bSpotted = bSpotted;
		`LogConcealment(`ShowVar(m_bSpotted)@"ID("$ObjectID$")"@m_kPawn);
	}
}

function EAlertLevel GetAlertLevel(optional XComGameState_Unit UnitState = none)
{
	local EAlertLevel AlertLevelEnum;

	if(UnitState == none)
	{
		UnitState = GetVisualizedGameState();
	}
	`assert(UnitState != none);

	if(UnitState.GetTeam() == eTeam_XCom || UnitState.GetTeam() == eTeam_Resistance)
	{
		AlertLevelEnum = eAL_None;
	}
	else
	{
		AlertLevelEnum = EAlertLevel(UnitState.GetCurrentStat(eStat_AlertLevel) + 1);
	}
	
	return AlertLevelEnum;
}

// under certain circumstances we want to use the animations and behaviors from a different alert level.
// this function provides a common path for all systems to use to compute this
function EAlertLevel GetVisualAlertLevel()
{
	local XComGameStateHistory History;
	local EAlertLevel AlertLevel;

	// Player controlled units default to Yellow
	if( !IsAI() )
	{
		return eAL_Yellow;
	}
	else
	{
		AlertLevel = VisualizedAlertLevel;

		// on maps where aliens are targeting civilians, alert visuals default to yellow for all non-xcom units
		History = `XCOMHISTORY;
		if( AlertLevel == eAL_Green 
			&& XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) ).AreCiviliansAlienTargets() )
		{
			return eAL_Yellow;
		}

		if ( IsCivilianChar() )
		{
			if( `XTACTICALSOUNDMGR.NumCombatEvents > 0 )
			{
				return eAL_Yellow; // after combat has happened, civilians always look yellow
			}
			else if (AlertLevel != eAL_Red)
			{
				return eAL_Green; // otherwise anything below red looks green
			}
		}

		// if no special cases, use the actual alert level

		if( AlertLevel == eAL_None )
		{
			AlertLevel = GetAlertLevel();
		}

		return AlertLevel;
	}
}

 // Currently only green alert units should be walking.
event bool ShouldUseWalkAnim(XComGameState ReleventGameState)
{
	 local XComGameStateHistory History;
	 local XComGameState_Unit Unit, OwnerState;
	 local XComGameState_Item ItemState;
	 History = `XCOMHISTORY;

	if (m_bForceWalk)
	{
		return true;
	}

	if (IsAI())
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID, , ReleventGameState.HistoryIndex));

		// for now forcing ACVs to always run.  Because they don't have any walk anims.
		if(Unit.IsACV() != 0 || Unit.GetMyTemplateGroupName() == 'Archon')
			return false;
			
		// Start Issue #33 : do not allow cosmetic units to be used by this check
		/// HL-Docs: ref:Bugfixes; issue:33
		/// Gremlins owned by AI units now correctly use fast walk animations even if their owner is in Red Alert
		if (GetAlertLevel(Unit) == eAL_Green && !Unit.IsMindControlled() && !Unit.GetMyTemplate().bIsCosmetic)
			return true;
		
		//instead, we iterate through itemstates to look for a Gremlin's owner, if they are a gremlin
		if(Unit.GetMyTemplate().bIsCosmetic)
		{
			foreach ReleventGameState.IterateByClassType(class'XComGameState_Item', ItemState)
			{
				if(ItemState.CosmeticUnitRef.ObjectID != 0 && ItemState.CosmeticUnitRef == Unit.GetReference())
				{
				 	OwnerState = XComGameState_Unit(History.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
					
					if(GetAlertLevel(OwnerState) == eAL_Green && !OwnerState.IsMindControlled() && !OwnerState.GetMyTemplate().bIsCosmetic) //a gremlin attaching itself to another cosmetic unit should never happen, but just in case...
							return true;
				}
			
			}
		}
    // End Issue #33
	}

	return false;
}

simulated native final function SetUnitCoverState(ECoverState newCover, optional FLOAT BlendTime = -1.0f);

// i believe the intent of this function was to return whether or not this unit is owned by the local player.
// it was previously just returning whether or not the player was human but that is completely busted in MP as all players are human. -tsmith 
simulated native function bool IsMine();
simulated native function bool IsCriticallyWounded();
native simulated event vector GetLocation();
/*
{
	if( m_kPawn == none )
		return vect( 0,0,0 );
	else
		return m_kPawn.Location;
}*/

native function vector GetGameStateLocation( bool bVisualizedLocation=false ); 

simulated event vector GetLocation_AdjustedByPeekTestHeight()
{
	local vector vAdjust;

	if( m_kPawn == none )
		return vect( 0,0,0 );
	else
	{
		if (m_kPawn.CylinderComponent != none)
		{
			vAdjust.X = 0;
			vAdjust.Y = 0;
			vAdjust.Z = -m_kPawn.CylinderComponent.CollisionHeight + class'XComWorldData'.const.Cover_PeekTestHeight;
		}

		return m_kPawn.Location + vAdjust;
	}
}

// Return base location.
simulated function vector GetFootLocation()
{
	if (m_kPawn == none)
	{
		return vect( 0,0,0 );
	}

	return m_kPawn.Location - (vect( 0, 0, 1 ) * m_kPawn.CylinderComponent.CollisionHeight);
}

// Return ground height location.
simulated function float GetWorldZ( optional out float fFootZ )
{
	local vector HitLocation, HitNormal, vLoc;
	local float Distance;
	local float WorldZ;
	local Actor returnedActor;
	local TTile kFloorTile;
	local vector vFloor;
	if (`XWORLD.GetFloorTileForPosition(Location, kFloorTile, true))
	{
		vFloor = `XWORLD.GetPositionFromTileCoordinates(kFloorTile);
		fFootZ = vFloor.Z;
		return fFootZ;
	}
	else
	{
		// Trace variables
		vLoc = GetFootLocation();
		fFootZ = vLoc.Z;
		Distance = 2048.0f;
		returnedActor = Trace( HitLocation, HitNormal, vLoc + vect(0,0,-1) * Distance );
		if ( returnedActor != none )
		{
			WorldZ = HitLocation.Z;
		}
		else
		{
			WorldZ = vLoc.Z;
		}
		return WorldZ;
	}

}

native simulated event bool IsAliveAndWell();
native simulated event bool IsAlive();
native final function bool IsAlert();

// CHARACTER NAME INTERFACE -----------------------------------------
simulated event string SafeGetCharacterName()
{
	/* jbouscher - REFACTORING CHARACTERS
	if (m_kCharacter.ShouldGenerateSafeNames())
	{
		GenerateSafeCharacterNames();
	}
	return m_kCharacter.SafeGetCharacterName();
	*/
	return "";
}

simulated event string SafeGetCharacterFullName()
{
	/* jbouscher - REFACTORING CHARACTERS
	if (m_kCharacter.ShouldGenerateSafeNames())
	{
		GenerateSafeCharacterNames();
	}
	return m_kCharacter.SafeGetCharacterFullName();
	*/
	return "";
}

simulated event string SafeGetCharacterFirstName()
{
	/* jbouscher - REFACTORING CHARACTERS
	if (m_kCharacter.ShouldGenerateSafeNames())
	{
		GenerateSafeCharacterNames();
	}
	return m_kCharacter.SafeGetCharacterFirstName();
	*/
	return "";
}

simulated event string SafeGetCharacterLastName()
{
	/*  jbouscher - REFACTORING CHARACTERS
	if (m_kCharacter.ShouldGenerateSafeNames())
	{
		GenerateSafeCharacterNames();
	}
	return m_kCharacter.SafeGetCharacterLastName();
	*/
	return "";
}

simulated event string SafeGetCharacterNickname()
{
	/* jbouscher - REFACTORING CHARACTERS
	if (m_kCharacter.ShouldGenerateSafeNames())
	{
		GenerateSafeCharacterNames();
	}
	return m_kCharacter.SafeGetCharacterNickname();
	*/
	return "";
}
// ------------------------------------------------------------------

// Generate in the derived class, since the generation functionality 
// requires appearance data which is not set here.
simulated function GenerateSafeCharacterNames()
{
	`warn("System was unable to generate safe character names for unit" @ self);
}
// ------------------------------------------------------------------


simulated function XComUnitPawn GetPawn()
{
	return XComUnitPawn(m_kPawn);
}

function Vector GetLeftVector()
{
	// MILLER - Changed the direction of the offset to be that of the claimed cover's direction
	//          rather than the pawns rotation vector
	return TransformVectorByRotation(rot(0,49152,0), GetCoverDirection());
	
}

function Vector GetLeftVectorAtCoverPoint(XComCoverPoint Point, int iDirIdx)
{
	return TransformVectorByRotation(rot(0,49152,0), `XWORLD.GetWorldDirection(`IDX_TO_DIR(iDirIdx), `IS_DIAGONAL_COVER(Point)));
}

function Vector GetRightVector()
{
	// MILLER - Changed the direction of the offset to be that of the claimed cover's direction
	//          rather than the pawns rotation vector
	return TransformVectorByRotation(rot(0,16384,0), GetCoverDirection());
}

function Vector GetRightVectorAtCoverPoint(XComCoverPoint Point, int iDirIdx)
{
	return TransformVectorByRotation(rot(0,16384,0), `XWORLD.GetWorldDirection(`IDX_TO_DIR(iDirIdx), `IS_DIAGONAL_COVER(Point)));
}

native function GetStanceForInteraction(XComInteractiveLevelActor InteractLevelActor, name InteractSocketName, out int CoverDirectionIndex, out int PeekSide);

simulated event OnAbilitiesInitiallyReplicated()
{
	// no longer calling here because the way the new pooling code works cause the render thread to starve if called to many time.
	// instead i am calling this at the beginning and end of every action on the client. -tsmith 5.11.2012
	//UpdateAbilitiesUI();
	// actually, the code has been optimized, need to call it here to resolve some edge cases where the abilities would not show in the code  -tsmith 6.10.2012
	MPForceUpdateAbilitiesUI();
}

simulated function DebugWeaponAnims(Canvas kCanvas, bool DisplayHistory, Vector vScreenPos)
{
	local XComGameState_Unit gameStateUnit;
	local array<XComGameState_Item> InventoryItems;
	local XComGameState_Item CurrentInventoryItem;
	local XGWeapon CurrentWeapon;
	local XComAnimatedWeapon AnimatedWeapon;
	local XComWeapon WeaponEntity;
	local int NumInventoryItems;
	local int ScanInventoryItems;

	gameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	InventoryItems = gameStateUnit.GetAllInventoryItems();
	NumInventoryItems = InventoryItems.Length;

	for (ScanInventoryItems = 0; ScanInventoryItems < NumInventoryItems; ++ScanInventoryItems)
	{
		CurrentInventoryItem = InventoryItems[ScanInventoryItems];
		CurrentWeapon = XGWeapon(CurrentInventoryItem.GetVisualizer());
		if (CurrentWeapon != None)
		{
			AnimatedWeapon = XComAnimatedWeapon(CurrentWeapon.m_kEntity);
			WeaponEntity = XComWeapon(CurrentWeapon.m_kEntity);
			if (AnimatedWeapon != None)
			{
				kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
				kCanvas.DrawText("Weapon:");
				kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
				AnimatedWeapon.GetAnimTreeController().DebugAnims(kCanvas, DisplayHistory, None, vScreenPos);
			}
			else if( WeaponEntity != None )
			{
				WeaponEntity.DebugAnims(kCanvas, DisplayHistory, None, vScreenPos);
			}
		}
	}
}

/**
 * NOTE: only used in MP because we have edgecase bugs that we need to smash with a hammer
 * and fully and completely blow away and rebuild the abilities UI. Do NOT call this function
 * often as it will take 30-40ms and Boswell will beat you down with the optimization hammer. -tsmith
 */
simulated function MPForceUpdateAbilitiesUI()
{
	if(WorldInfo.NetMode != NM_Standalone)
	{
		if( m_kPlayerNativeBase != none && 
			(IsActiveUnit() || m_kPlayerNativeBase.GetActiveUnit() == self) && 
			m_kPlayerNativeBase.m_kPlayerController != none && 
			m_kPlayerNativeBase.m_kPlayerController.IsLocalPlayerController())
		{
			if(`PRES.m_kTacticalHUD != none)
				`PRES.m_kTacticalHUD.Update();
		}
	}
}

simulated event UpdateAbilitiesUI()
{
	`PRES.m_kTacticalHUD.Update();
}

// This is different than IsMine() because of multiplayer
native simulated function bool IsAI();
native simulated function bool IsDead();
native simulated function bool CanUseCover( bool bIgnoreFlight=false);

simulated event int GetMaxPathLengthMeters()
{
	local XComGameState_Unit Unit;
	local int iMaxMobility;
	
	Unit = GetVisualizedGameState();
	iMaxMobility = Unit.GetCurrentStat(eStat_Mobility) * Unit.NumActionPointsForMoving();

	return iMaxMobility;
}

//bRecord will insert InvOperation into this unit's list of inventory operations so that the operations can be reversed or examined later
simulated function PerformInventoryOperation(float BlendTime, InventoryOperation InvOperation, bool bRecord)
{
	local XGInventory LocalInventory;
	
	LocalInventory = GetInventory();
	
	//Put the current item away
	if (InvOperation.bUpdateGameInventory)
	{
		if (InvOperation.LocationTo == eSlot_RightSling)
		{
			LocalInventory.UnequipItem(true); // Unequip to rightsling
		}
		else
		{
			LocalInventory.UnequipItem();
		}
	}

	//Handles the visuals - the from and to slot will be used by animation notifies
	m_kPawn.m_kMoveItem = none;
	if( InvOperation.Item != none )
	{
		m_kPawn.m_kMoveItem = XGWeapon(InvOperation.Item).GetEntity();
		m_kPawn.m_eMoveItemToSlot = InvOperation.LocationTo;
		`log(self @ m_kPawn @ "XGUnitNativeBase:" $ GetFuncName() @ "Item=" $ m_kPawn.m_kMoveItem @ "ItemToSlot=" $ m_kPawn.m_eMoveItemToSlot,,'GameCore');

		//This item is being equipped ( set as an active item ).
		if( InvOperation.bUpdateGameInventory && InvOperation.LocationTo == InvOperation.Item.m_eEquipLocation)
		{	
			//Equip ChangeToWeapon
			LocalInventory.EquipItem(InvOperation.Item, false, true);

			if( InvOperation.Item.IsA('XGWeapon') )
			{
				// <APC> Need to call SetActiveWeapon, because the active slot location may have changed. (not always eSlot_RightHand, i.e. for Sectoids).
				LocalInventory.SetActiveWeapon(XGWeapon(InvOperation.Item));
			}
		}
	}

	//Add the operation to the list if requested
	if( bRecord )
	{
		InventoryOperations.AddItem(InvOperation);
	}
}

//*********************************
native simulated function bool IsAnimal();

native simulated function int GetUnitMaxHP();

native simulated function int GetUnitHP();// MHU - Retrieve the final and total HP value for the unit.

native simulated function int GetShieldHP();
native simulated function int GetMaxShieldHP();

native simulated function bool IsPanicking();

native simulated function bool IsPanicked();

native simulated function bool IsWaitingToPanic();// Is this unit waiting for XGPlayer to put it into the 'Panicking' state?

//---------------------------------------------------------------
// Is this unit currently receiving a cover bonus?
// if (bActualCover==false) then flight bonus and no-cover bonus should return false.  (i.e. hunker down ability should not be available from the air.)
native simulated function bool HasCoverBonus( bool bActualCover=false );

//Moved out of XGAction_Dropdown to a central location for sharing
native simulated function bool DoClimbOverCheck(const out vector Destination, optional bool bUseDestinationZ = false);

native function bool GetDirectionInfoForTarget(XComGameState_Unit Target, out GameRulesCache_VisibilityInfo VisInfo, out int Direction, out UnitPeekSide PeekSide, out int bCanSeeDefaultFromDefault, out int bRequiresLean, optional bool bCanSeeConcealed = false, optional int HistoryIndex = -1);

native function bool GetDirectionInfoForPosition(vector Position, out GameRulesCache_VisibilityInfo VisInfo, out int Direction, out UnitPeekSide PeekSide, out int bCanSeeDefaultFromDefault, out int bRequiresLean, optional bool bRequireVisibility, optional int HistoryIndex=-1);

/** This event is triggered by XComWorldData::Tick when it detects that a tracked XGUnit has changed its tile position. This only occurs during movement */
simulated event OnUnitChangedTileDuringMovement(out TTile NewTileLocation)
{	
	local X2Action CurrentAction;
	local X2Action_Move MoveAction;

	`BATTLE.m_kLevel.OnEnteredTile(XComUnitPawn(m_kPawn), `XWORLD.GetPositionFromTileCoordinates(NewTileLocation));

	CurrentAction = `XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(self);
	if(CurrentAction != none)
	{
		MoveAction = X2Action_Move(CurrentAction);
		if(MoveAction != none)
		{
			MoveAction.OnUnitChangedTile(NewTileLocation);
		}
	}
}

// Moved this to the bottom of the file since it screws up script debugging.
simulated function bool IsInitialReplicationComplete()
{
	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_eTeam) @ `ShowVar(m_kPawn.IsInitialReplicationComplete())  @ `ShowVar(m_kSquad) @`ShowVar(m_kNetExecActionQueue) @ `ShowVar(m_kInventory.IsInitialReplicationComplete()));

	return	m_eTeam != eTeam_None && 
			m_kPawn != none && m_kPawn.IsInitialReplicationComplete() &&
			m_kSquad != none &&
			m_kInventory != none && m_kInventory.IsInitialReplicationComplete();
}

native simulated function int NumCustomFireNotifiesRemaining();

simulated function DestroyXComWeapons()
{
	GetInventory().DestroyXComWeapons();
}

simulated function ProcessNewPosition( )
{
	// For units with subsystems - subsystem locations need to match.
	XGUnit(self).SyncLocation( );
	IdleStateMachine.CheckForStanceUpdateOnIdle( );
}

simulated event CallProcessNewPosition() 
{
	ProcessNewPosition();
}

native function CachedCoverAndPeekData GetCachedCoverAndPeekData(optional int HistoryFrame = -1);

// Given a cover direction and a peek side, returns the peek location the unit will be at when stepping out
native function Vector GetExitCoverPosition(int CoverDirectionIndex, UnitPeekSide PeekSide, optional bool SteppingOut = true, optional int HistoryIndex = -1);

// Returns true if this unit has the same stepout tile as the specified unit
native function bool HasSameStepoutTile(XGUnitNativeBase OtherUnit);

// Given a target, this function will output if you shoudl step out for the target, in addition to the 
// cover direction and peek side
simulated event bool GetStepOutCoverInfo(XComGameState_Unit TargetUnitState, const out Vector TargetLoc, 
													 out int UseCoverDirectionIndex, 
													 out UnitPeekSide UsePeekSide, 
													 out int RequiresLean,
													 out int bCanSeeDefaultFromDefault,
													 optional int HistoryIndex = -1)
{
	local ECoverType CoverType;
	local bool ShouldStepOut;	
	local float AngleToTarget;
	local vector ToTarget;
	local float DotProduct;
	local bool RequireVisibility;
	local Actor ActorTarget;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;

	if (TargetUnitState != None)
	{
		//If the shot has a target unit, then we will always require visibility to the target
		GetDirectionInfoForTarget(TargetUnitState, OutVisibilityInfo, UseCoverDirectionIndex, UsePeekSide, bCanSeeDefaultFromDefault, RequiresLean, , HistoryIndex);
		ActorTarget = TargetUnitState.GetVisualizer();



	}
	else
	{
		RequireVisibility = true;
		GetDirectionInfoForPosition(TargetLoc, OutVisibilityInfo, UseCoverDirectionIndex, UsePeekSide, bCanSeeDefaultFromDefault, RequiresLean, RequireVisibility, HistoryIndex);
	}

	CoverType = GetCoverType(UseCoverDirectionIndex, HistoryIndex);

	

	ToTarget = Normal(TargetLoc - Location);
	DotProduct = NoZDot(ToTarget, vector(Rotation));
	AngleToTarget = Acos(DotProduct) * RadToDeg;
	if ((bCanSeeDefaultFromDefault != 0 && CoverType != CT_Standing)
	   || (OutVisibilityInfo.TargetCover > CT_MidLevel && (VSize(TargetLoc - Location) < (class'XComWorldData'.const.WORLD_StepSize * 2.0f))) //Don't step out for diagonal shots unless the target is in high cover relative to us
	   || (CoverType != CT_Standing && CoverType != CT_MidLevel)
	   || UseCoverDirectionIndex == -1
	   || (bCanSeeDefaultFromDefault != 0 && AngleToTarget < GetPawn().GetAnimTreeController().StepOutAngleThreshold)
	   || (ActorTarget != None && IsActorInCoverActors(ActorTarget)) )
	{
		ShouldStepOut = false;
	}
	else
	{
		ShouldStepOut = true;
	}

	return ShouldStepOut;
}

function bool IsActorInCoverActors(Actor TestActor)
{
	local Actor kActor;
	local XComCoverPoint CoverPoint;

	CoverPoint = GetCoverPoint();
	FindCoverActors(CoverPoint);

	foreach m_aCoverActors(kActor)
	{
		if( kActor == TestActor )
		{
			return true;
		}
	}

	return false;
}


// jboswell: Because a unit cannot safely be considered dead until his XGAction_Death
// or mind merge stuff is over with, we need to know if he's GOING to die for
// death tracking purposes
// @TODO - pmiller - delete this function
simulated event bool IsDeadOrDying()
{
	return IsDead();
}

simulated function bool IsCivilian()
{
	return (m_kBehavior != none &&
		m_kBehavior.IsA('XGAIBehavior_Civilian'));
}

//This is unique from IsCivilian, as IsCivilian will return false if the civilian is player controlled
simulated function bool IsCivilianChar()
{
	local XComGameState_Unit Unit;
	Unit = GetVisualizedGameState();
	return Unit.IsCivilian();
}

simulated function bool IsRobotic()
{
	//  @TODO jbouscher / rmcfall - should probably move queries to the state instead of using this function
	return GetVisualizedGameState().IsRobotic();
}

simulated function bool IsSoldier()
{
	//  @TODO jbouscher / rmcfall - should probably move queries to the state instead of using this function
	return GetVisualizedGameState().IsSoldier();
}

simulated function int GetCharacterRank()
{
	//  @TODO jbouscher / rmcfall - should probably move queries to the state instead of using this function
	return GetVisualizedGameState().GetRank();
}

//=======================================================================================
//X-Com 2 Refactoring
//
function SetObjectIDFromState(XComGameState_Unit UnitState)
{
	ObjectID = UnitState.ObjectID;
}

simulated native function int GetMobility();

//X2VisualizerInterface implementation
//************************************
event OnAddedToVisualizerTrack()
{	
	++NumVisualizerTracks;
}

event OnActionStarted(X2Action ActionStarted)
{
	//This unit is about to be controlled by a series of X2Actions, put the idle state machine into its dormant state
	if (!IdleStateMachine.IsDormant())
	{
		IdleStateMachine.GoDormant();
	}

	//Tick rate at normal speed when performing actions
	LOD_TickRate = 0.0f;
	m_kPawn.LOD_TickRate = 0.0f;
}

event OnActionCompleted()
{	
	local X2Action CurrentAction;

	--NumVisualizerTracks;
	NumVisualizerTracks = Max(0, NumVisualizerTracks); 	

	//Re-activate the idle state machine if there are either no more track actions OR we are not part of any
	//currently active running block
	CurrentAction = `XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(self);
	if( CurrentAction == None || CurrentAction.bCompleted == true )
	{		
		//Schedule a check in the future to see whether we should resume our idle state. We check a short time in the future
		//because back to back visualization states look better without brief attempts to go idle
		SetTimer(0.2f, false, nameof(TimedGoToIdle));
	}
}

function TimedGoToIdle()
{
	local X2Action CurrentAction;
	local bool ShouldResume;

	CurrentAction = `XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(self);
	ShouldResume = (IsAlive() || GetIsAliveInVisualizer()) && !GetVisualizedGameState().IsIncapacitated();
	if( (CurrentAction == None || CurrentAction.bCompleted == true) && ShouldResume )
	{
		IdleStateMachine.Resume();
		ResetWeaponsToDefaultSockets();
	}
}

event SetTimeDilation(float TimeDilation, optional bool bComingFromDeath/*=false*/)
{
	if( !bTimeDilationSetByDeath )
	{
		//Set our time dilation
		CustomTimeDilation = TimeDilation;
		m_kPawn.CustomTimeDilation = TimeDilation;

		bTimeDilationSetByDeath = bComingFromDeath;
	}	

	//`log("Setting TimeDilation :"@self@"-"@CustomTimeDilation);
	//ScriptTrace();
}

simulated function ResetWeaponsToDefaultSockets()
{
	local XGInventory kInventory;
	local XGWeapon kItemToEquip;
	local Attachment Attach;
	local SkeletalMeshComponent SkeletalMesh;
	local array<Attachment> ToBeDetached;
	local int NumAttachments;
	local int scan;
	local name PrimarySocketName;
	local name SecondarySocketName;

	kInventory = GetInventory();

	//Removing any attachment on the primary and secondary Weapon socket if any exist
	if( kInventory.m_kPrimaryWeapon != none && XComWeapon(kInventory.m_kPrimaryWeapon.m_kEntity) != none)
	{
		PrimarySocketName = XComWeapon(kInventory.m_kPrimaryWeapon.m_kEntity).DefaultSocket;
	}
	if( kInventory.m_kSecondaryWeapon != none && XComWeapon(kInventory.m_kSecondaryWeapon.m_kEntity) != none)
	{
		SecondarySocketName = XComWeapon(kInventory.m_kSecondaryWeapon.m_kEntity).DefaultSocket;
	}

	SkeletalMesh = GetPawn().Mesh;
	NumAttachments = SkeletalMesh.Attachments.Length;
	for( scan = 0; scan < NumAttachments; ++scan )
	{
		Attach = SkeletalMesh.Attachments[scan];
		if( Attach.Component == none || Attach.SocketName == '' )
		{
			continue;
		}

		if( Attach.SocketName == PrimarySocketName || Attach.SocketName == SecondarySocketName )
		{
			ToBeDetached.AddItem(Attach);
		}
	}
	foreach ToBeDetached(Attach)
	{
		SkeletalMesh.DetachComponent(Attach.Component);
	}

	//using same logic as per ApplyLoadoutFromGameState to then equip the Original weapons
	if( kInventory.m_kSecondaryWeapon != none )
	{
		if (XComWeapon(kInventory.m_kSecondaryWeapon.m_kEntity) != none)
		{
			// Need this in case an ItemAttach AnimNotify has previously hidden this weapon
			XComWeapon(kInventory.m_kSecondaryWeapon.m_kEntity).ShowWeapon();
		}
		kInventory.PresEquip(kInventory.m_kSecondaryWeapon, true);
	}

	if( kInventory.m_kPrimaryWeapon != none )
		kItemToEquip = kInventory.m_kPrimaryWeapon;
	else if( kInventory.m_kSecondaryWeapon != none )
		kItemToEquip = kInventory.m_kSecondaryWeapon;

	if( kItemToEquip != none )
	{
		if (XComWeapon(kItemToEquip.m_kEntity) != none)
		{
			// Need this in case an ItemAttach AnimNotify has previously hidden this weapon
			XComWeapon(kItemToEquip.m_kEntity).ShowWeapon();
			kItemToEquip.UpdateFlashlightState();
		}
		kInventory.EquipItem(kItemToEquip, true, true);
	}
}

native function UpdateShootLocationForLargeUnit( StateObjectReference Shooter, out vector ShootAtLocation );

event vector GetShootAtLocation(EAbilityHitResult HitResult, StateObjectReference Shooter)
{
	local Vector ShootAtLocation;
	local XComGameState_Unit UnitState;
	local rotator SocketRotation;

	UnitState = GetVisualizedGameState();
	
	if( (UnitState.IsDead() && HitResult == eHit_Crit) || UnitState.GetTeam() == eTeam_TheLost )
	{
		//If we were critically hit, and died aim for the face
		ShootAtLocation = XComUnitPawn(m_kPawn).GetHeadshotLocation();
	}
	else
	{	
		if( m_kPawn.Mesh.GetSocketWorldLocationAndRotation( 'Ribcage', ShootAtLocation, SocketRotation ))
		{
			// success. location filled out from call to socket function
		}
		else if( m_kPawn.Mesh.MatchRefBone('Ribcage') > -1 )
		{
			//Aim for the rib cage if we have one
			ShootAtLocation = m_kPawn.Mesh.GetBoneLocation('Ribcage');
		}
		else
		{
			//Fall back to using the location of the pawn if there is no rib cage
			ShootAtLocation = m_kPawn.Location;
		}
	}

	// for a large unit, we may not actually be able to see the ribcage
	if (UnitState.UnitSize > 1)
	{
		UpdateShootLocationForLargeUnit( Shooter, ShootAtLocation );
	}

	if(class'XComTacticalGRI'.static.GetReactionFireSequencer().FiringAtMovingTarget())
	{
		if(HitResult == eHit_Miss)
		{
			ShootAtLocation -= Normal(m_kPawn.Velocity) * class'XComWorldData'.const.WORLD_HalfStepSize;
		}
	}

	return ShootAtLocation;
}

event vector GetTargetingFocusLocation()
{
	return XComUnitPawn(m_kPawn).GetHeadshotLocation();
}

function string GetMyHUDIcon()
{
	local XComGameState_Unit StateObject;
	StateObject = GetVisualizedGameState();

	//First, check for an image specified in the character template
	if (StateObject.GetMyTemplate().strTargetIconImage != "")
		return StateObject.GetMyTemplate().strTargetIconImage;

	//If none is set, fallback to picking based on their team.
	`RedScreenOnce("Character template" @ StateObject.GetMyTemplateName() @ "doesn't have a targeting icon hooked up. @btopp @gameplay");

	if( StateObject.GetTeam() == eTeam_XCom )
		return class'UIUtilities_Image'.const.TargetIcon_XCom;
	else if( StateObject.GetTeam() == eTeam_Alien )
		return class'UIUtilities_Image'.const.TargetIcon_Alien;
	else if( StateObject.GetTeam() == eTeam_TheLost )
		return class'UIUtilities_Image'.const.TargetIcon_TheLost;
	else if( StateObject.GetTeam() == eTeam_Resistance )
		return class'UIUtilities_Image'.const.TargetIcon_XCom;
	else
		return class'UIUtilities_Image'.const.TargetIcon_Civilian;
}

function EUIState GetMyHUDIconColor()
{
	local XComGameState_Unit StateObject;
	local EUIState TeamOneColor, TeamTwoColor;
	local XComLWTuple OverrideTuple;

	TeamOneColor = eUIState_Warning2;
	TeamTwoColor = eUIState_Cash;

	// issue #188: let mods override default hud colours for these teams
	// Instead of a boolean, we use the Enum instead
	//set up a Tuple for return value

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideEnemyHudColors';
	OverrideTuple.Data.Add(2);

	// XComLWTuple does not have a Byte kind
	OverrideTuple.Data[0].kind = XComLWTVInt;
	OverrideTuple.Data[0].i = TeamOneColor;
	OverrideTuple.Data[1].kind = XComLWTVInt;
	OverrideTuple.Data[1].i = TeamTwoColor;

	`XEVENTMGR.TriggerEvent('OverrideEnemyHudColors', OverrideTuple, OverrideTuple);
	TeamOneColor = EUIState(OverrideTuple.Data[0].i);
	TeamTwoColor = EUIState(OverrideTuple.Data[1].i);
	StateObject = GetVisualizedGameState();

	//TODO: @gameplay
	//if( IsVIP() )
	//	return eUIState_Bad; 

	//TODO: @gameplay : you may want to move this door check to an override function somewhere else, if not here in XGUnitNativeBase.
	//if( IsADoor() )
	//	return eUIState_Bad; 
	
	if( IsCivilian() ) // TODO: civilian factions? Pro-, neutral, or anti- XCom? 
		return eUIState_Warning; 
	if( StateObject.GetTeam() == eTeam_XCom || StateObject.GetTeam() == eTeam_Resistance)
		return eUIState_Normal; 
	if( StateObject.GetTeam() == eTeam_Alien )
		return eUIState_Bad;
	if( StateObject.GetTeam() == eTeam_TheLost )
		return eUIState_TheLost;
	if(StateObject.GetTeam() == eTeam_One) //issue #188 - support for added team colours
		return EUIState(TeamOneColor);
	if(StateObject.GetTeam() == eTeam_Two)
		return EUIState(TeamTwoColor);
	//end issue #188
	
	//Default to show something is wrong: 
	return eUIState_Disabled;
}

event vector GetUnitFlagLocation()
{
	return GetLocation();
}

event StateObjectReference GetVisualizedStateReference()
{
	local StateObjectReference Reference;

	Reference.ObjectID = ObjectID;
	return Reference;
}

event VerifyTrackSyncronization()
{	
}

function int GetNumVisualizerTracks()
{
	return NumVisualizerTracks;	
}

function BuildAbilityEffectsVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata InTrack)
{	
	local XComGameState_Unit OldUnitState, NewUnitState;
	local bool bNowDead, bNowBleedingOut, bNowStasisLaned, bNowUnconscious;
	local bool bWasDead, bWasBleedingOut, bWasStasisLaned, bWasUnconscious, bWasBurrowed;
	local X2Action_PersistentEffect	PersistentEffectAction;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local X2Action DeathNode;

	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	
	OldUnitState = XComGameState_Unit(InTrack.StateObject_OldState);
	NewUnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(OldUnitState.ObjectID));
	if(NewUnitState == none)
	{
		return; //No delta
	}

	bNowDead = NewUnitState.IsDead();
	bWasDead = OldUnitState.IsDead();

	bNowBleedingOut = NewUnitState.IsBleedingOut();
	bWasBleedingOut = OldUnitState.IsBleedingOut();

	bNowStasisLaned = NewUnitState.IsStasisLanced();
	bWasStasisLaned = OldUnitState.IsStasisLanced();

	bNowUnconscious = NewUnitState.IsUnconscious();
	bWasUnconscious = OldUnitState.IsUnconscious();

	bWasBurrowed = OldUnitState.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.BurrowedName);

	if (!bWasDead && !bWasBleedingOut && !bWasStasisLaned && !bWasUnconscious && !bWasBurrowed)
	{
		if (bNowDead || bNowBleedingOut || bNowStasisLaned || bNowUnconscious)
		{
			PersistentEffectAction = X2Action_PersistentEffect(class'X2Action_PersistentEffect'.static.AddToVisualizationTree(InTrack, VisualizeGameState.GetContext(), false, InTrack.LastActionAdded));
			PersistentEffectAction.IdleAnimName = '';

			//Check to make sure there isn't already a death node for this actor. Could happen in sequences that kill a unit multiple times over, such as fan fire.
			DeathNode = VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_Death', self);
			if (DeathNode == none)
			{
				class'X2Action_Death'.static.AddToVisualizationTree(InTrack, VisualizeGameState.GetContext(), false, InTrack.LastActionAdded);
			}
		}
	}

	if (!bWasBleedingOut && bNowBleedingOut)
	{
		class'X2Action_DestroyTempFOWViewer'.static.AddToVisualizationTree(InTrack, VisualizeGameState.GetContext(), false, InTrack.LastActionAdded);
		class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(InTrack, VisualizeGameState.GetContext(), class'X2StatusEffects'.default.BleedingOutFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_BleedingOut);
		class'X2StatusEffects'.static.AddEffectMessageToTrack(InTrack,
															  class'X2StatusEffects'.default.BleedingOutEffectAcquiredString,
															  VisualizeGameState.GetContext(),
															  class'UIEventNoticesTactical'.default.BleedingOutTitle,
															  class'UIUtilities_Image'.const.UnitStatus_BleedingOut,
															  eUIState_Bad);
		class'X2StatusEffects'.static.UpdateUnitFlag(InTrack, VisualizeGameState.GetContext());
	}
}

//This method is called by the animation system when an AnimNotify_FireWeaponVolley is hit 
event OnFireWeaponVolley(AnimNotify_FireWeaponVolley Notify)
{	
	AddProjectileVolley(Notify);	
}

function AddProjectileVolley(AnimNotify_FireWeaponVolley Notify)
{
	local XComWeapon WeaponEntity;
	local XComGameState_Item SpecialAmmoGameState;	
	local array<WeaponAttachment> WeaponAttachments;
	local int Index;
	local XComUnitPawn UnitPawn;
	local XComGameStateContext_Ability AbilityContext;
	local AbilityInputContext InputContext;
	local XComGameState_Item SourceItemGameState;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<XComPerkContent> RelevantContent;
	local XComPerkContent PerkContent;
	local bool PerkManualFire;
	local XComGameState_Ability AbilityState;
	local XGWeapon AmmoWeapon;
	local XComWeapon AmmoEntity;
	local name EffectIter;
	local XComGameState_Effect EffectState;
	local Actor EffectProjectileTemplate;
	local XComGameState SuppressionGameState;

	UnitPawn = GetPawn();
	if (Notify.bPerkVolley == false)
	{
		//The archetypes for the projectiles come from the weapon entity archetype
		WeaponEntity = XComWeapon(UnitPawn.Weapon);
	}
	else
	{
		if ((CurrentPerkAction != none) && (CurrentPerkAction.GetAbilityName() == Notify.PerkAbilityName))
		{
			WeaponEntity = CurrentPerkAction.GetPerkWeapon( );
		}
	}

	if( WeaponEntity != none )
	{
		PerkManualFire = CurrentPerkAction != none && CurrentPerkAction.TrackHasNoFireAction && CurrentPerkAction.NeedsDelay;

		if ((CurrentFireAction == none) && !(IdleStateMachine.IsUnitSuppressing() || IdleStateMachine.IsUnitSuppressingArea()) && !PerkManualFire)
		{
			//`Redscreen("A FireWeaponVolley anim notify has occurred outside of X2Action_Fire. The projectile not operate properly!" @ self @ GetPawn() @ Notify);
		}
		else
		{
			//Spawn X2UnifiedProjectile actors to manage this volley. These actors are not visual, and exist to orchestrate and provide 
			//a scoped existence for projectile visuals. Should we consolidate multiple of these actors into a single actor or not? For
			//now we are letting them exist separately.
			//
			//Also, not that all the projectile actors created here will use the unit as their parent

			History = `XCOMHISTORY;

			if (CurrentFireAction != none)
			{
				InputContext = CurrentFireAction.AbilityContext.InputContext;
				AbilityContext = CurrentFireAction.AbilityContext;
			}
			else if (PerkManualFire)
			{
				InputContext = CurrentPerkAction.StartingAbility.InputContext;
				AbilityContext = CurrentPerkAction.StartingAbility;				
			}
			else
			{
				UnitState = GetVisualizedGameState();
				SuppressionGameState = History.GetGameStateFromHistory(UnitState.m_SuppressionHistoryIndex);
				AbilityContext = XComGameStateContext_Ability(SuppressionGameState.GetContext());
				InputContext = AbilityContext.InputContext;
			}

			//Create weapon default projectile
			SpawnAndConfigureNewProjectile(WeaponEntity.DefaultProjectileTemplate, Notify, AbilityContext, WeaponEntity);

			//Create projectile actors associated with weapon upgrades
			SourceItemGameState = XComGameState_Item(History.GetGameStateForObjectID(InputContext.ItemObject.ObjectID));
			if (SourceItemGameState != none)
			{
				WeaponAttachments = SourceItemGameState.GetWeaponAttachments();
				for (Index = 0; Index < WeaponAttachments.Length; ++Index)
				{
					SpawnAndConfigureNewProjectile(Actor(WeaponAttachments[Index].LoadedProjectileTemplate), Notify, AbilityContext, WeaponEntity);
				}
			}

			//Create projectile actors associated with ammo type
			if (SourceItemGameState != none && SourceItemGameState.HasLoadedAmmo())
			{
				SpecialAmmoGameState = XComGameState_Item(History.GetGameStateForObjectID(SourceItemGameState.LoadedAmmo.ObjectID));

				if (SpecialAmmoGameState != none)
				{
					SpawnAndConfigureNewProjectile(Actor(SpecialAmmoGameState.GetGameArchetype()), Notify, AbilityContext, WeaponEntity);
				}
			}

			AbilityState = XComGameState_Ability( History.GetGameStateForObjectID( InputContext.AbilityRef.ObjectID ) );
			SourceItemGameState = XComGameState_Item( History.GetGameStateForObjectID( AbilityState.SourceAmmo.ObjectID ) );
			if (SourceItemGameState != none)
			{
				AmmoWeapon = XGWeapon( SourceItemGameState.GetVisualizer( ) );
				AmmoEntity = XComWeapon( AmmoWeapon.m_kEntity );

				if (AmmoEntity.DefaultProjectileTemplate != none)
				{
					SpawnAndConfigureNewProjectile( AmmoEntity.DefaultProjectileTemplate, Notify, AbilityContext, WeaponEntity );
				}
			}

			//Create projectiles for perk content
			class'XComPerkContent'.static.GetAssociatedPerkDefinitions(RelevantContent, GetPawn(), InputContext.AbilityTemplateName);
			foreach RelevantContent(PerkContent)
			{
				if (PerkContent.CasterProjectile != none)
				{
					SpawnAndConfigureNewProjectile(PerkContent.CasterProjectile, Notify, AbilityContext, WeaponEntity);
				}
			}

			//Create projectiles for effects that are interested
			if (class'X2AbilityTemplateManager'.default.EffectsForProjectileVolleys.Length > 0)
			{
				if (UnitState == none)
					UnitState = GetVisualizedGameState();

				foreach class'X2AbilityTemplateManager'.default.EffectsForProjectileVolleys(EffectIter)
				{
					EffectState = UnitState.GetUnitAffectedByEffectState(EffectIter);
					if (EffectState != none)
					{
						EffectProjectileTemplate = EffectState.GetX2Effect().GetProjectileVolleyTemplate(UnitState, EffectState, AbilityContext);
						if (EffectProjectileTemplate != None)
						{
							SpawnAndConfigureNewProjectile(EffectProjectileTemplate, Notify, AbilityContext, WeaponEntity);
						}
					}
				}
			}
		}
	}
}

/// HL-Docs: feature:OverrideProjectileInstance; issue:829; tags:tactical
/// Allows listeners to override the parameters of SpawnAndConfigureNewProjectile
/// The feature also introduces support for subclasses of X2UnifiedProjectile as custom projectile archetypes.
/// If bPreventProjectileSpawning is set to true the projectile instance will NOT be spawned.
///
/// If your subclass of `X2UnifiedProjectile` overrides any of the functions that handle Particle System Components,
/// it's important to preserve changes implemented by Issue #720: [ProjectilePerformanceDrain](../tactical/ProjectilePerformanceDrain.md)
///
/// ```event
/// EventID: OverrideProjectileInstance,
/// EventData: [
///     out bool bPreventProjectileSpawning,
///     in Actor ProjectileTemplate,
///     in AnimNotify_FireWeaponVolley InVolleyNotify,
///     in XComWeapon InSourceWeapon,
///     inout X2Action_Fire CurrentFireAction,
///     in XGUnitNativeBase Unit
/// ],
/// EventSource: XComGameStateContext_Ability (AbilityContext),
/// NewGameState: none
/// ```
private function bool TriggerOverrideProjectileInstance(Actor ProjectileTemplate,
												AnimNotify_FireWeaponVolley InVolleyNotify,
												XComGameStateContext_Ability AbilityContext,
												XComWeapon InSourceWeapon)
{
	local XComLWTuple Tuple;
	local bool bPreventProjectileSpawning;

	bPreventProjectileSpawning = false;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideProjectileInstance';
	Tuple.Data.Add(6);

	Tuple.Data[0].Kind = XComLWTVBool;
	Tuple.Data[0].b = bPreventProjectileSpawning;

	Tuple.Data[1].Kind = XComLWTVObject;
	Tuple.Data[1].o = ProjectileTemplate;

	Tuple.Data[2].Kind = XComLWTVObject;
	Tuple.Data[2].o = InVolleyNotify;

	Tuple.Data[3].Kind = XComLWTVObject;
	Tuple.Data[3].o = InSourceWeapon;

	Tuple.Data[4].Kind = XComLWTVObject;
	Tuple.Data[4].o = CurrentFireAction;

	Tuple.Data[5].Kind = XComLWTVObject;
	Tuple.Data[5].o = self;

	`XEVENTMGR.TriggerEvent(Tuple.Id, Tuple, AbilityContext);

	CurrentFireAction = X2Action_Fire(Tuple.Data[4].o);

	return bPreventProjectileSpawning;
}

private function SpawnAndConfigureNewProjectile(Actor ProjectileTemplate,
												AnimNotify_FireWeaponVolley InVolleyNotify,
												XComGameStateContext_Ability AbilityContext,
												XComWeapon InSourceWeapon)
{
	local X2UnifiedProjectile NewProjectile;

	// Start Issue #829
	if (TriggerOverrideProjectileInstance(ProjectileTemplate, InVolleyNotify, AbilityContext, InSourceWeapon))
	{
		return;
	}

	NewProjectile = Spawn(class<X2UnifiedProjectile>(ProjectileTemplate.class),self, , , , ProjectileTemplate);
	// End Issue #829

	NewProjectile.ConfigureNewProjectile(CurrentFireAction, InVolleyNotify, AbilityContext, InSourceWeapon);

	NewProjectile.GotoState('Executing');
	if (CurrentFireAction != none)
	{
		CurrentFireAction.AddProjectileVolley(NewProjectile);
	}
}

function AddBlazingPinionsProjectile(vector SourceLocation, vector TargetLocation, XComGameStateContext_Ability AbilityContext)
{
	local XComWeapon WeaponEntity;
	local XComUnitPawn UnitPawn;
	local X2UnifiedProjectile NewProjectile;
	local AnimNotify_FireWeaponVolley FireVolleyNotify;
	
	UnitPawn = GetPawn();

	//The archetypes for the projectiles come from the weapon entity archetype
	WeaponEntity = XComWeapon(UnitPawn.Weapon);

	if( WeaponEntity != none )
	{
		FireVolleyNotify = new class'AnimNotify_FireWeaponVolley';
		FireVolleyNotify.NumShots = 1;
		FireVolleyNotify.ShotInterval = 0.3f;
		FireVolleyNotify.bCosmeticVolley = true;

		NewProjectile = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2UnifiedProjectile', , , , , WeaponEntity.DefaultProjectileTemplate);
		NewProjectile.ConfigureNewProjectileCosmetic(FireVolleyNotify, AbilityContext, , , CurrentFireAction, SourceLocation, TargetLocation, true);
		NewProjectile.GotoState('Executing');
	}
}

// This method is called by the animation system when an AnimNotify_FireDecalProjectile is hit 
// This is used usually for for melee or other animation driven attacks that do not use a weapon
// to place an impact decal into the world.
event OnAnimTriggerDecal(XComAnimNotify_TriggerDecal Notify)
{
	local X2Action CurrentAction;

	CurrentAction = `XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(self);
	CurrentAction.OnAnimNotify(Notify);

	if( CurrentFireAction != none )
	{
		CurrentFireAction.NotifyApplyDecal(Notify);
	}
}

function AddDecalProjectile(vector StartLocation, vector EndLocation, XComGameStateContext_Ability AbilityContext)
{
	local XComWeapon WeaponEntity;
	local X2UnifiedProjectile NewProjectile;
	local AnimNotify_FireWeaponVolley FireVolleyNotify;

	//The archetypes for the projectiles come from the weapon entity archetype
	if( CurrentPerkAction != none )
	{
		WeaponEntity = CurrentPerkAction.GetPerkWeapon();
	}

	if( WeaponEntity == none )
	{
		// If there is no perk weapon use the current weapon as a default
		WeaponEntity = XComWeapon(GetPawn().Weapon);
	}

	if( WeaponEntity != none )
	{
		FireVolleyNotify = new class'AnimNotify_FireWeaponVolley';
		FireVolleyNotify.NumShots = 1;
		FireVolleyNotify.ShotInterval = 0.3f;
		FireVolleyNotify.bCosmeticVolley = true;

		NewProjectile = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2UnifiedProjectile', , , , , WeaponEntity.DefaultProjectileTemplate);
		NewProjectile.ConfigureNewProjectileCosmetic(FireVolleyNotify, AbilityContext, , , CurrentFireAction, StartLocation, EndLocation, true);
		NewProjectile.GotoState('Executing');
	}
}

//This method is called by the animation system when an AnimNotify_FireWeaponVolley is hit 
event OnEndVolleyConstants( AnimNotify_EndVolleyConstants Notify )
{
	if (CurrentFireAction != none)
	{
		CurrentFireAction.EndVolleyConstants( Notify );
	}
	else
	{
		`Redscreen("A FireWeaponVolley anim notify has occurred outside of X2Action_Fire. The projectile will not operate properly!" @ self @ GetPawn() @ Notify);
	}
}

//This method is called by the animation system when an AnimNotify_FireWeaponVolley is hit 
event OnPerkStart( AnimNotify_PerkStart Notify )
{
	if (CurrentPerkAction != none)
	{
		CurrentPerkAction.NotifyPerkStart( Notify );
	}
	else
	{
		`Redscreen("A PerkStart anim notify has occurred outside the scope of perk actions. The perk will not operate properly!" @ self @ GetPawn( ) @ Notify);
	}
}

simulated function bool GetIsAliveInVisualizer()
{
    return !m_DeadInVisualizer;
}
simulated function SetDeadInVisualizer()
{
    m_DeadInVisualizer = true;
}

simulated function SetForceVisibility(EForceVisibilitySetting InForceVisibility)
{
	ForceVisibility = InForceVisibility;
}

//************************************
//

native function XComGameState_AIGroup GetAIGroupState( int HistoryIndex=INDEX_NONE );
//=======================================================================================

function bool HasOverrideDeathAnim(out Name DeathAnim)
{
	local XComGameState_Unit StateObject;
	StateObject = GetVisualizedGameState();
	if( StateObject.IsTurret() )
	{
		if( StateObject.GetTeam() == eTeam_Alien )
		{
			DeathAnim = 'NO_Death_Advent';
		}
		else
		{
			DeathAnim = 'NO_Death_Xcom';
		}
		return true;
	}

	// Check to see if this GameState Unit has an override anim 
	return StateObject.HasOverrideDeathAnimOnLoad(DeathAnim);
}

defaultproperties
{
	//bAlwaysRelevant=true;
	//RemoteRole=ROLE_SimulatedProxy;
	bAlwaysRelevant=false;
	bTimeDilationSetByDeath=false
	// TODO: make this ROLE_Authority for all our actors that dont need replication, unless none works -tsmith
	RemoteRole=ROLE_None
	m_kPawn = none;
	m_bVisible=true;
	m_eCoverState=eCS_None;

	FlankingAngle=180
	ClaimDistance=32.0f
	CornerClaimDistance=42.0f;
	CurrentCoverDirectionIndex=0

	m_bReactionFireStatus=true
	m_iLastTurnFireDamaged = -1;
	m_bDebugUnitVis=false

	Begin Object Class=ParticleSystemComponent Name=OnFirePSC
		bAutoActivate=false		
	End Object
	Components.Add(OnFirePSC)
	m_OnFirePSC=OnFirePSC
	LastStateHistoryVisualized=-1
}
