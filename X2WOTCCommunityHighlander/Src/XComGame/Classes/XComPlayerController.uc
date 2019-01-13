// XCOM Player Controller
// 
// Used as a base for all game types in XCOM

class XComPlayerController extends XComPlayerControllerNativeBase
	dependson(XComContentManager)
	native(Core);

// Client specific data
var XComPresentationLayerBase           Pres;
var class<XComPresentationLayerBase>    PresentationLayerClass;

var private XComWeatherControl  m_kWeatherControl;
var private XComTerrainCaptureControl m_kTerrainCaptureControl;

// Checkpoint variables
var transient float LastCheckpointSaveTime;
var bool bProfileSettingsUpdated;

var bool bIsAcceptingInvite;
var bool bVoluntarilyDisconnectingFromGame;

var privatewrite bool bBlockingInputAfterMovie;

// For coming back after alt-tabbing.
var protected transient float m_fAltTabTime;

var transient bool m_bPauseFromLossOfFocus;
var transient bool m_bPauseFromGame;

var bool bDebugCameraOn;

//Seamless travel support
var private SeqEvent_OnTacticalIntro TacticalIntro;
var bool bSeamlessTravelDestinationLoaded;
var UIScreen BriefingScreen;
var array<XComUnitPawn> DropshipPawns; //List of pawns riding in the dropship, so we can destroy / clean them up when done.
var array<string> DropshipPawnVariables; //List of pawn variables we used, so we can cleanup
var bool bProcessedTravelDestinationLoaded;
var string MapImagePath;
var Object MapImage;

simulated function SetInputState( name nStateName, optional bool bForce );

