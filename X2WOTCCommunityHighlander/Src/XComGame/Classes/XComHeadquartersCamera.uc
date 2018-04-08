//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComHeadquartersCamera extends XComBaseCamera
	config(Camera);

// current ViewDistance multiplier
var transient float						CurrentZoom;

var name RoomTransitioningToFromEarthView;

var rotator m_kEarthViewRotation;

var bool bHasFocusQueued;
var Vector2D QueuedEarthFocusLoc;   // When we transition to Earth view, we'll look at this location if its been Queued
var float fQueuedInterpTime;

var privatewrite name PreviousRoom;
var private name QueuedBaseRoom;
var private float fQueuedBaseRoomInterpTime;

var name CurrentRoom;
var float fEarthTransitionInterp;
var float fFreeMovementInterpTime;		// Issue #193

var bool bTransitionFromSideViewToEarthView;

// temporarily store these for some instances of StartRoomView
var Vector ForcedLocation;
var Rotator ForcedRotation;

const FREECAM_MIN_X = -2300; // right
const FREECAM_MAX_X = 600; // left
const FREECAM_MAX_Z = 1400; // up
const FREECAM_MIN_Z = 800; // down

delegate EnteringAvengerView();
delegate EnteringArmoryView();
delegate EnteringBarView();
delegate EnteringPhotoboothView();
delegate EnteringGeoscapeView();
delegate EnteringFacilityView();

function InitializeFor(PlayerController PC)
{
	super.InitializeFor( PC );

	CurrentZoom = 1.0f;
	fFreeMovementInterpTime = 1.0f;		// Issue #193
}

function bool IsMoving()
{
	return AnimTime < TotalAnimTime;
}

function SetZoom( float Amount )
{
	Amount = FMax( Amount, 0.01f );
	CurrentZoom = Amount;
}

function ResetZoom()
{
	CurrentZoom = 1.0f;
}

protected function OnCameraInterpolationComplete()
{
	local bool bEarthView;
	local Vector EmptyVec;
	local Rotator EmptyRot;

	if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game) == None || `HQPRES == None) //Clean up log spam -BET
		return;
	`log("XComHeadquartersCamera::OnCameraInterpolationComplete <<<<<",,'DebugHQCamera');

	`HQPRES.fCameraSwoopDelayTime = -1.0f;
	
	super.OnCameraInterpolationComplete();

	if (IsInState('EarthView') || IsInState('EarthViewFocusingOnLocation'))
	{
		`log("  IsInState('EarthView') || IsInState('EarthViewFocusingOnLocation')",,'DebugHQCamera');
		bEarthView = true;

		LastCameraStateOrientation.Focus = `EARTH.GetWorldViewLocation();
		OldCameraStateOrientation.Focus = LastCameraStateOrientation.Focus;
	}
	else if (IsInState('BaseViewTransition'))
	{
		`log("  IsInState('BaseViewTransition')",,'DebugHQCamera');
		`log("  PreviousRoom = QueuedBaseRoom which is" @ PreviousRoom,,'DebugHQCamera');		
		
		StartRoomView(QueuedBaseRoom, fQueuedBaseRoomInterpTime, ForcedLocation, ForcedRotation);
		ForcedLocation = EmptyVec;
		ForcedRotation = EmptyRot;
	}

	if (!bEarthView)
	{
		`EARTH.Show(false);
	}
	else
	{
		`EARTH.Show(true);
	}

	`HQPRES.OnCameraInterpolationComplete();
	PreviousRoom = QueuedBaseRoom;
	fQueuedBaseRoomInterpTime = 0;
	QueuedBaseRoom = '';
}


protected function GetCameraStateView( XComCameraState CamState, float DeltaTime, out CameraStateOrientation NewOrientation )
{
	// start with an fov of 90, the views can override if they want to
	NewOrientation.FOV = 90.0f;

	super.GetCameraStateView( CamState, DeltaTime, NewOrientation );

	NewOrientation.ViewDistance *= CurrentZoom;
}

function GetViewDistance( out float ViewDistance )
{
	local CameraStateOrientation NewOrientation;
	GetCameraStateView( CameraState, 0.0f, NewOrientation );

	NewOrientation.ViewDistance *= CurrentZoom;
	ViewDistance = NewOrientation.ViewDistance;
}
function float GetTargetViewDistance()
{
	return XComCamState_HQ_FreeMovement(CameraState).GetTargetViewDistance();
}

