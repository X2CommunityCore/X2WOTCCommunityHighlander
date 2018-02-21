//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultRewards.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultRewards extends X2StrategyElement
	dependson(X2RewardTemplate)
	config(GameData);

var config int							SuppliesRangePercent;
var config float						SuppliesScalarFromGoods;
var config array<int>                   IntelBaseReward;
var config array<int>                   IntelInterval;
var config array<int>                   IntelRewardIncrease;
var config int							IntelRangePercent;
var config array<int>					AlloysBaseReward;
var config array<int>					AlloysInterval;
var config array<int>					AlloysRewardIncrease;
var config int							AlloysRangePercent;
var config array<int>					EleriumBaseReward;
var config array<int>					EleriumInterval;
var config array<int>					EleriumRewardIncrease;
var config int							EleriumRangePercent;

var config array<int>					ScienceScoreBaseReward;
var config array<int>					EngineeringScoreBaseReward;
var config array<int>					ResCommsBaseReward;
var config array<int>					PowerBaseReward;

var config array<float>					TechRushReductionScalar;

var config int							MissionMinDuration;
var config int							MissionMaxDuration;

var config name							HeavyWeaponRewardDeck;
var config name							AdvHeavyWeaponRewardDeck;
var config name							AmmoRewardDeck;
var config name							GrenadeRewardDeck;

var config array<int>					IncreaseIncomeBaseReward; // If the Increase Income reward given, increase monthly supply drop by this amount
var config int							IncreaseIncomeRangePercent;
var config array<int>					ReducedContactBaseModifier;	// If the Reduced Contact reward is active, this modifier will be applied to the contact cost

var config array<int>					CrewRewardForceLevelGates; // Once force level is passed, rank up crew reward
var config array<int>					SoldierRewardForceLevelGates; // Once force level is passed, rank up soldier reward

var config array<int>					ChanceRewardStaffWhenHeavyPercent; // The chance a player can still receive a staff reward even if they are heavy
var config array<int>					ChanceForceRewardWhenLightPercent; // The chance a player will automatically receive a reward option they badly need if they are light

var localized string					DoctorPrefixText;
var localized string					SkillLevelText;
var localized string					TechRushText;
var localized string					RewardReducedContact;
var localized string					IncomeIncreasedLabel;

var localized array<string>				ScientistBlackMarketText;
var localized array<string>				EngineerBlackMarketText;
var localized array<string>				SoldierBlackMarketText;
var localized array<string>				SuppliesBlackMarketText;
var localized array<string>				GenericItemBlackMarketText;
var localized array<string>				TechRushBlackMarketText;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Rewards;

	// Resource Rewards
	Rewards.AddItem(CreateSuppliesRewardTemplate());
	Rewards.AddItem(CreateIntelRewardTemplate());
	Rewards.AddItem(CreateAlloysRewardTemplate());
	Rewards.AddItem(CreateEleriumRewardTemplate());

	// Personnel Rewards
	Rewards.AddItem(CreateScientistRewardTemplate());
	Rewards.AddItem(CreateEngineerRewardTemplate());
	Rewards.AddItem(CreateSoldierRewardTemplate());
	Rewards.AddItem(CreateCapturedSoldierRewardTemplate());
	Rewards.AddItem(CreateRookieRewardTemplate());

	// Avenger Rewards
	Rewards.AddItem(CreateIncreaseScienceScoreRewardTemplate());
	Rewards.AddItem(CreateIncreaseEngineeringScoreRewardTemplate());
	Rewards.AddItem(CreateIncreaseAvengerPowerRewardTemplate());
	Rewards.AddItem(CreateIncreaseAvengerResCommsRewardTemplate());

	// Mission Rewards
	Rewards.AddItem(CreateGuerillaOpMissionRewardTemplate());
	Rewards.AddItem(CreateSupplyRaidMissionRewardTemplate());

	// Item Rewards
	Rewards.AddItem(CreateItemRewardTemplate());
	Rewards.AddItem(CreateHeavyWeaponRewardTemplate());
	Rewards.AddItem(CreateAmmoRewardTemplate());
	Rewards.AddItem(CreateGrenadeRewardTemplate());
	Rewards.AddItem(CreateFacilityLeadRewardTemplate());

	// Loot Table Rewards
	Rewards.AddItem(CreateLootTableRewardTemplate());
	
	// Region Rewards
	Rewards.AddItem(CreateIncreaseIncomeRewardTemplate());
	Rewards.AddItem(CreateReducedContactRewardTemplate());

	// Doom Reduction Rewards
	Rewards.AddItem(CreateDoomReductionRewardTemplate());
	
	// Unlock Rewards
	Rewards.AddItem(CreateUnlockResearchRewardTemplate());
	Rewards.AddItem(CreateUnlockItemRewardTemplate());

	// Create Haven Op Reward
	Rewards.AddItem(CreateHavenOpRewardTemplate());

	// Tech Rush Reward
	Rewards.AddItem(CreateTechRushRewardTemplate());

	// Resistance HQ Toggle Reward
	Rewards.AddItem(CreateResistanceModeRewardTemplate());

	// No Reward
	Rewards.AddItem(CreateNoRewardTemplate());

	return Rewards;
}

// #######################################################################################
// -------------------- RESOURCE REWARDS -------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateSuppliesRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Supplies');
	Template.rewardObjectTemplateName = 'Supplies';
	Template.RewardImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Supplies";
	Template.bResourceReward = true;

	Template.GenerateRewardFn = GenerateResourceReward;
	Template.SetRewardFn = SetResourceReward;
	Template.GiveRewardFn = GiveResourceReward;
	Template.GetRewardStringFn = GetResourceRewardString;
	Template.GetRewardPreviewStringFn = GetResourceRewardString;
	Template.GetRewardImageFn = GetResourceRewardImage;
	Template.GetBlackMarketStringFn = GetSuppliesBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	
	return Template;
}

