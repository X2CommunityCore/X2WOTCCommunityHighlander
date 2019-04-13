
class UIPersonnel extends UIScreen
	implements(IUISortableScreen);

enum EUIPersonnelType
{
	eUIPersonnel_Soldiers,
	eUIPersonnel_Scientists,
	eUIPersonnel_Engineers,
	eUIPersonnel_Deceased,
	eUIPersonnel_All
};

enum EPersonnelSortType
{
	ePersonnelSoldierSortType_Name,
	ePersonnelSoldierSortType_Status,
	ePersonnelSoldierSortType_Time,
	ePersonnelSoldierSortType_Location,
	ePersonnelSoldierSortType_Rank,
	ePersonnelSoldierSortType_Class,
	ePersonnelSoldierSortType_Kills,
	ePersonnelSoldierSortType_Missions,
	ePersonnelSoldierSortType_Operations,
};

// these are set in UIFlipSortButton
var bool m_bFlipSort;
var EPersonnelSortType m_eSortType;

//bsg-crobinson (5.15.17): Sorting variables
var array<EPersonnelSortType> m_aSortTypeOrder; 
var int m_iSortTypeOrderIndex; 
var bool m_bDirtySortHeaders;
//bsg-crobinson (5.15.17): end
//----------------------------------------------------------------------------
// MEMBERS

// UI
var string Title; 

var public int m_eListType;
var array<int> m_arrNeededTabs;

var int m_iMaskWidth;
var int m_iMaskHeight;

var int m_eCurrentTab;

var UIList m_kList;
var UIPanel ListBG;
var array<UIButton> m_arrTabButtons;
var UIPanel m_kSoldierSortHeader;
var UIPanel m_kDeceasedSortHeader;
var UIPanel m_kPersonnelSortHeader;

var public localized string m_strTitle;
var public localized string m_strScientistTab;
var public localized string m_strEngineerTab;
var public localized string m_strSoldierTab;
var public localized string m_strDeceasedTab;
var public localized string m_strAvailableSlot;
var public localized string m_strToggleSort;
var public localized string m_strChangeColumn; //bsg-crobinson (5.15.17): String for change columns

var localized string m_strButtonLabels[EPersonnelSortType.EnumCount]<BoundEnum = EPersonnelSortType>;
var localized string m_strButtonValues[EPersonnelSortType.EnumCount]<BoundEnum = EPersonnelSortType>;
var localized string m_strEmptyListLabels[EUIPersonnelType.EnumCount]<BoundEnum = EUIPersonnelType>;


// Gameplay
var XComGameState GameState; // setting this allows us to display data that has not yet been submitted to the history 
var XComGameState_HeadquartersXCom HQState;
var array<StateObjectReference> m_arrSoldiers;
var array<StateObjectReference> m_arrScientists;
var array<StateObjectReference> m_arrEngineers;
var array<StateObjectReference> m_arrDeceased;
var StateObjectReference SlotRef;

