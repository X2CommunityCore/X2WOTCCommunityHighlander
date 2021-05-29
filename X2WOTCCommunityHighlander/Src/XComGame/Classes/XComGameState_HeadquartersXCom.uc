//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersXCom.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for X-Com's HQ in the 
//           X-Com 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersXCom extends XComGameState_Airship 
	native(Core) 
	config(GameData)
	DependsOn(XGMissionControlUI, XComGameState_ObjectivesList);

// Since unreal script doesn't support nested arrays, we need a wrapper for the "AllSquads"
// array. Reserve squads exist to allow different squads to exist on different legs
// of a mission. While we will always default to setting the main Squad array to
// AllSquads[0], we also allow X2MissionTemplates to build custom squads
// based on whatever combination of the reserve squads that were chosen in strategy by the user.
struct native ReserveSquad
{
	var array<StateObjectReference> SquadMembers;
};

struct native PendingFacilityDiscount
{
	var name TemplateName;
	var int DiscountPercent;
};

// Ship State Vars
var() StateObjectReference          StartingRegion;//Region in which the X-Com HQ started
var() StateObjectReference			CurrentLocation; // Geoscape entity where the Avenger is currently located or scanning
var() StateObjectReference			StartingHaven;
var() StateObjectReference			SavedLocation; // Used during UFO attacks to store where the Avenger was located

// Base Vars and Lists
var() array<StateObjectReference>		Rooms; //List of rooms within the X-Com HQ.
var() array<StateObjectReference>		Facilities; //Facilities in the HQ
var() privatewrite array<StateObjectReference> Crew;	//All Avenger crew members, including soldiers. Gameplay-important crew - ie. engineers, scientists, soldiers
var() privatewrite array<StateObjectReference> Clerks;	//Cosmetic crew members who are populated into rooms when the rooms are staffed.
var() array<StateObjectReference>		DeadCrew;   //The fallen. *gentle weeping*
var() array<StateObjectReference>		TechsResearched; // All Techs that have been researched by XCom
var() array<StateObjectReference>		Inventory; // XCom Item and Resource inventory
var() array<StateObjectReference>		LootRecovered;
var() array<StateObjectReference>		Projects; // All Headquarters projects (tech, item, facility, repair, etc.)
var() array<StateObjectReference>		Squad; // The soldiers currently selected to go on the current mission
var() array<ReserveSquad>               AllSquads; // An array of squads selected in strategy by the user. X2MissionTemplates are free to build the Squad array from any combination of these soldiers.
var() array<name>						SoldierClassDeck;   //Soldier classes to randomly pick from when a soldier ranks up.
var() array<SoldierClassCount>			SoldierClassDistribution;
var() array<StateObjectReference>		MalfunctionFacilities;
var() protectedwrite array<name>		SoldierUnlockTemplates;  //  Purchased unlocks
var() protectedwrite array<name>		SavedSoldierUnlockTemplates; // The list of purchased unlocks which is saved if the GTS is deleted
var() StateObjectReference				SkyrangerRef; // The drop ship
var() array<name>						UnlockedItems; // Blocked items that are available for build now
var() int								HighestSoldierRank;
var() int								AverageSoldierFame;
var() array<HQOrder>					CurrentOrders; // Personnel on order to be delivered to HQ

var() array<Name>						EverAcquiredInventoryTypes; // list (and counts) of all inventory ever acquired by the hq
var() array<int>						EverAcquiredInventoryCounts; // list (and counts) of all inventory ever acquired by the hq

// Generic String to Int mapping used by kismet actions to store persistent data
var native Map_Mirror GenericKVP { TMap<FString, INT> };

struct native AmbientNarrativeInfo
{
	var string QualifiedName;
	var int PlayCount;
};

var() array<AmbientNarrativeInfo>    PlayedAmbientNarrativeMoments;  // used for track which ambient narrative moments we've played
var() array<AmbientNarrativeInfo>	 PlayedLootNarrativeMoments; // used for recovered items
var() array<AmbientNarrativeInfo>	 PlayedArmorIntroNarrativeMoments; // used for armor intros
var() array<AmbientNarrativeInfo>	 PlayedEquipItemNarrativeMoments; // used for equipping items
var() array<name>					 PlayedAmbientSpeakers; // used to track speakers which have limits on the number of moments they can play

var() array<string>	PlayedTacticalNarrativeMomentsCurrentMapOnly;

// The Geoscape Entity that the user has selected as their target.
var StateObjectReference			SelectedDestination;
var StateObjectReference			CrossContinentMission; // Store the mission if clicked on from different continent


// Mission Data
var() array<GeneratedMissionData>   arrGeneratedMissionData;    //  When a mission is selected in the UI, its generated data is stored here to live through squad selection etc.

var() array<Name>					TacticalGameplayTags;	// A list of Tags representing modifiers to the tactical game rules

// Power Vars
var() EPowerState                   PowerState; // Power state affects how some facilities function

// Healing Vars
var() int							HealingRate;

// Proving Ground Vars
var() int							ProvingGroundRate;

// Psi Chamber Vars
var() int							PsiTrainingRate;

// Construction Vars
var() int							ConstructionRate;

// Movie Flags
var() bool                          bDontShowSetupMovies;       // flag for setup phase movies
var() bool                          bHasVisitedEngineering; // flag for playing movie
var() bool                          bHasVisitedLabs;        // flag for playing movie
var() bool                          bJustWentOnFirstMission; // flag for playing movie
var() bool							bHasSeenFirstGrenadier;
var() bool							bHasSeenFirstPsiOperative;
var() bool							bHasSeenFirstRanger;
var() bool							bHasSeenFirstSharpshooter;
var() bool							bHasSeenFirstSpecialist;
var() bool							bHasSeenWelcomeResistance;
var() bool							bNeedsToSeeFinalMission;
var() array<name>					SeenCharacterTemplates;	//This list contains a list of character template groups that X-Com has seen during their campaign
var() array<name>					RequiredSpawnGroups;	//This list contains a list of character template groups that X-Com must spawn for Objective reasons

var() array<name>					SeenClassMovies; // Better system than individual flags, to support DLC/Mod classes

var() bool							bTutorial;
var() bool							bHasPlayedAmbushTutorial;
var() bool							bHasPlayedMeleeTutorial;
var() bool							bHasPlayedNeutralizeTargetTutorial;
var() bool							bBlockObjectiveDisplay;

// info for popups that must be played once returning to the avenger after the completion of a mission
var() array<DynamicPropertySet>		QueuedDynamicPopups;

// UFO Chase
var() bool							bUFOChaseInProgress;
var() int							UFOChaseLocationsCompleted;
var() StateObjectReference			AttackingUFO;

// Popup flags
var() bool							bReturningFromMission;
var() bool							bHasSeenWeaponUpgradesPopup;
var() bool							bHasSeenCustomizationsPopup;
var() bool							bHasSeenReinforcedUnderlayPopup;
var() bool							bHasSeenPsiLabIntroPopup;
var() bool							bHasSeenPsiOperativeIntroPopup;
var() bool							bHasSeenTrainingCenterIntroPopup;
var() bool							bHasSeenInfirmaryIntroPopup;
var() bool							bHasSeenBuildTheRingPopup;
var() bool							bHasSeenLowIntelPopup;
var() bool							bHasSeenLowSuppliesPopup;
var() bool							bHasSeenLowScientistsPopup;
var() bool							bHasSeenLowEngineersPopup;
var() bool							bHasSeenSupplyDropReminder;
var() bool							bHasSeenRingAvailablePopup;
var() bool							bHasSeenPowerCoilShieldedPopup;
var() bool							bHasSeenHeroPromotionScreen;
var() bool							bHasSeenCombatIntelligenceIntroPopup;
var() bool							bHasSeenTiredSoldierPopup;
var() bool							bHasSeenShakenSoldierPopup;
var() bool							bHasSeenSitrepIntroPopup;
var() bool							bHasSeenSoldierCompatibilityIntroPopup;
var() bool							bHasSeenResistanceOrdersIntroPopup;
var() bool							bHasSeenCovertActionIntroPopup;
var() bool							bHasSeenCovertActionRiskIntroPopup;
var() bool							bHasReceivedResistanceOrderPopup;
var() bool							bHasSeenCantChangeOrdersPopup;
var() bool							bHasSeenSoldierBondPopup;
var() bool							bHasSeenNegativeTraitPopup;

// Tactical Tutorial Flags
var() bool							bHasSeenTacticalTutorialSoldierBonds;
var() bool							bHasSeenTacticalTutorialDazed;
var() bool							bHasSeenTacticalTutorialTargetPreview;
var() bool							bHasSeenTacticalTutorialTrackingShot;
var() bool							bHasSeenTacticalTutorialReaper;
var() bool							bHasSeenTacticalTutorialTemplar;
var() bool							bHasSeenTacticalTutorialTemplarMomentum;
var() bool							bHasSeenTacticalTutorialSkirmisher;

// Upgrade Vars
var() bool                          bSurgeProtection;
var() int                           SurgeProtectionReduction;
var() bool                          bModularWeapons;
var() bool							bReinforcedUnderlay;
var() bool							bPsiSoldiers;

// Region Bonus Flags
var() bool							bQuickStudy;
var() bool							bCrunchTime;
var() bool							bIntoTheShadows;
var() bool							bSpreadTheWord;
var() bool							bConfoundTheEnemy;
var() bool							bScavengers;

// To Do Widget Warnings
var() bool							bPlayedWarningNoResearch;
var() bool							bPlayedWarningUnstaffedEngineer;
var() bool							bPlayedWarningUnstaffedScientist;
var() bool							bPlayedWarningNoIncome;
var() bool							bPlayedWarningNoRing;
var() bool							bPlayedWarningNoCovertAction;

// Modifiers
var int								ResearchEffectivenessPercentIncrease; // PursuitOfKnowledge Continent Bonus
var int								EngineeringEffectivenessPercentIncrease; // HigherLearning Continent Bonus
var int								ProvingGroundPercentDiscount;
var int								GTSPercentDiscount;
var int								PowerOutputBonus; // HiddenReserves Continent Bonus
var bool							bLabBonus; // PursuitOfKnowledge Continent Bonus
var bool							bInstantAutopsies; // Xenobiology Continent Bonus
var bool							bInstantArmors; // SuitUp Continent Bonus
var bool							bInstantRandomAmmo;
var bool							bInstantRandomGrenades;
var bool							bInstantRandomHeavyWeapons;
var bool							bReducedContact; // From POI Reward
var float							ReducedContactModifier; // From POI Reward - Percentage cost decreased
var bool							bFreeContact; // SignalFlare Continent Bonus
var bool							bUsedFreeContact; // if false allows player to use free contact on signal flare deactivation->reactivation
var bool							bInstantContacts; // Resistance Order: Resistance Network
var bool							bExtraEngineer; // HelpingHand Continent Bonus
var bool							bReuseUpgrades; // From Breakthrough tech
var bool							bReusePCS; // From Breakthrough tech
var bool							bExtraWeaponUpgrade; // ArmedToTheTeeth ContinentBonus
var bool							bEmpoweredUpgrades; // Resistance Order: Inside Knowledge
var int								BonusScienceScore;
var int								BonusEngineeringScore;
var int								BonusPowerProduced;
var int								BonusCommCapacity;
var bool							bInstantSingleExcavation;
var bool							bAllowLightlyWoundedOnMissions; // Resistance Order: Greater Resolve
var array<PendingFacilityDiscount>	PendingFacilityDiscounts;

// scanning modifier
var float							CurrentScanRate; // how fast the Avenger scans, with a default of 1.0
var array<ScanRateMod>				ScanRateMods;

// Staff XP Timer
var TDateTime						StaffXPIntervalEndTime;
var TDateTime						LowScientistPopupTime;
var TDateTime						LowEngineerPopupTime;

// FLAG OF ULTIMATE VICTORY
var() bool							bXComFullGameVictory;

// Timed Loot Weight
var float							AdventLootWeight;
var float							AlienLootWeight;

// Reference to a new staff members that we are currently waiting for a photograph of
var private array<StateObjectReference>   NewStaffRefs;

// The region name of the next lead available to be acquired
var Name NextAvailableFacilityLeadRegion;

// Tutorial Soldier
var StateObjectReference TutorialSoldier;

var() StateObjectReference MissionRef;
var() bool bSimCombatVictory;
var LastMissionData LastMission;

// Landing site map
var string LandingSiteMap;

// XPack Variables
var bool							bWaitingForChosenAmbush;
var bool							bCanCureNegativeTraits;
var float							BonusKillXP; // Some Strategy Cards give 'Wetwork' style bonus xp
var float							BonusPOIScalar; // Bonus to POI rewards from Strategy Cards, does nothing if 0
var int								BonusTrainingRanks; // GTS trainees gain these additional ranks (from Strategy Card)
var float							BonusAbilityPointScalar; // Bonus to Ability Points granted in tactical
var float							ChosenKnowledgeGainScalar; // Modifier to amount of knowledge gained by Chosen in tactical
var bool							bSoldierEverGainedNegativeTrait; // Track if a soldier has ever gained a negative trait this campaign
var int								MissionsSinceTraitGained; // Tracking for missions between negative traits being gained
var int								NumChosenRetributions; // The number of times Chosen have used Retribution

// Breakthrough Tech Data
var array<name>						ExtraUpgradeWeaponCats;
var array<StateObjectReference>		TacticalTechBreakthroughs;

var TDateTime						InspiredTechTimer;
var TDateTime						BreakthroughTechTimer;
var StateObjectReference			CurrentInspiredTech;
var StateObjectReference			CurrentBreakthroughTech;
var array<StateObjectReference>		IgnoredBreakthroughTechs;
var float							BreakthroughTimerModifier;
var int								SabotageChanceModifier; // Defense Matrix increases resistance to sabotage

// Localized strings
var localized string strETAInstant;
var localized string strETADay;
var localized string strETADays;
var localized string strErrInsufficientData;
var localized string strCostLabel;
var localized string strCostData;
var localized string strNoScientists;
var localized string strStaffArrived;

// Event Strings
var localized string ProjectPausedLabel;
var localized string ResearchEventLabel;
var localized string ItemEventLabel;
var localized string ProvingGroundEventLabel;
var localized string FacilityEventLabel;
var localized string UpgradeEventLabel;
var localized string PsiTrainingEventLabel;
var localized string SupplyDropEventLabel;
var localized string ShadowEventLabel;
var localized string MakingContactEventLabel;
var localized string BuildingHavenEventLabel;
var localized string StaffOrderEventLabel;
var localized string TrainRookieEventLabel;
var localized string RespecSoldierEventLabel;
var localized string RemoveTraitsEventLabel;
var localized string BondSoldiersEventLabel;
var localized string CovertActionsGoToRing;
var localized string CovertActionsSelectOp;
var localized string CovertActionsBuildRing;

// Tutorial Strings
var localized string DeadTutorialSoldier1CauseOfDeath;
var localized string DeadTutorialSoldier1Epitaph;
var localized string DeadTutorialSoldier2CauseOfDeath;
var localized string DeadTutorialSoldier2Epitaph;


// Config Vars
var config ECharacterPoolSelectionMode InitialSoldiersCharacterPoolSelectionMode;
var config ECharacterPoolSelectionMode RewardUnitCharacterPoolSelectionMode;
var config int XComHeadquarters_NumToRemoveFromSoldierDeck;
var config int XComHeadquarters_NumRooms;
var config int XComHeadquarters_RoomRowLength;
var config int XComHeadquarters_MinGridIndex;
var config int XComHeadquarters_MaxGridIndex;
var config Vector XComHeadquarters_RoomUIOffset;

var config int NumClerks_ActOne;
var config int NumClerks_ActTwo;
var config int NumClerks_ActThree;

var config array<int> XComHeadquarters_StartingValueSupplies;
var config array<int> XComHeadquarters_StartingValueIntel;
var config array<int> XComHeadquarters_StartingValueAlienAlloys;
var config array<int> XComHeadquarters_StartingValueEleriumCrystals;
var config array<int> XComHeadquarters_StartingValueAbilityPoints;

var config array<int> XComHeadquarters_BaseHealRates; // Not difficulty adjusted, Wound times adjusted instead

var config array<int> XComHeadquarters_ShakenChance;
var config array<int> XComHeadquarters_ShakenRecoverMissionsRequired;
var config int XComHeadquarters_ShakenRecoverWillBonus;
var config int XComHeadquarters_ShakenRecoverWillRandBonus;

var config float XComHeadquarters_YellowPowerStatePercent;
var config int XComHeadquarters_SoldierWarningNumber;

var config int XComHeadquarters_DefaultConstructionWorkPerHour;
var config int XComHeadquarters_DefaultProvingGroundWorkPerHour;
var config int XComHeadquarters_DefaultPsiTrainingWorkPerHour;
var config array<int> XComHeadquarters_DefaultTrainRookieDays;
var config array<int> XComHeadquarters_DefaultRespecSoldierDays;
var config array<int> XComHeadquarters_DefaultBondSoldiersDays;
var config array<int> XComHeadquarters_DefaultRemoveTraitDays;
var config array<int> XComHeadquarters_PsiTrainingDays;
var config array<float> PsiTrainingRankScalar;

var config int XComHeadquarters_StartingScienceScore;
var config int XComHeadquarters_StartingEngineeringScore;
var config array<int> XComHeadquarters_StartingPowerProduced; // Changes based on difficulty might be better in powercore template
var config array<int> XComHeadquarters_StartingCommCapacity;
var config int XComHeadquarters_NumAWCAbilities; // Number of abilities soldiers can buy through the Training Center
var config int XComHeadquarters_MinAWCTalentRank; // Min eligible rank for a hidden talent to be placed (not grabbed from)
var config int XComHeadquarters_MaxAWCTalentRank; // Max eligible rank for a hidden talent to be placed (not grabbed from)

var config int UFOChaseLocations;
var config int UFOChaseChanceToSwitchContinent;

var config array<int> ResearchProgressDays_Fast;
var config array<int> ResearchProgressDays_Normal;
var config array<int> ResearchProgressDays_Slow;

var config array<int> StartingRegionSupplyDrop;
var config int MaxSoldierClassDifference;

var config int TimedLootPerMission;
var config float StartingAdventLootWeight;
var config float StartingAlienLootWeight;
var config float LootWeightIncrease;

var config array<int> PowerRelayOnCoilBonus;

var config array<float> StartingScientistMinCap;
var config array<float> ScientistMinCapIncrease;
var config array<float> StartingScientistMaxCap;
var config array<float> ScientistMaxCapIncrease;
var config array<int> ScientistNeverWarnThreshold; // never warn the player if they have this many scientists

var config array<float> StartingEngineerMinCap;
var config array<float> EngineerMinCapIncrease;
var config array<float> StartingEngineerMaxCap;
var config array<float> EngineerMaxCapIncrease;
var config array<int> EngineerNeverWarnThreshold; // never warn the player if they have this many engineers

var config int LowScientistPopupDays;
var config int LowEngineerPopupDays;

// Cost Scalars
var config array<StrategyCostScalar> RoomSpecialFeatureCostScalars;
var config array<StrategyCostScalar> FacilityBuildCostScalars;
var config array<StrategyCostScalar> FacilityUpgradeCostScalars;
var config array<StrategyCostScalar> ResearchCostScalars;
var config array<StrategyCostScalar> ProvingGroundCostScalars;
var config array<StrategyCostScalar> ItemBuildCostScalars;
var config array<StrategyCostScalar> OTSUnlockScalars;
var config array<StrategyCostScalar> MissionOptionScalars;

var config string ShakenIcon;

var config array<name> PossibleStartingRegions; // List of all possible starting regions
var config array<name> ResourceItems; // List of items which are resources and should never be removed from the inventory

// Tutorial Stuff
// Jane Kelly
var config EGender TutorialSoldierGender;
var config name TutorialSoldierCountry;
var config TAppearance TutorialSoldierAppearance;
var config name TutorialSoldierEnglishVoice;
var config name TutorialSoldierFrenchVoice;
var config name TutorialSoldierGermanVoice;
var config name TutorialSoldierItalianVoice;
var config name TutorialSoldierSpanishVoice;

// Peter Osei
var config EGender DeadTutorialSoldier1Gender;
var config name DeadTutorialSoldier1Country;
var config TAppearance DeadTutorialSoldier1Appearance;
var config int DeadTutorialSoldier1NumKills;

// Ana Ramirez
var config EGender DeadTutorialSoldier2Gender;
var config name DeadTutorialSoldier2Country;
var config TAppearance DeadTutorialSoldier2Appearance;
var config int DeadTutorialSoldier2NumKills;

var config array<name> TutorialExcludeSpecialRoomFeatures;
var config Vector TutorialStartingLocation; // Ghat Mountains in India
var config int TutorialExcavateIndex;
var config name TutorialFinishedObjective;
var config array<name> TutorialStartingItems; // You pick up a scope in the tutorial


// XPack Config Values
var config array<int> MaxInspiredTechTimerHours; // Maximum number of hours between research inspirations
var config array<int> StartingBreakthroughTechTimerHours; // Maximum number of hours between research breakthroughs at the start of the game
var config array<int> MaxBreakthroughTechTimerHours; // Maximum number of hours between research breakthroughs
var config float MaxInspiredTechTimeReduction;
var config float MinInspiredTechTimeReduction;
var config float BreakthroughLaboratoryModifier;
var config float BreakthroughResistanceOrderModifier;
var config int MinMissionsBetweenTraits;

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SetUpHeadquarters(XComGameState StartState, optional bool bTutorialEnabled = false, optional bool bXPackNarrativeEnabled = false)
{	
	local int Index, i;
	local XComGameState_HeadquartersXCom HeadquartersStateObject;
	local XComGameState_HeadquartersRoom RoomStateObject;
	local array<XComGameState_HeadquartersRoom> LocalRooms;
	local X2FacilityTemplate FacilityTemplate;
	local array<X2StrategyElementTemplate> AllFacilityTemplates;
	local XComGameState_FacilityXCom FacilityStateObject;
	local XComGameState_GameTime TimeState;
	local XComGameState_Skyranger SkyrangerState;
	local XComGameState_Continent ContinentState;
	local XComGameState_Haven HavenState;
	local XComGameState_HeadquartersResistance ResHQ;
	
	//HQ location selection
	local int RandomIndex;
	local XComGameState_WorldRegion IterateRegion;
	local array<XComGameState_WorldRegion> AllStartingRegions, BestStartingRegions;
	local XComGameState_WorldRegion BaseRegion;
	local Vector ResHQLoc;

	//Create the HQ state object
	HeadquartersStateObject = XComGameState_HeadquartersXCom(StartState.CreateNewStateObject(class'XComGameState_HeadquartersXCom'));

	HeadquartersStateObject.bTutorial = bTutorialEnabled;
	if (!HeadquartersStateObject.bTutorial)
	{
		HeadquartersStateObject.bHasPlayedAmbushTutorial = true;
		HeadquartersStateObject.bHasPlayedMeleeTutorial = true;
		HeadquartersStateObject.bHasSeenPowerCoilShieldedPopup = true;
	}
	else
	{
		HeadquartersStateObject.bBlockObjectiveDisplay = true;
	}

	//Pick which region the HQ will start in
	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', IterateRegion)
	{
		if (default.PossibleStartingRegions.Find(IterateRegion.GetMyTemplateName()) != INDEX_NONE)
		{
			AllStartingRegions.AddItem(IterateRegion);
		}

		// Try to find an optimal starting region
		if(IterateRegion.CanBeStartingRegion(StartState))
		{
			BestStartingRegions.AddItem(IterateRegion);
		}
	}

	if(BestStartingRegions.Length > 0)
	{
		RandomIndex = `SYNC_RAND_STATIC(BestStartingRegions.Length);
		BaseRegion = BestStartingRegions[RandomIndex];
	}
	else
	{
		RandomIndex = `SYNC_RAND_STATIC(AllStartingRegions.Length);
		BaseRegion = AllStartingRegions[RandomIndex];
	}
	
	HeadquartersStateObject.StartingRegion = BaseRegion.GetReference();
	HeadquartersStateObject.Region = BaseRegion.GetReference();
	BaseRegion.SetResistanceLevel(StartState, eResLevel_Outpost);
	BaseRegion.BaseSupplyDrop = HeadquartersStateObject.GetStartingRegionSupplyDrop();

	ContinentState = XComGameState_Continent(StartState.GetGameStateForObjectID(BaseRegion.Continent.ObjectID));
	HeadquartersStateObject.Continent = ContinentState.GetReference();
	HeadquartersStateObject.TargetEntity = HeadquartersStateObject.Continent;

	//Fill out the rooms in the HQ
	for(Index = 0; Index < default.XComHeadquarters_NumRooms; Index++)
	{
		RoomStateObject = XComGameState_HeadquartersRoom(StartState.CreateNewStateObject(class'XComGameState_HeadquartersRoom'));		
		RoomStateObject.MapIndex = Index;

		if (Index >= default.XComHeadquarters_MinGridIndex && Index <= default.XComHeadquarters_MaxGridIndex)
		{
			RoomStateObject.GridRow = (Index - default.XComHeadquarters_MinGridIndex) / default.XComHeadquarters_RoomRowLength;
		}
		else
		{
			RoomStateObject.GridRow = -1;
		}

		RoomStateObject.Locked = true; // All rooms start locked and require excavation to gain access
		HeadquartersStateObject.Rooms.AddItem(RoomStateObject.GetReference());//Add the new room to the HQ's list of rooms
		LocalRooms.AddItem(RoomStateObject);
	}

	// Set up room adjacencies
	for (Index = 0; Index < LocalRooms.Length; Index++)
	{
		for (i = 1; i < LocalRooms.Length; i++)
		{
			if (class'X2StrategyGameRulesetDataStructures'.static.AreRoomsAdjacent(LocalRooms[Index], LocalRooms[i]))
			{
				LocalRooms[Index].AdjacentRooms.AddItem(LocalRooms[i].GetReference());
			}
		}
	}

	foreach StartState.IterateByClassType(class'XComGameState_GameTime', TimeState)
	{
		break;
	}
	`assert(TimeState != none);

	//Create the core facilities
	AllFacilityTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2FacilityTemplate');

	for( Index = 0; Index < AllFacilityTemplates.Length; ++Index )
	{
		FacilityTemplate = X2FacilityTemplate(AllFacilityTemplates[Index]);

		if(FacilityTemplate.bIsCoreFacility)
		{
			//Create the state object
			FacilityStateObject = FacilityTemplate.CreateInstanceFromTemplate(StartState);
			
			//Assign it to a room
			for(i = 0; i < LocalRooms.Length; i++)
			{
				RoomStateObject = LocalRooms[i];
				if(RoomStateObject.MapIndex == FacilityTemplate.ForcedMapIndex)
				{
					break;
				}
			}
			FacilityStateObject.Room = RoomStateObject.GetReference();     //Let the facility know what room it is in
			RoomStateObject.Facility = FacilityStateObject.GetReference(); //Let the room know there is a facility assigned to it

			//Record the construction date
			FacilityStateObject.ConstructionDateTime = TimeState.CurrentTime;
	
			//Add the new facility to the HQ's list of facilities
			HeadquartersStateObject.Facilities.AddItem(FacilityStateObject.GetReference());
		}
	}
	HeadquartersStateObject.BuildSoldierClassForcedDeck();

	// Set the Healing Rate
	HeadquartersStateObject.HealingRate = `ScaleGameLengthArrayInt(default.XComHeadquarters_BaseHealRates);

	// Set the Proving Ground Rate
	HeadquartersStateObject.ProvingGroundRate = default.XComHeadquarters_DefaultProvingGroundWorkPerHour;

	// Set the Psi Chamber Rate
	HeadquartersStateObject.PsiTrainingRate = default.XComHeadquarters_DefaultPsiTrainingWorkPerHour;

	// Set the Construction Rate
	HeadquartersStateObject.ConstructionRate = default.XComHeadquarters_DefaultConstructionWorkPerHour;

	// Set Starting Loot Rates
	HeadquartersStateObject.AdventLootWeight = default.StartingAdventLootWeight;
	HeadquartersStateObject.AlienLootWeight = default.StartingAlienLootWeight;

	//Create the starting staff
	CreateStartingSoldiers(StartState, bTutorialEnabled, bXPackNarrativeEnabled);
	CreateStartingEngineer(StartState);
	CreateStartingScientist(StartState);
	CreateStartingBradford(StartState);
	CreateStartingClerks(StartState);

	// Create ResHQ recruits here, so character pool soldiers propagate to staff first
	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		ResHQ.CreateRecruits(StartState);
	}

	//Create the starting resources
	CreateStartingResources(StartState, bTutorialEnabled);

	//Create the room special features
	CreateRoomSpecialFeatures(StartState, bTutorialEnabled);

	// Start the tech inspiration and breakthrough timers
	HeadquartersStateObject.BreakthroughTimerModifier = 1.0;
	HeadquartersStateObject.ResetInspiredTechTimer();
	HeadquartersStateObject.ResetBreakthroughTechTimer(true);

	// Create the Skyranger
	SkyrangerState = XComGameState_Skyranger(StartState.CreateNewStateObject(class'XComGameState_Skyranger'));
	
	// Get Starting Location and set the starting location of Resistance HQ to match the HQ
	foreach StartState.IterateByClassType(class'XComGameState_Haven', HavenState)
	{
		if (HavenState.Region.ObjectID == BaseRegion.ObjectID)
		{
			HeadquartersStateObject.StartingHaven = HavenState.GetReference();

			if (bTutorialEnabled)
			{
				HeadquartersStateObject.Location = default.TutorialStartingLocation;
				HavenState.Location = GetStartingLocation(BaseRegion, HavenState, ResHQLoc);
			}
			else
			{
				HeadquartersStateObject.Location = GetStartingLocation(BaseRegion, HavenState, ResHQLoc);
				HavenState.Location = ResHQLoc;
			}

			HeadquartersStateObject.CurrentLocation = HavenState.GetReference();
			break; // We have found the resistance HQ haven
		}
	}
	
	HeadquartersStateObject.SourceLocation.X = HeadquartersStateObject.Location.X;
	HeadquartersStateObject.SourceLocation.Y = HeadquartersStateObject.Location.Y;
	SkyrangerState.Location = HeadquartersStateObject.Location;
	SkyrangerState.SourceLocation.X = SkyrangerState.Location.X;
	SkyrangerState.SourceLocation.Y = SkyrangerState.Location.Y;
	SkyrangerState.SquadOnBoard = true;

	// Set starting landing site map
	HeadquartersStateObject.LandingSiteMap = class'XGBase'.static.GetBiomeTerrainMap(true);

	// Create the starting mission
	if(!bTutorialEnabled)
	{
		CreateStartingMission(StartState, SkyrangerState.Location);
	}
	
	// update the reference to the Skyranger
	HeadquartersStateObject.SkyrangerRef = SkyrangerState.GetReference();
}

function AddToCrew(XComGameState NewGameState, XComGameState_Unit NewUnit )
{
	Crew.AddItem(NewUnit.GetReference());
	OnCrewMemberAdded(NewGameState, NewUnit);
}

function AddToCrewNoStrategy( XComGameState_Unit NewUnit )
{
	Crew.AddItem( NewUnit.GetReference( ) );
}

function RemoveFromCrew( StateObjectReference CrewRef )
{
	Crew.RemoveItem(CrewRef);
}

