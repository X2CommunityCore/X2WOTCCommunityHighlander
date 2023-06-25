//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIFacilityGrid_FacilityOverlay
//  AUTHOR:  Sam Batista, Brittany Steiner
//  PURPOSE: Displays a graphical element over a facility in the Avenger
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIFacilityGrid_FacilityOverlay extends UIPanel
	dependson(UIStaffIcon);

struct TUIRoomData
{
	var String strTitle;
	var String strLabel;
	var String strQueue;
	var EUIState eBorderColor;
	var int iAlpha;
	var int iBackDropAlpha; // 0 - 100 alpha value.
	var bool bHighlight;
	var bool bClearing;
	var bool bUnderConstruction;
	var bool bLocked;
	var bool bShowCancel;
	var bool bShowRemove;
	var bool bShowUpgrade;
	var array<EUIStaffIconType> StaffIcons;
};

var UIList	FacilityIcons;
var array<EUIStaffIconType> IconTypes;

var UIPanel BGPanel; 
var UIButton CancelConstructionButton;
var UIButton UpgradeButton;
var UIButton RemoveButton;
var EUIState		BGState;
var string			BGColor; 
var bool			bAlignRight;
var bool			bIsHighlighted;

var Vector m_RoomLocation;
var array<vector> Corners;
var StateObjectReference RoomRef;
var StateObjectReference m_UnitRef; // used when reassigning staff
var int RoomMapIndex; 

var string Label; 
var string Status; 
var string Queue;
var bool bUnderConstruction; 
var bool m_bClearing;
var bool bLocked;
var privatewrite bool m_bCanCancelConstruction; //used to convert buttons to navhelp

var localized string m_strEmpty;
var localized string m_strHealth;
var localized string m_strConstruct;
var localized string m_strDemolish;
var localized string m_strUnderConstruction;
var localized string m_strUnderConstructionNoStaff;
var localized string m_strCancelConstructionButton;
var localized string m_strCancelConstructionTitle;
var localized string m_strCancelConstructionDescription;
var localized string m_strCancelConstructionConfirm;
var localized string m_strCancelConstructionCancel;
var localized string m_strCancelClearRoomDescription;
var localized string m_strRemoveFacilityTitle;
var localized string m_strRemoveFacilityDescription;
var localized string m_strCantRemoveFacilityTitle;
var localized string m_strLocked;
var localized string m_strLockedLabel;
var localized String m_strUpgrade;
var localized String m_strRemove;
var localized string m_strAlienMachinery;
var localized string m_strReinforcedBulkhead;
var localized string m_strExposedPowerCell;
var localized string m_strShieldedPowerCell;
var localized string m_strAlienDebris;
var localized string m_strClearMachinery;
var localized string m_strShieldPowerCell;
var localized string m_strClearDebris;
var localized string m_strClearMachineryInProgress;
var localized string m_strShieldPowerCellInProgress;
var localized string m_strClearDebrisInProgress;
var localized string m_strClearMachineryHalted;
var localized string m_strShieldPowerCellHalted;
var localized string m_strClearDebrisHalted;
var localized string m_strFlyShipStatus;
var localized string m_strClearCost;
var localized string m_strEngCost;
var localized string m_strSciCost;
var localized string m_strNeedMoreScientistsTitle;
var localized string m_strNeedMoreScientistsText;
var localized string m_strNeedMoreEngineersTitle;
var localized string m_strNeedMoreEngineersText;
var localized string m_strNeedMoreSuppliesTitle;
var localized string m_strNeedMoreSuppliesText;
var localized String m_strReward;
var localized String m_strRequired;
var localized String m_strUpgrading;
var localized String m_strStaff;
var localized String m_strPaused;
var localized string TooltipCancelConstruction;
var localized string TooltipUpgrade;
var localized string TooltipRemove;
var localized string m_strShieldedPowerCoilTooltip;

var private int BuildModeUnSelectedAlpha;
var private int BuildModeUnSelectedBackGroundTextAlpha;
//----------------------------------------------------------------------------
// MEMBERS

simulated function InitFacilityOverlay(StateObjectReference InitRoomRef, Vector RoomLocation, array<Vector> RoomCorners)
{
	local XComGameState_HeadquartersRoom Room;

	InitPanel(, GetLibId(InitRoomRef) );

	RoomRef = InitRoomRef;
	m_RoomLocation = RoomLocation;
	Corners = RoomCorners;

	Room = GetRoom();
	RoomMapIndex = Room.MapIndex;

	InitLayout();
	
	BGPanel = Spawn(class'UIPanel', self).InitPanel('roomOutline');
	BGPanel.ProcessMouseEvents(OnChildMouseEvent);
	BGPanel.AddOnInitDelegate(OnBGPanelInited);
	BGPanel.Hide();

	InitActionButtons();

	FacilityIcons = Spawn(class'UIList', self);
	FacilityIcons.InitList(, 5, height-25, width - 5, 20, true);
	FacilityIcons.bAnimateOnInit = false;
	FacilityIcons.ShrinkToFit();
	FacilityIcons.bStickyHighlight = false; 
	FacilityIcons.ItemPadding = 6;

	UpdateData();
}