// Delegates
var bool m_bRemoveWhenUnitSelected;
var public delegate<OnPersonnelSelected> onSelectedDelegate;
delegate OnPersonnelSelected(StateObjectReference selectedUnitRef);
delegate OnButtonClickedDelegate(UIButton ButtonControl);
delegate int SortDelegate(StateObjectReference A, StateObjectReference B);

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot SlotState;
	
	// Init UI
	super.InitScreen(InitController, InitMovie, InitName);
	
	ListBG = Spawn(class'UIPanel', self);
	ListBG.InitPanel('SoldierListBG'); 
	ListBG.bShouldPlayGenericUIAudioEvents = false;
	ListBG.Show();

	m_kList = Spawn(class'UIList', self);
	m_kList.bIsNavigable = true;
	m_kList.InitList('listAnchor',,, m_iMaskWidth, m_iMaskHeight);
	m_kList.bStickyHighlight = false;
	
	ListBG.ProcessMouseEvents(m_kList.OnChildMouseEvent);

	History = `XCOMHISTORY;
	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));

	if(SlotState != none)
	{
		if(SlotState.IsSoldierSlot())
		{
			m_arrNeededTabs.AddItem(eUIPersonnel_Soldiers);
		}

		if(SlotState.IsScientistSlot())
		{
			m_arrNeededTabs.AddItem(eUIPersonnel_Scientists);
		}

		if(SlotState.IsEngineerSlot())
		{
			m_arrNeededTabs.AddItem(eUIPersonnel_Engineers);
		}
	}
	else
	{
		if(m_eListType == eUIPersonnel_All)
		{
			m_arrNeededTabs.AddItem(eUIPersonnel_Soldiers);
			m_arrNeededTabs.AddItem(eUIPersonnel_Engineers);
			m_arrNeededTabs.AddItem(eUIPersonnel_Scientists);
		}
		else
		{
			m_arrNeededTabs.AddItem(m_eListType);
		}
	}

	// Create Soldiers Tab + List
	if( m_arrNeededTabs.Find(eUIPersonnel_Soldiers) != INDEX_NONE )
	{
		m_arrTabButtons[eUIPersonnel_Soldiers] = CreateTabButton('SoldierTab', m_strSoldierTab, SoldiersTab);
		m_arrTabButtons[eUIPersonnel_Soldiers].bIsNavigable = false;
	}

	// Create Engineer Tab + 
	if( m_arrNeededTabs.Find(eUIPersonnel_Engineers) != INDEX_NONE )
	{
		m_arrTabButtons[eUIPersonnel_Engineers] = CreateTabButton('EngineerTab', m_strEngineerTab, EngineersTab);
		m_arrTabButtons[eUIPersonnel_Engineers].bIsNavigable = false;
	}

	// Create Scientist Tab + List
	if( m_arrNeededTabs.Find(eUIPersonnel_Scientists) != INDEX_NONE )
	{
		m_arrTabButtons[eUIPersonnel_Scientists] = CreateTabButton('ScientistTab', m_strScientistTab, ScientistTab);
		m_arrTabButtons[eUIPersonnel_Scientists].bIsNavigable = false;
	}

	// Create Deceased Tab + List
	if( m_arrNeededTabs.Find(eUIPersonnel_Deceased) != INDEX_NONE )
	{
		m_arrTabButtons[eUIPersonnel_Deceased] = CreateTabButton('DeceasedTab', m_strDeceasedTab, DeceasedTab);
		m_arrTabButtons[eUIPersonnel_Deceased].bIsNavigable = false;
	}


	// ---------------------------------------------------------

	CreateSortHeaders();
	UpdateNavHelp();
	RefreshTitle();
	SpawnNavHelpIcons();
	
	// ---------------------------------------------------------
	if(m_eListType != eUIPersonnel_All)
		SwitchTab(m_eListType);
	else
		SwitchTab(m_arrNeededTabs[0]);

	if( `ISCONTROLLERACTIVE == false )
	{
		EnableNavigation();

		Navigator.LoopSelection = true;
		Navigator.SelectedIndex = 0;
		Navigator.OnSelectedIndexChanged = SelectedHeaderChanged;
	}
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	if(HQState.IsObjectiveCompleted('T0_M2_WelcomeToArmory'))
	{
		NavHelp.AddBackButton(OnCancel);

		// Don't allow jumping to the geoscape from the armory in the tutorial or when coming from squad select
		if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') != eObjectiveState_InProgress
			&& !`SCREENSTACK.IsInStack(class'UISquadSelect'))
			NavHelp.AddGeoscapeButton();

		if( `ISCONTROLLERACTIVE )
		{
			NavHelp.AddLeftHelp(m_strToggleSort, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
			NavHelp.AddLeftHelp(m_strChangeColumn, class'UIUtilities_Input'.const.ICON_DPAD_HORIZONTAL); //bsg-crobinson (5.15.17): Add change column icon
		}
		
		// bsg-jrebar (4.5.17): end
	}
	else if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddLeftHelp(m_strToggleSort, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
		NavHelp.AddLeftHelp(m_strChangeColumn, class'UIUtilities_Input'.const.ICON_DPAD_HORIZONTAL); //bsg-crobinson (5.15.17): Add change column icon
	}
}

