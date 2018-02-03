
class UIAvengerHUD extends UIScreen
	dependson(UIStaffIcon);

var UIPanel					FacilityBG;

var UINavigationHelp	NavHelp;

var UIX2ResourceHeader			ResourceContainer;
//var UIText				ResourceLabel;

var config bool AvengerSecondButtonNavigation;
var UIEventQueue                EventQueue;
var UIToDoWidget				ToDoWidget;
var UIAvengerShortcuts			Shortcuts;
var UIAvengerLinks				Links; 
var UIObjectiveList				Objectives;
var UIX2ScreenHeader			FacilityHeader;
var UIAvengerHUD_SoldierStatusIndicatorContainer StatusIndicatorContainer;

var int CurrentEngineers;
var int CurrentScientists;
var UIList StaffIcons;

var localized string MonthlyLabel;
var localized string EleriumLabel;
var localized string AlloysLabel;
var localized string CoresLabel;
var localized string SciLabel;
var localized string EngLabel;
var localized string ContactsLabel;
var localized string PowerLabel;
 
delegate OnClickStaffIcon(UIPanel Control, int Cmd);

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	InitializeStatusIndicatorContainer();
	InitializeShortcuts(); // Shortcuts before To Do, because ToDo uses the shortcuts placement callback. 
	InitializeToDoWidget();
	InitializeHelpBar();
	InitializeFacilityHeader();
	InitializeResourcePanel();
	InitializeEventQueue();
	InitializeLinks();
	InitializeObjectivesList();

	//Pulse this, to get tooltips and friends to sort properly. 
	Movie.UpdateHighestDepthScreens(); 
}

simulated function Hide()
{
	super.Hide();
}
simulated function Show()
{
	super.Show();
}


// ==============================================================================
//								BOND INDICATORS
// ==============================================================================

simulated function InitializeStatusIndicatorContainer()
{
	StatusIndicatorContainer = Spawn(class'UIAvengerHUD_SoldierStatusIndicatorContainer', self);
	StatusIndicatorContainer.InitPanel();
	StatusIndicatorContainer.DisableNavigation();
}

// ==============================================================================
//								FACILITY HEADER 
// ==============================================================================

simulated function InitializeFacilityHeader()
{
	FacilityHeader = Spawn(class'UIX2ScreenHeader', self);
	FacilityHeader.InitScreenHeader('FacilityHeader');
	FacilityHeader.Hide();
	FacilityHeader.AnchorTopLeft();
	FacilityHeader.DisableNavigation();
}

// ==============================================================================
//								NAV HELP 
// ==============================================================================

simulated function InitializeHelpBar()
{
	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
}

// ==============================================================================
//								RESOURCES PANEL 
// ==============================================================================

simulated function InitializeResourcePanel()
{ 
	ResourceContainer = Spawn(class'UIX2ResourceHeader', self).InitResourceHeader('ResourceContainer');
	ResourceContainer.OnSizeRealized = RefreshStaffIconPlacement; 
	
	StaffIcons = Spawn(class'UIList', self);
	StaffIcons.InitList(, 5, 5, 500, 20, true);
	StaffIcons.bAnimateOnInit = false;
	StaffIcons.ShrinkToFit();
	StaffIcons.bStickyHighlight = false;
	StaffIcons.AnchorTopRight();

}

