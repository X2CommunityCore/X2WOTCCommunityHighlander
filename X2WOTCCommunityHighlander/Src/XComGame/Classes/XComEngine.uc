class XComEngine extends GameEngine
	native;

const MAX_DATASIZE_FOR_ALL_SAVEGAMES = 10000000;

/** Information set to trigger a checkpoint load/save on the next tick. */
enum ESaveGameAction
{
	SaveGameAction_None,
	SaveGameAction_Load,
	SaveGameAction_Save
};

/** struct to store the date and time the checkpoint was created */
// Gears2-specific, not sure if this makes sense for x-com
struct native CheckpointTime
{
	var int SecondsSinceMidnight;
	var int Day;
	var int Month;
	var int Year;
};

struct native SaveGameEvent
{
	var ESaveGameAction Action;
	var Checkpoint      AssociatedCheckpoint;
};

var	SaveGameEvent PendingCheckpointEvents;

/** current checkpoint in use (if any) */
var							Checkpoint	CurrentCheckpoint;

/** user and device ID to use when checkpointing on xbox */
var							int			CurrentUserID;
var		private{private}	int			CurrentDeviceID;

/** whether to actually write checkpoint data to the storage device or simply keep it in memory */
var							bool		bShouldWriteCheckpointToDisk;

/**
 * Tracks whether the current value of CurrentDeviceID is expected to be valid; used for deterining what action to take when
 * IsCurrentDeviceValid() returns FALSE.
 */
var	transient	const		bool		bHasSelectedValidStorageDevice;

var transient bool	bRefreshAmbientCubeRequested;


var XComContentManager          ContentManager;
var XComMapManager              MapManager;
var XComParcelManager           ParcelManager;
var XComTacticalMissionManager  TacticalMissionManager;
var XComEnvLightingManager      EnvLightingManager;
var XComMCP MCPManager;
var XComOnlineProfileSettings XComProfileSettings;
var XGLocalizeContext LocalizeContext;
var XComChallengeModeManager    ChallengeModeManager;

//=======================================================================================
//X-Com 2 Refactoring
//
var private XComGameStateHistory				GameStateHistory;
var private XComGameStateHistory				ValidationGameStateHistory;
var private XComGameStateNetworkManager			GameStateNetworkManager;
var private X2EventManager						EventManager;
var private XComAISpawnManager					SpawnManager;
var private X2CardManager						CardManager;
var private X2AIBTBehaviorTree					BehaviorTreeManager;
var private X2AIJobManager						AIJobManager;
var private X2AutoPlayManager					AutoPlayManager;
var private X2FiraxisLiveClient					LiveClient;

var private AnalyticsManager					m_AnalyticsManager;
var private X2AchievementTracker				m_AchievementTracker;

var private X2BodyPartTemplateManager		BodyPartTemplateManager;

var private RedScreenManager                m_RedScreenManager;
var private bool							m_RedScreensTemporarilyDisabled;

var public bool								bReviewFlagged;

var CharacterPoolManager					m_CharacterPoolManager;
var X2PhotoBooth_PhotoManager				m_kPhotoManager;

var XComSteamControllerManager				m_SteamControllerManager;

//=======================================================================================

var XGParamTag      ParamTag;
var XGBulletTag     BulletTag;
var X2ObjectTag     ObjectTag;
var X2AbilityTag	AbilityTag;
var X2MetricTag		MetricTag; 
var X2PhotoboothTag		PhotoboothTag;

/** objects that are listening for events from the engine */
var privatewrite array<XComMCPEventListener>     MCPEventListeners;

var private bool m_bShowChart;

var private bool m_bRunAutoTest;
var private float m_autoTestLimit;
var private float m_autoTestDelay;

var private float m_autoTestStart;

var TextureRenderTarget2D   m_kPhotoboothUITexture;
var TextureRenderTarget2D   m_kPhotoboothSoldierTexture;

//=======================================================================================


native static function XComMCP GetMCP();

native static function int GetStringCRC(string Text);

native static function int GetMaxSaveSizeInBytes();

// Gets the default class object for the specified class
native static function Class GetClassByName(name ClassName);

// Gets the default class object for the specified class
native static function Object GetClassDefaultObject(class SeachClass);

// Gets the default class object for the specified class
native static function Object GetClassDefaultObjectByName(name ClassName);

