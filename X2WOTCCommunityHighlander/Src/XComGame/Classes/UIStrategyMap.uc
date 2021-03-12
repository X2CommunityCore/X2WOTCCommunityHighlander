//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMap
//  AUTHOR:  Sam Batista
//  PURPOSE: Screen responsible for managing 2D UI components in the StrategyMap:
//
//           UIStrategyMap_HUD
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMap extends UIX2SimpleScreen
	dependson(UINavigationHelp, UIStrategyMap_MissionIcon);

const MAX_NUM_STRATEGYICONS = 20;

enum EStrategyMapState
{
	eSMS_Default,
	eSMS_Resistance,
	eSMS_Flight,
};

struct TStrategyMapMissionItemUI
{
	var array<UIStrategyMap_MissionIcon> MissionIcons;
	var array<XComGameState_ScanningSite> ScanSites;
	var array<XComGameState_MissionSite> Missions;
};

var UIPanel ItemContainer;
var XComStrategyMap XComMap;

var UIStrategyMap_HUD StrategyMapHUD;
var UINavigationHelp NavBar;

var EStrategyMapState m_eUIState;

//var UIButton FlightButton;
//var UIButton OutpostButton;
//var UIButton ContactButton;
var TStrategyMapMissionItemUI MissionItemUI;

var UIButton DarkEventsButton; 
var UIPanel DarkEventsContainer;
var UIPanel LeftGreeble;
var UIPanel RightGreeble;
var UIPanel CenteredNavHelp;

var localized string m_strStartTime;
var localized string m_strStopTime;
var localized string m_strScanDisabled;
var localized string m_strDarkEventsLabel;
var localized string m_strToggleResNet;
var localized string m_srResistanceOrders;
var localized string m_srChosenInfo;
var localized string m_ResHQLabel;
var localized string m_MissionsLabel;
var localized string m_ScanSiteLabel;
var localized string m_strStartScan;
var localized string m_strMoveToSite;
var localized string m_strSelectSite;
var localized string m_strScanSite;
var localized string m_strLookAtAvenger;
var localized string m_strZoomIn;
var localized string m_strZoomOut;

var UIStrategyMapItem SelectedMapItem;
var UIStrategyMapItem LastSelectedMapItem;

var UIGamepadIcons LeftBumperIcon;
var UIGamepadIcons RightBumperIcon;

var UITextTooltip ActiveTooltip;
var float SelectionRadius;
var X2FadingStaticMeshComponent CursorMesh;
var float CursorMeshOpacity;
var float TargetCursorMeshOpacity;
var bool bCursorAlwaysVisible;
var bool bMoveViewLocation;
var bool bSelectNearest;

var float CrosshairAlpha;
var float TargetCrosshairAlpha;

var UIPanel Crosshair;
var Vector2D PreviousViewDelta;

var float ZoomSpeed;
var bool m_bResNetForcedOn;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState_HeadquartersResistance ResHQ; //bsg-crobinson (5.23.17): Add ref to the resistance hq

	super.InitScreen(InitController, InitMovie, InitName);	

	XComMap = XComHQPresentationLayer(Movie.Pres).m_kXComStrategyMap;
	if(XComMap != none)
	{
		XComMap.UIMapZoom = 0;
	}
	
	ItemContainer = Spawn(class'UIPanel', self).InitPanel(, 'StrategyMapContainer');


	NavBar = XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp;
	StrategyMapHUD = Spawn(class'UIStrategyMap_HUD', self).InitStrategyMapHUD();

	/*OutpostButton = Spawn(class'UIButton', self).InitButton(InitName, class'UIUtilities_Text'.static.GetSizedText("BUILD OUTPOST", 25), OnBuildOutpostClicked, eUIButtonStyle_HOTLINK_BUTTON);
	OutpostButton.SetPosition(0, 0);
	OutpostButton.Hide();

	ContactButton = Spawn(class'UIButton', self).InitButton(InitName, class'UIUtilities_Text'.static.GetSizedText("MAKE CONTACT", 25), OnMakeContactClicked, eUIButtonStyle_HOTLINK_BUTTON);
	ContactButton.SetPosition(0, 0);
	ContactButton.Hide();*/

	InitMissionIcons();

	if( `ISCONTROLLERACTIVE )
	{
		SpawnNavHelpIcons();

		CursorMesh.SetStaticMesh(
			StaticMesh(DynamicLoadObject("XB0_XCOM2_OverworldIcons.IconSelection", class'StaticMesh')));

	}
	else
	{
		CursorMesh.SetStaticMeshes(
			StaticMesh(DynamicLoadObject("UI_3D.CursorSet.S_MovePuckCircle_Dashing", class'StaticMesh')), 
			StaticMesh(DynamicLoadObject("UI_3D.CursorSet.S_MovePuck_Confirm", class'StaticMesh')));
	}

	if (Crosshair == none && `ISCONTROLLERACTIVE)
	{
		Crosshair = Spawn(class'UIPanel', self);
		Crosshair.InitPanel('Crosshair', 'crosshair2');
		Crosshair.CenterOnScreen();
		Crosshair.SetPanelScale(0.28);
		Crosshair.SetColor("9acbcb");
		Crosshair.SetAlpha(0.8);
	}
	
	UpdateButtonHelp();
	UpdatePopSupportAndAlert();
	UpdateMissions();
	UpdateDarkEvents();

	//We're being explicit here, because the screen will initialize and select whatever is first available, 
	//which gets weird pins selected unexpectedly. 
	if (MissionItemUI.MissionIcons.Length > 0) 
	{
		Navigator.SetSelected(MissionItemUI.MissionIcons[0]);
	}
	else
	{
		Navigator.SetSelected(StrategyMapHUD);
	}
	
	Navigator.HorizontalNavigation = true;
	Navigator.LoopSelection = true;
	Navigator.OnSelectedIndexChanged = OnNavigationChanged;

	OnNavigationChanged(0);
	
	if (!bCursorAlwaysVisible)
	{
		SelectionRadius = 0.031;
	}
	
	//This is always supposed to be active if we're entering this screen.
	//`GAME.GetGeoscape().Resume();

	StrategyMapHUD.mc.BeginFunctionOp("SetMissionTrayLabels");

	//bsg-crobinson (5.23.17): If the player has met a faction show string, else: don't
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();

	if (ResHQ.HaveMetAnyFactions())
	{
		StrategyMapHUD.mc.QueueString(m_ResHQLabel);
	}
	else
	{
		StrategyMapHUD.mc.QueueString("");
	}
	//bsg-crobinson (5.23.17): end

	StrategyMapHUD.mc.QueueString(m_MissionsLabel);
	StrategyMapHUD.mc.QueueString(m_ScanSiteLabel);
	StrategyMapHUD.mc.EndOp();

	Movie.Pres.m_kEventNotices.Activate();
}

simulated function SetUIState(EStrategyMapState eNewUIState)
{
	local bool bToggleFlight;
	if( eNewUIState == eSMS_Resistance && !XCOMHQ().IsContactResearched() )
	{
		return;
	}

	if( m_bResNetForcedOn && eNewUIState != eSMS_Flight )
	{
		return;
	}

	bToggleFlight = false;
	
	if( m_eUIState != eNewUIState )
	{
		bToggleFlight = (m_eUIState == eSMS_Flight || eNewUIState == eSMS_Flight);
		m_eUIState = eNewUIState;

		if(bToggleFlight)
		{
			m_bResNetForcedOn = false; // If the resnet was forced on, turn it off when going into Flight Mode
			OnFlightModeToggled();
		}

		XComMap.UpdateVisuals();
		UpdateRegionPins();
	}
	if (eNewUIState == eSMS_Flight)
	{
		TargetCursorMeshOpacity = 0.0;
		TargetCrosshairAlpha = 0.0;
	}
}

