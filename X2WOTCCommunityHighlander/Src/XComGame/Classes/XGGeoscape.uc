class XGGeoscape extends Actor
	dependson(XGMissionControlUI)
	dependson(XComEarth);


// SAVE DATA
var float                     m_fTimeScale;           // The speed at which the game is moving
var float                     m_fGameTimer;           // Timer for Game ticks
var bool                      m_bGlobeHidden;

var TDateTime                 m_kDateTime;
var bool                      m_bInPauseMenu;
var bool                      m_bInCombat;
var float                     m_fCombatCooldown;
var array<string>             m_arrMissionList;
var XGBase                    m_kBase;

const MIN_FLIGHT_SECONDS = 3.0f;
const PAUSED = 0;
const ONE_MINUTE = 60;
const TEN_MINUTES = 600;
const FIFTEEN_MINUTES = 900;
const THIRTY_MINUTES = 1800;
const ONE_HOUR = 3600;
const TWELVE_HOURS = 43200;
const TWENTY_FOUR_HOURS = 86400;
const MAXIMUM_TIMESLICE = 60;
const SCAN_TIMESLICE = 1800;

function Init()
{
	m_kDateTime = `STRATEGYRULES.GameTime;
	m_kBase = Spawn( class'XGBase' );
	m_kBase.Init();
}

//------------------------------------------------
function InitLoadGame()
{
	m_fTimeScale = 0;   // Always start paused
}

//------------------------------------------------
//-------------------------------------------------------------------------------
function vector2d GetShortestDist( vector2d v2Start, vector2d v2End )
{
	return vect2d( ShortestWrappedDistance( v2Start.X, v2End.X ), v2End.Y - v2Start.Y );
}
//-------------------------------------------------------------------------------
function float ShortestWrappedDistance( float fStart, float fEnd )
{
	local float fA, fB, fabsA, fabsB;

	fA = fEnd - fStart;
	
	if( fStart < fEnd )
		fB = (fEnd-1)-fStart;
	else
		fB = (fEnd+1)-fStart;

	fabsA = Abs(fA);
	fabsB = Abs(fB);
	if (fabsA <= fabsB)
		return fA;

	return fB;
}


//#############################################################################################
//----------------   GAME   -------------------------------------------------------------------
//#############################################################################################

//-----------------------------------------------------------------------
//-----------------------------------------------------------------------
function bool CanExit()
{
	return true;
}
//-----------------------------------------------------------------------
function OnExitMissionControl()
{
	Pause();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_AvengerNoRoom");
	`XSTRATEGYSOUNDMGR.PlayBaseViewMusic();
}

//-----------------------------------------------------------------------
//This method is called immediately after returning from a mission
function OnEnterMissionControl(optional bool bSimCombat = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Airship Dropship;
	local XGStrategy kStrategy;
	local XComHQPresentationLayer HQPres;
	local XComStrategySoundManager SoundManager;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pre Mission End UI Sequence Hook");
	`XEVENTMGR.TriggerEvent('PreMissionDone', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	kStrategy = `Game;
	History = `XCOMHISTORY;
	HQPres = `HQPRES;
	SoundManager = `XSTRATEGYSOUNDMGR;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	SoundManager.StopHQMusicEvent();	

	// Clear out any playing or queued narrative - requested by Jake
	HQPres.m_kNarrativeUIMgr.ClearConversationQueueOfNonTentpoles();

	ShowRealEarth();

	SetTimer(0.25f, false, nameof(ClearCameraFadeAndLoadingScreen));
	StartHQMusic();
		
	if( XComHQ.GetObjectiveStatus('T0_M0_TutorialFirstMission') == eObjectiveState_InProgress )
	{
		//HQPres.m_kFacilityGrid.Hide();
		//class'XComGameStateContext_StrategyGameRule'.static.RemoveInvalidSoldiersFromSquad();
		//class'XComGameStateContext_StrategyGameRule'.static.AddLootToInventory();
		HQPres.ExitPostMissionSequence();
	}
	//If we loaded from a save, go straight to the map
	else if(kStrategy.m_bLoadedFromSave)
	{
		kStrategy.PostLoadSaveGame();
		//HQPres.UIEnterStrategyMap();
	}
	else if(XComHQ.bXComFullGameVictory)
	{
		HQPres.UIEnterStrategyMap();
		SoundManager.PlaySoundEvent("Geoscape_SkyrangerStop");
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Victory Hook");
		`XEVENTMGR.TriggerEvent('XComVictory', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		
		// Movie will have already played so jump to player stats screen
		HQPres.UIYouWin();
	}
	else if(AlienHQ.bAlienFullGameVictory)
	{
		HQPres.UIEnterStrategyMap();
		SoundManager.PlaySoundEvent("Geoscape_SkyrangerStop");
		// Movie has not played yet, play it then it triggers stats on complete
		class'X2StrategyElement_DefaultAlienAI'.static.PlayerLossAction();
	}
	else if(!XComHQ.bReturningFromMission)
	{
		HQPres.UIEnterStrategyMap();
	}
	else
	{
		//Find the dropship
		foreach History.IterateByClassType(class'XComGameState_Airship', Dropship)
		{
			if(Dropship.IsCurrentlyInFlight())
			{
				break;
			}
		}

		//Make sure we are paused, otherwise map events will fire during the dropship sequence
		if(m_fTimeScale != PAUSED)
		{
			m_fTimeScale = PAUSED;
		}

		//Instantly complete the dropship's flight back
		if (Dropship != none)
			Dropship.ProcessFlightComplete();

		// only proceed with the normal after action mission flow if there are no narrative conversations preempting it
		//if( !HQPres.m_kNarrativeUIMgr.AnyActiveConversations() )
		//{
			HQPres.UIAfterAction(bSimCombat);
		//}
	}
	
	SoundManager.PlaySoundEvent("Stop_AvengerAmbience");
}

