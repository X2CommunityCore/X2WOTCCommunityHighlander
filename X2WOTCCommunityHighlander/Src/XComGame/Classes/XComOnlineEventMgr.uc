//---------------------------------------------------------------------------------------
//  FILE:    XComOnlineEventMgr.uc
//  AUTHOR:  Ryan McFall  --  08/17/2011
//  PURPOSE: This object is designed to contain the various callbacks and delegates that
//           respond to online systems changes such as login/logout, storage device selection,
//           controller changes, and others
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComOnlineEventMgr extends OnlineEventMgr
	dependson(UI_Definitions)
	dependson(UIDialogueBox)
	dependson(UIProgressDialogue)
	native;

enum EOnlineStatusType
{
	OnlineStatus_MainMenu,
	OnlineStatus_InGameSP,
	OnlineStatus_InRankedMP,
	OnlineStatus_InUnrankedMP
};

const LowestCompatibleCheckpointVersion = 21;
const CheckpointVersion = 22;
const StorageRemovalWarningDelayTime = 1.0; // needed to prevent us from showing this on the very first frame if we pulled the storage device during load

struct native TMPLastMatchInfo_Player
{
	var UniqueNetId     m_kUniqueID;
	var bool            m_bMatchStarted;
	var int             m_iWins;
	var int             m_iLosses;
	var int             m_iDisconnects;
	var int             m_iSkillRating;
	var int             m_iRank;

	structdefaultproperties
	{
		m_bMatchStarted = false;
		m_iWins = -1;
		m_iLosses = -1;
		m_iDisconnects = -1;
		m_iSkillRating = -1;
		m_iRank = -1;
	}
};

struct native TMPLastMatchInfo
{
	var bool                        m_bIsRanked;
	var bool                        m_bAutomatch;
	var int                         m_iMapPlotType;
	var int                         m_iMapBiomeType;
	var EMPNetworkType              m_eNetworkType;
	var EMPGameType                 m_eGameType;
	var int                         m_iTurnTimeSeconds;
	var int                         m_iMaxSquadCost;
	var TMPLastMatchInfo_Player     m_kLocalPlayerInfo;
	var TMPLastMatchInfo_Player     m_kRemotePlayerInfo;
};

var TMPLastMatchInfo                m_kMPLastMatchInfo;

var Engine LocalEngine;
var XComMCP MCP;
var X2FiraxisLiveClient FiraxisLiveClient;
var XComCopyProtection CopyProtection;
var XComOnlineStatsReadDeathmatchRanked m_kStatsRead;
var XComPlayerController m_kStatsReadPlayerController;
var privatewrite bool m_bStatsReadInProgress;
var privatewrite bool m_bStatsReadSuccessful;

var privatewrite int     StorageDeviceIndex;
var privatewrite string  StorageDeviceName;
var privatewrite bool    bHasStorageDevice;
var privatewrite bool    bStorageSelectPending;
var privatewrite bool    bLoginUIPending;
var privatewrite bool    bSaveDeviceWarningPending;
var privatewrite float   fSaveDeviceWarningPendingTimer; // to wait a few frames before showing the message, makes sure we don't show it the very first frame before things look decent
var privatewrite bool    bInShellLoginSequence;
var privatewrite bool    bExternalUIOpen;
var privatewrite bool    bUpdateSaveListInProgress;
var bool                 bWarnedOfOnlineStatus;
var bool                 bWarnedOfOfflineStatus;
var bool                 bAcceptedInviteDuringGameplay;

// Login Requirements
var privatewrite bool    bRequireLogin;
var privatewrite bool    bAllowInactiveProfiles;

var privatewrite bool          bOnlineSubIsSteamworks;
var privatewrite bool          bOnlineSubIsPSN;
var privatewrite bool          bOnlineSubIsLive;
var privatewrite ELoginStatus  LoginStatus;	
var privatewrite bool          bHasLogin;
var privatewrite bool          bHasProfileSettings;
var privatewrite bool          bShowingLoginUI;
var privatewrite bool          bShowingLossOfDataWarning;
var privatewrite bool          bShowingLoginRequiredWarning;
var privatewrite bool          bShowingLossOfSaveDeviceWarning;
var privatewrite bool          bShowSaveIndicatorForProfileSaves;
var privatewrite bool          bCancelingShellLoginDialog;
var privatewrite bool          bMCPEnabledByConfig;
var privatewrite bool          bSaveDataOwnerErrHasShown;
var privatewrite bool          bSaveDataOwnerErrPending;
var privatewrite bool          bDelayDisconnects;
var privatewrite bool          bDisconnectPending;
var privatewrite bool          bConfigIsUpToDate;

var privatewrite EOnlineStatusType OnlineStatus;

var privatewrite bool			bProfileDirty; //Marks profile as needing to be saved. Used for deferred saving, preventing multiple requests from issuing multiple tasks in a single frame.
var privatewrite bool			bForceShowSaveIcon; //Saved option for deferred profile saving, indiciating if SaveIcon needs to be shown.

var bool bSaveExplanationScreenHasShown;
var private int                m_iCurrentGame;

var bool bPerformingStandardLoad;       //True when loading a normal saved game - ie. from player storage
var int  LoadGameContentCacheIndex;     //Index in the content cache to use during a standard load
var bool bPerformingTransferLoad;       //True when loading a strategy game from 'StrategySaveData', ie when going from a tactical game to the strategy
var init array<byte> TransportSaveData; //Stores the transport save blob for going between strategy & tactical
var init array<byte> StrategySaveData;  //Stores the strategy save blob while we are in a tactical game
var int StrategySaveDataCheckpointVersion; //Saves the version of the checkpoint system used to create the strategy save date blob
var init array<byte> SaveLoadBuffer;    //Scratch for loading / saving

//This flag is set to true when loading a saved game via the replay option, and cleared when that load is cancelled, or the load succeeds and the replay system is activated
var bool bInitiateReplayAfterLoad;
var bool bInitiateValidationAfterLoad;	//Start the validator after loading the map.
var bool bIsChallengeModeGame;			//True if this game is started from Challenge Mode.
var int  ChallengeModeSeedGenNum;		//Greater than 0 is auto-generating Challenge Start State #
var bool bGenerateMapForSkirmish;
var bool bIsLocalChallengeModeGame;

// Campaign Settings to pass to Strategy Start after the tutorial
var string CampaignStartTime;
var int CampaignDifficultySetting;
var int CampaignLowestDifficultySetting;
var float CampaignTacticalDifficulty;
var float CampaignStrategyDifficulty;
var float CampaignGameLength;
var bool CampaignbIronmanEnabled;
var bool CampaignbTutorialEnabled;
var bool CampaignbXPackNarrativeEnabled;
var bool CampaignbIntegratedDLCEnabled;
var bool CampaignbSuppressFirstTimeNarrative;
var array<name> CampaignSecondWaveOptions;
var array<name> CampaignRequiredDLC;
var array<name> CampaignOptionalNarrativeDLC;

var bool bTutorial;  // Actively running the tutorial in Demo Direct mode using the replay system
var bool bDemoMode;	// Demo mode uses the Tutorial Code path but doesn't not draw helper markers
var bool bAutoTestLoad;

//A stable of checkpoints used for nefarious purposes.
var Checkpoint CurrentTacticalCheckpoint; //Holds a currently loading tactical checkpoint, for the purposes of bringing in kismet at a point later 
										  //than when the actors are serialized in. USED FOR LOADING

var bool CheckpointIsSerializing;
var bool CheckpointIsWritingToDisk;
var bool ProfileIsSerializing;
var Checkpoint StrategyCheckpoint;        //These hold a checkpoint that is currently being saved - the saving process happens asynchronously, so
var Checkpoint TacticalCheckpoint;	      //the online event mgr holds a reference until the save is done
var Checkpoint TransportCheckpoint;
var XComGameState SummonSuperSoldierGameState;
var XComGameState_Unit ConvertedSoldierState;

var private bool bAchivementsEnabled;
var bool bAchievementsDisabledXComHero;     // Achievements have been disabled because we are using an easter egg XCom Hero

var private int DLCWatchVarHandle;

var localized string	m_strSkirmishFormatString;
var localized string	m_strLadderFormatString;
var localized string    m_strIronmanFormatString;
var localized string	m_strAutosaveTacticalFormatString;
var localized string	m_strAutosaveStrategyFormatString;
var localized string	m_strQuicksaveTacticalFormatString;
var localized string	m_strQuicksaveStrategyFormatString;
var localized string    m_strIronmanLabel;
var localized string    m_strAutosaveLabel;
var localized string    m_strQuicksaveLabel;
var localized string    m_strGameLabel;
var localized string    m_strSaving;
var localized string    m_sLoadingProfile;
var localized string    m_sLossOfDataTitle;
var localized string    m_sLossOfDataWarning;
var localized string    m_sLossOfDataWarning360;
var localized string    m_sNoStorageDeviceSelectedWarning;
var localized string    m_sLoginWarning;
var localized string    m_sLoginWarningPC;
var localized string    m_sLossOfSaveDeviceWarning;
var localized string    m_strReturnToStartScreenLabel;
var localized string    m_sInactiveProfileMessage;
var localized string    m_sLoginRequiredMessage;
var localized string    m_sCorrupt;
var localized string	m_sXComHeroSummonTitle;
var localized string	m_sXComHeroSummonText;
var localized string    m_sSaveDataOwnerErrPS3;
var localized string    m_sSaveDataHeroErrPS3;
var localized string    m_sSaveDataHeroErr360PC;
var localized string    m_sSlingshotDLCFriendlyName;
var localized string    m_sEliteSoldierPackDLCFriendlyName;
var localized string    m_sEmptySaveString;
var localized string	m_sCampaignString;

// My2K status messages
var localized string My2k_Offline;
var localized string My2k_Link;
var localized string My2k_Unlink;

// Used by the UI to allow players to provide a custom save description
var private string m_sCustomSaveDescription;

var			string m_sReplayUserID;
var			string m_sLastReplayMapCommand;

// Rich Presence Strings
var localized string m_aRichPresenceStrings[EOnlineStatusType]<BoundEnum=EOnlineStatusType>;

var privatewrite ELoginStatus m_eNewLoginStatusForDestroyOnlineGame_OnLoginStatusChange;
var privatewrite UniqueNetId  m_kNewIdForDestroyOnlineGame_OnLoginStatusChange;

var private array< delegate<ShellLoginComplete> > m_BeginShellLoginDelegates;
var private array< delegate<SaveProfileSettingsComplete> > m_SaveProfileSettingsCompleteDelegates;
var private array< delegate<UpdateSaveListStarted> >  m_UpdateSaveListStartedDelegates;
var private array< delegate<UpdateSaveListComplete> > m_UpdateSaveListCompleteDelegates;
var private array< delegate<OnlinePlayerInterface.OnLoginStatusChange> > m_LoginStatusChangeDelegates;
var private array< delegate<OnConnectionProblem> > m_ConnectionProblemDelegates;
var private array< delegate<OnSaveDeviceLost> > m_SaveDeviceLostDelegates;

// Challenge Mode Data
var array<INT>          m_ChallengeModeEventMap;

// cached array of DLCs
var bool m_bCheckedForInfos;
var array<X2DownloadableContentInfo> m_cachedDLCInfos;


// Helper function for dealing with pre localized dates
native static function bool ParseTimeStamp(String TimeStamp, out int Year, out int Month, out int Day, out int Hour, out int Minute);

//External delegates
//==================================================================================================================

//Delegates for external users - ie. the UI wants to know when something finishes
delegate SaveProfileSettingsComplete(bool bWasSuccessful);
delegate UpdateSaveListStarted();
delegate UpdateSaveListComplete(bool bWasSuccessful);
delegate ReadSaveGameComplete(bool bWasSuccessful);
delegate WriteSaveGameComplete(bool bWasSuccessful);
delegate ShellLoginComplete(bool bWasSuccessful); // Called when the shell login sequence has completed
delegate OnConnectionProblem();
delegate OnSaveDeviceLost();


//Initialization
//==================================================================================================================

event Init()
{
	super.Init();

	LocalEngine = class'Engine'.static.GetEngine();

	bOnlineSubIsLive       = OnlineSub.Class.Name == 'OnlineSubsystemLive';
	bOnlineSubIsSteamworks = OnlineSub.Class.Name == 'OnlineSubsystemSteamworks';
	bOnlineSubIsPSN        = OnlineSub.Class.Name == 'OnlineSubsystemPSN';

	//Handle the editor / PIE case
	if(OnlineSub == none)
	{
		bOnlineSubIsSteamworks = true;
	}

	// Profile saves on Xbox 360 take less than 500 ms so we don't need a save indicator per TCR 047.
	// Showing the indicator when we don't need to actually causes more bugs because of timing requirements.
	// On other platforms we show the save indicator because it is a better user experience.
	bShowSaveIndicatorForProfileSaves = false;//!class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360);

	// Login Requirements

	// We require the user to be logged into a gamer profile on Xbox 360
	bRequireLogin = class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360);

	// There has been a lot of debate about whether or not logins should be
	// allowed on inactive controllers. We ultimately decided they should
	// be but if the decision changes all we need to do is change this bool.
	bAllowInactiveProfiles = true;

	// On PC subscribe to read profile settings early so we can check our input settings before the shell login sequence
	if( !class'WorldInfo'.static.IsConsoleBuild() )
	{
		// Set the initial state of the controller
		super.SetActiveController(0);

		OnlineSub.PlayerInterface.AddReadProfileSettingsCompleteDelegate(LocalUserIndex, ReadProfileSettingsCompleteDelegate);
		OnlineSub.PlayerInterface.AddReadPlayerStorageCompleteDelegate(LocalUserIndex, ReadPlayerStorageCompleteDelegate);
	}
}

