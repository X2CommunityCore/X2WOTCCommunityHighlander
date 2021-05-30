//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_CovertAction.uc
//  AUTHOR:  Joe Weinhoffer
//  PURPOSE: This object represents the instance data for a covert action on the world map
//   
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_CovertAction extends XComGameState_GeoscapeEntity
	config(GameBoard);

var() protected name                        m_TemplateName;
var() protected X2CovertActionTemplate		m_Template;

var() protected name						m_NarrativeTemplateName;
var() protected X2CovertActionNarrativeTemplate	m_NarrativeTemplate;

var() bool									bAvailable; // Is this Action available on the Geoscape
var() bool									bStarted; // Has this Action been started
var() bool									bCompleted; // Has this Action been completed
var() bool									bAmbushed; // Did this Action get ambushed
var() bool									bNeedsActionCompletePopup; // Does this Action need a popup so the player knows it finished
var() bool									bNeedsAmbushPopup; // Does this Action need a popup to alert the player an Ambush is happening
var() bool									bNewAction; // Flag for VO and popup alerts to indicate that this Covert Action was newly made available in the facility
var() bool									bBondmateDurationBonusApplied; // Are bondmates staffed on this Covert Action?

var() TDateTime								StartDateTime; // When did this Action begin
var() TDateTime								EndDateTime; // When does this Action end
var() float									HoursToComplete;

var() StateObjectReference					Faction; // The Faction who is running this action
var() StateObjectReference					LocationEntity; // The Geoscape entity where this action takes place
var() array<StateObjectReference>			RewardRefs; // Rewards given for completing the action
var() EFactionInfluence						RequiredFactionInfluence; // The required influence with a faction needed to unlock this Action

var() StateObjectReference					StoredRewardRef; // Save a unique reward object ref so it can be retrieved and referenced

var() config int							ChanceForIndividualSlotReward;
var() config int							ChanceToRequireFame;
var() config array<name>					RandomSoldierClasses; // Classes which can be selected randomly as soldier requirements
var() config name							ReduceRiskRewardName; // Template name for the reduce risk reward
var() config int							ReduceRiskAmount; // Amount each risk will be reduced if designated slots are filled
var() config int							MinCovertActionKills; // The minimum number of kills each soldier who goes on the Action will receive
var() config int							MaxCovertActionKills; // The maximum number of kills each soldier who goes on the Action will receive
var() config int							BondmateBonusHours; // The number of hours the duration will be reduced if bondmates are on the Covert Action

// Start Issue #485
var name									AmbushMissionSource; // The MissionSource of the Ambush for this Covert Action
// End Issue #485

// Start Issue #810
//
// Indicates whether the covert action rewards were given to the player
// on completion. By default this is `false`, indicating that the rewards
// *were* given.
//
// Note that this variable has no value until the covert action has been
// completed.
var privatewrite bool RewardsNotGivenOnCompletion;
// End Issue #810

struct CovertActionStaffSlot
{
	var() StateObjectReference				StaffSlotRef;
	var() StateObjectReference				RewardRef; // The reward granted by filling this slot
	var() bool								bFame; // Does this slot require a famous soldier
	var() bool								bOptional; // Is this slot optional to fill
};
var() array<CovertActionStaffSlot>			StaffSlots; //List of slots that units can be assigned to

struct CovertActionCostSlot
{
	var() StrategyCost						Cost; // An optional cost to earn more rewards
	var() StateObjectReference				RewardRef; // The reward granted by paying this cost
	var() bool								bPurchased; // Is this cost being purchased by the player
};
var() array<CovertActionCostSlot>			CostSlots;

struct CovertActionRisk
{
	var() name								RiskTemplateName;
	var() StateObjectReference				Target;
	var() int								ChanceToOccur;
	var() int								ChanceToOccurModifier;
	var() bool								bOccurs;
	var() int								Level;
};
var() array<CovertActionRisk>				Risks; // Risks associated with completing this action
var() array<name>							NegatedRisks; // Risks which have been negated by staffing

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

//---------------------------------------------------------------------------------------
simulated function X2CovertActionTemplate GetMyTemplate()
{
	if (m_Template == none)
	{
		m_Template = X2CovertActionTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
simulated function name GetMyNarrativeTemplateName()
{
	return m_NarrativeTemplateName;
}

//---------------------------------------------------------------------------------------
simulated function X2CovertActionNarrativeTemplate GetMyNarrativeTemplate()
{
	if (m_NarrativeTemplate == none)
	{
		m_NarrativeTemplate = X2CovertActionNarrativeTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_NarrativeTemplateName));
	}
	return m_NarrativeTemplate;
}

//---------------------------------------------------------------------------------------
event OnCreation(optional X2DataTemplate Template)
{
	super.OnCreation( Template );

	m_Template = X2CovertActionTemplate(Template);
	m_TemplateName = Template.DataName;
}

simulated function PostCreateInit( XComGameState NewGameState, StateObjectReference FactionRef )
{
	Faction = FactionRef;

	ChooseNarrative();
	CreateRisks(); // Create risks before staff and cost slots, so they can choose one to negate if necessary
	CreateStaffSlots( GetParentGameState() );
	CreateCostSlots( GetParentGameState() );

	UpdateNegatedRisks(NewGameState); // Negate any risks based on dark events or Res HQ Ambush prevention
}

function Spawn(XComGameState NewGameState, optional out array<StateObjectReference> ExcludeLocations)
{
	bAvailable = true;

	SetTimer();
	ChooseLocation(NewGameState, ExcludeLocations);
	GenerateRewards(NewGameState);
}

//---------------------------------------------------------------------------------------
function bool HasCost()
{
	return (GetMyTemplate().Cost.ResourceCosts.Length > 0 || GetMyTemplate().Cost.ArtifactCosts.Length > 0);
}

//---------------------------------------------------------------------------------------
private function ChooseNarrative()
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionTemplate ActionTemplate;
	local X2CovertActionNarrativeTemplate NarrativeTemplate;
	local array<X2CovertActionNarrativeTemplate> NoFactionNarratives;
	local name NarrativeName, FactionName;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ActionTemplate = GetMyTemplate();
	FactionName = GetFaction().GetMyTemplateName();

	foreach ActionTemplate.Narratives(NarrativeName)
	{
		NarrativeTemplate = X2CovertActionNarrativeTemplate(StratMgr.FindStrategyElementTemplate(NarrativeName));
		if (NarrativeTemplate.AssociatedFaction == FactionName)
		{
			m_NarrativeTemplate = NarrativeTemplate;
			m_NarrativeTemplateName = NarrativeTemplate.DataName;
			return;
		}
		else if (NarrativeTemplate.AssociatedFaction == '')
		{
			NoFactionNarratives.AddItem(NarrativeTemplate);
		}
	}

	// If no narrative for the specific faction was found, randomly choose a non-associated narrative
	if (NoFactionNarratives.Length > 0)
	{
		NarrativeTemplate = NoFactionNarratives[`SYNC_RAND(NoFactionNarratives.Length)];
		m_NarrativeTemplate = NarrativeTemplate;
		m_NarrativeTemplateName = NarrativeTemplate.DataName;
	}
	else
	{
		`RedScreen("@jweinhoffer Could not find CovertActionNarrativeTemplate for " @ GetMyTemplate().ActionObjective @ "associated with faction" @ GetFaction().GetFactionTitle());
	}
}

//---------------------------------------------------------------------------------------
// Sets the action's duration and despawn datetime under the current conditions
private function SetTimer()
{
	local XComGameState_HeadquartersResistance ResHQ;

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	HoursToComplete = GetMinDaysToComplete() + `SYNC_RAND(GetMaxDaysToComplete() - GetMinDaysToComplete() + 1);
	HoursToComplete *= ResHQ.CovertActionDurationModifier;
}

//---------------------------------------------------------------------------------------
private function ChooseLocation(XComGameState NewGameState, out array<StateObjectReference> ExcludeLocations)
{
	local XComGameState_WorldRegion ActionLocation;

	if (GetMyTemplate().ChooseLocationFn != none)
	{
		GetMyTemplate().ChooseLocationFn(NewGameState, self, ExcludeLocations);

		ActionLocation = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(LocationEntity.ObjectID));
		Region = ActionLocation.Region; // Set the region of this Action to be the same as its target location
		Continent = ActionLocation.Continent;
		ExcludeLocations.AddItem(ActionLocation.GetReference());
		bNeedsLocationUpdate = true; // This will cause the CA to generate a random location in the region, or continent
	}
	else
	{
		`RedScreen("CovertActionTemplate does not have a ChooseLocationFn - @jweinhoffer: " $ GetMyTemplate().Name);
	}
}

public function string GetLocationDisplayString()
{
	return GetWorldRegion().GetDisplayName();
}

