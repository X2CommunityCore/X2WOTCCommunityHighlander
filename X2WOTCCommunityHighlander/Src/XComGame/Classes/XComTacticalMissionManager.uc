class XComTacticalMissionManager extends Object
	native(Core)
	dependson(X2StrategyGameRulesetDataStructures)
	config(Missions);

enum EObjectivePieceType
{
	eObjectivePieceType_TriggerVolume,
	eObjectivePieceType_ExitVolume,
	eObjectivePieceType_Pawn,
	eObjectivePieceType_Interact,
	eObjectivePieceType_See,
};

struct native ObjectiveSpawnArchetype
{
	var string ArchetypePath; // full path name of the archetype to spawn
	var int MinForceLevel; // minimum force level at which to spawn this archetype
	var int MaxForceLevel; // maximum force level at which to spawn this archetype
	
	structdefaultproperties
	{
		MinForceLevel = -1
		MaxForceLevel = -1
	}
};

struct native ObjectiveSpawnInfo
{
	var string							sMissionType;
	var bool							bUseObjectiveLocation;
	var int								iMinObjectives;
	var int								iMaxObjectives;
	var int								iMinTilesBetweenObjectives;
	var int								iMinTilesFromObjectiveCenter;
	var int								iMaxTilesFromObjectiveCenter;
	var bool							bCanSpawnOutsideObjectiveParcel;

	var array<ObjectiveSpawnArchetype>  ARCToSpawn; // List of potential archetypes to spawn for this objective
	var name							DefaultVIPTemplate; // in TQL or in cases where strategy fails to provide a pawn, what kind of VIP should this mission spawn?
	var bool							bReplaceSwapActor; // if false, will convert an OSPs swap actor to the selected archetype instead of replacing it

	var bool							SpawnVIPWithXComSquad; // if true, will spawn the first reward unit with the xcom squad in addition to whatever objectives are spawned

	structdefaultproperties
	{
		iMinTilesBetweenObjectives = 0
		iMinTilesFromObjectiveCenter = 0
		iMaxTilesFromObjectiveCenter = 10000
		iMinObjectives = 1
		iMaxObjectives = 1
		bReplaceSwapActor = true
	}
};

struct native MissionSourceRewardMapping
{
	var name                    MissionSource;
	var name                    RewardType;
	var string					MissionFamily;
	var bool					XPackMissionSource;
};

// allows designers and artists to have reward units spawn in as a different kind of 
// unit. If the original unit's template is found in the mapping array, the proxy template 
// will spawn in tactical instead. Otherwise, we spawn the original unit
struct native ProxyRewardUnitTemplateMapping
{
	var name OriginalTemplate;
	var name ProxyTemplate;
};

struct native AdditionalMissionIntroPackageMapping
{
	var string OriginalIntroMatineePackage; // original matinee package in the MissionIntroDefinition structure for a mission
	var string AdditionalIntroMatineePackage; // additional matinee package to load when OriginalIntroMatineePackage is loaded
};

struct native ChosenSpawningTagToEncounterIDInformation
{
	var name SpawningTag;
	var name EncounterID;
};

// config information
// Start Issue #101 - allow runtime modification of config
var config array<ProxyRewardUnitTemplateMapping> ProxyRewardUnitMappings;
var config array<string> arrTMissionTypes;
var config(EncounterLists) array<SpawnDistributionList> SpawnDistributionLists;
var config(Encounters) array<ConfigurableEncounter> ConfigurableEncounters;
var config(Encounters) array<EncounterBucket> EncounterBuckets;
var config(Schedules) array<MissionSchedule> MissionSchedules;
var config(MissionDefs) array<MissionDefinition> arrMissions;
var config(MissionSources) array<MissionSourceRewardMapping> arrSourceRewardMissionTypes;
var config(MissionDefs) array<ObjectiveSpawnInfo> arrObjectiveSpawnInfo;
var config array<PlotLootDefinition> arrPlotLootDefinitions;
var config(MissionSources) array<string> VIPMissionFamilies;
var config MissionIntroDefinition DefaultMissionIntroDefinition;
var config array<AdditionalMissionIntroPackageMapping> AdditionalMissionIntroPackages; // for modding, allows packages with intros for new character types to be loaded
var config array<ChosenSpawningTagToEncounterIDInformation> ChosenSpawnTagToEncounterID;

//Used to allow mods to alias themselves to an existing mission type ( baked into shipping maps )
struct native MissionTypeAliasEntry
{
	var string KeyMissionType; //New mission type that should alias to a base game type
	var array<string> AltMissionTypes; //List of base game types that are supported
};
var config array<MissionTypeAliasEntry> arrMissionTypeAliases;
// End Issue #101

// runtime data
var MissionDefinition ForceMission; // Way to force this mission
var MissionDefinition ActiveMission;
var name MissionQuestItemTemplate;

// The index into the active mission of the MissionSchedule to use
var private{private} int ActiveMissionScheduleIndex;

var bool bBlockingLoadParcels;

var private bool HasCachedCards; // Allows us to only cache the deck cards once per run
var private bool HasCombinedSpawnDistributionLists;

var private transient Name LastSelectedRewardName;
var private transient bool BuildingChallengeMission;

var config array<Name> CharactersExcludedFromEvacZoneCounts;

//bsg-mfawcett(08.22.16): resets our cached card variable allowing us to re-add all necessary cards. Used when starting a new campaign (fixes issues when first going to MP then back to SP).
function ResetCachedCards()
{
	HasCachedCards = false;
}

// Issue #528 - allow mods to call this function
/*private*/ function CacheMissionManagerCards()
{
	local X2CardManager CardManager;
	local MissionDefinition MissionDef;
	local X2DataTemplate DataTemplate;
	local X2QuestItemTemplate QuestItemDataTemplate;
	local MissionSchedule MissionScheduleRef;
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate HackRewardTemplate;
	local string MissionFamily;
	local float CardWeight;

	if (HasCachedCards)
	{
		return;
	}

	CardManager = class'X2CardManager'.static.GetCardManager();

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

	foreach HackRewardTemplateManager.IterateTemplates(DataTemplate, None)
	{
		HackRewardTemplate = X2HackRewardTemplate(DataTemplate);

		if( HackRewardTemplate.MaxIntelCost > 0 )
		{
			if (HackRewardTemplate.bGuaranteedIntelReward)
				CardManager.AddCardToDeck('GuaranteedIntelPurchasedHackRewards', string(HackRewardTemplate.DataName));
			else
				CardManager.AddCardToDeck('IntelPurchasedHackRewards', string(HackRewardTemplate.DataName));
		}

		if( HackRewardTemplate.bIsNegativeTacticalReward )
		{
			CardManager.AddCardToDeck('NegativeTacticalHackRewards', string(HackRewardTemplate.DataName));
		}

		if( HackRewardTemplate.bIsNegativeStrategyReward )
		{
			CardManager.AddCardToDeck('NegativeStrategyHackRewards', string(HackRewardTemplate.DataName));
		}

		if( HackRewardTemplate.bIsTier1Reward || HackRewardTemplate.bIsTier2Reward )
		{
			if( HackRewardTemplate.bIsStrategyReward )
			{
				CardManager.AddCardToDeck('StrategyHackRewards', string(HackRewardTemplate.DataName));
			}

			if( HackRewardTemplate.bIsTacticalReward )
			{
				CardManager.AddCardToDeck('TacticalHackRewards', string(HackRewardTemplate.DataName));
			}
		}
	}

	foreach MissionSchedules(MissionScheduleRef)
	{
		CardManager.AddCardToDeck('MissionSchedules', string(MissionScheduleRef.ScheduleID));
	}

	// add all of the mission families to the card manager. Missions without families are their own family
	foreach arrMissions(MissionDef)
	{
		MissionFamily = MissionDef.MissionFamily;
		CardWeight = 1.0f;

		if(MissionFamily == "")
		{
			MissionFamily = MissionDef.sType;
		}

		if(MissionFamilyIsXPack(MissionFamily))
		{
			CardWeight = 2.0f;
		}

		CardManager.AddCardToDeck('MissionFamilies', MissionFamily, CardWeight);
		
		// also add the raw mission type
		CardManager.AddCardToDeck('MissionTypes', MissionDef.sType);
	}

	// add all quest items to the card manager. Since they are just cosmetic sugar, we can use them
	// interchangeably and therefore want them to be seen as infrequently as we can
	foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(DataTemplate, none)
	{
		QuestItemDataTemplate = X2QuestItemTemplate(DataTemplate);
		if (QuestItemDataTemplate != none)
		{
			CardManager.AddCardToDeck('QuestItems', string(QuestItemDataTemplate.DataName));
		}
	}

	HasCachedCards = true;
}

private function bool MissionFamilyIsXPack(string MissionFamily)
{
	local int FamilyIndex;

	FamilyIndex = arrSourceRewardMissionTypes.Find('MissionFamily', MissionFamily);

	if(FamilyIndex != INDEX_NONE && arrSourceRewardMissionTypes[FamilyIndex].XPackMissionSource)
	{
		return true;
	}

	return false;
}