function EvalName(XComGameState_Unit TestUnit)
{
	local name SuperSoldierID;
	local int SoldierIndex;

	if(`GAME != none && TestUnit.IsSoldier() && TestUnit.GetMyTemplateName() == 'Soldier')
	{
		if(TestUnit.GetFirstName() == "Sid" && TestUnit.GetLastName() == "Meier")
		{
			SuperSoldierID = 'Sid';
		}
		else if(TestUnit.GetNickName(true) == "Beaglerush")
		{
			SuperSoldierID = 'Beagle';
		}
		else if(TestUnit.GetFirstName() == "Peter" && TestUnit.GetLastName() == "Van Doorn")
		{
			SuperSoldierID = 'Peter';
		}

		if(SuperSoldierID != '')
		{
			for(SoldierIndex = 0; SoldierIndex < class'UITacticalQuickLaunch_MapData'.default.Soldiers.Length; ++SoldierIndex)
			{
				if(class'UITacticalQuickLaunch_MapData'.default.Soldiers[SoldierIndex].SoldierID == SuperSoldierID)
				{
					PromptSummonSuperSoldier(class'UITacticalQuickLaunch_MapData'.default.Soldiers[SoldierIndex], TestUnit);
					break;
				}
			}
		}
	}
}

//Transform a regular soldier into a super soldier
function PromptSummonSuperSoldier(ConfigurableSoldier SoldierConfig, XComGameState_Unit ExistingSoldier)
{
	local StateObjectReference SuperSoldierRef;

	SummonSuperSoldierGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Make Super Soldier");
	ConvertedSoldierState = XComGameState_Unit(SummonSuperSoldierGameState.ModifyStateObject(ExistingSoldier.Class, ExistingSoldier.ObjectID));
	ConvertedSoldierState.bIsSuperSoldier = true;
	
	//Change the existing soldier in the the selected super soldier
	//****************************************************************
	ConvertedSoldierState.SetSoldierClassTemplate(SoldierConfig.SoldierClassTemplate);
	SuperSoldier_UpdateUnit(SoldierConfig, ConvertedSoldierState, SummonSuperSoldierGameState);
	if(ConvertedSoldierState.GetMyTemplate().RequiredLoadout != '')
	{
		ConvertedSoldierState.ApplyInventoryLoadout(SummonSuperSoldierGameState, ConvertedSoldierState.GetMyTemplate().RequiredLoadout);
	}
	SuperSoldier_AddFullInventory(SoldierConfig, SummonSuperSoldierGameState, ConvertedSoldierState);
	//****************************************************************

	//Submit the change
	`XCOMGAME.GameRuleset.SubmitGameState(SummonSuperSoldierGameState);

	SuperSoldierRef = ConvertedSoldierState.GetReference();
	
	`HQPRES.GetPhotoboothAutoGen().AddHeadShotRequest(SuperSoldierRef, 512, 512, ShowSuperSoldierAlert);
	`HQPRES.GetPhotoboothAutoGen().RequestPhotos();
}

private simulated function ShowSuperSoldierAlert(StateObjectReference UnitRef)
{
	local Texture2D StaffPicture;
	local XComGameState_CampaignSettings SettingsState;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	StaffPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, UnitRef.ObjectID, 512, 512);

	`HQPRES.SuperSoldierAlert(UnitRef, SuperSoldierAlertCB, class'UIUtilities_Image'.static.ValidateImagePath(PathName(StaffPicture)));
}

simulated function SuperSoldier_AddFullInventory(ConfigurableSoldier SoldierConfig, XComGameState GameState, XComGameState_Unit Unit)
{
	// Add inventory
	Unit.bIgnoreItemEquipRestrictions = true;
	Unit.MakeItemsAvailable(GameState, false); // Drop all of their existing items
	Unit.EmptyInventoryItems(); // Then delete whatever was still in their inventory
	SuperSoldier_AddItemToUnit(GameState, Unit, SoldierConfig.PrimaryWeaponTemplate);
	SuperSoldier_AddItemToUnit(GameState, Unit, SoldierConfig.SecondaryWeaponTemplate);
	SuperSoldier_AddItemToUnit(GameState, Unit, SoldierConfig.ArmorTemplate);
	SuperSoldier_AddItemToUnit(GameState, Unit, SoldierConfig.HeavyWeaponTemplate);
	SuperSoldier_AddItemToUnit(GameState, Unit, SoldierConfig.GrenadeSlotTemplate);
	SuperSoldier_AddItemToUnit(GameState, Unit, SoldierConfig.UtilityItem1Template);
	SuperSoldier_AddItemToUnit(GameState, Unit, SoldierConfig.UtilityItem2Template);
	Unit.bIgnoreItemEquipRestrictions = false;
}

simulated function SuperSoldier_AddItemToUnit(XComGameState NewGameState, XComGameState_Unit Unit, name EquipmentTemplateName)
{
	local XComGameState_Item ItemInstance;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(EquipmentTemplateName));

	if(EquipmentTemplate != none)
	{
		ItemInstance = EquipmentTemplate.CreateInstanceFromTemplate(NewGameState);
		Unit.AddItemToInventory(ItemInstance, EquipmentTemplate.InventorySlot, NewGameState);
	}
}

simulated function SuperSoldier_UpdateUnit(ConfigurableSoldier SoldierConfig, XComGameState_Unit Unit, XComGameState UseGameState)
{
	local TSoldier Soldier;
	local int Index;
	local SCATProgression Progression;
	local array<SCATProgression> SoldierProgression;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2SoldierClassTemplate UnitSoldierClassTemplate;
	local X2CharacterTemplate CivilianTemplate;//Get super soldier bios from the civilian character template
	local string RedScreenMsg;

	CivilianTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Civilian');

	Soldier.kAppearance = Unit.kAppearance;
	if(SoldierConfig.SoldierID == 'Sid')
	{
		Soldier.kAppearance.nmPawn = 'XCom_Soldier_M';
		Soldier.kAppearance.iGender = 1;
		Soldier.kAppearance.nmHead = 'Supersoldier1_M';
		Soldier.kAppearance.nmHelmet = 'Helmet_0_NoHelmet_M';
		Soldier.kAppearance.nmHaircut = 'SidMeier_Hair';
		Soldier.kAppearance.nmBeard = 'MaleBeard_Blank';
		Soldier.kAppearance.nmEye = 'DefaultEyes';
		Soldier.kAppearance.nmTeeth = 'DefaultTeeth';
		Soldier.kAppearance.nmFacePropLower = 'Prop_FaceLower_Blank';
		Soldier.kAppearance.nmFacePropUpper = 'Prop_FaceUpper_Blank';
		Soldier.kAppearance.nmPatterns = 'Hex';
		Soldier.kAppearance.nmVoice = 'MaleVoice4_English_US';
		Soldier.kAppearance.nmTorso_Underlay = 'CnvUnderlay_Std_Torsos_A_M';
		Soldier.kAppearance.nmArms_Underlay = 'CnvUnderlay_Std_Arms_A_M';
		Soldier.kAppearance.nmLegs_Underlay = 'CnvUnderlay_Std_Legs_A_M';
		Unit.SetCharacterName(Unit.GetFirstName(), Unit.GetLastName(), "Godfather");
		Unit.SetCountry('Country_USA');
		Unit.SetBackground(CivilianTemplate.strCharacterBackgroundMale[0]);
		
	}
	else if(SoldierConfig.SoldierID == 'Beagle')
	{
		Soldier.kAppearance.nmPawn = 'XCom_Soldier_M';
		Soldier.kAppearance.iGender = 1;
		Soldier.kAppearance.nmHead = 'Supersoldier2_M';
		Soldier.kAppearance.nmHelmet = 'Helmet_0_NoHelmet_M';
		Soldier.kAppearance.nmHaircut = 'Beaglerush_Hair';
		Soldier.kAppearance.nmBeard = 'Beard_Beaglerush';
		Soldier.kAppearance.nmEye = 'DefaultEyes';
		Soldier.kAppearance.nmTeeth = 'DefaultTeeth';
		Soldier.kAppearance.iHairColor = 10;
		Soldier.kAppearance.nmFacePropLower = 'Prop_FaceLower_Blank';
		Soldier.kAppearance.nmFacePropUpper = 'Prop_FaceUpper_Blank';
		Soldier.kAppearance.nmPatterns = 'Camo_Digital';
		Soldier.kAppearance.nmVoice = 'MaleVoice1_English_UK';
		Soldier.kAppearance.nmTorso_Underlay = 'CnvUnderlay_Std_Torsos_A_M';
		Soldier.kAppearance.nmArms_Underlay = 'CnvUnderlay_Std_Arms_A_M';
		Soldier.kAppearance.nmLegs_Underlay = 'CnvUnderlay_Std_Legs_A_M';
		Unit.SetCharacterName("John", "Teasdale", Unit.SafeGetCharacterNickName());
		Unit.SetCountry('Country_Australia');
		Unit.SetBackground(CivilianTemplate.strCharacterBackgroundMale[1]);
	}
	else if(SoldierConfig.SoldierID == 'Peter')
	{
		Soldier.kAppearance.nmPawn = 'XCom_Soldier_M';
		Soldier.kAppearance.iGender = 1;
		Soldier.kAppearance.nmHead = 'Supersoldier3_M';
		Soldier.kAppearance.nmArms = 'PwrLgt_Std_D_M';
		Soldier.kAppearance.nmHelmet = 'Helmet_0_NoHelmet_M';
		Soldier.kAppearance.nmHaircut = 'VanDoorn_Hair';
		Soldier.kAppearance.nmBeard = 'ShortFullBeard';
		Soldier.kAppearance.nmEye = 'DefaultEyes';
		Soldier.kAppearance.nmTeeth = 'DefaultTeeth';
		Soldier.kAppearance.nmFacePropLower = 'Prop_FaceLower_Blank';
		Soldier.kAppearance.nmFacePropUpper = 'Prop_FaceUpper_Blank';
		Soldier.kAppearance.nmPatterns = 'Tigerstripe';
		Soldier.kAppearance.iTattooTint = 5;
		Soldier.kAppearance.iHairColor = 1;		
		Soldier.kAppearance.nmTattoo_LeftArm = 'Tattoo_Arms_05';
		Soldier.kAppearance.nmTattoo_RightArm = 'Tattoo_Arms_09';
		Soldier.kAppearance.nmVoice = 'MaleVoice9_English_US';
		Soldier.kAppearance.nmTorso_Underlay = 'CnvUnderlay_Std_Torsos_A_M';
		Soldier.kAppearance.nmArms_Underlay = 'CnvUnderlay_Std_Arms_A_M';
		Soldier.kAppearance.nmLegs_Underlay = 'CnvUnderlay_Std_Legs_A_M';
		Unit.SetCountry('Country_USA');		
		Unit.SetBackground(CivilianTemplate.strCharacterBackgroundMale[2]);
	}

	Unit.SetTAppearance(Soldier.kAppearance);
	Unit.SetSoldierClassTemplate(SoldierConfig.SoldierClassTemplate);
	Unit.ResetSoldierRank();
	for(Index = 0; Index < SoldierConfig.SoldierRank; ++Index)
	{
		Unit.RankUpSoldier(UseGameState, SoldierConfig.SoldierClassTemplate);
	}
	Unit.bNeedsNewClassPopup = false;
	UnitSoldierClassTemplate = Unit.GetSoldierClassTemplate();

	for(Progression.iRank = 0; Progression.iRank < UnitSoldierClassTemplate.GetMaxConfiguredRank(); ++Progression.iRank)
	{
		AbilityTree = Unit.GetRankAbilities(Progression.iRank);
		for(Progression.iBranch = 0; Progression.iBranch < AbilityTree.Length; ++Progression.iBranch)
		{
			if(SoldierConfig.EarnedClassAbilities.Find(AbilityTree[Progression.iBranch].AbilityName) != INDEX_NONE)
			{
				SoldierProgression.AddItem(Progression);
			}
		}
	}

	if(SoldierConfig.EarnedClassAbilities.Length != SoldierProgression.Length)
	{
		RedScreenMsg = "Soldier '" $ SoldierConfig.SoldierID $ "' has invalid ability definition: \n-> Configured Abilities:";
		for(Index = 0; Index < SoldierConfig.EarnedClassAbilities.Length; ++Index)
		{
			RedScreenMsg = RedScreenMsg $ "\n\t" $ SoldierConfig.EarnedClassAbilities[Index];
		}
		RedScreenMsg = RedScreenMsg $ "\n-> Selected Abilities:";
		for(Index = 0; Index < SoldierProgression.Length; ++Index)
		{
			AbilityTree = Unit.GetRankAbilities(SoldierProgression[Index].iRank);
			RedScreenMsg = RedScreenMsg $ "\n\t" $ AbilityTree[SoldierProgression[Index].iBranch].AbilityName;
		}
		`RedScreen(RedScreenMsg);
	}

	Unit.SetSoldierProgression(SoldierProgression);
	Unit.SetBaseMaxStat(eStat_UtilityItems, 2);
	Unit.SetCurrentStat(eStat_UtilityItems, 2);
}

simulated function SuperSoldierAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	switch(eAction)
	{
		case 'eUIAction_Accept':
			class'UICustomize'.static.CycleToSoldier(ConvertedSoldierState.GetReference());
			EnableAchievements(false, true);

			// If the soldier was staffed in a training slot, unstaff them and stop the project
			if (ConvertedSoldierState.StaffingSlot.ObjectID != 0)
			{
				ConvertedSoldierState.GetStaffSlot().EmptySlotStopProject();
			}
			break;
		case 'eUIAction_Cancel':
			History.ObliterateGameStatesFromHistory(1); //Undo if the user doesn't want this
			break;
	}
}


//Internal delegates
//==================================================================================================================

/** Called when a user signs in or out */
private simulated function LoginChangeDelegate(byte LocalUserNum)
{	
	local ELoginStatus InactiveUserLoginStatus;

	`log("LoginChange: " @`ShowVar(LocalUserNum) @ `ShowVar(OnlineSub.PlayerInterface.GetLoginStatus(LocalUserNum), LoginStatus) @ `ShowVar((OnlineSub.PlayerInterface.GetLoginStatus(LocalUserNum) != LS_NotLoggedIn), bHasLogin) , true, 'XCom_Online');

	if( LocalUserIndex == LocalUserNum )
	{
		RefreshLoginStatus();

		if( bInShellLoginSequence )
		{
			if( bShowingLossOfDataWarning )
			{
				// User logged in while the loss of data
				// warning simply was up.  Cancel the
				// dialog and jump back to the user login
				// phase of the shell login sequence.
				CancelActiveShellLoginDialog();
				ShellLoginUserLoginComplete();
			}
			else if( bShowingLoginRequiredWarning )
			{
				// User logged in while Login Required dialog
				// was up. Cancel the dialog and jump back to
				// the user login phase of the shell login sequence.
				CancelActiveShellLoginDialog();
				ShellLoginUserLoginComplete();
			}
			else if( bHasProfileSettings )
			{
				// User loggin changed at an unexpected time before
				// the shell login sequence could complete
				`log("Shell Login Failed: User login changed before completion.",,'XCom_Online');
				AbortShellLogin();
			}
			else
			{
				// User logged in at the expected time
				// in the shell login sequence.
				ShellLoginUserLoginComplete();
			}
		}
		else if( bHasProfileSettings )
		{
			`log("Login Changed",,'XCom_Online');

			// The user changed during gameplay.
			// Kick them back to the start screen.
			ReturnToStartScreen(QuitReason_SignOut);
		}
	}
	else
	{
		InactiveUserLoginStatus = OnlineSub.PlayerInterface.GetLoginStatus(LocalUserNum);
		if( InactiveUserLoginStatus != LS_NotLoggedIn )
		{
			if( bInShellLoginSequence && bShowingLoginUI )
			{
				// If an inactive profile chooses a login during the shell login sequence
				// then restart the login with that controller as active.
				`log("Shell Login: Restarting Shell Login Sequence. Inactive controller logged in.",,'XCom_Online');

				bInShellLoginSequence = false;
				BeginShellLogin(LocalUserNum);
			}
			else if( !bAllowInactiveProfiles && bHasProfileSettings )
			{
				// If inactive profiles are not allow then make sure that none are signed in
				ReturnToStartScreen(QuitReason_InactiveUser);
			}
		}
	}

	bShowingLoginUI = false;
}

function bool SaveInProgress()
{
	return ProfileIsSerializing || CheckpointIsSerializing;
}

/** Called if a user is prompted to log in but cancels */
private function LoginCancelledDelegate()
{
	`log("Login Cancelled",,'XCom_Online');

	bShowingLoginUI = false;

	RefreshLoginStatus();

	if( bInShellLoginSequence )
	{
		ShellLoginUserLoginComplete();
	}
}

/**
 * Delegate called when a player's status changes but doesn't change profiles
 *
 * @param NewStatus the new login status for the user
 * @param NewId the new id to associate with the user
 */
private simulated function LoginStatusChange(ELoginStatus NewStatus, UniqueNetId NewId)
{
	local OnlineGameSettings kGameSettings;
	`log(`location @ `ShowVar(NewStatus) @ `ShowVar(LocalUserIndex) @ "UniqueId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(NewId), true, 'XCom_Online');
	if(OnlineSub != none && OnlineSub.GameInterface != none && OnlineSub.GameInterface.GetGameSettings('Game') != none)
	{
		// Is this a LAN Game Settings, and is it a host?  At which point we should ignore the destruction. -ttalley
		// BUG 21959: [ONLINE] - The host will be unable to successfully host or join a System Link/LAN match after the client disconnects their ethernet cable from a previous System Link/LAN match.
		kGameSettings = OnlineSub.GameInterface.GetGameSettings('Game');
		if ( (kGameSettings == none) || ((kGameSettings != none) && (! kGameSettings.bIsLanMatch)) )
		{
			`log(`location @ "An online game settings exists, destroying before continuing...", true, 'XCom_Online');
			OnlineSub.GameInterface.AddDestroyOnlineGameCompleteDelegate(OnDestroyOnlineGameComplete_LoginStatusChange);
			if(OnlineSub.GameInterface.DestroyOnlineGame('Game'))
			{
				m_eNewLoginStatusForDestroyOnlineGame_OnLoginStatusChange = NewStatus;
				m_kNewIdForDestroyOnlineGame_OnLoginStatusChange = NewId;
				`log(`location @ "Successfully created async task DestroyOnlineGame, waiting...", true, 'XCom_Online');
				return;
			}
			else
			{
				OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyOnlineGameComplete_LoginStatusChange);
				`warn(`location @ "Failed to create async task DestroyOnlineGame!");
			}
		}
		else
		{
			`warn(`location @ "Problem with the Login Status, there is a LAN match running, so we are not destroying the game session!", true, 'XCom_Online');
		}
	}

	RefreshLoginStatus();

	if( bOnlineSubIsPSN && bInShellLoginSequence && bShowingLoginUI ) 
	{//The PS3 is trying to complete a shell login and the player is also trying to log into the PSN.  
		//We got a LoginStatusChange because we're logged into the PSN and can proceed.
		//This situation occurs when a player accepted a cross game invite while logged out of the PSN.  
		//NOTE: We need this special case because we don't use LoginChangeDelegates on the PS3 because 
		//it doesn't care about local user profiles.  (Instead, everything is associated with the user's PSN account)

		ShellLoginUserLoginComplete(); 
		bShowingLoginUI = false; 
	} 

	if( MCP != none )
	{
		// Only enable the MCP if we have an online profile and the config allows it.
		MCP.bEnableMcpService = bMCPEnabledByConfig && LoginStatus == LS_LoggedIn;
	}

	if( bHasLogin )
	{
		RequestLoginFeatures();
	}

	// Route the event to our listeners. While it may seem odd to route this event through
	// the OnlineEventMgr it removes the complexity of having to worry about tracking the
	// active user in systems other than the OnlineEventMgr.
	CallLoginStatusChangeDelegates(NewStatus, NewId);
}

private simulated function OnDestroyOnlineGameComplete_LoginStatusChange(name SessionName, bool bWasSuccessful)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyOnlineGameComplete_LoginStatusChange);
	LoginStatusChange(m_eNewLoginStatusForDestroyOnlineGame_OnLoginStatusChange, m_kNewIdForDestroyOnlineGame_OnLoginStatusChange);
}

simulated function RefreshLoginStatus()
{
	local OnlinePlayerInterface PlayerInterface;

	PlayerInterface = OnlineSub.PlayerInterface;
	if( PlayerInterface != none )
	{
		LoginStatus = PlayerInterface.GetLoginStatus(LocalUserIndex);
		bHasLogin = LoginStatus != LS_NotLoggedIn && !PlayerInterface.IsGuestLogin(LocalUserIndex);
	}
}

/** Called if a user logs out */
private function LogoutCompletedDelegate(bool bWasSuccessful)
{
	bHasLogin = false;
	bHasProfileSettings = false;
}

