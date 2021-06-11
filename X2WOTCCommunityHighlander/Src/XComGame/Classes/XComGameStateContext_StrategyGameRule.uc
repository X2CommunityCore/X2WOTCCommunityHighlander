//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_StrategyGameRule.uc
//  AUTHOR:  Ryan McFall  --  11/21/2013
//  PURPOSE: Context for game rules such as the game starting, rules engine state changes
//           and replay support.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_StrategyGameRule extends XComGameStateContext 
	native(Core);

enum StrategyGameRuleStateChange
{
	eStrategyGameRule_StrategyGameStart,
	eStrategyGameRule_RulesEngineStateChange,   //Called when the strategy rules engine changes to a new phase. See X2StrategyGameRuleset and its states.
	eStrategyGameRule_ReplaySync,               //This informs the system sync all visualizers to an arbitrary state
};

var StrategyGameRuleStateChange GameRuleType;
var name RuleEngineNextState;           //The name of the new state that the rules engine is entering. Can be used for error checking or actually implementing GotoState
var string StrategyMapCommand;

//XComGameStateContext interface
//***************************************************
/// <summary>
/// Should return true if ContextBuildGameState can return a game state, false if not. Used internally and externally to determine whether a given context is
/// valid or not.
/// </summary>
function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

/// <summary>
/// Override in concrete classes to converts the InputContext into an XComGameState
/// </summary>
function XComGameState ContextBuildGameState()
{
	
}

/// <summary>
/// Convert the ResultContext and AssociatedState into a set of visualization tracks
/// </summary>
protected function ContextBuildVisualization()
{
	
}

/// <summary>
/// Override to return TRUE for the XComGameStateContext object to show that the associated state is a start state
/// </summary>
event bool IsStartState()
{
	return GameRuleType == eStrategyGameRule_StrategyGameStart;
}

native function bool NativeIsStartState();

/// <summary>
/// Returns a short description of this context object
/// </summary>
function string SummaryString()
{
	local string GameRuleString;

	GameRuleString = string(GameRuleType);
	if( RuleEngineNextState != '' )
	{
		GameRuleString = GameRuleString @ "(" @ RuleEngineNextState @ ")";
	}

	return GameRuleString;
}

/// <summary>
/// Returns a string representation of this object.
/// </summary>
function string ToString()
{
	return "";
}
//***************************************************

/// <summary>
/// Returns an XComGameState that is used to launch the X-Com 2 campaign.
/// </summary>
static function XComGameState CreateStrategyGameStart(
	optional XComGameState StartState, 
	optional bool bSetRandomSeed=true, 
	optional bool bTutorialEnabled=false, 
	optional bool bXPackNarrativeEnabled=false,
	optional bool bIntegratedDLCEnabled=true,
	optional int SelectedDifficulty=1, 
	optional float TacticalDifficulty = -1,
	optional float StrategyDifficulty = -1,
	optional float GameLength = -1,
	optional bool bSuppressFirstTimeVO=false,
	optional array<name> EnabledOptionalNarrativeDLC, 
	optional bool SendCampaignAnalytics=true, 
	optional bool IronManEnabled=false, 
	optional int UseTemplateGameArea=-1, 
	optional bool bSetupDLCContent=true,
	optional array<name> SecondWaveOptions)
{	
	local XComGameStateHistory History;
	local XComGameStateContext_StrategyGameRule StrategyStartContext;
	local Engine LocalGameEngine;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;
	local int Seed;
	local bool NewCampaign;

	NewCampaign = false;
	if( StartState == None )
	{
		History = `XCOMHISTORY;

		History.ResetHistory( ); // clear out anything else that may have been in the history (shell save, ladders, challenges, whatever)

		StrategyStartContext = XComGameStateContext_StrategyGameRule(class'XComGameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
		StrategyStartContext.GameRuleType = eStrategyGameRule_StrategyGameStart;
		StartState = History.CreateNewGameState(false, StrategyStartContext);
		History.AddGameStateToHistory(StartState);

		NewCampaign = true;
	}

	if (bSetRandomSeed)
	{
		LocalGameEngine = class'Engine'.static.GetEngine();
		Seed = LocalGameEngine.GetARandomSeed();
		LocalGameEngine.SetRandomSeeds(Seed);
	}

	// Start Issue #869
	//
	// Register campaign-start listeners after the start state has been created
	// but before any campaign initialization has occurred.
	class'X2EventListenerTemplateManager'.static.RegisterCampaignStartListeners();
	// End Issue #869

	//Create start time
	class'XComGameState_GameTime'.static.CreateGameStartTime(StartState);

	//Create campaign settings
	class'XComGameState_CampaignSettings'.static.CreateCampaignSettings(
		StartState, 
		bTutorialEnabled, 
		bXPackNarrativeEnabled,
		bIntegratedDLCEnabled,
		SelectedDifficulty, 
		TacticalDifficulty, 
		StrategyDifficulty, 
		GameLength, 
		bSuppressFirstTimeVO, 
		EnabledOptionalNarrativeDLC,
		SecondWaveOptions);

	//Create analytics object
	class'XComGameState_Analytics'.static.CreateAnalytics(StartState, SelectedDifficulty);

	//Create and add regions
	class'XComGameState_WorldRegion'.static.SetUpRegions(StartState);

	//Create and add continents
	class'XComGameState_Continent'.static.SetUpContinents(StartState);

	//Create and add region links
	class'XComGameState_RegionLink'.static.SetUpRegionLinks(StartState);

	//Create and add cities
	class'XComGameState_City'.static.SetUpCities(StartState);

	//Create and add Trading Posts (requires regions)
	class'XComGameState_TradingPost'.static.SetUpTradingPosts(StartState);

	// Create and add Black Market (requires regions)
	class'XComGameState_BlackMarket'.static.SetUpBlackMarket(StartState);

	// Create and add the Resource Cache (requires regions)
	class'XComGameState_ResourceCache'.static.SetUpResourceCache(StartState);

	// Create the POIs
	class'XComGameState_PointOfInterest'.static.SetUpPOIs(StartState, UseTemplateGameArea);
	
	//Create XCom Techs
	class'XComGameState_Tech'.static.SetUpTechs(StartState);

	// Create Strategy Cards
	class'XComGameState_StrategyCard'.static.SetUpStrategyCards(StartState);

	//Create Resistance HQ
	class'XComGameState_HeadquartersResistance'.static.SetUpHeadquarters(StartState, bTutorialEnabled);

	//Create Alien HQ (Alien Facilities)
	class'XComGameState_HeadquartersAlien'.static.SetUpHeadquarters(StartState);

	//Create X-Com HQ (Rooms, Facilities, Initial Staff)
	class'XComGameState_HeadquartersXCom'.static.SetUpHeadquarters(StartState, bTutorialEnabled, bXPackNarrativeEnabled);

	// Create Dark Events
	class'XComGameState_DarkEvent'.static.SetUpDarkEvents(StartState);

	// Create Mission Calendar
	class'XComGameState_MissionCalendar'.static.SetupCalendar(StartState);

	// Create Narrative Manager
	class'XComGameState_NarrativeManager'.static.SetUpNarrativeManager(StartState);

	// Create Objectives
	class'XComGameState_Objective'.static.SetUpObjectives(StartState);

	// Finish initializing Havens
	class'XComGameState_Haven'.static.SetUpHavens(StartState);

	// Create Bastions
	//class'XComGameState_Bastion'.static.SetUpBastions(StartState);

	if (NewCampaign && SendCampaignAnalytics)
	{
		class'AnalyticsManager'.static.SendGameStartTelemetry( History, IronManEnabled );
	}

	if( bSetupDLCContent )
	{
		// Let the DLC / Mods hook the creation of a new campaign
		EventManager = `ONLINEEVENTMGR;
		DLCInfos = EventManager.GetDLCInfos(false);
		for(i = 0; i < DLCInfos.Length; ++i)
		{
			DLCInfos[i].InstallNewCampaign(StartState);
		}
	}

	// Start Issue #971
	//
	// Clear out the campaign start listeners to ensure they don't hang around
	// for longer than they're needed.
	class'X2EventListenerTemplateManager'.static.UnRegisterAllListeners();
	// End Issue #971

	return StartState;
}

