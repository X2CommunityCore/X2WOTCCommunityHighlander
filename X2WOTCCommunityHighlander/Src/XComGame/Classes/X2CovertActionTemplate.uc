//---------------------------------------------------------------------------------------
//  FILE:    X2CovertActionTemplate.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2CovertActionTemplate extends X2StrategyElementTemplate
	config(GameBoard);

// Data
var() string						OverworldMeshPath; // Used for its 3D map icon
var array<Name>						Narratives; // Potential narrative options for this Covert Action
var array<CovertActionSlot>			Slots;
var array<StrategyCostReward>		OptionalCosts;
var array<Name>						Risks;
var array<Name>						Rewards;
var StrategyCost					Cost; // If there is a required cost for this Covert Action
var EFactionInfluence				RequiredFactionInfluence; // The required influence with a faction needed to offer this Action
var bool							bGoldenPath; // If true, this Covert Action is part of the Golden Path and must appear at some point in the campaign
var bool							bUnique; // If true, this Covert Action can only be completed once per faction per game. GP Actions are automatically unique.
var bool							bForceCreation; // If true, this Covert Action will always be created if it is available
var bool							bMultiplesAllowed; // If true, this Covert Action can appear be presented by multiple factions at the same time
var bool							bDisplayIgnoresInfluence; // Will create and display this covert action even if the influence requirements are not met
var bool							bDisplayRequiresAvailable; // For non-golden path actions, displaying the Action always requires a check of its availability
var bool							bUseRewardImage; // Ignore any image set by the narrative, and instead use the reward image

// Config Data
var config array<int>				MinActionHours;
var config array<int>				MaxActionHours;

// Text
var localized String				ActionObjective;

// Functions
var Delegate<ChooseLocationDelegate> ChooseLocationFn;
var Delegate<OnStartedDelegate> OnStartedFn;

delegate ChooseLocationDelegate(XComGameState NewGameState, XComGameState_CovertAction ActionState, out array<StateObjectReference> ExcludeLocations);
delegate OnStartedDelegate(XComGameState NewGameState, XComGameState_CovertAction ActionState);

function XComGameState_CovertAction CreateInstanceFromTemplate(XComGameState NewGameState, StateObjectReference FactionRef)
{
	local XComGameState_CovertAction ActionState;

	ActionState = XComGameState_CovertAction(NewGameState.CreateNewStateObject(class'XComGameState_CovertAction', self));
	ActionState.PostCreateInit( NewGameState, FactionRef );

	return ActionState;
}

function bool AreActionRewardsAvailable(XComGameState_ResistanceFaction FactionState, optional XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2RewardTemplate RewardTemplate;
	local name RewardName;
	local bool bRewardsAvailable;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	bRewardsAvailable = true;

	foreach Rewards(RewardName)
	{
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(RewardName));
		if (RewardTemplate != none)
		{
			if (RewardTemplate.IsRewardAvailableFn != none && !RewardTemplate.IsRewardAvailableFn(NewGameState, FactionState.GetReference()))
			{
				bRewardsAvailable = false;
				break;
			}
		}
	}

	return bRewardsAvailable;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}