// Any layout that needs to be updated only once, and not constantly in the update refresh. 
simulated function InitLayout()
{
	local XComGameState_HeadquartersRoom Room;
	local X2FacilityTemplate FacilityTemplate;

	Room = GetRoom();

	// Set Facility Name
	if( Room.HasFacility() )
	{
		FacilityTemplate = GetFacility().GetMyTemplate();
		
		if( FacilityTemplate.UIFacilityGridAlignRight )
			AlignRight();
		else if( FacilityTemplate.UIFacilityGridAlignCenter )
			AlignCenter();
		//special facility alignement, handled in flash
		switch(FacilityTemplate.DataName)
		{
			case 'PowerCore':
				MC.FunctionVoid("alignPowerCoreTitle");
				break;
			case 'Hangar':
				MC.FunctionVoid("alignArmoryTitle");
				break;
			case 'CIC':
				MC.FunctionVoid("alignCICTitle");
				break;
			case 'CommandersQuarters':
				MC.FunctionVoid("alignCommanderTitle");
				break;
			case 'Storage':
				MC.FunctionVoid("alignEngineeringTitle");
				break;
		}
	}
}

simulated function InitActionButtons()
{
	local String strButton;

	strButton = class'UIUtilities_Text'.static.GetColoredText(m_strUpgrade, eUIState_Good, 25);
	UpgradeButton = Spawn(class'UIButton', self);
	UpgradeButton.bIsNavigable = false;
	UpgradeButton.InitButton('OverlayUpgradeButton', strButton, OnUpgradeClicked, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	UpgradeButton.Hide(); // start off hidden
	SetHelperTooltip(UpgradeButton, TooltipUpgrade);
	UpgradeButton.OnMouseEventDelegate = OnChildMouseEvent;
	UpgradeButton.SetTooltipText(TooltipUpgrade);
	Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(UpgradeButton.CachedTooltipId, true);

	// ---------------

	strButton = class'UIUtilities_Text'.static.GetColoredText(m_strRemove, eUIState_Bad, 25);
	RemoveButton = Spawn(class'UIButton', self);
	RemoveButton.bIsNavigable = false;
	RemoveButton.InitButton('OverlayRemoveButton', strButton, OnRemoveClicked, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	RemoveButton.Hide(); // start off hidden
	RemoveButton.OnMouseEventDelegate = OnChildMouseEvent;
	RemoveButton.SetTooltipText(TooltipRemove);
	Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(RemoveButton.CachedTooltipId, true);

	//---------------

	strButton = class'UIUtilities_Text'.static.GetColoredText(m_strCancelConstructionButton, eUIState_Bad, 25);
	CancelConstructionButton = Spawn(class'UIButton', self);
	CancelConstructionButton.bIsNavigable = false;
	CancelConstructionButton.InitButton('OverlayCancelConstructionButton', strButton, OnCancelConstruction, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	CancelConstructionButton.Hide(); // start off hidden
	CancelConstructionButton.SetTooltipText(TooltipCancelConstruction);
	Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(CancelConstructionButton.CachedTooltipId, true);
	CancelConstructionButton.OnMouseEventDelegate = OnChildMouseEvent;
}

simulated function SetHelperTooltip( UIPanel TargetPanel, string Text)
{
}

simulated function XComGameState_HeadquartersRoom GetRoom()
{
	local XComGameState_HeadquartersRoom Room;

	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomRef.ObjectID));

	return Room;
}

simulated function XComGameState_FacilityXCom GetFacility()
{
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;

	Room = GetRoom();

	if( Room != none )
	{
		if( Room.HasFacility() )
		{
			Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Room.Facility.ObjectID));
		}
		else if( Room.UnderConstruction )
		{
			Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().GetFacilityProject(Room.GetReference()).ProjectFocus.ObjectID));
		}
	}

	return Facility;
}

simulated function bool IsBuildMode()
{
	return UIBuildFacilities(Movie.Stack.GetCurrentScreen()) != none || UIFacilityGrid(Screen).bForceShowGrid;
}

// Update the visuals of this individual grid
simulated function UpdateData()
{
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersRoom Room;
	
	Room = GetRoom();
	Facility = GetFacility();

	if (Room == none )
		return;

	if( Facility != none )
	{
		if (Facility.GetMyTemplate() == none)
			return;

		if( Facility.bTutorialLocked )
		{
			UpdateTutorialLocked();
		}
		else if( GetRoom().UnderConstruction )
		{
			UpdateConstructionFacility();
		}
		else if( Facility.GetMyTemplate().bIsCoreFacility )
		{
			UpdateCoreFacility();
		}
		else
		{
			UpdateFacility();
		}
	}
	else
	{
		if( Room != none )
		{
			if( Room.bTutorialLocked )
			{
				UpdateTutorialLocked();
			}
			else if( Room.ClearingRoom )
			{
				UpdateClearingRoom();
			}
			else if (Room.Locked)
			{
				UpdateLockedRoom();
			}
			else if( Room.HasSpecialFeature() )
			{
				UpdateFeatureRoom();
			}
			else
			{
				UpdateEmptyRoom();
			}
		}
	}
	RefreshStatusIcons(IconTypes);
}

simulated function UpdateTutorialLocked()
{
	local TUIRoomData kData;

	kData.bLocked = true;
	kData.eBorderColor = eUIState_Disabled;
	kData.iAlpha = 0;
	kData.iBackDropAlpha = -1;

	if( bIsFocused )
	{
		kData.bHighlight = true;
		kData.iAlpha = 75;
	}

	UpdateGridUI(kData);
}