/// <summary>
/// Used to create a strategy game start state from a tactical battle
/// </summary>
static function XComGameState CreateStrategyGameStartFromTactical()
{	
	local XComGameStateHistory History;
	local XComGameState StartState;
	local XComGameStateContext_StrategyGameRule StrategyStartContext;
	local XComGameState PriorStrategyState;
	local int PreStartStateIndex;	
	local int BackpackIndex;
	local XComGameState_BaseObject StateObject;
	local array<XComGameState_Item> BackpackItems;
	local XComGameState_Item ItemState;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_ObjectivesList ObjectivesList;
	local XComGameState_WorldNarrativeTracker NarrativeTracker;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	//Build a game state that contains the full state of every object that existed in the strategy
	//game session prior to the current tactical match
	PreStartStateIndex = History.FindStartStateIndex() - 1;
	PriorStrategyState = History.GetGameStateFromHistory(PreStartStateIndex, eReturnType_Copy, false);

	//Now create the strategy start state and add it to the history
	StrategyStartContext = XComGameStateContext_StrategyGameRule(class'XComGameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
	StrategyStartContext.GameRuleType = eStrategyGameRule_StrategyGameStart;
	StartState = History.CreateNewGameState(false, StrategyStartContext);
	
			
	//Iterate all the game states in the strategy game state built above and create a new entry in the 
	//start state we are building for each one. If any of the state objects were changed / updated in the
	//tactical battle, their changes are automatically picked up by this process.
	//
	//Caveat: Currently this assumes that the only objects that can return from tactical to strategy are those 
	//which were created in the strategy game. Additional logic will be necessary to transfer NEW objects 
	//created within tactical.
	foreach PriorStrategyState.IterateByClassType( class'XComGameState_BaseObject', StateObject )
	{
		StartState.ModifyStateObject(StateObject.Class, StateObject.ObjectID);

		//  Check units for items in the backpack and move them over as they were created in tactical
		if (StateObject.IsA('XComGameState_Unit'))
		{
			BackpackItems = XComGameState_Unit(StateObject).GetAllItemsInSlot(eInvSlot_Backpack);
			for (BackpackIndex = 0; BackpackIndex < BackpackItems.Length; ++BackpackIndex)
			{
				ItemState = XComGameState_Item(StartState.GetGameStateForObjectID(BackpackItems[BackpackIndex].ObjectID));

				if(ItemState == none)
				{
					StartState.ModifyStateObject(BackpackItems[BackpackIndex].Class, BackpackItems[BackpackIndex].ObjectID);
				}				
			}
		}
	}

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	`assert(BattleData.m_iMissionID == XComHQ.MissionRef.ObjectID);
	BattleData = XComGameState_BattleData(StartState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));

	ObjectivesList = XComGameState_ObjectivesList(History.GetSingleGameStateObjectForClass(class'XComGameState_ObjectivesList'));
	ObjectivesList = XComGameState_ObjectivesList(StartState.ModifyStateObject(class'XComGameState_ObjectivesList', ObjectivesList.ObjectID));

	// clear completed & failed objectives on transition back to strategy
	ObjectivesList.ClearTacticalObjectives();

	// if we have a narrative tracker, pass it along
	NarrativeTracker = XComGameState_WorldNarrativeTracker(History.GetSingleGameStateObjectForClass(class'XComGameState_WorldNarrativeTracker', true));
	if(NarrativeTracker != none)
	{
		StartState.ModifyStateObject(class'XComGameState_WorldNarrativeTracker', NarrativeTracker.ObjectID);
	}

	History.AddGameStateToHistory(StartState);

	return StartState;
}

/// <summary>
/// Modify any objects as they come into strategy from tactical
/// e.g. Move backpack items into storage, place injured soldiers in the infirmary, move dead soldiers to the morgue, etc.
/// </summary>
static function CompleteStrategyFromTacticalTransfer()
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;
	
	// Start issue #785
	/// HL-Docs: feature:PreCompleteStrategyFromTacticalTransfer; issue:785; tags:strategy
	/// There are no events that trigger before the mission rewards and several
	/// other critical functions are processed. This event gives a way for mods
	/// to change several aspects in the transition from tactical to strategy.
	///
	/// ```event
	/// EventID: PreCompleteStrategyFromTacticalTransfer,
	/// EventData: None,
	/// EventSource: None,
	/// NewGameState: none,
	/// ```
	`XEVENTMGR.TriggerEvent('PreCompleteStrategyFromTacticalTransfer');

	UpdateSkyranger();
	CleanupProxyVips();
	ProcessMissionResults();
	UpdateChosen();
	SquadTacticalToStrategyTransfer();
	
	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPostMission();
	}
}

/// <summary>
/// Return skyranger to the Avenger
/// </summary>
static function UpdateSkyranger()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Skyranger SkyrangerState;

	// Dock Skyranger at HQ
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Dock Skyranger");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SkyrangerState = XComGameState_Skyranger(NewGameState.ModifyStateObject(class'XComGameState_Skyranger', XComHQ.SkyrangerRef.ObjectID));
	SkyrangerState.Location = XComHQ.Location;
	SkyrangerState.SourceLocation.X = SkyrangerState.Location.X;
	SkyrangerState.SourceLocation.Y = SkyrangerState.Location.Y;
	SkyrangerState.TargetEntity = XComHQ.GetReference();
	SkyrangerState.SquadOnBoard = false;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/// <summary>
/// Removes mission and handles rewards
/// </summary>
static function ProcessMissionResults()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionSite MissionState, FortressMission;
	local X2MissionSourceTemplate MissionSource;
	local bool bMissionSuccess;
	local int idx;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cleanup Mission");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.bReturningFromMission = true;
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', XComHQ.MissionRef.ObjectID));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	FortressMission = AlienHQ.GetFortressMission();

	// Remove Mission Tags from the general tags list
	XComHQ.RemoveMissionTacticalTags(MissionState);

	// Handle tactical objective complete doom removal (should not be any other pending doom at this point)
	for(idx = 0; idx < AlienHQ.PendingDoomData.Length; idx++)
	{
		if(AlienHQ.PendingDoomData[idx].Doom > 0)
		{
			AlienHQ.PendingDoomData[idx].Doom = Clamp(AlienHQ.PendingDoomData[idx].Doom, 0, AlienHQ.GetCurrentDoom(true));
			AlienHQ.AddDoomToFortress(NewGameState, AlienHQ.PendingDoomData[idx].Doom, , false);
			AlienHQ.PendingDoomEntity = FortressMission.GetReference();

			if(AlienHQ.PendingDoomData[idx].DoomMessage != "" && FortressMission.ShouldBeVisible())
			{
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, AlienHQ.PendingDoomData[idx].DoomMessage, true);
			}
			
		}
		else if(AlienHQ.PendingDoomData[idx].Doom < 0)
		{
			AlienHQ.PendingDoomData[idx].Doom = Clamp(AlienHQ.PendingDoomData[idx].Doom, -AlienHQ.GetCurrentDoom(true), 0);
			AlienHQ.RemoveDoomFromFortress(NewGameState, -AlienHQ.PendingDoomData[idx].Doom, , false);
			AlienHQ.PendingDoomEntity = FortressMission.GetReference();

			if(AlienHQ.PendingDoomData[idx].DoomMessage != "" && FortressMission.ShouldBeVisible())
			{
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, AlienHQ.PendingDoomData[idx].DoomMessage, false);
				class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgressReduced', -AlienHQ.PendingDoomData[idx].Doom);
			}
		}
		else
		{
			AlienHQ.PendingDoomData.Remove(idx, 1);
			AlienHQ.PendingDoomEvent = '';
			idx--;
		}
		
	}

	// If accelerating doom, stop
	if(AlienHQ.bAcceleratingDoom)
	{
		AlienHQ.StopAcceleratingDoom();
	}

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleData.m_iMissionID == MissionState.ObjectID);

	MissionSource = MissionState.GetMissionSource();

	// Main objective success/failure hooks
	bMissionSuccess = BattleData.bLocalPlayerWon;

	class'X2StrategyElement_DefaultMissionSources'.static.IncreaseForceLevel(NewGameState, MissionState);

	if( bMissionSuccess )
	{
		if( MissionSource.OnSuccessFn != none )
		{
			MissionSource.OnSuccessFn(NewGameState, MissionState);
		}
	}
	else
	{
		if( MissionSource.OnFailureFn != none )
		{
			MissionSource.OnFailureFn(NewGameState, MissionState);
		}
	}

	// Triad objective success/failure hooks
	if( BattleData.AllTriadObjectivesCompleted() )
	{
		if( MissionSource.OnTriadSuccessFn != none )
		{
			MissionSource.OnTriadSuccessFn(NewGameState, MissionState);
		}
	}
	else
	{
		if( MissionSource.OnTriadFailureFn != none )
		{
			MissionSource.OnTriadFailureFn(NewGameState, MissionState);
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/// <summary>
/// Modify the squad and related items as they come into strategy from tactical
/// e.g. Move backpack items into storage, place injured soldiers in the infirmary, move dead soldiers to the morgue, etc.
/// </summary>
static function SquadTacticalToStrategyTransfer()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local StateObjectReference DeadUnitRef;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local XComGameState_HeadquartersAlien AlienHeadquarters;
	local XComGameState_MissionSite MissionState;
	local array<StateObjectReference> SoldiersToTransfer;
	local int idx, idx2, NumDeadOrCaptured;
	local XComGameStateHistory History;
	local X2EventManager EventManager;
	local XComGameState_BattleData BattleData;
	local array<XComGameState_Unit> ReturningSoldiers;
	local bool bBondAvailable, bLevelUpBondAvailable;
	local LastMissionData MissionData;

	EventManager = `XEVENTMGR;
	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission Squad Cleanup");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID)); 
	MissionData.MissionSource = MissionState.GetMissionSource().DataName;
	MissionData.bXComWon = BattleData.bLocalPlayerWon;
	MissionData.MissionFamily = MissionState.GeneratedMission.Mission.MissionFamily;
	MissionData.bChosenEncountered = (BattleData.ChosenRef.ObjectID != 0);
	
	// If the unit is in the squad or was spawned from the avenger on the mission, add them to the SoldiersToTransfer array
	SoldiersToTransfer = XComHQ.Squad;
	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		if (XComHQ.Crew[idx].ObjectID != 0)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));
			if (UnitState.bSpawnedFromAvenger)
			{
				SoldiersToTransfer.AddItem(XComHQ.Crew[idx]);
			}
		}
	}

	NumDeadOrCaptured = 0;

	for( idx = 0; idx < SoldiersToTransfer.Length; idx++ )
	{
		if(SoldiersToTransfer[idx].ObjectID != 0)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', SoldiersToTransfer[idx].ObjectID));
			UnitState.iNumMissions++;

			UnitState.ClearRemovedFromPlayFlag();

			// Issue #44 Start
			// Clear the UnitValue that records start-of-mission will. Would get overwritten next Mission,
			// but clearing it because it makes sense
			UnitState.ClearUnitValue('CH_StartMissionWill');
			// Issue #44 End
      
			// Bleeding out soldiers die if not rescued, some characters die when captured
			if (UnitState.bBleedingOut || (UnitState.bCaptured && UnitState.GetMyTemplate().bDiesWhenCaptured))
			{
				UnitState.SetCurrentStat(eStat_HP, 0);
			}

			// First remove any units provided by the mission
			if (UnitState.bMissionProvided)
			{
				idx2 = XComHQ.Squad.Find('ObjectID', UnitState.ObjectID);
				if (idx2 != INDEX_NONE)
					XComHQ.Squad.Remove(idx2, 1);

				continue; // Skip the rest of the transfer processing for the mission provided unit, since they shouldn't return to strategy
			}
			//  Dead soldiers get moved to the DeadCrew list
			else if (UnitState.IsDead())
			{
				DeadUnitRef = UnitState.GetReference();
				XComHQ.RemoveFromCrew(DeadUnitRef);
				XComHQ.DeadCrew.AddItem(DeadUnitRef);
				// Removed from squad in UIAfterAction

				if (UnitState.GetRank() >= 5)
				{
					MissionData.bLostVeteran = true; // Flag for ambient VO triggers in strategy
				}
			}
			else if (UnitState.bCaptured)
			{
				//  Captured soldiers get moved to the AI HQ capture list
				if (AlienHeadquarters == none)
				{
					AlienHeadquarters = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
					AlienHeadquarters = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHeadquarters.ObjectID));
				}

				XComHQ.RemoveFromCrew(UnitState.GetReference());

				if(UnitState.ChosenCaptorRef.ObjectID == 0)
				{
					class'X2StrategyGameRulesetDataStructures'.static.ResetAllBonds(NewGameState, UnitState);
					AlienHeadquarters.CapturedSoldiers.AddItem(UnitState.GetReference());
				}
			}
			else
			{
				ReturningSoldiers.AddItem(UnitState);
			}

			// If dead or captured remove relevant projects
			if (UnitState.IsDead() || UnitState.bCaptured)
			{
				foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', ProjectState)
				{
					if (ProjectState.ProjectFocus == UnitState.GetReference())
					{
						XComHQ.Projects.RemoveItem(ProjectState.GetReference());
						NewGameState.RemoveStateObject(ProjectState.ObjectID);
					}
				}

				NumDeadOrCaptured++;
			}

			// Handle any additional unit transfers events (e.g. Analytics)
			EventManager.TriggerEvent('SoldierTacticalToStrategy', UnitState, UnitState, NewGameState);

			//  Unload backpack (loot) items from any live or recovered soldiers, and retrieve inventory for dead soldiers
			PostMissionUpdateSoldierItems(NewGameState, BattleData, UnitState);
			
			// Tactical to Strategy transfer code which may be unique on a per-class basis
			if (!UnitState.GetSoldierClassTemplate().bUniqueTacticalToStrategyTransfer)
			{
				// Update soldier's mental state based on will and start will recovery
				//PostMissionUpdateSoldierWill(NewGameState, UnitState);

				// Start healing injured soldiers
				PostMissionUpdateSoldierHealing(NewGameState, UnitState);
				
				// If the soldier is shaken, check to see if the status is removed
				//PostMissionUpdateSoldierShakenStatus(NewGameState, UnitState);

				// Update the soldier's mental state now that healing has begun
				//PostMissionUpdateSoldierMentalState(UnitState);

				// If the Psi Operative was training an ability before the mission continue the training automatically, or delete the project if they died
				PostMissionUpdatePsiOperativeTraining(NewGameState, UnitState);

				// If the mission was a success and the unit is a resistance soldier, grant influence with their faction
				//if (bMissionSuccess)
				//{
				//	PostMissionUpdateSoldierFactionInfluence(NewGameState, UnitState);
				//}
			}
		}
	}

	XComHQ.UpdateAverageFame(NewGameState);
	UpdateSoldierWill(NewGameState, MissionState, ReturningSoldiers, NumDeadOrCaptured);
	AdjustSoldierBonds(ReturningSoldiers);
	
	XComHQ.LastMission = MissionData; // Save the info about this mission
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	// Adjust narrative flags for soldier bonds so battle data knows to trigger the appropriate events
	if (IsBondAvailable(ReturningSoldiers))
	{
		bBondAvailable = true;
	}
	if (IsBondAvailable(ReturningSoldiers, true))
	{
		bLevelUpBondAvailable = true;
	}

	QueuePostMissionPopups(ReturningSoldiers, bBondAvailable);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission Set Grade");
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	BattleData.SetPostMissionGrade();
	BattleData.bBondAvailable = bBondAvailable;
	BattleData.bBondLevelUpAvailable = bLevelUpBondAvailable;

	// Now that the mission grade has been calculated, update the AlienHQ if XCOM suffered heavy losses
	if (BattleData.bToughMission && MissionData.bChosenEncountered)
	{
		AlienHeadquarters = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHeadquarters = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHeadquarters.ObjectID));
		AlienHeadquarters.LastChosenEncounter.bHeavyLosses = true;
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

