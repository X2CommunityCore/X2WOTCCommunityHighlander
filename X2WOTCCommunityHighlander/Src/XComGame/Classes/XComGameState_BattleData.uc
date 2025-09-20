//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Player.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: This object represents the instance data for a tactical battle of X-Com.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_BattleData extends XComGameState_BaseObject 
	dependson(XComParcelManager, XComPlotCoverParcelManager) 
	native(Core)
	config(GameData);

enum PlotSelectionEnum
{
	ePlotSelection_Random,
	ePlotSelection_Type,
	ePlotSelection_Specify
};

struct native DirectTransferInformation_UnitStats
{
	var StateObjectReference UnitStateRef;
	var float                HP; // amount of HP this unit had before the transfer
	var int                  ArmorShred; // amount armor that was shredded on this unit before the transfer
	var int					 LowestHP; // for injuries, needs to be tracked across all parts of a mission
	var int					 HighestHP; // for injuries, needs to be tracked across all parts of a mission
	var int					 MissingHP; // for injuries, needs to be tracked across all parts of a mission
	var int					 FocusAmount;	//	for templar focus amount to be restored properly
	var bool			     RemovedFromRestOfMission; // if true, this unit was evac'd while carried, and cannot come on any further legs of the mission

	structcpptext
	{
		FDirectTransferInformation_UnitStats()
		{
			appMemzero(this, sizeof(FDirectTransferInformation_UnitStats));
		}
		FDirectTransferInformation_UnitStats(EEventParm)
		{
			appMemzero(this, sizeof(FDirectTransferInformation_UnitStats));
		}
	}
};

// This structure (and it's substructures) are intended to pass extra information along when doing a
// direct mission->mission tactical transfer. Since many gamestates are destroyed permanently when
// leaving a tactical mission, there will be various values that should be manually tracked at
// the end of each mission, such as transferred unit stats and aliens killed
struct native DirectTransferInformation
{
	var bool IsDirectMissionTransfer; // true if this battle data is being transferred over from another mission directly
	var array<DirectTransferInformation_UnitStats> TransferredUnitStats;

	// to allow us to correctly talley the number of units killed/seen at the end of the mission,
	// keep track of what has happened in the previous parts of the mission. Ideally we'd be keeping
	// all of the state information for these units along for the ride as well, but I don't think we have the
	// time to ensure that I don't accidentally break something doing that. So for now (DLC3), doing it the
	// safe way
	var int AliensSeen;
	var int AliensKilled;

	structcpptext
	{
		FDirectTransferInformation()
		{
			appMemzero(this, sizeof(FDirectTransferInformation));
		}
		FDirectTransferInformation(EEventParm)
		{
			appMemzero(this, sizeof(FDirectTransferInformation));
		}
	}
};

//RAM - copied from XGBattleDesc
//------------STRATEGY GAME DATA -----------------------------------------------
// ------- Please no touchie ---------------------------------------------------
var() string						m_strLocation;          // The city and country where this mission is taking place
var() string						m_strOpName;            // Operation name
var() string						m_strObjective;         // Squad objective
var() string						m_strDesc;              // Type of mission string
var() string						m_strTime;              // Time of Day string
var() int							m_iMissionID;           // Mission ID in the strategy layer
var() int							m_iMissionType;         // CHENG - eMission_TerrorSite
var() EShipType						m_eUFOType;
var() EContinent					m_eContinent;
var() ETOD							m_eTimeOfDay;
var() bool							m_bOvermindEnabled;
var() bool							m_bIsFirstMission;      // Is this the player's very first mission?
var() bool							m_bIsTutorial;          // Is this the tutorial
var() bool							m_bDisableSoldierChatter; // Disable Soldier Chatter
var() bool							m_bIsIronman;           // Is the player in Ironman mode?
var() bool							m_bScripted;            // Is this mission the scripted first mission?
var() float							m_fMatchDuration;
var() array<int>					m_arrSecondWave;
var() int							m_iPlayCount;
var() bool							m_bSilenceNewbieMoments;
var() bool							bIsTacticalQuickLaunch; //Flag set to true if this is a tactical battle that was started via TQL
var() TDateTime						LocalTime;			    //The local time at the mission site

var name DefaultLeaderListOverride;
var name DefaultFollowerListOverride;

//RAM - these are legacy from EU/EW
var() string						m_strMapCommand;        // Name of map

//Used by the tactical quick launch process to pick a map
var PlotSelectionEnum               PlotSelectionType;
var string                          PlotType;

// A list of unit state objects being treated as "rewards" for the mission
var() array<StateObjectReference>   RewardUnits;

// A list of the original units that the reward unit proxies were created from.
// Not for use in tactical, it simply maintains the links to the reward proxies so that
// we can sync them up after the mission.
var() array<StateObjectReference>   RewardUnitOriginals;

//Saved data describing the layout of the level
var() PlotDefinition				PlotData; //Backwards compatibility
var() StoredMapData					MapData;

// active sitreps in this battle
var() array<name>                   ActiveSitReps;

//Temporary variable for save load of the parcel system. Eventually we need to replace this with a parcel state object.
var() int							iLevelSeed;
var() int							iFirstStartTurnSeed;    // Specified Seed for whenever the map is done loading and the first turn is about to be taken.
var() bool							bUseFirstStartTurnSeed; // If set, will set the engine's random seed with the specified iFirstStartTurnSeed after the map has been loaded or generated.

//From profile/shell
var() int							m_iSubObjective;
var() name 							m_nQuestItem;
var() int							m_iLayer;
var() privatewrite int				m_iForceLevel;
var() privatewrite int				m_iAlertLevel;
var() privatewrite int				m_iPopularSupport;
var() privatewrite int				m_iMaxPopularSupport;

// The tactical gameplay events affecting Alert/Popular support levels
var() array<Name>					AlertEventIDs;
var() array<Name>					PopularSupportEventIDs;

var() StateObjectReference			CivilianPlayerRef;

var() bool							bRainIfPossible;	// Rain if the map supports rain
//------------------------------------------------------------------------------
//------------END STRATEGY GAME DATA -------------------------------------------

