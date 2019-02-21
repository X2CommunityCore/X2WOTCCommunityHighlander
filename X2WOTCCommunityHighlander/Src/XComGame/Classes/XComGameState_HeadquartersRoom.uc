//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersRoom.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for a room within the avenger
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersRoom extends XComGameState_BaseObject native(Core);

var() StateObjectReference Facility; //If a facility is built in this room, this is a reference to it
var() int MapIndex; // used to find location on avenger baseview map
var() int GridRow; // If this room is in the facility grid, store which row it is located on
var() array<StateObjectReference> AdjacentRooms; // References to the rooms adjacent to this one
var() name SpecialFeature;

var() protected name m_BuildSlotTemplateName;
//var() StateObjectReference BuildSlot;
var() array<StateObjectReference> BuildSlots; //List of slots that staff can be assigned to
var() bool ClearingRoom;
var() StateObjectReference ClearRoomProject;
var() LootResults Loot;

var() bool UnderConstruction;
var() bool Locked; // room is locked due to excavation requirements
var() bool ConstructionBlocked;

var() bool bTutorialLocked; // room is locked due to tutorial state

var() bool UpdateRoomMap;
var() bool bHasShieldedPowerCoil;
var() bool bSpecialRoomFeatureCleared;
var() String strLootGiven;		//  A string representation of the loot given to the player after clearing the room, if any exists

var() string SpecialFeatureUnclearedMapName;
var() string SpecialFeatureClearedMapName;

//---------------------------------------------------------------------------------------
event OnCreation(optional X2DataTemplate Template)
{
	super.OnCreation(Template);

	// Every room needs at least one build slot
	AddBuildSlot(GetParentGameState());
}

//---------------------------------------------------------------------------------------
function AddBuildSlot(XComGameState NewGameState)
{
	local X2StaffSlotTemplate StaffSlotTemplate;
	local XComGameState_StaffSlot StaffSlotState;
	
	StaffSlotTemplate = X2StaffSlotTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(m_BuildSlotTemplateName));
	
	if (StaffSlotTemplate != none)
	{
		StaffSlotState = StaffSlotTemplate.CreateInstanceFromTemplate(NewGameState);
		StaffSlotState.Room = GetReference(); //make sure the staff slot knows what room it is in

		BuildSlots.AddItem(StaffSlotState.GetReference());
	}
}