//#############################################################################################
//----------------------------- STAFF SLOTS ---------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
private function CreateStaffSlots(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2StaffSlotTemplate StaffSlotTemplate;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_Reward RewardState;
	local CovertActionSlot TemplateSlot;
	local CovertActionStaffSlot Slot;
	local array<int> PersonalRewardSlots;
	local int i, IndividualRewardIndex;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	StaffSlots.Length = 0;
	
	// Choose a non-optional personnel slot to give a personal reward
	for (i = 0; i < GetMyTemplate().Slots.Length; i++)
	{
		TemplateSlot = GetMyTemplate().Slots[i];
		if (TemplateSlot.Rewards.Length > 0)
		{
			PersonalRewardSlots.AddItem(i); // Save the slot index which can have a personal reward
		}
	}
	IndividualRewardIndex = PersonalRewardSlots[`SYNC_RAND(PersonalRewardSlots.Length)]; // Grab an eligible personal reward slot index

	for (i = 0; i < GetMyTemplate().Slots.Length; i++)
	{
		TemplateSlot = GetMyTemplate().Slots[i];
		StaffSlotTemplate = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate(TemplateSlot.StaffSlot));

		if (StaffSlotTemplate != none)
		{
			StaffSlotState = StaffSlotTemplate.CreateInstanceFromTemplate(NewGameState);
			StaffSlotState.CovertAction = GetReference(); //make sure the staff slot knows which covert action it is in
			
			// Reset values for each iteration
			Slot.bOptional = false;
			Slot.bFame = false;
			Slot.RewardRef.ObjectID = 0;
			
			// If this slot reduces overall covert action risks, substitute in the risk reduction reward			
			if (TemplateSlot.bReduceRisk)
			{
				RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(default.ReduceRiskRewardName));
				Slot.bOptional = true; // All risk reduction slots are optional
			}
			else if(i == IndividualRewardIndex) // If this is the selected personal reward slot
			{
				// Roll for a reward for this individual staff slot
				RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(TemplateSlot.Rewards[`SYNC_RAND(TemplateSlot.Rewards.Length)]));
			}
			else
			{
				RewardTemplate = none; // Make sure the template gets cleared from previous slots if not picked again
			}

			if (RewardTemplate != none)
			{
				RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
				RewardState.GenerateReward(NewGameState, 1.0, GetReference());
				Slot.RewardRef = RewardState.GetReference();
			}

			// Make sure the rank requirement of the new staff slot matches the template
			StaffSlotState.RequiredMinRank = TemplateSlot.iMinRank;

			// Determine class if one is required
			if (TemplateSlot.bFactionClass)
			{
				StaffSlotState.RequiredClass = GetFaction().GetChampionClassName();
			}
			else if (TemplateSlot.bRandomClass)
			{
				StaffSlotState.RequiredClass = default.RandomSoldierClasses[`SYNC_RAND(default.RandomSoldierClasses.Length)];
			}

			// Roll to see if the slot requires a famous soldier
			if (TemplateSlot.bChanceFame && class'X2StrategyGameRulesetDataStructures'.static.Roll(default.ChanceToRequireFame))
			{
				StaffSlotState.bRequireFamous = true;
				Slot.bFame = true;
			}
			
			Slot.StaffSlotRef = StaffSlotState.GetReference();
			StaffSlots.AddItem(Slot);
		}
	}
}

//---------------------------------------------------------------------------------------
function RemoveStaffedUnitsFromSquad(XComGameState NewGameState)
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectPsiTraining PsiProjectState;
	local StateObjectReference EmptyRef;
	local int i, SquadIndex;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			UnitState = StaffSlot.GetAssignedStaff();
			
			// If the unit is currently in the the squad, remove them
			SquadIndex = XComHQ.Squad.Find('ObjectID', UnitState.ObjectID);
			if (SquadIndex != INDEX_NONE)
			{
				XComHQ.Squad[SquadIndex] = EmptyRef;
			}
			
			if (!HasAmbushRisk() && !UnitState.bIsSuperSoldier
				&& !class'CHHelpers'.default.bDontUnequipCovertOps) // Issue #153
			{
				// Drop all of the unit's unique items if there is no chance of an Ambush
				UnitState.MakeItemsAvailable(NewGameState, true);
			}

			// Stop any in-progress Psi Training
			PsiProjectState = XComHQ.GetPsiTrainingProject(UnitState.GetReference());
			if (PsiProjectState != none) // A Psi Training project was found for the unit
			{
				// Pause the training project.
				// Don't need to empty the psi slot, since the soldier is already staffed on the Action
				PsiProjectState = XComGameState_HeadquartersProjectPsiTraining(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectPsiTraining', PsiProjectState.ObjectID));
				PsiProjectState.bForcePaused = true;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function EmptyAllStaffSlots(XComGameState NewGameState)
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			StaffSlot.EmptySlot(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
function bool IsVeteranRequired()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.RequiredMinRank >= 3)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function UpdateDurationForBondmates(XComGameState NewGameState)
{
	local XComGameState_StaffSlot SlotStateA, SlotStateB;
	local XComGameState_Unit UnitStateA, UnitStateB;
	local StateObjectReference BondmateRef;
	local SoldierBond BondData;
	local int i, j;
	local bool bBondmatesFound;

	// Calculate the overall risk modification score based on filled staff slots which reduce risks
	for (i = 0; i < (StaffSlots.Length - 1); i++)
	{
		SlotStateA = XComGameState_StaffSlot(NewGameState.GetGameStateForObjectID(StaffSlots[i].StaffSlotRef.ObjectID));
		if (SlotStateA == none) // If the staff slot was not found in the new game state, grab it from the history
		{
			SlotStateA = GetStaffSlot(i);
		}

		if (SlotStateA.IsSoldierSlot() && SlotStateA.IsSlotFilled())
		{
			UnitStateA = SlotStateA.GetAssignedStaff();
			if (UnitStateA.HasSoldierBond(BondmateRef, BondData))
			{
				for (j = (i + 1); j < StaffSlots.Length; j++)
				{
					SlotStateB = XComGameState_StaffSlot(NewGameState.GetGameStateForObjectID(StaffSlots[j].StaffSlotRef.ObjectID));
					if (SlotStateB == none) // If the staff slot was not found in the new game state, grab it from the history
					{
						SlotStateB = GetStaffSlot(j);
					}

					if (SlotStateB.IsSoldierSlot() && SlotStateB.IsSlotFilled())
					{
						UnitStateB = SlotStateB.GetAssignedStaff();

						if (UnitStateB.ObjectID == BondmateRef.ObjectID && BondData.BondLevel >= class'X2Ability_DefaultBondmateAbilities'.default.CovertOperatorsBondLevel)
						{
							// Both bondmates are staffed in this Covert Action, so reduce the duration by 24 hours
							bBondmatesFound = true;
							break;
						}
					}
				}
			}
		}
	}

	if (bBondmatesFound && !bBondmateDurationBonusApplied)
	{
		// Don't let time to complete be less than 0
		HoursToComplete = max(HoursToComplete - BondmateBonusHours, 0);
		bBondmateDurationBonusApplied = true;
	}
	else if (!bBondmatesFound && bBondmateDurationBonusApplied)
	{
		HoursToComplete += BondmateBonusHours;
		bBondmateDurationBonusApplied = false;
	}
}

//#############################################################################################
//------------------------------ COST SLOTS ---------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
private function CreateCostSlots(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Reward RewardState;
	local CovertActionCostSlot Slot;
	local StrategyCostReward OptionalCost;
	local int i;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CostSlots.Length = 0;

	for (i = 0; i < GetMyTemplate().OptionalCosts.Length; i++)
	{
		OptionalCost = GetMyTemplate().OptionalCosts[i];
		
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(OptionalCost.Reward));
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		RewardState.GenerateReward(NewGameState, TriggerOverrideCostScalar(RewardState, 0.5), GetReference()); // Issue #807 - trigger call added
		
		Slot.Cost = OptionalCost.Cost;
		Slot.RewardRef = RewardState.GetReference();
		CostSlots.AddItem(Slot);
	}
}

//---------------------------------------------------------------------------------------
function string GetCostSlotImage(int idx)
{
	local X2ItemTemplateManager ItemMgr;
	local X2ItemTemplate ItemTemplate;
	local StrategyCost Cost;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	Cost = CostSlots[idx].Cost;
	if (Cost.ArtifactCosts.Length > 0)
	{
		ItemTemplate = ItemMgr.FindItemTemplate(Cost.ArtifactCosts[0].ItemTemplateName);
	}
	else if (Cost.ResourceCosts.Length > 0)
	{
		ItemTemplate = ItemMgr.FindItemTemplate(Cost.ResourceCosts[0].ItemTemplateName);
	}

	if (ItemTemplate != none)
	{
		if (ItemTemplate.strInventoryImage != "")
		{
			return ItemTemplate.strInventoryImage;
		}
		else
		{
			return ItemTemplate.strImage;
		}
	}
	
	return "";
}

//---------------------------------------------------------------------------------------
function ResetAllCostSlots(XComGameState NewGameState)
{
	local int i;

	for (i = 0; i < CostSlots.Length; ++i)
	{
		CostSlots[i].bPurchased = false;
		UpdateNegatedRisks(NewGameState);
	}
}

//#############################################################################################
//----------------   REWARDS   ---------------------------------------------------------
//#############################################################################################

private function GenerateRewards(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local array<name> RewardTypes;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTypes = GetMyTemplate().Rewards;
	RewardRefs.Length = 0; // Reset the rewards
	
	// And also has a list of unique rewards based on its template
	for (idx = 0; idx < RewardTypes.Length; idx++)
	{
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(RewardTypes[idx]));
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		RewardState.GenerateReward(NewGameState, TriggerOverrideRewardScalar(RewardState, 0.5), GetReference()); // Issue #807 - trigger call added
		RewardRefs.AddItem(RewardState.GetReference());
	}
}

// Start Issue #807
/// HL-Docs: feature:CovertAction_OverrideCostScalar; issue:807; tags:strategy
/// Allows listeners to override the multiplier covert actions use to determine
/// how many resources an optional cost requires. The game uses 0.5 by default,
/// which means CAs need half the supplies/intel/etc. you would get from a POI
/// as the cost to mitigate a risk.
///
/// ```event
/// EventID: CovertAction_OverrideCostScalar,
/// EventData: [
///     inout float DefaultCostScalar,
///     in XComGameState_Reward RewardState
/// ],
/// EventSource: XComGameState_CovertAction (ActionState),
/// NewGameState: none
/// ```
private function float TriggerOverrideCostScalar(XComGameState_Reward RewardState, float DefaultCostScalar)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'CovertAction_OverrideCostScalar';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVFloat;
	OverrideTuple.Data[0].f = DefaultCostScalar;
	OverrideTuple.Data[1].kind = XComLWTVObject;
	OverrideTuple.Data[1].o = RewardState;

	`XEVENTMGR.TriggerEvent(OverrideTuple.Id, OverrideTuple, self);

	return OverrideTuple.Data[0].f;
}

/// HL-Docs: feature:CovertAction_OverrideRewardScalar; issue:807; tags:strategy
/// Allows listeners to override the multiplier covert actions use to determine
/// how many resources to award. The game uses 0.5 by default, which means CAs
/// award half the supplies/intel/etc. you would get from a POI.
///
/// ```event
/// EventID: CovertAction_OverrideRewardScalar,
/// EventData: [
///     inout float DefaultRewardScalar,
///     in XComGameState_Reward RewardState
/// ],
/// EventSource: XComGameState_CovertAction (ActionState),
/// NewGameState: none
/// ```
private function float TriggerOverrideRewardScalar(XComGameState_Reward RewardState, float DefaultRewardScalar)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'CovertAction_OverrideRewardScalar';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVFloat;
	OverrideTuple.Data[0].f = DefaultRewardScalar;
	OverrideTuple.Data[1].kind = XComLWTVObject;
	OverrideTuple.Data[1].o = RewardState;

	`XEVENTMGR.TriggerEvent(OverrideTuple.Id, OverrideTuple, self);

	return OverrideTuple.Data[0].f;
}
// End Issue #807

function GiveRewards(XComGameState NewGameState)
{
	local XComGameState_Reward RewardState;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> BondedSoldiers;
	local int idx;

	// Issue #438 Start
	if (TriggerPreventGiveRewards())
	{
		RewardsNotGivenOnCompletion = true;
		return;
	}
	// Issue #438 End

	// First give the general Covert Action reward
	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(RewardRefs[idx].ObjectID));
		RewardState.GiveReward(NewGameState, GetReference());
	}

	// Then give all of the individual rewards
	for (idx = 0; idx < StaffSlots.Length; idx++)
	{
		SlotState = GetStaffSlot(idx);
		if (SlotState.IsSlotFilled())
		{
			// Give every soldier who went on the Covert Action a few kills
			// Do this before the individual rewards, so if they earned a promotion reward the kills are set to the promotion rank level
			UnitState = SlotState.GetAssignedStaff();
			if (UnitState.IsSoldier() && UnitState.IsAlive() && !UnitState.bCaptured)
			{
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				UnitState.NonTacticalKills += default.MinCovertActionKills + `SYNC_RAND(default.MaxCovertActionKills - default.MinCovertActionKills + 1);
				BondedSoldiers.AddItem(UnitState);
			}

			if (StaffSlots[idx].RewardRef.ObjectID != 0)
			{
				RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(StaffSlots[idx].RewardRef.ObjectID));
				RewardState.GiveReward(NewGameState, SlotState.GetAssignedStaffRef()); // Give the reward to the staffed unit
			}
		}
	}

	// Increase the Cohesion between all soldiers who went on the Covert Action (and survived)
	class'XComGameStateContext_StrategyGameRule'.static.AdjustSoldierBonds(BondedSoldiers);

	// And give all of the rewards for cost options the player payed for
	for (idx = 0; idx < CostSlots.Length; idx++)
	{		
		if (CostSlots[idx].bPurchased)
		{
			RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(CostSlots[idx].RewardRef.ObjectID));
			RewardState.GiveReward(NewGameState, Region);
		}
	}
}