var() bool							bIntendedForReloadLevel; //variable that gets checked so that we know if we want to create a new game, or load one instead when restarting a match
var() DirectTransferInformation     DirectTransferInfo; // data used to facilitate direct mission->mission transfer carryover

//These variables deal with controlling the flow of the Unit Actions turn phase
var() array<StateObjectReference>   PlayerTurnOrder;	 //Indicates the order in which the players take the unit actions phase of their turn
var() StateObjectReference			InterruptingGroupRef;	// the ref to the AIGroup that is interrupting the normal turn order
var() StateObjectReference			InterruptedUnitRef; // the ref to the unit that had the selection when turn order was interrupted
var() private array<name>           AllowedAbilities;	 //Some abilities must be enabled by kismet. That is tracked here.
var() private array<name>           DisallowedAbilities; //Some abilities can be disabled by kismet. That is tracked here.
var() private array<name>           HighlightedObjectiveAbilities; //Abilities which have been flagged by kismet to show with a green background
var() bool                          bMissionAborted;	 //If Abort Mission ability is used, this will be set true.
var() bool                          bLocalPlayerWon;     //Set true during BuildTacticalGameEndGameState if the victorious player is XCom / Local Player
var() StateObjectReference          VictoriousPlayer;    //Set to the player who won the match

// The bucket of loot that will be awarded to the XCom player if they successfully complete all tactical mission objectives on this mission.
var() array<Name>					AutoLootBucket;

// The bucket of loot that was carried out of the mission by XCom soldiers.
var() array<Name>					CarriedOutLootBucket;


// The list of all unique once-per-mission hack rewards that have already been acquired this mission.
var() array<Name>					UniqueHackRewardsAcquired;

// The list of the tactical hack rewards that are available to be acquired this mission.
var() array<Name>					TacticalHackRewards;

// The list of the strategy hack rewards that are available to be acquired this mission.
var() array<Name>					StrategyHackRewards;

// True if a tactical hack has already been completed for this battle.
var() bool							bTacticalHackCompleted;

// Great Mission and tough mission bool for after action and reward recap VO
var() bool bGreatMission;
var() bool bToughMission;

// Chosen vars for triggering VO on the post-mission walkup
var() StateObjectReference ChosenRef;
var() bool bChosenWon;
var() bool bChosenLost;
var() bool bChosenDefeated; // Was the Chosen permanently killed on a Stronghold

// Faction Hero vars for after action VO
var() array<StateObjectReference> FactionHeroesOnMission;
var() array<StateObjectReference> FactionHeroesCaptured;
var() array<StateObjectReference> FactionHeroesKilled;
var() array<StateObjectReference> FactionHeroesHighLevel;
var() bool bSoldierCaptured;

var() bool bRulerEscaped;
var() bool bBondAvailable;
var() bool bBondLevelUpAvailable;

var() int iMaxSquadCost;
var() int iTurnTimeSeconds;
var() bool bMultiplayer;
var() bool bRanked;
var() bool bAutomatch;
var() string strMapType;

var StateObjectReference UnitActionInitiativeRef;			//Reference to the XComGameState_Player or XComGameState_AIGroup that is currently taking unit actions
var StateObjectReference UnitActionPlayerRef;				//Reference to the XComGameState_Player that is currently taking unit actions

var string BizAnalyticsMissionID;

// the current tactical turn
var int TacticalTurnCount;

// the current level of LostSpawn value
var int LostSpawningLevel;

// at this threshold level, the lost timer will advance
var config int LostLoudSoundThreshold;
var config int LostMaxWaves;
var config int MinLostSpawningLevelWhileConcealed;

var bool bLostSpawningDisabledViaKismet;

var int LostQueueStrength;
var int LostLastSoundMagnitude; // For reporting sound volume to kismet, used for Lost and Abandoned dialogue hooks

// how far away from xcom (in tiles) new lost groups will try to spawn in
var config int LostSpawningDistance;

// This many turns of cooldown after the last spawn of the lost before lost spawning can resume
var config array<int> MinLostSpawnTurnCooldown;
var config array<int> MaxLostSpawnTurnCooldown;

var int KismetMinLostSpawnTurnOverride;
var int KismetMaxLostSpawnTurnOverride;

// Default group ID for lost reinforcements - can be overriden by Kismet
var name LostGroupID;
var config array<name> LostSwarmIDs;

// how far away from xcom (in tiles) new Chosen will try to spawn in
var config int ChosenSpawningDistance;
var bool bChosenSpawningDisabledViaKismet;

var int TacticalEventAbilityPointsGained;
var array<int> TacticalEventGameStates;

// Kismet driven control for disabling intercept movement (implemented for Compound Rescue)
var bool bKismetDisabledInterceptMovement;

var bool bForceNoSquadConcealment;

var string TQLEnemyForcesSelection;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

final function ResetObjectiveCompletionStatus()
{
	local int ObjectiveIndex;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted = false;
	}
}

final function CompleteObjective(Name ObjectiveName)
{
	local int ObjectiveIndex;
	local Object ThisObj;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( MapData.ActiveMission.MissionObjectives[ObjectiveIndex].ObjectiveName == ObjectiveName )
		{
			MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted = true;
			`Log("Marked mission objective #"$ObjectiveIndex@"as completed.");
		}
	}
	ThisObj = self;
	`XEVENTMGR.TriggerEvent('OnMissionObjectiveComplete', ThisObj, ThisObj);
}

final function bool AllTacticalObjectivesCompleted()
{
	local int ObjectiveIndex;
	local bool AnyTacticalObjectives;

	AnyTacticalObjectives = false;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bIsTacticalObjective )
		{
			if( !MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted )
			{
				return false;
			}

			AnyTacticalObjectives = true;
		}
	}

	return AnyTacticalObjectives;
}

final function bool AllStrategyObjectivesCompleted()
{
	local int ObjectiveIndex;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bIsStrategyObjective && !MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted )
		{
			return false;
		}
	}

	return true;
}