static function string GetSuppliesBlackMarketString(XComGameState_Reward RewardState)
{
	return default.SuppliesBlackMarketText[`SYNC_RAND_STATIC(default.SuppliesBlackMarketText.Length)];
}

static function int GetSuppliesReward()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local int SupplyAmount, iAdjPercent, iAdjAmount;
	local float fAdjust;

	History = `XCOMHISTORY;
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	SupplyAmount = ResHQ.GetBaseGoodsCost();
	SupplyAmount += ((ResHQ.NumMonths - 1) * ResHQ.GetGoodsCostIncrease());
	SupplyAmount = Round(float(SupplyAmount) * default.SuppliesScalarFromGoods);
	iAdjPercent = `SYNC_RAND_STATIC(default.SuppliesRangePercent + 1);

	if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
	{
		iAdjPercent = -iAdjPercent;
	}

	fAdjust = (float(iAdjPercent) / 100.0f);
	iAdjAmount = Round(fAdjust*float(SupplyAmount));

	SupplyAmount += iAdjAmount;

	return SupplyAmount;
}

static function X2DataTemplate CreateIntelRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Intel');
	Template.rewardObjectTemplateName = 'Intel';
	Template.RewardImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Intel";
	Template.bResourceReward = true;

	Template.GenerateRewardFn = GenerateResourceReward;
	Template.SetRewardFn = SetResourceReward;
	Template.GiveRewardFn = GiveResourceReward;
	Template.GetRewardStringFn = GetResourceRewardString;
	Template.GetRewardPreviewStringFn = GetResourceRewardString;
	Template.GetRewardImageFn = GetResourceRewardImage;
	Template.GetRewardIconFn = GetGenericRewardIcon;

	return Template;
}

static function X2DataTemplate CreateAlloysRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Alloys');
	Template.rewardObjectTemplateName = 'AlienAlloy';
	Template.RewardImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Alien_Alloy";
	Template.bResourceReward = true;

	Template.GenerateRewardFn = GenerateResourceReward;
	Template.SetRewardFn = SetResourceReward;
	Template.GiveRewardFn = GiveResourceReward;
	Template.GetRewardStringFn = GetResourceRewardString;
	Template.GetRewardPreviewStringFn = GetResourceRewardString;
	Template.GetRewardImageFn = GetResourceRewardImage;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	
	return Template;
}

static function X2DataTemplate CreateEleriumRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Elerium');
	Template.rewardObjectTemplateName = 'EleriumDust';
	Template.RewardImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Elerium_Crystals";
	Template.bResourceReward = true;

	Template.GenerateRewardFn = GenerateResourceReward;
	Template.SetRewardFn = SetResourceReward;
	Template.GiveRewardFn = GiveResourceReward;
	Template.GetRewardStringFn = GetResourceRewardString;
	Template.GetRewardPreviewStringFn = GetResourceRewardString;
	Template.GetRewardImageFn = GetResourceRewardImage;
	Template.GetRewardIconFn = GetGenericRewardIcon;

	return Template;
}

static function GenerateResourceReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	switch(RewardState.GetMyTemplate().rewardObjectTemplateName)
	{
	case 'Supplies':
		RewardState.Quantity = GetSuppliesReward();
		break;
	case 'Intel':
		RewardState.Quantity = GetIntelReward();
		break;
	case 'AlienAlloy':
		RewardState.Quantity = GetResourceReward(GetAlloysBaseReward(), GetAlloysRewardIncrease(), GetAlloysInterval(), default.AlloysRangePercent);
		break;
	case 'EleriumDust':
		RewardState.Quantity = GetResourceReward(GetEleriumBaseReward(), GetEleriumRewardIncrease(), GetEleriumInterval(), default.EleriumRangePercent);
		break;
	default:
		RewardState.Quantity = 0;
		break;
	}

	RewardState.Quantity = Round(RewardScalar * float(RewardState.Quantity));
}

static function SetResourceReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.Quantity = Amount;
}

static function GiveResourceReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.AddResource(NewGameState, RewardState.GetMyTemplate().rewardObjectTemplateName, RewardState.Quantity);
}

static function string GetResourceRewardString(XComGameState_Reward RewardState)
{
	return string(RewardState.Quantity) @ RewardState.GetMyTemplate().DisplayName;
}

static function string GetResourceRewardImage(XComGameState_Reward RewardState)
{
	return RewardState.GetMyTemplate().RewardImage;
}

static function int GetResourceReward(int BaseReward, int RewardIncrease, int Interval, int RangePercent)
{
	local int iAdjAmount, iAdjPercent, iResourceReward, iResourceTemp, iIntervalsPassed;
	local float fAdjust;
	local TDateTime StartDateTime, CurrentTime;

	class'X2StrategyGameRulesetDataStructures'.static.SetTime(StartDateTime, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
															  class'X2StrategyGameRulesetDataStructures'.default.START_DAY,
															  class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();

	iIntervalsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(CurrentTime, StartDateTime) / Interval;
	iResourceTemp = BaseReward + (iIntervalsPassed * RewardIncrease);
	iAdjPercent = `SYNC_RAND_STATIC(RangePercent + 1);

	if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
	{
		iAdjPercent = -iAdjPercent;
	}

	fAdjust = (float(iAdjPercent) / 100.0);
	iAdjAmount = Round(fAdjust*float(iResourceTemp));

	iResourceReward = iResourceTemp + iAdjAmount;

	return iResourceReward;
}

static function int GetIntelReward()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int iIntelReward;
	
	iIntelReward = GetResourceReward(GetIntelBaseReward(), GetIntelRewardIncrease(), GetIntelInterval(), default.IntelRangePercent);

	// Check for Spy Ring Continent Bonus
	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	iIntelReward += Round(float(iIntelReward) * (float(ResistanceHQ.IntelRewardPercentIncrease) / 100.0));

	return iIntelReward;
}

// #######################################################################################
// -------------------- PERSONNEL REWARDS ------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateScientistRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Scientist');
	Template.rewardObjectTemplateName = 'Scientist';
	
	Template.IsRewardAvailableFn = IsScientistRewardAvailable;
	Template.IsRewardNeededFn = IsScientistRewardNeeded;
	Template.GenerateRewardFn = GeneratePersonnelReward;
	Template.SetRewardFn = SetPersonnelReward;
	Template.GiveRewardFn = GivePersonnelReward;
	Template.GetRewardStringFn = GetPersonnelRewardString;
	Template.GetRewardImageFn = GetPersonnelRewardImage;
	Template.GetBlackMarketStringFn = GetScientistBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.CleanUpRewardFn = CleanUpUnitReward;
	Template.RewardPopupFn = PersonnelRewardPopup;

	return Template;
}

static function bool IsScientistRewardAvailable(optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime StartDateTime, CurrentTime;
	local int MaxScientists, NumScientists, iMonthsPassed;
	local bool bAllowReward;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	iMonthsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime);

	// Calculate the maximum amount of scientists allowed at this time
	MaxScientists = `ScaleStrategyArrayFloat(XComHQ.StartingScientistMaxCap) + (`ScaleStrategyArrayFloat(XComHQ.ScientistMaxCapIncrease) * iMonthsPassed);
	NumScientists = XComHQ.GetNumberOfScientists() + CountAvailableRewards('Reward_Scientist');

	if (MaxScientists == NumScientists) // If we are exactly at the cap, roll for a chance to still offer the reward
		bAllowReward = class'X2StrategyGameRulesetDataStructures'.static.Roll(`ScaleStrategyArrayInt(default.ChanceRewardStaffWhenHeavyPercent));

	return (bAllowReward || NumScientists < MaxScientists);
}

static function bool IsScientistRewardNeeded()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime StartDateTime, CurrentTime;
	local int MinScientists, NumScientists, iMonthsPassed;
	local bool bForceReward;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;	
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	iMonthsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime);
	
	// Calculate the minimum amount of scientists the player should have at this time
	if (iMonthsPassed > 0)
	{
		MinScientists = `ScaleStrategyArrayFloat(XComHQ.StartingScientistMinCap) + (`ScaleStrategyArrayFloat(XComHQ.ScientistMinCapIncrease) * iMonthsPassed);
		NumScientists = XComHQ.GetNumberOfScientists() + CountAvailableRewards('Reward_Scientist');
		bForceReward = class'X2StrategyGameRulesetDataStructures'.static.Roll(`ScaleStrategyArrayInt(default.ChanceForceRewardWhenLightPercent));
	}

	return (bForceReward && NumScientists < MinScientists);
}