function MissionIntroDefinition GetActiveMissionIntroDefinition()
{
	// Start Issue #395 -- content moved to GetActiveMissionIntroDefinition_Default
	
	local array<X2DownloadableContentInfo> DLCInfos;
	local MissionIntroDefinition MissionIntro;
	local int i, OverrideType;
	local string OverrideTag;

	MissionIntro = GetActiveMissionIntroDefinition_Default(OverrideType, OverrideTag);

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		if(DLCInfos[i].UseAlternateMissionIntroDefinition(ActiveMission, OverrideType, OverrideTag, MissionIntro))
		{
			break;
		}
	}
	// End Issue #395

	return MissionIntro;
}

function MissionIntroDefinition GetActiveMissionIntroDefinition_Default(out int OverrideType, out string OverrideTag) // Issue #395 -- rename, parameters
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComParcelManager ParcelManager;
	local PlotDefinition PlotDef;
	local PlotTypeDefinition PlotTypeDef;

	History = `XCOMHISTORY;
	ParcelManager = `PARCELMGR;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// intro priority it mission->plot->plot type->default
	// mission specific intro?
	if(ActiveMission.OverrideDefaultMissionIntro)
	{
		OverrideType = 0; // Issue #395
		OverrideTag = ActiveMission.sType; // Issue #395
		return ActiveMission.MissionIntroOverride;
	}

	// do we have a plot-specific intro?
	PlotDef = ParcelManager.GetPlotDefinition(BattleData.MapData.PlotMapName);
	if(PlotDef.OverrideDefaultMissionIntro)
	{
		OverrideType = 1; // Issue #395
		OverrideTag = PlotDef.MapName; // Issue #395
		return PlotDef.MissionIntroOverride;
	}
	
	// plot type specific intro?>
	PlotTypeDef = ParcelManager.GetPlotTypeDefinition(PlotDef.strType);
	if(PlotTypeDef.OverrideDefaultMissionIntro) 
	{
		OverrideType = 2; // Issue #395
		OverrideTag = PlotTypeDef.strType; // Issue #395
		return PlotTypeDef.MissionIntroOverride;
	}

	// just go with the default
	OverrideType = -1; // Issue #395
	OverrideTag = ""; // Issue #395
	return DefaultMissionIntroDefinition;
}

function bool ValidateMissionSchedule(string CardLabel, Object ValidationData)
{
	local bool ScheduleInMission;
	local int CheckAlertLevel, CheckForceLevel;
	local XComGameState_MissionSite MissionSiteState;
	local MissionSchedule CheckMissionSchedule;
	local XComGameState_BattleData BattleData;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	if( ValidationData == self )
	{
		ScheduleInMission = (ActiveMission.MissionSchedules.Find(Name(CardLabel)) != INDEX_NONE);

		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		CheckAlertLevel = BattleData.GetAlertLevel();
		CheckForceLevel = BattleData.GetForceLevel();
	}
	else
	{
		MissionSiteState = XComGameState_MissionSite(ValidationData);

		ScheduleInMission = (MissionSiteState.GeneratedMission.Mission.MissionSchedules.Find(Name(CardLabel)) != INDEX_NONE);
		CheckAlertLevel = MissionSiteState.SelectedMissionData.AlertLevel;
		CheckForceLevel = MissionSiteState.SelectedMissionData.ForceLevel;
	}

	if( !ScheduleInMission )
	{
		return false;
	}

	GetMissionSchedule(Name(CardLabel), CheckMissionSchedule);

	if( !(CheckMissionSchedule.MinRequiredAlertLevel <= CheckAlertLevel && CheckMissionSchedule.MaxRequiredAlertLevel >= CheckAlertLevel &&
		CheckMissionSchedule.MinRequiredForceLevel <= CheckForceLevel && CheckMissionSchedule.MaxRequiredForceLevel >= CheckForceLevel) )
	{
		return false;
	}

	if( CheckMissionSchedule.IncludeTacticalTag != '' || CheckMissionSchedule.ExcludeTacticalTag != '' )
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		if( XComHQ != None )     //  TQL doesn't have an HQ object
		{
			if( CheckMissionSchedule.IncludeTacticalTag != '' && XComHQ.TacticalGameplayTags.Find(CheckMissionSchedule.IncludeTacticalTag) == INDEX_NONE )
			{
				return false;
			}

			if( CheckMissionSchedule.ExcludeTacticalTag != '' && XComHQ.TacticalGameplayTags.Find(CheckMissionSchedule.ExcludeTacticalTag) != INDEX_NONE )
			{
				return false;
			}
		}
	}

	return true;
}

event Name ChooseMissionSchedule(Object Caller)
{
	local X2CardManager CardManager;
	local string ScheduleID;

	CacheMissionManagerCards();

	CardManager = class'X2CardManager'.static.GetCardManager();

	CardManager.SelectNextCardFromDeck('MissionSchedules', ScheduleID, ValidateMissionSchedule, Caller);

	return Name(ScheduleID);
}

final native function int GetMissionScheduleIndex(Name LookupID);
final native function GetMissionSchedule(Name LookupID, out MissionSchedule MissionScheduleRef);
final native function GetActiveMissionSchedule(out MissionSchedule MissionScheduleRef);
final native function GetConfigurableEncounter(
	Name LookupID, 
	out ConfigurableEncounter ConfigurableEncounterRef, 
	optional int ForceLevel = -1, 
	optional int AlertLevel = -1, 
	optional XComGameState_HeadquartersXCom XComHQ);

function InitMission(XComGameState_BattleData BattleData)
{
	local int Idx;
	local XComGameState_MissionSite MissionSiteState;
	local Name SelectedMissionSchedule;
	local XComGameState NewGameState;

	NewGameState = BattleData.GetParentGameState();

	if (Len(ForceMission.sType) > 0) // we have a mission coming from strategy
	{
		ActiveMission = ForceMission;	
	}
	else // need to see what the current TQL settings want to do
	{
		`assert( BattleData.m_iMissionType >= 0 );
		ActiveMission = arrMissions[BattleData.m_iMissionType];

		for (Idx = 0; Idx < ActiveMission.ForcedSitreps.Length; ++Idx)
		{
			BattleData.ActiveSitReps.AddItem( ActiveMission.ForcedSitreps[Idx] );
		}
	}

	// If this mission was initiated by a MissionSite in Strategy, then pull the mission information from that mission site
	if( BattleData.m_iMissionID > 0 )
	{
		MissionSiteState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', BattleData.m_iMissionID));

		if( MissionSiteState.SelectedMissionData.SelectedMissionScheduleName == '' )
		{
			MissionSiteState.CacheSelectedMissionData(BattleData.GetForceLevel(), BattleData.GetAlertLevel());
		}
		else if(BattleData.DirectTransferInfo.IsDirectMissionTransfer)
		{
			// We always need to recompute an appropriate mission schedule if doing a direct transfer, the initial 
			// schedule from strategy is only valid for the first part of the mission.
			SelectedMissionSchedule = ChooseMissionSchedule(self);
			MissionSiteState.SelectedMissionData.SelectedMissionScheduleName = SelectedMissionSchedule;
			MissionSiteState.SelectedMissionData.SelectedEncounters.Length = 0;
		}

		SelectedMissionSchedule = MissionSiteState.SelectedMissionData.SelectedMissionScheduleName;
		MissionQuestItemTemplate = MissionSiteState.GeneratedMission.MissionQuestItemTemplate;

		BattleData.ActiveSitReps = MissionSiteState.GeneratedMission.SitReps;
	}
	else
	{
		// no mission site, so this must be a tql mission. grab the item from the battle data state
		MissionQuestItemTemplate = BattleData.m_nQuestItem;
	}

	if( SelectedMissionSchedule == '' )
	{
		SelectedMissionSchedule = ChooseMissionSchedule(self);
	}

	SetActiveMissionScheduleIndex(SelectedMissionSchedule);

	LoadMissionScriptingMaps(BattleData, ActiveMission, bBlockingLoadParcels);

	BattleData.MapData.ActiveMission = ActiveMission;
	BattleData.MapData.ActiveMissionSchedule = SelectedMissionSchedule;
	BattleData.MapData.ActiveQuestItemTemplate = MissionQuestItemTemplate;

	// Mark all of the objectives as not yet completed
	BattleData.ResetObjectiveCompletionStatus();

	// clear the loot bucket
	BattleData.AutoLootBucket.Remove(0, BattleData.AutoLootBucket.Length);
	BattleData.CarriedOutLootBucket.Remove(0, BattleData.CarriedOutLootBucket.Length);
	BattleData.UniqueHackRewardsAcquired.Remove(0, BattleData.UniqueHackRewardsAcquired.Length);
	BattleData.bTacticalHackCompleted = false;

	RefreshHackRewards( BattleData );
}

function RefreshHackRewards( XComGameState_BattleData BattleData )
{
	local bool TacticalOnlyGameMode;

	BattleData.TacticalHackRewards.Length = 0;
	BattleData.StrategyHackRewards.Length = 0;

	TacticalOnlyGameMode = class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode( );

	if ((TacticalOnlyGameMode == false) && BattleData.m_strDesc != "BenchmarkTest")
	{
		SelectHackRewards( 'TacticalHackRewards', 'NegativeTacticalHackRewards', BattleData.TacticalHackRewards );
		SelectHackRewards( 'StrategyHackRewards', 'NegativeStrategyHackRewards', BattleData.StrategyHackRewards );
	}
	else
	{
		BuildingChallengeMission = true;
		SelectHackRewards( 'TacticalHackRewards', 'NegativeTacticalHackRewards', BattleData.TacticalHackRewards );
		SelectHackRewards( 'TacticalHackRewards', '', BattleData.StrategyHackRewards );
		BuildingChallengeMission = false;
	}
}

function RollRandomTacticalHackRewards( out array<name> HackNames )
{
	local bool TacticalOnlyGameMode;
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ));
	TacticalOnlyGameMode = class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode( );

	if ((TacticalOnlyGameMode == false) && BattleData.m_strDesc != "BenchmarkTest")
	{
		SelectHackRewards( 'TacticalHackRewards', 'NegativeTacticalHackRewards', HackNames );
	}
	else
	{
		BuildingChallengeMission = true;
		SelectHackRewards( 'TacticalHackRewards', 'NegativeTacticalHackRewards', HackNames );
		BuildingChallengeMission = false;
	}
}

// modifies the scripting map set on the active mission structure and then 
// loads the final set of scripting maps
protected static function LoadMissionScriptingMaps(XComGameState_BattleData BattleData, out MissionDefinition InActiveMission, bool BlockingLoadParcels)
{
	local X2SitRepEffect_ModifyMissionMaps MapEffect;
	local LevelStreaming MissionLevel;
	local string MissionMapName;
	local MissionMapSwap SwapData;
	local int MapIndex;

	// first see if any sitreps want to modify the mission maps array
	foreach class'X2SitRepTemplateManager'.static.IterateEffects(class'X2SitRepEffect_ModifyMissionMaps', MapEffect, BattleData.ActiveSitReps)
	{
		foreach MapEffect.ReplacementMissionMaps( SwapData )
		{
			MapIndex = InActiveMission.MapNames.Find( SwapData.ToReplace );
			if (MapIndex != INDEX_NONE)
			{
				InActiveMission.MapNames[ MapIndex ] = SwapData.ReplaceWith;
			}
		}

		foreach MapEffect.AdditionalMissionMaps(MissionMapName)
		{
			InActiveMission.MapNames.AddItem(MissionMapName); 
		}
	}

	// and then load all of the missions
	foreach InActiveMission.MapNames(MissionMapName)
	{
		MissionLevel = `MAPS.AddStreamingMap(MissionMapName, vect(0,0,0), rot(0,0,0), BlockingLoadParcels, true);
		if(MissionLevel != none) //Can be none when performing seamless travel
		{
			MissionLevel.bForceNoDupe = true;
		}
	}
}

