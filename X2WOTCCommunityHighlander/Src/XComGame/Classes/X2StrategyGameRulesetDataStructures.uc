//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyGameRulesetDataStructures.uc
//  AUTHOR:  Ryan McFall  --  02/20/2013
//  PURPOSE: Container class that holds data structures common to various aspects of the
//           strategy game rules set
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyGameRulesetDataStructures 
	extends object 
	native(Core) 	
	dependson(XGTacticalGameCoreNativeBase, XComGameState)
	config(GameData);

// For appearance chance of persistent units
struct native AppearChance
{
	var int Difficulty;
	var int MissionCount;
	var int PercentChance;
};

// For linking template names to narrative moments
struct native TemplateNarrative
{
	var name TemplateName;
	var string Narrative;
};

// Soldier Will mental states
enum EMentalState
{
	eMentalState_Shaken,
	eMentalState_Tired,
	eMentalState_Ready,
};

// Soldier Com Int states
enum ECombatIntelligence
{
	eComInt_Standard,
	eComInt_AboveAverage,
	eComInt_Gifted,
	eComInt_Genius,
	eComInt_Savant,
};

// Resistance Faction Influene states
enum EFactionInfluence
{
	eFactionInfluence_Minimal,
	eFactionInfluence_Respected,
	eFactionInfluence_Influential,
	eFactionInfluence_MAX,
};

// For facilities to define their staff slots
struct native StaffSlotDefinition
{
	var name StaffSlotTemplateName; // Name of template
	var name LinkedStaffSlotTemplateName; // Name of template of linked slot
	var bool bStartsLocked; // Staff Slot must be unlocked
};

// Linked Templates
struct native LinkedTemplates
{
	var name TemplateA;
	var name TemplateB;
};

// Soldier Bond
struct native SoldierBond
{
	var StateObjectReference Bondmate; // Who the bond is with
	var float Compatibility; // How quickly cohesion increases
	var int BondLevel; // discrete level of bond (levels have different benefits)
	var int Cohesion; // raw score of bond
	var int MostRecentCohesionGain; 
	var bool bSoldierBondLevelUpAvailable;
	var bool bBondJustBecameAvailable;
};

// Min/Max Float
struct native MinMaxFloat
{
	var float MinValue;
	var float MaxValue;
};

// Distribution for soldier compatibility rolls
struct native CompatRollDistribution
{
	var int VeryLowWeight;
	var int LowWeight;
	var int HighWeight;
	var int VeryHighWeight;
};

// manually set region link length
struct native RegionLinkLength
{
	var name RegionA;
	var name RegionB;
	var float LinkLength;
	var float LinkLocLerp;
};

// Times for each wound state
struct native WoundLengths
{
	var array<int> WoundStateLengths;
};

// Health percentage for each wound state
struct native WoundHealthPercents
{
	var array<int> WoundStateHealthPercents;
};

// Pending doom (for panning on geoscape)
struct native PendingDoom
{
	var int Doom;
	var string DoomMessage;
};

// Amount of doom and chance to be chosen
struct native DoomAddedChance
{
	var int DoomToAdd;
	var int PercentChance;
};

// Aggregate doom added chances
struct native DoomAddedData
{
	var array<DoomAddedChance> DoomChances;
};

// For the mission calendar
struct native MissionMonthEntry
{
	var name MissionSource; // leave blank if using randomized deck
	var name RandomDeckName; // Name of configured deck in mission calendar
};

struct native MissionDeck
{
	var name DeckName;
	var name NextDeckName;
	var int MissionMonthDays;
	var bool bForceNoConsecutive;
	var array<MissionMonthEntry> Missions;
};

struct native RandomMissionDeck
{
	var name DeckName;
	var array<name> Missions;
};

struct native MissionRewardDeck
{
	var name MissionSource;
	var array<name> Rewards;
};

struct native DoomGenData
{
	var int NumFacilities;
	var int MinInterval;
	var int MaxInterval;
	var int Difficulty;
};

struct native MissionMonthDifficulty
{
	var int Month; // What month do we use this data
	var int CampaignDifficulty; // What campaign difficulty does this apply to
	var array<int> Difficulties; // The possibly mission difficulties
};

struct native SoldierClassCount
{
	var name	SoldierClassName;
	var int		Count;
};

struct native AlienFacilityBuildData
{
	var int Month; // What month do we use this data
	var int MinBuildDays; // Min days it takes to build a facility
	var int MaxBuildDays; // Max days it takes to build a facility
	var int MinLinkDistance; // Min ideal distance from a contacted region (will decrease if distance is impossible)
	var int MaxLinkDistance; // Max ideal distance from a contacted region
	var int Difficulty; // What difficulty setting is this for?
};

struct native CountryNames
{
	var array<string>	MaleNames;
	var array<string>	FemaleNames;
	var array<string>	MaleLastNames;
	var array<string>	FemaleLastNames;
	var int				PercentChance;
	var bool			bRaceSpecific;
	var ECharacterRace  Race;
};

struct native CountryRaces
{
	var int		iCaucasian;
	var int		iAfrican;
	var int		iHispanic;
	var int		iAsian;
};

enum NarrativeAvailabilityWindow
{
	NAW_OnAssignment,	// This narrative can be played any time after it is assigned to the player
	NAW_OnReveal,		// This narrative can be played any time after it is revealed to the player
	NAW_OnNag,			// This narrative can be played any time a nag needs to play to remind the player to complete this objective
	NAW_OnCompletion,	// This narrative can be played any time after it is completed by the player
};

enum NarrativePlayCount
{
	NPC_Multiple,
	NPC_Once,
	NPC_OncePerTacticalMission,
};

struct native NarrativeTrigger
{
	// The narrative moment that will be played.
	var XComNarrativeMoment	NarrativeMoment;

	// If specified, wait for this event to be triggered by the EventManager before playing this narrative. 
	// If unspecified, this narrative triggers immediately when available.
	var Name TriggeringEvent;

	// If specified, the above triggering event will only fire off when the Data for the event is a GameState Object based on this specific data template.
	var Name TriggeringTemplateName;

	// When registering for this event, register on this specific Deferral window.
	var EventListenerDeferral EventDeferral;

	// This specifies the window for when this narrative is available to be played.
	var NarrativeAvailabilityWindow AvailabilityWindow;

	// specify play frequency
	var NarrativePlayCount PlayCount;

	// If specified, when this NarrativeTrigger qualifies to be played; a narrative moment will be chosen from amongst 
	// all of the qualifying triggers within the same NarrativeDeck.
	var Name NarrativeDeck;

	// Function to call when the narrative completes playing (most likely only used for binks or matinees)
	var delegate<NarrativeCompleteDelegate> NarrativeCompleteFn;

	// Whether or not the X2Action_PlayNarrative should wait for narrative completion.  Presence of NarrativeComleteFn forces this to true
	var bool bWaitForCompletion;

	// If not none, determines whether the narrative should play
	var delegate<NarrativeRequirementsMet> NarrativeRequirementsMetFn;
};

struct native DynamicNarrativeMoment
{
	var name										ExclusionGroup; // An identifier specifying moments which should also be marked as played whenever this one is
	var name										MomentCondition; // A condition associated with this specific narrative moment
	var name										SequenceID; // An ID to group sequenced narrative moments across multiple events together
	var XComNarrativeMoment							NarrativeMoment;
};

struct native BlackMarketItemPrice
{
	var StateObjectReference ItemRef;
	var int Price;
};

struct native StrategyNames
{
	var array<name>			Names;
};

struct native ArtifactCost
{
	var name ItemTemplateName;
	var int Quantity;
};

struct native StrategyCostScalar
{
	var name ItemTemplateName;
	var float Scalar;
	var int Difficulty; // The difficulty on which this scalar will be applied
};

struct native StrategyCost
{
	var array<ArtifactCost> ResourceCosts;
	var array<ArtifactCost> ArtifactCosts;
};

struct native StrategyRequirement
{
	var array<Name>			RequiredTechs;
	var bool				bVisibleIfTechsNotMet;
	var array<Name>			RequiredItems;
	var array<Name>         AlternateRequiredItems;
	var array<ArtifactCost> RequiredItemQuantities;
	var bool				bVisibleIfItemsNotMet;
	var array<Name>			RequiredEquipment;
	var bool				bDontRequireAllEquipment;
	var bool				bVisibleIfRequiredEquipmentNotMet;
	var array<Name>			RequiredFacilities;
	var bool				bVisibleIfFacilitiesNotMet;
	var array<Name>			RequiredUpgrades;
	var bool				bVisibleIfUpgradesNotMet;
	var int					RequiredEngineeringScore;
	var int					RequiredScienceScore;
	var bool				bVisibleIfPersonnelGatesNotMet;
	var int					RequiredHighestSoldierRank;
	var Name				RequiredSoldierClass;
	var bool				RequiredSoldierRankClassCombo;
	var bool				bVisibleIfSoldierRankGatesNotMet;
	var array<Name>			RequiredObjectives;
	var bool				bVisibleIfObjectivesNotMet;
	var delegate<SpecialRequirementsDelegate> SpecialRequirementsFn;

	structcpptext
	{
		FStrategyRequirement()
		{
		}
		FStrategyRequirement(EEventParm)
		{
			appMemzero(this, sizeof(FStrategyRequirement));
		}

		// True if there are no requirements specified or if all specified requirements have been met.
		UBOOL RequirementMet() const;

		// True if there are any requirements actually specified on this StrategyRequirement.
		UBOOL AnyRequirementsSpecified() const;
	}
};

struct native Commodity
{
	var StateObjectReference		RewardRef;
	var StrategyRequirement			Requirements;
	var StrategyCost				Cost;
	var String						Title;
	var String						Desc;
	var String						Image;
	var bool						bTech;
	var bool						bOrder;
	var int							OrderHours;
	var array<StrategyCostScalar>	CostScalars;
	var int							DiscountPercent;
};

enum EResistanceLevelType
{
	eResLevel_Locked,
	eResLevel_Unlocked,
	eResLevel_Contact,
	eResLevel_Outpost,
	eResLevel_Max, 
};

enum EResearchProgress
{
	eResearchProgress_VerySlow,
	eResearchProgress_Slow,
	eResearchProgress_Normal,
	eResearchProgress_Fast,
};

struct native TResistanceActivity
{
	var name		ActivityTemplateName;
	var String		Title;
	var EUIState	Rating;	// Good or bad
	var int			Count;
	var int			LastIncrement;
};

struct native TRegion
{
	var string        strRegion;
	var int           iContinent;
	var bool          bCanBePopulated;
	var array<TRect>  arrBounds;
	var array<string> arrAdjacentRegions;
	//TODO: Add other relevant data like localized strings, etc.
};

struct native ContinentRegions
{
	var string                      strContinent;
	var array<StateObjectReference> Regions;
};

struct native TCity
{
	var string      strCity;
	var int         iCountry;
	var string      strRegion;
	var Vector2D    v2Coords;
};

// TODO: Move these into loc files somehow
struct native CityText
{
	var string              strCity;
	var string              strPoiText;
};

enum ETimeOfDay
{   
	eTimeOfDay_None,
	eTimeOfDay_Dawn,
	eTimeOfDay_MorningTwilight,
	eTimeOfDay_Sunrise,
	eTimeOfDay_Morning,
	eTimeOfDay_Noon,
	eTimeOfDay_Afternoon,
	eTimeOfDay_Evening,
	eTimeofDay_Sunset,
	eTimeOfDay_EveningTwilight,
	eTimeOfDay_Dusk,
	eTimeOfDay_Night,
	eTimeOfDay_Max
};

enum EWoundType
{
	eWoundType_Light,
	eWoundType_Medium,
	eWoundType_Severe,
};

struct native MissionRewardDistribution
{
	var int iMission_Supplies;
	var int iMission_Intel;
	var int iMission_Data;
	var int iMission_ScienceVIP;
	var int iMission_EngineeringVIP;
	var int iMission_SoldierVIP;
	var int iMission_Clue;
	var int iMission_Item;
};

// Temp structure to pass mission rewards in the prototype
// TODO: Remove once the strategy game saves it's progress when going back and forth with tactical
struct native ProtoMissionRewards
{
	var name RewardTypeName;
	var int RewardAmount;
};

// Should make a generic reward struct
struct native ResourceCacheReward
{
	var name RewardTypeName;
	var int RewardAmount;
};

struct native ResourceCacheRewardType
{
	var name RewardTypeName;
	var int PercentChance;
};

enum EVisibilityType
{
	eVisibilityType_NeverSeen,
	eVisibilityType_HasSeen,
	eVisibilityType_CanSee,
};

enum EObjectiveState
{
	eObjectiveState_NotStarted,
	eObjectiveState_InProgress,
	eObjectiveState_Completed,
};

