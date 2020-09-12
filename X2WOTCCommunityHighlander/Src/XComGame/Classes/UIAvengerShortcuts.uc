//---------------------------------------------------------------------------------------
//  FILE:    UIAvengerShortcuts.uc
//  AUTHOR:  Brit Steiner --  12/22/2014
//  PURPOSE:Soldier category options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIAvengerShortcuts extends UIPanel
	config(UI);

enum UIAvengerShortcutCategory
{
	eUIAvengerShortcutCat_Research,
	eUIAvengerShortcutCat_Engineering,
	eUIAvengerShortcutCat_Barracks,
	eUIAvengerShortcutCat_CommandersQuarters,
	eUIAvengerShortcutCat_ShadowChamber
};

enum EUIAvengerShortcutMsgUrgency
{
	eUIAvengerShortcutMsgUrgency_Low,
	eUIAvengerShortcutMsgUrgency_Medium,
	eUIAvengerShortcutMsgUrgency_High,
};

struct UIAvengerShortcutMessage
{
	var string Label;
	var string Description;
	var StateObjectReference HotLinkRef;
	var EUIAvengerShortcutMsgUrgency Urgency;
	var delegate<MsgCallback> OnItemClicked;
	var bool bDisabled;
};

struct UIAvengerShortcutMessageCategory
{
	//var UIIcon Icon; 
	var UIX2MenuButton Button; 
	var array<UIAvengerShortcutMessage> Messages;
	var StateObjectReference HotLinkRef;
	var delegate<MsgCallback> OnItemClicked;
	var bool bAlert; 
};

// Start Issue #163 New Menu Hooks
// A custom sub-menu item. Contains an identifier to allow it to be located 
// and updated in the future.
struct UIAvengerShortcutSubMenuItem
{
    var name Id;
    var UIAvengerShortcutMessage Message;
};

// A list of sub-menu items.
struct AvengerSubMenuList
{
    var array<UIAvengerShortcutSubMenuItem> SubMenuItems;
};

// A sub-menu list for each category in UIAvengerShortcuts.
var array<AvengerSubMenuList> ModSubMenus;

// End Issue #163 New Menu Hooks

var const config float CategoryBufferSpace; // pixel buffer between category buttons. 
var const config float SubmenuYOffset;

//----------------------------------------------------------------------------
// MEMBERS

var localized string CategoryLabels[UIAvengerShortcutCategory.EnumCount]<BoundEnum=UIAvengerShortcutCategory>;

var localized string LabelResearch_NewResearch;
var localized string LabelResearch_ChangeResearch;
var localized string LabelResearch_ShadowProject;
var localized string LabelResearch_AccessArchives;
var localized string LabelResearch_ViewScientists; 

var localized string LabelEngineering_BuildItems;
var localized string LabelEngineering_BuildFacilities;
var localized string LabelEngineering_ViewInventory;
var localized string LabelEngineering_ViewEngineers;
var localized string LabelEngineering_ViewSchematics;
var localized string LabelEngineering_ProvingGround;

var localized string LabelBarracks_ViewSoldiers;
var localized string LabelBarracks_ViewPosters;
var localized string LabelBarracks_OTS;
var localized string LabelBarracks_AdvancedWarfareCenter;
var localized string LabelBarracks_PsiChamber;
var localized string LabelBarracks_Recruit;
var localized string LabelBarracks_Memorial;

var localized string LabelCQ_Objectives;
var localized string LabelCQ_AvengerReport;
var localized string LabelCQ_XCOMDatabase;
var localized string LabelCQ_DailyChallenge;
var localized string LabelCQ_ResistanceOrders;

var localized string LabelShadowChamber_ShadowProject;
var localized string LabelShadowChamber_AccessArchives;
var localized string LabelShadowChamber_ShadowProjectNoneAvailable;

var localized string TooltipResearch;
var localized string TooltipEngineering;
var localized string TooltipBarracks;
var localized string TooltipCommandersQuarters;
var localized string TooltipShadowChamber;
var localized string TooltipGeoscape;

var localized string TooltipResearch_NewResearch;
var localized string TooltipResearch_ChangeResearch;
var localized string TooltipResearch_ShadowProject;
var localized string TooltipResearch_AccessArchives;
var localized string TooltipResearch_ReviewCredits;
var localized string TooltipResearch_ViewScientists;

var localized string TooltipEngineering_BuildItems;
var localized string TooltipEngineering_BuildFacilities;
var localized string TooltipEngineering_ViewInventory;
var localized string TooltipEngineering_ViewEngineers;
var localized string TooltipEngineering_ViewSchematics;
var localized string TooltipEngineering_ProvingGround;

var localized string TooltipBarracks_ViewSoldiers;
var localized string TooltipBarracks_ViewPosters;
var localized string TooltipBarracks_OTS;
var localized string TooltipBarracks_AdvancedWarfareCenter;
var localized string TooltipBarracks_PsiChamber;
var localized string TooltipBarracks_Recruit;
var localized string TooltipBarracks_Memorial;

var localized string TooltipCQ_Objectives;
var localized string TooltipCQ_AvengerReport;
var localized string TooltipCQ_XCOMDatabase;
var localized string TooltipCQ_DailyChallenge;
var localized string TooltipCQ_ResistanceOrders;

var localized string TooltipShadowChamber_ShadowProject;
var localized string TooltipShadowChamber_AccessArchives;
var localized string TooltipShadowChamber_ShadowProjectNoneAvailable;

var UIPanel			ListContainer;
var UIList				List;
var UIScreenListener		ScreenListener;
var UIPanel					CategoryBG; 
var int CachedListItemSelection; 

var UIGamepadIcons LeftBumperIcon;
var UIGamepadIcons RightBumperIcon;
var bool bHasShortcutTabAttention;
var int InRoomCurrentShortcutTabHighlightIndex;		//not the current category, but the current tab we have selected.
var array<UIAvengerShortcutMessageCategory> Categories;
// CurrentCategory now refers to what room we are physically in, as opposed to the shortcut tab that we have selected, -1 means we're not in any room.
var int							 CurrentCategory; 

var int	RequestedNewCategory; // Used while checking for interruption 

var bool ShouldShowWhenRealized;
const BUMPER_CAMERA_SWOOP_DELAY = 0.5f;

delegate MsgCallback(optional StateObjectReference Facility);


//----------------------------------------------------------------------------
// FUNCTIONS


