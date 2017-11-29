//---------------------------------------------------------------------------------------
//  FILE:    X2TacticalGameRulesetDataStructures.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: Container class that holds data structures common to various aspects of the
//           tactical game rules set
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TacticalGameRulesetDataStructures extends object 
	native(Core) 
	dependson(X2GameRulesetVisibilityDataStructures, UIUtilities_Text);

enum EAbilityHitResult
{
	eHit_Success,
	eHit_Crit,
	eHit_Graze,
	eHit_Miss,
	eHit_LightningReflexes,
	eHit_Untouchable,
	eHit_CounterAttack,	//Melee attacks can turn into this hit result type
	eHit_Parry,
	eHit_Deflect,
	eHit_Reflect,
};

var init localized string m_aAbilityHitResultStrings[EAbilityHitResult.EnumCount] <BoundEnum=EAbilityHitResult>;

struct native ArmorMitigationResults
{
	var bool bNaturalArmor;             //  deprecated - will always consider eStat_ArmorMitigation
	var ECoverType CoverType;           //  deprecated - cover as armor is not a thing
	var init array<StateObjectReference> BonusArmorEffects;         //  refs to the XComGameState_Effects which are granting an X2Effect_BonusArmor to the unit
	var int TotalMitigation;            //  total of all bonus armor effects plus eStat_ArmorMitigation
};

enum EInventorySlot
{
	eInvSlot_Unknown,
	eInvSlot_Armor,
	eInvSlot_PrimaryWeapon,
	eInvSlot_SecondaryWeapon,
	eInvSlot_HeavyWeapon,
	eInvSlot_Utility,
	eInvSlot_Mission,
	eInvSlot_Backpack,
	eInvSlot_Loot,
	eInvSlot_GrenadePocket,
	eInvSlot_CombatSim,
	eInvSlot_AmmoPocket,
	eInvSlot_TertiaryWeapon,
	eInvSlot_QuaternaryWeapon,
	eInvSlot_QuinaryWeapon,
	eInvSlot_SenaryWeapon,
	eInvSlot_SeptenaryWeapon,
};

enum EffectTemplateLookupType
{
	TELT_AbilityTargetEffects,
	TELT_AbilityMultiTargetEffects,
	TELT_AbilityShooterEffects,
	TELT_AmmoTargetEffects,
	TELT_BleedOutEffect,
	TELT_UnspottedEffect,
	TELT_WorldEffect,
	TELT_PersistantEffect,
	TELT_ThrownGrenadeEffects,
	TELT_LaunchedGrenadeEffects,
	TELT_WeaponEffects,
};

enum EXComUnitPawn_RagdollFlag
{
	ERagdoll_IfDamageTypeSaysTo,
	ERagdoll_Always,
	ERagdoll_Never
};

struct native X2EffectTemplateRef
{
	var() Name SourceTemplateName;
	var() EffectTemplateLookupType LookupType;
	var() int TemplateEffectLookupArrayIndex;
	var() int ApplyOnTickIndex;

	structcpptext
	{
		FX2EffectTemplateRef()
		{
		}
		FX2EffectTemplateRef(EEventParm)
		{
			appMemzero(this, sizeof(FX2EffectTemplateRef));
		}

		/** Serializer. */
		friend FArchive& operator<<(FArchive& Ar, FX2EffectTemplateRef& EffectTemplate)
		{
			Ar << EffectTemplate.SourceTemplateName 
				<< EffectTemplate.LookupType 
				<< EffectTemplate.TemplateEffectLookupArrayIndex 
				<< EffectTemplate.ApplyOnTickIndex;

			return Ar;
		}

		FORCEINLINE UBOOL operator==(const FX2EffectTemplateRef &Other) const
		{
			return (
				SourceTemplateName == Other.SourceTemplateName &&
				LookupType == Other.LookupType &&
				TemplateEffectLookupArrayIndex == Other.TemplateEffectLookupArrayIndex &&
				ApplyOnTickIndex == Other.ApplyOnTickIndex);
		}
	}

	structdefaultproperties
	{
		ApplyOnTickIndex=INDEX_NONE
	}
};

//This data structure can be used to gather useful information on a tile
struct native GameplayTileData
{
	var int SourceObjectID;
	var TTile EventTile;

	var init array<GameRulesCache_VisibilityInfo> VisibleEnemies; //A list of units which are enemies of the unit represented by SourceObjectID
	var int NumLocalViewers; //Tracks the number of player local viewers that can see this unit moving. Used to determine the unit's visibility state while performing the move
};