enum EStaffType
{
	eStaff_None,
	eStaff_Soldier,
	eStaff_Scientist,
	eStaff_Engineer,
	eStaff_HeadEngineer,
	eStaff_HeadScientist,
	eStaff_Central,
	eStaff_Commander,
};

enum EStaffStatus
{
	eStaffStatus_Available,  // not assigned to any slot
	eStaffStatus_Busy        // assigned to a slot
};

// mnauta: first pass on different types of slots/ pls add and change
enum EUnitSlotType
{
	eUnitSlotType_None,
	eUnitSlotType_Bucket,
	eUnitSlotType_Passive,
	eUnitSlotType_Patient,
	eUnitSlotType_Repair,
	eUnitSlotType_Build,
	eUnitSlotType_PreparingForMission,
};

enum EPowerState
{
	ePowerState_Green,
	ePowerState_Yellow,
	ePowerState_Red,
};

struct native BiomeMapping
{
	var string BiomeName;
	var string Channel; // r,g,b, or a
	var int Value; // 0-255
};

// Biomes not drawn on the biome texture can have a chance to appear
struct native BiomeChance
{
	var string BiomeName;
	var int Chance;
};

struct native BiomeTerrain
{
	var string		  BiomeType;
	var array<string> arrMapNames;
};

struct native LandingSiteLighting
{
	var string		  MapName;
	var ETimeOfDay    eTimeOfDay;
	var array<string> arrBiomeTypes;
};

struct native RegionPath
{
	var array<XComGameState_WorldRegion> Regions;
	var int Cost;
};

struct native RoomAdjacency
{
	var int RoomIndex;
	var array<int>  AdjacentRooms;
};

struct native StaffUnitInfo
{
	var StateObjectReference UnitRef;
	var StateObjectReference PairUnitRef; // If the staff slot accepts a pair of units, this ref points to the second one
	var bool bGhostUnit;
	var StateObjectReference GhostLocation;
};

var config array<Name> UIAlertTypes;
//enum EAlertType
//{
//	eAlert_CouncilComm,
//	eAlert_GOps,
//	eAlert_Retaliation,
//	eAlert_AlienFacility,
//	eAlert_Control,
//	eAlert_Doom,//5
//	eAlert_HiddenDoom,
//	eAlert_UFOInbound,
//	eAlert_UFOEvaded,
//	eAlert_Objective,
//	eAlert_Contact, //10
//	eAlert_Outpost,
//	eAlert_ContactMade,
//	eAlert_OutpostBuilt,
//	eAlert_ContinentBonus,
//	eAlert_BlackMarket,// 15
//	eAlert_RegionUnlocked,
//	eAlert_RegionUnlockedMission,
//
//	eAlert_ResearchComplete,
//	eAlert_ItemComplete,
//	eAlert_ProvingGroundProjectComplete,//20
//	eAlert_FacilityComplete,
//	eAlert_UpgradeComplete,
//	eAlert_ShadowProjectComplete,
//	eAlert_ClearRoomComplete,
//	eAlert_TrainingComplete,//25
//	eAlert_SoldierPromoted,
//	eAlert_PsiSoldierPromoted,
//
//	eAlert_BuildSlotOpen,
//	eAlert_ClearRoomSlotOpen,
//	eAlert_StaffSlotOpen, // 30
//	eAlert_BuildSlotFilled,
//	eAlert_ClearRoomSlotFilled,
//	eAlert_StaffSlotFilled,
//	eAlert_SuperSoldier,
//
//	eAlert_ResearchAvailable,
//	eAlert_ItemAvailable,// 35
//	eAlert_ItemReceived,
//	eAlert_ItemUpgraded,
//	eAlert_ProvingGroundProjectAvailable,
//	eAlert_FacilityAvailable,
//	eAlert_UpgradeAvailable,// 40
//	eAlert_ShadowProjectAvailable,
//	eAlert_NewStaffAvailable,
//
//	eAlert_XCOMLives,
//	eAlert_HelpContact,
//	eAlert_HelpOutpost,// 45 
//	eAlert_HelpResHQGoods,
//	eAlert_HelpHavenOps,
//	eAlert_HelpNewRegions,
//	eAlert_HelpMissionLocked,
//
//	eAlert_SoldierShaken,//50 
//	eAlert_SoldierShakenRecovered,
//
//	eAlert_NewScanningSite,
//	eAlert_ScanComplete,
//
//	eAlert_DarkEvent,
//
//	eAlert_BlackMarketAvailable,//55 
//	eAlert_ResourceCacheAvailable,
//	eAlert_ResourceCacheComplete,
//
//	eAlert_SupplyRaid,
//	eAlert_LandedUFO,
//	eAlert_CouncilMission,// 60
//
//	eAlert_CustomizationsAvailable,
//	eAlert_ForceUnderstrength,
//	eAlert_MissionExpired,
//	eAlert_WoundedSoldiersAllowed,
//	eAlert_PsiTrainingComplete,//65 
//	eAlert_TimeSensitiveMission,
//	eAlert_PsiOperativeIntro,
//	eAlert_WeaponUpgradesAvailable,
//	eAlert_AlienVictoryImminent, // 69
//	eAlert_InstantResearchAvailable,
//	eAlert_NewStaffAvailableSmall,
//
//	eAlert_LowIntel, // 72
//	eAlert_LowSupplies,
//	eAlert_LowScientists,
//	eAlert_LowEngineers,
//	eAlert_PsiLabIntro,
//	eAlert_LowScientistsSmall,
//	eAlert_LowEngineersSmall,
//	eAlert_SupplyDropReminder,
//	eAlert_PowerCoilShielded, // 80
//	eAlert_StaffInfo,
//	eAlert_ItemReceivedProvingGround,
//	eAlert_LaunchMissionWarning,
//
//	// Expansion Alerts
//	eAlert_CovertActions,
//	eAlert_LostAndAbandoned,
//	eAlert_ResistanceOp,
//	eAlert_ChosenAmbush,
//	eAlert_ChosenStronghold,
//	eAlert_RescueSoldier,
//
//	eAlert_NegativeTraitAcquired,
//	eAlert_PositiveTraitAcquired,
//
//	eAlert_InspiredResearchAvailable,
//	eAlert_BreakthroughResearchAvailable,
//};

//// TODO: convert all per-alert properties to be part of this struct
//struct native ReturnFromMissionPopupInfo
//{
//	var EAlertType AlertType;
//
//	var int UnitID;
//
//	var Name PrimaryTemplateName;
//	var Name SecondaryTemplateName;
//	var Name EventToTrigger;
//	var string SoundToPlay;
//};

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


struct native DynamicProperty
{
	// the name of this property
	var Name Key;

	// the current value of this property
	var Name ValueName;
	var int ValueInt;
	var float ValueFloat;
	var string ValueString;
	var Vector ValueVector;
	//var Object ValueObject;
	var array<DynamicProperty> ValueArray;
};

struct native DynamicPropertySet
{
	// The primary routing key to determine where this property set is applicable
	var Name PrimaryRoutingKey;

	// The secondary routing key to specify the particular handling of the data contained within
	var Name SecondaryRoutingKey;

	// The set of data special to the specified Primary/Secondary keys above
	var array<DynamicProperty> DynamicProperties;

	// The Handler for what happens after this information is presented
	var delegate<AlertCallback> CallbackFunction;

	// When it is applicable to display this message set
	var bool bDisplayImmediate;
	var bool bDisplayOnAvengerSideViewIdle;
	var bool bDisplayOnGeoscapeIdle;
	var bool bDisplayInTacticalIdle;
};

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


struct native SoldierAbilityInfo
{
	var int iRank;
	var int iBranch;
	var X2AbilityTemplate AbilityTemplate;
};

struct native SoldierMoment
{
	var StateObjectReference Soldier_A;
	var StateObjectReference Soldier_B;
	var bool SpecialBond;
};

struct native AvengerAnimationCharacter
{
	var eStaffType CharacterType;
	var int        PercentChance;
};

struct native AvengerAnimationSlot
{
	var array<AvengerAnimationCharacter> EligibleCharacters;
	var bool                             IsMandatory;
	var bool                             CorrespondsToStaffingSlot;
};

struct native WeightedAvengerAnimationEntry
{
	var X2AvengerAnimationTemplate AnimTemplate;
	var float                      Weight;
};

struct native HQEvent
{
	var string Data;
	var int Hours;

	var string Title;
	var string DayLabel;
	var string DayValue;
	var string ImagePath;
	var StateObjectReference FacilityHotLinkRef;
	var StateObjectReference ActionRef;
	var bool bActionEvent;
};

struct native LootData
{
	var int Quantity;
	var name ItemTemplateName;
};

struct native SpecialRoomFeatureEntry
{
	var X2SpecialRoomFeatureTemplate FeatureTemplate;
	var int Quantity;
};

struct native PopSupportThresholdReward
{
	var name				 RegionBonus;
	var StateObjectReference RewardReference;
	var int					 SuppliesPerInterval;
	var int					 MaxCaches;
	var bool				 bGenerateCaches;
	var bool				 bThresholdPassed;
	var bool				 bRevealTradingPost;
	var StateObjectReference EndingMissionReference;
};

struct native ClueThreshold
{
	var int		CluesRequired;
	var bool	bThresholdPassed;
	var bool	bForceLevelIncrease;
	var bool	bAlienBase;
};

struct native RewardDeckEntry
{
	var name	RewardName;
	var int		Quantity;
	var int		ForceLevelGate;
};

struct native EndingMissionData
{
	var name MissionSource; // template name of mission source
	var name RewardTypeName; // e.g. Reward_Item
	var name RewardObjectName; // e.g. Toxin engineering project
	var name PreMissionObjective;
	var name PostMissionObjective;
	var XComNarrativeMoment PostMissionComm; // Play on first base view after mission if other mission not yet completed.
};

struct native WoundSeverity
{
	var float MinHealthPercent;
	var float MaxHealthPercent;
	var int   MinPointsToHeal;
	var int	  MaxPointsToHeal;
	var int   Difficulty;
};

// Ambient VO specific to particular endings
struct native AmbientEndingComm
{
	var int GatingTentPole; // What tentpole needs to be passed for comm to be valid
	var array<name> Facilities;  // what facilities does this ambient VO play in
	var XComNarrativeMoment NarrativeMoment; // the narrative moment to play
	var int GatingMissions; // How many story missions must be passed (in current tentpole couplet)
	var bool bTriggered; // Has this VO been played
};

// Defines a strategy cost and reward pair
struct native StrategyCostReward
{
	var StrategyCost Cost;
	var name Reward;
};

// Defines a weighting structure for a POI
struct native POIWeight
{
	var array<int> Weight; // Weight array per difficulty
	var int DaysActive; // The number of days this Weight setting will be active
};

struct native CovertActionSlot
{
	var name StaffSlot;
	var array<name> Rewards; // List of rewards which can be applied to a unit in the slot; only one will be chosen
	var bool bFactionClass; // Require a class for the associated faction
	var bool bRandomClass; // Require a random soldier class
	var bool bChanceFame; // Roll for a chance to require a famous soldier to staff here
	var bool bReduceRisk; // Filling this staff slot will reduce the overall risks for the covert action
	var int iMinRank; // Require a soldier of this rank or higher in the slot
};

/// <summary>
/// Defines the display info for a single line in the objectives list
/// </summary>
struct native ObjectiveDisplayInfo
{
	var int GroupID, TextPoolIndex, LineIndex;
	var string MissionType;
	var string DisplayLabel; // Label that appears in the objective list
	var bool ShowCompleted;
	var bool ShowFailed;
	var bool ShowCheckBox;
	var bool ShowWarning;
	var bool ShowHeader;
	var bool bIsDarkEvent;
	var int Timer; // timer value to display at the end of this info
	var string CounterHaveImage;
	var string CounterAvailableImage;
	var string CounterLostImage;
	var int CounterHaveAmount;
	var int CounterHaveMin;
	var int CounterAvailableAmount;
	var int CounterLostAmount;
	var bool HideInTactical;
	var bool GPObjective;
	var name ObjectiveTemplateName; // If applicable (Strategy Objectives have templates)

	structdefaultproperties
	{
		GroupID = -1;
		Timer = -1;
		CounterHaveAmount = -1;
		CounterHaveMin = -1;
		CounterAvailableAmount = -1;
		CounterLostAmount = -1;
		ShowHeader = false;
		bIsDarkEvent = false;
	}
};

struct native MinMaxDays
{
	var int MinDays;
	var int MaxDays;
};

// @mnauta temp struct to be replaced
struct native UnitTrait
{
	var name TraitName;
	var name LinkedAbility;
	var string IconPath;
	var string DisplayName;
	var string Description;
	var bool bWeakness;
};