//
// Network: Server only
//
// Called after a successful login. This is the first place
// it is safe to call replicated functions on the PlayerController.
//
// this is also the first place where its safe to test for being a local player controller on the server
event PostLogin()
{
	if( PlayerCamera == None && IsLocalPlayerController() ) 
	{
		if( CameraClass != None )
		{
			// Associate Camera with PlayerController
			PlayerCamera = Spawn(CameraClass, Self);
			if( PlayerCamera != None )
			{
				PlayerCamera.InitializeFor( Self );
			}
			else
			{
				`log("Couldn't Spawn Camera Actor for Player!!");
			}
		}
	}
}

/**
 * Called after this PlayerController's viewport/net connection is associated with this player controller.
 * It is valid to test for this player being a local player controller at this point.
 */
simulated event ReceivedPlayer()
{
	// NOTE: this function will be called multiple times for a given player login/connection -tsmith 
	super.ReceivedPlayer();

	if(IsLocalPlayerController())
	{
		InitPres();
		InitPostProcessChains();
	}
}

simulated function InitPostProcessChains()
{
	local LocalPlayer kLP;

	kLP = LocalPlayer(Player); 
	if(kLP != None) 
	{ 
		kLP.RemoveAllPostProcessingChains(); 
		kLP.InsertPostProcessingChain(kLP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
	}
}

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	SubscribeToOnCleanupWorld();
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	`if(`notdefined(FINAL_RELEASE))
		if ( WorldInfo.NetMode == NM_Client )
		{
				AddCheats();
		}
	`endif
}

event Destroyed()
{
	UnsubscribeFromOnCleanupWorld();
	Cleanup();

	super.Destroyed();
}

simulated event OnCleanupWorld()
{
	Cleanup();

	super.OnCleanupWorld();
}

simulated event Cleanup()
{
	//`log(`location @ `ShowVar(bIsAcceptingInvite));
	`ONLINEEVENTMGR.ClearBeginShellLoginDelegate(ShellLoginDuringGameInviteComplete);
	if (bIsAcceptingInvite)
	{
		`warn("Unable to complete ShellLogin prior to destruction! Notifying invite system of problem.");
		`ONLINEEVENTMGR.OnGameInviteComplete(SystemMessage_InviteSystemError, false);
	}

	// Cleanup delegates in XComTacticalInput
	if(XComTacticalInput(PlayerInput) != none)
	{
		XComTacticalInput(PlayerInput).Cleanup();
	}
}


`if(`notdefined(FINAL_RELEASE))
simulated function AddCheats(optional bool bForce)
{
	if(CheatManager == None)
	{
		CheatManager = new(Self) CheatClass;
	}
}
`endif

simulated function InitPres()
{
	if(Pres == none || PresentationLayerClass != Pres.Class)
	{
		Pres = Spawn( PresentationLayerClass, self,,,,,, m_eTeam );
		Pres.Init();
	}
}

simulated private function bool CanCommunicate()
{
	return OnlineSub.PlayerInterface.CanCommunicate(`ONLINEEVENTMGR.LocalUserIndex) == FPL_Enabled;
}

/**
 * Displays information to the user whenever an event occurs, like a player joins or leaves.
 */
reliable client event ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	// Wait for player to be up to date with replication when joining a server, before stacking up messages
	if ( WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.GRI == None )
		return;

	//Message.Static.ClientReceive( Self, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );  // BUG 7979: [ONLINE] - The host will see text overlap on the bottom of the lobby screen reading "____ Has entered the game" when a user joins their lobby.
}

reliable client event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime  )
{
	// Send the message to the MP hud
	if( `PRES != none && `PRES.m_kMultiplayerChatManager != none )
	{
		`PRES.m_kMultiplayerChatManager.AddMessage(PRI.PlayerName, S, PRI == GetALocalPlayerController().PlayerReplicationInfo);
	}
	else
	{
		// no chat hud, so just use the build in hud so we at least get client messages for
		// things like kismet debugging
`if(`notdefined(FINAL_RELEASE))
		super.TeamMessage(PRI, S, Type, MsgLifeTime);
`endif
	}
}

/*exec function LoadGame()
{
	XComGameInfo(WorldInfo.Game).LoadGame(iSlotId);
}*/

function bool AttemptGameInviteAccepted(const out OnlineGameSearchResult InviteResult, bool bWasSuccessful)
{
	// Clear any messages before transitioning to another map - sbatista
	`ONLINEEVENTMGR.ClearSystemMessages();
	return super.AttemptGameInviteAccepted(InviteResult, bWasSuccessful);
}

/**
 * Determine if there are any other functions that need to be called prior to loading into multiplayer lobby. -ttalley
 */
function StartAcceptGameInvite()
{
	//`log(`location @ `ShowVar(bIsAcceptingInvite) @ `ShowVar(`ONLINEEVENTMGR.IsReadyForMultiplayer()) @ `ShowVar(`ONLINEEVENTMGR.bInShellLoginSequence),,'XCom_Online');
	if (bIsAcceptingInvite)
	{
		return;
	}

	bIsAcceptingInvite = true;
	if ( `ONLINEEVENTMGR.IsReadyForMultiplayer() )
	{
		// Shell already logged-in (i.e. we're on any other screen than the start screen)
		super.StartAcceptGameInvite();
	}
	else if( `ONLINEEVENTMGR.bInShellLoginSequence )
	{
		// Delay the call to the super function until the shell login is complete. (i.e. we're probably on the start screen)
		`ONLINEEVENTMGR.AddBeginShellLoginDelegate(ShellLoginDuringGameInviteComplete);
	}
	else
	{
		// Begin the shell login sequence.
		// Delay the call to the super function until the shell login is complete. (i.e. we're probably on the start screen)
		`ONLINEEVENTMGR.AddBeginShellLoginDelegate(ShellLoginDuringGameInviteComplete);
		`ONLINEEVENTMGR.BeginShellLogin(LocalPlayer(Player).ControllerId);
	}
}


/**
 * Once the join completes, use the platform specific connection information
 * to connect to it
 *
 * @param SessionName the name of the session that was joined
 * @param bWasSuccessful whether the join worked or not
 */
function OnInviteJoinComplete(name SessionName,bool bWasSuccessful)
{
	local string URL;//, ConnectPassword;
	local ESystemMessageType eSystemError;

	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful), true, 'XCom_Online');

	ClearInviteDelegates();

	if (bWasSuccessful)
	{
		`ONLINEEVENTMGR.OnGameInviteComplete(SystemMessage_None, bWasSuccessful);

		// Set the online status for the MP menus
		`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_MainMenu);

		if (OnlineSub != None && OnlineSub.GameInterface != None)
		{
			// Get the platform specific information
			if (OnlineSub.GameInterface.GetResolvedConnectString(SessionName,URL))
			{
				URL $= "?bIsFromInvite";
				URL = ModifyClientURL(URL); // allow game to override

				`Log("Resulting url is ("$URL$")");
				// Open a network connection to it
				StartNetworkGame(SessionName, URL);
			}
		}
	}
	else
	{
		eSystemError = SystemMessage_InviteSystemError;
		if (SessionName == 'RoomFull' || SessionName == 'LobbyFull' || SessionName == 'GroupFull')
		{
			eSystemError = SystemMessage_GameFull;
		}

		`ONLINEEVENTMGR.OnGameInviteComplete(eSystemError, bWasSuccessful);

		// Clean-up session
		if (OnlineSub != None && OnlineSub.GameInterface != None)
		{
			OnlineSub.GameInterface.DestroyOnlineGame(SessionName);
		}
	}
	bIsAcceptingInvite=false;
}

private function ShellLoginDuringGameInviteComplete(bool bWasSuccessful)
{
	`log(`location @ `ShowVar(bWasSuccessful),,'XCom_Online');
	`ONLINEEVENTMGR.ClearBeginShellLoginDelegate(ShellLoginDuringGameInviteComplete);

	bIsAcceptingInvite=false;
	if( bWasSuccessful )
	{
		// This will run our MP ready check again then call super.StartAcceptGameInvite()
		// if it passes. Eventually FinishAcceptGameInvite() will be called.
		StartAcceptGameInvite();
	}
	else
	{
		FinishAcceptGameInvite(false);
	}
}

function FinishAcceptGameInvite(bool bWasSuccessful)
{
	`log(`location @ `ShowVar(bWasSuccessful),,'XCom_Online');
	super.FinishAcceptGameInvite(bWasSuccessful);
}

function NotifyInviteFailed()
{
	ScriptTrace();
	bIsAcceptingInvite=false;
	`ONLINEEVENTMGR.OnGameInviteComplete(SystemMessage_InviteSystemError, false);
	ClearInviteDelegates();
}

function NotifyNotAllPlayersCanJoinInvite()
{
	bIsAcceptingInvite=false;
	`ONLINEEVENTMGR.OnGameInviteComplete(SystemMessage_InvitePermissionsFailed, false);
}

function NotifyNotEnoughSpaceInInvite()
{
	bIsAcceptingInvite=false;
	bIgnoreNetworkMessages=true; // Ignore the disconnect message
	`ONLINEEVENTMGR.OnGameInviteComplete(SystemMessage_GameFull, false);
}

function bool StartNetworkGame(name SessionName, optional string ResolvedURL="")
{
	`log(`location,,'XComOnline');
	return Pres.StartNetworkGame(SessionName, ResolvedURL);
}

function SetCinematicMode( bool bInCinematicMode, bool bHidePlayer, bool bAffectsHUD, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsButtons, optional bool bDoClientRPC = true, optional bool bOverrideUserMusic = false )
{
	super.SetCinematicMode( bInCinematicMode, bHidePlayer, bAffectsHUD, bAffectsMovement, bAffectsTurning, bAffectsButtons, bDoClientRPC, bOverrideUserMusic );

	if( bOverrideUserMusic )
	{
		if( bInCinematicMode )
			EnterCinematicModeForUserAudio();
		else
			UpdateUserAudioForCinematicMode(false);
	}
	else
	{
		// we don't want to override the user's music, so ensure that cinematic mode is off (so the user music can play)
		UpdateUserAudioForCinematicMode(false);
	}
}

/** Enters cinematic mode for user audio but only after the loading screen is closed */
private simulated function EnterCinematicModeForUserAudio()
{
	if( `XENGINE.IsLoadingMoviePlaying() )
		SetTimer(0.1, false, 'EnterCinematicModeForUserAudio');
	else
		UpdateUserAudioForCinematicMode(true);
}

/** Starts or stops user music so as to not play over a cinematic */
private simulated native function UpdateUserAudioForCinematicMode(bool bInCinematicMode);

/**
 * Attempts to pause/unpause the game when a controller becomes
 * disconnected/connected
 *
 * @param ControllerId the id of the controller that changed
 * @param bIsConnected whether the controller is connected or not
 */
function OnControllerChanged(int ControllerId,bool bIsConnected)
{
	local LocalPlayer LP;

	// Don't worry about remote players
	LP = LocalPlayer(Player);

	// If the controller that changed, is attached to the this playercontroller
	if (LP != None
	&&	LP.ControllerId == ControllerId
	// do not pause if there is no controller when we are automatedperftesting
	&&	(WorldInfo.Game == None || !WorldInfo.Game.IsAutomatedPerfTesting()))
	{
		bIsControllerConnected = bIsConnected;

		`log("Received gamepad connection change for player" @ class'UIInteraction'.static.GetPlayerIndex(ControllerId) $ ": gamepad" @ ControllerId @ "is now" @ (bIsConnected ? "connected" : "disconnected"));
		
		if( bIsConnected )
		{
			OnControllerConnected();
		}
		else
		{
			OnControllerDisconnected();
		}
	}
}

/**
 * Called when the local player is about to travel to a new map or IP address.  Need to have the 
 * UI clean up anything prior to the travel.
 */
event PreClientTravel( string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel )
{
	super.PreClientTravel( PendingURL, TravelType, bIsSeamlessTravel );
	Pres.PreClientTravel( PendingURL, TravelType, bIsSeamlessTravel );
}

function bool CanUnpauseControllerConnected()
{
	if( Pres.IsPauseMenuRaised() ) //Don't permit the reconnection of a controller to unpause us while we're also at the pause menu.
		return false;

	return super.CanUnpauseControllerConnected();
}
simulated private function OnControllerConnected()
{
	 if( bIsControllerConnected )
	 {
		 if( Pres != none && Pres.IsPresentationLayerReady() )
		{
			Pres.UICloseControllerUnplugDialog();
		}

		if (!Pres.IsInState('State_PauseMenu', true))         //  only unpause if the pause menu isn't up
			SetPause(false, CanUnpauseControllerConnected);
	 }
}

simulated private function OnControllerDisconnected()
{
	local LocalPlayer LP;
	local bool bIsInShellOptions; 
	local string strGameClassName; 

	LP = LocalPlayer(Player);

	if( !bIsControllerConnected && LP != none )
	{
		if( Pres != none && Pres.IsPresentationLayerReady() &&
			!Pres.IsInState('State_ProgressDialog') &&
			!`XENGINE.IsMoviePlaying("1080_PropLoad_001") )
		{
			// Do not pause if we're on the start screen. We don't yet know which controller will be used.
			if( !Pres.IsInState('State_StartScreen') || WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
			{
				`log("Showing controller unplugged dialog",,'xcomui');
				SetPause(!Pres.IsA('XComShellPresentationLayer'), CanUnpauseControllerConnected); // Pause while showing the controller unplugged dialog if in gameplay
				strGameClassName = String(WorldInfo.GRI.GameClass.name);
				bIsInShellOptions = (Pres.IsInState('State_PCOptions', true) && (strGameClassName == "XComShell"));
				Pres.UIControllerUnplugDialog(LP.ControllerId, bIsInShellOptions );
			}
		}
		else
		{
			// If the presentation layer is not yet ready then show the dialog when it is.
			// This is necessary when the controller has been unplugged during a load screen.
			`log("Waiting to show controller unplugged dialog",,'xcomui');
			SetTimer(1, false, 'OnControllerDisconnected'); // Try again in 1 second
		}
	}
}

// creates/returns the singleton weather control -tsmith 
simulated function XComWeatherControl WeatherControl()
{
	local XComWeatherControl    kWeatherControl;

	if(m_kWeatherControl == none)
	{
		// sanity check, make sure there is only one WC -tsmith 
		foreach AllActors(class'XComWeatherControl', kWeatherControl) 
		{
			m_kWeatherControl = kWeatherControl;
			break;
		}
	}

	return m_kWeatherControl;
}

// creates/returns the singleton terrain capture control
simulated function XComTerrainCaptureControl TerrainCaptureControl()
{
	local XComTerrainCaptureControl    kTerrainCaptureControl;

	if (m_kTerrainCaptureControl == none)
	{
		// sanity check, make sure there is only one terrain capture control
		foreach AllActors(class'XComTerrainCaptureControl', kTerrainCaptureControl)
		{
			m_kTerrainCaptureControl = kTerrainCaptureControl;
			break;
		}
	}

	return m_kTerrainCaptureControl;
}

simulated native function ShowFog(bool bShow);

simulated function bool IsInCinematicMode();
simulated function bool IsStartingGame();
simulated function bool ShouldBlockPauseMenu()
{
	// Don't allow pause between continent select and mission briefing
	return IsStartingGame();
}

exec function ToggleDebugCamera()
{
	local float FOV;

	if( !class'Engine'.static.IsRetailGame() || class'Engine'.static.IsConsoleAllowed())
	{
		bDebugCameraOn = !bDebugCameraOn;
		if( bDebugCameraOn )
		{
			PlayerCamera.ClearAllCameraShakes();

			// field of view before changing state may be different from debug cam
			FOV = XComBaseCamera(PlayerCamera).GetFOVAngle();
			XComBaseCamera(PlayerCamera).PushState('DebugView');		
			XComBaseCamera(PlayerCamera).SetFOV(FOV);		
		}
		else
		{
			`log("Jake's Debug Camera Direction" @ vector(XComBaseCamera(PlayerCamera).CameraCache.POV.Rotation), , 'XComCameraMgr');

			XComBaseCamera(PlayerCamera).SetFOV(0); // unlock the FOV
			XComBaseCamera(PlayerCamera).PopState();
		}
	}
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                      INPUT
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// Movies don't always consume all input cleanly, and so sometimes events will cascade in to 
// the exec bindings system and fall here. This is blockign all inptu for the half second
// following a movie's end, and is triggered by the movie controls in the engine. 
simulated event BlockInputAfterMovie()
{
	bBlockingInputAfterMovie = true;
	SetTimer( 0.5f, false, 'UnblockInputAfterMovie' );
}
simulated function UnblockInputAfterMovie()
{
	bBlockingInputAfterMovie = false;
}
exec function A_Button_Press()
{
	if( bBlockingInputAfterMovie ) return; 

	if( class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive() )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_B );
	else
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_A );
}
exec function A_Button_Release()
{
	if( bBlockingInputAfterMovie ) return; 

	if( class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive() ) 
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_B, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
	else
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_A, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function B_Button_Press()
{
	if( class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive() )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_A );
	else
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_B );
}
exec function B_Button_Release()
{
	if( class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive() ) 
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_A, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
	else
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_B, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function X_Button_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_X );
}
exec function X_Button_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_X, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function Y_Button_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_Y );
}
exec function Y_Button_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_Y, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

exec function A_Button_Steam_Press()
{
	if( bBlockingInputAfterMovie ) return;

	XComInputBase(PlayerInput).InputEvent(class'UIUtilities_Input'.const.FXS_BUTTON_A_STEAM);
}
exec function A_Button_Steam_Release()
{
	if( bBlockingInputAfterMovie ) return;

	XComInputBase(PlayerInput).InputEvent(class'UIUtilities_Input'.const.FXS_BUTTON_A_STEAM, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
}


//---------------------------------------------------------------------------------------
exec function DPad_Right_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_DPAD_RIGHT );
}
exec function DPad_Right_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_DPAD_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function DPad_Left_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_DPAD_LEFT );
}
exec function DPad_Left_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_DPAD_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function DPad_Up_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_DPAD_UP );
}
exec function DPad_Up_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_DPAD_UP, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );
}
//---------------------------------------------------------------------------------------
exec function DPad_Down_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_DPAD_DOWN );
}
exec function DPad_Down_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_DPAD_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );
}
//---------------------------------------------------------------------------------------
exec function Back_Button_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_SELECT );
}
exec function Back_Button_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_SELECT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );
}
//---------------------------------------------------------------------------------------
exec function Forward_Button_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_START );
}
exec function Forward_Button_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_START, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );
}
//---------------------------------------------------------------------------------------
exec function Thumb_Left_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_L3 );
}
exec function Thumb_Left_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_L3, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );
}
//---------------------------------------------------------------------------------------
exec function Thumb_Right_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_R3 );
}
exec function Thumb_Right_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_R3, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );
}
//---------------------------------------------------------------------------------------
exec function Shoulder_Left_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER );
}
exec function Shoulder_Left_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function Shoulder_Right_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER );
}
exec function Shoulder_Right_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function Trigger_Left_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER );
}
exec function Trigger_Left_Release()
{
	XComInputBase(PlayerInput).Trigger_Left_Analog(0.0f);
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );
}
//---------------------------------------------------------------------------------------
exec function Trigger_Right_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER );
}
exec function Trigger_Right_Release()
{
	XComInputBase(PlayerInput).Trigger_Right_Analog(0.0f);
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function Left_Mouse_Button_Press()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN );
}
exec function Left_Mouse_Button_Release()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

//---------------------------------------------------------------------------------------
exec function Right_Mouse_Button_Press()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN );
}
exec function Right_Mouse_Button_Release()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

//---------------------------------------------------------------------------------------
exec function Middle_Mouse_Button_Press()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_M_MOUSE );
}
exec function Middle_Mouse_Button_Release()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_M_MOUSE, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

//---------------------------------------------------------------------------------------
exec function Mouse_Scroll_Up()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP );
}
exec function Mouse_Scroll_Up_Release()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

//---------------------------------------------------------------------------------------
exec function Mouse_Scroll_Down()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN );
}
exec function Mouse_Scroll_Down_Release()
{
	if( Pres.Get2DMovie().IsMouseActive () )
		XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
//---------------------------------------------------------------------------------------
exec function Mouse_4_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_MOUSE_4 );}
exec function Mouse_4_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_MOUSE_4, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Mouse_5_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_MOUSE_5 );}
exec function Mouse_5_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_MOUSE_5, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}

//---------------------------------------------------------------------------------------
exec function Arrow_Up()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_ARROW_UP );
}
exec function Arrow_Up_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_ARROW_UP, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

//---------------------------------------------------------------------------------------
exec function Arrow_Down()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_ARROW_DOWN );
}
exec function Arrow_Down_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_ARROW_DOWN, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

//---------------------------------------------------------------------------------------
exec function Arrow_Left()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_ARROW_LEFT );
}
exec function Arrow_Left_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_ARROW_LEFT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

//---------------------------------------------------------------------------------------
exec function Arrow_Right()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_ARROW_RIGHT );
}
exec function Arrow_Right_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_ARROW_RIGHT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

//---------------------------------------------------------------------------------------
exec function Escape_Key_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_ESCAPE );
}
exec function Escape_Key_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_ESCAPE, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}

exec function Pause_Key_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_PAUSE );
}
exec function Pause_Key_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_PAUSE, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}


//---------------------------------------------------------------------------------------
exec function Enter_Key_Press()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_ENTER );
}
exec function Enter_Key_Release()
{
	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_ENTER, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );
}
exec function ALT_F4_QUIT()
{
	ConsoleCommand("exit");
}
//---------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------
exec function F1_Key_Press()	{   XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F1 );}
exec function F1_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F1, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F2_Key_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F2 );}
exec function F2_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F2, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F3_Key_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F3 );}
exec function F3_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F3, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F4_Key_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F4 );}
exec function F4_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F4, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F5_Key_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F5 );}
exec function F5_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F5, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F6_Key_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F6 );}
exec function F6_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F6, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F7_Key_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F7 );}
exec function F7_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F7, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F8_Key_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F8 );}
exec function F8_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F8, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F9_Key_Press()    {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F9 );}
exec function F9_Key_Release()  {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F9, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F10_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F10 );}
exec function F10_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F10, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F11_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F11 );}
exec function F11_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F11, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F12_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F12 );}
exec function F12_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F12, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
exec function N1_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_1 );}
exec function N1_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_1, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N2_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_2 );}
exec function N2_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_2, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N3_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_3 );}
exec function N3_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_3, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N4_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_4 );}
exec function N4_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_4, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N5_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_5 );}
exec function N5_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_5, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N6_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_6 );}
exec function N6_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_6, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N7_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_7 );}
exec function N7_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_7, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N8_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_8 );}
exec function N8_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_8, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N9_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_9 );}
exec function N9_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_9, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function N0_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_0 );}
exec function N0_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_0, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
exec function NUMPAD1_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_1 );}
exec function NUMPAD1_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_1, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//--------------------------------------------------------------------------------------
exec function NUMPAD2_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_2 );}
exec function NUMPAD2_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_2, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function NUMPAD3_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_3 );}
exec function NUMPAD3_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_3, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function NUMPAD4_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_4 );}
exec function NUMPAD4_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_4, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function NUMPAD5_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_5 );}
exec function NUMPAD5_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_5, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function NUMPAD6_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_6 );}
exec function NUMPAD6_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_6, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function NUMPAD7_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_7 );}
exec function NUMPAD7_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_7, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function NUMPAD8_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_8 );}
exec function NUMPAD8_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_8, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function NUMPAD9_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_9 );}
exec function NUMPAD9_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_9, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
exec function NUMPAD0_Key_Press()   {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_0 );}
exec function NUMPAD0_Key_Release() {	XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_NUMPAD_0, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  ); }
//---------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------

exec function A_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_A );}
exec function A_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_A, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function B_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_B );}
exec function B_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_B, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function D_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_D );}
exec function D_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_D, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function E_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_E );}
exec function E_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_E, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function F_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F );}
exec function F_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_F, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function I_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_I );}
exec function I_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_I, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function J_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_J );}
exec function J_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_J, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function C_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_C );}
exec function C_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_C, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function G_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_G );}
exec function G_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_G, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function L_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_L );}
exec function L_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_L, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function K_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_K );}
exec function K_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_K, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function N_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_N );}
exec function N_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_N, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function M_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_M );}
exec function M_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_M, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function O_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_O );}
exec function O_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_O, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function P_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_P );}
exec function P_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_P, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Q_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_Q );}
exec function Q_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_Q, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function R_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_R );}
exec function R_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_R, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function S_Key_Press()     {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_S );}
exec function S_Key_Release()   {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_S, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function T_Key_Press()	    {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_T );}
exec function T_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_T, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function U_Key_Press()	    {   if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_U );}
exec function U_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_U, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function V_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_V );}
exec function V_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_V, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function W_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_W );}
exec function W_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_W, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function X_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_X );}
exec function X_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_X, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Y_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_Y );}
exec function Y_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_Y, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Z_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_Z );}
exec function Z_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_Z, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Backspace_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_BACKSPACE);}
exec function Backspace_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_BACKSPACE, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function End_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_END);}
exec function End_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_END, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function PageUp_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_PAGEUP);}
exec function PageUp_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_PAGEUP, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function PageDn_Key_Press()     {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_PAGEDN);}
exec function PageDn_Key_Release()   {	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_PAGEDN, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Spacebar_Key_Press()      {	if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR);}
exec function Spacebar_Key_Release()    { 	if( !WorldInfo.IsConsoleBuild() ) XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Left_Shift_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT);}
exec function Left_Shift_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Left_Control_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_LEFT_CONTROL);}
exec function Left_Control_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_LEFT_CONTROL, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Left_Alt_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_LEFT_ALT);}
exec function Left_Alt_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_LEFT_ALT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Right_Shift_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_RIGHT_SHIFT);}
exec function Right_Shift_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_RIGHT_SHIFT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Right_Control_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_RIGHT_CONTROL);}
exec function Right_Control_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_RIGHT_CONTROL, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Right_Alt_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_RIGHT_ALT);}
exec function Right_Alt_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_RIGHT_ALT, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Delete_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_DELETE);}
exec function Delete_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_DELETE, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Home_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_HOME);}
exec function Home_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_HOME, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}
//---------------------------------------------------------------------------------------
exec function Tab_Key_Press()    {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_TAB);}
exec function Tab_Key_Release()  {   if( !WorldInfo.IsConsoleBuild() )XComInputBase(PlayerInput).InputEvent( class'UIUtilities_Input'.const.FXS_KEY_TAB, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE  );}

exec function SlowDownGame()
{
	if( !class'Engine'.static.IsRetailGame() || class'Engine'.static.IsConsoleAllowed())
	{
		WorldInfo.Game.SetGameSpeed(WorldInfo.Game.GameSpeed / 2.0f);
	}
}

exec function SpeedUpGame()
{
	if( !class'Engine'.static.IsRetailGame() || class'Engine'.static.IsConsoleAllowed())
	{
		WorldInfo.Game.SetGameSpeed(WorldInfo.Game.GameSpeed * 2.0f);
	}
}

event PreRender(Canvas Canvas)
{
	super.PreRender(Canvas);

	if (Pres != none)
		Pres.PreRender();
}

event PlayerTick( float DeltaTime )
{
	if( m_fAltTabTime > 0 )
	{
		m_fAltTabTime -= DeltaTime;
		if( m_fAltTabTime <= 0 )
		{
			m_fAltTabTime = 0;
		}
	}
	super.PlayerTick( DeltaTime );
}

function bool InAltTab()
{
	return( m_fAltTabTime > 0 );
}

function bool SetPause( bool bPause, optional delegate<CanUnpause> CanUnpauseDelegate=CanUnpause, optional bool bFromLossOfFocus=false)
{
	local bool NewPause;
	if (PlayerCamera != None)
	{
		if (PlayerCamera.bEnableFading && !`ScreenStack.bPauseMenuInput)
		{
			//Do not pause when a camera fade is present.
			return false;
		}
	}
	// When "unpausing" from loss of focus (i.e, the user alt-tabs, or clicks, back into the game),
	// don't allow any inputs for 1/2 second.  This stops the activation mouse clicks from triggering game
	// related items. - DMW
	if( bFromLossOfFocus && !bPause )
	{
		m_fAltTabTime = 0.5f;
	}

	if( bFromLossOfFocus )
		m_bPauseFromLossOfFocus = bPause;
	else
		m_bPauseFromGame = bPause;

	NewPause = m_bPauseFromLossOfFocus || m_bPauseFromGame;

	// jbouscher - this should be safe to comment out, but if stuff breaks with pause/unpause, might need to make it live again
	/*
	if( Pres.IsPauseMenuRaised() )
	{
		return false;
	}
	*/

	// Pause any narratives.
	if( Pres.m_kNarrativeUIMgr != None )
	{
		Pres.m_kNarrativeUIMgr.SetPaused(NewPause);
	}

	return super.SetPause(NewPause, CanUnpauseDelegate);
}

function bool GetPauseMenuRaised ()
{
	return Pres.IsPauseMenuRaised();
}

/**
 * Notifies the player that an attempt to connect to a remote server failed, or an existing connection was dropped.
 *
 * @param	Message		a description of why the connection was lost
 * @param	Title		the title to use in the connection failure message.
 */
function NotifyConnectionError(EProgressMessageType MessageType, optional string Message, optional string Title)
{
	local OnlineSubsystem kOSS;
	local WorldInfo WI;

	WI = class'Engine'.static.GetCurrentWorldInfo();
	kOSS = class'GameEngine'.static.GetOnlineSubsystem();

	`log(`location @ `showvar(Title) @ `showvar(Message) @ `showenum(ENetMode,WI.NetMode,NetMode) @ `showvar(WI.GetURLMap(),Map) @ `showvar(kOSS,OnlineSubsystem),,'XCom_Net');
	// Must have both a title and message, otherwise ignore this message as an "error"
	if ( (Len(Title) == 0) || (Len(Message) == 0) )
	{
		`log(`location @ "Title or Message is empty, ignoring connection error:" @ `ShowVar(MessageType));
		return;
	}

	if (WI.NetMode != NM_Standalone)
	{
		if ( WI.Game != None )
		{
			// Mark the server as having a problem
			WI.Game.bHasNetworkError = true;
			// server needs to bail out early, it cleans up the connections and games state differently -tsmith 
			return;
		}
	}

	WI.GetALocalPlayerController().bIgnoreNetworkMessages = true;

	if( kOSS != none && kOSS.GameInterface != none)
	{
		`log(self $ "::" $ GetFuncName() @ "Destroying online game", true, 'XCom_Net');
		kOSS.GameInterface.AddDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
		if (!kOSS.GameInterface.DestroyOnlineGame('Game'))
		{
			kOSS.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
			OnDestroyedOnlineGame('Game',true);
		}
	}
	else
	{
		OnDestroyedOnlineGame('Game',true);
	}
}

simulated function OnDestroyedOnlineGame(name SessionName,bool bWasSuccessful)
{
	local OnlineSubsystem kOSS;
	local XComOnlineEventMgr EventMgr;
	local EQuitReason eReason;

	kOSS = class'GameEngine'.static.GetOnlineSubsystem();
	if( kOSS != none && kOSS.GameInterface != none)
	{
		kOSS.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	}

	//`log(`location @ `ShowVar(bIsAcceptingInvite));
	if ( ! bIsAcceptingInvite )
	{
		`log(`location @ "Game destroyed, 'disconnecting' and then returning to the main menu.", true, 'XCom_Net');
		EventMgr = `ONLINEEVENTMGR;
		EventMgr.RefreshLoginStatus();

		if( EventMgr.LoginStatus != LS_LoggedIn )
		{
			if( EventMgr.bHasLogin )
			{
				eReason = QuitReason_LostConnection;
			}
			else
			{
				eReason = QuitReason_SignOut;
			}
		}
		else
		{
			if(bVoluntarilyDisconnectingFromGame)
				eReason = QuitReason_None;
			else
				eReason = QuitReason_OpponentDisconnected;
		}
		EventMgr.ReturnToMPMainMenu(eReason);
	}
}

//Dropship transition map functionality
//********************************************
// Called after the engine switches maps from Strategy -> Transition -> Tactical and vice versa
event NotifyLoadedWorld(name WorldPackageName, bool bFinalDest)
{

	super.NotifyLoadedWorld(WorldPackageName, bFinalDest);

	`log("NotifyLoadedWorld:" @ WorldPackageName @ "is now the active world");

	if(!bFinalDest)
	{
		if(Pres != none)
		{
			Pres.Destroy();
			Pres = none;
		}
		
		//We need to update the class, since the controller class is from the map prior to the transition map
		if(`TACTICALGRI != none)
		{
			PresentationLayerClass = class'XComTacticalController'.default.PresentationLayerClass;
		}
		else
		{
			PresentationLayerClass = class'XComHeadquartersController'.default.PresentationLayerClass;
		}
		InitPres();

		bSeamlessTravelDestinationLoaded = false;

		// Prevent the game from immediately jumping to the destination map when it's done
		// loading, we need to make sure all user interaction is complete first.
		// In SP, set this to false, in MP always make sure this is true or loading will hang -- jboswell
		WorldInfo.bContinueToSeamlessTravelDestination = false;

		//Make sure the kismet variable map is up to date
		WorldInfo.MyKismetVariableMgr.RebuildVariableMap(); //Streaming levels can include kismet, so rebuild the map here
		WorldInfo.MyKismetVariableMgr.RebuildClassMap();

		InitDropshipUI(); //Sets up the screen that the user will interact with ( "press any key to continue" )

		SetupDropshipMatinee();
	}

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true);
}

event NotifyStartTacticalSeamlessLoad()
{
	//Make sure the kismet variable map is up to date
	WorldInfo.MyKismetVariableMgr.RebuildVariableMap(); //Streaming levels can include kismet, so rebuild the map here
	WorldInfo.MyKismetVariableMgr.RebuildClassMap();

	InitDropshipUI(); //Sets up the screen that the user will interact with ( "press any key to continue" )

	SetupDropshipMatinee();
}


//=======================================================================================
//X-Com 2 Refactoring
//
simulated function SetupDropshipMatinee()
{
	local array<SequenceObject> Events;
	local array<XComGameState_Unit> UnitsInDropship;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local XComGameState_HeadquartersXCom Headquarters;
	local XComUnitPawn UnitPawn;
	local SkeletalMeshActor IterateActor;
	local SkeletalMeshActor CineDummy;
	local int UnitIndex;
	local Vector ZeroVector;
	local Rotator ZeroRotation;
	local string PawnVariableString;
	local string RemoteEventString;
	local string SoldierEmotion;
	local XComGameState_BattleData BattleData;
	local float NumLost;
	local float TotalNum;
	local float PercentLost;
	local int SquadIndex;

	bProcessedTravelDestinationLoaded = false;

	DropshipPawns.Length = 0;
	DropshipPawnVariables.Length = 0;

	WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_OnTacticalIntro', TRUE, Events);
	if(Events.Length > 0)
	{
		TacticalIntro = SeqEvent_OnTacticalIntro(Events[0]);
	}
	
	foreach AllActors(class'SkeletalMeshActor', IterateActor)
	{
		if(IterateActor.Tag == 'CineDummy')
		{
			CineDummy = IterateActor;
			break;
		}
	}
		
	TacticalIntro.CheckActivate(self, self);

	History = `XCOMHISTORY;
	Headquarters = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// collect all the units we want to appear in the drophip. Start with everybody on the squads the user picked in 
	// strategy
	for(SquadIndex = 0; SquadIndex < Headquarters.AllSquads.Length; SquadIndex++)
	{
		foreach Headquarters.AllSquads[SquadIndex].SquadMembers(UnitRef)
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if(UnitsInDropship.Find(Unit) == INDEX_NONE)
			{
				UnitsInDropship.AddItem(Unit);
			}
		}
	}

	// delicious hackery for the dlc spark. Ideally this will be extended to a "show reward unit in dropship" 
	// flag, but right now the sparks don't go through the usual reward unit paths and it wouldn't work,
	// and we don't have time to do it well.
	if(BattleData.MapData.ActiveMission.sType == "LastGiftC")
	{
		foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			if(Unit.GetMyTemplateName() == 'LostTowersSpark')
			{
				if(UnitsInDropship.Length >= 6)
				{
					// remove the first unit that isn't shen so we have space for the spark
					for(UnitIndex = 0; UnitIndex < UnitsInDropship.Length; UnitIndex++)
					{
						if(UnitsInDropship[UnitIndex].GetMyTemplateName() != 'LostTowersShen')
						{
							UnitsInDropship.Remove(UnitIndex, 1);
							break;
						}
					}
				}

				// stick the spark in the front of the list so appears at the front of the dropship and is easily seen
				UnitsInDropship.InsertItem(0, Unit);
				break;
			}
		}
	}
	// end of hackery

	if (`TACTICALGRI != none)
	{
		//if we are starting the mission the emotion is neutral
		SoldierEmotion = "Neutral";
	}
	else
	{
		//See what percentage of soldiers are alive
		NumLost = 0.0f;
		TotalNum = 0.0f;
		foreach UnitsInDropship(Unit)
		{
			if(Unit.IsSoldier()) //No gremlins, VIPs, etc.		   
			{
				TotalNum += 1.0f;

				//Bleeding-out units die in SquadTacticalToStrategyTransfer, but that hasn't happened yet - explicit handling here.
				if(!Unit.IsAlive() || Unit.bCaptured || Unit.IsBleedingOut())
				{
					NumLost += 1.0f;
				}
			}
		}
		PercentLost = NumLost / TotalNum;

		//Figure out the emotion of the soldier in the dropship based on the mission performance
		if(BattleData.bLocalPlayerWon && PercentLost <= 0.5f)
		{
			if(PercentLost == 0.0f)
			{
				SoldierEmotion = "Happy";
			}
			else
			{
				SoldierEmotion = "Neutral";
			}
		}
		else
		{
			SoldierEmotion = "Sad";
		}
	}

	UnitIndex = 1;		
	foreach UnitsInDropship(Unit)
	{
		if(Unit.IsSoldier() && //No gremlins, VIPs, etc.
		   Unit.IsAlive() && !Unit.bCaptured && !Unit.IsBleedingOut()) //No dead or MIA soldiers in the seats
		{
			UnitPawn = Unit.CreatePawn(self, ZeroVector, ZeroRotation);
			UnitPawn.Mesh.bUpdateSkelWhenNotRendered = true;
			UnitPawn.SetBase(CineDummy);
			UnitPawn.RestoreAnimSetsToDefault(); //Manually call this in advance of SetupForMatinee
			UnitPawn.SetupForMatinee(, true);
			UnitPawn.SetVisibleToTeams(eTeam_All);
			UnitPawn.CreateVisualInventoryAttachments(none, Unit, none, false, true, false, true); // only add certain equipment to the scene, like templar gauntlets
			DropshipPawns.AddItem(UnitPawn);

			PawnVariableString = Unit.GetMyTemplate().strLoadingMatineeSlotPrefix$string(UnitIndex);
			SetDropshipPawnVariable(UnitPawn, PawnVariableString);
			DropshipPawnVariables.AddItem(PawnVariableString);

			RemoteEventString = PawnVariableString$"_"$SoldierEmotion;
			`XCOMGRI.DoRemoteEvent(name(RemoteEventString));

			++UnitIndex;
		}
	}
}

private function SetDropshipPawnVariable(XComUnitPawn UnitPawn, string VariableName)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	WorldInfo.MyKismetVariableMgr.GetVariable(name(VariableName), OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(UnitPawn);
		}
	}
}

simulated function InitDropshipUI()
{
	Pres = XComPlayerController(GetALocalPlayerController()).Pres;
	if(Pres != none && Pres.Get3DMovie().bIsInited && Pres.Get2DMovie().bIsInited)
	{		
		SetupDropshipBriefingScreen(); //Starts the 3D UI ( provides game play information )
	}
	else
	{
		//Call this method again in .1 seconds to see if the presentation layer is ready or not. Flash takes a while to spin up....
		SetTimer(0.1f, false, nameof(InitDropshipUI));
	}
}

//This is called from the parcel mgr once it knows what our objective map is going to be
function UpdateUIBriefingScreen(string ObjectiveMapName)
{
	if (class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode())
		return; // no briefing audio in tactical game modes

	MapImagePath = `MAPS.SelectMapImage(ObjectiveMapName);

	StartDropshipNarrative();

	`CONTENT.RequestObjectAsync(MapImagePath, self, OnImageLoaded);
}

function OnImageLoaded(object LoadedObject)
{
	local UIDropShipBriefing_MissionStart LocalBriefingScreen;
	local string ImagePath;	

	//If the briefing screen is loaded already, set the image.
	LocalBriefingScreen = UIDropShipBriefing_MissionStart(BriefingScreen);
	if(LocalBriefingScreen != none)
	{
		ImagePath = PathName(LoadedObject);
		LocalBriefingScreen.SetMapImage(ImagePath);
	}	

	MapImage = LoadedObject;
}

function StartDropshipNarrative()
{
	local XComGameStateHistory History;
	local X2MissionTemplate MissionTemplate;
	local XComGameState_BattleData BattleData;
	local XComNarrativeMoment DropshipNarrative;
	local GeneratedMissionData GeneratedMission;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int ChosenDefeated;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	GeneratedMission = class'UIUtilities_Strategy'.static.GetXComHQ().GetGeneratedMissionData(BattleData.m_iMissionID);
	MissionTemplate = class'X2MissionTemplateManager'.static.GetMissionTemplateManager().FindMissionTemplate(GeneratedMission.Mission.MissionName);	

	if(MissionTemplate.PreMissionNarratives.Length > 0 && !BattleData.DirectTransferInfo.IsDirectMissionTransfer)
	{
		if (GeneratedMission.Mission.MissionName == 'ChosenStrongholdShort' || GeneratedMission.Mission.MissionName == 'ChosenStrongholdLong')
		{
			// If this is a stronghold mission, play the unique narrative moment related to the number of Chosen the player has killed
			AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
			ChosenDefeated = AlienHQ.NumAdventChosen - AlienHQ.GetNumLivingChosen();
			DropshipNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(MissionTemplate.PreMissionNarratives[ChosenDefeated]));
		}
		else
		{
			DropshipNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(MissionTemplate.PreMissionNarratives[`SYNC_RAND(MissionTemplate.PreMissionNarratives.Length)]));
		}
		if(DropshipNarrative != None)
		{
			`PRES.UINarrative(DropshipNarrative);
		}
	}
}

private function SetupDropshipBriefingScreen()
{		
	local XComTacticalGRI TacticalGRI;
	local XComPresentationLayerBase PresentationLayer;
	//local UIMovie_3D GFXMovie;

	TacticalGRI = `TACTICALGRI;
	if(TacticalGRI != none)
	{
		BriefingScreen = Spawn(class'UIDropShipBriefing_MissionStart', self);
		UIDropShipBriefing_MissionStart(BriefingScreen).SetMapImage(MapImagePath);
	}
	else
	{
		BriefingScreen = Spawn(class'UIDropShipBriefing_MissionEnd', self);
	}

	RemoteEvent('CIN_InFlight');

	BriefingScreen.AllowShowDuringCinematic(true);

	PresentationLayer = Pres;
	PresentationLayer.ScreenStack.Push(BriefingScreen, PresentationLayer.Get3DMovie());
		
	if (class'WorldInfo'.static.GetWorldInfo().IsInSeamlessTravel())
	{
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false);
	}
}

function CleanupDropshipStart()
{
	bProcessedTravelDestinationLoaded = true;	

	//If we are seamless traveling, clean up now. Otherwise wait for the camera fade
	if(class'WorldInfo'.static.GetWorldInfo().IsInSeamlessTravel())
	{
		RemoteEvent('CIN_Cleanup');	
		CleanupDropshipEnd();
	}
	else
	{
		SetTimer(1.0f, false, nameof(CleanupDropshipEnd));
	}
}

function CleanupDropshipEnd()
{
	local int Index;

	if(!class'WorldInfo'.static.GetWorldInfo().IsInSeamlessTravel())
	{
		RemoteEvent('CIN_Cleanup');
	}

	WorldInfo.bContinueToSeamlessTravelDestination = true;

	Pres.GetUIComm().Hide(); //Hide the comms screen, as things are about to get choppy
	
	Pres.ScreenStack.Pop(BriefingScreen);

	//Clean up the dropship pawns
	for(Index = 0; Index < DropshipPawns.Length; ++Index)
	{
		SetDropshipPawnVariable(none, DropshipPawnVariables[Index]);
		DropshipPawns[Index].Destroy();
	}

	DropshipPawns.Length = 0;
}

event NotifyLoadedDestinationMap(name WorldPackageName)
{
	Pres.UILoadAnimation(false);

	if(!`ONLINEEVENTMGR.bDisconnectPending)
	{
		RemoteEvent('CIN_DestinationLoaded');
	}

	RemoteEvent('CIN_DropZone');
		
	bSeamlessTravelDestinationLoaded = true;	
		
	if (`MAPS.bSkipLoadingConfirmation)
	{
		//This functionality "automatically" presses the A button / any key in the drop ship so that load times can be measured when the blocking load override test value is set
		CleanupDropshipStart();
		ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.5);
	}	

	`ONLINEEVENTMGR.DelayDisconnects(false);
}
//********************************************

function bool IsInLobby()
{
	return false;
}

// override of the built in Epic restart level command. Since we need far more information than just the initial map in tactical,
// the command will basically load the start state, effectively restarting the level
exec native function RestartLevel();

// Helper function for TransferToNewMission, it was getting kinda bit and hairy
private function TransferUnitToNewMission(XComGameState_Unit UnitState, 
										  XComGameState NewStartState,
										  XComGameState_HeadquartersXCom XComHQ, 
										  XComGameState_BattleData BattleData,
										  int LocalPlayerObjectID,
										  array<StateObjectReference> ForcedCapturedSoldiers,
										  array<StateObjectReference> ForcedEvacSoldiers)
{
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference StateRef;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;
	if(UnitState.ControllingPlayer.ObjectID == LocalPlayerObjectID 
		&& !UnitState.GetMyTemplate().bIsCosmetic 
		&& !UnitState.IsMindControlled()) // don't pull in aliens who are only on the xcom team because they are mind-controlled
	{
		UnitState = XComGameState_Unit(NewStartState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			
		if (ForcedEvacSoldiers.Find('ObjectID', UnitState.ObjectID) != INDEX_NONE)
		{
			UnitState.RemoveUnitFromPlay();
		}
		else if (ForcedCapturedSoldiers.Find('ObjectID', UnitState.ObjectID) != INDEX_NONE)
		{
			UnitState.RemoveUnitFromPlay();
			UnitState.bCaptured = true;
		}
		else if(UnitState.IsIncapacitated() || UnitState.IsDead())
		{
			// units that were "left behind" are left for dead
			UnitState.RemoveUnitFromPlay(); // don't let this unit show up in the next mission
			UnitState.SetCurrentStat(eStat_HP, 0); // they're dead, Jim
			UnitState.Abilities.Length = 0; // Since we are now dead, remove all abilities
		}
		else if(XComHQ.Squad.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
		{
			// this unit needs to stay in the history in cases they appear again in later legs of
			// this mission, but they are not in this leg, so remove them
			UnitState.RemoveUnitFromPlay();
		}

		// copy their stats to the transfer info. This needs to happen before we remove abilities and effects, as
		// they could change the stat values
		BattleData.StoreDirectTransferUnitStats(UnitState);

		// copy over the unit's abilities
		foreach UnitState.Abilities(StateRef)
		{
			NewStartState.ModifyStateObject(class'XComGameState_Ability', StateRef.ObjectID);
		}

		// and their weapons
		foreach UnitState.InventoryItems(StateRef)
		{
			ItemState = XComGameState_Item( NewStartState.ModifyStateObject(class'XComGameState_Item', StateRef.ObjectID) );
			ItemState.CosmeticUnitRef.ObjectID = 0;
		}

		// and clear any effects they are under
		while (UnitState.AppliedEffects.Length > 0)
		{
			StateRef = UnitState.AppliedEffects[UnitState.AppliedEffects.Length - 1];
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(StateRef.ObjectID));
			UnitState.RemoveAppliedEffect(EffectState);
			UnitState.UnApplyEffectFromStats(EffectState);
		}

		while (UnitState.AffectedByEffects.Length > 0)
		{
			StateRef = UnitState.AffectedByEffects[UnitState.AffectedByEffects.Length - 1];
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(StateRef.ObjectID));
			UnitState.RemoveAffectingEffect(EffectState);
			UnitState.UnApplyEffectFromStats(EffectState);
		}
	}
}

// Loads into a new map of the specified mission type, transferring all XCom soldiers
exec function TransferToNewMission(string MissionType, array<StateObjectReference> ForcedCapturedSoldiers, array<StateObjectReference> ForcedEvacSoldiers)
{
	local XComGameStateHistory History;
	local X2EventManager EventManager;
	local XComParcelManager ParcelManager;
	local XComTacticalMissionManager MissionManager;
	local X2TacticalGameRuleset Rules;
	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local MissionDefinition MissionDef;
	local XComGameState_BattleData BattleData;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState StartState;
	local StateObjectReference LocalPlayerReference;
	local XComGameState_Player PlayerState;
	local XComGameState_Player NewPlayerState;
	local XComGameState_Unit UnitState;
	local StateObjectReference UnitStateRef;
	local StateObjectReference StateRef;
	local XComGameState_BaseObject BaseState;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local XComGameState_MissionSite MissionState;
	local XComGameState_LootDrop LootDropState;
	local int LootIndex;
	local XComGameState_Item ItemState;
	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;
	local string MissionBriefing;

	History = `XCOMHISTORY;
	ParcelManager = `PARCELMGR;
	MissionManager = `TACTICALMISSIONMGR;
	Rules = `TACTICALRULES;
	EventManager = `XEVENTMGR;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// pick our new map
	if(!MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
	{
		`Redscreen("TransferToNewMission(): Mission Type " $ MissionType $ " has no definition!");
		return;
	}

	MissionManager.ForceMission = MissionDef;

	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef, BattleData.MapData.Biome);
	if(ValidPlots.Length == 0)
	{
		`Redscreen("TransferToNewMission(): Could not find a plot to transfer to for mission type " $ MissionType $ "!");
		return;
	}
	
	NewPlot = ValidPlots[0];

	// generate a new start state
	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);

	BattleData = XComGameState_BattleData(StartState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	BattleData.DirectTransferInfo.IsDirectMissionTransfer = true;
	BattleData.MapData.PlotMapName = NewPlot.MapName;
	BattleData.MapData.ActiveMission = MissionDef;
	BattleData.MapData.EntranceData.Length = 0;
	BattleData.MapData.ParcelData.Length = 0;
	BattleData.MapData.PlotCoverParcelData.Length = 0;
	BattleData.MapData.ObjectiveParcelIndex = -1;
	BattleData.TacticalTurnCount = 0;
	BattleData.LostQueueStrength = 0;
	BattleData.LostSpawningLevel = BattleData.SelectLostActivationCount();

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(MissionDef.MissionName);
	if( MissionTemplate != none )
	{
		MissionBriefing = MissionTemplate.Briefing;
	}
	else
	{
		MissionBriefing = "NO LOCALIZED BRIEFING TEXT!";
	}
	BattleData.m_strDesc = MissionBriefing;

	// save off the aliens we've seen/killed up 'till now
	BattleData.DirectTransferInfo.AliensKilled = class'UIMissionSummary'.static.GetNumEnemiesKilled(BattleData.DirectTransferInfo.AliensSeen);

	// copy over the xcom headquarters object. Need to do this first so it's available for the unit transfer
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(StartState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	// compute the squad for the new leg of the mission
	class'X2MissionTemplate'.static.GetMissionSquad(MissionType, XComHQ.Squad);

	// Copy over the XCOM player state and create new states for the alien and civilian players
	LocalPlayerReference.ObjectID = Rules.GetLocalClientPlayerObjectID();

	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(PlayerState.ObjectID == LocalPlayerReference.ObjectID) // this is the local human team, need to keep track of it
		{
			PlayerState = XComGameState_Player(StartState.ModifyStateObject(class'XComGameState_Player', LocalPlayerReference.ObjectID));
		}
		else
		{
			// create a new player. This will clear out any old data about
			// units and AI
			NewPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, PlayerState.GetTeam());
			NewPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
			BattleData.PlayerTurnOrder.AddItem(NewPlayerState.GetReference());

			// Player states will automatically be removed as part of the archive process, but we still need
			// to remove them from the player turn order
			assert(class'XComGameState_Player'.default.bTacticalTransient); // verify that the player will automatically be removed
			BattleData.PlayerTurnOrder.RemoveItem(PlayerState.GetReference());
		}
	}

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.IsBeingCarried() )
		{
			UnitStateRef.ObjectID = UnitState.ObjectID;
			ForcedEvacSoldiers.AddItem(UnitStateRef);
		}
	}

	// copy over any other non-transient state objects, excepting player objects and alien units
	foreach History.IterateByClassType(class'XComGameState_BaseObject', BaseState)
	{
		UnitState = XComGameState_Unit(BaseState);
		if(UnitState != none)
		{
			// remove any events associated with units. We'll re-add them when the next mission starts
			TransferUnitToNewMission(UnitState, StartState, XComHQ, BattleData, LocalPlayerReference.ObjectID, ForcedCapturedSoldiers, ForcedEvacSoldiers);
		}
		else if(XComGameState_Player(BaseState) == none // we already handled players above
			&& XComGameState_HeadquartersXCom(BaseState) == none // we also handled xcom headquarters
			&& !BaseState.bTacticalTransient)
		{
			// not a transient state, so bring it along
			BaseState = StartState.ModifyStateObject(BaseState.Class, BaseState.ObjectID);
			
			if(XComGameState_ObjectivesList(BaseState) != none)
			{
				XComGameState_ObjectivesList(BaseState).ClearTacticalObjectives();
			}
		}
		else if (XComGameState_LootDrop(BaseState) != none)
		{
			LootDropState = XComGameState_LootDrop(BaseState);
			for( LootIndex = 0; LootIndex < LootDropState.LootableItemRefs.Length; ++LootIndex )
			{
				ItemState = XComGameState_Item(StartState.ModifyStateObject(class'XComGameState_Item', LootDropState.LootableItemRefs[LootIndex].ObjectID));

				ItemState.OwnerStateObject = XComHQ.GetReference();
				XComHQ.PutItemInInventory(StartState, ItemState, true);

				BattleData.CarriedOutLootBucket.AddItem(ItemState.GetMyTemplateName());
			}
		}
	}

	// make sure every unit on this leg of the mission is ready to go
	foreach XComHQ.Squad(UnitStateRef)
	{
		// pull the unit from the archives, and add it to the start state
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateRef.ObjectID));
		if(!UnitState.IsDead())
		{
			UnitState = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', UnitStateRef.ObjectID));
			UnitState.SetControllingPlayer(LocalPlayerReference);
			UnitState.SetHQLocation(eSoldierLoc_Dropship);

			if(BattleData.IsUnitRemovedFromRestOfMission(UnitState))
			{
				UnitState.RemoveUnitFromPlay();
			}
			else if ((ForcedCapturedSoldiers.Find( 'ObjectID', UnitState.ObjectID ) != INDEX_NONE) ||
					 (ForcedEvacSoldiers.Find( 'ObjectID', UnitState.ObjectID ) != INDEX_NONE))
			{
				UnitState.RemoveUnitFromPlay();
			}
			else
			{
				UnitState.ClearRemovedFromPlayFlag();
			}
			
			//Add this soldier's items to the start state
			foreach UnitState.InventoryItems(StateRef)
			{
				StartState.ModifyStateObject(class'XComGameState_Item', StateRef.ObjectID);
			}
		}
	}

	// give mods/dlcs a chance to modify the transfer state
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.ModifyTacticalTransferStartState(StartState);
	}

	// This is not the correct way to handle this. Ideally, we should be calling EndTacticalState
	// or some variant there of on each object. Unfortunately, this also requires adding a new
	// modified state object to a game state, and we can't do that here as it will just add the object to
	// the start state, causing it to be pulled along to the next part of the mission. What should happen is 
	// that we build a list of transient tactical objects that are coming along to the next mission, call some
	// PrepareForTransfer function on them, EndTacticalPlay on the others, and add that as a change container
	// state before beginning to build the tactical start state. This is a pretty large change, however, and not
	// one that I have time to do before I leave. Leaving this comment here for my future code inheritors.
	// Also I'm really sorry. - dburchanowski
	foreach History.IterateByClassType(class'XComGameState_BaseObject', BaseState)
	{
		if(BaseState.bTacticalTransient && StartState.GetGameStateForObjectID(BaseState.ObjectID) == none)
		{
			EventManager.UnRegisterFromAllEvents(BaseState);
		}
	}

	History.AddGameStateToHistory(StartState);

	// if this mission has a custom loading map, play it
	if( MissionDef.ForceLoadingScreenBink != "" )
	{
		`XENGINE.PlaySpecificLoadingMovie(MissionDef.ForceLoadingScreenBink, MissionDef.ForceLoadingScreenWiseEvent);
		`XENGINE.PlayLoadMapMovie(-1);
	}
	else
	{
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));
		if( MissionState.GetMissionSource().CustomLoadingMovieName_Intro != "" )
		{
			`XENGINE.PlaySpecificLoadingMovie(MissionState.GetMissionSource().CustomLoadingMovieName_Intro, MissionState.GetMissionSource().CustomLoadingMovieName_IntroSound);
			`XENGINE.PlayLoadMapMovie(-1);
		}
	}

	// and do the client transfer to the new map!
	ClientTravel(NewPlot.MapName, TRAVEL_Relative);
}

simulated event NotifyMatineeStartedAkEvent(AkEvent Event, float EventDuration)
{
	local UINarrativeMgr NarrativeMgr;

	// if this event has commlink subtitles attached to it, play them
	if(Event.SpeakerTemplate != '')
	{
		NarrativeMgr = Pres.m_kNarrativeUIMgr;
		NarrativeMgr.CurrentOutput.strTitle = NarrativeMgr.TemplateToTitle(Event.SpeakerTemplate);
		NarrativeMgr.CurrentOutput.strImage = NarrativeMgr.TemplateToPortrait(Event.SpeakerTemplate);
		NarrativeMgr.CurrentOutput.strText = Event.SpokenText;
		NarrativeMgr.CurrentOutput.fDuration = EventDuration;

		Pres.GetUIComm().Show();

		// add a bit of hang time so the comm doesn't immediately disappear when the audio completes
		SetTimer(EventDuration + 0.25, false, 'StopCommLink'); 
	}
}

simulated private function StopCommLink()
{
	local UINarrativeMgr NarrativeMgr;

	NarrativeMgr = Pres.m_kNarrativeUIMgr;
	NarrativeMgr.CurrentOutput.strTitle = "";
	NarrativeMgr.CurrentOutput.strText = "";

	Pres.GetUIComm().Hide();
}

defaultproperties
{
	bIsAcceptingInvite=false
	bBlockingInputAfterMovie=false
	bVoluntarilyDisconnectingFromGame=false

	m_bPauseFromLossOfFocus=false;
	m_bPauseFromGame=false;

	m_eTeam=eTeam_XCom //default to the XCom team if this is left unset
	bProcessedTravelDestinationLoaded=true
}
