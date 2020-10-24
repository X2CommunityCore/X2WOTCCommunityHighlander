//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComTacticalInput extends XComInputBase dependson(X2GameRuleset)
	native(UI);     // TODO - move into separate native base class

var UIInputGate             m_kInputGate; 

var() vector2d				AimSpeedMax;
var() vector2d				AimAccel;
var() vector2d				AimDecel;

// aim position for firing cursor, int -1...1 space
var transient vector2d		ScreenAimPos;
var transient vector2d		CurrentAimSpeed;

// Right thumbstick selection
var transient Vector2D      LeftStickVector;
var transient XGUnit        RightStickSelection;

var localized string        m_sHelpNoAbilitiesAvailable;
var UITutorialSaveData      m_kTutorialSaveData;

var bool                    m_bInputBlocked;
var bool					m_bMouseFreeLook;
var vector2d				m_vMouseCursorPos; // current location of the mouse cursor
var vector2d				m_vMouseCursorDelta; // delta between the mouse cursor location last frame and this frame
var bool                    m_bReceivedPress; //Verifying input pairing on A button event 
var float                   m_fRightMouseHoldTime;

var XComOnlineProfileSettings m_ProfileSettings;
var() float                 ScrollSpeedUnitsPerSecond;

var bool bWasHUDVisible;
var bool m_bPrevBorderHidden;

