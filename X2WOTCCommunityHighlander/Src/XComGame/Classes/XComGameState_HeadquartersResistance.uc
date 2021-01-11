//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersResistance.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for the resistance's HQ in the 
//           X-Com 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersResistance extends XComGameState_BaseObject native(Core) config(GameData);

// Basic Info
var() TDateTime                           StartTime;
var() array<StateObjectReference>         Recruits;
var array<Commodity>					  ResistanceGoods;
var array<StateObjectReference>			  PersonnelGoods; // Subset of Resistance goods storing the personnel options each month
var array<TResistanceActivity>			  ResistanceActivities;
var int									  NumMonths;
var array<name>							  SoldierClassDeck;   //Soldier classes to randomly pick from when generating rewards

// Timers
var() TDateTime							  MonthIntervalStartTime;
var() TDateTime							  MonthIntervalEndTime;

// POI Timers
var() TDateTime							  ForceStaffPOITime;
var() bool								  bStaffPOISpawnedDuringTimer;

// Modifiers
var int									  SupplyDropPercentIncrease; // AllIn Continent bonus
var int									  IntelRewardPercentIncrease; // SpyRing Continent bonus
var int									  RecruitCostModifier; // ToServeMankind Continent bonus
var float								  RecruitScalar; // Midnight raids
var float								  SupplyDropPercentDecrease; // Rural Checkpoints
var float								  SavedSupplyDropPercentDecrease; // Saved value since dark events get deactivated on end of month before Monthly Report is shown

// Flags
var bool								  bInactive; // Resistance isn't active at the beginning of the tutorial
var() bool								  bEndOfMonthNotify;
var() bool								  bHasSeenNewResistanceGoods;
var() bool								  bIntelMode; // If scanning at Resistance HQ is intel mode
var() bool								  bFirstPOIActivated; // If ResHQ should spawn the first POI upon the next Geoscape entry
var() bool								  bFirstPOISpawned; // Has the first POI been spawned yet

// Resistance Scanning Mode
var() name								  ResistanceMode;

// VIP Rewards
var string								  VIPRewardsString;

// Rewards Recap
var array<string>						  RecapRewardsStrings;
var array<string>						  RecapGlobalEffectsGood;
var array<string>						  RecapGlobalEffectsBad;

// POIs
var array<StateObjectReference>			  ActivePOIs; // All of the POIs currently active on the map

// Factions
var array<StateObjectReference>			  Factions;

// Covert Actions
var array<name>							  RookieCovertActions; // List of covert actions which do not have veteran soldier requirements, so can always be started
var array<name>							  CovertActionExclusionList; // The list of covert actions currently in the facility, saved to avoid duplicates
var array<name>							  CovertActionDarkEventRisks; // The list of Risks added by Dark Events, which should appear on every Action and have double chance of occuring
var float								  CovertActionDurationModifier;
var bool								  bCovertActionStartedThisMonth;
var bool								  bPreventCovertActionAmbush; // Resistance Order: Guardian Angels
var bool								  bCovertActionSafeguardActive;
var TDateTime							  NextCovertActionAmbushTime;

// Expired Mission
var StateObjectReference				  ExpiredMission;

// Card vars
var array<StateObjectReference>			  WildCardSlots;
var array<StateObjectReference>			  OldWildCardSlots;

// Resistance Order Modifiers
var float								  CohesionScalar;
var float								  AbilityPointScalar;
var float								  MissionResourceRewardScalar;
var float								  WeaponsResearchScalar;
var float								  ArmorResearchScalar;
var float								  WillRecoveryRateScalar;
var float								  FacilityBuildScalar;
var float								  ExcavateScalar;

// Config Vars
var config int							  MinSuppliesInterval;
var config int							  MaxSuppliesInterval;
var config array<int>					  RecruitSupplyCosts;
var config int							  RecruitOrderTime;
var config array<int>					  StartingNumRecruits;
var config array<int>					  RefillNumRecruits;
var config ECharacterPoolSelectionMode	  RecruitsCharacterPoolSelectionMode;
var config array<int>					  BaseGoodsCost;
var config array<int>					  GoodsCostVariance;
var config array<int>					  GoodsCostIncrease;
var config array<int>					  ResHQToggleCost;
var config int							  NumToRemoveFromSoldierDeck;
var config array<StrategyCostScalar>	  ResistanceGoodsCostScalars;
var config array<int>					  AdditionalPOIChance;
var config array<float>					  NeededPOIWeightModifier;
var config int							  StartingStaffPOITimerDays;
var config int							  StaffPOITimerDays;
var config int							  CovertActionAmbushSafeguardDays;

// Card config
var config int							  StartingNumWildCardSlots;

// Popup Text
var localized string					  SupplyDropPopupTitle;
var localized string					  SupplyDropPopupPerRegionText;
var localized string					  SupplyDropPopupBonusText;
var localized string					  SupplyDropPopupTotalText;
var localized string					  IntelDropPopupPerRegionText;

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// Set-up Resistance HQ at the start of the game
static function SetUpHeadquarters(XComGameState StartState, optional bool bTutorialEnabled = false)
{
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int idx;

	//Locate the resistance HQ in the same region
	ResistanceHQ = XComGameState_HeadquartersResistance(StartState.CreateNewStateObject(class'XComGameState_HeadquartersResistance'));

	// Set Start Date
	class'X2StrategyGameRulesetDataStructures'.static.SetTime(ResistanceHQ.StartTime, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH, 
		class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );

	// Set the active flag
	ResistanceHQ.bInactive = bTutorialEnabled;
	ResistanceHQ.SetProjectedMonthInterval(ResistanceHQ.StartTime);

	ResistanceHQ.ForceStaffPOITime = ResistanceHQ.StartTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(ResistanceHQ.ForceStaffPOITime, ResistanceHQ.StartingStaffPOITimerDays);

	ResistanceHQ.SupplyDropPercentDecrease = 0.0f;

	// Used to create the resistance recruits here, moved to XComHQ setup so character pool characters fill staff first

	// Create Resistance Activities List
	ResistanceHQ.ResetActivities();

	// Set up Resistance Factions
	ResistanceHQ.SetUpFactions(StartState);

	// Create the Rookie Covert Actions list
	ResistanceHQ.FindRookieCovertActions();
	
	// Give starting wild card slots
	for(idx = 0; idx < default.StartingNumWildCardSlots; idx++)
	{
		ResistanceHQ.AddWildCardSlot();
	}
}

//---------------------------------------------------------------------------------------
function CreateRecruits(XComGameState StartState)
{
	local XComGameState_Unit NewSoldierState;
	local XComOnlineProfileSettings ProfileSettings;
	local int Index;

	assert(StartState != none);
	ProfileSettings = `XPROFILESETTINGS;

	for(Index = 0; Index < GetStartingNumRecruits(); ++Index)
	{
		NewSoldierState = `CHARACTERPOOLMGR.CreateCharacter(StartState, ProfileSettings.Data.m_eCharPoolUsage);
		NewSoldierState.RandomizeStats();
		if(!NewSoldierState.HasBackground())
			NewSoldierState.GenerateBackground();
		NewSoldierState.ApplyInventoryLoadout(StartState);
		Recruits.AddItem(NewSoldierState.GetReference());
	}

	RecruitScalar = 1.0f;
}

//---------------------------------------------------------------------------------------
function BuildSoldierClassDeck()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local int i;

	if(SoldierClassDeck.Length != 0)
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
			}
		}
	}
	if(default.NumToRemoveFromSoldierDeck >= SoldierClassDeck.Length)
	{
		`RedScreen("Soldier class deck problem. No elements removed. @gameplay_engineers Author: mnauta");
		return;
	}
	for(i = 0; i < default.NumToRemoveFromSoldierDeck; ++i)
	{
		SoldierClassDeck.Remove(`SYNC_RAND(SoldierClassDeck.Length), 1);
	}
}