simulated function SpawnNavHelpIcons()
{
	local UIGamepadIcons ButtonGraphic;

	if( m_arrNeededTabs.length < 2 || !`ISCONTROLLERACTIVE ) return; // no bumper buttons on mouse/keyboard

	ButtonGraphic = Spawn(class'UIGamepadIcons', Self);
	ButtonGraphic.InitGamepadIcon('NavButtonLeftBumper', class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LB_L1);
	ButtonGraphic.SetSize(43.623, 26.845);
	ButtonGraphic.AnchorCenter();
	ButtonGraphic.SetX(-320);
	ButtonGraphic.SetY(-430);

	ButtonGraphic = Spawn(class'UIGamepadIcons', Self);
	ButtonGraphic.InitGamepadIcon('NavButtonRightBumper', class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RB_R1);
	ButtonGraphic.SetSize(43.623, 26.845);
	ButtonGraphic.AnchorCenter();
	ButtonGraphic.SetX(320);
	ButtonGraphic.SetY(-430);
}

simulated function SelectedHeaderChanged(int NavigationIndex)
{
	SwitchTab(m_arrNeededTabs[NavigationIndex]);
}

simulated function CreateSortHeaders()
{
	m_kSoldierSortHeader = Spawn(class'UIPanel', self);
	m_kSoldierSortHeader.bIsNavigable = false;
	m_kSoldierSortHeader.InitPanel('soldierSort', 'SoldierSortHeader');
	m_kSoldierSortHeader.Hide();

	m_kDeceasedSortHeader = Spawn(class'UIPanel', self);
	m_kDeceasedSortHeader.bIsNavigable = false;
	m_kDeceasedSortHeader.InitPanel('deceasedSort', 'DeceasedSortHeader');
	m_kDeceasedSortHeader.Hide();
	
	m_kPersonnelSortHeader = Spawn(class'UIPanel', self);
	m_kPersonnelSortHeader.bIsNavigable = false;
	m_kPersonnelSortHeader.InitPanel('personnelSort', 'PersonnelSortHeader');
	m_kPersonnelSortHeader.Hide();

	// Create Soldiers header
	if( m_arrNeededTabs.Find(eUIPersonnel_Soldiers) != INDEX_NONE )
	{
		Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("rankButton", ePersonnelSoldierSortType_Rank, m_strButtonLabels[ePersonnelSoldierSortType_Rank]);
		Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("nameButton", ePersonnelSoldierSortType_Name, m_strButtonLabels[ePersonnelSoldierSortType_Name]);
		Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("classButton", ePersonnelSoldierSortType_Class, m_strButtonLabels[ePersonnelSoldierSortType_Class]);
		Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("statusButton", ePersonnelSoldierSortType_Status, m_strButtonLabels[ePersonnelSoldierSortType_Status], m_strButtonValues[ePersonnelSoldierSortType_Status]);
	}

	// Create Scientist / Engineer header 
	if(m_arrNeededTabs.Find(eUIPersonnel_Scientists) != INDEX_NONE || m_arrNeededTabs.Find(eUIPersonnel_Engineers) != INDEX_NONE )
	{
		Spawn(class'UIFlipSortButton', m_kPersonnelSortHeader).InitFlipSortButton("nameButton", ePersonnelSoldierSortType_Name, m_strButtonLabels[ePersonnelSoldierSortType_Name]);
		Spawn(class'UIFlipSortButton', m_kPersonnelSortHeader).InitFlipSortButton("statusButton", ePersonnelSoldierSortType_Status, m_strButtonLabels[ePersonnelSoldierSortType_Status], " " /*m_strButtonValues[ePersonnelSoldierSortType_Status]*/); //Not sure if we will use this flipsort column. -bsteiner 
	}

	// Create Memorial header
	if( m_arrNeededTabs.Find(eUIPersonnel_Deceased) != INDEX_NONE )
	{
		Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("nameButton", ePersonnelSoldierSortType_Name, m_strButtonLabels[ePersonnelSoldierSortType_Name]);
		Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("killsButton", ePersonnelSoldierSortType_Kills, m_strButtonLabels[ePersonnelSoldierSortType_Kills]);
		Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("missionsButton", ePersonnelSoldierSortType_Missions, m_strButtonLabels[ePersonnelSoldierSortType_Missions]);
		Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("operationButton", ePersonnelSoldierSortType_Operations, m_strButtonLabels[ePersonnelSoldierSortType_Operations]);
		Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("dateButton", ePersonnelSoldierSortType_Time, m_strButtonLabels[ePersonnelSoldierSortType_Time]);
	}
}

simulated function UIButton CreateTabButton(Name ButtonMCName, string text, delegate<OnButtonClickedDelegate> buttonClickedDelegate)
{
	local UIButton kTabButton;

	kTabButton = Spawn(class'UIButton', self);
	kTabButton.InitButton(ButtonMCName, text, buttonClickedDelegate, eUIButtonStyle_SELECTED_SHOWS_HOTLINK);
	kTabButton.SetAlpha(100);
	kTabButton.DisableNavigation();
	
	return kTabButton;
}

simulated function RefreshData()
{
	UpdateData();
	SortData();
	UpdateList();
}

simulated function UpdateData()
{
	local int i;
	local XComGameState_Unit Unit;

	// Destroy old data
	m_arrSoldiers.Length = 0;
	m_arrScientists.Length = 0;
	m_arrEngineers.Length = 0;
	m_arrDeceased.Length = 0;

	//Need to get the latest state here, else you may have old sata in the list upon refreshing at OnReceiveFocus, such as 
	//still showing dismissed soldiers. 
	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();

	for(i = 0; i < HQState.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(HQState.Crew[i].ObjectID));

		if(Unit.IsAlive())
		{
			if (Unit.IsSoldier())
			{
				if (m_arrNeededTabs.Find(eUIPersonnel_Soldiers) != INDEX_NONE)
				{
					m_arrSoldiers.AddItem(Unit.GetReference());
				}
				else if (m_arrNeededTabs.Find(eUIPersonnel_Deceased) != INDEX_NONE)
				{
					m_arrDeceased.AddItem(Unit.GetReference());
				}
			}
			else if ((Unit.IsScientist() && Unit.GetMyTemplateName() != 'HeadScientist') && (m_arrNeededTabs.Find(eUIPersonnel_Scientists) != INDEX_NONE))
			{
				m_arrScientists.AddItem(Unit.GetReference());
			}
			else if((Unit.IsEngineer() && Unit.GetMyTemplateName() != 'HeadEngineer') && (m_arrNeededTabs.Find(eUIPersonnel_Engineers) != INDEX_NONE))
			{
				m_arrEngineers.AddItem(Unit.GetReference());
			}
		}
	}
}

simulated function UpdateList()
{
	local int SelIdx;

	SelIdx = m_kList.SelectedIndex;

	m_kList.ClearItems();
	PopulateListInstantly();

	// Always select first option if using controller (and last selection is invalid)
	// bsg-dforrest (5.16.17): also reset the index if above the list size, this can happen with delete
	if((SelIdx < 0 || SelIdx >= m_kList.itemCount) && m_kList.itemCount > 0 && `ISCONTROLLERACTIVE)
	// bsg-dforrest (5.16.17): end
	{
		SelIdx = 0;
	}	

	m_kList.SetSelectedIndex(SelIdx);
	m_kList.Navigator.SetSelected(m_kList.GetItem(SelIdx));

	Navigator.SetSelected(m_kList);
}