// Deprecated
struct native ChosenProgression
{
	var array<name> ProgressionTemplates;
};

// Deprecated
struct native ChosenData
{
	var name ChosenTemplateName;
	var name ChosenReplacePodTag;
	var name ChosenReinforceTag;
};

struct native ChosenEncounterData
{
	var bool bKilled; // Was the Chosen killed during normal tactical combat
	var bool bDefeated; // Was the Chosen defeated by XCom (permanently killed killed in the Stronghold mission)
	var bool bCapturedSoldier;
	var bool bGainedKnowledge;
	var bool bHeavyLosses; // Did XCOM experience heavy losses during the encounter
	var name MissionSource; // The mission the encounter occurred on
};

struct native ChosenReinforcementGroups
{
	var array<name> GroupNames;
};

struct native ChosenInformation
{
	var array<name> CharTemplates;
	var array<name> SpawningTags;
	var array<ChosenReinforcementGroups> ReinforcementGroups;
};

struct StackedUIIconData
{
	var array<string> Images; //Image at index 2 is the offset images; may contain any number of images in the stack. 
	var bool bInvert; 
};

struct native LastMissionData
{
	var bool bXComWon; // Did XCOM win the mission?
	var bool bLostVeteran; // Was a veteran soldier killed on the mission?
	var bool bChosenEncountered; // Was a Chosen encountered on this mission
	var name MissionSource; // The mission source
	var string MissionFamily; // The mission family
};

//Mission / POI reward handling
//************************************************************

var localized array<string>				MissionDifficultyLabels;

var config string ResistanceLevelBorderPaths[EResistanceLevelType.EnumCount]<BoundEnum = EResistanceLevelType>;
var config string ResistanceLevelInteriorPaths[EResistanceLevelType.EnumCount]<BoundEnum = EResistanceLevelType>;
var config string FullControlBorderPath;
var config string FullControlInteriorPath;
var config string RegionLinkUnlockedPath;
var config string RegionLinkLockedPath;
var config string RegionLinkDashedPath;
var config string HavenMaterialPaths[EResistanceLevelType.EnumCount]<BoundEnum = EResistanceLevelType>;

var config int							MissionAboutToExpireHours;
var config int							MinMissionDifficulty;
var config int							MaxMissionDifficulty;
var config array<int>					CampaignDiffModOnMissionDiff;
var config array<int>					CampaignDiffMaxDiff;
var config int							MaxIntelOptionsPerMission;
var config int							MissionIntelOptionPriceVariance;
//************************************************************

var config int                          m_iMaxSoldiersOnMission;
var config int							VeteranSoldierRank;
var config string                       BiomeMapTexture;
var config array<BiomeMapping>          m_arrBiomeMappings;
var config array<BiomeChance>			m_arrBiomeChances; // for extra biomes, not on the biome texture

var config array<RoomAdjacency>         m_arrRoomAdjacencies;

// Project Scalars
//************************************************************ 
var config array<StrategyCostScalar>	GlobalStrategyCostScalars;
var config array<float>					ResearchProject_TimeScalar;
var config array<float>					BuildItemProject_TimeScalar;
var config array<float>					BuildFacilityProject_TimeScalar;
var config array<float>					UpgradeFacilityProject_TimeScalar;
var config array<float>					ClearRoomProject_TimeScalar;
var config array<float>					ClearRoomProjectFirstRow_TimeScalar;
var config array<float>					HealSoldierProject_TimeScalar;
var config array<int>					ResearchProject_MinInspiredDays;

// Wound Data
//************************************************************
var config array<WoundSeverity>			WoundSeverities;
var config array<WoundHealthPercents>	WoundStates; // In order from least to most severe (used for infirmary UI/bed screens)

var localized array<string>				WoundStatusStrings;

// Covert Action Risk Data
//************************************************************
var config array<int>					RiskThresholds; // In order from least to most probable

var localized array<string>				CovertActionRiskLabels;

// DateTime Handling
//************************************************************
var localized string m_sAM;
var localized string m_sPM;

var localized string m_strMonth0;
var localized string m_strMonth1;
var localized string m_strMonth2;
var localized string m_strMonth3;
var localized string m_strMonth4;
var localized string m_strMonth5;
var localized string m_strMonth6;
var localized string m_strMonth7;
var localized string m_strMonth8;
var localized string m_strMonth9;
var localized string m_strMonth10;
var localized string m_strMonth11;

var localized string m_strMonthDayYearLong;
var localized string m_strMonthDayYearShort;
var localized string m_strDayMonthYearShort;
var localized string m_strDayMonthYearLong;

var localized string m_strYearSuffix;
var localized string m_strMonthSuffix;
var localized string m_strDaySuffix;

var config int START_DAY;
var config int START_MONTH;
var config int START_YEAR;

// Intro movie narrative moment
var config string IntroMovie;

// Soldier Compatibility Values
var config MinMaxFloat VeryLowCompatRange;
var config MinMaxFloat LowCompatRange;
var config MinMaxFloat HighCompatRange;
var config MinMaxFloat VeryHighCompatRange;
var config CompatRollDistribution StandardCompatRoll;
var config CompatRollDistribution ForceLowCompatRoll;
var config CompatRollDistribution FavorLowCompatRoll;
var config CompatRollDistribution ForceHighCompatRoll;
var config CompatRollDistribution FavorHighCompatRoll;
var config array<int> CohesionThresholds;
var config array<int> BondProjectPoints; // Length should match CohesionThresholds
var config array<int> BondWillBonuses; // Length should match CohesionThresholds
var config int MinMissionCohesion;
var config int MaxMissionCohesion;
var config float MinBondedCompatibility;

// Soldier Will values
var config MinMaxDays WillRecoveryDays[EMentalState.EnumCount]<BoundEnum = EMentalState>; // Min and Max Days for recovering to full will from current mental state
var config int MentalStatePercents[EMentalState.EnumCount]<BoundEnum = EMentalState>; // Percent values for mental states of soldier will (add to 100)
var config int MentalStateTraitModifier[EMentalState.EnumCount]<BoundEnum = EMentalState>; // Delta on roll value when testing for negative traits
var config int MaxConcurrentNegativeTraits; // For single soldier, ignored if 0
var config int MaxCampaignNegativeTraits;  // For single soldier, ignored if 0
var config int MaxCampaignPositiveTraits; // For single soldier, ignored if 0
var config int MaxTraitsPerMissionForReadySoldiers;
var config array<int> MaxIncapSoldiersPerMission;
var config array<name> NoLimitIncapSoldiersMissions;

var localized string MentalStateLabels[EMentalState.EnumCount]<BoundEnum = EMentalState>;
var localized string NoCompatLabel;
var localized string VeryLowCompatLabel;
var localized string LowCompatLabel;
var localized string HighCompatLabel;
var localized string VeryHighCompatLabel;
var localized string InvalidCompatLabel;

// Soldier Progression
var config array<int> AbilityPointCosts;
var config int PowerfulAbilityPointCost;
var config array<name> PowerfulAbilities;
var config int ComIntAboveAverageChance;
var config array<int> ComIntThresholds;
var config int BaseSoldierComIntBonuses[ECombatIntelligence.EnumCount]<BoundEnum = ECombatIntelligence>;
var config float ResistanceHeroComIntModifiers[ECombatIntelligence.EnumCount]<BoundEnum = ECombatIntelligence>;

var localized string ComIntLabels[ECombatIntelligence.EnumCount]<BoundEnum = ECombatIntelligence>;

// Will Trait config

// The chance, at X missions completed flawlessly per trait, that the trait will recover
var config array<int> TraitRecoveryChanceSchedule;


struct native TDateTime
{
	var float   m_fTime;
	var int 	m_iDay;
	var int 	m_iMonth;
	var int 	m_iYear;
};

// Store Chosen attack region and duration of attack
struct native RegionAttack
{
	var StateObjectReference RegionRef;
	var TDateTime AttackEndTime;
};

// Nag VO
struct native NagComm
{
	var XComNarrativeMoment NarrativeMoment; // the narrative moment to play
	var int NagDelay; // Hours until the narrative moment plays after the Nag timer is started
	var TDateTime NagTriggerTime;  // When the nag will trigger
};

struct native MissionCalendarDate
{
	var name MissionSource;
	var TDateTime SpawnDate;
	var array<StateObjectReference> Missions;
};

struct native HQOrder
{
	var StateObjectReference OrderRef;
	var TDateTime OrderCompletionTime;
};

struct native X2PhotoboothInfo
{
	var String FilterGroupName;
	var name TemplateName;

	var int NumSoldiers;

	var String LayoutBlueprint;
	var String CameraFocus;
	var array<String> LocationTags;

	var array<String> DefaultPose;

	var array<String> AllowedClasses;
	var array<String> BlockedClasses;

	// Localized text displayed in customization screen
	var localized string DisplayName;

	// Indicates which mod / dlc this belongs to
	var name DLCName;
};

struct native ScanRateMod
{
	var float Modifier;
	var TDateTime ScanRateEndTime;
};

struct native X2TextLayoutInfo
{
	var String FilterGroupName;
	var name TemplateName;

	var int NumTextBoxes;
	var int NumIcons;
	var int LayoutIndex;

	var int LayoutType;

	var array<String> TextBoxMCTags;
	var array<String> IconMCTags;

	var array<int> TextBoxDefaultData;
	var array<int> TextBoxDefaultDataSoldierIndex;
	var array<int> MaxChars;
	var array<int> DefaultFontSize;

	// Localized text displayed in customization screen
	var localized string DisplayName;

	// Indicates which mod / dlc this belongs to
	var name DLCName;
};

// Used by X2SitRepEffect_ModifyMissionMaps
struct MissionMapSwap
{
	var string ToReplace;
	var string ReplaceWith;
};

// Second Wave config
//************************************************************

var config array<WoundHealthPercents>	SecondWaveBetaStrikeHealthWoundStates; // In order from least to most severe (used for infirmary UI/bed screens)

// When 'BetaStrike' second wave option is enabled, maximum unit health for all units 
// (and the healing rate on the Avenger) is multiplied by this amount.
var config float SecondWaveBetaStrikeHealthMod;

////////////////////////////////////////////
// delegates

delegate AlertCallback(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false);

////////////////////////////////////////////
// functions

static function bool IsFirstDay(TDateTime kDateTime)
{
	return kDateTime.m_iMonth == default.START_MONTH && kDateTime.m_iYear == default.START_YEAR && kDateTime.m_iDay == default.START_DAY;
}

static function SetTime( out TDateTime kDateTime, int iHour, int iMinute, int iSecond, int iMonth, int iDay, int iYear )
{
	kDateTime.m_fTime = iSecond + (iMinute*60) + ((iHour*60)*60);
	kDateTime.m_iDay = iDay;
	kDateTime.m_iMonth = iMonth;
	kDateTime.m_iYear = iYear;

	if( kDateTime.m_iMonth > 12 )
	{
		kDateTime.m_iMonth = (kDateTime.m_iMonth%12)+1;
		kDateTime.m_iYear += 1;
	}
}

static function string GetSystemDateTimeString()
{
	local string DateString, TimeString, CombinedString;

	GetSystemDateTimeStrings(DateString, TimeString);

	CombinedString = class'XLocalizedData'.default.DateTimeFormatString;
	CombinedString = Repl(CombinedString, "%DATE", DateString);
	CombinedString = Repl(CombinedString, "%TIME", TimeString);

	return CombinedString;
}

