//---------------------------------------------------------------------------------------
//  FILE:    X2TacticalGameRuleset.uc
//  AUTHOR:  Ryan McFall  --  10/9/2013
//  PURPOSE: This actor extends X2GameRuleset to provide special logic and behavior for
//			 the tactical game mode in X-Com 2.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TacticalGameRuleset extends X2GameRuleset 
	dependson(X2GameRulesetVisibilityManager, X2TacticalGameRulesetDataStructures, XComGameState_BattleData)
	config(GameCore)
	native(Core);

// Moved this here from UICombatLose.uc because of dependency issues
enum UICombatLoseType
{
	eUICombatLose_FailableGeneric,
	eUICombatLose_UnfailableGeneric,
	eUICombatLose_UnfailableHQAssault,
	eUICombatLose_UnfailableObjective,
	eUICombatLose_UnfailableCommanderKilled,
};

//******** General Purpose Variables **********
var protected XComTacticalController TacticalController;        //Cache the local player controller. Used primarily during the unit actions phase
var protected XComParcelManager ParcelManager;                  //Cached copy of the parcel mgr
var protected XComPresentationLayer Pres;						//Cached copy of the presentation layer (UI)
var protected bool bShowDropshipInteriorWhileGeneratingMap;		//TRUE if we should show the dropship interior while the map is created for this battle
var protected vector DropshipLocation;
var protected Rotator DropshipRotation;
var protected array<GameRulesCache_Unit> UnitsCache;            //Book-keeping for which abilities are available / not available
var protected StateObjectReference CachedBattleDataRef;         //Reference to the singleton BattleData state for this battle
var protected StateObjectReference CachedXpManagerRef;          //Reference to the singleton XpManager state for this battle
var protected X2UnitRadiusManager UnitRadiusManager;
var protected string BeginBlockWaitingLocation;                 //Debug text relating to where the current code is executing
var protectedwrite array<StateObjectReference> CachedDeadUnits;
`define SETLOC(LocationString) BeginBlockWaitingLocation = DEBUG_SetLocationString(GetStateName() $ ":" @ `LocationString);
var private string NextSessionCommandString;
var XComNarrativeMoment TutorialIntro;
var privatewrite bool bRain; //Records TRUE/FALSE whether there is rain in this map
//****************************************

//******** TurnPhase_UnitActions State Variables **********
var protected int UnitActionInitiativeIndex;	                //Index into BattleData.PlayerTurnOrder that keeps track of which player in the list is currently taking unit actions
var StateObjectReference CachedUnitActionInitiativeRef;			//Reference to the XComGameState_Player or XComGameState_AIGroup that is currently taking unit actions
var StateObjectReference CachedUnitActionPlayerRef;				//Reference to the XComGameState_Player that is currently taking unit actions
var StateObjectReference InterruptingUnitActionPlayerRef;		// Ref to the player of the currently interrupting group
var protected StateObjectReference UnitActionUnitRef;           //Reference to the XComGameState_Unit that the player has currently selected
var protected float WaitingForNewStatesTime;                    //Keeps track of how long the unit actions phase has been waiting for a decision from the player.
var privatewrite bool bLoadingSavedGame;						//This variable is true for the duration of TurnPhase_UnitActions::BeginState if the previous state was loading
var protected bool bSkipAutosaveAfterLoad;                        //If loading a game, this flag is set to indicate that we don't want to autosave until the next turn starts
var protected bool bAlienActivity;                                //Used to give UI indication to player it is the alien's turn
var protected bool bSkipRemainingTurnActivty;						//Used to end a player's turn regardless of action availability
var float EarliestTurnSwitchTime;  // The current turn should not end until this time has passed
var config float MinimumTurnTime;  // Each turn should not end until this amount of time has passed
var private bool bInitiativeInterruptingInitialGroup;			// true if the initiative group for the current player is starting out interrupted
//****************************************

//******** EndTacticalGame State Variables **********
var bool bWaitingForMissionSummary;                             //Set to true when we show the mission summary, cleared on pressing accept in that screen
var protected bool bTacticalGameInPlay;							// True from the CreateTacticalGame::EndState() -> EndTacticalGame::BeginState(), query using TacticalGameIsInPlay()
var UICombatLoseType LoseType;									// If the mission is lost, this is the type of UI that should be used
var bool bPromptForRestart;
var int TacticalGameEndIndex;
//****************************************

//******** Config Values **********
var config int UnitHeightAdvantage;                             //Unit's location must be >= this many tiles over another unit to have height advantage against it
var config int UnitHeightAdvantageBonus;                        //Amount of additional Aim granted to a unit with height advantage
var config int UnitHeightDisadvantagePenalty;                   //Amount of Aim lost when firing against a unit with height advantage
var config int XComIndestructibleCoverMaxDifficulty;			//The highest difficulty at which to give xcom the advantage of indestructible cover (from missed shots).
var config float HighCoverDetectionModifier;					// The detection modifier to apply to units when they enter a tile with high cover.
var config float NoCoverDetectionModifier;						// The detection modifier to apply to units when they enter a tile with no high cover.
var config array<string> ForceLoadCinematicMaps;                // Any maps required for Cinematic purposes that may not otherwise be loaded.
var config array<string> arrHeightFogAdjustedPlots;				// any maps required to adjust heightfog actor properties through a remote event.
var config float DepletedAvatarHealthMod;                       // the health mod applied to the first avatar spawned in as a result of skulljacking the codex
var config bool ActionsBlockAbilityActivation;					// the default setting for whether or not X2Actions block ability activation (can be overridden on a per-action basis)
var config float ZipModeMoveSpeed;								// in zip mode, all movement related animations are played at this speed
var config float ZipModeTrivialAnimSpeed;						// in zip mode, all trivial animations (like step outs) are played at this speed
var config float ZipModeDelayModifier;							// in zip mode, all action delays are modified by this value
var config float ZipModeDoomVisModifier;						// in zip mode, the doom visualization timers are modified by this value
var config array<string> PlayerTurnOrder;						// defines the order in which players act
var config array<float> MissionTimerDifficultyAdjustment;			// defines the number of additional turns players get per difficulty
var config float SecondWaveExtendedTimerScalar;					// scales the number of turns on mission timers (for ExtendedMissionTimers)
var config float SecondWaveBetaStrikeTimerScalar;				// scales the number of turns on mission timers (for BetaStrike)
//****************************************

var int LastNeutralReactionEventChainIndex; // Last event chain index to prevent multiple civilian reactions from same event. Also used for simultaneous civilian movement.

var array<int> VisualizerActivationHistoryFrames; // set of history frames where the visualizer was kicked off from actions being taken.

//******** Ladder Photobooth Variables **********
var X2Photobooth_StrategyAutoGen m_kPhotoboothAutoGen;
var int m_HeadshotsPending;
var X2Photobooth_TacticalLocationController m_kTacticalLocation;
var bool bStudioReady;
//****************************************

//******** Delegates **********
delegate SetupStateChange(XComGameState SetupState);
//****************************************

function string DEBUG_SetLocationString(string LocationString)
{
	if (LocationString != BeginBlockWaitingLocation)
		ReleaseScriptLog( self @ LocationString );

	return LocationString;
}

simulated native function int GetLocalClientPlayerObjectID();

// Added for debugging specific ability availability. Called only from cheat manager.
function UpdateUnitAbility( XComGameState_Unit kUnit, name strAbilityName )
{
	local XComGameState_Ability kAbility;
	local StateObjectReference AbilityRef;
	local AvailableAction kAction;

	AbilityRef = kUnit.FindAbility(strAbilityName);
	if (AbilityRef.ObjectID > 0)
	{
		kAbility = XComGameState_Ability(CachedHistory.GetGameStateForObjectID(AbilityRef.ObjectID));
		kAbility.UpdateAbilityAvailability(kAction);
	}
}

function UpdateAndAddUnitAbilities( out GameRulesCache_Unit kUnitCache, XComGameState_Unit kUnit, out array<int> CheckAvailableAbility, out array<int> UpdateAvailableIcon)
{
	local XComGameState_Ability kAbility;
	local AvailableAction kAction, EmptyAction;	
	local int i, ComponentID, HideIf;
	local StateObjectReference OtherAbilityRef;
	local XComGameState_Unit kSubUnit;
	local X2AbilityTemplate AbilityTemplate;

	for (i = 0; i < kUnit.Abilities.Length; ++i)
	{
		kAction = EmptyAction;
		kAbility = XComGameState_Ability(CachedHistory.GetGameStateForObjectID(kUnit.Abilities[i].ObjectID));
		if (kAbility != none) //kAbility can be none if abilities are being added removed during dev
		{
			kAbility.UpdateAbilityAvailability(kAction);
			kUnitCache.AvailableActions.AddItem(kAction);
			kUnitCache.bAnyActionsAvailable = kUnitCache.bAnyActionsAvailable || kAction.AvailableCode == 'AA_Success';
			if (kAction.eAbilityIconBehaviorHUD == eAbilityIconBehavior_HideIfOtherAvailable)
			{
				AbilityTemplate = kAbility.GetMyTemplate();
				for (HideIf = 0; HideIf < AbilityTemplate.HideIfAvailable.Length; ++HideIf)
				{
					OtherAbilityRef = kUnit.FindAbility(AbilityTemplate.HideIfAvailable[HideIf]);
					if (OtherAbilityRef.ObjectID != 0)
					{
						CheckAvailableAbility.AddItem(OtherAbilityRef.ObjectID);
						UpdateAvailableIcon.AddItem(kUnitCache.AvailableActions.Length - 1);
					}
				}
			}
		}
	}

	if (!kUnit.m_bSubsystem) // Should be no more than 1 level of recursion depth.
	{
		foreach kUnit.ComponentObjectIds(ComponentID)
		{
			kSubUnit = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(ComponentID));
			if (kSubUnit != None)
			{
				UpdateAndAddUnitAbilities(kUnitCache, kSubUnit, CheckAvailableAbility, UpdateAvailableIcon);
			}
		}
	}
}

/// <summary>
/// The local player surrenders from the match, mark as a loss.
/// </summary>
function LocalPlayerForfeitMatch();

simulated function FailBattle()
{
	local XComGameState_Player PlayerState;
	local XComGameState_TimerData TimerState;
	local XGPlayer Player;

	foreach CachedHistory.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		Player = XGPlayer(PlayerState.GetVisualizer());
		if (Player != none && !Player.IsHumanPlayer())
		{
			EndBattle(Player);

			TimerState = XComGameState_TimerData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData'));
			TimerState.bStopTime = true;
			return;
		}
	}
	`RedScreen("Failed to EndBattle properly! @ttalley");
}

private simulated function bool SquadDead( )
{
	local StateObjectReference SquadMemberRef;
	local XComGameState_Unit SquadMemberState;

	foreach `XCOMHQ.Squad(SquadMemberRef)
	{
		if (SquadMemberRef.ObjectID != 0)
		{
			SquadMemberState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SquadMemberRef.ObjectID));
			if (SquadMemberState != None && SquadMemberState.IsAlive())
			{
				return false;
			}
		}
	}

	return true;
}

/// <summary>
/// Will add a game state to the history marking that the battle is over
/// </summary>
simulated function EndBattle(XGPlayer VictoriousPlayer, optional UICombatLoseType UILoseType = eUICombatLose_FailableGeneric, optional bool GenerateReplaySave = false)
{
	local XComGameStateContext_TacticalGameRule Context;
	local XComGameState NewGameState;
	local int ReplaySaveID;
	local XComGameState_BattleData BattleData;
	local XComOnlineProfileSettings ProfileSettings;
	local XComLWTuple OverrideTuple; // for issue #266
	local int VictoriousPlayerID; // for issue #266
	
	`log(`location @ `ShowVar(VictoriousPlayer) @ `ShowEnum(UICombatLoseType, UILoseType) @ `ShowVar(GenerateReplaySave));
	if (`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		// Check for the End of Tactical Game ...
		foreach CachedHistory.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
		{
			if (Context.GameRuleType == eGameRule_TacticalGameEnd)
			{
				TacticalGameEndIndex = Context.AssociatedState.HistoryIndex;
				`log(`location @ "eGameRule_TacticalGameEnd Found @" @ `ShowVar(TacticalGameEndIndex));
				return; // Make sure to not end the battle multiple times.
			}
		}
	}

	LoseType = UILoseType;

	if(class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress())
	{
		if (!SquadDead( ))
			LoseType = eUICombatLose_UnfailableObjective; //The squad made it out, but we lost - must have been an objective. Don't show "all xcom killed!" screen.
		else
			LoseType = eUICombatLose_UnfailableGeneric;
	}

	bPromptForRestart = !VictoriousPlayer.IsHumanPlayer() && LoseType != eUICombatLose_FailableGeneric;
	if (!VictoriousPlayer.IsHumanPlayer() && (CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress', true ) != none))
	{
		if (!SquadDead( ))
			LoseType = eUICombatLose_UnfailableObjective; //The squad made it out, but we lost - must have been an objective. Don't show "all xcom killed!" screen.
		else
			LoseType = eUICombatLose_UnfailableGeneric;

		bPromptForRestart = true;
	}

	BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID( CachedBattleDataRef.ObjectID ));
	if (VictoriousPlayer.IsHumanPlayer() && (BattleData.m_strDesc == "Skirmish Mode"))
	{
		ProfileSettings = `XPROFILESETTINGS;

		++ProfileSettings.Data.HubStats.NumSkirmishVictories;

		`ONLINEEVENTMGR.SaveProfileSettings();
	}

	// Don't end battles in PIE, at least not for now
	if(WorldInfo.IsPlayInEditor()) return;
	
	// issue #266: set up a Tuple to determine objectID of victorious player of a battle
	OverrideTuple = new class'XComLWTuple'; 
	OverrideTuple.Id = 'OverrideVictoriousPlayer';
	OverrideTuple.Data.Add(1);
	OverrideTuple.Data[0].kind = XComLWTVInt;
	OverrideTuple.Data[0].i = VictoriousPlayer.ObjectID;
	`XEVENTMGR.TriggerEvent('OverrideVictoriousPlayer', OverrideTuple, OverrideTuple, none); // mods should be able to use XCOMHistory to check the battle data without needing any intervention here
	
	VictoriousPlayerID = OverrideTuple.Data[0].i;
	
	Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_TacticalGameEnd);
	Context.PlayerRef.ObjectID = VictoriousPlayerID;
	NewGameState = Context.ContextBuildGameState();
	SubmitGameState(NewGameState);

	if(GenerateReplaySave)
	{
		ReplaySaveID = `AUTOSAVEMGR.GetNextSaveID();
		`ONLINEEVENTMGR.SaveGame(ReplaySaveID, false, false, none);
	}

	`XEVENTMGR.TriggerEvent('EndBattle');
}

simulated function bool IsFinalMission()
{
	local XComGameState_MissionSite MissionState;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	if (MissionState.GetMissionSource().DataName == 'MissionSource_Final')
	{
		return true;
	}

	return false;
}

/// <summary>
/// </summary>
simulated function bool HasTacticalGameEnded()
{
	local XComGameStateHistory History;
	local int StartStateIndex;
	local XComGameState StartState, EndState;
	local XComGameStateContext_TacticalGameRule StartContext, EndContext;

	//XComTutorialMgr will end the tactical game when appropriate
	if (`REPLAY.bInTutorial)
	{
		return false;
	}

	History = `XCOMHISTORY;

	StartStateIndex = History.FindStartStateIndex( );

	StartState = History.GetGameStateFromHistory( StartStateIndex );
	EndState = History.GetGameStateFromHistory( TacticalGameEndIndex );
	
	if (EndState != none)
	{
		EndContext = XComGameStateContext_TacticalGameRule( EndState.GetContext() );

		if ((EndContext != none) && (EndContext.GameRuleType == eGameRule_TacticalGameEnd))
			return true;
	}

	if (StartState != none)
	{
		StartContext = XComGameStateContext_TacticalGameRule( StartState.GetContext() );

		if ((StartContext != none) && (StartContext.GameRuleType == eGameRule_TacticalGameStart))
			return false;
	}

	return HasTimeExpired();
}

simulated function bool HasTimeExpired()
{
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));

	return Timer != none && Timer.GetCurrentTime() <= 0;
}

/// <summary>
/// This method builds a local list of state object references for objects that are relatively static, and that we 
/// may need to access frequently. Using the cached ObjectID from a game state object reference is much faster than
/// searching for it each time we need to use it.
/// </summary>
simulated function BuildLocalStateObjectCache()
{	
	local XComGameState_XpManager XpManager;	
	local XComWorldData WorldData;	
	local XComGameState_BattleData BattleDataState;

	super.BuildLocalStateObjectCache();

	//Get a reference to the BattleData for this tactical game
	BattleDataState = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	CachedBattleDataRef = BattleDataState.GetReference();

	foreach CachedHistory.IterateByClassType(class'XComGameState_XpManager', XpManager, eReturnType_Reference)
	{
		CachedXpManagerRef = XpManager.GetReference();
		break;
	}

	TacticalController = XComTacticalController(GetALocalPlayerController());	
	TacticalController.m_kPathingPawn.InitEvents();
	ParcelManager = `PARCELMGR;
	Pres = XComPresentationLayer(XComPlayerController(GetALocalPlayerController()).Pres);	

	//Make sure that the world's OnNewGameState delegate is called prior to the visibility systems, as the vis system is dependent on the
	//world data. Unregistering these delegates is handled natively
	WorldData = `XWORLD;
	WorldData.RegisterForNewGameState();
	WorldData.RegisterForObliterate();

	VisibilityMgr = Spawn(class'X2GameRulesetVisibilityManager', self);
	VisibilityMgr.RegisterForNewGameStateEvent();

	if (BattleDataState.MapData.ActiveMission.sType == "Terror")
	{
		UnitRadiusManager = Spawn( class'X2UnitRadiusManager', self );
	}

	CachedHistory.RegisterOnObliteratedGameStateDelegate(OnObliterateGameState);
	CachedHistory.RegisterOnNewGameStateDelegate(OnNewGameState);
}

function OnObliterateGameState(XComGameState ObliteratedGameState)
{
	local int i, CurrentHistoryIndex;
	CurrentHistoryIndex = CachedHistory.GetCurrentHistoryIndex();
	for( i = 0; i < UnitsCache.Length; i++ )
	{
		if( UnitsCache[i].LastUpdateHistoryIndex > CurrentHistoryIndex )
		{
			UnitsCache[i].LastUpdateHistoryIndex = INDEX_NONE; // Force this to get updated next time.
		}
	}
}

function OnNewGameState(XComGameState NewGameState)
{
	local XComGameStateContext_TacticalGameRule TacticalContext;
	TacticalContext = XComGameStateContext_TacticalGameRule( NewGameState.GetContext() );

	if (IsInState( 'TurnPhase_UnitActions' ) && (TacticalContext != none) && (TacticalContext.GameRuleType == eGameRule_SkipTurn))
	{
		bSkipRemainingTurnActivty = true;
	}
	else if ((TacticalContext != none) && (TacticalContext.GameRuleType == eGameRule_TacticalGameEnd))
	{
		TacticalGameEndIndex = NewGameState.HistoryIndex;
	}
}

/// <summary>
/// Return a state object reference to the static/global battle data state
/// </summary>
simulated function StateObjectReference GetCachedBattleDataRef()
{
	return CachedBattleDataRef;
}

/// <summary>
/// Called by the tactical game start up process when a new battle is starting
/// </summary>
simulated function StartNewGame()
{
		BuildLocalStateObjectCache();

	GotoState('CreateTacticalGame');
}

/// <summary>
/// Called by the tactical game start up process the player is resuming a previously created battle
/// </summary>
simulated function LoadGame()
{
	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();

	GotoState('LoadTacticalGame');
}

/// <summary>
/// Called by the tactical game start up process when a new challenge mission is starting
/// </summary>
simulated function StartChallengeGame()
{
	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();

	GotoState('CreateChallengeGame');
}


/// <summary>
/// Returns true if the visualizer is currently in the process of showing the last game state change
/// </summary>
simulated function bool WaitingForVisualizer()
{
	return class'XComGameStateVisualizationMgr'.static.VisualizerBusy() || (`XCOMVISUALIZATIONMGR.VisualizationTree != none);
}

/// <summary>
/// Expanded version of WaitingForVisualizer designed for the end of a unit turn. WaitingForVisualizer and EndOfTurnWaitingForVisualizer would ideally be consolidated, but
/// the potential for knock-on would be high as WaitingForVisualizer is used in many places for many different purposes.
/// </summary>
simulated function bool EndOfTurnWaitingForVisualizer()
{
	return !class'XComGameStateVisualizationMgr'.static.VisualizerIdleAndUpToDateWithHistory() || (`XCOMVISUALIZATIONMGR.VisualizationTree != none);
}

simulated function bool IsSavingAllowed()
{
	if( IsDoingLatentSubmission() )
	{
		return false;
	}

	if( !bTacticalGameInPlay || bWaitingForMissionSummary || HasTacticalGameEnded() )
	{
		return false;
	}

	return true;
}

/// <summary>
/// Returns true if the current game time has not yet exceeded the Minimum time that must be elapsed before visualizing the next turn
/// </summary>
simulated function bool WaitingForMinimumTurnTimeElapsed()
{
	return (WorldInfo.TimeSeconds < EarliestTurnSwitchTime);
}

simulated function ResetMinimumTurnTime()
{
	EarliestTurnSwitchTime = WorldInfo.TimeSeconds + MinimumTurnTime;
}

simulated function AddDefaultPathingCamera()
{
	local XComPlayerController Controller;	

	Controller = XComPlayerController(GetALocalPlayerController());

	// add a default camera.
	if(Controller != none)
	{
		if (Controller.IsMouseActive())
		{
			XComCamera(Controller.PlayerCamera).CameraStack.AddCamera(new class'X2Camera_FollowMouseCursor');
		}
		else
		{
			XComCamera(Controller.PlayerCamera).CameraStack.AddCamera(new class'X2Camera_FollowCursor');
		}
	}
}

/// <summary>
/// Returns cached information about the unit such as what actions are available
/// </summary>
simulated function bool GetGameRulesCache_Unit(StateObjectReference UnitStateRef, out GameRulesCache_Unit OutCacheData)
{
	local AvailableAction kAction;	
	local XComGameState_Unit kUnit;
	local int CurrentHistoryIndex;
	local int ExistingCacheIndex;
	local int i;
	local array<int> CheckAvailableAbility;
	local array<int> UpdateAvailableIcon;
	local GameRulesCache_Unit EmptyCacheData;
	local XComGameState_BaseObject StateObject;

	//Correct us of this method does not 'accumulate' information, so reset the output 
	OutCacheData = EmptyCacheData;

	if (UnitStateRef.ObjectID < 1) //Caller passed in an invalid state object ID
	{
		return false;
	}

	kUnit = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(UnitStateRef.ObjectID));

	if (kUnit == none) //The state object isn't a unit!
	{
		StateObject = CachedHistory.GetGameStateForObjectID(UnitStateRef.ObjectID);
		`redscreen("WARNING! Tried to get cached abilities for non unit game state object:\n"$StateObject.ToString());
		return false;
	}

	if (kUnit.m_bSubsystem) // Subsystem abilities are added to base unit's abilities.
	{
		return false;
	}

	if(kUnit.bDisabled			||          // skip disabled units
	   kUnit.bRemovedFromPlay	||			// removed from play ( ie. exited level )
	   kUnit.GetMyTemplate().bIsCosmetic )	// unit is visual flair, like the gremlin and should not have actions
	{
		return false;
	}

	CurrentHistoryIndex = CachedHistory.GetCurrentHistoryIndex();

	// find our cache data, if any (UnitsCache should be converted to a Map_Mirror when this file is nativized, for faster lookup)
	ExistingCacheIndex = -1;
	for(i = 0; i < UnitsCache.Length; i++)
	{
		if(UnitsCache[i].UnitObjectRef == UnitStateRef)
		{
			if(UnitsCache[i].LastUpdateHistoryIndex == CurrentHistoryIndex)
			{
				// the cached data is still current, so nothing to do
				OutCacheData = UnitsCache[i];
				return true;
			}
			else
			{
				// this cache is outdated, update
				ExistingCacheIndex = i;
				break;
			}
		}
	}

	// build the cache data
	OutCacheData.UnitObjectRef = kUnit.GetReference();
	OutCacheData.LastUpdateHistoryIndex = CurrentHistoryIndex;
	OutCacheData.AvailableActions.Length = 0;
	OutCacheData.bAnyActionsAvailable = false;

	UpdateAndAddUnitAbilities(OutCacheData, kUnit, CheckAvailableAbility, UpdateAvailableIcon);
	for (i = 0; i < CheckAvailableAbility.Length; ++i)
	{
		foreach OutCacheData.AvailableActions(kAction)
		{
			if (kAction.AbilityObjectRef.ObjectID == CheckAvailableAbility[i])
			{
				if (kAction.AvailableCode == 'AA_Success' || kAction.AvailableCode == 'AA_NoTargets')
					OutCacheData.AvailableActions[UpdateAvailableIcon[i]].eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
				else
					OutCacheData.AvailableActions[UpdateAvailableIcon[i]].eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
						
				break;
			}
		}
	}

	if(ExistingCacheIndex == -1)
	{
		UnitsCache.AddItem(OutCacheData);
	}
	else
	{
		UnitsCache[ExistingCacheIndex] = OutCacheData;
	}

	return true;
}