//---------------------------------------------------------------------------------------
function BuildSoldierClassForcedDeck()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local SoldierClassCount ClassCount;
	local int i;

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	foreach SoldierClassTemplateMan.IterateTemplates(Template, none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(Template);

		if(!SoldierClassTemplate.bMultiplayerOnly)
		{
			for(i = 0; i < SoldierClassTemplate.NumInForcedDeck; ++i)
			{
				SoldierClassDeck.AddItem(SoldierClassTemplate.DataName);

				if(SoldierClassDistribution.Find('SoldierClassName', SoldierClassTemplate.DataName) == INDEX_NONE)
				{
					// Add to array to track class distribution
					ClassCount.SoldierClassName = SoldierClassTemplate.DataName;
					ClassCount.Count = 0;
					SoldierClassDistribution.AddItem(ClassCount);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function BuildSoldierClassDeck()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local SoldierClassCount ClassCount;
	local int i;

	if (SoldierClassDeck.Length != 0)
	{
		SoldierClassDeck.Length = 0;
	}

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach SoldierClassTemplateMan.IterateTemplates(Template, none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(Template);
		if(!SoldierClassTemplate.bMultiplayerOnly)
		{
			for(i = 0; i < SoldierClassTemplate.NumInDeck; ++i)
			{
				SoldierClassDeck.AddItem(SoldierClassTemplate.DataName);

				if(SoldierClassDistribution.Find('SoldierClassName', SoldierClassTemplate.DataName) == INDEX_NONE)
				{
					// Add to array to track class distribution
					ClassCount.SoldierClassName = SoldierClassTemplate.DataName;
					ClassCount.Count = 0;
					SoldierClassDistribution.AddItem(ClassCount);
				}
			}
		}
	}
	if (XComHeadquarters_NumToRemoveFromSoldierDeck >= SoldierClassDeck.Length)
	{
		`RedScreen("Soldier class deck problem. No elements removed. @gameplay -mnauta");
		return;
	}
	for (i = 0; i < XComHeadquarters_NumToRemoveFromSoldierDeck; ++i)
	{
		SoldierClassDeck.Remove(`SYNC_RAND(SoldierClassDeck.Length), 1);
	}
}

//---------------------------------------------------------------------------------------
function name SelectNextSoldierClass(optional name ForcedClass)
{
	local name RetName;
	local array<name> ValidClasses;
	local int Index;

	if(SoldierClassDeck.Length == 0)
	{
		BuildSoldierClassDeck();
	}
	
	if(ForcedClass != '')
	{
		// Must be a valid class in the distribution list
		if(SoldierClassDistribution.Find('SoldierClassName', ForcedClass) != INDEX_NONE)
		{
			// If not in the class deck rebuild the class deck
			if(SoldierClassDeck.Find(ForcedClass) == INDEX_NONE)
			{
				BuildSoldierClassDeck();
			}

			ValidClasses.AddItem(ForcedClass);
		}
	}

	// Only do this if not forced
	if(ValidClasses.Length == 0)
	{
		ValidClasses = GetValidNextSoldierClasses();
	}
	
	// If not forced, and no valid, rebuild
	if(ValidClasses.Length == 0)
	{
		BuildSoldierClassDeck();
		ValidClasses = GetValidNextSoldierClasses();
	}

	if(SoldierClassDeck.Length == 0)
		`RedScreen("No elements found in SoldierClassDeck array. This might break class assignment, please inform sbatista and provide a save.");

	if(ValidClasses.Length == 0)
		`RedScreen("No elements found in ValidClasses array. This might break class assignment, please inform sbatista and provide a save.");
	
	RetName = ValidClasses[`SYNC_RAND(ValidClasses.Length)];
	SoldierClassDeck.Remove(SoldierClassDeck.Find(RetName), 1);
	Index = SoldierClassDistribution.Find('SoldierClassName', RetName);
	SoldierClassDistribution[Index].Count++;

	return RetName;
}

//---------------------------------------------------------------------------------------
function array<name> GetValidNextSoldierClasses()
{
	local array<name> ValidClasses;
	local int idx;

	for(idx = 0; idx < SoldierClassDeck.Length; idx++)
	{
		if(GetClassDistributionDifference(SoldierClassDeck[idx]) < default.MaxSoldierClassDifference)
		{
			ValidClasses.AddItem(SoldierClassDeck[idx]);
		}
	}

	return ValidClasses;
}

//---------------------------------------------------------------------------------------
private function int GetClassDistributionDifference(name SoldierClassName)
{
	local int LowestCount, ClassCount, idx;

	LowestCount = SoldierClassDistribution[0].Count;

	for(idx = 0; idx < SoldierClassDistribution.Length; idx++)
	{
		if(SoldierClassDistribution[idx].Count < LowestCount)
		{
			LowestCount = SoldierClassDistribution[idx].Count;
		}

		if(SoldierClassDistribution[idx].SoldierClassName == SoldierClassName)
		{
			ClassCount = SoldierClassDistribution[idx].Count;
		}
	}

	return (ClassCount - LowestCount);
}

//---------------------------------------------------------------------------------------
function array<name> GetNeededSoldierClasses()
{
	local XComGameStateHistory History;
	local array<SoldierClassCount> ClassCounts, ClassHighestRank;
	local SoldierClassCount SoldierClassStruct, EmptyStruct;
	local XComGameState_Unit UnitState;
	local array<name> NeededClasses;
	local int idx, Index, HighestClassCount;

	History = `XCOMHISTORY;

	// Grab reward classes
	for(idx = 0; idx < SoldierClassDistribution.Length; idx++)
	{
		SoldierClassStruct = EmptyStruct;
		SoldierClassStruct.SoldierClassName = SoldierClassDistribution[idx].SoldierClassName;
		SoldierClassStruct.Count = 0;
		ClassCounts.AddItem(SoldierClassStruct);
		ClassHighestRank.AddItem(SoldierClassStruct);
	}

	HighestClassCount = 0;

	// Grab current crew information
	for(idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(UnitState != none && UnitState.IsSoldier() && UnitState.GetRank() > 0)
		{
			Index = ClassCounts.Find('SoldierClassName', UnitState.GetSoldierClassTemplate().DataName);

			if(Index != INDEX_NONE)
			{
				// Add to class count
				ClassCounts[Index].Count++;
				if(ClassCounts[Index].Count > HighestClassCount)
				{
					HighestClassCount = ClassCounts[Index].Count;
				}

				// Update Highest class rank if applicable
				if(ClassHighestRank[Index].Count < UnitState.GetRank())
				{
					ClassHighestRank[Index].Count = UnitState.GetRank();
				}
			}
		}
	}

	// Parse the info to grab needed classes
	for(idx = 0; idx < ClassCounts.Length; idx++)
	{
		if((ClassCounts[idx].Count == 0) || ((HighestClassCount - ClassCounts[idx].Count) >= 2) || ((HighestSoldierRank - ClassHighestRank[idx].Count) >= 2))
		{
			NeededClasses.AddItem(ClassCounts[idx].SoldierClassName);
		}
	}

	// If no classes are needed, all classes are needed
	if(NeededClasses.Length == 0)
	{
		for(idx = 0; idx < ClassCounts.Length; idx++)
		{
			NeededClasses.AddItem(ClassCounts[idx].SoldierClassName);
		}
	}

	return NeededClasses;
}

//---------------------------------------------------------------------------------------
static function CreateRoomSpecialFeatures(XComGameState StartState, optional bool bTutorialEnabled = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
	local array<XComGameState_HeadquartersRoom> ValidRooms;
	local array<SpecialRoomFeatureEntry> FeatureDeck, FillDeck, RowFeatureDeck, RowFillDeck;
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local int idx, FeatureIndex, RandIndex, CurrentRow, NumRows;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	assert(StartState != none);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// First fill the valid room array
	for(idx = 0; idx < XComHQ.Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(StartState.GetGameStateForObjectID(XComHQ.Rooms[idx].ObjectID));

		if(Room != none)
		{
			if(!Room.HasFacility())
			{
				ValidRooms.AddItem(Room);
			}
		}
	}

	// Add special features to random rooms to meet minimum feature requirements
	CreateMinimumSpecialFeatureRequirements(StartState, ValidRooms, bTutorialEnabled);
	
	// Create source special feature and fill decks
	FeatureDeck = BuildSpecialFeatureDeck(bTutorialEnabled);
	FillDeck = BuildSpecialFillDeck(bTutorialEnabled);

	NumRows = ValidRooms.Length / default.XComHeadquarters_RoomRowLength;
	
	// For each row in the Avenger facility grid
	for (CurrentRow = 0; CurrentRow < NumRows; CurrentRow++)
	{
		// Build a row-specific feature and fill deck using the source decks
		RowFeatureDeck = BuildRowSpecialFeatureDeck(FeatureDeck, CurrentRow);
		RowFillDeck = BuildRowSpecialFillDeck(FillDeck, CurrentRow);

		// For each room in the row
		for (idx = 0; idx < default.XComHeadquarters_RoomRowLength; idx++)
		{
			Room = ValidRooms[CurrentRow * default.XComHeadquarters_RoomRowLength + idx];
			
			if (!Room.HasSpecialFeature()) // If the room did not have a feature or fill already set
			{
				RandIndex = `SYNC_RAND_STATIC(RowFeatureDeck.Length);
				SpecialFeature = RowFeatureDeck[RandIndex].FeatureTemplate;

				if (SpecialFeature != none)
				{
					// Find the related feature in the source deck, and check to see if the max quantity is surpassed
					for (FeatureIndex = 0; FeatureIndex < FeatureDeck.Length; FeatureIndex++)
					{
						if (FeatureDeck[FeatureIndex].FeatureTemplate == SpecialFeature)
						{
							FeatureDeck[FeatureIndex].Quantity++;

							if (FeatureDeck[FeatureIndex].Quantity >= SpecialFeature.MaxTotalAllowed)
							{
								// If so, remove it from the row deck
								RowFeatureDeck.Remove(RandIndex, 1);
							}
						}
					}
				}
				else // If the Feature was none, pick a random Fill instead
				{
					RandIndex = `SYNC_RAND_STATIC(RowFillDeck.Length);
					SpecialFeature = RowFillDeck[RandIndex].FeatureTemplate;
				}
				
				// Assign the feature to the chosen room
				if (SpecialFeature != none)
				{
					AssignSpecialFeatureToRoom(StartState, SpecialFeature, Room);
				}
			}
			else if (Room.SpecialFeature == 'SpecialRoomFeature_EmptyRoom')
			{
				// If the room was set as empty by the empty room template, erase that now so it will spawn as a true empty room
				Room.SpecialFeature = '';
				Room.Locked = false;
				UnlockAdjacentRooms(StartState, Room);
			}

			// Unlock tutorial excavate room
			if(bTutorialEnabled && Room.MapIndex == default.TutorialExcavateIndex)
			{
				Room.Locked = false;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
private static function CreateMinimumSpecialFeatureRequirements(XComGameState StartState, array<XComGameState_HeadquartersRoom> ValidRooms, optional bool bTutorialEnabled = false)
{	
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local array<SpecialRoomFeatureEntry> FeatureDeck;
	local XComGameState_HeadquartersRoom Room, ExclusiveRoom;
	local array<XComGameState_HeadquartersRoom> ValidRoomsForFeature;
	local array<int> ExclusiveIndices;
	local int idx, RoomIndex, MinRoomIndex, MaxRoomIndex;
	local bool bExclusiveFeatureFound;

	FeatureDeck = BuildSpecialFeatureDeck(bTutorialEnabled);

	for (idx = 0; idx < FeatureDeck.Length; idx++)
	{
		SpecialFeature = FeatureDeck[idx].FeatureTemplate;
		
		//If the feature exists and has a minimum requirement, find the rooms where it can be applied
		if (SpecialFeature != None && SpecialFeature.MinTotalAllowed > 0)
		{
			// Set the min and max room indices based on the feature row requirements
			// Lowest/HighestRowAllowed start at 1, not 0, to allow for default values when they are not set in the templates
			if (SpecialFeature.LowestRowAllowed > 0)
				MinRoomIndex = (SpecialFeature.LowestRowAllowed - 1) * default.XComHeadquarters_RoomRowLength;
			else
				MinRoomIndex = 0;

			if (SpecialFeature.HighestRowAllowed > 0)
				MaxRoomIndex = (SpecialFeature.HighestRowAllowed) * default.XComHeadquarters_RoomRowLength;
			else
				MaxRoomIndex = ValidRooms.Length;

			ValidRoomsForFeature.Length = 0; // Reset the array of valid rooms
			for (RoomIndex = MinRoomIndex; RoomIndex < MaxRoomIndex; RoomIndex++)
			{
				if (!ValidRooms[RoomIndex].HasSpecialFeature()) // Don't pick a room which already has an assigned feature
				{
					ValidRoomsForFeature.AddItem(ValidRooms[RoomIndex]);
				}
			}

			// Then randomly choose rooms from the list and assign the feature to them until its minimum quantity is met
			while (FeatureDeck[idx].Quantity > 0)
			{
				bExclusiveFeatureFound = false;

				if (ValidRoomsForFeature.Length > 0)
				{
					Room = ValidRoomsForFeature[`SYNC_RAND_STATIC(ValidRoomsForFeature.Length)];

					// Get any exclusivity conditions for this special feature type
					ExclusiveIndices = FeatureDeck[idx].FeatureTemplate.ExclusiveRoomIndices;
					if (ExclusiveIndices.Length > 0)
					{
						if (ExclusiveIndices.Find(Room.MapIndex) != INDEX_NONE) // Is the selected room part of the exclusivity array for this feature
						{
							foreach ValidRooms(ExclusiveRoom) // Take all of the possible rooms
							{
								// Check if the checked room is in the exclusive list and if it already has the feature
								if (ExclusiveIndices.Find(ExclusiveRoom.MapIndex) != INDEX_NONE && ExclusiveRoom.GetSpecialFeature() == FeatureDeck[idx].FeatureTemplate)
								{
									bExclusiveFeatureFound = true; // Feature was found in an exclusive room, so cannot be placed here again
									break;
								}
							}
						}
					}
					
					// Otherwise its fine
					if (!bExclusiveFeatureFound)
					{
						AssignSpecialFeatureToRoom(StartState, FeatureDeck[idx].FeatureTemplate, Room);
					}

					ValidRoomsForFeature.RemoveItem(Room);
				}

				if (!bExclusiveFeatureFound)
					FeatureDeck[idx].Quantity--;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
private static function array<SpecialRoomFeatureEntry> BuildSpecialFeatureDeck(optional bool bTutorialEnabled = false)
{
	local array<X2StrategyElementTemplate> AllSpecialFeatures;
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local SpecialRoomFeatureEntry FeatureEntry;
	local array<SpecialRoomFeatureEntry> FeatureDeck;
	local int idx;

	FeatureDeck.Length = 0;

	// First add a blank entry to the deck to give a random chance for no special feature
	FeatureDeck.AddItem(FeatureEntry);

	// Create special feature deck
	AllSpecialFeatures = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SpecialRoomFeatureTemplate');

	for (idx = 0; idx < AllSpecialFeatures.Length; idx++)
	{
		SpecialFeature = X2SpecialRoomFeatureTemplate(AllSpecialFeatures[idx]);
		FeatureEntry.FeatureTemplate = SpecialFeature;

		if (!SpecialFeature.bFillAvenger && (!bTutorialEnabled || default.TutorialExcludeSpecialRoomFeatures.Find(SpecialFeature.DataName) == INDEX_NONE))
		{
			FeatureEntry.Quantity = SpecialFeature.MinTotalAllowed;
			FeatureDeck.AddItem(FeatureEntry);
		}
	}

	return FeatureDeck;
}

//---------------------------------------------------------------------------------------
private static function array<SpecialRoomFeatureEntry> BuildRowSpecialFeatureDeck(array<SpecialRoomFeatureEntry> SourceDeck, int Row)
{	
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local SpecialRoomFeatureEntry FeatureEntry;
	local array<SpecialRoomFeatureEntry> FeatureDeck;
	local int idx;

	FeatureDeck.Length = 0;

	// First add a blank entry to the deck to give a random chance for no special feature
	FeatureDeck.AddItem(FeatureEntry);

	for (idx = 0; idx < SourceDeck.Length; idx++)
	{
		SpecialFeature = SourceDeck[idx].FeatureTemplate;
		if (SpecialFeature == none)
			continue;

		// Then check to make sure the other features are still allowed to be generated before adding to the deck
		if (((SpecialFeature.LowestRowAllowed - 1) <= Row) &&
			(SpecialFeature.MaxTotalAllowed - SpecialFeature.MinTotalAllowed > 0) &&
			(SourceDeck[idx].Quantity < SpecialFeature.MaxTotalAllowed))
		{
			FeatureDeck.AddItem(SourceDeck[idx]);
		}
	}

	return FeatureDeck;
}

//---------------------------------------------------------------------------------------
private static function array<SpecialRoomFeatureEntry> BuildSpecialFillDeck(optional bool bTutorialEnabled = false)
{
	local array<X2StrategyElementTemplate> AllSpecialFeatures;
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local SpecialRoomFeatureEntry FeatureEntry;
	local array<SpecialRoomFeatureEntry> FillDeck;
	local int idx;

	FillDeck.Length = 0;
	
	// Create special feature deck
	AllSpecialFeatures = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SpecialRoomFeatureTemplate');

	for (idx = 0; idx < AllSpecialFeatures.Length; idx++)
	{
		SpecialFeature = X2SpecialRoomFeatureTemplate(AllSpecialFeatures[idx]);
		FeatureEntry.FeatureTemplate = SpecialFeature;

		if(SpecialFeature.bFillAvenger && (!bTutorialEnabled || default.TutorialExcludeSpecialRoomFeatures.Find(SpecialFeature.DataName) == INDEX_NONE))
		{
			FillDeck.AddItem(FeatureEntry);
		}
	}

	return FillDeck;
}

//---------------------------------------------------------------------------------------
private static function array<SpecialRoomFeatureEntry> BuildRowSpecialFillDeck(array<SpecialRoomFeatureEntry> SourceDeck, int Row)
{
	local array<SpecialRoomFeatureEntry> FillDeck;
	local int idx;

	FillDeck.Length = 0;
	
	for (idx = 0; idx < SourceDeck.Length; idx++)
	{		
		if ((SourceDeck[idx].FeatureTemplate.LowestRowAllowed - 1) <= Row)
		{
			FillDeck.AddItem(SourceDeck[idx]);
		}
	}

	return FillDeck;
}

//---------------------------------------------------------------------------------------
private static function AssignSpecialFeatureToRoom(XComGameState StartState, X2SpecialRoomFeatureTemplate SpecialFeature, XComGameState_HeadquartersRoom Room)
{
	local X2LootTableManager LootManager;
	local int LootIndex, NumBuildSlotsToAdd, idx;
	
	Room.SpecialFeature = SpecialFeature.DataName;

	if(SpecialFeature.UnclearedMapNames.Length > 0)
	{
		Room.SpecialFeatureUnclearedMapName = SpecialFeature.UnclearedMapNames[`SYNC_RAND_STATIC(SpecialFeature.UnclearedMapNames.Length)];
	}

	if(SpecialFeature.ClearedMapNames.Length > 0)
	{
		Room.SpecialFeatureClearedMapName = SpecialFeature.ClearedMapNames[`SYNC_RAND_STATIC(SpecialFeature.ClearedMapNames.Length)];
	}
	

	if (SpecialFeature.bBlocksConstruction)
	{
		Room.ConstructionBlocked = true;
	}

	if (SpecialFeature.bHasLoot && SpecialFeature.GetDepthBasedLootTableNameFn != none)
	{
		LootManager = class'X2LootTableManager'.static.GetLootTableManager();
		LootIndex = LootManager.FindGlobalLootCarrier(SpecialFeature.GetDepthBasedLootTableNameFn(Room));
		if (LootIndex >= 0)
		{
			LootManager.RollForGlobalLootCarrier(LootIndex, Room.Loot, StartState);
		}
	}

	// Create the build slots associated with this special feature
	if (SpecialFeature.GetDepthBasedNumBuildSlotsFn != none)
	{
		NumBuildSlotsToAdd = SpecialFeature.GetDepthBasedNumBuildSlotsFn(Room);
		for (idx = 0; idx < NumBuildSlotsToAdd; idx++)
		{
			Room.AddBuildSlot(StartState);
		}
	}
}

//---------------------------------------------------------------------------------------
static function CreateStartingResources(XComGameState StartState, bool bTutorialEnabled)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateMgr;
	local XComGameState_Item NewItemState;
	local X2ItemTemplate ItemTemplate;
	local X2DataTemplate DataTemplate;
	local XComGameStateHistory History;
	local name ItemTemplateName;

	History = `XCOMHISTORY;

	assert(StartState != none);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Create Supplies
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('Supplies');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingSupplies();
	XComHQ.AddItemToHQInventory(NewItemState);

	// Create Intel
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('Intel');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingIntel();
	XComHQ.AddItemToHQInventory(NewItemState);

	// Create Alien Alloys
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('AlienAlloy');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingAlloys();
	XComHQ.AddItemToHQInventory(NewItemState);

	// Create Elerium Crystals
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('EleriumDust');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingElerium();
	XComHQ.AddItemToHQInventory(NewItemState);

	// Create Ability Points
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('AbilityPoint');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingAbilityPoints();
	XComHQ.AddItemToHQInventory(NewItemState);

	// Create one of each starting item
	foreach ItemTemplateMgr.IterateTemplates(DataTemplate, none)
	{
		if( X2ItemTemplate(DataTemplate) != none && X2ItemTemplate(DataTemplate).StartingItem)
		{
			NewItemState = X2ItemTemplate(DataTemplate).CreateInstanceFromTemplate(StartState);
			XComHQ.AddItemToHQInventory(NewItemState);
		}
	}

	if(bTutorialEnabled)
	{
		foreach default.TutorialStartingItems(ItemTemplateName)
		{
			ItemTemplate = ItemTemplateMgr.FindItemTemplate(ItemTemplateName);

			if(ItemTemplate != none)
			{
				NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
				XComHQ.AddItemToHQInventory(NewItemState);
			}
		}
	}
}

// Helper function for GetStartingLocation - can't call the existing non-static one
static function float WrapFStatic(float Val, float Min, float Max)
{
	if (Val > Max)
		return WrapFStatic(Min + (Val - Max), Min, Max);
	if (Val < Min)
		return WrapFStatic(Max - (Min - Val), Min, Max);
	return Val;
}

static function int GetRandomTriangle(array<float> CumulativeTriangleArea)
{
	local int Tri;
	local int ArrLength;
	local float RandomArea;

	ArrLength = CumulativeTriangleArea.Length;
	if (ArrLength <= 0) return 0;

	RandomArea = class'Engine'.static.GetEngine().SyncFRand("GetRandomTriangle") * CumulativeTriangleArea[ArrLength - 1];
	for (Tri = 0; Tri < ArrLength - 1; ++Tri)
	{
		if (CumulativeTriangleArea[Tri] > RandomArea) break;
	}

	return Tri;
}

// HACK: The starting location needs to be set before region meshes are available.
//		 Load the starting region mesh one time here to be able to generate a 
//		 starting location from it.
static function Vector GetStartingLocation(XComGameState_WorldRegion LandingSite, XComGameState_Haven HavenSite, out Vector ResHQLoc)
{
	local array<XComGameState_GeoscapeEntity> OverlapEntities;
	local StaticMesh RegionMesh;
	local Texture2D RegionTexture;
	local Object TextureObject;
	local X2WorldRegionTemplate RegionTemplate;
	local StaticMeshComponent curRegion;
	local Vector RandomLocation, ResHQLocTransform, RegionCenter;
	local Matrix Transform;
	local Vector2D RandomLoc2D, ResHQLoc2D, RegionCenter2D;
	local int Iterations, idx;
	local int RandomTri;
	local array<float> CumulativeTriangleArea;
	local bool bFoundGoodResHQLoc;

	RandomLocation.X = -1.0; RandomLocation.Y = -1.0; RandomLocation.Z = -1.0;

	RegionTemplate = LandingSite.GetMyTemplate();

	TextureObject = `CONTENT.RequestGameArchetype(RegionTemplate.RegionTexturePath);
	if (TextureObject == none || !TextureObject.IsA('Texture2D'))
	{
		`RedScreen("Could not load region texture" @ RegionTemplate.RegionTexturePath);
		return RandomLocation;
	}

	RegionTexture = Texture2D(TextureObject);
	RegionMesh = class'Helpers'.static.ConstructRegionActor(RegionTexture);

	curRegion = new class'StaticMeshComponent';
	curRegion.SetAbsolute(true, true, true);
	curRegion.SetStaticMesh(RegionMesh);

	Transform.XPlane.X = RegionTemplate.RegionMeshScale;
	Transform.YPlane.Y = RegionTemplate.RegionMeshScale;
	Transform.ZPlane.Z = RegionTemplate.RegionMeshScale;

	Transform.WPlane.X = RegionTemplate.RegionMeshLocation.X * class'XComEarth'.default.Width + class'XComEarth'.default.XOffset;
	Transform.WPlane.Y = RegionTemplate.RegionMeshLocation.Y * class'XComEarth'.default.Height;
	Transform.WPlane.Z = 0.1f;
	Transform.WPlane.W = 1.0f;

	class'Helpers'.static.GenerateCumulativeTriangleAreaArray(curRegion, CumulativeTriangleArea);
	
	// Make sure Res HQ region has an updated center location, then add to overlap array to prevent pin overlaps
	RegionCenter = class'Helpers'.static.GetRegionCenterLocation(curRegion, false);
	RegionCenter = TransformVector(Transform, RegionCenter);
	RegionCenter2D = class'XComEarth'.static.ConvertWorldToEarth(RegionCenter);
	LandingSite.Location.X = RegionCenter2D.X;
	LandingSite.Location.Y = RegionCenter2D.Y;
	OverlapEntities.AddItem(LandingSite);
	
	do {
		// Get a random point in the region mesh for the Avenger
		RandomTri = GetRandomTriangle(CumulativeTriangleArea);
		RandomLocation = class'Helpers'.static.GetRandomPointInRegionMesh(curRegion, RandomTri, false);
		RandomLocation = TransformVector(Transform, RandomLocation);

		// Convert Avenger point to Earth coords
		RandomLoc2D = class'XComEarth'.static.ConvertWorldToEarth(RandomLocation);
		RandomLocation.X = RandomLoc2D.X;
		RandomLocation.Y = RandomLoc2D.Y;
		RandomLocation.Z = 0.0f;
		
		if (class'X2StrategyGameRulesetDataStructures'.static.IsOnLand(RandomLoc2D))
		{
			// We have found a point in the region and on land for the Avenger, now find one for Res HQ
			for (idx = 0; idx < 100; idx++)
			{
				// Get a point within the radius of the Avenger for Res HQ's starting location
				ResHQLoc2D = class'X2StrategyGameRulesetDataStructures'.static.AdjustLocationByRadius(RandomLoc2D, default.LandingRadius);
				ResHQLoc.X = ResHQLoc2D.X;
				ResHQLoc.Y = ResHQLoc2D.Y;

				// convert Res HQ point to world coordinates
				ResHQLocTransform = class'XComEarth'.static.ConvertEarthToWorld(ResHQLoc2D, true);
				ResHQLocTransform = InverseTransformVector(Transform, ResHQLocTransform);

				// Check if the Res HQ point is in the region and not overlapping with the region pin
				if (class'Helpers'.static.IsInRegion(curRegion, ResHQLocTransform, false)
					&& class'X2StrategyGameRulesetDataStructures'.static.AvoidOverlapWithTooltipBounds(ResHQLoc, OverlapEntities, HavenSite))
				{
					bFoundGoodResHQLoc = true;
					break; // We have found a successful point for this starting Res HQ location AND Avenger location
				}
			}
		}

		++Iterations;
	} 
	until(bFoundGoodResHQLoc || Iterations > 100);

	return RandomLocation;
}

//---------------------------------------------------------------------------------------
static function CreateStartingMission(XComGameState StartState, Vector StartingMissionLoc)
{
	local XComGameState_MissionSite Mission;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local array<XComGameState_Reward> MissionRewards;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local XComGameStateHistory History;
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local XComGameState_WorldRegion RegionState;
	local Vector2D v2Loc;

	History = `XCOMHISTORY;
	
	assert(StartState != none);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	RegionState = XComGameState_WorldRegion(StartState.GetGameStateForObjectID(XComHQ.StartingRegion.ObjectID));
	v2Loc.X = StartingMissionLoc.X;
	v2Loc.Y = StartingMissionLoc.Y;

	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(StartState);
	MissionRewards.AddItem(RewardState);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		break;
	}

	Mission = XComGameState_MissionSite(StartState.CreateNewStateObject(class'XComGameState_MissionSite'));
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_Start'));
	Mission.BuildMission(MissionSource, v2Loc, RegionState.GetReference(), MissionRewards, true);
}

//---------------------------------------------------------------------------------------
static function CreateStartingSoldiers(XComGameState StartState, optional bool bTutorialEnabled = false, optional bool bXPackNarrativeEnabled = false)
{
	local XComGameState_Unit NewSoldierState;	
	local XComGameState_HeadquartersXCom XComHQ;
	local XGCharacterGenerator CharacterGenerator;
	local TSoldier TutSoldier;
	local int Index, i;
	local XComGameState_GameTime GameTime;
	local XComGameState_Analytics Analytics;
	local TAppearance TutSoldierAppearance;
	local TDateTime TutKIADate;
	local StateObjectReference EmptyRef;
	local X2MissionSourceTemplate MissionSource;
	local XComOnlineProfileSettings ProfileSettings;

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	foreach StartState.IterateByClassType(class'XComGameState_GameTime', GameTime)
	{
		break;
	}
	`assert( GameTime != none );

	foreach StartState.IterateByClassType( class'XComGameState_Analytics', Analytics )
	{
		break;
	}
	`assert( Analytics != none );

	ProfileSettings = `XPROFILESETTINGS;

	// Starting soldiers
	for( Index = 0; Index < class'XGTacticalGameCore'.default.NUM_STARTING_SOLDIERS; ++Index )
	{
		if (!bXPackNarrativeEnabled && !bTutorialEnabled && Index == 3)
		{
			NewSoldierState = CreateStartingFactionSoldier(StartState);
		}
		else
		{
			NewSoldierState = `CHARACTERPOOLMGR.CreateCharacter(StartState, ProfileSettings.Data.m_eCharPoolUsage);
			CharacterGenerator = `XCOMGRI.Spawn(NewSoldierState.GetMyTemplate().CharacterGeneratorClass);
			`assert(CharacterGenerator != none);

			if (bTutorialEnabled && Index == 0)
			{
				TutSoldier = CharacterGenerator.CreateTSoldier('Soldier', default.TutorialSoldierGender, default.TutorialSoldierCountry);
				TutSoldierAppearance = default.TutorialSoldierAppearance;

				if (GetLanguage() == "FRA")
				{
					TutSoldierAppearance.nmVoice = default.TutorialSoldierFrenchVoice;
				}
				else if (GetLanguage() == "DEU")
				{
					TutSoldierAppearance.nmVoice = default.TutorialSoldierGermanVoice;
				}
				else if (GetLanguage() == "ITA")
				{
					TutSoldierAppearance.nmVoice = default.TutorialSoldierItalianVoice;
				}
				else if (GetLanguage() == "ESN")
				{
					TutSoldierAppearance.nmVoice = default.TutorialSoldierSpanishVoice;
				}
				else
				{
					TutSoldierAppearance.nmVoice = default.TutorialSoldierEnglishVoice;
				}

				NewSoldierState.SetTAppearance(TutSoldierAppearance);
				NewSoldierState.SetCharacterName(class'XLocalizedData'.default.TutorialSoldierFirstName, class'XLocalizedData'.default.TutorialSoldierLastName, TutSoldier.strNickName);
				NewSoldierState.SetCountry(TutSoldier.nmCountry);
				NewSoldierState.SetXPForRank(1);
				NewSoldierState.GenerateBackground(, CharacterGenerator.BioCountryName);
				NewSoldierState.StartingRank = 1;
				NewSoldierState.iNumMissions = 1;
				XComHQ.TutorialSoldier = NewSoldierState.GetReference();
			}
		}
		
		NewSoldierState.RandomizeStats();
		NewSoldierState.ApplyInventoryLoadout(StartState);
		NewSoldierState.bIsFamous = true;

		NewSoldierState.SetHQLocation(eSoldierLoc_Barracks);

		XComHQ.AddToCrew(StartState, NewSoldierState);
		NewSoldierState.m_RecruitDate = GameTime.CurrentTime; // AddToCrew does this, but during start state creation the StrategyRuleset hasn't been created yet

		if(XComHQ.Squad.Length < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
		{
			XComHQ.Squad.AddItem(NewSoldierState.GetReference());
		}
	}

	// Dead tutorial soldiers

	if(bTutorialEnabled)
	{
		class'X2StrategyGameRulesetDataStructures'.static.SetTime(TutKIADate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
			class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);

		MissionSource = X2MissionSourceTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('MissionSource_Start'));

		// Osei
		NewSoldierState = `CHARACTERPOOLMGR.CreateCharacter(StartState, ProfileSettings.Data.m_eCharPoolUsage);
		TutSoldier = CharacterGenerator.CreateTSoldier('Soldier', default.DeadTutorialSoldier1Gender, default.DeadTutorialSoldier1Country);
		NewSoldierState.SetTAppearance(default.DeadTutorialSoldier1Appearance);
		NewSoldierState.SetCharacterName(class'XLocalizedData'.default.DeadTutorialSoldier1FirstName, class'XLocalizedData'.default.DeadTutorialSoldier1LastName, TutSoldier.strNickName);
		NewSoldierState.SetCountry(TutSoldier.nmCountry);
		NewSoldierState.SetXPForRank(1);
		NewSoldierState.StartingRank = 1;
		NewSoldierState.iNumMissions = 1;
		NewSoldierState.RandomizeStats();
		NewSoldierState.ApplyInventoryLoadout(StartState);
		NewSoldierState.SetHQLocation(eSoldierLoc_Barracks);
		NewSoldierState.SetCurrentStat(eStat_HP, 0.0f);
		NewSoldierState.m_KIADate = TutKIADate;
		NewSoldierState.m_strKIAOp = MissionSource.BattleOpName;
		NewSoldierState.m_strCauseOfDeath = default.DeadTutorialSoldier1CauseOfDeath;
		NewSoldierState.m_strEpitaph = default.DeadTutorialSoldier1Epitaph;

		for(i = 0; i < default.DeadTutorialSoldier1NumKills; i++)
		{
			NewSoldierState.SimGetKill(EmptyRef);
		}

		XComHQ.DeadCrew.AddItem(NewSoldierState.GetReference());

		Analytics.AddValue( "ACC_UNIT_SERVICE_LENGTH", 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( "ACC_UNIT_HEALING", 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( "ACC_UNIT_SUCCESSFUL_ATTACKS", 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( "ACC_UNIT_DEALT_DAMAGE", 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( "ACC_UNIT_ABILITIES_RECIEVED", 0, NewSoldierState.GetReference( ) );

		// Ramirez
		NewSoldierState = `CHARACTERPOOLMGR.CreateCharacter(StartState, ProfileSettings.Data.m_eCharPoolUsage);
		TutSoldier = CharacterGenerator.CreateTSoldier('Soldier', default.DeadTutorialSoldier2Gender, default.DeadTutorialSoldier2Country);
		NewSoldierState.SetTAppearance(default.DeadTutorialSoldier2Appearance);
		NewSoldierState.SetCharacterName(class'XLocalizedData'.default.DeadTutorialSoldier2FirstName, class'XLocalizedData'.default.DeadTutorialSoldier2LastName, TutSoldier.strNickName);
		NewSoldierState.SetCountry(TutSoldier.nmCountry);
		NewSoldierState.SetXPForRank(1);
		NewSoldierState.StartingRank = 1;
		NewSoldierState.iNumMissions = 1;
		NewSoldierState.RandomizeStats();
		NewSoldierState.ApplyInventoryLoadout(StartState);
		NewSoldierState.SetHQLocation(eSoldierLoc_Barracks);
		NewSoldierState.SetCurrentStat(eStat_HP, 0.0f);
		NewSoldierState.m_KIADate = TutKIADate;
		NewSoldierState.m_strKIAOp = MissionSource.BattleOpName;
		NewSoldierState.m_strCauseOfDeath = default.DeadTutorialSoldier2CauseOfDeath;
		NewSoldierState.m_strEpitaph = default.DeadTutorialSoldier2Epitaph;

		for(i = 0; i < default.DeadTutorialSoldier2NumKills; i++)
		{
			NewSoldierState.SimGetKill(EmptyRef);
		}

		XComHQ.DeadCrew.AddItem(NewSoldierState.GetReference());

		// Ramirez Bar Memorial Data
		Analytics.AddValue( "ACC_UNIT_SERVICE_LENGTH", 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( "ACC_UNIT_HEALING", 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( "ACC_UNIT_SUCCESSFUL_ATTACKS", 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( "ACC_UNIT_DEALT_DAMAGE", 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( "ACC_UNIT_ABILITIES_RECIEVED", 0, NewSoldierState.GetReference( ) );
	}
}

//---------------------------------------------------------------------------------------
static function XComGameState_Unit CreateStartingFactionSoldier(XComGameState StartState)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_Unit UnitState;

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		break;
	}

	// Gatecrasher involves meeting up with a Faction Soldier, so create them
	FactionState = XComGameState_ResistanceFaction(StartState.GetGameStateForObjectID(ResHQ.Factions[0].ObjectID));
	if (FactionState != none)
	{
		UnitState = `CHARACTERPOOLMGR.CreateCharacter(StartState, `XPROFILESETTINGS.Data.m_eCharPoolUsage, FactionState.GetChampionCharacterName());
	}

	return UnitState;
}

//---------------------------------------------------------------------------------------
static function CreateStartingEngineer(XComGameState StartState)
{
	local X2CharacterTemplateManager CharTemplateMgr;	
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit ShenState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_HeadquartersXCom XComHQ;

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('HeadEngineer');
	`assert(CharacterTemplate != none);
	CharacterGenerator = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	ShenState = CharacterTemplate.CreateInstanceFromTemplate(StartState);
	ShenState.SetSkillLevel(2);
	ShenState.SetCharacterName(class'XLocalizedData'.default.LilyShenFirstName, class'XLocalizedData'.default.LilyShenLastName, "");
	CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
	ShenState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		
	XComHQ.AddToCrew(StartState, ShenState);
}

//---------------------------------------------------------------------------------------
static function CreateStartingScientist(XComGameState StartState)
{
	local X2CharacterTemplateManager CharTemplateMgr;	
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit TyganState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_HeadquartersXCom XComHQ;

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('HeadScientist');
	`assert(CharacterTemplate != none);
	CharacterGenerator = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	TyganState = CharacterTemplate.CreateInstanceFromTemplate(StartState);
	TyganState.SkillValue = TyganState.GetMyTemplate().SkillLevelThresholds[2];
	TyganState.SetCharacterName(class'XLocalizedData'.default.RichardTyganFirstName, class'XLocalizedData'.default.RichardTyganLastName, "");
	CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
	TyganState.SetTAppearance(CharacterGeneratorResult.kAppearance);

	XComHQ.AddToCrew(StartState, TyganState);
}

static function CreateStartingBradford(XComGameState StartState)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit CentralState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_HeadquartersXCom XComHQ;	

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('StrategyCentral');
	`assert(CharacterTemplate != none);
	CharacterGenerator = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	CentralState = CharacterTemplate.CreateInstanceFromTemplate(StartState);	
	CentralState.SetCharacterName(class'XLocalizedData'.default.OfficerBradfordFirstName, class'XLocalizedData'.default.OfficerBradfordLastName, "");
	CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
	CentralState.SetTAppearance(CharacterGeneratorResult.kAppearance);

	XComHQ.AddToCrew(StartState, CentralState);
}

static function CreateStartingClerks(XComGameState StartState)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit ClerkState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_HeadquartersXCom XComHQ;	
	local int Idx;

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Clerk');
	`assert(CharacterTemplate != none);

	CharacterGenerator = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	for(Idx = 0; Idx < default.NumClerks_ActOne; ++Idx)
	{
		ClerkState = CharacterTemplate.CreateInstanceFromTemplate(StartState);
		CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
		ClerkState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		XComHQ.Clerks.AddItem(ClerkState.GetReference());
	}
}

function UpdateClerkCount(int ActNum, XComGameState UpdateGameState)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit ClerkState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;	
	local int MaxClerks;

	switch(ActNum)
	{
		case 1:
			MaxClerks = NumClerks_ActOne;
			break;
		case 2:
			MaxClerks = NumClerks_ActTwo;
			break;
		case 3:
			MaxClerks = NumClerks_ActThree;
			break;
	}

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);
	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Clerk');
	`assert(CharacterTemplate != none);
	CharacterGenerator = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	while(Clerks.Length < MaxClerks)
	{
		ClerkState = CharacterTemplate.CreateInstanceFromTemplate(UpdateGameState);
		CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
		ClerkState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		Clerks.AddItem(ClerkState.GetReference());
	}
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool ShouldUpdate()
{
	local X2StrategyGameRuleset StrategyRuleset;
	local ScanRateMod ScanRateModifier;
	local int idx;

	StrategyRuleset = `STRATEGYRULES;

	// Iterate through each of the scan rate mods and check to see if it has expired
	for (idx = 0; idx < ScanRateMods.Length; idx++)
	{
		ScanRateModifier = ScanRateMods[idx];
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ScanRateModifier.ScanRateEndTime, StrategyRuleset.GameTime))
		{
			return true;
		}
	}

	for (idx = 0; idx < CurrentOrders.Length; idx++)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(CurrentOrders[idx].OrderCompletionTime, StrategyRuleset.GameTime))
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool Update(XComGameState NewGameState, out array<XComGameState_Unit> UnitsWhichLeveledUp)
{
	local bool bUpdated;
	local int idx;
	local X2StrategyGameRuleset StrategyRuleset;

	bUpdated = false;
	StrategyRuleset = `STRATEGYRULES;
		
	// First update any scan rate modifiers that have been applied to XComHQ
	bUpdated = UpdateScanRateModifiers(NewGameState);

	for(idx = 0; idx < CurrentOrders.Length; idx++)
	{
		if( class'X2StrategyGameRulesetDataStructures'.static.LessThan(CurrentOrders[idx].OrderCompletionTime, StrategyRuleset.GameTime) )
		{
			if (NewGameState != none)
			{
				OnStaffOrderComplete(NewGameState, CurrentOrders[idx]);
			}
			bUpdated = true;
		}
	}

	return bUpdated;
}

//---------------------------------------------------------------------------------------
function bool UpdateScanRateModifiers(XComGameState NewGameState)
{
	local ScanRateMod ScanRateModifier;
	local bool bUpdated;
	local int idx;
	
	for (idx = 0; idx < ScanRateMods.Length; idx++)
	{
		ScanRateModifier = ScanRateMods[idx];
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ScanRateModifier.ScanRateEndTime, `STRATEGYRULES.GameTime))
		{
			CurrentScanRate /= ScanRateModifier.Modifier;
			UpdateScanSiteTimes(NewGameState, (1.0 / ScanRateModifier.Modifier));
			ScanRateMods.Remove(idx, 1); // The scan mod was deactivated, so remove it from the list
			bUpdated = true;

			if (ScanRateMods.Length == 0)
			{
				CurrentScanRate = 1.0; // If there are no mods left, reset the scan time to the default
			}
			else
			{
				idx--; // Drop the index to account for the removed mod
			}			
		}
	}

	return bUpdated;
}

//#############################################################################################
//----------------   PERSONNEL MANAGEMENT   ---------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function StateObjectReference GetShenReference()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference EmptyRef;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == 'HeadEngineer')
		{
			return UnitState.GetReference();
		}
	}

	`Redscreen("Shen Unit Reference not found.");
	return EmptyRef;
}

//---------------------------------------------------------------------------------------
function StateObjectReference GetTyganReference()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference EmptyRef;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == 'HeadScientist')
		{
			return UnitState.GetReference();
		}
	}

	`Redscreen("Tygan Unit Reference not found.");
	return EmptyRef;
}

//---------------------------------------------------------------------------------------
function int GetCrewQuantity()
{
	// Add one for central
	return (Crew.Length + 1);
}

//---------------------------------------------------------------------------------------
function int GetNumberOfDeployableSoldiers(optional bool bExcludeWounded = false)
{
	local XComGameState_Unit Soldier;
	local int idx, iDeployable;

	iDeployable = 0;
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Soldier != none)
		{
			if(Soldier.CanGoOnMission())
			{
				if(!bExcludeWounded || !Soldier.IsInjured())
				{
					iDeployable++;
				}
			}
		}
	}

	return iDeployable;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfInjuredSoldiers()
{
	local XComGameState_Unit Soldier;
	local int idx, iInjured;

	iInjured = 0;
	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none)
		{
			if (Soldier.IsSoldier() && Soldier.IsInjured())
			{
				iInjured++;
			}
		}
	}

	return iInjured;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Unit> GetSoldiers(optional bool bDontIncludeSquad = false, optional bool bDontIncludeCovertActions = false)
{
	local XComGameState_Unit Soldier;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none)
		{
			if (Soldier.IsSoldier() && !Soldier.IsDead())
			{
				if((!bDontIncludeCovertActions || !Soldier.IsOnCovertAction()) && 
					(!bDontIncludeSquad || !IsUnitInSquad(Soldier.GetReference())))
				{
					Soldiers.AddItem(Soldier);
				}
			}
		}
	}

	return Soldiers;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Unit> GetDeployableSoldiers(optional bool bDontIncludeSquad=false, optional bool bAllowWoundedSoldiers=false, 
														 optional int MinRank = -1, optional int MaxRank = -1)
{
	local XComGameState_Unit Soldier;
	local array<XComGameState_Unit> DeployableSoldiers;
	local int idx;
	local bool bHasRankLimits;

	bHasRankLimits = (MinRank > -1 && MaxRank > -1);

	for(idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Soldier != none)
		{
			if(Soldier.CanGoOnMission(bAllowWoundedSoldiers))
			{
				if(!bDontIncludeSquad || (bDontIncludeSquad && !IsUnitInSquad(Soldier.GetReference())))
				{
					if(!bHasRankLimits || (Soldier.GetRank() >= MinRank && Soldier.GetRank() <= MaxRank))
					{
						DeployableSoldiers.AddItem(Soldier);
					}
				}
			}
		}
	}

	return DeployableSoldiers;
}

//---------------------------------------------------------------------------------------
function XComGameState_Unit GetBestDeployableSoldier(optional bool bDontIncludeSquad=false, optional bool bAllowWoundedSoldiers = false, 
													 optional int MinRank = -1, optional int MaxRank = -1)
{
	local array<XComGameState_Unit> DeployableSoldiers, ReadySoldiers;
	local int idx, HighestRank;

	DeployableSoldiers = GetDeployableSoldiers(bDontIncludeSquad, bAllowWoundedSoldiers, MinRank, MaxRank);

	if(DeployableSoldiers.Length == 0)
	{
		return none;
	}

	// We want ready soldiers above all other considerations
	for(idx = 0; idx < DeployableSoldiers.Length; idx++)
	{
		if(DeployableSoldiers[idx].GetMentalState() == eMentalState_Ready)
		{
			ReadySoldiers.AddItem(DeployableSoldiers[idx]);
		}
	}

	if(ReadySoldiers.Length > 0)
	{
		DeployableSoldiers = ReadySoldiers;
	}

	HighestRank = 0;

	for(idx = 0; idx < DeployableSoldiers.Length; idx++)
	{
		if(DeployableSoldiers[idx].GetRank() > HighestRank)
		{
			HighestRank = DeployableSoldiers[idx].GetRank();
		}
	}

	for(idx = 0; idx < DeployableSoldiers.Length; idx++)
	{
		if(DeployableSoldiers[idx].GetRank() < HighestRank)
		{
			DeployableSoldiers.Remove(idx, 1);
			idx--;
		}
	}

	return (DeployableSoldiers[`SYNC_RAND(DeployableSoldiers.Length)]);
}

//---------------------------------------------------------------------------------------
function bool HasSoldiersToPromote()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(UnitState != none)
		{
			if(UnitState.IsSoldier() && !UnitState.IsDead() && !UnitState.IsOnCovertAction() &&
				(UnitState.CanRankUpSoldier() || UnitState.HasAvailablePerksToAssign()))
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfSoldiers()
{
	local XComGameState_Unit Soldier;
	local int idx, iSoldiers;

	iSoldiers = 0;
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Soldier != none)
		{
			if(Soldier.IsSoldier() && !Soldier.IsDead())
			{
				iSoldiers++;
			}
		}
	}

	return iSoldiers;
}

function int GetNumberOfSoldiersOfTemplate(name TemplateName)
{
	local XComGameState_Unit Soldier;
	local int idx, iSoldiers;

	iSoldiers = 0;
	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none)
		{
			if (Soldier.IsSoldier() && !Soldier.IsDead() && Soldier.GetMyTemplateName() == TemplateName)
			{
				iSoldiers++;
			}
		}
	}

	return iSoldiers;
}

function StateObjectReference GetSoldierRefOfTemplate(name TemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Soldier;
	local StateObjectReference SoldierRef;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none)
		{
			if (Soldier.IsSoldier() && !Soldier.IsDead() && Soldier.GetMyTemplateName() == TemplateName)
			{
				SoldierRef.ObjectID = Crew[idx].ObjectID;
				break;
			}
		}
	}

	return SoldierRef;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfPossibleLevelUpBonds()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference BondmateRef;
	local array<StateObjectReference> CheckedUnits;
	local SoldierBond BondData;
	local int idx, iLevelUpBonds;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (UnitState.IsAlive() && UnitState.HasSoldierBond(BondmateRef, BondData))
		{
			if (BondData.BondLevel > 0 && BondData.bSoldierBondLevelUpAvailable && CheckedUnits.Find('ObjectID', BondmateRef.ObjectID) == INDEX_NONE)
			{
				iLevelUpBonds++;
			}
		}
		
		CheckedUnits.AddItem(Crew[idx]); // Ignore the unit which was just checked when they come up later in the list so each bond is only counted once
	}

	return iLevelUpBonds;
}

//---------------------------------------------------------------------------------------
function UpdateAverageFame(XComGameState NewGameState)
{
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit SoldierState;
	local int TotalFame;

	Soldiers = GetSoldiers();

	// First iterate through soldier list and calculate updated average fame score for all soldiers
	foreach Soldiers(SoldierState)
	{
		TotalFame += SoldierState.GetFame();
	}
	AverageSoldierFame = TotalFame / Soldiers.Length;

	// Then update each soldier's individual fame status if it changed
	foreach Soldiers(SoldierState)
	{
		if (SoldierState.GetFame() >= AverageSoldierFame && !SoldierState.bIsFamous)
		{
			SoldierState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XCOmGameSTate_Unit', SoldierState.ObjectID));
			SoldierState.bIsFamous = true;
		}
		else if (SoldierState.GetFame() < AverageSoldierFame && SoldierState.bIsFamous)
		{
			SoldierState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XCOmGameSTate_Unit', SoldierState.ObjectID));
			SoldierState.bIsFamous = false;
		}
	}
}

//---------------------------------------------------------------------------------------
function int GetNumberOfEngineers()
{
	local XComGameState_Unit Engineer;
	local int idx, iEngineers;

	iEngineers = -1; // Start at negative one to negate counting the head engineer
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Engineer != none)
		{
			if(Engineer.IsEngineer() && !Engineer.IsDead())
			{
				iEngineers++;
			}
		}
	}

	return iEngineers;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfUnstaffedEngineers()
{
	local XComGameState_Unit Engineer;
	local int idx, iEngineers;

	iEngineers = 0;
	for (idx = 0; idx < Crew.Length; idx++)
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Engineer != none)
		{
			if (Engineer.IsEngineer() && !Engineer.IsDead() && Engineer.StaffingSlot.ObjectID == 0 && Engineer.CanBeStaffed())
			{
				iEngineers++;
			}
		}
	}

	return iEngineers;
}

//---------------------------------------------------------------------------------------
function array<StaffUnitInfo> GetUnstaffedEngineers()
{
	local XComGameState_Unit Engineer;
	local XComGameState_StaffSlot SlotState;
	local int idx, iGhostCount;
	local array<StaffUnitInfo> UnstaffedEngineers;
	local StaffUnitInfo UnitInfo;

	for( idx = 0; idx < Crew.Length; idx++ )
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if( Engineer != none )
		{
			if (Engineer.IsEngineer() && !Engineer.IsDead())
			{
				UnitInfo.UnitRef = Engineer.GetReference();
				if (Engineer.StaffingSlot.ObjectID == 0 && Engineer.CanBeStaffed())
				{
					UnitInfo.bGhostUnit = false;
					UnstaffedEngineers.AddItem(UnitInfo);
				}
				else if (Engineer.StaffingSlot.ObjectID != 0)
				{
					SlotState = Engineer.GetStaffSlot();
					iGhostCount = SlotState.AvailableGhostStaff;
					UnitInfo.bGhostUnit = true;
					
					// Checking for available ghosts and available adjacent staff slots
					if (iGhostCount > 0 && SlotState.HasOpenAdjacentStaffSlots(UnitInfo))
					{
						while (iGhostCount > 0)
						{
							UnstaffedEngineers.AddItem(UnitInfo);
							iGhostCount--;
						}
					}
				}
			}
		}
	}

	return UnstaffedEngineers;
}
//---------------------------------------------------------------------------------------
function int GetEngineeringScore(optional bool bAddWorkshopBonus = false)
{
	local XComGameState_Unit Engineer;
	local XComGameState_FacilityXCom FacilityState;
	local int idx, Score;

	Score = default.XComHeadquarters_StartingEngineeringScore;
	Score += BonusEngineeringScore;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));
		
		if (Engineer != none)
		{
			//First check that the unit is actually a engineer and alive
			if (Engineer.IsEngineer() && !Engineer.IsDead() && !Engineer.IsInjured())
			{
				Score += Engineer.GetSkillLevel(bAddWorkshopBonus);
			}
		}
	}

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (FacilityState != none)
		{
			Score += FacilityState.GetMyTemplate().EngineeringBonus;
		}
	}

	return Score;
}