static function string GetScientistBlackMarketString(XComGameState_Reward RewardState)
{
	return default.ScientistBlackMarketText[`SYNC_RAND_STATIC(default.ScientistBlackMarketText.Length)];
}

static function X2DataTemplate CreateEngineerRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Engineer');
	Template.rewardObjectTemplateName = 'Engineer';

	Template.IsRewardAvailableFn = IsEngineerRewardAvailable;
	Template.IsRewardNeededFn = IsEngineerRewardNeeded;
	Template.GenerateRewardFn = GeneratePersonnelReward;
	Template.SetRewardFn = SetPersonnelReward;
	Template.GiveRewardFn = GivePersonnelReward;
	Template.GetRewardStringFn = GetPersonnelRewardString;
	Template.GetRewardImageFn = GetPersonnelRewardImage;
	Template.GetBlackMarketStringFn = GetEngineerBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.CleanUpRewardFn = CleanUpUnitReward;
	Template.RewardPopupFn = PersonnelRewardPopup;

	return Template;
}

static function bool IsEngineerRewardAvailable(optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime StartDateTime, CurrentTime;
	local int MaxEngineers, NumEngineers, iMonthsPassed;
	local bool bAllowReward;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	iMonthsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime);

	// Calculate the maximum amount of engineers allowed at this time
	MaxEngineers = `ScaleStrategyArrayFloat(XComHQ.StartingEngineerMaxCap) + (`ScaleStrategyArrayFloat(XComHQ.EngineerMaxCapIncrease) * iMonthsPassed);
	NumEngineers = XComHQ.GetNumberOfEngineers() + CountAvailableRewards('Reward_Engineer');
	
	if (MaxEngineers == NumEngineers) // If we are exactly at the cap, roll for a chance to still offer the reward
		bAllowReward = class'X2StrategyGameRulesetDataStructures'.static.Roll(`ScaleStrategyArrayInt(default.ChanceRewardStaffWhenHeavyPercent));

	return (bAllowReward || NumEngineers < MaxEngineers);
}

static function bool IsEngineerRewardNeeded()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime StartDateTime, CurrentTime;
	local int MinEngineers, NumEngineers, iMonthsPassed;
	local bool bForceReward;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	iMonthsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime);

	// Calculate the minimum amount of engineers the player should have at this time
	if (iMonthsPassed > 0)
	{
		MinEngineers = `ScaleStrategyArrayFloat(XComHQ.StartingEngineerMinCap) + (`ScaleStrategyArrayFloat(XComHQ.EngineerMinCapIncrease) * iMonthsPassed);
		NumEngineers = XComHQ.GetNumberOfEngineers() + CountAvailableRewards('Reward_Engineer');
		bForceReward = class'X2StrategyGameRulesetDataStructures'.static.Roll(`ScaleStrategyArrayInt(default.ChanceForceRewardWhenLightPercent));
	}

	return (bForceReward && NumEngineers < MinEngineers);
}

static function string GetEngineerBlackMarketString(XComGameState_Reward RewardState)
{
	return default.EngineerBlackMarketText[`SYNC_RAND_STATIC(default.EngineerBlackMarketText.Length)];
}

static function X2DataTemplate CreateSoldierRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Soldier');
	Template.rewardObjectTemplateName = 'Soldier';

	Template.GenerateRewardFn = GeneratePersonnelReward;
	Template.SetRewardFn = SetPersonnelReward;
	Template.GiveRewardFn = GivePersonnelReward;
	Template.GetRewardStringFn = GetPersonnelRewardString;
	Template.GetRewardImageFn = GetPersonnelRewardImage;
	Template.GetBlackMarketStringFn = GetSoldierBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.RewardPopupFn = PersonnelRewardPopup;

	return Template;
}

static function X2DataTemplate CreateRookieRewardTemplate()
{
	local X2RewardTemplate Template;

	// Gives you a rookie instead of a promoted soldier
	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Rookie');
	Template.rewardObjectTemplateName = 'Soldier';

	Template.GenerateRewardFn = GeneratePersonnelReward;
	Template.SetRewardFn = SetPersonnelReward;
	Template.GiveRewardFn = GivePersonnelReward;
	Template.GetRewardStringFn = GetPersonnelRewardString;
	Template.GetRewardImageFn = GetPersonnelRewardImage;
	Template.GetBlackMarketStringFn = GetSoldierBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.CleanUpRewardFn = CleanUpUnitReward;
	Template.RewardPopupFn = PersonnelRewardPopup;

	return Template;
}

static function string GetSoldierBlackMarketString(XComGameState_Reward RewardState)
{
	return default.SoldierBlackMarketText[`SYNC_RAND_STATIC(default.SoldierBlackMarketText.Length)];
}

static function GeneratePersonnelReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_WorldRegion RegionState;
	local name nmCountry;
	
	// Grab the region and pick a random country
	nmCountry = '';
	RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID));

	if(RegionState != none)
	{
		nmCountry = RegionState.GetMyTemplate().GetRandomCountryInRegion();
	}

	NewUnitState = CreatePersonnelUnit(NewGameState, RewardState.GetMyTemplate().rewardObjectTemplateName, nmCountry, (RewardState.GetMyTemplateName() == 'Reward_Rookie'));
	RewardState.RewardObjectReference = NewUnitState.GetReference();
}

static function XComGameState_Unit CreatePersonnelUnit(XComGameState NewGameState, name nmCharacter, name nmCountry, optional bool bIsRookie)
{
	local XComGameStateHistory History;
	local XComGameState_Unit NewUnitState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int idx, NewRank, StartingIdx;

	History = `XCOMHISTORY;

	//Use the character pool's creation method to retrieve a unit
	NewUnitState = `CHARACTERPOOLMGR.CreateCharacter(NewGameState, `XPROFILESETTINGS.Data.m_eCharPoolUsage, nmCharacter, nmCountry);
	NewUnitState.RandomizeStats();

	if (NewUnitState.IsSoldier())
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

		if (!NewGameState.GetContext().IsStartState())
		{
			ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
		}

		NewUnitState.ApplyInventoryLoadout(NewGameState);
		NewRank = GetPersonnelRewardRank(true, bIsRookie);
		NewUnitState.SetXPForRank(NewRank);
		NewUnitState.StartingRank = NewRank;
		StartingIdx = 0;

		if(NewUnitState.GetMyTemplate().DefaultSoldierClass != '' && NewUnitState.GetMyTemplate().DefaultSoldierClass != class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)
		{
			// Some character classes start at squaddie on creation
			StartingIdx = 1;
		}

		for (idx = StartingIdx; idx < NewRank; idx++)
		{
			// Rank up to squaddie
			if (idx == 0)
			{
				NewUnitState.RankUpSoldier(NewGameState, ResistanceHQ.SelectNextSoldierClass());
				NewUnitState.ApplySquaddieLoadout(NewGameState);
				NewUnitState.bNeedsNewClassPopup = false;
			}
			else
			{
				NewUnitState.RankUpSoldier(NewGameState, NewUnitState.GetSoldierClassTemplate().DataName);
			}
		}

		// Set an appropriate fame score for the unit
		NewUnitState.StartingFame = XComHQ.AverageSoldierFame;
		NewUnitState.bIsFamous = true;
		`XEVENTMGR.TriggerEvent('RewardUnitGenerated', NewUnitState, NewUnitState); //issue #185 - fires off event with unit after they've been promoted to their reward rank
	}
	else
	{
		NewUnitState.SetSkillLevel(GetPersonnelRewardRank(false));
	}

	return NewUnitState;
}

static function SetPersonnelReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.RewardObjectReference = RewardObjectRef;
}

static function GivePersonnelReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;	
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;	

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	if(UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RewardState.RewardObjectReference.ObjectID));
		UnitState.TacticalTag = ''; // Clear any previously applied tactical tags
	}
		
	`assert(UnitState != none);

	if(bOrder)
	{
		XComHQ.OrderStaff(UnitState.GetReference(), OrderHours);
	}
	else
	{
		// If the reward unit is a soldier, make sure they have the best gear XCOM has acquired
		if (UnitState.IsSoldier())
		{
			UnitState.ApplyBestGearLoadout(NewGameState);
		}

		XComHQ.AddToCrew(NewGameState, UnitState);
		XComHQ.HandlePowerOrStaffingChange(NewGameState);
	}
}

static function string GetPersonnelRewardString(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if(UnitState != none)
	{
		if(UnitState.IsSoldier())
		{
			if(UnitState.GetRank() > 0)
			{
				return UnitState.GetName(eNameType_RankFull) @ "-" @ UnitState.GetSoldierClassTemplate().DisplayName;
			}
			else
			{
				return UnitState.GetName(eNameType_RankFull);
			}
		}
		else
		{
			//return default.DoctorPrefixText @ UnitState.GetName(eNameType_Full) @ "-" @ default.SkillLevelText @ string(UnitState.GetSkillLevel()) @ RewardState.GetMyTemplate().DisplayName;
			return default.DoctorPrefixText @ UnitState.GetName(eNameType_Full) @ "-" @ RewardState.GetMyTemplate().DisplayName;
		}
	}

	return "";
}

