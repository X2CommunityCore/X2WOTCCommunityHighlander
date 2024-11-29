//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_AlienNetworkComponent.uc
//  AUTHOR:  Mark Nauta  --  01/12/2015
//  PURPOSE: This object represents the instance data for an alien network component
//			 on the world map
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AlienNetworkComponent extends XComGameState_GeoscapeEntity
	native(Core) config(GameBoard);

var() StateObjectReference			Mission;
var() int							Doom;

// Doom Projects
var() TDateTime						DoomProjectIntervalStartTime;
var() TDateTime						DoomProjectIntervalEndTime;
var() float							DoomProjectTimeRemaining;
var() int							DoomProjectSuccessChance;
var() bool							bNeedsDoomPopup;

var config int						IntelCost;
var config int						MinDoomProjectInterval;
var config int						MaxDoomProjectInterval;
var config int						StartingSuccessChance;
var config int						SuccessChanceIncrease;
var config int						DoomProjectGracePeriod; // On return from Lose phase
var config int						MaxDoom;

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function PostCreateInit(XComGameState NewGameState, StateObjectReference RegionRef)
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local array<XComGameState_Reward> MissionRewards;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_MissionSite MissionState;
	local X2MissionSourceTemplate MissionSource;
	local int HoursToAdd;
	
	// Set Region and Location
	History = `XCOMHISTORY;
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(RegionRef.ObjectID));
	Region = RegionRef;
	Location = RegionState.GetRandomLocationInRegion(,,self);

	// Set Starting Doom Project Chance
	DoomProjectSuccessChance = default.StartingSuccessChance;
		
	// Start Doom ProjectTimer
	DoomProjectIntervalStartTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	DoomProjectIntervalEndTime = DoomProjectIntervalStartTime;
	HoursToAdd = default.MinDoomProjectInterval + `SYNC_RAND(default.MaxDoomProjectInterval - default.MinDoomProjectInterval + 1);
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(DoomProjectIntervalEndTime, HoursToAdd);
	DoomProjectTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(DoomProjectIntervalEndTime, DoomProjectIntervalStartTime);

	// Create Mission
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	MissionRewards.AddItem(RewardState);

	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_AlienNetwork'));
	MissionState = XComGameState_MissionSite(NewGameState.CreateNewStateObject(class'XComGameState_MissionSite'));

	MissionState.BuildMission(MissionSource, Get2DLocation(), RegionRef, MissionRewards, true, false);
	Mission = MissionState.GetReference();
}

//---------------------------------------------------------------------------------------
function string GetDisplayName()
{
	return "";
}

//---------------------------------------------------------------------------------------
function string GetSummaryText()
{
	return "";
}

//---------------------------------------------------------------------------------------
function int GetIntelCost()
{
	return default.IntelCost;
}

//---------------------------------------------------------------------------------------
function bool CanAffordIntelCost()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return (XComHQ.CanAffordResourceCost('Intel', GetIntelCost()));
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool Update(XComGameState NewGameState)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local UIStrategyMap StrategyMap;
	local bool bUpdated;
	local int HoursToAdd;

	StrategyMap = `HQPRES.StrategyMap2D;
	bUpdated = false;
	
	// Do not modify doom while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(DoomProjectIntervalEndTime, `STRATEGYRULES.GameTime))
		{
			bUpdated = true;
			if (class'X2StrategyGameRulesetDataStructures'.static.Roll(DoomProjectSuccessChance))
			{
				AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

				Doom++;
				DoomProjectSuccessChance = default.StartingSuccessChance;
				
				if (!AlienHQ.bHasSeenDoomPopup)
				{
					bNeedsDoomPopup = true;
				}
				
				if (Doom > default.MaxDoom)
				{
					Doom--;
					AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
					AlienHQ.ModifyDoom(1);
				}

				class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgress');
			}
			else
			{
				DoomProjectSuccessChance += default.SuccessChanceIncrease;
			}

			DoomProjectIntervalStartTime = `STRATEGYRULES.GameTime;
			DoomProjectIntervalEndTime = DoomProjectIntervalStartTime;
			HoursToAdd = default.MinDoomProjectInterval + `SYNC_RAND(default.MaxDoomProjectInterval - default.MinDoomProjectInterval + 1);
			class'X2StrategyGameRulesetDataStructures'.static.AddHours(DoomProjectIntervalEndTime, HoursToAdd);
			DoomProjectTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(DoomProjectIntervalEndTime, DoomProjectIntervalStartTime);
		}
	}

	return bUpdated;
}