//---------------------------------------------------------------------------------------
function int GetHeadEngineerRef()
{
	local XComGameState_Unit Engineer;
	local int idx;

	for( idx = 0; idx < Crew.Length; idx++ )
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if( Engineer != none && Engineer.GetMyTemplateName() == 'HeadEngineer' )
		{
			return Engineer.ObjectID;
		}
	}

	return 0; 
}

//---------------------------------------------------------------------------------------
function int GetHeadScientistRef()
{
	local XComGameState_Unit Scientist;
	local int idx;

	for( idx = 0; idx < Crew.Length; idx++ )
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if( Scientist != none && Scientist.GetMyTemplateName() == 'HeadScientist' )
		{
			return Scientist.ObjectID;
		}
	}

	return 0;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfScientists()
{
	local XComGameState_Unit Scientist;
	local int idx, iScientists;

	iScientists = -1; // Start at negative one to negate counting the head scientist
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Scientist != none)
		{
			if(Scientist.IsScientist() && !Scientist.IsDead())
			{
				iScientists++;
			}
		}
	}

	return iScientists;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfUnstaffedScientists()
{
	local XComGameState_Unit Scientist;
	local int idx, iScientists;

	iScientists = 0;
	for (idx = 0; idx < Crew.Length; idx++)
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Scientist != none)
		{
			if (Scientist.IsScientist() && !Scientist.IsDead() && Scientist.StaffingSlot.ObjectID == 0 && Scientist.CanBeStaffed())
			{
				iScientists++;
			}
		}
	}

	return iScientists;
}

//---------------------------------------------------------------------------------------
function array<StaffUnitInfo> GetUnstaffedScientists()
{
	local XComGameState_Unit Scientist;
	local int idx;
	local array<StaffUnitInfo> UnstaffedScientists;
	local StaffUnitInfo UnitInfo;

	for( idx = 0; idx < Crew.Length; idx++ )
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if( Scientist != none )
		{
			if(Scientist.IsScientist() && !Scientist.IsDead() && Scientist.StaffingSlot.ObjectID == 0 && Scientist.CanBeStaffed())
			{
				UnitInfo.UnitRef = Scientist.GetReference();
				UnstaffedScientists.AddItem(UnitInfo);
			}
		}
	}

	return UnstaffedScientists;
}

//---------------------------------------------------------------------------------------
function int GetScienceScore(optional bool bAddLabBonus = false)
{
	local XComGameState_Unit Scientist;
	local XComGameState_FacilityXCom FacilityState;
	local int idx, Score;

	Score = default.XComHeadquarters_StartingScienceScore;
	Score += BonusScienceScore;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));
		
		if (Scientist != none)
		{
			//First check that the unit is actually a scientist and alive
			if (Scientist.IsScientist() && !Scientist.IsDead() && !Scientist.IsInjured() && !Scientist.IsOnCovertAction())
			{
				Score += Scientist.GetSkillLevel(bAddLabBonus);
			}
		}
	}

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (FacilityState != none)
		{
			Score += FacilityState.GetMyTemplate().ScienceBonus;
		}
	}

	// Start Issue #626
	return TriggerOverrideScienceScore(Score, bAddLabBonus);
	// End Issue #626
}

// Start Issue #626
//
// Fires an 'OverrideScienceScore' event that allows listeners to override
// the current science score, for example to apply bonuses or to remove scientists
// that are on other jobs. If the `AddLabBonus` is true, then the game is
// calculating the actual science score contributing to tech research progress.
// If it's false, then the game is just checking whether a tech's or item's
// science score requirement has been met.
//
// The event takes the form:
//
//  {
//     ID: OverrideScienceScore,
//     Data: [inout int ScienceScore, in bool AddLabBonus],
//     Source: self (XCGS_HeadquartersXCom)
//  }
//
// This function returns the new science score (or the original one if no listeners
// modified it).
//
function int TriggerOverrideScienceScore(int BaseScienceScore, bool AddLabBonus)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideScienceScore';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].Kind = XComLWTVInt;
	OverrideTuple.Data[0].i = BaseScienceScore;
	OverrideTuple.Data[1].Kind = XComLWTVBool;
	OverrideTuple.Data[1].b = AddLabBonus;

	`XEVENTMGR.TriggerEvent('OverrideScienceScore', OverrideTuple, self);

	return OverrideTuple.Data[0].i;
}
// End Issue #626

//---------------------------------------------------------------------------------------
native function bool IsUnitInSquad(StateObjectReference UnitRef);

//---------------------------------------------------------------------------------------
simulated function bool NeedSoldierShakenPopup(optional out array<XComGameState_Unit> UnitStates)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;
	local bool bNeedPopup;

	History = `XCOMHISTORY;
	bNeedPopup = false;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (UnitState != none)
		{
			if ((UnitState.bIsShaken && !UnitState.bSeenShakenPopup) || UnitState.bNeedsShakenRecoveredPopup)
			{
				UnitStates.AddItem(UnitState);
				bNeedPopup = true;
			}
		}
	}

	return bNeedPopup;
}