// calling this function will add items instantly
simulated function PopulateListInstantly()
{
	local UIPersonnel_ListItem kItem;
	local StateObjectReference SoldierRef;
	local array<StateObjectReference> CurrentData;

	CurrentData = GetCurrentData();

	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();

	while( m_kList.itemCount < CurrentData.Length )
	{
		if( m_eListType == eUIPersonnel_Soldiers || m_eCurrentTab == eUIPersonnel_Soldiers )
		{
			kItem = Spawn(class'UIPersonnel_SoldierListItem', m_kList.itemContainer);
			SoldierRef = CurrentData[m_kList.itemCount];
			kItem.InitListItem(SoldierRef);

			kItem.SetDisabled(!class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory') && (SoldierRef != HQState.TutorialSoldier));
		}
		else if( m_eListType == eUIPersonnel_Deceased || m_eCurrentTab == eUIPersonnel_Deceased )
		{
			Spawn(class'UIPersonnel_DeceasedListItem', m_kList.itemContainer).InitListItem(CurrentData[m_kList.itemCount]);
		}
		else
		{
			Spawn(class'UIPersonnel_ListItem', m_kList.itemContainer).InitListItem(CurrentData[m_kList.itemCount]);
		}
	}

	MC.FunctionString("SetEmptyLabel", CurrentData.Length == 0 ? m_strEmptyListLabels[m_eCurrentTab] : "");
}

// calling this function will add items sequentially, the next item loads when the previous one is initialized
simulated function PopulateListSequentially( UIPanel Control )
{
	local UIPersonnel_ListItem kItem;
	local array<StateObjectReference> CurrentData;

	CurrentData = GetCurrentData();

	if(m_kList.itemCount < CurrentData.Length)
	{
		if( m_eListType == eUIPersonnel_Soldiers )
		{
			kItem = Spawn(class'UIPersonnel_SoldierListItem', m_kList.itemContainer);
		}
		else if( m_eListType == eUIPersonnel_Deceased )
		{
			kItem = Spawn(class'UIPersonnel_DeceasedListItem', m_kList.itemContainer);
		}
		else
		{
			kItem = Spawn(class'UIPersonnel_ListItem', m_kList.itemContainer);
		}

		kItem.InitListItem(CurrentData[m_kList.itemCount]);
		kItem.AddOnInitDelegate(PopulateListSequentially);
	}
}

function SortData()
{
	switch( m_eSortType )
	{
	case ePersonnelSoldierSortType_Name:	 SortCurrentData(SortByName);      break;
	case ePersonnelSoldierSortType_Location: SortCurrentData(SortByLocation);  break;
	case ePersonnelSoldierSortType_Rank:	 SortCurrentData(SortByRank);      break;
	case ePersonnelSoldierSortType_Class:	 SortCurrentData(SortByClass);     break;
	case ePersonnelSoldierSortType_Status:	 SortCurrentData(SortByStatus);    break;
	case ePersonnelSoldierSortType_Kills:	 SortCurrentData(SortByKills);    break;
	case ePersonnelSoldierSortType_Missions:	 SortCurrentData(SortByMissions);    break;
	case ePersonnelSoldierSortType_Operations:	 SortCurrentData(SortByOperation);    break;
	case ePersonnelSoldierSortType_Time:	 SortCurrentData(SortByTime);    break;
	}

	m_bDirtySortHeaders = false;
	UpdateSortHeaders();
}

//bsg-crobinson (5.15.17): Update sorting colunms
simulated function UpdateSortHeaders()
{
	local int i;
	local array<UIPanel> SortButtons;
	local UIFlipSortButton SortButton;

	// Realize sort buttons
	GetCurrentSortPanel().GetChildrenOfType(class'UIFlipSortButton', SortButtons);
	for(i = 0; i < SortButtons.Length; ++i)
	{
		SortButton = UIFlipSortButton(SortButtons[i]);
		SortButton.RealizeSortOrder();
		SortButton.SetArrow(m_bFlipSort);
		if (SortButton.IsSelected())
		{
			SortButton.OnReceiveFocus();
		}
	}
}
//bsg-crobinson (5.15.17): end

simulated function int SortByName(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local string NameA, NameB, FullA, FullB; 

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	NameA = UnitA.GetName(eNameType_Last);
	NameB = UnitB.GetName(eNameType_Last);

	if( NameA < NameB )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( NameA > NameB )
	{
		return m_bFlipSort ? 1 : -1;
	}
	else // Last names match, so sort by full name.
	{
		FullA = UnitA.GetName(eNameType_Full);
		FullB = UnitB.GetName(eNameType_Full);
		if( FullA < FullB )
		{
			return m_bFlipSort ? -1 : 1;
		}
		else if( FullA > FullB )
		{
			return m_bFlipSort ? 1 : -1;
		}
		else
		{
			return 0;
		}
	}
	return 0;
}

simulated function int SortByKills(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	//Alphabetical sort on the status strings. 
	if( UnitA.GetNumKills() < UnitB.GetNumKills() )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( UnitA.GetNumKills() > UnitB.GetNumKills() )
	{
		return m_bFlipSort ? 1 : -1;
	}
	return 0;
}

simulated function int SortByMissions(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	//Alphabetical sort on the status strings. 
	if( UnitA.GetNumMissions() < UnitB.GetNumMissions() )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( UnitA.GetNumMissions() > UnitB.GetNumMissions() )
	{
		return m_bFlipSort ? 1 : -1;
	}
	return 0;
}

simulated function int SortByOperation(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	//Alphabetical sort on the status strings. 
	if( UnitA.GetKIAOp() < UnitB.GetKIAOp() )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( UnitA.GetKIAOp() > UnitB.GetKIAOp() )
	{
		return m_bFlipSort ? 1 : -1;
	}
	return 0;
}

simulated function int SortByTime(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local int DateDiff;

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	DateDiff = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMinutes(UnitA.GetKIADate(), UnitB.GetKIADate());

	//Alphabetical sort on the status strings. 
	if( DateDiff < 0 )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( DateDiff > 0)
	{
		return m_bFlipSort ? 1 : -1;
	}
	return 0;
}

simulated function int SortByStatus(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local string StatusA, StatusB;

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	StatusA = class'UIUtilities_Strategy'.static.GetPersonnelStatus(UnitA);
	StatusB = class'UIUtilities_Strategy'.static.GetPersonnelStatus(UnitB);

	//Alphabetical sort on the status strings. 
	if (UnitA.bIsShaken && !UnitB.bIsShaken)
	{
		return m_bFlipSort ? -1 : 1;
	}
	if (!UnitA.bIsShaken && UnitB.bIsShaken)
	{
		return m_bFlipSort ? 1 : -1;
	}
	else if (UnitA.GetMentalState() > UnitB.GetMentalState())
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if (UnitA.GetMentalState() < UnitB.GetMentalState())
	{
		return m_bFlipSort ? 1 : -1;
	}
	else if( StatusA < StatusB )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( StatusA > StatusB )
	{
		return m_bFlipSort ? 1 : -1;
	}
	return 0;
}

simulated function int SortByClass(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local X2SoldierClassTemplate SoldierClassA, SoldierClassB;
	local string NameA, NameB;

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	SoldierClassA = UnitA.GetSoldierClassTemplate();
	SoldierClassB = UnitB.GetSoldierClassTemplate();
	
	NameA = SoldierClassA.DisplayName;
	NameB = SoldierClassB.DisplayName;

	if( NameA < NameB )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( NameA > NameB )
	{
		return m_bFlipSort ? 1 : -1;
	}
	return 0;
}

simulated function int SortByRank(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local int RankA, RankB; 

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	RankA = UnitA.GetRank();
	RankB = UnitB.GetRank();

	if( RankA < RankB )
	{
		return m_bFlipSort ? 1 : -1;
	}
	else if( RankA > RankB )
	{
		return m_bFlipSort ? -1 : 1;
	}
	return 0;
}

simulated function int SortByLocation(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local string LocationA, LocationB; 

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	LocationA = class'UIUtilities_Strategy'.static.GetPersonnelLocation(UnitA);
	LocationB = class'UIUtilities_Strategy'.static.GetPersonnelLocation(UnitB);

	if( LocationA < LocationB )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( LocationA > LocationB )
	{
		return m_bFlipSort ? 1 : -1;
	}
	return 0;
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
	RefreshData();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp(); 
}

//------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local int tempCurrentTab;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnAccept();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break; 
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			if(m_arrNeededTabs.Length > 1)
			{
				tempCurrentTab = m_eCurrentTab-1;
				while(m_arrNeededTabs.Find(tempCurrentTab) == INDEX_NONE)
				{
					tempCurrentTab--;
					if(tempCurrentTab < 0)
					{
						tempCurrentTab = eUIPersonnel_All-1;
					}
				}

				SwitchTab(tempCurrentTab);
			}
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			if(m_arrNeededTabs.Length > 1)
			{
				tempCurrentTab = m_eCurrentTab+1;
				while(m_arrNeededTabs.Find(tempCurrentTab) == INDEX_NONE)
				{
					tempCurrentTab++;
					if(tempCurrentTab >= eUIPersonnel_All)
					{
						tempCurrentTab = 0;
					}
				}

				SwitchTab(tempCurrentTab);
			}
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			if (m_eListType == eUIPersonnel_All)
			{
				switch (m_eCurrentTab)
				{
				case eUIPersonnel_Soldiers:
					SwitchTab(eUIPersonnel_Scientists);
					break;

				case eUIPersonnel_Scientists:
					SwitchTab(eUIPersonnel_Engineers);
					break;				
				
				case eUIPersonnel_Engineers:
					SwitchTab(eUIPersonnel_Soldiers);
					break;
				}
			}

			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			if (m_eListType == eUIPersonnel_All)
			{
				switch (m_eCurrentTab)
				{
				case eUIPersonnel_Soldiers:
					SwitchTab(eUIPersonnel_Engineers);
					break;

				case eUIPersonnel_Engineers:
					SwitchTab(eUIPersonnel_Scientists);
					break;				
				
				case eUIPersonnel_Scientists:
					SwitchTab(eUIPersonnel_Soldiers);
					break;
				}
			}

			break;
		
		//bsg-crobinson (5.15.17): move sort functionality to left and right presses
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			m_bFlipSort = !m_bFlipSort;
			RefreshData();
			m_kList.NavigatorSelectionChanged(0); //bsg-crobinson (5.15.17): always move to top of the list on sort change
			break;
		
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:			
			m_bFlipSort = false;
			m_iSortTypeOrderIndex--;
			if(m_iSortTypeOrderIndex < 0)
				m_iSortTypeOrderIndex = m_aSortTypeOrder.Length - 1;
			SetSortType(m_aSortTypeOrder[m_iSortTypeOrderIndex]);
			m_bDirtySortHeaders = true;
			UpdateSortHeaders();
			PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
			m_bFlipSort = false;
			m_iSortTypeOrderIndex++;
			if(m_iSortTypeOrderIndex >= m_aSortTypeOrder.Length)
				m_iSortTypeOrderIndex = 0;
			SetSortType(m_aSortTypeOrder[m_iSortTypeOrderIndex]);
			m_bDirtySortHeaders = true;
			UpdateSortHeaders();
			PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
			break;
		//bsg-crobinson (5.15.17): end
		default:
			bHandled = super.OnUnrealCommand(cmd, arg);
			if (!bHandled)
			{
				bHandled = m_kList.Navigator.OnUnrealCommand(cmd, arg);
			}

			break;
	}


	if (bHandled)
	{
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//------------------------------------------------------

simulated function SwitchTab( int eTab )
{
	if(m_eCurrentTab == eTab)
		return;
	
	if( (m_eCurrentTab >= 0) && m_arrTabButtons[m_eCurrentTab].IsVisible() )
	{
		m_arrTabButtons[m_eCurrentTab].MC.SetBool("isSelected", false);
		m_arrTabButtons[m_eCurrentTab].MC.FunctionVoid("onLoseFocus");
	}

	m_eCurrentTab = eTab;

	switch(m_eCurrentTab)
	{
	case eUIPersonnel_Scientists:
		m_eSortType = ePersonnelSoldierSortType_Name;
		m_kList.OnItemClicked = OnScientistSelected;
		m_kPersonnelSortHeader.Show();
		m_kDeceasedSortHeader.Hide();
		m_kSoldierSortHeader.Hide();
		break;
	case eUIPersonnel_Engineers:
		m_eSortType = ePersonnelSoldierSortType_Name;
		m_kList.OnItemClicked = OnEngineerSelected;
		m_kPersonnelSortHeader.Show();
		m_kDeceasedSortHeader.Hide();
		m_kSoldierSortHeader.Hide();
		break;
	case eUIPersonnel_Soldiers: 
		m_eSortType = ePersonnelSoldierSortType_Rank;
		m_kList.OnItemClicked = OnSoldierSelected;
		m_kPersonnelSortHeader.Hide();
		m_kDeceasedSortHeader.Hide();
		m_kSoldierSortHeader.Show();
		break;
	case eUIPersonnel_Deceased: 
		m_eSortType = ePersonnelSoldierSortType_Name;
		m_kList.OnItemClicked = OnDeceasedSelected;
		m_kPersonnelSortHeader.Hide();
		m_kSoldierSortHeader.Hide();
		m_kDeceasedSortHeader.Show();
		break;
	}
	
	//bsg-crobinson (5.15.17): Change column list depending on which type of personnel we're viewing
	m_aSortTypeOrder.Length = 0;
	if (m_eListType == eUIPersonnel_Soldiers || m_eCurrentTab == eUIPersonnel_Soldiers)
	{		
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Rank);
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Name);
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Class);
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Status);
	}
	else if (m_eListType == eUIPersonnel_Deceased || m_eCurrentTab == eUIPersonnel_Deceased)
	{
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Name);
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Kills);
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Missions);
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Operations);
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Time);
	}
	else
	{
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Name);
		m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Status);
	}
	m_iSortTypeOrderIndex = m_aSortTypeOrder.Find(m_eSortType);
	//bsg-crobinson (5.15.17): end

	RefreshData();
	m_kList.NavigatorSelectionChanged(0); //bsg-crobinson (5.15.17): always move to top of the list on sort change
	
	UpdateNavHelp();

	// Set Move HighlightPosition
	if( m_arrTabButtons[m_eCurrentTab].IsVisible() )
	{
		m_arrTabButtons[m_eCurrentTab].MC.SetBool("isSelected", true);
		m_arrTabButtons[m_eCurrentTab].MC.FunctionVoid("onReceiveFocus");
	}
}