function bool IsKeyPressed(TacticalBindableCommands command)
{	
	local PlayerInput PlayerIn;
	local XComKeybindingData KeyBindData;
	local KeyBind KeyBinding;

	PlayerIn = XComPlayerController(`PRES.Owner).PlayerInput;
	KeyBindData = `PRES.m_kKeybindingData;

	KeyBinding = KeyBindData.GetBoundKeyForAction(PlayerIn, command);
	if (PressedKeys.Find(KeyBinding.Name) != INDEX_NONE)
		return true;

	KeyBinding = KeyBindData.GetBoundKeyForAction(PlayerIn, command, true);
	if (PressedKeys.Find(KeyBinding.Name) != INDEX_NONE)
		return true;

	return false;
}

function float GetScrollSpeedInUnitsPerSecond()
{
	local float fPercent;

	if ( m_ProfileSettings == none )
	{
		m_ProfileSettings = `XPROFILESETTINGS;
	}

	// Scale the scroll speed such that it goes from 0.25 to 1.75 of the default speed.
	fPercent = Lerp( 0.25f, 1.75f, m_ProfileSettings.Data.m_fScrollSpeed * 0.01f );

	return ( ScrollSpeedUnitsPerSecond * fPercent );
}

simulated function UIMovie Get2DMovie()
{
	if (XComPresentationLayer(XComTacticalController(Outer).Pres) == none)
		return none;

	return XComPresentationLayer(XComTacticalController(Outer).Pres).Get2DMovie();
}

simulated function XGUnit GetActiveUnit()
{
	return XComTacticalController(Outer).GetActiveUnit();
}

simulated event Camera GetPlayerCamera()
{
	return XComTacticalController(Outer).PlayerCamera;
}

simulated function bool PostProcessCheckGameLogic( float DeltaTime )
{
//`if(`notdefined(FINAL_RELEASE))
//	if( GetProtoUI() != none )
//	{
//		GetProtoUI().PostProcessInput( self, DeltaTime );
//		return true;
//	}
//`endif
	return false;
}

native function GetMouseCoordinates(out vector2d vec);

simulated function ActivateInputGateSystem( bool bTurnOn )
{
	if( bTurnOn )
	{
		m_kInputGate = Spawn(class'UIInputGate', XComPresentationLayer(XComTacticalController(Outer).Pres) );
		m_kInputGate.Init();	
		m_kInputGate.Activate(bTurnOn);
	}
	else
	{
		m_kInputGate.Activate(bTurnOn);
		m_kInputGate = none; 
	}
}

simulated function bool ButtonIsDisabled( int cmd )
{
	if( `TACTICALGRI != none && `TACTICALGRI.DirectedExperience != none )
	{
		return `TACTICALGRI.DirectedExperience.ButtonIsBlocked(cmd);
	}
	return false;
}

simulated function bool ActivateAbilityByHotKey(int ActionMask, int KeyCode)
{
	local UITacticalHUD TacticalHUD;
	local int AbilityIndex;

	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
		return false;

	TacticalHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
	AbilityIndex = TacticalHUD.m_kAbilityHUD.GetAbilityIndexByHotKey(KeyCode);
	if (AbilityIndex == INDEX_NONE)
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
		return false;
	}

	TacticalHUD.m_kAbilityHUD.DirectConfirmAbility(AbilityIndex, true);
	return true;
}

simulated function bool ActivateAbilityByName(int ActionMask, name AbilityName)
{
	local UITacticalHUD TacticalHUD;
	local int AbilityIndex;

	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0)
	{
		return false;
	}

	TacticalHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
	AbilityIndex = TacticalHUD.m_kAbilityHUD.GetAbilityIndexByName(AbilityName);
	if (AbilityIndex == INDEX_NONE)
	{
		PlaySound(SoundCue'SoundUI.NegativeSelection2Cue', true , true);
		return false;
	}

	TacticalHUD.m_kAbilityHUD.DirectConfirmAbility(AbilityIndex);
	return true;
}

//-----------------------------------------------------------
//-----------------------------------------------------------
// Return true if the input is consumed in preprocessing; else return false and input continues down the waterfall. 
simulated function bool PreProcessCheckGameLogic( int cmd , int ActionMask) 
{
	local XComPresentationLayer pres;
	local UIMovie_2D interfaceMgr; 
	local UIScreen Screen;
	local bool CinematicBlocked;
	pres = XComPresentationLayer(XComTacticalController(Outer).Pres);
	interfaceMgr = (pres != none)? pres.Get2DMovie() : none;

	//Check the input gating system first.
	if( m_kInputGate != none ) 
	{
		if( m_kInputGate.OnUnrealCommand( cmd, Actionmask ) ) 
			return false; 
	}

	// If a dialog is up then let input go to it
	if( interfaceMgr != none && interfaceMgr.DialogBox != none && interfaceMgr.DialogBox.ShowingDialog() )
	{
		return true;
	}

	//No end of mission pause
	if( cmd == class'UIUtilities_Input'.const.FXS_BUTTON_START
		&& `BATTLE.IsBattleDone() )
		return false;

	if( XComTacticalController(Outer).m_iBloodlustMove > 0)
		return false;

	if(m_bInputBlocked)
	{
		return false;
	}

	if (pres == none)
		return false;

	if( pres.ScreenStack.bCinematicMode && !pres.ScreenStack.bPauseMenuInput &&
	   ((cmd != class'UIUtilities_Input'.const.FXS_KEY_PAUSE && cmd != class'UIUtilities_Input'.const.FXS_KEY_ESCAPE) || IsCurrentMatineeSkippable()) )
	{
		// no input while the ui is hidden (unless a screen explicitly allows it)
		CinematicBlocked = true;
		foreach pres.ScreenStack.Screens(Screen) 
		{
			if(Screen.bShowDuringCinematic)
			{
				CinematicBlocked = false;
				break;
			}
		}

		if(CinematicBlocked)
		{
			return false;
		}
	}

	if( `XENGINE != none && `XENGINE.IsMoviePlaying(class'Engine'.static.GetLastMovieName()) )
	{
		if(WorldInfo.NetMode != NM_Standalone ||
			(WorldInfo.GRI != none && XComTacticalGRI(WorldInfo.GRI).m_kBattle != none && XComTacticalGRI(WorldInfo.GRI).m_kBattle.AtBottomOfRunningStateBeginBlock()) )
		{
			pres.UIStopMovie();
		}
		return false;
	}
	return true;
}
function Abort();

//Used to change via bumpers and mouse controls 
function bool PrevUnit();
function bool NextUnit();

// MHU - Do not comment out the below log statements. Currently tracking cases where tacticalinput somehow ends up locked.
event BeginState(name nmPrevState)
{
	if (GetStateName() == 'None' || nmPrevState == 'None')
		`log("XComTacticalInput.uc, Transition to/from State None detected. BeginState"@GetStateName()@"from"@nmPrevState);
}

event EndState(Name NextStateName)
{
	if (GetStateName() == 'None' || NextStateName == 'None')
		`log("XComTacticalInput.uc, Transition to/from State None detected. EndState"@GetStateName()@"to"@NextStateName);
}

simulated function CheckMouseSmartToggle( int cmd )
{
	local XComOnlineProfileSettings ProfileSettings;

	//If the input setting is marked to prevent the mouse from activation, then don't let the mouse trigger on. 
	ProfileSettings = `XPROFILESETTINGS;
	if( ProfileSettings != none && !ProfileSettings.Data.IsMouseActive() ) 
	{
		//Turn off if it was supposed to be off, as an additional check. 
		if( Get2DMovie().IsMouseActive() )
		{
			Get2DMovie().DeactivateMouse();
		}
	}
	else
	{
		super.CheckMouseSmartToggle( cmd ); 
	}
}

simulated function PostProcessMouseMovement()
{
	local Vector2D prevMouseCursorLocation;
	local XComOnlineProfileSettings ProfileSettings;

	//If the input setting is marked to prevent the mouse from activation, then don't let the mouse trigger on. 
	ProfileSettings = `XPROFILESETTINGS;
	if( ProfileSettings != none )
	{
		if( !ProfileSettings.Data.IsMouseActive() ) 
		{
			//Turn off if it was supposed to be off, as an additional check. 
			if( Get2DMovie() != none && Get2DMovie().IsMouseActive() )
			{
				Get2DMovie().DeactivateMouse();
			}
			return; 
		}
		else if( Get2DMovie() != none && !Get2DMovie().IsMouseActive() ) // if profile wants mouse but we aren't using it
		{
			Get2DMovie().ActivateMouse();
		}
	}
	else if( Get2DMovie() != none && !Get2DMovie().IsMouseActive() )			
	{
		Get2DMovie().ActivateMouse();
	}

	// update the cursor position and delta
	prevMouseCursorLocation = m_vMouseCursorPos;
	GetMouseCoordinates(m_vMouseCursorPos);
	m_vMouseCursorDelta = m_vMouseCursorPos - prevMouseCursorLocation;

	super.PostProcessMouseMovement(); 
}

simulated function Mouse_CheckForWindowScroll(float fDeltaTime)
{
	local XComTacticalController kController;
	local XComPresentationLayer pres;
	local XComHUD kHud;
	local Vector2D v2Tmp, v2Mouse, v2ScreenSize; 
	local float fScrollAmount;
	local bool bInScrollArea;

	kController = XComTacticalController(Outer);
	pres = XComPresentationLayer(kController.Pres); 
	kHud = XComHud(kController.myHUD);

	// If mouse isn't yet fully initialized bail out - sbatista 6/17/2013
	if (!pres.GetMouseCoords(v2Tmp)) return;

	//Don't use the UI reporting mouse loc, because you'll end up with fun rounding errors and sadness. 
	//Use the player controller's info on teh hardware mouse. -bsteiner 
	v2Mouse = XComLocalPlayer(kController.Player).ViewportClient.GetMousePosition();

	if (v2Mouse.Y <= 1 || //Up
		v2Mouse.Y >= (v2ScreenSize.y - 1) || //Down
		v2Mouse.X <= 1 ||  //Left
		v2Mouse.X >= (v2ScreenSize.x - 1)) //Right
	{
		bInScrollArea = true;
	}

	//Checking edges of the screen for mouse-push camera scrolling.
	if( pres != none && pres.Get2DMovie().IsMouseActive() && bInScrollArea
		&& !m_bMouseFreeLook
		&& kHud.bGameWindowHasFocus
		&& pres.m_kUIMouseCursor != none
		&& !pres.m_kUIMouseCursor.bIsInDefaultLocation  
		&& !pres.IsPauseMenuRaised()
		&& !TestMouseConsumedByFlash() )
	{
		v2ScreenSize = XComLocalPlayer(kController.Player).SceneView.GetSceneResolution();
		fScrollAmount = GetScrollSpeedInUnitsPerSecond() * fDeltaTime;

		if( v2Mouse.Y <= 1 )        //Up
			XComCamera(PlayerCamera).EdgeScrollCamera( 0, fScrollAmount );
		else if( v2Mouse.Y >= (v2ScreenSize.y - 1) )   //Down
			XComCamera(PlayerCamera).EdgeScrollCamera( 0, -fScrollAmount );

		if( v2Mouse.X <= 1 )        //Left
			XComCamera(PlayerCamera).EdgeScrollCamera( -fScrollAmount, 0 );
		else if( v2Mouse.X >= (v2ScreenSize.x - 1) )   //Right
			XComCamera(PlayerCamera).EdgeScrollCamera( fScrollAmount, 0 );
	}
}

simulated function Mouse_FreeLook()
{
	local XComPresentationLayer vPres;

	if(!m_bMouseFreeLook) return;

	vPres = XComPresentationLayer(XComTacticalController(Outer).Pres); 
	if ( vPres.Get2DMovie().IsMouseActive() 
		&& !vPres.m_kUIMouseCursor.bIsInDefaultLocation )
	{
		`CAMERASTACK.PitchCameras(-m_vMouseCursorDelta.y * 0.2);
		`CAMERASTACK.YawCameras(m_vMouseCursorDelta.x * 0.3);
	}
}

simulated function Controller_CheckForWindowScroll()
{
	local float fSpeed;

	if(XComPresentationLayer(XComTacticalController(Outer).Pres) != none && XComPresentationLayer(XComTacticalController(Outer).Pres).Get2DMovie().IsMouseActive())
	{
		return;
	}

	if( aTurn != 0 || aLookUp != 0 )
	{
		// aTurn and aLookup are scaled from 0 to 100, but we want it from 0.0 to 1.0
		// it also already takes delta time into account
		fSpeed = GetScrollSpeedInUnitsPerSecond() * 0.01;
		XComCamera(PlayerCamera).ScrollCamera( aTurn * fSpeed, aLookUp * fSpeed);
	}
}

// Adjusts the mouse pick location for air picks and grid snaps.
simulated function bool GetAdjustedMousePickPoint(out Vector kPickPoint, bool bAllowAirPicking, bool bSnapToGrid)
{
	local XComWorldData kWorldData;
	local XCom3DCursor kCursor; 
	local XComHUD kHUD; 
	local Vector kPlaneHitPoint;
	local float fGroundLocation;
	local float fRatio;
	local TTile tTile;

	kHUD = GetXComHUD();
	if( kHUD == none ) return false; 

	kWorldData = `XWORLD;
	if(kWorldData == none) return false;

	kCursor = XComTacticalController(Outer).GetCursor();
	if(kCursor == none) return false;

	// to allow selecting points in the air (same as kicking the the 3d cursor up with the controller),
	// create a plane parallel to the xy-plane with height and the bottom of the current floor.
	// If the mouse pick ray intersects that before it hits the ground and we're allowing
	// air picks, use the plane intersection point instead. This may seem a bit wonky, but Unreals trace
	// functions are only able to trace against objects.
	kPlaneHitPoint.Z = kCursor.m_fLogicalCameraFloorHeight;
	fGroundLocation = kWorldData.GetFloorZForPosition( kHUD.CachedHitLocation );
	if( bAllowAirPicking && kPlaneHitPoint.Z > fGroundLocation && kHUD.CachedMouseWorldDirection.Z < 0.0 )
	{
		// invisible plane is closer or no mouse pick collision, so intersect pick ray with the invisible plane
		fRatio = ( kHUD.CachedHitLocation.Z - kPlaneHitPoint.Z ) / -kHUD.CachedMouseWorldDirection.Z;
		kPlaneHitPoint.X = (kHUD.CachedMouseWorldDirection.X * fRatio) + kHUD.CachedHitLocation.X;
		kPlaneHitPoint.Y = (kHUD.CachedMouseWorldDirection.Y * fRatio) + kHUD.CachedHitLocation.Y;

		if(bSnapToGrid)
		{
			tTile = kWorldData.GetTileCoordinatesFromPosition( kPlaneHitPoint );
			kPickPoint = kWorldData.GetPositionFromTileCoordinates( tTile ); // snap to grid cell center 
			kPickPoint.Z = kPlaneHitPoint.Z;
		}
		else
		{
			kPickPoint = kPlaneHitPoint;
		}
			
		return true;
	}
	else if( kHUD.CachedMouseInteractionInterface != none )
	{
		if(bSnapToGrid)
		{
			tTile = kWorldData.GetTileCoordinatesFromPosition( kHUD.CachedHitLocation );
			kPickPoint = kWorldData.GetPositionFromTileCoordinates( tTile ); // snap to grid cell center 
			kPickPoint.Z = fGroundLocation;
		}
		else
		{
			kPickPoint = kHUD.CachedHitLocation;
		}
				
		return true; 
	}

	return false;
}

// jboswell: state where input does nothing, used during transition maps
auto state InTransition
{
	event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
	}

	event EndState(name NextStateName)
	{
		super.EndState(NextStateName);
	}
}


//bsg - when player loses in single player, needed for overriding PostProcessCheckGameLogic
state SinglePlayerLost
{
	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{
		return true;
	}
}


state InReplayPlayback
{
// Only called while unit is performing action
	function Abort()
	{
	}

	simulated function bool PreProcessCheckGameLogic( int cmd , int ActionMask ) 
	{
		local XComPresentationLayerBase kPres;

		kPres = XComTacticalController(Outer).Pres;
		// Make sure that the pause menu shows up when moving.
		if ( kPres.IsPauseMenuRaised() )
		{
			return true;
		}

		return super.PreProcessCheckGameLogic( cmd, ActionMask );
	}

	function bool A_Button( int ActionMask )
	{		
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			//XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD().OnClickedButtonStepReplay();			
		}
		return true;
	}
	function bool B_Button( int ActionMask )
	{		
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			//XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD().OnClickedButtonStopReplay();
		}
		return true;
	}
	
	function bool Key_X( int Actionmask )
	{
		return X_Button( Actionmask );
	}
	function bool X_Button( int ActionMask )
	{
		return false;
	}

	function bool Key_Y( int ActionMask )
	{
		return Y_Button(ActionMask);
	}

	function bool Key_N( int ActionMask )
	{				
		return false;
	}
	function bool Key_R( int ActionMask )
	{				
		return false;
	}
	function bool Y_Button( int ActionMask )
	{	
		return false;
	}
	function bool Mouse4( int ActionMask )
	{
		return false;
	}

	function bool Bumper_Right( int ActionMask )
	{
		return false;
	}
	
	function bool Mouse5( int ActionMask )
	{
		return false;
	}

	function bool Bumper_Left( int ActionMask )
	{
		return false;
	}

	function bool Key_Spacebar( int ActionMask )
	{
		return false;
	}

	function bool Trigger_Right( float fTrigger, int ActionMask )
	{
		return false;
	}

	function bool Key_Left_Shift( int ActionMask )
	{
		return false;
	}
	function bool Key_Left_Control( int ActionMask )
	{
		return false;
	}
	function bool Key_Delete( int ActionMask )
	{
		return false;
	}
	function bool Key_Tab( int ActionMask )
	{
		return false;
	}

	private function OpenShotHUD()
	{
		
	}

	function bool Key_Z(int ActionMask )
	{
		return false;
	}

	function bool Trigger_Left( float fTrigger, int ActionMask )
	{	
		return false;
	}

	function bool Stick_R3( int ActionMask )
	{		
		return false;
	}
	function bool Stick_L3( int ActionMask )
	{
		return false;
	}
	
	function bool Key_W( int ActionMask ){ return ArrowUp( ActionMask );}
	function bool Key_A( int ActionMask ){ return ArrowLeft( ActionMask );}
	function bool Key_S( int ActionMask ){ return ArrowDown( ActionMask );}
	function bool Key_D( int ActionMask ){ return ArrowRight( ActionMask );}
	
	function bool Key_F( int ActionMask ){ return Dpad_Up( ActionMask );}
	function bool Key_C( int ActionMask ){ return Dpad_Down( ActionMask );}

	function bool Key_Q( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(90.0);
		return false;
	}
	function bool Key_E( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(-90.0);
		return false;
	}

	function bool DPad_Right( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(-90.0);
		return false;
	}
	function bool DPad_Left( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(90.0);
		return false;
	}
	function bool DPad_Up( int ActionMask )
	{
		local XCom3DCursor Cursor;
		local int iMASK;

		iMASK = class'UIUtilities_Input'.const.FXS_ACTION_RELEASE;	

		if (( ActionMask & iMASK) != 0)
		{
			//XComTacticalController(Outer).PerformMoveModeChange( eMove_Fast );

			Cursor = XComTacticalController(Outer).GetCursor();
			Cursor.AscendFloor();
		}
		return false;
	}
	function bool DPad_Down( int ActionMask )
	{
		local XCom3DCursor Cursor;
		local int iMASK;

		iMASK = class'UIUtilities_Input'.const.FXS_ACTION_RELEASE;

		if (( ActionMask & iMASK) != 0)
		{
			//XComTacticalController(Outer).PerformMoveModeChange( eMove_Normal );

			Cursor = XComTacticalController(Outer).GetCursor();
			Cursor.DescendFloor();
		}
		return false;
	}
	function bool Back_Button( int ActionMask )
	{
		return false;
	}
	
	function bool Key_Backspace( int ActionMask )
	{
		return false;
	}
	function bool Start_Button( int ActionMask )
	{
		return false;
	}	

	function bool LMouse( int ActionMask )
	{
		return false;
	}

	function bool LDoubleClick( int ActionMask )
	{
		return false;
	}

	function bool RMouse( int Actionmask )
	{
		return false;
	}

	function bool MMouse(int ActionMask)
	{
		return false;
	}
	function bool MouseScrollUp( int ActionMask )
	{
		return true; 
	}
	function bool MouseScrollDown( int ActionMask )
	{
		return true; 
	}

	function bool Key_T( int ActionMask )
	{
		return true; 
	}
	function bool Key_G( int ActionMask )
	{
		return true; 
	}
	function bool Key_V( int ActionMask )
	{
		return false;
	}	
	
	simulated function bool ArrowUp( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorUp))
			{
				DPad_Up(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}
	simulated function bool ArrowDown( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorDown))
			{
				DPad_Down(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}

	simulated function bool ArrowLeft( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateLeft))
			{
				DPad_Left(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}

	simulated function bool ArrowRight( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateRight))
			{
				DPad_Right(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}

	simulated function bool PauseKey( int ActionMask )
	{
		return false;
	}

	simulated function bool EscapeKey( int ActionMask )
	{
		// Ignoring EscapeKey press, ShotHUD is raised. This prevents excessive Escape/Space combos which flood Targeting actions in MP. -ttalley
		if( XComTacticalController(Outer).GetPres().GetTacticalHUD().IsMenuRaised() )
		{
			return true;
		}

		return Start_Button(ActionMask);
	}

	simulated function bool EnterKey( int ActionMask )
	{		
		XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StepReplayForward();
		return true;
	}
	
	simulated function bool Key_Home( int ActionMask )
	{		
		return true; 
	}

	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{		
		if( `XENGINE != none && `XENGINE.IsMoviePlaying(class'Engine'.static.GetLastMovieName()) )
		{
			return false;
		}

		if( ! `BATTLE.IsPaused() )
		{
			if( !XComPresentationLayer(XComTacticalController(Outer).Pres).Get2DMovie().DialogBox.TopIsModal()
				&& !XComPresentationLayer(XComTacticalController(Outer).Pres).IsPauseMenuRaised())
			{
				Controller_CheckForWindowScroll();
			}
		}

		return true;
	}

	event BeginState( name nmPrevState )
	{
		super.BeginState(nmPrevState);
	}

	event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);
	}
