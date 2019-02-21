//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_StaffSlot.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_StaffSlot extends XComGameState_BaseObject;

var() protected name                   m_TemplateName;
var() protected X2StaffSlotTemplate    m_Template;

var StateObjectReference			   Facility;
var StateObjectReference			   Room; // Use for staff slots that don't have a facility (Build Slot)
var StateObjectReference			   CovertAction;
var StaffUnitInfo					   AssignedStaff;

var int								   MaxAdjacentGhostStaff; // the maximum number of ghost staff units this slot can create

// Start Issue #424
// DEPRECATED
var int								   AvailableGhostStaff; // the current number of possible ghost units which can be staffed in adjacent rooms
// DEPRECATED
// End Issue #424

var() bool							   bIsLocked; // If the staff slot is locked and cannot be staffed
var() bool							   bRequireFamous; // If this staff slot requires a famous unit to be staffed there

var() Name							   RequiredClass; // If this staff slot requires a specific soldier class
var() int							   RequiredMinRank; // If this staff slot requires a soldier of at least a specific rank

var StateObjectReference			   LinkedStaffSlot;

// Start Issue #424
// This slot is filled with a Ghost Gremlin
var bool IsGhost;
// The Creator staffed unit
var StateObjectReference CreatorRef;
// The Creator Staffslot
var StateObjectReference CreatorSlotRef;
// References to Ghost children created by this Staffslot
var array<StateObjectReference> Ghosts;
// End Issue #424


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
simulated function X2StaffSlotTemplate GetMyTemplate()
{
	if(m_Template == none)
	{
		m_Template = X2StaffSlotTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
event OnCreation(optional X2DataTemplate Template)
{
	super.OnCreation( Template );

	m_Template = X2StaffSlotTemplate(Template);
	m_TemplateName = Template.DataName;
}

//#############################################################################################
//----------------   ACCESS   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function LockSlot()
{
	bIsLocked = true;
}

//---------------------------------------------------------------------------------------
function UnlockSlot()
{
	bIsLocked = false;
}

//---------------------------------------------------------------------------------------
function bool IsLocked()
{
	return bIsLocked;
}

//#############################################################################################
//----------------   FILLING/EMPTYING   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool IsUnitAvailableForThisSlot()
{
	local array<StaffUnitInfo> ValidUnits;
		
	if (IsSlotFilled())
	{
		return true;
	}

	ValidUnits = GetValidUnitsForSlot();
	if (ValidUnits.Length > 0)
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function array<StaffUnitInfo> GetValidUnitsForSlot()
{
	local array<StaffUnitInfo> ValidUnits;

	if (GetMyTemplate().GetValidUnitsForSlotFn != None)
	{
		ValidUnits = GetMyTemplate().GetValidUnitsForSlotFn(self);
	}

	return ValidUnits;
}

//---------------------------------------------------------------------------------------
function bool ValidUnitForSlot(StaffUnitInfo UnitInfo)
{
	if (GetMyTemplate().IsUnitValidForSlotFn != None)
	{
		return GetMyTemplate().IsUnitValidForSlotFn(self, UnitInfo);
	}

	// If there is no function to check if the unit is valid, assume all staff are allowed
	return true;
}

//---------------------------------------------------------------------------------------
function bool CanStaffBeMoved()
{
	// If slot is filled, check if the staffer can be moved without breaking anything
	if (IsSlotFilled())
	{
		if (GetMyTemplate().CanStaffBeMovedFn != None)
		{
			return GetMyTemplate().CanStaffBeMovedFn(self.GetReference());
		}
	}
	
	// If the slot is empty or no slot check function, no issue
	return true;
}

//---------------------------------------------------------------------------------------
function bool IsStaffSlotBusy()
{
	// If slot is filled, check if the staffer is currently busy working on something
	if (IsSlotFilled())
	{
		if (GetMyTemplate().IsStaffSlotBusyFn != None)
		{
			return GetMyTemplate().IsStaffSlotBusyFn(self);
		}
	}

	// If the slot is empty or no function exists, it is not busy
	return false;
}

//---------------------------------------------------------------------------------------
function bool IsSlotFilled()
{
	local StateObjectReference EmptyRef;

	return (AssignedStaff.UnitRef != EmptyRef);
}

//---------------------------------------------------------------------------------------

// Start Issue #424
// Cleaned boilerplate code
function bool IsSlotFilledWithGhost(optional out XComGameState_StaffSlot GhostOwnerSlot)
{
	if (IsSlotFilled() && IsGhost)
	{
		GhostOwnerSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(CreatorSlotRef.ObjectID));
		return true;
	}

	return false;
}

function bool IsSlotFilledWithCreator()
{
	if (IsSlotFilled() && IsCreator())
	{
		return true;
	}

	return false;
}

function array<XComGameState_StaffSlot> GetAdjacentStaffSlots()
{
	local array<XComGameState_StaffSlot> AdjacentStaffSlots;
	local XComGameState_HeadquartersRoom RoomState;

	RoomState = GetRoomAbsolute();

	if (RoomState != none)
	{
		AdjacentStaffSlots = RoomState.GetAdjacentStaffSlots();
	}

	return AdjacentStaffSlots;
}

function array<XComGameState_StaffSlot> GetAdjacentGhostCreatingStaffSlots()
{
	local array<XComGameState_StaffSlot> AdjacentStaffSlots;
	local XComGameState_HeadquartersRoom RoomState;

	RoomState = GetRoomAbsolute();

	if (RoomState != none)
	{
		AdjacentStaffSlots = RoomState.GetAdjacentGhostCreatingStaffSlots();
	}

	return AdjacentStaffSlots;
}

function bool HasOpenAdjacentStaffSlots(StaffUnitInfo UnitInfo)
{
	local XComGameState_HeadquartersRoom RoomState;

	RoomState = GetRoomAbsolute();

	if (RoomState != none)
	{
		return RoomState.HasOpenAdjacentStaffSlots(UnitInfo);
	}

	return false;
}

function bool HasAvailableAdjacentGhosts()
{
	local XComGameState_HeadquartersRoom RoomState;

	RoomState = GetRoomAbsolute();

	if (RoomState != none)
	{
		return RoomState.HasAvailableAdjacentGhosts();
	}

	return false;
}

// Get all adjacent staffslots which are filled with ghosts created by this staffslot
function array<XComGameState_StaffSlot> GetAdjacentGhostFilledStaffSlots()
{
	local array<XComGameState_StaffSlot> GhostFilledStaffSlots;
	local XComGameState_HeadquartersRoom RoomState;

	if (IsSlotFilledWithCreator())
	{
		RoomState = GetRoomAbsolute();

		if (RoomState != none)
		{
			GhostFilledStaffSlots = RoomState.GetAdjacentGhostFilledStaffSlots(GetAssignedStaffRef());
		}
	}

	return GhostFilledStaffSlots;
}
// End Issue #424

//---------------------------------------------------------------------------------------
function bool IsSlotEmpty()
{
	return (!IsSlotFilled());
}

//---------------------------------------------------------------------------------------
function XComGameState_Unit GetAssignedStaff()
{
	if (IsSlotFilled())
	{
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AssignedStaff.UnitRef.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function XComGameState_Unit GetPairedStaff()
{
	if (IsSlotFilled() && AssignedStaff.PairUnitRef.ObjectID != 0)
	{
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AssignedStaff.PairUnitRef.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function StateObjectReference GetAssignedStaffRef()
{
	return AssignedStaff.UnitRef;
}

//---------------------------------------------------------------------------------------
function StateObjectReference GetPairedStaffRef()
{
	return AssignedStaff.PairUnitRef;
}

//---------------------------------------------------------------------------------------
function bool CanBeEmptied()
{
	if (IsSlotFilled())
	{
		if (!CanStaffBeMoved()) // If the unit is providing a critical function at their current slot, they can't be moved
		{
			return false;
		}
	}
	
	return true;
}

//---------------------------------------------------------------------------------------
private function bool RemoveUnitFromOldSlot(StaffUnitInfo UnitInfo)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot OldStaffSlot;
	
	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID)); // the new unit attempting to fill this staff slot

	// Check the new unit or ghost's current staffing slot and try to empty it
	if (UnitInfo.bGhostUnit)
	{
		OldStaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(UnitInfo.GhostLocation.ObjectID));
	}
	else if (Unit.StaffingSlot.ObjectID != 0)
	{
		OldStaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(Unit.StaffingSlot.ObjectID));
	}

	if (OldStaffSlot != none)
	{
		// if users are trying to assign a unit to the same slot they were previously on, bail out (do nothing).
		if (ObjectID == OldStaffSlot.ObjectID)
		{
			return false; // If old slot is the same as this slot
		}
		else if (!OldStaffSlot.CanBeEmptied())
		{
			return false; // If old slot cannot be emptied
		}

		OldStaffSlot.EmptySlot();
	}

	return true;
}

//---------------------------------------------------------------------------------------
// Attempts to auto-fill this slot with an available Unit
function AutoFillSlot()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot UnitSlotState;
	local array<XComGameState_StaffSlot> AdjacentGhostCreatingSlots;
	local XComGameState_Unit UnitState;
	local StateObjectReference StaffRef;
	local StaffUnitInfo UnitInfo;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	AdjacentGhostCreatingSlots = GetAdjacentGhostCreatingStaffSlots();

	// Cycle through all crew members looking for the unstaffed engineer or scientist to fill the slot, and place them there
	foreach XComHQ.Crew(StaffRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StaffRef.ObjectID));
		UnitSlotState = UnitState.GetStaffSlot();
		UnitInfo.UnitRef = StaffRef;

		// Only assign a ghost unit if there are adjacent slots with available ghosts next to this slot location
		if (AdjacentGhostCreatingSlots.Length > 0)
		{
			if (AdjacentGhostCreatingSlots.Find(UnitSlotState) != INDEX_NONE && UnitSlotState.HasGhosts())
			{
				UnitInfo.bGhostUnit = true;
			}
		}

		// Only allow staffing if this unit is creating available ghost units, or if they are available themselves, and are valid for the slot
		if ((UnitSlotState == none || UnitInfo.bGhostUnit) && ValidUnitForSlot(UnitInfo))
		{
			AssignStaffToSlot(UnitInfo);
			break;
		}
	}
}

