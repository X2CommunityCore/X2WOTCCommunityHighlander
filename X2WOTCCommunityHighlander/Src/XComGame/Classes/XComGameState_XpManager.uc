class XComGameState_XpManager extends XComGameState_BaseObject	
	dependson(X2ExperienceConfig)
	native(Core);

struct native UnitXpShare
{
	var() StateObjectReference UnitRef;
	var() float Shares;

	structcpptext
	{
		FUnitXpShare()
		{
			appMemzero(this, sizeof(FUnitXpShare));
		}
		FUnitXpShare(EEventParm)
		{
			appMemzero(this, sizeof(FUnitXpShare));
		}

		FORCEINLINE UBOOL operator==(const FUnitXpShare &Other) const
		{
			return UnitRef == Other.UnitRef;
		}
	}
};

struct native XpEventCount
{
	var() StateObjectReference ObjRef;
	var() int Count;

	structcpptext
	{
		FXpEventCount()
		{
			appMemzero(this, sizeof(FXpEventCount));
		}
		FXpEventCount(EEventParm)
		{
			appMemzero(this, sizeof(FXpEventCount));
		}

		FORCEINLINE UBOOL operator==(const FXpEventCount &Other) const
		{
			return ObjRef == Other.ObjRef;
		}
	}
};

struct native TrackedXpEvent
{
	var() name      EventID;
	var() int       GlobalCount;
	var() array<XpEventCount>   UnitCounts;
	var() array<XpEventCount>   TargetCounts;

	structcpptext
	{
		FTrackedXpEvent()
		{
			appMemzero(this, sizeof(FTrackedXpEvent));
		}
		FTrackedXpEvent(EEventParm)
		{
			appMemzero(this, sizeof(FTrackedXpEvent));
		}

		FORCEINLINE UBOOL operator==(const FTrackedXpEvent &Other) const
		{
			return EventID == Other.EventID;
		}
	}
};

var() protected float                    MissionTotalXpCap;          //  Calculated inside of Init
var() protected float                    MissionKillXpCap;           //  Calculated inside of Init
var() protectedwrite float               EarnedPool;                 //  Actual amount earned during the mission
var() protected float                    EarnedKillPool;             //  Amount of EarnedPool that comes from kill xp, capped separately by MissionKillXpCap
var() protectedwrite float               SquadXpShares;              //  Shares to be given to the entire squad at mission end
var() protectedwrite array<UnitXpShare>  UnitXpShares;               //  Shares per unit to be distributed at mission end
var() protectedwrite array<TrackedXpEvent> TrackedXpEvents;          //  Tracks various limits for certain events
var() protected StateObjectReference     BattleRef;

native function Init(XComGameState_BattleData BattleData);
native protected function bool ProcessXpEvent(name XpEvent, XpEventData EventData);
native protected function EventListenerReturn XpEventResponse(name XpEvent, XpEventData EventData, XComGameState GameState, Name EventID, Object CallbackData);

