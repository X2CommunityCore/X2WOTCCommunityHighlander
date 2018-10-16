//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_LadderProgress.uc
//  AUTHOR:  Russell Aasland
//	DATE:	 11/06/2017
//           
//  Game state information for data related to ladder mode progression
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameState_LadderProgress extends XComGameState_BaseObject
		native( Challenge )
		dependson(X2ChallengeModeDataStructures)
		config( Ladder );

var bool	bNewLadder;
var bool	bRandomLadder;

var int		LadderSize;
var int		LadderIndex;
var int		LadderRung;
var string	SquadProgressionName;
var name	LadderSquadName;
var string	LadderName;

var array<string>	PlayedMissionFamilies;

var int		CumulativeScore;
var array<name> ProgressionUpgrades;

var array<name> ProgressionChoices1;
var array<name> ProgressionChoices2;

var array<string> LoadingScreenAkEvents;
var array<string> LootSelectNarrative;

var array<XComGameState_Unit> LastMissionState;

var array<int> MedalThresholds;

var privatewrite string ProgressCommand;

var config int DefaultSize;
var config array<string> AllowedMissionTypes;
var config array<string> FinalMissionTypes;

var localized string EarlyBirdTitle;
var localized string EarlyBirdBonus;

struct native SoldierFullNames
{
	var localized string sFirstName;
	var localized string sLastName;
	var localized string sNickName;
};

struct native RungConfig
{
	var int ForceLevel;
	var int AlertLevel;
};
var config array<RungConfig> RungConfiguration;

var localized string ChoiceDialogText;
var localized array<String> NarrativeLadderNames;
var localized array<SoldierFullNames> Ladder1Names;
var localized array<SoldierFullNames> Ladder2Names;
var localized array<SoldierFullNames> Ladder3Names;
var localized array<SoldierFullNames> Ladder4Names;

struct native Squad
{
	var array<name> Members;
};
struct native SquadProgression
{
	var string SquadName;
	var array<Squad> Progression;
};
var config array<SquadProgression> SquadProgressions;

// when adding to this struction, don't forget to add to PopulateFromNarrativeConfig to copy from the config to the actual ladder data
struct native NarrativeLadder
{
	var int LadderIndex;

	var array<name> Choices1;
	var array<name> Choices2;

	var array<string> LoadingAkEvents;
	var array<string> LootNarratives;

	var array<int> MedalThresholds;

	var array<string> LoadingMovies;
	var array<string> BackgroundPaths;

	var string CompletionUnlockImage;

	var array<name> SquadProgression;
};
var config array<NarrativeLadder> NarrativeLadderConfig;

var config ChallengeMissionScoring DefaultMissionScoring;
var config array<ChallengeMissionScoring> DefaultMissionScoringTable;

var config ChallengeObjectiveScoring DefaultObjectiveScoring;
var config array<ChallengeObjectiveScoring> DefaultObjectiveScoringTable;

var config ChallengeEnemyScoring DefaultEnemyScoring;
var config array<ChallengeEnemyScoring> DefaultEnemyScoringTable;

var config ChallengeSoldierScoring DefaultSoldierScoring;

var config int RestartScorePenalty;

struct native FixedLastNames
{
	var array<String> LastNames;
};

var array<FixedLastNames> FixedNarrativeUnits;

native function string GetLoadingMovie( ) const;
native function string GetLoadingAudio() const;

static function AppendNames( out array<name> Destination, const out array<name> Source )
{
	local name Entry;

	foreach Source( Entry )
		Destination.AddItem( Entry );
}

