class Helper extends object;

// Generic Helper functions used by multiple different mods
// Placed here for convenience and clarity

// Updates StaffSlots of a facility to match changes done by the mod
static function UpdateStaffSlots(name FacilityName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local X2FacilityTemplate FacilityTemplate;
	local XComGameState_StaffSlot StaffSlotState;
	local X2StaffSlotTemplate StaffSlotTemplate;
	local X2StrategyElementTemplateManager StrategyElementTemplateManager;
	local int i;
	local bool ShouldAdd, ShouldReplace;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Facility = XComHQ.GetFacilityByName(FacilityName);
	
	if (Facility != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Updating Existing StaffSlots to accept incoming changes");
		StrategyElementTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		FacilityTemplate = Facility.GetMyTemplate();

		for (i = 0; i < FacilityTemplate.StaffSlotDefs.Length; i++)
		{
			if (i < Facility.StaffSlots.Length)
			{
				//Check for Template mismatch
				if(Facility.GetStaffSlot(i).GetMyTemplateName() != FacilityTemplate.StaffSlotDefs[i].StaffSlotTemplateName)
				{
					ShouldAdd = true;
					ShouldReplace = true;
				}
			}
			else
			{
				ShouldAdd = true;
				ShouldReplace = false;
			}

			if (ShouldAdd)
			{
				ShouldAdd = false;
				StaffSlotTemplate = X2StaffSlotTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate(FacilityTemplate.StaffSlotDefs[i].StaffSlotTemplateName));

				// Create slot state and link to this facility
				StaffSlotState = StaffSlotTemplate.CreateInstanceFromTemplate(NewGameState);
				StaffSlotState.Facility = Facility.GetReference();

				// Check for starting the slot locked
				if(FacilityTemplate.StaffSlotDefs[i].bStartsLocked)
				{
					StaffSlotState.LockSlot();
				}					

				if (ShouldReplace)
				{
					// Replace staffslot item
					Facility.StaffSlots[i] = StaffSlotState.GetReference();
				}
				else
				{
					// Add game state and add to staffslots list
					Facility.StaffSlots.InsertItem(i, StaffSlotState.GetReference());	
				}
			}
		}

		if (NewGameState.GetNumGameStateObjects() > 0)
		{
			XComGameInfo(class'Engine'.static.GetCurrentWorldInfo().Game).GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			`XCOMHistory.CleanupPendingGameState(NewGameState);
		}
	}
}

static function array<XComGameState_FacilityXCom> GetAllFacilitiesByName(name FacilityName)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local StateObjectReference FacilityRef;
	local array<XComGameState_FacilityXCom> Facilities;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach XcomHQ.Facilities(FacilityRef)
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));

		if(Facility.GetMyTemplateName() == FacilityName)
		{
			Facilities.AddItem(Facility);
		}
	}

	return Facilities;
}

static function array<XComGameState_StaffSlot> GetAllStaffSlots(optional bool FilledOnly = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local StateObjectReference FacilityRef;
	local XComGameState_StaffSlot StaffSlot;
	local array<XComGameState_StaffSlot> StaffSlots;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	foreach XComHQ.Facilities(FacilityRef)
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));

		for (i = 0; i < Facility.StaffSlots.Length; i++)
		{
			StaffSlot = Facility.GetStaffSlot(i);

			if (FilledOnly)
			{
				if (Staffslot.IsSlotFilled())
				{
					StaffSlots.AddItem(StaffSlot);
				}
			}
			else
			{
				StaffSlots.AddItem(StaffSlot);
			}
		}
	}

	return StaffSlots;
}

static function array<XComGameState_StaffSlot> GetAllStaffSlotsByName(name StaffSlotName, optional bool FilledOnly = false)
{
	local XComGameState_StaffSlot StaffSlot;
	local array<XComGameState_StaffSlot> StaffSlots, MatchingSlots;

	StaffSlots = GetAllStaffSlots(FilledOnly);

	foreach StaffSlots(Staffslot)
	{
		if (StaffSlot.GetMyTemplateName() == StaffSlotName)
		{
			MatchingSlots.AddItem(StaffSlot);
		}
	}

	return MatchingSlots;
}

static function array<XComGameState_StaffSlot> GetAllGhosts()
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlot, GhostCreator;
	local array<XComGameState_StaffSlot> GhostCreators, ActiveGhosts;
    local StateObjectReference GhostRef;

	History = `XCOMHISTORY;
	GhostCreators = GetAllGhostCreators();

	foreach GhostCreators(GhostCreator)
	{
		foreach GhostCreator.Ghosts(GhostRef)
		{
			StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(GhostRef.ObjectID));

			if (StaffSlot != none)
			{
				ActiveGhosts.AddItem(StaffSlot);
			}
		}
	}

	return ActiveGhosts;
}

static function array<XComGameState_StaffSlot> GetAllGhostCreators()
{
	local XComGameState_StaffSlot StaffSlot;
	local array<XComGameState_StaffSlot> StaffSlots, GhostCreators;

	// We only care about filled StaffSlots as empty slots do not produce ghosts by themselves
	StaffSlots = GetAllStaffSlots(true);

	foreach StaffSlots(StaffSlot)
	{
		if (StaffSlot.IsCreator())
		{
			GhostCreators.AddItem(StaffSlot);
		}
	}

	return GhostCreators;
}