// Associates two object states that lie on either end of a move boundry. i.e., the state immediately
// before and after the given object changed locations.
struct MovedObjectStatePair 
{
	var XComGameState_BaseObject PreMoveState;
	var XComGameState_BaseObject PostMoveState;
};

// Associates two object states that lie on either end of a move boundry. i.e., the state immediately
// before and after the given object changed locations.
struct DamagedUnitStatePair 
{
	var XComGameState_Unit PreDamagedState;
	var XComGameState_Unit PostDamagedState;
};

struct native PathPoint
{
	var Vector Position;
	var ETraversalType Traversal;
	var bool Phasing;
	var int PathTileIndex;

	//We cannot store actor references in this structure because it may exist
	//outside GWorld
	var ActorIdentifier ActorId;

	structcpptext
	{
		FPathPoint()
		: Position(0, 0, 0)
		, Traversal(eTraversal_Normal)
		, Phasing(false),
		PathTileIndex(-1)
		{
		}

		FPathPoint(EEventParm)
			: Position(0, 0, 0)
			, Traversal(eTraversal_Normal)
			, Phasing(false),
			PathTileIndex(-1)
		{
		}

		FPathPoint(const FVector &InPos, ETraversalType InTraversal = eTraversal_Normal, bool InPhasing = false)
			: Position(InPos)
			, Traversal(InTraversal)
			, Phasing(InPhasing)
			, PathTileIndex(-1)
		{
		}

		UBOOL operator==(const FPathPoint& Other) const
		{
			return Position == Other.Position;
		}


		UBOOL operator!=(const FPathPoint& Other) const
		{
			return Position != Other.Position;
		}
	}
};

struct native ProjectileTouchEvent
{
	var float	TravelDistance;	//Stores the distance that this projectile traveled from its fire point to the HitLocation	
	var Vector	HitLocation;
	var Vector	HitNormal;
	var bool	bEntry;			//Indicates whether this is an entrance or exit event

	var TraceHitInfo TraceInfo; //Stores information useful for impacts ( like material )
};

struct native PathingInputData
{
	var StateObjectReference		MovingUnitRef;			//Unit performing this move
	var array<PathPoint>            MovementData;           //Used to store path points if a move was attempted. Eg Begin Move -> Direct Move -> Climb Over -> Land -> End Move.
	var array<TTile>                MovementTiles;          //Stores tiles traversed during the move
	var array<TTile>                WaypointTiles;          //Waypoints that were set while creating the movement path 
	var array<int>                  CostIncreases;          //Each element is an index into MovementTiles where the move cost increases
	var array<int>					Destructibles;			//Each element is an index into MovementTiles where a destructible will break
};

//Ability Input Context
struct native AbilityInputContext
{
	var name                        AbilityTemplateName;	//Template name of the used ability
	var StateObjectReference        AbilityRef;             //State object reference to the ability that was used
	var StateObjectReference        PrimaryTarget;          //Main target of the ability
	var array<StateObjectReference>	MultiTargets;           //Array of target objects (Units, Terrain, Items, etc) hit in addition to the primary target
	var array<bool>					MultiTargetsNotified;	//Array corresponding to MultiTargets, to tell us if the target has been notified.
	var array<vector>               TargetLocations;        //Holds an array of locations representing the location of the target, in some cases also hold the location of the PrimaryTarget
	var StateObjectReference        SourceObject;           //Unit/object performing the ability
	var StateObjectReference        ItemObject;             //Item used to perform the ability, if any

	//If this ability fires a projectile, this contains information about what that projectile did as it traveled. Can be used by effects to apply damage to the world.
	var array<ProjectileTouchEvent> ProjectileEvents;
	var vector						ProjectileTouchStart;
	var vector						ProjectileTouchEnd;
	
	//Pathing support                           
	var array<PathingInputData>		MovementPaths;			 //Support for multiple unit paths

	var array<TTile>				VisibleTargetedTiles;    // These are tiles the targeting system has set to be active tiles
	var array<TTile>				VisibleNeighborTiles;    // These are tiles the targeting system has set to be active tiles

	structcpptext
	{
		FAbilityInputContext(){}
		FAbilityInputContext(EEventParm)
		{
			appMemzero(this, sizeof(FAbilityInputContext));
		}

		FString ToString() const;
	}
};

struct native EffectResults
{
	var array<X2Effect> Effects;
	var array<X2EffectTemplateRef> TemplateRefs;
	var array<name> ApplyResults;
};

