//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyGame_SimCombat.uc
//  AUTHOR:  Mark Nauta  --  09/04/2014
//  PURPOSE: Class for simming tactical combat from the strategy game
//           
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyGame_SimCombat 
	extends object
	native(Core) 
	config(GameData)
	dependson(UIMissionSummary);

enum EPowerCompare
{
	ePowerCompare_MajorDisadvantage,
	ePowerCompare_Disadvantage,
	ePowerCompare_MinorDisadvantage,
	ePowerCompare_Neutral,
	ePowerCompare_MinorAdvantage,
	ePowerCompare_Advantage,
	ePowerCompare_MajorAdvantage,
};

struct native PowerCompareDefinition
{
	var EPowerCompare ePowCompare;
	var float         MinThreshold;
	var float         MaxThreshold;
	var int           KIAChance;
	var int           MaxKIAs;
	var int           WoundChance;
	var int           SuccessChance;
};

struct native AlertExclusionScoreMapping
{
	var int			  MinAlert;
	var int			  MaxAlert;
	var float		  ExclusionValue;
	var float		  ScoreValue;
};

// Config vars
var config float							 BaseItemPower;
var config float							 ModifiedItemPower;
var config float							 PowerPerItemTech;
var config float							 ItemPowerTierBonus;
var config int								 UnitAliveSuccessBonus;
var config int								 XPPercentVariance;
var config int								 MinEnemiesLooted;
var config int								 MaxEnemiesLooted;
var config int								 MinEncounters;
var config int								 MaxEncounters;
var config float							 BaseEnemyValue;
var config array<float>						 RankMultipliers;
var config array<name>						 TierTechs;
var config array<name>						 ExcludedItems;
var config array<float>						 AlertLevelMultipliers;
var config array<int>						 AlertLevelWoundModifiers;
var config array<int>						 AlertLevelKIAModifiers;
var config array<float>						 ForceLevelPowers;
var config array<PowerCompareDefinition>	 PowerCompareDefinitions;
var config array<int>						 ForceLevelXP;
var config int								 MinIntel;
var config int								 MaxIntel;

//#############################################################################################
//----------------   SIMCOMBAT   --------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SimCombat()
{
	local TSimCombatSummaryData SummaryData;
	local PowerCompareDefinition PowCompare;
	local int NumAlive;
	local bool bTacticalSuccess, bStrategySuccess, bTriadSuccess;
	local array<StateObjectReference> Enemies;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	class'XComGameStateContext_StrategyGameRule'.static.UpdateSkyranger();
	InitializeMission(SummaryData);
	PowCompare = GetPowerComparison();
	NumAlive = 0;
	Enemies = GetEnemiesOnMission();
	DetermineKillsAndXP(Enemies);
	CalculateDeathsAndWounds(PowCompare, NumAlive);
	DetermineLoot(Enemies);

	bTacticalSuccess = DetermineMissionSuccess(PowCompare, NumAlive);
	bStrategySuccess = bTacticalSuccess;
	bTriadSuccess = bTacticalSuccess;
	class'XComGameStateContext_StrategyGameRule'.static.CleanupProxyVips();
	ProcessMission(bTacticalSuccess, bStrategySuccess, bTriadSuccess, SummaryData);

	class'XComGameStateContext_StrategyGameRule'.static.SquadTacticalToStrategyTransfer();

	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPostMission();
	}

	CompleteTacticalGoldenPathObjectives();

	`GAME.GetGeoscape().m_kBase.ResetPreMissionMap(); //Reset the pre mission map so that sim combat can run it over and over without issue
	`GAME.GetGeoscape().OnEnterMissionControl(true);
}

//#############################################################################################
//----------------   WOUNDS AND KIA   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function PowerCompareDefinition GetPowerComparison()
{
	local float SquadPower, AlienPower, PowerDiff, TotalPower;
	local int idx;

	SquadPower = GetSquadPowerLevel();
	AlienPower = GetAlienPowerLevel();
	TotalPower = SquadPower + AlienPower;
	PowerDiff = (((SquadPower - AlienPower)/TotalPower) * 100.0);

	for(idx = 0; idx < default.PowerCompareDefinitions.Length; idx++)
	{
		if(PowerDiff >= default.PowerCompareDefinitions[idx].MinThreshold &&
			PowerDiff <= default.PowerCompareDefinitions[idx].MaxThreshold)
		{
			return default.PowerCompareDefinitions[idx];
		}
	}

	return default.PowerCompareDefinitions[3]; // returns neutral if something went wrong
}

