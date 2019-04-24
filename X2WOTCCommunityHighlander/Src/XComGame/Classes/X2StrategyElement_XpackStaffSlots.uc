//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_XpackStaffSlots.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_XpackStaffSlots extends X2StrategyElement_DefaultStaffSlots 
	config(GameData);

var config float RESISTANCE_RING_COVERT_ACTION_DURATION_MODIFIER;

//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> StaffSlots;

	// Facilities
	StaffSlots.AddItem(CreateInfirmarySoldierStaffSlotTemplate());
	StaffSlots.AddItem(CreateRecoveryCenterBondStaffSlotTemplate());
	StaffSlots.AddItem(CreateResistanceRingStaffSlotTemplate());

	// Covert Actions
	StaffSlots.AddItem(CreateCovertActionFormSoldierBondStaffSlotTemplate());
	StaffSlots.AddItem(CreateCovertActionImproveComIntStaffSlotTemplate());

	StaffSlots.AddItem(CreateCovertActionSoldierStaffSlotTemplate('CovertActionSoldierStaffSlot'));
	StaffSlots.AddItem(CreateCovertActionRookieStaffSlotTemplate());
	StaffSlots.AddItem(CreateCovertActionScientistStaffSlotTemplate());
	StaffSlots.AddItem(CreateCovertActionEngineerStaffSlotTemplate());

	return StaffSlots;
}

//#############################################################################################
//-------------------------------   INFIRMARY    ----------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateInfirmarySoldierStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('InfirmarySoldierStaffSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.UIStaffSlotClass = class'UIFacility_InfirmarySlot';
	Template.FillFn = FillInfirmarySoldierSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectInfirmarySoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayInfirmarySoldierToDoWarning;
	Template.GetSkillDisplayStringFn = GetInfirmarySoldierSkillDisplayString;
	Template.IsUnitValidForSlotFn = IsUnitValidForInfirmarySoldierSlot;
	Template.MatineeSlotName = "Soldier";

	return Template;
}

static function FillInfirmarySoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectRemoveTraits ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	ProjectState = XComGameState_HeadquartersProjectRemoveTraits(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectRemoveTraits'));
	ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

	NewUnitState.SetStatus(eStatus_Training);
	NewXComHQ.Projects.AddItem(ProjectState.GetReference());

	// If the unit undergoing training is in the squad, remove them
	SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		// Remove them from the squad
		NewXComHQ.Squad[SquadIndex] = EmptyRef;
	}
}

static function EmptyStopProjectInfirmarySoldierSlot(StateObjectReference SlotRef)
{
	local HeadquartersOrderInputContext OrderInput;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectRemoveTraits RemoveTraitsProject;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));

	RemoveTraitsProject = XComHQ.GetRemoveTraitsProject(SlotState.GetAssignedStaffRef());
	if (RemoveTraitsProject != none)
	{
		OrderInput.OrderType = eHeadquartersOrderType_CancelRemoveTraits;
		OrderInput.AcquireObjectReference = RemoveTraitsProject.GetReference();

		class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
	}
}

static function bool ShouldDisplayInfirmarySoldierToDoWarning(StateObjectReference SlotRef)
{
	return false;
}

static function bool IsUnitValidForInfirmarySoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.CanBeStaffed()
		&& Unit.IsSoldier()
		&& Unit.IsActive()
		&& Unit.NegativeTraits.Length > 0 // Unit has negative traits
		&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE) // Certain classes can't retrain their abilities (Psi Ops)
	{
		return true;
	}

	return false;
}

static function string GetInfirmarySoldierSkillDisplayString(XComGameState_StaffSlot SlotState)
{
	return "";
}