//---------------------------------------------------------------------------------------
function name SelectNextSoldierClass()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local name RetName;
	local int idx;
	local array<name> NeededClasses, RewardClasses, AvoidedClasses; //issue #113: added AvoidedClasses array

	History = `XCOMHISTORY;

	if(SoldierClassDeck.Length == 0)
	{
		BuildSoldierClassDeck();
	}
	 
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NeededClasses = XComHQ.GetNeededSoldierClasses();
	//start Issue #113: we use AvoidedClasses to not count classes that mod authors do not want used here
	AvoidedClasses = class'CHHelpers'.default.ClassesExcludedFromResHQ;
	
	for(idx = 0; idx < SoldierClassDeck.Length; idx++)
	{
		if(NeededClasses.Find(SoldierClassDeck[idx]) != INDEX_NONE && AvoidedClasses.Find(SoldierClassDeck[idx]) == INDEX_NONE)
		{
			RewardClasses.AddItem(SoldierClassDeck[idx]);
		}
	}

	if(RewardClasses.Length == 0)
	{
		BuildSoldierClassDeck();

		for(idx = 0; idx < SoldierClassDeck.Length; idx++)
		{
			if(NeededClasses.Find(SoldierClassDeck[idx]) != INDEX_NONE && AvoidedClasses.Find(SoldierClassDeck[idx]) == INDEX_NONE)
			{
				RewardClasses.AddItem(SoldierClassDeck[idx]);
			}
		}
	}
	//end issue #113
	
	`assert(SoldierClassDeck.Length != 0);
	`assert(RewardClasses.Length != 0);
	RetName = RewardClasses[`SYNC_RAND(RewardClasses.Length)];
	SoldierClassDeck.Remove(SoldierClassDeck.Find(RetName), 1);

	return RetName;
}

//#############################################################################################
//----------------   UPDATE AND TIME MANAGEMENT   ---------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// returns true if an internal value has changed (lots of time checks)
function bool Update(XComGameState NewGameState)
{
	local UIStrategyMap StrategyMap;
	local bool bUpdated;

	StrategyMap = `HQPRES.StrategyMap2D;
	bUpdated = false;
	
	// Don't trigger end of month while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (!bInactive)
		{
			if (bCovertActionSafeguardActive && class'X2StrategyGameRulesetDataStructures'.static.LessThan(NextCovertActionAmbushTime, `STRATEGYRULES.GameTime))
			{
				bCovertActionSafeguardActive = false;
				UpdateCovertActionNegatedRisks(NewGameState);
				bUpdated = true;
			}

			if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(MonthIntervalEndTime, `STRATEGYRULES.GameTime))
			{
				OnEndOfMonth(NewGameState);
				bUpdated = true;
			}
		}
	}

	return bUpdated;
}

//---------------------------------------------------------------------------------------
function OnEndOfMonth(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_BlackMarket BlackMarket;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	// Start Issue #539
	//
	// Notify listeners of the start of end-of-month processing.
	`XEVENTMGR.TriggerEvent('PreEndOfMonth', self, self, NewGameState);
	// End Issue #539

	bEndOfMonthNotify = true;
	GiveSuppliesReward(NewGameState);
	SetProjectedMonthInterval(`STRATEGYRULES.GameTime);
	//CleanUpResistanceGoods(NewGameState);
	//SetUpResistanceGoods(NewGameState);
	RefillRecruits(NewGameState);
	ResetMonthlyMissingPersons(NewGameState);

	SavedSupplyDropPercentDecrease = SupplyDropPercentDecrease; // Save the supply drop decrease caused by any Dark Events before they are reset

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	AlienHQ.EndOfMonth(NewGameState);

	BlackMarket = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	BlackMarket = XComGameState_BlackMarket(NewGameState.ModifyStateObject(class'XComGameState_BlackMarket', BlackMarket.ObjectID));
	BlackMarket.ResetBlackMarketGoods(NewGameState);

	FactionsOnEndOfMonth(NewGameState);
	bCovertActionStartedThisMonth = false;

	NumMonths++;
}

//---------------------------------------------------------------------------------------
function RefillRecruits(XComGameState NewGameState)
{
	local array<StateObjectReference> NewRecruitList;
	local XComGameState_Unit SoldierState;
	local XComOnlineProfileSettings ProfileSettings;
	local int idx;

	ProfileSettings = `XPROFILESETTINGS;

	for(idx = 0; idx < GetRefillNumRecruits(); idx++)
	{
		SoldierState = `CHARACTERPOOLMGR.CreateCharacter(NewGameState, ProfileSettings.Data.m_eCharPoolUsage);
		SoldierState.RandomizeStats();
		if(!SoldierState.HasBackground())
			SoldierState.GenerateBackground();
		SoldierState.ApplyInventoryLoadout(NewGameState);
		NewRecruitList.AddItem(SoldierState.GetReference());
	}

	for(idx = 0; idx < Recruits.Length; idx++)
	{
		NewRecruitList.AddItem(Recruits[idx]);
	}

	Recruits = NewRecruitList;
}

//---------------------------------------------------------------------------------------
function ResetMonthlyMissingPersons(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
		RegionState.UpdateMissingPersons();
		RegionState.NumMissingPersonsThisMonth = 0;
	}
}

//---------------------------------------------------------------------------------------
function GiveSuppliesReward(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_ResourceCache CacheState;
	local int TotalReward;

	History = `XCOMHISTORY;
	// Start Issue #539 - Added the NewGameState argument
	TotalReward = GetSuppliesReward_CH(, NewGameState);
	// End Issue #539
	
	if (TotalReward > 0)
	{
		CacheState = XComGameState_ResourceCache(History.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));
		CacheState = XComGameState_ResourceCache(NewGameState.ModifyStateObject(class'XComGameState_ResourceCache', CacheState.ObjectID));
		CacheState.ShowResourceCache(NewGameState, TotalReward);
	}
	// Start Issue #539
	else
	{
		// Let listeners know that we're in negative income territory. This
		// also allows them to make adjustments to the game state.
		TriggerProcessNegativeIncome(NewGameState, TotalReward);
	}
	// End Issue #539
}

// Start Issue #539
//
// Fires a 'ProcessNegativeIncome' event that allows mods to do their
// own processing when XCOM's income at the end of the month is negative.
// This allows mods to actually deduct supplies from the Avenger's pool.
//
// The event takes the form:
//
//   {
//      ID: ProcessNegativeIncome,
//      Data: [in int SupplyAmount],
//      Source: self (XCGS_HeadquartersResistance)
//   }
//
function TriggerProcessNegativeIncome(XComGameState NewGameState, int SupplyValue)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'ProcessNegativeIncome';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVInt;
	Tuple.Data[0].i = SupplyValue;  // The amount of negative supplies

	`XEVENTMGR.TriggerEvent('ProcessNegativeIncome', Tuple, self, NewGameState);
}
// End Issue #539

//---------------------------------------------------------------------------------------
// Issue #539
//
// Retain this function for backwards compatibility.
function int GetSuppliesReward(optional bool bUseSavedPercentDecrease)
{
	return GetSuppliesReward_CH(bUseSavedPercentDecrease);
}

// This is the old GetSuppliesReward() function with an optional NewGameState argument
// that can be passed to listeners that want to modify the supplies reward.
function int GetSuppliesReward_CH(optional bool bUseSavedPercentDecrease, optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;
	local int SupplyReward;
	local bool SkipRegionSupplyRewards;  // Issue #539

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SupplyReward = 0;

	// Start Issue #539
	if (NewGameState != none)
	{
		SkipRegionSupplyRewards = TriggerOverrideSupplyDrop(SupplyReward, NewGameState);
	}

	// Issue #539: Only the condition is new.
	if (!SkipRegionSupplyRewards)
	{
		foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
		{
			SupplyReward += RegionState.GetSupplyDropReward();
		}
	}
	// End Issue # 539

	// Subtract the upkeep from the Avenger facilities
	SupplyReward -= XComHQ.GetFacilityUpkeepCost();

	// Bonus from PopSupport res cards
	SupplyReward += Round(float(SupplyReward) * (float(SupplyDropPercentIncrease) / 100.0));
	
	// Before the Monthly Report, use the saved decrease value, it will already have been reset when the Dark Event deactivated at months end otherwise
	if (bUseSavedPercentDecrease)
		SupplyReward -= Round(float(SupplyReward) * SavedSupplyDropPercentDecrease);
	else
		SupplyReward -= Round(float(SupplyReward) * SupplyDropPercentDecrease);

	return SupplyReward;
}

// Start Issue #539
// 
// Fires an 'OverrideSupplyDrop' event that allows mods to override the
// amount of supplies awarded at the end of the month.
//
// The method returns `true` if the base game region-based income should
// be skipped. `false` means that the region-based income should be added
// to the total.
//
// The event takes the form:
//
//   {
//      ID: OverrideSupplyDrop,
//      Data: [inout bool SkipRegionSupplyRewards, inout int SupplyAmount],
//      Source: self (XCGS_HeadquartersResistance)
//   }
//
function bool TriggerOverrideSupplyDrop(out int SupplyAmount, XComGameState NewGameState)
{
	local XComLWTuple OverrideTuple;

	// LWS - set up a Tuple for return value - return value is supplies generated this month
	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideSupplyDrop';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;  // Whether the game should skip adding region income to the supply drop
	OverrideTuple.Data[1].kind = XComLWTVInt;
	OverrideTuple.Data[1].i = SupplyAmount;  // Return Value of supplies

	`XEVENTMGR.TriggerEvent('OverrideSupplyDrop', OverrideTuple, self, NewGameState);

	SupplyAmount = OverrideTuple.Data[1].i;

	return OverrideTuple.Data[0].b;
}
// End Issue #539