// Start Issue #438, #810
/// HL-Docs: feature:CovertAction_PreventGiveRewards; issue:438; tags:strategy
/// Fires an event that allows listeners to prevent the covert action from
/// awarding the action's rewards to the player. Note that if the `PreventGiveRewards`
/// boolean is `true` then not only are the rewards not given, but the soldiers
/// on the covert action get no XP or cohesion. The results are saved and are used to adjust UI later.
///
/// ```event
/// EventID: CovertAction_PreventGiveRewards,
/// EventData: [ inout bool PreventGiveRewards ],
/// EventSource: XComGameState_CovertAction (CAState),
/// NewGameState: none
/// ```
private function bool TriggerPreventGiveRewards()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertAction_PreventGiveRewards';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false;

	`XEVENTMGR.TriggerEvent('CovertAction_PreventGiveRewards', Tuple, self);

	return Tuple.Data[0].b;
}
// End Issue #438, #810

//---------------------------------------------------------------------------------------
function string GetRewardDescriptionString()
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local string strRewards;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRefs[idx].ObjectID));

		if (RewardState != none)
		{
			strRewards $= RewardState.GetRewardPreviewString();

			if (idx < (RewardRefs.Length - 1))
			{
				strRewards $= ", ";
			}
		}
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strRewards);
}

//---------------------------------------------------------------------------------------
function string GetRewardDetailsString()
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local string strRewards, strRewardDetails;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRefs[idx].ObjectID));

		if (RewardState != none)
		{
			strRewardDetails = RewardState.GetRewardDetailsString();
			
			if (strRewardDetails != "")
			{
				if (strRewards != "")
				{
					strRewards $= ", ";
				}
				
				strRewards $= strRewardDetails;
			}
		}
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strRewards);
}

//---------------------------------------------------------------------------------------
function string GetRewardValuesString()
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local string strRewards;
	local int idx;

	History = `XCOMHISTORY;
	
	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRefs[idx].ObjectID));

		if (RewardState != none)
		{
			strRewards $= RewardState.GetRewardString();

			if (idx < (RewardRefs.Length - 1))
			{
				strRewards $= ", ";
			}
		}
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strRewards);
}

//---------------------------------------------------------------------------------------
function string GetRewardSavedString()
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local string strRewards;
	local int idx;

	History = `XCOMHISTORY;

		for (idx = 0; idx < RewardRefs.Length; idx++)
		{
			RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRefs[idx].ObjectID));

			if (RewardState != none)
			{
				strRewards $= RewardState.RewardString;

				if (idx < (RewardRefs.Length - 1))
				{
					strRewards $= ", ";
				}
			}
		}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strRewards);
}

//---------------------------------------------------------------------------------------
function string GetRewardImage()
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRefs[idx].ObjectID));

		if (RewardState != none)
		{
			return RewardState.GetRewardImage();
		}
	}

	return "";
}

//---------------------------------------------------------------------------------------
function string GetRewardIconString()
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRefs[idx].ObjectID));

		if (RewardState != none)
		{
			return RewardState.GetRewardIcon();
		}
	}

	return "";
}

//---------------------------------------------------------------------------------------
function CleanUpRewards(XComGameState NewGameState)
{
	local bool bStartState;
	local int idx;

	bStartState = (NewGameState.GetContext().IsStartState());
	
	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		CleanUpReward(NewGameState, bStartState, RewardRefs[idx]);
	}

	for (idx = 0; idx < StaffSlots.Length; idx++)
	{
		CleanUpReward(NewGameState, bStartState, StaffSlots[idx].RewardRef);
	}

	for (idx = 0; idx < CostSlots.Length; idx++)
	{
		CleanUpReward(NewGameState, bStartState, CostSlots[idx].RewardRef);
	}
}

//---------------------------------------------------------------------------------------
private function CleanUpReward(XComGameState NewGameState, bool bStartState, StateObjectReference RewardRef)
{
	local XComGameState_Reward RewardState;

	if (bStartState)
	{
		RewardState = XComGameState_Reward(NewGameState.GetGameStateForObjectID(RewardRef.ObjectID));
	}
	else
	{
		RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(RewardRef.ObjectID));
	}

	if (RewardState != none)
	{
		RewardState.CleanUpReward(NewGameState);
	}
}

//#############################################################################################
//----------------------   RISKS	-----------------------------------------------------------
//#############################################################################################

private function CreateRisks()
{
	local XComGameState_HeadquartersResistance ResHQ;
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionRiskTemplate RiskTemplate;
	local array<name> RiskNames;
	local name DarkEventRiskName;
	local bool bChosenIncreaseRisks, bDarkEventRisk;
	local int idx;

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	
	RiskNames = GetMyTemplate().Risks;
	bChosenIncreaseRisks = GetFaction().GetRivalChosen().ShouldIncreaseCovertActionRisks();
	
	for (idx = 0; idx < RiskNames.Length; idx++)
	{
		RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(RiskNames[idx]));
		if (RiskTemplate.IsRiskAvailableFn == none || RiskTemplate.IsRiskAvailableFn(GetFaction()))
		{
			bDarkEventRisk = false;
			if (ResHQ.CovertActionDarkEventRisks.Find(RiskNames[idx]) != INDEX_NONE)
			{
				bDarkEventRisk = true;
			}

			AddRisk(RiskTemplate, bChosenIncreaseRisks, bDarkEventRisk);
		}
	}

	// Since this is a new Covert Action, ensure it has any Dark Event risks
	bDarkEventRisk = true;
	foreach ResHQ.CovertActionDarkEventRisks(DarkEventRiskName)
	{
		if (RiskNames.Find(DarkEventRiskName) == INDEX_NONE)
		{
			// The Risk is not part of the Action by default, so add it
			RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(DarkEventRiskName));
			if (TriggerAllowDarkEventRisk(RiskTemplate, true)) // Issue #692
			{
				AddRisk(RiskTemplate, bChosenIncreaseRisks, bDarkEventRisk);
			}
		}
	}
}

private function AddRisk(X2CovertActionRiskTemplate RiskTemplate, bool bChosenIncreaseRisks, bool bDarkEventRisk)
{
	local CovertActionRisk NewRisk;
		
	NewRisk.RiskTemplateName = RiskTemplate.DataName;
	NewRisk.ChanceToOccur = (RiskTemplate.MinChanceToOccur + `SYNC_RAND(RiskTemplate.MaxChanceToOccur - RiskTemplate.MinChanceToOccur + 1));
	NewRisk.ChanceToOccurModifier = CalculateRiskChanceToOccurModifiers(NewRisk, bChosenIncreaseRisks, bDarkEventRisk);
	NewRisk.Level = GetRiskLevel(NewRisk); // Get the risk level based on the chance to occur (not whether it actually does)

	Risks.AddItem(NewRisk);
}

