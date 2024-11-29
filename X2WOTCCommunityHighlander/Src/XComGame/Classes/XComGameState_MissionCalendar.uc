//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MissionCalendar.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_MissionCalendar extends XComGameState_BaseObject config(GameData);

var array<MissionCalendarDate>			CurrentMissionMonth;
var TDateTime							MonthEndTime;
var float								RetaliationSpawnTimeDecrease;
var name								CurrentMissionDeckName;
var array<RandomMissionDeck>			CurrentRandomMissionDecks;

// Reward Decks
var array<MissionRewardDeck>			MissionRewardDecks;
var array<MissionRewardDeck>			MissionRewardExcludeDecks;

// Created Missions
var array<name>							CreatedMissionSources;

// Popup Flags
var array<name>							MissionPopupSources;

var config int							MissionSpawnVariance; // Hours
var config array<name>					StartingMissionDeck;
var config name							EndGameMissionDeck;
var config name							BlankMissionName;
var config array<MissionDeck>			MissionDecks;  // Schedule of mission sources for each month
var config array<RandomMissionDeck>		RandomMissionDecks; // Some entries in the mission schedule will call for a random mission


// #######################################################################################
// -------------------- INITIALIZATION ---------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
static function SetupCalendar(XComGameState StartState)
{
	local XComGameState_MissionCalendar CalendarState;

	CalendarState = XComGameState_MissionCalendar(StartState.CreateNewStateObject(class'XComGameState_MissionCalendar'));

	CalendarState.OnEndOfMonth(StartState);
}