static function string GetPersonnelRewardImage(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local Texture2D StaffPicture;
	local XComGameState_Unit UnitState;
	local XComGameState_CampaignSettings SettingsState;

	History = `XCOMHISTORY;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if (UnitState != none)
	{
		SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		StaffPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, RewardState.RewardObjectReference.ObjectID, 512, 512);
		if (StaffPicture == none)
		{
			return "";
		}

		return class'UIUtilities_Image'.static.ValidateImagePath(PathName(StaffPicture));
	}
	
	return "";
}

static function static String GetPersonnelName(XComGameState_Reward RewardState, optional bool bExcludeFirstName)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if( UnitState != none )
	{
		if( UnitState.IsSoldier() )
		{
			if (bExcludeFirstName)
				return UnitState.GetName(eNameType_RankLast);
			else
				return UnitState.GetName(eNameType_RankFull);
		}
		else
		{
			if (bExcludeFirstName)
				return default.DoctorPrefixText @ UnitState.GetLastName();
			else
				return default.DoctorPrefixText @ UnitState.GetFullName();
		}
	}

	return "";
}

static function static XComGameState_WorldRegion GetPersonnelHomeRegion(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_WorldRegion HomeRegion;
	local array<XComGameState_WorldRegion> arrRegions;

	History = `XCOMHISTORY;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if( UnitState != none )
	{
		// TODO: @jsolomon, @mnauta, give units/staff a home region
		
		foreach History.IterateByClassType(class'XComGameState_WorldRegion', HomeRegion)
		{
			arrRegions.AddItem(HomeRegion);
		}

		return arrRegions[Rand(arrRegions.Length)];
	}

	return none;
}

static function int GetPersonnelRewardRank(bool bIsSoldier, optional bool bIsRookie = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int NewRank, idx;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewRank = 1;

	if(bIsSoldier)
	{
		if (bIsRookie)
		{
			return 0;
		}

		for(idx = 0; idx < default.SoldierRewardForceLevelGates.Length; idx++)
		{
			if(AlienHQ.GetForceLevel() >= default.SoldierRewardForceLevelGates[idx])
			{
				NewRank++;
			}
		}
	}
	else
	{
		for(idx = 0; idx < default.CrewRewardForceLevelGates.Length; idx++)
		{
			if(AlienHQ.GetForceLevel() >= default.CrewRewardForceLevelGates[idx])
			{
				NewRank++;
			}
		}
	}

	return NewRank;
}

static function PersonnelRewardPopup(XComGameState_Reward RewardState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if (UnitState != none)
	{
		`HQPRES.UINewStaffAvailable(RewardState.RewardObjectReference);
	}
}

static function X2DataTemplate CreateCapturedSoldierRewardTemplate()
{
	local X2RewardTemplate Template;

	// Council missions can give you your captured soldiers as a reward, so this template will attempt to
	// do that. Otherwise it defaults to generating a soldier reward
	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_SoldierCaptured');
	Template.rewardObjectTemplateName = 'Soldier';

	Template.IsRewardAvailableFn = IsCapturedSoldierRewardAvailable;
	Template.GenerateRewardFn = GenerateCapturedSoldierReward;
	Template.SetRewardFn = SetPersonnelReward;
	Template.GiveRewardFn = GiveCapturedSoldierReward;
	Template.GetRewardStringFn = GetPersonnelRewardString;
	Template.GetBlackMarketStringFn = GetSoldierBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.CleanUpRewardFn = CleanUpUnitReward;
	Template.RewardPopupFn = PersonnelRewardPopup;

	return Template;
}

static function bool IsCapturedSoldierRewardAvailable(optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	// we can only rescue a soldier if there are soldiers to rescue
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	return AlienHQ.CapturedSoldiers.Length > 0;
}

static function GenerateCapturedSoldierReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int CapturedSoldierIndex;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	// first check if the aliens have captured one of our soldiers. If so, then they get to be the reward
	if(AlienHQ.CapturedSoldiers.Length > 0)
	{
		// pick a soldier to rescue and save them as the reward state
		CapturedSoldierIndex = class'Engine'.static.GetEngine().SyncRand(AlienHQ.CapturedSoldiers.Length, "GenerateSoldierReward");
		RewardState.RewardObjectReference = AlienHQ.CapturedSoldiers[CapturedSoldierIndex];

		// remove the soldier from the captured unit list so they don't show up again later in the playthrough
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		AlienHQ.CapturedSoldiers.Remove(CapturedSoldierIndex, 1);
	}
	else
	{
		// somehow the soldier to be rescued has been pulled out from under us! Generate one as a fallback.
		GeneratePersonnelReward(RewardState, NewGameState, RewardScalar, RegionRef);
	}
}

static function GiveCapturedSoldierReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_Unit NewUnitState;
	
	GivePersonnelReward(NewGameState, RewardState, AuxRef, bOrder, OrderHours);

	// The unit should always be in the NewGameState from calling GivePersonnelReward
	NewUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	// mark the soldier as no longer captured
	NewUnitState.bCaptured = false;
}

// #######################################################################################
// -------------------- AVENGER REWARDS ------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateIncreaseScienceScoreRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_ScienceScore');
	Template.rewardObjectTemplateName = 'ScienceScore';

	Template.GenerateRewardFn = GenerateAvengerReward;
	Template.SetRewardFn = SetAvengerReward;
	Template.GiveRewardFn = GiveAvengerReward;
	Template.GetRewardStringFn = GetAvengerRewardString;

	return Template;
}

static function X2DataTemplate CreateIncreaseEngineeringScoreRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_EngineeringScore');
	Template.rewardObjectTemplateName = 'EngineeringScore';

	Template.GenerateRewardFn = GenerateAvengerReward;
	Template.SetRewardFn = SetAvengerReward;
	Template.GiveRewardFn = GiveAvengerReward;
	Template.GetRewardStringFn = GetAvengerRewardString;

	return Template;
}

static function X2DataTemplate CreateIncreaseAvengerResCommsRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_AvengerResComms');
	Template.rewardObjectTemplateName = 'AvengerResComms';

	Template.GenerateRewardFn = GenerateAvengerReward;
	Template.SetRewardFn = SetAvengerReward;
	Template.GiveRewardFn = GiveAvengerReward;
	Template.GetRewardPreviewStringFn = GetAvengerRewardString;
	Template.GetRewardStringFn = GetAvengerRewardString;

	return Template;
}

static function X2DataTemplate CreateIncreaseAvengerPowerRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_AvengerPower');
	Template.rewardObjectTemplateName = 'AvengerPower';

	Template.GenerateRewardFn = GenerateAvengerReward;
	Template.SetRewardFn = SetAvengerReward;
	Template.GiveRewardFn = GiveAvengerReward;
	Template.GetRewardStringFn = GetAvengerRewardString;

	return Template;
}

static function GenerateAvengerReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	switch (RewardState.GetMyTemplate().rewardObjectTemplateName)
	{
	case 'ScienceScore':
		RewardState.Quantity = GetScienceScoreBaseReward();
		break;
	case 'EngineeringScore':
		RewardState.Quantity = GetEngineeringScoreBaseReward();
		break;
	case 'AvengerPower':
		RewardState.Quantity = GetPowerBaseReward();
		break;
	case 'AvengerResComms':
		RewardState.Quantity = GetResCommsBaseReward();
		break;
	default:
		RewardState.Quantity = 0;
		break;
	}

	RewardState.Quantity = Round(RewardScalar * float(RewardState.Quantity));
}

static function SetAvengerReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.Quantity = Amount;
}

static function GiveAvengerReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	switch (RewardState.GetMyTemplate().rewardObjectTemplateName)
	{
	case 'ScienceScore':
		GiveScienceScoreReward(NewGameState, RewardState);
		break;
	case 'EngineeringScore':
		GiveEngineeringScoreReward(NewGameState, RewardState);
		break;
	case 'AvengerPower':
		GiveAvengerPowerReward(NewGameState, RewardState);
		break;
	case 'AvengerResComms':
		GiveAvengerResCommsReward(NewGameState, RewardState);
		break;
	default:
		break;
	}
}

static function string GetAvengerRewardString(XComGameState_Reward RewardState)
{
	return RewardState.GetMyTemplate().DisplayName @ "+" $ RewardState.Quantity;
}

static function GiveScienceScoreReward(XComGameState NewGameState, XComGameState_Reward RewardState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		
	XComHQ.BonusScienceScore += RewardState.Quantity;
}

static function GiveEngineeringScoreReward(XComGameState NewGameState, XComGameState_Reward RewardState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.BonusEngineeringScore += RewardState.Quantity;
}

static function GiveAvengerPowerReward(XComGameState NewGameState, XComGameState_Reward RewardState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.BonusPowerProduced += RewardState.Quantity;
	XComHQ.DeterminePowerState();
}

static function GiveAvengerResCommsReward(XComGameState NewGameState, XComGameState_Reward RewardState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.BonusCommCapacity += RewardState.Quantity;
}

// #######################################################################################
// -------------------- MISSION REWARDS --------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateSupplyRaidMissionRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_SupplyRaid');

	Template.GiveRewardFn = GiveSupplyRaidReward;
	Template.GetRewardStringFn = GetMissionRewardString;
	Template.RewardPopupFn = MissionRewardPopup;

	return Template;
}

static function X2DataTemplate CreateGuerillaOpMissionRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_GuerillaOp');

	Template.GiveRewardFn = GiveGuerillaOpReward;
	Template.GetRewardStringFn = GetMissionRewardString;
	Template.RewardPopupFn = MissionRewardPopup;

	return Template;
}

static function string GetMissionRewardString(XComGameState_Reward RewardState)
{
	return RewardState.GetMyTemplate().DisplayName;
}

static function GiveSupplyRaidReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Reward MissionRewardState;
	local X2RewardTemplate RewardTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local array<XComGameState_Reward> MissionRewards;
	local float MissionDuration;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(AuxRef.ObjectID));	

	MissionRewards.Length = 0;
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	MissionRewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	MissionRewards.AddItem(MissionRewardState);

	MissionState = XComGameState_MissionSite(NewGameState.CreateNewStateObject(class'XComGameState_MissionSite'));

	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_SupplyRaid'));
	
	MissionDuration = float((default.MissionMinDuration + `SYNC_RAND_STATIC(default.MissionMaxDuration - default.MissionMinDuration + 1)) * 3600);
	MissionState.BuildMission(MissionSource, RegionState.GetRandom2DLocationInRegion(), RegionState.GetReference(), MissionRewards, true, true, , MissionDuration);
	MissionState.PickPOI(NewGameState);

	RewardState.RewardObjectReference = MissionState.GetReference();
}