simulated function ETeam GetUnitActionTeam()
{
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(GetCachedUnitActionPlayerRef().ObjectID));
	if( PlayerState != none )
	{
		return PlayerState.TeamFlag;
	}

	return eTeam_None;
}

simulated function bool UnitActionPlayerIsAI()
{
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(GetCachedUnitActionPlayerRef().ObjectID));
	if( PlayerState != none )
	{
		return PlayerState.GetVisualizer().IsA('XGAIPlayer');
	}

	return false;
}

/// <summary>
/// This event is called after a system adds a gamestate to the history, perhaps circumventing the ruleset itself.
/// </summary>
simulated function OnSubmitGameState()
{
	bWaitingForNewStates = false;
}

/// <summary>
/// Overridden per State - determines whether SubmitGameStates can add new states to the history or not. During some 
/// turn phases new state need to be added only at certain times.
/// </summary>
simulated function bool AddNewStatesAllowed()
{
	local bool bAddNewStatesAllowed;	
		
	bAddNewStatesAllowed = super.AddNewStatesAllowed();
	
	//Do not permit new states to be added while we are performing a replay
	bAddNewStatesAllowed = bAddNewStatesAllowed && !XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay;

	return bAddNewStatesAllowed;
}

/// <summary>
/// Overridden per state. Allows states to specify that unit visualizers should not be selectable (and human controlled) at the current time
/// </summary>
simulated function bool AllowVisualizerSelection()
{
	return true;
}

/// <summary>
/// Called whenever the rules authority changes state in the rule engine. This creates a rules engine sate change 
/// history frame that directs non-rules authority instances to change their rule engine state.
/// </summary>
function BeginState_RulesAuthority( delegate<SetupStateChange> SetupStateDelegate )
{
	local XComGameState EnteredNewPhaseGameState;
	local XComGameStateContext_TacticalGameRule NewStateContext;

	NewStateContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());	
	NewStateContext.GameRuleType = eGameRule_RulesEngineStateChange;
	NewStateContext.RuleEngineNextState = GetStateName();
	NewStateContext.SetContextRandSeedFromEngine();
	
	EnteredNewPhaseGameState = CachedHistory.CreateNewGameState(true, NewStateContext);

	if( SetupStateDelegate != none )
	{
		SetupStateDelegate(EnteredNewPhaseGameState);	
	}

	CachedHistory.AddGameStateToHistory(EnteredNewPhaseGameState);
}

/// <summary>
/// Called whenever a non-rules authority receives a rules engine state change history frame.
/// </summary>
simulated function BeginState_NonRulesAuthority(name DestinationState)
{
	local name NextTurnPhase;
	
	//Validate that this state change is legal
	NextTurnPhase = GetNextTurnPhase(GetStateName());
	`assert(DestinationState == NextTurnPhase);

	GotoState(DestinationState);
}

simulated function string GetStateDebugString();

simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string kStr;
	local int iX, iY;
	local XComCheatManager LocalCheatManager;
	
	LocalCheatManager = XComCheatManager(GetALocalPlayerController().CheatManager);

	if( LocalCheatManager != None && LocalCheatManager.bDebugRuleset )
	{
		iX=250;
		iY=50;

		kStr =      "=========================================================================================\n";
		kStr = kStr$"Rules Engine (State"@GetStateName()@")\n";
		kStr = kStr$"=========================================================================================\n";	
		kStr = kStr$GetStateDebugString();
		kStr = kStr$"\n";

		kCanvas.SetPos(iX, iY);
		kCanvas.SetDrawColor(0,255,0);
		kCanvas.DrawText(kStr);
	}
}

private static function Object GetEventFilterObject(AbilityEventFilter eventFilter, XComGameState_Unit FilterUnit, XComGameState_Player FilterPlayerState)
{
	local Object FilterObj;

	switch(eventFilter)
	{
	case eFilter_None:
		FilterObj = none;
		break;
	case eFilter_Unit:
		FilterObj = FilterUnit;
		break;
	case eFilter_Player:
		FilterObj = FilterPlayerState;
		break;
	}

	return FilterObj;
}

//  THIS SHOULD ALMOST NEVER BE CALLED OUTSIDE OF NORMAL TACTICAL INIT SEQUENCE. USE WITH EXTREME CAUTION.
static simulated function StateObjectReference InitAbilityForUnit(X2AbilityTemplate AbilityTemplate, XComGameState_Unit Unit, XComGameState StartState, optional StateObjectReference ItemRef, optional StateObjectReference AmmoRef)
{
	local X2EventManager EventManager;
	local XComGameState_Ability kAbility;
	local XComGameState_Player PlayerState;
	local XComGameState_AdventChosen ChosenOwner;
	local Object FilterObj, SourceObj;
	local AbilityEventListener kListener;
	local X2AbilityTrigger Trigger;
	local X2AbilityTrigger_EventListener AbilityTriggerEventListener;
	local XGUnit UnitVisualizer;
	local StateObjectReference AbilityReference;

	`assert(AbilityTemplate != none);

	//Add a new ability state to StartState
	kAbility = AbilityTemplate.CreateInstanceFromTemplate(StartState);

	if( kAbility != none )
	{
		//Set source weapon as the iterated item
		kAbility.SourceWeapon = ItemRef;
		kAbility.SourceAmmo = AmmoRef;

		//Give the iterated unit state the new ability
		`assert(Unit.bReadOnly == false);
		Unit.Abilities.AddItem(kAbility.GetReference());
		kAbility.InitAbilityForUnit(Unit, StartState);
		AbilityReference = kAbility.GetReference();

		EventManager = `XEVENTMGR;
		PlayerState = XComGameState_Player(StartState.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));
		if (PlayerState == none)
			PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));

		if( AbilityTemplate.AbilityRevealEvent != '' && !kAbility.IsChosenTraitRevealed() )
		{
			ChosenOwner = kAbility.GetChosenOwner();
			if( ChosenOwner != None )
			{
				SourceObj = ChosenOwner;
				EventManager.RegisterForEvent(SourceObj, AbilityTemplate.AbilityRevealEvent, ChosenOwner.RevealChosenTrait, ELD_OnStateSubmitted, /*priority*/, /*FilterObj*/, , kAbility);
			}
		}

		foreach AbilityTemplate.AbilityEventListeners(kListener)
		{
			SourceObj = kAbility;
			
			FilterObj = GetEventFilterObject(kListener.Filter, Unit, PlayerState);
			EventManager.RegisterForEvent(SourceObj, kListener.EventID, kListener.EventFn, kListener.Deferral, /*priority*/, FilterObj);
		}
		foreach AbilityTemplate.AbilityTriggers(Trigger)
		{
			if (Trigger.IsA('X2AbilityTrigger_EventListener'))
			{
				AbilityTriggerEventListener = X2AbilityTrigger_EventListener(Trigger);

				FilterObj = GetEventFilterObject(AbilityTriggerEventListener.ListenerData.Filter, Unit, PlayerState);
				AbilityTriggerEventListener.RegisterListener(kAbility, FilterObj);
			}
		}

		// In the case of Aliens, they're spawned with no abilities so we add their perks when we add their ability
		UnitVisualizer = XGUnit(Unit.GetVisualizer());
		if (UnitVisualizer != none)
		{
			UnitVisualizer.GetPawn().AppendAbilityPerks( AbilityTemplate.DataName, AbilityTemplate.GetPerkAssociationName() );
			UnitVisualizer.GetPawn().StartPersistentPawnPerkFX( AbilityTemplate.DataName );
		}
	}
	else
	{
		`log("WARNING! AbilityTemplate.CreateInstanceFromTemplate FAILED for ability"@AbilityTemplate.DataName);
	}
	return AbilityReference;
}

static simulated function InitializeUnitAbilities(XComGameState NewGameState, XComGameState_Unit NewUnit)
{		
	local XComGameState_Player kPlayer;
	local int i;
	local array<AbilitySetupData> AbilityData;
	local bool bIsMultiplayer;
	local X2AbilityTemplate AbilityTemplate;

	`assert(NewGameState != none);
	`assert(NewUnit != None);

	bIsMultiplayer = class'Engine'.static.GetEngine().IsMultiPlayerGame();

	kPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(NewUnit.ControllingPlayer.ObjectID));			
	AbilityData = NewUnit.GatherUnitAbilitiesForInit(NewGameState, kPlayer);
	for (i = 0; i < AbilityData.Length; ++i)
	{
		AbilityTemplate = AbilityData[i].Template;

		if( !AbilityTemplate.IsTemplateAvailableToAnyArea(AbilityTemplate.BITFIELD_GAMEAREA_Tactical) )
		{
			`log(`staticlocation @ "WARNING!! Ability:"@ AbilityTemplate.DataName@" is not available in tactical!");
		}
		else if( bIsMultiplayer && !AbilityTemplate.IsTemplateAvailableToAnyArea(AbilityTemplate.BITFIELD_GAMEAREA_Multiplayer) )
		{
			`log(`staticlocation @ "WARNING!! Ability:"@ AbilityTemplate.DataName@" is not available in multiplayer!");
		}
		else
		{
			InitAbilityForUnit(AbilityTemplate, NewUnit, NewGameState, AbilityData[i].SourceWeaponRef, AbilityData[i].SourceAmmoRef);			
		}
	}
}

static simulated function StartStateInitializeUnitAbilities(XComGameState StartState)
{	
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit UnitState;
	local X2ItemTemplate MissionItemTemplate;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// Select the mission item for the current mission (may be None)
	MissionItemTemplate = GetMissionItemTemplate();

	`assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom )
		{
			if(BattleData.DirectTransferInfo.IsDirectMissionTransfer 
				&& !UnitState.GetMyTemplate().bIsCosmetic
				&& UnitState.Abilities.Length > 0)
			{
				// XCom's abilities will have also transferred over, and do not need to be reapplied
				continue;
			}

			// update the mission items for this XCom unit
			UpdateMissionItemsForUnit(MissionItemTemplate, UnitState, StartState);
		}

		// initialize the abilities for this unit
		InitializeUnitAbilities(StartState, UnitState);
	}
}

static simulated function X2ItemTemplate GetMissionItemTemplate()
{
	if (`TACTICALMISSIONMGR.ActiveMission.RequiredMissionItem.Length > 0)
	{
		return class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(`TACTICALMISSIONMGR.ActiveMission.RequiredMissionItem[0]));
	}
	
	return none;
}

static simulated function UpdateMissionItemsForUnit(X2ItemTemplate MissionItemTemplate, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Item MissionItemState;
	local StateObjectReference ItemStateRef;

	History = `XCOMHISTORY;

	// remove the existing mission item
	foreach UnitState.InventoryItems(ItemStateRef)
	{
		MissionItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemStateRef.ObjectID));

		if( MissionItemState != None && MissionItemState.InventorySlot == eInvSlot_Mission )
		{
			UnitState.RemoveItemFromInventory(MissionItemState, NewGameState);
		}
	}

	// award the new mission item
	if( MissionItemTemplate != None )
	{
		MissionItemState = MissionItemTemplate.CreateInstanceFromTemplate(NewGameState);
		UnitState.AddItemToInventory(MissionItemState, eInvSlot_Mission, NewGameState);
	}
}

simulated function StartStateCreateXpManager(XComGameState StartState)
{
	local XComGameState_XpManager XpManager;

	XpManager = XComGameState_XpManager(StartState.CreateNewStateObject(class'XComGameState_XpManager'));
	CachedXpManagerRef = XpManager.GetReference();
	XpManager.Init(XComGameState_BattleData(StartState.GetGameStateForObjectID(CachedBattleDataRef.ObjectID)));
}

simulated function StartStateInitializeSquads(XComGameState StartState)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Player PlayerState;
	local array<XComGameState_Unit> XComUnits;
	local XComGameState_AIGroup PlayerGroup;

	PlayerGroup = XComGameState_AIGroup(StartState.CreateNewStateObject(class'XComGameState_AIGroup'));
	PlayerGroup.bProcessedScamper = true;

	foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom )
		{
			PlayerGroup.AddUnitToGroup(UnitState.ObjectID, StartState);

			UnitState.SetBaseMaxStat(eStat_DetectionModifier, HighCoverDetectionModifier);
			XComUnits.AddItem(UnitState);

			// clear out the current hack reward on mission start
			UnitState.CurrentHackRewards.Remove(0, UnitState.CurrentHackRewards.Length);
		}
	}

	foreach StartState.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if (PlayerState.GetTeam() == eTeam_XCom)
		{
			PlayerState.SquadCohesion = class'X2ExperienceConfig'.static.GetSquadCohesionValue(XComUnits);
			break;
		}
	}
}

simulated function BuildInitiativeOrder(XComGameState NewGameState)
{
	local XComGameState_BattleData BattleData;
	local string PlayerTurnName, CompareTeamName;
	local ETeam PlayerTurnTeam, CompareTurnTeam;
	local int TeamIndex;
	local XComGameState_Player PlayerState;
	local XComGameState_AIGroup PlayerGroup;
	local int InitiativeIndex;
	local array<XComGameState_AIGroup> UnsortedGroupsForPlayer;

	BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	BattleData.PlayerTurnOrder.Remove(0, BattleData.PlayerTurnOrder.Length);

	// iterate over player order
	foreach PlayerTurnOrder(PlayerTurnName)
	{
		PlayerTurnTeam = eTeam_None;
		for( TeamIndex = eTeam_Neutral; PlayerTurnTeam == eTeam_None && TeamIndex < eTeam_All; TeamIndex *= 2 )
		{
			CompareTurnTeam = ETeam(TeamIndex);
			CompareTeamName = string(CompareTurnTeam);
			if( PlayerTurnName == CompareTeamName )
			{
				PlayerTurnTeam = CompareTurnTeam;
			}
		}

		// add all players
		foreach NewGameState.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if( PlayerState.GetTeam() == PlayerTurnTeam )
			{
				BattleData.PlayerTurnOrder.AddItem(PlayerState.GetReference());
			}
		}

		foreach CachedHistory.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if( PlayerState.GetTeam() == PlayerTurnTeam &&
			   BattleData.PlayerTurnOrder.Find('ObjectID', PlayerState.ObjectID) == INDEX_NONE )
			{
				BattleData.PlayerTurnOrder.AddItem(PlayerState.GetReference());
			}
		}

		InitiativeIndex = BattleData.PlayerTurnOrder.Length;
		UnsortedGroupsForPlayer.Length = 0;

		// add all groups who should be in initiative
		foreach NewGameState.IterateByClassType(class'XComGameState_AIGroup', PlayerGroup)
		{
			if( PlayerGroup.TeamName == PlayerTurnTeam &&
			   !PlayerGroup.bShouldRemoveFromInitiativeOrder )
			{
				UnsortedGroupsForPlayer.AddItem(PlayerGroup);
			}
		}

		// add all groups who should be in initiative
		foreach CachedHistory.IterateByClassType(class'XComGameState_AIGroup', PlayerGroup)
		{
			if( PlayerGroup.TeamName == PlayerTurnTeam &&
			   !PlayerGroup.bShouldRemoveFromInitiativeOrder &&
			   UnsortedGroupsForPlayer.Find(PlayerGroup) == INDEX_NONE )
			{
				UnsortedGroupsForPlayer.AddItem(PlayerGroup);
			}
		}

		foreach UnsortedGroupsForPlayer(PlayerGroup)
		{
			InsertGroupByInitiativePriority(InitiativeIndex, PlayerGroup, BattleData);
		}
	}

	RefreshInitiativeIndex(BattleData);
}

function RefreshInitiativeIndex(XComGameState_BattleData BattleData)
{
	local int InitiativeIndex;

	// update the index to match the current initiative ref
	if( CachedUnitActionInitiativeRef.ObjectID > 0 )
	{
		for( InitiativeIndex = 0; InitiativeIndex < BattleData.PlayerTurnOrder.Length; ++InitiativeIndex )
		{
			if( CachedUnitActionInitiativeRef.ObjectID == BattleData.PlayerTurnOrder[InitiativeIndex].ObjectID )
			{
				UnitActionInitiativeIndex = InitiativeIndex;
				return;
			}
		}

		`redscreen("WARNING! The Initiative order has been compromised.  THIS IS A VERY BAD THING. @dkaplan");
	}
}

private function InsertGroupByInitiativePriority(int MinInitiativeIndex, XComGameState_AIGroup GroupState, XComGameState_BattleData BattleData)
{
	local int Index;
	local XComGameState_AIGroup OtherGroup;
	local XComGameStateHistory History;

	// do not add if the group is already in the initiative order
	if( BattleData.PlayerTurnOrder.Find('ObjectID', GroupState.ObjectID) != INDEX_NONE )
	{
		return;
	}

	History = `XCOMHISTORY;

	for( Index = MinInitiativeIndex; Index < BattleData.PlayerTurnOrder.Length; ++Index )
	{
		OtherGroup = XComGameState_AIGroup(History.GetGameStateForObjectID(BattleData.PlayerTurnOrder[Index].ObjectID));
		if( OtherGroup == None || GroupState.InitiativePriority < OtherGroup.InitiativePriority )
		{
			break;
		}
	}

	BattleData.PlayerTurnOrder.InsertItem(Index, GroupState.GetReference());
}

simulated function AddGroupToInitiativeOrder(XComGameState_AIGroup NewGroup, XComGameState NewGameState)
{
	local XComGameState_BattleData BattleData;
	local int OrderIndex;
	local XComGameState_Player PlayerState;

	BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// do not add if the group is already in the initiative order
	if( BattleData.PlayerTurnOrder.Find('ObjectID', NewGroup.ObjectID) != INDEX_NONE )
	{
		return;
	}
		
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	// Look for the new group's team in the order list.  
	for( OrderIndex = 0; OrderIndex < BattleData.PlayerTurnOrder.Length; ++OrderIndex )
	{
		PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(BattleData.PlayerTurnOrder[OrderIndex].ObjectID));
		if ( PlayerState != None )
		{
			// Looking for our team.
			if( PlayerState.GetTeam() == NewGroup.TeamName )
			{
				InsertGroupByInitiativePriority(OrderIndex + 1, NewGroup, BattleData);
				NewGroup.bShouldRemoveFromInitiativeOrder = false;

				RefreshInitiativeIndex(BattleData);

				return;
			}
		}
	}

	// Player not yet in the list.  Add the player at the end.
	foreach NewGameState.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if( PlayerState.GetTeam() == NewGroup.TeamName )
		{
			BattleData.PlayerTurnOrder.AddItem(PlayerState.GetReference());
		}
	}
	// Add the new group to the end of the list.
	BattleData.PlayerTurnOrder.AddItem(NewGroup.GetReference());
	NewGroup.bShouldRemoveFromInitiativeOrder = false;

	RefreshInitiativeIndex(BattleData);
}

simulated function RemoveGroupFromInitiativeOrder(XComGameState_AIGroup NewGroup, XComGameState NewGameState)
{
	local XComGameState_BattleData BattleData;
	local int OrderIndex;
	local XComGameState_AIGroup GroupState;

	if( NewGroup.TeamName == eTeam_XCom && NewGroup.m_arrMembers.Length > 1 )
	{
		`redscreen("WARNING! It looks like the primary XCom group is being removed from the Initiative order.  THIS IS A VERY BAD THING. @dkaplan");
	}

	BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	// Look for the new group's team in the order list.  
	for( OrderIndex = 0; OrderIndex < BattleData.PlayerTurnOrder.Length; ++OrderIndex )
	{
		GroupState = XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(BattleData.PlayerTurnOrder[OrderIndex].ObjectID));
		if( GroupState != None && GroupState.ObjectID == NewGroup.ObjectID )
		{
			BattleData.PlayerTurnOrder.Remove(OrderIndex, 1);
			break;
		}
	}

	NewGroup.bShouldRemoveFromInitiativeOrder = true;

	RefreshInitiativeIndex(BattleData);
}

function ApplyStartOfMatchConditions()
{
	local XComGameState_Player PlayerState;
	local XComGameState_BattleData BattleDataState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComTacticalMissionManager MissionManager;
	local MissionSchedule ActiveMissionSchedule;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2TacticalGameRuleset TactialRuleset;
	local X2HackRewardTemplateManager TemplateMan;
	local X2HackRewardTemplate Template;
	local XComGameState NewGameState;
	local Name HackRewardName, ConcealmentName;

	History = `XCOMHISTORY;

	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.GetActiveMissionSchedule(ActiveMissionSchedule);

	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// set initial squad concealment
	if( ActiveMissionSchedule.XComSquadStartsConcealed && !BattleDataState.bForceNoSquadConcealment )
	{
		foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if( PlayerState.GetTeam() == eTeam_XCom )
			{
				PlayerState.SetSquadConcealment(true, 'StartOfMatchConcealment');
			}
		}
	}
	else
	{
		if(!BattleDataState.DirectTransferInfo.IsDirectMissionTransfer) // only apply phantom at the start of the first leg of a multi-part mission
		{
			foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				foreach class'X2AbilityTemplateManager'.default.AbilityProvidesStartOfMatchConcealment(ConcealmentName)
				{
					if( UnitState.FindAbility(ConcealmentName).ObjectID > 0 )
					{
						UnitState.EnterConcealment();
						break;
					}
				}
			}
		}
	}

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if( XComHQ != None )	//  TQL doesn't have an HQ object
	{
		UnitState = None;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.GetTeam() == eTeam_XCom )
			{
				break;
			}
		}
		`assert(UnitState != None); // there should always be at least one XCom member at the start of a match

		TemplateMan = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
		TactialRuleset = `TACTICALRULES;
			
		// any Hack Rewards whose name matches a TacticalGameplayTag should be applied now, to the first available XCom unit
		foreach XComHQ.TacticalGameplayTags(HackRewardName)
		{
			Template = TemplateMan.FindHackRewardTemplate(HackRewardName);

			if( Template != None )
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gain Tactical Hack Reward '" $ HackRewardName $ "'");

				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

				Template.OnHackRewardAcquired(UnitState, None, NewGameState);

				TactialRuleset.SubmitGameState(NewGameState);
			}
		}
	}
}

simulated function LoadMap()
{
	local XComGameState_BattleData CachedBattleData;
		
	//Check whether the map has been generated already
	if( ParcelManager.arrParcels.Length == 0 )
	{	
		`MAPS.RemoveAllStreamingMaps(); //Generate map requires there to be NO streaming maps when it starts

		CachedBattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		ParcelManager.LoadMap(CachedBattleData);
	}
	else
	{
		ReleaseScriptLog( "Tactical Load Debug: Skipping Load Map due to ParcelManager parcel length "@ParcelManager.arrParcels.Length );
	}
}