//---------------------------------------------------------------------------------------
function PauseDoomProjectTimer()
{
	// Update Time remaining and set end time to unreachable future
	DoomProjectTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(DoomProjectIntervalEndTime, `STRATEGYRULES.GameTime);
	DoomProjectIntervalEndTime.m_iYear = 9999;
}

//---------------------------------------------------------------------------------------
function ResumeDoomProjectTimer(optional bool bGracePeriod = false)
{
	local float TimeToAdd;

	// Update the start time then calculate the end time using the time remaining
	DoomProjectIntervalStartTime = `STRATEGYRULES.GameTime;
	DoomProjectIntervalEndTime = DoomProjectIntervalStartTime;
	TimeToAdd = DoomProjectTimeRemaining;

	if (bGracePeriod)
	{
		TimeToAdd += float(default.DoomProjectGracePeriod) * 3600.0;
	}

	class'X2StrategyGameRulesetDataStructures'.static.AddTime(DoomProjectIntervalEndTime, TimeToAdd);
}

//#############################################################################################
//----------------   GEOSCAPE ENTITY IMPLEMENTATION   -----------------------------------------
//#############################################################################################

function bool ShouldBeVisible()
{
	return true;
}

//---------------------------------------------------------------------------------------
function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_AlienNetworkComponent';
}

//---------------------------------------------------------------------------------------
function string GetUIWidgetFlashLibraryName()
{
	return "MI_alienFacility";
}

//---------------------------------------------------------------------------------------
function string GetUIPinImagePath()
{
	return "";
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	return StaticMesh'UI_3D.Overworld.Triad_Icon';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 2;
	ScaleVector.Y = 2;
	ScaleVector.Z = 2;

	return ScaleVector;
}

//---------------------------------------------------------------------------------------
function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_AlienNetworkComponent ANCState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Alien Network");

	ANCState = XComGameState_AlienNetworkComponent(NewGameState.ModifyStateObject(class'XComGameState_AlienNetworkComponent', ObjectID));

	if (!ANCState.Update(NewGameState))
	{
		NewGameState.PurgeGameStateForObjectID(ANCState.ObjectID);
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	if(bNeedsDoomPopup)
	{
		DoomAddedPopup();
	}
}

//---------------------------------------------------------------------------------------
simulated private function IntelUnlockCallback(Name eAction)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;

	if (eAction == 'eUIAction_Accept')
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unlock Mission");

		// spend the intel
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ.AddResource(NewGameState, 'Intel', -GetIntelCost());

		// unlock the mission
		MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', Mission.ObjectID));
		MissionState.Available = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		// do not make Skyranger RTB
		InteractionComplete(false);
	}
	else if (eAction == 'eUIAction_Cancel')
	{
		InteractionComplete(false);
	}
	else
	{
		`assert(false);
	}
}

//---------------------------------------------------------------------------------------
simulated public function DoomAddedPopup()
{
	local XComGameState NewGameState;
	local XComGameState_AlienNetworkComponent ANCState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local DynamicPropertySet PropertySet;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Doom Popup flag");
	ANCState = XComGameState_AlienNetworkComponent(NewGameState.ModifyStateObject(class'XComGameState_AlienNetworkComponent', self.ObjectID));
	ANCState.bNeedsDoomPopup = false;
	
	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	AlienHQ.bHasSeenDoomPopup = true; // Ensure the doom popup is only shown to the player once
	
	`XEVENTMGR.TriggerEvent('OnDoomPopup', , , NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	`GAME.GetGeoscape().Pause();

	class'XComHQPresentationLayer'.static.BuildUIAlert(PropertySet, 'eAlert_Doom', class'XComHQPresentationLayer'.static.DoomAlertCB, '', "Geoscape_DoomIncrease");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', Mission.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'RegionRef', ANCState.Region.ObjectID);
	class'XComHQPresentationLayer'.static.QueueDynamicPopup(PropertySet, NewGameState);
}

//---------------------------------------------------------------------------------------
function RemoveEntity(XComGameState NewGameState)
{
	local bool SubmitLocally;

	if (NewGameState == None)
	{
		SubmitLocally = true;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Alien Network Component Removed");
	}

	// remove from the history
	NewGameState.RemoveStateObject(ObjectID);

	if (`HQPRES != none && `HQPRES.StrategyMap2D != none)
	{
		RemoveMapPin(NewGameState);
	}

	if (SubmitLocally)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}