struct native OverriddenEffectsInfo
{
	var name OverrideType;
	var array<X2Effect> OverriddenEffects;
	var array<X2Effect> OverriddingEffects;
};

struct native OverriddenEffectsByType
{
	var array<OverriddenEffectsInfo> OverrideInfo;
};

struct native PathingResultData
{
	var init array<GameplayTileData> PathTileData;
};

struct native EffectRedirect
{
	var StateObjectReference    OriginalTargetRef;      //  the effect's original intended target
	var StateObjectReference    RedirectedToTargetRef;  //  the new target
	var EffectResults           RedirectResults;        //  result of applying to the new target
	var name                    RedirectReason;         //  should be from AbilityAvailabilityCodes so localized text can used
};

//Ability Result Context
struct native AbilityResultContext
{
	var int CalculatedHitChance; // The hit chance calculated at the time this HitResult was applied
	var EAbilityHitResult HitResult; //Abilities that have a ToHitCalc set will fill this with the result during their initial ContextBuildGameState
	var ArmorMitigationResults ArmorMitigation;  // DEPRECATED - armor is always applied
	var int StatContestResult;  //Potentially set along with HitResult, to show the outcome of a stat contest (e.g. Psi attacks, Tech attacks)
	var OverriddenEffectsByType TargetEffectsOverrides;  // CURRENTLY USED PURELY TO PASS INFORMATION WHEN APPLYING THE EFFECT
	var EffectResults ShooterEffectResults;
	var EffectResults TargetEffectResults;
	var array<EAbilityHitResult> MultiTargetHitResults;
	var array<EffectResults> MultiTargetEffectResults;
	var array<ArmorMitigationResults> MultiTargetArmorMitigation;
	var array<int> MultiTargetStatContestResult;
	var array<OverriddenEffectsByType> MultiTargetEffectsOverrides;
	var array<EffectRedirect> EffectRedirects;

	var int InterruptionStep; //If this ability was interrupted, this defines what 'step' of the ability was interrupted.
	var class ObserverClass;  //Observer class that handled the interruption
		
	var array<PathingResultData> PathResults;//Contains information on events that resulted from the movement path(s)
	var array<TTile> RelevantEffectTiles;   //If the ability needs to pass tile data to an effect, it would do so through here.
	var array<vector> ProjectileHitLocations; //Stores the hit / miss locations for projectiles

	var int iCustomAbilityData; // used for passing custom ability data to the action, as needed.
	var int CachedFinalVisibilityStep; // -2 == not yet cached; -1 == cached, never visible; otherwise, cached step of last valid enemy visibility
	var bool bPathCausesDestruction; // true if processing movement and destruction is being caused by entering the new tile

	structcpptext
	{
		FAbilityResultContext(){}
		FAbilityResultContext(EEventParm)
		{
			appMemzero(this, sizeof(FAbilityInputContext));
			CachedFinalVisibilityStep = -2;
		}

		FString ToString() const;
	}

	structdefaultproperties
	{
		CachedFinalVisibilityStep=-2
	}
};

//This structure defines parameters for the application of this effect, providing
//information such as what the source / target were, the source ability, etc.
struct native EffectAppliedData
{
	var() StateObjectReference PlayerStateObjectRef;       // Player's turn when this effect was created
	var() StateObjectReference SourceStateObjectRef;       // The state object responsible for applying this effect
	var() StateObjectReference TargetStateObjectRef;       // A state object representing the Target that will be affected by this effect	
	var() StateObjectReference ItemStateObjectRef;         // Item associated with creating this effect, if any	

	var() StateObjectReference AbilityStateObjectRef;      // Ability associated with creating this effect, if any
	var() AbilityInputContext  AbilityInputContext;        // Copy of the input context used to create this effect		
	var() AbilityResultContext AbilityResultContext;       // Copy of the result context for the ability
	var() X2EffectTemplateRef  EffectRef;				   // The info necessary to lookup this X2Effect as a Template, given the source template
};

enum EDuplicateEffect
{
	eDupe_Allow,        //  new effect is added and tracked separately from the old effect
	eDupe_Refresh,      //  current effect's duration is reset    
	eDupe_Ignore,       //  new effect is not added and old effect is unchanged
};

enum EPerkBuffCategory
{
	ePerkBuff_Passive,  // icon show up in lower left if it is a soldier (does appear in the tooltip?)
	ePerkBuff_Bonus,    // you get a green arrow
	ePerkBuff_Penalty,  // you get red arrows
};