final function bool OneStrategyObjectiveCompleted()
{
	local int ObjectiveIndex;

	for(ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex)
	{
		if(MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bIsStrategyObjective && MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted)
		{
			return true;
		}
	}

	return false;
}

final function bool AllTriadObjectivesCompleted()
{
	local int ObjectiveIndex;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bIsTriadObjective && !MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted )
		{
			return false;
		}
	}

	return true;
}


function SetForceLevel(int NewForceLevel)
{
	m_iForceLevel = NewForceLevel;
}

function SetAlertLevel(int NewAlertLevel)
{
	m_iAlertLevel = NewAlertLevel;
}

function SetPopularSupport( int NewPopVal )
{
	m_iPopularSupport = NewPopVal;
}

function int GetPopularSupport()
{
	return m_iPopularSupport;
}

function SetMaxPopularSupport( int NewMaxPopVal )
{
	m_iMaxPopularSupport = NewMaxPopVal;
}

function int GetMaxPopularSupport()
{
	return m_iMaxPopularSupport;
}

event bool ShouldOverrideCivilianHostility()
{
	local Name SitRepName;
	foreach ActiveSitReps(SitRepName)
	{
		if (class'X2SitRepTemplateManager'.static.ShouldOverrideCivilianHostility(SitRepName))
		{
			return true;
		}
	}
	return false;
}

native function int GetForceLevel();
native function int GetAlertLevel();

native function bool AlertLevelThresholdReached(int Threshold);
native function bool AlertLevelSupportsPCPCheckpoints();
native function bool AlertLevelSupportsPCPTurrets();

native function bool AreCiviliansAlienTargets();
native function bool AreCiviliansAlwaysVisible();
native function bool CiviliansAreHostile();

static function bool SetGlobalAbilityEnabled(name AbilityName, bool Enabled, optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local X2AbilityTemplateManager AbilityMan;
	local XComGameState_BattleData BattleData;
	local X2TacticalGameRuleset Rules; 
	local bool SubmitState;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	if(AbilityMan.FindAbilityTemplate(AbilityName) == none)
	{
		return false;
	}
		
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if (BattleData == none)
	{
		`RedScreen(GetFuncName() @ "activated for" @ AbilityName @ "but no BattleData state object exists.");
		return false;
	}

	if (Enabled)
	{
		if(BattleData.AllowedAbilities.Find(AbilityName) == INDEX_NONE || BattleData.DisallowedAbilities.Find(AbilityName) != INDEX_NONE)
		{
			if(NewGameState == none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ AbilityName);
				SubmitState = true;
			}
			BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(BattleData.Class, BattleData.ObjectID));
			BattleData.AllowedAbilities.AddItem(AbilityName);
			BattleData.DisallowedAbilities.RemoveItem(AbilityName);
		}
	}	
	else
	{
		if(BattleData.AllowedAbilities.Find(AbilityName) != INDEX_NONE || BattleData.DisallowedAbilities.Find(AbilityName) == INDEX_NONE)
		{
			if(NewGameState == none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ AbilityName);
				SubmitState = true;
			}
			BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(BattleData.Class, BattleData.ObjectID));
			BattleData.AllowedAbilities.RemoveItem(AbilityName);
			BattleData.DisallowedAbilities.AddItem(AbilityName);
		}
	}

	if(SubmitState)
	{
		Rules = `TACTICALRULES;
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("Failed to submit state from" @ GetFuncName());
			return false;
		}
	}

	return true;
}

static function bool HighlightObjectiveAbility(name AbilityName, bool Enabled, optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local X2AbilityTemplateManager AbilityMan;
	local XComGameState_BattleData BattleData;
	local X2TacticalGameRuleset Rules; 
	local bool SubmitState;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	if(AbilityMan.FindAbilityTemplate(AbilityName) == none)
	{
		return false;
	}
		
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if (BattleData == none)
	{
		`RedScreen(GetFuncName() @ "activated for" @ AbilityName @ "but no BattleData state object exists.");
		return false;
	}

	if (Enabled && BattleData.HighlightedObjectiveAbilities.Find(AbilityName) == INDEX_NONE)
	{
		if(NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ AbilityName);
			SubmitState = true;
		}
		BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(BattleData.Class, BattleData.ObjectID));
		BattleData.HighlightedObjectiveAbilities.AddItem(AbilityName);
	}	
	else if(!Enabled && BattleData.HighlightedObjectiveAbilities.Find(AbilityName) != INDEX_NONE)
	{
		if(NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ AbilityName);
			SubmitState = true;
		}
		BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(BattleData.Class, BattleData.ObjectID));
		BattleData.HighlightedObjectiveAbilities.RemoveItem(AbilityName);
	}

	if(SubmitState)
	{
		Rules = `TACTICALRULES;
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("Failed to submit state from" @ GetFuncName());
			return false;
		}
	}

	return true;
}

function bool IsAbilityGloballyDisabled(name AbilityName)
{
	local X2AbilityTemplate Template;

	Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
	if(Template != none)
	{
		if (Template.bAllowedByDefault)
		{
			return DisallowedAbilities.Find(AbilityName) != INDEX_NONE;
		}
		else
		{
			return AllowedAbilities.Find(AbilityName) == INDEX_NONE;
		}
		
	}

	return false;
}

function bool IsAbilityObjectiveHighlighted(X2AbilityTemplate AbilityTemplate)
{
	local int idx;

	// check for the ability
	if (HighlightedObjectiveAbilities.Find( AbilityTemplate.DataName ) != INDEX_NONE)
		return true;

	// check if this ability is an equivalent replacement (ie Intrusion Protocol vs Hack)
	for (idx = 0; idx < AbilityTemplate.OverrideAbilities.Length; ++idx)
	{
		if (HighlightedObjectiveAbilities.Find( AbilityTemplate.OverrideAbilities[idx] ) != INDEX_NONE)
			return true;
	}

	return false;
}

// Hooks for tracking gameplay events affecting strategy layer alert level & pop support