function SetRelativeViewDistance( float fRelativeDist )
{
	local CameraStateOrientation NewOrientation;

	GetCameraStateView( CameraState, 0.0, NewOrientation );
	NewOrientation.ViewDistance += fRelativeDist;
	
	XComCamState_HQ_FreeMovement(CameraState).SetViewDistance( NewOrientation.ViewDistance );
}

function SetViewDistance( float fDist )
{
	local CameraStateOrientation NewOrientation;

	GetCameraStateView( CameraState, 0.0, NewOrientation );
	NewOrientation.ViewDistance = fDist;
	
	XComCamState_HQ_FreeMovement(CameraState).SetViewDistance( NewOrientation.ViewDistance );

	LookRelative(vect(0, 0, 0), CurrentZoom);
}
function StartStrategyShellView()
{
	XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',0.0f)).InitRoomView( PCOwner, 'Shell' );
	TriggerKismetEvent('Shell');
	GotoState( 'BaseView' );
}


function StartHeadquartersView()
{
	XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',0.0f)).InitRoomView( PCOwner, 'Base' );
	TriggerKismetEvent('Base');
}

function bool FreeMovementInterpolationIsOccurring()
{
	return XComCamState_HQ_FreeMovement(CameraState).FreeMovementInterpolationIsOccurring();
}
function StartRoomView( name RoomName, float InterpTime, optional Vector ForceLocation, optional Rotator ForceRotation )
{
	local CameraStateOrientation CurrentOrientation;
	local CameraActor cameraActor;
	`log("StartRoomView" @ string(RoomName) @ InterpTime,,'DebugHQCamera');

	if (IsInState('EarthView') || IsInState('EarthViewFocusingOnLocation'))
	{
		/*RoomTransitioningToFromEarthView = RoomName;
		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, 'MissionControl' );
		TriggerKismetEvent(RoomName);
		if (InterpTime > 0)
			fEarthTransitionInterp = 1.0f;
		else fEarthTransitionInterp = 0;
		GotoState('EarthViewReverseTransition');*/

		if (RoomName == 'CameraPhotobooth')
		{
			//Do nothing. This is the case for generating ChosenCaptured posters.
			return;
		}

		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, RoomName );
				
		`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true); // Refresh Avenger visibility states when leaving the Geoscape

		TriggerKismetEvent(RoomName);
		GotoState( 'BaseRoomView' );
	}
	else if (RoomName == 'MissionControl')
	{
		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, RoomName );
		TriggerKismetEvent(RoomName);
		if (InterpTime > 0)
			fEarthTransitionInterp = 1.0f;
		else fEarthTransitionInterp = 0;		
	}
	else if(RoomName == 'FreeMovement')
	{
		//Only switch to free movement if we are not in a cinematic view at the moment ( cinematic mode should be toggled off first, and the matinees stopped )
		if( XComCamState_HQ_FreeMovement(CameraState) == none && !IsInState('CinematicView') && !`SCREENSTACK.HasInstanceOf(class'UIBuildFacilities'))
		{
			//Grab the current view...
			GetCameraStateView( CameraState, 0.0, CurrentOrientation );
			ResetZoom();

			//...and init the free movement at the current view's focus . 
			//Start Issue #193
			XComCamState_HQ_FreeMovement(SetCameraState(class'XComCamState_HQ_FreeMovement',InterpTime)).Init( PCOwner, CurrentOrientation.Focus, CurrentOrientation.ViewDistance );
			//End Issue #193
			//TriggerKismetEvent('FreeMovement'); //TODO: will we need this? 
			GotoState( 'FreeMovementView' );
		}
	}
	else if(RoomName == 'Expansion')
	{
		if( WorldInfo.IsConsoleBuild() )
		{
			foreach AllActors(class'CameraActor', cameraActor)
			{
				if( cameraActor.Tag == 'Expansion')
				{
					cameraActor.SetLocation(vect(3290, 3000, -2500));
				}
			}
		}

		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, RoomName );
		TriggerKismetEvent(RoomName);
		GotoState( 'BaseRoomView' );
	}
	else if (RoomName == 'CameraPhotobooth')
	{
		//Do nothing. Implemented in UIArmory_Photobooth.uc
		CurrentRoom = RoomName;
	}
	else
	{

		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, RoomName, ForceLocation, ForceRotation );
		TriggerKismetEvent(RoomName);
		GotoState( 'BaseRoomView' );

		// if going to ant farm view or...
		// if going into the armory and not in squad select sequence then we still want ambient musings to trigger
		if (RoomName == 'Base')
		{
			if (EnteringAvengerView != none)
			{
				EnteringAvengerView();
			}
		}
		else if ((RoomName == 'UIDisplayCam_Armory' || RoomName == 'UIBlueprint_ArmoryMenu' || RoomName == 'UIBlueprint_Loadout' || 
				RoomName == 'UIBlueprint_Promotion_Hero' || RoomName == 'UIBlueprint_CustomizeMenu' || RoomName == 'UIBlueprint_CustomizeHead') &&
				!`SCREENSTACK.HasInstanceOf(class'UISquadSelect'))
		{
			if (EnteringArmoryView != none)
			{
				EnteringArmoryView();
			}
		}
		else if (RoomName == 'UIDisplayCam_BarMemorial')
		{
			if (EnteringBarView != none)
			{
				EnteringBarView();
			}
		}
		else
		{
			// going into a specific room
			if (EnteringFacilityView != none)
			{
				EnteringFacilityView();
			}
		}
	}
}