//---------------------------------------------------------------------------------------
function bool InjuredSoldiersAndNoInfirmary()
{
	local XComGameState_Unit Soldier;
	local int idx, iInjured;

	iInjured = 0;
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Soldier != none)
		{
			if(Soldier.IsSoldier() && Soldier.GetStatus() == eStatus_Healing)
			{
				iInjured++;
			}
		}
	}

	if(iInjured > 0 && !HasFacilityByName('AdvancedWarfareCenter'))
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
simulated function int GetSquadCohesionValue()
{
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local int i;

	History = `XCOMHISTORY;
	for (i = 0; i < Squad.Length; ++i)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Squad[i].ObjectID));
		if (UnitState != none)
			Units.AddItem(UnitState);
	}

	return class'X2ExperienceConfig'.static.GetSquadCohesionValue(Units);
}

//---------------------------------------------------------------------------------------
function HandlePowerOrStaffingChange(optional XComGameState NewGameState = none)
{
	local XComGameState_HeadquartersProject ProjectState;
	local int idx;
	local XComGameStateHistory History;
	local bool bSubmitGameState;

	History = `XCOMHISTORY;
	bSubmitGameState = false;

	if(NewGameState == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Handle PowerState/Staffing Change");
		bSubmitGameState = true;
	}

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ProjectState = XComGameState_HeadquartersProject(NewGameState.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ProjectState != none)
		{
			ProjectState.OnPowerStateOrStaffingChange();
		}
		else
		{
			ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));

			if(ProjectState != none)
			{
				ProjectState = XComGameState_HeadquartersProject(NewGameState.ModifyStateObject(ProjectState.Class, ProjectState.ObjectID));

				if(!ProjectState.OnPowerStateOrStaffingChange())
				{
					NewGameState.PurgeGameStateForObjectID(ProjectState.ObjectID);
				}
			}
		}
	}

	if(bSubmitGameState)
	{
		if(NewGameState.GetNumGameStateObjects() > 0)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
function bool IsUnitInCrew(StateObjectReference UnitRef)
{
	local int idx;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		if(Crew[idx] == UnitRef)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function OrderStaff(StateObjectReference UnitRef, int OrderHours)
{
	local HQOrder StaffOrder;
	
	StaffOrder.OrderRef = UnitRef;
	StaffOrder.OrderCompletionTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(StaffOrder.OrderCompletionTime, OrderHours);
	CurrentOrders.AddItem(StaffOrder);
}

//---------------------------------------------------------------------------------------
function OnStaffOrderComplete(XComGameState NewGameState, HQOrder StaffOrder)
{
	local XComGameState_Unit UnitState;
	local int OrderIndex;
	local string Notice;

	OrderIndex = CurrentOrders.Find('OrderRef', StaffOrder.OrderRef);

	if(OrderIndex != INDEX_NONE)
	{
		CurrentOrders.Remove(OrderIndex, 1);
	}

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', StaffOrder.OrderRef.ObjectID));
	`assert(UnitState != none);

	AddToCrew(NewGameState, UnitState);

	Notice = default.strStaffArrived;
	Notice = Repl(Notice, "%STAFF", UnitState.GetFullName());
	`HQPRES.Notify(Notice, class'UIUtilities_Image'.const.EventQueue_Staff);
}

//---------------------------------------------------------------------------------------
function FireStaff(StateObjectReference UnitReference)
{
	local HeadquartersOrderInputContext OrderInput;

	OrderInput.OrderType = eHeadquartersOrderType_FireStaff;
	OrderInput.AcquireObjectReference = UnitReference;

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
}

function ResetLowScientistsPopupTimer()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Low Scientists Popup Timer");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', ObjectID));
	XComHQ.LowScientistPopupTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(XComHQ.LowScientistPopupTime, default.LowScientistPopupDays);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function ResetLowEngineersPopupTimer()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Low Scientists Popup Timer");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', ObjectID));
	XComHQ.LowEngineerPopupTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(XComHQ.LowEngineerPopupTime, default.LowEngineerPopupDays);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//---------------------------------------------------------------------------------------
function bool HasBoostedSoldier()
{
	local array<XComGameState_Unit> AllSoldiers;
	local XComGameState_Unit UnitState;

	AllSoldiers = GetSoldiers();

	foreach AllSoldiers(UnitState)
	{
		if(UnitState.bRecoveryBoosted)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasBoostableSoldiers()
{
	local array<XComGameState_Unit> BoostableSoldiers;

	BoostableSoldiers = GetBoostableSoldiers();

	return (BoostableSoldiers.Length > 0);
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Unit> GetBoostableSoldiers()
{
	local array<XComGameState_Unit> AllSoldiers, BoostableSoldiers;
	local XComGameState_Unit UnitState;

	AllSoldiers = GetSoldiers();
	BoostableSoldiers.Length = 0;

	foreach AllSoldiers(UnitState)
	{
		if(UnitState.CanBeBoosted())
		{
			BoostableSoldiers.AddItem(UnitState);
		}
	}

	return BoostableSoldiers;
}

//---------------------------------------------------------------------------------------
function ResetNegativeTraitRecovery(XComGameState NewGameState)
{
	local array<XComGameState_Unit> AllSoldiers;
	local XComGameState_Unit UnitState;
	
	AllSoldiers = GetSoldiers();
	
	foreach AllSoldiers(UnitState)
	{
		if(UnitState.NegativeTraits.Length > 0)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.ResetTraitRecovery();
		}
	}
}

//#############################################################################################
//----------------   FACILITY MANAGEMENT   ----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool HasFacilityByName(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if(FacilityTemplate != none)
	{
		return HasFacility(FacilityTemplate);
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasFacilityUpgradeByName(name UpgradeName)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local int idx;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		for(idx = 0; idx < FacilityState.Upgrades.Length; idx++)
		{
			UpgradeState = XComGameState_FacilityUpgrade(History.GetGameStateForObjectID(FacilityState.Upgrades[idx].ObjectID));

			if(UpgradeState != none && UpgradeState.GetMyTemplateName() == UpgradeName)
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityByName(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if(FacilityTemplate != none)
	{
		return GetFacility(FacilityTemplate);
	}

	return none;
}

//---------------------------------------------------------------------------------------
function X2FacilityTemplate GetFacilityTemplate(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if (FacilityTemplate != none)
	{
		return FacilityTemplate;
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool HasFacility(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local int idx;

	for(idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacility(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local int idx;

	for(idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			return Facility;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityWithOpenStaffSlots(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local int idx;

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			if (Facility.GetNumEmptyStaffSlots() > 0)
			{
				return Facility;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityByNameWithOpenStaffSlots(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if (FacilityTemplate != none)
	{
		return GetFacilityWithOpenStaffSlots(FacilityTemplate);
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityWithAvailableStaffSlots(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local int idx;

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			if (Facility.GetNumLockedStaffSlots() > 0 || Facility.GetNumEmptyStaffSlots() > 0)
			{
				return Facility;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityByNameWithAvailableStaffSlots(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if (FacilityTemplate != none)
	{
		return GetFacilityWithAvailableStaffSlots(FacilityTemplate);
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool HasEmptyEngineerSlotsAvailable()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local int idx;
	
	for (idx = 0; idx < Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if (!Room.Locked && Room.HasSpecialFeature() && !Room.bSpecialRoomFeatureCleared && Room.GetNumEmptyBuildSlots() > 0)
		{
			StaffSlot = Room.GetBuildSlot(Room.GetEmptyBuildSlotIndex());
			if (StaffSlot.IsEngineerSlot())
			{
				return true;
			}
		}
		else if (Room.UnderConstruction && Room.GetNumEmptyBuildSlots() > 0)
		{
			StaffSlot = Room.GetBuildSlot(Room.GetEmptyBuildSlotIndex());
			if (StaffSlot.IsEngineerSlot())
			{
				return true;
			}
		}
	}

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (Facility.GetNumEmptyStaffSlots() > 0)
		{
			StaffSlot = Facility.GetStaffSlot(Facility.GetEmptyStaffSlotIndex());
			if (StaffSlot.IsEngineerSlot())
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_StaffSlot> GetAllEmptyStaffSlotsForUnit(XComGameState_Unit UnitState)
{
	local array<XComGameState_StaffSlot> arrStaffSlots;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local StaffUnitInfo UnitInfo;
	local int idx;
	local bool bExcavationSlotAdded;

	UnitInfo.UnitRef = UnitState.GetReference();

	for (idx = 0; idx < Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if (!bExcavationSlotAdded && !Room.Locked && Room.HasSpecialFeature() && !Room.bSpecialRoomFeatureCleared && Room.GetNumEmptyBuildSlots() > 0)
		{
			StaffSlot = Room.GetBuildSlot(Room.GetEmptyBuildSlotIndex());
			if (StaffSlot.ValidUnitForSlot(UnitInfo))
			{
				arrStaffSlots.AddItem(StaffSlot);
				bExcavationSlotAdded = true; // only add one excavation slot per list
			}
		}
		else if (Room.UnderConstruction && Room.GetNumEmptyBuildSlots() > 0)
		{
			StaffSlot = Room.GetBuildSlot(Room.GetEmptyBuildSlotIndex());
			if (StaffSlot.ValidUnitForSlot(UnitInfo))
			{
				arrStaffSlots.AddItem(StaffSlot);
			}
		}
	}

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (Facility.GetNumEmptyStaffSlots() > 0)
		{
			StaffSlot = Facility.GetStaffSlot(Facility.GetEmptyStaffSlotIndex());
			if (StaffSlot.ValidUnitForSlot(UnitInfo))
			{
				arrStaffSlots.AddItem(StaffSlot);
			}
		}
	}

	return arrStaffSlots;
}

//---------------------------------------------------------------------------------------
function bool IsBuildingFacility(X2FacilityTemplate FacilityTemplate)
{
	return IsBuildingFacilityByName(FacilityTemplate.DataName);
}

//---------------------------------------------------------------------------------------
function bool IsBuildingFacilityByName(name FacilityName)
{
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local int idx;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (FacilityProject != none)
		{
			Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityProject.ProjectFocus.ObjectID));

			if (Facility != none)
			{
				if (Facility.GetMyTemplateName() == FacilityName)
				{
					return true;
				}
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function int GetNumberBuildingOfFacilitiesOfType(X2FacilityTemplate FacilityTemplate)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local int idx, Total;

	History = `XCOMHISTORY;
	Total = 0;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(FacilityProject != none)
		{
			Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityProject.ProjectFocus.ObjectID));

			if(Facility != none)
			{
				if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
				{
					Total++;
				}
			}
		}
	}

	return Total;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfFacilitiesOfType(X2FacilityTemplate FacilityTemplate)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;
	local int idx, iTotal;

	History = `XCOMHISTORY;
	iTotal = 0;
	for(idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			iTotal++;
		}
	}

	return iTotal;
}

//---------------------------------------------------------------------------------------
function int GetFacilityUpkeepCost()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;
	local int idx, iUpkeep;

	History = `XCOMHISTORY;
	iUpkeep = 0;
	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Facilities[idx].ObjectID));
		iUpkeep += Facility.UpkeepCost;
	}

	return iUpkeep;
}

//---------------------------------------------------------------------------------------
function bool HasEmptyRoom()
{
	local XComGameState_HeadquartersRoom RoomState;
	local int idx;

	for(idx = 0; idx < Rooms.Length; idx++)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if(RoomState != none)
		{
			if(!RoomState.HasFacility() && !RoomState.ConstructionBlocked)
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasUnexcavatedRoom()
{
	local XComGameState_HeadquartersRoom RoomState;
	local int idx;

	for (idx = 0; idx < Rooms.Length; idx++)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if (RoomState != none)
		{
			if (!RoomState.HasFacility() && RoomState.ConstructionBlocked)
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasShieldedPowerCoil()
{
	local XComGameState_HeadquartersRoom RoomState;
	local int idx;

	for (idx = 0; idx < Rooms.Length; idx++)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if (RoomState != none && RoomState.HasShieldedPowerCoil())
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersRoom GetRoom(int Index)
{
	local int idx;
	local XComGameState_HeadquartersRoom Room;

	for(idx = 0; idx < Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if(Room.MapIndex == Index)
		{
			return Room;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersRoom GetRoomFromFacility(StateObjectReference FacilityRef)
{
	local int idx;
	local XComGameState_HeadquartersRoom Room;

	for(idx = 0; idx < Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));
		if(Room.Facility == FacilityRef)
			return Room;
	}

	return none;
}

//---------------------------------------------------------------------------------------
static function UnlockAdjacentRooms(XComGameState NewGameState, XComGameState_HeadquartersRoom Room)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom RoomToUnlock;
	local int AdjustedMapIndex, GridStartIndex, GridEndIndex, NumRooms;

	GridStartIndex = 3;
	GridEndIndex = 14;
	AdjustedMapIndex = Room.MapIndex - GridStartIndex;
	NumRooms = GridEndIndex - GridStartIndex + 1;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (AdjustedMapIndex % default.XComHeadquarters_RoomRowLength != 0) // not in the left hand column, so unlock the room to the left
	{
		RoomToUnlock = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', XComHQ.Rooms[Room.MapIndex - 1].ObjectID));
		RoomToUnlock.Locked = false;
	}

	if (AdjustedMapIndex % default.XComHeadquarters_RoomRowLength != (default.XComHeadquarters_RoomRowLength - 1)) // not in the right hand column, so unlock the room to the right
	{
		RoomToUnlock = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', XComHQ.Rooms[Room.MapIndex + 1].ObjectID));
		RoomToUnlock.Locked = false;
	}

	if (AdjustedMapIndex >= default.XComHeadquarters_RoomRowLength) // not in the top row, so unlock the room above
	{
		RoomToUnlock = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', XComHQ.Rooms[Room.MapIndex - default.XComHeadquarters_RoomRowLength].ObjectID));
		RoomToUnlock.Locked = false;
	}

	if (AdjustedMapIndex <= (NumRooms - default.XComHeadquarters_RoomRowLength)) // not in the bottom row, so unlock the room below
	{
		RoomToUnlock = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', XComHQ.Rooms[Room.MapIndex + default.XComHeadquarters_RoomRowLength].ObjectID));
		RoomToUnlock.Locked = false;
	}
}

//---------------------------------------------------------------------------------------
function AddFacilityProject(StateObjectReference RoomRef, X2FacilityTemplate FacilityTemplate)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityStateObject;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_HeadquartersProjectBuildFacility BuildProject;
	local XComGameState_StaffSlot BuildSlotState;
	local XComNarrativeMoment BuildStartedNarrative;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Facility Project");
	FacilityStateObject = FacilityTemplate.CreateInstanceFromTemplate(NewGameState);

	RoomState = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', RoomRef.ObjectID));
	RoomState.UnderConstruction = true;
	RoomState.UpdateRoomMap = true;
		
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
	
	BuildProject = XComGameState_HeadquartersProjectBuildFacility(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectBuildFacility'));
	BuildProject.SetProjectFocus(FacilityStateObject.GetReference(), NewGameState, RoomRef);
	BuildProject.SavedDiscountPercent = XComHQ.GetPendingFacilityDiscountPercent( FacilityTemplate.DataName );

	XComHQ.Projects.AddItem(BuildProject.GetReference());
	XComHQ.RemovePendingFacilityDiscountPercent( FacilityTemplate.DataName );

	XComHQ.PayStrategyCost(NewGameState, FacilityTemplate.Cost, FacilityBuildCostScalars, BuildProject.SavedDiscountPercent);
	
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Facility_Build");

	`XEVENTMGR.TriggerEvent('ConstructionStarted', BuildProject, BuildProject, NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if(FacilityTemplate.ConstructionStartedNarrative != "")
	{
		BuildStartedNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityTemplate.ConstructionStartedNarrative));
		if(BuildStartedNarrative != None)
		{
			`HQPRES.UINarrative(BuildStartedNarrative);
		}
	}
	
	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
	
	// If an unstaffed engineer exists, alert the player that they could help build this facility
	BuildSlotState = RoomState.GetBuildSlot(0);
	if (BuildSlotState.IsEngineerSlot() && (XComHQ.GetNumberOfUnstaffedEngineers() > 0 || BuildSlotState.HasAvailableAdjacentGhosts()))
	{
		`HQPRES.UIBuildSlotOpen(RoomState.GetReference());
	}

	// Refresh XComHQ and see if we need to display a power warning
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.PowerState == ePowerState_Red && FacilityStateObject.GetPowerOutput() < 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Warning No Power");
		`XEVENTMGR.TriggerEvent('WarningNoPower', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	
	// force avenger rooms to update
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

//---------------------------------------------------------------------------------------
function String GetFacilityBuildEstimateString(StateObjectReference RoomRef, X2FacilityTemplate FacilityTemplate)
{
	local int  iHours, iDaysLeft;
	local XGParamTag kTag;
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectBuildFacility BuildProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");

	FacilityState = FacilityTemplate.CreateInstanceFromTemplate(NewGameState);

	BuildProject = XComGameState_HeadquartersProjectBuildFacility(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectBuildFacility'));
	BuildProject.SetProjectFocus(FacilityState.GetReference(), NewGameState, RoomRef);

	iHours = BuildProject.GetProjectedNumHoursRemaining();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	iDaysLeft = class'X2StrategyGameRulesetDataStructures'.static.HoursToDays(iHours);

	if(iDaysLeft < 0)
	{
		iDaysLeft = 1;
	}

	kTag.IntValue0 = iDaysLeft;

	NewGameState.PurgeGameStateForObjectID(BuildProject.ObjectID);
	NewGameState.PurgeGameStateForObjectID(FacilityState.ObjectID);
	History.CleanupPendingGameState(NewGameState);

	return `XEXPAND.ExpandString((iDaysLeft != 1) ? strETADays : strETADay);
}

//---------------------------------------------------------------------------------------
function String GetFacilityBuildEngineerEstimateString(StateObjectReference BuildSlotRef, StateObjectReference EngineerRef)
{
	local int  iHours, iDaysLeft;
	local XGParamTag kTag;
	local XComGameState NewGameState;
	local XComGameState_StaffSlot SlotState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectBuildFacility BuildProject;
	local bool bProjectFound;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");

	SlotState = XComGameState_StaffSlot(NewGameState.ModifyStateObject(class'XComGameState_StaffSlot', BuildSlotRef.ObjectID));
	SlotState.AssignedStaff.UnitRef = EngineerRef;
	bProjectFound = false;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectBuildFacility', BuildProject)
	{
		if(BuildProject.AuxilaryReference == SlotState.Room)
		{
			BuildProject = XComGameState_HeadquartersProjectBuildFacility(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectBuildFacility', BuildProject.ObjectID));
			BuildProject.UpdateWorkPerHour(NewGameState);
			bProjectFound = true;
			break;
		}
	}
	
	if(bProjectFound)
	{
		iHours = BuildProject.GetProjectedNumHoursRemaining();

		kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		iDaysLeft = class'X2StrategyGameRulesetDataStructures'.static.HoursToDays(iHours);

		if(iDaysLeft < 0)
		{
			iDaysLeft = 1;
		}

		kTag.IntValue0 = iDaysLeft;

		History.CleanupPendingGameState(NewGameState);

		return `XEXPAND.ExpandString((iDaysLeft != 1) ? strETADays : strETADay);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
		return "ERROR BUILD PROJECT NOT FOUND";
	}
	
}

//---------------------------------------------------------------------------------------
function CancelFacilityProject(XComGameState_HeadquartersProjectBuildFacility FacilityProject)
{
	local HeadquartersOrderInputContext OrderInput;

	OrderInput.OrderType = eHeadquartersOrderType_CancelFacilityConstruction;
	OrderInput.AcquireObjectReference = FacilityProject.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();

	// force refresh of rooms
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectBuildFacility GetFacilityProject(StateObjectReference RoomRef)
{
	local int iProject;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for(iProject = 0; iProject < Projects.Length; iProject++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(Projects[iProject].ObjectID));

		if(FacilityProject != none)
		{
			if(RoomRef == FacilityProject.AuxilaryReference)
			{
				return FacilityProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function CancelClearRoomProject(XComGameState_HeadquartersProjectClearRoom ClearRoomProject)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersRoom Room;
	local HeadquartersOrderInputContext OrderInput;
	local X2SpecialRoomFeatureTemplate SpecialRoomTemplate;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Refund Special Feature Project");
	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(ClearRoomProject.ProjectFocus.ObjectID));
	SpecialRoomTemplate = Room.GetSpecialFeature();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
	XComHQ.RefundStrategyCost(NewGameState, SpecialRoomTemplate.GetDepthBasedCostFn(Room), RoomSpecialFeatureCostScalars);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	OrderInput.OrderType = eHeadquartersOrderType_CancelClearRoom;
	OrderInput.AcquireObjectReference = ClearRoomProject.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	// force refresh of rooms
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectClearRoom GetClearRoomProject(StateObjectReference RoomRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectClearRoom ClearRoomProject;
		
	for (idx = 0; idx < Projects.Length; idx++)
	{
		ClearRoomProject = XComGameState_HeadquartersProjectClearRoom(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ClearRoomProject != none)
		{
			if (RoomRef == ClearRoomProject.ProjectFocus)
			{
				return ClearRoomProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function CancelUpgradeFacilityProject(XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityUpgrade Upgrade;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local HeadquartersOrderInputContext OrderInput;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Refund Facility Upgrade Project");
	Upgrade = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(UpgradeProject.ProjectFocus.ObjectID));
	UpgradeTemplate = Upgrade.GetMyTemplate();
	RefundStrategyCost(NewGameState, UpgradeTemplate.Cost, FacilityUpgradeCostScalars);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	OrderInput.OrderType = eHeadquartersOrderType_CancelUpgradeFacility;
	OrderInput.AcquireObjectReference = UpgradeProject.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	// force refresh of rooms
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectUpgradeFacility GetUpgradeFacilityProject(StateObjectReference FacilityRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeFacilityProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		UpgradeFacilityProject = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (UpgradeFacilityProject != none)
		{
			if (FacilityRef == UpgradeFacilityProject.AuxilaryReference)
			{
				return UpgradeFacilityProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectTrainRookie GetTrainRookieProject(StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectTrainRookie TrainRookieProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		TrainRookieProject = XComGameState_HeadquartersProjectTrainRookie(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (TrainRookieProject != none)
		{
			if (UnitRef == TrainRookieProject.ProjectFocus)
			{
				return TrainRookieProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectRespecSoldier GetRespecSoldierProject(StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectRespecSoldier RespecSoldierProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		RespecSoldierProject = XComGameState_HeadquartersProjectRespecSoldier(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (RespecSoldierProject != none)
		{
			if (UnitRef == RespecSoldierProject.ProjectFocus)
			{
				return RespecSoldierProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectRemoveTraits GetRemoveTraitsProject(StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectRemoveTraits RemoveTraitsProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		RemoveTraitsProject = XComGameState_HeadquartersProjectRemoveTraits(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (RemoveTraitsProject != none)
		{
			if (UnitRef == RemoveTraitsProject.ProjectFocus)
			{
				return RemoveTraitsProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectPsiTraining GetPsiTrainingProject(StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		PsiProject = XComGameState_HeadquartersProjectPsiTraining(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (PsiProject != none)
		{
			if (UnitRef == PsiProject.ProjectFocus)
			{
				return PsiProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool HasPausedPsiAbilityTrainingProject(StateObjectReference UnitRef, SoldierAbilityInfo AbilityInfo)
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectPsiTraining PsiTrainingProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		PsiTrainingProject = XComGameState_HeadquartersProjectPsiTraining(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (PsiTrainingProject != none && PsiTrainingProject.ProjectFocus == UnitRef &&
			PsiTrainingProject.iAbilityRank == AbilityInfo.iRank && PsiTrainingProject.iAbilityBranch == AbilityInfo.iBranch)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectPsiTraining GetPausedPsiAbilityTrainingProject(StateObjectReference UnitRef, SoldierAbilityInfo AbilityInfo)
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectPsiTraining PsiTrainingProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		PsiTrainingProject = XComGameState_HeadquartersProjectPsiTraining(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (PsiTrainingProject != none && PsiTrainingProject.ProjectFocus == UnitRef &&
			PsiTrainingProject.iAbilityRank == AbilityInfo.iRank && PsiTrainingProject.iAbilityBranch == AbilityInfo.iBranch)
		{
			return PsiTrainingProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool HasActiveConstructionProject()
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectClearRoom ClearRoomProject;
	local XComGameState_HeadquartersProjectBuildFacility BuildFacilityProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ClearRoomProject = XComGameState_HeadquartersProjectClearRoom(History.GetGameStateForObjectID(Projects[idx].ObjectID));
		BuildFacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ClearRoomProject != none || BuildFacilityProject != none)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectBondSoldiers GetBondSoldiersProjectForUnit(StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectBondSoldiers BondSoldiersProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		BondSoldiersProject = XComGameState_HeadquartersProjectBondSoldiers(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (BondSoldiersProject != none)
		{
			if (UnitRef == BondSoldiersProject.ProjectFocus || UnitRef == BondSoldiersProject.AuxilaryReference)
			{
				return BondSoldiersProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool HasBondSoldiersProjectForUnit(StateObjectReference UnitRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectBondSoldiers BondSoldiersProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		BondSoldiersProject = XComGameState_HeadquartersProjectBondSoldiers(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (BondSoldiersProject != none)
		{
			if (UnitRef == BondSoldiersProject.ProjectFocus || UnitRef == BondSoldiersProject.AuxilaryReference)
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasBondSoldiersProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectBondSoldiers BondProject;
	local int iProject;

	History = `XCOMHISTORY;

	for (iProject = 0; iProject < Projects.Length; iProject++)
	{
		BondProject = XComGameState_HeadquartersProjectBondSoldiers(History.GetGameStateForObjectID(Projects[iProject].ObjectID));

		if (BondProject != none)
		{
			return true;
		}
	}

	return false;
}

//#############################################################################################
//----------------   INVENTORY MANAGEMENT   ---------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool HasItem(X2ItemTemplate ItemTemplate, optional int Quantity = 1)
{
	local XComGameState_Item ItemState;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;


	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplateName() == ItemTemplate.DataName && ItemState.Quantity >= Quantity)
			{
				return true;
			}
		}
	}

	return false;
}



//---------------------------------------------------------------------------------------
function bool HasItemByName(name ItemTemplateName)
{
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemTemplateName);

	if( ItemTemplate != none )
	{
		return HasItem(ItemTemplate);
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasItemInInventoryOrLoadout(X2ItemTemplate ItemTemplate, optional int Quantity = 1)
{
	local array<XComGameState_Unit> Soldiers;
	local int iSoldier;
	
	if (HasItem(ItemTemplate, Quantity))
	{
		return true;
	}

	Soldiers = GetSoldiers();
	for (iSoldier = 0; iSoldier < Soldiers.Length; iSoldier++)
	{
		if (Soldiers[iSoldier].HasItemOfTemplateType(ItemTemplate.DataName))
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasUnModifiedItem(XComGameState AddToGameState, X2ItemTemplate ItemTemplate, out XComGameState_Item ItemState, optional bool bLoot = false, optional XComGameState_Item CombatSimTest)
{
	local int idx;

	if(bLoot)
	{
		for(idx = 0; idx < LootRecovered.Length; idx++)
		{
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(LootRecovered[idx].ObjectID));

			if(ItemState == none)
			{
				ItemState = XComGameState_Item(AddToGameState.GetGameStateForObjectID(LootRecovered[idx].ObjectID));
			}

			if(ItemState != none)
			{
				if (ItemState.GetMyTemplateName() == ItemTemplate.DataName && (ItemState.Quantity > 0 || ItemState.GetMyTemplate().ItemCat == 'resource') && !ItemState.HasBeenModified())
				{
					if(ItemState.GetMyTemplate().ItemCat == 'combatsim')
					{
						if(ItemState.StatBoosts.Length > 0 && CombatSimTest.StatBoosts.Length > 0 && ItemState.StatBoosts[0].Boost == CombatSimTest.StatBoosts[0].Boost && ItemState.StatBoosts[0].StatType == CombatSimTest.StatBoosts[0].StatType)
						{
							return true;
						}
					}
					else
					{
						return true;
					}
				}
			}
		}
	}
	else
	{
		for(idx = 0; idx < Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

			if(ItemState == none)
			{
				ItemState = XComGameState_Item(AddToGameState.GetGameStateForObjectID(Inventory[idx].ObjectID));
			}

			if(ItemState != none)
			{
				if (ItemState.GetMyTemplateName() == ItemTemplate.DataName && (ItemState.Quantity > 0 || ItemState.GetMyTemplate().ItemCat == 'resource') && !ItemState.HasBeenModified())
				{
					if(ItemState.GetMyTemplate().ItemCat == 'combatsim')
					{
						if(ItemState.StatBoosts.Length > 0 && CombatSimTest.StatBoosts.Length > 0 && ItemState.StatBoosts[0].Boost == CombatSimTest.StatBoosts[0].Boost && ItemState.StatBoosts[0].StatType == CombatSimTest.StatBoosts[0].StatType)
						{
							return true;
						}
					}
					else
					{
						return true;
					}
				}
			}
		}
	}
	
	return false;
}

//---------------------------------------------------------------------------------------
// returns true if HQ has been modified (you need to update the gamestate)
function bool PutItemInInventory(XComGameState AddToGameState, XComGameState_Item ItemState, optional bool bLoot = false)
{
	local bool HQModified;
	local XComGameState_Item InventoryItemState, NewInventoryItemState;
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = ItemState.GetMyTemplate();

	if( ItemState.HasBeenModified() || ItemTemplate.bAlwaysUnique )
	{
		HQModified = true;

		if(bLoot)
		{
			LootRecovered.AddItem(ItemState.GetReference());
		}
		else
		{
			AddItemToHQInventory(ItemState);
		}
	}
	else
	{
		if(!ItemState.GetMyTemplate().bInfiniteItem)
		{
			if( HasUnModifiedItem(AddToGameState, ItemTemplate, InventoryItemState, bLoot, ItemState) )
			{
				HQModified = false;
				
				if(InventoryItemState.ObjectID != ItemState.ObjectID)
				{
					NewInventoryItemState = XComGameState_Item(AddToGameState.ModifyStateObject(class'XComGameState_Item', InventoryItemState.ObjectID));
					NewInventoryItemState.Quantity += ItemState.Quantity;
				}
			}
			else
			{
				HQModified = true;

				if(bLoot)
				{
					LootRecovered.AddItem(ItemState.GetReference());
				}
				else
				{
					AddItemToHQInventory(ItemState);
				}
			}
		}
		else
		{
			HQModified = false;
			AddToGameState.RemoveStateObject(ItemState.ObjectID);
		}
	}

	if( !bLoot && (ItemTemplate.OnAcquiredFn != None) && ItemTemplate.HideInInventory )
	{
		HQModified = ItemTemplate.OnAcquiredFn(AddToGameState, ItemState) || HQModified;
	}

	// this item awards other items when acquired
	if( !bLoot && ItemTemplate.ResourceTemplateName != '' && ItemTemplate.ResourceQuantity > 0 )
	{
		ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemTemplate.ResourceTemplateName);
		ItemState = ItemTemplate.CreateInstanceFromTemplate(AddToGameState);
		ItemState.Quantity = ItemTemplate.ResourceQuantity;

		if( ItemState != none )
		{
			HQModified = PutItemInInventory(AddToGameState, ItemState) || HQModified;
		}
	}

	return HQModified;
}

function AddItemToHQInventory(XComGameState_Item ItemState)
{
	local Name ItemTemplateName;
	local int EverAcquireInventoryIndex;

	ItemTemplateName = ItemState.GetMyTemplateName();

	EverAcquireInventoryIndex = EverAcquiredInventoryTypes.Find(ItemTemplateName);
	if( EverAcquireInventoryIndex == INDEX_NONE )
	{
		EverAcquiredInventoryTypes.AddItem(ItemTemplateName);
		EverAcquiredInventoryCounts.AddItem(ItemState.Quantity);
	}
	else
	{
		EverAcquiredInventoryCounts[EverAcquireInventoryIndex] += ItemState.Quantity;
	}

	Inventory.AddItem(ItemState.GetReference());
}

function bool UnpackCacheItems(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate, UnpackedItemTemplate;
	local bool bXComHQModified;
	local int i;

	History = `XCOMHISTORY;

	// Open up any caches we received and add their contents to the loot list
	for (i = 0; i < LootRecovered.Length; i++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(LootRecovered[i].ObjectID));
		ItemTemplate = ItemState.GetMyTemplate();

		// this item awards other items when acquired
		if (ItemTemplate.ResourceTemplateName != '' && ItemTemplate.ResourceQuantity > 0)
		{
			UnpackedItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemTemplate.ResourceTemplateName);
			ItemState = UnpackedItemTemplate.CreateInstanceFromTemplate(NewGameState);
			ItemState.Quantity = ItemTemplate.ResourceQuantity;

			if (ItemState != none)
			{
				// Remove the cache item which was opened
				LootRecovered.Remove(i, 1);
				i--;

				// Then add whatever it gave us
				LootRecovered.AddItem(ItemState.GetReference());
				bXComHQModified = true;
			}
		}
	}

	return bXComHQModified;
}

//---------------------------------------------------------------------------------------
// 
function XComGameState_Item GetItemByName(name ItemTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_Item InventoryItemState;
	local int i;

	History = `XCOMHISTORY;

	for( i = 0; i < Inventory.Length; i++ )
	{
		InventoryItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[i].ObjectId));

		if( InventoryItemState != none && InventoryItemState.GetMyTemplateName() == ItemTemplateName )
		{
			return InventoryItemState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function int GetNumItemInInventory(name ItemTemplateName)
{
	local XComGameState_Item ItemState;

	ItemState = GetItemByName(ItemTemplateName);
	if (ItemState != none)
	{
		return ItemState.Quantity;
	}

	return 0;
}

//---------------------------------------------------------------------------------------
// returns true if HQ has been modified (you need to update the gamestate)
// ItemRef is StateObjectReference of item in inventory, ItemState is the item you are getting
function bool GetItemFromInventory(XComGameState AddToGameState, StateObjectReference ItemRef, out XComGameState_Item ItemState)
{
	local XComGameState_Item InventoryItemState;
	local bool HQModified;

	InventoryItemState = XComGameState_Item(AddToGameState.GetGameStateForObjectID(ItemRef.ObjectID));
	if (InventoryItemState == none)
	{
		InventoryItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
	}

	if(InventoryItemState != none)
	{
		if(!InventoryItemState.GetMyTemplate().bInfiniteItem || InventoryItemState.HasBeenModified())
		{
			if(InventoryItemState.Quantity > 1)
			{
				HQModified = false;
				InventoryItemState = XComGameState_Item(AddToGameState.ModifyStateObject(class'XComGameState_Item', InventoryItemState.ObjectID));
				InventoryItemState.Quantity--;
				ItemState = XComGameState_Item(AddToGameState.CreateNewStateObject(class'XComGameState_Item', InventoryItemState.GetMyTemplate()));
				ItemState.StatBoosts = InventoryItemState.StatBoosts; // Make sure the stat boosts are the same. Used for PCS.
			}
			else
			{
				HQModified = true;
				Inventory.RemoveItem(ItemRef);
				ItemState = XComGameState_Item(AddToGameState.ModifyStateObject(class'XComGameState_Item', InventoryItemState.ObjectID));
			}
		}
		else
		{
			HQModified = false;
			ItemState = XComGameState_Item(AddToGameState.CreateNewStateObject(class'XComGameState_Item', InventoryItemState.GetMyTemplate()));
		}
	}

	return HQModified;
}

//---------------------------------------------------------------------------------------
// returns true if HQ has been modified (you need to update the gamestate)
// ItemRef is StateObjectReference of item in inventory, Quantity is how many to remove
function bool RemoveItemFromInventory(XComGameState AddToGameState, StateObjectReference ItemRef, int Quantity)
{
	local XComGameState_Item InventoryItemState, NewInventoryItemState;
	local bool HQModified;

	InventoryItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));

	if(InventoryItemState != none)
	{
		if(!InventoryItemState.GetMyTemplate().bInfiniteItem)
		{
			if (ResourceItems.Find(InventoryItemState.GetMyTemplateName()) != INDEX_NONE) // If this item is a resource, use the AddResource method instead
			{
				AddResource(AddToGameState, InventoryItemState.GetMyTemplateName(), -1*Quantity);
			}
			else if(InventoryItemState.Quantity > Quantity)
			{
				HQModified = false;
				NewInventoryItemState = XComGameState_Item(AddToGameState.ModifyStateObject(class'XComGameState_Item', InventoryItemState.ObjectID));
				NewInventoryItemState.Quantity -= Quantity;
			}
			else
			{
				HQModified = true;
				Inventory.RemoveItem(ItemRef);
			}
		}
		else
		{
			return false;
		}
	}

	return HQModified;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Item> GetAllCombatSimsInInventory()
{
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> AllCombatSims;
	local int idx;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplate().ItemCat == 'combatsim')
			{
				AllCombatSims.AddItem(ItemState);
			}
		}
	}

	return AllCombatSims;
}

function bool HasCombatSimsInInventory()
{
	local array<XComGameState_Item> AllCombatSims;
	AllCombatSims = GetAllCombatSimsInInventory();
	return AllCombatSims.Length > 0;
}

//---------------------------------------------------------------------------------------

function array<XComGameState_Item> GetAllWeaponUpgradesInInventory()
{
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> AllWeaponUpgrades;
	local int idx;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplate().ItemCat == 'upgrade')
			{
				AllWeaponUpgrades.AddItem(ItemState);
			}
		}
	}

	return AllWeaponUpgrades;
}

function bool HasWeaponUpgradesInInventory()
{
	local array<XComGameState_Item> AllWeaponUpgrades;
	AllWeaponUpgrades = GetAllWeaponUpgradesInInventory();
	return AllWeaponUpgrades.Length > 0;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetTradingPostItems()
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local array<StateObjectReference> TradingPostItems;
	local int idx;

	History = `XCOMHISTORY;
	TradingPostItems.Length = 0;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplate().TradingPostValue > 0 && !ItemState.GetMyTemplate().bInfiniteItem && !ItemState.IsNeededForGoldenPath())
			{
				TradingPostItems.AddItem(ItemState.GetReference());
			}
		}
	}

	//<workshop> BLACK_MARKET_FIXES, BET, 2016-04-22
	//INS:
	class'XComGameState_Item'.static.FilterOutGoldenPathItems(TradingPostItems);
	//</workshop>

	return TradingPostItems;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Item> GetReverseEngineeringItems()
{
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> ReverseEngineeringItems;
	local int idx;

	ReverseEngineeringItems.Length = 0;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplate().ReverseEngineeringValue > 0)
			{
				ReverseEngineeringItems.AddItem(ItemState);
			}
		}
	}

	return ReverseEngineeringItems;
}

//---------------------------------------------------------------------------------------
function int GetItemBuildTime(X2ItemTemplate ItemTemplate, StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Item ItemState;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local int BuildHours;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT HAVE SUBMITTED");
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

	ItemProject = XComGameState_HeadquartersProjectBuildItem(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectBuildItem'));
	ItemProject.SetProjectFocus(ItemState.GetReference(), NewGameState, FacilityRef);

	if (!ItemProject.bInstant)
		BuildHours = ItemProject.GetProjectedNumHoursRemaining();
	else
		BuildHours = 0;

	NewGameState.PurgeGameStateForObjectID(ItemState.ObjectID);
	NewGameState.PurgeGameStateForObjectID(ItemProject.ObjectID);
	History.CleanupPendingGameState(NewGameState);

	return BuildHours;
}

//---------------------------------------------------------------------------------------
function int GetNumItemBeingBuilt(X2ItemTemplate ItemTemplate)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local int idx, iCount;

	History = `XCOMHISTORY;
	iCount = 0;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ItemProject = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ItemProject != none)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemProject.ProjectFocus.ObjectID));

			if(ItemState != none)
			{
				if(ItemState.GetMyTemplateName() == ItemTemplate.DataName)
				{
					iCount++;
				}
			}
		}
	}

	return iCount;
}

// Used by schematics and techs to upgrade all of the instances of an item based on a creator template
static function UpgradeItems(XComGameState NewGameState, name CreatorTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate BaseItemTemplate, UpgradeItemTemplate;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local XComGameState_Item InventoryItemState, BaseItemState, UpgradedItemState;
	local array<X2ItemTemplate> CreatedItems, ItemsToUpgrade;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local array<XComGameState_Item> InventoryItems;
	local array<XComGameState_Unit> Soldiers;
	local array<StateObjectReference> InventoryItemRefs;
	local EInventorySlot InventorySlot;
	local XComGameState_Unit SoldierState, HighestRankSoldier;
	local int idx, iSoldier, iItems;
	local Object constRef;

	History = `XCOMHISTORY;
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	CreatedItems = ItemTemplateManager.GetAllItemsCreatedByTemplate(CreatorTemplateName);

	for (idx = 0; idx < CreatedItems.Length; idx++)
	{
		UpgradeItemTemplate = CreatedItems[idx];

		ItemsToUpgrade.Length = 0; // Reset ItemsToUpgrade for this upgrade item iteration
		GetItemsToUpgrade(UpgradeItemTemplate, ItemsToUpgrade);

		// If the new item is infinite, just add it directly to the inventory
		if (UpgradeItemTemplate.bInfiniteItem)
		{
			// But only add the infinite item if it isn't already in the inventory
			if (!XComHQ.HasItem(UpgradeItemTemplate))
			{
				UpgradedItemState = UpgradeItemTemplate.CreateInstanceFromTemplate(NewGameState);
				
				/// HL-Docs: feature:ItemUpgraded; issue:289; tags:strategy
				/// This is an event that allows mods to perform non-standard handling to item states
				/// when they are upgraded to a new tier. It is fired up to four times during upgrading:
				/// * When upgrading the infinite item, if any.
				/// * When upgrading utility items, like grenades and medkits.
				/// * When upgrading unequipped items that have attachments
				/// * When upgrading equipped items that have attachments
				///
				/// Note: EventSource (BaseItem) will be `none` when the event is triggered by upgrading an infinite item.
				/// This is because infinite items are created rather than upgraded.
				/// ```event
				/// EventID: ItemUpgraded,
				/// EventData: XComGameState_Item (UpgradedItem),
				/// EventSource: XComGameState_Item (BaseItem),
				/// NewGameState: yes
				/// ```
				// Single line for Issue #289 - handle upgrades for infinite items
				// There are three more event triggers with this EventID in this function.
				`XEVENTMGR.TriggerEvent('ItemUpgraded', UpgradedItemState, none, NewGameState);
				XComHQ.AddItemToHQInventory(UpgradedItemState);
			}
		}
		else
		{
			// Otherwise cycle through each of the base item templates
			foreach ItemsToUpgrade(BaseItemTemplate)
			{
				// Check if the base item is in the XComHQ inventory
				BaseItemState = XComHQ.GetItemByName(BaseItemTemplate.DataName);

				// If it is not, we have nothing to replace, so move on
				if (BaseItemState != none)
				{
					// Otherwise match the base items quantity
					UpgradedItemState = UpgradeItemTemplate.CreateInstanceFromTemplate(NewGameState);
					UpgradedItemState.Quantity = BaseItemState.Quantity;
					// Single line for Issue #289 - handle upgrades for utility items like grenades and medkits
					`XEVENTMGR.TriggerEvent('ItemUpgraded', UpgradedItemState, BaseItemState, NewGameState);

					// Then add the upgrade item and remove all of the base items from the inventory
					XComHQ.PutItemInInventory(NewGameState, UpgradedItemState);
					XComHQ.RemoveItemFromInventory(NewGameState, BaseItemState.GetReference(), BaseItemState.Quantity);
					NewGameState.RemoveStateObject(BaseItemState.GetReference().ObjectID);
				}
			}
		}

		// Check the inventory for any unequipped items with weapon upgrades attached, make sure they get updated
		InventoryItemRefs = XComHQ.Inventory;
		for (iItems = 0; iItems < InventoryItemRefs.Length; iItems++)
		{
			InventoryItemState = XComGameState_Item(History.GetGameStateForObjectID(InventoryItemRefs[iItems].ObjectID));
			foreach ItemsToUpgrade(BaseItemTemplate)
			{
				// Single line for Issue #306
				if (InventoryItemState.GetMyTemplateName() == BaseItemTemplate.DataName && InventoryItemState.GetMyWeaponUpgradeCount() > 0)
				{
					UpgradedItemState = UpgradeItemTemplate.CreateInstanceFromTemplate(NewGameState);
					UpgradedItemState.WeaponAppearance = InventoryItemState.WeaponAppearance;
					UpgradedItemState.Nickname = InventoryItemState.Nickname;

					// Some special weapons already have attachments. If so, do not put older
					// attachments onto the upgraded weapon
					// Single line for Issue #306
					if (UpgradedItemState.GetMyWeaponUpgradeCount() == 0)
					{
						// Transfer over all weapon upgrades to the new item
						WeaponUpgrades = InventoryItemState.GetMyWeaponUpgradeTemplates();
						foreach WeaponUpgrades(WeaponUpgradeTemplate)
						{
							UpgradedItemState.ApplyWeaponUpgradeTemplate(WeaponUpgradeTemplate);
						}
					}
					// Single line for Issue #289 - handle upgrades for unequipped items with attachments
					`XEVENTMGR.TriggerEvent('ItemUpgraded', UpgradedItemState, InventoryItemState, NewGameState);

					// Delete the old item, and add the new item to the inventory
					NewGameState.RemoveStateObject(InventoryItemState.GetReference().ObjectID);
					XComHQ.Inventory.RemoveItem(InventoryItemState.GetReference());
					XComHQ.PutItemInInventory(NewGameState, UpgradedItemState);
				}
			}
		}

		// Then check every soldier's inventory and replace the old item with a new one
		Soldiers = XComHQ.GetSoldiers();
		for (iSoldier = 0; iSoldier < Soldiers.Length; iSoldier++)
		{
			// Do not upgrade gear for soldiers deployed on Covert Actions, it will get modified when they return
			if (!Soldiers[iSoldier].IsOnCovertAction())
			{
				InventoryItems = Soldiers[iSoldier].GetAllInventoryItems(NewGameState, false);

				foreach InventoryItems(InventoryItemState)
				{
					foreach ItemsToUpgrade(BaseItemTemplate)
					{
						if (InventoryItemState.GetMyTemplateName() == BaseItemTemplate.DataName)
						{
							UpgradedItemState = UpgradeItemTemplate.CreateInstanceFromTemplate(NewGameState);
							UpgradedItemState.WeaponAppearance = InventoryItemState.WeaponAppearance;
							UpgradedItemState.Nickname = InventoryItemState.Nickname;
							InventorySlot = InventoryItemState.InventorySlot; // save the slot location for the new item

							// Remove the old item from the soldier and transfer over all weapon upgrades to the new item
							SoldierState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[iSoldier].ObjectID));
							SoldierState.RemoveItemFromInventory(InventoryItemState, NewGameState);

							// Some special weapons already have attachments. If so, do not put older
							// attachments onto the upgraded weapon
							// Single line for Issue #306
							if (UpgradedItemState.GetMyWeaponUpgradeCount() == 0)
							{
								WeaponUpgrades = InventoryItemState.GetMyWeaponUpgradeTemplates();
								foreach WeaponUpgrades(WeaponUpgradeTemplate)
								{
									UpgradedItemState.ApplyWeaponUpgradeTemplate(WeaponUpgradeTemplate);
								}
							}
							// Single line for Issue #289 - handle upgrades for equipped items with attachments
							`XEVENTMGR.TriggerEvent('ItemUpgraded', UpgradedItemState, InventoryItemState, NewGameState);

							// Delete the old item
							NewGameState.RemoveStateObject(InventoryItemState.GetReference().ObjectID);

							// Then add the new item to the soldier in the same slot
							SoldierState.AddItemToInventory(UpgradedItemState, InventorySlot, NewGameState);

							// Store the highest ranking soldier to get the upgraded item
							if (!SoldierState.IsResistanceHero())
							{
								if (HighestRankSoldier == none || SoldierState.GetRank() > HighestRankSoldier.GetRank())
								{
									HighestRankSoldier = SoldierState;
								}
							}
						}
					}
				}
			}
		}

		// Play a narrative if there is one and there is a valid soldier. Since we haven't actually submitted
		// the state yet, add an event that will trigger when we do, otherwise the soldier won't actually have 
		// the item we want to show
		if (HighestRankSoldier != none && X2EquipmentTemplate(UpgradeItemTemplate).EquipNarrative != "")
		{
			constRef = HighestRankSoldier;
			class'X2EventManager'.static.GetEventManager().RegisterForEvent(constRef, 'ItemUpgradedNarrative', OnUpgradeItemNarrative, ELD_OnStateSubmitted);
			class'X2EventManager'.static.GetEventManager().TriggerEvent('ItemUpgradedNarrative', UpgradeItemTemplate, HighestRankSoldier, NewGameState);
		}
	}
}

// callback to play the item upgrade narrative only after the item upgrade has actually been applied to the history
private static function EventListenerReturn OnUpgradeItemNarrative(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local X2ItemTemplate UpgradeItemTemplate;
	local XComNarrativeMoment EquipNarrativeMoment;
	local Object constRef;

	Unit = XComGameState_Unit(EventSource);
	UpgradeItemTemplate = X2ItemTemplate(EventData);
	
	EquipNarrativeMoment = XComNarrativeMoment(`CONTENT.RequestGameArchetype(X2EquipmentTemplate(UpgradeItemTemplate).EquipNarrative));
	if (EquipNarrativeMoment != None)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if (UpgradeItemTemplate.ItemCat == 'armor')
		{
			if (XComHQ.CanPlayArmorIntroNarrativeMoment(EquipNarrativeMoment))
			{
				XComHQ.UpdatePlayedArmorIntroNarrativeMoments(EquipNarrativeMoment);
				`HQPRES.UIArmorIntroCinematic(EquipNarrativeMoment.nmRemoteEvent, 'CIN_ArmorIntro_Done', Unit.GetReference());
			}
		}
		else if (XComHQ.CanPlayEquipItemNarrativeMoment(EquipNarrativeMoment))
		{
			XComHQ.UpdateEquipItemNarrativeMoments(EquipNarrativeMoment);
			`HQPRES.UINarrative(EquipNarrativeMoment);
		}
	}

	constRef = Unit;
	class'X2EventManager'.static.GetEventManager().UnRegisterFromEvent(constRef, 'OnUpdateArmorIntroCinematic');

	return ELR_NoInterrupt;
}

// Recursively calculates the list of items to upgrade based on the final upgraded item template
private static function GetItemsToUpgrade(X2ItemTemplate UpgradeItemTemplate, out array<X2ItemTemplate> ItemsToUpgrade)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate BaseItemTemplate, AdditionalBaseItemTemplate;
	local array<X2ItemTemplate> BaseItems;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Search for any base items which specify this item as their upgrade. This accounts for the old version of schematics, mainly for Day 0 DLC
	BaseItems = ItemTemplateManager.GetAllBaseItemTemplatesFromUpgrade(UpgradeItemTemplate.DataName);
	foreach BaseItems(AdditionalBaseItemTemplate)
	{
		if (ItemsToUpgrade.Find(AdditionalBaseItemTemplate) == INDEX_NONE)
		{
			ItemsToUpgrade.AddItem(AdditionalBaseItemTemplate);
		}
	}
	
	// If the base item was also the result of an upgrade, we need to save that base item as well to ensure the entire chain is upgraded
	BaseItemTemplate = ItemTemplateManager.FindItemTemplate(UpgradeItemTemplate.BaseItem);
	if (BaseItemTemplate != none)
	{
		ItemsToUpgrade.AddItem(BaseItemTemplate);
		GetItemsToUpgrade(BaseItemTemplate, ItemsToUpgrade);
	}
}

// Gives an item as though it was just constructed. Gives the highest available upgraded version of the item.
static function GiveItem(XComGameState NewGameState, out X2ItemTemplate ItemTemplate)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	
	if (ItemTemplate != none)
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		{
			break;
		}

		if (XComHQ == none)
		{
			History = `XCOMHISTORY;
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		}

		// Find the highest available upgraded version of the item
		XComHQ.UpdateItemTemplateToHighestAvailableUpgrade(ItemTemplate);
		ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

		// Act as though it was just built, and immediately add it to the inventory
		ItemState.OnItemBuilt(NewGameState);
		XComHQ.PutItemInInventory(NewGameState, ItemState);

		`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', ItemState, ItemState, NewGameState);
	}
}

// Calculates the highest available upgrade for an item template
function UpdateItemTemplateToHighestAvailableUpgrade(out X2ItemTemplate ItemTemplate)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate UpgradedItemTemplate;
	local XComGameState_Tech CompletedTechState;
	local array<XComGameState_Tech> CompletedTechs;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Get the item template which has this item as a base (should be only one)
	UpgradedItemTemplate = ItemTemplateManager.GetUpgradedItemTemplateFromBase(ItemTemplate.DataName);
	if (UpgradedItemTemplate != none)
	{
		if (HasItemByName(UpgradedItemTemplate.CreatorTemplateName)) // Check if an item which upgrades the base has been built
		{
			// The upgrading item has been built, so replace the template
			ItemTemplate = UpgradedItemTemplate;
			UpdateItemTemplateToHighestAvailableUpgrade(ItemTemplate); // Use recursion to keep climbing the upgrade chain
		}
		else
		{
			CompletedTechs = GetAllCompletedTechStates();
			foreach CompletedTechs(CompletedTechState) // Check if a tech which upgrades the base has been researched
			{
				if (CompletedTechState.GetMyTemplateName() == UpgradedItemTemplate.CreatorTemplateName)
				{
					// The upgrading tech has been researched, so replace the template
					ItemTemplate = UpgradedItemTemplate;
					UpdateItemTemplateToHighestAvailableUpgrade(ItemTemplate); // Use recursion to keep climbing the upgrade chain
					break;
				}
			}
		}
	}
}

//#############################################################################################
//----------------   RESOURCE MANAGEMENT   ----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function AddResourceOrder(name ResourceTemplateName, int iQuantity)
{
	local HeadquartersOrderInputContext OrderInput;

	OrderInput.OrderType = eHeadquartersOrderType_AddResource;
	OrderInput.AquireObjectTemplateName = ResourceTemplateName;
	OrderInput.Quantity = iQuantity;

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
}

function AddResource(XComGameState NewGameState, name ResourceTemplateName, int iQuantity)
{
	local XComGameState_Item ResourceItemState;
	local XComGameStateHistory History;
	local int idx, OldQuantity;
	local bool bFoundResource;

	if(iQuantity != 0)
	{
		History = `XCOMHISTORY;
		bFoundResource = false;

		for(idx = 0; idx < Inventory.Length; idx++)
		{
			ResourceItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

			if(ResourceItemState != none)
			{
				if(ResourceItemState.GetMyTemplate().DataName == ResourceTemplateName)
				{
					bFoundResource = true;
					break;
				}
			}
		}

		if(bFoundResource)
		{
			OldQuantity = ResourceItemState.Quantity;
			ResourceItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ResourceItemState.ObjectID));
			ResourceItemState.Quantity += iQuantity;
			ResourceItemState.LastQuantityChange = iQuantity;

			if(ResourceItemState.Quantity < 0)
			{
				ResourceItemState.Quantity = 0;
				ResourceItemState.LastQuantityChange = -OldQuantity;
			}

			if(ResourceItemState.Quantity != OldQuantity)
			{
				`XEVENTMGR.TriggerEvent( 'AddResource', ResourceItemState, , NewGameState );
			}
			else
			{
				NewGameState.PurgeGameStateForObjectID(ResourceItemState.ObjectID);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function int GetResourceAmount(name ResourceName)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none && ItemState.GetMyTemplateName() == ResourceName)
		{
			return ItemState.Quantity;
		}
	}

	return 0;
}

//---------------------------------------------------------------------------------------
function int GetSupplies()
{
	return GetResourceAmount('Supplies');
}

//---------------------------------------------------------------------------------------
function int GetIntel()
{
	return GetResourceAmount('Intel');
}

//---------------------------------------------------------------------------------------
function int GetAlienAlloys()
{
	return GetResourceAmount('AlienAlloy');
}

//---------------------------------------------------------------------------------------
function int GetEleriumDust()
{
	return GetResourceAmount('EleriumDust');
}

//---------------------------------------------------------------------------------------
function int GetEleriumCores()
{
	return GetResourceAmount('EleriumCore');
}

//---------------------------------------------------------------------------------------
function int GetAbilityPoints()
{
	return GetResourceAmount('AbilityPoint');
}

//#############################################################################################
//----------------   REQUIREMENT/COST CHECKING  -----------------------------------------------
//#############################################################################################

function int GetPendingFacilityDiscountPercent( name TemplateName )
{
	local PendingFacilityDiscount Discount;

	foreach PendingFacilityDiscounts( Discount )
	{
		if (Discount.TemplateName == TemplateName)
			return Discount.DiscountPercent;
	}

	return 0;
}

function RemovePendingFacilityDiscountPercent( name TemplateName )
{
	local int idx;

	for (idx = 0; idx < PendingFacilityDiscounts.Length; ++idx)
	{
		 if (PendingFacilityDiscounts[ idx ].TemplateName == TemplateName)
		 {
			 PendingFacilityDiscounts.Remove( idx, 1 );
			 break;
		 }
	}
}

//---------------------------------------------------------------------------------------
static function StrategyCost GetScaledStrategyCost(StrategyCost Cost, array<StrategyCostScalar> CostScalars, float DiscountPercent)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<StrategyCostScalar> GlobalScalars;
	local StrategyCostScalar CostScalar;
	local StrategyCost NewCost;
	local ArtifactCost NewArtifactCost, NewResourceCost;
	local int idx, iDifficulty;
	
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	GlobalScalars = class'X2StrategyGameRulesetDataStructures'.default.GlobalStrategyCostScalars;
	iDifficulty = `STRATEGYDIFFICULTYSETTING;

	// Add any cost scalars from AlienHQ which were triggered by Dark Events
	for(idx = 0; idx < AlienHQ.CostScalars.Length; idx++)
	{
		GlobalScalars.AddItem(AlienHQ.CostScalars[idx]);
	}

	for (idx = 0; idx < Cost.ArtifactCosts.Length; idx++)
	{
		NewArtifactCost.ItemTemplateName = Cost.ArtifactCosts[idx].ItemTemplateName;
		NewArtifactCost.Quantity = Round(Cost.ArtifactCosts[idx].Quantity * (1 - (DiscountPercent / 100.0)));

		foreach GlobalScalars(CostScalar)
		{
			if (Cost.ArtifactCosts[idx].ItemTemplateName == CostScalar.ItemTemplateName && iDifficulty == CostScalar.Difficulty)
			{
				NewArtifactCost.Quantity = Round(NewArtifactCost.Quantity * CostScalar.Scalar);
			}
		}

		foreach CostScalars(CostScalar)
		{
			if (Cost.ArtifactCosts[idx].ItemTemplateName == CostScalar.ItemTemplateName && iDifficulty == CostScalar.Difficulty)
			{
				NewArtifactCost.Quantity = Round(NewArtifactCost.Quantity * CostScalar.Scalar);
			}
		}

		NewCost.ArtifactCosts.AddItem(NewArtifactCost);
	}

	for (idx = 0; idx < Cost.ResourceCosts.Length; idx++)
	{
		NewResourceCost.ItemTemplateName = Cost.ResourceCosts[idx].ItemTemplateName;
		NewResourceCost.Quantity = Round(Cost.ResourceCosts[idx].Quantity * (1 - (DiscountPercent / 100.0)));

		foreach GlobalScalars(CostScalar)
		{
			if (Cost.ResourceCosts[idx].ItemTemplateName == CostScalar.ItemTemplateName && iDifficulty == CostScalar.Difficulty)
			{
				NewResourceCost.Quantity = Round(NewResourceCost.Quantity * CostScalar.Scalar);
			}
		}

		foreach CostScalars(CostScalar)
		{
			if (Cost.ResourceCosts[idx].ItemTemplateName == CostScalar.ItemTemplateName && iDifficulty == CostScalar.Difficulty)
			{
				NewResourceCost.Quantity = Round(NewResourceCost.Quantity * CostScalar.Scalar);
			}
		}

		NewCost.ResourceCosts.AddItem(NewResourceCost);
	}

	return NewCost;
}