//------------------------------------------------------

simulated function ScientistTab( UIButton kTabButton )
{
	SwitchTab( eUIPersonnel_Scientists );
}
simulated function OnScientistSelected( UIList kList, int index )
{
	`log("OnScientistSelected" @ index);
	if( !UIPersonnel_ListItem(kList.GetItem(index)).IsDisabled )
	{
		if( onSelectedDelegate != none )
			onSelectedDelegate(GetCurrentData()[index]);

		if(m_bRemoveWhenUnitSelected)
			CloseScreen();
	}
}

simulated function EngineersTab( UIButton kTabButton )
{
	SwitchTab( eUIPersonnel_Engineers );
}
simulated function OnEngineerSelected( UIList kList, int index )
{
	`log("OnEngineerSelected" @ index);
	if( !UIPersonnel_ListItem(kList.GetItem(index)).IsDisabled )
	{
		if( onSelectedDelegate != none )
			onSelectedDelegate(GetCurrentData()[index]);

		if(m_bRemoveWhenUnitSelected)
			CloseScreen();
	}
}

simulated function SoldiersTab( UIButton kTabButton )
{
	SwitchTab( eUIPersonnel_Soldiers );
}
simulated function OnSoldierSelected( UIList kList, int index )
{
	local UIPersonnel_ListItem Item;

	`log("OnSoldierSelected" @ index);

	Item =  UIPersonnel_ListItem( kList.GetItem(index) );
	if( (Item != none) && !Item.IsDisabled )
	{
		if( onSelectedDelegate != none )
			onSelectedDelegate(GetCurrentData()[index]);

		if(m_bRemoveWhenUnitSelected)
			CloseScreen();
	}
}

simulated function DeceasedTab( UIButton kTabButton )
{
	SwitchTab( eUIPersonnel_Deceased );
}
simulated function OnDeceasedSelected( UIList kList, int index )
{
	`log("OnDeceasedSelected" @ index);
	if( !UIPersonnel_ListItem(kList.GetItem(index)).IsDisabled )
	{
		if( onSelectedDelegate != none )
			onSelectedDelegate(GetCurrentData()[index]);

		if(m_bRemoveWhenUnitSelected)
			CloseScreen();
	}
}