//#############################################################################################
//-------------------------   RECOVERY CENTER    ----------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateRecoveryCenterBondStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('RecoveryCenterBondStaffSlot');
	Template.UIStaffSlotClass = class'UIFacility_BondSlot';
	Template.bSoldierSlot = true;
	Template.bPreventFilledPopup = true;
	Template.bRequireConfirmToEmpty = true;
	Template.FillFn = FillRecoveryCenterBondSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectRecoveryCenterBondSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayRecoveryCenterBondSlotToDoWarning;
	Template.GetNameDisplayStringFn = GetNameDisplayStringRecoveryCenterBondSlot;
	Template.GetValidUnitsForSlotFn = GetValidUnitsForRecoveryCenterBondSlot;
	Template.IsUnitValidForSlotFn = IsUnitValidForRecoveryCenterBondSlot;
	Template.MatineeSlotName = "Soldier";
	
	return Template;
}

static function FillRecoveryCenterBondSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBondSoldiers BondProject;
	local XComGameState_Unit UnitState, PairUnitState;
	local XComGameState_StaffSlot SlotState;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, SlotState, UnitState);
		
	// Start a bond project for the two units
	PairUnitState = SlotState.GetPairedStaff();
	PairUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(PairUnitState.ObjectID)); // New game state should exist from FillSlot

	BondProject = XComGameState_HeadquartersProjectBondSoldiers(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectBondSoldiers'));
	BondProject.SetProjectFocus(UnitInfo.UnitRef, NewGameState, UnitInfo.PairUnitRef);
			
	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.Projects.AddItem(BondProject.GetReference());

	// If the units undergoing bond training are in the squad, remove them
	SquadIndex = XComHQ.Squad.Find('ObjectID', UnitState.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		XComHQ.Squad[SquadIndex].ObjectID = 0;
	}

	SquadIndex = XComHQ.Squad.Find('ObjectID', PairUnitState.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		XComHQ.Squad[SquadIndex].ObjectID = 0;
	}
}

static function array<StaffUnitInfo> GetValidUnitsForRecoveryCenterBondSlot(XComGameState_StaffSlot SlotState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState, PairUnitState;
	local StaffUnitInfo UnitInfo;
	local array<StaffUnitInfo> ValidUnits;
	local array<XComGameState_Unit> ValidTwoBonds, ValidThreeBonds;
	local array<StateObjectReference> CheckedUnits;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		UnitInfo.UnitRef = UnitState.GetReference();

		ValidTwoBonds = class'X2StrategyGameRulesetDataStructures'.static.GetAllValidSoldierBondsAtLevel(UnitState, 2);
		foreach ValidTwoBonds(PairUnitState)
		{
			// Don't re-add units whose bonds we already checked
			if (CheckedUnits.Find('ObjectID', PairUnitState.ObjectID) == INDEX_NONE)
			{
				UnitInfo.PairUnitRef = PairUnitState.GetReference();

				if (SlotState.ValidUnitForSlot(UnitInfo))
				{
					ValidUnits.AddItem(UnitInfo);
				}
			}
		}

		ValidThreeBonds = class'X2StrategyGameRulesetDataStructures'.static.GetAllValidSoldierBondsAtLevel(UnitState, 3);
		foreach ValidThreeBonds(PairUnitState)
		{
			// Don't re-add units whose bonds we already checked
			if (CheckedUnits.Find('ObjectID', PairUnitState.ObjectID) == INDEX_NONE)
			{
				UnitInfo.PairUnitRef = PairUnitState.GetReference();

				if (SlotState.ValidUnitForSlot(UnitInfo))
				{
					ValidUnits.AddItem(UnitInfo);
				}
			}
		}

		CheckedUnits.AddItem(UnitState.GetReference());
	}

	return ValidUnits;
}

static function bool IsUnitValidForRecoveryCenterBondSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, PairUnitState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (UnitState.CanBeStaffed() && UnitState.IsSoldier() && UnitState.IsActive() && 
		UnitState.GetReference().ObjectID != SlotState.GetAssignedStaffRef().ObjectID)
	{
		PairUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.PairUnitRef.ObjectID));
		if (PairUnitState != none && PairUnitState.CanBeStaffed() && PairUnitState.IsSoldier() && PairUnitState.IsActive() &&
			PairUnitState.GetReference().ObjectID != SlotState.GetAssignedStaffRef().ObjectID)
		{
			return true;
		}
	}

	return false;
}