Begin: 
}

// This state is exactly the same as state "UsingTargetingMethod" except that I brought back camera rotation
// and I removed the ability to press the Y button for Overwatch shortcut.
state UsingSecondaryTargetingMethod
{
	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{
		super.PostProcessCheckGameLogic(DeltaTime);

		Controller_CheckForWindowScroll();
		Mouse_CheckForWindowScroll(DeltaTime);
		Mouse_FreeLook();
		Mouse_CheckForFreeAim();

		XComCamera(PlayerCamera).PostProcessInput();

		return true;
	}

	simulated function bool LMouse(int ActionMask)
	{
		local UITacticalHUD TacticalHUD;
		local X2TargetingMethod TargetingMethod;

		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			// check for left mouse clicks. It's very difficult to trap these properly in a movie screen, so process them here
			TacticalHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
			TargetingMethod = TacticalHUD.GetTargetingMethod();
			if(TargetingMethod != none && TargetingMethod.AllowMouseConfirm())
			{
				TacticalHUD.m_kAbilityHUD.ConfirmAbility();
				return true;
			}
		}

		return false;
	}

	simulated function Mouse_CheckForFreeAim()
	{
		local XComPresentationLayer pres;
		local IMouseInteractionInterface MouseTarget; 
		local XCom3DCursor Cursor; 
		local XComHUD HUD; 
		local XComUnitPawn kPawn; 
		local XGUnit kTargetUnit;
		local Vector kPickPoint;

		pres = XComPresentationLayer(XComTacticalController(Outer).Pres); 

		HUD = GetXComHUD();
		if( HUD == none ) return; 

		// update the free aim cursor location
		if( pres.Get2DMovie().IsMouseActive() && pres.GetTacticalHUD().IsMenuRaised())
		{ 
			MouseTarget = GetMouseInterfaceTarget();		
			if( MouseTarget == none ) return;

			Cursor = XComTacticalController(Outer).GetCursor();

			// try to find a unit to lock on to
			kPawn = XComUnitPawn(MouseTarget);	
			if( kPawn != none )
			{
				kTargetUnit = XGUnit(kPawn.GetGameUnit());
			}

			if( kTargetUnit != none ) 
			{
				// if we're highlighting a unit, lock the targeting cursor to it
				Cursor.CursorSetLocation( kTargetUnit.GetLocation(), false ); 
			}
			else if(GetAdjustedMousePickPoint(kPickPoint, false, false))
			{
				XComTacticalController(Outer).GetCursor().CursorSetLocation(kPickPoint, false);
			}			
		}
	}

	function bool Key_Q( int ActionMask ){ return Dpad_Left( ActionMask );}
	function bool Key_E( int ActionMask ){ return Dpad_Right( ActionMask );}
	function bool Key_F( int ActionMask ){ return Dpad_Up( ActionMask );}
	function bool Key_C( int ActionMask ){ return Dpad_Down( ActionMask );}

	function bool Key_W( int ActionMask ){ return ArrowUp( ActionMask );}
	function bool Key_A( int ActionMask ){ return ArrowLeft( ActionMask );}
	function bool Key_S( int ActionMask ){ return ArrowDown( ActionMask );}
	function bool Key_D( int ActionMask ){ return ArrowRight( ActionMask );}

	function bool DPad_Right( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComTacticalController(Outer).YawCamera(-90.0);
		}
		return true;
	}

	function bool DPad_Left( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComTacticalController(Outer).YawCamera(90.0);
		}
		return true;
	}

	simulated function bool ArrowUp( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorUp))
			{
				DPad_Up(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}
	simulated function bool ArrowDown( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorDown))
			{
				DPad_Down(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}

	simulated function bool ArrowLeft( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateLeft))
			{
				DPad_Left(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}

	simulated function bool ArrowRight( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateRight))
			{
				DPad_Right(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}
}