simulated function OnFlightModeToggled()
{
	if (bIsFocused)
	{
		UpdateButtonHelp();
		UpdateDarkEvents();
		UpdateToDoWidget();
		UpdateResourceBar();
		UpdateObjectiveList();

		if (m_eUIState == eSMS_Flight)
		{
			HideMissionButtons();
			TargetCursorMeshOpacity = 0.0;
			TargetCrosshairAlpha =  0.0;
			HideTooltip();
			bMoveViewLocation = false;
			bSelectNearest = false;
		}
		else
		{
			UpdateMissions();
			TargetCursorMeshOpacity = 1.0;
			TargetCrosshairAlpha = 1.0;
			bMoveViewLocation = true;
			bSelectNearest = true;
		}
	}
	if (m_eUIState == eSMS_Flight)
	{
		TargetCursorMeshOpacity = 0.0;
		TargetCrosshairAlpha =  0.0;
	}

	// Issue #358
	`XEVENTMGR.TriggerEvent('GeoscapeFlightModeUpdate', self, self, none);
}

simulated function UpdateObjectiveList()
{
	local XComHQPresentationLayer PresLayer;
	PresLayer = XComHQPresentationLayer(Movie.Pres);

	if(!class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress())
	{
		if(m_eUIState == eSMS_Flight)
		{
			PresLayer.m_kAvengerHUD.Objectives.Hide();
		}
		else
		{
			PresLayer.m_kAvengerHUD.Objectives.Show();
		}
	}
}

simulated function UpdateResourceBar()
{
	local XComHQPresentationLayer PresLayer;
	PresLayer = XComHQPresentationLayer(Movie.Pres);

	if(m_eUIState == eSMS_Flight)
	{
		PresLayer.m_kAvengerHUD.HideResources();
	}
	else
	{
		PresLayer.m_kAvengerHUD.ShowResources();
	}
}

simulated function UpdateToDoWidget()
{
	local XComHQPresentationLayer PresLayer;
	PresLayer = XComHQPresentationLayer(Movie.Pres);

	if(m_eUIState == eSMS_Flight)
	{
		PresLayer.m_kAvengerHUD.ToDoWidget.Hide();
	}
	else
	{
		if( `ISCONTROLLERACTIVE == false )
			PresLayer.m_kAvengerHUD.ToDoWidget.Show();
	}
}

simulated function SelectMapItemNearestLocation(vector2D Loc)
{
	local int i;
	local vector ItemDirection;
	local float Distance;
	local float ShortestDistance;
	local XComGameState_GeoscapeEntity GeoscapeEntity;
	local UIStrategyMapItem ConsiderMapItem;
	local array<UIStrategyMapItem> SelectableMapItems;
	local UIStrategyMapItem NewSelection;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', GeoscapeEntity)
	{
		if (GeoscapeEntity.ShouldBeVisible())
		{
			ConsiderMapItem = UIStrategyMapItem(History.GetVisualizer(GeoscapeEntity.ObjectID));
			if (ConsiderMapItem.IsSelectable() || UIStrategyMapItem_Continent(ConsiderMapItem) != none)
			{
				SelectableMapItems.AddItem(ConsiderMapItem);
			}
		}
	}

	ShortestDistance = SelectionRadius * `EARTH.GetCurrentZoomLevel();
	for (i = 0; i < SelectableMapItems.Length; i++)
	{
		ItemDirection.X = SelectableMapItems[i].Cached2DWorldLocation.X - Loc.X;
		ItemDirection.Y = SelectableMapItems[i].Cached2DWorldLocation.Y - Loc.Y;
		ItemDirection.Y /= 1.8;

		Distance = VSize(ItemDirection);
		if (ShortestDistance > Distance)
		{
			NewSelection = SelectableMapItems[i];
			ShortestDistance = Distance;
		}
	}

	if (SelectedMapItem != NewSelection)
	{
		if (UIStrategyMapItem_Continent(NewSelection) != none)
		{
			SelectedMapItem = NewSelection;
			if (ActiveTooltip == none || ActiveTooltip.ID != SelectedMapItem.CachedTooltipId)
			{
				HideTooltip();
				ShowTooltip(SelectedMapItem);
			}

			if (!bCursorAlwaysVisible)
			{
				TargetCursorMeshOpacity = 0.0;
				CursorMeshOpacity = 0.0;
				CursorMesh.SetOpacity(0.0);
			}

			return;
		}

		SetSelectedMapItem(NewSelection);
	}
}

simulated function SetSelectedMapItem(UIStrategyMapItem Selection, optional bool NavigationSelect = false)
{	
	local int i;

	if (SelectedMapItem != none)
	{
		SelectedMapItem.OnMouseOut();
		SelectedMapItem.OnLoseFocus();
	}

	HideTooltip();
		
	SelectedMapItem = Selection;
	UpdateButtonHelp();

	if (SelectedMapItem != none)
	{
		SelectedMapItem.Show();
		SelectedMapItem.UpdateVisuals(true);

		SelectedMapItem.OnReceiveFocus();
		SelectedMapItem.OnMouseIn();

		ShowTooltip(SelectedMapItem);

		if (!bCursorAlwaysVisible)
		{
			TargetCursorMeshOpacity = 1.0;
		}
		TargetCrosshairAlpha = 0.0;
	}
	else
	{
		if (!bCursorAlwaysVisible)
		{
			TargetCursorMeshOpacity = 0.0;
		}
		TargetCrosshairAlpha = 1.0;
	}

	if (NavigationSelect)
	{
		return;
	}

	Navigator.OnLoseFocus();
	Navigator.SetSelected();

	if (SelectedMapItem != none)
	{
		for (i = 0; i < MAX_NUM_STRATEGYICONS; i++)
		{
			MissionItemUI.MissionIcons[i].bMoveCamera = NavigationSelect;
			MissionItemUI.MissionIcons[i].OnLoseFocus();

			if ((MissionItemUI.MissionIcons[i].ScanSite != none &&
				MissionItemUI.MissionIcons[i].ScanSite.ObjectID == SelectedMapItem.GeoscapeEntityRef.ObjectID) ||
				(MissionItemUI.MissionIcons[i].MissionSite != none && 
				MissionItemUI.MissionIcons[i].MissionSite.ObjectID == SelectedMapItem.GeoscapeEntityRef.ObjectID))
			{
				Navigator.SetSelected(MissionItemUI.MissionIcons[i]);
			}

			MissionItemUI.MissionIcons[i].bMoveCamera = false;
		}
	}

	UpdateButtonHelp();
}

simulated function OnNavigationChanged(int NewIndex)
{
	local UIStrategyMapItem MapItem;
	local int i;
	
	MapItem = UIStrategyMap_MissionIcon(Navigator.GetControl(NewIndex)).MapItem;
	if (MapItem != none)
	{
		for (i = 0; i < MAX_NUM_STRATEGYICONS; i++)
		{
			MissionItemUI.MissionIcons[i].bMoveCamera = false;
			MissionItemUI.MissionIcons[i].OnLoseFocus();

			if ((MissionItemUI.MissionIcons[i].ScanSite != none &&
				MissionItemUI.MissionIcons[i].ScanSite.ObjectID == MapItem.GeoscapeEntityRef.ObjectID) &&
				(MissionItemUI.MissionIcons[i].ScanSite.CanBeScanned() || UIStrategyMapItem_BlackMarket(MapItem) != none) || //bsg-jneal (5.19.17): do not try to switch to targets if they are not currently scannable, fixes stuttering issue on gamepad bumper navigation
				(MissionItemUI.MissionIcons[i].MissionSite != none && 
				MissionItemUI.MissionIcons[i].MissionSite.ObjectID == MapItem.GeoscapeEntityRef.ObjectID))
			{
				MissionItemUI.MissionIcons[i].bMoveCamera = true;
				MissionItemUI.MissionIcons[i].OnReceiveFocus();
				SetSelectedMapItem(MapItem, true);
			}

			MissionItemUI.MissionIcons[i].bMoveCamera = false;
		}
	}
}

simulated function HideCursor()
{
	if (!bCursorAlwaysVisible)
	{
		TargetCursorMeshOpacity = 0.0;
		CursorMeshOpacity = 0.0;
		CursorMesh.SetOpacity(0.0);
	}
}

simulated function ShowCursor()
{
	if (!bCursorAlwaysVisible)
	{
		if (m_eUIState != eSMS_Flight)
		{
			TargetCursorMeshOpacity = 1.0;
		}
	}
}

simulated function UpdateRegionPins()
{
	local UIStrategyMapItem_Region Pin;
	local XComGameState_WorldRegion Region;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', Region)
	{
		Pin = UIStrategyMapItem_Region(GetMapItem(Region));
		if( Pin != none )
		{
			Pin.UpdateFlyoverText();
		}
	}
}

simulated function UIStrategyMapItem GetMapItem(XComGameState_GeoscapeEntity Entity, optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local UIStrategyMapItem MapItem;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Continent ContinentState;
	local bool bAllContinentRegionsUpdated;
	local bool bLocalSubmission;
	
	if (Entity.GetUIClass() == none) // no UI, nothing to position
		return none;

	MapItem = UIStrategyMapItem(Entity.GetVisualizer());
	if (MapItem != none)
	{
		return MapItem;
	}
		
	MapItem = Spawn(Entity.GetUIClass(), ItemContainer).InitMapItem(Entity);
	History = `XCOMHISTORY;
	History.SetVisualizer(Entity.ObjectID, MapItem);
		
	if (NewGameState == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entity Locations Updated");
		bLocalSubmission = true;
	}

	// This function ensures that all World Regions have their meshes generated before anything else gets to update its location,
	// so other entities can be properly aware of region locations and avoid them for placement if necessary (Ex: Faction HQs, Chosen)
	// If the Region has been generated previously, the new entity will update its location
	// Otherwise, when the Region is generated, it will update all of the entities inside it, and then check and update any entities
	// on its continent, if all of the other regions on the continent have also been generated
	
	// First check if this Entity is a Region, which would have just had its MapItem initialized for the first time
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(Entity.ObjectID));
	if (RegionState != none)
	{
		// Check the continent to see if all of the region meshes in it have been generated
		ContinentState = RegionState.GetContinent();
		if (ContinentState != none)
		{
			bAllContinentRegionsUpdated = ContinentState.AreAllRegionLocationsUpdated();
		}

		// This region exists and its mesh has been generated, so we can update location of all entities in the region
		foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', Entity)
		{
			if (Entity.bNeedsLocationUpdate)
			{
				if (Entity.Region.ObjectID != 0 && Entity.Region.ObjectID == RegionState.ObjectID)
				{
					Entity = XComGameState_GeoscapeEntity(NewGameState.ModifyStateObject(Entity.Class, Entity.ObjectID));
					Entity.Location = RegionState.GetRandomLocationInRegion(, , Entity);
					Entity.HandleUpdateLocation();
					Entity.bNeedsLocationUpdate = false;
				}
				else if (bAllContinentRegionsUpdated && Entity.Continent.ObjectID != 0 && Entity.Continent.ObjectID == ContinentState.ObjectID)
				{						
					Entity = XComGameState_GeoscapeEntity(NewGameState.ModifyStateObject(Entity.Class, Entity.ObjectID));
					Entity.Location = ContinentState.GetRandomLocationInContinent(, Entity);
					Entity.HandleUpdateLocation();
					Entity.bNeedsLocationUpdate = false;
				}
			}
		}
	}
	else if (Entity.bNeedsLocationUpdate) // This entity is not a Region
	{
		// Update location if flagged to do so (for game start objects created before region mesh generation)
		UpdateGeoscapeEntityLocation(Entity, NewGameState);
	}

	if (bLocalSubmission)
	{
		if (NewGameState.GetNumGameStateObjects() > 0)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}
	
	return MapItem;
}

