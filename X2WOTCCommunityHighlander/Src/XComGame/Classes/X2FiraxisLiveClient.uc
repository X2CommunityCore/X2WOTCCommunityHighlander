//---------------------------------------------------------------------------------------
//  FILE:    X2FiraxisLiveClient.uc
//  AUTHOR:  Timothy Talley  --  02/16/2015
//  PURPOSE: Bridge between the Firaxis Live and Unreal
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2FiraxisLiveClient extends object
	inherits(FTickableObject, FCallbackEventDevice)
	implements(X2ChallengeModeInterface)
	dependson(X2ChallengeModeDataStructures)
	native(Online);

// Used in my2KNotifications.h, update appropriately
enum EFiraxisLiveAccountType
{
	E2kAT_Unknown,
	E2kAT_Anonymous,
	E2kAT_Full,
	E2kAT_Platform
};

// Used in my2KNotifications.h, update appropriately
enum ELoginStatusType
{
	E2kLT_Login, 
	E2kLT_SilentLogin, 
	E2kLT_CreateAccount, 
	E2kLT_Logout, 
	E2kLT_PlatformLogin, 
	E2kLT_LinkAccount, 
	E2kLT_UnLinkAccount,
	E2kLT_UpgradeAccount
};

// Used in my2KNotifications.h, update appropriately
enum ELoginType 
{
	EFLC_Full, 
	EFLC_FullSilent, 
	EFLC_Platform
};

// used in my2kCore.h, update appropriately
enum EStatusType
{
	E2kST_Unknown,						// this should never happen, if it does check logs.
	E2kST_Offline,						// my2K is offline. 
	E2kST_OfflineBanned,				// The system has blocked this application. 
	E2kST_OfflineBlocked,				// User was denied access to my2K services by the doorman. 
	E2kST_OfflineRejectedWhitelist,		// User was denied access via a white list. 
	E2kST_OfflineRejectedCapacity,		// The my2K service is at capacity. 
	E2kST_OfflineLegalAccepted,			// The system is offline, but legal has been accepted. 
	E2kST_OfflineLoggedInCached,		// The system is offline, but the user's is logged in from cached data. 
	E2kST_LoggedInDoormanOffline,		// The system is offline, but the user had logged in before going offline
	E2kST_Online,						// The system is online and functioning normally.
	E2kST_OnlineLoggedIn				// The system is online and a user is logged in. 
};

enum KVPScope
{
	eKVPSCOPE_USER,
	eKVPSCOPE_GLOBAL,
	eKVPSCOPE_USERANDGLOBAL
};

// used in IFiraxisLive.h, update appropriately
enum EGUIDType
{
	EGUID_GUID64,
	EGUID_GUID64ASCII,
	EGUID_GUID128,
	EGUID_GUID128ASCII,
	EGUID_GUID256,
	EGUID_GUID256ASCII 
};

// used in flClient\States.h, update appropriately
enum EFLClientStateType
{
	EFLCST_Stopped,						// nothing to do so we are stopped.
	EFLCST_PreRun,						// set set after connect, before FirstConnect or Running
	EFLCST_Running,						// we are running.
	EFLCST_FirstConnect,				// this state is set upon the first connection to FiraxisLive
	EFLCST_WaitingForServerConnection,	// waiting for connection to server to complete
	EFLCST_KeyExchange,					// exchanging keys
	EFLCST_ShutDown,					// we have shutdown because too many errors
	EFLCST_Retry						// in retry mode, attempting to reconnect to servers
};


//matches Document struct in X2FiraxisLiveClient_CallbackBridge::My2KLegalNotify::Notify
struct native LegalDocuments
{
	var int ID;
	var string Title;
	var string UID;
	var string DocumentText;
};

struct native MOTDMessageData
{
	var string MessageType;
	var string Message;
};

struct native MOTDData
{
	var string Category;
	var array<MOTDMessageData> Messages;
};