simulated function Name GetNextIntelPurchaseableHackReward(optional bool bUseGuaranteedDeck = false)
{
	local X2CardManager CardManager;
	local string CardLabel;

	CacheMissionManagerCards();

	CardManager = class'X2CardManager'.static.GetCardManager();

	if (bUseGuaranteedDeck) // Use the special deck of intel rewards to guarantee one of them is presented to the player
		CardManager.SelectNextCardFromDeck('GuaranteedIntelPurchasedHackRewards', CardLabel);
	else
		CardManager.SelectNextCardFromDeck('IntelPurchasedHackRewards', CardLabel);

	return Name(CardLabel);
}

function SetActiveMissionScheduleIndex(Name MissionScheduleID)
{
	ActiveMissionScheduleIndex = GetMissionScheduleIndex(MissionScheduleID);
}

function RemoveMaps()
{
	local string MissionMapName;

	foreach ActiveMission.MapNames(MissionMapName)
	{
		`MAPS.RemoveStreamingMapByName(MissionMapName);
	}
}

function MissionDefinition GetMissionDefinitionForSourceReward(name nSource, name Reward, optional array<string> ExcludeFamilies, optional array<string> ExcludeTypes)
{
	local X2CardManager CardManager;
	local MissionSourceRewardMapping MissionReward;
	local MissionDefinition MissionDef;
	local array<string> ValidMissionFamilies, XPackMissionFamilies;
	local array<string> DeckMissionFamilies;
	local array<string> DeckMissionTypes, ValidMissionTypes;
	local string MissionFamily;
	local string MissionType;

	CacheMissionManagerCards();

	CardManager = class'X2CardManager'.static.GetCardManager();

	// get all mission families that are valid for this mapping
	foreach arrSourceRewardMissionTypes(MissionReward)
	{
		if (MissionReward.MissionSource == nSource && MissionReward.RewardType == Reward && ExcludeFamilies.Find(MissionReward.MissionFamily) == INDEX_NONE)
		{
			ValidMissionFamilies.AddItem(MissionReward.MissionFamily);

			if (`SecondWaveEnabled('OnlyXPackMissions') && MissionReward.XPackMissionSource)
			{
				XPackMissionFamilies.AddItem(MissionReward.MissionFamily);
			}
		}		
	}

	if(ValidMissionFamilies.Length == 0)
	{
		`Redscreen("Could not find a mission family for Source: " $ string(nSource) $ ", Reward: " $ string(Reward));
		ValidMissionFamilies.AddItem(arrSourceRewardMissionTypes[0].MissionFamily);
	}

	if (XPackMissionFamilies.Length > 0) // If XPack mission families were found, the Second Wave option is enabled
	{
		// Replace the full mission family list with the XPack-only variants before we find the full mission def
		ValidMissionFamilies = XPackMissionFamilies;
	}

	// select the first mission type off the deck that is valid for this mapping
	CardManager.GetAllCardsInDeck('MissionFamilies', DeckMissionFamilies);
	foreach DeckMissionFamilies(MissionFamily)
	{
		if(ValidMissionFamilies.Find(MissionFamily) != INDEX_NONE)
		{
			CardManager.MarkCardUsed('MissionFamilies', MissionFamily);
			break;
		}
	}
	
	// now that we have a mission family, determine the mission type to use
	CardManager.GetAllCardsInDeck('MissionTypes', DeckMissionTypes);

	// Get All valid mission types factoring in exclusions
	foreach DeckMissionTypes(MissionType)
	{
		if(ExcludeTypes.Find(MissionType) == INDEX_NONE)
		{
			ValidMissionTypes.AddItem(MissionType);
		}
	}

	foreach ValidMissionTypes(MissionType)
	{
		if(GetMissionDefinitionForType(MissionType, MissionDef))
		{
			if(MissionDef.MissionFamily == MissionFamily 
				|| (MissionDef.MissionFamily == "" && MissionDef.sType == MissionFamily)) // missions without families are their own family
			{
				CardManager.MarkCardUsed('MissionTypes', MissionType);
				return MissionDef;
			}
		}
	}

	`Redscreen("Could not find a mission type for MissionFamily: " $ MissionFamily);
	return arrMissions[0];
}

function bool GetMissionDefinitionForType(string MissionType, out MissionDefinition MissionDef)
{
	local int Index;

	Index = arrMissions.Find('sType', MissionType);
	
	if(Index == INDEX_NONE)
	{
		// this can happen if mods are added and then removed
		return false;
	}
	
	MissionDef = arrMissions[Index];
	return true;
}