//---------------------------------------------------------------------------------------
static function CalculateDeathsAndWounds(PowerCompareDefinition PowCompare, out int NumAlive)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> SortedUnits;
	local int idx, KillCount, MaxKills, CurrentWill, WillDeduction;
	local XComGameState_BattleData BattleData;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SimCombat: Calculate Death and Wounds");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	MaxKills = PowCompare.MaxKIAs;

	if( `TACTICALDIFFICULTYSETTING <= 1 )
	{
		MaxKills = 1;
	}

	KillCount = 0;

	for(idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

		if(UnitState != none)
		{
			SortedUnits.AddItem(UnitState);
		}
	}

	SortedUnits.Sort(SortUnits);

	for(idx = 0; idx < SortedUnits.Length; idx++)
	{
		UnitState = SortedUnits[idx];

		if(UnitState != none)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.LowestHP = UnitState.GetCurrentStat(eStat_HP);
			UnitState.HighestHP = UnitState.GetCurrentStat(eStat_HP);
			UnitState.SimEvacuate();

			if(KillCount < MaxKills && class'X2StrategyGameRulesetDataStructures'.static.Roll(PowCompare.KIAChance + GetAlertLevelWoundModifier(true)))
			{
				UnitState.SetCurrentStat(eStat_HP, 0);
				UnitState.LowestHP = 0;
				UnitState.m_strKIAOp = BattleData.m_strOpName;
				UnitState.m_KIADate = BattleData.LocalTime;
				KillCount++;
			}
			else if(class'X2StrategyGameRulesetDataStructures'.static.Roll(PowCompare.WoundChance + GetAlertLevelWoundModifier(false)))
			{
				UnitState.SetCurrentStat(eStat_HP, 1+(`SYNC_RAND_STATIC(int(UnitState.GetMaxStat(eStat_HP)-1))));
				UnitState.LowestHP = UnitState.GetCurrentStat(eStat_HP);
				NumAlive++;
			}
			else
			{
				NumAlive++;
			}

			CurrentWill = UnitState.GetCurrentStat(eStat_Will);
			WillDeduction = UnitState.GetMaxStat(eStat_Will) * 0.2;
			UnitState.SetCurrentStat(eStat_Will, max(CurrentWill - WillDeduction, 1));
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
//---------------------------------------------------------------------------------------
private static function int SortUnits(XComGameState_Unit UnitA, XComGameState_Unit UnitB)
{
	return (Round(GetSoldierPowerLevel(UnitB) - GetSoldierPowerLevel(UnitA)));
}

//---------------------------------------------------------------------------------------
static function int GetAlertLevelWoundModifier(bool bKIA)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));


	if(bKIA)
	{
		return default.AlertLevelKIAModifiers[MissionState.GetMissionDifficulty()];
	}

	return default.AlertLevelWoundModifiers[MissionState.GetMissionDifficulty()];
}

