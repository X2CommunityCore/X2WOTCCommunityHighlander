//---------------------------------------------------------------------------------------
//  FILE:    X2HackReward.uc
//  AUTHOR:  Dan Kaplan  --  11/11/2014
//  PURPOSE: Interface for adding new Hack Rewards to X-Com 2.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2HackReward extends X2DataSet
	config(GameCore);

var config array<name> HackRewardNames;

var config int PRIORITY_DATA_DARK_EVENT_EXTENSION_HOURS;
var config float WATCH_LIST_CONTACT_COST_MOD;
var config float INSIGHT_TECH_COMPLETION_MOD;
var config float SATELLITE_DATA_SCAN_RATE_MOD;
var config int SATELLITE_DATA_SCAN_RATE_DURATION_HOURS;
var config int RESISTANCE_BROADCAST_INCOME_BONUS;
var config int ENEMY_PROTOCOL_HACKING_BONUS;
var config int VIPER_ROUNDS_APPLICATION_CHANCE;
var config int COLLATERAL_DAMAGE_APPLICATION_CHANCE;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2HackRewardTemplate Template;
	local name TemplateName;
	
	foreach default.HackRewardNames(TemplateName)
	{
		`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);
		Templates.AddItem(Template);
	}

	Templates.AddItem(Distraction('Distraction_T1'));
	Templates.AddItem(Distraction('Distraction_T2'));

	Templates.AddItem(PriorityData('PriorityData_T1'));
	Templates.AddItem(PriorityData('PriorityData_T2'));

	Templates.AddItem(WatchList('WatchList_T1'));
	Templates.AddItem(WatchList('WatchList_T2'));

	Templates.AddItem(Insight('Insight_T1'));
	Templates.AddItem(Insight('Insight_T2'));

	Templates.AddItem(SatelliteData('SatelliteData_T1'));
	Templates.AddItem(SatelliteData('SatelliteData_T2'));

	Templates.AddItem(ResistanceBroadcast('ResistanceBroadcast_T1'));
	Templates.AddItem(ResistanceBroadcast('ResistanceBroadcast_T2'));

	Templates.AddItem(EnemyProtocol('EnemyProtocol_T1'));
	Templates.AddItem(EnemyProtocol('EnemyProtocol_T2'));

	// Negative rewards
	Templates.AddItem(MapAlert('MapAlert_T0'));

	// Intel rewards
	Templates.AddItem(SquadConceal('SquadConceal_Intel'));
	Templates.AddItem(IndividualConceal('IndividualConceal_Intel'));

	// Dark Events
	Templates.AddItem(DarkEvent('DarkEvent_ViperRounds', ApplyViperRounds));
	Templates.AddItem(DarkEvent('DarkEvent_CollateralDamage', ApplyCollateralDamage));

	// Compound Rescue Door Hack
	Templates.AddItem(SecureDoorHack('ObjectiveDoor_T1_Secure'));

	return Templates;
}


static function X2HackRewardTemplate Distraction(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyDistraction;

	return Template;
}

function ApplyDistraction(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit NewUnitState, Unit;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && Unit.IsAlive() )
		{
			NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			NewUnitState.GiveStandardActionPoints();
		}
	}

	NewGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeDistraction);
}

static function VisualizeDistraction(XComGameState VisualizeGameState)
{
	local X2Action_UpdateUI UpdateUIAction;
	local XComGameStateHistory History;
	local VisualizationActionMetadata ActionMetadata, EmptyTrack;
	local XComGameState_Unit UnitState;
	local XComGameStateContext Context;

	// Iterate through all units affected by this action point manipulation & update unit flags to show the new action points remaining
	History = `XCOMHISTORY;
	Context = VisualizeGameState.GetContext( );

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		ActionMetadata = EmptyTrack;

		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		UpdateUIAction.SpecificID = UnitState.ObjectID;
		UpdateUIAction.UpdateType = EUIUT_UnitFlag_Moves;

	}
}


