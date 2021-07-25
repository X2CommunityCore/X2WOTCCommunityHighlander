
class UIFacilityGrid extends UIScreen;

var UIFacilityGrid_FacilityOverlay m_kSelectedOverlay;
var array<UIFacilityGrid_FacilityOverlay> FacilityOverlays;
var bool bInstantInterp;
var bool bSmoothTransitionFromGeoscape;

var bool bForceShowGrid; 

var localized string MenuPause;
var localized string MenuGridOn;
var localized string MenuGridOff;
var localized string BuildFacilities;

var array<int> shortcutRoomIndices;
var int ShortcutIndex;
//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	local XComGameState_HeadquartersRoom RoomState; 
	local Vector Loc, DefaultOffset; 
	local array<Vector> Corners; 

	super.InitScreen(InitController, InitMovie, InitName);

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_HeadquartersRoom', RoomState)
	{
		Loc = RoomState.GetLocation();
		Corners = RoomState.GetUILocations();

		//If we didn't find the points in the level, then generate the defaults. 
		if( Corners.Length == 0 )
		{
			//Use default if no facility is in this location. 
			DefaultOffset = class'XComGameState_HeadquartersXCom'.default.XComHeadquarters_RoomUIOffset; 
			Corners.AddItem(Loc);
			Corners.AddItem(Loc + DefaultOffset); 
		}

		Corners.Sort(SortCorners); 

		FacilityOverlay = Spawn(class'UIFacilityGrid_FacilityOverlay', self);
		FacilityOverlay.InitFacilityOverlay(RoomState.GetReference(), Loc, Corners);

		FacilityOverlays.AddItem(FacilityOverlay);
	}

	FacilityOverlays.Sort(SortFacilityOverlaysByMapIndex);
	
	if( `ISCONTROLLERACTIVE)
	{
		InitializeNavigationGrid();
		Navigator.OnlyUsesNavTargets = true;
		Navigator.SetSelected(FacilityOverlays[15]);
		ShortcutIndex = -1;
	}

	SetBorderSize(Movie.UI_RES_X * 0.9, Movie.UI_RES_Y * 0.9);

	Movie.Pres.SubscribeToUIUpdate(UpdateOverlayPositions);
	
	RefreshButtonHelp();
}

simulated function OnInit()
{
	local UIPanel SelectedPanel; 

	super.OnInit();

	// This will allow a room to be default selected in the super.OnInit, but will 
	// then hide the highlight. The highlight reappears if any keyboard button or mouse over action occurs. 
	SelectedPanel = Navigator.GetSelected(); 
	if( SelectedPanel!= none )
		SelectedPanel.OnLoseFocus();
	Navigator.SetSelected(FacilityOverlays[15]);
	Navigator.OnSelectedIndexChanged = OnSelectedRoomChanged;
}
simulated function LookAtSelectedRoom()
{
	local array<vector> RoomCorners;
	local Vector RoomLocation;

	RoomCorners = UIFacilityGrid_FacilityOverlay(Navigator.GetSelected()).Corners;
	RoomLocation.X = RoomCorners[0].X + RoomCorners[1].X;
	RoomLocation.Z = RoomCorners[0].Z + RoomCorners[1].Z;
	RoomLocation.X /= 2.0f;
	RoomLocation.Z /= 2.0f;
	XComHQPresentationLayer(Movie.Pres).GetCamera().LookAtLocation(RoomLocation);
}

simulated function OnSelectedRoomChanged(int NewIndex)
{
	local UIAvengerShortcuts AvengerShortcuts;
	local int i, j;

	//This changes the look at point to a room but from an outside perspective.
	if (NewIndex != INDEX_NONE)
	{
		LookAtSelectedRoom();
	}

	UnHighlightAvengerShortcuts();

	AvengerShortcuts = UIAvengerHUD(Movie.Stack.GetScreen(class'UIAvengerHUD')).Shortcuts;
	if (AvengerShortcuts != none)
	{
		AvengerShortcuts.HighlightRoomButton(UIFacilityGrid_FacilityOverlay(Navigator.GetSelected()).GetFacility().GetReference());
	}

	for (i = 0; i < FacilityOverlays.Length; i++)
	{
		if (UIFacilityGrid_FacilityOverlay(Navigator.GetSelected()) == FacilityOverlays[i])
		{
			for (j = 0; j < shortcutRoomIndices.Length; j++)
			{
				if (i == shortcutRoomIndices[j])
				{
					ShortcutIndex = j;
				}
			}
		}
	}

	RefreshButtonHelp(); //bsg-crobinson (5.2.17): Update Navhelp on selection change //bsg-jedwards (5.12.17) : Reordering so that NavHelp for Facility doesn't overwrite the Build Facility NavHelp

	//Check to see if Construction mode is active
	//If it is, then update the navhelp for that screen
	//(must be done here because UIBuildFacilities does not have it's own navigator to detect index changes)
	if(Movie.Pres.ScreenStack.GetScreen(class'UIBuildFacilities') != None)
		UIBuildFacilities(Movie.Pres.ScreenStack.GetScreen(class'UIBuildFacilities')).UpdateNavHelp();
}

simulated function UpdateData()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;

	foreach FacilityOverlays(FacilityOverlay)
		FacilityOverlay.UpdateData();
}

simulated function Show()
{
	if( !IsTimerActive('CameraTravelFinished') && (`SCREENSTACK.IsTopScreen(self) || `SCREENSTACK.IsInStack(class'UIBuildFacilities') ))
		super.Show();
	//AnimateIn();
}

simulated function Hide()
{
	super.Hide();

	if (MC != none)
		MC.FunctionVoid("hideBorder");
}

simulated function UpdateOverlayPositions()
{
	local Vector2D v2DPos, v2Offset;
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;

	foreach FacilityOverlays(FacilityOverlay)
	{
		// get screen position for the upper corner
		class'UIUtilities'.static.IsOnScreen(FacilityOverlay.Corners[0], v2DPos, 0, 0);
		v2DPos = Movie.ConvertNormalizedScreenCoordsToUICoords(v2DPos.x, v2DPos.y, false);
		
		// get screen position for the lower corner
		class'UIUtilities'.static.IsOnScreen(FacilityOverlay.Corners[1], v2Offset, 0, 0);
		v2Offset = Movie.ConvertNormalizedScreenCoordsToUICoords(v2Offset.x, v2Offset.y, false);
		
		//FacilityOverlay.UpdateBGSizeUsingOffset(v2Offset.X - v2DPos.x, v2Offset.Y - v2DPos.y);
		FacilityOverlay.SetSize(Abs(v2Offset.X - v2DPos.x), Abs(v2Offset.Y - v2DPos.y));

		// ------------------------------- 

		/// NOTE: you want to set the location *after* setting the Offset -> BG Size up above, that way the BG has updated the facility's height. 
		FacilityOverlay.SetPosition(v2DPos.x, v2DPos.y - FacilityOverlay.height);

		// ------------------------------- 

		FacilityOverlay.Show();
	}

	// This flushes queued SetPosition events so UI elements don't lag behind the Facility Rooms
	Movie.ProcessQueuedCommands();
}

//Sorts so that map index matches array index. 
simulated function int SortFacilityOverlaysByMapIndex(UIFacilityGrid_FacilityOverlay FacilityA, UIFacilityGrid_FacilityOverlay FacilityB)
{
	if( FacilityA.RoomMapIndex < FacilityB.RoomMapIndex )
		return 1;
	else
		return -1;
}

simulated function InitializeNavigationGrid()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay, CommandersQuarters, CIC, Armory, Engineering, PowerCore, LivingQuarters, Memorial;
	
	local int ShadowChamberIndex;
	local int i;
	//CORE FACILITIES: ==============================================

	PowerCore = FacilityOverlays[1];
	CommandersQuarters = FacilityOverlays[0];
	CIC = FacilityOverlays[15];
	Armory = FacilityOverlays[2];
	Engineering = FacilityOverlays[17]; 
	LivingQuarters = FacilityOverlays[16];
	Memorial = FacilityOverlays[18];

	if(UIAvengerHUD(Movie.Stack.GetScreen(class'UIAvengerHUD')).AvengerSecondButtonNavigation)
	{
		if(shortcutRoomIndices.Length == 0)
		{
			shortcutRoomIndices.AddItem(1);		//Research
			shortcutRoomIndices.AddItem(17);	//Engineering
			shortcutRoomIndices.AddItem(2);		//Armory
			shortcutRoomIndices.AddItem(0);		//Command

			ShadowChamberIndex = GetShadowChamberIndex();
			if(ShadowChamberIndex != -1)
				shortcutRoomIndices.AddItem(ShadowChamberIndex);
		}
	}

	for(i = 0; i < 19; ++i)
	{
		FacilityOverlays[i].Navigator.ClearAllNavigationTargets();
		FacilityOverlays[i].Navigator.OnlyUsesNavTargets = true;
	}
	PowerCore.Navigator.AddNavTargetRight(FacilityOverlays[9]);
	PowerCore.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[3]);
	PowerCore.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[12]);
	CommandersQuarters.Navigator.AddNavTargetRight(CIC);
	CommandersQuarters.Navigator.AddNavTargetDown(LivingQuarters);
	CommandersQuarters.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[15]);


	CIC.Navigator.AddNavTargetLeft(LivingQuarters);
	CIC.Navigator.AddNavTargetRight(Armory);
	CIC.Navigator.AddNavTargetDown(FacilityOverlays[5]);
	CIC.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[4]);
	CIC.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[0]);

	Armory.Navigator.AddNavTargetLeft(FacilityOverlays[5]);

	Armory.Navigator.AddNavTargetDown(Memorial);
	Armory.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[15]);
	Armory.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[8]);
	
	Engineering.Navigator.AddNavTargetLeft(FacilityOverlays[11]);
	Engineering.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[8]);
	Engineering.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[14]);
	Engineering.Navigator.AddNavTargetUp(Memorial);
	LivingQuarters.Navigator.AddNavTargetRight(CIC);
	LivingQuarters.Navigator.AddNavTargetDown(FacilityOverlays[3]);
	LivingQuarters.Navigator.AddNavTargetUp(CommandersQuarters);
	
	Memorial.Navigator.AddNavTargetLeft(FacilityOverlays[8]);
	Memorial.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[2]);
	Memorial.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[5]);
	Memorial.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[11]);
	Memorial.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[17]);
	Memorial.Navigator.AddNavTargetUp(Armory);
	Memorial.Navigator.AddNavTargetDown(Engineering);

	// CENTER GRID: ==================================================

	// TOP ROW 0 ---------------------------------------------------------
	// Top left  3
	FacilityOverlay = FacilityOverlays[3];
	FacilityOverlay.Navigator.AddNavTargetLeft(PowerCore);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[4]);

	FacilityOverlay.Navigator.AddNavTargetUp(LivingQuarters);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[1]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[6]);


	// Top middle 4
	FacilityOverlay = FacilityOverlays[4];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[3]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[5]);
	FacilityOverlay.Navigator.AddNavTargetUp(CIC);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[16]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[15]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[7]);

	// Top Right 5
	FacilityOverlay = FacilityOverlays[5];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetRight(Armory);
	FacilityOverlay.Navigator.AddNavTargetUp(CIC);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[15]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[2]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[18]);

	// CENTER ROW 1 -------------------------------------------------------

	// Center left 6
	FacilityOverlay = FacilityOverlays[6];
	FacilityOverlay.Navigator.AddNavTargetLeft(PowerCore);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[3]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[1]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[10]);

	// Center middle 7
	FacilityOverlay = FacilityOverlays[7];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[3]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[5]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[11]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[9]);

	// Center right 8
	FacilityOverlay = FacilityOverlays[8];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetRight(Memorial);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[5]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[11]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[2]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[17]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[10]);

	// CENTER ROW 2 -------------------------------------------------------

	// Center left 9
	FacilityOverlay = FacilityOverlays[9];
	FacilityOverlay.Navigator.AddNavTargetLeft(PowerCore);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[12]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[1]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[12]);

	// Center middle 10
	FacilityOverlay = FacilityOverlays[10];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[11]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[14]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[12]);

	// Center right 11
	FacilityOverlay = FacilityOverlays[11];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetRight(Engineering);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[14]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[18]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[17]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[13]);

	// BOTTOM ROW 3 -------------------------------------------------------

	// Bottom left 12
	FacilityOverlay = FacilityOverlays[12];
	FacilityOverlay.Navigator.AddNavTargetLeft(PowerCore);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[1]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[10]);

	// Bottom middle 13
	FacilityOverlay = FacilityOverlays[13];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[12]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[14]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[11]);

	// Bottom right 14
	FacilityOverlay = FacilityOverlays[14];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetRight(Engineering);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[11]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[17]);
}

simulated function InitializeBuildNavigationGrid()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	local int i;

	for(i = 0; i < 19; ++i)
	{
		FacilityOverlays[i].Navigator.ClearAllNavigationTargets();
		FacilityOverlays[i].Navigator.OnlyUsesNavTargets = true;
	}

	FacilityOverlay = FacilityOverlays[3];
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[7]);

	FacilityOverlay = FacilityOverlays[4];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[3]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[5]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[6]);

	FacilityOverlay = FacilityOverlays[5];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[7]);

	FacilityOverlay = FacilityOverlays[6];
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[3]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[10]);

	FacilityOverlay = FacilityOverlays[7];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[3]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[5]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[11]);

	FacilityOverlay = FacilityOverlays[8];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[5]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[11]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[10]);

	FacilityOverlay = FacilityOverlays[9];
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[12]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[13]);

	FacilityOverlay = FacilityOverlays[10];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[11]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownRight(FacilityOverlays[14]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[12]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[6]);

	FacilityOverlay = FacilityOverlays[11];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[14]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDiagDownLeft(FacilityOverlays[13]);

	FacilityOverlay = FacilityOverlays[12];
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[10]);

	FacilityOverlay = FacilityOverlays[13];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[12]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[14]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpRight(FacilityOverlays[11]);

	FacilityOverlay = FacilityOverlays[14];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[11]);
	FacilityOverlay.Navigator.AddNavTargetDiagUpLeft(FacilityOverlays[10]);
}

simulated function SelectGeoscape()
{
	Navigator.GetSelected().OnLoseFocus();
	Navigator.SetSelected(FacilityOverlays[15]);
}

simulated function UIFacilityGrid_FacilityOverlay GetOverlayForRoom( StateObjectReference RoomRef )
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;

	foreach FacilityOverlays(FacilityOverlay)
	{
		if( FacilityOverlay.RoomRef == RoomRef )
			return FacilityOverlay;
	}
	return none; 
}
simulated function ClickPauseButton()
{
	`HQPRES.UIPauseMenu(); 
}
simulated function RefreshButtonHelp()
{
	local UINavigationhelp NavHelp;
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	
	if(!UIFacilityGrid_FacilityOverlay(Navigator.GetSelected()).bLocked) //bsg-crobinson (5.2.17): Don't show select if the room is locked (IE Debris, etc)
		NavHelp.AddSelectNavHelp(); // bsg-jrebar (4.5.17): Move Select to bottom of order

	NavHelp.AddGeoscapeButton();

	if (`ISCONTROLLERACTIVE)
	{
		if(!class'UIUtilities_Strategy'.static.IsInTutorial(true))
			NavHelp.AddLeftHelp(BuildFacilities, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
	}
}

simulated function OnReceiveFocus()
{
	local int ShadowChamberIndex;
	`log("UIFacilityGrid::OnReceiveFocus <<<<<<<<<<<<<<<<<<<<<<",,'DebugHQCamera');
	
	super.OnReceiveFocus();
	
	XComHeadquartersController(`HQPRES.Owner).SetInputState('HQ_FreeMovement');
	Movie.Pres.SubscribeToUIUpdate(UpdateOverlayPositions);
	UpdateOverlayPositions();
	UpdateData();

	if( bForceShowGrid ) 
		ActivateGrid(); 

	//when receiving focus we need to check the whereabouts of shadow chamber, it's possible
	//that it changed or it may or may not exist
	if(UIAvengerHUD(Movie.Stack.GetScreen(class'UIAvengerHUD')).AvengerSecondButtonNavigation)
	{
		ShadowChamberIndex = GetShadowChamberIndex();
		if(ShadowChamberIndex != -1)
		{
			//if we have only 4, then let's add
			if(shortcutRoomIndices.Length == 4)
				shortcutRoomIndices.AddItem(ShadowChamberIndex);
			else
				shortcutRoomIndices[shortcutRoomIndices.Length - 1] = ShadowChamberIndex;
		}
		else
		{
			if(shortcutRoomIndices.Length > 4)
			{
				//we have no shadow chamber but we have 4 indices
				shortcutRoomIndices.Remove(4, 1);
			}
		}
		ShortcutIndex = -1;
	}
	
	RefreshButtonHelp();

	if(`HQPRES.GetCamera().PreviousRoom != 'Base')
	{
		Hide();
		if(bInstantInterp)
		{
			`HQPRES.GetCamera().StartRoomViewNamed('Base', 0);
			CameraTravelFinished();
			bInstantInterp = false;
		}
		else if(!bSmoothTransitionFromGeoscape)
		{
			`HQPRES.GetCamera().StartRoomViewNamed('Base', `HQINTERPTIME);
			// Show the UI right before the camera transition is over
			SetTimer(`HQINTERPTIME, false, 'CameraTravelFinished');
		}

		//Reset this here as we expect it to have been set TRUE immediately prior to this UI screen gaining focus ( ie. coming from the geoscape )
		bSmoothTransitionFromGeoscape = false; 
	}
	OnSelectedRoomChanged(INDEX_NONE);

	`HQPRES.UICheckForPostCovertActionAmbush();

	Movie.Pres.m_kEventNotices.Activate();
}

// allows us to only show the UI once the camera finishes moving back to base view. Otherwise all of the 2D UI
// floats around strangely
simulated function CameraTravelFinished()
{
	`log("CameraTravelFinished",,'DebugHQCamera');
	
	//CALLING UP, to skip the timer check.
	if( `SCREENSTACK.IsTopScreen( self ) || `SCREENSTACK.IsInStack(class'UIBuildFacilities') )
		super.Show();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	`HQPRES.m_kAvengerHUD.HideEventQueue();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	XComHeadquartersController(`HQPRES.Owner).SetInputState('None');
	DeactivateGrid();
	ClearOverlayHighlights();
	Movie.Pres.m_kEventNotices.Deactivate();

	if (Movie != none)
	{
		Movie.Pres.UnsubscribeToUIUpdate(UpdateOverlayPositions);
		Movie.Pres.m_kTooltipMgr.HideTooltipsByPartialPath(string(MCPath));
		//This clear is helpful for hotlinking around the base. We clear all tooltips, in case something is 
		//dangling once a hotlink activates. 
		Movie.Pres.m_kTooltipMgr.HideAllTooltips();
	}

	// if we lose focus again before the camera finishes transitioning to the screen, we could trip this timer
	// and show ourself even though we shouldn't. So clear any extant timers just in case. 
	ClearTimer('CameraTravelFinished');
}