public static function UpdateSoldierWill(XComGameState NewGameState, XComGameState_MissionSite MissionState, array<XComGameState_Unit> ReturningSoldiers, int NumDeadOrCaptured)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> ValidSoldiers, GuaranteedSoldiers, ReadyCriticalSoldiers, ReadySoldiers;
	local bool bBlockTraits, bLimitIncap;
	local int ReadyTraitCount, MaxNewTiredSoldiers, idx;
	local array<int> ForceReadySoldierIDs;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.MissionsSinceTraitGained++;
	ValidSoldiers.Length = 0;
	GuaranteedSoldiers.Length = 0;
	ReadyCriticalSoldiers.Length = 0;
	ReadySoldiers.Length = 0;
	ForceReadySoldierIDs.Length = 0;

	// Some missions don't allow negative traits
	bBlockTraits = (MissionState.GetMissionSource().bBlocksNegativeTraits);

	// Some missions limit the amount of incap soldiers
	bLimitIncap = (class'X2StrategyGameRulesetDataStructures'.default.NoLimitIncapSoldiersMissions.Find(MissionState.Source) == INDEX_NONE);
	MaxNewTiredSoldiers = `ScaleStrategyArrayInt(class'X2StrategyGameRulesetDataStructures'.default.MaxIncapSoldiersPerMission) - NumDeadOrCaptured;

	// Grab all soldiers that use the will system
	foreach ReturningSoldiers(UnitState)
	{
		if(UnitState.UsesWillSystem())
		{
			ValidSoldiers.AddItem(UnitState);

			if(UnitState.GetMentalState() == eMentalState_Ready && !UnitState.IsInjured())
			{
				ReadySoldiers.AddItem(UnitState);
			}

			if(UnitState.IsInjured())
			{
				MaxNewTiredSoldiers--;
			}

			if(!bBlockTraits)
			{
				if(UnitState.GetMentalState() == eMentalState_Tired || UnitState.GetMentalState() == eMentalState_Shaken)
				{
					// Guaranteed roll for negative trait
					GuaranteedSoldiers.AddItem(UnitState);
				}
				else if(UnitState.IsGravelyInjured() && UnitState.GetNumTraits() == 0)
				{
					// Roll for negative trait if allowed
					ReadyCriticalSoldiers.AddItem(UnitState);
				}
			}
		}
	}

	// Do all guaranteed rolls
	foreach GuaranteedSoldiers(UnitState)
	{
		if(UnitState.RollForNegativeTrait(NewGameState))
		{
			XComHQ.bSoldierEverGainedNegativeTrait = true;
			XComHQ.MissionsSinceTraitGained = 0;
		}
	}

	// Sort soldiers from low to high will (roll for negative traits first)
	ReadyCriticalSoldiers.Sort(SortSoldiersByWill);
	ReadyTraitCount = 0;

	// Do extra rolls on critically injured soldiers if allowed
	foreach ReadyCriticalSoldiers(UnitState)
	{
		if(ReadyTraitCount >= class'X2StrategyGameRulesetDataStructures'.default.MaxTraitsPerMissionForReadySoldiers || 
			(XComHQ.bSoldierEverGainedNegativeTrait && XComHQ.MissionsSinceTraitGained < XComHQ.MinMissionsBetweenTraits))
		{
			break;
		}

		if(UnitState.RollForNegativeTrait(NewGameState))
		{
			XComHQ.bSoldierEverGainedNegativeTrait = true;
			XComHQ.MissionsSinceTraitGained = 0;
			ReadyTraitCount++;
		}
	}

	if(bLimitIncap)
	{
		ReadySoldiers.Sort(SortSoldiersByWill);

		for(idx = 0; idx < ReadySoldiers.Length; idx++)
		{
			if(idx >= MaxNewTiredSoldiers)
			{
				ForceReadySoldierIDs.AddItem(ReadySoldiers[idx].ObjectID);
			}
		}
	}

	// Update Will for all valid soldiers
	foreach ValidSoldiers(UnitState)
	{
		//  Update Mental State
		PostMissionUpdateSoldierMentalState(UnitState);

		// Start Will recovery
		PostMissionUpdateSoldierWill(NewGameState, UnitState, ForceReadySoldierIDs, MissionState.GetMissionSource().bBlockShaken);
	}
}

private static function int SortSoldiersByWill(XComGameState_Unit UnitStateA, XComGameState_Unit UnitStateB)
{
	if(UnitStateA.GetCurrentStat(eStat_Will) < UnitStateB.GetCurrentStat(eStat_Will))
	{
		return 1;
	}
	else if(UnitStateB.GetCurrentStat(eStat_Will) < UnitStateA.GetCurrentStat(eStat_Will))
	{
		return -1;
	}

	return 0;
}

public static function AdjustSoldierBonds(array<XComGameState_Unit> BondedSoldiers)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_Unit BondmateA, BondmateB;
	local StateObjectReference BondmateRef;
	local int MissionCohesion, i, j;

	// Calculate Mission Cohesion
	MissionCohesion = class'X2StrategyGameRulesetDataStructures'.default.MinMissionCohesion + 
		`SYNC_RAND_STATIC(class'X2StrategyGameRulesetDataStructures'.default.MaxMissionCohesion - class'X2StrategyGameRulesetDataStructures'.default.MinMissionCohesion + 1);

	// Mission Cohesion may be scaled by Resistance Orders
	History = `XCOMHISTORY;
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	if(ResHQ.CohesionScalar > 0)
	{
		MissionCohesion = Round(float(MissionCohesion) * ResHQ.CohesionScalar);
	}

	// Modify cohesion between all pairs of bonded soldiers
	for(i = 0; i < (BondedSoldiers.Length - 1); i++)
	{
		BondmateA = BondedSoldiers[i];

		// If a soldier already has a bond, only increase cohesion with their bondmate if they were also on the mission
		if (BondmateA.HasSoldierBond(BondmateRef))
		{
			for (j = (i + 1); j < BondedSoldiers.Length; j++)
			{
				BondmateB = BondedSoldiers[j];
				if (BondmateB.ObjectID == BondmateRef.ObjectID)
				{
					class'X2StrategyGameRulesetDataStructures'.static.ModifySoldierCohesion(BondmateA, BondmateB, MissionCohesion);
					break;
				}
			}
		}
		else // Otherwise increase their cohesion with each soldier in the mission squad
		{
			for (j = (i + 1); j < BondedSoldiers.Length; j++)
			{
				BondmateB = BondedSoldiers[j];

				// If the second soldier has a bond, don't modify cohesion, since they only gain cohesion with their bondmate if the bondmate is also on the mission
				// One of the two bondmates will always be earlier in the squad lineup and trigger their gain cohesion in the code block above
				if (!BondmateB.HasSoldierBond(BondmateRef)) 
				{
					class'X2StrategyGameRulesetDataStructures'.static.ModifySoldierCohesion(BondmateA, BondmateB, MissionCohesion);
				}
			}
		}
	}
}

private static function bool IsBondAvailable(array<XComGameState_Unit> BondedSoldiers, optional bool bLevelUp)
{
	local array<XComGameState_Unit> ValidBonds;
	local int i;

	for (i = 0; i < BondedSoldiers.Length; i++)
	{
		if (!bLevelUp)
		{
			ValidBonds = class'X2StrategyGameRulesetDataStructures'.static.GetAllValidSoldierBondsAtLevel(BondedSoldiers[i], 1);
			if (ValidBonds.Length > 0)
			{
				return true;
			}
		}
		else
		{
			ValidBonds = class'X2StrategyGameRulesetDataStructures'.static.GetAllValidSoldierBondsAtLevel(BondedSoldiers[i], 2);
			if (ValidBonds.Length > 0)
			{
				return true;
			}
		}
	}

	return false;
}

private static function XComGameState_HeadquartersXCom GetAndAddXComHQ(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	return XComHQ;
}

private static function PostMissionUpdateSoldierItems(XComGameState NewGameState, XComGameState_BattleData BattleData, XComGameState_Unit UnitState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Item> Items;
	local XComGameState_Item ItemState;
	local bool bRemoveItemStatus;
	local X2WeaponTemplate WeaponTemplate;

	XComHQ = GetAndAddXComHQ(NewGameState);
	
	//  Unload backpack (loot) items from any live or recovered soldiers
	if (!UnitState.IsDead() || UnitState.bBodyRecovered)
	{
		Items = UnitState.GetAllItemsInSlot(eInvSlot_Backpack, NewGameState);
		foreach Items(ItemState)
		{
			ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));

			bRemoveItemStatus = UnitState.RemoveItemFromInventory(ItemState, NewGameState);
			`assert(bRemoveItemStatus);

			ItemState.OwnerStateObject = XComHQ.GetReference();
			XComHQ.PutItemInInventory(NewGameState, ItemState, true);

			BattleData.CarriedOutLootBucket.AddItem(ItemState.GetMyTemplateName());
		}
	}

	//  Recover regular inventory from dead but recovered units.
	if (UnitState.IsDead() && UnitState.bBodyRecovered)
	{
		Items = UnitState.GetAllInventoryItems(NewGameState, true);
		foreach Items(ItemState)
		{
			ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));

			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
			{
				continue;
			}

			if (UnitState.RemoveItemFromInventory(ItemState, NewGameState)) //  possible we'll have some items that cannot be removed, so don't recover them
			{
				ItemState.OwnerStateObject = XComHQ.GetReference();
				XComHQ.PutItemInInventory(NewGameState, ItemState, false); // Recovered items from recovered units goes directly into inventory, doesn't show on loot screen

				//BattleData.CarriedOutLootBucket.AddItem(ItemState.GetMyTemplateName());
			}
		}
	}
}