function StartRoomViewNamed( name RoomName, float fInterpTime, optional bool bSkipBaseViewTransition, optional Vector ForceLocation, optional Rotator ForceRotation )
{
	local XComCamState_HQ_BaseRoomView RoomView;
	RoomView = XComCamState_HQ_BaseRoomView(CameraState);

	`log("StartRoomViewNamed" @ RoomName @ PreviousRoom @ RoomView.CamName @ fInterpTime,,'DebugHQCamera');
	if(fInterpTime > 0)
	{
/*
		// No need to interpolate to the same room - prevents camera jerking
		if(RoomName == PreviousRoom)
		{
			return;
		}
*/
		// This fix handles the case occurs when LBUMPER or RBUMPER is pressed twice before the camera can reach the
		// halfway point, and the camera position jumps.  This makes the position continuous!
		if (!bSkipBaseViewTransition && RoomView != none && RoomView.CamName == 'Base' && AnimTime < TotalAnimTime && RoomName != PreviousRoom)
		{
			`log("StartRoomViewNamed 2",,'DebugHQCamera');
			`log("  QueuedBaseRoom =" @ RoomName,,'DebugHQCamera');
			`log("  fQueuedBaseRoomInterpTime =" @ fInterpTime,,'DebugHQCamera');
			PreviousRoom = RoomName;
			StartRoomView( RoomName, fInterpTime, ForceLocation, ForceRotation );
			ForcedLocation = ForceLocation;
			ForcedRotation = ForceRotation;
			QueuedBaseRoom = RoomName;
			fQueuedBaseRoomInterpTime = fInterpTime;
			GotoState('BaseViewTransition');
			return;
		}
	}
	else
	{
		// if we get an instant camera change then drop any queued change
		`log("StartRoomViewNamed 3",,'DebugHQCamera');
		QueuedBaseRoom = '';
		fQueuedBaseRoomInterpTime = 0;
	}

	if(RoomName == 'MissionControl')
	{
		`log("StartRoomViewNamed 4",,'DebugHQCamera');
		RoomName = 'Base';
	}

	if(RoomName == 'Base' && fInterpTime > 0)
	{
		`log("StartRoomViewNamed 5",,'DebugHQCamera');
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("AntFarm_Camera_Zoom_Out");
	}

	if (CurrentRoom == 'CameraPhotobooth')
	{
		// Need to pop back to the Armory when exiting photobooth, else we will interpolate from below the ground.
		fInterpTime = 0.0f;
	}

	// cache the previous room to prevent animation reset to the same camera location
	PreviousRoom = RoomName;

	StartRoomView( RoomName, fInterpTime, ForceLocation, ForceRotation);
}

function TriggerKismetEvent(name RoomName)
{
	local int i;
	local SeqEvent_OnStrategyRoomEntered RoomEnteredEvent;
	local SeqEvent_OnStrategyRoomExited RoomExitedEvent;
	local array<SequenceObject> Events;

	if( WorldInfo.GetGameSequence() != None )
	{
		WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_OnStrategyRoomExited', TRUE, Events);
		for (i = 0; i < Events.Length; i++)
		{
			RoomExitedEvent = SeqEvent_OnStrategyRoomExited(Events[i]);
			if( RoomExitedEvent != None )
			{
				RoomExitedEvent.RoomName = CurrentRoom;

				RoomExitedEvent.CheckActivate(WorldInfo, None);
			}
		}

		CurrentRoom = RoomName; // This will be the next room to be left

		WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_OnStrategyRoomEntered', TRUE, Events);
		for (i = 0; i < Events.Length; i++)
		{
			RoomEnteredEvent = SeqEvent_OnStrategyRoomEntered(Events[i]);
			if( RoomEnteredEvent != None )
			{
				RoomEnteredEvent.RoomName = RoomName;

				RoomEnteredEvent.CheckActivate(WorldInfo, None);
			}
		}
	}
}

function FocusOnFacility(name RoomName)
{
	local vector FacilityLocation;
	local XComHQ_RoomLocation RoomLoc;

	foreach AllActors(class'XComHQ_RoomLocation', RoomLoc)
	{
		if (RoomLoc.RoomName == RoomName)
		{
			FacilityLocation = RoomLoc.Location;
			break;
		}
	}

	StartRoomView('FreeMovement', fFreeMovementInterpTime);			//Issue #193
	XComCamState_HQ_FreeMovement(CameraState).SetTargetFocus(FacilityLocation);
	//SetZoom(0.3f);
}

function LookAtLocation(Vector LookLocation)
{
	StartRoomView('FreeMovement', fFreeMovementInterpTime);			//Issue #193
	XComCamState_HQ_FreeMovement(CameraState).LookAtRoom(LookLocation, false);
}
function SetInitialFocusToCamera(name CameraName)
{
	local CameraActor Camera;

	if (Camera == none)
	{
		foreach WorldInfo.AllActors(class'CameraActor', Camera)
		{
			if (Camera.Tag == CameraName)
			{
				break;
			}
		}
	}

	if (Camera == none)
	{
		return;
	}

	XComCamState_HQ_FreeMovement(CameraState).SetInitialFocus(Camera.Location);
}

state BaseView
{
}

state BaseViewTransition
{
}

state BaseRoomView
{
	event BeginState(Name PreviousStateName)
	{
		if (CurrentRoom == 'Base' && PreviousStateName == 'EarthView')
		{
			`AUTOSAVEMGR.DoAutosave();
		}
	}

	event EndState(Name NextStateName)
	{
		if (CurrentRoom == 'UIDisplayCam_CIC' && NextStateName == 'EarthView')
		{
			if (EnteringGeoscapeView != none)
			{
				EnteringGeoscapeView();
			}

			if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M3_WelcomeToHQ') != eObjectiveState_InProgress)
			{
				`AUTOSAVEMGR.DoAutosave();
			}
		}
	}
}


function LookRelative( Vector vRelativeLoc, optional float fZoomPercent = 1.0f ); 
state FreeMovementView
{	
	event BeginState(Name PreviousStateName)
	{
		if (CurrentRoom == 'Base')
		{
			if (EnteringAvengerView != none)
			{
				EnteringAvengerView();
			}
		}
	}

	function LookRelative( Vector vRelativeLoc, optional float fZoomPercent = 1.0f )
	{
		local CameraStateOrientation CurrentOrientation, NewOrientation;
		local bool bFreeCam;
		local float fViewDistScalar;

		GetCameraStateView( CameraState, 0.0, CurrentOrientation );
		NewOrientation = CurrentOrientation;
		NewOrientation.Focus.X += vRelativeLoc.X;
		NewOrientation.Focus.Y += vRelativeLoc.Y;
		NewOrientation.Focus.Z += vRelativeLoc.Z; 


		bFreeCam = false;
		if (XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager) != none) 
			bFreeCam = XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager).bFreeCam;

		fViewDistScalar = GetViewDistanceScalar();

		if (!bFreeCam)
		{
			if (NewOrientation.Focus.X > GetFreeCamMax_X(fViewDistScalar))
				NewOrientation.Focus.X = GetFreeCamMax_X(fViewDistScalar);
			else if (NewOrientation.Focus.X < GetFreeCamMin_X(fViewDistScalar))
				NewOrientation.Focus.X = GetFreeCamMin_X(fViewDistScalar);
			if (NewOrientation.Focus.Z > GetFreeCamMax_Z(fViewDistScalar))
				NewOrientation.Focus.Z = GetFreeCamMax_Z(fViewDistScalar);
			else if (NewOrientation.Focus.Z < GetFreeCamMin_Z(fViewDistScalar))
				NewOrientation.Focus.Z = GetFreeCamMin_Z(fViewDistScalar);
		}
		
		SetZoom( fZoomPercent );
		if(`ISCONTROLLERACTIVE)
			XComCamState_HQ_FreeMovement(CameraState).LookAtImmediate( NewOrientation.Focus );
		else
			XComCamState_HQ_FreeMovement(CameraState).LookAt( NewOrientation.Focus );
		
		`Log("HQ cam look at " $ NewOrientation.Focus,,'XComCameramgr');
	}
}

function ForceEarthViewImmediately(bool TransitionFromSideView)
{
	bTransitionFromSideViewToEarthView = TransitionFromSideView;
	GotoState('EarthView');
}

function NewEarthView(float fInterpTime)
{
	XComCamState_Earth(SetCameraState(class'XComCamState_Earth', fInterpTime)).Init(PCOwner, self);
}

function GeoscapePausePawnInterpActions()
{
	local XComHumanPawn P;
	
	foreach WorldInfo.AllPawns( class'XComHumanPawn', P )
	{
		P.GeoscapePauseInterpActions();
	}
}

function GeoscapeUnpausePawnInterpActions()
{
	local XComHumanPawn P;
	
	foreach WorldInfo.AllPawns( class'XComHumanPawn', P )
	{
		P.GeoscapeUnpauseInterpActions();
	}
}
state EarthView
{
	event BeginState(Name PreviousStateName)
	{
		NewEarthView(0);

		if (EnteringGeoscapeView != none)
		{
			EnteringGeoscapeView();
		}

		XComInputBase(PCOwner.PlayerInput).m_bSteamControllerInGeoscapeView = true;
		GeoscapePausePawnInterpActions();
	}

	event EndState(Name NextStateName)
	{
		XComInputBase(PCOwner.PlayerInput).m_bSteamControllerInGeoscapeView = false;
		GeoscapeUnpausePawnInterpActions();
	}


Begin:
	if( bTransitionFromSideViewToEarthView )
	{
		bTransitionFromSideViewToEarthView = false;

		// Wait for the geoscape to become fully visible
		while( !`MAPS.IsStreamingComplete() )
		{
			Sleep(0.1f);
		}

		// kick off the post-geoscape-fully-loaded events
		`XCOMGRI.DoRemoteEvent('CIN_PostGeoscapeLoaded');
	}
}



simulated state BootstrappingStrategy
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		StartRoomView('MissionControl', 0.0f);
		StartRoomView('FreeMovement', fFreeMovementInterpTime);			//Issue #193
	}
}

function float GetViewDistanceScalar()
{
	local float fViewDist;

	`HQPRES.GetCamera().GetViewDistance(fViewDist);

	return 1.0f - fViewDist / (class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance() - class'XComCamState_HQ_BaseView'.default.m_fPCDefaultMinViewDistance);
}

