//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGBattle_SP extends XGBattle
	abstract
	native(Core);
	
var bool            m_bInCinematic;
var bool            m_bAchivementsEnabled;
var bool            m_bAchievementsDisabledXComHero;
var bool            m_bMissionAlreadyWon; // mission cannot be lost anymore, but units still need to be extracted

function InitDescription()
{
	local XGNarrative kNarr;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	

	if (PRES().m_kNarrative == none)
	{
		CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

		kNarr = spawn(class'XGNarrative');
		kNarr.InitNarrative(CampaignSettingsStateObject.bSuppressFirstTimeNarrative);
		PRES().SetNarrativeMgr(kNarr);
	}
}

function UninitDescription()
{
	//@TODO - rmcfall - deprecated for XCom 2
}

// Loads all standalone seekfree unit content from disk
// Without this, we won't be able to spawn any units
//simulated function RequestContent()
//{
//    RequestContentForTeam(eTeam_XCom);
//	RequestContentForTeam(eTeam_Alien);
//}

simulated function InitLevel()
{
	super.InitLevel();
}

simulated protected function PostLevelLoaded()
{
	super.PostLevelLoaded();
}

// --------------------------------------------------------------
// --------------------------------------------------------------
protected function InitPlayers(optional bool bLoading = false)
{
	
}