//---------------------------------------------------------------------------------------
// Attempts to remove the unit from their current staff slot, and then assign them to this slot
function bool AssignStaffToSlot(StaffUnitInfo UnitInfo)
{
	local XComGameState NewGameState;
	local XComGameState_StaffSlot StaffSlotState;

	// First, if this slot provides ghosts make sure that it can be emptied (and replaced by the new unit)
	// Because all ghost units must be manually unstaffed before the unit creating them can be replaced
	if (MaxAdjacentGhostStaff > 0 && !CanBeEmptied())
	{
		return false;
	}

	// If the unit cannot be removed from its old slot, return false. Otherwise, empty the old staff slot.
	if (!RemoveUnitFromOldSlot(UnitInfo))
	{
		return false;
	}
		
	// Need to update game state for self in case we were emptied earlier (replacing unit in the same slot)
	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	StaffSlotState.FillSlot(UnitInfo); // Fill this slot with the unit
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event On Staff Select");
	`XEVENTMGR.TriggerEvent('OnStaffSelected', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	return true;
}

//---------------------------------------------------------------------------------------
// This function assumes that all validation on whether the unit can actually be placed
// into this staff slot (ValidUnitForSlot) has already been completed!
function FillSlot(StaffUnitInfo UnitInfo, optional XComGameState NewGameState)
{
	local bool bSubmitNewGameState;

	if (NewGameState == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fill Staff Slot");
		bSubmitNewGameState = true;
	}

	EmptySlot(NewGameState);

	if(GetMyTemplate() != none && GetMyTemplate().FillFn != none)
	{
		GetMyTemplate().FillFn(NewGameState, self.GetReference(), UnitInfo);

		`XEVENTMGR.TriggerEvent('StaffUpdated', self, self, NewGameState);
	}
	else
	{
		`RedScreen("StaffSlot Template," @ string(GetMyTemplateName()) $ ", has no FillFn.");
	}

	if (bSubmitNewGameState)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		
		// Alerts and XComHQ updates rely on the history, so only trigger them if the new game state was submitted
		DisplaySlotFilledPopup(UnitInfo);
		UpdateXComHQ();
	}
}

//---------------------------------------------------------------------------------------
function EmptySlot(optional XComGameState NewGameState)
{
	local bool bSubmitNewGameState;

	if(IsSlotFilled())
	{
		if (NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Empty Staff Slot");
			bSubmitNewGameState = true;
		}

		if(GetMyTemplate().EmptyFn != none)
		{
			GetMyTemplate().EmptyFn(NewGameState, self.GetReference());

			`XEVENTMGR.TriggerEvent('StaffUpdated', self, self, NewGameState);
		}
		else
		{
			`RedScreen("StaffSlot Template," @ string(GetMyTemplateName()) $ ", has no EmptyFn.");
		}
		
		if (bSubmitNewGameState)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			UpdateXComHQ(); // XComHQ updates rely on the history, so only update if the new game state was submitted
		}
	}
}

//---------------------------------------------------------------------------------------
function EmptySlotStopProject()
{
	local XComGameState NewGameState;

	if (IsSlotFilled())
	{
		if (GetMyTemplate().EmptyStopProjectFn != none)
		{
			GetMyTemplate().EmptyStopProjectFn(self.GetReference());

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Staff");
			`XEVENTMGR.TriggerEvent('StaffUpdated', self, self, NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			`RedScreen("StaffSlot Template," @ string(GetMyTemplateName()) $ ", has no EmptyStopProjectFn.");
		}

		UpdateXComHQ(); // XComHQ updates rely on the history, so only update if the new game state was submitted
	}
}

//---------------------------------------------------------------------------------------
function UpdateXComHQ()
{
	local XComGameState_HeadquartersXCom XComHQ;

	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.HandlePowerOrStaffingChange();

	`HQPRES.m_kAvengerHUD.UpdateResources();
}

//#############################################################################################
//----------------   DISPLAY   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
private function DisplaySlotFilledPopup(StaffUnitInfo UnitInfo)
{
	local XComGameState_HeadquartersRoom RoomState;

	// Trigger the appropriate popup to tell the player about the benefit they have received by filling this staff slot
	if (!GetMyTemplate().bPreventFilledPopup)
	{
		// If the unit just added is a ghost, update its location to its new staff slot before passing to the Alerts
		if (UnitInfo.bGhostUnit)
		{
			UnitInfo.GhostLocation = GetReference();
		}

		RoomState = GetRoom();
		if (RoomState != none)
		{
			if (RoomState.ClearingRoom)
			{
				`HQPRES.UIClearRoomSlotFilled(RoomState.GetReference(), UnitInfo);
			}
			else if (RoomState.UnderConstruction)
			{
				`HQPRES.UIConstructionSlotFilled(RoomState.GetReference(), UnitInfo);
			}
		}
		else
		{
			`HQPRES.UIStaffSlotFilled(GetFacility().GetReference(), GetMyTemplate(), UnitInfo);
		}
	}
}

//---------------------------------------------------------------------------------------
function bool ShouldDisplayToDoWarning()
{
	if (GetMyTemplate().ShouldDisplayToDoWarningFn != none)
	{
		return GetMyTemplate().ShouldDisplayToDoWarningFn(self.GetReference());
	}

	return true;
}

//---------------------------------------------------------------------------------------
function string GetNameDisplayString()
{
	if(GetMyTemplate().GetNameDisplayStringFn != none)
	{
		return GetMyTemplate().GetNameDisplayStringFn(self);
	}

	return "MISSING DISPLAY INFO";
}

//---------------------------------------------------------------------------------------
function string GetSkillDisplayString()
{
	if (GetMyTemplate().GetSkillDisplayStringFn != none)
	{
		return GetMyTemplate().GetSkillDisplayStringFn(self);
	}

	return "MISSING DISPLAY INFO";
}

//---------------------------------------------------------------------------------------
function string GetBonusDisplayString(optional bool bPreview)
{
	if (GetMyTemplate().GetBonusDisplayStringFn != none)
	{
		return GetMyTemplate().GetBonusDisplayStringFn(self, bPreview);
	}

	return "MISSING BONUS DISPLAY INFO";
}

//---------------------------------------------------------------------------------------
function string GetLocationDisplayString()
{
	if (GetMyTemplate().GetLocationDisplayStringFn != None)
	{
		return GetMyTemplate().GetLocationDisplayStringFn(self);
	}

	return "MISSING DISPLAY INFO";
}

//---------------------------------------------------------------------------------------
function string GetUnitTypeImage()
{
	local XComGameState_Unit Unit;

	Unit = GetAssignedStaff();

	if (Unit != none)
	{
		if (Unit.IsEngineer())
		{
			return class'UIUtilities_Image'.const.EventQueue_Engineer;
		}
		else if (Unit.IsScientist())
		{
			return class'UIUtilities_Image'.const.EventQueue_Science;
		}
		else if (Unit.IsSoldier())
		{
			return class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName());
		}
	}

	return "";
}

//#############################################################################################
//----------------   TYPE   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool IsHidden()
{
	return GetMyTemplate().bHideStaffSlot;
}

//---------------------------------------------------------------------------------------
function bool IsEngineerSlot()
{
	return GetMyTemplate().bEngineerSlot;
}

//---------------------------------------------------------------------------------------
function bool IsScientistSlot()
{
	return GetMyTemplate().bScientistSlot;
}

//---------------------------------------------------------------------------------------
function bool IsSoldierSlot()
{
	return GetMyTemplate().bSoldierSlot;
}

//---------------------------------------------------------------------------------------
// Start Issue #424
// Does this Staffslot create Ghosts?
function bool IsCreator()
{
	return GetMyTemplate().CreatesGhosts;
}
// End Issue #424

//#############################################################################################
//----------------   HELPERS   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacility()
{
	local StateObjectReference EmptyRef;

	if (Facility != EmptyRef)
	{
		return XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facility.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersRoom GetRoom()
{
	local StateObjectReference EmptyRef;

	if (Room != EmptyRef)
	{
		return XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Room.ObjectID));
	}
	else
		return None;
}
//---------------------------------------------------------------------------------------
// Start Issue #424
// If regular GetRoom fails, it will try to get the room with GetFacility
// Cuts down on boilerplate code, based on original boilerplate room code
function XComGameState_HeadquartersRoom GetRoomAbsolute()
{
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_FacilityXCom FacilityState;

	RoomState = GetRoom();
	FacilityState = GetFacility();

	if (FacilityState == none)
	{
		if (RoomState != none)
		{
			return RoomState;
		}
	}
	else
	{
		return FacilityState.GetRoom();
	}

	return none;
}
// End Issue #424
//---------------------------------------------------------------------------------------
function XComGameState_CovertAction GetCovertAction()
{
	local StateObjectReference EmptyRef;

	if (CovertAction != EmptyRef)
	{
		return XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(CovertAction.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function XComGameState_StaffSlot GetLinkedStaffSlot()
{
	local StateObjectReference EmptyRef;

	if(LinkedStaffSlot != EmptyRef)
	{
		return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(LinkedStaffSlot.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
// Start Issue #424

function AddCreator(StateObjectReference CreatorUnit)
{
	local XComGameState_Unit Creator;

	Creator = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(CreatorUnit.ObjectID));
	CreatorRef = Creator.GetReference();
	CreatorSlotRef = Creator.GetStaffSlot().GetReference();
}
function RemoveCreator()
{
	local StateObjectReference EmptyRef;

	CreatorRef = EmptyRef;
	CreatorSlotRef = EmptyRef;
}
function AddGhost(StateObjectReference GhostRef)
{
	Ghosts.AddItem(GhostRef);
}
function RemoveGhost(StateObjectReference GhostRef)
{
	local int i;

	i = Ghosts.Find('ObjectID', GhostRef.ObjectID);

	if (i != INDEX_NONE)
	{
		Ghosts.Remove(i, 1);
	}
}
function bool CreatedBy(StateObjectReference GhostCreatorRef)
{
	return (CreatorRef.ObjectID == GhostCreatorRef.ObjectID);
}
function XComGameState_Unit GetCreator()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(CreatorRef.ObjectID));
}
function XComGameState_StaffSlot GetCreatorSlot()
{
	return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(CreatorSlotRef.ObjectID));
}
function bool HasGhosts()
{
	return (Ghosts.Length > 0);
}
function int AvailableGhosts()
{
	return (MaxAdjacentGhostStaff - Ghosts.Length);
}
function bool HasAvailableGhosts()
{
	return (Ghosts.Length < MaxAdjacentGhostStaff);
}
// End Issue #424
//---------------------------------------------------------------------------------------


DefaultProperties
{
}