function name ChooseQuestItemTemplate(name MissionSource, X2RewardTemplate MissionReward, MissionDefinition Mission, optional bool bDarkEvent = false)
{
	local X2CardManager CardManager;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2DataTemplate DataTemplate;
	local X2QuestItemTemplate QuestItemDataTemplate;
	local X2QuestItemTemplate SelectedTemplate;
	local array<string> ValidQuestItemTemplates;
	local array<string> QuestItemDeck;
	local string QuestItemCard;
	local int TemplateIndex;

	CacheMissionManagerCards();

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	CardManager = class'X2CardManager'.static.GetCardManager();
	CardManager.GetAllCardsInDeck('QuestItems', QuestItemDeck);

	// collect all quest item templates that are valid for this mission/source/reward combo
	foreach ItemTemplateManager.IterateTemplates(DataTemplate, none)
	{
		QuestItemDataTemplate = X2QuestItemTemplate(DataTemplate);
		if(QuestItemDataTemplate == none) continue;

		// verify this quest item is either explicitly valid for each of the parameters, or else doesn't care
		if(QuestItemDataTemplate.MissionSource.Length > 0 && QuestItemDataTemplate.MissionSource.Find(MissionSource) == INDEX_NONE)
		{
			continue;
		}

		if(QuestItemDataTemplate.MissionType.Length > 0 && QuestItemDataTemplate.MissionType.Find(Mission.sType) == INDEX_NONE)
		{
			continue;
		}

		if(QuestItemDataTemplate.RewardType.Length > 0 && QuestItemDataTemplate.RewardType.Find(MissionReward.DataName) == INDEX_NONE)
		{
			continue;
		}

		if((bDarkEvent && !QuestItemDataTemplate.bDarkEventRelated) || (!bDarkEvent && QuestItemDataTemplate.bDarkEventRelated))
		{
			continue;
		}

		ValidQuestItemTemplates.AddItem(string(QuestItemDataTemplate.DataName));
	};

	// now select the first card on the deck that is valid
	foreach QuestItemDeck(QuestItemCard)
	{
		TemplateIndex = ValidQuestItemTemplates.Find(QuestItemCard);
		if(TemplateIndex != INDEX_NONE)
		{
			DataTemplate = ItemTemplateManager.FindItemTemplate(name(ValidQuestItemTemplates[TemplateIndex]));
			SelectedTemplate = X2QuestItemTemplate(DataTemplate);
			break;
		}
	}

	// if no template what found, then scan through the list and see if this mission should have a reward.
	// fall back to any reward if so
	if(SelectedTemplate == none)
	{
		foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(DataTemplate, none)
		{
			QuestItemDataTemplate = X2QuestItemTemplate(DataTemplate);
			if(QuestItemDataTemplate != none && QuestItemDataTemplate.MissionType.Find(Mission.sType) != INDEX_NONE)
			{
				SelectedTemplate = QuestItemDataTemplate;

				`Redscreen("Could not find matching quest item template for:\n   Mission Source: " $ string(MissionSource)
					$ ",\n   Mission Reward: " $ string(MissionReward.rewardObjectTemplateName)
					$ ",\n   Mission Type: " $ Mission.sType
					$ "\nUsing " $ string(SelectedTemplate.DataName) $ " as a fallback, since this mission appears to require a quest item!");

				break;
			}
		}
	}

	`log("Selected quest item template '" $ string(SelectedTemplate) 
		$ "' for\n   Mission Source: " $ string(MissionSource) 
		$ "\n   Mission Reward: " $ string(MissionReward.rewardObjectTemplateName) 
		$ "\n   Mission Type: " $ Mission.sType, , 'XCom_Strategy');

	if (SelectedTemplate != none)
	{
		CardManager.MarkCardUsed('QuestItems', string(SelectedTemplate.DataName));
		return SelectedTemplate.DataName;
	}
	else
	{
		return '';
	}
}

function ObjectiveSpawnInfo GetObjectiveSpawnInfoByType(string sType)
{
	local int idx;
	local ObjectiveSpawnInfo EmptySpawnInfo;
	
	for(idx = 0; idx < arrObjectiveSpawnInfo.Length; idx++)
	{
		if(arrObjectiveSpawnInfo[idx].sMissionType == sType)
		{
			return arrObjectiveSpawnInfo[idx];
		}
	}

	//This can occur when loading from a saved game
	return EmptySpawnInfo;
}

function name GetQuestItemTemplateForMissionType(string MissionType)
{
	if(MissionType == ActiveMission.sType)
	{
		return MissionQuestItemTemplate;
	}
	else
	{
		`Redscreen("GetQuestItemTemplateForMissionType: No active mission with type " $ MissionType);
		return '';
	}
}

private function FixupSwappedActorDestructionLinks(XComInteractiveLevelActor NewObjectiveActor, XComLevelActor SwappedActor)
{
	local XComDestructibleActor NearbyActor;
	local int Index;

	// when swapping an interactive objective in for an actor in the world, we need to make sure that 
	// any links from other actors are also propagated. For example, if we make a laptop on a table an objective,
	// we need to make sure the relationship from the table to the laptop is recreated. Otherwise the laptop will
	// not be destroyed when the table is.
	foreach SwappedActor.CollidingActors(class'XComDestructibleActor', NearbyActor, class'XComWorldData'.const.WORLD_StepSize * 2)
	{
		Index = NearbyActor.AffectedChildren.Find(SwappedActor);
		if(Index != INDEX_NONE)
		{
			NearbyActor.AffectedChildren[Index] = NewObjectiveActor;
			// could break out here, but just in case keep looking in case we are linked to more than one actor
		}
	}
}

// common setup to match a visualizer's visuals to a spawn info and possiblity. Some spawn possibilities require actors to be
// hidden or replaced with the visualizer, and this function takes care of that. For example, we may want to turn a laptop on a desk
// into the objective, and we accomplish this by "stealing" it's visuals and applying them to the interactive actor.
function UpdateObjectiveVisualizerFromSwapInfo(XComInteractiveLevelActor Visualizer, ObjectiveSpawnPossibility Spawn, ObjectiveSpawnInfo SpawnInfo)
{
	local XComLevelActor SwapActor;
	local ParticleSystemComponent System;

	// spawn the visualizer object. 
	if(!SpawnInfo.bReplaceSwapActor)
	{
		// Replace the visuals of the spawned archetype with those of the actor already there
		SwapActor = XComLevelActor(Spawn.arrActorsToSwap[0]);
		if(SwapActor != none)
		{
			Visualizer.StaticMeshComponent.SetHidden(false);
			Visualizer.StaticMeshComponent.SetAbsolute(true, true, false);
			Visualizer.SetStaticMesh(SwapActor.StaticMeshComponent.StaticMesh, SwapActor.Location, SwapActor.Rotation);
			FixupSwappedActorDestructionLinks(Visualizer, SwapActor);

			// recenter any visual effects on the visual static mesh component
			foreach Visualizer.m_arrRemovePSCOnDeath(System)
			{
				System.SetAbsolute(true, true);
				System.SetTranslation(SwapActor.Location);
				System.SetRotation(SwapActor.Rotation);
			}
		}
		else
		{
			`RedScreen("bReplaceSwapActor=false, but arrSwapActors.Length=0!");
		}
	}
}

function CreateObjective_Interact(ObjectiveSpawnPossibility Spawn, ObjectiveSpawnInfo SpawnInfo, optional name nmRemoteEvent = '', optional bool RequiresObjectiveMarker = true)
{
	local XComGameStateHistory History;
	local XComWorldData XComWorld;
	local XComGameState_InteractiveObject InteractiveObject;
	local XComGameState_ObjectiveInfo ObjectiveState;
	local XComGameStateContext_TacticalGameRule StateChangeContainer;
	local XComGameState NewGameState;
	local XComInteractiveLevelActor VisArchetype;
	local XComInteractiveLevelActor Visualizer;
	local Vector Location;
	local X2LootTableManager LootManager;
	local int LootIndex;
	local XComPresentationLayer Presentation;

	Location = Spawn.GetSpawnLocation();

	// add this spawn to the list of used OSPs so that we don't use it again
	Spawn.bBeenUsed = true;
	Spawn.HideSwapActors(); // hide right away, so that it doesn't block the swapped actor sitting on the floor

	History = `XCOMHISTORY;
	XComWorld = `XWORLD;

	NewGameState = History.GetStartState();
	if(NewGameState == none)
	{
		// the start state has already been locked, so we'll need to make our own
		StateChangeContainer = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
		StateChangeContainer.GameRuleType = eGameRule_UnitAdded;
		NewGameState = History.CreateNewGameState(true, StateChangeContainer);
	}

	// determine our archetype
	VisArchetype = SelectSpawnArchetype(SpawnInfo);

	// spawn the game object
	InteractiveObject = XComGameState_InteractiveObject(NewGameState.CreateNewStateObject(class'XComGameState_InteractiveObject'));
	XComWorld.GetFloorTileForPosition(Location, InteractiveObject.TileLocation);
	InteractiveObject.ArchetypePath = PathName(VisArchetype);
	InteractiveObject.SpawnedRotation = Spawn.GetSpawnRotation();

	InteractiveObject.InteractionBoundingBox = Spawn.GetInteractionBoundingBox();

	// Add loot to the object
	if( !InteractiveObject.PendingLoot.bRolledForLoot && Spawn.LootCarrierName != '' )
	{
		LootManager = class'X2LootTableManager'.static.GetLootTableManager();

		//  @TODO: figure out how to make the name of the global loot carrier data driven
		LootIndex = LootManager.FindGlobalLootCarrier(Spawn.LootCarrierName);

		if( LootIndex >= 0 )
		{
			LootManager.RollForGlobalLootCarrier(LootIndex, InteractiveObject.PendingLoot);
		}
	}

	if (Spawn.HackRewards.Length > 0)
	{
		InteractiveObject.SetHackRewards(class'X2HackRewardTemplateManager'.static.SelectHackRewards(Spawn.HackRewards));
	}

	// add an objective information component to the game object
	if( RequiresObjectiveMarker )
	{
		ObjectiveState = XComGameState_ObjectiveInfo(NewGameState.CreateNewStateObject(class'XComGameState_ObjectiveInfo'));
		ObjectiveState.MissionType = SpawnInfo.sMissionType;
		ObjectiveState.OSPSpawnTag = Spawn.SpawnTag;
		InteractiveObject.AddComponentObject(ObjectiveState);
	}

	// snap the loc to the spawned game object
	Location = XComWorld.GetPositionFromTileCoordinates(InteractiveObject.TileLocation);
	Location.Z = XComWorld.GetFloorZForPosition(Location);

	// submit the new state
	if(NewGameState != History.GetStartState())
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	// spawn the visualizer object. 
	InteractiveObject.ActorId.Location = Location; //Set the location on the state object so it can be found when the visualizer spawns
	Visualizer = `XCOMGAME.Spawn(VisArchetype.Class,,, Location, Spawn.GetSpawnRotation(), VisArchetype, true);
	Visualizer.SetObjectIDFromState(InteractiveObject);

	Visualizer.UpdateLootSparklesEnabled(false, InteractiveObject);

	UpdateObjectiveVisualizerFromSwapInfo(Visualizer, Spawn, SpawnInfo);

	History.SetVisualizer(InteractiveObject.ObjectID, Visualizer);
	InteractiveObject.SetInitialState(Visualizer);
	Visualizer.SetObjectIDFromState(InteractiveObject);

	// add a unit flag for this object if needed, since the object is created 
	// after the ui has finished scanning the map for objects with flags
	if(InteractiveObject.IsTargetable())
	{
		Presentation = `PRES;
		Presentation.m_kUnitFlagManager.AddFlag(InteractiveObject.GetReference());
	}

	// objective interactables need to have their health modified by second wave options
	if( `SecondWaveEnabled('BetaStrike' ) && InteractiveObject.Health > 0 )
	{
		InteractiveObject.Health *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
	}
}

function bool GetVIPCharacterTemplate(out X2CharacterTemplate VIPTemplate)
{
	local ObjectiveSpawnInfo SpawnInfo;
	local X2CharacterTemplate ProxyTemplate;
	SpawnInfo = GetObjectiveSpawnInfoByType(ActiveMission.sType);

	// use the same proxy discovery logic that strategy does
	VIPTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(SpawnInfo.DefaultVIPTemplate);
	ProxyTemplate = GetProxyTemplateFromOriginalTemplate(VIPTemplate);
	if (ProxyTemplate != none)
	{
		VIPTemplate = ProxyTemplate;
	}
	return VIPTemplate != None;
}

private function XComGameState_Unit CreatePawnCommon(XComGameState NewGameState, TTile SpawnTile, int RewardUnitIndex)
{
	local XGBattle_SP Battle;
	local XComGameStateHistory History;
	local XComAISpawnManager SpawnManager;
	local StateObjectReference NewUnitRef;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit Unit;
	local XComGameState_BattleData BattleData;
	local vector SpawnLocation;

	Battle = XGBattle_SP(`BATTLE);
	if(Battle == none) return none;

	History = `XCOMHISTORY;

	// Create the unit state. This takes a few different paths depending on whether we are in the start state
	// and if we have a reward unit to use
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if( RewardUnitIndex >= BattleData.RewardUnits.Length )
	{
		// spawn the unit, this is a fallback in case there are no reward units...
		SpawnManager = `SPAWNMGR;

		GetVIPCharacterTemplate(CharacterTemplate);

		NewUnitRef = SpawnManager.CreateUnit(SpawnLocation, 
											 CharacterTemplate != none ? CharacterTemplate.DataName : 'Civilian', 
											 eTeam_Neutral, 
											 History.GetStartState() != none);

		// add the unit to the reward units array. This is the normal path in TQL missions, so
		// it needs to be supported and forwarded to other game systems correctly.
		BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
		BattleData.RewardUnits.AddItem(NewUnitRef);

		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', NewUnitRef.ObjectID)); // grab the unit we just created
	}
	else
	{
		// the reward unit already exists and was passed from strategy. Make a new version of it for our start state
		NewUnitRef = BattleData.RewardUnits[RewardUnitIndex];
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', NewUnitRef.ObjectID)); // this will create or return the existing version in the state
	}

	// Set the unit's location to the spawn location
	Unit.SetVisibilityLocation(SpawnTile);
	
	return Unit;
}