static function GetSystemDateTimeStrings(out string DateString, out string TimeString)
{
	local int Year, Month, DayOfWeek, Day, Hour, Min, Sec, MSec;
	local TDateTime kDateTime;

	`XENGINE.GetSystemTime(Year, Month, DayOfWeek, Day, Hour, Min, Sec, MSec);
	SetTime(kDateTime, Hour, Min, Sec, Month, Day, Year);

	DateString = GetDateString(kDateTime);
	TimeString = GetTimeString(kDateTime);
}

static function CopyDateTime( TDateTime kDateFrom, out TDateTime kDateTo )
{
	SetTime( kDateTo, GetHour(kDateFrom),GetMinute(kDateFrom), GetSecond(kDateFrom), GetMonth(kDateFrom), GetDay(kDateFrom), GetYear(kDateFrom) );
}

static function AddTime( out TDateTime kDateTime, float fSeconds )
{
	local float fDay;

	if (fSeconds < 0)
	{
		RemoveTime(kDateTime, -fSeconds);
		return;
	}

	fDay = 24*60*60;	// Seconds in a day

	kDateTime.m_fTime += fSeconds;

	while( kDateTime.m_fTime >= fDay )
	{
		kDateTime.m_fTime -= fDay;
		AddDay(kDateTime);
	}
}

static function AddHours( out TDateTime kDateTime, int iHours)
{
	local float fSeconds;

	fSeconds = float(iHours * 3600);

	AddTime(kDateTime, fSeconds);
}

static function RemoveTime(out TDateTime kDateTime, float fSeconds )
{
	//  WARNING: This only sets the number of seconds in the day correctly so you can
	//           get the correct hour. The actual day/month/year is NOT adjusted.
	local float fDay;

	fDay = 24*60*60;

	kDateTime.m_fTime -= fSeconds;
	while ( kDateTime.m_fTime < 0 )
	{
		SubtractDay(kDateTime);
		kDateTime.m_fTime += fDay;
	}
}

static function RemoveHours(out TDateTime kDateTime, int iHours)
{
	local float fSeconds;

	fSeconds = float(iHours * 3600);

	RemoveTime(kDateTime, fSeconds);
}

static function SubtractDay(out TDateTime kDateTime)
{
	kDateTime.m_iDay--;

	if(kDateTime.m_iDay <= 0)
	{
		kDateTime.m_iMonth--;

		if(kDateTime.m_iMonth <= 0)
		{
			kDateTime.m_iYear--;
			kDateTime.m_iMonth = 12;
		}

		kDateTime.m_iDay = DaysInMonth(kDateTime.m_iMonth, kDateTime.m_iYear);
	}
}

static function AddDays(out TDateTime kDateTime, int iNumDays )
{
	local int i;

	for( i = 0; i < iNumDays; i++ )
	{
		AddDay(kDateTime);
	}
}

static function AddDay(out TDateTime kDateTime)
{
	kDateTime.m_iDay++;

	if( kDateTime.m_iDay > DaysInMonth(kDateTime.m_iMonth, kDateTime.m_iYear ) )
	{
		AddMonth(kDateTime);
		kDateTime.m_iDay = 1;
	}
}

static function AddMonth(out TDateTime kDateTime)
{
	kDateTime.m_iMonth++;

	if( kDateTime.m_iMonth > 12 )
	{
		AddYear(kDateTime);
		kDateTime.m_iMonth = 1;
	}
}

static protected function AddYear(out TDateTime kDateTime)
{
	kDateTime.m_iYear++;
}

// How many days are in the specified month?
static function int DaysInMonth( int iMonth, int iYear )
{
	if( iMonth == 2 )
	{
		if( (iYear%4) == 0 )	// Leap Year
		{
			return 29;
		}
		else
		{
			return 28;
		}
	}
	else if( iMonth == 9 || iMonth == 4 || iMonth == 6 || iMonth == 11 )
	{
		return 30;
	}
	else
	{
		return 31;
	}
}

// Get the total number of days that have passed since 0 AD
static function int GetTotalDays(TDateTime kDateTime)
{
	local int iDays;
	local int i;

	iDays = ((kDateTime.m_iYear-1) / 4) * 1461; // Leap year blocks we have passed
	iDays += ((kDateTime.m_iYear-1) % 4) * 365; // Days since last leap year

	for( i = 1; i < kDateTime.m_iMonth; i++ )
	{
		iDays += DaysInMonth( i, kDateTime.m_iYear );
	}

	iDays += kDateTime.m_iDay;

	return iDays;
}

static function int DifferenceInYears( TDateTime kDateTime, TDateTime kSubtractThisOne )
{
	local int iDiff;
	iDiff = GetYear(kDateTime) - GetYear(kSubtractThisOne);

	return iDiff;
}

static function int DifferenceInMonths( TDateTime kDateTime, TDateTime kSubtractThisOne )
{
	local int iDiff;
	iDiff = (DifferenceInYears(kDateTime, kSubtractThisOne)*12) + (GetMonth(kDateTime) - GetMonth(kSubtractThisOne));

	return iDiff;
}

static function int DifferenceInDays( TDateTime kDateTime, TDateTime kSubtractThisOne )
{
	local int iDiff;

	if( GetYear(kDateTime) == GetYear(kSubtractThisOne) && GetMonth(kDateTime) == GetMonth(kSubtractThisOne) ) 
	{
		iDiff = GetDay(kDateTime) - GetDay(kSubtractThisOne);
	}
	else
	{
		iDiff = GetTotalDays(kDateTime) - GetTotalDays(kSubtractThisOne);
	}

	return iDiff;
}

static function int DifferenceInHours( TDateTime kDateTime, TDateTime kSubtractThisOne )
{
	local int iDiff;
	
	iDiff = DifferenceInDays(kDateTime, kSubtractThisOne)*24;
	iDiff += GetHour(kDateTime) - GetHour(kSubtractThisOne);

	return iDiff;
}

static function int DifferenceInMinutes( TDateTime kDateTime, TDateTime kSubtractThisOne )
{
	local int iDiff;
	iDiff = (DifferenceInHours(kDateTime, kSubtractThisOne)*60) + (GetMinute(kDateTime) - GetMinute(kSubtractThisOne));
	return iDiff;
}

static function int DifferenceInSeconds( TDateTime kDateTime, TDateTime kSubtractThisOne )
{
	local int iDiff;
	iDiff = (DifferenceInMinutes(kDateTime, kSubtractThisOne)*60) + (GetSecond(kDateTime) - GetSecond(kSubtractThisOne));
	return iDiff;
}

static function bool LessThan( TDateTime kDateTime, TDateTime kDate )
{
	if( GetYear(kDateTime) < GetYear(kDate) )
		return true;
	else if( GetYear(kDateTime) == GetYear(kDate) )
	{
		if( GetMonth(kDateTime) < GetMonth(kDate) )
			return true;
		else if( GetMonth(kDateTime) == GetMonth(kDate) )
		{
			if( GetDay(kDateTime) < GetDay(kDate) )
				return true;
			else if( GetDay(kDateTime) == GetDay(kDate) )
			{
				if( GetHour(kDateTime) < GetHour(kDate) )
					return true;
				else if( GetHour(kDateTime) == GetHour(kDate) )
				{
					if( GetMinute(kDateTime) < GetMinute(kDate) )
						return true;
					else if( GetMinute(kDateTime) == GetMinute(kDate) )
					{
						if( GetSecond(kDateTime) < GetSecond(kDate) )
							return true;
					}
				}
			}
		}   
	}

	return false;
}

static function bool DateEquals( TDateTime kDateTime, TDateTime kDate )
{
	return GetYear(kDateTime) == GetYear(kDate) && GetMonth(kDateTime) == GetMonth(kDate) && GetDay(kDateTime) == GetDay(kDate);
}

static function string GetTimeString(TDateTime kDateTime)
{
	local string strHour, strMinute, strSuffix;

	GetTimeStringSeparated(kDateTime, strHour, strMinute, strSuffix);

	return strHour$":"$strMinute@strSuffix;
}
static function GetTimeStringSeparated(TDateTime kDateTime, out string Hours, out string Minutes, out string Suffix)
{
	local int iHour;
	local string Lang;

	Lang = GetLanguage();
	iHour = GetHour(kDateTime);

	// INT and ESN use the 12 hour clock for events, checked with Loc 12/15/2015. -bsteiner 
	if( Lang == "INT" || Lang == "ESN" )
	{
		// AM
		if( iHour < 12 )
		{
			if( iHour == 0 )
				iHour = 12;

			Suffix = default.m_sAM;
		}
		// PM
		else
		{
			if( iHour > 12 )
				iHour = iHour - 12;

			Suffix = default.m_sPM;
		}
	}
	else 
	{
		//iHour is a 24 hour time. 
		Suffix = "";
	}

	if( GetMinute(kDateTime) < 10 )
	{
		Minutes = "0"$GetMinute(kDateTime);
	}
	else
	{
		Minutes = string(GetMinute(kDateTime));
	}

	Hours = string(iHour);
}

static function string GetDateString(TDateTime kDateTime, optional bool bShortFormat = false)
{
	local XGParamTag kTag;
	local bool bEuroStyleDate;
	local string Lang;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	// this can happen in the editor/PIE
	if( kTag != none )
	{
		kTag.StrValue0 = GetMonthString(,,kDateTime);
		kTag.IntValue0 = kDateTime.m_iDay;
		kTag.IntValue1 = kDateTime.m_iYear;
		kTag.IntValue2 = kDateTime.m_iMonth;

		Lang = GetLanguage();

		kTag.StrValue1 = "/";

		if  ( Lang == "FRA" || Lang == "ITA" || Lang == "ESN")
		{
			bEuroStyleDate = true;
		}

		if (Lang == "DEU" || Lang == "RUS" || Lang == "POL")
		{
			bEuroStyleDate = true;
			kTag.StrValue1 = ".";
		}

		if( Lang == "FRA" && kDateTime.m_iDay == 1 )
		{
			kTag.StrValue2 = "er";
		}
		else if ( Lang == "JPN" || Lang == "KOR" || Lang == "CHN" || Lang == "CHT" )
		{
			kTag.StrValue0 $= default.m_strDaySuffix;
			kTag.StrValue1 = default.m_strMonthSuffix;

			return String(kDateTime.m_iYear) $ default.m_strYearSuffix $ "  " $
				String( kDateTime.m_iMonth ) $ default.m_strMonthSuffix $ "  " $
				String(kDateTime.m_iDay) $ default.m_strDaySuffix;
		}

		if (bEuroStyleDate)
		{
			if (bShortFormat)
			{
				return `XEXPAND.ExpandString( default.m_strDayMonthYearShort );
			}
			else
			{
				return `XEXPAND.ExpandString( default.m_strDayMonthYearLong );
			}
		}
		else
		{
			if (bShortFormat)
			{
				return `XEXPAND.ExpandString( default.m_strMonthDayYearShort );
			}
			else
			{
				return `XEXPAND.ExpandString( default.m_strMonthDayYearLong );
			}
		}
	}
	else
	{
		return string('dateTime');
	}
}

static function string GetMonthString(optional int iMonth = -1, optional bool bCapitalize = false, optional TDateTime kDateTime)
{
	local string strMonth;

	if( iMonth == -1 )
		iMonth = GetMonth(kDateTime);

	switch( iMonth )
	{
	case 1:
		strMonth = default.m_strMonth0;
	break;
	case 2:
		strMonth = default.m_strMonth1;
	break;
	case 3:
		strMonth = default.m_strMonth2;
	break;
	case 4:
		strMonth = default.m_strMonth3;
	break;
	case 5:
		strMonth = default.m_strMonth4;
	break;
	case 6:
		strMonth = default.m_strMonth5;
	break;
	case 7:
		strMonth = default.m_strMonth6;
	break;
	case 8:
		strMonth = default.m_strMonth7;
	break;
	case 9:
		strMonth = default.m_strMonth8;
	break;
	case 10:
		strMonth = default.m_strMonth9;
	break;
	case 11:
		strMonth = default.m_strMonth10;
	break;
	case 12:
		strMonth = default.m_strMonth11;
	break;
	default:
	break;
	}

	if( bCapitalize )
		strMonth = GetMonthStringCapitalized(strMonth);

	return strMonth;
}

static function string GetMonthStringCapitalized (string month)
{
	local string firstChar;
	local string lastChars;

	firstChar = Left(month,1);
	firstChar = Caps(firstChar);

	lastChars = Right(month,Len(month)-1);
	return firstChar$lastChars;
}

static function int GetHour(TDateTime kDateTime)
{
	return ((kDateTime.m_fTime/60)/60);
}

static function int GetMinute(TDateTime kDateTime)
{
	return ((kDateTime.m_fTime%3600)/60);
}

static function int GetSecond(TDateTime kDateTime)
{
	return kDateTime.m_fTime%60;
}

static function int GetYear(TDateTime kDateTime)
{
	return kDateTime.m_iYear;
}

static function int GetMonth(TDateTime kDateTime)
{
	return kDateTime.m_iMonth;
}

static function int GetDay(TDateTime kDateTime)
{
	return kDateTime.m_iDay;
}

// Get the current number of seconds that have passed TODAY
static function float GetTimeInSeconds(TDateTime kDateTime)
{
	return kDateTime.m_fTime;
}
static function GetLocalizedTime( vector2d v2Loc, out TDateTime kDate )
{
	local float fHourStep, fMapWidth, fXDist;
	local int iHourDiff, iXMT;
	
	// Adjustment factor that can be used to tweak the local time
	fMapWidth = 1.0f;

	fHourStep = fMapWidth / 24.0f;

	// Assuming this is GMT
	fXDist = v2Loc.X - fMapWidth/2;

	iXMT = GetXMTHourDiff();
	// IF( This is in the GMT zone )
	if( Abs( fXDist ) < fHourStep/2 )
	{
		iHourDiff = iXMT;
	}
	else
	{
		// IF( This point is EARLIER )
		if( fXDist < 0 )
		{
			// Account for checking from the center of the zone
			fXDist += fHourStep/2;

			iHourDiff = -1 + int(fXDist/fHourStep);
		}
		// ELSE IF( This point is LATER )
		else
		{
			// Account for checking from the center of the zone
			fXDist -= fHourStep/2;

			iHourDiff = 1 + int(fXDist/fHourStep);
		}
		iHourDiff -= iXMT;
	}

	AddTime(kDate, iHourDiff*60*60);

	if( kDate.m_fTime < 0 )
	{
		kDate.m_fTime += 24*60*60;
	}
}

//  Time has always been treated as GMT, but we adjust your base (visually) so that the game start at midnight "GMT" (let's call it XMT)
//  is actually midnight over your home base. Therefore when getting localized time, we need to account for this offset.
//  So if your base is in North America and you try to figure out the time in Kansas, it should wind up the same as XMT, not 6 hours behind.
static function int GetXMTHourDiff()
{
	/*local int iHourDiff; 

	switch (`HQ.GetContinent())
	{
	case eContinent_NorthAmerica:
		iHourDiff = -6;
		break;
	case eContinent_SouthAmerica:
		iHourDiff = -4;
		break;
	case eContinent_Europe:
		iHourDiff = 1;
		break;
	case eContinent_Asia:
		iHourDiff = 8;
		break;
	case eContinent_Africa:
		iHourDiff = 1;
		break;
	}

	return iHourDiff;*/

	return 0;
}