private function AddCharacterStreamingCinematicMaps(bool bBlockOnLoad = false)
{
	local X2CharacterTemplateManager TemplateManager;
	local XComGameStateHistory History;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit UnitState;
	local array<string> MapNames;
	local string MapName;

	History = `XCOMHISTORY;
	TemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	// Force load any specified maps
	MapNames = ForceLoadCinematicMaps;

	// iterate each unit on the map and add it's cinematic maps to the list of maps
	// we need to load
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		CharacterTemplate = TemplateManager.FindCharacterTemplate(UnitState.GetMyTemplateName());
		if (CharacterTemplate != None)
		{
			foreach CharacterTemplate.strMatineePackages(MapName)
			{
				if(MapName != "" && MapNames.Find(MapName) == INDEX_NONE)
				{
					MapNames.AddItem(MapName);
				}
			}
		}
	}

	// and then queue the maps for streaming
	foreach MapNames(MapName)
	{
		`log( "Adding matinee map" $ MapName );
		`MAPS.AddStreamingMap(MapName, , , bBlockOnLoad).bForceNoDupe = true;
	}
}

private function AddDropshipStreamingCinematicMaps()
{
	local XComTacticalMissionManager MissionManager;
	local MissionIntroDefinition MissionIntro;
	local AdditionalMissionIntroPackageMapping AdditionalIntroPackage;
	local XComGroupSpawn kSoldierSpawn;
	local XComGameState StartState;
	local Vector ObjectiveLocation;
	local Vector DirectionTowardsObjective;
	local Rotator ObjectiveFacing;

	StartState = CachedHistory.GetStartState();
	ParcelManager = `PARCELMGR; // make sure this is cached

	//Don't do the cinematic intro if the below isn't correct, as this means we are loading PIE, or directly into a map
	if( StartState != none && ParcelManager != none && ParcelManager.SoldierSpawn != none)
	{
		kSoldierSpawn = ParcelManager.SoldierSpawn;		
		ObjectiveLocation = ParcelManager.ObjectiveParcel.Location;
		DirectionTowardsObjective = ObjectiveLocation - kSoldierSpawn.Location;
		DirectionTowardsObjective.Z = 0;
		ObjectiveFacing = Rotator(DirectionTowardsObjective);
	}

	// load the base intro matinee package
	MissionManager = `TACTICALMISSIONMGR;
	MissionIntro = MissionManager.GetActiveMissionIntroDefinition();
	if( kSoldierSpawn != none && MissionIntro.MatineePackage != "" && MissionIntro.MatineeSequences.Length > 0)
	{	
		`MAPS.AddStreamingMap(MissionIntro.MatineePackage, kSoldierSpawn.Location, ObjectiveFacing, false).bForceNoDupe = true;
	}

	// load any additional packages that mods may require
	if (kSoldierSpawn != none)
	{
		foreach MissionManager.AdditionalMissionIntroPackages(AdditionalIntroPackage)
		{
			if (AdditionalIntroPackage.OriginalIntroMatineePackage == MissionIntro.MatineePackage)
			{
				`MAPS.AddStreamingMap(AdditionalIntroPackage.AdditionalIntroMatineePackage, kSoldierSpawn.Location, ObjectiveFacing, false).bForceNoDupe = true;
			}
		}
	}
}

function EndReplay()
{

}

// Used in Tutorial mode to put the state back into 'PerformingReplay'
function ResumeReplay()
{
	GotoState('PerformingReplay');
}
function EventListenerReturn HandleNeutralReactionsOnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	// Kick off civilian movement when an enemy unit takes a shot nearby.
	local XComGameState_Ability ActivatedAbilityState;
	local XComGameStateContext_Ability ActivatedAbilityStateContext;
	local XComGameState_Unit SourceUnitState;
	local XComGameState_Item WeaponState;
	local int SoundRange;
	local float SoundRangeUnitsSq;
	local TTile SoundTileLocation;
	local Vector SoundLocation;
	local XComGameStateHistory History;
	local StateObjectReference CivilianPlayerRef;
	local array<GameRulesCache_VisibilityInfo> VisInfoList;
	local GameRulesCache_VisibilityInfo VisInfo;
	local XComGameState_Unit CivilianState;
	local array<XComGameState_Unit> Civilians;
	local XComGameState_BattleData Battle;
	local bool bAIAttacksCivilians;
	local XGUnit Civilian;
	local XGAIPlayer_Civilian CivilianPlayer;
	local XGAIBehavior_Civilian CivilianBehavior;

	History = `XCOMHISTORY;
	Battle = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	bAIAttacksCivilians = Battle.AreCiviliansAlienTargets();
	if( bAIAttacksCivilians )
	{
		ActivatedAbilityStateContext = XComGameStateContext_Ability(GameState.GetContext());
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.SourceObject.ObjectID));
		ActivatedAbilityState = XComGameState_Ability(EventData);
		if( SourceUnitState.ControllingPlayerIsAI() && ActivatedAbilityState.DoesAbilityCauseSound() )
		{
			if( ActivatedAbilityStateContext != None && ActivatedAbilityStateContext.InputContext.ItemObject.ObjectID > 0 )
			{
				WeaponState = XComGameState_Item(GameState.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.ItemObject.ObjectID));
				if( WeaponState != None )
				{
					SoundRange = WeaponState.GetItemSoundRange();
					SoundRangeUnitsSq = Square(`METERSTOUNITS(SoundRange));
					// Find civilians within sound range of the source and target, and add them to the list of civilians to react.
					if( SoundRange > 0 )
					{
						CivilianPlayerRef = class'X2TacticalVisibilityHelpers'.static.GetPlayerFromTeamEnum(eTeam_Neutral);
						// Find civilians in range of the source location.
						SoundTileLocation = SourceUnitState.TileLocation;
						class'X2TacticalVisibilityHelpers'.static.GetAllTeamUnitsForTileLocation(SoundTileLocation, CivilianPlayerRef.ObjectID, eTeam_Neutral, VisInfoList);
						foreach VisInfoList(VisInfo)
						{
							if( VisInfo.DefaultTargetDist < SoundRangeUnitsSq )
							{
								CivilianState = XComGameState_Unit(History.GetGameStateForObjectID(VisInfo.SourceID));
								if( !CivilianState.bRemovedFromPlay && Civilians.Find(CivilianState) == INDEX_NONE )
								{
									Civilians.AddItem(CivilianState);
								}
							}
						}

						// Also find civilians in range of the target location.
						if( ActivatedAbilityStateContext.InputContext.TargetLocations.Length > 0 )
						{
							VisInfoList.Length = 0;
							SoundLocation = ActivatedAbilityStateContext.InputContext.TargetLocations[0];
							class'X2TacticalVisibilityHelpers'.static.GetAllTeamUnitsForLocation(SoundLocation, CivilianPlayerRef.ObjectID, eTeam_Neutral, VisInfoList);
							foreach VisInfoList(VisInfo)
							{
								if( VisInfo.DefaultTargetDist < SoundRangeUnitsSq )
								{
									CivilianState = XComGameState_Unit(History.GetGameStateForObjectID(VisInfo.SourceID));
									if( !CivilianState.bRemovedFromPlay && Civilians.Find(CivilianState) == INDEX_NONE )
									{
										Civilians.AddItem(CivilianState);
									}
								}
							}
						}

						// Adding civilian target unit if not dead.  
						CivilianState = XComGameState_Unit(History.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.PrimaryTarget.ObjectID));
						if(CivilianState != none
						   && CivilianState.GetTeam() == eTeam_Neutral 
						   && CivilianState.IsAlive() 
						   && !CivilianState.bRemovedFromPlay 
						   && Civilians.Find(CivilianState) == INDEX_NONE )
						{
							Civilians.AddItem(CivilianState);
						}

						LastNeutralReactionEventChainIndex = History.GetEventChainStartIndex();
						CivilianPlayer = XGBattle_SP(`BATTLE).GetCivilianPlayer();
						CivilianPlayer.InitTurn();

						// Any civilians we've found in range will now run away.
						foreach Civilians(CivilianState)
						{
							Civilian = XGUnit(CivilianState.GetVisualizer());

							CivilianBehavior = XGAIBehavior_Civilian(Civilian.m_kBehavior);
							if (CivilianBehavior != none)
							{
								CivilianBehavior.InitActivate();
								CivilianState.AutoRunBehaviorTree();
								CivilianPlayer.AddToMoveList(Civilian);
							}
						}
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn HandleNeutralReactionsOnMovement(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData) 
{
	local XComGameState_Unit MovedUnit, CivilianState;
	local array<XComGameState_Unit> Civilians;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local XComGameState_BattleData Battle;
	local XGAIPlayer_Civilian CivilianPlayer;
	local XGUnit Civilian;
	local bool bAIAttacksCivilians, bCiviliansRunFromXCom;
	local int EventChainIndex;
	local TTile MovedToTile;
	local float MaxTileDistSq;
	local GameRulesCache_VisibilityInfo OutVisInfo;
	local ETeam MoverTeam;
	local XGAIBehavior_Civilian CivilianBehavior;

	MovedUnit = XComGameState_Unit( EventData );
	MoverTeam = MovedUnit.GetTeam();
	if( MovedUnit.IsMindControlled() )
	{
		MoverTeam = MovedUnit.GetPreviousTeam();
	}
	if( (MovedUnit == none) || MovedUnit.GetMyTemplate().bIsCosmetic || (XGUnit(MovedUnit.GetVisualizer()).m_eTeam == eTeam_Neutral) )
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	Battle = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	bCiviliansRunFromXCom = Battle.CiviliansAreHostile();
	bAIAttacksCivilians = Battle.AreCiviliansAlienTargets();

	if (!bCiviliansRunFromXCom && MoverTeam == eTeam_XCom)
	{
		return ELR_NoInterrupt;
	}

	// In missions where AI doesn't attack civilians, do nothing if the player or the mover is concealed.
	if(!bAIAttacksCivilians )
	{
		// If XCom is in squad concealment, don't move.
		foreach History.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
		{
			if( PlayerState.PlayerClassName == Name("XGPlayer") )
			{
				if( PlayerState.bSquadIsConcealed )
				{
					return ELR_NoInterrupt; // Do not move if squad concealment is active.
				}
				break;
			}
		}

		if( MovedUnit.IsConcealed() && bCiviliansRunFromXCom )
		{
			return ELR_NoInterrupt;
		}
	}
	else
	{
		// Addendum from Brian - only move civilians from Aliens when the alien that moves is out of action points.
		if( (MoverTeam == eTeam_Alien || MoverTeam == eTeam_TheLost) && MovedUnit.NumAllActionPoints() > 0 && MovedUnit.IsMeleeOnly() )
		{
			return ELR_NoInterrupt;
		}
	}

	// Only kick off civilian behavior once per event chain.
	EventChainIndex = History.GetEventChainStartIndex();
	if( EventChainIndex == LastNeutralReactionEventChainIndex )
	{
		return ELR_NoInterrupt;
	}
	LastNeutralReactionEventChainIndex = EventChainIndex;

	// All civilians in range now update.
	CivilianPlayer = XGBattle_SP(`BATTLE).GetCivilianPlayer();
	CivilianPlayer.InitTurn();
	CivilianPlayer.GetPlayableUnits(Civilians);

	MovedToTile = MovedUnit.TileLocation;
	MaxTileDistSq = Square(class'XGAIBehavior_Civilian'.default.CIVILIAN_NEAR_STANDARD_REACT_RADIUS);

	// Kick off civilian behavior tree if it is in range of the enemy.
	foreach Civilians(CivilianState)
	{
		if (CivilianState.bTriggerRevealAI == false) 
		{
			continue;
		}
		// Let kismet handle XCom rescue behavior.
		if( bAIAttacksCivilians && !CivilianState.IsAlien() && MoverTeam == eTeam_XCom )
		{
			continue;
		}
		// Let the Ability trigger system handle Faceless units when XCom moves into range. 
		if( CivilianState.IsAlien() && MoverTeam == eTeam_XCom )
		{
			continue;
		}
		// Probably a VIP that the player interacts with that should just stay put in this case
		if (CivilianState.GetMyTemplate().bUsePoolVIPs)
		{
			continue;
		}

		// Start Issue #666
		//
		// Let mods have their say on whether this civilian should run from MovedUnit.
		if (!TriggerShouldCivilianRun(CivilianState, MovedUnit, bAIAttacksCivilians))
		{
			continue;
		}
		// End Issue #666

		// Non-rescue behavior is kicked off here.
		if( class'Helpers'.static.IsTileInRange(CivilianState.TileLocation, MovedToTile, MaxTileDistSq) 
		   && VisibilityMgr.GetVisibilityInfo(MovedUnit.ObjectID, CivilianState.ObjectID, OutVisInfo)
			&& OutVisInfo.bVisibleGameplay )
		{
			Civilian = XGUnit(CivilianState.GetVisualizer());
			
			CivilianBehavior = XGAIBehavior_Civilian(Civilian.m_kBehavior);
			if (CivilianBehavior != none)
			{
				CivilianBehavior.InitActivate();
				CivilianState.AutoRunBehaviorTree();
				CivilianPlayer.AddToMoveList(Civilian);
			}
		}
	}

	return ELR_NoInterrupt;
}

// Start Issue #666
/// HL-Docs: feature:ShouldCivilianRun; issue:666; tags:tactical
/// Triggers a 'ShouldCivilianRun' event that allows listeners to determine whether
/// neutrals should run in reaction to another unit moving by them. Returns `true`
/// if the given neutral unit should run, `false` otherwise.
///
/// ```event
/// EventID: ShouldCivilianRun,
/// EventData: [in XComGameState_Unit MovedUnit, in bool AIAttacksCivilians, inout bool ShouldRun],
/// EventSource: XComGameState_Unit (Civilian),
/// NewGameState: none
/// ```
static function bool TriggerShouldCivilianRun(
	XComGameState_Unit CivilianUnit,
	XComGameState_Unit MovedUnit,
	bool AIAttacksCivilians)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'ShouldCivilianRun';
	Tuple.Data.Add(3);
	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].o = MovedUnit;
	Tuple.Data[1].kind = XComLWTVBool;
	Tuple.Data[1].b = AIAttacksCivilians;
	Tuple.Data[2].kind = XComLWTVBool;
	Tuple.Data[2].b = true;

	`XEVENTMGR.TriggerEvent(Tuple.Id, Tuple, CivilianUnit);

	return Tuple.Data[2].b;
}
// End Issue #666

function EventListenerReturn HandleUnitDiedCache(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData) 
{
	local XComGameState_Unit DeadUnit;

	DeadUnit = XComGameState_Unit( EventData );

	if( (DeadUnit == none) || DeadUnit.GetMyTemplate().bIsCosmetic )
	{
		return ELR_NoInterrupt;
	}

	CachedDeadUnits.AddItem(DeadUnit.GetReference());

	return ELR_NoInterrupt;
}

function EventListenerReturn HandleAdditionalFalling(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory History;
	local StateObjectReference UnitRef;
	local XComGameState_Unit DeadUnit;
	local XComWorldData WorldData;
	local TTIle VisualizerTile;
	local XGUnit UnitVisualizer;

	local XComGameState_LootDrop Loot, FallLoot;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	foreach CachedDeadUnits(UnitRef)
	{
		DeadUnit = XComGameState_Unit( History.GetGameStateForObjectID( UnitRef.ObjectID ) );

		if( DeadUnit != none && !WorldData.IsTileOutOfRange(DeadUnit.TileLocation) )
		{
			if ((XGUnit(DeadUnit.GetVisualizer()).GetPawn().RagdollFlag == ERagdoll_Never) && DeadUnit.bFallingApplied)
			{
				continue;
			}

			UnitVisualizer = XGUnit( DeadUnit.GetVisualizer( ) );
			VisualizerTile = WorldData.GetTileCoordinatesFromPosition( UnitVisualizer.Location );

			if (!WorldData.IsTileOutOfRange(VisualizerTile) && !WorldData.IsFloorTile( VisualizerTile ))
			{
				WorldData.SubmitUnitFallingContext( DeadUnit, VisualizerTile );
			}
		}
	}

	foreach History.IterateByClassType( class'XComGameState_LootDrop', Loot )
	{
		if (!WorldData.IsTileOutOfRange(Loot.TileLocation) && !WorldData.IsFloorTile( Loot.TileLocation ))
		{
			if (NewGameState == none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Loot Falling" );
			}

			FallLoot = XComGameState_LootDrop( NewGameState.ModifyStateObject( class'XComGameState_LootDrop', Loot.ObjectID ) );
			FallLoot.TileLocation.Z = WorldData.GetFloorTileZ( Loot.TileLocation, true );

			NewGameState.GetContext( ).PostBuildVisualizationFn.AddItem( FallLoot.VisualizeLootFountainMove );
		}
	}

	if (NewGameState != none)
	{
		SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

simulated function bool CanToggleWetness()
{
	local XComGameState_BattleData BattleDataState;
	local PlotDefinition PlotDef;
	local bool bWet;
	local string strMissionType;	

	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	bWet = false;
	strMissionType = "";
	if (BattleDataState != none)
	{
		PlotDef = `PARCELMGR.GetPlotDefinition(BattleDataState.MapData.PlotMapName);

		// much hackery follows...
		// using LightRain for precipitation without sound effects and lightning, and LightStorm for precipitation with sounds effects and lightning
		switch (PlotDef.strType)
		{
		case "Shanty":
			// This could be cleaner without all the calls to XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(),
			// but attempting to use a variable required modifying what this class depends on. That resulted in some unreal weirdness that changed some headers
			// and functions that I never touched, which I wasn't comfortable with.
			XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(LightRain, 0, 0, 0);			
			break;
		case "Facility":
		case "DerelictFacility":
		case "LostTower":
		case "Tunnels_Sewer":
		case "Tunnels_Subway":
			XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(NoStorm, 0, 0, 0);
			break;
		default:
			// PsiGate acts like Shanty above, but it's a mission, not a plotType
			strMissionType = BattleDataState.MapData.ActiveMission.sType;
			if (strMissionType == "GP_PsiGate")
			{
				XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(LightRain, 0, 0, 0);
			}
			else if (BattleDataState.bRainIfPossible)
			{
				// Nothing for Arid. Tundra gets snow only. Temperate gets wetness, precipitation, sound effects and lightning.
				if (BattleDataState.MapData.Biome == "" || BattleDataState.MapData.Biome == "Temperate" || PlotDef.strType == "CityCenter" || PlotDef.strType == "Slums")
				{					
					XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(LightStorm, 0, 0, 0);
					bWet = true;
				}
				else if (BattleDataState.MapData.Biome == "Tundra")
				{
					XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(LightRain, 0, 0, 0);
				}
				else
				{
					XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(NoStorm, 0, 0, 0);
				}
			}
			else
			{
				XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(NoStorm, 0, 0, 0);
			}
			break;
		}
	}
	else
	{
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(NoStorm, 0, 0, 0);
	}

	return bWet;
}

// Do any specific remote events related to environment lighting
simulated function EnvironmentLightingRemoteEvents()
{
	local XComGameState_BattleData BattleDataState;

	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// Forge only check to change the height fog actors to mask out the underneath of forge parcel that can be seen through glass floors (yay run on sentence)
	if (BattleDataState.MapData.PlotMapName != "" && arrHeightFogAdjustedPlots.Find(BattleDataState.MapData.PlotMapName) != INDEX_NONE)
	{
		`XCOMGRI.DoRemoteEvent('ModifyHeightFogActorProperties');
	}
}

// Call after abilities are initialized in post begin play, which may adjust stats.
// This function restores all transferred units' stats to their pre-transfer values, 
// to help maintain the illusion of one continuous mission
simulated private function RestoreDirectTransferUnitStats()
{
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local DirectTransferInformation_UnitStats UnitStats;
	local XComGameState_Unit UnitState;
	local XComGameState_Effect_TemplarFocus FocusEffect;

	BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(!BattleData.DirectTransferInfo.IsDirectMissionTransfer)
	{
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Restore Transfer Unit Stats");

	foreach BattleData.DirectTransferInfo.TransferredUnitStats(UnitStats)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitStats.UnitStateRef.ObjectID));
		UnitState.SetCurrentStat(eStat_HP, UnitStats.HP);
		UnitState.AddShreddedValue(UnitStats.ArmorShred);
		UnitState.LowestHP = UnitStats.LowestHP;
		UnitState.HighestHP = UnitStats.HighestHP;
		UnitState.MissingHP = UnitStats.MissingHP;

		if (UnitStats.FocusAmount > 0)
		{
			FocusEffect = UnitState.GetTemplarFocusEffectState();
			if (FocusEffect != none)
			{
				FocusEffect = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusEffect.Class, FocusEffect.ObjectID));
				FocusEffect.SetFocusLevel(UnitStats.FocusAmount, UnitState, NewGameState, true);
			}
		}
	}

	SubmitGameState(NewGameState);
}

simulated function BeginTacticalPlay()
{
	local XComGameState_BaseObject ObjectState, NewObjectState;
	local XComGameState_Ability AbilityState;
	local XComGameState_BattleData BattleData;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Begin Tactical Play");

	foreach CachedHistory.IterateByClassType(class'XComGameState_BaseObject', ObjectState)
	{
		NewObjectState = NewGameState.ModifyStateObject(ObjectState.Class, ObjectState.ObjectID);
		NewObjectState.bInPlay = false;
	}

	bTacticalGameInPlay = true;

	// have any abilities that are post play activated start up
	foreach CachedHistory.IterateByClassType(class'XComGameState_Ability', AbilityState)
	{
		if(AbilityState.OwnerStateObject.ObjectID > 0)
		{
			AbilityState.CheckForPostBeginPlayActivation( NewGameState );
		}
	}

	// iterate through all existing state objects and call BeginTacticalPlay on them
	foreach NewGameState.IterateByClassType(class'XComGameState_BaseObject', ObjectState)
	{
		ObjectState.BeginTacticalPlay(NewGameState);
	}

	// if we're playing a challenge, don't do much encounter vo
	if (CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) != none)
	{
		`CHEATMGR.DisableFirstEncounterVO = true;
	}

	// if we're playing a skirmish map, don't do encounter vo
	BattleData = XComGameState_BattleData( CachedHistory.GetGameStateForObjectID( CachedBattleDataRef.ObjectID ) );
	if (BattleData.m_strDesc == "Skirmish Mode")
	{
		`CHEATMGR.DisableFirstEncounterVO = true;
	}

	`XEVENTMGR.TriggerEvent('OnTacticalBeginPlay', self, , NewGameState);

	SubmitGameState(NewGameState);

	RestoreDirectTransferUnitStats();
}

simulated function EndTacticalPlay()
{
	local XComGameState_BaseObject ObjectState, NewObjectState;
	local XComGameState NewGameState;
	local X2EventManager EventManager;
	local Object ThisObject;

	bTacticalGameInPlay = false;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("End Tactical Play");

	// iterate through all existing state objects and call EndTacticalPlay on them
	foreach CachedHistory.IterateByClassType(class'XComGameState_BaseObject', ObjectState)
	{
		if (!ObjectState.bTacticalTransient)
		{
			NewObjectState = NewGameState.ModifyStateObject( ObjectState.Class, ObjectState.ObjectID );
			NewObjectState.EndTacticalPlay( NewGameState );
		}
		else
		{
			ObjectState.EndTacticalPlay( NewGameState );
		}		
	}

	EventManager = `XEVENTMGR;
		ThisObject = self;

	EventManager.UnRegisterFromEvent(ThisObject, 'UnitMoveFinished');
	EventManager.UnRegisterFromEvent(ThisObject, 'UnitDied');

	SubmitGameState(NewGameState);
}

static function CleanupTacticalMission(optional bool bSimCombat = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local int LootIndex, ObjectiveIndex;
	local X2ItemTemplateManager ItemTemplateManager;
	local XComGameState_Item ItemState;
	local XComGameState_Unit UnitState;
	local XComGameState_LootDrop LootDropState;
	local Name ObjectiveLootTableName;
	local X2LootTableManager LootManager;
	local array<Name> RolledLoot;
	local XComGameState_XpManager XpManager, NewXpManager;
	local int MissionIndex;
	local MissionDefinition RefMission;
	local int CivKilled, CivTotal, ResKilled, ResTotal, TotalSaved;
	local XComGameState_Effect BleedOutEffect; // Issue #571

	History = `XCOMHISTORY;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cleanup Tactical Mission");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.bReturningFromMission = true;
	XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.Remove(0, XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.Length);

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	// Start Issue #96:
	// Let mods handle any necessary cleanup before we do recovery.
	`XEVENTMGR.TriggerEvent('CleanupTacticalMission', BattleData, none, NewGameState);
	// End Issue #96

	// Start Issue #571
	//
	// Let mods determine whether to recover incapacitated/dead soldiers or not
	// if they choose.
	if (TriggerOverrideBodyRecovery(BattleData, BattleData.AllTacticalObjectivesCompleted(), NewGameState))
	{
	// End Issue #571
		// recover all dead soldiers, remove all other soldiers from play/clear deathly ailments
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( XComHQ.IsUnitInSquad(UnitState.GetReference()) )
			{
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				UnitState.RemoveUnitFromPlay();
				UnitState.bBleedingOut = false;
				UnitState.bUnconscious = false;

				if( UnitState.IsDead() )
				{
					UnitState.bBodyRecovered = true;
				}
			}
		}
	}

	// Start Issue #571
	//
	// Let mods determine whether to recover loot or not if they choose.
	if (TriggerOverrideLootRecovery(BattleData, BattleData.AllTacticalObjectivesCompleted(), NewGameState))
	{
	// End Issue #571
		foreach History.IterateByClassType(class'XComGameState_LootDrop', LootDropState)
		{
			for( LootIndex = 0; LootIndex < LootDropState.LootableItemRefs.Length; ++LootIndex )
			{
				ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', LootDropState.LootableItemRefs[LootIndex].ObjectID));

				ItemState.OwnerStateObject = XComHQ.GetReference();
				XComHQ.PutItemInInventory(NewGameState, ItemState, true);

				BattleData.CarriedOutLootBucket.AddItem(ItemState.GetMyTemplateName());
			}
		}
	}

	// Start Issue #571
	//
	// Corpse retrieval and other "auto loot" stuff still needs tactical
	// objectives to be completed.
	if (BattleData.AllTacticalObjectivesCompleted())
	{
	// End Issue #571
		// 7/29/15 Non-explicitly-picked-up loot is now once again only recovered if the sweep objective was completed
		RolledLoot = BattleData.AutoLootBucket;
	}
	else
	{
		// Start Issue #571
		//
		// Only handle capture of mind-controlled soldiers if we're *not* recovering
		// soldiers.
		if (!TriggerOverrideBodyRecovery(BattleData, false, NewGameState))
		{
		// End Issue #571
			//It may be the case that the user lost as a result of their remaining units being mind-controlled. Consider them captured (before the mind-control effect gets wiped).
			foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				if (XComHQ.IsUnitInSquad(UnitState.GetReference()))
				{
					if (UnitState.IsMindControlled())
					{
						UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
						UnitState.bCaptured = true;
					}
				}

				// Start Issue #571
				//
				// Bug fix from LW2. Ensure that bleed-out status is cleared on captured (and dead) soldiers.
				if (UnitState.bBleedingOut)
				{
					BleedOutEffect = UnitState.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
					BleedOutEffect.RemoveEffect(NewGameState, NewGameState, false);
				}
				// End Issue #571
			}
		}
	}

	//Backwards compatibility support for campaigns started when mission objectives could only have one loot table
	MissionIndex = class'XComTacticalMissionManager'.default.arrMissions.Find('MissionName', BattleData.MapData.ActiveMission.MissionName);
	if ( MissionIndex > -1)
	{
		RefMission = class'XComTacticalMissionManager'.default.arrMissions[MissionIndex];
	}
	
	// add loot for each successful Mission Objective
	LootManager = class'X2LootTableManager'.static.GetLootTableManager();
	for( ObjectiveIndex = 0; ObjectiveIndex < BattleData.MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( BattleData.MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted )
		{
			ObjectiveLootTableName = GetObjectiveLootTable(BattleData.MapData.ActiveMission.MissionObjectives[ObjectiveIndex]);
			if (ObjectiveLootTableName == '' && RefMission.MissionObjectives[ObjectiveIndex].SuccessLootTables.Length > 0)
			{
				//Try again with the ref mission, backwards compatibility support
				ObjectiveLootTableName = GetObjectiveLootTable(RefMission.MissionObjectives[ObjectiveIndex]);
			}

			if( ObjectiveLootTableName != '' )
			{
				LootManager.RollForLootTable(ObjectiveLootTableName, RolledLoot);
			}
		}
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	for( LootIndex = 0; LootIndex < RolledLoot.Length; ++LootIndex )
	{
		// create the loot item
		ItemState = ItemTemplateManager.FindItemTemplate(
		RolledLoot[LootIndex]).CreateInstanceFromTemplate(NewGameState);

		// assign the XComHQ as the new owner of the item
		ItemState.OwnerStateObject = XComHQ.GetReference();

		// add the item to the HQ's inventory of loot items
		XComHQ.PutItemInInventory(NewGameState, ItemState, true);
	}

	// If this was a Chosen Retaliation mission, calculate the number of rescued civilians and create rewards to add to XComHQ as loot
	if (BattleData.MapData.ActiveMission.MissionFamily == "ChosenRetaliation")
	{
		CivKilled = class'Helpers'.static.GetNumCiviliansKilled(CivTotal, true);
		TotalSaved += (CivTotal - CivKilled);
		
		ResKilled = class'Helpers'.static.GetNumResistanceSoldiersKilled(ResTotal, true);
		TotalSaved += (ResTotal - ResKilled);
		
		// Create the Rescued Civ loot item and add it to the HQ inventory
		if (TotalSaved > 0)
		{
			ItemState = ItemTemplateManager.FindItemTemplate('RescueCivilianReward').CreateInstanceFromTemplate(NewGameState);
			ItemState.Quantity = TotalSaved;
			ItemState.OwnerStateObject = XComHQ.GetReference();
			XComHQ.PutItemInInventory(NewGameState, ItemState, true);
		}
	}

	//  Distribute XP
	if( !bSimCombat )
	{
		XpManager = XComGameState_XpManager(History.GetSingleGameStateObjectForClass(class'XComGameState_XpManager', true)); //Allow null for sim combat / cheat start
		NewXpManager = XComGameState_XpManager(NewGameState.ModifyStateObject(class'XComGameState_XpManager', XpManager == none ? -1 : XpManager.ObjectID));
		NewXpManager.DistributeTacticalGameEndXp(NewGameState);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// Start Issue #571
//
// Fires an event that allows mods to override whether incapacitated/dead soldiers
// should be automatically recovered at the end of a mission. The `DoBodyRecovery`
// parameter specifies what the current behaviour will be.
//
// The event that's fired takes the form:
//
//   {
//     ID: OverrideBodyRecovery,
//     Data: [inout bool DoBodyRecovery],
//     Source: XComGameState_BattleData
//   }
//
private static function bool TriggerOverrideBodyRecovery(
	XComGameState_BattleData BattleData,
	bool DoBodyRecovery,
	XComGameState NewGameState)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideBodyRecovery';
	OverrideTuple.Data.Add(1);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = DoBodyRecovery;

	`XEVENTMGR.TriggerEvent('OverrideBodyRecovery', OverrideTuple, BattleData, NewGameState);

	return OverrideTuple.Data[0].b;
}

// Fires an event that allows mods to override whether loot should be automatically
// recovered at the end of a mission. The `DoLootRecovery` parameter specifies what
// the current behaviour will be.
//
// The event that's fired takes the form:
//
//   {
//     ID: OverrideLootRecovery,
//     Data: [inout bool DoLootRecovery],
//     Source: XComGameState_BattleData
//   }
//
private static function bool TriggerOverrideLootRecovery(
	XComGameState_BattleData BattleData,
	bool DoLootRecovery,
	XComGameState NewGameState)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideLootRecovery';
	OverrideTuple.Data.Add(1);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = DoLootRecovery;

	`XEVENTMGR.TriggerEvent('OverrideLootRecovery', OverrideTuple, BattleData, NewGameState);

	return OverrideTuple.Data[0].b;
}
// End Issue #571

static function name GetObjectiveLootTable(MissionObjectiveDefinition MissionObj)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local name LootTableName;
	local int CurrentForceLevel, HighestValidForceLevel, idx;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	CurrentForceLevel = AlienHQ.GetForceLevel();

	if (MissionObj.SuccessLootTables.Length == 0)
	{
		return ''; 
	}

	HighestValidForceLevel = -1;

	for(idx = 0; idx < MissionObj.SuccessLootTables.Length; idx++)
	{
		if(CurrentForceLevel >= MissionObj.SuccessLootTables[idx].ForceLevel &&
		   MissionObj.SuccessLootTables[idx].ForceLevel > HighestValidForceLevel)
		{
			HighestValidForceLevel = MissionObj.SuccessLootTables[idx].ForceLevel;
			LootTableName = MissionObj.SuccessLootTables[idx].LootTableName;
		}
	}

	return LootTableName;
}

function StartStatePositionUnits()
{
	local XComGameState StartState;		
	local XComGameState_Player PlayerState;
	local XComGameState_Unit UnitState;
	local XComGameState_BattleData BattleData;
	
	local vector vSpawnLoc;
	local XComGroupSpawn kSoldierSpawn;
	local array<vector> FloorPoints;

	StartState = CachedHistory.GetStartState();
	ParcelManager = `PARCELMGR; // make sure this is cached

	//If this is a start state, we need to additional processing. Place the player's
	//units. Create and place the AI player units.
	//======================================================================
	if( StartState != none )
	{
		if(ParcelManager == none || ParcelManager.SoldierSpawn == none)
		{
			// We're probably loaded in PIE, which doesn't go through the parcel manager. Just grab any spawn point for
			// testing
			foreach `XWORLDINFO.AllActors(class'XComGroupSpawn', kSoldierSpawn) { break; }
		}
		else
		{
			kSoldierSpawn = ParcelManager.SoldierSpawn;
		}

		foreach StartState.IterateByClassType( class'XComGameState_BattleData', BattleData ) { break; }

		ParcelManager.ParcelGenerationAssert(kSoldierSpawn != none, "No Soldier Spawn found when positioning units!");
			
		kSoldierSpawn.GetValidFloorLocations(FloorPoints, BattleData.MapData.ActiveMission.SquadSpawnSizeOverride );

		ParcelManager.ParcelGenerationAssert(FloorPoints.Length > 0, "No valid floor points for spawn: " $ kSoldierSpawn);
						
		//Updating the positions of the units
		foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
		{				
			`assert(UnitState.bReadOnly == false);

			PlayerState = XComGameState_Player(StartState.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID, eReturnType_Reference));			
			if (PlayerState != None && PlayerState.TeamFlag == ETeam.eTeam_XCom && UnitState.ControllingPlayer.ObjectID == PlayerState.ObjectID)
			{
				vSpawnLoc = FloorPoints[`SYNC_RAND_TYPED(FloorPoints.Length)];
				FloorPoints.RemoveItem(vSpawnLoc);						

				UnitState.SetVisibilityLocationFromVector(vSpawnLoc);
				`XWORLD.SetTileBlockedByUnitFlag(UnitState);
			}
		}
	}
}

/// <summary>
/// Cycles through building volumes and update children floor volumes and extents. Needs to happen early in loading, before units spawn.
/// </summary>
simulated function InitVolumes()
{
	local XComBuildingVolume kVolume;
	local XComMegaBuildingVolume kMegaVolume;

	foreach WorldInfo.AllActors(class 'XComBuildingVolume', kVolume)
	{
		if (kVolume != none)   // Hack to eliminate tree break
		{
			kVolume.CacheBuildingVolumeInChildrenFloorVolumes();
			kVolume.CacheFloorCenterAndExtent();
		}
	}

	foreach WorldInfo.AllActors(class 'XComMegaBuildingVolume', kMegaVolume)
	{
		if (kMegaVolume != none)
		{
			kMegaVolume.InitInLevel();
			kMegaVolume.CacheBuildingVolumeInChildrenFloorVolumes();
			kMegaVolume.CacheFloorCenterAndExtent();
		}
	}
}

simulated function bool ShowUnitFlags( )
{
	return true;
}

private simulated function HeadshotReceived(StateObjectReference UnitRef)
{
	if (--m_HeadshotsPending == 0)
	{
		m_kPhotoboothAutoGen.Destroy();
		m_kTacticalLocation.Cleanup();
		m_kTacticalLocation = none;
	}
}

/// <summary>
/// This state is entered if the tactical game being played need to be set up first. Setup handles placing units, creating scenario
/// specific game states, processing any scenario kismet logic, etc.
/// </summary>
simulated state CreateTacticalGame
{
	simulated event BeginState(name PreviousStateName)
	{
		local X2EventManager EventManager;
		local Object ThisObject;

		`SETLOC("BeginState");

		// the start state has been added by this point
		//	nothing in this state should be adding anything that is not added to the start state itself
		CachedHistory.AddHistoryLock();

		EventManager = `XEVENTMGR;
		ThisObject = self;

		EventManager.RegisterForEvent(ThisObject, 'UnitMoveFinished', HandleNeutralReactionsOnMovement, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'AbilityActivated', HandleNeutralReactionsOnAbilityActivated, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'UnitDied', HandleUnitDiedCache, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'TileDataChanged', HandleAdditionalFalling, ELD_OnStateSubmitted);

		// allow templated event handlers to register themselves
		class'X2EventListenerTemplateManager'.static.RegisterTacticalListeners();
	}
	
	simulated function StartStateSpawnAliens(XComGameState StartState)
	{
		local XComGameState_Player IteratePlayerState;
		local XComGameState_BattleData BattleData;
		local XComGameState_MissionSite MissionSiteState;
		local XComAISpawnManager SpawnManager;
		local int AlertLevel, ForceLevel;

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		ForceLevel = BattleData.GetForceLevel();
		AlertLevel = BattleData.GetAlertLevel();

		if( BattleData.m_iMissionID > 0 )
		{
			MissionSiteState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(BattleData.m_iMissionID));

			if( MissionSiteState != None && MissionSiteState.SelectedMissionData.SelectedMissionScheduleName != '' )
			{
				AlertLevel = MissionSiteState.SelectedMissionData.AlertLevel;
				ForceLevel = MissionSiteState.SelectedMissionData.ForceLevel;
			}
		}

		SpawnManager = `SPAWNMGR;
		SpawnManager.ClearCachedFireTiles();
		SpawnManager.SpawnAllAliens(ForceLevel, AlertLevel, StartState, MissionSiteState);

		// Start Issue #457
		/// HL-Docs: feature:PostAliensSpawned; issue:457; tags:tactical
		/// This event triggers right after the alien pods are added into the tactical mission's Start State, before their visualizers are spawned/visualized.
		/// Overall it can be treated as an earlier alternative to `'OnTacticalBeginPlay'` event.
		/// It can be used to make arbitrary changes to units that were just added to the Start State,
		///	including Soldier VIPs that are spawned for Gather Survivors missions.
		///	For example, this is how to set up an Event Listener to modify these Soldier VIPs:
		/// ```unrealscript
		/// //	This EventFn requires an ELD_Immediate deferral.
		/// static protected function EventListenerReturn PostAliensSpawned_Listener(Object EventData, Object EventSource, XComGameState StartState, Name EventID, Object CallbackData)
		/// {
		/// 	local XComTacticalMissionManager	MissionManager;
		/// 	local XComGameState_Unit			UnitState;
		/// 	local XComGameState_AIGroup			GroupState;
		/// 
		/// 	MissionManager = `TACTICALMISSIONMGR;
		/// 	if (MissionManager.ActiveMission.sType == "GatherSurvivors")
		/// 	{
		/// 		//	Cycle through Group States, which are basically Game States for pods.
		/// 		foreach GameState.IterateByClassType(class'XComGameState_AIGroup', GroupState)
		/// 		{
		/// 			//	Check the pod for correct markings.
		/// 			if (GroupState.EncounterID == 'ResistanceTeamMember_VIP' && GroupState.PrePlacedEncounterTag == 'ResistanceTeamMember_01')
		/// 			{
		/// 				//	Assume the pod contains only one unit and grab the Unit State for it.
		/// 				UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(GroupState.m_arrMembers[0].ObjectID));
		/// 				if (UnitState != none)
		/// 				{
		/// 					//	Make arbitrary changes to the Unit here.
		/// 				}
		/// 			}
		/// 			//	Do the same for GroupState.PrePlacedEncounterTag == 'ResistanceTeamMember_02' here.
		/// 		}
		/// 	}
		/// 	return ELR_NoInterrupt;
		/// }
		/// ```
		/// 
		/// ```unrealscript
		/// EventID: PostAliensSpawned
		/// NewGameState: StartState
		/// ```
		`XEVENTMGR.TriggerEvent('PostAliensSpawned',,, StartState);
		// End Issue #457

		// After spawning, the AI player still needs to sync the data
		foreach StartState.IterateByClassType(class'XComGameState_Player', IteratePlayerState)
		{
			//issue #188 change vanilla addition to auto adding every AIPlayer that isn't the MP teams, this lets AIPlayers sync their units to a singleton AIPlayerData, letting units resolve alerts they receive
			//this is vital for how XCOM 2's gameplay works: if a unit can't resolve an alert telling them to go into red alert, they will never be able to fire on hostiles
			//this should also expand the capability of what modders can do with teams like eTeam_Resistance: units on these teams will be able to work normally, instead of relying on kismet to be alerted
			if( IteratePlayerState.TeamFlag != eTeam_One && IteratePlayerState.TeamFlag != eTeam_Two ) 
			{				
				XGAIPlayer( CachedHistory.GetVisualizer(IteratePlayerState.ObjectID) ).UpdateDataToAIGameState(true);
				//break;
			}
			if(IteratePlayerState.TeamFlag == eTeam_One && class'CHHelpers'.static.TeamOneRequired()) //and check the MP teams, and add AIPlayers for them depending on what mods are installed
			{
				XGAIPlayer( CachedHistory.GetVisualizer(IteratePlayerState.ObjectID) ).UpdateDataToAIGameState(true);
			}
			
			if(IteratePlayerState.TeamFlag == eTeam_Two && class'CHHelpers'.static.TeamTwoRequired())
			{
				XGAIPlayer( CachedHistory.GetVisualizer(IteratePlayerState.ObjectID) ).UpdateDataToAIGameState(true);
			}			
			//end issue #188
		}
	}

	simulated function StartStateSpawnCosmeticUnits(XComGameState StartState)
	{
		local XComGameState_Item IterateItemState;
				
		foreach StartState.IterateByClassType(class'XComGameState_Item', IterateItemState)
		{
			IterateItemState.CreateCosmeticItemUnit(StartState);
		}
	}

	function SetupPIEGame()
	{
		local XComParcel FakeObjectiveParcel;
		local MissionDefinition MissionDef;

		local Sequence GameSequence;
		local Sequence LoadedSequence;
		local array<string> KismetMaps;

		local X2DataTemplate ItemTemplate;
		local X2QuestItemTemplate QuestItemTemplate;

		// Since loading a map in PIE just gives you a single parcel and possibly a mission map, we need to
		// infer the mission type and create a fake objective parcel so that the LDs can test the game in PIE

		// This would normally be set when generating a map
		ParcelManager.TacticalMissionManager = `TACTICALMISSIONMGR;

		// Get the map name for all loaded kismet sequences
		GameSequence = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
		foreach GameSequence.NestedSequences(LoadedSequence)
		{
			// when playing in PIE, maps names begin with "UEDPIE". Strip that off.
			KismetMaps.AddItem(split(LoadedSequence.GetLevelName(), "UEDPIE", true));
		}

		// determine the mission 
		foreach ParcelManager.TacticalMissionManager.arrMissions(MissionDef)
		{
			if(KismetMaps.Find(MissionDef.MapNames[0]) != INDEX_NONE)
			{
				ParcelManager.TacticalMissionManager.ActiveMission = MissionDef;
				break;
			}
		}

		// Add a quest item in case the mission needs one. we don't care which one, just grab the first
		foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(ItemTemplate, none)
		{
			QuestItemTemplate = X2QuestItemTemplate(ItemTemplate);

			if(QuestItemTemplate != none)
			{
				ParcelManager.TacticalMissionManager.MissionQuestItemTemplate = QuestItemTemplate.DataName;
				break;
			}
		}
		
		// create a fake objective parcel at the origin
		FakeObjectiveParcel = Spawn(class'XComParcel');
		ParcelManager.ObjectiveParcel = FakeObjectiveParcel;
	}

	simulated function GenerateMap()
	{
		local int ProcLevelSeed;
		local XComGameState_BattleData BattleData;
		local bool bSeamlessTraveled;

		// if we're running PIE, kick that off.  Don't bother with the data that is in the battle data
		if(class'WorldInfo'.static.IsPlayInEditor())
		{
			ParcelManager.InitPlacedEvacZone(); // in case we are testing placed evac zones in this map
			SetupPIEGame();
			return;
		}
		
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		bSeamlessTraveled = `XCOMGAME.m_bSeamlessTraveled;

		//Check whether the map has been generated already
		if(BattleData.MapData.ParcelData.Length > 0 && !bSeamlessTraveled)
		{
			// this data has a prebuilt map, load it
			LoadMap();
		}
		else if(BattleData.MapData.PlotMapName != "")
		{			
			// create a new procedural map 
			ProcLevelSeed = BattleData.iLevelSeed;

			//Unless we are using seamless travel, generate map requires there to be NO streaming maps when it starts
			if(!bSeamlessTraveled)
			{
				if(bShowDropshipInteriorWhileGeneratingMap)
				{	 
					ParcelManager.bBlockingLoadParcels = false;
				}
				else
				{
					`MAPS.RemoveAllStreamingMaps();
				}
				
				ParcelManager.GenerateMap(ProcLevelSeed);
			}
			else
			{
				//Make sure that we don't flush async loading, or else the transition map will hitch.
				ParcelManager.bBlockingLoadParcels = false; 

				//The first part of map generation has already happened inside the dropship. Now do the second part
				ParcelManager.GenerateMapUpdatePhase2();
			}

			ReleaseScriptLog( "Tactical Load Debug: Generating Map" );
		}
		else // static, non-procedural map (such as the obstacle course)
		{
			`log("X2TacticalGameRuleset: RebuildWorldData");
			ParcelManager.InitPlacedEvacZone(); // in case we are testing placed evac zones in this map
			ReleaseScriptLog( "Tactical Load Debug: Static Map - Generate" );
		}
	}

	function bool ShowDropshipInterior()
	{
		local XComGameState_BattleData BattleData;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_MissionSite MissionState;
		local bool bValidMapLaunchType;
		local bool bSkyrangerTravel;
		local bool bLoadingMoviePlaying;

		if (class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode( ))
			return false;

		XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if(XComHQ != none)
		{
			MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
		}

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		//Not TQL, test map, PIE, etc.
		bValidMapLaunchType = `XENGINE.IsSinglePlayerGame() && BattleData.MapData.PlotMapName != "" && BattleData.MapData.ParcelData.Length == 0;

		bLoadingMoviePlaying = class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsMoviePlaying("CIN_XP_UI_LogoSpin");

		//True if we didn't seamless travel here, and the mission type wanted a skyranger travel ( ie. no avenger defense or other special mission type ), and if no loading movie is playing
		bSkyrangerTravel = !`XCOMGAME.m_bSeamlessTraveled && (MissionState == None || MissionState.GetMissionSource().bRequiresSkyrangerTravel) && !bLoadingMoviePlaying;
				
		return bValidMapLaunchType && bSkyrangerTravel && !BattleData.DirectTransferInfo.IsDirectMissionTransfer;
	}

	simulated function CreateMapActorGameStates()
	{
		local XComDestructibleActor DestructibleActor;
		local X2WorldNarrativeActor NarrativeActor;
		local X2SquadVisiblePoint SquadVisiblePoint;

		local XComGameState StartState;
		local int StartStateIndex;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		foreach `BATTLE.AllActors(class'XComDestructibleActor', DestructibleActor)
		{
			DestructibleActor.GetState(StartState);
		}

		foreach `BATTLE.AllActors(class'X2WorldNarrativeActor', NarrativeActor)
		{
			NarrativeActor.CreateState(StartState);
		}

		foreach `BATTLE.AllActors(class'X2SquadVisiblePoint', SquadVisiblePoint)
		{
			SquadVisiblePoint.CreateState(StartState);
		}
	}

	simulated function BuildVisualizationForStartState()
	{
		local int StartStateIndex;		
		local array<X2Action> NewlyStartedActions;

		StartStateIndex = CachedHistory.FindStartStateIndex();
		//Make sure this is a tactical game start state
		`assert( StartStateIndex > -1 );
		`assert( XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(StartStateIndex).GetContext()) != none );
		
		//Bootstrap the visualization mgr. Enabling processing of new game states, and making sure it knows which state index we are at.
		VisualizationMgr.EnableBuildVisualization();
		VisualizationMgr.SetCurrentHistoryFrame(StartStateIndex);

		//This will set up the visualizers that init the camera, XGBattle, etc.
		VisualizationMgr.BuildVisualizationFrame(StartStateIndex, NewlyStartedActions);
		VisualizationMgr.CheckStartBuildTree();
	}

	simulated function SetupFirstStartTurnSeed()
	{
		local XComGameState_BattleData BattleData;
		
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		if (BattleData.bUseFirstStartTurnSeed)
		{
			class'Engine'.static.GetEngine().SetRandomSeeds(BattleData.iFirstStartTurnSeed);
		}
	}

	simulated function SetupUnits()
	{
		local XComGameState StartState;
		local int StartStateIndex;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();
		
			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		// the xcom squad needs to be initialized before alien spawning
		StartStateInitializeSquads(StartState);

		// only spawn AIs in SinglePlayer...
		if (`XENGINE.IsSinglePlayerGame())
			StartStateSpawnAliens(StartState);

		// Spawn additional units ( such as cosmetic units like the Gremlin )
		StartStateSpawnCosmeticUnits(StartState);

		//Add new game object states to the start state.
		//*************************************************************************	
		StartStateCreateXpManager(StartState);
		StartStateInitializeUnitAbilities(StartState);      //Examine each unit's start state, and add ability state objects as needed
		//*************************************************************************


		// build the initiative order
		BuildInitiativeOrder(StartState);
	}

	//Used by the system if we are coming from strategy and did not use seamless travel ( which handles this internally )
	function MarkPlotUsed()
	{
		local XComGameState_BattleData BattleDataState;

		BattleDataState = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		// notify the deck manager that we have used this plot
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('Plots', BattleDataState.MapData.PlotMapName);
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('PlotTypes', ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName).strType);
	}

	simulated function bool AllowVisualizerSelection()
	{
		return false;
	}

	simulated function ApplyResistancePoliciesToStartState( )
	{
		local XComGameState StartState;
		local int StartStateIndex;
		local XComGameState_HeadquartersResistance ResHQ;
		local array<StateObjectReference> PolicyCards;
		local StateObjectReference PolicyRef;
		local XComGameState_StrategyCard PolicyState;
		local X2StrategyCardTemplate PolicyTemplate;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		ResHQ = XComGameState_HeadquartersResistance( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersResistance' ) );
		PolicyCards = ResHQ.GetAllPlayedCards(true);

		foreach PolicyCards( PolicyRef )
		{
			if (PolicyRef.ObjectID == 0)
				continue;

			PolicyState = XComGameState_StrategyCard( CachedHistory.GetGameStateForObjectID( PolicyRef.ObjectID ) );
			`assert( PolicyState != none );

			PolicyTemplate = PolicyState.GetMyTemplate( );

			if (PolicyTemplate.ModifyTacticalStartStateFn != none)
			{
				PolicyTemplate.ModifyTacticalStartStateFn( StartState );
			}
		}
	}

	// start CHL issue #450
	// added function ApplySitRepEffectsToStartState
	// to give SitReps access to the Tactical StartState
	simulated function ApplySitRepEffectsToStartState()
	{
		local XComGameState StartState;
		local int StartStateIndex;
		local X2SitRepEffect_ModifyTacticalStartState SitRepEffect;
		local XComGameState_BattleData BattleDataState;

		StartState = CachedHistory.GetStartState();
		BattleDataState = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		foreach class'X2SitRepTemplateManager'.static.IterateEffects(class'X2SitRepEffect_ModifyTacticalStartState', SitRepEffect, BattleDataState.ActiveSitReps)
		{
			if (SitRepEffect.ModifyTacticalStartStateFn != none)
			{
				SitRepEffect.ModifyTacticalStartStateFn(StartState);
			}
		}
	}
	// end CHL issue #450

	simulated function ApplyDarkEventsToStartState( )
	{
		local XComGameState StartState;
		local int StartStateIndex;
		local XComGameState_HeadquartersAlien AlienHQ;
		local StateObjectReference EventRef;
		local XComGameState_DarkEvent DarkEventState;
		local X2DarkEventTemplate DarkEventTemplate;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		AlienHQ = XComGameState_HeadquartersAlien(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

		foreach AlienHQ.ActiveDarkEvents( EventRef )
		{
			DarkEventState = XComGameState_DarkEvent(CachedHistory.GetGameStateForObjectID( EventRef.ObjectID ));
			`assert( DarkEventState != none );

			DarkEventTemplate = DarkEventState.GetMyTemplate();

			if (DarkEventTemplate.ModifyTacticalStartStateFn != none)
			{
				DarkEventTemplate.ModifyTacticalStartStateFn( StartState );
			}
		}
	}

	simulated function bool ShowUnitFlags( )
	{
		return false;
	}

	private simulated function OnStudioLoaded( )
	{
		bStudioReady = true;
	}

	simulated function RequestHeadshots( )
	{
		local XComGameState_Unit UnitState;

		m_HeadshotsPending = 0;

		foreach CachedHistory.IterateByClassType( class'XComGameState_Unit', UnitState )
		{
			if (UnitState.GetTeam() != eTeam_XCom) // only headshots of XCom
				continue;
			if (UnitState.GetMyTemplate().bIsCosmetic) // no Gremlins
				continue;
			if (UnitState.bMissionProvided) // no VIPs
				continue;

			m_kPhotoboothAutoGen.AddHeadShotRequest( UnitState.GetReference( ), 512, 512, HeadshotReceived );
			++m_HeadshotsPending;
		}

		m_kPhotoboothAutoGen.RequestPhotos();
	}

Begin:
	`SETLOC("Start of Begin Block");

	if (class'XComEngine'.static.IsAnyMoviePlaying())
	{
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
	}

	//Wait for the UI to initialize
	`assert(Pres != none); //Reaching this point without a valid presentation layer is an error
	
	`MAPS.LoadTimer_Start();
	//`log("Starting level load at" @ LevelLoadStartTime @ "seconds", , 'DevLoad');
	
	// Added for testing with command argument for map name (i.e. X2_ObstacleCourse) otherwise mouse does not get initialized.
	//`ONLINEEVENTMGR.ReadProfileSettings();

	while( Pres.UIIsBusy() )
	{
		Sleep(0.0f);
	}
	
	//Show the soldiers riding to the mission while the map generates
	bShowDropshipInteriorWhileGeneratingMap = ShowDropshipInterior();
	if(bShowDropshipInteriorWhileGeneratingMap)
	{
		class'CHHelpers'.static.UpdateTransitionMap(); // Issue #388

		`MAPS.AddStreamingMap(`MAPS.GetTransitionMap(), DropshipLocation, DropshipRotation, false);
		while(!`MAPS.IsStreamingComplete())
		{
			sleep(0.0f);
		}

		MarkPlotUsed();

		`log("CreateTacticalGame: Dropship loaded");
		
		XComPlayerController(Pres.Owner).NotifyStartTacticalSeamlessLoad();		
		//Stop any movies playing. HideLoadingScreen also re-enables rendering
		Pres.UIStopMovie();
		Pres.HideLoadingScreen();
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);

		WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

		//Let the dropship settle in
		Sleep(1.0f);

		WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(FALSE);

		`log("CreateTacticalGame: CIN_XP_UI_LogoSpin started");
		`XENGINE.PlayMovie(true, "CIN_XP_UI_LogoSpin.bk2");
	}
	else
	{
		//Will stop the HQ launch music if it is still playing ( which it should be, if we seamless traveled )
		`XTACTICALSOUNDMGR.StopHQMusicEvent();
	}

	//Generate the map and wait for it to complete
	GenerateMap();

	// Still rebuild the world data even if it is a static map except we need to wait for all the blueprints to resolve before
	// we build the world data.  In the case of a valid plot map, the parcel manager will build the world data at a step before returning
	// true from IsGeneratingMap
	if (XComGameState_BattleData( CachedHistory.GetGameStateForObjectID( CachedBattleDataRef.ObjectID ) ).MapData.PlotMapName == "")
	{
		while (!`MAPS.IsStreamingComplete( ))
		{
			sleep( 0.0f );
		}

		ParcelManager.RebuildWorldData( );
	}

	while( ParcelManager.IsGeneratingMap() )
	{
		if (bShowDropshipInteriorWhileGeneratingMap && ParcelManager.GeneratingMapPhase > 1 && class'XComEngine'.static.IsAnyMoviePlaying())
		{			
			`log("CreateTacticalGame: Map phase 2 started, clearing loading movie");
			`XENGINE.StopCurrentMovie();
			Sleep(0.5f); //Scene needs to initialize after the movie is stopped.
			class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false);
		}		

		Sleep(0.0f);
	}

	ReleaseScriptLog("X2TacticalGameRuleset: Finished Parcel Map Generation");

	if( `XENGINE.IsSinglePlayerGame() )
	{
		AddDropshipStreamingCinematicMaps();
	}

	//Wait for the drop ship and all other maps to stream in
	while (!`MAPS.IsStreamingComplete())
	{
		sleep(0.0f);
	}

	ReleaseScriptLog("X2TacticalGameRuleset: Finished Map Streaming");

	// Start Issue #720
	// Create the manager here since
	// (1) we will 100% need it
	// (2) better it happens during a loading screen/transion map than when it's time for first projectile to start its death countdown
	/// HL-Docs: ref:ProjectilePerformanceDrain
	class'CHEmitterPoolDelayedReturner'.static.GetSingleton();
	// End Issue #720

	if(bShowDropshipInteriorWhileGeneratingMap)
	{
		WorldInfo.bContinueToSeamlessTravelDestination = false;
		XComPlayerController(Pres.Owner).NotifyLoadedDestinationMap('');
		`log("CreateTacticalGame: Waiting for player confirmation");
		while(!WorldInfo.bContinueToSeamlessTravelDestination)
		{
			Sleep(0.0f);
		}

		`log("CreateTacticalGame: Starting tactical battle");

		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);		

		`MAPS.ClearPreloadedLevels();
		`MAPS.RemoveStreamingMapByName(`MAPS.GetTransitionMap(), false);
		`MAPS.ResetTransitionMap(); // Issue #388 -- revert transition map changes
	}

	TacticalStreamingMapsPostLoad();

	if( XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl() != none )
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();
		
		bRain = CanToggleWetness();
		class'XComWeatherControl'.static.SetAllAsWet(bRain);
	}
	else
	{
		bRain = false;
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (WorldInfo.m_kDominantDirectionalLight != none &&
		WorldInfo.m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}
	
	InitVolumes();

	WorldInfo.MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	if (XComTacticalController(WorldInfo.GetALocalPlayerController()).TerrainCaptureControl() != none)
	{
		XComTacticalController(WorldInfo.GetALocalPlayerController()).TerrainCaptureControl().ResetCapturesNative();
	}

	class'XComEngine'.static.ConsolidateVisGroupData(); 

	class'XComEngine'.static.TriggerTileDestruction();

	class'XComEngine'.static.AddEffectsToStartState();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

	ReleaseScriptLog("X2TacticalGameRuleset: Finished Generating Map");

	ApplyResistancePoliciesToStartState( );
	ApplySitRepEffectsToStartState();  // CHL issue #450
	ApplyDarkEventsToStartState( );

	//Position units already in the start state
	//*************************************************************************
	StartStatePositionUnits();
	//*************************************************************************

	// "spawn"/prespawn player and ai units
	SetupUnits();

	// load cinematic maps for units
	AddCharacterStreamingCinematicMaps();

	//Wait for any loading movie to finish playing
	while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		Sleep(0.0f);
	}

	// Add the default camera
	AddDefaultPathingCamera();

	if (UnitRadiusManager != none)
	{
		UnitRadiusManager.SetEnabled( true );
	}

	//Create game states for actors in the map
	CreateMapActorGameStates();

	// Create all soldier portraits right now for ladder mode
	if (CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress', true ) != none)
	{
		//`XENGINE.PlayMovie( true, "CIN_XP_UI_LogoSpin.bk2" );

		bStudioReady = false;

		m_kTacticalLocation = new class'X2Photobooth_TacticalLocationController';
		m_kTacticalLocation.Init( OnStudioLoaded );

		while (!bStudioReady)
		{
			Sleep( 0.0f );
		}

		m_kPhotoboothAutoGen = Spawn(class'X2Photobooth_StrategyAutoGen', self);
		m_kPhotoboothAutoGen.bLadderMode = true;
		m_kPhotoboothAutoGen.Init( );

		`log("X2TacticalGameRuleset: Starting Headshot Captures", , 'XCom_GameStates');

		RequestHeadshots( );

		//Unveil scene - should be playing an intro if there is one
		if (class'XComEngine'.static.IsLoadingMoviePlaying())
		{
			Pres.HideLoadingScreen();
		}

		//`XENGINE.StopCurrentMovie( );
	}
	else
	{
		//Unveil scene - should be playing an intro if there is one
		if (class'XComEngine'.static.IsLoadingMoviePlaying())
		{
			Pres.HideLoadingScreen();
		}
	}

	//Wait for environmental captures to complete now that we have hidden any loading screens ( the loading screen will inhibit scene capture )
	//while (!WorldInfo.MyLocalEnvMapManager.AreCapturesComplete())
	//{
	//	Sleep(0.0f);
	//}

	//The dropship intro will now start, stop the HQ music ( ready for battle music )
	if (bShowDropshipInteriorWhileGeneratingMap)
	{
		`XTACTICALSOUNDMGR.StopHQMusicEvent();
	}

	//Visualize the start state - in the most basic case this will create pawns, etc. and position the camera.
	BuildVisualizationForStartState();
	
	`MAPS.LoadTimer_Stop();
	//`log("Ending level load at " @ class'Engine'.static.GetEngine().seconds @ "s. Loading took" @ (WorldInfo.RealTimeSeconds - LevelLoadStartTime) @ "s.", , 'DevLoad');

	//Let the visualization blocks accumulated so far run their course ( which may include intro movies, etc. ) before continuing. 
	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//This needs to be called after CreateMapActorGameStates, to make sure Destructibles have their state objects ready.
	`PRES.m_kUnitFlagManager.AddFlags();

	//Bootstrap the visibility mgr with the start state
	VisibilityMgr.InitialUpdate();

	// For things like Challenge Mode that require a level seed for all the level generation and a differing seed for each player that enters, set the 
	// specific seed for all random actions hereafter. Additionally, do this before the BeginState_rulesAuthority submits its state context so that the
	// seed is baked into the first context.
	SetupFirstStartTurnSeed();

	// remove the lock that was added in CreateTacticalGame.BeginState
	//	the history is fair game again...
	CachedHistory.RemoveHistoryLock();

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while entering a tactical battle! This WILL result in buggy behavior during game play continued with this save.");

	//After this point, the start state is committed
	BeginState_RulesAuthority(none);

	//This is guarded internally from redundantly starting. Various different ways of entering the mission may have called this earlier.
	`XTACTICALSOUNDMGR.StartAllAmbience();

	//Initialization continues in the PostCreateTacticalGame state.
	//Further changes are not part of the Tactical Game start state.	

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This state is entered if the tactical game being played is resuming a previously saved game state. LoadTacticalGame handles resuming from a previous
/// game state as well initiating a replay of previous moves.
/// </summary>
simulated state LoadTacticalGame
{	
	simulated event BeginState(name PreviousStateName)
	{
		local X2EventManager EventManager;
		local Object ThisObject;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData Timer;
		local XComGameState_BattleData BattleData;

		`SETLOC("BeginState");

		EventManager = `XEVENTMGR;
		ThisObject = self;

		EventManager.RegisterForEvent(ThisObject, 'UnitMoveFinished', HandleNeutralReactionsOnMovement, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'AbilityActivated', HandleNeutralReactionsOnAbilityActivated, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'UnitDied', HandleUnitDiedCache, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'TileDataChanged', HandleAdditionalFalling, ELD_OnStateSubmitted);

		// allow templated event handlers to register themselves
		class'X2EventListenerTemplateManager'.static.RegisterTacticalListeners();

		// update our templates with the correct difficulty modifiers
		class'X2DataTemplateManager'.static.RebuildAllTemplateGameCaches();

		bTacticalGameInPlay = true;
		bProcessingLoad = true;

		// Technically a player can't ever actually load a challenge mode save so resetting the timer shouldn't be exploitable.
		// However, devs should/need to be able to load a challenge error report save and in order for those saves to be useful,
		// we need to reset the timer.  Otherwise loading the error save immediately triggers the 'timer expires' end condition.
		ChallengeData = XComGameState_ChallengeData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true));
		if (ChallengeData != none)
		{
			Timer = XComGameState_TimerData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
			Timer.ResetTimer();
		}

		// if we're playing a skirmish map, don't do encounter vo
		BattleData = XComGameState_BattleData( CachedHistory.GetGameStateForObjectID( CachedBattleDataRef.ObjectID ) );
		if (BattleData.m_strDesc == "Skirmish Mode")
		{
			`CHEATMGR.DisableFirstEncounterVO = true;
		}
	}

	function BuildVisualizationForStartState()
	{
		local int StartStateIndex;		
		local array<X2Action> NewlyStartedActions;

		VisualizationMgr = `XCOMVISUALIZATIONMGR;

		StartStateIndex = CachedHistory.FindStartStateIndex();
		//Make sure this is a tactical game start state
		`assert( StartStateIndex > -1 );
		`assert( XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(StartStateIndex).GetContext()) != none );

		//This will set up the visualizers that init the camera, XGBattle, etc.
		VisualizationMgr.BuildVisualizationFrame(StartStateIndex, NewlyStartedActions);
		VisualizationMgr.CheckStartBuildTree();
	}

	//Set up the visualization mgr to run from the correct frame
	function SyncVisualizationMgr()
	{
		local XComGameState FullGameState;
		local int StartStateIndex;
		local array<X2Action> NewlyStartedActions;

		if( `ONLINEEVENTMGR.bInitiateReplayAfterLoad )
		{
			//Start the replay from the most recent start state
			StartStateIndex = CachedHistory.FindStartStateIndex();
			FullGameState = CachedHistory.GetGameStateFromHistory(StartStateIndex, eReturnType_Copy, false);

			// init the UI before StartReplay() because if its the Tutorial, Start replay will hide the UI which needs to have been created already
			XComPlayerController(GetALocalPlayerController()).Pres.UIReplayScreen(`ONLINEEVENTMGR.m_sReplayUserID);

			XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StartReplay(StartStateIndex);	

			`ONLINEEVENTMGR.bInitiateReplayAfterLoad = false;
		}
		else
		{
			//Continue the playthrough from the latest frame
			FullGameState = CachedHistory.GetGameStateFromHistory(-1, eReturnType_Copy, false);


		}

		VisualizationMgr.SetCurrentHistoryFrame(FullGameState.HistoryIndex);
		if( !XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay )
		{
			//If we are loading a saved game to play, sync all the visualizers to the current state and enable passive visualizer building
			VisualizationMgr.EnableBuildVisualization();		
			VisualizationMgr.OnJumpForwardInHistory();
			VisualizationMgr.BuildVisualizationFrame(FullGameState.HistoryIndex, NewlyStartedActions, true);
			VisualizationMgr.CheckStartBuildTree();
		}
	}

	simulated function SetupFirstStartTurnSeed()
	{
		local XComGameState_BattleData BattleData;

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		if (BattleData.bUseFirstStartTurnSeed)
		{
			class'Engine'.static.GetEngine().SetRandomSeeds(BattleData.iFirstStartTurnSeed);
		}
	}

	function SetupDeadUnitCache()
	{
		local XComGameState_Unit Unit;
		local XComGameState FullGameState;
		local int CurrentStateIndex;

		CachedDeadUnits.Length = 0;

		CurrentStateIndex = CachedHistory.GetCurrentHistoryIndex();
		FullGameState = CachedHistory.GetGameStateFromHistory(CurrentStateIndex, eReturnType_Copy, false);

		foreach FullGameState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			if( Unit.IsDead() )
			{
				CachedDeadUnits.AddItem(Unit.GetReference());
			}
		}
	}

	// legacy save game support to rebuild the initiative order using the new model
	function RebuildInitiativeOrderIfNeccessary()
	{
		local XComGameState_BattleData BattleData;
		local StateObjectReference InitiativeRef;
		local bool AnyGroupsFound;
		local XComGameState NewGameState;
		local XComGameState_Player PlayerState;
		local XComGameState_HeadquartersXCom XComHQ;
		local StateObjectReference SquadMemberRef;
		local XComGameState_AIGroup PlayerGroup;


		AnyGroupsFound = false;
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		foreach BattleData.PlayerTurnOrder(InitiativeRef)
		{
			if( XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(InitiativeRef.ObjectID)) != None )
			{
				AnyGroupsFound = true;
				break;
			}
		}

		// if no groups were found then this save game has not yet built initiative (it is a legacy save)
		// in this case, we need to build a partial representation of the start state as needed to rebuild initiative
		if( !AnyGroupsFound )
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rebuilding Initiative Order");

			PlayerGroup = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
			PlayerGroup.bProcessedScamper = true;

			XComHQ = `XCOMHQ;

			foreach XComHQ.Squad(SquadMemberRef)
			{
				PlayerGroup.AddUnitToGroup(SquadMemberRef.ObjectID, NewGameState);
			}

			foreach CachedHistory.IterateByClassType(class'XComGameState_Player', PlayerState)
			{
				PlayerState = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', PlayerState.ObjectID));
			}

			// add all groups who should be in initiative
			foreach CachedHistory.IterateByClassType(class'XComGameState_AIGroup', PlayerGroup)
			{
				PlayerGroup = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', PlayerGroup.ObjectID));

				foreach PlayerGroup.m_arrMembers(SquadMemberRef)
				{
					PlayerGroup.AddUnitToGroup(SquadMemberRef.ObjectID, NewGameState);
				}
			}


			BuildInitiativeOrder(NewGameState);
			SubmitGameState(NewGameState);
		}
	}

	simulated function CreateMapActorGameStates()
	{
		local XComDestructibleActor DestructibleActor;
		local XComGameState_CampaignSettings SettingsState;
		local XComGameState StartState;
		local int StartStateIndex;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		// only make start states for destructible actors that have not been created by the load
		//	this can happen if parcels/doors change between when the save was created and when the save was loaded
		foreach `BATTLE.AllActors(class'XComDestructibleActor', DestructibleActor)
		{
			DestructibleActor.GetState(StartState);
		}

		SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		`XENGINE.m_kPhotoManager.FillPropagandaTextureArray(ePWM_Campaign, SettingsState.GameIndex);
	}

	//Wait for ragdolls to finish moving
	function bool AnyUnitsRagdolling()
	{
		local XComUnitPawn UnitPawn;

		foreach AllActors(class'XComUnitPawn', UnitPawn)
		{
			if( UnitPawn.IsInState('RagdollBlend') )
			{
				return true;
			}
		}

		return false;
	}

	simulated function bool AllowVisualizerSelection()
	{
		return false;
	}

	function RefreshEventManagerUnitRegistration()
	{
		local XComGameState_Unit UnitState;

		foreach CachedHistory.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			UnitState.RefreshEventManagerRegistrationOnLoad();
		}
	}

	simulated function bool ShowUnitFlags( )
	{
		return false;
	}