// Issue #436: CHL function modified: first parameter changed from "int ChanceToOccur" to "CovertActionRisk ActionRisk"
private function int CalculateRiskChanceToOccurModifiers(CovertActionRisk ActionRisk, bool bChosenIncreaseRisks, bool bDarkEventRisk)
{
	local int ChanceToOccurModifier;
	local XComLWTuple Tuple; // Issue #436

	if (bChosenIncreaseRisks)
	{
		// Increase the chance to occur if the rival Chosen is increasing risks
		ChanceToOccurModifier += class'XComGameState_AdventChosen'.default.CovertActionRiskIncrease;
	}

	// Issue #436 Start
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertActionRisk_AlterChanceModifier';
	Tuple.Data.Add(5);
	Tuple.Data[0].kind = XComLWTVName;
	Tuple.Data[0].n = ActionRisk.RiskTemplateName;
	Tuple.Data[1].kind = XComLWTVInt;
	Tuple.Data[1].i = ActionRisk.ChanceToOccur;
	Tuple.Data[2].kind = XComLWTVBool;
	Tuple.Data[2].b = bChosenIncreaseRisks;
	Tuple.Data[3].kind = XComLWTVBool;
	Tuple.Data[3].b = bDarkEventRisk;
	Tuple.Data[4].kind = XComLWTVInt;
	Tuple.Data[4].i = ChanceToOccurModifier;

	`XEVENTMGR.TriggerEvent('CovertActionRisk_AlterChanceModifier', Tuple, self);

	return Tuple.Data[4].i;
	// Issue #436 End
}

// Issue #436 Start: This function must be called if you are using CovertActionRisk_AlterChanceModifier:
// This class internally caches the risks and will not be aware of anything that might change the behavior
// of your listener function. Call this function whenever you observe a change that affects the output of
// your CovertActionRisk_AlterChanceModifier listener.
function RecalculateRiskChanceToOccurModifiers()
{
	local XComGameState_HeadquartersResistance ResHQ;
	local X2StrategyElementTemplateManager StratMgr;
	local bool bChosenIncreaseRisks, bDarkEventRisk;
	local X2CovertActionRiskTemplate RiskTemplate;
	local int idx;

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for (idx = 0; idx < Risks.Length; idx++)
	{
		bChosenIncreaseRisks = GetFaction().GetRivalChosen().ShouldIncreaseCovertActionRisks();
		RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(Risks[idx].RiskTemplateName));
		if (RiskTemplate.IsRiskAvailableFn == none || RiskTemplate.IsRiskAvailableFn(GetFaction()))
		{
			bDarkEventRisk = false;
			if (ResHQ.CovertActionDarkEventRisks.Find(Risks[idx].RiskTemplateName) != INDEX_NONE)
			{
				bDarkEventRisk = true;
			}
		}

		Risks[idx].ChanceToOccurModifier = CalculateRiskChanceToOccurModifiers(Risks[idx], bChosenIncreaseRisks, bDarkEventRisk);
		// Start Issue #777
		//
		// Covert action risk level will now be updated when a risk's chance to occur
		// is recalculated, which ensures the risks panel displays the correct chance.
		Risks[idx].Level = GetRiskLevel(Risks[idx]);
		// End Issue #777
	}
}
// Issue #436 End

function EnableDarkEventRisk(name DarkEventRiskName)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionRiskTemplate RiskTemplate;
	local CovertActionRisk ActionRisk;
	local array<name> RiskNames;
	local bool bChosenIncreaseRisks;
	local int idx;
		
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(DarkEventRiskName));
	
	// Only add or modify risks which are available
	if (TriggerAllowDarkEventRisk(RiskTemplate, false)) // Issue #436
	{
		RiskNames = GetMyTemplate().Risks;
		bChosenIncreaseRisks = GetFaction().GetRivalChosen().ShouldIncreaseCovertActionRisks();

		// If the Risk is not a part of the default template, add it
		if (RiskNames.Find(DarkEventRiskName) == INDEX_NONE)
		{
			AddRisk(RiskTemplate, bChosenIncreaseRisks, true);
		}
		else // Otherwise search through the existing risks to modify the chance to occur
		{
			for (idx = 0; idx < Risks.Length; idx++)
			{
				ActionRisk = Risks[idx];
				if (ActionRisk.RiskTemplateName == DarkEventRiskName)
				{
					// The Risk is part of the default template, so recalculate its chance to occur modifiers and level				
					// Issue #436: Changed first parameter
					ActionRisk.ChanceToOccurModifier = CalculateRiskChanceToOccurModifiers(ActionRisk, bChosenIncreaseRisks, true);
					ActionRisk.Level = GetRiskLevel(ActionRisk);
					Risks[idx] = ActionRisk; // Resave the risk with the updated data
					break;
				}
			}
		}
	}
}

// Start issues #436, #692
private function bool TriggerAllowDarkEventRisk (X2CovertActionRiskTemplate RiskTemplate, bool bSetup)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'AllowDarkEventRisk';
	Tuple.Data.Add(3);
	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].o = RiskTemplate;
	Tuple.Data[1].kind = XComLWTVBool;
	Tuple.Data[1].b = RiskTemplate.IsRiskAvailableFn == none || RiskTemplate.IsRiskAvailableFn(GetFaction()); // Vanilla logic
	Tuple.Data[2].kind = XComLWTVBool;
	Tuple.Data[2].b = bSetup;

	`XEVENTMGR.TriggerEvent('AllowDarkEventRisk', Tuple, self);

	return Tuple.Data[1].b;
}
// End issues #436, #692

function DisableDarkEventRisk(name DarkEventRiskName)
{
	local CovertActionRisk ActionRisk;
	local array<name> RiskNames;
	local bool bChosenIncreaseRisks;
	local int idx;
	
	RiskNames = GetMyTemplate().Risks;
	bChosenIncreaseRisks = GetFaction().GetRivalChosen().ShouldIncreaseCovertActionRisks();

	for (idx = 0; idx < Risks.Length; idx++)
	{
		ActionRisk = Risks[idx];
		if (ActionRisk.RiskTemplateName == DarkEventRiskName )
		{
			if (RiskNames.Find(DarkEventRiskName) == INDEX_NONE)
			{
				// If the Risk exists and is not a default risk for this Action, remove it
				Risks.Remove(idx, 1);
			}
			else
			{
				// The Risk is part of the default template, so recalculate its chance to occur and level
				// Issue #436: Changed first parameter
				ActionRisk.ChanceToOccurModifier = CalculateRiskChanceToOccurModifiers(ActionRisk, bChosenIncreaseRisks, false);
				ActionRisk.Level = GetRiskLevel(ActionRisk);
				Risks[idx] = ActionRisk; // Resave the risk with the updated data				
			}
			
			break; // Found the Risk which was added by the Dark Event, so no need to continue
		}
	}
}