//#############################################################################################
//----------------   MISSION   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function bool DetermineMissionSuccess(PowerCompareDefinition PowCompare, int NumAlive)
{
	if(NumAlive == 0)
	{
		return false;
	}
	else if( `TACTICALDIFFICULTYSETTING <= 1 )
	{
		return true;
	}

	return class'X2StrategyGameRulesetDataStructures'.static.Roll(PowCompare.SuccessChance + (NumAlive*default.UnitAliveSuccessBonus));
}

//---------------------------------------------------------------------------------------
static function InitializeMission(out TSimCombatSummaryData SummaryData)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionSite MissionState;
	local GeneratedMissionData MissionData;
	local XComGameState_BattleData BattleData;
	local XComTacticalMissionManager TacticalMissionManager;
	local X2SelectedMissionData EmptyMissionData;
	local XComGameState_Player CivilianPlayerState;
	local XComGameState_Player ResistancePlayerState;
	local XComGameState_GameTime TimeState;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	History = `XCOMHISTORY;
	TacticalMissionManager = `TACTICALMISSIONMGR;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SimCombat: Initialize Mission");

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', XComHQ.MissionRef.ObjectID));
	XComHQ.AddMissionTacticalTags(MissionState);
	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);

	EventManager = `ONLINEEVENTMGR;
		DLCInfos = EventManager.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPreMission(NewGameState, MissionState);
	}

	if(MissionState.SelectedMissionData == EmptyMissionData)
	{
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		MissionState.CacheSelectedMissionData(AlienHQ.GetForceLevel(), MissionState.GetMissionDifficulty());
	}

	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));

	BattleData = XComGameState_BattleData(NewGameState.CreateNewStateObject(class'XComGameState_BattleData'));
	BattleData.m_iMissionID = MissionState.ObjectID;
	BattleData.m_strOpName = MissionData.BattleOpName;
	BattleData.LocalTime = TimeState.CurrentTime;

	CivilianPlayerState = class'XComGameState_Player'.static.CreatePlayer(NewGameState, eTeam_Neutral);
	CivilianPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleData.CivilianPlayerRef = CivilianPlayerState.GetReference();

	ResistancePlayerState = class'XComGameState_Player'.static.CreatePlayer(NewGameState, eTeam_Resistance);
	ResistancePlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleData.CivilianPlayerRef = ResistancePlayerState.GetReference();

	BattleData.m_iMissionType = TacticalMissionManager.arrMissions.Find('sType', MissionData.Mission.sType);
	TacticalMissionManager.InitMission(BattleData);

	SummaryData.MissionName = MissionData.BattleOpName;
	SummaryData.MissionType = class'X2MissionTemplateManager'.static.GetMissionTemplateManager().GetMissionDisplayName(MissionData.Mission.MissionName);
	SummaryData.MissionLocation = MissionState.GetWorldRegion().GetMyTemplate().DisplayName;

	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPreMission(NewGameState, MissionState);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function ProcessMission(bool bTacticalMissionSuccess, bool bStrategyMissionSuccess, bool bTriadMissionSuccess, out TSimCombatSummaryData SummaryData)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionState;
	local XComGameState_Item ItemState;
	local XComGameState_Reward RewardStateObject;
	local XComGameState_Unit RewardUnitState;
	local int Index;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SimCombat: Process Mission");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleData.m_iMissionID == MissionState.ObjectID);
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	XComHQ.bReturningFromMission = true;
	XComHQ.bSimCombatVictory = bStrategyMissionSuccess;
	SummaryData.bMissionSuccess = bStrategyMissionSuccess;

	class'X2StrategyElement_DefaultMissionSources'.static.IncreaseForceLevel(NewGameState, MissionState);

	if (bStrategyMissionSuccess)
	{
		// Give Quest Item if there is one and strategy success
		if(MissionState.GeneratedMission.MissionQuestItemTemplate != '')
		{
			ItemState = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(
				MissionState.GeneratedMission.MissionQuestItemTemplate).CreateInstanceFromTemplate(NewGameState);

			XComHQ.PutItemInInventory(NewGameState, ItemState, true);
		}

		//Add any reward personnel to the battlefield
		for( Index = 0; Index < MissionState.Rewards.Length; ++Index )
		{
			RewardStateObject = XComGameState_Reward(History.GetGameStateForObjectID(MissionState.Rewards[Index].ObjectID));
			if(MissionState.IsVIPMission() && XComGameState_Unit(History.GetGameStateForObjectID(RewardStateObject.RewardObjectReference.ObjectID)) != none)
			{
				//Add the reward unit to the battle
				RewardUnitState = XComGameState_Unit( NewGameState.ModifyStateObject(class'XComGameState_Unit', RewardStateObject.RewardObjectReference.ObjectID) );
				`assert(RewardUnitState != none);
				RewardUnitState.SetControllingPlayer( BattleData.CivilianPlayerRef );

				//Track which units the battle is considering to be rewards ( used later when spawning objectives )
				BattleData.RewardUnits.AddItem(RewardStateObject.RewardObjectReference);
			}
		}
	}

	// update the mission objectives' success or failure to match the desired outcome
	for( Index = 0; Index < BattleData.MapData.ActiveMission.MissionObjectives.Length; ++Index )
	{
		if( BattleData.MapData.ActiveMission.MissionObjectives[Index].bIsTacticalObjective )
		{
			BattleData.MapData.ActiveMission.MissionObjectives[Index].bCompleted = bTacticalMissionSuccess;
		}

		if( BattleData.MapData.ActiveMission.MissionObjectives[Index].bIsStrategyObjective )
		{
			BattleData.MapData.ActiveMission.MissionObjectives[Index].bCompleted = bStrategyMissionSuccess;
		}

		if( BattleData.MapData.ActiveMission.MissionObjectives[Index].bIsTriadObjective )
		{
			BattleData.MapData.ActiveMission.MissionObjectives[Index].bCompleted = bTriadMissionSuccess;
		}
	}

	if(MissionState.GetMissionSource().WasMissionSuccessfulFn != none)
	{
		BattleData.bLocalPlayerWon = MissionState.GetMissionSource().WasMissionSuccessfulFn(BattleData);
	}
	else
	{
		BattleData.bLocalPlayerWon = BattleData.OneStrategyObjectiveCompleted();
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	class'X2TacticalGameRuleset'.static.CleanupTacticalMission(true);
	class'XComGameStateContext_StrategyGameRule'.static.ProcessMissionResults();
}

//#############################################################################################
//----------------   LOOT   -------------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function DetermineLoot(array<StateObjectReference> Enemies)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemMgr;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> ActiveUnits, EnemyStates;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> LootItems;
	local int idx, iSquad, iItem;
	local bool bLootSuccess;
	local XComAISpawnManager SpawnManager;
	local XComTacticalMissionManager TacticalMissionManager;
	local MissionSchedule SelectedMissionSchedule;
	local XComGameState_MissionSite MissionState;
	local XComGameState_BattleData BattleData;

	SpawnManager = `SPAWNMGR;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SimCombat: Determine Loot");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	// Grab the active units
	for(iSquad = 0; iSquad < XComHQ.Squad.Length; iSquad++)
	{
		if(XComHQ.Squad[iSquad].ObjectID != 0)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', XComHQ.Squad[iSquad].ObjectID));
			ActiveUnits.AddItem(UnitState);
		}
	}

	// Grab Highest ranking Alien and Advent from enemy list
	for(idx = 0; idx < Enemies.Length; idx++)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Enemies[idx].ObjectID));
		EnemyStates.AddItem(UnitState);
	}
	
	// roll for timed loot
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', XComHQ.MissionRef.ObjectID));

	if( MissionState.SelectedMissionData.SelectedMissionScheduleName == '' )
	{
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		MissionState.CacheSelectedMissionData(BattleData.GetForceLevel(), BattleData.GetAlertLevel());
	}

	TacticalMissionManager = `TACTICALMISSIONMGR;
	TacticalMissionManager.GetMissionSchedule(MissionState.SelectedMissionData.SelectedMissionScheduleName, SelectedMissionSchedule);
	SpawnManager.RollForTimedLoot(EnemyStates, XComHQ, SelectedMissionSchedule);

	// create the timed loot
	for( idx = 0; idx < EnemyStates.Length; idx++ )
	{
		UnitState = EnemyStates[idx];

		if( UnitState != none && UnitState.PendingLoot.LootToBeCreated.Length != 0 )
		{
			for( iItem = 0; iItem < UnitState.PendingLoot.LootToBeCreated.Length; iItem++ )
			{
				ItemState = ItemMgr.FindItemTemplate(UnitState.PendingLoot.LootToBeCreated[iItem]).CreateInstanceFromTemplate(NewGameState);
				LootItems.AddItem(ItemState);
			}
		}
	}

	// Distribute the loot to active units
	for(iItem = 0; iItem < LootItems.Length; iItem++)
	{
		bLootSuccess = false;
		ItemState = LootItems[iItem];

		for(iSquad = 0; iSquad < ActiveUnits.Length; iSquad++)
		{
			UnitState = ActiveUnits[iSquad];
			//start issue #114: pass along item state for mod purposes
			if(!UnitState.IsDead() && UnitState.HasBackpack() &&
			   UnitState.CanAddItemToInventory(ItemState.GetMyTemplate(), eInvSlot_Backpack, NewGameState, ItemState.Quantity, ItemState))
			{
				UnitState.AddItemToInventory(ItemState, eInvSlot_BackPack, NewGameState);
				bLootSuccess = true;
				break;
			}
			//end issue #114
		}
		
		if(!bLootSuccess)
		{
			NewGameState.PurgeGameStateForObjectID(ItemState.ObjectID);
		}
	}

	// Create the loot from dead bodies
	for(idx = 0; idx < EnemyStates.Length; idx++)
	{
		EnemyStates[idx].RollForAutoLoot(NewGameState);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//---------------------------------------------------------------------------------------
static function array<StateObjectReference> GetEnemiesOnMission()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local array<PodSpawnInfo> MissionPods;
	local XComGameState_Unit UnitState;
	local X2CharacterTemplate CharacterTemplate;
	local array<StateObjectReference> Enemies;
	local int idx, i;
	local Name CharTemplateName;
	local X2CharacterTemplateManager CharTemplateManager;

	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SimCombat: Create Enemies");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	// Grab all pods on the mission
	for(idx = 0; idx < MissionState.SelectedMissionData.SelectedEncounters.Length; idx++)
	{
		MissionPods.AddItem(MissionState.SelectedMissionData.SelectedEncounters[idx].EncounterSpawnInfo);
	}

	for(idx = 0; idx < MissionPods.Length; idx++)
	{
		for(i = 0; i < MissionPods[idx].SelectedCharacterTemplateNames.Length; i++)
		{
			CharTemplateName = MissionPods[idx].SelectedCharacterTemplateNames[i];
			CharacterTemplate = CharTemplateManager.FindCharacterTemplate(CharTemplateName);

			if(CharacterTemplate != none)
			{
				UnitState = CharacterTemplate.CreateInstanceFromTemplate(NewGameState);
				Enemies.AddItem(UnitState.GetReference());
			}
		}
	}

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return Enemies;
}

//---------------------------------------------------------------------------------------
private static function int SortEnemies(X2CharacterTemplate CharTemplateA, X2CharacterTemplate CharTemplateB)
{
	return (Round(CharTemplateA.XpKillscore - CharTemplateB.XpKillscore));
}


//#############################################################################################
//----------------   KILLS AND XP   -----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function DetermineKillsAndXP(array<StateObjectReference> Enemies)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Unit UnitState, EnemyState;
	local array<StateObjectReference> ActiveSoldiers, EnemyList;
	local int idx, i, RandIndex, XPToAdd, XPVariance, KillsPerSoldier, LeftOverKills;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SimCombat: Determine Kills and XP");

	for(idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		if(XComHQ.Squad[idx].ObjectID != 0)
		{
			ActiveSoldiers.AddItem(XComHQ.Squad[idx]);
		}
	}

	EnemyList = Enemies;
	KillsPerSoldier = EnemyList.Length / ActiveSoldiers.Length;
	LeftOverKills = EnemyList.Length - (KillsPerSoldier * ActiveSoldiers.Length);

	// Spread out kills
	for(idx = 0; idx < ActiveSoldiers.Length; idx++)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ActiveSoldiers[idx].ObjectID));

		for(i = 0; i < KillsPerSoldier; i++)
		{
			RandIndex = `SYNC_RAND_STATIC(EnemyList.Length);
			EnemyState = XComGameState_Unit(History.GetGameStateForObjectID(EnemyList[RandIndex].ObjectID));

			if(EnemyState != none)
			{
				UnitState.SimGetKill(EnemyState.GetReference());
				UnitState.bRankedUp = false;
				UnitState.AddXp(EnemyState.GetDirectXpAmount());
			}

			EnemyList.Remove(RandIndex, 1);
		}
	}

	// Randomnly assign rest of kills
	while(LeftOverKills > 0)
	{
		idx = `SYNC_RAND_STATIC(ActiveSoldiers.Length);
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ActiveSoldiers[idx].ObjectID));

		RandIndex = `SYNC_RAND_STATIC(EnemyList.Length);
		EnemyState = XComGameState_Unit(History.GetGameStateForObjectID(EnemyList[RandIndex].ObjectID));

		if(EnemyState != none)
		{
			UnitState.SimGetKill(EnemyState.GetReference());
			UnitState.AddXp(EnemyState.GetDirectXpAmount());
		}

		EnemyList.Remove(RandIndex, 1);
		LeftOverKills--;
	}

	// Give some bonus XP
	for(idx = 0; idx < ActiveSoldiers.Length; idx++)
	{
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ActiveSoldiers[idx].ObjectID));

		XPToAdd = default.ForceLevelXP[AlienHQ.GetForceLevel()];
		XPVariance = Round(float(default.XPPercentVariance)*`SYNC_FRAND_STATIC() / 100.0*float(XPToAdd));

		if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
		{
			XPToAdd -= XPVariance;
		}
		else
		{
			XPToAdd += XPVariance;
		}

		UnitState.AddXp(XPToAdd);
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//#############################################################################################
//----------------   XCOM POWER   -------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function float GetSquadPowerLevel()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local float SquadPower;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SquadPower = 0;

	// Sum of power of all soldiers
	for(idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

		if(UnitState != none)
		{
			SquadPower += GetSoldierPowerLevel(UnitState);
		}
	}

	return SquadPower;
}

//---------------------------------------------------------------------------------------
static function float GetSoldierPowerLevel(XComGameState_Unit UnitState)
{
	// Rank multiplier x gear power level
	return (default.RankMultipliers[UnitState.GetRank()] * GetGearPowerLevel(UnitState));
}

//---------------------------------------------------------------------------------------
static function float GetGearPowerLevel(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local float GearPower;
	local int idx;

	History = `XCOMHISTORY;
	GearPower = 0;

	// Sum of power of all items
	for(idx = 0; idx < UnitState.InventoryItems.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(UnitState.InventoryItems[idx].ObjectID));

		if(ItemState != none)
		{
			GearPower += GetItemPowerLevel(ItemState);
		}
	}

	return GearPower;
}