// A room that is empty and ready to be built in
simulated function UpdateEmptyRoom()
{
	local TUIRoomData kData;

	kData.eBorderColor = eUIState_Good;

	kData.iBackDropAlpha = -1;
	if( IsBuildMode() )
	{
		if( bIsFocused )
		{
			kData.bHighlight = true;
			kData.strTitle = m_strEmpty;
			kData.strLabel = m_strConstruct;
			kData.iAlpha = 100;
		}
		else
		{
			if( `ISCONTROLLERACTIVE )
			{
				kData.iAlpha = BuildModeUnSelectedAlpha;
				kData.iBackDropAlpha = BuildModeUnSelectedBackGroundTextAlpha;
			}
			else
			{
				kData.iAlpha = 75;
			}
		}
	}
	else
	{
		if( bIsFocused )
		{
			kData.bHighlight = true;
			kData.eBorderColor = eUIState_Normal;
			kData.strTitle = m_strEmpty;
			kData.iAlpha = 100;
		}
	}

	UpdateGridUI(kData);
}

// A room that is currently being cleared of alien debris/machinery/etc
simulated function UpdateClearingRoom()
{
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_HeadquartersProjectClearRoom ClearRoomProject;
	local TUIRoomData kData;
	local int iHours;

	Room = GetRoom();

	kData.bClearing = true;
	kData.iAlpha = 75;
	kData.iBackDropAlpha = -1;

	ClearRoomProject = Room.GetClearRoomProject();
	if( ClearRoomProject != none )
	{
		if (Room.GetClearRoomProject().MakingProgress())
		{
			kData.bHighlight = bIsFocused;
			kData.eBorderColor = eUIState_Warning;
			kData.strTitle = Room.GetClearingInProgressLabel();

			iHours = GetRoom().GetClearRoomProject().GetCurrentNumHoursRemaining();

			if(iHours <= 0)
			{
				// Guard against instances where we scanned past the end time, but the end popup hasn't triggered
				iHours = 1;
			}

			kData.strLabel = class'UIUtilities_Text'.static.GetTimeRemainingString(iHours);
		}
		else
		{
			kData.eBorderColor = eUIState_Bad;
			kData.strTitle = Room.GetClearingInProgressLabel();
			kData.strLabel = m_strPaused;
		}
	}

	kData.StaffIcons = GetStaffIconDataForClearingSlots();

	if( IsBuildMode() )
	{
		if( bIsFocused )
		{
			kData.iAlpha = 100;
		}
		else
		{
			kData.iBackDropAlpha = BuildModeUnSelectedBackGroundTextAlpha;
		}
	}
	else
	{
		if( bIsFocused )
		{
			kData.bHighlight = true;
			kData.iAlpha = 100;
		}
	}

	UpdateGridUI(kData);
}

// A room that is locked due to surrounding rooms not being cleared
simulated function UpdateLockedRoom()
{
	local XComGameState_HeadquartersRoom Room;
	local TUIRoomData kData;

	kData.bLocked = true;
	kData.eBorderColor = eUIState_Disabled;

	kData.iBackDropAlpha = -1;
	Room = GetRoom();

	if (IsBuildMode())
	{
		kData.strTitle = Room.GetSpecialFeatureLabel();
		kData.strLabel = m_strLocked;

		if (bIsFocused)
		{
			kData.strLabel = class'UIUtilities_Text'.static.GetColoredText(m_strLockedLabel, eUIState_Bad);
			kData.iAlpha = 100;
			kData.eBorderColor = eUIState_Bad;
		}
		else
		{
			if( `ISCONTROLLERACTIVE )
			{
				kData.iAlpha = BuildModeUnSelectedAlpha;
				kData.iBackDropAlpha = BuildModeUnSelectedBackGroundTextAlpha;
			}
			else
			{
				kData.iAlpha = 75;
			}
		}
	}
	else
	{
		if (bIsFocused)
		{
			kData.strTitle = Room.GetSpecialFeatureLabel();
			kData.strLabel = m_strLocked;
			kData.iAlpha = 100;
			kData.bHighlight = true;
			kData.eBorderColor = eUIState_Bad;
		}
	}

	UpdateGridUI(kData);
}