static function EmptyStopProjectRecoveryCenterBondSlot(StateObjectReference SlotRef)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBondSoldiers BondProject;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit UnitStateA, UnitStateB;

	History = `XCOMHISTORY;
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));
		
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Stop Soldier Bond Project");
	UnitStateA = SlotState.GetAssignedStaff();
	if (UnitStateA != none)
	{
		// Set the soldier status back to active and remove them from the slot
		UnitStateA = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitStateA.ObjectID));
		UnitStateA.SetStatus(eStatus_Active);
	}
	
	UnitStateB = SlotState.GetPairedStaff();
	if (UnitStateB != none)
	{
		// Set the soldier status back to active and remove them from the slot
		UnitStateB = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitStateB.ObjectID));
		UnitStateB.SetStatus(eStatus_Active);
	}

	SlotState.EmptySlot(NewGameState); // Will remove both Units from the staff slot
	
	// Remove the Bond Project from XComHQ
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ != none)
	{
		BondProject = XComHQ.GetBondSoldiersProjectForUnit(UnitStateA.GetReference());
		if (BondProject != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(BondProject.GetReference());
			NewGameState.RemoveStateObject(BondProject.ObjectID);
		}
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function bool ShouldDisplayRecoveryCenterBondSlotToDoWarning(StateObjectReference SlotRef)
{
	return false;
}

static function string GetNameDisplayStringRecoveryCenterBondSlot(XComGameState_StaffSlot SlotState)
{	
	local XComGameState_Unit PairUnitState;
	local string DisplayString;

	DisplayString = GetNameDisplayStringDefault(SlotState);

	if (SlotState.IsSlotFilled())
	{
		PairUnitState = SlotState.GetPairedStaff();

		if (PairUnitState.IsSoldier())
			DisplayString @= class'UIUtilities_Text'.default.m_strAmpersand @ PairUnitState.GetName(eNameType_RankFull);
		else
			DisplayString @= class'UIUtilities_Text'.default.m_strAmpersand @ PairUnitState.GetFullName();
	}

	return DisplayString;
}

//#############################################################################################
//----------------   RESISTANCE RING   --------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateResistanceRingStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('ResistanceRingStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillResistanceRingSlot;
	Template.EmptyFn = EmptyResistanceRingSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayResistanceRingToDoWarning;
	Template.GetAvengerBonusAmountFn = GetResistanceRingAvengerBonus;
	Template.GetBonusDisplayStringFn = GetResistanceRingBonusDisplayString;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

static function int GetResistanceRingAvengerBonus(XComGameState_Unit Unit, optional bool bPreview)
{
	local float PercentIncrease;

	// Need to return the percent increase in overall project speed provided by this unit
	PercentIncrease = (default.RESISTANCE_RING_COVERT_ACTION_DURATION_MODIFIER * 100.0);

	return Round(PercentIncrease);
}

static function FillResistanceRingSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_HeadquartersResistance NewResHQ;
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	
	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewResHQ = GetNewResHQState(NewGameState);
	NewResHQ.AddCovertActionModifier(NewGameState, (1.0 - default.RESISTANCE_RING_COVERT_ACTION_DURATION_MODIFIER));
}

static function EmptyResistanceRingSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_HeadquartersResistance NewResHQ;
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	
	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	NewResHQ = GetNewResHQState(NewGameState);
	NewResHQ.RemoveCovertActionModifier(NewGameState, (1.0 - default.RESISTANCE_RING_COVERT_ACTION_DURATION_MODIFIER));
}

static function bool ShouldDisplayResistanceRingToDoWarning(StateObjectReference SlotRef)
{
	local XComGameState_HeadquartersResistance ResHQ;

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	
	return ResHQ.IsCovertActionInProgress();
}

static function string GetResistanceRingBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		Contribution = string(GetResistanceRingAvengerBonus(SlotState.GetAssignedStaff(), bPreview));
	}

	return GetBonusDisplayString(SlotState, "%AVENGERBONUS", Contribution);
}

//#############################################################################################
//----------------   COVERT ACTIONS    --------------------------------------------------------
//#############################################################################################

static function X2StaffSlotTemplate CreateCovertActionStaffSlotTemplate(name CovertActionSlotName)
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate(CovertActionSlotName);
	Template.bPreventFilledPopup = true;
	Template.FillFn = FillCovertActionSlot;
	Template.EmptyFn = EmptyCovertActionSlot;
	Template.CanStaffBeMovedFn = CanStaffBeMovedCovertActions;

	return Template;
}

static function X2DataTemplate CreateCovertActionFormSoldierBondStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateCovertActionSoldierStaffSlotTemplate('CovertActionFormSoldierBondStaffSlot');
	Template.IsUnitValidForSlotFn = IsUnitValidForCovertActionFormSoldierBondSlot;

	return Template;
}

static function bool IsUnitValidForCovertActionFormSoldierBondSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;
	local SoldierBond BondInfo;
	local StateObjectReference BondmateRef;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	
	if (!Unit.GetSoldierClassTemplate().bCanHaveBonds)
	{
		return false;
	}
	else if(Unit.HasSoldierBond(BondmateRef, BondInfo))
	{
		// If this unit is already at the max bond level, they are not available
		if ((BondInfo.BondLevel + 1) >= class'X2StrategyGameRulesetDataStructures'.default.CohesionThresholds.Length)
		{
			return false;
		}
	}

	return IsUnitValidForCovertActionSoldierSlot(SlotState, UnitInfo);
}

static function X2DataTemplate CreateCovertActionImproveComIntStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateCovertActionSoldierStaffSlotTemplate('CovertActionImproveComIntStaffSlot');
	Template.IsUnitValidForSlotFn = IsUnitValidForCovertActionImproveComIntSlot;

	return Template;
}

static function bool IsUnitValidForCovertActionImproveComIntSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.ComInt >= eComInt_Savant || !Unit.GetSoldierClassTemplate().bAllowAWCAbilities)
	{
		// If this unit is already at the max Com Int level, they are not available
		return false;
	}

	return IsUnitValidForCovertActionSoldierSlot(SlotState, UnitInfo);
}

static function X2StaffSlotTemplate CreateCovertActionSoldierStaffSlotTemplate(Name TemplateName)
{
	local X2StaffSlotTemplate Template;

	Template = CreateCovertActionStaffSlotTemplate(TemplateName);
	Template.bSoldierSlot = true;
	Template.GetNameDisplayStringFn = GetCovertActionSoldierNameDisplayString;
	Template.IsUnitValidForSlotFn = IsUnitValidForCovertActionSoldierSlot;
	
	return Template;
}

static function bool IsUnitValidForCovertActionSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.CanBeStaffed()
		&& Unit.IsSoldier() && !Unit.IsRobotic()
		&& Unit.IsActive(true) && Unit.GetMentalState(true) == eMentalState_Ready
		&& (SlotState.RequiredClass == '' || Unit.GetSoldierClassTemplateName() == SlotState.RequiredClass)
		&& (SlotState.RequiredMinRank == 0 || Unit.GetRank() >= SlotState.RequiredMinRank)
		&& (!SlotState.bRequireFamous || Unit.bIsFamous))
	{
		return true;
	}

	return false;
}

static function string GetCovertActionSoldierNameDisplayString(XComGameState_StaffSlot SlotState)
{
	local X2SoldierClassTemplateManager ClassManager;
	local X2SoldierClassTemplate ClassTemplate;
	local string DisplayString;

	DisplayString = GetNameDisplayStringDefault(SlotState);
	
	if (!SlotState.IsSlotFilled())
	{
		if (SlotState.RequiredClass != '')
		{
			ClassManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
			ClassTemplate = ClassManager.FindSoldierClassTemplate(SlotState.RequiredClass);

			if (ClassTemplate != none)
			{
				DisplayString = Caps(ClassTemplate.DisplayName);
			}
		}

		if (SlotState.RequiredMinRank > 0)
		{
			// Pass in blank class will return default rank names
			DisplayString @= "[" $ Caps(class'X2ExperienceConfig'.static.GetRankName(SlotState.RequiredMinRank, '')) $ "+]";
		}
	}

	return DisplayString;
}

static function X2DataTemplate CreateCovertActionRookieStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateCovertActionStaffSlotTemplate('CovertActionRookieStaffSlot');
	Template.bSoldierSlot = true;
	Template.IsUnitValidForSlotFn = IsUnitValidForCovertActionRookieSlot;
	
	return Template;
}

static function bool IsUnitValidForCovertActionRookieSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.CanBeStaffed()
		&& Unit.IsSoldier()
		&& Unit.IsActive()
		&& Unit.GetRank() == 0 //only include soldiers who are still Rookies
		&& !Unit.CanRankUpSoldier()) // and haven't yet received a promotion
	{
		return true;
	}

	return false;
}

static function X2DataTemplate CreateCovertActionEngineerStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateCovertActionStaffSlotTemplate('CovertActionEngineerStaffSlot');
	Template.bEngineerSlot = true;
	
	return Template;
}

static function X2DataTemplate CreateCovertActionScientistStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateCovertActionStaffSlotTemplate('CovertActionScientistStaffSlot');
	Template.bScientistSlot = true;
	
	return Template;
}

static function FillCovertActionSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_CovertAction NewActionState;
	local XComGameState_HeadquartersXCom XComHQ;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewUnitState.SetStatus(eStatus_CovertAction);

	NewActionState = GetNewCovertActionState(NewGameState, NewSlotState);
	NewActionState.UpdateNegatedRisks(NewGameState);
	NewActionState.UpdateDurationForBondmates(NewGameState);

	if (NewUnitState.IsSoldier())
	{
		XComHQ = GetNewXComHQState(NewGameState);
		if ((XComHQ.GetNumberOfDeployableSoldiers() - 1) < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
		{
			`XEVENTMGR.TriggerEvent('LowSoldiersCovertAction', , , NewGameState);
		}
	}
}