/** Called when a user has picked a storage device */
private function DeviceSelectionDoneDelegate(bool bWasSuccessful)
{
	local OnlinePlayerInterfaceEx PlayerInterfaceEx;
	PlayerInterfaceEx = OnlineSub.PlayerInterfaceEx;

	if( bInShellLoginSequence && bOnlineSubIsLive && !bHasLogin )
	{
		`log("Storage Device Selector Failed: Login lost while storage selector was up!",,'XCom_Online');
		return;
	}

	StorageDeviceIndex = PlayerInterfaceEx.GetDeviceSelectionResults(LocalUserIndex, StorageDeviceName);
	if( bWasSuccessful && (!bOnlineSubIsLive || PlayerInterfaceEx.IsDeviceValid(StorageDeviceIndex)) )
	{
		`log("Storage Device Selected" @ `ShowVar(LocalUserIndex) @ `ShowVar(StorageDeviceName) @ `ShowVar(StorageDeviceIndex),,'XCom_Online');

		bHasStorageDevice = true;

		UpdateSaveGameList();

		// Now that we've picked storage, try to find our profile settings		
		ReadProfileSettings();
	}
	else
	{
		`log("Storage Device Selection Failed" @ `ShowVar(LocalUserIndex) @ `ShowVar(StorageDeviceName),,'XCom_Online');

		StorageDeviceIndex = -1;
		StorageDeviceName = "";
		bHasStorageDevice = false;

		UpdateSaveGameList();

		if( bInShellLoginSequence )
		{
			CreateNewProfile();
		}
		else
		{
			LossOfDataWarning(m_sNoStorageDeviceSelectedWarning);
		}
	}
}

/** Called when a storage device has been added or removed. */
private simulated function StorageDeviceChangeDelegate()
{
	local OnlinePlayerInterfaceEx PlayerInterfaceEx;

	PlayerInterfaceEx = OnlineSub.PlayerInterfaceEx;
	if( bHasStorageDevice && PlayerInterfaceEx != none && !PlayerInterfaceEx.IsDeviceValid(StorageDeviceIndex) )
	{
		`log("Save Device Lost.",,'XCom_Online');
		CallSaveDeviceLostDelegates();
		LossOfSaveDevice();
	}
}

private simulated function ExternalUIChangedDelegate(bool bOpen)
{
	local XComEngine GameEngine;

	bExternalUIOpen = bOpen;

	GameEngine = XComEngine(LocalEngine);
	if( GameEngine != none && GameEngine.IsAnyMoviePlaying() )
	{
		if( bExternalUIOpen )
			GameEngine.PauseMovie();
		else
			GameEngine.UnpauseMovie();
	}

	if( bStorageSelectPending )
	{
		bStorageSelectPending = false;
		SelectStorageDevice();
	}

	if( bLoginUIPending )
	{
		bLoginUIPending = false;
		ShellLoginShowLoginUI();
	}
}

/** Called when a ReadAchievements operation has completed */
private function ReadAchievementsCompleteDelegate(int TitleId)
{
	local array<AchievementDetails> ArrTrophies;

	OnlineSub.PlayerInterface.ClearReadAchievementsCompleteDelegate(LocalUserIndex, ReadAchievementsCompleteDelegate);
	OnlineSub.PlayerInterface.GetAchievements(LocalUserIndex, ArrTrophies);
}

/** Called when a ReadPlayerStorage operation has completed */
private function ReadProfileSettingsCompleteDelegate(byte LocalUserNum,EStorageResult eResult)
{
	local XComOnlineProfileSettings ProfileSettings;
	local XComPresentationLayerBase Presentation;
	local TDialogueBoxData kData; 

	if( eResult == eSR_Success )
	{	
		`log("Profile Read Successful",,'XCom_Online');

		ReadProfileSettingsFromBuffer();

		ProfileSettings = `XPROFILESETTINGS;

		// If the mouse is not active but no gamepad controllers are availabe then switch back to mouse input
		if( !class'WorldInfo'.static.IsConsoleBuild() && !ProfileSettings.Data.IsMouseActive() && !GamepadConnected_PC() )
		{
			ProfileSettings.Data.ActivateMouse(true);
			ProfileSettings.Data.SetControllerIconType(eControllerIconType_Mouse);
		}

		// need to set on the player controller because in MP the server needs to know whether a mouse or controller pawn is spawned -tsmith 
		XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).SetIsMouseActive(ProfileSettings.Data.IsMouseActive());

		if( bInShellLoginSequence )
		{
			bHasProfileSettings = true;
			EndShellLogin();
		}

		ProfileSettings.PostLoadData();

		ProfileSettings.ApplyOptionsSettings();
	}
	else
	{
		`log("Profile Read Failed",,'XCom_Online');

		if(eResult == eSR_Corrupt)
		{
			// TCR 49/30 on 360: We must confirm the destruction of the corrupt profile data before actually
			// nuking it with the flaming justice of 1000 fiery suns
			kData.eType = eDialog_Warning;
			kData.isModal = true;
			kData.strTitle = m_sSystemMessageTitles[SystemMessage_CorruptedSave];
			kData.strText = m_sSystemMessageStrings[SystemMessage_CorruptedSave];
			kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
			kData.strCancel = class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360) ? m_strReturnToStartScreenLabel : "";
			kData.fnCallback = ConfirmCorruptProfileDestructionCallback;

			Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
			Presentation.UICloseProgressDialog();
			Presentation.UIRaiseDialog(kData);
		}
		else if( bInShellLoginSequence )
		{
			// Automatically create a new profile if a profile could not be read
			CreateNewProfile();
			`XPROFILESETTINGS.ApplyOptionsSettings();
		}
	}
}

private function ConfirmCorruptProfileDestructionCallback(Name Action)
{	
	if(Action == 'eUIAction_Accept')
	{
		CreateNewProfile();
		`XPROFILESETTINGS.ApplyOptionsSettings();
	}
	else if(class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360))
	{
		ReturnToStartScreen(QuitReason_UserQuit);
	}
}

private function ReadPlayerStorageCompleteDelegate(byte LocalUserNum, EStorageResult eResult)
{
	ReadProfileSettingsCompleteDelegate(LocalUserNum, eResult);
}

/** Called when a WritePlayerStorage operation has completed */
private function WriteProfileSettingsCompleteDelegate(byte LocalUserNum, bool bWasSuccessful)
{	
	local delegate<SaveProfileSettingsComplete> dSaveProfileSettingsComplete;

	// Don't show the save indicator for failed saves
	if( !bWasSuccessful )
	{
		HideSaveIndicator();
	}

	ProfileIsSerializing = false;

	foreach m_SaveProfileSettingsCompleteDelegates(dSaveProfileSettingsComplete)
	{
		dSaveProfileSettingsComplete(bWasSuccessful);
	}
}

private function WritePlayerStorageCompleteDelegate(byte LocalUserNum, bool bWasSuccessful)
{
	WriteProfileSettingsCompleteDelegate(LocalUserNum, bWasSuccessful);
}

private function OnUpdateSaveListComplete(bool bWasSuccessful)
{
	RefreshSaveIDs();
	bUpdateSaveListInProgress = false;
	CallUpdateSaveListCompleteDelegates(bWasSuccessful);
}

/** Update save IDs to match content list. */
native private function RefreshSaveIDs();

/** Ensure that the save IDs are correct */
native private function CheckSaveIDs(out array<OnlineSaveGame> SaveGames);

native private function OnReadSaveGameDataComplete(bool bWasSuccessful,byte LocalUserNum,int DeviceId,string FriendlyName,string FileName,string SaveFileName);

private function OnWriteSaveGameDataComplete(bool bWasSuccessful, byte LocalUserNum, int DeviceId, string FriendlyName, string FileName, string SaveFileName)
{
	// Don't show the save indicator for failed saves
	if( !bWasSuccessful )
	{
		HideSaveIndicator();
	}

	if( WriteSaveGameComplete != none )
	{
		WriteSaveGameComplete(bWasSuccessful);
		WriteSaveGameComplete = none;
	}

	OnSaveCompleteInternal( bWasSuccessful, LocalUserNum, DeviceId, FriendlyName, FileName, SaveFileName );
}

function UpdateCurrentGame(int iGame)
{
	m_iCurrentGame = iGame;
}

function int GetCurrentGame()
{
	return m_iCurrentGame;
}

/**
 * Messages the user about a Save Data owner error on PS3.
 * Only shows the message if it has not already shown.
 */
event ShowPostLoadMessages()
{
	local XComPresentationLayerBase Presentation;
	local TDialogueBoxData DialogData;
	local bool bShowDialog;
	local bool bIsPS3Build;

	bIsPS3Build = class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3);

	if( (bIsPS3Build && LoadedSaveDataFromAnotherUserPS3()) || !bAchivementsEnabled )
	{
		Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
		if( Presentation != none && Presentation.IsPresentationLayerReady() )
		{
			DialogData.eType = eDialog_Warning;
			if (bAchievementsDisabledXComHero)
			{
				bShowDialog = true;
				if( bIsPS3Build )
				{
					DialogData.strText = m_sSaveDataHeroErrPS3;
				}
				else
				{
					DialogData.strText = m_sSaveDataHeroErr360PC;
				}
			}
			else
			{
				if( bIsPS3Build )
				{
					bShowDialog = true;
					DialogData.strText = m_sSaveDataOwnerErrPS3;
				}
			}

			if( bShowDialog )
			{
				DialogData.strAccept = class'XComPresentationLayerBase'.default.m_strOK;
				Presentation.UIRaiseDialog(DialogData);

			}

			bSaveDataOwnerErrHasShown = true;
			bSaveDataOwnerErrPending = false;
		}
		else
		{
			bSaveDataOwnerErrPending = true;
		}
	}
}

//External interface
//==================================================================================================================

private function SetupDefaultProfileSettings()
{
	//Initialize the profile settings, these will be overwritten if we are able to load saved settings
	LocalEngine.CreateProfileSettings();	
	XComOnlineProfileSettings(LocalEngine.GetProfileSettings()).SetToDefaults();	
}

function AddBeginShellLoginDelegate( delegate<ShellLoginComplete> ShellLoginCompleteCallback )
{
	`log(`location @ `ShowVar(ShellLoginCompleteCallback), true, 'XCom_Online');
	if (m_BeginShellLoginDelegates.Find(ShellLoginCompleteCallback) == INDEX_None)
	{
		m_BeginShellLoginDelegates[m_BeginShellLoginDelegates.Length] = ShellLoginCompleteCallback;
	}
}

function ClearBeginShellLoginDelegate( delegate<ShellLoginComplete> ShellLoginCompleteCallback )
{
	local int i;

	`log(`location @ `ShowVar(ShellLoginCompleteCallback), true, 'XCom_Online');
	i = m_BeginShellLoginDelegates.Find(ShellLoginCompleteCallback);
	if (i != INDEX_None)
	{
		m_BeginShellLoginDelegates.Remove(i, 1);
	}
}

/** Begins the shell login sequence. Logs in as local user associated with Controller ID. */
function BeginShellLogin(int ControllerId)
{
	local delegate<ShellLoginComplete> dShellLoginComplete;

	if( bInShellLoginSequence )
	{
		`warn("Shell Login could not start: already started!",,'XCom_Online');
		foreach m_BeginShellLoginDelegates(dShellLoginComplete)
		{
			dShellLoginComplete(false);
		}
		return;
	}
	
	`log("Shell Login Started",,'XCom_Online');

	if( bHasProfileSettings )
		ResetLogin();

	bDelayDisconnects = false;
			
	bInShellLoginSequence = true;

	ClearScreenUI();

	//ShellLoginProgressMsg(m_sLoadingProfile);

	if( `ISCONTROLLERACTIVE() )
	{
		// Associate the correct controller
		SetActiveController(ControllerId);
	}

	// Initialize rich presence system
	InitRichPresence();

	// If inactive profiles are not allow then make sure that none are signed in
	if( !bAllowInactiveProfiles && CheckForInactiveProfiles() )
	{
		ShellLoginHandleInactiveProfiles();
		return;
	}

	if (CopyProtection == none)
	{
		`log("Creating protection object",,'XCom_Online');
		CopyProtection = new(self) class'XComCopyProtection';
	}

	InitializeDelegates();

	//////////////////////////////////////////////////////////////////
	//

	SetupDefaultProfileSettings();

	// Get MCP
	if( XComEngine(LocalEngine) != none && MCP == none )
	{
		MCP = XComEngine(LocalEngine).MCPManager;
		bMCPEnabledByConfig = MCP.bEnableMcpService;
	}

	// Get Firaxis Live
	if( FiraxisLiveClient == none )
	{
		EnableFiraxisLive();
	}

	RefreshLoginStatus();

	if( bOnlineSubIsLive && !bHasLogin )
	{	
		ShellLoginShowLoginUI(true);
	}
	else if( bOnlineSubIsPSN && LoginStatus != LS_LoggedIn && OnlineSub.GameInterface.GameBootIsFromInvite() )
	{
		ShellLoginShowLoginUI(true);
	}
	else
	{
		ShellLoginUserLoginComplete();
	}
	
}

protected function EnableFiraxisLive()
{
	FiraxisLiveClient = `FXSLIVE;
	FiraxisLiveClient.AddConnectionFailureDelegate(FiraxisLiveClient_OnConnectionFailure);
	FiraxisLiveClient.AddConnectionStatusDelegate(FiraxisLiveClient_OnConnectionStatusChange);
	FiraxisLiveClient.AddLogonDataDelegate(FiraxisLiveClient_OnLogonData);
	FiraxisLiveClient.AddLoginStatusDelegate(FiraxisLiveClient_OnLoginStatus);
	FiraxisLiveClient.AddCreateNewAccountDelegate(FiraxisLiveClient_OnNewAccountNotify);
	FiraxisLiveClient.AddDOBDataDelegate(FiraxisLiveClient_OnDoBNotify);
	FiraxisLiveClient.AddLegalInfoDelegate(FiraxisLiveClient_OnLegalNotify);
}

function FiraxisLiveClient_OnConnectionFailure(string Reason)
{
	//local UIFiraxisLiveLogin FiraxisLiveUI;
	`log(`location @ `ShowVar(Reason),,'XCom_Online');
	//FiraxisLiveUI = GetFiraxisLiveLoginUI();
	//if( FiraxisLiveUI != None )
	//{
	//	FiraxisLiveUI.OnConnectionFailure(Reason);
	//	FiraxisLiveUI.GotoConnectionFailure();
	//}
}

function FiraxisLiveClient_OnConnectionStatusChange(string Title, string Message, string OkLabel)
{
	local UIFiraxisLiveLogin FiraxisLiveUI;
	`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(OkLabel),,'XCom_Online');
	FiraxisLiveUI = GetFiraxisLiveLoginUI();
	if( FiraxisLiveUI != None )
	{
		FiraxisLiveUI.OnConnectionStatusChange(Title, Message, OkLabel);
		FiraxisLiveUI.GotoConnectionStatus();
	}
}

function FiraxisLiveClient_OnLogonData(string Title, string Message, string EMailLabel, string PasswordLabel, string OkLabel, string CancelLabel, string CreateLabel, bool Error)
{
	local UIFiraxisLiveLogin FiraxisLiveUI;
	`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(EMailLabel) @ `ShowVar(PasswordLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(CreateLabel) @ `ShowVar(Error),,'XCom_Online');
	FiraxisLiveUI = GetFiraxisLiveLoginUI();
	if( FiraxisLiveUI != None )
	{
		FiraxisLiveUI.OnLogonData(Title, Message, EMailLabel, PasswordLabel, OkLabel, CancelLabel, CreateLabel, Error);
		FiraxisLiveUI.GotoUnlinkedAccount();
	}
}

function FiraxisLiveClient_OnLoginStatus(ELoginStatusType Type, EFiraxisLiveAccountType Account, string Message, bool bSuccess)
{
	//local UIFiraxisLiveLogin FiraxisLiveUI;
	//local XComOnlineProfileSettings ProfileSettings;

	`log(`location @ `ShowEnum(ELoginStatusType, Type, Type) @ `ShowEnum(EFiraxisLiveAccountType, Account, Account) @ `ShowVar(Message) @ `ShowVar(bSuccess),,'XCom_Online');
	//ProfileSettings = XComOnlineProfileSettings(LocalEngine.GetProfileSettings());
	//if( !FiraxisLiveClient.IsAccountLinked() && ProfileSettings.ShouldDisplayMy2KConversionAttempt() )
	//{
	//	// Display Link Dialog
	//	FiraxisLiveUI = GetFiraxisLiveLoginUI();
	//	if( FiraxisLiveUI != None )
	//	{
	//		FiraxisLiveUI.OnLoginStatus(Type, Account, Message, bSuccess);
	//		SaveProfileSettings();
	//	}
	//}
}

function FiraxisLiveClient_OnNewAccountNotify(string Title, string Message, string EmailLabel, string OkLabel, string CancelLabel, bool Error)
{
	local UIFiraxisLiveLogin FiraxisLiveUI;
	`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(EmailLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(Error),,'XCom_Online');
	FiraxisLiveUI = GetFiraxisLiveLoginUI();
	if( FiraxisLiveUI != None )
		FiraxisLiveUI.OnNewAccountNotify(Title, Message, EmailLabel, OkLabel, CancelLabel, Error);
}

function FiraxisLiveClient_OnDoBNotify(string Title, string Message, string DoBLabel, string OkLabel, string CancelLabel, array<string> MonthNames, bool Error)
{
	local UIFiraxisLiveLogin FiraxisLiveUI;
	`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(DoBLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(Error),,'XCom_Online');
	FiraxisLiveUI = GetFiraxisLiveLoginUI();
	if( FiraxisLiveUI != None )
		FiraxisLiveUI.OnDoBNotify(Title, Message, DoBLabel, OkLabel, CancelLabel, MonthNames, Error);
}

function FiraxisLiveClient_OnLegalNotify(string Title, string Message, string AgreeLabel, string AgreeAllLabel, string DisagreeLabel, string DisagreeAllLabel, string ReadLabel, array<LegalDocuments> EULAs)
{
	local UIFiraxisLiveLogin FiraxisLiveUI;
	`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(AgreeLabel) @ `ShowVar(AgreeAllLabel) @ `ShowVar(DisagreeLabel) @ `ShowVar(DisagreeAllLabel) @ `ShowVar(ReadLabel),,'XCom_Online');
	FiraxisLiveUI = GetFiraxisLiveLoginUI();
	if( FiraxisLiveUI != None )
		FiraxisLiveUI.OnLegalNotify(Title, Message, AgreeLabel, AgreeAllLabel, DisagreeLabel, DisagreeAllLabel, ReadLabel, EULAs);
}

function UIFiraxisLiveLogin GetFiraxisLiveLoginUI()
{
	local XComPresentationLayerBase Presentation;
	local UIFiraxisLiveLogin FiraxisLiveUI;
	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not use LocalUserIndex.
	if( !Presentation.ScreenStack.HasInstanceOf(class'UIFiraxisLiveLogin') )
	{
		// Only open and handle the notification if the Live UI is not up already.
		FiraxisLiveUI = UIFiraxisLiveLogin(Presentation.UIFiraxisLiveLogin(false));
	}
	return FiraxisLiveUI;
}

protected function SetActiveController(int ControllerId)
{
	local LocalPlayer ActivePlayer;
	local PlayerController ActivePlayerController;

	// Set the active user
	if( !bOnlineSubIsSteamworks )
		super.SetActiveController(ControllerId);

	if (LocalEngine != none)
	{
		// Set the active controller
		if( LocalEngine.GamePlayers.Length > 0 && LocalEngine.GamePlayers[0] != none )
		{
			`log("USING CONTROLLER " $ ControllerId,,'XCom_Online');

			ActivePlayer = LocalEngine.GamePlayers[0];
			ActivePlayer.SetControllerId(ControllerId);

			ActivePlayerController = ActivePlayer.Actor;
			if( ActivePlayerController != none && ActivePlayerController.bIsControllerConnected == m_bControllerUnplugged )
			{
				`log("Updating controller connection status",,'XCom_Online');
				ActivePlayerController.OnControllerChanged(ControllerId, !m_bControllerUnplugged);
			}
		}
		else
		{
			`log("Failed to set active controller! No players detected!");
		}
	}
}