// A room that has alien debris/machinery/etc.
simulated function UpdateFeatureRoom()
{
	local X2SpecialRoomFeatureTemplate FeatureTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
	local TUIRoomData kData;

	kData.eBorderColor = eUIState_Normal;

	kData.iBackDropAlpha = -1;
	Room = GetRoom();

	if( IsBuildMode() )
	{
		kData.strTitle = Room.GetSpecialFeatureLabel();

		if( bIsFocused )
		{
			kData.iAlpha = 100;

			if (Room.HasShieldedPowerCoil()) // if the special feature is a cleared, positive benefit
			{
				// Present as an "empty" room able to be built
				kData.bHighlight = true;
				kData.strLabel = m_strConstruct;
				kData.eBorderColor = eUIState_Good;

				BGPanel.SetTooltipText(m_strShieldedPowerCoilTooltip);
			}
			else
			{
				FeatureTemplate = Room.GetSpecialFeature();
				kData.strLabel = FeatureTemplate.ClearText;

				XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

				if (!XComHQ.MeetsAllStrategyRequirements(FeatureTemplate.Requirements))
				{
					kData.strQueue = m_strRequired @ class'UIUtilities_Strategy'.static.GetStrategyReqString(FeatureTemplate.Requirements);
					kData.eBorderColor = eUIState_Bad;
				}
				else
				{
					if ((FeatureTemplate.GetDepthBasedCostFn != none) && !XComHQ.CanAffordAllStrategyCosts(FeatureTemplate.GetDepthBasedCostFn(Room), XComHQ.RoomSpecialFeatureCostScalars))
					{
						kData.eBorderColor = eUIState_Bad;
					}
					else
					{
						kData.bHighlight = true;
					}

					kData.strQueue = m_strReward @ class'UIUtilities_Text'.static.GetColoredText(Room.GetLootString(true), eUIState_Good);
					
				}
			}
		}
		else
		{
			if( `ISCONTROLLERACTIVE )
			{
				kData.iAlpha = BuildModeUnSelectedAlpha;
				kData.iBackDropAlpha = BuildModeUnSelectedBackGroundTextAlpha;
			}
			else
			{
				kData.iAlpha = 75;
			}

			if (Room.HasShieldedPowerCoil()) // if the special feature is a cleared, set the border color to green
			{
				kData.eBorderColor = eUIState_Good;
			}
		}
	}
	else
	{
		if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M9_ExcavateRoom') == eObjectiveState_InProgress && !Room.Locked)
		{
			kData.bHighlight = true;
			kData.iAlpha = 100;
			kData.eBorderColor = eUIState_Warning;
		}

		if( bIsFocused )
		{
			kData.strTitle = Room.GetSpecialFeatureLabel();
			kData.iAlpha = 100;
			kData.bHighlight = true;

			if (Room.HasShieldedPowerCoil()) // if the special feature is a cleared, positive benefit
			{
				BGPanel.SetTooltipText(m_strShieldedPowerCoilTooltip);
			}
		}
	}

	UpdateGridUI(kData);
}

// A facility that is under construction
simulated function UpdateConstructionFacility()
{
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local TUIRoomData kData;
	local int iHours;

	kData.eBorderColor = eUIState_Warning;
	kData.iAlpha = 75;
	kData.bUnderConstruction = true;
	kData.iBackDropAlpha = -1;

	kData.strTitle = GetFacility().GetMyTemplate().DisplayName;

	FacilityProject = GetRoom().GetBuildFacilityProject();

	if( FacilityProject != none )
	{
		if(FacilityProject.MakingProgress())
		{
			iHours = FacilityProject.GetCurrentNumHoursRemaining();

			if(iHours <= 0)
			{
				// Guard against instances where we scanned past the end time, but the end popup hasn't triggered
				iHours = 1;
			}

			kData.strLabel = class'UIUtilities_Text'.static.GetTimeRemainingString(iHours);
		}
		else
		{
			kData.strLabel = m_strPaused;
			kData.eBorderColor = eUIState_Bad;
		}
	}

	kData.StaffIcons = GetStaffIconDataForConstructionSlots();

	if( IsBuildMode() )
	{
		if( bIsFocused )
		{
			kData.bHighlight = true;
			kData.iAlpha = 100;
			kData.bShowCancel = true;
		}
	}
	else
	{
		if( bIsFocused )
		{
			kData.bHighlight = true;
			kData.iAlpha = 100;
		}
	}

	UpdateGridUI(kData);
}

// A facility that has been constructed by the player
simulated function UpdateFacility()
{
	//local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;
	local XComGameState_FacilityXCom Facility;
	local TUIRoomData kData;
	//local bool bUpgrading;

	Facility = GetFacility();
	kData.eBorderColor = eUIState_Normal;
	kData.iBackDropAlpha = -1;

	kData.StaffIcons = GetStaffIconData(Facility);
	
	if( IsBuildMode() )
	{
		kData.strTitle = GetFacility().GetMyTemplate().DisplayName;
		//WAS: do we need this switch? bsteiner 
		//kData.bHighlight = true;
		kData.bHighlight = false;
		kData.bShowUpgrade = Facility.CanUpgrade();
		kData.bShowRemove = true;

		if( Facility.CanUpgrade() )
		{
			kData.bHighlight = true;
			kData.bHighlight = false;
			kData.bShowUpgrade = true;
			kData.eBorderColor = eUIState_Normal;
		}

		if( bIsFocused )
		{
			kData.bHighlight = true;
			kData.iAlpha = 100;
			kData.bShowRemove = true;
		}
		else
		{
			if( `ISCONTROLLERACTIVE )
			{
				kData.iAlpha = BuildModeUnSelectedAlpha;
				kData.iBackDropAlpha = BuildModeUnSelectedBackGroundTextAlpha;
			}
			else
			{
				kData.iAlpha = 50;
			}
		}
	}
	else
	{
		if( Facility.NeedsAttention() )
		{
			kData.bHighlight = true;
			kData.iAlpha = 100;
			kData.eBorderColor = eUIState_Warning;
		}

		if( bIsFocused )
		{
			kData.strTitle = GetFacility().GetMyTemplate().DisplayName;
			kData.strQueue = GetQueueMessage(GetRoom());
			kData.iAlpha = 100;
			kData.bHighlight = true;
		}
	}

	UpdateGridUI(kData);
}

// A facility that has in the Avenger when the game started
simulated function UpdateCoreFacility()
{
	local XComGameState_FacilityXCom Facility;
	local TUIRoomData kData;

	Facility = GetFacility();
	kData.eBorderColor = eUIState_Normal;
	kData.iBackDropAlpha = -1;

	kData.StaffIcons = GetStaffIconData(Facility);

	if( IsBuildMode() )
	{
		kData.bShowUpgrade = Facility.CanUpgrade();
		kData.bShowRemove = Facility.CanRemove();
		kData.strTitle = GetFacility().GetMyTemplate().DisplayName;
	}
	else
	{
		if( Facility.NeedsAttention() )
		{
			kData.bHighlight = true;
			kData.iAlpha = 100;
			kData.eBorderColor = eUIState_Warning;
		}

		if( bIsFocused )
		{
			kData.strTitle = GetFacility().GetMyTemplate().DisplayName;
			kData.strQueue = GetQueueMessage(GetRoom());
			kData.iAlpha = 100;
			kData.bHighlight = true;
		}
	}

	UpdateGridUI(kData);
}

