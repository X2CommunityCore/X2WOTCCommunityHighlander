//-----------------------------------------------------------
// NOTE: This class is serialized on loading/saving games.
// This will save any properties not marked deprecated or transient.
//-----------------------------------------------------------
class XGStrategy extends Actor config(GameData);

var localized string m_strNewItemAvailable;
var localized string m_strNewItemHelp;

var localized string m_strNewFacilityAvailable;
var localized string m_strNewFacilityHelp;

var localized string m_strNewFoundryAvailable;
var localized string m_strNewFoundryHelp;

// Saved Data
var XGGeoscape					m_kGeoscape;
var bool						m_bDebugStart;
var bool						m_bDebugStartNonCheat;
var XGNarrative					m_kNarrative;
var bool						m_bTutorial;
var bool						m_bLost;
var bool						m_bGameOver;
var bool						m_bOvermindEnabled;
var bool						m_bIronMan;
var bool						m_bControlledStart;         // 
var bool						m_bShowRecommendations;
var float						m_fGameDuration;
var bool						m_bPlayedTutorial;
var bool                        m_bCompletedFirstMec;
var bool						m_bUsedEEC;
var array<int>					m_arrSecondWave;
var protectedwrite bool			m_bLoadedFromSave;
var bool						SimCombatNextMission;
var protected vector			DropshipLocation;
var protected Rotator			DropshipRotation;

var config int					DEBUG_StartingValueSupplies;
var config int					DEBUG_StartingValueIntel;
var config int					DEBUG_StartingValueElerium;
var config int					DEBUG_StartingValueAlloys;
var config array<name>			DEBUG_StartingTechs;
var config array<name>			DEBUG_StartingItems;
var config int					DEBUG_StartingItemQuantity;
var config array<name>			DEBUG_StartingSoldierClasses;
var config array<name>			DEBUG_StartingSoldierCharacters;
var config array<name>			DEBUG_StartingFacilities;
var config int					DEBUG_FacilityIndex;
var config array<name>			DEBUG_SecondWaveOptions; // Issue #197
var config float				RainPctChance;

function Init()
{
	local XComGameStateHistory History;	
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	History = `XCOMHISTORY;	

	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	m_kGeoscape = Spawn( class'XGGeoscape' );	
	m_kNarrative = spawn(class'XGNarrative');
	m_kNarrative.InitNarrative(CampaignSettingsStateObject.bSuppressFirstTimeNarrative);
	m_arrSecondWave.Add(eGO_MAX);
	m_bGameOver = false;
	`HQPRES.InitUIScreens();
	`HQPRES.SetNarrativeMgr(m_kNarrative);
	m_bOvermindEnabled = true;
	
	`GAME.m_bIronman = CampaignSettingsStateObject.bIronmanEnabled;

	m_bTutorial = CampaignSettingsStateObject.bTutorialEnabled;

	//Handle the various types of cheating that the dev strategy shell provides
	m_bDebugStart = CampaignSettingsStateObject.bCheatStart;
	m_bDebugStartNonCheat = CampaignSettingsStateObject.bSkipFirstTactical;

	if(m_bDebugStart || m_bDebugStartNonCheat)
	{
		XComHeadquartersGame(WorldInfo.Game).m_bControlledStartFromShell = true;
	}

	GotoState( 'Initing' );
}

function OnLoadedGame()
{
	m_bLoadedFromSave = true;
	Init();
}

function PostLoadSaveGame()
{
	m_bLoadedFromSave = false;

	// Refresh wanted captures
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshWantedCaptures();
}

