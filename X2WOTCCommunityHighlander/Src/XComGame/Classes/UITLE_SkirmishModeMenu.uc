//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITLE_LadderModeMenu.uc
//  AUTHOR:  Joe Cortese
//----------------------------------------------------------------------------
//  Copyright (c) 2018 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITLE_SkirmishModeMenu extends UITLEScreen
	Native(UI)
	config(UI);

enum EUISkirmishScreen
{
	eUISkirmishScreen_Base,
	eUISkirmishScreen_Squad,
	eUISkirmishScreen_SoldierData,
	eUISkirmishScreen_SoldierClass,
	eUISkirmishScreen_SoldierEquipment,
	eUISkirmishScreen_PrimaryWeapon,
	eUISkirmishScreen_SecondaryWeapon,
	eUISkirmishScreen_Armor,
	eUISkirmishScreen_PCS,
	eUISkirmishScreen_UtilItem1,
	eUISkirmishScreen_UtilItem2,
	eUISkirmishScreen_GrenadePocket,
	eUISkirmishScreen_HeavyWeapon,
	eUISkirmishScreen_SoldierAbilities,
	eUISkirmishScreen_SoldierRank,
	eUISkirmishScreen_MapData,
	eUISkirmishScreen_Map,
	eUISkirmishScreen_Mission,
	EUISkirmishScreen_Biome,
	eUISkirmishScreen_Enemies,
	eUISkirmishScreen_Difficulty,
	eUISkirmishScreen_MAX
};
struct native SkirmishModeItemMapping //Because I can't have a TMap in script. Sigh. -bsteiner 
{
	var XComGameState_Item Item;
	var EInventorySlot eInvSlot;
	var Name ItemTemplateName;
};

var UINavigationHelp NavHelp;

var UIList List;
var UILargeButton ContinueButton;

var XComGameState			StartState;
var XComGameState_Player XComPlayerState;
var XComGameState_HeadquartersXCom HeadquartersStateObject;

//Map setup managers
var int ProcLevelSeed;   //Random seed to use when building levels
var X2ChallengeTemplateManager ChallengeTemplateManager;
var XComEnvLightingManager      EnvLightingManager;
var XComTacticalMissionManager  TacticalMissionManager;
var XComParcelManager           ParcelManager;

//Game state objects
var XComGameStateHistory        History;
var XComGameState_BattleData    BattleDataState;
var XComGameState_MissionSite	ChallengeMissionSite;
var XComGameState_CampaignSettings CampaignSettings;

var EUISkirmishScreen m_CurrentState;
var string MapImagePath;
var Object MapImage;

// used to debug TacticalGameplayTags applied before mission begins
var array<Name> TacticalGameplayTags;

var int	m_SelectedSoldier, m_SelectedSoldierClass, m_SelectedEnemy, m_previouslySelectedEnemy, m_SelectedMissionType,  m_currentBiome;
var string MapTypeString;
var string BiomeTypeString;
var config array<name> m_FilteredMissions;
var array<XComGameState_Unit> m_CurrentSquad;
var array<SCATProgression> m_arrProgression;
var array<X2SoldierClassTemplate> ClassTemplates;
var array<X2StrategyElementTemplate> UnlockTemplates;

var localized string m_arrSubtitles[EUISkirmishScreen] <BoundEnum = EUISkirmishScreen>;

var localized string m_StartGame;
var localized string m_EditSquad;
var localized string m_EditMap;
var localized string m_EditMissionType;
var localized string m_EditMapType;
var localized string m_EditBiome;
var localized string m_EditEnemies;
var localized string m_EditDifficulty;
var localized string m_ScreenTitle;
var localized string m_SquadLabel;
var localized string m_SquadGeneralDescription;
var localized string m_SoldiersFactionLabel;
var localized string m_SoldiersFactionDescription;
var localized string m_EnemyLabel;
var localized string m_PCSLabel;
var localized string m_UtilityLabel;
var localized string m_ObjectiveLabel;
var localized string m_RemoveUnit;
var localized string m_EditAbilities;
var localized string m_EditEquipment;
var localized string m_ChangeClass;
var localized string m_EditRank;
var localized string m_AddUnit;
var localized string m_EditUnit;

var localized string m_PrimaryWeapon;
var localized string m_SecondaryWeapon;
var localized string m_UtilItem1;
var localized string m_UtilItem2;
var localized string m_GrenadierGrenade;
var localized string m_ArmorLabel;
var localized string m_HeavyWeaponLabel;

var localized string m_strWillLabel;
var localized string m_strAimLabel;
var localized string m_strHealthLabel;
var localized string m_strMobilityLabel;
var localized string m_strTechLabel;
var localized string m_strArmorLabel;
var localized string m_strDodgeLabel;
var localized string m_strPsiLabel;

var localized string m_strPrimaryLabel;
var localized string m_strSecondaryLabel;
var localized string m_strUtilLabel;

var localized string m_DestructiveActionTitle;
var localized string m_DestructiveActionBody;

var localized string m_NeedHumanSoldierTitle;
var localized string m_NeedHumanSoldierBody;

var localized string m_RemoveSoldierTitle;
var localized string m_RemoveSoldierBody;
var localized string m_strPCSNone;
var localized string m_Random;

var config array<string> MapTypeNames;
var config array<string> BiomeTypeNames;

static function string GetLocalizedMapTypeName( string MapName )
{
	local int i;

	for (i = 0; i < default.MapTypeNames.Length; ++i)
	{
		if (default.MapTypeNames[i] == MapName)
			return class'X2MPData_Shell'.default.arrMPMapFriendlyNames[ i ];
	}

	return "Unlocalized:"$MapName;
}

private static function string GetLocalizedBiomeTypeName( string BiomeName )
{
	local int i;

	for (i = 0; i < default.MapTypeNames.Length; ++i)
	{
		if (default.BiomeTypeNames[i] == BiomeName)
			return class'X2MPData_Shell'.default.arrMPBiomeFriendlyNames[ i ];
	}

	return "Unlocalized:"$BiomeName;
}

simulated function OnSetSelectedIndex(UIList ContainerList, int ItemIndex)
{
	if (m_CurrentState == eUISkirmishScreen_Squad)
	{
		m_SelectedSoldier = m_CurrentSquad.Length < 6 ? ItemIndex - 1 : ItemIndex;
		RefreshSquadDetailsPanel();
	}
	if (m_CurrentState == eUISkirmishScreen_Enemies)
	{
		m_SelectedEnemy = ItemIndex;
		UpdateEnemyPortraits();
	}
	if( m_CurrentState == eUISkirmishScreen_SoldierAbilities )
	{
		UpdateAbilityInfo(ItemIndex);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_KEY_ENTER, arg);
		return true;
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		OnCancel();
		bHandled = true;
		break;
		
	case class'UIUtilities_Input'.const.FXS_DPAD_UP :
	case class'UIUtilities_Input'.const.FXS_ARROW_UP :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP :
	case class'UIUtilities_Input'.const.FXS_KEY_W :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_UP, arg);
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN :
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN :
	case class'UIUtilities_Input'.const.FXS_KEY_S :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_DOWN, arg);
		break;

	default:
		bHandled = false;
		break;
	}

	if( !bHandled && Navigator.GetSelected() != none && Navigator.GetSelected().OnUnrealCommand(cmd, arg) )
	{
		bHandled = true;
	}


	// always give base class a chance to handle the input so key input is propogated to the panel's navigator
	return (bHandled || super.OnUnrealCommand(cmd, arg));
}

function InitHistory()
{
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState_Player EnemyPlayerState;
	local XComGameState_Player CivilianPlayerState;
	local XComGameState_Player TheLostPlayerState;
	local XComGameState_Player ResistancePlayer;
	local XComGameState_Analytics Analytics;
	local MissionDefinition MissionDef;
	local array<name> PrevSelectors;
	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local string sType;
	local PlotTypeDefinition PlotType;
	local XComOnlineEventMgr EventManager;
	local int i, MissionDefIndex;
	local X2MissionTemplateManager MissionTemplateManager;
	local array<name> missionNames;

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplateManager.GetTemplateNames(missionNames);

	for (i = 0; i < m_FilteredMissions.Length; i++)
	{
		missionNames.RemoveItem(m_FilteredMissions[i]);
	}
	
	History = `XCOMHISTORY;
	History.ResetHistory(, false);

	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);
	History.AddGameStateToHistory(StartState);

	BattleDataState = XComGameState_BattleData(StartState.CreateNewStateObject(class'XComGameState_BattleData'));

	//Add basic states to the start state ( battle, players, abilities, etc. )
	BattleDataState.iLevelSeed = class'Engine'.static.GetEngine().GetSyncSeed();
	BattleDataState.bIsTacticalQuickLaunch = true;

	BattleDataState.LostSpawningLevel = BattleDataState.SelectLostActivationCount();
	BattleDataState.m_strMapCommand = "open" @ BattleDataState.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";
	BattleDataState.BizAnalyticsMissionID = `FXSLIVE.GetGUID();

	m_SelectedMissionType = `SYNC_RAND_STATIC( missionNames.Length );
	MissionDefIndex = TacticalMissionManager.arrMissions.Find('MissionName', missionNames[m_SelectedMissionType]);
	sType = TacticalMissionManager.arrMissions[MissionDefIndex].sType;

	BattleDataState.m_iMissionType = TacticalMissionManager.arrMissions.Find('sType', sType);
	BattleDataState.m_nQuestItem = class'XComGameState_LadderProgress'.static.SelectQuestItem(sType);

	if (!TacticalMissionManager.GetMissionDefinitionForType(sType, MissionDef))
	{
		`Redscreen("CreateNewLadder(): Mission Type " $ sType $ " has no definition!");
		return;
	}

	BattleDataState.MapData.ActiveMission = MissionDef;
	TacticalMissionManager.ForceMission = MissionDef;

	// pick our new map
	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef);
	if (ValidPlots.Length == 0)
	{
		`Redscreen("TransferToNewMission(): Could not find a plot to transfer to for mission type " $ sType $ "!");
		return;
	}

	NewPlot = ValidPlots[`SYNC_RAND(ValidPlots.Length)];
	PlotType = ParcelManager.GetPlotTypeDefinition(NewPlot.strType);

	SelectRandomBiome(NewPlot);

	BattleDataState.MapData.PlotMapName = NewPlot.MapName;
	MapTypeString = NewPlot.strType;

	MapImagePath = `MAPS.SelectMapImage(NewPlot.strType);

	BattleDataState.ActiveSitReps = MissionDef.ForcedSitreps;
	class'XComGameState_LadderProgress'.static.AppendNames( BattleDataState.ActiveSitReps, PlotType.ForcedSitReps );
	ChallengeMissionSite.GeneratedMission.SitReps = BattleDataState.ActiveSitReps;

	// Civilians are always pro-advent
	BattleDataState.SetPopularSupport(0);
	BattleDataState.SetMaxPopularSupport(1);

	BattleDataState.m_strDesc = "Skirmish Mode"; // if this is changed, note that it controls a path through TacticalOnlyGameMode( )
	BattleDataState.m_strOpName = class'XGMission'.static.GenerateOpName(false);
	BattleDataState.m_strMapCommand = "open" @ BattleDataState.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";

	XComPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_XCom);
	XComPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());

	EnemyPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Alien);
	EnemyPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(EnemyPlayerState.GetReference());

	CivilianPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Neutral);
	CivilianPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.CivilianPlayerRef = CivilianPlayerState.GetReference();

	TheLostPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_TheLost);
	TheLostPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(TheLostPlayerState.GetReference());

	ResistancePlayer = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Resistance);
	ResistancePlayer.bPlayerReady = true;
	BattleDataState.PlayerTurnOrder.AddItem(ResistancePlayer.GetReference());


	// create a default cheats object
	StartState.CreateNewStateObject(class'XComGameState_Cheats');

	Analytics = XComGameState_Analytics(StartState.CreateNewStateObject(class'XComGameState_Analytics'));
	Analytics.SubmitToFiraxisLive = false;

	CampaignSettings = XComGameState_CampaignSettings(StartState.CreateNewStateObject(class'XComGameState_CampaignSettings'));
	CampaignSettings.SetDifficulty(1); // Force challenge mode to 'Commander' difficulty
	CampaignSettings.SetSuppressFirstTimeNarrativeEnabled(true);
	CampaignSettings.SetTutorialEnabled(false);
	CampaignSettings.SetGameIndexFromProfile( );
	CampaignSettings.BizAnalyticsCampaignID = `FXSLIVE.GetGUID();
	CampaignSettings.SetStartTime( class'XComCheatManager'.static.GetCampaignStartTime() );
	
	EventManager = `ONLINEEVENTMGR;
	for(i = EventManager.GetNumDLC() - 1; i >= 0; i--)
	{
		CampaignSettings.AddRequiredDLC( EventManager.GetDLCNames(i) );
	}

	HeadquartersStateObject = XComGameState_HeadquartersXCom(StartState.CreateNewStateObject(class'XComGameState_HeadquartersXCom'));
	HeadquartersStateObject.AdventLootWeight = class'XComGameState_HeadquartersXCom'.default.StartingAdventLootWeight;
	HeadquartersStateObject.AlienLootWeight = class'XComGameState_HeadquartersXCom'.default.StartingAlienLootWeight;
	HeadquartersStateObject.bHasPlayedAmbushTutorial = true;
	HeadquartersStateObject.bHasPlayedMeleeTutorial = true;
	HeadquartersStateObject.bHasPlayedNeutralizeTargetTutorial = true;
	HeadquartersStateObject.SetGenericKeyValue("NeutralizeTargetTutorial", 1);

	StartState.CreateNewStateObject(class'XComGameState_ObjectivesList');

	class'XComGameState_HeadquartersResistance'.static.SetUpHeadquarters(StartState, false);

	class'XComGameState_HeadquartersAlien'.static.SetUpHeadquarters(StartState);

	class'XComGameState_GameTime'.static.CreateGameStartTime(StartState);

	ChallengeTemplateManager = class'X2ChallengeTemplateManager'.static.GetChallengeTemplateManager();
	
	AddRandomSoldiers(StartState, PrevSelectors);

	SetupChallengeMissionSite(StartState, BattleDataState);

	UpdateDataSquad();

}

function AddRandomSoldiers(XComGameState LocalStartState, out array<name> PrevSelectors)
{
	local X2ChallengeSoldierRank RankSelector;
	local X2ChallengeArmor ArmorSelector;
	local X2ChallengePrimaryWeapon PrimaryWeaponSelector;
	local X2ChallengeSecondaryWeapon SecondaryWeaponSelector;
	local X2ChallengeUtility UtilityItemSelector;
	local int i;

	for (i = 0; i < 4; ++i)
	{
		AddRandomUnit();
	}

	RankSelector = X2ChallengeSoldierRank(GetChallengeTemplate('ChallengeRank_OneHighRestLowRank', class'X2ChallengeSoldierRank', ChallengeTemplateManager));
	class'X2ChallengeSoldierRank'.static.SelectSoldierRanks(RankSelector, m_CurrentSquad, StartState);

	ArmorSelector = X2ChallengeArmor(GetChallengeTemplate('TLEArmor', class'X2ChallengeArmor', ChallengeTemplateManager));
	class'X2ChallengeArmor'.static.SelectSoldierArmor(ArmorSelector, m_CurrentSquad, StartState);

	PrimaryWeaponSelector = X2ChallengePrimaryWeapon(GetChallengeTemplate('TLEPrimaryRandom', class'X2ChallengePrimaryWeapon', ChallengeTemplateManager));
	class'X2ChallengePrimaryWeapon'.static.SelectSoldierPrimaryWeapon(PrimaryWeaponSelector, m_CurrentSquad, StartState);

	SecondaryWeaponSelector = X2ChallengeSecondaryWeapon(GetChallengeTemplate('TLESecondaryRandom', class'X2ChallengeSecondaryWeapon', ChallengeTemplateManager));
	class'X2ChallengeSecondaryWeapon'.static.SelectSoldierSecondaryWeapon(SecondaryWeaponSelector, m_CurrentSquad, StartState);

	UtilityItemSelector = X2ChallengeUtility(GetChallengeTemplate('ChallengeTLEUtilityItems', class'X2ChallengeUtility', ChallengeTemplateManager));
	class'X2ChallengeUtility'.static.SelectSoldierUtilityItems(UtilityItemSelector, m_CurrentSquad, StartState);

	
}

simulated function XComGameState_Unit CreateUnit(name Classname)
{
	local X2SoldierClassTemplate ClassTemplate;
	local X2CharacterTemplate CharTemplate;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_Unit BuildUnit;
	local TSoldier Soldier;
	local name RequiredLoadout;

	ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Classname);
	`assert(ClassTemplate != none);

	CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate((ClassTemplate.RequiredCharacterClass != '') ? ClassTemplate.RequiredCharacterClass : 'Soldier');
	`assert(CharTemplate != none);
	CharacterGenerator = `XCOMGRI.Spawn(CharTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != None);

	BuildUnit = CharTemplate.CreateInstanceFromTemplate(StartState);
	BuildUnit.bRolledForAWCAbility = true;	// Do not allow AWC abilities to be added to skirmish units
	BuildUnit.SetSoldierClassTemplate(ClassTemplate.DataName);
	BuildUnit.SetControllingPlayer(XComPlayerState.GetReference());

	// Randomly roll what the character looks like
	Soldier = CharacterGenerator.CreateTSoldier();
	BuildUnit.SetTAppearance(Soldier.kAppearance);
	BuildUnit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
	BuildUnit.SetCountry(Soldier.nmCountry);
	if (!BuildUnit.HasBackground())
		BuildUnit.GenerateBackground(, CharacterGenerator.BioCountryName);

	HeadquartersStateObject.Squad.AddItem(BuildUnit.GetReference());
	HeadquartersStateObject.AddToCrewNoStrategy(BuildUnit);

	RequiredLoadout = CharTemplate.RequiredLoadout;
	if (RequiredLoadout != '')
	{
		BuildUnit.ApplyInventoryLoadout(StartState, RequiredLoadout);
	}

	CharacterGenerator.Destroy( );

	return BuildUnit;
}