simulated function UpdateGridUI(TUIRoomData kData)
{
	local XComHeadquartersCheatManager CheatMgr;

	SetBGColorState(kData.eBorderColor);
	SetLabel(kData.strTitle);
	SetStatus(kData.strLabel, kData.strQueue);
	
	CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);
	if (CheatMgr == none || !CheatMgr.bGamesComDemo)
	{
		SetHighlighted(kData.bHighlight);
		SetBorderAlpha(kData.iAlpha);
		SetTextBackDropAlpha(kData.iBackDropAlpha);
	}
	else
	{
		SetHighlighted(false);
		SetBorderAlpha(0);
	}

	SetConstruction(kData.bUnderConstruction);
	SetClearing(kData.bClearing);
	SetLocked(kData.bLocked);

	RefreshStatusIcons(kData.StaffIcons);

	if( kData.bShowCancel )
	{
		if( `ISCONTROLLERACTIVE ) 
		{
		
			m_bCanCancelConstruction = true;
		}
		else
		{
			CancelConstructionButton.Show();
		}
	}
	else
	{
		m_bCanCancelConstruction = false;
		CancelConstructionButton.Hide();
	}
	if( `ISCONTROLLERACTIVE == false ) 
	{
		if( kData.bShowRemove )
		{
			RemoveButton.Show();
		}
		else
		{
			RemoveButton.Hide();
		}
	}
	if( kData.bShowUpgrade )
	{
		UpgradeButton.Show();
	}
	else
	{
		UpgradeButton.Hide();
	}
}

simulated function string GetQueueMessage(XComGameState_HeadquartersRoom Room)
{
	local string strStatus;

	if( Room.HasFacility() )
	{
		strStatus = Room.GetFacility().GetQueueMessage();
	}

	return strStatus;
}

// Don't delay AnimateIn or AnimateOut functions
simulated function AnimateIn(optional float Delay = -1.0) { super.AnimateIn(0); }
simulated function AnimateOut(optional float Delay = -1.0) { super.AnimateOut(0); }

// --------------------------------------------------------------------------------------

simulated function OnChildMouseEvent( UIPanel control, int cmd )
{
	switch( control )
	{
	case UpgradeButton:
	case RemoveButton:
	case CancelConstructionButton:
		OnReceiveFocus();
		break;
	default:
		switch( cmd )
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			OnConfirm();
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			OnReceiveFocus();
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			OnLoseFocus();
			break;
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
			// These must be reversed for some reason -sbatista
			`HQINPUT.MouseScrollDown(class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
			break;
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
			// These must be reversed for some reason -sbatista
			`HQINPUT.MouseScrollUp(class'UIUtilities_Input'.const.FXS_ACTION_PRESS);
			break;
		}
	}
}

// --------------------------------------------------------------------------------------
simulated function OnReceiveFocus()
{
	//local UIPanel Child; 

	//DO NOT CALL SUPER. We don't want to activate all of the children. 
	//super.OnReceiveFocus();

	if(!bIsFocused) 
	{
		bIsFocused = true;
		MC.FunctionVoid("onReceiveFocus");
	}

	BGPanel.OnReceiveFocus();

	UpdateData();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_Mouseover");
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Movie.Pres.m_kTooltipMgr.HideTooltipsByPartialPath(string(MCPath));
	UpdateData();
}

// --------------------------------------------------------------------------------------
simulated function OnShowGrid()
{
	UpdateData();
}

simulated function OnHideGrid()
{
	UpdateData();
	Movie.Pres.m_kTooltipMgr.HideTooltipsByPartialPath(string(MCPath));
}

// --------------------------------------------------------------------------------------