Begin:
	`SETLOC("Start of Begin Block");

	`MAPS.LoadTimer_Start();
	`MAPS.RemoveStreamingMapByName(`MAPS.GetTransitionMap(), false);

	`CURSOR.ResetPlotValueCache( );

	LoadMap();

	AddCharacterStreamingCinematicMaps(true);

	while( ParcelManager.IsGeneratingMap() )
	{
		Sleep(0.0f);
	}

	TacticalStreamingMapsPostLoad();

	// remove all the replacement actors that have been replaced
	`SPAWNMGR.CleanupReplacementActorsOnLevelLoad();

	// Cleanup may have made blueprint requests, wait for those
	while (!`MAPS.IsStreamingComplete())
	{
		sleep(0.0f);
	}

	if(XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl() != none)
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();

		bRain = CanToggleWetness();
		class'XComWeatherControl'.static.SetAllAsWet(bRain);
	}
	else
	{
		bRain = false;
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (WorldInfo.m_kDominantDirectionalLight != none &&
		WorldInfo.m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}

	InitVolumes();

	WorldInfo.MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	if (XComTacticalController(WorldInfo.GetALocalPlayerController()).TerrainCaptureControl() != none)
	{
		XComTacticalController(WorldInfo.GetALocalPlayerController()).TerrainCaptureControl().ResetCapturesNative();
	}

	class'XComEngine'.static.ConsolidateVisGroupData();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	// Clear stale data from previous map that could affect placement of reinforcements in this game.
	`SPAWNMGR.ClearCachedFireTiles();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

	RefreshEventManagerUnitRegistration();

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while loading a saved game! This WILL result in buggy behavior during game play continued with this save.");

	//If the load occurred from UnitActions, mark the ruleset as loading which will instigate the loading procedure for 
	//mid-UnitAction save (suppresses player turn events). This will be false for MP loads, and true for singleplayer saves.
	// raasland - except it wasn't being set to true for SP and breaking turn start tick effects
	bLoadingSavedGame = true;

	//Wait for the presentation layer to be ready
	while(Pres.UIIsBusy())
	{
		Sleep(0.0f);
	}
	
	// Add the default camera
	AddDefaultPathingCamera( );

	Sleep(0.1f);

	//Create game states for actors in the map
	CreateMapActorGameStates();

	CachedHistory.AddHistoryLock( ); // Lock the history here, because there should be no gamestate submissions while doing the initial sync

	BuildVisualizationForStartState();

	`MAPS.LoadTimer_Stop();

	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//Sync visualizers to the proper state ( variable depending on whether we are performing a replay or loading a save game to play )
	SyncVisualizationMgr();

	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	class'SeqEvent_OnPlayerLoadedFromSave'.static.FireEvent( );

	CachedHistory.RemoveHistoryLock( ); // initial sync is done, unlock the history for playing

	//Wait for any units that are ragdolling to stop
	while(AnyUnitsRagdolling())
	{
		sleep(0.0f);
	}

	//This needs to be called after CreateMapActorGameStates, to make sure Destructibles have their state objects ready.
	Pres.m_kUnitFlagManager.AddFlags();

	//Flush cached visibility data now that the visualizers are correct for all the viewers and the cached visibility system uses visualizers as its inputs
	`XWORLD.FlushCachedVisibility();
	`XWORLD.ForceUpdateAllFOWViewers();

	//Flush cached unit rules, because they can be affected by not having visualizers ready (pre-SyncVisualizationMgr)
	UnitsCache.Length = 0;

	if (UnitRadiusManager != none)
	{
		UnitRadiusManager.SetEnabled( true );
	}

	CachedHistory.CheckNoPendingGameStates();

	SetupDeadUnitCache();

	//Signal that we are done
	bProcessingLoad = false; 

	RebuildInitiativeOrderIfNeccessary();

	// Now that the game is in the updated state, we can build the initial game visibility data
	VisibilityMgr.InitialUpdate();
	VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle(); //Force all visualizers to update their visualization state

	Pres.m_kTacticalHUD.ForceUpdate(-1);

	if (`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		SetupFirstStartTurnSeed();
	}

	//Achievement event listeners do not survive the serialization process. Adding them here.
	`XACHIEVEMENT_TRACKER.Init();

	if(`REPLAY.bInTutorial)
	{
		// Force an update of the save game list, otherwise our tutorial replay save is shown in the load/save screen
		`ONLINEEVENTMGR.UpdateSaveGameList();

		//Allow the user to skip the movie now that the major work / setup is done
		`XENGINE.SetAllowMovieInput(true);

		while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
		{
			Sleep(0.0f);
		}
		
		TutorialIntro = XComNarrativeMoment(`CONTENT.RequestGameArchetype("X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_PostIntro"));
		Pres.UINarrative(TutorialIntro);		
	}

	//Start Issue #647
	UpdateDLCLoadingTacticalGame();
	//End Issue #647

	// Start Issue #720
	// Create the manager here since
	// (1) we will 100% need it
	// (2) better it happens during a loading screen/transion map than when it's time for first projectile to start its death countdown
	/// HL-Docs: ref:ProjectilePerformanceDrain
	class'CHEmitterPoolDelayedReturner'.static.GetSingleton();
	// End Issue #720

	//Movie handline - for both the tutorial and normal loading
	while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		Sleep(0.0f);
	}

	if(class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		ReleaseScriptLog( "Tactical Load Debug: Detected loading movie" );

		//Set the screen to black - when the loading move is stopped the renderer and game will be initializing lots of structures so is not quite ready
		WorldInfo.GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
		Pres.HideLoadingScreen();		

		ReleaseScriptLog( "Tactical Load Debug: Requested loading movie stop" );

		//Allow the game time to finish setting up following the loading screen being popped. Among other things, this lets ragdoll rigid bodies finish moving.
		Sleep(4.0f);
	}

	ReleaseScriptLog( "Tactical Load Debug: Post loading movie check" );

	// once all loading and intro screens clear, we can start the actual tutorial
	if(`REPLAY.bInTutorial)
	{
		`TUTORIAL.StartDemoSequenceDeferred();
	}
	
	//Clear the camera fade if it is still set
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(false, , , 1.0f);	
	`XTACTICALSOUNDMGR.StartAllAmbience();

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

// hacky function to get a few script logs that are needed for a low repro bug with tactical load
static native function ReleaseScriptLog( string log );

private simulated native function PostCreateTacticalModifyKismetVariables_Internal(XComGameState NewGameState);
private simulated native function SecondWaveModifyKismetVariables_Internal(XComGameState NewGameState, float Scalar);

/// <summary>
/// This state is entered after CreateTacticalGame, to handle any manipulations that are not rolled into the start state.
/// It can be entered after LoadTacticalGame as well, if needed (i.e. if we're loading to a start state).
/// </summary>
simulated state PostCreateTacticalGame
{
	simulated function StartStateCheckAndBattleDataCleanup()
	{
		local XComGameState_BattleData BattleData;
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		if ((BattleData == none) ||
			(BattleData != none &&
			BattleData.bIntendedForReloadLevel == false))
			`assert( CachedHistory.GetStartState() == none );

			if (BattleData != none)
			{
				BattleData.bIntendedForReloadLevel = false;
			}
	}

	simulated function BeginState(name PreviousStateName)
	{
		`SETLOC("BeginState");
	}

	simulated event EndState(Name NextStateName)
	{
		VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle(); //Force all visualizers to update their visualization state
	}

	simulated function bool AllowVisualizerSelection()
	{
		return false;
	}

	simulated function PostCreateTacticalModifyKismetVariables( )
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;

		History = `XCOMHISTORY;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("PostCreateTacticalGame::ModifyKismetVariables");
		PostCreateTacticalModifyKismetVariables_Internal( NewGameState );

		if(NewGameState.GetNumGameStateObjects() > 0)
		{
			SubmitGameState(NewGameState);
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}

	simulated function SecondWaveModifyKismetVariables( )
	{
		local XComGameStateHistory History;
		local XComGameState NewGameState;
		local float TotalScalar;

		TotalScalar = 0;

		if (`SecondWaveEnabled('ExtendedMissionTimers') && (SecondWaveExtendedTimerScalar > 0))
			TotalScalar += SecondWaveExtendedTimerScalar;

		if (`SecondWaveEnabled('BetaStrike') && (SecondWaveBetaStrikeTimerScalar > 0))
			TotalScalar += SecondWaveBetaStrikeTimerScalar;

		if (TotalScalar <= 0)
			return;

		History = `XCOMHISTORY;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("PostCreateTacticalGame::SecondWaveModifyKismetVariables");
		SecondWaveModifyKismetVariables_Internal( NewGameState, TotalScalar );

		if(NewGameState.GetNumGameStateObjects() > 0)
		{
			SubmitGameState(NewGameState);
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}

	simulated function bool ShowUnitFlags( )
	{
		return false;
	}

Begin:
	`SETLOC("Start of Begin Block");

	//Posts a game state updating all state objects that they are in play
	BeginTacticalPlay();

	//Let kismet know everything is ready
	`XCOMGRI.DoRemoteEvent('XGBattle_Running_BeginBlockFinished');

	`CURSOR.ResetPlotValueCache( );

	CachedHistory.CheckNoPendingGameStates();

	// immediately before running kismet, allow sitreps to modify values on the kismet canvas
	PostCreateTacticalModifyKismetVariables( );
	class'X2SitRepEffect_ModifyKismetVariable'.static.ModifyKismetVariables();
	SecondWaveModifyKismetVariables( );

	// kick off the mission intro kismet, and wait for it to complete all latent actions
	WorldInfo.TriggerGlobalEventClass(class'SeqEvent_OnTacticalMissionStartBlocking', WorldInfo);


	while (WaitingForVisualizer())
	{
		sleep(0.0);
	}

	// set up start of match special conditions, including squad concealment
	ApplyStartOfMatchConditions();

	// kick off the gameplay start kismet, do not wait for it to complete latent actions
	WorldInfo.TriggerGlobalEventClass(class'SeqEvent_OnTacticalMissionStartNonBlocking', WorldInfo);

	StartStateCheckAndBattleDataCleanup();

	// give the player a few seconds to get adjusted to the level
	Sleep(0.5f);

	// Catch all screen fade that should make sure that the camera fade is lifted at this point. Normally done as part of the intro sequence above in the
	// visualizer wait loop
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(false, , , 1.0f);

	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This state is entered when creating a challenge mission. Setup handles creating scenario
/// specific game states, processing any scenario kismet logic, etc.
/// </summary>
simulated state CreateChallengeGame
{
	simulated event BeginState(name PreviousStateName)
	{
		local X2EventManager EventManager;
		local Object ThisObject;

		`SETLOC("BeginState");

		// the start state has been added by this point
		//	nothing in this state should be adding anything that is not added to the start state itself
		CachedHistory.AddHistoryLock();

		EventManager = `XEVENTMGR;
			ThisObject = self;

		EventManager.RegisterForEvent(ThisObject, 'UnitMoveFinished', HandleNeutralReactionsOnMovement, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'AbilityActivated', HandleNeutralReactionsOnAbilityActivated, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'UnitDied', HandleUnitDiedCache, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'TileDataChanged', HandleAdditionalFalling, ELD_OnStateSubmitted);

		// allow templated event handlers to register themselves
		class'X2EventListenerTemplateManager'.static.RegisterTacticalListeners();

		SetUnitsForMatinee();
	}

	simulated event EndState(Name NextStateName)
	{
		VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle(); //Force all visualizers to update their visualization state
	}

	simulated function SetUnitsForMatinee()
	{
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_Unit Unit;
		local XComGameState StartState;

		StartState = CachedHistory.GetStartState();
		XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(StartState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.Squad.Length = 0;
		foreach StartState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			if ((Unit.GetTeam() == eTeam_XCom) && (!Unit.GetMyTemplate().bIsCosmetic))
			{
				XComHQ.Squad.AddItem(Unit.GetReference());
			}
		}
	}

	simulated function BuildVisualizationForStartState()
	{
		local int StartStateIndex;
		local array<X2Action> NewlyStartedActions;

		StartStateIndex = CachedHistory.FindStartStateIndex();
		//Make sure this is a tactical game start state
		`assert( StartStateIndex > -1 );
		`assert( XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(StartStateIndex).GetContext()) != none );

		//Bootstrap the visualization mgr. Enabling processing of new game states, and making sure it knows which state index we are at.
		VisualizationMgr.EnableBuildVisualization();
		VisualizationMgr.SetCurrentHistoryFrame(StartStateIndex);

		//This will set up the visualizers that init the camera, XGBattle, etc.
		VisualizationMgr.BuildVisualizationFrame(StartStateIndex, NewlyStartedActions);
		VisualizationMgr.CheckStartBuildTree();
	}

	simulated function SetupFirstStartTurnSeed()
	{
		local XComGameState_BattleData BattleData;

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		if (BattleData.bUseFirstStartTurnSeed)
		{
			class'Engine'.static.GetEngine().SetRandomSeeds(BattleData.iFirstStartTurnSeed);
		}
	}

	simulated function GenerateMap()
	{
		local int ProcLevelSeed;
		local XComGameState_BattleData BattleData;
		local bool bSeamlessTraveled;

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		bSeamlessTraveled = `XCOMGAME.m_bSeamlessTraveled;

		//Check whether the map has been generated already
		if (BattleData.MapData.ParcelData.Length > 0 && !bSeamlessTraveled)
		{
			// this data has a prebuilt map, load it
			LoadMap();
		}
		else if (BattleData.MapData.PlotMapName != "")
		{
			// create a new procedural map 
			ProcLevelSeed = BattleData.iLevelSeed;

			//Unless we are using seamless travel, generate map requires there to be NO streaming maps when it starts
			if (!bSeamlessTraveled)
			{
				if (bShowDropshipInteriorWhileGeneratingMap)
				{
					ParcelManager.bBlockingLoadParcels = false;
				}
				else
				{
					`MAPS.RemoveAllStreamingMaps();
				}

				ParcelManager.GenerateMap(ProcLevelSeed);
			}
			else
			{
				//Make sure that we don't flush async loading, or else the transition map will hitch.
				ParcelManager.bBlockingLoadParcels = false;

				//The first part of map generation has already happened inside the dropship. Now do the second part
				ParcelManager.GenerateMapUpdatePhase2();
			}

			ReleaseScriptLog("Tactical Load Debug: Generating Map");
		}
		else // static, non-procedural map (such as the obstacle course)
		{
			`log("X2TacticalGameRuleset: RebuildWorldData");
			ParcelManager.InitPlacedEvacZone(); // in case we are testing placed evac zones in this map
			ReleaseScriptLog("Tactical Load Debug: Static Map - Generate");
		}
	}

	simulated function bool ShowUnitFlags( )
	{
		return false;
	}

Begin:
	`SETLOC("Start of Begin Block");

	//Wait for the UI to initialize
	`assert(Pres != none); //Reaching this point without a valid presentation layer is an error

	while (Pres.UIIsBusy())
	{
		Sleep(0.0f);
	}

	if (`ONLINEEVENTMGR.bGenerateMapForSkirmish)
	{
		GenerateMap();
		`ONLINEEVENTMGR.bGenerateMapForSkirmish = false;
	}
	else if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		LoadMap();
	}

	// Still rebuild the world data even if it is a static map except we need to wait for all the blueprints to resolve before
	// we build the world data.  In the case of a valid plot map, the parcel manager will build the world data at a step before returning
	// true from IsGeneratingMap
	if (XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID)).MapData.PlotMapName == "")
	{
		while (!`MAPS.IsStreamingComplete())
		{
			sleep(0.0f);
		}

		ParcelManager.RebuildWorldData();
	}

	while (ParcelManager.IsGeneratingMap())
	{
		Sleep(0.0f);
	}

	// remove all the replacement actors that have been replaced
	`SPAWNMGR.CleanupReplacementActorsOnLevelLoad();

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		AddDropshipStreamingCinematicMaps();
	}

	//Wait for the drop ship and all other maps to stream in
	while (!`MAPS.IsStreamingComplete())
	{
		sleep(0.0f);
	}

	if(XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl() != none)
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();

		bRain = CanToggleWetness();
		class'XComWeatherControl'.static.SetAllAsWet(bRain);
	}
	else
	{
		bRain = false;
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (WorldInfo.m_kDominantDirectionalLight != none &&
		WorldInfo.m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}

	WorldInfo.MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	if (XComTacticalController(WorldInfo.GetALocalPlayerController()).TerrainCaptureControl() != none)
	{
		XComTacticalController(WorldInfo.GetALocalPlayerController()).TerrainCaptureControl().ResetCapturesNative();
	}

	class'XComEngine'.static.ConsolidateVisGroupData();

	class'XComEngine'.static.TriggerTileDestruction();

	class'XComEngine'.static.AddEffectsToStartState();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	`SPAWNMGR.ClearCachedFireTiles();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

	// update the ability states based on the patch-ups that we've done to the gamestate
	if (CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress', true ) != none)
	{
		class'XComGameState_LadderProgress'.static.RefreshAbilities( CachedHistory );
	}

	`log("X2TacticalGameRuleset: Finished Generating Map", , 'XCom_GameStates');

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		// load cinematic maps for units
		AddCharacterStreamingCinematicMaps();
	}

	// Add the default camera
	AddDefaultPathingCamera();

	if (UnitRadiusManager != none)
	{
		UnitRadiusManager.SetEnabled(true);
	}

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		//Visualize the start state - in the most basic case this will create pawns, etc. and position the camera.
		BuildVisualizationForStartState();

		//Let the visualization blocks accumulated so far run their course ( which may include intro movies, etc. ) before continuing. 
		while (WaitingForVisualizer())
		{
			sleep(0.0);
		}

		`PRES.m_kUnitFlagManager.AddFlags();
	}

	//Bootstrap the visibility mgr with the start state
	VisibilityMgr.InitialUpdate();

	// For things like Challenge Mode that require a level seed for all the level generation and a differing seed for each player that enters, set the 
	// specific seed for all random actions hereafter. Additionally, do this before the BeginState_rulesAuthority submits its state context so that the
	// seed is baked into the first context.
	SetupFirstStartTurnSeed();

	// remove the lock that was added in CreateTacticalGame.BeginState
	//	the history is fair game again...
	CachedHistory.RemoveHistoryLock();

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while entering a tactical battle! This WILL result in buggy behavior during game play continued with this save.");

	//After this point, the start state is committed
	BeginState_RulesAuthority(none);

	//Posts a game state updating all state objects that they are in play
	BeginTacticalPlay();

	//Let kismet know everything is ready
	`XCOMGRI.DoRemoteEvent('XGBattle_Running_BeginBlockFinished');

	CachedHistory.CheckNoPendingGameStates();

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		// give the player a few seconds to get adjusted to the level
		sleep(0.5);
	}

	// set up start of match special conditions, including squad concealment
	ApplyStartOfMatchConditions();

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		// an extra couple seconds before we potentially kick off narrative intro VO
		sleep(1.25);
	}

	// Clear any camera fades to black.
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(false, , , 1.0f);

	// kick off the mission intro kismet, and wait for it to complete all latent actions
	WorldInfo.TriggerGlobalEventClass(class'SeqEvent_OnTacticalMissionStartBlocking', WorldInfo);

	while (WaitingForVisualizer())
	{
		sleep(0.0);
	}

	// kick off the gameplay start kismet, do not wait for it to complete latent actions
	WorldInfo.TriggerGlobalEventClass(class'SeqEvent_OnTacticalMissionStartNonBlocking', WorldInfo);

	// Catch all screen fade that should make sure that the camera fade is lifted at this point. Normally done as part of the intro sequence above in the
	// visualizer wait loop
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(false, , , 1.0f);

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This turn phase is entered at the end of the CreateChallengeGame state and waits for the user to confirm the start of the challenge mission.
/// </summary>
simulated state TurnPhase_StartTimer
{
	simulated event BeginState(name PreviousStateName)
	{
		`SETLOC("BeginState");

		if (CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress', true ) == none)
			`PRES.UIChallengeStartTimerMessage();
		else
			`PRES.UILadderStartTimerMessage();
	}

	simulated event EndState(Name NextStateName)
	{
		local XComGameState_TimerData Timer;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState NewGameState;
		
		Timer = XComGameState_TimerData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
		if (Timer != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TurnPhase_StartTimer");
			Timer = XComGameState_TimerData(NewGameState.ModifyStateObject(class'XComGameState_TimerData', Timer.ObjectID));

			if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
			{
				//Reset the timer game state object to the desired time limit and begin the countdown.
				Timer.ResetTimer();
			}

			ChallengeData = XComGameState_ChallengeData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true));
			ChallengeData = XComGameState_ChallengeData(NewGameState.ModifyStateObject(class'XComGameState_ChallengeData', ChallengeData.ObjectID));
			if (ChallengeData != none)
			{
				ChallengeData.SeedData.StartTime.A = Timer.GetUTCTimeInSeconds();
			}

			SubmitGameState(NewGameState);
		}

		`XANALYTICS.Init();

		`ONLINEEVENTMGR.bIsChallengeModeGame = (ChallengeData != none);
	}

	function CheckForAutoGenerateSave()
	{
		local XComOnlineEventMgr EventMgr;
		local XComCheatManager CheatMgr;
		EventMgr = `ONLINEEVENTMGR;
			if (EventMgr.ChallengeModeSeedGenNum > 0)
			{
				CheatMgr = XComCheatManager(GetALocalPlayerController().CheatManager);
				if (CheatMgr != none)
				{
					// Save ...
					CheatMgr.CreateChallengeStart(string(EventMgr.ChallengeModeSeedGenNum));

					// Increment to the next seed
					++EventMgr.ChallengeModeSeedGenNum;

					// Return to Tactical Quick Launch
					ConsoleCommand("open TacticalQuickLaunch");
				}
			}
	}

Begin:
	CheckForAutoGenerateSave();

	while (`PRES.WaitForChallengeAccept())
	{
		sleep(0.0);
	}
	GotoState(GetNextTurnPhase(GetStateName()));
}