simulated function UpdateGeoscapeEntityLocation(XComGameState_GeoscapeEntity Entity, XComGameState NewGameState)
{
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Continent ContinentState;
	local UIStrategyMapItem MapItem;
	
	// First check to see if this entity has a region, and if that region's mesh has been generated
	RegionState = Entity.GetWorldRegion();
	if (RegionState != none)
	{
		// If the mesh was not generated, the entities location will be updated when the region mesh is
		MapItem = UIStrategyMapItem(RegionState.GetVisualizer());
		if (MapItem != none)
		{
			// The region mesh location has been updated, so we can safely grab a random location
			Entity = XComGameState_GeoscapeEntity(NewGameState.ModifyStateObject(Entity.Class, Entity.ObjectID));
			Entity.Location = RegionState.GetRandomLocationInRegion(, , Entity);
			Entity.HandleUpdateLocation();
			Entity.bNeedsLocationUpdate = false;
		}
	}
	else
	{
		// No region found for this entity, so look for a Continent instead and check if it's region's meshes have been generated
		ContinentState = Entity.GetContinent();
		if (ContinentState != none && ContinentState.AreAllRegionLocationsUpdated())
		{
			// Meshes are all generated and updated, so we can safely grab a random location in the continent
			Entity = XComGameState_GeoscapeEntity(NewGameState.ModifyStateObject(Entity.Class, Entity.ObjectID));
			Entity.Location = ContinentState.GetRandomLocationInContinent(, Entity);
			Entity.HandleUpdateLocation();
			Entity.bNeedsLocationUpdate = false;
		}
	}
}

simulated function bool IsInFlightMode()
{
	return (m_eUIState == eSMS_Flight);
}