static function GiveGuerillaOpReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionSite MissionState, DarkEventMissionState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Reward MissionRewardState;
	local XComGameState_DarkEvent DarkEventState;
	//local XComGameState_MissionCalendar CalendarState;
	local X2RewardTemplate RewardTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local array<XComGameState_Reward> MissionRewards;
	local array<StateObjectReference> DarkEvents, PossibleDarkEvents;
	local array<int> OnMissionDarkEventIDs;
	local StateObjectReference DarkEventRef;
	local float MissionDuration;
	//local array<name> ExcludeList;

	History = `XCOMHISTORY;
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(AuxRef.ObjectID));
	
	//CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
	MissionRewards.Length = 0;
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Supplies'));
	MissionRewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	MissionRewardState.GenerateReward(NewGameState, , RegionState.GetReference());
	MissionRewards.AddItem(MissionRewardState);

	MissionState = XComGameState_MissionSite(NewGameState.CreateNewStateObject(class'XComGameState_MissionSite'));

	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_GuerillaOp'));

	MissionDuration = float((default.MissionMinDuration + `SYNC_RAND_STATIC(default.MissionMaxDuration - default.MissionMinDuration + 1)) * 3600);
	MissionState.BuildMission(MissionSource, RegionState.GetRandom2DLocationInRegion(), RegionState.GetReference(), MissionRewards, true, true, , MissionDuration);
	MissionState.PickPOI(NewGameState);
	
	// Find out if there are any missions on the board which are paired with Dark Events
	foreach History.IterateByClassType(class'XComGameState_MissionSite', DarkEventMissionState)
	{
		if (DarkEventMissionState.DarkEvent.ObjectID != 0)
		{
			OnMissionDarkEventIDs.AddItem(DarkEventMissionState.DarkEvent.ObjectID);
		}
	}

	// See if there are any Dark Events left over after comparing the mission Dark Event list with the Alien HQ Chosen Events
	DarkEvents = AlienHQ.ChosenDarkEvents;
	foreach DarkEvents(DarkEventRef)
	{		
		if (OnMissionDarkEventIDs.Find(DarkEventRef.ObjectID) == INDEX_NONE)
		{
			PossibleDarkEvents.AddItem(DarkEventRef);
		}
	}

	// If there are Dark Events that this mission can counter, pick a random one and ensure it won't activate before the mission expires
	if (PossibleDarkEvents.Length > 0)
	{
		DarkEventRef = PossibleDarkEvents[`SYNC_RAND_STATIC(PossibleDarkEvents.Length)];		
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(DarkEventRef.ObjectID));
		if (DarkEventState.TimeRemaining < MissionDuration)
		{
			DarkEventState = XComGameState_DarkEvent(NewGameState.ModifyStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			DarkEventState.ExtendActivationTimer(default.MissionMaxDuration);
		}

		MissionState.DarkEvent = DarkEventRef;
	}

	RewardState.RewardObjectReference = MissionState.GetReference();
}

static function MissionRewardPopup(XComGameState_Reward RewardState)
{
	local XComGameState_MissionSite MissionSite;

	MissionSite = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	if (MissionSite != none && MissionSite.GetMissionSource().MissionPopupFn != none)
	{
		MissionSite.GetMissionSource().MissionPopupFn(MissionSite);
	}
}

// #######################################################################################
// -------------------- ITEM REWARDS -----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateItemRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Item');

	// Generic template designed to be overwritten, used by the Black Market
	Template.GenerateRewardFn = GenerateItemReward;
	Template.SetRewardFn = SetItemReward;
	Template.GiveRewardFn = GiveItemReward;
	Template.GetRewardStringFn = GetItemRewardString;
	Template.GetRewardImageFn = GetItemRewardImage;
	Template.GetBlackMarketStringFn = GetItemBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.RewardPopupFn = ItemRewardPopup;

	return Template;
}

static function ItemRewardPopup(XComGameState_Reward RewardState)
{
	local XComGameState_Item ItemState;

	ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	if (ItemState != none)
	{
		`HQPRES.UIItemReceived(ItemState.GetMyTemplate());
	}
}

static function X2DataTemplate CreateHeavyWeaponRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_HeavyWeapon');

	Template.GenerateRewardFn = GenerateHeavyWeaponReward;
	Template.SetRewardFn = SetItemReward;
	Template.GiveRewardFn = GiveItemReward;
	Template.GetRewardStringFn = GetItemRewardString;
	Template.GetRewardImageFn = GetItemRewardImage;
	Template.GetBlackMarketStringFn = GetItemBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.RewardPopupFn = ItemRewardPopup;

	return Template;
}