function AddAlertEvent(Name EventID, XComGameState NewGameState=None)
{
	local XComGameState_BattleData NewBattleData;
	local bool NewGameStateMustBeSubmitted;

	NewGameStateMustBeSubmitted = false;
	if( NewGameState == None )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ EventID);
		NewGameStateMustBeSubmitted = true;
	}

	NewBattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(Class, ObjectID));
	NewBattleData.AlertEventIDs.AddItem(EventID);

	if( NewGameStateMustBeSubmitted )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function AddPopularSupportEvent(Name EventID, XComGameState NewGameState=None)
{
	local XComGameState_BattleData NewBattleData;
	local bool NewGameStateMustBeSubmitted;

	NewGameStateMustBeSubmitted = false;
	if( NewGameState == None )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ EventID);
		NewGameStateMustBeSubmitted = true;
	}

	NewBattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(Class, ObjectID));
	NewBattleData.PopularSupportEventIDs.AddItem(EventID);

	if( NewGameStateMustBeSubmitted )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

private function bool FindChosenOnMissionSpawningTag(XComGameState NewGameState, optional out name ChosenSpawningTag)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local array<name> AllChosenSpawningTags;
	local int i;
	local bool bFoundTag;

	bFoundTag = false;
	if( !bChosenSpawningDisabledViaKismet )
	{
		// Check to see if any of the chosen TacticalGameplayTags are present, if so set a listener that acts as the Chosens' activate ability
		XComHQ = `XCOMHQ;

		AllChosenSpawningTags = class'XComGameState_HeadquartersAlien'.static.GetAllChosenSpawningTags();

		for( i = 0; i < XComHQ.TacticalGameplayTags.Length; ++i )
		{
			if( AllChosenSpawningTags.Find(XComHQ.TacticalGameplayTags[i]) != INDEX_NONE )
			{
				ChosenSpawningTag = XComHQ.TacticalGameplayTags[i];
				bFoundTag = true;

				break;
			}
		}

		if( !bFoundTag )
		{
			ChosenSpawningTag = '';
		}
	}

	return bFoundTag;
}

function OnBeginTacticalPlay(XComGameState NewGameState)
{
	local Object ThisObj;
	local X2EventManager EventManager;

	super.OnBeginTacticalPlay(NewGameState);
	TacticalTurnCount = 0;
	LostQueueStrength = 0;
	LostSpawningLevel = SelectLostActivationCount();
	LostGroupID = default.LostSwarmIDs[`TacticalDifficultySetting];

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted);

	// Check to see if any of the chosen TacticalGameplayTags are present, if so set a listener that acts as the Chosens' activate ability
	if (FindChosenOnMissionSpawningTag(NewGameState))
	{
		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnEnded', ActivateChosenAlert, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObj, 'UnitDied', ActivateChosenAlertOnUnitDeath, ELD_OnStateSubmitted);
	}

	EventManager.RegisterForEvent(ThisObj, 'UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted);
	EventManager.RegisterForEvent(ThisObj, 'UnitSpawned', OnUnitSpawned, ELD_OnStateSubmitted);
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted);
}