private static function PostMissionUpdateSoldierWill(XComGameState NewGameState, XComGameState_Unit UnitState, array<int> ForceReadySoldierIDs, bool bBlockShaken)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectRecoverWill WillProject;
	local XComGameState_HeadquartersXCom XComHQ;
	local int MinReadyWill, MinTiredWill;

	History = `XCOMHISTORY;

	if(!UnitState.IsDead() && !UnitState.bCaptured)
	{
		if(UnitState.NeedsWillRecovery())
		{
			if(ForceReadySoldierIDs.Find(UnitState.ObjectID) != INDEX_NONE)
			{
				MinReadyWill = UnitState.GetMinWillForMentalState(eMentalState_Ready);

				if(UnitState.GetCurrentStat(eStat_Will) < MinReadyWill)
				{
					UnitState.SetCurrentStat(eStat_Will, MinReadyWill);
					UnitState.UpdateMentalState();
				}
			}

			if(bBlockShaken)
			{
				MinTiredWill = UnitState.GetMinWillForMentalState(eMentalState_Tired);

				if(UnitState.GetCurrentStat(eStat_Will) < MinTiredWill)
				{
					UnitState.SetCurrentStat(eStat_Will, MinTiredWill);
					UnitState.UpdateMentalState();
				}
			}

			// First remove existing recover will project if there is one.
			XComHQ = GetAndAddXComHQ(NewGameState);
			foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectRecoverWill', WillProject)
			{
				if(WillProject.ProjectFocus == UnitState.GetReference())
				{
					XComHQ.Projects.RemoveItem(WillProject.GetReference());
					NewGameState.RemoveStateObject(WillProject.ObjectID);
					break;
				}
			}

			// Add new will recover project
			WillProject = XComGameState_HeadquartersProjectRecoverWill(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectRecoverWill'));
			WillProject.SetProjectFocus(UnitState.GetReference(), NewGameState);
			XComHQ.Projects.AddItem(WillProject.GetReference());
		}
	}
}

private static function bool PostMissionUpdateSoldierMentalState(XComGameState_Unit UnitState)
{
	if (!UnitState.IsDead())
	{
		UnitState.UpdateMentalState();
		if (UnitState.GetMentalState() < eMentalState_Ready)
		{
			return true;
		}
	}

	return false;
}

private static function PostMissionUpdateSoldierHealing(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local int NewBlocksRemaining, NewProjectPointsRemaining;
	// variables for issue #140
	local XComLWTuple Tuple;

	// Start issue #140
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'PostMissionUpdateSoldierHealing';
	Tuple.Data.Add(1);

	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = true;

	`XEVENTMGR.TriggerEvent('PostMissionUpdateSoldierHealing', Tuple, UnitState, NewGameState);

	if (!UnitState.IsDead() && !UnitState.bCaptured && UnitState.IsSoldier() && UnitState.IsInjured() && UnitState.GetStatus() != eStatus_Healing && Tuple.Data[0].b)
	// End issue #140
	{
		History = `XCOMHISTORY;
		XComHQ = GetAndAddXComHQ(NewGameState);
		
		UnitState.SetStatus(eStatus_Healing);

		if (!UnitState.HasHealingProject())
		{
			ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
			ProjectState.SetProjectFocus(UnitState.GetReference(), NewGameState);
			XComHQ.Projects.AddItem(ProjectState.GetReference());
		}
		else
		{
			foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', ProjectState)
			{
				if (ProjectState.ProjectFocus == UnitState.GetReference())
				{
					NewBlocksRemaining = UnitState.GetBaseStat(eStat_HP) - UnitState.GetCurrentStat(eStat_HP);
					if (NewBlocksRemaining > ProjectState.BlocksRemaining) // The unit was injured again, so update the time to heal
					{
						ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectHealSoldier', ProjectState.ObjectID));

						// Calculate new wound length again, but ensure it is greater than the previous time, since the unit is more injured
						//ProjectState.SetExtraWoundPointsFromMentalState(NewGameState, UnitState);
						NewProjectPointsRemaining = ProjectState.GetWoundPoints(UnitState, ProjectState.ProjectPointsRemaining);

						ProjectState.ProjectPointsRemaining = NewProjectPointsRemaining;
						ProjectState.BlocksRemaining = NewBlocksRemaining;
						ProjectState.PointsPerBlock = Round(float(NewProjectPointsRemaining) / float(NewBlocksRemaining));
						ProjectState.BlockPointsRemaining = ProjectState.PointsPerBlock;
						ProjectState.UpdateWorkPerHour();
						ProjectState.StartDateTime = `STRATEGYRULES.GameTime;
						ProjectState.SetProjectedCompletionDateTime(ProjectState.StartDateTime);
					}

					break;
				}
			}
		}

		// If a soldier is gravely wounded, roll to see if they are shaken
		if (UnitState.IsGravelyInjured() && !UnitState.bIsShaken && !UnitState.bIsShakenRecovered)
		{
			if (class'X2StrategyGameRulesetDataStructures'.static.Roll(XComHQ.GetShakenChance()))
			{
				// @mnauta - leaving in chance to get random scar, but removing shaken gameplay (for new will system)
				//UnitState.bIsShaken = true;
				//UnitState.bSeenShakenPopup = false;

				//Give this unit a random scar if they don't have one already
				if (UnitState.kAppearance.nmScars == '')
				{
					UnitState.GainRandomScar();
					UnitState.bIsShakenRecovered = true;
				}

				//UnitState.SavedWillValue = UnitState.GetBaseStat(eStat_Will);
				//UnitState.SetBaseMaxStat(eStat_Will, 0);
			}
		}
	}
}