static function X2DataTemplate CreateAmmoRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Ammo');

	Template.GenerateRewardFn = GenerateAmmoReward;
	Template.SetRewardFn = SetItemReward;
	Template.GiveRewardFn = GiveItemReward;
	Template.GetRewardStringFn = GetItemRewardString;
	Template.GetRewardImageFn = GetItemRewardImage;
	Template.GetBlackMarketStringFn = GetItemBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.RewardPopupFn = ItemRewardPopup;

	return Template;
}

static function X2DataTemplate CreateGrenadeRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_Grenade');

	Template.GenerateRewardFn = GenerateGrenadeReward;
	Template.SetRewardFn = SetItemReward;
	Template.GiveRewardFn = GiveItemReward;
	Template.GetRewardStringFn = GetItemRewardString;
	Template.GetRewardImageFn = GetItemRewardImage;
	Template.GetBlackMarketStringFn = GetItemBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.RewardPopupFn = ItemRewardPopup;

	return Template;
}

static function X2DataTemplate CreateFacilityLeadRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_FacilityLead');
	Template.rewardObjectTemplateName = 'FacilityLeadItem';

	Template.IsRewardAvailableFn = IsFacilityLeadRewardAvailable;
	Template.GenerateRewardFn = GenerateItemReward;
	Template.SetRewardFn = SetItemReward;
	Template.GiveRewardFn = GiveItemReward;
	Template.GetRewardStringFn = GetItemRewardString;
	Template.GetRewardImageFn = GetItemRewardImage;
	Template.GetBlackMarketStringFn = GetItemBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.RewardPopupFn = ItemRewardPopup;

	return Template;
}

static function bool IsFacilityLeadRewardAvailable(optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Missions;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	Missions = AlienHQ.GetValidFacilityDoomMissions(true);

	return (Missions.Length > 0);
}

static function string GetItemBlackMarketString(XComGameState_Reward RewardState)
{
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local String BMText;

	History = `XCOMHISTORY;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	BMText = ItemState.GetMyTemplate().GetItemBlackMarketText();
	if( BMText != "" )
	{
		return BMText;
	}

	return default.GenericItemBlackMarketText[`SYNC_RAND_STATIC(default.GenericItemBlackMarketText.Length)];
}

static function GenerateItemReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(RewardState.GetMyTemplate().rewardObjectTemplateName);
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

	RewardState.RewardObjectReference = ItemState.GetReference();
}

static function GenerateHeavyWeaponReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local name RewardDeckName;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.IsTechResearched('AdvancedHeavyWeapons'))
		RewardDeckName = default.AdvHeavyWeaponRewardDeck;
	else
		RewardDeckName = default.HeavyWeaponRewardDeck;
	
	GenerateDeckedItemReward(RewardState, NewGameState, RewardDeckName);
}

static function GenerateAmmoReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{	
	GenerateDeckedItemReward(RewardState, NewGameState, default.AmmoRewardDeck);
}

static function GenerateGrenadeReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{	
	GenerateDeckedItemReward(RewardState, NewGameState, default.GrenadeRewardDeck);
}

static function GenerateDeckedItemReward(XComGameState_Reward RewardState, XComGameState NewGameState, name RewardDeckName)
{	
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local XComGameState_Item ItemState;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local X2CardManager CardManager;
	local string RewardName;

	CardManager = class'X2CardManager'.static.GetCardManager();
	CardManager.SelectNextCardFromDeck(RewardDeckName, RewardName);

	// Safety check in case the deck doesn't exist
	if (RewardName == "")
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
		{
			if (TechState.GetMyTemplate().RewardDeck == RewardDeckName)
			{
				TechState.SetUpTechRewardDeck(TechState.GetMyTemplate());
				CardManager.SelectNextCardFromDeck(TechState.GetMyTemplate().RewardDeck, RewardName);
				break;
			}
		}
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemTemplateManager.FindItemTemplate(name(RewardName));

	// Find the highest available upgraded version of the item
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.UpdateItemTemplateToHighestAvailableUpgrade(ItemTemplate);

	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	RewardState.RewardObjectReference = ItemState.GetReference();
}

static function SetItemReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.RewardObjectReference = RewardObjectRef;
}

static function GiveItemReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local bool bXComHQGameStateCreated;

	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		bXComHQGameStateCreated = true;
	}
	
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if(!XComHQ.PutItemInInventory(NewGameState, ItemState))
	{
		if (bXComHQGameStateCreated) // Only delete the XComHQ game state if it was created by this function
		{
			NewGameState.PurgeGameStateForObjectID(XComHQ.ObjectID);
		}
	}
}

static function string GetItemRewardString(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if(ItemState != none)
	{
		return string(ItemState.Quantity) @ (ItemState.Quantity == 1 ? ItemState.GetMyTemplate().GetItemFriendlyName() : ItemState.GetMyTemplate().GetItemFriendlyNamePlural());
	}

	return "";
}

static function string GetItemRewardImage(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if (ItemState != none)
	{
		return ItemState.GetMyTemplate().strImage;
	}

	return "";
}

//---------------------------------------------------------------------------------------
static function string GetGenericRewardIcon(XComGameState_Reward RewardState)
{
	local XComGameState_Tech TechState;
	local XComGameState_Unit UnitState;
	local StateObjectReference EmptyRef;
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;

	if(RewardState.RewardObjectReference != EmptyRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

		if(UnitState != none)
		{
			if( UnitState.IsEngineer() )  	
				return class'UIUtilities_Image'.const.AlertIcon_Engineering;
			else if( UnitState.IsScientist() )  	
				return class'UIUtilities_Image'.const.AlertIcon_Science;
			else
				return class'UIUtilities_Image'.const.EventQueue_Staff;
		}

		TechState = XComGameState_Tech(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

		if(TechState == none)
		{
			return class'UIUtilities_Image'.const.AlertIcon_Science;
		}
		
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

		if (ItemState != none)
		{
			return ItemState.GetMyTemplate().strImage;
		}
	}
	return "";
}


// #######################################################################################
// -------------------- LOOT TABLE  ------------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateLootTableRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_LootTable');
	Template.rewardObjectTemplateName = 'POI';
	
	Template.SetRewardByTemplateFn = SetLootTableReward;
	Template.GiveRewardFn = GiveLootTableReward;
	Template.GetRewardStringFn = GetLootTableRewardString;

	return Template;
}

static function SetLootTableReward(XComGameState_Reward RewardState, name TemplateName)
{
	RewardState.RewardObjectTemplateName = TemplateName;
}

static function GiveLootTableReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateManager;
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;
	local X2LootTableManager LootManager;
	local LootResults LootToGive;
	local name LootName;
	local int LootIndex, idx;
	local string LootString;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	LootManager = class'X2LootTableManager'.static.GetLootTableManager();
	LootIndex = LootManager.FindGlobalLootCarrier(RewardState.GetMyTemplate().rewardObjectTemplateName);
	if (LootIndex >= 0)
	{
		LootManager.RollForGlobalLootCarrier(LootIndex, LootToGive);
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// First give each piece of loot to XComHQ so it can be collected and added to LootRecovered, which will stack it automatically
	foreach LootToGive.LootToBeCreated(LootName)
	{
		ItemTemplate = ItemTemplateManager.FindItemTemplate(LootName);
		ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
		XComHQ.PutItemInInventory(NewGameState, ItemState, true);
	}

	// Then create the loot string for the room
	for (idx = 0; idx < XComHQ.LootRecovered.Length; idx++)
	{
		ItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(XComHQ.LootRecovered[idx].ObjectID));

		if (ItemState != none)
		{
			LootString $= ItemState.GetMyTemplate().GetItemFriendlyName() $ " x" $ ItemState.Quantity;

			if (idx < XComHQ.LootRecovered.Length - 1)
			{
				LootString $= ", ";
			}
		}
	}
	RewardState.RewardString = LootString;
	
	// Actually add the loot which was generated to the inventory
	class'XComGameStateContext_StrategyGameRule'.static.AddLootToInventory(NewGameState);
}