function float GetFreeCamMax_X(float fViewDistScalar)
{
	return FREECAM_MAX_X + (FREECAM_MAX_X - FREECAM_MIN_X)*fViewDistScalar;
}

function float GetFreeCamMin_X(float fViewDistScalar)
{
	return FREECAM_MIN_X - (FREECAM_MAX_X - FREECAM_MIN_X)*fViewDistScalar;
}

function float GetFreeCamMax_Z(float fViewDistScalar)
{
	return FREECAM_MAX_Z + (FREECAM_MAX_Z - FREECAM_MIN_Z)*fViewDistScalar;
}

function float GetFreeCamMin_Z(float fViewDistScalar)
{
	return FREECAM_MIN_Z - (FREECAM_MAX_Z - FREECAM_MIN_Z)*fViewDistScalar;
}

function GetViewFromCameraName( CameraActor CamActor_, name CamName_, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha )
{
	CameraState.GetViewFromCameraName( CamActor_, CamName_, out_Focus, out_Rotation, out_ViewDistance, out_FOV, out_PPSettings, out_PPOverrideAlpha );
}

// Overrides XComBaseCamera::InterpCameraState.
protected function InterpCameraState(float DeltaTime, out vector out_Location, out rotator out_Rotation, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha)
{
	local float tVal;
//	local XComCamState_HQ_BaseRoomView HQCamState;
	local vector				FacilityTransition_Focus;
	local rotator				FacilityTransition_Rotation;
	local float					FacilityTransition_ViewDistance;
	local float					FacilityTransition_FOV;
	local PostProcessSettings	FacilityTransition_PPSettings;
	local float					FacilityTransition_PPOverrideAlpha;
	local float					Dist;
	local float				    RealDeltaTime;
	local XComHQPresentationLayer LocalHQPres;
	local GameInfo				LocalGameInfo;

	// Reducing log spam in non-HQ related areas.
	LocalGameInfo = class'Engine'.static.GetCurrentWorldInfo().Game;
	if ((XComHeadquartersGame(LocalGameInfo) != None) && (XComHeadquartersController(XComHeadquartersGame(LocalGameInfo).PlayerController) != None))
	{
		LocalHQPres = `HQPRES;
	}
	
	// Don't let the Avenger camera hitch, so interpolate with a steady DeltaTime, but
	// maintain the RealDeltaTime so the .5 second fCameraSwoopDelayTime stays in real time.
	RealDeltaTime = DeltaTime;
	DeltaTime = FMin( DeltaTime, 0.0333f );	
	
	//`log("XComHeadquartersCamera::InterpCameraState",,'DebugHQCamera');

	GetCameraStateView(CameraState, DeltaTime, LastCameraStateOrientation);

//	HQCamState = XComCamState_HQ_BaseRoomView(CameraState);

	// Check for special calculation done for Facilty-to-facility Parabolic Interpolation
	if (LocalHQPres != None && LocalHQPres.EnteringParabolicFacilityTransition())
	{
		LocalHQPres.GetFacilityTransition(FacilityTransition_Focus, FacilityTransition_Rotation, FacilityTransition_ViewDistance, FacilityTransition_FOV,  FacilityTransition_PPSettings, FacilityTransition_PPOverrideAlpha);

		Dist = VSize(OldCameraStateOrientation.Focus - FacilityTransition_Focus);

		`log("InterpCameraState EnteringParabolicFacilityTransition:",,'DebugHQCamera');
		`log("  OldCameraStateOrientation.Focus =" @ OldCameraStateOrientation.Focus  @ "ViewDistance =" @ OldCameraStateOrientation.ViewDistance,,'DebugHQCamera');
		`log("  FacilityTransition_Focus        =" @ FacilityTransition_Focus         @ "ViewDistance =" @ FacilityTransition_ViewDistance       ,,'DebugHQCamera');

		// Set camera location and other properties to the midpoint of the two locations
		LastCameraStateOrientation.Focus            = (OldCameraStateOrientation.Focus            + FacilityTransition_Focus          ) * 0.5f;
		LastCameraStateOrientation.Rotation         = (OldCameraStateOrientation.Rotation         + FacilityTransition_Rotation       ) * 0.5f;
		LastCameraStateOrientation.ViewDistance     = (OldCameraStateOrientation.ViewDistance     + FacilityTransition_ViewDistance   ) * 0.5f;
		LastCameraStateOrientation.FOV              = (OldCameraStateOrientation.FOV              + FacilityTransition_FOV            ) * 0.5f;
		LastCameraStateOrientation.PPOverrideAlpha  = (OldCameraStateOrientation.PPOverrideAlpha  + FacilityTransition_PPOverrideAlpha) * 0.5f;

		LastCameraStateOrientation.PPSettings = FacilityTransition_PPSettings;
		class'Helpers'.static.OverridePPSettings(LastCameraStateOrientation.PPSettings, OldCameraStateOrientation.PPSettings, 0.5f);
		
		`log("  New Target                Focus =" @ LastCameraStateOrientation.Focus @ "ViewDistance =" @ LastCameraStateOrientation.ViewDistance,,'DebugHQCamera');


		//TODO(AMS): implement OverridePPSettings at some point?  Perhaps after they fix the blurriness issue.

		LastCameraStateOrientation.ViewDistance += Dist * 0.5f;
	}

	// Camera movement is delayed by a small amount following a left or right bumper press.
	// (Wait .5 seconds of real time before transitioning the camera to a facility.)
	if (LocalHQPres != None && LocalHQPres.fCameraSwoopDelayTime > 0.0f)
	{
		LocalHQPres.fCameraSwoopDelayTime -= RealDeltaTime;
		tVal = 0.0f;
	}
	if (LocalHQPres != None && LocalHQPres.fCameraSwoopDelayTime <= 0.0f)
	{
		LocalHQPres.fCameraSwoopDelayTime = 0.0f;
	}

	// Once the fCameraSwoopDelayTime is done, continue to wait until the crew member background load completes.
	if (AnimTime == 0.0 && IsAsyncLoadingWrapper())
	{
		`log("Waiting for AsyncLoading to complete before interpolating camera",,'DebugHQCamera');
	}
	else
	{
		/*if (`XPROFILESETTINGS.Data.GetConsoleType() == CONSOLE_Durango ||
			`XPROFILESETTINGS.Data.GetConsoleType() == CONSOLE_Orbis)
		{
			DeltaTime *= (`HQINTERPTIME / `HQINTERPTIME_CONSOLE);
		}*/

		// Keep the contribution of DeltaTime constant frame-to-frame, so AnimTime does not get capped off by the FMin below.  
		// (Note: the same value is always passed in for DeltaTime.)
		DeltaTime = 1.0f / Round(TotalAnimTime / DeltaTime);

		AnimTime += DeltaTime;

		tVal = FMin( AnimTime / TotalAnimTime, 1.0f );
	}
	

	//`log("XComHeadquartersCamera::InterpCameraState tVal =" @ tVal,,'DebugHQCamera');

	// For ViewDistance, use a parabola-like spline.
	if (LocalHQPres != None && LocalHQPres.EnteringParabolicFacilityTransition())
	{
		LastCameraStateOrientation.ViewDistance = FCubicInterp(
			OldCameraStateOrientation.ViewDistance,
			2.0f * (LastCameraStateOrientation.ViewDistance - OldCameraStateOrientation.ViewDistance),
			LastCameraStateOrientation.ViewDistance,
			0.0f,
			tVal);
	}
	else if (LocalHQPres != None && LocalHQPres.ExitingParabolicFacilityTransition())
	{
		LastCameraStateOrientation.ViewDistance = FCubicInterp(
			OldCameraStateOrientation.ViewDistance,
			0.0f,
			LastCameraStateOrientation.ViewDistance,
			2.0f * (LastCameraStateOrientation.ViewDistance - OldCameraStateOrientation.ViewDistance),
			tVal);
	}
	else
	{
		LastCameraStateOrientation.ViewDistance =  Lerp( OldCameraStateOrientation.ViewDistance, LastCameraStateOrientation.ViewDistance, tVal );
	}

	LastCameraStateOrientation.Focus = VLerp( OldCameraStateOrientation.Focus, LastCameraStateOrientation.Focus, tVal );
	LastCameraStateOrientation.Rotation =   RLerp( OldCameraStateOrientation.Rotation, LastCameraStateOrientation.Rotation, tVal, true );
	LastCameraStateOrientation.FOV =  Lerp(OldCameraStateOrientation.FOV, LastCameraStateOrientation.FOV, tVal);
	LastCameraStateOrientation.PPOverrideAlpha = Lerp(OldCameraStateOrientation.PPOverrideAlpha, LastCameraStateOrientation.PPOverrideAlpha, tVal);
	class'Helpers'.static.OverridePPSettings(LastCameraStateOrientation.PPSettings, OldCameraStateOrientation.PPSettings, 1.0f - tVal);

	`log("InterpCameraState Focus=" @ LastCameraStateOrientation.Focus @ "ViewDistance=" @ LastCameraStateOrientation.ViewDistance 
		                            @ "AnimTime =" @ AnimTime @ "TotalAnimTime =" @ TotalAnimTime,,'DebugHQCamera');

	out_Location = LastCameraStateOrientation.Focus - vector(LastCameraStateOrientation.Rotation) * LastCameraStateOrientation.ViewDistance;
	out_Rotation = LastCameraStateOrientation.Rotation;
	out_FOV = LastCameraStateOrientation.FOV;//DefaultFOV;
	out_PPOverrideAlpha = LastCameraStateOrientation.PPOverrideAlpha;
	out_PPSettings = LastCameraStateOrientation.PPSettings;

	if ( AnimTime >= TotalAnimTime )
	{
		`log("Interp Done!  AnimTime=" @ AnimTime @ "TotalAnimTime =" @ TotalAnimTime,,'DebugHQCamera');
		OnCameraInterpolationComplete();
	}
}

DefaultProperties
{
	DefaultFOV=30.0f
	CurrentRoom=none
}