enum ECharStatType
{
	eStat_Invalid,
	eStat_UtilityItems,
	eStat_HP,
	eStat_Offense,
	eStat_Defense,
	eStat_Mobility,
	eStat_Will,
	eStat_Hacking,              // Used in calculating chance of success for hacking attempts.
	eStat_SightRadius,
	eStat_FlightFuel,
	eStat_AlertLevel,
	eStat_BackpackSize,
	eStat_Dodge,
	eStat_ArmorChance,          //  DEPRECATED - armor will always be used regardless of this value
	eStat_ArmorMitigation,      
	eStat_ArmorPiercing,
	eStat_PsiOffense,
	eStat_HackDefense,          // Units use this when defending against hacking attempts.
	eStat_DetectionRadius,		// The radius at which this unit will detect other concealed units.								Overall Detection Range = 
	eStat_DetectionModifier,	// The modifier this unit will apply to the range at which other units can detect this unit.	Detector.DetectionRadius * (1.0 - Detectee.DetectionModifier)
	eStat_CritChance,
	eStat_Strength,
	eStat_SeeMovement,
	eStat_HearingRadius,
	eStat_CombatSims,
	eStat_FlankingCritChance,
	eStat_ShieldHP,
	eStat_Job,
	eStat_FlankingAimBonus,
};

var init localized string m_aCharStatLabels[ECharStatType] <BoundEnum=ECharStatType>;

enum ECharStatModApplicationRule
{
	ECSMAR_None,			// do not change the current value when altering the max value
	ECSMAR_Additive,		// adjust the current value linearly by the delta between old and new MaxValue when altering the max value
	ECSMAR_Multiplicative,	// adjust the current value by keeping the same relative percentage between CurrentValue & MaxValue when altering the max value
};

struct native CharacterStat
{
	// The current value of this stat. May be modified independently of stat mods.
	var() private{private}	float			CurrentValue;

	// The current calculated maximum value of this stat, considering all mods applied to the stat.
	var() private{private,mutable}	float	MaxValue;

	// The base maximum value of this stat, ignoring any mods in effect on it.
	var() private{private}	float			BaseMaxValue;

	// The type of this stat, ie. what this stat represents.
	var() private{private}	ECharStatType	Type;

	// The list of effects that are currently modifying this stat.
	var() private{private}	array<StateObjectReference>	StatMods;
	// The final value each mod is providing to the stat.
	var() private{private}	array<float> StatModAmounts;

	// While false, the Max Value may be out of date and needs to be recached before the next access
	var   private{private,mutable} bool		CachedMaxValueIsCurrent;

	structcpptext
	{
		FCharacterStat() {}
		FCharacterStat(EEventParm)
		{
			appMemzero(this, sizeof(FCharacterStat));
		}

		/** Serializer. */
		friend FArchive& operator<<(FArchive& Ar, FCharacterStat& CharacterStat)
		{
			Ar << CharacterStat.CurrentValue 
				<< CharacterStat.MaxValue 
				<< CharacterStat.BaseMaxValue 
				<< CharacterStat.Type 
				<< CharacterStat.StatMods 
				<< CharacterStat.StatModAmounts;

			UBOOL Value = CharacterStat.CachedMaxValueIsCurrent;
			Ar << Value;
			CharacterStat.CachedMaxValueIsCurrent = Value;

			return Ar;
		}

		// add a new mod to this stat
		void ApplyMod( const class UXComGameState_Effect& SourceEffect, class UXComGameState* NewGameState );

		// remove an existing mod from this stat
		void UnApplyMod( const class UXComGameState_Effect& SourceEffect, class UXComGameState* NewGameState );

		// native mutators
		void SetBaseMaxValue( FLOAT Amount, ECharStatModApplicationRule ApplicationRule = ECSMAR_Additive );
		void SetCurrentValue( FLOAT Amount );
		void ModifyCurrentValue( FLOAT Delta );

		// native accessors
		FLOAT GetMaxValue();
		FLOAT GetCurrentValue() const;
		FLOAT GetBaseValue() const;
		void GetStatModifiers(TArray<class UXComGameState_Effect*>& Mods,TArray<FLOAT>& ModValues,UXComGameStateHistory* GameStateHistoryObject=NULL);


	private:
		// helper function to update the max value as a result of a known modification to it
		void UpdateMaxValue( ECharStatModApplicationRule ApplicationRule, class UXComGameState* NewGameState );

		// helper function to recache the max value for this stat
		void ReCacheMaxValue(class UXComGameState* NewGameState);

		// helper function to clamp the current value within the range 0...MaxValue
		void ClampCurrentValue();
	}
};