// #######################################################################################
// -------------------- UPDATE -----------------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function bool Update(XComGameState NewGameState)
{
	local UIStrategyMap StrategyMap;
	local int idx;

	StrategyMap = `HQPRES.StrategyMap2D;

	// Do not spawn any new missions while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		// Check for mission events
		for (idx = 0; idx < CurrentMissionMonth.Length; idx++)
		{
			if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(CurrentMissionMonth[idx].SpawnDate, `STRATEGYRULES.GameTime))
			{
				SpawnMissions(NewGameState, idx);
				CurrentMissionMonth.Remove(idx, 1);
				return true;
			}
		}

		// Check for end of month
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(MonthEndTime, `STRATEGYRULES.GameTime))
		{
			OnEndOfMonth(NewGameState);
			return true;
		}
	}
	
	return false;
}

//---------------------------------------------------------------------------------------
function bool HasCreatedMissionOfSource(name MissionSourceName)
{
	return (CreatedMissionSources.Find(MissionSourceName) != INDEX_NONE);
}

//---------------------------------------------------------------------------------------
function bool HasCreatedMultipleMissionsOfSource(name MissionSourceName)
{
	local name CreatedMissionName;
	local bool bFoundOneMission;

	foreach CreatedMissionSources(CreatedMissionName)
	{		
		if (!bFoundOneMission && CreatedMissionName == MissionSourceName)
		{
			// If the first instance of the mission has not been found yet, flag one as found
			bFoundOneMission = true;
		}
		else if(CreatedMissionName == MissionSourceName)
		{
			// If one match was found, and we just found another, there are multiple missions, so return true
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function int GetNumTimesMissionSourceCreated(name MissionSourceName)
{
	local name CreatedMissionName;
	local int Count;

	Count = 0;

	foreach CreatedMissionSources(CreatedMissionName)
	{
		if(CreatedMissionName == MissionSourceName)
		{
			Count++;
		}
	}

	return Count;
}

//---------------------------------------------------------------------------------------
function OnEndOfMonth(XComGameState NewGameState)
{
	local MissionCalendarDate MissionDate;
	local TDateTime CurrentTime;
	local MissionDeck CurrentMissionDeck;
	local array<name> ExcludeMissions;
	local name DeckName, LastMission, LastRandomMission;
	local int MonthHours, SpawnInterval, HoursToAdd, idx;
	local XComGameState_HeadquartersResistance ResHQ;
	local bool bStartCalendar;

	// Grab current datetime
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	bStartCalendar = false;

	// Select Mission Deck
	if(CurrentMissionDeckName == '')
	{
		CurrentMissionDeckName = GetStartingMissionDeck();
		bStartCalendar = true;
	}
	else
	{
		if(GetMissionDeckByName(CurrentMissionDeckName, CurrentMissionDeck))
		{
			DeckName = CurrentMissionDeck.NextDeckName;

			if(GetMissionDeckByName(DeckName, CurrentMissionDeck))
			{
				CurrentMissionDeckName = DeckName;
			}
		}
	}

	if(!GetMissionDeckByName(CurrentMissionDeckName, CurrentMissionDeck))
	{
		`RedScreen("Could not find a valid mission deck for calendar. @Gameplay @mnauta");
	}

	// Schedule end of month
	if(!bStartCalendar)
	{
		// Don't adjust in the end game
		if(!class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T5_M1_AutopsyTheAvatar'))
		{
			// Readjust time down to start of ResHQ month
			ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

			if(class'X2StrategyGameRulesetDataStructures'.static.LessThan(ResHQ.MonthIntervalEndTime, CurrentTime))
			{
				CurrentTime = ResHQ.MonthIntervalStartTime;
			}
		}
	}

	MonthEndTime = CurrentTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(MonthEndTime, CurrentMissionDeck.MissionMonthDays);

	// Clear mission month
	CurrentMissionMonth.Length = 0;

	// Find default spawn interval, Month length/num of mission events
	MonthHours = CurrentMissionDeck.MissionMonthDays * 24;
	SpawnInterval = MonthHours / CurrentMissionDeck.Missions.Length;

	// Plot mission events across the month
	LastMission = '';
	LastRandomMission = '';
	for(idx = 0; idx < CurrentMissionDeck.Missions.Length; idx++)
	{
		if(CurrentMissionDeck.Missions[idx].MissionSource != '')
		{
			MissionDate.MissionSource = CurrentMissionDeck.Missions[idx].MissionSource;
		}
		else if(CurrentMissionDeck.Missions[idx].RandomDeckName != '')
		{
			ExcludeMissions.Length = 0;

			if(LastRandomMission != '')
			{
				ExcludeMissions.AddItem(LastRandomMission);
			}

			if(CurrentMissionDeck.bForceNoConsecutive)
			{
				if(LastMission != '' && LastMission != LastRandomMission)
				{
					ExcludeMissions.AddItem(LastMission);
				}

			}

			MissionDate.MissionSource = GetNextRandomMission(CurrentMissionDeck.Missions[idx].RandomDeckName, ExcludeMissions);
		}
		else
		{
			`RedScreen("Bad entry in mission deck for calendar. @Gameplay @mnauta");
		}
		
		MissionDate.SpawnDate = CurrentTime;

		HoursToAdd = SpawnInterval * (idx + 1);
		HoursToAdd -= `SYNC_RAND(default.MissionSpawnVariance);
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(MissionDate.SpawnDate, HoursToAdd);

		CurrentMissionMonth.AddItem(MissionDate);
		LastMission = MissionDate.MissionSource;
	}

	CreateMissions(NewGameState);

	if(bStartCalendar && !(XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings')).bXPackNarrativeEnabled))
	{
		MoveFirstRetaliation();
	}
}

//---------------------------------------------------------------------------------------
private function MoveFirstRetaliation()
{
	local XComGameState_HeadquartersResistance ResHQ;
	local TDateTime NewTime;
	local int idx;

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	NewTime = ResHQ.MonthIntervalEndTime;

	// Ensure the mission appears more than the max mission expire time before the first resistance report
	class'X2StrategyGameRulesetDataStructures'.static.RemoveHours(NewTime, (class'X2StrategyElement_DefaultMissionSources'.default.MissionMaxDuration + `SYNC_RAND(10) + 1));

	for(idx = 0; idx < CurrentMissionMonth.Length; idx++)
	{
		if(CurrentMissionMonth[idx].MissionSource == 'MissionSource_Retaliation')
		{
			CurrentMissionMonth[idx].SpawnDate = NewTime;
			break;
		}
	}
}

//---------------------------------------------------------------------------------------
// From config
function bool GetMissionDeckByName(name DeckName, out MissionDeck FoundDeck)
{
	local int idx;

	for(idx = 0; idx < default.MissionDecks.Length; idx++)
	{
		if(default.MissionDecks[idx].DeckName == DeckName)
		{
			FoundDeck = default.MissionDecks[idx];
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// From config
function bool GetNextMissionDeck(out MissionDeck FoundDeck)
{
	local MissionDeck CurrentMissionDeck;

	if(GetMissionDeckByName(CurrentMissionDeckName, CurrentMissionDeck))
	{
		if(GetMissionDeckByName(CurrentMissionDeck.NextDeckName, FoundDeck))
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// From config
function bool GetRandomMissionDeckByName(name DeckName, out RandomMissionDeck FoundDeck)
{
	local int idx;

	for(idx = 0; idx < default.RandomMissionDecks.Length; idx++)
	{
		if(default.RandomMissionDecks[idx].DeckName == DeckName)
		{
			FoundDeck = default.RandomMissionDecks[idx];
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function name GetNextRandomMission(name DeckName, optional array<name> ExcludeMissions)
{
	local name MissionName;
	local int Index, MissionIndex, idx;
	local array<name> Missions;

	Index = CurrentRandomMissionDecks.Find('DeckName', DeckName);

	if(Index == INDEX_NONE)
	{
		AddRandomMissionDeck(DeckName);
	}
	else if(CurrentRandomMissionDecks[Index].Missions.Length == 0 || (ExcludeMissions.Length != 0 && NeedToExtendRandomMissionDeck(CurrentRandomMissionDecks[Index], ExcludeMissions)))
	{
		AddRandomMissionDeck(DeckName);
	}

	Index = CurrentRandomMissionDecks.Find('DeckName', DeckName);
	Missions = CurrentRandomMissionDecks[Index].Missions;
	
	if(ExcludeMissions.Length != 0)
	{
		for(idx = 0; idx < Missions.Length; idx++)
		{
			if(ExcludeMissions.Find(Missions[idx]) != INDEX_NONE)
			{
				Missions.Remove(idx, 1);
				idx--;
			}
		}
	}

	if(Missions.Length == 0)
	{
		`RedScreen("Problem in getting random mission for calendar. @Gameplay @mnauta");
	}

	MissionName = Missions[`SYNC_RAND(Missions.Length)];
	MissionIndex = CurrentRandomMissionDecks[Index].Missions.Find(MissionName);
	CurrentRandomMissionDecks[Index].Missions.Remove(MissionIndex, 1);

	return MissionName;
}

//---------------------------------------------------------------------------------------
function AddRandomMissionDeck(name DeckName)
{
	local RandomMissionDeck FoundDeck;
	local int Index, idx;

	Index = CurrentRandomMissionDecks.Find('DeckName', DeckName);

	if(Index == INDEX_NONE)
	{
		if(GetRandomMissionDeckByName(DeckName, FoundDeck))
		{
			CurrentRandomMissionDecks.AddItem(FoundDeck);
		}
		else
		{
			`RedScreen("Problem in getting random mission for calendar. @Gameplay @mnauta");
		}
		
	}
	else if(CurrentRandomMissionDecks[Index].Missions.Length == 0)
	{
		if(GetRandomMissionDeckByName(DeckName, FoundDeck))
		{
			CurrentRandomMissionDecks[Index].Missions = FoundDeck.Missions;
		}
		else
		{
			`RedScreen("Problem in getting random mission for calendar. @Gameplay @mnauta");
		}
	}
	else
	{
		if(GetRandomMissionDeckByName(DeckName, FoundDeck))
		{
			for(idx = 0; idx < FoundDeck.Missions.Length; idx++)
			{
				CurrentRandomMissionDecks[Index].Missions.AddItem(FoundDeck.Missions[idx]);
			}
		}
		else
		{
			`RedScreen("Problem in getting random mission for calendar. @Gameplay @mnauta");
		}
	}
}

//---------------------------------------------------------------------------------------
function bool NeedToExtendRandomMissionDeck(RandomMissionDeck RandomDeck, array<name> ExcludeMissions)
{
	local int idx;

	for(idx = 0; idx < RandomDeck.Missions.Length; idx++)
	{
		if(ExcludeMissions.Find(RandomDeck.Missions[idx]) == INDEX_NONE)
		{
			return false;
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool GetNextDateForMissionSource(name MissionSourceName, out TDateTime MissionDateTime)
{
	local array<MissionCalendarDate> NextMissionMonth;
	local int Index;

	Index = CurrentMissionMonth.Find('MissionSource', MissionSourceName);

	if(Index != INDEX_NONE)
	{
		MissionDateTime = CurrentMissionMonth[Index].SpawnDate;
		return true;
	}

	NextMissionMonth = GetNextProjectedMissionMonth();

	Index = NextMissionMonth.Find('MissionSource', MissionSourceName);

	if(Index != INDEX_NONE)
	{
		MissionDateTime = NextMissionMonth[Index].SpawnDate;

		// Retaliation Spawn time decrease var is only used if next retaliation mission is in next mission month
		if(MissionSourceName == 'MissionSource_Retaliation')
		{
			class'X2StrategyGameRulesetDataStructures'.static.RemoveTime(MissionDateTime, RetaliationSpawnTimeDecrease);
		}

		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
// Random spots are will have empty mission source name
function array<MissionCalendarDate> GetNextProjectedMissionMonth()
{
	local MissionDeck NextMissionDeck;
	local array<MissionCalendarDate> NextMissionMonth;
	local MissionCalendarDate MissionDate;
	local TDateTime NextMonthEndTime;
	local int MonthHours, SpawnInterval, HoursToAdd, idx;

	// Get Next Mission Deck
	if(!GetNextMissionDeck(NextMissionDeck))
	{
		`RedScreen("Problem in finding next mission deck for calendar. @Gameplay @mnauta");
	}

	// Schedule end of next month
	NextMonthEndTime = MonthEndTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(NextMonthEndTime, NextMissionDeck.MissionMonthDays);

	// Find default spawn interval, Month length/num of mission events
	MonthHours = NextMissionDeck.MissionMonthDays * 24;
	SpawnInterval = MonthHours / NextMissionDeck.Missions.Length;

	// Plot mission events across the month
	for(idx = 0; idx < NextMissionDeck.Missions.Length; idx++)
	{
		MissionDate.MissionSource = NextMissionDeck.Missions[idx].MissionSource;
		MissionDate.SpawnDate = MonthEndTime;

		HoursToAdd = SpawnInterval * (idx + 1);
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(MissionDate.SpawnDate, HoursToAdd);

		NextMissionMonth.AddItem(MissionDate);
	}

	return NextMissionMonth;
}

//---------------------------------------------------------------------------------------
function name GetNextMissionSource()
{
	local array<MissionCalendarDate> NextMissionMonth;

	if (CurrentMissionMonth.Length > 0)
	{
		return CurrentMissionMonth[0].MissionSource;
	}
	else
	{
		NextMissionMonth = GetNextProjectedMissionMonth();
		return NextMissionMonth[0].MissionSource;
	}
}

//---------------------------------------------------------------------------------------
function X2MissionSourceTemplate GetNextMissionSourceTemplate()
{
	local X2StrategyElementTemplateManager StratMgr;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	return X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate(GetNextMissionSource()));
}

//---------------------------------------------------------------------------------------
function TDateTime GetBestNewMissionDateBetweenMissions(int NumMissionsToCheck)
{
	local array<MissionCalendarDate> DatesToCheck, NextMissionMonth;
	local TDateTime BestTimeFrameStart;
	local int idx, TimeFrameLength, BestTimeFrameLength, NumMissionsToAdd;

	DatesToCheck = CurrentMissionMonth;
	if (DatesToCheck.Length < (NumMissionsToCheck + 1))
	{
		NextMissionMonth = GetNextProjectedMissionMonth();
		
		// Add projected mission dates to our list until we have the required number
		NumMissionsToAdd = NumMissionsToCheck - DatesToCheck.Length;
		while (idx < NumMissionsToAdd)
		{
			DatesToCheck.AddItem(NextMissionMonth[idx]);
			idx++;
		}
	}

	if (NumMissionsToCheck == 0)
	{
		BestTimeFrameLength = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(DatesToCheck[0].SpawnDate, `STRATEGYRULES.GameTime);
		BestTimeFrameStart = `STRATEGYRULES.GameTime;
	}
	else
	{
		for (idx = 1; idx <= NumMissionsToCheck; idx++)
		{
			TimeFrameLength = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(DatesToCheck[idx].SpawnDate, DatesToCheck[idx - 1].SpawnDate);
			if (TimeFrameLength > BestTimeFrameLength)
			{
				BestTimeFrameLength = TimeFrameLength;
				BestTimeFrameStart = DatesToCheck[idx - 1].SpawnDate;
			}
		}
	}
	
	// Add half of the best time frame length, so the new mission will appear halfway between the two longest-separated missions
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(BestTimeFrameStart, BestTimeFrameLength / 2);
	
	return BestTimeFrameStart;
}

function SwitchToEndGameMissions(XComGameState NewGameState)
{
	CurrentMissionDeckName = default.EndGameMissionDeck;

	OnEndOfMonth(NewGameState); // Clear the current month and generate a new one
}

// #######################################################################################
// -------------------- MISSION GENERATION -----------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function CreateMissions(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for(idx = 0; idx < CurrentMissionMonth.Length; idx++)
	{
		if(CurrentMissionMonth[idx].MissionSource != default.BlankMissionName)
		{
			MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate(CurrentMissionMonth[idx].MissionSource));

			if(MissionSource != none && MissionSource.CreateMissionsFn != none)
			{
				MissionSource.CreateMissionsFn(NewGameState, idx);
			}
		}
	}
}



// #######################################################################################
// -------------------- MISSION SPAWNING -------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function SpawnMissions(XComGameState NewGameState, int MissionMonthIndex)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;

	if(CurrentMissionMonth[MissionMonthIndex].MissionSource != default.BlankMissionName)
	{
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate(CurrentMissionMonth[MissionMonthIndex].MissionSource));

		if(MissionSource != none && MissionSource.SpawnMissionsFn != none)
		{
			MissionSource.SpawnMissionsFn(NewGameState, MissionMonthIndex);
		}
	}
}

// #######################################################################################
// -------------------- DIFFICULTY HELPERS -----------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function name GetStartingMissionDeck()
{
	return default.StartingMissionDeck[`StrategyDifficultySetting];
}

//---------------------------------------------------------------------------------------
DefaultProperties
{

}