static function ProceedToNextRung( )
{
	local XComGameStateHistory History;
	local X2EventManager EventManager;
	local XComParcelManager ParcelManager;
	local XComTacticalMissionManager MissionManager;
	local X2TacticalGameRuleset Rules;

	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState StartState;

	local string MissionType;
	local MissionDefinition MissionDef;

	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local PlotTypeDefinition PlotType;

	local XComGameState_LadderProgress LadderData, NextMissionLadder;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ, NextHQ;
	local StateObjectReference LocalPlayerReference, OriginalPlayerReference;
	local XComGameState_Player PlayerState;
	local XComGameState_Player NewPlayerState;
	local XComGameState_BaseObject BaseState;
	local XComGameState_Unit UnitState;
	local XComGameState_MissionSite MissionSite;

	local StateObjectReference UnitStateRef;

	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;

	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;

	local array<name> SquadProgressionNames;
	local ConfigurableSoldier SoldierConfigData;
	local name ConfigName;
	local int SoldierIndex;
	local XComGameState_Player XComPlayer;
	local XComOnlineProfileSettings Profile;

	local array<string> PossibleMissionTypes;

	local XComGameState_CampaignSettings CurrentCampaign, NextCampaign;

	local array<XComGameState_Unit> EndingUnitStates;
	local int MedalLevel;

	local array<Actor> Visualizers;
	local Actor Visualizer;

	local int CampaignSaveID;

	local LadderMissionID ID, Entry;
	local bool Found;

	local XComGameState_Analytics CurrentAnalytics, CampaignAnalytics;

	History = `XCOMHISTORY;
	ParcelManager = `PARCELMGR;
	MissionManager = `TACTICALMISSIONMGR;
	Rules = `TACTICALRULES;
	EventManager = `XEVENTMGR;

	LadderData = XComGameState_LadderProgress(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));
	if (LadderData == none)
		return;

	CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CurrentAnalytics = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));

	foreach XComHQ.Squad(UnitStateRef)
	{
		EndingUnitStates.AddItem( XComGameState_Unit( History.GetGameStateForObjectID( UnitStateRef.ObjectID ) ) );
	}

	if (LadderData.LadderIndex < 10)
	{
		Profile = `XPROFILESETTINGS;

		ID.LadderIndex = LadderData.LadderIndex;
		ID.MissionIndex = LadderData.LadderRung;

		Found = false;

		foreach Profile.Data.HubStats.LadderCompletions(Entry)
		{
			if (Entry == ID)
			{
				Found = true;
				break;
			}
		}

		if (!Found)
		{
			Profile.Data.HubStats.LadderCompletions.AddItem( ID );

			`ONLINEEVENTMGR.SaveProfileSettings();
		}
	}

	if (LadderData.LadderRung + 1 > LadderData.LadderSize)
	{

		if (LadderData.MedalThresholds.Length > 0)
		{
			for (MedalLevel = 0; (LadderData.CumulativeScore > LadderData.MedalThresholds[ MedalLevel ]) && (MedalLevel < LadderData.MedalThresholds.Length); ++MedalLevel)
				; // no actual work to be done, once the condition fails MedalLevel will be the value we want
		}
		else
		{
			MedalLevel = 0;
		}

		`FXSLIVE.BizAnalyticsLadderEnd( CurrentCampaign.BizAnalyticsCampaignID, LadderData.LadderIndex, LadderData.CumulativeScore, MedalLevel, LadderData.SquadProgressionName, CurrentCampaign.DifficultySetting );

		if (MedalLevel == 3)
		{
			switch (LadderData.LadderIndex)
			{
				case 1:
					class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Gold Blast from the Past");
					`ONLINEEVENTMGR.UnlockAchievement(AT_GoldBlastFromThePast);
					break;

				case 2:
					class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Gold It Came from the Sea");
					`ONLINEEVENTMGR.UnlockAchievement(AT_GoldItCameFromTheSea);
					break;

				case 3:
					class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Gold Avenger Assemble");
					`ONLINEEVENTMGR.UnlockAchievement(AT_GoldAvengerAssemble);
					break;

				case 4:
					class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Gold Lazarus Project");
					`ONLINEEVENTMGR.UnlockAchievement(AT_GoldLazarusProject);
					break;
			}
		}

		if (LadderData.bNewLadder && LadderData.bRandomLadder)
		{
			class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Complete Procedural Ladder");
			`ONLINEEVENTMGR.UnlockAchievement(AT_CompleteProceduralLadder);
		}

		// Finished the ladder, delete the save so that next time the player will start from the beginning
		CampaignSaveID = `AUTOSAVEMGR.GetSaveIDForCampaign( CurrentCampaign );
		if (CampaignSaveID >= 0)
		{
			`ONLINEEVENTMGR.DeleteSaveGame( CampaignSaveID );
		}
		`ONLINEEVENTMGR.SaveLadderSummary( );

		LadderData.ProgressCommand = "disconnect";
		LadderData.LadderRung++;
		return;
	}

	if (!LadderData.bNewLadder)
	{
		Visualizers = History.GetAllVisualizers( );

		if (!History.ReadHistoryFromFile( "Ladders/", "Mission_" $ LadderData.LadderIndex $ "_" $ (LadderData.LadderRung + 1) $ "_" $ CurrentCampaign.DifficultySetting ))
		{
			if (!LadderData.bRandomLadder)
			{
				LadderData.ProgressCommand = "disconnect";
				return;
			}
			// there isn't a next mission for this procedural ladder, fall through to the normal procedural ladder progression
		}
		else
		{
			foreach Visualizers( Visualizer ) // gotta get rid of all these since we'll be wiping out the history objects they may be referring to (but only if we loaded a history)
			{
				if (Visualizer.bNoDelete)
					continue;

				Visualizer.SetTickIsDisabled( true );
				Visualizer.Destroy( );
			}

			// abuse the history diffing function to copy data from the current campaign into the new start state
			CampaignAnalytics = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
			CampaignAnalytics.SingletonCopyForHistoryDiffDuplicate( CurrentAnalytics );

			NextHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			NextHQ.SeenCharacterTemplates = XComHQ.SeenCharacterTemplates;

			// transfer over the player's current score to the loaded history start state.
			NextMissionLadder = XComGameState_LadderProgress( History.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress' ) );
			NextMissionLadder.CumulativeScore = LadderData.CumulativeScore;

			// transfer over the active set of player choices (overwriting the choices they had made the previous time)
			NextMissionLadder.ProgressionUpgrades = LadderData.ProgressionUpgrades;

			NextMissionLadder.LastMissionState = EndingUnitStates;

			// Maintain the campaign start times
			NextCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
			NextCampaign.SetStartTime( CurrentCampaign.StartTime );
			NextCampaign.HACK_ForceGameIndex( CurrentCampaign.GameIndex );
			NextCampaign.BizAnalyticsCampaignID = CurrentCampaign.BizAnalyticsCampaignID;

			SoldierIndex = 0;
			foreach NextHQ.Squad(UnitStateRef)
			{
				// pull the unit from the archives, and add it to the start state
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateRef.ObjectID));

				if (SoldierIndex < EndingUnitStates.Length)
					UpdateUnitCustomization(UnitState, EndingUnitStates[SoldierIndex]);
				else if(LadderData.LadderIndex <= 4)
					LocalizeUnitName(UnitState, SoldierIndex, LadderData.LadderIndex);

				++SoldierIndex;
			}

			// fix up the soldier equipment for the choices we've made along the way
			HandlePreExistingSoliderEquipment( History, NextMissionLadder );
		
			// update the ability states based on the patch-ups that we've done to the gamestate
			//RefreshAbilities( History ); // moved to tactical ruleset so that any cosmetic units that are spawned happen after we've loaded the new map

			// TODO: any other patch up from the previous mission history into the new history.

			BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
			NextMissionLadder.ProgressCommand =  BattleData.m_strMapCommand;
			BattleData.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );
			return;
		}
	}

	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);

	LadderData = XComGameState_LadderProgress(StartState.ModifyStateObject(class'XComGameState_LadderProgress', LadderData.ObjectID));
	LadderData.bNewLadder = true; // in case we're picking up from an abandoned ladder and the last rung was not new.

	LadderData.LastMissionState = EndingUnitStates;

	if (LadderData.LadderRung < (LadderData.LadderSize - 1))
	{
		PossibleMissionTypes = default.AllowedMissionTypes;

		do {
			MissionType = PossibleMissionTypes[ `SYNC_RAND_STATIC( PossibleMissionTypes.Length ) ]; // try a random mission

			if (!MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
			{
				MissionType = "";
				continue; // try again
			}

			// see if we've already played that
			if ((LadderData.PlayedMissionFamilies.Find( MissionDef.MissionFamily ) != INDEX_NONE) && (default.AllowedMissionTypes.Length > 1))
			{
				PossibleMissionTypes.RemoveItem( MissionType );

				// if we ran out of mission types, start over but remove half the history
				// this way we do repeat, but at least we repeat stuff that's older than what we just played.
				if (PossibleMissionTypes.Length == 0)
				{
					PossibleMissionTypes = default.AllowedMissionTypes;
					LadderData.PlayedMissionFamilies.Remove( 0, LadderData.PlayedMissionFamilies.Length / 2 );
				}

				MissionType = "";
				continue; // try again
			}

		} until( MissionType != "" );

		LadderData.PlayedMissionFamilies.AddItem( MissionDef.MissionFamily ); // add to the ladder history
	}
	else
	{
		MissionType = default.FinalMissionTypes[ `SYNC_RAND_STATIC( default.FinalMissionTypes.Length ) ];

		if(!MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
		{
			`Redscreen("TransferToNewMission(): Mission Type " $ MissionType $ " has no definition!");
			LadderData.ProgressCommand = "disconnect";
			return;
		}
	}

	MissionManager.ForceMission = MissionDef;

	// pick our new map
	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef);
	if(ValidPlots.Length == 0)
	{
		`Redscreen("TransferToNewMission(): Could not find a plot to transfer to for mission type " $ MissionType $ "!");
		LadderData.ProgressCommand = "disconnect";
		return;
	}

	// Get the local player id before creating the new battle data since this uses latest battle data to find that value.
	LocalPlayerReference.ObjectID = Rules.GetLocalClientPlayerObjectID();

	NewPlot = ValidPlots[ `SYNC_RAND_STATIC(ValidPlots.Length) ];
	PlotType = ParcelManager.GetPlotTypeDefinition( NewPlot.strType );

	BattleData = XComGameState_BattleData( StartState.CreateNewStateObject( class'XComGameState_BattleData' ) );
	BattleData.m_iMissionType = MissionManager.arrMissions.Find('sType', MissionType);
	BattleData.MapData.PlotMapName = NewPlot.MapName;
	BattleData.MapData.ActiveMission = MissionDef;
	BattleData.LostSpawningLevel = BattleData.SelectLostActivationCount();
	BattleData.m_strMapCommand = "open" @ BattleData.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";
	BattleData.SetForceLevel( default.RungConfiguration[ LadderData.LadderRung ].ForceLevel );
	BattleData.SetAlertLevel( default.RungConfiguration[ LadderData.LadderRung ].AlertLevel );
	BattleData.m_nQuestItem = SelectQuestItem( MissionDef.sType );
	BattleData.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );

	if (NewPlot.ValidBiomes.Length > 0)
		BattleData.MapData.Biome = NewPlot.ValidBiomes[ `SYNC_RAND_STATIC(NewPlot.ValidBiomes.Length) ];

	AppendNames( BattleData.ActiveSitReps, MissionDef.ForcedSitreps );
	AppendNames( BattleData.ActiveSitReps, PlotType.ForcedSitReps );

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(MissionDef.MissionName);
	if( MissionTemplate != none )
	{
		BattleData.m_strDesc = MissionTemplate.Briefing;
	}
	else
	{
		BattleData.m_strDesc = "NO LOCALIZED BRIEFING TEXT!";
	}

	MissionSite = SetupMissionSite( StartState, BattleData );

	// copy over the xcom headquarters object. Need to do this first so it's available for the unit transfer
	XComHQ = XComGameState_HeadquartersXCom(StartState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.TacticalGameplayTags.Length = 0;

	OriginalPlayerReference = LocalPlayerReference;

	// Player states and ai groups will automatically be removed as part of the archive process, but we still need
	// to remove them from the player turn order
	assert(class'XComGameState_Player'.default.bTacticalTransient); // verify that the player will automatically be removed
	assert(class'XComGameState_AIGroup'.default.bTacticalTransient); // verify that the ai groups will automatically be removed
	BattleData.PlayerTurnOrder.Length = 0;

	// Create new states for the players
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		// create a new player. This will clear out any old data about
		// units and AI
		NewPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, PlayerState.GetTeam());
		NewPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
		BattleData.PlayerTurnOrder.AddItem(NewPlayerState.GetReference());

		if (PlayerState.ObjectID == LocalPlayerReference.ObjectID) // this is the local human team, need to keep track of it
		{
			LocalPlayerReference.ObjectID = NewPlayerState.ObjectID;
			XComPlayer = NewPlayerState;
		}
	}

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		// remove any events associated with units. We'll re-add them when the next mission starts
		TransferUnitToNewMission(UnitState, StartState, XComHQ, BattleData, OriginalPlayerReference, LocalPlayerReference);
	}

	// copy over any other non-transient state objects, excepting player objects and alien units
	foreach History.IterateByClassType(class'XComGameState_BaseObject', BaseState)
	{
		if (XComGameState_Player(BaseState) != none) // we already handled players above
			continue;

		if (XComGameState_HeadquartersXCom(BaseState) != none) // we also handled xcom headquarters
			continue;

		if (XComGameState_Unit(BaseState) != none) // we also handled units
			continue;
		
		if (XComGameState_BattleData(BaseState) != none)
			continue;

		if (BaseState.bTacticalTransient) // a transient state, so don't bring it along
			continue;
		
		BaseState = StartState.ModifyStateObject(BaseState.Class, BaseState.ObjectID);

		if (XComGameState_ObjectivesList(BaseState) != none)
		{
			XComGameState_ObjectivesList(BaseState).ClearTacticalObjectives();
		}
	}

	SquadProgressionNames = GetSquadProgressionMembers( LadderData.SquadProgressionName, LadderData.LadderRung + 1 );

	// make sure every unit on this leg of the mission is ready to go
	SoldierIndex = 0;
	foreach XComHQ.Squad(UnitStateRef)
	{
		// pull the unit from the archives, and add it to the start state
		UnitState = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', UnitStateRef.ObjectID));
		UnitState.SetHQLocation(eSoldierLoc_Dropship);

		UnitState.ClearRemovedFromPlayFlag();

		ConfigName = SquadProgressionNames[ SoldierIndex ];

		if (class'UITacticalQuickLaunch_MapData'.static.GetConfigurableSoldierSpec( ConfigName, SoldierConfigData ))
		{
			UnitState.bIgnoreItemEquipRestrictions = true;
			UpdateUnitCustomization( UnitState, EndingUnitStates[ SoldierIndex ] );
			UpdateUnitState( StartState, UnitState, SoldierConfigData, LadderData.ProgressionUpgrades );
		}
		else
		{
			`warn("LadderMode Progression unable to find '" $ ConfigName $ "' soldier data.");
		}

		++SoldierIndex;
	}

	while (SoldierIndex < SquadProgressionNames.Length) // new soldier added to the squad
	{
		ConfigName = SquadProgressionNames[ SoldierIndex ];

		UnitState = class'UITacticalQuickLaunch_MapData'.static.ApplySoldier( ConfigName, StartState, XComPlayer );

		if (class'UITacticalQuickLaunch_MapData'.static.GetConfigurableSoldierSpec( ConfigName, SoldierConfigData ))
		{
			UnitState.bIgnoreItemEquipRestrictions = true;
			UpdateUnitState( StartState, UnitState, SoldierConfigData, LadderData.ProgressionUpgrades );
		}

		++SoldierIndex;
	}
	History.UpdateStateObjectCache( );

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

	MissionSite.UpdateSitrepTags( );
	XComHQ.AddMissionTacticalTags( MissionSite );
	class'X2SitRepTemplate'.static.ModifyPreMissionBattleDataState(BattleData, BattleData.ActiveSitReps);

	LadderData.ProgressCommand = BattleData.m_strMapCommand;
	++LadderData.LadderRung;

	History.AddGameStateToHistory(StartState);
}

static function XComGameState_MissionSite SetupMissionSite(XComGameState LocalStartState, XComGameState_BattleData OldBattleData)
{
	local XComGameState_MissionSite ChallengeMissionSite;
	local XComGameState_Continent Continent;
	local XComGameState_WorldRegion Region;

	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> ContinentDefinitions;
	local X2ContinentTemplate RandContinentTemplate;
	local X2WorldRegionTemplate RandRegionTemplate;

	local int RandContinent, RandRegion;
	local Vector CenterLoc, RegionExtents;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ContinentDefinitions = StratMgr.GetAllTemplatesOfClass(class'X2ContinentTemplate');

	RandContinent = `SYNC_RAND_STATIC(ContinentDefinitions.Length);
	RandContinentTemplate = X2ContinentTemplate(ContinentDefinitions[RandContinent]);

	RandRegion = `SYNC_RAND_STATIC( RandContinentTemplate.Regions.Length );
	RandRegionTemplate = X2WorldRegionTemplate(StratMgr.FindStrategyElementTemplate(RandContinentTemplate.Regions[RandRegion]));

	Continent = XComGameState_Continent(LocalStartState.CreateNewStateObject(class'XComGameState_Continent', RandContinentTemplate));

	Region = XComGameState_WorldRegion(LocalStartState.CreateNewStateObject(class'XComGameState_WorldRegion', RandRegionTemplate));

	Continent.AssignRegions(LocalStartState);

	// Choose random location from the region
	RegionExtents.X = (RandRegionTemplate.Bounds[0].fRight - RandRegionTemplate.Bounds[0].fLeft) / 2.0f;
	RegionExtents.Y = (RandRegionTemplate.Bounds[0].fBottom - RandRegionTemplate.Bounds[0].fTop) / 2.0f;
	CenterLoc.x = RandRegionTemplate.Bounds[0].fLeft + RegionExtents.X;
	CenterLoc.y = RandRegionTemplate.Bounds[0].fTop + RegionExtents.Y;

	ChallengeMissionSite = XComGameState_MissionSite(LocalStartState.CreateNewStateObject(class'XComGameState_MissionSite'));
	ChallengeMissionSite.Location = CenterLoc + (`SYNC_VRAND_STATIC() * RegionExtents);
	ChallengeMissionSite.Continent.ObjectID = Continent.ObjectID;
	ChallengeMissionSite.Region.ObjectID = Region.ObjectID;

	ChallengeMissionSite.GeneratedMission.MissionID = ChallengeMissionSite.ObjectID;
	ChallengeMissionSite.GeneratedMission.Mission = `TACTICALMISSIONMGR.arrMissions[OldBattleData.m_iMissionType];
	ChallengeMissionSite.GeneratedMission.LevelSeed = OldBattleData.iLevelSeed;
	ChallengeMissionSite.GeneratedMission.BattleOpName = OldBattleData.m_strOpName;
	ChallengeMissionSite.GeneratedMission.BattleDesc = "Ladder Mode";
	ChallengeMissionSite.GeneratedMission.MissionQuestItemTemplate = OldBattleData.m_nQuestItem;
	ChallengeMissionSite.GeneratedMission.SitReps = OldBattleData.ActiveSitReps;

	OldBattleData.m_iMissionID = ChallengeMissionSite.ObjectID;

	return ChallengeMissionSite;
}

static function RefreshAbilities( XComGameStateHistory History )
{
	local XComGameState StartState;
	local XComGameState_Ability AbilityState;
	local XComGameState_Item IterateItemState;

	StartState = History.GetStartState( );
	`assert( StartState != none );

	// recreate any cosmetic units that we destroyed the original of
	foreach StartState.IterateByClassType(class'XComGameState_Item', IterateItemState)
	{
		IterateItemState.CreateCosmeticItemUnit(StartState);
	}

	// remove all the abilities that are already in the start state
	foreach History.IterateByClassType( class'XComGameState_Ability', AbilityState )
	{
		History.PurgeObjectIDFromStartState( AbilityState.ObjectID, false );
	}
	History.UpdateStateObjectCache( );

	// rebuild them based on various updates to loadout and other patchup work we've done
	class'X2TacticalGameRuleset'.static.StartStateInitializeUnitAbilities( StartState );
}

private static function UpdateUnitCustomization( XComGameState_Unit NextMissionUnit, XComGameState_Unit PrevMissionUnit )
{
	local XGCharacterGenerator CharacterGenerator;
	local TSoldier Soldier;

	if (PrevMissionUnit.IsAlive( ))
	{
		Soldier.kAppearance = PrevMissionUnit.kAppearance;
		Soldier.nmCountry = PrevMissionUnit.GetCountry( );

		Soldier.strFirstName = PrevMissionUnit.GetFirstName( );
		Soldier.strLastName = PrevMissionUnit.GetLastName( );
		Soldier.strNickName = PrevMissionUnit.GetNickName( );
	}
	else
	{
		CharacterGenerator = `XCOMGRI.Spawn(NextMissionUnit.GetMyTemplate().CharacterGeneratorClass);

		Soldier = CharacterGenerator.CreateTSoldier( NextMissionUnit.GetMyTemplateName() );
		Soldier.strNickName = NextMissionUnit.GenerateNickname( );
	}

	NextMissionUnit.SetTAppearance(Soldier.kAppearance);
	NextMissionUnit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
	NextMissionUnit.SetCountry(Soldier.nmCountry);
}

static function LocalizeUnitName(XComGameState_Unit NextMissionUnit, int unitNameIndex, int ladderMissionIndex)
{
	local array<SoldierFullNames> nameArray;

	switch (ladderMissionIndex)
	{
	case 1:
		nameArray = default.Ladder1Names;
		break;
	case 2:
		nameArray = default.Ladder2Names;
		break;
	case 3:
		nameArray = default.Ladder3Names;
		break;
	case 4:
		nameArray = default.Ladder4Names;
		break;
	default:
		nameArray = default.Ladder1Names;
	}

	NextMissionUnit.SetCharacterName(nameArray[unitNameIndex].sFirstName, nameArray[unitNameIndex].sLastName, nameArray[unitNameIndex].sNickName);
}

static function string GetUnitName(int unitNameIndex, int ladderMissionIndex)
{
	local array<SoldierFullNames> nameArray;

	switch (ladderMissionIndex)
	{
	case 1:
		nameArray = default.Ladder1Names;
		break;
	case 2:
		nameArray = default.Ladder2Names;
		break;
	case 3:
		nameArray = default.Ladder3Names;
		break;
	case 4:
		nameArray = default.Ladder4Names;
		break;
	default:
		nameArray = default.Ladder1Names;
	}

	return nameArray[unitNameIndex].sFirstName @ nameArray[unitNameIndex].sLastName;
}

private static function HandlePreExistingSoliderEquipment( XComGameStateHistory History, XComGameState_LadderProgress LadderData )
{
	local XComGameState StartState;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<name> SquadProgressionNames;
	local int SoldierIndex, Index;
	local StateObjectReference UnitStateRef;
	local ConfigurableSoldier SoldierConfigData;
	local name ConfigName;
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState;

	StartState = History.GetStartState( );
	`assert( StartState != none );

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (LadderData.SquadProgressionName != "")
		SquadProgressionNames = GetSquadProgressionMembers( LadderData.SquadProgressionName, LadderData.LadderRung );
	if (LadderData.LadderSquadName != '')
		class'UITacticalQuickLaunch_MapData'.static.GetSqaudMemberNames( LadderData.LadderSquadName, SquadProgressionNames );

	// make sure every unit on this leg of the mission is ready to go
	SoldierIndex = 0;
	foreach XComHQ.Squad(UnitStateRef)
	{
		UnitState = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', UnitStateRef.ObjectID));

		// remove all their items
		for (Index = UnitState.InventoryItems.Length - 1; Index >= 0; --Index)
		{
			ItemState = XComGameState_Item( StartState.ModifyStateObject(class'XComGameState_Item', UnitState.InventoryItems[Index].ObjectID) );
			if (UnitState.CanRemoveItemFromInventory( ItemState, StartState ))
			{
				UnitState.RemoveItemFromInventory( ItemState, StartState );
				History.PurgeObjectIDFromStartState( ItemState.ObjectID, false ); // don't refresh the cache every time, we'll do that once after removing all items from all units

				if (ItemState.CosmeticUnitRef.ObjectID > 0) // we also need to destroy any associated units that may exist
				{
					History.PurgeObjectIDFromStartState( ItemState.CosmeticUnitRef.ObjectID, false ); // don't refresh the cache every time, we'll do that once after removing all items from all units
				}
			}
		}

		ConfigName = SquadProgressionNames[ SoldierIndex ];

		if (class'UITacticalQuickLaunch_MapData'.static.GetConfigurableSoldierSpec( ConfigName, SoldierConfigData ))
		{
			UnitState.bIgnoreItemEquipRestrictions = true;
			UpdateUnitState( StartState, UnitState, SoldierConfigData, LadderData.ProgressionUpgrades );
		}
		else
		{
			`warn("LadderMode Progression unable to find '" $ ConfigName $ "' soldier data.");
		}

		++SoldierIndex;
	}
	History.UpdateStateObjectCache( );
}

private static function TransferUnitToNewMission(XComGameState_Unit UnitState, 
													XComGameState NewStartState,
													XComGameState_HeadquartersXCom XComHQ, 
													XComGameState_BattleData BattleData,
													StateObjectReference OriginalPlayerObjectID,
													StateObjectReference NewLocalPlayerObjectID)
{
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference StateRef, EmptyReference;
	local int SquadIdx;

	History = `XCOMHISTORY;

	SquadIdx = XComHQ.Squad.Find( 'ObjectID', UnitState.ObjectID );

	if (!UnitState.bMissionProvided // don't keep anyone the mission started them with
		&& (SquadIdx != INDEX_NONE)) // don't keep anyone that wasn't configured as part of our squad
	{
		UnitState = XComGameState_Unit(NewStartState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		UnitState.SetCurrentStat( eStat_Will, UnitState.GetMaxStat( eStat_Will ) );
		UnitState.SetControllingPlayer( NewLocalPlayerObjectID );

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

			if (EffectState != None)
			{
				// Some effects like Stasis and ModifyStats need to be undone
				EffectState.GetX2Effect().UnitEndedTacticalPlay(EffectState, UnitState);
			}

			UnitState.RemoveAffectingEffect(EffectState);
			UnitState.UnApplyEffectFromStats(EffectState);
		}

		UnitState.bDisabled = false;
		UnitState.ReflexActionState = eReflexActionState_None;
		UnitState.DamageResults.Length = 0;
		UnitState.Ruptured = 0;
		UnitState.bTreatLowCoverAsHigh = false;
		UnitState.m_SpawnedCocoonRef = EmptyReference;
		UnitState.m_MultiTurnTargetRef = EmptyReference;
		UnitState.m_SuppressionHistoryIndex = -1;
		UnitState.bPanicked = false;
		UnitState.bInStasis = false;
		UnitState.bBleedingOut = false;
		UnitState.bUnconscious = false;
		UnitState.bHasSuperConcealment = false;
		UnitState.SuperConcealmentLoss = 0;
		UnitState.bGeneratesCover = false;
		UnitState.CoverForceFlag = CoverForce_Default;
		UnitState.ReflectedAbilityContext = none;

		UnitState.ClearAllTraversalChanges();
	}
	else if (SquadIdx != INDEX_NONE) // if they were in the squad they should be removed.
	{
		XComHQ.Squad.Remove( SquadIdx, 1 );
	}
}

private static function SwapItem( XComGameState StartState, XComGameState_Unit UnitState, name EquipmentTemplateName, optional EInventorySlot OverrideSlot = eInvSlot_Unknown )
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item ItemInstance, ExistingItem;
	local EInventorySlot WorkingSlot;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	EquipmentTemplate = X2EquipmentTemplate( ItemTemplateManager.FindItemTemplate( EquipmentTemplateName ) );

	if (EquipmentTemplate != none)
	{
		WorkingSlot = OverrideSlot == eInvSlot_Unknown ? EquipmentTemplate.InventorySlot : OverrideSlot;

		ExistingItem = UnitState.GetItemInSlot( WorkingSlot );

		if (ExistingItem.GetMyTemplate() != EquipmentTemplate)
		{
			if (ExistingItem != none)
			{
				`assert( UnitState.CanRemoveItemFromInventory( ExistingItem, StartState ) );

				UnitState.RemoveItemFromInventory( ExistingItem, StartState );
				`XCOMHISTORY.PurgeObjectIDFromStartState( ExistingItem.ObjectID, false ); // don't refresh the cache every time, we'll do that once after removing all items from all units
			}

			ItemInstance = EquipmentTemplate.CreateInstanceFromTemplate( StartState );
			UnitState.AddItemToInventory( ItemInstance, WorkingSlot, StartState );
		}
		else
		{
			// propagate this item through to the next start state
			ExistingItem = XComGameState_Item( StartState.ModifyStateObject( class'XComGameState_Item', ExistingItem.ObjectID ) );

			// reset the reference to the cosmetic unit: A) that unit won't be coming along in the transfers, B) and we'll create new ones at the start of the map anyway
			if (ExistingItem.CosmeticUnitRef.ObjectID > 0)
				ExistingItem.CosmeticUnitRef.ObjectID = -1;
		}
	}
}

private static function SwapUtilityItem( XComGameState StartState, XComGameState_Unit UnitState, name EquipmentTemplateName, int UtilityIndex )
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate, SlotTemplate;
	local XComGameState_Item ItemInstance;
	local array<XComGameState_Item> AllUtilities;
	local int Index;
	local bool GrenadeItem;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	EquipmentTemplate = X2EquipmentTemplate( ItemTemplateManager.FindItemTemplate( EquipmentTemplateName ) );

	if (EquipmentTemplate != none)
	{
		AllUtilities = UnitState.GetAllItemsInSlot( eInvSlot_Utility );

		for (Index = 0; Index < AllUtilities.Length; ++Index)
		{
			SlotTemplate = X2EquipmentTemplate( AllUtilities[ Index ].GetMyTemplate( ) );

			if (SlotTemplate.DataName == 'XPad')
				continue;

			// treat grenades and medkits as a slot 1 item, everything else is slot 2.
			GrenadeItem = ((SlotTemplate.ItemCat == 'grenade') || (SlotTemplate.ItemCat == 'heal'));

			if (GrenadeItem && (UtilityIndex != 0))
				continue;
			if (!GrenadeItem && (UtilityIndex == 0))
				continue;

			`assert( UnitState.CanRemoveItemFromInventory( AllUtilities[ Index ], StartState ) );

			UnitState.RemoveItemFromInventory( AllUtilities[ Index ], StartState );
			`XCOMHISTORY.PurgeObjectIDFromStartState( AllUtilities[ Index ].ObjectID, false ); // don't refresh the cache every time, we'll do that once after removing all items from all units

			break;
		}

		ItemInstance = EquipmentTemplate.CreateInstanceFromTemplate( StartState );
		UnitState.AddItemToInventory( ItemInstance, eInvSlot_Utility, StartState );
	}
}

private static function UpdateUnitState( XComGameState StartState, XComGameState_Unit UnitState, const out ConfigurableSoldier SoldierConfigData, const array<name> Upgrades )
{
	local SCATProgression Progression;
	local array<SoldierClassAbilityType> AbilityTree;
	local array<SCATProgression> SoldierProgression;

	local X2LadderUpgradeTemplateManager TemplateManager;
	local name UpgradeName;
	local X2LadderUpgradeTemplate UpgradeTemplate;
	local Upgrade Entry;

	local X2ItemTemplateManager ItemManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local name ItemName;
	local XComGameState_Item PrimaryWeapon;
	local X2WeaponTemplate WeaponTemplate;
	local array<name> WeaponUpgrades;
	local int index;
	local array<XComGameState_Item> BackpackItems;

	`assert( UnitState.GetSoldierClassTemplateName() == SoldierConfigData.SoldierClassTemplate );

	while (UnitState.GetRank() < SoldierConfigData.SoldierRank)
	{
		UnitState.RankUpSoldier( StartState );
	}

	for (Progression.iRank = 0; Progression.iRank < SoldierConfigData.SoldierRank; ++Progression.iRank)
	{
		AbilityTree = UnitState.GetRankAbilities( Progression.iRank );
		for (Progression.iBranch = 0; Progression.iBranch < AbilityTree.Length; ++Progression.iBranch)
		{
			if (SoldierConfigData.EarnedClassAbilities.Find( AbilityTree[ Progression.iBranch ].AbilityName ) != INDEX_NONE)
			{
				SoldierProgression.AddItem( Progression );
			}
		}
	}
	UnitState.SetSoldierProgression( SoldierProgression );

	UnitState.AppearanceStore.Length = 0;

	// Add all the items for this configuration level
	SwapItem( StartState, UnitState, SoldierConfigData.PrimaryWeaponTemplate );
	SwapItem( StartState, UnitState, SoldierConfigData.SecondaryWeaponTemplate );
	SwapItem( StartState, UnitState, SoldierConfigData.ArmorTemplate );
	SwapItem( StartState, UnitState, SoldierConfigData.HeavyWeaponTemplate );
	SwapItem( StartState, UnitState, SoldierConfigData.GrenadeSlotTemplate, eInvSlot_GrenadePocket );
	SwapUtilityItem( StartState, UnitState, SoldierConfigData.UtilityItem1Template, 0 );
	SwapUtilityItem( StartState, UnitState, SoldierConfigData.UtilityItem2Template, 1 );

	if ((SoldierConfigData.SoldierClassTemplate == 'Grenadier') &&
		(SoldierConfigData.GrenadeSlotTemplate == ''))
	{
		SwapItem( StartState, UnitState, 'FragGrenade', eInvSlot_GrenadePocket );
	}

	BackpackItems = UnitState.GetAllItemsInSlot( eInvSlot_Backpack );
	for (index = 0; index < BackpackItems.Length; ++index)
	{
		UnitState.RemoveItemFromInventory( BackpackItems[index], StartState );
		`XCOMHISTORY.PurgeObjectIDFromStartState( BackpackItems[index].ObjectID, false ); // don't refresh the cache every time, we'll do that once after removing all items from all units
	}

	PrimaryWeapon = UnitState.GetPrimaryWeapon( );
	PrimaryWeapon = XComGameState_Item( StartState.GetGameStateForObjectID( PrimaryWeapon.ObjectID ) );
	WeaponTemplate = X2WeaponTemplate( PrimaryWeapon.GetMyTemplate( ) );
	if (WeaponTemplate.NumUpgradeSlots > 0)
		PrimaryWeapon.WipeUpgradeTemplates( );

	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	TemplateManager = class'X2LadderUpgradeTemplateManager'.static.GetLadderUpgradeTemplateManager( );
	foreach Upgrades( UpgradeName )
	{
		UpgradeTemplate = TemplateManager.FindUpgradeTemplate( UpgradeName );

		foreach UpgradeTemplate.Upgrades( Entry )
		{
			if ((Entry.ClassFilter != "") && (Entry.ClassFilter != string(SoldierConfigData.SoldierClassTemplate)))
				continue;

			foreach Entry.EquipmentNames( ItemName )
			{
				EquipmentTemplate = X2EquipmentTemplate( ItemManager.FindItemTemplate( ItemName ) );
				WeaponUpgradeTemplate = X2WeaponUpgradeTemplate( ItemManager.FindItemTemplate( ItemName ) );

				if (EquipmentTemplate != none)
				{
					if (EquipmentTemplate.InventorySlot != eInvSlot_Utility)
					{
						ItemName = MaybeTweakItemName( EquipmentTemplate, UnitState );
						SwapItem( StartState, UnitState, ItemName );
					}
					else if (EquipmentTemplate.ItemCat == 'grenade')
					{
						SwapUtilityItem( StartState, UnitState, ItemName, 0 );
					}
					else
					{
						SwapUtilityItem( StartState, UnitState, ItemName, 1 );
					}
				}
				else if ((WeaponUpgradeTemplate != none) && (WeaponTemplate.NumUpgradeSlots > 0))
				{
					WeaponUpgrades = PrimaryWeapon.GetMyWeaponUpgradeTemplateNames( );

					for (index = 0; index < WeaponUpgrades.Length; ++index)
					{
						if (WeaponUpgradeTemplate.MutuallyExclusiveUpgrades.Find( WeaponUpgrades[ index ] ) != -1)
						{
							PrimaryWeapon.ApplyWeaponUpgradeTemplate( WeaponUpgradeTemplate, index );
							break;
						}
					}

					if (index == WeaponUpgrades.Length)
					{
						if (index < WeaponTemplate.NumUpgradeSlots)
						{
							PrimaryWeapon.ApplyWeaponUpgradeTemplate( WeaponUpgradeTemplate );
						}
						else
						{
							`redscreen( "Unable to determine space to apply weapon upgrade"@WeaponUpgradeTemplate.DataName );
						}
					}
				}
			}
		}
	}

	UnitState.SetCurrentStat( eStat_HP, UnitState.GetMaxStat( eStat_HP ) );
}

static function name MaybeTweakItemName( X2EquipmentTemplate EquipmentTemplate, XComGameState_Unit UnitState )
{
	local XComGameState_Item ExistingItem;
	local X2EquipmentTemplate ExistingTemplate, UpgradeTemplate;
	local X2ItemTemplateManager ItemManager;
	local X2DataTemplate Template;

	// if it's not a weapon, don't bother with trying to upgrades
	if ((EquipmentTemplate.InventorySlot != eInvSlot_PrimaryWeapon) &&
		(EquipmentTemplate.InventorySlot != eInvSlot_SecondaryWeapon))
	{
		return EquipmentTemplate.DataName;
	}

	ExistingItem = UnitState.GetItemInSlot( EquipmentTemplate.InventorySlot );
	ExistingTemplate = X2EquipmentTemplate( ExistingItem.GetMyTemplate( ) );

	if (EquipmentTemplate.Tier >= ExistingTemplate.Tier)
		return EquipmentTemplate.DataName;

	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach ItemManager.IterateTemplates( Template )
	{
		UpgradeTemplate = X2EquipmentTemplate( Template );

		if (UpgradeTemplate.BaseItem == EquipmentTemplate.DataName)
		{
			EquipmentTemplate = UpgradeTemplate;

			if (EquipmentTemplate.Tier >= ExistingTemplate.Tier)
				return EquipmentTemplate.DataName;
		}
	}

	return EquipmentTemplate.DataName;
}

event OnCreation( optional X2DataTemplate InitTemplate )
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.RegisterForEvent( ThisObj, 'KillMail', OnKillMail, ELD_OnStateSubmitted, , , true ); // unit died messages
	EventManager.RegisterForEvent( ThisObj, 'KillMail', OnUnitKilled, ELD_OnStateSubmitted, , , true ); // unit died messages
	EventManager.RegisterForEvent( ThisObj, 'KnockSelfoutUnconscious', OnUnitUnconscious, ELD_OnStateSubmitted, , , true ); // unit goes unconscious instead of killed messages
	EventManager.RegisterForEvent( ThisObj, 'CivilianRescued', OnCivilianRescued, ELD_OnStateSubmitted, , , true ); // civilian rescued
	EventManager.RegisterForEvent( ThisObj, 'MissionObjectiveMarkedCompleted', OnMissionObjectiveComplete, ELD_OnStateSubmitted, , , true ); // mission objective complete
	EventManager.RegisterForEvent( ThisObj, 'UnitTakeEffectDamage', OnUnitDamage, ELD_OnStateSubmitted, , , true ); // unit damaged messages
	EventManager.RegisterForEvent( ThisObj, 'ChallengeModeScoreChange', OnChallengeModeScore, ELD_OnStateSubmitted, , , true );
}

function EventListenerReturn OnUnitDamage(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState, PreviousState;
	local XComChallengeModeManager ChallengeModeManager;
	local ChallengeSoldierScoring SoldierScoring;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress LadderData;
	local XComGameState_ChallengeScore ChallengeScore;
	local UnitValue UnitValue;
	local XComGameState_Analytics Analytics;

	UnitState = XComGameState_Unit( EventData );

	if (UnitState.GetPreviousTeam() != eTeam_XCom) // Not XCom
		return ELR_NoInterrupt;
	if (UnitState.bMissionProvided) // Not a soldier
		return ELR_NoInterrupt;
	if (UnitState.GetMyTemplate().bIsCosmetic) // Not a soldier
		return ELR_NoInterrupt;
	if (UnitState.GetUnitValue( 'NewSpawnedUnit', UnitValue )) // spawned unit like a Ghost or Mimic Beacon
		return ELR_NoInterrupt;

	PreviousState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( UnitState.ObjectID, , GameState.HistoryIndex - 1 ) );
	if (PreviousState.HighestHP > PreviousState.LowestHP) // already taken damage
		return ELR_NoInterrupt;

	ChallengeModeManager = `CHALLENGEMODE_MGR;
	ChallengeModeManager.GetSoldierScoring( SoldierScoring );

	if (SoldierScoring.UninjuredBonus > 0)
	{
		NewGameState = class'XComGameStateContext_ChallengeScore'.static.CreateChangeState( );

		ChallengeScore = XComGameState_ChallengeScore( NewGameState.CreateStateObject( class'XComGameState_ChallengeScore' ) );
		ChallengeScore.ScoringType = CMPT_WoundedSoldier;
		ChallengeScore.AddedPoints = -SoldierScoring.UninjuredBonus;

		LadderData = XComGameState_LadderProgress( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );
		LadderData.CumulativeScore -= SoldierScoring.UninjuredBonus;

		Analytics = XComGameState_Analytics( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
		if (Analytics != none)
		{
			Analytics = XComGameState_Analytics( NewGameState.ModifyStateObject( class'XComGameState_Analytics', Analytics.ObjectID ) );
			Analytics.AddValue( "TLE_INJURIES", 1 );
		}

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitKilled(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState, UnitStateUpdated;
	local XComChallengeModeManager ChallengeModeManager;
	local ChallengeSoldierScoring SoldierScoring;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress LadderData;
	local XComGameState_ChallengeScore ChallengeScore;
	local UnitValue UnitValue;

	UnitState = XComGameState_Unit( EventData );

	if (UnitState.GetPreviousTeam() != eTeam_XCom) // Not XCom
		return ELR_NoInterrupt;
	if (UnitState.bMissionProvided) // Not a soldier
		return ELR_NoInterrupt;
	if (UnitState.GetMyTemplate().bIsCosmetic) // Not a soldier
		return ELR_NoInterrupt;
	if (UnitState.GetUnitValue( 'NewSpawnedUnit', UnitValue )) // spawned unit like a Ghost or Mimic Beacon
		return ELR_NoInterrupt;

	ChallengeModeManager = `CHALLENGEMODE_MGR;
	ChallengeModeManager.GetSoldierScoring( SoldierScoring );

	if (SoldierScoring.WoundedBonus > 0)
	{
		NewGameState = class'XComGameStateContext_ChallengeScore'.static.CreateChangeState( );

		ChallengeScore = XComGameState_ChallengeScore( NewGameState.CreateStateObject( class'XComGameState_ChallengeScore' ) );
		ChallengeScore.ScoringType = CMPT_DeadSoldier;
		ChallengeScore.AddedPoints = -SoldierScoring.WoundedBonus;

		LadderData = XComGameState_LadderProgress( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );
		LadderData.CumulativeScore -= SoldierScoring.WoundedBonus;

		if(UnitState.IsUnconscious())
		{
			// We only set this if the unit went unconscious. This helps prevent issues if a unit is not allowed to become unconscious.
			UnitStateUpdated = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitStateUpdated.SetUnitFloatValue('LadderKilledScored', 1.0, eCleanup_BeginTactical);
		}

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitUnconscious(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local StateObjectReference AbilityRef;
	local UnitValue UnitValue;

	UnitState = XComGameState_Unit(EventSource);
	AbilityRef = UnitState.FindAbility('LadderUnkillable');
	if (AbilityRef.ObjectID == 0) // Does not have the LadderUnkillable ability
		return ELR_NoInterrupt;
	if (UnitState.GetUnitValue('LadderKilledScored', UnitValue)) // Already scored as Ladder Killed (and not been revived)
		return ELR_NoInterrupt;

	return OnUnitKilled(UnitState, EventSource, GameState, Event, CallbackData);
}

function EventListenerReturn OnChallengeModeScore(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_ChallengeScore Scoring;

	foreach GameState.IterateByClassType(class'XComGameState_ChallengeScore', Scoring)
	{
		if (Scoring.LadderBonus > 0)
		{
			GameState.GetContext().PostBuildVisualizationFn.AddItem( BuildLadderBonusVis );
			return ELR_NoInterrupt;
		}
	}

	return ELR_NoInterrupt;
}

static function BuildLadderBonusVis( XComGameState VisualizeGameState )
{
	local XComGameState_ChallengeScore Scoring;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlayMessageBanner Action;
	local XGParamTag Tag;

	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_ChallengeScore', Scoring)
	{
		if (Scoring.LadderBonus <= 0)
			continue;

		if (Action == none)
		{
			ActionMetadata.StateObject_OldState = Scoring;
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
			ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer( `TACTICALRULES.GetLocalClientPlayerObjectID() );

			Action = X2Action_PlayMessageBanner( class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree( ActionMetadata, VisualizeGameState.GetContext() ) );
		}

		Tag.IntValue0 = Scoring.LadderBonus;

		Action.AddMessageBanner(	default.EarlyBirdTitle,
									,
									,
									`XEXPAND.ExpandString( default.EarlyBirdBonus ),
									eUIState_Good );
	}
}

function EventListenerReturn OnKillMail(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local int AddedPoints;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress LadderData;

	AddedPoints = class'XComGameState_ChallengeScore'.static.AddKillMail( XComGameState_Unit(EventSource), XComGameState_Unit(EventData), GameState );

	if (AddedPoints > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "LadderScoreKillMail" );
		LadderData = XComGameState_LadderProgress( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );

		LadderData.CumulativeScore += AddedPoints;

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnMissionObjectiveComplete(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local SeqAct_DisplayMissionObjective SeqActDisplayMissionObjective;
	local int AddedPoints;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress LadderData;

	SeqActDisplayMissionObjective = SeqAct_DisplayMissionObjective( EventSource );
	if (SeqActDisplayMissionObjective != none)
	{
		AddedPoints = class'XComGameState_ChallengeScore'.static.AddIndividualMissionObjectiveComplete( SeqActDisplayMissionObjective );

		if (AddedPoints > 0)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "LadderScoreObjectiveComplete" );
			LadderData = XComGameState_LadderProgress( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );

			LadderData.CumulativeScore += AddedPoints;

			`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnCivilianRescued(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local int AddedPoints;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress LadderData;

	AddedPoints = class'XComGameState_ChallengeScore'.static.AddCivilianRescued( XComGameState_Unit(EventSource), XComGameState_Unit(EventData) );

	if (AddedPoints > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "LadderScoreCivilianRescue" );
		LadderData = XComGameState_LadderProgress( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );

		LadderData.CumulativeScore += AddedPoints;

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

function FilterUpgradeTemplates( array<X2LadderUpgradeTemplate> AllTemplates, array<name> SquadMembers, int RungIndex, out array<X2LadderUpgradeTemplate> FilteredTemplates )
{
	local X2LadderUpgradeTemplate Template;
	local bool AMatch, ThisMatch;
	local Upgrade Entry;
	local name SoldierName;

	FilteredTemplates.Length = 0;

	foreach AllTemplates( Template )
	{
		if ((Template.MinLadderLevel >= 0) && (Template.MinLadderLevel > RungIndex))
			continue;

		if ((Template.MaxLadderLevel >= 0) && (Template.MaxLadderLevel < RungIndex))
			continue;

		AMatch = false;
		foreach Template.Upgrades( Entry )
		{
			if (Entry.ClassFilter == "")
				continue;

			ThisMatch = false;
			foreach SquadMembers(SoldierName)
			{
				if ( InStr( string(SoldierName), Entry.ClassFilter ) >= 0 )
				{
					AMatch = true;
					ThisMatch = true;
					break;
				}
			}

			if (Entry.Required && !ThisMatch)
			{
				AMatch = false;
				break;
			}
		}

		if (!AMatch) // at least one match is needed for this to be a valid upgrade choice
			continue;

		FilteredTemplates.AddItem( Template );
	}
}

function PopulateUpgradeProgression( )
{
	local X2LadderUpgradeTemplateManager TemplateManager;
	local X2DataTemplate Template;
	local array<X2LadderUpgradeTemplate> AllTemplates, FilteredTemplates;
	local int x, RandIdx;
	local array<name> SquadProgressionNames;

	TemplateManager = class'X2LadderUpgradeTemplateManager'.static.GetLadderUpgradeTemplateManager( );
	foreach TemplateManager.IterateTemplates( Template )
	{
		`assert( X2LadderUpgradeTemplate( Template ) != none );
		AllTemplates.AddItem( X2LadderUpgradeTemplate( Template ) );
	}

	ProgressionChoices1.Length = LadderSize - 1;
	ProgressionChoices2.Length = LadderSize - 1;

	for (x = 0; x < ProgressionChoices1.Length; ++x)
	{
		if (AllTemplates.Length < 2)
			break;

		// base the available upgrades based on what soldier we'll have on the next mission
		SquadProgressionNames = GetSquadProgressionMembers( SquadProgressionName, x + 2 );

		FilterUpgradeTemplates( AllTemplates, SquadProgressionNames, x, FilteredTemplates );

		if (FilteredTemplates.Length < 2)
			continue;

		RandIdx = `SYNC_RAND( FilteredTemplates.Length );
		ProgressionChoices1[ x ] = FilteredTemplates[ RandIdx ].DataName;
		AllTemplates.RemoveItem( FilteredTemplates[ RandIdx ] );
		FilteredTemplates.Remove( RandIdx, 1 );

		RandIdx = `SYNC_RAND( FilteredTemplates.Length );
		ProgressionChoices2[ x ] = FilteredTemplates[ RandIdx ].DataName;
		AllTemplates.RemoveItem( FilteredTemplates[ RandIdx ] );
		FilteredTemplates.Remove( RandIdx, 1 );
	}
}

function OnComplete( Name ActionName )
{
	local name Selection;

	if (ActionName == 'eUIAction_Accept')
	{
		Selection = ProgressionChoices1[ LadderRung - 1 ];
	}
	else
	{
		Selection = ProgressionChoices2[ LadderRung - 1 ];
	}

	ProgressionUpgrades.AddItem( Selection );

	`TACTICALRULES.bWaitingForMissionSummary = false;
	`PRES.UICloseLadderUpgradeScreen();
}

static function bool MaybeDoLadderProgressionChoice( )
{
	local XComGameState_LadderProgress LadderData;

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));

	// not playing a ladder, skip this UI
	if (LadderData == none)
		return false;

	// don't do an upgrade choice for completing the last mission
	if (LadderData.LadderRung == LadderData.LadderSize)
		return false;

	// if we don't have a choice available for either track, skip the UI
	if ((LadderData.ProgressionChoices1.Length < LadderData.LadderRung) ||
		(LadderData.ProgressionChoices2.Length < LadderData.LadderRung))
		return false;

	// if either track wasn't configured with a choice, skip the UI
	if ((LadderData.ProgressionChoices1[LadderData.LadderRung - 1] == 'none') ||
		(LadderData.ProgressionChoices2[LadderData.LadderRung - 1] == 'none'))
		return false;

	`PRES.UIRaiseLadderUpgradeScreen();
	return true;
}

static function bool MaybeDoLadderSoliderScreen( )
{
	local XComGameState_LadderProgress LadderData;

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));

	// not playing a ladder, skip this UI
	if (LadderData == none)
		return false;

	if (LadderData.LadderRung == LadderData.LadderSize+1)
	{
		// TODO: Show a ladder completed UI instead? (if we do, return true instead of false)
		return false;
	}

	`PRES.UIRaiseLadderSoldierScreen();
	return true;
}

static function bool MaybeDoLadderMedalScreen()
{
	local XComGameState_LadderProgress LadderData;

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));

	// not playing a ladder, skip this UI
	if (LadderData == none)
		return false;

	if (LadderData.bRandomLadder) // don't show during procedural ladders
		return false;

	// show the right medal screen for where we are in the ladder
	if (LadderData.LadderRung == LadderData.LadderSize+1)
	{
		// don't show if we didn't even make Bronze.
		if (LadderData.CumulativeScore < LadderData.MedalThresholds[0] )
		{
			return false;
		}

		`PRES.UIRaiseLadderMedalScreen();
	}
	else
		`PRES.UITLELadderMedalProgressScreen();

	return true;
}

static function bool MaybeDoLadderEndScreen()
{
	local XComGameState_LadderProgress LadderData;

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));

	// not playing a ladder, skip this UI
	if (LadderData == none)
		return false;

	if (LadderData.LadderRung < LadderData.LadderSize+1)
	{
		return false;
	}

	`PRES.UIRaiseLadderEndScreen();
	return true;
}

static function name SelectQuestItem( string MissionType )
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2DataTemplate DataTemplate;
	local X2QuestItemTemplate QuestItemDataTemplate;
	local array<X2QuestItemTemplate> ValidQuestItemTemplates;
	local int RandIdx;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// collect all quest item templates that are valid for this mission/source/reward combo
	foreach ItemTemplateManager.IterateTemplates(DataTemplate, none)
	{
		QuestItemDataTemplate = X2QuestItemTemplate(DataTemplate);
		if (QuestItemDataTemplate == none) continue;

		if (QuestItemDataTemplate.MissionType.Length > 0 && QuestItemDataTemplate.MissionType.Find(MissionType) == INDEX_NONE)
		{
			continue;
		}

		ValidQuestItemTemplates.AddItem( QuestItemDataTemplate );
	};

	if (ValidQuestItemTemplates.Length == 0)
		return '';

	RandIdx = `SYNC_RAND_STATIC( ValidQuestItemTemplates.Length );

	return ValidQuestItemTemplates[ RandIdx ].DataName;
}

function PopulateFromNarrativeConfig( )
{
	local NarrativeLadder Entry;

	foreach NarrativeLadderConfig( Entry )
	{
		if (Entry.LadderIndex == LadderIndex)
		{
			ProgressionChoices1 = Entry.Choices1;
			ProgressionChoices2 = Entry.Choices2;

			LoadingScreenAkEvents = Entry.LoadingAkEvents;
			LootSelectNarrative = Entry.LootNarratives;

			MedalThresholds = Entry.MedalThresholds;

			break;
		}
	}
}

static function int GetLadderMedalThreshold( int InLadderIndex, int MedalIndex )
{
	local NarrativeLadder Entry;

	foreach default.NarrativeLadderConfig( Entry )
	{
		if ((Entry.LadderIndex == InLadderIndex) && (Entry.MedalThresholds.Length > MedalIndex))
		{
			return Entry.MedalThresholds[ MedalIndex ];
		}
	}

	return -1;
}

function string GetBackgroundPath( optional int RungModifier = 0 )
{
	local NarrativeLadder Entry;

	foreach default.NarrativeLadderConfig( Entry )
	{
		if ((Entry.LadderIndex == LadderIndex) && (Entry.BackgroundPaths.Length >= (LadderRung + RungModifier)))
		{
			return Entry.BackgroundPaths[ (LadderRung + RungModifier) - 1 ];
		}
	}

	return "";
}

function string GetLadderCompletionUnlockImagePath( )
{
	local NarrativeLadder Entry;

	foreach default.NarrativeLadderConfig( Entry )
	{
		if (Entry.LadderIndex == LadderIndex)
		{
			return Entry.CompletionUnlockImage;
		}
	}

	return "";
}

static function array<name> GetSquadProgressionMembers( string ProgressionName, int Rung )
{
	local SquadProgression Progression;
	local array<name> Members;

	foreach default.SquadProgressions( Progression )
	{
		if (Progression.SquadName != ProgressionName)
			continue;

		Members = Progression.Progression[ Rung - 1 ].Members;
		break;
	}

	return Members;
}

static function name GetNarrativeSquadName( int LadderIdx, int Rung )
{
	local NarrativeLadder Entry;

	foreach default.NarrativeLadderConfig( Entry )
	{
		if (Entry.LadderIndex == LadderIdx)
		{
			return Entry.SquadProgression[ Rung - 1 ];
		}
	}

	return '';
}

function bool IsFixedNarrativeUnit(XComGameState_Unit UnitState)
{
	local int i;
	local string LastName;

	if (LadderIndex >= 10) return false;

	LastName = UnitState.GetLastName();
	for (i = 0; i < FixedNarrativeUnits[LadderIndex - 1].LastNames.length; ++i)
	{
		if (LastName == FixedNarrativeUnits[LadderIndex - 1].LastNames[i])
		{
			return true;
		}
	}

	return false;
}

defaultproperties
{
	bNewLadder = false
	LadderName="Missing Ladder Name"

	FixedNarrativeUnits(0) = (LastNames=("Rojas", "Bradford", "Zeng", "Rutherford"))
	FixedNarrativeUnits(1) = (LastNames=("Bedi", "Bradford", "Campbell", "Lewis"))
	FixedNarrativeUnits(2) = (LastNames=("Shen", "Cohen", "Barta", "Marvez"))
	FixedNarrativeUnits(3) = (LastNames=("Bradford", "Sokolov", "Eze"))
}