static function EmptyCovertActionSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_CovertAction NewActionState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);

	// Only set a unit status back to normal if they are still listed as being on the covert action
	// Since this means they weren't killed, wounded, or captured on the mission
	if (NewUnitState.GetStatus() == eStatus_CovertAction)
	{
		NewUnitState.SetStatus(eStatus_Active);

		// Don't change super soldier loadouts since they have specialized gear
		if (NewUnitState.IsSoldier() && !NewUnitState.bIsSuperSoldier)
		{
			// First try to upgrade the soldier's primary weapons, in case a tier upgrade happened while
			// they were away on the CA. This is needed to make sure weapon upgrades and customization transfer properly.
			// Issue #230 start
			//CheckToUpgradePrimaryWeapons(NewGameState, NewUnitState);
			CheckToUpgradeItems(NewGameState, NewUnitState);
			// Issue #230 end

			// Then try to equip the rest of the old items
			if (!class'CHHelpers'.default.bDontUnequipCovertOps) // Issue #153
			{
				NewUnitState.EquipOldItems(NewGameState);
			}

			// Try to restart any psi training projects
			class'XComGameStateContext_StrategyGameRule'.static.PostMissionUpdatePsiOperativeTraining(NewGameState, NewUnitState);
		}
	}

	NewActionState = GetNewCovertActionState(NewGameState, NewSlotState);
	NewActionState.UpdateNegatedRisks(NewGameState);
	NewActionState.UpdateDurationForBondmates(NewGameState);
}

