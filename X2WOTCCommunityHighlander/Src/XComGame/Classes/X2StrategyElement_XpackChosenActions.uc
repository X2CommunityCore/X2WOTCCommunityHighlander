//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_XpackChosenActions.uc
//  AUTHOR:  Mark Nauta  --  09/21/2016
//  PURPOSE: Create templates for Chosen actions for the Chosen to choose from in
//			 the XCOM 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_XpackChosenActions extends X2StrategyElement config(GameData);

var config int				MinRetributionSupplies;
var config int				MaxRetributionSupplies;
var config array<int>		ChosenLevelUpForceLevels;
var config array<int>		SabotageChance;

//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Actions;

	Actions.AddItem(CreateRetributionTemplate());
	Actions.AddItem(CreateTrainingTemplate());
	Actions.AddItem(CreateSabotageTemplate());
	Actions.AddItem(CreateDarkEventTemplate());
	Actions.AddItem(CreateAvengerAssaultTemplate());

	return Actions;
}

//#############################################################################################
//----------------   RETRIBUTION  -------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateRetributionTemplate()
{
	local X2ChosenActionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ChosenActionTemplate', Template, 'ChosenAction_Retribution');
	Template.Category = "ChosenAction";
	Template.OnActivatedFn = ActivateRetribution;
	Template.OnChooseActionFn = OnChooseRetribution;
	Template.PostActionPerformedFn = PostRetribution;
	Template.GetActionPriorityFn = GetRetributionPriority;

	return Template;
}

//---------------------------------------------------------------------------------------
static function ActivateRetribution(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_ChosenAction ActionState;
	local XComGameState_WorldRegion RegionState;

	ActionState = GetAction(InRef, NewGameState);
	RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', ActionState.StoredReference.ObjectID));
	RegionState.ChosenSupplyDropDelta += ActionState.StoredIntValue;
}

//---------------------------------------------------------------------------------------
static function OnChooseRetribution(XComGameState NewGameState, XComGameState_ChosenAction ActionState)
{
	local XComGameState_WorldRegion RegionState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_HeadquartersXCom XComHQ;

	ChosenState = GetChosen(ActionState.ChosenRef, NewGameState);
	RegionState = ChooseRetributionRegion(ChosenState);
	ActionState.StoredReference = RegionState.GetReference();
	ActionState.StoredIntValue = GetRetributionSupplyValue();
	
	XComHQ = GetXComHQ(NewGameState);
	XComHQ.NumChosenRetributions++;
}

//---------------------------------------------------------------------------------------
private static function XComGameState_WorldRegion ChooseRetributionRegion(XComGameState_AdventChosen ChosenState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local StateObjectReference RegionRef;

	History = `XCOMHISTORY;

	if(ChosenState.RegionAttackDeck.Length == 0)
	{
		ChosenState.RegionAttackDeck = ChosenState.TerritoryRegions;
	}

	RegionRef = ChosenState.RegionAttackDeck[`SYNC_RAND_STATIC(ChosenState.RegionAttackDeck.Length)];
	ChosenState.RegionAttackDeck.RemoveItem(RegionRef);
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(RegionRef.ObjectID));

	return RegionState;
}

//---------------------------------------------------------------------------------------
private static function int GetRetributionSupplyValue()
{
	local int SupplyValue;

	SupplyValue = default.MinRetributionSupplies;
	SupplyValue += `SYNC_RAND_STATIC(default.MaxRetributionSupplies - default.MinRetributionSupplies + 1);
	SupplyValue *= -1;

	return SupplyValue;
}

//---------------------------------------------------------------------------------------
static function PostRetribution(StateObjectReference InRef)
{
	`HQPRES.UIChosenRetribution(InRef);
}

//---------------------------------------------------------------------------------------
static function int GetRetributionPriority()
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;
	local X2StrategyElementTemplateManager StratMgr;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if(ChosenState.NumAvengerAssaults > 0)
		{
			return 1;
		}
	}

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	return X2ChosenActionTemplate(StratMgr.FindStrategyElementTemplate('ChosenAction_Retribution')).ActionPriority;
}