// Gets the default class objects for the specified class and all derived subclasses
native static function array<Object> GetClassDefaultObjects(class SeachClass);

native function bool DoesPackageExist(string Package);

// ONLY use for loading movies, uses a different code path than normal movies -- jboswell
native static final function PlaySpecificLoadingMovie(string MovieName, optional string WiseEvent);
native function bool PlayLoadMapMovie(optional int Idx=0);

native static final function int PlayMovie(bool bLoop, string MovieFilename, optional string WiseEvent, int StartFrame=0);
native static final function WaitForMovie();
native static final function bool IsWaitingForMovie();
native static final function bool IsMoviePlaying(string MovieName);
native static final function bool IsAnyMoviePlaying();
native static final function bool IsLoadingMoviePlaying();
native static final function StopCurrentMovie();
native static final function PauseMovie();
native static final function UnpauseMovie();

//=======================================================================================
//X-Com 2 Refactoring
//
native function Object GetEventManager();
native function Object GetSpawnManager();
native function Object GetCardManager();
native function Object GetBehaviorTreeManager();
native function Object GetAIJobManager();
native function Object GetAutoPlayManager();

native function Object GetCharacterPoolManager();

native function Object GetAnalyticsManager();
native function Object GetAchievementTracker();

native function Object GetFiraxisLiveClient();

//Managers for dynamic map creation
native function Object GetParcelManager();
native function Object GetTacticalMissionManager();
native function Object GetEnvLightingManager();
native function Object GetMapManager();

function CreateGameStateHistory()
{
	GameStateHistory = new(self) class'XComGameStateHistory';
}
native function Object GetGameStateHistory();
native function OnGameStateHistoryResetComplete();

native function Object GetValidationGameStateHistory();
native function Object GetGameStateNetworkManager();

native function WriteSaveFile(string FilePath, string Description);

// Reporting
native function ReportLevelLoadTime(FLOAT LoadTime);


// MP Game check
native function bool IsMultiPlayerGame();
native function bool IsSinglePlayerGame();


//=======================================================================================

static native function BlendVertexPaintForTerrain();
static native function ConsolidateVisGroupData();
static native function AssociateNeighborVisGroups();
static native function TriggerTileDestruction();
static native function AddEffectsToStartState();
static native function UpdateGI();
static native function ClearLPV();

simulated function int ScriptDebugSyncRand(int Max)
{
	return SyncRand(Max,"ScriptDebugSyncRand");
}

simulated function int ScriptDebugSyncFRand()
{
	return SyncFRand("ScriptDebugSyncFRand");
}

native function bool IsLoadingAudioPlaying();

cpptext
{
	virtual void Init();
	virtual void PreExit();

	UBOOL Exec( const TCHAR* Cmd, FOutputDevice& Ar=*GLog );
	virtual void Tick(FLOAT DeltaSeconds);	
	UCheckpoint* ConstructCheckpoint( UClass* GameInfoClass );

	// From GameEngine -- jboswell
	virtual void PlayLoadingMovie( const TCHAR *MovieName);
	virtual UBOOL LoadMap( const FURL& URL, class UPendingLevel* Pending, FString& Error );
	virtual void PostLoadMap();

	virtual void LoadDynamicContent(const FURL &URL, UBOOL bAsync=FALSE);
	virtual void CleanupDynamicContent();

	// communicate required content to clients -tsmith 
	virtual void ClearAllRequiredContentInfo();
	virtual void CacheRequiredContent();
	virtual void FillRequiredContentInfo_Weapons(class FRequiredContentInfo_Weapons& kRequiredContentInfo_Weapons);
	virtual void FillRequiredContentInfo_ArmorKits(class FRequiredContentInfo_ArmorKits& kRequiredContentInfo_ArmorKits);
	virtual void SetRequiredContentFromRequiredContentInfo_Weapons(const class FRequiredContentInfo_Weapons& kRequiredContentInfo_Weapons);
	virtual void SetRequiredContentFromRequiredContentInfo_ArmorKits(const class FRequiredContentInfo_ArmorKits& kRequiredContentInfo_ArmorKits);

	 /** handles an FXS channel message */
	 virtual UBOOL HandleFxsChannelMessage(UNetConnection* Connection, INT MessageType, class FInBunch& Bunch);

	static INT NativeSyncRand(INT iMax);

	virtual UBOOL FindBlueprintSwap(AXComBlueprint* Blueprint, FString& BlueprintMapToSwapIn);

	virtual void CrashDump(FCrashDumpArchive &Ar);

	virtual void ActorDestroyedHandler(AActor* ActorBeingDestroyed);

	// Creates and initializes the template manager objects. Static so that the editor engine can
	// resuse this function, rather than have to duplicate it both places and have a virtual on UEngine
	static void CreateTemplateManagers(UEngine& Engine);
	static void ValidateTemplates(UEngine& Engine);

	void CreatePhotoboothTextures();

	void SendInitialTelemetry();

	virtual void RenderExtraSubtitles();

	virtual void ResetCharacterPool();		// called by LoadMap under dire, gonna crash circumstances
}