static function X2HackRewardTemplate PriorityData(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyPriorityData;

	return Template;
}

function ApplyPriorityData(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local StateObjectReference DarkEventRef;
	local XComGameState_DarkEvent DarkEventState;

	History = `XCOMHISTORY;

	// extend the activation timer on all currently chosen Dark Events
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	foreach AlienHQ.ChosenDarkEvents(DarkEventRef)
	{
		DarkEventState = XComGameState_DarkEvent(NewGameState.ModifyStateObject(class'XComGameState_DarkEvent', DarkEventRef.ObjectID));

		DarkEventState.ExtendActivationTimer(PRIORITY_DATA_DARK_EVENT_EXTENSION_HOURS);
	}
}


static function X2HackRewardTemplate WatchList(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyWatchList;

	return Template;
}

function ApplyWatchList(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameState_WorldRegion RegionState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_WorldRegion> PossibleContactRegions;

	History = `XCOMHISTORY;

	// choose a region with available contact
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	PossibleContactRegions = XComHQ.GetContactRegions();
	RegionState = PossibleContactRegions[`SYNC_RAND(PossibleContactRegions.Length)];

	// modify the contact cost
	RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));

	RegionState.ModifyContactCost(WATCH_LIST_CONTACT_COST_MOD);
}


static function X2HackRewardTemplate Insight(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyInsight;

	return Template;
}


function ApplyInsight(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectResearch ResearchProjectState;

	History = `XCOMHISTORY;

	// decrease the research time on the current tech
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ResearchProjectState = XComHQ.GetCurrentResearchProject();

	if( ResearchProjectState != None )
	{
		ResearchProjectState = XComGameState_HeadquartersProjectResearch(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectResearch', ResearchProjectState.ObjectID));

		ResearchProjectState.ModifyProjectPointsRemaining(INSIGHT_TECH_COMPLETION_MOD);
	}
}

static function X2HackRewardTemplate SatelliteData(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplySatelliteData;

	return Template;
}

function ApplySatelliteData(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	// increase the scan rate for the avenger
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.SetScanRateForDuration(NewGameState, SATELLITE_DATA_SCAN_RATE_MOD, SATELLITE_DATA_SCAN_RATE_DURATION_HOURS);
}


static function X2HackRewardTemplate ResistanceBroadcast(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyResistanceBroadcast;

	return Template;
}

function ApplyResistanceBroadcast(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameState_WorldRegion RegionState;

	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	// Modify the supply drop value for the current region
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));

	RegionState.ModifyBaseSupplyDrop(RESISTANCE_BROADCAST_INCOME_BONUS);
}


static function X2HackRewardTemplate EnemyProtocol(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyEnemyProtocol;

	return Template;
}

function ApplyEnemyProtocol(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameState_Unit HackerState;

	HackerState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Hacker.ObjectID));

	HackerState.SetBaseMaxStat(eStat_Hacking, HackerState.GetMaxStat(eStat_Hacking) + ENEMY_PROTOCOL_HACKING_BONUS);
}

static function X2HackRewardTemplate MapAlert(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyMapAlert;

	return Template;
}