private static function PostMissionUpdateSoldierShakenStatus(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	if (!UnitState.IsDead() && !UnitState.bCaptured && UnitState.bIsShaken)
	{
		if (!UnitState.IsInjured()) // This unit was shaken but survived the mission unscathed. Check to see if they have recovered.
		{
			XComHQ = GetAndAddXComHQ(NewGameState);
			
			UnitState.MissionsCompletedWhileShaken++;
			if ((UnitState.UnitsKilledWhileShaken > 0) || (UnitState.MissionsCompletedWhileShaken >= XComHQ.GetShakenRecoveryMissions()))
			{
				//This unit has stayed healthy and killed some bad dudes, or stayed healthy for multiple missions in a row --> no longer shaken
				UnitState.bIsShaken = false;
				UnitState.bIsShakenRecovered = true;
				UnitState.bNeedsShakenRecoveredPopup = true;

				// Give a bonus to will (free stat progression roll) for recovering
				UnitState.SetBaseMaxStat(eStat_Will, UnitState.SavedWillValue + XComHQ.XComHeadquarters_ShakenRecoverWillBonus + `SYNC_RAND_STATIC(XComHQ.XComHeadquarters_ShakenRecoverWillRandBonus));
			}
		}
		else // The unit was injured on a mission while they were shaken. Reset counters. (This will also be called to init the values after shaken is set)
		{
			UnitState.MissionsCompletedWhileShaken = 0;
			UnitState.UnitsKilledWhileShaken = 0;
		}
	}
}

public static function PostMissionUpdatePsiOperativeTraining(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	local XComGameState_HeadquartersProjectPsiTraining PsiProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot SlotState;
	local StaffUnitInfo UnitInfo;
	local int SlotIndex;
	
	if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
	{
		XComHQ = GetAndAddXComHQ(NewGameState);
		PsiProjectState = XComHQ.GetPsiTrainingProject(UnitState.GetReference());
		if (PsiProjectState != none) // A paused Psi Training project was found for the unit
		{
			if (UnitState.IsDead() || UnitState.bCaptured) // The unit died or was captured, so remove the project
			{
				XComHQ.Projects.RemoveItem(PsiProjectState.GetReference());
				NewGameState.RemoveStateObject(PsiProjectState.ObjectID);
			}
			else if (!UnitState.IsInjured()) // If the unit is uninjured, restart the training project automatically
			{
				// Get the Psi Chamber facility and staff the unit in it if there is an open slot
				FacilityState = XComHQ.GetFacilityByName('PsiChamber'); // Only one Psi Chamber allowed, so safe to do this

				for (SlotIndex = 0; SlotIndex < FacilityState.StaffSlots.Length; ++SlotIndex)
				{
					//If this slot has not already been modified (filled) in this tactical transfer, check to see if it's valid
					SlotState = XComGameState_StaffSlot(NewGameState.GetGameStateForObjectID(FacilityState.StaffSlots[SlotIndex].ObjectID));
					if (SlotState == None)
					{
						SlotState = FacilityState.GetStaffSlot(SlotIndex);

						// If this is a valid soldier slot in the Psi Lab, restaff the soldier and restart their training project
						if (!SlotState.IsLocked() && SlotState.IsSlotEmpty() && SlotState.IsSoldierSlot())
						{
							// Restart the paused training project
							PsiProjectState = XComGameState_HeadquartersProjectPsiTraining(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectPsiTraining', PsiProjectState.ObjectID));
							PsiProjectState.bForcePaused = false;

							UnitInfo.UnitRef = UnitState.GetReference();
							SlotState.FillSlot(UnitInfo, NewGameState);

							break;
						}
					}
				}
			}
		}
	}
}

//private static function PostMissionUpdateSoldierFactionInfluence(XComGameState NewGameState, XComGameState_Unit UnitState)
//{
//	local XComGameState_ResistanceFaction FactionState;
//
//	if (UnitState.IsAlive() && UnitState.IsResistanceHero())
//	{
//		FactionState = UnitState.GetResistanceFaction();
//		if (FactionState != none)
//		{
//			FactionState.GivePostMissionInfluenceReward(NewGameState);
//		}
//	}
//}

private static function QueuePostMissionPopups(array<XComGameState_Unit> UnitStates, bool bBondAvailable)
{
	//local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	//local bool bTiredPopupQueued;
	local int idx;

	//XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	//if (bBondAvailable)
	//{
	//	`HQPRES.UISoldierCompatibilityIntro(false);
	//}

	for (idx = 0; idx < UnitStates.Length; idx++)
	{
		UnitState = UnitStates[idx];
	
		if (!UnitState.IsInjured())
		{
			if (UnitState.GetMentalState() == eMentalState_Shaken)
			{
				// Always trigger the Soldier Shaken popup
				`HQPRES.UISoldierShaken(UnitState);
			}
			//else if (!bTiredPopupQueued && !XComHQ.bHasSeenTiredSoldierPopup && UnitState.GetMentalState() == eMentalState_Tired)
			//{
			//	// Only trigger the Soldier Tired popup once per game
			//	bTiredPopupQueued = true;
			//	`HQPRES.UISoldierTired(UnitState);
			//}
		}
	}
}

static function CleanupProxyVips()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit OriginalUnit;
	local XComGameState_Unit ProxyUnit;
	local XComGameState NewGameState;
	local int Index;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// cleanup VIP proxies. If the proxy dies, then the original, real unit must also die
	for (Index = 0; Index < BattleData.RewardUnits.Length; Index++)
	{
		OriginalUnit = XComGameState_Unit(History.GetGameStateForObjectID(BattleData.RewardUnitOriginals[Index].ObjectID));
		ProxyUnit = XComGameState_Unit(History.GetGameStateForObjectID(BattleData.RewardUnits[Index].ObjectID));

		// If we never made a proxy (or it's an older save before proxies were a thing), just skip this unit.
		// we don't need to do anything if the player played the mission with the original unit
		if(OriginalUnit == none || OriginalUnit.ObjectID == ProxyUnit.ObjectID)
		{
			continue;
		}
		
		if(NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission VIP Proxy Cleanup");
		}

		// if the proxy dies, the original unit must also die
		if(ProxyUnit.IsDead())
		{
			OriginalUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', OriginalUnit.ObjectID));
			OriginalUnit.SetCurrentStat(eStat_HP, 0);
		}
		else if(OriginalUnit.IsSoldier() && ProxyUnit.IsInjured())
		{
			OriginalUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', OriginalUnit.ObjectID));
			OriginalUnit.SetCurrentStat(eStat_HP, ProxyUnit.GetCurrentStat(eStat_HP));
		}

		// Start Issue #465
		if (class'CHHelpers'.default.PreserveProxyUnitData && ProxyUnit.bRemovedFromPlay)
		{
			OriginalUnit.RemoveStateFromPlay();
		}
		// End Issue #465
		
		// remove the proxy from the game. We don't need it anymore
		NewGameState.RemoveStateObject(ProxyUnit.ObjectID);
	}

	if(NewGameState != none)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

static function UpdateChosen()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_MissionSite MissionState;
	local XComGameState_BattleData BattleData;
	local ChosenEncounterData EncounterData;
	local bool bChosenOnMission;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("PostMission: Update Chosen");
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	bChosenOnMission = false;
	
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	EncounterData.MissionSource = MissionState.GetMissionSource().DataName;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	BattleData.ChosenRef.ObjectID = 0;
	BattleData.bChosenDefeated = false;
	BattleData.bChosenLost = false;
	BattleData.bChosenWon = false;
	
	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if(ChosenState.bWasOnLastMission)
		{
			ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ChosenState.ObjectID));
			ChosenState.NumEncounters++;
			ChosenState.MissionsSinceLastAppearance = 0;
			ChosenState.CurrentAppearanceRoll = `SYNC_RAND_STATIC(100);
			ChosenState.MonthActivities.AddItem(ChosenState.EncounteredXComActivityString);
			ChosenState.bMetXCom = true;

			BattleData.ChosenRef = ChosenState.GetReference();

			// Check Chosen Status after the mission
			if(ChosenState.bDefeated)
			{
				ChosenState.OnDefeated(NewGameState);
				EncounterData.bDefeated = true;
				BattleData.bChosenDefeated = true;
			}
			else
			{
				ChosenState.ModifyKnowledgeScore(NewGameState, ChosenState.MissionKnowledgeExtracted);

				if (ChosenState.bKilledInCombat)
				{
					EncounterData.bKilled = true;
					BattleData.bChosenLost = true;
				}
				else if (ChosenState.bCapturedSoldier)
				{
					EncounterData.bCapturedSoldier = true;
					BattleData.bChosenWon = true;
				}
				else if (ChosenState.bExtractedKnowledge)
				{
					EncounterData.bGainedKnowledge = true;
					BattleData.bChosenWon = true;
				}
			}

			// Clear vars
			ChosenState.bWasOnLastMission = false;
			ChosenState.bKilledInCombat = false;
			ChosenState.bCapturedSoldier = false;
			ChosenState.bExtractedKnowledge = false;
			ChosenState.MissionKnowledgeExtracted = 0;

			// Flag that there was a Chosen on the Mission, and remove from attacking queue; save encounter data
			bChosenOnMission = true;
			AlienHQ.LastAttackingChosen = ChosenState.GetReference();
			AlienHQ.LastChosenEncounter = EncounterData;
			ChosenState.LastEncounter = EncounterData;

			// Reset the variable which tracks if a facility was sabotaged between Chosen encounters
			// but only if this mission was not a sabotage, since the flag would have just been set during ProcessMissionResults()
			if (EncounterData.MissionSource != 'MissionSource_AlienNetwork')
			{
				AlienHQ.bRecentlySabotagedFacility = false;
			}
		}

		// We increment all Chosen here (including Chosen on mission)
		ChosenState.MissionsSinceLastAppearance++;
	}

	if(bChosenOnMission)
	{
		class'XComGameState_HeadquartersAlien'.static.ClearChosenTags(NewGameState);
		AlienHQ.MissionsSinceChosen = 0;
	}
	else
	{
		AlienHQ.MissionsSinceChosen++;
	}

	AlienHQ.CurrentChosenAppearRoll = `SYNC_RAND_STATIC(100);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// Called in UIAfterAction
static function RemoveInvalidSoldiersFromSquad()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local StateObjectReference DeadUnitRef, EmptyRef;
	local GeneratedMissionData MissionData;
	local int SquadIndex;
	local array<name> SpecialSoldierNames;
	local array<EInventorySlot> SpecialSoldierSlotsToClear, SlotsToClear, LockedSlots;
	local EInventorySlot LockedSlot;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	SpecialSoldierNames = MissionData.Mission.SpecialSoldiers;

	// Issue #118 Start
	//SpecialSoldierSlotsToClear.AddItem(eInvSlot_Armor);
	//SpecialSoldierSlotsToClear.AddItem(eInvSlot_PrimaryWeapon);
	//SpecialSoldierSlotsToClear.AddItem(eInvSlot_SecondaryWeapon);
	//SpecialSoldierSlotsToClear.AddItem(eInvSlot_HeavyWeapon);
	//SpecialSoldierSlotsToClear.AddItem(eInvSlot_Utility);
	//SpecialSoldierSlotsToClear.AddItem(eInvSlot_GrenadePocket);
	//SpecialSoldierSlotsToClear.AddItem(eInvSlot_AmmoPocket);
	class'CHItemSlot'.static.CollectSlots(class'CHItemSlot'.const.SLOT_ALL, SpecialSoldierSlotsToClear);
	// Issue #118 End
	
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		DeadUnitRef = UnitState.GetReference();
		SquadIndex = XComHQ.Squad.Find('ObjectID', DeadUnitRef.ObjectID);

		if(SquadIndex != INDEX_NONE || UnitState.bSpawnedFromAvenger)
		{
			// Cleanse Status effects
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitState.bUnconscious = false;
			UnitState.bBleedingOut = false;
			UnitState.bSpawnedFromAvenger = false;

			if(SquadIndex != INDEX_NONE && (UnitState.IsDead() || (!UnitState.CanGoOnMission()) || UnitState.bCaptured || SpecialSoldierNames.Find(UnitState.GetMyTemplateName()) != INDEX_NONE))
			{
				// Remove them from the squad
				XComHQ.Squad[SquadIndex] = EmptyRef;

				// Have any special soldiers drop unique items they were given before the mission
				if (SpecialSoldierNames.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
				{
					// Reset SlotsToClear
					SlotsToClear.Length = 0;
					SlotsToClear = SpecialSoldierSlotsToClear;

					// Find the slots which are uneditable for this soldier, and remove those from the list of slots to clear
					LockedSlots = UnitState.GetSoldierClassTemplate().CannotEditSlots;
					foreach LockedSlots(LockedSlot)
					{
						if (SlotsToClear.Find(LockedSlot) != INDEX_NONE)
						{
							SlotsToClear.RemoveItem(LockedSlot);
						}
					}

					// Start Issue #310
					if (!class'CHHelpers'.default.bDontUnequipWhenWounded)
					{
						UnitState.MakeItemsAvailable(NewGameState, false, SlotsToClear);
					}
					// End Issue #310

					UnitState.bIsShaken = false;
				}
			}
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// Called in UIInventory_LootRecovered
static function AddLootToInventory(optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local int idx;
	local bool bLocalSubmission;

	History = `XCOMHISTORY;

	if (NewGameState == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Mission Loot");
		bLocalSubmission = true;
	}
	
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	for(idx = 0; idx < XComHQ.LootRecovered.Length; idx++)
	{
		ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', XComHQ.LootRecovered[idx].ObjectID));
		if(ItemState != none)
		{
			XComHQ.PutItemInInventory(NewGameState, ItemState);
		}
	}

	XComHQ.LootRecovered.Length = 0;

	if (bLocalSubmission)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

defaultproperties
{
	StrategyMapCommand = "servertravel Avenger_Root?game=XComGame.XComHeadQuartersGame"
}