function EventListenerReturn OnChallengeObjectiveFailed( Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData )
{
	FailBattle();
	return ELR_InterruptEventAndListeners;
}

/// <summary>
/// This turn phase is entered at the start of each turn and handles any start-of-turn scenario events. Unit/Terrain specific effects occur in subsequent phases.
/// </summary>
simulated state TurnPhase_Begin
{
	simulated event BeginState(name PreviousStateName)
	{
		`SETLOC("BeginState");

		BeginState_RulesAuthority(UpdateAbilityCooldowns);
	}

	simulated function UpdateAbilityCooldowns(XComGameState NewPhaseState)
	{
		local XComGameState_Ability AbilityState, NewAbilityState;
		local XComGameState_Player  PlayerState, NewPlayerState;
		local XComGameState_Unit UnitState, NewUnitState;
		local bool TickCooldown;
		local XComGameState_BattleData BattleData;

		if (!bLoadingSavedGame)
		{
			BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
			BattleData = XComGameState_BattleData(NewPhaseState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
			BattleData.TacticalTurnCount++;

			foreach CachedHistory.IterateByClassType(class'XComGameState_Ability', AbilityState)
			{
				// some units tick their cooldowns per action instead of per turn, skip them.
				UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
				`assert(UnitState != none);
				TickCooldown = AbilityState.iCooldown > 0 && !UnitState.GetMyTemplate().bManualCooldownTick;

				if( TickCooldown || AbilityState.TurnsUntilAbilityExpires > 0 )
				{
					NewAbilityState = XComGameState_Ability(NewPhaseState.ModifyStateObject(class'XComGameState_Ability', AbilityState.ObjectID));//Create a new state object on NewPhaseState for AbilityState

					if( TickCooldown )
					{
						NewAbilityState.iCooldown--;
					}

					if( NewAbilityState.TurnsUntilAbilityExpires > 0 )
					{
						NewAbilityState.TurnsUntilAbilityExpires--;
						if( NewAbilityState.TurnsUntilAbilityExpires == 0 )
						{
							NewUnitState = XComGameState_Unit(NewPhaseState.ModifyStateObject(class'XComGameState_Unit', NewAbilityState.OwnerStateObject.ObjectID));
							NewUnitState.Abilities.RemoveItem(NewAbilityState.GetReference());
						}
					}
				}
			}

			foreach CachedHistory.IterateByClassType(class'XComGameState_Player', PlayerState)
			{
				if (PlayerState.HasCooldownAbilities() || PlayerState.SquadCohesion > 0)
				{
					NewPlayerState = XComGameState_Player(NewPhaseState.ModifyStateObject(class'XComGameState_Player', PlayerState.ObjectID));
					NewPlayerState.UpdateCooldownAbilities();
					if (PlayerState.SquadCohesion > 0)
						NewPlayerState.TurnsSinceCohesion++;
				}
			}
		}
	}