static function ETimeOfDay GetTimeOfDay(TDateTime kDateTime)
{
    local int Hour;

    Hour = GetHour(kDateTime);

    if (Hour > 5 && Hour <= 8)
        return eTimeOfDay_Dawn;
    else if (Hour > 8 && Hour <= 14)
        return eTimeOfDay_Noon;
    else if (Hour > 14 && Hour <= 18)
        return eTimeofDay_Sunset;
    else
        return eTimeOfDay_Night;
}

static function int HoursToDays(int Hours)
{
	local float Days;

	Days = float(Hours)/ 24.0f;

	if(Days > int(Days))
	{
		return int(Days) + 1;
	}
	else
	{
		return int(Days);
	}
}
//************************************************************

static function bool Roll( int iChance )
{
	return `SYNC_RAND_STATIC(100) < iChance;
}

static function int GetMaxSoldiersAllowedOnMission(optional XComGameState_MissionSite MissionSite = none)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local MissionDefinition Mission;
	local X2SitRepEffect_SquadSize SitRepEffect;
	local int MaxSquad;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	if(MissionSite != none)
	{
		Mission = MissionSite.GeneratedMission.Mission;
	}

	if( Mission.MaxSoldiers > 0 )
	{
		MaxSquad = Mission.MaxSoldiers;
	}
	else
	{
		MaxSquad = default.m_iMaxSoldiersOnMission;
		if (History.GetCurrentHistoryIndex() > -1)
		{
			if (XComHQ != none)
			{
				if (XComHQ.SoldierUnlockTemplates.Find('SquadSizeIUnlock') != INDEX_NONE)
					MaxSquad++;
				if (XComHQ.SoldierUnlockTemplates.Find('SquadSizeIIUnlock') != INDEX_NONE)
					MaxSquad++;
			}
			else
			{
				// give both unlock slots in TQL and PIE
				MaxSquad += 2;
			}
		}
	}

	if( XComHQ != None && XComHQ.TacticalGameplayTags.Find('ExtraSoldier_Intel') != INDEX_NONE )
	{
		++MaxSquad;
	}

	// check if we have any sitreps that modify the size of the squad
	if( MissionSite != none )
	{
		foreach class'X2SitRepTemplateManager'.static.IterateEffects(class'X2SitrepEffect_SquadSize', SitRepEffect, MissionSite.GeneratedMission.SitReps)
		{
			if(SitRepEffect.MaxSquadSize > 0)
			{
				MaxSquad = min(MaxSquad, SitRepEffect.MaxSquadSize);
			}

			// add in the relative adjustment value, but make sure we have at least one unit
			MaxSquad = Max(1, MaxSquad + SitRepEffect.SquadSizeAdjustment);
		}
	}

	return MaxSquad;
}

static function bool HasSquadSizeUpgrade()
{
	return GetMaxSoldiersAllowedOnMission() > default.m_iMaxSoldiersOnMission;
}

static function bool IsOnLand(Vector2D Location)
{
	local Object BiomeObject;
	local Texture2D LandMap;
	local Color PixelColor;
	local int MapX, MapY;
	local Vector WorldLocation;
	local Vector2D UVLocation;

	BiomeObject = `CONTENT.RequestGameArchetype(default.BiomeMapTexture);
	if (BiomeObject == none || !BiomeObject.IsA('Texture2D'))
	{
		`RedScreen("Could not load biome texture" @ default.BiomeMapTexture);
		return false;
	}
	LandMap = Texture2D(BiomeObject);

	WorldLocation = class'XComEarth'.static.ConvertEarthToWorld(Location, true);
	UVLocation = class'XComEarth'.static.ConvertWorldToUV(WorldLocation);

	MapX = int(WrapF(UVLocation.X, 0, 1) * float(LandMap.SizeX));
	MapY = int(UVLocation.Y * float(LandMap.SizeY));

	PixelColor = LandMap.GetPixel(MapX, MapY);

	if (PixelColor.r == 255 &&
		PixelColor.g == 255 &&
		PixelColor.b == 255)
		return false;

	return true;
}

static function Vector2D AdjustLocationByRadius(Vector2D Target, float Radius)
{
	local Vector2D NewTarget;
	local int Iterations;

	if (Radius > 0)
	{
		// Calculate the direction to move the target using rands from -1.0 to 1.0
		NewTarget.X = -1.0 + (2.0 * `SYNC_FRAND_STATIC());
		NewTarget.Y = -1.0 + (2.0 * `SYNC_FRAND_STATIC());

		// Normalize the direction
		NewTarget = V2DNormal(NewTarget);

		// Add in the radius distance and offset from the original target position
		NewTarget.X = (NewTarget.X * Radius) + Target.X;
		NewTarget.Y = (NewTarget.Y * Radius) + Target.Y;

		while (!IsOnLand(NewTarget) && Iterations < 500)
		{
			// Calculate the direction to move the target using rands from -1.0 to 1.0
			NewTarget.X = -1.0 + (2.0 * `SYNC_FRAND_STATIC());
			NewTarget.Y = -1.0 + (2.0 * `SYNC_FRAND_STATIC());

			// Normalize the direction
			NewTarget = V2DNormal(NewTarget);

			// Add in the radius distance and offset from the original target position
			NewTarget.X = (NewTarget.X * Radius) + Target.X;
			NewTarget.Y = (NewTarget.Y * Radius) + Target.Y;

			++Iterations;
		}

		return NewTarget;
	}

	return Target;
}

// Method to determine if NewPos is a minimum distance from every item in List
static function bool MinDistanceFromOtherItems(Vector NewPos, array<XComGameState_GeoscapeEntity> Entities, float InDistance)
{
	local int idx;

	if (Entities.Length == 0)
		return true;

	for (idx = 0; idx < Entities.Length; ++idx)
	{
		if (VSize(Entities[idx].Location - NewPos) < InDistance)
		{
			return false;
		}
	}

	return true;
}

static function bool AvoidOverlapWithTooltipBounds(Vector NewPos, array<XComGameState_GeoscapeEntity> Entities, XComGameState_GeoscapeEntity NewEntity)
{
	local XComGameState_Continent ContinentState;
	local Vector2D EntityLoc2D;
	local TRect CheckEntityBounds, NewEntityBounds;
	local int idx;
	
	if (NewEntity != None && NewEntity.HasTooltipBounds())
	{
		// Calculate what the tooltip bounds on the new entity would be if it was placed at this location
		NewEntityBounds = NewEntity.TooltipBounds;
		NewEntityBounds.fLeft += NewPos.X;
		NewEntityBounds.fRight += NewPos.X;
		NewEntityBounds.fTop += NewPos.Y;
		NewEntityBounds.fBottom += NewPos.Y;

		// Add the continent the entity is going to be created on
		ContinentState = NewEntity.GetContinent();
		if (ContinentState != None)
			Entities.AddItem(NewEntity.GetContinent());

		for (idx = 0; idx < Entities.Length; ++idx)
		{
			CheckEntityBounds = Entities[idx].TooltipBounds;
			EntityLoc2D = Entities[idx].Get2DLocation();

			CheckEntityBounds.fLeft += EntityLoc2D.X;
			CheckEntityBounds.fRight += EntityLoc2D.X;
			CheckEntityBounds.fTop += EntityLoc2D.Y;
			CheckEntityBounds.fBottom += EntityLoc2D.Y;

			// Check if the new entity's tooltip bounds would overlap with an existing entity
			if (IsOverlap(CheckEntityBounds, NewEntityBounds))
			{
				return false;
			}
		}
	}

	return true;
}

static function bool IsOverlap(TRect Rect1, TRect Rect2)
{
	if (Rect1.fLeft > Rect2.fRight || Rect2.fLeft > Rect1.fRight)
		return false;

	if (Rect1.fTop > Rect2.fBottom || Rect2.fTop > Rect1.fBottom)
		return false;

	return true;
}

static function string GetBiome(Vector2D Location)
{
	local Object BiomeObject;
	local Texture2D LandMap;
	local Color PixelColor;
	local int MapX, MapY;
	local int idx;
	local Vector WorldLocation;
	local Vector2D UVLocation;

	BiomeObject = `CONTENT.RequestGameArchetype(default.BiomeMapTexture);
	if (BiomeObject == none || !BiomeObject.IsA('Texture2D'))
	{
		`RedScreen("Could not load biome texture" @ default.BiomeMapTexture);
		return "ERROR: COULDN'T FIND BIOME";
	}
	LandMap = Texture2D(BiomeObject);

	WorldLocation = class'XComEarth'.static.ConvertEarthToWorld(Location, true);
	UVLocation = class'XComEarth'.static.ConvertWorldToUV(WorldLocation);

	MapX = int(WrapF(UVLocation.X, 0, 1) * float(LandMap.SizeX));
	MapY = int(UVLocation.Y * float(LandMap.SizeY));

	PixelColor = LandMap.GetPixel(MapX, MapY);

	// default to temperate if we somehow ended up on a white (unused) pixel
	if(PixelColor.r == 255 && PixelColor.g == 255 && PixelColor.b == 255 && PixelColor.a == 255)
	{
		return "Temperate";
	}

	for(idx = 0; idx < default.m_arrBiomeMappings.Length; idx++)
	{
		switch(default.m_arrBiomeMappings[idx].Channel)
		{
		case "r":
			if(PixelColor.r == default.m_arrBiomeMappings[idx].Value)
			{
				return default.m_arrBiomeMappings[idx].BiomeName;
			}
			break;
		case "g":
			if(PixelColor.g == default.m_arrBiomeMappings[idx].Value)
			{
				return default.m_arrBiomeMappings[idx].BiomeName;
			}
			break;
		case "b":
			if(PixelColor.b == default.m_arrBiomeMappings[idx].Value)
			{
				return default.m_arrBiomeMappings[idx].BiomeName;
			}
			break;
		case "a":
			if(PixelColor.a == default.m_arrBiomeMappings[idx].Value)
			{
				return default.m_arrBiomeMappings[idx].BiomeName;
			}
			break;
		default:
			break;
		}
	}

	return "ERROR: COULDN'T FIND BIOME";
}

static function bool AreRoomsAdjacent(XComGameState_HeadquartersRoom Room1, XComGameState_HeadquartersRoom Room2)
{
	local RoomAdjacency RoomAdj;
	local int idx;

	for(idx = 0; idx < default.m_arrRoomAdjacencies.Length; idx++)
	{
		RoomAdj = default.m_arrRoomAdjacencies[idx];

		if(RoomAdj.RoomIndex == Room1.MapIndex)
		{
			break;
		}
	}

	for(idx = 0; idx < RoomAdj.AdjacentRooms.Length; idx++)
	{
		if(RoomAdj.AdjacentRooms[idx] == Room2.MapIndex)
		{
			return true;
		}
	}

	return false;
}

static function CheckForPowerStateChange()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ, NewXComHQ;
	local EPowerState OldPowerState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Handle HQ Power State Change");

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	OldPowerState = XComHQ.PowerState;
	XComHQ.DeterminePowerState();

	if(XComHQ.PowerState != OldPowerState)
	{
		NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		NewXComHQ.DeterminePowerState();
		NewXComHQ.HandlePowerOrStaffingChange(NewGameState);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function UpdateObjectivesUI(XComGameState NewGameState)
{
	local UIAvengerHUD AvengerHUD2D;
	local XComGameState_ObjectivesList ObjectiveList;

	if (`HQGAME == none) // no Avenger hud when we're in tactical
		return;

	AvengerHUD2D = UIAvengerHUD(`HQPRES.ScreenStack.GetScreen(class'UIAvengerHUD'));

	if( AvengerHUD2D != none && AvengerHUD2D.Objectives != none )
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
		{
			break;
		}

		AvengerHUD2D.Objectives.RefreshObjectivesDisplay(ObjectiveList);
	}
}

static function ForceUpdateObjectivesUI()
{
	local XComGameStateHistory History;
	local UIAvengerHUD AvengerHUD2D;
	local XComGameState_ObjectivesList ObjectiveList;

	History = `XCOMHISTORY;
	AvengerHUD2D = UIAvengerHUD(`HQPRES.ScreenStack.GetScreen(class'UIAvengerHUD'));

	if(AvengerHUD2D != none && AvengerHUD2D.Objectives != none)
	{
		foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
		{
			break;
		}

		AvengerHUD2D.Objectives.RefreshObjectivesDisplay(ObjectiveList, true);
	}
}

static function bool ValidQuantityForTradingPost(XComGameState_Item ItemState)
{
	if(ItemState.Quantity <= 0)
	{
		return false;
	}

	if(ItemState.Quantity >= ItemState.GetMyTemplate().TradingPostBatchSize)
	{
		return true;
	}
	
	return false;
}

static function bool ValidQuantityForReverseEngineering(XComGameState_Item ItemState)
{
	if(ItemState.Quantity <= 0)
	{
		return false;
	}

	if(ItemState.Quantity >= ItemState.GetMyTemplate().ReverseEngineeringBatchSize)
	{
		return true;
	}
	
	return false;
}

static function TradingPostTransaction(XComGameState NewGameState, XComGameState_BlackMarket BlackMarketState, XComGameState_Item ItemState, int Price, optional int Quantity = 1)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local bool bNeedToAddHQ;
	local int SupplyAmount;

	History = `XCOMHISTORY;
	
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	bNeedToAddHQ = false;

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		bNeedToAddHQ = true;
	}

	if(XComHQ.RemoveItemFromInventory(NewGameState, ItemState.GetReference(), Quantity) && bNeedToAddHQ)
	{
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	if(ItemState.GetMyTemplate().TradingPostBatchSize > 1)
	{
		SupplyAmount = ((Price * Quantity) / ItemState.GetMyTemplate().TradingPostBatchSize);
	}
	else
	{
		SupplyAmount = (Price * Quantity);
	}

	`XPROFILESETTINGS.Data.m_BlackMarketSuppliesReceived = `XPROFILESETTINGS.Data.m_BlackMarketSuppliesReceived + SupplyAmount;
	XComHQ.AddResource(NewGameState, 'Supplies', SupplyAmount);
	//BlackMarketState.SupplyReserve -= SupplyAmount;
}

static function ReverseEngineeringTransaction(XComGameState_Item ItemState, optional int Quantity = 1)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reverse Engineering Transaction");

	if(XComHQ.RemoveItemFromInventory(NewGameState, ItemState.GetReference(), Quantity))
	{
		NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID);
	}

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	
	if(ItemState.GetMyTemplate().ReverseEngineeringBatchSize > 1)
	{
		XComHQ.AddResourceOrder('Data', (ItemState.GetMyTemplate().ReverseEngineeringValue * Quantity) / ItemState.GetMyTemplate().ReverseEngineeringBatchSize);
	}
	else
	{
		XComHQ.AddResourceOrder('Data', ItemState.GetMyTemplate().ReverseEngineeringValue * Quantity);
	}
	
}



static function name PromoteSoldier(StateObjectReference UnitRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local name SoldierClassName;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));

	if(UnitState != none && !UnitState.IsDead() && UnitState.CanRankUpSoldier())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Soldier Promotion");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		if (UnitState.GetRank() == 0)
		{
			if(XComHQ.GetObjectiveStatus('T0_M2_WelcomeToArmory') == eObjectiveState_InProgress)
			{
				SoldierClassName = XComHQ.SelectNextSoldierClass('Ranger');
			}
			else
			{
				SoldierClassName = XComHQ.SelectNextSoldierClass();
			}
			
		}

		UnitState.RankUpSoldier(NewGameState, SoldierClassName);
		
		if (UnitState.GetRank() == 1)
		{
			UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
			UnitState.ApplyBestGearLoadout(NewGameState); // Make sure the squaddie has the best gear available
		}

		`XEVENTMGR.TriggerEvent('PromotionEvent', UnitState, UnitState, NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`HQPRES.PlayUISound(eSUISound_SoldierPromotion);
	}

	return SoldierClassName;
}