function NotifyUserOfInvalidSave()
{
	if(`HQPRES != none && `HQPRES.m_bInitialized)
	{
		ClearTimer(nameof(NotifyUserOfInvalidSave));
		`HQPRES.PopupDebugDialog("Invalid Save", "Your Save contains broken item data");
	}
}

function PreloadTacticalPlot(int MissionID)
{
	local XComGameStateHistory History;
	local XComMapManager Maps;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite StartingMission;
	local GeneratedMissionData MissionData;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	//  MissionID should always be passed in, except when starting a new game, so just make a mission now and go.
	if(MissionID == -1) 
	{
		//When starting a new game, a mission site should have been created
		foreach History.IterateByClassType(class'XComGameState_MissionSite', StartingMission)
		{
			if(StartingMission.GetMissionSource().bStart)
			{
				MissionID = StartingMission.ObjectID;				
				break;
			}
		}
	}

	MissionData = XComHQ.GetGeneratedMissionData(MissionID);

	//Preload the plot
	Maps = `MAPS;	
	Maps.PreloadMap(MissionData.Plot.MapName);
}

state Initing
{
Begin:
	
	while( `HQPRES.IsBusy() )
		Sleep( 0 );
	
	//Detect whether we starting a new campaing or not
	if( `XCOMHISTORY.GetNumGameStates() == 1 )
	{		
		if( XComHeadquartersGame(WorldInfo.Game).m_bControlledStartFromShell )
		{			
			DebugCheatStartGame();
			
		}
		else if(m_bTutorial)
		{
			TutorialStartGame();
		}
		else
		{		
			`STRATEGYRULES.StartNewGame();
			`STRATEGYRULES.GameTime = GetGameTime();
			NewGameEventHook();

			PreloadTacticalPlot(-1); //Starting mission

			class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);

			//Allow the user to skip the movie now that the major work / setup is done
			`XENGINE.SetAllowMovieInput(true);

			//The loading movie will be playing the intro movie at the start of a new campaign. Wait until it is over / skipped
			while(class'XComEngine'.static.IsAnyMoviePlaying())
			{
				Sleep(0.0f);
			}

			`XSTRATEGYSOUNDMGR.PlayHQMusicEvent();
			`XSTRATEGYSOUNDMGR.PlaySquadSelectMusic();		

			Sleep(0.25f); //Give the music ak event time to start

			LaunchTacticalBattle();
		}
	}
	else
	{		
		if(m_bLoadedFromSave)
		{
			LoadGame();
		}
		else
		{
			TransferFromTactical();
		}
		
	}
}

function PrepareTacticalBattle(int MissionID)
{
	local XComGameStateHistory History;	
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference MissionReference;
	local XComGameState_Item IterateItemState;
	local StateObjectReference EmptyRef;

	//This is a holdover until we can get strategy on board with the game state system. A game state with critical 
	//strategy data is stored in here (ie. avenger location)
	local XComGameState SaveStrategyState;

	History = `XCOMHISTORY;
	//MissionManager = `TACTICALMISSIONMGR;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	//if (XComHQ.GetGeneratedMissionData(MissionID, GeneratedMission))
		//return;                     //  mission was already created, don't make another one!

	//Create a strategy save state. Since the strategy game is not yet operating using the game state system, we
	//perform the minimal set of state storage necessary to restore the strategy game upon returning from the 
	//mission we are about to launch
	SaveStrategyState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Preparing Tactical Battle");
	XComHQ = XComGameState_HeadquartersXCom(SaveStrategyState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	MissionReference.ObjectID = MissionID;
	XComHQ.MissionRef = MissionReference;

	foreach History.IterateByClassType(class'XComGameState_Item', IterateItemState)
	{
		if( IterateItemState.CosmeticUnitRef.ObjectID > 0 )
		{
			IterateItemState = XComGameState_Item(SaveStrategyState.ModifyStateObject(class'XComGameState_Item', IterateItemState.ObjectID));
			IterateItemState.CosmeticUnitRef = EmptyRef;
		}
	}
		
	//This save state is special, so add it directly to the history. (Normally we would go through the ruleset object!)
	History.AddGameStateToHistory(SaveStrategyState);	
	
	//  At this point, the mission has been generated and saved in the history. LaunchTacticalBattle needs to be called to get it going.
}

// TEMP Mission reward name and amount to simulate strategy->tactical loop
function LaunchTacticalBattle(optional int MissionID = -1)
{
	local int RewardIndex;
	local int UnitIndex, ItemIndex, i;
	local bool FirstMission;
	local XComGameStateHistory History;	
	local XComGameState NewStartState;
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit SendSoldierState;
	local XComGameState_Unit ProxySoldierState;
	local StateObjectReference XComPlayerRef;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComTacticalMissionManager MissionManager;
	local GeneratedMissionData GeneratedMission;
	local XComGameState_MissionSite StartingMission, MissionState;
	local XComGameState_GameTime TimeState;
	local XComGameState_Player XComPlayer;
	local XComGameState_Reward RewardStateObject;
	local Vector2D MissionCoordinates;
	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;
	local string MissionBriefing;
	local XComGameState_Tech OldTechState;
	local XComGameState_Objective OldObjectiveState;
	local XComGameState_ObjectivesList ObjectivesList;
	local XComGameState_WorldNarrativeTracker NarrativeTracker;
	local XComGameState_ScanningSite ScanningSiteState;
	local XComGameState_Continent ContinentState;
	local XComGameState_HeadquartersProjectResearch ResearchProjectState;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_NarrativeManager NarrativeMgr;

	`XCOMVISUALIZATIONMGR.DisableForShutdown();

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();

	History = `XCOMHISTORY;
	MissionManager = `TACTICALMISSIONMGR;

	if (MissionID == -1) //  MissionID should always be passed in, except when starting a new game, so just make a mission now and go.
	{
		//When starting a new game, a mission site should have been created
		foreach History.IterateByClassType(class'XComGameState_MissionSite', StartingMission)
		{
			if(StartingMission.GetMissionSource().bStart)
			{
				MissionID = StartingMission.ObjectID;
				FirstMission = true;
				break;
			}
		}

		PrepareTacticalBattle(MissionID);
	}	
	else
	{
		//If this is not the first mission, pause the geoscape so that additional processing does not push states after the start state
		`GAME.GetGeoscape().Pause();
	}

	//`XSTRATEGYSOUNDMGR.StopHQMusicEvent();
	//Create a new game state that will form the start state for the tactical battle. Use this helper method to set up the basics and
	//get a reference to the battle data object
	NewStartState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Singleplayer(BattleData);

	// clear recap data in res hq
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResistanceHQ = XComGameState_HeadquartersResistance(NewStartState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	ResistanceHQ.ClearRewardsRecapData();
	ResistanceHQ.ClearVIPRewardsData();

	// copy the xcom hq
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewStartState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.QueuedDynamicPopups.Length = 0;	// clear the delegates here holding on to 

	if(XComHQ.AllSquads.Length == 0)
	{
		// support for legacy saves and missions that don't go through squad select, make sure the xcom squad
		// shows up in the list of squads
		XComHQ.AllSquads.Add(1);
		XComHQ.AllSquads[0].SquadMembers = XComHQ.Squad;
	}

	// copy the alien hq
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewStartState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));

	// copy the Advent Chosen
	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		ChosenState = XComGameState_AdventChosen(NewStartState.ModifyStateObject(class'XComGameState_AdventChosen', ChosenState.ObjectID));
	}

	//Copy time state into the new start state
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	TimeState = XComGameState_GameTime(NewStartState.ModifyStateObject(class'XComGameState_GameTime', TimeState.ObjectID));	

	// Copy the world narrative tracker over (if one exists)
	NarrativeTracker = XComGameState_WorldNarrativeTracker(History.GetSingleGameStateObjectForClass(class'XComGameState_WorldNarrativeTracker', true));
	if(NarrativeTracker != none)
	{
		NewStartState.ModifyStateObject(class'XComGameState_WorldNarrativeTracker', NarrativeTracker.ObjectID);
	}

	// Copy the dynamic narrative manager
	NarrativeMgr = XComGameState_NarrativeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_NarrativeManager'));
	NarrativeMgr = XComGameState_NarrativeManager(NewStartState.ModifyStateObject(class'XComGameState_NarrativeManager', NarrativeMgr.ObjectID));

	ObjectivesList = XComGameState_ObjectivesList(History.GetSingleGameStateObjectForClass(class'XComGameState_ObjectivesList'));
	ObjectivesList = XComGameState_ObjectivesList(NewStartState.ModifyStateObject(class'XComGameState_ObjectivesList', ObjectivesList.ObjectID));

	// add each tech to the tactical start state
	foreach History.IterateByClassType(class'XComGameState_Tech', OldTechState)
	{
		NewStartState.ModifyStateObject(class'XComGameState_Tech', OldTechState.ObjectID);
	}

	// add each objective to the tactical start state
	foreach History.IterateByClassType(class'XComGameState_Objective', OldObjectiveState)
	{
		NewStartState.ModifyStateObject(class'XComGameState_Objective', OldObjectiveState.ObjectID);
	}

	// add each region to the tactical start state
	foreach History.IterateByClassType(class'XComGameState_ScanningSite', ScanningSiteState)
	{
		NewStartState.ModifyStateObject(class'XComGameState_ScanningSite', ScanningSiteState.ObjectID);
	}

	// add each continent to the tactical start state so we can check the bonuses
	foreach History.IterateByClassType(class'XComGameState_Continent', ContinentState)
	{
		NewStartState.ModifyStateObject(class'XComGameState_Continent', ContinentState.ObjectID);
	}

	// add the current research project to the tactical start state
	ResearchProjectState = XComHQ.GetCurrentResearchProject();
	if( ResearchProjectState != None )
	{
		NewStartState.ModifyStateObject(class'XComGameState_HeadquartersProjectResearch', ResearchProjectState.ObjectID);
	}
	
	//Copy data that was previously prepared into the battle data
	`assert(!BattleData.bReadOnly);

	GeneratedMission = XComHQ.GetGeneratedMissionData(MissionID);

	MissionTemplate = MissionTemplateManager.FindMissionTemplate(GeneratedMission.Mission.MissionName);
	if (MissionTemplate != none)
	{
		MissionBriefing = MissionTemplate.Briefing;
	}
	else
	{
		MissionBriefing  = "NO LOCALIZED BRIEFING TEXT!";
	}

	BattleData.m_bIsFirstMission = FirstMission;
	BattleData.iLevelSeed = GeneratedMission.LevelSeed;
	BattleData.m_strDesc    = MissionBriefing;
	BattleData.m_strOpName  = GeneratedMission.BattleOpName;
	BattleData.MapData.PlotMapName = GeneratedMission.Plot.MapName;
	BattleData.MapData.Biome = GeneratedMission.Biome.strType;	

	// Force Level
	BattleData.SetForceLevel(AlienHQ.GetForceLevel());

	// Alert Level
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(MissionID));
	BattleData.SetAlertLevel(MissionState.GetMissionDifficulty());

	// Safety Mission Tags call
	XComHQ.AddMissionTacticalTags(MissionState);

	// Make the map command based on whether we are riding the dropship to the mission or not
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
	`HQPRES.HideUIForCinematics();
	if(MissionState.GetMissionSource().bRequiresSkyrangerTravel)
	{
		if(class'XComMapManager'.default.bUseSeamlessTravelToTactical)
		{
			BattleData.m_strMapCommand = "servertravel" @ GeneratedMission.Plot.MapName $ "?game=XComGame.XComTacticalGame";
		}
		else
		{
			`XENGINE.PlaySpecificLoadingMovie("CIN_XP_UI_LogoSpin.bk2");
			`XENGINE.PlayLoadMapMovie(-1);
			BattleData.m_strMapCommand = "open" @ GeneratedMission.Plot.MapName $ "?game=XComGame.XComTacticalGame";			
		}
	}
	else
	{
		if(MissionState.GetMissionSource().CustomLoadingMovieName_Intro != "")
		{
			`XENGINE.PlaySpecificLoadingMovie(MissionState.GetMissionSource().CustomLoadingMovieName_Intro, MissionState.GetMissionSource().CustomLoadingMovieName_IntroSound);
			`XENGINE.PlayLoadMapMovie(-1);
		}		
		BattleData.m_strMapCommand = "open" @ GeneratedMission.Plot.MapName $ "?game=XComGame.XComTacticalGame";
	}

	// For civilian behavior (may be deprecated)
	BattleData.SetPopularSupport(0);
	BattleData.SetMaxPopularSupport(1000);
	
	BattleData.LocalTime = TimeState.CurrentTime;
	MissionCoordinates.X = MissionState.Location.X;
	MissionCoordinates.Y = MissionState.Location.Y;
	class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime( MissionCoordinates, BattleData.LocalTime );
	BattleData.m_strLocation = MissionState.GetLocationDescription();

	BattleData.m_iMissionID = MissionID;
	BattleData.bRainIfPossible = FRand() < RainPctChance; // if true, doesn't guarantee rain, map must be able to support raining.

	MissionManager.ForceMission = GeneratedMission.Mission;
	MissionManager.MissionQuestItemTemplate = GeneratedMission.MissionQuestItemTemplate;
	
	XComPlayerRef = BattleData.PlayerTurnOrder[0];

	//  Copy all purchased unlocks to the player state
	XComPlayer = XComGameState_Player(NewStartState.GetGameStateForObjectID(XComPlayerRef.ObjectID));
	XComPlayer.SoldierUnlockTemplates = XComHQ.SoldierUnlockTemplates;

	// choose the starting squad (the actual selection can be modified per mission type)
	class'X2MissionTemplate'.static.GetMissionSquad(MissionState.GeneratedMission.Mission.sType, XComHQ.Squad);

	//Add starting units and their inventory items
	//Assume that the squad limits were followed correctly in the Avenger UI
	for( UnitIndex = 0; UnitIndex <  XComHQ.Squad.Length; ++UnitIndex )
	{
		if(XComHQ.Squad[UnitIndex].ObjectID <= 0)
			continue;
		
		SendSoldierState = XComGameState_Unit( History.GetGameStateForObjectID(XComHQ.Squad[UnitIndex].ObjectID) );
		
		if( !SendSoldierState.IsSoldier() ) { `HQPRES.PopupDebugDialog("ERROR", "Attempting to send a non-soldier unit to battle."); continue; }
		if( !SendSoldierState.IsAlive() )   { `HQPRES.PopupDebugDialog("ERROR", "Attempting to send a dead soldier to battle."); continue; }

		SendSoldierState = XComGameState_Unit( NewStartState.ModifyStateObject(class'XComGameState_Unit', SendSoldierState.ObjectID) );

		//Add this soldier's items to the start state
		for( ItemIndex = 0; ItemIndex < SendSoldierState.InventoryItems.Length; ++ItemIndex )
		{
			NewStartState.ModifyStateObject(class'XComGameState_Item', SendSoldierState.InventoryItems[ItemIndex].ObjectID);
		}
		
		SendSoldierState.SetControllingPlayer( XComPlayerRef );
		SendSoldierState.SetHQLocation(eSoldierLoc_Dropship);
		SendSoldierState.ClearRemovedFromPlayFlag();
	}

	//Add any reward personnel to the battlefield
	for( RewardIndex = 0; RewardIndex < MissionState.Rewards.Length; ++RewardIndex )
	{
		RewardStateObject = XComGameState_Reward(History.GetGameStateForObjectID(MissionState.Rewards[RewardIndex].ObjectID));
		SendSoldierState = XComGameState_Unit(History.GetGameStateForObjectID(RewardStateObject.RewardObjectReference.ObjectID));
		if(MissionState.IsVIPMission() && SendSoldierState != none)
		{
			//Add the reward unit to the battle

			// create a proxy if needed. This allows the artists and LDs to create simpler standin versions of units,
			// for example soldiers without weapons.
			// Unless the reward is a soldier with a tactical tag to be specifically passed into the mission
			ProxySoldierState = none;
			if (RewardStateObject.GetMyTemplateName() != 'Reward_Soldier' || SendSoldierState.TacticalTag == '')
			{
				ProxySoldierState = class'XComTacticalMissionManager'.static.CreateProxyRewardUnitIfNeeded(SendSoldierState, NewStartState);
			}

			if(ProxySoldierState == none)
			{
				// no proxy needed, so just send the original
				ProxySoldierState = SendSoldierState;
			}

			// all reward units start on the neutral team
			ProxySoldierState.SetControllingPlayer( BattleData.CivilianPlayerRef );

			//Track which units the battle is considering to be rewards ( used later when spawning objectives ).
			BattleData.RewardUnits.AddItem(ProxySoldierState.GetReference());

			// Also keep track of what the original unit was that the proxy was spawned from. If no proxy was made,
			// then just insert a null so we know there was no original
			BattleData.RewardUnitOriginals.AddItem(SendSoldierState.GetReference());
		}
	}

	// allow sitreps to modify the battle data state before we transition to tactical
	class'X2SitRepTemplate'.static.ModifyPreMissionBattleDataState(BattleData, MissionState.GeneratedMission.SitReps);

	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPreMission(NewStartState, MissionState);
	}

	//Add the start state to the history
	History.AddGameStateToHistory(NewStartState);

	//Tell the content manager to build its list of required content based on the game state that we just built and added.
	`CONTENT.RequestContent();

	// at the end of the session, the event listener needs to be cleared of all events and listeners; reset it
	`XEVENTMGR.ResetToDefaults(false);

	`XENGINE.m_kPhotoManager.CleanupUnusedTextures();

	//Launch into the tactical map
	ConsoleCommand( BattleData.m_strMapCommand );
}

function Uninit()
{
	m_kGeoscape.Destroy();
}

function XGGeoscape GetGeoscape()
{
	return m_kGeoscape;
}

function DebugCheatStartGame()
{
	`STRATEGYRULES.StartNewGame();
	GoToState('StartingDebugCheatGame');	
}