simulated function AddRandomUnit()
{
	local X2ChallengeSoldierClass ClassSelector;
	local array<name> ClassNames;
	local XComGameState_Unit NewUnit;

	ClassSelector = X2ChallengeSoldierClass(GetChallengeTemplate('TLESoldiersRandom', class'X2ChallengeSoldierClass', ChallengeTemplateManager));
	ClassNames = class'X2ChallengeSoldierClass'.static.SelectSoldierClasses(ClassSelector, 1);

	NewUnit = CreateUnit( ClassNames[0] );

	m_CurrentSquad.AddItem( NewUnit );
}

simulated function X2ChallengeTemplate GetChallengeTemplate(name TemplateName, class<X2ChallengeTemplate> TemplateType, X2ChallengeTemplateManager TemplateManager, optional array<name> PrevSelectorNames)
{
	local X2ChallengeTemplate Template;

	if (TemplateName == '')
	{
		Template = TemplateManager.GetRandomChallengeTemplateOfClass(TemplateType);
	}
	else
	{
		Template = TemplateManager.FindChallengeTemplate(TemplateName);
	}

	`assert( Template != none );

	return Template;
}

function SetupChallengeMissionSite(XComGameState LocalStartState, XComGameState_BattleData OldBattleData)
{
	local XComGameState_Continent Continent;
	local XComGameState_WorldRegion Region;

	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> ContinentDefinitions;
	local X2ContinentTemplate RandContinentTemplate;
	local X2WorldRegionTemplate RandRegionTemplate;

	local int RandContinent, RandRegion;
	local Vector CenterLoc, RegionExtents;

	// Disable standard reinforcements
	BattleDataState.ActiveSitReps.AddItem('ChallengeNoReinforcements');

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ContinentDefinitions = StratMgr.GetAllTemplatesOfClass(class'X2ContinentTemplate');

	RandContinent = `SYNC_RAND(ContinentDefinitions.Length);
	RandContinentTemplate = X2ContinentTemplate(ContinentDefinitions[RandContinent]);

	RandRegion = `SYNC_RAND( RandContinentTemplate.Regions.Length );
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
	ChallengeMissionSite.Location = CenterLoc + (`SYNC_VRAND() * RegionExtents);
	ChallengeMissionSite.Continent.ObjectID = Continent.ObjectID;
	ChallengeMissionSite.Region.ObjectID = Region.ObjectID;

	ChallengeMissionSite.GeneratedMission.MissionID = ChallengeMissionSite.ObjectID;
	ChallengeMissionSite.GeneratedMission.Mission = `TACTICALMISSIONMGR.arrMissions[BattleDataState.m_iMissionType];
	ChallengeMissionSite.GeneratedMission.LevelSeed = BattleDataState.iLevelSeed;
	ChallengeMissionSite.GeneratedMission.BattleOpName = BattleDataState.m_strOpName;
	ChallengeMissionSite.GeneratedMission.BattleDesc = "Skirmish Mode";
	ChallengeMissionSite.GeneratedMission.MissionQuestItemTemplate = BattleDataState.m_nQuestItem;
	ChallengeMissionSite.GeneratedMission.SitReps = BattleDataState.ActiveSitReps;

	BattleDataState.m_iMissionID = ChallengeMissionSite.ObjectID;
}

function UIMechaListItem GetListItem(int ItemIndex, optional bool bDisableItem, optional string DisabledReason)
{
	local UIMechaListItem CustomizeItem;
	local UIPanel Item;

	if (ItemIndex >= List.ItemContainer.ChildPanels.Length)
	{
		CustomizeItem = Spawn(class'UIMechaListItem', List.itemContainer);
		CustomizeItem.bAnimateOnInit = false;
		CustomizeItem.InitListItem(, , 400);
	}
	else
	{
		Item = List.GetItem(ItemIndex);
		CustomizeItem = UIMechaListItem(Item);
	}
	
	return CustomizeItem;
}

simulated private function OnButtonStartBattleClicked(UIButton MyButton)
{
	local bool bAllSparks;
	local XComGameState_Unit SoldierUnit;
	local int i, MissionDefIndex;
	local X2MissionTemplateManager MissionTemplateManager;
	local array<name> missionNames;
	local MissionDefinition MissionDef;
	local string sType;
	
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplateManager.GetTemplateNames(missionNames);

	for (i = 0; i < m_FilteredMissions.Length; i++)
	{
		missionNames.RemoveItem(m_FilteredMissions[i]);
	}

	bAllSparks = true;

	if (m_CurrentSquad.Length > 0)
	{
		MissionDefIndex = TacticalMissionManager.arrMissions.Find('MissionName', missionNames[m_SelectedMissionType]);
		sType = TacticalMissionManager.arrMissions[MissionDefIndex].sType;

		TacticalMissionManager.GetMissionDefinitionForType(sType, MissionDef);

		for(i = 0; i < m_CurrentSquad.Length; i++)
		{
			SoldierUnit = m_CurrentSquad[i];
			if (SoldierUnit.GetMyTemplateName() != 'SparkSoldier')
			{
				bAllSparks = false;
			}
		}
		
		if ((MissionDef.MissionName == 'AdventFacilityFORGE' || MissionDef.MissionName == 'CompoundRescueOperative') && bAllSparks)
		{
			NeedHumanPopup();
		}
		else
		{
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			`ONLINEEVENTMGR.bGenerateMapForSkirmish = true;
			CreateNewLadder(2);
		}
	}
}

function NeedHumanPopup()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.strTitle = m_NeedHumanSoldierTitle;
	kConfirmData.strText = m_NeedHumanSoldierBody;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnNeedHumanPopupExitDialog;

	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnNeedHumanPopupExitDialog(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		`ONLINEEVENTMGR.bGenerateMapForSkirmish = true;
		CreateNewLadder(2);
	}
}

function HideListItems()
{
	local int i;
	
	for (i = 0; i < List.ItemCount; ++i)
	{
		List.GetItem(i).Destroy();
	}

	List.ClearItems();
}

simulated function OnReceiveFocus()
{
	UpdateNavHelp();
	super.OnReceiveFocus();
}

simulated function UpdateData()
{
	mc.FunctionString("SetScreenTitle", m_ScreenTitle);
	mc.FunctionString("SetScreenSubtitle", m_arrSubtitles[m_CurrentState]);
	
	HideListItems();
	List.OnSelectionChanged = OnDefaultSelectionChanged;
	
	switch (m_CurrentState)
	{
	case eUISkirmishScreen_Base:
		UpdateDataBase();
		break;
	case eUISkirmishScreen_Squad:
		UpdateDataSquad();
		break;
	case eUISkirmishScreen_SoldierData:
		UpdateDataSoldierData();
		UpdateEditSoldierMenuItems();
		break;
	case eUISkirmishScreen_SoldierClass:
		UpdateDataSoldierClass();
		break;
	case eUISkirmishScreen_SoldierAbilities:
		UpdateDataSoldierAbilities();
		break;
	case eUISkirmishScreen_SoldierEquipment:
		UpdateDataSoldierEquipment();
		break;
	case eUISkirmishScreen_SoldierRank:
		UpdateDataSoldierRank();
		break;
	case eUISkirmishScreen_PrimaryWeapon:
		UpdateDataPrimaryWeapon();
		break;
	case eUISkirmishScreen_SecondaryWeapon:
		UpdateDataSecondaryWeapon();
		break;
	case eUISkirmishScreen_Armor:
		UpdateDataArmor();
		break;
	case eUISkirmishScreen_PCS:
		UpdateDataPCS();
		break;
	case eUISkirmishScreen_UtilItem1:
		UpdateDataUtilItem1();
		break;
	case eUISkirmishScreen_UtilItem2:
		UpdateDataUtilItem2();
		break;
	case eUISkirmishScreen_GrenadePocket:
		UpdateDataGrenadePocket();
		break;
	case eUISkirmishScreen_HeavyWeapon:
		UpdateDataHeavyWeapon();
		break;
	case eUISkirmishScreen_MapData:
		UpdateDataMapData();
		break;
	case eUISkirmishScreen_Enemies:
		UpdateDataEnemies();
		break;
	case eUISkirmishScreen_Map:
		UpdateDataMap();
		break;
	case eUISkirmishScreen_Mission:
		UpdateDataMission();
		break;
	case EUISkirmishScreen_Biome:
		UpdateDataBiome();
		break;
	case eUISkirmishScreen_Difficulty:
		UpdateDataDifficulty();
		break;
	};

	if( List.IsSelectedNavigation() )
		List.Navigator.SelectFirstAvailable();
}

simulated function UpdateDataPCS()
{
	local int i, index;
	local X2ChallengeUtility PrimaryWeaponSelector;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	PrimaryWeaponSelector = X2ChallengeUtility(GetChallengeTemplate('ChallengeTLEPCSItems', class'X2ChallengeUtility', ChallengeTemplateManager));

	index = 0;
	
	//Add a NONE option 
	GetListItem(0).EnableNavigation();
	GetListItem(index).metadataString = m_strPCSNone;
	GetListItem(index++).UpdateDataValue(m_strPCSNone, "", , , OnClickNewPCS);

	for (i = 1; i < PrimaryWeaponSelector.UtilitySlot.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PrimaryWeaponSelector.UtilitySlot[i].templatename));

		if (EquipmentTemplate != none)
		{
			GetListItem(i).EnableNavigation();
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewPCS);
		}
	}
}

simulated function OnClickNewPCS(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;
	local array<XComGameState_Item> Items;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	Items = m_CurrentSquad[m_SelectedSoldier].GetAllItemsInSlot(eInvSlot_CombatSim, StartState, true, true);

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	if( Items[0] != none )
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(Items[0], StartState);

	if(selectedIndex == 0 )
	{
		//NONE option selected, do not add any PCS 
	}
	else
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(name(GetListItem(selectedIndex).metadataString)));
		`assert( EquipmentTemplate != none );

		NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);

		m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_CombatSim, StartState);
	}

	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

