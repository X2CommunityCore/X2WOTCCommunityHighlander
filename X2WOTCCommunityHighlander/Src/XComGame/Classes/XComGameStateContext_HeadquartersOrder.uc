//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_HeadquartersOrder.uc
//  AUTHOR:  Ryan McFall  --  11/22/2013
//  PURPOSE: Meta data for an order given in the headquarters. Examples of orders are
//           Hiring soldiers, Changing research priorities, building items, constructing
//           facilities. This context exists for prototyping purposes, and at some point 
//           will be dismantled and made mod-friendly like the ability context. In the 
//           meantime, this context will make that process easier
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_HeadquartersOrder extends XComGameStateContext;

//These enums will eventually be converted into a template system like abilities 
enum HeadquartersOrderType
{
	eHeadquartersOrderType_HireStaff,
	eHeadquartersOrderType_HireStaffExplicit,
	eHeadquartersOrderType_FireStaff,
	eHeadquartersOrderType_ResearchCompleted,
	eHeadquartersOrderType_FacilityConstructionCompleted,
	eHeadquartersOrderType_CancelFacilityConstruction,
	eHeadquartersOrderType_StartFacilityRepair,
	eHeadquartersOrderType_FacilityRepairCompleted,
	eHeadquartersOrderType_AddResource,
	eHeadquartersOrderType_ItemConstructionCompleted,
	eHeadquartersOrderType_CancelItemConstruction,
	eHeadquartersOrderType_ClearRoomCompleted,
	eHeadquartersOrderType_CancelClearRoom,
	eHeadquartersOrderType_StartUnitHealing,
	eHeadquartersOrderType_UnitHealingCompleted,
	eHeadquartersOrderType_UpgradeFacilityCompleted,
	eHeadquartersOrderType_CancelUpgradeFacility,
	eHeadquartersOrderType_TrainRookieCompleted,
	eHeadquartersOrderType_CancelTrainRookie,
	eHeadquartersOrderType_RespecSoldierCompleted,
	eHeadquartersOrderType_CancelRespecSoldier,
	eHeadquartersOrderType_PsiTrainingCompleted,
	eHeadquartersOrderType_CancelPsiTraining,
	eHeadquartersOrderType_RemoveTraitsCompleted,
	eHeadquartersOrderType_CancelRemoveTraits,
};

struct HeadquartersOrderInputContext
{	
	var HeadquartersOrderType OrderType;

	//These context vars are used for orders that involve trading a resource for a quantity of something. Ie. Hiring staff, buying mcguffins
	//***************************
	var name AquireObjectTemplateName;
	var int Quantity;
	var int Cost;
	var int CostResourceType;
	var StateObjectReference AcquireObjectReference;
	var StateObjectReference FacilityReference;
	//***************************
};

var HeadquartersOrderInputContext InputContext;

//XComGameStateContext interface
//***************************************************
/// <summary>
/// Should return true if ContextBuildGameState can return a game state, false if not. Used internally and externally to determine whether a given context is
/// valid or not.
/// </summary>
function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