private function XComGameState_Unit CreateObjective_Pawn(ObjectiveSpawnPossibility Spawn, ObjectiveSpawnInfo SpawnInfo, int RewardUnitIndex)
{
	local XGBattle_SP Battle;
	local X2TacticalGameRuleset Rules;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_ObjectiveInfo ObjectiveState;
	local XComGameState NewGameState;
	local XComWorldData WorldData;
	local Vector SpawnLocation;
	local TTile SpawnTile;

	Battle = XGBattle_SP(`BATTLE);
	if(Battle == none) return none;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;
	
	// create a game state for this unit (if we aren't still in the start state)
	NewGameState = History.GetStartState();
	if(NewGameState == none)
	{
		NewGameState = History.CreateNewGameState(true, class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Create Objective Pawn"));
	}

	// find the location to spawn this pawn
	`assert((Spawn != none));

	// we have an objective spawn, so use it for our location
	Spawn.bBeenUsed = true; // also mark used and hide swap actors
	Spawn.HideSwapActors();
	SpawnLocation = Spawn.GetSpawnLocation();

	WorldData = `XWORLD;
	if(!WorldData.GetFloorTileForPosition(SpawnLocation, SpawnTile))
	{
		SpawnTile = WorldData.GetTileCoordinatesFromPosition(SpawnLocation);
	}

	Unit = CreatePawnCommon(NewGameState, SpawnTile, RewardUnitIndex);

	// Add an objective state component to the newly created unit
	ObjectiveState = XComGameState_ObjectiveInfo(NewGameState.CreateNewStateObject(class'XComGameState_ObjectiveInfo'));
	ObjectiveState.MissionType = SpawnInfo.sMissionType;
	ObjectiveState.OSPSpawnTag = Spawn != none ? Spawn.SpawnTag : "";
	Unit.AddComponentObject(ObjectiveState);

	if(NewGameState != History.GetStartState())
	{
		Rules = `TACTICALRULES;
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("Unable to submit Create Objective Pawn gamestate!");
		}
	}

	return Unit;
}

/// <summary>
/// Returns the averaged centerpoint of all objectives in the primary active mission.
/// </summary>
native function bool GetLineOfPlayEndpoint(out vector LineOfPlayEndpoint);