/**
 * Accessor for setting the value of CurrentDeviceID
 *
 * @param	NewDeviceID			the new value to set CurrentDeviceID to
 * @param	bProfileSignedOut	Controls whether the previous value of CurrentDeviceID is considered; specify TRUE when setting
 *								CurrentDeviceID to an invalid value as a result of a profile being signed out and
 *								bHasSelectedValidStorageDevice will be reset to FALSE.
 */
native final function SetCurrentDeviceID( int NewDeviceID, optional bool bProfileSignedOut );


/**
* Wrapper for checking whether saving user content (checkpoints, screenshots) to a storage device is allowed.
*
* @param	bIgnoreDeviceStatus		specify TRUE to skip checking whether saving to a storage device is actually possible.
*
* @return	TRUE if saving checkpoint data and screenshots (and any other profile-specific content) is allowed.
*/
event bool AreStorageWritesAllowed( optional bool bIgnoreDeviceStatus, optional int RequiredSize=MAX_DATASIZE_FOR_ALL_SAVEGAMES )
{
	return	bShouldWriteCheckpointToDisk && (bIgnoreDeviceStatus || IsCurrentDeviceValid(RequiredSize));
}


/**
 * Wrapper for checking whether a previously selected storage device has been removed.
 *
 * @return	TRUE if the currently selected device is invalid but bHasSelectedValidStorageDevice is TRUE.
 */
native final function bool HasStorageDeviceBeenRemoved() const;

/**
 * Returns GCurrentTime
 */
static native final function float GetCurrentTime() const;


/**
 * Checks whether the currently selected device is valid (i.e. connected, has enough space, etc.)
 *
 * @param	SizeNeeded	optionally specify a minimum size that must be available on the device.
 *
 * @return	TRUE if the current device is valid and contains enough space.
 */
event bool IsCurrentDeviceValid( optional int SizeNeeded )
{
	local OnlineSubsystem OnlineSub;
	local bool bResult;

	OnlineSub = GetOnlineSubsystem();
	if ( OnlineSub != None && OnlineSub.PlayerInterfaceEx != None )
	{
		bResult = OnlineSub.PlayerInterfaceEx.IsDeviceValid(CurrentDeviceID, SizeNeeded);
	}

	return bResult;
}

/**
 * Accessor for getting the value of CurrentDeviceID
 */
native final function int GetCurrentDeviceID() const;

native function Object GetContentManager();

native function Object GetProfileSettings();

//Returns the state object cache from Temp history. TempHistory should only ever be used locally, never stored.
native function XComGameState LatestSaveState(out XComGameStateHistory TempHistory);

native function string GetShellMap();

native function SetAllowMovieInput(bool bAllowInput);  //Toggles whether a movie can be skipped or not

function CreateProfileSettings()
{
	XComProfileSettings = new(self) class'XComOnlineProfileSettings';
}

//Triggers the load of streaming maps that support the 'base' maps in X-Com. 
//Routes to XComMapManager, which decides which parcels, rooms, cinematic maps, etc. need to be loaded
native function SeamlessTravelDetermineAdditionalMaps();

//In situations where additional content loading is asynchronous, the async process can use this polling function to find out if 
//loading is done
native function bool SeamlessTravelSignalStageComplete();

static native function SetSeamlessTraveled(bool bSeamlessTraveled);

static native function bool IsPointInTriangle( const out Vector vP, const out Vector vA, const out Vector vB, const out Vector vC ) const;