simulated function UpdateButtonHelp()
{
	local int enumval;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;

	NavBar.ClearButtonHelp();
	NavBar.bIsVerticalHelp = `ISCONTROLLERACTIVE; 
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(m_eUIState != eSMS_Flight)
	{
		// can only back out if the avenger is landed
		NavBar.AddBackButton(CloseScreen);

		if( `ISCONTROLLERACTIVE )
		{
			NavBar.AddLeftHelp(m_strLookAtAvenger, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RSCLICK_R3);

			//bsg-hlee (05.16.17): Changing to new button. Also moving to pair up with R3 in nav help list.
			if (AlienHQ.HaveMetAnyChosen())//bsg-crobinson (5.8.17): Add X help when chosen have been revealed
				NavBar.AddLeftHelp(m_srChosenInfo, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
			//bsg-hlee (05.16.17): End


			if (XCOMHQ.IsContactResearched())
			{
				if (!Movie.IsMouseActive())
				{
					NavBar.AddLeftHelp(m_strToggleResNet, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_BACK_SELECT);
				}
			}
		}
		else
		{
			if( XCOMHQ.IsContactResearched() )
			{
				enumval = eButtonIconPC_Land;
				NavBar.SetButtonType("XComButtonIconPC");
				NavBar.AddLeftHelp(string(enumval), string(enumval), OnResNetClicked, false, m_strToggleResNet);
				NavBar.SetButtonType("");
			}
		}
	}

	// Start Issue #932
	/// HL-Docs: feature:StrategyMap_NavHelpUpdated; issue:932;tags:strategy,ui
	/// This event is fired after the base game has performed its own updates to
	/// the nav help on the Geoscape (StrategyMap), allowing mods to make further
	/// changes if they wish.
	/// ```event
	/// EventID: StrategyMap_NavHelpUpdated,
	/// EventData: UINavigationHelp,
	/// EventSource: UIStrategyMap (StrategyMap),
	/// NewGameState: none
	/// ```
	// This event is modeled on the 'UIArmory_WeaponUpgrade_NavHelpUpdated' event.
	`XEVENTMGR.TriggerEvent('StrategyMap_NavHelpUpdated', NavBar, self);
	// End Issue #932
}

simulated function UpdateCenteredNavHelp()
{
	local int i, bgPadding, containerMargin, lineHeight, helpCount;
	local bool bAdvanceTime, bCanScan;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIButton Button;
	local UIPanel NavHelpBG;

	//These are local constants only used in this funtion
	containerMargin = 70;
	bgPadding = 8;
	lineHeight = 25;

	//Initializes the container and the background if this is the first time this function is being called
	if(CenteredNavHelp == None)
	{
		//adding centered nav help container (mostly for positioning and scaling)
		CenteredNavHelp = Spawn(class'UIPanel',Self);
		CenteredNavHelp.InitPanel();
		CenteredNavHelp.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
		CenteredNavHelp.SetPanelScale(1.3);
		CenteredNavHelp.SetY(-210);
		CenteredNavHelp.SetX(-containerMargin);

		//adding the background asset
		NavHelpBG = Spawn(class'UIPanel',CenteredNavHelp);
		NavHelpBG.InitPanel('bg','GradientHorizonalBlack');
		NavHelpBG.SetWidth(256);
		NavHelpBG.SetX(containerMargin);
		NavHelpBG.SetAlpha(0.5f);

		//adding the nav help children (INCREASE IF A HIGHER CAP IS NEEDED)
		for(i=0; i<3; i++)
		{
			Button = Spawn(class'UIButton', CenteredNavHelp);
			Button.InitButton(name("navHelp" $ i),,, eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE).SetY(-i * lineHeight);
			Button.OnSizeRealized = OnCenterButtonSizeRealized;
		}
	}

	History = `XCOMHISTORY;
	bAdvanceTime = `GAME.GetGeoscape().IsScanning();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	bCanScan = XComHQ.IsScanningAllowedAtCurrentLocation();

	if (m_eUIState != eSMS_Flight)
	{
		if (SelectedMapItem != none)
		{
			if (bCanScan && 
				XComGameState_ScanningSite(History.GetGameStateForObjectID(SelectedMapItem.GeoscapeEntityRef.ObjectID)) == 
				XComHQ.GetCurrentScanningSite())
			{
				if (!bAdvanceTime)
				{
					AddCenterNavHelp(helpCount, m_strScanSite, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
				}
				else
				{
					AddCenterNavHelp(helpCount, m_strStopTime, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
				}

				//if (XComGameState_Haven(History.GetGameStateForObjectID(SelectedMapItem.GeoscapeEntityRef.ObjectID)) != none &&
				//	XComGameState_Haven(History.GetGameStateForObjectID(SelectedMapItem.GeoscapeEntityRef.ObjectID)).HasResistanceGoods())
				//{
				//	AddCenterNavHelp(helpCount, m_strSelectSite, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
				//}
			}
			else
			{
				AddCenterNavHelp(helpCount, m_strMoveToSite, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
			}
		}
	}

	for(i=0; i<CenteredNavHelp.ChildPanels.Length; i++)
	{
		if(CenteredNavHelp.ChildPanels[i] != None && CenteredNavHelp.ChildPanels[i].MCName != 'bg')
		{
			CenteredNavHelp.ChildPanels[i].SetVisible(i <= helpCount);
		}
	}

	//resizes the background to match the number of help options
	NavHelpBG = CenteredNavHelp.GetChildByName('bg');
	if(NavHelpBG != None)
	{
		NavHelpBG.SetHeight(helpCount*lineHeight + bgPadding*2); //will hide the background completely if there are no navhelp buttons
		NavHelpBG.SetY(lineHeight-NavHelpBG.Height + bgPadding);
		NavHelpBG.SetVisible(helpCount > 0);
	}	
}

simulated function OnCenterButtonSizeRealized()
{
	local int i;
	local UIButton Button;
	
	for (i = 0; i< CenteredNavHelp.ChildPanels.Length; i++)
	{
		Button = UIButton(CenteredNavHelp.ChildPanels[i]);
		if (Button != none)
		{
			Button.SetX(-Button.Width / 2.0);
		}
	}
}
simulated function AddCenterNavHelp(out int Index, String NewLabel, String NewIcon)
{
	local UIButton NewBttn;

	if(CenteredNavHelp != None && CenteredNavHelp.ChildPanels.Length > Index + 1) // +1 index accounts for the bg
	{
		NewBttn = UIButton(CenteredNavHelp.GetChildByName(name("navHelp" $ Index)));
		if(NewBttn != None)
		{
			NewBttn.SetText(NewLabel);
			NewBttn.SetGamepadIcon(NewIcon);
			Index++;
		}
	}
}

simulated function UpdatePopSupportAndAlert(optional StateObjectReference ContinentRef)
{
	local array<int> PopularSupportBlocks, AlertBlocks, ThresholdIndicies;
	local XComGameStateHistory History;
	local XComGameState_Continent ContinentState;
	local XComGameState_StrategyCard ContinentBonusCard;

	History = `XCOMHISTORY;

	if(bIsVisible)
	{
		if(ContinentRef.ObjectID > 0)
			ContinentState = XComGameState_Continent(History.GetGameStateForObjectID(ContinentRef.ObjectID));
		else
			ContinentState = XComGameState_Continent(History.GetGameStateForObjectID(`XCOMHQ.Continent.ObjectID));

		if(ContinentState != none)
		{
			// PopularSupport Data
			ThresholdIndicies[0] = ContinentState.GetMaxResistanceLevel();

			PopularSupportBlocks = class'UIUtilities_Strategy'.static.GetMeterBlockTypes(ContinentState.GetMaxResistanceLevel(), ContinentState.GetResistanceLevel(),
																						 0,
																						 ThresholdIndicies);

			ContinentBonusCard = ContinentState.GetContinentBonusCard();
			StrategyMapHUD.UpdateSupportTooltip(0, ContinentBonusCard.GetDisplayName(), ContinentBonusCard.GetSummaryText(), 
												ThresholdIndicies[0] <= ContinentState.GetMaxResistanceLevel());

			// Alert Data
			AlertBlocks.Length = 0;
		}

		StrategyMapHUD.UpdatePopularSupportMeter(PopularSupportBlocks);
		StrategyMapHUD.UpdateAlertMeter(AlertBlocks);
	}
}


simulated function ClearScanSites()
{
	MissionItemUI.ScanSites.Remove(0, MissionItemUI.ScanSites.Length);
}

simulated function ClearDarkEvents()
{
	if( DarkEventsContainer != none )
	{
		DarkEventsContainer.Hide();
		DarkEventsContainer.Destroy();
	}
	
	DarkEventsContainer	= none;
}

simulated function HideDarkEventsButton()
{
	if( DarkEventsContainer != none )
	{
		DarkEventsContainer.Hide();
	}
}

simulated function bool ShowDarkEventsButton()
{
	local XComHeadquartersCheatManager CheatMgr;
	local bool bInResistanceReport;
	local UIScreenStack ScreenStack;

	if(m_eUIState == eSMS_Flight)
	{
		return false;
	}

	CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);

	if(CheatMgr != none && CheatMgr.bGamesComDemo)
	{
		return false;
	}

	ScreenStack = `HQPRES.ScreenStack;
	bInResistanceReport = (ScreenStack.IsInStack(class'UIResistanceReport') || ScreenStack.IsInStack(class'UIResistanceReport_ChosenEvents') ||
						   ScreenStack.IsInStack(class'UIAdventOperations') || ScreenStack.IsInStack(class'UIStrategyPolicy') ||
						   ScreenStack.IsInStack(class'UIInventory_LootRecovered') );

	return (!bInResistanceReport && (ALIENHQ().ChosenDarkEvents.Length > 0 || ALIENHQ().ActiveDarkEvents.Length > 0 || ALIENHQ().bHasSeenDarkEvents));
}

simulated function UpdateDarkEvents()
{
	ClearDarkEvents();

	if(ShowDarkEventsButton())
	{
		AddDarkEventsButton();
	}
}

simulated function AddDarkEventsButton()
{
	//Tie the doom button to the doom display, which will anchor and look tidy automatically.
	if( DarkEventsContainer == none )
	{
		DarkEventsContainer = Spawn(class'UIPanel', self).InitPanel();
		DarkEventsContainer.AnchorTopCenter();
		DarkEventsContainer.bAnimateOnInit = false;
		DarkEventsContainer.Hide();
		
		LeftGreeble = Spawn(class'UIPanel', DarkEventsContainer);
		LeftGreeble.InitPanel(, 'leftDoomGreeble').SetPosition(-5, 5); //flash visuals
		RightGreeble = Spawn(class'UIPanel', DarkEventsContainer);
		RightGreeble.InitPanel(, 'rightDoomGreeble').SetY(5);

		DarkEventsButton = Spawn(class'UIButton', DarkEventsContainer);
		DarkEventsButton.LibID = 'X2DarkEventsButton'; 
		DarkEventsButton.bAnimateOnInit = false;
		DarkEventsButton.InitButton();
		DarkEventsButton.SetColor(class'UIUtilities_Colors'.const.BAD_HTML_COLOR); // specially overwritten to handle the text specifically. 
		DarkEventsButton.ProcessMouseEvents( OnDarkEventsClicked );
		DarkEventsButton.OnSizeRealized = OnDarkEventsButtonSizeRealized;
		if( `ISCONTROLLERACTIVE )
		{
			DarkEventsButton.SetHeight(45);
			DarkEventsButton.SetText(class'UIUtilities_Text'.static.InjectImage(
				class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, 26, 26, -10) @ 
				class'UIUtilities_Text'.static.GetSizedText(m_strDarkEventsLabel, 21));
		}
		else
		{
			DarkEventsButton.SetText(m_strDarkEventsLabel);
		}
		DarkEventsContainer.DisableNavigation();
		DarkEventsButton.DisableNavigation();
	}
	else
	{
		OnDarkEventsButtonSizeRealized();
	}
}

simulated function OnDarkEventsButtonSizeRealized()
{
	if (DarkEventsContainer == none)
		return;

	DarkEventsContainer.Hide();

	if( class'UIUtilities_Strategy'.static.GetAlienHQ().AtMaxDoom() )
		DarkEventsContainer.SetY(112); //relative, beneath the Doom Counter. 
	else if( class'UIUtilities_Strategy'.static.GetAlienHQ().GetCurrentDoom() > 0 || class'UIUtilities_Strategy'.static.GetAlienHQ().bHasSeenDoomMeter)
		DarkEventsContainer.SetY(76); //relative, beneath the Doom Bar. 
	else 
		DarkEventsContainer.SetY(0); //relative, beneath the Doom Bar. 

	DarkEventsContainer.SetX(-0.5 * DarkEventsButton.Width);
	RightGreeble.SetX(DarkEventsButton.Width + 5);
	DarkEventsContainer.Show();

	StrategyMapHUD.MC.BeginFunctionOp("RefreshInfoButtons");
	StrategyMapHUD.MC.QueueBoolean(true);
	StrategyMapHUD.MC.QueueNumber( DarkEventsButton.Width );
	StrategyMapHUD.MC.EndOp();
}

simulated function OnDarkEventsClicked(UIPanel Panel, int Cmd)
{
	if( Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
	{
		`GAME.GetGeoscape().Pause();
		HQPRES().UIAdventOperations(false);
	}
}

simulated function ClearMissions()
{
	MissionItemUI.Missions.Remove(0, MissionItemUI.Missions.Length);
}


simulated function OnBuildOutpostClicked(UIButton Button)
{
	HQPRES().UIBuildOutpost(XCOMHQ().GetWorldRegion());
}

simulated function OnMakeContactClicked(UIButton Button)
{
	HQPRES().UIMakeContact(XCOMHQ().GetWorldRegion());
}

simulated function OnResNetClicked()
{
	if( m_bResNetForcedOn )
	{
		m_bResNetForcedOn = false;	// Ordering of these statements matters
		SetUIState(eSMS_Default);
	}
	else
	{
		SetUIState(eSMS_Resistance);
		m_bResNetForcedOn = true;
	}
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

simulated function OnChosenInfoClicked()
{
	local XComGameState_HeadquartersAlien AlienHQ;

	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if( AlienHQ != none && AlienHQ.HaveMetAnyChosen() )
		HQPRES().UIChosenInformation(); //bsg-crobinson(5.8.17): Show the screen if we've seen the chosen
}

simulated function HideMissionButtons()
{
	local int i;
	
	i = 0;

	while(i < MAX_NUM_STRATEGYICONS)
	{
		MissionItemUI.MissionIcons[i].Hide();
		i++;
	}

	StrategyMapHUD.mc.BeginFunctionOp("AnimateMissionTrayOut");
	StrategyMapHUD.mc.EndOp();
	
	if (LeftBumperIcon != none) LeftBumperIcon.Hide();
	if (RightBumperIcon != none) RightBumperIcon.Hide();
}

simulated function UpdateMissions()
{
	local array<XComGameState_ScanningSite> arrScanSites;
	local XComGameState_ScanningSite ScanSite;
	local XComGameState_MissionSite MissionSite;
	local XComGameState_Haven FactionHQ;
	local int i, numScanSites, numMissions, numHQ;
	local XComGameStateHistory History;
	local bool bGuerillaAdded;

	ClearMissions();
	ClearScanSites();

	if(m_eUIState == eSMS_Flight)
	{
		return;
	}
	numHQ = 0;
	numScanSites = 0;
	
	History = `XCOMHISTORY;
	StrategyMapHUD.mc.BeginFunctionOp("AnimateMissionTrayIn");
	StrategyMapHUD.mc.EndOp();

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionSite)
	{
		// Is this mission active
		if( MissionSite.Available )
		{
			if( MissionSite.Source == 'MissionSource_GuerillaOp')
			{
				if( !bGuerillaAdded )
				{
					// Don't add multiple Guerrilla Op missions
					MissionItemUI.Missions.AddItem(MissionSite);
					bGuerillaAdded = true;
				}
			}
			else if(MissionSite.Source == 'MissionSource_Final')
			{
				if(!MissionSite.bNotAtThreshold)
				{
					MissionItemUI.Missions.AddItem(MissionSite);
				}
			}
			else
			{
				MissionItemUI.Missions.AddItem(MissionSite);
			}
		}	
	}

	// Apply sorting to missions
	MissionItemUI.Missions.Sort(SortMissionsUnlocked);
	MissionItemUI.Missions.Sort(SortMissionsType);
	
	arrScanSites = XCOMHQ().GetAvailableScanningSites();
	arrScanSites.Sort(SortScanSitesType);

	if( arrScanSites.Length > 0 )
	{
		foreach arrScanSites(ScanSite)
		{
			if(i < MAX_NUM_STRATEGYICONS)
			{
				i++;
				FactionHQ = XComGameState_Haven(ScanSite);
				if(FactionHQ != none)
				{
					//numHQ++; issue #76 start: variable addition commented out and added to below cases
					switch (FactionHQ.GetResistanceFaction().GetChampionClassName())
					{
					case 'Skirmisher':
						MissionItemUI.MissionIcons[1].SetScanSite(ScanSite);
						numHQ++;
						break;
					case 'Reaper':
						MissionItemUI.MissionIcons[0].SetScanSite(ScanSite);
						numHQ++;
						break;
					case 'Templar':
						MissionItemUI.MissionIcons[2].SetScanSite(ScanSite);
						numHQ++;
						break;
					default: //issue #76: this is for any mod-added factions so their HQs are still properly registered. We don't count them as HQs for UI purposes though, as those slots are reserved for the above factions
						MissionItemUI.MissionIcons[3 - numHQ + numScanSites].SetScanSite(ScanSite); //numHQ will be never go above 3, so this should always work
						break;
						
					}
					//end issue #76
				}
				else if(FactionHQ == none)
				{
					//start issue #76; this is basically just cleanup since there's no real reason for the if statement: numHQ will never go above 3 with the changes we've made
					MissionItemUI.MissionIcons[3 - numHQ + numScanSites].SetScanSite(ScanSite);

					if (ScanSite.IsA('XComGameState_BlackMarket'))
					{
						MissionItemUI.MissionIcons[3 - numHQ + numScanSites].AS_SetAlert(!XComGameState_BlackMarket(ScanSite).bHasSeenNewGoods);
					}
					//end issue #76
				}

				numScanSites++;
			}
			else
			{
				`RedScreenOnce("Too many Scan Sites, increase size of MAX_NUM_STRATEGYICONS in UIStrategyMap");
			}
		}
	}

	foreach MissionItemUI.Missions(MissionSite)
	{
		if(i < MAX_NUM_STRATEGYICONS)
		{
			MissionItemUI.MissionIcons[i].SetMissionSite(MissionSite);
			i++;
			numMissions++;
		}
		else
		{
			`RedScreenOnce("Too many Missions, increase size of MAX_NUM_STRATEGYICONS in UIStrategyMap");
		}
	}

	Navigator.Clear();
	for(i = 0; i < MAX_NUM_STRATEGYICONS; i++ )
	{
		if(i < numScanSites+numMissions)
		{
			MissionItemUI.MissionIcons[i].SetSortedPosition(numScanSites, numMissions);
			
			//bsg-jneal (5.19.17): for Faction HQs, do not make them navigable if the player has not unlocked them yet
			FactionHQ = XComGameState_Haven(MissionItemUI.MissionIcons[i].ScanSite);
			if (FactionHQ == none || FactionHQ.IsResistanceFactionMet())
			{
				// Scan sites list backwards
				if (i < numScanSites)
				{
					Navigator.AddControl(MissionItemUI.MissionIcons[i]);
				}
				else
				{
					Navigator.AddControl(MissionItemUI.MissionIcons[i]);
				}
			}
			//bsg-jneal (5.19.17): end			
		}
		else
		{
			MissionItemUI.MissionIcons[i].Hide();
		}
	}

	StrategyMapHUD.mc.BeginFunctionOp("SetMissionTrayWidth");
	StrategyMapHUD.mc.QueueNumber(numScanSites-3);
	StrategyMapHUD.mc.QueueNumber(numMissions);
	StrategyMapHUD.mc.EndOp();

	MissionItemUI.ScanSites = arrScanSites;


	if( `ISCONTROLLERACTIVE )
	{
		if (SelectedMapItem != none)
		{
			`EARTH.SetViewLocation(SelectedMapItem.Cached2DWorldLocation);
			SetSelectedMapItem(SelectedMapItem);
			HideTooltip();
		}
		else
		{
			TargetCursorMeshOpacity = 0.0;
		}
	}
	else
	{
		Navigator.SelectFirstAvailableIfNoCurrentSelection();
	}

	if( `ISCONTROLLERACTIVE )
	{
		if (numScanSites > 1 || numMissions > 0)
		{
			LeftBumperIcon.Show();
			RightBumperIcon.Show();
		}
		else
		{
			LeftBumperIcon.Hide();
			RightBumperIcon.Hide();
		}
	}
}

function int SortMissionsUnlocked(XComGameState_MissionSite MissionA, XComGameState_MissionSite MissionB)
{
	local XComGameState_WorldRegion RegionA, RegionB;

	RegionA = MissionA.GetWorldRegion();
	RegionB = MissionB.GetWorldRegion();

	if (RegionA == none || RegionB == none)
		return 1;
	
	if (RegionA.ResistanceLevel > RegionB.ResistanceLevel)
	{
		return 1;
	}
	else if (RegionA.ResistanceLevel < RegionB.ResistanceLevel)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortMissionsType(XComGameState_MissionSite MissionA, XComGameState_MissionSite MissionB)
{
	local X2MissionSourceTemplate MissionASource, MissionBSource;

	MissionASource = MissionA.GetMissionSource();
	MissionBSource = MissionB.GetMissionSource();

	// First sort alien facility missions
	if (MissionASource.bAlienNetwork && !MissionBSource.bAlienNetwork)
	{
		return -1;
	}
	else if (!MissionASource.bAlienNetwork && MissionBSource.bAlienNetwork)
	{
		return 1;
	}
	else
	{
		// Then Golden Path missions
		if (MissionASource.bGoldenPath && !MissionBSource.bGoldenPath)
		{
			return -1;
		}
		else if (!MissionASource.bGoldenPath && MissionBSource.bGoldenPath)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
}

function int SortScanSitesType(XComGameState_ScanningSite ScanSiteA, XComGameState_ScanningSite ScanSiteB)
{
	local bool SiteAResource, SiteBResource, SiteARegion, SiteBRegion, SiteABlackMarket, SiteBBlackMarket;

	SiteABlackMarket = ScanSiteA.IsA('XComGameState_BlackMarket');
	SiteBBlackMarket = ScanSiteB.IsA('XComGameState_BlackMarket');
	SiteAResource = ScanSiteA.IsA('XComGameState_ResourceCache');
	SiteBResource = ScanSiteB.IsA('XComGameState_ResourceCache');
	SiteARegion = ScanSiteA.IsA('XComGameState_WorldRegion');
	SiteBRegion = ScanSiteB.IsA('XComGameState_WorldRegion');

	// First Black Market
	if (SiteABlackMarket && !SiteBBlackMarket)
	{
		return 1;
	}
	else if (!SiteABlackMarket && SiteBBlackMarket)
	{
		return -1;
	}
	else
	{
		// Then Supply Drop
		if (SiteAResource && !SiteBResource)
		{
			return 1;
		}
		else if (!SiteAResource && SiteBResource)
		{
			return -1;
		}
		else
		{
			// Then World Regions
			if (SiteARegion && !SiteBRegion)
			{
				return 1;
			}
			else if (!SiteARegion && SiteBRegion)
			{
				return -1;
			}
			else
			{
				return 0;
			}
		}
	}
}

simulated function InitMissionIcons()
{
	local int i;

	for( i = 0; i < MAX_NUM_STRATEGYICONS; i++)
	{
		MissionItemUI.MissionIcons.AddItem(Spawn(class'UIStrategyMap_MissionIcon', self).InitMissionIcon(i));
		MissionItemUI.MissionIcons[i].SetSortedPosition(0, 0);//this will spread the icons out based on the number we have
	}
}

simulated function SpawnNavHelpIcons()
{
	local float LocalizedTextOffset;
	local float EstimatedCharacterSize;
	//16 is the test character size that we're using.
	EstimatedCharacterSize = 16;
	if(GetLanguage() == "JPN")
		EstimatedCharacterSize = 28;
	LocalizedTextOffset = EstimatedCharacterSize * Len(m_ResHQLabel)/2;
	if(LocalizedTextOffset < 104)
		LocalizedTextOffset = 104;

	LeftBumperIcon = Spawn(class'UIGamepadIcons', self);
	LeftBumperIcon.InitGamepadIcon('NavButtonLeftBumper', class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LB_L1);
	LeftBumperIcon.SetSize(43.623, 26.845);
	LeftBumperIcon.AnchorBottomCenter();
	//LeftBumperIcon.SetX(-98 - LeftBumperIcon.Width / 2.0 + class'UIGamepadIcons'.const.X_OFFSET);
	LeftBumperIcon.SetX(-LocalizedTextOffset - LeftBumperIcon.Width / 2.0 + class'UIGamepadIcons'.const.X_OFFSET);

	LeftBumperIcon.SetY(-22);

	RightBumperIcon = Spawn(class'UIGamepadIcons', self);
	RightBumperIcon.InitGamepadIcon('NavButtonRightBumper', class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RB_R1);
	RightBumperIcon.SetSize(43.623, 26.845);
	RightBumperIcon.AnchorBottomCenter();
	//RightBumperIcon.SetX(98 - RightBumperIcon.Width / 2.0 + class'UIGamepadIcons'.const.X_OFFSET);
	RightBumperIcon.SetX(LocalizedTextOffset - RightBumperIcon.Width / 2.0 + class'UIGamepadIcons'.const.X_OFFSET);

	RightBumperIcon.SetY(-22);
}

simulated function MoveViewLocation(Vector2D ViewDelta, float DeltaTime)
{
	local Vector2D TargetViewLocation;

	if (!bMoveViewLocation)
	{
		return;
	}

	if (ViewDelta.X < 0.0001 && -0.0001 < ViewDelta.X &&
		ViewDelta.Y < 0.0001 && -0.0001 < ViewDelta.Y)
	{
		if (SelectedMapItem != none)
		{
			TargetViewLocation.X = Lerp(`EARTH.GetViewLocation().X, SelectedMapItem.Cached2DWorldLocation.X, 1.0 - 0.074 ** DeltaTime);
			TargetViewLocation.Y = Lerp(`EARTH.GetViewLocation().Y, SelectedMapItem.Cached2DWorldLocation.Y, 1.0 - 0.074 ** DeltaTime);
			`EARTH.SetViewLocation(TargetViewLocation);
		}
		else
		{
			PreviousViewDelta.X = Lerp(PreviousViewDelta.X, 0.0, 1.0 - 0.0008 ** DeltaTime);
			PreviousViewDelta.Y = Lerp(PreviousViewDelta.Y, 0.0, 1.0 - 0.0008 ** DeltaTime);
			`EARTH.MoveViewLocation(PreviousViewDelta);
		}
	}
	else
	{
		`EARTH.MoveViewLocation(ViewDelta);
		PreviousViewDelta = ViewDelta;
	}
}
simulated function UpdateSelection(float DeltaTime)
{
	local XComEarth Geoscape;
	local vector2D ViewLocation;
	local Vector WorldViewLocation;
	local vector2D TooltipLocation; 
	local float ZoomScale;

	Geoscape = `EARTH;
	ViewLocation = Geoscape.GetViewLocation();
	if (m_eUIState != eSMS_Flight)
	{
		if (bCursorAlwaysVisible)
		{
			if (SelectedMapItem != none)
			{
				WorldViewLocation = SelectedMapItem.CachedWorldLocation;
				WorldViewLocation.Z = 0.1;
				CursorMesh.SetTranslation(VLerp(CursorMesh.Translation, WorldViewLocation, 1.0 - 0.0016 ** DeltaTime));
			}
			else
			{
				WorldViewLocation = Geoscape.GetWorldViewLocation();
				CursorMesh.SetTranslation(VLerp(CursorMesh.Translation, WorldViewLocation, 1.0 - 0.00008 ** DeltaTime));
			}
		}
		else
		{
			if (SelectedMapItem != none)
			{
				WorldViewLocation = SelectedMapItem.CachedWorldLocation;
				WorldViewLocation.Z = 0.1;
				CursorMesh.SetTranslation(WorldViewLocation);
			}
		}

		if (bSelectNearest)
		{
			SelectMapItemNearestLocation(ViewLocation);
		}
	}

	if (ActiveTooltip != none)
	{
		class'UIUtilities'.static.IsOnscreen(SelectedMapItem.CachedWorldLocation, TooltipLocation);
		TooltipLocation = Movie.ConvertNormalizedScreenCoordsToUICoords(TooltipLocation.X, TooltipLocation.Y);
		TooltipLocation.X += 60;
		TooltipLocation.Y -= ActiveTooltip.Height + 60;
		ActiveTooltip.SetTooltipPosition(TooltipLocation.X, TooltipLocation.Y);
	}
	
	CursorMeshOpacity = Lerp(CursorMeshOpacity, TargetCursorMeshOpacity, 1.0 - 0.0008 ** DeltaTime);
	CursorMesh.SetOpacity(CursorMeshOpacity);	

	CrosshairAlpha = Lerp(CrosshairAlpha, TargetCrosshairAlpha, 1.0 - 0.0016 ** DeltaTime);
	Crosshair.SetAlpha(CrosshairAlpha);

	ZoomScale = 0.623 + ((Geoscape.GetCurrentZoomLevel() - 0.32) / (1.274 - 0.32)) * (1.7124 - 0.623);
	//<workshop> Change scale of new cursor - CN 2016/04/21
	//WAS:
	//CursorMesh.SetScale(0.08 * ZoomScale);
	CursorMesh.SetScale(0.70 * ZoomScale);
}

simulated function UpdateZoom(float LeftTrigger, float RightTrigger, float DeltaTime)
{
	Zoom(LeftTrigger, 1.0, DeltaTime);
	Zoom(RightTrigger, - 1.0, DeltaTime);
}

simulated function Zoom(float Delta, float Direction, float DeltaTime)
{
	local XComEarth Geoscape;
	local float ZoomLevel;

	if (Delta > 1.0)
	{
		Delta = 1.0;
	}

	if (Delta < 0.0)
	{
		Delta = 0.0;
	}

	DeltaTime *= Direction;
	Geoscape = `EARTH;

	if (Delta > 0.4 || Delta < -0.4)
	{
		ZoomLevel = Geoscape.fTargetZoom;
		
		if( `ISCONTROLLERACTIVE )
		{
			ZoomLevel += Delta * DeltaTime * 0.8;
			ZoomLevel = FClamp(ZoomLevel, 0.32, 1.274);
		}
		else
		{
			ZoomLevel += Delta * DeltaTime;
			ZoomLevel = FClamp(ZoomLevel, 0.32, 1.75);
		}
		Geoscape.SetCurrentZoomLevel(ZoomLevel);
	}
}

simulated function LookAtAvenger(float InterpTime)
{
	local XComGameState_GeoscapeEntity GeoscapeEntity;
	local UIStrategyMapItem HQMapItem;
	local XComGameStateHistory History;
	local XComEarth Geoscape;

	History = `XCOMHISTORY;
	Geoscape = `EARTH;
	foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', GeoscapeEntity)
	{
		if (XComGameState_HeadquartersXCom(GeoscapeEntity) != none)
		{
			HQMapItem = UIStrategyMapItem(History.GetVisualizer(GeoscapeEntity.ObjectID));
			XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(HQMapItem.Cached2DWorldLocation, Geoscape.fTargetZoom, InterpTime);
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			break;
		}
	}
}

simulated function bool HasLastSelectedMapItem()
{
	return LastSelectedMapItem != none;
}

simulated function SelectLastSelectedMapItem()
{
	if (LastSelectedMapItem != none)
	{
		`EARTH.SetViewLocation(LastSelectedMapItem.Cached2DWorldLocation);
		SetSelectedMapItem(LastSelectedMapItem);
		HideTooltip();
		LastSelectedMapItem = none;
	}
}
simulated function ShowTooltip(UIStrategyMapItem MapItem)
{
	local vector2D ScreenLocation; 

	if (MapItem.CachedTooltipId < 0)
	{
		return;
	}

	ActiveTooltip = UITextTooltip( XComHQPresentationLayer(Movie.Pres).m_kTooltipMgr.GetTooltipByID(MapItem.CachedTooltipId) );
	if (ActiveTooltip != none)
	{
		if (ActiveTooltip.del_OnMouseIn != none)
		{   
			ActiveTooltip.del_OnMouseIn(ActiveTooltip);
		}
		
		ActiveTooltip.SetDelay(0.8);
		class'UIUtilities'.static.IsOnscreen(MapItem.CachedWorldLocation, ScreenLocation);
		ActiveTooltip.SetNormalizedPosition(ScreenLocation);
		XComHQPresentationLayer(Movie.Pres).m_kTooltipMgr.ActivateTooltip(ActiveTooltip);
	}
}

simulated function HideTooltip()
{
	if (ActiveTooltip != none)
	{
		XComHQPresentationLayer(Movie.Pres).m_kTooltipMgr.DeactivateTooltip(ActiveTooltip, true);
		ActiveTooltip = none;
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local XComEarth Geoscape;
	local float OldZoom;
	local XComGameState_Haven Haven;

	// No input during flight mode
	if(m_eUIstate == eSMS_Flight)
	{
		return true;
	}

	// Only pay attention to presses or repeats; ignoring other input types
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	Geoscape = `EARTH;
	OldZoom = Geoscape.fTargetZoom;

	if (SelectedMapItem != none)
	{
		Haven = XComGameState_Haven(`XCOMHISTORY.GetGameStateForObjectID(SelectedMapItem.GeoscapeEntityRef.ObjectID));
		if (Haven != none && cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A)
		{
			if (XCOMHQ().GetCurrentScanningSite().GetReference() == SelectedMapItem.GeoscapeEntityRef &&
				XCOMHQ().IsScanningAllowedAtCurrentLocation())
			{
				ToggleScan();
				return true;
			}
		}

		if (SelectedMapItem.OnUnrealCommand(cmd, arg))
		{
			return true;
		}
	}
	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			TryExiting();
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_L3: //bsg-hlee (05.16.17): Changing to L3 to avoid input issues when using X.
			OnChosenInfoClicked(); //bsg-crobinson(5.8.17): Open chosen info screen
			break;

		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			if (XCOMHQ().IsScanningAllowedAtCurrentLocation())
				ToggleScan();
			//if (SelectedMapItem != none)
			//{
			//	Haven = XComGameState_Haven(`XCOMHISTORY.GetGameStateForObjectID(SelectedMapItem.GeoscapeEntityRef.ObjectID));
			//	if (Haven != none && Haven.HasResistanceGoods())
			//	{
			//		SelectedMapItem.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_BUTTON_A, arg);
			//	}
			//}
			break;

		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
			Geoscape.SetCurrentZoomLevel(Geoscape.fTargetZoom - ZoomSpeed);
			break;

		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
			Geoscape.SetCurrentZoomLevel(Geoscape.fTargetZoom + ZoomSpeed);
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			Navigator.Next(); //bsg-jneal (5.19.17): due to the mission icons being built in reverse order we need to swap the navigation so it appears to go in the right direction
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			Navigator.Prev(); //bsg-jneal (5.19.17): due to the mission icons being built in reverse order we need to swap the navigation so it appears to go in the right direction
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			//SelectMapItemInDirection(0.0, 1.0);
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			//SelectMapItemInDirection(0.0, -1.0);
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
			//SelectMapItemInDirection(-1.0, 0.0);
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
			//SelectMapItemInDirection(1.0, 0.0);
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_SELECT:
			OnResNetClicked();
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_R3:
			LookAtAvenger(0.75f);
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			if (ShowDarkEventsButton() && DarkEventsButton != None)
			{
				OnDarkEventsClicked(none, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
			}
			break;

		// Consume stick input
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
			break;
		default:
			return super.OnUnrealCommand(cmd, arg);
	}

	if(Geoscape.fTargetZoom != OldZoom)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_Zoom_Tick");
	}

	return true;	
}

simulated function TryExiting()
{
	if(`GAME.GetGeoscape().IsScanning())
		ToggleScan();
	else if(m_eUIState != eSMS_Flight)
		CloseScreen();
}

simulated function ToggleScan(optional bool bForceScan=false)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local XGGeoscape Geoscape;
	local bool bAdvanceTime, bTimeSensitiveMission;

	Geoscape = `GAME.GetGeoscape();

	bAdvanceTime = !Geoscape.IsScanning();

	// If attempting to start a scan, if there is a time sensitive mission on the map warn the player that it could be skipped
	if (bAdvanceTime && !bForceScan)
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
				if (MissionState.Expiring && !MissionState.bHasSeenSkipPopup)
				{
					bTimeSensitiveMission = true;
					break;
				}
			}

		if (bTimeSensitiveMission && MissionState != none)
		{
			`HQPRES.UITimeSensitiveMission(MissionState);
		}
	}

	// If we are trying to pause, or if there is no time sensitive mission, then scan as normal
	if (!bAdvanceTime || !bTimeSensitiveMission || bForceScan)
	{
		XCOMHQ().ToggleSiteScanning(bAdvanceTime);

		if (bAdvanceTime)
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_TimeForwardScan");
			Geoscape.m_fTimeScale = Geoscape.TWELVE_HOURS;
		}
		else
		{
			Geoscape.m_fTimeScale = Geoscape.ONE_MINUTE;
		}
	}

	//...then refresh the button help so it switches labels
	if (!bTimeSensitiveMission || MissionState == none)
	{
		UpdateButtonHelp();
	}
}

simulated function CloseScreen()
{
	local XComHQPresentationLayer HQPres; 
	local UIFacilityGrid Grid;

	if( `GAME.GetGeoscape().CanExit() )
	{	
		LastSelectedMapItem = SelectedMapItem;
		HQPres = XComHQPresentationLayer(Movie.Pres);
		Grid = UIFacilityGrid(Movie.Stack.GetScreen(class'UIFacilityGrid'));
		Grid.bSmoothTransitionFromGeoscape = true; //Tell the facility grid not to initiate a camera transition, as we are going to do a smooth camera transition with kismet. ( Below in ExitStrategyMap ) 
		Movie.Stack.Pop(self);
		HQPres.m_kAvengerHUD.Hide();
		HQPres.StrategyMap2D = none;
		HQPres.ExitStrategyMap(true);
		HQPres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(MCPath));
	}
}


simulated function OnLoseFocus()
{
	if(!bIsFocused)
		return;
	super.OnLoseFocus();
	if (SelectedMapItem != none)
	{
		SelectedMapItem.OnMouseOut();
		SelectedMapItem.OnLoseFocus();
	}
	LastSelectedMapItem = SelectedMapItem;
	StrategyMapHUD.Hide(); //Specifically hide, since we're leaving this screen active in general, so the pins are visible. 
	XComMap.OnLoseFocus();
	`HQPRES.m_kEventNotices.Hide();
	`HQPRES.m_kAvengerHUD.HideEventQueue();
	HideMissionButtons();
	HideDarkEventsButton();
	NavBar.ClearButtonHelp(); //removed ForceClearButtonHelp() - JTA 2016/6/20
	CenteredNavHelp.Hide();
	HideTooltip();
	Movie.Pres.m_kEventNotices.Deactivate();

	if( Crosshair != none )
	{
		Crosshair.SetAlpha(0.0);
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Show();
	
	//It may be the case that we're receiving focus after the player has lost the game, as they are about to be kicked back to the main menu.
	//In this case, all of the HQ objects have been cleaned up - don't try to update.
	if (`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true) == None)
		return;

	XComMap.OnReceiveFocus();
	StrategyMapHUD.UpdateData();
	StrategyMapHUD.Show();
	UpdateMissions();
	UpdateButtonHelp();
	if (CenteredNavHelp != none) CenteredNavHelp.Show();
	UpdateDarkEvents();
	UpdateToDoWidget();
//	OnNavigationChanged(0);
	if (m_eUIState != eSMS_Flight)
	{
		bMoveViewLocation = true;
		bSelectNearest = true;
	}
	else
	{
		bMoveViewLocation = false;
		bSelectNearest = false;
	}

	if(`ISCONTROLLERACTIVE == true)
	{
		SelectLastSelectedMapItem(); //bsg-jneal (8.17.16): reselect last map item since we cleared its focus when the map lost focus before.
	}

	Movie.Pres.m_kEventNotices.Activate();
}

simulated function OnRemoved()
{
	super.OnRemoved();
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(MCPath));
	LastSelectedMapItem = SelectedMapItem;
	SelectedMapItem = none;
	HideTooltip();
	`GAME.GetGeoscape().OnExitMissionControl();
	`HQPRES.m_kEventNotices.Hide();
}

//----------------------------------------------------------------

DefaultProperties
{
	InputState = eInputState_Evaluate;
	Package = "/ package/gfxStrategyMap/StrategyMap";
	ZoomSpeed = 0.085
	bHideOnLoseFocus = false; 
	SelectionRadius = 0.016
	CursorMeshOpacity = 1.0
	TargetCursorMeshOpacity = 1.0
	CrosshairAlpha = 1.0
	TargetCrosshairAlpha = 1.0
	bCursorAlwaysVisible = false
	bMoveViewLocation = true;
	bSelectNearest = true

	Begin Object Class=X2FadingStaticMeshComponent Name=CursorMesh
		StaticMesh=none
		HiddenGame=false
		bOwnerNoSee=false
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		TranslucencySortPriority=1000
		bTranslucentIgnoreFOW=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		Scale=0.70
	End Object
	CursorMesh=CursorMesh
	Components.Add(CursorMesh)
}