private function array<ObjectiveSpawnPossibility> SelectObjectiveSpawns(ObjectiveSpawnInfo SpawnInfo, const array<ObjectiveSpawnPossibility> arrObjectiveSpawns)
{
	local array<ObjectiveSpawnPossibility> arrWorkingCopy;
	local array<ObjectiveSpawnPossibility> arrResult;
	local ObjectiveSpawnPossibility Spawn;
	local ObjectiveSpawnPossibility Check;
	local float MinDistanceBetweenObjectives;
	local int NumToSelect;
	local int AttemptCount;

	// Start Issue #463
	//	
	// Vars
	local XComGameState_BattleData BattleData;
	local XComLWTuple OverrideTuple;
	
    BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// Fix the random range to correct an off-by-one error so that the max objective count is possible to spawn.
	NumToSelect = SpawnInfo.iMinObjectives + `SYNC_RAND_TYPED(SpawnInfo.iMaxObjectives - SpawnInfo.iMinObjectives + 1);

    // If we have battle info with a mission ID, see if any mods want
	// to specify the number of objectives to use by passing this
	// BattleData to them via an event.
	//
	// The event takes the form:
	//   {
	//       ID: OverrideObjectiveSpawnCount,
	//       Data: [ in BattleData BattleData, out int SpawnCount ]
	//   }
    if (BattleData != none && BattleData.m_iMissionID > 0)
    {
		OverrideTuple = new class'XComLWTuple';
		OverrideTuple.Id = 'OverrideObjectiveSpawnCount';
		OverrideTuple.Data.Add(2);
		OverrideTuple.Data[0].kind = XComLWTVObject;
		OverrideTuple.Data[0].o = BattleData;
		OverrideTuple.Data[1].kind = XComLWTVInt;
		OverrideTuple.Data[1].i = NumToSelect;
		
		`XEVENTMGR.TriggerEvent('OverrideObjectiveSpawnCount', OverrideTuple, self);
		
		NumToSelect = OverrideTuple.Data[1].i;
    }
	// End Issue #463
	
	if(SpawnInfo.iMinTilesBetweenObjectives <= 0)
	{
		// simple case where we don't care about distance, so just select at random
		arrResult = arrObjectiveSpawns;
		while (arrResult.Length > NumToSelect)
		{
			arrResult.Remove(`SYNC_RAND_TYPED(arrResult.Length), 1);
		}
	}
	else
	{
		MinDistanceBetweenObjectives = SpawnInfo.iMinTilesBetweenObjectives * class'XComWorldData'.const.WORLD_StepSize;

		// We need to ensure that all selected objectives are far enough apart.
		// try 20 times to satisfy the requirements with random picks.
		// if this proves to not be robust enough, we may need to come up with a better 
		// algorithm. Please don't just make the attempt count something silly like
		// 1000
		for(AttemptCount = 0; arrResult.Length < NumToSelect && AttemptCount < 20; AttemptCount++)
		{
			arrWorkingCopy = arrObjectiveSpawns;

			while(arrResult.Length < NumToSelect && arrWorkingCopy.Length > 0)
			{
				Spawn = arrWorkingCopy[`SYNC_RAND_TYPED(arrWorkingCopy.Length)];
				arrWorkingCopy.RemoveItem(Spawn);

				// Make sure all OSPs currently in the result set are at least the min distance away from the new one.
				foreach arrResult(Check)
				{
					if(VSize(Spawn.Location - Check.Location) < MinDistanceBetweenObjectives)
					{
						Spawn = none;
						break;
					}
				}

				if(Spawn != none)
				{
					arrResult.AddItem(Spawn);
				}
			}
		}
	}

	`assert(arrResult.Length >= 0);
	return arrResult;
}

function SpawnMissionObjectives()
{
	local ObjectiveSpawnInfo SpawnInfo;

	SpawnInfo = GetObjectiveSpawnInfoByType(ActiveMission.sType);
	SpawnMissionObjectivesForInfo(SpawnInfo);
}

function SpawnVIPWithXComSquad()
{
	local XComGameStateHistory History;
	local X2TacticalGameRuleset Rules;
	local XComParcelManager ParcelManager;
	local XComWorldData WorldData;
	local ObjectiveSpawnInfo SpawnInfo;
	local XComGameState_Unit Unit;
	local XComGameState_Player PlayerState;
	local XComGameState NewGameState;
	local array<Vector> SpawnLocations;
	local Vector SpawnLocation;
	local TTile SpawnTile;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_AIGroup GroupState;

	SpawnInfo = GetObjectiveSpawnInfoByType(ActiveMission.sType);

	if(!SpawnInfo.SpawnVIPWithXComSquad)
	{
		// only spawn if the objective info wants a unit to spawn
		return;
	}

	History = `XCOMHISTORY;
	WorldData = `XWORLD;
	Rules = `TACTICALRULES;
	
	// create a game state for this unit (if we aren't still in the start state)
	NewGameState = History.GetStartState();
	if(NewGameState == none)
	{
		NewGameState = History.CreateNewGameState(true, class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Create Objective Pawn"));
	}

	// find a spot with the squad and spawn the unit
	ParcelManager = `PARCELMGR;
	ParcelManager.SoldierSpawn.GetValidFloorLocations(SpawnLocations);
	foreach SpawnLocations(SpawnLocation)
	{
		if(WorldData.IsPositionOnFloorAndValidDestination(SpawnLocation))
		{
			// put the unit here
			WorldData.GetFloorTileForPosition(SpawnLocation, SpawnTile);
			Unit = CreatePawnCommon(NewGameState, SpawnTile, 0);
			break;
		}
	}

	if(Unit == none)
	{
		`Redscreen("Unable to spawn unit in SpawnVIPWithXComSquad! Possibly no more valid spawn locations with the squad?");
	}
	else
	{
		// put the vip on the XCom team
		foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if(PlayerState.GetTeam() == eTeam_XCom)
			{
				Unit.SetControllingPlayer(PlayerState.GetReference());
				break;
			}
		}

		GroupState = Unit.GetGroupMembership( );
		GroupState.RemoveUnitFromGroup( Unit.ObjectID, NewGameState );

		foreach History.IterateByClassType(class'XComGameState_AIGroup', GroupState)
		{
			if (GroupState.TeamName == eTeam_XCom)
			{
				GroupState.AddUnitToGroup( Unit.ObjectID, NewGameState );
				break;
			}
		}

		XComHQ = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
		XComHQ = XComGameState_HeadquartersXCom( NewGameState.ModifyStateObject( class'XComGameState_HeadquartersXCom', XComHQ.ObjectID ) );

		XComHQ.Squad.AddItem( Unit.GetReference() );
		XComHQ.AllSquads[0].SquadMembers.AddItem( Unit.GetReference() );
		Unit.bMissionProvided = true;
	}

	// and submit the unit (even if we failed to spawn one we need to commit the state we created)
	if(NewGameState != History.GetStartState())
	{
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("Unable to submit SpawnVIPWithXComSquad gamestate!");
		}
	}
}

private function bool MissionTypeSupported(ObjectiveSpawnPossibility Spawn, string MissionType)
{
	local int AliasIndex;
	local int TempIndex;
	if (Spawn.arrMissionTypes.Find(MissionType) == INDEX_NONE)
	{		
		AliasIndex = arrMissionTypeAliases.Find('KeyMissionType', MissionType);
		if (AliasIndex == INDEX_NONE)
		{
			//No alias, failure
			return false;
		}
		else
		{
			//Iterate the list of aliases. If one is found, then return success
			for (TempIndex = 0; TempIndex < arrMissionTypeAliases[AliasIndex].AltMissionTypes.Length; ++TempIndex)
			{
				if (Spawn.arrMissionTypes.Find(arrMissionTypeAliases[AliasIndex].AltMissionTypes[TempIndex]) != INDEX_NONE)
				{
					return true;
				}
			}

			return false;
		}
	}

	return true;
}

private function GatherSpawnObjectives(ObjectiveSpawnInfo SpawnInfo, out array<ObjectiveSpawnPossibility> ValidSpawns)
{
	local XGBattle Battle;
	local bool IsPrimaryObjective;
	local bool IsSpawnInObjectiveParcel;
	local int TilesFromObjectiveParcelCenter;
	local Vector SpawnLocation;
	local XComParcel ObjectiveParcel;
	local ObjectiveSpawnPossibility Spawn;

	Battle = `BATTLE;

	IsPrimaryObjective = SpawnInfo.sMissionType == ActiveMission.sType;
	ObjectiveParcel = `PARCELMGR.ObjectiveParcel;

	// grab all spawns that are valid for this mission type
	foreach Battle.AllActors(class'ObjectiveSpawnPossibility', Spawn)
	{
		if(Spawn.bBeenUsed)
		{
			// don't use the same spawn more than once
			continue;
		}
		
		// do primary/sub objective specific checks
		SpawnLocation = Spawn.GetSpawnLocation();
		if(IsPrimaryObjective)
		{
			if (!MissionTypeSupported(Spawn, SpawnInfo.sMissionType))
			{
				// only use spawns with the same mission type
				continue;
			}
	
			IsSpawnInObjectiveParcel = ObjectiveParcel != none && ObjectiveParcel.IsInsideBounds(SpawnLocation);
			if(!IsSpawnInObjectiveParcel && !SpawnInfo.bCanSpawnOutsideObjectiveParcel)
			{
				// primary objectives only spawn in objective parcel (unless flagged otherwise)
				continue;
			}
		}
		else // subobjective
		{
			if(Spawn.arrSubObjectiveTypes.Find(SpawnInfo.sMissionType) == INDEX_NONE )
			{
				// only use spawns with the same sub mission type
				continue;
			}

			IsSpawnInObjectiveParcel = ObjectiveParcel != none && ObjectiveParcel.IsInsideBounds(SpawnLocation);
			if(IsSpawnInObjectiveParcel)
			{
				// subobjectives only spawn outside the objective parcel
				continue;
			}
		}

		// check distance stuff
		TilesFromObjectiveParcelCenter = VSize(SpawnLocation - ObjectiveParcel.Location) / class'XComWorldData'.const.WORLD_StepSize;
		if(TilesFromObjectiveParcelCenter < SpawnInfo.iMinTilesFromObjectiveCenter)
		{
			// not if too close to the objective parcel center
			continue;
		}
		else if(TilesFromObjectiveParcelCenter > SpawnInfo.iMaxTilesFromObjectiveCenter)
		{
			// and not if too far
			continue;
		}

		// all checks passed, this spawn is a valid option
		ValidSpawns.AddItem(Spawn);
	}

	// now that we have our spawn possibilities, pick a random sampling of them that fits the 
	// distance requirements
	ValidSpawns = SelectObjectiveSpawns(SpawnInfo, ValidSpawns);
}