function ApplyMapAlert(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameState_AIUnitData NewAIUnitDataState, AIUnitDataState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local AlertAbilityInfo AlertInfo;

	History = `XCOMHISTORY;
		
	Hacker.GetKeystoneVisibilityLocation(AlertInfo.AlertTileLocation);
	AlertInfo.AlertRadius = 1000;
	AlertInfo.AlertUnitSourceID = Hacker.ObjectID;
	AlertInfo.AnalyzingHistoryIndex = History.GetCurrentHistoryIndex(); //NewGameState.HistoryIndex; <- this value is -1.

	foreach History.IterateByClassType(class'XComGameState_AIUnitData', AIUnitDataState)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIUnitDataState.m_iUnitObjectID));
		if( UnitState != None && UnitState.IsAlive() )
		{
			NewAIUnitDataState = XComGameState_AIUnitData(NewGameState.ModifyStateObject(AIUnitDataState.Class, AIUnitDataState.ObjectID));

			if( !NewAIUnitDataState.AddAlertData(NewAIUnitDataState.m_iUnitObjectID, eAC_MapwideAlert_Hostile, AlertInfo, NewGameState) )
			{
				NewGameState.PurgeGameStateForObjectID(NewAIUnitDataState.ObjectID);
			}
		}
	}
}

static function X2HackRewardTemplate SquadConceal(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplySquadConceal;
	Template.MutuallyExclusiveRewards.AddItem('IndividualConceal_Intel');

	return Template;
}

function ApplySquadConceal(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;

	History = `XCOMHISTORY;

	// enable individual concealment on all XCom units
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if( PlayerState.GetTeam() == eTeam_XCom )
		{
			PlayerState.SetSquadConcealmentNewGameState(true, NewGameState);
		}
	}
}

static function X2HackRewardTemplate IndividualConceal(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyIndividualConceal;
	Template.MutuallyExclusiveRewards.AddItem('SquadConceal_Intel');

	return Template;
}

function ApplyIndividualConceal(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

	// enable individual concealment on all XCom units
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom )
		{
			UnitState.EnterConcealmentNewGameState(NewGameState);
		}
	}
}

static function X2HackRewardTemplate DarkEvent(Name TemplateName, Delegate<X2HackRewardTemplate.ApplyHackReward> ApplyDarkEvent)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplyDarkEvent;

	return Template;
}

function ApplyViperRounds(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, NewUnitState;
	local XComGameState_Item AmmoState, WeaponState;
	local X2ItemTemplate AmmoTemplate;

	History = `XCOMHISTORY;
	AmmoTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate('VenomRounds');

	// viper rounds only apply to advent officers
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetMyTemplate().bIsAdvent )
		{
			if( `SYNC_RAND(100) < VIPER_ROUNDS_APPLICATION_CHANCE )
			{
				WeaponState = UnitState.GetPrimaryWeapon();
				if( WeaponState != None )
				{
					NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

					// create the ammo
					AmmoState = AmmoTemplate.CreateInstanceFromTemplate(NewGameState);

					NewUnitState.AddItemToInventory(AmmoState, eInvSlot_AmmoPocket, NewGameState);

					// apply it to the unit's weapon
					WeaponState = XComGameState_Item(NewGameState.ModifyStateObject(WeaponState.Class, WeaponState.ObjectID));

					WeaponState.LoadedAmmo = AmmoState.GetReference();
				}
			}
		}
	}
}

function ApplyCollateralDamage(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Item> Items;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetMyTemplate().bIsAdvent )
		{
			if( `SYNC_RAND(100) < COLLATERAL_DAMAGE_APPLICATION_CHANCE )
			{
				Items = UnitState.GetAllItemsInSlot( eInvSlot_Utility );

				foreach Items(ItemState)
				{
					if (X2GrenadeTemplate(ItemState.GetMyTemplate()) != none)
						break;
				}

				if (ItemState == none) // didn't find a grenade
					continue;

				ItemState = XComGameState_Item(NewGameState.ModifyStateObject(ItemState.Class, ItemState.ObjectID));
				++ItemState.Ammo;
			}
		}
	}
}

static function X2HackRewardTemplate SecureDoorHack(Name TemplateName)
{
	local X2HackRewardTemplate Template;

	`CREATE_X2TEMPLATE(class'X2HackRewardTemplate', Template, TemplateName);

	Template.ApplyHackRewardFn = ApplySecureDoorUnlock;

	return Template;
}

function ApplySecureDoorUnlock(XComGameState_Unit Hacker, XComGameState_BaseObject HackTarget, XComGameState NewGameState)
{
	// Broadcast a remote event for kismet, so it register that the player didn't blow their cover when hacking the door
	`XCOMGRI.DoRemoteEvent('CompoundRescue_SecureDoorUnlock');
}