simulated function OnConfirm()
{
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;

	if( bLocked )
	{
		return;
	}
	
	Room = GetRoom();
	Facility = GetFacility();

	if( IsBuildMode() )
	{
	        if (Facility != none && Facility.CanUpgrade())
	        {
				OnUpgradeClicked(none);
		}
		else
		if( IsAvailableForConstruction(Room) )
		{
			`HQPRES.CAMLookAtRoom(Room, `HQINTERPTIME);
			`HQPRES.UIChooseFacility(RoomRef);
		}
		else if( IsAvailableForClearing(Room) )
		{
			`HQPRES.CAMLookAtRoom(Room, `HQINTERPTIME);
			class'UIUtilities_Strategy'.static.SelectRoom(RoomRef);
		}
		else if (Room.Locked && !Room.HasFacility())
		{
			`HQPRES.RoomLockedPopup();
		}
	}
	else
	{
		if( Room == none)
			return;

		if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M9_ExcavateRoom') == eObjectiveState_InProgress &&
		   Room.MapIndex == class'XComGameState_HeadquartersXCom'.default.TutorialExcavateIndex)
		{
			`HQPRES.CAMLookAtRoom(Room, `HQINTERPTIME);
			class'UIUtilities_Strategy'.static.SelectRoom(RoomRef);
		}
		else if (Room.ClearingRoom || Room.UnderConstruction)
		{
			class'UIUtilities_Strategy'.static.SelectRoom(RoomRef);
		}
		else if(Facility != none && !Facility.IsUnderConstruction() )
		{
			class'UIUtilities_Strategy'.static.SelectFacility(Room.Facility);
		}
		else
		{
			`HQPRES.UIBuildFacilities();
		}
			
	}
}

// --------------------------------------------------------------------------------------

simulated function bool IsAvailableForConstruction(XComGameState_HeadquartersRoom Room)
{
	return !Room.HasFacility() && !Room.UnderConstruction && !Room.ConstructionBlocked && !Room.Locked;
}

simulated function bool IsAvailableForClearing(XComGameState_HeadquartersRoom Room)
{
	return Room.HasSpecialFeature() && Room.ConstructionBlocked && !Room.ClearingRoom && !Room.Locked;
}

//Adding means to detect if construction/upgrades can be canceled
simulated function bool IsCancelAvailable()
{
	return m_bCanCancelConstruction;
}

simulated function OnCancelConstruction(UIButton kButton)
{
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersRoom Room;
	local UICallbackData_StateObjectReference CallbackData;

	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomRef.ObjectID));
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	if (Room.UnderConstruction)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().GetFacilityProject(Room.GetReference()).ProjectFocus.ObjectID));
		kTag.StrValue0 = Facility.GetMyTemplate().DisplayName;
	}
	else if (Room.ClearingRoom)
	{
		kTag.StrValue0 = Room.GetSpecialFeature().ClearingInProgressText;
	}

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle	= m_strCancelConstructionTitle;
	kDialogData.strText     = `XEXPAND.ExpandString(Room.ClearingRoom ? m_strCancelClearRoomDescription : m_strCancelConstructionDescription);
	
	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Room.GetReference();
	kDialogData.xUserData = CallbackData;
	kDialogData.fnCallbackEx  = (Room.ClearingRoom ? CancelClearRoomDialogueCallback : CancelConstructionDialogueCallback);

	kDialogData.strAccept = m_strCancelConstructionConfirm;
	kDialogData.strCancel = m_strCancelConstructionCancel;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

function OnUpgradeClicked(UIButton kButton)
{		 
	if (GetFacility() != none)
	{
		`HQPRES.UIFacilityUpgrade(GetFacility().GetReference());
		`HQPRES.CAMLookAtRoom(GetRoom(), `HQINTERPTIME);
	}
}

function OnRemoveClicked(UIButton kButton)
{
	local XComGameState_FacilityXCom Facility;
	
	Facility = GetFacility();
	if (Facility != none)
	{
		if (Facility.CanRemove())
		{
			ShowRemoveFacilityDialogue();
		}
		else
		{
			ShowCannotRemoveFacilityDialogue();
		}
	}
}

function ShowRemoveFacilityDialogue()
{
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;
	local XComGameState_FacilityXCom Facility;
	local UICallbackData_StateObjectReference CallbackData;

	Facility = GetFacility();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = Facility.GetMyTemplate().DisplayName;
	
	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strRemoveFacilityTitle;
	kDialogData.strText = `XEXPAND.ExpandString(m_strRemoveFacilityDescription);
	
	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Facility.GetReference();
	kDialogData.xUserData = CallbackData;
	kDialogData.fnCallbackEx = RemoveFacilityDialogueCallback;
	
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericConfirm;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;
	
	Movie.Pres.UIRaiseDialog(kDialogData);
}

function ShowCannotRemoveFacilityDialogue()
{
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;
	local XComGameState_FacilityXCom Facility;
	
	Facility = GetFacility();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = Facility.GetMyTemplate().DisplayName;

	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strCantRemoveFacilityTitle;
	kDialogData.strText = Facility.GetMyTemplate().CantBeRemovedText;
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

function OnStaffClicked(UIButton kButton)
{
	local XComGameState_FacilityXCom Facility;

	Facility = GetFacility();
	if( Facility != none )
	{
		class'UIUtilities_Strategy'.static.SelectFacility(Facility.GetReference());	
	}
	else if (m_bClearing || bUnderConstruction)
	{
		class'UIUtilities_Strategy'.static.SelectRoom(RoomRef);
	}
}

simulated public function CancelConstructionDialogueCallback(Name eAction, UICallbackData xUserData)
{
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameState_HeadquartersXCom XComHQ; 
	local UICallbackData_StateObjectReference CallbackData;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if( eAction == 'eUIAction_Accept' )
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

		FacilityProject = class'UIUtilities_Strategy'.static.GetXComHQ().GetFacilityProject(CallbackData.ObjectRef);

		if(FacilityProject != none)
		{
			XComHQ.CancelFacilityProject(FacilityProject);
		}
		
		class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
		XComHQ.HandlePowerOrStaffingChange();
		`HQPRES.m_kAvengerHUD.UpdateResources();
		UpdateData();
		m_bCanCancelConstruction = false;
		//Updating the navhelp for UIBuildFacilties, if active
		if(Movie.Pres.ScreenStack.GetScreen(class'UIBuildFacilities') != None)
			UIBuildFacilities(Movie.Pres.ScreenStack.GetScreen(class'UIBuildFacilities')).UpdateNavHelp();
	}
}

simulated public function CancelClearRoomDialogueCallback(Name eAction, UICallbackData xUserData)
{
	local XComGameState_HeadquartersProjectClearRoom ClearRoomProject;
	local XComGameState_HeadquartersXCom XComHQ;
	local UICallbackData_StateObjectReference CallbackData;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if (eAction == 'eUIAction_Accept')
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

		ClearRoomProject = class'UIUtilities_Strategy'.static.GetXComHQ().GetClearRoomProject(CallbackData.ObjectRef);

		if (ClearRoomProject != none)
		{
			XComHQ.CancelClearRoomProject(ClearRoomProject);
		}

		XComHQ.HandlePowerOrStaffingChange();
		`HQPRES.m_kAvengerHUD.UpdateResources();
		UpdateData();
		//Updating the navhelp for UIBuildFacilties, if active
		if(Movie.Pres.ScreenStack.GetScreen(class'UIBuildFacilities') != None)
			UIBuildFacilities(Movie.Pres.ScreenStack.GetScreen(class'UIBuildFacilities')).UpdateNavHelp();
	}
}

simulated public function RemoveFacilityDialogueCallback(Name eAction, UICallbackData xUserData)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UICallbackData_StateObjectReference CallbackData;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if (eAction == 'eUIAction_Accept')
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(CallbackData.ObjectRef.ObjectID));
		`GAME.GetGeoscape().m_kBase.m_kCrewMgr.VacateAllCrew(FacilityState.GetRoom().MapIndex);
		FacilityState.RemoveEntity();
		
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Facility_Destroy");

		class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
		XComHQ.HandlePowerOrStaffingChange();
		`HQPRES.m_kAvengerHUD.UpdateResources();
		UpdateData();

		// force avenger rooms to update
		`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
		if(Movie.Pres.ScreenStack.IsInStack(class'UIBuildFacilities'))
		{
			UIBuildFacilities(Movie.Pres.ScreenStack.GetScreen(class'UIBuildFacilities')).UpdateNavHelp();
		}
	}
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	bHandled = true; 
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		if(`HQPRES.m_bCanPause)
		{
			if (class'UIUtilities_Strategy'.static.IsInTutorial(true))
			{
				if(bLocked)
					bHandled = false;
			}
			OnConfirm();
		}
		break;

	default:
		bHandled = false;
		break;
	}
	return bHandled;
}