private function XComInteractiveLevelActor SelectSpawnArchetype(ObjectiveSpawnInfo SpawnInfo)
{
	local XComInteractiveLevelActor SpawnArchetype;
	local XComGameState_BattleData BattleDataState;
	local int CurrentForceLevel;
	local int NumValidFound;
	local int Index;
	local int SelectedIndex;

	if(SpawnInfo.ARCToSpawn.Length == 0)
	{
		// no archetype specified, so we're spawning a pawn. Just return none
		return none;
	}

	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	CurrentForceLevel = BattleDataState.GetForceLevel();
	
	// find all appropriate archetypes for the given force level and then pick one
	SelectedIndex = -1;
	NumValidFound = 0;
	for(Index = 0; Index < SpawnInfo.ARCToSpawn.Length; Index++)
	{
		if((SpawnInfo.ARCToSpawn[Index].MinForceLevel < 0 || SpawnInfo.ARCToSpawn[Index].MinForceLevel <= CurrentForceLevel)
			&& (SpawnInfo.ARCToSpawn[Index].MaxForceLevel < 0 || SpawnInfo.ARCToSpawn[Index].MaxForceLevel >= CurrentForceLevel))
		{
			NumValidFound++;
			
			// do a weighted random roll. This effectively causes every valid entry to have the same chance of 
			// being selected
			if(`SYNC_RAND(NumValidFound) == 0)
			{
				SelectedIndex = Index;
			}
		}
	}

	if(SelectedIndex < 0)
	{
		// couldn't find a valid force level entry, so fallback to any archetype
		`Redscreen("SelectSpawnArchetype(): No valid force level found for and archetype possibility in " $ SpawnInfo.sMissionType);
		SelectedIndex = `SYNC_RAND(SpawnInfo.ARCToSpawn.Length);
	}
	
	SpawnArchetype = XComInteractiveLevelActor(DynamicLoadObject(SpawnInfo.ARCToSpawn[SelectedIndex].ArchetypePath, class'XComInteractiveLevelActor'));

	if(SpawnArchetype == none)
	{
		`Redscreen("SelectSpawnArchetype(): Couldn't load actor for archetype " $ SpawnInfo.ARCToSpawn[SelectedIndex].ArchetypePath);
	}
	return SpawnArchetype;
}

private function SpawnMissionObjectivesForInfo(ObjectiveSpawnInfo SpawnInfo)
{
	local array<ObjectiveSpawnPossibility> ValidSpawns;
	local ObjectiveSpawnPossibility Spawn;
	local int RewardUnitIndex;
	local XComGameState NewGameState;	
	local XComGameState_InteractiveObject InteractiveObject;

	GatherSpawnObjectives(SpawnInfo, ValidSpawns);

	// if SpawnVIPWithXComSquad is specified, the first vip index is reserved for placement with the XComSquad
	RewardUnitIndex = SpawnInfo.SpawnVIPWithXComSquad ? 1 : 0;

	foreach ValidSpawns(Spawn)
	{
		if(SpawnInfo.ARCToSpawn.Length > 0) // archetypes are specified, so we need to spawn an interactive object
		{
			CreateObjective_Interact(Spawn, SpawnInfo);
		}
		else // no archetype means a pawn objective 
		{
			CreateObjective_Pawn(Spawn, SpawnInfo, RewardUnitIndex); 
			++RewardUnitIndex;
		}

		if( Spawn.AssociatedObjectiveActor != None )
		{
			NewGameState = `XCOMHISTORY.GetStartState();
			if(NewGameState == none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Configuring Associated Objective Hackable");
			}			

			InteractiveObject = Spawn.AssociatedObjectiveActor.GetInteractiveState(NewGameState);
			InteractiveObject.SetLocked(Spawn.AssociatedLockStrength);

			if( Spawn.HackRewards.Length > 0 )
			{
				InteractiveObject.SetHackRewards(class'X2HackRewardTemplateManager'.static.SelectHackRewards(Spawn.HackRewards));
			}

			if(`XCOMHISTORY.GetStartState() == none)
			{	
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}

	// Roll for loot if this is the main mission type. We may want to split this out later
	if(SpawnInfo.sMissionType == ActiveMission.sType)
	{
		RollForMapLoot();
	}

	HideOSPActors();
}

// Meant to be called at mission startup, checks if the level designers specified an explicit actor
// to use as the endpoint of the line of play, and if so, sets it up
function CheckForLineOfPlayAnchorOverride()
{
	local XComGameStateHistory History;
	local XComGameState StartState;
	local XComInteractiveLevelActor InteractiveActor;
	local XComGameState_InteractiveObject InteractiveObject;
	local XComGameState_LineOfPlayAnchor Anchor;

	History = `XCOMHISTORY;
	StartState = History.GetStartState();
	if(StartState == none)
	{
		`Redscreen("CheckForLineOfPlayAnchorOverride should only be called as part of the mission startup sequence.");
		return;
	}

	if(ActiveMission.OverrideLineOfPlayAnchorActorTag != '')
	{
		foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComInteractiveLevelActor', InteractiveActor)
		{
			if(InteractiveActor.Tag == ActiveMission.OverrideLineOfPlayAnchorActorTag)
			{
				InteractiveObject = InteractiveActor.GetInteractiveState(StartState);
				Anchor = XComGameState_LineOfPlayAnchor(StartState.CreateNewStateObject(class'XComGameState_LineOfPlayAnchor'));
				InteractiveObject.AddComponentObject(Anchor);
				break;
			}
		}

		if(Anchor == none)
		{
			`Redscreen("CheckForLineOfPlayAnchorOverride could not find an interactive actor with tag " $ string(ActiveMission.OverrideLineOfPlayAnchorActorTag));
		}
	}
}

// This function is responsible for making the bHideSwapActorsIfUnused flag on OSPs work.
// OSPs with this flag should hide their swap actors if they are not used. This is to allow things like
// gather evidence to place OSPs for meat piles, corpses, and other things that would normally be
// out of place in the mission.
function HideOSPActors()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local XGBattle Battle;
	local ObjectiveSpawnPossibility Spawn;
	local XComGameState_InteractiveObject ObjectState;
	local array<XComGameState_InteractiveObject> ObjectStates;
	local Vector SpawnLocation;
	local bool IsUsedObjectiveSpawn;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;
	Battle = `BATTLE;

	// build a list of interactive objects that are objectives
	foreach History.IterateByClassType(class'XComGameState_InteractiveObject', ObjectState)
	{
		if(ObjectState.FindComponentObject(class'XComGameState_ObjectiveInfo') != none)
		{
			ObjectStates.AddItem(ObjectState);
		}
	}

	// hide all unused OSPs Actors that request it and were not used for objective spawns
	foreach Battle.AllActors(class'ObjectiveSpawnPossibility', Spawn)
	{
		if(Spawn.bHideSwapActorsIfUnused)
		{
			IsUsedObjectiveSpawn = false;

			// Determine if this spawn was used. Sadly, we can't just check the bBeenUsed flag on the osp,
			// since this function also runs when loading games and that flag is not saved (it's only)
			// used to make mission generation faster
			foreach ObjectStates(ObjectState)
			{
				SpawnLocation = Spawn.GetSpawnLocation();
				if(ObjectState.TileLocation == WorldData.GetTileCoordinatesFromPosition(SpawnLocation))
				{
					IsUsedObjectiveSpawn = true;
					break;
				}
			}

			if(!IsUsedObjectiveSpawn)
			{
				Spawn.HideSwapActors();
			}
		}
	}
}

function bool GetPlotLootDefinitions(string PlotType, out array<PlotLootDefinition> PlotLootDefs)
{
	local PlotLootDefinition PlotLootDef;

	PlotLootDefs.Length = 0;
	foreach arrPlotLootDefinitions(PlotLootDef)
	{
		if(PlotLootDef.PlotType == PlotType)
		{
			PlotLootDefs.AddItem(PlotLootDef);
		}
	}

	return PlotLootDefs.Length > 0;
}

private function RollForMapLoot()
{
	local XComParcelManager ParcelManager;
	local array<PlotLootDefinition> PlotLootDefs;
	local PlotLootDefinition PlotLootDef;
	local array<ObjectiveSpawnPossibility> SpawnPossibilities;
	local ObjectiveSpawnPossibility SpawnPossibility; 
	local ObjectiveSpawnInfo FakeSpawnInfo;
	local ObjectiveSpawnArchetype FakeSpawnArchetype;
	local int Index;

	ParcelManager = `PARCELMGR;
	
	if(!GetPlotLootDefinitions(ParcelManager.PlotType.strType, PlotLootDefs)) 
	{
		return; // no loot requested for this plot type
	}

	foreach PlotLootDefs(PlotLootDef)
	{
		// find all OSPs that we can spawn this loot on
		foreach `XWORLDINFO.AllActors(class'ObjectiveSpawnPossibility', SpawnPossibility)
		{
			if (!SpawnPossibility.bBeenUsed && MissionTypeSupported(SpawnPossibility, PlotLootDef.OSPMissionType))
			{
				SpawnPossibilities.AddItem(SpawnPossibility);
			}
		}

		// shuffle them up
		SpawnPossibilities.RandomizeOrder();

		// create a fake spawn info for the loot objects
		FakeSpawnArchetype.ArchetypePath = PlotLootDef.LootActorArchetype;
		FakeSpawnInfo.ARCToSpawn.AddItem(FakeSpawnArchetype);

		// and spawn as many as is desired
		for(Index = 0; Index < PlotLootDef.DesiredSpawnCount && Index < SpawnPossibilities.Length; Index++)
		{
			CreateObjective_Interact(SpawnPossibilities[Index], FakeSpawnInfo,, false);
		}
	}
}

function SelectHackRewards(Name RewardDeck, Name NegativeRewardDeck, out array<Name> RewardList)
{
	local X2CardManager CardManager;
	local string CardLabel;
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate HackRewardTemplate;

	RewardList.Length = 0;

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

	CacheMissionManagerCards();

	CardManager = class'X2CardManager'.static.GetCardManager();

	// select the Tier 2 reward first
	CardManager.SelectNextCardFromDeck(RewardDeck, CardLabel, ValidateTier2HackRewards);
	LastSelectedRewardName = Name(CardLabel);

	RewardList.AddItem(LastSelectedRewardName);

	// if the Tier 2 reward has an accompanying Tier 1 variant, select that as well
	HackRewardTemplate = HackRewardTemplateManager.FindHackRewardTemplate(LastSelectedRewardName);
	if( HackRewardTemplate.bPairWithLinkedReward && HackRewardTemplate.LinkedReward != '' )
	{
		RewardList.InsertItem(0, HackRewardTemplate.LinkedReward);
	}
	else
	{
		// select the tier 1 reward randomly from the deck
		CardManager.SelectNextCardFromDeck(RewardDeck, CardLabel, ValidateTier1HackRewards);

		RewardList.InsertItem(0, Name(CardLabel));
	}

	// always mark the linked reward card as used
	if( HackRewardTemplate.LinkedReward != '' )
	{
		CardManager.MarkCardUsed(RewardDeck, string(HackRewardTemplate.LinkedReward));
	}

	CardLabel = "";
	CardManager.SelectNextCardFromDeck(NegativeRewardDeck, CardLabel);
	if( CardLabel != "" )
	{
		RewardList.InsertItem(0, Name(CardLabel));
	}
}

function bool ValidateTier2HackRewards(string CardLabel, Object ValidationData)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate HackRewardTemplate;

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	HackRewardTemplate = HackRewardTemplateManager.FindHackRewardTemplate(Name(CardLabel));

	if( !HackRewardTemplate.bIsTier2Reward )
	{
		return false;
	}

	if (BuildingChallengeMission && HackRewardTemplate.bIsStrategyReward)
	{
		return false;
	}

	// TODO: add additional validation for strategy requirements
	if( !HackRewardTemplate.IsHackRewardCurrentlyPossible() )
	{
		return false;
	}

	return true;
}

function bool ValidateTier1HackRewards(string CardLabel, Object ValidationData)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate HackRewardTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	HackRewardTemplate = HackRewardTemplateManager.FindHackRewardTemplate(Name(CardLabel));

	if( !HackRewardTemplate.bIsTier1Reward )
	{
		return false;
	}

	if( HackRewardTemplate.LinkedReward != '' )
	{
		if( HackRewardTemplate.bPairWithLinkedReward == (HackRewardTemplate.LinkedReward != LastSelectedRewardName) )
		{
			return false;
		}
	}

	if (BuildingChallengeMission && HackRewardTemplate.bIsStrategyReward)
	{
		return false;
	}

	// TODO: add additional validation for strategy requirements
	if( !HackRewardTemplate.IsHackRewardCurrentlyPossible() )
	{
		return false;
	}

	return true;
}

static private function X2CharacterTemplate GetProxyTemplateFromOriginalTemplate(X2CharacterTemplate OriginalUnitTemplate)
{
	local X2CharacterTemplateManager TemplateManager;
	local X2CharacterTemplate ProxyTemplate;
	local int Index;

	Index = default.ProxyRewardUnitMappings.Find('OriginalTemplate', OriginalUnitTemplate.DataName);	
	if(Index != INDEX_NONE)
	{
		TemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		ProxyTemplate = TemplateManager.FindCharacterTemplate(default.ProxyRewardUnitMappings[Index].ProxyTemplate);
		if(ProxyTemplate != none)
		{
			return ProxyTemplate;
		}
		else
		{
			`Redscreen("GetProxyTemplateFromOriginalTemplate(): Could not find character template for " $ default.ProxyRewardUnitMappings[Index].ProxyTemplate);
		}
	}

	return none;
}

static function AddCosmeticItemToProxyUnit(XComGameState_Unit OriginalUnit, XComGameState_Unit ProxyUnit, EInventorySlot InvSlot, XComGameState NewStartState)
{
	local X2WeaponTemplate WeaponTemplate;
	local XComGameState_Item OriginalItem;
	local XComGameState_Item ProxyItem;

	OriginalItem = OriginalUnit.GetItemInSlot(InvSlot, NewStartState);
	if (OriginalItem != none)
	{
		WeaponTemplate = X2WeaponTemplate(OriginalItem.GetMyTemplate());
		if(WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
		{
			ProxyItem = WeaponTemplate.CreateInstanceFromTemplate(NewStartState);
			ProxyItem.ItemLocation = WeaponTemplate.StowedLocation;

			ProxyUnit.AddItemToInventory(ProxyItem, InvSlot, NewStartState);
		}
	}
}

// creates a proxy reward unit for sending to tactical. Since VIP and reward units need to appear differently
// (for example, soldiers have no weapons and civilian ability sets), rather than go through all the hullabaloo
// of trying to massage them into something they are not, we will create a proxy unit that has the appearance and
// behaviors that we want, and then give them the face and characteristics of the original unit. Upon returning to
// strategy, the original unit will be updated from the state of the proxy. e.g., a dead proxy will result in a dead
// original.
static function XComGameState_Unit CreateProxyRewardUnitIfNeeded(XComGameState_Unit OriginalUnit, XComGameState NewStartState)
{
	local XComTacticalMissionManager MissionManager;
	local XGCharacterGenerator Generator;
	local TSoldier GeneratedSoldier;
	local XComGameState_Unit ProxyUnit;
	local X2CharacterTemplate ProxyTemplate;

	MissionManager = `TACTICALMISSIONMGR;
	ProxyTemplate = MissionManager.GetProxyTemplateFromOriginalTemplate(OriginalUnit.GetMyTemplate());
	if(ProxyTemplate == none)
	{
		return none;
	}

	ProxyUnit = XComGameState_Unit(NewStartState.CreateNewStateObject(class'XComGameState_Unit', ProxyTemplate));
	ProxyUnit.SetTAppearance(OriginalUnit.kAppearance);
	ProxyUnit.SetUnitName(OriginalUnit.GetFirstName(), OriginalUnit.GetLastName(), OriginalUnit.GetNickName());
	ProxyUnit.TacticalTag = OriginalUnit.TacticalTag; // Copy any tactical tag over in case Kismet needs to find this unit

	// generate an appearance that is appropriate for the proxy template. We'll steal it's body, arms, and legs,
	// and leave the rest matching the original unit
	Generator = `XCOMGRI.Spawn(ProxyTemplate.CharacterGeneratorClass);
	if (Generator != none)
	{
		GeneratedSoldier = Generator.CreateTSoldier(ProxyTemplate.DataName, EGender(ProxyUnit.kAppearance.iGender));
		ProxyUnit.kAppearance.nmArms = GeneratedSoldier.kAppearance.nmArms;
		ProxyUnit.kAppearance.nmArms_Underlay = GeneratedSoldier.kAppearance.nmArms_Underlay;
		ProxyUnit.kAppearance.nmLegs = GeneratedSoldier.kAppearance.nmLegs;
		ProxyUnit.kAppearance.nmLegs_Underlay = GeneratedSoldier.kAppearance.nmLegs_Underlay;
		ProxyUnit.kAppearance.nmTorso = GeneratedSoldier.kAppearance.nmTorso;
		ProxyUnit.kAppearance.nmTorso_Underlay = GeneratedSoldier.kAppearance.nmTorso_Underlay;
	}

	// start off on the same team as the proxy
	if(OriginalUnit.ControllingPlayer.ObjectID > 0)
	{
		ProxyUnit.SetControllingPlayer(OriginalUnit.ControllingPlayer);
	}

	// this fixes missing cosmetic items on proxy units
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_PrimaryWeapon, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_SecondaryWeapon, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_HeavyWeapon, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_GrenadePocket, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_AmmoPocket, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_TertiaryWeapon, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_QuaternaryWeapon, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_QuinaryWeapon, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_SenaryWeapon, NewStartState);
	AddCosmeticItemToProxyUnit(OriginalUnit, ProxyUnit, eInvSlot_SeptenaryWeapon, NewStartState);	

	return ProxyUnit;
}

cpptext
{
	// Accessor for the MissionSchedule for the current(active) mission
	const FMissionSchedule& GetActiveMissionSchedule() const;

	// Accessors for the mission schedule information structs by lookup IDs
	const FMissionSchedule* GetMissionSchedule(const FName& LookupID) const;
	const FConfigurableEncounter* GetConfigurableEncounter(
		const FName& LookupID, 
		INT ForceLevel, 
		INT AlertLevel, 
		const UXComGameState_HeadquartersXCom* XComHQ) const;
	const FSpawnDistributionList* GetSpawnDistributionList(const FName& LookupID);
}

defaultproperties
{
	bBlockingLoadParcels=true
	ActiveMissionScheduleIndex=-1
}