private function ClearScreenUI()
{
	local XComPresentationLayerBase Presentation;
	local UIMovie_2D InterfaceMgr;

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	InterfaceMgr = (Presentation != none)? Presentation.Get2DMovie() : none;
	if( InterfaceMgr != none && InterfaceMgr.DialogBox != none )
	{
		ClearSystemMessages(); // Remove any system messages
		InterfaceMgr.DialogBox.ClearDialogs(); // Remove any existing dialogs.
	}
}

private function InitializeDelegates()
{
	local OnlinePlayerInterface PlayerInterface;
	local OnlinePlayerInterfaceEx PlayerInterfaceEx;
	local OnlineContentInterface ContentInterface;
	local OnlineSystemInterface SystemInterface;
	local OnlineStatsInterface StatsInterface;

	//Initialize all our delegates
	//////////////////////////////////////////////////////////////////
	PlayerInterface = OnlineSub.PlayerInterface;
	if( PlayerInterface != none )
	{
		//Login
		PlayerInterface.AddLoginChangeDelegate(LoginChangeDelegate);
		PlayerInterface.AddLoginCancelledDelegate(LoginCancelledDelegate);
		PlayerInterface.AddLogoutCompletedDelegate(LocalUserIndex, LogoutCompletedDelegate);
		PlayerInterface.AddLoginStatusChangeDelegate(LoginStatusChange, LocalUserIndex);

		//Player Profile
		PlayerInterface.AddWriteProfileSettingsCompleteDelegate(LocalUserIndex, WriteProfileSettingsCompleteDelegate);
		PlayerInterface.AddReadProfileSettingsCompleteDelegate(LocalUserIndex, ReadProfileSettingsCompleteDelegate);
		PlayerInterface.AddWritePlayerStorageCompleteDelegate(LocalUserIndex, WritePlayerStorageCompleteDelegate);
		PlayerInterface.AddReadPlayerStorageCompleteDelegate(LocalUserIndex, ReadPlayerStorageCompleteDelegate);
	}

	PlayerInterfaceEx = OnlineSub.PlayerInterfaceEx;
	if( PlayerInterfaceEx != none )
	{
		//Device Selection
		PlayerInterfaceEx.AddDeviceSelectionDoneDelegate(LocalUserIndex, DeviceSelectionDoneDelegate);
	}

	SystemInterface = OnlineSub.SystemInterface;
	if( SystemInterface != none )
	{
		//External UI
		SystemInterface.AddExternalUIChangeDelegate(ExternalUIChangedDelegate);

		// Storage added or removed
		SystemInterface.AddStorageDeviceChangeDelegate(StorageDeviceChangeDelegate);
	}

	//Player content (saves)
	ContentInterface = OnlineSub.ContentInterface;
	if( ContentInterface != none )
	{
		ContentInterface.AddReadSaveGameDataComplete(LocalUserIndex, OnReadSaveGameDataComplete);
		ContentInterface.AddReadContentComplete(LocalUserIndex, OCT_SaveGame, OnUpdateSaveListComplete);
		ContentInterface.AddWriteSaveGameDataComplete(LocalUserIndex, OnWriteSaveGameDataComplete);
		ContentInterface.AddDeleteSaveGameDataComplete(LocalUserIndex, OnDeleteSaveGameDataComplete);
	}

	// stats -tsmith 
	StatsInterface = OnlineSub.StatsInterface;
	if(StatsInterface != none)
	{
		StatsInterface.SetStatsViewPropertyToColumnIdMapping(class'XComOnlineStatsUtils'.default.StatsViewPropertyToColumnIdMap);
		StatsInterface.SetViewToLeaderboardNameMapping(class'XComOnlineStatsUtils'.default.ViewIdToLeaderboardNameMap);
	}

}

/** Called during shell login to update the progress message. */
private function ShellLoginProgressMsg(string sProgressMsg)
{
	local XComPresentationLayerBase Presentation;
	local TProgressDialogData kDialogData;

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	if( Presentation != none )
	{
		// Remove previous dialog box
		ShellLoginHideProgressDialog();

		kDialogData.strTitle = sProgressMsg;
		Presentation.UIProgressDialog(kDialogData);
	}
}

/** Use during the shell login sequence to hide the shell login progress dialog */
private function ShellLoginHideProgressDialog()
{
	local XComPresentationLayerBase Presentation;

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	if( Presentation != none && bInShellLoginSequence )
	{
		// Close the progress dialog as well as any other UI state that has
		// managed to introduce itself above the progress dialog.
		Presentation.ScreenStack.PopIncludingClass( class'UIProgressDialogue', false );
	}
}

/** Called when the user login is complete during the shell login sequence. */
private function ShellLoginUserLoginComplete()
{
	if( bHasLogin )
	{
		`log("Shell Login: User Logged In",,'XCom_Online');

		InitMCP();
		SelectStorageDevice();

		RefreshOnlineStatus(); // Updates rich presence

		CopyProtection.StartCheck(LocalUserIndex);
		RequestLoginFeatures();
	}
	else
	{
		`log("Shell Login: User NOT Logged In",,'XCom_Online');

		if( bRequireLogin )
		{
			if( bOnlineSubIsLive )
			{
				RequestLogin();
				return;
			}
			else
			{
				`log("Login required but not present. However, Online Sub does not have login UI.",,'XCom_Online');
			}
		}

		// Non-Live systems can perform check without begin logged-in
		if( !bOnlineSubIsLive )
			CopyProtection.StartCheck(LocalUserIndex);

		if( bOnlineSubIsSteamworks )
		{
			SelectStorageDevice(); //PC users always have storage
		}
		else
		{
			// A failed login automatically goes to creating a new profile
			CreateNewProfile();
		}
	}
}

private function RequestLogin()
{
	local XComPresentationLayerBase Presentation;
	local TDialogueBoxData kData;

	`log("Requesting user login.",,'XCom_Online');

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	if( Presentation != none )
	{
		bShowingLoginRequiredWarning = true;

		kData.eType = eDialog_Warning;
		kData.strText = m_sLoginRequiredMessage;
		kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
		kData.fnCallback = RequestLoginDialogCallback;

		// Close the progress dialog
		ShellLoginHideProgressDialog();

		Presentation.UIRaiseDialog(kData);
	}
	else
	{
		RequestLoginDialogCallback('eUIAction_Accept');
	}
}

private function RequestLoginDialogCallback(Name Action)
{
	bShowingLoginRequiredWarning = false;

	ShellLoginProgressMsg(m_sLoadingProfile); // Restore progress dialog

	if( Action == 'eUIAction_Accept' )
	{
		ShellLoginShowLoginUI();
	}
}

/** 
 *  Called during the shell login sequence when there are
 *  inactive profiles that need to be logged out.
 */
private function ShellLoginHandleInactiveProfiles()
{
	local XComPresentationLayerBase Presentation;
	local TDialogueBoxData kData;

	`log("Shell Login: Raising inactive profile dialog",,'XCom_Online');

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	if( Presentation != none )
	{
		kData.eType = eDialog_Warning;
		kData.strText = m_sInactiveProfileMessage;
		kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
		kData.fnCallback = InactiveProfilesDialogCallback;

		Presentation.UIRaiseDialog(kData);
	}
	else
	{
		InactiveProfilesDialogCallback('eUIAction_Cancel');
	}
}

private function InactiveProfilesDialogCallback(Name Action)
{
	if( !CheckForInactiveProfiles() )
	{
		// No more inactive profiles. Restart Shell Login.
		`log("Shell Login: Restarting Shell Login Sequence",,'XCom_Online');

		bInShellLoginSequence = false;
		BeginShellLogin(LocalUserIndex);
	}
	else
	{
		`log("Shell Login Failed: Inactive Profiles Present",,'XCom_Online');

		AbortShellLogin();
	}
}

/** Called when the shell login has failed */
private function AbortShellLogin()
{
	local delegate<ShellLoginComplete> dShellLoginComplete;

	`log("Shell Login: Aborting");

	ResetLogin();

	// Close the progress dialog
	ShellLoginHideProgressDialog();

	bInShellLoginSequence = false;

	foreach m_BeginShellLoginDelegates(dShellLoginComplete)
	{
		dShellLoginComplete(false);
	}
}

/** Called when the shell login process is complete */
private function EndShellLogin()
{
	local XComPresentationLayerBase Presentation;
	`ONLINEEVENTMGR.ResetAchievementState(); //Firaxis RAM - shell login resets our internal state regarding achievements being disabled by easter eggs

	// Refresh configs only when logging in from the start screen
	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	if( bOnlineSubIsSteamworks || (Presentation != none && Presentation.IsInState('State_StartScreen', true)) )
	{
		DownloadConfigFiles();
	}

	ShellLoginDLCRefreshComplete();
}

/** Called when DLC has finished refreshing while the shell login is waiting for it to complete. */
private function ShellLoginDLCRefreshComplete()
{
	local delegate<ShellLoginComplete> dShellLoginComplete;

	if( bInShellLoginSequence )
	{
		//`log("Shell Login: DLC Refresh Complete",,'XCom_Online');
		`log("Shell Login Complete",,'XCom_Online');

		// Close the progress dialog
		ShellLoginHideProgressDialog();

		ShowPostLoadMessages();

		bInShellLoginSequence = false;
		
		foreach m_BeginShellLoginDelegates(dShellLoginComplete)
		{
			dShellLoginComplete(true);
		}
	}
}

private function DownloadConfigFiles()
{
	if (OnlineSub != none && OnlineSub.Patcher != none && OnlineSub.Patcher.TitleFileInterface != none && 
		(LoginStatus == LS_LoggedIn || bOnlineSubIsSteamworks))
	{
		`log("XComOnlineEventMgr: Requesting config files from server",,'XCom_Online');
		OnlineSub.Patcher.AddReadFileDelegate(OnReadTitleFileComplete);
		OnlineSub.Patcher.DownloadFiles();
	}
	else
	{
		`log("XComOnlineEventMgr: User is offline or patcher is not configured, no configs will be downloaded",,'XCom_Online');
		// Because we either aren't online or are not configured to download files, we just pretend
		// that everything is current -- jboswell
		bConfigIsUpToDate = true;
	}
}

simulated function OnReadTitleFileComplete(bool bWasSuccessful,string FileName)
{
	`log("XComOnlineEventMgr: Config file downloaded:" @ FileName @ bWasSuccessful,,'XCom_Online');
	// We don't care if it was successful, we are not going to hold the player up from playing
	// if we don't get a new config file. We only want to protect against the updated config arriving at
	// a bad time -- jboswell
	bConfigIsUpToDate = true;
}

simulated native function bool HasEliteSoldierPack();
simulated native function bool HasSlingshotPack();
simulated native function bool HasDLCEntitlement(int ContentID);
simulated native function bool HasTLEEntitlement();

simulated function ReadProfileSettings()
{
	local OnlinePlayerInterfaceEx PlayerInterfaceEx;	
	local XComOnlineProfileSettings ProfileSettings;

	PlayerInterfaceEx = OnlineSub.PlayerInterfaceEx;	

	ProfileSettings = XComOnlineProfileSettings(LocalEngine.GetProfileSettings());
	if( ProfileSettings == none )
	{
		SetupDefaultProfileSettings();
	}

	StorageDeviceIndex = PlayerInterfaceEx.GetDeviceSelectionResults(LocalUserIndex, StorageDeviceName);
	OnlineSub.PlayerInterface.ReadPlayerStorage(LocalUserIndex, ProfileSettings, StorageDeviceIndex);
}

simulated function QueueQuitReasonMessage(EQuitReason Reason, optional bool bIgnoreMsgAdd=false)
{
	local ESystemMessageType systemMessage;
	
	systemMessage = GetSystemMessageForQuitReason(Reason);
	`log(`location $ ":" @ `ShowVar(Reason, QuitReason) @ "," @ `ShowVar(systemMessage, SystemMessage),,'XCom_Online');

	// We really don't care about QuitReasons that don't have an associated SystemMessage (just triggers disconnect, no error msg).
	if(systemMessage != SystemMessage_None)
		QueueSystemMessage(GetSystemMessageForQuitReason(Reason), bIgnoreMsgAdd);
}

simulated function ESystemMessageType GetSystemMessageForQuitReason(EQuitReason Reason)
{
	switch( Reason )
	{
	case QuitReason_SignOut:                return SystemMessage_QuitReasonLogout;
	case QuitReason_LostDlcDevice:          return SystemMessage_QuitReasonDlcDevice;
	case QuitReason_InactiveUser:           return SystemMessage_QuitReasonInactiveUser;
	case QuitReason_LostConnection:         return SystemMessage_QuitReasonLostConnection;
	case QuitReason_LostLinkConnection:     return SystemMessage_QuitReasonLinkLost;
	case QuitReason_OpponentDisconnected:   return SystemMessage_QuitReasonOpponentDisconnected;
	default:
		return SystemMessage_None;
	};
}

simulated function ReturnToStartScreen(EQuitReason Reason)
{
	`log("Returning to Start Screen" @ `ShowVar(Reason) @ `ShowEnum(ShuttleToScreenType, ShuttleToScreen, ShuttleToScreen),,'XCom_Online');

	if (Reason == QuitReason_LostConnection )
	{
		// If we received a lost connect because of a user sign out
		// then use this as the real reason for the quit.
		RefreshLoginStatus();
		if( !bHasLogin )
			Reason = QuitReason_SignOut;
	}

	QueueQuitReasonMessage(Reason, true /* bIgnoreMsgAdd */);

	if (GetShuttleToStartMenu())
	{
		`log("Ignoring duplicate return to Start Screen.",,'XCom_Online');
		ScriptTrace();
		return;
	}
	ScriptTrace();

	bInShellLoginSequence = false;
	bPerformingStandardLoad = false;
	bPerformingTransferLoad = false;
	bShowingLoginUI = false;
	bWarnedOfOnlineStatus = false;

	ResetLogin();

	`XENGINE.StopCurrentMovie();
	SetShuttleToStartMenu();

	if (!bDelayDisconnects)
		DisconnectAll();
	else
		bDisconnectPending = true;
}

simulated function InviteFailed(ESystemMessageType eSystemMessage, bool bTravelToMPMenus=false)
{
	`log(`location @ `ShowVar(m_bCurrentlyTriggeringBootInvite) @ `ShowVar(eSystemMessage) @ `ShowVar(bTravelToMPMenus) @ "\n" @ GetScriptTrace(),,'XCom_Online');
	SetBootInviteChecked(true);
	ClearCurrentlyTriggeringBootInvite();
	if (bTravelToMPMenus)
	{
		ShowSystemMessageOnMPMenus(eSystemMessage);
	}
	else
	{
		QueueSystemMessage(eSystemMessage);
		ReturnToStartScreen(QuitReason_None);
	}
}

simulated function DelayDisconnects(bool bDelay)
{
	bDelayDisconnects = bDelay;
	if (!bDelayDisconnects && bDisconnectPending)
	{
		bDisconnectPending = false;
		DisconnectAll();
	}
}

simulated function DisconnectAll()
{
	local XComGameStateNetworkManager NetworkMgr;
	NetworkMgr  = `XCOMNETMANAGER;
	NetworkMgr.Disconnect();
	EngineLevelDisconnect();
}

function ReturnToMPMainMenuBase()
{
	ReturnToMPMainMenu();
}

function bool IsAtMPMainMenu()
{
	local XComPresentationLayerBase Presentation;
	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
	if(Presentation != none)
	{
		//This state comes from XComShellPresentationLayer.uc
		if(Presentation.IsInState('State_MPShell', true))
		{
			return true;
		}
	}

	return false;
}

/**
 *  This sets up the flow to return to the MP Main Menu.  Once the UI is initialized, 
 *  it will check here to find out if it should transfer to the Multiplayer menu.
 */
function ReturnToMPMainMenu(optional EQuitReason Reason=QuitReason_None)
{
	`log("Returning to MP Main Menu" @ `ShowVar(Reason) @ `ShowEnum(ShuttleToScreenType, ShuttleToScreen, ShuttleToScreen) @ "\n" $ GetScriptTrace(),,'XCom_Online');

	if (Reason == QuitReason_None && HasAcceptedInvites())
	{
		`log("Triggering Accepted Invites instead of returning to the MP Main Menu.",,'XCom_Online');
		// Trigger the invite
		TriggerAcceptedInvite();
		return;
	}

	QueueQuitReasonMessage(Reason, true /* bIgnoreMsgAdd */);

	if (GetShuttleToMPMainMenu())
	{
		`log("Ignoring duplicate return to MP Main Menu.",,'XCom_Online');
		return;
	}

	SetShuttleToMPMainMenu();
	DisconnectAll();
}

private function ClearLoginSettings()
{
	LoginStatus = LS_NotLoggedIn;
	bHasLogin = false;
	bHasStorageDevice = false;
	bHasProfileSettings = false;
	StorageDeviceIndex = -1;
	StorageDeviceName = "";
	bSaveExplanationScreenHasShown = false;

	if( CopyProtection != none )
		CopyProtection.bProtectionPassed = false;
}

simulated function ResetLogin()
{
	local OnlinePlayerInterface    PlayerInterface;
	local OnlinePlayerInterfaceEx  PlayerInterfaceEx;
	local OnlineContentInterface   ContentInterface;

	// Disable the MCP
	if( MCP != none )
	{
		MCP.bEnableMcpService = false;
	}

	// Clear user specific delegates
	if( OnlineSub != none )
	{
		PlayerInterface = OnlineSub.PlayerInterface;
		if( PlayerInterface != none )
		{
			//Login
			OnlineSub.PlayerInterface.ResetLogin();
			PlayerInterface.ClearLogoutCompletedDelegate(LocalUserIndex, LogoutCompletedDelegate);
			PlayerInterface.ClearLoginStatusChangeDelegate(LoginStatusChange, LocalUserIndex);

			//Player Profile
			PlayerInterface.ClearWriteProfileSettingsCompleteDelegate(LocalUserIndex, WriteProfileSettingsCompleteDelegate);
			PlayerInterface.ClearReadProfileSettingsCompleteDelegate(LocalUserIndex, ReadProfileSettingsCompleteDelegate);
			PlayerInterface.ClearWritePlayerStorageCompleteDelegate(LocalUserIndex, WritePlayerStorageCompleteDelegate);
			PlayerInterface.ClearReadPlayerStorageCompleteDelegate(LocalUserIndex, ReadPlayerStorageCompleteDelegate);
		}

		PlayerInterfaceEx = OnlineSub.PlayerInterfaceEx;
		if( PlayerInterfaceEx != none )
		{
			//Device Selection
			PlayerInterfaceEx.ClearDeviceSelectionDoneDelegate(LocalUserIndex, DeviceSelectionDoneDelegate);
		}
		
		ContentInterface = OnlineSub.ContentInterface;
		if( ContentInterface != none )
		{
			//Player content (saves)
			ContentInterface.ClearReadSaveGameDataComplete(LocalUserIndex, OnReadSaveGameDataComplete);
			ContentInterface.ClearReadContentComplete(LocalUserIndex, OCT_SaveGame, OnUpdateSaveListComplete);
			ContentInterface.ClearWriteSaveGameDataComplete(LocalUserIndex, OnWriteSaveGameDataComplete);
			ContentInterface.ClearDeleteSaveGameDataComplete(LocalUserIndex, OnDeleteSaveGameDataComplete);
		}
	}

	// Clear any login settings
	ClearLoginSettings();
}

function InitMCP()
{
	local bool bLoggedIntoOnlineProfile;

	if( MCP != none )
	{
		bLoggedIntoOnlineProfile = LoginStatus == LS_LoggedIn;

		// Enable the MCP if we have an online profile and the config allows it.
		MCP.bEnableMcpService = bMCPEnabledByConfig && bLoggedIntoOnlineProfile;

		// Init even when disabled. This makes sure init listeners are called. MCP will still obey the enabled flag.
		MCP.Init(bLoggedIntoOnlineProfile);
	}
}

//function RefreshDLC()
//{
//	local DownloadableContentManager DLCManager;

//	DLCManager = class'GameEngine'.static.GetDLCManager();
//	if( DLCManager != none )
//	{
//		`log("Manually Refreshing DLC",,'XCom_Online');
//		DLCManager.RefreshDLC();
//	}
//	else
//	{
//		`log("Failed to manually refresh DLC. DLC Manager not found.",,'XCom_Online');
//	}
//}

function bool ShellLoginShowLoginUI(optional bool bCallLoginComplete=false)
{
	local bool bOpenedUI;
	bOpenedUI = false;

	if( bExternalUIOpen )
	{
		// We can't open the login UI while another external UI is up.
		// The login will be open when the current UI is closed.
		`log("Login UI Pending",,'XCom_Online');
		bLoginUIPending = true;
	}
	else
	{
		`log("Showing login UI",,'XCom_Online');
		bLoginUIPending = false;
		if (bCallLoginComplete)
		{
			OnlineSub.PlayerInterface.AddLoginUICompleteDelegate(OnShellLoginShowLoginUIComplete);
		}
		bOpenedUI = OnlineSub.PlayerInterface.ShowLoginUI(false);
		bShowingLoginUI = bOpenedUI;
	}
	return bOpenedUI;
}

private function OnShellLoginShowLoginUIComplete(bool bWasSuccessful)
{
	OnlineSub.PlayerInterface.ClearLoginUICompleteDelegate(OnShellLoginShowLoginUIComplete);
	if (!bWasSuccessful)
	{
		ShellLoginUserLoginComplete();
	}
}


simulated function SelectStorageDevice()
{
	if( bOnlineSubIsSteamworks || bOnlineSubIsPSN ) //Steamworks and PSN have default access to hard drives
	{
		DeviceSelectionDoneDelegate(true);
	}
	else if( bExternalUIOpen )
	{
		// We can't open the storage selection UI while another external UI is up.
		// The storage selection UI will be open when the current UI is closed.
		`log("Select Storage Device Pending",,'XCom_Online');
		bStorageSelectPending = true;
	}
	else
	{
		// Refresh Login Status
		// Under certain wacky circumstances the delegates will be called in such an order
		// that the login status is out of date here. We need to verify our login status
		// before showing the device selector. We shouldn't show it if we aren't logged in.
		RefreshLoginStatus();

		if( bHasLogin )
		{
			`log("Showing Storage Device Selector" @ `ShowVar(LocalUserIndex) @ `ShowVar(`XENGINE.GetMaxSaveSizeInBytes(), MaxSize) @ `ShowVar(bStorageSelectPending) @ `ShowVar(bInShellLoginSequence),,'XCom_Online');
			bStorageSelectPending = false;
			OnlineSub.PlayerInterfaceEx.ShowDeviceSelectionUI(
				LocalUserIndex, `XENGINE.GetMaxSaveSizeInBytes(), false, !bInShellLoginSequence);
		}
		else
		{
			`log("Storage Device Selector Failed: Login Lost",,'XCom_Online');
			bStorageSelectPending = false;
		}
	}
}

function SaveProfileSettingsImmediate()
{
	local delegate<SaveProfileSettingsComplete> dSaveProfileSettingsComplete;
	local bool bWritingProfileSettings;
	local bool bWroteSettingsToBuffer;
	local OnlinePlayerInterfaceEx PlayerInterfaceEx;
	local XComOnlineProfileSettings ProfileSettings;
	PlayerInterfaceEx = OnlineSub.PlayerInterfaceEx;

	ProfileSettings = XComOnlineProfileSettings(LocalEngine.GetProfileSettings());
	if (bHasProfileSettings && ProfileSettings != none && ProfileSettings.Data != none && !ProfileIsSerializing)	
	{
		`log("Saving profile to disk", , 'XCom_Online');

		ProfileSettings.PreSaveData();

		bWroteSettingsToBuffer = WriteProfileSettingsToBuffer();

		if (bWroteSettingsToBuffer)
		{
			ProfileIsSerializing = true;

			StorageDeviceIndex = PlayerInterfaceEx.GetDeviceSelectionResults(LocalUserIndex, StorageDeviceName);
			bWritingProfileSettings = OnlineSub.PlayerInterface.WritePlayerStorage(LocalUserIndex, ProfileSettings, StorageDeviceIndex);

			if (bWritingProfileSettings && (bShowSaveIndicatorForProfileSaves || bForceShowSaveIcon))
				ShowSaveIndicator(true);

			bProfileDirty = false;
		}
		else
		{
			`log("Cannot save profile settings: WriteProfileSettingsToBuffer failed!", , 'XCom_Online');
			foreach m_SaveProfileSettingsCompleteDelegates(dSaveProfileSettingsComplete)
			{
				dSaveProfileSettingsComplete(false);
			}
		}
	}
	else
	{
		`log("Cannot save profile settings: No profile available!", , 'XCom_Online');
		foreach m_SaveProfileSettingsCompleteDelegates(dSaveProfileSettingsComplete)
		{
			dSaveProfileSettingsComplete(false);
		}

		bProfileDirty = false;
	}

	bForceShowSaveIcon = false;
}

function SaveProfileSettings(optional bool bForceShowSaveIndicator=false)
{	
	bProfileDirty = true;
	bForceShowSaveIcon = bForceShowSaveIcon || bForceShowSaveIndicator;
}

function DebugSaveProfileSettingsCompleteDelegate()
{
	local delegate<SaveProfileSettingsComplete> dSaveProfileSettingsComplete;
	`log(`location, true, 'XCom_Online');
	foreach m_SaveProfileSettingsCompleteDelegates(dSaveProfileSettingsComplete)
	{
		`log(`location @ "      DebugSaveProfileSettingsCompleteDelegate: " $ dSaveProfileSettingsComplete, true, 'XCom_Online');
	}
}

function AddSaveProfileSettingsCompleteDelegate( delegate<SaveProfileSettingsComplete> dSaveProfileSettingsCompleteDelegate )
{
	`log(`location @ `ShowVar(dSaveProfileSettingsCompleteDelegate), true, 'XCom_Online');
	if (m_SaveProfileSettingsCompleteDelegates.Find(dSaveProfileSettingsCompleteDelegate) == INDEX_None)
	{
		m_SaveProfileSettingsCompleteDelegates[m_SaveProfileSettingsCompleteDelegates.Length] = dSaveProfileSettingsCompleteDelegate;
	}
}

function ClearSaveProfileSettingsCompleteDelegate(delegate<SaveProfileSettingsComplete> dSaveProfileSettingsCompleteDelegate)
{
	local int i;

	`log(`location @ `ShowVar(dSaveProfileSettingsCompleteDelegate), true, 'XCom_Online');
	i = m_SaveProfileSettingsCompleteDelegates.Find(dSaveProfileSettingsCompleteDelegate);
	if (i != INDEX_None)
	{
		m_SaveProfileSettingsCompleteDelegates.Remove(i, 1);
	}
}

function CreateNewProfile()
{
	`log("Creating New Profile",,'XCom_Online');

	SetupDefaultProfileSettings();
	bHasProfileSettings = true;

	if( !bHasLogin )
	{
		`log("NOT Saving New Profile",,'XCom_Online');

		if( class'WorldInfo'.static.IsConsoleBuild() )
			LossOfDataWarning(m_sLoginWarning);
		else
			LossOfDataWarning(m_sLoginWarningPC);
	}
	else if( !bHasStorageDevice )
	{
		`log("NOT Saving New Profile",,'XCom_Online');
		LossOfDataWarning(m_sNoStorageDeviceSelectedWarning);
	}
	else
	{
		`log("Saving New Profile",,'XCom_Online');
		AddSaveProfileSettingsCompleteDelegate( NewProfileSaveComplete );
		SaveProfileSettings();
	}
}