function ClearCameraFadeAndLoadingScreen()
{
	`HQPRES.HideLoadingScreen();
	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true);
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false, , , 1.0);	
}

function StartHQMusic()
{
	`XSTRATEGYSOUNDMGR.PlayHQMusicEvent();
}

event Tick( float fDeltaT )
{
	local int i, iSlices;
	local float fGameTime, fRemainderTime, fUseMaximumTimeslice;
	
	if( !`HQPRES.ScreenStack.IsInStack(class'UIPauseMenu') )
		`GAME.m_fGameDuration += fDeltaT;

	fGameTime = fDeltaT * m_fTimeScale;

	// Never fully process a tick while the tactical start state is the head of the history - 
	// this could result in strategy states being layered on top of the start state, which has other downstream effects 
	// (such as InitBattle() attempting to execute the LoadTacticalGame path instead of the CreateTacticalGame path).
	if( fGameTime > 0 && `XCOMHISTORY.GetStartState() != None )
	{
		fGameTime = 0;
	}

	// Start issue #425
	if (fGameTime > 0 && ShouldPreventTick())
	{
		fGameTime = 0;
	}
	// End issue #425
	
	// IF( PAUSED )
	if (fGameTime == 0)
	{
		UpdateUIVisualsOnly();
		return;
	}
		

	if( fGameTime >= MAXIMUM_TIMESLICE )
	{
		if( fGameTime <= FIFTEEN_MINUTES ) //FIFTEEN_MINUTE timescale is used while aircraft are flying
		{
			fUseMaximumTimeslice = MAXIMUM_TIMESLICE;
		}
		else
		{
			fUseMaximumTimeslice = SCAN_TIMESLICE; //Maximum time slice for advancing time to help perf on the consoles
		}

		fRemainderTime = fGameTime > fUseMaximumTimeslice ? (fGameTime % fUseMaximumTimeslice) : 0.0f;
		iSlices = max( fGameTime/fUseMaximumTimeslice, 1 );

		for( i = 0; i < iSlices; i++ )
		{
			GameTick( fUseMaximumTimeslice );
		}

		if( fRemainderTime > 0 )
			GameTick( fRemainderTime );
	}
	else
	{
		GameTick( fGameTime );
	}

	UpdateUI( fDeltaT );
}

// Start issue #425
protected function bool ShouldPreventTick()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
 	Tuple.Id = 'PreventGeoscapeTick';
 	Tuple.Data.Add(1);
 	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false;

	`XEVENTMGR.TriggerEvent('PreventGeoscapeTick', Tuple, self);

	return Tuple.Data[0].b;
}
// End issue #425

function GameTick( float fGameTime )
{
	local XComHeadquartersCheatManager CheatMgr;

	if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T5_M3_CompleteFinalMission') != eObjectiveState_InProgress)
	{
		m_fGameTimer -= fGameTime;
		if (m_fGameTimer <= 0)
		{
			XGMissionControlUI(`HQPRES.GetMgr(class'XGMissionControlUI')).UpdateView();
			m_fGameTimer += ONE_HOUR;
		}

		class'X2StrategyGameRulesetDataStructures'.static.AddTime(m_kDateTime, fGameTime);
		`STRATEGYRULES.GameTime = m_kDateTime;
		`EARTH.SetTime(m_kDateTime);
		UpdateAlienAI();
		UpdateResistance();
		UpdateDLCs();
		//UpdateHiddenMapElements(); Nothing is actually hidden and this is a terrible function vis-a-vis framerate
		UpdateMissionCalendar();

		CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);

		if (CheatMgr != none && CheatMgr.bGamesComDemo)
		{
			if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(CheatMgr.DarkEventPopupTime, `STRATEGYRULES.GameTime))
			{
				CheatMgr.DarkEventsPopup();
			}
		}
	}
}

function UpdateMissionCalendar()
{
	local XComGameState NewGameState;
	local XComGameState_MissionCalendar CalendarState;
	local XComGameStateHistory History;
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local UIStrategyMap StrategyMap;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Mission Calendar");
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
	CalendarState = XComGameState_MissionCalendar(NewGameState.ModifyStateObject(class'XComGameState_MissionCalendar', CalendarState.ObjectID));

	if(!CalendarState.Update(NewGameState))
	{
		NewGameState.PurgeGameStateForObjectID(CalendarState.ObjectID);
	}

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	History = `XCOMHISTORY;
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));

	StrategyMap = `HQPRES.StrategyMap2D;
	if (CalendarState.MissionPopupSources.Length > 0 && StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate(CalendarState.MissionPopupSources[0]));

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Calendar: Remove Popup Signal");
		CalendarState = XComGameState_MissionCalendar(NewGameState.ModifyStateObject(class'XComGameState_MissionCalendar', CalendarState.ObjectID));
		CalendarState.MissionPopupSources.Remove(0, 1);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		if(MissionSource != none && MissionSource.MissionPopupFn != none)
		{
			Pause();
			MissionSource.MissionPopupFn();
		}
	}
}