simulated function UIAvengerShortcuts InitShortcuts(optional name InitName)
{
	local int i;
	local UIX2MenuButton Button; 	
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;

	// Start Issue #163 New Menu Hooks
	ModSubMenus.length = eUIAvengerShortcutCat_MAX;
	// End Issue #163 New Menu Hooks

	InitPanel(InitName); 
	SetSize(300, 600);
	AnchorBottomCenter();
	SetPosition(0, -55);

	Navigator.HorizontalNavigation = true;

	// Create ListContainer for list beneath depth of buttons. 
	ListContainer = Spawn(class'UIPanel', self).InitPanel('ListContainer');
	ListContainer.bCascadeFocus = false; 

	// ---------------------------------------------------------

	CategoryBG = Spawn(class'UIPanel', self).InitPanel('AvengerShortcutsBG', 'X2MenuBG');
	CategoryBG.DisableNavigation();
	CategoryBG.SetY(24);

	Categories.length = eUIAvengerShortcutCat_MAX;

	for( i = eUIAvengerShortcutCat_MAX-1; i >= 0; i-- )
	{		
		//TODO: Do we want to convert this in to a horizontal list? 
		Button = Spawn(class'UIX2MenuButton', self);
		Button.InitMenuButton(( i == eUIAvengerShortcutCat_ShadowChamber ), Name("CatButton_" $ i), CategoryLabels[i], OnCategoryMouseEvent);
		
		//After initializing the button
		if( i == eUIAvengerShortcutCat_ShadowChamber )
			Button.SetColor(class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR);
		
		Button.Hide(); // starts off hidden
		Button.OnSizeRealized = OnCategoryButtonSizeRealized;
		Categories[i].Button = Button; 
	}

	//---------------------------------------------------------
	// Initialize category facility links: 

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Categories[eUIAvengerShortcutCat_Research].OnItemClicked = SelectFacilityHotlink; 
	Categories[eUIAvengerShortcutCat_Research].HotLinkRef = XComHQ.GetFacilityByName('PowerCore').GetReference();
	InitializeTooltipResearch();

	Categories[eUIAvengerShortcutCat_Engineering].OnItemClicked = SelectFacilityHotlink;
	Categories[eUIAvengerShortcutCat_Engineering].HotLinkRef = XComHQ.GetFacilityByName('Storage').GetReference();
	InitializeTooltipEngineering();

	Categories[eUIAvengerShortcutCat_Barracks].OnItemClicked = SelectFacilityHotlink;
	Categories[eUIAvengerShortcutCat_Barracks].HotLinkRef = XComHQ.GetFacilityByName('Hangar').GetReference();
	InitializeTooltipBarracks();

	Categories[eUIAvengerShortcutCat_CommandersQuarters].OnItemClicked = SelectFacilityHotlink;
	Categories[eUIAvengerShortcutCat_CommandersQuarters].HotLinkRef = XComHQ.GetFacilityByName('CommandersQuarters').GetReference();
	InitializeTooltipCommandersQuarters();

	Facility = XComHQ.GetFacilityByName('ShadowChamber');
	if (Facility != none)
	{
		Categories[eUIAvengerShortcutCat_ShadowChamber].OnItemClicked = SelectFacilityHotlink;
		Categories[eUIAvengerShortcutCat_ShadowChamber].HotLinkRef = Facility.GetReference();
		InitializeTooltipShadowChamber();
	}

	// ---------------------------------------------------------

	ListContainer.SetY(Button.Height - 5);
	ListContainer.SetSize(600, 500);

	List = Spawn(class'UIList', ListContainer);
	List.bIsNavigable = true;
	List.BGPaddingBottom = 100;
	List.InitList('', 0, 5, width - 20, height - 10, , true);
	List.BG.SetAlpha(80);
	List.OnItemClicked = OnListItemCallback;
	List.OnItemDoubleClicked = OnListItemCallback;
	List.bStickyHighlight = false;
	//List.BG.ProcessMouseEvents(OnBGMouseEvent);
	HideList();

	// ---------------------------------------------------------
	
	UpdateCategories();
	
	// ---------------------------------------------------------

	if( !Movie.IsMouseActive() )
		SpawnNavHelpIcons();
	return self;
}
simulated function SpawnNavHelpIcons()
{
	local float IconSizeRatio;
	local float newHeight;
	local float newWidth;

	//original icon ratio that was used before.
	IconSizeRatio = 71.5 / 44;
	newHeight = 35;
	newWidth = newHeight * IconSizeRatio;

	LeftBumperIcon = Spawn(class'UIGamepadIcons',Self);
	LeftBumperIcon.InitGamepadIcon('NavBtn_Left', class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LB_L1);
	LeftBumperIcon.SetSize(newWidth, newHeight);//71.5, 44);
	LeftBumperIcon.SetY(8);

	RightBumperIcon = Spawn(class'UIGamepadIcons',Self);
	RightBumperIcon.InitGamepadIcon('NavBtn_Right', class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RB_R1);
	RightBumperIcon.SetSize(newWidth, newHeight);//71.5, 44);
	RightBumperIcon.SetY(8);
}

simulated function UpdateCategories()
{
	local int i, j; // Issue #163 New Menu Hooks
	local UIAvengerShortcutMessageCategory CurrentCat;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Categories[eUIAvengerShortcutCat_Research].Messages = GetResearchMessages();
	Categories[eUIAvengerShortcutCat_Engineering].Messages = GetEngineeringMessages();
	Categories[eUIAvengerShortcutCat_Barracks].Messages = GetBarracksMessages();
	Categories[eUIAvengerShortcutCat_CommandersQuarters].Messages = GetCommandersQuartersMessages();

	if( HasShadowChamber() )
	{
		Categories[eUIAvengerShortcutCat_ShadowChamber].Messages = GetShadowChamberMessages();

		// TTP 16875 - the ShadowChamber isn't a valid facility when we Init this screen at the start of the game so refresh it if needed
		if (Categories[eUIAvengerShortcutCat_ShadowChamber].HotLinkRef.ObjectID == 0)
		{
			Categories[eUIAvengerShortcutCat_ShadowChamber].HotLinkRef = XComHQ.GetFacilityByName('ShadowChamber').GetReference();
		}

		if( Categories[eUIAvengerShortcutCat_ShadowChamber].OnItemClicked == none )
		{
			FacilityState = XComHQ.GetFacilityByName('ShadowChamber');
			if( FacilityState != none )
			{
				Categories[eUIAvengerShortcutCat_ShadowChamber].OnItemClicked = SelectFacilityHotlink;
				Categories[eUIAvengerShortcutCat_ShadowChamber].HotLinkRef = FacilityState.GetReference();
				InitializeTooltipShadowChamber();
			}
		}
	}

	for( i = 0; i < eUIAvengerShortcutCat_MAX; i++ )
	{
		RefreshCategoryAlert(i); // Do this before text is refreshed. 
		CurrentCat = Categories[i];
		if( ShouldShowCurrentCategory(i) )
		{
			FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(CurrentCat.HotLinkRef.ObjectID));
			CurrentCat.Button.SetDisabled(FacilityState.bTutorialLocked);

			CurrentCat.Button.Show();
			CurrentCat.Button.SetText(CategoryLabels[i]);
			CurrentCat.Button.NeedsAttention(CurrentCat.bAlert && !CurrentCat.Button.IsDisabled);
		}
		else
		{
			Categories[i].Button.Hide();
		}
		// Start Issue #163 New Menu Hooks
		for (j = 0; j < ModSubMenus[i].SubMenuItems.Length; ++j)
		{
			Categories[i].Messages.InsertItem(0, ModSubMenus[i].SubMenuItems[j].Message);
		}
		// End Issue #163 New Menu Hooks
	}
	OnCategoryButtonSizeRealized();
}

function RefreshCategoryAlert(int iCat)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameStateHistory History;
	
	// Default alert off:
	Categories[iCat].bAlert = false;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Categories[iCat].HotLinkRef.ObjectID));

	// Check if the category facility needs attention
	if(FacilityState != none && FacilityState.NeedsAttention())
	{
		Categories[iCat].bAlert = true;
	}
}

simulated function bool ShouldShowCurrentCategory(int iCat)
{
	if (iCat == eUIAvengerShortcutCat_ShadowChamber)
		return HasShadowChamber();

	return true;
}

