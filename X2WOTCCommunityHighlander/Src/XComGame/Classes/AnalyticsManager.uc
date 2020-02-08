//---------------------------------------------------------------------------------------
//  FILE:    AnalyticsManager.uc
//  AUTHOR:  Scott Ramsay  --  4/6/2015
//  PURPOSE: Global manager
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class AnalyticsManager extends Object
	native(Core)
	dependson(X2StrategyGameRulesetDataStructures, XComGameState);

// data duped from XComGameState_CampaignSettings
struct native CampaignSettings
{
	var string StartTime;					// Tracks when the player initiated this campaign.
	var int DifficultySetting;				// 0:Easy 1:Normal 2:Classic 3:Impossible
	var bool bIronmanEnabled;				// TRUE indicates that this campaign was started with Ironman enabled
	var bool bTutorialEnabled;				// TRUE indicates that this campaign was started with the tutorial enabled
	var bool bXPackNarrativeEnabled;		// TRUE indicates that this campaign was started with XPack narrative tutorial enabled
	var bool bIntegratedDLCEnabled;			// TRUE indicates that this campaign was started withe Integrated DLC enabled
	var bool bSuppressFirstTimeNarrative;	// TRUE, the tutorial narrative moments will be skipped
};

var private{private} bool bShouldSubmitGameState;

var private{private} bool bAvaibleWorldStats;
var private{private} bool bWaitingOnWorldStats;

var private native Map_Mirror GlobalEndgameStats{ TMap<FString, double> };
var private int NumEndgameStatSubmissions;

var XComGameState_Analytics		PrevDebugAnalytics;

const WORLD_STAT_TIMEOUT_SECONDS = 30.0f;

native function Init();

function bool ShouldSubmitGameState()
{
	return bShouldSubmitGameState;
}

native static function SendCampaignEndGame( );

function EndgameStatsTimeout()
{
	if (bWaitingOnWorldStats)
	{
		bWaitingOnWorldStats = false;
		`FXSLIVE.ClearReceivedStatsKVPDelegate( StatsRecieved );
		CloseWorldStatsDialog( );
	}
}

function DebugDoEndgameStats( bool Win )
{
	local X2FiraxisLiveClient LiveClient;
	local XComEarth Earth;

	if (Win)
		SendCampaignEndGame( );

	LiveClient = `FXSLIVE;
	Earth = `EARTH; // for no particular reason, we just need a strategy available actor (we are just a lowley object without timers).

	bAvaibleWorldStats = false;
	bWaitingOnWorldStats = true;
	LiveClient.AddReceivedStatsKVPDelegate( StatsRecieved );

	Earth.SetTimer( WORLD_STAT_TIMEOUT_SECONDS, false, nameof(EndgameStatsTimeout), self );

	LiveClient.GetStats( eKVPSCOPE_GLOBAL );
}

static function bool SkipAddAnalyticObject(XComGameState GameState)
{
	local XComGameState_BattleData Battle;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));

	// Don't add any objects while in Multiplayer
	if( (Battle != none) && (Battle.m_strDesc ~= "Multiplayer") )
	{
		return true;
	}

	// Don't add objects for interrupted gamestates.  Only create analytics for completed (none or resume contexts)
	if (GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		return true;
	}

	return false;
}


static function EventListenerReturn OnSoldierTacticalToStrategy(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject(GameState))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddSoldierTacticalToStrategy(XComGameState_Unit(EventData), GameState);
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnTacticalGameStart(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddTacticalGameStart( );
	}

	SendMissionStartTelemetry( History );

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnTacticalGameEnd(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject(GameState))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddTacticalGameEnd();
	}

	SendMissionEndTelemetry( History );

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnPlayerTurnEnded( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if ((AnalyticsObject != none) && (XComGameState_Player(EventData).TeamFlag == eTeam_XCom))
	{
		AnalyticsObject.AddPlayerTurnEnd( );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnUnitMoved(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		// report move
		AnalyticsObject.AddUnitMoved( XComGameState_Unit( EventSource ), GameState );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnKillMail(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if( SkipAddAnalyticObject(GameState) )
	{
		return ELR_NoInterrupt;
	}

	`ANALYTICSLOG("KillMail");

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	if (AnalyticsObject != none)
	{
		// report kill
		AnalyticsObject.AddKillMail(XComGameState_Unit(EventSource), XComGameState_Unit(EventData));
	}

	return ELR_NoInterrupt;
}


static function EventListenerReturn OnBreakWindow(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if( SkipAddAnalyticObject(GameState) )
	{
		return ELR_NoInterrupt;
	}

	`ANALYTICSLOG("BreakWindow");

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddBreakWindow(XComGameState_Unit(EventSource), XComGameStateContext_Ability(EventData));
	}

	return ELR_NoInterrupt;
}


static function EventListenerReturn OnBreakDoor(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if( SkipAddAnalyticObject(GameState) )
	{
		return ELR_NoInterrupt;
	}

	`ANALYTICSLOG("BreakDoor");

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddBreakDoor(XComGameState_Unit(EventSource), XComGameStateContext_Ability(EventData));
	}

	return ELR_NoInterrupt;
}