simulated function OnRemoved()
{
	Movie.Pres.UnsubscribeToUIUpdate(UpdateOverlayPositions);
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(MCPath));
	super.OnRemoved();
}


simulated function SetBorderSize(float NewWidth, float NewHeight)
{
	MC.BeginFunctionOp("setBorderSize");
	MC.QueueNumber(NewWidth);
	MC.QueueNumber(NewHeight);
	MC.EndOp();
}

simulated function SetBorderLabel(string Label)
{
	MC.FunctionString("setLabel", Label);
}

simulated function ActivateGrid()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	bForceShowGrid = true;

	foreach FacilityOverlays(FacilityOverlay)
	{
		if( FacilityOverlay.GetRoom() != none )
		{
			FacilityOverlay.OnShowGrid();
		}
	}

	MC.FunctionVoid("showBorder");
	bProcessMouseEventsIfNotFocused = true;

	//The grid may be requested to activate beneath another screen. 
	if( !bIsFocused )
		Movie.Pres.SubscribeToUIUpdate(UpdateOverlayPositions);
	InitializeBuildNavigationGrid();
	FacilityOverlay = UIFacilityGrid_FacilityOverlay(Navigator.GetSelected());
	if (FacilityOverlay == FacilityOverlays[0] || 
		FacilityOverlay == FacilityOverlays[1] ||
		FacilityOverlay == FacilityOverlays[2] ||
		FacilityOverlay == FacilityOverlays[15] ||
		FacilityOverlay == FacilityOverlays[16] ||
		FacilityOverlay == FacilityOverlays[17] ||
		FacilityOverlay == FacilityOverlays[18])
	{
		Navigator.GetSelected().OnLoseFocus();
		if( `ISCONTROLLERACTIVE )
			Navigator.SetSelected(FacilityOverlays[7]); 
	}
}

simulated function DeactivateGrid()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;

	bForceShowGrid = false;

	foreach FacilityOverlays(FacilityOverlay)
	{
		if(!FacilityOverlay.bIsFocused)
			FacilityOverlay.OnHideGrid();
	}

	MC.FunctionVoid("hideBorder");
	bProcessMouseEventsIfNotFocused = false;

	//The grid may be requested to deactivate beneath another screen. 
	if( !bIsFocused )
		Movie.Pres.UnsubscribeToUIUpdate(UpdateOverlayPositions);
	
	if( `ISCONTROLLERACTIVE)
	   InitializeNavigationGrid();
}