`DeclareAddClearDelegatesArray(ConnectionStatus);
`DeclareAddClearDelegatesArray(ConnectionFailure);
`DeclareAddClearDelegatesArray(LogonData);
`DeclareAddClearDelegatesArray(LoginStatus);
`DeclareAddClearDelegatesArray(LogonUser);
`DeclareAddClearDelegatesArray(LogoffUser);
`DeclareAddClearDelegatesArray(ClientStateChange);
`DeclareAddClearDelegatesArray(CreateNewAccount);
`DeclareAddClearDelegatesArray(DOBData);
`DeclareAddClearDelegatesArray(LegalInfo);

`DeclareAddClearDelegatesArray(ReceivedChallengeModeIntervalStart);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeIntervalEnd);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeIntervalEntry);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeDeactivatedIntervalStart);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeDeactivatedIntervalEnd);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeDeactivatedIntervalEntry);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeSeed);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeLeaderboardStart);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeLeaderboardEnd);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeLeaderboardEntry);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeGetEventMapData);
`DeclareAddClearDelegatesArray(ReceivedChallengeModePostEventMapData);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeClearInterval);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeClearSubmitted);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeClearAll);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeGetGameSave);
`DeclareAddClearDelegatesArray(ReceivedChallengeModePostGameSave);
`DeclareAddClearDelegatesArray(ReceivedChallengeModeValidateGameScore);

`DeclareAddClearDelegatesArray(ReceivedMOTD);
`DeclareAddClearDelegatesArray(ReceivedStatsKVP);

var native pointer X2FiraxisLiveCallbackBridge{class X2FiraxisLiveClient_CallbackBridge};

var qword bizSessionId;
var private EFiraxisLiveAccountType CurrentAccountType;
var private bool bAccountLoggedIn;
var private bool bDeclinedEULAs;
var private bool bFirstClientInitCalled;
var private bool bInitialEngineTelemetrySent;
var private EFLClientStateType LastState; // Received from ClientStateChange

var private X2FiraxisLiveClient LiveClient;

var bool bCHEATDisableAutoLogin;
var array<MOTDData> CachedMOTDData;

native function StatSetValue(name Key, int Value, KVPScope Scope);
native function StatAddValue(name Key, int Value, KVPScope Scope);
native function StatSubValue(name Key, int Value, KVPScope Scope);

native function AnalyticsGameTutorialCompleted();
native function AnalyticsGameTutorialExited();
native function AnalyticsGameProgress(string AchievementName, float pctComplete);

native function BizAnalyticsGameStart( string CampaignID, string GameMode, int Difficulty, bool Ironman );
native function BizAnalyticsGameEnd( string CampaignID, bool GameSuccess );
native function BizAnalyticsMissionStart( string CampaignID, string MissionID, string MissionType, string MissionName, int Difficulty, int TeamSize,
											int NumSpecialists, int NumRangers, int NumSharpshooters, int NumGrenadiers, int NumPsiOps, int NumSparkMECS,
											int NumSkirmishers, int NumReapers, int NumTemplars, int NumVolunteers, int NumDoubleAgents,
											int NumRookies, int NumStoryCharacters, int NumVIPS, int NumUnknown );
native function BizAnalyticsMissionEnd( string CampaignID, string MissionID, int EnemiesKilled, int CiviliansRescued, int NumUninjuredSoldiers, int TurnCount, string Grade, string Status, string StatusReason );
native function BizAnalyticsGameProgressv2( string CampaignID, string MilestoneName, int TimeToDays );
native function BizAnalyticsMPStart( string SessionID, string GameMode, string Map, string TeamMakeup );
native function BizAnalyticsMPEnd( string SessionID, int TurnCount, bool IsWinner, bool IsCompleted );

native function BizAnalyticsLadderStart( string CampaignID, int LadderID, bool NewLadder, int Difficulty, string SquadID );
native function BizAnalyticsLadderEnd( string CampaignID, int LadderID, int Score, int Medal, string SquadID, int Difficulty );
native function BizAnalyticsLadderUpgrade( string CampaignID, string Choice1, string Choice2, int Choice );

native function string GetGUID( EGUIDType Type = EGUID_GUID128ASCII );