private function NewProfileSaveComplete(bool bWasSuccessful)
{
	ClearSaveProfileSettingsCompleteDelegate( NewProfileSaveComplete );
	if( bWasSuccessful )
	{
		`log("New Profile Saved",,'XCom_Online');

		if( bInShellLoginSequence )
		{
			EndShellLogin();
		}
	}
	else
	{
		`log("New Profile Save Failed",,'XCom_Online');
		
		if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360) )
		{
			LossOfDataWarning(m_sLossOfDataWarning360);
		}
		else
		{
			LossOfDataWarning(m_sLossOfDataWarning);
		}
	}
}

simulated private function LossOfDataWarning(string sWarningText)
{
	local XComPresentationLayerBase Presentation;
	local UIMovie_2D InterfaceMgr; 
	local TDialogueBoxData kData;

	bShowingLossOfDataWarning = true;

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	InterfaceMgr = (Presentation != none)? Presentation.Get2DMovie() : none;
	if( InterfaceMgr != none && InterfaceMgr.DialogBox != none )
	{
		kData.eType = eDialog_Warning;
		kData.strTitle = m_sLossOfDataTitle;
		kData.strText = sWarningText;
		kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

		if( sWarningText == m_sNoStorageDeviceSelectedWarning )
		{
			kData.fnCallback = NoStorageDeviceCallback;
			kData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		}
		else
		{
			kData.fnCallback = LossOfDataAccepted;
		}

		// Close the progress dialog if in the shell login sequence
		if( bInShellLoginSequence )
		{
			ShellLoginHideProgressDialog();
		}
		else
		{
			ClearScreenUI();
		}

		Presentation.UIRaiseDialog(kData);
	}
	else
	{
		LossOfDataAccepted('eUIAction_Accept');
	}
}

private simulated function LossOfDataAccepted(Name eAction)
{
	bShowingLossOfDataWarning = false;

	if( bCancelingShellLoginDialog )
	{
		ShellLoginProgressMsg(m_sLoadingProfile); // Going back to an earlier stage in the shell login
	}
	else if( bInShellLoginSequence )
	{
		EndShellLogin();
	}
}

private simulated function NoStorageDeviceCallback(Name eAction)
{
	bShowingLossOfDataWarning = false;

	if( bCancelingShellLoginDialog )
	{
		ShellLoginProgressMsg(m_sLoadingProfile); // Going back to an earlier stage in the shell login
	}
	else if( eAction == 'eUIAction_Accept' )
	{
		SelectStorageDevice();
	}
	else if( bInShellLoginSequence )
	{
		EndShellLogin();
	}
}



/** Called when a dialog in the shell login sequence needs to be aborted */
private function CancelActiveShellLoginDialog()
{
	local XComPresentationLayerBase Presentation;
	local UIMovie_2D InterfaceMgr;
	local UIDialogueBox DialogBox; 

	if( bInShellLoginSequence && (bShowingLossOfDataWarning || bShowingLoginRequiredWarning) )
	{
		Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
		InterfaceMgr = (Presentation != none)? Presentation.Get2DMovie() : none;
		DialogBox = (InterfaceMgr != none)? InterfaceMgr.DialogBox : none;
		if( DialogBox != none )
		{
			// HACK! Close the dialog box with 'eUIAction_Cancel'
			bCancelingShellLoginDialog = true;
			DialogBox.OnCancel();
			bCancelingShellLoginDialog = false;
		}
	}
}

private simulated function LossOfSaveDevice()
{
	local XComPlayerController ActiveController;
	local XComPresentationLayerBase Presentation;
	local Camera PlayerCamera;
	local TDialogueBoxData kData;

	bHasStorageDevice = false;
	StorageDeviceIndex = -1;
	StorageDeviceName = "";

	ActiveController = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor); // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	Presentation = ActiveController.Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	PlayerCamera =ActiveController.PlayerCamera; 
	if( Presentation != none 
	   && Presentation.IsPresentationLayerReady()
		&& Presentation.Get2DMovie().DialogBox != none 
		&& !Presentation.Get2DMovie().DialogBox.ShowingDialog() 
		&& !Presentation.IsInState('State_ProgressDialog') 
		&& !ActiveController.bCinematicMode 
		&& !Presentation.ScreenStack.IsInputBlocked
		&& (PlayerCamera == none || !PlayerCamera.bEnableFading || PlayerCamera.FadeAmount == 0.0 ))
	{
		if( Presentation.GetStateName() == 'State_StartScreen' && !bHasProfileSettings )
		{
			`log("Ignoring loss of save device because we're on the start screen.",,'XCom_Online');
		}
		else
		{
			`log("Showing loss of save device warning.",,'XCom_Online');

			if( class'XComEngine'.static.IsLoadingMoviePlaying() )
			{
				Presentation.UIStopMovie();
			}

			kData.eType = eDialog_Warning;
			kData.strTitle = "";
			kData.strText = m_sLossOfSaveDeviceWarning;
			kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
			kData.strCancel = m_strReturnToStartScreenLabel;
			kData.fnCallback = LossOfSaveDeviceAccepted;

			// Force show the UI for this
			bShowingLossOfSaveDeviceWarning = true;
			Presentation.Get2DMovie().PushForceShowUI();
			ActiveController.SetPause(true, CanUnpauseLossOfSaveDeviceWarning);

			Presentation.UIRaiseDialog(kData);
		}
	}
	else
	{
		`log("Loss of save device warning waiting for presentation layer.",,'XCom_Online');
		bSaveDeviceWarningPending = true;
	}
}

private simulated function LossOfSaveDeviceAccepted(Name eAction)
{
	local XComPlayerController ActiveController;
	local XComPresentationLayerBase Presentation;

	ActiveController = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor); // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	Presentation = ActiveController.Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.

	bShowingLossOfSaveDeviceWarning = false;

	if( Presentation != none && Presentation.Get2DMovie() != none )
		Presentation.Get2DMovie().PopForceShowUI();

	ActiveController.SetPause(false, CanUnpauseLossOfSaveDeviceWarning);

	if( eAction == 'eUIAction_Accept' )
	{
		SelectStorageDevice();
	}
	else
	{
		ReturnToStartScreen(QuitReason_UserQuit);
	}
}

private function bool CanUnpauseLossOfSaveDeviceWarning()
{
	return !bShowingLossOfSaveDeviceWarning;
}

event Tick(float DeltaTime)
{
	if( bSaveDeviceWarningPending && IsPresentationLayerReady() )
	{
		fSaveDeviceWarningPendingTimer = fmax(0, fSaveDeviceWarningPendingTimer - DeltaTime);
		if(fSaveDeviceWarningPendingTimer == 0)
		{
			bSaveDeviceWarningPending = false;
			LossOfSaveDevice();
		}
	}
	else if( bShowingLossOfSaveDeviceWarning && !IsPresentationLayerReady() )
	{
		// We lost our presentation layer after showing the loss of save device warning.
		// We'll have to bring it back when we get a new presentation layer.
		LossOfSaveDeviceAccepted('eUIAction_Cancel');
		bSaveDeviceWarningPending = true;
		fSaveDeviceWarningPendingTimer = StorageRemovalWarningDelayTime;
	}
	
	if( bSaveDataOwnerErrPending )
	{
		ShowPostLoadMessages();
	}

	if (bProfileDirty)
	{
		SaveProfileSettingsImmediate();
	}
}

private function bool IsPresentationLayerReady()
{
	local XComPresentationLayerBase Presentation;
	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.

	return Presentation != none && Presentation.IsPresentationLayerReady() && Presentation.Get2DMovie().DialogBox != none;
}

function bool WaitingForPlayerProfileRead()
{
	return false;
}

function bool AreAchievementsEnabled()
{
	return bAchivementsEnabled;
}

function EnableAchievements(bool enable, optional bool bXComHero)
{
	bAchivementsEnabled = enable;
	bAchievementsDisabledXComHero = bXComHero;
}

function UnlockAchievement(EAchievementType Type)
{
	DevOnlineMsg("UnlockAchievement: " $ AreAchievementsEnabled() $ ": " $ Type);

	if (AreAchievementsEnabled())
	{		
		OnlineSub.PlayerInterface.UnlockAchievement(LocalUserIndex, Type);
	}

	CheckGameProgress(Type);
}

function int AchievementToProgressIndex(EAchievementType Type)
{
	switch (Type)
	{
		case AT_BuildResistanceComms:		return 1;  // Build Resistance Comms
		case AT_ContactRegion:				return 2;  // Make contact with a region
		case AT_RecoverBlackSiteData:		return 3;  // Recover the Black Site Data
		case AT_SkulljackAdventOfficer:		return 4;  // Skulljack an ADVENT Officer
		case AT_RecoverCodexBrain:			return 5;  // Recover a Codex Brain
		case AT_BuildShadowChamber:			return 6;  // Build the Shadow Chamber
		case AT_RecoverForgeItem:			return 7;  // Recover the Forge Item
		case AT_RecoverPsiGate:				return 8;  // Recover the Psi Gate
		case AT_KillAvatar:					return 9;  // Kill an Avatar
		case AT_CompleteAvatarAutopsy:		return 10; // Complete the Avatar Autopsy
		case AT_CreateDarkVolunteer:		return 11; // Create the Dark Volunteer
		case AT_OverthrowAny:				return 12; // Overthrow the aliens at any difficulty level

		default: return 0;
	}


}

function int CountBits(int v)
{
	local int c;

	v = v - ((v >> 1) & 0x55555555);                    // reuse input as temporary
	v = (v & 0x33333333) + ((v >> 2) & 0x33333333);     // temp
	c = ((v + (v >> 4) & 0xF0F0F0F) * 0x1010101) >> 24; // count

	return c;
}


function CheckGameProgress(EAchievementType Type)
{
	local int progressIndex;
	local int progressSoFar;
	local int progressCount;
	local XComGameState_Analytics AnalyticsObject;
	local XComGameStateHistory History;


	progressIndex = AchievementToProgressIndex(Type);

	if( progressIndex != 0 )
	{
		History = `XCOMHISTORY;

		// check if we have analytics object
		AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
		if (AnalyticsObject != none)
		{
			progressSoFar = int( AnalyticsObject.GetFloatValue("GameProgress") );

			// if the bit for this achievement hasn't been set yet
			if( (progressSoFar & (1<<progressIndex)) == 0 )
			{
				progressSoFar = progressSoFar | ( 1 << progressIndex );
				progressCount = CountBits(progressSoFar);
				AnalyticsObject.SetValue("GameProgress", progressSoFar);
				
				// let bizdev know how awesome we are
				`FXSLIVE.AnalyticsGameProgress(string(GetEnum(enum'EAchievementType', EAchievementType(Type))), float(progressCount) / 12);
				class'AnalyticsManager'.static.SendGameProgressTelemetry( History, string(GetEnum(enum'EAchievementType', EAchievementType(Type))) );
			}
		}
	}
}

native function DevOnlineMsg(string msg);

/** Sets a new Online Status and uses it to set the rich presence strings */
reliable client function SetOnlineStatus(EOnlineStatusType NewOnlineStatus)
{
	if( OnlineStatus != NewOnlineStatus )
	{
		`log("Setting online status to: " $ NewOnlineStatus,,'XCom_Online');

		OnlineStatus = NewOnlineStatus;
		RefreshOnlineStatus();
	}
}

/** Looks at the current Online Status and uses it to set the rich presence strings */
reliable client function RefreshOnlineStatus()
{
	local OnlinePlayerInterface PlayerInterface;
	local array<LocalizedStringSetting> LocalizedStringSettings;
	local array<SettingsProperty> Properties;

	if( bHasLogin )
	{
		PlayerInterface = OnlineSub.PlayerInterface;
		if (PlayerInterface != None)
		{
			`log("Refreshing online status." @ `ShowVar(LocalUserIndex) @ `ShowVar(OnlineStatus),,'XCom_Online');
			PlayerInterface.SetOnlineStatus(LocalUserIndex, OnlineStatus, LocalizedStringSettings, Properties);
		}
		else
		{
			`log("Failed to refresh online status: Missing player interface",,'XCom_Online');
		}
	}
}

reliable client function InitRichPresence()
{
	local int OnlineStatusID;
	local int UserIndex;
	local OnlinePlayerInterface PlayerInterface;
	local array<LocalizedStringSetting> LocalizedStringSettings;
	local array<SettingsProperty> Properties;

	PlayerInterface = OnlineSub.PlayerInterface;
	if (PlayerInterface != None)
	{
		if( bOnlineSubIsLive )
		{
			// Set online status to OnlineStatus_MainMenu for inactive users
			for( UserIndex = 0; UserIndex < 4; UserIndex++ )
			{
				if( UserIndex != LocalUserIndex ) // Do not set online status for active user. That comes later.
				{
					`log("Refreshing online status." @ `ShowVar(UserIndex),,'XCom_Online');
					PlayerInterface.SetOnlineStatus(UserIndex, OnlineStatus_MainMenu, LocalizedStringSettings, Properties);
				}
			}
		}
		else
		{
			`log("Initializing Rich Presence Strings",,'XCom_Online');
			for( OnlineStatusID = 0; OnlineStatusID < EOnlineStatusType.EnumCount; OnlineStatusID++ )
			{
				PlayerInterface.SetOnlineStatusString(OnlineStatusID, m_aRichPresenceStrings[OnlineStatusID]);
			}
		}
	}
	else
	{
		`log("Failed to init rich presence: Missing player interface",,'XCom_Online');
	}
}

private function RequestLoginFeatures()
{
	// called whenever the user is signed in.
	// perform any queries related to login features. e.g. request stats, friends, trophies

	OnlineSub.PlayerInterface.AddReadAchievementsCompleteDelegate(LocalUserIndex, ReadAchievementsCompleteDelegate);
	OnlineSub.PlayerInterface.ReadAchievements(LocalUserIndex);

	// need to initialize unique ID so things such as online subsystem work correctly. -tsmith 
	XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).InitUniquePlayerId(); // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
}