Begin:
	`SETLOC("Start of Begin Block");

	CachedHistory.CheckNoPendingGameStates();

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

function UpdateAIActivity(bool bActive)
{
	bAlienActivity = bActive;
}

simulated function bool UnitActionPlayerIsRemote()
{
	local XComGameState_Player PlayerState;
	local XGPlayer Player;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(GetCachedUnitActionPlayerRef().ObjectID));
	if( PlayerState != none )
	{
		Player = XGPlayer(PlayerState.GetVisualizer());
	}

	`assert(PlayerState != none);
	`assert(Player != none);

	return (PlayerState != none) && (Player != none) && Player.IsRemote();
}

function bool RulesetShouldAutosave()
{
	local XComGameState_Player PlayerState;
	local XComGameState_BattleData BattleData;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(GetCachedUnitActionPlayerRef().ObjectID));
	BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if (BattleData.m_strDesc == "BenchmarkTest")
		return false;

	if (CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) != none)
		return false;

	return !bSkipAutosaveAfterLoad && !HasTacticalGameEnded() &&!PlayerState.IsAIPlayer() && !`REPLAY.bInReplay && `TUTORIAL == none;
}

simulated function InterruptInitiativeTurn(XComGameState NewGameState, StateObjectReference InterruptingAIGroupRef)
{
	local XComGameState_BattleData NewBattleData;
	local XComGameState_AIGroup InterruptedAIGroup, InterruptingAIGroup;

	NewBattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', CachedBattleDataRef.ObjectID));
	NewBattleData.InterruptingGroupRef = InterruptingAIGroupRef;
	NewBattleData.InterruptedUnitRef = TacticalController.GetActiveUnitStateRef();

	InterruptedAIGroup = XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(CachedUnitActionInitiativeRef.ObjectID));
	if( InterruptedAIGroup != None )
	{
		InterruptedAIGroup = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', CachedUnitActionInitiativeRef.ObjectID));
		InterruptedAIGroup.bInitiativeInterrupted = true;
	}

	InterruptingAIGroup = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', InterruptingAIGroupRef.ObjectID));
	RemoveGroupFromInitiativeOrder(InterruptingAIGroup, NewGameState);
}

simulated function bool UnitHasActionsAvailable(XComGameState_Unit UnitState)
{
	local GameRulesCache_Unit UnitCache;
	local AvailableAction Action;

	if( UnitState == none )
		return false;

	if (UnitState.bPanicked) //Panicked units are not allowed to be selected
		return false;

	//Dead, unconscious, and bleeding-out units should not be selectable.
	if (UnitState.IsDead() || UnitState.IsIncapacitated())
		return false;

	if( !UnitState.GetMyTemplate().bIsCosmetic &&
	   !UnitState.IsPanicked() &&
	   (UnitState.AffectedByEffectNames.Find(class'X2Ability_Viper'.default.BindSustainedEffectName) == INDEX_NONE) )
	{
		GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache);
		foreach UnitCache.AvailableActions(Action)
		{
			if( Action.bInputTriggered && Action.AvailableCode == 'AA_Success' )
			{
				return true;
			}
		}
	}

	return false;
}

/// <summary>
/// This turn phase forms the bulk of the X-Com 2 turn and represents the phase of the battle where players are allowed to 
/// select what actions they will perform with their units
/// </summary>
simulated state TurnPhase_UnitActions
{
	simulated event BeginState(name PreviousStateName)
	{
		local XComGameState_BattleData BattleData;
		local XComGameState_AIGroup OtherGroup;
		local int Index;

		`SETLOC("BeginState");

		if( !bLoadingSavedGame )
		{
			BeginState_RulesAuthority(SetupUnitActionsState);
		}

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		`assert(BattleData.PlayerTurnOrder.Length > 0);

		ResetInitiativeOrder();

		if( bLoadingSavedGame )
		{
			//Skip to the current player			
			CachedUnitActionInitiativeRef = BattleData.UnitActionInitiativeRef;
			CachedUnitActionPlayerRef = BattleData.UnitActionPlayerRef;

			UnitActionInitiativeIndex = BattleData.PlayerTurnOrder.Find( 'ObjectID', CachedUnitActionInitiativeRef.ObjectID );

			// if the currently active group is not in the initiative order, we have to find the group that is being interrupted to mark the current index
			if( UnitActionInitiativeIndex == INDEX_NONE && BattleData.InterruptingGroupRef.ObjectID == CachedUnitActionInitiativeRef.ObjectID )
			{
				for( Index = 0; Index < BattleData.PlayerTurnOrder.Length; ++Index )
				{
					OtherGroup = XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(BattleData.PlayerTurnOrder[Index].ObjectID));
					if( OtherGroup != None && OtherGroup.bInitiativeInterrupted )
					{
						UnitActionInitiativeIndex = Index;
						break;
					}
				}

				bInitiativeInterruptingInitialGroup = true;
			}

			RefreshInitiativeReferences();

			BeginInitiativeTurn( false, false );

			class'Engine'.static.GetEngine().ReinitializeValueOnLoadComplete();

			//Clear the loading flag - it is only relevant during the 'next player' determination
			bSkipAutosaveAfterLoad = (CachedUnitActionInitiativeRef == CachedUnitActionPlayerRef);
			bLoadingSavedGame = false;
		}
		else
		{
			NextInitiativeGroup();
		}

		bSkipRemainingTurnActivty = false;
	}

	simulated function ResetInitiativeOrder()
	{
		UnitActionInitiativeIndex = -1;
	}

	simulated function SetupUnitActionsState(XComGameState NewPhaseState)
	{
		//  This code has been moved to the player turn observer, as units need to reset their actions
		//  only when their player turn changes, not when the over all game turn changes over.
		//  Leaving this function hook for future implementation needs. -jbouscher
	}

	simulated function ResetHitCountersOnPlayerTurnBegin()
	{
		local XComGameState_Player NewPlayerState;
		local XComGameState NewGameState;
		local XComGameState_AIGroup GroupState;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ResetHitCountersOnPlayerTurnBegin");

		// clear the streak counters on this player
		NewPlayerState = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', GetCachedUnitActionPlayerRef().ObjectID));
		NewPlayerState.MissStreak = 0;
		NewPlayerState.HitStreak = 0;

		// clear summoning sickness on any groups of this player's team
		foreach CachedHistory.IterateByClassType(class'XComGameState_AIGroup', GroupState)
		{
			if( GroupState.TeamName == NewPlayerState.TeamFlag )
			{
				GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', GroupState.ObjectID));
				GroupState.bSummoningSicknessCleared = true;
			}
		}

		SubmitGameState(NewGameState);
	}

	simulated function SetupUnitActionsForGroupTurnBegin(bool bReturningFromInterruptedTurn)
	{
		local XComGameState_AIGroup GroupState;
		local StateObjectReference UnitRef;
		local XComGameState_Unit NewUnitState;
		local XComGameStateContext_TacticalGameRule Context;
		local XComGameState NewGameState;
		local XComGameState_BattleData BattleData;
		local X2EventManager EventManager;

		// build a gamestate to mark this end of this players turn
		Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitGroupTurnBegin);
		Context.PlayerRef = InterruptingUnitActionPlayerRef.ObjectID >= 0 ? InterruptingUnitActionPlayerRef : CachedUnitActionPlayerRef;
		NewGameState = Context.ContextBuildGameState();

		GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', CachedUnitActionInitiativeRef.ObjectID));
		GroupState.bInitiativeInterrupted = false;

		BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', CachedBattleDataRef.ObjectID));
		BattleData.UnitActionInitiativeRef = GroupState.GetReference();

		if( !bReturningFromInterruptedTurn )
		{
			foreach GroupState.m_arrMembers(UnitRef)
			{
				// Create a new state object on NewPhaseState for UnitState
				NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
				NewUnitState.SetupActionsForBeginTurn();
			}

			// Trigger the UnitGroupTurnBegun event
			EventManager = `XEVENTMGR;
			EventManager.TriggerEvent('UnitGroupTurnBegun', GroupState, GroupState, NewGameState);
		}

		SubmitGameState(NewGameState);
	}

	simulated function bool NextInitiativeGroup()
	{
		local XComGameState NewGameState;
		local XComGameState_BattleData NewBattleData;
		local bool bResumeFromInterruptedInitiative, bBeginInterruptedInitiative;
		local StateObjectReference PreviousPlayerRef, PreviousUnitActionRef;

		NewBattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		PreviousPlayerRef = GetCachedUnitActionPlayerRef();
		PreviousUnitActionRef = CachedUnitActionInitiativeRef;

		bResumeFromInterruptedInitiative = false;
		bBeginInterruptedInitiative = false;

		// select the interrupting group if there is one
		if( NewBattleData.InterruptingGroupRef.ObjectID > 0 )
		{
			// if the interrupting group is already the active group, we are resuming from interruption; else we are starting the interruption
			if( CachedUnitActionInitiativeRef.ObjectID == NewBattleData.InterruptingGroupRef.ObjectID )
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RemoveInterruptingInitiativeGroup");
				NewBattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', CachedBattleDataRef.ObjectID));
				NewBattleData.InterruptingGroupRef.ObjectID = -1;
				SubmitGameState(NewGameState);

				bResumeFromInterruptedInitiative = true;

				UnitActionUnitRef = NewBattleData.InterruptedUnitRef;
				NewBattleData.InterruptedUnitRef.ObjectID = -1;
			}
			else
			{
				bBeginInterruptedInitiative = true;
			}
		}

		// advance initiative, unless we are starting an interruption or resuming an initiative that was previously interrupted
		if( !bResumeFromInterruptedInitiative && !bBeginInterruptedInitiative )
		{
			++UnitActionInitiativeIndex;
		}

		RefreshInitiativeReferences();

		EndInitiativeTurn(PreviousPlayerRef, PreviousUnitActionRef, bBeginInterruptedInitiative, bResumeFromInterruptedInitiative);

		if( HasTacticalGameEnded() )
		{
			// if the tactical game has already completed, then we need to bail before
			// initializing the next player, as we do not want any more actions to be taken.
			return false;
		}

		return BeginInitiativeTurn(bBeginInterruptedInitiative, bResumeFromInterruptedInitiative);
	}

	simulated function RefreshInitiativeReferences()
	{
		local XComGameState_Player PlayerState;
		local XComGameState_BattleData BattleData;
		local XComGameState_AIGroup AIGroupState;
		local XComGameState_Unit GroupLeadUnitState;

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		`assert(BattleData.PlayerTurnOrder.Length > 0);

		InterruptingUnitActionPlayerRef.ObjectID = -1;

		if( BattleData.InterruptingGroupRef.ObjectID > 0 )
		{
			CachedUnitActionInitiativeRef = BattleData.InterruptingGroupRef;

			AIGroupState = XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(CachedUnitActionInitiativeRef.ObjectID));
			GroupLeadUnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(AIGroupState.m_arrMembers[0].ObjectID));
			InterruptingUnitActionPlayerRef = GroupLeadUnitState.ControllingPlayer;
		}
		else if( UnitActionInitiativeIndex >= 0 && UnitActionInitiativeIndex < BattleData.PlayerTurnOrder.Length )
		{
			CachedUnitActionInitiativeRef = BattleData.PlayerTurnOrder[UnitActionInitiativeIndex];
			PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionInitiativeRef.ObjectID));
			if( PlayerState != None )
			{
				CachedUnitActionPlayerRef = CachedUnitActionInitiativeRef;
			}
		}
		else
		{
			CachedUnitActionInitiativeRef.ObjectID = -1;
			CachedUnitActionPlayerRef.ObjectID = -1;
		}
	}

	simulated function bool BeginInitiativeTurn(bool bBeginInterruptedInitiative, bool bResumeFromInterruptedInitiative)
	{
		local XComGameStateContext_TacticalGameRule Context;
		local XComGameState NewGameState;
		local XComGameState_Player PlayerState;
		local X2EventManager EventManager;
		local XGPlayer PlayerStateVisualizer;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;
		local XComGameState_AIGroup AIGroupState;
		local bool bReturningFromInterruptedTurn;
		local XComGameState_BattleData BattleData;

		if( CachedUnitActionInitiativeRef.ObjectID >= 0 )
		{
			//Don't process turn begin/end events if we are loading from a save
			if( !bLoadingSavedGame )
			{
				if( CachedUnitActionPlayerRef.ObjectID == CachedUnitActionInitiativeRef.ObjectID )
				{
					// ResetHitCountersOnPlayerTurnBegin(); Issue #36, commented and move below
					/// HL-Docs: ref:Bugfixes; issue:36
					/// Do not clear Reinforcements' "Summoning Sickness" when interrupted by Skirmisher, denying them an erronous bonus turn.
					PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
					`assert( PlayerState != None );
					PlayerStateVisualizer = XGPlayer(PlayerState.GetVisualizer());

					PlayerStateVisualizer.OnUnitActionPhaseBegun_NextPlayer();  // This initializes the AI turn 

					if( !bResumeFromInterruptedInitiative && !bBeginInterruptedInitiative )
					{
						//start Issue #36
						ResetHitCountersOnPlayerTurnBegin();
						//end issue #36
						// Trigger the PlayerTurnBegun event
						EventManager = `XEVENTMGR;

							// build a gamestate to mark this beginning of this players turn
							Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnBegin);
						Context.PlayerRef = CachedUnitActionPlayerRef;

						BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
						if( UnitActionInitiativeIndex >= BattleData.PlayerTurnOrder.Length ||
						   XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(BattleData.PlayerTurnOrder[UnitActionInitiativeIndex + 1].ObjectID)) == None )
						{
							Context.bSkipVisualization = true;
						}

						NewGameState = Context.ContextBuildGameState();

						EventManager.TriggerEvent('PlayerTurnBegun', PlayerState, PlayerState, NewGameState);

						SubmitGameState(NewGameState);
					}

					ChallengeData = XComGameState_ChallengeData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true));
					if( (ChallengeData != none) && !UnitActionPlayerIsAI() )
					{
						TimerState = XComGameState_TimerData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData'));
						TimerState.bStopTime = false;
					}
				}
				else
				{
					AIGroupState = XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(CachedUnitActionInitiativeRef.ObjectID));
					`assert( AIGroupState != None );

					bReturningFromInterruptedTurn = 
						(bResumeFromInterruptedInitiative && AIGroupState.bInitiativeInterrupted) || 
						!AIGroupState.bSummoningSicknessCleared;	// Summoning sickness should be treated like a resumed turn

					// before the start of each player's turn, submit a game state resetting that player's units' per-turn values (like action points remaining)
					SetupUnitActionsForGroupTurnBegin(bReturningFromInterruptedTurn);

					if( !bReturningFromInterruptedTurn || bInitiativeInterruptingInitialGroup )
					{
						PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(GetCachedUnitActionPlayerRef().ObjectID));
						`assert( PlayerState != None );
						PlayerStateVisualizer = XGPlayer(PlayerState.GetVisualizer());

						PlayerStateVisualizer.OnUnitActionPhase_NextGroup(CachedUnitActionInitiativeRef);

						bInitiativeInterruptingInitialGroup = false;
					}
				}
			}

			//Uncomment if there are persistent lines you want to refresh each turn
			//WorldInfo.FlushPersistentDebugLines();

			`XTACTICALSOUNDMGR.EvaluateTacticalMusicState();
			return true;
		}
		return false;
	}

	simulated function EndInitiativeTurn(StateObjectReference PreviousPlayerRef, StateObjectReference PreviousUnitActionRef, bool bBeginInterruptedInitiative, bool bResumeFromInterruptedInitiative)
	{
		local XComGameStateContext_TacticalGameRule Context;
		local XComGameState_Player PlayerState;
		local X2EventManager EventManager;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;
		local XComGameState_AIGroup GroupState;
		local XComGameState NewGameState;

		EventManager = `XEVENTMGR;

		if( PreviousPlayerRef.ObjectID > 0 )
		{
			if( CachedUnitActionPlayerRef.ObjectID != PreviousPlayerRef.ObjectID )
			{
				//Notify the player state's visualizer that they are no longer the unit action player
				PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(PreviousPlayerRef.ObjectID));
				`assert( PlayerState != None );
				XGPlayer(PlayerState.GetVisualizer()).OnUnitActionPhaseFinished_NextPlayer();

				//Don't process turn begin/end events if we are loading from a save
				if( !bLoadingSavedGame && !bResumeFromInterruptedInitiative && !bBeginInterruptedInitiative )
				{
					// build a gamestate to mark this end of this players turn
					Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnEnd);
					Context.PlayerRef = PreviousPlayerRef;

					NewGameState = Context.ContextBuildGameState();
					EventManager.TriggerEvent('PlayerTurnEnded', PlayerState, PlayerState, NewGameState);

					SubmitGameState(NewGameState);
				}

				ChallengeData = XComGameState_ChallengeData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true));
				if( (ChallengeData != none) && !UnitActionPlayerIsAI() )
				{
					TimerState = XComGameState_TimerData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData'));
					TimerState.bStopTime = true;
				}
			}

			//If we switched away from a unit initiative group, trigger an event
			//Don't process turn begin/end events if we are loading from a save
			if( (PreviousUnitActionRef.ObjectID != PreviousPlayerRef.ObjectID) && !bLoadingSavedGame && !bBeginInterruptedInitiative )
			{
				GroupState = XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(PreviousUnitActionRef.ObjectID));

				// build a gamestate to mark this end of this players turn
				Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitGroupTurnEnd);
				Context.PlayerRef = PreviousPlayerRef;
				Context.UnitRef = PreviousUnitActionRef;
				NewGameState = Context.ContextBuildGameState( );

				EventManager.TriggerEvent('UnitGroupTurnEnded', GroupState, GroupState, NewGameState);

				SubmitGameState(NewGameState);
			}
		}
	}

	simulated function bool ActionsAvailable()
	{
		local XComGameState_Unit UnitState;
		local XComGameState_Player PlayerState;
		local bool bActionsAvailable;
		local XComGameState_AIGroup GroupState;
		local StateObjectReference UnitRef;
		local XComGameState_BattleData BattleData;
		local int NumGroupMembers, MemberIndex, CurrentUnitIndex;

		// no units act when a player has initiative; they only act when their group has initiative
		if( CachedUnitActionInitiativeRef.ObjectID == CachedUnitActionPlayerRef.ObjectID )
		{
			return false;
		}

		// if there is an interrupting group specified and that is not the currently active group, this group needs interruption
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		if( BattleData.InterruptingGroupRef.ObjectID > 0 && CachedUnitActionInitiativeRef.ObjectID != BattleData.InterruptingGroupRef.ObjectID )
		{
			return false;
		}

		// Turn was skipped, no more actions
		if (bSkipRemainingTurnActivty)
		{
			return false;
		}

		bActionsAvailable = false;

		GroupState = XComGameState_AIGroup(CachedHistory.GetGameStateForObjectID(CachedUnitActionInitiativeRef.ObjectID));

		// handle interrupting unit
		if (UnitActionUnitRef.ObjectID > 0)
		{
			UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(UnitActionUnitRef.ObjectID));
			if ((UnitState.GetGroupMembership().ObjectID == GroupState.ObjectID) && UnitHasActionsAvailable(UnitState))
			{
				bActionsAvailable = true;
				UnitActionUnitRef.ObjectID = -1;
			}
		}

		// handle restoring the previous unit if possible
		UnitRef = TacticalController.GetActiveUnitStateRef();
		if( UnitRef.ObjectID > 0 )
		{
			UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(UnitRef.ObjectID));
			if( (UnitState.GetGroupMembership().ObjectID == GroupState.ObjectID) && UnitHasActionsAvailable(UnitState) )
			{
				bActionsAvailable = true;
			}
		}

		// select the *next* available group member that has any actions
		if( !bActionsAvailable )
		{
			NumGroupMembers = GroupState.m_arrMembers.Length;

			CurrentUnitIndex = Clamp(GroupState.m_arrMembers.Find('ObjectID', UnitRef.ObjectID), 0, NumGroupMembers - 1);

			for( MemberIndex = 0; !bActionsAvailable && MemberIndex < NumGroupMembers; ++MemberIndex )
			{
				UnitRef = GroupState.m_arrMembers[(CurrentUnitIndex + MemberIndex) % NumGroupMembers];

				UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(UnitRef.ObjectID));

				bActionsAvailable = UnitHasActionsAvailable(UnitState);
			}
		}

		if( bActionsAvailable )
		{
			bWaitingForNewStates = true;	//If there are actions available, indicate that we are waiting for a decision on which one to take

			if( !UnitActionPlayerIsRemote() )
			{				
				PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
				`assert(PlayerState != none);
				XGPlayer(PlayerState.GetVisualizer()).OnUnitActionPhase_ActionsAvailable(UnitState);
			}
		}

		return bActionsAvailable;
	}

	simulated function EndPhase()
	{
		local X2AIBTBehaviorTree BehaviorTree;

		BehaviorTree = `BEHAVIORTREEMGR;

		//Safety measure, make sure all AI BT queues are clear. This should have been taken care of during the 
		//AI turn. If this becomes a problem, a redscreen here might be appropriate.
		BehaviorTree.ClearQueue();

		if (HasTacticalGameEnded())
		{
			GotoState( 'EndTacticalGame' );
		}
		else
		{
			GotoState( GetNextTurnPhase( GetStateName() ) );
		}
	}

	simulated function string GetStateDebugString()
	{
		local string DebugString;
		local XComGameState_Player PlayerState;
		local int UnitCacheIndex;
		local int ActionIndex;
		local XComGameState_Unit UnitState;				
		local XComGameState_Ability AbilityState;
		local AvailableAction AvailableActionData;
		local string EnumString;

		PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));

		DebugString = "Unit Action Player  :"@((PlayerState != none) ? string(PlayerState.GetVisualizer()) : "PlayerState_None")@" ("@CachedUnitActionPlayerRef.ObjectID@") ("@ (UnitActionPlayerIsRemote() ? "REMOTE" : "") @")\n";
		DebugString = DebugString$"Begin Block Location: " @ BeginBlockWaitingLocation @ "\n\n";
		DebugString = DebugString$"Internal State:"@ (bWaitingForNewStates ? "Waiting For Player Decision" : "Waiting for Visualizer") @ "\n\n";
		DebugString = DebugString$"Unit Cache Info For Unit Action Player:\n";

		for( UnitCacheIndex = 0; UnitCacheIndex < UnitsCache.Length; ++UnitCacheIndex )
		{
			UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(UnitsCache[UnitCacheIndex].UnitObjectRef.ObjectID));

			//Check whether this unit is controlled by the UnitActionPlayer
			if( UnitState.ControllingPlayer.ObjectID == GetCachedUnitActionPlayerRef().ObjectID )
			{			
				DebugString = DebugString$"Unit: "@((UnitState != none) ? string(UnitState.GetVisualizer()) : "UnitState_None")@"("@UnitState.ObjectID@") [HI:"@UnitsCache[UnitCacheIndex].LastUpdateHistoryIndex$"] ActionPoints:"@UnitState.NumAllActionPoints()@" (Reserve:" @ UnitState.NumAllReserveActionPoints() $") - ";
				for( ActionIndex = 0; ActionIndex < UnitsCache[UnitCacheIndex].AvailableActions.Length; ++ActionIndex )
				{
					AvailableActionData = UnitsCache[UnitCacheIndex].AvailableActions[ActionIndex];

					AbilityState = XComGameState_Ability(CachedHistory.GetGameStateForObjectID(AvailableActionData.AbilityObjectRef.ObjectID));
					EnumString = string(AvailableActionData.AvailableCode);
					
					DebugString = DebugString$"("@AbilityState.GetMyTemplateName()@"-"@EnumString@") ";
				}
				DebugString = DebugString$"\n";
			}
		}

		return DebugString;
	}

	event Tick(float DeltaTime)
	{		
		local XComGameState_Player PlayerState;
		local XGAIPlayer AIPlayer;
		local int fTimeOut;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;

		super.Tick(DeltaTime);

		//rmcfall - if the AI player takes longer than 25 seconds to make a decision a blocking error has occurred in its logic. Skip its turn to avoid a hang.
		//This logic is redundant to turn skipping logic in the behaviors, and is intended as a last resort
		if( UnitActionPlayerIsAI() && bWaitingForNewStates && !(`CHEATMGR != None && `CHEATMGR.bAllowSelectAll) )
		{
			PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(GetCachedUnitActionPlayerRef().ObjectID));
			AIPlayer = XGAIPlayer(PlayerState.GetVisualizer());

			if (AIPlayer.m_eTeam == eTeam_Neutral)
			{
				fTimeOut = 5.0f;
			}
			else
			{
				fTimeOut = 25.0f;
			}
			WaitingForNewStatesTime += DeltaTime;
			if (WaitingForNewStatesTime > fTimeOut && !`REPLAY.bInReplay)
			{
				`LogAIActions("Exceeded WaitingForNewStates TimeLimit"@WaitingForNewStatesTime$"s!  Calling AIPlayer.EndTurn()");
				AIPlayer.OnTimedOut();
				class'XGAIPlayer'.static.DumpAILog();
				AIPlayer.EndTurn(ePlayerEndTurnType_AI);
			}
		}

		ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) );
		if ((ChallengeData != none) && !UnitActionPlayerIsAI() && !WaitingForVisualizer())
		{
			TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData') );
			if (TimerState.GetCurrentTime() <= 0)
			{
				FailBattle();
			}
		}
	}

	function StateObjectReference GetCachedUnitActionPlayerRef()
	{
		if( InterruptingUnitActionPlayerRef.ObjectID > 0 )
		{
			return InterruptingUnitActionPlayerRef;
		}
		return CachedUnitActionPlayerRef;
	}

	function CheckForAutosave(optional bool bDebugSave)
	{
		local XComGameState_LadderProgress LadderData;
		local XComGameState_Player PlayerState;

		if(bSkipAutosaveAfterLoad)
		{
			bSkipAutosaveAfterLoad = false; // clear the flag so that the next autosave goes through
		}
		else if (RulesetShouldAutosave())
		{
			`AUTOSAVEMGR.DoAutosave(, bDebugSave);
		}

		LadderData = XComGameState_LadderProgress( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress', true ) );
		PlayerState = XComGameState_Player( `XCOMHISTORY.GetGameStateForObjectID( CachedUnitActionPlayerRef.ObjectID ) );
		if (!bDebugSave && (LadderData != none) && (PlayerState.PlayerTurnCount == 1) && (PlayerState.TeamFlag == eTeam_XCom))
		{
			`ONLINEEVENTMGR.SaveLadderGame( );
		}
	}

Begin:
	`SETLOC("Start of Begin Block");
	CachedHistory.CheckNoPendingGameStates();

	//Loop through the players, allowing each to perform actions with their units
	do
	{	
		sleep(0.0); // Wait a tick for the game states to be updated before switching the sending
		
		//Before switching players, wait for the current player's last action to be fully visualized
		while( WaitingForVisualizer() )
		{
			`SETLOC("Waiting for Visualizer: 1");
			sleep(0.0);
		}

		// autosave after the visualizer finishes doing it's thing and control is being handed over to the player. 
		// This guarantees that any pre-turn behavior tree or other ticked decisions have completed modifying the history.
		// Only autosave at the start of player turns, not for each initiative group.
		if (CachedUnitActionPlayerRef == CachedUnitActionInitiativeRef)
		{
			while (IsDoingLatentSubmission())
			{
				`SETLOC("Waiting for Latent Submission: 1");
				sleep(0.0);
			}
			CheckForAutosave();
		}
			

		`SETLOC("Check for Available Actions");
		while( ActionsAvailable() && !HasTacticalGameEnded() )
		{
			CachedHistory.CheckNoPendingGameStates();

			if( `CHEATMGR.bShouldAutosaveBeforeEveryAction && bWaitingForNewStates )
			{
				while (IsDoingLatentSubmission())
				{
					`SETLOC("Waiting for Latent Submission: 1");
					sleep(0.0);
				}				
				CheckForAutosave(true);
				sleep(0.0);
			}
			if (RulesetShouldAutosave())
				VisualizerActivationHistoryFrames.AddItem( CachedHistory.GetNumGameStates() );

			WaitingForNewStatesTime = 0.0f;

			//Wait for new states created by the player / AI / remote player. Manipulated by the SubmitGameStateXXX methods
			while( (bWaitingForNewStates && !HasTimeExpired()) || BuildingLatentGameState)
			{
				`SETLOC("Available Actions");
				sleep(0.0);
			}
			`SETLOC("Available Actions: Done waiting for New States");

			while( WaitingForVisualizer() )
			{
				`SETLOC("Waiting for Visualizer: 1.5");
				sleep(0.0);
			}

			sleep(0.0);
		}

		while( WaitingForVisualizer() || WaitingForMinimumTurnTimeElapsed() )
		{
			`SETLOC("Waiting for Visualizer: 2");
			sleep(0.0);
		}

		// Moved to clear the SkipRemainingTurnActivty flag until after the visualizer finishes.  Prevents an exploit where
		// the end/back button is spammed during the player's final action. Previously the Skip flag was set to true 
		// while visualizing the action, after the flag was already cleared, causing the subsequent AI turn to get skipped.
		bSkipRemainingTurnActivty = false;
		`SETLOC("Going to the Next Player");
	}
	until(!NextInitiativeGroup()); //NextInitiativeGroup returns false when the UnitActionInitiativeIndex has reached the end of PlayerTurnOrder in the BattleData state.
	
	//Wait for the visualizer to perform the visualization steps for all states before we permit the rules engine to proceed to the next phase
	while( EndOfTurnWaitingForVisualizer() )
	{
		`SETLOC("Waiting for Visualizer: 3");
		sleep(0.0);
	}

	// Failsafe. Make sure there are no active camera anims "stuck" on
	GetALocalPlayerController().PlayerCamera.StopAllCameraAnims(TRUE);

	`SETLOC("Updating AI Activity");
	UpdateAIActivity(false);

	CachedHistory.CheckNoPendingGameStates();

	`SETLOC("Ending the Phase");
	EndPhase();
	`SETLOC("End of Begin Block");
}