function UpdateHiddenMapElements()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_BaseObject TestObject;
	local HiddenOnMap HiddenObj;

	
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_BaseObject', TestObject)
	{
		HiddenObj = HiddenOnMap(TestObject);

		if(HiddenObj != none)
		{
			if(HiddenObj.IsHidden() && HiddenObj.AvengerInRegion() && HiddenObj.UnhideTimerComplete())
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unhide Map Element");
				HiddenObj.Unhide(NewGameState);
				break;
			}
		}
	}

	if(NewGameState != none)
	{
		if(NewGameState.GetNumGameStateObjects() > 0)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			HiddenObj.UnhiddenNotification();
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}
}

function UpdateAlienAI()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ.Update();
}

function UpdateResistance()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local StateObjectReference EmptyRef;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update ResistanceHQ");
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));

	if(!ResistanceHQ.Update(NewGameState))
	{
		NewGameState.PurgeGameStateForObjectID(ResistanceHQ.ObjectID);
	}

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		if(ResistanceHQ.bEndOfMonthNotify)
		{
			ResistanceHQ.EndOfMonthPopup();
		}
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	if(ResistanceHQ.ExpiredMission != EmptyRef)
	{
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(ResistanceHQ.ExpiredMission.ObjectID));
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Expiring Mission");
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
		ResistanceHQ.ExpiredMission = EmptyRef;
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		AlienHQ.StartAcceleratingDoom();
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`HQPRES.UIMissionExpired(MissionState);
	}
}

function UpdateDLCs()
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;
	
	// Update each DLC
	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].UpdateDLC();
	}
}

//---------------------------------------------------------------
function bool IsBusy()
{
	return false;
}
//---------------------------------------------------------------
function bool IsPaused()
{
	return m_fTimeScale == PAUSED;
}
//---------------------------------------------------------------
function Pause()
{
	local XComGameState NewGameState;
	local XComGameState StartState;
	local XComGameState_GameTime TimeState;
	local XComGameState_HeadquartersXCom XComHQ;

	if (IsScanning()) 
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		XComHQ.ToggleSiteScanning(false);

		`XCOMGRI.DoRemoteEvent('FastForwardOff');
	}

	m_fTimeScale = PAUSED;

	//  @TODO - this is probably not the best place to have this, but for now it will do
	//  Update the game time in the history so that we can't go backward in time by saving/loading the game.	
	StartState = `XCOMHISTORY.GetStartState();
	if(StartState == none) //If there is a start state, it means we are launching tactical and the history is locked
	{
		TimeState = XComGameState_GameTime(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Geoscape Pause");
		TimeState = XComGameState_GameTime(NewGameState.ModifyStateObject(TimeState.Class, TimeState.ObjectID));
		TimeState.CurrentTime = m_kDateTime;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}
//---------------------------------------------------------------
function Resume()
{		
	// IF( The game is fast forwarding )
	if(m_fTimeScale == TWELVE_HOURS)
		return;
	
	m_fTimeScale = ONE_MINUTE;
}
//---------------------------------------------------------------
function bool DecreaseTimeScale()
{
	if(m_fTimeScale == TWELVE_HOURS)
		m_fTimeScale = THIRTY_MINUTES;
	else if (m_fTimeScale == THIRTY_MINUTES)
		m_fTimeScale = ONE_MINUTE;
	else if (m_fTimeScale == ONE_MINUTE)
		return false;//m_fTimeScale = PAUSED;

	return true;
}
//---------------------------------------------------------------
function bool IncreaseTimeScale()
{
	if (m_fTimeScale == ONE_MINUTE)
		m_fTimeScale = THIRTY_MINUTES;
	else if (m_fTimeScale == THIRTY_MINUTES)
		m_fTimeScale = TWELVE_HOURS;
	else if(m_fTimeScale == TWELVE_HOURS)
		return false;
		

	return true;
}

//---------------------------------------------------------------
function bool IsScanning()
{
	return m_fTimeScale == TWELVE_HOURS;
}
//---------------------------------------------------------------
function bool CanScan()
{
	return m_fTimeScale <= ONE_MINUTE;
}
//---------------------------------------------------------------
function FastForward()
{
	m_fTimeScale = TWELVE_HOURS;
	`XCOMGRI.DoRemoteEvent('FastForwardOn');
}
function RestoreNormalTimeFrame()
{
	`XCOMGRI.DoRemoteEvent('FastForwardOff');
	m_fTimeScale = ONE_MINUTE;
}
//-----------------------------------------------------
function vector2D WrapCoords( Vector2D v2Coords )
{
	local Vector2D v2Wrapped;

	if( v2Coords.X > 1 )
		v2Wrapped.X = v2Coords.X - 1;
	else if( v2Coords.X < 0 )
		v2Wrapped.X = v2Coords.X + 1;
	else
		v2Wrapped.X = v2Coords.X;

	if( v2Coords.Y > 1 )
		v2Wrapped.Y = v2Coords.Y - 1;
	else if( v2Coords.Y < 0 )
		v2Wrapped.Y = v2Coords.Y + 1;
	else
		v2Wrapped.Y = v2Coords.Y;

	return v2Wrapped;
}

//-----------------------------------------------------
function ShowRealEarth()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_HologlobeDeactivation);
	TriggerGlobalEventClass( class'SeqEvent_MissionControl', self, 4 );
	TriggerGlobalEventClass( class'SeqEvent_MissionControl', self, 3 );
}

//-----------------------------------------------------
function UpdateUI( float fDeltaT )
{
	local XComStrategyMap XComMap;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Skyranger Skyranger;
	local Vector2D MoveDelta, CurLoc;

	XComMap = `HQPRES.m_kXComStrategyMap;

	if(XComMap != none)
	{
		XComMap.UpdateStrategyMap();
		XComMap.UpdateMovers(fDeltaT);
		XComMap.UpdateVisuals(); //update visuals last to reflect the other changes
	}

	//Only lock to the ship while it flies
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Skyranger = XComGameState_Skyranger(History.GetGameStateForObjectID(XComHQ.SkyrangerRef.ObjectID));
	
	if(XComHQ.IsCurrentlyInFlight())
	{
		CurLoc = `EARTH.GetViewLocation();
		MoveDelta = XComHQ.Get2DLocation();
		MoveDelta.X -= CurLoc.X;
		MoveDelta.Y -= CurLoc.Y;

		`EARTH.MoveViewLocation(MoveDelta);
	}
	else if (Skyranger.IsCurrentlyInFlight())
	{
		CurLoc = `EARTH.GetViewLocation();
		MoveDelta = Skyranger.Get2DLocation();
		MoveDelta.X -= CurLoc.X;
		MoveDelta.Y -= CurLoc.Y;

		`EARTH.MoveViewLocation(MoveDelta);
	}

}

function UpdateUIVisualsOnly()
{
	local XComStrategyMap XComMap;
	
	XComMap = `HQPRES.m_kXComStrategyMap;

	if (XComMap != none)
	{
		XComMap.UpdateVisuals(); //update visuals last to reflect the other changes
	}
}

defaultproperties
{
	m_fTimeScale=PAUSED
}