function DistributeTacticalGameEndXp(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<int> Survivors;
	local int TotalXp, EarnedXp, SurvivorIdx, ShareIdx, ExcessXp, TotalExcess;
	local float TotalShares, CurrentShares, KillBonus;
	local XpEventData NewEventData;
	local StateObjectReference NewEventRef, UnitRef;
	local XComGameState_BattleData BattleState;
	local array<XComGameState_Unit> UnrankedUnits;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Player XComPlayer;
	local bool bKillXpBonus;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	`log("===" @ GetFuncName() @ "===",,'XComXpMan');

	//  If the full xp system is not enabled, just reset the RankedUp flag.
	if (!class'X2ExperienceConfig'.default.bUseFullXpSystem)
	{
		`log("FullXpSystem is disabled, skipping Xp distribution.",,'XComXpMan');

		foreach XComHQ.Squad(UnitRef)
		{
			if(UnitRef.ObjectID != 0)
			{
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
				UnitState.bRankedUp = false;
			}
		}

		return;
	}

	BattleState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleState.m_iMissionID == XComHQ.MissionRef.ObjectID);

	XComPlayer = GetXComPlayer(NewGameState);
	bKillXpBonus = false;
	if(XComPlayer != none)
	{
		bKillXpBonus = XComPlayer.SoldierUnlockTemplates.Find('WetWorkUnlock') != INDEX_NONE;
	}
	
	EarnedKillPool = min(EarnedKillPool, MissionKillXpCap);         //  make sure kill pool is capped properly	
	`log("MissionTotalXpCap:" @ MissionTotalXpCap,,'XComXpMan');
	`log("MissionKillXpCap:" @ MissionKillXpCap,,'XComXpMan');
	`log("EarnedPool:" @ EarnedPool,,'XComXpMan');
	`log("EarnedKillPool:" @ EarnedKillPool,,'XComXpMan');

	if (bKillXpBonus)
	{
		KillBonus = EarnedKillPool * class'X2ExperienceConfig'.default.KillXpBonusMult;
		`log("Kill XP Bonus unlock adding bonus xp:" @ KillBonus,,'XComXpMan');
		EarnedPool += KillBonus;
		`log("New EarnedPool:" @ EarnedPool,,'XComXpMan');
	}

	foreach XComHQ.Squad(UnitRef)
	{
		if (UnitRef.ObjectID > 0)
		{
			UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitRef.ObjectID));
			if (UnitState == none)
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			`assert(UnitState != none);
			if (UnitState.IsAlive() && UnitState.bRemovedFromPlay)          //  must be alive and and evac'd
			{
				if (NewEventRef.ObjectID == 0)
					NewEventRef = UnitRef;

				`log("Found survivor:" @ UnitState.ToString(), , 'XComXpMan');
				Survivors.AddItem(UnitState.ObjectID);
			}
		}
	}

	if (Survivors.Length == 0)
	{
		`log("No survivors!",,'XComXpMan');
		return;
	}

	if (BattleState.m_bIsFirstMission)
	{
		`log("Adding first mission bonus.",,'XComXpMan');
		NewEventData = class'XpEventData'.static.NewXpEventData(NewEventRef, NewEventRef);
		ProcessXpEvent('XpFirstMissionBonus', NewEventData);
	}

	if (XComHQ.Squad.Length == Survivors.Length && XComHQ.Squad.Length > 0)
	{
		`log("Adding all soldiers survived bonus.",,'XComXpMan');
		NewEventData = class'XpEventData'.static.NewXpEventData(NewEventRef, NewEventRef);
		ProcessXpEvent('XpAllSoldiersSurvive', NewEventData);
	}
	//  @TODO gameplay - pod circumvented rewards need to be added here

	if (Survivors.Length > 0)
	{
		TotalXp = EarnedPool * Survivors.Length;
		TotalShares = SquadXpShares * Survivors.Length;
		`log("TotalXp:" @ TotalXp,,'XComXpMan');
		//  First tally the total number of shares between the survivors.
		for (SurvivorIdx = 0; SurvivorIdx < Survivors.Length; ++SurvivorIdx)
		{
			for (ShareIdx = 0; ShareIdx < UnitXpShares.Length; ++ShareIdx)			
			{
				if (UnitXpShares[ShareIdx].UnitRef.ObjectID == Survivors[SurvivorIdx])
				{
					TotalShares += UnitXpShares[ShareIdx].Shares;
				}
			}
		}
		`log("TotalShares:" @ TotalShares,,'XComXpMan');
		//  Now calculate how much each survivor will earn.
		for (SurvivorIdx = 0; SurvivorIdx < Survivors.Length; ++SurvivorIdx)
		{
			CurrentShares = SquadXpShares;
			for (ShareIdx = 0; ShareIdx < UnitXpShares.Length; ++ShareIdx)			
			{
				if (UnitXpShares[ShareIdx].UnitRef.ObjectID == Survivors[SurvivorIdx])
				{
					CurrentShares += UnitXpShares[ShareIdx].Shares;
					break;
				}
			}
			`log("Calculating for unit" @ Survivors[SurvivorIdx],,'XComXpMan');
			EarnedXp = class'X2ExperienceConfig'.static.GetBaseMissionXp(BattleState.GetForceLevel());
			`log("BaseMissionXp:" @ EarnedXp,,'XComXpMan');
			EarnedXp += (CurrentShares / TotalShares) * TotalXP;			
			`log("Shares:" @ CurrentShares @ "EarnedXp:" @ EarnedXp,,'XComXpMan');

			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Survivors[SurvivorIdx]));
			ExcessXp = UnitState.AddXp(EarnedXp);
			if (UnitState.CanRankUpSoldier())
			{
				TotalExcess += ExcessXp;
				`log("--Excess Xp:" @ ExcessXp,,'XComXpMan');
			}
			else if (UnitState.GetRank() != `GET_MAX_RANK)
			{
				UnrankedUnits.AddItem(UnitState);
			}

		}
		`log("Total excess xp:" @ TotalExcess,,'XComXpMan');
		if (ExcessXp > 0)
		{
			`log("Number of unranked units:" @ UnrankedUnits.Length,,'XComXpMan');
			if (UnrankedUnits.Length > 0)
			{
				ExcessXp = TotalExcess / UnrankedUnits.Length;
				foreach UnrankedUnits(UnitState)
				{
					`log("Giving" @ ExcessXp @ "excess xp to unit" @ UnitState.ObjectID,,'XComXpMan');
					UnitState.AddXp(ExcessXp);
				}
			}
		}
	}
}

protected function XComGameState_Player GetXComPlayer(XComGameState CheckGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;

	foreach CheckGameState.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if (PlayerState.GetTeam() == eTeam_XCom)
			return PlayerState;
	}
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if (PlayerState.GetTeam() == eTeam_XCom)
			return PlayerState;
	}

	// @mnauta removing assert, possible to not have PlayerState in strategy
	//`assert(false);
	return none;
}

//
//  ==XpEvent Delegates Below==
//
//  There should be one delegate per event, whose name exactly matches the event name (as found in the config values of X2ExperienceConfig.XpEvents).
//  Each delegate should simply call the native response function to handle processing.
//
function EventListenerReturn XpAllSoldiersSurvive(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}

function EventListenerReturn XpPodCircumvented(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}

function EventListenerReturn XpActivateVIP(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}

function EventListenerReturn XpSuccessfulHack(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}

function EventListenerReturn XpLowHealth(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}

function EventListenerReturn XpKillShot(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}

function EventListenerReturn XpHealDamage(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}

function EventListenerReturn XpGetShotAt(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}

function EventListenerReturn XpFirstMissionBonus(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return XpEventResponse(GetFuncName(), XpEventData(EventData), GameState, EventID, CallbackData);
}