//#############################################################################################
//----------------   TRAINING  ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateTrainingTemplate()
{
	local X2ChosenActionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ChosenActionTemplate', Template, 'ChosenAction_Training');
	Template.Category = "ChosenAction";
	Template.OnActivatedFn = ActivateTraining;
	Template.CanBePlayedFn = TrainingCanBePlayed;

	return Template;
}

//---------------------------------------------------------------------------------------
static function ActivateTraining(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local name OldTacticalTag, NewTacticalTag;

	ActionState = GetAction(InRef, NewGameState);
	ChosenState = GetChosen(ActionState.ChosenRef, NewGameState);

	// Grab Old Tactical Tag
	OldTacticalTag = ChosenState.GetMyTemplate().GetSpawningTag(ChosenState.Level);

	// Increase the Chosen's level
	ChosenState.Level++;
	NewTacticalTag = ChosenState.GetMyTemplate().GetSpawningTag(ChosenState.Level);

	// Only met, active chosen trigger the just leveled up popup
	if(ChosenState.bMetXCom && !ChosenState.bDefeated)
	{
		ChosenState.bJustLeveledUp = true;
	}

	// Replace Old Tag with new Tag in missions
	ChosenState.RemoveTacticalTagFromAllMissions(NewGameState, OldTacticalTag, NewTacticalTag);

	// Gain New Traits
	ChosenState.GainNewStrengths(NewGameState, class'XComGameState_AdventChosen'.default.NumStrengthsPerLevel);
}

//---------------------------------------------------------------------------------------
static function bool TrainingCanBePlayed(StateObjectReference InRef, optional XComGameState NewGameState = none)
{
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_ChosenAction ActionState;
	local StateObjectReference ActionRef;
	local bool bCantPlay;
	local int idx, ForceLevel;

	ChosenState = XComGameState_AdventChosen(NewGameState.GetGameStateForObjectID(InRef.ObjectID));

	if(ChosenState == none)
	{
		ChosenState = GetChosen(InRef);
	}

	// Cannot be first action after meeting XCOM
	if(ChosenState.bMetXCom)
	{
		bCantPlay = true;

		foreach ChosenState.PreviousMonthActions(ActionRef)
		{
			ActionState = GetAction(ActionRef);

			if(ActionState.GetMyTemplateName() != 'ChosenAction_Training')
			{
				bCantPlay = false;
				break;
			}
		}

		if(bCantPlay)
		{
			return false;
		}
	}

	if(!ChosenState.AtMaxLevel())
	{
		ForceLevel = GetAlienHQ().GetForceLevel();

		for(idx = 0; idx < default.ChosenLevelUpForceLevels.Length; idx++)
		{
			if(ChosenState.Level == idx && ForceLevel >= default.ChosenLevelUpForceLevels[idx])
			{
				return true;
			}
		}
	}

	return false;
}

//#############################################################################################
//----------------   SABOTAGE  ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateSabotageTemplate()
{
	local X2ChosenActionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ChosenActionTemplate', Template, 'ChosenAction_Sabotage');
	Template.Category = "ChosenAction";
	Template.OnActivatedFn = ActivateSabotage;
	Template.OnChooseActionFn = OnChooseSabotage;
	Template.PostActionPerformedFn = PostSabotage;

	return Template;
}