simulated function ClearOverlayHighlights()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	
	foreach FacilityOverlays(FacilityOverlay)
	{
		if (FacilityOverlay.bIsFocused)
			FacilityOverlay.OnLoseFocus();
	}
}

public function ToggleGrid()
{
	if( bForceShowGrid )
		DeactivateGrid();
	else
		ActivateGrid();
	RefreshButtonHelp();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;


	if (!bIsVisible)
	{
		return false;
	}
	
	if( !`ISCONTROLLERACTIVE )
	{
		// Ensure we're at the top of the input stack - navigation commands should only be processed on top screen
		if( Movie.Stack.GetCurrentScreen() != self )
			return false;

		bHandled = true;

		switch( cmd )
		{

		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
			if( arg == class'UIUtilities_Input'.const.FXS_ACTION_RELEASE )
			{
				ClickPauseButton();
			}
			break;
		default:
			bHandled = false;
			break;
		}

		return bHandled || super.OnUnrealCommand(cmd, arg);

	}
	
	bHandled = true;
	
	if (class'UIUtilities_Strategy'.static.IsInTutorial(true))
	{
		if( Movie.Stack.IsCurrentClass(class'UIFacilityGrid'))
		{
			switch( cmd )
			{
			case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
				if (arg == class'UIUtilities_Input'.const.FXS_ACTION_PRESS)
				{
					SetNextShortcutRoomAsSelected();
				}
				break;

			case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
				if (arg == class'UIUtilities_Input'.const.FXS_ACTION_PRESS)
				{
					SetPrevShortcutRoomAsSelected();
				}
				break;
			default:
				bHandled = false;
				break;
			}
		}
		else
			bHandled = false;

		return bHandled || super.OnUnrealCommand(cmd, arg);
	}
	
	// Ensure we're at the top of the input stack - navigation commands should only be processed on top screen
	if ( Movie.Stack.GetCurrentScreen() != self )
		return false;

	// This was moved to the top of the function to support some of the tutorial stuff as well.
	//bHandled = true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		if (arg == class'UIUtilities_Input'.const.FXS_ACTION_RELEASE)
		{
			`HQPRES.UIBuildFacilities();
		}
			
		break;
	default:
		bHandled = false;
		break;
	}

	if(UIAvengerHUD(Movie.Stack.GetScreen(class'UIAvengerHUD')).AvengerSecondButtonNavigation)
	{
		if(!bHandled)
		{
			if( Movie.Stack.IsCurrentClass(class'UIFacilityGrid'))
			{
				bHandled = true;
				switch( cmd )
				{
				case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
					if (arg == class'UIUtilities_Input'.const.FXS_ACTION_PRESS)
					{
						SetNextShortcutRoomAsSelected();
					}
					break;

				case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
					if (arg == class'UIUtilities_Input'.const.FXS_ACTION_PRESS)
					{
						SetPrevShortcutRoomAsSelected();
					}
					break;

				case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
					if( arg == class'UIUtilities_Input'.const.FXS_ACTION_RELEASE)
					{
						ClickPauseButton();
					}
					break;
/*
				case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
				case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
				case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
				case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
				//<workshop> DIAGONAL_NAVIGATION kmartinez 2016-01-25
				//INS:
				case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DIAG_UP_LEFT:
				case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DIAG_UP_RIGHT:
				case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DIAG_DOWN_RIGHT:
				case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DIAG_DOWN_LEFT:
				//</workshop>
				case class'UIUtilities_Input'.const.FXS_DPAD_UP:
				case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
				case class'UIUtilities_Input'.const.FXS_DPAD_LEFT: 
				case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
					if (arg == class'UIUtilities_Input'.const.FXS_ACTION_PRESS)
					{
						UnHighlightAvengerShortcuts();
					}

					bHandled = false;
					break;
*/
				default:
					bHandled = false;
					break;
				}
			}
		}
	}
	return bHandled || super.OnUnrealCommand(cmd, arg);
}
simulated function UnHighlightAvengerShortcuts()
{
	local UIAvengerShortcuts AvengerShortcuts;
	if(ShortcutIndex == -1)
		return;

	AvengerShortcuts = UIAvengerHUD(Movie.Stack.GetScreen(class'UIAvengerHUD')).Shortcuts;
	if(AvengerShortcuts != none)
	{
		AvengerShortcuts.HighlightShortcutButton(ShortcutIndex, false);
		AvengerShortcuts.CurrentCategory = -1;
	}
	ShortcutIndex = -1;
}
simulated function SetNextShortcutRoomAsSelected()
{
	local UIAvengerShortcuts AvengerShortcuts;
	local int previousIndex;

	previousIndex = ShortcutIndex;
	++ShortcutIndex;
	if(ShortcutIndex >= shortcutRoomIndices.Length)
		ShortcutIndex = 0;

	Navigator.OnLoseFocus();
	Navigator.SetSelected(FacilityOverlays[shortcutRoomIndices[ShortcutIndex]]);
	
	// Camera transition from farm view only occurs if the corresponding Shortcut/Category Tab button is enabled.
	AvengerShortcuts = UIAvengerHUD(Movie.Stack.GetScreen(class'UIAvengerHUD')).Shortcuts;
	if(AvengerShortcuts != none && !AvengerShortcuts.Categories[ShortcutIndex].Button.IsDisabled)
		OnSelectedRoomChanged(0);	//param literally does not matter
	if(AvengerShortcuts != none)
	{
		AvengerShortcuts.HighlightShortcutButton(previousIndex, false);
		AvengerShortcuts.HighlightShortcutButton(ShortcutIndex, true);
	}
}