cpptext
{
	void Init();

	void SendTelemetryData(class FTelemetryData& Data);

	void SendFileData(const FString& FileName, const void* Data, INT Size);

	void FlushTelemetryData();
//
// FTickableObject interface
//
	/**
	 * Returns whether it is okay to tick this object. E.g. objects being loaded in the background shouldn't be ticked
	 * till they are finalized and unreachable objects cannot be ticked either.
	 *
	 * @return	TRUE if tickable, FALSE otherwise
	 */
	virtual UBOOL IsTickable() const;
	/**
	 * Used to determine if an object should be ticked when the game is paused.
	 *
	 * @return always TRUE as networking needs to be ticked even when paused
	 */
	virtual UBOOL IsTickableWhenPaused() const;
	/**
	 * Just calls the tick event
	 *
	 * @param DeltaTime The time that has passed since last frame.
	 */
	virtual void Tick(FLOAT DeltaTime);

	virtual void ShutdownAfterError();


//
// FCallbackEventDevice interface
//
	/**
	 * Called for notifications that require no additional information.
	 */
	virtual void Send( ECallbackEventType InType );

// Biz intelligence functions
	UINT AnalyticsSessionStart();
	UBOOL AnalyticsSessionStop();

	void AnalyticsGameMovie(const TCHAR *videoName, DOUBLE watchTime, DOUBLE FullLengthTime);
	void AnalyticsGameProgressSaved(const TCHAR *fileName, const char *gameMode, const char *gameStage, bool isNewFile);

	//virtual bool AnalyticsGameLobbyStats(bool inParty, bool useMicrophone, int64 waitTimeMilliseconds, int64 pingTimeMilliseconds = -1, const char *action = NULL) = 0;
	//virtual bool AnalyticsGameMatch(int64 waitingMilliseconds, int64 retriesOccured, int64 pingTimeMilliseconds = -1, const char *action = NULL, const char *resultMessage = NULL, const char *metaData = NULL) = 0;
	//virtual bool AnalyticsGameTutorialCompleted(const char *tutorialID, bool completed, int64 elapsedTimeMilliseconds, int64 replayCount) = 0;
	//virtual bool AnalyticsGameUITrigger(const char *uiSectionName, const char *uiElement, const char *uiAction, int64 elapsedTimeMilliseconds = -1, const char *metaData = NULL) = 0;
	//virtual bool AnalyticsGameProgress(const char *item, const char *itemid, const char *type, int64 elapsedTimeMilliseconds = -1, const char *metaData = NULL) = 0;

	bool ChallengeModeSetValidateToken(const char* token);
	bool ChallengeModeGetValidateData();
	bool ChallengeModeGetStartState(const char* keyName);
	bool ChallengeModePostValidateResult(unsigned __int64 verifyID, bool success);

private:
	FString GetLangauge();
};

