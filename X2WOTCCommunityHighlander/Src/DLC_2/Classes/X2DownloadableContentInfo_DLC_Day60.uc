//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo_DLC_Day60.uc
//  AUTHOR:  Ryan McFall
//           
//	Installs Day 60 DLC into new campaigns and loaded ones. New armors, weapons, etc
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_DLC_Day60 extends X2DownloadableContentInfo;

var config array<name> DLCTechs;
var config array<name> DLCPointsOfInterest;
var config array<name> DLCObjectives;

var config name DLCAlwaysStartObjective;
var config name DLCOptionalNarrativeObjective;
var config name DLCNoNarrativeObjective;

var config name ArmoryUpgradeName;
var config name HunterWeaponsPOIName;
var config name AlienNestPOIName;
var config int AlienNestPOIForceLevel; // The Alien Nest POI should be placed as the mission reward for the last mission BEFORE this force level is hit

var localized string m_strRulerPresentOnMission;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	InitializeManagers();
}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{
	local XComGameState_AlienRulerManager RulerMgr;

	InitializeManagers(); // Make sure manager classes are initialized

	RulerMgr = XComGameState_AlienRulerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));

	// If the content check for this DLC has not yet been performed, ask the player whether or not it should be enabled for their campaign
	if (!RulerMgr.bContentCheckCompleted)
	{
		EnableDLCContentPopup();
	}
}

static function InitializeManagers()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_HuntersLodgeManager LodgeManager;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Day 60 DLC State Objects");

	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager', true));
	if (RulerMgr == none) // Prevent duplicate Ruler Managers
	{
		// Add the manager class
		RulerMgr = XComGameState_AlienRulerManager(NewGameState.CreateNewStateObject(class'XComGameState_AlienRulerManager'));
	}

	LodgeManager = XComGameState_HuntersLodgeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_HuntersLodgeManager', true));
	if (LodgeManager == none) // Prevent duplicate Lodge Managers
	{
		// Add Hunter's Lodge manager
		LodgeManager = XComGameState_HuntersLodgeManager(NewGameState.CreateNewStateObject(class'XComGameState_HuntersLodgeManager'));
		LodgeManager.CalcKillCount(NewGameState);
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function AddNewTechGameStates(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager TechMgr;
	local X2TechTemplate TechTemplate;
	local int idx;

	TechMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// Iterate through the DLC Techs, find their templates, and build a Tech State Object for each
	for (idx = 0; idx < default.DLCTechs.Length; idx++)
	{
		TechTemplate = X2TechTemplate(TechMgr.FindStrategyElementTemplate(default.DLCTechs[idx]));
		if (TechTemplate != none)
		{
			if (TechTemplate.RewardDeck != '')
			{
				class'XComGameState_Tech'.static.SetUpTechRewardDeck(TechTemplate);
			}

			NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate);
		}
	}
}

static function AddNewObjectiveGameStates(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager ObjMgr;
	local XComGameState_Objective ObjectiveState;
	local X2ObjectiveTemplate ObjectiveTemplate;
	local int idx;

	ObjMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// Iterate through the DLC Objectives, find their templates, and build and activate the Objective State Object for each
	for (idx = 0; idx < default.DLCObjectives.Length; idx++)
	{
		ObjectiveTemplate = X2ObjectiveTemplate(ObjMgr.FindStrategyElementTemplate(default.DLCObjectives[idx]));
		if (ObjectiveTemplate != none)
		{
			ObjectiveState = ObjectiveTemplate.CreateInstanceFromTemplate(NewGameState);
		}

		// Start the main DLC objective.
		if (ObjectiveState.GetMyTemplateName() == default.DLCAlwaysStartObjective)
		{
			ObjectiveState.StartObjective(NewGameState);
		}

		// This is always called from a saved game installation of DLC, so narrative is never enabled
		if (ObjectiveState.GetMyTemplateName() == default.DLCNoNarrativeObjective)
		{
			ObjectiveState.StartObjective(NewGameState);
		}
	}
}