// Upon any AI unit getting alerted, we activate the chosen, to be revealed on the start of the next turn.
function EventListenerReturn ActivateChosenAlert(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Player PlayerState;

	// Check to see if there are any XCom are not 
	PlayerState = XComGameState_Player(EventData);
	if( PlayerState.TeamFlag == eTeam_XCom &&
		PlayerState.IsAnySquadMemberRevealed() )
	{
		InternalActivateChosenAlert();
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn ActivateChosenAlertOnUnitDeath(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Player PlayerState;
	PlayerState = class'XComGameState_Player'.static.GetPlayerState(eTeam_XCom);
	// Update for TTP 17473 -  do not activate the Chosen unless the enemy is unconcealed.
	if (PlayerState.IsAnySquadMemberRevealed())
	{
		InternalActivateChosenAlert();
	}

	return ELR_NoInterrupt;
}

function InternalActivateChosenAlert()
{
	local Object ThisObj;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;
		ThisObj = self;

	EventManager.UnRegisterFromEvent(ThisObj, 'PlayerTurnEnded', , ActivateChosenAlert);
	EventManager.UnRegisterFromEvent(ThisObj, 'UnitDied', , ActivateChosenAlertOnUnitDeath);
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', ActivatedChosenSpawnListener, ELD_OnStateSubmitted);
}

function EventListenerReturn ActivatedChosenSpawnListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local Object ThisObj;
	local X2EventManager EventManager;
	local name SpawnTag, EncounterID;
	local XComTacticalMissionManager MissionManager;
	local int Index;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameState NewGameState;
	local XComGameState_Player PlayerState;

	// attempt to activate the chosen only at the start of the alien turn
	PlayerState = XComGameState_Player(EventData);
	if( PlayerState.TeamFlag == eTeam_Alien )
	{
		EventManager = `XEVENTMGR;
		ThisObj = self;

		EventManager.UnRegisterFromEvent(ThisObj, 'PlayerTurnBegun', , ActivatedChosenSpawnListener);

		if( FindChosenOnMissionSpawningTag(GameState, SpawnTag) )
		{
			MissionManager = `TACTICALMISSIONMGR;

			Index = MissionManager.ChosenSpawnTagToEncounterID.Find('SpawningTag', SpawnTag);

			if( Index != INDEX_NONE )
			{
				TacticalRules = `TACTICALRULES;
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Activated Chosen Spawn");

				EncounterID = MissionManager.ChosenSpawnTagToEncounterID[Index].EncounterID;
				class'XComGameState_AIReinforcementSpawner'.static.InitiateReinforcements(EncounterID,
					0,
					,
					,
					ChosenSpawningDistance,
					NewGameState,
					,
					'',
					true,
					false,
					true,
					false,
					true,
					true);

				TacticalRules.SubmitGameState(NewGameState);
			}
		}
	}

	return ELR_NoInterrupt;
}

function int GetAlertLevelBonus()
{
	local int TotalBonus, i;

	TotalBonus = 0;

	for( i = 0; i < AlertEventIDs.length; ++i )
	{
		TotalBonus += class'X2ExperienceConfig'.static.GetAlertLevelBonusForEvent(AlertEventIDs[i]);
	}

	return TotalBonus;
}

function int GetPopularSupportBonus()
{
	local int TotalBonus, i;

	TotalBonus = 0;

	for( i = 0; i < PopularSupportEventIDs.length; ++i )
	{
		TotalBonus += class'X2ExperienceConfig'.static.GetPopularSupportBonusForEvent(PopularSupportEventIDs[i]);
	}

	return TotalBonus;
}


function AwardTacticalGameEndBonuses(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local Name MissionResultEventID;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	if(bLocalPlayerWon)
	{
		MissionResultEventID = MissionState.GetMissionSuccessEventID();
	}
	else
	{
		MissionResultEventID = MissionState.GetMissionFailureEventID();
	}

	AddPopularSupportEvent(MissionResultEventID, NewGameState);
	AddAlertEvent(MissionResultEventID, NewGameState);
}

function SetVictoriousPlayer(XComGameState_Player Winner, bool bWinnerIsLocal)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local X2MissionSourceTemplate MissionSource;

	if(bWinnerIsLocal)
	{
		History = `XCOMHISTORY;
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(m_iMissionID));

		if(MissionState != none)
		{
			MissionSource = MissionState.GetMissionSource();

			if(MissionSource.WasMissionSuccessfulFn != none)
			{
				bLocalPlayerWon = MissionSource.WasMissionSuccessfulFn(self);
			}
			else
			{
				bLocalPlayerWon = true;
			}
		}
		else
		{
			bLocalPlayerWon = true;
		}	
	}
	else
	{
		bLocalPlayerWon = false;
	}
	
	VictoriousPlayer = Winner.GetReference();
}

function bool IsMultiplayer()
{	
	return bMultiplayer;
}

function SetPostMissionGrade()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_ResistanceFaction FactionState;
	local int idx, NumWounded, NumDead, NumSquad, NumCaptured;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	NumWounded = 0;
	NumDead = 0;
	NumCaptured = 0;
	NumSquad = 0;

	FactionHeroesOnMission.Length = 0;
	FactionHeroesCaptured.Length = 0;
	FactionHeroesKilled.Length = 0;
	FactionHeroesHighLevel.Length = 0;
	bSoldierCaptured = false;

	for(idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

		if(UnitState != none)
		{
			NumSquad++;
			if(UnitState.IsDead())
			{
				NumDead++;
				if (UnitState.IsResistanceHero())
				{
					FactionState = UnitState.GetResistanceFaction();
					if (FactionState.GetHeroKilledEvent() != '')
					{
						FactionHeroesKilled.AddItem(FactionState.GetReference());
					}
				}
			}
			else if (UnitState.bCaptured)
			{
				if(UnitState.ChosenCaptorRef.ObjectID != 0)
				{
					bSoldierCaptured = true;
					if(UnitState.IsResistanceHero())
					{
						FactionState = UnitState.GetResistanceFaction();
						if(FactionState.GetHeroCapturedEvent() != '')
						{
							FactionHeroesCaptured.AddItem(FactionState.GetReference());
						}
					}
				}

				NumCaptured++;
			}
			else
			{
				if (UnitState.IsResistanceHero())
				{
					FactionState = UnitState.GetResistanceFaction();
					if (FactionState.GetHeroOnMissionEvent() != '')
					{
						FactionHeroesOnMission.AddItem(FactionState.GetReference());
					}
					
					if (UnitState.GetRank() > 5)
					{
						FactionHeroesHighLevel.AddItem(FactionState.GetReference());
					}
				}

				if (UnitState.IsInjured())
				{
					NumWounded++;
				}
			}
		}
	}

	bGreatMission = false;
	bToughMission = false;
	if(bLocalPlayerWon && (NumDead + NumCaptured) == 0 && NumWounded <= 1)
	{
		bGreatMission = true;
	}
	else if((NumDead + NumCaptured) > (NumSquad / 2))
	{
		bToughMission = true;
	}
}

static function bool TacticalHackCompleted()
{
	local XComGameState_BattleData BattleData;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	return BattleData != None && BattleData.bTacticalHackCompleted;
}


function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(EventData);

	if( PlayerState.TeamFlag == eTeam_TheLost )
	{
		AdvanceLostSpawning(LostLoudSoundThreshold);
	}

	return ELR_NoInterrupt;
}