//---------------------------------------------------------------------------------------
static function float GetItemPowerLevel(XComGameState_Item ItemState)
{
	local X2TechTemplate TechTemplate;
	local float ItemPower;
	local int idx;

	if(IsExcludedItem(ItemState.GetMyTemplateName()))
	{
		return 0;
	}

	ItemPower = default.BaseItemPower;

	// Modified items get a bonus
	if(ItemState.HasBeenModified())
	{
		ItemPower += default.ModifiedItemPower;
	}

	// Add power for each tech required to unlock item + "tier" tech bonuses
	for(idx = 0; idx < ItemState.GetMyTemplate().Requirements.RequiredTechs.Length; idx++)
	{
		TechTemplate = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager()
						.FindStrategyElementTemplate(ItemState.GetMyTemplate().Requirements.RequiredTechs[idx]));

		if(TechTemplate != none)
		{
			ItemPower += GetTechTemplatePower(TechTemplate);
		}
	}

	return ItemPower;
}

//---------------------------------------------------------------------------------------
static function bool IsExcludedItem(name ItemName)
{
	return (default.ExcludedItems.Find(ItemName) != INDEX_NONE);
}

//---------------------------------------------------------------------------------------
static function float GetTechTemplatePower(X2TechTemplate TechTemplate)
{
	local X2TechTemplate PrereqTechTemplate;
	local float TechPower;
	local int idx;

	TechPower = default.PowerPerItemTech;

	// bonus for "tier" tech
	if(IsTierTech(TechTemplate.DataName))
	{
		TechPower += default.ItemPowerTierBonus;
	}

	for(idx = 0; idx < TechTemplate.Requirements.RequiredTechs.Length; idx++)
	{
		PrereqTechTemplate = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager()
											.FindStrategyElementTemplate(TechTemplate.Requirements.RequiredTechs[idx]));

		if(PrereqTechTemplate != none)
		{
			TechPower += GetTechTemplatePower(PrereqTechTemplate);
		}
	}

	return TechPower;
}