/// <summary>
/// Override in concrete classes to converts the InputContext into an XComGameState
/// </summary>
function XComGameState ContextBuildGameState()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_HeadquartersOrder NewGameStateContext;
	local int Index;

	History = `XCOMHISTORY;

	//Make the new game state
	NewGameState = History.CreateNewGameState(true, self);
	NewGameStateContext = XComGameStateContext_HeadquartersOrder(NewGameState.GetContext());

	//Add new or updated state objects
	switch(InputContext.OrderType)
	{
	case eHeadquartersOrderType_HireStaff:
		for( Index = 0; Index < NewGameStateContext.InputContext.Quantity; ++Index )
		{			
			BuildNewUnit(NewGameState, InputContext.AquireObjectTemplateName);
		}
		break;
	case eHeadquartersOrderType_HireStaffExplicit:
		RecruitUnit(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_FireStaff:
		FireUnit(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_ResearchCompleted:
		CompleteResearch(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_FacilityConstructionCompleted:
		CompleteFacilityConstruction(NewGameState, InputContext.AcquireObjectReference, InputContext.FacilityReference);
		break;
	case eHeadquartersOrderType_CancelFacilityConstruction:
		CancelFacilityConstruction(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_StartFacilityRepair:
		break;
	case eHeadquartersOrderType_FacilityRepairCompleted:
		break;
	case eHeadquartersOrderType_AddResource:
		AddResource(NewGameState, InputContext.AquireObjectTemplateName, InputContext.Quantity);
		break;
	case eHeadquartersOrderType_ItemConstructionCompleted:
		CompleteItemConstruction(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelItemConstruction:
		CancelItemConstruction(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_ClearRoomCompleted:
		CompleteClearRoom(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelClearRoom:
		CancelClearRoom(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_StartUnitHealing:
		StartUnitHealing(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_UnitHealingCompleted:
		CompleteUnitHealing(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_UpgradeFacilityCompleted:
		CompleteUpgradeFacility(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelUpgradeFacility:
		CancelUpgradeFacility(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_TrainRookieCompleted:
		CompleteTrainRookie(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_RespecSoldierCompleted:
		CompleteRespecSoldier(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_PsiTrainingCompleted:
		CompletePsiTraining(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_RemoveTraitsCompleted:
		CompleteRemoveTraits(NewGameState, InputContext.AcquireObjectReference);
		break;
	case eHeadquartersOrderType_CancelTrainRookie:
	case eHeadquartersOrderType_CancelRespecSoldier:
	case eHeadquartersOrderType_CancelPsiTraining:
	case eHeadquartersOrderType_CancelRemoveTraits:
		CancelSoldierTrainingProject(NewGameState, InputContext.AcquireObjectReference);
		break;
		
	}

	//@TODO Deduct resources
	if( InputContext.Cost > 0 )
	{
		
	}

	return NewGameState;
}

/// <summary>
/// Convert the ResultContext and AssociatedState into a set of visualization tracks
/// </summary>
protected function ContextBuildVisualization()
{	
}

/// <summary>
/// Returns a short description of this context object
/// </summary>
function string SummaryString()
{
	local string OutputString;
	OutputString = string(InputContext.OrderType);
	OutputString = OutputString @ "( Type:" @ InputContext.AquireObjectTemplateName @ "Qty:" @ InputContext.Quantity @ ")";
	return OutputString;
}

/// <summary>
/// Returns a string representation of this object.
/// </summary>
function string ToString()
{
	return "";
}
//***************************************************

private function BuildNewUnit(XComGameState AddToGameState, name UseTemplate)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item BuildItem;
	local XGCharacterGenerator CharGen;
	local TSoldier CharacterGeneratorResult;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2SoldierClassTemplateManager SoldierClassTemplateManager;
	local array<name> aTemplateNames;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;


	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);
	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate(UseTemplate);
	`assert(CharacterTemplate != none);

	//Make the unit from a template
	//*************************
	NewUnitState = CharacterTemplate.CreateInstanceFromTemplate(AddToGameState);
	
	//Fill in the unit's stats and appearance
	NewUnitState.RandomizeStats();	
	CharGen = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);	
	`assert(CharGen != none);
	CharacterGeneratorResult = CharGen.CreateTSoldier(UseTemplate);
	NewUnitState.SetTAppearance(CharacterGeneratorResult.kAppearance);
	NewUnitState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
	NewUnitState.SetCountry(CharacterGeneratorResult.nmCountry);
	if(!NewUnitState.HasBackground())
		NewUnitState.GenerateBackground(, CharGen.BioCountryName);

	//*************************

	//If we added a soldier, give the soldier default items. Eventually we will want to be pulling items from the armory...
	//***************
	if( UseTemplate == 'Soldier' )
	{
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('KevlarArmor'));
		BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);			
		BuildItem.ItemLocation = eSlot_None;
		NewUnitState.AddItemToInventory(BuildItem, eInvSlot_Armor, AddToGameState);

		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('AssaultRifle_CV'));
		BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);			
		BuildItem.ItemLocation = eSlot_RightHand;
		NewUnitState.AddItemToInventory(BuildItem, eInvSlot_PrimaryWeapon, AddToGameState);

		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('Pistol'));
		BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);				
		BuildItem.ItemLocation = eSlot_RightThigh;
		NewUnitState.AddItemToInventory(BuildItem, eInvSlot_SecondaryWeapon, AddToGameState);


		SoldierClassTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		SoldierClassTemplateManager.GetTemplateNames(aTemplateNames);

		NewUnitState.SetSoldierClassTemplate(aTemplateNames[`SYNC_RAND(aTemplateNames.Length)]);
		NewUnitState.BuySoldierProgressionAbility(AddToGameState, 0, 0); // Setup the first rank ability
	}
	//***************

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.AddToCrew(AddToGameState, NewUnitState);
	}
}