// get the number of turns till the lost should spawn if no explosions shorten it
static function int SelectLostActivationCount()
{
	local int MinCooldown, MaxCooldown;
	local XComGameState_BattleData BattleData;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if(BattleData.KismetMinLostSpawnTurnOverride > 0 && BattleData.KismetMaxLostSpawnTurnOverride > 0)
	{
		MinCooldown = BattleData.KismetMinLostSpawnTurnOverride;
		MaxCooldown = BattleData.KismetMaxLostSpawnTurnOverride;
	}
	else
	{
		MinCooldown = `ScaleTacticalArrayInt(default.MinLostSpawnTurnCooldown);
		MaxCooldown = `ScaleTacticalArrayInt(default.MaxLostSpawnTurnCooldown);
	}

	return `SYNC_RAND_STATIC(MaxCooldown - MinCooldown) + MinCooldown;
}

static event AdvanceLostSpawning(int ActivationAmount, bool bSoundAdvance = false, bool bForceImmediateActivation = false )
{
	local XComGameState NewGameState;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bLostHowlTriggered;
	local XComGameState_Player PlayerState;
	local bool bReinforcementSuccess;

	XComHQ = `XCOMHQ;
		BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if(	(XComHQ.TacticalGameplayTags.Find('SITREP_TheLost') != INDEX_NONE || XComHQ.TacticalGameplayTags.Find('SITREP_TheHorde') != INDEX_NONE) &&
	   !BattleData.bLostSpawningDisabledViaKismet &&
	   ( BattleData.LostMaxWaves < 0 || BattleData.LostQueueStrength < BattleData.LostMaxWaves ) &&
	   ( bForceImmediateActivation || (ActivationAmount >= BattleData.LostLoudSoundThreshold) ) )
	{

		TacticalRules = `TACTICALRULES;
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Lost Spawning advanced");

		BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

		--BattleData.LostSpawningLevel;

		// limit the lost countdown timer while xcom is concealed
		if( BattleData.LostSpawningLevel < BattleData.MinLostSpawningLevelWhileConcealed )
		{
			PlayerState = class'XComGameState_Player'.static.GetPlayerState(eTeam_XCom);
			if( PlayerState.bSquadIsConcealed )
			{
				BattleData.LostSpawningLevel = BattleData.MinLostSpawningLevelWhileConcealed;
			}
		}

		// the howler yell will always immediately spawn the next lost group
		if( bForceImmediateActivation )
		{
			BattleData.LostSpawningLevel = 0;
		}

		`XEVENTMGR.TriggerEvent('LostSoundLevelChanged', BattleData, BattleData, NewGameState);

		`log("Lost spawn level decreased from" @ (BattleData.LostSpawningLevel + 1) @ "to" @ BattleData.LostSpawningLevel);

		bLostHowlTriggered = true;

		// Check against the lost spawning threshold to see if we need to queue a pack
		if( BattleData.LostSpawningLevel <= 0 )
		{
			`log("calling Lost reinforcements.");

			bReinforcementSuccess = class'XComGameState_AIReinforcementSpawner'.static.InitiateReinforcements(BattleData.LostGroupID, 0, , , BattleData.LostSpawningDistance, NewGameState, , 'TheLostSwarm', true, false, true, true, true);

			if( bReinforcementSuccess )
			{
				// Set lost group strength
				BattleData.LostQueueStrength += 1;

				// reached spawning threshold, reset the counter and spawn a swarm of Lost
				BattleData.LostSpawningLevel = SelectLostActivationCount();

				// Lost are incoming on next turn, play world message
				NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BattleData.LostSpawnVisualizationWorldMessage);

				`XEVENTMGR.TriggerEvent('LostThresholdPassed', BattleData, BattleData, NewGameState);
			}
		}
		else if( BattleData.LostSpawningLevel == 1 )
		{
			// The Lost are close to spawning a swarm
			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BattleData.LostAlmostSpawnVisualizationWorldMessage);
			`XEVENTMGR.TriggerEvent('OnLostApproaching', , , NewGameState);
		}
		else if( bSoundAdvance )
		{
			// The player did something really loud, play a world message
			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BattleData.LostHowlVisualizationWorldMessage);
		}
		else
		{
			bLostHowlTriggered = false; // No howl or major Lost spawn state changes, so don't trigger the event
		}

		if (bLostHowlTriggered)
		{
			`XEVENTMGR.TriggerEvent('OnLostHowl', , , NewGameState);
		}

		TacticalRules.SubmitGameState(NewGameState);
	}
}

// Triggered when the Lost will spawn on the next turn
function LostSpawnVisualizationWorldMessage(XComGameState VisualizeGameState)
{
	AddLostWorldMessage(VisualizeGameState, class'XLocalizedData'.default.LostSpawnMessage);
	`XTACTICALSOUNDMGR.PlaySoundEvent("Lost_Reinforcements_Call");
}

function LostAlmostSpawnVisualizationWorldMessage(XComGameState VisualizeGameState)
{
	AddLostWorldMessage(VisualizeGameState, class'XLocalizedData'.default.LostAlmostSpawnMessage);
	`XTACTICALSOUNDMGR.PlaySoundEvent("Lost_Reinforcements_Call");
}

function LostHowlVisualizationWorldMessage(XComGameState VisualizeGameState)
{
	AddLostWorldMessage(VisualizeGameState, class'XLocalizedData'.default.LostLoudNoiseMessage);
	`XTACTICALSOUNDMGR.PlaySoundEvent("Lost_Reinforcements_Response");
}

function AddLostWorldMessage(XComGameState VisualizeGameState, string LostMessage)
{
	//local XComPresentationLayer Presentation;
	local XComGameStateHistory History;
	local VisualizationActionMetadata BuildData;
	local X2Action_PlayMessageBanner MessageAction;

	//Presentation = `PRES;
	History = `XCOMHISTORY;

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, BuildData.StateObject_OldState, BuildData.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	BuildData.VisualizeActor = History.GetVisualizer(ObjectID);

	MessageAction = X2Action_PlayMessageBanner(class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree(BuildData, VisualizeGameState.GetContext()));
	MessageAction.AddMessageBanner(class'UIEventNoticesTactical'.default.TheLostTitle,
								   /*"img:///UILibrary_XPACK_Common.target_lost"*/,
								   "",
								   LostMessage,
								   eUIState_Warning);
}

// Helper functions for manipulating the direct transfer states
function StoreDirectTransferUnitStats(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit StatsUnit;
	local int TransferDataIndex;

	// if the unit was removed from play, it's stat buffs from armor and such have also been removed.
	// In order to get the correct health and armor values, we need to go back in time
	// to the point they left the level
	if(UnitState.bRemovedFromPlay)
	{
		History = `XCOMHISTORY;
		StatsUnit = UnitState;
		while(StatsUnit != none && StatsUnit.bRemovedFromPlay)
		{
			StatsUnit = XComGameState_Unit(History.GetPreviousGameStateForObject(StatsUnit));
		}

		if(StatsUnit != none)
		{
			UnitState = StatsUnit;
		}
	}
	
	// copy their stats to the transfer info. This needs to happen before we remove abilities and effects, as
	// they could change the stat values
	for(TransferDataIndex = 0; TransferDataIndex < DirectTransferInfo.TransferredUnitStats.Length; TransferDataIndex++)
	{
		if(DirectTransferInfo.TransferredUnitStats[TransferDataIndex].UnitStateRef.ObjectID == UnitState.ObjectID)
		{
			break;
		}
	}

	if(TransferDataIndex >= DirectTransferInfo.TransferredUnitStats.Length)
	{
		DirectTransferInfo.TransferredUnitStats.Add(1);
	}

	DirectTransferInfo.TransferredUnitStats[TransferDataIndex].UnitStateRef = UnitState.GetReference();
	DirectTransferInfo.TransferredUnitStats[TransferDataIndex].HP = UnitState.GetCurrentStat(eStat_HP);
	DirectTransferInfo.TransferredUnitStats[TransferDataIndex].ArmorShred = UnitState.Shredded;
	DirectTransferInfo.TransferredUnitStats[TransferDataIndex].LowestHP = UnitState.LowestHP;
	DirectTransferInfo.TransferredUnitStats[TransferDataIndex].HighestHP = UnitState.HighestHP;
	DirectTransferInfo.TransferredUnitStats[TransferDataIndex].MissingHP = UnitState.MissingHP;
	DirectTransferInfo.TransferredUnitStats[TransferDataIndex].RemovedFromRestOfMission = 
		DirectTransferInfo.TransferredUnitStats[TransferDataIndex].RemovedFromRestOfMission || UnitState.IsBeingCarried();

	DirectTransferInfo.TransferredUnitStats[TransferDataIndex].FocusAmount = UnitState.GetTemplarFocusLevel();
}