//---------------------------------------------------------------------------------------
// Need to ensure that anytime this function is called the appropriate StrategyCostScalars are applied beforehand
function bool CanAffordResourceCost(name ResourceName, int Cost)
{
	return (GetResourceAmount(ResourceName) >= Cost);
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function bool CanAffordArtifactCost(ArtifactCost ArtifactReq)
{
	return HasItem(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ArtifactReq.ItemTemplateName), ArtifactReq.Quantity);
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function bool CanAffordAllArtifactCosts(array<ArtifactCost> ArtifactReqs)
{
	local bool CanAfford;
	local int idx;

	CanAfford = true;

	for(idx = 0; idx < ArtifactReqs.Length; idx++)
	{
		CanAfford = CanAffordArtifactCost(ArtifactReqs[idx]);

		if(!CanAfford)
			break;
	}

	return CanAfford;
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function bool CanAffordAllResourceCosts(array<ArtifactCost> ResourceCosts)
{
	local bool CanAfford;
	local int idx;

	CanAfford = true;

	for(idx = 0; idx < ResourceCosts.Length; idx++)
	{
		CanAfford = CanAffordResourceCost(ResourceCosts[idx].ItemTemplateName, ResourceCosts[idx].Quantity);

		if(!CanAfford)
			break;
	}

	return CanAfford;
}

//---------------------------------------------------------------------------------------
function bool MeetsTechRequirements(array<name> RequiredTechs)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2TechTemplate TechTemplate;
	local int idx;
	
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for(idx = 0; idx < RequiredTechs.Length; idx++)
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate(RequiredTechs[idx]));

		if(TechTemplate != none)
		{
			if(!TechTemplateIsResearched(TechTemplate))
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Tech Prereq name:" @ string(RequiredTechs[idx]));
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsItemRequirements(array<name> RequiredItems, optional bool bFailOnEmpty = false)
{
	local X2ItemTemplateManager ItemMgr;
	local X2ItemTemplate ItemTemplate;
	local int idx;

	if(bFailOnEmpty && RequiredItems.Length == 0)
	{
		return false;
	}

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for(idx = 0; idx < RequiredItems.Length; idx++)
	{
		ItemTemplate = ItemMgr.FindItemTemplate(RequiredItems[idx]);

		if(ItemTemplate != none)
		{
			if(!HasItem(ItemTemplate))
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Item Prereq name:" @ string(RequiredItems[idx]));
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsItemQuantityRequirements(array<ArtifactCost> RequiredItemQuantities)
{
	local int idx;
		
	for (idx = 0; idx < RequiredItemQuantities.Length; idx++)
	{
		if (!CanAffordArtifactCost(RequiredItemQuantities[idx]))
		{
			return false;
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsEquipmentRequirements(array<name> RequiredEquipment, optional bool bDontRequireAllEquipment = false)
{
	local X2ItemTemplateManager ItemMgr;
	local X2EquipmentTemplate EquipmentTemplate;
	local bool bEquipmentFound;
	local int idx;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for (idx = 0; idx < RequiredEquipment.Length; idx++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemMgr.FindItemTemplate(RequiredEquipment[idx]));

		if (EquipmentTemplate != none)
		{
			bEquipmentFound = HasItemInInventoryOrLoadout(EquipmentTemplate);
			if (bEquipmentFound && bDontRequireAllEquipment)
			{
				return true;
			}
			else if (!bEquipmentFound && !bDontRequireAllEquipment)
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Equipment Prereq name:" @ string(RequiredEquipment[idx]));
		}
	}

	return (bDontRequireAllEquipment ? false : true);
}

//---------------------------------------------------------------------------------------
function bool MeetsFacilityRequirements(array<name> RequiredFacilities)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2FacilityTemplate FacilityTemplate;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for(idx = 0; idx < RequiredFacilities.Length; idx++)
	{
		FacilityTemplate = X2FacilityTemplate(StratMgr.FindStrategyElementTemplate(RequiredFacilities[idx]));

		if(FacilityTemplate != none)
		{
			if(!HasFacilityByName(FacilityTemplate.DataName))
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Facility Prereq name:" @ string(RequiredFacilities[idx]));
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsUpgradeRequirements(array<name> RequiredUpgrades)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for(idx = 0; idx < RequiredUpgrades.Length; idx++)
	{
		UpgradeTemplate = X2FacilityUpgradeTemplate(StratMgr.FindStrategyElementTemplate(RequiredUpgrades[idx]));

		if(UpgradeTemplate != none)
		{
			if(!HasFacilityUpgradeByName(UpgradeTemplate.DataName))
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Upgrade Prereq name:" @ string(RequiredUpgrades[idx]));
		}
	}

	return true;
}

function bool MeetsObjectiveRequirements(array<Name> RequiredObjectives)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ObjectiveTemplate ObjectiveTemplate;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for( idx = 0; idx < RequiredObjectives.Length; idx++ )
	{
		ObjectiveTemplate = X2ObjectiveTemplate(StratMgr.FindStrategyElementTemplate(RequiredObjectives[idx]));

		if( ObjectiveTemplate != None )
		{
			if( !IsObjectiveCompleted(ObjectiveTemplate.DataName) )
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Objective Prereq name:" @ string(RequiredObjectives[idx]));
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsScienceAndEngineeringGates(int RequiredScience, int RequiredEngineering)
{
	return MeetsScienceGates(RequiredScience) && MeetsEngineeringGates(RequiredEngineering);
}

//---------------------------------------------------------------------------------------
function bool MeetsScienceGates(int RequiredScience)
{
	// The "-5" accounts for Tygan starting at level 10
	return Max((GetScienceScore() - 5),0) >= RequiredScience;
}

//---------------------------------------------------------------------------------------
function bool MeetsEngineeringGates(int RequiredEngineering)
{
	return GetEngineeringScore() >= RequiredEngineering;
}

//---------------------------------------------------------------------------------------
function bool MeetsSoldierGates(int RequiredRank, Name RequiredClass, bool RequiredClassRankCombo)
{
	if (RequiredClassRankCombo)
	{
		return MeetsSoldierRankClassCombo(RequiredRank, RequiredClass);
	}
	else
	{
		return MeetsSoldierRankGates(RequiredRank) && MeetsSoldierClassGates(RequiredClass);
	}	
}

//---------------------------------------------------------------------------------------
function bool MeetsSoldierRankGates(int RequiredRank)
{
	local XComGameState_Unit Soldier;
	local int idx;

	if (RequiredRank == 0)
		return true;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none && Soldier.IsSoldier())
		{
			// Check if rank gate is met, and the soldier is not a Psi Op
			if (Soldier.GetRank() >= RequiredRank && Soldier.GetSoldierClassTemplateName() != 'PsiOperative')
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool MeetsSoldierClassGates(Name RequiredClass)
{
	local XComGameState_Unit Soldier;
	local int idx;

	if (RequiredClass == '')
		return true;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none)
		{
			if (Soldier.GetSoldierClassTemplateName() == RequiredClass)
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool MeetsSoldierRankClassCombo(int RequiredRank, Name RequiredClass)
{
	local XComGameState_Unit Soldier;
	local int idx;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none && Soldier.IsSoldier())
		{
			if (Soldier.GetSoldierClassTemplate().DataName == RequiredClass && Soldier.GetRank() >= RequiredRank)
			{
				return true;
			}
		}
	}

	return false;
}
	
function bool MeetsSpecialRequirements(delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> SpecialRequirementsFn)
{
	if( SpecialRequirementsFn != None )
	{
		return SpecialRequirementsFn();
	}

	return true;
}

//---------------------------------------------------------------------------------------
event bool MeetsAllStrategyRequirements(StrategyRequirement Requirement)
{
	return (MeetsSpecialRequirements(Requirement.SpecialRequirementsFn) &&
			MeetsTechRequirements(Requirement.RequiredTechs) && 
			(MeetsItemRequirements(Requirement.RequiredItems) || MeetsItemRequirements(Requirement.AlternateRequiredItems, true)) &&
			MeetsEquipmentRequirements(Requirement.RequiredEquipment, Requirement.bDontRequireAllEquipment) &&
			MeetsItemQuantityRequirements(Requirement.RequiredItemQuantities) &&
			MeetsFacilityRequirements(Requirement.RequiredFacilities) && 
			MeetsUpgradeRequirements(Requirement.RequiredUpgrades) && 
			MeetsObjectiveRequirements(Requirement.RequiredObjectives) &&
			MeetsScienceAndEngineeringGates(Requirement.RequiredScienceScore, Requirement.RequiredEngineeringScore) &&
			MeetsSoldierGates(Requirement.RequiredHighestSoldierRank, Requirement.RequiredSoldierClass, Requirement.RequiredSoldierRankClassCombo));
}

//---------------------------------------------------------------------------------------
function bool MeetsEnoughRequirementsToBeVisible(StrategyRequirement Requirement, optional array<StrategyRequirement> AlternateRequirements)
{
	local StrategyRequirement AltRequirement;

	if (MeetsVisibilityRequirements(Requirement))
	{
		return true;
	}
	else if (AlternateRequirements.Length > 0)
	{
		foreach AlternateRequirements(AltRequirement)
		{
			if (MeetsVisibilityRequirements(AltRequirement))
			{
				return true;
			}
		}
	}

	return false;
}

private function bool MeetsVisibilityRequirements(StrategyRequirement Requirement)
{
	return (MeetsSpecialRequirements(Requirement.SpecialRequirementsFn) &&
		(MeetsTechRequirements(Requirement.RequiredTechs) || Requirement.bVisibleIfTechsNotMet) &&
		((MeetsItemRequirements(Requirement.RequiredItems) || MeetsItemRequirements(Requirement.AlternateRequiredItems, true)) || Requirement.bVisibleIfItemsNotMet) &&
		(MeetsEquipmentRequirements(Requirement.RequiredEquipment, Requirement.bDontRequireAllEquipment) || Requirement.bVisibleIfRequiredEquipmentNotMet) &&
		(MeetsFacilityRequirements(Requirement.RequiredFacilities) || Requirement.bVisibleIfFacilitiesNotMet) &&
		(MeetsUpgradeRequirements(Requirement.RequiredUpgrades) || Requirement.bVisibleIfUpgradesNotMet) &&
		(MeetsObjectiveRequirements(Requirement.RequiredObjectives) || Requirement.bVisibleIfObjectivesNotMet) &&
		(MeetsScienceAndEngineeringGates(Requirement.RequiredScienceScore, Requirement.RequiredEngineeringScore) || Requirement.bVisibleIfPersonnelGatesNotMet) &&
		(MeetsSoldierGates(Requirement.RequiredHighestSoldierRank, Requirement.RequiredSoldierClass, Requirement.RequiredSoldierRankClassCombo) || Requirement.bVisibleIfSoldierRankGatesNotMet));
}

//---------------------------------------------------------------------------------------
function bool CanAffordAllStrategyCosts(StrategyCost Cost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent)
{
	local StrategyCost ScaledCost;

	ScaledCost = GetScaledStrategyCost(Cost, CostScalars, DiscountPercent);

	return (CanAffordAllResourceCosts(ScaledCost.ResourceCosts) && CanAffordAllArtifactCosts(ScaledCost.ArtifactCosts));
}

//---------------------------------------------------------------------------------------
function bool MeetsRequirmentsAndCanAffordCost(StrategyRequirement Requirement, StrategyCost Cost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent, optional array<StrategyRequirement> AlternateRequirements)
{
	local StrategyRequirement AltRequirement;
	
	if (CanAffordAllStrategyCosts(Cost, CostScalars, DiscountPercent))
	{
		if (MeetsAllStrategyRequirements(Requirement))
		{
			return true;
		}
		else if (AlternateRequirements.Length > 0)
		{
			foreach AlternateRequirements(AltRequirement)
			{
				if (MeetsAllStrategyRequirements(AltRequirement))
				{
					return true;
				}
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool MeetsCommodityRequirements(Commodity CommodityObject)
{
	return MeetsAllStrategyRequirements(CommodityObject.Requirements);
}

//---------------------------------------------------------------------------------------
function bool CanAffordCommodity(Commodity CommodityObject)
{
	return CanAffordAllStrategyCosts(CommodityObject.Cost, CommodityObject.CostScalars, CommodityObject.DiscountPercent);
}

//---------------------------------------------------------------------------------------
function BuyCommodity(XComGameState NewGameState, Commodity CommodityObject, optional StateObjectReference AuxRef)
{
	ReceiveCommodityReward(NewGameState, CommodityObject, AuxRef);
	PayCommodityCost(NewGameState, CommodityObject);
}

//---------------------------------------------------------------------------------------
// Private function to ensure Commodity ArtifactCosts were modified by cost scalars
private function ReceiveCommodityReward(XComGameState NewGameState, Commodity CommodityObject, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;

	History = `XCOMHISTORY;

	RewardState = XComGameState_Reward(History.GetGameStateForObjectID(CommodityObject.RewardRef.ObjectID));
	RewardState.GiveReward(NewGameState, AuxRef);
}

//---------------------------------------------------------------------------------------
// Private function to ensure Commodity ArtifactCosts are modified by cost scalars
private function PayCommodityCost(XComGameState NewGameState, Commodity CommodityObject)
{
	local StrategyCost ScaledCost;

	ScaledCost = GetScaledStrategyCost(CommodityObject.Cost, CommodityObject.CostScalars, CommodityObject.DiscountPercent);

	PayResourceCosts(NewGameState, ScaledCost.ResourceCosts);
	PayArtifactCosts(NewGameState, ScaledCost.ArtifactCosts);
}

//---------------------------------------------------------------------------------------
function PayStrategyCost(XComGameState NewGameState, StrategyCost StratCost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent)
{
	local StrategyCost ScaledCost;

	ScaledCost = GetScaledStrategyCost(StratCost, CostScalars, DiscountPercent);

	PayResourceCosts(NewGameState, ScaledCost.ResourceCosts);
	PayArtifactCosts(NewGameState, ScaledCost.ArtifactCosts);
}

//---------------------------------------------------------------------------------------
function RefundStrategyCost(XComGameState NewGameState, StrategyCost StratCost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent)
{
	local StrategyCost ScaledCost;

	ScaledCost = GetScaledStrategyCost(StratCost, CostScalars, DiscountPercent);

	RefundResourceCosts(NewGameState, ScaledCost.ResourceCosts);
	RefundArtifactCosts(NewGameState, ScaledCost.ArtifactCosts);
}

//---------------------------------------------------------------------------------------
// Private function to ensure ResourceCosts were modified by cost scalars
private function PayResourceCosts(XComGameState NewGameState, array<ArtifactCost> ResourceCosts)
{
	local int idx;

	for(idx = 0; idx < ResourceCosts.Length; idx++)
	{
		AddResource(NewGameState, ResourceCosts[idx].ItemTemplateName, -ResourceCosts[idx].Quantity);
	}
}

//---------------------------------------------------------------------------------------
// Private function to ensure ResourceCosts were modified by cost scalars
private function RefundResourceCosts(XComGameState NewGameState, array<ArtifactCost> ResourceCosts)
{
	local int idx;

	for(idx = 0; idx < ResourceCosts.Length; idx++)
	{
		AddResource(NewGameState, ResourceCosts[idx].ItemTemplateName, ResourceCosts[idx].Quantity);
	}
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function PayArtifactCosts(XComGameState NewGameState, array<ArtifactCost> ArtifactCosts)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local int idx, i;

	History = `XCOMHISTORY;

	for(idx = 0; idx < ArtifactCosts.Length; idx++)
	{
		for(i = 0; i < Inventory.Length; i++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[i].ObjectID));

			if(ItemState != none)
			{
				if(ItemState.GetMyTemplateName() == ArtifactCosts[idx].ItemTemplateName && ItemState.Quantity >= ArtifactCosts[idx].Quantity)
				{
					RemoveItemFromInventory(NewGameState, ItemState.GetReference(), ArtifactCosts[idx].Quantity);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function RefundArtifactCosts(XComGameState NewGameState, array<ArtifactCost> ArtifactCosts)
{
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;
	local int idx;

	for(idx = 0; idx < ArtifactCosts.Length; idx++)
	{
		ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ArtifactCosts[idx].ItemTemplateName);
		ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
		ItemState.Quantity = ArtifactCosts[idx].Quantity;

		if(ItemState != none)
		{
			PutItemInInventory(NewGameState, ItemState);
		}
	}
}

//#############################################################################################
//----------------   OBJECTIVES   -------------------------------------------------------------
//#############################################################################################

static function bool IsObjectiveCompleted(Name ObjectiveName)
{
	if(GetObjective(ObjectiveName) == none)
	{
		return true;
	}

	return GetObjectiveStatus(ObjectiveName) == eObjectiveState_Completed;
}

static function EObjectiveState GetObjectiveStatus(Name ObjectiveName)
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if( ObjectiveState.GetMyTemplateName() == ObjectiveName )
		{
			return ObjectiveState.GetStateOfObjective();
		}
	}

	// no objective by the specified name
	return eObjectiveState_NotStarted;
}

static function XComGameState_Objective GetObjective(Name ObjectiveName)
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if (ObjectiveState.GetMyTemplateName() == ObjectiveName)
		{
			return ObjectiveState;
		}
	}

	// no objective by the specified name
	return None;
}

static function bool AnyTutorialObjectivesInProgress()
{
	return (!IsObjectiveCompleted(default.TutorialFinishedObjective));
}

static function bool LostAndAbandonedCompleted()
{
	local XComGameState_CampaignSettings CampaignState;

	CampaignState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	return (!CampaignState.bXPackNarrativeEnabled || IsObjectiveCompleted('XP0_M1_LostAndAbandonedComplete') || IsObjectiveCompleted('XP0_M1_TutorialLostAndAbandonedComplete'));
}

static function array<StateObjectReference> GetCompletedAndActiveStrategyObjectives()
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;
	local array<StateObjectReference> Objectives; 

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if( ObjectiveState.GetStateOfObjective() == eObjectiveState_Completed || ObjectiveState.GetStateOfObjective() == eObjectiveState_InProgress )
		{
			if( !ObjectiveState.GetMyTemplate().bNeverShowObjective && ObjectiveState.bIsRevealed && ObjectiveState.IsMainObjective() )
				Objectives.AddItem( ObjectiveState.GetReference() );
		}
	}
	return Objectives;
}

static function bool NeedsToEquipMedikitTutorial()
{
	return static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress;
}

static function bool IsWelcomeToLabsInProgressTutorial()
{
	return static.GetObjectiveStatus('T0_M1_WelcomeToLabs') == eObjectiveState_InProgress;
}

//#############################################################################################
//----------------   RESEARCH   ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
simulated function bool IsTechResearched(name TechName)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2TechTemplate TechTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate(TechName));

	return TechTemplate != none && TechTemplateIsResearched(TechTemplate);
}

//---------------------------------------------------------------------------------------
simulated function bool IsContactResearched()
{
	return IsTechResearched('ResistanceCommunications');
}

//---------------------------------------------------------------------------------------
simulated function bool IsOutpostResearched()
{
	return IsTechResearched('ResistanceRadio');
}

//---------------------------------------------------------------------------------------
native function bool TechTemplateIsResearched(X2TechTemplate TechTemplate);

//---------------------------------------------------------------------------------------
native function bool TechIsResearched(StateObjectReference TechRef);

//---------------------------------------------------------------------------------------
//----------------------------RESEARCH PROJECTS------------------------------------------
//---------------------------------------------------------------------------------------

function XComGameState_Tech GetCurrentResearchTech()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ResearchProject != none && !ResearchProject.bShadowProject && !ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused)
		{
			return XComGameState_Tech(History.GetGameStateForObjectID(ResearchProject.ProjectFocus.ObjectID));
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectResearch GetCurrentResearchProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ResearchProject != none && !ResearchProject.bShadowProject && !ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused)
		{
			return ResearchProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetCompletedResearchTechs()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));

		//Outdated savegames may contain completed techs that have since been removed. Don't bother enumerating them.
		if (TechState.GetMyTemplate() == None)
			continue;

		if (!TechState.GetMyTemplate().bProvingGround && !TechState.GetMyTemplate().bShadowProject)
			CompletedTechs.AddItem(TechState.GetReference());
	}

	return CompletedTechs;
}

//---------------------------------------------------------------------------------------
function bool HasCompletedResearchTechs()
{
	return (GetNumTechsResearched() > 0);
}

//---------------------------------------------------------------------------------------
function int GetNumTechsResearched()
{
	local array<StateObjectReference> CompletedTechs;

	CompletedTechs = GetCompletedResearchTechs();

	return CompletedTechs.Length;
}

//---------------------------------------------------------------------------------------
function bool HasResearchProject()
{
	return (GetCurrentResearchProject() != none);
}

//---------------------------------------------------------------------------------------
//------------------------------SHADOW PROJECTS------------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
function XComGameState_Tech GetCurrentShadowTech()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.bShadowProject && !ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused)
		{
			return XComGameState_Tech(History.GetGameStateForObjectID(ResearchProject.ProjectFocus.ObjectID));
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectResearch GetCurrentShadowProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.bShadowProject && !ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused)
		{
			return ResearchProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetCompletedShadowTechs()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));

		if (TechState.GetMyTemplate().bShadowProject)
			CompletedTechs.AddItem(TechState.GetReference());
	}

	return CompletedTechs;
}