// Current order of opperations - MODOP_Multiplication, MODOP_Addition, MODOP_PostMultiplication
enum EStatModOp
{
	MODOP_Addition,
	MODOP_Multiplication,   // Pre-multiplication - This is in the base game and so stays the same name.
	MODOP_PostMultiplication,
};

struct native StatChange
{
	var ECharStatType   StatType;
	var float           StatAmount;
	var EStatModOp		ModOp;
	var ECharStatModApplicationRule ApplicationRule;

	structdefaultproperties
	{
		ApplicationRule=ECSMAR_Additive
	}
};

struct native TraversalChange
{
	var ETraversalType  Traversal;
	var bool            bAllowed;
};

enum EUnitValueCleanup
{
	eCleanup_BeginTurn,
	eCleanup_BeginTactical,
	eCleanup_Never,
};

struct native UnitValue
{
	var float fValue;
	var EUnitValueCleanup eCleanup;

	structcpptext
	{
		friend FArchive& operator<<( FArchive& Ar, FUnitValue& T );
	}
};

struct native StatCheck
{
	var ECharStatType Stat;
	var int RollsPerPoint;
	var float ChancePerRoll;
	var ECharStatType AddStatToSuccessCheck;
	var int AddValueToSuccessCheck;
};

enum ERelationshipState
{
	eRelationshipState_None,
	eRelationshipState_FirstCine,           // Eligible for 1st cine
	eRelationshipState_SecondCine,          // Eligible for 2nd cine
	eRelationshipState_SpecialBond,         // Soldiers share a special bond
};

struct native AppearanceInfo
{
	var string GenderArmorTemplate;
	var TAppearance Appearance;
};


struct native SquadmateScore
{
	var StateObjectReference    SquadmateObjectRef;
	var int                     Score;
	var ERelationshipState      eRelationship;
	var bool                    bPlayCine;

	structcpptext
	{
	FSquadmateScore()
	{
		appMemzero(this, sizeof(FSquadmateScore));
	}
	FSquadmateScore(EEventParm)
	{
		appMemzero(this, sizeof(FSquadmateScore));
	}

	FORCEINLINE UBOOL operator==(const FStateObjectReference &Other) const
	{
		return SquadmateObjectRef.ObjectID == Other.ObjectID;
	}
	}
};

//Looting related structures
struct native LootTableEntry
{
	var int     Chance;				//  0-100%
	var int     RollGroup;          //  Group identifies all loot table entries in a loot table that are rolled on at once	
	var int     MinCount, MaxCount;   //  Quantity of item received at random

	var float	ChanceModPerExistingItem; // a modifier on the chance, multiplicatively applied for each existing Item of type TemplateName acquired: TotalChance = Chance * ChanceModPerExistingItem ^ NumExistingItems
	
	//  NOTE: these two are mutually exclusive, so only one should ever be filled in for a given entry
	var name    TemplateName;           //  ItemTemplate name
	var name    TableRef;       //  Try not to reference your own LootTableName here...

	structdefaultproperties
	{
		MinCount=1
		MaxCount=1
		ChanceModPerExistingItem=1.0
	}
};

struct native LootTable
{
	var name    TableName;      //  unique identifier for this loot table
	var array<LootTableEntry> Loots;
};

struct native LootReference
{
	var() name    LootTableName;
	var() int     ForceLevel;       //  alien force level must be >= this number for the LootReference to be valid
};

struct native LootCarrier           //  struct to use in template classes to define potential loot
{
	var() array<LootReference>    LootReferences;	
};

struct native GlobalLootCarrier extends LootCarrier     //  used by LootTableManager to handle loot carriers that are not templates
{
	var name CarrierName;
};

struct native LootResults           //  struct used on game state classes to know what loot is available
{
	var bool                    bRolledForLoot;     //  Has LootToBeCreated been filled out?
	var array<name>             LootToBeCreated;    //  Stores all loot that has yet to be taken.
	var array<StateObjectReference> AvailableLoot;  //  Any items created but not yet taken from this object (or items a player has left behind)
};
//End of looting related structures
//Commander Lookup table related structures
struct native CommanderLookupTableEntry
{
	var int ForceLevel;
	var array<name> Option;
};

struct native InventoryLoadoutItem
{
	var name Item;    //  template name
	//  may be some other info we need
	//  for now we will always use the template's location/slot automatically
};

struct native InventoryLoadout
{
	var name LoadoutName;
	var array<InventoryLoadoutItem> Items;
};