/// <summary>
/// This turn phase is entered at the end of each turn and handles any end-of-turn scenario events.
/// </summary>
simulated state TurnPhase_End
{
	simulated event BeginState(name PreviousStateName)
	{
		`SETLOC("BeginState");

		BeginState_RulesAuthority(none);
	}

Begin:
	`SETLOC("Start of Begin Block");

	////Wait for all players to reach this point in their rules engine
	//while( WaitingForPlayerSync() )
	//{
	//	sleep(0.0);
	//}

	CachedHistory.CheckNoPendingGameStates();

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This turn phase is entered at the end of each turn and handles any end-of-turn scenario events.
/// </summary>
simulated state TurnPhase_WaitForTutorialInput
{
	simulated event BeginState(name PreviousStateName)
	{
		`SETLOC("BeginState");

		BeginState_RulesAuthority(none);
	}

Begin:
	//We wait here forever until put back into PerformingReplay by XComTutorialMgr
	while (true)
	{
		sleep(0.f);
	}
}

/// <summary>
/// This phase is entered following the successful load of a replay. Turn logic is not intended to be applied to replays by default, but may be activated and
/// used to perform unit tests / validation of correct operation within this state.
/// </summary>
simulated state PerformingReplay
{
	simulated event BeginState(name PreviousStateName)
	{
		local UIReplay ReplayUI;
		`SETLOC("BeginState");

		bTacticalGameInPlay = true;

		//Auto-start the replay, but not if we are in the tutorial
		if (!`REPLAY.bInTutorial)
		{	
			ReplayUI = UIReplay(`PRES.ScreenStack.GetCurrentScreen());
			if (ReplayUI != none)
			{
				ReplayUI.OnPlayClicked();
			}
		}
	}

	function EndReplay()
	{
		GotoState(GetNextTurnPhase(GetStateName()));
	}

Begin:
	`SETLOC("End of Begin Block");
}

function ExecuteNextSessionCommand()
{
	//Tell the content manager to build its list of required content based on the game state that we just built and added.
	`CONTENT.RequestContent();
	ConsoleCommand(NextSessionCommandString);
}

/// <summary>
/// This state is entered when a tactical game ended state is pushed onto the history
/// </summary>
simulated state EndTacticalGame
{
	simulated event BeginState(name PreviousStateName)
	{
		local XGPlayer ActivePlayer;
		local XComGameState_ChallengeData ChallengeData;

		`SETLOC("BeginState");

		ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) );

		if (PreviousStateName != 'PerformingReplay')
		{
			SubmitChallengeMode();
		}

		// make sure that no controllers are active
		if( GetCachedUnitActionPlayerRef().ObjectID > 0)
		{
			ActivePlayer = XGPlayer(CachedHistory.GetVisualizer(GetCachedUnitActionPlayerRef().ObjectID));
			ActivePlayer.m_kPlayerController.Visualizer_ReleaseControl();
		}

		//Show the UI summary screen before we clean up the tactical game
		if(!bPromptForRestart && !`REPLAY.bInTutorial && !IsFinalMission() && !IsLostAndAbandonedMission())
		{
			if (ChallengeData == none)
			{
				if(class'XComGameState_HeadquartersAlien'.static.WasChosenOnMission() && !IsChosenShowdownMission())
				{
					`PRES.UIChosenMissionSummaryScreen();
				}
				else
				{
					`PRES.UIMissionSummaryScreen();
				}
			}
			else
			{
				`PRES.UIChallengeModeSummaryScreen( );
			}

			`XTACTICALSOUNDMGR.StartEndBattleMusic();
		}

		//Disable visibility updates
		`XWORLD.bDisableVisibilityUpdates = true;
	}

	simulated function CleanupAndClearTacticalPlayFlags()
	{
		local XComGameState_ChallengeData ChallengeData;

		ChallengeData = XComGameState_ChallengeData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true));

		//The tutorial is just a replay that the player clicks through by performing the actions in the replay. 
		if( !`REPLAY.bInTutorial && (ChallengeData == none) )
		{
			CleanupTacticalMission();
			EndTacticalPlay();
		}
		else
		{
			bTacticalGameInPlay = false;
		}
	}

	simulated function SubmitChallengeMode()
	{
		local XComGameState_TimerData Timer;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_BattleData BattleData;
		local XComGameState NewGameState;
		local X2ChallengeModeInterface ChallengeModeInterface;
		local XComChallengeModeManager ChallengeModeManager;
		local X2TacticalChallengeModeManager TacticalChallengeModeManager;

		ChallengeModeManager = `CHALLENGEMODE_MGR;
		ChallengeModeInterface = `CHALLENGEMODE_INTERFACE;
		BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		TacticalChallengeModeManager = `TACTICALGRI.ChallengeModeManager;
		TacticalChallengeModeManager.OnEventTriggered((BattleData.bLocalPlayerWon) ? ECME_CompletedMission : ECME_FailedMission);
		`log(`location @ "Triggered Event on Tactical Challenge Mode Manager: " @ `ShowVar(BattleData.bLocalPlayerWon));

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("EndTacticalGame: SubmitChallengeMode");

		Timer = XComGameState_TimerData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
		if (Timer != none)
		{
			ChallengeData = XComGameState_ChallengeData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true));
			ChallengeData = XComGameState_ChallengeData(NewGameState.ModifyStateObject(class'XComGameState_ChallengeData', ChallengeData.ObjectID));
			if (ChallengeData != none)
			{
				ChallengeData.SeedData.EndTime.A = Timer.GetUTCTimeInSeconds();
				ChallengeData.SeedData.VerifiedCount = Timer.GetElapsedTime();
				ChallengeData.SeedData.GameScore = ChallengeModeManager.GetTotalScore();
			}
		}

		SubmitGameState(NewGameState);

		if (ChallengeData != none && ChallengeModeInterface != none)
		{
			ChallengeModeInterface.PerformChallengeModePostGameSave();
			ChallengeModeInterface.PerformChallengeModePostEventMapData();
		}

		ChallengeModeManager.SetTempScoreData(CachedHistory);
	}

	simulated function bool IsLostAndAbandonedMission()
	{
		local XComGameState_MissionSite MissionState;
		local XComGameState_HeadquartersXCom XComHQ;

		XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

		if (MissionState.GetMissionSource().DataName == 'MissionSource_LostAndAbandoned')
		{
			return true;
		}

		return false;
	}

	simulated function bool IsChosenShowdownMission()
	{
		local XComGameState_MissionSite MissionState;
		local XComGameState_HeadquartersXCom XComHQ;

		XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

		if (MissionState.GetMissionSource().DataName == 'MissionSource_ChosenStronghold')
		{
			return true;
		}

		return false;
	}

	simulated function NextSessionCommand()
	{	
		local XComGameState_BattleData BattleData;
		local XComGameState_CampaignSettings NewCampaignSettingsStateObject;
		local XComGameState StrategyStartState;
		local XComGameState_MissionSite MissionState;
		local XComGameState_HeadquartersXCom XComHQ;	
		local XComNarrativeMoment TutorialReturn;
		local XGUnit Unit;
		local XComPawn DisablePawn;
		local bool bLoadingMovieOnReturn;
		local XComGameState_LadderProgress LadderData;

		// at the end of the session, the event listener needs to be cleared of all events and listeners; reset it
		`XEVENTMGR.ResetToDefaults(false);

		LadderData = XComGameState_LadderProgress( CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress') );

		//Determine whether we were playing a one-off tactical battle or if we are in a campaign.
		BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if (`ONLINEEVENTMGR.bIsLocalChallengeModeGame)
		{
			`ONLINEEVENTMGR.bIsLocalChallengeModeGame = false; // won't be in challenge mode anymore
			ConsoleCommand("disconnect");
		}
		else if (BattleData.m_strDesc ~= "Challenge Mode")
		{
			`ONLINEEVENTMGR.SetShuttleToChallengeMenu();
			ConsoleCommand("disconnect");
		}
		else if (BattleData.m_strDesc == "BenchmarkTest")
		{
			//ConsoleCommand( "EXIT" );
		}
		else if (LadderData != none)
		{
			ConsoleCommand( LadderData.ProgressCommand );
		}
		else if(BattleData.bIsTacticalQuickLaunch && !`REPLAY.bInTutorial) //Due to the way the tutorial was made, the battle data in it may record that it is a TQL match
		{
			ConsoleCommand("disconnect");
		}
		else
		{	
			XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
						
			//Figure out whether we need to go to a loading screen or not
			NextSessionCommandString = class'XComGameStateContext_StrategyGameRule'.default.StrategyMapCommand;
			bLoadingMovieOnReturn = !MissionState.GetMissionSource().bRequiresSkyrangerTravel || !class'XComMapManager'.default.bUseSeamlessTravelToStrategy || MissionState.GetMissionSource().CustomLoadingMovieName_Outro != "";

			//If we are in the tutorial, create a strategy game start
			if(`REPLAY.bInTutorial)
			{
				//Special case for units since they have attached pawns.
				foreach WorldInfo.AllActors(class'XGUnit', Unit)
				{
					Unit.Uninit();
				}

				//Covers pathing pawns, cosmetic pawns, etc.
				foreach WorldInfo.AllActors(class'XComPawn', DisablePawn)
				{
					DisablePawn.SetTickIsDisabled(true);
				}

				//Disable various managers and actors that have problems when we destroy visualizers
				`XWORLD.bTickIsDisabled = true;				
				TacticalController.ClearActiveUnit();
				TacticalController.Visualizer_ReleaseControl();

				// Complete tutorial achievement
				`ONLINEEVENTMGR.UnlockAchievement( AT_CompleteTutorial );
				`FXSLIVE.AnalyticsGameTutorialCompleted( );

				//Destroy all the visualizers being used by the history, and then reset the history
				CachedHistory.DestroyVisualizers();
				CachedHistory.ResetHistory();

				// Beginner VO is turned on by default parameters in CreateStrategyGameStart()
				StrategyStartState = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(
					,
					,
					true, // Force on the tutorial
					true, // Force on the XPack narrative
					`ONLINEEVENTMGR.CampaignbIntegratedDLCEnabled,
					`ONLINEEVENTMGR.CampaignDifficultySetting,
					`ONLINEEVENTMGR.CampaignTacticalDifficulty,
					`ONLINEEVENTMGR.CampaignStrategyDifficulty,
					`ONLINEEVENTMGR.CampaignGameLength);

				//Copy the original campaign settings into the new
				NewCampaignSettingsStateObject = XComGameState_CampaignSettings(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
				class'XComGameState_CampaignSettings'.static.CopySettingsFromOnlineEventMgr(NewCampaignSettingsStateObject);
				NewCampaignSettingsStateObject.SetStartTime(StrategyStartState.TimeStamp);
				
				bLoadingMovieOnReturn = true; //Play commander awakens as a loading movie
				`XENGINE.PlaySpecificLoadingMovie("CIN_TP_CommanderAwakens.bk2", "X2_010_CommanderAwakens");

				TutorialReturn = XComNarrativeMoment(`CONTENT.RequestGameArchetype("X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_SkyrangerReturn"));
				`PRES.UINarrative(TutorialReturn);
			}
			else
			{
				class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStartFromTactical();

				if (IsFinalMission())
				{					
					`XENGINE.WaitForMovie();
					`XENGINE.StopCurrentMovie();
				}
			}

			//Change the session command based on whether we want to use a loading screen or seamless travel
			if(bLoadingMovieOnReturn)
			{				
				if(MissionState.GetMissionSource().CustomLoadingMovieName_Outro != "")
				{
					`XENGINE.PlaySpecificLoadingMovie(MissionState.GetMissionSource().CustomLoadingMovieName_Outro, MissionState.GetMissionSource().CustomLoadingMovieName_OutroSound);
				}
				else if(MissionState.GetMissionSource().bRequiresSkyrangerTravel)
				{
					`XENGINE.PlaySpecificLoadingMovie("CIN_XP_UI_LogoSpin.bk2");
				}				

				ReplaceText(NextSessionCommandString, "servertravel", "open");
			}

			
			if(bLoadingMovieOnReturn)
			{				
				`XENGINE.PlayLoadMapMovie(-1);
				SetTimer(0.5f, false, nameof(ExecuteNextSessionCommand));
			}
			else
			{
				ExecuteNextSessionCommand();
			}
		}
	}

	simulated function PromptForRestart()
	{
		`PRES.UICombatLoseScreen(LoseType);
	}

Begin:
	`SETLOC("Start of Begin Block");

	if (bPromptForRestart)
	{
		CleanupAndClearTacticalPlayFlags();
		PromptForRestart();
	}
	else
	{
		//This variable is cleared by the mission summary screen accept button
		bWaitingForMissionSummary = !`REPLAY.bInTutorial && !IsFinalMission() && !IsLostAndAbandonedMission();
		while (bWaitingForMissionSummary)
		{
			Sleep(0.0f);
		}

		bWaitingForMissionSummary = class'XComGameState_LadderProgress'.static.MaybeDoLadderProgressionChoice( );
		while (bWaitingForMissionSummary)
		{
			Sleep(0.0f);
		}

		// once the Mission summary UI's have cleared, it is then safe to cleanup the rest of the mission game state
		CleanupAndClearTacticalPlayFlags();

		class'XComGameState_LadderProgress'.static.ProceedToNextRung( );

		bWaitingForMissionSummary = class'XComGameState_LadderProgress'.static.MaybeDoLadderSoliderScreen( );
		while (bWaitingForMissionSummary)
		{
			Sleep(0.0f);
		}

		bWaitingForMissionSummary = class'XComGameState_LadderProgress'.static.MaybeDoLadderMedalScreen();
		while (bWaitingForMissionSummary)
		{
			Sleep(0.0f);
		}

		bWaitingForMissionSummary = class'XComGameState_LadderProgress'.static.MaybeDoLadderEndScreen();
		while (bWaitingForMissionSummary)
		{
			Sleep(0.0f);
		}

		//Turn the visualization mgr off while the map shuts down / seamless travel starts
		VisibilityMgr.UnRegisterForNewGameStateEvent();
		VisualizationMgr.DisableForShutdown();

		//Schedule a 1/2 second fade to black, and wait a moment. Only if the camera is not already faded
		if(!WorldInfo.GetALocalPlayerController().PlayerCamera.bEnableFading)
		{
			`PRES.HUDHide();
			WorldInfo.GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.75);			
			Sleep(1.0f);
		}

		//Trigger the launch of the next session
		NextSessionCommand();
	}
	`SETLOC("End of Begin Block");
}

simulated function name GetLastStateNameFromHistory(name DefaultName='')
{
	local int HistoryIndex;
	local XComGameStateContext_TacticalGameRule Rule;
	local name StateName;

	StateName = DefaultName;
	for( HistoryIndex = CachedHistory.GetCurrentHistoryIndex(); HistoryIndex > 0; --HistoryIndex )
	{
		Rule = XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(HistoryIndex).GetContext());
		if( Rule != none && Rule.GameRuleType == eGameRule_RulesEngineStateChange)
		{
			StateName = Rule.RuleEngineNextState;
			break;
		}
	}
	return StateName;
}

simulated function bool LoadedGameNeedsPostCreate()
{
	local XComGameState_BattleData BattleData;
	BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

	if (BattleData == None)
		return false;

	if (BattleData.bInPlay)
		return false;

	if (!BattleData.bIntendedForReloadLevel)
		return false;

	return true;
}

simulated function name GetNextTurnPhase(name CurrentState, optional name DefaultPhaseName='TurnPhase_End')
{
	local name LastState;
	switch (CurrentState)
	{
	case 'CreateTacticalGame':
		return 'PostCreateTacticalGame';
	case 'LoadTacticalGame':
		if( XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay )
		{
			return 'PerformingReplay';
		}
		if (LoadedGameNeedsPostCreate())
		{
			return 'PostCreateTacticalGame';
		}
		LastState = GetLastStateNameFromHistory();
		return (LastState == '' || LastState == 'LoadTacticalGame') ? 'TurnPhase_UnitActions' : GetNextTurnPhase(LastState, 'TurnPhase_UnitActions');
	case 'PostCreateTacticalGame':
		if (class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode( false ))
			return 'TurnPhase_StartTimer';

		return 'TurnPhase_Begin';
	case 'TurnPhase_Begin':		
		if (XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInTutorial)
		{
			return 'TurnPhase_WaitForTutorialInput';
		}
		else
		{
			return 'TurnPhase_UnitActions';
		}
	case 'TurnPhase_UnitActions':
		return 'TurnPhase_End';
	case 'TurnPhase_End':
		return 'TurnPhase_Begin';
	case 'PerformingReplay':
		if (!XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay || XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInTutorial)
		{
			//Used when resuming from a replay, or in the tutorial and control has "returned" to the player
			return 'TurnPhase_Begin';
		}
	case 'CreateChallengeGame':
		return 'TurnPhase_StartTimer';
	case 'TurnPhase_StartTimer':
		return 'TurnPhase_Begin';
	}
	`assert(false);
	return DefaultPhaseName;
}


//Start issue #647
function UpdateDLCLoadingTacticalGame()
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnLoadedSavedGameToTactical();
	}
}
//End issue #647


function StateObjectReference GetCachedUnitActionPlayerRef()
{
	local StateObjectReference EmptyRef;
	// This should generally not be called outside of the TurnPhase_UnitActions
	// state, except when applying an effect that has bIgnorePlayerCheckOnTick
	// set
	return EmptyRef;
}

final function bool TacticalGameIsInPlay()
{
	return bTacticalGameInPlay;
}

function bool IsWaitingForNewStates()
{
	return bWaitingForNewStates;
}

native function TacticalStreamingMapsPostLoad();

DefaultProperties
{	
	EventObserverClasses[0] = class'X2TacticalGameRuleset_MovementObserver'	
	EventObserverClasses[1] = class'X2TacticalGameRuleset_AttackObserver'
	EventObserverClasses[2] = class'KismetGameRulesetEventObserver'
	
	ContextBuildDepth = 0

	// use -2 so that passing it to GetGameStateFromHistory will return NULL. -1 would return the latest gamestate
	TacticalGameEndIndex = -2
}