static function CheckToUpgradePrimaryWeapons(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	local XComGameState_Item EquippedPrimaryWeapon, UpgradedItemState;
	local array<X2WeaponTemplate> BestPrimaryWeapons;
	local X2WeaponTemplate BestPrimaryWeaponTemplate;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local EInventorySlot InventorySlot;
	local int idx;

	EquippedPrimaryWeapon = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState);
	BestPrimaryWeapons = UnitState.GetBestPrimaryWeaponTemplates();

	// Run the same logic used in XComGameState_HeadquartersXCom::UpgradeItems()
	// but only for the primary weapons of the soldier, so we ensure that upgrades and customization transfer properly
	if (EquippedPrimaryWeapon != none)
	{
		for (idx = 0; idx < BestPrimaryWeapons.Length; idx++)
		{
			BestPrimaryWeaponTemplate = BestPrimaryWeapons[idx];

			if (BestPrimaryWeaponTemplate.Tier > EquippedPrimaryWeapon.GetMyTemplate().Tier)
			{
				if (BestPrimaryWeaponTemplate.WeaponCat != X2WeaponTemplate(EquippedPrimaryWeapon.GetMyTemplate()).WeaponCat)
				{
					continue;
				}

				UpgradedItemState = BestPrimaryWeaponTemplate.CreateInstanceFromTemplate(NewGameState);
				UpgradedItemState.WeaponAppearance = EquippedPrimaryWeapon.WeaponAppearance;
				UpgradedItemState.Nickname = EquippedPrimaryWeapon.Nickname;
				InventorySlot = EquippedPrimaryWeapon.InventorySlot; // save the slot location for the new item

				// Remove the old item from the soldier and transfer over all weapon upgrades to the new item
				UnitState.RemoveItemFromInventory(EquippedPrimaryWeapon, NewGameState);
				WeaponUpgrades = EquippedPrimaryWeapon.GetMyWeaponUpgradeTemplates();
				foreach WeaponUpgrades(WeaponUpgradeTemplate)
				{
					UpgradedItemState.ApplyWeaponUpgradeTemplate(WeaponUpgradeTemplate);
				}

				// Delete the old item
				NewGameState.RemoveStateObject(EquippedPrimaryWeapon.GetReference().ObjectID);

				// Then add the new item to the soldier in the same slot
				UnitState.AddItemToInventory(UpgradedItemState, InventorySlot, NewGameState);
			}
		}
	}
}