static function AddAchievementTriggers(Object TriggerObj)
{
	local X2EventManager EventManager;

	// Set up triggers for achievements
	EventManager = `XEVENTMGR;
	EventManager.RegisterForEvent(TriggerObj, 'TacticalGameEnd', class'X2AchievementTracker_DLC_Day60'.static.OnTacticalGameEnd, ELD_OnStateSubmitted, 50, , true);
	EventManager.RegisterForEvent(TriggerObj, 'UnitDied', class'X2AchievementTracker_DLC_Day60'.static.OnUnitDied, ELD_OnStateSubmitted, 50, , true);
	EventManager.RegisterForEvent(TriggerObj, 'ItemConstructionCompleted', class'X2AchievementTracker_DLC_Day60'.static.OnItemConstructed, ELD_OnStateSubmitted, 50, , true);
	EventManager.RegisterForEvent(TriggerObj, 'RulerArmorAbilityActivated', class'X2AchievementTracker_DLC_Day60'.static.OnRulerArmorAbilityActivated, ELD_OnStateSubmitted, 50, , true);
}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_HuntersLodgeManager LodgeManager;
	local XComGameState_CampaignSettings CampaignSettings;
	local XComGameState_Objective ObjectiveState;
	
	foreach StartState.IterateByClassType(class'XComGameState_CampaignSettings', CampaignSettings)
	{
		break;
	}

	// Add the alien ruler manager class
	RulerMgr = XComGameState_AlienRulerManager(StartState.CreateNewStateObject(class'XComGameState_AlienRulerManager'));
	RulerMgr.SetUpRulers(StartState);
	RulerMgr.bContentCheckCompleted = true; // No need to ask the player about enabling new content on new games
	RulerMgr.bContentActivated = true;
	AddAchievementTriggers(RulerMgr);

	// Add Hunter's Lodge manager
	LodgeManager = XComGameState_HuntersLodgeManager(StartState.CreateNewStateObject(class'XComGameState_HuntersLodgeManager'));
	LodgeManager.CalcKillCount(StartState);

	// Setup Narrative mission/objectives based on content enable
	foreach StartState.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if (CampaignSettings.HasOptionalNarrativeDLCEnabled(name(default.DLCIdentifier)))
		{
			if (ObjectiveState.GetMyTemplateName() == default.DLCOptionalNarrativeObjective)
			{
				ObjectiveState.StartObjective(StartState);
				break;
			}
		}
		else
		{
			if (ObjectiveState.GetMyTemplateName() == default.DLCNoNarrativeObjective)
			{
				ObjectiveState.StartObjective(StartState);
				break;
			}
		}
	}
}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// </summary>
static event OnPreMission(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_MissionCalendar CalendarState;
	local XComGameState_CampaignSettings CampaignSettings;
	local XComGameState_AlienRulerManager RulerMgr;
	local StateObjectReference POIRef;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
	CampaignSettings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	
	if (RulerMgr.bContentActivated)
	{
		// Update the Alien Rulers
		class'XComGameState_AlienRulerManager'.static.PreMissionUpdate(NewGameState, MissionState);

		// Only attempt to replace POIs if the player has Narrative content enabled for this DLC, and this mission would have spawned a POI
		// and the tutorial is completed (or not enabled)
		if (CampaignSettings.HasOptionalNarrativeDLCEnabled(name(default.DLCIdentifier)) && MissionState.POIToSpawn.ObjectID != 0 && 
			XComHQ.IsObjectiveCompleted('T0_M10_IntroToBlacksite'))
		{
			foreach History.IterateByClassType(class'XComGameState_PointOfInterest', POIState)
			{
				POIRef = POIState.GetReference();

				// Always looking for an unactivated POI which has never been spawned before, since each of these are unique one-time spawns
				if (ResHQ.ActivePOIs.Find('ObjectID', POIRef.ObjectID) == INDEX_NONE && POIState.NumSpawns < 1)
				{
					// Try to spawn the Hunter Weapons POI.
					if (POIState.GetMyTemplateName() == default.HunterWeaponsPOIName)
					{
						// Deactivate the POI which was going to be spawned so it can be used again
						ResHQ.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
						ResHQ.ActivatePOI(NewGameState, POIRef);
						MissionState.POIToSpawn = POIRef;
						break; // Break so that this POI is not replaced by Alien Nest.
					}

					// Try to spawn the Alien Nest POI if the next mission (after the current one) will be at the next force level,
					// and that next force level is the one where the Alien Nest POI should appear
					if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('DLC_HunterWeapons') &&
						class'X2StrategyGameRulesetDataStructures'.static.LessThan(AlienHQ.ForceLevelIntervalEndTime, CalendarState.CurrentMissionMonth[0].SpawnDate)
						&& (AlienHQ.GetForceLevel() + 1) >= default.AlienNestPOIForceLevel && POIState.GetMyTemplateName() == default.AlienNestPOIName)
					{
						// Deactivate the POI which was going to be spawned so it can be used again
						ResHQ.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
						ResHQ.ActivatePOI(NewGameState, POIRef);
						MissionState.POIToSpawn = POIRef;
						// We don't break here to allow this POI to be overwritten by Hunter Weapons
					}
				}
			}
		}
	}
}

/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
static event OnPostMission()
{
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;

	InitializeManagers(); // Make sure manager classes are initialized
	
	RulerMgr = XComGameState_AlienRulerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));

	if (RulerMgr.bContentActivated)
	{
		// Update the Alien Rulers
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("DLC 60 On Post Mission");
		class'XComGameState_AlienRulerManager'.static.PostMissionUpdate(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
static event OnExitPostMissionSequence()
{
	local XComGameState_AlienRulerManager RulerMgr;
	
	// Ruler Manager should always exist here, because OnPostMission is called before OnExitPostMissionSequence, and InitializeManagers is called there
	RulerMgr = XComGameState_AlienRulerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));

	// If the content check for this DLC has not yet been performed, ask the player whether or not it should be enabled for their campaign
	if (!RulerMgr.bContentCheckCompleted)
	{
		EnableDLCContentPopup();
	}
}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	class'X2Helpers_DLC_Day60'.static.OnPostAbilityTemplatesCreated();
	class'X2Helpers_DLC_Day60'.static.OnPostTechTemplatesCreated();
	class'X2Helpers_DLC_Day60'.static.OnPostCharacterTemplatesCreated();
}

/// <summary>
/// Called when the difficulty changes and this DLC is active
/// </summary>
static event OnDifficultyChanged()
{
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;

	InitializeManagers(); // Make sure manager classes are initialized

	RulerMgr = XComGameState_AlienRulerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Alien Hunters Change Difficulty");
	RulerMgr.UpdateRulerStatsForDifficulty(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}


/// <summary>
/// Called by the Geoscape tick
/// </summary>
static event UpdateDLC()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local UIStrategyMap StrategyMap;
	local bool bUpdated;

	if (class'X2Helpers_DLC_Day60'.static.IsXPackIntegrationEnabled())
	{
		History = `XCOMHISTORY;
		StrategyMap = `HQPRES.StrategyMap2D;
		RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
		
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Alien Hunters DLC");
		RulerMgr = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerMgr.ObjectID));
		
		// Don't trigger updates while the Avenger or Skyranger are flying, or if another popup is already being presented
		if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
		{
			bUpdated = RulerMgr.ActivateRulerLocations(); // Check for any new rulers getting activated, and set their timers
			bUpdated = bUpdated || RulerMgr.UpdateRulerLocations();
		}
		
		if (bUpdated)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			RulerMgr.DisplayRulerPopup(); // Check to see if any new popups need to be displayed
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}
}

simulated function EnableDLCContentPopupCallback_Ex(Name eAction)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_CampaignSettings CampaignSettings;

	super.EnableDLCContentPopupCallback_Ex(eAction);

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	CampaignSettings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Callback Enable Alien Rulers Content");

	// If enabling DLC content from this popup, it is from a loaded save where the DLC wasn't previously installed
	// So if narrative content was somehow enabled, it should be turned off
	if(CampaignSettings.HasOptionalNarrativeDLCEnabled(name(default.DLCIdentifier)))
	{
		CampaignSettings = XComGameState_CampaignSettings(NewGameState.ModifyStateObject(class'XComGameState_CampaignSettings', CampaignSettings.ObjectID));
		CampaignSettings.RemoveOptionalNarrativeDLC(name(default.DLCIdentifier));
	}

	RulerMgr = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerMgr.ObjectID));
	RulerMgr.bContentCheckCompleted = true;

	if (eAction == 'eUIAction_Accept')
	{
		// Content accepted, initiate activation sequence!
		RulerMgr.bContentActivated = true;
		RulerMgr.SetUpRulers(NewGameState);
		AddNewTechGameStates(NewGameState);
		AddNewObjectiveGameStates(NewGameState);
		AddAchievementTriggers(RulerMgr);
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/// <summary>
/// Called when viewing mission blades, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool ShouldUpdateMissionSpawningInfo(StateObjectReference MissionRef)
{
	local XComGameState_MissionSite MissionState;

	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionRef.ObjectID));
	if (MissionState.Source == 'MissionSource_AlienNetwork')
	{
		// Force a schedule update when alien facilities are selected, since rulers can be located there
		return true;
	}
}

/// <summary>
/// Called when viewing mission blades, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool UpdateMissionSpawningInfo(StateObjectReference MissionRef)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local array<name> OldTacticalTags;
	local int idx, i, EncounterIndex;
	local bool bMatching;
	local XComGameState_Unit UnitState;
	local XComTacticalMissionManager MissionMgr;
	local array<name> RulerNames;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Callback Enable Alien Rulers Content");
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerMgr = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerMgr.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(MissionRef.ObjectID));

	// Store old tactical tags for comparison, remove dupes
	for(idx = 0; idx < XComHQ.TacticalGameplayTags.Length; idx++)
	{
		if(OldTacticalTags.Find(XComHQ.TacticalGameplayTags[idx]) == INDEX_NONE)
		{
			OldTacticalTags.AddItem(XComHQ.TacticalGameplayTags[idx]);
		}
	}

	OldTacticalTags.Sort(SortTacticalTags);
	XComHQ.TacticalGameplayTags = OldTacticalTags;

	// Update Spawning data and tags
	RulerMgr.UpdateRulerSpawningData(NewGameState, MissionState);
	XComHQ.TacticalGameplayTags.Sort(SortTacticalTags);

	// Check if ruler is in encounter groups when they're not supposed to be (for concurrent missions)
	if(RulerMgr.RulerOnCurrentMission.ObjectID == 0)
	{
		MissionMgr = `TACTICALMISSIONMGR;

		// Grab Ruler Names
		for(idx = 0; idx < RulerMgr.AllAlienRulers.Length; idx++)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RulerMgr.AllAlienRulers[idx].ObjectID));

			if(UnitState != none)
			{
				RulerNames.AddItem(UnitState.GetMyTemplateName());
			}
		}

		// Check if selected encounters contain a ruler
		for(idx = 0; idx < MissionState.SelectedMissionData.SelectedEncounters.Length; idx++)
		{
			EncounterIndex = MissionMgr.ConfigurableEncounters.Find('EncounterID', MissionState.SelectedMissionData.SelectedEncounters[idx].SelectedEncounterName);

			if(EncounterIndex != INDEX_NONE)
			{
				for(i = 0; i < RulerNames.Length; i++)
				{
					if(MissionMgr.ConfigurableEncounters[EncounterIndex].ForceSpawnTemplateNames.Find(RulerNames[i]) != INDEX_NONE)
					{
						// Ruler is in encounter even though none is set by Ruler Manager
						`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
						return true;
					}
				}
			}
		}
	}

	// Compare new tactical tags with old ones
	if(XComHQ.TacticalGameplayTags.Length == OldTacticalTags.Length)
	{
		bMatching = true;

		for(idx = 0; idx < OldTacticalTags.Length; idx++)
		{
			if(XComHQ.TacticalGameplayTags[idx] != OldTacticalTags[idx])
			{
				bMatching = false;
				break;
			}
		}

		if(bMatching)
		{
			History.CleanupPendingGameState(NewGameState);
			return false;
		}
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return true;
}

private function int SortTacticalTags(name NameA, name NameB)
{
	local string StringA, StringB;

	StringA = string(NameA);
	StringB = string(NameB);

	if (StringA < StringB)
	{
		return 1;
	}
	else if (StringA > StringB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

/// <summary>
/// Called when viewing mission blades, used to add any additional text to the mission description
/// </summary>
static function string GetAdditionalMissionDesc(StateObjectReference MissionRef)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local XComGameState_AlienRulerManager RulerMgr;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(MissionRef.ObjectID));
	if (MissionState.Source == 'MissionSource_AlienNetwork' && RulerMgr.AlienRulerLocations.Find('MissionRef', MissionRef) != INDEX_NONE)
	{
		return class'UIUtilities_Text'.static.GetColoredText(default.m_strRulerPresentOnMission, eUIState_Warning);
	}
}

/// <summary>
/// Calls DLC specific popup handlers to route messages to correct display functions
/// </summary>
static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	if (PropertySet.PrimaryRoutingKey == 'UIAlert_DLC_Day60')
	{
		CallUIAlert_DLC_Day60(PropertySet);
		return true;
	}

	return false;
}

static function CallUIAlert_DLC_Day60(const out DynamicPropertySet PropertySet)
{
	local XComHQPresentationLayer Pres;
	local UIAlert_DLC_Day60 Alert;

	Pres = `HQPRES;

	Alert = Pres.Spawn(class'UIAlert_DLC_Day60', Pres);
	Alert.DisplayPropertySet = PropertySet;
	Alert.eAlertName = PropertySet.SecondaryRoutingKey;

	Pres.ScreenStack.Push(Alert);
}

/// <summary>
/// Called after HeadquartersAlien builds a Facility
/// </summary>
static event OnPostAlienFacilityCreated(XComGameState NewGameState, StateObjectReference NewFacilityRef)
{
	local XComGameState_AlienRulerManager RulerMgr;

	RulerMgr = XComGameState_AlienRulerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerMgr = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerMgr.ObjectID));	
	RulerMgr.PlaceRulerAtLocation(NewFacilityRef); // Attempt to place a ruler at the new facility location
}

/// <summary>
/// Called after a new Alien Facility's doom generation display is completed
/// </summary>
static event OnPostFacilityDoomVisualization()
{
	local XComGameState_AlienRulerManager RulerMgr;

	RulerMgr = XComGameState_AlienRulerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerMgr.DisplayRulerPopup();
}


//---------------------------------------------------------------------------------------
//-------------------------------- DLC CHEATS -------------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
// For TQL Testing of Alien Rulers
// WARNING: DON'T USE IN STRATEGY
exec function InitAlienRulerManager()
{
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: InitAlienRulerManager");
	RulerMgr = XComGameState_AlienRulerManager(NewGameState.CreateNewStateObject(class'XComGameState_AlienRulerManager'));
	RulerMgr.CreateAlienRulers(NewGameState);
	RulerMgr.ActiveAlienRulers = RulerMgr.AllAlienRulers;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	SetRulerNumAppearances('ViperKing', 1);
	SetRulerNumAppearances('BerserkerQueen', 1);
	SetRulerNumAppearances('ArchonKing', 1);

	AddAchievementTriggers(RulerMgr);
}

//---------------------------------------------------------------------------------------
exec function ForceRulerOnNextMission(name RulerTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local StateObjectReference RulerRef;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(RulerTemplateName);

	if(RulerRef.ObjectID != 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: ForceRulerOnNextMission");
		RulerMgr = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerMgr.ObjectID));
		RulerMgr.ForcedRulerOnNextMission = RulerRef;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`log("RulerTemplateName is invalid.\nValid Entries: ViperKing, BerserkerQueen, ArchonKing");
	}
}

//---------------------------------------------------------------------------------------
exec function SetRulerNumAppearances(name RulerTemplateName, int Count)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit UnitState;
	local StateObjectReference RulerRef;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(RulerTemplateName);

	if(RulerRef.ObjectID != 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetRulerNumAppearances");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RulerRef.ObjectID));
		UnitState.SetUnitFloatValue('NumAppearances', float(Count), eCleanup_Never);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`log("RulerTemplateName is invalid.\nValid Entries: ViperKing, BerserkerQueen, ArchonKing");
	}
}

