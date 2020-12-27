//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChooseClass.uc
//  AUTHOR:  Joe Weinhoffer
//  PURPOSE: Screen that allows the player to select the class in which will a rookie will be trained.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIChooseClass extends UISimpleCommodityScreen;

var array<X2SoldierClassTemplate> m_arrClasses;
var X2SoldierClassTemplate CurrentClass;

var StateObjectReference m_UnitRef; // set in XComHQPresentationLayer

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}

	if (CanAffordItem(iSelectedItem))
	{
		if (OnClassSelected(iSelectedItem))
			Movie.Stack.Pop(self);
		//UpdateData();
	}
	else
	{
		PlayNegativeSound(); // bsg-jrebar (4/20/17): New PlayNegativeSound Function in Parent Class
	}
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	ItemCard.Hide();
	Navigator.SetSelected(List);
	List.SetSelectedIndex(0);
}

simulated function PopulateData()
{
	local Commodity Template;
	local int i;

	List.ClearItems();
	List.bSelectFirstAvailable = false;
	
	for(i = 0; i < arrItems.Length; i++)
	{
		Template = arrItems[i];
		if(i < m_arrRefs.Length)
		{
			Spawn(class'UIInventory_ClassListItem', List.itemContainer).InitInventoryListCommodity(Template, m_arrRefs[i], GetButtonString(i), m_eStyle, , 126);
		}
		else
		{
			Spawn(class'UIInventory_ClassListItem', List.itemContainer).InitInventoryListCommodity(Template, , GetButtonString(i), m_eStyle, , 126);
		}
	}
}

simulated function PopulateResearchCard(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function GetItems()
{
	arrItems = ConvertClassesToCommodities();
}

simulated function array<Commodity> ConvertClassesToCommodities()
{
	local X2SoldierClassTemplate ClassTemplate;
	local int iClass;
	local array<Commodity> arrCommodoties;
	local Commodity ClassComm;
	
	m_arrClasses.Remove(0, m_arrClasses.Length);
	m_arrClasses = GetClasses();
	m_arrClasses.Sort(SortClassesByName);

	for (iClass = 0; iClass < m_arrClasses.Length; iClass++)
	{
		ClassTemplate = m_arrClasses[iClass];
		
		ClassComm.Title = ClassTemplate.DisplayName;
		ClassComm.Image = ClassTemplate.IconImage;
		ClassComm.Desc = ClassTemplate.ClassSummary;
		ClassComm.OrderHours = XComHQ.GetTrainRookieDays() * 24;

		arrCommodoties.AddItem(ClassComm);
	}

	return arrCommodoties;
}

//-----------------------------------------------------------------------------

//This is overwritten in the research archives. 
simulated function array<X2SoldierClassTemplate> GetClasses()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local array<X2SoldierClassTemplate> ClassTemplates;

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach SoldierClassTemplateMan.IterateTemplates(Template, none)
	{		
		SoldierClassTemplate = X2SoldierClassTemplate(Template);
		
		if (TriggerGTSClassValidationEvent(SoldierClassTemplate)) // Issue #814
			ClassTemplates.AddItem(SoldierClassTemplate);
	}

	return ClassTemplates;
}

// Start Issue #814
/// HL-Docs: feature:ValidateGTSClassTraining; issue:814; tags:strategy
/// Triggers an 'ValidateGTSClassTraining' event that allows listeners to control
/// whether the given class can be trained in the GTS.
///
/// The event is fired once for each class whenever the GTS creates a list of classes 
/// to train. The boolean value is based on vanilla checks (NumInForcedDeck and 
/// bMultiplayerOnly), so vanilla behavior is maintained when the value isn't changed
/// by the listener(s), and listeners can base their logic on the vanilla checks or
/// override the result.
///
/// ```event
/// EventID: ValidateGTSClassTraining,
/// EventData: [
///     out bool CanTrainClass,
///     in X2SoldierClassTemplate SoldierClassTemplate
/// ],
/// EventSource: UIChooseClass (ChooseClassScreen),
/// NewGameState: none
/// ```
private function bool TriggerGTSClassValidationEvent(X2SoldierClassTemplate SoldierClassTemplate)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'ValidateGTSClassTraining';
	OverrideTuple.Data.Add(2);
	// boolean to return
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = SoldierClassTemplate.NumInForcedDeck > 0 && !SoldierClassTemplate.bMultiplayerOnly;
	// The soldier class to be validated
	OverrideTuple.Data[1].kind = XComLWTVObject;
	OverrideTuple.Data[1].o = SoldierClassTemplate;

	`XEVENTMGR.TriggerEvent('ValidateGTSClassTraining', OverrideTuple, self, none);

	return OverrideTuple.Data[0].b;
}
// End Issue #814

function int SortClassesByName(X2SoldierClassTemplate ClassA, X2SoldierClassTemplate ClassB)
{	
	if (ClassA.DisplayName < ClassB.DisplayName)
	{
		return 1;
	}
	else if (ClassA.DisplayName > ClassB.DisplayName)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function bool OnClassSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_HeadquartersProjectTrainRookie TrainRookieProject;
	local StaffUnitInfo UnitInfo;

	FacilityState = XComHQ.GetFacilityByName('OfficerTrainingSchool');
	StaffSlotState = FacilityState.GetEmptyStaffSlotByTemplate('OTSStaffSlot');
	
	if (StaffSlotState != none)
	{
		// The Training project is started when the staff slot is filled. Pass in the NewGameState so the project can be found below.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Train Rookie Slot");
		UnitInfo.UnitRef = m_UnitRef;
		StaffSlotState.FillSlot(UnitInfo, NewGameState);
		
		// Find the new Training Project which was just created by filling the staff slot and set the class
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersProjectTrainRookie', TrainRookieProject)
		{
			TrainRookieProject.NewClassName = m_arrClasses[iOption].DataName;
			break;
		}
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
		
		RefreshFacility();
	}

	return true;
}

simulated function RefreshFacility()
{
	local UIScreen QueueScreen;

	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_Academy');
	if (QueueScreen != None)
		UIFacility_Academy(QueueScreen).RealizeFacility();
}

//----------------------------------------------------------------
simulated function OnCancelButton(UIButton kButton) { OnCancel(); }
simulated function OnCancel()
{
	CloseScreen();
}

//==============================================================================

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(OnCancel);
}

defaultproperties
{
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;
	//bConsumeMouseEvents = true;

	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}