simulated function OnCategoryButtonSizeRealized()
{
	local int i, CurrentCatX;

	CurrentCatX = CategoryBufferSpace; //Start spaced over slightly, to give BG edge breathing room. 
	for( i = 0; i < eUIAvengerShortcutCat_MAX; i++ )
	{
		if( ShouldShowCurrentCategory(i) )
		{
			//Buttons stick together to the bottom left, so no blank spaces between icons. 
			Categories[i].Button.SetX(CurrentCatX);
			CurrentCatX += Categories[i].Button.Width + CategoryBufferSpace;
		}
		else
		{
			//Button should be hidden, so do nothing. 
		}
	}

	CategoryBG.SetWidth(CurrentCatX);

	// Center to the category list along the bottom of the screen.
	SetX(CurrentCatX * -0.5); 
	// Issue #163: Don't adjust the bumpers unless we're using a controller
	if (`ISCONTROLLERACTIVE)
	{
		if (LeftBumperIcon != none) LeftBumperIcon.SetX(-38.0 - LeftBumperIcon.Width / 2.0 - class'UIGamepadIcons'.const.X_OFFSET);
		if (RightBumperIcon != none) RightBumperIcon.SetX(CurrentCatX + 38.0 - RightBumperIcon.Width / 2.0 - class'UIGamepadIcons'.const.X_OFFSET);
	}
	// Issue #163: Need a category to display the list
	if (CurrentCategory >= 0) RealizeListPosition();

	if( ShouldShowWhenRealized )
		super.Show();
}

simulated function Show()
{
	`HQPRES.ShowAvengerShortcutList(-1, true, true);
}

simulated function DoShow()
{
	ShouldShowWhenRealized = true;
	UpdateCategories();
}

simulated function Hide()
{
	`HQPRES.ShowAvengerShortcutList(-1, false, true);

	HideList();
}
simulated function DoHide()
{
	super.Hide();
	ShouldShowWhenRealized = false;
}

simulated function ShowList( optional int eCat = -1 )
{
	`HQPRES.ShowAvengerShortcutList(eCat, true, false);
}

simulated function DoShowList( int eCat )
{
	local int i; 
	local string TooltipText;
	local UIListItemString ListItem; 
	local UIPanel Padding;
	
	CachedListItemSelection = List.SelectedIndex; 

	List.ClearItems();

	if( eCat == -1 )
	{
		// The requested category may be -1 for a facility not in the link bar. This is a valid request, 
		// and there maybe no previous selection, so return here and don't show the list. 
		if( CurrentCategory == -1 )
			return; 
		else
			eCat = CurrentCategory;
	}
	
	// Update the category header to selected to match the open list 
	for( i = 0; i < Categories.length; i++ )
	{
		if( i == eCat )
		{
			if (!Categories[eCat].Button.IsDisabled)
			{
				Categories[i].Button.AnimateShine(true);
			}
			Navigator.SetSelected(Categories[i].Button);
		}
		else
		{
			Categories[i].Button.AnimateShine(false);
			Categories[i].Button.OnLoseFocus();
		}
	}

	if (Categories[eCat].Button.IsDisabled)
	{
		return;
	}
	for( i = 0; i < Categories[eCat].Messages.length; i++ )
	{
		ListItem = Spawn(class'UIListItemString', List.itemContainer).InitListItem(Categories[eCat].Messages[i].Label).SetDisabled(Categories[eCat].Messages[i].bDisabled);

		switch( Categories[eCat].Messages[i].Urgency )
		{
		case eUIAvengerShortcutMsgUrgency_Low: 		
			break;
		case eUIAvengerShortcutMsgUrgency_Medium: 
			ListItem.SetWarning(true);
			break;
		case eUIAvengerShortcutMsgUrgency_High: 
			ListItem.SetBad(true);
			break;
		}

		TooltipText = Categories[eCat].Messages[i].Description;
		if( TooltipText != "" )
			ListItem.SetTooltipText(TooltipText, , , , false);
	}

	// add padding at the bottom of the list.
	Padding = List.CreateItem(class'UIPanel');
	Padding.bIsNavigable = false;
	Padding.InitPanel();
	Padding.SetHeight(SubmenuYOffset);
	Padding.DisableNavigation();
	RealizeListPosition();
	
	if( Categories[eCat].Messages.length > 0 )
	{
		List.Show();
		ListContainer.SetSelectedNavigation();
		List.SetSelectedNavigation();
		if( CachedListItemSelection > -1 && CachedListItemSelection < List.GetItemCount() )
			List.SetSelectedIndex(CachedListItemSelection);
		else
			List.SetSelectedIndex(List.GetItemCount() - 2);
	}
	else
	{
		List.Hide();
		CachedListItemSelection = INDEX_NONE; 
	}
	//List.SetSelectedIndex(List.GetItemCount() - 2);
	Movie.Pres.StopDistort();
}
function RealizeListPosition()
{
	local float TargetListX, TargetListY, ListWidth; 

	// The requested category may be -1 for a facility not in the link bar. This is a valid request, 
	// and there maybe no previous selection, so return here and don't show the list. 
	if (CurrentCategory == -1)
		return;

	TargetListX = Categories[CurrentCategory].Button.X;
	TargetListY = -List.ShrinkToFit();

	ListWidth = List.Width; 

	//Don't let the list wander beyond the right edge of the categories. 
	if( TargetListX + ListWidth > CategoryBG.X + CategoryBG.Width )
		TargetListX = CategoryBG.X + CategoryBG.Width - ListWidth; 

	List.SetPosition(TargetListX, TargetListY);
}

simulated function HideList()
{
	`HQPRES.ShowAvengerShortcutList(-1, false, false);
}

simulated function DoHideList()
{
	local int i;
	for( i = 0; i < Categories.length; i++ )
	{
		Categories[i].Button.AnimateShine(false);
		if (CurrentCategory != i)
		{
			Categories[i].Button.OnLoseFocus();
		}
	}

	Movie.Pres.m_kTooltipMgr.HideTooltipsByPartialPath(string(MCPath));
	List.Hide();
	//CurrentCategory = -1;
}

simulated function SelectCategoryForFacilityScreen(UIFacility FacilityScreen, optional bool bForce)
{
	local int Index; 
	Index = Categories.Find('HotLinkRef', FacilityScreen.FacilityRef);
	if( Index != CurrentCategory || bForce )
	{
		CurrentCategory = Index;
		//Reset the selection if we change categories. 
		List.SetSelectedIndex(List.GetItemCount() - 2);
		ShowList(CurrentCategory);
	}

	InRoomCurrentShortcutTabHighlightIndex = CurrentCategory;
}

//------------------------------------------------------
// We care when you mouse IN to a category, and change the category.
simulated function OnCategoryMouseEvent(UIButton Button)
{
	local int iNewCat; 
	iNewCat = int(GetRightMost(Button.MCName));
	SelectCategory(iNewCat);
}

simulated function OnListItemCallback(UIList ContainerList, int ItemIndex)
{
	local UIAvengerShortcutMessage Msg; 
	local delegate<MsgCallback> MsgCallback; 
	
	Msg = Categories[CurrentCategory].Messages[ItemIndex]; 
	MsgCallback = Msg.OnItemClicked;

	if( MsgCallback != none && !Msg.bDisabled)
	{
		//`HQPRES.ClearToFacilityMainMenu();
		MsgCallback(Msg.HotLinkRef);
	}
}