function UpdateNegatedRisks(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_Reward RewardState;
	local XComGameState_StaffSlot SlotState;
	local X2CovertActionRiskTemplate RiskTemplate;
	local array<name> RiskNames;
	local int idx;

	// Start by clearing the list
	NegatedRisks.Length = 0;
	
	// Calculate the overall risk modification score based on filled staff slots which reduce risks
	for (idx = 0; idx < StaffSlots.Length; idx++)
	{
		RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(StaffSlots[idx].RewardRef.ObjectID));
		if (RewardState != none && RewardState.GetMyTemplate().DataName == default.ReduceRiskRewardName)
		{
			SlotState = XComGameState_StaffSlot(NewGameState.GetGameStateForObjectID(StaffSlots[idx].StaffSlotRef.ObjectID));
			if (SlotState == none) // If the staff slot was not found in the new game state, grab it from the history
			{
				SlotState = GetStaffSlot(idx);
			}

			if (SlotState.IsSlotFilled() && NegatedRisks.Find(RewardState.RewardObjectTemplateName) == INDEX_NONE)
			{
				NegatedRisks.AddItem(RewardState.RewardObjectTemplateName);
			}
		}
	}

	// Calculate the overall risk modification score based on filled staff slots which reduce risks
	for (idx = 0; idx < CostSlots.Length; idx++)
	{
		RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(CostSlots[idx].RewardRef.ObjectID));
		if (RewardState != none && RewardState.GetMyTemplate().DataName == default.ReduceRiskRewardName)
		{
			if (CostSlots[idx].bPurchased && NegatedRisks.Find(RewardState.RewardObjectTemplateName) == INDEX_NONE)
			{
				NegatedRisks.AddItem(RewardState.RewardObjectTemplateName);
			}
		}
	}
	
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		break;
	}	
	if (ResHQ == none)
	{
		ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	}

	// Check for Resistance Order which can prevent ambush, and add it to the negated list if the Order is active and it hasn't been negated
	if (!ResHQ.CanCovertActionsBeAmbushed())
	{
		if (NegatedRisks.Find('CovertActionRisk_Ambush') == INDEX_NONE)
		{
			NegatedRisks.AddItem('CovertActionRisk_Ambush');
		}
	}

	// Finally ensure that all of the risks which were originally created are still available, and negate them if not
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RiskNames = GetMyTemplate().Risks;
	for (idx = 0; idx < RiskNames.Length; idx++)
	{
		if (NegatedRisks.Find(RiskNames[idx]) == INDEX_NONE)
		{
			RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(RiskNames[idx]));
			if (RiskTemplate.IsRiskAvailableFn != none && !RiskTemplate.IsRiskAvailableFn(GetFaction(), NewGameState))
			{
				NegatedRisks.AddItem(RiskNames[idx]);
			}
		}
	}
}

function bool IsRewardRiskNegated(StateObjectReference RewardRef)
{
	local XComGameState_Reward RewardState;

	RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(RewardRef.ObjectID));
	if (RewardState != none && NegatedRisks.Find(RewardState.RewardObjectTemplateName) != INDEX_NONE)
	{
		return true;
	}

	return false;
}

private function int GetRiskLevel(CovertActionRisk Risk)
{
	local array<int> RiskThresholds;
	local int TotalChanceToOccur, Threshold, iThreshold;

	RiskThresholds = class'X2StrategyGameRulesetDataStructures'.default.RiskThresholds;
	TotalChanceToOccur = Risk.ChanceToOccur + Risk.ChanceToOccurModifier;

	// Set the risk threshold based on the chance to occur (not whether it actually does)
	foreach RiskThresholds(Threshold, iThreshold)
	{
		if (TotalChanceToOccur <= Threshold)
		{
			break;
		}
	}

	return iThreshold;
}

function ActivateRisks()
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionRiskTemplate RiskTemplate;
	local array<StateObjectReference> ExclusionList;
	local StateObjectReference RiskTargetRef;
	local int idx, ChanceToOccur, RisksBlockedIndex;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for (idx = 0; idx < Risks.Length; idx++)
	{
		if (NegatedRisks.Find(Risks[idx].RiskTemplateName) != INDEX_NONE)
		{
			// If the Risk was negated, it has no chance to occur
			ChanceToOccur = 0;
		}
		else
		{
			// Calculate chance to occur including any modifiers
			ChanceToOccur = Risks[idx].ChanceToOccur + Risks[idx].ChanceToOccurModifier;
			ChanceToOccur = min(max(ChanceToOccur, 0), 100);
		}
		// Roll to calculate whether this risk occurs
		Risks[idx].bOccurs = class'X2StrategyGameRulesetDataStructures'.static.Roll(ChanceToOccur);
		
		if (Risks[idx].bOccurs)
		{
			RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(Risks[idx].RiskTemplateName));
			if(RiskTemplate != none && RiskTemplate.FindTargetFn != none)
			{
				RiskTargetRef = RiskTemplate.FindTargetFn(self, ExclusionList);

				if (RiskTargetRef.ObjectID != 0)
				{
					Risks[idx].Target = RiskTargetRef;
				}
				else // No target found, so this risk cannot occur
				{
					Risks[idx].bOccurs = false;
				}
			}
			
			// Check to make sure it still occurs after looking for a target, then see if the blocking flag is enabled
			if (Risks[idx].bOccurs && RiskTemplate.bBlockOtherRisks)
			{
				RisksBlockedIndex = idx; // Save the index in the array up to which risks may have been activated
				break; // Don't need to activate any more risks, since this one blocks the others
			}
		}
	}

	if (RisksBlockedIndex > 0)
	{
		// If a risk has blocked all others from occurring, iterate through the list and turn off any others which were activated
		for (idx = 0; idx < RisksBlockedIndex; idx++)
		{
			Risks[idx].bOccurs = false;
		}
	}
}

function ApplyRisks(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionRiskTemplate RiskTemplate;
	local CovertActionRisk Risk;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	
	for (idx = 0; idx < Risks.Length; idx++)
	{
		Risk = Risks[idx];
		if (Risk.bOccurs)
		{
			RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(Risk.RiskTemplateName));
			if (RiskTemplate != none)
			{
				// Check if the Risk is still available
				if (RiskTemplate.IsRiskAvailableFn == none || RiskTemplate.IsRiskAvailableFn(GetFaction(), NewGameState))
				{
					// Then make sure it can be applied
					if (RiskTemplate.ApplyRiskFn != none)
					{
						RiskTemplate.ApplyRiskFn(NewGameState, self, Risk.Target);
					}
				}
			}
		}		
	}
}

function string GetRiskDifficultyLabel(int Level)
{
	local string Text;
	local eUIState ColorState;

	Text = class'X2StrategyGameRulesetDataStructures'.default.CovertActionRiskLabels[Level];

	switch (Level)
	{
	case 0: ColorState = eUIState_Normal;     break;
	case 1: ColorState = eUIState_Warning;   break;
	case 2: ColorState = eUIState_Bad;		break;
	}

	return class'UIUtilities_Text'.static.GetColoredText(Text, ColorState);
}

function GetRisksStrings(out array<string> Labels, out array<string> Values)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionRiskTemplate RiskTemplate;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for (idx = 0; idx < Risks.Length; idx++)
	{
		RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(Risks[idx].RiskTemplateName));		
		if (RiskTemplate != none && NegatedRisks.Find(Risks[idx].RiskTemplateName) == INDEX_NONE)
		{
			Labels.AddItem(RiskTemplate.RiskName);
			Values.AddItem(GetRiskDifficultyLabel(Risks[idx].Level));
		}
	}

	TriggerOverrideRiskStrings(Labels, Values);  // Issue #779
}