simulated function UpdateDataMap()
{
	local array<PlotDefinition> ValidPlots;
	local array<string> plotNames;
	local string friendlyName;
	local int i;

	ParcelManager.GetValidPlotsForMission(ValidPlots, BattleDataState.MapData.ActiveMission);

	for (i = 0; i< ValidPlots.Length; I++)
	{
		friendlyName = ValidPlots[i].strType;
		if(plotNames.Find(friendlyName) == -1)
			plotNames.AddItem(friendlyName);
	}

	for (i = 0; i < plotNames.Length; i++)
	{
		GetListItem(i).UpdateDataValue( GetLocalizedMapTypeName( plotNames[i] ), "", , , OnClickMap);
		GetListItem(i).EnableNavigation();
	}
}

simulated function OnClickMap(UIMechaListItem MechaItem)
{
	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local array<string> plotNames;
	local string friendlyName;
	local string plotIndex;
	local int i;
	local PlotTypeDefinition PlotType;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	ParcelManager.GetValidPlotsForMission(ValidPlots, BattleDataState.MapData.ActiveMission);

	for (i = 0; i < ValidPlots.Length; i++)
	{
		friendlyName = ValidPlots[i].strType;
		if (plotNames.Find(friendlyName) == -1)
			plotNames.AddItem(friendlyName);
	}

	plotIndex = plotNames[selectedIndex];
	do
	{
		NewPlot = ValidPlots[`SYNC_RAND(ValidPlots.Length)];
	} until(NewPlot.strType == plotIndex);

	PlotType = ParcelManager.GetPlotTypeDefinition(NewPlot.strType);

	SelectRandomBiome(NewPlot);

	BattleDataState.ActiveSitReps = ChallengeMissionSite.GeneratedMission.Mission.ForcedSitreps;
	class'XComGameState_LadderProgress'.static.AppendNames( BattleDataState.ActiveSitReps, PlotType.ForcedSitReps );
	ChallengeMissionSite.GeneratedMission.SitReps = BattleDataState.ActiveSitReps;

	BattleDataState.MapData.PlotMapName = NewPlot.MapName;
	MapTypeString = NewPlot.strType;
	MapImagePath = `MAPS.SelectMapImage(NewPlot.strType);

	BattleDataState.m_strMapCommand = "open" @ BattleDataState.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";

	m_CurrentState = eUISkirmishScreen_MapData;
	UpdateData();
}

simulated function UpdateDataMission()
{
	local int i;
	local X2MissionTemplateManager MissionTemplateManager;
	local array<name> missionNames;
	local X2MissionTemplate MissionTemplate;
	local name TempMissionName;

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplateManager.GetTemplateNames(missionNames);

	for (i = 0; i < m_FilteredMissions.Length; i++)
	{
		missionNames.RemoveItem(m_FilteredMissions[i]);
	}

	//missionNames.RemoveItem()
	for (i = 0; i < missionNames.Length; i++)
	{
		MissionTemplate = MissionTemplateManager.FindMissionTemplate(missionNames[i]);
		GetListItem(i).UpdateDataValue(MissionTemplate.DisplayName, "", , , OnClickMission);
		GetListItem(i).EnableNavigation();

		TempMissionName = missionNames[i];
		GetListItem(i).metadataString = string(TempMissionName);
	}
}

simulated function OnClickMission(UIMechaListItem MechaItem)
{
	local MissionDefinition MissionDef;
	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local string sType;
	local PlotTypeDefinition PlotType;
	local int MissionDefIndex;
	
	for (m_SelectedMissionType = 0; m_SelectedMissionType < List.ItemContainer.ChildPanels.Length; m_SelectedMissionType++)
	{
		if (GetListItem(m_SelectedMissionType) == MechaItem)
			break;
	}

	MissionDefIndex = TacticalMissionManager.arrMissions.Find('MissionName', name(GetListItem(m_SelectedMissionType).metadataString));
	sType = TacticalMissionManager.arrMissions[MissionDefIndex].sType;

	BattleDataState.m_iMissionType = TacticalMissionManager.arrMissions.Find('sType', sType);
	BattleDataState.m_nQuestItem = class'XComGameState_LadderProgress'.static.SelectQuestItem(sType);
	ChallengeMissionSite.GeneratedMission.MissionQuestItemTemplate = BattleDataState.m_nQuestItem;

	if (!TacticalMissionManager.GetMissionDefinitionForType(sType, MissionDef))
	{
		`Redscreen("CreateNewLadder(): Mission Type " $ sType $ " has no definition!");
			return;
	}

	BattleDataState.MapData.ActiveMission = MissionDef;
	TacticalMissionManager.ForceMission = MissionDef;
	ChallengeMissionSite.GeneratedMission.Mission = MissionDef;

	// pick our new map
	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef);
	if (ValidPlots.Length == 0)
	{
		`Redscreen("TransferToNewMission(): Could not find a plot to transfer to for mission type " $ sType $ "!");
		return;
	}

	NewPlot = ValidPlots[`SYNC_RAND(ValidPlots.Length)];
	PlotType = ParcelManager.GetPlotTypeDefinition(NewPlot.strType);

	SelectRandomBiome(NewPlot);

	BattleDataState.MapData.PlotMapName = NewPlot.MapName;
	MapTypeString = NewPlot.strType;
	
	BattleDataState.ActiveSitReps = MissionDef.ForcedSitreps;
	class'XComGameState_LadderProgress'.static.AppendNames( BattleDataState.ActiveSitReps, PlotType.ForcedSitReps );
	ChallengeMissionSite.GeneratedMission.SitReps = BattleDataState.ActiveSitReps;

	MapImagePath = `MAPS.SelectMapImage(NewPlot.strType);

	BattleDataState.m_strMapCommand = "open" @ BattleDataState.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";

	m_CurrentState = eUISkirmishScreen_MapData;
	UpdateData();
}

simulated function SelectRandomBiome(PlotDefinition InPlot)
{
	local array<string> AvailableBiomes;
	local bool bWildernessMap;
	local int i;

	bWildernessMap = InPlot.strType == "Wilderness";

	if (InPlot.ValidBiomes.Length > 0)
	{
		for (i = 0; i < InPlot.ValidBiomes.Length; ++i)
		{
			if (!bWildernessMap && InPlot.ValidBiomes[i] == "Xenoform") continue;

			AvailableBiomes.AddItem(InPlot.ValidBiomes[i]);
		}

		m_currentBiome = `SYNC_RAND(AvailableBiomes.Length);
		BattleDataState.MapData.Biome = AvailableBiomes[m_currentBiome];
		BiomeTypeString = BattleDataState.MapData.Biome;
	}
	else
	{
		BiomeTypeString = "";
	}
}

simulated function UpdateDataBiome()
{
	local PlotDefinition Plot;
	local int i;
	local bool bWildernessMap;

	Plot = ParcelManager.GetPlotDefinition( MapTypeString );
	
	bWildernessMap = MapTypeString == "Wilderness";

	for (i = 0; i < Plot.ValidBiomes.Length; ++i)
	{
		if(!bWildernessMap && Plot.ValidBiomes[i] == "Xenoform") continue;

		GetListItem(i).UpdateDataValue( GetLocalizedBiomeTypeName( Plot.ValidBiomes[i] ), "", , , OnClickBiome);
		GetListItem(i).metadataString = Plot.ValidBiomes[i];
		GetListItem(i).EnableNavigation();
	}
	List.OnSelectionChanged = OnBiomeSelectionChanged; 
}

simulated function OnBiomeSelectionChanged(UIList listControl, int itemIndex)
{
	local PlotDefinition Plot;

	if( itemIndex > -1 )
	{
		Plot = ParcelManager.GetPlotDefinition(MapTypeString);
		MapImagePath = `MAPS.SelectMapImage(Plot.strType, Plot.ValidBiomes[itemIndex]);
		UpdateGeneralMissionInfoPanel(); 
	}
}

simulated function OnDefaultSelectionChanged(UIList listControl, int itemIndex)
{
	//Do nothing for now 
}

simulated function OnClickBiome( UIMechaListItem MechaItem)
{
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	m_currentBiome = selectedIndex;
	BattleDataState.MapData.Biome = GetListItem( m_currentBiome ).metadataString;
	BiomeTypeString = BattleDataState.MapData.Biome;
	UpdateGeneralMissionInfoPanel();

	m_CurrentState = eUISkirmishScreen_MapData;
	UpdateData();
}

simulated function OnClickEditSquad()
{
	m_CurrentState = eUISkirmishScreen_Squad;
	UpdateData();
}

simulated function OnClickAddUnit()
{
	AddRandomUnit();
	GiveUnitBasicEquipment(m_CurrentSquad[m_CurrentSquad.Length - 1]);
	m_CurrentState = eUISkirmishScreen_Squad;
	UpdateData();
}

simulated function OnClickEditMap()
{
	m_CurrentState = eUISkirmishScreen_MapData;
	UpdateData();
}

simulated function OnClickEditEnemies()
{
	m_CurrentState = eUISkirmishScreen_Enemies;
	UpdateData();
}

simulated function OnClickEditDifficulty()
{
	m_CurrentState = eUISkirmishScreen_Difficulty;
	UpdateData();
}

simulated function OnClickChangeClass()
{
	m_CurrentState = eUISkirmishScreen_SoldierClass;
	UpdateData();
}


simulated function UpdateGeneralMissionInfoPanel()
{
	local StateObjectReference UnitStateRef;
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate SoldierClass;
	local Texture2D SoldierPicture;
	local XComGameState_CampaignSettings CurrentCampaign;

	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;
	local array<X2ChallengeTemplate> Templates;
	local int index;

	index = 0;

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(BattleDataState.MapData.ActiveMission.MissionName);
	Templates = ChallengeTemplateManager.GetAllTemplatesOfClass(class'X2ChallengeEnemyForces');
	
	mc.FunctionVoid("HideAllScreens");
	mc.BeginFunctionOp("SetMissionInfo");
	
	mc.QueueString("img:///"$MapImagePath); // big image
	mc.QueueString(BattleDataState.m_strOpName);// mission name

	mc.QueueString(""); //XCOM squad
	mc.QueueString(m_EnemyLabel);
	mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(X2ChallengeEnemyForces(Templates[m_SelectedEnemy]).DisplayName));
	mc.QueueString(X2ChallengeEnemyForces(Templates[m_SelectedEnemy]).Description);


	mc.QueueString(m_ObjectiveLabel);
	mc.QueueString(MissionTemplate.DisplayName);
	mc.QueueString(m_StartGame);
	mc.EndOp();


	CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	for( index = 0; index < m_CurrentSquad.Length; index++ )
	{
		UnitState = m_CurrentSquad[index];
		UnitStateRef = UnitState.GetReference();
		SoldierClass = UnitState.GetSoldierClassTemplate();

		if( UnitState.bMissionProvided ) // skip mission added units like VIPs
			continue;

		mc.BeginFunctionOp("SetMissionSoldierInfo");
		MC.QueueNumber(index);

		SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(CurrentCampaign.GameIndex, UnitStateRef.ObjectID, 128, 128);
		if( SoldierPicture != none )
		{
			MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture))); // Picture Image
		}
		else
		{
			MC.QueueString(""); // Picture Image
		}

		MC.QueueString(SoldierClass.IconImage); //Class Icon Image
		MC.QueueString(class'UIUtilities_Image'.static.GetRankIcon(UnitState.GetRank(), UnitState.GetSoldierClassTemplateName())); //Rank image
		MC.QueueString(UnitState.GetFullName()); //Unit Name
		MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(SoldierClass.DisplayName)); //Class Name
		MC.EndOp();
	}

	while (index < 6)
	{
		mc.BeginFunctionOp("SetMissionSoldierInfo");
		MC.QueueNumber(index);
		MC.QueueString("");
		MC.QueueString(""); 
		MC.QueueString(""); 
		MC.QueueString("");
		MC.QueueString("");
		MC.EndOp();

		index++;
	}
}