static function string GetLootTableRewardString(XComGameState_Reward RewardState)
{
	return RewardState.RewardString;
}

// #######################################################################################
// -------------------- REGION REWARDS ---------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateIncreaseIncomeRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_IncreaseIncome');

	Template.GenerateRewardFn = GenerateIncreaseIncomeReward;
	Template.SetRewardFn = SetIncreaseIncomeReward;
	Template.GiveRewardFn = GiveIncreaseIncomeReward;
	Template.GetRewardDetailsStringFn = GetIncreaseIncomeRewardString;
	Template.GetRewardStringFn = GetIncreaseIncomeRewardString;
	Template.CleanUpRewardFn = CleanUpRewardWithoutRemoval;

	return Template;
}

static function GenerateIncreaseIncomeReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_CovertAction ActionState;
	local int iIncomeAmt, iAdjPercent, iAdjAmount;
	local float fAdjust;

	History = `XCOMHISTORY;
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(AuxRef.ObjectID));
	ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(AuxRef.ObjectID));
	if (ActionState != none)
	{
		RewardState.RewardObjectReference = ActionState.GetWorldRegion().GetReference();
	}
	else
	{
		RewardState.RewardObjectReference = RegionState.GetReference();
	}

	iIncomeAmt = Round(float(GetIncreaseIncomeBaseReward()) * RewardScalar);
	iAdjPercent = `SYNC_RAND_STATIC(default.IncreaseIncomeRangePercent + 1);

	if (class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
	{
		iAdjPercent = -iAdjPercent;
	}

	fAdjust = (float(iAdjPercent) / 100.0f);
	iAdjAmount = Round(fAdjust*float(iIncomeAmt));
	iIncomeAmt += iAdjAmount;

	RewardState.Quantity = iIncomeAmt;
}

static function SetIncreaseIncomeReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.Quantity = Amount;
}

static function GiveIncreaseIncomeReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_WorldRegion RegionState;

	RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', RewardState.RewardObjectReference.ObjectID));
	RegionState.POISupplyBonusDelta += RewardState.Quantity;
}

static function string GetIncreaseIncomeRewardString(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local XGParamTag kTag;

	History = `XCOMHISTORY;
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if (RegionState != none)
	{
		kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		kTag.IntValue0 = RewardState.Quantity;
		kTag.StrValue0 = RegionState.GetDisplayName();
		return `XEXPAND.ExpandString(default.IncomeIncreasedLabel);
	}

	return "";
}

static function X2DataTemplate CreateReducedContactRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_ReducedContact');

	Template.GenerateRewardFn = GenerateReducedContactReward;
	Template.SetRewardFn = SetReducedContactReward;
	Template.GiveRewardFn = GiveReducedContactReward;
	Template.GetRewardStringFn = GetReducedContactRewardString;
	Template.CleanUpRewardFn = CleanUpRewardWithoutRemoval;

	return Template;
}

static function GenerateReducedContactReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	RewardState.Quantity = Round(float(GetReduceContactCostModifier()) * RewardScalar);
}

static function SetReducedContactReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.Quantity = Amount;
}

static function GiveReducedContactReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.bReducedContact = true;
	XComHQ.ReducedContactModifier = (RewardState.Quantity / 100.0); // convert from int to float percentage
}

static function string GetReducedContactRewardString(XComGameState_Reward RewardState)
{
	local XGParamTag kTag;
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.IntValue0 = RewardState.Quantity;

	return `XEXPAND.ExpandString(default.RewardReducedContact);
}

// #######################################################################################
// -------------------- DOOM REDUCTION REWARDS -------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateDoomReductionRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_DoomReduction');

	Template.GenerateRewardFn = GenerateDoomReductionReward;
	Template.SetRewardFn = SetDoomReductionReward;
	Template.GiveRewardFn = GiveDoomReductionReward;
	Template.GetRewardStringFn = GetDoomReductionRewardString;

	return Template;
}

static function GenerateDoomReductionReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	RewardState.Quantity = 168.0;
}

static function SetDoomReductionReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.Quantity = Amount;
}

static function GiveDoomReductionReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	if(AlienHQ == none)
	{
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	}

	AlienHQ.ExtendDoomTimer(RewardState.Quantity);
}

static function string GetDoomReductionRewardString(XComGameState_Reward RewardState)
{
	return RewardState.GetMyTemplate().DisplayName $ ":" @ class'UIUtilities_Text'.static.GetTimeRemainingString(RewardState.Quantity);
}

// #######################################################################################
// -------------------- UNLOCK REWARDS ---------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateUnlockResearchRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_UnlockResearch');

	Template.SetRewardFn = SetUnlockResearchReward;
	Template.GiveRewardFn = GiveUnlockResearchReward;
	Template.GetRewardStringFn = GetUnlockResearchRewardString;

	return Template;
}

static function SetUnlockResearchReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.RewardObjectReference = RewardObjectRef;
}

static function GiveUnlockResearchReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_Tech TechState;

	TechState = XComGameState_Tech(NewGameState.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if(TechState == none)
	{
		TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', RewardState.RewardObjectReference.ObjectID));
	}

	if(TechState != none)
	{
		TechState.bBlocked = false;
	}
}

static function string GetUnlockResearchRewardString(XComGameState_Reward RewardState)
{
	local XComGameState_Tech TechState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if(TechState != none)
	{
		return TechState.GetMyTemplate().DisplayName;
	}
	
	return "";
}

static function X2DataTemplate CreateUnlockItemRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_UnlockItem');

	Template.SetRewardFn = SetUnlockItemReward;
	Template.GiveRewardFn = GiveUnlockItemReward;
	Template.GetRewardStringFn = GetUnlockItemRewardString;

	return Template;
}

static function SetUnlockItemReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.RewardObjectReference = RewardObjectRef;
}

static function GiveUnlockItemReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));	

	ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if(ItemState != none)
	{
		XComHQ.UnlockedItems.AddItem(ItemState.GetMyTemplateName());
	}
}

static function string GetUnlockItemRewardString(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if(ItemState != none)
	{
		return ItemState.GetMyTemplate().GetItemFriendlyName();
	}
	
	return "";
}

// #######################################################################################
// -------------------- HAVEN OP ---------------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateHavenOpRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_HavenOp');

	Template.SetRewardByTemplateFn = SetHavenOpReward;
	Template.GiveRewardFn = GiveHavenOpReward;
	Template.GetRewardStringFn = GetHavenOpRewardString;

	return Template;
}

static function SetHavenOpReward(XComGameState_Reward RewardState, name TemplateName)
{
	RewardState.RewardObjectTemplateName = TemplateName;
}

static function GiveHavenOpReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2HavenOpTemplate HavenOpTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	HavenOpTemplate = X2HavenOpTemplate(StratMgr.FindStrategyElementTemplate(RewardState.RewardObjectTemplateName));

	if(HavenOpTemplate != none && HavenOpTemplate.OnLaunchedFn != none)
	{
		HavenOpTemplate.OnLaunchedFn(NewGameState, HavenOpTemplate, AuxRef);
	}
}

static function string GetHavenOpRewardString(XComGameState_Reward RewardState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2HavenOpTemplate HavenOpTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	HavenOpTemplate = X2HavenOpTemplate(StratMgr.FindStrategyElementTemplate(RewardState.RewardObjectTemplateName));

	return HavenOpTemplate.DisplayName;
}

// #######################################################################################
// -------------------- TECH RUSH --------------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateTechRushRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_TechRush');

	Template.SetRewardFn = SetTechRushReward;
	Template.GiveRewardFn = GiveTechRushReward;
	Template.GetRewardStringFn = GetTechRushRewardString;
	Template.GetRewardImageFn = GetTechRushRewardImage;
	Template.GetBlackMarketStringFn = GetTechRushBlackMarketString;
	Template.GetRewardIconFn = GetGenericRewardIcon;
	Template.CleanUpRewardFn = CleanUpRewardWithoutRemoval;

	return Template;
}

static function SetTechRushReward(XComGameState_Reward RewardState, optional StateObjectReference RewardObjectRef, optional int Amount)
{
	RewardState.RewardObjectReference = RewardObjectRef;
}

static function GiveTechRushReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ProjectState;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;

	// Adjust Tech's time reduction value
	TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', RewardState.RewardObjectReference.ObjectID));
	TechState.TimeReductionScalar = GetTechRushReductionScalar();

	// If there is already a project rush it
	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectResearch', ProjectState)
	{
		if(ProjectState.ProjectFocus == RewardState.RewardObjectReference)
		{
			ProjectState = XComGameState_HeadquartersProjectResearch(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectResearch', ProjectState.ObjectID));
			ProjectState.RushResearch(NewGameState);
			return;
		}
	}
}

static function string GetTechRushRewardString(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	return default.TechRushText @ TechState.GetDisplayName();
}

static function string GetTechRushRewardImage(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	return TechState.GetMyTemplate().strImage;
}

static function string GetTechRushBlackMarketString(XComGameState_Reward RewardState)
{
	return default.TechRushBlackMarketText[`SYNC_RAND_STATIC(default.TechRushBlackMarketText.Length)];
}