// Start Issue #779
/// HL-Docs: feature:CovertAction_OverrideRiskStrings; issue:779; tags:strategy
/// Allows listeners to override how risk chances are displayed in the covert
/// actions screen (UICovertActions). The names of each risk and the texts
/// displayed to represent the chance of each one occurring are passed in the
/// event as two separate arrays of strings.
///
/// Note that the two arrays are in the same order, i.e. the first element of
/// each array corresponds to the first risk, the second element to the second
/// risk, and so on.
//
/// Also be aware that the existing texts for the chance values will be HTML
/// markup, with some entries using `<font>` tags to color the text.
///
/// ```unrealscript
/// EventID: CovertAction_OverrideRiskStrings
/// EventData: XComLWTuple {
///     Data: [
///       inout array<string> RiskLabels,
///       inout array<string> RiskChanceTexts
///     ]
/// }
/// EventSource: self (XCGS_CovertAction)
/// NewGameState: no
/// ```
private function TriggerOverrideRiskStrings(out array<string> Labels, out array<string> Values)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'CovertAction_OverrideRiskStrings';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVArrayStrings;
	OverrideTuple.Data[0].as = Labels;
	OverrideTuple.Data[1].kind = XComLWTVArrayStrings;
	OverrideTuple.Data[1].as = Values;

	`XEVENTMGR.TriggerEvent(OverrideTuple.Id, OverrideTuple, self);

	Labels = OverrideTuple.Data[0].as;
	Values = OverrideTuple.Data[1].as;
}
// End Issue #779

function string GetStaffRisksAppliedString(int idx)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionRiskTemplate RiskTemplate;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit UnitState;
	local CovertActionRisk Risk;
	local string strRisks;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	SlotState = GetStaffSlot(idx);

	if (SlotState.IsSlotFilled())
	{
		UnitState = SlotState.GetAssignedStaff();

		// Iterate through all of the risks, and add the risk name for any which were applied to the staffed unit
		strRisks = "";
		for (idx = 0; idx < Risks.Length; idx++)
		{
			Risk = Risks[idx];
			if (Risk.bOccurs && Risk.Target.ObjectID == UnitState.ObjectID)
			{
				RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(Risk.RiskTemplateName));
				if (RiskTemplate != none)
				{
					if (Len(strRisks) > 0)
					{
						strRisks $= ", ";
					}
					strRisks $= RiskTemplate.RiskName;
				}
			}
		}
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strRisks);
}

function bool HasAmbushRisk()
{
	local name RiskName;
	local int idx;
	local array<name> AmbushRiskTemplateNames; // Issue 485

	AmbushRiskTemplateNames = class'CHHelpers'.static.GetAmbushRiskTemplateNames(); // Issue 485

	for (idx = 0; idx < Risks.Length; idx++)
	{
		RiskName = Risks[idx].RiskTemplateName;
		if (AmbushRiskTemplateNames.Find(RiskName) != INDEX_NONE && NegatedRisks.Find(RiskName) == INDEX_NONE) // Issue 485
		{
			return true;
		}
	}

	return false;
}

function bool DidRiskOccur(name RiskName)
{
	local int idx;

	for (idx = 0; idx < Risks.Length; idx++)
	{
		if (Risks[idx].RiskTemplateName == RiskName && Risks[idx].bOccurs)
		{
			return true;
		}		
	}

	return false;
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

// THIS FUNCTION SHOULD RETURN TRUE IN ALL THE SAME CASES AS Update
function bool ShouldUpdate()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local UIStrategyMap StrategyMap;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	StrategyMap = `HQPRES.StrategyMap2D;
	
	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (!bCompleted)
		{
			// If the end date time has passed, this action has completed
			if (bStarted && class'X2StrategyGameRulesetDataStructures'.static.LessThan(EndDateTime, GetCurrentTime()))
			{
				return true;
			}
		}
		else if (bAmbushed && !XComHQ.bWaitingForChosenAmbush)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// IF ADDING NEW CASES WHERE bModified = true, UPDATE FUNCTION ShouldUpdate ABOVE
function bool Update(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bModified;
	//local XComNarrativeMoment ActionNarrative;
	local UIStrategyMap StrategyMap;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	StrategyMap = `HQPRES.StrategyMap2D;
	bModified = false;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (!bCompleted)
		{
			// If the end date time has passed, this action has completed
			if (bStarted && class'X2StrategyGameRulesetDataStructures'.static.LessThan(EndDateTime, GetCurrentTime()))
			{
				ApplyRisks(NewGameState);
				if (bAmbushed)
				{
					// Flag XComHQ as expecting an ambush, so we can ensure the Covert Action rewards are only granted after it is completed
					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.bWaitingForChosenAmbush = true;
				}
				else
				{
					CompleteCovertAction(NewGameState);
				}

				bCompleted = true;
				bModified = true;
			}
		}
		else if (bAmbushed && !XComHQ.bWaitingForChosenAmbush)
		{
			bAmbushed = false; // Turn off Ambush flag so we don't hit this code block more than once
					
			// If the mission was ambushed, rewards were not granted before the tactical battle, so give them here
			CompleteCovertAction(NewGameState);
			bModified = true;
		}
	}

	return bModified;
}

function CompleteCovertAction(XComGameState NewGameState)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_ResistanceFaction FactionState;

	GiveRewards(NewGameState);

	// Save the Action as completed by its faction
	FactionState = GetFaction();
	FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionState.ObjectID));
	FactionState.CompletedCovertActions.AddItem(GetMyTemplateName());

	// Check to ensure a Rookie Action is available
	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	if (ResHQ.RookieCovertActions.Find(GetMyTemplateName()) != INDEX_NONE)
	{
		// This is a Rookie Action, so check to see if another one exists
		if (!ResHQ.IsRookieCovertActionAvailable(NewGameState))
		{
			ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
			ResHQ.CreateRookieCovertAction(NewGameState);
		}
	}

	// Flag the completion popup and trigger appropriate events
	bNeedsActionCompletePopup = true;
	`XEVENTMGR.TriggerEvent('CovertActionCompleted', , self, NewGameState);
	
	if (TriggerAllowResActivityRecord(NewGameState)) { // Issue #696
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_ActionsCompleted');
	} // Issue #696
}

// Start Issue #696
private function bool TriggerAllowResActivityRecord (XComGameState NewGameState)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = true;

	`XEVENTMGR.TriggerEvent('CovertAction_AllowResActivityRecord', Tuple, self, NewGameState);
	
	return Tuple.Data[0].b;
}
// End Issue #696

//#############################################################################################
//----------------   GEOSCAPE ENTITY IMPLEMENTATION   -----------------------------------------
//#############################################################################################

protected function bool CanInteract()
{
	// Issue #438 Start
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertAction_CanInteract';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false;

	`XEVENTMGR.TriggerEvent('CovertAction_CanInteract', Tuple, self);
	
	return Tuple.Data[0].b;
	// Issue #438 End
}

function string GetObjective()
{
	local XComGameState_ResistanceFaction FactionState;
	local XGParamTag kTag;

	FactionState = GetFaction();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = FactionState.GetRivalChosen().GetChosenClassName();
	kTag.StrValue1 = GetRewardSavedString();
	kTag.StrValue2 = FactionState.GetFactionTitle();

	return `XEXPAND.ExpandString(GetMyTemplate().ActionObjective);
}

function string GetDisplayName()
{
	return GetMyNarrativeTemplate().ActionName;
}

function string GetImage()
{
	if (GetMyTemplate().bUseRewardImage)
	{
		return GetRewardImage();
	}

	return GetMyNarrativeTemplate().ActionImage;
}

function string GetNarrative()
{
	local XComGameState_ResistanceFaction FactionState;
	local XGParamTag kTag;

	FactionState = GetFaction();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = FactionState.GetFactionName();
	kTag.StrValue1 = FactionState.GetRivalChosen().GetChosenName();
	kTag.StrValue2 = FactionState.GetRivalChosen().GetChosenClassName();
	kTag.StrValue3 = GetContinent().GetMyTemplate().DisplayName;
	kTag.StrValue4 = GetRewardSavedString();

	// Issue #438
	`XEVENTMGR.TriggerEvent('CovertAction_ModifyNarrativeParamTag', kTag, self);

	return `XEXPAND.ExpandString(GetMyNarrativeTemplate().ActionPreNarrative);
}

function string GetSummary()
{
	local XComGameState_ResistanceFaction FactionState;
	local XGParamTag kTag;

	FactionState = GetFaction();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = FactionState.GetFactionName();
	kTag.StrValue1 = FactionState.GetRivalChosen().GetChosenName();
	kTag.StrValue2 = FactionState.GetRivalChosen().GetChosenClassName();
	kTag.StrValue3 = GetContinent().GetMyTemplate().DisplayName;
	kTag.StrValue4 = GetRewardSavedString();

	return `XEXPAND.ExpandString(GetMyNarrativeTemplate().ActionPostNarrative);
}

function string GetCostString()
{
	local array<StrategyCostScalar> CostScalars;

	CostScalars.Length = 0;
	return class'UIUtilities_Strategy'.static.GetStrategyCostString(GetMyTemplate().Cost, CostScalars);
}

function XComGameState_ResistanceFaction GetFaction()
{
	return XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(Faction.ObjectID));
}

//---------------------------------------------------------------------------------------
// Helper to modify remaining duration
function ModifyRemainingTime(float Modifier)
{
	local int HoursRemaining, NewHoursRemaining;

	if (!bStarted)
	{
		HoursToComplete *= Modifier;
	}

	if (bStarted)
	{
		HoursRemaining = GetNumHoursRemaining();
		NewHoursRemaining = HoursRemaining * Modifier;

		// Update the end time of the Action to account for the new modifier
		EndDateTime = `STRATEGYRULES.GameTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(EndDateTime, NewHoursRemaining);
	}
}

function AddHoursToComplete(int Hours)
{
	local int HoursRemaining, NewHoursRemaining;

	if (!bStarted)
	{
		HoursToComplete += Hours;
	}

	if (bStarted)
	{
		HoursRemaining = GetNumHoursRemaining();
		NewHoursRemaining = HoursRemaining + Hours;

		// Update the end time of the Action to account for the new modifier
		EndDateTime = `STRATEGYRULES.GameTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(EndDateTime, NewHoursRemaining);
	}
}

function int GetNumHoursRemaining()
{
	local int HoursRemaining;

	if (!bStarted)
		HoursRemaining = HoursToComplete;
	else
		HoursRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(EndDateTime, GetCurrentTime());

	return HoursRemaining;
}

function int GetNumDaysRemaining()
{
	return FCeil(GetNumHoursRemaining() / 24.0f);
}