simulated function UpdateDataBase()
{
	local int index; 
	local string DifficultyString; 
	local string sType;
	local int i, MissionDefIndex;
	local X2MissionTemplateManager MissionTemplateManager;
	local array<name> missionNames;

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplateManager.GetTemplateNames(missionNames);

	for (i = 0; i < m_FilteredMissions.Length; i++)
	{
		missionNames.RemoveItem(m_FilteredMissions[i]);
	}

	UpdateGeneralMissionInfoPanel();

	index = 0; 
	GetListItem(index).EnableNavigation();
	GetListItem(index++).UpdateDataValue(m_EditSquad, "", OnClickEditSquad);
	GetListItem(index).EnableNavigation();
	GetListItem(index++).UpdateDataValue(m_EditMap, "", OnClickEditMap);

	MissionDefIndex = TacticalMissionManager.arrMissions.Find('MissionName', missionNames[m_SelectedMissionType]);
	sType = TacticalMissionManager.arrMissions[MissionDefIndex].sType;

	if (sType != "RecoverExpedition") // rescue stranded agents only gets 'the lost'
	{
		GetListItem(index).EnableNavigation();
		GetListItem(index++).UpdateDataValue(m_EditEnemies, "", OnClickEditEnemies);
	}
	
	DifficultyString = class'UIShellDifficulty'.default.m_arrDifficultyTypeStrings[ CampaignSettings.DifficultySetting ];
	GetListItem(index).EnableNavigation();
	GetListItem(index++).UpdateDataValue(m_EditDifficulty, DifficultyString, OnClickEditDifficulty);	
}

simulated function UpdateDataSquad()
{
	local int index, loopIndex;
	index = 0;

	if( m_CurrentSquad.Length < 6 )
	{
		GetListItem(index).EnableNavigation();
		GetListItem(index++).UpdateDataValue(m_AddUnit, "", OnClickAddUnit);
	}

	for( loopIndex = 0; loopIndex < m_CurrentSquad.Length; loopIndex++ )
	{
		GetListItem(index).EnableNavigation();
		GetListItem(index++).UpdateDataValue(m_EditUnit, m_CurrentSquad[loopIndex].GetFullName(), , , OnClickEditUnit);
	}

	mc.FunctionVoid("HideAllScreens");

	RefreshSquadDetailsPanel();
}

simulated function RefreshSquadDetailsPanel()
{
	mc.FunctionVoid("HideAllScreens");

	if( (m_CurrentSquad.length < 6 && List.SelectedIndex == 0) || List.SelectedIndex < 0)
	{
		UpdateDetailsGeneric();
	}
	else
	{
		UpdateDataSoldierData();
	}
}
simulated function UpdateDetailsGeneric()
{
	local XComGameState_ResistanceFaction FactionState;
	local int index; 
	local X2SoldierClassTemplateManager ClassMgr; 
	local X2SoldierClassTemplate SoldierClass; 
	local StackedUIIconData IconData; 
	
	mc.BeginFunctionOp("SetXcomDetails");
	mc.QueueString(m_SquadLabel); // title
	mc.QueueString(m_SquadGeneralDescription);// description
	mc.QueueString(m_SoldiersFactionLabel);// factiontitle
	mc.QueueString(m_SoldiersFactionDescription);//factiondescription
	
	ClassMgr= class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager(); 

	SoldierClass = ClassMgr.FindSoldierClassTemplate('Ranger');
	mc.QueueString(SoldierClass.IconImage);
	mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(SoldierClass.DisplayName));

	SoldierClass = ClassMgr.FindSoldierClassTemplate('Sharpshooter');
	mc.QueueString(SoldierClass.IconImage);
	mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(SoldierClass.DisplayName));

	SoldierClass = ClassMgr.FindSoldierClassTemplate('Specialist');
	mc.QueueString(SoldierClass.IconImage);
	mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(SoldierClass.DisplayName));

	SoldierClass = ClassMgr.FindSoldierClassTemplate('Grenadier');
	mc.QueueString(SoldierClass.IconImage);
	mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(SoldierClass.DisplayName));

	SoldierClass = ClassMgr.FindSoldierClassTemplate('PsiOperative');
	mc.QueueString(SoldierClass.IconImage);
	mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(SoldierClass.DisplayName));

	SoldierClass = ClassMgr.FindSoldierClassTemplate('Spark');
	mc.QueueString(SoldierClass.IconImage);
	mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(SoldierClass.DisplayName));

	mc.EndOp();

	//Faction Icons

	foreach History.IterateByClassType(class'XComGameState_ResistanceFaction', FactionState)
	{
		IconData = FactionState.GetMyTemplate().FactionIconData;  //Default Icon 
		SetFactionIcon(index++, class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(FactionState.GetFactionTitle()), IconData);
	}
}

function SetFactionIcon(int index, string FactionName, StackedUIIconData factionIcon)
{
	local int i;
	MC.BeginFunctionOp("SetFactionIcon");
	MC.QueueNumber(index);
	MC.QueueString(FactionName);
	MC.QueueBoolean(factionIcon.bInvert);
	for( i = 0; i < factionIcon.Images.Length; i++ )
	{
		MC.QueueString("img:///" $ factionIcon.Images[i]);
	}
	MC.EndOp();
}

simulated function OnListSelectionChanged()
{
	if( m_CurrentState == eUISkirmishScreen_Squad )
	{
		RefreshSquadDetailsPanel();
	}
}

simulated function OnClickEditUnit(UIMechaListItem MechaItem)
{
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	m_SelectedSoldier = m_CurrentSquad.Length < 6 ? selectedIndex - 1 : selectedIndex;

	m_CurrentState = eUISkirmishScreen_SoldierData;
	UpdateData();
}

simulated function OnClickRemoveUnit()
{
	local array<XComGameState_Item> inventoryItems;
	local int i;
	inventoryItems = m_CurrentSquad[m_SelectedSoldier].GetAllInventoryItems(StartState);

	for (i = 0; i < inventoryItems.Length; i++)
	{
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(inventoryItems[i], StartState);
	}
	StartState.PurgeGameStateForObjectID(m_CurrentSquad[m_SelectedSoldier].ObjectID, true);
	
	m_CurrentSquad.Remove(m_SelectedSoldier, 1);
	m_CurrentState = eUISkirmishScreen_Squad;

	HeadquartersStateObject.Squad.Remove(m_SelectedSoldier, 1);
	HeadquartersStateObject.RemoveFromCrew( m_CurrentSquad[m_SelectedSoldier].GetReference() );

	UpdateData();
}

simulated function OnClickEditAbilities()
{
	m_CurrentState = eUISkirmishScreen_SoldierAbilities;
	UpdateData();
}

simulated function OnClickEditEquipment()
{
	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

simulated function OnClickEditRank()
{
	m_CurrentState = eUISkirmishScreen_SoldierRank;
	UpdateData();
}

simulated function UpdateDataSoldierData()
{
	mc.FunctionVoid("HideAllScreens");
	mc.BeginFunctionOp("SetSoldierData");
	mc.QueueString("");
	mc.QueueString(m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplate().IconImage);
	mc.QueueString(class'UIUtilities_Image'.static.GetRankIcon(m_CurrentSquad[m_SelectedSoldier].GetSoldierRank(), m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName()));
	mc.QueueString(class'X2ExperienceConfig'.static.GetRankName(m_CurrentSquad[m_SelectedSoldier].GetSoldierRank(), m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName()));
	mc.QueueString(m_CurrentSquad[m_SelectedSoldier].GetFullName()); //Unit Name
	mc.QueueString(m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplate().DisplayName); //Class Name
	mc.EndOp();

	SetSoldierStats();
	SetSoldierGear();
}

simulated function UpdateEditSoldierMenuItems()
{
	local int index;
	index = 0;

	GetListItem(index).EnableNavigation();
	GetListItem(index++).UpdateDataValue(m_RemoveUnit, "", RemoveSoldierPopup);
	GetListItem(index).EnableNavigation();
	GetListItem(index++).UpdateDataValue(m_ChangeClass, "", OnClickChangeClass);
	if (m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName() != 'Rookie')
	{
		GetListItem(index).EnableNavigation();
		GetListItem(index++).UpdateDataValue(m_EditAbilities, "", OnClickEditAbilities);
	}
	GetListItem(index).EnableNavigation();
	GetListItem(index++).UpdateDataValue(m_EditEquipment, "", OnClickEditEquipment);

	if (m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName() != 'Rookie')
	{
		GetListItem(index).EnableNavigation();
		GetListItem(index++).UpdateDataValue(m_EditRank, "", OnClickEditRank);
	}
}

public function SetSoldierStats()
{
	local int WillBonus, AimBonus, HealthBonus, MobilityBonus, TechBonus, PsiBonus, ArmorBonus, DodgeBonus;
	local string Health;
	local string Mobility;
	local string Aim;
	local string Will;
	local string Armor;
	local string Dodge;
	local string Tech;
	local string Psi;
	local XComGameState_Unit Unit;

	Unit = m_CurrentSquad[m_SelectedSoldier];

	// Get Unit base stats and any stat modifications from abilities
	Will = string(int(Unit.GetCurrentStat(eStat_Will)) + Unit.GetUIStatFromAbilities(eStat_Will)) $ "/" $ string(int(Unit.GetMaxStat(eStat_Will)));
	Will = class'UIUtilities_Text'.static.GetColoredText(Will, Unit.GetMentalStateUIState());
	Aim = string(int(Unit.GetCurrentStat(eStat_Offense)) + Unit.GetUIStatFromAbilities(eStat_Offense));
	Health = string(int(Unit.GetCurrentStat(eStat_HP)) + Unit.GetUIStatFromAbilities(eStat_HP));
	Mobility = string(int(Unit.GetCurrentStat(eStat_Mobility)) + Unit.GetUIStatFromAbilities(eStat_Mobility));
	Tech = string(int(Unit.GetCurrentStat(eStat_Hacking)) + Unit.GetUIStatFromAbilities(eStat_Hacking));
	Armor = string(int(Unit.GetCurrentStat(eStat_ArmorMitigation)) + Unit.GetUIStatFromAbilities(eStat_ArmorMitigation));
	Dodge = string(int(Unit.GetCurrentStat(eStat_Dodge)) + Unit.GetUIStatFromAbilities(eStat_Dodge));

	// Get bonus stats for the Unit from items
	WillBonus = Unit.GetUIStatFromInventory(eStat_Will, StartState);
	AimBonus = Unit.GetUIStatFromInventory(eStat_Offense, StartState);
	HealthBonus = Unit.GetUIStatFromInventory(eStat_HP, StartState);
	MobilityBonus = Unit.GetUIStatFromInventory(eStat_Mobility, StartState);
	TechBonus = Unit.GetUIStatFromInventory(eStat_Hacking, StartState);
	ArmorBonus = Unit.GetUIStatFromInventory(eStat_ArmorMitigation, StartState);
	DodgeBonus = Unit.GetUIStatFromInventory(eStat_Dodge, StartState);

	if (Unit.IsPsiOperative())
	{
		Psi = string(int(Unit.GetCurrentStat(eStat_PsiOffense)) + Unit.GetUIStatFromAbilities(eStat_PsiOffense));
		PsiBonus = Unit.GetUIStatFromInventory(eStat_PsiOffense, StartState);
	}

	if (WillBonus > 0)
		Will $= class'UIUtilities_Text'.static.GetColoredText("+"$WillBonus, eUIState_Good);
	else if (WillBonus < 0)
		Will $= class'UIUtilities_Text'.static.GetColoredText(""$WillBonus, eUIState_Bad);

	if (AimBonus > 0)
		Aim $= class'UIUtilities_Text'.static.GetColoredText("+"$AimBonus, eUIState_Good);
	else if (AimBonus < 0)
		Aim $= class'UIUtilities_Text'.static.GetColoredText(""$AimBonus, eUIState_Bad);

	if (HealthBonus > 0)
		Health $= class'UIUtilities_Text'.static.GetColoredText("+"$HealthBonus, eUIState_Good);
	else if (HealthBonus < 0)
		Health $= class'UIUtilities_Text'.static.GetColoredText(""$HealthBonus, eUIState_Bad);

	if (MobilityBonus > 0)
		Mobility $= class'UIUtilities_Text'.static.GetColoredText("+"$MobilityBonus, eUIState_Good);
	else if (MobilityBonus < 0)
		Mobility $= class'UIUtilities_Text'.static.GetColoredText(""$MobilityBonus, eUIState_Bad);

	if (TechBonus > 0)
		Tech $= class'UIUtilities_Text'.static.GetColoredText("+"$TechBonus, eUIState_Good);
	else if (TechBonus < 0)
		Tech $= class'UIUtilities_Text'.static.GetColoredText(""$TechBonus, eUIState_Bad);

	if (ArmorBonus > 0)
		Armor $= class'UIUtilities_Text'.static.GetColoredText("+"$ArmorBonus, eUIState_Good);
	else if (ArmorBonus < 0)
		Armor $= class'UIUtilities_Text'.static.GetColoredText(""$ArmorBonus, eUIState_Bad);

	if (DodgeBonus > 0)
		Dodge $= class'UIUtilities_Text'.static.GetColoredText("+"$DodgeBonus, eUIState_Good);
	else if (DodgeBonus < 0)
		Dodge $= class'UIUtilities_Text'.static.GetColoredText(""$DodgeBonus, eUIState_Bad);

	if (PsiBonus > 0)
		Psi $= class'UIUtilities_Text'.static.GetColoredText("+"$PsiBonus, eUIState_Good);
	else if (PsiBonus < 0)
		Psi $= class'UIUtilities_Text'.static.GetColoredText(""$PsiBonus, eUIState_Bad);

	//Stats will stack to the right, and clear out any unused stats 
	mc.BeginFunctionOp("SetSoldierStats");

	if (Health != "")
	{
		mc.QueueString(m_strHealthLabel);
		mc.QueueString(Health);
	}
	if (Mobility != "")
	{
		mc.QueueString(m_strMobilityLabel);
		mc.QueueString(Mobility);
	}
	if (Aim != "")
	{
		mc.QueueString(m_strAimLabel);
		mc.QueueString(Aim);
	}
	
	if (Will != "")
	{
		mc.QueueString(m_strWillLabel);
		mc.QueueString(Will);
	}
	if (Armor != "")
	{
		mc.QueueString(m_strArmorLabel);
		mc.QueueString(Armor);
	}
	if (Dodge != "")
	{
		mc.QueueString(m_strDodgeLabel);
		mc.QueueString(Dodge);
	}
	if (Tech != "")
	{
		mc.QueueString(m_strTechLabel);
		mc.QueueString(Tech);
	}
	if (Psi != "")
	{
		mc.QueueString(class'UIUtilities_Text'.static.GetColoredText(m_strPsiLabel, eUIState_Psyonic));
		mc.QueueString(class'UIUtilities_Text'.static.GetColoredText(Psi, eUIState_Psyonic));
	}
	else
	{
		mc.QueueString(" ");
		mc.QueueString(" ");
	}

	mc.EndOp();
}

simulated function SetSoldierGear()
{
	local XComGameState_Item equippedItem;
	local array<XComGameState_Item> utilItems;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2SoldierClassTemplate SoldierClassTemplate;

	mc.BeginFunctionOp("SetSoldierGear");

	equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_Armor, StartState, true);
	mc.QueueString(m_strArmorLabel);//armor
	mc.QueueString(equippedItem.GetMyTemplate().strImage);
	mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());

	equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_PrimaryWeapon, StartState, true);
	mc.QueueString(m_strPrimaryLabel);//primary
	mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());
	//primary weapon image is handled in a different function to support the stack of weapon attachments

	mc.QueueString(m_strSecondaryLabel);//secondary
	
	//we need to handle the reaper claymore
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName());
	if (SoldierClassTemplate.DataName == 'Reaper')
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('Reaper_Claymore'));
		mc.QueueString(EquipmentTemplate.strImage);
		mc.QueueString(EquipmentTemplate.GetItemFriendlyName());
	}
	else
	{

		equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_SecondaryWeapon, StartState, true);
		mc.QueueString(equippedItem.GetMyTemplate().strImage);
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());
	}
	

	utilItems = m_CurrentSquad[m_SelectedSoldier].GetAllItemsInSlot(eInvSlot_Utility, StartState, , true);
	mc.QueueString(m_strUtilLabel);//util 1
	mc.QueueString(utilItems[0].GetMyTemplate().strImage);
	mc.QueueString(utilItems[0].GetMyTemplate().GetItemFriendlyNameNoStats());
	mc.QueueString(utilItems[1].GetMyTemplate().strImage);// util 2 and 3
	mc.QueueString(utilItems[1].GetMyTemplate().GetItemFriendlyNameNoStats());

	equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_GrenadePocket, StartState, true);
	mc.QueueString(equippedItem.GetMyTemplate().strImage);
	mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());

	mc.EndOp();

	equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_PrimaryWeapon, StartState, true);
	SetSoldierPrimaryWeapon(equippedItem);

	equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_HeavyWeapon, StartState, true);
	mc.BeginFunctionOp("SetSoldierHeavyWeaponSlot");
	if (equippedItem != none && m_CurrentSquad[m_SelectedSoldier].HasHeavyWeapon())
	{
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());
		mc.QueueString(equippedItem.GetMyTemplate().strImage);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}
	mc.EndOp();
	
	equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_CombatSim, StartState, true);
	mc.BeginFunctionOp("SetSoldierPCS");
	if (equippedItem != none)
	{
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyName(equippedItem.ObjectID));
		mc.QueueString(class'UIUtilities_Image'.static.GetPCSImage(equippedItem));
		mc.QueueString(class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
		mc.QueueString(class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR);
	}
	mc.EndOp();
}