simulated function SelectCategoryButtonOnly(int iNewCat)
{
	if( Categories[iNewCat].Button.IsDisabled )
	{
		if(InRoomCurrentShortcutTabHighlightIndex >= 0)
		{
			Categories[InRoomCurrentShortcutTabHighlightIndex].Button.AnimateShine(false);
			Categories[InRoomCurrentShortcutTabHighlightIndex].Button.OnLoseFocus();
			HighlightShortcutButton(InRoomCurrentShortcutTabHighlightIndex, false);
			Categories[InRoomCurrentShortcutTabHighlightIndex].Button.AnimateShine(false);
		}
		InRoomCurrentShortcutTabHighlightIndex = iNewCat;
		HighlightShortcutButton(InRoomCurrentShortcutTabHighlightIndex, true);
		Categories[InRoomCurrentShortcutTabHighlightIndex].Button.AnimateShine(false);
	}
	else
	{
		InRoomCurrentShortcutTabHighlightIndex = iNewCat;
		if(InRoomCurrentShortcutTabHighlightIndex != CurrentCategory)
		{
			Categories[CurrentCategory].Button.OnLoseFocus();
			Categories[CurrentCategory].Button.AnimateShine(false);
			HideList();
			//We might be able to get away with disabling navigation from the very beginning since we handle it OnUnrealCommand()
			List.DisableNavigation();
		}
		else
		{
			ShowList(CurrentCategory);
		}
		HighlightShortcutButton(InRoomCurrentShortcutTabHighlightIndex, true);
		Navigator.SetSelected(Categories[InRoomCurrentShortcutTabHighlightIndex].Button);
	}
}
simulated function SelectCategory(int iNewCat)
{
	`log("SelectCategory "$iNewCat,,'DebugHQCamera');

	if( iNewCat != CurrentCategory )
	{
		//Reset the selection if we change categories. 
		List.SetSelectedIndex(-1, true);
	}

	`HQPRES.SelectAvengerShortcut(iNewCat, CurrentCategory);
	// do not process the input if the button should be disabled
	if( Categories[iNewCat].Button.IsDisabled )
	{
		Categories[CurrentCategory].Button.AnimateShine(false);
		Categories[CurrentCategory].Button.OnLoseFocus();
		CurrentCategory = iNewCat;
		Navigator.SetSelected(Categories[iNewCat].Button);
		return;
	}

	if(!`HQPRES.ScreenStack.HasInstanceOf(class'UIAlert'))
	{
		CheckForInterrupt(iNewCat);
	}
}
//------------------------------------------------------

simulated function bool HasShadowChamber()
{
	local XComGameState_HeadquartersXCom XComHQ;
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	return (XComHQ.GetFacilityByName('ShadowChamber') != none);
}


//----------------------------------------------------------------------------
// GATHER MESSAGE FUNCTIONS

reliable client function array<UIAvengerShortcutMessage> GetResearchMessages()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState, PowerCoreFacilityState;
	local array<UIAvengerShortcutMessage> Messages;
	local UIAvengerShortcutMessage Msg;
	local string AlertIcon;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Messages.Length = 0;

	if(XComHQ.GetObjectiveStatus('T0_M1_WelcomeToLabs') != eObjectiveState_InProgress)
	{
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if(FacilityState.GetMyTemplateName() == 'PowerCore')
			{
				PowerCoreFacilityState = FacilityState;
				break;
			}
		}

		// Access scientist list ----------------------------------------------------------
		if(PowerCoreFacilityState != none)
		{
			Msg.Label = LabelResearch_ViewScientists;
			Msg.Description = TooltipResearch_ViewScientists;
			Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			Msg.HotLinkRef = PowerCoreFacilityState.GetReference();
			Msg.OnItemClicked = ViewScientistsHotlink;
			Messages.AddItem(Msg);
		}


		// Access the research archives -----------------------------------------------------------
		if(class'UIUtilities_Strategy'.static.GetXComHQ().HasCompletedResearchTechs())
		{
			Msg.Label = LabelResearch_AccessArchives;
			Msg.Description = TooltipResearch_AccessArchives;
			Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			Msg.HotLinkRef = PowerCoreFacilityState.GetReference();
			Msg.OnItemClicked = SelectResearchArchivesHotlink;
			Messages.AddItem(Msg);
		}

		// Power core for research. -------------------------------------------------
		if(PowerCoreFacilityState != none)
		{
			if(XComHQ.HasResearchProject())
			{
				Msg.Label = LabelResearch_ChangeResearch;
				Msg.Description = TooltipResearch_ChangeResearch;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			}
			else
			{
				if (XComHQ.HasTechsAvailableForResearch())
				{
					AlertIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 20, 20, 0) $" ";
				}
				Msg.Label = AlertIcon $ LabelResearch_NewResearch;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.Description = TooltipResearch_NewResearch;
			}

			Msg.HotLinkRef = PowerCoreFacilityState.GetReference();
			Msg.OnItemClicked = SelectChooseResearch;
			Messages.AddItem(Msg);
		}
	}
	else
	{
		// Failsafe for if you somehow back out of the choose research screen during the tutorial
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if(FacilityState.GetMyTemplateName() == 'PowerCore')
			{
				PowerCoreFacilityState = FacilityState;
				break;
			}
		}

		if(PowerCoreFacilityState != none)
		{
			if(!XComHQ.HasResearchProject() && XComHQ.HasTechsAvailableForResearch())
			{
				AlertIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 20, 20, 0) $" ";
				Msg.Label = AlertIcon $ LabelResearch_NewResearch;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.Description = TooltipResearch_NewResearch;
				Msg.HotLinkRef = PowerCoreFacilityState.GetReference();
				Msg.OnItemClicked = SelectChooseResearch;
				Messages.AddItem(Msg);
			}
		}
	}
	
	return Messages;
}

reliable client function array<UIAvengerShortcutMessage> GetEngineeringMessages()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState, StorageFacilityState, ProvingGroundFacilityState;
	local array<UIAvengerShortcutMessage> Messages;
	local UIAvengerShortcutMessage Msg, EmptyMsg;
	local bool bWelcomeToEng;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if(FacilityState.GetMyTemplateName() == 'Storage')
		{
			StorageFacilityState = FacilityState; 
			break;
		}
	}

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if (FacilityState.GetMyTemplateName() == 'ProvingGround' && !FacilityState.IsUnderConstruction())
		{
			ProvingGroundFacilityState = FacilityState;
			break;
		}
	}

	Messages.Length = 0;
	bWelcomeToEng = !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M5_WelcomeToEngineering');

	if(!bWelcomeToEng)
	{
		// Access engineer list ----------------------------------------------------------
		if(StorageFacilityState != none)
		{
			Msg = EmptyMsg;
			Msg.Label = LabelEngineering_ViewEngineers;
			Msg.Description = TooltipEngineering_ViewEngineers;
			Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			Msg.HotLinkRef = StorageFacilityState.GetReference();
			Msg.OnItemClicked = ViewEngineersHotlink;
			//Msg.bDisabled = bWelcomeToEng;
			Messages.AddItem(Msg);
		}

		// List items in inventory storage. ---------------------------------
		if(StorageFacilityState != none)
		{
			Msg = EmptyMsg;
			Msg.Label = LabelEngineering_ViewInventory;
			Msg.Description = TooltipEngineering_ViewInventory;
			Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			Msg.HotLinkRef = StorageFacilityState.GetReference();
			Msg.OnItemClicked = SelectInventoryHotlink;
			//Msg.bDisabled = bWelcomeToEng;
			Messages.AddItem(Msg);
		}

		// Show build facilities mode ---------------------------------
		if(StorageFacilityState != none)
		{
			Msg = EmptyMsg;
			Msg.Label = LabelEngineering_BuildFacilities;
			Msg.Description = TooltipEngineering_BuildFacilities;
			Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			Msg.HotLinkRef = StorageFacilityState.GetReference();
			Msg.OnItemClicked = SelectBuildFacilitiesHotlink;
			//Msg.bDisabled = bWelcomeToEng;
			Messages.AddItem(Msg);
		}

		// List storage facility to build items. ---------------------------------
		if(StorageFacilityState != none)
		{
			Msg = EmptyMsg;
			Msg.Label = LabelEngineering_BuildItems;
			Msg.Description = TooltipEngineering_BuildItems;
			Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			Msg.HotLinkRef = StorageFacilityState.GetReference();
			Msg.OnItemClicked = SelectBuildItemHotlink;
			Messages.AddItem(Msg);
		}

		// Go to the Proving Ground ---------------------------------
		if(ProvingGroundFacilityState != none)
		{
			Msg = EmptyMsg;
			Msg.Label = LabelEngineering_ProvingGround;
			Msg.Description = TooltipEngineering_ProvingGround;
			Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			Msg.HotLinkRef = ProvingGroundFacilityState.GetReference();
			Msg.OnItemClicked = SelectFacilityHotlink;
			Messages.AddItem(Msg);

			// List storage facility to view schematic archive. -------------------------
			if(class'UIUtilities_Strategy'.static.GetXComHQ().HasCompletedProvingGroundProjects())
			{
				Msg = EmptyMsg;
				Msg.Label = LabelEngineering_ViewSchematics;
				Msg.Description = TooltipEngineering_ViewSchematics;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.HotLinkRef = StorageFacilityState.GetReference();
				Msg.OnItemClicked = SelectSchematicArchiveHotlink;
				Messages.AddItem(Msg);
			}
		}
	}
	

	return Messages;
}

reliable client function array<UIAvengerShortcutMessage> GetBarracksMessages()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState, ArmoryState;
	local XComGameState_CampaignSettings SettingsState;
	local array<UIAvengerShortcutMessage> Messages;
	local UIAvengerShortcutMessage Msg;
	local string AlertIcon; 

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if( FacilityState.GetMyTemplateName() == 'Hangar' )
		{
			ArmoryState = FacilityState; 
			break;
		}
	}

	if (ArmoryState != none)
	{
		SettingsState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

		if (`XENGINE.m_kPhotoManager.GetNumOfPosterForCampaign(SettingsState.GameIndex, true) > 0)
		{
			if (`XENGINE.m_kPhotoManager.HasNewPhotos())
				AlertIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 20, 20, 0) $" ";

			Msg.Label = AlertIcon $ LabelBarracks_ViewPosters;
			Msg.Description = TooltipBarracks_ViewPosters;
			Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
			Msg.HotLinkRef = ArmoryState.GetReference();
			Msg.OnItemClicked = ViewPostersHotlink;
			Messages.AddItem(Msg);

			AlertIcon = "";
		}
	}

	// Access bar/memorial --------------------------------------------------------------
	if( XComHQ.HasFacilityByName('BarMemorial') )
	{
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if( FacilityState.GetMyTemplateName() == 'BarMemorial' )
			{
				Msg.Label = LabelBarracks_Memorial;
				Msg.Description = TooltipBarracks_Memorial;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.HotLinkRef = FacilityState.GetReference();
				Msg.OnItemClicked = SelectFacilityHotlink;
				Messages.AddItem(Msg);
				break;
			}
		}
	}

	// New recruits ----------------------------------------------------------------
	if( ArmoryState != none )
	{
		Msg.Label = LabelBarracks_Recruit;
		Msg.Description = TooltipBarracks_Recruit;
		Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
		Msg.HotLinkRef = ArmoryState.GetReference();
		Msg.OnItemClicked = SelectRecruitsHotlink;
		Messages.AddItem(Msg);
	}

	// Access psi chamber --------------------------------------------------------------
	if (XComHQ.HasFacilityByName('PsiChamber'))
	{
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if (FacilityState.GetMyTemplateName() == 'PsiChamber' && !FacilityState.IsUnderConstruction())
			{
				Msg.Label = LabelBarracks_PsiChamber;
				Msg.Description = TooltipBarracks_PsiChamber;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.HotLinkRef = FacilityState.GetReference();
				Msg.OnItemClicked = SelectFacilityHotlink;
				Messages.AddItem(Msg);
				break;
			}
		}
	}
	
	// Access Advanced Warfare Center --------------------------------------------------------------
	if( XComHQ.HasFacilityByName('AdvancedWarfareCenter') )
	{
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if (FacilityState.GetMyTemplateName() == 'AdvancedWarfareCenter' && !FacilityState.IsUnderConstruction())
			{
				Msg.Label = LabelBarracks_AdvancedWarfareCenter;
				Msg.Description = TooltipBarracks_AdvancedWarfareCenter;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.HotLinkRef = FacilityState.GetReference();
				Msg.OnItemClicked = SelectFacilityHotlink;
				Messages.AddItem(Msg);
			}
		}
	}

	// Access the OTS --------------------------------------------------------------
	if( XComHQ.HasFacilityByName('OfficerTrainingSchool') )
	{
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if (FacilityState.GetMyTemplateName() == 'OfficerTrainingSchool' && !FacilityState.IsUnderConstruction())
			{
				Msg.Label = LabelBarracks_OTS;
				Msg.Description = TooltipBarracks_OTS;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.HotLinkRef = FacilityState.GetReference();
				Msg.OnItemClicked = SelectFacilityHotlink;
				Messages.AddItem(Msg);
				break;
			}
		}
	}

	// Access soldier list ----------------------------------------------------------
	if( ArmoryState != none )
	{
		if(XComHQ.HasSoldiersToPromote())
			AlertIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 20, 20, 0) $" ";

		Msg.Label = AlertIcon $ LabelBarracks_ViewSoldiers;
		Msg.Description = TooltipBarracks_ViewSoldiers;
		Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
		Msg.HotLinkRef = ArmoryState.GetReference();
		Msg.OnItemClicked = ViewSoldiersHotlink;
		Messages.AddItem(Msg);
	}

	return Messages;
}

reliable client function array<UIAvengerShortcutMessage> GetCommandersQuartersMessages()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local array<UIAvengerShortcutMessage> Messages;
	local UIAvengerShortcutMessage Msg;
	local bool bTutorial;

	History = `XCOMHISTORY;
	bTutorial = (!class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M0_TutorialFirstMission'));

	if(!bTutorial)
	{
		// Access Daily Challenge ----------------------------------------------------
		/*Msg.Label = LabelCQ_DailyChallenge;
		Msg.Description = TooltipCQ_DailyChallenge;
		Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
		//Msg.HotLinkRef = FacilityState.GetReference(); //TODO 
		Msg.OnItemClicked = none; // TODO
		Messages.AddItem(Msg);*/
	}

	// Access XCOM Database ------------------------------------------------------
	Msg.Label = LabelCQ_XCOMDatabase;
	Msg.Description = TooltipCQ_XCOMDatabase;
	Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
	//Msg.HotLinkRef = FacilityState.GetReference(); //TODO 
	Msg.OnItemClicked = GoToXComDatabase;
	Messages.AddItem(Msg);

	if(!bTutorial)
	{
		// Access facility list --------------------------------------------------------
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if(FacilityState.GetMyTemplateName() == 'CommandersQuarters')
			{
				Msg.Label = LabelCQ_AvengerReport;
				Msg.Description = TooltipCQ_AvengerReport;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.HotLinkRef = FacilityState.GetReference();
				Msg.OnItemClicked = SelectFacilitySummaryHotlink;
				Messages.AddItem(Msg);
				break;
			}
		}

		// Access geoscape objectives ----------------------------------------------------
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if(FacilityState.GetMyTemplateName() == 'CommandersQuarters')
			{
				Msg.Label = LabelCQ_Objectives;
				Msg.Description = TooltipCQ_Objectives;
				Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
				Msg.HotLinkRef = FacilityState.GetReference();
				Msg.OnItemClicked = ViewObjectivesHotlink;
				Messages.AddItem(Msg);
				break;
			}
		}
	}

	// Issue #368
	if (ShouldShowResistanceOrders())
	{
		Msg.Label = LabelCQ_ResistanceOrders;
		Msg.Description = TooltipCQ_ResistanceOrders;
		Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
		Msg.HotLinkRef = FacilityState.GetReference();
		Msg.OnItemClicked = ViewResistanceOrders;
		Messages.AddItem(Msg);
	}

	return Messages;
}

// Start issue #368
/// HL-Docs: feature:UIAvengerShortcuts_ShowCQResistanceOrders; issue:368; tags:strategy,ui
/// Allows overriding whether the resistance orders button should be shown in `UIAvengerShortcuts`.
/// Default: After the first month if any faction met.
///
/// ```event
/// EventID: UIAvengerShortcuts_ShowCQResistanceOrders,
/// EventData: [inout bool ShouldShow],
/// EventSource: UIAvengerShortcuts (ShortcutsScreen),
/// NewGameState: none
/// ```
 simulated protected function bool ShouldShowResistanceOrders()
 {
	local XComGameState_HeadquartersResistance ResHQ;
	local XComLWTuple Tuple;
 
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
 	
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'UIAvengerShortcuts_ShowCQResistanceOrders';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = ResHQ.NumMonths > 0 && ResHQ.HaveMetAnyFactions();

	`XEVENTMGR.TriggerEvent('UIAvengerShortcuts_ShowCQResistanceOrders', Tuple, self, none);
 
 	return Tuple.Data[0].b;
 }
 // End issue #368


reliable client function array<UIAvengerShortcutMessage> GetShadowChamberMessages()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState, ShadowChamberState;
	local array<UIAvengerShortcutMessage> Messages;
	local UIAvengerShortcutMessage Msg;
	local array<StateObjectReference> ShadowProjectsAvailable;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if (FacilityState.GetMyTemplateName() == 'ShadowChamber' && !FacilityState.IsUnderConstruction())
		{
			ShadowChamberState = FacilityState;
			break;
		}
	}

	//Safety check! 
	if( ShadowChamberState == none )
		return Messages;

	ShadowProjectsAvailable = class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableTechsForResearch(true);
	
	// Access the shadow chambers -----------------------------------------------------------
	if( ShadowProjectsAvailable.Length == 0 )
	{
		Msg.Label = LabelShadowChamber_ShadowProjectNoneAvailable;
		Msg.Description = TooltipShadowChamber_ShadowProjectNoneAvailable;
	}
	else
	{
		Msg.Label = LabelShadowChamber_ShadowProject;
		Msg.Description = TooltipShadowChamber_ShadowProject;
	}
	Msg.Urgency = eUIAvengerShortcutMsgUrgency_Medium;
	Msg.HotLinkRef = ShadowChamberState.GetReference();
	Msg.OnItemClicked = SelectShadowChamberProjectHotlink;
	Messages.AddItem(Msg);

	// Access the shadow archives -----------------------------------------------------------
	if( class'UIUtilities_Strategy'.static.GetXComHQ().HasCompletedShadowProjects() )
	{
		Msg.Label = LabelShadowChamber_AccessArchives;
		Msg.Description = TooltipShadowChamber_AccessArchives;
		Msg.Urgency = eUIAvengerShortcutMsgUrgency_Low;
		Msg.HotLinkRef = ShadowChamberState.GetReference();
		Msg.OnItemClicked = SelectShadowChamberArchivesHotlink;
		Messages.AddItem(Msg);
	}


	return Messages;
}


//----------------------------------------------------------------------------
// HOTLINK FUNCTIONS


function SelectFacilityHotlink(StateObjectReference FacilityRef)
{
	local UIFacility CurrentScreen;
	local XComGameState_FacilityXCom FacilityState;
	CurrentScreen = UIFacility(Movie.Stack.GetCurrentScreen());
	if( CurrentScreen == none || CurrentScreen.FacilityRef != FacilityRef )
	{		
		`log("SelectFacilityHotlink",,'DebugHQCamera');
		`log("  MCPath="$MCPath,,'DebugHQCamera');
		`HQPRES.SetFacilityTransition(FacilityRef, false);

		`log("  SelectFacilityHotlink1",,'DebugHQCamera');
		`HQPRES.ClearUIToHUD(false);
		`log("  SelectFacilityHotlink2",,'DebugHQCamera');
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
		`log("  SelectFacilityHotlink3",,'DebugHQCamera');
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityRef);
	}
}

function SelectResearchArchivesHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);

	// get to research archives, once we're on a labs screen. 
	if( UIFacility_Powercore(Movie.Stack.GetCurrentScreen()) != none )
	{
		`HQPRES.UIResearchArchives();
	}
}

function SelectShadowChamberArchivesHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);

	// get to archives, once we're on the shadow chamber screen. 
	if( UIFacility_ShadowChamber(Movie.Stack.GetCurrentScreen()) != none )
	{
		`HQPRES.UIShadowChamberArchives();
	}
}


function SelectShadowChamberProjectHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);

	// get to archives, once we're on the shadow chamber screen. 
	if( UIFacility_ShadowChamber(Movie.Stack.GetCurrentScreen()) != none )
	{
		`HQPRES.UIChooseShadowProject();
	}
}

function ViewScientistsHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);

	// get to personnel view, once we're on a labs screen. 
	if( UIFacility_Powercore(Movie.Stack.GetCurrentScreen()) != none )
	{
		`HQPRES.UIPersonnel(eUIPersonnel_Scientists);
	}
}

function SelectChooseResearch(StateObjectReference FacilityRef)
{
	if( !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M1_WelcomeToLabs') )
	{
		if( !class'XComGameState_HeadquartersXCom'.static.IsWelcomeToLabsInProgressTutorial() )
			return;
	}

	//If Welcome to Labs is in progress, we'll let you come back in to Choose Research, rather than get stuck outside on the main menu.  
	SelectFacilityHotlink(FacilityRef);

	// get to personnel view, once we're on a labs screen. 
	if( UIFacility_Powercore(Movie.Stack.GetCurrentScreen()) != none )
	{
		`HQPRES.UIChooseResearch();
	}
}

function SelectBuildItemHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);

	// get to build item, once we're on the storage screen: 
	if( UIFacility_Storage(Movie.Stack.GetCurrentScreen()) != none )
	{
		`HQPRES.UIBuildItem();
	}
}

function SelectSchematicArchiveHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);

	// get to schematic archives, once we're on the proving ground screen. 
	if( UIFacility_Storage(Movie.Stack.GetCurrentScreen()) != none )
	{
		`HQPRES.UISchematicArchives();
	}
}

function SelectBuildFacilitiesHotlink(StateObjectReference FacilityRef)
{
	`HQPRES.UIBuildFacilities();
}

function SelectInventoryHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);

	// get to build item, once we're on the storage screen: 
	if( UIFacility_Storage(Movie.Stack.GetCurrentScreen()) != none )
	{
		`HQPRES.UIInventory_Storage();
	}
}

function ViewEngineersHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);

	// get to personnel view, once we're on a labs screen, if inventory is not already open. 
	if( UIFacility_Storage(Movie.Stack.GetCurrentScreen()) != none )
		`HQPRES.UIPersonnel(eUIPersonnel_Engineers);
}

function ViewSoldiersHotlink(StateObjectReference FacilityRef)
{
	local UIFacility_Armory CurrentScreen;

	SelectFacilityHotlink(FacilityRef);

	// get to personnel view, once we're on a labs screen, if inventory is not already open. 
	CurrentScreen = UIFacility_Armory(Movie.Stack.GetCurrentScreen());
	if( CurrentScreen != none )
		CurrentScreen.Personnel();
}

function ViewPostersHotlink(StateObjectReference FacilityRef)
{
	SelectFacilityHotlink(FacilityRef);
	`HQPres.PhotoboothReview();
}

function SelectRecruitsHotlink(StateObjectReference FacilityRef)
{
	local UIFacility_Armory CurrentScreen;

	SelectFacilityHotlink(FacilityRef);

	// get to recruit screen, once we're on the armory screen. 
	CurrentScreen = UIFacility_Armory(Movie.Stack.GetCurrentScreen());
	if( CurrentScreen != none )
		CurrentScreen.Recruit();
}

function SelectFacilitySummaryHotlink(StateObjectReference FacilityRef)
{
	local UIFacility_CIC CurrentScreen;

	SelectFacilityHotlink(FacilityRef);

	// get to facility summary, once we're on the armory screen. 
	CurrentScreen = UIFacility_CIC(Movie.Stack.GetCurrentScreen());
	if( CurrentScreen != none )
		CurrentScreen.FacilitySummary();
}

function ViewObjectivesHotlink(StateObjectReference FacilityRef)
{
	local UIFacility_CIC CurrentScreen;

	SelectFacilityHotlink(FacilityRef);

	// get to view objectives screen, once we're on the armory screen. 
	CurrentScreen = UIFacility_CIC(Movie.Stack.GetCurrentScreen());
	if( CurrentScreen != none )
		CurrentScreen.ViewObjectives();
}

function ViewResistanceOrders(StateObjectReference FacilityRef)
{
	if( Movie.Pres.ScreenStack.GetScreen(class'UIChosenReveal') == none )
		`HQPRES.UIStrategyPolicy(false, true);
}

//==============================================================================

simulated function int GetUrgencyLevel(int iCat)
{
	if( Categories[iCat].Messages.Find( 'Urgency', eUIAvengerShortcutMsgUrgency_High ) > -1 )
		return eUIAvengerShortcutMsgUrgency_High; 

	if( Categories[iCat].Messages.Find( 'Urgency', eUIAvengerShortcutMsgUrgency_Medium ) > -1 )
		return eUIAvengerShortcutMsgUrgency_Medium; 

	return eUIAvengerShortcutMsgUrgency_Low; 

}


simulated function EUIState GetUrgencyColor(int iCat)
{
	if( Categories[iCat].Messages.Find( 'Urgency', eUIAvengerShortcutMsgUrgency_High ) > -1 )
		return eUIState_Bad; 

	if( Categories[iCat].Messages.Find( 'Urgency', eUIAvengerShortcutMsgUrgency_Medium ) > -1 )
		return eUIState_Warning; 

	return eUIState_Normal; 

}

simulated function UnHighlightAllShortcuts()
{
	local int i;
	for(i = 0; i < Categories.Length; ++i)
	{
		Categories[i].Button.AnimateShine(false);
	}
	Navigator.OnLoseFocus();
}
simulated function HighlightShortcutButton(int index, bool bHighlight)
{
	if (!Categories[index].Button.IsDisabled)
	{
		Categories[index].Button.AnimateShine(bHighlight);
	}

	if(bHighlight)
		Navigator.SetSelected(Categories[index].Button);
	else
	{
		Categories[index].Button.OnLoseFocus();
		Navigator.OnLoseFocus();
	}
}