//---------------------------------------------------------------------------------------
static function ActivateSabotage(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local array<X2SabotageTemplate> ValidSabotageTypes;
	local X2SabotageTemplate SabotageType;

	ActionState = GetAction(InRef, NewGameState);
	ChosenState = GetChosen(ActionState.ChosenRef, NewGameState);
	ValidSabotageTypes = GetValidSabotageTypes();

	if(ValidSabotageTypes.Length > 0)
	{
		SabotageType = ValidSabotageTypes[`SYNC_RAND_STATIC(ValidSabotageTypes.Length)];
		ActionState.StoredTemplateName = SabotageType.DataName;

		if(ActionState.RollValue < GetSabotageChance(ChosenState))
		{
			ActionState.bActionFailed = false;
			if(SabotageType.OnActivatedFn != none)
			{
				SabotageType.OnActivatedFn(NewGameState, ActionState.GetReference());
			}
		}
		else
		{
			ActionState.bActionFailed = true;
		}
	}
	else
	{
		ActionState.bActionFailed = true;
	}
}

//---------------------------------------------------------------------------------------
private static function array<X2SabotageTemplate> GetValidSabotageTypes()
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2SabotageTemplate> ValidSabotageTypes;
	local X2SabotageTemplate SabotageTemplate;
	local array<X2StrategyElementTemplate> AllSabotageTemplates;
	local int idx;

	ValidSabotageTypes.Length = 0;
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	AllSabotageTemplates = StratMgr.GetAllTemplatesOfClass(class'X2SabotageTemplate');

	for(idx = 0; idx < AllSabotageTemplates.Length; idx++)
	{
		SabotageTemplate = X2SabotageTemplate(AllSabotageTemplates[idx]);

		if(SabotageTemplate.CanActivateFn == none || SabotageTemplate.CanActivateFn())
		{
			ValidSabotageTypes.AddItem(SabotageTemplate);
		}
	}

	return ValidSabotageTypes;
}

//---------------------------------------------------------------------------------------
static private function int GetSabotageChance(XComGameState_AdventChosen ChosenState)
{
	return `ScaleStrategyArrayInt(default.SabotageChance);
}

//---------------------------------------------------------------------------------------
static function OnChooseSabotage(XComGameState NewGameState, XComGameState_ChosenAction ActionState)
{
	ActionState.RollValue = `SYNC_RAND_STATIC(100);
}

//---------------------------------------------------------------------------------------
static function PostSabotage(StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetXComHQ();
	XComHQ.HandlePowerOrStaffingChange();

	`HQPRES.UIChosenSabotage(InRef);
}

//#############################################################################################
//----------------   DARK EVENT  --------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateDarkEventTemplate()
{
	local X2ChosenActionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ChosenActionTemplate', Template, 'ChosenAction_DarkEvent');
	Template.Category = "ChosenAction";
	Template.OnActivatedFn = ActivateDarkEvent;
	Template.CanBePlayedFn = DarkEventCanBePlayed;

	return Template;
}

//---------------------------------------------------------------------------------------
static function ActivateDarkEvent(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_ChosenAction ActionState;
	local XComGameState_HeadquartersAlien AlienHQ;

	ActionState = GetAction(InRef, NewGameState);
	AlienHQ = GetAlienHQ(NewGameState);
	AlienHQ.bAddChosenActionDarkEvent = true;
	AlienHQ.ChosenAddDarkEventRef = ActionState.ChosenRef;
}

//---------------------------------------------------------------------------------------
static function bool DarkEventCanBePlayed(StateObjectReference InRef, optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if(!ChosenState.bMetXCom)
		{
			return false;
		}
	}

	return true;
}

//#############################################################################################
//----------------   ASSAULT AVENGER  ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAvengerAssaultTemplate()
{
	local X2ChosenActionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ChosenActionTemplate', Template, 'ChosenAction_AvengerAssault');
	Template.Category = "ChosenAction";
	Template.OnActivatedFn = ActivateAvengerAssault;
	Template.PostActionPerformedFn = PostAssaultAvenger;
	Template.CanBePlayedFn = AvengerAssaultCanBePlayed;

	return Template;
}

//---------------------------------------------------------------------------------------
static function ActivateAvengerAssault(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2StrategyElementTemplateManager StratMgr;
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_MissionSiteChosenAssault ChosenAssaultSite;
	local X2MissionSourceTemplate MissionSource;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Reward RewardState;
	local array<XComGameState_Reward> MissionRewards;
	local XComGameState_WorldRegion RegionState;
	
	ActionState = GetAction(InRef, NewGameState);
	ChosenState = GetChosen(ActionState.ChosenRef, NewGameState);
	XComHQ = GetXComHQ(NewGameState);

	RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Region.ObjectID));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// Create Mission
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	MissionRewards.AddItem(RewardState);

	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_ChosenAvengerAssault'));
	ChosenAssaultSite = XComGameState_MissionSiteChosenAssault(NewGameState.CreateNewStateObject(class'XComGameState_MissionSiteChosenAssault'));
	ChosenAssaultSite.BuildMission(MissionSource, RegionState.Get2DLocation(), RegionState.GetReference(), MissionRewards, true, false);
	ChosenAssaultSite.AttackingChosen = ChosenState.GetReference();
	ChosenAssaultSite.ResistanceFaction = ChosenState.RivalFaction;

	ChosenAssaultSite.Location = XComHQ.Location;

	// Set XComHQ's location as this mission.
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.SavedLocation.ObjectID = XComHQ.CurrentLocation.ObjectID;
	XComHQ.CurrentLocation.ObjectID = ChosenAssaultSite.ObjectID;
	XComHQ.TargetEntity.ObjectID = ChosenAssaultSite.ObjectID; // Set this so the Avenger doesn't fly anywhere on ConfirmSelection

	// Store the assault site on the Chosen
	ChosenState.AssaultMissionRef = ChosenAssaultSite.GetReference();
	ChosenState.NumAvengerAssaults++;
}