//This set the alpha on the bulk of the art pieces on a grid item, but leaves the overall
//overlay full alpha, and also leaves the status icons showing. 
simulated function SetBorderAlpha(float NewAlpha)
{
	MC.FunctionNum("setBorderAlpha", NewAlpha);
}

simulated function SetTextBackDropAlpha(float NewAlpha)
{
	MC.FunctionNum("setTextBackDropAlpha", NewAlpha);
}

simulated function UIPanel SetSize(float NewWidth, float NewHeight)
{
	super.SetSize(NewWidth, NewHeight);

	if( bAlignRight ) 
		FacilityIcons.SetPosition(width - FacilityIcons.GetTotalWidth(), height);
	else
		FacilityIcons.SetPosition(5, height);

	//FacilityQueue.SetPosition(5, height - 30);
	
	return self;
}

// --------------------------------------------------------------------------------

function array<EUIStaffIconType> GetStaffIconData(XComGameState_FacilityXCom Facility)
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;
	local array<EUIStaffIconType> NewIcons;

	if( Facility.DisplayStaffingInfo() )
	{
		for( i = 0; i < Facility.StaffSlots.Length; ++i )
		{
			StaffSlot = Facility.GetStaffSlot(i);
			if( !StaffSlot.IsLocked() && !StaffSlot.IsHidden() )
			{
				if( StaffSlot.IsScientistSlot() )
				{
					if( StaffSlot.IsSlotFilled() )
						NewIcons.AddItem(eUIFG_Science);
					else
						NewIcons.AddItem(eUIFG_ScienceEmpty);
				}
				else if( StaffSlot.IsSoldierSlot() )
				{
					if( Facility.GetMyTemplateName() == 'PsiChamber' )
					{
						if( StaffSlot.IsSlotFilled() )
							NewIcons.AddItem(eUIFG_PsiSoldier);
						else
							NewIcons.AddItem(eUIFG_PsiSoldierEmpty);
					}
					else
					{
						if( StaffSlot.IsSlotFilled() )
							NewIcons.AddItem(eUIFG_Soldier);
						else
							NewIcons.AddItem(eUIFG_SoldierEmpty);
					}
				}
				else if( StaffSlot.IsEngineerSlot() )
				{
					if( StaffSlot.IsSlotFilled() )
						NewIcons.AddItem(eUIFG_Engineer);
					else
						NewIcons.AddItem(eUIFG_EngineerEmpty);
				}
				else
				{
					if( StaffSlot.IsSlotFilled() )
						NewIcons.AddItem(eUIFG_GenericStaff);
					else
						NewIcons.AddItem(eUIFG_GenericStaffEmpty);
				}
			}
		}
	}
	return NewIcons;
}

function array<EUIStaffIconType> GetStaffIconDataForClearingSlots()
{
	local int i, numSlotsFilled, numSlotsEmpty;
	local array<EUIStaffIconType> NewIcons;
	local XComGameState_HeadquartersRoom Room;

	Room = GetRoom();

	//------------------------------------------------
	numSlotsFilled = Room.GetNumFilledBuildSlots();
	for( i = 0; i < numSlotsFilled; i++ )
	{
		NewIcons.AddItem(eUIFG_Engineer);
	}
	//------------------------------------------------
	numSlotsEmpty = Room.GetNumEmptyBuildSlots();
	for( i = 0; i < numSlotsEmpty; i++ )
	{
		NewIcons.AddItem(eUIFG_EngineerEmpty);
	}
	//------------------------------------------------
	return NewIcons;
}

function array<EUIStaffIconType> GetStaffIconDataForConstructionSlots()
{
	local array<EUIStaffIconType> NewIcons;

	//DESIGN ASSUMPTION: only ever show one slot for construction 
 
	if( GetRoom().GetNumFilledBuildSlots() > 0 )
		NewIcons.AddItem(eUIFG_Engineer);
	else
		NewIcons.AddItem(eUIFG_EngineerEmpty);

	return NewIcons;
}

// --------------------------------------------------------------------------------
simulated function UIStaffIcon AddStatusIcon(EUIStaffIconType eType = eUIFG_GenericStaff)
{
	local UIStaffIcon Icon;

	Icon = UIStaffIcon(FacilityIcons.CreateItem(class'UIStaffIcon'));
	Icon.InitStaffIcon();
	Icon.SetType(eType);
	Icon.ProcessMouseEvents(OnClickStaffIcon);
	FacilityIcons.OnItemSizeChanged(Icon);

	return Icon;
}

