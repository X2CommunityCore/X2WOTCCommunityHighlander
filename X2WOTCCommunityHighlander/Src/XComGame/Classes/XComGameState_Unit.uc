//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Unit.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: This object represents the instance data for a unit in the tactical game for
//           X-Com
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Unit extends XComGameState_BaseObject 
	implements(X2GameRulesetVisibilityInterface, X2VisualizedInterface, Lootable, UIQueryInterfaceUnit, Damageable, Hackable) 
	dependson(XComCoverInterface, XComPerkContent, UIAlert)
	native(Core);

//IMPORTED FROM XGStrategySoldier
//@TODO - rmcfall/jbouscher - Refactor these enums? IE. make location a state object reference to something? and make status based on the location?
//*******************************************
enum ESoldierStatus
{
	eStatus_Active,			// not otherwise on a mission or in training
	eStatus_OnMission,		// a soldier out on a dropship
	eStatus_CovertAction,	// a soldier on a covert action
	eStatus_PsiTesting,		// a rookie currently training as a Psi Operative
	eStatus_PsiTraining,	// a soldier currently learning a new Psi ability
	eStatus_Training,		// a soldier currently training as a specific class or retraining abilities
	eStatus_Healing,		// healing up
	eStatus_Dead,			// ain't nobody comes back from this
};

enum ESoldierLocation
{
	eSoldierLoc_Barracks,
	eSoldierLoc_Dropship,
	eSoldierLoc_Infirmary,
	eSoldierLoc_Morgue,
	eSoldierLoc_PsiLabs,
	eSoldierLoc_PsiLabsCinematic,  // This solider is currently involved in the Psionics narrative moment matinee
	eSoldierLoc_Armory,
	eSoldierLoc_Gollup,
	eSoldierLoc_Outro,
	eSoldierLoc_MedalCeremony,    // Being awarded a medal
};

enum ENameType
{
	eNameType_First,
	eNameType_Last,
	eNameType_Nick,
	eNameType_Full,
	eNameType_Rank,
	eNameType_RankLast,
	eNameType_RankFull,
	eNameType_FullNick,
};

enum EAlertLevel
{
	eAL_None,
	eAL_Green,
	eAL_Yellow,
	eAL_Red,
};

enum EReflexActionState
{
	eReflexActionState_None,               //The default state, the reflex mechanic is not active on this unit	
	eReflexActionState_SelectAction,       //This state is active while the player decides what action to take with their reflex action
	eReflexActionState_ExecutingAction,    //This state is active while the reflex action is being performed
	eReflexActionState_AIScamper,          //This state is unique to the AI and the reflex action it receives when moving to red-alert during X-Com's turn
};

enum EIdleTurretState
{
	eITS_None,
	eITS_AI_Inactive,			// Initial state when on AI team.
	eITS_AI_ActiveTargeting,	// AI team active state, has targets visible.
	eITS_AI_ActiveAlerted,		// AI team active state, has no targets visible.
	eITS_XCom_Inactive,			// Inactive gun-down state on turn after having been hacked.
	eITS_XCom_ActiveTargeting,	// XCom-controlled active state, has targets visible.
	eITS_XCom_ActiveAlerted,	// XCom-controlled active state, has no targets visible.
};

//*******************************************

var() protected name                             m_TemplateName;
var() protected{mutable} transient X2CharacterTemplate     m_CharTemplate;
var() protected name	                         m_SoldierClassTemplateName;
var() protected X2SoldierClassTemplate           m_SoldierClassTemplate;
var   protected name                             m_MPCharacterTemplateName;
var   protected X2MPCharacterTemplate            m_MPCharacterTemplate;
var() bool                                       bAllowedTypeSoldier; //For character pool use - how might this unit be used
var() bool                                       bAllowedTypeVIP;     //"
var() bool                                       bAllowedTypeDarkVIP; //"
var() string                                     PoolTimestamp;       //Time the character was added to character pool
var() protectedwrite array<SCATProgression>      m_SoldierProgressionAbilties;
var() protected int                              m_SoldierRank;
var() int										 StartingRank; // For reward soldiers and cheating up ranks
var() protected int                              m_iXp;
var() protected array<StateObjectReference>      KilledUnits, KillAssists;
var() float										 KillCount, KillAssistsCount; // Track the value of kills obtained over the course of the game
var() int										 WetWorkKills;
var() int										 NonTacticalKills; // Any kills which the unit receives on non-tactical missions (ex: Covert Actions). Used for ranking up, not display.
var() float										 BonusKills; // Extra kill bonus (from strategy cards)
var() int                                        PsiCredits;    //  Accumulated from taking feedback and treated as XP for Kills/KAs
var() bool                                       bRankedUp;     //  To prevent ranking up more than once after a tactical match.
var() int						                 iNumMissions;
var() int                                        LowestHP;      //  Tracks lowest HP during a tactical match so that strategy heals a soldier based on that.
var() int										 HighestHP;		// Tracks highest HP during a tactical match (b/c armor effects add health, needed to calculate wounds)
var() int										 MissingHP;		// Tracks how much HP the unit had missing when a tactical match began, used to provide correct heal values post-mission
var() int										 StartingFame; // For reward soldiers and cheating up fame
var() int										 AbilityPoints;
var() int										 SpentAbilityPoints;

var() protected name							 PersonalityTemplateName;
var() protected X2SoldierPersonalityTemplate	 PersonalityTemplate;

var() privatewrite bool bTileLocationAmbiguous; //Indicates that this unit is in the midst of being thrown in rag doll form. The TileLocation will be set when it comes to rest.
var() privatewrite TTile TileLocation;       //Location of the unit on the battle map
var() privatewrite TTile TurnStartLocation;  //Recorded at the start of the unit's turn
var() rotator MoveOrientation;
var() protectedwrite bool bRemovedFromPlay;   // No longer on the battlefield
var() bool bDisabled;          // Unit can take no turns and processes no ai
var() StateObjectReference GhostSourceUnit;		//	If set, this unit is a ghost copy of the unit referred to here.

var() protected CharacterStat CharacterStats[ECharStatType.EnumCount];
var() int               UnitSize;           //Not a stat because it can't change... unless we implement shrink rays. or embiggeners (preposterous)
var() int				UnitHeight;
var() bool              bGeneratesCover;
var() ECoverForceFlag   CoverForceFlag;     //Set when a unit generates cover

var() protectedwrite array<StateObjectReference> InventoryItems;    //Items this units is carrying
var() array<StateObjectReference> MPBaseLoadoutItems;				//Base loadout items for this MP unit, cannot be removed
var() bool bIgnoreItemEquipRestrictions;							//Set to TRUE if this unit should be allowed to gain items without regard for inventory space or class.
var() privatewrite StateObjectReference ControllingPlayer;          //Which player is in control of us
var() array<StateObjectReference> Abilities;                        //Abilities this unit can use - filled out at the start of a tactical battle
var() protected array<TraversalChange> TraversalChanges;            //Cache of traversal changes applied by effects
var() protectedwrite array<StateObjectReference> AffectedByEffects; //List of XComGameState_Effects this unit is the target of
var() protectedwrite array<name> AffectedByEffectNames;				//Parallel to AffectedByEffects with the EffectName
var() protectedwrite array<StateObjectReference> AppliedEffects;    //List of XComGameState_Effects this unit is the source of
var() protectedwrite array<name> AppliedEffectNames;				//Parallel to AppliedEffects with the EffectName
var() array<name> ActionPoints;                                     //Action points available for use this turn
var() array<name> ReserveActionPoints;                              //Action points available for use during the enemy turn
var() array<name> SkippedActionPoints;                              //When the turn is skipped, any ActionPoints remaining are copied into here
var() int StunnedActionPoints, StunnedThisTurn;                     //Number of stunned action points remaining, and stunned actions consumed this turn
var() int Ruptured;                                                 //Ruptured amount is permanent extra damage this unit suffers from each attack.
var() int Shredded;                                                 //Shredded amount is always subtracted from any armor mitigation amount.
var() int Untouchable;                                              //Number of times this unit can freely dodge attacks.
var() protectedwrite array<name> AcquiredTraits;                    //X2TraitTemplates that this unit currently possesses
var() protectedwrite array<name> PendingTraits;                     //X2TraitTemplates whose criteria have been met, and will be applied at the end of the mission
var() protectedwrite array<name> CuredTraits;						//X2TraitTemplates who were previously acquired and are thus unavailable to be re-acquired
var() array<name> WorldMessageTraits;								//Cleared after seeing world message on the Avenger
var() array<name> AlertTraits;										//Cleared after seeing the trait alert (floating icon displays until cleared)
var() XComGameStateContext_Ability ReflectedAbilityContext;			//Original context of last reflected ability
var() int LastDamagedByUnitID;										//Keep track of which unit damaged this one last so XP can be attributed even if the unit doesn't have an explicit killer

struct native NegativeTraitRecoveryInfo
{
	// The name of the trait that can be recovered by completing perfect missions
	var Name TraitName;

	// The number of perfect missions that have been completed with this trait active
	var int PerfectMissionsCompleted;
};

var() protectedwrite array<NegativeTraitRecoveryInfo> NegativeTraits; // All negative traits currently active on this unit

//Store death related information
var() array<name> KilledByDamageTypes;								//Array of damage types from the effect that dealt the killing blow to this unit

var() array<DamageResult> DamageResults;
var() array<name> HackRewards;                  //Randomly chosen from the character template's rewards

var() bool bTriggerRevealAI;                    //Indicates whether this unit will trigger an AI reveal sequence
var() EReflexActionState ReflexActionState;	    //Unit is currently being forced to take a reflex action
var() protectedwrite LootResults PendingLoot;	//Results of rolling for loot 
var() bool bAutoLootEnabled;					//If true, this unit will automatically award it's basic loot table to the Mission Sweep loot pool when it dies
var() bool bKilledByExplosion;
var() bool bGotFreeFireAction;
var() bool bLightningReflexes;                  //Has active lightning reflexes - reaction fire against this target will miss
var() bool bBleedingOut;
var() bool bUnconscious;
var() bool bInStasis;
var() bool bBodyRecovered;                      //If the unit was killed, indicates if the body was recovered successfully
var() bool bTreatLowCoverAsHigh;                //GetCoverTypeFromLocation will return CT_Standing instead of CT_MidLevel
var() bool bPanicked;							// Unit is panicking.
var() bool bStasisLanced;                       // Unit has been hit by a Stasis Lance and is vulnerable to hacking.
var() bool bHasBeenHacked;                      // Unit has been hacked after being Stasis Lanced
var() bool bFallingApplied;
var   int  UserSelectedHackReward;
var() bool bCaptured;                           // unit was abandoned and has been captured by the aliens
var() bool bIsSuperSoldier;						// unit is a summoned super soldier
var() bool bIsSpecial;							// unit is part of a special faction
var() bool bIsFamous;							// unit is currently famous
var() bool bSpawnedFromAvenger;					// unit was spawned from the avenger for a defense mission
var() bool bMissionProvided;					// unit added to squad by mission.  Should be removed from squad on transition back to strategy.
var() TDateTime m_RecruitDate;
var() TDateTime m_KIADate; 
var() string m_strCauseOfDeath;
var() string m_strKIAOp;                       // Operation unit died on
var() string m_strEpitaph;

var array<AppearanceInfo> AppearanceStore;

var private native Map_Mirror UnitValues{TMap<FName, FUnitValue>};
var private array<SquadmateScore> SoldierRelationships;

// Alertness and concealment vars
var() private{private} bool m_bConcealed; // In full cover, not flanked or moving from a concealed location
var() bool bHasSuperConcealment;    //  Indicates the unit should use rules for super concealment ("Shadow" ability) - concealment status is still tracked through m_bConcealed
var() int SuperConcealmentLoss;     //  chance to lose concealment at the end oAllSoldierBondsf an action
var() int LastSuperConcealmentRoll;	//	stores the roll made when checking super concealment so it can be displayed in the UI
var() int LastSuperConcealmentValue;	//	stores the value of super concealment when reveal was rolled so it can be displayed in the UI
var() bool LastSuperConcealmentResult;	//	true if last roll broke concealment
var() bool bConcealedWithHeightAdvantage; //Set to true by passive effects / class abilities.
var() bool m_bSpotted;	// Visible to enemy.
var() bool m_bSubsystem; // This unit is a subsystem of another unit.

var int m_iTeamsThatAcknowledgedMeByVO; // Bitflags for remembering which teams have played VO due to seeing this unit.

var() EIdleTurretState IdleTurretState;

var int m_SuppressionHistoryIndex;
var StateObjectReference m_SpawnedCocoonRef; // Units may die while parthenogenic poison is on them, thus causing a cocoon to grow out of them
var StateObjectReference m_MultiTurnTargetRef; // Some abilities are delayed and the source should keep looking at the target, this allows that
var name CopiedUnitTemplateName;		// Template name of the (non-soldier) unit the shadow copied
var StateObjectReference ShadowUnit_CopiedUnit;	// Reference to the unit that this is a copy of

var array<Name> CurrentHackRewards; // The template name of the current hack rewards in effect on this unit.

var StateObjectReference ConcealmentBrokenByUnitRef; // The ref of the unit that saw this unit, causing it to lose concealment
var bool bUnitWasFlanked;	// true if concealment was broken due to being flanked

var int MPSquadLoadoutIndex;	// index into the mp squad array

var() array<int> HackRollMods;	// A set of modifiers for the current hack

var int GroupMembershipID;	// The ObjectID of the AIGroup this unit belongs to

var int ActivationLevel;		// for engaged chosen units, the current activation level of that unit
var int ActivationThreshold;	// for engaged chosen units, the threshold at which this unit will activate
var private StateObjectReference ChosenRef; // The ref to the AdventChosen state object that this is a Unit of (only set if this unit is a Chosen)
var StateObjectReference ChosenCaptorRef; // If this unit is captured by a Chosen, store a ref to the Chosen unit

var StateObjectReference FactionRef; // If this unit is part of a Resistance Faction

var array<SoldierBond> AllSoldierBonds;
var array<int> EnemiesInteractedWithSinceLastTurn;

var EMentalState MentalState; // Store current mental state (based on Will Threshold)
var array<name> WillEventsActivatedThisMission; // a list of all named will events that have been activated on this unit this mission
var bool bIgnoreWillSystem; // Used by multiplayer character to turn off the will system
var int PanicTestsPerformedThisTurn;	// Tracks the number of panic tests this unit has already performed this turn.  Reset in SetupActionsForBeginTurn().

var ECombatIntelligence ComInt; // The soldiers combat intelligence (modifiers AP gains when ranking up)

var array<SoldierRankAbilities> AbilityTree; // All Soldier Classes now build and store their ability tree upon rank up to Squaddie (could be at creation time)

var Name TacticalTag;	// A Tag used by tactical kismet to identify the unit

var float RescueRingRadius;

//================================== BEGIN LEGACY CODE SUPPORT ==============================================
//                           DO NOT USE THESE VARIABLES FOR NEW FEATURES
/**
 *  THESE VARS HAVE BEEN COPIED FROM TSoldier AND ARE NOT REFACTORED YET
 */
var() protected string      strFirstName;
var() protected string      strLastName;
var() protected string      strNickName;
var() protected string      strBackground;
var() protected name        nmCountry;
var() TAppearance           kAppearance;
/**
 *  END TSoldier VARS
 */

/**
 *  THESE VARS HAVE BEEN COPIED FROM TCharacter AND ARE NOT REFACTORED YET
 */
var() protected int         aTraversals[ETraversalType.EnumCount]<FGDEIgnore=true>;

/**
 *  END TCharacter VARS
 */

var StateObjectReference	StaffingSlot;
var() int					SkillValue; // Non-soldier XP
var() float					SkillLevelBonus; // From staffing slots
var() bool					bHasPsiGift;
var() bool					bRolledForPsiGift;

// Healing Flags
var() bool							bIsShaken; // Unit is Shaken after being gravely injured
var() bool							bIsShakenRecovered; // Unit has recovered from being Shaken
var() bool							bSeenShakenPopup; // If the Shaken popup has been presented to the player for this unit
var() bool							bNeedsShakenRecoveredPopup; // If the Shaken recovered needs to be presented to the player for this unit
var() int							SavedWillValue; // The unit's old Will value before they were shaken
var() int							MissionsCompletedWhileShaken;
var() int							UnitsKilledWhileShaken;

// New Class Popup
var() bool							bNeedsNewClassPopup; // If the new class popup has been presented to the player for this unit

// Advanced Warfare Abilities
var() bool							bRolledForAWCAbility;
var() bool							bSeenAWCAbilityPopup; // If the AWC Ability popup has been presented to the player for this unit
var() array<ClassAgnosticAbility>	AWCAbilities;

// Psi Abilities - only for Psi Operatives
var() array<SCATProgression>		PsiAbilities;

// Old Inventory Items (before items made available b/c of healing, etc.)
var() array<EquipmentInfo>	OldInventoryItems;

// Recovery Boost variables (Available after building Support Axis Facility)
var bool bRecoveryBoosted;
var bool bHasEverBeenBoosted;
var int PreBoostHealth;
var int PreBoostWill;

//@TODO - rmcfall - Copied wholesale from strategy. Decide whether these values are still relevant or not!
//*********************************************************************************************************
var private eSoldierStatus      HQStatus;
var private ESoldierLocation    HQLocation;
var int						    m_iEnergy;
var int						    m_iInjuryPoints;
var int                         m_iInjuryHours;
var string                      m_strKIAReport;
var bool					    m_bPsiTested;
var bool					    bForcePsiGift;
var transient XComUnitPawn      m_kPawn;

// Tracks special deaths
var bool bSpecialDeathOccured;

var duplicatetransient Array<XComGameState_Unit_AsyncLoadRequest> m_asynchronousLoadRequests;

var transient bool bIsInCreate;
var transient bool bHandlingAsyncRequests;

var private transient int CachedUnitDataStateObjectId;


var private bool bEverAppliedFirstTimeStatModifiers;

delegate OnUnitPawnCreated( XComGameState_Unit Unit);

//================================== END LEGACY CODE SUPPORT ==============================================


native function GetVisibilityForLocation(const out TTile FromLocation, out array<TTile> VisibilityTiles) const;

//================================== Visibility Interface ==============================================
/// <summary>
/// Used to supply a tile location to the visibility system to use for visibility checks
/// </summary>
native function NativeGetVisibilityLocation(out array<TTile> VisibilityTiles) const;
native function NativeGetKeystoneVisibilityLocation(out TTile VisibilityTile) const;

function GetVisibilityLocation(out array<TTile> VisibilityTiles)
{
	NativeGetVisibilityLocation(VisibilityTiles);
}

function GetKeystoneVisibilityLocation(out TTile VisibilityTile)
{
	NativeGetKeystoneVisibilityLocation(VisibilityTile);
}

native function float GetVisionArcDegrees();

event GetVisibilityExtents(out Box VisibilityExtents)
{
	local Vector HalfTileExtents;
	local TTile MaxTile;

	HalfTileExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;

	MaxTile = TileLocation;
	MaxTile.X += UnitSize - 1;
	MaxTile.Y += UnitSize - 1;
	MaxTile.Z += UnitHeight - 1;

	VisibilityExtents.Min = `XWORLD.GetPositionFromTileCoordinates( TileLocation ) - HalfTileExtents;
	VisibilityExtents.Max = `XWORLD.GetPositionFromTileCoordinates( MaxTile ) + HalfTileExtents;
	VisibilityExtents.IsValid = 1;
}

function SetVisibilityLocationFromVector( const out Vector VisibilityLocation )
{
	local TTile TempTile;

	TempTile = `XWORLD.GetTileCoordinatesFromPosition(VisibilityLocation);

	SetVisibilityLocation(TempTile);
}

/// <summary>
/// Used by the visibility system to manipulate this state object's VisibilityTile while analyzing game state changes
/// </summary>
event SetVisibilityLocation(const out TTile VisibilityTile)
{
	local array<Object> PreFilterObjects;
	local X2EventManager EventManager;
	local XComWorldData WorldData;
	local Vector NewUnitLocation, OldUnitLocation;
	local Object TestObject;
	local Volume TestVolume;
	local bool NeedsToCheckVolumeTouches, NeedsToCheckExitTouches;
	local XComGroupSpawn Exit;
	local array<TTile> AllVisibilityTiles;
	local TTile AllVisibilityTilesIter, Clamped;


	if( TileLocation != VisibilityTile )
	{
		`assert( !`XWORLD.IsTileOutOfRange(VisibilityTile) );

		WorldData = `XWORLD;

		Clamped.X = Clamp( VisibilityTile.X, 0, WorldData.NumX - 1 );
		Clamped.Y = Clamp( VisibilityTile.Y, 0, WorldData.NumY - 1 );
		Clamped.Z = Clamp( VisibilityTile.Z, 0, WorldData.NumZ - 1 );

		if (Clamped != VisibilityTile)
		{
			`redscreen( "SetVisibilityLocation given a tile that needed to be clamped to a valid location.\nTrace:\n" @ GetScriptTrace() );
		}

		// if there are any listeners for 'UnitTouchedVolume', get the volumes and test this unit's movement against those 
		// volumes to determine if a touch event occurred
		EventManager = `XEVENTMGR;

		NeedsToCheckVolumeTouches = EventManager.GetPreFiltersForEvent( 'UnitTouchedVolume', PreFilterObjects );

		Exit = `PARCELMGR.LevelExit;
		NeedsToCheckExitTouches = ( 
			Exit != None && 
			Exit.IsVisible() && 
			EventManager.AnyListenersForEvent( 'UnitTouchedExit' ) );

		if( NeedsToCheckVolumeTouches || NeedsToCheckExitTouches )
		{
			NewUnitLocation = WorldData.GetPositionFromTileCoordinates(Clamped);
			OldUnitLocation = WorldData.GetPositionFromTileCoordinates(TileLocation);
		}

		//Clear the stored peek and cover data around the OLD location. It will be reconstructed the next time it is needed ( for visibility ). This is necessary since our move could have
		//effects on nearby tiles ( such as requiring an adjacent unit to need to lean / step out a shorter distance )
		GetVisibilityLocation(AllVisibilityTiles);
		foreach AllVisibilityTiles(AllVisibilityTilesIter)
		{
			WorldData.ClearVisibilityDataAroundTile(AllVisibilityTilesIter);
		}

		TileLocation = Clamped;
		bRequiresVisibilityUpdate = true;

		//Clear the stored peek and cover data around the NEW location. It will be reconstructed the next time it is needed ( for visibility ). This is necessary since our move could have
		//effects on nearby tiles ( such as requiring an adjacent unit to need to lean / step out a shorter distance )
		GetVisibilityLocation(AllVisibilityTiles);
		foreach AllVisibilityTiles(AllVisibilityTilesIter)
		{
			WorldData.ClearVisibilityDataAroundTile(AllVisibilityTilesIter);
		}

		if( NeedsToCheckVolumeTouches )
		{
			foreach PreFilterObjects(TestObject)
			{
				TestVolume = Volume(TestObject);

				if( TestVolume.ContainsPoint(NewUnitLocation) &&
					!TestVolume.ContainsPoint(OldUnitLocation) )
				{
					EventManager.TriggerEvent( 'UnitTouchedVolume', self, TestVolume, GetParentGameState() );
				}
			}
		}

		if( NeedsToCheckExitTouches )
		{
			if( Exit.IsLocationInside(NewUnitLocation) &&
				!Exit.IsLocationInside(OldUnitLocation) )
			{
				EventManager.TriggerEvent( 'UnitTouchedExit', self,, GetParentGameState() );
			}
		}
		ApplyToSubsystems(SetVisibilityLocationSub);
	}
}

function SetVisibilityLocationSub( XComGameState_Unit kSubsystem )
{
	kSubsystem.SetVisibilityLocation(TileLocation);
}

private simulated function string GenerateAppearanceKey(int eGender, name ArmorTemplate)
{
	local string GenderArmor;
	local X2BodyPartTemplate ArmorPartTemplate;
	local X2BodyPartTemplateManager BodyPartMgr;

	if (eGender == -1)
	{
		eGender = kAppearance.iGender;
	}

	if (ArmorTemplate == '')
	{
		BodyPartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
		ArmorPartTemplate = BodyPartMgr.FindUberTemplate("Torso", kAppearance.nmTorso);
		if (ArmorPartTemplate == none)
		{
			return "";
		}

		ArmorTemplate = ArmorPartTemplate.ArmorTemplate;
	}

	GenderArmor = string(ArmorTemplate) $ eGender;
	return GenderArmor;
}

simulated function StoreAppearance(optional int eGender = -1, optional name ArmorTemplate)
{
	local AppearanceInfo info;
	local int idx;
	local string GenderArmor;

	GenderArmor = GenerateAppearanceKey(eGender, ArmorTemplate);
	`assert(GenderArmor != "");

	info.GenderArmorTemplate = GenderArmor;
	info.Appearance = kAppearance;

	idx = AppearanceStore.Find('GenderArmorTemplate', GenderArmor);
	if (idx != -1)
	{
		AppearanceStore[idx] = info;
	}
	else
	{
		AppearanceStore.AddItem(info);
	}
}

simulated function bool HasStoredAppearance(optional int eGender = -1, optional name ArmorTemplate)
{
	local string GenderArmor;
	GenderArmor = GenerateAppearanceKey(eGender, ArmorTemplate);
	return (AppearanceStore.Find('GenderArmorTemplate', GenderArmor) != -1);
}

simulated function GetStoredAppearance(out TAppearance appearance, optional int eGender = -1, optional name ArmorTemplate)
{
	local string GenderArmor;
	local int idx;
	local name UnderlayTorso;
	local name UnderlayArms;
	local name UnderlayLegs;

	GenderArmor = GenerateAppearanceKey(eGender, ArmorTemplate);
	`assert(GenderArmor != "");

	idx = AppearanceStore.Find('GenderArmorTemplate', GenderArmor);
	`assert(idx != -1);

	//Save the underlay settings
	UnderlayTorso = appearance.nmTorso_Underlay;
	UnderlayArms = appearance.nmArms_Underlay;
	UnderlayLegs = appearance.nmLegs_Underlay;

	appearance = AppearanceStore[idx].Appearance;

	//Restore. Put this in a helper method if we need to do more of this
	appearance.nmTorso_Underlay = UnderlayTorso;
	appearance.nmArms_Underlay = UnderlayArms;
	appearance.nmLegs_Underlay = UnderlayLegs;
}

native function XComGameState_Item GetPrimaryWeapon();
native function XComGameState_Item GetSecondaryWeapon();

/// <summary>
/// Used to determine whether a target is in range or not
/// </summary>
event float GetVisibilityRadius()
{
	return GetCurrentStat(eStat_SightRadius);
}

//Apply unit specific logic to determine whether the target is visible or not. The result of this method is used to set CheckVisibilityInfo.bVisibleGameplay, don't use
//CheckVisibilityInfo.bVisibleGameplay in this method. Also, when updating logic in this function make sure that the mechanics being considered set bRequiresVisibilityUpdate
//when updating the object's state. This function will not be called / vis not updated unless game play logic flags the new state as having changed visibility.
event UpdateGameplayVisibility(out GameRulesCache_VisibilityInfo InOutVisibilityInfo)
{
	local XComGameState_Unit kTargetCurrent;
	local XComGameState_Unit kTargetPrevious;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;
	local XComGameState_BaseObject TargetPreviousState;
	local XComGameState_BaseObject TargetCurrentState;
	local bool bUnalerted;
	local bool bUnitCanUseCover;
	local X2Effect_Persistent EffectTemplate;
	local XComGameState_Destructible DestructibleTarget;

	if( InOutVisibilityInfo.bVisibleBasic )
	{
		if( bRemovedFromPlay )
		{
			InOutVisibilityInfo.bVisibleBasic = false;
			InOutVisibilityInfo.bVisibleGameplay = false;
			InOutVisibilityInfo.GameplayVisibleTags.AddItem('RemovedFromPlay');
		}
		else
		{
			InOutVisibilityInfo.bVisibleGameplay = InOutVisibilityInfo.bVisibleBasic; //Defaults to match bVisibleBasic
			History = `XCOMHISTORY;

			//Handle the case where we are a type of unit that cannot take cover ( and thus does not have peeks )
			if(!InOutVisibilityInfo.bVisibleFromDefault && !CanTakeCover())
			{
				InOutVisibilityInfo.bVisibleBasic = false;
				InOutVisibilityInfo.bVisibleGameplay = false;
				InOutVisibilityInfo.GameplayVisibleTags.AddItem('PeekNotAvailable_Source');
			}
		
			History.GetCurrentAndPreviousGameStatesForObjectID(InOutVisibilityInfo.TargetID, TargetPreviousState, TargetCurrentState);
			kTargetCurrent = XComGameState_Unit(TargetCurrentState);
			DestructibleTarget = XComGameState_Destructible(TargetCurrentState);
			if(kTargetCurrent != none)
			{
				//Check to see whether the target moved. If so, visibility is not permitted to use peeks against the target
				kTargetPrevious = XComGameState_Unit(TargetPreviousState);
				if(kTargetPrevious != none && kTargetPrevious.TileLocation != kTargetCurrent.TileLocation)
				{					
					InOutVisibilityInfo.bTargetMoved = true;					
				}

				//Support for targeting non cover taking units with their peeks. Looks pretty bad though so it is gated by a config option...
				if(kTargetCurrent.ControllingPlayerIsAI())
				{
					bUnalerted = kTargetCurrent.GetCurrentStat(eStat_AlertLevel) == 0;
					bUnitCanUseCover = kTargetCurrent.GetMyTemplate().bCanTakeCover || class'X2Ability_DefaultAbilitySet'.default.bAllowPeeksForNonCoverUnits;

					//Handle the case where the target's peeks should be unavailable. Either because they are moving or for some other game mechanics reason.
					if(!InOutVisibilityInfo.bVisibleToDefault && (bUnalerted || !bUnitCanUseCover))
					{
						InOutVisibilityInfo.bVisibleBasic = false;
						InOutVisibilityInfo.bVisibleGameplay = false;
						InOutVisibilityInfo.GameplayVisibleTags.AddItem('PeekNotAvailable_Target');
					}
				}

				if(kTargetCurrent.bRemovedFromPlay)
				{
					InOutVisibilityInfo.bVisibleBasic = false;
					InOutVisibilityInfo.bVisibleGameplay = false;
					InOutVisibilityInfo.GameplayVisibleTags.AddItem('RemovedFromPlay');
				}
				else
				{
					//AI units have special visibility rules with respect to their alert level and enemies
					if(IsEnemyUnit(kTargetCurrent) && kTargetCurrent.IsConcealed())
					{
						InOutVisibilityInfo.bVisibleGameplay = false;
						InOutVisibilityInfo.GameplayVisibleTags.AddItem('concealed');
					}
						
					//Check effects that modify visibility for target - Do This Last!
					foreach kTargetCurrent.AffectedByEffects(EffectRef)
					{
						EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
						if (EffectState != none)
						{
							EffectTemplate = EffectState.GetX2Effect();
							if (EffectTemplate != none)
								EffectTemplate.ModifyGameplayVisibilityForTarget(InOutVisibilityInfo, self, kTargetCurrent);
						}						
					}
				}
			}
			else if (DestructibleTarget != none)
			{
				if (DestructibleTarget.bTargetableBySpawnedTeamOnly && GetTeam() != DestructibleTarget.SpawnedDestructibleTeam)
				{
					InOutVisibilityInfo.bVisibleGameplay = false;
					InOutVisibilityInfo.GameplayVisibleTags.AddItem('NotMyTeam');
				}
			}
		}
	}
}

function int GetSoldierRank()
{
	return m_SoldierRank;
}

function name GetSoldierClassTemplateName()
{
	if(IsMPCharacter())
		return m_MPCharacterTemplateName;

	return m_SoldierClassTemplateName;
}

function int GetNumTraits(optional bool bPositive = false, optional bool bCampaign = false)
{
	local X2EventListenerTemplateManager EventTemplateManager;
	local X2TraitTemplate TraitTemplate;
	local name TraitName;
	local int TraitCount;

	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();
	TraitCount = 0;

	foreach AcquiredTraits(TraitName)
	{
		TraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(TraitName));

		if(TraitTemplate != none)
		{
			if(bPositive && TraitTemplate.bPositiveTrait)
			{
				TraitCount++;
			}
			else if(!bPositive && !TraitTemplate.bPositiveTrait)
			{
				TraitCount++;
			}
		}
	}

	if(bCampaign)
	{
		foreach CuredTraits(TraitName)
		{
			TraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(TraitName));

			if(TraitTemplate != none)
			{
				if(bPositive && TraitTemplate.bPositiveTrait)
				{
					TraitCount++;
				}
				else if(!bPositive && !TraitTemplate.bPositiveTrait)
				{
					TraitCount++;
				}
			}
		}
	}

	return TraitCount;
}

function bool HasNegativeTraits()
{
	return (GetNumTraits(false, false) > 0);
}

function bool CanAcquireTrait(optional bool bPositive = false)
{
	local int MaxCampaignPositiveTraits, MaxConcurrentNegativeTraits, MaxCampaignNegativeTraits;

	if(!UsesWillSystem())
	{
		return false;
	}

	if(bPositive)
	{
		MaxCampaignPositiveTraits = class'X2StrategyGameRulesetDataStructures'.default.MaxCampaignPositiveTraits;
		return (MaxCampaignPositiveTraits <= 0 || GetNumTraits(true, true) < MaxCampaignPositiveTraits);
	}

	MaxCampaignNegativeTraits = class'X2StrategyGameRulesetDataStructures'.default.MaxCampaignNegativeTraits;
	MaxConcurrentNegativeTraits = class'X2StrategyGameRulesetDataStructures'.default.MaxConcurrentNegativeTraits;

	return ((MaxCampaignNegativeTraits <= 0 || GetNumTraits(false, true) < MaxCampaignNegativeTraits) &&
			(MaxConcurrentNegativeTraits <= 0 || GetNumTraits(false, false) < MaxConcurrentNegativeTraits));
}

// Normally acquired traits are not applied until the end of a tactical mission.
// Setting the Immediate flag will cause this trait to be immediately added to the unit.
function AcquireTrait(XComGameState NewGameState, name TraitTemplateName, optional bool Immediate = false)
{
	local bool InPendingList;
	local bool InAcquiredList;

	InAcquiredList = AcquiredTraits.Find(TraitTemplateName) != INDEX_NONE;

	if(InAcquiredList)
	{
		return; // we already have this trait
	}

	InPendingList = PendingTraits.Find(TraitTemplateName) != INDEX_NONE;

	if(InPendingList && Immediate)
	{
		// this trait was pending, but now we want to force it immediately
		PendingTraits.RemoveItem(TraitTemplateName);
	}

	// add the trait
	if(Immediate)
	{
		AddAcquiredTrait(NewGameState, TraitTemplateName);
	}
	else if(!InPendingList)
	{
		PendingTraits.AddItem(TraitTemplateName);
	}

	`XEVENTMGR.TriggerEvent( 'UnitTraitsChanged', self, , NewGameState );
}

function AddAcquiredTrait(XComGameState NewGameState, name TraitTemplateName, optional name ReplacedTraitName)
{
	local NegativeTraitRecoveryInfo NegativeTrait;
	//start issue #85: variables required to check the trait template of what we've been given
	local X2EventListenerTemplateManager EventTemplateManager;
	local X2TraitTemplate TraitTemplate;
	//end issue #85
	
	if( !IsAlive() )
	{
		return;
	}
	//start issue #85: init variables here after confirming it's a unit valid for it
	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();
	TraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(TraitTemplateName));
	//end issue #85
	if( AcquiredTraits.Find(TraitTemplateName) == INDEX_NONE )
	{
		AcquiredTraits.AddItem(TraitTemplateName);
		WorldMessageTraits.AddItem(TraitTemplateName);
		AlertTraits.AddItem(TraitTemplateName);
		//start issue #85: check if the trait's not positive: if so, we can add it to the negative trait array
		if(!TraitTemplate.bPositiveTrait)
		{
			NegativeTrait.TraitName = TraitTemplateName;
			NegativeTrait.PerfectMissionsCompleted = 0;
			NegativeTraits.AddItem(NegativeTrait);		
		}
		//end issue #85
	}
	else
	{
		`Redscreen("AddAcquiredTrait(): " $ GetFullName() $ " already has pending trait " $ string(TraitTemplateName));
	}
}

// Applys all pending trait template names to the AcquiredTraits array,
// effectively making them active.
function AcquirePendingTraits()
{
	local name PendingTrait;
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	if( PendingTraits.Length > 0 )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit acquiring pending traits");
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));

		foreach NewUnitState.PendingTraits(PendingTrait)
		{
			NewUnitState.AddAcquiredTrait(NewGameState, PendingTrait);
		}

		NewUnitState.PendingTraits.Length = 0;

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

// In Tac->Strat tranfer, soldiers have a chance to gain negative traits
// true if gained a negative trait
function bool RollForNegativeTrait(XComGameState NewGameState)
{
	local int RollValue, WillPercentMark, HealthPercentMark;
	local array<name> ValidTraits, GenericTraits;
	local name TraitName;

	// TODO: @mnauta - possibly pre-roll this value on mission start
	RollValue = `SYNC_RAND(200);
	WillPercentMark = (100 - int((GetCurrentStat(eStat_Will) / GetMaxStat(eStat_Will)) * 100.0f));
	WillPercentMark += class'X2StrategyGameRulesetDataStructures'.default.MentalStateTraitModifier[GetMentalState()];
	HealthPercentMark = (100 - int((GetCurrentStat(eStat_HP) / GetMaxStat(eStat_HP)) * 100.0f));
	ValidTraits.Length = 0;
	
	// Roll to see if they should gain a trait
	if(CanAcquireTrait(false) && RollValue < (WillPercentMark + HealthPercentMark))
	{
		// Check for pending traits first (triggered in mission)
		foreach PendingTraits(TraitName)
		{
			if(AcquiredTraits.Find(TraitName) == INDEX_NONE && ValidTraits.Find(TraitName) == INDEX_NONE)
			{
				ValidTraits.AddItem(TraitName);
			}
		}

		if(ValidTraits.Length > 0)
		{
			AddAcquiredTrait(NewGameState, ValidTraits[`SYNC_RAND(ValidTraits.Length)]);
			return true;
		}

		// No valid pending traits so try to give a generic negative trait
		GenericTraits = class'X2TraitTemplate'.static.GetAllGenericTraitNames();

		foreach GenericTraits(TraitName)
		{
			if(AcquiredTraits.Find(TraitName) == INDEX_NONE && ValidTraits.Find(TraitName) == INDEX_NONE)
			{
				ValidTraits.AddItem(TraitName);
			}
		}

		if(ValidTraits.Length > 0)
		{
			AddAcquiredTrait(NewGameState, ValidTraits[`SYNC_RAND(ValidTraits.Length)]);
			return true;
		}
	}

	return false;
}

function RecoverFromTraits()
{
	local int CurrentTraitIndex;
	local X2TraitTemplate CurrentTraitTemplate;
	local X2EventListenerTemplateManager EventTemplateManager;
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	if( NegativeTraits.Length > 0 )
	{
		EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit recovering from negative traits");
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));

		for( CurrentTraitIndex = NewUnitState.NegativeTraits.Length - 1; CurrentTraitIndex >= 0; --CurrentTraitIndex )
		{
			++NewUnitState.NegativeTraits[CurrentTraitIndex].PerfectMissionsCompleted;

			if( RollForTraitRecovery(NewUnitState.NegativeTraits[CurrentTraitIndex].PerfectMissionsCompleted) )
			{
				// cure the trait
				CurrentTraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(NewUnitState.NegativeTraits[CurrentTraitIndex].TraitName));

				NewUnitState.AcquiredTraits.RemoveItem(CurrentTraitTemplate.DataName);

				NewUnitState.NegativeTraits.Remove(CurrentTraitIndex, 1);


				//start of issue #85: uncommenting function to add positive traits + added cured trait to proper array
				NewUnitState.CuredTraits.AddItem(CurrentTraitTemplate.DataName);
				// replace it with a positive trait if possible
				if(CanAcquireTrait(true))
				{
					if(CurrentTraitTemplate.PositiveReplacementTrait != '')
					{
						NewUnitState.AddAcquiredTrait(NewGameState, CurrentTraitTemplate.PositiveReplacementTrait, CurrentTraitTemplate.DataName);
					}
					else
					{
						NewUnitState.ApplyGenericPositiveTrait(NewGameState, CurrentTraitTemplate.DataName);
					}
				}
				//end of issue #85

			}
		}

		`XEVENTMGR.TriggerEvent( 'UnitTraitsChanged', self, , NewGameState );
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function bool RollForTraitRecovery(int PerfectMissionsCompleted)
{
	PerfectMissionsCompleted = Clamp(PerfectMissionsCompleted, 0, class'X2StrategyGameRulesetDataStructures'.default.TraitRecoveryChanceSchedule.Length - 1);

	return (`SYNC_RAND(100) < class'X2StrategyGameRulesetDataStructures'.default.TraitRecoveryChanceSchedule[PerfectMissionsCompleted] );
}

function RecoverFromAllTraits(XComGameState NewGameState)
{
	local int CurrentTraitIndex;
	local X2TraitTemplate CurrentTraitTemplate;
	local X2EventListenerTemplateManager EventTemplateManager;
	
	if (NegativeTraits.Length > 0)
	{
		EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();
				
		for (CurrentTraitIndex = NegativeTraits.Length - 1; CurrentTraitIndex >= 0; --CurrentTraitIndex)
		{			
			// cure the trait
			CurrentTraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(NegativeTraits[CurrentTraitIndex].TraitName));
			AcquiredTraits.RemoveItem(CurrentTraitTemplate.DataName);
			NegativeTraits.Remove(CurrentTraitIndex, 1);
			//start of issue #85: add cured trait to proper array
			CuredTraits.AddItem(CurrentTraitTemplate.DataName);		
			//end of issue #85
		}
	}
}

// Recovery facility was removed
function ResetTraitRecovery()
{
	local int idx;
	
	for(idx = 0; idx < NegativeTraits.Length; idx++)
	{
		NegativeTraits[idx].PerfectMissionsCompleted = 0;
	}
}

function ApplyGenericPositiveTrait(XComGameState NewGameState, Name ReplacementTraitName)
{
	local X2DataTemplate CurrentDataTemplate;
	local X2TraitTemplate CurrentTraitTemplate;
	local X2EventListenerTemplateManager EventTemplateManager;
	local array<Name> PositiveTemplates;
	local array<Name> ExplicitReplacementTemplateNames;
	local Name ExplicitReplacementTemplateName;
	local Name SelectedTemplateName;

	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

	foreach EventTemplateManager.IterateTemplates(CurrentDataTemplate)
	{
		CurrentTraitTemplate = X2TraitTemplate(CurrentDataTemplate);

		if( CurrentTraitTemplate != None )
		{
			if( CurrentTraitTemplate.bPositiveTrait )
			{
				if( !EverHadTrait(CurrentTraitTemplate.DataName) )
				{
					PositiveTemplates.AddItem(CurrentTraitTemplate.DataName);
				}
			}
			else if( CurrentTraitTemplate.PositiveReplacementTrait != '' )
			{
				ExplicitReplacementTemplateNames.AddItem(CurrentTraitTemplate.PositiveReplacementTrait);
			}
		}
	}

	foreach ExplicitReplacementTemplateNames(ExplicitReplacementTemplateName)
	{
		PositiveTemplates.RemoveItem(ExplicitReplacementTemplateName);
	}

	if( PositiveTemplates.Length > 0 )
	{
		SelectedTemplateName = PositiveTemplates[`SYNC_RAND_STATIC(PositiveTemplates.Length)];

		AddAcquiredTrait(NewGameState, SelectedTemplateName, ReplacementTraitName);
	}
}

function bool HasActiveTrait(name TraitTemplateName)
{
	return (AcquiredTraits.Find(TraitTemplateName) != INDEX_NONE);
}

function bool HasTrait(name TraitTemplateName)
{
	return (AcquiredTraits.Find(TraitTemplateName) != INDEX_NONE) || (PendingTraits.Find(TraitTemplateName) != INDEX_NONE);
}

function bool EverHadTrait(name TraitTemplateName)
{
	return (CuredTraits.Find(TraitTemplateName) != INDEX_NONE && class'CHHelpers'.default.CHECK_CURED_TRAITS) || HasTrait(TraitTemplateName);
}

simulated function bool HasHeightAdvantageOver(XComGameState_Unit OtherUnit, bool bAsAttacker)
{
	local int BonusZ;

	if (bAsAttacker)
		BonusZ = GetHeightAdvantageBonusZ();

	return TileLocation.Z + BonusZ >= (OtherUnit.TileLocation.Z + class'X2TacticalGameRuleset'.default.UnitHeightAdvantage);
}

simulated function int GetHeightAdvantageBonusZ()
{
	local UnitValue SectopodHeight;
	local int BonusZ;

	if (GetUnitValue(class'X2Ability_Sectopod'.default.HighLowValueName, SectopodHeight))
	{
		if (SectopodHeight.fValue == class'X2Ability_Sectopod'.const.SECTOPOD_HIGH_VALUE)
			BonusZ = class'X2Ability_Sectopod'.default.HEIGHT_ADVANTAGE_BONUS;
	}

	return BonusZ;
}

/// <summary>
/// Applies to queries that need to know whether a given target is an 'enemy' of the source
/// </summary>
event bool TargetIsEnemy(int TargetObjectID, int HistoryIndex = -1)
{	
	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit UnitState;
	local XComGameState_Destructible DestructibleState;

	// is this an enemy unit?
	TargetState = `XCOMHISTORY.GetGameStateForObjectID(TargetObjectID, , HistoryIndex);

	UnitState = XComGameState_Unit(TargetState);
	if( UnitState != none )
	{
		return IsEnemyUnit(UnitState);
	}

	DestructibleState = XComGameState_Destructible(TargetState);
	if(DestructibleState != none)
	{
		return DestructibleState.TargetIsEnemy(ObjectID, HistoryIndex);
	}

	return false;
}

/// <summary>
/// Applies to queries that need to know whether a given target is an 'ally' of the source
/// </summary>
event bool TargetIsAlly(int TargetObjectID, int HistoryIndex = -1)
{	
	local XComGameState_Unit TargetState;	

	//Only other units can be allies atm
	TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetObjectID, , HistoryIndex));
	if( TargetState != none )
	{
		return !IsEnemyUnit(TargetState);
	}

	return false;
}

event bool ShouldTreatLowCoverAsHighCover( )
{
	return bTreatLowCoverAsHigh;
}

/// <summary>
/// Allows for the determination of whether a unit should visible or not to a given player
/// </summary>
event int GetAssociatedPlayerID()
{
	return ControllingPlayer.ObjectID;
}

event EForceVisibilitySetting ForceModelVisible()
{
	local XComTacticalCheatManager CheatMgr;
	local XGUnit UnitVisualizer;
	local XComUnitPawn UnitPawn;
	local XComGameState_BattleData BattleData;
	local X2Action CurrentTrackAction;

	//Scampering enemies always have their model visible regardless of what the game state says
	if( !GetMyTemplate().bDisableRevealForceVisible && ReflexActionState == eReflexActionState_AIScamper )
	{
		return eForceVisible;
	}

	UnitVisualizer = XGUnit(GetVisualizer());
	UnitPawn = UnitVisualizer.GetPawn();

	if(UnitPawn.m_bInMatinee)
	{
		return eForceVisible;
	}

	if(UnitPawn.m_bHiddenForMatinee)
	{
		return eForceNotVisible;
	}

	if (UnitPawn.bScanningProtocolOutline || UnitPawn.bAffectedByTargetDefinition)
	{
		return eForceVisible;
	}

	CheatMgr = `CHEATMGR;
	if(CheatMgr != none && CheatMgr.ForceAllUnitsVisible)
	{
		return eForceVisible;
	}
	
	if( bRemovedFromPlay )
	{
		//If a unit was removed from play, but is still playing an action (usually, evacuating right now) don't hide them.
		CurrentTrackAction = `XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(UnitVisualizer);
		if (CurrentTrackAction == None || CurrentTrackAction.bCompleted) //No action / finished action, time to hide them
			return eForceNotVisible;
	}

	//Force bodies to be visible
	if (!IsAlive() || IsBleedingOut() || IsStasisLanced() || IsUnconscious())
	{
		return eForceVisible;
	}

	//If our controlling player is local	
	if (ControllingPlayer.ObjectID == `TACTICALRULES.GetLocalClientPlayerObjectID())
	{
		return eForceVisible;
	}

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if( (GetTeam() == eTeam_Neutral || GetTeam() == eTeam_Resistance) &&  BattleData.AreCiviliansAlwaysVisible() )
	{
		return eForceVisible;
	}

	// If this unit is not owned by the local player AND is Concealed, should be invisible
	if( (UnitVisualizer.GetPlayer() != XComTacticalController(`BATTLE.GetALocalPlayerController()).m_XGPlayer) &&
		IsConcealed() )
	{
		return eForceNotVisible;
	}

	return UnitVisualizer.ForceVisibility;
}

//================================== End Visibility Interface ==============================================

event OnStateSubmitted()
{	
	GetMyTemplate();

	`assert(m_CharTemplate != none);
}

native function bool GetUnitValue(name nmValue, out UnitValue kUnitValue);
native function SetUnitFloatValue(name nmValue, const float fValue, optional EUnitValueCleanup eCleanup=eCleanup_BeginTurn);
native function ClearUnitValue(name nmValue);
native function CleanupUnitValues(EUnitValueCleanup eCleanupType);
native function string UnitValues_ToString();

native function bool GetSquadmateScore(int iSquadmateID, out SquadmateScore kSquadmateScore);
native function SetSquadmateScore(int iSquadmateID, const int iScore, bool bUpdateStatus);
native function AddToSquadmateScore(int iSquadmateID, const int iScoreToAdd, optional bool bUpdateStatus=false);
native function ClearSquadmateScore(int iSquadmateID);
native function OnSoldierMoment(int iSquadmateID);

function SetInitialState(XGUnit UnitActor)
{
	local XGItem Item;
	local int i;
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local XComGameState_Item ItemState;
	
	History = `XCOMHISTORY;

	History.SetVisualizer(ObjectID, UnitActor);
	UnitActor.SetObjectIDFromState(self);

	`XWORLD.GetFloorTileForPosition(UnitActor.Location, TileLocation, false);

	UnitActor.m_kReachableTilesCache.SetCacheUnit(self);

	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitActor.m_kPlayer.ObjectID));
	ControllingPlayer = PlayerState.GetReference();

	for(i = 0; i < eSlot_Max; i++)
	{
		Item = UnitActor.GetInventory().GetItem(ELocation(i));
		if( Item == none )
			continue;

		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Item.ObjectID));
		InventoryItems.AddItem(ItemState.GetReference());
	}
}

function AddStreamingCinematicMaps()
{
	// add the streaming map if we're not at level initialization time
	//	should make this work when using dropUnit etc
	local XComGameStateHistory History;
	local X2CharacterTemplateManager TemplateManager;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit kGameStateUnit;
	local string MapName;

	History = `XCOMHISTORY;
	if (History.GetStartState() == none)
	{

		kGameStateUnit = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

		TemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		CharacterTemplate = TemplateManager.FindCharacterTemplate(kGameStateUnit.GetMyTemplateName());
		if (CharacterTemplate != None)
		{
			foreach CharacterTemplate.strMatineePackages(MapName)
			{
				if(MapName != "")
				{
					`MAPS.AddStreamingMap(MapName, , , false).bForceNoDupe = true;
				}
			}
		}

	}

}



function PostCreateInit(XComGameState NewGameState, X2CharacterTemplate kTemplate, int iPlayerID, TTile UnitTile, bool bEnemyTeam, bool bUsingStartState, bool PerformAIUpdate, optional const XComGameState_Unit ReanimatedFromUnit = None, optional string CharacterPoolName, optional bool bDisableScamper, optional bool bCopyReanimatedFromUnit, optional bool bCopyReanimatedStatsFromUnit)
{
	local XComGameStateHistory History;
	local XGCharacterGenerator CharGen;
	local TSoldier Soldier;
	local XComGameState_Unit kSubSystem, Unit;
	local XComGameState_Player PlayerState;
	local name SubTemplateName;
	local X2CharacterTemplate kSubTemplate;
	local array<StateObjectReference> arrNewSubsystems;
	local StateObjectReference kSubsystemRef;
	local AttachedComponent SubComponent;
	local int i;
	local XComGameState_Item InventoryItem, NewItemState;
	local X2EquipmentTemplate EquipmentTemplate;

	//Character pool support
	local bool bDropCharacterPoolUnit;
	local CharacterPoolManager CharacterPool;
	local XComGameState_Unit CharacterPoolUnitState;
		
	History = `XCOMHISTORY;

	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(iPlayerID));
	SetControllingPlayer(PlayerState.GetReference());
	SetVisibilityLocation(UnitTile);
		
	bDropCharacterPoolUnit = CharacterPoolName != "";

	if (ReanimatedFromUnit != none && bCopyReanimatedFromUnit)
	{
		SetTAppearance(ReanimatedFromUnit.kAppearance);
		SetCharacterName(ReanimatedFromUnit.GetFirstName(), ReanimatedFromUnit.GetLastName(), ReanimatedFromUnit.GetNickName());
		SetCountry(ReanimatedFromUnit.GetCountry());
	}
	//If our pawn is gotten from our appearance, and we don't yet have a torso - it means we need to generate an appearance. This should
	//generally ONLY happen when running from tactical as appearances should be generated within the campaign/strategy game normally.
	else if(kTemplate.bAppearanceDefinesPawn && (kAppearance.nmTorso == '' || bDropCharacterPoolUnit))
	{				
		if(bDropCharacterPoolUnit)
		{
			CharacterPool = `CHARACTERPOOLMGR;
			CharacterPoolUnitState = CharacterPool.GetCharacter(CharacterPoolName);
		}

		if(CharacterPoolUnitState != none)
		{
			SetTAppearance(CharacterPoolUnitState.kAppearance);
			SetCharacterName(CharacterPoolUnitState.GetFirstName(), CharacterPoolUnitState.GetLastName(), CharacterPoolUnitState.GetNickName());
			SetCountry(CharacterPoolUnitState.GetCountry());
		}
		else
		{
			CharGen = `XCOMGRI.Spawn(kTemplate.CharacterGeneratorClass);
			`assert(CharGen != none);
			Soldier = CharGen.CreateTSoldier(kTemplate.DataName);
			SetTAppearance(Soldier.kAppearance);
			SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
			SetCountry(Soldier.nmCountry);
		}
	}

	if( CharGen != none )
	{
		CharGen.Destroy();
	}

	// If Boosted, Max out health and will
	if(bRecoveryBoosted)
	{
		SetCurrentStat(eStat_HP, GetMaxStat(eStat_HP));
		SetCurrentStat(eStat_Will, GetMaxStat(eStat_Will));
	}

	//	copy stats - currently using rules for templar ghost stat copy in here (for lower hp)
	if (ReanimatedFromUnit != none && bCopyReanimatedStatsFromUnit)
	{		
		for (i = 0; i < eStat_MAX; ++i)
		{
			if (i == eStat_HP)
			{
				if (ReanimatedFromUnit.GetCurrentStat(eStat_HP) > 1)
				{
					SetBaseMaxStat(eStat_HP, ReanimatedFromUnit.GetCurrentStat(eStat_HP) - 1);
				}
				else
				{
					SetBaseMaxStat(eStat_HP, 1);
				}
			}
			else
			{
				SetBaseMaxStat(ECharStatType(i), ReanimatedFromUnit.GetBaseStat(ECharStatType(i)));
			}

			SetCurrentStat(ECharStatType(i), GetMaxStat(ECharStatType(i)));
		}
	}

	//	copy inventory
	if (ReanimatedFromUnit != none && bCopyReanimatedFromUnit)
	{
		for (i = 0; i < ReanimatedFromUnit.InventoryItems.Length; ++i)
		{
			InventoryItem = XComGameState_Item(History.GetGameStateForObjectID(ReanimatedFromUnit.InventoryItems[i].ObjectID));
			if (InventoryItem != none)
			{
				EquipmentTemplate = X2EquipmentTemplate(InventoryItem.GetMyTemplate());
				if (EquipmentTemplate != none)
				{
					NewItemState = EquipmentTemplate.CreateInstanceFromTemplate(NewGameState);
					NewItemState.WeaponAppearance = InventoryItem.WeaponAppearance;

					AddItemToInventory(NewItemState, EquipmentTemplate.InventorySlot, NewGameState);
				}
			}
		}
	}
	else
	{
		ApplyInventoryLoadout(NewGameState);
	}	

	if (!bDisableScamper)
	{
		bTriggerRevealAI = bEnemyTeam;
	}

	if (HackRewards.Length == 0 && kTemplate.HackRewards.Length > 0)
	{
		HackRewards = class'X2HackRewardTemplateManager'.static.SelectHackRewards(kTemplate.HackRewards);
	}

	//	copy soldier class and abilities
	if (ReanimatedFromUnit != none && bCopyReanimatedFromUnit)
	{
		if (ReanimatedFromUnit.IsSoldier())
		{
			SetSoldierClassTemplate(ReanimatedFromUnit.GetSoldierClassTemplateName());
			AbilityTree = ReanimatedFromUnit.AbilityTree;
			m_SoldierProgressionAbilties = ReanimatedFromUnit.m_SoldierProgressionAbilties;
			m_SoldierRank = ReanimatedFromUnit.m_SoldierRank;
		}
		else
		{
			CopiedUnitTemplateName = ReanimatedFromUnit.GetMyTemplateName();
		}
	}

	if( !bUsingStartState )
	{
		// If not in start state, we need to initialize the abilities here.
		`TACTICALRULES.InitializeUnitAbilities(NewGameState, self);
	}

	// copy over any pending loot from the old unit to this new unit
	if( ReanimatedFromUnit != None )
	{
		PendingLoot = ReanimatedFromUnit.PendingLoot;

		if( GetMyTemplate().strPawnArchetypes.Length > 1 )
		{
			// This type of unit may have a gender, so copy the gender from
			// the copied unit
			kAppearance = ReanimatedFromUnit.kAppearance;
		}
	}

	if( PerformAIUpdate )
	{
		XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer()).AddNewSpawnAIData(NewGameState);
	}

	if( GetTeam() == eTeam_Alien )
	{
		if( `TACTICALMISSIONMGR.ActiveMission.AliensAlerted )
		{
			SetCurrentStat(eStat_AlertLevel, `ALERT_LEVEL_YELLOW);
		}
	}

	// This isn't thread safe, visualizers should only be created from X2Actions on the game thread.
	// Leaving it commented out in case something breaks and it needs to be obvious what might be a culprit.
	//class'XGUnit'.static.CreateVisualizer(NewGameState, self, PlayerState, ReanimatedFromUnit);

	if(kTemplate.bIsTurret)
	{
		InitTurretState();
	}

	if(!kTemplate.bIsCosmetic)
	{
		`XWORLD.SetTileBlockedByUnitFlag(self);
	}

	// Handle creation of subsystems here.
	if (!m_bSubsystem) // Should not be more than 1 level of subsystems.
	{
		foreach kTemplate.SubsystemComponents(SubComponent)
		{
			SubTemplateName = SubComponent.SubsystemTemplateName;
			kSubTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(SubTemplateName);
			if (kSubTemplate == none)
			{
				`log("No character subtemplate named" @ SubTemplateName @ "was found.");
				continue;
			}

			kSubSystem = kSubTemplate.CreateInstanceFromTemplate(NewGameState);
			kSubSystem.m_bSubsystem = true;
			arrNewSubsystems.AddItem(kSubSystem.GetReference());
			kSubSystem.PostCreateInit(NewGameState, kSubTemplate, iPlayerID, UnitTile, bEnemyTeam, bUsingStartState, PerformAIUpdate,,,bDisableScamper);
		}

		if (arrNewSubsystems.Length > 0)
		{
			// Update the Unit GameState to include these subsystems.
			Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));
			if (Unit != none)
			{
				foreach arrNewSubsystems(kSubsystemRef)
				{
					kSubSystem = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', kSubsystemRef.ObjectID));
					Unit.AddComponentObject(kSubSystem);
					`Assert(kSubSystem.OwningObjectId > 0);
				}
			}
		}
	}


	AddStreamingCinematicMaps();
}

function InitTurretState()
{
	if( GetNumVisibleEnemyUnits() > 0 )
	{
		if( GetTeam() == eTeam_Alien )
		{
			IdleTurretState = eITS_AI_ActiveTargeting;
		}
		else
		{
			IdleTurretState = eITS_XCom_ActiveTargeting;
		}
	}
	else
	{
		if( GetTeam() == eTeam_Alien )
		{
			IdleTurretState = eITS_AI_ActiveAlerted;
		}
		else
		{
			IdleTurretState = eITS_XCom_ActiveTargeting;
		}
	}
}

function bool AutoRunBehaviorTree(Name OverrideNode = '', int RunCount = 1, int HistoryIndex = -1, bool bOverrideScamper = false, bool bInitFromPlayerEachRun=false, bool bInitiatedFromEffect=false)
{
	local X2AIBTBehaviorTree BTMgr;
	BTMgr = `BEHAVIORTREEMGR;
	if( bOverrideScamper )
	{
		BTMgr.RemoveFromBTQueue(ObjectID, true);
	}
	if( BTMgr.QueueBehaviorTreeRun(self, String(OverrideNode), RunCount, HistoryIndex, , , , bInitFromPlayerEachRun, bInitiatedFromEffect) )
	{
		BTMgr.TryUpdateBTQueue();
		return true;
	}
	return false;
}

// start of turn - clear red alert state if no perfect knowledge remains (no visibility on enemy units)
function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_AIUnitData AIGameState;
	local int AIUnitDataID;
	local StateObjectReference KnowledgeOfUnitRef;
	local StateObjectReference AbilityRef;
	local XComGameState_Effect RedAlertEffectState, YellowAlertEffectState;
	local X2TacticalGameRuleset Ruleset;
	local XComGameStateContext_Ability NewAbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit ChosenState;
	local XComGameState_Player PlayerState;

	if(ControllingPlayer.ObjectID == XComGameState_Player(EventSource).ObjectID)
	{
		History = `XCOMHISTORY;
		Ruleset = X2TacticalGameRuleset(`XCOMGAME.GameRuleset);

		// check for loss of red alert state.  (Only valid for enemy AI.  Don't allow team Resistance to drop to yellow alert.)
		if( GetCurrentStat(eStat_AlertLevel) == `ALERT_LEVEL_RED && !IsFriendlyToLocalPlayer())
		{
			AIUnitDataID = GetAIUnitDataID();
			if( AIUnitDataID > 0 )
			{
				AIGameState = XComGameState_AIUnitData(History.GetGameStateForObjectID(AIUnitDataID));
				if( !AIGameState.HasAbsoluteKnowledge(KnowledgeOfUnitRef) )
				{
					RedAlertEffectState = GetUnitAffectedByEffectState('RedAlert');
					if( RedAlertEffectState != None && !RedAlertEffectState.bRemoved ) // Don't remove an effect that's already been removed.
					{
						// remove RED ALERT
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RemoveRedAlertStatus");
						RedAlertEffectState.RemoveEffect(NewGameState, GameState);
						Ruleset.SubmitGameState(NewGameState);

						`LogAI("ALERTEFFECTS:Removed Red Alert effect from unit "$ ObjectID @", to be replaced with YellowAlert effect.");

						// add YELLOW ALERT (if necessary)
						YellowAlertEffectState = GetUnitAffectedByEffectState('YellowAlert');
						if( YellowAlertEffectState == None || YellowAlertEffectState.bRemoved )
						{
							AbilityRef = FindAbility('YellowAlert');
							if( AbilityRef.ObjectID > 0 )
							{
								AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

								if( AbilityState != None )
								{
									NewAbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, ObjectID);
									if( NewAbilityContext.Validate() )
									{
										Ruleset.SubmitGameStateContext(NewAbilityContext);
									}
								}
							}
						}
					}
				}
			}
		}

		if( `SecondWaveEnabled('ChosenActivationSystemEnabled' ) )
		{
			if( IsChosen() )
			{
				ChosenState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

				if( ChosenState.IsEngagedChosen() )
				{
					PlayerState = XComGameState_Player(History.GetGameStateForObjectID(ChosenState.ControllingPlayer.ObjectID));
					if( PlayerState.ChosenActivationsThisTurn <= 0 )
					{
						AdvanceChosenActivation(ChosenState.ActivationThreshold - ChosenState.ActivationLevel);
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnGroupTurnBegin(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local Name BTAutoRun;
	local X2AutoPlayManager AutoPlayMgr;

	BTAutoRun = Name(GetMyTemplate().strAutoRunNonAIBT);
	AutoPlayMgr = `AUTOPLAYMGR;
	if( AutoPlayMgr.AutoRunSoldiers && BTAutoRun != '' )
	{
		// Automatically run behavior tree for Non-AI turrets.  XCom-controlled Turrets run their own modified behavior tree.
		if( GetTeam() == eTeam_XCom && IsAbleToAct() && NumActionPoints() > 0 ) // Not in Stunned state.
		{
			AutoRunBehaviorTree(BTAutoRun, NumActionPoints());
		}
	}

	return ELR_NoInterrupt;
}

function bool UpdateTurretState( bool UpdateIdleStateMachine=true )
{
	local EIdleTurretState eOldState;
	local int nVisibleEnemies;
	// Update turret state
	eOldState = IdleTurretState;
	nVisibleEnemies = GetNumVisibleEnemyUnits();
	// Handle stunned state.  
	if( StunnedActionPoints > 0 || StunnedThisTurn > 0 ) // Stunned state.
	{
		if( ControllingPlayerIsAI() )
		{
			IdleTurretState = eITS_AI_Inactive;
		}
		else
		{
			IdleTurretState = eITS_XCom_Inactive;
		}
	}
	// Otherwise the unit is active.
	else
	{
		if( nVisibleEnemies > 0 )
		{
			if( GetTeam() == eTeam_Alien )
			{
				IdleTurretState = eITS_AI_ActiveTargeting;
			}
			else
			{
				IdleTurretState = eITS_XCom_ActiveTargeting;
			}
		}
		else
		{
			if( GetTeam() == eTeam_Alien )
			{
				IdleTurretState = eITS_AI_ActiveAlerted;
			}
			else
			{
				IdleTurretState = eITS_XCom_ActiveTargeting;
			}
		}
	}

	if( UpdateIdleStateMachine )
	{
		XGUnit(GetVisualizer()).UpdateTurretIdle(IdleTurretState);
	}
	if(eOldState != IdleTurretState)
	{
		return true;
	}
	return false;
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	local XComGameState_Player PlayerState;
	local XGUnit UnitVisualizer;
	local XComHumanPawn HumanPawnVisualizer;
	local Vector ObjectiveLoc;
	local Vector DirToObj;
	local X2ArmorTemplate ArmorTemplate;

	if (GameState == none)
	{
		GameState = GetParentGameState( );
	}

	UnitVisualizer = XGUnit(GetVisualizer());
	if(!bRemovedFromPlay && (UnitVisualizer == none || m_bSubsystem))
	{
		PlayerState = XComGameState_Player( `XCOMHISTORY.GetGameStateForObjectID( ControllingPlayer.ObjectID ) );

		class'XGUnit'.static.CreateVisualizer(GameState, self, PlayerState);
		UnitVisualizer = XGUnit(GetVisualizer());
		//`assert(UnitVisualizer != none);
		if (!UnitVisualizer.IsAI())
		{
			if (!`TACTICALMISSIONMGR.GetLineOfPlayEndpoint(ObjectiveLoc))
			{
				// If there is no objective, they look at the origin 
				ObjectiveLoc = vect(0, 0, 0);
			}
			
			UnitVisualizer.GetPawn().SetFocalPoint(ObjectiveLoc);
			if (GetCoverTypeFromLocation() == CT_None)
			{
				DirToObj = ObjectiveLoc - UnitVisualizer.GetPawn().Location;
				DirToObj.Z = 0;
				UnitVisualizer.GetPawn().SetRotation(Rotator(DirToObj));
			}
		}


		// Set the correct wwise switch value.  Per request from the sound designers, this, "allows us to 
		// change the soldier Foley based on the type of armor the soldier is waring"  mdomowicz 2015_07_22
		if(IsSoldier() && GetItemInSlot(eInvSlot_Armor, GameState) != none)
		{
			ArmorTemplate = X2ArmorTemplate(GetItemInSlot(eInvSlot_Armor, GameState).GetMyTemplate());
			HumanPawnVisualizer = XComHumanPawn(UnitVisualizer.GetPawn());

			if (ArmorTemplate != None && HumanPawnVisualizer != None)
			{
				HumanPawnVisualizer.SetSwitch('SoldierArmor', ArmorTemplate.AkAudioSoldierArmorSwitch);
			}
		}

		if (!m_CharTemplate.bIsCosmetic && `PRES.m_kUnitFlagManager != none)
		{
			`PRES.m_kUnitFlagManager.AddFlag(GetReference());
		}


	}

	return UnitVisualizer;
}

function SyncVisualizer(optional XComGameState GameState = none)
{
	local XGUnit UnitVisualizer;
	local name EffectName;
	local XComGameState_Effect EffectState;
	local int x, y, t;
	local array<XComPerkContent> Perks;
	local XComGameState_Unit TargetState;
	local X2AbilityTemplate AbilityTemplate;
	local WorldInfo WInfo;
	local XComPerkContentInst PerkInstance;
	local XComUnitPawn SourcePawn;

	WInfo = class'WorldInfo'.static.GetWorldInfo();
	
	if(GameState == none)
	{
		GameState = GetParentGameState();
	}

	UnitVisualizer = XGUnit(FindOrCreateVisualizer(GameState));
	if(UnitVisualizer == none)
	{
		return; // units that have been removed from play will not have a visualizer
	}

	UnitVisualizer.m_kPlayer = XGPlayer(`XCOMHISTORY.GetVisualizer(ControllingPlayer.ObjectID));
	UnitVisualizer.m_kPlayerNativeBase = UnitVisualizer.m_kPlayer;
	UnitVisualizer.SetTeamType(GetTeam());

	if( UnitVisualizer.m_kPlayer == none )
	{
		`RedScreen("[@gameplay] SyncVisualizer: No unit visualizer for " $ GetFullName());
	}

	// Spawning system is meant to do this but since our sync created the visualizer we want it right away
	UnitVisualizer.m_bForceHidden = bRemovedFromPlay;

	SourcePawn = UnitVisualizer.GetPawn();
	SourcePawn.GameStateResetVisualizer(self);

	//Units also set up visualizers for their items, since the items are dependent on the unit visualizer
	UnitVisualizer.ApplyLoadoutFromGameState(self, GameState);

	for (x = 0; x < AppliedEffectNames.Length; ++x)
	{
		EffectName = AppliedEffectNames[x];
		EffectState = XComGameState_Effect( `XCOMHISTORY.GetGameStateForObjectID( AppliedEffects[ x ].ObjectID ) );

		AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager( ).FindAbilityTemplate( EffectState.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName );
		if (AbilityTemplate.bSkipPerkActivationActions && AbilityTemplate.bSkipPerkActivationActionsSync)
		{
			continue;
		}

		Perks.Length = 0;
		class'XComPerkContent'.static.GetAssociatedPerkDefinitions( Perks, SourcePawn, EffectState.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName );
		for (y = 0; y < Perks.Length; ++y)
		{
			if (Perks[y].AssociatedEffect == EffectName)
			{
				PerkInstance = class'XComPerkContent'.static.GetMatchingInstanceForPerk(SourcePawn, Perks[y] );
				if (PerkInstance == None)
				{
					PerkInstance = WInfo.Spawn( class'XComPerkContentInst' );
					PerkInstance.Init( Perks[y], SourcePawn);
				}

				if (!PerkInstance.IsInState('DurationActive'))
				{
					ReloadPerkContentInst(PerkInstance, EffectState, AbilityTemplate, Perks[y].AssociatedEffect, EffectName);
				}
				else
				{
					TargetState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( EffectState.ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID ) );
					if ((TargetState != none) && (TargetState.AffectedByEffectNames.Find(EffectName) != INDEX_NONE))
					{
						PerkInstance.AddPerkTarget(XGUnit( TargetState.GetVisualizer( ) ), EffectState, true);
					}
					for (t = 0; t < EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets.Length; ++t)
					{
						TargetState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets[t].ObjectID ) );
						if ((TargetState != none) && (TargetState.AffectedByEffectNames.Find(EffectName) != INDEX_NONE))
						{
							PerkInstance.AddPerkTarget(XGUnit( TargetState.GetVisualizer( ) ), EffectState, true);
						}
					}
				}

				if(!Perks[ y ].CasterDurationFXOnly && !Perks[ y ].TargetDurationFXOnly)
				{
					// It is possible this perk is for only the target or source.
					// Only break if that is not the case.
					break;
				}
			}
		}
	}

	if( bRemovedFromPlay )
	{
		// Force invisible and clear blocking tile.
		RemoveUnitFromPlay();
	}
	else
	{
		if(IsAlive() && !IsIncapacitated())
		{
			SourcePawn.UpdateAnimations();
		}
		
		if( UnitVisualizer.m_kBehavior == None )
		{
			UnitVisualizer.InitBehavior();
		}
	}

	if( IsTurret() && IsAlive() )
	{
		UpdateTurretState(true);
	}

	// Don't Ragdoll cocoons
	if (m_SpawnedCocoonRef.ObjectID != 0)
	{
		SourcePawn.RagdollFlag = eRagdoll_Never;
	}

	UnitVisualizer.VisualizedAlertLevel = UnitVisualizer.GetAlertLevel(self);

	UnitVisualizer.IdleStateMachine.bStartedPanick = bPanicked;

	if( GetMyTemplate().bLockdownPodIdleUntilReveal && UnitVisualizer.VisualizedAlertLevel != eAL_Green )
	{
		SourcePawn.GetAnimTreeController().SetAllowNewAnimations(true);
	}

	if ((RescueRingRadius > 0) && (GetTeam() == eTeam_Neutral))
	{
		SourcePawn.AttachRangeIndicator( RescueRingRadius, SourcePawn.CivilianRescueRing );
	}

	if (bGeneratesCover)
	{
		class'X2Effect_GenerateCover'.static.UpdateWorldCoverDataOnSync( self );
	}
}

function ReloadPerkContentInst(out XComPerkContentInst PerkInstance, 
									XComGameState_Effect EffectState, 
									X2AbilityTemplate AbilityTemplate,
									Name AssociatedEffectName, 
									Name EffectName)
{
	local PerkActivationData ActivationData;
	local X2Effect_Persistent TargetEffect;
	local XComGameState_Unit TargetState;
	local int EffectIndex, z;
	class'XComPerkContent'.static.ResetActivationData(ActivationData);
	ActivationData.TargetLocations = EffectState.ApplyEffectParameters.AbilityInputContext.TargetLocations;

	if (AbilityTemplate != none)
	{
		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
		{
			TargetEffect = X2Effect_Persistent(AbilityTemplate.AbilityShooterEffects[EffectIndex]);

			if ((TargetEffect != none) &&
				(TargetEffect.EffectName == AssociatedEffectName))
			{
				z = AffectedByEffectNames.Find(TargetEffect.EffectName);
				`assert( z != INDEX_NONE );

				ActivationData.ShooterEffect = AffectedByEffects[z];

				break;
			}
		}
	}

	TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID));
	EffectIndex = TargetState != none ? TargetState.AffectedByEffectNames.Find(EffectName) : INDEX_NONE;
	if (EffectIndex != INDEX_NONE)
	{
		ActivationData.TargetUnits.AddItem(XGUnit(TargetState.GetVisualizer()));
		ActivationData.TargetEffects.AddItem(TargetState.AffectedByEffects[EffectIndex]);
	}
	for (z = 0; z < EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets.Length; ++z)
	{
		TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets[z].ObjectID));
		EffectIndex = TargetState != none ? TargetState.AffectedByEffectNames.Find(EffectName) : INDEX_NONE;
		if (EffectIndex != INDEX_NONE)
		{
			ActivationData.TargetUnits.AddItem(XGUnit(TargetState.GetVisualizer()));
			ActivationData.TargetEffects.AddItem(TargetState.AffectedByEffects[EffectIndex]);
		}
	}


	if ((ActivationData.ShooterEffect.ObjectID > 0) || (ActivationData.TargetUnits.Length > 0) || (ActivationData.TargetLocations.Length > 0))
		PerkInstance.OnPerkLoad(ActivationData);
	else
		PerkInstance.GotoState( 'PendingDestroy' );
}

function AppendAdditionalSyncActions( out VisualizationActionMetadata ActionMetadata, const XComGameStateContext Context)
{
	local int x;
	local name EffectName;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Persistent;
	local X2AbilityTemplate Template;

	// run through the applied effects and see if anything needs to sync
	for (x = 0; x < AppliedEffectNames.Length; ++x)
	{
		EffectName = AppliedEffectNames[ x ];
		EffectState = XComGameState_Effect( `XCOMHISTORY.GetGameStateForObjectID( AppliedEffects[ x ].ObjectID ) );

		Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager( ).FindAbilityTemplate( EffectState.ApplyEffectParameters.EffectRef.SourceTemplateName );
		if ((Template != none) && (Template.BuildAppliedVisualizationSyncFn != none))
		{
			Template.BuildAppliedVisualizationSyncFn(EffectName, EffectState.GetParentGameState(), ActionMetadata ); 
		}
	}

	// find world effects and apply them since those aren't referenced in two places
	for (x = 0; x < AffectedByEffectNames.Length; ++x)
	{
		EffectName = AffectedByEffectNames[ x ];
		EffectState = XComGameState_Effect( `XCOMHISTORY.GetGameStateForObjectID( AffectedByEffects[ x ].ObjectID ) );

		if (EffectState.ApplyEffectParameters.EffectRef.LookupType != TELT_WorldEffect)
		{
			Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager( ).FindAbilityTemplate( EffectState.ApplyEffectParameters.EffectRef.SourceTemplateName );
			if ((Template != none) && (Template.BuildAffectedVisualizationSyncFn != none))
			{
				Template.BuildAffectedVisualizationSyncFn( EffectName, EffectState.GetParentGameState( ), ActionMetadata );
			}
		}

		Persistent = EffectState.GetX2Effect( );
		if (Persistent != none)
		{
			Persistent.AddX2ActionsForVisualization_Sync( EffectState.GetParentGameState( ), ActionMetadata );
		}
	}

	if( GhostSourceUnit.ObjectID > 0 )
	{
		class'X2Effect_SpawnGhost'.static.SyncGhostActions(ActionMetadata, Context);
	}
}


function DoAmbushTutorial()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	if (XComHQ != None && !XComHQ.bHasPlayedAmbushTutorial && IsConcealed())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Ambush Tutorial");
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForAmbushTutorial;

		// Update the HQ state to record that we saw this enemy type
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.Class, XComHQ.ObjectID));
		XComHQ.bHasPlayedAmbushTutorial = true;

		`TACTICALRULES.SubmitGameState(NewGameState);

		class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(class'XLocalizedData'.default.AmbushTutorialTitle,
																							class'XLocalizedData'.default.AmbushTutorialText,
																							class'UIUtilities_Image'.static.GetTutorialImage_Ambush());
	}
}

function BuildVisualizationForAmbushTutorial(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlayNarrative NarrativeAction;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));

	NarrativeAction = X2Action_PlayNarrative(class'X2Action_PlayNarrative'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	NarrativeAction.Moment = XComNarrativeMoment'X2NarrativeMoments.CENTRAL_Tactical_Tutorial_Mission_Two_Ambush';
	NarrativeAction.WaitForCompletion = false;

	ActionMetadata.StateObject_OldState = UnitState;
	ActionMetadata.StateObject_NewState = UnitState;
	
}

function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit EventUnit;
	local XComGameStateContext_TacticalGameRule NewContext;
	local XComGameState NewGameState;

	EventUnit = XComGameState_Unit(EventData);

	if( EventUnit.ObjectID == ObjectID )
	{
		if( CanTakeCover() )
		{
			NewContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_ClaimCover);
			NewContext.UnitRef = GetReference();
			NewGameState = NewContext.ContextBuildGameState();
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}

		// TODO: update the EventMgr & move this to a PreSubmit deferral

		// dkaplan - 8/12/15 - we no longer update detection modifiers based on cover; we may want to revisit this for expansion
	}

	return ELR_NoInterrupt;
}

function RegisterForEvents()
{
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local StateObjectReference BondmateRef;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	EventManager = `XEVENTMGR;
	ThisObj = self;
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(ControllingPlayer.ObjectID));

	if (!GetMyTemplate().bIsCosmetic)
	{
		// Cosmetic units should not get these events as it causes them to break concealment and trigger alerts
		EventManager.RegisterForEvent(ThisObj, 'ObjectMoved', OnUnitEnteredTile, ELD_OnStateSubmitted, , ThisObj);
		EventManager.RegisterForEvent(ThisObj, 'UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted, , ThisObj);
	}
	EventManager.RegisterForEvent(ThisObj, 'UnitTakeEffectDamage', OnUnitTookDamage, ELD_OnStateSubmitted, , ThisObj);

	if( HasSoldierBond(BondmateRef) )
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		if( XComHQ.IsUnitInSquad(BondmateRef) )
		{
			EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', PreAbilityActivated, ELD_PreStateSubmitted);
			EventManager.RegisterForEvent(ThisObj, 'UnitGroupTurnEnded', PreGroupTurnTicked, ELD_PreStateSubmitted, , GetGroupMembership());
		}
	}
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted, , PlayerState);
	EventManager.RegisterForEvent(ThisObj, 'EffectBreakUnitConcealment', OnEffectBreakUnitConcealment, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'EffectEnterUnitConcealment', OnEffectEnterUnitConcealment, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'AlertDataTriggerAlertAbility', OnAlertDataTriggerAlertAbility, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'UnitRemovedFromPlay', OnUnitRemovedFromPlay, ELD_OnVisualizationBlockCompleted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'UnitRemovedFromPlay', OnUnitRemovedFromPlay_GameState, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'UnitDied', OnThisUnitDied, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'Alerted', OnUnitAlerted, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'UnitChangedTeam', UnitChangedTeam_Listener, ELD_OnStateSubmitted, , ThisObj);
}

function RefreshEventManagerRegistrationOnLoad()
{
	RegisterForEvents();
}

/// <summary>
/// "Transient" variables that should be cleared when this object is added to a start state
/// </summary>
function OnBeginTacticalPlay(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local XComGameState_BattleData BattleDataState;

	super.OnBeginTacticalPlay(NewGameState);

	EventManager = `XEVENTMGR;

	EventManager.TriggerEvent( 'OnUnitBeginPlay', self, self, NewGameState );

	if( !bEverAppliedFirstTimeStatModifiers )
	{
		ApplyFirstTimeStatModifiers();
	}

	// If Boosted, Max out health and will
	if(bRecoveryBoosted)
	{
		SetCurrentStat(eStat_HP, GetMaxStat(eStat_HP));
		SetCurrentStat(eStat_Will, GetMaxStat(eStat_Will));
	}

	WillEventsActivatedThisMission.Length = 0;

	LowestHP = GetCurrentStat(eStat_HP);
	HighestHP = GetCurrentStat(eStat_HP);
	MissingHP = GetMaxStat(eStat_HP) - GetCurrentStat(eStat_HP);
	LastDamagedByUnitID = 0;

	RegisterForEvents();

	CleanupUnitValues(eCleanup_BeginTactical);

	// Start Issue #44
	// Store our starting will the first time we enter a mission sequence, for use in XComGameStateContext_WillRoll
	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	// Don't store the will if we are in a multi-mission and we have already appeared in this mission
	// This should catch cases like Lost&Abandoned, where units may appear first in the second part
	if (
		(BattleDataState.DirectTransferInfo.IsDirectMissionTransfer 
		&& BattleDataState.DirectTransferInfo.TransferredUnitStats.Find('UnitStateRef', self.GetReference()) != INDEX_NONE)
		== false)
	{
		// This is the value consistent with base-game behavior (before any stat bonuses from abilities, since this is set before any abilities are triggered)
		// We can't ever let it be cleared, since a "BeginTactical" rule would clean it up when we want to explicitely keep it
		SetUnitFloatValue('CH_StartMissionWill', GetCurrentStat(eStat_Will), eCleanup_Never);
	}
	// End Issue #44

	//Units removed from play in previous tactical play are no longer removed, unless they are explicitly set to remain so.
	//However, this update happens too late to get caught in the usual tile-data build.
	//So, if we're coming back into play, make sure to update the tile we now occupy.
	if (bRemovedFromPlay && !GetMyTemplate().bDontClearRemovedFromPlay)
	{
		BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if(!BattleDataState.DirectTransferInfo.IsDirectMissionTransfer)
		{
			bRemovedFromPlay = false;
			`XWORLD.SetTileBlockedByUnitFlag(self);
		}
	}

	bRequiresVisibilityUpdate = true;
}

function ApplyFirstTimeStatModifiers()
{
	local float CurrentHealthMax;

	bEverAppliedFirstTimeStatModifiers = true;

	if( `SecondWaveEnabled('BetaStrike' ) && GetMyTemplate().CharacterGroupName != 'TheLost')
	{
		CurrentHealthMax = GetMaxStat(eStat_HP);
		if (!bIsSpecial)
		{
			SetBaseMaxStat(eStat_HP, CurrentHealthMax +
				GetMyTemplate().GetCharacterBaseStat(eStat_HP) *
				(class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod - 1.0));
		}
		else // Alien Rulers have 1.5X their HP with Beta Strike
		{
			SetBaseMaxStat(eStat_HP, Round(CurrentHealthMax + GetMyTemplate().GetCharacterBaseStat(eStat_HP) * 0.5));
		}
		SetCurrentStat(eStat_HP, GetMaxStat(eStat_HP));

		// Redo the stat assignment complete
		if(GetMyTemplate().OnStatAssignmentCompleteFn != none)
		{
			GetMyTemplate().OnStatAssignmentCompleteFn(self);
		}
	}

}

// Unit needs to reregister for events that are tied to its player state.  (Fixes AutoRun issues when units swap teams)
function OnSwappedTeams( StateObjectReference NewPlayerRef )
{
	local XComGameState_Player PlayerState;
	local X2EventManager EventManager;
	local Object ThisObj;
	EventManager = `XEVENTMGR;
	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(NewPlayerRef.ObjectID));
	ThisObj = self;
	EventManager.UnRegisterFromEvent(ThisObj, 'PlayerTurnBegun');
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted, , PlayerState);
	// Also queue up his auto-play move if he has action points.
	// This is apparently no longer needed and is causing bonkers behavior in XPACK resistance missions
	// AutoRunBehaviorTree(Name(GetMyTemplate().strAutoRunNonAIBT), NumActionPoints());
}

function EventListenerReturn UnitChangedTeam_Listener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameStateContext_EffectRemoved EffectRemovedContext;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent PersistentEffect;
	local bool bRemove, bAtLeastOneRemoved;
		
	// Check to see if the target is an Advent Priest, if so remove Holy Warrior or Mind Control that is is the source of
	History = `XCOMHISTORY;

	bAtLeastOneRemoved = false;
	foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		PersistentEffect = EffectState.GetX2Effect();
		bRemove = false;

		if ((EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == ObjectID) &&
			(class'X2StatusEffects'.default.REMOVE_EFFECTS_ON_TEAM_SWAP_SOURCE.Find(PersistentEffect.EffectName) != INDEX_NONE))
		{
			// The Unit under stasis is the source of this existing effect
			bRemove = true;
		}

		if (!bRemove &&
			(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == ObjectID) &&
			(class'X2StatusEffects'.default.REMOVE_EFFECTS_ON_TEAM_SWAP_TARGET.Find(PersistentEffect.EffectName) != INDEX_NONE))
		{
			// The Unit under stasis is the target of this existing effect
			bRemove = true;
		}

		if (bRemove)
		{
			// Stasis removes the existing effect
			if( !bAtLeastOneRemoved )
			{
				EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
				NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
				EffectRemovedContext.RemovedEffects.Length = 0;

				bAtLeastOneRemoved = true;
			}

			EffectState.RemoveEffect(NewGameState, NewGameState, false);

			EffectRemovedContext.RemovedEffects.AddItem(EffectState.GetReference());
		}
	}

	if( bAtLeastOneRemoved )
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function OnEndTacticalPlay(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local StateObjectReference EmptyReference, EffectRef;
	local XComGameState_Effect EffectState;
	local LootResults EmptyLootResults;
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnEndTacticalPlay(NewGameState);

	History = `XCOMHISTORY;
	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.UnRegisterFromEvent(ThisObj, 'ObjectMoved');
	EventManager.UnRegisterFromEvent(ThisObj, 'UnitMoveFinished' );
	EventManager.UnRegisterFromEvent(ThisObj, 'UnitTakeEffectDamage');
	EventManager.UnRegisterFromEvent(ThisObj, 'AbilityActivated');
	EventManager.UnRegisterFromEvent(ThisObj, 'PlayerTurnBegun');
	EventManager.UnRegisterFromEvent(ThisObj, 'EffectBreakUnitConcealment');
	EventManager.UnRegisterFromEvent(ThisObj, 'EffectEnterUnitConcealment');
	EventManager.UnRegisterFromEvent(ThisObj, 'AlertDataTriggerAlertAbility');
	EventManager.UnRegisterFromEvent(ThisObj, 'UnitDied');
	EventManager.UnRegisterFromEvent(ThisObj, 'UnitChangedTeam');

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != None)
		{
			EffectState.GetX2Effect().UnitEndedTacticalPlay(EffectState, self);
		}
	}

	TileLocation.X = -1;
	TileLocation.Y = -1;
	TileLocation.Z = -1;
	
	bDisabled = false;	
	Abilities.Length = 0;
	ReflexActionState = eReflexActionState_None;
	PendingLoot = EmptyLootResults;
	AffectedByEffectNames.Length = 0;
	AffectedByEffects.Length = 0;
	AppliedEffectNames.Length = 0;
	AppliedEffects.Length = 0;
	DamageResults.Length = 0;
	Ruptured = 0;
	bTreatLowCoverAsHigh = false;
	m_SpawnedCocoonRef = EmptyReference;
	m_MultiTurnTargetRef = EmptyReference;
	m_SuppressionHistoryIndex = -1;
	bPanicked = false;
	bInStasis = false;
	m_bConcealed = false;
	bHasSuperConcealment = false;
	SuperConcealmentLoss = 0;
	bGeneratesCover = false;
	CoverForceFlag = CoverForce_Default;
	ReflectedAbilityContext = none;

	TraversalChanges.Length = 0;
	ResetTraversals();

	if (!GetMyTemplate().bIgnoreEndTacticalHealthMod)
	{
		EndTacticalHealthMod();
	}

	if(bRecoveryBoosted)
	{
		SetCurrentStat(eStat_HP, float(Min(PreBoostHealth, int(GetCurrentStat(eStat_HP)))));
		SetCurrentStat(eStat_Will, float(Min(PreBoostWill, int(GetCurrentStat(eStat_Will)))));

		// Set Lowest HP here as well to show on the walk-up correctly
		LowestHP = GetCurrentStat(eStat_HP);
		UnBoostSoldier();
	}

	if (!GetMyTemplate().bIgnoreEndTacticalRestoreArmor)
	{
		Shredded = 0;
	}

	if (GetMyTemplate().OnEndTacticalPlayFn != none)
	{
		GetMyTemplate().OnEndTacticalPlayFn(self);
	}
}

// Health is adjusted after tactical play so that units that only took armor damage still require heal time
function EndTacticalHealthMod()
{
	local float HealthPercent, NewHealth, SWHeal;
	local int RoundedNewHealth, HealthLost, NewMissingHP;

	HealthLost = HighestHP - LowestHP;

	if (LowestHP > 0 && `SecondWaveEnabled('BetaStrike'))  // Immediately Heal 1/2 Damage
	{
		SWHeal = FFloor( HealthLost / 2 );
		LowestHP += SWHeal;
		HealthLost -= SWHeal;
	}

	// If Dead or never injured, return
	if(LowestHP <= 0 || (HealthLost <= 0 && MissingHP == 0))
	{
		return;
	}

	// Calculate health percent
	HealthPercent = (float(HighestHP - HealthLost) / float(HighestHP));

	// Calculate and apply new health value
	NewHealth = (HealthPercent * GetBaseStat(eStat_HP));
	RoundedNewHealth = Round(NewHealth);
	RoundedNewHealth = Clamp(RoundedNewHealth, 1, (int(GetBaseStat(eStat_HP)) - 1));
	RoundedNewHealth = Min(RoundedNewHealth, LowestHP);

	// Ensure that any HP which was missing for this unit at the start of the mission is still missing now even though armor has been removed
	// This guarnatees we have consistent health values if the unit entered the mission wounded and did not get injured further
	NewMissingHP = int(GetBaseStat(eStat_HP)) - RoundedNewHealth;
	if (NewMissingHP < MissingHP)
	{
		RoundedNewHealth -= (MissingHP - NewMissingHP);
	}

	SetCurrentStat(eStat_HP, RoundedNewHealth);
}

/**
 *  These functions should exist on all data instance classes, but they are not implemented as an interface so
 *  the correct classes can be used for type checking, etc.
 *  
 *  function <TemplateManagerClass> GetMyTemplateManager()
 *      @return the manager which should be available through a static function on XComEngine.
 *      
 *  function name GetMyTemplateName()
 *      @return the name of the template this instance was created from. This should be saved in a private field separate from a reference to the template.
 *      
 *  function <TemplateClass> GetMyTemplate()
 *      @return the template used to create this instance. Use a private variable to cache it, as it shouldn't be saved in a checkpoint.
 *      
 *  function OnCreation(<TemplateClass> Template)
 *      @param Template this instance should base itself on, which is as meaningful as you need it to be.
 *      Cache a reference to the template now, store its name, and perform any other required setup.
 */

static function X2CharacterTemplateManager GetMyTemplateManager()
{
	return class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
}

simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

simulated function name GetMyTemplateGroupName()
{
	local X2CharacterTemplate CharacterTemplate;

	CharacterTemplate = GetMyTemplate();

	if( CharacterTemplate != None )
	{
		if (CharacterTemplate.CharacterGroupName != '')
		{
			return CharacterTemplate.CharacterGroupName;
		}
		else
		{
			return CharacterTemplate.DataName;
		}
	}
	else
	{
		return '';
	}
}

/// <summary>
/// Called immediately prior to loading, this method is called on each state object so that its resources can be ready when the map completes loading. Request resources
/// should output an array of strings containing archetype paths to load
/// </summary>
event RequestResources(out array<string> ArchetypesToLoad)
{
	local X2CharacterTemplate CharacterTemplate;
	local X2BodyPartTemplate BodyPartTemplate;
	local X2BodyPartTemplateManager PartManager;	
	local X2StrategyElementTemplateManager StratMgr;
	local X2CountryTemplate CountryTemplate;
	local int Index;
	local name UnderlayName;

	super.RequestResources(ArchetypesToLoad);

	//Load the character pawn(s)
	CharacterTemplate = GetMyTemplate();
	for(Index = 0; Index < CharacterTemplate.strPawnArchetypes.Length; ++Index)
	{
		ArchetypesToLoad.AddItem(CharacterTemplate.strPawnArchetypes[Index]);
	}
	
	//Load the character's body parts
	if(CharacterTemplate.bAppearanceDefinesPawn || CharacterTemplate.bForceAppearance)
	{
		if (CharacterTemplate.bForceAppearance)
			class'XComHumanPawn'.static.UpdateAppearance(kAppearance, CharacterTemplate.ForceAppearance);

		PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

		if(kAppearance.nmPawn != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Pawn", kAppearance.nmPawn);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmTorso != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Torso", kAppearance.nmTorso);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		UnderlayName = kAppearance.nmTorso_Underlay;
		if (UnderlayName == '')
			UnderlayName = class'XComHumanPawn'.static.GetUnderlayName(true, kAppearance);

		if (UnderlayName != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Torso", UnderlayName);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmTorsoDeco != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("TorsoDeco", kAppearance.nmTorsoDeco);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmHead != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Head", kAppearance.nmHead);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}
				
		if(kAppearance.nmHelmet != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Helmets", kAppearance.nmHelmet);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}
				
		if(kAppearance.nmFacePropLower != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("FacePropsLower", kAppearance.nmFacePropLower);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmHaircut != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Hair", kAppearance.nmHaircut);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmBeard != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Beards", kAppearance.nmBeard);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmFacePropUpper != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("FacePropsUpper", kAppearance.nmFacePropUpper);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmArms != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Arms", kAppearance.nmArms);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmArms_Underlay != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Arms", kAppearance.nmArms_Underlay);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmLeftArm != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("LeftArm", kAppearance.nmLeftArm);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmRightArm != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("RightArm", kAppearance.nmRightArm);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmLeftArmDeco != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("LeftArmDeco", kAppearance.nmLeftArmDeco);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmRightArmDeco != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("RightArmDeco", kAppearance.nmRightArmDeco);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmLeftForearm != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("LeftForearm", kAppearance.nmLeftForearm);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmRightForearm != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("RightForearm", kAppearance.nmRightForearm);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmLegs != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Legs", kAppearance.nmLegs);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmLegs_Underlay != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Legs", kAppearance.nmLegs_Underlay);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		/*if (kAppearance.nmThighs != '') - Potential problems with cloth
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Thighs", kAppearance.nmThighs);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}*/

		if (kAppearance.nmShins != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Shins", kAppearance.nmShins);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmEye != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Eyes", kAppearance.nmEye);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmTeeth != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Teeth", kAppearance.nmTeeth);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmPatterns != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Patterns", kAppearance.nmPatterns);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmWeaponPattern != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Patterns", kAppearance.nmWeaponPattern);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmTattoo_LeftArm != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Tattoos", kAppearance.nmTattoo_LeftArm);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmTattoo_RightArm != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Tattoos", kAppearance.nmTattoo_RightArm);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmScars != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Scars", kAppearance.nmScars);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmFacePaint != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Facepaint", kAppearance.nmFacePaint);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if (kAppearance.nmFlag != '')
		{
			StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
			CountryTemplate = X2CountryTemplate(StratMgr.FindStrategyElementTemplate(kAppearance.nmFlag));
			ArchetypesToLoad.AddItem(CountryTemplate.FlagArchetype);
		}

		//Don't load voices as part of this - they are caught when the pawn loads, or the voice previewed
	}
}

simulated native function X2CharacterTemplate GetMyTemplate() const;

simulated function X2CharacterTemplate GetOwnerTemplate()
{
	local XComGameState_Unit kOwner;
	if (OwningObjectId > 0)
	{
		kOwner = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwningObjectId));
		return kOwner.GetMyTemplate();
	}
	return none;
}

//Call to update the character's stored personality template
simulated function UpdatePersonalityTemplate()
{
	PersonalityTemplateName = '';
	PersonalityTemplate = none;
	PersonalityTemplate = GetPersonalityTemplate();
}

simulated function X2SoldierPersonalityTemplate GetPersonalityTemplate()
{
	local array<X2StrategyElementTemplate> PersonalityTemplates;
	if(PersonalityTemplate == none)
	{		
		if(PersonalityTemplateName == '')
		{			
			PersonalityTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');
			PersonalityTemplate = X2SoldierPersonalityTemplate(PersonalityTemplates[kAppearance.iAttitude]);
		}
		else
		{
			PersonalityTemplate = X2SoldierPersonalityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(PersonalityTemplateName));
		}
	}

return PersonalityTemplate;
}

simulated function X2SoldierPersonalityTemplate GetPhotoboothPersonalityTemplate()
{
	local X2SoldierPersonalityTemplate PhotoboothPersonalityTemplate;

	if( GetMyTemplate().PhotoboothPersonality != '' )
	{
		PhotoboothPersonalityTemplate = X2SoldierPersonalityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(GetMyTemplate().PhotoboothPersonality));
		if( PhotoboothPersonalityTemplate != none )
		{
			return PhotoboothPersonalityTemplate;
		}
	}

	return class'X2StrategyElement_DefaultSoldierPersonalities'.static.Personality_ByTheBook();
}

function GiveRandomPersonality()
{
	local array<X2StrategyElementTemplate> PersonalityTemplates;
	local XGUnit UnitVisualizer;
	local XComHumanPawn HumanPawn;
	local int iChoice;

	PersonalityTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');
	iChoice = `SYNC_RAND(PersonalityTemplates.Length);

	PersonalityTemplate = X2SoldierPersonalityTemplate(PersonalityTemplates[iChoice]);
	PersonalityTemplateName = PersonalityTemplate.DataName;
	kAppearance.iAttitude = iChoice; // Attitude needs to be in sync

	//Update the appearance stored in our visualizer if we have one
	UnitVisualizer = XGUnit(GetVisualizer());
	if( UnitVisualizer != none && UnitVisualizer.GetPawn() != none )
	{
		HumanPawn = XComHumanPawn(UnitVisualizer.GetPawn());
		if( HumanPawn != none )
		{
			HumanPawn.SetAppearance(kAppearance, false);
		}
	}
}

function GiveCombatIntelligence()
{
	local array<int> ComIntThresholds;
	local int idx, ComIntRoll;
	
	if (class'X2StrategyGameRulesetDataStructures'.static.Roll(class'X2StrategyGameRulesetDataStructures'.default.ComIntAboveAverageChance))
	{
		ComIntThresholds = class'X2StrategyGameRulesetDataStructures'.default.ComIntThresholds;
		ComIntRoll = `SYNC_RAND_STATIC(100);
		
		for (idx = 0; idx < ComIntThresholds.Length; idx++)
		{
			if (ComIntRoll < ComIntThresholds[idx])
			{
				ComInt = ECombatIntelligence(1 + idx);
				break;
			}
		}
	}
	else
	{
		ComInt = eComInt_Standard;
	}
}

function ImproveCombatIntelligence()
{
	local int iRank, APIncrease;
		
	// First improve Combat Intelligence to the next rank
	if (ComInt < eComInt_Savant)
	{
		ComInt = ECombatIntelligence(ComInt + 1);
	}

	// Provide additional AP as if the soldier had the higher ComInt the entire time
	for (iRank = m_SoldierRank; iRank >= 2; iRank--)
	{
		if (IsResistanceHero())
		{			
			APIncrease += (GetResistanceHeroAPAmount(iRank, ComInt) - GetResistanceHeroAPAmount(iRank, ECombatIntelligence(ComInt - 1)));
		}
		else
		{
			APIncrease += (GetBaseSoldierAPAmount(ComInt) - GetBaseSoldierAPAmount(ECombatIntelligence(ComInt - 1)));
		}
	}

	AbilityPoints += Round(APIncrease);
}

private function int GetResistanceHeroAPAmount(int SoldierRank, ECombatIntelligence eComInt)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local int APReward, BaseAP;

	History = `XCOMHISTORY;
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));

	BaseAP = GetSoldierClassTemplate().BaseAbilityPointsPerPromotion;
	if (SoldierRank >= 7) // Colonel abilities are way more expensive, so give the appropriate points to buy one of them
	{
		APReward = class'X2StrategyGameRulesetDataStructures'.default.PowerfulAbilityPointCost;
	}
	else
	{
		APReward += BaseAP; // Always start with base points
		APReward += (SoldierRank - 2); // Ability points gained is enough to buy new rank
	}

	if (SoldierRank >= 3)
	{
		// And half the cost of one ability from the previous rank
		APReward += ((BaseAP + (m_SoldierRank - 3)) / 2);
	}
	APReward *= class'X2StrategyGameRulesetDataStructures'.default.ResistanceHeroComIntModifiers[eComInt];

	// AP amount could be modified by Resistance Orders
	if(ResHQ.AbilityPointScalar > 0)
	{
		APReward = Round(float(APReward) * ResHQ.AbilityPointScalar);
	}

	return APReward;
}

private function int GetBaseSoldierAPAmount(ECombatIntelligence eComInt)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local int APReward;

	// Base game soldier classes gain a lot less AP than other soldiers
	APReward += GetSoldierClassTemplate().BaseAbilityPointsPerPromotion; // Always start with base points
	if (APReward > 0)
	{
		// Only give AP reward bonus if the soldier class has a base AP gain per promotion
		APReward += class'X2StrategyGameRulesetDataStructures'.default.BaseSoldierComIntBonuses[eComInt];

		// AP amount could be modified by Resistance Orders
		History = `XCOMHISTORY;
		ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

		if(ResHQ.AbilityPointScalar > 0)
		{
			APReward = Round(float(APReward) * ResHQ.AbilityPointScalar);
		}
	}

	return APReward;
}

simulated function name GetComponentSocket()
{
	local X2CharacterTemplate kOwnerTemplate;
	local name SocketName;
	local int CompIndex;
	kOwnerTemplate = GetOwnerTemplate();
	if( kOwnerTemplate != None )
	{
		CompIndex = kOwnerTemplate.SubsystemComponents.Find('SubsystemTemplateName', m_TemplateName);
		if( CompIndex != -1 )
		{
			SocketName = kOwnerTemplate.SubsystemComponents[CompIndex].SocketName;
		}
		else
		{
			`Warn("Could not find this component from owner's SubsystemComponents list! TemplateName="@m_TemplateName@"OwnerName="$kOwnerTemplate.DataName);
		}
	}
	return SocketName;
}

event OnCreation(optional X2DataTemplate InitTemplate)
{
	local int i;
	local ECharStatType StatType;
	local float StatVal;
	local XComGameState_AdventChosen ChosenState;

	super.OnCreation( InitTemplate );

	m_CharTemplate = X2CharacterTemplate( InitTemplate );
	m_TemplateName = m_CharTemplate.DataName;

	UnitSize = m_CharTemplate.UnitSize;
	UnitHeight = m_CharTemplate.UnitHeight;

	//bConcealed = false;
	//AlertStatus = eAL_Green;
	
	for (i = 0; i < eStat_MAX; ++i)
	{
		StatType = ECharStatType(i);
		CharacterStats[i].Type = StatType;
		SetBaseMaxStat( StatType, m_CharTemplate.GetCharacterBaseStat(StatType) );
		SetCurrentStat( StatType, GetMaxStat(StatType) );
	}

	// Some starting stats can be randomized, determine those values here (overwrites base stat values)
	for(i = 0; i < m_CharTemplate.RandomizedBaseStats.Length; ++i)
	{
		StatVal = m_CharTemplate.RandomizedBaseStats[i].StatAmount;
		//  add random amount if any
		if(m_CharTemplate.RandomizedBaseStats[i].RandStatAmount > 0)
		{
			StatVal += `SYNC_RAND(m_CharTemplate.RandomizedBaseStats[i].RandStatAmount);
		}
		//  cap the new value if required
		if(m_CharTemplate.RandomizedBaseStats[i].CapStatAmount > 0)
		{
			if(StatVal > m_CharTemplate.RandomizedBaseStats[i].CapStatAmount)
				StatVal = m_CharTemplate.RandomizedBaseStats[i].CapStatAmount;
		}

		SetBaseMaxStat(m_CharTemplate.RandomizedBaseStats[i].StatType, StatVal);
		SetCurrentStat(m_CharTemplate.RandomizedBaseStats[i].StatType, StatVal);
	}

	// Create and apply soldier class template to the unit.
	// Takes place after base stat generation so any rank up stat changes from the soldier class are applied correctly
	if (IsSoldier())
	{
		// if we specify a non-default soldier class, start the unit off at squaddie rank so they get the base
		// class abilities (this will also set them to the default class)
		if ((m_CharTemplate.DefaultSoldierClass != '' && m_CharTemplate.DefaultSoldierClass != class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)  )
		{
			m_SoldierRank = 0;
			SetXPForRank(1);
			StartingRank = 1;
			RankUpSoldier(GetParentGameState(), m_CharTemplate.DefaultSoldierClass);
		}
		else if (m_SoldierClassTemplateName != 'Rookie' && m_SoldierClassTemplateName != '')
		{
			m_SoldierRank = 0;
			SetXPForRank(1);
			StartingRank = 1;
			RankUpSoldier(GetParentGameState(), m_SoldierClassTemplateName);
		}
		else
		{
			m_SoldierRank = 0;
			SetXPForRank(0);
			StartingRank = 0;
			SetSoldierClassTemplate(class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass);
		}
	}

	GiveCombatIntelligence();

	LowestHP = GetCurrentStat(eStat_HP);
	HighestHP = GetCurrentStat(eStat_HP);

	if (m_CharTemplate.OnStatAssignmentCompleteFn != none)
	{
		m_CharTemplate.OnStatAssignmentCompleteFn(self);
	}

	//RAM - not all stats should start at CharacterMax. Perhaps there is a better way to do this, but for now we can set these here...
	SetCurrentStat(eStat_AlertLevel, `ALERT_LEVEL_GREEN );
	if( !m_CharTemplate.bIsSoldier && !m_CharTemplate.bIsCivilian )
	{
		//If this is an alien or advent, adjust their sight radius according to the patrol setting
		SetBaseMaxStat(eStat_SightRadius, m_CharTemplate.GetCharacterBaseStat(eStat_SightRadius));
		SetCurrentStat( eStat_SightRadius, GetMaxStat(eStat_SightRadius) );
	}

	if(m_CharTemplate.bAppearanceDefinesPawn)
	{
		if(m_CharTemplate.bForceAppearance)
		{
			kAppearance = m_CharTemplate.ForceAppearance;

			if(m_CharTemplate.ForceAppearance.nmFlag != '')
			{
				SetCountry(m_CharTemplate.ForceAppearance.nmFlag);
			}
		}
		else if(m_CharTemplate.bHasFullDefaultAppearance)
		{
			kAppearance = m_CharTemplate.DefaultAppearance;

			if(m_CharTemplate.DefaultAppearance.nmFlag != '')
			{
				SetCountry(m_CharTemplate.ForceAppearance.nmFlag);
			}
		}
	}

	//If a gender is wanted and we are a null gender, set one
	if(m_CharTemplate.bSetGenderAlways && kAppearance.iGender == 0)
	{
		kAppearance.iGender = (Rand(2) == 0) ? eGender_Female : eGender_Male;
	}

	// If the character has a forced name, set it here
	if(m_CharTemplate.strForcedFirstName != "" || m_CharTemplate.strForcedLastName != "" || m_CharTemplate.strForcedNickName != "")
	{
		SetCharacterName(m_CharTemplate.strForcedFirstName, m_CharTemplate.strForcedLastName, m_CharTemplate.strForcedNickName);
	}

	ResetTraversals();

	if (m_CharTemplate.bIsChosen)
	{
		foreach `XCOMHISTORY.IterateByClassType( class'XComGameState_AdventChosen', ChosenState )
		{
			if (ChosenState.GetChosenTemplate() == m_CharTemplate)
			{
				ChosenRef = ChosenState.GetReference();
				break;
			}
		}
	}
}

event RollForTimedLoot()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2LootTableManager LootManager;

	LootManager = class'X2LootTableManager'.static.GetLootTableManager();

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if( XComHQ != none && XComHQ.SoldierUnlockTemplates.Find('VultureUnlock') != INDEX_NONE )
	{
		// vulture loot roll
		LootManager.RollForLootCarrier(m_CharTemplate.VultureLoot, PendingLoot);
	}
	else
	{
		// roll on regular timed loot if vulture is not enabled
		LootManager.RollForLootCarrier(m_CharTemplate.TimedLoot, PendingLoot);
	}
}

function RollForAutoLoot(XComGameState NewGameState)
{
	local LootResults PendingAutoLoot;
	local XComGameState_BattleData BattleDataState;
	local XComGameStateHistory History;
	local Name LootTemplateName;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item NewItem;
	local int VisualizeLootIndex;
	local bool AnyAlwaysRecoverLoot;

	if( m_CharTemplate.Loot.LootReferences.Length > 0)
	{
		class'X2LootTableManager'.static.GetLootTableManager().RollForLootCarrier(m_CharTemplate.Loot, PendingAutoLoot);

		if( PendingAutoLoot.LootToBeCreated.Length > 0 )
		{
			AnyAlwaysRecoverLoot = false;

			VisualizeLootIndex = NewGameState.GetContext().HasPostBuildVisualization(VisualizeAutoLoot);
			//Remove any previous VisualizeAutoLoot call as the function only needs to happen once per new game state.
			if (VisualizeLootIndex != INDEX_NONE)
			{
				NewGameState.GetContext().PostBuildVisualizationFn.Remove(VisualizeLootIndex, 1);
			}
			//Add the loot message at the end of the list.
			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeAutoLoot);

			History = `XCOMHISTORY;
			BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
			BattleDataState = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleDataState.ObjectID));
			ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

			foreach PendingAutoLoot.LootToBeCreated(LootTemplateName)
			{
				ItemTemplate = ItemTemplateManager.FindItemTemplate(LootTemplateName);
				if( bKilledByExplosion )
				{
					if( ItemTemplate.LeavesExplosiveRemains )
					{
						if( ItemTemplate.ExplosiveRemains != '' )
						{
							ItemTemplate = ItemTemplateManager.FindItemTemplate(ItemTemplate.ExplosiveRemains);     //  item leaves a different item behind due to explosive death
						}
					}
					else
					{
						ItemTemplate = None;
					}
				}

				if( ItemTemplate != None )
				{
					if( ItemTemplate.bAlwaysRecovered )
					{
						XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
						XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

						NewItem = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

						NewItem.OwnerStateObject = XComHQ.GetReference();
						XComHQ.PutItemInInventory(NewGameState, NewItem, true);

						AnyAlwaysRecoverLoot = true;
					}
					else
					{
						BattleDataState.AutoLootBucket.AddItem(ItemTemplate.DataName);
					}
				}
			}

			if( AnyAlwaysRecoverLoot )
			{
				NewGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeAlwaysRecoverLoot);
			}
		}
	}
}

function VisualizeAutoLoot(XComGameState VisualizeGameState)
{
	local XComPresentationLayer Presentation;
	local XComGameState_BattleData OldBattleData, NewBattleData;
	local XComGameStateHistory History;
	local int LootBucketIndex;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlayWorldMessage MessageAction;
	local XGParamTag kTag;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<Name> UniqueItemNames;
	local array<int> ItemQuantities;
	local int ExistingIndex;
	local XComGameStateVisualizationMgr LocalVisualizationMgr;

	Presentation = `PRES;
	History = `XCOMHISTORY;
	LocalVisualizationMgr = `XCOMVISUALIZATIONMGR;

	// add a message for each loot drop
	NewBattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	NewBattleData = XComGameState_BattleData(History.GetGameStateForObjectID(NewBattleData.ObjectID, , VisualizeGameState.HistoryIndex));
	OldBattleData = XComGameState_BattleData(History.GetGameStateForObjectID(NewBattleData.ObjectID, , VisualizeGameState.HistoryIndex - 1));

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = History.GetVisualizer(ObjectID);

	// try to parent to the death action if there is one
	ActionMetadata.LastActionAdded = LocalVisualizationMgr.GetNodeOfType(LocalVisualizationMgr.BuildVisTree, class'X2Action_Death', none, ObjectID);

	MessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for( LootBucketIndex = OldBattleData.AutoLootBucket.Length; LootBucketIndex < NewBattleData.AutoLootBucket.Length; ++LootBucketIndex )
	{
		ExistingIndex = UniqueItemNames.Find(NewBattleData.AutoLootBucket[LootBucketIndex]);
		if( ExistingIndex == INDEX_NONE )
		{
			UniqueItemNames.AddItem(NewBattleData.AutoLootBucket[LootBucketIndex]);
			ItemQuantities.AddItem(1);
		}
		else
		{
			++ItemQuantities[ExistingIndex];
		}
	}

	for( LootBucketIndex = 0; LootBucketIndex < UniqueItemNames.Length; ++LootBucketIndex )
	{
		kTag.StrValue0 = ItemTemplateManager.FindItemTemplate(UniqueItemNames[LootBucketIndex]).GetItemFriendlyName();
		kTag.IntValue0 = ItemQuantities[LootBucketIndex];
		MessageAction.AddWorldMessage(`XEXPAND.ExpandString(Presentation.m_strAutoLoot));
	}
}

function VisualizeAlwaysRecoverLoot(XComGameState VisualizeGameState)
{
	local XComPresentationLayer Presentation;
	local XComGameState_HeadquartersXCom OldXComHQ, NewXComHQ;
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local Name ItemTemplateName;
	local int LootBucketIndex;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlayWorldMessage MessageAction;
	local XGParamTag kTag;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<Name> UniqueItemNames;
	local array<int> ItemQuantities;
	local int ExistingIndex;
	local XComGameStateVisualizationMgr LocalVisualizationMgr;

	Presentation = `PRES;
	History = `XCOMHISTORY;
	LocalVisualizationMgr = `XCOMVISUALIZATIONMGR;

	// add a message for each loot drop
	NewXComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewXComHQ = XComGameState_HeadquartersXCom(History.GetGameStateForObjectID(NewXComHQ.ObjectID, , VisualizeGameState.HistoryIndex));
	OldXComHQ = XComGameState_HeadquartersXCom(History.GetGameStateForObjectID(NewXComHQ.ObjectID, , VisualizeGameState.HistoryIndex - 1));

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = History.GetVisualizer(ObjectID);
	// try to parent to a death action if there is one
	ActionMetadata.LastActionAdded = LocalVisualizationMgr.GetNodeOfType(LocalVisualizationMgr.BuildVisTree, class'X2Action_Death', none, ObjectID);


	MessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for( LootBucketIndex = OldXComHQ.LootRecovered.Length; LootBucketIndex < NewXComHQ.LootRecovered.Length; ++LootBucketIndex )
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(NewXComHQ.LootRecovered[LootBucketIndex].ObjectID));
		ItemTemplateName = ItemState.GetMyTemplateName();
		ExistingIndex = UniqueItemNames.Find(ItemTemplateName);
		if( ExistingIndex == INDEX_NONE )
		{
			UniqueItemNames.AddItem(ItemTemplateName);
			ItemQuantities.AddItem(1);
		}
		else
		{
			++ItemQuantities[ExistingIndex];
		}
	}

	for( LootBucketIndex = 0; LootBucketIndex < UniqueItemNames.Length; ++LootBucketIndex )
	{
		kTag.StrValue0 = ItemTemplateManager.FindItemTemplate(UniqueItemNames[LootBucketIndex]).GetItemFriendlyName();
		kTag.IntValue0 = ItemQuantities[LootBucketIndex];
		MessageAction.AddWorldMessage(`XEXPAND.ExpandString(Presentation.m_strAutoLoot));
	}
}


function ResetTraversals()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = GetMyTemplate();
	aTraversals[eTraversal_Normal]       = int(CharTemplate.bCanUse_eTraversal_Normal);	
	aTraversals[eTraversal_ClimbOver]    = int(CharTemplate.bCanUse_eTraversal_ClimbOver);	
	aTraversals[eTraversal_ClimbOnto]    = int(CharTemplate.bCanUse_eTraversal_ClimbOnto);	
	aTraversals[eTraversal_ClimbLadder]  = int(CharTemplate.bCanUse_eTraversal_ClimbLadder);	
	aTraversals[eTraversal_DropDown]     = int(CharTemplate.bCanUse_eTraversal_DropDown);	
	aTraversals[eTraversal_Grapple]      = int(CharTemplate.bCanUse_eTraversal_Grapple);	
	aTraversals[eTraversal_Landing]      = int(CharTemplate.bCanUse_eTraversal_Landing);	
	aTraversals[eTraversal_BreakWindow]  = int(CharTemplate.bCanUse_eTraversal_BreakWindow);	
	aTraversals[eTraversal_KickDoor]     = int(CharTemplate.bCanUse_eTraversal_KickDoor);	
	aTraversals[eTraversal_JumpUp]       = int(CharTemplate.bCanUse_eTraversal_JumpUp);	
	aTraversals[eTraversal_WallClimb]    = int(CharTemplate.bCanUse_eTraversal_WallClimb);
	aTraversals[eTraversal_Phasing]      = int(CharTemplate.bCanUse_eTraversal_Phasing);
	aTraversals[eTraversal_BreakWall]    = int(CharTemplate.bCanUse_eTraversal_BreakWall);
	aTraversals[eTraversal_Launch]       = int(CharTemplate.bCanUse_eTraversal_Launch);
	aTraversals[eTraversal_Flying]       = int(CharTemplate.bCanUse_eTraversal_Flying);
	aTraversals[eTraversal_Land]         = int(CharTemplate.bCanUse_eTraversal_Land);
}

native function int GetRank();

function bool IsVeteran()
{
	return GetRank() >= class'X2StrategyGameRulesetDataStructures'.default.VeteranSoldierRank;
}

function SetSoldierClassTemplate(name TemplateName)
{
	local UIScreenStack screenstacks;
	screenstacks = `Screenstack;
	if (TemplateName != m_SoldierClassTemplateName)
	{
		m_SoldierClassTemplateName = TemplateName;
		m_SoldierClassTemplate = GetSoldierClassTemplate();

		if (screenstacks != none && screenstacks.IsInStack(class'UICharacterPool')) // only do this in character pool
		{
			if (m_SoldierClassTemplateName != 'Rookie' && m_SoldierClassTemplateName != '')
			{
				m_SoldierRank = 0;
				SetXPForRank(1);
				StartingRank = 1;
				RankUpSoldier(GetParentGameState(), m_SoldierClassTemplateName);
			}
			else
			{
				m_SoldierRank = 0;
				SetXPForRank(0);
				StartingRank = 0;
			}
		}
	}
}

function bool IsChampionClass()
{
	return (class'X2SoldierClass_DefaultChampionClasses'.default.ChampionClasses.Find(m_SoldierClassTemplateName) != INDEX_NONE);
}

function SetMPCharacterTemplate(name TemplateName)
{
	m_MPCharacterTemplateName = TemplateName;
	m_MPCharacterTemplate = class'X2MPCharacterTemplateManager'.static.GetMPCharacterTemplateManager().FindMPCharacterTemplate(m_MPCharacterTemplateName);
}

function name GetMPCharacterTemplateName()
{
	return m_MPCharacterTemplateName;
}

function bool IsMPCharacter()
{
	return (m_MPCharacterTemplateName != '');
}

function X2MPCharacterTemplate GetMPCharacterTemplate()
{
	return m_MPCharacterTemplate;
}

function ClearSoldierClassTemplate()
{
	m_SoldierClassTemplateName = '';
	m_SoldierClassTemplate = none;
}

native function X2SoldierClassTemplate GetSoldierClassTemplate();

function XComGameState_ResistanceFaction GetResistanceFaction()
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;

	if (IsResistanceHero())
	{
		History = `XCOMHISTORY;
		
		FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(FactionRef.ObjectID));
		if (FactionState == none) // The faction has not been assigned yet
		{			
			foreach History.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
			{
				if (FactionState.GetChampionCharacterName() == GetMyTemplateName())
				{
					FactionRef = FactionState.GetReference(); // Save the Faction ref for future access
					break;
				}
			}
		}		
	}

	return FactionState;
}

function RollForTrainingCenterAbilities()
{
	local array<SoldierClassAbilityType> EligibleAbilities;
	local array<int> PossibleRanks;
	local int Idx, RemIdx, NumRanks, RankIdx, AbilityIdx;
	local X2SoldierClassTemplate SoldierClassTemplate;

	// Start Issue #80
	// List of classes to exclude from rolling awc abilities
	// These classes have bAllowAWCAbilities set to true just to participate in the ComInt / AP system
	if (!bRolledForAWCAbility && class'CHHelpers'.default.ClassesExcludedFromAWCRoll.Find(GetSoldierClassTemplateName()) == INDEX_NONE)
	// End Issue #80
	{
		bRolledForAWCAbility = true;
		// Start Issue #62
		EligibleAbilities = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().GetCrossClassAbilities_CH(AbilityTree);
		// End Issue #62

		SoldierClassTemplate = GetSoldierClassTemplate();
		for (Idx = 0; Idx < SoldierClassTemplate.ExcludedAbilities.Length; ++Idx)
		{
			RemIdx = EligibleAbilities.Find('AbilityName', SoldierClassTemplate.ExcludedAbilities[Idx]);
			if (RemIdx != INDEX_NONE)
				EligibleAbilities.Remove(RemIdx, 1);
		}

		if (EligibleAbilities.Length > 0)
		{
			// Set up the array of possible ranks the soldier can purchase abilities
			NumRanks = m_SoldierClassTemplate.GetMaxConfiguredRank();
			for (Idx = 1; Idx < NumRanks; Idx++)
			{
				PossibleRanks.AddItem(Idx);
			}

			for(Idx = 0; Idx < class'XComGameState_HeadquartersXCom'.default.XComHeadquarters_NumAWCAbilities; Idx++)
			{
				RankIdx = `SYNC_RAND(PossibleRanks.Length);
				AbilityIdx = `SYNC_RAND(EligibleAbilities.Length);
				AbilityTree[PossibleRanks[RankIdx]].Abilities.AddItem(EligibleAbilities[AbilityIdx]);
				
				PossibleRanks.Remove(RankIdx, 1); // Remove the rank which was chosen so it won't get picked again
				EligibleAbilities.Remove(AbilityIdx, 1); // Remove the ability which was chosen so it won't get picked again
			}
		}
	}
}

function bool NeedsAWCAbilityPopup()
{
	local int idx;
	
	if (!bSeenAWCAbilityPopup)
	{
		for(idx = 0; idx < AWCAbilities.Length; idx++)
		{
			if(AWCAbilities[idx].bUnlocked)
			{
				return true;
			}
		}
	}

	return false;
}

function array<name> GetAWCAbilityNames()
{
	local array<name> AWCAbilityNames;
	local int idx;

	for (idx = 0; idx < AWCAbilities.Length; idx++)
	{
		if (AWCAbilities[idx].bUnlocked)
		{
			AWCAbilityNames.AddItem(AWCAbilities[idx].AbilityType.AbilityName);
		}
	}

	return AWCAbilityNames;
}

function RollForPsiAbilities()
{
	local SCATProgression PsiAbility;
	local array<SCATProgression> PsiAbilityDeck;
	local int NumRanks, iRank, iBranch, idx;

	NumRanks = m_SoldierClassTemplate.GetMaxConfiguredRank();
		
	for (iRank = 0; iRank < NumRanks; iRank++)
	{
		for (iBranch = 0; iBranch < 2; iBranch++)
		{
			PsiAbility.iRank = iRank;
			PsiAbility.iBranch = iBranch;
			PsiAbilityDeck.AddItem(PsiAbility);
		}
	}

	while (PsiAbilityDeck.Length > 0)
	{
		// Choose an ability randomly from the deck
		idx = `SYNC_RAND(PsiAbilityDeck.Length);
		PsiAbility = PsiAbilityDeck[idx];
		PsiAbilities.AddItem(PsiAbility);
		PsiAbilityDeck.Remove(idx, 1);
	}
}

function array<SoldierClassAbilityType> GetEarnedSoldierAbilities()
{
	local X2SoldierClassTemplate ClassTemplate;
	local array<SoldierClassAbilityType> EarnedAbilities, RankAbilities;
	local SoldierClassAbilityType Ability;
	local int i;

	ClassTemplate = GetSoldierClassTemplate();
	if (ClassTemplate != none)
	{
		for (i = 0; i < m_SoldierProgressionAbilties.Length; ++i)
		{
			if (ClassTemplate.GetMaxConfiguredRank() <= m_SoldierProgressionAbilties[i].iRank)
				continue;
			RankAbilities = AbilityTree[m_SoldierProgressionAbilties[i].iRank].Abilities;
			if (RankAbilities.Length <= m_SoldierProgressionAbilties[i].iBranch)
				continue;
			Ability = RankAbilities[m_SoldierProgressionAbilties[i].iBranch];
			EarnedAbilities.AddItem(Ability);
		}
	}

	for(i = 0; i < AWCAbilities.Length; ++i)
	{
		if(AWCAbilities[i].bUnlocked && m_SoldierRank >= AWCAbilities[i].iRank)
		{
			EarnedAbilities.AddItem(AWCAbilities[i].AbilityType);
		}
	}

	return EarnedAbilities;
}

//  Looks for the Ability inside the unit's earned soldier abilities. If bSearchAllAbilties is true, it will use FindAbility to see if the unit currently has the ability at all.
native function bool HasSoldierAbility(name Ability, optional bool bSearchAllAbilities = true);

function bool MeetsAbilityPrerequisites(name AbilityName)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local int iName;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

	if (AbilityTemplate != none && AbilityTemplate.PrerequisiteAbilities.Length > 0)
	{
		for (iName = 0; iName < AbilityTemplate.PrerequisiteAbilities.Length; iName++)
		{
			AbilityName = AbilityTemplate.PrerequisiteAbilities[iName];

			// Start Issue #128
			if (InStr(AbilityName, "NOT_") == 0)
			{
				if (HasSoldierAbility(name(Repl(AbilityName, "NOT_", ""))))
				{
					return false;
				}
			}
			// End Issue #128
			else if (!HasSoldierAbility(AbilityName)) // if the soldier does not have a prereq ability, return false
			{
				return false;
			}
		}
	}

	return true;
}

function bool HasGrenadePocket()
{
	local name CheckAbility;

	foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksGrenadePocket(CheckAbility)
	{
		if (HasSoldierAbility(CheckAbility))
			return true;
	}
	return false;
}

function bool HasAmmoPocket()
{
	local name CheckAbility;

	foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksAmmoPocket(CheckAbility)
	{
		if (HasSoldierAbility(CheckAbility))
			return true;
	}
	return false;
}

// Check is for squad select UI
function bool HasExtraUtilitySlot()
{
	local XComGameState_Item ItemState;

	// Some units start without utility slots
	if(GetCurrentStat(eStat_UtilityItems) <= 1.0f)
	{
		return false;
	}

	if (HasExtraUtilitySlotFromAbility())
		return true;

	ItemState = GetItemInSlot(eInvSlot_Armor);
	if (ItemState != none)
	{
		return X2ArmorTemplate(ItemState.GetMyTemplate()).bAddsUtilitySlot;
	}
	return false;
}

function bool HasExtraUtilitySlotFromAbility()
{
	local name CheckAbility;

	foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksExtraUtilitySlot(CheckAbility)
	{
		if (HasSoldierAbility(CheckAbility))
			return true;
	}
	return false;
}

function bool HasHeavyWeapon(optional XComGameState CheckGameState)
{
	local XComGameState_Item ItemState;
	local name CheckAbility;
	// Variables for Issue #172
	local XComLWTuple Tuple;
	local bool bOverrideHasHeavyWeapon, bHasHeavyWeapon;

	// Start Issue #172
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideHasHeavyWeapon';
	Tuple.Data.Add(3);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false; //bOverrideHasHeavyWeapon;
	Tuple.Data[1].kind = XComLWTVBool;
	Tuple.Data[1].b = false; //bHasHeavyWeapon;
	Tuple.Data[2].kind = XComLWTVObject;
	Tuple.Data[2].o = CheckGameState;

	`XEVENTMGR.TriggerEvent('OverrideHasHeavyWeapon', Tuple, self);

	bOverrideHasHeavyWeapon = Tuple.Data[0].b;
	bHasHeavyWeapon = Tuple.Data[1].b;

	if (bOverrideHasHeavyWeapon)
	{
		return bHasHeavyWeapon;
	}
	// End Issue Issue #172

	foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksHeavyWeapon(CheckAbility)
	{
		if (HasSoldierAbility(CheckAbility))
			return true;
	}

	ItemState = GetItemInSlot(eInvSlot_Armor, CheckGameState);
	if (ItemState != none)
	{
		return ItemState.AllowsHeavyWeapon();
	}
	return false;
}

function bool BuySoldierProgressionAbility(XComGameState NewGameState, int iAbilityRank, int iAbilityBranch, optional int AbilityPointCost = 0)
{
	local SCATProgression ProgressAbility;
	local bool bSuccess;
	local name AbilityName;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_HeadquartersXCom XComHQ;

	bSuccess = false;

	// Update only if the selection is valid
	AbilityName = GetAbilityName(iAbilityRank, iAbilityBranch);
	if (AbilityName == '')
	{
		return bSuccess;
	}

	//Silently ignore duplicates, returning success.
	foreach m_SoldierProgressionAbilties(ProgressAbility)
	{
		if (ProgressAbility.iBranch == iAbilityBranch && ProgressAbility.iRank == iAbilityRank)
		{
			bSuccess = true;
			return bSuccess;
		}
	}

	// If the unit must pay an Ability Point cost to purchase this ability
	if (AbilityPointCost > 0)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if (AbilityPoints >= AbilityPointCost)
		{
			// If the unit can afford the ability on their own, spend their AP
			AbilityPoints -= AbilityPointCost;
			SpentAbilityPoints += AbilityPointCost; // Save the amount of AP spent
		}
		else if ((AbilityPoints + XComHQ.GetAbilityPoints()) >= AbilityPointCost)
		{
			// If the unit cannot afford ability on their own, spend all remaining AP and draw the difference from the Shared AP pool
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.AddResource(NewGameState, 'AbilityPoint', -(AbilityPointCost - AbilityPoints));
			SpentAbilityPoints += AbilityPoints; // The unit spent all of their remaining AP
			AbilityPoints = 0;
		}
		else
		{
			// Cannot afford ability, return false
			return bSuccess;
		}
		
		`XEVENTMGR.TriggerEvent('AbilityPointsChange', self, , NewGameState);
	}

	ProgressAbility.iRank = iAbilityRank;
	ProgressAbility.iBranch = iAbilityBranch;

	m_SoldierProgressionAbilties.AddItem(ProgressAbility);
	bSuccess = true;

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
	if (AbilityTemplate != none && AbilityTemplate.SoldierAbilityPurchasedFn != none)
		AbilityTemplate.SoldierAbilityPurchasedFn(NewGameState, self);

	return bSuccess;
}

function ResetSoldierRank()
{
	local int i;
	local ECharStatType StatType;
	local X2CharacterTemplate Template;

	Template = GetMyTemplate();
	m_SoldierRank = 0;
	m_SoldierProgressionAbilties.Length = 0;

	for (i = 0; i < eStat_MAX; ++i)
	{
		StatType = ECharStatType(i);
		CharacterStats[i].Type = StatType;
		SetBaseMaxStat( StatType, Template.GetCharacterBaseStat(StatType) );
		SetCurrentStat( StatType, GetMaxStat(StatType) );
	}
}

function ResetSoldierAbilities()
{
	//local int idx;

	m_SoldierProgressionAbilties.Length = 0;
	
	// remove any AWC abilities which were previously unlocked
	//for (idx = 0; idx < AWCAbilities.Length; idx++)
	//{
	//	if (AWCAbilities[idx].bUnlocked)
	//	{
	//		AWCAbilities.Remove(idx, 1);
	//		idx--;
	//	}
	//}
}

function bool HasSpecialBond(XComGameState_Unit BondMate)
{
	local SquadmateScore CurrentScore;

	if(GetSquadmateScore(BondMate.ObjectID, CurrentScore))
	{
		return (CurrentScore.eRelationship == eRelationshipState_SpecialBond);
	}

	return false;
}

// Returns a string of this unit's current location
function string GetLocation()
{
	if (StaffingSlot.ObjectID != 0)
	{
		return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffingSlot.ObjectID)).GetLocationDisplayString();
	}

	return class'XLocalizedData'.default.SoldierStatusAvailable;
}

// Returns staffing slot they are in (none if not staffed)
function XComGameState_StaffSlot GetStaffSlot()
{
	if (StaffingSlot.ObjectID != 0)
	{
		return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffingSlot.ObjectID));
	}

	return none;
}

// Returns headquarters room they are in (none if not in staffing slot)
function XComGameState_HeadquartersRoom GetRoom()
{
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	if (StaffingSlot.ObjectID != 0)
	{
		StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffingSlot.ObjectID));
		return XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(StaffSlotState.Room.ObjectID));
	}
	
	return none;
}

function int GetUnitPointValue()
{
	local XComGameState ParentGameState;
	local XComGameState_Item ItemGameState;
	local int Points;

	if(GetMPCharacterTemplate() != none)
	{
		Points = GetMPCharacterTemplate().Cost;
		
		// only soldiers are allowed to customize their items and therefore affect the cost. otherwise its just the MP character type cost. -tsmith
		if(IsSoldier())
		{
			ParentGameState = GetParentGameState();
			foreach ParentGameState.IterateByClassType(class'XComGameState_Item', ItemGameState)
			{
				if (ItemGameState.OwnerStateObject.ObjectID != ObjectId)
					continue;

				if(ItemIsInMPBaseLoadout(ItemGameState.GetMyTemplateName()))
				{
					if(GetNumItemsByTemplateName(ItemGameState.GetMyTemplateName(), ParentGameState) > 1)
					{
						Points += ItemGameState.GetMyTemplate().MPCost / GetNumItemsByTemplateName(ItemGameState.GetMyTemplateName(), ParentGameState);
					}
					continue;
				}

				Points += ItemGameState.GetMyTemplate().MPCost;
			}
		}
	}
	else
	{
		Points = 0;
	}
	
	return Points;
}

function protected MergeAmmoAsNeeded(XComGameState StartState)
{
	local XComGameState_Item ItemIter, ItemInnerIter;
	local X2WeaponTemplate MergeTemplate;
	local int Idx, InnerIdx, BonusAmmo;

	for (Idx = 0; Idx < InventoryItems.Length; ++Idx)
	{
		ItemIter = XComGameState_Item(StartState.GetGameStateForObjectID(InventoryItems[Idx].ObjectID));
		if (ItemIter != none && !ItemIter.bMergedOut)
		{
			MergeTemplate = X2WeaponTemplate(ItemIter.GetMyTemplate());
			if (MergeTemplate != none && MergeTemplate.bMergeAmmo)
			{
				BonusAmmo = GetBonusWeaponAmmoFromAbilities(ItemIter, StartState);
				ItemIter.MergedItemCount = 1;
				for (InnerIdx = Idx + 1; InnerIdx < InventoryItems.Length; ++InnerIdx)
				{
					ItemInnerIter = XComGameState_Item(StartState.GetGameStateForObjectID(InventoryItems[InnerIdx].ObjectID));
					if (ItemInnerIter != none && ItemInnerIter.GetMyTemplate() == MergeTemplate)
					{
						BonusAmmo += GetBonusWeaponAmmoFromAbilities(ItemInnerIter, StartState);
						ItemInnerIter.bMergedOut = true;
						ItemInnerIter.Ammo = 0;
						ItemIter.MergedItemCount++;
					}
				}
				ItemIter.Ammo = ItemIter.GetClipSize() * ItemIter.MergedItemCount + BonusAmmo;
			}
		}
	}
}

function protected int GetBonusWeaponAmmoFromAbilities(XComGameState_Item ItemState, XComGameState StartState)
{
	local array<SoldierClassAbilityType> SoldierAbilities;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local int Bonus, Idx;

	//  Note: This function is called prior to abilities being generated for the unit, so we only inspect
	//          1) the earned soldier abilities
	//          2) the abilities on the character template

	Bonus = 0;
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	SoldierAbilities = GetEarnedSoldierAbilities();

	for (Idx = 0; Idx < SoldierAbilities.Length; ++Idx)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(SoldierAbilities[Idx].AbilityName);
		if (AbilityTemplate != none && AbilityTemplate.GetBonusWeaponAmmoFn != none)
			Bonus += AbilityTemplate.GetBonusWeaponAmmoFn(self, ItemState);
	}

	CharacterTemplate = GetMyTemplate();
	
	for (Idx = 0; Idx < CharacterTemplate.Abilities.Length; ++Idx)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(CharacterTemplate.Abilities[Idx]);
		if (AbilityTemplate != none && AbilityTemplate.GetBonusWeaponAmmoFn != none)
			Bonus += AbilityTemplate.GetBonusWeaponAmmoFn(self, ItemState);
	}

	return Bonus;
}

function array<AbilitySetupData> GatherUnitAbilitiesForInit(optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local name AbilityName, UnlockName;
	local AbilitySetupData Data, EmptyData;
	local array<AbilitySetupData> arrData;
	local X2AbilityTemplateManager AbilityTemplateMan;
	local X2AbilityTemplate AbilityTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local array<XComGameState_Item> CurrentInventory;
	local XComGameState_Item InventoryItem;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2SoldierAbilityUnlockTemplate AbilityUnlockTemplate;
	local array<SoldierClassAbilityType> EarnedSoldierAbilities;
	local int i, j, OverrideIdx;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local XComGameState_AdventChosen ChosenState;
	local X2TraitTemplate TraitTemplate;
	local X2EventListenerTemplateManager TraitTemplateManager;
	local XComGameState_BattleData BattleDataState;
	local X2SitRepEffect_GrantAbilities SitRepEffect;
	local array<name> GrantedAbilityNames;
	local StateObjectReference ObjectRef;
	local XComGameState_Tech BreakthroughTech;
	local X2TechTemplate TechTemplate;
	local XComGameState_HeadquartersResistance ResHQ;
	local array<StateObjectReference> PolicyCards;
	local StateObjectReference PolicyRef;
	local XComGameState_StrategyCard PolicyState;
	local X2StrategyCardTemplate PolicyTemplate;

	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local int ScanEffect;
	local X2Effect_SpawnUnit SpawnUnitEffect;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	if(StartState != none)
		MergeAmmoAsNeeded(StartState);

	AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	CharacterTemplate = GetMyTemplate();

	//  Gather default abilities if allowed
	if (!CharacterTemplate.bSkipDefaultAbilities)
	{
		foreach class'X2Ability_DefaultAbilitySet'.default.DefaultAbilitySet(AbilityName)
		{
			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
			if (AbilityTemplate != none && 
				(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) && 
				AbilityTemplate.ConditionsEverValidForUnit(self, false))
			{
				Data = EmptyData;
				Data.TemplateName = AbilityName;
				Data.Template = AbilityTemplate;
				arrData.AddItem(Data);
			}
			else if (AbilityTemplate == none)
			{
				`RedScreen("DefaultAbilitySet array specifies unknown ability:" @ AbilityName);
			}
		}
	}
	//  Gather character specific abilities
	foreach CharacterTemplate.Abilities(AbilityName)
	{
		AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
		if( AbilityTemplate != none &&
			(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
		   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
		{
			Data = EmptyData;
			Data.TemplateName = AbilityName;
			Data.Template = AbilityTemplate;
			arrData.AddItem(Data);
		}
		else if (AbilityTemplate == none)
		{
			`RedScreen("Character template" @ CharacterTemplate.DataName @ "specifies unknown ability:" @ AbilityName);
		}
	}
	// If a Chosen, gather abilities from strengths and weakness
	if(IsChosen() && StartState != none)
	{
		ChosenState = GetChosenGameState();

		foreach ChosenState.Strengths(AbilityName)
		{
			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
			if( AbilityTemplate != none &&
				(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
			   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
			{
				Data = EmptyData;
				Data.TemplateName = AbilityName;
				Data.Template = AbilityTemplate;
				arrData.AddItem(Data);
			}
			else if(AbilityTemplate == none)
			{
				`RedScreen("Chosen Strength," @ AbilityName $ ", is not valid. @gameplay @mnauta");
			}
		}

		if(!ChosenState.bIgnoreWeaknesses)
		{
			foreach ChosenState.Weaknesses(AbilityName)
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
				if(AbilityTemplate != none &&
					(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
				   AbilityTemplate.ConditionsEverValidForUnit(self, false))
				{
					Data = EmptyData;
					Data.TemplateName = AbilityName;
					Data.Template = AbilityTemplate;
					arrData.AddItem(Data);
				}
				else if(AbilityTemplate == none)
				{
					`RedScreen("Chosen Weakness," @ AbilityName $ ", is not valid. @gameplay @mnauta");
				}
			}
		}
	}

	// If this is a spawned unit, perform any necessary inventory modifications before item abilities are added
	AbilityContext = XComGameStateContext_Ability(StartState.GetContext());
	if (AbilityContext != None)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
		if (AbilityState != None)
		{
			AbilityTemplate = AbilityState.GetMyTemplate();
			if (AbilityTemplate != None)
			{
				for (ScanEffect = 0; ScanEffect < AbilityTemplate.AbilityTargetEffects.Length; ++ScanEffect)
				{
					SpawnUnitEffect = X2Effect_SpawnUnit(AbilityTemplate.AbilityTargetEffects[ScanEffect]);
					if (SpawnUnitEffect != None)
					{
						SpawnUnitEffect.ModifyItemsPreActivation(GetReference(), StartState);
					}
				}
			}
		}
	}

	//  Gather abilities from the unit's inventory
	CurrentInventory = GetAllInventoryItems(StartState);
	foreach CurrentInventory(InventoryItem)
	{
		if (InventoryItem.bMergedOut || InventoryItem.InventorySlot == eInvSlot_Unknown)
			continue;
		EquipmentTemplate = X2EquipmentTemplate(InventoryItem.GetMyTemplate());
		if (EquipmentTemplate != none)
		{
			foreach EquipmentTemplate.Abilities(AbilityName)
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
				if( AbilityTemplate != none &&
					(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
				   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
				{
					Data = EmptyData;
					Data.TemplateName = AbilityName;
					Data.Template = AbilityTemplate;
					Data.SourceWeaponRef = InventoryItem.GetReference();
					arrData.AddItem(Data);
				}
				else if (AbilityTemplate == none)
				{
					`RedScreen("Equipment template" @ EquipmentTemplate.DataName @ "specifies unknown ability:" @ AbilityName);
				}
			}
		}
		//  Gather abilities from any weapon upgrades
		WeaponUpgradeTemplates = InventoryItem.GetMyWeaponUpgradeTemplates();
		foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
		{
			foreach WeaponUpgradeTemplate.BonusAbilities(AbilityName)
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
				if( AbilityTemplate != none &&
					(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
				   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
				{
					Data = EmptyData;
					Data.TemplateName = AbilityName;
					Data.Template = AbilityTemplate;
					Data.SourceWeaponRef = InventoryItem.GetReference();
					arrData.AddItem(Data);
				}
				else if (AbilityTemplate == none)
				{
					`RedScreen("Weapon upgrade template" @ WeaponUpgradeTemplate.DataName @ "specifies unknown ability:" @ AbilityName);
				}
			}
		}

		// Gather abilities from applicable tech breakthroughs
		// if it's someone the player brought onto the mission
		if ((XComHQ != none) && (GetTeam() == eTeam_XCom) && !bMissionProvided)
		{
			foreach XComHQ.TacticalTechBreakthroughs(ObjectRef)
			{
				BreakthroughTech = XComGameState_Tech(History.GetGameStateForObjectID(ObjectRef.ObjectID));
				TechTemplate = BreakthroughTech.GetMyTemplate();

				if (TechTemplate.BreakthroughCondition != none && TechTemplate.BreakthroughCondition.MeetsCondition(InventoryItem))
				{
					Data = EmptyData;
					Data.TemplateName = TechTemplate.RewardName;
					Data.Template = AbilityTemplateMan.FindAbilityTemplate(Data.TemplateName);
					Data.SourceWeaponRef = InventoryItem.GetReference();
					arrData.AddItem(Data);
				}
			}
		}
	}
	//  Gather soldier class abilities
	EarnedSoldierAbilities = GetEarnedSoldierAbilities();
	for (i = 0; i < EarnedSoldierAbilities.Length; ++i)
	{
		AbilityName = EarnedSoldierAbilities[i].AbilityName;
		AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
		if( AbilityTemplate != none &&
			(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
		   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
		{
			Data = EmptyData;
			Data.TemplateName = AbilityName;
			Data.Template = AbilityTemplate;
			if (EarnedSoldierAbilities[i].ApplyToWeaponSlot != eInvSlot_Unknown)
			{
				foreach CurrentInventory(InventoryItem)
				{
					if (InventoryItem.bMergedOut)
						continue;
					if (InventoryItem.InventorySlot == EarnedSoldierAbilities[i].ApplyToWeaponSlot)
					{
						Data.SourceWeaponRef = InventoryItem.GetReference();

						if (EarnedSoldierAbilities[i].ApplyToWeaponSlot != eInvSlot_Utility)
						{
							//  stop searching as this is the only valid item
							break;
						}
						else
						{
							//  add this item if valid and keep looking for other utility items
							if (InventoryItem.GetWeaponCategory() == EarnedSoldierAbilities[i].UtilityCat)							
							{
								arrData.AddItem(Data);
							}
						}
					}
				}
				//  send an error if it wasn't a utility item (primary/secondary weapons should always exist)
				if (Data.SourceWeaponRef.ObjectID == 0 && EarnedSoldierAbilities[i].ApplyToWeaponSlot != eInvSlot_Utility)
				{
					`RedScreen("Soldier ability" @ AbilityName @ "wants to attach to slot" @ EarnedSoldierAbilities[i].ApplyToWeaponSlot @ "but no weapon was found there.");
				}
			}
			//  add data if it wasn't on a utility item
			if (EarnedSoldierAbilities[i].ApplyToWeaponSlot != eInvSlot_Utility)
			{
				if (AbilityTemplate.bUseLaunchedGrenadeEffects)     //  could potentially add another flag but for now this is all we need it for -jbouscher
				{
					//  populate a version of the ability for every grenade in the inventory
					foreach CurrentInventory(InventoryItem)
					{
						if (InventoryItem.bMergedOut) 
							continue;

						if (X2GrenadeTemplate(InventoryItem.GetMyTemplate()) != none)
						{ 
							Data.SourceAmmoRef = InventoryItem.GetReference();
							arrData.AddItem(Data);
						}
					}
				}
				else
				{
					arrData.AddItem(Data);
				}
			}
		}
	}
	//  Add abilities based on the player state
	if (PlayerState != none && PlayerState.IsAIPlayer())
	{
		foreach class'X2Ability_AlertMechanics'.default.AlertAbilitySet(AbilityName)
		{
			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
			if( AbilityTemplate != none &&
				(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
			   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
			{
				Data = EmptyData;
				Data.TemplateName = AbilityName;
				Data.Template = AbilityTemplate;
				arrData.AddItem(Data);
			}
			else if (AbilityTemplate == none)
			{
				`RedScreen("AlertAbilitySet array specifies unknown ability:" @ AbilityName);
			}
		}
	}
	if (PlayerState != none && PlayerState.SoldierUnlockTemplates.Length > 0)
	{
		foreach PlayerState.SoldierUnlockTemplates(UnlockName)
		{
			AbilityUnlockTemplate = X2SoldierAbilityUnlockTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(UnlockName));
			if (AbilityUnlockTemplate == none)
				continue;
			if (!AbilityUnlockTemplate.UnlockAppliesToUnit(self))
				continue;

			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityUnlockTemplate.AbilityName);
			if( AbilityTemplate != none &&
				(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
			   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
			{
				Data = EmptyData;
				Data.TemplateName = AbilityUnlockTemplate.AbilityName;
				Data.Template = AbilityTemplate;
				arrData.AddItem(Data);
			}
		}
	}

	//	Check for abilities from traits
	TraitTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

	for( i = 0; i < AcquiredTraits.Length; ++i )
	{
		TraitTemplate = X2TraitTemplate(TraitTemplateManager.FindEventListenerTemplate(AcquiredTraits[i]));
		if( TraitTemplate != None && TraitTemplate.Abilities.Length > 0 )
		{
			for( j = 0; j < TraitTemplate.Abilities.Length; ++j )
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(TraitTemplate.Abilities[j]);
				if( AbilityTemplate != none &&
					(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
				   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
				{
					Data = EmptyData;
					Data.TemplateName = AbilityTemplate.DataName;
					Data.Template = AbilityTemplate;
					arrData.AddItem(Data);
				}
			}
		}
	}

	// Gather sitrep granted abilities
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (BattleDataState != none)
	{
		foreach class'X2SitreptemplateManager'.static.IterateEffects(class'X2SitRepEffect_GrantAbilities', SitRepEffect, BattleDataState.ActiveSitReps)
		{
			SitRepEffect.GetAbilitiesToGrant(self, GrantedAbilityNames);
			for (i = 0; i < GrantedAbilityNames.Length; ++i)
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(GrantedAbilityNames[i]);
				if( AbilityTemplate != none &&
					(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
				   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
				{
					Data = EmptyData;
					Data.TemplateName = AbilityTemplate.DataName;
					Data.Template = AbilityTemplate;
					arrData.AddItem(Data);
				}
			}
		}
	}

	// Gather Policy granted abilities
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));
	
	if (ResHQ != none)
	{
		PolicyCards = ResHQ.GetAllPlayedCards( true );

		foreach PolicyCards( PolicyRef )
		{
			if (PolicyRef.ObjectID == 0)
				continue;

			PolicyState = XComGameState_StrategyCard(History.GetGameStateForObjectID(PolicyRef.ObjectID));
			`assert( PolicyState != none );

			PolicyTemplate = PolicyState.GetMyTemplate( );
			if (PolicyTemplate.GetAbilitiesToGrantFn != none)
			{
				GrantedAbilityNames.Length = 0;
				PolicyTemplate.GetAbilitiesToGrantFn( self, GrantedAbilityNames );
				for (i = 0; i < GrantedAbilityNames.Length; ++i)
				{
					AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(GrantedAbilityNames[i]);
					if (AbilityTemplate != none && (!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE))
					{
						Data = EmptyData;
						Data.TemplateName = AbilityTemplate.DataName;
						Data.Template = AbilityTemplate;
						arrData.AddItem(Data);
					}
				}
			}
		}
	}

	//  Check for ability overrides - do it BEFORE adding additional abilities so we don't end up with extra ones we shouldn't have
	for (i = arrData.Length - 1; i >= 0; --i)
	{
		if (arrData[i].Template.OverrideAbilities.Length > 0)
		{
			for (j = 0; j < arrData[i].Template.OverrideAbilities.Length; ++j)
			{
				OverrideIdx = arrData.Find('TemplateName', arrData[i].Template.OverrideAbilities[j]);
				if (OverrideIdx != INDEX_NONE)
				{
					arrData[OverrideIdx].Template = arrData[i].Template;
					arrData[OverrideIdx].TemplateName = arrData[i].TemplateName;
					//  only override the weapon if requested. otherwise, keep the original source weapon for the override ability
					if (arrData[i].Template.bOverrideWeapon)
						arrData[OverrideIdx].SourceWeaponRef = arrData[i].SourceWeaponRef;
				
					arrData.Remove(i, 1);
					break;
				}
			}
		}
	}
	//  Add any additional abilities
	for (i = 0; i < arrData.Length; ++i)
	{
		foreach arrData[i].Template.AdditionalAbilities(AbilityName)
		{
			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
			if( AbilityTemplate != none &&
				(!AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE) &&
			   AbilityTemplate.ConditionsEverValidForUnit(self, false) )
			{
				Data = EmptyData;
				Data.TemplateName = AbilityName;
				Data.Template = AbilityTemplate;
				Data.SourceWeaponRef = arrData[i].SourceWeaponRef;
				arrData.AddItem(Data);
			}			
		}
	}
	//  Check for ability overrides AGAIN - in case the additional abilities want to override something
	for (i = arrData.Length - 1; i >= 0; --i)
	{
		if (arrData[i].Template.OverrideAbilities.Length > 0)
		{
			for (j = 0; j < arrData[i].Template.OverrideAbilities.Length; ++j)
			{
				OverrideIdx = arrData.Find('TemplateName', arrData[i].Template.OverrideAbilities[j]);
				if (OverrideIdx != INDEX_NONE)
				{
					arrData[OverrideIdx].Template = arrData[i].Template;
					arrData[OverrideIdx].TemplateName = arrData[i].TemplateName;
					//  only override the weapon if requested. otherwise, keep the original source weapon for the override ability
					if (arrData[i].Template.bOverrideWeapon)
						arrData[OverrideIdx].SourceWeaponRef = arrData[i].SourceWeaponRef;
				
					arrData.Remove(i, 1);
					break;
				}
			}
		}
	}	

	if (XComHQ != none)
	{
		// remove any abilities whose requirements are not met
		for( i = arrData.Length - 1; i >= 0; --i )
		{
			if( !XComHQ.MeetsAllStrategyRequirements(arrData[i].Template.Requirements) )
			{
				arrData.Remove(i, 1);
			}
		}
	}
	else
	{
		`log("No XComHeadquarters data available to filter unit abilities");
	}

	// for any abilities that specify a default source slot and do not have a source item yet,
	// set that up now
	for( i = 0; i < arrData.Length; ++i )
	{
		if( arrData[i].Template.DefaultSourceItemSlot != eInvSlot_Unknown && arrData[i].SourceWeaponRef.ObjectID <= 0 )
		{
			//	terrible terrible thing to do but it's the easiest at this point.
			//	everyone else has a gun for their primary weapon - templars have it as their secondary.
			if (arrData[i].Template.DefaultSourceItemSlot == eInvSlot_PrimaryWeapon && m_TemplateName == 'TemplarSoldier')
				arrData[i].SourceWeaponRef = GetItemInSlot(eInvSlot_SecondaryWeapon).GetReference();
			else
				arrData[i].SourceWeaponRef = GetItemInSlot(arrData[i].Template.DefaultSourceItemSlot).GetReference();
		}
	}

	if (AbilityState != none)
	{
		AbilityTemplate = AbilityState.GetMyTemplate(); // We already have the AbilityState from earlier in the function
		if (AbilityTemplate != None)
		{
			for (ScanEffect = 0; ScanEffect < AbilityTemplate.AbilityTargetEffects.Length; ++ScanEffect)
			{
				SpawnUnitEffect = X2Effect_SpawnUnit(AbilityTemplate.AbilityTargetEffects[ScanEffect]);
				if (SpawnUnitEffect != None)
				{
					SpawnUnitEffect.ModifyAbilitiesPreActivation(GetReference(), arrData, StartState);
				}
			}
		}
	}

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.FinalizeUnitAbilitiesForInit(self, arrData, StartState, PlayerState, bMultiplayerDisplay);
	}

	return arrData;
}

//IMPORTED FROM XGStrategySoldier
//@TODO - rmcfall - Evaluate and replace?
//=============================================================================================
simulated function string GetFirstName()
{
	return strFirstName;
}

simulated function string GetLastName()
{
	return strLastName;
}

simulated function string GetNickName(optional bool noQuotes = false)
{
	local string OpenQuote, CloseQuote;

	OpenQuote = class'UIUtilities_Text'.default.m_strOpenQuote;
	CloseQuote = class'UIUtilities_Text'.default.m_strCloseQuote;

	if (strNickName == "")
	{
		return "";
	}
	//once Quoted by either '' or "", stop appending quote to the nickname
	else if (!noQuotes && (Left(strNickName, 1) != OpenQuote && Right(strNickName, 1) != CloseQuote) )
	{
		return OpenQuote $ SanitizeQuotes(strNickName)  $CloseQuote;
	}
	else
	{
		return SanitizeQuotes(strNickName);
	}
}

simulated function SetUnitName( string firstName, string lastName, string nickName )
{
	strFirstName = firstName; 
	strLastName = lastName; 
	strNickname = nickName;
}

function string GetFullName()
{
	return GetName(eNameType_Full);
}

function string GetName( ENameType eType )
{
	local bool bFirstNameBlank;
	local string OpenQuote, CloseQuote; 
	local bool bHasName; // Variables for Issue #52

	OpenQuote = class'UIUtilities_Text'.default.m_strOpenQuote;
	CloseQuote = class'UIUtilities_Text'.default.m_strCloseQuote;

	// Start Issue #52: let units with proper names always show them if possible
	bHasName = (strFirstName != "" || strLastName != "");
	
	if (IsSoldier() || IsCivilian() || bHasName) // End issue #52
	{
		if( IsMPCharacter() )
			return GetMPName(eType);

		bFirstNameBlank = (strFirstName == "");
		switch( eType )
		{
		case eNameType_First:
			return strFirstName;
			break;
		case eNameType_Last:
			return strLastName;
			break;
		case eNameType_Nick:
			if( strNickName != "" )
			{			
				if( Left(strNickName, 1) != OpenQuote && Right(strNickName, 1) != CloseQuote )//bsg lmordarski (5/29/2012) - prevent single quotes from being added multiple times
				{
					return OpenQuote $ SanitizeQuotes(strNickName) $CloseQuote;
				}
				else
				{
					return SanitizeQuotes(strNickName);
				}
			}
			else
				return " ";
			break;
		case eNameType_RankFull:
			if( IsSoldier() )
			{
				if( GhostSourceUnit.ObjectID > 0 )
				{
					if( bFirstNameBlank ) return strLastName;
					return strFirstName @ strLastName;
				}
				if( bFirstNameBlank )
				{
					return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strLastName;
				}
				return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strFirstName @ strLastName;
				break;
			}
			// civilians should fall through to full name with no rank
		case eNameType_Full:
			if(bFirstNameBlank)
				return strLastName;
			return strFirstName @ strLastName;
			break;
		case eNameType_Rank:
			if (GhostSourceUnit.ObjectID > 0) return "";
			return `GET_RANK_STR(m_SoldierRank, m_SoldierClassTemplateName);
			break;
		case eNameType_RankLast:
			if (GhostSourceUnit.ObjectID > 0) return strLastName;
			return `GET_RANK_ABBRV(m_SoldierRank, m_SoldierClassTemplateName) @ strLastName;
			break;
		case eNameType_FullNick:
			if(strNickName != "")
			{
				if (GhostSourceUnit.ObjectID > 0)
				{
					if( Left(strNickName, 1) != OpenQuote && Right(strNickName, 1) != CloseQuote )
					{
						if( bFirstNameBlank )
						{
							return OpenQuote $ SanitizeQuotes(strNickName) $CloseQuote @ strLastName;
						}
						return strFirstName @ OpenQuote $ SanitizeQuotes(strNickName) $CloseQuote @ strLastName;
					}
					else
					{

						if( bFirstNameBlank )
						{
							return SanitizeQuotes(strNickName)  @ strLastName;
						}
						return strFirstName @ SanitizeQuotes(strNickName)  @ strLastName;
					}
				}
				if( Left(strNickName, 1) != OpenQuote && Right(strNickName, 1) != CloseQuote )
				{
					if( bFirstNameBlank )
					{
						return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ OpenQuote $ SanitizeQuotes(strNickName)  $CloseQuote @ strLastName;
					}
					return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strFirstName @ OpenQuote $ SanitizeQuotes(strNickName)  $CloseQuote @ strLastName;
				}
				else
				{
					if( bFirstNameBlank )
					{
						return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ SanitizeQuotes(strNickName)  @ strLastName;
					}
					return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strFirstName @ SanitizeQuotes(strNickName)  @ strLastName;
				}
			}
			else
			{
				if (GhostSourceUnit.ObjectID > 0)
				{
					if (bFirstNameBlank) return strLastName;
					return strFirstName @ strLastName;
				}
				if(bFirstNameBlank)
					return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strLastName;
				return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strFirstName @ strLastName;
			}
				
			break;
		}

		return "???";
	}
	return GetMyTemplate().strCharacterName;
}

function string SummaryString()
{
	return "[" $ GetName(eNameType_First) $ ", " $ GetVisualizer() $ ", " $ ObjectID $ "]";
}

// Aliens can have human names in MP
function string GetMPName( ENameType eType )
{
	local string OpenQuote, CloseQuote;

	OpenQuote = class'UIUtilities_Text'.default.m_strOpenQuote;
	CloseQuote = class'UIUtilities_Text'.default.m_strCloseQuote;

	switch( eType )
	{
	case eNameType_First:
		return strFirstName;
		break;
	case eNameType_Last:
		return strLastName;
		break;
	case eNameType_Nick:
		if( strNickName != "" )
		{			
			if( Left(strNickName, 1) != OpenQuote && Right(strNickName, 1) != CloseQuote )//bsg lmordarski (5/29/2012) - prevent single quotes from being added multiple times
			{
				return OpenQuote $ SanitizeQuotes(strNickName) $CloseQuote;
			}
			else
			{
				return SanitizeQuotes(strNickName);
			}
		}
		else
			return " ";
		break;
	case eNameType_Full:
		return strFirstName @ strLastName;
		break;
	case eNameType_Rank:
		return `GET_RANK_STR(m_SoldierRank, m_MPCharacterTemplateName);
		break;
	case eNameType_RankLast:
		return `GET_RANK_ABBRV(m_SoldierRank, m_MPCharacterTemplateName) @ strLastName;
		break;
	case eNameType_RankFull:
		return `GET_RANK_ABBRV( m_SoldierRank, m_MPCharacterTemplateName ) @ strFirstName @ strLastName;
		break;
	case eNameType_FullNick:
		if(IsSoldier())
		{
			if(strNickName != "")
				return `GET_RANK_ABBRV( m_SoldierRank, m_MPCharacterTemplateName ) @ strFirstName @ OpenQuote $ SanitizeQuotes(strNickName) $CloseQuote @ strLastName;
			else
				return `GET_RANK_ABBRV( m_SoldierRank, m_MPCharacterTemplateName ) @ strFirstName @ strLastName;
		}
		else
		{
			if(strNickName != "")
				return strFirstName @ OpenQuote $ SanitizeQuotes(strNickName) $CloseQuote @ strLastName;
			else
				return strFirstName @ strLastName;
		}
		
		break;
	}
}

function string SanitizeQuotes(string DisplayLabel)
{
	local string SanitizedLabel; 

	SanitizedLabel = DisplayLabel; 

	//If we're in CHT, check to see if we spot single quotes in the name. If so, strip them out. 
	if( GetLanguage() == "CHT" )
	{
		if( Left(SanitizedLabel, 1) == "'" )
		{
			SanitizedLabel = Right(SanitizedLabel, Len(SanitizedLabel) - 1);
		}
		if( Right(SanitizedLabel, 1) == "'" )
		{
			SanitizedLabel = Left(SanitizedLabel, Len(SanitizedLabel) - 1);
		}
	}
	return SanitizedLabel; 
}

function string GetBackground()
{
	return strBackground;
}

function SetBackground(string NewBackground)
{
	strBackground = NewBackground;
}

function bool HasBackground()
{
	return strBackground != "";
}

function GenerateBackground(optional string ForceBackgroundStory, optional name BioCountryName)
{
	local XGParamTag LocTag;
	local TDateTime Birthday;
	local X2CharacterTemplate CharTemplate;
	local X2CountryTemplate CountryTemplate;
	local string BackgroundStory;

	if(BioCountryName != '')
	{
		CountryTemplate = X2CountryTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(BioCountryName));
	}
	else
	{
		CountryTemplate = GetCountryTemplate();
	}

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));	
	
	LocTag.StrValue0 = CountryTemplate.DisplayName;
	strBackground = `XEXPAND.ExpandString(class'XLocalizedData'.default.CountryBackground);
	strBackground $= "\n";

	Birthday.m_iMonth = Rand(12) + 1;
	Birthday.m_iDay = (Birthday.m_iMonth == 2 ? Rand(27) : Rand(30)) + 1;
	Birthday.m_iYear = class'X2StrategyGameRulesetDataStructures'.default.START_YEAR - int(RandRange(25, 35));
	LocTag.StrValue0 = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Birthday);

	strBackground $= `XEXPAND.ExpandString(class'XLocalizedData'.default.DateOfBirthBackground);

	CharTemplate = GetMyTemplate();
	if(ForceBackgroundStory == "")
	{
		if(kAppearance.iGender == eGender_Female)
		{
			if (CharTemplate.strCharacterBackgroundFemale.Length > 0)
				BackgroundStory = CharTemplate.strCharacterBackgroundFemale[`SYNC_RAND(CharTemplate.strCharacterBackgroundFemale.Length)];
		}
		else
		{
			if (CharTemplate.strCharacterBackgroundMale.Length > 0)
				BackgroundStory = CharTemplate.strCharacterBackgroundMale[`SYNC_RAND(CharTemplate.strCharacterBackgroundMale.Length)];
		}
	}
	else
	{
		BackgroundStory = ForceBackgroundStory;
	}	

	if(BackgroundStory != "")
	{	
		LocTag.StrValue0 = CountryTemplate.DisplayNameWithArticleLower;
		LocTag.StrValue1 = GetFirstName();
		strBackground $= "\n\n" $ `XEXPAND.ExpandString(BackgroundStory);
	}
}

function SetTAppearance(const out TAppearance NewAppearance)
{
	kAppearance = NewAppearance;
}

function SetHQLocation(ESoldierLocation NewLocation)
{
	HQLocation = NewLocation;
}

function ESoldierLocation GetHQLocation()
{
	return HQLocation;
}

function int RollStat( int iLow, int iHigh, int iMultiple )
{
	local int iSpread, iNewStat; 

	iSpread = iHigh - iLow;

	iNewStat = iLow + `SYNC_RAND( iSpread/iMultiple + 1 ) * iMultiple;

	if( iNewStat == iHigh && `SYNC_RAND(2) == 0 )
		iNewStat += iMultiple;

	return iNewStat;
}

function bool ModifySkillValue(int iDelta)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int OldValue, ThresholdValue;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	OldValue = SkillValue;

	if(XComHQ.bCrunchTime)
	{
		iDelta = Round(float(iDelta) * 1.25);
	}

	SkillValue += iDelta;

	if(GetMyTemplate().SkillLevelThresholds.Length > 0)
	{
		ThresholdValue = GetMyTemplate().SkillLevelThresholds[GetSkillLevel()];

		if(OldValue < ThresholdValue && SkillValue >= ThresholdValue)
		{
			return true;
		}
	}

	return false;
}

function SetSkillLevel(int iSkill)
{
	if(iSkill >= GetMyTemplate().SkillLevelThresholds.Length)
	{
		iSkill = GetMyTemplate().SkillLevelThresholds.Length - 1;
	}

	SkillValue = GetMyTemplate().SkillLevelThresholds[iSkill];
}

function int GetSkillLevel(optional bool bIncludeSkillBonus = false)
{
	local int idx, SkillLevel;

	SkillLevel = 0;

	if (GetMyTemplate().SkillLevelThresholds.Length > 0)
	{
		for (idx = 0; idx < GetMyTemplate().SkillLevelThresholds.Length; idx++)
		{
			if (SkillValue >= GetMyTemplate().SkillLevelThresholds[idx])
			{
				SkillLevel = idx;
			}
		}

		if (bIncludeSkillBonus) //check whether to include the workshop / lab skill bonuses
		{
			SkillLevel += SkillLevelBonus;			
		}
	}

	return SkillLevel;
}

function int GetSkillLostByReassignment()
{
	local int SkillLost;

	SkillLost = 0;

	if (GetRoom() != none)
	{
		if ((IsEngineer() && GetRoom().GetFacility().GetMyTemplateName() == 'Workshop') ||
			(IsScientist() && GetRoom().GetFacility().GetMyTemplateName() == 'Laboratory'))
		{
			//Staffers in lab or shop double their contribution, so the skill lost is equal to 1x their skill if they move
			SkillLost = GetSkillLevel();
		}
	}

	return SkillLost;
}

function bool IsAtMaxSkillLevel()
{
	if(GetMyTemplate().SkillLevelThresholds.Length > 0)
	{
		if(GetSkillLevel() == (GetMyTemplate().SkillLevelThresholds.Length-1))
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	return true;
}

// Staffing gameplay
function bool CanBeStaffed()
{
	return(IsAlive() && !IsInjured() && GetMyTemplate().bStaffingAllowed);
}

// Staffing visually
function bool CanAppearInBase()
{
	return(IsAlive() && !IsOnCovertAction() && GetMyTemplate().bAppearInBase);
}

function RandomizeStats()
{
	local int iMultiple;

	`XEVENTMGR.TriggerEvent('UnitRandomizedStats', self, self); // issue #185 - fires event containing unitstate to indicate new unit has been created, due to where this event is used commonly
	if( `GAMECORE.IsOptionEnabled( eGO_RandomRookieStats ) )
	{
		iMultiple = 5;
		SetBaseMaxStat( eStat_Offense, RollStat( class'XGTacticalGameCore'.default.LOW_AIM, class'XGTacticalGameCore'.default.HIGH_AIM, iMultiple ) );

		iMultiple = 1;
		SetBaseMaxStat( eStat_Mobility, RollStat( class'XGTacticalGameCore'.default.LOW_MOBILITY, class'XGTacticalGameCore'.default.HIGH_MOBILITY, iMultiple ) );

		iMultiple = 2;
		SetBaseMaxStat( eStat_Will, RollStat( class'XGTacticalGameCore'.default.LOW_WILL, class'XGTacticalGameCore'.default.HIGH_WILL, iMultiple ) );
	}
}

function bool HasPsiGift()
{
	return bHasPsiGift;
}

function ESoldierStatus GetStatus()
{
	return HQStatus;
}

function SetStatus(ESoldierStatus NewStatus)
{
	HQStatus = NewStatus;
}

function string GetStatusString()
{
	local string FormattedStatus, Status, TimeLabel;
	local int TimeValue;

	GetStatusStringsSeparate(Status, TimeLabel, TimeValue);

	FormattedStatus = Status @ "(" $ string(TimeValue) @ TimeLabel $")";

	return FormattedStatus;
}

function GetStatusStringsSeparate(out string Status, out string TimeLabel, out int TimeValue)
{
	local bool bProjectExists;
	local int iHours, iDays;
	
	if( IsInjured() )
	{
		Status = GetWoundStatus(iHours);
		if (Status != "")
			bProjectExists = true;
	}
	else if (IsOnCovertAction())
	{
		Status = GetCovertActionStatus(iHours);
		if (Status != "")
			bProjectExists = true;
	}
	else if (IsTraining() || IsPsiTraining() || IsPsiAbilityTraining())
	{
		Status = GetTrainingStatus(iHours);
		if (Status != "")
			bProjectExists = true;
	}
	else if( IsDead() )
	{
		Status = "KIA";
	}
	else
	{
		Status = "";
	}
	
	if (bProjectExists)
	{
		iDays = iHours / 24;

		if (iHours % 24 > 0)
		{
			iDays += 1;
		}

		TimeValue = iDays;
		TimeLabel = class'UIUtilities_Text'.static.GetDaysString(iDays);
	}
}
//-------------------------------------------------------------------------
// Returns a UI state (color) that matches the soldier's status
function int GetStatusUIState()
{
	switch ( GetStatus() )
	{
	case eStatus_Active:
		if(IsDead())
			return eUIState_Bad;
		else 
			return eUIState_Good;
	case eStatus_Healing:
		return eUIState_Bad;
	case eStatus_OnMission:
		return eUIState_Highlight;
	case eStatus_PsiTesting:
	case eStatus_Training:
	case eStatus_CovertAction:
		return eUIState_Disabled;
	}

	return eUIState_Normal;
}

// For mission summary UI
simulated event bool WasInjuredOnMission()
{
	return (GetCurrentStat(eStat_HP) > 0 && LowestHP < HighestHP);
}

simulated function bool IsInjured()
{
	return GetCurrentStat(eStat_HP) > 0 && GetCurrentStat(eStat_HP) < GetMaxStat(eStat_HP);
}

// Is the Soldier at the least-serious level of injury, given their remaining health percentage
simulated function bool IsLightlyInjured()
{
	local array<int> WoundStates;
	local float HPPercentage;
	
	if (`SecondWaveEnabled('BetaStrike') )
	{
		WoundStates = class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthWoundStates[`StrategyDifficultySetting].WoundStateHealthPercents;
	}
	else
	{
		WoundStates = class'X2StrategyGameRulesetDataStructures'.default.WoundStates[`StrategyDifficultySetting].WoundStateHealthPercents;
	}

	HPPercentage = 100.0f * GetCurrentStat(eStat_HP) / GetMaxStat(eStat_HP);

	// Check if the current HP amount is at the first wound state, the least severe
	return (HPPercentage >= WoundStates[0]);
}

// Is the Soldier at the most-serious level of injury, given their remaining health percentage
simulated function bool IsGravelyInjured()
{
	local array<int> WoundStates;
	local float HPPercentage;
	local int idx;

	if( `SecondWaveEnabled('BetaStrike' ) )
	{
		WoundStates = class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthWoundStates[`StrategyDifficultySetting].WoundStateHealthPercents;
	}
	else
	{
		WoundStates = class'X2StrategyGameRulesetDataStructures'.default.WoundStates[`StrategyDifficultySetting].WoundStateHealthPercents;
	}
	
	HPPercentage = 100.0f * GetCurrentStat(eStat_HP) / GetMaxStat(eStat_HP);

	for (idx = 0; idx < WoundStates.Length; idx++)
	{
		if (HPPercentage >= WoundStates[idx] || idx == (WoundStates.Length - 1))
		{
			break;
		}
	}
	
	// If the loop broke at the highest wound state, return true
	return (idx == (WoundStates.Length - 1));
}

//This will update the character's appearance with a random scar. Only call if this state object is already part of a game state transaction.
simulated function GainRandomScar()
{
	local X2BodyPartTemplateManager PartTemplateManager;
	local X2SimpleBodyPartFilter BodyPartFilter;
	local X2BodyPartTemplate SelectedScar;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	BodyPartFilter = `XCOMGAME.SharedBodyPartFilter;
	SelectedScar = PartTemplateManager.GetRandomUberTemplate("Scars", BodyPartFilter, BodyPartFilter.FilterAny);

	//Update our appearance
	kAppearance.nmScars = SelectedScar.DataName;
}

simulated function bool IsActive(optional bool bAllowPsiTraining)
{
	// Soldiers can sometimes perform actions (like going on missions) while training psi abilities
	if (bAllowPsiTraining && IsPsiAbilityTraining())
	{
		return true;
	}

	return (!IsInjured() && (GetMentalState() != eMentalState_Shaken) && GetStatus() == eStatus_Active);
}

simulated function bool IsOnCovertAction()
{
	return (GetStatus() == eStatus_CovertAction);
}

simulated function bool IsTraining()
{
	return (GetStatus() == eStatus_Training);
}

simulated function bool IsPsiTraining()
{
	return (GetStatus() == eStatus_PsiTesting);
}

simulated function bool IsPsiAbilityTraining()
{
	return (GetStatus() == eStatus_PsiTraining);
}

simulated function bool IgnoresInjuries()
{
	local X2SoldierClassTemplate ClassTemplate;

	ClassTemplate = GetSoldierClassTemplate();
	if (ClassTemplate != none)
	{
		return ClassTemplate.bIgnoreInjuries;
	}

	return false;
}

simulated function bool BelowReadyWillState()
{
	return (GetMentalState() < eMentalState_Ready);
}

simulated function bool NeedsWillRecovery()
{
	return (GetCurrentStat(eStat_Will) < GetMaxStat(eStat_Will));
}

simulated function bool CanGoOnMission(optional bool bAllowWoundedSoldiers = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bHealthy, bShaken, bHasInjuries, bIgnoreInjuries;

	if (!IsSoldier() || !IsAlive())
	{
		return false; // Dead units and non-soldiers can't go on missions
	}

	bHealthy = IsActive(true);
	if (bHealthy)
	{
		return true;
	}
	else
	{
		bShaken = (GetMentalState() == eMentalState_Shaken);
		bHasInjuries = (IsInjured() || bShaken);
		bIgnoreInjuries = (bAllowWoundedSoldiers || IgnoresInjuries() || bRecoveryBoosted);

		// If the Resistance Order to allow lightly wounded soldiers is active, flag a lightly wounded non-shaken unit as able to ignore injuries
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (!bShaken && XComHQ.bAllowLightlyWoundedOnMissions && IsLightlyInjured())
		{
			bIgnoreInjuries = true;
		}

		return (bHasInjuries && bIgnoreInjuries);
	}
}

function name GetCountry()
{
	return nmCountry;
}

function X2CountryTemplate GetCountryTemplate()
{
	return X2CountryTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(nmCountry));
}

function bool HasHealingProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', HealProject)
	{
		if(HealProject.ProjectFocus == self.GetReference())
		{
			return true;
		}
	}

	return false;
}

// For infirmary -- low->high in severity
function int GetWoundState(out int iHours, optional bool bPausedProject = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local array<int> WoundStates;
	local float HPPercentage;
	local int idx;
	
	History = `XCOMHISTORY;

	if( `SecondWaveEnabled('BetaStrike' ) )
	{
		WoundStates = class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthWoundStates[`StrategyDifficultySetting].WoundStateHealthPercents;
	}
	else
	{
		WoundStates = class'X2StrategyGameRulesetDataStructures'.default.WoundStates[`StrategyDifficultySetting].WoundStateHealthPercents;
	}
	
	// Find how many hours are remaining on this soldiers heal project
	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', HealProject)
	{
		if (HealProject.ProjectFocus == self.GetReference())
		{
			if (bPausedProject)
				iHours = HealProject.GetProjectedNumHoursRemaining();
			else
				iHours = HealProject.GetCurrentNumHoursRemaining();
		}
	}

	// Then grab the wound state based on their current health
	HPPercentage = 100.0f * GetCurrentStat(eStat_HP) / GetMaxStat(eStat_HP);

	for (idx = 0; idx < WoundStates.Length; idx++)
	{
		if (HPPercentage >= WoundStates[idx] || idx == (WoundStates.Length - 1))
		{
			return idx;
		}
	}

	// Soldier isn't injured
	return -1;
}

function string GetWoundStatus(optional out int iHours, optional bool bIgnorePaused = false)
{
	local array<string> WoundStatusStrings;
	local int idx;
	
	WoundStatusStrings = class'X2StrategyGameRulesetDataStructures'.default.WoundStatusStrings;
	idx = GetWoundState(iHours);

	if (iHours == -1) // Heal project is paused
	{
		idx = GetWoundState(iHours, true); // Calculate the projected hours instead of actual
		if (bIgnorePaused)
			return WoundStatusStrings[idx]; // If we are ignoring the paused status, return the normal heal status string
		else
			return GetMyTemplate().strCharacterHealingPaused; // Otherwise return special paused heal string
	}
	else if (idx >= 0)
		return WoundStatusStrings[idx];
	else
		return ""; // Soldier isn't injured
}

function string GetTrainingStatus(optional out int iHours)
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectTrainRookie TrainProject;
	local XComGameState_HeadquartersProjectRespecSoldier RespecProject;
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;
	local XComGameState_HeadquartersProjectRemoveTraits TraitProject;
	local XComGameState_HeadquartersProjectBondSoldiers BondProject;

	History = `XCOMHISTORY;

	if (StaffingSlot.ObjectID != 0)
	{
		StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffingSlot.ObjectID));
		
		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectTrainRookie', TrainProject)
		{
			if (TrainProject.ProjectFocus == self.GetReference())
			{
				iHours = TrainProject.GetCurrentNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}

		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectRespecSoldier', RespecProject)
		{
			if (RespecProject.ProjectFocus == self.GetReference())
			{
				iHours = RespecProject.GetCurrentNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}

		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectPsiTraining', PsiProject)
		{
			if (PsiProject.ProjectFocus == self.GetReference())
			{
				iHours = PsiProject.GetCurrentNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}

		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectRemoveTraits', TraitProject)
		{
			if (TraitProject.ProjectFocus == self.GetReference() || TraitProject.AuxilaryReference == self.GetReference())
			{
				iHours = TraitProject.GetCurrentNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}

		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectBondSoldiers', BondProject)
		{
			if(BondProject.ProjectFocus == self.GetReference() || BondProject.AuxilaryReference == self.GetReference())
			{
				iHours = BondProject.GetCurrentNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}
	}

	// Soldier isn't training
	return "";
}

function string GetCovertActionStatus(optional out int iHours)
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_CovertAction ActionState;

	History = `XCOMHISTORY;
		
	if (StaffingSlot.ObjectID != 0)
	{
		StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffingSlot.ObjectID));

		foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
		{
			if (ActionState.StaffSlots.Find('StaffSlotRef', StaffingSlot) != INDEX_NONE)
			{
				iHours = ActionState.GetNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}
	}

	// Soldier isn't on a covert action
	return "";
}

function string GetCombatIntelligenceLabel()
{
	return class'X2StrategyGameRulesetDataStructures'.default.ComIntLabels[ComInt];
}

function SetCountry( name nmNewCountry )
{
	local XGUnit UnitVisualizer;
	local XComHumanPawn HumanPawn;

	nmCountry = nmNewCountry;
	kAppearance.nmFlag = nmNewCountry; //iFlag needs to be in sync

	//Update the appearance stored in our visualizer if we have one
	UnitVisualizer = XGUnit(GetVisualizer());	
	if( UnitVisualizer != none && UnitVisualizer.GetPawn() != none )
	{
		HumanPawn = XComHumanPawn(UnitVisualizer.GetPawn());
		if( HumanPawn != none )
		{
			HumanPawn.SetAppearance(kAppearance, false);
		}
	}
}

native function ECoverType GetCoverTypeFromLocation();

native function bool IsInWorldEffectTile(const out name WorldEffectName);

function bool CanBleedOut()
{
	local bool CanBleedOut, EffectsAllowBleedOut;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	CanBleedOut = GetMyTemplate().bCanBeCriticallyWounded && `TACTICALRULES != none && !IsBleedingOut();

	EffectsAllowBleedOut = true;
	if( CanBleedOut )
	{
		// Check with effects on the template to see if it can bleed out
		foreach AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if( EffectState != none )
			{
				EffectTemplate = EffectState.GetX2Effect();
				EffectsAllowBleedOut = EffectTemplate.DoesEffectAllowUnitToBleedOut(self);

				if( !EffectsAllowBleedOut )
				{
					break;
				}
			}
		}
	}

	return CanBleedOut && EffectsAllowBleedOut;
}

function bool ShouldBleedOut(int OverkillDamage)
{
	local int Chance;
	local int Roll, RollOutOf;
	local XComGameState_HeadquartersXCom XComHQ;
	// Start Issue #91:
	// Add Tuple Object to pass values through the event trigger
	local XComLWTuple Tuple;
	// End Issue #91

	`log("ShouldBleedOut called for" @ ToString(),,'XCom_HitRolls');
	if (CanBleedOut())
	{
		if(`CHEATMGR != none && `CHEATMGR.bForceCriticalWound)
		{
			return true;
		}
		else
		{
			Chance = class'X2StatusEffects'.static.GetBleedOutChance(self, OverkillDamage);
			RollOutOf = class'X2StatusEffects'.default.BLEEDOUT_ROLL;

			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
			if (XComHQ != none && XComHQ.SoldierUnlockTemplates.Find('StayWithMeUnlock') != INDEX_NONE)
			{
				`log("Applying bonus chance for StayWithMeUnlock...",,'XCom_HitRolls');
				RollOutOf = class'X2StatusEffects'.default.BLEEDOUT_BONUS_ROLL;
			}

			// Start Issue #91:
			// Set up a Tuple to pass the Bleedout chance, roll max, and overkill damage
			Tuple = new class'XComLWTuple';
			Tuple.Id = 'OverrideBleedoutChance';
			Tuple.Data.Add(3);
			Tuple.Data[0].kind = XComLWTVInt;
			Tuple.Data[0].i = Chance;
			Tuple.Data[1].kind = XComLWTVInt;
			Tuple.Data[1].i = RollOutOf;
			Tuple.Data[2].kind = XComLWTVInt;
			Tuple.Data[2].i = OverkillDamage;

			// To use, register the XComGameState_Effect for the event, pull in the Tuple, and manipulate the standard Bleedout Chance Roll
			// threshold in Tuple.Data[0].i and/or the Bleedout Chance Roll Max in Tuple.Data[1].i, as desired.
			// NOTE: OverkillDamage isn't actually used as part of the Bleedout Chance calculation or rolls by default, though the value is
			// passed from the TakeDamage event and can be used to modify the Bleedout Chance accordingly, if desired.
			`XEVENTMGR.TriggerEvent('OverrideBleedoutChance', Tuple, self);

			// Read back in the new values for Chance and RollOutOf
			Chance = Tuple.Data[0].i;
			RollOutOf = Tuple.Data[1].i;
			// End Issue #91

			Roll = `SYNC_RAND(RollOutOf);
			`log("Chance to bleed out:" @ Chance @ "Rolled:" @ Roll,,'XCom_HitRolls');
			`log("Bleeding out!", Roll <= Chance, 'XCom_HitRolls');
			`log("Dying!", Roll > Chance, 'XCom_HitRolls');
			return Roll <= Chance;
		}
	}
	`log("Unit cannot possibly bleed out. Dying.",,'XCom_HitRolls');
	return false;
}

protected function bool ApplyBleedingOut(XComGameState NewGameState)
{
	local EffectAppliedData ApplyData;
	local X2Effect BleedOutEffect;
	local string LogMsg;

	if (NewGameState != none)
	{
		BleedOutEffect = class'X2StatusEffects'.static.CreateBleedingOutStatusEffect();
		ApplyData.PlayerStateObjectRef = ControllingPlayer;
		ApplyData.SourceStateObjectRef = GetReference();
		ApplyData.TargetStateObjectRef = GetReference();
		ApplyData.EffectRef.LookupType = TELT_BleedOutEffect;
		if (BleedOutEffect.ApplyEffect(ApplyData, self, NewGameState) == 'AA_Success')
		{
			LogMsg = class'XLocalizedData'.default.BleedingOutLogMsg;
			LogMsg = repl(LogMsg, "#Unit", GetName(eNameType_RankFull));
			`COMBATLOG(LogMsg);
			return true;
		}
	}
	return false;
}

simulated function int GetBleedingOutTurnsRemaining()
{
	local XComGameState_Effect BleedOutEffect;

	if( IsBleedingOut() )
	{
		BleedOutEffect = GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
		if( BleedOutEffect != none )
		{
			return BleedOutEffect.iTurnsRemaining;
		}
	}
	return 0;
}

function bool IsLootable(XComGameState NewGameState)
{
	local bool EffectsAllowLooting;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	EffectsAllowLooting = true;
	// Check with effects on the template to see if it can bleed out
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if( EffectState != none )
		{
			EffectTemplate = EffectState.GetX2Effect();
			EffectsAllowLooting = EffectTemplate.DoesEffectAllowUnitToBeLooted(NewGameState, self);

			if( !EffectsAllowLooting )
			{
				break;
			}
		}
	}

	return EffectsAllowLooting;
}

function int GetAIPlayerDataID(bool bIgnorePlayerID=false)
{
	local XComGameState_AIPlayerData AIData;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_AIPlayerData', AIData)
	{
		if (bIgnorePlayerID || AIData.m_iPlayerObjectID == ControllingPlayer.ObjectID)
			return AIData.ObjectID;
	}
	return 0;
}

function int GetAIUnitDataID()
{
	local XComGameState_AIUnitData AIData;
	local XComGameStateHistory History;


	if (CachedUnitDataStateObjectId != INDEX_NONE)
		return CachedUnitDataStateObjectID;

	History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_AIUnitData', AIData)
	{
		if (AIData.m_iUnitObjectID == ObjectID)
		{
			CachedUnitDataStateObjectId = AIData.ObjectID;
			return AIData.ObjectID;
		}
	}
	return -1;
}

function AddRupturedValue(const int Rupture)
{
	if (Rupture > Ruptured)
		Ruptured = Rupture;
}

function int GetRupturedValue()
{
	return Ruptured;
}

function AddShreddedValue(const int Shred)
{
	Shredded += Shred;
}

function TakeEffectDamage( const X2Effect DmgEffect, const int DamageAmount, const int MitigationAmount, const int ShredAmount, const out EffectAppliedData EffectData,
						   XComGameState NewGameState, optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false,
						   optional array<Name> AppliedDamageTypes, optional array<DamageModifierInfo> SpecialDamageMessages)
{
	if( AppliedDamageTypes.Length == 0 )
	{
		AppliedDamageTypes = DmgEffect.DamageTypes;
	}
	TakeDamage(NewGameState, DamageAmount, MitigationAmount, ShredAmount, EffectData, DmgEffect, EffectData.SourceStateObjectRef, DmgEffect.IsExplosiveDamage(),
			   AppliedDamageTypes, bForceBleedOut, bAllowBleedout, bIgnoreShields, SpecialDamageMessages);
}

event TakeDamage( XComGameState NewGameState, const int DamageAmount, const int MitigationAmount, const int ShredAmount, optional EffectAppliedData EffectData, 
						optional Object CauseOfDeath, optional StateObjectReference DamageSource, optional bool bExplosiveDamage = false, optional array<name> DamageTypes,
						optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false, optional array<DamageModifierInfo> SpecialDamageMessages)
{
	local int ShieldHP, DamageAmountBeforeArmor, DamageAmountBeforeArmorMinusShield, 
		      PostShield_MitigationAmount, PostShield_DamageAmount, PostShield_ShredAmount, 
		      DamageAbsorbedByShield;
	local DamageResult DmgResult;
	local string LogMsg;
	local Object ThisObj;
	local X2EventManager EventManager;
	local int OverkillDamage;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent PersistentEffect;
	local UnitValue DamageThisTurnValue;
	local XComGameState_Unit DamageSourceUnit;
	local name PreCheckName;
	local X2Effect_ApplyWeaponDamage DamageEffect;
    
	// Variable for Issue #202
	local XComLWTuple KilledByExplosionTuple;

	//  Cosmetic units should not take damage
	if (GetMyTemplate( ).bIsCosmetic)
		return;

	// already dead units should not take additional damage
	if (IsDead( ))
	{
		return;
	}

	if (`CHEATMGR != none && `CHEATMGR.bInvincible == true && GetTeam( ) == eTeam_XCom)
	{
		LogMsg = class'XLocalizedData'.default.UnitInvincibleLogMsg;
		LogMsg = repl( LogMsg, "#Unit", GetName( eNameType_RankFull ) );
		`COMBATLOG(LogMsg);
		return;
	}
	if (`CHEATMGR != none && `CHEATMGR.bAlwaysBleedOut)
	{
		bForceBleedOut = true;
	}

	History = `XCOMHISTORY;

	// Loop over persistent effects to see if one forces the unit to bleed out
	if (!bForceBleedOut && CanBleedOut())
	{
		foreach AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(NewGameState.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState == none)
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState == none || EffectState.bRemoved)
				continue;
			PersistentEffect = EffectState.GetX2Effect();
			if (PersistentEffect == none)
				continue;
			if (PersistentEffect.ForcesBleedout(NewGameState, self, EffectState))
			{
				bForceBleedOut = true;
				break;
			}
		}

		if (!bForceBleedOut)
		{
			DamageSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(DamageSource.ObjectID));

			if (DamageSourceUnit != none)
			{
				foreach DamageSourceUnit.AffectedByEffects(EffectRef)
				{
					EffectState = XComGameState_Effect(NewGameState.GetGameStateForObjectID(EffectRef.ObjectID));
					if (EffectState == none)
						EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
					if (EffectState == none || EffectState.bRemoved)
						continue;
					PersistentEffect = EffectState.GetX2Effect();
					if (PersistentEffect == none)
						continue;
					if (PersistentEffect.ForcesBleedoutWhenDamageSource(NewGameState, self, EffectState))
					{
						bForceBleedOut = true;
						break;
					}
				}
			}
		}
	}

	ShieldHP = GetCurrentStat( eStat_ShieldHP );
	PostShield_MitigationAmount = MitigationAmount;
	PostShield_DamageAmount = DamageAmount;
	PostShield_ShredAmount = ShredAmount;
	DamageAbsorbedByShield = 0;
	if ((ShieldHP > 0) && !bIgnoreShields) //If there is a shield, then shield should take all damage from both armor and hp, before spilling back to armor and hp
	{
		DamageAmountBeforeArmor = DamageAmount + MitigationAmount;
		DamageAmountBeforeArmorMinusShield = DamageAmountBeforeArmor - ShieldHP;

		if (DamageAmountBeforeArmorMinusShield > 0) //partial shield, needs to recompute armor
		{
			DamageAbsorbedByShield = ShieldHP;  //The shield took as much damage as possible
			PostShield_MitigationAmount = DamageAmountBeforeArmorMinusShield;
			if (PostShield_MitigationAmount > MitigationAmount) //damage is more than what armor can take
			{
				PostShield_DamageAmount = (DamageAmountBeforeArmorMinusShield - MitigationAmount);
				PostShield_MitigationAmount = MitigationAmount;
			}
			else //Armor takes the rest of the damage
			{
				PostShield_DamageAmount = 0;
			}

			// Armor is taking damage, which might cause shred. We shouldn't shred more than the
			// amount of armor used.
			PostShield_ShredAmount = min(PostShield_ShredAmount, PostShield_MitigationAmount);
		}
		else //shield took all, armor doesn't need to take any
		{
			PostShield_MitigationAmount = 0;
			PostShield_DamageAmount = 0;
			DamageAbsorbedByShield = DamageAmountBeforeArmor;  //The shield took a partial hit from the damage
			PostShield_ShredAmount = 0;
		}
	}

	AddShreddedValue(PostShield_ShredAmount);  // Add the new PostShield_ShredAmount

	DmgResult.Shred = PostShield_ShredAmount;
	DmgResult.DamageAmount = PostShield_DamageAmount;
	DmgResult.MitigationAmount = PostShield_MitigationAmount;
	DmgResult.ShieldHP = DamageAbsorbedByShield;
	DmgResult.SourceEffect = EffectData;
	DmgResult.Context = NewGameState.GetContext( );
	DmgResult.SpecialDamageFactors = SpecialDamageMessages;
	DmgResult.DamageTypes = DamageTypes;
	DamageResults.AddItem( DmgResult );

	if (DmgResult.MitigationAmount > 0)
		LogMsg = class'XLocalizedData'.default.MitigatedDamageLogMsg;
	else
		LogMsg = class'XLocalizedData'.default.UnmitigatedDamageLogMsg;

	LogMsg = repl( LogMsg, "#Unit", GetName( eNameType_RankFull ) );
	LogMsg = repl( LogMsg, "#Damage", DmgResult.DamageAmount );
	LogMsg = repl( LogMsg, "#Mitigated", DmgResult.MitigationAmount );
	`COMBATLOG(LogMsg);

	//Damage removes ReserveActionPoints(Overwatch)
	if ((DamageAmount + MitigationAmount) > 0)
	{
		ReserveActionPoints.Length = 0;
	}

	SetUnitFloatValue( 'LastEffectDamage', DmgResult.DamageAmount, eCleanup_BeginTactical );
	GetUnitValue('DamageThisTurn', DamageThisTurnValue);
	DamageThisTurnValue.fValue += DmgResult.DamageAmount;
	SetUnitFloatValue('DamageThisTurn', DamageThisTurnValue.fValue, eCleanup_BeginTurn);

	if (DmgResult.SourceEffect.SourceStateObjectRef.ObjectID != 0)
	{
		LastDamagedByUnitID = DmgResult.SourceEffect.SourceStateObjectRef.ObjectID;
	}
	
	ThisObj = self;
	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent( 'UnitTakeEffectDamage', ThisObj, ThisObj, NewGameState );

	// Apply damage to the shielding
	if (DamageAbsorbedByShield > 0)
	{
		ModifyCurrentStat( eStat_ShieldHP, -DamageAbsorbedByShield );

		if( GetCurrentStat(eStat_ShieldHP) <= 0 )
		{
			// The shields have been expended, remove the shields
			EventManager.TriggerEvent('ShieldsExpended', ThisObj, ThisObj, NewGameState);
		}
	}

	OverkillDamage = (GetCurrentStat( eStat_HP )) - DmgResult.DamageAmount;
	if (OverkillDamage <= 0)
	{
		// Issue #202 Start, allow listeners to override killed by explosion
		KilledByExplosionTuple = new class'XComLWTuple';
		KilledByExplosionTuple.Id = 'OverrideKilledByExplosion';
		KilledByExplosionTuple.Data.Add(2);
		KilledByExplosionTuple.Data[0].kind = XComLWTVBool;
		KilledByExplosionTuple.Data[0].b = bExplosiveDamage;
		KilledByExplosionTuple.Data[1].kind = XComLWTVInt;
		KilledByExplosionTuple.Data[1].i = DamageSource.ObjectID;

		`XEVENTMGR.TriggerEvent('KilledByExplosion', KilledByExplosionTuple, self, NewGameState);

		bKilledByExplosion = KilledByExplosionTuple.Data[0].b;
		// Issue #202 End

		KilledByDamageTypes = DamageTypes;

		DamageEffect = X2Effect_ApplyWeaponDamage(CauseOfDeath);

		if (bForceBleedOut || (bAllowBleedout && ShouldBleedOut( -OverkillDamage )))
		{
			if( DamageEffect == None || !DamageEffect.bBypassSustainEffects )
			{
				if( `CHEATMGR == none || !`CHEATMGR.bSkipPreDeathCheckEffects )
				{
					foreach class'X2AbilityTemplateManager'.default.PreDeathCheckEffects(PreCheckName)
					{
						EffectState = GetUnitAffectedByEffectState(PreCheckName);
						if( EffectState != None )
						{
							PersistentEffect = EffectState.GetX2Effect();
							if( PersistentEffect != None )
							{
								if( PersistentEffect.PreBleedoutCheck(NewGameState, self, EffectState) )
								{
									`COMBATLOG("Effect" @ PersistentEffect.FriendlyName @ "is handling the PreBleedoutCheck - unit should bleed out but the effect is handling it");
									return;
								}
							}
						}
					}
				}
			}

			if (ApplyBleedingOut( NewGameState ))
			{
				return;
			}
			else
			{
				`RedScreenOnce("Unit" @ GetName(eNameType_Full) @ "should have bled out but ApplyBleedingOut failed. Killing it instead. -jbouscher @gameplay");
			}
		}

		if( DamageEffect == None || !DamageEffect.bBypassSustainEffects )
		{
			if( `CHEATMGR == none || !`CHEATMGR.bSkipPreDeathCheckEffects )
			{
				foreach class'X2AbilityTemplateManager'.default.PreDeathCheckEffects(PreCheckName)
				{
					EffectState = GetUnitAffectedByEffectState(PreCheckName);
					if( EffectState != None )
					{
						PersistentEffect = EffectState.GetX2Effect();
						if( PersistentEffect != None )
						{
							if( PersistentEffect.PreDeathCheck(NewGameState, self, EffectState) )
							{
								`COMBATLOG("Effect" @ PersistentEffect.FriendlyName @ "is handling the PreDeathCheck - unit should be dead but the effect is handling it");
								return;
							}
						}
					}
				}
			}
		}

		SetCurrentStat( eStat_HP, 0 );
		OnUnitDied( NewGameState, CauseOfDeath, DamageSource, , EffectData );
		return;
	}

	// Apply damage to the HP
	ModifyCurrentStat( eStat_HP, -DmgResult.DamageAmount );

	if (CanEarnXp( ))
	{
		if (GetCurrentStat( eStat_HP ) < (GetMaxStat( eStat_HP ) * 0.5f))
		{
			`TRIGGERXP('XpLowHealth', GetReference( ), GetReference( ), NewGameState);
		}
	}
	if (GetCurrentStat( eStat_HP ) < LowestHP)
		LowestHP = GetCurrentStat( eStat_HP );
}

function OnUnitBledOut(XComGameState NewGameState, Object CauseOfDeath, const out StateObjectReference SourceStateObjectRef, optional const out EffectAppliedData EffectData)
{
	OnUnitDied(NewGameState, CauseOfDeath, SourceStateObjectRef,, EffectData);
	`XEVENTMGR.TriggerEvent('UnitBledOut', self, self, NewGameState);
}

protected function OnUnitDied(XComGameState NewGameState, Object CauseOfDeath, const out StateObjectReference SourceStateObjectRef, bool ApplyToOwnerAndComponents = true, optional const out EffectAppliedData EffectData)
{
	local XComGameState_Unit Killer, Owner, Comp, KillAssistant, Iter, NewUnitState;
	local XComGameStateHistory History;
	local int iComponentID;
	local bool bAllDead;
	local X2EventManager EventManager;
	local string LogMsg;
	local XComGameState_Ability AbilityStateObject;
	local UnitValue RankUpValue;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local Name CharacterGroupName, CharacterDeathEvent;
	local XComGameState_Destructible DestructibleKiller;
	local X2Effect EffectCause;
	local XComGameState_Effect EffectState;

	local StateObjectReference objRef;
	local X2CharacterTemplate myTemplate;

	objRef = GetReference();
	myTemplate = GetMyTemplate();


	LogMsg = class'XLocalizedData'.default.UnitDiedLogMsg;
	LogMsg = repl(LogMsg, "#Unit", GetName(eNameType_RankFull));
	`COMBATLOG(LogMsg);

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	m_strKIAOp = BattleData.m_strOpName;
	m_KIADate = BattleData.LocalTime;

	EffectCause = X2Effect(CauseOfDeath);
	if (EffectCause != none && EffectCause.bHideDeathWorldMessage)
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(UnitDeathVisualizationWithoutWorldMessage);
	else
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(UnitDeathVisualizationWorldMessage);

	NewGameState.GetContext().SetVisualizerUpdatesState(true); //This unit will be rag-dolling, which will move it, so notify the history system

	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent('UnitDied', self, self, NewGameState);
	
	`XACHIEVEMENT_TRACKER.OnUnitDied(self, NewGameState, CauseOfDeath, SourceStateObjectRef, ApplyToOwnerAndComponents, EffectData, bKilledByExplosion);

	// Golden Path special triggers
	CharacterDeathEvent = GetMyTemplate().DeathEvent;
	if (CharacterDeathEvent != '')
	{
		CharacterGroupName = GetMyTemplate().CharacterGroupName;
		if (CharacterGroupName != 'Cyberus' || AreAllCodexInLineageDead(NewGameState))
		{
			EventManager.TriggerEvent(CharacterDeathEvent, self, self, NewGameState);
		}
	}

	Killer = XComGameState_Unit( History.GetGameStateForObjectID( SourceStateObjectRef.ObjectID ) );
	if (Killer == None && LastDamagedByUnitID != 0)
	{
		Killer = XComGameState_Unit(History.GetGameStateForObjectID(LastDamagedByUnitID));
	}

	//	special handling for claymore kills - credit the reaper that placed the claymore, regardless of what blew it up
	//	also special handling for remote start kills
	if (Killer == none)
	{
		DestructibleKiller = XComGameState_Destructible(History.GetGameStateForObjectID(SourceStateObjectRef.ObjectID));
		if (DestructibleKiller != none)
		{
			if (DestructibleKiller.DestroyedByRemoteStartShooter.ObjectID > 0)
			{
				Killer = XComGameState_Unit(History.GetGameStateForObjectID(DestructibleKiller.DestroyedByRemoteStartShooter.ObjectID));
			}
			else
			{
				foreach History.IterateByClassType(class'XcomGameState_Effect', EffectState)
				{
					if (EffectState.CreatedObjectReference.ObjectID == DestructibleKiller.ObjectID)
					{
						if (X2Effect_Claymore(EffectState.GetX2Effect()) != none)
						{
							Killer = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
						}

						break;
					}
				}
			}
		}
	}
	//	special handling for templar ghosts - credit the creator of the ghost with any kills by the ghost
	if (Killer != none && Killer.GhostSourceUnit.ObjectID > 0)
	{
		Killer = XComGameState_Unit(History.GetGameStateForObjectID(Killer.GhostSourceUnit.ObjectID));
	}

	if( GetTeam() == eTeam_Alien || GetTeam() == eTeam_TheLost )
	{
		if( SourceStateObjectRef.ObjectID != 0 )
		{	
			if (Killer != none && Killer.CanEarnXp())
			{
				Killer = XComGameState_Unit(NewGameState.ModifyStateObject(Killer.Class, Killer.ObjectID));
				Killer.KilledUnits.AddItem(GetReference());
				Killer.KillCount += GetMyTemplate().KillContribution; // Allows specific units to contribute different amounts to the kill total

				// If the Wet Work GTS bonus is active, increment the Wet Work kill counter
				XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
				if(XComHQ != none)
				{
					if(XComHQ.SoldierUnlockTemplates.Find('WetWorkUnlock') != INDEX_NONE)
					{
						Killer.WetWorkKills++;
					}
					
					Killer.BonusKills += (XComHQ.BonusKillXP);
				}

				if (Killer.bIsShaken)
				{
					Killer.UnitsKilledWhileShaken++; //confidence boost towards recovering from being Shaken
				}

				CheckForFlankingEnemyKill(NewGameState, Killer);

				//  Check for and trigger event to display rank up message if applicable
				if (Killer.IsSoldier() && Killer.CanRankUpSoldier())
				{
					Killer.GetUnitValue('RankUpMessage', RankUpValue);
					if (RankUpValue.fValue == 0)
					{
						EventManager.TriggerEvent('RankUpMessage', Killer, Killer, NewGameState);
						Killer.SetUnitFloatValue('RankUpMessage', 1, eCleanup_BeginTactical);
					}
				}

				//  All team mates that are alive and able to earn XP will be credited with a kill assist (regardless of their actions)
				foreach History.IterateByClassType(class'XComGameState_Unit', Iter)
				{
					if (Iter != Killer && Iter.ControllingPlayer.ObjectID == Killer.ControllingPlayer.ObjectID && Iter.CanEarnXp() && Iter.IsAlive())
					{
						KillAssistant = XComGameState_Unit(NewGameState.ModifyStateObject(Iter.Class, Iter.ObjectID));
						KillAssistant.KillAssists.AddItem(objRef);
						KillAssistant.KillAssistsCount += myTemplate.KillContribution;

						//  jbouscher: current desire is to only display the rank up message based on a full kill, commenting this out for now.
						//  Check for and trigger event to display rank up message if applicable
						//if (KillAssistant.IsSoldier() && KillAssistant.CanRankUpSoldier())
						//{
						//	RankUpValue.fValue = 0;
						//	KillAssistant.GetUnitValue('RankUpMessage', RankUpValue);
						//	if (RankUpValue.fValue == 0)
						//	{
						//		EventManager.TriggerEvent('RankUpMessage', KillAssistant, KillAssistant, NewGameState);
						//		KillAssistant.SetUnitFloatValue('RankUpMessage', 1, eCleanup_BeginTactical);
						//	}
						//}		
					}
				}

				`TRIGGERXP('XpKillShot', Killer.GetReference(), GetReference(), NewGameState);
			}

			if (Killer != none && Killer.GetMyTemplate().bIsTurret && Killer.GetTeam() == eTeam_XCom && Killer.IsMindControlled())
			{
				`ONLINEEVENTMGR.UnlockAchievement(AT_KillWithHackedTurret);
			}
		}

		// when enemies are killed with pending loot, start the loot expiration timer
		if( IsLootable(NewGameState) )
		{
			// no loot drops in Challenge Mode
			// This would really be done in the AI spawn manager, just don't roll loot for enemies,
			// but that would require fixing up all the existing start states.  Doing it here at runtime is way easier.
			// Also we do it before RollForSpecialLoot so that Templar Focus drops will still occur.
			if (History.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) != none)
			{
				PendingLoot.LootToBeCreated.Length = 0;
			}

			RollForSpecialLoot();

			if( HasAvailableLoot() )
			{
				MakeAvailableLoot(NewGameState);
			}
			else if( PendingLoot.LootToBeCreated.Length > 0 )
			{
				NewGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeLootDestroyedByExplosives);
			}

			// no loot drops in Challenge Mode
			if (History.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) == none)
			{
				RollForAutoLoot(NewGameState);
			}
		}
		else
		{
			NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));
			NewUnitState.PendingLoot.LootToBeCreated.Length = 0;
		}
	}
	else if( GetTeam() == eTeam_XCom )
	{
		if( IsLootable(NewGameState) )
		{
			DropCarriedLoot(NewGameState);
		}
	}

	m_strCauseOfDeath = class'UIBarMemorial_Details'.static.FormatCauseOfDeath( self, Killer, NewGameState.GetContext() );

	if (ApplyToOwnerAndComponents)
	{
		// If is component, attempt to apply to owner.
		if ( m_bSubsystem && OwningObjectId > 0)
		{
			// Check all other components of our owner object.
			Owner = XComGameState_Unit(History.GetGameStateForObjectID(OwningObjectId));
			bAllDead = true;
			foreach Owner.ComponentObjectIds(iComponentID)
			{
				if (iComponentID == ObjectID) // Skip this one.
					continue;
				Comp = XComGameState_Unit(History.GetGameStateForObjectID(iComponentID));
				if (Comp != None && Comp.IsAlive())
				{
					bAllDead = false;
					break;
				}
			}
			if (bAllDead && Owner.IsAlive())
			{
				Owner = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', OwningObjectId));
				Owner.SetCurrentStat(eStat_HP, 0);
				Owner.OnUnitDied(NewGameState, CauseOfDeath, SourceStateObjectRef, false, EffectData);
			}
		}
		else
		{
			// If we are the owner, and we're dead, set all the components as dead.
			foreach ComponentObjectIds(iComponentID)
			{
				Comp = XComGameState_Unit(History.GetGameStateForObjectID(iComponentID));
				if (Comp != None && Comp.IsAlive())
				{
					Comp = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', iComponentID));
					Comp.SetCurrentStat(eStat_HP, 0);
					Comp.OnUnitDied(NewGameState, CauseOfDeath, SourceStateObjectRef, false, EffectData);
				}
			}
		}
	}

	LowestHP = 0;

	// finally send a kill mail: soldier/alien and alien/soldier
	Killer = none;
	if( SourceStateObjectRef.ObjectID != 0 )
	{
		Killer = XComGameState_Unit(History.GetGameStateForObjectID(SourceStateObjectRef.ObjectID));
	}
	EventManager.TriggerEvent('KillMail', self, Killer, NewGameState);

	if (Killer == none)
	{
		if (DestructibleKiller != none)
		{
			EventManager.TriggerEvent('KilledByDestructible', self, DestructibleKiller, NewGameState);
		}
	}

	// send weapon ability that did the killing
	AbilityStateObject = XComGameState_Ability(NewGameState.GetGameStateForObjectID(EffectData.AbilityStateObjectRef.ObjectID));
	if (AbilityStateObject == none)
	{
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(EffectData.AbilityStateObjectRef.ObjectID));
	}

	if (AbilityStateObject != none)
	{
		EventManager.TriggerEvent('WeaponKillType', AbilityStateObject, Killer);
	}

}

function UnitDeathVisualizationWorldMessage(XComGameState VisualizeGameState)
{
	local XComPresentationLayer Presentation;
	local XComGameStateHistory History;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlayMessageBanner MessageAction;
	local X2Action_PlayWorldMessage WorldMessageAction;
	local X2Action_UpdateFOW FOWUpdateAction;
	local XGParamTag kTag;
	local ETeam UnitTeam;
	local XComGameStateVisualizationMgr LocalVisualizationMgr;
	local X2Action_CameraLookAt CameraLookAt;
	
	Presentation = `PRES;
	History = `XCOMHISTORY;
	LocalVisualizationMgr = `XCOMVISUALIZATIONMGR;

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = History.GetVisualizer(ObjectID);

	// try to parent to the death action if there is one
	ActionMetadata.LastActionAdded = LocalVisualizationMgr.GetNodeOfType(LocalVisualizationMgr.BuildVisTree, class'X2Action_Death', none, ObjectID);

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = GetFullName();

	// no need to display death world messages for enemies; most enemies will display loot messages when killed
	UnitTeam = GetTeam();
	if( UnitTeam == eTeam_XCom )
	{
		CameraLookAt = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		CameraLookAt.LookAtObject = ActionMetadata.StateObject_NewState;
		CameraLookAt.LookAtDuration = 2.0;
		CameraLookAt.BlockUntilActorOnScreen = true;
		CameraLookAt.UseTether = false;
		CameraLookAt.DesiredCameraPriority = eCameraPriority_GameActions; // increased camera priority so it doesn't get stomped

		MessageAction = X2Action_PlayMessageBanner(class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		MessageAction.AddMessageBanner(class'UIEventNoticesTactical'.default.UnitDiedTitle,
			/*class'UIUtilities_Image'.const.UnitStatus_Unconscious*/,
			GetName(eNameType_RankFull),
			`XEXPAND.ExpandString(Presentation.m_strUnitDied),
			eUIState_Bad);
	}
	else
	{
		WorldMessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		WorldMessageAction.AddWorldMessage(`XEXPAND.ExpandString(Presentation.m_strUnitDied));
	}

	FOWUpdateAction = X2Action_UpdateFOW(class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	FOWUPdateAction.Remove = true;
}

function UnitDeathVisualizationWithoutWorldMessage(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_UpdateFOW FOWUpdateAction;
	local XComGameStateVisualizationMgr LocalVisualizationMgr;

	History = `XCOMHISTORY;
	LocalVisualizationMgr = `XCOMVISUALIZATIONMGR;

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = History.GetVisualizer(ObjectID);

	// try to parent to the death action if there is one
	ActionMetadata.LastActionAdded = LocalVisualizationMgr.GetNodeOfType(LocalVisualizationMgr.BuildVisTree, class'X2Action_Death', none, ObjectID);

	FOWUpdateAction = X2Action_UpdateFOW(class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	FOWUPdateAction.Remove = true;
}

function CheckForFlankingEnemyKill(XComGameState NewGameState, XComGameState_Unit Killer)
{
	local array<StateObjectReference> OutFlankingEnemies;
	local int Index, KillerID;
	local XComGameState_Unit FlankedSoldier;

	if (!`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		class'X2TacticalVisibilityHelpers'.static.GetEnemiesFlankedBySource(ObjectID, OutFlankingEnemies);
		KillerID = Killer.ObjectID;
		for (Index = OutFlankingEnemies.Length - 1; Index > -1; --Index)
		{
			FlankedSoldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OutFlankingEnemies[Index].ObjectID));
			if ((OutFlankingEnemies[Index].ObjectID != KillerID) && (FlankedSoldier.CanEarnSoldierRelationshipPoints(Killer))) // pmiller - so that you can't have a relationship with yourself
			{
				FlankedSoldier = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', OutFlankingEnemies[Index].ObjectID));
				FlankedSoldier.AddToSquadmateScore(Killer.ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_KillFlankingEnemy);
				Killer.AddToSquadmateScore(OutFlankingEnemies[Index].ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_KillFlankingEnemy);
			}
		}
	}
}

native function SetBaseMaxStat( ECharStatType Stat, float Amount, optional ECharStatModApplicationRule ApplicationRule = ECSMAR_Additive );
native function float GetBaseStat( ECharStatType Stat ) const;
native function float GetMaxStat( ECharStatType Stat );
native function float GetCurrentStat( ECharStatType Stat ) const;
native function ModifyCurrentStat(ECharStatType Stat, float Delta);
native function SetCurrentStat( ECharStatType Stat, float NewValue );
native function GetStatModifiers(ECharStatType Stat, out array<XComGameState_Effect> Mods, out array<float> ModValues, optional XComGameStateHistory GameStateHistoryObject);

native function ApplyEffectToStats( const ref XComGameState_Effect SourceEffect, optional XComGameState NewGameState );
native function UnApplyEffectFromStats( const ref XComGameState_Effect SourceEffect, optional XComGameState NewGameState );

function GiveStandardActionPoints()
{
	local int i, PointsToGive;

	//  Clear any leftover action points or reserved action points
	ActionPoints.Length = 0;
	ReserveActionPoints.Length = 0;
	SkippedActionPoints.Length = 0;
	//  Retrieve standard action points per turn
	PointsToGive = class'X2CharacterTemplateManager'.default.StandardActionsPerTurn;
	//  Subtract any stunned action points
	StunnedThisTurn = 0;
	if( StunnedActionPoints > 0 )
	{
		if( StunnedActionPoints >= PointsToGive )
		{
			StunnedActionPoints -= PointsToGive;
			StunnedThisTurn = PointsToGive;
			PointsToGive = 0;
		}
		else
		{
			PointsToGive -= StunnedActionPoints;
			StunnedThisTurn = StunnedActionPoints;
			StunnedActionPoints = 0;
		}
	}
	//  Issue non-stunned standard action points
	for( i = 0; i < PointsToGive; ++i )
	{
		ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	}
}

function SetupActionsForBeginTurn()
{
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local UnitValue MovesThisTurn;

	GiveStandardActionPoints();

	if( ActionPoints.Length > 0 )
	{
		History = `XCOMHISTORY;
		foreach AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();
			EffectTemplate.ModifyTurnStartActionPoints(self, ActionPoints, EffectState);
		}
	}

	Untouchable = 0;                    //  untouchable only lasts until the start of your next turn, so always clear it out
	bGotFreeFireAction = false;                                                      //Reset FreeFireAction flag
	GetUnitValue('MovesThisTurn', MovesThisTurn);
	SetUnitFloatValue('MovesLastTurn', MovesThisTurn.fValue, eCleanup_BeginTactical); 
	CleanupUnitValues(eCleanup_BeginTurn);
	TurnStartLocation = TileLocation;
	PanicTestsPerformedThisTurn = 0;
}

function int NumAllActionPoints()
{
	return ActionPoints.Length;
}

function int NumAllReserveActionPoints()
{
	return ReserveActionPoints.Length;
}

function int GetNumScamperActionPoints()
{
	local int NumScamperPoints;
	local X2CharacterTemplate CharacterTemplate;
	CharacterTemplate = GetMyTemplate();
	NumScamperPoints = CharacterTemplate.ScamperActionPoints;
	// Also due to some dark events, some units will get multiple action points to scamper and overwatch.

	return NumScamperPoints;
}

function bool HasValidMoveAction()
{
	local GameRulesCache_Unit UnitCache;
	local AvailableAction Action;
	local XComGameStateHistory History;
	local XComGameState_Ability Ability;

	//  retrieve cached action info - check if movement is valid first.
	`TACTICALRULES.GetGameRulesCache_Unit(GetReference(), UnitCache);
	if( UnitCache.bAnyActionsAvailable )
	{
		History = `XCOMHISTORY;
		foreach UnitCache.AvailableActions(Action)
		{
			Ability = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
			if( Ability.IsAbilityPathing() )
			{
				return (Action.AvailableCode == 'AA_Success');
			}
		}
	}
	return false;
}


event int NumActionPointsForMoving()
{
	local array<name> MoveTypes;
	local int i, Count;

	MoveTypes = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().GetStandardMoveAbilityActionTypes();
	for (i = 0; i < MoveTypes.Length; ++i)
	{
		Count += NumActionPoints(MoveTypes[i]);
	}
	return Count;
}

function int NumActionPoints(optional name Type=class'X2CharacterTemplateManager'.default.StandardActionPoint)
{
	return InternalNumActionPoints(ActionPoints, Type);
}

function int NumReserveActionPoints(optional name Type=class'X2CharacterTemplateManager'.default.StandardActionPoint)
{
	return InternalNumActionPoints(ReserveActionPoints, Type);
}

event bool HasKillZoneEffect()
{
	return NumReserveActionPoints(class'X2Ability_SharpshooterAbilitySet'.default.KillZoneReserveType) > 0;
}

protected function int InternalNumActionPoints(const out array<name> Actions, name Type)
{
	local int i, Count;

	for (i = 0; i < Actions.Length; ++i)
	{
		if (Actions[i] == Type)
			Count++;
	}
	return Count;
}

function DisplayActionPointInfoFlyover()
{
	local string DisplayString;
	local XComPresentationLayer PresentationLayer;
	local X2TacticalGameRuleset Rules;

	Rules = `TACTICALRULES;

	if( ControllingPlayer.ObjectID == Rules.GetLocalClientPlayerObjectID() && !`REPLAY.bInReplay )
	{
		PresentationLayer = `PRES;

		if( ActionPoints.Length == 0 )
		{
			if( !(Rules.UnitHasActionsAvailable(self)) )
			{
				// display no action points remaining
				DisplayString = PresentationLayer.m_strNoActionPointsRemaining;
			}
		}
		else if( ActionPoints.Find(class'X2CharacterTemplateManager'.default.StandardActionPoint) == INDEX_NONE )
		{
			// select display message based on ActionPoint type
			switch( ActionPoints[0] )
			{
			case class'X2CharacterTemplateManager'.default.MomentumActionPoint :
				DisplayString = PresentationLayer.m_strMomentumActionPointRemaining;
				break;
			case class'X2CharacterTemplateManager'.default.MoveActionPoint :
				DisplayString = PresentationLayer.m_strMoveActionPointRemaining;
				break;
			case class'X2CharacterTemplateManager'.default.RunAndGunActionPoint :
				DisplayString = PresentationLayer.m_strRunAndGunActionPointRemaining;
				break;
			}
		}

		if( DisplayString != "" )
		{
			PresentationLayer.QueueWorldMessage(DisplayString, GetVisualizer().Location, GetReference(), eColor_Attention, , , , , , 3.0 /*DisplayTime*/, , /*FlyOverIcon*/, , , , , , , , true);
		}
	}
}

function string GetKIAOp()
{
	return m_strKIAOp;
}

function string GetCauseOfDeath()
{
	return m_strCauseOfDeath;
}

function TDateTime GetKIADate()
{
	return m_KIADate;
}

function int GetNumKills()
{
	return KilledUnits.Length;
}

function int GetNumKillsFromAssists()
{
	local X2SoldierClassTemplate ClassTemplate;
	local int Assists;

	ClassTemplate = GetSoldierClassTemplate();
	if (ClassTemplate != none)
	{
		if (KillAssistsCount > 0 && ClassTemplate.KillAssistsPerKill > 0)
			Assists = Round(KillAssistsCount) / ClassTemplate.KillAssistsPerKill;
		if (PsiCredits > 0 && ClassTemplate.PsiCreditsPerKill > 0)
			Assists += PsiCredits / ClassTemplate.PsiCreditsPerKill;
	}
	
	return Assists;
}

simulated function int GetNumMissions()
{
	return iNumMissions;
}

function int GetFame()
{
	return min((StartingFame + (KilledUnits.Length / 2) + iNumMissions), 100);
}

function SetHasPsiGift()
{
	bHasPsiGift = true;
}

function name GetVoice()
{
	return kAppearance.nmVoice;
}

function SetVoice(name Voice)
{
	kAppearance.nmVoice = Voice;
}

function bool HasAvailablePerksToAssign()
{
	local int i, AbilityCost;
	local array<SoldierClassAbilityType> RankAbilities;

	if(m_SoldierRank == 0 || m_SoldierClassTemplateName == '' || m_SoldierClassTemplateName == 'PsiOperative')
		return false;
	
	if (IsResistanceHero() && m_SoldierRank > 1)
	{
		// Resistance Heroes can purchase abilities without choosing one at the most recent rank, so check their remaining AP instead		
		AbilityCost = class'X2StrategyGameRulesetDataStructures'.default.AbilityPointCosts[m_SoldierRank - 1];
		if (AbilityCost > AbilityPoints)
		{
			// If the cost of abilities at this rank is more than their available AP, they have already spent their promotion AP
			return false;
		}
	}
	
	RankAbilities = AbilityTree[m_SoldierRank - 1].Abilities;
	for (i = 0; i < RankAbilities.Length; ++i)
	{
		if (HasSoldierAbility(RankAbilities[i].AbilityName))
			return false;
	}
		
	return true;
}

function bool HasPurchasedPerkAtRank(int Rank, optional int NumBranchesToCheck)
{
	local int i;
	local array<SoldierClassAbilityType> RankAbilities;
		
	RankAbilities = AbilityTree[Rank].Abilities;
	
	// Do not let the num of branches to check be 0, or larger than the available abilities
	if (NumBranchesToCheck == 0 || NumBranchesToCheck > RankAbilities.Length)
	{
		NumBranchesToCheck = RankAbilities.Length;
	}

	for (i = 0; i < NumBranchesToCheck; ++i)
	{
		if (HasSoldierAbility(RankAbilities[i].AbilityName))
			return true;
	}

	return false;
}

function EnableGlobalAbilityForUnit(name AbilityName)
{
	local X2AbilityTemplateManager AbilityMan;
	local X2AbilityTemplate Template;
	local name AllowedName;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMan.FindAbilityTemplate(AbilityName);
	if (Template != none)
	{
		AllowedName = name("AllowedAbility_" $ string(AbilityName));
		SetUnitFloatValue(AllowedName, 1, eCleanup_BeginTactical);
	}
}

function DisableGlobalAbilityForUnit(name AbilityName)
{
	local X2AbilityTemplateManager AbilityMan;
	local X2AbilityTemplate Template;
	local name AllowedName;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMan.FindAbilityTemplate(AbilityName);
	if (Template != none)
	{
		AllowedName = name("AllowedAbility_" $ string(AbilityName));
		SetUnitFloatValue(AllowedName, 0, eCleanup_BeginTactical);
	}
}

function bool CanDodge(XComGameState_Unit Attacker, XComGameState_Ability AbilityState)
{
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;
	local X2Effect_Persistent Effect;

	History = `XCOMHISTORY;
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Effect = EffectState.GetX2Effect();
			if (Effect != none)
			{
				if (!Effect.AllowDodge(Attacker, AbilityState))
					return false;
			}
		}
	}

	return true;
}

//=============================================================================================

function SetCharacterName(string First, string Last, string Nick)
{
	strFirstName = First;
	strLastName = Last;
	strNickName = Nick;
}

simulated function XComUnitPawn GetPawnArchetype( string strArchetype="", optional const XComGameState_Unit ReanimatedFromUnit = None )
{
	local Object kPawn;

	if(strArchetype == "")
	{
		strArchetype = GetMyTemplate().GetPawnArchetypeString(self, ReanimatedFromUnit);
	}

	kPawn = `CONTENT.RequestGameArchetype(strArchetype);
	if (kPawn != none && kPawn.IsA('XComUnitPawn'))
		return XComUnitPawn(kPawn);
	return none;
}

function OnAsyncLoadRequestComplete(XComGameState_Unit_AsyncLoadRequest alr)
{
    alr.PawnCreatedCallback(self);
    self.m_asynchronousLoadRequests.RemoveItem(alr);

	`XENGINE.UnPauseGC();
}

// Returns when all packages for the pawn are created. Call CreatePawn afterwards.
simulated function LoadPawnPackagesAsync( Actor PawnOwner, vector UseLocation, rotator UseRotation, delegate<OnUnitPawnCreated> Callback )
{
    local XComGameState_Unit_AsyncLoadRequest alr;
    local string strArchetype;
	local int i;

	strArchetype = GetMyTemplate().GetPawnArchetypeString(self);

    alr = new class'XComGameState_Unit_AsyncLoadRequest';

    alr.ArchetypeName = strArchetype;
    alr.UseLocation = UseLocation;
    alr.UseRotation = UseRotation;
    alr.bForceMenuState = false;

    alr.PawnCreatedCallback = Callback;
    alr.OnAsyncLoadComplete_UnitCallback = OnAsyncLoadRequestComplete;

	RequestResources(alr.ArchetypesToLoad);

	alr.NumContentRequests = 1;	

    `CONTENT.RequestGameArchetype(strArchetype, alr, alr.OnObjectLoaded, true);
	
	for (i = 0; i < alr.ArchetypesToLoad.Length; ++i)
	{
		if (alr.ArchetypesToLoad[i] != "")
		{
			`CONTENT.RequestGameArchetype(alr.ArchetypesToLoad[i], alr, alr.OnObjectLoaded, true);
			alr.NumContentRequests++;
		}
	}

	`XENGINE.PauseGC();

	m_asynchronousLoadRequests.AddItem(alr);
}

/*
function HandleAsyncRequests()
{
	local XComUnitPawn SpawnedPawn;
    local XComGameState_Unit_AsyncLoadRequest alr;

    bHandlingAsyncRequests = true;

    // this call can force the already queued up request to flush, but we can't call it again from inside the completion delegate
    //  handle that mess here
    if(m_asynchronousLoadRequests.Length != 0 )
    {
        while( m_asynchronousLoadRequests.Length != 0 && m_asynchronousLoadRequests[0].bIsComplete)
        {       
            alr = m_asynchronousLoadRequests[0];
            SpawnedPawn = CreatePawn(alr.PawnOwner, alr.UseLocation, alr.UseRotation);
            alr.PawnCreatedCallback(SpawnedPawn);
            m_asynchronousLoadRequests.RemoveItem(alr);
        }
    }

    bHandlingAsyncRequests = false;

}
*/

simulated function XComUnitPawn CreatePawn( Actor PawnOwner, vector UseLocation, rotator UseRotation, optional bool bForceMenuState = false )
{
	local XComUnitPawn UnitPawnArchetype;
	local XComUnitPawn SpawnedPawn;
	local XComGameStateHistory History;
	local XComHumanPawn HumanPawn;
	local X2CharacterTemplate CharacterTemplate;
	local bool bInHistory;

    bIsInCreate = true;

	History = `XCOMHISTORY;
	bInHistory = !bForceMenuState && History.GetGameStateForObjectID(ObjectID) != none;

	UnitPawnArchetype = GetPawnArchetype();

	SpawnedPawn = class'Engine'.static.GetCurrentWorldInfo().Spawn( UnitPawnArchetype.Class, PawnOwner, , UseLocation, UseRotation, UnitPawnArchetype, true, eTeam_All );
	SpawnedPawn.SetPhysics(PHYS_None);
	SpawnedPawn.SetVisible(true);
	SpawnedPawn.ObjectID = ObjectID;

	CharacterTemplate = GetMyTemplate();
	HumanPawn = XComHumanPawn(SpawnedPawn);
	if(HumanPawn != none && CharacterTemplate.bAppearanceDefinesPawn)
	{	
		if (CharacterTemplate.bForceAppearance)
			HumanPawn.UpdateAppearance(kAppearance, CharacterTemplate.ForceAppearance);

		HumanPawn.SetAppearance(kAppearance);
	}

	if(!bInHistory)
	{
		SpawnedPawn.SetMenuUnitState(self);
	}

    bIsInCreate = false;

	//Trigger to allow mods access to the newly created pawn
	`XEVENTMGR.TriggerEvent('OnCreateCinematicPawn', SpawnedPawn, self);

	return SpawnedPawn;
}

simulated function bool HasBackpack()
{
	return true; // all units now have a backpack
	//return GetMaxStat(eStat_BackpackSize) > 0 && GetItemInSlot(eInvSlot_Mission) == none && !HasHeavyWeapon();
}

simulated native function XComGameState_Item GetItemGameState(StateObjectReference ItemRef, optional XComGameState CheckGameState, optional bool bExcludeHistory = false);

simulated native function XComGameState_Item GetItemInSlot(EInventorySlot Slot, optional XComGameState CheckGameState, optional bool bExcludeHistory = false);

simulated function array<XComGameState_Item> GetAllItemsInSlot(EInventorySlot Slot, optional XComGameState CheckGameState, optional bool bExcludeHistory=false, optional bool bHasSize = false)
{
	local int i;
	local XComGameState_Item kItem;
	local array<XComGameState_Item> Items;
	
	// Issue #118 -- don't hardcode multi item slots here
	`assert(class'CHItemSlot'.static.SlotIsMultiItem(Slot));     //  these are the only multi-item slots
	
	for (i = 0; i < InventoryItems.Length; ++i)
	{
		kItem = GetItemGameState(InventoryItems[i], CheckGameState, bExcludeHistory);
		if (kItem != none && kItem.InventorySlot == Slot && (!bHasSize || kItem.GetMyTemplate().iItemSize > 0))
			Items.AddItem(kItem);
	}
	return Items;
}


simulated function GetAttachedUnits(out array<XComGameState_Unit> AttachedUnits, optional XComGameState GameState)
{
	local XComGameState_Item ItemIterator;
	local XComGameState_Unit AttachedUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Item', ItemIterator)
	{
		if (ObjectID == ItemIterator.AttachedUnitRef.ObjectID && ItemIterator.CosmeticUnitRef.ObjectID > 0)
		{
			AttachedUnit = XComGameState_Unit(History.GetGameStateForObjectID(ItemIterator.CosmeticUnitRef.ObjectID, , (GameState != none) ? GameState.HistoryIndex : - 1 ));
			AttachedUnits.AddItem(AttachedUnit);
		}
	}
}

simulated function XComGameState_Item GetBestMedikit(optional XComGameState CheckGameState, optional bool bExcludeHistory)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item, BestMedikit;

	Items = GetAllItemsInSlot(eInvSlot_Utility, CheckGameState, bExcludeHistory);
	foreach Items(Item)
	{
		if (Item.GetWeaponCategory() == class'X2Item_DefaultUtilityItems'.default.MedikitCat)
		{
			if (BestMedikit == none || BestMedikit.Ammo < Item.Ammo)
			{
				BestMedikit = Item;
			}
		}
	}
	return BestMedikit;
}

function name DefaultGetRandomUberTemplate_WarnAboutFilter(string PartType, X2SimpleBodyPartFilter Filter)
{
	`log("WARNING:"@ `ShowVar(self) $": Unable to find a GetRandomUberTemplate for '"$PartType$"' Filter:"@Filter.DebugString_X2SimpleBodyPartFilter(), , 'XCom_Templates');
	return '';
}

function bool AddItemToInventory(XComGameState_Item Item, EInventorySlot Slot, XComGameState NewGameState, optional bool bAddToFront)
{
	local X2BodyPartTemplate ArmorPartTemplate, BodyPartTemplate;
	local X2BodyPartTemplateManager BodyPartMgr;
	local X2SimpleBodyPartFilter Filter;
	local X2ItemTemplate ItemTemplate;
	local array<name> DLCNames; //issue #155 addition

	ItemTemplate = Item.GetMyTemplate();
	
	// issue #114: pass along item state when possible
	if (CanAddItemToInventory(ItemTemplate, Slot, NewGameState, Item.Quantity, Item))
	{
	// end issue #114
		if( ItemTemplate.OnEquippedFn != None )
		{
			ItemTemplate.OnEquippedFn(Item, self, NewGameState);
		}

		Item.InventorySlot = Slot;
		Item.OwnerStateObject = GetReference();

		if (Slot == eInvSlot_Backpack)
		{
			AddItemToBackpack(Item, NewGameState);
		}
		else
		{			
			if(bAddToFront)
				InventoryItems.InsertItem(0, Item.GetReference());
			else
				InventoryItems.AddItem(Item.GetReference());
		}

		if (Slot == eInvSlot_Mission)
		{
			//  @TODO gameplay: in tactical, if there are any items in the backpack, they must be dropped on a nearby tile for pickup by another soldier
			//  this would only happen if a soldier picked up a mission item from a dead soldier.
			//  in HQ, a soldier would never have items sitting around in the backpack
		}
		else if (Slot == eInvSlot_Armor)
		{
			// Start Issue #171
			if(!IsMPCharacter())
			{
				RealizeItemSlotsCount(NewGameState);
				// End Issue #171
			}

			//  must ensure appearance matches 
			if (GetMyTemplate().bAppearanceDefinesPawn && !GetMyTemplate().bForceAppearance)
			{
				BodyPartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
				ArmorPartTemplate = BodyPartMgr.FindUberTemplate("Torso", kAppearance.nmTorso);

				//Here to handle cases where the character has changed gender and armor at the same time
				if(ArmorPartTemplate != none && EGender(kAppearance.iGender) != ArmorPartTemplate.Gender)
				{
					ArmorPartTemplate = none;
				}

				if (IsSoldier() && (ArmorPartTemplate == none || (ArmorPartTemplate.ArmorTemplate != '' && ArmorPartTemplate.ArmorTemplate != Item.GetMyTemplateName())))
				{
					//  setup filter based on new armor
					Filter = `XCOMGAME.SharedBodyPartFilter;
					//start issue #155, get usable DLC part pack names when upgrading armours
					DLCNames = class'CHHelpers'.static.GetAcceptablePartPacks();
					Filter.Set(EGender(kAppearance.iGender), ECharacterRace(kAppearance.iRace), '', , , DLCNames); //end issue #155
					Filter.SetTorsoSelection('ForceArmorMatch', Item.GetMyTemplateName()); //ForceArmorMatch will make the system choose a torso based on the armor type

					//  need to pick a new torso, which will necessitate updating arms and legs
					ArmorPartTemplate = BodyPartMgr.GetRandomUberTemplate("Torso", Filter, Filter.FilterTorso);
					kAppearance.nmTorso = (ArmorPartTemplate != none) ? ArmorPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("Torso", Filter);
					//  update filter to include specific torso data to match
					Filter.Set(EGender(kAppearance.iGender), ECharacterRace(kAppearance.iRace), kAppearance.nmTorso, , , DLCNames); //issue #155, re-set filter with new DLC names

					BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("Arms", Filter, Filter.FilterByTorsoAndArmorMatch);
					if(BodyPartTemplate == none)
					{
						kAppearance.nmArms = '';

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("LeftArm", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmLeftArm = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("LeftArm", Filter);

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("RightArm", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmRightArm = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("RightArm", Filter);

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("LeftArmDeco", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmLeftArmDeco = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("LeftArmDeco", Filter);

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("RightArmDeco", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmRightArmDeco = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("RightArmDeco", Filter);

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("LeftForearm", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmLeftForearm = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("LeftForearm", Filter);

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("RightForearm", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmRightForearm = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("RightForearm", Filter);
					}
					else
					{
						kAppearance.nmArms = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("Arms", Filter);
						kAppearance.nmLeftArm = '';
						kAppearance.nmRightArm = '';
						kAppearance.nmLeftArmDeco = '';
						kAppearance.nmRightArmDeco = '';
						kAppearance.nmLeftForearm = '';
						kAppearance.nmRightForearm = '';
					}

					BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("Legs", Filter, Filter.FilterByTorsoAndArmorMatch);
					kAppearance.nmLegs = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("Legs", Filter);

					BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("Thighs", Filter, Filter.FilterByTorsoAndArmorMatch);
					kAppearance.nmThighs = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("Thighs", Filter);

					BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("Shins", Filter, Filter.FilterByTorsoAndArmorMatch);
					kAppearance.nmShins = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("Shins", Filter);

					BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("Helmets", Filter, Filter.FilterByTorsoAndArmorMatch);
					kAppearance.nmHelmet = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : kAppearance.nmHelmet;

					if (ArmorPartTemplate != none && HasStoredAppearance(kAppearance.iGender, ArmorPartTemplate.ArmorTemplate) && !bIsSuperSoldier)
					{
						GetStoredAppearance(kAppearance, kAppearance.iGender, ArmorPartTemplate.ArmorTemplate);
					}
				}
			}
		}
		else if(Slot == eInvSlot_CombatSim)
		{
			ApplyCombatSimStats(Item);
		}
		// Issue #118 Start
		else if (class'CHItemSlot'.static.SlotIsTemplated(Slot))
		{
			class'CHItemSlot'.static.GetTemplateForSlot(Slot).AddItemToSlot(self, Item, NewGameState);
		}
		// Issue #118 End

		if (Item.IsMissionObjectiveItem())
		{
			`XEVENTMGR.TriggerEvent('EffectBreakUnitConcealment', self, self, NewGameState);
		}

		return true;
	}
	return false;
}
//issue #114: function can now take in item states for new hook
simulated function bool CanAddItemToInventory(const X2ItemTemplate ItemTemplate, const EInventorySlot Slot, optional XComGameState CheckGameState, optional int Quantity=1, optional XComGameState_Item Item)
{
	local int i, iUtility;
	local XComGameState_Item kItem;
	local X2WeaponTemplate WeaponTemplate;
	local X2GrenadeTemplate GrenadeTemplate;
	local X2ArmorTemplate ArmorTemplate;
	local array<X2DownloadableContentInfo> DLCInfos; // Issue #50: Added for hook
	local int bCanAddItem; // Issue #50: hackery to avoid bool not being allowed to be out parameter
	local string BlankString; //issue #114: blank string variable for the out variable
	// Issue #171 Variables
	local int NumHeavy;
	// Start Issue #50 and #114: inventory hook
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		if(DLCInfos[i].CanAddItemToInventory_CH_Improved(bCanAddItem, Slot, ItemTemplate, Quantity, self, CheckGameState, BlankString, Item))
		{
			return bCanAddItem > 0;
		}
	}
	// End Issue #50 and #114
	
	if( bIgnoreItemEquipRestrictions )
		return true;

	if (ItemTemplate != none)
	{
		WeaponTemplate = X2WeaponTemplate(ItemTemplate);
		ArmorTemplate = X2ArmorTemplate(ItemTemplate);
		GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);

		if(class'X2TacticalGameRulesetDataStructures'.static.InventorySlotIsEquipped(Slot))
		{
			if (IsSoldier() && WeaponTemplate != none)
			{
				if (!GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate))
					return false;
			}

			if (IsSoldier() && ArmorTemplate != none)
			{
				if (!GetSoldierClassTemplate().IsArmorAllowedByClass(ArmorTemplate))
					return false;
			}

			if (!IsMPCharacter() && !RespectsUniqueRule(ItemTemplate, Slot, CheckGameState))
				return false;
		}

		switch(Slot)
		{
		case eInvSlot_Loot:
		case eInvSlot_Backpack: 
			return true;
		case eInvSlot_Mission:
			return GetItemInSlot(eInvSlot_Mission) == none;
		case eInvSlot_Utility:
			iUtility = 0;
			for (i = 0; i < InventoryItems.Length; ++i)
			{
				kItem = GetItemGameState(InventoryItems[i], CheckGameState);
				if (kItem != none && kItem.InventorySlot == eInvSlot_Utility)
					iUtility += kItem.GetItemSize();
			}
			if(GetMPCharacterTemplate() != none)
			{
				return iUtility + ItemTemplate.iItemSize <= GetMPCharacterTemplate().NumUtilitySlots;
			}
			return (iUtility + ItemTemplate.iItemSize <= GetCurrentStat(eStat_UtilityItems));
		case eInvSlot_GrenadePocket:
			if (!HasGrenadePocket())
				return false;
			if (GetItemInSlot(eInvSlot_GrenadePocket, CheckGameState) != none)
				return false;
			return (GrenadeTemplate != none);
		case eInvSlot_AmmoPocket:
			if (!HasAmmoPocket())
				return false;
			if (GetItemInSlot(eInvSlot_AmmoPocket, CheckGameState) != none)
				return false;
			return ItemTemplate.ItemCat == 'ammo';
		case eInvSlot_HeavyWeapon:
			// Start Issue #171
			NumHeavy = GetNumHeavyWeapons(CheckGameState);
			if (NumHeavy == 0)
				return false;
			if (WeaponTemplate ==  none)
				return false;
			return GetAllItemsInSlot(eInvSlot_HeavyWeapon, CheckGameState).Length < NumHeavy;
			// End Issue #171
		case eInvSlot_CombatSim:
			return (ItemTemplate.ItemCat == 'combatsim' && GetCurrentStat(eStat_CombatSims) > 0);
		default:
			// Issue #118 Start
			if (class'CHItemSlot'.static.SlotIsTemplated(Slot))
			{
				// TODO: Update with #114, ItemState
				return class'CHItemSlot'.static.GetTemplateForSlot(Slot).CanAddItemToSlot(self, ItemTemplate, CheckGameState, Quantity);
			}
			// Issue #118 End
			return (GetItemInSlot(Slot, CheckGameState) == none);
		}
	}
	return false;
}

public function bool RespectsUniqueRule(const X2ItemTemplate ItemTemplate, const EInventorySlot Slot, optional XComGameState CheckGameState, optional int SkipObjectID)
{
	local int i;
	local bool bUniqueCat;
	local bool bUniqueWeaponCat;
	local XComGameState_Item kItem;
	local X2ItemTemplate UniqueItemTemplate;
	local X2WeaponTemplate WeaponTemplate, UniqueWeaponTemplate;
	local X2ItemTemplatemanager ItemTemplateManager;

	if (!class'X2TacticalGameRulesetDataStructures'.static.InventorySlotBypassesUniqueRule(Slot))
	{
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
		bUniqueCat = ItemTemplateManager.ItemCategoryIsUniqueEquip(ItemTemplate.ItemCat);

		WeaponTemplate = X2WeaponTemplate(ItemTemplate);
		if (!bUniqueCat && WeaponTemplate != none)
			bUniqueWeaponCat = ItemTemplateManager.ItemCategoryIsUniqueEquip(WeaponTemplate.WeaponCat);
	
		if (bUniqueCat || bUniqueWeaponCat)
		{
			for (i = 0; i < InventoryItems.Length; ++i)
			{
				if(InventoryItems[i].ObjectID == SkipObjectID)
					continue;

				kItem = GetItemGameState(InventoryItems[i], CheckGameState);
				if (kItem != none)
				{
					if (class'X2TacticalGameRulesetDataStructures'.static.InventorySlotBypassesUniqueRule(kItem.InventorySlot))
						continue;

					UniqueItemTemplate = kItem.GetMyTemplate();
					if (bUniqueCat)
					{
						if (UniqueItemTemplate.ItemCat == ItemTemplate.ItemCat)
							return false;
					}
					if (bUniqueWeaponCat)
					{
						UniqueWeaponTemplate = X2WeaponTemplate(UniqueItemTemplate);
						if (UniqueWeaponTemplate != none && UniqueWeaponTemplate.WeaponCat == WeaponTemplate.WeaponCat)
							return false;
					}
				}
			}
		}
	}

	return true;
}

protected simulated function bool AddItemToBackpack(XComGameState_Item Item, XComGameState NewGameState)
{
	local array<XComGameState_Item> BackpackItems;
	local XComGameState_Item BackpackItem, NewBackpackItem;
	local X2ItemTemplate ItemTemplate;
	local int AvailableQuantity, UseQuantity;

	//  First look to distribute all available quantity into existing stacks
	ItemTemplate = Item.GetMyTemplate();
	BackpackItems = GetAllItemsInSlot(eInvSlot_Backpack, NewGameState);
	foreach BackpackItems(BackpackItem)
	{
		AvailableQuantity = 0;
		if (BackpackItem.GetMyTemplate() == ItemTemplate)
		{
			if (BackpackItem.Quantity < ItemTemplate.MaxQuantity)
			{
				AvailableQuantity = ItemTemplate.MaxQuantity - BackpackItem.Quantity;
				UseQuantity = min(AvailableQuantity, Item.Quantity);
				NewBackpackItem = XComGameState_Item(NewGameState.ModifyStateObject(BackpackItem.Class, BackpackItem.ObjectID));
				NewBackpackItem.Quantity += UseQuantity;
				Item.Quantity -= UseQuantity;
				if (Item.Quantity < 1)
					break;
			}
		}
	}
	if (Item.Quantity < 1)
	{
		//  item should be destroyed as it was collated into other existing items
		NewGameState.RemoveStateObject(Item.ObjectID);
	}
	else
	{
		InventoryItems.AddItem(Item.GetReference());
		ModifyCurrentStat(eStat_BackpackSize, -Item.GetItemSize());
	}	
	return true;
}

simulated function ApplyCombatSimStats(XComGameState_Item CombatSim, optional bool bLookupBonus = true, optional bool bForceBonus = false)
{
	local bool bHasBonus, bWasInjured;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local float MaxStat, NewMaxStat, NewCurrentStat;
	local int i, Boost;

	History = `XCOMHISTORY;
	bHasBonus = bForceBonus;
	if (bLookupBonus && !bHasBonus)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		if (XComHQ != none)
		{
			bHasBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;
		}
	}
	bWasInjured = IsInjured();
	for(i = 0; i < CombatSim.StatBoosts.Length; i++)
	{
		Boost = CombatSim.StatBoosts[i].Boost;
		if (bHasBonus)
		{
			if (X2EquipmentTemplate(CombatSim.GetMyTemplate()).bUseBoostIncrement)
				Boost += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement;
			else
				Boost += Round(Boost * class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostValue);
		}

		if ((CombatSim.StatBoosts[i].StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
		{
			Boost *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
		}

		MaxStat = GetMaxStat(CombatSim.StatBoosts[i].StatType);
		NewMaxStat = MaxStat + Boost;
		NewCurrentStat = int(GetCurrentStat(CombatSim.StatBoosts[i].StatType)) + Boost;
		SetBaseMaxStat(CombatSim.StatBoosts[i].StatType, NewMaxStat);

		if(CombatSim.StatBoosts[i].StatType != eStat_HP || !bWasInjured)
		{
			SetCurrentStat(CombatSim.StatBoosts[i].StatType, NewCurrentStat);
		}
	}
}

simulated function UnapplyCombatSimStats(XComGameState_Item CombatSim, optional bool bLookupBonus = true)
{
	local bool bHasBonus;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local float MaxStat, NewMaxStat;
	local int i, Boost, NewCurrentStat;

	History = `XCOMHISTORY;
	if (bLookupBonus)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		if (XComHQ != none)
		{
			bHasBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;
		}
	}
	for (i = 0; i < CombatSim.StatBoosts.Length; ++i)
	{
		Boost = CombatSim.StatBoosts[i].Boost;
		if (bHasBonus)
		{
			if (X2EquipmentTemplate(CombatSim.GetMyTemplate()).bUseBoostIncrement)
				Boost += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement;
			else
				Boost += Round(Boost * class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostValue);
		}

		if ((CombatSim.StatBoosts[i].StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
		{
			Boost *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
		}

		MaxStat = GetMaxStat(CombatSim.StatBoosts[i].StatType);
		NewMaxStat = MaxStat - Boost;
		NewCurrentStat = int(GetCurrentStat(CombatSim.StatBoosts[i].StatType)) - Boost;
		SetBaseMaxStat(CombatSim.StatBoosts[i].StatType, NewMaxStat);

		if(GetCurrentStat(CombatSim.StatBoosts[i].StatType) > NewCurrentStat)
		{
			SetCurrentStat(CombatSim.StatBoosts[i].StatType, NewCurrentStat);
		}
	}
}

simulated function bool RemoveItemFromInventory(XComGameState_Item Item, optional XComGameState ModifyGameState)
{
	local X2ItemTemplate ItemTemplate;
	local X2ArmorTemplate ArmorTemplate;
	local int RemoveIndex;

	if (CanRemoveItemFromInventory(Item, ModifyGameState))
	{				
		RemoveIndex = InventoryItems.Find('ObjectID', Item.ObjectID);
		`assert(RemoveIndex != INDEX_NONE);

		ItemTemplate = Item.GetMyTemplate();

		// If the item to remove is armor and this unit is a soldier, store appearance settings
		ArmorTemplate = X2ArmorTemplate(ItemTemplate);
		if (ArmorTemplate != none && IsSoldier())
		{
			StoreAppearance(kAppearance.iGender, ArmorTemplate.DataName);
		}

		if( ItemTemplate.OnUnequippedFn != None )
		{
			ItemTemplate.OnUnequippedFn(Item, self, ModifyGameState);

			//  find the removed item again, in case it got handled somehow in the above
			RemoveIndex = InventoryItems.Find('ObjectID', Item.ObjectID);
			if (RemoveIndex == INDEX_NONE)          //  must have been removed already, although that's kind of naughty
			{
				`RedScreen("Attempt to remove item" @ Item.GetMyTemplateName() @ "properly may have failed due to OnUnequippedFn -jbouscher @gameplay");
			}
		}		

		if (RemoveIndex != INDEX_NONE)
			InventoryItems.Remove(RemoveIndex, 1);

		Item.OwnerStateObject.ObjectID = 0;

		switch(Item.InventorySlot)
		{
		case eInvSlot_Armor:
			// Start Issue #171
			if(!IsMPCharacter())
			{
				RealizeItemSlotsCount(ModifyGameState);
			}
			// End Issue #171
			break;
		case eInvSlot_Backpack:
			ModifyCurrentStat(eStat_BackpackSize, Item.GetItemSize());
			break;
		case eInvSlot_CombatSim:
			UnapplyCombatSimStats(Item);
			break;
		default:
			// Issue #118 Start
			if (class'CHItemSlot'.static.SlotIsTemplated(Item.InventorySlot))
			{
				class'CHItemSlot'.static.GetTemplateForSlot(Item.InventorySlot).RemoveItemFromSlot(self, Item, ModifyGameState);
			}
			// Issue #118 End
		}

		Item.InventorySlot = eInvSlot_Unknown;
		return true;
	}
	return false;
}

simulated function bool CanRemoveItemFromInventory(XComGameState_Item Item, optional XComGameState CheckGameState)
{
	local name TemplateName;
	local StateObjectReference Ref;

	// Check for bad items due to outdated saves
	if(Item.GetMyTemplate() == none)
		return true;

	//	always let focus loot get removed - it's a temporary pick up only
	if (X2FocusLootItemTemplate(Item.GetMyTemplate()) != none)
		return true;

	if (Item.GetItemSize() == 0)
		return false;

	TemplateName = Item.GetMyTemplateName();
	if(IsMPCharacter() && ItemIsInMPBaseLoadout(TemplateName) && GetNumItemsByTemplateName(TemplateName, CheckGameState) == 1)
		return false;

	foreach InventoryItems(Ref)
	{
		if (Ref.ObjectID == Item.ObjectID)
		// Issue #118 Start, was return true;
		{
			if (class'CHItemSlot'.static.SlotIsTemplated(Item.InventorySlot))
			{
				return class'CHItemSlot'.static.GetTemplateForSlot(Item.InventorySlot).CanRemoveItemFromSlot(self, Item, CheckGameState);
			}
			else
			{
				return true;
			}
		}
		// Issue #118 End
			
	}
	return false;
}

simulated function bool ItemIsInMPBaseLoadout(name ItemTemplateName)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem LoadoutItem;
	local bool bFoundLoadout;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemTemplateManager.Loadouts(Loadout)
	{
		if (Loadout.LoadoutName == m_MPCharacterTemplate.Loadout)
		{
			bFoundLoadout = true;
			break;
		}
	}
	if (bFoundLoadout)
	{
		foreach Loadout.Items(LoadoutItem)
		{
			if(LoadoutItem.Item == ItemTemplateName)
				return true;
		}
	}

	return false;
}

simulated function int GetNumItemsByTemplateName(name ItemTemplateName, optional XComGameState CheckGameState)
{
	local int i, NumItems;
	local XComGameState_Item Item;
	NumItems = 0;
	for (i = 0; i < InventoryItems.Length; ++i)
	{
		Item = GetItemGameState(InventoryItems[i], CheckGameState);
		if(Item != none && Item.GetMyTemplateName() == ItemTemplateName)
			NumItems++;
	}
	return NumItems;
}

simulated function array<XComGameState_Item> GetAllInventoryItems(optional XComGameState CheckGameState, optional bool bExcludePCS = false)
{
	local int i;
	local XComGameState_Item Item;
	local array<XComGameState_Item> Items;

	for (i = 0; i < InventoryItems.Length; ++i)
	{
		Item = GetItemGameState(InventoryItems[i], CheckGameState);

		if(Item != none && (!bExcludePCS || (bExcludePCS && Item.GetMyTemplate().ItemCat != 'combatsim')))
		{
			Items.AddItem(Item);
		}
	}
	return Items;
}

simulated function bool HasItemOfTemplateClass(class<X2ItemTemplate> TemplateClass, optional XComGameState CheckGameState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;

	Items = GetAllInventoryItems(CheckGameState);
	foreach Items(Item)
	{
		if(Item.GetMyTemplate().Class == TemplateClass)
		{
			return true;
		}
	}

	return false;
}
simulated function bool HasItemOfTemplateType(name TemplateName, optional XComGameState CheckGameState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;

	Items = GetAllInventoryItems(CheckGameState);
	foreach Items(Item)
	{
		if(Item.GetMyTemplateName() == TemplateName)
		{
			return true;
		}
	}

	return false;
}

simulated function bool HasLoadout(name LoadoutName, optional XComGameState CheckGameState)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem LoadoutItem;
	local bool bFoundLoadout;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach ItemTemplateManager.Loadouts(Loadout)
	{
		if(Loadout.LoadoutName == LoadoutName)
		{
			bFoundLoadout = true;
			break;
		}
	}

	if(bFoundLoadout)
	{
		foreach Loadout.Items(LoadoutItem)
		{
			if(!HasItemOfTemplateType(LoadoutItem.Item, CheckGameState))
			{
				return false;
			}
		}

		return true;
	}

	return false;
}

/**
 *  Functions below here are for querying this XComGameState_Unit's template data.
 *  These functions can return results that are not exactly the template data if instance data overrides it,
 *  so if you really need the pure template data you'll have to call GetMyTemplate() and look at it yourself.
 */

simulated function bool CanBeCriticallyWounded()
{
	return GetMyTemplate().bCanBeCriticallyWounded;
}

simulated function bool CanBeTerrorist()
{
	return GetMyTemplate().bCanBeTerrorist;
}

simulated function class<XGAIBehavior> GetBehaviorClass()
{
	return GetMyTemplate().BehaviorClass;
}

simulated event bool IsChosen()
{
	return GetMyTemplate().bIsChosen;
}

simulated native function bool IsAdvent() const;

simulated native function bool IsAlien() const;
simulated native function bool IsNonHumanoidAlien() const;

simulated native function bool IsTurret() const;

// Required for specialized ACV alien heads.
simulated function int IsACV()
{
	local name TemplateName;
	TemplateName = GetMyTemplateName();
	switch (TemplateName)
	{
		case 'ACV':
			return 1;
		break;
		
		case 'ACVCannonChar':
			return 2;
		break;
		
		case 'ACVTreads':
			return 3;
		break;
		
		default:
			return 0;
		break;
	}
}

simulated function bool IsAfraidOfFire()
{
	return GetMyTemplate().bIsAfraidOfFire && !IsImmuneToDamage('Fire');
}

simulated event bool IsPsionic()
{
	return GetMyTemplate().bIsPsionic || IsPsiOperative();
}

simulated function bool HasScorchCircuits()
{
	return FindAbility('ScorchCircuits').ObjectID != 0;
}

simulated function bool IsMeleeOnly()
{
	return GetMyTemplate().bIsMeleeOnly;
}

simulated native function bool IsCivilian() const;
simulated native function bool IsRobotic() const;
simulated native function bool IsSoldier() const;
simulated native function bool IsEngineer() const;
simulated native function bool IsScientist() const;
simulated native function bool IsResistanceHero() const;
simulated native function bool CanScamper() const;
simulated native function bool CanTakeCover() const;
simulated native function bool IsDead() const;
simulated native function bool IsAlive() const;
simulated native function bool IsBleedingOut() const;
simulated native function bool IsStasisLanced() const;
simulated native function bool IsUnconscious() const;
simulated native function bool IsBurning() const;
simulated native function bool IsAcidBurning() const;
simulated native function bool IsConfused() const;
simulated native function bool IsDisoriented() const;
simulated native function bool IsPoisoned() const;
simulated native function bool IsInStasis() const;
simulated native function bool IsUnitAffectedByEffectName(name EffectName) const;
simulated native function XComGameState_Effect GetUnitAffectedByEffectState(name EffectName) const;
simulated native function bool IsUnitAffectedByDamageType(name DamageType) const;
simulated native function bool IsUnitApplyingEffectName(name EffectName) const;
simulated native function XComGameState_Effect GetUnitApplyingEffectState(name EffectName) const;
simulated native function bool IsImpaired(optional bool bIgnoreStunned) const;
simulated native function bool IsInCombat() const;
simulated native function bool IsPanicked() const;
simulated native function bool UsesWillSystem() const;
simulated native function bool CanEarnXp() const;
simulated native function float GetXpKillscore() const;
simulated native function int GetDirectXpAmount() const;
simulated native function bool HasClearanceToMaxZ() const;
simulated native function bool IsStunned() const;
simulated native function bool IsDazed() const;
simulated native function bool IsFrozen() const;
simulated native function bool IsInVoidConduit() const;
simulated native function bool IsIncapacitated() const;
simulated native function bool IsMindControlled() const;
simulated native function ETeam GetPreviousTeam() const;        //  if mind controlled, the team the unit was on before being mind controlled. otherwise, the current team.
simulated native function bool BlocksPathingWhenDead() const;
simulated native function bool IsBlind() const;
simulated native function int GetTemplarFocusLevel() const;
simulated native function XComGameState_Effect_TemplarFocus GetTemplarFocusEffectState() const;
simulated native function bool IsDeadFromSpecialDeath() const;

simulated native private function bool IsUnitAffectedByNonBreaksConcealmentEffect() const;

simulated native function bool IsAbleToAct(bool bSkipPanickedCheck=false) const;
//{
//	return IsAlive() && !IsIncapacitated() && !IsStunned() && !IsPanicked() && !IsDazed();
//}

simulated function AddAffectingEffect(XComGameState_Effect Effect)
{
	AffectedByEffects.AddItem(Effect.GetReference());
	AffectedByEffectNames.AddItem(Effect.GetX2Effect().EffectName);
}

simulated function RemoveAffectingEffect(XComGameState_Effect Effect)
{
	local int Idx;
	local name strName;

	Idx = AffectedByEffects.Find('ObjectID', Effect.ObjectID);
	if(Idx != INDEX_NONE)
	{
		AffectedByEffectNames.Remove(Idx, 1);
		AffectedByEffects.Remove(Idx, 1);
	}
	else
	{
		`Redscreen("AffectedByEffectNames: No effect found-" @Effect @"Name:"@ Effect.GetX2Effect().EffectName@"\nArray length:" @AffectedByEffectNames.Length); 
		foreach AffectedByEffectNames(strName)
		{
			`Redscreen("EffectName:"@strName); 
		}
	}
}

simulated function AddAppliedEffect(XComGameState_Effect Effect)
{
	AppliedEffects.AddItem(Effect.GetReference());
	AppliedEffectNames.AddItem(Effect.GetX2Effect().EffectName);
}

simulated function RemoveAppliedEffect(XComGameState_Effect Effect)
{
	local int Idx;
	local name strName;

	Idx = AppliedEffects.Find('ObjectID', Effect.ObjectID);
	if (Idx != INDEX_NONE)
	{
		AppliedEffectNames.Remove(Idx, 1);
		AppliedEffects.Remove(Idx, 1);
	}
	else
	{
		`Redscreen("AppliedEffectNames: No effect found-" @Effect @"Name:"@ Effect.GetX2Effect().EffectName@"\nArray length:" @AppliedEffectNames.Length); 
		foreach AppliedEffectNames(strName)
		{
			`Redscreen("EffectName:"@strName); 
		}
	}
}

simulated function bool IsHunkeredDown()
{
	return IsUnitAffectedByEffectName('HunkerDown');
}

native function bool IsInGreenAlert() const;
native function bool ShouldAvoidPathingNearCover() const;
native function bool ShouldAvoidWallSmashPathing() const;
native function bool ShouldAvoidDestructionPathing() const;
native function bool ShouldExtraAvoidDestructionPathing() const;

simulated native function bool IsBeingCarried();
simulated native function bool CanBeCarried();

native function bool IsImmuneToDamageCharacterTemplate(name DamageType) const;

event bool IsImmuneToDamage(name DamageType)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	
	if( IsImmuneToDamageCharacterTemplate(DamageType) )
	{
		return true;
	}

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState.GetX2Effect().ProvidesDamageImmunity(EffectState, DamageType))
			return true;
	}
	return false;
}

event bool IsAlreadyTakingEffectDamage(name DamageType)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState.GetX2Effect().DamageTypes.Find(DamageType) != INDEX_NONE)
			return true;
	}
	return false;
}

native function bool IsImmuneToWorldHazard(name WorldEffectName) const;

native function bool IsPlayerControlled() const;
simulated native function bool ControllingPlayerIsAI() const;

delegate SubSystemFnPtr(XComGameState_Unit kSubsystem);

function SetControllingPlayerSub(XComGameState_Unit kSubsystem)
{
	kSubsystem.SetControllingPlayer(ControllingPlayer);
}

simulated function SetControllingPlayer( StateObjectReference kPlayerRef )
{
	local bool ShouldTriggerEvent;
	local XComGameState_Unit PreviousState;

	//We should trigger an event if this is a team change (i.e. not initial setup).
	//So, check that the unit exists previously.
	PreviousState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	if (PreviousState != None && PreviousState != self && kPlayerRef != ControllingPlayer)
		ShouldTriggerEvent = true;

	`assert( kPlayerRef.ObjectID != 0 );
	ControllingPlayer = kPlayerRef;
	bRequiresVisibilityUpdate = true; //Changing teams requires updated visibility

	//Actually trigger the event, only after we've actually altered ControllingPlayer
	if (ShouldTriggerEvent)
		`XEVENTMGR.TriggerEvent('UnitChangedTeam', self, self, XComGameState(Outer));
}

simulated function ApplyToSubsystems( delegate<SubSystemFnPtr> FunctionPtr)
{
	local XComGameState_Unit kSubsystem;
	local int ComponentID;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	if (!m_bSubsystem)
	{
		foreach ComponentObjectIds(ComponentID)
		{
			kSubsystem = XComGameState_Unit(History.GetGameStateForObjectID(ComponentID));
			if (kSubsystem != None)
			{
				FunctionPtr(kSubsystem);
			}
		}
	}
}

simulated native function bool WasConcealed(int HistoryIndex) const;
simulated native function bool IsSpotted() const;
simulated native function bool IsConcealed() const;
simulated native function bool IsSuperConcealed() const;
simulated native function bool IsIndividuallyConcealed() const;
simulated native function bool IsSquadConcealed() const;
//  IMPORTANT: Only X2Effect_RangerStealth should call this function. Otherwise, the rest of the gameplay stuff won't be in sync with the bool!!!
simulated native function SetIndividualConcealment(bool bIsConcealed, XComGameState NewGameState);

event OnConcealmentEntered(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.TriggerEvent('UnitConcealmentEntered', ThisObj, ThisObj, NewGameState);

	// clear the concealment breaker ref whenever we enter concealment
	ConcealmentBrokenByUnitRef.ObjectID = -1;
	//  reset chance to lose super concealment
	SuperConcealmentLoss = 0;
}

event OnConcealmentBroken(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.TriggerEvent('UnitConcealmentBroken', ThisObj, ThisObj, NewGameState);
	
	//  reset chance to lose super concealment
	//SuperConcealmentLoss = 0;
}

function RankUpTacticalVisualization()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Rank Up");
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForRankUp;

	NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID);

	//Award rank up after the action has completed that granted it
	NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);

	`TACTICALRULES.SubmitGameState(NewGameState);
}

function BuildVisualizationForRankUp(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local X2Action_PlayMessageBanner MessageAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameState_Unit UnitState;
	local string Display, Title, SoldierName, Subtitle, RankIcon;
	local XGParamTag LocTag;

	History = `XCOMHISTORY;

	// Add a track for the instigator
	//****************************************************************************************
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		// the first unit is the instigating unit for this block
		break;
	}

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = UnitState;
	ActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);

	
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = class'X2ExperienceConfig'.static.GetRankName(UnitState.GetSoldierRank() + 1, Unitstate.GetSoldierClassTemplateName());

	// show the event notices message
	Title = class'UIEventNoticesTactical'.default.RankUpMessage;
	Subtitle = `XEXPAND.ExpandString(class'UIEventNoticesTactical'.default.RankUpSubtitle);
	SoldierName = UnitState.GetName(eNameType_RankFull);
	RankIcon = class'UIUtilities_Image'.static.GetRankIcon(UnitState.GetSoldierRank() + 1, Unitstate.GetSoldierClassTemplateName());

	MessageAction = X2Action_PlayMessageBanner(class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	MessageAction.AddMessageBanner(Title, RankIcon, SoldierName, Subtitle, eUIState_Good);
	MessageAction.bDontPlaySoundEvent = true; // the rank up audio plays below

	// play the revealed flyover on the instigator
	Display = Repl(class'UIEventNoticesTactical'.default.RankUpMessage, "%NAME", UnitState.GetName(eNameType_FullNick));

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundFX.SoldierPromotedCue', Display, '', eColor_Good); 
}

function EnterConcealment()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Concealment Gained");
	EnterConcealmentNewGameState(NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

function EnterConcealmentNewGameState(XComGameState NewGameState)
{
	local XComGameState_Unit NewUnitState;

	if( NewGameState.GetContext().PostBuildVisualizationFn.Find(BuildVisualizationForConcealment_Entered_Individual) == INDEX_NONE ) // we only need to visualize this once
	{
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BuildVisualizationForConcealment_Entered_Individual);
	}

	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));
	NewUnitState.SetIndividualConcealment(true, NewGameState);
}

function BreakConcealment(optional XComGameState_Unit ConcealmentBreaker, optional bool UnitWasFlanked)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Concealment Broken");
	BreakConcealmentNewGameState(NewGameState, ConcealmentBreaker, UnitWasFlanked);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

function BreakConcealmentNewGameState(XComGameState NewGameState, optional XComGameState_Unit ConcealmentBreaker, optional bool UnitWasFlanked)
{
	local XComGameState_Unit NewUnitState, UnitState;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local bool bRetainConcealment;

	History = `XCOMHISTORY;

	if( NewGameState.GetContext().PostBuildVisualizationFn.Find(BuildVisualizationForConcealment_Broken_Individual) == INDEX_NONE ) // we only need to visualize this once
	{
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BuildVisualizationForConcealment_Broken_Individual);
	}

	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));
	NewUnitState.SetIndividualConcealment(false, NewGameState);
	if( ConcealmentBreaker != None )
	{
		NewUnitState.ConcealmentBrokenByUnitRef = ConcealmentBreaker.GetReference();
		NewUnitState.bUnitWasFlanked = UnitWasFlanked;
	}

	// break squad concealment
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(ControllingPlayer.ObjectID));
	if( PlayerState.bSquadIsConcealed )
	{
		PlayerState = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', PlayerState.ObjectID));
		PlayerState.bSquadIsConcealed = false;

		`XEVENTMGR.TriggerEvent('SquadConcealmentBroken', PlayerState, PlayerState, NewGameState);

		// break concealment on each other squad member
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.ControllingPlayer.ObjectID == PlayerState.ObjectID )
			{
				bRetainConcealment = false;

				if( UnitState.IsIndividuallyConcealed() )
				{
					foreach UnitState.AffectedByEffects(EffectRef)
					{
						EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
						if( EffectState != none )
						{
							if( EffectState.GetX2Effect().RetainIndividualConcealment(EffectState, UnitState) )
							{
								bRetainConcealment = true;
								break;
							}
						}
					}
				}

				if( !bRetainConcealment )
				{
					NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
					NewUnitState.SetIndividualConcealment(false, NewGameState);
				}
			}
		}
	}
}


//Different wrappers because we need to pass these as delegates and can't simply curry the one function

private function BuildVisualizationForConcealment_Entered_Individual(XComGameState VisualizeGameState)
{	BuildVisualizationForConcealmentChanged(VisualizeGameState, true);	}

private function BuildVisualizationForConcealment_Broken_Individual(XComGameState VisualizeGameState)
{	BuildVisualizationForConcealmentChanged(VisualizeGameState, false);	}

simulated static function BuildVisualizationForConcealmentChanged(XComGameState VisualizeGameState, bool NowConcealed)
{
	local XComGameStateHistory History;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_UpdateUI UIUpdateAction;
	local X2Action_CameraLookAt LookAtAction;	
	local X2Action_ConnectTheDots ConnectTheDots;
	local X2Action_Delay DelayAction;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameState_Unit ConcealmentChangeFocusUnitState;
	local XComGameState_Unit UnitState, OldUnitState;
	local XComGameState_Player PlayerState, OldPlayerState;
	local array<XComGameState_Unit> AllConcealmentChangedUnitStates;
	local XComGameStateContext Context;
	local bool bIsSquadConcealEvent;
	local int UnitIndex;
	local bool bCreatedConcealBreakerTracks;
	local X2Action_WaitForAbilityEffect WaitAction;
	local float LookAtDuration;

	LookAtDuration = 0.5f;

	History = `XCOMHISTORY;
	Context = VisualizeGameState.GetContext();

	// determine the best concealment-changed unit to focus the event on
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		OldUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
		if( UnitState.IsIndividuallyConcealed() != OldUnitState.IsIndividuallyConcealed() )
		{
			AllConcealmentChangedUnitStates.AddItem(UnitState);

			if( ConcealmentChangeFocusUnitState == None || UnitState.ConcealmentBrokenByUnitRef.ObjectID > 0 )
			{
				ConcealmentChangeFocusUnitState = UnitState;
			}
		}
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		OldPlayerState = XComGameState_Player(History.GetGameStateForObjectID(PlayerState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
		if (PlayerState.bSquadIsConcealed != OldPlayerState.bSquadIsConcealed)
		{
			bIsSquadConcealEvent = true;
			break;
		}
	}

	//Add a track for each revealed unit.
	for (UnitIndex = 0; UnitIndex < AllConcealmentChangedUnitStates.Length; UnitIndex++)
	{
		UnitState = AllConcealmentChangedUnitStates[UnitIndex];

		if (UnitState.GetMyTemplate().bIsCosmetic)
			continue;


		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);

		//The instigator gets special treatment.  For Individual reveal events, every unit is the instigator
		if( UnitState == ConcealmentChangeFocusUnitState || !bIsSquadConcealEvent )
		{
			// if a specific enemy broke concealment, draw a visible connection between that unit and this
			if (UnitState.ConcealmentBrokenByUnitRef.ObjectID > 0 && !bCreatedConcealBreakerTracks)
			{
				// Only crate concealmentbreakertracks once
				bCreatedConcealBreakerTracks = true;
				CreateConcealmentBreakerTracks(VisualizeGameState, UnitState);

				// Unit must wait for concealment breaker tracks to signal us
				class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);	
			}
			else if (!bIsSquadConcealEvent && UnitIndex != 0)
			{
				// If we are not a squad conceal event and we're not the first unit, we need to wait for the previous unit to send us a message before we proceed so the units actions
				// advance in sequence rather than simultaneously
				WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				WaitAction.ChangeTimeoutLength(12.0f + UnitIndex * 2);
			}

			// Camera pan to the instigator
			// wait for the camera to arrive
			LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			LookAtAction.LookAtObject = UnitState;
			LookAtAction.UseTether = false;
			LookAtAction.BlockUntilActorOnScreen = true;
			LookAtAction.LookAtDuration = LookAtDuration;

			// animate in the HUD status update
			UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			if (`TUTORIAL != none)
			{
				// Needs to be set for the tutorial to enter concealement at the proper time because an active unit is not set when this is visualized
				UIUpdateAction.SpecificID = UnitState.ObjectID; 
			}
			UIUpdateAction.UpdateType = EUIUT_HUD_Concealed;

			// update the concealment flag on all revealed units
			UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			UIUpdateAction.SpecificID = -1;
			UIUpdateAction.UpdateType = EUIUT_UnitFlag_Concealed;			

			//Instigator gets flyover with sound
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			if (NowConcealed)
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundTacticalUI.Concealment_Concealed_Cue', class'X2StatusEffects'.default.ConcealedFriendlyName, bIsSquadConcealEvent ? 'EnterSquadConcealment' : '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Concealed);
				//	jbouscher: removing delay per Jake
				//if( UnitState.IsUnitAffectedByEffectName(class'X2Effect_Shadow'.default.EffectName) )
				//{
				//	SoundAndFlyOver.BlockUntilFinished = true;
				//	SoundAndFlyOver.DelayDuration = 3.0f;
				//}
			}
			else
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundTacticalUI.Concealment_Unconcealed_Cue', class'X2StatusEffects'.default.RevealedFriendlyName, bIsSquadConcealEvent ? 'SquadConcealmentBroken' : 'ConcealedSpotted', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Revealed);
			}

			// pause a few seconds
			DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			DelayAction.Duration = bIsSquadConcealEvent ? 0.5 : LookAtDuration;

			// cleanup the connect the dots vis if there was one
			if( UnitState.ConcealmentBrokenByUnitRef.ObjectID > 0 )
			{
				ConnectTheDots = X2Action_ConnectTheDots(class'X2Action_ConnectTheDots'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				ConnectTheDots.bCleanupConnection = true;
			}
		}
		else
		{
			//Everyone else waits for the instigator
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

			//Everyone else, if we're showing them, just gets visual flyovers
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			if (NowConcealed)
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'X2StatusEffects'.default.ConcealedFriendlyName, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Concealed);
			}
			else
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'X2StatusEffects'.default.RevealedFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Revealed);
			}
		}

		//Update flashlight status on everyone (turn on lights if revealed)
		class'X2Action_UpdateFlashlight'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

		//Subsequent units are not the instigator.
			}
}

static function CreateConcealmentBreakerTracks(XComGameState VisualizeGameState, XComGameState_Unit UnitState)
{
	local VisualizationActionMetadata ConcealmentBreakerBuildTrack;
	local TTile UnitTileLocation;
	local Vector UnitLocation;
	local VisualizationActionMetadata EmptyTrack;
	local XComGameStateHistory History;
	local XComGameState_Unit ConcealmentBrokenByUnitState;
	local X2Action_MoveTurn MoveTurnAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_ConnectTheDots ConnectTheDots;
	local X2Action_Delay DelayAction;	
	local XComGameStateContext Context;
	local X2Action_PlayEffect EffectAction;
	local XComGameState_AIGroup AIGroup;
	local XComGameStateContext_Ability AbilityInterrupted;
	local int scan;
	local PathingInputData CurrentPathData;

	History = `XCOMHISTORY;
	Context = VisualizeGameState.GetContext();

	UnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
	UnitLocation = `XWORLD.GetPositionFromTileCoordinates(UnitTileLocation);

	// visualization of the concealment breaker
	ConcealmentBrokenByUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ConcealmentBrokenByUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex));

	ConcealmentBreakerBuildTrack = EmptyTrack;
	ConcealmentBreakerBuildTrack.StateObject_OldState = History.GetGameStateForObjectID(ConcealmentBrokenByUnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ConcealmentBreakerBuildTrack.StateObject_NewState = ConcealmentBrokenByUnitState;
	ConcealmentBreakerBuildTrack.VisualizeActor = History.GetVisualizer(ConcealmentBrokenByUnitState.ObjectID);

	// connect the dots
	ConnectTheDots = X2Action_ConnectTheDots(class'X2Action_ConnectTheDots'.static.AddToVisualizationTree(ConcealmentBreakerBuildTrack, Context));
	ConnectTheDots.bCleanupConnection = false;
	ConcealmentBrokenByUnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
	ConnectTheDots.SourceLocation = `XWORLD.GetPositionFromTileCoordinates(UnitTileLocation);
	ConnectTheDots.TargetLocation = UnitLocation;

	// center the camera on the enemy group for a few seconds and clear the FOW
	AIGroup = ConcealmentBrokenByUnitState.GetGroupMembership(VisualizeGameState, VisualizeGameState.HistoryIndex);
	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ConcealmentBreakerBuildTrack, Context));
	EffectAction.CenterCameraOnEffectDuration = 1.25f;
	EffectAction.RevealFOWRadius = class'XComWorldData'.const.WORLD_StepSize * 5.0f;
	EffectAction.FOWViewerObjectID = UnitState.ObjectID; //Setting this to be a unit makes it possible for the FOW viewer to reveal units
	EffectAction.EffectLocation = AIGroup != none ? AIGroup.GetGroupMidpoint(VisualizeGameState.HistoryIndex) : ConcealmentBrokenByUnitState.GetVisualizer().Location;
	EffectAction.bWaitForCameraArrival = true;
	EffectAction.bWaitForCameraCompletion = false;

	// add flyover for "I Saw You!"
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ConcealmentBreakerBuildTrack, Context));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None,
		UnitState.bUnitWasFlanked ?
	class'X2StatusEffects'.default.SpottedFlankedConcealedUnitFriendlyName :
	class'X2StatusEffects'.default.SpottedConcealedUnitFriendlyName,
		'',
		eColor_Bad,
	class'UIUtilities_Image'.const.UnitStatus_Revealed, 
		, 
		, 
		, 
	class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_READY);

	// Turn to face target unit
	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ConcealmentBreakerBuildTrack, Context));
	MoveTurnAction.m_vFacePoint = UnitLocation;

	// pause a few seconds
	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ConcealmentBreakerBuildTrack, Context));
	DelayAction.Duration = 1.25;	

	AbilityInterrupted = XComGameStateContext_Ability(VisualizeGameState.ParentGameState.GetContext());
	if( AbilityInterrupted != None )
	{
		for( scan = 0; scan < AbilityInterrupted.InputContext.MovementPaths.Length; ++scan )
		{
			CurrentPathData = AbilityInterrupted.InputContext.MovementPaths[scan];
			if( CurrentPathData.MovingUnitRef.ObjectID == UnitState.ObjectID )
			{
				UnitTileLocation = CurrentPathData.MovementTiles[CurrentPathData.MovementTiles.Length - 1];
				UnitLocation = `XWORLD.GetPositionFromTileCoordinates(UnitTileLocation);
				MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ConcealmentBreakerBuildTrack, Context));
				MoveTurnAction.m_vFacePoint = UnitLocation;
				break;
			}
		}
	}
	
}

function EventListenerReturn PreAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability ActivatedAbilityStateContext;
	local XComGameState_Unit UnitState;
	local StateObjectReference OtherObjectRef;

	ActivatedAbilityStateContext = XComGameStateContext_Ability(GameState.GetContext());

	// this unit targeting enemies
	if( ActivatedAbilityStateContext.InputContext.SourceObject.ObjectID == ObjectID )
	{
		UnitState = XComGameState_Unit(GameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));

		UnitState.EnemiesInteractedWithSinceLastTurn.AddItem(ActivatedAbilityStateContext.InputContext.PrimaryTarget.ObjectID);

		foreach ActivatedAbilityStateContext.InputContext.MultiTargets(OtherObjectRef)
		{
			UnitState.EnemiesInteractedWithSinceLastTurn.AddItem(OtherObjectRef.ObjectID);
		}
	}
	//// enemy targeting this unit
	//else if( ActivatedAbilityStateContext.InputContext.PrimaryTarget.ObjectID == ObjectID ||
	//		(ActivatedAbilityStateContext.InputContext.MultiTargets.Find('ObjectID', ObjectID) != INDEX_NONE) )
	//{
	//	UnitState = XComGameState_Unit(GameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));
	//	UnitState.EnemiesInteractedWithSinceLastTurn.AddItem(ActivatedAbilityStateContext.InputContext.SourceObject.ObjectID);
	//}

	return ELR_NoInterrupt;
}

function EventListenerReturn PreGroupTurnTicked(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(GameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));
	UnitState.EnemiesInteractedWithSinceLastTurn.Length = 0;

	return ELR_NoInterrupt;
}

function int GetSuperConcealedModifier( XComGameState_Ability SelectedAbilityState, optional XComGameState GameState = none, optional int PotentialTarget )
{
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;
	local int BaseModifier, SuperConcealedModifier;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;

	History = `XCOMHISTORY;

	AbilityTemplate = SelectedAbilityState.GetMyTemplate( );

	BaseModifier = AbilityTemplate.SuperConcealmentLoss;
	if (BaseModifier == -1)
		BaseModifier = class'X2AbilityTemplateManager'.default.SuperConcealmentNormalLoss;

	SuperConcealedModifier = BaseModifier;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			EffectState.GetX2Effect().AdjustSuperConcealModifier( self, EffectState, SelectedAbilityState, GameState, BaseModifier, SuperConcealedModifier);
		}
	}

	if (SuperConcealedModifier < 0) // modifier shouldn't go below zero from effect contributions
		SuperConcealedModifier = 0;

	//	special handling for objective stuff which should always break concealment
	if (class'Helpers'.static.IsObjectiveTarget(PotentialTarget, GameState))
	{
		SuperConcealedModifier = 100;
	}

	return SuperConcealedModifier;
}

// unit makes an attack - alert to enemies with vision of the attacker
function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability ActivatedAbilityState;
	local XComGameStateContext_Ability ActivatedAbilityStateContext;
	local XComGameState_Unit SourceUnitState, EnemyInSoundRangeUnitState;
	local XComGameState_Item WeaponState;
	local int SoundRange;
	local TTile SoundTileLocation;
	local Vector SoundLocation;
	local array<StateObjectReference> Enemies;
	local StateObjectReference EnemyRef;
	local XComGameStateHistory History;
	local bool bRetainConcealment;
	local XComGameState SuperConcealedState;
	local int SuperConcealedModifier, RandRoll, Priority, ChosenActivationModifier, LostSpawnModifier;
	local XComGameState_Unit ChosenState;
	local X2AbilityTemplate AbilityTemplate;
	local X2AIBTBehaviorTree BTMgr;
	// Variables for Issue #2 Trigger an event for RetainConcealmentOnActivation
	local XComLWTuple Tuple;

	ActivatedAbilityStateContext = XComGameStateContext_Ability(GameState.GetContext());

	// do not process concealment breaks or AI alerts during interrupt processing
	if( ActivatedAbilityStateContext.InterruptionStatus == eInterruptionStatus_Interrupt )
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	ActivatedAbilityState = XComGameState_Ability(EventData);
	AbilityTemplate = ActivatedAbilityState.GetMyTemplate();

	// check for reasons to break the concealment
	if( IsConcealed() )
	{
		bRetainConcealment = ActivatedAbilityState.RetainConcealmentOnActivation(ActivatedAbilityStateContext);

		// Start Issue #2 Trigger an event for RetainConcealmentOnActivation
		Tuple = new class'XComLWTuple';
		Tuple.Id = 'RetainConcealmentOnActivation';
		Tuple.Data.Add(1);
		
		Tuple.Data[0].kind = XComLWTVBool;
		Tuple.Data[0].b = bRetainConcealment;

		`XEVENTMGR.TriggerEvent('RetainConcealmentOnActivation', Tuple, ActivatedAbilityStateContext, GameState);
		bRetainConcealment = Tuple.Data[0].b;
		// End Issue #2 Trigger an event for RetainConcealmentOnActivation

		if (bHasSuperConcealment && !bRetainConcealment)       //  ignore the usual rules for concealment and instead base it on the loss chance
		{
			if (!ActivatedAbilityState.IsAbilityTriggeredOnUnitPostBeginTacticalPlay(Priority))
			{
				//  handle changing the existing modifier if necessary
				SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.SourceObject.ObjectID));
				SuperConcealedModifier = SourceUnitState.GetSuperConcealedModifier( ActivatedAbilityState, GameState );

				if (SuperConcealedModifier > 0)
				{				
					SuperConcealedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SuperConcealmentLossChance Modified");
					SourceUnitState = XComGameState_Unit(SuperConcealedState.ModifyStateObject(SourceUnitState.Class, SourceUnitState.ObjectID));
					SourceUnitState.SuperConcealmentLoss += SuperConcealedModifier;
					if (SourceUnitState.SuperConcealmentLoss > 100)
						SourceUnitState.SuperConcealmentLoss = 100;

					//	taking a shot with the vektor rifle has a specific cap to loss chance - except against objective targets
					if (!class'Helpers'.static.IsObjectiveTarget(ActivatedAbilityStateContext.InputContext.PrimaryTarget.ObjectID, GameState))
					{
						WeaponState = ActivatedAbilityState.GetSourceWeapon();
						if (WeaponState != none && WeaponState.InventorySlot == eInvSlot_PrimaryWeapon && ActivatedAbilityState.IsAbilityInputTriggered())
						{


							if (SourceUnitState.SuperConcealmentLoss > class'X2AbilityTemplateManager'.default.SuperConcealShotMax)
								SourceUnitState.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealShotMax;
						}
					}

					`TACTICALRULES.SubmitGameState(SuperConcealedState);
				}
				RandRoll = `SYNC_RAND(100);
					
				SuperConcealedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SuperConcealmentLossChance Roll");
				SourceUnitState = XComGameState_Unit(SuperConcealedState.ModifyStateObject(SourceUnitState.Class, SourceUnitState.ObjectID));
				SourceUnitState.LastSuperConcealmentRoll = RandRoll;
				SourceUnitState.LastSuperConcealmentValue = SourceUnitState.SuperConcealmentLoss;
				SourceUnitState.LastSuperConcealmentResult = RandRoll < SourceUnitState.SuperConcealmentLoss;
				XComGameStateContext_ChangeContainer(SuperConcealedState.GetContext()).BuildVisualizationFn = SuperConcealmentRollVisualization;
				SuperConcealedState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);
				`TACTICALRULES.SubmitGameState(SuperConcealedState);
					
				`log(SourceUnitState @ "SuperConcealementLoss=" $ SourceUnitState.SuperConcealmentLoss @ "d100=" $ RandRoll,,'XCom_HitRolls');
				if (RandRoll < SourceUnitState.SuperConcealmentLoss)
				{
					`log("Concealment lost!",,'XCom_HitRolls');
					BreakConcealment();
				}
				else
				{
					`log("Concealment retained.",,'XCom_HitRolls'); 
					BTMgr = `BEHAVIORTREEMGR;
					if (BTMgr.bWaitingOnSquadConcealment)
					{
						// Disable the wait on squad concealment, since this unit will not break concealment.
						BTMgr.bWaitingOnSquadConcealment = false;
					}
				}
			}
		}
		else
		{			
			if (!bRetainConcealment)
				BreakConcealment();
			else 
			{
				BTMgr = `BEHAVIORTREEMGR;
				if (BTMgr.bWaitingOnSquadConcealment)
				{
					// Disable the wait on squad concealment, since this unit will not break concealment.
					BTMgr.bWaitingOnSquadConcealment = false;
				}
			}
		}
	}

	if( ActivatedAbilityState.DoesAbilityCauseSound() )
	{
		if( ActivatedAbilityStateContext != None && ActivatedAbilityStateContext.InputContext.ItemObject.ObjectID > 0 )
		{
			SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.SourceObject.ObjectID));
			WeaponState = XComGameState_Item(GameState.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.ItemObject.ObjectID));

			SoundRange = WeaponState.GetItemSoundRange();
			if( SoundRange > 0 )
			{
				if( !WeaponState.SoundOriginatesFromOwnerLocation() && ActivatedAbilityStateContext.InputContext.TargetLocations.Length > 0 )
				{
					SoundLocation = ActivatedAbilityStateContext.InputContext.TargetLocations[0];
					SoundTileLocation = `XWORLD.GetTileCoordinatesFromPosition(SoundLocation);
				}
				else
				{
					GetKeystoneVisibilityLocation(SoundTileLocation);
				}

				GetEnemiesInRange(SoundTileLocation, SoundRange, Enemies);

				`LogAI("Weapon sound @ Tile("$SoundTileLocation.X$","@SoundTileLocation.Y$","@SoundTileLocation.Z$") - Found"@Enemies.Length@"enemies in range ("$SoundRange$" meters)");
				foreach Enemies(EnemyRef)
				{
					EnemyInSoundRangeUnitState = XComGameState_Unit(History.GetGameStateForObjectID(EnemyRef.ObjectID));

					// this was the targeted unit
					if( EnemyInSoundRangeUnitState.ObjectID == ActivatedAbilityStateContext.InputContext.PrimaryTarget.ObjectID )
					{
						UnitAGainsKnowledgeOfUnitB(EnemyInSoundRangeUnitState, SourceUnitState, GameState, eAC_TakingFire, false);
					}
					// this unit just overheard the sound
					else
					{
						UnitAGainsKnowledgeOfUnitB(EnemyInSoundRangeUnitState, SourceUnitState, GameState, eAC_DetectedSound, false);
					}
				}
			}
		}
	}

	if( `SecondWaveEnabled('ChosenActivationSystemEnabled') )
	{
		ChosenState = GetEngagedChosen(, GameState.HistoryIndex);
		if( ChosenState != None && !ChosenState.IsDead() )
		{
			// if this unit is a chosen and it is currently engaged, if the action that was just taken was an attack against an XCom target, interject the 
			// 'directed' attack visualization sequence
			if( ChosenState.ObjectID != ObjectID )
			{
				//Disable for now until we have replaced the logic within the visualization mgr to support it
				//ChosenState.InterjectDirectAttackVisualization(ActivatedAbilityStateContext, ActivatedAbilityState, GameState);
			}

			if( GetTeam() == eTeam_XCom && IsAbleToAct() )
			{
				ChosenActivationModifier = ChosenState.CalculateChosenActivationAmount(ActivatedAbilityState);

				if( ChosenActivationModifier == -1 )
					ChosenActivationModifier = class'X2AbilityTemplateManager'.default.NormalChosenActivationIncreasePerUse;

				ChosenState.AdvanceChosenActivation(ChosenActivationModifier);
			}
		}
	}

	// lost spawning
	LostSpawnModifier = AbilityTemplate.LostSpawnIncreasePerUse;

	// Contribute sound to lost spawning if the lost spawn is enabled and off cooldown, or the sound contribution is above the loud sound threshold
	if(LostSpawnModifier > 0)
	{
		class'XComGameState_BattleData'.static.AdvanceLostSpawning(LostSpawnModifier, true, ActivatedAbilityStateContext.InputContext.AbilityTemplateName == 'LostHowlerAbility');
	}

	return ELR_NoInterrupt;
}

function InterjectDirectAttackVisualization(XComGameStateContext_Ability AbilityContext, XComGameState_Ability AbilityState, XComGameState GameState)
{
	local XComGameState_Unit SourceUnitState, TargetUnitState;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability NewAbilityContext;
	local XComGameState_Ability DirectedAttackAbilityState;
	local StateObjectReference DirectedAttackAbilityRef;
	local array<int> SourceUnitRefs;
	local float CurrentTime, LastNarrativeVOTime;

	History = `XCOMHISTORY;

	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if( SourceUnitState != None && SourceUnitState.GetTeam() == eTeam_Alien && AbilityState.GetMyTemplate().Hostility == eHostility_Offensive )
	{
		TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

		if( TargetUnitState != None && TargetUnitState.GetTeam() == eTeam_XCom )
		{
			CurrentTime = class'WorldInfo'.static.GetWorldInfo().TimeSeconds;
			LastNarrativeVOTime = `PRES.LastChosenDirectedAttack;

			if( CurrentTime > LastNarrativeVOTime + 60.0 ) // todo: config me
			{
				DirectedAttackAbilityRef = FindAbility('ChosenDirectedAttack');

				if( DirectedAttackAbilityRef.ObjectID > 0 )
				{
					SourceUnitRefs.AddItem(AbilityContext.InputContext.SourceObject.ObjectID);
					DirectedAttackAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(DirectedAttackAbilityRef.ObjectID));
					NewAbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(DirectedAttackAbilityState, TargetUnitState.ObjectID, SourceUnitRefs);
					if( NewAbilityContext.Validate() )
					{
						`PRES.LastChosenDirectedAttack = CurrentTime;
						`TACTICALRULES.SubmitGameStateContext(NewAbilityContext);
					}
				}
			}
		}
	}

}

static function SuperConcealmentRollVisualization(XComGameState VisualizeGameState)
{
	local X2Action_UpdateUI UpdateUIAction;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local X2Action_CameraLookAt LookAtAction;
	local X2Action_MarkerNamed JoinAction;
	local X2Action_Delay DelayAction;
	local X2Action ParentAction;
	local Array<X2Action> ActionsToJoin;
	local int LocalPlayerID;

	History = `XCOMHISTORY;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		break;
	}

	LocalPlayerID = `TACTICALRULES.GetLocalClientPlayerObjectID();

	if(UnitState.ControllingPlayer.ObjectID == LocalPlayerID)
	{
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.StateObject_OldState = History.GetPreviousGameStateForObject(UnitState);
		ActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);

		ParentAction = ActionMetadata.LastActionAdded;

		// Jwats: First get the actor on screen!
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ParentAction));
		LookAtAction.LookAtActor = ActionMetadata.VisualizeActor;
		LookAtAction.BlockUntilActorOnScreen = true;
		LookAtAction.LookAtDuration = class'X2Ability_ReaperAbilitySet'.default.ShadowRollCameraDelay;
		LookAtAction.TargetZoomAfterArrival = -0.4f;

		// Jwats: Then update the UI
		UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, LookAtAction));
		UpdateUIAction.UpdateType = EUIUT_SuperConcealRoll;
		UpdateUIAction.SpecificID = UnitState.ObjectID;
		ActionsToJoin.AddItem(UpdateUIAction);

		// Jwats: Make sure the visualization waits for the UI to finish
		DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, LookAtAction));
		DelayAction.Duration = class'X2Ability_ReaperAbilitySet'.default.ShadowRollCameraDelay;
		DelayAction.bIgnoreZipMode = true;
		ActionsToJoin.AddItem(DelayAction);

		//Block ability activation while this sequence is running
		class'X2Action_BlockAbilityActivation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);

		// Jwats: Make sure the Delay and update UI is waited for and not just one of them.
		JoinAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, None, ActionsToJoin));
		JoinAction.SetName("Join");
	}
}

static function XComGameState_Unit GetEngagedChosen(optional out XComGameState_Unit UnengagedChosen, optional int HistoryIndex = -1)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState, , , HistoryIndex)
	{
		if( UnitState.IsChosen() )
		{
			if( UnitState.IsEngagedChosen() )
			{
				return UnitState;
			}

			UnengagedChosen = UnitState;
		}
	}

	return None;
}

function bool IsEngagedChosen()
{
	local UnitValue ActivationValue;

	if( IsChosen() && ControllingPlayerIsAI() && IsAlive() && !IsIncapacitated() && !bRemovedFromPlay )
	{
		GetUnitValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, ActivationValue);
		if( ActivationValue.fValue == class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ENGAGED )
		{
			return true;
		}
	}

	return false;
}

static function XComGameState_Unit GetActivatedChosen(optional int HistoryIndex = -1)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState, , , HistoryIndex)
	{
		if( UnitState.IsActivatedChosen() )
		{
			return UnitState;
		}
	}

	return None;
}

function bool IsActivatedChosen()
{
	local UnitValue ActivationValue;

	if( IsChosen() && ControllingPlayerIsAI() && IsAlive() && !IsIncapacitated() && !bRemovedFromPlay )
	{
		GetUnitValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, ActivationValue);
		if( ActivationValue.fValue == class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ACTIVATED ||
			ActivationValue.fValue == class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ENGAGED )
		{
			return true;
		}
	}

	return false;
}

private function int CalculateChosenActivationAmount(XComGameState_Ability AbilityState)
{
	local int ActivationAmount;
	local X2AbilityTemplate AbilityTemplate;
	local ModifyChosenActivationIncreasePerUse EmptyModStruct, AbilityChosenActivationIncreasePerUse;
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local float MultiplicationValue, AdditionValue, PostMultiplicationValue;

	ActivationAmount = 0;
	MultiplicationValue = 1.0f;
	AdditionValue = 0.0f;
	PostMultiplicationValue = 1.0f;

	if( AbilityState != None )
	{
		AbilityTemplate = AbilityState.GetMyTemplate();

		if( AbilityTemplate != None )
		{
			ActivationAmount = AbilityTemplate.ChosenActivationIncreasePerUse;

			History = `XCOMHISTORY;
			// Loop over the effects on the unit for any modifications to this amount
			foreach AffectedByEffects(EffectRef)
			{
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				if( EffectState != None )
				{
					EffectTemplate = EffectState.GetX2Effect();
					AbilityChosenActivationIncreasePerUse = EmptyModStruct;
					if( (EffectTemplate != None) &&
						(EffectTemplate.GetModifyChosenActivationIncreasePerUseFn != None) &&
						EffectTemplate.GetModifyChosenActivationIncreasePerUseFn(AbilityState, AbilityChosenActivationIncreasePerUse) )
					{
						switch (AbilityChosenActivationIncreasePerUse.ModOp)
						{
						case MODOP_Multiplication:
							MultiplicationValue *= AbilityChosenActivationIncreasePerUse.Amount;
							break;
						case MODOP_Addition:
							AdditionValue += AbilityChosenActivationIncreasePerUse.Amount;
							break;
						case MODOP_Multiplication:
							PostMultiplicationValue *= AbilityChosenActivationIncreasePerUse.Amount;
							break;
						}
					}
				}
			}

			ActivationAmount *= MultiplicationValue;
			ActivationAmount += AdditionValue;
			ActivationAmount *= PostMultiplicationValue;
		}
	}

	return ActivationAmount;
}

function AdvanceChosenActivation(int ActivationAmount)
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameState_Player NewPlayerState;

	if( ActivationAmount != 0 )
	{
		TacticalRules = `TACTICALRULES;
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Chosen activation advanced");

		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));

		NewUnitState.ActivationLevel += ActivationAmount;
		if( NewUnitState.ActivationLevel >= NewUnitState.ActivationThreshold )
		{
			NewUnitState.ActivationLevel = NewUnitState.ActivationThreshold;
			NewPlayerState = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', NewUnitState.ControllingPlayer.ObjectID));
			++NewPlayerState.ChosenActivationsThisTurn;

			TacticalRules.InterruptInitiativeTurn(NewGameState, GetGroupMembership().GetReference());
		}

		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeChosenUI);

		TacticalRules.SubmitGameState(NewGameState);
	}
}

private function VisualizeChosenUI(XComGameState VisualizeGameState)
{
	local X2Action_UpdateUI UpdateUIAction;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameState_Unit UnitState;
	local X2Action_Delay DelayAction;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		break;
	}

	ActionMetadata.StateObject_NewState = UnitState;
	ActionMetadata.StateObject_OldState = `XCOMHISTORY.GetPreviousGameStateForObject(UnitState);

	UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
	UpdateUIAction.SpecificID = UnitState.ObjectID;
	UpdateUIAction.UpdateType = EUIUT_ChosenHUD;

	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	DelayAction.Duration = 0.75;
}


// unit moves - alert for him for other units he sees from the new location
// unit moves - alert for other units towards this unit
function EventListenerReturn OnUnitEnteredTile(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit OtherUnitState, ThisUnitState;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local GameRulesCache_VisibilityInfo VisibilityInfoFromThisUnit, VisibilityInfoFromOtherUnit;
	local float ConcealmentDetectionDistance;
	local XComGameState_AIGroup AIGroupState;
	local XComGameStateContext_Ability SourceAbilityContext;
	local XComGameState_InteractiveObject InteractiveObjectState;
	local XComWorldData WorldData;
	local Vector CurrentPosition, TestPosition;
	local TTile CurrentTileLocation;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent PersistentEffect;
	local XComGameState NewGameState;
	local XComGameStateContext_EffectRemoved EffectRemovedContext;
	local bool DoesUnitBreaksConcealmentIgnoringDistance;
	local name RetainConcealmentName;
	local bool RetainConcealment;

	WorldData = `XWORLD;
	History = `XCOMHISTORY;

	ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

	// cleanse burning on entering water
	ThisUnitState.GetKeystoneVisibilityLocation(CurrentTileLocation);
	if( ThisUnitState.IsBurning() && WorldData.IsWaterTile(CurrentTileLocation) )
	{
		foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
		{
			if( EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == ObjectID )
			{
				PersistentEffect = EffectState.GetX2Effect();
				if( PersistentEffect.EffectName == class'X2StatusEffects'.default.BurningName )
				{
					EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
					NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
					EffectState.RemoveEffect(NewGameState, NewGameState, true); //Cleansed

					`TACTICALRULES.SubmitGameState(NewGameState);
				}
			}
		}
	}

	SourceAbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if( SourceAbilityContext != None )
	{
		// concealment for this unit is broken when stepping into a new tile if the act of stepping into the new tile caused environmental damage (ex. "broken glass")
		// if this occurred, then the GameState will contain either an environmental damage state or an InteractiveObject state
		// unless you're in challenge mode, then breaking stuff doesn't break concealment
		if( ThisUnitState.IsConcealed() && SourceAbilityContext.ResultContext.bPathCausesDestruction && (History.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) == none))
		{
			ThisUnitState.BreakConcealment();
		}

		ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

		// check if this unit is a member of a group waiting on this unit's movement to complete 
		// (or at least reach the interruption step where the movement should complete)
		AIGroupState = ThisUnitState.GetGroupMembership();
		if( AIGroupState != None &&
			AIGroupState.IsWaitingOnUnitForReveal(ThisUnitState) &&
			(SourceAbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt ||
			(AIGroupState.FinalVisibilityMovementStep > INDEX_NONE &&
			AIGroupState.FinalVisibilityMovementStep <= SourceAbilityContext.ResultContext.InterruptionStep)) )
		{
			AIGroupState.StopWaitingOnUnitForReveal(ThisUnitState);
		}
	}

	// concealment may be broken by moving within range of an interactive object 'detector'
	if( ThisUnitState.IsConcealed() )
	{
		foreach class'X2AbilityTemplateManager'.default.AbilityRetainsConcealmentVsInteractives(RetainConcealmentName)
		{
			if (ThisUnitState.HasSoldierAbility(RetainConcealmentName))
			{
				RetainConcealment = true;
				break;
			}
		}

		if (!RetainConcealment)
		{
			ThisUnitState.GetKeystoneVisibilityLocation(CurrentTileLocation);
			CurrentPosition = WorldData.GetPositionFromTileCoordinates(CurrentTileLocation);
		
			foreach History.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObjectState)
			{
				if (InteractiveObjectState.DetectionRange > 0.0 && !InteractiveObjectState.bHasBeenHacked)
				{
					TestPosition = WorldData.GetPositionFromTileCoordinates(InteractiveObjectState.TileLocation);

					if (VSizeSq(TestPosition - CurrentPosition) <= Square(InteractiveObjectState.DetectionRange))
					{
						ThisUnitState.BreakConcealment();
						ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
						break;
					}
				}
			}
		}
	}

	// concealment may also be broken if this unit moves into detection range of an enemy unit
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	foreach History.IterateByClassType(class'XComGameState_Unit', OtherUnitState)
	{
		// don't process visibility against self
		if( OtherUnitState.ObjectID == ThisUnitState.ObjectID )
		{
			continue;
		}

		VisibilityMgr.GetVisibilityInfo(ThisUnitState.ObjectID, OtherUnitState.ObjectID, VisibilityInfoFromThisUnit);

		if( VisibilityInfoFromThisUnit.bVisibleBasic )
		{
			// check if the other unit is concealed, and this unit's move has revealed him
			if( OtherUnitState.IsConcealed() &&
			    OtherUnitState.UnitBreaksConcealment(ThisUnitState) &&
				VisibilityInfoFromThisUnit.TargetCover == CT_None )
			{
				DoesUnitBreaksConcealmentIgnoringDistance = ThisUnitState.DoesUnitBreaksConcealmentIgnoringDistance();

				if( !DoesUnitBreaksConcealmentIgnoringDistance )
				{
					ConcealmentDetectionDistance = OtherUnitState.GetConcealmentDetectionDistance(ThisUnitState);
				}

				if( DoesUnitBreaksConcealmentIgnoringDistance ||
					VisibilityInfoFromThisUnit.DefaultTargetDist <= Square(ConcealmentDetectionDistance) )
				{
					OtherUnitState.BreakConcealment(ThisUnitState, true);

					// have to refresh the unit state after broken concealment
					OtherUnitState = XComGameState_Unit(History.GetGameStateForObjectID(OtherUnitState.ObjectID));
				}
			}

			// generate alert data for this unit about other units
			UnitASeesUnitB(ThisUnitState, OtherUnitState, GameState);
		}

		// only need to process visibility updates from the other unit if it is still alive
		if( OtherUnitState.IsAlive() )
		{
			VisibilityMgr.GetVisibilityInfo(OtherUnitState.ObjectID, ThisUnitState.ObjectID, VisibilityInfoFromOtherUnit);

			if( VisibilityInfoFromOtherUnit.bVisibleBasic )
			{
				// check if this unit is concealed and that concealment is broken by entering into an enemy's detection tile
				if( ThisUnitState.IsConcealed() && UnitBreaksConcealment(OtherUnitState) )
				{
					DoesUnitBreaksConcealmentIgnoringDistance = OtherUnitState.DoesUnitBreaksConcealmentIgnoringDistance();

					if (!DoesUnitBreaksConcealmentIgnoringDistance)
					{
						ConcealmentDetectionDistance = GetConcealmentDetectionDistance(OtherUnitState);
					}

					if( DoesUnitBreaksConcealmentIgnoringDistance ||
						VisibilityInfoFromOtherUnit.DefaultTargetDist <= Square(ConcealmentDetectionDistance) )
					{
						ThisUnitState.BreakConcealment(OtherUnitState);

						// have to refresh the unit state after broken concealment
						ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
					}
				}

				// generate alert data for other units that see this unit
				if( VisibilityInfoFromOtherUnit.bVisibleBasic && !ThisUnitState.IsConcealed() )
				{
					//  don't register an alert if this unit is about to reflex
					AIGroupState = OtherUnitState.GetGroupMembership();
					if (AIGroupState == none || AIGroupState.EverSightedByEnemy)
						UnitASeesUnitB(OtherUnitState, ThisUnitState, GameState);
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

static function UnitASeesUnitB(XComGameState_Unit UnitA, XComGameState_Unit UnitB, XComGameState AlertInstigatingGameState)
{
	local EAlertCause AlertCause;
	local XComGameState_AIGroup UnitBGroup;

	AlertCause = eAC_None;

	// Ignore the fact that we saw a cosmetic unit.  It's the non-cosmetic parent that we care about having seen.
	if (UnitB.GetMyTemplate().bIsCosmetic)
	{
		return;
	}

	if (!UnitA.IsDead() && !UnitB.IsDead())
	{
		`XEVENTMGR.TriggerEvent('UnitSeesUnit', UnitA, UnitB, AlertInstigatingGameState);
	}

	if( (!UnitB.IsDead() || !UnitA.HasSeenCorpse(UnitB.ObjectID)) && UnitB.GetTeam() != eTeam_Neutral )
	{
		if( UnitB.IsDead() )
		{
			AlertCause = eAC_DetectedNewCorpse;
			UnitA.MarkCorpseSeen(UnitB.ObjectID);
		}
		else if( UnitA.IsEnemyUnit(UnitB) )
		{
			if(!UnitB.IsConcealed())
			{
				AlertCause = eAC_SeesSpottedUnit;
			}
		}
		else if( UnitB.GetCurrentStat(eStat_AlertLevel) > 0 )
		{
			// Prevent alerting the group if this is a fallback unit. (Fallback is not meant to aggro the other group)
			UnitBGroup = UnitB.GetGroupMembership();
			if( UnitBGroup == None || !UnitBGroup.IsFallingBack() )
			{
				AlertCause = eAC_SeesAlertedAllies;
			}
		}

		UnitAGainsKnowledgeOfUnitB(UnitA, UnitB, AlertInstigatingGameState, AlertCause, true);
	}
}

static function UnitAGainsKnowledgeOfUnitB(XComGameState_Unit UnitA, XComGameState_Unit UnitB, XComGameState AlertInstigatingGameState, EAlertCause AlertCause, bool bUnitAIsMidMove)
{
	local XComGameStateHistory History;
	local AlertAbilityInfo AlertInfo;	
	local X2TacticalGameRuleset Ruleset;
	local XComGameState_AIGroup AIGroupState;
	local XComGameStateContext_Ability SourceAbilityContext;
	local bool bStartedRedAlert;
	local bool bGainedRedAlert;
	local bool bAlertDataSuccessfullyAdded;
	local ETeam UnitATeam, UnitBTeam;

	if (UnitB == none)
		return;

	if( AlertCause != eAC_None )
	{
		History = `XCOMHISTORY;
		UnitB.GetKeystoneVisibilityLocation(AlertInfo.AlertTileLocation);
		AlertInfo.AlertUnitSourceID = UnitB.ObjectID;
		AlertInfo.AnalyzingHistoryIndex = History.GetCurrentHistoryIndex();

		UnitATeam = UnitA.GetTeam();
		UnitBTeam = UnitB.GetTeam();

		// do not process this alert if:
		// the cause is not allowed regardless of visibility
		if( !class'XComGameState_AIUnitData'.static.ShouldEnemyFactionsTriggerAlertsOutsidePlayerVision(AlertCause) &&

		   // there is assumed to be visibility if either unit is an XCom unit
		   UnitATeam != eTeam_XCom &&  
		   UnitBTeam != eTeam_XCom && 

		   // this is an AI <-> AI alert; these should only be processed if the player has visibility to both targets
		   !(class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(UnitA.ObjectID)
			   && class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(UnitB.ObjectID) ) )
		{
			return;
		}

		// no knowledge updates for The Lost
		if( UnitATeam != eTeam_TheLost && UnitBTeam != eTeam_TheLost )
		{
			bAlertDataSuccessfullyAdded = UnitA.UpdateAlertData(AlertCause, AlertInfo);
		}
		else
		{
			bAlertDataSuccessfullyAdded = true; // the lost still need to process alert level changes
		}

		bStartedRedAlert = UnitA.GetCurrentStat(eStat_AlertLevel) == `ALERT_LEVEL_RED;
		AIGroupState = UnitA.GetGroupMembership();
		if( bAlertDataSuccessfullyAdded && (AIGroupState != none) )
		{
			// If the AlertData was not added successfully, then do not process the AlertAbility
			// based upon the AlertCause
			AIGroupState.ApplyAlertAbilityToGroup(AlertCause);
		}
		UnitA = XComGameState_Unit(History.GetGameStateForObjectID(UnitA.ObjectID));
		bGainedRedAlert = !bStartedRedAlert && UnitA.GetCurrentStat(eStat_AlertLevel) == `ALERT_LEVEL_RED;

		if( AIGroupState != None && //Verify we have a valid group here
		    !AIGroupState.bProcessedScamper && //That we haven't scampered already
		    UnitA.bTriggerRevealAI //We are able to scamper 			
		    ) // Update - remove restriction on scampers only happening for XCom visibility.  Scamper can happen with the Lost.
		{
			if(class'XComGameState_AIUnitData'.static.DoesCauseReflexMoveActivate(AlertCause)) //The cause of our concern can result in a scamper
			{
				Ruleset = X2TacticalGameRuleset(`XCOMGAME.GameRuleset);

				// if AI is active player and is currently moving, then reveal. The camera system / reveal action will worry about whether it can frame this as a pod reveal or not
				if(Ruleset.UnitActionPlayerIsAI() && bUnitAIsMidMove )
				{
					AIGroupState.InitiateReflexMoveActivate(UnitB, AlertCause);
				}
				// otherwise, reveal iff XCom has visibility of the current unit location
				else if( class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(UnitA.ObjectID) )
				{
					SourceAbilityContext = XComGameStateContext_Ability(AlertInstigatingGameState.GetContext());
					// If this is a move interrupt, flag the behavior tree to kick off after the move ends.
					if (!Ruleset.UnitActionPlayerIsAI() // Do not wait if it was the AI that was interrupted.  (EndMove event for AI's move will not trigger until the interrupted move + scamper is completed. This would hang the AI.)
						&& SourceAbilityContext != None
						&& SourceAbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt 
						&& SourceAbilityContext.InputContext.MovementPaths.Length > 0 )
					{
						`BEHAVIORTREEMGR.bWaitingOnEndMoveEvent = true;
					}
					AIGroupState.InitiateReflexMoveActivate(UnitB, AlertCause);
					if( !`BEHAVIORTREEMGR.IsScampering() )
					{
						// Clear the flag if no one is set to scamper.
						`BEHAVIORTREEMGR.bWaitingOnEndMoveEvent = false;
					}
				}
			}
			else if(bGainedRedAlert)
			{				
				`redscreen("Warning: AI gained a red alert status by cause "$ AlertCause $" that was not valid for scamper. Units shouldn't enter red alert without scampering! @gameplay" );
			}
		}
	}
}

// Returns true if the AlertCause was successfully added as AlertData to the unit
function bool UpdateAlertData(EAlertCause AlertCause, AlertAbilityInfo AlertInfo)
{
	local XComGameState_AIUnitData AIUnitData_NewState;
	local XComGameState NewGameState;
	local int AIUnitDataID;
	local bool bResult;

	bResult = false;

	AIUnitDataID = GetAIUnitDataID();
	if( AIUnitDataID > 0 )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UpdateAlertData [" $ ObjectID @ AlertCause @ AlertInfo.AlertUnitSourceID $ "]");

		AIUnitData_NewState = XComGameState_AIUnitData(NewGameState.ModifyStateObject(class'XComGameState_AIUnitData', AIUnitDataID));
		bResult = AIUnitData_NewState.AddAlertData(ObjectID, AlertCause, AlertInfo, NewGameState);
		if( bResult )
		{
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
		else
		{
			NewGameState.PurgeGameStateForObjectID(AIUnitData_NewState.ObjectID);
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
	}

	return bResult;
}

function ApplyAlertAbilityForNewAlertData(EAlertCause AlertCause)
{
	local StateObjectReference AbilityRef;
	local XComGameStateContext_Ability NewAbilityContext;
	local X2TacticalGameRuleset Ruleset;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;

	if( class'XComGameState_AIUnitData'.static.IsCauseAggressive(AlertCause) && GetCurrentStat(eStat_AlertLevel) < `ALERT_LEVEL_RED )
	{
		// go to red alert
		AbilityRef = FindAbility('RedAlert');
	}
	else if(class'XComGameState_AIUnitData'.static.IsCauseSuspicious(AlertCause) && GetCurrentStat(eStat_AlertLevel) < `ALERT_LEVEL_YELLOW)
	{
		// go to yellow alert
		AbilityRef = FindAbility('YellowAlert');
	}

	// process the alert ability
	if( AbilityRef.ObjectID > 0 )
	{
		History = `XCOMHISTORY;

		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

		if( AbilityState != None )
		{
			NewAbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, ObjectID);
			NewAbilityContext.ResultContext.iCustomAbilityData = AlertCause;
			if( NewAbilityContext.Validate() )
			{
				Ruleset = X2TacticalGameRuleset(`XCOMGAME.GameRuleset);
				Ruleset.SubmitGameStateContext(NewAbilityContext);
			}
		}
	}
}

function EventListenerReturn OnAlertDataTriggerAlertAbility(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit AlertedUnit;

	local XComGameState_AIUnitData AIGameState;
	local int AIUnitDataID;
	local EAlertCause AlertCause;
	local XComGameState NewGameState;

	AlertedUnit = XComGameState_Unit(EventSource);
	
	if( AlertedUnit.IsAlive() )
	{
		AIUnitDataID = AlertedUnit.GetAIUnitDataID();
		if( AIUnitDataID == INDEX_NONE )
		{
			return ELR_NoInterrupt; // This may be a mind-controlled soldier. If so, we don't need to update their alert data.
		}
		AIGameState = XComGameState_AIUnitData(GameState.GetGameStateForObjectID(AIUnitDataID));
		`assert(AIGameState != none);

		AlertCause = eAC_None;

		if( AIGameState.RedAlertCause != eAC_None )
		{
			AlertCause = AIGameState.RedAlertCause;
		}
		else if( AIGameState.YellowAlertCause != eAC_None )
		{
			AlertCause =  AIGameState.YellowAlertCause;
		}

		if( AlertCause != eAC_None )
		{
			AlertedUnit.ApplyAlertAbilityForNewAlertData(AlertCause);

			// Clear the stored AlertCause
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Alerted Unit Update");
			AIGameState = XComGameState_AIUnitData(NewGameState.ModifyStateObject(class'XComGameState_AIUnitData', AIGameState.ObjectID));

			AIGameState.RedAlertCause = eAC_None;
			AIGameState.YellowAlertCause = eAC_None;

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnThisUnitDied(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComWorldData WorldData;
	local XComGameState_Unit DeadUnit;

	if( !m_CharTemplate.bBlocksPathingWhenDead )
	{
		WorldData = `XWORLD;
		DeadUnit = XComGameState_Unit(EventData);
		WorldData.ClearTileBlockedByUnitFlag(DeadUnit);
	}

	return ELR_NoInterrupt;
}

// Unit takes damage - alert for himself
// unit takes damage - alert to allies with vision of the damagee
function EventListenerReturn OnUnitTookDamage(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit Damagee, Damager, DamageObserver;
	local XComGameStateContext_Ability AbilityContext;
	local array<GameRulesCache_VisibilityInfo> DamageObserverInfos;
	local GameRulesCache_VisibilityInfo DamageObserverInfo;
	local TTile DamageeTileLocation;
	local bool DamageeWasKilled;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local int ChainStartIndex, iHistoryIndex;
	local XComGameState TestGameState;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == None)
	{
		// Walk up the event chain until we find an ability context that initiated this damage.
		ChainStartIndex = GameState.GetContext().EventChainStartIndex;
		for (iHistoryIndex = GameState.HistoryIndex - 1; iHistoryIndex >= ChainStartIndex && AbilityContext == None; --iHistoryIndex)
		{
			TestGameState = History.GetGameStateFromHistory(iHistoryIndex);
			AbilityContext = XComGameStateContext_Ability(TestGameState.GetContext());
		}
	}
	if( AbilityContext != None )
	{
		Damager = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	}
	Damagee = XComGameState_Unit(EventSource);

	// damaged unit gains direct (though not necessarily absolute) knowledge of the attacker
	DamageeWasKilled = Damagee.IsDead();
	if( !DamageeWasKilled )
	{
		UnitAGainsKnowledgeOfUnitB(Damagee, Damager, GameState, eAC_TookDamage, false);
	}
	
	// all other allies with visibility to the damagee gain indirect knowledge of the attacker
	Damagee.GetKeystoneVisibilityLocation(DamageeTileLocation);
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	VisibilityMgr.GetAllViewersOfLocation(DamageeTileLocation, DamageObserverInfos, class'XComGameState_Unit', -1);
	foreach DamageObserverInfos(DamageObserverInfo)
	{
		if( DamageObserverInfo.bVisibleGameplay )
		{
			DamageObserver = XComGameState_Unit(History.GetGameStateForObjectID(DamageObserverInfo.SourceID));
			if( DamageObserver != None && DamageObserver.IsAlive() )
			{
				if( DamageeWasKilled )
				{
					if( DamageObserver.IsEnemyUnit(Damager) )
					{
						// aliens in the same pod detect their ally (and by extension themselves) under fire, 
						// aliens in other pods just detect the corpse
						if(Damagee.GetGroupMembership().m_arrMembers.Find('ObjectID', DamageObserver.ObjectID) != INDEX_NONE)
						{
							UnitAGainsKnowledgeOfUnitB(DamageObserver, Damager, GameState, eAC_TakingFire, false);
						}
						else
						{
							UnitAGainsKnowledgeOfUnitB(DamageObserver, Damager, GameState, eAC_DetectedNewCorpse, false);
						}
					}

					DamageObserver.MarkCorpseSeen(Damagee.ObjectID);
				}
				else if( DamageObserver.IsEnemyUnit(Damager) )
				{
					UnitAGainsKnowledgeOfUnitB(DamageObserver, Damager, GameState, eAC_DetectedAllyTakingDamage, false);
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitAlerted(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit AlertedToUnit, AlertedUnit;
	local XComGameState_AIGroup AlertedGroup;
	if (IsUnrevealedAI())
	{
		AlertedUnit = XComGameState_Unit(EventData);
		AlertedToUnit = XComGameState_Unit(EventSource);

		UnitAGainsKnowledgeOfUnitB(AlertedUnit, AlertedToUnit, GameState, eAC_TakingFire, false);
		// Force group scamper.
		AlertedGroup = AlertedUnit.GetGroupMembership();
		AlertedGroup.InitiateReflexMoveActivate(AlertedToUnit, eAC_TakingFire);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnEffectBreakUnitConcealment(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	BreakConcealment();

	return ELR_NoInterrupt;
}

function EventListenerReturn OnEffectEnterUnitConcealment(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	EnterConcealment();

	return ELR_NoInterrupt;
}

function GetEnemiesInRange(TTile kLocation, int nMeters, out array<StateObjectReference> OutEnemies)
{
	local vector vCenter, vLoc;
	local float fDistSq;
	local XComGameState_Unit kUnit;
	local XComGameStateHistory History;
	local float AudioDistanceRadius, UnitHearingRadius, RadiiSumSquared;

	History = `XCOMHISTORY;
	vCenter = `XWORLD.GetPositionFromTileCoordinates(kLocation);
	AudioDistanceRadius = `METERSTOUNITS(nMeters);
	fDistSq = Square(AudioDistanceRadius);

	foreach History.IterateByClassType(class'XComGameState_Unit', kUnit)
	{
		if( IsEnemyUnit(kUnit) && kUnit.IsAlive() )
		{
			vLoc = `XWORLD.GetPositionFromTileCoordinates(kUnit.TileLocation);
			UnitHearingRadius = kUnit.GetCurrentStat(eStat_HearingRadius);

			RadiiSumSquared = fDistSq;
			if( UnitHearingRadius != 0 )
			{
				RadiiSumSquared = Square(AudioDistanceRadius + UnitHearingRadius);
			}

			if( VSizeSq(vLoc - vCenter) < RadiiSumSquared )
			{
				OutEnemies.AddItem(kUnit.GetReference());
			}
		}
	}
}

native function float GetConcealmentDetectionDistance(const ref XComGameState_Unit DetectorUnit);

simulated function bool CanFlank(bool bAllowMelee = false)
{
	return bAllowMelee || !IsMeleeOnly();
}

/// <summary>
/// Returns true if this unit is flanked
/// </summary>
/// <param name="FlankedBy">Filter the results of this method by a specific viewer</param>
/// <param name="bOnlyVisibleFlankers">If set to TRUE, then the method will only return true if this unit can see the flankers. Use this to avoid revealing positions of hidden enemies</param>
simulated function bool IsFlanked(optional StateObjectReference FlankedBy, bool bOnlyVisibleFlankers = false, int HistoryIndex = -1, bool bAllowMeleeFlankers = false)
{
	local int i;
	local array<StateObjectReference> FlankingEnemies;

	if (GetTeam() == eTeam_Neutral)
	{
		if(bOnlyVisibleFlankers)
		{
			// This may need to switch between XCom or Aliens based on Popular Support.
			class'X2TacticalVisibilityHelpers'.static.GetVisibleFlankersOfTarget(GetReference().ObjectID, eTeam_XCom, FlankingEnemies, HistoryIndex);
		}
		else
		{
			class'X2TacticalVisibilityHelpers'.static.GetFlankersOfTarget(GetReference().ObjectID, eTeam_XCom, FlankingEnemies, HistoryIndex);
		}
	}
	else
	{
		if(bOnlyVisibleFlankers)
		{
			class'X2TacticalVisibilityHelpers'.static.GetVisibleFlankingEnemiesOfTarget(GetReference().ObjectID, FlankingEnemies, HistoryIndex);
		}
		else
		{
			class'X2TacticalVisibilityHelpers'.static.GetFlankingEnemiesOfTarget(GetReference().ObjectID, FlankingEnemies, HistoryIndex, , bAllowMeleeFlankers);
		}
	}

	if(FlankedBy.ObjectID <= 0)
		return FlankingEnemies.Length > 0;

	for(i = 0; i < FlankingEnemies.Length; ++i)
	{
		if(FlankingEnemies[i].ObjectID == FlankedBy.ObjectID)
			return true;
	}

	return false;
}

simulated event bool IsFlankedAtLocation(const vector Location)
{
	local array<StateObjectReference> FlankingEnemies;

	class'X2TacticalVisibilityHelpers'.static.GetFlankingEnemiesOfLocation(Location, ControllingPlayer.ObjectID, FlankingEnemies);

	return FlankingEnemies.Length > 0;
}

simulated function bool IsPsiOperative()
{
	local X2SoldierClassTemplate SoldierClassTemplate;
	SoldierClassTemplate = GetSoldierClassTemplate();
	return SoldierClassTemplate != none && SoldierClassTemplate.DataName == 'PsiOperative';
}

simulated native function bool HasSquadsight() const;

function int TileDistanceBetween(XComGameState_Unit OtherUnit)
{
	local XComWorldData WorldData;
	local vector UnitLoc, TargetLoc;
	local float Dist;
	local int Tiles;

	if (OtherUnit == none || OtherUnit == self || TileLocation == OtherUnit.TileLocation)
		return 0;

	WorldData = `XWORLD;
	UnitLoc = WorldData.GetPositionFromTileCoordinates(TileLocation);
	TargetLoc = WorldData.GetPositionFromTileCoordinates(OtherUnit.TileLocation);
	Dist = VSize(UnitLoc - TargetLoc);
	Tiles = Dist / WorldData.WORLD_StepSize;      //@TODO gameplay - surely there is a better check for finding the number of tiles between two points
	return Tiles;
}

simulated function bool UseLargeArmoryScale() // Add your template name here if the model is too large to fit in normal position
{
	return GetMyTemplate().bIsTooBigForArmory;
}

native function bool IsFriendlyToLocalPlayer() const;
native function bool IsMine() const;
simulated native function ETeam GetTeam() const;
simulated native function bool IsEnemyTeam(ETeam OtherTeam);
simulated native function bool IsEnemyUnit(XComGameState_Unit IsEnemy);
simulated native function bool IsFriendlyUnit(XComGameState_Unit IsFriendly);
simulated native function bool UnitBreaksConcealment(XComGameState_Unit OtherUnit);

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

//	@TODO jbouscher/gameplay - probably want to make this extensible for modders, etc.
function RollForSpecialLoot()
{
	local XComGameState_Unit IterUnit;
	local XComGameStateHistory History;
	local int Chance, RandRoll;

	//	Look for XCom units with Channel and if any are found, roll to drop focus
	//	But robots don't drop it
	if (!IsRobotic())
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', IterUnit)
		{
			if (IterUnit.GetTeam() == eTeam_XCom && IterUnit.IsAlive() && IterUnit.HasSoldierAbility('Channel'))
			{
				if (IsPsionic())
					Chance = class'X2Ability_TemplarAbilitySet'.default.ChannelPsionicChance;
				else
					Chance = class'X2Ability_TemplarAbilitySet'.default.ChannelChance;

				RandRoll = `SYNC_RAND(100);
				if (RandRoll <= Chance)
				{
					PendingLoot.LootToBeCreated.AddItem(class'X2Ability_TemplarAbilitySet'.default.ChannelDropItemTemplate);
				}

				//	Only one roll gets to be made and only one item can drop
				break;
			}
		}
	}
}

simulated event bool HasLoot()
{
	return HasUnexplodedLoot();
}

simulated event bool HasAvailableLoot()
{
	return HasLoot() && IsDead() && !IsBeingCarried();
}

function bool HasAvailableLootForLooter(StateObjectReference LooterRef)
{
	return class'Helpers'.static.HasAvailableLootInternal(self, LooterRef);
}

simulated function bool HasPsiLoot()
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local int i;

	History = `XCOMHISTORY;

	for( i = 0; i < PendingLoot.LootToBeCreated.Length; ++i )
	{
		if( PendingLoot.LootToBeCreated[i] == 'BasicFocusLoot' )
		{
			return true;
		}
	}

	for( i = 0; i < PendingLoot.AvailableLoot.Length; ++i )
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(PendingLoot.AvailableLoot[i].ObjectID));
		if( ItemState != none && X2FocusLootItemTemplate(ItemState.GetMyTemplate()) != none )
		{
			return true;
		}
	}

	return false;
}

simulated function bool HasNonPsiLoot()
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local int i;

	History = `XCOMHISTORY;

	for (i = 0; i < PendingLoot.LootToBeCreated.Length; ++i)
	{
		if (PendingLoot.LootToBeCreated[i] != 'BasicFocusLoot')
		{
			return true;
		}
	}

	for (i = 0; i < PendingLoot.AvailableLoot.Length; ++i)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(PendingLoot.AvailableLoot[i].ObjectID));
		if (ItemState != none && X2FocusLootItemTemplate(ItemState.GetMyTemplate()) == none)
		{
			return true;
		}
	}

	return false;
}

protected simulated function bool HasUnexplodedLoot()
{
	local int i;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;

	if(class'XComGameState_Cheats'.static.GetCheatsObject().DisableLooting)
	{
		return false;
	}

	if (PendingLoot.AvailableLoot.Length > 0)
		return true;

	if (PendingLoot.LootToBeCreated.Length == 0)
		return false;

	if (!bKilledByExplosion)
		return true;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	for (i = 0; i < PendingLoot.LootToBeCreated.Length; ++i)
	{
		ItemTemplate = ItemTemplateManager.FindItemTemplate(PendingLoot.LootToBeCreated[i]);
		if (ItemTemplate != none)
		{
			if (ItemTemplate.LeavesExplosiveRemains)
				return true;
		}
	}
	return false;
}

function DropCarriedLoot(XComGameState ModifyGameState)
{
	local XComGameState_Unit NewUnit;
	local array<XComGameState_Item> Items;

	NewUnit = XComGameState_Unit(ModifyGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));

	Items = NewUnit.GetAllItemsInSlot(eInvSlot_Backpack, ModifyGameState);

	class'XComGameState_LootDrop'.static.CreateLootDrop(ModifyGameState, Items, self, false);
}

function VisualizeLootDropped(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local VisualizationActionMetadata ActionMetadata;

	// loot fountain
	History = `XCOMHISTORY;
	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);

	ActionMetadata.VisualizeActor = History.GetVisualizer(ObjectID);

	class'X2Action_LootFountain'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);

	}


function Lootable MakeAvailableLoot(XComGameState ModifyGameState)
{
	local name LootName;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Item NewItem, SearchItem;
	local XComGameState_Unit NewUnit;
	local StateObjectReference Ref;
	local array<XComGameState_Item> CreatedLoots;
	local bool bStacked;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local bool AnyAlwaysRecoverLoot;

	AnyAlwaysRecoverLoot = false;
	History = `XCOMHISTORY;


	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	NewUnit = XComGameState_Unit(ModifyGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));

	CreatedLoots.Length = 0;
	
	//  copy any objects that have already been created into the new game state
	foreach NewUnit.PendingLoot.AvailableLoot(Ref)
	{
		NewItem = XComGameState_Item(ModifyGameState.ModifyStateObject(class'XComGameState_Item', Ref.ObjectID));
	}
	//  create new items for all loot that hasn't been created yet
	foreach NewUnit.PendingLoot.LootToBeCreated(LootName)
	{		
		ItemTemplate = ItemTemplateManager.FindItemTemplate(LootName);
		if (ItemTemplate != none)
		{
			if (bKilledByExplosion && !ItemTemplate.LeavesExplosiveRemains)
				continue;                                                                               //  item leaves nothing behind due to explosive death
			if (bKilledByExplosion && ItemTemplate.ExplosiveRemains != '')
				ItemTemplate = ItemTemplateManager.FindItemTemplate(ItemTemplate.ExplosiveRemains);     //  item leaves a different item behind due to explosive death
			
			if (ItemTemplate != none)
			{
				bStacked = false;
				if (ItemTemplate.MaxQuantity > 1)
				{
					foreach CreatedLoots(SearchItem)
					{
						if (SearchItem.GetMyTemplate() == ItemTemplate)
						{
							if (SearchItem.Quantity < ItemTemplate.MaxQuantity)
							{
								SearchItem.Quantity++;
								bStacked = true;
								break;
							}
						}
					}
					if (bStacked)
						continue;
				}
				
				NewItem = ItemTemplate.CreateInstanceFromTemplate(ModifyGameState);

				if( ItemTemplate.bAlwaysRecovered )
				{
					XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
					XComHQ = XComGameState_HeadquartersXCom(ModifyGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

					NewItem.OwnerStateObject = XComHQ.GetReference();
					XComHQ.PutItemInInventory(ModifyGameState, NewItem, true);

					AnyAlwaysRecoverLoot = true;
				}
				else
				{

					CreatedLoots.AddItem(NewItem);
					//NewUnit.AddItemToInventory(NewItem, eInvSlot_Loot, ModifyGameState);
					//NewUnit.PendingLoot.AvailableLoot.AddItem(NewItem.GetReference());
				}
			}
		}
	}
	NewUnit.PendingLoot.LootToBeCreated.Length = 0;	

	class'XComGameState_LootDrop'.static.CreateLootDrop(ModifyGameState, CreatedLoots, self, true);

	if( AnyAlwaysRecoverLoot )
	{
		ModifyGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeAlwaysRecoverLoot);
	}

	return NewUnit;
}

function VisualizeLootDestroyedByExplosives(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_Delay DelayAction;

	History = `XCOMHISTORY;

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = History.GetVisualizer(ObjectID);

	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	DelayAction.Duration = 1.5;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'XLocalizedData'.default.LootExplodedMsg, '', eColor_Bad);

	}

function VisualizeLootFountain(XComGameState VisualizeGameState)
{
	class'Helpers'.static.VisualizeLootFountainInternal(self, VisualizeGameState);
}

function bool GetLoot(StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	return class'Helpers'.static.GetLootInternal(self, ItemRef, LooterRef, ModifyGameState);
}

function bool LeaveLoot(StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	return class'Helpers'.static.LeaveLootInternal(self, ItemRef, LooterRef, ModifyGameState);
}

function UpdateLootSparklesEnabled(bool bHighlightObject)
{
	XGUnit(GetVisualizer()).UpdateLootSparklesEnabled(bHighlightObject, self);
}

function array<StateObjectReference> GetAvailableLoot()
{
	return PendingLoot.AvailableLoot;
}

function AddLoot(StateObjectReference ItemRef, XComGameState ModifyGameState)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item Item;

	NewUnitState = XComGameState_Unit(ModifyGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));

	Item = XComGameState_Item(ModifyGameState.ModifyStateObject(class'XComGameState_Item', ItemRef.ObjectID));

	if (GetTeam() == eTeam_XCom)
	{
		NewUnitState.AddItemToInventory(Item, eInvSlot_Backpack, ModifyGameState);
	}
	else
	{
		NewUnitState.PendingLoot.AvailableLoot.AddItem( Item.GetReference() );
	}
}

function RemoveLoot(StateObjectReference ItemRef, XComGameState ModifyGameState)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item Item;
	local int Index;

	NewUnitState = XComGameState_Unit(ModifyGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));

	Item = XComGameState_Item(ModifyGameState.ModifyStateObject(class'XComGameState_Item', ItemRef.ObjectID));

	if (GetTeam() == eTeam_XCom)
	{
		NewUnitState.RemoveItemFromInventory(Item, ModifyGameState);
	}
	else
	{
		Index = NewUnitState.PendingLoot.AvailableLoot.Find( 'ObjectID', Item.ObjectID );
		if (Index != INDEX_NONE)
		{
			NewUnitState.PendingLoot.AvailableLoot.Remove( Index, 1 );
		}
	}
}

function string GetLootingName()
{
	local string strName;

	if (strFirstName != "" || strLastName != "")
		strName = GetName(eNameType_Full);
	else
		strName = GetMyTemplate().strCharacterName;

	return strName;
}

simulated function TTile GetLootLocation()
{
	return TileLocation;
}

function SetLoot(const out LootResults NewLoot)
{
	if (bReadOnly)
	{
		`RedScreen("XComGameState_Unit::SetLoot - This cannot run on a read only object: " $ObjectID);
	}
	PendingLoot = NewLoot;
}

//  This should only be used when initially creating a unit, never after a unit has already been established with inventory.
function ApplyInventoryLoadout(XComGameState ModifyGameState, optional name NonDefaultLoadout)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem LoadoutItem;
	local bool bFoundLoadout;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local XComGameState_Item NewItem;
	local name UseLoadoutName, RequiredLoadout;
	local X2SoldierClassTemplate SoldierClassTemplate;

	if (NonDefaultLoadout != '')      
	{
		//  If loadout is specified, always use that.
		UseLoadoutName = NonDefaultLoadout;
	}
	else
	{
		//  If loadout was not specified, use the character template's default loadout, or the squaddie loadout for the soldier class (if any).
		UseLoadoutName = GetMyTemplate().DefaultLoadout;
		SoldierClassTemplate = GetSoldierClassTemplate();
		if (SoldierClassTemplate != none && SoldierClassTemplate.SquaddieLoadout != '')
			UseLoadoutName = SoldierClassTemplate.SquaddieLoadout;
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemTemplateManager.Loadouts(Loadout)
	{
		if (Loadout.LoadoutName == UseLoadoutName)
		{
			bFoundLoadout = true;
			break;
		}
	}
	if (bFoundLoadout)
	{
		foreach Loadout.Items(LoadoutItem)
		{
			EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(LoadoutItem.Item));
			if (EquipmentTemplate != none)
			{
				NewItem = EquipmentTemplate.CreateInstanceFromTemplate(ModifyGameState);

				//Transfer settings that were configured in the character pool with respect to the weapon. Should only be applied here
				//where we are handing out generic weapons.
				if(EquipmentTemplate.InventorySlot == eInvSlot_PrimaryWeapon || EquipmentTemplate.InventorySlot == eInvSlot_SecondaryWeapon ||
					EquipmentTemplate.InventorySlot == eInvSlot_TertiaryWeapon)
				{
					WeaponTemplate = X2WeaponTemplate(NewItem.GetMyTemplate());
					if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
					{
						NewItem.WeaponAppearance.iWeaponTint = kAppearance.iArmorTint;
					}
					else
					{
						NewItem.WeaponAppearance.iWeaponTint = kAppearance.iWeaponTint;
					}

					NewItem.WeaponAppearance.nmWeaponPattern = kAppearance.nmWeaponPattern;
				}

				AddItemToInventory(NewItem, EquipmentTemplate.InventorySlot, ModifyGameState);
			}
		}
	}
	//  Always apply the template's required loadout.
	RequiredLoadout = GetMyTemplate().RequiredLoadout;
	if (RequiredLoadout != '' && RequiredLoadout != UseLoadoutName && !HasLoadout(RequiredLoadout, ModifyGameState))
		ApplyInventoryLoadout(ModifyGameState, RequiredLoadout);

	// Give Kevlar armor if Unit's armor slot is empty
	if(IsSoldier() && GetItemInSlot(eInvSlot_Armor, ModifyGameState) == none)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('KevlarArmor'));
		NewItem = EquipmentTemplate.CreateInstanceFromTemplate(ModifyGameState);
		AddItemToInventory(NewItem, eInvSlot_Armor, ModifyGameState);
	}
}

//  Called only when ranking up from rookie to squaddie. Applies items per configured loadout, safely removing
//  items and placing them back into HQ's inventory.
function ApplySquaddieLoadout(XComGameState GameState, optional XComGameState_HeadquartersXCom XHQ = none)
{
	local X2ItemTemplateManager ItemTemplateMan;
	local X2EquipmentTemplate ItemTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local InventoryLoadout Loadout;
	local name SquaddieLoadout;
	local bool bFoundLoadout;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> UtilityItems;
	local int i;

	`assert(GameState != none);

	SquaddieLoadout = GetSoldierClassTemplate().SquaddieLoadout;
	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemTemplateMan.Loadouts(Loadout)
	{
		if (Loadout.LoadoutName == SquaddieLoadout)
		{
			bFoundLoadout = true;
			break;
		}
	}
	if (bFoundLoadout)
	{
		for (i = 0; i < Loadout.Items.Length; ++i)
		{
			ItemTemplate = X2EquipmentTemplate(ItemTemplateMan.FindItemTemplate(Loadout.Items[i].Item));
			if (ItemTemplate != none)
			{
				ItemState = none;
				// Issue #118 Start: Change hardcoded check for Utility Items to multi-item slot
				if (class'CHItemSlot'.static.SlotIsMultiItem(ItemTemplate.InventorySlot))
				// Issue #118 End
				{
					//  If we can't add a utility item, remove the first one. That should fix it. If not, we may need more logic later.
					if (!CanAddItemToInventory(ItemTemplate, ItemTemplate.InventorySlot, GameState))
					{
						UtilityItems = GetAllItemsInSlot(ItemTemplate.InventorySlot, GameState);
						if (UtilityItems.Length > 0)
						{
							ItemState = UtilityItems[0];
						}
					}
				}
				else
				{
					//  If we can't add an item, there's probably one occupying the slot already, so remove it.
					if (!CanAddItemToInventory(ItemTemplate, ItemTemplate.InventorySlot, GameState))
					{
						ItemState = GetItemInSlot(ItemTemplate.InventorySlot, GameState);
					}
				}
				//  ItemState will be populated with an item we need to remove in order to place the new item in (if any).
				if (ItemState != none)
				{
					if (ItemState.GetMyTemplateName() == ItemTemplate.DataName)
						continue;
					if (!RemoveItemFromInventory(ItemState, GameState))
					{
						`RedScreen("Unable to remove item from inventory. Squaddie loadout will be affected." @ ItemState.ToString());
						continue;
					}

					if(XHQ != none)
					{
						XHQ.PutItemInInventory(GameState, ItemState);
					}
				}
				if (!CanAddItemToInventory(ItemTemplate, ItemTemplate.InventorySlot, GameState))
				{
					`RedScreen("Unable to add new item to inventory. Squaddie loadout will be affected." @ ItemTemplate.DataName);
					continue;
				}
				ItemState = ItemTemplate.CreateInstanceFromTemplate(GameState);

				//Transfer settings that were configured in the character pool with respect to the weapon. Should only be applied here
				//where we are handing out generic weapons.
				if (ItemTemplate.InventorySlot == eInvSlot_PrimaryWeapon || ItemTemplate.InventorySlot == eInvSlot_SecondaryWeapon ||
					ItemTemplate.InventorySlot == eInvSlot_TertiaryWeapon)
				{
					WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
					if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
					{
						ItemState.WeaponAppearance.iWeaponTint = kAppearance.iArmorTint;
					}
					else
					{
						ItemState.WeaponAppearance.iWeaponTint = kAppearance.iWeaponTint;
					}
					ItemState.WeaponAppearance.nmWeaponPattern = kAppearance.nmWeaponPattern;
				}

				AddItemToInventory(ItemState, ItemTemplate.InventorySlot, GameState);
			}
			else
			{
				`RedScreen("Unknown item template" @ Loadout.Items[i].Item @ "specified in loadout" @ SquaddieLoadout);
			}
		}
	}

	// Give Kevlar armor if Unit's armor slot is empty
	if(IsSoldier() && GetItemInSlot(eInvSlot_Armor, GameState) == none)
	{
		ItemTemplate = X2EquipmentTemplate(ItemTemplateMan.FindItemTemplate('KevlarArmor'));
		ItemState = ItemTemplate.CreateInstanceFromTemplate(GameState);
		AddItemToInventory(ItemState, eInvSlot_Armor, GameState);
	}
}

//------------------------------------------------------
// Apply the best infinite armor, weapons, grenade, and utility items from the inventory
function ApplyBestGearLoadout(XComGameState NewGameState)
{
	local XComGameState_Item EquippedArmor, EquippedPrimaryWeapon, EquippedSecondaryWeapon; // Default slots
	local XComGameState_Item EquippedHeavyWeapon, EquippedGrenade, EquippedUtilityItem; // Special slots
	local array<XComGameState_Item> EquippedUtilityItems; // Utility Slots
	local array<X2ArmorTemplate> BestArmorTemplates;
	local array<X2WeaponTemplate> BestPrimaryWeaponTemplates, BestSecondaryWeaponTemplates, BestHeavyWeaponTemplates;
	local array<X2GrenadeTemplate> BestGrenadeTemplates;
	local array<X2EquipmentTemplate> BestUtilityTemplates;
	local int idx;
	
	// Armor Slot
	EquippedArmor = GetItemInSlot(eInvSlot_Armor, NewGameState);
	BestArmorTemplates = GetBestArmorTemplates();
	UpgradeEquipment(NewGameState, EquippedArmor, BestArmorTemplates, eInvSlot_Armor);

	// Primary Weapon Slot
	EquippedPrimaryWeapon = GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState);
	BestPrimaryWeaponTemplates = GetBestPrimaryWeaponTemplates();
 	UpgradeEquipment(NewGameState, EquippedPrimaryWeapon, BestPrimaryWeaponTemplates, eInvSlot_PrimaryWeapon);
	
	// Secondary Weapon Slot
	if (NeedsSecondaryWeapon())
	{
		EquippedSecondaryWeapon = GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState);
		BestSecondaryWeaponTemplates = GetBestSecondaryWeaponTemplates();
		UpgradeEquipment(NewGameState, EquippedSecondaryWeapon, BestSecondaryWeaponTemplates, eInvSlot_SecondaryWeapon);
	}

	// Heavy Weapon
	if (HasHeavyWeapon())
	{
		EquippedHeavyWeapon = GetItemInSlot(eInvSlot_HeavyWeapon, NewGameState);
		BestHeavyWeaponTemplates = GetBestHeavyWeaponTemplates();
		UpgradeEquipment(NewGameState, EquippedHeavyWeapon, BestHeavyWeaponTemplates, eInvSlot_HeavyWeapon);
	}

	// Grenade Pocket
	if (HasGrenadePocket())
	{
		EquippedGrenade = GetItemInSlot(eInvSlot_GrenadePocket, NewGameState);
		BestGrenadeTemplates = GetBestGrenadeTemplates();
		UpgradeEquipment(NewGameState, EquippedGrenade, BestGrenadeTemplates, eInvSlot_GrenadePocket);
	}

	// Utility Slot
	EquippedUtilityItems = GetAllItemsInSlot(eInvSlot_Utility, NewGameState, , true);
	BestUtilityTemplates = GetBestUtilityItemTemplates();
	for (idx = 0; idx < EquippedUtilityItems.Length; idx++)
	{
		EquippedUtilityItem = EquippedUtilityItems[idx];
		if (UpgradeEquipment(NewGameState, EquippedUtilityItem, BestUtilityTemplates, eInvSlot_Utility))
			break; // Only need to replace one utility item, so break if successful
	}

	// Always validate the loadout after upgrading everything
	ValidateLoadout(NewGameState);
}

//------------------------------------------------------
// Apply the best infinite armor, weapons, grenade, and utility items from the inventory
function array<X2EquipmentTemplate> GetBestGearForSlot(EInventorySlot Slot)
{
	local array<X2EquipmentTemplate> EmptyList;

	switch (Slot)
	{
	case eInvSlot_Armor:
		return GetBestArmorTemplates();
		break;
	case eInvSlot_PrimaryWeapon:
		return GetBestPrimaryWeaponTemplates();
		break;
	case eInvSlot_SecondaryWeapon:
		return GetBestSecondaryWeaponTemplates();
		break;
	case eInvSlot_HeavyWeapon:
		return GetBestHeavyWeaponTemplates();
		break;
	case eInvSlot_GrenadePocket:
		return GetBestGrenadeTemplates();
		break;
	case eInvSlot_Utility:
		return GetBestUtilityItemTemplates();
		break;
	default:
		// Issue #118 Start
		if (class'CHItemSlot'.static.SlotIsTemplated(Slot))
		{
			return class'CHItemSlot'.static.GetTemplateForSlot(Slot).GetBestGearForSlot(self);
		}
		// Issue #118 End
	}

	EmptyList.Length = 0;
	return EmptyList;
}

function bool UpgradeEquipment(XComGameState NewGameState, XComGameState_Item CurrentEquipment, array<X2EquipmentTemplate> UpgradeTemplates, EInventorySlot Slot, optional out XComGameState_Item UpgradeItem)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item EquippedItem;
	local X2EquipmentTemplate UpgradeTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local int idx;

	if(UpgradeTemplates.Length == 0)
	{
		return false;
	}

	// Grab HQ Object
	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}
	
	if (CurrentEquipment == none)
	{
		// Make an instance of the best equipment we found and equip it
		UpgradeItem = UpgradeTemplates[0].CreateInstanceFromTemplate(NewGameState);

		//Transfer weapon customization options. Should only be applied here when we are handing out generic weapons.
		if (Slot == eInvSlot_PrimaryWeapon || Slot == eInvSlot_SecondaryWeapon || Slot == eInvSlot_TertiaryWeapon)
		{
			WeaponTemplate = X2WeaponTemplate(UpgradeItem.GetMyTemplate());
			if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
			{
				UpgradeItem.WeaponAppearance.iWeaponTint = kAppearance.iArmorTint;
			}
			else
			{
				UpgradeItem.WeaponAppearance.iWeaponTint = kAppearance.iWeaponTint;
			}
			UpgradeItem.WeaponAppearance.nmWeaponPattern = kAppearance.nmWeaponPattern;
		}
		
		return AddItemToInventory(UpgradeItem, Slot, NewGameState, (Slot == eInvSlot_Utility));
	}
	else
	{
		for(idx = 0; idx < UpgradeTemplates.Length; idx++)
		{
			UpgradeTemplate = UpgradeTemplates[idx];

			if(UpgradeTemplate.Tier > CurrentEquipment.GetMyTemplate().Tier)
			{
				if(X2WeaponTemplate(UpgradeTemplate) != none && X2WeaponTemplate(UpgradeTemplate).WeaponCat != X2WeaponTemplate(CurrentEquipment.GetMyTemplate()).WeaponCat)
				{
					continue;
				}

				// Remove the equipped item and put it back in HQ inventory
				EquippedItem = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', CurrentEquipment.ObjectID));
				RemoveItemFromInventory(EquippedItem, NewGameState);
				XComHQ.PutItemInInventory(NewGameState, EquippedItem);

				// Make an instance of the best equipment we found and equip it
				UpgradeItem = UpgradeTemplate.CreateInstanceFromTemplate(NewGameState);
				
				//Transfer weapon customization options. Should only be applied here when we are handing out generic weapons.
				if (Slot == eInvSlot_PrimaryWeapon || Slot == eInvSlot_SecondaryWeapon || Slot == eInvSlot_TertiaryWeapon)
				{
					WeaponTemplate = X2WeaponTemplate(UpgradeItem.GetMyTemplate());
					if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
					{
						UpgradeItem.WeaponAppearance.iWeaponTint = kAppearance.iArmorTint;
					}
					else
					{
						UpgradeItem.WeaponAppearance.iWeaponTint = kAppearance.iWeaponTint;
					}
					UpgradeItem.WeaponAppearance.nmWeaponPattern = kAppearance.nmWeaponPattern;
				}

				return AddItemToInventory(UpgradeItem, Slot, NewGameState);
			}
		}
	}

	return false;
}

//------------------------------------------------------
// After loadout change verify # of slots/valid items in slots
function ValidateLoadout(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item EquippedArmor, EquippedPrimaryWeapon, EquippedSecondaryWeapon; // Default slots
	local XComGameState_Item EquippedHeavyWeapon, EquippedGrenade, EquippedAmmo, UtilityItem; // Special slots
	local array<XComGameState_Item> EquippedUtilityItems; // Utility Slots
	local int idx;
	// Issue #171 Variables
	local int NumHeavy, NumUtility, NumMinEquip, item_idx;
	local array<XComGameState_Item> EquippedHeavyWeapons;
	local array<X2EquipmentTemplate> BestUtilityItems;

	local array<CHItemSlot> ModSlots; // Variable for Issue #118

	// Grab HQ Object
	History = `XCOMHISTORY;
	
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	// Armor Slot
	EquippedArmor = GetItemInSlot(eInvSlot_Armor, NewGameState);
	if(EquippedArmor == none)
	{
		EquippedArmor = GetDefaultArmor(NewGameState);
		AddItemToInventory(EquippedArmor, eInvSlot_Armor, NewGameState);
	}

	// Primary Weapon Slot
	EquippedPrimaryWeapon = GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState);
	if(EquippedPrimaryWeapon == none)
	{
		EquippedPrimaryWeapon = GetBestPrimaryWeapon(NewGameState);
		AddItemToInventory(EquippedPrimaryWeapon, eInvSlot_PrimaryWeapon, NewGameState);
	}

	// Check Ammo Item compatibility
	// Start Issue #171 - Handling ammo pocket
	EquippedAmmo = GetItemInSlot(eInvSlot_AmmoPocket, NewGameState);
	if (EquippedAmmo != none)
	{
		if (X2AmmoTemplate(EquippedAmmo.GetMyTemplate()) != none && 
		   (!X2AmmoTemplate(EquippedAmmo.GetMyTemplate()).IsWeaponValidForAmmo(X2WeaponTemplate(EquippedPrimaryWeapon.GetMyTemplate())) ||
		   !HasAmmoPocket()))
		{
			EquippedAmmo = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedAmmo.ObjectID));
			RemoveItemFromInventory(EquippedAmmo, NewGameState);
			XComHQ.PutItemInInventory(NewGameState, EquippedAmmo);
			EquippedAmmo = none;
		}
	}

	EquippedUtilityItems = GetAllItemsInSlot(eInvSlot_Utility, NewGameState, ,true);
	for(idx = 0; idx < EquippedUtilityItems.Length; idx++)
	{
		if (X2AmmoTemplate(EquippedUtilityItems[idx].GetMyTemplate()) != none && 
		   !X2AmmoTemplate(EquippedUtilityItems[idx].GetMyTemplate()).IsWeaponValidForAmmo(X2WeaponTemplate(EquippedPrimaryWeapon.GetMyTemplate())))
		{
			EquippedAmmo = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedUtilityItems[idx].ObjectID));
			RemoveItemFromInventory(EquippedAmmo, NewGameState);
			XComHQ.PutItemInInventory(NewGameState, EquippedAmmo);
			EquippedAmmo = none;
			EquippedUtilityItems.Remove(idx, 1);
			idx--;
		}
	}

	// Secondary Weapon Slot
	EquippedSecondaryWeapon = GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState);
	// Start Issue #171
	if(EquippedSecondaryWeapon == none && NeedsSecondaryWeapon() && class'CHItemSlot'.static.SlotGetMinimumEquipped(eInvSlot_SecondaryWeapon, self) != 0)
	{
	// End Issue #171
		EquippedSecondaryWeapon = GetBestSecondaryWeapon(NewGameState);
		AddItemToInventory(EquippedSecondaryWeapon, eInvSlot_SecondaryWeapon, NewGameState);
	}
	else if(EquippedSecondaryWeapon != none && !NeedsSecondaryWeapon())
	{
		EquippedSecondaryWeapon = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedSecondaryWeapon.ObjectID));
		RemoveItemFromInventory(EquippedSecondaryWeapon, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, EquippedSecondaryWeapon);
		EquippedSecondaryWeapon = none;
	}

	// Start Issue #171
	// UtilitySlots and heavy slots (Already grabbed equipped)

	if(!IsMPCharacter())
	{
		RealizeItemSlotsCount(NewGameState);
	}

	NumHeavy = GetNumHeavyWeapons(NewGameState);

	// Heavy Weapon Slot
	EquippedHeavyWeapons = GetAllItemsInSlot(eInvSlot_HeavyWeapon, NewGameState);
	// NumMinEquip will only be relevant if the Unit has the slot, as the Max number of
	// Heavy weapons can only be > 0 when the unit has the slot.
	NumMinEquip = class'CHItemSlot'.static.SlotGetMinimumEquipped(eInvSlot_HeavyWeapon, self);
	for (idx = 0; idx < NumHeavy; idx++)
	{
		if (idx >= EquippedHeavyWeapons.Length && (idx < NumMinEquip || NumMinEquip == -1))
		{
			EquippedHeavyWeapon = GetBestHeavyWeapon(NewGameState);
			if (AddItemToInventory(EquippedHeavyWeapon, eInvSlot_HeavyWeapon, NewGameState))
			{
				EquippedHeavyWeapons.AddItem(EquippedHeavyWeapon);
			}
		}
	}

	for (idx = NumHeavy; idx < EquippedHeavyWeapons.Length; idx++)
	{
		EquippedHeavyWeapon = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedHeavyWeapons[idx].ObjectID));
		RemoveItemFromInventory(EquippedHeavyWeapon, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, EquippedHeavyWeapon);
		EquippedHeavyWeapon = none;
	}
	// End Issue #171

	// Grenade Pocket
	EquippedGrenade = GetItemInSlot(eInvSlot_GrenadePocket, NewGameState);
	NumMinEquip = class'CHItemSlot'.static.SlotGetMinimumEquipped(eInvSlot_GrenadePocket, self);
	if(EquippedGrenade == none && HasGrenadePocket() && NumMinEquip != 0)
	{
		EquippedGrenade = GetBestGrenade(NewGameState);
		AddItemToInventory(EquippedGrenade, eInvSlot_GrenadePocket, NewGameState);
	}
	else if(EquippedGrenade != none && !HasGrenadePocket())
	{
		EquippedGrenade = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedGrenade.ObjectID));
		RemoveItemFromInventory(EquippedGrenade, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, EquippedGrenade);
		EquippedGrenade = none;
	}

	// Issue #171 - code moved

	// Remove Extra Utility Items
	for(idx = GetCurrentStat(eStat_UtilityItems); idx < EquippedUtilityItems.Length; idx++)
	{
		if(idx >= EquippedUtilityItems.Length)
		{
			break;
		}

		UtilityItem = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedUtilityItems[idx].ObjectID));
		RemoveItemFromInventory(UtilityItem, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, UtilityItem);
		UtilityItem = none;
		EquippedUtilityItems.Remove(idx, 1);
		idx--;
	}

	// Equip Default Utility Item in first slot if needed
	// Start Issue #171 - Fill out slot based on inventory equipped
	NumMinEquip = class'CHItemSlot'.static.SlotGetMinimumEquipped(eInvSlot_Utility, self);
	NumUtility = GetCurrentStat(eStat_UtilityItems);
	BestUtilityItems = GetUtilityItemTemplatesByTier(true);
	for (idx = 0; idx < NumUtility; idx++)
	{
		if (idx >= EquippedUtilityItems.Length && (idx < NumMinEquip || NumMinEquip == -1))
		{
			while (BestUtilityItems.Length > 0)
			{
				// Array is already randomized, then sorted by tier, so we can just grab the first one
				item_idx = 0;
				UtilityItem = BestUtilityItems[item_idx].CreateInstanceFromTemplate(NewGameState);
				if (AddItemToInventory(UtilityItem, eInvSlot_Utility, NewGameState))
				{
					EquippedUtilityItems.AddItem(UtilityItem);
					break;
				}
				else
				{
					// Prevent leaking state objects!
					NewGameState.PurgeGameStateForObjectID(UtilityItem.ObjectID);
					BestUtilityItems.Remove(item_idx, 1);
				}
			}
		}
	// End Issue #171
	}

	// Issue #118 Start
	ModSlots = class'CHItemSlot'.static.GetAllSlotTemplates();
	for (idx = 0; idx < ModSlots.Length; idx++)
	{
		ModSlots[idx].ValidateLoadout(self, XComHQ, NewGameState);
	}
	// Issue #118 End
}

//------------------------------------------------------
function XComGameState_Item GetDefaultArmor(XComGameState NewGameState)
{
	local array<X2ArmorTemplate> ArmorTemplates;
	local XComGameState_Item ItemState;

	ArmorTemplates = GetBestArmorTemplates();

	if (ArmorTemplates.Length == 0)
	{
		return none;
	}

	ItemState = ArmorTemplates[`SYNC_RAND(ArmorTemplates.Length)].CreateInstanceFromTemplate(NewGameState);
	
	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestPrimaryWeapon(XComGameState NewGameState)
{
	local array<X2WeaponTemplate> PrimaryWeaponTemplates;
	local XComGameState_Item ItemState;

	PrimaryWeaponTemplates = GetBestPrimaryWeaponTemplates();

	if (PrimaryWeaponTemplates.Length == 0)
	{
		return none;
	}
	
	ItemState = PrimaryWeaponTemplates[`SYNC_RAND(PrimaryWeaponTemplates.Length)].CreateInstanceFromTemplate(NewGameState);
	
	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestSecondaryWeapon(XComGameState NewGameState)
{
	local array<X2WeaponTemplate> SecondaryWeaponTemplates;
	local XComGameState_Item ItemState;

	SecondaryWeaponTemplates = GetBestSecondaryWeaponTemplates();

	if (SecondaryWeaponTemplates.Length == 0)
	{
		return none;
	}

	ItemState = SecondaryWeaponTemplates[`SYNC_RAND(SecondaryWeaponTemplates.Length)].CreateInstanceFromTemplate(NewGameState);
	
	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestHeavyWeapon(XComGameState NewGameState)
{
	local array<X2WeaponTemplate> HeavyWeaponTemplates;
	local XComGameState_Item ItemState;

	HeavyWeaponTemplates = GetBestHeavyWeaponTemplates();

	if(HeavyWeaponTemplates.Length == 0)
	{
		return none;
	}
	
	ItemState = HeavyWeaponTemplates[`SYNC_RAND(HeavyWeaponTemplates.Length)].CreateInstanceFromTemplate(NewGameState);

	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestGrenade(XComGameState NewGameState)
{
	local array<X2GrenadeTemplate> GrenadeTemplates;
	local XComGameState_Item ItemState;

	GrenadeTemplates = GetBestGrenadeTemplates();

	if(GrenadeTemplates.Length == 0)
	{
		return none;
	}

	ItemState = GrenadeTemplates[`SYNC_RAND(GrenadeTemplates.Length)].CreateInstanceFromTemplate(NewGameState);

	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestUtilityItem(XComGameState NewGameState)
{
	local array<X2EquipmentTemplate> UtilityItemTemplates;
	local XComGameState_Item ItemState;

	UtilityItemTemplates = GetBestUtilityItemTemplates();

	if (UtilityItemTemplates.Length == 0)
	{
		return none;
	}
	// Issue #171, not neccessarily a weapon. Fixing here for convenience
	ItemState = UtilityItemTemplates[`SYNC_RAND(UtilityItemTemplates.Length)].CreateInstanceFromTemplate(NewGameState);

	return ItemState;
}

//------------------------------------------------------
function array<X2ArmorTemplate> GetBestArmorTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2EquipmentTemplate> DefaultEquipment;
	local X2ArmorTemplate ArmorTemplate, BestArmorTemplate;
	local array<X2ArmorTemplate> BestArmorTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default armor template
	DefaultEquipment = GetCompleteDefaultLoadout();
	for (idx = 0; idx < DefaultEquipment.Length; idx++)
	{
		BestArmorTemplate = X2ArmorTemplate(DefaultEquipment[idx]);
		if (BestArmorTemplate != none)
		{
			BestArmorTemplates.AddItem(BestArmorTemplate);
			HighestTier = BestArmorTemplate.Tier;
			break;
		}
	}

	if( XComHQ != none )
	{
		// Try to find a better armor as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

			if (ArmorTemplate != none && ArmorTemplate.bInfiniteItem && (BestArmorTemplate == none || 
				(BestArmorTemplates.Find(ArmorTemplate) == INDEX_NONE && ArmorTemplate.Tier >= BestArmorTemplate.Tier))
				&& GetSoldierClassTemplate().IsArmorAllowedByClass(ArmorTemplate))
			{
				BestArmorTemplate = ArmorTemplate;
				BestArmorTemplates.AddItem(ArmorTemplate);
				HighestTier = BestArmorTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestArmorTemplates.Length; idx++)
	{
		if(BestArmorTemplates[idx].Tier < HighestTier)
		{
			BestArmorTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestArmorTemplates;
}

//------------------------------------------------------
function array<X2WeaponTemplate> GetBestPrimaryWeaponTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2EquipmentTemplate> DefaultEquipment;
	local X2WeaponTemplate WeaponTemplate, BestWeaponTemplate;
	local array<X2WeaponTemplate> BestWeaponTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default primary weapon template
	DefaultEquipment = GetCompleteDefaultLoadout();
	for (idx = 0; idx < DefaultEquipment.Length; idx++)
	{
		if (X2WeaponTemplate(DefaultEquipment[idx]) != none && DefaultEquipment[idx].InventorySlot == eInvSlot_PrimaryWeapon)
		{
			BestWeaponTemplate = X2WeaponTemplate(DefaultEquipment[idx]);
			BestWeaponTemplates.AddItem(BestWeaponTemplate);
			HighestTier = BestWeaponTemplate.Tier;
			break;
		}
	}

	if( XComHQ != none )
	{
		// Try to find a better primary weapon as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

			if (WeaponTemplate != none && WeaponTemplate.bInfiniteItem && (BestWeaponTemplate == none || (BestWeaponTemplates.Find(WeaponTemplate) == INDEX_NONE && WeaponTemplate.Tier >= BestWeaponTemplate.Tier)) && 
				WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon && GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate))
			{
				BestWeaponTemplate = WeaponTemplate;
				BestWeaponTemplates.AddItem(BestWeaponTemplate);
				HighestTier = BestWeaponTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestWeaponTemplates.Length; idx++)
	{
		if(BestWeaponTemplates[idx].Tier < HighestTier)
		{
			BestWeaponTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestWeaponTemplates;
}

//------------------------------------------------------
function array<X2WeaponTemplate> GetBestSecondaryWeaponTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2EquipmentTemplate> DefaultEquipment;
	local X2WeaponTemplate WeaponTemplate, BestWeaponTemplate;
	local array<X2WeaponTemplate> BestWeaponTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default secondary weapon template
	DefaultEquipment = GetCompleteDefaultLoadout();
	for (idx = 0; idx < DefaultEquipment.Length; idx++)
	{
		if (X2WeaponTemplate(DefaultEquipment[idx]) != none && DefaultEquipment[idx].InventorySlot == eInvSlot_SecondaryWeapon)
		{
			BestWeaponTemplate = X2WeaponTemplate(DefaultEquipment[idx]);
			BestWeaponTemplates.AddItem(BestWeaponTemplate);
			HighestTier = BestWeaponTemplate.Tier;
			break;
		}
	}

	if( XComHQ != none )
	{
		// Try to find a better secondary weapon as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

			if(WeaponTemplate != none && WeaponTemplate.bInfiniteItem && (BestWeaponTemplate == none || (BestWeaponTemplates.Find(WeaponTemplate) == INDEX_NONE && WeaponTemplate.Tier >= BestWeaponTemplate.Tier)) &&
				WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon && GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate))
			{
				BestWeaponTemplate = WeaponTemplate;
				BestWeaponTemplates.AddItem(BestWeaponTemplate);
				HighestTier = BestWeaponTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestWeaponTemplates.Length; idx++)
	{
		if(BestWeaponTemplates[idx].Tier < HighestTier)
		{
			BestWeaponTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestWeaponTemplates;
}

//------------------------------------------------------
function array<X2WeaponTemplate> GetBestHeavyWeaponTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2WeaponTemplate HeavyWeaponTemplate, BestHeavyWeaponTemplate;
	local array<X2WeaponTemplate> BestHeavyWeaponTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default heavy weapon template
	BestHeavyWeaponTemplate = X2WeaponTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'X2Item_HeavyWeapons'.default.FreeHeavyWeaponToEquip));
	BestHeavyWeaponTemplates.AddItem(BestHeavyWeaponTemplate);
	HighestTier = BestHeavyWeaponTemplate.Tier;

	if( XComHQ != none )
	{
		// Try to find a better grenade as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			HeavyWeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

			if(HeavyWeaponTemplate != none && HeavyWeaponTemplate.bInfiniteItem && (BestHeavyWeaponTemplate == none || 
				(BestHeavyWeaponTemplates.Find(HeavyWeaponTemplate) == INDEX_NONE && HeavyWeaponTemplate.Tier >= BestHeavyWeaponTemplate.Tier)) &&
				HeavyWeaponTemplate.InventorySlot == eInvSlot_HeavyWeapon && GetSoldierClassTemplate().IsWeaponAllowedByClass(HeavyWeaponTemplate))
			{
				BestHeavyWeaponTemplate = HeavyWeaponTemplate;
				BestHeavyWeaponTemplates.AddItem(BestHeavyWeaponTemplate);
				HighestTier = BestHeavyWeaponTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestHeavyWeaponTemplates.Length; idx++)
	{
		if(BestHeavyWeaponTemplates[idx].Tier < HighestTier)
		{
			BestHeavyWeaponTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestHeavyWeaponTemplates;
}

//------------------------------------------------------
function array<X2GrenadeTemplate> GetBestGrenadeTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2GrenadeTemplate GrenadeTemplate, BestGrenadeTemplate;
	local array<X2GrenadeTemplate> BestGrenadeTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default grenade template
	BestGrenadeTemplate = X2GrenadeTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'X2Ability_GrenadierAbilitySet'.default.FreeGrenadeForPocket));
	BestGrenadeTemplates.AddItem(BestGrenadeTemplate);
	HighestTier = BestGrenadeTemplate.Tier;

	if( XComHQ != none )
	{
		// Try to find a better grenade as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			GrenadeTemplate = X2GrenadeTemplate(ItemState.GetMyTemplate());

			if(GrenadeTemplate != none && GrenadeTemplate.bInfiniteItem && (BestGrenadeTemplate == none || (BestGrenadeTemplates.Find(GrenadeTemplate) == INDEX_NONE && GrenadeTemplate.Tier >= BestGrenadeTemplate.Tier)))
			{
				BestGrenadeTemplate = GrenadeTemplate;
				BestGrenadeTemplates.AddItem(BestGrenadeTemplate);
				HighestTier = BestGrenadeTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestGrenadeTemplates.Length; idx++)
	{
		if(BestGrenadeTemplates[idx].Tier < HighestTier)
		{
			BestGrenadeTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestGrenadeTemplates;
}

//------------------------------------------------------
// Issue #171 Start
function array<X2EquipmentTemplate> GetUtilityItemTemplatesByTier(optional bool bRandomizeWithinTiers)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2EquipmentTemplate> DefaultEquipment;
	local X2EquipmentTemplate UtilityTemplate;
	local array<X2EquipmentTemplate> BestUtilityTemplates;
	local XComGameState_Item ItemState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default utility template
	DefaultEquipment = GetCompleteDefaultLoadout();
	for (idx = 0; idx < DefaultEquipment.Length; idx++)
	{
		if (DefaultEquipment[idx].InventorySlot == eInvSlot_Utility)
		{
			BestUtilityTemplates.AddItem(DefaultEquipment[idx]);
			break;
		}
	}

	if( XComHQ != none )
	{
		// Try to find a better utility item as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			UtilityTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());

			if(UtilityTemplate != none && UtilityTemplate.bInfiniteItem && BestUtilityTemplates.Find(UtilityTemplate) == INDEX_NONE
			   && UtilityTemplate.InventorySlot == eInvSlot_Utility)
			{
				BestUtilityTemplates.AddItem(UtilityTemplate);
			}
		}
	}

	if (bRandomizeWithinTiers)
	{
		BestUtilityTemplates.RandomizeOrder();
	}
	BestUtilityTemplates.Sort(EquipmentByTier);

	return BestUtilityTemplates;
}

private function int EquipmentByTier(X2EquipmentTemplate A, X2EquipmentTemplate B)
{
	return A.Tier - B.Tier;
}

function array<X2EquipmentTemplate> GetBestUtilityItemTemplates()
{
	local array<X2EquipmentTemplate> UtilityTemplates;
	local int i, HighestTier;

	UtilityTemplates = GetUtilityItemTemplatesByTier(false);

	if (UtilityTemplates.Length > 0)
	{
		HighestTier = UtilityTemplates[0].Tier;
		// The array is sorted by tier. This means that we can find the first Item with a lower tier
		// and remove all subsequent items in the array with one function call
		for (i = 1; i < UtilityTemplates.Length; i++)
		{
			if (UtilityTemplates[i].Tier < HighestTier)
			{
				// i is the first item that needs to be removed, UtilityTemplates.Length - i is the number we need to remove
				UtilityTemplates.Remove(i, UtilityTemplates.Length - i);
				break;
			}
		}
	}

	return UtilityTemplates;
}
// Issue #171 End

//------------------------------------------------------
function bool NeedsSecondaryWeapon()
{
	return GetSoldierClassTemplate().bNoSecondaryWeapon == false;
}

//------------------------------------------------------
// Clear the loadout and remove the item game states (used in Debug Strategy)
function BlastLoadout(XComGameState ModifyGameState)
{
	local int idx;

	for(idx = 0; idx < InventoryItems.Length; idx++)
	{
		ModifyGameState.RemoveStateObject(InventoryItems[idx].ObjectID);
	}

	InventoryItems.Length = 0;
}

//  This is for clearing the list out after the unit's inventory has been converted into a soldier kit, none of the items should be destroyed.
function EmptyInventoryItems()
{
	InventoryItems.Length = 0;
}

// Makes this soldiers items available, but stores references to those items so they can attempt to reequip them
function MakeItemsAvailable(XComGameState NewGameState, optional bool bStoreOldItems = true, optional array<EInventorySlot> SlotsToClear)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> AllItems;
	local EInventorySlot eSlot;
	local EquipmentInfo OldEquip;
	local int idx;
	// local bool bClearAll; // Issue #189

	History = `XCOMHISTORY;
	// Issue #189 Start
	// bClearAll = (SlotsToClear.Length == 0);
	if (SlotsToClear.Length == 0)
	{
		// This will primarily avoid unequipping the Ternary-Septernary slots, as well as the Backpack/Loot/Mission slots (which should be empty already).
		class'CHItemSlot'.static.CollectSlots(class'CHItemSlot'.const.SLOT_ALL, SlotsToClear);
	}
	// Issue #189 End

	// Grab HQ Object
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	// Remove all items, store references to them, and place in HQ inventory
	AllItems = GetAllInventoryItems(NewGameState, true);

	for(idx = 0; idx <AllItems.Length; idx++)
	{
		eSlot = AllItems[idx].InventorySlot;
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(AllItems[idx].ObjectID));

		// Issue #189 - bClearAll is not a thing
		if(/*bClearAll || */SlotsToClear.Find(eSlot) != INDEX_NONE)
		{
			ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));

			if(RemoveItemFromInventory(ItemState, NewGameState))
			{
				if(bStoreOldItems)
				{
					OldEquip.EquipmentRef = ItemState.GetReference();
					OldEquip.eSlot = eSlot;
					OldInventoryItems.AddItem(OldEquip);
				}
				
				XComHQ.PutItemInInventory(NewGameState, ItemState);
			}
			else
			{
				// Item wasn't removed, so don't keep it in the NewGameState
				NewGameState.PurgeGameStateForObjectID(ItemState.ObjectID);
			}
		}
	}

	// Equip required loadout if needed
	if(GetMyTemplate().RequiredLoadout != '' && !HasLoadout(GetMyTemplate().RequiredLoadout, NewGameState))
	{
		ApplyInventoryLoadout(NewGameState, GetMyTemplate().RequiredLoadout);
	}

	if (!bIsSuperSoldier) //Will already have the best gear
	{
		ApplyBestGearLoadout(NewGameState);
	}
}

// Combines rookie and squaddie loadouts so that things like kevlar armor and grenades are included
private function array<X2EquipmentTemplate> GetCompleteDefaultLoadout()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem LoadoutItem;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<X2EquipmentTemplate> CompleteDefaultLoadout;
	local bool bCanAdd;
	local int idx;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// First grab squaddie loadout if possible
	SoldierClassTemplate = GetSoldierClassTemplate();

	if(SoldierClassTemplate != none && SoldierClassTemplate.SquaddieLoadout != '')
	{
		foreach ItemTemplateManager.Loadouts(Loadout)
		{
			if(Loadout.LoadoutName == SoldierClassTemplate.SquaddieLoadout)
			{
				foreach Loadout.Items(LoadoutItem)
				{
					EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(LoadoutItem.Item));

					if(EquipmentTemplate != none)
					{
						CompleteDefaultLoadout.AddItem(EquipmentTemplate);
					}
				}

				break;
			}
		}
	}

	// Next grab default loadout
	foreach ItemTemplateManager.Loadouts(Loadout)
	{
		if(Loadout.LoadoutName == GetMyTemplate().DefaultLoadout)
		{
			foreach Loadout.Items(LoadoutItem)
			{
				EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(LoadoutItem.Item));

				if(EquipmentTemplate != none)
				{
					bCanAdd = true;
					for(idx = 0; idx < CompleteDefaultLoadout.Length; idx++)
					{
						if(EquipmentTemplate.InventorySlot == CompleteDefaultLoadout[idx].InventorySlot)
						{
							bCanAdd = false;
							break;
						}
					}

					if(bCanAdd)
					{
						CompleteDefaultLoadout.AddItem(EquipmentTemplate);
					}
				}
			}

			break;
		}
	}

	return CompleteDefaultLoadout;
}

// Equip old items (after recovering from an injury, etc.)
function EquipOldItems(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState, InvItemState;
	local array<XComGameState_Item> UtilityItems;
	local X2EquipmentTemplate ItemTemplate;
	local int idx, InvIndex;

	History = `XCOMHISTORY;

	if(OldInventoryItems.Length == 0)
	{
		// Make sure they have the most updated gear, even if they didn't have anything saved
		ApplyBestGearLoadout(NewGameState);
		return;
	}

	// Sort the old inventory items (armors need to be equipped first)
	OldInventoryItems.Sort(SortOldEquipment);

	// Grab HQ Object
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	// Try to find old items
	for(idx = 0; idx < OldInventoryItems.Length; idx++)
	{
		ItemState = none;
		InvIndex = XComHQ.Inventory.Find('ObjectID', OldInventoryItems[idx].EquipmentRef.ObjectID);

		if(InvIndex != INDEX_NONE)
		{
			// Found the exact item in the inventory, so it wasn't equipped by another soldier
			XComHQ.GetItemFromInventory(NewGameState, XComHQ.Inventory[InvIndex], InvItemState);
		}
		else
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(OldInventoryItems[idx].EquipmentRef.ObjectID));

			// Try to find an unmodified item with the same template
			for(InvIndex = 0; InvIndex < XComHQ.Inventory.Length; InvIndex++)
			{
				InvItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[InvIndex].ObjectID));

				if(InvItemState != none && !InvItemState.HasBeenModified() && InvItemState.GetMyTemplateName() == ItemState.GetMyTemplateName())
				{
					XComHQ.GetItemFromInventory(NewGameState, XComHQ.Inventory[InvIndex], InvItemState);
					break;
				}

				InvItemState = none;
			}
		}

		// We found a version of the old item available to equip
		if(InvItemState != none)
		{
			InvItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', InvItemState.ObjectID));
			
			ItemTemplate = X2EquipmentTemplate(InvItemState.GetMyTemplate());
			if(ItemTemplate != none)
			{
				ItemState = none;


				//  If we can't add an item, there's probably one occupying the slot already, so find it so we can remove it.
				//start issue #114: pass along item state in case there's a reason the soldier should be unable to re-equip from a mod
				if(!CanAddItemToInventory(ItemTemplate, OldInventoryItems[idx].eSlot, NewGameState, InvItemState.Quantity, InvItemState))
				{
          //end issue #114
					// Issue #118 Start: change hardcoded check for utility item
					if (class'CHItemSlot'.static.SlotIsMultiItem(OldInventoryItems[idx].eSlot))
					{
						// If there are multiple utility items, grab the last one to try and replace it with the restored item
						UtilityItems = GetAllItemsInSlot(OldInventoryItems[idx].eSlot, NewGameState, , true);
						ItemState = UtilityItems[UtilityItems.Length - 1];
					}
					else
					{
						// Otherwise just look for an item in the slot we want to restore
						ItemState = GetItemInSlot(OldInventoryItems[idx].eSlot, NewGameState);
					}
				}
        
				// If we found an item to replace with the restored equipment, it will be stored in ItemState, and we need to put it back into the inventory
				if(ItemState != none)
				{
					ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));
					
					// Try to remove the item we want to replace from our inventory
					if(!RemoveItemFromInventory(ItemState, NewGameState))
					{
						// Removing the item failed, so add our restored item back to the HQ inventory
						XComHQ.PutItemInInventory(NewGameState, InvItemState);
						continue;
					}

					// Otherwise we successfully removed the item, so add it to HQ's inventory
					XComHQ.PutItemInInventory(NewGameState, ItemState);
				}

				// If we still can't add the restored item to our inventory, put it back into the HQ inventory where we found it and move on
				//issue #114: pass along item state in case a mod has a reason to prevent this from being equipped
				if(!CanAddItemToInventory(ItemTemplate, OldInventoryItems[idx].eSlot, NewGameState, InvItemState.Quantity, InvItemState))
				{
				//end issue #114
					XComHQ.PutItemInInventory(NewGameState, InvItemState);
					continue;
				}

				if(ItemTemplate.IsA('X2WeaponTemplate'))
				{
					if(ItemTemplate.InventorySlot == eInvSlot_PrimaryWeapon)
						InvItemState.ItemLocation = eSlot_RightHand;
					else
						InvItemState.ItemLocation = X2WeaponTemplate(ItemTemplate).StowedLocation;
				}

				// Add the restored item to our inventory
				AddItemToInventory(InvItemState, OldInventoryItems[idx].eSlot, NewGameState);
			}
		}
	}

	OldInventoryItems.Length = 0;
	ApplyBestGearLoadout(NewGameState);
}

private function int SortOldEquipment(EquipmentInfo OldEquipA, EquipmentInfo OldEquipB)
{
	return (int(OldEquipB.eSlot) - int(OldEquipA.eSlot));
}


//------------------------------------------------------
// A ham handed way of ensuring that we don't double up on names
static function NameCheck( XGCharacterGenerator CharGen, XComGameState_Unit Soldier, ENameType NameType )
{
	local int iCounter;
	local string FirstName;
	local string LastName;

	iCounter = 10;

	while( NameMatch(Soldier, NameType) && iCounter > 0 )
	{
		FirstName = Soldier.GetFirstName();
		LastName = Soldier.GetLastName();
		CharGen.GenerateName( Soldier.kAppearance.iGender, Soldier.GetCountry(), FirstName, LastName, Soldier.kAppearance.iRace );
		iCounter--;
	}
}

//------------------------------------------------------
static function bool NameMatch( XComGameState_Unit Soldier, ENameType NameType )
{
	local XComGameState_Unit OtherSoldier;
	
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', OtherSoldier, eReturnType_Reference)
	{
		if( Soldier == OtherSoldier )
			continue;
		if( OtherSoldier.GetName(NameType) == Soldier.GetName(NameType) )
			return true;
	}

	return false;
}


function string Stat_ToString(const out CharacterStat Stat)
{
	local String Str;
	Str = `ShowEnum(ECharStatType, Stat.Type, Type) @ `ShowVar(Stat.CurrentValue, CurrentValue) @ `ShowVar(Stat.BaseMaxValue, BaseMaxValue) @ `ShowVar(Stat.MaxValue, MaxValue);
	return Str;
}

function string CharacterStats_ToString()
{
	local string Str;
	local int i;

	for (i = 0; i < eStat_MAX; ++i)
	{
		Str $= Stat_ToString(CharacterStats[i]) $ "\n";
	}
	return Str;
}


function bool HasSeenCorpse( int iCorpseID )
{
	local XComGameState_AIUnitData AIGameState;
	local int AIUnitDataID;
	AIUnitDataID = GetAIUnitDataID();
	if( AIUnitDataID > 0 )
	{
		AIGameState = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(AIUnitDataID));
		return AIGameState.HasSeenCorpse(iCorpseID);
	}
	return false;
}

function MarkCorpseSeen(int CorpseID)
{
	local int AIUnitDataID;
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule NewContext;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	AIUnitDataID = GetAIUnitDataID();
	if( AIUnitDataID > 0 && CorpseID > 0 )
	{
		`logAI("Marking Corpse#"$CorpseID@"seen to AI #" $ ObjectID);
		NewContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_MarkCorpseSeen);
		NewContext.AIRef = History.GetGameStateForObjectID(AIUnitDataID).GetReference();
		NewContext.UnitRef = History.GetGameStateForObjectID(CorpseID).GetReference();
		NewGameState = NewContext.ContextBuildGameState();
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function int GetNumVisibleEnemyUnits( bool bAliveOnly=true, bool bBreakOnAnyHits=false, bool bIncludeUnspotted=false, int HistoryIndex=-1, bool bIncludeIncapacitated=false, bool bIncludeCosmetic=false, bool bIncludeLost=true )
{
	local int NumVisibleEnemies;
	local array<StateObjectReference> VisibleUnits;
	local StateObjectReference kObjRef;
	local XComGameState_Unit kEnemy;
	local bool bSpottedOnly;
	if (!bIncludeUnspotted && ControllingPlayerIsAI())
	{
		bSpottedOnly = true;
	}

	NumVisibleEnemies = 0;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(ObjectID, VisibleUnits);
	foreach VisibleUnits(kObjRef)
	{
		kEnemy = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kObjRef.ObjectID, , HistoryIndex));
		if (kEnemy != None && kEnemy.IsAlive() && (!bSpottedOnly || kEnemy.IsSpotted()))
		{
			if(   ( !bIncludeIncapacitated && kEnemy.IsIncapacitated() )
			   || ( !bIncludeCosmetic && kEnemy.GetMyTemplate().bIsCosmetic ) )
			{
				continue;
			}
			if (!bIncludeLost && kEnemy.GetTeam() == eTeam_TheLost)
			{
				continue;
			}

			NumVisibleEnemies++; 
			if (bBreakOnAnyHits)
				break;// In case we want to just return 1 if any visible enemies.
		}
	}
	return NumVisibleEnemies;
}

function ApplyTraversalChanges(const X2Effect_PersistentTraversalChange TraversalChange)
{
	local int i;

	for (i = 0; i < TraversalChange.aTraversalChanges.Length; ++i)
	{
		TraversalChanges.AddItem(TraversalChange.aTraversalChanges[i]);
	}
	UpdateTraversals();
}

function UnapplyTraversalChanges(const X2Effect_PersistentTraversalChange TraversalChange)
{
	local int i, j;

	for (i = 0; i < TraversalChange.aTraversalChanges.Length; ++i)
	{
		for (j = 0; j < TraversalChanges.Length; ++j)
		{
			if (TraversalChanges[j].Traversal == TraversalChange.aTraversalChanges[i].Traversal)
			{
				if (TraversalChanges[j].bAllowed == TraversalChange.aTraversalChanges[i].bAllowed)
				{
					TraversalChanges.Remove(j, 1);
					break;
				}
			}
		}
	}
	UpdateTraversals();
}

function UpdateTraversals()
{
	local int i, j;
	local bool EffectAllows, EffectDisallows;
	
	ResetTraversals();

	if (TraversalChanges.Length > 0)
	{
		for (i = eTraversal_Normal; i < eTraversal_Unreachable; ++i)
		{
			EffectAllows = false;
			EffectDisallows = false;
			for (j = 0; j < TraversalChanges.Length; ++j)
			{
				if (TraversalChanges[j].Traversal == i)
				{
					if (TraversalChanges[j].bAllowed)
					{
						//  if an effect allows the traversal, it will be enabled as long as no other effect disallows it
						EffectAllows = true;
					}
					else
					{
						//  if an effect disallows the traversal, it will be disabled
						EffectDisallows = true;
						break;
					}
				}
			}
			if (EffectDisallows)
				aTraversals[i] = 0;
			else if (EffectAllows)
				aTraversals[i] = 1;
		}
	}
}

function SetSoldierProgression(const out array<SCATProgression> Progression)
{
	m_SoldierProgressionAbilties = Progression;
}

//  returns the amount of excess xp that was wasted by not being able to rank up more than once
function int AddXp(int Delta)
{
	local int NewXp, RankXp, ExcessXp;

	NewXp = m_iXp + Delta;

	if (m_SoldierRank + 2 < `GET_MAX_RANK)
	{
		//  a soldier cannot gain enough xp to gain 2 levels at the end of one mission, so restrict xp to just below that amount
		RankXp = class'X2ExperienceConfig'.static.GetRequiredXp(m_SoldierRank + 2) - 1;
	}
	else
	{
		//  don't let a soldier accumulate xp beyond max rank
		RankXp = class'X2ExperienceConfig'.static.GetRequiredXp(`GET_MAX_RANK);		
	}
	RankXp = max(RankXp, 0);
	if (NewXp > RankXp)
	{
		ExcessXp = NewXp - RankXp;
		NewXp = RankXp;
	}
	m_iXp = NewXp;
	m_iXp = max(m_iXp, 0);

	return ExcessXp;
}

function SetXPForRank(int SoldierRank)
{
	m_iXp = class'X2ExperienceConfig'.static.GetRequiredXp(SoldierRank);
}

function SetKillsForRank(int SoldierRank)
{
	NonTacticalKills = max(class'X2ExperienceConfig'.static.GetRequiredKills(SoldierRank) - GetTotalNumKills(false), 0);
}

function int GetXPValue()
{
	return m_iXp;
}

function int GetTotalNumKills(optional bool bIncludeNonTacticalKills = true)
{
	local int NumKills;

	NumKills = Round(KillCount);

	// Increase kills for WetWork bonus if appropriate - DEPRECATED
	NumKills += Round(WetWorkKills * class'X2ExperienceConfig'.default.NumKillsBonus);

	// Add in bonus kills
	NumKills += Round(BonusKills);

	//  Add number of kills from assists
	NumKills += GetNumKillsFromAssists();

	// Add required kills of StartingRank
	NumKills += class'X2ExperienceConfig'.static.GetRequiredKills(StartingRank);

	// Add Non-tactical kills (from covert actions)
	if(bIncludeNonTacticalKills)
	{
		NumKills += NonTacticalKills;
	}

	return NumKills;
}

function bool CanRankUpSoldier()
{
	local int NumKills;

	if (m_SoldierRank + 1 < `GET_MAX_RANK && !bRankedUp)
	{
		NumKills = GetTotalNumKills();

		//  Check required xp if that system is enabled
		if (class'X2ExperienceConfig'.default.bUseFullXpSystem)
		{
			if (m_iXp < class'X2ExperienceConfig'.static.GetRequiredXp(m_SoldierRank + 1))
				return false;
		}

		if ( NumKills >= class'X2ExperienceConfig'.static.GetRequiredKills(m_SoldierRank + 1)
			&& (GetStatus() != eStatus_PsiTesting && GetStatus() != eStatus_Training) 
			&& !GetSoldierClassTemplate().bBlockRankingUp)
			return true;
	}

	return false;
}

function RankUpSoldier(XComGameState NewGameState, optional name SoldierClass, optional bool bRecoveredFromBadClassData)
{
	local X2SoldierClassTemplate Template;
	local int RankIndex, i, MaxStat, NewMaxStat, StatVal, NewCurrentStat, StatCap;
	local float APReward;
	local bool bInjured;
	local array<SoldierClassStatType> StatProgression;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<SoldierClassAbilityType> RankAbilities;
	
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	bInjured = IsInjured();

	if (!class'X2ExperienceConfig'.default.bUseFullXpSystem)
		bRankedUp = true;

	RankIndex = m_SoldierRank;
	if (m_SoldierRank == 0)
	{
		if(SoldierClass == '')
		{
			SoldierClass = XComHQ.SelectNextSoldierClass();
		}

		SetSoldierClassTemplate(SoldierClass);
		BuildAbilityTree();
		
		if (GetSoldierClassTemplateName() == 'PsiOperative')
		{
			RollForPsiAbilities();

			// Adjust the soldiers appearance to have white hair and purple eyes - not permanent
			kAppearance.iHairColor = 25;
			kAppearance.iEyeColor = 19;
		}
		else
		{
			// Add new Squaddie abilities to the Unit if they aren't a Psi Op
			RankAbilities = AbilityTree[0].Abilities;
			for (i = 0; i < RankAbilities.Length; ++i)
			{
				BuySoldierProgressionAbility(NewGameState, 0, i);
			}

			bNeedsNewClassPopup = true;
		}
	}
	
	Template = GetSoldierClassTemplate();
	
	// Attempt to recover from having an invalid class
	if(Template == none)
	{
		`RedScreen("Invalid ClassTemplate detected, this unit has been reset to Rookie and given a new promotion. Please inform sbatista and provide a save.\n\n" $ GetScriptTrace());
		ResetRankToRookie();

		// This check prevents an infinite loop in case a valid class is not found
		if(!bRecoveredFromBadClassData)
		{
			RankUpSoldier(NewGameState, XComHQ.SelectNextSoldierClass(), true);
			return;
		}
	}

	if (RankIndex >= 0 && RankIndex < Template.GetMaxConfiguredRank())
	{
		m_SoldierRank++;

		StatProgression = Template.GetStatProgression(RankIndex);
		if (m_SoldierRank > 0)
		{
			for (i = 0; i < class'X2SoldierClassTemplateManager'.default.GlobalStatProgression.Length; ++i)
			{
				StatProgression.AddItem(class'X2SoldierClassTemplateManager'.default.GlobalStatProgression[i]);
			}
		}

		for (i = 0; i < StatProgression.Length; ++i)
		{
			StatVal = StatProgression[i].StatAmount;
			//  add random amount if any
			if (StatProgression[i].RandStatAmount > 0)
			{
				StatVal += `SYNC_RAND(StatProgression[i].RandStatAmount);
			}

			if((StatProgression[i].StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike' ))
			{
				StatVal *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
			}

			MaxStat = GetMaxStat(StatProgression[i].StatType);
			//  cap the new value if required
			if (StatProgression[i].CapStatAmount > 0)
			{
				StatCap = StatProgression[i].CapStatAmount;

				if((i == eStat_HP) && `SecondWaveEnabled('BetaStrike' ))
				{
					StatCap *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
				}

				if (StatVal + MaxStat > StatCap)
					StatVal = StatCap - MaxStat;
			}

			// If the Soldier has been shaken, save any will bonus from ranking up to be applied when they recover
			if (StatProgression[i].StatType == eStat_Will && bIsShaken)
			{
				SavedWillValue += StatVal;
			}
			else
			{				
				NewMaxStat = MaxStat + StatVal;
				NewCurrentStat = int(GetCurrentStat(StatProgression[i].StatType)) + StatVal;
				SetBaseMaxStat(StatProgression[i].StatType, NewMaxStat);
				if (StatProgression[i].StatType != eStat_HP || !bInjured)
				{
					SetCurrentStat(StatProgression[i].StatType, NewCurrentStat);
				}
			}
		}

		// When the soldier ranks up to Corporal, they start earning Ability Points
		if (m_SoldierRank >= 2 && !bIsSuperSoldier)
		{
			if (IsResistanceHero())
			{
				APReward = GetResistanceHeroAPAmount(m_SoldierRank, ComInt);
			}
			else if(Template.bAllowAWCAbilities)
			{
				APReward = GetBaseSoldierAPAmount(ComInt);
			}
			AbilityPoints += Round(APReward);
			
			if (APReward > 0)
			{
				`XEVENTMGR.TriggerEvent('AbilityPointsChange', self, , NewGameState);
			}
		}

		`XEVENTMGR.TriggerEvent('UnitRankUp', self, , NewGameState);
	}

	if (m_SoldierRank == class'X2SoldierClassTemplateManager'.default.NickNameRank)
	{
		if (strNickName == "" && Template.RandomNickNames.Length > 0)
		{
			strNickName = GenerateNickname();
		}
	}

	if (XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		if(XComHQ != none)
		{
			if(XComHQ.HighestSoldierRank < m_SoldierRank)
			{
				XComHQ.HighestSoldierRank = m_SoldierRank;
			}
		
			// If this soldier class can gain AWC abilities
			if (Template.bAllowAWCAbilities)
			{
				RollForTrainingCenterAbilities(); // Roll for Training Center extra abilities if they haven't been already generated
			}
		}
	}
}

// Set bRandomize to true in the case of something like training roulette
function BuildAbilityTree(optional bool bRandomize = false)
{
	local X2SoldierClassTemplate ClassTemplate;
	local SoldierRankAbilities RankAbilities, EmptyRankAbilities;
	local array<SoldierClassRandomAbilityDeck> RandomAbilityDecks;
	local SoldierClassRandomAbilityDeck RandomDeck;
	local array<SoldierClassAbilitySlot> AllAbilitySlots;
	local SoldierClassAbilitySlot AbilitySlot;
	local SoldierClassAbilityType EmptyAbility;
	local int RankIndex, SlotIndex, DeckIndex;

	ClassTemplate = GetSoldierClassTemplate();
	AbilityTree.Length = 0;

	if(ClassTemplate != none)
	{
		// TODO: @mnauta check for bRandomize and redirect here
		
		// Grab random ability decks
		RandomAbilityDecks = ClassTemplate.RandomAbilityDecks;

		// Go rank by rank, filling in our tree
		for(RankIndex = 0; RankIndex < ClassTemplate.GetMaxConfiguredRank(); RankIndex++)
		{
			RankAbilities = EmptyRankAbilities;
			AllAbilitySlots = ClassTemplate.GetAbilitySlots(RankIndex);

			// Determine ability (or lack thereof) from each slot
			for(SlotIndex = 0; SlotIndex < AllAbilitySlots.Length; SlotIndex++)
			{
				AbilitySlot = AllAbilitySlots[SlotIndex];

				// First check for random ability from deck
				if(AbilitySlot.RandomDeckName != '')
				{
					DeckIndex = RandomAbilityDecks.Find('DeckName', AbilitySlot.RandomDeckName);

					if(DeckIndex != INDEX_NONE)
					{
						RandomDeck = RandomAbilityDecks[DeckIndex];
						RankAbilities.Abilities.AddItem(GetAbilityFromRandomDeck(RandomDeck));
						RandomAbilityDecks[DeckIndex] = RandomDeck; // Resave the deck so we don't get the same abilities multiple times
					}
					else
					{
						// Deck not found, probably a data error
						`RedScreen("Random ability deck" @ string(AbilitySlot.RandomDeckName) @ "not found. Probably a config error. @gameplay @mnauta");
						RankAbilities.Abilities.AddItem(EmptyAbility);
					}
				}
				else
				{
					// Use the ability type listed (can be blank)
					RankAbilities.Abilities.AddItem(AbilitySlot.AbilityType);
				}
			}

			// Add the rank to the ability tree
			AbilityTree.AddItem(RankAbilities);
		}
	}
	else
	{
		`RedScreen("Tried to build soldier ability tree without a set soldier class. @gameplay @mnauta");
	}
}

// Gets and removes the ability from the deck
private function SoldierClassAbilityType GetAbilityFromRandomDeck(out SoldierClassRandomAbilityDeck RandomDeck)
{
	local SoldierClassAbilityType AbilityToReturn;
	local int RandIndex;

	if(RandomDeck.Abilities.Length == 0)
	{
		return AbilityToReturn;
	}

	RandIndex = `SYNC_RAND(RandomDeck.Abilities.Length);
	AbilityToReturn = RandomDeck.Abilities[RandIndex];
	RandomDeck.Abilities.Remove(RandIndex, 1);
	return AbilityToReturn;
}

function array<SoldierClassAbilityType> GetRankAbilities(int Rank)
{
	local array<SoldierClassAbilityType> EmptyRankAbilities;

	if(AbilityTree.Length == 0)
	{
		EmptyRankAbilities.Length = 0;
		return EmptyRankAbilities;
	}

	if(Rank < 0 || Rank >= AbilityTree.Length)
	{
		`RedScreen("Invalid rank given for GetRankAbilities(). @gameplay @mnauta");
		return  AbilityTree[0].Abilities;
	}

	return AbilityTree[Rank].Abilities;
}

function name GetAbilityName(int iRank, int iBranch)
{
	if (iRank < 0 && iRank >= AbilityTree.Length)
		return '';

	if (iBranch < 0 && iBranch >= AbilityTree[iRank].Abilities.Length)
		return '';

	return AbilityTree[iRank].Abilities[iBranch].AbilityName;
}

function SCATProgression GetSCATProgressionForAbility(name AbilityName)
{
	local SCATProgression Progression;
	local int rankIdx, branchIdx;

	Progression.iBranch = INDEX_NONE;
	Progression.iRank = INDEX_NONE;

	for (rankIdx = 0; rankIdx < AbilityTree.Length; ++rankIdx)
	{
		for (branchIdx = 0; branchIdx < AbilityTree[rankIdx].Abilities.Length; ++branchIdx)
		{
			if (AbilityTree[rankIdx].Abilities[branchIdx].AbilityName == AbilityName)
			{
				Progression.iRank = rankIdx;
				Progression.iBranch = branchIdx;
				return Progression;
			}
		}
	}

	return Progression;
}

// Show the promotion icon (in strategy)
function bool ShowPromoteIcon()
{
	return (IsAlive() && !bCaptured && (CanRankUpSoldier() || HasAvailablePerksToAssign()));
}

function bool ShowBondAvailableIcon(out StateObjectReference BondmateRef, out SoldierBond BondData)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local StateObjectReference UnitRef;
	
	if (HasSoldierBondAvailable(BondmateRef, BondData) && BondData.BondLevel == 0)
	{
		return true;
	}
	else
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		foreach XComHQ.Crew(UnitRef)
		{
			// Look for another unit in the crew that does not have a bond
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (UnitState != none && !UnitState.HasSoldierBond(BondmateRef))
			{
				// Check to see if that unit has a bond level up available with this one
				// Need this check since only one soldier's bond data will have the bSoldierBondLevelUpAvailable flag set to true,
				// to prevent double bond icons from showing up in the Avenger
				if (UnitState.GetBondData(GetReference(), BondData) && BondData.bSoldierBondLevelUpAvailable && BondData.BondLevel == 0)
				{
					BondmateRef = UnitState.GetReference();
					return true;
				}
			}
		}
	}
	
	return false;
}

function String GenerateNickname()
{
	local X2SoldierClassTemplate Template;
	local int iNumChoices, iChoice;

	Template = GetSoldierClassTemplate();
	iNumChoices = Template.RandomNickNames.Length;

	if( kAppearance.iGender == eGender_Female )
	{
		iNumChoices += Template.RandomNickNames_Female.Length;
	}
	else if( kAppearance.iGender == eGender_Male )
	{
		iNumChoices += Template.RandomNickNames_Male.Length;
	}

	iChoice = `SYNC_RAND(iNumChoices);

	if( iChoice < Template.RandomNickNames.Length )
	{
		return Template.RandomNickNames[iChoice];
	}
	else
	{
		iChoice -= Template.RandomNickNames.Length;
	}

	if( kAppearance.iGender == eGender_Female )
	{
		return Template.RandomNickNames_Female[iChoice];
	}
	else if( kAppearance.iGender == eGender_Male )
	{
		return Template.RandomNickNames_Male[iChoice];
	}

	return "";
}

function ResetRankToRookie()
{
	local int idx;

	// soldier becomes a rookie
	m_SoldierRank = 0;
	ClearSoldierClassTemplate();

	// reset soldier stats
	for(idx = 0; idx < eStat_MAX; idx++)
	{
		SetBaseMaxStat(ECharStatType(idx), GetMyTemplate().GetCharacterBaseStat(ECharStatType(idx)));
		SetCurrentStat(ECharStatType(idx), GetMyTemplate().GetCharacterBaseStat(ECharStatType(idx)));
	}

	// Start Issue #95
	ApplyFirstTimeStatModifiers();
	// End Issue #95

	// reset XP to squaddie threshold
	SetXPForRank(m_SoldierRank + 1);
}

function array<int> GetPCSRanks()
{
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<int> ValidRanks;
	local int RankIndex, StatIndex;
	local array<SoldierClassStatType> StatProgression;

	if(GetMyTemplate().GetCharacterBaseStat(eStat_CombatSims) > 0)
	{
		ValidRanks.AddItem(0);
	}

	// Does not matter which class we grab, all should have same combat sim stats
	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate('Ranger');

	for(RankIndex = 0; RankIndex < SoldierClassTemplate.GetMaxConfiguredRank(); RankIndex++)
	{
		StatProgression = SoldierClassTemplate.GetStatProgression(RankIndex);
		for(StatIndex = 0; StatIndex < StatProgression.Length; StatIndex++)
		{
			if(StatProgression[StatIndex].StatType == eStat_CombatSims && StatProgression[StatIndex].StatAmount > 0)
			{
				ValidRanks.AddItem(RankIndex+1);
			}
		}
	}

	return ValidRanks;
}

function bool IsSufficientRankToEquipPCS()
{
	local int i, Rank;
	local array<int> ValidRanks;

	Rank = GetRank();
	ValidRanks = GetPCSRanks();

	for(i = 0; i < ValidRanks.Length; ++i)
	{
		if(Rank >= ValidRanks[i])
			return true;
	}

	return false;
}

simulated function name CheckSpecialGuaranteedHit(XComGameState_Ability AbilityState, XComGameState_Item WeaponState, XComGameState_Unit TargetState)
{
	local X2SoldierClassTemplate SoldierClassTemplate;

	SoldierClassTemplate = GetSoldierClassTemplate();
	if (SoldierClassTemplate != none && SoldierClassTemplate.CheckSpecialGuaranteedHitFn != None)
		return SoldierClassTemplate.CheckSpecialGuaranteedHitFn(self, AbilityState, WeaponState, TargetState);

	return '';
}

simulated function string CheckSpecialCritLabel(XComGameState_Ability AbilityState, XComGameState_Item WeaponState, XComGameState_Unit TargetState)
{
	local X2SoldierClassTemplate SoldierClassTemplate;

	SoldierClassTemplate = GetSoldierClassTemplate();
	if (SoldierClassTemplate != none && SoldierClassTemplate.CheckSpecialCritLabelFn != None)
		return SoldierClassTemplate.CheckSpecialCritLabelFn(self, AbilityState, WeaponState, TargetState);

	return "";
}

simulated function bool GetTargetingMethodPostProcess(XComGameState_Ability AbilityState, XComGameState_Item WeaponState, XComGameState_Unit TargetState, out name EnabledPostProcess, out name DisabledPostProcess)
{
	local X2SoldierClassTemplate SoldierClassTemplate;

	SoldierClassTemplate = GetSoldierClassTemplate();
	if (SoldierClassTemplate != none && SoldierClassTemplate.GetTargetingMethodPostProcessFn != None)
		return SoldierClassTemplate.GetTargetingMethodPostProcessFn(self, AbilityState, WeaponState, TargetState, EnabledPostProcess, DisabledPostProcess);

	return false;
}

native simulated function StateObjectReference FindAbility(name AbilityTemplateName, optional StateObjectReference MatchSourceWeapon, optional array<StateObjectReference> ExcludeSourceWeapons) const;
/*  the below code was moved into native but describes the implementation accurately
{
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local StateObjectReference ObjRef, EmptyRef, IterRef;
	local int ComponentID;
	local XComGameState_Unit kSubUnit;
	local bool bSkip;

	History = `XCOMHISTORY;
	foreach Abilities(ObjRef)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(ObjRef.ObjectID));
		if (AbilityState.GetMyTemplateName() == AbilityTemplateName)
		{
			bSkip = false;
			foreach ExcludeSourceWeapons(IterRef)
			{
				if (IterRef.ObjectID != 0 && IterRef == AbilityState.SourceWeapon)
				{
					bSkip = true;
					break;
				}
			}
			if (bSkip)
				continue;

			if (MatchSourceWeapon.ObjectID == 0 || AbilityState.SourceWeapon == MatchSourceWeapon)
				return ObjRef;
		}
	}

	if (!m_bSubsystem) // limit 1-depth recursion.
	{
		foreach ComponentObjectIds(ComponentID)
		{
			kSubUnit = XComGameState_Unit(History.GetGameStateForObjectID(ComponentID));
			if (kSubUnit != None)
			{
				ObjRef = kSubUnit.FindAbility(AbilityTemplateName, MatchSourceWeapon, ExcludeSourceWeapons);
				if (ObjRef.ObjectID > 0)
					return ObjRef;
			}
		}
	}

	return EmptyRef;
}
*/

function EvacuateUnit(XComGameState NewGameState)
{
	local XComGameState_Unit NewUnitState, CarriedUnitState;
	local XComGameState_Effect CarryEffect, BleedOutEffect;
	local XComGameStateHistory History;
	local bool bFoundCarry;

	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(Class, ObjectID));
	NewUnitState.bRemovedFromPlay = true;
	NewUnitState.bRequiresVisibilityUpdate = true;

	`XEVENTMGR.TriggerEvent( 'UnitRemovedFromPlay', self, self, NewGameState );			
	`XEVENTMGR.TriggerEvent( 'UnitEvacuated', self, self, NewGameState );			

	`XWORLD.ClearTileBlockedByUnitFlag(NewUnitState);

	CarryEffect = NewUnitState.GetUnitAffectedByEffectState(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
	if (CarryEffect != none)
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', CarriedUnitState)
		{
			CarryEffect = CarriedUnitState.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
			if (CarryEffect != none && CarryEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID == ObjectID)
			{
				bFoundCarry = true;
				break;
			}
		}
		if (bFoundCarry)
		{
			CarriedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(CarriedUnitState.Class, CarriedUnitState.ObjectID));				
			if (CarriedUnitState.IsBleedingOut())
			{
				//  cleanse the effect so the unit is rendered unconscious
				BleedOutEffect = CarriedUnitState.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
				BleedOutEffect.RemoveEffect(NewGameState, NewGameState, true);

				// Achievement: Evacuate a soldier whose bleed-out timer is still running
				if (CarriedUnitState.IsAlive() && CarriedUnitState.IsPlayerControlled())
				{
					`ONLINEEVENTMGR.UnlockAchievement(AT_EvacRescue);
				}

			}
			if (NewUnitState.ObjectID != CarriedUnitState.ObjectID && CarriedUnitState.CanEarnSoldierRelationshipPoints(NewUnitState))
			{
				NewUnitState.AddToSquadmateScore(CarriedUnitState.ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_CarrySoldier);
				CarriedUnitState.AddToSquadmateScore(NewUnitState.ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_CarrySoldier);
			}
			CarryEffect.RemoveEffect(NewGameState, NewGameState, true);           //  Stop being carried
			CarriedUnitState.bBodyRecovered = true;
			CarriedUnitState.bRemovedFromPlay = true;
			CarriedUnitState.bRequiresVisibilityUpdate = true;

			`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', CarriedUnitState, CarriedUnitState, NewGameState);
			`XEVENTMGR.TriggerEvent('UnitEvacuated', CarriedUnitState, CarriedUnitState, NewGameState);

			`XWORLD.ClearTileBlockedByUnitFlag(CarriedUnitState);

		}
	}
}
function EventListenerReturn OnUnitRemovedFromPlay(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	RemoveUnitFromPlay();
	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitRemovedFromPlay_GameState(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Removed From Play");

	// This needs to create a new version of the unit since this is an event callback
	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ObjectID));
	NewUnitState.RemoveStateFromPlay();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

// Needed for simcombat @mnauta
function SimEvacuate()
{
	bRemovedFromPlay = true;
	bRequiresVisibilityUpdate = true;
}

// Different than RemoveUnitFromPlay so that we just do the state change.
function RemoveStateFromPlay( )
{
	bRemovedFromPlay = true;
	bRequiresVisibilityUpdate = true;
}

// Needed for simcombat @mnauta
function SimGetKill(StateObjectReference EnemyRef)
{
	local XComGameState_Unit UnitState;

	KilledUnits.AddItem(EnemyRef);
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EnemyRef.ObjectID));
	if (UnitState != none)
	{
		KillCount += UnitState.GetMyTemplate().KillContribution;
	}
}

function ClearKills()
{
	KilledUnits.Length = 0;
	KillCount = 0.0;
}

function CopyKills(XComGameState_Unit CopiedUnitState)
{
	KilledUnits = CopiedUnitState.GetKills();
	KillCount = CopiedUnitState.KillCount;
}

function CopyKillAssists(XComGameState_Unit CopiedUnitState)
{
	KillAssists = CopiedUnitState.GetKillAssists();
	KillAssistsCount = CopiedUnitState.KillAssistsCount;
}

function array<StateObjectReference> GetKills()
{
	return KilledUnits;
}

function array <StateObjectReference> GetKillAssists()
{
	return KillAssists;
}

// Is unit provided a critical function in the strategy layer
function bool IsUnitCritical()
{
	local XComGameState_StaffSlot StaffSlotState;
	
	if (StaffingSlot.ObjectID != 0)
	{
		StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffingSlot.ObjectID));
		return (!StaffSlotState.CanStaffBeMoved());
	}

	return false;
}

function RemoveUnitFromPlay()
{
	local XGUnit UnitVisualizer;

	bRemovedFromPlay = true;
	bRequiresVisibilityUpdate = true;

	UnitVisualizer = XGUnit(GetVisualizer());
	if( UnitVisualizer != none )
	{
		UnitVisualizer.SetForceVisibility(eForceNotVisible);
		UnitVisualizer.DestroyBehavior();
	}
}

function ClearRemovedFromPlayFlag()
{
	local XGUnit UnitVisualizer;

	if (!GetMyTemplate().bDontClearRemovedFromPlay)
	{
		bRemovedFromPlay = false;
	}
	
	bRequiresVisibilityUpdate = true;

	UnitVisualizer = XGUnit(GetVisualizer());
	if( UnitVisualizer != none )
	{
		UnitVisualizer.SetForceVisibility(eForceNone);
	}
}

function int GetWeakenedWillModifications()
{
	local int TotalMod;

	TotalMod = 0;
	if( AffectedByEffectNames.Find(class'X2AbilityTemplateManager'.default.DisorientedName) != INDEX_NONE )
	{
		TotalMod += class'X2StatusEffects'.default.DISORIENTED_WILL_ADJUST;
	}

	if( IsPanicked() )
	{
		TotalMod += class'X2StatusEffects'.default.PANIC_WILL_ADJUST;
	}

	if( AffectedByEffectNames.Find(class'X2AbilityTemplateManager'.default.ConfusedName) != INDEX_NONE )
	{
		TotalMod += class'X2StatusEffects'.default.CONFUSED_WILL_ADJUST;
	}

	if( StunnedActionPoints > 0 )
	{
		TotalMod += class'X2StatusEffects'.default.STUNNED_WILL_ADJUST;
	}

	return TotalMod;
}

///////////////////////////////////////
// UI Summaries interface

simulated function EUISummary_UnitStats GetUISummary_UnitStats()
{
	local int i;
	local XComGameState_XpManager XpMan;
	local EUISummary_UnitStats Summary; 
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;

	Summary.CurrentHP = GetCurrentStat(eStat_HP);
	Summary.MaxHP = GetMaxStat(eStat_HP);
	Summary.Aim = GetCurrentStat(eStat_Offense);
	Summary.Tech = GetCurrentStat(eStat_Hacking);
	Summary.Defense = GetCurrentStat(eStat_Defense);
	Summary.CurrentWill = GetCurrentStat(eStat_Will);
	Summary.MaxWill = GetMaxStat(eStat_Will);
	Summary.Dodge = GetCurrentStat(eStat_Dodge);
	Summary.Armor = GetCurrentStat(eStat_ArmorMitigation);
	Summary.PsiOffense = GetCurrentStat(eStat_PsiOffense);
	Summary.Mobility = GetCurrentStat(eStat_Mobility);
	Summary.UnitName = GetName(eNameType_Full);

	History = `XCOMHISTORY;
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			EffectTemplate = EffectState.GetX2Effect();
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Offense, Summary.Aim);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Hacking, Summary.Tech);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Defense, Summary.Defense);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Will, Summary.MaxWill);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Dodge, Summary.Dodge);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_PsiOffense, Summary.PsiOffense);
		}
	}

	/* Debug Values */
	if (`CHEATMGR != none && `CHEATMGR.bDebugXp)
	{
		Summary.Xp = m_iXp;
		foreach History.IterateByClassType(class'XComGameState_XpManager', XpMan)
		{
			break;
		}
		for (i = 0; i < XpMan.UnitXpShares.Length; ++i)
		{
			if (XpMan.UnitXpShares[i].UnitRef.ObjectID == ObjectID)
			{
				Summary.XpShares = XpMan.UnitXpShares[i].Shares;
				break;
			}
		}
		Summary.SquadXpShares = XpMan.SquadXpShares;
		Summary.EarnedPool = XpMan.EarnedPool;
	}	
	/* End Debug Values */

	return Summary; 
}

simulated function array<UISummary_UnitEffect> GetUISummary_UnitEffectsByCategory(EPerkBuffCategory Category)
{
	local UISummary_UnitEffect Item, EmptyItem;  
	local array<UISummary_UnitEffect> List; 
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Persist;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;

	History = `XCOMHISTORY;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Persist = EffectState.GetX2Effect();
			if (Persist != none && Persist.bDisplayInUI && Persist.BuffCategory == Category && Persist.IsEffectCurrentlyRelevant(EffectState, self))
			{
				Item = EmptyItem;
				FillSummaryUnitEffect(EffectState, Persist, false, Item);
				List.AddItem(Item);
			}
		}
	}
	foreach AppliedEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Persist = EffectState.GetX2Effect();
			if (Persist != none && Persist.bSourceDisplayInUI && Persist.SourceBuffCategory == Category && Persist.IsEffectCurrentlyRelevant(EffectState, self))
			{
				Item = EmptyItem;
				FillSummaryUnitEffect(EffectState, Persist, true, Item);
				List.AddItem(Item);
			}
		}
	}
	if (Category == ePerkBuff_Penalty)
	{
		if (GetRupturedValue() > 0)
		{
			Item = EmptyItem;
			Item.AbilitySourceName = 'eAbilitySource_Standard';
			Item.Icon = class 'X2StatusEffects'.default.RuptureIcon;
			Item.Name = class'X2StatusEffects'.default.RupturedFriendlyName;
			Item.Description = class'X2StatusEffects'.default.RupturedFriendlyDesc;
			List.AddItem(Item);
		}
	}

	return List; 
}

private simulated function FillSummaryUnitEffect(const XComGameState_Effect EffectState, const X2Effect_Persistent Persist, const bool bSource, out UISummary_UnitEffect Summary)
{
	local X2AbilityTag AbilityTag;

	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = EffectState;

	if (bSource)
	{
		Summary.Name = Persist.SourceFriendlyName;
		Summary.Description = `XEXPAND.ExpandString(Persist.SourceFriendlyDescription);
		Summary.Icon = Persist.SourceIconLabel;
		Summary.Cooldown = 0; //TODO @jbouscher @bsteiner
		Summary.Charges = 0; //TODO @jbouscher @bsteiner
		Summary.AbilitySourceName = Persist.AbilitySourceName;
	}
	else
	{
		Summary.Name = Persist.FriendlyName;
		Summary.Description = `XEXPAND.ExpandString(Persist.FriendlyDescription);
		Summary.Icon = Persist.IconImage;
		Summary.Cooldown = 0; //TODO @jbouscher @bsteiner
		Summary.Charges = 0; //TODO @jbouscher @bsteiner
		Summary.AbilitySourceName = Persist.AbilitySourceName;
	}

	AbilityTag.ParseObj = None;
}
simulated function array<string> GetUISummary_UnitStatusIcons()
{
	local array<string> List;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Persist;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		Persist = EffectState.GetX2Effect();
		if( Persist.bDisplayInUI && Persist.IsEffectCurrentlyRelevant(EffectState, self) )
		{
			List.AddItem(Persist.StatusIcon);
		}
	}

	if( StunnedActionPoints > 0 )
	{
		List.AddItem(class'UIUtilities_Image'.const.UnitStatus_Stunned);
	}

	return List;
}

simulated function array<UISummary_Ability> GetUISummary_Abilities()
{
	local array<UISummary_Ability> UIAbilities; 
	local XComGameState_Ability AbilityState;   //Holds INSTANCE data for the ability referenced by AvailableActionInfo. Ie. cooldown for the ability on a specific unit
	local X2AbilityTemplate AbilityTemplate; 
	local int i, len; 

	len = Abilities.Length;
	for(i = 0; i < len; i++)
	{	
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Abilities[i].ObjectID));
		if( AbilityState == none) 
			continue; 

		AbilityTemplate = AbilityState.GetMyTemplate(); 
		if( !AbilityTemplate.bDisplayInUITooltip )
			continue; 

		//Add to our list of abilities 
		UIAbilities.AddItem( AbilityState.GetUISummary_Ability(self) );
	}

	return UIAbilities; 
}

simulated function int GetUISummary_StandardShotHitChance(XGUnit Target)
{
	local XComGameStateHistory History;
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local X2TacticalGameRuleset TacticalRules;
	local GameRulesCache_Unit OutCachedAbilitiesInfo;
	local AvailableAction StandardShot;
	local ShotBreakdown kBreakdown;
	local StateObjectReference TargetRef; 
	local int Index;
	local int TargetIndex;

	local int iHitChance;

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	//Show the standard shot % to hit if it is available
	TacticalRules.GetGameRulesCache_Unit(self.GetReference(), OutCachedAbilitiesInfo);
	for( Index = 0; Index < OutCachedAbilitiesInfo.AvailableActions.Length; ++Index )
	{		
		StandardShot = OutCachedAbilitiesInfo.AvailableActions[Index];
		SelectedAbilityState = XComGameState_Ability( History.GetGameStateForObjectID(StandardShot.AbilityObjectRef.ObjectID) );
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();	

		if( SelectedAbilityTemplate.DisplayTargetHitChance && StandardShot.AvailableCode == 'AA_Success' )
		{
			//Find our target
			for( TargetIndex = 0; TargetIndex < StandardShot.AvailableTargets.Length; ++TargetIndex )
			{
				TargetRef = StandardShot.AvailableTargets[TargetIndex].PrimaryTarget;
				if( Target.ObjectID == TargetRef.ObjectID )
				{
					iHitChance = SelectedAbilityState.LookupShotBreakdown(GetReference(), TargetRef, StandardShot.AbilityObjectRef, kBreakdown);
					break;
				}								
			}
		}
	}

	return iHitChance;
}

simulated function GetUISummary_TargetableUnits(out array<StateObjectReference> arrVisibleUnits, out array<StateObjectReference> arrSSEnemies, out array<StateObjectReference> arrCurrentlyAffectable, XComGameState_Ability CurrentAbility, int HistoryIndex)
{
	local XComGameState_BaseObject Target;
	local XComGameState_Unit EnemyUnit;
	local XComGameState_Destructible DestructibleObject;
	local array<StateObjectReference> arrHackableObjects;
	local AvailableAction ActionInfo;
	local StateObjectReference TargetRef;
	local int i, j;
	local GameRulesCache_Unit UnitCache;

	arrCurrentlyAffectable.Length = 0;
	//  retrieve cached action info
	`TACTICALRULES.GetGameRulesCache_Unit(GetReference(), UnitCache);  // note, the unit cache is acting on current (latest history index) information, so this may not be technically correct

	foreach UnitCache.AvailableActions(ActionInfo)
	{
		// only show heads for abilities which have icons in the hud. Otherwise non-targeted abilities and passives will cause targets
		// to show as available
		if( (CurrentAbility == None && class'UITacticalHUD_AbilityContainer'.static.ShouldShowAbilityIcon(ActionInfo)) 
			|| (CurrentAbility != none && ActionInfo.AbilityObjectRef.ObjectID == CurrentAbility.ObjectID) )
		{
			for( j = 0; j < ActionInfo.AvailableTargets.Length; ++j )
			{
				TargetRef = ActionInfo.AvailableTargets[j].PrimaryTarget;
				if( TargetRef.ObjectID > 0 && arrCurrentlyAffectable.Find('ObjectID', TargetRef.ObjectID) == INDEX_NONE )
				{
					Target = `XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID, , HistoryIndex);
					EnemyUnit = XComGameState_Unit(Target);
					if (EnemyUnit == none || !EnemyUnit.GetMyTemplate().bIsCosmetic)
					{
						arrCurrentlyAffectable.AddItem(TargetRef);
					}
				}
			}
		}
	}

	arrVisibleUnits.Length = 0;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyTargetsForUnit(ObjectID, arrVisibleUnits, , HistoryIndex);

	//  Check for squadsight
	if( HasSquadsight() )
	{
		class'X2TacticalVisibilityHelpers'.static.GetAllSquadsightEnemiesForUnit(ObjectID, arrSSEnemies, HistoryIndex, true);
	}
	for( i = 0; i < arrSSEnemies.length; i++ )
	{
		arrVisibleUnits.AddItem(arrSSEnemies[i]);
	}

	//Remove cosmetic and deceased units from the enemy array
	if( arrVisibleUnits.Length > 0 )
	{
		for( i = arrVisibleUnits.Length - 1; i >= 0; i-- )
		{
			Target = `XCOMHISTORY.GetGameStateForObjectID(arrVisibleUnits[i].ObjectID, , HistoryIndex);
			EnemyUnit = XComGameState_Unit(Target);
			if( EnemyUnit != none && ( !EnemyUnit.IsAlive() || EnemyUnit.GetMyTemplate().bIsCosmetic ) )
			{
				arrVisibleUnits.Remove(i, 1);
			}
			else
			{
				DestructibleObject = XComGameState_Destructible(Target);
				if( DestructibleObject != none && !DestructibleObject.IsTargetable(GetTeam()) )
				{
					arrVisibleUnits.Remove(i, 1);
				}
			}
		}
	}

	//Add all hackable objects to the array 
	class'X2TacticalVisibilityHelpers'.static.GetHackableObjectsInRangeOfUnit(ObjectID, arrHackableObjects, , HistoryIndex, FindAbility('IntrusionProtocol').ObjectID > 0);
	for( i = 0; i < arrHackableObjects.length; i++ )
	{
		arrVisibleUnits.AddItem(arrHackableObjects[i]);
	}
}

simulated function int GetUIStatFromInventory(ECharStatType Stat, optional XComGameState CheckGameState)
{
	local int Result;
	local XComGameState_Item InventoryItem;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<XComGameState_Item> CurrentInventory;

	//  Gather abilities from the unit's inventory
	CurrentInventory = GetAllInventoryItems(CheckGameState);
	foreach CurrentInventory(InventoryItem)
	{
		EquipmentTemplate = X2EquipmentTemplate(InventoryItem.GetMyTemplate());
		if (EquipmentTemplate != none)
		{
			// Don't include sword boosts or any other equipment in the EquipmentExcludedFromStatBoosts array
			if(class'UISoldierHeader'.default.EquipmentExcludedFromStatBoosts.Find(EquipmentTemplate.DataName) == INDEX_NONE)
				Result += EquipmentTemplate.GetUIStatMarkup(Stat, InventoryItem);
		}
	}

	return Result;
}

simulated function int GetUIStatFromAbilities(ECharStatType Stat)
{
	local int Result, i;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> SoldierAbilities;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;
	local array<X2SoldierUnlockTemplate> UnlockTemplates;
	local X2SoldierAbilityUnlockTemplate AbilityUnlockTemplate;
	local XComGameState_HeadquartersXCom HQ;
	
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	SoldierAbilities = GetEarnedSoldierAbilities();
	for (i = 0; i < SoldierAbilities.Length; ++i)
	{
		AbilityName = SoldierAbilities[i].AbilityName;
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

		if (AbilityTemplate != none)
		{
			Result += AbilityTemplate.GetUIStatMarkup(Stat);
		}
	}
	HQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (HQ != none)
	{
		UnlockTemplates = HQ.GetActivatedSoldierUnlockTemplates();
		for (i = 0; i < UnlockTemplates.Length; ++i)
		{
			AbilityUnlockTemplate = X2SoldierAbilityUnlockTemplate(UnlockTemplates[i]);
			if (AbilityUnlockTemplate != none && AbilityUnlockTemplate.UnlockAppliesToUnit(self))
			{
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityUnlockTemplate.AbilityName);
				if (AbilityTemplate != none)
				{
					Result += AbilityTemplate.GetUIStatMarkup(Stat);
				}
			}
		}
	}

	return Result;
}

///////////////////////////////////////
function int GetRelationshipChanges(XComGameState_Unit OldState)
{
	local int i, j;

	if (SoldierRelationships.Length != OldState.SoldierRelationships.Length && (OldState.SoldierRelationships.Length != 0))
	{
		for (i = 0; i < SoldierRelationships.Length; ++i)
		{
			for (j = 0; j < OldState.SoldierRelationships.Length; ++j)
			{
				if (SoldierRelationships[i].SquadmateObjectRef == OldState.SoldierRelationships[j].SquadmateObjectRef)
				{
					break;
				}
				else if (j == (OldState.SoldierRelationships.Length - 1))
				{
					return SoldierRelationships[i].Score;
				}
			}
		}
	}
	else if ( (SoldierRelationships.Length == OldState.SoldierRelationships.Length) && (SoldierRelationships.Length > 0) )
	{
		for (i = 0; i < SoldierRelationships.Length; ++i)
		{
			for (j = 0; j < SoldierRelationships.Length; ++j)
			{
				if (SoldierRelationships[i].SquadmateObjectRef == OldState.SoldierRelationships[j].SquadmateObjectRef &&
					SoldierRelationships[i].Score != OldState.SoldierRelationships[j].Score)
				{
					return (SoldierRelationships[i].Score - OldState.SoldierRelationships[j].Score);
				}
			}
		}
	}
	else if (OldState.SoldierRelationships.Length == 0 && SoldierRelationships.Length > 0)
	{
		return SoldierRelationships[0].Score;
	}

	return -1;
}

function string GetSoldierRelationshipFlyOverString(int iDiff)
{
	local string strXP, strPoints;

	if (iDiff != -1)
	{
		strXP = class'XLocalizedData'.default.RelationshipChanged;
		if (iDiff > 0)
		{
			strPoints = "+" $ iDiff;
			`BATTLE.ReplaceText(strXP, "<Amount>", strPoints);
		}
		else
		{
			strPoints = "" $ iDiff;
			`BATTLE.ReplaceText(strXP, "<Amount>", strPoints);
		}
		return strXP;
	}
}

static function SetUpBuildTrackForSoldierRelationship(out VisualizationActionMetadata ActionMetadata, XComGameState VisualizeGameState, int UnitID)
{
	local XComGameStateHistory History;
	local X2Action_PlaySoundAndFlyOver      SoundAndFlyOver;
	local XComGameState_Unit                NewStateUnit, OldStateUnit;
	local int                               iDiff;
	local string                            RelationshipString;
	local XComGameState_BaseObject          NewStateBaseObject, OldStateBaseObject;

	History = `XCOMHISTORY;

	NewStateUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	OldStateUnit = XComGameState_Unit(ActionMetadata.StateObject_OldState);

	History.GetCurrentAndPreviousGameStatesForObjectID(UnitID, OldStateBaseObject, NewStateBaseObject, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	NewStateUnit = XComGameState_Unit(NewStateBaseObject);
	OldStateUnit = XComGameState_Unit(OldStateBaseObject);
	if (NewStateUnit.IsSoldier() && !NewStateUnit.IsAlien())
	{
		iDiff = NewStateUnit.GetRelationshipChanges(OldStateUnit);
		if (iDiff != -1 && `CHEATMGR.bDebugSoldierRelationships)
		{
			RelationshipString = NewStateUnit.GetSoldierRelationshipFlyOverString(iDiff);
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, RelationshipString, '', eColor_Purple);
		}
	}
}

function bool CanEarnSoldierRelationshipPoints(XComGameState_Unit OtherUnit)
{
	if (IsDead() || OtherUnit.IsDead() || bRemovedFromPlay)
	{
		return false;
	}
	else if (!CanEarnXP() || !OtherUnit.CanEarnXp())
	{
		return false;
	}
	else
	{
		return true;
	}
}

// returns true if this unit has a bond available to level up with another unit, and gets a reference to that unit if so
function native bool HasSoldierBondAvailable(out StateObjectReference BondmateRef, optional out SoldierBond OutBondData) const;

// returns true if this unit is bonded to another unit, and gets a reference to that unit if so
function native bool HasSoldierBond(out StateObjectReference BondmateRef, optional out SoldierBond OutBondData) const;

// returns true if this unit has ever had a soldier bond
function native bool HasEverHadSoldierBond();

// gets the bond data for two soldiers, if it exists
function native bool GetBondData(StateObjectReference UnitRef, out SoldierBond Bond) const;

function EMentalState GetMentalState(optional bool bIgnoreBoost = false)
{
	if(bRecoveryBoosted && !bIgnoreBoost)
	{
		return eMentalState_Ready;
	}

	return MentalState;
}

function UpdateMentalState()
{
	local int WillPercent, idx;

	WillPercent = int((GetCurrentStat(eStat_Will) / GetMaxStat(eStat_Will)) * 100.0f);

	for(idx = 0; idx < eMentalState_Max; idx++)
	{
		if(WillPercent <= class'X2StrategyGameRulesetDataStructures'.default.MentalStatePercents[idx])
		{
			MentalState = EMentalState(idx);
			return;
		}
	}
}

function int GetMaxWillForMentalState(EMentalState eState)
{
	local float MaxWill, MultiplyFactor;

	MaxWill = GetMaxStat(eStat_Will);
	MultiplyFactor = float(class'X2StrategyGameRulesetDataStructures'.default.MentalStatePercents[eState]) / 100.0f;

	return int(MultiplyFactor * MaxWill);
}

function int GetMinWillForMentalState(EMentalState eState)
{
	if(eState == eMentalState_Shaken)
	{
		return 0;
	}
	else if(eState == eMentalState_Tired)
	{
		return (GetMaxWillForMentalState(eMentalState_Shaken) + 1);
	}
	else
	{
		return (GetMaxWillForMentalState(eMentalState_Tired) + 1);
	}
}

function string GetMentalStateLabel()
{
	return class'UIUtilities_Text'.static.GetColoredText(class'X2StrategyGameRulesetDataStructures'.default.MentalStateLabels[GetMentalState()], GetMentalStateUIState());
}

function GetMentalStateStringsSeparate(out string Status, out string TimeLabel, out int TimeValue)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectRecoverWill WillProject;
	local int iDays;

	History = `XCOMHISTORY;
	Status = GetMentalStateLabel();
	TimeLabel = "";
	TimeValue = 0;

	if(BelowReadyWillState())
	{
		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectRecoverWill', WillProject)
		{
			if(WillProject.ProjectFocus.ObjectID == self.ObjectID)
			{
				iDays = WillProject.GetCurrentNumDaysRemaining();
				TimeValue = iDays;
				if (TimeValue == 0)
				{
					// Even if there isn't any time left, add a day to the string so it displays some time remaining in the UI
					TimeValue = 1;
				}
				TimeLabel = class'UIUtilities_Text'.static.GetDaysString(iDays);
				break;
			}
		}
	}
}

function eUIState GetMentalStateUIState()
{
	local EMentalState CurrentMentalState;

	CurrentMentalState = GetMentalState();
	switch(CurrentMentalState)
	{
	case eMentalState_Ready:
		return eUIState_Good;
		break;
	case eMentalState_Tired:
		return eUIState_Warning;
		break;
	case eMentalState_Shaken:
		return eUIState_Bad;
		break;
	default:
		return eUIState_Normal;
		break;
	}

	return eUIState_Normal;
}

function bool CanBeBoosted()
{
	return (!bRecoveryBoosted && !bHasEverBeenBoosted && ((IsInjured() && !IgnoresInjuries()) || NeedsWillRecovery()));
}

function BoostSoldier()
{
	// Strategy Cost payment done elsewhere, record health and will
	bRecoveryBoosted = true;
	bHasEverBeenBoosted = true;
	PreBoostHealth = int(GetCurrentStat(eStat_HP));
	PreBoostWill = int(GetCurrentStat(eStat_Will));
}

function UnBoostSoldier(optional bool bAllowReboost)
{
	// Refund of strategy payment done elsewhere
	bRecoveryBoosted = false;
	bHasEverBeenBoosted = !bAllowReboost;
	PreBoostHealth = 0;
	PreBoostWill = 0;
}

///////////////////////////////////////
// Damageable interface

//  NOTE - Armor parameter no longer used - now returns all armor on the unit, less Shred
simulated event float GetArmorMitigation(const out ArmorMitigationResults Armor)
{
	local float Total;
	local ArmorMitigationResults ArmorResults;

	class'X2AbilityArmorHitRolls'.static.RollArmorMitigation(Armor, ArmorResults, self);
	Total = ArmorResults.TotalMitigation;
	Total -= Shredded;
	Total = max(0, Total);

	return Total;
}

simulated function float GetArmorMitigationForUnitFlag()
{
	local float Total;
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local X2Effect_BonusArmor ArmorEffect;

	Total = 0;
	
	Total += GetCurrentStat(eStat_ArmorMitigation);

	if (AffectedByEffects.Length > 0)
	{
		History = `XCOMHISTORY;
		foreach AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			ArmorEffect = X2Effect_BonusArmor(EffectState.GetX2Effect());
			if (ArmorEffect != none)
			{
				Total += ArmorEffect.GetArmorMitigation(EffectState, self);
			}
		}
	}

	Total -= Shredded;
	Total = max(0, Total);

	return Total;
}

// Accessor Method for SoldierRelationships
function array<SquadmateScore> GetSoldierRelationships()
{
	return SoldierRelationships;
}

function string SafeGetCharacterNickName()
{
	return strNickName;
}

function string SafeGetCharacterLastName()
{
	return strLastName;
}

function string SafeGetCharacterFirstName()
{
	return strFirstName;
}

function bool FindAvailableNeighborTile(out TTile OutTileLocation)
{
	return class'Helpers'.static.FindAvailableNeighborTile(TileLocation, OutTileLocation);
}

delegate bool ValidateTileDelegate(const out TTile TileOption, const out TTile SourceTile, const out Object PassedObject)
{
	return true;
}

function bool FindAvailableNeighborTileWeighted(Vector PreferredDirection, out TTile OutTileLocation, optional delegate<ValidateTileDelegate> IsValidTileFn=ValidateTileDelegate, optional Object PassToDelegate)
{
	local TTile NeighborTileLocation;
	local XComWorldData World;
	local array<Actor> TileActors;

	local Vector ToNeighbor;
	local TTile BestTile;
	local float DotToPreferred;
	local float BestDot;
	local bool FoundTile;
	local int CardinalScore;
	local int BestCardinalScore;

	World = `XWORLD;

	BestDot = -1.0f; // Exact opposite of preferred direction
	FoundTile = false;
	BestCardinalScore = -1;
	NeighborTileLocation = TileLocation;
	for (NeighborTileLocation.X = TileLocation.X - 1; NeighborTileLocation.X <= TileLocation.X + 1; ++NeighborTileLocation.X)
	{
		for (NeighborTileLocation.Y = TileLocation.Y - 1; NeighborTileLocation.Y <= TileLocation.Y + 1; ++NeighborTileLocation.Y)
		{
			CardinalScore = (abs(NeighborTileLocation.X - TileLocation.X) > 0 && abs(NeighborTileLocation.Y - TileLocation.Y) > 0) ? 0 : 1;

			TileActors = World.GetActorsOnTile(NeighborTileLocation);

			// If the tile is empty and is on the same z as this unit's location
			if ((TileActors.Length == 0) && (World.GetFloorTileZ(NeighborTileLocation, false) == TileLocation.Z))
			{
				if( !IsValidTileFn(NeighborTileLocation, TileLocation, PassToDelegate) )
				{
					continue;
				}

				ToNeighbor = Normal(World.GetPositionFromTileCoordinates(NeighborTileLocation) - World.GetPositionFromTileCoordinates(TileLocation));
				DotToPreferred = NoZDot(PreferredDirection, ToNeighbor);
				// Jwats: Cardinal directions have priority over diagonals
				if ((DotToPreferred >= BestDot && CardinalScore >= BestCardinalScore) || (CardinalScore > BestCardinalScore))
				{
					BestCardinalScore = CardinalScore;
					BestDot = DotToPreferred;
					BestTile = NeighborTileLocation;
					FoundTile = true;
				}
			}
		}
	}

	if (FoundTile)
	{
		OutTileLocation = BestTile;
	}

	return FoundTile;
}

native function XComGameState_AIGroup GetGroupMembership(optional XComGameState NewGameState, optional int HistoryIndex = -1);

function bool IsGroupLeader(optional XComGameState NewGameState=None)
{
	local XComGameState_AIGroup Group;
	Group = GetGroupMembership(NewGameState);
	if( Group == None || (Group.m_arrMembers.Length > 0 && Group.m_arrMembers[0].ObjectID == ObjectID) )
	{
		return true;
	}
	return false;
}

// Adds an extra layer of gameplay finesse to unit tile blocking. By default, all units
// block all other units from occupying the same tile they are on. This allows that to
// be overridden, so that a unit can selectively allow other units to occupy the
// tile they are on.
event bool DoesBlockUnitPathing(const XComGameState_Unit TestUnit)
{
	local XComGameState_Effect EffectState, HighestRankEffect;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local EGameplayBlocking CurrentBlocking, TempBlocking;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// until told otherwise, all units block all other units if they are in the same time
	CurrentBlocking = eGameplayBlocking_Blocks;

	//Check effects that modify blocking
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

		if( EffectState != none )
		{
			EffectTemplate = EffectState.GetX2Effect();

			if( EffectTemplate != none )
			{
				TempBlocking = EffectTemplate.ModifyGameplayPathBlockingForTarget(self, TestUnit);

				// This Unit blocks/does not block the TestUnit depending on the highest ranked
				// effect that modifies blocking
				if( (TempBlocking != eGameplayBlocking_DoesNotModify) && (CurrentBlocking != TempBlocking) &&
					((HighestRankEffect == none) || (EffectTemplate.IsThisEffectBetterThanExistingEffect(HighestRankEffect))) )
				{
					CurrentBlocking = TempBlocking;
					HighestRankEffect = EffectState;
				}
			}
		}
	}

	if( CurrentBlocking == eGameplayBlocking_Blocks )
	{
		return true;
	}

	// This Unit does not block the TestUnit
	return false;
}

// Adds an extra layer of gameplay finesse to unit tile blocking. By default, all units
// block all other units from occupying the same tile they are on. This allows that to
// be overridden, so that a unit can selectively allow other units to block pathing to the
// tile that they are on
event bool DoesBlockUnitDestination(const XComGameState_Unit TestUnit)
{
	local XComGameState_Effect EffectState, HighestRankEffect;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local EGameplayBlocking CurrentBlocking, TempBlocking;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// until told otherwise, all units block all other units if they are in the same time
	CurrentBlocking = eGameplayBlocking_Blocks;

	//Check effects that modify blocking
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

		if( EffectState != none )
		{
			EffectTemplate = EffectState.GetX2Effect();

			if( EffectTemplate != none )
			{
				TempBlocking = EffectTemplate.ModifyGameplayDestinationBlockingForTarget(self, TestUnit);

				// This Unit blocks/does not block the TestUnit depending on the highest ranked
				// effect that modifies blocking
				if( (TempBlocking != eGameplayBlocking_DoesNotModify) && (CurrentBlocking != TempBlocking) &&
					((HighestRankEffect == none) || (EffectTemplate.IsThisEffectBetterThanExistingEffect(HighestRankEffect))) )
				{
					CurrentBlocking = TempBlocking;
					HighestRankEffect = EffectState;
				}
			}
		}
	}

	if( CurrentBlocking == eGameplayBlocking_Blocks )
	{
		return true;
	}

	// This Unit does not block the TestUnit
	return false;
}

native function bool IsUnrevealedAI( int HistoryIndex=INDEX_NONE ) const;

function int GetSuppressors(optional out array<StateObjectReference> Suppressors)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent Effect;
	History = `XCOMHISTORY;
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if( EffectState != None )
		{
			Effect = EffectState.GetX2Effect();  
			if( Effect.IsA('X2Effect_Suppression') )
			{
				Suppressors.AddItem(EffectState.ApplyEffectParameters.SourceStateObjectRef);
			}
		}
	}
	return Suppressors.Length;
}

// From X2AIBTDefaultActions - moving here so serialization of the delegate works
simulated function SoldierRescuesCivilian_BuildVisualization(XComGameState VisualizeGameState)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameStateContext Context;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameState_Unit UnitState;

	if (VisualizeGameState.GetNumGameStateObjects() > 0)
	{
		foreach VisualizeGameState.IterateByClassType( class'XComGameState_Unit', UnitState )
		{
			break;
		}
		ActionMetadata.StateObject_OldState = UnitState;
		ActionMetadata.StateObject_NewState = UnitState;

		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		Context = VisualizeGameState.GetContext();
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'CivilianRescue', eColor_Good);
	}
}

function bool CanAbilityHitUnit(name AbilityName)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent Effect;
	local bool bCanHit;

	History = `XCOMHISTORY;
	bCanHit = true;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if( EffectState != None )
		{
			Effect = EffectState.GetX2Effect();
			if(Effect != none)
			{
				bCanHit = bCanHit && Effect.CanAbilityHitUnit(AbilityName);

				if(!bCanHit)
				{
					break;
				}
			}
		}
	}

	return bCanHit;
}

// Checks to see if all Codex that originated from an original Codex are dead
event bool AreAllCodexInLineageDead(XComGameState NewGameState/*, XComGameState_Unit UnitState*/)
{
	local XComGameState_Unit TestUnitInNewGameState, TestUnit;
	local XComGameStateHistory History;
	local UnitValue OriginalCodexObjectIDValue;
	local float UnitStateOriginalCodexObjectID, TestUnitOriginalCodexObjectID;
	
	History = `XCOMHISTORY;

	UnitStateOriginalCodexObjectID = ObjectID;
	if(GetUnitValue(class'X2Ability_Cyberus'.default.OriginalCyberusValueName, OriginalCodexObjectIDValue))
	{
		// If the UnitState has a value for OriginalCyberusValueName, use that since it is the original Codex of its group
		UnitStateOriginalCodexObjectID = OriginalCodexObjectIDValue.fValue;
	}

	foreach History.IterateByClassType(class'XComGameState_Unit', TestUnit)
	{
		if( (TestUnit.ObjectID != ObjectID) &&
			(TestUnit.GetMyTemplateName() == GetMyTemplateName()) )
		{
			// The TestUnit is not the same as UnitState but is the same template
			TestUnitInNewGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(TestUnit.ObjectID));
			if( TestUnitInNewGameState != none )
			{
				// Check units in the unsubmitted GameState if possible
				TestUnit = TestUnitInNewGameState;
			}

			if( !TestUnit.bRemovedFromPlay &&
				TestUnit.IsAlive() )
			{
				// If the TestUnit is in play and alive
				TestUnitOriginalCodexObjectID = TestUnit.ObjectID;
				if(TestUnit.GetUnitValue(class'X2Ability_Cyberus'.default.OriginalCyberusValueName, OriginalCodexObjectIDValue))
				{
					// If the UnitState has a value for OriginalCyberusValueName, use that since it is the original Codex of its group
					TestUnitOriginalCodexObjectID = OriginalCodexObjectIDValue.fValue;
				}

				if( TestUnitOriginalCodexObjectID == UnitStateOriginalCodexObjectID )
				{
					// If the living TestUnit has the same original codex value, UnitState is not the last
					// of its kind.
					return false;
				}
			}
		}
	}

	return true;
}

function TTile GetDesiredTileForAttachedCosmeticUnit()
{
	local TTile TargetTile;

	TargetTile = TileLocation;
	TargetTile.Z += GetDesiredZTileOffsetForAttachedCosmeticUnit();

	return TargetTile;
}

// if this unit is an attached unit (cosmetic flying gremlin and such), we need to 
// put them high enough off the ground that they don't collide with the owning unit. To that end,
// this function determines if any extra bump is needed. Basically, any unit taller than two units
// will lack clearence for the gremlin, and need to have it bumped up
function int GetDesiredZTileOffsetForAttachedCosmeticUnit()
{
	return max(UnitHeight - 2, 0);
}

////////////////////////////////////////////////////////////////////////////////////////
// Hackable interface

function array<int> GetHackRewardRollMods()
{
	return HackRollMods;
}

function SetHackRewardRollMods(const out array<int> RollMods)
{
	HackRollMods = RollMods;
}

function bool HasBeenHacked()
{
	return bHasBeenHacked;
}

function int GetUserSelectedHackOption()
{
	return UserSelectedHackReward;
}

function array<Name> GetHackRewards(Name HackAbilityName)
{
	local Name HackTemplateName;
	local X2CharacterTemplate MyTemplate;
	local X2HackRewardTemplate HackTemplate;
	local X2HackRewardTemplateManager HackTemplateManager;
	local array<Name> ApprovedHackRewards;

	MyTemplate = GetMyTemplate();
	HackTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

	foreach MyTemplate.HackRewards(HackTemplateName)
	{
		HackTemplate = HackTemplateManager.FindHackRewardTemplate(HackTemplateName);

		if( HackTemplate != None && HackTemplate.HackAbilityTemplateRestriction == HackAbilityName && HackTemplate.IsHackRewardCurrentlyPossible() )
		{
			ApprovedHackRewards.AddItem(HackTemplateName);

			if( ApprovedHackRewards.Length == 3 )
			{
				break;
			}
		}
	}

	if (ApprovedHackRewards.Length != 3 && ApprovedHackRewards.Length != 0 )
	{
		`RedScreen("[@design, #dkaplan] Not exactly 3 hack rewards selected for :" @ HackAbilityName);
	}
	return ApprovedHackRewards;
}

function bool HasOverrideDeathAnimOnLoad(out Name DeathAnim)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect HighestRankEffectState, EffectState;
	local X2Effect_Persistent HighestRankEffectTemplate, EffectTemplate;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != None)
		{
			EffectTemplate = EffectState.GetX2Effect();

			if ((EffectTemplate != none ) &&
				(HighestRankEffectState == none) || (EffectTemplate.IsThisEffectBetterThanExistingEffect(HighestRankEffectState)))
			{
				HighestRankEffectState = EffectState;
				HighestRankEffectTemplate = EffectTemplate;
			}
		}
	}

	if (HighestRankEffectState != none)
	{
		return HighestRankEffectTemplate.HasOverrideDeathAnimOnLoad(DeathAnim);
	}

	return false;
}

function bool DoesUnitBreaksConcealmentIgnoringDistance()
{
	local bool DoesBreakConcealment;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	DoesBreakConcealment = false;
	
	// Loop over the effects on the unit to see if the distance is ignored when breaking concealment
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if( EffectState != None )
		{
			EffectTemplate = EffectState.GetX2Effect();

			if( (EffectTemplate != None) &&
				(EffectTemplate.UnitBreaksConcealmentIgnoringDistanceFn != None) &&
				EffectTemplate.UnitBreaksConcealmentIgnoringDistanceFn() )
			{
				DoesBreakConcealment = true;
				break;
			}
		}
	}

	return DoesBreakConcealment;
}

function bool IsAnImmediateSelectTarget()
{
	// for the time being, only lost units count as immediate select targets
	if( GetTeam() == eTeam_TheLost )
	{
		return true;
	}

	return false;
}

function XComGameState_AdventChosen GetChosenGameState()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_AdventChosen ChosenState;

	History = `XCOMHISTORY;
		
	if( ChosenRef.ObjectID > 0 )
	{
		ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ChosenRef.ObjectID));
	}
	else
	{
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien', true));
		if( AlienHQ != None )
		{
			ChosenState = AlienHQ.GetChosenOfTemplate(GetMyTemplateGroupName());
		}
	}

	return ChosenState;
}

function EventListenerReturn OnSpawnReinforcementsComplete(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_AIGroup GroupState;
	local array<int> AffectedUnitIds;
	local array<XComGameState_Unit> AffectedUnits;
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	GroupState = XComGameState_AIGroup(EventData);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Chosen Reinforcements scamper");

	GroupState.GetLivingMembers(AffectedUnitIds, AffectedUnits);
	
	class'XComGameState_AIReinforcementSpawner'.static.AlertAndScamperUnits(NewGameState, AffectedUnits, true, GameState.HistoryIndex);

	EventManager.UnRegisterFromEvent(ThisObj, 'ChosenSpawnReinforcementsComplete');

	return ELR_NoInterrupt;
}

function SetRescueRingRadius( float NewRadius )
{
	local XGUnit Visualizer;

	Visualizer = XGUnit( GetVisualizer( ) );
	if (Visualizer != none)
	{
		if (RescueRingRadius > 0)
		{
			Visualizer.GetPawn().DetachRangeIndicator( );
		}

		if (NewRadius > 0)
		{
			Visualizer.GetPawn().AttachRangeIndicator( NewRadius, Visualizer.GetPawn().CivilianRescueRing );
		}
	}

	RescueRingRadius = NewRadius;
}

function bool UnitIsValidForPhotobooth()
{
	// Check that this is not a VIP.
	switch (GetMyTemplateName())
	{
	case 'Soldier_VIP':
	case 'Scientist_VIP':
	case 'Engineer_VIP':
	case 'FriendlyVIPCivilian':
	case 'HostileVIPCivilian':
	case 'CommanderVIP':
	case 'Engineer':
	case 'Scientist':
	case 'StasisSuitVIP':
		return false;
	}

	if (IsSoldier()
		&& !IsDead()
		&& !IsBleedingOut() // Bleeding-out units get cleaned up by SquadTacticalToStrategyTransfer, but that happens later
		&& GhostSourceUnit.ObjectID == 0 // Check that this is not a ghost.
		&& !bCaptured)
	{
		return true;
	}

	return false;
}

// Start Issue #106
function String GetSoldierClassIcon()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'SoldierClassIcon';
	Tuple.Data.Add(1);

	Tuple.Data[0].kind = XComLWTVString;
	Tuple.Data[0].s = GetSoldierClassTemplate().IconImage;

	`XEVENTMGR.TriggerEvent('SoldierClassIcon', Tuple, self, none);

	return Tuple.Data[0].s;
}

function String GetSoldierClassDisplayName()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'SoldierClassDisplayName';
	Tuple.Data.Add(1);

	Tuple.Data[0].kind = XComLWTVString;
	Tuple.Data[0].s = GetSoldierClassTemplate().DisplayName;

	`XEVENTMGR.TriggerEvent('SoldierClassDisplayName', Tuple, self, none);

	return Tuple.Data[0].s;
}

function String GetSoldierClassSummary()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'SoldierClassSummary';
	Tuple.Data.Add(1);

	Tuple.Data[0].kind = XComLWTVString;
	Tuple.Data[0].s = GetSoldierClassTemplate().ClassSummary;

	`XEVENTMGR.TriggerEvent('SoldierClassSummary', Tuple, self, none);

	return Tuple.Data[0].s;
}
// End Issue #106

// Start Issue #171
// Sets the eStat_UtilityItems of the unit and returns it.
function int RealizeItemSlotsCount(XComGameState CheckGameState)
{
	local int i, NumUtility;
	local array<X2DownloadableContentInfo> DLCInfos;
	local XComGameState_Item ArmorItem;

	NumUtility = GetMyTemplate().GetCharacterBaseStat(eStat_UtilityItems);

	ArmorItem = GetItemInSlot(eInvSlot_Armor, CheckGameState);

	if ((ArmorItem != none && X2ArmorTemplate(ArmorItem.GetMyTemplate()).bAddsUtilitySlot) || HasExtraUtilitySlotFromAbility())
	{
		NumUtility += 1.0f;
	}

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].GetNumUtilitySlotsOverride(NumUtility, ArmorItem, self, CheckGameState);
	}

	SetBaseMaxStat(eStat_UtilityItems, NumUtility);
	SetCurrentStat(eStat_UtilityItems, NumUtility);

	return NumUtility;
}

function int GetNumHeavyWeapons(optional XComGameState CheckGameState)
{
	local int i, NumHeavy;
	local array<X2DownloadableContentInfo> DLCInfos;

	NumHeavy = HasHeavyWeapon(CheckGameState) ? 1 : 0;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].GetNumHeavyWeaponSlotsOverride(NumHeavy, self, CheckGameState);
	}
	
	return NumHeavy;
}
// End Issue #171

////////////////////////////////////////////////////////////////////////////////////////
// cpptext

cpptext
{
	FCharacterStat& GetCharacterStat(ECharStatType StatType);
	const FCharacterStat& GetCharacterStat(ECharStatType StatType) const;

	virtual void Serialize(FArchive& Ar);

	// ----- X2GameRulesetVisibilityInterface -----
	virtual UBOOL CanEverSee() const
	{
		return UXComWorldData::Instance()->TileOnBoard(TileLocation);
	}

	virtual UBOOL CanEverBeSeen() const
	{
		return UXComWorldData::Instance()->TileOnBoard(TileLocation);
	}
	// ----- end X2GameRulesetVisibilityInterface -----
};

////////////////////////////////////////////////////////////////////////////////////////
// defprops

DefaultProperties
{
	UnitSize = 1;
	UnitHeight = 2;
	CoverForceFlag = CoverForce_Default;
	MPSquadLoadoutIndex = INDEX_NONE;
	CachedUnitDataStateObjectId = INDEX_NONE;
	GroupMembershipID = -1
	ActivationThreshold = 5
	bSpecialDeathOccured=false
	RescueRingRadius=0
	MentalState=eMentalState_Ready
}