///Begin - Soldier Class Definitions
struct native SoldierClassAbilityType
{
	var name AbilityName;
	var EInventorySlot ApplyToWeaponSlot;
	var name UtilityCat;
};
struct native SoldierClassStatType
{
	var ECharStatType   StatType;
	var int             StatAmount;
	var int             RandStatAmount;     //   if > 0, roll this number and add to StatAmount to get the new value
	var int             CapStatAmount;      //   if > 0, the stat cannot increase beyond this amount
};
struct native SoldierClassRandomAbilityDeck
{
	var name DeckName;
	var array<SoldierClassAbilityType> Abilities;
};
struct native SoldierClassAbilitySlot
{
	var SoldierClassAbilityType AbilityType; // Can be empty struct in the case of blank slot on the tree
	var name RandomDeckName;				 // If picking a random ability for the slot, look at the random decks on the X2SoldierClassTemplate for this deck
	var bool bFixedAbilityPosition;			 // Ability will not move if whole ability tree is randomized
};
struct native SoldierClassWeaponType
{
	var name WeaponType;
	var EInventorySlot SlotType;
};
struct native SoldierClassRank
{
	var array<SoldierClassAbilitySlot>      AbilitySlots;
	var array<SoldierClassStatType>         aStatProgression;
};
struct native SCATProgression // SoldierClassAbilityTreeProgression
{
	var int iRank;
	var int iBranch;
};
///End - Soldier Class Definitions
struct native ClassAgnosticAbility
{
	var SoldierClassAbilityType AbilityType;
	var int iRank;
	var bool bUnlocked;
};

// Used to build an individual soldier's ability tree
struct native SoldierRankAbilities
{
	var array<SoldierClassAbilityType> Abilities;
};

struct native DamageModifierInfo
{
	var() int     Value;
	var() X2EffectTemplateRef SourceEffectRef;
	var() int	  SourceID;
	var() bool    bIsRupture;

	structcpptext
	{
		FDamageModifierInfo() {}
		FDamageModifierInfo(EEventParm)
		{
			appMemzero(this, sizeof(FDamageModifierInfo));
		}
		FDamageModifierInfo(INT InValue, FX2EffectTemplateRef InSourceEffectRef, INT InSourceID, UBOOL InIsRupture)
			: Value(InValue), SourceEffectRef(InSourceEffectRef), SourceID(InSourceID), bIsRupture(InIsRupture)
		{}
	}
};

struct native WeaponDamageValue
{
	var() int Damage;           //  base damage amount
	var() int Spread;           //  damage can be modified +/- this amount
	var() int PlusOne;          //  chance from 0-100 that one bonus damage will be added
	var() int Crit;             //  additional damage dealt on a critical hit
	var() int Pierce;           //  armor piercing value
	var() int Rupture;          //  permanent extra damage the target will take
	var() int Shred;            //  permanent armor penetration value
	var() name Tag;
	var() name DamageType;
	var() array<DamageModifierInfo> BonusDamageInfo;
};

struct native DamageResult
{
	var int DamageAmount, MitigationAmount, ShieldHP, Shred;
	var bool bImmuneToAllDamage;	//	if ALL of the damage being dealt was 0'd out due to immunity, it will be tracked here
	var bool bFreeKill;     //  free kill weapon upgrade forced death of the unit
	var name FreeKillAbilityName;
	var EffectAppliedData SourceEffect;
	var XComGameStateContext Context;
	var array<DamageModifierInfo> SpecialDamageFactors;
	var array<name> DamageTypes;
};

struct native ShotModifierInfo
{
	var() EAbilityHitResult ModType;
	var() int     Value;
	var() string  Reason;
};

struct native ShotBreakdown
{
	var array<ShotModifierInfo> Modifiers;
	var int ResultTable[EAbilityHitResult.EnumCount];   //  breakdown by EAbilityHitResult to hit, crit, dodge, etc.
	var ArmorMitigationResults ArmorMitigation;         //  not the actual results but the allowed armor for this shot
	var int FinalHitChance;                             //  total chance to hit + crit from ResultTable
	var bool HideShotBreakdown;
	var bool bIsMultiShot; 
	var int MultiShotHitChance; 
	var name SpecialGuaranteedHit;                      //  e.g. Reaper class using Vektor Rifle
	var string SpecialCritLabel;						//	e.g. Reaper unit with Executioner ability
};

enum AbilityEventFilter
{
	eFilter_None,
	eFilter_Unit,
	eFilter_Player,
};