private function RecruitUnit(XComGameState AddToGameState, StateObjectReference UnitReference)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_Unit NewUnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewUnitState = XComGameState_Unit(AddToGameState.GetGameStateForObjectID(UnitReference.ObjectID));
		if (NewUnitState == none)
			NewUnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitReference.ObjectID));
		`assert(NewUnitState != none);
		XComHQ.AddToCrew(AddToGameState, NewUnitState);
	}

	if(ResistanceHQ != none)
	{
		ResistanceHQ = XComGameState_HeadquartersResistance(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
		ResistanceHQ.Recruits.RemoveItem(UnitReference);
	}
}

private function FireUnit(XComGameState AddToGameState, StateObjectReference UnitReference)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference EmptyRef;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.RemoveFromCrew(UnitReference);
		
	for(idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		if(XComHQ.Squad[idx] == UnitReference)
		{
			XComHQ.Squad[idx] = EmptyRef;
			break;
		}
	}

	UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitReference.ObjectID));
	class'X2StrategyGameRulesetDataStructures'.static.ResetAllBonds(AddToGameState, UnitState);
	// REMOVE FIRED UNIT?
	AddToGameState.RemoveStateObject(UnitReference.ObjectID);
}

private function CompleteResearch(XComGameState AddToGameState, StateObjectReference TechReference)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local XComGameState_Tech TechState;
	local X2TechTemplate TechTemplate;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.TechsResearched.AddItem(TechReference);
		for(idx = 0; idx < XComHQ.Projects.Length; idx++)
		{
			ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
			
			if (ResearchProject != None && ResearchProject.ProjectFocus == TechReference)
			{
				XComHQ.Projects.RemoveItem(ResearchProject.GetReference());
				AddToGameState.RemoveStateObject(ResearchProject.GetReference().ObjectID);

				if (ResearchProject.bProvingGroundProject)
				{
					FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ResearchProject.AuxilaryReference.ObjectID));

					if (FacilityState != none)
					{
						FacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
						FacilityState.BuildQueue.RemoveItem(ResearchProject.GetReference());
					}
				}
				else if (ResearchProject.bShadowProject)
				{
					XComHQ.EmptyShadowChamber(AddToGameState);
				}

				break;
			}
		}
	}

	TechState = XComGameState_Tech(AddToGameState.ModifyStateObject(class'XComGameState_Tech', TechReference.ObjectID));
	TechState.TimesResearched++;
	TechState.TimeReductionScalar = 0;
	TechState.CompletionTime = `GAME.GetGeoscape().m_kDateTime;

	TechState.OnResearchCompleted(AddToGameState);
	
	TechTemplate = TechState.GetMyTemplate(); // Get the template for the completed tech
	if (!TechState.IsInstant() && !TechTemplate.bShadowProject && !TechTemplate.bProvingGround)
	{
		XComHQ.CheckForInstantTechs(AddToGameState);
		
		// Do not allow two breakthrough techs back-to-back, jump straight to inspired check
		if (TechTemplate.bBreakthrough || !XComHQ.CheckForBreakthroughTechs(AddToGameState))
		{
			// If there is no breakthrough activated, check to activate inspired tech
			XComHQ.CheckForInspiredTechs(AddToGameState);
		}
	}
	
	// Do not clear Breakthrough and Inspired references until after checking for instant
	// to avoid game state conflicts when potentially choosing a new breakthrough tech if the tech tree is exhausted
	if (TechState.bBreakthrough && XComHQ.CurrentBreakthroughTech.ObjectID == TechState.ObjectID)
	{
		XComHQ.CurrentBreakthroughTech.ObjectID = 0;
	}
	else if (TechState.bInspired && XComHQ.CurrentInspiredTech.ObjectID == TechState.ObjectID)
	{
		XComHQ.CurrentInspiredTech.ObjectID = 0;
	}
	
	if (TechState.GetMyTemplate().bProvingGround)
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(AddToGameState, 'ResAct_ProvingGroundProjectsCompleted');
	else
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(AddToGameState, 'ResAct_TechsCompleted');

	`XEVENTMGR.TriggerEvent('ResearchCompleted', TechState, ResearchProject, AddToGameState);
}

private function CompleteFacilityConstruction(XComGameState AddToGameState, StateObjectReference RoomReference, StateObjectReference FacilityReference)
{
	local XComGameState_HeadquartersRoom Room, NewRoom;
	local XComGameState_FacilityXCom Facility, NewFacility;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameStateHistory History;
	local int idx;

	History = `XCOMHISTORY;

	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomReference.ObjectID));
	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityReference.ObjectID));

	if(Room != none && Facility != none)
	{
		NewRoom = XComGameState_HeadquartersRoom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
	
		NewFacility = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', Facility.ObjectID));

		NewFacility.Room = NewRoom.GetReference();   
		NewFacility.ConstructionDateTime = `STRATEGYRULES.GameTime;
		NewFacility.bPlayFlyIn = true;

		NewRoom.Facility = NewFacility.GetReference();
		NewRoom.UpdateRoomMap = true;
		NewRoom.UnderConstruction = false;

		if (NewRoom.GetBuildSlot().IsSlotFilled())
		{
			NewFacility.Builder = NewRoom.GetBuildSlot().GetAssignedStaffRef();
			NewRoom.GetBuildSlot().EmptySlot(AddToGameState);
		}
		
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Facilities.AddItem(FacilityReference);

			for(idx = 0; idx < XComHQ.Projects.Length; idx++)
			{
				FacilityProject = XComGameState_HeadquartersProjectBuildFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
				
				if(FacilityProject != none)
				{
					if(FacilityProject.ProjectFocus == FacilityReference)
					{
						XComHQ.Projects.RemoveItem(FacilityProject.GetReference());
						AddToGameState.RemoveStateObject(FacilityProject.ObjectID);
						break;
					}
				}
			}
		}

		`XEVENTMGR.TriggerEvent('AnalyticsFacilityContruction', NewFacility, FacilityProject, AddToGameState);
		`XEVENTMGR.TriggerEvent('FacilityConstructionCompleted', NewFacility, XComHQ, AddToGameState);
	}
}

private function CancelFacilityConstruction(XComGameState AddToGameState, StateObjectReference ProjectReference)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBuildFacility ProjectState;
	local XComGameState_HeadquartersRoom Room, NewRoom;
	local XComGameStateHistory History;
	local X2FacilityTemplate FacilityTemplate;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(ProjectReference.ObjectID));
	
	if(ProjectState != none)
	{
		FacilityTemplate = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID)).GetMyTemplate();
		Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));
		if(Room != none)
		{
			NewRoom = XComGameState_HeadquartersRoom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
			NewRoom.UpdateRoomMap = true;
			NewRoom.UnderConstruction = false;
			
			if (NewRoom.GetBuildSlot().IsSlotFilled())
			{
				NewRoom.GetBuildSlot().EmptySlot(AddToGameState);
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.RefundStrategyCost(AddToGameState, FacilityTemplate.Cost, XComHQ.FacilityBuildCostScalars, ProjectState.SavedDiscountPercent);
			XComHQ.Projects.RemoveItem(ProjectReference);
			AddToGameState.RemoveStateObject(ProjectState.ProjectFocus.ObjectID);
			AddToGameState.RemoveStateObject(ProjectReference.ObjectID);
		}

		`XEVENTMGR.TriggerEvent('AnalyticsFacilityContruction', none, ProjectState, AddToGameState);
	}
}