function string GetDurationString()
{
	local string DurationStr, ActionTimeValue, ActionTimeLabel;
	local int DaysRemaining;

	DaysRemaining = GetNumDaysRemaining();
	ActionTimeValue = string(DaysRemaining);
	ActionTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
	DurationStr = ActionTimeValue @ ActionTimeLabel;

	if (bBondmateDurationBonusApplied)
	{
		DurationStr = class'UIUtilities_Text'.static.GetColoredText(DurationStr, eUIState_Good);
	}

	return DurationStr;
}

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_CovertAction';
}

function string GetUIWidgetFlashLibraryName()
{
	return string(class'UIPanel'.default.LibID);
}

function string GetUIPinImagePath()
{
	return "";
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	local X2CovertActionTemplate ActionTemplate;
	local string OverworldMeshPath;
	local Object MeshObject;

	ActionTemplate = GetMyTemplate();
	OverworldMeshPath = "";

	if (OverworldMeshPath == "" && ActionTemplate.OverworldMeshPath != "")
	{
		OverworldMeshPath = ActionTemplate.OverworldMeshPath;
	}

	if (OverworldMeshPath != "")
	{
		MeshObject = `CONTENT.RequestGameArchetype(OverworldMeshPath);

		if (MeshObject != none && MeshObject.IsA('StaticMesh'))
		{
			return StaticMesh(MeshObject);
		}
	}

	return none;
}

simulated function string GetUIButtonIcon()
{
	return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Resistance";
}

simulated function string GetUIButtonTooltipTitle()
{
	if (bStarted)
		return class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetDisplayName() $ ":" @ GetWorldRegion().GetMyTemplate().DisplayName);
	else
		return "COVERT ACTIONS";
}

simulated function string GetUIButtonTooltipBody()
{
	local string toolTip;
	
	if (bStarted)
	{
		toolTip = GetRewardDescriptionString() $ ":" @ GetDurationString() @ "Remaining";
	}
	
	return toolTip;
}

function bool ShouldBeVisible()
{
	// Issue #438 Start
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertAction_ShouldBeVisible';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = bStarted;

	`XEVENTMGR.TriggerEvent('CovertAction_ShouldBeVisible', Tuple, self);

	return Tuple.Data[0].b;
	// Issue #438 End
}

function bool ShouldStaffSlotBeDisplayed(int idx)
{
	local XComGameState_StaffSlot SlotState;

	// Immediately return if slot isn't valid
	if (idx > StaffSlots.Length - 1)
		return false;
	
	SlotState = GetStaffSlot(idx);

	if (SlotState.IsSlotFilled())
	{
		return true;
	}		
	else if (bCompleted)
	{
		if (!SlotState.IsSlotFilled())
		{
			return false;
		}
	}
	else if (StaffSlots[idx].bOptional)
	{
		return !IsRewardRiskNegated(StaffSlots[idx].RewardRef);
	}

	return true;
}

function bool ShouldCostSlotBeDisplayed(int idx)
{
	// Immediately return if slot isn't valid
	if (idx > CostSlots.Length - 1)
		return false;

	if (CostSlots[idx].bPurchased)
	{
		return true;
	}
	else
	{
		return !IsRewardRiskNegated(CostSlots[idx].RewardRef);
	}
}

function bool CanActionBeDisplayed()
{
	local XComGameState_ResistanceFaction FactionState;
	local X2CovertActionTemplate ActionTemplate;

	ActionTemplate = GetMyTemplate();
	FactionState = GetFaction();

	// Always display any non-Golden Path covert actions unless specifically flagged, since they only get created if they are available
	// Golden Path actions are ALWAYS created, so we need to make sure they are available before displaying
	if ((!ActionTemplate.bGoldenPath && !ActionTemplate.bDisplayRequiresAvailable) || ActionTemplate.AreActionRewardsAvailable(FactionState))
	{
		return true;
	}

	return false;
}

function bool CanBeginAction()
{
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StrategyCostScalar> CostScalars;
	local StrategyCost TotalCost;
	local int idx;
	
	// Cannot begin an action which has already been started
	if (bStarted)
	{
		return false;
	}

	// Ensure Faction Influence is high enough to run the action
	if (GetFaction().GetInfluence() < RequiredFactionInfluence)
	{
		return false;
	}

	// Check all of the staff slots which are required and make sure they are filled
	for (idx = 0; idx < StaffSlots.Length; idx++)
	{
		if (!StaffSlots[idx].bOptional)
		{
			SlotState = GetStaffSlot(idx);
			if (!SlotState.IsSlotFilled())
			{
				return false;
			}
		}
	}

	// Calculate the combined cost for beginning this covert action	
	TotalCost = GetMyTemplate().Cost;	
	for (idx = 0; idx < CostSlots.Length; idx++)
	{
		if (CostSlots[idx].bPurchased)
		{
			class'X2StrategyGameRulesetDataStructures'.static.AddCosts(CostSlots[idx].Cost, TotalCost);
		}
	}

	// Make sure the player has resources to afford all of the costs, for the Action and their purchased cost slots
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CostScalars.Length = 0;	
	if (!XComHQ.CanAffordAllStrategyCosts(TotalCost, CostScalars))
	{
		return false;
	}

	return true;
}

private function PayCovertActionCost(XComGameState NewGameState, XComGameState_CovertAction NewActionState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StrategyCostScalar> CostScalars;
	local int idx;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	CostScalars.Length = 0;

	// Pay the cost for this Covert Action
	XComHQ.PayStrategyCost(NewGameState, GetMyTemplate().Cost, CostScalars);

	// Also pay the cost for each optional slot the player has purchased
	for (idx = 0; idx < CostSlots.Length; idx++)
	{
		if (CostSlots[idx].bPurchased)
		{
			XComHQ.PayStrategyCost(NewGameState, CostSlots[idx].Cost, CostScalars);
		}
	}
}

function ConfirmAction()
{
	`HQPRES.UIConfirmCovertAction(GetReference());
}

function StartAction()
{
	local XComGameState NewGameState;
	local XComGameState_CovertAction NewActionState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Launch Covert Action");
	
	if (GetFaction().bMetXCom)
	{
		`XEVENTMGR.TriggerEvent(GetFaction().GetConfirmCovertActionEvent(), , , NewGameState);
	}
	
	NewActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ObjectID));
	
	PayCovertActionCost(NewGameState, NewActionState);
	RemoveStaffedUnitsFromSquad(NewGameState);

	NewActionState.bStarted = true;

	// Only activate risks if the CA tutorial has been completed
	if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('XP2_M0_FirstCovertActionTutorial'))
	{
		NewActionState.ActivateRisks();
	}

	if (GetMyTemplate().OnStartedFn != none)
	{
		GetMyTemplate().OnStartedFn(NewGameState, self);
	}
	
	// Set the start and end times for this action
	NewActionState.StartDateTime = `STRATEGYRULES.GameTime;
	NewActionState.EndDateTime = NewActionState.StartDateTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(NewActionState.EndDateTime, NewActionState.HoursToComplete); // Time to Complete is calculated when Action is created
	
	// Check for overlaps with projects from the HQ
	NewActionState.CheckForProjectOverlap();

	// Mark Res HQ as having started a covert action this month
	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	if (!ResHQ.bCovertActionStartedThisMonth)
	{
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
		ResHQ.bCovertActionStartedThisMonth = true;
	}

	`XEVENTMGR.TriggerEvent('CovertActionStarted',, self, NewGameState); // Issue #584
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Update XComHQ staffing, power, and resource numbers
	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.HandlePowerOrStaffingChange();

	`HQPRES.m_kAvengerHUD.UpdateResources();

	if (!TriggerAllowEngineerPopup()) return; // Issue #584

	// Throw up a popup alerting the player that there is an idle engineer
	FacilityState = XComHQ.GetFacilityByName('ResistanceRing');
	if (FacilityState.GetNumEmptyStaffSlots() > 0)
	{
		StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

		if (StaffSlotState.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0)
		{
			`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlotState.GetMyTemplate());
		}
	}
}

// Start issue #584
protected function bool TriggerAllowEngineerPopup ()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertActionAllowEngineerPopup';
	Tuple.Data.Add(1);
	Tuple.Data[0].Kind = XComLWTVBool;
	Tuple.Data[0].b = true;

	`XEVENTMGR.TriggerEvent('CovertActionAllowEngineerPopup', Tuple, self);

	return Tuple.Data[0].b;
}
// End issue #584

private function CheckForProjectOverlap()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProject ProjectState;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local StateObjectReference ProjectRef;
	local bool bModified;

	if (!TriggerAllowCheckForProjectOverlap()) return; // Issue #584

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	foreach XComHQ.Projects(ProjectRef)
	{
		if (ProjectRef.ObjectID != ObjectID) // make sure we don't check against ourself
		{
			ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(ProjectRef.ObjectID));
			HealProject = XComGameState_HeadquartersProjectHealSoldier(ProjectState);

			// Heal projects can overlap since they don't give popups on the Geoscape
			if (HealProject == none)
			{
				if (ProjectState.CompletionDateTime == EndDateTime)
				{
					// If the projects' completion date and time is the same as the covert action, subtract an hour so the events don't stack
					// An hour is subtracted instead of added so the total "Days Remaining" does not change because of the offset.
					class'X2StrategyGameRulesetDataStructures'.static.AddHours(EndDateTime, -1);
					bModified = true;
				}
			}
		}
	}

	if (bModified)
	{
		CheckForProjectOverlap(); // Recursive to check if the new offset time overlaps with anything
	}
}

// Start issue #584
protected function bool TriggerAllowCheckForProjectOverlap ()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertActionAllowCheckForProjectOverlap';
	Tuple.Data.Add(1);
	Tuple.Data[0].Kind = XComLWTVBool;
	Tuple.Data[0].b = true;

	`XEVENTMGR.TriggerEvent('CovertActionAllowCheckForProjectOverlap', Tuple, self);

	return Tuple.Data[0].b;
}
// End issue #584