struct native AbilityEventListener
{
	var name EventID;
	var delegate<AbilityEventDelegate> EventFn;
	var EventListenerDeferral Deferral;
	var AbilityEventFilter Filter;
	var Object OverrideListenerSource; //Should only ever be a persistent object
	var int Priority;

	structdefaultproperties
	{
		Priority=50;            //  matches default value for RegisterForEvent
	}
};

struct native AbilitySetupData
{
	var name TemplateName;
	var X2AbilityTemplate Template;
	var StateObjectReference SourceWeaponRef;
	var StateObjectReference SourceAmmoRef;
};

struct native XpEventDef
{
	var name    EventID;
	var int     GlobalCap;
	var int     PerUnitCap;
	var int     PerTargetCap;
	var float   Shares;
	var float   PoolPercentage;
	var float   SquadShares;
	var bool    KillXp;

	structcpptext
	{
		FXpEventDef()
		{
			appMemzero(this, sizeof(FXpEventDef));
		}
		FXpEventDef(EEventParm)
		{
			appMemzero(this, sizeof(FXpEventDef));
		}

		FORCEINLINE UBOOL operator==(const FXpEventDef &Other) const
		{
			return EventID == Other.EventID;
		}
	}
};

struct native WeaponAttachment
{
	var() name AttachSocket;
	var() name UIArmoryCameraPointTag;
	var() string AttachMeshName;
	var() EGender RequiredGender; // if gender is specified, only apply the attachment for characters of that gender
	var() string AttachIconName;
	var() string InventoryIconName;
	var() string InventoryCategoryIcon;
	var() string AttachProjectileName <ToolTip="Specifies additional projectile content that will play when a weapon with this upgrade is fired">;
	var() name ApplyToWeaponTemplate;
	var() bool AttachToPawn;
	var Object LoadedObject;
	var Object LoadedProjectileTemplate;
	var delegate<CheckUpgradeStatus>			ValidateAttachmentFn;
};

//Body part template info
struct native X2PartInfo
{
	var name TemplateName;
	var EGender Gender;
	var ECharacterRace Race;
	var name Language;
	var string ArchetypeName;
	var bool SpecializedType;

	// Body Info
	var ECivilianType CivilianType;

	// Hair Info
	var bool bCanUseOnCivilian;
	var bool bIsHelmet;

	//ArmorPart Info
	var bool bVeteran;
	var bool bAnyArmor;
	var name ArmorTemplate;
	var name CharacterTemplate;
	var name Tech;
	var name ReqClass;

	//Allows body parts to belong to 'set' of parts keyed off of the torso selection
	var array<name> SetNames;

	var string PartType;
	var string DLCName; //Name of the DLC / Mod this part is a part of
	var bool bGhostPawn;
};

//End - Body part template info

struct native SpawnPointCache
{
	var XComGroupSpawn  GroupSpawnPoint;
	var array<vector>   FloorPoints;
};

struct native AttachedComponent 
{
	var() name SubsystemTemplateName; // Character Template name for component.
	var() name SocketName; // Where to attach this component.
};

struct native BehaviorTreeNode
{
	var name	BehaviorName;
	var name    NodeType; // Can be Sequence/Selector/Condition/Action/Decorator
	var array<name> Child; // Child names must match another BehaviorName.  Sequences/selectors can have multiples, Decorators can have one, conditions/actions have none.
	var array<name> Param; // Parameters may be used for leaf nodes.
	var name	Intent;    // for debugging purposes.
};

// PrecomputedPathData are values that precomputed paths use
// so design can change things like max arc and number of times
// a thrown item may bounce along the path
struct native PrecomputedPathData
{
	var float InitialPathTime;
	var float MaxPathTime;
	var int MaxNumberOfBounces;

	structdefaultproperties
   {
		InitialPathTime=1.0f
		MaxPathTime=2.5f
		MaxNumberOfBounces=4
   }
};

struct native StatBoostDefinition
{
	var int			  PowerLevel;
	var ECharStatType StatType;
	var int			  MinBoost;
	var int			  MaxBoost;
};

struct native StatBoost
{
	var ECharStatType StatType;
	var int			  Boost;
};

// Used for storing a units old equipment after "Make Items Available" so reequip can be attempted
struct native EquipmentInfo
{
	var StateObjectReference EquipmentRef;
	var EInventorySlot		 eSlot;
};

struct native ModifyChosenActivationIncreasePerUse
{
	var float Amount;
	var EStatModOp ModOp;