static function EventListenerReturn OnWeaponKillType(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if( SkipAddAnalyticObject(GameState) )
	{
		return ELR_NoInterrupt;
	}

	`ANALYTICSLOG("Weapon Kill Type");

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddWeaponKill(XComGameState_Unit(EventSource), XComGameState_Ability(EventData));
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnMissionObjectiveComplete(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject(GameState))
	{
		return ELR_NoInterrupt;
	}

	`ANALYTICSLOG("Mission Objective Complete");

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddMissionObjectiveComplete();
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnCivilianRescued(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject(GameState))
	{
		return ELR_NoInterrupt;
	}

	`ANALYTICSLOG("Civilian Rescued");

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddCivilianRescued(XComGameState_Unit(EventData), XComGameState_Unit(EventSource));
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnUnitDamaged(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit DamageSource;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AbilityContext = XComGameStateContext_Ability( GameState.GetContext() );
		if (AbilityContext != none)
		{
			DamageSource = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		}

		AnalyticsObject.AddUnitDamage( XComGameState_Unit( EventSource ), DamageSource, GameState.GetContext() );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnAbilityActivation(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit Shooter, Target;
	local XComGameState_Item Tool;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AbilityContext = XComGameStateContext_Ability( GameState.GetContext( ) );
		`assert( AbilityContext != none );

		Shooter = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		Target = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		Tool = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));

		AnalyticsObject.AddUnitTakenShot( Shooter, Target, Tool, AbilityContext, XComGameState_Ability(EventData) );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnUnitHealComplete(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local XComGameState_Unit UnitState;
	local TDateTime CurrentDate;
	local int TimeDiffHours;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		UnitState = XComGameState_Unit( EventData );
		HealProject = XComGameState_HeadquartersProjectHealSoldier( EventSource );
		CurrentDate = `STRATEGYRULES.GameTime;

		TimeDiffHours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours( CurrentDate, HealProject.StartDateTime );
		TimeDiffHours += HealProject.ProjectTimeBeforePausesHours;

		AnalyticsObject.AddUnitHealCompleted( UnitState, TimeDiffHours );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnNewCrewAdded( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddCrewAddition( XComGameState_Unit(EventData) );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnResearchCompleted( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Tech Tech;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local XComGameState_HeadquartersXCom XComHQ;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		Tech = XComGameState_Tech( EventData );
		ResearchProject = XComGameState_HeadquartersProjectResearch( EventSource );

		if (Tech.GetMyTemplate().bProvingGround)
		{
			XComHQ = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
			XComHQ = XComGameState_HeadquartersXCom( History.GetGameStateForObjectID( XComHQ.ObjectID, , GameState.HistoryIndex ) );

			AnalyticsObject.AddProvingGroundCompletion( Tech, XComHQ, ResearchProject, GameState );
		}
		else
		{
			AnalyticsObject.AddResearchCompletion( Tech, ResearchProject );
		}

	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnResistanceActivityComplete( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local X2ResistanceActivityTemplate ActivityTemplate;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int Delta, idx;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	if (EventData == none)
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		ActivityTemplate = X2ResistanceActivityTemplate( EventData );
		ResistanceHQ = XComGameState_HeadquartersResistance( EventSource );

		idx = ResistanceHQ.ResistanceActivities.Find('ActivityTemplateName', ActivityTemplate.DataName );
		Delta = ResistanceHQ.ResistanceActivities[idx].LastIncrement;

		AnalyticsObject.AddResistanceActivity( ActivityTemplate, Delta );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnResourceAdded( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Item Resource;
	
	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		Resource = XComGameState_Item( EventData );

		AnalyticsObject.AddResource( Resource, Resource.LastQuantityChange );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnBlackMarketPurchase( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_BlackMarket BlackMarket;
	local XComGameState_Reward RewardState;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		RewardState = XComGameState_Reward( EventData );
		BlackMarket = XComGameState_BlackMarket( History.GetPreviousGameStateForObject( XComGameState_BlackMarket( EventSource ) ) );

		AnalyticsObject.AddBlackMarketPurchase( BlackMarket, RewardState );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnBlackMarketGoodsSold( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local StateObjectReference ObjRef;
	local XComGameState_Item ItemState, PrevState;
	local XComGameState_HeadquartersXCom XComHQ;
	local int Supplies, PrevSupplies;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		XComHQ = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
		foreach XComHQ.Inventory(ObjRef)
		{
			ItemState = XComGameState_Item( History.GetGameStateForObjectID( ObjRef.ObjectID ) );

			if (ItemState != none && ItemState.GetMyTemplateName( ) == 'Supplies')
			{
				break;
			}
		}

		PrevState = XComGameState_Item( History.GetPreviousGameStateForObject( ItemState ) );

		Supplies = ItemState.Quantity;
		PrevSupplies = PrevState.Quantity;

		AnalyticsObject.AddBlackmarketSupplies( Supplies - PrevSupplies );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnSupplyDrop( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local StateObjectReference ObjRef;
	local XComGameState_Item ItemState, PrevState;
	local XComGameState_HeadquartersXCom XComHQ;
	local int Supplies, PrevSupplies;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		XComHQ = XComGameState_HeadquartersXCom( History.GetGameStateForObjectID( XComGameState_BaseObject(EventData).ObjectID ) );
		foreach XComHQ.Inventory(ObjRef)
		{
			ItemState = XComGameState_Item( History.GetGameStateForObjectID( ObjRef.ObjectID ) );

			if (ItemState != none && ItemState.GetMyTemplateName( ) == 'Supplies')
			{
				break;
			}
		}

		PrevState = XComGameState_Item( History.GetPreviousGameStateForObject( ItemState ) );

		Supplies = ItemState.Quantity;
		PrevSupplies = PrevState.Quantity;

		AnalyticsObject.AddSupplyDropSupplies( Supplies - PrevSupplies );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnChosenDefeated( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Unit KilledUnit;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		KilledUnit = XComGameState_Unit(EventData);

		// ignore everybody who is not a chosen
		if (!KilledUnit.GetMyTemplate().bIsChosen)
			return ELR_NoInterrupt;

		AnalyticsObject.AddChosenDefeated( KilledUnit );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnChosenInterrogation( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit Chosen;
	local XComGameState_Unit CapturedUnit;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AbilityState = XComGameState_Ability( EventData );
		AbilityContext = XComGameStateContext_Ability( GameState.GetContext() );
		Chosen = XComGameState_Unit( History.GetGameStateForObjectID( AbilityContext.InputContext.SourceObject.ObjectID ) );
		CapturedUnit = XComGameState_Unit( History.GetGameStateForObjectID( AbilityContext.InputContext.PrimaryTarget.ObjectID ) );

		AnalyticsObject.AddChosenInterrogation( Chosen, CapturedUnit, AbilityState, AbilityContext );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnChosenKidnap( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit Chosen;
	local XComGameState_Unit CapturedUnit;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AbilityState = XComGameState_Ability( EventData );
		AbilityContext = XComGameStateContext_Ability( GameState.GetContext() );
		Chosen = XComGameState_Unit( History.GetGameStateForObjectID( AbilityContext.InputContext.SourceObject.ObjectID ) );
		CapturedUnit = XComGameState_Unit( History.GetGameStateForObjectID( AbilityContext.InputContext.PrimaryTarget.ObjectID ) );

		AnalyticsObject.AddChosenKidnapping( Chosen, CapturedUnit, AbilityState, AbilityContext );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnChosenCapture( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_AdventChosen Chosen;
	local XComGameState_Unit CapturedUnit;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		Chosen = XComGameState_AdventChosen( EventSource );
		CapturedUnit = XComGameState_Unit( EventData );

		AnalyticsObject.AddChosenCapture( Chosen, CapturedUnit, none, none );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnPCSApplied( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState_Item UpdatedImplant;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		UpdatedUnit = XComGameState_Unit( EventData );
		UpdatedImplant = XComGameState_Item( EventSource );

		AnalyticsObject.AddPCSApplied( UpdatedUnit, UpdatedImplant );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnWeaponUpgraded( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Item UpdatedWeapon;
	local XComGameState_Item UpdatedUpgrade;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		UpdatedWeapon = XComGameState_Item( EventData );
		UpdatedUpgrade = XComGameState_Item( EventSource );

		AnalyticsObject.AddWeaponUpgrade( UpdatedWeapon, UpdatedUpgrade );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnItemConstruction( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Item NewItem;
	local XComGameState_HeadquartersXCom XComHQ;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		NewItem = XComGameState_Item( EventData );

		XComHQ = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
		XComHQ = XComGameState_HeadquartersXCom( History.GetGameStateForObjectID( XComHQ.ObjectID, , GameState.HistoryIndex ) );

		AnalyticsObject.AddItemConstruction( NewItem, XComHQ );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnCoverActionComplete( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddCovertActionCompletion( );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnFacilityConstruction( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectBuildFacility ProjectState;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		Facility = XComGameState_FacilityXCom( EventData );
		ProjectState = XComGameState_HeadquartersProjectBuildFacility( EventSource );

		AnalyticsObject.AddFacilityConstruction( Facility, ProjectState );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnBondLevelUp( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit1, Unit2;
	local XComGameState_HeadquartersProjectBondSoldiers ProjectState;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		Unit1 = XComGameState_Unit( EventData );
		Unit2 = XComGameState_Unit( EventSource );

		foreach GameState.IterateByClassType( class'XComGameState_HeadquartersProjectBondSoldiers', ProjectState )
			break;
		`assert( ProjectState != none );

		AnalyticsObject.AddBondEvent( Unit1, Unit2, ProjectState );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnBondCreation( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit1, Unit2;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		Unit1 = XComGameState_Unit( EventData );
		Unit2 = XComGameState_Unit( EventSource );

		AnalyticsObject.AddBondCreation( Unit1, Unit2 );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnAbilityPointsChange( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		UnitState = XComGameState_Unit( EventData );

		AnalyticsObject.AddAbilityPointChange( UnitState );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnTraitsChanged( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		UnitState = XComGameState_Unit( EventData );

		AnalyticsObject.AddUnitTraitsChange( UnitState );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnHavenScanCompleted( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Haven Haven;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		Haven = XComGameState_Haven( EventData );

		AnalyticsObject.AddHavenScanning( Haven );
	}

	return ELR_NoInterrupt;
}

native function StatsRecieved( bool Success, array<string> GlobalKeys, array<int> GlobalValues, array<string> UserKeys, array<int> UserValues );

native function string NativeGetAvgWorldStatValueAsString( string Metric, string Default = "0" ) const;
native function double NativeGetAvgWorldStatValue( string Metric ) const;
native function float NativeGetAvgWorldStatFloatValue( string Metric ) const; // Unrealscript has trouble converting from double to float.  This works around the compiler issue.

native function string NativeGetWorldStatValueAsString( string Metric, string Default = "0" ) const;
native function double NativeGetWorldStatValue( string Metric ) const;
native function float NativeGetWorldStatFloatValue( string Metric ) const; // Unrealscript has trouble converting from double to float.  This works around the compiler issue.

function string GetAvgWorldStatValueAsString( string Metric, string DefaultVal = "0" )
{
	Metric = class'XComGameState_Analytics'.static.BuildEndGameMetric( Metric );

	return NativeGetAvgWorldStatValueAsString( Metric, DefaultVal );
}

function double GetAvgWorldStatValue( string Metric )
{
	Metric = class'XComGameState_Analytics'.static.BuildEndGameMetric( Metric );

	return NativeGetAvgWorldStatValue( Metric );
}

function float GetAvgWorldStatFloatValue( string Metric )
{
	Metric = class'XComGameState_Analytics'.static.BuildEndGameMetric( Metric );

	return NativeGetAvgWorldStatFloatValue( Metric );
}

function string GetWorldStatValueAsString( string Metric, string DefaultVal = "0" )
{
	Metric = class'XComGameState_Analytics'.static.BuildEndGameMetric( Metric );

	return NativeGetWorldStatValueAsString( Metric, DefaultVal );
}

function double GetWorldStatValue( string Metric )
{
	Metric = class'XComGameState_Analytics'.static.BuildEndGameMetric( Metric );

	return NativeGetWorldStatValue( Metric );
}

function float GetWorldStatFloatValue( string Metric )
{
	Metric = class'XComGameState_Analytics'.static.BuildEndGameMetric( Metric );

	return NativeGetWorldStatFloatValue( Metric );
}

function bool WaitingOnWorldStats( )
{
	return bWaitingOnWorldStats;
}

function bool WorldStatsAvailable( )
{
	return !bWaitingOnWorldStats && bAvaibleWorldStats;
}

static function EventListenerReturn OnVictory( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local X2FiraxisLiveClient LiveClient;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AnalyticsObject.AddXComVictory( );

		SendCampaignEndGame( );

		LiveClient = `FXSLIVE;

		`XANALYTICS.bAvaibleWorldStats = false;
		`XANALYTICS.bWaitingOnWorldStats = true;
		LiveClient.AddReceivedStatsKVPDelegate( `XANALYTICS.StatsRecieved );

		// using the earth for no particular reason, we just need a strategy available actor (we are just a lowley object without timers).
		`EARTH.SetTimer( WORLD_STAT_TIMEOUT_SECONDS, false, nameof(EndgameStatsTimeout), `XANALYTICS );

		LiveClient.GetStats( eKVPSCOPE_GLOBAL );
	}

	SendGameEndTelemetry( History, true );

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnLoss( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local X2FiraxisLiveClient LiveClient;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	LiveClient = `FXSLIVE;
	History = `XCOMHISTORY;

	`XANALYTICS.bAvaibleWorldStats = false;
	`XANALYTICS.bWaitingOnWorldStats = true;
	LiveClient.AddReceivedStatsKVPDelegate( `XANALYTICS.StatsRecieved );

	// using the earth for no particular reason, we just need a strategy available actor (we are just a lowley object without timers).
	`EARTH.SetTimer( WORLD_STAT_TIMEOUT_SECONDS, false, nameof(EndgameStatsTimeout), `XANALYTICS );

	LiveClient.GetStats( eKVPSCOPE_GLOBAL );

	SendGameEndTelemetry( History, false );

	return ELR_NoInterrupt;
}

function CancelWorldStats( )
{
	local X2FiraxisLiveClient LiveClient;

	bWaitingOnWorldStats = false;

	LiveClient = `FXSLIVE;
	LiveClient.ClearReceivedStatsKVPDelegate( StatsRecieved );
}

event CloseWorldStatsDialog()
{
	`HQPRES.UICloseProgressDialog();
}

static function EventListenerReturn OnUnitPromotion( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, PrevUnitState;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		UnitState = XComGameState_Unit( EventData );
		PrevUnitState = XComGameState_Unit( History.GetPreviousGameStateForObject( UnitState ) );

		AnalyticsObject.AddUnitPromotion( UnitState, PrevUnitState );
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn ChallengeScoreChange( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;

	if (SkipAddAnalyticObject( GameState ))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// check if we have analytics object
	AnalyticsObject = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (AnalyticsObject != none)
	{
		AnalyticsObject.ChallengeScoreChange( GameState );
	}

	return ELR_NoInterrupt;
}

static function SendGameStartTelemetry( XComGameStateHistory History, bool IronmanEnabled )
{
	local int Difficulty;
	local string GameMode;

	local XComGameState_CampaignSettings CampaignState;

	GameMode = "CAMPAIGN";

	CampaignState = XComGameState_CampaignSettings( History.GetSingleGameStateObjectForClass( class'XComGameState_CampaignSettings' ) );
	Difficulty = CampaignState.DifficultySetting;

	`FXSLIVE.BizAnalyticsGameStart( CampaignState.BizAnalyticsCampaignID, GameMode, Difficulty, IronmanEnabled );
}

static function SendGameEndTelemetry( XComGameStateHistory History, bool CampaignSuccess )
{
	local XComGameState_CampaignSettings CampaignState;

	CampaignState = XComGameState_CampaignSettings( History.GetSingleGameStateObjectForClass( class'XComGameState_CampaignSettings' ) );

	`FXSLIVE.BizAnalyticsGameEnd( CampaignState.BizAnalyticsCampaignID, CampaignSuccess );
}

static function SendMissionStartTelemetry( XComGameStateHistory History )
{
	local string MissionType;
	local string MissionName;
	local int MissionDifficulty;
	local int TeamSize;

	local int NumSpecialists, NumRangers, NumSharpshooters, NumGrenadiers, NumPsiOps, NumSparkMECS;
	local int NumRookies, NumStoryCharacters, NumVIPS, NumUnknown, NumVolunteers, NumDoubleAgents;
	local int NumSkirmishers, NumReapers, NumTemplars;

	local XComGameState_CampaignSettings CampaignState;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef;
	local XComGameState_Unit UnitState;
	local X2CharacterTemplate SourceTemplate;
	local X2SoldierClassTemplate SoldierClass;

	CampaignState = XComGameState_CampaignSettings( History.GetSingleGameStateObjectForClass( class'XComGameState_CampaignSettings' ) );
	BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	XComHQ = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );

	MissionType = BattleData.MapData.ActiveMission.sType;
	MissionName = BattleData.m_strOpName;
	MissionDifficulty = BattleData.MapData.ActiveMission.Difficulty;

	TeamSize = XComHQ.Squad.Length;
	foreach XComHQ.Squad( UnitRef )
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( UnitRef.ObjectID ) );

		SourceTemplate = UnitState.GetMyTemplateManager( ).FindCharacterTemplate( UnitState.GetMyTemplateName( ) );
		SoldierClass = UnitState.GetSoldierClassTemplate( );

		if (SoldierClass != None)
		{
			switch (SoldierClass.DataName)
			{
				case 'Specialist': ++NumSpecialists;
					break;

				case 'Grenadier': ++NumGrenadiers;
					break;

				case 'Ranger': ++NumRangers;
					break;

				case 'Sharpshooter': ++NumSharpshooters;
					break;

				case 'PsiOperative': ++NumPsiOps;
					break;

				case 'Rookie': ++NumRookies;
					break;

				case 'CentralOfficer': ++NumStoryCharacters;
					break;

				case 'ChiefEngineer': ++NumStoryCharacters;
					break;

				case 'Spark': ++NumSparkMECS;
					break;

				case 'Skirmisher':
					if (SourceTemplate.DataName != 'LostAndAbandonedMox')
						++NumSkirmishers;
					else
						++NumStoryCharacters;
					break;

				case 'Reaper':
					if (SourceTemplate.DataName != 'LostAndAbandonedElena')
						++NumReapers;
					else
						++NumStoryCharacters;
					break;

				case 'Templar':
					++NumTemplars;
					break;

				default: ++NumUnknown;
					break;
			}
		}
		else
		{
			switch (SourceTemplate.DataName)
			{
				case 'AdvPsiWitchM2':
					++NumStoryCharacters;
					break;

				case 'FriendlyVIPCivilian':
				case 'Soldier_VIP':
				case 'Scientist_VIP':
				case 'Engineer_VIP':
					++NumVIPS;
					break;

				case 'VolunteerArmyMilitia':
					++NumVolunteers;
					break;

				default:
					if (SourceTemplate.bIsAdvent)
						++NumDoubleAgents;
					else
						++NumUnknown;
					break;
			}
		}
	}

	`FXSLIVE.BizAnalyticsMissionStart( CampaignState.BizAnalyticsCampaignID, BattleData.BizAnalyticsMissionID, MissionType, MissionName, MissionDifficulty, TeamSize,
											NumSpecialists, NumRangers, NumSharpshooters, NumGrenadiers, NumPsiOps, NumSparkMECS,
											NumSkirmishers, NumReapers, NumTemplars, NumVolunteers, NumDoubleAgents,
											NumRookies, NumStoryCharacters, NumVIPS, NumUnknown );
}

static function SendMissionEndTelemetry( XComGameStateHistory History )
{
	local int EnemiesKilled;
	local int CiviliansRescued, CiviliansKilled, CiviliansTotal;
	local int NumUninjuredSoldiers;
	local string Grade;
	local string Status;
	local string StatusReason;
	local int TurnCount;

	local XGBattle_SP Battle;
	local int i;
	local array<XComGameState_Unit> arrUnits;
	local int KilledSoldiers, InjuredSoldiers;

	local XComGameState_CampaignSettings CampaignState;
	local XComGameState_BattleData BattleData;
	local XComGameState_Player PlayerState;
	local XComGameState_ObjectivesList ObjectivesList;

	Battle = XGBattle_SP(`BATTLE);
	CampaignState = XComGameState_CampaignSettings( History.GetSingleGameStateObjectForClass( class'XComGameState_CampaignSettings' ) );
	BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );

	if (BattleData.MapData.ActiveMission.sType == "Terror")
	{
		CiviliansKilled = class'Helpers'.static.GetNumCiviliansKilled(CiviliansTotal, BattleData.bLocalPlayerWon);
		CiviliansRescued = CiviliansTotal - CiviliansKilled;
	}
	else
	{
		CiviliansRescued = -1;
	}

	Battle.GetAIPlayer( ).GetOriginalUnits( arrUnits, true );
	for (i = 0; i < arrUnits.Length; ++i)
	{
		if (arrUnits[ i ].IsDead( ))
		{
			++EnemiesKilled;
		}
	}

	arrUnits.Length = 0;
	Battle.GetHumanPlayer().GetOriginalUnits( arrUnits, true );
	for (i = 0; i < arrUnits.Length; ++i)
	{
		if (!arrUnits[i].isSoldier())
		{
			continue;
		}

		if (arrUnits[i].IsDead() || arrUnits[i].IsBleedingOut())
		{
			++KilledSoldiers;
		}
		else if (arrUnits[i].WasInjuredOnMission())
		{
			++InjuredSoldiers;
		}
		else
		{
			++NumUninjuredSoldiers;
		}
	}

	foreach History.IterateByClassType( class'XComGameState_Player', PlayerState )
	{
		if (PlayerState.GetTeam( ) == eTeam_XCom)
		{
			break;
		}
	}
	TurnCount = PlayerState.PlayerTurnCount;

	if (KilledSoldiers == 0 && InjuredSoldiers == 0)
	{
		Grade = "FLAWLESS";
	}
	else if (KilledSoldiers == 0)
	{
		Grade = "EXCELLENT";
	}
	else if ((KilledSoldiers * 100 / arrUnits.Length) <= 34) // multiply to transform to percentage
	{
		Grade = "GOOD";
	}
	else if ((KilledSoldiers * 100 / arrUnits.Length) <= 50) // multiply to transform to percentage
	{
		Grade = "FAIR";
	}
	else
	{
		Grade = "POOR";
	}

	if (BattleData.bLocalPlayerWon)
	{
		Status = "COMPLETED";
	}
	else
	{
		Status = "FAILED";
		Grade = "POOR";

		ObjectivesList = XComGameState_ObjectivesList( History.GetSingleGameStateObjectForClass( class'XComGameState_ObjectivesList' ) );
		for (i = 0; i < ObjectivesList.ObjectiveDisplayInfos.Length; ++i)
		{
			if (ObjectivesList.ObjectiveDisplayInfos[i].ShowFailed)
			{
				StatusReason = StatusReason@"OBJECTIVE FAILED="@ObjectivesList.ObjectiveDisplayInfos[i].DisplayLabel;
			}
		}
	}

	`FXSLIVE.BizAnalyticsMissionEnd( CampaignState.BizAnalyticsCampaignID, BattleData.BizAnalyticsMissionID, EnemiesKilled, CiviliansRescued, NumUninjuredSoldiers, TurnCount, Grade, Status, StatusReason );
}

static function SendGameProgressTelemetry( XComGameStateHistory History, string MilestoneName )
{
	local int TimeToDays;

	local TDateTime GameStartDate;
	local float TimeDiffHours;

	local XComGameState_CampaignSettings CampaignState;
	local XComGameState_GameTime GameTime;

	CampaignState = XComGameState_CampaignSettings( History.GetSingleGameStateObjectForClass( class'XComGameState_CampaignSettings' ) );

	class'X2StrategyGameRulesetDataStructures'.static.SetTime( GameStartDate, 0, 0, 0,
																	class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
																	class'X2StrategyGameRulesetDataStructures'.default.START_DAY,
																	class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );

	GameTime = XComGameState_GameTime( History.GetSingleGameStateObjectForClass( class'XComGameState_GameTime' ) );

	TimeDiffHours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours( GameTime.CurrentTime, GameStartDate );

	TimeToDays = Round( TimeDiffHours / 24.0f );

	`FXSLIVE.BizAnalyticsGameProgressv2( CampaignState.BizAnalyticsCampaignID, MilestoneName, TimeToDays );
}

static function SendMPStartTelemetry( XComGameStateHistory History )
{
	local string Map;
	local string TeamMakeup;
	local string GameMode;

	local int i;
	local array<XComGameState_Unit> arrUnits;
	local X2SoldierClassTemplate SoldierClass;
	local X2CharacterTemplate SourceTemplate;
	local XComTacticalController LocalController;
	local XComGameState_BattleDataMP BattleData;

	LocalController = XComTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) );
	BattleData = XComGameState_BattleDataMP( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleDataMP' ) );

	GameMode = "DEATHMATCH";

	LocalController.ControllingPlayerVisualizer.GetOriginalUnits( arrUnits );
	for (i = 0; i < arrUnits.Length; ++i)
	{
		SourceTemplate = arrUnits[i].GetMyTemplateManager( ).FindCharacterTemplate( arrUnits[i].GetMyTemplateName( ) );
		SoldierClass = arrUnits[i].GetSoldierClassTemplate( );

		if (SoldierClass != None)
		{
			TeamMakeup = TeamMakeup@SoldierClass.DataName;
		}
		else
		{
			TeamMakeup = TeamMakeup@SourceTemplate.DataName;
		}

		if (i != arrUnits.Length - 1)
		{
			TeamMakeup = TeamMakeup@", ";
		}
	}

	Map = "PLOT="@BattleData.MapData.PlotMapName@"PARCELS=";
	for (i = 0; i < BattleData.MapData.ParcelData.Length; ++i)
	{
		Map = Map@BattleData.MapData.ParcelData[i].MapName;

		if (i != BattleData.MapData.ParcelData.Length - 1)
		{
			Map = Map@",";
		}
	}

	`FXSLIVE.BizAnalyticsMPStart( BattleData.BizAnalyticsSessionID, GameMode, Map, TeamMakeup );
}

static function SendMPEndTelemetry( XComGameStateHistory History, bool IsCompleted )
{
	local XComTacticalController LocalController;
	local XComGameState_BattleDataMP BattleData;
	local XComGameState_Player LocalPlayer;
	local StateObjectReference LocalPlayerRef;

	LocalController = XComTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) );
	LocalPlayerRef = LocalController.ControllingPlayer;
	LocalPlayer = XComGameState_Player( History.GetGameStateForObjectID( LocalPlayerRef.ObjectID ) );
	BattleData = XComGameState_BattleDataMP( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleDataMP' ) );

	`FXSLIVE.BizAnalyticsMPEnd( BattleData.BizAnalyticsSessionID, LocalPlayer.PlayerTurnCount, BattleData.bLocalPlayerWon, IsCompleted );
}

defaultproperties
{
	bShouldSubmitGameState = true
	bAvaibleWorldStats = false
	bWaitingOnWorldStats = false
}