function bool ShowGamerCardUI(UniqueNetID PlayerID)
{
	local OnlinePlayerInterfaceEx PlayerInterfaceEx;

	if (OnlineSub != None)
	{
		PlayerInterfaceEx = OnlineSub.PlayerInterfaceEx;
		if (PlayerInterfaceEx != None)
		{
			return PlayerInterfaceEx.ShowGamerCardUI(LocalUserIndex, PlayerID);
		}
		else
		{
			`log(self $ "::" $ GetFuncName() @ "OnlineSubsystem does not support the extended player interface. Can't show gamercard.", true, 'XCom_Online');
		}
	}
	else
	{
		`log(self $ "::" $ GetFuncName() @ "No OnlineSubsystem present. Can't show gamercard.", true, 'XCom_Online');
	}

	return false;
}


function bool GetSaveGames( out array<OnlineSaveGame> SaveGames )
{
	local OnlineContentInterface ContentInterface;
	local EOnlineEnumerationReadState ReadState;
	local bool bSuccess;

	SaveGames.Remove(0, SaveGames.Length);

	ContentInterface = OnlineSub.ContentInterface;
	if( ContentInterface != none )
	{
		ReadState = ContentInterface.GetSaveGames(LocalUserIndex, SaveGames);
		bSuccess = ReadState == OERS_Done || (!bOnlineSubIsLive && ReadState == OERS_NotStarted);
		CheckSaveIDs(SaveGames);

		`log(self $ "::" $ GetFuncName() @ `ShowVar(ReadState), true, 'XCom_Online');
	}
	else
	{
		bSuccess = false;

		`log(self $ "::" $ GetFuncName() $ " failed to retrieve content interface", true, 'XCom_Online');
	}

	return bSuccess;
}

function OnlineStatsRead GetOnlineStatsRead()
{
	return m_kStatsRead;
}

function bool GetOnlineStatsReadSuccess()
{
	return m_bStatsReadSuccessful;
}

function bool IsReadyForMultiplayer()
{
	// Check to make sure that we're logged in and that we're logged in to the correct local player.
	// The local player may change if an inactive controller accepts an invite. We want this to trigger a new "shell" login.
	return bHasProfileSettings && !bInShellLoginSequence && LocalUserIndex == LocalEngine.GamePlayers[0].ControllerId;
}

/**
 * @return true if inactive controllers are logged in, false otherwise
 */
function bool CheckForInactiveProfiles()
{
	local int UserIndex;
	local ELoginStatus InactiveUserLoginStatus;
	local OnlinePlayerInterface PlayerInterface;

	PlayerInterface = OnlineSub.PlayerInterface;
	if( PlayerInterface != none )
	{
		for( UserIndex = 0; UserIndex < 4; UserIndex++ )
		{
			if( UserIndex != LocalUserIndex ) // Do not check the active user
			{
				InactiveUserLoginStatus = PlayerInterface.GetLoginStatus(UserIndex);
				if( InactiveUserLoginStatus != LS_NotLoggedIn )
					return true;
			}
		}
	}

	return false;
}


function bool CheckOnlineConnectivity()
{
	local UniqueNetId ZeroID;
	local XComPlayerController xPlayerController;

	xPlayerController = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor);
	if (OnlineSub.PlayerInterface.GetLoginStatus(LocalUserIndex) != LS_LoggedIn ||
	    xPlayerController.PlayerReplicationInfo == none ||
	    xPlayerController.PlayerReplicationInfo.UniqueId == ZeroID)
	{
		return false;
	}
	else if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360) && OnlineSub.PlayerInterface.IsGuestLogin(LocalUserIndex) )
	{
		return false;
	}

	return true;
}

// Checks for any lingering system messages or dialogs to be displayed 
// since they may have been torn-down via a loading screen.
function PerformNewScreenInit()
{
	local XComPresentationLayerBase kPres;

	kPres = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
	if(kPres != none)
	{
		// Display the controller unplugged message if it was unplugged before accepting a multiplayer invite
		if(m_bControllerUnplugged)
		{
			kPres.UIControllerUnplugDialog(`ONLINEEVENTMGR.LocalUserIndex);
		}

		kPres.SanitizeSystemMessages();
	}

	if(m_bCurrentlyTriggeringBootInvite)
	{
		// Were there any critical system messages removed? (i.e. were there any problems loading the invite?)
		if(ClearSystemMessages() > 0)
		{
			InviteFailed(SystemMessage_BootInviteFailed);
		}
	}

	ActivateAllSystemMessages(); // No longer trigger invites here, instead wait for an explicit call from the Loadout UI
}

native function bool HasValidLoginAndStorage();

native function bool ReadProfileSettingsFromBuffer();
native function bool WriteProfileSettingsToBuffer();

// Save / Load functionality
//==================================================================================================================
function UpdateSaveGameList()
{
	local OnlineContentInterface ContentInterface;

	`log("Refreshing Save Game List",,'XCom_Online');

	bUpdateSaveListInProgress = true;

	ContentInterface = OnlineSub.ContentInterface;
	if( ContentInterface != none )
	{
		if( bHasStorageDevice )
		{
			CallUpdateSaveListStartedDelegates();
			ContentInterface.ReadContentList(LocalUserIndex, OCT_SaveGame, StorageDeviceIndex);
		}
		else
		{
			// Wipe out any cached saved games if there is no save device
			ContentInterface.ClearContentList(LocalUserIndex, OCT_SaveGame);
			OnUpdateSaveListComplete(true);
		}
	}
	else
	{
		// No content interface means a failed save game list update
		OnUpdateSaveListComplete(false);
	}
}

native function bool GetSaveSlotDescription(int SaveSlotIndex, out string Description);
native function bool GetSaveSlotMapName(int SaveSlotIndex, out string MapName);
native function bool GetSaveSlotLanguage(int SaveSlotIndex, out string Language);

/**Events for the save games to get writter or read from native code*/
private event ReadSaveGameData(byte LocalUserNum,int DeviceId,string FriendlyName,string FileName,string SaveFileName)
{
	local OnlineContentInterface ContentInterface;

	ContentInterface = OnlineSub.ContentInterface;
	if( ContentInterface != none )
	{
		ContentInterface.ReadSaveGameData(LocalUserNum, DeviceId, FriendlyName, FileName, SaveFileName);
	}
}

//This method is called AFTER the successful / unsuccessful load of saved game data, but before the map open command has been sent.
private event PreloadSaveGameData(byte LocalUserNum, bool Success, int GameNum, int SaveID)
{
	local XComGameState_Unit Unit;
	local XComGameStateHistory History;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local XComGameState_CampaignSettings Settings;
	local int i;
	local bool bAnySuperSoldiers;
	local name DLCName;

	// Variable for issue #808
	local array<X2DownloadableContentInfo> ExistingDLCInfos;

	if(Success)
	{
		//Disable achievements if a super soldier is being used
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			if(Unit.bIsSuperSoldier)
			{
				bAnySuperSoldiers = true;
				break;				
			}
		}

		if(bAnySuperSoldiers)
		{
			EnableAchievements(false, true);
		}
		else
		{
			EnableAchievements(true, false);
		}

		//Fills out the 'RequestedArchetypes' array in the content manager by iterating the state objects in the recently loaded history
		`CONTENT.RequestContent();

		//Check to see if we have campaign settings. If so, see if we have DLCs that have been newly added that should process - and if so
		//add them to our list of required DLC
		Settings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
		if(Settings != none)
		{	
			EventManager = `ONLINEEVENTMGR;
			
			// Let the DLC / Mods hook the creation of a new campaign
			DLCInfos = EventManager.GetDLCInfos(true);
			for(i = 0; i < DLCInfos.Length; ++i)
			{
				DLCInfos[i].OnLoadedSavedGame();
			}

			// Start issue #808
			/// HL-Docs: ref:OnLoadedSavedGameWithDLCExisting
			
			// Get all DLCInfos (there is no API to get only the existing ones)
			ExistingDLCInfos = EventManager.GetDLCInfos(false);
			
			// Clear the new ones (otherwise we will call both OnLoadedSavedGame hooks)
			for (i = 0; i < DLCInfos.Length; ++i)
			{
				ExistingDLCInfos.RemoveItem(DLCInfos[i]);
			}
			
			// Invoke OnLoadedSavedGameWithDLCExisting
			for (i = 0; i < ExistingDLCInfos.Length; ++i)
			{
				ExistingDLCInfos[i].OnLoadedSavedGameWithDLCExisting();
			}
			// End issue #808

			// Add new DLCs to the list of required DLCs. Directly writing to the state object outside of a game state change is 
			// unorthodox, but works for this situation
			for(i = 0; i < EventManager.GetNumDLC(); ++i)
			{
				DLCName = EventManager.GetDLCNames(i);					
				if(Settings.RequiredDLC.Find(DLCName) == -1)
				{
					Settings.AddRequiredDLC(DLCName);
				}
			}			
		}
	}
}

private event WriteSaveGameData(byte LocalUserNum, int DeviceId, string FileName, const out array<byte> SaveGameData, string FriendlyName, const out SaveGameHeader SaveHeader)
{
	local OnlineContentInterface ContentInterface;
	local bool bWritingSaveGameData;

	ContentInterface = OnlineSub.ContentInterface;
	if( ContentInterface != none )
	{
		m_sCustomSaveDescription = "";
		
		bWritingSaveGameData = ContentInterface.WriteSaveGameData(LocalUserNum, DeviceId, FriendlyName, FileName, FileName, SaveGameData, SaveHeader);

		if( bWritingSaveGameData )
			ShowSaveIndicator();
	}
}

function ShowSaveIndicator(bool bProfileSave=false)
{
	//RAM - disabling while Brit is refactoring the UI system
	//local float SaveIndicatorDuration;
	//local XComPresentationLayerBase Presentation;

	//Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	//if( Presentation != none )
	//{
	//	if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_XBOX360) )
	//	{
	//		SaveIndicatorDuration = (bProfileSave)? 1.0f : 3.0f;
	//	}
	//	else if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3) )
	//	{
	//		SaveIndicatorDuration = 3.0f;
	//	}
	//	else
	//	{
	//		SaveIndicatorDuration = 2.5f; // PC
	//	}

	//	Presentation.QueueAnchoredMessage(
	//		class'WorldInfo'.static.IsConsoleBuild()? "" : m_strSaving, // No text for the save indicator on consoles
	//		0.9f, 0.9f, BOTTOM_CENTER, SaveIndicatorDuration, "SaveIndicator", eIcon_Globe);
	//}
}

// Immediately hide a raised save indicator
function HideSaveIndicator()
{
	local XComPresentationLayerBase Presentation;

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres; // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	if( Presentation != none )
	{
		Presentation.GetAnchoredMessenger().RemoveMessage( "SaveIndicator" );
	}
}

//This description will be used in the next save operation ( and cleared after )
simulated function SetPlayerDescription(string CustomDescription)
{
	m_sCustomSaveDescription = CustomDescription;
}

event FillInHeaderForSave(out SaveGameHeader Header, out string SaveFriendlyName, optional int PartialHistorySaveIndex = -1)
{	
	local WorldInfo LocalWorldInfo;	
	local XComGameInfo LocalGameInfo;	
	local int Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond;
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local int Index;
	local XComAutosaveMgr AutosaveMgr;
	local string DLCName;
	local string DLCFriendlyName;
	local TDateTime StartDateTime, CurrentTime;
	local XComGameState_Player PlayerState;
	local XComGameState_BattleData BattleData;
	local XComGameState_Analytics AnalyticsState;
	local XComGameState_MissionSite MissionState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGParamTag kTag;
	local string PrePostString;
	local XComGameState_LadderProgress LadderData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	History = `XCOMHISTORY;
	AutosaveMgr = `AUTOSAVEMGR;

	LocalWorldInfo = class'Engine'.static.GetCurrentWorldInfo();
	LocalGameInfo = XComGameInfo(LocalWorldInfo.Game);

	LocalWorldInfo.GetSystemTime(Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond);
	FormatTimeStamp(Header.Time, Year, Month, Day, Hour, Minute);

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true) );
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
	{
		Header.DLCPackNames.Length = 0;
		Header.DLCPackFriendlyNames.Length = 0;
		for(Index = 0; Index < CampaignSettingsStateObject.RequiredDLC.Length; ++Index)
		{
			DLCName = string(CampaignSettingsStateObject.RequiredDLC[Index]);
			Header.DLCPackNames.AddItem(DLCName);
			DLCFriendlyName = GetDLCFriendlyName(DLCName);
			if(DLCFriendlyName != "")
			{
				Header.DLCPackFriendlyNames.AddItem(DLCFriendlyName);
			}
			else
			{
				Header.DLCPackFriendlyNames.AddItem(DLCName);
			}
		}

		Header.CampaignStartTime = CampaignSettingsStateObject.StartTime;
		Header.bIsIronman = CampaignSettingsStateObject.bIronmanEnabled;
		Header.GameNum = CampaignSettingsStateObject.GameIndex;
	}
	
	Header.bIsTacticalSave = XComTacticalGRI(LocalWorldInfo.GRI) != none;	
	Header.Description = Header.Time;

	// fill in Month
	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	Header.Month = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime) + 1;

	// fill in Turn/Actions taken
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState, , , PartialHistorySaveIndex)
	{
		if( PlayerState.GetTeam() == eTeam_XCom )
		{
			break;
		}
	}
	Header.Turn = PlayerState.PlayerTurnCount;
	Header.Action = PlayerState.ActionsTakenThisTurn;

	// fill in Mission Type
	if( Header.bPreMission )
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
		Header.MissionType = MissionState.GeneratedMission.Mission.MissionFamily;
	}
	else if (BattleData != none)
	{
		Header.MissionType = BattleData.MapData.ActiveMission.MissionFamily;
	}
	else
	{
		Header.MissionType = "";
	}

	// fill in Mission # (-1 for TQL)
	if( (BattleData != none) && BattleData.bIsTacticalQuickLaunch )
	{
		Header.Mission = -1;
	}
	else
	{
		AnalyticsState = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
		Header.Mission = AnalyticsState.GetFloatValue("BATTLES_WON") + AnalyticsState.GetFloatValue("BATTLES_LOST") + 1;

		// subtract 1 for post mission
		if( Header.bPostMission )
		{
			--Header.Mission;
		}
	}

	LadderData = XComGameState_LadderProgress( History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true) );
	if (LadderData != none)
	{
		Header.bLadder = true;
		Header.GameNum = LadderData.LadderIndex;
		Header.Mission = LadderData.LadderRung;
	}

	// user-generated description
	if( m_sCustomSaveDescription != "" )
	{
		Header.PlayerSaveDesc = m_sCustomSaveDescription;
	}
	// debug saves
	else if( Header.bDebugSave )
	{
		if( (BattleData != none) && BattleData.bIsTacticalQuickLaunch )
		{
			PrePostString = "TQL";
		}
		else if( Header.bPreMission )
		{
			PrePostString = "Pre";
		}
		else if( Header.bPostMission )
		{
			PrePostString = "Post";
		}
		Header.PlayerSaveDesc = "DEBUG" @ "Campaign" @ Header.GameNum @ PrePostString @ "Mission" @ Header.Mission @ "[" $ Header.MissionType $ "]" @ "Turn" @ Header.Turn @ "Action" @ Header.Action;
	}
	else
	{
		kTag.IntValue0 = Header.GameNum;
		kTag.IntValue1 = Header.Mission;
		kTag.IntValue2 = Header.Turn;

		// in progress ladder
		if (Header.bLadder)
		{
			Header.PlayerSaveDesc = class'XComLocalizer'.static.ExpandString(m_strLadderFormatString);
		}
		else if (BattleData.m_strDesc == "Skirmish Mode") // skirmish mode
		{
			Header.PlayerSaveDesc = class'XComLocalizer'.static.ExpandString(m_strSkirmishFormatString);
		}
		// ironman saves
		else if( Header.bIsIronman )
		{
			Header.PlayerSaveDesc = class'XComLocalizer'.static.ExpandString(m_strIronmanFormatString);
		}
		// autosaves
		else if( Header.bIsAutosave )
		{
			if( Header.bIsTacticalSave )
			{
				Header.PlayerSaveDesc = class'XComLocalizer'.static.ExpandString(m_strAutosaveTacticalFormatString);
			}
			else
			{
				Header.PlayerSaveDesc = class'XComLocalizer'.static.ExpandString(m_strAutosaveStrategyFormatString);
			}
		}
		// quicksaves
		else if( Header.bIsQuicksave )
		{
			if( Header.bIsTacticalSave )
			{
				Header.PlayerSaveDesc = class'XComLocalizer'.static.ExpandString(m_strQuicksaveTacticalFormatString);
			}
			else
			{
				Header.PlayerSaveDesc = class'XComLocalizer'.static.ExpandString(m_strQuicksaveStrategyFormatString);
			}
		}
	}
	
	// fallback - "Save #"
	if(Header.PlayerSaveDesc == "")
	{
		Header.PlayerSaveDesc = m_sEmptySaveString @ AutosaveMgr.GetNextSaveID();
	}

			
	Header.Description $= "\n" $ Header.PlayerSaveDesc;
	Header.Description $= "\n" $ LocalGameInfo.GetSavedGameDescription();
	Header.MapCommand = LocalGameInfo.GetSavedGameCommand();
	Header.MapImage = `MAPS.SelectMapImage(LocalGameInfo.GetSavedGameMapName()); //@TODO fill out by using a method on LocalGameInfo like GetSavedGameDescription
	Header.VersionNumber = class'XComOnlineEventMgr'.const.CheckpointVersion;
	Header.Language = GetLanguage();

	if (class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360)) 
		SaveFriendlyName = Header.Time; // The Xbox 360 dashboard has very limited space to show save game names
	else
		SaveFriendlyName = Header.Description;
}