	structdefaultproperties
	{
		Amount = 0
		ModOp = MODOP_Addition
	}
};

delegate bool CheckUpgradeStatus(array<X2WeaponUpgradeTemplate> AllUpgradeTemplates);

delegate EventListenerReturn AbilityEventDelegate(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData);       //  This is a copy of X2EventManager:OnEventDelegate because we don't have visiblity to it here

static native function string GetVisibilityInfoDebugString(const out GameRulesCache_VisibilityInfo VisibilityInfo);
static native function DrawVisibilityInfoDebugPrimitives(const out GameRulesCache_VisibilityInfo VisibilityInfo);

//This method analyzes the passed-in game state and returns the object ID of the state object has moved in this game state. Currently we only 
//permit one state object to move per game state.
static native function int GetMovedStateObjectID(XComGameState NewGameState);

/// <summary>
/// Given a game state, NewGameState, output a list of state objects that changed location / position within the NewGameState 
/// </summary>
static function GetMovedStateObjectList(XComGameState NewGameState, out array<MovedObjectStatePair> OutMovedStateObjects)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject StateObjectCurrent;
	local XComGameState_BaseObject StateObjectPrevious;
	local X2GameRulesetVisibilityInterface CurrentInterface;
	local X2GameRulesetVisibilityInterface PreviousInterface;
	local TTile CurrentLocation;
	local TTile PreviousLocation;
	local MovedObjectStatePair StatePair;

	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType( class'XComGameState_BaseObject', StateObjectCurrent )
	{
		CurrentInterface = X2GameRulesetVisibilityInterface(StateObjectCurrent);
		if( CurrentInterface != none )
		{
			StateObjectPrevious = History.GetGameStateForObjectID(StateObjectCurrent.ObjectID, , NewGameState.HistoryIndex - 1);
			PreviousInterface = X2GameRulesetVisibilityInterface(StateObjectPrevious);
			
			CurrentInterface.GetKeystoneVisibilityLocation(CurrentLocation);

            if( PreviousInterface != none )
			    PreviousInterface.GetKeystoneVisibilityLocation(PreviousLocation);
			
			if( CurrentLocation != PreviousLocation )
			{
				StatePair.PreMoveState = StateObjectPrevious;
				StatePair.PostMoveState = StateObjectCurrent;
				OutMovedStateObjects.AddItem(StatePair);
			}
		}
	}
}

/// <summary>
/// Given a game state, NewGameState, output a list of unit state objects that took damage within the NewGameState 
/// </summary>
static function GetDamagedUnitList(XComGameState NewGameState, out array<DamagedUnitStatePair> OutDamagedUnitStates)
{
	local XComGameStateHistory History;
	
	local DamagedUnitStatePair StatePair;

	local XComGameState_Unit CurrentUnitState;
	local XComGameState_Unit PreviousUnitState;

	History = `XCOMHISTORY;

	`assert(NewGameState.HistoryIndex > -1);
	foreach NewGameState.IterateByClassType(class'XComGameState_Unit', CurrentUnitState)
	{
		PreviousUnitState = XComGameState_Unit( History.GetGameStateForObjectID(CurrentUnitState.ObjectID, , NewGameState.HistoryIndex - 1) );
		
		if( PreviousUnitState != none )
		{
			if( CurrentUnitState.GetCurrentStat(eStat_HP) < PreviousUnitState.GetCurrentStat(eStat_HP) )
			{
				StatePair.PreDamagedState = PreviousUnitState;
				StatePair.PostDamagedState = CurrentUnitState;
				OutDamagedUnitStates.AddItem(StatePair);
			}
		}		
	}
}

static function XComGameState_Unit GetAttackingUnitState(XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext != none)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		if (AbilityTemplate == none)
		{
			`RedScreen("NewGameState using Ability Context without a valid ability template?" @ AbilityContext.InputContext.AbilityTemplateName);
		}
		else
		{
			if (AbilityTemplate.Hostility == eHostility_Offensive)
			{
				UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
				if (UnitState == none)
					UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
			}
		}
	}
	return UnitState;
}

static function bool InventorySlotIsEquipped(EInventorySlot Slot)
{
	switch(Slot)
	{
	case eInvSlot_Backpack:
	case eInvSlot_Loot:
		return false;
	}
	return true;
}

static function bool InventorySlotBypassesUniqueRule(EInventorySlot Slot)
{
	switch(Slot)
	{
	case eInvSlot_AmmoPocket:
	case eInvSlot_GrenadePocket:
		return true;
	}
	return false;
}