static function bool ShowClassMovie(name SoldierClassName, StateObjectReference SoldierRef, optional bool bNoCallback)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local X2SoldierClassTemplateManager SoldierClassMgr;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local bool MovieShown;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MovieShown = false;

	// First Update Seen Class Movies if necessary (will be needed for campaigns already in progress)
	if(XComHQ.SeenClassMovies.Length == 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Initial Soldier Class Movie Update");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		if(XComHQ.bHasSeenFirstGrenadier)
			XComHQ.SeenClassMovies.AddItem('Grenadier');
		if(XComHQ.bHasSeenFirstPsiOperative)
			XComHQ.SeenClassMovies.AddItem('PsiOperative');
		if(XComHQ.bHasSeenFirstRanger)
			XComHQ.SeenClassMovies.AddItem('Ranger');
		if(XComHQ.bHasSeenFirstSharpshooter)
			XComHQ.SeenClassMovies.AddItem('Sharpshooter');
		if(XComHQ.bHasSeenFirstSpecialist)
			XComHQ.SeenClassMovies.AddItem('Specialist');

		if(XComHQ.SeenClassMovies.Length > 0)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		}
		else
		{
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}

	}

	SoldierClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	SoldierClassTemplate = SoldierClassMgr.FindSoldierClassTemplate(SoldierClassName);

	if(SoldierClassTemplate != none && SoldierClassTemplate.bHasClassMovie && XComHQ.SeenClassMovies.Find(SoldierClassName) == INDEX_NONE)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Soldier Class Movie");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.SeenClassMovies.AddItem(SoldierClassName);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`HQPRES.UISoldierIntroCinematic(SoldierClassName, SoldierRef, bNoCallback);
		MovieShown = true;
	}

	return MovieShown;
}

static function EStaffStatus GetStafferStatus(StaffUnitInfo UnitInfo, optional out string sLocation, optional out int iHours, optional out int iUIState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProject Project;
	local StateObjectReference StaffSlotRef;

	History = `XCOMHISTORY;
	
	if (UnitInfo.bGhostUnit)
	{
		StaffSlotRef = UnitInfo.GhostLocation;
	}
	else
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
		if (UnitState != None)
		{
			StaffSlotRef = UnitState.StaffingSlot;
		}
	}

	if (StaffSlotRef.ObjectID != 0)
	{
		StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID));
		
		foreach History.IterateByClassType(class'XComGameState_HeadquartersProject', Project)
		{
			if (Project.ProjectFocus == UnitInfo.UnitRef || Project.AuxilaryReference == UnitInfo.UnitRef ||
				(Project.AuxilaryReference.ObjectID != 0 && Project.AuxilaryReference == StaffSlot.Room))
			{
				if (UnitInfo.PairUnitRef.ObjectID != 0 && (Project.ProjectFocus == UnitInfo.PairUnitRef || Project.AuxilaryReference == UnitInfo.PairUnitRef))
				{
					iUIState = eUIState_Bad;
					iHours = Project.GetCurrentNumHoursRemaining();
					sLocation = StaffSlot.GetLocationDisplayString();
					return eStaffStatus_Busy;
				}
			}
		}

		if (StaffSlot.AssignedStaff.UnitRef == UnitInfo.UnitRef)
		{
			iUIState = eUIState_Bad;
			iHours = 0;
			sLocation = StaffSlot.GetLocationDisplayString();
			return eStaffStatus_Busy;
		}
	}

	iUIState = eUIState_Good;
	sLocation = "";
	return eStaffStatus_Available;
}

// Set the NagComm's end time based on its delay field, call when condition to be nagged about first occurs
static function StartNagTimer(out NagComm Nag)
{
	Nag.NagTriggerTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	AddHours(Nag.NagTriggerTime, Nag.NagDelay);
}

// Play the nag narrative moment and set nag timer to unreachable future, call in update
static function TriggerNag(out NagComm Nag)
{
	Nag.NagTriggerTime.m_iYear = 9999;
	`HQPRES.UINarrative(Nag.NarrativeMoment);
}

// Set nag end time to unreachable future, call when player has done the thing you were going to nag them about
static function CancelNag(out NagComm Nag)
{
	Nag.NagTriggerTime.m_iYear = 9999;
}

static function int RollForDoomAdded(DoomAddedData DoomData)
{
	local int idx, TotalChance, RolledValue, CurrentValue;

	TotalChance = 0;

	for(idx = 0; idx < DoomData.DoomChances.Length; idx++)
	{
		TotalChance += DoomData.DoomChances[idx].PercentChance;
	}

	RolledValue = `SYNC_RAND_STATIC(TotalChance);
	CurrentValue = 0;

	for(idx = 0; idx < DoomData.DoomChances.Length; idx++)
	{
		if((DoomData.DoomChances[idx].PercentChance + CurrentValue) >= RolledValue)
		{
			return DoomData.DoomChances[idx].DoomToAdd;
		}

		CurrentValue += DoomData.DoomChances[idx].PercentChance;
	}

	// for safety, should not reach
	return DoomData.DoomChances[0].DoomToAdd;
}

static function TDateTime GetDateFromMinMax(TDateTime StartDate, MinMaxDays DaysStruct)
{
	local TDateTime ReturnDate;
	local int HoursToAdd;

	HoursToAdd = (DaysStruct.MinDays*24) + `SYNC_RAND_STATIC((DaysStruct.MaxDays*24) - (DaysStruct.MinDays*24) + 1);
	ReturnDate = StartDate;
	AddHours(ReturnDate, HoursToAdd);

	return ReturnDate;
}