simulated function SetSoldierPrimaryWeapon(XComGameState_Item Item)
{
	local int i;
	local array<string> NewImages;

	if( Item == none )
	{
		MC.FunctionVoid("SetSoldierPrimaryWeapon");
		return;
	}

	NewImages = Item.GetWeaponPanelImages();
	
	//If no image at all is defined, mark it as empty 
	if( NewImages.length == 0 )
	{
		NewImages.AddItem("");
	}

	MC.BeginFunctionOp("SetSoldierPrimaryWeapon");

	for( i = 0; i < NewImages.Length; i++ )
		MC.QueueString(NewImages[i]);

	MC.EndOp();
}

simulated function UpdateAbilityInfo(int ItemIndex)
{
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<SoldierRankAbilities> AbilityTree;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2StrategyElementTemplateManager TemplateMan;
	local int TreeIndex, AbilityIndex, j;
	local UIMechaListItem ListItem;
	local UISummary_Ability AbilityData;
	local array<X2StrategyElementTemplate> AWCUnlockTemplates;
	local X2SoldierAbilityUnlockTemplate Template;

	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName());

	MC.FunctionVoid("HideAllScreens");

	ListItem = UIMechaListItem(List.GetItem(ItemIndex));

	TreeIndex = int(ListItem.metadataString);
	AbilityIndex = ListItem.metadataInt;

	AbilityTree = m_CurrentSquad[m_SelectedSoldier].AbilityTree;
	
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[TreeIndex].Abilities[AbilityIndex].AbilityName);

	if (AbilityTemplate == none)
	{
		TemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		AWCUnlockTemplates = TemplateMan.GetAllTemplatesOfClass(class'X2SoldierAbilityUnlockTemplate');

		for (j = 0; j < AWCUnlockTemplates.Length; ++j)
		{
			Template = X2SoldierAbilityUnlockTemplate(AWCUnlockTemplates[j]);
			if (Template.AllowedClasses.Find(SoldierClassTemplate.DataName) != INDEX_NONE)
			{
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(Template.AbilityName);
				break;
			}
		}
	}
	
	AbilityData = AbilityTemplate.GetUISummary_Ability();

	MC.BeginFunctionOp("SetAbilityData");
	MC.QueueString(AbilityTemplate.IconImage != "" ? AbilityTemplate.IconImage : Template.strImage);
	MC.QueueString(AbilityData.Name);
	MC.QueueString(AbilityData.Description);//AbilityTemplate.LocLongDescription);
	MC.QueueString("" /*unlockString*/ );
	MC.QueueString("" /*rank icon*/ );
	MC.EndOp();
}

simulated function UpdateDataSoldierAbilities()
{
	local int index;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<SoldierRankAbilities> AbilityTree;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local SCATProgression Progression;
	local string Display;
	local int j, k;
	local bool Earned;
	local X2StrategyElementTemplateManager TemplateMan;
	local X2SoldierAbilityUnlockTemplate Template;
	local UIMechaListItem ListItem;
	local ClassAgnosticAbility AWC;
	local bool bIsPsiOp; 

	index = 0;

	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName());
	bIsPsiOp = (SoldierClassTemplate.DataName == 'PsiOperative');

	AbilityTree = m_CurrentSquad[m_SelectedSoldier].AbilityTree;

	m_arrProgression = m_CurrentSquad[m_SelectedSoldier].m_SoldierProgressionAbilties;
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for (j = 0; j < AbilityTree.Length; ++j)
	{
		for (k = 0; k < AbilityTree[j].Abilities.Length; ++k)
		{
			if (AbilityTree[j].Abilities[k].AbilityName != '')
			{
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate( AbilityTree[j].Abilities[k].AbilityName );
				Display = AbilityTemplate.LocFriendlyName;
				Earned = false;

				foreach m_arrProgression(Progression)
				{
					if (Progression.iRank == j && Progression.iBranch == k && m_CurrentSquad[m_SelectedSoldier].MeetsAbilityPrerequisites(AbilityTree[j].Abilities[k].AbilityName))
					{
						Earned = true;
						break;
					}
				}

				ListItem = GetListItem(index++);

				ListItem.UpdateDataCheckbox(Display, "", Earned, OnAbilityCheckboxChanged);
				ListItem.metadataString = string(j);
				ListItem.metadataInt = k;

				if ((j == 0 && !bIsPsiOp) || !m_CurrentSquad[m_SelectedSoldier].MeetsAbilityPrerequisites(AbilityTree[j].Abilities[k].AbilityName)) // show but don't allow interaction with base class abilities, except PsiOp 
					ListItem.SetDisabled( true );
			}
		}
	}

	TemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	UnlockTemplates = TemplateMan.GetAllTemplatesOfClass( class'X2SoldierAbilityUnlockTemplate' );

	for (j = 0; j < UnlockTemplates.Length; ++j)
	{
		Template = X2SoldierAbilityUnlockTemplate( UnlockTemplates[ j ] );
		if (Template.AllowedClasses.Find( SoldierClassTemplate.DataName ) != INDEX_NONE)
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate( Template.AbilityName );
			Display = AbilityTemplate.LocFriendlyName;
			Earned = false;

			foreach m_CurrentSquad[m_SelectedSoldier].AWCAbilities( AWC )
			{
				if (AWC.AbilityType.AbilityName == Template.AbilityName)
				{
					Earned = true;
					break;
				}
			}

			GetListItem(index).UpdateDataCheckbox(Display, "", Earned, OnAbilityCheckboxChanged);
			GetListItem(index++).metadataInt = -j;
		}
	}
}

simulated function RefreshDataSoldierAbilities()
{
	local int index;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<SoldierRankAbilities> AbilityTree;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local SCATProgression Progression;
	local string Display;
	local int j, k;
	local bool Earned;
	local X2StrategyElementTemplateManager TemplateMan;
	local X2SoldierAbilityUnlockTemplate Template;
	local UIMechaListItem ListItem;
	local ClassAgnosticAbility AWC;
	local bool bIsPsiOp;

	index = 0;

	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName());
	bIsPsiOp = (SoldierClassTemplate.DataName == 'PsiOperative');

	AbilityTree = m_CurrentSquad[m_SelectedSoldier].AbilityTree;

	m_arrProgression = m_CurrentSquad[m_SelectedSoldier].m_SoldierProgressionAbilties;
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for (j = 0; j < AbilityTree.Length; ++j)
	{
		for (k = 0; k < AbilityTree[j].Abilities.Length; ++k)
		{
			if (AbilityTree[j].Abilities[k].AbilityName != '')
			{
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[j].Abilities[k].AbilityName);
				Display = AbilityTemplate.LocFriendlyName;
				Earned = false;

				foreach m_arrProgression(Progression)
				{
					if (Progression.iRank == j && Progression.iBranch == k && m_CurrentSquad[m_SelectedSoldier].MeetsAbilityPrerequisites(AbilityTree[j].Abilities[k].AbilityName))
					{
						Earned = true;
						break;
					}
				}

				ListItem = GetListItem(index++);

				ListItem.UpdateDataCheckbox(Display, "", Earned, OnAbilityCheckboxChanged);
				ListItem.metadataString = string(j);
				ListItem.metadataInt = k;

				if ((j == 0 && !bIsPsiOp) || !m_CurrentSquad[m_SelectedSoldier].MeetsAbilityPrerequisites(AbilityTree[j].Abilities[k].AbilityName)) // show but don't allow interaction with base class abilities, except PsiOp 
					ListItem.SetDisabled(true);
				else
					ListItem.SetDisabled(false);
			}
		}
	}

	TemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	UnlockTemplates = TemplateMan.GetAllTemplatesOfClass(class'X2SoldierAbilityUnlockTemplate');

	for (j = 0; j < UnlockTemplates.Length; ++j)
	{
		Template = X2SoldierAbilityUnlockTemplate(UnlockTemplates[j]);
		if (Template.AllowedClasses.Find(SoldierClassTemplate.DataName) != INDEX_NONE)
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(Template.AbilityName);
			Display = AbilityTemplate.LocFriendlyName;
			Earned = false;

			foreach m_CurrentSquad[m_SelectedSoldier].AWCAbilities(AWC)
			{
				if (AWC.AbilityType.AbilityName == Template.AbilityName)
				{
					Earned = true;
					break;
				}
			}

			GetListItem(index).UpdateDataCheckbox(Display, "", Earned, OnAbilityCheckboxChanged);
			GetListItem(index++).metadataInt = -j;
		}
	}
}

simulated function UpdateDataSoldierClass()
{
	local int i;

	ClassTemplates = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().GetAllSoldierClassTemplates();

	//filter out the specialized characters like Shen or Bradford
	for (i = ClassTemplates.Length -1; i > 0; i--)
	{
		if (ClassTemplates[i].bHideInCharacterPool)
			ClassTemplates.Remove(i, 1);

		if (ClassTemplates[i].DataName == 'Rookie')
			ClassTemplates.Remove(i, 1);
	}

	for (i = 0; i < ClassTemplates.Length; i++)
	{
		GetListItem(i).UpdateDataValue(ClassTemplates[i].DisplayName, "", , , OnClickNewClass);
		GetListItem(i).EnableNavigation();
	}
}