//------------------------------------------------------

// IUISortableInterface, for access from the flip sort header buttons. 
function bool GetFlipSort()
{
	return m_bFlipSort;
}
function int GetSortType()
{
	return int(m_eSortType);
}
function SetFlipSort(bool bFlip)
{
	m_bFlipSort = bFlip;
}
function SetSortType(int eSortType)
{
	m_eSortType = EPersonnelSortType(eSortType);
}


simulated function UIPanel GetCurrentSortPanel()
{
	switch(m_eCurrentTab)
	{
	case eUIPersonnel_Soldiers: 
		return m_kSoldierSortHeader;
	case eUIPersonnel_Scientists: 
	case eUIPersonnel_Engineers: 
		return m_kPersonnelSortHeader;
	case eUIPersonnel_Deceased:
		return m_kDeceasedSortHeader;
	}
}

simulated function array<StateObjectReference> GetCurrentData()
{
	switch(m_eCurrentTab)
	{
	case eUIPersonnel_Soldiers: 
		return m_arrSoldiers;
	case eUIPersonnel_Scientists: 
		return m_arrScientists;
	case eUIPersonnel_Engineers: 
		return m_arrEngineers;
	case eUIPersonnel_Deceased: 
		return m_arrDeceased;
	}
}

simulated function SortCurrentData(delegate<SortDelegate> SortFunction)
{
	switch(m_eCurrentTab)
	{
	case eUIPersonnel_Soldiers: 
		m_arrSoldiers.Sort(SortFunction);
		break;
	case eUIPersonnel_Scientists: 
		m_arrScientists.Sort(SortFunction);
		break;
	case eUIPersonnel_Engineers: 
		m_arrEngineers.Sort(SortFunction);
		break;
	case eUIPersonnel_Deceased: 
		m_arrDeceased.Sort(SortFunction);
		break;
	}
}