//---------------------------------------------------------------------------------------
static function bool IsTierTech(name TechName)
{
	return (default.TierTechs.Find(TechName) != INDEX_NONE);
}

//#############################################################################################
//----------------   ALIEN POWER   ------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function float GetAlienPowerLevel()
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	return (default.ForceLevelPowers[AlienHQ.GetForceLevel()] * GetAlertLevelPower(MissionState));
}

//---------------------------------------------------------------------------------------
static function float GetAlertLevelPower(XComGameState_MissionSite MissionState)
{
	return default.AlertLevelMultipliers[MissionState.GetMissionDifficulty()];
}

//---------------------------------------------------------------------------------------
static function CompleteTacticalGoldenPathObjectives()
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;
	local X2EventManager EventManager;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local Name ItemToAward;
	local XComGameState_Item ItemState;
	local X2ItemTemplateManager ItemMgr;
	local X2ItemTemplate ItemTemplate;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	History = `XCOMHISTORY;
	EventManager = `XEVENTMGR;

	// for each currently active tactical objective, trigger events as though they had been completed
	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if( ObjectiveState.ShouldCompleteWithSimCombat() )
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strategy: SimCombat: Objective Completion: " $ ObjectiveState.GetMyTemplate().CompletionEvent);
			EventManager.TriggerEvent(ObjectiveState.GetMyTemplate().CompletionEvent, , , NewGameState);

			ItemToAward = ObjectiveState.GetMyTemplate().SimCombatItemReward;
			
			if( ItemToAward != '' )
			{
				XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				ItemTemplate = ItemMgr.FindItemTemplate(ItemToAward);
				if( ItemTemplate != none )
				{
					ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
					ItemState.Quantity = 1;
					XComHQ.PutItemInInventory(NewGameState, ItemState);
				}
			}

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			// check for any other tactical objectives that are in progress after this one completes
			CompleteTacticalGoldenPathObjectives();
			break;
		}
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}