static function AddResource(XComGameState AddToGameState, name ResourceTemplateName, int iQuantity)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Resource, NewResource;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.Inventory.Length; idx++)
	{
		Resource = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));

		if(Resource != none)
		{
			if(Resource.GetMyTemplateName() == ResourceTemplateName)
			{
				NewResource = XComGameState_Item(AddToGameState.ModifyStateObject(class'XComGameState_Item', Resource.ObjectID));
				NewResource.Quantity += iQuantity;
				
				if(NewResource.Quantity < 0)
				{
					NewResource.Quantity = 0;
				}
			}
		}
	}
}

static function CompleteItemConstruction(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXcom FacilityState, NewFacilityState;
	local XComGameState_HeadquartersProjectBuildItem ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectBuildItem(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));

		if(FacilityState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewFacilityState.BuildQueue.RemoveItem(ProjectRef);
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
			//if(NewFacilityState.RefundPercent > 0)
			//{
			//	XComHQ.AddResource(AddToGameState, 'Supplies', Round(float(ItemState.GetMyTemplate().SupplyCost) * 
			//		class'X2StrategyGameRulesetDataStructures'.default.BuildItemProject_CostScalar * (float(NewFacilityState.RefundPercent)/100.0)));
			//}
			
			ItemState.OnItemBuilt(AddToGameState);

			XComHQ.PutItemInInventory(AddToGameState, ItemState);
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);

			`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', ItemState, ItemState, AddToGameState);
		}
	}
}

static function CancelItemConstruction(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXCom FacilityState, NewFacilityState;
	local XComGameState_HeadquartersProjectBuildItem ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));

		if(FacilityState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewFacilityState.BuildQueue.RemoveItem(ProjectRef);
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.RefundStrategyCost(AddToGameState, ItemState.GetMyTemplate().Cost, XComHQ.ItemBuildCostScalars, ProjectState.SavedDiscountPercent);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ProjectFocus.ObjectID);
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function CancelProvingGroundProject(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXCom FacilityState, NewFacilityState;
	local XComGameState_HeadquartersProjectProvingGround ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));

		if (FacilityState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewFacilityState.BuildQueue.RemoveItem(ProjectRef);
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.RefundStrategyCost(AddToGameState, TechState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars, ProjectState.SavedDiscountPercent);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function ClearRoomShared(XComGameState AddToGameState, XComGameState_HeadquartersRoom RoomState, XComGameState_HeadquartersXCom NewXComHQ)
{
	local XComGameState_HeadquartersRoom NewRoomState;
	local StateObjectReference EmptyRef;

	NewRoomState = XComGameState_HeadquartersRoom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', RoomState.ObjectID));
	NewRoomState.ClearingRoom = false;
	NewRoomState.ClearRoomProject = EmptyRef;
	NewRoomState.bSpecialRoomFeatureCleared = true;
	NewRoomState.UpdateRoomMap = true;

	if (NewRoomState.HasStaff())
	{
		NewRoomState.EmptyAllBuildSlots(AddToGameState);;
	}

	NewRoomState.GetSpecialFeature().OnClearFn(AddToGameState, NewRoomState);
	if(NewRoomState.GetSpecialFeature().bRemoveOnClear)
	{
		NewRoomState.SpecialFeature = '';
	}

	NewXComHQ.UnlockAdjacentRooms(AddToGameState, NewRoomState);
}

static function CompleteClearRoom(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_HeadquartersProjectClearRoom ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectClearRoom(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	if(ProjectState != none)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if(RoomState != none)
		{
			ClearRoomShared( AddToGameState, RoomState, XComHQ );
		}

		XComHQ.Projects.RemoveItem(ProjectState.GetReference());
		AddToGameState.RemoveStateObject(ProjectState.ObjectID);		
	}
}

static function CancelClearRoom(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersRoom RoomState, NewRoomState;
	local XComGameState_HeadquartersProjectClearRoom ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectClearRoom(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if(RoomState != none)
		{
			NewRoomState = XComGameState_HeadquartersRoom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', RoomState.ObjectID));
			NewRoomState.UpdateRoomMap = true;
			NewRoomState.ClearingRoom = false;
			
			if (NewRoomState.GetBuildSlot().IsSlotFilled())
			{
				NewRoomState.GetBuildSlot().EmptySlot(AddToGameState);
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function StartUnitHealing(XComGameState AddToGameState, StateObjectReference UnitRef)
{
	local XComGameState_Unit UnitState, NewUnitState;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if(UnitState != none)
	{
		NewUnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		
		ProjectState = XComGameState_HeadquartersProjectHealSoldier(AddToGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
		ProjectState.SetProjectFocus(UnitRef);

		NewUnitState.SetStatus(eStatus_Healing);

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.AddItem(ProjectState.GetReference());

			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshFacilityPatients();
		}
	}
}

static function CompleteUnitHealing(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_Unit UnitState, NewUnitState;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local XComGameState_HeadquartersProjectPsiTraining PsiProjectState;
	local XComGameState_HeadquartersProjectRecoverWill WillProject;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameStateHistory History;
	local StaffUnitInfo UnitInfo;
	local array<StrategyCostScalar> CostScalars;
	local int SlotIndex;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectHealSoldier(History.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if(UnitState != none && XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);

			NewUnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewUnitState.SetCurrentStat(eStat_HP, NewUnitState.GetBaseStat(eStat_HP));
			NewUnitState.SetStatus(eStatus_Active);

			if(NewUnitState.bRecoveryBoosted && !NewUnitState.NeedsWillRecovery())
			{
				NewUnitState.UnBoostSoldier(true);

				// HQ Refund Cost
				CostScalars.Length = 0;
				XComHQ.RefundStrategyCost(AddToGameState, class'X2StrategyElement_XpackFacilities'.default.BoostSoldierCost, CostScalars);
			}

			// Set Unit to ready if needed
			if (NewUnitState.GetMentalState() != eMentalState_Ready)
			{
				foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectRecoverWill', WillProject)
				{
					if (WillProject.ProjectFocus == NewUnitState.GetReference())
					{
						XComHQ.Projects.RemoveItem(WillProject.GetReference());
						AddToGameState.RemoveStateObject(WillProject.ObjectID);
						break;
					}
				}

				NewUnitState.SetCurrentStat(eStat_Will, NewUnitState.GetMinWillForMentalState(eMentalState_Ready));
				NewUnitState.UpdateMentalState();
				WillProject = XComGameState_HeadquartersProjectRecoverWill(AddToGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectRecoverWill'));
				WillProject.SetProjectFocus(NewUnitState.GetReference(), AddToGameState);
				XComHQ.Projects.AddItem(WillProject.GetReference());
			}
						
			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshFacilityPatients();

			`XEVENTMGR.TriggerEvent( 'UnitHealCompleted', UnitState, ProjectState, AddToGameState );
		}		
		
		// If the unit is a Psi Operative who was training an ability before they got hurt, continue the training automatically
		if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
		{
			PsiProjectState = XComHQ.GetPsiTrainingProject(UnitState.GetReference());
			if (PsiProjectState != none) // A paused Psi Training project was found for the unit
			{
				// Get the Psi Chamber facility and staff the unit in it if there is an open slot
				FacilityState = XComHQ.GetFacilityByName('PsiChamber');
				SlotIndex = FacilityState.GetEmptySoldierStaffSlotIndex();
				if (SlotIndex >= 0)
				{
					// Restart the paused training project
					PsiProjectState = XComGameState_HeadquartersProjectPsiTraining(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectPsiTraining', PsiProjectState.ObjectID));
					PsiProjectState.bForcePaused = false;

					UnitInfo.UnitRef = UnitState.GetReference();
					FacilityState.GetStaffSlot(SlotIndex).FillSlot(UnitInfo, AddToGameState);
				}
			}
		}
	}
}