simulated function HighlightRoomButton(StateObjectReference RoomReference)
{
	local int i;

	Navigator.OnLoseFocus();

	for (i = 0; i < Categories.Length; i++)
	{
		if (Categories[i].HotLinkRef == RoomReference)
		{
			HighlightShortcutButton(i, true);
		}
	}
}

//==============================================================================
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int iTargetCat;
	//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
	//INS:
	local bool bHandled;
	//</workshop>
	
	//<workshop> SCI 2016/5/23
	//INS:
	if (!bIsVisible)
	{
		return false;
	}
	//</workshop>

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;


	iTargetCat = -1;

	//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
	//INS:
	bHandled = true;
	//</workshop>

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			//<workshop> Fixed locked navigation SCI 2015/11/16
			//WAS:
			//iTargetCat = (CurrentCategory + 1) % Categories.Length;
			if (HasShadowChamber())
			{
				//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
				//WAS:
				//iTargetCat = (CurrentCategory + 1) % Categories.Length;
				iTargetCat = (InRoomCurrentShortcutTabHighlightIndex + 1) % Categories.Length;
				//</workshop>
			}
			else
			{
				//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
				//WAS:
				//iTargetCat = (CurrentCategory + 1) % (Categories.Length - 1);
				iTargetCat = (InRoomCurrentShortcutTabHighlightIndex + 1) % (Categories.Length - 1);
				//</workshop>
			}
			//</workshop>
			//<BSG> TTP_5913_ADDED_MISSING_SHORCUT_SOUND_WHEN_ZOOMED_IN JHilton 07.06.2016
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_Mouseover");
			//</BSG>
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
			//WAS:
			//iTargetCat = CurrentCategory - 1;
			iTargetCat = InRoomCurrentShortcutTabHighlightIndex - 1;
			//</workshop>
			if (iTargetCat < 0)
			{
				//<workshop> Fixed locked navigation SCI 2015/11/16
				//WAS:
				//iTargetCat = Categories.Length - 1;
				if (HasShadowChamber())
				{
					iTargetCat = Categories.Length - 1;
				}
				else
				{
					iTargetCat = Categories.Length - 2;
				}		
				//</workshop>
			}
				//<BSG> TTP_5913_ADDED_MISSING_SHORCUT_SOUND_WHEN_ZOOMED_IN JHilton 07.06.2016
				`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_Mouseover");
				//</BSG>
			break;
			//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
			// This is when we actually make the request to transition to the next room
			//INS:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			if(!List.bIsVisible && InRoomCurrentShortcutTabHighlightIndex != CurrentCategory)
			{
				`HQPRES.fCameraSwoopDelayTime = BUMPER_CAMERA_SWOOP_DELAY;
				SelectCategory(InRoomCurrentShortcutTabHighlightIndex);
				return true;
			}
			break;
			//</workshop>
			
		case class'UIUtilities_Input'.const.FXS_KEY_1 :
			CurrentCategory = -1; 
			XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.HotlinkToGeoscape();
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_2:
			iTargetCat = 0;
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_3:
			iTargetCat = 1;
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_4:
			iTargetCat = 2;
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_5:
			iTargetCat = 3;
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_6:
			iTargetCat = 4;
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_7:
			iTargetCat = 5;
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
			iTargetCat = -1;
			break;

		//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
		//INS:
		default:
			bHandled = false;
			break;
		//</workshop>
	}

	// if we aren't visible don't change categories because it will pull us from the geoscape
	// TODO: maybe this check needs to be more explicit like check to see if the geoscape is visible too
	if (!bIsVisible)
		return false;

	if( iTargetCat > -1 && iTargetCat < Categories.Length )
	{
		if(`ISCONTROLLERACTIVE)
		{
			//bsg-crobinson (5.2.17): Don't switch immediately to tabbed room, instead player must confirm to switch
			SelectCategoryButtonOnly(iTargetCat);
			if( InRoomCurrentShortcutTabHighlightIndex == CurrentCategory )
			{
				bHasShortcutTabAttention = false;
			}
			else
			{
				bHasShortcutTabAttention = true;
			}
		}
		else
		{
			SelectCategory(iTargetCat);
		}
		
		return true;
	}

	bHasShortcutTabAttention = false;
	//bsg-crobinson (5.2.17): end

	if (super.OnUnrealCommand(cmd, arg))
		return true;
	
	//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
	//WAS:
	//return List.OnUnrealCommand(cmd, arg);
	// Since we're manually hiding and unhiding the list, it's not always
	// appropriate to send input to the list anymore.
	if(List.bIsVisible && InRoomCurrentShortcutTabHighlightIndex == CurrentCategory)
	{
		if(List.OnUnrealCommand(cmd, arg))
		{
			ResetAndClearTabShortcutFunctionality();
			return true;
		}
		return false;
	}
	else
	{
		return bHandled;
	}
	//</workshop>
}

//<workshop> AVENGER_ROOM_TRANSITION_CHANGES kmartinez 2016-04-01
//INS:
simulated function ResetAndClearTabShortcutFunctionality()
{
	//we can't put away the list if it's open, and we can't unhighlight the same
	//button that's part of the list.
	if(!List.bIsVisible)
	{
		UnHighlightAllShortcuts();
		InRoomCurrentShortcutTabHighlightIndex = -1;
	}
	bHasShortcutTabAttention = false;
}
//</workshop>

//==============================================================================

simulated function CheckForInterrupt( int inewCat )
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local UIAvengerShortcutMessageCategory Category;
	local XComGameState_FacilityXCom FacilityState;
	local X2FacilityTemplate FacilityTemplate; 

	// Save a request for where we want to go.
	RequestedNewCategory = iNewCat; 

	// Ask current facility if it has any interrupts 
	Category = Categories[CurrentCategory];

	// Check if there is an interrupt function 
	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Category.HotLinkRef.ObjectID));
	FacilityTemplate = FacilityState.GetMyTemplate();

	if( FacilityTemplate.OnLeaveFacilityInterruptFn == none )
	{
		OnReturnFromInterrupt(true); //Push direct through the navigation
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Set Facility Interrupt callback");
		FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
		FacilityState.LeaveFacilityInterruptCallback = OnReturnFromInterrupt;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		FacilityTemplate.OnLeaveFacilityInterruptFn(Category.HotLinkRef); //Go out to the interrupt
	}
}

function OnReturnFromInterrupt( bool bContinueNav )
{
	local UIAvengerShortcutMessageCategory Category;
	local delegate<MsgCallback> MsgCallback;

	`log("OnReturnFromInterrupt",,'DebugHQCamera');
	if( bContinueNav )
	{
		if( RequestedNewCategory != CurrentCategory || !List.bIsVisible )
		{
			CurrentCategory = RequestedNewCategory;
			//Reset the selection if we change categories. 
			List.SetSelectedIndex(-1);
			InRoomCurrentShortcutTabHighlightIndex = CurrentCategory;
			`HQPRES.m_kFacilityGrid.SelectRoomByReference(Categories[CurrentCategory].HotLinkRef);
			RequestedNewCategory = -1;
			CachedListItemSelection = -1;
			ShowList(CurrentCategory);
		}

		Category = Categories[CurrentCategory];
		MsgCallback = Category.OnItemClicked;

		if( MsgCallback != none )
		{
			MsgCallback(Category.HotLinkRef);
		}
	}
	else
	{
		RequestedNewCategory = -1;
		InRoomCurrentShortcutTabHighlightIndex = CurrentCategory;
	}
}

// Used by the UITutorialHelper to point at things.
simulated function UIButton GetCategoryButtonForFacility(StateObjectReference CategoryHotLinkRef)
{
	local int i;
	for( i = 0; i < Categories.length; i++ )
	{
		if( CategoryHotLinkRef == Categories[i].HotLinkRef )
			return Categories[i].Button;
	}
	return none;
}
simulated function UIListItemString GetListItemByHotLink(StateObjectReference MessageHotLinkRef)
{
	local int i;
	local array <UIAvengerShortcutMessage> Messages; 

	Messages = Categories[CurrentCategory].Messages; 

	for( i = 0; i < Messages.length; i++ )
	{
		if( MessageHotLinkRef == Messages[i].HotLinkRef )
			return UIListItemString(List.GetItem(i));
	}
	return none;
}

simulated function GoToXComDatabase(optional StateObjectReference Facility)
{
	Movie.Pres.UIXComDatabase();
}

//==============================================================================


function InitializeTooltipResearch()
{
	Categories[eUIAvengerShortcutCat_Research].Button.SetTooltipWIthCallback("Init", RefreshTooltipResearch);
}

function InitializeTooltipEngineering()
{
	Categories[eUIAvengerShortcutCat_Engineering].Button.SetTooltipWIthCallback("Init", RefreshTooltipEngineering);
}

function InitializeTooltipBarracks()
{
	Categories[eUIAvengerShortcutCat_Barracks].Button.SetTooltipWIthCallback("Init", RefreshTooltipBarracks);
}

function InitializeTooltipCommandersQuarters()
{
	Categories[eUIAvengerShortcutCat_CommandersQuarters].Button.SetTooltipWIthCallback("Init", RefreshTooltipCommandersQuarters);
}

function InitializeTooltipShadowChamber()
{
	Categories[eUIAvengerShortcutCat_ShadowChamber].Button.SetTooltipWIthCallback("Init", RefreshTooltipShadowChamber);
}

simulated function RefreshTooltipResearch(UITooltip Tooltip)
{
	local string TooltipDesc; 
	local byte KeyNotFound; 
	local XComKeybindingData KeyBindData; 
	local PlayerInput PlayerIn; 

	PlayerIn = XComPlayerController(`HQPRES.Owner).PlayerInput;
	KeyBindData = `HQPRES.m_kKeybindingData;
	KeyNotFound = 0;

	TooltipDesc = class'UIUtilities_Input'.static.FindAbilityKey(TooltipResearch, "%KEY:TWO%", eABC_Research, KeyNotFound, KeyBindData, PlayerIn, eKC_Avenger );
	UITextTooltip(Tooltip).SetText(TooltipDesc);
}


simulated function RefreshTooltipEngineering(UITooltip Tooltip)
{
	local string TooltipDesc; 
	local byte KeyNotFound; 
	local XComKeybindingData KeyBindData; 
	local PlayerInput PlayerIn; 

	PlayerIn = XComPlayerController(`HQPRES.Owner).PlayerInput;
	KeyBindData = `HQPRES.m_kKeybindingData;
	KeyNotFound = 0;

	TooltipDesc = class'UIUtilities_Input'.static.FindAbilityKey(TooltipEngineering, "%KEY:THREE%", eABC_Engineering, KeyNotFound, KeyBindData, PlayerIn, eKC_Avenger );
	UITextTooltip(Tooltip).SetText(TooltipDesc);
}

simulated function RefreshTooltipBarracks(UITooltip Tooltip)
{
	local string TooltipDesc; 
	local byte KeyNotFound; 
	local XComKeybindingData KeyBindData; 
	local PlayerInput PlayerIn; 

	PlayerIn = XComPlayerController(`HQPRES.Owner).PlayerInput;
	KeyBindData = `HQPRES.m_kKeybindingData;
	KeyNotFound = 0;

	TooltipDesc = class'UIUtilities_Input'.static.FindAbilityKey(TooltipBarracks, "%KEY:FOUR%", eABC_Barracks, KeyNotFound, KeyBindData, PlayerIn, eKC_Avenger );
	UITextTooltip(Tooltip).SetText(TooltipDesc);
}

simulated function RefreshTooltipCommandersQuarters(UITooltip Tooltip)
{
	local string TooltipDesc; 
	local byte KeyNotFound; 
	local XComKeybindingData KeyBindData; 
	local PlayerInput PlayerIn; 

	PlayerIn = XComPlayerController(`HQPRES.Owner).PlayerInput;
	KeyBindData = `HQPRES.m_kKeybindingData;
	KeyNotFound = 0;

	TooltipDesc = class'UIUtilities_Input'.static.FindAbilityKey(TooltipCommandersQuarters, "%KEY:FIVE%", eABC_CommandersQuarters, KeyNotFound, KeyBindData, PlayerIn, eKC_Avenger );
	UITextTooltip(Tooltip).SetText(TooltipDesc);
}

simulated function RefreshTooltipShadowChamber(UITooltip Tooltip)
{
	local string TooltipDesc; 
	local byte KeyNotFound; 
	local XComKeybindingData KeyBindData; 
	local PlayerInput PlayerIn; 

	PlayerIn = XComPlayerController(`HQPRES.Owner).PlayerInput;
	KeyBindData = `HQPRES.m_kKeybindingData;
	KeyNotFound = 0;

	TooltipDesc = class'UIUtilities_Input'.static.FindAbilityKey(TooltipShadowChamber, "%KEY:SIX%", eABC_ShadowChamber, KeyNotFound, KeyBindData, PlayerIn, eKC_Avenger );
	UITextTooltip(Tooltip).SetText(TooltipDesc);
}

// *************** BEGIN ISSUE #163 HELPER FUNCTIONS *******************

// Add a new sub-menu to the given category.
simulated function AddSubMenu(int Category, out UIAvengerShortcutSubMenuItem Item)
{
    if (Category < 0 || Category > eUIAvengerShortcutCat_MAX)
    {
        `redscreen("UIAvengerShortcuts (LWS)::AddCategorySubMenu: Bad Shortcut category: " $ Category);
        return;
    }

    ModSubMenus[Category].SubMenuItems.AddItem(Item);
}