function TutorialStartGame()
{
	`STRATEGYRULES.StartNewGame();
	GoToState('StartingFromTutorial');
}

function LoadGame()
{
	`STRATEGYRULES.StartNewGame();
	GoToState('LoadingGame');
}

function TransferFromTactical()
{
	`STRATEGYRULES.StartNewGame();
	GoToState('StartingFromTactical');
}

function GoToHQ()
{
	GotoState( 'Headquarters' );
}

function NewGameEventHook()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("New Game Event Hook");
	`XEVENTMGR.TriggerEvent('OnNewGame', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function TDateTime GetGameTime()
{
	local XComGameState_GameTime TimeState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_GameTime', TimeState)
	{
		break;
	}
	`assert(TimeState != none);
	return TimeState.CurrentTime;
}

function UpdateDLCLoadingStrategyGame()
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnLoadedSavedGameToStrategy();
	}
}

state Headquarters
{
	function HandleTutorialBlockers()
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_FacilityXCom FacilityState;
		local XComGameState_HeadquartersRoom RoomState;
		local bool bAllFacilitiesLocked, bAllRoomsLocked;

		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		bAllFacilitiesLocked = true;
		bAllRoomsLocked = true;

		if(XComHQ.GetObjectiveStatus('T0_M1_WelcomeToLabs') == eObjectiveState_InProgress)
		{
			FacilityState = XComHQ.GetFacilityByName('PowerCore');
			if(!FacilityState.NeedsAttention())
			{
				class'X2StrategyElement_DefaultObjectives'.static.RequireAttentionToRoom('Hangar', false, true);
				return;
			}
		}
		else if(XComHQ.GetObjectiveStatus('T0_M6_WelcomeToLabsPt2') == eObjectiveState_InProgress)
		{
			FacilityState = XComHQ.GetFacilityByName('PowerCore');
			if(!FacilityState.NeedsAttention())
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Welcome Labs Pt 2 Complete");
				`XEVENTMGR.TriggerEvent('WelcomeLabsPt2Complete', , , NewGameState);
				`GAMERULES.SubmitGameState(NewGameState);
				class'X2StrategyElement_DefaultObjectives'.static.RequireAttentionToRoom('CIC', false, false, true);
				return;
			}
		}
		else if(XComHQ.GetObjectiveStatus('T0_M9_ExcavateRoom') == eObjectiveState_InProgress)
		{
			if(XComHQ.HasActiveConstructionProject())
			{
				class'X2StrategyElement_DefaultObjectives'.static.RequireAttentionToRoom('CommandersQuarters', false, true);
				return;
			}
		}

		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if(!FacilityState.bTutorialLocked)
			{
				bAllFacilitiesLocked = false;
				break;
			}
		}

		if(bAllFacilitiesLocked)
		{
			foreach History.IterateByClassType(class'XComGameState_HeadquartersRoom', RoomState)
			{
				if(!RoomState.bTutorialLocked)
				{
					bAllRoomsLocked = false;
					break;
				}
			}
		}

		if(bAllFacilitiesLocked && bAllRoomsLocked)
		{
			// general failsafe, should not reach this case
			class'X2StrategyElement_DefaultObjectives'.static.RequireAttentionToRoom('', false, false, false);
		}
	}

	event BeginState( name nmPrevState )
	{
		local XComGameState_CampaignSettings SettingsState;

		SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		`XENGINE.m_kPhotoManager.FillPropagandaTextureArray(ePWM_Campaign, SettingsState.GameIndex);

		`HQPRES.UIAvengerFacilityMenu();
		if(m_bLoadedFromSave)
		{
			HandleTutorialBlockers();
		}

		`HQPC.GotoState( 'Headquarters' );

		// When returning from combat, we start out in MC, watching the skyranger fly home
		GetGeoscape().OnEnterMissionControl();
	}
}

state StartingDebugCheatGame
{
	function DebugInitHQ()
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_Skyranger SkyrangerState;
		local XComGameState_CampaignSettings CampaignSettingsStateObject;
		local name Option; // Issue #197

		History = `XCOMHISTORY;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("DEBUG Init HQ");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		XComHQ.bDontShowSetupMovies = true;
		XComHQ.AddResource(NewGameState, 'Supplies', (default.DEBUG_StartingValueSupplies - XComHQ.GetSupplies()));
		XComHQ.AddResource(NewGameState, 'Intel', (default.DEBUG_StartingValueIntel - XComHQ.GetIntel()));
		XComHQ.AddResource(NewGameState, 'AlienAlloy', (default.DEBUG_StartingValueAlloys - XComHQ.GetAlienAlloys()));
		XComHQ.AddResource(NewGameState, 'EleriumDust', (default.DEBUG_StartingValueElerium - XComHQ.GetEleriumDust()));

		// Dock Skyranger at HQ
		SkyrangerState = XComGameState_Skyranger(NewGameState.ModifyStateObject(class'XComGameState_Skyranger', XComHQ.SkyrangerRef.ObjectID));
		SkyrangerState.Location = XComHQ.Location;
		SkyrangerState.SourceLocation.X = SkyrangerState.Location.X;
		SkyrangerState.SourceLocation.Y = SkyrangerState.Location.Y;
		SkyrangerState.TargetEntity = XComHQ.GetReference();
		SkyrangerState.SquadOnBoard = false;

		CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		CampaignSettingsStateObject = XComGameState_CampaignSettings(NewGameState.ModifyStateObject(class'XComGameState_CampaignSettings', CampaignSettingsStateObject.ObjectID));
		// Issue #197 -- replaced single 'BetaStrike' with configurable list
		/// HL-Docs: feature:DebugStartSecondWave; issue:197; tags:
		/// A debug strategy start by default uses Beta Strike and no other second wave options.
		/// This change disables Beta Strike by default and makes the list configurable.
		foreach default.DEBUG_SecondWaveOptions(Option)
		{
			CampaignSettingsStateObject.AddSecondWaveOption(Option);
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	function DebugInitItems()
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_Item ItemState;
		local X2ItemTemplateManager ItemMgr;
		local X2ItemTemplate ItemTemplate;
		local int idx, i;

		ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
		History = `XCOMHISTORY;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("DEBUG Init Items");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		
		for(idx = 0; idx < default.DEBUG_StartingItems.Length; idx++)
		{
			ItemTemplate = ItemMgr.FindItemTemplate(default.DEBUG_StartingItems[idx]);

			if(ItemTemplate != none)
			{
				if (ItemTemplate.bInfiniteItem)
				{
					ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
					XComHQ.AddItemToHQInventory(ItemState);
				}
				else
				{
					for (i = 0; i < default.DEBUG_StartingItemQuantity; i++)
					{
						ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
						XComHQ.PutItemInInventory(NewGameState, ItemState);
					}
				}
			}
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	function DebugInitTechs()
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_Tech TechState;
		local int idx;

		History = `XCOMHISTORY;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("DEBUG Init Techs");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		for(idx = 0; idx < default.DEBUG_StartingTechs.Length; idx++)
		{
			foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
			{
				if(TechState.GetMyTemplateName() == default.DEBUG_StartingTechs[idx])
				{
					TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechState.ObjectID));
					TechState.TimesResearched++;
					XComHQ.TechsResearched.AddItem(TechState.GetReference());
					TechState.bSeenResearchCompleteScreen = true;

					if(TechState.GetMyTemplate().ResearchCompletedFn != none)
					{
						TechState.GetMyTemplate().ResearchCompletedFn(NewGameState, TechState);
					}
				}
			}
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	function DebugInitSoldiers()
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_Unit UnitState;
		local XComOnlineProfileSettings ProfileSettings;
		local int idx;

		History = `XCOMHISTORY;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("DEBUG Init Soldiers");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		ProfileSettings = `XPROFILESETTINGS;

		for(idx = 0; idx < default.DEBUG_StartingSoldierClasses.Length; idx++)
		{
			UnitState = `CHARACTERPOOLMGR.CreateCharacter(NewGameState, ProfileSettings.Data.m_eCharPoolUsage);
			UnitState.RandomizeStats();
			UnitState.ApplyInventoryLoadout(NewGameState);
			UnitState.SetHQLocation(eSoldierLoc_Barracks);
			if(default.DEBUG_StartingSoldierClasses[idx] == 'PsiOperative')
			{
				//UnitState.bHasPsiGift = true;
				UnitState.bRolledForPsiGift = true;
			}
			UnitState.RankUpSoldier(NewGameState, default.DEBUG_StartingSoldierClasses[idx]);
			UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
			UnitState.StartingRank = 1;
			UnitState.SetXPForRank(1);
			UnitState.bNeedsNewClassPopup = false;
			UnitState.bIsFamous = true;
			XComHQ.AddToCrew(NewGameState, UnitState);
		}

		// Generate special soldier characters who don't use the default Soldier character template
		for (idx = 0; idx < default.DEBUG_StartingSoldierCharacters.Length; idx++)
		{
			UnitState = `CHARACTERPOOLMGR.CreateCharacter(NewGameState, ProfileSettings.Data.m_eCharPoolUsage, default.DEBUG_StartingSoldierCharacters[idx]);
			UnitState.RandomizeStats();
			UnitState.ApplyInventoryLoadout(NewGameState);
			UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
			UnitState.SetHQLocation(eSoldierLoc_Barracks);						
			UnitState.bNeedsNewClassPopup = false;
			UnitState.bIsFamous = true;

			// This is a hacky cheat just to get the soldiers looking properly in the Avenger
			// when running Debug Strategy. Should be updated to use whatever function we create
			// to generate them properly as rewards on the Strategy layer.
			if (UnitState.GetMyTemplate().GetPawnNameFn != None)
			{
				UnitState.kAppearance.nmPawn = UnitState.GetMyTemplate().GetPawnNameFn(EGender(UnitState.kAppearance.iGender));
			}

			XComHQ.AddToCrew(NewGameState, UnitState);
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	function DebugInitFacilities()
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;
		local XComGameState_HeadquartersXCom XComHQ;
		local X2StrategyElementTemplateManager StratMgr;
		local X2FacilityTemplate FacilityTemplate;
		local array<X2FacilityTemplate> FacilityTemplates;
		local array<StateObjectReference> FacilityRefs;
		local XComGameState_FacilityXCom FacilityState;
		local XComGameState_HeadquartersRoom RoomState;
		local int idx;

		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		History = `XCOMHISTORY;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("DEBUG Init Facilities");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		for(idx = 0; idx < default.DEBUG_StartingFacilities.Length; idx++)
		{
			foreach History.IterateByClassType(class'XComGameState_HeadquartersRoom', RoomState)
			{
				if(RoomState.MapIndex == (default.DEBUG_FacilityIndex + idx))
				{
					FacilityTemplate = X2FacilityTemplate(StratMgr.FindStrategyElementTemplate(default.DEBUG_StartingFacilities[idx]));
					if(FacilityTemplate != none)
					{
						FacilityTemplates.AddItem(FacilityTemplate);
						RoomState = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', RoomState.ObjectID));
						RoomState.ConstructionBlocked = false;
						RoomState.SpecialFeature = '';
						RoomState.Locked = false;
						XComHQ.UnlockAdjacentRooms(NewGameState, RoomState);
						
						FacilityState = FacilityTemplate.CreateInstanceFromTemplate(NewGameState);
						FacilityRefs.AddItem(FacilityState.GetReference());
						FacilityState.Room = RoomState.GetReference();
						FacilityState.ConstructionDateTime = GetGameTime();
						
						RoomState.Facility = FacilityState.GetReference();
						XComHQ.Facilities.AddItem(FacilityState.GetReference());
					}
				}
			}
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		for(idx = 0; idx < FacilityTemplates.Length; idx++)
		{
			if(FacilityTemplates[idx].OnFacilityBuiltFn != none)
			{
				FacilityTemplates[idx].OnFacilityBuiltFn(FacilityRefs[idx]);
			}
		}
	}
	function DebugRemoveStartingMission()
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;
		local XComGameState_MissionSite MissionState;

		History = `XCOMHISTORY;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("DEBUG Remove Starting Mission");

		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.GetMissionSource().bStart)
			{
				NewGameState.RemoveStateObject(MissionState.ObjectID);
			}
		}

		// when removing the first mission, we still have to complete the objective for having completed the first mission
		`XEVENTMGR.TriggerEvent('PreMissionDone', , , NewGameState);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	function DebugStuff()
	{
		DebugInitHQ();
		DebugInitItems();
		DebugInitTechs();
		DebugInitSoldiers();
		DebugInitFacilities();
		DebugRemoveStartingMission();
	}	
	
	function NonCheatDebugStuff()
	{
		local XComGameStateHistory History;
		local XComGameState_MissionSite MissionState;

		History = `XCOMHISTORY;

		if(!m_bTutorial)
		{
			foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
			{
				if(MissionState.GetMissionSource().bStart)
				{
					break;
				}
			}

			PrepareTacticalBattle(MissionState.ObjectID);
			`HQPRES.m_bExitFromSimCombat = true;
			class'X2StrategyGame_SimCombat'.static.SimCombat();
		}
		else
		{
			GetGeoscape().OnEnterMissionControl();
		}
	}

Begin:
	`STRATEGYRULES.GameTime = GetGameTime();

	// Start Issue #3 -- adding this after the game time assignment like in LoadingFromTactical
	// allow templated event handlers to register themselves
	class'X2EventListenerTemplateManager'.static.RegisterStrategyListeners();
	// End Issue #3

	m_kGeoscape.Init();
	
	while(!GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		Sleep(0);
	}
		
	NewGameEventHook();

	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
	
	// DEBUG STRATEGY
	if (m_bDebugStart)
	{
		DebugStuff();
	}

	while(`HQPRES.IsBusy())
	{
		Sleep(0);
	}
		
	`ONLINEEVENTMGR.ResetAchievementState();

	GetGeoscape().m_kBase.StreamInBaseRooms(false);

	while(!GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		Sleep(0);
	}
	
	GetGeoscape().m_kBase.UpdateFacilityProps();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true);

	Sleep(1.0f); //We don't want to populate the base rooms while capturing the environment, as it is very demanding on the games resources

	GetGeoscape().m_kBase.m_kCrewMgr.PopulateBaseRoomsWithCrew();

	GetGeoscape().m_kBase.SetAvengerVisibility(true);

	// DEBUG STRATEGY
	if(m_bDebugStart)
	{
		GoToHQ();
	}

	// DEBUG STRATEGY NONCHEAT
	if(m_bDebugStartNonCheat)
	{
		`HQPRES.UIAvengerFacilityMenu();
		`HQPC.GotoState('Headquarters');
		NonCheatDebugStuff();
	}
}

state LoadingGame
{
	function ClearQueuedDynamicPopups()
	{
		local XComGameState NewGameState;
		local XComGameState_HeadquartersXCom XComHQ;

		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ.QueuedDynamicPopups.Length > 0)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Loading Game: Clear Queued Dynamic Popups");
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.QueuedDynamicPopups.Length = 0;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}

Begin:
	// update our templates with the correct difficulty modifiers
	class'X2DataTemplateManager'.static.RebuildAllTemplateGameCaches();

	`STRATEGYRULES.GameTime = GetGameTime();
	m_kGeoscape.Init();

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while loading a save! This WILL result in buggy behavior during game play continued with this save.");

	// Start Issue #3 -- adding this after event manager validation like in LoadingFromTactical
	// allow templated event handlers to register themselves
	class'X2EventListenerTemplateManager'.static.RegisterStrategyListeners();
	// End Issue #3

	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);

	while(!GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		Sleep(0);
	}

	while(`HQPRES.IsBusy())
	{
		Sleep(0);
	}

	GetGeoscape().m_kBase.StreamInBaseRooms(false);

	while(!GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		Sleep(0);
	}

	UpdateDLCLoadingStrategyGame();

	GetGeoscape().m_kBase.UpdateFacilityProps(); 

	// WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true); // Don't do this hear, apparently this is too early.

	Sleep(1.0f); //We don't want to populate the base rooms while capturing the environment, as it is very demanding on the games resources

	GetGeoscape().m_kBase.m_kCrewMgr.PopulateBaseRoomsWithCrew();
	
	GetGeoscape().m_kBase.SetAvengerVisibility(true);
	GetGeoscape().m_kBase.SetAvengerCapVisibility(false);
	GetGeoscape().m_kBase.SetPostMissionSequenceVisibility(false);

	ClearQueuedDynamicPopups();

	`XSTRATEGYSOUNDMGR.PlayBaseViewMusic();
	GoToHQ();
}