//DLC references both mods and Firaxis DLCs.
native function bool IsDLCRequiredAtCampaignStart(string dlcName);
native function name GetDLCNames(int index);
native function int GetNumDLC();
native function string GetDLCFriendlyName(string DLCName);

//Returns a list of X2DownloadableContentInfo corresponding to various DLCs and mods that are installed. Mods & DLCs aren't required to implement this, but
//it is highly recommended for them to do since many Mods/DLC need custom handling when being installed.
//
//If bNewDLCOnly is TRUE, the function retrieves the current campaign settings object from the history and only returns content infos for DLCs that are new
//to that campaign
native function array<X2DownloadableContentInfo> GetDLCInfos(bool bNewDLCOnly);

/** Create a time stamp string in the format used for X-Com saves */
native static function FormatTimeStamp(out string TimeStamp, int Year, int Month, int Day, int Hour, int Minute);
native static function string FormatTimeStampFor12HourClock(string TimeStamp);
native static function FormatTimeStampSingleLine12HourClock(out string TimeStamp, int Year, int Month, int Day, int Hour, int Minute);


/** Provided for the save / load UI - where saves need to be ordered from most recent to oldest*/
native function SortSavedGameListByTimestamp(const out array<OnlineSavegame> SaveGameList);

function bool ArePRIStatsNewerThanCachedVersion(XComPlayerReplicationInfo PRI)
{
	local int iPRIStatsSum;
	local int iCachedStatsSum;
	local bool bResult;
	local UniqueNetId kZeroID;

	bResult = false;
	`log(self $ "::" $ GetFuncName() @ PRI.ToString() @ "CachedStats=" $ TMPLastMatchInfo_Player_ToString(m_kMPLastMatchInfo.m_kLocalPlayerInfo), true, 'XCom_Online');
	// only want to use cached stats for ourself or if the cache -tsmith 
	if(PRI.UniqueId == m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_kUniqueID) 
	{
		// our stats are always increasing so newer stats will always sum to a larger value -tsmith 
		iPRIStatsSum = PRI.m_iRankedDeathmatchMatchesWon + PRI.m_iRankedDeathmatchMatchesLost + PRI.m_iRankedDeathmatchDisconnects;
		iCachedStatsSum = m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iWins + m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iLosses + m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iDisconnects;
		`log(self $ "::" $  GetFuncName() @ `ShowVar(iPRIStatsSum) @ `ShowVar(iCachedStatsSum), true, 'XCom_Online');
		bResult = iPRIStatsSum >= iCachedStatsSum;
	}
	else
	{
		// if the cached stats unique id is empty that means the game has just started running so the PRI stats will definitely be newer. -tsmith 
		bResult = m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_kUniqueID  == kZeroId;
	}

	return bResult;
}

static function FillPRIFromLastMatchPlayerInfo(out TMPLastMatchInfo_Player kLastMatchPlayerInfo, XComPlayerReplicationInfo kPRI)
{
	kPRI.UniqueId = kLastMatchPlayerInfo.m_kUniqueID;
	kPRI.m_iRankedDeathmatchMatchesWon = kLastMatchPlayerInfo.m_iWins;
	kPRI.m_iRankedDeathmatchMatchesLost = kLastMatchPlayerInfo.m_iLosses;
	kPRI.m_iRankedDeathmatchDisconnects = kLastMatchPlayerInfo.m_iDisconnects;
	kPRI.m_iRankedDeathmatchSkillRating = kLastMatchPlayerInfo.m_iSkillRating;
	kPRI.m_iRankedDeathmatchRank = kLastMatchPlayerInfo.m_iRank;
	kPRI.m_bRankedDeathmatchLastMatchStarted = kLastMatchPlayerInfo.m_bMatchStarted;

	`log(GetFuncName() @ TMPLastMatchInfo_Player_ToString(kLastMatchPlayerInfo), true, 'XCom_Net');
}

static function FillLastMatchPlayerInfoFromPRI(out TMPLastMatchInfo_Player kLastMatchPlayerInfo, XComPlayerReplicationInfo kPRI)
{
	kLastMatchPlayerInfo.m_kUniqueID = kPRI.UniqueId;
	kLastMatchPlayerInfo.m_iWins = kPRI.m_iRankedDeathmatchMatchesWon;
	kLastMatchPlayerInfo.m_iLosses = kPRI.m_iRankedDeathmatchMatchesLost;
	kLastMatchPlayerInfo.m_iDisconnects = kPRI.m_iRankedDeathmatchDisconnects;
	kLastMatchPlayerInfo.m_iSkillRating = kPRI.m_iRankedDeathmatchSkillRating;
	kLastMatchPlayerInfo.m_iRank = kPRI.m_iRankedDeathmatchRank;
	kLastMatchPlayerInfo.m_bMatchStarted = kPRI.m_bRankedDeathmatchLastMatchStarted;

	`log(GetFuncName() @ TMPLastMatchInfo_Player_ToString(kLastMatchPlayerInfo), true, 'XCom_Net');
}

static function string TMPLastMatchInfo_ToString(const out TMPLastMatchInfo kLastMatchInfo)
{
	local string strRep;

	strRep = "\n    IsRanked=" $ kLastMatchInfo.m_bIsRanked;
	strRep @= "\n    Automatch=" $ kLastMatchInfo.m_bAutomatch;
	strRep @= "\n    MapPlotType=" $ kLastMatchInfo.m_iMapPlotType;
	strRep @= "\n    MapBiomeType=" $ kLastMatchInfo.m_iMapBiomeType;
	strRep @= "\n    NetworkType=" $ kLastMatchInfo.m_eNetworkType;
	strRep @= "\n    GameType=" $ kLastMatchInfo.m_eGameType;
	strRep @= "\n    TurnTimeSeconds=" $ kLastMatchInfo.m_iTurnTimeSeconds;
	strRep @= "\n    MaxSquadCost=" $ kLastMatchInfo.m_iMaxSquadCost;
	strRep @= "\n    LocalPlayerInfo=" $ TMPLastMatchInfo_Player_ToString(kLastMatchInfo.m_kLocalPlayerInfo);
	strRep @= "\n    RemotePlayerInfo=" $ TMPLastMatchInfo_Player_ToString(kLastMatchInfo.m_kRemotePlayerInfo);

	return strRep;
}

static function string TMPLastMatchInfo_Player_ToString(const out TMPLastMatchInfo_Player kLastMatchInfoPlayer)
{
	local string strRep;

	strRep = "\n        PlayerUniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(kLastMatchInfoPlayer.m_kUniqueID);
	strRep @= "\n        MatchStarted=" $ kLastMatchInfoPlayer.m_bMatchStarted;
	strRep @= "\n        Wins=" $ kLastMatchInfoPlayer.m_iWins;
	strRep @= "\n        Losses=" $ kLastMatchInfoPlayer.m_iLosses;
	strRep @= "\n        Disconnects=" $ kLastMatchInfoPlayer.m_iDisconnects;
	strRep @= "\n        SkillRating=" $ kLastMatchInfoPlayer.m_iSkillRating;
	strRep @= "\n        Rank=" $ kLastMatchInfoPlayer.m_iRank;

	return strRep;
}

event OnDeleteSaveGameDataComplete(byte LocalUserNum)
{
	local OnlineContentInterface ContentInterface;

	ContentInterface = OnlineSub.ContentInterface;
	if( ContentInterface != none )
	{
		ContentInterface.ClearSaveGames(LocalUserNum);
		UpdateSaveGameList();
	}
}