//---------------------------------------------------------------------------------------
function SetProjectedMonthInterval(TDateTime Start, optional float TimeRemaining = -1.0)
{
	local int HoursToAdd;

	MonthIntervalStartTime = Start;
	MonthIntervalEndTime = MonthIntervalStartTime;

	if(TimeRemaining > 0)
	{
		class'X2StrategyGameRulesetDataStructures'.static.AddTime(MonthIntervalEndTime, TimeRemaining);
	}
	else
	{
		HoursToAdd = default.MinSuppliesInterval + `SYNC_RAND(
			default.MaxSuppliesInterval-default.MinSuppliesInterval+1);
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(MonthIntervalEndTime, HoursToAdd);
	}
}

simulated public function EndOfMonthPopup()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Supplies Reward Popup Handling");
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', self.ObjectID));

	ResistanceHQ.bEndOfMonthNotify = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	`GAME.GetGeoscape().Pause();

	`HQPRES.UIMonthlyReport();
}

simulated function array<TResistanceActivity> GetMonthlyActivity(optional bool bAliens)
{
	local array<TResistanceActivity> arrActions;
	local TResistanceActivity ActivityStruct;
	local int idx;
	
	for(idx = 0; idx < ResistanceActivities.Length; idx++)
	{
		ActivityStruct = ResistanceActivities[idx];

		if(ActivityShouldAppearInReport(ActivityStruct))
		{
			ActivityStruct.Rating = GetActivityTextState(ActivityStruct);
			if ((ActivityStruct.Rating == eUIState_Bad && bAliens) ||
				(ActivityStruct.Rating == eUIState_Good && !bAliens))
			{
				arrActions.AddItem(ActivityStruct);
			}
		}
	}

	return arrActions;
}

simulated function name GetResistanceMoodEvent()
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ResistanceActivityTemplate ActivityTemplate;
	local TResistanceActivity ActivityStruct;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int idx, iMissionsFailed, iDoomReduced;
	local float DoomRatio;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for (idx = 0; idx < ResistanceActivities.Length; idx++)
	{
		ActivityStruct = ResistanceActivities[idx];
		ActivityTemplate = X2ResistanceActivityTemplate(StratMgr.FindStrategyElementTemplate(ActivityStruct.ActivityTemplateName));

		// Count the number of missions which were failed
		if (ActivityTemplate.bMission && ActivityTemplate.bAlwaysBad)
		{
			iMissionsFailed += ActivityStruct.Count;
		}

		// Count the amount of doom the player reduced
		if (ActivityTemplate.DataName == 'ResAct_AvatarProgressReduced')
		{
			iDoomReduced += ActivityStruct.Count;
		}
	}

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	DoomRatio = (AlienHQ.GetCurrentDoom() * 1.0) / AlienHQ.GetMaxDoom();

	if (iMissionsFailed >= 2 && iDoomReduced == 0)
	{
		return 'MonthlyReport_Bad';
	}
	else if (iMissionsFailed >= 1 || (iDoomReduced == 0 && DoomRatio >= 0.66))
	{
		return 'MonthlyReport_Moderate';
	}
	else
	{
		return 'MonthlyReport_Good';
	}
}

simulated private function EndOfMonthPopupCallback(Name eAction)
{
	`GAME.GetGeoscape().Resume();

	if(`GAME.GetGeoscape().IsScanning())
		`HQPRES.StrategyMap2D.ToggleScan();
}

//---------------------------------------------------------------------------------------
function ResetActivities()
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> Activities;
	local X2ResistanceActivityTemplate ActivityTemplate;
	local TResistanceActivity ActivityStruct, EmptyActivityStruct;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	Activities = StratMgr.GetAllTemplatesOfClass(class'X2ResistanceActivityTemplate');
	ResistanceActivities.Length = 0;

	for(idx = 0; idx < Activities.Length; idx++)
	{
		ActivityTemplate = X2ResistanceActivityTemplate(Activities[idx]);
		ActivityStruct = EmptyActivityStruct;
		ActivityStruct.ActivityTemplateName = ActivityTemplate.DataName;
		ActivityStruct.Title = ActivityTemplate.DisplayName;
		ResistanceActivities.AddItem(ActivityStruct);
	}
}

//---------------------------------------------------------------------------------------
function IncrementActivityCount(X2ResistanceActivityTemplate ActivityTemplate, optional int DeltaCount=1)
{
	local int ActivityIndex;
	local TResistanceActivity ActivityStruct;

	ActivityIndex = ResistanceActivities.Find('ActivityTemplateName', ActivityTemplate.DataName);
	if (ActivityIndex == INDEX_NONE) // new activity after game in progress
	{
		ActivityIndex = ResistanceActivities.Length;

		ActivityStruct.ActivityTemplateName = ActivityTemplate.DataName;
		ActivityStruct.Title = ActivityTemplate.DisplayName;
		ResistanceActivities.AddItem(ActivityStruct);
	}

	ResistanceActivities[ActivityIndex].Count += DeltaCount;
	ResistanceActivities[ActivityIndex].LastIncrement = DeltaCount;
}

//---------------------------------------------------------------------------------------
static function RecordResistanceActivity(XComGameState NewGameState, name ActivityTemplateName, optional int DeltaCount=1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local X2ResistanceActivityTemplate ActivityTemplate;
	local X2StrategyElementTemplateManager StratMgr;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager( );
	ActivityTemplate = X2ResistanceActivityTemplate(StratMgr.FindStrategyElementTemplate(ActivityTemplateName));
	if (ActivityTemplate == none)
	{
		`RedScreenOnce( "Unable to find resistance activity template '"$ActivityTemplateName$"'." );
		return;
	}

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResistanceHQ)
	{
		break;
	}

	if (ResistanceHQ == none)
	{
		History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true /* AllowNULL */));
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', (ResistanceHQ == none) ? -1 : ResistanceHQ.ObjectID));
	}
	
	ResistanceHQ.IncrementActivityCount(ActivityTemplate, DeltaCount);

	`XEVENTMGR.TriggerEvent('ResistanceActivity', ActivityTemplate, ResistanceHQ, NewGameState);
}

//---------------------------------------------------------------------------------------
function bool ActivityShouldAppearInReport(TResistanceActivity ActivityStruct)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ResistanceActivityTemplate ActivityTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ActivityTemplate = X2ResistanceActivityTemplate(StratMgr.FindStrategyElementTemplate(ActivityStruct.ActivityTemplateName));

	if(ActivityTemplate != none)
	{
		if(ActivityStruct.Count == 0)
		{
			return false;
		}

		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function EUIState GetActivityTextState(TResistanceActivity ActivityStruct)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ResistanceActivityTemplate ActivityTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ActivityTemplate = X2ResistanceActivityTemplate(StratMgr.FindStrategyElementTemplate(ActivityStruct.ActivityTemplateName));

	if(ActivityTemplate != none)
	{
		if(ActivityTemplate.bAlwaysBad)
		{
			return eUIState_Bad;
		}
		
		if(ActivityTemplate.bAlwaysGood)
		{
			return eUIState_Good;
		}
		
		if((ActivityStruct.Count >= ActivityTemplate.MinGoodValue && ActivityStruct.Count <= ActivityTemplate.MaxGoodValue))
		{
			return eUIState_Good;
		}
		else
		{
			return eUIState_Bad;
		}
	}
}

//#############################################################################################
//----------------   SCANNING MODE   ----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
function X2ResistanceModeTemplate GetResistanceMode()
{
	return X2ResistanceModeTemplate(GetMyTemplateManager().FindStrategyElementTemplate(ResistanceMode));
}

//---------------------------------------------------------------------------------------
function ActivateResistanceMode(XComGameState NewGameState)
{
	GetResistanceMode().OnActivatedFn(NewGameState, self.GetReference());
}

//---------------------------------------------------------------------------------------
function DeactivateResistanceMode(XComGameState NewGameState)
{
	GetResistanceMode().OnDeactivatedFn(NewGameState, self.GetReference());
}

//---------------------------------------------------------------------------------------
function OnXCOMArrives()
{
	local XComGameState NewGameState;

	if (GetResistanceMode().OnXCOMArrivesFn != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Arrive Res HQ: Apply Scan Mode Bonus");	
		GetResistanceMode().OnXCOMArrivesFn(NewGameState, self.GetReference());
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function OnXCOMLeaves()
{
	local XComGameState NewGameState;

	if (GetResistanceMode().OnXCOMLeavesFn != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Leave Res HQ: Remove Scan Mode Bonus");
		GetResistanceMode().OnXCOMLeavesFn(NewGameState, self.GetReference());
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//#############################################################################################
//----------------   RESISTANCE GOODS   -------------------------------------------------------
//#############################################################################################

// @mnauta - Deprecated

//---------------------------------------------------------------------------------------
function BuyResistanceGood(StateObjectReference RewardRef, optional bool bGrantForFree)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Reward RewardState;
	local StrategyCost FreeCost;
	local int ItemIndex, idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ItemIndex = ResistanceGoods.Find('RewardRef', RewardRef);

	if(ItemIndex != INDEX_NONE)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy Resistance Good");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		if( bGrantForFree )
		{
			ResistanceGoods[ItemIndex].Cost = FreeCost;
		}

		XComHQ.BuyCommodity(NewGameState, ResistanceGoods[ItemIndex]);
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', self.ObjectID));
		ResistanceHQ.ResistanceGoods.Remove(ItemIndex, 1);

		// If the reward was a resistance mode, remove all others from the goods list. Player can only switch modes once per month.
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
		if (RewardState.GetMyTemplateName() == 'Reward_ResistanceMode')
		{
			for (idx = 0; idx < ResistanceHQ.ResistanceGoods.Length; idx++)
			{
				RewardState = XComGameState_Reward(History.GetGameStateForObjectID(ResistanceHQ.ResistanceGoods[idx].RewardRef.ObjectID));
				if (RewardState.GetMyTemplateName() == 'Reward_ResistanceMode')
				{
					RewardState.CleanUpReward(NewGameState);
					ResistanceHQ.ResistanceGoods.Remove(idx, 1);
					idx--;
				}
			}
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//#############################################################################################
//----------------   RECRUITS   ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetRecruitSupplyCost()
{
	return Round(float(`ScaleStrategyArrayInt(default.RecruitSupplyCosts) + RecruitCostModifier) * RecruitScalar);
}

//---------------------------------------------------------------------------------------
// Give a recruit from the Resistance to XCom
function GiveRecruit(StateObjectReference RecruitReference)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_Unit UnitState;
	local int RecruitIndex;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Order Recruit");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));

	// Pay Cost and Order Recruit
	XComHQ.AddResource(NewGameState, 'Supplies', -ResistanceHQ.GetRecruitSupplyCost());
	
	if (RecruitOrderTime > 0)
	{
		XComHQ.OrderStaff(RecruitReference, RecruitOrderTime);
	}
	else // No delay in recruiting, so add the unit immediately
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RecruitReference.ObjectID));
		`assert(UnitState != none);

		// If FNG is unlocked, rank up the soldier to Squaddie
		if (XComHQ.HasSoldierUnlockTemplate('FNGUnlock'))
		{
			UnitState.SetXPForRank(1);
			UnitState.StartingRank = 1;
			UnitState.RankUpSoldier(NewGameState, XComHQ.SelectNextSoldierClass());
			UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
		}

		UnitState.ApplyBestGearLoadout(NewGameState);
		XComHQ.AddToCrew(NewGameState, UnitState);
		XComHQ.HandlePowerOrStaffingChange(NewGameState);
	}

	// Remove from recruit list
	RecruitIndex = ResistanceHQ.Recruits.Find('ObjectID', RecruitReference.ObjectID);

	if(RecruitIndex != INDEX_NONE)
	{
		ResistanceHQ.Recruits.Remove(RecruitIndex, 1);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//#############################################################################################
//----------------   REWARD RECAP   -----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function ClearVIPRewardsData()
{
	VIPRewardsString = "";
}

//---------------------------------------------------------------------------------------
function ClearRewardsRecapData()
{
	RecapRewardsStrings.Length = 0;
	RecapGlobalEffectsGood.Length = 0;
	RecapGlobalEffectsBad.Length = 0;
}

//---------------------------------------------------------------------------------------
static function SetRecapRewardString(XComGameState NewGameState, array<string> RewardStrings)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResistanceHQ)
	{
		break;
	}

	if(ResistanceHQ == none)
	{
		History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	}

	ResistanceHQ.RecapRewardsStrings = RewardStrings;
}

static function SetVIPRewardString(XComGameState NewGameState, string RewardString)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResistanceHQ)
	{
		break;
	}

	if(ResistanceHQ == none)
	{
		History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	}

	ResistanceHQ.VIPRewardsString = RewardString;
}

//---------------------------------------------------------------------------------------
static function AddGlobalEffectString(XComGameState NewGameState, string EffectString, bool bBad)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResistanceHQ)
	{
		break;
	}

	if(ResistanceHQ == none)
	{
		History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	}

	if(bBad)
	{
		ResistanceHQ.RecapGlobalEffectsBad.AddItem(EffectString);
	}
	else
	{
		ResistanceHQ.RecapGlobalEffectsGood.AddItem(EffectString);
	}
}

// #######################################################################################
// --------------------------- POIS ------------------------------------------------------
// #######################################################################################

function XComGameState_PointOfInterest GetPOIStateFromTemplateName(name TemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_PointOfInterest', POIState)
	{
		if (POIState.GetMyTemplateName() == TemplateName)
		{
			return POIState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function AttemptSpawnRandomPOI(optional XComGameState NewGameState)
{
	local bool bSubmitLocally;

	// If there are less than 3 POIs on the board, attempt to spawn a new one
	if (ActivePOIs.Length < 3)
	{
		// If there are no POIs, or the roll succeeds, or the player has just finished the first POI, spawn another one immediately
		if (ActivePOIs.Length == 0 || class'X2StrategyGameRulesetDataStructures'.static.Roll(`ScaleStrategyArrayInt(AdditionalPOIChance)) ||
		class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M0_CompleteGuerillaOps') == eObjectiveState_InProgress ||
		class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M1_TutorialLostAndAbandonedComplete') == eObjectiveState_InProgress ||
		class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M1_LostAndAbandonedComplete') == eObjectiveState_InProgress)
		{
			if (NewGameState == None)
			{
				bSubmitLocally = true;
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("POI Complete: Spawn another POI");
			}

			ChoosePOI(NewGameState, true);
			
			if (bSubmitLocally)
			{
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function StateObjectReference ChoosePOI(XComGameState NewGameState, optional bool bSpawnImmediately = false)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_PointOfInterest POIState;
	local array<XComGameState_PointOfInterest> POIDeck;
	local bool bStaffPOISpawnedFromTimer;
	
	ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ObjectID));

	// If force staff POI timer is up and a staff POI has not been spawned, choose one to give
	if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ForceStaffPOITime, `STRATEGYRULES.GameTime))
	{
		// Timer is up and no staff POI was spawned, so force pick one
		if (!bStaffPOISpawnedDuringTimer)
		{
			POIDeck = BuildPOIDeck(true);
			bStaffPOISpawnedFromTimer = true;
		}
		
		// If a staff POI couldn't be found, or timer is up and staff was spawned already during its duration, pick from the full set
		// (Will exclude Staff POIs from the Deck because of their CanAppearFn logic until bStaffPOISpawnedDuringTimer is reset)
		if (bStaffPOISpawnedDuringTimer || POIDeck.Length == 0)
		{
			POIDeck = BuildPOIDeck();
		}

		// Reset the POI timer
		ResHQ.ForceStaffPOITime = `STRATEGYRULES.GameTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddDays(ResHQ.ForceStaffPOITime, StaffPOITimerDays);
		ResHQ.bStaffPOISpawnedDuringTimer = false;
	}
	else
	{
		POIDeck = BuildPOIDeck();
	}

	POIState = DrawFromPOIDeck(POIDeck);

	if (POIState != none)
	{
		POIState = XComGameState_PointOfInterest(NewGameState.ModifyStateObject(class'XComGameState_PointOfInterest', POIState.ObjectID));
		
		ActivatePOI(NewGameState, POIState.GetReference());

		// If a staff POI was activated normally (not forced from the staff POI timer), then flag ResHQ
		if (!bStaffPOISpawnedFromTimer && POIState.GetMyTemplate().bStaffPOI)
		{
			ResHQ.bStaffPOISpawnedDuringTimer = true;
		}

		if (bSpawnImmediately)
		{
			POIState.Spawn(NewGameState);

			if (!ResHQ.bFirstPOISpawned)
			{
				ResHQ.bFirstPOISpawned = true;
			}
		}
	}

	return POIState.GetReference();
}

//---------------------------------------------------------------------------------------
function array<XComGameState_PointOfInterest> BuildPOIDeck(optional bool bOnlyStaffPOIs = false)
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState, ActivePOIState;
	local array<XComGameState_PointOfInterest> POIDeck;
	local int idx, Weight;
	local bool bValid;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_PointOfInterest', POIState)
	{
		bValid = true;

		if (bOnlyStaffPOIs && !POIState.GetMyTemplate().bStaffPOI)
		{
			bValid = false;
		}

		for (idx = 0; idx < ActivePOIs.Length; idx++)
		{
			ActivePOIState = XComGameState_PointOfInterest(History.GetGameStateForObjectID(ActivePOIs[idx].ObjectID));

			if (ActivePOIState.ObjectID == POIState.ObjectID)
			{
				bValid = false;
			}
		}

		if (!POIState.CanAppear())
		{
			bValid = false;
		}

		if (bValid)
		{
			Weight = POIState.Weight;
			if (POIState.IsNeeded())
			{
				// Apply a weight modifier if the POI is needed by the player
				Weight *= `ScaleStrategyArrayFloat(NeededPOIWeightModifier);
			}

			for (idx = 0; idx < Weight; idx++)
			{
				POIDeck.AddItem(POIState);
			}
		}
	}

	return POIDeck;
}

//---------------------------------------------------------------------------------------
function XComGameState_PointOfInterest DrawFromPOIDeck(out array<XComGameState_PointOfInterest> POIEventDeck)
{
	local XComGameState_PointOfInterest POIEventState;

	if (POIEventDeck.Length == 0)
	{
		return none;
	}

	// Choose a POI randomly from the deck
	POIEventState = POIEventDeck[`SYNC_RAND_STATIC(POIEventDeck.Length)];

	return POIEventState;
}

//---------------------------------------------------------------------------------------
static function ActivatePOI(XComGameState NewGameState, StateObjectReference POIRef)
{
	local XComGameState_HeadquartersResistance ResHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		break;
	}

	if (ResHQ == none)
	{
		ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
	}

	// Add the POI to the activated list
	ResHQ.ActivePOIs.AddItem(POIRef);
}

//---------------------------------------------------------------------------------------
static function DeactivatePOI(XComGameState NewGameState, StateObjectReference POIRef)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local int idx;
	
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		break;
	}

	if (ResHQ == none)
	{
		ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
	}

	// Check Active POIs for the need to deactivate
	for (idx = 0; idx < ResHQ.ActivePOIs.Length; idx++)
	{
		if (ResHQ.ActivePOIs[idx].ObjectID == POIRef.ObjectID)
		{
			ResHQ.ActivePOIs.Remove(idx, 1);
			break;
		}
	}
}

//#############################################################################################
//----------------   DIFFICULTY HELPERS   -----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetStartingNumRecruits()
{
	return `ScaleStrategyArrayInt(default.StartingNumRecruits);
}

//---------------------------------------------------------------------------------------
function int GetRefillNumRecruits()
{
	return `ScaleStrategyArrayInt(default.RefillNumRecruits);
}

//---------------------------------------------------------------------------------------
function int GetBaseGoodsCost()
{
	return `ScaleStrategyArrayInt(default.BaseGoodsCost);
}

//---------------------------------------------------------------------------------------
function int GetGoodsCostVariance()
{
	return `ScaleStrategyArrayInt(default.GoodsCostVariance);
}

//---------------------------------------------------------------------------------------
function int GetGoodsCostIncrease()
{
	return `ScaleStrategyArrayInt(default.GoodsCostIncrease);
}

//#############################################################################################
//----------------   FACTIONS   ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function SetUpFactions(XComGameState StartState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> AllFactions;
	local X2ResistanceFactionTemplate Faction;
	local XComGameState_CampaignSettings CampaignSettings;
	local int RandIndex;
	//issue #82 variables - used for filtering out faction templates
	local int i;
	local array<name> ExcludedFactions;
	local X2StrategyElementTemplate StratTemplate;
	//end issue #82
	// Grab all the faction templates
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	//start issue #82: filter out factions

	ExcludedFactions = class'CHHelpers'.default.EXCLUDED_FACTIONS;
	AllFactions = StratMgr.GetAllTemplatesOfClass(class'X2ResistanceFactionTemplate');
	
	for(i = 0; i < AllFactions.Length; i++)
	{
		if(ExcludedFactions.Find(AllFactions[i].DataName) != INDEX_NONE)
		{
			StratTemplate = StratMgr.FindStrategyElementTemplate(AllFactions[i].DataName); //get the strat template
			AllFactions.Remove(AllFactions.Find(StratTemplate), 1); //remove the match in the array
			i--; //go back one so we make sure we check every faction
		}
	}
	//end issue #82
	
	// When playing XPack Narrative, the Reapers as the first faction you meet from Lost and Abandoned
	CampaignSettings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	if (CampaignSettings.bXPackNarrativeEnabled)
	{
		Faction = X2ResistanceFactionTemplate(StratMgr.FindStrategyElementTemplate('Faction_Reapers'));
		InitializeFaction(StartState, Faction);
		AllFactions.Remove(AllFactions.Find(Faction), 1);

		// Ensure the Skirmishers are the second faction you meet after L&A
		Faction = X2ResistanceFactionTemplate(StratMgr.FindStrategyElementTemplate('Faction_Skirmishers'));
		InitializeFaction(StartState, Faction);
		AllFactions.Remove(AllFactions.Find(Faction), 1);
	}
	else if (`SecondWaveEnabled('ReaperStart'))
	{
		Faction = X2ResistanceFactionTemplate(StratMgr.FindStrategyElementTemplate('Faction_Reapers'));
		InitializeFaction(StartState, Faction);
		AllFactions.Remove(AllFactions.Find(Faction), 1);
	}
	else if(`SecondWaveEnabled('SkirmisherStart'))
	{
		Faction = X2ResistanceFactionTemplate(StratMgr.FindStrategyElementTemplate('Faction_Skirmishers'));
		InitializeFaction(StartState, Faction);
		AllFactions.Remove(AllFactions.Find(Faction), 1);
	}
	else if (`SecondWaveEnabled('TemplarStart'))
	{
		Faction = X2ResistanceFactionTemplate(StratMgr.FindStrategyElementTemplate('Faction_Templars'));
		InitializeFaction(StartState, Faction);
		AllFactions.Remove(AllFactions.Find(Faction), 1);
	}

	// Create the factions
	while(AllFactions.Length > 0)
	{
		RandIndex = `SYNC_RAND(AllFactions.Length);
		Faction = X2ResistanceFactionTemplate(AllFactions[RandIndex]);
		InitializeFaction(StartState, Faction);

		AllFactions.Remove(RandIndex, 1);
	}
}

//---------------------------------------------------------------------------------------
private function InitializeFaction(XComGameState StartState, X2ResistanceFactionTemplate FactionTemplate)
{
	local XComGameState_ResistanceFaction FactionState;

	FactionState = FactionTemplate.CreateInstanceFromTemplate(StartState);
	Factions.AddItem(FactionState.GetReference());

	// Use the champion template to generate a faction name
	FactionState.FactionName = FactionTemplate.GenerateFactionName();
	FactionState.FactionIconData = FactionTemplate.GenerateFactionIcon();
}

//---------------------------------------------------------------------------------------
function array<XComGameState_ResistanceFaction> GetAllFactions()
{
	local XComGameStateHistory History;
	local array<XComGameState_ResistanceFaction> AllFactions;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Factions.Length; idx++)
	{
		AllFactions.AddItem(XComGameState_ResistanceFaction(History.GetGameStateForObjectID(Factions[idx].ObjectID)));
	}

	return AllFactions;
}

//---------------------------------------------------------------------------------------
function XComGameState_ResistanceFaction GetFactionByTemplateName(name TemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Factions.Length; idx++)
	{
		FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(Factions[idx].ObjectID));
		if (FactionState.GetMyTemplateName() == TemplateName)
		{
			return FactionState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
static function bool HaveMetAnyFactions()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction FactionState;
	local array<XComGameState_ResistanceFaction> AllFactions;
	
	History = `XCOMHISTORY;
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	
	AllFactions = ResHQ.GetAllFactions();

	foreach AllFactions(FactionState)
	{
		if (FactionState.bMetXCom)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function SetFactionHomeRegions(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_ResistanceFaction> AllFactions;
	local array<StateObjectReference> AllRegions;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_WorldRegion RegionState;
	local StateObjectReference RegionRef, HomeRef;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_Continent ContinentState;
	local int idx;

	History = `XCOMHISTORY;
	AllFactions = GetAllFactions();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// Grab all regions for fallback cases
	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		AllRegions.AddItem(RegionState.GetReference());
	}

	// Grab StartRegion
	HomeRef = XComHQ.StartingRegion;

	// Assign Faction Home Regions
	for(idx = 0; idx < AllFactions.Length; idx++)
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', AllFactions[idx].ObjectID));

		if(idx == 0)
		{
			// First Faction is in XCom Starting Region
			RegionRef = HomeRef;
			FactionState.bFirstFaction = true; // Save that this is the first Faction met by the player - used for Covert Action reqs
		}
		else
		{
			RegionRef.ObjectID = 0;

			if(idx == (AllFactions.Length - 1))
			{
				FactionState.bFarthestFaction = true; // Save that this is the last HQ created - used for Covert Action reqs
			}

			ChosenState = XComGameState_AdventChosen(NewGameState.GetGameStateForObjectID(FactionState.RivalChosen.ObjectID));

			if(ChosenState != none)
			{
				if(ChosenState.ControlledContinents.Length > 0)
				{
					ContinentState = XComGameState_Continent(History.GetGameStateForObjectID(ChosenState.ControlledContinents[`SYNC_RAND(ChosenState.ControlledContinents.Length)].ObjectID));
					RegionRef = ContinentState.Regions[`SYNC_RAND(ContinentState.Regions.Length)];
				}
			}
		}

		// fallback to random region	
		if(RegionRef.ObjectID == 0)
		{
			RegionRef = AllRegions[`SYNC_RAND(AllRegions.Length)];
		}

		FactionState.HomeRegion = RegionRef;
		FactionState.Region = FactionState.HomeRegion;
		FactionState.Continent = FactionState.GetWorldRegion().Continent;
		FactionState.InitializeHQ(NewGameState, idx);
	}
}

//#############################################################################################
//----------------   MORALE   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetGlobalMorale()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local int Morale;

	History = `XCOMHISTORY;
	Morale = 0;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		Morale += RegionState.GetMorale();
	}

	return Morale;
}

//---------------------------------------------------------------------------------------
function int GetGlobalFear()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local int Fear;

	History = `XCOMHISTORY;
	Fear = 0;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		Fear += RegionState.GetFear();
	}

	return Fear;
}

//---------------------------------------------------------------------------------------
function int GetMaxGlobalMorale()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local int MaxMorale;

	History = `XCOMHISTORY;
	MaxMorale = 0;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		MaxMorale += RegionState.GetMaxMorale();
	}

	return MaxMorale;
}

//---------------------------------------------------------------------------------------
function int GetMinGlobalMorale()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local int MinMorale;

	History = `XCOMHISTORY;
	MinMorale = 0;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		MinMorale += RegionState.GetMinMorale();
	}

	return MinMorale;
}

//#############################################################################################
//----------------   COVERT ACTIONS   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function FindRookieCovertActions()
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> Actions;
	local X2CovertActionTemplate ActionTemplate;
	local X2StaffSlotTemplate SlotTemplate;
	local CovertActionSlot ActionSlot;
	local bool bRankRequired;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	Actions = StratMgr.GetAllTemplatesOfClass(class'X2CovertActionTemplate');
	RookieCovertActions.Length = 0;

	for (idx = 0; idx < Actions.Length; idx++)
	{
		ActionTemplate = X2CovertActionTemplate(Actions[idx]);

		if (
			!ActionTemplate.bGoldenPath
			&& ActionTemplate.RequiredFactionInfluence == eFactionInfluence_Minimal
			/// HL-Docs: ref:CanNeverBeRookieCovertAction 
			&& !ActionTemplate.bCanNeverBeRookie // Issue #695
		)
		{
			bRankRequired = false;
			foreach ActionTemplate.Slots(ActionSlot)
			{
				SlotTemplate = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate(ActionSlot.StaffSlot));
				if (!ActionSlot.bReduceRisk && (ActionSlot.iMinRank > 0 || (SlotTemplate != None && !SlotTemplate.bSoldierSlot)))
				{
					// If any of the slots have a rank requirement, it is disqualified
					bRankRequired = true;
					break;
				}
			}

			if (!bRankRequired)
			{
				RookieCovertActions.AddItem(ActionTemplate.DataName);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function bool IsRookieCovertActionAvailable(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState, NewActionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		// Only check the History status of the Action if it was not added to the NewGameState. Otherwise it will be handled in the NewGameState loop below.
		NewActionState = XComGameState_CovertAction(NewGameState.GetGameStateForObjectID(ActionState.ObjectID));
		if (NewActionState == none)
		{
			if (ActionState.bAvailable && !ActionState.bStarted && RookieCovertActions.Find(ActionState.GetMyTemplateName()) != INDEX_NONE)
			{
				return true;
			}
		}
	}

	foreach NewGameState.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		if (!ActionState.bRemoved && !ActionState.bStarted && RookieCovertActions.Find(ActionState.GetMyTemplateName()) != INDEX_NONE)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function CreateRookieCovertAction(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local X2StrategyElementTemplateManager StratMgr;
	local XComGameState_ResistanceFaction FactionState;
	local array<XComGameState_ResistanceFaction> MetFactions;
	local array<X2CovertActionTemplate> PossibleRookieActions;
	local X2CovertActionTemplate RookieActionTemplate;
	local StateObjectReference FactionRef;
	local name RookieActionName;
	local bool bRookieActionCreated;
	local int iRand;

	History = `XCOMHISTORY;

	foreach Factions(FactionRef)
	{
		FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(FactionRef.ObjectID));
		if (FactionState.bMetXCom)
		{
			// Save which Factions have met XCOM
			MetFactions.AddItem(FactionState);
		}
	}

	if (MetFactions.Length == 0)
	{
		// If no met Faction states were found in the History, check the NewGameState
		foreach NewGameState.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
		{
			if (FactionState.bMetXCom)
			{
				MetFactions.AddItem(FactionState);
			}
		}
	}

	if (MetFactions.Length > 0)
	{
		// Choose a random Met Faction to generate a random Rookie Action
		FactionState = MetFactions[`SYNC_RAND(MetFactions.Length)];
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionState.ObjectID));
		
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

		// Find all of the potentially available rookie actions
		foreach RookieCovertActions(RookieActionName)
		{
			RookieActionTemplate = X2CovertActionTemplate(StratMgr.FindStrategyElementTemplate(RookieActionName));
			if (RookieActionTemplate != none && RookieActionTemplate.AreActionRewardsAvailable(FactionState, NewGameState))
			{
				PossibleRookieActions.AddItem(RookieActionTemplate);
			}
		}

		// Then randomly choose an available Rookie Covert Action for the selected Faction
		while (PossibleRookieActions.Length > 0 && !bRookieActionCreated)
		{
			iRand = `SYNC_RAND(PossibleRookieActions.Length);
			RookieActionTemplate = PossibleRookieActions[iRand];

			if(RookieActionTemplate != none)
			{
				FactionState.AddCovertAction(NewGameState, RookieActionTemplate, CovertActionExclusionList);
				bRookieActionCreated = true;
			}

			PossibleRookieActions.Remove(iRand, 1); // Remove the template from the available actions list
		}

		if (!bRookieActionCreated)
		{
			`Redscreen("@jweinhoffer Tried to create a Rookie Covert Action, but no Rookie Actions were available.");
		}
	}
	else
	{
		`Redscreen("@jweinhoffer Tried to create a Rookie Covert Action, but no met Factions were found.");
	}
}

//---------------------------------------------------------------------------------------
static function bool IsCovertActionInProgress()
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		if (ActionState.bStarted)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
static function XComGameState_CovertAction GetCurrentCovertAction()
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		if (ActionState.bStarted)
		{
			return ActionState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool CanCovertActionsBeAmbushed()
{
	if (bPreventCovertActionAmbush || bCovertActionSafeguardActive)
	{
		return false;
	}

	return true;
}

//---------------------------------------------------------------------------------------
function SaveNextCovertActionAmbushTime()
{
	NextCovertActionAmbushTime = `STRATEGYRULES.GameTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(NextCovertActionAmbushTime, default.CovertActionAmbushSafeguardDays);
	bCovertActionSafeguardActive = true;
}

//---------------------------------------------------------------------------------------
function UpdateCovertActionNegatedRisks(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		if (!ActionState.bStarted)
		{
			ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));
			ActionState.UpdateNegatedRisks(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
function AddCovertActionModifier(XComGameState NewGameState, float Modifier)
{
	CovertActionDurationModifier *= Modifier;
	CovertActionDurationModifier = FClamp(CovertActionDurationModifier, 0.0, 1.0);
	UpdateCovertActionTimes(NewGameState, Modifier);
}

//---------------------------------------------------------------------------------------
function RemoveCovertActionModifier(XComGameState NewGameState, float Modifier)
{
	CovertActionDurationModifier /= Modifier;
	CovertActionDurationModifier = FClamp(CovertActionDurationModifier, 0.0, 1.0);
	UpdateCovertActionTimes(NewGameState, 1.0 / Modifier);
}

//---------------------------------------------------------------------------------------
// Update all covert actions times to match the current duration modifier rate
private function UpdateCovertActionTimes(XComGameState NewGameState, float Modifier)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));
		ActionState.ModifyRemainingTime(Modifier);
	}
}

//---------------------------------------------------------------------------------------
function ActivateCovertActionDarkEventRisk(XComGameState NewGameState, name DarkEventRiskName)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;

	if (CovertActionDarkEventRisks.Find(DarkEventRiskName) == INDEX_NONE)
	{
		CovertActionDarkEventRisks.AddItem(DarkEventRiskName);
	}

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		if (!ActionState.bStarted)
		{
			ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));
			ActionState.EnableDarkEventRisk(DarkEventRiskName);
		}
	}
}

//---------------------------------------------------------------------------------------
function DeactivateCovertActionDarkEventRisk(XComGameState NewGameState, name DarkEventRiskName)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;
	local int RiskIndex;

	RiskIndex = CovertActionDarkEventRisks.Find(DarkEventRiskName);
	if(RiskIndex != INDEX_NONE)
	{
		CovertActionDarkEventRisks.Remove(RiskIndex, 1);
	}

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		if (!ActionState.bStarted)
		{
			ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));
			ActionState.DisableDarkEventRisk(DarkEventRiskName);
		}
	}
}

//---------------------------------------------------------------------------------------
function FactionsOnEndOfMonth(XComGameState NewGameState)
{
	local XComGameState_ResistanceFaction FactionState;
	local StateObjectReference FactionRef;

	CovertActionExclusionList.Length = 0; // Clear the exclusion list
	foreach Factions(FactionRef)
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionRef.ObjectID));
		FactionState.OnEndOfMonth(NewGameState, CovertActionExclusionList);
	}

	// Ensure that there is always at least one Rookie action available for the player
	if (!IsRookieCovertActionAvailable(NewGameState))
	{
		CreateRookieCovertAction(NewGameState);
	}
}

//#############################################################################################
//----------------   MONTHLY CARD GAME   ------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function OnCardScreenConfirm(XComGameState NewGameState)
{
	DeactivateRemovedCards(NewGameState);
	PlayAllNewCards(NewGameState);
	ClearNewCardFlag(NewGameState);
}

//---------------------------------------------------------------------------------------
function PlayAllNewCards(XComGameState NewGameState)
{
	local array<XComGameState_ResistanceFaction> AllFactions, NewCardFactions;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_StrategyCard CardState;
	local array<StateObjectReference> WildCardRefs;
	local StateObjectReference WildCardRef, FactionRef;

	// Play Faction Cards
	foreach Factions(FactionRef)
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionRef.ObjectID));
		if (FactionState.PlayAllNewCards(NewGameState, OldWildCardSlots))
		{
			NewCardFactions.AddItem(FactionState); // Store which factions have played new cards
		}
		AllFactions.AddItem(FactionState);
	}

	// Find Wild Cards that are new
	WildCardRefs = WildCardSlots;

	// Remove Old Wild Cards
	foreach OldWildCardSlots(WildCardRef)
	{
		WildCardRefs.RemoveItem(WildCardRef);
	}

	// Player could have moved faction card to wild card slot so remove those as well
	foreach AllFactions(FactionState)
	{
		foreach FactionState.OldCardSlots(WildCardRef)
		{
			WildCardRefs.RemoveItem(WildCardRef);
		}
	}

	// Play new Wild Cards
	foreach WildCardRefs(WildCardRef)
	{
		if(WildCardRef.ObjectID != 0)
		{
			CardState = XComGameState_StrategyCard(NewGameState.ModifyStateObject(class'XComGameState_StrategyCard', WildCardRef.ObjectID));
			CardState.ActivateCard(NewGameState);
			
			FactionState = CardState.GetAssociatedFaction();
			if (FactionState != none)
			{
				NewCardFactions.AddItem(CardState.GetAssociatedFaction());
			}
		}
	}

	// Trigger the policy confirmation event for one of the factions who played a new card if the Covert Action screen won't be displayed next
	if (NewCardFactions.Length > 0 && IsCovertActionInProgress())
	{
		FactionState = NewCardFactions[`SYNC_RAND(NewCardFactions.Length)];
		`XEVENTMGR.TriggerEvent(FactionState.GetConfirmPoliciesEvent(), , , NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function DeactivateRemovedCards(XComGameState NewGameState)
{
	local array<XComGameState_ResistanceFaction> AllFactions;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_StrategyCard CardState;
	local array<StateObjectReference> WildCardRefs;
	local StateObjectReference WildCardRef, FactionRef;

	// Deactivate Faction Cards
	foreach Factions(FactionRef)
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionRef.ObjectID));
		FactionState.DeactivateRemovedCards(NewGameState, WildCardSlots);
		AllFactions.AddItem(FactionState);
	}

	// Find Wild Cards that are old
	WildCardRefs = OldWildCardSlots;

	// Remove New Wild Cards
	foreach WildCardSlots(WildCardRef)
	{
		WildCardRefs.RemoveItem(WildCardRef);
	}

	// Player could have moved wild card to faction card slot so remove those as well
	foreach AllFactions(FactionState)
	{
		foreach FactionState.CardSlots(WildCardRef)
		{
			WildCardRefs.RemoveItem(WildCardRef);
		}
	}

	// Deactivate old Wild Cards
	foreach WildCardRefs(WildCardRef)
	{
		if(WildCardRef.ObjectID != 0)
		{
			CardState = XComGameState_StrategyCard(NewGameState.ModifyStateObject(class'XComGameState_StrategyCard', WildCardRef.ObjectID));
			CardState.DeActivateCard(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
function ClearNewCardFlag(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_StrategyCard CardState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_StrategyCard', CardState)
	{
		if (CardState.bNewCard)
		{
			CardState = XComGameState_StrategyCard(NewGameState.ModifyStateObject(class'XComGameState_StrategyCard', CardState.ObjectID));
			CardState.bNewCard = false;
		}
	}
}

//---------------------------------------------------------------------------------------
// Call before making changes on the card screen
function StoreOldCards(XComGameState NewGameState)
{
	local XComGameState_ResistanceFaction FactionState;
	local StateObjectReference FactionRef;

	// Store Wild Cards
	OldWildCardSlots = WildCardSlots;

	// Store cards in faction slots
	foreach Factions(FactionRef)
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionRef.ObjectID));
		FactionState.StoreOldCards();
	}
}

//---------------------------------------------------------------------------------------
function AddWildCardSlot()
{
	local StateObjectReference EmptyRef;

	WildCardSlots.AddItem(EmptyRef);
}

//---------------------------------------------------------------------------------------
// How many wild cards can be played per month
function int GetNumCardSlots()
{
	return WildCardSlots.Length;
}

//---------------------------------------------------------------------------------------
function PlaceCardInSlot(StateObjectReference CardRef, int SlotIndex)
{
	if(SlotIndex < 0 || SlotIndex >= WildCardSlots.Length)
	{
		return;
	}

	RemoveCardFromSlot(SlotIndex);
	WildCardSlots[SlotIndex] = CardRef;
}

//---------------------------------------------------------------------------------------
function RemoveCardFromSlot(int SlotIndex)
{
	local StateObjectReference EmptyRef;

	if(SlotIndex < 0 || SlotIndex >= WildCardSlots.Length)
	{
		return;
	}

	WildCardSlots[SlotIndex] = EmptyRef;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_StrategyCard> GetAllPlayableCards()
{
	local XComGameStateHistory History;
	local array<XComGameState_StrategyCard> AllPlayableCards, FactionPlayableCards;
	local array<StateObjectReference> AllPlayableCardRefs;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_StrategyCard CardState;
	local StateObjectReference FactionRef;

	History = `XCOMHISTORY;
	AllPlayableCards.Length = 0;
	AllPlayableCardRefs.Length = 0;

	foreach Factions(FactionRef)
	{
		FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(FactionRef.ObjectID));
		if (FactionState.bSeenFactionHQReveal)
		{
			FactionPlayableCards = FactionState.GetAllPlayableCards();

			foreach FactionPlayableCards(CardState)
			{
				if (AllPlayableCardRefs.Find('ObjectID', CardState.ObjectID) == INDEX_NONE)
				{
					AllPlayableCards.AddItem(CardState);
					AllPlayableCardRefs.AddItem(CardState.GetReference());
				}
			}
		}
	}

	return AllPlayableCards;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetHandCards()
{
	local XComGameStateHistory History;
	local array<StateObjectReference> HandCards, FactionHandCards;
	local XComGameState_ResistanceFaction FactionState;
	local StateObjectReference FactionRef, CardRef;

	History = `XCOMHISTORY;
	HandCards.Length = 0;

	foreach Factions(FactionRef)
	{
		FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(FactionRef.ObjectID));
		if (FactionState.bSeenFactionHQReveal)
		{
			FactionHandCards = FactionState.GetHandCards();

			foreach FactionHandCards(CardRef)
			{
				if (HandCards.Find('ObjectID', CardRef.ObjectID) == INDEX_NONE)
				{
					HandCards.AddItem(CardRef);
				}
			}
		}
	}

	return HandCards;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetWildCardSlots()
{
	return WildCardSlots;
}

//---------------------------------------------------------------------------------------
function bool HasEmptyWildCardSlot()
{
	local StateObjectReference CardRef;

	foreach WildCardSlots(CardRef)
	{
		if (CardRef.ObjectID == 0)
		{
			return true;
		}
	}

	return false;
}

function array<StateObjectReference> GetAllPlayedCards(optional bool bIncludeContintentBonuses)
{
	local XComGameStateHistory History;
	local array<StateObjectReference> PlayedCards;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_Continent ContinentState;
	local StateObjectReference FactionRef, CardRef;

	History = `XCOMHISTORY;

	PlayedCards = WildCardSlots;

	foreach Factions(FactionRef)
	{
		FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(FactionRef.ObjectID));

		foreach FactionState.CardSlots( CardRef )
		{
			PlayedCards.AddItem( CardRef );
		}
	}
	
	if (bIncludeContintentBonuses)
	{
		// Check for any active continent bonuses whose associated cards provide tactical effects
		foreach History.IterateByClassType(class'XComGameState_Continent', ContinentState)
		{
			if (ContinentState.bContinentBonusActive)
			{
				PlayedCards.AddItem(ContinentState.ContinentBonusCard);
			}
		}
	}

	return PlayedCards;
}

//#############################################################################################
//----------------   RESISTANCE ORDERS   ------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function float GetMissionResourceRewardScalar(XComGameState_Reward RewardState)
{
	if(MissionResourceRewardScalar <= 0 || !RewardState.IsResourceReward())
	{
		return 1.0f;
	}

	return MissionResourceRewardScalar;
}

//---------------------------------------------------------------------------------------
function float GetWillRecoveryRateScalar()
{
	if(WillRecoveryRateScalar <= 0)
	{
		return 1.0f;
	}

	return WillRecoveryRateScalar;
}

//---------------------------------------------------------------------------------------
function float GetFacilityBuildScalar()
{
	if(FacilityBuildScalar <= 0)
	{
		return 1.0f;
	}

	return FacilityBuildScalar;
}

//---------------------------------------------------------------------------------------
function float GetExcavateScalar()
{
	if(ExcavateScalar <= 0)
	{
		return 1.0f;
	}

	return ExcavateScalar;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	CovertActionDurationModifier=1.0
}