state StartingFromTactical
{
	function bool ShowDropshipInterior()
	{	
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_MissionSite MissionState;		
		local bool bSkyrangerTravel;

		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if(XComHQ != none)
		{
			MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
		}

		//True if we didn't seamless travel here, and the mission type wanted a skyranger travel ( ie. no avenger defense or other special mission type )
		bSkyrangerTravel = MissionState.GetMissionSource().CustomLoadingMovieName_Outro == "" && 
						   !`XCOMGAME.m_bSeamlessTraveled && 
						   (MissionState == None || MissionState.GetMissionSource().bRequiresSkyrangerTravel);

		return bSkyrangerTravel;
	}

	function SetHQMusicFlag()
	{
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_MissionSite MissionState;
		local bool bLoadingMovieOnReturn;

		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if(XComHQ != none)
		{
			MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
		}

		bLoadingMovieOnReturn = !MissionState.GetMissionSource().bRequiresSkyrangerTravel || !class'XComMapManager'.default.bUseSeamlessTravelToStrategy || MissionState.GetMissionSource().CustomLoadingMovieName_Outro != "";

		`XSTRATEGYSOUNDMGR.bSkipPlayHQMusicAfterTactical = !bLoadingMovieOnReturn;
	}

Begin:
	//This is only true if the game is NOT using seamless travel and instead just puts the player into a streamed in drop ship while the rest of the levels stream in around them
	if(ShowDropshipInterior()) 
	{
		class'CHHelpers'.static.UpdateTransitionMap(); // Issue #388

		//DropshipLocation.Z -= 2000.0f; //Locate the drop ship below the map
		`MAPS.AddStreamingMap(`MAPS.GetTransitionMap(), DropshipLocation, DropshipRotation, false);// .bForceNoDupe = true;
		while(!`MAPS.IsStreamingComplete())
		{
			sleep(0.0f);
		}				

		XComPlayerController(`HQPRES.Owner).NotifyStartTacticalSeamlessLoad();
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false);

		if (`XENGINE.IsAnyMoviePlaying() == false || `XENGINE.IsMoviePlaying("CIN_XP_UI_LogoSpin.bk2") == false)
		{
			`XENGINE.StopCurrentMovie();
			`XENGINE.PlayMovie(true, "CIN_XP_UI_LogoSpin.bk2");
		}		
	}	
	else
	{
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
	}

	`STRATEGYRULES.GameTime = GetGameTime();
	
	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while entering strategy! This WILL result in buggy behavior during game play continued with this save.");

	// allow templated event handlers to register themselves
	class'X2EventListenerTemplateManager'.static.RegisterStrategyListeners();

	class'XComGameStateContext_StrategyGameRule'.static.CompleteStrategyFromTacticalTransfer();

	m_kGeoscape.Init();

	while(!GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		Sleep(0);
	}

	while(`HQPRES.IsBusy())
	{
		Sleep(0);
	}

	GetGeoscape().m_kBase.StreamInBaseRooms(false);

	while(!GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		Sleep(0);
	}

	GetGeoscape().m_kBase.UpdateFacilityProps();	
	GetGeoscape().m_kBase.m_kCrewMgr.PopulateBaseRoomsWithCrew();
	Sleep(0.1); //We don't want to populate the base rooms while capturing the environment, as it is very demanding on the games resources

	while (GetGeoscape().m_kBase.m_kCrewMgr.IsPlacingStaff())
	{
		Sleep(0);
	}

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

	if(ShowDropshipInterior())
	{
		`XENGINE.StopCurrentMovie();

		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);

		while (!WorldInfo.MyLocalEnvMapManager.AreCapturesComplete())
		{
			Sleep(0);
		}

		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false, , , 1.0);

		WorldInfo.bContinueToSeamlessTravelDestination = false;
		XComPlayerController(`HQPRES.Owner).NotifyLoadedDestinationMap('');
		while(!WorldInfo.bContinueToSeamlessTravelDestination)
		{
			Sleep(0.0f);
		}

		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
		Sleep(0.1f);

		`MAPS.RemoveStreamingMapByName(`MAPS.GetTransitionMap(), false);
		`MAPS.ResetTransitionMap(); // Issue #388 -- revert transition map changes
	}
	else
	{
		while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
		{
			Sleep(0.0f);
		}
	}

	GetGeoscape().m_kBase.SetAvengerVisibility(true);

	SetHQMusicFlag();

	while (!`MAPS.IsStreamingComplete())
	{
		sleep(0.0f);
	}
	class'XComEngine'.static.SetSeamlessTraveled(false); // Turn off seamless travel once all of the maps are loaded

	GoToHQ();
}