// UITacticalHUD_AbilityContainer will handle most targeting method specific input work. Just do normal camera adjustment and scroll logic here.
// This is the state we are in when handling targeting an ability selected on the hud
state UsingTargetingMethod
{

	event BeginState( name nmPrevState )
	{
		local XCom3DCursor Cursor;

		super.BeginState(nmPrevState);

		Cursor = `CURSOR;
		Cursor.m_bCustomAllowCursorMovement = false;
		Cursor.m_bAllowCursorAscensionAndDescension = false;
	}
	
	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{
		super.PostProcessCheckGameLogic(DeltaTime);

		Controller_CheckForWindowScroll();
		Mouse_CheckForWindowScroll(DeltaTime);
		Mouse_FreeLook();
		Mouse_CheckForFreeAim();

		XComCamera(PlayerCamera).PostProcessInput();

		return true;
	}

	simulated function bool LMouse(int ActionMask)
	{
		local UITacticalHUD TacticalHUD;
		local X2TargetingMethod TargetingMethod;

		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			// check for left mouse clicks. It's very difficult to trap these properly in a movie screen, so process them here
			TacticalHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
			TargetingMethod = TacticalHUD.GetTargetingMethod();
			if(TargetingMethod != none && TargetingMethod.AllowMouseConfirm())
			{
				TacticalHUD.m_kAbilityHUD.ConfirmAbility();
				return true;
			}
		}

		return false;
	}

	simulated function Mouse_CheckForFreeAim()
	{
		local XComPresentationLayer pres;
		local IMouseInteractionInterface MouseTarget; 
		local XCom3DCursor Cursor; 
		local XComHUD HUD; 
		local XComUnitPawn kPawn; 
		local XGUnit kTargetUnit;
		local Vector kPickPoint;

		pres = XComPresentationLayer(XComTacticalController(Outer).Pres); 

		HUD = GetXComHUD();
		if( HUD == none ) return; 

		// update the free aim cursor location
		if( pres.Get2DMovie().IsMouseActive() && pres.GetTacticalHUD().IsMenuRaised())
		{ 
			MouseTarget = GetMouseInterfaceTarget();		
			if( MouseTarget == none ) return;

			Cursor = XComTacticalController(Outer).GetCursor();

			// try to find a unit to lock on to
			kPawn = XComUnitPawn(MouseTarget);	
			if( kPawn != none )
			{
				kTargetUnit = XGUnit(kPawn.GetGameUnit());
			}

			if( kTargetUnit != none ) 
			{
				// if we're highlighting a unit, lock the targeting cursor to it
				Cursor.CursorSetLocation( kTargetUnit.GetLocation(), false ); 
			}
			else if(GetAdjustedMousePickPoint(kPickPoint, false, false))
			{
				XComTacticalController(Outer).GetCursor().CursorSetLocation(kPickPoint, false);
			}			
		}
	}
	
	function bool Key_F( int ActionMask ){ return Dpad_Up( ActionMask );}
	function bool Key_C( int ActionMask ){ return Dpad_Down( ActionMask );}

	function bool Key_W( int ActionMask ){ return ArrowUp( ActionMask );}
	function bool Key_A( int ActionMask ){ return ArrowLeft( ActionMask );}
	function bool Key_S( int ActionMask ){ return ArrowDown( ActionMask );}
	function bool Key_D( int ActionMask ){ return ArrowRight( ActionMask );}

	function bool X_Button(int ActionMask)
	{
		return ActivateAbilityByHotKey(ActionMask, class'UIUtilities_Input'.const.FXS_KEY_R);
	}
	
	function bool Y_Button(int ActionMask)
	{				
		return ActivateAbilityByHotKey(ActionMask, class'UIUtilities_Input'.const.FXS_KEY_Y);
	}
	
	function bool Stick_R3(int ActionMask)
	{
		if (!UITacticalHUD(Get2DMovie().Pres.ScreenStack.GetScreen(class'UITacticalHUD')).SkyrangerButton.bIsVisible)
		{
			return false;
		}

		if (`REPLAY.bInTutorial)
		{
			if (`TUTORIAL.IsNextAbility('PlaceEvacZone'))
			{
				return ActivateAbilityByName(ActionMask, 'PlaceEvacZone');
			}
			else
			{
				return false;
			}
		}

		return ActivateAbilityByName(ActionMask, 'PlaceEvacZone');
	}
	function bool DPad_Up( int ActionMask )
	{
		local XCom3DCursor Cursor;
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			Cursor = XComTacticalController(Outer).GetCursor();
			Cursor.AscendFloor();
		}
		return true; 
	}

	function bool DPad_Down( int ActionMask )
	{
		local XCom3DCursor Cursor;
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			Cursor = XComTacticalController(Outer).GetCursor();
			Cursor.DescendFloor();
		}
		return true; 
	}

	function bool DPad_Left( int ActionMask )
	{
		return false;
	}
	function bool DPad_Right( int ActionMask )
	{
		return false;
	}

	function bool Key_E( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComTacticalController(Outer).YawCamera(-90.0);
		}
		return true;
	}

	function bool Key_Q( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComTacticalController(Outer).YawCamera(90.0);
		}
		return true;
	}

	simulated function bool ArrowUp( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorUp))
			{
				DPad_Up(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}
	simulated function bool ArrowDown( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorDown))
			{
				DPad_Down(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}

	simulated function bool ArrowLeft( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateLeft))
			{
				DPad_Left(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}

	simulated function bool ArrowRight( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateRight))
			{
				DPad_Right(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
state Multiplayer_Inactive
{
	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{
	//	return true;
		if( `XENGINE != none && `XENGINE.IsMoviePlaying(class'Engine'.static.GetLastMovieName()) )
		{
			return false;
		}

		//// disable cursor movement when its not my turn -tsmith 
		//aBaseY = 0.0f;
		//aStrafe = 0.0f;

		// we can always scroll, even if the action is blocking input. Looking around doesn't hurt anything
		if (PlayerCamera != none)
		{
			XComCamera(PlayerCamera).PostProcessInput();
		}

		Mouse_CheckForWindowScroll(DeltaTime);
		Mouse_FreeLook();

		// No input to gamecore if an action is being performed by the active unit
		//if( GetActiveUnit() != None && GetActiveUnit().GetAction() != none )
		//{
		//	if( XComPresentationLayer(XComTacticalController(Outer).Pres).m_kPostMatchSummary == none && !XComTacticalController(Outer).Pres.IsPauseMenuRaised() )
		//	{
		//		if( GetActiveUnit().GetAction().BlocksInput() || GetActiveUnit().GetAction().IsModal() )
		//			return false;
		//	}
		//}

//`if(`notdefined(FINAL_RELEASE))
//		if( GetProtoUI() != none )
//		{
//			GetProtoUI().PostProcessInput( self, DeltaTime );
//			return false;
//		}
//`endif

		if( `TACTICALGRI == None || ! `BATTLE.IsPaused() )
		{
			if( XComPresentationLayer(XComTacticalController(Outer).Pres) == none || 
				(!XComPresentationLayer(XComTacticalController(Outer).Pres).Get2DMovie().DialogBox.TopIsModal()
				&& !XComPresentationLayer(XComTacticalController(Outer).Pres).IsPauseMenuRaised()) )
			{
				Controller_CheckForWindowScroll();
			}
		}
	
		return true;
	}

	simulated function bool PreProcessCheckGameLogic( int cmd , int ActionMask ) 
	{
		//// disable cursor movement when its not my turn -tsmith 
		//aBaseY = 0.0f;
		//aStrafe = 0.0f;

		if(cmd == class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP ||
		   cmd == class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN)
		{
			return false;
		}

		return super.PreProcessCheckGameLogic( cmd, ActionMask );
	}

	event BeginState(name PreviousStateName)
	{
		if( IsInState('Multiplayer_GameOver', true) )
		{
			PopState(); // Don't enter Multiplayer_Inactive when in Multiplayer_GameOver
		}

		m_bInputBlocked = false;
	}

	function bool Start_Button( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).UIPauseMenu(, true );
			return true;
		}
		return false;
	}

	function bool Key_Z(int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraOut();
			return false;
		}

		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraIn();
			return false;
		}

		return false;
	}
	function bool Trigger_Left( float fTrigger, int ActionMask )
	{	
		//if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		//{
		//	XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraOut();
		//	return false;
		//}

		//if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		//{
		//	XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraIn();
		//	return false;
		//}

		return false;
	}

	function bool Key_T( int ActionMask )
	{
		XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraScroll( false );
		return true; 
	}
	function bool Key_G( int ActionMask )
	{
		XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraScroll( true );
		return true; 
	}

	function bool Key_E( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(-90.0);
		return false;
	}
	function bool Key_Q( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(90.0);
		return false;
	}

	function bool DPad_Right( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(-90.0);
		return false;
	}
	function bool DPad_Left( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(90.0);
		return false;
	}
	function bool DPad_Up( int ActionMask )
	{
		local XCom3DCursor Cursor;
		local int iMASK;

		iMASK = class'UIUtilities_Input'.const.FXS_ACTION_RELEASE;	

		if (( ActionMask & iMASK) != 0)
		{
			//XComTacticalController(Outer).PerformMoveModeChange( eMove_Fast );

			Cursor = XComTacticalController(Outer).GetCursor();
			Cursor.AscendFloor();
		}
		return false;
	}
	function bool DPad_Down( int ActionMask )
	{
		local XCom3DCursor Cursor;
		local int iMASK;

		iMASK = class'UIUtilities_Input'.const.FXS_ACTION_RELEASE;

		if (( ActionMask & iMASK) != 0)
		{
			//XComTacticalController(Outer).PerformMoveModeChange( eMove_Normal );

			Cursor = XComTacticalController(Outer).GetCursor();
			Cursor.DescendFloor();
		}
		return false;
	}
	
	function bool EscapeKey( int ActionMask )
	{
		return Start_Button(ActionMask);
	}
	
	function bool Key_W( int ActionMask ){ return ArrowUp( ActionMask );}
	function bool Key_A( int ActionMask ){ return ArrowLeft( ActionMask );}
	function bool Key_S( int ActionMask ){ return ArrowDown( ActionMask );}
	function bool Key_D( int ActionMask ){ return ArrowRight( ActionMask );}
	
	function bool Key_F( int ActionMask ){ return Dpad_Up( ActionMask );}
	function bool Key_C( int ActionMask ){ return Dpad_Down( ActionMask );}

	simulated function bool ArrowUp( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorUp))
			{
				DPad_Up(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}
	simulated function bool ArrowDown( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorDown))
			{
				DPad_Down(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}

	
	simulated function bool ArrowLeft( int ActionMask )

	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateLeft))
			{
				Key_Q(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}

	simulated function bool ArrowRight( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateRight))
			{
				Key_E(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}
}

//-----------------------------------------------------------
state Multiplayer_GameOver
{
	event BeginState(name PreviousStateName)
	{
		local OnlineSystemInterface OnlineSystem;
		m_bInputBlocked = false;
		
		// Clear repeat timers to prevent issues when the player opens the Steam Interface from a gamepad 
		if(!WorldInfo.IsConsoleBuild() && !Get2DMovie().IsMouseActive())
		{
			OnlineSystem = class'GameEngine'.static.GetOnlineSubsystem().SystemInterface;
			OnlineSystem.AddExternalUIChangeDelegate(OnExternalUIChanged);
		}
	}

	// Crash avoidance logic:
	event EndState(name PreviousStateName)
	{
		Cleanup();
	}
	event Cleanup()
	{
		local OnlineSystemInterface OnlineSystem;
		// Cleanup 'ExternalUIChangeDelegate'
		if(!WorldInfo.IsConsoleBuild() && !Get2DMovie().IsMouseActive())
		{
			OnlineSystem = class'GameEngine'.static.GetOnlineSubsystem().SystemInterface;
			OnlineSystem.ClearExternalUIChangeDelegate(OnExternalUIChanged);
		}
	}

	function OnExternalUIChanged(bool bIsOpening)
	{
		ClearAllRepeatTimers();
	}

	simulated function bool PreProcessCheckGameLogic( int cmd , int ActionMask ) 
	{
		return true;
	}

	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{
		Mouse_CheckForWindowScroll(DeltaTime);
		Mouse_FreeLook();
		Controller_CheckForWindowScroll();
		return true;
	}
}
//-----------------------------------------------------------
//-----------------------------------------------------------