private event DeleteSaveGameData(byte LocalUserNum, int DeviceId, string FileName)
{
	local OnlineContentInterface ContentInterface;

	ContentInterface = OnlineSub.ContentInterface;
	if( ContentInterface != none )
	{
		`log("Deleting Save File: " $ FileName,,'XCom_Online');
		ContentInterface.DeleteSaveGame(LocalUserNum, DeviceID, "", FileName);
	}
}

//Saving is simple, fire and forget
native function SaveGame(int SlotIndex, bool IsAutosave, bool IsQuicksave, delegate<WriteSaveGameComplete> WriteSaveGameCompleteCallback = none, optional bool bDebugSave, optional bool bPreMissionSave, optional bool bPostMissionSave, optional int PartialHistoryLength = -1);
native function OnSaveCompleteInternal(bool bWasSuccessful, byte LocalUserNum, int DeviceId, string FriendlyName, string FileName, string SaveFileName); //The main purpose of this is to clear the save game serializing flag so that new saves can happen
native function SaveLadderGame( delegate<WriteSaveGameComplete> WriteSaveGameCompleteCallback = none );
native function SaveLadderSummary( );
 
//Loading is a 3 step process:
native function LoadGame(int SlotIndex, delegate<ReadSaveGameComplete> ReadSaveGameCompleteCallback = none);  //1. Initiate the (possibly async) read for a specific save from the player's storage. Calls OnReadSaveGameDataComplete when this is done.
//OnReadSaveGameDataComplete (delegate, above)	                                                              //2. Read the save data and initiate the map travel/load 
native function FinishLoadGame(); 	                                                                          //3. Load the save data ( instantiate saved actors ), this is done after the map loads.

// Implemented for tutorial mode, to load a save from a file not in your saves folder
native function LoadSaveFromFile(String SaveFile, delegate<ReadSaveGameComplete> ReadSaveGameCompleteCallback = none);

native function DeleteSaveGame(int SlotIndex);

// These save / load functions use in-memory checkpoints/saves
native function StartLoadFromStoredStrategy();  // Called from the tactical game when it finishes, starts the command1 map load / seamless travel
native function FinishLoadFromStoredStrategy(); // Called from the strategy game after the command1 map has finished loading, serializes in the saved strategy actors
native function SaveToStoredStrategy();         // Saves strategy actors to a binary blob for safe keeping
native function SaveTransport();
native function LoadTransport();
native function ReleaseCurrentTacticalCheckpoint(); // releases and nulls CurrentTacticalCheckpoint, 4.5+ megs of memory
//==================================================================================================================
//

native function int GetNextSaveID();
native function int SaveNameToID(string SaveFileName);
native function SaveIDToFileName(int SaveID, out string SaveFileName);
native function bool CheckSaveDLCRequirements(int SaveID, out string MissingDLC);
native function bool CheckSaveVersionRequirements(int SaveID);
native private function GetNewSaveFileName(out string SaveFileName, const out SaveGameHeader SaveHeader);

// Platform Specific Cert Functionality
//==================================================================================================================

/**
 * Calls the "Delete save data from a list" function for TRC R115
 * This brings up a list of save files and allows the user to pick
 * which files they wish to delete. ONLY AVAILABLE ON PS3! 
 */
native function DeleteSaveDataFromListPS3();

/**
 * On PS3 it is possible to transfer saves between profiles using
 * a USB stick to move the save off then back on the PS3. We need
 * to detect this circumstance and notify the user that they will
 * not be able to unlock trophies.
 * 
 * @return true if save data owned by another user has been loaded
 */
native function bool LoadedSaveDataFromAnotherUserPS3();

/**
 * Detect if a non-standard controller is in use. QA says that we
 * are suppose to prevent tha game from working with the Move controller
 * per TRC R026. This also checks for other non-standard controllers
 * like the Guitar controller or the DJ Deck controller.
 * 
 * @param ControllerIndex The index of the controller to check. Must be less than CELL_PAD_MAX_PORT_NUM.
 * @return true if the player is using a standard controller. false if the controller is non-standard OR not connected.
 */
native function bool StandardControllerInUsePS3(int ControllerIndex);

/**
 * Get the free space on the save device.
 * This is Xbox 360 only for now.
 * 
 * @return The free space on the save device in KB
 */
native function int GetSaveDeviceSpaceKB_Xbox360();

/**
 * Check to see if we have enough storage space for a new save game.
 * This is Xbox 360 only for now.
 * 
 * @return True if there is sufficient space to save. False otherwise.
 */
native function bool CheckFreeSpaceForSave_Xbox360();

/**
 * Use to determine if a gamepad is connected on PC
 * 
 * @return True if a gamepad is connected
 */
native static function bool GamepadConnected_PC();

/**
 * Detect gamepads that have been connected since the game started.
 */
native static function EnumGamepads_PC();

// Update Save List Started Delegates
//==================================================================================================================
function AddUpdateSaveListStartedDelegate( delegate<UpdateSaveListStarted> Callback )
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(Callback), true, 'XCom_Online');
	if (m_UpdateSaveListStartedDelegates.Find(Callback) == INDEX_None)
	{
		m_UpdateSaveListStartedDelegates[m_UpdateSaveListStartedDelegates.Length] = Callback;
	}
}

function ClearUpdateSaveListStartedDelegate( delegate<UpdateSaveListStarted> Callback )
{
	local int i;

	`log(self $ "::" $ GetFuncName() @ `ShowVar(Callback), true, 'XCom_Online');
	i = m_UpdateSaveListStartedDelegates.Find(Callback);
	if (i != INDEX_None)
	{
		m_UpdateSaveListStartedDelegates.Remove(i, 1);
	}
}

private function CallUpdateSaveListStartedDelegates()
{
	local delegate<UpdateSaveListStarted> Callback;

	foreach m_UpdateSaveListStartedDelegates(Callback)
	{
		Callback();
	}
}

// Update Save List Complete Delegates
//==================================================================================================================
function AddUpdateSaveListCompleteDelegate( delegate<UpdateSaveListComplete> Callback )
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(Callback), true, 'XCom_Online');
	if (m_UpdateSaveListCompleteDelegates.Find(Callback) == INDEX_None)
	{
		m_UpdateSaveListCompleteDelegates[m_UpdateSaveListCompleteDelegates.Length] = Callback;
	}
}

function ClearUpdateSaveListCompleteDelegate( delegate<UpdateSaveListComplete> Callback )
{
	local int i;

	`log(self $ "::" $ GetFuncName() @ `ShowVar(Callback), true, 'XCom_Online');
	i = m_UpdateSaveListCompleteDelegates.Find(Callback);
	if (i != INDEX_None)
	{
		m_UpdateSaveListCompleteDelegates.Remove(i, 1);
	}
}

private function CallUpdateSaveListCompleteDelegates(bool bWasSuccessful)
{
	local delegate<UpdateSaveListComplete> Callback;

	foreach m_UpdateSaveListCompleteDelegates(Callback)
	{
		Callback(bWasSuccessful);
	}
}

// Login Status Changed Delegates
//==================================================================================================================
// While it may seem odd to route this event through the OnlineEventMgr it removes the complexity of having to worry
// about tracking the active user in systems other than the OnlineEventMgr. This helps for edge cases such as an
// inactive profile accepting an invite and therefore becoming the active controller.
function AddLoginStatusChangeDelegate( delegate<OnlinePlayerInterface.OnLoginStatusChange> Callback )
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(Callback), true, 'XCom_Online');
	if (m_LoginStatusChangeDelegates.Find(Callback) == INDEX_None)
	{
		m_LoginStatusChangeDelegates[m_LoginStatusChangeDelegates.Length] = Callback;
	}
}

function ClearLoginStatusChangeDelegate( delegate<OnlinePlayerInterface.OnLoginStatusChange> Callback )
{
	local int i;

	`log(self $ "::" $ GetFuncName() @ `ShowVar(Callback), true, 'XCom_Online');
	i = m_LoginStatusChangeDelegates.Find(Callback);
	if (i != INDEX_None)
	{
		m_LoginStatusChangeDelegates.Remove(i, 1);
	}
}

private function CallLoginStatusChangeDelegates(ELoginStatus NewStatus, UniqueNetId NewId)
{
	local delegate<OnlinePlayerInterface.OnLoginStatusChange> Callback;

	foreach m_LoginStatusChangeDelegates(Callback)
	{
		Callback(NewStatus, NewId);
	}
}

// Save Device Lost Delegates
//==================================================================================================================
function AddSaveDeviceLostDelegate( delegate<OnSaveDeviceLost> Callback )
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(Callback), true, 'XCom_Online');
	if (m_SaveDeviceLostDelegates.Find(Callback) == INDEX_None)
	{
		m_SaveDeviceLostDelegates[m_SaveDeviceLostDelegates.Length] = Callback;
	}
}

function ClearSaveDeviceLostDelegate( delegate<OnSaveDeviceLost> Callback )
{
	local int i;

	`log(self $ "::" $ GetFuncName() @ `ShowVar(Callback), true, 'XCom_Online');
	i = m_SaveDeviceLostDelegates.Find(Callback);
	if (i != INDEX_None)
	{
		m_SaveDeviceLostDelegates.Remove(i, 1);
	}
}

private function CallSaveDeviceLostDelegates()
{
	local delegate<OnSaveDeviceLost> Callback;

	foreach m_SaveDeviceLostDelegates(Callback)
	{
		Callback();
	}
}

// Network Connection Problems
//==================================================================================================================
//
function AddNotifyConnectionProblemDelegate( delegate<OnConnectionProblem> Callback )
{
	`log(`location @ `ShowVar(Callback), true, 'XCom_Online');
	if (m_ConnectionProblemDelegates.Find(Callback) == INDEX_None)
	{
		m_ConnectionProblemDelegates[m_ConnectionProblemDelegates.Length] = Callback;
	}
}

function ClearNotifyConnectionProblemDelegate( delegate<OnConnectionProblem> Callback )
{
	local int i;

	`log(`location @ `ShowVar(Callback), true, 'XCom_Online');
	i = m_ConnectionProblemDelegates.Find(Callback);
	if (i != INDEX_None)
	{
		m_ConnectionProblemDelegates.Remove(i, 1);
	}
}

function NotifyConnectionProblem()
{
	local delegate<OnConnectionProblem> Callback;
	foreach m_ConnectionProblemDelegates(Callback)
	{
		Callback();
	}
}

// Invite System
//==================================================================================================================
//
function SwitchUsersThenTriggerAcceptedInvite()
{
	`log(`location @ `ShowVar(LocalUserIndex) @ `ShowVar(InviteUserIndex),,'XCom_Online');
	if (InviteUserIndex != LocalUserIndex)
	{
		AddBeginShellLoginDelegate(OnShellLoginComplete_SwitchUsers);
		BeginShellLogin(InviteUserIndex);
	}
	else
	{
		`log(`location @ "No need to switch users!",,'XCom_Online');
	}
}

function OnShellLoginComplete_SwitchUsers(bool bWasSuccessful)
{
	`log(`location,,'XCom_Online');
	ClearBeginShellLoginDelegate(OnShellLoginComplete_SwitchUsers);
	if (bWasSuccessful)
	{
		TriggerAcceptedInvite();
	}
}

/**
 *  OnGameInviteAccepted - Callback from the OnlineSubsystem whenever a player accepts an invite.  This will store
 *    the invite data, since it is not stored elsewhere, and will allow the game to process invites through load
 *    screens or whenever the PlayerController will be destroyed.
 *    
 *    NOTE: This will be called multiple times with the same InviteResult, due to the way the invite callbacks are
 *    registered on all controllers.
 */
function OnGameInviteAccepted(const out OnlineGameSearchResult InviteResult, bool bWasSuccessful)
{
	local XComPlayerController xPlayerController;
	local XComPresentationLayerBase Presentation;
	local bool bIsMoviePlaying;
	local XComGameStateNetworkManager NetworkMgr;
	
	`log(`location @ `ShowVar(InviteResult.GameSettings) @ `ShowVar(m_tAcceptedGameInviteResults.Length) @ `ShowEnum(ELoginStatus, OnlineSub.PlayerInterface.GetLoginStatus(LocalUserIndex), LoginStatus), true, 'XCom_Online');

	if (!bWasSuccessful)
	{
		if (OnlineSub.PlayerInterface.GetLoginStatus(LocalUserIndex) != LS_LoggedIn)
		{
			if (class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3))
			{
				OnlineSub.PlayerInterface.AddLoginUICompleteDelegate(OnLoginUIComplete);
				OnlineSub.PlayerInterface.ShowLoginUI(true); // Show Online Only
			}
			else
			{
				InviteFailed(SystemMessage_LostConnection);
			}
		}
		else
		{
			InviteFailed(SystemMessage_BootInviteFailed);
		}
		return;
	}

	if (InviteResult.GameSettings == none)
	{
		// XCOM_EW: BUG 5321: [PCR] [360Only] Client receives the incorrect message 'Game Full' and 'you haven't selected a storage device' when accepting a game invite which has been dismissed.
		// BUG 20260: [ONLINE] - Users will soft crash when accepting an invite to a full lobby.
		InviteFailed(SystemMessage_InviteSystemError, !IsCurrentlyTriggeringBootInvite()); // Travel to the MP Menu only if the invite was made while in-game.
		return;
	}

	if ( ! InviteResult.GameSettings.bAllowInvites )
	{
		// BUG 20611: MP - Host can invite the Client into a ranked match through Steam.
		InviteFailed(SystemMessage_InviteRankedError, true);
		return;
	}

	if (CheckInviteGameVersionMismatch(XComOnlineGameSettings(InviteResult.GameSettings)))
	{
		InviteFailed(SystemMessage_VersionMismatch, true);
		return;
	}


	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.Disconnect();
	// Mark that we accepted an invite. and active game is now marked failed
	SetShuttleToMPInviteLoadout();
	bAcceptedInviteDuringGameplay = true;
	m_tAcceptedGameInviteResults[m_tAcceptedGameInviteResults.Length] = InviteResult;

	// If on the boot-train, ignore the rest of the checks and reprocess once at the next valid time.
	if (bWasSuccessful && !bHasProfileSettings)
	{
		`log(`location @ " -----> Shutting down the playing movie and returning to the MP Main Menu, then accepting the invite again.",,'XCom_Online');
		return;
	}

	bIsMoviePlaying = `XENGINE.IsAnyMoviePlaying();
	if (bIsMoviePlaying || IsPlayerReadyForInviteTrigger() )
	{
		if (bIsMoviePlaying)
		{
			// By-pass movie and continue accepting the invite.
			`XENGINE.StopCurrentMovie();
		}
		xPlayerController = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor); // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
		if (xPlayerController != none)
		{
			Presentation = xPlayerController.Pres;
			Presentation.StartMPShellState();
		}
		else
		{
			`RedScreen("Failing to transition to the MP Shell after accepting an invite. @ttalley");
		}
	}
	else
	{
		`log(`location @ "Waiting for whatever to finish and transition back to the MP Shell before entering the Loadout screen.");
	}
}

function bool CheckInviteGameVersionMismatch(XComOnlineGameSettings InviteGameSettings)
{
	local string ByteCodeHash;
	local int InstalledDLCHash;
	local int InstalledModsHash;
	local string INIHash;

	ByteCodeHash = class'Helpers'.static.NetGetVerifyPackageHashes();
	InstalledDLCHash = class'Helpers'.static.NetGetInstalledMPFriendlyDLCHash();
	InstalledModsHash = class'Helpers'.static.NetGetInstalledModsHash();
	INIHash = class'Helpers'.static.NetGetMPINIHash();

	if (ByteCodeHash == "") ByteCodeHash = "EMPTY";
	if (INIHash == "") INIHash = "EMPTY";

	`log(`location @ "InviteGameSettings=" $ InviteGameSettings.ToString(),, 'XCom_Online');
	`log(`location @ `ShowVar(InviteGameSettings.GetByteCodeHash()) @ `ShowVar(InviteGameSettings.GetInstalledDLCHash()) @ `ShowVar(InviteGameSettings.GetInstalledModsHash()) @ `ShowVar(InviteGameSettings.GetINIHash()), , 'XCom_Online');
	`log(`location @ `ShowVar(ByteCodeHash) @ `ShowVar(InstalledDLCHash) @ `ShowVar(InstalledModsHash) @ `ShowVar(INIHash),, 'XCom_Online');
	return  ByteCodeHash != InviteGameSettings.GetByteCodeHash() ||
			InstalledDLCHash != InviteGameSettings.GetInstalledDLCHash() ||
			InstalledModsHash != InviteGameSettings.GetInstalledModsHash() ||
			INIHash != InviteGameSettings.GetINIHash();
}

function bool IsPlayerInLobby()
{
	`log(self $ "::" $ GetFuncName() @ "IsInLobby=" $ XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).IsInLobby(), true, 'XCom_Online');
	return XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).IsInLobby();
}

// System Messaging
//==================================================================================================================
//

function DisplaySystemMessage(string sSystemMessage, string sSystemTitle, optional delegate<DisplaySystemMessageComplete> dOnDisplaySystemMessageComplete=OnDisplaySystemMessageComplete)
{
	local XComPresentationLayerBase Presentation;
	local XComPlayerController xPlayerController;
	local UICallbackData_SystemMessage xSystemMessageData;
	local TDialogueBoxData kData;

	xPlayerController = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor); // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	if (xPlayerController != none)
	{
		Presentation = xPlayerController.Pres;
		if (Presentation != none)
		{
			if (!Presentation.UIIsShowingDialog()) // Ignore if a dialog is already up
			{
				`log( "DISPLAY SYSTEM MESSAGE:" @ `ShowVar(Presentation.m_kProgressDialogData.strTitle, Title) @ `ShowVar(Presentation.m_kProgressDialogData.strDescription, Description),,'XCom_Online');

				xSystemMessageData = new class'UICallbackData_SystemMessage';
				xSystemMessageData.dOnSystemMessageComplete = dOnDisplaySystemMessageComplete;

				kData.eType        = eDialog_Warning;
				kData.strTitle     = sSystemTitle;
				kData.strText      = sSystemMessage;
				kData.isModal      = true;
				kData.fnCallbackEx = OnSystemMessageDialogueClosed;
				kData.xUserData    = xSystemMessageData;

				Presentation.UIRaiseDialog( kData );
			}
			else
			{
				`warn(`location @ "Unable to display message as one is already being displayed." @ `ShowVar(Presentation.m_kProgressDialogData.strTitle, Title)@ `ShowVar(Presentation.m_kProgressDialogData.strDescription, Description)@ `ShowVar(Presentation.m_kProgressDialogData.strAbortButtonText, AbortText)@ `ShowVar(Presentation.m_kProgressDialogData.strAbortButtonText, fnCallback));
			}
		}
		else
		{
			`warn(`location @ "Unable to display message as the Pres was not found." @ `ShowVar(xPlayerController));
		}
	}
	else
	{
		`warn(`location @ "Unable to display message as the XComPlayerController was not found." @ `ShowVar(class'UIInteraction'.static.GetLocalPlayer(0)));
	}
}

simulated function OnSystemMessageDialogueClosed(Name eAction, UICallbackData xUserData)
{
	local UICallbackData_SystemMessage xSystemMessageData;

	`log("OnlineEventMgr::OnSystemMessageDialogueClosed" @ eAction @ `ShowVar(xUserData),,'XCom_Online');
	DebugPrintSystemMessageQueue();

	// This was closed automatically by the system, ignore calling the callbacks.
	if (eAction == 'eUIAction_Closed')
	{
		`log(`location @ "Waiting to fire off this system message at a later time.");
	}
	else if (xUserData != none)
	{
		xSystemMessageData = UICallbackData_SystemMessage(xUserData);
		if (xSystemMessageData != none)
		{
			xSystemMessageData.dOnSystemMessageComplete();
		}
	}
}

simulated native function EnsureSavesAreComplete();

event OnSaveAsyncTaskComplete() //This is triggered when the GSaveDataTask_General task has been marked Done. Note that saving is not actually done at this point, but it is
								//safe to destroy actors
{

}

/**
 * MPLoadTimeout - The multiplayer load timer has elapsed.
 */
event OnMPLoadTimeout()
{
//bolson [PS3 TRC R180; bug 21140] - Hack to force the user back to the MP menus if they have spent too much time loading.
//                                   This can happen if the opponent disconnected while we were loading.
   m_fMPLoadTimeout = 0.0f;
`if(`isdefined(FINAL_RELEASE))  
	if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3) //ps3 only to avoid rocking the boat.
		&& `XENGINE.IsAnyMoviePlaying()) //assume we're still at the loading screen if we're still playing a movie.
	{//we're still loading, which means we've been loading for too long.  
		//We're 10 seconds away from a loading time TRC violation on the consoles.  
		//We're going to abort back to the multiplayer menu before that happens. 
		`log(`location @ "Multiplayer loading timed out.  Your opponent probably disconnected. Returned to MP menu.", true, 'XCom_Online');
		ReturnToMPMainMenu(QuitReason_OpponentDisconnected);
	}
`endif 
}

function bool OnSystemMessage_AutomatchGameFull()
{
	local XComPresentationLayerBase Presentation;
	local XComPlayerController xPlayerController;
	local bool bSuccess;

	bSuccess = false;

	xPlayerController = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor); // GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	if (xPlayerController != none)
	{
		Presentation = xPlayerController.Pres;
		if (Presentation != none)
		{
			bSuccess = Presentation.OnSystemMessage_AutomatchGameFull();
		}
	}

	return bSuccess;
}

function bool LastGameWasAutomatch()
{
	return m_kMPLastMatchInfo.m_bAutomatch;
}

function ResetAchievementState()
{
	bAchivementsEnabled = true;
	bAchievementsDisabledXComHero = false;
}

//RAM - overriding these OnlineEventMgr functions with our own to support system link
public function string GetSystemMessageString(ESystemMessageType eMessageType)
{
	local bool bOverridden;
	local string sSystemMessage;

	// GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	`log(`location @ `ShowVar(eMessageType));
	sSystemMessage = "";
	bOverridden = false;
	if (class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360))
	{
		if( Len(m_sSystemMessageStringsXBOX[eMessageType]) > 0 )
		{
			sSystemMessage = m_sSystemMessageStringsXBOX[eMessageType];
			bOverridden = true;
		}
	}
	else if (class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3))
	{
		if (Len(m_sSystemMessageStringsPS3[eMessageType]) > 0)
		{
			sSystemMessage = m_sSystemMessageStringsPS3[eMessageType];
			bOverridden = true;
		}
	}

	if ( !bOverridden )
	{
		sSystemMessage = m_sSystemMessageStrings[eMessageType];
	}

	return sSystemMessage;
}

public function string GetSystemMessageTitle(ESystemMessageType eMessageType)
{	
	local string sSystemMessage;	
	local XComPresentationLayerBase Presentation;

	// GetLocalPlayer takes player index not controller index. Do not user LocalUserIndex.
	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
	`log(`location @ `ShowVar(eMessageType) @ `ShowVar(Presentation) @ `ShowVar(Presentation.IsPresentationLayerReady()));
	sSystemMessage = "";
	sSystemMessage = m_sSystemMessageTitles[eMessageType];
	return sSystemMessage;
}

//Returns the state object cache from Temp history. TempHistory should only ever be used locally, never stored.
native function XComGameState LatestSaveState(out XComGameStateHistory TempHistory);

//Used when a piece of functionality needs to temporarily treat another history object as the canonical history. Takes the history to be considered the canonical history, returns the previous one.
native function XComGameStateHistory SwapHistory(XComGameStateHistory NewHistory);

// cpptext & defaultproperties
//==================================================================================================================
//
cpptext
{
	/**
	 * Just calls the tick event
	 *
	 * @param DeltaTime The time that has passed since last frame.
	 */
	virtual void Tick(FLOAT DeltaTime);

	virtual void WaitForSavesToComplete();
}

defaultproperties
{
	LocalUserIndex = 0
	LoginStatus = LS_NotLoggedIn
	StorageDeviceIndex = -1
	StorageDeviceName = ""
	bOnlineSubIsSteamworks = false
	bOnlineSubIsLive = false
	bOnlineSubIsPSN = false
	bHasLogin = false
	bHasProfileSettings = false
	bHasStorageDevice = false
	bShowingLoginUI = false
	bShowingLossOfDataWarning = false
	bShowingLoginRequiredWarning = false
	bShowingLossOfSaveDeviceWarning = false
	bMCPEnabledByConfig = false
	bSaveExplanationScreenHasShown = false
	OnlineStatus = OnlineStatus_MainMenu
	bStorageSelectPending = false
	bLoginUIPending = false
	bSaveDeviceWarningPending = false
	fSaveDeviceWarningPendingTimer = 0
	bInShellLoginSequence = false
	bExternalUIOpen = false
	bUpdateSaveListInProgress = false
	bPerformingStandardLoad = false
	bPerformingTransferLoad = false
	m_bStatsReadSuccessful = false
	bAchivementsEnabled = true
	CheckpointIsSerializing = false
	CheckpointIsWritingToDisk = false
	ProfileIsSerializing = false
	bAcceptedInviteDuringGameplay = false
	ChallengeModeSeedGenNum = -1
}