event Init()
{
	local OnlinePlayerInterface PlayerInterface;
	
	// Start variables for issue #412
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	// End variables for issue #412

	`log(`location);
	AddLoginStatusDelegate(InternalStateHandler_OnLoginStatus);

	PlayerInterface = class'Engine'.static.GetOnlineSubsystem().PlayerInterface;
	PlayerInterface.AddRetrieveEncryptedAppTicketDelegate(OnRetrieveEncryptedAppTicketComplete);

	LiveClient = `FXSLIVE;

	// Start issue #412
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.OnPreCreateTemplates();
	}
	// End issue #412
}

native function OnRetrieveEncryptedAppTicketComplete(bool bWasSuccessful, array<byte> EncryptedTicket);

/**
 * FirstClientInit - Called whenever the UIFinalShell gets to the first User Input, basically saying that the system is ready to handle requests.
 */
native function FirstClientInit();

event Tick( float fDeltaT )
{
}

function UserEULAs(bool bAccepted)
{
	if( bAccepted )
	{
		bDeclinedEULAs = false;
	}
	else
	{
		// TODO: Perhaps save this preference in the profile so they don't have to decline every time? @ttalley
		bAccountLoggedIn = false;
		bDeclinedEULAs = true;
	}
}

function bool HasDeclinedUserEULAs()
{
	return bDeclinedEULAs;
}

private function InternalStateHandler_OnLoginStatus(ELoginStatusType Type, EFiraxisLiveAccountType Account, string Message, bool bSuccess)
{
	`log(`location @ `ShowVar(CurrentAccountType) @ `ShowVar(bAccountLoggedIn) @ `ShowEnum(ELoginStatusType, Type, Type) @ `ShowEnum(EFiraxisLiveAccountType, Account, Account) @ `ShowVar(Message) @ `ShowVar(bSuccess),,'FiraxisLive');

	switch( Account )
	{
	case E2kAT_Anonymous:
	case E2kAT_Platform:
	case E2kAT_Full:
		if( bSuccess )
		{
			CurrentAccountType = Account;
		}
		break;
	default:
		break;
	}

	switch(Type)
	{
	case E2kLT_Logout:
		bAccountLoggedIn = false;
		break;
	case E2kLT_CreateAccount:
	case E2kLT_SilentLogin:
	case E2kLT_Login:
	case E2kLT_PlatformLogin:
	case E2kLT_UnLinkAccount:
	case E2kLT_LinkAccount:
	case E2kLT_UpgradeAccount:
		bAccountLoggedIn = true;
		break;
	default:
		break;
	}
}

function bool IsAutoLoginDisabled()
{
	return bCHEATDisableAutoLogin;
}

function bool IsAccountLoggedOut()
{
	return CurrentAccountType == E2kAT_Unknown;
}

function bool IsAccountAnonymous()
{
	return CurrentAccountType == E2kAT_Anonymous;
}

function bool IsAccountPlatform()
{
	return CurrentAccountType == E2kAT_Platform;
}

function bool IsAccountFull()
{
	return CurrentAccountType == E2kAT_Full;
}

//---------------------------------------------------------------------------------------
//  System Functionality
//---------------------------------------------------------------------------------------
function bool ChallengeModeInit()
{
	return true;
}

function bool ChallengeModeShutdown()
{
	// Clear out all Delegates!
	`ClearDelegatesArray(ConnectionStatus);
	`ClearDelegatesArray(ConnectionFailure);
	`ClearDelegatesArray(LogonData);
	`ClearDelegatesArray(LoginStatus);
	`ClearDelegatesArray(LogonUser);
	`ClearDelegatesArray(LogoffUser);

	`ClearDelegatesArray(ReceivedChallengeModeIntervalStart);
	`ClearDelegatesArray(ReceivedChallengeModeIntervalEnd);
	`ClearDelegatesArray(ReceivedChallengeModeIntervalEntry);
	`ClearDelegatesArray(ReceivedChallengeModeDeactivatedIntervalStart);
	`ClearDelegatesArray(ReceivedChallengeModeDeactivatedIntervalEnd);
	`ClearDelegatesArray(ReceivedChallengeModeDeactivatedIntervalEntry);
	`ClearDelegatesArray(ReceivedChallengeModeSeed);
	`ClearDelegatesArray(ReceivedChallengeModeLeaderboardStart);
	`ClearDelegatesArray(ReceivedChallengeModeLeaderboardEnd);
	`ClearDelegatesArray(ReceivedChallengeModeLeaderboardEntry);
	`ClearDelegatesArray(ReceivedChallengeModeGetEventMapData);
	`ClearDelegatesArray(ReceivedChallengeModePostEventMapData);
	`ClearDelegatesArray(ReceivedChallengeModeClearInterval);
	`ClearDelegatesArray(ReceivedChallengeModeClearSubmitted);
	`ClearDelegatesArray(ReceivedChallengeModeClearAll);
	`ClearDelegatesArray(ReceivedChallengeModeGetGameSave);
	`ClearDelegatesArray(ReceivedChallengeModePostGameSave);
	`ClearDelegatesArray(ReceivedChallengeModeValidateGameScore);

	`ClearDelegatesArray(ReceivedMOTD);
	`ClearDelegatesArray(ReceivedStatsKVP);

	return true;
}

native function bool ChallengeModeLoadGameData(array<byte> GameData, optional int SaveGameID=-1);

function bool RequiresSystemLogin()
{
	return false;
}

static function string GetSystemLoginUIClassName()
{
	return "XComGame.UIFiraxisLiveLogin";
}

static function bool IsDebugMenuEnabled()
{
	return false;
}

function bool OpenUserEULAs()
{
	return LiveClient.UpgradeAccount();
}



//---------------------------------------------------------------------------------------
//  Client States
//---------------------------------------------------------------------------------------
native function EStatusType GetStatus();
native function bool IsTokenCached();
native function bool IsAccountLinked();
native function bool IsConnected();
native function bool IsLoggedIn();
native function bool IsBusy();
native function bool IsReady();

delegate OnClientStateChange(string StateName);
`AddClearDelegates(ClientStateChange);



//---------------------------------------------------------------------------------------
//  Connection Status
//---------------------------------------------------------------------------------------
/**
 * Received whenever the login process is completed
 */
delegate OnConnectionStatus(string Title, string Message, string OkLabel);
`AddClearDelegates(ConnectionStatus);

/**
 * Tells the server that the user has responded to the connection status message
 */
native function bool RespondConnectionStatus();



//---------------------------------------------------------------------------------------
//  Connection Failure
//---------------------------------------------------------------------------------------
/**
 * Received whenever the connection has an issue
 */
delegate OnConnectionFailure(string Reason);
`AddClearDelegates(ConnectionFailure);



//---------------------------------------------------------------------------------------
//  Login Functionality
//---------------------------------------------------------------------------------------
/**
 * Sync Call returns the Current Login State of the User
 */
native function ELoginState GetLoginState();

/**
 * Requests that the server start the login sequence
 */
native function bool StartLoginRequest(ELoginType LoginType=EFLC_Platform);

/**
 * Upgrades the current E2kAT_Anonymous account type to E2kAT_Platform account type. The
 * only known difference right now is the acceptance of EULAs / TOS, which should be
 * displayed after this is called.
 */
native function bool UpgradeAccount();

/**
 * Cancels the Login Request
 */
native function bool CancelLoginRequest();

/**
 * Received whenever the System is ready for the user to respond to the incoming login
 */
delegate OnLogonData(string Title, string Message, string EMailLabel, string PasswordLabel, string OkLabel, string CancelLabel, string CreateLabel, bool Error);
`AddClearDelegates(LogonData);

/**
 * Received whenever the login (on, off, create) attempt comes back
 */
delegate OnLoginStatus(ELoginStatusType Type, EFiraxisLiveAccountType Account, string Message, bool bSuccess);
`AddClearDelegates(LoginStatus);



//---------------------------------------------------------------------------------------
//  Login User
//---------------------------------------------------------------------------------------
/**
 * Attempts to log the user into the system
 */
native function bool LogonUser(string Username, string Password);

/**
 * Received whenever the user is attempting to login ... Currently being handled by 
 * the OnConnectionStatus callback.
 */
delegate OnLogonUser(string Title, string Message, string OkLabel);
`AddClearDelegates(LogonUser);



//---------------------------------------------------------------------------------------
//  Logoff User
//---------------------------------------------------------------------------------------
/**
 * Attempts to logoff the user from the system
 */
native function bool LogoffUser();

/**
 * Received whenever the user is logged off ... not sure where from at the moment, but is
 * not called whenever the LogoffUser command is issued; that instead goes to the 
 * LoginStatus callback.
 */
delegate OnLogoffUser(string Title, string Message, string OkLabel);
`AddClearDelegates(LogoffUser);



//---------------------------------------------------------------------------------------
//  Create New Account
//---------------------------------------------------------------------------------------
/**
 * Initiates the creation of a new account, a multi-step process.
 */
native function StartNewAccount();

/**
 * Received when a new account is ready to be created.
 */
delegate OnCreateNewAccount(string Title, string Message, string EmailLabel, string OkLabel, string CancelLabel, bool Error);
`AddClearDelegates(CreateNewAccount);

/**
 * Response to OnCreateNewAccount to continue or cancel; if TRUE, OnDOBData will be triggered.
 */
native function CreateNewAccount(bool bContinue, string EMail);

/**
 * Will be triggered after CreateNewAccount(true) is called.
 */
delegate OnDOBData(string Title, string Message, string DoBLabel, string OkLabel, string CancelLabel, array<string> MonthNames, bool Error);
`AddClearDelegates(DOBData);

/**
 * Response to OnDOBData to set information to continue or cancel; if TRUE, OnLegalInfo will be triggered.
 */
native function SetDOBData(bool bContinue, int Month, int Day, int Year);

/**
 * Will be triggered after SetDOBData(true) is called.
 */
delegate OnLegalInfo(string Title, string Message, string AgreeLabel, string AgreeAllLabel, string DisagreeLabel, string DisagreeAllLabel, string ReadLabel, array<LegalDocuments> EULAs);
//delegate OnLegalInfo(string Title, string Message, string AgreeLabel, string AgreeAllLabel, string DisagreeLabel, string DisagreeAllLabel, string ReadLabel, array<string> DocumentNames, array<string> DocumentIds, array<string> DocumentText);
`AddClearDelegates(LegalInfo);

/**
 * Response to OnLegalInfo by accepting or declining documents.
 */
native function RespondLegal(array<string> AcceptedDocumentIds, array<string> DeclinedDocumentIds);



//---------------------------------------------------------------------------------------
//  Link Account
//---------------------------------------------------------------------------------------
/**
 * Call this to start the Linking process
 */
native function bool StartLinkAccount();

/**
 * Links the platform account to a new user or an existing account (must specify Password)
 */
native function bool LinkAccount(bool bNewUser, string EMail, optional string Password="");

/**
 * Must call if a successful LinkAccount does not occur (OnLogonData w/ Success) and user is attempting to exit the screen.
 */
native function bool CancelLinkAccount();

/**
 * Calls a one-time unlink function, which has no follow-up.
 */
native function bool UnlinkAccount();

//---------------------------------------------------------------------------------------
//	Get Stats KVP information
//---------------------------------------------------------------------------------------

native function bool GetStats( optional KVPScope Scope = eKVPSCOPE_GLOBAL, optional string Filter );

delegate OnReceivedStatsKVP( bool Success, array<string> GlobalKeys, array<int> GlobalValues, array<string> UserKeys, array<int> UserValues );
`AddClearDelegates(ReceivedStatsKVP);

//---------------------------------------------------------------------------------------
//  Get Seed Intervals
//---------------------------------------------------------------------------------------
/**
 * Requests data on all of the intervals
 */
native function bool PerformChallengeModeGetIntervals(optional bool bGetSeedData=true);

/**
* Received when the intervals comes back from the server
*
* @param NumIntervals, total number of intervals to expect
*/
delegate OnReceivedChallengeModeIntervalStart(int NumIntervals);
`AddClearDelegates(ReceivedChallengeModeIntervalStart);

/**
* Called once all of the interval entries have been processed
*/
delegate OnReceivedChallengeModeIntervalEnd();
`AddClearDelegates(ReceivedChallengeModeIntervalEnd);

/**
 * Received when the Challenge Mode data has been read.
 * 
 */
delegate OnReceivedChallengeModeIntervalEntry(qword IntervalSeedID, int ExpirationDate, int TimeLength, EChallengeStateType IntervalState, string IntervalName, array<byte> StartState);
`AddClearDelegates(ReceivedChallengeModeIntervalEntry);


//---------------------------------------------------------------------------------------
//  Get Deactivated Intervals
//---------------------------------------------------------------------------------------
/**
* Requests all of the deactivated intervals over the past number of specified days since today
*
* @param NumberDaysPrior, number of days to search through for deactivated intervals
*/
native function bool PerformChallengeModeGetDeactivatedIntervals(optional int NumberDaysPrior = 90);

/**
* Received when the deactivated intervals comes back from the server
*
* @param NumIntervals, total number of intervals to expect
*/
delegate OnReceivedChallengeModeDeactivatedIntervalStart(int NumIntervals);
`AddClearDelegates(ReceivedChallengeModeDeactivatedIntervalStart);

/**
* Called once all of the deactivated intervals entries have been processed
*/
delegate OnReceivedChallengeModeDeactivatedIntervalEnd();
`AddClearDelegates(ReceivedChallengeModeDeactivatedIntervalEnd);

/**
* Received when the Challenge Mode data has been read.
*/
delegate OnReceivedChallengeModeDeactivatedIntervalEntry(qword IntervalSeedID, int ExpirationDate, int TimeLength, EChallengeStateType IntervalState, string IntervalName);
`AddClearDelegates(ReceivedChallengeModeDeactivatedIntervalEntry);


//---------------------------------------------------------------------------------------
//  Get Seed
//---------------------------------------------------------------------------------------
/**
 * Requests the Challenge Mode Seed from the server for the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeGetSeed(qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param LevelSeed, seed shared among all challengers to populate the map, aliens, etc.
 * @param PlayerSeed, seed specific to the player to randomize the shots so they are unable to "plan" via YouTube.
 * @param TimeLimit, amount of time before the seed expires.
 * @param StartTime, amount of time in seconds from Epoch to when the Seed was distributed the first time.
 * @param GameScore, positive values indicate the final result of a finished interval.
 */
delegate OnReceivedChallengeModeSeed(int LevelSeed, int PlayerSeed, int TimeLimit, qword StartTime, int GameScore);
`AddClearDelegates(ReceivedChallengeModeSeed);



//---------------------------------------------------------------------------------------
//  Get Challenge Mode Leaderboard (CURRENTLY UNSUPPORTED BY FiraxisLive)
//---------------------------------------------------------------------------------------
/**
* Requests the Leaderboard from the server
*
* @param ChallengeKeyname, the name of the challenge to retrieve
* @param Offset, retrieves entries starting at the specified offset (0=top)
* @param Limit, only return this number of entries (top 10, 4, etc)
*/
native function bool PerformChallengeModeGetTopGameScores(string ChallengeKeyname, optional int Offset = 0, optional int Limit = 10);
native function bool PerformChallengeModeGetGameScoresFriends(string ChallengeKeyname, const array<string> PlatformFriendIDs);

/**
 * Received when the Challenge Mode data has been download and processing is ready to occur.
 * 
 * @param NumEntries, total number of board entries to expect
 */
delegate OnReceivedChallengeModeLeaderboardStart(int NumEntries, qword IntervalSeedID);
`AddClearDelegates(ReceivedChallengeModeLeaderboardStart);


/**
 * Called once all of the leaderboard entries have been processed
 */
delegate OnReceivedChallengeModeLeaderboardEnd(qword IntervalSeedID);
`AddClearDelegates(ReceivedChallengeModeLeaderboardEnd);


/**
* Received when the Challenge Mode data has been read.
*
* @param Entry, Struct filled with all the data incoming from the server
*/
delegate OnReceivedChallengeModeLeaderboardEntry(ChallengeModeLeaderboardData Entry);
`AddClearDelegates(ReceivedChallengeModeLeaderboardEntry);



//---------------------------------------------------------------------------------------
//  Get Event Map
//---------------------------------------------------------------------------------------
/**
 * Requests the Event Map Data for the challenge over the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeGetEventMapData(qword IntervalSeedID);

/**
 * Received when the Event Map data has been read.
 * 
 * @param IntervalSeedID, The associated Interval for the data
 * @param NumEvents, Number of registered events in the map data
 * @param NumTurns, Total number of moves per event
 * @param EventMap, Any array of integers representing the number of players that have completed the event, which is looked-up by index of EventType x TurnOccurred.
 */
delegate OnReceivedChallengeModeGetEventMapData(qword IntervalSeedID, int NumEvents, int NumTurns, array<INT> EventMap);
`AddClearDelegates(ReceivedChallengeModeGetEventMapData);



//---------------------------------------------------------------------------------------
//  Post Event Map
//---------------------------------------------------------------------------------------
/**
 * Submits all of the Event results for the played challenge
 */
native function bool PerformChallengeModePostEventMapData();

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModePostEventMapData(qword IntervalSeedID, bool bSuccess);
`AddClearDelegates(ReceivedChallengeModePostEventMapData);



//---------------------------------------------------------------------------------------
//  Clear Interval - Admin Server Request (CURRENTLY UNSUPPORTED BY FiraxisLive)
//---------------------------------------------------------------------------------------
/**
 * Clears all of the submitted and attempted Challenge Results over the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeClearInterval(qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearInterval(qword IntervalSeedID, bool bSuccess);
`AddClearDelegates(ReceivedChallengeModeClearInterval);



//---------------------------------------------------------------------------------------
//  Clear Submitted - Admin Server Requests (CURRENTLY UNSUPPORTED BY FiraxisLive)
//---------------------------------------------------------------------------------------
/**
 * Clears all of the submitted and attempted Challenge Results over the specified interval 
 * for only the specified player.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeClearSubmitted(UniqueNetId PlayerID, qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearSubmitted(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess);
`AddClearDelegates(ReceivedChallengeModeClearSubmitted);



//---------------------------------------------------------------------------------------
//  Clear All - Admin Server Requests (CURRENTLY UNSUPPORTED BY FiraxisLive)
//---------------------------------------------------------------------------------------
/**
 * Performs a full clearing of all user generated data.
 *
 */
native function bool PerformChallengeModeClearAll();

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearAll(bool bSuccess);
`AddClearDelegates(ReceivedChallengeModeClearAll);



//---------------------------------------------------------------------------------------
//  Get Game Save (CURRENTLY UNSUPPORTED BY FiraxisLive)
//---------------------------------------------------------------------------------------
/**
 * Retrieves the stored save of the submitted game for the specified player and interval
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeGetGameSave(UniqueNetId PlayerID, qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param PlayerName, Name to show on the leaderboard
 * @param IntervalSeedID, Specifies the entry's leaderboard (since there may be multiple days worth of leaderboards)
 * @param LevelSeed, Seed used for the level generation
 * @param PlayerSeed, Seed specific for that player
 * @param TimeLimit, Time allowed to play the level
 * @param GameScore, Value of the entry
 * @param TimeStart, Epoch time in UTC whenever the player first started the challenge
 * @param TimeEnd, Epoch time in UTC whenever the player finished the challenge
 * @param GameData, History data for replay / validation
 */
delegate OnReceivedChallengeModeGetGameSave(UniqueNetId PlayerID, string PlayerName, qword IntervalSeedID, int LevelSeed, int PlayerSeed, int TimeLimit, int GameScore, qword TimeStart, qword TimeEnd, array<byte> GameData);
`AddClearDelegates(ReceivedChallengeModeGetGameSave);



//---------------------------------------------------------------------------------------
//  Post Game Save
//---------------------------------------------------------------------------------------
/**
 * Submits the completed Challenge game to the server for validation and scoring
 * 
 */
native function bool PerformChallengeModePostGameSave();

/**
 * Response for the posting of completed game
 * 
 * @param Status, Response from the server
 */
delegate OnReceivedChallengeModePostGameSave(EChallengeModeErrorStatus Status);
`AddClearDelegates(ReceivedChallengeModePostGameSave);



//---------------------------------------------------------------------------------------
//  Validate Game Score (CURRENTLY UNSUPPORTED BY FiraxisLive)
//---------------------------------------------------------------------------------------
/**
 * Processes the loaded game for validity and submits the score to the server as a 
 * validated score.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param LevelSeed, Seed used for the level generation
 * @param PlayerSeed, Seed specific for that player
 * @param TimeLimit, Time allowed to play the level
 * @param GameScore, Value of the entry
 * @param GameData, History data for replay / validation
 */
native function bool PerformChallengeModeValidateGameScore(UniqueNetId PlayerID, int LevelSeed, int PlayerSeed, int TimeLimit, int GameScore, array<byte> GameData);

/**
 * Response for validating a game score
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, Specifies the entry's leaderboard (since there may be multiple days worth of leaderboards)
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeValidateGameScore(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess);
`AddClearDelegates(ReceivedChallengeModeValidateGameScore);


//---------------------------------------------------------------------------------------
//  Message Of The Day
//---------------------------------------------------------------------------------------
/**
 * Will attempt to trigger the associated callbacks by requesting the information from 
 * the server, or using cached data. A return of FALSE means the request & cached data is
 * not available and a backup should be considered.
 * 
 * @param Category, Filters based on the Data Notification's "KeyName"
 * @param MessageType, Further filters based on the list of message's "KeyName" attached to the category
 * @return True if a request is sent or the cache already exists
 */
native function bool GetMOTD(optional string Category, optional string MessageType);
delegate OnReceivedMOTD(string Category, array<MOTDMessageData> Messages);
`AddClearDelegates(ReceivedMOTD);


defaultproperties
{
	bDeclinedEULAs=false
	bFirstClientInitCalled=false
}