// Issue #230 start
// Why not use XComGameState_HeadquartersXCom::UpgradeItems()?
// Only supports a single upgrade. A single covert ops mission could span multiple upgrades
static function CheckToUpgradeItems(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Item> AllEquippedItems;
	local XComGameState_Item EquippedItemState;
	local X2ItemTemplate UpgradedItemTemplate;
	local XComGameState_Item UpgradedItemState;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local EInventorySlot InventorySlot;

	XComHQ = `XCOMHQ;
	AllEquippedItems = UnitState.GetAllInventoryItems(NewGameState, true);

	foreach AllEquippedItems(EquippedItemState)
	{
		if (EquippedItemState != none)
		{
			UpgradedItemTemplate = EquippedItemState.GetMyTemplate();
			XComHQ.UpdateItemTemplateToHighestAvailableUpgrade(UpgradedItemTemplate);
			
			if (UpgradedItemTemplate != EquippedItemState.GetMyTemplate())
			{
				UpgradedItemState = UpgradedItemTemplate.CreateInstanceFromTemplate(NewGameState);
				UpgradedItemState.WeaponAppearance = EquippedItemState.WeaponAppearance;
				UpgradedItemState.Nickname = EquippedItemState.Nickname;
				InventorySlot = EquippedItemState.InventorySlot; // save the slot location for the new item
					
				// Remove the old item from the soldier and transfer over all weapon upgrades to the new item
				UnitState.RemoveItemFromInventory(EquippedItemState, NewGameState);
				WeaponUpgrades = EquippedItemState.GetMyWeaponUpgradeTemplates();
				foreach WeaponUpgrades(WeaponUpgradeTemplate)
				{
					UpgradedItemState.ApplyWeaponUpgradeTemplate(WeaponUpgradeTemplate);
				}

				// Delete the old item
				NewGameState.RemoveStateObject(EquippedItemState.GetReference().ObjectID);

				// Then add the new item to the soldier in the same slot
				UnitState.AddItemToInventory(UpgradedItemState, InventorySlot, NewGameState);
			}
		}
	}
}
// Issue #230 end

static function bool CanStaffBeMovedCovertActions(StateObjectReference SlotRef)
{
	// Staff assigned to Covert Actions cannot be moved until the Covert Action completes and empties the slot
	return false;
}