//---------------------------------------------------------------------------------------
exec function PrintRulerNumAppearances(name RulerTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit UnitState;
	local StateObjectReference RulerRef;
	local UnitValue AppearanceValue;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(RulerTemplateName);

	if(RulerRef.ObjectID != 0)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RulerRef.ObjectID));
		UnitState.GetUnitValue('NumAppearances', AppearanceValue);
		`log(string(RulerTemplateName) @ "Appearances:" @ int(AppearanceValue.fValue));
	}
	else
	{
		`log("RulerTemplateName is invalid.\nValid Entries: ViperKing, BerserkerQueen, ArchonKing");
	}
}

//---------------------------------------------------------------------------------------
exec function SetRulerNumEscapes(name RulerTemplateName, int Count)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit UnitState;
	local StateObjectReference RulerRef;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(RulerTemplateName);

	if(RulerRef.ObjectID != 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetRulerNumAppearances");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RulerRef.ObjectID));
		UnitState.SetUnitFloatValue('NumEscapes', float(Count), eCleanup_Never);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`log("RulerTemplateName is invalid.\nValid Entries: ViperKing, BerserkerQueen, ArchonKing");
	}
}

//---------------------------------------------------------------------------------------
exec function PrintRulerNumEscapes(name RulerTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit UnitState;
	local StateObjectReference RulerRef;
	local UnitValue EscapeValue;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(RulerTemplateName);

	if(RulerRef.ObjectID != 0)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RulerRef.ObjectID));
		UnitState.GetUnitValue('NumEscapes', EscapeValue);
		`log(string(RulerTemplateName) @ "Escapes:" @ int(EscapeValue.fValue));
	}
	else
	{
		`log("RulerTemplateName is invalid.\nValid Entries: ViperKing, BerserkerQueen, ArchonKing");
	}
}

//---------------------------------------------------------------------------------------
exec function SetRulerEscapeHealth(name RulerTemplateName, int Health)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit UnitState;
	local StateObjectReference RulerRef;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(RulerTemplateName);

	if (RulerRef.ObjectID != 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetRulerEscapeHealth");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RulerRef.ObjectID));
		UnitState.SetUnitFloatValue('EscapeHealth', float(Health), eCleanup_Never);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`log("RulerTemplateName is invalid.\nValid Entries: ViperKing, BerserkerQueen, ArchonKing");
	}
}