//---------------------------------------------------------------------------------------
static function PostAssaultAvenger(StateObjectReference InRef)
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_MissionSiteChosenAssault ChosenAssaultSite;

	History = `XCOMHISTORY;
	ActionState = GetAction(InRef);
	ChosenState = GetChosen(ActionState.ChosenRef);
	ChosenAssaultSite = XComGameState_MissionSiteChosenAssault(History.GetGameStateForObjectID(ChosenState.AssaultMissionRef.ObjectID));

	if(ChosenAssaultSite != none)
	{
		// Force XComHQ to move to this mission site, but since we just set HQ to be at the site, the mission popup should trigger with no flight
		ChosenAssaultSite.ConfirmSelection();
	}
}

//---------------------------------------------------------------------------------------
static function bool AvengerAssaultCanBePlayed(StateObjectReference InRef, optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;
	local bool bPrevAssault;

	if(`StrategyDifficultySetting > 1)
	{
		return true;
	}

	History = `XCOMHISTORY;
	bPrevAssault = false;

	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if(ChosenState.NumAvengerAssaults > 0)
		{
			bPrevAssault = true;
			break;
		}
	}

	if(!bPrevAssault)
	{
		return true;
	}

	ChosenState = XComGameState_AdventChosen(NewGameState.GetGameStateForObjectID(InRef.ObjectID));

	if(ChosenState == none)
	{
		ChosenState = GetChosen(InRef);
	}

	return (ChosenState.MonthsAsRaider > 1);
}

//#############################################################################################
//----------------   HELPERS  -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function XComGameState_ChosenAction GetAction(StateObjectReference ActionRef, optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;

	if(NewGameState == none)
	{
		History = `XCOMHISTORY;
		ActionState = XComGameState_ChosenAction(History.GetGameStateForObjectID(ActionRef.ObjectID));
	}
	else
	{
		ActionState = XComGameState_ChosenAction(NewGameState.ModifyStateObject(class'XComGameState_ChosenAction', ActionRef.ObjectID));
	}

	return ActionState;
}

//---------------------------------------------------------------------------------------
static function XComGameState_AdventChosen GetChosen(StateObjectReference ChosenRef, optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;

	if(NewGameState == none)
	{
		History = `XCOMHISTORY;
		ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ChosenRef.ObjectID));
	}
	else
	{
		ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ChosenRef.ObjectID));
	}

	return ChosenState;
}

//---------------------------------------------------------------------------------------
static function XComGameState_HeadquartersAlien GetAlienHQ(optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(NewGameState != none)
	{
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	}

	return AlienHQ;
}

//---------------------------------------------------------------------------------------
static function XComGameState_HeadquartersXCom GetXComHQ(optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(NewGameState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	return XComHQ;
}