//---------------------------------------------------------------------------------------
function bool HasCompletedShadowProjects()
{
	return (GetNumShadowProjectsCompleted() > 0);
}

//---------------------------------------------------------------------------------------
function int GetNumShadowProjectsCompleted()
{
	local array<StateObjectReference> CompletedProjects;

	CompletedProjects = GetCompletedShadowTechs();

	return CompletedProjects.Length;
}

//---------------------------------------------------------------------------------------
function bool HasShadowProject()
{
	return (GetCurrentShadowProject() != none);
}

//---------------------------------------------------------------------------------------
function bool HasActiveShadowProject()
{
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	ResearchProject = GetCurrentShadowProject();

	return (ResearchProject != none && !ResearchProject.bForcePaused);
}

//---------------------------------------------------------------------------------------
//----------------------------PROVING GROUND PROJECTS------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
function XComGameState_Tech GetCurrentProvingGroundTech()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectProvingGround ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ResearchProject != none && ResearchProject.bProvingGroundProject && !ResearchProject.bShadowProject && !ResearchProject.bForcePaused && ResearchProject.FrontOfBuildQueue())
		{
			return XComGameState_Tech(History.GetGameStateForObjectID(ResearchProject.ProjectFocus.ObjectID));
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectProvingGround GetCurrentProvingGroundProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectProvingGround ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && !ResearchProject.bShadowProject && ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused && ResearchProject.FrontOfBuildQueue())
		{
			return ResearchProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetCompletedProvingGroundTechs()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));

		if (TechState.GetMyTemplate().bProvingGround)
			CompletedTechs.AddItem(TechState.GetReference());
	}

	return CompletedTechs;
}


//---------------------------------------------------------------------------------------
function array<XComGameState_Tech> GetCompletedProvingGroundTechStates()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<XComGameState_Tech> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));

		if (TechState.GetMyTemplate().bProvingGround)
			CompletedTechs.AddItem(TechState);
	}

	return CompletedTechs;
}

//---------------------------------------------------------------------------------------
function bool HasCompletedProvingGroundProjects()
{
	return (GetNumProvingGroundProjectsCompleted() > 0);
}

//---------------------------------------------------------------------------------------
function int GetNumProvingGroundProjectsCompleted()
{
	local array<StateObjectReference> CompletedProjects;

	CompletedProjects = GetCompletedProvingGroundTechs();

	return CompletedProjects.Length;
}

//---------------------------------------------------------------------------------------
function bool HasProvingGroundProject()
{
	return (GetCurrentProvingGroundProject() != none);
}

//---------------------------------------------------------------------------------------
//-----------------------------------TECH HELPERS----------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
function bool IsTechAvailableForResearch(StateObjectReference TechRef, optional bool bShadowProject = false, optional bool bProvingGround = false, optional bool bBreakthrough = false)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	if(TechIsResearched( TechRef ) && !TechState.GetMyTemplate().bRepeatable)
	{
		return false;
	}

	if(TechState.bBlocked)
	{
		return false;
	}
	else if((bShadowProject && !TechState.GetMyTemplate().bShadowProject) ||
			(!bShadowProject && TechState.GetMyTemplate().bShadowProject) ||
			(bProvingGround && !TechState.GetMyTemplate().bProvingGround) ||
			(!bProvingGround && TechState.GetMyTemplate().bProvingGround) ||
			(bBreakthrough && !TechState.GetMyTemplate().bBreakthrough) ||
			(!bBreakthrough && TechState.GetMyTemplate().bBreakthrough))
	{
		return false;
	}

	if (TechState.ShouldTechBeHidden())
	{
		return false;
	}

	if(!HasPausedProject(TechRef) && !MeetsEnoughRequirementsToBeVisible(TechState.GetMyTemplate().Requirements, TechState.GetMyTemplate().AlternateRequirements))
	{
		return false;
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool IsTechCurrentlyBeingResearched(XComGameState_Tech TechState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.ProjectFocus == TechState.GetReference())
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool IsTechCurrentlyBeingResearchedByName(Name TechTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if (TechState.GetMyTemplateName() == TechTemplateName)
		{
			break;
		}
	}

	return IsTechCurrentlyBeingResearched(TechState);
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetAvailableTechsForResearch(optional bool bShadowProject = false, optional bool bMeetsRequirements = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StateObjectReference> AvailableTechs, BreakthroughTechs;

	AvailableTechs.Length = 0;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if (TechState.GetMyTemplate() != none)
		{
			if (bShadowProject)
			{
				if ((!HasActiveShadowProject() || TechState.ObjectID != GetCurrentShadowTech().ObjectID) && IsTechAvailableForResearch(TechState.GetReference(), bShadowProject))
				{
					if (!bMeetsRequirements || MeetsRequirmentsAndCanAffordCost(TechState.GetMyTemplate().Requirements, TechState.GetMyTemplate().Cost, ResearchCostScalars, 0.0, TechState.GetMyTemplate().AlternateRequirements))
					{
						AvailableTechs.AddItem(TechState.GetReference());
					}
				}
			}
			else
			{
				if ((!HasResearchProject() || TechState.ObjectID != GetCurrentResearchTech().ObjectID) && IsTechAvailableForResearch(TechState.GetReference(), bShadowProject))
				{
					if (!bMeetsRequirements || MeetsRequirmentsAndCanAffordCost(TechState.GetMyTemplate().Requirements, TechState.GetMyTemplate().Cost, ResearchCostScalars, 0.0, TechState.GetMyTemplate().AlternateRequirements))
					{
						AvailableTechs.AddItem(TechState.GetReference());
					}
				}
			}
		}
	}
	
	if (!bShadowProject)
	{
		if (CurrentBreakthroughTech.ObjectID != 0) // If a breakthrough was triggered, add it to the available tech list
		{
			// Don't display the breakthrough tech in the "Change Research" list if it is already in progress
			if ((CurrentBreakthroughTech.ObjectID != GetCurrentResearchTech().ObjectID) && IsTechAvailableForResearch(CurrentBreakthroughTech, false, false, true))
			{
				AvailableTechs.AddItem(CurrentBreakthroughTech);
			}
		}	
		else if (AvailableTechs.Length == 0) // There are no available techs, so generate a random breakthrough tech to keep the tree going
		{
			BreakthroughTechs = GetAvailableBreakthroughTechs(true); // Allow ignored breakthroughs to pop up again
			
			if (BreakthroughTechs.Length > 0)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tech Tree Exhausted: Add Breakthrough");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', ObjectID));

				TechState = XComGameState_Tech(History.GetGameStateForObjectID(BreakthroughTechs[`SYNC_RAND(BreakthroughTechs.Length)].ObjectID));
				TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechState.ObjectID));
				TechState.bBreakthrough = true;

				// Save the current breakthrough tech into XComHQ so it can be easily accessed after the next tech is started			
				XComHQ.CurrentBreakthroughTech = TechState.GetReference();

				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

				AvailableTechs.AddItem(TechState.GetReference());
			}
		}
	}

	return AvailableTechs;
}

//---------------------------------------------------------------------------------------
function bool HasTechsAvailableForResearch(optional bool bShadowProject = false)
{
	local array<StateObjectReference> AvailableTechs;

	AvailableTechs = GetAvailableTechsForResearch(bShadowProject);

	return (AvailableTechs.Length > 0);
}

//---------------------------------------------------------------------------------------
function bool HasTechsAvailableForResearchWithRequirementsMet(optional bool bShadowProject = false)
{
	local array<StateObjectReference> AvailableTechs;

	AvailableTechs = GetAvailableTechsForResearch(bShadowProject, true);

	return (AvailableTechs.Length > 0);
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetAvailableProvingGroundProjects()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> AvailableProjects;

	AvailableProjects.Length = 0;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if ((TechState.GetMyTemplate().bRepeatable || !IsTechCurrentlyBeingResearched(TechState)) && IsTechAvailableForResearch(TechState.GetReference(), false, true))
		{
			AvailableProjects.AddItem(TechState.GetReference());
		}
	}

	return AvailableProjects;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Tech> GetAllCompletedTechStates()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<XComGameState_Tech> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));
		CompletedTechs.AddItem(TechState);
	}

	return CompletedTechs;
}

//---------------------------------------------------------------------------------------
function int GetPercentSlowTechs()
{
	local XComGameStateHistory History;
	local array<StateObjectReference> AvailableTechs, ShadowTechs;
	local StateObjectReference TechRef;
	local X2TechTemplate TechTemplate;
	local float NumSlowTechs;
	local int PercentGated;

	History = `XCOMHISTORY;
	AvailableTechs = GetAvailableTechsForResearch(false);
	ShadowTechs = GetAvailableTechsForResearch(true);

	foreach AvailableTechs(TechRef)
	{
		TechTemplate = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID)).GetMyTemplate();
		if (!TechTemplate.bAutopsy && !TechTemplate.bRepeatable && GetResearchProgress(TechRef) < eResearchProgress_Normal)
		{
			NumSlowTechs += 1.0;
		}
	}
	foreach ShadowTechs(TechRef)
	{
		TechTemplate = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID)).GetMyTemplate();
		if (!TechTemplate.bAutopsy && !TechTemplate.bRepeatable && GetResearchProgress(TechRef) < eResearchProgress_Normal)
		{
			NumSlowTechs += 1.0;
		}
	}

	PercentGated = int((NumSlowTechs / (AvailableTechs.Length + ShadowTechs.Length)) * 100);
	return PercentGated;
}

//---------------------------------------------------------------------------------------
function bool HasGatedPriorityResearch()
{
	local XComGameStateHistory History;
	local array<StateObjectReference> AvailableTechs, ShadowTechs;
	local StateObjectReference TechRef;
	local X2TechTemplate TechTemplate;
	local XComGameState_Tech TechState;
	local int ScienceScore;

	History = `XCOMHISTORY;
	AvailableTechs = GetAvailableTechsForResearch(false);
	ShadowTechs = GetAvailableTechsForResearch(true);
	ScienceScore = GetScienceScore();

	foreach AvailableTechs(TechRef)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		TechTemplate = TechState.GetMyTemplate();
		if (TechState.IsPriority() && TechTemplate.Requirements.RequiredScienceScore > ScienceScore)
		{
			return true;
		}
	}
	foreach ShadowTechs(TechRef)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		TechTemplate = TechState.GetMyTemplate();
		if (TechState.IsPriority() && TechTemplate.Requirements.RequiredScienceScore > ScienceScore)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasGatedEngineeringItem()
{
	local X2ItemTemplate ItemTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2ItemTemplate> BuildableItems;
	local int EngineeringScore;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	BuildableItems = ItemTemplateManager.GetBuildableItemTemplates();
	EngineeringScore = GetEngineeringScore();
	
	foreach BuildableItems(ItemTemplate)
	{
		if (ItemTemplateManager.BuildItemWeaponCategories.Find(ItemTemplate.ItemCat) != INDEX_NONE)
		{
			if (ItemTemplate.Requirements.RequiredEngineeringScore > EngineeringScore)
				return true;
		}
		else if (ItemTemplateManager.BuildItemArmorCategories.Find(ItemTemplate.ItemCat) != INDEX_NONE)
		{
			if (ItemTemplate.Requirements.RequiredEngineeringScore > EngineeringScore)
				return true;
		}		
	}

	return false;
}

//---------------------------------------------------------------------------------------
function SetNewResearchProject(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState, InspiredTechState, BreakthroughTechState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local XComNarrativeMoment TechStartedNarrative;
	local StrategyCost TechCost;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Research Project");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));

	ResearchProject = GetPausedProject(TechRef);

	if(ResearchProject != none)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectResearch', ResearchProject.ObjectID));
		ResearchProject.bForcePaused = false;
	}
	else
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectResearch'));
		ResearchProject.SetProjectFocus(TechRef);
		XComHQ.Projects.AddItem(ResearchProject.GetReference());

		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		TechCost = TechState.GetMyTemplate().Cost;
		XComHQ.PayStrategyCost(NewGameState, TechCost, ResearchCostScalars);
	}

	if (ResearchProject.bShadowProject)
	{
		StaffShadowChamber(NewGameState);
	}

	// Only clear current Inspired or Breakthrough techs if a non-Instant project was started,
	// or if the started tech is a Shadow Project
	if (!ResearchProject.bInstant && !ResearchProject.bShadowProject)
	{
		if (XComHQ.CurrentInspiredTech.ObjectID != 0 && TechRef.ObjectID != XComHQ.CurrentInspiredTech.ObjectID)
		{
			InspiredTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', XComHQ.CurrentInspiredTech.ObjectID));
			InspiredTechState.bInspired = false;
			InspiredTechState.TimeReductionScalar = 0.0;

			XComHQ.CurrentInspiredTech.ObjectID = 0;
		}

		if (XComHQ.CurrentBreakthroughTech.ObjectID != 0 && TechRef.ObjectID != XComHQ.CurrentBreakthroughTech.ObjectID)
		{
			BreakthroughTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', XComHQ.CurrentBreakthroughTech.ObjectID));
			BreakthroughTechState.bBreakthrough = false;

			ResearchProject = GetPausedProject(XComHQ.CurrentBreakthroughTech);
			if (ResearchProject != none) // A paused version of this breakthrough project exists, so we need to remove it
			{
				XComHQ.Projects.RemoveItem(ResearchProject.GetReference());
				NewGameState.RemoveStateObject(ResearchProject.ObjectID);
			}

			XComHQ.CurrentBreakthroughTech.ObjectID = 0;
			XComHQ.IgnoredBreakthroughTechs.AddItem(BreakthroughTechState.GetReference());
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	HandlePowerOrStaffingChange();

	if(ResearchProject.bInstant)
	{
		ResearchProject.OnProjectCompleted();
	}

	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
	
	if (TechState != none && TechState.GetMyTemplate().TechStartedNarrative != "")
	{
		TechStartedNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(TechState.GetMyTemplate().TechStartedNarrative));
		if (TechStartedNarrative != None)
		{
			`HQPRES.UINarrative(TechStartedNarrative);
		}
	}
}

//---------------------------------------------------------------------------------------
function PauseResearchProject(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectResearch ProjectState;
	local XComGameState_Tech TechState;
	local int WorkPerHour, ReducedProjectPoints, OriginalProjectPoints, PointDiff;

	ProjectState = GetCurrentResearchProject();

	if (ProjectState != none)
	{
		ProjectState = XComGameState_HeadquartersProjectResearch(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectResearch', ProjectState.ObjectID));
		WorkPerHour = ProjectState.GetCurrentWorkPerHour();
		ProjectState.bForcePaused = true;

		// If the tech was inspired, remove the inspiration and add back the reduced project points
		TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (TechState.bInspired)
		{
			TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechState.ObjectID));			
			ReducedProjectPoints = TechState.GetProjectPoints(WorkPerHour); // Grab the current inspired points
			TechState.bInspired = false;
			TechState.TimeReductionScalar = 0.0;
			OriginalProjectPoints = TechState.GetProjectPoints(WorkPerHour); // Now get the points again that inspiration is turned off
			PointDiff = OriginalProjectPoints - ReducedProjectPoints;
			ProjectState.ProjectPointsRemaining += PointDiff; // Add the difference to the points remaining for the project

			// Remove the inspired project from XComHQ as well
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
			XComHQ.CurrentInspiredTech.ObjectID = 0;
		}
	}
}

//---------------------------------------------------------------------------------------
function PauseShadowProject(XComGameState NewGameState)
{
	local XComGameState_HeadquartersProjectResearch ProjectState;

	ProjectState = GetCurrentShadowProject();

	if(ProjectState != none)
	{
		ProjectState = XComGameState_HeadquartersProjectResearch(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectResearch', ProjectState.ObjectID));
		ProjectState.bForcePaused = true;
		EmptyShadowChamber(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function bool HasPausedProject(StateObjectReference TechRef)
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.ProjectFocus == TechRef && ResearchProject.bForcePaused)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectResearch GetPausedProject(StateObjectReference TechRef)
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.ProjectFocus == TechRef && ResearchProject.bForcePaused)
		{
			return ResearchProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function int GetHoursLeftOnResearchProject()
{
	return GetCurrentResearchProject().GetCurrentNumHoursRemaining();
}

//---------------------------------------------------------------------------------------
function int GetHoursLeftOnShadowProject()
{
	return GetCurrentShadowProject().GetCurrentNumHoursRemaining();
}

//---------------------------------------------------------------------------------------
function String GetResearchEstimateString(StateObjectReference TechRef)
{
	local int iHours, iDaysLeft;
	local XGParamTag kTag;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");
	
	ResearchProject = GetPausedProject(TechRef);
	
	if (ResearchProject == none)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		if (TechState.GetMyTemplate().bProvingGround)
			ResearchProject = XComGameState_HeadquartersProjectProvingGround(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectProvingGround'));
		else
			ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectResearch'));

		ResearchProject.SetProjectFocus(TechRef);
	}

	iHours = ResearchProject.GetProjectedNumHoursRemaining();
	
	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		NewGameState.PurgeGameStateForObjectID(ResearchProject.ObjectID);
	}
	History.CleanupPendingGameState(NewGameState);

	if( ResearchProject.bInstant )
	{
		return strETAInstant;
	}
	else
	{
		kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		iDaysLeft = class'X2StrategyGameRulesetDataStructures'.static.HoursToDays(iHours);

		if( iDaysLeft < 0 )
		{
			iDaysLeft = 1;
		}

		kTag.IntValue0 = iDaysLeft;

		return `XEXPAND.ExpandString((iDaysLeft != 1) ? strETADays : strETADay);
	}
}

//---------------------------------------------------------------------------------------
function int GetResearchHours(StateObjectReference TechRef)
{
	local int iHours;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");
	
	ResearchProject = GetPausedProject(TechRef);

	if (ResearchProject == none)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		if (TechState.GetMyTemplate().bProvingGround)
			ResearchProject = XComGameState_HeadquartersProjectProvingGround(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectProvingGround'));
		else
			ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectResearch'));

		ResearchProject.SetProjectFocus(TechRef);
	}

	iHours = ResearchProject.GetProjectedNumHoursRemaining();
	
	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		NewGameState.PurgeGameStateForObjectID(ResearchProject.ObjectID);
	}
	History.CleanupPendingGameState(NewGameState);

	if( ResearchProject.bInstant )
	{
		return 0;
	}
	else
	{
		return iHours;
	}
}

//---------------------------------------------------------------------------------------
function EResearchProgress GetResearchProgress(StateObjectReference TechRef)
{
	local int iHours, iDays;

	if(TechRef.ObjectID == 0)
	{
		return eResearchProgress_Normal;
	}

	iHours = GetResearchHours(TechRef);
	iDays = class'X2StrategyGameRulesetDataStructures'.static.HoursToDays(iHours);

	if( iDays <= `ScaleStrategyArrayInt(ResearchProgressDays_Fast) )
		return eResearchProgress_Fast;
	else if( iDays <= `ScaleStrategyArrayInt(ResearchProgressDays_Normal) )
		return eResearchProgress_Normal;
	else if( iDays <= `ScaleStrategyArrayInt(ResearchProgressDays_Slow) )
		return eResearchProgress_Slow;
	else
		return eResearchProgress_VerySlow;
}

function StaffShadowChamber(XComGameState NewGameState)
{
	local XComGameState_FacilityXCom FacilityState;
	local StaffUnitInfo ShenInfo, TyganInfo;

	// Add Shen and Tygan to the Shadow Chamber
	ShenInfo.UnitRef = GetShenReference();
	TyganInfo.UnitRef = GetTyganReference();
	FacilityState = GetFacilityByName('ShadowChamber');
	FacilityState.GetStaffSlot(0).FillSlot(ShenInfo, NewGameState);
	FacilityState.GetStaffSlot(1).FillSlot(TyganInfo, NewGameState);
}

function EmptyShadowChamber(XComGameState NewGameState)
{
	local XComGameState_FacilityXCom FacilityState;
	
	// Empty the Shadow Chamber
	FacilityState = GetFacilityByName('ShadowChamber');
	FacilityState.GetStaffSlot(0).EmptySlot(NewGameState);
	FacilityState.GetStaffSlot(1).EmptySlot(NewGameState);
}

//---------------------------------------------------------------------------------------------
//---------------------------------RESEARCH BREAKTHROUGHS--------------------------------------
//---------------------------------------------------------------------------------------------

function CheckForInstantTechs(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local array<StateObjectReference> AvailableTechRefs;
	local X2TechTemplate TechTemplate;
	local XComGameState_Tech AvailableTechState;
	local int idx;

	History = `XCOMHISTORY;
	AvailableTechRefs = GetAvailableTechsForResearch();
	
	for (idx = 0; idx < AvailableTechRefs.Length; idx++)
	{
		AvailableTechState = XComGameState_Tech(History.GetGameStateForObjectID(AvailableTechRefs[idx].ObjectID));
		TechTemplate = AvailableTechState.GetMyTemplate();
		if (TechTemplate.bCheckForceInstant && MeetsAllStrategyRequirements(TechTemplate.InstantRequirements) && !HasPausedProject(AvailableTechRefs[idx]))
		{
			AvailableTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', AvailableTechState.ObjectID));
			AvailableTechState.bForceInstant = true;
		}
	}
}

function bool CheckForBreakthroughTechs(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local array<StateObjectReference> AvailableTechRefs;
	local XComGameState_Tech AvailableTechState;
	local int TechIndex;
	local bool bTechFound;

	if (CanActivateBreakthroughTech())
	{
		History = `XCOMHISTORY;
		AvailableTechRefs = GetAvailableBreakthroughTechs();
		
		// Iterate through available breakthroughs, and randomly choose a non-instant one to inspire
		while (AvailableTechRefs.Length > 0 && !bTechFound)
		{
			TechIndex = `SYNC_RAND(AvailableTechRefs.Length);
			AvailableTechState = XComGameState_Tech(History.GetGameStateForObjectID(AvailableTechRefs[TechIndex].ObjectID));
			AvailableTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', AvailableTechState.ObjectID));
			AvailableTechState.bBreakthrough = true;

			// Save the current breakthrough tech into XComHQ so it can be easily accessed after the next tech is started
			CurrentBreakthroughTech = AvailableTechState.GetReference();
			bTechFound = true;
		}

		// If a tech was successfully inspired, reset the inspiration timer
		if (bTechFound)
		{
			ResetBreakthroughTechTimer();
			return true;
		}
	}

	return false;
}

function CheckForInspiredTechs(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local array<StateObjectReference> AvailableTechRefs;
	local X2TechTemplate TechTemplate;
	local XComGameState_Tech AvailableTechState;
	local int TechIndex;
	local bool bTechFound;

	if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(InspiredTechTimer, GetCurrentTime()))
	{
		History = `XCOMHISTORY;
		AvailableTechRefs = GetAvailableTechsForResearch();

		// Iterate through available techs, and randomly choose a non-instant one to inspire
		while (AvailableTechRefs.Length > 0 && !bTechFound)
		{
			TechIndex = `SYNC_RAND(AvailableTechRefs.Length);
			AvailableTechState = XComGameState_Tech(History.GetGameStateForObjectID(AvailableTechRefs[TechIndex].ObjectID));
			TechTemplate = AvailableTechState.GetMyTemplate();

			// Prevent any techs which could be made instant (autopsies), or which have already been reduced by purchasing tech reductions from the black market
			// and only inspire techs which the player can afford
			if (!TechTemplate.bCheckForceInstant && AvailableTechState.TimeReductionScalar < 0.001f && !HasPausedProject(AvailableTechRefs[TechIndex]) &&
				MeetsRequirmentsAndCanAffordCost(TechTemplate.Requirements, TechTemplate.Cost, default.ResearchCostScalars, , TechTemplate.AlternateRequirements) &&
				/* Issue #633 */ TriggerCanTechBeInspired(AvailableTechState, NewGameState))
			{
				AvailableTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', AvailableTechState.ObjectID));
				AvailableTechState.bInspired = true;
				AvailableTechState.TimeReductionScalar = ((default.MinInspiredTechTimeReduction + `SYNC_RAND(default.MaxInspiredTechTimeReduction - default.MinInspiredTechTimeReduction + 1)) / 100.0f);
				
				// Save the current inspired tech into XComHQ so it can be easily accessed after the next tech is started
				CurrentInspiredTech = AvailableTechState.GetReference();
				
				bTechFound = true;
			}
			else
			{
				AvailableTechRefs.Remove(TechIndex, 1);
			}
		}

		// If a tech was successfully inspired, reset the inspiration timer
		if (bTechFound)
		{
			ResetInspiredTechTimer();
		}
	}
}