function AddMCPEventListener(XComMCPEventListener Listener)
{
	if(MCPEventListeners.Find(Listener) == -1)
	{
		MCPEventListeners.AddItem(Listener);
		if(MCPManager != none)
		{
			MCPManager.AddEventListener(Listener);
			if(MCPManager.eInitStatus != EMCPIS_NotInitialized)
			{
				// MCP has already been initialized then we need to fire off the event to let this listener know. -tsmith
				Listener.OnMCPInitialized(MCPManager.eInitStatus);
			}
		}
	}
}

function RemoveMCPEventListener(XComMCPEventListener Listener)
{
	MCPEventListeners.RemoveItem(Listener);
	MCPManager.RemoveEventListener(Listener);
}

function RedScreen( string ErrorString )
{
	`assert(m_RedScreenManager != none);
	if (m_RedScreenManager != none)
	{
		m_RedScreenManager.AddRedScreen(ErrorString);
	}
}

function RedScreenOnce(string ErrorString)
{
	`assert(m_RedScreenManager != none);
	if (m_RedScreenManager != none)
	{
		m_RedScreenManager.AddRedScreenOnce(ErrorString);
	}
}

// until the next level load
function TemporarilyDisableRedscreens()
{
	m_RedScreensTemporarilyDisabled = true;
}

event BuildLocalization()
{
	LocalizeContext = new(self) class'XGLocalizeContext';

	ParamTag    = new(self) class'XGParamTag';
	LocalizeContext.LocalizeTags.AddItem(ParamTag);

	BulletTag   = new(self) class'XGBulletTag';
	LocalizeContext.LocalizeTags.AddItem(BulletTag);

	ObjectTag   = new(self) class'X2ObjectTag';
	LocalizeContext.LocalizeTags.AddItem(ObjectTag);

	AbilityTag  = new(self) class'X2AbilityTag';
	LocalizeContext.LocalizeTags.AddItem(AbilityTag);

	MetricTag	= new(self) class'X2MetricTag';
	LocalizeContext.LocalizeTags.AddItem(MetricTag);

	PhotoboothTag = new(self) class'X2PhotoboothTag';
	LocalizeContext.LocalizeTags.AddItem(PhotoboothTag);
}


static native function XComSoundEmitter FindSoundEmitterForParticleSystem(ParticleSystemComponent Component);

// jboswell: bOverrideAll should only be true when working around fullscreen movies
static native final function AddStreamingTextureSlaveLocation(vector Loc, rotator Rot, float Duration, bool bOverrideAll=false);

native function SetEnableAllLightsInLevel(Level kLevel, bool bEnable);

static native function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData);
static native function EventListenerReturn OnTacticalPlayBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData);
static native function EventListenerReturn OnTacticalPlayEnded(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData);

// helper accessors for uci calls (to avoid spamming logs with tons of none references when casts fail)
static function XComHQPresentationLayer GetHQPres()
{
	local XComHeadquartersGame HeadquartersGame;

	HeadquartersGame = XComHeadquartersGame(class'XComEngine'.static.GetCurrentWorldInfo().Game);
	return HeadquartersGame != none ? XComHQPresentationLayer(XComHeadquartersController(HeadquartersGame.PlayerController).Pres) : none;
}

event RegisterForAutoTestEvents()
{
	local Object thisObject;

	thisObject = self;

	EventManager.RegisterForEvent(thisObject, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted, 50, , true);
	EventManager.RegisterForEvent(thisObject, 'OnTacticalBeginPlay', OnTacticalPlayBegun, ELD_OnStateSubmitted, 50, , true);
	//EventManager.RegisterForEvent(thisObject, 'TacticalGameEnd', OnTacticalPlayEnded, ELD_OnStateSubmitted, 50, , true);

	EventManager.RegisterForEvent(thisObject, 'EndBattle', OnTacticalPlayEnded, ELD_OnStateSubmitted, 50, , true);

}

// DANGEROUS - HANDLE WITH EXTREME CARE
static native function PauseGC();
static native function UnpauseGC();

defaultproperties
{
	// Start Issue #511
	OnlineEventMgrClassName = "XComGame.CHOnlineEventMgr"
	// End Issue #511
	m_iSeedOverride = 0

	m_RedScreensTemporarilyDisabled = false;
}