state StartingFromTutorial
{
Begin:
	`STRATEGYRULES.GameTime = GetGameTime();

	// Start Issue #3 -- adding this after the game time assignment like in LoadingFromTactical
	// allow templated event handlers to register themselves
	class'X2EventListenerTemplateManager'.static.RegisterStrategyListeners();
	// End Issue #3

	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);

	m_kGeoscape.Init();

	while(!GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		Sleep(0);
	}

	while(`HQPRES.IsBusy())
	{
		Sleep(0);
	}

	GetGeoscape().m_kBase.StreamInBaseRooms(false);

	while(!GetGeoscape().m_kBase.MinimumAvengerStreamedInAndVisible())
	{
		Sleep(0);
	}

	GetGeoscape().m_kBase.UpdateFacilityProps();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true);

	Sleep(1.0f); //We don't want to populate the base rooms while capturing the environment, as it is very demanding on the games resources

	GetGeoscape().m_kBase.m_kCrewMgr.PopulateBaseRoomsWithCrew();

	GetGeoscape().m_kBase.SetAvengerVisibility(true);

	//Allow the user to skip the movie now that the major work / setup is done
	`XENGINE.SetAllowMovieInput(true);

	//Wait for the post tutorial movie to finish if the player is still watching it
	while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		Sleep(0.0f);
	}

	GoToHQ();
}

function string GetTip( ETipTypes eTip  )
{
	local string strTip;

	strTip = class'XGLocalizedData'.default.m_strTipLabel@class'XGLocalizedData'.default.GameplayTips_Tactical[m_kNarrative.GetNextTip(eTip)];

	return strTip;
}

//-----------------------------------------------------------
//-----------------------------------------------------------
defaultproperties
{
	m_bShowRecommendations=true
}