function PopulateBuildCrew(XGBaseCrewMgr Mgr)
{
	local int Idx;
	local vector RoomOffset;
	local XComGameState_StaffSlot StaffSlot;
	
	if (`GAME.GetGeoscape().m_kBase.m_arrLvlStreaming_Anim[MapIndex] == None)
		return;

	RoomOffset = GetLocation();

	if (HasStaff())
	{
		for ( Idx = 0; Idx < BuildSlots.Length; ++Idx)
		{
			StaffSlot = GetBuildSlot(Idx);
			if (StaffSlot.IsSlotFilled() && !StaffSlot.IsSlotFilledWithGhost())
			{
				Mgr.AddCrew(MapIndex, none, StaffSlot.AssignedStaff.UnitRef, StaffSlot.GetMyTemplate().MatineeSlotName, RoomOffset, true);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function bool IsIndestructible()
{
	local XComGameState_FacilityXCom FacilityState;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facility.ObjectID));

	if(FacilityState != none)
	{
		if(FacilityState.GetMyTemplate().bIsIndestructible)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function Vector GetLocation()
{
	local XComHQ_RoomLocation RoomLoc;
	local string tagtofind;

	tagtofind = "" $ MapIndex;

	foreach `XWORLDINFO.AllActors(class'XComHQ_RoomLocation', RoomLoc)
	{
		if (RoomLoc.RoomName == name(tagtofind))
			return RoomLoc.Location;
	}

	return vect(0,0,0);
}
//---------------------------------------------------------------------------------------
function array<Vector> GetUILocations()
{
	local XComHQ_RoomLocationUI RoomLoc;
	local string tagtofind;
	local array<Vector> Locations; 

	tagtofind = "" $ MapIndex;

	foreach `XWORLDINFO.AllActors(class'XComHQ_RoomLocationUI', RoomLoc)
	{
		if (RoomLoc.RoomName == name(tagtofind))
			Locations.AddItem(RoomLoc.Location);
	}

	return Locations;
}

//---------------------------------------------------------------------------------------
function bool HasFacility()
{
	return (Facility.ObjectID != 0);
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacility()
{
	return XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facility.ObjectID));
}

//---------------------------------------------------------------------------------------
function X2SpecialRoomFeatureTemplate GetSpecialFeature()
{
	return X2SpecialRoomFeatureTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(SpecialFeature));
}

//---------------------------------------------------------------------------------------
function bool HasSpecialFeature()
{
	return (GetSpecialFeature() != none);
}

//---------------------------------------------------------------------------------------
function string GetSpecialFeatureLabel()
{
	if (bSpecialRoomFeatureCleared)
		return GetSpecialFeature().ClearedDisplayName;
	else
		return GetSpecialFeature().UnclearedDisplayName;
}

//---------------------------------------------------------------------------------------
function string GetClearingInProgressLabel()
{
	if (HasSpecialFeature())
		return GetSpecialFeature().ClearingInProgressText;
}

//---------------------------------------------------------------------------------------
function string GetClearingHaltedLabel()
{
	if (HasSpecialFeature())
		return GetSpecialFeature().ClearingHaltedText;
}

//---------------------------------------------------------------------------------------
function bool HasShieldedPowerCoil()
{
	return bHasShieldedPowerCoil;
}

//#############################################################################################
//---------------------   ADJACENCIES   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool IsRoomAdjacent(StateObjectReference RoomRef)
{
	return (AdjacentRooms.Find('ObjectID', RoomRef.ObjectID) != INDEX_NONE);
}

//---------------------------------------------------------------------------------------
function array<XComGameState_StaffSlot> GetAdjacentStaffSlots()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersRoom AdjacentRoom;
	local XComGameState_FacilityXCom AdjacentFacility;
	local XComGameState_StaffSlot AdjacentStaffSlot;
	local array<XComGameState_StaffSlot> AdjacentStaffSlots;
	local StateObjectReference RoomRef;
	local int idx;

	History = `XCOMHISTORY;

	foreach AdjacentRooms(RoomRef)
	{
		AdjacentRoom = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(RoomRef.ObjectID));

		if (AdjacentRoom.HasFacility())
		{
			AdjacentFacility = AdjacentRoom.GetFacility();

			for (idx = 0; idx < AdjacentFacility.StaffSlots.Length; idx++)
			{
				AdjacentStaffSlot = AdjacentFacility.GetStaffSlot(idx);
				AdjacentStaffSlots.AddItem(AdjacentStaffSlot);
			}
		}
		else if (!AdjacentRoom.Locked)
		{
			for (idx = 0; idx < AdjacentRoom.BuildSlots.Length; idx++)
			{
				AdjacentStaffSlot = AdjacentRoom.GetBuildSlot(idx);
				AdjacentStaffSlots.AddItem(AdjacentStaffSlot);
			}
		}
	}

	return AdjacentStaffSlots;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_StaffSlot> GetAdjacentGhostCreatingStaffSlots()
{
	local array<XComGameState_StaffSlot> AdjacentStaffSlots, AdjacentGhostStaffSlots;
	local int idx;
	
	AdjacentStaffSlots = GetAdjacentStaffSlots();

	for (idx = 0; idx < AdjacentStaffSlots.Length; idx++)
	{
		if (AdjacentStaffSlots[idx].MaxAdjacentGhostStaff > 0)
		{
			AdjacentGhostStaffSlots.AddItem(AdjacentStaffSlots[idx]);
		}
	}

	return AdjacentGhostStaffSlots;
}

//---------------------------------------------------------------------------------------
// Get any adjacent staff slots which are filled with ghosts created by the provided unit
function array<XComGameState_StaffSlot> GetAdjacentGhostFilledStaffSlots(StateObjectReference GhostCreatorRef)
{
	local array<XComGameState_StaffSlot> AdjacentStaffSlots, GhostFilledStaffSlots;
	local int idx;

	AdjacentStaffSlots = GetAdjacentStaffSlots();

	for (idx = 0; idx < AdjacentStaffSlots.Length; idx++)
	{
		if (AdjacentStaffSlots[idx].GetAssignedStaffRef().ObjectID == GhostCreatorRef.ObjectID)
		{
			GhostFilledStaffSlots.AddItem(AdjacentStaffSlots[idx]);
		}
	}

	return GhostFilledStaffSlots;
}

//---------------------------------------------------------------------------------------
function bool HasOpenAdjacentStaffSlots(StaffUnitInfo UnitInfo)
{
	local array<XComGameState_StaffSlot> AdjacentSlots;
	local XComGameState_StaffSlot AdjacentSlot;

	AdjacentSlots = GetAdjacentStaffSlots();
	foreach AdjacentSlots(AdjacentSlot)
	{
		if (AdjacentSlot.IsSlotEmpty() && !AdjacentSlot.IsLocked() && AdjacentSlot.ValidUnitForSlot(UnitInfo))
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasAvailableAdjacentGhosts()
{
	local array<XComGameState_StaffSlot> GhostCreatingSlots;
	local XComGameState_StaffSlot GhostCreatingSlot;

	GhostCreatingSlots = GetAdjacentGhostCreatingStaffSlots();
	foreach GhostCreatingSlots(GhostCreatingSlot)
	{
		if (GhostCreatingSlot.AvailableGhostStaff > 0)
		{
			return true;
		}
	}

	return false;
}

//#############################################################################################
//---------------------   PROJECTS   ----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool HasBuildProject()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameState_HeadquartersProjectClearRoom ClearProject;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;
	local XComGameState_FacilityXCom FacilityState;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
		ClearProject = XComGameState_HeadquartersProjectClearRoom(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
		UpgradeProject = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));

		if(FacilityProject != none)
		{
			if(FacilityProject.AuxilaryReference == self.GetReference())
			{
				return true;
			}
		}
		else if(ClearProject != none)
		{
			if(ClearProject.ProjectFocus == self.GetReference())
			{
				return true;
			}
		}
		else if(UpgradeProject != none)
		{
			FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(UpgradeProject.AuxilaryReference.ObjectID));

			if(FacilityState != none)
			{
				if(FacilityState.Room == self.GetReference())
				{
					return true;
				}
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectBuildFacility GetBuildFacilityProject()
{
	local XComGameState_HeadquartersXcom XComHQ;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));

		if(FacilityProject != none)
		{
			if(FacilityProject.AuxilaryReference == self.GetReference())
			{
				return FacilityProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectUpgradeFacility GetUpgradeProject()
{
	local XComGameState_HeadquartersXcom XComHQ;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;
	local XComGameState_FacilityXCom FacilityState;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		UpgradeProject = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));

		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(UpgradeProject.AuxilaryReference.ObjectID));

		if(FacilityState != none)
		{
			if(FacilityState.Room == self.GetReference())
			{
				return UpgradeProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_HeadquartersRoom> GetNeighboringRooms()
{
	local XComGameState_HeadquartersRoom Room;
	local array<XComGameState_HeadquartersRoom> Neighbors;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_HeadquartersRoom', Room)
	{
		if(class'X2StrategyGameRulesetDataStructures'.static.AreRoomsAdjacent(self,Room))
		{
			Neighbors.AddItem(Room);
		}
	}

	return Neighbors;
}

//---------------------------------------------------------------------------------------
// A function to compute the string representation of the loot found in this room
// The loot is generated and added to XComHQ's LootRecovered array in order to easily create a string of items and their quantities
// After creating the string, the pending game state is cleared to erase the temporary changes
function String GetLootString(optional bool bShowAmounts = false)
{
	local XComGameState PendingState;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Item ItemState;
	local name LootName;
	local String LootString;
	local int idx;

	if (Loot.LootToBeCreated.Length > 0)
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

		PendingState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Temporarily adding room loot to inventory to get preview string");
		XComHQ = XComGameState_HeadquartersXCom(PendingState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		// First give each piece of loot to XComHQ so it can be collected and added to LootRecovered, which will stack it automatically
		foreach Loot.LootToBeCreated(LootName)
		{
			ItemTemplate = ItemTemplateManager.FindItemTemplate(LootName);
			ItemState = ItemTemplate.CreateInstanceFromTemplate(PendingState);
			XComHQ.PutItemInInventory(PendingState, ItemState, true);
		}

		// Then create the loot string for the room
		for (idx = 0; idx < XComHQ.LootRecovered.Length; idx++)
		{
			ItemState = XComGameState_Item(PendingState.GetGameStateForObjectID(XComHQ.LootRecovered[idx].ObjectID));

			if (ItemState != none)
			{
				LootString $= ItemState.GetMyTemplate().GetItemFriendlyName();
				if (bShowAmounts)
				{
					LootString $= " x" $ ItemState.Quantity;
				}

				if (idx < XComHQ.LootRecovered.Length - 1)
				{
					LootString $= ", ";
				}
			}
		}

		// cleanup pending game state and restore work per hour to correct value from the history
		`XCOMHISTORY.CleanupPendingGameState(PendingState);
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(LootString);
}

//#############################################################################################
//----------------   EXCAVATION   -------------------------------------------------------------
//#############################################################################################

simulated function StartClearRoom()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersRoom NewRoomState;
	local XComGameState_HeadquartersProjectClearRoom ClearProject;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StaffUnitInfo> BuilderInfoList;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (XComHQ.bInstantSingleExcavation)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Instant Room Clear");

		XComHQ = XComGameState_HeadquartersXCom( NewGameState.ModifyStateObject( class'XComGameState_HeadquartersXCom', XComHQ.ObjectID ) );
		XComHQ.bInstantSingleExcavation = false;

		class'XComGameStateContext_HeadquartersOrder'.static.ClearRoomShared( NewGameState, self, XComHQ );

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_ProjectComplete");

		BuilderInfoList.Length = 0;
		`HQPRES.UIClearRoomComplete(GetReference(), GetSpecialFeature(), BuilderInfoList);

		// Actually add the loot which was generated from clearing to the inventory
		class'XComGameStateContext_StrategyGameRule'.static.AddLootToInventory();
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Start Clearing Room");
		
		NewRoomState = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', ObjectID));
		NewRoomState.ClearingRoom = true;
		NewRoomState.UpdateRoomMap = true;

		ClearProject = XComGameState_HeadquartersProjectClearRoom(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectClearRoom'));
		ClearProject.SetProjectFocus(GetReference(), NewGameState, GetReference());
		NewRoomState.ClearRoomProject = ClearProject.GetReference();
	
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.Projects.AddItem(ClearProject.GetReference());
		//XComHQ.PayStrategyCost(NewGameState, NewRoomState.GetSpecialFeature().GetDepthBasedCostFn(NewRoomState), XComHQ.RoomSpecialFeatureCostScalars);

		`XEVENTMGR.TriggerEvent('ExcavationStarted', ClearProject, ClearProject, NewGameState);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		class'UIUtilities_Strategy'.static.GetXComHQ().HandlePowerOrStaffingChange();

		`XSTRATEGYSOUNDMGR.PlaySoundEvent(NewRoomState.GetSpecialFeature().StartProjectAkEvent);

		//UIFacilityGrid(Screen).UpdateData();
		//`HQPRES.m_kAvengerHUD.UpdateResources();

		// If an unstaffed engineer exists, alert the player that they could help clear this room
		if (NewRoomState.GetNumEmptyBuildSlots() > 0 && (XComHQ.GetNumberOfUnstaffedEngineers() > 0 || NewRoomState.HasAvailableAdjacentGhosts()))
		{
			`HQPRES.UIClearRoomSlotOpen(NewRoomState.GetReference());
		}
	}

	// force avenger rooms to update
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

function XComGameState_HeadquartersProjectClearRoom GetClearRoomProject()
{	
	return XComGameState_HeadquartersProjectClearRoom(`XCOMHISTORY.GetGameStateForObjectID(ClearRoomProject.ObjectID));
}

//---------------------------------------------------------------------------------------
function int GetEstimatedClearHours()
{
	local int iHours;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectClearRoom ClearProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");
	
	// Need to add the room to the NewGameState so the Project can calculate its estimates properly
	XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', ObjectID));

	ClearProject = XComGameState_HeadquartersProjectClearRoom(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectClearRoom'));
	ClearProject.SetProjectFocus(GetReference(), NewGameState, GetReference());
	
	iHours = ClearProject.GetProjectedNumHoursRemaining();
		
	NewGameState.PurgeGameStateForObjectID(ClearProject.ObjectID);
	History.CleanupPendingGameState(NewGameState);

	return iHours;
}

//#############################################################################################
//----------------   STAFFING   ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function XComGameState_StaffSlot GetBuildSlot(optional int i = 0)
{
	if (i >= 0 && i < BuildSlots.Length)
	{
		return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(BuildSlots[i].ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function bool IsStaffedHere(StateObjectReference UnitRef)
{
	local int i;
	for (i = 0; i < BuildSlots.Length; ++i)
	{
		if (GetBuildSlot(i).GetAssignedStaffRef() == UnitRef)
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function int GetTotalStaffSkill()
{
	local XComGameState_StaffSlot BuildSlot;
	local int i, TotalSkill;

	for (i = 0; i < BuildSlots.Length; ++i)
	{
		BuildSlot = GetBuildSlot(i);
		if (BuildSlot.IsSlotFilled())
			TotalSkill += BuildSlot.GetAssignedStaff().GetSkillLevel();
	}
	return TotalSkill;
}

//---------------------------------------------------------------------------------------
function bool HasStaff()
{
	local XComGameState_StaffSlot BuildSlot;
	local int i;

	for (i = 0; i < BuildSlots.Length; ++i)
	{
		BuildSlot = GetBuildSlot(i);
		if (BuildSlot.IsSlotFilled())
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function int GetNumEmptyBuildSlots()
{
	local XComGameState_StaffSlot BuildSlot;
	local int i, openBuildSlots;

	for (i = 0; i < BuildSlots.Length; ++i)
	{
		BuildSlot = GetBuildSlot(i);
		if (!BuildSlot.IsLocked() && BuildSlot.IsSlotEmpty())
			openBuildSlots++;
	}
	return openBuildSlots;
}

//---------------------------------------------------------------------------------------
function int GetNumFilledBuildSlots()
{
	local XComGameState_StaffSlot BuildSlot;
	local int i, assignedStaff;

	for (i = 0; i < BuildSlots.Length; ++i)
	{
		BuildSlot = GetBuildSlot(i);
		if (BuildSlot.IsSlotFilled())
			assignedStaff++;
	}
	return assignedStaff;
}

//---------------------------------------------------------------------------------------
function int GetEmptyBuildSlotIndex()
{
	local XComGameState_StaffSlot BuildSlot;
	local int i;

	for (i = 0; i < BuildSlots.Length; ++i)
	{
		BuildSlot = GetBuildSlot(i);
		if (BuildSlot.IsSlotEmpty())
			return i;
	}
	return -1;
}

//---------------------------------------------------------------------------------------
// Returns the index of this build slot out of the group of slots which are filled.
// Used for displaying different values in build slot bonus strings in the same room
function int GetOrderAmongFilledBuildSlots(XComGameState_StaffSlot SlotState, bool bPreview)
{
	local XComGameState_StaffSlot BuildSlot;
	local int i, iOrder, NumFilledBuildSlots;

	NumFilledBuildSlots = GetNumFilledBuildSlots();

	for (i = 0; i < BuildSlots.Length; ++i)
	{
		BuildSlot = GetBuildSlot(i);

		if (BuildSlot.IsSlotFilled())
			iOrder++;

		if (BuildSlot.ObjectID == SlotState.ObjectID)
		{
			if (bPreview)
			{
				// If this slot is earlier in the order than filled slots, and we are previewing it, set this slot to be at the end of the order
				// since it will be the newest to be filled. Actual bonus values will update automatically after it is filled.
				if (iOrder < NumFilledBuildSlots)
				{
					iOrder = NumFilledBuildSlots;
				}

				iOrder++; // Assuming that this slot is filled, so increase the order
			}
						
			return iOrder;
		}
	}
	return -1;
}

//---------------------------------------------------------------------------------------
function EmptyAllBuildSlots(XComGameState NewGameState)
{
	local XComGameState_StaffSlot BuildSlot;
	local int i;

	for (i = 0; i < BuildSlots.Length; ++i)
	{
		BuildSlot = GetBuildSlot(i);
		if (BuildSlot.IsSlotFilled())
		{
			BuildSlot.EmptySlot(NewGameState);
		}
	}
}

function bool ShowOverlayStaffingIcons()
{	
	return true;
}

DefaultProperties
{    
	m_BuildSlotTemplateName = "BuildStaffSlot";
}