//Updated the resources based on the current screen context. 
simulated function UpdateResources()
{
	local UIScreen CurrentScreen;

	ClearResources();
	ShowResources();

	CurrentScreen = `SCREENSTACK.GetCurrentScreen();

	switch( CurrentScreen.Class )
	{
	case class'UIFacilityGrid':
		UpdateDefaultResources();
		UpdateStaff();
		break;
	case class'UIStrategyMap':
		UpdateMonthlySupplies();
		UpdateSupplies();
		UpdateIntel();
		UpdateEleriumCrystals();
		UpdateAlienAlloys();
		UpdateScientistScore();
		UpdateEngineerScore();
		UpdateResContacts();
		break;
	case class'UIBlackMarket_Buy':
		UpdateMonthlySupplies();
		UpdateSupplies();
		UpdateIntel();
		UpdateEleriumCrystals();
		UpdateAlienAlloys();
		UpdateScientistScore();
		UpdateEngineerScore();
		break;
	case class'UIBlackMarket_Sell':
		UpdateMonthlySupplies();
		UpdateSupplies();
		break;
	case class'UIResistanceGoods':
		UpdateMonthlySupplies();
		UpdateSupplies();
		UpdateScientistScore();
		UpdateEngineerScore();
		break;
	case class'UIAdventOperations':
		UpdateMonthlySupplies();
		UpdateSupplies();
		UpdateIntel();
		break;
	case class'UIChooseProject':
		UpdateMonthlySupplies();
		UpdateSupplies();
		UpdateEleriumCores();
		UpdateEleriumCrystals();
		UpdateAlienAlloys();
		UpdateEngineerScore();
		break;
	case class'UIOfficerTrainingSchool':
	case class'UIRecruitSoldiers':
		UpdateMonthlySupplies();
		UpdateSupplies();
		break;
	case class'UIBuildFacilities':
	case class'UIChooseFacility':
		UpdateMonthlySupplies();
		UpdateSupplies();
		UpdatePower();
		break;
	case class'UIFacilityUpgrade':
	case class'UIChooseUpgrade':
		UpdateMonthlySupplies();
		UpdateSupplies();
		UpdateEleriumCrystals();
		UpdateAlienAlloys();
		UpdatePower();
		break;
	case class'UIInventory_BuildItems':
		UpdateMonthlySupplies();
		UpdateSupplies();
		UpdateEleriumCrystals();
		UpdateAlienAlloys();
		UpdateEngineerScore();
		break;
	case class'UIChooseResearch':
		UpdateIntel();
		UpdateEleriumCrystals();
		UpdateAlienAlloys();
		UpdateScientistScore();
		UpdateEngineerScore();
		break;
	case class'UIFacility_Labs':
		UpdateScientistScore();
		break;
	case class'UIFacility_PowerGenerator':
		UpdatePower();
		break;
	case class'UIFacility_ResistanceComms':
		UpdateResContacts();
		break;
	case class'UIAlert':		
		if (UIAlert(CurrentScreen).eAlertName == 'eAlert_Contact')
		{
			UpdateIntel();
		}
		else if (UIAlert(CurrentScreen).eAlertName == 'eAlert_Outpost')
		{
			UpdateSupplies();
		}
		else
		{
			HideResources();
		}
		break;
	case class'UICovertActions':
		UpdateSupplies();
		UpdateIntel();
		UpdateAlienAlloys();
		UpdateEleriumCrystals();
		break;
	default:
		HideResources();
		break;
	}
}

simulated function UpdateDefaultResources()
{
	ClearResources();

	UpdateMonthlySupplies();
	UpdateSupplies();
	UpdateIntel();
	UpdateEleriumCrystals();
	UpdateAlienAlloys();
	UpdateScientistScore();
	UpdateEngineerScore();
	UpdateResContacts();
	UpdatePower();

	ShowResources();
}

simulated function UpdateMonthlySupplies()
{
	local int iMonthly;
	local string Monthly, Prefix;

	iMonthly = class'UIUtilities_Strategy'.static.GetResistanceHQ().GetSuppliesReward();
	Prefix = (iMonthly < 0) ? "-" : "+";
	Monthly = class'UIUtilities_Text'.static.GetColoredText("(" $Prefix $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ String(int(Abs(iMonthly))) $")", (iMonthly > 0) ? eUIState_Cash : eUIState_Bad);

	AddResource(MonthlyLabel, Monthly);
}

simulated function UpdateSupplies()
{
	local int iSupplies; 
	local string Supplies, Prefix; 
	
	iSupplies = class'UIUtilities_Strategy'.static.GetResource('Supplies');
	Prefix = (iSupplies < 0) ? "-" : ""; 
	Supplies = class'UIUtilities_Text'.static.GetColoredText(Prefix $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ String(iSupplies), (iSupplies > 0) ? eUIState_Cash : eUIState_Bad);

	AddResource(Caps(class'UIUtilities_Strategy'.static.GetResourceDisplayName('Supplies', iSupplies)), Supplies);
}

simulated function UpdateIntel()
{
	local int iIntel;
	
	iIntel = class'UIUtilities_Strategy'.static.GetResource('Intel');
	AddResource(Caps(class'UIUtilities_Strategy'.static.GetResourceDisplayName('Intel', iIntel)), class'UIUtilities_Text'.static.GetColoredText(String(iIntel), (iIntel > 0) ? eUIState_Normal : eUIState_Bad));
}

simulated function UpdateEleriumCrystals()
{
	local int iEleriumCrystals;

	iEleriumCrystals = class'UIUtilities_Strategy'.static.GetResource('EleriumDust');
	AddResource(EleriumLabel, class'UIUtilities_Text'.static.GetColoredText(String(iEleriumCrystals), (iEleriumCrystals > 0) ? eUIState_Normal : eUIState_Bad));
}

simulated function UpdateAlienAlloys()
{
	local int iAlloys;

	iAlloys = class'UIUtilities_Strategy'.static.GetResource('AlienAlloy');
	AddResource(AlloysLabel, class'UIUtilities_Text'.static.GetColoredText(String(iAlloys), (iAlloys > 0) ? eUIState_Normal : eUIState_Bad));
}

simulated function UpdateEleriumCores()
{
	local int iCores;

	iCores = class'UIUtilities_Strategy'.static.GetResource('EleriumCore');
	AddResource(CoresLabel, class'UIUtilities_Text'.static.GetColoredText(String(iCores), (iCores > 0) ? eUIState_Normal : eUIState_Bad));
}

simulated function UpdateScientistScore()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bBonusActive;
	local int NumSci;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	NumSci = XComHQ.GetNumberOfScientists();
	bBonusActive = (NumSci > XComHQ.GetNumberOfScientists());
	AddResource(SciLabel, class'UIUtilities_Text'.static.GetColoredText(string(NumSci), bBonusActive ? eUIState_Good : eUIState_Normal));
}
simulated function UpdateEngineerScore()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bBonusActive;
	local int NumEng;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	NumEng = XComHQ.GetNumberOfEngineers();
	bBonusActive = (NumEng > XComHQ.GetNumberOfEngineers());
	AddResource(EngLabel, class'UIUtilities_Text'.static.GetColoredText(string(NumEng), bBonusActive ? eUIState_Good : eUIState_Normal));
}

simulated function UpdateResContacts()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int iCurrentContacts, iTotalContacts;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (XComHQ.IsContactResearched())
	{
		iCurrentContacts = XComHQ.GetCurrentResContacts();
		iTotalContacts = XComHQ.GetPossibleResContacts();

		if (iCurrentContacts >= iTotalContacts)
			AddResource(ContactsLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentContacts $ "/" $ iTotalContacts, eUIState_Bad));
		else if (iTotalContacts - iCurrentContacts <= 2)
			AddResource(ContactsLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentContacts $ "/" $ iTotalContacts, eUIState_Warning));
		else
			AddResource(ContactsLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentContacts $ "/" $ iTotalContacts, eUIState_Cash));
	}
}

simulated function UpdatePower()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int iCurrentPower, iTotalPower;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	iCurrentPower = XComHQ.GetPowerConsumed();
	iTotalPower = XComHQ.GetPowerProduced();

	switch(XComHQ.PowerState)
	{
	case ePowerState_Green:
		AddResource(PowerLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentPower $ "/" $ iTotalPower, eUIState_Cash));
		
		break;
	case ePowerState_Yellow:
		AddResource(PowerLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentPower $ "/" $ iTotalPower, eUIState_Warning));
		break;
	case ePowerState_Red:
		AddResource(PowerLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentPower $ "/" $ iTotalPower, eUIState_Bad));
		break;
	}
}

simulated function AddResource(string label, string data)
{
	ResourceContainer.AddResource(label, data);
}

simulated function ClearResources() 
{
	ResourceContainer.ClearResources();
	StaffIcons.Hide();
}

simulated function HideResources()
{
	ResourceContainer.Hide();
	StaffIcons.Hide();
}

simulated function ShowResources()
{
	if( class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M4_ReturnToAvenger') )
	{
		ResourceContainer.Show();
	}
}

simulated function UpdateStaff()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int iNewEngineers, iNewScientists;
	local int i;
	local array<StaffUnitInfo> Scientists, Engineers;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	Engineers = XComHQ.GetUnstaffedEngineers();
	Scientists = XComHQ.GetUnstaffedScientists();

	iNewEngineers = Engineers.Length;
	iNewScientists = Scientists.Length;

	if( iNewEngineers == 0 && iNewScientists == 0 )
	{
		CurrentEngineers = iNewEngineers;
		CurrentScientists = iNewScientists; 
		StaffIcons.ClearItems();
	}
	else
	{
		StaffIcons.ClearItems();

		CurrentEngineers = iNewEngineers;
		CurrentScientists = iNewScientists;

		for( i = 0; i < CurrentEngineers; i++ )
		{
			AddStatusIcon(Engineers[i], eUIFG_Engineer, OnClickEngineerStaffIcon);
		}

		/*for( i = 0; i < CurrentScientists; i++ )
		{
			AddStatusIcon(Scientists[i], eUIFG_Science, OnClickScientistStaffIcon);
		}*/
	}

	if(StaffIcons.ItemCount > 0 )
		StaffIcons.Show();
	else
		StaffIcons.Hide();
}

simulated function AddStatusIcon(StaffUnitInfo UnitInfo, UIStaffIcon.EUIStaffIconType eType = eUIFG_GenericStaff, optional delegate<OnClickStaffIcon> onClick)
{
	local UIStaffIcon Icon;

	Icon = UIStaffIcon(StaffIcons.CreateItem(class'UIStaffIcon'));
	Icon.InitStaffIcon();
	Icon.SetType(eType);
	Icon.BuildStaffTooltip(UnitInfo);
	Icon.ProcessMouseEvents(onClick);
	StaffIcons.OnItemSizeChanged(Icon);
}

function OnClickEngineerStaffIcon(UIPanel Control, int Cmd)
{
	if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
		`HQPRES.UIPersonnel(eUIPersonnel_Engineers,,true);
}
function OnClickScientistStaffIcon(UIPanel Control, int Cmd)
{
	if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
		`HQPRES.UIPersonnel(eUIPersonnel_Scientists,,true);
}

simulated function RefreshStaffIconPlacement()
{
	StaffIcons.SetX(-StaffIcons.GetTotalWidth() - 20);
	StaffIcons.SetY(ResourceContainer.Y + 64);
}

// ==============================================================================
//							EVENT QUEUE 
// ==============================================================================

simulated function InitializeEventQueue()
{
	EventQueue = Spawn(class'UIEventQueue', self).InitEventQueue();
	EventQueue.Hide(); // Start off hidden
}

simulated public function HideEventQueue()
{
	EventQueue.Hide();
}

simulated public function ShowEventQueue( bool bExpand = false )
{
	local XGMissionControlUI MCUI;

	MCUI = XGMissionControlUI(XComHQPresentationLayer(Movie.Pres).GetMgr( class'XGMissionControlUI' ));
	MCUI.UpdateEvents();

	if( MCUI.m_kEvents.Length > 0 )
	{
		EventQueue.UpdateEventQueue(MCUI.m_kEvents, bExpand, false);
		EventQueue.Show();
	}
	else
		EventQueue.Hide();
}

// ==============================================================================
//							TODO WIDGET
// ==============================================================================

simulated function InitializeToDoWidget()
{
	ToDoWidget = Spawn(class'UIToDoWidget', self);
	ToDoWidget.InitToDoWidget('ToDoWidget');
}


// ==============================================================================
//							SHORTCUTS WIDGET
// ==============================================================================

simulated function InitializeShortcuts()
{
	Shortcuts = Spawn(class'UIAvengerShortcuts', self);
	Shortcuts.InitShortcuts('UIAvengerShortcuts');
	Navigator.SetSelected(Shortcuts); 
}

// ==============================================================================
//							LINKS WIDGET
// ==============================================================================

simulated function InitializeLinks()
{
	Links = Spawn(class'UIAvengerLinks', self);
	Links.InitLinks('UIAvengerLinks');
}

// ==============================================================================
//							OBJECTIVES LIST
// ==============================================================================

simulated function InitializeObjectivesList()
{
	Objectives = Spawn(class'UIObjectiveList', self).InitObjectiveList();
}

// ==============================================================================
//							DEBUG FUNCTIONS  
// ==============================================================================

simulated function DEBUG_ShowPanels()
{
	if( !ResourceContainer.bIsVisible )
		UpdateDefaultResources(); 
}

simulated function DEBUG_HidePanels()
{
	ClearResources(); 
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (EventQueue.OnUnrealCommand(cmd, arg))
	{
		return true;
	}
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_P:
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
			`HQPRES.UIPersonnel(eUIPersonnel_All, class'UIUtilities_Strategy'.static.OnPersonnelSelected);
			break;
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_L3:
			if (ToDoWidget.bIsVisible)
			{
				OpenNotificationsScreen();
			}

			break;
		default:
			bHandled = false;
			break;
	}

	if( bHandled ) return true; 

	if (NavHelp.OnUnrealCommand(cmd, arg))
	{
		return true;
	}

	if( Shortcuts.OnUnrealCommand(cmd, arg) ) return true; 
	
	return super.OnUnrealCommand(cmd, arg);
}

simulated function OpenNotificationsScreen()
{
	if(ToDoWidget != None)
	{
		ToDoWidget.OpenScreen();
	}
}
//==============================================================================

defaultproperties
{
	bHideOnLoseFocus = false;
	bProcessMouseEventsIfNotFocused = true;
}