function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_CovertAction NewActionState;
	local UIStrategyMap StrategyMap;
	local bool bUpdated;
	
	if (ShouldUpdate())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Covert Action");

		NewActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ObjectID));

		bUpdated = NewActionState.Update(NewGameState);
		`assert(bUpdated); // why did Update & ShouldUpdate return different bools?

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`HQPRES.StrategyMap2D.UpdateMissions();
	}

	StrategyMap = `HQPRES.StrategyMap2D;
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight)
	{
		// Flags indicate the covert action has been completed
		if (bNeedsAmbushPopup || bNeedsActionCompletePopup)
		{
			StartActionCompleteSequence();
		}
	}
}

//---------------------------------------------------------------------------------------
simulated public function StartActionCompleteSequence()
{
	`HQPRES.UIStartActionCompletedSequence(GetReference());
}

//---------------------------------------------------------------------------------------
simulated public function ShowActionCompletePopups()
{
	if (bNeedsAmbushPopup)
	{
		AmbushPopup();
	}
	else if (bNeedsActionCompletePopup)
	{
		ActionCompletePopup();
	}
}

//---------------------------------------------------------------------------------------
simulated public function ActionCompletePopup()
{
	local XComGameState NewGameState;
	local XComGameState_CovertAction ActionState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Action Complete Popup");
	ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', self.ObjectID));
	ActionState.bNeedsActionCompletePopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	TriggerActionCompletePopup();
	TriggerRiskPopups();

	`GAME.GetGeoscape().Pause();
}

private function TriggerRiskPopups()
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionRiskTemplate RiskTemplate;
	local CovertActionRisk Risk;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	foreach Risks(Risk)
	{
		if (Risk.bOccurs)
		{
			RiskTemplate = X2CovertActionRiskTemplate(StratMgr.FindStrategyElementTemplate(Risk.RiskTemplateName));
			if (RiskTemplate != none && RiskTemplate.RiskPopupFn != none)
			{
				RiskTemplate.RiskPopupFn(self, Risk.Target);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
simulated public function ActionRewardPopups()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Reward RewardState;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit UnitState;
	local StateObjectReference RewardRef;
	local bool bPromoteReward;
	local int idx;

	History = `XCOMHISTORY;

	// Popups are triggered in backwards order of how they are presented to the player, since they get pushed onto the UI stack
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ.HasFacilityByName('ResistanceRing'))
	{
		TriggerNextCovertActionPopup();
	}

	// Start Issue #810
	/// HL-Docs: ref:CovertAction_PreventGiveRewards
	if (RewardsNotGivenOnCompletion)
	{
		// A mod or some other source prevented this reward from being
		// given to the player, so don't display the popups.
		return;
	}
	// End Issue #810

	// Display popups for Cost Slot rewards
	for (idx = 0; idx < CostSlots.Length; idx++)
	{
		if (CostSlots[idx].bPurchased)
		{
			RewardState = XComGameState_Reward(History.GetGameStateForObjectID(CostSlots[idx].RewardRef.ObjectID));
			if (RewardState != none)
				RewardState.DisplayRewardPopup();
		}
	}

	// Display popups for Staff Slot rewards
	for (idx = 0; idx < StaffSlots.Length; idx++)
	{
		SlotState = GetStaffSlot(idx);
		if (SlotState.IsSlotFilled())
		{
			bPromoteReward = false;
			RewardState = XComGameState_Reward(History.GetGameStateForObjectID(StaffSlots[idx].RewardRef.ObjectID));
			if (RewardState != none)
			{
				RewardState.DisplayRewardPopup();
				if (RewardState.GetMyTemplateName() == 'Reward_RankUp')
				{
					bPromoteReward = true;
				}
			}

			if (!bPromoteReward)
			{
				// Only display a promotion reward here if the unit didn't get it as a specific covert action slot reward,
				// since in that case the reward popup will already have been the promotion popup
				UnitState = SlotState.GetAssignedStaff();
				if (UnitState != none && UnitState.ShowPromoteIcon())
				{
					`HQPRES.UISoldierPromoted(UnitState.GetReference());
				}
			}
		}
	}

	// Display any popups associated with the base Action rewards
	foreach RewardRefs(RewardRef)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
		if (RewardState != none)
			RewardState.DisplayRewardPopup();
	}
}

//---------------------------------------------------------------------------------------
simulated public function AmbushPopup()
{
	local XComGameState NewGameState;
	local XComGameState_CovertAction ActionState;
	local XComGameState_MissionSite MissionSite;
	local name MissionSource; // Issue #485

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Action Complete Popup");
	ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', self.ObjectID));
	ActionState.bNeedsAmbushPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Start Issue #485
	if(AmbushMissionSource == '') // backwards compatibility
	{
		MissionSource = 'MissionSource_ChosenAmbush';
	}
	else
	{
		MissionSource = AmbushMissionSource;
	}
	MissionSite = GetMission(MissionSource); // Find the Ambush mission and display its popup
	// End Issue #485

	if (MissionSite != none && MissionSite.GetMissionSource().MissionPopupFn != none)
	{
		MissionSite.GetMissionSource().MissionPopupFn(MissionSite);
	}
	
	`GAME.GetGeoscape().Pause();
}

simulated function XComGameState_MissionSite GetMission(name MissionSource)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.Source == MissionSource && MissionState.Available)
		{
			return MissionState;
		}
	}
}

// Separated from the ActionCompletePopup function so it can be easily overwritten by mods
simulated function TriggerActionCompletePopup()
{
	`HQPRES.UIActionCompleted();
}

simulated function TriggerNextCovertActionPopup()
{
	`HQPRES.UINextCovertAction();
}

function RemoveEntity(XComGameState NewGameState)
{
	local XComGameState_ResistanceFaction FactionState;
	local bool SubmitLocally;
	local XComLWTuple Tuple; // Issue #438

	if (NewGameState == None)
	{
		SubmitLocally = true;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Covert Action Despawned");
	}

	// Issue #438 Start
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertAction_RemoveEntity_ShouldEmptySlots';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = true;

	`XEVENTMGR.TriggerEvent('CovertAction_RemoveEntity_ShouldEmptySlots', Tuple, self, NewGameState);

	if (Tuple.Data[0].b)
	{
	// Issue #438 End
		EmptyAllStaffSlots(NewGameState);
	// Issue #438 Start
	}
	// Issue #438 End

	// clean up the rewards for this action if it wasn't started
	if (!bStarted)
	{
		CleanUpRewards(NewGameState);
	}

	// Remove the action from the list stored by the Faction, so it can't be modified after it has been completed
	FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', Faction.ObjectID));
	FactionState.RemoveCovertAction(GetReference());

	// remove this action from the history
	NewGameState.RemoveStateObject(ObjectID);

	if (!bNeedsLocationUpdate && `HQPRES != none && `HQPRES.StrategyMap2D != none)
	{
		// Only remove map pin if it was generated
		bAvailable = false;
		RemoveMapPin(NewGameState);
	}

	if (SubmitLocally)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function AttemptSelectionCheckInterruption()
{
	// Mission sites should never trigger interruption states since they are so important, so just
	// jump straight to the selection
	AttemptSelection();
}

protected function bool DisplaySelectionPrompt()
{
	ActionSelected();

	return true;
}

function ActionSelected()
{
	// Issue #438 Start
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertAction_ActionSelectedOverride';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false;

	`XEVENTMGR.TriggerEvent('CovertAction_ActionSelectedOverride', Tuple, self);

	if (!Tuple.Data[0].b)
	{
	// Issue #438 End
		`HQPRES.OnCovertActionSelected(self);
	// Issue #438 Start
	}
	// Issue #438 End
}

//#############################################################################################
//----------------   HELPER FUNCTIONS   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function XComGameState_StaffSlot GetStaffSlot(int i)
{
	if (i >= 0 && i < StaffSlots.Length)
	{
		return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlots[i].StaffSlotRef.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function int GetMinDaysToComplete()
{
	return `ScaleStrategyArrayInt(GetMyTemplate().MinActionHours);
}

//---------------------------------------------------------------------------------------
function int GetMaxDaysToComplete()
{
	return `ScaleStrategyArrayInt(GetMyTemplate().MaxActionHours);
}

// Start Issue #485
defaultproperties
{
	AmbushMissionSource="MissionSource_ChosenAmbush"
}
// End Issue #485