// Start Issue #633
/// HL-Docs: feature:CanTechBeInspired; issue:633; tags:strategy
/// The `CanTechBeInspired` event allows mods to forbid a tech from being inspired. 
/// This provides an important lever for balancing the strategy game. 
/// It's particularly important for repeatable techs, which the inspiration mechanic doesn't seem to handle very well 
/// (the techs remain inspired even after the first inspired research of them is complete).
///
///```event
///EventID: CanTechBeInspired,
///EventData: [inout bool bCanTechBeInspired],
///EventSource: XComGameState_Tech (TechState),
///NewGameState: yes
///```
private function bool TriggerCanTechBeInspired(XComGameState_Tech TechState, XComGameState NewGameState)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CanTechBeInspired';
	Tuple.Data.Add(1);
	Tuple.Data[0].Kind = XComLWTVBool;
	Tuple.Data[0].b = true;

	`XEVENTMGR.TriggerEvent('CanTechBeInspired', Tuple, TechState, NewGameState);

	return Tuple.Data[0].b;
}
// End Issue #633

private function bool CanActivateBreakthroughTech()
{
	// First check that the breakthrough timer is completed
	if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(BreakthroughTechTimer, GetCurrentTime()))
	{
		// If the inspired tech timer is not complete, then triggering a breakthrough is fine
		if (!class'X2StrategyGameRulesetDataStructures'.static.LessThan(InspiredTechTimer, GetCurrentTime()))
		{
			return true;
		}
		else if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(BreakthroughTechTimer, InspiredTechTimer))
		{
			// But if both timers are complete, only trigger a breakthrough if the timer finished before the inspiration timer
			return true;
		}
	}

	return false;
}

function array<StateObjectReference> GetAvailableBreakthroughTechs(optional bool bAllowIgnored)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> AvailableBreakthroughs;

	AvailableBreakthroughs.Length = 0;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if (!IsTechCurrentlyBeingResearched(TechState) && IsTechAvailableForResearch(TechState.GetReference(), false, false, true))
		{
			if (!HasPausedProject(TechState.GetReference()) && (bAllowIgnored || IgnoredBreakthroughTechs.Find('ObjectID', TechState.ObjectID) == INDEX_NONE))
			{
				AvailableBreakthroughs.AddItem(TechState.GetReference());
			}
		}
	}

	return AvailableBreakthroughs;
}

// Checks if a breakthrough tech is available, accounting for any which have been ignored or already researched
// Used by covert actions
function bool IsBreakthroughTechAvailable()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if (!IsTechCurrentlyBeingResearched(TechState) && IsTechAvailableForResearch(TechState.GetReference(), false, false, true))
		{
			if (!HasPausedProject(TechState.GetReference()) && IgnoredBreakthroughTechs.Find('ObjectID', TechState.ObjectID) == INDEX_NONE)
			{
				return true;
			}
		}
	}

	return false;
}

private function ResetInspiredTechTimer()
{
	local int InspiredTimerHours;

	InspiredTimerHours = `SYNC_RAND(`ScaleStrategyArrayInt(default.MaxInspiredTechTimerHours));
	InspiredTechTimer = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(InspiredTechTimer, InspiredTimerHours);
}

private function ResetBreakthroughTechTimer(optional bool bFirstTime)
{
	local int BreakthroughTimerHours;

	BreakthroughTimerHours = `SYNC_RAND(`ScaleStrategyArrayInt(bFirstTime ? default.StartingBreakthroughTechTimerHours : default.MaxBreakthroughTechTimerHours));
	BreakthroughTimerHours *= BreakthroughTimerModifier;

	BreakthroughTechTimer = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(BreakthroughTechTimer, BreakthroughTimerHours);
}

function ModifyBreakthroughTechTimer(float Modifier)
{
	local int HoursRemaining, NewHoursRemaining;
	
	// Save the modifier so it can be applied when the tech timer is reset
	BreakthroughTimerModifier *= Modifier;
	BreakthroughTimerModifier = FMin(BreakthroughTimerModifier, 1.0); // Ensure the timer never goes above the base rate
		
	HoursRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(BreakthroughTechTimer, GetCurrentTime());
	NewHoursRemaining = HoursRemaining * Modifier;

	// Update the end time of the current Breakthrough tech timer to account for the new modifier
	BreakthroughTechTimer = `STRATEGYRULES.GameTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(BreakthroughTechTimer, NewHoursRemaining);
}

//#############################################################################################
//----------------   SCHEMATICS ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// Return list of schematics from the inventory. 
function array<X2SchematicTemplate> GetPurchasedSchematics()
{
	local array<X2SchematicTemplate> Schematics; 
	local X2SchematicTemplate SchematicTemplate; 
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local int idx;

	History = `XCOMHISTORY; 

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			SchematicTemplate = X2SchematicTemplate(ItemState.GetMyTemplate());
			if( SchematicTemplate != none )
			{
				Schematics.AddItem(SchematicTemplate);
			}
		}
	}

	return Schematics; 
}

function bool HasFoundSchematics()
{
	local array<X2SchematicTemplate> Schematics;

	Schematics = GetPurchasedSchematics();

	return (Schematics.length > 0);
}

//#############################################################################################
//----------------   POWER   ------------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetPowerProduced()
{
	local XComGameState_FacilityXCom FacilityState;
	local int idx, iPowerProduced, iFacilityPower;

	iPowerProduced = GetStartingPowerProduced();
	iPowerProduced += BonusPowerProduced;
	iPowerProduced += PowerOutputBonus;

	for(idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(FacilityState != none)
		{
			iFacilityPower = FacilityState.GetPowerOutput();

			if(iFacilityPower > 0)
			{
				iPowerProduced += iFacilityPower;
			}
		}
	}

	return iPowerProduced;
}

//---------------------------------------------------------------------------------------
function int GetPowerConsumed()
{
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectBuildFacility BuildFacilityState;
	local int idx, iPowerConsumed, iFacilityPower;

	iPowerConsumed = 0;

	for(idx = 0; idx < Rooms.Length; idx++)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));
				
		// If the room has a facility, get its power output
		if (RoomState.HasFacility())
		{
			FacilityState = RoomState.GetFacility();

			iFacilityPower = FacilityState.GetPowerOutput();
			if(iFacilityPower < 0)
			{
				iPowerConsumed -= iFacilityPower;
			}
		}
		else // Otherwise check to see if a facility is being built, and then get the new facility's output
		{
			BuildFacilityState = RoomState.GetBuildFacilityProject();
			if (BuildFacilityState != None && !RoomState.HasShieldedPowerCoil())
			{
				FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(BuildFacilityState.ProjectFocus.ObjectID));
				
				iFacilityPower = FacilityState.GetPowerOutput();
				if (iFacilityPower < 0)
				{
					iPowerConsumed -= iFacilityPower;
				}
			}
		}
	}

	return iPowerConsumed;
}

//---------------------------------------------------------------------------------------
function float GetPowerPercent()
{
	return (float(GetPowerConsumed()) / float(GetPowerProduced())) * 100.0;
}

//---------------------------------------------------------------------------------------
function DeterminePowerState()
{
	local float PowerPercent;
	local int PowerProduced, PowerConsumed;

	PowerPercent = GetPowerPercent();
	PowerProduced = GetPowerProduced();
	PowerConsumed = GetPowerConsumed();

	if(PowerConsumed >= PowerProduced)
	{
		PowerState = ePowerState_Red;
	}
	else if(PowerPercent >= default.XComHeadquarters_YellowPowerStatePercent)
	{
		PowerState = ePowerState_Yellow;
	}
	else
	{
		PowerState = ePowerState_Green;
	}
}

//#############################################################################################
//----------------   RESISTANCE COMMS   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetPossibleResContacts()
{
	local int iPossibleContacts;

	local XComGameState_FacilityXCom Facility;
	local int idx;

	iPossibleContacts = GetStartingCommCapacity();
	iPossibleContacts += BonusCommCapacity;

	for( idx = 0; idx < Facilities.Length; idx++ )
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));
		
		iPossibleContacts += Facility.CommCapacity;
	}

	return iPossibleContacts;
}

//---------------------------------------------------------------------------------------
function int GetCurrentResContacts(optional bool bExcludeInProgress = false)
{
	local XComGameState_WorldRegion RegionState;
	local XComGameStateHistory History;
	local int iContacts;

	History = `XCOMHISTORY;

	iContacts = 0;
	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if( RegionState.HaveMadeContact() || (RegionState.bCanScanForContact && !bExcludeInProgress))
		{
			iContacts++;
		}
	}

	return iContacts;
}

//---------------------------------------------------------------------------------------
function int GetRemainingContactCapacity()
{
	return GetPossibleResContacts() - GetCurrentResContacts();
}

//---------------------------------------------------------------------------------------
function array<XComGameState_WorldRegion> GetContactRegions()
{
	local array<XComGameState_WorldRegion> arrContactRegions;
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if (RegionState.ResistanceLevel == eResLevel_Unlocked)
		{
			arrContactRegions.AddItem(RegionState);
		}
	}

	return arrContactRegions;
}

//---------------------------------------------------------------------------------------
function bool HasRegionsAvailableForContact()
{
	local array<XComGameState_WorldRegion> arrContactRegions;

	arrContactRegions = GetContactRegions();

	return (arrContactRegions.Length > 0);
}

//#############################################################################################
//----------------   AVENGER STATUS   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// Helper for Hack Rewards to modify scan rate for a specified period of time
function SetScanRateForDuration(XComGameState NewGameState, float NewModifier, int DurationHours)
{
	local TDateTime NewEndTime;
	local ScanRateMod NewScanRateMod;

	CurrentScanRate *= NewModifier;
	
	// Calculate when the scan rate mod will expire
	NewEndTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(NewEndTime, DurationHours);
	
	// Save the new scan rate modifier amount and when it expires
	NewScanRateMod.Modifier = NewModifier;
	NewScanRateMod.ScanRateEndTime = NewEndTime;
	ScanRateMods.AddItem(NewScanRateMod);
	
	UpdateScanSiteTimes(NewGameState, NewModifier);
}

//---------------------------------------------------------------------------------------
// Update all active scanning sites to match the current scanning rate
function UpdateScanSiteTimes(XComGameState NewGameState, float Modifier)
{
	local array<XComGameState_ScanningSite> PossibleScanningSites;
	local XComGameState_ScanningSite ScanningSiteState;

	PossibleScanningSites = GetAvailableScanningSites();
	foreach PossibleScanningSites(ScanningSiteState)
	{
		ScanningSiteState = XComGameState_ScanningSite(NewGameState.ModifyStateObject(class'XComGameState_ScanningSite', ScanningSiteState.ObjectID));

		ScanningSiteState.ModifyRemainingScanTime(Modifier);
	}
}

//---------------------------------------------------------------------------------------
// Can the Avenger scan in its current region
function bool IsScanningAllowedAtCurrentLocation()
{
	local XComGameState_ScanningSite ScanSiteState;

	ScanSiteState = GetCurrentScanningSite();
	if (ScanSiteState != none)
		return ScanSiteState.CanBeScanned();

	return false;
}

function string GetScanSiteLabel()
{
	local XComGameState_ScanningSite ScanSiteState;

	ScanSiteState = GetCurrentScanningSite();
	if (ScanSiteState != none)
		return ScanSiteState.GetScanButtonLabel();

	return "";
}