simulated function UpdateSubMenu(int Category, out UIAvengerShortcutSubMenuItem Item)
{
    local int i;

    if (Category < 0 || Category > eUIAvengerShortcutCat_MAX)
    {
        `redscreen("UIAvengerShortcut (LWS)::AddCategorySubMenu: Bad Shortcut category: " $ Category);
        return;
    }

    for (i = 0; i < ModSubMenus[Category].SubMenuItems.Length; ++i)
    {
        if (ModSubMenus[Category].SubMenuItems[i].Id == Item.Id)
        {
            ModSubMenus[Category].SubmenuItems[i] = Item;
            return;
        }
    }     
}

// Look up a given sub-menu in the current list for the given category. Returns true if found,
// or false if no such menu exists.
simulated function bool FindSubMenu(int Category, name Id, out UIAvengerShortcutSubMenuItem Item)
{
    local int i;

    if (Category < 0 || Category > eUIAvengerShortcutCat_MAX)
    {
        `redscreen("UIAvengerShortcuts (LWS)::AddCategorySubMenu: Bad Shortcut category: " $ Category);
        return false;
    }

    for (i = 0; i < ModSubMenus[Category].SubMenuItems.Length; ++i)
    {
        if (ModSubMenus[Category].SubMenuItems[i].Id == Id)
        {
            Item = ModSubMenus[Category].SubMenuItems[i];
            return true;
        }
    }

    return false;
}

simulated function RemoveSubMenu(int Category, name Id)
{
      local int i;

    if (Category < 0 || Category > eUIAvengerShortcutCat_MAX)
    {
        `redscreen("UIAvengerShortcuts (LWS)::AddCategorySubMenu: Bad Shortcut category: " $ Category);
        return;
    }

    for (i = 0; i < ModSubMenus[Category].SubMenuItems.Length; ++i)
    {
        if (ModSubMenus[Category].SubMenuItems[i].Id == Id)
        {
            ModSubMenus[Category].SubMenuItems.Remove(i, 1);
            return;
        }
    }  
}

// *************** END ISSUE #163 HELPER FUNCTIONS *******************

defaultproperties
{
	MCName          = "AvengerShortcuts";	
	bIsNavigable	= true; 
	bCascadeFocus = false; 
	ShouldShowWhenRealized = false;
	CurrentCategory = -1;
	InRoomCurrentShortcutTabHighlightIndex = -1;
	bHasShortcutTabAttention = false;
}