function bool IsUnitRemovedFromRestOfMission(XComGameState_Unit UnitState)
{
	local int TransferDataIndex;

	// copy their stats to the transfer info. This needs to happen before we remove abilities and effects, as
	// they could change the stat values
	for(TransferDataIndex = 0; TransferDataIndex < DirectTransferInfo.TransferredUnitStats.Length; TransferDataIndex++)
	{
		if(DirectTransferInfo.TransferredUnitStats[TransferDataIndex].UnitStateRef.ObjectID == UnitState.ObjectID)
		{
			return DirectTransferInfo.TransferredUnitStats[TransferDataIndex].RemovedFromRestOfMission;
		}
	}

	return false;
}

function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit EventUnit;

	EventUnit = XComGameState_Unit(EventData);

	if( EventUnit.GetTeam() == eTeam_XCom )
	{
		CheckFirstSightingOfAnyEnemy(GameState.HistoryIndex);
	}
	else
	{
		CheckFirstSightingOfSpecificEnemy(EventUnit, GameState.HistoryIndex);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitSpawned(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit SpawnedUnit;

	SpawnedUnit = XComGameState_Unit(EventData);

	if( SpawnedUnit.GetTeam() == eTeam_XCom )
	{
		CheckFirstSightingOfAnyEnemy(GameState.HistoryIndex);
	}
	else
	{
		CheckFirstSightingOfSpecificEnemy(SpawnedUnit, GameState.HistoryIndex);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	CheckFirstSightingOfAnyEnemy(GameState.HistoryIndex);

	return ELR_NoInterrupt;
}

function CheckFirstSightingOfAnyEnemy(int HistoryIndex)
{
	local StateObjectReference SightedUnitStateRef;
	local array<StateObjectReference> VisibleUnits;
	local XComGameState_Unit SightedUnit, ViewingUnitState;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local array<X2Condition> RequiredConditions;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	RequiredConditions = class'X2TacticalVisibilityHelpers'.default.LivingGameplayVisibleFilter;

	foreach History.IterateByClassType(class'XComGameState_Unit', ViewingUnitState, eReturnType_Reference, , HistoryIndex)
	{
		if( ViewingUnitState.GetTeam() == eTeam_XCom )
		{
			VisibilityMgr.GetAllVisibleToSource(ViewingUnitState.ObjectID, VisibleUnits, class'XComGameState_Unit', HistoryIndex, RequiredConditions);
			foreach VisibleUnits(SightedUnitStateRef)
			{
				SightedUnit = XComGameState_Unit(History.GetGameStateForObjectID(SightedUnitStateRef.ObjectID, , HistoryIndex));
				if( SightedUnit != none && ViewingUnitState.IsEnemyUnit(SightedUnit) )
				{
					CheckFirstSightingOfSpecificEnemyFromViewer(SightedUnit, ViewingUnitState, HistoryIndex);
				}
			}
		}
	}
}


function CheckFirstSightingOfSpecificEnemy(XComGameState_Unit SightedUnit, int HistoryIndex)
{
	local XComGameState_Unit ViewingUnitState;
	local XComGameStateHistory History;
	local array<StateObjectReference> Viewers;
	local bool bAnyPlayerControlledViewers;
	local int Index;

	// determine if the player has visibility of the SightedUnit, and if so, play the first sighting sequence
	class'X2TacticalVisibilityHelpers'.static.GetEnemyViewersOfTarget(SightedUnit.ObjectID, Viewers, HistoryIndex);

	if( Viewers.Length > 0 )
	{
		History = `XCOMHISTORY;

		for (Index = 0; Index < Viewers.Length; ++Index)
		{
			ViewingUnitState = XComGameState_Unit(History.GetGameStateForObjectID(Viewers[Index].ObjectID, , HistoryIndex));
			if (!ViewingUnitState.ControllingPlayerIsAI())
			{
				bAnyPlayerControlledViewers = true;
				break;
			}
		}

		if (bAnyPlayerControlledViewers)
		{
			CheckFirstSightingOfSpecificEnemyFromViewer(SightedUnit, ViewingUnitState, HistoryIndex);
		}
	}
}

function CheckFirstSightingOfSpecificEnemyFromViewer( XComGameState_Unit SightedUnit, XComGameState_Unit ViewingUnitState, int HistoryIndex)
{
	local XComGameState_Unit GroupLeaderUnitState;
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AIGroup AIGroupState;
	local XComGameState_AIGroup NewGroupState;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local int i;
	local bool bPlayFirstSighting;

	if( ViewingUnitState != none )
	{
		AIGroupState = SightedUnit.GetGroupMembership();

		if( AIGroupState != None && !AIGroupState.EverSightedByEnemy && AIGroupState.RevealInstigatorUnitObjectID <= 0 )
		{
			History = `XCOMHISTORY;
			GroupLeaderUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.m_arrMembers[0].ObjectID,, HistoryIndex));

			if( GroupLeaderUnitState != none && GroupLeaderUnitState.GetTeam() != eTeam_Neutral )
			{
				CharacterTemplate = GroupLeaderUnitState.GetMyTemplate();

				if( `CHEATMGR == none || !`CHEATMGR.DisableFirstEncounterVO )
				{
					bPlayFirstSighting = false;

					if( GroupLeaderUnitState.IsAlive() )
					{
						XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
						bPlayFirstSighting = (XComHQ != None) && !XComHQ.HasSeenCharacterTemplate(CharacterTemplate) && !CharacterTemplate.bNeverShowFirstSighted;
					}

					// If this group has not scampered OR the character template hasn't been seen before, 
					if( !AIGroupState.bProcessedScamper || bPlayFirstSighting )
					{
						// first time sighting an enemy group, want to force a camera look at for this group
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("First Sighting Of Enemy Group [" $ AIGroupState.ObjectID $ "]");
						if( !CharacterTemplate.bNeverShowFirstSighted )
						{
							XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForFirstSightingOfEnemyGroup;
						}

						NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', AIGroupState.ObjectID));
						NewGroupState.MarkGroupSighted(ViewingUnitState, NewGameState);

						if( bPlayFirstSighting )
						{
							// Update the HQ state to record that we saw this enemy type
							XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.Class, XComHQ.ObjectID));
							XComHQ.AddSeenCharacterTemplate(CharacterTemplate);
						}

						NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);

						`TACTICALRULES.SubmitGameState(NewGameState);

						ViewingUnitState.DoAmbushTutorial();
					}
				}

				for( i = 0; i < CharacterTemplate.SightedEvents.Length; i++ )
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Sighted event");
					`XEVENTMGR.TriggerEvent(CharacterTemplate.SightedEvents[i], , , NewGameState);
					`TACTICALRULES.SubmitGameState(NewGameState);
				}
			}
		}
	}
}

function BuildVisualizationForFirstSightingOfEnemyGroup(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata ActionMetadata, EmptyMetadata;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, GroupLeaderUnitState, GroupUnitState;
	local X2Action_PlayEffect EffectAction;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_AIGroup AIGroupState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local X2Action_UpdateUI UpdateUIAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local bool bPlayedVO;
	local int Index;
	local X2Action_Delay DelayAction;
	local XComGameStateContext Context;
	local bool bFirstSightingOfUnitEver;
	local TTile TileLocation;
	local XComGameState_LadderProgress LadderData;

	Context = VisualizeGameState.GetContext();
	History = `XCOMHISTORY;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	bFirstSightingOfUnitEver = (XComHQ != None);

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_AIGroup', AIGroupState)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.SightedByUnitID));

		ActionMetadata = EmptyMetadata;

		ActionMetadata.StateObject_OldState = UnitState;
		ActionMetadata.StateObject_NewState = UnitState;

		if( !bFirstSightingOfUnitEver )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		}

		// always center the camera on the enemy group for a few seconds and clear the FOW
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		EffectAction.CenterCameraOnEffectDuration = bFirstSightingOfUnitEver ? 5.0 : 1.0;
		EffectAction.RevealFOWRadius = class'XComWorldData'.const.WORLD_StepSize * 5.0f;
		EffectAction.FOWViewerObjectID = AIGroupState.m_arrMembers[0].ObjectID; //Setting this to be a unit makes it possible for the FOW viewer to reveal units
		TileLocation = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.m_arrMembers[0].ObjectID)).TileLocation;
		EffectAction.EffectLocation = `XWORLD.GetPositionFromTileCoordinates(TileLocation); //Use the first unit in the group for the first sighted.
		EffectAction.bWaitForCameraArrival = true;
		EffectAction.bWaitForCameraCompletion = false;

		UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		UpdateUIAction.UpdateType = EUIUT_Pathing_Concealment;

		LadderData = XComGameState_LadderProgress( History.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress', true ) );

		// if there is an HQ in this game state, it means that this unit is being shown for the first time, so we need to perform that intro narrative
		GroupLeaderUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.m_arrMembers[0].ObjectID));
		if( XComHQ != None && GroupLeaderUnitState != None && GroupLeaderUnitState.IsAlive() )
		{
			// iterating through all SightedNarrativeMoments on the character template
			CharacterTemplate = GroupLeaderUnitState.GetMyTemplate();

			MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
			if( MissionState == none || !MissionState.GetMissionSource().bBlockFirstEncounterVO )
			{
				if (LadderData != none)
				{
					if (CharacterTemplate.SightedNarrativeMoments.Length > 1)
						EffectAction.NarrativeToPlay = CharacterTemplate.SightedNarrativeMoments[1];
				}
				else if (CharacterTemplate.SightedNarrativeMoments.Length > 0)
					EffectAction.NarrativeToPlay = CharacterTemplate.SightedNarrativeMoments[0];
			}
		}
		else if( !bPlayedVO && !bFirstSightingOfUnitEver && !GroupLeaderUnitState.GetMyTemplate().bIsTurret )
		{
			if( GroupLeaderUnitState.IsAdvent() )
			{
				bPlayedVO = true;
				if( UnitState.IsConcealed() )
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'EnemyPatrolSpotted', eColor_Good);
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'ADVENTsighting', eColor_Good);
				}
			}
			else
			{
				// Iterate through other units to see if there are advent units
				for( Index = 1; Index < AIGroupState.m_arrMembers.Length; Index++ )
				{
					GroupUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.m_arrMembers[Index].ObjectID));
					if( !bPlayedVO && GroupUnitState.IsAdvent() )
					{
						bPlayedVO = true;
						if( UnitState.IsConcealed() )
						{
							SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'EnemyPatrolSpotted', eColor_Good);
						}
						else
						{
							SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'ADVENTsighting', eColor_Good);
						}
						break;
					}
				}
			}
		}

		class'X2Action_BlockAbilityActivation'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

		// pause a few seconds
		ActionMetadata.StateObject_OldState = none;
		ActionMetadata.StateObject_NewState = none;
		ActionMetadata.VisualizeActor = none;

		// ignore when in challenge, ladder, etc. mode
		if (!class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode())
		{
			DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			DelayAction.Duration = bFirstSightingOfUnitEver ? 5.0 : 1.0;
		}
	}
}


DefaultProperties
{	
	m_iLayer=-1 // no layer by default
	m_iForceLevel=1
	m_iAlertLevel=1
}