private function QuicksaveComplete(bool bWasSuccessful)
{
	if( !bWasSuccessful )
		`PRES.PlayUISound(eSUISound_MenuClose);
}

function bool Start_Button(int ActionMask)
{
	if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 )
	{
		XComPresentationLayer(XComTacticalController(Outer).Pres).UIPauseMenu(, true);
		return true;
	}
	return false;
}

function bool EscapeKey(int ActionMask)
{
	return Start_Button(ActionMask);
}

// simple null state for blocking input while non-gameplay-safe things are being visualized
state Cinematic
{
	event Tick(float DeltaTime)
	{
		if(!XComTacticalController(Outer).m_bInCinematicMode)
		{
			if(GetActiveUnit() != none)
			{
				XComTacticalController(Outer).SetInputState('ActiveUnit_Moving');
			}
			else
			{
				XComTacticalController(Outer).SetInputState('Multiplayer_Inactive');
			}
		}
	}
	//The outer PostProcessCheckGameLogic does nothing and returns false, causing joystick events not to be processed.
	//This is a problem when we're hacking, as we're in the Cinematic state here but need those stick events for the hacking UI.
	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{	
		if( `XENGINE != none && `XENGINE.IsMoviePlaying(class'Engine'.static.GetLastMovieName()) )
		{
			return false;
		}

		return true;
	}
}

// This state controls input when the unit is pathing.
state ActiveUnit_Moving
{
	event BeginState( name nmPrevState )
	{
		local XGUnit ActiveUnit;
		local XCom3DCursor Cursor;
		local XComTutorialMgr TutorialMgr;

		super.BeginState(nmPrevState);
		Cursor = `CURSOR;
		Cursor.m_bCustomAllowCursorMovement = true;
		Cursor.m_bAllowCursorAscensionAndDescension = true;

		// show the pathing pawn and pathing tile border
		ActiveUnit = GetActiveUnit();
		if (ActiveUnit != none)
		{
			XComTacticalController(Outer).m_kPathingPawn.SetActive(ActiveUnit);
		}

		if( WorldInfo.IsPlayInEditor() )
		{
			XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).SetIsMouseActive(true);
		}
		
		if( `ISCONTROLLERACTIVE == false )
		{
			SetPathingUIVisible(true, true);
			XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).HideInputButtonRelatedHUDElements(false);
		}
		else
		{
			//show here
			if(`REPLAY.bInTutorial)
			{
				TutorialMgr = XComTutorialMgr(`REPLAY);
				if(TutorialMgr != None)
				{
					SetPathingUIVisible(true, true);
					XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).HideInputButtonRelatedHUDElements(false);
				}
			}
			else
			{
				SetPathingUIVisible(true, true);
				XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).HideInputButtonRelatedHUDElements(false);
			}
		}
		
		//putting call here because the handling is in this class
		UITacticalHUD(Get2DMovie().Pres.ScreenStack.GetScreen(class'UITacticalHUD')).UpdateNavHelp();
	}

	event EndState(Name NextStateName)
	{
		local XComTutorialMgr TutorialMgr;
		super.EndState(NextStateName);

		CancelMousePathing();

		if(NextStateName != 'ActiveUnit_Moving' && NextStateName != 'InReplayPlayback')
		{
			// don't hide the ui for one frame if we're just going into active movement on another unit. It will flicker.
			SetPathingUIVisible(false, false);
			if(`REPLAY.bInTutorial)
			{
				TutorialMgr = XComTutorialMgr(`REPLAY);
				if(TutorialMgr != None)
				{
					XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).HideInputButtonRelatedHUDElements(true);
				}
			}
			else
			{
				XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).HideInputButtonRelatedHUDElements(true);
			}
		}
	}

	simulated private function SetPathingUIVisible(bool RibbonVisible, bool BorderVisible)
	{
		local XComWorldData WorldData;
		local XComLevelVolume LevelVolume;
		local XComPresentationLayer Pres;
		local XCom3DCursor Cursor;

		// hide the pathing pawn and movement border
		XComTacticalController(Outer).m_kPathingPawn.SetVisible(RibbonVisible);

		WorldData = class'XComWorldData'.static.GetWorldData();
		LevelVolume = WorldData.Volume;
		`assert(LevelVolume != none); // how do we not have a level volume?

		LevelVolume.BorderComponent.SetUIHidden(!BorderVisible);
		LevelVolume.BorderComponentDashing.SetUIHidden(!BorderVisible);
		
		// Show the movement icons and border
		Cursor = `CURSOR;
		Pres = `PRES;
		Pres.GetActionIconMgr().ShowIcons(RibbonVisible);
		Pres.GetLevelBorderMgr().ShowBorder(BorderVisible);

		if (Cursor.bHidden != !RibbonVisible && !Pres.IsPauseMenuRaised())
		{
			Cursor.SetHidden(!RibbonVisible);
		}	
	}

	function bool IsManualUnitSwitchAllowed()
	{
		local XComGameStateVisualizationMgr VisualizationManager;

		if(class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableUnitSwitching)
		{
			return false;
		}

		// if ability activation is blocked, so is unit tabbing
		VisualizationManager = `XCOMVISUALIZATIONMGR;
		return !VisualizationManager.VisualizerBlockingAbilityActivation(true);
	}

	event Tick(float DeltaTime)
	{
		local XComGameStateVisualizationMgr VisualizationManager;
		local XComGameState_Unit ActiveUnitState;
		local XComPresentationLayer Pres; 
		local XCom3DCursor Cursor;
		local XComTutorialMgr TutorialMgr;
		local bool HideRibbon;
		local bool HideBorder;

		super.Tick(DeltaTime);

		// Update the movement icons and border
		Cursor = `CURSOR;
		Pres = `PRES;
		Pres.GetActionIconMgr().UpdateCursorLocation();
		Pres.GetLevelBorderMgr().UpdateCursorLocation(Cursor.Location);

		if(XComTacticalController(Outer).m_bInCinematicMode)
		{
			XComTacticalController(Outer).SetInputState('Cinematic');
		}

		// update pathing ui visibiliy

		ActiveUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetActiveUnit().ObjectID));

		// determine border hide
		VisualizationManager = `XCOMVISUALIZATIONMGR;
		HideBorder = VisualizationManager.IsActorBeingVisualized(GetActiveUnit()) 
			|| ActiveUnitState.NumActionPointsForMoving() == 0
			|| ActiveUnitState.GetCurrentStat(eStat_Mobility) == 0
			|| Cursor.m_bCustomAllowCursorMovement == false; //DISPLAYING_GAMEPAD_BUTTON_IN_TACTICAL_UI_ONLY_WHEN_APPROPRIATE kmartinez 2016-03-28
		HideBorder = HideBorder || (ActiveUnitState.NumActionPointsForMoving() == 0) || ActiveUnitState.bRemovedFromPlay;
		HideBorder = HideBorder || VisualizationManager.VisualizerBlockingAbilityActivation();
		HideBorder = HideBorder || `CAMERASTACK.ActiveCameraHidesBorder();
		HideBorder = HideBorder || `TACTICALRULES.BuildingLatentGameState; // || VisualizationManager.BuildingLatentGameState;

		// determine pathing ribbon hide
		HideRibbon = HideBorder || Cursor.m_bCustomAllowCursorMovement == false || TestMouseConsumedByFlash();

		if(`REPLAY.bInTutorial)
		{
			TutorialMgr = XComTutorialMgr(`REPLAY);
			if(TutorialMgr != None)
			{
				HideRibbon = !TutorialMgr.bIsTutorialAllowingControls;
				HideBorder = !TutorialMgr.bIsTutorialAllowingControls;
			}
		}

		if(!HideBorder && m_bPrevBorderHidden)
		{
			XComTacticalController(Cursor.GetALocalPlayerController()).m_kPathingPawn.UpdateTileCacheVisuals();
			m_bPrevBorderHidden = false;
		}
		else if(HideBorder)
		{
			m_bPrevBorderHidden = true;
		}

		SetPathingUIVisible(!HideRibbon, !HideBorder);
	}

	// Only called while unit is performing action
	function Abort()
	{
	}

	simulated function bool PreProcessCheckGameLogic( int cmd , int ActionMask ) 
	{
		local bool bPauseMenuRaised;
		local XComPresentationLayerBase kPres;

		kPres = XComTacticalController(Outer).Pres;

		bPauseMenuRaised = kPres.IsPauseMenuRaised();
	
		// Make sure that the pause menu shows up when moving.
		if ( bPauseMenuRaised )
		{
			return true;
		}

		return super.PreProcessCheckGameLogic( cmd, ActionMask );
	}

	function CheckForControllerInteraction()
	{
		local XGUnit kActiveUnit;
		local XComGameState_Unit kUnitState;
		local GameRulesCache_Unit kUnitRules;
		local XComGameState_Ability kAbility;
		local AvailableAction kAction;
		local XComGameStateContext kAbilityContext;

		// grab all the data we need. bail if we don't have a unit, or an interaction target, etc
		kActiveUnit = GetActiveUnit();
		kUnitState = ( kActiveUnit != none ) ? XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID)) : none;	
		if( kUnitState == none || !`TACTICALRULES.GetGameRulesCache_Unit(kUnitState.GetReference(), kUnitRules ) )
		{
			return;
		}

		foreach kUnitRules.AvailableActions(kAction)
		{
			kAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID));
			if (kAbility != none && kAbility.GetMyTemplateName() == 'Interact')
			{
				kAbilityContext = kAbility.GetParentGameState().GetContext();
				kAbilityContext.SetSendGameState(true);
				class'XComGameStateContext_Ability'.static.ActivateAbility(kAction);
				kAbilityContext.SetSendGameState(false);
				break;
			}
		}
		
		foreach kUnitRules.AvailableActions(kAction)
		{
			kAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID));
			if (kAbility != none && kAbility.GetMyTemplateName() == 'Hack')
			{
				kAbilityContext = kAbility.GetParentGameState().GetContext();
				kAbilityContext.SetSendGameState(true);
				class'XComGameStateContext_Ability'.static.ActivateAbility(kAction);
				kAbilityContext.SetSendGameState(false);
				break;
			}
		}
	}

	function bool A_Button( int ActionMask )
	{
		if( `ISCONTROLLERACTIVE() )
		{
			if( XComTacticalController(Outer).m_kPathingPawn.CursorOnOriginalUnit() )
			{
				return false;
			}
		
			return RMouse(ActionMask);
		}
		else
		{
			if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 )
			{
				m_bReceivedPress = true;
			}
			// IF( Button was held down )
			else if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_HOLD) != 0 )
			{
				if( !m_bReceivedPress ) return true;

				if( XComTacticalController(Outer).CheatManager != none && class'Engine'.static.IsConsoleAllowed() )
				{
					XComTacticalController(Outer).ServerTeleportActiveUnitTo(XComCheatManager(XComTacticalController(Outer).CheatManager).GetCursorLoc());
					m_bReceivedPress = false;
				}
				return true;
			}
			else
			if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 )
			{
				m_bReceivedPress = false;
			}
		}
		return false;
	}
	function bool B_Button( int ActionMask )
	{
		if (XComTacticalController(Outer).m_kPathingPawn.Waypoints.Length > 0)
		{
			XComTacticalController(Outer).m_kPathingPawn.ClearAllWaypoints();
			XComTacticalController(Outer).m_kPathingPawn.SetWaypointModifyMode(false);
		}
		return false;
	}
	
	function bool Key_X( int Actionmask )
	{
		return X_Button( Actionmask );
	}
	function bool X_Button( int ActionMask )
	{
		if( `ISCONTROLLERACTIVE() )
		{
			
			return ActivateAbilityByHotKey(ActionMask, class'UIUtilities_Input'.const.FXS_KEY_R);
		}
		else
		{

			if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			{
				XComTacticalController(Outer).m_kPathingPawn.SetWaypointModifyMode(true);

				ClickToAddOrRemoveWaypoint();

				if (XComTacticalController(Outer).m_kPathingPawn.Waypoints.Length <= 0)
				{
					XComTacticalController(Outer).m_kPathingPawn.SetWaypointModifyMode(false);
				}

				return true;
			}

			return false;
		}
	}

	function bool Key_R( int ActionMask )
	{				
		return ActivateAbilityByHotKey(ActionMask, class'UIUtilities_Input'.const.FXS_KEY_R);
	}
	function bool Key_Y( int ActionMask )
	{
		return Y_Button(ActionMask);
	}
	function bool Y_Button( int ActionMask )
	{				
		// For consistency, 2K asked for consistency between PC and Console, so we should be able to switch to a different unit and Overwatch while the first unit is pathing. (kmartinez)
		if (`ISCONTROLLERACTIVE() == false || (!`XCOMVISUALIZATIONMGR.VisualizerBlockingAbilityActivation() ))// && !`XCOMVISUALIZATIONMGR.VisualizerBusy()))
		{
			return ActivateAbilityByHotKey(ActionMask, class'UIUtilities_Input'.const.FXS_KEY_Y);
		}
		return false;
	}
	function bool Mouse4( int ActionMask )
	{
		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			NextUnit();
		}

		return false;
	}

	function bool Bumper_Right( int ActionMask )
	{
		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			NextUnit();
		}

		return false;
	}
	function bool NextUnit()
	{
		// Don't allow unit changes when the unit is locked.
		if( !IsManualUnitSwitchAllowed() )
		{
			return false;
		}

		if (`XCOMVISUALIZATIONMGR.VisualizerBusy())
		{
			XComTacticalController(Outer).bManuallySwitchedUnitsWhileVisualizerBusy = true;
		}

		XComTacticalController(Outer).Visualizer_SelectNextUnit();

		return true;
	}

	function bool Mouse5( int ActionMask )
	{
		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			PrevUnit();
		}

		return false;
	}
	function bool Bumper_Left( int ActionMask )
	{

		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			PrevUnit();
		}

		return false;
	}
	function bool Key_Left_Shift( int ActionMask )
	{

		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			PrevUnit();
		}

		return false;
	}
	function bool PrevUnit()
	{
		// Don't allow unit changes when the unit is locked.
		if( !IsManualUnitSwitchAllowed() )
		{
			return false;
		}

		if (`XCOMVISUALIZATIONMGR.VisualizerBusy())
		{
			XComTacticalController(Outer).bManuallySwitchedUnitsWhileVisualizerBusy = true;
		}

		XComTacticalController(Outer).Visualizer_SelectPreviousUnit();
		
		return true; 
	}
	
	function bool Key_Spacebar( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			OpenShotHUD();
			return true; 
		}
		return false;
	}

	function bool Trigger_Right( float fTrigger, int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			if( XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD().IsMenuRaised() )
				CloseShotHUD();
			else
				OpenShotHUD();
		}	
		return false;
	}

	function bool Key_Tab( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			if (PressedKeys.Find('LeftShift') != INDEX_NONE || PressedKeys.Find('RightShift') != INDEX_NONE)
			{
				PrevUnit();
			}
			else
			{
				NextUnit();
			}
		}
		return false;
	}

	private function OpenShotHUD()
	{
		local int abilityIdxToSelect;
		if(XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD().m_kAbilityHUD.IsEmpty())
		{
			//Show a help message that no abilities are currently available 
			XComTacticalController(Outer).Pres.QueueStandardMessage( m_sHelpNoAbilitiesAvailable,,,2.0,,);
		}
		else
		{
			//Begin targeting / activating the ShotHUD
			abilityIdxToSelect = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD().m_kAbilityHUD.GetFirstUsableAbilityIdx();
			XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD().m_kAbilityHUD.SelectAbility(abilityIdxToSelect);
		}
	}
	private function CloseShotHUD()
	{
		XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD().LowerTargetSystem(true);
	}
	
	function bool Key_P(int ActionMask)
	{
		local UITacticalHUD kHUD;

		kHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
		kHUD.m_kMouseControls.ActivateCommandAbility(0);

		return true;
	}

	function bool Key_L(int ActionMask)
	{
		local UITacticalHUD kHUD;

		kHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
		kHUD.m_kMouseControls.ActivateCommandAbility(1);

		return true;
	}

	function bool Key_K(int ActionMask)
	{
		local UITacticalHUD kHUD;

		kHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
		kHUD.m_kMouseControls.ActivateCommandAbility(2);

		return true;
	}

	function bool Key_M(int ActionMask)
	{
		local UITacticalHUD kHUD;

		kHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
		kHUD.m_kMouseControls.ActivateCommandAbility(3);

		return true;
	}

	function bool Key_N(int ActionMask)
	{
		local UITacticalHUD kHUD;

		kHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
		kHUD.m_kMouseControls.ActivateCommandAbility(4);

		return true;
	}

	function bool Key_Z(int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraOut();
			return false;
		}

		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraIn();
			return false;
		}

		return false;
	}
	function bool Trigger_Left( float fTrigger, int ActionMask )
	{	
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraOut();
			return false;
		}

		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraIn();
			return false;
		}

		return false;
	}

	

	function bool Stick_R3( int ActionMask )
	{		if (!UITacticalHUD(Get2DMovie().Pres.ScreenStack.GetScreen(class'UITacticalHUD')).SkyrangerButton.bIsVisible)
		{
			return false;
		}

		if(`REPLAY.bInTutorial)
		{
			//we can't place an evac zone till we reach a certain point in the tutorial.
			if(`TUTORIAL.IsNextAbility('PlaceEvacZone'))
				return ActivateAbilityByName(ActionMask, 'PlaceEvacZone');
			else
				return false;
		}
		
		return ActivateAbilityByName(ActionMask, 'PlaceEvacZone');
	}
	function bool Stick_L3( int ActionMask )
	{
		local UITacticalCharInfoScreen TactCharScreen;
		local UIMovie Movie; 
		Movie = Get2DMovie();
		if (!Movie.Pres.ScreenStack.IsInStack(class'UITacticalCharInfoScreen'))
		{
			TactCharScreen = Spawn(class'UITacticalCharInfoScreen', Movie.Pres.ScreenStack.GetCurrentScreen());
			bWasHUDVisible = XComTacticalController(Outer).GetPres().GetTacticalHUD().bIsVisible;
			XComTacticalController(Outer).GetPres().GetTacticalHUD().Hide();
			TactCharScreen.InitCharacterInfoScreen(XComPlayerController(Movie.Pres.Owner), Movie);
			Movie.Pres.ScreenStack.Push(TactCharScreen);

			return true;
		}

		return false;
	}
	
	function bool Key_W( int ActionMask ){ return ArrowUp( ActionMask );}
	function bool Key_A( int ActionMask ){ return ArrowLeft( ActionMask );}
	function bool Key_S( int ActionMask ){ return ArrowDown( ActionMask );}
	function bool Key_D( int ActionMask ){ return ArrowRight( ActionMask );}
	
	function bool Key_F( int ActionMask ){ return Dpad_Up( ActionMask );}
	function bool Key_C( int ActionMask ){ return Dpad_Down( ActionMask );}

	function bool DPad_Right( int ActionMask )
	{ 

		return Key_E(ActionMask);
	}
	function bool DPad_Left( int ActionMask )
	{ 

		return Key_Q(ActionMask);
	}

	function bool Key_E( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(-90.0);
		return false;
	}
	function bool Key_Q( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			XComTacticalController(Outer).YawCamera(90.0);
		return false;
	}
	function bool DPad_Up( int ActionMask )
	{
		local XCom3DCursor Cursor;
		local int iMASK;

		iMASK = class'UIUtilities_Input'.const.FXS_ACTION_RELEASE;	

		if (( ActionMask & iMASK) != 0)
		{
			//XComTacticalController(Outer).PerformMoveModeChange( eMove_Fast );

			Cursor = XComTacticalController(Outer).GetCursor();
			Cursor.AscendFloor();
		}
		return false;
	}
	function bool DPad_Down( int ActionMask )
	{
		local XCom3DCursor Cursor;
		local int iMASK;

		iMASK = class'UIUtilities_Input'.const.FXS_ACTION_RELEASE;

		if (( ActionMask & iMASK) != 0)
		{
			//XComTacticalController(Outer).PerformMoveModeChange( eMove_Normal );

			Cursor = XComTacticalController(Outer).GetCursor();
			Cursor.DescendFloor();
		}
		return false;
	}
	function bool Back_Button( int ActionMask )
	{

		if(`TUTORIAL != None)
			return true;

		if( ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 )
		{
			if(WorldInfo.NetMode != NM_Client)
			{
				if( XComTacticalController(Outer).GetPres().GetTacticalHUD().IsMenuRaised() )
					XComTacticalController(Outer).GetPres().GetTacticalHUD().CancelTargetingAction();

				XComTacticalController(Outer).PerformEndTurn(ePlayerEndTurnType_PlayerInput);
			}
			else
			{
				if(!XComTacticalController(Outer).GetPres().GetTacticalHUD().IsMenuRaised())
				{
					XComTacticalController(Outer).PerformEndTurn(ePlayerEndTurnType_PlayerInput);
				}
			}
			return true;
		}
		return true;
	}
	
	function bool Key_U( int ActionMask )
	{
		if ( ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0  )
		{
			return ClearAllWaypoints();
		}
		return true;
	}

	function bool Key_J( int ActionMask )
	{
		if ( ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0  )
		{
			return RemoveLastWaypoint();
		}
		return true;
	}

	function bool Key_Backspace(int ActionMask)
	{
		Back_Button(ActionMask);
		return true;
	}

	function bool Key_End(int ActionMask)
	{
		Back_Button(ActionMask);
		return true;
	}

	function bool Start_Button( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			bWasHUDVisible = XComTacticalController(Outer).GetPres().GetTacticalHUD().bIsVisible;
			XComTacticalController(Outer).GetPres().GetTacticalHUD().Hide();
			XComPresentationLayer(XComTacticalController(Outer).Pres).UIPauseMenu();
			UIPauseMenu(Get2DMovie().Pres.ScreenStack.GetScreen(class'UIPauseMenu')).OnCancel = OnPauseMenuCancel;
			
			return true;
		}
		return false;
	}

	function bool Key_Left_Control(int ActionMask)
	{
		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			XComTacticalController(Outer).m_kPathingPawn.SetWaypointModifyMode(false);
			return true;
		}
		else if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComTacticalController(Outer).m_kPathingPawn.SetWaypointModifyMode(true);
			return true;
		}

		return false;
	}

	function bool LMouse(int ActionMask)
	{
		local IMouseInteractionInterface MouseTarget; 
		local bool bHandled; 

		bHandled = false; 

		if(TestMouseConsumedByFlash()) return false;

		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			m_fRightMouseHoldTime = 0.0;

			// prevent spam of next/prev unit and end turn button to allow a next/prev unit command thru even though the player has ended turn -tsmith 
			//if(XComTacticalController(Outer).m_XGPlayer.IsInState('Active'))      //  we no longer use state on XGPlayer to control turn flow -jbouscher
			//{
				MouseTarget = GetMouseInterfaceTarget();		
				if( MouseTarget != none )
				{
					//Try to click a unit first
					bHandled = ClickSoldier(MouseTarget);

					//Loot comes before opponent targeting because it's a valid ability on dead targets! But we don't want to use the shot HUD
					if (!bHandled)
						bHandled = ClickLoot(MouseTarget);
	
					//See if we're trying to target an opponent 
					if( !bHandled ) 
						bHandled = ClickUnitToTarget(MouseTarget);

					// See if we're trying to click on an interactive object
					if( !bHandled ) 
						bHandled = ClickInterativeLevelActor(MouseTarget);

					if (!bHandled)
						bHandled = ClickTargetingMethod(MouseTarget);
			}
		}

		return bHandled;
	}

	function bool LDoubleClick( int ActionMask )
	{
		// Do nothing for now
		`log("LDoubleClick: ActionMask="$ActionMask,,'uixcom');
		return false;
	}

	function bool RMouse( int Actionmask )
	{
		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			m_fRightMouseHoldTime += 0.001; // give it just a little bit to indicate the button is held
			return true;
		}

		// bsg-mfawcett(10.03.16): support for waypoints when using controller
		if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_HOLD) != 0 )
		{
			if( m_fRightMouseHoldTime > 0.0 )
			{
				ClickToAddOrRemoveWaypoint();
				m_fRightMouseHoldTime = 0.0f;   // reset to 0 so that we do not trigger a move
			}
			return true;
		}

		if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			//On Release: Confirm the pathing line 
			if(IsKeyPressed(eTBC_Waypoint))
			{
				ClickToAddOrRemoveWaypoint();
			}
			else if(m_fRightMouseHoldTime > 0.0)
			{	
				ClickToPath();
			}
			return true;
		}
		return false;
	}

	function bool MMouse(int ActionMask)
	{
		if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 )
		{
			if(`CHEATMGR.bAllowFancyCameraStuff)
			{
				m_bMouseFreeLook = true;
			}
			else
			{
				XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraOut();
			}
		}
		else if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 )
		{
			m_bMouseFreeLook = false;
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraIn();
		}

		return true;
	}

	function bool Key_T( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraScroll( false );
			return true; 
		}
		return false;
	}
	function bool Key_G( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			XComPresentationLayer(XComTacticalController(Outer).Pres).ZoomCameraScroll( true );
			return true; 
		}
		return false;
	}
	function bool Key_V( int ActionMask )
	{
		return ActivateAbilityByHotKey(ActionMask, class'UIUtilities_Input'.const.FXS_KEY_V);
	}

	function bool SelectSoldier( int iIndex )
	{
		local XComGameStateHistory History;
		local XGUnit kTargetedUnit;
		local bool bHandled;
		local XGSquad kSquad; 
		local int iSquadSize; 

		if(!IsManualUnitSwitchAllowed())
		{
			return false;
		}

		if (`XCOMVISUALIZATIONMGR.VisualizerBusy())
		{
			XComTacticalController(Outer).bManuallySwitchedUnitsWhileVisualizerBusy = true;
		}

		kSquad = XComTacticalController(Outer).m_XGPlayer.GetSquad(); 
		iSquadSize = kSquad.GetNumMembers(); 

		if( iIndex >= iSquadSize ) return false; 

		//This is the next unit we want to set as active 
		kTargetedUnit = kSquad.GetMemberAt( iIndex ); 
		if( kTargetedUnit == none ) return false; 

		bHandled = false;
		if( XComTacticalController(Outer).m_XGPlayer.m_eTeam == kTargetedUnit.m_eTeam ) 
		{
			//`log("Want to target: " $ kTargetedUnit.GetHumanReadableName(),,'uixcom');
			
			// Select the targeted unit
			if( GetActiveUnit() != kTargetedUnit )
			{
				History = `XCOMHISTORY;
				bHandled =  XComTacticalController(Outer).Visualizer_SelectUnit(XComGameState_Unit(History.GetGameStateForObjectID(kTargetedUnit.ObjectID))); 
			}
			else
			{
				bHandled = true;
			}
		} 
		return bHandled; 
	}

	function bool Key_F1(int ActionMask) 
	{
		// Jacob said remove target enemy by F1-F8, if we want it back this is how we do it
		//return XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD().SelectTargetByHotKey(ActionMask, class'UIUtilities_Input'.const.FXS_KEY_F1);
		return false;
	}
	function bool Key_F2(int ActionMask)
	{
		return false;
	}
	function bool Key_F3(int ActionMask)
	{
		return false;
}
	function bool Key_F4(int ActionMask)
	{
		return false;
	}
	function bool Key_F5(int ActionMask) 
	{
		if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			`AUTOSAVEMGR.DoQuickSave();
			return true;
		} 
		return false;
	}
	function bool Key_F6(int ActionMask)
	{
		return false;
	}
	function bool Key_F7(int ActionMask)
	{
		return false;
	}
	function bool Key_F8(int ActionMask)
	{
		return false;
	}
	function bool Key_F9(int ActionMask)
	{
		if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		{
			`AUTOSAVEMGR.DoQuickLoad();
			return true;
		} 
		return false;
	}
	function bool Key_F10(int ActionMask)
	{
		return false;
	}	

	function bool ClickLoot( IMouseInteractionInterface MouseTarget )
	{
		local XComUnitPawn kPawn;
		local XComGameState_Unit ActiveUnitState, LootUnitState;
		local GameRulesCache_Unit LooterRules;
		local AvailableAction Action;
		local XComGameStateContext LootAbilityContext;
		local XComGameState_Ability LootAbility;
		local AvailableTarget Target;
		local bool bFoundLootAbility;
		local Actor HitActor;
		local Vector vHitLocation, vHitNormal;
		local TTile HitTile;
		local Lootable LootableObj;
		local XComGameState_BaseObject TestObject;

		ActiveUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetActiveUnit().ObjectID));	
		if (`TACTICALRULES.GetGameRulesCache_Unit(ActiveUnitState.GetReference(), LooterRules))
		{
			//  find the loot ability and confirm that it is available
			foreach LooterRules.AvailableActions(Action)
			{
				LootAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
				if (LootAbility != none && LootAbility.IsLootAbility())
				{
					LootAbilityContext = LootAbility.GetParentGameState().GetContext();
					LootAbilityContext.SetSendGameState(true);
					bFoundLootAbility = true;
					break;
				}
			}
			if (bFoundLootAbility && Action.AvailableCode == 'AA_Success')
			{
				kPawn = XComUnitPawn(MouseTarget);
				if (kPawn == none)
				{
					//  if we didn't click on a pawn, figure out where we hit and find something in lootable range
					//  this is necessary because a corpse won't necessarily be in the tile its position is in, but since we can't tell
					//  you clicked on the pawn (otherwise that's what the MouseTarget would be) we have to guess...
					HitActor = `XTRACEMGR.XTrace(eXTrace_AllActors, vHitLocation, vHitNormal, 
									  GetXComHUD().CachedMouseWorldOrigin + (GetXComHUD().CachedMouseWorldDirection * 100000.0f), 
									  GetXComHUD().CachedMouseWorldOrigin, vect(0,0,0));
					if (HitActor != none)
					{
						foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_BaseObject', TestObject)
						{
							LootableObj = Lootable(TestObject);
							if( LootableObj != none )
							{
								HitTile = LootableObj.GetLootLocation();
								vHitNormal = `XWORLD.GetPositionFromTileCoordinates(HitTile);
								if (VSize(vHitNormal - `XWORLD.GetPositionFromTileCoordinates(ActiveUnitState.TileLocation)) 
									<= class'X2Ability_DefaultAbilitySet'.default.LOOT_RANGE)
								{
									foreach Action.AvailableTargets(Target)
									{
										if (Target.PrimaryTarget.ObjectID == XComGameState_BaseObject(LootableObj).ObjectID)
										{
											class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0);
											LootAbilityContext.SetSendGameState(false);
											return true;
										}
									}
								}
							}
						}
					}
				}
				else if (kPawn != none)
				{
					//  confirm target for looting is also available
					LootUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kPawn.GetGameUnit().ObjectID));
					foreach Action.AvailableTargets(Target)
					{
						if (Target.PrimaryTarget.ObjectID == LootUnitState.ObjectID)
						{
							class'XComGameStateContext_Ability'.static.ActivateAbility(Action);
							LootAbilityContext.SetSendGameState(false);
							return true;
						}
					}
				}
			}
		}
		return false;
	}

	function bool ClickSoldier( IMouseInteractionInterface MouseTarget )
	{
		local XComGameStateHistory History;
		local XComGameState_Unit UnitState;
		local XComUnitPawnNativeBase kPawn; 
		local XGUnit kTargetedUnit;
		local bool bChangeUnitSuccess, bHandled;

		if(!IsManualUnitSwitchAllowed())
		{
			return false;
		}

		kPawn = XComUnitPawnNativeBase(MouseTarget);	
		if( kPawn == none ) return false; 

		//This is the next unit we want to set as active 
		kTargetedUnit = XGUnit(kPawn.GetGameUnit());
		if( kTargetedUnit == none ) return false; 

		bChangeUnitSuccess = false;
		bHandled = false;
		if( XComTacticalController(Outer).m_XGPlayer.m_eTeam == kTargetedUnit.m_eTeam ) 
		{
			//`log("Want to target: " $ kTargetedUnit.GetHumanReadableName(),,'uixcom');
			
			// Select the targeted unit
			if( GetActiveUnit() != kTargetedUnit && `TUTORIAL == none)
			{
				History = `XCOMHISTORY;
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kTargetedUnit.ObjectID));
				bChangeUnitSuccess = (UnitState != none) && XComTacticalController(Outer).Visualizer_SelectUnit(UnitState);
				kTargetedUnit.m_bClickActivated = bChangeUnitSuccess;
				bHandled = bChangeUnitSuccess;
			}
		} 
		return bHandled; 
	}
	simulated function bool ArrowUp( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorUp))
			{
				DPad_Up(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}
	simulated function bool ArrowDown( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Adjust Cursor Height
			if(IsKeyPressed(eTBC_CursorDown))
			{
				DPad_Down(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( 0, -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY );
			return true;
		}

		return false;
	}

	simulated function bool ArrowLeft( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateLeft))
			{
				DPad_Left(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}

	simulated function bool ArrowRight( int ActionMask )
	{
		// Only pay attention to presses or repeats
		if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
			|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
		{
			// Rotate Camera
			if(IsKeyPressed(eTBC_CamRotateRight))
			{
				DPad_Right(ActionMask);
				return true;
			}

			XComCamera(PlayerCamera).ScrollCamera( GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0 );
			return true;
		}

		return false;
	}

	simulated function bool EscapeKey( int ActionMask )
	{
		// Ignoring EscapeKey press, ShotHUD is raised. This prevents excessive Escape/Space combos which flood Targeting actions in MP. -ttalley
		if( XComTacticalController(Outer).GetPres().GetTacticalHUD().IsMenuRaised() )
		{
			return true;
		}

		if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 && ClearAllWaypoints() )
			return true;

		if( m_fRightMouseHoldTime > 0 )
		{
			if( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0  )
				CancelMousePathing();
			return true;
		}

		return Start_Button(ActionMask);
	}

	simulated function bool EnterKey( int ActionMask )
	{
		return Key_Spacebar(ActionMask);
	}
	
	simulated function bool Key_Home( int ActionMask )
	{
		local X2EventManager EventManager;

		if( ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0 )
		{
			EventManager = `XEVENTMGR;
			EventManager.TriggerEvent('CameraFocusActiveUnit');
		}
		return true; 
	} 

	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{		
		if( `XENGINE != none && `XENGINE.IsMoviePlaying(class'Engine'.static.GetLastMovieName()) )
		{
			return false;
		}

		if(m_fRightMouseHoldTime > 0.0)
		{
			m_fRightMouseHoldTime += DeltaTime;
		}

		// we can always scroll, even if the action is blocking input. Looking around doesn't hurt anything
		Mouse_CheckForWindowScroll(DeltaTime);
		Mouse_FreeLook();

		XComCamera(PlayerCamera).PostProcessInput();

//`if(`notdefined(FINAL_RELEASE))
//		if( GetProtoUI() != none )
//		{
//			GetProtoUI().PostProcessInput( self, DeltaTime );
//			return false;
//		}
//`endif

		if( !XComPresentationLayer(XComTacticalController(Outer).Pres).Get2DMovie().DialogBox.TopIsModal() &&
			!XComPresentationLayer(XComTacticalController(Outer).Pres).IsPauseMenuRaised())
		{
			Controller_CheckForWindowScroll();
		}
	
		Mouse_CheckForPathing(); 
		return true;
	}
Begin: 
}

function bool RemoveLastWaypoint()
{
	return XComTacticalController(Outer).m_kPathingPawn.RemoveLastWaypoint();
}

function bool ClearAllWaypoints()
{
	return XComTacticalController(Outer).m_kPathingPawn.ClearAllWaypoints();
}

function ClickToAddOrRemoveWaypoint()
{
	local Vector kPickPoint;

	if (`ISCONTROLLERACTIVE )
	{

		XComTacticalController(Outer).m_kPathingPawn.AddOrRemoveWaypoint(
			`XWORLD.GetPositionFromTileCoordinates(XComTacticalController(Outer).m_kPathingPawn.LastCursorTile));
	}
	else
	{
	
		if(GetAdjustedMousePickPoint(kPickPoint, GetActiveUnit().m_bIsFlying, true))
		{
			XComTacticalController(Outer).m_kPathingPawn.AddOrRemoveWaypoint(kPickPoint);
		}	

	}
}

function bool ClickToPath()
{
	local XComGameStateHistory History;
	local XComGameState_Unit ActiveUnitState;
	local XComGameState_Ability AbilityState;
	local GameRulesCache_Unit UnitCache;
	local XComPathingPawn PathingPawn;
	local array<TTile> WaypointTiles;
	local int ActionIndex;
	local int TargetIndex;
	local string ConfirmSound;

	if(`XCOMVISUALIZATIONMGR.VisualizerBlockingAbilityActivation())
	{
		return false;
	}

	PathingPawn = XComTacticalController(Outer).m_kPathingPawn;

	// try to do a melee attack
	History = `XCOMHISTORY;

	ActiveUnitState = XComGameState_Unit(History.GetGameStateForObjectID(GetActiveUnit().ObjectID));
	AbilityState = class'X2AbilityTrigger_EndOfMove'.static.GetAvailableEndOfMoveAbilityForUnit(ActiveUnitState);
	if(AbilityState != none 
		&& PathingPawn.LastTargetObject != none
		&& `TACTICALRULES.GetGameRulesCache_Unit(ActiveUnitState.GetReference(), UnitCache))
	{
		// find the melee ability's location in the action array
		ActionIndex = UnitCache.AvailableActions.Find('AbilityObjectRef', AbilityState.GetReference());
		`assert(ActionIndex != INDEX_NONE); // since GetAvailableEndOfMoveAbilityForUnit told us this was available, it had better be available

		// and the targeted unit's location
		TargetIndex = UnitCache.AvailableActions[ActionIndex].AvailableTargets.Find('PrimaryTarget', PathingPawn.LastTargetObject.GetReference());
		PathingPawn.GetWaypointTiles(WaypointTiles);
		if(TargetIndex != INDEX_NONE && class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[ActionIndex], TargetIndex,,, PathingPawn.PathTiles, WaypointTiles))
		{
			//If there is a ConfirmSound for the melee ability, play it
			ConfirmSound = AbilityState.GetMyTemplate().AbilityConfirmSound;
			if (ConfirmSound != "")
				`SOUNDMGR.PlaySoundEvent(ConfirmSound);

			XComTacticalController(Outer).m_kPathingPawn.OnMeleeAbilityActivated();
			return true;
		}
	}

	// we couldn't do a melee attack, so just do a normal path
	return XComTacticalController(Outer).PerformPath(GetActiveUnit(), true /*bUserCreated*/);
}

function XGUnit GetUnitFromInteractionInterface( IMouseInteractionInterface MouseTarget )
{
	local XComUnitPawnNativeBase kPawn; 
	local XGUnit kTargetedUnit;

	kPawn = XComUnitPawnNativeBase(MouseTarget);	
	if( kPawn == none ) return none; 

	// This is the unit we clicked on
	kTargetedUnit = XGUnit(kPawn.GetGameUnit());
	
	return kTargetedUnit;
}

function XComDestructibleActor GetDestructibleFromInteractionInterface( IMouseInteractionInterface MouseTarget )
{
	local XComDestructibleActor DestructibleActor; 
	DestructibleActor = XComDestructibleActor(MouseTarget);	
	return DestructibleActor;
}

//Available while moving or firing 
function bool ClickUnitToTarget( IMouseInteractionInterface MouseTarget )
{
	local XGUnit kTargetedUnit;
	local XGUnit kActiveUnit;	

	// This is the unit we clicked on
	kTargetedUnit = GetUnitFromInteractionInterface(MouseTarget);
	if( kTargetedUnit == none ) return false; 

	kActiveUnit = GetActiveUnit();
	if( kActiveUnit == none ) return false;

	return TargetUnit( kTargetedUnit );
}

//Called from clicking units in various locations of the interface/input systems. 
simulated function bool TargetUnit( XGUnit kTargetedUnit )
{
	local XGUnit kActiveUnit;
	local UITacticalHUD kHUD;
	local bool bIsTargetOnOurTeam;

	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;

	Ruleset = `XCOMGAME.GameRuleset;	
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(Outer).GetActiveUnitStateRef(), UnitInfoCache);

	kActiveUnit = GetActiveUnit();
	if( kActiveUnit == none ) return false;

	kHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();

	if(WorldInfo.NetMode != NM_Standalone && kHUD.m_kAbilityHUD.IsEmpty())
	{
		// due to the way ability UI is built on the clients, it may be empty because it hasnt been updated yet. -tsmith 
		kActiveUnit.MPForceUpdateAbilitiesUI();
	}
	if( kHUD.m_kAbilityHUD.IsEmpty() )
	{
		//Show a help message that no abilities are currently available
		XComTacticalController(Outer).Pres.QueueStandardMessage( m_sHelpNoAbilitiesAvailable,,,2.0,,);
		return false;
	}

	bIsTargetOnOurTeam = XComTacticalController(Outer).m_XGPlayer.m_eTeam == kTargetedUnit.m_eTeam;

	if( bIsTargetOnOurTeam )
	{
		// if attempting to target an ally without being in a targeted action, bail. We should be selecting them instead.
		return false;
	}

	// attempt to target the unit
	return kHud.m_kAbilityHUD.DirectTargetObjectWithDefaultTargetingAbility(kTargetedUnit.ObjectID);
}

simulated function bool ClickInterativeLevelActor( IMouseInteractionInterface MouseTarget )
{
	local UITacticalHUD kHUD;
	local XComInteractiveLevelActor kInteractiveLevelActor;

	kHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();
	
	// attempt to target the object
	kInteractiveLevelActor = XComInteractiveLevelActor( MouseTarget );
	if (kInteractiveLevelActor != none)
		return kHud.m_kAbilityHUD.DirectTargetObjectWithDefaultTargetingAbility(kInteractiveLevelActor.ObjectID, true);

	return false;
}

simulated function bool ClickTargetingMethod(IMouseInteractionInterface MouseTarget)
{
	local UITacticalHUD kHUD;

	kHUD = XComPresentationLayer(XComTacticalController(Outer).Pres).GetTacticalHUD();

	if(kHud.m_kAbilityHUD.IsTargetingMethodActivated())
		return kHud.m_kAbilityHUD.OnAccept();

	return false;
}

simulated function Mouse_CheckForPathing()
{
	local XComPresentationLayer pres;
	local Vector kPickPoint;
	local XGUnit ActiveUnit;

	pres = XComPresentationLayer(XComTacticalController(Outer).Pres); 

	if( pres.Get2DMovie().IsMouseActive())
	{
		ActiveUnit = GetActiveUnit();
		if(GetAdjustedMousePickPoint(kPickPoint, ActiveUnit.m_bIsFlying, false))
		{
			kPickPoint -= ActiveUnit.WorldSpaceOffset;
			XComTacticalController(Outer).GetCursor().CursorSetLocation(kPickPoint, false);
		}
	}
}

simulated function CancelMousePathing()
{
	local XComPresentationLayer kPres;

	if(!XComTacticalController(Outer).IsMouseActive()) return;

	XComTacticalController(Outer).m_kPathingPawn.ClearAllWaypoints();

	m_fRightMouseHoldTime = 0.0;

	kPres = XComPresentationLayer(XComTacticalController(Outer).Pres);
	if( kPres != none )
	{
		kPres.GetActionIconMgr().ClearCoverIcons();
	}
}

function DrawHUD( HUD HUD )
{
	// ???TMH - Does this need to be in an inventory state?
	// Necessary as TacticalInput is currently raised when the placeholder main menu is up.
	if ( XComTacticalController(Outer).Pres == none )
		return;

	XComTacticalController(Outer).DrawDebugData(HUD);
}

function bool SelectSoldier( int iIndex )
{
	return false;
}

function bool AttemptSteamControllerConfirm(int cmd)
{
	local IMouseInteractionInterface MouseTarget;
	local bool bHandled; 

	if( cmd != class'UIUtilities_Input'.const.FXS_BUTTON_A_STEAM || !IsControllerActive() ) return false;

	// Steam controller code below; this button was unused, try to make it an all-in-one targeting/pathing tool

	bHandled = super.AttemptSteamControllerConfirm(cmd);

	if( !bHandled )
	{
		MouseTarget = GetMouseInterfaceTarget();
		if( MouseTarget != none )
		{
			//Try to click a unit first
			bHandled = ClickSoldier(MouseTarget);

			//Loot comes before opponent targeting because it's a valid ability on dead targets! But we don't want to use the shot HUD
			if( !bHandled )
				bHandled = ClickLoot(MouseTarget);

			//See if we're trying to target an opponent 
			if( !bHandled )
				bHandled = ClickUnitToTarget(MouseTarget);

			// See if we're trying to click on an interactive object
			if( !bHandled )
				bHandled = ClickInterativeLevelActor(MouseTarget);
		}
		if( !bHandled )
		{
			ClickToPath();
		}
	}
	return bHandled; 
}


function bool ClickSoldier(IMouseInteractionInterface MouseTarget)
{
	return false;
}

function bool ClickLoot(IMouseInteractionInterface MouseTarget)
{
	return false;
}

simulated function OnPauseMenuCancel()
{
	if (bWasHUDVisible)
	{
		XComTacticalController(Outer).GetPres().GetTacticalHUD().Show();
	}
}
// Overriden in 'Multiplayer_GameOver' state
event Cleanup();

function bool HandleInputKey(int ControllerId, name Key, EInputEvent Event, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
	return false;
}

native function bool IsCurrentMatineeSkippable();
//-----------------------------------------------------------
//-----------------------------------------------------------
defaultproperties
{
	OnReceivedNativeInputKey = HandleInputKey

	AimSpeedMax=(X=1.5f,Y=1.5f)
	AimAccel=(X=0.4f,Y=0.4f)
	AimDecel=(X=10.0f,Y=10.0f)

	ScrollSpeedUnitsPerSecond=2000.0

	m_bMouseFreeLook=false

	m_bPrevBorderHidden=false
}