//---------------------------------------------------------------------------------------
exec function PrintRulerEscapeHealth(name RulerTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit UnitState;
	local StateObjectReference RulerRef;
	local UnitValue EscapeValue;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(RulerTemplateName);

	if (RulerRef.ObjectID != 0)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RulerRef.ObjectID));
		UnitState.GetUnitValue('EscapeHealth', EscapeValue);
		`log(string(RulerTemplateName) @ "Escape Health:" @ int(EscapeValue.fValue));
	}
	else
	{
		`log("RulerTemplateName is invalid.\nValid Entries: ViperKing, BerserkerQueen, ArchonKing");
	}
}

//---------------------------------------------------------------------------------------
// Call in strategy to add Central as a normal soldier to your crew
exec function AddNestCentralToCrew()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if(UnitState.GetMyTemplateName() == 'NestCentral')
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: AddNestCentralToCrew");
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.AddToCrew(NewGameState, UnitState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
// Call in strategy to display debug numbers in the Hunters Lodge
exec function ToggleHuntersLodgeDebug()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HuntersLodgeManager LodgeManager;
	
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Toggle Hunters Lodge Debug Numbers");
	
	LodgeManager = XComGameState_HuntersLodgeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_HuntersLodgeManager', true));
	if (LodgeManager != none)
	{
		LodgeManager = XComGameState_HuntersLodgeManager(NewGameState.CreateNewStateObject(class'XComGameState_HuntersLodgeManager'));
		LodgeManager.bDebugVis = !LodgeManager.bDebugVis;
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}