function ToggleSiteScanning(bool bScanning)
{
	local XComGameState NewGameState;
	local XComGameState_ScanningSite ScanSiteState;
	local XComGameState_WorldRegion RegionState;
	
	ScanSiteState = GetCurrentScanningSite();
	if (ScanSiteState != none && ScanSiteState.CanBeScanned())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Scanning Site");
		ScanSiteState = XComGameState_ScanningSite(NewGameState.ModifyStateObject(class'XComGameState_ScanningSite', ScanSiteState.ObjectID));

		if (bScanning)
		{
			`XEVENTMGR.TriggerEvent('ScanStarted', ScanSiteState, , NewGameState);

			ScanSiteState.StartScan();

			RegionState = XComGameState_WorldRegion(ScanSiteState);
			if (RegionState != none && RegionState.bCanScanForContact && !RegionState.bScanForContactEventTriggered)
			{
				RegionState.bScanForContactEventTriggered = true;

				`XEVENTMGR.TriggerEvent('StartScanForContact', , , NewGameState);
			}
		}
		else
			ScanSiteState.PauseScan();
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function XComGameState_ScanningSite GetCurrentScanningSite()
{
	return XComGameState_ScanningSite(`XCOMHISTORY.GetGameStateForObjectID(CurrentLocation.ObjectID));
}

function array<XComGameState_ScanningSite> GetAvailableScanningSites()
{
	local array<XComGameState_ScanningSite> arrScanSites;
	local XComGameStateHistory History;
	local XComGameState_ScanningSite ScanSiteState;
	local XComGameState_BlackMarket BlackMarketState;
	local XComGameState_Haven HavenState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_ScanningSite', ScanSiteState)
	{
		BlackMarketState = XComGameState_BlackMarket(ScanSiteState);
		HavenState = XComGameState_Haven(ScanSiteState);

		if (ScanSiteState.CanBeScanned() || (BlackMarketState != none && BlackMarketState.ShouldBeVisible()) || (HavenState != none && HavenState.GetResistanceFaction() != none))
		{
			arrScanSites.AddItem(ScanSiteState);
		}
	}

	return arrScanSites;
}

//---------------------------------------------------------------------------------------
function bool IsSupplyDropAvailable()
{
	local XComGameStateHistory History;
	local XComGameState_ScanningSite ScanSiteState;
	local XComGameState_ResourceCache CacheState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_ScanningSite', ScanSiteState)
	{
		CacheState = XComGameState_ResourceCache(ScanSiteState);

		if (CacheState != none && CacheState.CanBeScanned())
		{
			return true;
		}
	}

	return false;
}

//#############################################################################################
//----------------   MISSION HANDLING   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function GeneratedMissionData GetGeneratedMissionData(int MissionID)
{
	local int MissionDataIndex;
	local GeneratedMissionData GeneratedMission;
	local XComGameState_MissionSite MissionState;

	MissionDataIndex = arrGeneratedMissionData.Find('MissionID', MissionID);

	if(MissionDataIndex == INDEX_NONE)
	{
		MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionID));
		GeneratedMission = MissionState.GeneratedMission;
		if(GeneratedMission.BattleOpName == "")
		{
			GeneratedMission.BattleOpName = class'XGMission'.static.GenerateOpName(false);
		}
		arrGeneratedMissionData.AddItem(GeneratedMission);
	}
	else
	{
		GeneratedMission = arrGeneratedMissionData[MissionDataIndex];
	}
	return GeneratedMission;
}

//#############################################################################################
//----------------   EVENTS   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function GetEvents(out array<HQEvent> arrEvents)
{
	GetOrderEvents(arrEvents);
	GetSoldierEvents(arrEvents);
	GetResearchEvents(arrEvents);
	GetProvingGroundEvents(arrEvents);
	GetItemEvents(arrEvents);
	GetFacilityEvents(arrEvents);
	GetClearRoomEvents(arrEvents);
	GetFacilityUpgradeEvents(arrEvents);
	GetPsiTrainingEvents(arrEvents);
	GetResistanceEvents(arrEvents);
	//start issue #112: get DLC events here
	GetDLCInfoEvents(arrEvents);
	//end issue #112
	GetCovertActionEvents(arrEvents);

}
//start issue #112
//---------------------------------------------------------------------------------------
function GetDLCInfoEvents(out array<HQEvent> arrEvents)
{
	local HQEvent kEvent;
	local array<HQEvent> jEvents;
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		jEvents.Length = 0; //this is to prevent stale data from previous DLCInfos from being kept
		if(DLCInfo.GetDLCEventInfo(jEvents)) //if this is true, a mod has added at least one event and we need to add it
		{		
			foreach jEvents(kEvent)
			{
				AddEventToEventList(arrEvents, kEvent);
			}

		}
	}

}
//end issue #112
//---------------------------------------------------------------------------------------
function AddEventToEventList(out array<HQEvent> arrEvents, HQEvent kEvent)
{
	local int iEvent;

	if(kEvent.Hours >= 0)
	{
		for(iEvent = 0; iEvent < arrEvents.Length; iEvent++)
		{
			if(arrEvents[iEvent].Hours < 0 || arrEvents[iEvent].Hours > kEvent.Hours)
			{
				arrEvents.InsertItem(iEvent, kEvent);
				return;
			}
		}
	}

	arrEvents.AddItem(kEvent);
}

//---------------------------------------------------------------------------------------
function GetOrderEvents(out array<HQEvent> arrEvents)
{
	local HQEvent kEvent;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < CurrentOrders.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(CurrentOrders[idx].OrderRef.ObjectID));

		if(UnitState != none)
		{
			kEvent.Data = default.StaffOrderEventLabel @ UnitState.GetFullName();
			kEvent.Hours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(CurrentOrders[idx].OrderCompletionTime, GetCurrentTime());
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;
			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetSoldierEvents(out array<HQEvent> arrEvents)
{
	local int iProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectTrainRookie TrainProject;
	local XComGameState_HeadquartersProjectRespecSoldier RespecProject;
	local XComGameState_HeadquartersProjectRemoveTraits TraitsProject;
	local XComGameState_HeadquartersProjectBondSoldiers BondProject;
	local XComGameState_Unit UnitState, LinkedUnitState;
	local XComGameStateHistory History;
	local string ClassName; 

	History = `XCOMHISTORY;

	for (iProject = 0; iProject < Projects.Length; iProject++)
	{
		TrainProject = XComGameState_HeadquartersProjectTrainRookie(History.GetGameStateForObjectID(Projects[iProject].ObjectID));
		RespecProject = XComGameState_HeadquartersProjectRespecSoldier(History.GetGameStateForObjectID(Projects[iProject].ObjectID));
		TraitsProject = XComGameState_HeadquartersProjectRemoveTraits(History.GetGameStateForObjectID(Projects[iProject].ObjectID));
		BondProject = XComGameState_HeadquartersProjectBondSoldiers(History.GetGameStateForObjectID(Projects[iProject].ObjectID));

		if (TrainProject != none)
		{			
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TrainProject.ProjectFocus.ObjectID));
			ClassName = Caps(TrainProject.GetTrainingClassTemplate().DisplayName); 
			kEvent.Data =  Repl(TrainRookieEventLabel @ UnitState.GetName(eNameType_RankFull), "%CLASSNAME", ClassName);
			kEvent.Hours = TrainProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;
			
			if (kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}

		if (RespecProject != none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RespecProject.ProjectFocus.ObjectID));
			kEvent.Data = Caps(UnitState.GetSoldierClassTemplate().DisplayName) @ RespecSoldierEventLabel @ UnitState.GetName(eNameType_RankFull);
			kEvent.Hours = RespecProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;
			
			if (kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}

		if (TraitsProject != none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TraitsProject.ProjectFocus.ObjectID));
			kEvent.Data = RemoveTraitsEventLabel @ UnitState.GetName(eNameType_RankFull);
			kEvent.Hours = TraitsProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;

			if (kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}

		if (BondProject != none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(BondProject.ProjectFocus.ObjectID));
			LinkedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(BondProject.AuxilaryReference.ObjectID));
			kEvent.Data = BondSoldiersEventLabel @ UnitState.GetName(eNameType_RankFull) @ class'UIUtilities_Text'.default.m_strAmpersand @ LinkedUnitState.GetName(eNameType_RankFull);
			kEvent.Hours = BondProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;

			if (kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetResearchEvents(out array<HQEvent> arrEvents)
{
	local HQEvent kEvent;

	if(HasResearchProject())
	{
		kEvent.Data = ResearchEventLabel @ GetCurrentResearchTech().GetDisplayName();
		kEvent.Hours = GetHoursLeftOnResearchProject();
		kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Science;

		if(kEvent.Hours < 0)
		{
			kEvent.Data = ProjectPausedLabel @ kEvent.Data;
		}

		AddEventToEventList(arrEvents, kEvent);
	}

	if(HasActiveShadowProject())
	{
		kEvent.Data = ShadowEventLabel @ GetCurrentShadowTech().GetDisplayName();
		kEvent.Hours = GetHoursLeftOnShadowProject();
		kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Science;

		if(kEvent.Hours < 0)
		{
			kEvent.Data = ProjectPausedLabel @ kEvent.Data;
		}

		AddEventToEventList(arrEvents, kEvent);
	}
}

//---------------------------------------------------------------------------------------
function GetClearRoomEvents(out array<HQEvent> arrEvents)
{
	local int iClearRoomProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectClearRoom ClearRoomProject;
	local XComGameState_HeadquartersRoom Room;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for(iClearRoomProject = 0; iClearRoomProject < Projects.Length; iClearRoomProject++)
	{
		ClearRoomProject = XComGameState_HeadquartersProjectClearRoom(History.GetGameStateForObjectID(Projects[iClearRoomProject].ObjectID));

		if(ClearRoomProject != none)
		{
			Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(ClearRoomProject.ProjectFocus.ObjectID));

			if(Room != none)
			{
				kEvent.Data = Room.GetSpecialFeature().ClearText;
				kEvent.Hours = ClearRoomProject.GetCurrentNumHoursRemaining();
				kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Construction;

				if(kEvent.Hours < 0)
				{
					kEvent.Data = ProjectPausedLabel @ kEvent.Data;
				}

				AddEventToEventList(arrEvents, kEvent);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function GetProvingGroundEvents(out array<HQEvent> arrEvents)
{
	local int idx, CumulativeHours, iProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local XComGameState_Tech ProjectState;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (FacilityState != none && FacilityState.BuildQueue.Length > 0)
		{
			for (iProject = 0; iProject < FacilityState.BuildQueue.Length; iProject++)
			{
				ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(FacilityState.BuildQueue[iProject].ObjectID));
				
				// Need to account for other item projects that might be taking up time
				ItemProject = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(FacilityState.BuildQueue[iProject].ObjectID));
				if (ItemProject != none)
				{
					if (iProject == 0)
						CumulativeHours = ItemProject.GetCurrentNumHoursRemaining();
					else
						CumulativeHours += ItemProject.GetProjectedNumHoursRemaining();
				}

				if (ProvingGroundProject != none)
				{
					if (iProject == 0)
					{
						ProjectState = XComGameState_Tech(History.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));
						kEvent.Data = ProvingGroundEventLabel @ ProjectState.GetMyTemplate().DisplayName;
						CumulativeHours = ProvingGroundProject.GetCurrentNumHoursRemaining();
						kEvent.Hours = CumulativeHours;
					}
					else
					{
						ProjectState = XComGameState_Tech(History.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));
						kEvent.Data = ProvingGroundEventLabel @ ProjectState.GetMyTemplate().DisplayName;
						CumulativeHours += ProvingGroundProject.GetProjectedNumHoursRemaining();
						kEvent.Hours = CumulativeHours;
					}

					kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Engineer;
					if (kEvent.Hours < 0)
					{
						kEvent.Data = ProjectPausedLabel @ kEvent.Data;
					}

					AddEventToEventList(arrEvents, kEvent);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function GetItemEvents(out array<HQEvent> arrEvents)
{
	local int idx, CumulativeHours, iItemProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(FacilityState != none && FacilityState.BuildQueue.Length > 0)
		{
			for(iItemProject = 0; iItemProject < FacilityState.BuildQueue.Length; iItemProject++)
			{
				ItemProject = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(FacilityState.BuildQueue[iItemProject].ObjectID));
								
				// Need to account for other proving ground projects that might be taking up time
				ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(FacilityState.BuildQueue[iItemProject].ObjectID));
				if (ProvingGroundProject != none)
				{
					if (iItemProject == 0)
						CumulativeHours = ProvingGroundProject.GetCurrentNumHoursRemaining();
					else
						CumulativeHours += ProvingGroundProject.GetProjectedNumHoursRemaining();
				}

				if(ItemProject != none)
				{
					if(iItemProject == 0)
					{
						ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemProject.ProjectFocus.ObjectID));
						kEvent.Data = ItemEventLabel @ ItemState.GetMyTemplate().GetItemFriendlyName();
						CumulativeHours = ItemProject.GetCurrentNumHoursRemaining();
						kEvent.Hours = CumulativeHours;
					}
					else
					{
						ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemProject.ProjectFocus.ObjectID));
						kEvent.Data = ItemEventLabel @ ItemState.GetMyTemplate().GetItemFriendlyName();
						CumulativeHours += ItemProject.GetProjectedNumHoursRemaining();
						kEvent.Hours = CumulativeHours;
					}

					kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Engineer;
					if(kEvent.Hours < 0)
					{
						kEvent.Data = ProjectPausedLabel @ kEvent.Data;
					}

					AddEventToEventList(arrEvents, kEvent);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function GetFacilityEvents(out array<HQEvent> arrEvents)
{
	local int iFacilityProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for(iFacilityProject = 0; iFacilityProject < Projects.Length; iFacilityProject++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(Projects[iFacilityProject].ObjectID));

		if(FacilityProject != none)
		{
			kEvent.Data = FacilityEventLabel @ XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityProject.ProjectFocus.ObjectID)).GetMyTemplate().DisplayName;
			kEvent.Hours = FacilityProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Engineer;

			if(kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetFacilityUpgradeEvents(out array<HQEvent> arrEvents)
{
	local int iUpgradeProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for(iUpgradeProject = 0; iUpgradeProject < Projects.Length; iUpgradeProject++)
	{
		UpgradeProject = XComGameState_HeadquartersProjectUpgradeFacility(History.GetGameStateForObjectID(Projects[iUpgradeProject].ObjectID));

		if(UpgradeProject != none)
		{
			kEvent.Data = UpgradeEventLabel @ XComGameState_FacilityUpgrade(History.GetGameStateForObjectID(UpgradeProject.ProjectFocus.ObjectID)).GetMyTemplate().DisplayName;
			kEvent.Hours = UpgradeProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Construction;

			if(kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetPsiTrainingEvents(out array<HQEvent> arrEvents)
{
	local XComGameStateHistory History;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;
	local string PsiTrainingStr, AbilityNameStr;
	local int iPsiProject;

	History = `XCOMHISTORY;

	for( iPsiProject = 0; iPsiProject < Projects.Length; iPsiProject++ )
	{
		PsiProject = XComGameState_HeadquartersProjectPsiTraining(History.GetGameStateForObjectID(Projects[iPsiProject].ObjectID));

		if(PsiProject != none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(PsiProject.ProjectFocus.ObjectID));

			if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
			{
				AbilityName = UnitState.GetAbilityName(PsiProject.iAbilityRank, PsiProject.iAbilityBranch);
				AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
				AbilityNameStr = Caps(AbilityTemplate.LocFriendlyName);
				PsiTrainingStr = Repl(TrainRookieEventLabel, "%CLASSNAME", AbilityNameStr);
			}
			else
			{
				PsiTrainingStr = PsiTrainingEventLabel;
			}

			kEvent.Data = PsiTrainingStr @ UnitState.GetName(eNameType_RankFull);
			kEvent.Hours = PsiProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Psi;

			if(kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetResistanceEvents(out array<HQEvent> arrEvents)
{
	local HQEvent kEvent;
	local XComGameState_HeadquartersResistance ResistanceHQ;;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	// Monthly supply drop
	if(!ResistanceHQ.bInactive)
	{
		kEvent.Data = SupplyDropEventLabel;
		kEvent.Hours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(ResistanceHQ.MonthIntervalEndTime, `STRATEGYRULES.GameTime);
		kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Resistance;
		AddEventToEventList(arrEvents, kEvent);
	}
}

//---------------------------------------------------------------------------------------
// chl issue #518 start: added tuple & event 'ForceNoCovertActionNagFirstMonth'

/// HL-Docs: feature:GetCovertActionEvents_Settings; issue:391; tags:strategy,ui
/// Allows configuring the behavior of covert actions in the event queue.  
/// `AddAll` allows multiple covert actions, `InsertSorted` inserts them into position
/// based on time remaining.
///
/// Default: Only one covert action is added at the end.
///
/// ```event
/// EventID: GetCovertActionEvents_Settings,
/// EventData: [out bool AddAll, out bool InsertSorted],
/// EventSource: XComGameState_HeadquartersXCom (XComHQ),
/// NewGameState: none
/// ```
function GetCovertActionEvents(out array<HQEvent> arrEvents)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;
	local XComGameState_HeadquartersResistance ResHQ;
	local HQEvent kEvent;
	local bool bActionFound, bRingBuilt;
	local XComLWTuple Tuple1, Tuple2; // chl issue #391, #518

	History = `XCOMHISTORY;

	// Start Issue #391
	Tuple1 = new class'XComLWTuple';
	Tuple1.Id = 'GetCovertActionEvents_Settings';
	Tuple1.Data.Add(2);
	Tuple1.Data[0].kind = XComLWTVBool;
	Tuple1.Data[0].b = false; // AddAll
	Tuple1.Data[1].kind = XComLWTVBool;
	Tuple1.Data[1].b = false; // InsertSorted

	`XEVENTMGR.TriggerEvent('GetCovertActionEvents_Settings', Tuple1, self);
	// End Issue #391
	
	Tuple2 = new class'XComLWTuple';
	Tuple2.Id = 'OverrideNoCaEventMinMonths';
	Tuple2.Data.Add(1);
	Tuple2.Data[0].kind = XComLWTVInt;
	Tuple2.Data[0].i = 1;

	`XEVENTMGR.TriggerEvent('OverrideNoCaEventMinMonths', Tuple2, self);

	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		if (ActionState.bStarted)
		{
			kEvent.Data = ActionState.GetDisplayName();
			kEvent.Hours = ActionState.GetNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Resistance;
			kEvent.ActionRef = ActionState.GetReference();
			kEvent.bActionEvent = true;

			// Start Issue #391
			if (!Tuple1.Data[1].b)
			{
			// End Issue #391
				//Add directly to the end of the events list, not sorted by hours. 
				arrEvents.AddItem(kEvent);
			// Start Issue #391
			}
			else
			{
				AddEventToEventList(arrEvents, kEvent);
			}
			// End Issue #391

			bActionFound = true;

			// Start Issue #391
			if (!Tuple1.Data[0].b)
			{
			// End Issue #391
				break; // We only need to display one Action at a time
			// Start Issue #391
			}
			// End Issue #391
		}
	}

	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	bRingBuilt = HasFacilityByName('ResistanceRing');

	if (!bActionFound && (ResHQ.NumMonths >= Tuple2.Data[0].i /* chl issue #518 */ || bRingBuilt))
	{
		if (bRingBuilt)
			kEvent.Data = CovertActionsGoToRing;
		else if (!ResHQ.bCovertActionStartedThisMonth)
			kEvent.Data = CovertActionsSelectOp;
		else
			kEvent.Data = CovertActionsBuildRing;

		kEvent.Hours = -1;
		kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Resistance;
		kEvent.bActionEvent = true;
		arrEvents.AddItem(kEvent);
	}
}

function bool HasSoldierUnlockTemplate(name UnlockName)
{
	return SoldierUnlockTemplates.Find(UnlockName) != INDEX_NONE;
}

function bool AddSoldierUnlockTemplate(XComGameState NewGameState, X2SoldierUnlockTemplate UnlockTemplate, optional bool bNoReqOrCost = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	`assert(NewGameState != none);
	if (!HasSoldierUnlockTemplate(UnlockTemplate.DataName))
	{
		if(bNoReqOrCost || MeetsRequirmentsAndCanAffordCost(UnlockTemplate.Requirements, UnlockTemplate.Cost, OTSUnlockScalars, GTSPercentDiscount))
		{
			if(!bNoReqOrCost)
			{
				PayStrategyCost(NewGameState, UnlockTemplate.Cost, OTSUnlockScalars, GTSPercentDiscount);
			}
			
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', ObjectID));
			XComHQ.SoldierUnlockTemplates.AddItem(UnlockTemplate.DataName);
			UnlockTemplate.OnSoldierUnlockPurchased(NewGameState);
			return true;
		}
	}
	return false;
}

function array<X2SoldierUnlockTemplate> GetActivatedSoldierUnlockTemplates()
{
	local X2StrategyElementTemplateManager TemplateMan;
	local array<X2SoldierUnlockTemplate> ActivatedUnlocks;
	local name UnlockName;

	TemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	ActivatedUnlocks.Length = 0;

	foreach SoldierUnlockTemplates(UnlockName)
	{
		ActivatedUnlocks.AddItem(X2SoldierUnlockTemplate(TemplateMan.FindStrategyElementTemplate(UnlockName)));
	}

	return ActivatedUnlocks;
}

function ClearGTSSoldierUnlockTemplates()
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2FacilityTemplate GTSTemplate;
	local int idx;

	// Only remove and save unlocks from the GTS
	// Some come from cards and should not be removed
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	GTSTemplate = X2FacilityTemplate(StratMgr.FindStrategyElementTemplate('OfficerTrainingSchool'));
	SavedSoldierUnlockTemplates.Length = 0;

	for(idx = 0; idx < SoldierUnlockTemplates.Length; idx++)
	{
		if(GTSTemplate.SoldierUnlockTemplates.Find(SoldierUnlockTemplates[idx]) != INDEX_NONE)
		{
			SavedSoldierUnlockTemplates.AddItem(SoldierUnlockTemplates[idx]);
			SoldierUnlockTemplates.Remove(idx, 1);
			idx--;
		}
	}
}

function RestoreSoldierUnlockTemplates()
{
	local int idx;

	for(idx = 0; idx < SavedSoldierUnlockTemplates.Length; idx++)
	{
		SoldierUnlockTemplates.AddItem(SavedSoldierUnlockTemplates[idx]);
	}

	SavedSoldierUnlockTemplates.Length = 0;
}

// For bonuses from cards, not GTS
function RemoveSoldierUnlockTemplate(name UnlockTemplateName)
{
	SoldierUnlockTemplates.RemoveItem(UnlockTemplateName);
}

function OnCrewMemberAdded(XComGameState NewGameState, XComGameState_Unit NewUnitState)
{
	local X2StrategyElementTemplateManager TemplateMan;
	local X2SoldierClassTemplate ClassTemplate;
	local X2SoldierUnlockTemplate UnlockTemplate;
	local name UnlockName;
	local StateObjectReference NewUnitRef;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	//local XComGameState_HeadquartersProjectRecoverWill WillProject;

	NewUnitRef = NewUnitState.GetReference( );
	if (`STRATEGYRULES == none)
		class'X2StrategyGameRulesetDataStructures'.static.SetTime(NewUnitState.m_RecruitDate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH, class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );	
	else
		NewUnitState.m_RecruitDate = `STRATEGYRULES.GameTime;

	//  note we expect Crew has already had the reference added to it.
	if (NewUnitState.IsSoldier())
	{
		NewUnitState.ValidateLoadout(NewGameState);

		TemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		foreach SoldierUnlockTemplates(UnlockName)
		{
			UnlockTemplate = X2SoldierUnlockTemplate(TemplateMan.FindStrategyElementTemplate(UnlockName));
			if (UnlockTemplate != none)
			{
				UnlockTemplate.OnSoldierAddedToCrew(NewUnitState);
			}
		}

		ClassTemplate = NewUnitState.GetSoldierClassTemplate();
		if (ClassTemplate.bAllowAWCAbilities && NewUnitState.GetRank() >= 1)
		{
			NewUnitState.RollForTrainingCenterAbilities();
		}

		// Default Mental State to ready, so negative modifiers are not automatically applied
		NewUnitState.MentalState = eMentalState_Ready;

		if (!ClassTemplate.bUniqueTacticalToStrategyTransfer)
		{
			NewUnitState.SetCurrentStat(eStat_Will, NewUnitState.GetMaxStat(eStat_Will));
			NewUnitState.UpdateMentalState();

			// @mnauta - getting units with lower will feels bad even when it makes sense
			//if(NewUnitState.NeedsWillRecovery())
			//{
			//	WillProject = XComGameState_HeadquartersProjectRecoverWill(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectRecoverWill'));
			//	WillProject.SetProjectFocus(NewUnitState.GetReference(), NewGameState);
			//	Projects.AddItem(WillProject.GetReference());
			//}

			if(NewUnitState.IsInjured() && NewUnitState.GetStatus() != eStatus_Healing)
			{
				ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));

				ProjectState.SetProjectFocus(NewUnitState.GetReference(), NewGameState);

				NewUnitState.SetStatus(eStatus_Healing);
				Projects.AddItem(ProjectState.GetReference());
			}
		}

		class'X2StrategyGameRulesetDataStructures'.static.OnAddedToCrewSoldierCompatRolls(NewGameState, self, NewUnitState);
		NewUnitState.ApplyFirstTimeStatModifiers( );
	}

	// Need to check That the avenger is streamed in, else photobooth autogen will have none for the formation location and will never trigger.
	// This seems to only be an issue for Pratal Mox and Elena Dragunova being given as rewards when transferring from tactical as the
	// rewards are given before streaming in the avenger, but should catch other newly added crew members as well.
	if (`HQPRES != none && `GAME.GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		NewStaffRefs.AddItem(NewUnitRef);
		NewStaffRefs.AddItem(NewUnitRef); // Yup...

		`HQPRES.GetPhotoboothAutoGen().AddHeadShotRequest(NewUnitRef, 128, 128, OnSoldierHeadCaptureFinishedSmall);
		`HQPRES.GetPhotoboothAutoGen().AddHeadShotRequest(NewUnitRef, 512, 512, OnSoldierHeadCaptureFinishedLarge);
		`HQPRES.GetPhotoboothAutoGen().RequestPhotos();
	}

	// Don't show the new unit popup if its a soldier we rescued
	if (!NewUnitState.bCaptured)
	{
		`XEVENTMGR.TriggerEvent('NewCrewNotification', NewUnitState, self, XComGameState(NewUnitState.Outer));
	}
}

private function OnSoldierHeadCaptureFinishedSmall(StateObjectReference UnitRef)
{
	UpdateNewStaffRefs(UnitRef);
}

private function OnSoldierHeadCaptureFinishedLarge(StateObjectReference UnitRef)
{
	UpdateNewStaffRefs(UnitRef);
}

private function UpdateNewStaffRefs(StateObjectReference UnitRef)
{
	local int ReqIdx;

	ReqIdx = NewStaffRefs.Find('ObjectID', UnitRef.ObjectID);
	if (ReqIdx == -1)
	{
		`Redscreen("Staff photograph handled is not the one requested!");
		return;
	}

	NewStaffRefs.Remove(ReqIdx, 1);
}

// Assumes a new game state has already been created
function ResetToDoWidgetWarnings()
{
	bPlayedWarningNoResearch = false;
	bPlayedWarningUnstaffedEngineer = false;
	bPlayedWarningUnstaffedScientist = false;
	bPlayedWarningNoIncome = false;
	bPlayedWarningNoRing = false;
	bPlayedWarningNoCovertAction = false;
	bHasSeenSupplyDropReminder = false;
}


// =======================================================================================================
// ======================= Strategy Refactor =============================================================
// =======================================================================================================

function ReturnToResistanceHQ(optional bool bOpenResHQGoods, optional bool bAlertResHQGoods)
{
	//local XComGameState NewGameState;
	local XComGameState_Haven ResHQ;
		
	ResHQ = XComGameState_Haven(`XCOMHISTORY.GetGameStateForObjectID(StartingHaven.ObjectID));

	//if (bOpenResHQGoods || bAlertResHQGoods)
	//{
	//	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Set ResHQ Haven on Arrival Flags");
	//	ResHQ = XComGameState_Haven(NewGameState.ModifyStateObject(class'XComGameState_Haven', ResHQ.ObjectID));
	//	ResHQ.bOpenOnXCOMArrival = bOpenResHQGoods;
	//	ResHQ.bAlertOnXCOMArrival = bAlertResHQGoods;
	//	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	//}

	SetPendingPointOfTravel(ResHQ);
}

function bool IsAtResistanceHQ()
{	
	return (CurrentLocation.ObjectID == StartingHaven.ObjectID);
}

function ReturnToSavedLocation()
{
	local XComGameState_GeoscapeEntity ReturnSite;

	ReturnSite = XComGameState_GeoscapeEntity(`XCOMHISTORY.GetGameStateForObjectID(SavedLocation.ObjectID));
	SetPendingPointOfTravel(ReturnSite);
}

function StartUFOChase(StateObjectReference UFORef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_UFO UFOState;
	local XComGameState_MissionSiteAvengerDefense AvengerDefense;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Start UFO Chase");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', ObjectID));

	XComHQ.SavedLocation = CurrentLocation;
	XComHQ.bUFOChaseInProgress = true;
	XComHQ.AttackingUFO = UFORef;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		
	// If there is only one or none UFO chase locations, spawn and fly to Avg Def immediately
	UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(UFORef.ObjectID));
	if (UFOState.bDoesInterceptionSucceed && default.UFOChaseLocations <= 1)
	{
		AvengerDefense = UFOState.CreateAvengerDefenseMission(GetContinent().GetRandomRegionInContinent(Region).GetReference());
		AvengerDefense.ConfirmSelection(); // Set XComHQ to fly to the Avenger Defense mission site
	}
	else // Otherwise pick a random region on the continent for the Avenger to flee towards
	{
		GetContinent().GetRandomRegionInContinent(Region).ConfirmSelection();
	}

	UFOState.FlyTo(self); // Tell the UFO to follow the Avenger
}

//final function SetPendingPointOfTravel(const out XComGameState_GeoscapeEntity GeoscapeEntity, optional bool bInstantCamInterp = false)
final function SetPendingPointOfTravel(const out XComGameState_GeoscapeEntity GeoscapeEntity, optional bool bInstantCamInterp = false, optional bool bRTB = false)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIStrategyMapItem MapItem;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Set Pending Point Of Travel");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', ObjectID));

	XComHQ.SelectedDestination.ObjectID = GeoscapeEntity.ObjectID;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	MapItem = `HQPRES.StrategyMap2D.GetMapItem(GeoscapeEntity);
	if (MapItem != none && !bRTB)
	{
		//bsg-jneal (8.17.16): set the last map item to the selected point of travel then select it, this fixes an issue where the strategy map would focus back on a previously selected different map item incorrectly because LastSelectedMapItem was not updated before opening screens like Mission Ops.
		`HQPRES.StrategyMap2D.LastSelectedMapItem = MapItem;
		`HQPRES.StrategyMap2D.SelectLastSelectedMapItem();
		//bsg-jneal (8.17.16): end
	}

	// Trigger an update of flight status for the Skyanger/Avenger
	XComHQ.UpdateFlightStatus(bInstantCamInterp);
}

// Hook to update the flight data of the Skyranger/Avenger.
final function UpdateFlightStatus(optional bool bInstantCamInterp = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_GeoscapeEntity SelectedDestinationEntity;
	local XComGameState_Skyranger Skyranger;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_ScanningSite ScanSiteState;

	History = `XCOMHISTORY;
	XComHQ = self;
	Skyranger = XComGameState_Skyranger(History.GetGameStateForObjectID(SkyrangerRef.ObjectID));
	SelectedDestinationEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(SelectedDestination.ObjectID));

	if( SelectedDestinationEntity == None )
	{
		// Skyranger RTB
		Skyranger.FlyTo(XComHQ, bInstantCamInterp);
	}
	else if( SelectedDestinationEntity.RequiresAvenger() )
	{
		// update avenger flight

		if( IsSkyrangerDocked() )
		{
			// cleanup the current continent before flying to the new one
			ScanSiteState = XComGameState_ScanningSite(History.GetGameStateForObjectID(XComHQ.CurrentLocation.ObjectID));
			if (ScanSiteState != none)
			{
				ScanSiteState.OnXComLeaveSite();
			}
			
			if (bUFOChaseInProgress && CurrentlyInFlight)
			{
				FlyToUFOChase(SelectedDestinationEntity);
			}
			else
			{
				// zoom zoom
				`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_AvengerLiftOff");

				if (SelectedDestinationEntity.ObjectID != CurrentLocation.ObjectID)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Avenger Flight Event");
					if (SelectedDestinationEntity.Region.ObjectID != 0)
					{
						`XEVENTMGR.TriggerEvent('OnAvengerTakeOff', SelectedDestinationEntity.GetWorldRegion(), SelectedDestinationEntity.GetWorldRegion(), NewGameState);
					}
					else
					{
						`XEVENTMGR.TriggerEvent('OnAvengerTakeOffGeneric', , , NewGameState);
					}

					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
				}

				// avenger fly to SelectedDestinationEntity
				FlyTo(SelectedDestinationEntity, bInstantCamInterp);
			}
		}
		else
		{
			// zoom zoom
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStart");

			// skyranger RTB
			Skyranger.FlyTo(XComHQ, bInstantCamInterp);
		}
	}
	else
	{
		// update skyranger flight

		// zoom zoom
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStart");

		if( SelectedDestinationEntity.RequiresSquad() )
		{
			if( Skyranger.SquadOnBoard )
			{
				// Skyranger fly to SelectedDestinationEntity
				`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.Avenger_Skyranger_Deployed');
				Skyranger.FlyTo(SelectedDestinationEntity, bInstantCamInterp);
			}
			else
			{
				// Skyranger RTB (to pick up squad)
				Skyranger.FlyTo(XComHQ, bInstantCamInterp);
			}
		}
		else
		{
			if( Skyranger.SquadOnBoard )
			{
				// Skyranger RTB (to drop off squad)
				Skyranger.FlyTo(XComHQ, bInstantCamInterp);
			}
			else
			{
				// Skyranger fly to SelectedDestinationEntity
				Skyranger.FlyTo(SelectedDestinationEntity, bInstantCamInterp);
			}
		}
	}
}

function FlyToUFOChase(XComGameState_GeoscapeEntity InTargetEntity)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;

	`assert(InTargetEntity.ObjectID > 0);

	if (TargetEntity.ObjectID != InTargetEntity.ObjectID)
	{
		// set new target location - course change!
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Chase: XComHQ Course Change");
		NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(Class, ObjectID));
		
		NewXComHQ.TargetEntity.ObjectID = InTargetEntity.ObjectID;
		NewXComHQ.SourceLocation = Get2DLocation();
		NewXComHQ.FlightDirection = GetFlightDirection(NewXComHQ.SourceLocation, InTargetEntity.Get2DLocation());
		NewXComHQ.TotalFlightDistance = GetDistance(NewXComHQ.SourceLocation, InTargetEntity.Get2DLocation());
		NewXComHQ.Velocity = vect(0.0, 0.0, 0.0);
		NewXComHQ.CurrentlyInFlight = true;
		NewXComHQ.Flying = true;
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function UpdateMovement(float fDeltaT)
{
	if (CurrentlyInFlight && TargetEntity.ObjectID > 0)
	{
		OldDeltaT = fDeltaT;
		OldVelocity = Velocity;

		if (Flying)
		{
			`GAME.GetGeoscape().m_fTimeScale = InFlightTimeScale; // Speed up the time scale
			UpdateMovementFly(fDeltaT);
		}
	}
}

function TransitionFlightToLand()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_UFO UFOState;
	local XComGameState_MissionSiteAvengerDefense AvengerDefense;
	local XComGameState_GeoscapeEntity NewDestination, SelectedDestinationEntity;
	
	if (bUFOChaseInProgress)
	{
		SelectedDestinationEntity = XComGameState_GeoscapeEntity(`XCOMHISTORY.GetGameStateForObjectID(SelectedDestination.ObjectID));
		AvengerDefense = XComGameState_MissionSiteAvengerDefense(SelectedDestinationEntity);

		if (UFOChaseLocationsCompleted < default.UFOChaseLocations && AvengerDefense == none)
		{
			// Save the updated location and chase count to the history
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Chase: Update XComHQ Location");
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(Class, ObjectID));
			XComHQ.UFOChaseLocationsCompleted++;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			// Pick the next location
			if (class'X2StrategyGameRulesetDataStructures'.static.Roll(UFOChaseChanceToSwitchContinent)) // If random roll success, pick a random continent
			{
				NewDestination = class'UIUtilities_Strategy'.static.GetRandomContinent(SelectedDestinationEntity.Continent).GetRandomRegionInContinent();
			}
			else //	Pick a random region on the current continent, excluding the current one
			{
				NewDestination = SelectedDestinationEntity.GetContinent().GetRandomRegionInContinent(SelectedDestinationEntity.Region);
			}

			NewDestination.ConfirmSelection();
						
			if (UFOChaseLocationsCompleted == (default.UFOChaseLocations - 1))
			{
				UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
				if (!UFOState.bDoesInterceptionSucceed) // If interception does not succeed, have the UFO fly away from the Avenger right before the chase ends
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Chase: Evade UFO");
					UFOState = XComGameState_UFO(NewGameState.ModifyStateObject(class'XComGameState_UFO', UFOState.ObjectID));
					UFOState.bChasingAvenger = false;
					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

					UFOState.FlyTo(class'UIUtilities_Strategy'.static.GetRandomContinent(SelectedDestinationEntity.Continent).GetRandomRegionInContinent());
				}
			}
		}
		else // If XComHQ is being chased and the number of chase locations HAS been reached
		{
			UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
			if (UFOState.bDoesInterceptionSucceed)
			{
				if (AvengerDefense != none) // If Avg Def is created, insta-land to begin the mission
				{
					if (UFOState.GetDistanceToAvenger() < 150) // But only if the UFO is close enough...
					{
						// Reset the UFO chase sequence variables
						ResetUFOChaseSequence(false);
						ProcessFlightComplete();

						`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_UFO_Fly_Stop");
					}
				}
				else // Otherwise, create the Avg Def mission in a random region on the current continent
				{
					UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
					AvengerDefense = UFOState.CreateAvengerDefenseMission(SelectedDestinationEntity.GetContinent().GetRandomRegionInContinent(SelectedDestinationEntity.Region).GetReference());
					AvengerDefense.ConfirmSelection(); // Set XComHQ to fly to the Avenger Defense mission site
				}
			}
			else // If interception fails, land normally
			{
				super.TransitionFlightToLand();
			}
		}
	}
	else
	{
		super.TransitionFlightToLand();
	}
}

function ResetUFOChaseSequence(bool bRemoveUFO)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_UFO UFOState;

	// Reset the UFO chase sequence variables
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Chase Sequence Completed");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(Class, ObjectID));
	XComHQ.bUFOChaseInProgress = false;
	XComHQ.UFOChaseLocationsCompleted = 0;
	XComHQ.AttackingUFO.ObjectID = 0;
	XComHQ.Location.Z = 0.0;

	if (bRemoveUFO)
	{
		UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
		UFOState.RemoveEntity(NewGameState);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function OnTakeOff(optional bool bInstantCamInterp = false)
{
	local XComHQPresentationLayer PresLayer;

	PresLayer = `HQPRES;

	// Update landing site map
	UpdateLandingSite(true);

	// Pause all HQ projects for flight
	PauseProjectsForFlight();

	// Hide map UI elements while flying
	PresLayer.StrategyMap2D.SetUIState(eSMS_Flight);

	if(bInstantCamInterp)
	{
		PresLayer.UIFocusOnEntity(self, 0.66f, 0.0f); //focus the camera on the airship
	}
	else
	{
		PresLayer.UIFocusOnEntity(self, 0.66f); //focus the camera on the airship
	}
}

function OnLanded()
{
	local XComHQPresentationLayer PresLayer;

	PresLayer = `HQPRES;

	// Update landing site map
	UpdateLandingSite(false);

	if (!bReturningFromMission)
	{
		`GAME.GetGeoscape().m_fTimeScale = `GAME.GetGeoscape().ONE_MINUTE;
	};
	
	// Show map UI elements which were hidden while flying
	PresLayer.StrategyMap2D.SetUIState(eSMS_Default);

	PresLayer.StrategyMap2D.SelectedMapItem = none; //bsg-jneal (8.17.16): when we land at a new location, clear the currently selected map item so it can be properly refocused and reselected

	OnFlightCompleted(TargetEntity, true);
}

function UpdateLandingSite(bool bTakeOff)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Landing Site");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));

	if(bTakeOff)
	{
		XComHQ.LandingSiteMap = "";
	}
	else
	{
		XComHQ.LandingSiteMap = class'XGBase'.static.GetBiomeTerrainMap(true);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

final function OnFlightCompleted(StateObjectReference ArrivedAtEntity, optional bool bIsAvenger = false)
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity SelectedDestinationEntity;
	local XComGameState_Skyranger SkyrangerState;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	SelectedDestinationEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(SelectedDestination.ObjectID));

	if( ArrivedAtEntity == SelectedDestination )
	{
		// if HQ resume projects
		if(!bIsAvenger)
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStop");
		}
		else
		{
			//Update the skyranger location to match the avenger after it moves between continents
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Skyranger location");
			SkyrangerState = XComGameState_Skyranger(NewGameState.ModifyStateObject(class'XComGameState_Skyranger', SkyrangerRef.ObjectID));
			SkyrangerState.Location = GetLocation();
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			//Zoom in on the avenger after it lands
			`HQPRES.UIFocusOnEntity(`XCOMHQ);
		}
		
		// Resume all HQ Projects
		ResumeProjectsPostFlight();

		// handle arrival at target destination
		SelectedDestinationEntity.DestinationReached();

		// If XComHQ lands while a chase is in progress and it is not at Avg Def, the UFO was successfully evaded
		if (bUFOChaseInProgress && XComGameState_MissionSiteAvengerDefense(SelectedDestinationEntity) == none)
		{
			ResetUFOChaseSequence(true);
			`HQPRES.UIUFOEvadedAlert();
		}
	}
	
	if( ArrivedAtEntity.ObjectID == ObjectID )
	{
		// Skyranger has completed RTB
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStop");

		if( SelectedDestinationEntity.RequiresSquad() )
		{
			// squad select
			SelectedDestinationEntity.SelectSquad();
		}
		else
		{
			// Unload squad
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unload Squad from Skyranger");
			SkyrangerState = XComGameState_Skyranger(NewGameState.ModifyStateObject(class'XComGameState_Skyranger', SkyrangerRef.ObjectID));
			SkyrangerState.SquadOnBoard = false;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			// continue on to selected destination immediately
			if( ArrivedAtEntity != SelectedDestination )
				UpdateFlightStatus();

			if(`SCREENSTACK.IsInStack(class'UIStrategyMap'))
				UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap')).UpdateButtonHelp();

			// launch after action report on return to base after mission
			if (bReturningFromMission)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete return from mission");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
				XComHQ.bReturningFromMission = false;
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);				
			}
		}
	}
}

function bool IsSkyrangerDocked()
{
	local XComGameStateHistory History;
	local XComGameState_Airship Skyranger;

	History = `XCOMHISTORY;

	Skyranger = XComGameState_Airship(History.GetGameStateForObjectID(SkyrangerRef.ObjectID));

	return ( Skyranger.TargetEntity.ObjectID == ObjectID && Skyranger.IsFlightComplete() );
}

function XComGameState_Skyranger GetSkyranger()
{
	local XComGameState_Skyranger Skyranger;

	Skyranger = XComGameState_Skyranger(`XCOMHISTORY.GetGameStateForObjectID(SkyrangerRef.ObjectID));

	return Skyranger;
}

function PauseProjectsForFlight()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersProject ProjectState;
	local int idx;
	
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pause All Projects");

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		// Pause all projects EXCEPT for those that progress during flight
		if (ProjectState != none && !ProjectState.bProgressesDuringFlight)
		{
			ProjectState = XComGameState_HeadquartersProject(NewGameState.ModifyStateObject(ProjectState.Class, ProjectState.ObjectID));
			ProjectState.PauseProject();
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function ResumeProjectsPostFlight()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersProject ProjectState;
	local int idx;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Resume All Projects");

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ProjectState != none && !ProjectState.bProgressesDuringFlight)
		{
			ProjectState = XComGameState_HeadquartersProject(NewGameState.ModifyStateObject(ProjectState.Class, ProjectState.ObjectID));
			ProjectState.ResumeProject();
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function SaveProjectStatus()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersProject ProjectState;
	local int idx;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Save All Project Status");

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ProjectState != none)
		{
			ProjectState = XComGameState_HeadquartersProject(NewGameState.ModifyStateObject(ProjectState.Class, ProjectState.ObjectID));
			ProjectState.UpdateProject();
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_Avenger';
}

function class<UIStrategyMapItemAnim3D> GetMapItemAnim3DClass()
{
	return class'UIStrategyMapItemAnim3D_Airship';
}

function string GetUIWidgetFlashLibraryName()
{
	return string(class'UIPanel'.default.LibID);
}

function string GetUIPinImagePath()
{
	return "";
}

// The skeletal mesh for this entity's 3D UI
function SkeletalMesh GetSkeletalMesh()
{
	return SkeletalMesh'AvengerIcon_ANIM.Meshes.SM_AvengerIcon';
}

function AnimSet GetAnimSet()
{
	return AnimSet'AvengerIcon_ANIM.Anims.AS_AvengerIcon';
}

function AnimTree GetAnimTree()
{
	return AnimTree'AnimatedUI_ANIMTREE.AircraftIcon_ANIMTREE';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 1.15;
	ScaleVector.Y = 1.15;
	ScaleVector.Z = 1.15;

	return ScaleVector;
}

// Rotation adjustment for the 3D UI static mesh
function Rotator GetMeshRotator()
{
	local Rotator MeshRotation;

	MeshRotation.Roll = 0;
	MeshRotation.Pitch = 0;
	MeshRotation.Yaw = 180 * DegToUnrRot; //Rotate by 180 degrees so the ship is facing the correct way when flying

	return MeshRotation;
}

protected function bool CanInteract()
{
	return false;
}


function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQState;
	local XComGameStateHistory History;
	local int idx;
	local XComGameState_HeadquartersProject ProjectState;
	local XComHQPresentationLayer Pres;
	local array<XComGameState_Unit> UnitsWhichLeveledUp;
	local XComGameState_Objective ObjectiveState, NewObjectiveState;
	local array<XComGameState_Objective> NagObjectives;

	Pres = `HQPRES;
	History = `XCOMHISTORY;
	
	// Don't let any HQ updates complete while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (Pres.StrategyMap2D != none && Pres.StrategyMap2D.m_eUIState != eSMS_Flight && !Pres.ScreenStack.HasInstanceOf(class'UIAlert'))
	{
		// Check objectives for nags
		foreach History.IterateByClassType( class'XComGameState_Objective', ObjectiveState )
		{
			if (ObjectiveState.CheckNagTimer( ))
			{
				NagObjectives.AddItem( ObjectiveState );
			}
		}

		if ((NagObjectives.Length > 0) || ShouldUpdate())
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Update XCom Headquarters" );

			NewXComHQState = XComGameState_HeadquartersXCom( NewGameState.ModifyStateObject( class'XComGameState_HeadquartersXCom', ObjectID ) );

			NewXComHQState.Update(NewGameState, UnitsWhichLeveledUp);

			// start nag states
			foreach NagObjectives(ObjectiveState)
			{
				NewObjectiveState = XComGameState_Objective( NewGameState.ModifyStateObject( class'XComGameState_Objective', ObjectiveState.ObjectID ) );

				NewObjectiveState.BeginNagging( NewXComHQState );
			}

			`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
		}

		// Check projects for completion
		for (idx = 0; idx < Projects.Length; idx++)
		{
			ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));

			if (ProjectState != none)
			{
				if (!ProjectState.bIncremental)
				{
					if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ProjectState.CompletionDateTime, GetCurrentTime()))
					{
						ProjectState.OnProjectCompleted();
						XGMissionControlUI(Pres.GetMgr(class'XGMissionControlUI')).UpdateView();
						HandlePowerOrStaffingChange();
						break;
					}
				}
				else
				{
					if (ProjectState.BlocksRemaining <= 0)
					{
						ProjectState.OnProjectCompleted();
						XGMissionControlUI(Pres.GetMgr(class'XGMissionControlUI')).UpdateView();
						HandlePowerOrStaffingChange();
						break;
					}
					if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ProjectState.BlockCompletionDateTime, GetCurrentTime()))
					{
						ProjectState.OnBlockCompleted();
					}
				}
			}
		}
	}

	super.UpdateGameBoard();
}

function AddSeenCharacterTemplate(X2CharacterTemplate CharacterTemplate)
{
	SeenCharacterTemplates.AddItem(CharacterTemplate.CharacterGroupName);
}

function bool HasSeenCharacterTemplate(X2CharacterTemplate CharacterTemplate)
{
	return (SeenCharacterTemplates.Find(CharacterTemplate.CharacterGroupName) != INDEX_NONE);
}

function XComGameState_WorldRegion GetRegionByName(Name RegionTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion WorldRegion;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', WorldRegion)
	{
		if( WorldRegion.GetMyTemplateName() == RegionTemplateName )
		{
			return WorldRegion;
		}
	}

	return None;
}

//#############################################################################################
//----------------   NARRATIVE   --------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool CanPlayLootNarrativeMoment(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedLootNarrativeMoments.Find('QualifiedName', QualifiedName);

	if(NarrativeInfoIdx == INDEX_NONE || /*!Moment.bFirstTimeAtIndexZero ||*/ (PlayedLootNarrativeMoments[NarrativeInfoIdx].PlayCount < 1))
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function UpdatePlayedLootNarrativeMoments(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;
	local AmbientNarrativeInfo NarrativeInfo;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedLootNarrativeMoments.Find('QualifiedName', QualifiedName);

	if(NarrativeInfoIdx != INDEX_NONE)
	{
		NarrativeInfo = PlayedLootNarrativeMoments[NarrativeInfoIdx];
		`assert(NarrativeInfo.QualifiedName == QualifiedName);
		NarrativeInfo.PlayCount++;
		PlayedLootNarrativeMoments[NarrativeInfoIdx] = NarrativeInfo;
	}
	else
	{
		NarrativeInfo.QualifiedName = QualifiedName;
		NarrativeInfo.PlayCount = 1;
		PlayedLootNarrativeMoments.AddItem(NarrativeInfo);
	}
}

//---------------------------------------------------------------------------------------
function bool CanPlayArmorIntroNarrativeMoment(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedArmorIntroNarrativeMoments.Find('QualifiedName', QualifiedName);

	if(NarrativeInfoIdx == INDEX_NONE || /*!Moment.bFirstTimeAtIndexZero ||*/ (PlayedArmorIntroNarrativeMoments[NarrativeInfoIdx].PlayCount < 1))
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function UpdatePlayedArmorIntroNarrativeMoments(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;
	local AmbientNarrativeInfo NarrativeInfo;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedArmorIntroNarrativeMoments.Find('QualifiedName', QualifiedName);

	if(NarrativeInfoIdx != INDEX_NONE)
	{
		NarrativeInfo = PlayedArmorIntroNarrativeMoments[NarrativeInfoIdx];
		`assert(NarrativeInfo.QualifiedName == QualifiedName);
		NarrativeInfo.PlayCount++;
		PlayedArmorIntroNarrativeMoments[NarrativeInfoIdx] = NarrativeInfo;
	}
	else
	{
		NarrativeInfo.QualifiedName = QualifiedName;
		NarrativeInfo.PlayCount = 1;
		PlayedArmorIntroNarrativeMoments.AddItem(NarrativeInfo);
	}
}

//---------------------------------------------------------------------------------------
function bool CanPlayEquipItemNarrativeMoment(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedEquipItemNarrativeMoments.Find('QualifiedName', QualifiedName);

	if (NarrativeInfoIdx == INDEX_NONE || /*!Moment.bFirstTimeAtIndexZero ||*/ (PlayedEquipItemNarrativeMoments[NarrativeInfoIdx].PlayCount < 1))
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function UpdateEquipItemNarrativeMoments(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;
	local AmbientNarrativeInfo NarrativeInfo;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedEquipItemNarrativeMoments.Find('QualifiedName', QualifiedName);

	if (NarrativeInfoIdx != INDEX_NONE)
	{
		NarrativeInfo = PlayedEquipItemNarrativeMoments[NarrativeInfoIdx];
		`assert(NarrativeInfo.QualifiedName == QualifiedName);
		NarrativeInfo.PlayCount++;
		PlayedEquipItemNarrativeMoments[NarrativeInfoIdx] = NarrativeInfo;
	}
	else
	{
		NarrativeInfo.QualifiedName = QualifiedName;
		NarrativeInfo.PlayCount = 1;
		PlayedEquipItemNarrativeMoments.AddItem(NarrativeInfo);
	}
}

//#############################################################################################
//----------------   TACTICAL TAGS   ----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SortAndCleanUpTacticalTags()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UIMission: Update Chosen Spawning Tags");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.CleanUpTacticalTags();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//---------------------------------------------------------------------------------------
function AddMissionTacticalTags(XComGameState_MissionSite MissionState)
{
	local name GameplayTag;

	if (MissionState != none)
	{
		foreach MissionState.TacticalGameplayTags(GameplayTag)
		{
			TacticalGameplayTags.AddItem(GameplayTag);
		}

		// these two are both structs and cannot be none
		foreach MissionState.GeneratedMission.Mission.ForcedTacticalTags(GameplayTag)
		{
			TacticalGameplayTags.AddItem(GameplayTag);
		}

	}

	CleanUpTacticalTags();
}

//---------------------------------------------------------------------------------------
function RemoveMissionTacticalTags(XComGameState_MissionSite MissionState)
{
	local name GameplayTag;

	if (MissionState != none)
	{
		foreach MissionState.TacticalGameplayTags(GameplayTag)
		{
			TacticalGameplayTags.RemoveItem(GameplayTag);
		}

		// these two are both structs and cannot be none
		foreach MissionState.GeneratedMission.Mission.ForcedTacticalTags(GameplayTag)
		{
			TacticalGameplayTags.RemoveItem(GameplayTag);
		}
	}

	CleanUpTacticalTags();
}

//---------------------------------------------------------------------------------------
// Remove dupes and sort tactical tags
function CleanUpTacticalTags()
{
	local array<name> SortedTacticalTags;
	local int idx;

	// Store old tactical tags for comparison, remove dupes
	for(idx = 0; idx < TacticalGameplayTags.Length; idx++)
	{
		if(SortedTacticalTags.Find(TacticalGameplayTags[idx]) == INDEX_NONE)
		{
			SortedTacticalTags.AddItem(TacticalGameplayTags[idx]);
		}
	}

	SortedTacticalTags.Sort(SortTacticalTags);
	TacticalGameplayTags = SortedTacticalTags;
}

//---------------------------------------------------------------------------------------
private function int SortTacticalTags(name NameA, name NameB)
{
	local string StringA, StringB;

	StringA = string(NameA);
	StringB = string(NameB);

	if(StringA < StringB)
	{
		return 1;
	}
	else if(StringA > StringB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

//#############################################################################################
//----------------   DIFFICULTY HELPERS   -----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetStartingSupplies()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_StartingValueSupplies);
}

//---------------------------------------------------------------------------------------
function int GetStartingIntel()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_StartingValueIntel);
}

//---------------------------------------------------------------------------------------
function int GetStartingAlloys()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_StartingValueAlienAlloys);
}

//---------------------------------------------------------------------------------------
function int GetStartingElerium()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_StartingValueEleriumCrystals);
}

//---------------------------------------------------------------------------------------
function int GetStartingAbilityPoints()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_StartingValueAbilityPoints);
}

//---------------------------------------------------------------------------------------
function int GetStartingCommCapacity()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_StartingCommCapacity);
}

//---------------------------------------------------------------------------------------
function int GetStartingPowerProduced()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_StartingPowerProduced);
}

//---------------------------------------------------------------------------------------
function int GetTrainRookieDays()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_DefaultTrainRookieDays);
}

//---------------------------------------------------------------------------------------
function int GetPsiTrainingDays()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_PsiTrainingDays);
}

//---------------------------------------------------------------------------------------
function float GetPsiTrainingScalar()
{
	return `ScaleStrategyArrayFloat(default.PsiTrainingRankScalar);
}

//---------------------------------------------------------------------------------------
function int GetStartingRegionSupplyDrop()
{
	return `ScaleStrategyArrayInt(default.StartingRegionSupplyDrop);
}

//---------------------------------------------------------------------------------------
function int GetRespecSoldierDays()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_DefaultRespecSoldierDays);
}

//---------------------------------------------------------------------------------------
function int GetBondSoldiersDays()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_DefaultBondSoldiersDays);
}

//---------------------------------------------------------------------------------------
function int GetRemoveTraitDays()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_DefaultRemoveTraitDays);
}

//---------------------------------------------------------------------------------------
function int GetShakenChance()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_ShakenChance);
}

//---------------------------------------------------------------------------------------
function int GetShakenRecoveryMissions()
{
	return `ScaleStrategyArrayInt(default.XComHeadquarters_ShakenRecoverMissionsRequired);
}

simulated native function int GetGenericKeyValue(string key);
simulated native function SetGenericKeyValue(string key, INT Value);

/////////////////////////////////////////////////////////////////////////////////////////
// cpptext

cpptext
{
public:
	void Serialize(FArchive& Ar);
};

DefaultProperties
{
	CurrentScanRate=1.0
	BonusAbilityPointScalar=1.0
	ChosenKnowledgeGainScalar=1.0
}