// #######################################################################################
// --------------------- RESISTANCE HQ MODES ---------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateResistanceModeRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_ResistanceMode');
		
	Template.GiveRewardFn = GiveResistanceModeReward;
	
	return Template;
}

static function GiveResistanceModeReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameState_HeadquartersResistance ResHQ;
	
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
	
	ResHQ.DeactivateResistanceMode(NewGameState);
	ResHQ.ResistanceMode = RewardState.RewardObjectTemplateName;
	ResHQ.ActivateResistanceMode(NewGameState);
}

// #######################################################################################
// -------------------- NO REWARD --------------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateNoRewardTemplate()
{
	local X2RewardTemplate Template;

	`CREATE_X2Reward_TEMPLATE(Template, 'Reward_None');

	return Template;
}

// #######################################################################################
// ---------------------- DELEGATE HELPERS -----------------------------------------------
// #######################################################################################
static function CleanUpRewardWithoutRemoval(XComGameState NewGameState, XComGameState_Reward RewardState)
{
	// Blank Clean Up function so the RewardObjectReference is not removed, which is the default behavior
}

static function CleanUpUnitReward(XComGameState NewGameState, XComGameState_Reward RewardState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	}

	if (UnitState != none)
	{
		// First remove the units items
		UnitState.BlastLoadout(NewGameState);
		
		// Then remove the actual unit
		NewGameState.RemoveStateObject(UnitState.ObjectID);
	}
}

static function XComGameState_ResistanceFaction GetFactionState(XComGameState NewGameState, StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_CovertAction ActionState;

	// First try to get the Faction state directly from the NewGameState
	if (NewGameState != none)
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.GetGameStateForObjectID(AuxRef.ObjectID));
		ActionState = XComGameState_CovertAction(NewGameState.GetGameStateForObjectID(AuxRef.ObjectID));
	}

	// Then try to get it directly from the History
	if (FactionState == none)
	{
		History = `XCOMHISTORY;
		FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(AuxRef.ObjectID));

		// Don't overwrite the ActionState if it was found in the NewGameState
		if (FactionState == none && ActionState == none)
		{
			ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(AuxRef.ObjectID));
		}
	}

	// If FactionState is still not found, check if the Covert Action exists and use it to get the Faction
	if (FactionState == none && ActionState != none)
	{
		FactionState = ActionState.GetFaction();
	}

	return FactionState;
}

static function XComGameState_CovertAction GetCovertActionState(XComGameState NewGameState, StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;

	// First try to get the Faction state directly from the NewGameState
	if (NewGameState != none)
	{
		ActionState = XComGameState_CovertAction(NewGameState.GetGameStateForObjectID(AuxRef.ObjectID));
	}

	// Then try to get it directly from the History
	if (ActionState == none)
	{
		History = `XCOMHISTORY;
		ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(AuxRef.ObjectID));
	}

	return ActionState;
}

static function int CountAvailableRewards(name RewardName)
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState;
	local XComGameState_CovertAction ActionState;
	local XComGameState_Reward RewardState;
	local StateObjectReference RewardRef;
	local int AvailableRewards;

	History = `XCOMHISTORY;

	// First iterate through all of the available POIs
	foreach History.IterateByClassType(class'XComGameState_PointOfInterest', POIState)
	{
		if (POIState.bAvailable)
		{
			foreach POIState.RewardRefs(RewardRef)
			{
				RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
				if (RewardState.GetMyTemplateName() == RewardName)
				{
					AvailableRewards++;
				}
			}
		}
	}

	// Then check all of the available Covert Actions
	foreach History.IterateByClassType(class'XComGameState_CovertAction', ActionState)
	{
		if (ActionState.bAvailable)
		{
			foreach ActionState.RewardRefs(RewardRef)
			{
				RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
				if (RewardState.GetMyTemplateName() == RewardName)
				{
					AvailableRewards++;
				}
			}
		}
	}

	return AvailableRewards;
}

// #######################################################################################
// -------------------- DIFFICULTY HELPERS -----------------------------------------------
// #######################################################################################

static function int GetIntelBaseReward()
{
	return `ScaleStrategyArrayInt(default.IntelBaseReward);
}

static function int GetIntelRewardIncrease()
{
	return `ScaleStrategyArrayInt(default.IntelRewardIncrease);
}

static function int GetIntelInterval()
{
	return `ScaleStrategyArrayInt(default.IntelInterval);
}

static function int GetAlloysBaseReward()
{
	return `ScaleStrategyArrayInt(default.AlloysBaseReward);
}

static function int GetAlloysRewardIncrease()
{
	return `ScaleStrategyArrayInt(default.AlloysRewardIncrease);
}

static function int GetAlloysInterval()
{
	return `ScaleStrategyArrayInt(default.AlloysInterval);
}

static function int GetEleriumBaseReward()
{
	return `ScaleStrategyArrayInt(default.EleriumBaseReward);
}

static function int GetEleriumRewardIncrease()
{
	return `ScaleStrategyArrayInt(default.EleriumRewardIncrease);
}

static function int GetEleriumInterval()
{
	return `ScaleStrategyArrayInt(default.EleriumInterval);
}

static function float GetTechRushReductionScalar()
{
	return `ScaleStrategyArrayFloat(default.TechRushReductionScalar);
}

static function int GetReduceContactCostModifier()
{
	return `ScaleStrategyArrayInt(default.ReducedContactBaseModifier);
}

static function int GetIncreaseIncomeBaseReward()
{
	return `ScaleStrategyArrayInt(default.IncreaseIncomeBaseReward);
}

static function int GetScienceScoreBaseReward()
{
	return `ScaleStrategyArrayInt(default.ScienceScoreBaseReward);
}

static function int GetEngineeringScoreBaseReward()
{
	return `ScaleStrategyArrayInt(default.EngineeringScoreBaseReward);
}

static function int GetPowerBaseReward()
{
	return `ScaleStrategyArrayInt(default.PowerBaseReward);
}

static function int GetResCommsBaseReward()
{
	return `ScaleStrategyArrayInt(default.ResCommsBaseReward);
}