function SwapTeams(XComGameState_Unit Unit, ETeam NewTeam)
{
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule TacticalRuleContext;
	local XComGameState NewGameState;

	if(Unit == none)
	{
		`Redscreen("Error! No unit specified when attempting to swap teams! - David B.");
		return;
	}

	History = `XCOMHISTORY;
	if(History.GetStartState() != none)
	{
		`Redscreen("Error! You can't change a unit's team in the start state! - David B.");
	}

	TacticalRuleContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitChangedTeams);

	// fill out the unit and player refs so the context knows who to switch to which team when you .
	TacticalRuleContext.UnitRef = Unit.GetReference();
	switch( NewTeam )
	{
	case eTeam_XCom:
		TacticalRuleContext.PlayerRef.ObjectID = GetHumanPlayer().ObjectID;
		break;
	case eTeam_Alien:
		TacticalRuleContext.PlayerRef.ObjectID = GetAIPlayer().ObjectID;
		break;
	case eTeam_Neutral:
		TacticalRuleContext.PlayerRef.ObjectID = GetCivilianPlayer().ObjectID;
		break;
	case eTeam_TheLost:
		TacticalRuleContext.PlayerRef.ObjectID = GetTheLostPlayer().ObjectID;
		break;
	case eTeam_Resistance:
		TacticalRuleContext.PlayerRef.ObjectID = GetResistancePlayer().ObjectID;
		break;
	case eTeam_One: //issue #188: accounting for MP teams
		TacticalRuleContext.PlayerRef.ObjectID = class'CHHelpers'.static.GetTeamOnePlayer().ObjectID;
		break;
	case eTeam_Two:
		TacticalRuleContext.PlayerRef.ObjectID = class'CHHelpers'.static.GetTeamTwoPlayer().ObjectID;
		break; //end issue #188
	default:
		`assert(false);
	}

	NewGameState = TacticalRuleContext.ContextBuildGameState();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// --------------------------------------------------------------
// --------------------------------------------------------------
// Note: if iNumSpawnPoints == -1, then we return all spawn points found
function array<XComSpawnPoint> GetSpawnPoints( ETeam eUnitTeam, optional int iNumSpawnPoints=-1 )
{
	local array<XComSpawnPoint> arrSpawnPoints;
	local array<XComSpawnPointNativeBase> SpawnGroupPoints;
	local int kPlayCount;

	local XComSpawnPointNativeBase SpawnPoint;
	local XComSpawnPoint StartSpot;
	local XComSpawnPoint_Alien kAlienSpawnPt;
	//local int iStartTag;

	local name SpawnGroupTag;
	`assert(false);
	
	// IF( We are looking for spawn points for the XCom Squad )
	if( eUnitTeam == eTeam_XCom )
	{
		//foreach DynamicActors( class 'XComSpawnPoint', StartSpot )
		//{
		//	if( iNumSpawnPoints != -1 && arrSpawnPoints.Length == iNumSpawnPoints )
		//		return arrSpawnPoints;

		//		if( StartSpot.UnitType == UNIT_TYPE_Tank || StartSpot.UnitType == UNIT_TYPE_Soldier )
		//		{
		//			// IF( This spawn point wants a certain position in the array )
		//			if( StartSpot.Tag != 'XComSpawnPoint' )
		//			{
		//				iStartTag = int(string(StartSpot.Tag));
		//				// Make sure this spot isn't already taken
		//				if( arrSpawnPoints[iStartTag] == none )
		//				{
		//					arrSpawnPoints[iStartTag] = StartSpot;
		//					continue;
		//				}
		//			}

		//			// The spawn point isn't ordered, so just throw it on the pile
		//			arrSpawnPoints.AddItem( StartSpot );
		//		}
		//}

		kPlayCount = GetSpawnGroup(SpawnGroupTag);

		class'XComSpawnPointNativeBase'.static.FindSpawnGroup(eUnitTeam, SpawnGroupPoints, SpawnGroupTag, kPlayCount);

		foreach SpawnGroupPoints(SpawnPoint)
		{
			StartSpot = XComSpawnPoint(SpawnPoint);
			if (StartSpot != none)
				arrSpawnPoints.InsertItem( 0, StartSpot);
		}
	}
	// ELSE IF( We are looking for spawn points for the Aliens )
	else if( eUnitTeam == eTeam_Alien )
	{
		foreach DynamicActors( class 'XComSpawnPoint_Alien', kAlienSpawnPt )
		{
			if( iNumSpawnPoints != -1 && arrSpawnPoints.Length == iNumSpawnPoints )
				return arrSpawnPoints;

			// Don't allow any "kismet spawn only" aliens to be added to the level spawn.
			if( !kAlienSpawnPt.bKismetSpawnOnly )
				arrSpawnPoints.AddItem( kAlienSpawnPt );
		}
	}
	else if (eUnitTeam == eTeam_Neutral )
	{
		arrSpawnPoints = GetAnimalSpawnPoints();
	}
	
	return arrSpawnPoints;
}

// --------------------------------------------------------------
// --------------------------------------------------------------
protected function array<XComSpawnPoint> GetAnimalSpawnPoints()
{
	local array<XComSpawnPoint> arrSpawnPoints;
	local XComSpawnPoint kSpawnPt;
	
	foreach DynamicActors( class 'XComSpawnPoint', kSpawnPt )
	{
		if( kSpawnPt.UnitType == UNIT_TYPE_Animal )
			arrSpawnPoints.AddItem( kSpawnPt );
	}
	
	return arrSpawnPoints;
}
// --------------------------------------------------------------
function array<XComSpawnPoint> GetCivilianSpawnPoints()
{
	local array<XComSpawnPoint> arrSpawnPoints;
	local XComSpawnPoint kSpawnPt;
	
	foreach DynamicActors( class 'XComSpawnPoint', kSpawnPt )
	{
		if( kSpawnPt.UnitType == UNIT_TYPE_Civilian )
			arrSpawnPoints.AddItem( kSpawnPt );
	}
	
	return arrSpawnPoints;
}
// --------------------------------------------------------------
function array<XComSpawnPoint> GetLootSpawnPoints()
{
	local array<XComSpawnPoint> arrSpawnPoints;
	local XComSpawnPoint kSpawnPt;
	
	foreach DynamicActors( class 'XComSpawnPoint', kSpawnPt )
	{
		if( kSpawnPt.UnitType == UNIT_TYPE_Loot )
			arrSpawnPoints.AddItem( kSpawnPt );
	}
	
	return arrSpawnPoints;
}
// --------------------------------------------------------------

protected function UpdateVisibility()
{
	//@TODO - rmcfall - replace sight manager check
}

// --------------------------------------------------------------
// --------------------------------------------------------------
simulated function XGSquad GetEnemySquad( XGPlayer kPlayer )
{
	return GetEnemyPlayer(kPlayer).GetSquad();
}

simulated function XGPlayer GetEnemyPlayer( XGPlayer kPlayer )
{
	local XGPlayer EnemyPlayer;
	local XComGameState_Player PlayerStateObject, EnemyStateObject, StateObject;

	if (kPlayer == none)
		return none;

	PlayerStateObject = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(kPlayer.ObjectID));

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', StateObject)
	{
		if (StateObject.ObjectID == PlayerStateObject.ObjectID)
			continue;
		EnemyStateObject = StateObject;
		if (PlayerStateObject.IsEnemyPlayer(EnemyStateObject))
			break;
	}
	if (EnemyStateObject != none)
	{
		EnemyPlayer = XGPlayer(EnemyStateObject.GetVisualizer());
	}
	return EnemyPlayer;
}

// --------------------------------------------------------------
// This function is called every frame.  It checks to see if the
// active player has decided to end their turn...
// --------------------------------------------------------------
function bool TurnIsComplete()
{
	return m_kActivePlayer.IsTurnDone();
}

// --------------------------------------------------------------
// Is the active player ready to begin a new turn?
function bool ReadyForNewTurn()
{
	return true;
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function CompleteCombat()
{
	PRES().m_kNarrativeUIMgr.Shutdown();

	m_kVolumeDuckingMgr.Destroy();

	`XMCP.EndMatchSP();

	`log("PLAYING SPECIFIC LOADING MOVIE");

	if (DESC().m_iMissionType == eMission_HQAssault)
	{
		`XENGINE.PlaySpecificLoadingMovie("1080_PropLoad_001.bik");	
		`MAPS.ResetTransitionMap();
	}
	else
	{
		`XENGINE.PlaySpecificLoadingMovie("TP_UnloadScreen.bik");	
	}
	
	`ONLINEEVENTMGR.SaveProfileSettings();  // save any ERecapStats values
	`ONLINEEVENTMGR.SaveTransport();

	if(false)   //  @TODO gameplay / design - handle failure on the first mission
	{
		//We lost the fist mission, go back to the main menu
		ConsoleCommand("demostop");
		ConsoleCommand("disconnect");
	}
	else
	{
		`ONLINEEVENTMGR.StartLoadFromStoredStrategy();
	}
}

// --------------------------------------------------------------
// --------------------------------------------------------------
simulated function XGPlayer GetLocalPlayer()
{
	return m_arrPlayers[0];
}
// --------------------------------------------------------------
// --------------------------------------------------------------
function XGPlayer GetHumanPlayer()
{
	local XComGameState_Player PlayerState;

	PlayerState = none;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.PlayerClassName == Name( "XGPlayer" ) )
		{
			break;
		}
	}

	return XGPlayer(PlayerState.GetVisualizer());
}
// --------------------------------------------------------------
// --------------------------------------------------------------
function XComGameState_Player GetAIPlayerState()
{
	local XComGameState_Player PlayerState;

	PlayerState = None;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.PlayerClassName == Name("XGAIPlayer") )
		{
			break;
		}
	}

	return PlayerState;
}

function XGPlayer GetAIPlayer()
{
	local XComGameState_Player PlayerState;

	PlayerState = GetAIPlayerState();

	return (PlayerState != none) ? XGPlayer(PlayerState.GetVisualizer()) : none;
}
//---------------------------------------------------------------
//---------------------------------------------------------------
function XGAIPlayer_Civilian GetCivilianPlayer()
{
	local XComGameState_Player PlayerState;
	
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.PlayerClassName == Name( "XGAIPlayer_Civilian" ) )
		{
			break;
		}
	}

	return PlayerState != none ? XGAIPlayer_Civilian(PlayerState.GetVisualizer()) : none;
}
// --------------------------------------------------------------
//---------------------------------------------------------------
function XGAIPlayer_TheLost GetTheLostPlayer()
{
	local XComGameState_Player PlayerState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.PlayerClassName == Name("XGAIPlayer_TheLost") )
		{
			break;
		}
	}

	return PlayerState != none ? XGAIPlayer_TheLost(PlayerState.GetVisualizer()) : none;
}
// --------------------------------------------------------------
// --------------------------------------------------------------
function XGAIPlayer_Resistance GetResistancePlayer()
{
	local XComGameState_Player PlayerState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.PlayerClassName == Name("XGAIPlayer_Resistance") )
		{
			break;
		}
	}

	return PlayerState != none ? XGAIPlayer_Resistance(PlayerState.GetVisualizer()) : none;
}
// --------------------------------------------------------------
// --------------------------------------------------------------

function bool PlayerCanSave()
{	
	local XGUnit    kUnit;
	local XGSquad   kSquad;

	// You may not save if we are not even functional yet. We must make it to
	// the bottom of the Running begin block before saves are allowed -- jboswell
	if (!self.AtBottomOfRunningStateBeginBlock())
		return false;

	kSquad = GetHumanPlayer().GetSquad();
	kUnit = kSquad.GetNextGoodMember(,,false);
	while (kUnit != none)
	{
		if (kUnit.IsPanicking() || kUnit.IsWaitingToPanic()) // Wait for panicking action to complete before allowing saves. #5926
			return false;
		kUnit = kSquad.GetNextGoodMember(kUnit,,false);
	}
	return m_kActivePlayer == GetHumanPlayer();
}

//  yes this is a copy of PlayerCanSave but that could change....
function bool PlayerCanAbort()
{	
	local XGUnit    kUnit;
	local XGSquad   kSquad;

	kSquad = GetHumanPlayer().GetSquad();
	kUnit = kSquad.GetNextGoodMember(,,false);
	while (kUnit != none)
	{
		if (kUnit.IsUnitBusy())
		{
			return false;
		}
		kUnit = kSquad.GetNextGoodMember(kUnit,,false);
	}

	return true;
}

// --------------------------------------------------------------
// --------------------------------------------------------------

simulated function XComPresentationLayer PRES()
{
	if (GetHumanPlayer().m_kPlayerController == None) return None;
	return XComPresentationLayer(GetHumanPlayer().m_kPlayerController.Pres);
}

simulated function XComGameState_BattleData DESC()
{
	if (m_kDesc == None)
		RefreshDesc();
	return m_kDesc;
}

state Running
{
	event BeginState(name PrevState)
	{
		super.BeginState(PrevState);

		m_kVolumeDuckingMgr = new(self) class'XComVolumeDuckingMgr';
		m_kVolumeDuckingMgr.Init();
	}

	simulated event Tick( float fDeltaT )
	{
		super.Tick(fDeltaT);
		
		m_kVolumeDuckingMgr.Tick(fDeltaT);
	}

	function bool IsPaused()
	{
        // In Single Player games, battle is paused when the human player is busy (Waiting for camera, waiting for UI)
		return PRES().IsBusy() || m_bInCinematic || IsPlayerPanicking() || m_bInPauseMenu;
	}
}

function string GetIntroMovie()
{
	return "";
}

// --------------------------------------------------------------

function int GetForceLevel()  
{
	// Check for override value from UI
	if (m_kDesc == None)
		RefreshDesc();

	return m_kDesc.GetForceLevel();
}

// --------------------------------------------------------------

function int GetPopularSupport()  
{
	// Check for override value from UI
	if (m_kDesc == None)
		RefreshDesc();

	return m_kDesc.GetPopularSupport();
}
// --------------------------------------------------------------

function SetPopularSupport(int iValue)  
{
	// Check for override value from UI
	if (m_kDesc == None)
		RefreshDesc();

	m_kDesc.SetPopularSupport(iValue);
}
// --------------------------------------------------------------

function int GetMaxPopularSupport()  
{
	// Check for override value from UI
	if (m_kDesc == None)
		RefreshDesc();

	return m_kDesc.GetMaxPopularSupport();
}
// --------------------------------------------------------------

function SetMaxPopularSupport(int iValue)  
{
	// Check for override value from UI
	if (m_kDesc == None)
		RefreshDesc();

	m_kDesc.SetMaxPopularSupport(iValue);
}

function bool ShouldOverrideCivilianHostility()
{
	return GetDesc().ShouldOverrideCivilianHostility();
}

// This check is mainly used to determine if Civilians should go into red alert when seeing XCom units.  Can also be accessed from BTs.
function bool IsLowPopularSupport()
{
	if (ShouldOverrideCivilianHostility())
	{
		return false;
	}
	return GetPopularSupport() < class'XComGameState_WorldRegion'.default.WorldRegion_PopSupportCivilianAlertThreshold;
}

// --------------------------------------------------------------
// These are updates to allow checks if any enemy within the map is alerted
// Currently used with AdventTower animation states, but could be used for other purposes in the future [Chang You 2015_4_23]
function bool AnyEnemyInVisualizeAlert_Red()
{
	return m_OneOrMoreEnemyVisualizeInRedAlert;
}
function Update_GlobalEnemyVisualizeAlertFlags()
{
	local XGPlayer AIPlayer;
	local XComGameState_Unit enemy;
	local array<XComGameState_Unit> Enemies_array;
	m_OneOrMoreEnemyVisualizeInRedAlert = false;
	AIPlayer = `battle.GetAIPlayer();
	AIPlayer.GetAliveUnits(Enemies_array);
	foreach Enemies_array(enemy)
	{
		if ( enemy.GetCurrentStat(eStat_AlertLevel) > `ALERT_LEVEL_YELLOW )
		{
			m_OneOrMoreEnemyVisualizeInRedAlert = true;
			break;
		}
	}
}

DefaultProperties
{
	m_bAchivementsEnabled=true
}