simulated function OnClickNewClass(UIMechaListItem MechaItem)
{
	local name oldClass;
	local XComGameState_Unit Unit;
	local name OldCharacter, NewCharacter;
	local array<XComGameState_Item> InventoryItems;
	local int i;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}
	
	m_SelectedSoldierClass = selectedIndex;
	Unit = m_CurrentSquad[m_SelectedSoldier];
	oldClass = Unit.GetSoldierClassTemplateName();

	if (oldClass != ClassTemplates[m_SelectedSoldierClass].DataName)
	{
		OldCharacter = Unit.GetMyTemplateName( );
		NewCharacter = ClassTemplates[m_SelectedSoldierClass].RequiredCharacterClass != '' ? ClassTemplates[m_SelectedSoldierClass].RequiredCharacterClass : 'Soldier';

		if (OldCharacter == NewCharacter)
		{
			Unit.ResetRankToRookie( );
			Unit.SetSoldierClassTemplate( ClassTemplates[ m_SelectedSoldierClass ].DataName );
		}
		else
		{
			InventoryItems = Unit.GetAllInventoryItems( StartState );
			for (i = 0; i < InventoryItems.Length; i++)
			{
				Unit.RemoveItemFromInventory( InventoryItems[ i ], StartState );
			}
			StartState.PurgeGameStateForObjectID( Unit.ObjectID, true );

			HeadquartersStateObject.Squad.RemoveItem( Unit.GetReference( ) );
			HeadquartersStateObject.RemoveFromCrew( Unit.GetReference( ) );

			i = m_CurrentSquad.Find( Unit );
			m_CurrentSquad[ i ] = none;
			Unit = none;

			Unit = CreateUnit( ClassTemplates[m_SelectedSoldierClass].DataName );
			m_CurrentSquad[ i ] = Unit;
		}

		GiveUnitBasicEquipment( Unit );
	}
	m_CurrentState = eUISkirmishScreen_SoldierData;
	UpdateData();
}

simulated function GiveUnitBasicEquipment(XComGameState_Unit Unit)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;
	local X2ChallengeSoldierRank RankSelector;
	local X2ChallengeArmor ArmorSelector;
	local X2ChallengePrimaryWeapon PrimaryWeaponSelector;
	local X2ChallengeSecondaryWeapon SecondaryWeaponSelector;
	local X2ChallengeUtility UtilityItemSelector;
	local array<XComGameState_Unit> UnitArray;
	local array<XComGameState_Item> Items;
	local int i;

	UnitArray.AddItem(Unit);
	
	Items = Unit.GetAllInventoryItems(StartState, true);
	for (i = 0; i < Items.Length; i++)
	{
		Unit.RemoveItemFromInventory(Items[i], StartState);
	}

	RankSelector = X2ChallengeSoldierRank(GetChallengeTemplate('ChallengeRank_OneHighRestLowRank', class'X2ChallengeSoldierRank', ChallengeTemplateManager));
	class'X2ChallengeSoldierRank'.static.SelectSoldierRanks(RankSelector, UnitArray, StartState);

	ArmorSelector = X2ChallengeArmor(GetChallengeTemplate('TLEArmor', class'X2ChallengeArmor', ChallengeTemplateManager));
	class'X2ChallengeArmor'.static.SelectSoldierArmor(ArmorSelector, UnitArray, StartState);

	PrimaryWeaponSelector = X2ChallengePrimaryWeapon(GetChallengeTemplate('TLEPrimaryRandom', class'X2ChallengePrimaryWeapon', ChallengeTemplateManager));
	class'X2ChallengePrimaryWeapon'.static.SelectSoldierPrimaryWeapon(PrimaryWeaponSelector, UnitArray, StartState);

	SecondaryWeaponSelector = X2ChallengeSecondaryWeapon(GetChallengeTemplate('TLESecondaryRandom', class'X2ChallengeSecondaryWeapon', ChallengeTemplateManager));
	class'X2ChallengeSecondaryWeapon'.static.SelectSoldierSecondaryWeapon(SecondaryWeaponSelector, UnitArray, StartState);

	UtilityItemSelector = X2ChallengeUtility(GetChallengeTemplate('ChallengeTLEUtilityItems', class'X2ChallengeUtility', ChallengeTemplateManager));
	class'X2ChallengeUtility'.static.SelectSoldierUtilityItems(UtilityItemSelector, UnitArray, StartState);

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('RocketLauncher'));
	`assert( EquipmentTemplate != none );
	NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);

	Unit.AddItemToInventory(NewItem, eInvSlot_HeavyWeapon, StartState);

}

simulated function OnAbilityCheckboxChanged(UICheckbox CheckboxControl)
{
	local int checkboxIndex, i;
	local SCATProgression Progression;
	local bool bFoundAbility;
	local UIMechaListItem ListItem;
	local X2SoldierAbilityUnlockTemplate Template;
	local ClassAgnosticAbility AWCAbility;

	Progression.iRank = 0;
	bFoundAbility = false;
	for (checkboxIndex = 0; checkboxIndex < List.ItemCount; checkboxIndex++)
	{
		ListItem = GetListItem(checkboxIndex);

		if (ListItem.Checkbox == CheckboxControl)
		{
			if (ListItem.metadataInt >= 0)
			{
				Progression.iRank = int(ListItem.metadataString);
				Progression.iBranch = ListItem.metadataInt;

				for (i = 0; i < m_arrProgression.Length; i++)
				{
					if (m_arrProgression[i] == Progression)
					{
						m_arrProgression.Remove(i, 1);
						bFoundAbility = true;
						break;
					}
				}

				if (!bFoundAbility)
				{
					m_arrProgression.AddItem(Progression);
				}
			}
			else
			{
				Template = X2SoldierAbilityUnlockTemplate( UnlockTemplates[ -ListItem.metadataInt ] );
				for (i = 0; i < m_CurrentSquad[m_SelectedSoldier].AWCAbilities.Length; ++i)
				{
					if (m_CurrentSquad[m_SelectedSoldier].AWCAbilities[i].AbilityType.AbilityName == Template.AbilityName)
					{
						m_CurrentSquad[m_SelectedSoldier].AWCAbilities.Remove(i, 1);
						bFoundAbility = true;
						break;
					}
				}

				if (!bFoundAbility)
				{
					AWCAbility.bUnlocked = true;
					AWCAbility.AbilityType.AbilityName = Template.AbilityName;

					m_CurrentSquad[m_SelectedSoldier].AWCAbilities.AddItem( AWCAbility );
				}
			}

			break;
		}
	}

	m_CurrentSquad[m_SelectedSoldier].SetSoldierProgression(m_arrProgression);
	RefreshDataSoldierAbilities();
}

simulated function UpdateDataSoldierEquipment()
{
	local XComGameState_Item equippedItem;
	local array<XComGameState_Item> utilItems;
	local int i;

	SetSoldierStats();
	SetSoldierGear();

	i = 0;

	equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_PrimaryWeapon, StartState, true);
	GetListItem(i).EnableNavigation();
	GetListItem(i++).UpdateDataValue(m_PrimaryWeapon, equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickPrimaryWeapon);

	if (m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName() != 'Rookie' && m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName() != 'Reaper')
	{
		equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_SecondaryWeapon, StartState, true);
		GetListItem(i).EnableNavigation();
		GetListItem(i++).UpdateDataValue(m_SecondaryWeapon, equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickSecondaryWeapon);
	}

	equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_Armor, StartState, true);
	GetListItem(i).EnableNavigation();
	GetListItem(i++).UpdateDataValue(m_ArmorLabel, equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickArmor);

	
	if (m_CurrentSquad[m_SelectedSoldier].IsSufficientRankToEquipPCS() && m_CurrentSquad[m_SelectedSoldier].GetCurrentStat(eStat_CombatSims) > 0)
	{
		utilItems = m_CurrentSquad[m_SelectedSoldier].GetAllItemsInSlot(eInvSlot_CombatSim, StartState, , true);
		GetListItem(i).EnableNavigation();
		GetListItem(i++).UpdateDataValue(m_PCSLabel, utilItems[0].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickPCS);
	}

	if (m_CurrentSquad[m_SelectedSoldier].GetCurrentStat( eStat_UtilityItems ) > 0)
	{
		utilItems = m_CurrentSquad[m_SelectedSoldier].GetAllItemsInSlot(eInvSlot_Utility, StartState, , true);
		GetListItem(i).EnableNavigation();
		GetListItem(i++).UpdateDataValue(m_UtilItem1, utilItems[0].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickUtilItem1);
	}

	if( m_CurrentSquad[m_SelectedSoldier].HasExtraUtilitySlot() )
	{
		GetListItem(i).EnableNavigation();
		GetListItem(i++).UpdateDataValue(m_UtilItem2, utilItems[1].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickUtilItem2);
	}

	if (m_CurrentSquad[m_SelectedSoldier].HasGrenadePocket())
	{
		equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_GrenadePocket, StartState, true);
		GetListItem(i).EnableNavigation();
		GetListItem(i++).UpdateDataValue(m_GrenadierGrenade, equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickGrenadePocket);
	}

	if (m_CurrentSquad[m_SelectedSoldier].HasHeavyWeapon())
	{
		equippedItem = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_HeavyWeapon, StartState, true);
		GetListItem(i).EnableNavigation();
		GetListItem(i++).UpdateDataValue(m_HeavyWeaponLabel, equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickHeavyWeapon);
	}
}

simulated function OnClickPrimaryWeapon()
{
	m_CurrentState = eUISkirmishScreen_PrimaryWeapon;
	UpdateData();
}

simulated function OnClickHeavyWeapon()
{
	m_CurrentState = eUISkirmishScreen_HeavyWeapon;
	UpdateData();
}

simulated function OnClickSecondaryWeapon()
{
	m_CurrentState = eUISkirmishScreen_SecondaryWeapon;
	UpdateData();
}

simulated function OnClickArmor()
{
	m_CurrentState = eUISkirmishScreen_Armor;
	UpdateData();
}

simulated function OnClickPCS()
{
	m_CurrentState = eUISkirmishScreen_PCS;
	UpdateData();
}


simulated function OnClickUtilItem1()
{
	m_CurrentState = eUISkirmishScreen_UtilItem1;
	UpdateData();
}

simulated function OnClickUtilItem2()
{
	m_CurrentState = eUISkirmishScreen_UtilItem2;
	UpdateData();
}

simulated function OnClickGrenadePocket()
{
	m_CurrentState = eUISkirmishScreen_GrenadePocket;
	UpdateData();
}

simulated function UpdateDataSoldierRank()
{
	local int i, MaxRank;
	local name SoldierClassTemplateName;

	SoldierClassTemplateName = m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName();
	MaxRank = `GET_MAX_RANK;

	for (i = 0; i < MaxRank - 1; ++i)
	{
		GetListItem(i).EnableNavigation();
		GetListItem(i).UpdateDataValue( `GET_RANK_STR(i + 1, SoldierClassTemplateName), "", , , OnClickSoldierRank );
	}
}

simulated function OnClickSoldierRank(UIMechaListItem MechaItem)
{
	local int NewRank, i, j;
	local XComGameState_Unit CurrentUnit;
	local name SoldierClassName;
	local array<SCATProgression> SoldierProgressionAbilities;
	local array <SkirmishModeItemMapping> Items;
	local XComGameState_Item Item;
	local array<XComGameState_Item> InventoryItems;
	local SkirmishModeItemMapping ItemMapData;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	CurrentUnit = m_CurrentSquad[m_SelectedSoldier];
	SoldierClassName = CurrentUnit.GetSoldierClassTemplateName();

	NewRank = selectedIndex + 1;

	if (CurrentUnit.GetRank() != NewRank)
	{
		// 1) BEFORE resetting soldier, need to unequip all items and hold on to items locally 
		for( i = 0; i < eInvSlot_MAX; i++ )
		{
			switch( EInventorySlot(i) )
			{
			case eInvSlot_Armor:
			case eInvSlot_PrimaryWeapon:
			case eInvSlot_SecondaryWeapon:
			case eInvSlot_HeavyWeapon:
			case eInvSlot_GrenadePocket:
				
				ItemMapData.eInvSlot = EInventorySlot(i);
				Item = CurrentUnit.GetItemInSlot(EInventorySlot(i), StartState, true);
				if( Item != none )
				{
					ItemMapData.Item = Item;
					ItemMapData.ItemTemplateName = Item.GetMyTemplateName();
					CurrentUnit.RemoveItemFromInventory(Item, StartState);
					Items.AddItem(ItemMapData);
				}
				break;

			case eInvSlot_CombatSim:
			case eInvSlot_Utility:

				InventoryItems = CurrentUnit.GetAllItemsInSlot(EInventorySlot(i), StartState, true);
				for( j = 0; j < InventoryItems.Length; j++ )
				{
					ItemMapData.eInvSlot = EInventorySlot(i);
					Item = InventoryItems[j];
					ItemMapData.Item = Item;
					if( Item != none )
					{
						ItemMapData.ItemTemplateName = Item.GetMyTemplateName();
						CurrentUnit.RemoveItemFromInventory(Item, StartState);
						Items.AddItem(ItemMapData);
					}
				}
				break;

			default: 
				break;
			}
		}

		// 2) Update the soldier rank
		SoldierProgressionAbilities = CurrentUnit.m_SoldierProgressionAbilties;
		CurrentUnit.ResetSoldierRank();
		for (i = 0; i < NewRank; ++i)
		{
			CurrentUnit.RankUpSoldier( StartState, SoldierClassName);
		}

		CurrentUnit.SetSoldierProgression( SoldierProgressionAbilities );

		// 3) THEN, after setting progression(rank), put all of the items back on the soldier
		
		for( i = 0; i < Items.Length; ++i )
		{
			ItemMapData = Items[i];
			CurrentUnit.AddItemToInventory(ItemMapData.Item, ItemMapData.eInvSlot, StartState);
		}
		Items.Length = 0; 
	}

	m_CurrentState = eUISkirmishScreen_SoldierData;
	UpdateData();
}

simulated function OnClickChooseMissionType()
{
	m_CurrentState = eUISkirmishScreen_Mission;
	UpdateData();
}

simulated function OnClickChooseBiome()
{
	m_CurrentState = EUISkirmishScreen_Biome;
	UpdateData();
}

simulated function OnClickChooseMap()
{
	m_CurrentState = eUISkirmishScreen_Map;
	UpdateData();
}

simulated function UpdateDataMapData()
{
	local int i;
	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;

	UpdateGeneralMissionInfoPanel(); 

	i = 0;

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(BattleDataState.MapData.ActiveMission.MissionName);

	GetListItem(i).EnableNavigation();
	GetListItem(i++).UpdateDataValue(m_EditMissionType, MissionTemplate.DisplayName, OnClickChooseMissionType);
	GetListItem(i).EnableNavigation();
	GetListItem(i++).UpdateDataValue(m_EditMapType, GetLocalizedMapTypeName( MapTypeString ), OnClickChooseMap);

	if (BiomeTypeString != "")
	{
		GetListItem(i).EnableNavigation();
		GetListItem(i++).UpdateDataValue(m_EditBiome, GetLocalizedBiomeTypeName( BiomeTypeString ), OnClickChooseBiome);
	}
}

simulated function UpdateDataEnemies()
{
	local array<X2ChallengeTemplate> Templates;
	local int i;

	Templates = ChallengeTemplateManager.GetAllTemplatesOfClass(class'X2ChallengeEnemyForces');
	UpdateEnemyPortraits();
	
	for (i = 0; i < Templates.Length; i++)
	{
		GetListItem(i).UpdateDataValue(X2ChallengeEnemyForces(Templates[i]).DisplayName, "", , , OnClickNewEnemies);
		GetListItem(i).EnableNavigation();
	}
}

simulated function UpdateEnemyPortraits()
{
	local array<X2ChallengeTemplate> Templates;
	local int i;
	local array<name> enemyTemplate;
	local X2CharacterTemplate enemy, other;
	local X2ChallengeEnemyForces EnemyForcesTemplate;

	Templates = ChallengeTemplateManager.GetAllTemplatesOfClass(class'X2ChallengeEnemyForces');
	
	if (ChallengeMissionSite != none)
	{
		EnemyForcesTemplate = X2ChallengeEnemyForces(ChallengeTemplateManager.FindChallengeTemplate(Templates[m_SelectedEnemy].DataName));
		if (EnemyForcesTemplate != none)
		{
			class'X2ChallengeEnemyForces'.static.SelectEnemyForces(EnemyForcesTemplate, ChallengeMissionSite, BattleDataState, BattleDataState.GetParentGameState());
		}
	}

	mc.FunctionVoid("HideAllScreens");
	GetPossibleEnemiesInPod(Templates[m_SelectedEnemy].DataName, enemyTemplate);
	
	mc.BeginFunctionOp("SetEnemyPodData");

	mc.QueueString(X2ChallengeEnemyForces(Templates[m_SelectedEnemy]).DisplayName);
	mc.QueueString(X2ChallengeEnemyForces(Templates[m_SelectedEnemy]).Description);
	mc.QueueString("");

	while (enemyTemplate.Length > 0)
	{
		enemy = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate( enemyTemplate[0] );
		enemyTemplate.Remove( 0, 1 );
		mc.QueueString(enemy.strSkirmishImage);
		mc.QueueString(enemy.strCharacterName);

		i = 0;
		while (i < enemyTemplate.Length)
		{
			other = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate( enemyTemplate[i] );

			if (other.CharacterGroupName == enemy.CharacterGroupName)
			{
				enemyTemplate.Remove( i, 1 );
				mc.QueueString(other.strSkirmishImage);
				mc.QueueString(other.strCharacterName);
			}
			else
			{
				++i;
			}
		}
	}

	mc.EndOp();
}

native function GetPossibleEnemiesInPod(name templateName, out array<name> enemyTemplate);

simulated function OnClickNewEnemies(UIMechaListItem MechaItem)
{
	local array<X2ChallengeTemplate> Templates;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	m_SelectedEnemy = selectedIndex;
	m_previouslySelectedEnemy = m_SelectedEnemy;
	Templates = ChallengeTemplateManager.GetAllTemplatesOfClass(class'X2ChallengeEnemyForces');
	BattleDataState.TQLEnemyForcesSelection = string(Templates[m_SelectedEnemy].DataName);

	m_CurrentState = eUISkirmishScreen_Base;
	UpdateData();
}

simulated function UpdateDataDifficulty( )
{
	local int i;

	for (i = 0; i < class'UIShellDifficulty'.default.m_arrDifficultyTypeStrings.Length; ++i)
	{
		GetListItem(i).UpdateDataValue(class'UIShellDifficulty'.default.m_arrDifficultyTypeStrings[i], "", , , OnClickDifficulty);
		GetListItem(i).EnableNavigation();
	}
}

simulated function OnClickDifficulty( UIMechaListItem MechaItem )
{
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	CampaignSettings.SetDifficulty(selectedIndex);

	m_CurrentState = eUISkirmishScreen_Base;
	UpdateData();
}

simulated function UINavigationHelp GetNavHelp()
{
	local UINavigationHelp Result;

	Result = PC.Pres.GetNavHelp();
	if (Result == None)
	{
		if (`PRES != none) // Tactical
		{
			Result = Spawn(class'UINavigationHelp', self).InitNavHelp();
			Result.SetX(-500); //offset to match the screen. 
		}
		else if (`HQPRES != none) // Strategy
			Result = `HQPRES.m_kAvengerHUD.NavHelp;
	}
	return Result;
}

simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnCancel);

	if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericConfirm, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	}

	NavHelp.Show();
}


simulated function OnInit()
{
	local UIPanel LeftColumn;

	super.OnInit();

	mc.FunctionString("SetScreenTitle", m_ScreenTitle);

	EnvLightingManager = `ENVLIGHTINGMGR;
	TacticalMissionManager = `TACTICALMISSIONMGR;
	ParcelManager = `PARCELMGR;

	InitHistory();

	LeftColumn = Spawn(class'UIPanel', self);
	LeftColumn.bIsNavigable = true;
	LeftColumn.InitPanel('SkirmishLeftColumnContainer');
	Navigator.SetSelected(LeftColumn);
	LeftColumn.Navigator.LoopSelection = true;	

	List = Spawn(class'UIList', LeftColumn);
	List.bStickyHighlight = false;
	List.InitList('MyList', , , , 825);
	List.Navigator.LoopOnReceiveFocus = true;
	List.Navigator.LoopSelection = false;
	List.bPermitNavigatorToDefocus = true;
	List.Navigator.SelectFirstAvailable();
	List.SetWidth(445);
	List.OnSetSelectedIndex = OnSetSelectedIndex;

	UpdateData();

	ContinueButton = Spawn(class'UILargeButton', LeftColumn);
	ContinueButton.InitLargeButton('ContinueButton', , , OnButtonStartBattleClicked);
	ContinueButton.SetPosition(500, 965);

	LeftColumn.Navigator.SetSelected(ContinueButton);

	NavHelp = GetNavHelp();
	UpdateNavHelp();

}

simulated public function OnCancel()
{
	local PlotDefinition Plot;

	switch (m_CurrentState)
	{
	case eUISkirmishScreen_Base:
		NavHelp.ClearButtonHelp();
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		DestructiveActionPopup();
		break;

	case eUISkirmishScreen_SoldierData:
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		m_CurrentState = eUISkirmishScreen_Squad;
		UpdateData();
		break;

	case eUISkirmishScreen_SoldierClass:
	case eUISkirmishScreen_SoldierEquipment:
	case eUISkirmishScreen_SoldierAbilities:
	case eUISkirmishScreen_SoldierRank:
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		m_CurrentState = eUISkirmishScreen_SoldierData;
		UpdateData();
		break;

	case eUISkirmishScreen_PrimaryWeapon:
	case eUISkirmishScreen_SecondaryWeapon:
	case eUISkirmishScreen_Armor:
	case eUISkirmishScreen_UtilItem1:
	case eUISkirmishScreen_UtilItem2:
	case eUISkirmishScreen_GrenadePocket:
	case eUISkirmishScreen_HeavyWeapon:
	case eUISkirmishScreen_PCS:
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		m_CurrentState = eUISkirmishScreen_SoldierEquipment;
		UpdateData();
		break;

	case eUISkirmishScreen_Enemies:
		m_SelectedEnemy = m_previouslySelectedEnemy;
	case eUISkirmishScreen_Squad:
	case eUISkirmishScreen_MapData:
	case eUISkirmishScreen_Difficulty:
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		m_CurrentState = eUISkirmishScreen_Base;
		UpdateData();
		break;
	case eUISkirmishScreen_Map:
	case eUISkirmishScreen_Mission:
	case EUISkirmishScreen_Biome:
		Plot = ParcelManager.GetPlotDefinition(MapTypeString);
		MapImagePath = `MAPS.SelectMapImage(Plot.strType, Plot.ValidBiomes[m_currentBiome]);
		UpdateGeneralMissionInfoPanel();

		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		m_CurrentState = eUISkirmishScreen_MapData;
		UpdateData();
		break;
	};
}

simulated function CreateNewLadder(int LadderDifficulty)
{
	local X2ChallengeEnemyForces EnemyForcesTemplate;
	local int Index;
	local int AlertLevel, ForceLevel;
	local X2ChallengeAlertForce AlertForceSelector;
	local XComOnlineProfileSettings ProfileSettings;

	if (ChallengeMissionSite != none)
	{
		if (BattleDataState.TQLEnemyForcesSelection == "")
		{
			BattleDataState.TQLEnemyForcesSelection = "ChallengeStandardSchedule";
		}

		AlertForceSelector = X2ChallengeAlertForce( ChallengeTemplateManager.FindChallengeTemplate( 'ChallengeCalculatedLevels' ) );
		class'X2ChallengeAlertForce'.static.SelectAlertAndForceLevels( AlertForceSelector, StartState, HeadquartersStateObject, AlertLevel, ForceLevel );
		BattleDataState.SetAlertLevel( AlertLevel );
		BattleDataState.SetForceLevel( ForceLevel );

		ChallengeMissionSite.SelectedMissionData.AlertLevel = AlertLevel;
		ChallengeMissionSite.SelectedMissionData.ForceLevel = ForceLevel;

		EnemyForcesTemplate = X2ChallengeEnemyForces(ChallengeTemplateManager.FindChallengeTemplate(name(BattleDataState.TQLEnemyForcesSelection)));
		if (EnemyForcesTemplate != none)
		{
			// Reset the encounter list to force the AI spawn manager to reselect the spawns based on the active forces selector.
			ChallengeMissionSite.SelectedMissionData.SelectedEncounters.Length = 0;

			// Add any tactical gameplay tags required by the enemy forces selector
			if (EnemyForcesTemplate.AdditionalTacticalGameplayTags.Length > 0)
			{
				for (Index = 0; Index < EnemyForcesTemplate.AdditionalTacticalGameplayTags.Length; ++Index)
				{
					HeadquartersStateObject.TacticalGameplayTags.AddItem(EnemyForcesTemplate.AdditionalTacticalGameplayTags[Index]);
					HeadquartersStateObject.CleanUpTacticalTags();
				}
			}
			class'X2ChallengeEnemyForces'.static.SelectEnemyForces(EnemyForcesTemplate, ChallengeMissionSite, BattleDataState, BattleDataState.GetParentGameState());

		}

		ChallengeMissionSite.UpdateSitrepTags( );
		HeadquartersStateObject.AddMissionTacticalTags( ChallengeMissionSite );
	}

	class'X2SitRepTemplate'.static.ModifyPreMissionBattleDataState(BattleDataState, BattleDataState.ActiveSitReps);

	ProfileSettings = `XPROFILESETTINGS;

	++ProfileSettings.Data.HubStats.NumSkirmishes;

	`ONLINEEVENTMGR.SaveProfileSettings();

	ConsoleCommand(BattleDataState.m_strMapCommand);
}

simulated function UpdateDataPrimaryWeapon()
{
	local int i, index;
	local ChallengeClassPrimaryWeapons PossibleItems;
	local X2ChallengePrimaryWeapon PrimaryWeaponSelector;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	PrimaryWeaponSelector = X2ChallengePrimaryWeapon(GetChallengeTemplate('TLEPrimaryRandom', class'X2ChallengePrimaryWeapon', ChallengeTemplateManager));
	PossibleItems = class'X2ChallengePrimaryWeapon'.static.GetClassWeapons(PrimaryWeaponSelector, m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName());

	index = 0;
	for (i = 0; i < PossibleItems.PrimaryWeapons.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PossibleItems.PrimaryWeapons[i].templatename));
		
		if (EquipmentTemplate != none)
		{
			GetListItem(index).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewPrimaryWeapon);
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).EnableNavigation();
		}
	}
}

simulated function OnClickNewPrimaryWeapon(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate( name(MechaItem.metadataString) ));
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);
	
	m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_PrimaryWeapon, StartState, true), StartState);
	m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_PrimaryWeapon, StartState);

	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

simulated function 	UpdateDataSecondaryWeapon()
{
	local int i, index;
	local ChallengeClassSecondaryWeapons PossibleItems;
	local X2ChallengeSecondaryWeapon PrimaryWeaponSelector;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	PrimaryWeaponSelector = X2ChallengeSecondaryWeapon(GetChallengeTemplate('TLESecondaryRandom', class'X2ChallengeSecondaryWeapon', ChallengeTemplateManager));
	PossibleItems = class'X2ChallengeSecondaryWeapon'.static.GetClassWeapons(PrimaryWeaponSelector, m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName());

	index = 0;
	for (i = 0; i < PossibleItems.SecondaryWeapons.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PossibleItems.SecondaryWeapons[i].templatename));

		if (EquipmentTemplate != none)
		{
			GetListItem(index).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewSecondaryWeapon);
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).EnableNavigation();
		}
	}
}