simulated function SetPrevShortcutRoomAsSelected()
{
	local UIAvengerShortcuts AvengerShortcuts;
	local int previousIndex;

	previousIndex = ShortcutIndex;
	--ShortcutIndex;
	if(ShortcutIndex < 0)
		ShortcutIndex = shortcutRoomIndices.Length - 1;

	Navigator.OnLoseFocus();
	Navigator.SetSelected(FacilityOverlays[shortcutRoomIndices[ShortcutIndex]]);
	
	// Camera transition from farm view only occurs if the corresponding Shortcut/Category Tab button is enabled.
	AvengerShortcuts = UIAvengerHUD(Movie.Stack.GetScreen(class'UIAvengerHUD')).Shortcuts;
	if(AvengerShortcuts != none && !AvengerShortcuts.Categories[ShortcutIndex].Button.IsDisabled)
		OnSelectedRoomChanged(0);	//param literally does not matter
		
	if(AvengerShortcuts != none)
	{
		AvengerShortcuts.HighlightShortcutButton(previousIndex, false);
		AvengerShortcuts.HighlightShortcutButton(ShortcutIndex, true);
	}
}

simulated function int GetShadowChamberIndex()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	local XComGameState_FacilityXCom ShadowChamberFacility;
	local int resultIndex;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ShadowChamberFacility = XComHQ.GetFacilityByName('ShadowChamber');
	if(ShadowChamberFacility == none)
		return -1;

	resultIndex = 0;
	foreach FacilityOverlays(FacilityOverlay)
	{
		if(FacilityOverlay.GetRoom().Facility.ObjectID == ShadowChamberFacility.ObjectID)
		{
			return resultIndex;
		}
		++resultIndex;
	}
	return -1;
}

simulated function SelectRoomByReference(StateObjectReference Reference)
{
	local int i;

	for (i = 0; i < FacilityOverlays.Length; i++)
	{
		FacilityOverlays[i].OnLoseFocus();
		if (FacilityOverlays[i].GetRoom().Facility.ObjectID == Reference.ObjectID)
		{
			Navigator.SetSelected(FacilityOverlays[i]);
		}
	}
}

simulated function int SortCorners( vector vA, vector vB )
{
	if( vB.X > vA.X ) return -1; 
	return 0; 
}

defaultproperties
{
	Package = "/ package/gfxFacilityGrid/FacilityGrid";
	bProcessMouseEventsIfNotFocused = false;
	bAutoSelectFirstNavigable = false;
	bIsNavigable = false;
}