simulated function RefreshStatusIcons(array<EUIStaffIconType> NewIconTypes)
{
	local int i;
	local UIStaffIcon Icon; 

	if( NewIconTypes.Length != IconTypes.Length )
	{
		FacilityIcons.ClearItems();
	}

	IconTypes = NewIconTypes;
	NewIconTypes.length = 0;

	for( i = 0; i < IconTypes.Length; i++ )
	{
		Icon = UIStaffIcon(FacilityIcons.GetItem(i)); 
		if( Icon == none )
			Icon = AddStatusIcon(IconTypes[i]);
		else
		{
			Icon.SetType(IconTypes[i]);
			Icon.SetTooltipText(""); // clear the existing tooltip; it will be filled out again below
		}

		Icon.BuildAssignedStaffTooltip(GetRoom(), i);
	}
}

function OnClickStaffIcon(UIPanel Control, int Cmd)
{
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local UIRoom RoomScreen;
	local UIFacility FacilityScreen; 
	local int IconIndex; 
	
	//We only want clicks here. 
	if( cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP ) return; 

	Room = GetRoom();
	Facility = GetFacility();
	IconIndex = UIPanel(Control.Owner).GetChildIndex(Control);

	if( Facility != none && !bUnderConstruction)
	{		
		class'UIUtilities_Strategy'.static.SelectFacility(Facility.GetReference());
		
		FacilityScreen = UIFacility(Movie.Stack.GetCurrentScreen());
		if(FacilityScreen != none && IconIndex > -1)
		{
			FacilityScreen.ClickStaffSlot(IconIndex);
		}
	}
	else if (Room.HasSpecialFeature() || bUnderConstruction)
	{
		class'UIUtilities_Strategy'.static.SelectRoom(Room.GetReference());

		RoomScreen = UIRoom(Movie.Stack.GetCurrentScreen());
		if (RoomScreen != none && IconIndex > -1)
		{
			RoomScreen.ClickStaffSlot(IconIndex);
		}
	}
}

// --------------------------------------------------------------------------------------
simulated function name GetLibId(StateObjectReference InitRoomRef)
{
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersRoom Room;
	local name TargetLibID; 
	
	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(InitRoomRef.ObjectID));

	// Set Facility Name
	if( Room != none && Room.HasFacility() )
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Room.Facility.ObjectID));
		TargetLibID = Facility.GetMyTemplate().UIFacilityGridID;
	}

	return (TargetLibID == '') ? 'GenericGridHighlight' : TargetLibID;
}

simulated function SetLabel(String NewLabel)
{
	if( Label != NewLabel )
	{
		Label = NewLabel; 

		MC.BeginFunctionOp("setLabel");
		MC.QueueString(Label);
		MC.EndOp();
	}
}

simulated function SetStatus(String NewStatus, String NewQueue)
{
	if( Status != NewStatus || Queue != NewQueue )
	{
		Status = NewStatus;
		Queue = NewQueue;

		MC.BeginFunctionOp("setStatus");
		MC.QueueString(Status);
		MC.QueueString(Queue);
		MC.EndOp();
	}
}

simulated function SetConstruction(bool bIsUnderConstruction)
{
	if( bUnderConstruction != bIsUnderConstruction )
	{
		bUnderConstruction = bIsUnderConstruction;

		MC.BeginFunctionOp("setConstruction");
		MC.QueueBoolean(bUnderConstruction);
		MC.EndOp();
	}
}

simulated function SetClearing(bool bClearing)
{
	if( m_bClearing != bClearing )
	{
		m_bClearing = bClearing;

		MC.BeginFunctionOp("setClearing");
		MC.QueueBoolean(m_bClearing);
		MC.EndOp();
	}
}

simulated function SetLocked(bool bIsLocked)
{
	if (bLocked != bIsLocked)
	{
		bLocked = bIsLocked;

		// TODO: Flash commands here to show lock icon on the grid
	}
}

simulated function SetBGColorState(EUIState ColorState)
{
	local string NewBGColor; 

	NewBGColor = class'UIUtilities_Colors'.static.GetHexColorFromState(ColorState);

	if( BGColor != NewBGColor )
	{
		BGColor = NewBGColor;

		MC.BeginFunctionOp("setBGColor");
		MC.QueueString(BGColor);
		MC.EndOp();
	}
}

simulated function SetHighlighted(bool bHighlight)
{
	if(bIsHighlighted != bHighlight)
	{
		bIsHighlighted = bHighlight;
		if(BGPanel.bIsInited)
			MC.FunctionBool("setHighlighted", bIsHighlighted);
	}
}

simulated function OnBGPanelInited(UIPanel Panel)
{
	MC.FunctionBool("setHighlighted", bIsHighlighted);
	BGPanel.Show();
}

simulated function AlignRight()
{
	bAlignRight = true; 
	MC.FunctionVoid("alignRight");
}

simulated function AlignCenter()
{
	MC.FunctionVoid("alignCenter");
}

// --------------------------------------------------------------------------------------

simulated event Removed()
{
	super.Removed();
	Movie.Pres.m_kTooltipMgr.RemoveTooltips(self);
}

// --------------------------------------------------------------------------------------

defaultproperties
{
	width = 310;
	height = 115;
	bIsNavigable = true;
	bAlignRight = false; 


	BuildModeUnSelectedAlpha = 40;
	BuildModeUnSelectedBackGroundTextAlpha = 85;
	Status = "UNINITIALIZED"
	Queue = "UNINITIALIZED"
	Label = "UNINITIALIZED"
	bUnderConstruction = false
}