simulated function 	OnClickNewSecondaryWeapon(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate( name(GetListItem(selectedIndex).metadataString) ) );
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);

	m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_SecondaryWeapon, StartState, true), StartState);
	m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_SecondaryWeapon, StartState);

	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

simulated function 	UpdateDataArmor()
{
	local int i, index;
	local array<name> RandomArmors;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	if (!m_CurrentSquad[m_SelectedSoldier].IsChampionClass() && m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName() != 'Spark')
	{
		RandomArmors.AddItem('KevlarArmor');
		RandomArmors.AddItem('KevlarArmor_DLC_Day0');
		RandomArmors.AddItem('LightPlatedArmor');
		RandomArmors.AddItem('MediumPlatedArmor');
		RandomArmors.AddItem('HeavyPlatedArmor');
		RandomArmors.AddItem('LightPoweredArmor');
		RandomArmors.AddItem('MediumPoweredArmor');
		RandomArmors.AddItem('HeavyPoweredArmor');
		RandomArmors.AddItem('MediumAlienArmor');
		RandomArmors.AddItem('HeavyAlienArmor');
		RandomArmors.AddItem('HeavyAlienArmorMk2');
		RandomArmors.AddItem('LightAlienArmor');
		RandomArmors.AddItem('LightAlienArmorMk2');
	}

	switch (m_CurrentSquad[m_SelectedSoldier].GetSoldierClassTemplateName())
	{
	case 'Reaper':
		RandomArmors.AddItem('ReaperArmor');
		RandomArmors.AddItem('PlatedReaperArmor');
		RandomArmors.AddItem('PoweredReaperArmor');
		break;
	case 'Templar':
		RandomArmors.AddItem('TemplarArmor');
		RandomArmors.AddItem('PlatedTemplarArmor');
		RandomArmors.AddItem('PoweredTemplarArmor');
		break;
	case 'Skirmisher':
		RandomArmors.AddItem('SkirmisherArmor');
		RandomArmors.AddItem('PlatedSkirmisherArmor');
		RandomArmors.AddItem('PoweredSkirmisherArmor');
		break;
	case 'Spark':
		RandomArmors.AddItem('SparkArmor');
		RandomArmors.AddItem('PlatedSparkArmor');
		RandomArmors.AddItem('PoweredSparkArmor');
		break;
	case 'Specialist':
		RandomArmors.AddItem('SpecialistKevlarArmor');
		RandomArmors.AddItem('SpecialistPlatedArmor');
		RandomArmors.AddItem('SpecialistPoweredArmor');
		break;
	case 'Grenadier':
		RandomArmors.AddItem('GrenadierKevlarArmor');
		RandomArmors.AddItem('GrenadierPlatedArmor');
		RandomArmors.AddItem('GrenadierPoweredArmor');
		break;
	case 'Sharpshooter':
		RandomArmors.AddItem('SharpshooterKevlarArmor');
		RandomArmors.AddItem('SharpshooterPlatedArmor');
		RandomArmors.AddItem('SharpshooterPoweredArmor');
		break;
	case 'Ranger':
		RandomArmors.AddItem('RangerKevlarArmor');
		RandomArmors.AddItem('RangerPlatedArmor');
		RandomArmors.AddItem('RangerPoweredArmor');
		break;
	case 'PsiOperative':
		RandomArmors.AddItem('PsiOperativeKevlarArmor');
		RandomArmors.AddItem('PsiOperativePlatedArmor');
		RandomArmors.AddItem('PsiOperativePoweredArmor');
		break;
	}

	index = 0;
	for (i = 0; i < RandomArmors.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate( RandomArmors[i] ) );

		if (EquipmentTemplate != none)
		{
			GetListItem(index).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewArmor);
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).EnableNavigation();
		}
	}
}

simulated function 	OnClickNewArmor(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Item NewItem;
	local array<XComGameState_Item> Items;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate( name(GetListItem(selectedIndex).metadataString) ) );
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);
	Items = m_CurrentSquad[m_SelectedSoldier].GetAllItemsInSlot(eInvSlot_Utility, StartState, true, true);
	
	m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_Armor, StartState, true), StartState);
	m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_Armor, StartState);

	if (!X2ArmorTemplate(EquipmentTemplate).bAddsUtilitySlot && Items.Length >= 2)// remove item 2
	{
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(Items[1], StartState);
	}
	else if (X2ArmorTemplate(EquipmentTemplate).bAddsUtilitySlot && Items.Length < 2)
	{
		ItemTemplate = ItemTemplateManager.FindItemTemplate('NanofiberVest');
		`assert( ItemTemplate != none );
		
		if (m_CurrentSquad[m_SelectedSoldier].CanAddItemToInventory(ItemTemplate, eInvSlot_Utility, StartState))
		{
			NewItem = ItemTemplate.CreateInstanceFromTemplate(StartState);
			m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_Utility, StartState);
		}
		else
		{
			ItemTemplate = ItemTemplateManager.FindItemTemplate('FragGrenade');
			`assert( ItemTemplate != none );
			NewItem = ItemTemplate.CreateInstanceFromTemplate(StartState);
			m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_Utility, StartState);
		}
	}

	if (m_CurrentSquad[m_SelectedSoldier].HasHeavyWeapon())
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('RocketLauncher'));
		`assert( EquipmentTemplate != none );
		NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);

		m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_HeavyWeapon, StartState);
	}
	else if(m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_HeavyWeapon, StartState, true) != none)
	{
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_HeavyWeapon, StartState, true), StartState);
	}

	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

simulated function UpdateDataUtilItem1()
{
	local int i, index;
	local X2ChallengeUtility PrimaryWeaponSelector;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	PrimaryWeaponSelector = X2ChallengeUtility(GetChallengeTemplate('ChallengeTLEUtilityItems', class'X2ChallengeUtility', ChallengeTemplateManager));

	index = 0;
	for (i = 0; i < PrimaryWeaponSelector.UtilitySlot.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PrimaryWeaponSelector.UtilitySlot[i].templatename));

		if (EquipmentTemplate != none)
		{
			GetListItem(i).EnableNavigation();
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewUtilItem1);
		}
	}

	for (i = 0; i < PrimaryWeaponSelector.GrenadierSlot.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PrimaryWeaponSelector.GrenadierSlot[i].templatename));

		if (EquipmentTemplate != none)
		{
			GetListItem(index).EnableNavigation();
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewUtilItem1);
		}
	}
}

simulated function OnClickNewUtilItem1(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate, ItemTemplate;
	local XComGameState_Item NewItem, SpareItem;
	local array<XComGameState_Item> Items;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	Items = m_CurrentSquad[m_SelectedSoldier].GetAllItemsInSlot(eInvSlot_Utility, StartState, true, true);

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate( name(GetListItem(selectedIndex).metadataString) ));
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);

	if (!m_CurrentSquad[m_SelectedSoldier].RespectsUniqueRule(EquipmentTemplate, eInvSlot_Utility, StartState))
	{
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(Items[1], StartState);
		ItemTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('FragGrenade'));
		`assert( ItemTemplate != none );

		if (m_CurrentSquad[m_SelectedSoldier].CanAddItemToInventory(ItemTemplate, eInvSlot_Utility, StartState))
		{
			SpareItem = ItemTemplate.CreateInstanceFromTemplate(StartState);
			m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(SpareItem, eInvSlot_Utility, StartState);
		}
		else
		{
			ItemTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('NanofiberVest'));
			`assert( ItemTemplate != none );
			SpareItem = ItemTemplate.CreateInstanceFromTemplate(StartState);
			m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(SpareItem, eInvSlot_Utility, StartState);
		}
	}

	if (Items[0] != none)
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(Items[0], StartState);
	
	m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_Utility, StartState, true);

	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

simulated function UpdateDataUtilItem2()
{
	local int i, index;
	local X2ChallengeUtility PrimaryWeaponSelector;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	PrimaryWeaponSelector = X2ChallengeUtility(GetChallengeTemplate('ChallengeTLEUtilityItems', class'X2ChallengeUtility', ChallengeTemplateManager));

	index = 0;
	for (i = 0; i < PrimaryWeaponSelector.UtilitySlot.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PrimaryWeaponSelector.UtilitySlot[i].templatename));

		if (EquipmentTemplate != none)
		{
			GetListItem(index).EnableNavigation();
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewUtilItem2);
		}
	}

	for (i = 0; i < PrimaryWeaponSelector.GrenadierSlot.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PrimaryWeaponSelector.GrenadierSlot[i].templatename));

		if (EquipmentTemplate != none)
		{
			GetListItem(index).EnableNavigation();
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewUtilItem2);
		}
	}
}

simulated function OnClickNewUtilItem2(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate, ItemTemplate;
	local XComGameState_Item NewItem, SpareItem;
	local array<XComGameState_Item> Items;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	Items = m_CurrentSquad[m_SelectedSoldier].GetAllItemsInSlot(eInvSlot_Utility, StartState, true, true);

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate( name(GetListItem(selectedIndex).metadataString) ));
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);

	if (!m_CurrentSquad[m_SelectedSoldier].RespectsUniqueRule(EquipmentTemplate, eInvSlot_Utility, StartState))
	{
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(Items[0], StartState);
		ItemTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('FragGrenade'));
		`assert( ItemTemplate != none );

		if (m_CurrentSquad[m_SelectedSoldier].CanAddItemToInventory(ItemTemplate, eInvSlot_Utility, StartState))
		{
			SpareItem = ItemTemplate.CreateInstanceFromTemplate(StartState);
			m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(SpareItem, eInvSlot_Utility, StartState, true);
		}
		else
		{
			ItemTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('NanofiberVest'));
			`assert( ItemTemplate != none );
			SpareItem = ItemTemplate.CreateInstanceFromTemplate(StartState);
			m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(SpareItem, eInvSlot_Utility, StartState, true);
		}
	}

	if(Items[1] != none)
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(Items[1], StartState);
	
	m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_Utility, StartState);

	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

simulated function UpdateDataGrenadePocket()
{
	local int i, index;
	local X2ChallengeUtility PrimaryWeaponSelector;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	PrimaryWeaponSelector = X2ChallengeUtility(GetChallengeTemplate('ChallengeTLEUtilityItems', class'X2ChallengeUtility', ChallengeTemplateManager));

	index = 0;
	for (i = 0; i < PrimaryWeaponSelector.GrenadierSlot.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PrimaryWeaponSelector.GrenadierSlot[i].templatename));

		if (EquipmentTemplate != none)
		{
			GetListItem(index).EnableNavigation();
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewGrenadePocket);
		}
	}
}

simulated function OnClickNewGrenadePocket(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;
	local XComGameState_Item Items;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	Items = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_GrenadePocket, StartState, true);

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate( name(GetListItem(selectedIndex).metadataString) ));
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);

	if(Items != none)
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(Items, StartState);
	
	m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_GrenadePocket, StartState);

	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

simulated function UpdateDataHeavyWeapon()
{
	local int i, index;
	local X2ChallengeUtility PrimaryWeaponSelector;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	PrimaryWeaponSelector = X2ChallengeUtility(GetChallengeTemplate('ChallengeTLEUtilityItems', class'X2ChallengeUtility', ChallengeTemplateManager));

	index = 0;
	for (i = 0; i < PrimaryWeaponSelector.HeavyWeapon.Length; i++)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(PrimaryWeaponSelector.HeavyWeapon[i].templatename));

		if (EquipmentTemplate != none)
		{
			GetListItem(index).EnableNavigation();
			GetListItem(index).metadataString = string(EquipmentTemplate.DataName);
			GetListItem(index++).UpdateDataValue(EquipmentTemplate.GetItemFriendlyNameNoStats(), "", , , OnClickNewHeavyWeapon);
		}
	}
}

simulated function OnClickNewHeavyWeapon(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;
	local XComGameState_Item Items;
	local int selectedIndex;

	for (selectedIndex = 0; selectedIndex < List.ItemContainer.ChildPanels.Length; selectedIndex++)
	{
		if (GetListItem(selectedIndex) == MechaItem)
			break;
	}

	Items = m_CurrentSquad[m_SelectedSoldier].GetItemInSlot(eInvSlot_HeavyWeapon, StartState, true);

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(name(GetListItem(selectedIndex).metadataString)));
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate(StartState);

	if (Items != none)
		m_CurrentSquad[m_SelectedSoldier].RemoveItemFromInventory(Items, StartState);

	m_CurrentSquad[m_SelectedSoldier].AddItemToInventory(NewItem, eInvSlot_HeavyWeapon, StartState);

	m_CurrentState = eUISkirmishScreen_SoldierEquipment;
	UpdateData();
}

function RemoveSoldierPopup()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.strTitle = m_RemoveSoldierTitle;
	kConfirmData.strText = m_RemoveSoldierBody;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnRemoveSoldierPopupExitDialog;

	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnRemoveSoldierPopupExitDialog(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);

		OnClickRemoveUnit();
	}
}

function DestructiveActionPopup()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.strTitle = m_DestructiveActionTitle;
	kConfirmData.strText = m_DestructiveActionBody;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnDestructiveActionPopupExitDialog;

	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDestructiveActionPopupExitDialog(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);

		CloseScreen();
	}
}

defaultproperties
{
	m_CurrentState = eUISkirmishScreen_Base;
	Package = "/ package/gfxTLE_SkirmishMenu/TLE_SkirmishMenu";
	InputState = eInputState_Consume;
	m_previouslySelectedEnemy = 0;

	bHideOnLoseFocus = true;
}