//------------------------------------------------------

simulated function RefreshTitle()
{
	local int i;

	if( m_arrNeededTabs.Length == 1 )
	{
		switch( m_arrNeededTabs[0] )
		{
		case eUIPersonnel_Soldiers:
			SetScreenHeader(m_strSoldierTab);
			break;
		case eUIPersonnel_Scientists:
			SetScreenHeader(m_strScientistTab);
			break;
		case eUIPersonnel_Engineers:
			SetScreenHeader(m_strEngineerTab);
			break;
		case eUIPersonnel_Deceased:
			SetScreenHeader(m_strDeceasedTab);
			break;
		}

		for( i = 0; i < m_arrTabButtons.length; i++ )
			m_arrTabButtons[i].Hide();
	}
}

simulated function SetScreenHeader(string NewTitle)
{
	if( Title != NewTitle )
	{
		Title = NewTitle;

		MC.FunctionString("SetScreenHeader", Title);
	}
}

//------------------------------------------------------

simulated function OnButtonCallback()
{
	switch(m_eCurrentTab)
	{
	case eUIPersonnel_Soldiers:
		OnSoldierSelected(m_kList, m_kList.selectedIndex  < 0 ? 0 : m_kList.selectedIndex);
		break;
	case eUIPersonnel_Scientists:
		OnScientistSelected(m_kList, m_kList.selectedIndex  < 0 ? 0 : m_kList.selectedIndex);
		break;
	case eUIPersonnel_Engineers:
		OnEngineerSelected(m_kList, m_kList.selectedIndex  < 0 ? 0 : m_kList.selectedIndex);
		break;
	case eUIPersonnel_Deceased:
		OnDeceasedSelected(m_kList, m_kList.selectedIndex  < 0 ? 0 : m_kList.selectedIndex);
		break;
	}
}

simulated function OnAccept()
{
	OnButtonCallback();
}

simulated function OnCancel()
{
	if(HQState.IsObjectiveCompleted('T0_M2_WelcomeToArmory'))
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_AvengerNoRoom");
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		CloseScreen();
	}
}

// can be overridden to provide custom behavior for derived classes
simulated function CloseScreen()
{
	Movie.Stack.Pop(self);
}

//==============================================================================

defaultproperties
{
	MCName          = "theScreen";
	Package = "/ package/gfxSoldierList/SoldierList";

	InputState    = eInputState_Evaluate;

	m_eCurrentTab = -1;
	m_eListType = eUIPersonnel_All;
	m_eSortType = ePersonnelSoldierSortType_Name;

	m_iMaskWidth = 961;
	m_iMaskHeight = 780;

	m_bRemoveWhenUnitSelected = false;
	bConsumeMouseEvents = true;
	bAutoSelectFirstNavigable = false;
}