static function float GetFloatFromMinMax(MinMaxFloat FloatStruct)
{
	local float MinMaxDiff;

	MinMaxDiff = FloatStruct.MaxValue - FloatStruct.MinValue;
	return (FloatStruct.MinValue + (MinMaxDiff * `SYNC_FRAND_STATIC()));
}

static function bool IsFloatWithinMinMax(float Value, MinMaxFloat FloatStruct)
{
	return (Value >= FloatStruct.MinValue && Value <= FloatStruct.MaxValue);
}

static function string GetSoldierCompatibilityLabel(float Compat)
{
	local int NumStrLength;
	local float CompatNumber;
	local string Language, CompatLabel; 

	CompatNumber = float(Round(Compat * 50.0f)) / 10.0f;
	NumStrLength = 3;

	if(CompatNumber >= 10.0f)
	{
		NumStrLength = 4;
	}

	if(IsFloatWithinMinMax(Compat, default.VeryLowCompatRange))
	{
		CompatLabel = default.VeryLowCompatLabel @ "(" $ Left(string(CompatNumber), NumStrLength) $ ")";
	}
	else if(IsFloatWithinMinMax(Compat, default.LowCompatRange))
	{
		CompatLabel = default.LowCompatLabel @ "(" $ Left(string(CompatNumber), NumStrLength) $ ")";
	}
	else if(IsFloatWithinMinMax(Compat, default.HighCompatRange))
	{
		CompatLabel = default.HighCompatLabel @ "(" $ Left(string(CompatNumber), NumStrLength) $ ")";
	}
	else if(IsFloatWithinMinMax(Compat, default.VeryHighCompatRange))
	{
		CompatLabel = default.VeryHighCompatLabel @ "(" $ Left(string(CompatNumber), NumStrLength) $ ")";
	}
	else
	{
		CompatLabel = default.NoCompatLabel;
	}

	Language = GetLanguage(); 
	
	switch (Language)
	{
	case "DEU":
	case "FRA":
	case "RUS":
	case "ITA":
	case "POL":
		CompatLabel = Repl(CompatLabel, ".", ","); //Languages use SI-French style fractional delimiter (comma instead of dot).
		break;
	}

	return (CompatLabel == "" ? default.InvalidCompatLabel : CompatLabel);
}

static function float SoldierCompatibilityRoll(optional CompatRollDistribution RollDistribution = default.StandardCompatRoll)
{
	local int TotalWeight, RolledValue, CurrentValue, CurrentIndex;
	local array<int> AllWeights;

	// Get Total Weight
	TotalWeight = RollDistribution.VeryLowWeight + RollDistribution.LowWeight + RollDistribution.HighWeight + RollDistribution.VeryHighWeight;

	// Store All the Weights
	AllWeights.AddItem(RollDistribution.VeryLowWeight);
	AllWeights.AddItem(RollDistribution.LowWeight);
	AllWeights.AddItem(RollDistribution.HighWeight);
	AllWeights.AddItem(RollDistribution.VeryHighWeight);

	// Do the Roll
	RolledValue = `SYNC_RAND_STATIC(TotalWeight);

	// Find what area the roll fell in
	CurrentIndex = 0;
	CurrentValue = AllWeights[CurrentIndex];
	
	while(CurrentIndex < AllWeights.Length && RolledValue > CurrentValue)
	{
		CurrentIndex++;
		CurrentValue += AllWeights[CurrentIndex];
	}

	switch(CurrentIndex)
	{
	case 0:
		return GetFloatFromMinMax(default.VeryLowCompatRange);
	case 1:
		return GetFloatFromMinMax(default.LowCompatRange);
	case 2:
		return GetFloatFromMinMax(default.HighCompatRange);
	case 3:
		return GetFloatFromMinMax(default.VeryHighCompatRange);
	}

	return GetFloatFromMinMax(default.HighCompatRange);
}

static function DetermineSoldierCompatibility(XComGameState_Unit Unit1, XComGameState_Unit Unit2, optional bool bForcePositive = false, optional bool bNextNegative = false, optional bool bNextPositive = false)
{
	local X2SoldierClassTemplate SoldierClass1, SoldierClass2;
	local SoldierBond Bond, PartnerBond;
	local CompatRollDistribution RollDistribution;
	local bool bBond, bPartnerBond;

	if(Unit1 == none || Unit2 == none)
	{
		`Redscreen("DetermineSoldierCompatibility received a null soldier!");
		return;
	}

	if(Unit1.ObjectID == Unit2.ObjectID)
	{
		// we can't have a relationship with ourself
		return;
	}

	SoldierClass1 = Unit1.GetSoldierClassTemplate();
	SoldierClass2 = Unit2.GetSoldierClassTemplate();

	if(SoldierClass1 == none || SoldierClass2 == none)
	{
		// only soldiers may have classes
		return;
	}

	// If forced positive we reroll even if there is already a bond
	if(!bForcePositive)
	{
		// check for existing bonds and fill holes if needed
		bBond = Unit1.GetBondData(Unit2.GetReference(), Bond);
		bPartnerBond = Unit2.GetBondData(Unit1.GetReference(), PartnerBond);
		
		if(bBond && bPartnerBond)
		{
			return;
		}
		else if(bBond && !bPartnerBond)
		{
			PartnerBond = Bond;
			PartnerBond.Bondmate = Unit1.GetReference();
			Unit2.AllSoldierBonds.AddItem(PartnerBond);
			return;
		}
		else if(!bBond && bPartnerBond)
		{
			Bond = PartnerBond;
			Bond.Bondmate = Unit2.GetReference();
			Unit1.AllSoldierBonds.AddItem(Bond);
			return;
		}
	}
	
	if(SoldierClass1.bCanHaveBonds && SoldierClass2.bCanHaveBonds)
	{
		// Check for forced value, if class is favored or not, and then try to alternate positive and negative compatibilities
		if(SoldierClass1.ForcedCompatibiliy > 0.0f)
		{
			Bond.Compatibility = SoldierClass1.ForcedCompatibiliy;
			PartnerBond.Compatibility = Bond.Compatibility;
		}
		else if(SoldierClass2.ForcedCompatibiliy > 0.0f)
		{
			Bond.Compatibility = SoldierClass2.ForcedCompatibiliy;
			PartnerBond.Compatibility = Bond.Compatibility;
		}
		else
		{
			if(SoldierClass1.UnfavoredClasses.Find(SoldierClass2.DataName) != INDEX_NONE ||
				SoldierClass2.UnfavoredClasses.Find(SoldierClass1.DataName) != INDEX_NONE)
			{
				RollDistribution = default.FavorLowCompatRoll;
			}
			else if(SoldierClass1.FavoredClasses.Find(SoldierClass2.DataName) != INDEX_NONE ||
					SoldierClass2.FavoredClasses.Find(SoldierClass1.DataName) != INDEX_NONE)
			{
				RollDistribution = default.FavorHighCompatRoll;
			}
			else if(bNextNegative)
			{
				RollDistribution = default.ForceLowCompatRoll;
			}
			else if(bForcePositive || bNextPositive)
			{
				RollDistribution = default.ForceHighCompatRoll;
			}
			else
			{
				RollDistribution = default.StandardCompatRoll;
			}

			Bond.Compatibility = SoldierCompatibilityRoll(RollDistribution);
			PartnerBond.Compatibility = Bond.Compatibility;
		}
	}
	else
	{
		// If soldier class can't have bonds zero out compatibility (still has entry to appear in lists)
		Bond.Compatibility = 0.0f;
		PartnerBond.Compatibility = Bond.Compatibility;
	}

	// Add the Bonds to the Soldiers' arrays
	Bond.Bondmate = Unit2.GetReference();
	PartnerBond.Bondmate = Unit1.GetReference();
	Unit1.AllSoldierBonds.AddItem(Bond);
	Unit2.AllSoldierBonds.AddItem(PartnerBond);
}

static function OnAddedToCrewSoldierCompatRolls(XComGameState NewGameState, XComGameState_HeadquartersXCom XComHQ, XComGameState_Unit UnitState)
{
	local XComGameState_Unit CrewUnitState;
	local int idx;
	local bool bNextNegative, bNextPositive;

	bNextNegative = false;
	bNextPositive = true;

	// Loop through Crew computing compatibilities
	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		if(XComHQ.Crew[idx] != UnitState.GetReference())
		{
			CrewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', XComHQ.Crew[idx].ObjectID));
			DetermineSoldierCompatibility(UnitState, CrewUnitState, false, bNextNegative, bNextPositive);
			bNextNegative = !bNextNegative;
			bNextPositive = !bNextPositive;
		}
	}
}

static function bool CanHaveBondAtLevel(XComGameState_Unit BondmateA, XComGameState_Unit BondmateB, int BondLevel)
{
	local SoldierBond Bond;
	local StateObjectReference BondedRefA, BondedRefB;
	local bool bAHasBond, bBHasBond;
	local int BondIndex;

	if(BondLevel > 0 && BondLevel < default.CohesionThresholds.Length)
	{
		BondIndex = BondmateA.AllSoldierBonds.Find('Bondmate', BondmateB.GetReference());

		if(BondIndex != INDEX_NONE)
		{
			Bond = BondmateA.AllSoldierBonds[BondIndex];

			// Must only increase by 1 and have reached the cohesion threshold
			if(Bond.BondLevel == (BondLevel - 1) && Bond.Cohesion >= default.CohesionThresholds[BondLevel])
			{
				bAHasBond = BondmateA.HasSoldierBond(BondedRefA);
				bBHasBond = BondmateB.HasSoldierBond(BondedRefB);

				// If setting to 1 neither can have bond yet, if higher they must be bonded to each other already
				return ((BondLevel == 1 && !bAHasBond && !bBHasBond) || (BondLevel > 1 && bAHasBond && bBHasBond && BondedRefA == BondmateB.GetReference()));
			}
		}
	}

	return false;
}

static function SetBondLevel(XComGameState_Unit BondmateA, XComGameState_Unit BondmateB, int BondLevel)
{
	local SoldierBond Bond, PartnerBond;
	local int BondIndex, PartnerBondIndex;

	if(BondLevel > 0 && BondLevel < default.CohesionThresholds.Length)
	{
		// find an existing bond data for these soldiers
		BondIndex = BondmateA.AllSoldierBonds.Find('Bondmate', BondmateB.GetReference());

		// if the bond data doesn't exist, compute our compatibility (this is normal in TQL)
		if(BondIndex < 0)
		{
			DetermineSoldierCompatibility(BondmateA, BondmateB);
			BondIndex = BondmateA.AllSoldierBonds.Find('Bondmate', BondmateB.GetReference());
		}

		PartnerBondIndex = BondmateB.AllSoldierBonds.Find('Bondmate', BondmateA.GetReference());

		// Grab old bond data and adjust bond level
		Bond = BondmateA.AllSoldierBonds[BondIndex];
		PartnerBond = BondmateB.AllSoldierBonds[PartnerBondIndex];
		Bond.BondLevel = BondLevel;
		PartnerBond.BondLevel = BondLevel;

		// If this is the first bond level make sure compatibility is at least a min value
		if(BondLevel == 1 && Bond.Compatibility < default.MinBondedCompatibility)
		{
			Bond.Compatibility = default.MinBondedCompatibility;
			PartnerBond.Compatibility = default.MinBondedCompatibility;
		}

		// Reset the bond availability flag
		Bond.bSoldierBondLevelUpAvailable = false;
		PartnerBond.bSoldierBondLevelUpAvailable = false;

		// Reset the just became available flag
		Bond.bBondJustBecameAvailable = false;
		PartnerBond.bBondJustBecameAvailable = false;
		
		// Update the bond data arrays with the new bond data
		BondmateA.AllSoldierBonds[BondIndex] = Bond;
		BondmateB.AllSoldierBonds[PartnerBondIndex] = PartnerBond;

		// Give each unit an inherent Will bonus
		GiveBondWillBonuses(BondmateA, BondmateB, BondLevel);
	}
}

private static function GiveBondWillBonuses(XComGameState_Unit BondmateA, XComGameState_Unit BondmateB, int BondLevel)
{
	local int WillBonus, NewMaxWill, NewCurrentWill;

	WillBonus = class'X2StrategyGameRulesetDataStructures'.default.BondWillBonuses[BondLevel];
	NewMaxWill = int(BondmateA.GetMaxStat(eStat_Will)) + WillBonus;
	NewCurrentWill = int(BondmateA.GetCurrentStat(eStat_Will)) + WillBonus;
	BondmateA.SetBaseMaxStat(eStat_Will, NewMaxWill);
	BondmateA.SetCurrentStat(eStat_Will, NewCurrentWill);
	NewMaxWill = int(BondmateB.GetMaxStat(eStat_Will)) + WillBonus;
	NewCurrentWill = int(BondmateB.GetCurrentStat(eStat_Will)) + WillBonus;
	BondmateB.SetBaseMaxStat(eStat_Will, NewMaxWill);
	BondmateB.SetCurrentStat(eStat_Will, NewCurrentWill);
}

static function ResetNotBondedSoldierCohesion(XComGameState NewGameState, XComGameState_Unit BondmateA, XComGameState_Unit BondmateB)
{
	local XComGameState_Unit UnitState;
	local SoldierBond BondData;
	local int BondAIndex, BondBIndex, ResetAIndex, ResetBIndex;

	foreach BondmateA.AllSoldierBonds(BondData, BondAIndex)
	{
		// Ignore the bondmates' bond data
		if (BondData.Bondmate.ObjectID != BondmateB.ObjectID)
		{
			// Grab the Unit whose bond data needs to be reset for the bonded pair
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', BondData.Bondmate.ObjectID));
			ResetAIndex = UnitState.AllSoldierBonds.Find('Bondmate', BondmateA.GetReference());
			ResetBIndex = UnitState.AllSoldierBonds.Find('Bondmate', BondmateB.GetReference());

			ResetBondCohesion(UnitState, ResetAIndex); // Save the new bond data for BondmateA
			ResetBondCohesion(BondmateA, BondAIndex); // on both BondmateA and the Reset Unit

			// Find Bondmate B's bond index for the Reset Unit
			BondBIndex = BondmateB.AllSoldierBonds.Find('Bondmate', BondData.Bondmate);
			ResetBondCohesion(UnitState, ResetBIndex); // Save the new bond data for BondmateB
			ResetBondCohesion(BondmateB, BondBIndex); // on both BondmateB and the Reset Unit
		}
	}
}

static function ResetAllBonds(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	local XComGameState_Unit BondUnitState;
	local SoldierBond BondData;
	local int BondIndex, PartnerBondIndex, idx;

	for(idx = 0; idx < UnitState.AllSoldierBonds.Length; idx++)
	{
		BondData = UnitState.AllSoldierBonds[idx];
		BondIndex = idx;
		BondUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', BondData.Bondmate.ObjectID));
		PartnerBondIndex = BondUnitState.AllSoldierBonds.Find('Bondmate', UnitState.GetReference());
		ResetBondCohesion(UnitState, BondIndex, true);
		ResetBondCohesion(BondUnitState, PartnerBondIndex, true);
	}
}

private static function ResetBondCohesion(XComGameState_Unit UnitState, int BondIndex, optional bool bResetBond = false)
{
	local SoldierBond BondData;

	BondData = UnitState.AllSoldierBonds[BondIndex];
	BondData.bSoldierBondLevelUpAvailable = false;
	BondData.bBondJustBecameAvailable = false;
	BondData.Cohesion = 0;
	BondData.MostRecentCohesionGain = 0;

	if(bResetBond)
	{
		BondData.BondLevel = 0;
	}

	UnitState.AllSoldierBonds[BondIndex] = BondData;
}

static function ModifySoldierCohesion(XComGameState_Unit BondmateA, XComGameState_Unit BondmateB, int CohesionDelta, optional bool bUseRawScore = false)
{
	local SoldierBond Bond, PartnerBond;
	local int BondIndex, PartnerBondIndex, ComputedDelta, NewCohesion;

	BondIndex = BondmateA.AllSoldierBonds.Find('Bondmate', BondmateB.GetReference());
	PartnerBondIndex = BondmateB.AllSoldierBonds.Find('Bondmate', BondmateA.GetReference());

	if(BondIndex != INDEX_NONE && PartnerBondIndex != INDEX_NONE)
	{
		// Grab old bond data and old cohesion
		Bond = BondmateA.AllSoldierBonds[BondIndex];
		PartnerBond = BondmateB.AllSoldierBonds[PartnerBondIndex];
		NewCohesion = Bond.Cohesion;

		// Compute actual delta using compatibility score squared
		ComputedDelta = Round(float(CohesionDelta) * (Bond.Compatibility * Bond.Compatibility));

		if(bUseRawScore)
		{
			ComputedDelta = CohesionDelta;
		}

		// Save the most recent cohesion gain, used to display compatibility flyovers on post mission walkup
		Bond.MostRecentCohesionGain = ComputedDelta;
		PartnerBond.MostRecentCohesionGain = ComputedDelta;

		NewCohesion = Clamp((NewCohesion + ComputedDelta), 0, default.CohesionThresholds[Clamp(Bond.BondLevel + 1, 0, default.CohesionThresholds.Length - 1)]);

		// Adjust cohesion
		Bond.Cohesion = NewCohesion;
		PartnerBond.Cohesion = NewCohesion;

		// This bond can level up, so set the bond as available if it isn't already
		if (!Bond.bSoldierBondLevelUpAvailable && (Bond.BondLevel + 1) < default.CohesionThresholds.Length && Bond.Cohesion >= default.CohesionThresholds[Bond.BondLevel+1])
		{
			Bond.bSoldierBondLevelUpAvailable = true;
			Bond.bBondJustBecameAvailable = true;
		}

		// Replace the previous bond entry
		BondmateA.AllSoldierBonds[BondIndex] = Bond;
		BondmateB.AllSoldierBonds[PartnerBondIndex] = PartnerBond;
	}
}

static function array<XComGameState_Unit> GetAllValidSoldierBondsAtLevel(XComGameState_Unit UnitState, int BondLevel)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array <XComGameState_Unit> ValidSoldiers, AllSoldiers;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AllSoldiers = XComHQ.GetSoldiers();
	ValidSoldiers.Length = 0;

	for(idx = 0; idx < AllSoldiers.Length; idx++)
	{
		if(AllSoldiers[idx].ObjectID != UnitState.ObjectID && CanHaveBondAtLevel(UnitState, AllSoldiers[idx], BondLevel))
		{
			ValidSoldiers.AddItem(AllSoldiers[idx]);
		}
	}

	return ValidSoldiers;
}

static function AddCosts(StrategyCost NewCost, out StrategyCost TotalCost)
{
	local ArtifactCost CostItem;
	local bool bCostFound;
	local int idx;

	foreach NewCost.ArtifactCosts(CostItem)
	{
		for(idx = 0; idx < TotalCost.ArtifactCosts.Length; idx++)
		{
			if (CostItem.ItemTemplateName == TotalCost.ArtifactCosts[idx].ItemTemplateName)
			{
				TotalCost.ArtifactCosts[idx].Quantity += CostItem.Quantity;
				bCostFound = true;
			}			
		}

		if (!bCostFound)
		{
			TotalCost.ArtifactCosts.AddItem(CostItem);
		}
	}

	bCostFound = false;
	foreach NewCost.ResourceCosts(CostItem)
	{
		for (idx = 0; idx < TotalCost.ResourceCosts.Length; idx++)
		{
			if (CostItem.ItemTemplateName == TotalCost.ResourceCosts[idx].ItemTemplateName)
			{
				TotalCost.ResourceCosts[idx].Quantity += CostItem.Quantity;
				bCostFound = true;
			}
		}

		if (!bCostFound)
		{
			TotalCost.ResourceCosts.AddItem(CostItem);
		}
	}
}

delegate NarrativeCompleteDelegate();
delegate bool NarrativeRequirementsMet();

delegate bool SpecialRequirementsDelegate();


static function AddDynamicBoolProperty(out DynamicPropertySet PropertySet, Name Key, bool Value)
{
	AddDynamicBoolPropertyToArray(PropertySet.DynamicProperties, Key, Value);
}

static function AddDynamicIntProperty(out DynamicPropertySet PropertySet, Name Key, int Value)
{
	AddDynamicIntPropertyToArray(PropertySet.DynamicProperties, Key, Value);
}

static function AddDynamicFloatProperty(out DynamicPropertySet PropertySet, Name Key, float Value)
{
	AddDynamicFloatPropertyToArray(PropertySet.DynamicProperties, Key, Value);
}

static function AddDynamicNameProperty(out DynamicPropertySet PropertySet, Name Key, Name Value)
{
	AddDynamicNamePropertyToArray(PropertySet.DynamicProperties, Key, Value);
}

static function AddDynamicStringProperty(out DynamicPropertySet PropertySet, Name Key, string Value)
{
	AddDynamicStringPropertyToArray(PropertySet.DynamicProperties, Key, Value);
}

static function AddDynamicVectorProperty(out DynamicPropertySet PropertySet, Name Key, Vector Value)
{
	AddDynamicVectorPropertyToArray(PropertySet.DynamicProperties, Key, Value);
}

static function AddDynamicVector2DProperty(out DynamicPropertySet PropertySet, Name Key, Vector2D Value)
{
	AddDynamicVector2DPropertyToArray(PropertySet.DynamicProperties, Key, Value);
}

static function AddDynamicArrayProperty(out DynamicPropertySet PropertySet, Name Key, const out array<DynamicProperty> Value)
{
	AddDynamicArrayPropertyToArray(PropertySet.DynamicProperties, Key, Value);
}

static function AddDynamicBoolPropertyToArray(out array<DynamicProperty> PropertyArray, Name Key, bool Value)
{
	local DynamicProperty DProp;

	DProp.Key = Key;
	DProp.ValueInt = (Value ? 1 : 0);

	PropertyArray.AddItem(DProp);
}

static function AddDynamicIntPropertyToArray(out array<DynamicProperty> PropertyArray, Name Key, int Value)
{
	local DynamicProperty DProp;

	DProp.Key = Key;
	DProp.ValueInt = Value;

	PropertyArray.AddItem(DProp);
}

static function AddDynamicFloatPropertyToArray(out array<DynamicProperty> PropertyArray, Name Key, float Value)
{
	local DynamicProperty DProp;

	DProp.Key = Key;
	DProp.ValueFloat = Value;

	PropertyArray.AddItem(DProp);
}

static function AddDynamicNamePropertyToArray(out array<DynamicProperty> PropertyArray, Name Key, Name Value)
{
	local DynamicProperty DProp;

	DProp.Key = Key;
	DProp.ValueName = Value;

	PropertyArray.AddItem(DProp);
}

static function AddDynamicStringPropertyToArray(out array<DynamicProperty> PropertyArray, Name Key, string Value)
{
	local DynamicProperty DProp;

	DProp.Key = Key;
	DProp.ValueString = Value;

	PropertyArray.AddItem(DProp);
}

static function AddDynamicVectorPropertyToArray(out array<DynamicProperty> PropertyArray, Name Key, Vector Value)
{
	local DynamicProperty DProp;

	DProp.Key = Key;
	DProp.ValueVector = Value;

	PropertyArray.AddItem(DProp);
}

static function AddDynamicVector2DPropertyToArray(out array<DynamicProperty> PropertyArray, Name Key, Vector2D Value)
{
	local DynamicProperty DProp;

	DProp.Key = Key;
	DProp.ValueVector.X = Value.X;
	DProp.ValueVector.Y = Value.Y;

	PropertyArray.AddItem(DProp);
}

static function AddDynamicArrayPropertyToArray(out array<DynamicProperty> PropertyArray, Name Key, const out array<DynamicProperty> Value)
{
	local DynamicProperty DProp;

	DProp.Key = Key;
	DProp.ValueArray = Value;

	PropertyArray.AddItem(DProp);
}


static native function bool GetDynamicBoolPropertyFromArray(const out array<DynamicProperty> PropertyArray, Name Key);
static native function int GetDynamicIntPropertyFromArray(const out array<DynamicProperty> PropertyArray, Name Key);
static native function float GetDynamicFloatPropertyFromArray(const out array<DynamicProperty> PropertyArray, Name Key);
static native function Name GetDynamicNamePropertyFromArray(const out array<DynamicProperty> PropertyArray, Name Key);
static native function String GetDynamicStringPropertyFromArray(const out array<DynamicProperty> PropertyArray, Name Key);
static native function Vector GetDynamicVectorPropertyFromArray(const out array<DynamicProperty> PropertyArray, Name Key);
static native function Vector2D GetDynamicVector2DPropertyFromArray(const out array<DynamicProperty> PropertyArray, Name Key);
static native function GetDynamicArrayPropertyFromArray(const out array<DynamicProperty> PropertyArray, Name Key, out array<DynamicProperty> Value);

static native function bool GetDynamicBoolProperty(const out DynamicPropertySet PropertySet, Name Key);
static native function int GetDynamicIntProperty(const out DynamicPropertySet PropertySet, Name Key);
static native function float GetDynamicFloatProperty(const out DynamicPropertySet PropertySet, Name Key);
static native function Name GetDynamicNameProperty(const out DynamicPropertySet PropertySet, Name Key);
static native function String GetDynamicStringProperty(const out DynamicPropertySet PropertySet, Name Key);
static native function Vector GetDynamicVectorProperty(const out DynamicPropertySet PropertySet, Name Key);
static native function Vector2D GetDynamicVector2DProperty(const out DynamicPropertySet PropertySet, Name Key);
static native function GetDynamicArrayProperty(const out DynamicPropertySet PropertySet, Name Key, out array<DynamicProperty> Value);

//native function Name GetCallbackFunctionName(delegate<AlertCallback> CallbackFunction);
//native function SetCallbackDelegate(delegate<AlertCallback> CallbackFunction, Name CallbackFunctionName);

static function BuildDynamicPropertySet(
	out DynamicPropertySet PropertySet, 
	Name PrimaryKey, 
	Name SecondaryKey, 
	delegate<AlertCallback> CallbackFunction, 
	bool bDisplayImmediate,
	bool bDisplayOnAvengerSideViewIdle,
	bool bDisplayOnGeoscapeIdle,
	bool bDisplayInTacticalIdle )
{
	PropertySet.PrimaryRoutingKey = PrimaryKey;
	PropertySet.SecondaryRoutingKey = SecondaryKey;
	PropertySet.CallbackFunction = CallbackFunction;
	PropertySet.bDisplayImmediate = bDisplayImmediate;
	PropertySet.bDisplayOnAvengerSideViewIdle = bDisplayOnAvengerSideViewIdle;
	PropertySet.bDisplayOnGeoscapeIdle = bDisplayOnGeoscapeIdle;
	PropertySet.bDisplayInTacticalIdle = bDisplayInTacticalIdle;
}


static function AddDynamicStaffUnitInfoProperties(out array<DynamicProperty> DynamicProperties, const out StaffUnitInfo UnitInfo)
{
	local DynamicProperty DProp;

	DProp.Key = 'bGhostUnit';
	DProp.ValueInt = (UnitInfo.bGhostUnit ? 1 : 0);

	DynamicProperties.AddItem(DProp);

	DProp.Key = 'UnitRef';
	DProp.ValueInt = UnitInfo.UnitRef.ObjectID;

	DynamicProperties.AddItem(DProp);

	DProp.Key = 'StaffSlotRef';
	DProp.ValueInt = UnitInfo.GhostLocation.ObjectID;

	DynamicProperties.AddItem(DProp);
}

static function GetDynamicStaffUnitInfoProperties(const out array<DynamicProperty> DynamicProperties, out StaffUnitInfo UnitInfo)
{
	UnitInfo.bGhostUnit = GetDynamicBoolPropertyFromArray(DynamicProperties, 'bGhostUnit');
	UnitInfo.UnitRef.ObjectID = GetDynamicIntPropertyFromArray(DynamicProperties, 'UnitRef');
	UnitInfo.GhostLocation.ObjectID = GetDynamicIntPropertyFromArray(DynamicProperties, 'StaffSlotRef');
}


DefaultProperties
{
}