static function CompleteUpgradeFacility(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXcom FacilityState, NewFacilityState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local XComGameState_HeadquartersProjectUpgradeFacility ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));
		UpgradeState = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if(FacilityState != none && UpgradeState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));			
			NewFacilityState.Upgrades.AddItem(ProjectState.ProjectFocus);

			UpgradeState.OnUpgradeAdded(AddToGameState, NewFacilityState);
		}
		
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		`XEVENTMGR.TriggerEvent('UpgradeCompleted', UpgradeState, FacilityState, AddToGameState);
	}
}

static function CancelUpgradeFacility(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectUpgradeFacility ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if(ProjectState != none)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));

		if (FacilityState != none)
		{
			RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(FacilityState.Room.ObjectID));

			if (RoomState != none)
			{
				if (RoomState.GetBuildSlot().IsSlotFilled())
				{
					RoomState.GetBuildSlot().EmptySlot(AddToGameState);		
				}
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function CompleteTrainRookie(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectTrainRookie ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;
	local int idx;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectTrainRookie(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			// Set the soldier status back to active, and rank them up to their new class
			UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.SetXPForRank(1);
			UnitState.StartingRank = 1;
			UnitState.RankUpSoldier(AddToGameState, ProjectState.NewClassName); // The class template name was set when the project began
			UnitState.ApplySquaddieLoadout(AddToGameState, XComHQ);
			UnitState.ApplyBestGearLoadout(AddToGameState); // Make sure the squaddie has the best gear available
			UnitState.SetStatus(eStatus_Active);

			// If there are bonus ranks, do those rank ups here
			for(idx = 0; idx < XComHQ.BonusTrainingRanks; idx++)
			{
				UnitState.SetXPForRank(idx + 2);
				UnitState.StartingRank++;
				UnitState.RankUpSoldier(AddToGameState);
			}

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}
	}
}

static function CompleteRespecSoldier(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectRespecSoldier ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;
	local int i;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectRespecSoldier(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			// Set the soldier status back to active, and rank them up to their new class
			UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.ResetSoldierAbilities(); // First clear all of the current abilities
			for (i = 0; i < UnitState.GetRankAbilities(0).Length; ++i) // Then give them their squaddie ability back
			{
				UnitState.BuySoldierProgressionAbility(AddToGameState, 0, i);
			}
			UnitState.SetStatus(eStatus_Active);
			//UnitState.EquipOldItems(AddToGameState);

			// Give the unit back any AP which they had spent on abilities
			UnitState.AbilityPoints += UnitState.SpentAbilityPoints;
			UnitState.SpentAbilityPoints = 0; // And reset the spent AP tracker

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}
	}
}

static function CompletePsiTraining(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectPsiTraining ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectPsiTraining(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			// Set the soldier status back to active, and rank them up as a squaddie Psi Operative
			UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

			// Rank up the solder. Will also apply class if they were a Rookie.
			UnitState.RankUpSoldier(AddToGameState, 'PsiOperative');
			
			// Teach the soldier the ability which was associated with the project
			UnitState.BuySoldierProgressionAbility(AddToGameState, ProjectState.iAbilityRank, ProjectState.iAbilityBranch);

			if (UnitState.GetRank() == 1) // They were just promoted to Initiate
			{
				UnitState.ApplyBestGearLoadout(AddToGameState); // Make sure the squaddie has the best gear available
			}

			UnitState.SetStatus(eStatus_Active);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
			
			`XEVENTMGR.TriggerEvent('PsiTrainingCompleted', UnitState, UnitState, AddToGameState);
		}		
	}
}

static function CompleteRemoveTraits(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectRemoveTraits ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectRemoveTraits(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			// Set the soldier status back to active, and rank them up to their new class
			UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.RecoverFromAllTraits(AddToGameState);
			UnitState.SetStatus(eStatus_Active);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}
	}
}

static function CancelSoldierTrainingProject(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProject ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProject(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if (UnitState != none)
		{
			// Set the soldier status back to active
			UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.SetStatus(eStatus_Active);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
}

static function IssueHeadquartersOrder(const out HeadquartersOrderInputContext UseInputContext)
{
	local XComGameStateContext_HeadquartersOrder NewOrderContext;

	NewOrderContext = XComGameStateContext_HeadquartersOrder(class'XComGameStateContext_HeadquartersOrder'.static.CreateXComGameStateContext());
	NewOrderContext.InputContext = UseInputContext;

	`GAMERULES.SubmitGameStateContext(NewOrderContext);
}