//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalQuickLaunch
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: This screen provides the functionality for dynamically building a level from 
//           within a tactical battle, and restarting a battle after the level has been
//           built.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalQuickLaunch extends UIScreen 
	dependson(XComParcelManager, XComPlotCoverParcelManager)
	native(UI)
	config(TQL);

var XComPresentationLayer   Pres;
var XComTacticalController  TacticalController;
var bool                    bShouldInitCamera;
var bool                    bStoredMouseIsActive;
var bool                    bPathingNeedsRebuilt;

//Debug camera
var bool                    bDebugCameraActive;
var vector                  DefaultCameraPosition;
var vector                  DefaultCameraDirection;

//Map setup managers
var int ProcLevelSeed;   //Random seed to use when building levels
var XComEnvLightingManager      EnvLightingManager;
var XComTacticalMissionManager  TacticalMissionManager;
var XComParcelManager           ParcelManager;

//Game state objects
var XComGameStateHistory        History;
var XComGameState_BattleData    BattleDataState;
var XComGameState_MissionSite	ChallengeMissionSite;

// stuff for ui interaction
var XComParcel HighlightedParcel;

var UIButton	Button_StartBattle;
var UIButton	Button_GenerateMap;
var UIButton	Button_ToggleMapSize;
var UIButton    Button_RerollSpawnPoint;
var UIButton    Button_ChooseMapData;
var UIButton    Button_ChooseSquadLoadout;
var UIButton    Button_ToggleDebugCamera;
var UIButton    Button_ReturnToShell;
var UIButton	Button_StartChallenge;
var UIButton	Button_ChallengeControls;
var UIDropdown	Dropdown_MapPreset;

var bool ChallengeControlsVisible;
var UIDropdown Challenge_SquadSize;
var UIDropdown Challenge_ClassSelector;
var UIDropdown Challenge_AlienSelector;
var UIDropdown Challenge_RankSelector;
var UIDropdown Challenge_ArmorSelector;
var UIDropdown Challenge_PrimaryWeaponSelector;
var UIDropdown Challenge_SecondaryWeaponSelector;
var UIDropdown Challenge_UtilityItemSelector;
var UIDropdown Challenge_AlertForceLevelSelector;
var UIDropdown Challenge_EnemyForcesSelector;

var UIPanel		InfoBoxContainer;
var UIBGBox		BGBox_InfoBox;
var UIText		Text_InfoBoxTitle;
var UIText		Text_InfoBoxText;

var UIList      ParcelDefinitionList;

enum ParcelSelectionEnum
{
	eParcelSelection_Random,	
	eParcelSelection_Specify
};

var ParcelSelectionEnum ParcelSelectionType;
var ParcelDefinition    SelectedParcel;

enum PlotCoverParcelSelectionEnum
{
	ePlotCoverParcelSelection_Random,	
	ePlotCoverParcelSelection_Specify
};

var PlotCoverParcelSelectionEnum    PlotCoverParcelSelectionType;
var PCPDefinition                   SelectedPlotCoverParcel;

//Set after hitting generate. Indicates that the map will need to be cleared before a new one can be generated
var bool bMapNeedsClear;
var bool MapGenerated;

//Set after hitting generate. Indicates that the map will need to be cleared before a new one can be generated
var bool bAutoStartBattleAfterGeneration;
var bool bGenerateChallengeHistory;

//Variables to help display progress while building a level
var int LastPhase; 
var array<string> PhaseText;
var float PhaseTime;

//Variables to draw the parcel / plot data to the canvas
var int CanvasDrawScale;

// used to debug TacticalGameplayTags applied before mission begins
var array<Name> TacticalGameplayTags;

struct native MapGenerationPreset
{
	var string PresetName;
	var string PlotName;
	var string Biome;
	var int ForceLevel;
	var int AlertLevel;
	var name SquadName;
	var name QuestItemName;

	structdefaultproperties
	{
		AlertLevel = -1;
	}
};

var config array<MapGenerationPreset> TQLMapPresets;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComOnlineEventMgr EventMgr;
	super.InitScreen(InitController, InitMovie, InitName);

	TacticalController = XComTacticalController(InitController);
	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();

	EnvLightingManager = `ENVLIGHTINGMGR;
	TacticalMissionManager = `TACTICALMISSIONMGR;
	ParcelManager = `PARCELMGR;

	//Set up the button elements
	BuildButton_StartBattle();
	BuildButton_GenerateMap();
	BuildButton_ChooseMapData();
	BuildButton_ToggleMapSize();
	BuildButton_ChooseSquadLoadout();
	BuildButton_ToggleDebugCamera();
	BuildButton_ReturnToShell();
	BuildButton_RerollSpawnPoint();
	BuildChallengeControls();

	//Set up the info box element
	InfoBoxContainer = Spawn(class'UIPanel', self).InitPanel();
	InfoBoxContainer.AnchorTopRight().SetPosition(-550,50);
	BuildInfoBox();
	InfoBoxContainer.DisableNavigation();
	Navigator.HorizontalNavigation = true;

	Pres = XComPresentationLayer(PC.Pres);

	InitHistory();

	AddHUDOverlayActor();

	InitializeCamera();

	`BATTLE.SetProfileSettings();

	Pres.Get2DMovie().Show();

	bMapNeedsClear = false;

	if(WorldInfo.IsPlayInEditor())
	{
		UpdatePIEMap();
	}

	`PARCELMGR.ResetIsFinishedGeneratingMap();

	EventMgr = `ONLINEEVENTMGR;
	if(EventMgr.ChallengeModeSeedGenNum > 0)
	{
		OnButtonStartChallengeClicked(None);
	}

	// Issue 406: allow templated event handlers to register themselves in TQL for map generation
	class'X2EventListenerTemplateManager'.static.RegisterTacticalListeners();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	// make sure our battle data is the most recent version (it may be changed by child screens)
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
}

function InitHistory()
{
	local XComOnlineProfileSettings Profile;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;

	Profile = `XPROFILESETTINGS;

	History = `XCOMHISTORY;
	History.ResetHistory(, false);

	// Grab the start state from the profile
	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	Pres.TacticalStartState = History.CreateNewGameState(false, TacticalStartContext);

	Profile.ReadTacticalGameStartState(Pres.TacticalStartState);

	History.AddGameStateToHistory(Pres.TacticalStartState);

	// Store off the battle data object in the start state
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
}

function UpdatePIEMap()
{
	local bool bFoundMatch;
	local string ForceLevel_PIE;	
	local int Index;

	ForceLevel_PIE = class'Engine'.static.GetEngine().ForceLevel_PIE;
	`log("ForceLevel_PIE is"@ForceLevel_PIE); 

	ParcelManager.ForceIncludeType = eForceInclude_None;

	`log("Searching plot definitions...");
	bFoundMatch = false;
	for( Index = 0; Index < ParcelManager.arrPlots.Length && !bFoundMatch; ++Index )
	{
		if( ForceLevel_PIE ~= ParcelManager.arrPlots[Index].MapName )
		{
			`log("Found matching plot definition...");

			ParcelManager.ForceIncludeType = eForceInclude_Plot;
			ParcelManager.ForceIncludePlot = ParcelManager.arrPlots[Index];

			BattleDataState.MapData.PlotMapName = ParcelManager.arrPlots[Index].MapName;
			BattleDataState.PlotSelectionType = ePlotSelection_Specify;

			bFoundMatch = true;
		}
	}

	`log("Searching parcel definitions...");
	for( Index = 0; Index < ParcelManager.arrAllParcelDefinitions.Length && !bFoundMatch; ++Index )
	{
		if( ForceLevel_PIE ~= ParcelManager.arrAllParcelDefinitions[Index].MapName )
		{
			`log("Found matching parcel definition...");

			ParcelManager.ForceIncludeType = eForceInclude_Parcel;
			ParcelManager.ForceIncludeParcel = ParcelManager.arrAllParcelDefinitions[Index];

			BattleDataState.PlotType = ParcelManager.arrAllParcelDefinitions[Index].arrPlotTypes[`SYNC_RAND(ParcelManager.arrAllParcelDefinitions[Index].arrPlotTypes.Length)].strPlotType;
			`log("Selecting plot type:"@BattleDataState.PlotType);
			BattleDataState.PlotSelectionType = ePlotSelection_Type;

			bFoundMatch = true;
		}
	}
}

function InitializeCamera()
{
	TacticalController.ClientSetCameraFade(false);
	TacticalController.SetInputState('Multiplayer_Inactive');
}

simulated private function BuildButton_StartBattle()
{
	Button_StartBattle = Spawn(class'UIButton', self);
	Button_StartBattle.InitButton('Button_StartBattle', "Start Battle", OnButtonStartBattleClicked, eUIButtonStyle_NONE);
	Button_StartBattle.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	Button_StartBattle.SetPosition(50, 50);
}

simulated private function OnButtonStartBattleClicked(UIButton button)
{
	if( IsIdle() && MapGenerated )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		GotoState('GoingToBattle');
	}
	else if(IsIdle() && !bMapNeedsClear)
	{
		bAutoStartBattleAfterGeneration = true;
		GotoState('GeneratingMap');
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function UIDropdown SpawnChallengeDropdown( name ID, string Label, int dropx, int dropy, class<X2ChallengeTemplate> TemplateType, X2ChallengeTemplateManager ChallengeTemplateManager )
{
	local UIDropdown Dropdown;
	local array<X2ChallengeTemplate> Templates;
	local X2ChallengeTemplate Template;

	Dropdown = Spawn(class'UIDropdown', self);
	Dropdown.InitDropdown( ID, Label );
	Dropdown.SetX( dropx );
	Dropdown.SetY( dropy );

	Dropdown.AddItem( "Random" );

	Templates = ChallengeTemplateManager.GetAllTemplatesOfClass( TemplateType );
	foreach Templates( Template )
	{
		Dropdown.AddItem( string( Template.DataName ) );
	}

	Dropdown.SetSelected( 0 );

	return Dropdown;
}

simulated private function BuildChallengeControls()
{
	local X2ChallengeTemplateManager ChallengeTemplateManager;

	ChallengeTemplateManager = class'X2ChallengeTemplateManager'.static.GetChallengeTemplateManager( );

	Button_StartChallenge = Spawn( class'UIButton', self );
	Button_StartChallenge.InitButton( 'Button_StartChallenge', "Start Challenge", OnButtonStartChallengeClicked, (`ISCONTROLLERACTIVE) ? eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE : eUIButtonStyle_NONE);
	Button_StartChallenge.SetGamepadIcon( class'UIUtilities_Input'.static.GetAdvanceButtonIcon() );
	Button_StartChallenge.SetPosition( 50, 200 );

	Button_ChallengeControls = Spawn( class'UIButton', self );
	Button_ChallengeControls.InitButton( 'Button_ChallengeControls', "Show Challenge Controls", OnButtonChallengeControlsClicked, (`ISCONTROLLERACTIVE) ? eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE : eUIButtonStyle_NONE);
	Button_ChallengeControls.SetGamepadIcon( class'UIUtilities_Input'.static.GetAdvanceButtonIcon() );
	Button_ChallengeControls.SetPosition( 200, 200 );

	ChallengeControlsVisible = true;

	Challenge_UtilityItemSelector		= SpawnChallengeDropdown( 'ChallengeUtility',			"Utility Items Template",		80, 230 + 65 * 8, class'X2ChallengeUtility', ChallengeTemplateManager );
	Challenge_SecondaryWeaponSelector	= SpawnChallengeDropdown( 'ChallengeSecondaryWeapon',	"Secondary Weapon Template",	80, 230 + 65 * 7, class'X2ChallengeSecondaryWeapon', ChallengeTemplateManager );
	Challenge_PrimaryWeaponSelector		= SpawnChallengeDropdown( 'ChallengePrimaryWeapon',		"Primary Weapon Template",		80, 230 + 65 * 6, class'X2ChallengePrimaryWeapon', ChallengeTemplateManager );
	Challenge_ArmorSelector				= SpawnChallengeDropdown( 'ChallengeArmor',				"Armor Template",				80, 230 + 65 * 5, class'X2ChallengeArmor', ChallengeTemplateManager );
	Challenge_RankSelector				= SpawnChallengeDropdown( 'ChallengeSoldierRank',		"Soldier Rank Template",		80, 230 + 65 * 4, class'X2ChallengeSoldierRank', ChallengeTemplateManager );
	Challenge_AlienSelector				= SpawnChallengeDropdown( 'ChallengeSquadAlien',		"Alien Squad Member Template",	80, 230 + 65 * 3, class'X2ChallengeSquadAlien', ChallengeTemplateManager );
	Challenge_ClassSelector				= SpawnChallengeDropdown( 'ChallengeSoldierClass',		"Soldier Class Template",		80, 230 + 65 * 2, class'X2ChallengeSoldierClass', ChallengeTemplateManager );
	Challenge_SquadSize					= SpawnChallengeDropdown( 'ChallengeSquadSize',			"Squad Size Template",			80, 230 + 65 * 1, class'X2ChallengeSquadSize', ChallengeTemplateManager );

	Challenge_EnemyForcesSelector		= SpawnChallengeDropdown( 'ChallengeEnemyForces',		"Enemy Forces Template",		80 + 350, 230 + 65 * 2, class'X2ChallengeEnemyForces', ChallengeTemplateManager );
	Challenge_AlertForceLevelSelector	= SpawnChallengeDropdown( 'ChallengeAlertForce',		"Alert & Force Level Template",	80 + 350, 230 + 65 * 1, class'X2ChallengeAlertForce', ChallengeTemplateManager );

	OnButtonChallengeControlsClicked( Button_ChallengeControls );
}

simulated private function OnButtonStartChallengeClicked(UIButton button)
{
	StartChallengeBattle();
}

simulated function StartChallengeBattle()
{
	if (IsIdle( ) && MapGenerated)
	{
		Movie.Pres.PlayUISound( eSUISound_MenuSelect );
		bGenerateChallengeHistory = true;
		GotoState( 'GoingToBattle' );
	}
	else if (IsIdle( ) && !bMapNeedsClear)
	{
		bAutoStartBattleAfterGeneration = true;
		bGenerateChallengeHistory = true;
		GotoState( 'GeneratingMap' );
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function OnButtonChallengeControlsClicked( UIButton button )
{
	ChallengeControlsVisible = !ChallengeControlsVisible;

	if (ChallengeControlsVisible)
	{
		Button_ChallengeControls.SetText( "Hide Challenge Controls" );

		Challenge_UtilityItemSelector.Show();
		Challenge_SecondaryWeaponSelector.Show();
		Challenge_PrimaryWeaponSelector.Show();
		Challenge_ArmorSelector.Show();
		Challenge_RankSelector.Show();
		Challenge_AlienSelector.Show();
		Challenge_ClassSelector.Show();
		Challenge_SquadSize.Show();

		Challenge_EnemyForcesSelector.Show();
		Challenge_AlertForceLevelSelector.Show();
	}
	else
	{
		Button_ChallengeControls.SetText( "Show Challenge Controls" );

		Challenge_UtilityItemSelector.Hide();
		Challenge_SecondaryWeaponSelector.Hide();
		Challenge_PrimaryWeaponSelector.Hide();
		Challenge_ArmorSelector.Hide();
		Challenge_RankSelector.Hide();
		Challenge_AlienSelector.Hide();
		Challenge_ClassSelector.Hide();
		Challenge_SquadSize.Hide();

		Challenge_EnemyForcesSelector.Hide();
		Challenge_AlertForceLevelSelector.Hide();
	}
}

simulated private function BuildButton_GenerateMap()
{
	local MapGenerationPreset Preset;

	Button_GenerateMap = Spawn(class'UIButton', self);
	Button_GenerateMap.InitButton('Button_GenerateMap', "Generate Map", OnButtonGenerateMapClicked, eUIButtonStyle_NONE);
	Button_GenerateMap.SetGamepadIcon(class'UIUtilities_Input'.static.GetBackButtonIcon());
	Button_GenerateMap.SetPosition(200, 50);

	Dropdown_MapPreset = Spawn(class'UIDropdown', self);
	Dropdown_MapPreset.InitDropdown('MapPreset', "Map Preset", SelectMapPreset);
	Dropdown_MapPreset.SetPosition(800, 50);

	Dropdown_MapPreset.Clear( );
	Dropdown_MapPreset.AddItem( "None" );

	foreach TQLMapPresets( Preset )
	{
		Dropdown_MapPreset.AddItem( Preset.PresetName );
	}

	Dropdown_MapPreset.SetSelected( 0 );
}

simulated function SelectMapPreset( UIDropdown dropdown )
{
	local MapGenerationPreset Preset;
	local array<name> SquadMemberNames;
	local int AlertLevel;

	if (dropdown.SelectedItem > 0)
		Preset = TQLMapPresets[ dropdown.SelectedItem - 1 ];

	if (Preset.PlotName != "")
	{
		BattleDataState.PlotSelectionType = ePlotSelection_Specify;
	}
	else
	{
		BattleDataState.PlotSelectionType = ePlotSelection_Random;
		Preset.AlertLevel = class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty;
		Preset.ForceLevel = 1;
	}

	BattleDataState.m_iMissionType = -1;	// randomize mission type selection

	BattleDataState.MapData.PlotMapName = Preset.PlotName;
	BattleDataState.MapData.Biome = Preset.Biome;
	`ENVLIGHTINGMGR.SetCurrentMap(BattleDataState, "");

	// start with the base alert level
	if (Preset.AlertLevel >= 0)
	{
		AlertLevel = Clamp( Preset.AlertLevel, 
			class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty, 
			class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty);

		// then update with the campaign difficulty modifier
		AlertLevel = Min(AlertLevel + class'X2StrategyGameRulesetDataStructures'.default.CampaignDiffModOnMissionDiff[ 2], 
						class'X2StrategyGameRulesetDataStructures'.default.CampaignDiffMaxDiff[ 2 ]);

		BattleDataState.SetAlertLevel( AlertLevel );
	}

	BattleDataState.SetForceLevel( Preset.ForceLevel );

	if (Preset.SquadName != '')
	{
		class'UITacticalQuickLaunch_MapData'.static.GetSqaudMemberNames( Preset.SquadName, SquadMemberNames );
		class'UITacticalQuickLaunch_MapData'.static.ApplySquad( SquadMemberNames );
		CacheLastUsedSquad( Preset.SquadName );
	}

	if (Preset.QuestItemName != '')
	{
		BattleDataState.m_nQuestItem = Preset.QuestItemName;
	}
}

simulated private function BuildButton_ToggleMapSize()
{
	Button_ToggleMapSize = Spawn(class'UIButton', self);
	Button_ToggleMapSize.InitButton('Button_ToggleMapSize', "Toggle Map Size", OnButtonToggleMapSizeClicked, (`ISCONTROLLERACTIVE) ? eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE : eUIButtonStyle_NONE);
	Button_ToggleMapSize.SetGamepadIcon(class'UIUtilities_Input'.static.GetBackButtonIcon());
	Button_ToggleMapSize.SetPosition(500, 50);
}

simulated private function OnButtonGenerateMapClicked(UIButton button)
{
	if( IsIdle() )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		if(bMapNeedsClear)
		{
			`PARCELMGR.ResetIsFinishedGeneratingMap();
			ConsoleCommand("open TacticalQuickLaunch");
		}
		else
		{
			GotoState('GeneratingMap');
		}
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function OnButtonToggleMapSizeClicked(UIButton button)
{
	if (CanvasDrawScale == 4)
	{
		CanvasDrawScale = 8;
	}
	else
	{
		CanvasDrawScale = 4;
	}
}

simulated private function BuildButton_RerollSpawnPoint()
{
	Button_RerollSpawnPoint = Spawn(class'UIButton', self);
	Button_RerollSpawnPoint.InitButton('Button_RerollSpawnPoint', "Reroll SpawnPoint", OnButtonRerollSpawnPointClicked, eUIButtonStyle_NONE);		
	Button_RerollSpawnPoint.SetGamepadIcon(class'UIUtilities_Input'.static.GetBackButtonIcon());
	Button_RerollSpawnPoint.SetPosition(200, 150);
	Button_RerollSpawnPoint.SetDisabled(true);
}

simulated private function OnButtonRerollSpawnPointClicked(UIButton button)
{
	if(IsIdle())
	{
		ParcelManager.BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		ParcelManager.ChooseSoldierSpawn();
	}
}

simulated private function BuildButton_ChooseMapData()
{
	Button_ChooseMapData = Spawn(class'UIButton', self);
	Button_ChooseMapData.InitButton('Button_ChooseMapData', "Choose Map Data", OnButtonChooseMapDataClicked, eUIButtonStyle_NONE);		
	Button_ChooseMapData.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	Button_ChooseMapData.SetPosition(350, 50);
}

simulated private function OnButtonChooseMapDataClicked(UIButton button)
{
	if( IsIdle() )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		Movie.Stack.Push(Spawn(class'UITacticalQuickLaunch_MapData', Pres));
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function BuildButton_ChooseSquadLoadout()
{
	Button_ChooseSquadLoadout = Spawn(class'UIButton', self);
	Button_ChooseSquadLoadout.InitButton('BuildButton_ChooseSquadLoadout', "Choose Squad", OnButtonChooseSquadLoadoutClicked, eUIButtonStyle_NONE);		
	Button_ChooseSquadLoadout.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
	Button_ChooseSquadLoadout.SetPosition(50, 100);
}

simulated private function OnButtonChooseSquadLoadoutClicked(UIButton button)
{
	if( IsIdle() )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		Movie.Stack.Push(Spawn(class'UITacticalQuickLaunch_SquadLoadout', Pres));
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function BuildButton_ToggleDebugCamera()
{
	Button_ToggleDebugCamera = Spawn(class'UIButton', self);
	Button_ToggleDebugCamera.InitButton('BuildButton_ToggleDebugCamera', "Turn On Debug Camera", OnButton_ToggleDebugCameraClicked, eUIButtonStyle_NONE);		
	Button_ToggleDebugCamera.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
	Button_ToggleDebugCamera.SetPosition(200, 100);
}

simulated function BuildButton_ReturnToShell()
{
	Button_ReturnToShell = Spawn(class'UIButton', self);
	Button_ReturnToShell.InitButton('Button_ReturnToShell', "Return To Shell", OnButtonReturnToShellClicked, eUIButtonStyle_NONE);
	Button_ReturnToShell.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	Button_ReturnToShell.SetPosition(50, 150);
}

simulated private function OnButtonReturnToShellClicked(UIButton button)
{
	OnUCancel();
}

simulated private function OnButton_ToggleDebugCameraClicked(UIButton button)
{
	local rotator DefaultCameraRotation;

	TacticalController.ToggleDebugCamera();	

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	if( !bDebugCameraActive )
	{
		bDebugCameraActive = true;
		Button_ToggleDebugCamera.SetText("Turn OFF Debug Camera");
		//Movie.DeactivateMouse();		
	}
	else
	{
		bDebugCameraActive = false;
		Button_ToggleDebugCamera.SetText("Turn ON Debug Camera");
		//Movie.ActivateMouse();
	}

	if( bShouldInitCamera )
	{
		DefaultCameraRotation = rotator(DefaultCameraDirection);
		TacticalController.PlayerCamera.CameraCache.POV.Location = DefaultCameraPosition;
		TacticalController.PlayerCamera.CameraCache.POV.Rotation.Yaw = DefaultCameraRotation.Yaw;
		TacticalController.PlayerCamera.CameraCache.POV.Rotation.Pitch = DefaultCameraRotation.Pitch;
		bShouldInitCamera = false;
	}
}

simulated private function BuildInfoBox()
{
	BGBox_InfoBox = Spawn(class'UIBGBox', InfoBoxContainer);
	BGBox_InfoBox.InitBG('infoBox', 0, 0, 500, 175);

	Text_InfoBoxTitle = Spawn(class'UIText', InfoBoxContainer);
	Text_InfoBoxTitle.InitText('infoBoxTitle', "<Empty>", true);
	Text_InfoBoxTitle.SetWidth(480);
	Text_InfoBoxTitle.SetY(5);
	Text_InfoBoxTitle.SetText("Instructions:");

	Text_InfoBoxText = Spawn(class'UIText', InfoBoxContainer);	
	Text_InfoBoxText.InitText('infoBoxText', "<Empty>", true);
	Text_InfoBoxText.SetWidth(480);
	Text_InfoBoxText.SetY(45);
	Text_InfoBoxText.SetText("1. Choose Map Data\n2. Generate Map\n3. Wait for map generation to complete\n4. Start Battle or Clear Map");
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_KEY_TAB :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :

		Navigator.GetSelected().OnUnrealCommand(cmd, arg);
		break; 

		//	OnButtonStartBattleClicked(Button_StartBattle);
		//	break;
			
		//case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		//	OnButtonStartBattleClicked(Button_StartBattle);
		//	break;
		//case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		//	OnButtonGenerateMapClicked(Button_GenerateMap);
		//	break;
		//case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
		//	OnButtonChooseMapDataClicked(Button_ChooseMapData);
		//	break;
		//case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		//	OnButtonChooseSquadLoadoutClicked(Button_ChooseSquadLoadout);
		//	break;
		//case class'UIUtilities_input'.const.FXS_BUTTON_L3:
		//	OnButton_ToggleDebugCameraClicked(Button_ToggleDebugCamera);
		//	break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:
			OnLMouseDown();
			break;		
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			OnButtonReturnToShellClicked(Button_ReturnToShell);
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated public function OnUCancel()
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	`XCOMHISTORY.ResetHistory(, false); //Don't leave any of our battle data behind (causes problems for obstacle course launching)
	ConsoleCommand("disconnect");
}

simulated public function OnLMouseDown()
{
	if(HighlightedParcel != none)
	{
		// we've clicked the highlighted parcel, bring up a list of parcel definitions that can be placed on it
		// so the user can custom select one
		ShowSelectParcelDefinitionList(HighlightedParcel);
	}
}

simulated private function array<ParcelDefinition> GetParcelDefsThatFit(XComParcel Parcel, bool ObjectiveParcels)
{
	local array<ParcelDefinition> ParcelDefinitions;
	local ParcelDefinition ParcelDef;
	local int Index;
	local Rotator Rot;

	if(ObjectiveParcels)
	{
		ParcelManager.GetValidParcelDefinitionsForObjective(ParcelManager.arrAllParcelDefinitions, ParcelDefinitions);
	}
	else
	{
		ParcelDefinitions = ParcelManager.arrAllParcelDefinitions;
	}

	// remove any parcels that don't fit
	for (Index = 0; Index < ParcelDefinitions.Length; Index++)
	{
		ParcelDef = ParcelDefinitions[Index];
		if(ParcelDef.eSize != Parcel.GetSizeType() 
			|| !ParcelManager.MeetsFacingAndEntranceRequirements(ParcelDef, Parcel, Rot)
			|| ParcelDef.arrPlotTypes.Find('strPlotType', ParcelManager.PlotType.strType) == INDEX_NONE)
		{
			ParcelDefinitions.Remove(Index, 1);
			Index--;
		}
	}

	return ParcelDefinitions;
}

simulated private function ShowSelectParcelDefinitionList(XComParcel Parcel)
{
	local array<ParcelDefinition> ParcelDefinitions;
	local ParcelDefinition ParcelDef;
	local UITacticalQuickLaunch_ListItem ListItem;

	if(Parcel != none && ParcelDefinitionList == none)
	{
		ParcelDefinitionList = Spawn(class'UIList', self);
		ParcelDefinitionList.InitList(, 200, 200, 800, 700, false, true);
		ParcelDefinitionList.OnItemClicked = OnParcelDefinitionItemClicked;

		// add a list item for "keep current". Effectively the cancel button
		ListItem = Spawn(class'UITacticalQuickLaunch_ListItem', ParcelDefinitionList.itemContainer);
		ListItem.InitListItem("(Keep Current)");
		ListItem.metadataString = "Cancel";

		// add non-objective options
		ParcelDefinitions = GetParcelDefsThatFit(Parcel, false);
		foreach ParcelDefinitions(ParcelDef)
		{
			ListItem = Spawn(class'UITacticalQuickLaunch_ListItem', ParcelDefinitionList.itemContainer);
			ListItem.InitListItem(ParcelDef.MapName);
			ListItem.metadataString = "Nonobjective";
			ListItem.ParcelDef = ParcelDef;
		}

		// add the objective parcel options
		if(Parcel.CanBeObjectiveParcel)
		{
			ParcelDefinitions = GetParcelDefsThatFit(Parcel, true);
			foreach ParcelDefinitions(ParcelDef)
			{
				ListItem = Spawn(class'UITacticalQuickLaunch_ListItem', ParcelDefinitionList.itemContainer);
				ListItem.InitListItem("(Objective) " $ ParcelDef.MapName);
				ListItem.metadataString = "Objective";
				ListItem.ParcelDef = ParcelDef;
			}
		}
	}

	if(ParcelDefinitionList.scrollbar != none) 
	{
		ParcelDefinitionList.scrollbar.Reset();
	}
}

// After changing out a parcel, we need to remove any states for interactive objects
// that were created for actors in the old parcel. Otherwise, there will be phantom states
// with no associated actors flying around and confusing the game.
private native function PurgeLostObjectStates(Vector LevelOffset);

function OnParcelDefinitionItemClicked(UIList listControl, int itemIndex)
{
	local UITacticalQuickLaunch_ListItem SelectedItem;
	local Rotator Rot;
	local int Index;
	
	assert(HighlightedParcel != none);
	if(HighlightedParcel != none)
	{
		SelectedItem = UITacticalQuickLaunch_ListItem(listControl.GetItem(itemIndex));

		if(SelectedItem.metadataString != "Cancel" && ParcelManager.MeetsFacingAndEntranceRequirements(SelectedItem.ParcelDef, HighlightedParcel, Rot))
		{
			PurgeLostObjectStates(HighlightedParcel.Location);
			HighlightedParcel.CleanupSpawnedEntrances();

			// remove the old parcel data from the save data store
			for (Index = 0; Index < BattleDataState.MapData.ParcelData.Length; ++Index)
			{
				if (BattleDataState.MapData.ParcelData[ Index ].MapName == HighlightedParcel.ParcelDef.MapName)
				{
					BattleDataState.MapData.ParcelData.Remove( Index, 1 );
					break;
				}
			}
			`assert( BattleDataState.MapData.ParcelData.Length == (ParcelManager.arrParcels.Length - 1) );

			`MAPS.RemoveStreamingMapByNameAndLocation(HighlightedParcel.ParcelDef.MapName, HighlightedParcel.Location);
			ParcelManager.ClearLinksFromParcelPatrolPathsToPlotPaths();
			ParcelManager.InitParcelWithDef(HighlightedParcel, SelectedItem.ParcelDef, Rot, true);
			bPathingNeedsRebuilt = true;

			// if they selected one of the "objective" parcel types, i.e. they want to change the
			// map *and* make this the new objective parcel, then set the new objective parcel and
			// clear the previous one
			if(SelectedItem.metadataString == "Objective")
			{
				ParcelManager.ObjectiveParcel = HighlightedParcel;
				Button_StartBattle.SetDisabled(false);
				Button_StartChallenge.SetDisabled(false);
			}
			else if(HighlightedParcel == ParcelManager.ObjectiveParcel)
			{
				ParcelManager.ObjectiveParcel = none;

				// plots with only a single parcel are test plots. Allow those to start without a valid objective parcel
				Button_StartBattle.SetDisabled(BattleDataState.MapData.ParcelData.Length > 1);
				Button_StartChallenge.SetDisabled(BattleDataState.MapData.ParcelData.Length > 1);
			}
		}
	}

	`assert(ParcelDefinitionList == listControl);
	ParcelDefinitionList.Remove();
	ParcelDefinitionList = none;
	HighlightedParcel = none;
}

function bool IsIdle()
{
	return IsInState('Idle');
}

simulated private function GetPlotRenderBounds(out Vector2D UpperLeft, optional out Vector2D Dimension)
{
	local Vector2D ViewportSize;

	if (`XWORLD == none)
		return;

	Dimension.X = `XWORLD.NumX * CanvasDrawScale;
	Dimension.Y = `XWORLD.NumY * CanvasDrawScale;

	class'Engine'.static.GetEngine().GameViewport.GetViewportSize(ViewportSize);

	UpperLeft.X = ViewportSize.X - Dimension.X - 60;
	UpperLeft.Y = BGBox_InfoBox.Y + 250;
}

simulated private function GetParcelRenderBounds(XComParcel Parcel, out Vector2D UpperLeft, optional out Vector2D Dimension)
{
	local Vector2D PlotCorner;
	local IntPoint OutParcelBoundsMin;
	local IntPoint OutParcelBoundsMax;

	GetPlotRenderBounds(PlotCorner);
	Parcel.GetTileBounds(OutParcelBoundsMin, OutParcelBoundsMax);

	UpperLeft.X = (float(OutParcelBoundsMin.X) * CanvasDrawScale) + PlotCorner.X;
	UpperLeft.Y = (float(OutParcelBoundsMin.Y) * CanvasDrawScale) + PlotCorner.Y;

	Dimension.X = (OutParcelBoundsMax.X - OutParcelBoundsMin.X)  * CanvasDrawScale;
	Dimension.Y = (OutParcelBoundsMax.Y - OutParcelBoundsMin.Y) * CanvasDrawScale;
}

simulated private function Vector2D GetSpawnRenderLocation(XComGroupSpawn Spawn)
{
	local Vector2D PlotCorner;
	local TTile TileLoc;
	local Vector2D Result;

	if (`XWORLD != none && Spawn != none)
	{
		GetPlotRenderBounds(PlotCorner);
		TileLoc = `XWORLD.GetTileCoordinatesFromPosition(Spawn.Location);

		Result.X = (float(TileLoc.X) * CanvasDrawScale) + PlotCorner.X;
		Result.Y = (float(TileLoc.Y) * CanvasDrawScale) + PlotCorner.Y;
	}

	return Result;
}

simulated private function bool GetObjectiveRenderLocation(out Vector2D Result)
{
	local Vector2D PlotCorner;
	local Vector ObjectivesCenter;
	local TTile TileLoc;
	GetPlotRenderBounds(PlotCorner);
	if(TacticalMissionManager.GetLineOfPlayEndpoint(ObjectivesCenter))
	{
		TileLoc = `XWORLD.GetTileCoordinatesFromPosition(ObjectivesCenter);

		Result.X = (float(TileLoc.X) * CanvasDrawScale) + PlotCorner.X;
		Result.Y = (float(TileLoc.Y) * CanvasDrawScale) + PlotCorner.Y;
		
		return true;
	}
	else
	{
		return false;
	}
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local int Index;
	local XComParcel IterateParcel;	

	local Vector2D ScreenLocation_PlotCorner;
	local Vector2D PlotSize;

	local Vector2D ParcelUpperLeft;
	local Vector2D ParcelDimension;
	local float Highlight;

	//Soldier spawn handling
	local Vector2D ScreenLocation_Spawn;
	local XGBattle Battle;
	local XComGroupSpawn GroupSpawn;

	//Objective parcel handling
	local Vector2D ScreenLocation_ObjectivesCenter;

	if( bDebugCameraActive && !ParcelManager.IsGeneratingMap())
	{
		Text_InfoBoxTitle.SetText("Debug Camera");
		Text_InfoBoxText.SetText("Camera Position:"@vCameraPosition@"\nDirection:"@vCameraDir);
	}

	if( bMapNeedsClear && kCanvas != none )
	{
		GetPlotRenderBounds(ScreenLocation_PlotCorner, PlotSize);

		//Draw rectangles for the parcels
		for( Index = 0; Index < ParcelManager.arrParcels.Length; ++Index )
		{
			IterateParcel = ParcelManager.arrParcels[Index];
			GetParcelRenderBounds(IterateParcel, ParcelUpperLeft, ParcelDimension);

			kCanvas.SetPos(ParcelUpperLeft.X, ParcelUpperLeft.Y);

			Highlight = IterateParcel == HighlightedParcel ? 1.0 : 1.5;

			if( IterateParcel == ParcelManager.ObjectiveParcel )
			{
				kCanvas.SetDrawColor(205 * Highlight, 50 * Highlight, 50 * Highlight, 200);
			}
			else
			{
				kCanvas.SetDrawColor(50 * Highlight, 50 * Highlight, 205 * Highlight, 200);				
			}	

			if( `MAPS.IsLevelLoaded(name(IterateParcel.ParcelDef.MapName), true) )
			{
				kCanvas.DrawRect( ParcelDimension.X, ParcelDimension.Y);
			}
			else
			{
				kCanvas.DrawBox( ParcelDimension.X, ParcelDimension.Y);
			}
		}

		//Draw text for the parcels
		for( Index = 0; Index < ParcelManager.arrParcels.Length; ++Index )
		{
			IterateParcel = ParcelManager.arrParcels[Index];
			GetParcelRenderBounds(IterateParcel, ParcelUpperLeft, ParcelDimension);

			kCanvas.SetPos(ParcelUpperLeft.X, ParcelUpperLeft.Y);
			kCanvas.SetDrawColor(255, 255, 255);
			kCanvas.DrawText(IterateParcel.ParcelDef.MapName@(IterateParcel == ParcelManager.ObjectiveParcel ? "\n(Objective:"@TacticalMissionManager.ActiveMission.MissionName@")" : "" ));
		}

		//If the map has finished generating, show objective / spawn information if it is available
		if( !ParcelManager.IsGeneratingMap() )
		{
			Battle = `BATTLE;
			foreach Battle.AllActors(class'XComGroupSpawn', GroupSpawn)
			{
				ScreenLocation_Spawn = GetSpawnRenderLocation(GroupSpawn);

				kCanvas.SetPos(ScreenLocation_Spawn.X, ScreenLocation_Spawn.Y);

				if( GroupSpawn == ParcelManager.SoldierSpawn )
				{
					kCanvas.SetDrawColor(255, 255, 255);
					kCanvas.DrawText("Spawn (" $ ParcelManager.SoldierSpawn.Score $ ")");

					if( GetObjectiveRenderLocation(ScreenLocation_ObjectivesCenter) )
					{
						kCanvas.SetDrawColor(0, 255, 0);
						kCanvas.Draw2DLine(ScreenLocation_Spawn.X, ScreenLocation_Spawn.Y,
										   ScreenLocation_ObjectivesCenter.X, ScreenLocation_ObjectivesCenter.Y,
										   kCanvas.DrawColor);
					}
				}
				else
				{
					kCanvas.SetDrawColor(50, 50, 50);
					kCanvas.DrawText("(" $ GroupSpawn.Score $ ")");
				}

				kCanvas.DrawRect(CanvasDrawScale * 3, CanvasDrawScale * 3); // 3x3 tile spawn
			}
		}		

		//Draw the plot rect last so that its text is not overwritten by parcel / exit rectangles
		kCanvas.SetPos(ScreenLocation_PlotCorner.X, ScreenLocation_PlotCorner.Y);
		kCanvas.SetDrawColor(50, 180, 50, 80);
		kCanvas.DrawRect(PlotSize.X, PlotSize.Y);

		kCanvas.SetPos(ScreenLocation_PlotCorner.X, ScreenLocation_PlotCorner.Y);
		kCanvas.SetDrawColor(255, 255, 255);
		kCanvas.DrawText(BattleDataState.MapData.PlotMapName);
	}
}

event Tick(float DeltaTime)
{
	local XComParcel Parcel;
	local Vector2D UpperLeft;
	local Vector2D Dimensions;
	local Vector2D MousePos;

	super.Tick(DeltaTime);

	if(ParcelManager != none && ParcelDefinitionList == none)
	{
		HighlightedParcel = none;
		MousePos = class'Engine'.static.GetEngine().GameViewport.GetMousePosition();
		foreach ParcelManager.arrParcels(Parcel)
		{
			GetParcelRenderBounds(Parcel, UpperLeft, Dimensions);
			if(MousePos.X > UpperLeft.X 
				&& MousePos.Y > UpperLeft.Y
				&& MousePos.X < (UpperLeft.X + Dimensions.X)
				&& MousePos.Y < (UpperLeft.Y + Dimensions.Y))
			{
				HighlightedParcel = Parcel;
				break;
			}
		}
	}
}

simulated function CleanupMaps()
{
	`MAPS.RemoveAllStreamingMaps();	
	ParcelManager.CleanupLevelReferences();
}

auto state Idle
{
	simulated event BeginState(name PreviousStateName)
	{	
	}
}

state GoingToBattle
{
	function StartBattle()
	{
		local XComGameState TacticalStartState;
		local XComGameState_BattleData LatestBattleDataState;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_Unit ExamineUnit;
		local Name GameplayTag;

		// this needs to be a separate function or else unreal will bail on the latent function as soon as we pop
		// ourself, instead of finishing and initing the battle		
		Movie.Stack.Pop(self);

		//Mark that we are tactical quick launch
		TacticalStartState = History.GetStartState();
		LatestBattleDataState = XComGameState_BattleData( TacticalStartState.GetGameStateForObjectID( BattleDataState.ObjectID ) );
		LatestBattleDataState.bIsTacticalQuickLaunch = History.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) == none;

		class'X2SitRepTemplate'.static.ModifyPreMissionBattleDataState(LatestBattleDataState, LatestBattleDataState.ActiveSitReps);

		// update the headquarters squad to contain our TQL soldiers
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(TacticalStartState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		foreach TacticalGameplayTags(GameplayTag)
		{
			if( XComHQ.TacticalGameplayTags.Find(GameplayTag) == INDEX_NONE )
			{
				XComHQ.TacticalGameplayTags.AddItem(GameplayTag);
			}
		}

		XComHQ.Squad.Length = 0;
		foreach TacticalStartState.IterateByClassType(class'XComGameState_Unit', ExamineUnit)
		{
			if (ExamineUnit.GetTeam() == eTeam_XCom)
			{
				XComHQ.Squad.AddItem(ExamineUnit.GetReference());
			}
		}

		`CHEATMGR.DisableFirstEncounterVO = true;

		`TACTICALGRI.InitBattle();
	}

	function UpdatePlotSwaps()
	{
		local string PlotType;

		PlotType = ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName).strType;
		class'XComPlotSwapData'.static.AdjustParcelsForBiomeType(BattleDataState.MapData.Biome, PlotType, BattleDataState.MapData.ActiveMission.sType);
		class'XComBrandManager'.static.SwapBrandsForParcels(BattleDataState.MapData);
	}

Begin:
	// make sure we aren't still loading anything
	while(!`MAPS.IsStreamingComplete())
	{
		Sleep(0);
	}

	if(bPathingNeedsRebuilt)
	{
		ParcelManager.RebuildWorldData();
		UpdatePlotSwaps();
		bPathingNeedsRebuilt = false;
	}

	if( !bStoredMouseIsActive )
	{
		Movie.DeactivateMouse();
	}

	RemoveHUDOverlayActor();

	//Make sure the debug camera is off
	if( bDebugCameraActive )
	{
		OnButton_ToggleDebugCameraClicked(Button_ToggleDebugCamera);
	}

	StartBattle();
}

state ClearingMap
{
Begin:
	while( `MAPS.NumStreamingMaps() > 0 )
	{
		CleanupMaps();
		Sleep(0.1f);
	}

	PopState();
}

state GeneratingMap
{
	simulated event BeginState(name PreviousStateName)
	{	
		local XComOnlineProfileSettings Profile;
		local XComGameState StartState;

		StartState = History.GetStartState();

		Profile = `XPROFILESETTINGS;
		Profile.WriteTacticalGameStartState(StartState);

		// add the strategy game start info to the tactical start state
		if (bGenerateChallengeHistory)
		{
			InitWithChallengeHistory( );
			bGenerateChallengeHistory = false;
		}

		`ONLINEEVENTMGR.SaveProfileSettings();

		if( !bDebugCameraActive )
		{
			OnButton_ToggleDebugCameraClicked(Button_ToggleDebugCamera);
		}
			
		Button_StartBattle.SetDisabled(true);
		Button_GenerateMap.SetDisabled(true);
		Button_ChooseMapData.SetDisabled(true);
		Button_ChooseSquadLoadout.SetDisabled(true);
		Button_StartChallenge.SetDisabled(true);

		MapGenerated = false;
	}

	simulated function X2ChallengeTemplate GetChallengeTemplate( UIDropdown Dropdown, class<X2ChallengeTemplate> TemplateType, X2ChallengeTemplateManager TemplateManager, optional array<name> PrevSelectorNames )
	{
		local X2ChallengeTemplate Template;
		local string TemplateName;

		if (Dropdown.SelectedItem == 0)
		{
			Template = TemplateManager.GetRandomChallengeTemplateOfClass(TemplateType, PrevSelectorNames);
		}
		else
		{
			TemplateName = Dropdown.GetSelectedItemText( );
			Template = TemplateManager.FindChallengeTemplate( name( TemplateName ) );
		}

		`assert( Template !=  none );

		return Template;
	}

	function InitWithChallengeHistory( )
	{
		local XComGameState StartState;
		local XComGameStateContext_TacticalGameRule TacticalStartContext;
		local XComGameState_Player XComPlayerState;
		local XComGameState_Player EnemyPlayerState;
		local XComGameState_Player CivilianPlayerState;
		local XComGameState_Player TheLostPlayerState;
		local XComGameState_Player ResistancePlayer;
		local XComGameState_Player TeamOneState;
		local XComGameState_Player TeamTwoState; //issue #188 added variables		
		local XComGameState_Analytics Analytics;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_CampaignSettings CampaignSettings;
		local XComGameState_HeadquartersXCom HeadquartersStateObject;
		local XComGameState_BattleData OldBattleData;
		local XComGameState_TimerData Timer;
		local int AlertLevel, ForceLevel;
		local X2ChallengeTemplateManager ChallengeTemplateManager;
		local X2ChallengeAlertForce AlertForceSelector;
		local X2ChallengeEnemyForces EnemyForcesSelector;
		local array<name> PrevSelectors;
		local name TacticalGameplayTagToAdd;

		OldBattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ));

		History.ResetHistory(, false);

		TacticalStartContext = XComGameStateContext_TacticalGameRule( class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext( ) );
		TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
		StartState = History.CreateNewGameState( false, TacticalStartContext );
		History.AddGameStateToHistory( StartState );

		BattleDataState = XComGameState_BattleData( StartState.CreateNewStateObject( class'XComGameState_BattleData' ) );

		BattleDataState.MapData = OldBattleData.MapData;
		BattleDataState.PlotData = OldBattleData.PlotData;
		BattleDataState.iLevelSeed = OldBattleData.iLevelSeed;
		BattleDataState.m_iMissionType = OldBattleData.m_iMissionType;
		BattleDataState.m_nQuestItem = OldBattleData.m_nQuestItem;
		BattleDataState.PlotType = OldBattleData.PlotType;
		BattleDataState.ActiveSitReps = OldBattleData.ActiveSitReps;
		BattleDataState.PlotSelectionType = OldBattleData.PlotSelectionType;

		// Civilians are always pro-advent
		BattleDataState.SetPopularSupport( 0 );
		BattleDataState.SetMaxPopularSupport( 1 );

		BattleDataState.m_strDesc = "Challenge Mode"; //If you change this, be aware that this is how the ruleset knows the battle is a challenge mode battle
		BattleDataState.m_strOpName = class'XGMission'.static.GenerateOpName( false );
		BattleDataState.m_strMapCommand = "open" @ BattleDataState.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";

		XComPlayerState = class'XComGameState_Player'.static.CreatePlayer( StartState, eTeam_XCom );
		XComPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
		BattleDataState.PlayerTurnOrder.AddItem( XComPlayerState.GetReference( ) );

		EnemyPlayerState = class'XComGameState_Player'.static.CreatePlayer( StartState, eTeam_Alien );
		EnemyPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
		BattleDataState.PlayerTurnOrder.AddItem( EnemyPlayerState.GetReference( ) );

		CivilianPlayerState = class'XComGameState_Player'.static.CreatePlayer( StartState, eTeam_Neutral );
		CivilianPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
		BattleDataState.CivilianPlayerRef = CivilianPlayerState.GetReference( );

		TheLostPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_TheLost);
		TheLostPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
		BattleDataState.PlayerTurnOrder.AddItem(TheLostPlayerState.GetReference());

		ResistancePlayer = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Resistance);
		ResistancePlayer.bPlayerReady = true;
		BattleDataState.PlayerTurnOrder.AddItem(ResistancePlayer.GetReference());
		
		TeamOneState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_One); //issue #188 - initing MP teams here for TQL
		TeamOneState.bPlayerReady = true;
		BattleDataState.PlayerTurnOrder.AddItem(TeamOneState.GetReference());
		
		TeamTwoState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Two);
		TeamTwoState.bPlayerReady = true;
		BattleDataState.PlayerTurnOrder.AddItem(TeamTwoState.GetReference());	//end #188
		
		// create a default cheats object
		StartState.CreateNewStateObject( class'XComGameState_Cheats' );

		ChallengeData = XComGameState_ChallengeData( StartState.CreateNewStateObject( class'XComGameState_ChallengeData' ) );
		ChallengeData.LeaderBoardName = BattleDataState.m_strOpName /*@ LeaderBoardSuffix*/;

		Analytics = XComGameState_Analytics( StartState.CreateNewStateObject( class'XComGameState_Analytics' ) );
		Analytics.SubmitToFiraxisLive = false;

		CampaignSettings = XComGameState_CampaignSettings( StartState.CreateNewStateObject( class'XComGameState_CampaignSettings' ) );
		CampaignSettings.SetDifficulty( 2 ); // Force challenge mode to 'Commander' difficulty
		CampaignSettings.SetIronmanEnabled( true );
		CampaignSettings.SetSuppressFirstTimeNarrativeEnabled( true );
		CampaignSettings.SetTutorialEnabled( false );

		HeadquartersStateObject = XComGameState_HeadquartersXCom( StartState.CreateNewStateObject( class'XComGameState_HeadquartersXCom' ) );
		HeadquartersStateObject.AdventLootWeight = class'XComGameState_HeadquartersXCom'.default.StartingAdventLootWeight;
		HeadquartersStateObject.AlienLootWeight = class'XComGameState_HeadquartersXCom'.default.StartingAlienLootWeight;
		HeadquartersStateObject.bHasPlayedAmbushTutorial = true;
		HeadquartersStateObject.bHasPlayedMeleeTutorial = true;
		HeadquartersStateObject.bHasPlayedNeutralizeTargetTutorial = true;
		HeadquartersStateObject.SetGenericKeyValue( "NeutralizeTargetTutorial", 1 );

		StartState.CreateNewStateObject( class'XComGameState_ObjectivesList' );

 		Timer = XComGameState_TimerData( StartState.CreateNewStateObject( class'XComGameState_TimerData' ) );
 		Timer.bIsChallengeModeTimer = true;
 		Timer.SetTimerData( EGSTT_AppRelativeTime, EGSTDT_Down, EGSTRT_None );
 		Timer.SetRealTimeTimer( 30 * 60 );
		Timer.bStopTime = true;

		class'XComGameState_HeadquartersResistance'.static.SetUpHeadquarters(StartState, false);

		class'XComGameState_HeadquartersAlien'.static.SetUpHeadquarters(StartState);

		class'XComGameState_GameTime'.static.CreateGameStartTime( StartState );

		AddRandomSoldiers( StartState, XComPlayerState, HeadquartersStateObject, ChallengeData, PrevSelectors );

		SetupChallengeMissionSite( StartState, BattleDataState );

		BattleDataState.SetGlobalAbilityEnabled( 'PlaceEvacZone', false, StartState );

		ChallengeTemplateManager = class'X2ChallengeTemplateManager'.static.GetChallengeTemplateManager( );

		AlertForceSelector = X2ChallengeAlertForce( GetChallengeTemplate( Challenge_AlertForceLevelSelector, class'X2ChallengeAlertForce', ChallengeTemplateManager, PrevSelectors ) );
		class'X2ChallengeAlertForce'.static.SelectAlertAndForceLevels( AlertForceSelector, StartState, HeadquartersStateObject, AlertLevel, ForceLevel );
		ChallengeData.AlertForceLevelSelectorName = AlertForceSelector.DataName;
		PrevSelectors.AddItem(AlertForceSelector.DataName);

		BattleDataState.SetAlertLevel( AlertLevel );
		BattleDataState.SetForceLevel( ForceLevel );

		EnemyForcesSelector = X2ChallengeEnemyForces( GetChallengeTemplate( Challenge_EnemyForcesSelector, class'X2ChallengeEnemyForces', ChallengeTemplateManager, PrevSelectors ) );
		ChallengeData.EnemyForcesSelectorName = EnemyForcesSelector.DataName;

		foreach EnemyForcesSelector.AdditionalTacticalGameplayTags (TacticalGameplayTagToAdd)
		{		
			HeadquartersStateObject.TacticalGameplayTags.AddItem( TacticalGameplayTagToAdd );
		}

		class'X2ChallengeEnemyForces'.static.SelectEnemyForces( EnemyForcesSelector, ChallengeMissionSite, BattleDataState, StartState );

		Pres.TacticalStartState = StartState;

		//History.WriteHistoryToFile( "SaveData_Dev/", "ChallengeStartState_" @ LeaderBoardSuffix );
	}

	function AddRandomSoldiers( XComGameState StartState, XComGameState_Player XComPlayerState, XComGameState_HeadquartersXCom HeadquartersStateObject, XComGameState_ChallengeData ChallengeData, out array<name> PrevSelectors )
	{
		local XGCharacterGenerator CharacterGenerator;
		local int SoldierCount, AlienCount;
		local int SoldierIndex, PartIndex;
		local X2ChallengeTemplateManager ChallengeTemplateManager;
		local X2ChallengeSquadSize SquadSizeSelector;
		local X2ChallengeSoldierClass ClassSelector;
		local X2ChallengeSquadAlien AlienSelector;
		local X2ChallengeSoldierRank RankSelector;
		local X2ChallengeArmor ArmorSelector;
		local X2ChallengePrimaryWeapon PrimaryWeaponSelector;
		local X2ChallengeSecondaryWeapon SecondaryWeaponSelector;
		local X2ChallengeUtility UtilityItemSelector;
		local array<name> ClassNames;
		local XComGameState_Unit BuildUnit;
		local TSoldier Soldier;
		local X2CharacterTemplate CharTemplate;
		local X2SoldierClassTemplate ClassTemplate;
		local array<XComGameState_Unit> XComUnits;
		local name RequiredLoadout;
		local XComOnlineProfileSettings kProfileSettings;
		local array<PartPackPreset> OldPartPackPresets;

		// forcibly set the profile data with 0% chances to select any DLC customization options
		kProfileSettings = `XPROFILESETTINGS;
		OldPartPackPresets = kProfileSettings.Data.PartPackPresets;
		for (PartIndex = 0; PartIndex < kProfileSettings.Data.PartPackPresets.Length; ++PartIndex)
		{
			kProfileSettings.Data.PartPackPresets[ PartIndex ].ChanceToSelect = 0.0f;
		}

		ChallengeTemplateManager = class'X2ChallengeTemplateManager'.static.GetChallengeTemplateManager( );

		SquadSizeSelector = X2ChallengeSquadSize( GetChallengeTemplate( Challenge_SquadSize, class'X2ChallengeSquadSize', ChallengeTemplateManager ) );
		class'X2ChallengeSquadSize'.static.SelectSquadSize( SquadSizeSelector, SoldierCount, AlienCount );
		PrevSelectors.AddItem(SquadSizeSelector.DataName);

		ClassSelector = X2ChallengeSoldierClass( GetChallengeTemplate( Challenge_ClassSelector, class'X2ChallengeSoldierClass', ChallengeTemplateManager, PrevSelectors ) );
		ClassNames = class'X2ChallengeSoldierClass'.static.SelectSoldierClasses( ClassSelector, SoldierCount );
		PrevSelectors.AddItem(ClassSelector.DataName);

		for (SoldierIndex = 0; SoldierIndex < SoldierCount; ++SoldierIndex)
		{
			ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager( ).FindSoldierClassTemplate( ClassNames[SoldierIndex] );
			`assert(ClassTemplate != none);

			CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate((ClassTemplate.RequiredCharacterClass != '') ? ClassTemplate.RequiredCharacterClass : 'Soldier');
			`assert(CharTemplate != none);
			CharacterGenerator = `XCOMGRI.Spawn(CharTemplate.CharacterGeneratorClass);
			`assert(CharacterGenerator != None);

			BuildUnit = CharTemplate.CreateInstanceFromTemplate( StartState );
			BuildUnit.SetSoldierClassTemplate( ClassTemplate.DataName );
			BuildUnit.SetControllingPlayer( XComPlayerState.GetReference( ) );

			// Randomly roll what the character looks like
			Soldier = CharacterGenerator.CreateTSoldier( );
			BuildUnit.SetTAppearance( Soldier.kAppearance );
			BuildUnit.SetCharacterName( Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName );
			BuildUnit.SetCountry( Soldier.nmCountry );
			if (!BuildUnit.HasBackground( ))
				BuildUnit.GenerateBackground( , CharacterGenerator.BioCountryName);

			HeadquartersStateObject.Squad.AddItem( BuildUnit.GetReference( ) );
			XComUnits.AddItem( BuildUnit );
		}

		RankSelector = X2ChallengeSoldierRank( GetChallengeTemplate( Challenge_RankSelector, class'X2ChallengeSoldierRank', ChallengeTemplateManager, PrevSelectors ) );
		class'X2ChallengeSoldierRank'.static.SelectSoldierRanks( RankSelector, XComUnits, StartState );
		PrevSelectors.AddItem(RankSelector.DataName);

		ArmorSelector = X2ChallengeArmor( GetChallengeTemplate( Challenge_ArmorSelector, class'X2ChallengeArmor', ChallengeTemplateManager, PrevSelectors ) );
		class'X2ChallengeArmor'.static.SelectSoldierArmor( ArmorSelector, XComUnits, StartState );
		PrevSelectors.AddItem(ArmorSelector.DataName);

		PrimaryWeaponSelector = X2ChallengePrimaryWeapon( GetChallengeTemplate( Challenge_PrimaryWeaponSelector, class'X2ChallengePrimaryWeapon', ChallengeTemplateManager, PrevSelectors ) );
		class'X2ChallengePrimaryWeapon'.static.SelectSoldierPrimaryWeapon( PrimaryWeaponSelector, XComUnits, StartState );
		PrevSelectors.AddItem(PrimaryWeaponSelector.DataName);

		SecondaryWeaponSelector = X2ChallengeSecondaryWeapon( GetChallengeTemplate( Challenge_SecondaryWeaponSelector, class'X2ChallengeSecondaryWeapon', ChallengeTemplateManager, PrevSelectors ) );
		class'X2ChallengeSecondaryWeapon'.static.SelectSoldierSecondaryWeapon( SecondaryWeaponSelector, XComUnits, StartState );
		PrevSelectors.AddItem(SecondaryWeaponSelector.DataName);

		UtilityItemSelector = X2ChallengeUtility( GetChallengeTemplate( Challenge_UtilityItemSelector, class'X2ChallengeUtility', ChallengeTemplateManager, PrevSelectors ) );
		class'X2ChallengeUtility'.static.SelectSoldierUtilityItems( UtilityItemSelector, XComUnits, StartState );
		PrevSelectors.AddItem(UtilityItemSelector.DataName);

		//  Always apply the template's required loadout. XPad's and whatnot
		for (SoldierIndex = 0; SoldierIndex < SoldierCount; ++SoldierIndex)
		{
			RequiredLoadout = CharTemplate.RequiredLoadout;
			if (RequiredLoadout != '')
				XComUnits[SoldierIndex].ApplyInventoryLoadout( StartState, RequiredLoadout );
		}

		CharacterGenerator.Destroy( );

		if (AlienCount > 0)
		{
			AlienSelector = X2ChallengeSquadAlien( GetChallengeTemplate( Challenge_AlienSelector, class'X2ChallengeSquadAlien', ChallengeTemplateManager, PrevSelectors ) );
			ClassNames = class'X2ChallengeSquadAlien'.static.SelectAlienTypes( AlienSelector, AlienCount );
			PrevSelectors.AddItem(AlienSelector.DataName);

			for (SoldierIndex = 0; SoldierIndex < AlienCount; ++SoldierIndex )
			{
				CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager( ).FindCharacterTemplate( ClassNames[SoldierIndex] );
				`assert(CharTemplate != none);

				BuildUnit = CharTemplate.CreateInstanceFromTemplate( StartState );
				BuildUnit.SetControllingPlayer( XComPlayerState.GetReference( ) );
				BuildUnit.ApplyInventoryLoadout( StartState );

				HeadquartersStateObject.Squad.AddItem( BuildUnit.GetReference( ) );
			}
		}

		ChallengeData.SquadSizeSelectorName = SquadSizeSelector.DataName;
		ChallengeData.ClassSelectorName = ClassSelector.DataName;
		ChallengeData.AlienSelectorName = AlienSelector.DataName;
		ChallengeData.RankSelectorName = RankSelector.DataName;
		ChallengeData.ArmorSelectorName = ArmorSelector.DataName;
		ChallengeData.PrimaryWeaponSelectorName = PrimaryWeaponSelector.DataName;
		ChallengeData.SecondaryWeaponSelectorName = SecondaryWeaponSelector.DataName;
		ChallengeData.UtilityItemSelectorName = UtilityItemSelector.DataName;

		// restore the player's profile data
		kProfileSettings.Data.PartPackPresets = OldPartPackPresets;
	}

	function string GetRandomChallengeMissionType()
	{
		local int Index;
		local array<PlotDefinition> PlotsForPlotType;
		local PlotDefinition PlotDef;
		local XComTacticalMissionManager MissionManager;
		local array<string> ValidMissionTypes, ValidChallengeMissionTypes;
		local MissionDefinition MissionDef;
		local ChallengeMissionScoring Scoring;

		MissionManager = `TACTICALMISSIONMGR;
		ParcelManager = `PARCELMGR;

		foreach class'XComChallengeModeManager'.default.DefaultChallengeMissionScoringTable(Scoring)
		{
			ValidChallengeMissionTypes.AddItem( string(Scoring.MissionType) );
		}

		if (BattleDataState.PlotSelectionType == ePlotSelection_Random)
		{
			ValidMissionTypes = ValidChallengeMissionTypes;
		}
		else if (BattleDataState.PlotSelectionType == ePlotSelection_Type)
		{
			ParcelManager.GetPlotDefinitionsForPlotType(BattleDataState.PlotType, "", PlotsForPlotType);

			foreach PlotsForPlotType(PlotDef)
			{
				foreach MissionManager.arrMissions(MissionDef)
				{
					if (ValidMissionTypes.Find(MissionDef.sType) != INDEX_NONE)
						continue;

					if (ValidChallengeMissionTypes.Find( MissionDef.sType ) == INDEX_NONE)
						continue;

					if (!ParcelManager.IsPlotValidForMission(PlotDef, MissionDef))
						continue;

					ValidMissionTypes.AddItem(MissionDef.sType);
				}
			}
		}
		else // PlotSelectionType == ePlotSelection_Specify
		{
			PlotDef = ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName, "");

			// only add missions that are supported by the specified plot type
			foreach MissionManager.arrMissions(MissionDef)
			{
				if(ParcelManager.IsPlotValidForMission(PlotDef, MissionDef))
				{
					if (ValidChallengeMissionTypes.Find( MissionDef.sType ) == INDEX_NONE)
						continue;

					ValidMissionTypes.AddItem(MissionDef.sType);
				}
			}
		}

		if (ValidMissionTypes.Length == 0)
		{
			`Redscreen( "Plot type does not support any valid challenge mission types, falling back on a completely random mission type" );
			ValidMissionTypes = ValidChallengeMissionTypes;
		}

		Index = `SYNC_RAND( ValidMissionTypes.Length );
		return ValidMissionTypes[ Index ];
	}

	function SetupChallengeMissionSite( XComGameState StartState, XComGameState_BattleData OldBattleData )
	{
		local XComGameState_Continent Continent;
		local XComGameState_WorldRegion Region;

		local X2StrategyElementTemplateManager StratMgr;
		local array<X2StrategyElementTemplate> ContinentDefinitions;
		local X2ContinentTemplate RandContinentTemplate;
		local X2WorldRegionTemplate RandRegionTemplate;

		local int RandContinent, RandRegion;
		local Vector CenterLoc, RegionExtents;

		if (BattleDataState.m_iMissionType < 0)
		{
			BattleDataState.m_iMissionType = TacticalMissionManager.arrMissions.Find( 'sType', GetRandomChallengeMissionType());
		}

		// Disable standard reinforcements
		BattleDataState.ActiveSitReps.AddItem('ChallengeNoReinforcements');

		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager( );
		ContinentDefinitions = StratMgr.GetAllTemplatesOfClass( class'X2ContinentTemplate' );

		RandContinent = `SYNC_RAND(ContinentDefinitions.Length);
		RandContinentTemplate = X2ContinentTemplate( ContinentDefinitions[ RandContinent ] );

		RandRegion = `SYNC_RAND( RandContinentTemplate.Regions.Length );
		RandRegionTemplate = X2WorldRegionTemplate( StratMgr.FindStrategyElementTemplate( RandContinentTemplate.Regions[ RandRegion ] ) );

		Continent = XComGameState_Continent( StartState.CreateNewStateObject( class'XComGameState_Continent', RandContinentTemplate ) );

		Region = XComGameState_WorldRegion( StartState.CreateNewStateObject( class'XComGameState_WorldRegion', RandRegionTemplate ) );

		Continent.AssignRegions( StartState );

		// Choose random location from the region
		RegionExtents.X = (RandRegionTemplate.Bounds[ 0 ].fRight - RandRegionTemplate.Bounds[ 0 ].fLeft) / 2.0f;
		RegionExtents.Y = (RandRegionTemplate.Bounds[ 0 ].fBottom - RandRegionTemplate.Bounds[ 0 ].fTop) / 2.0f;
		CenterLoc.x = RandRegionTemplate.Bounds[ 0 ].fLeft + RegionExtents.X;
		CenterLoc.y = RandRegionTemplate.Bounds[ 0 ].fTop + RegionExtents.Y;

		ChallengeMissionSite = XComGameState_MissionSite( StartState.CreateNewStateObject( class'XComGameState_MissionSite' ) );
		ChallengeMissionSite.Location = CenterLoc + (`SYNC_VRAND() * RegionExtents);
		ChallengeMissionSite.Continent.ObjectID = Continent.ObjectID;
		ChallengeMissionSite.Region.ObjectID = Region.ObjectID;

		ChallengeMissionSite.GeneratedMission.MissionID = ChallengeMissionSite.ObjectID;
		ChallengeMissionSite.GeneratedMission.Mission = `TACTICALMISSIONMGR.arrMissions[ BattleDataState.m_iMissionType ];
		ChallengeMissionSite.GeneratedMission.LevelSeed = BattleDataState.iLevelSeed;
		ChallengeMissionSite.GeneratedMission.BattleOpName = BattleDataState.m_strOpName;
		ChallengeMissionSite.GeneratedMission.BattleDesc = "ChallengeMode";
		ChallengeMissionSite.GeneratedMission.MissionQuestItemTemplate = BattleDataState.m_nQuestItem;
		ChallengeMissionSite.GeneratedMission.SitReps = BattleDataState.ActiveSitReps;

		BattleDataState.m_iMissionID = ChallengeMissionSite.ObjectID;
	}

	simulated event EndState(name NextStateName)
	{
		WorldInfo.MyLightClippingManager.BuildFromScript();
		`XWORLDINFO.MyLocalEnvMapManager.SetEnableCaptures(TRUE);
	}

	function LoadPlot()
	{
		//General locals
		local MissionDefinition Mission;
		local XComParcelManager ParcelMgr;
		local array<PlotDefinition> CandidatePlots;
		local PlotDefinition SelectedPlotDef;
		local int Index, ValidCount;
		local Vector ZeroVector;
		local Rotator ZeroRotator;
		local LevelStreaming PlotLevel;
		local XComGameState_MissionSite TQLMissionSite;
		local XComTacticalMissionManager TacticalMissionMgr;
		local X2ChallengeTemplateManager ChallengeTemplateManager;
		local X2ChallengeEnemyForces EnemyForcesTemplate;
		local XComGameState_HeadquartersXCom XComHQ;

		ParcelMgr = `PARCELMGR;

		// get the pool of possible plots
		switch(BattleDataState.PlotSelectionType)
		{
		case ePlotSelection_Random:
			// any plot will do
			CandidatePlots = ParcelMgr.arrPlots;
			break;

		case ePlotSelection_Type:
			// all plots of the desired type
			ParcelMgr.GetPlotDefinitionsForPlotType(BattleDataState.PlotType, BattleDataState.MapData.Biome, CandidatePlots);
			break;

		case ePlotSelection_Specify:
			// the specified plot map
			if( BattleDataState.MapData.PlotMapName != "" )
			{
				CandidatePlots.AddItem(ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName, BattleDataState.MapData.Biome));
			}
			break;
		}

		// Now filter the candidate list by mission type (some plots only support certain mission types)
		if(BattleDataState.m_iMissionType >= 0)
		{
			Mission = `TACTICALMISSIONMGR.arrMissions[BattleDataState.m_iMissionType];
			ParcelMgr.RemovePlotDefinitionsThatAreInvalidForMission(CandidatePlots, Mission);
			if( CandidatePlots.Length == 0 )
			{
				// none of the candidates were valid for the mission, so fall back to using any plot
				CandidatePlots = ParcelMgr.arrPlots;
				ParcelMgr.RemovePlotDefinitionsThatAreInvalidForMission(CandidatePlots, Mission);
				`Redscreen("Selected parcel or parcel type does not support the selected mission, falling back to to using any valid plot.");
			}
		}

		// if we aren't in specifying an exact map, remove all maps that are marked as exclude from strategy
		if(BattleDataState.PlotSelectionType != ePlotSelection_Specify)
		{
			for(Index = CandidatePlots.Length - 1; Index >= 0; Index--)
			{
				if(CandidatePlots[Index].ExcludeFromStrategy)
				{
					CandidatePlots.Remove(Index, 1);
				}
			}
		}

		// and pick one
		Index = `SYNC_RAND_TYPED(CandidatePlots.Length);
		SelectedPlotDef = CandidatePlots[Index];

		// notify the deck manager that we have used this plot
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('Plots', SelectedPlotDef.MapName);

		// need to add the plot type to make sure it's in the deck
		class'X2CardManager'.static.GetCardManager().AddCardToDeck('PlotTypes', ParcelManager.GetPlotDefinition(SelectedPlotDef.MapName).strType);
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('PlotTypes', ParcelManager.GetPlotDefinition(SelectedPlotDef.MapName).strType);

		// load the selected plot
		BattleDataState.MapData.PlotMapName = SelectedPlotDef.MapName;
		PlotLevel = `MAPS.AddStreamingMap(BattleDataState.MapData.PlotMapName, ZeroVector, ZeroRotator, false, true);
		PlotLevel.bForceNoDupe = true;

		// make sure our biome is sane for the plot we selected
		if(BattleDataState.MapData.Biome == "" 
			|| (SelectedPlotDef.ValidBiomes.Length > 0 && SelectedPlotDef.ValidBiomes.Find(BattleDataState.MapData.Biome) == INDEX_NONE))
		{
			if(SelectedPlotDef.ValidBiomes.Length > 0)
			{
				Index = `SYNC_RAND(SelectedPlotDef.ValidBiomes.Length);
				BattleDataState.MapData.Biome = SelectedPlotDef.ValidBiomes[Index];
			}
			else
			{
				BattleDataState.MapData.Biome = "";
			}
		}

		TQLMissionSite = XComGameState_MissionSite( History.GetGameStateForObjectID( BattleDataState.m_iMissionID ) );
		if (TQLMissionSite != none)
		{
			TQLMissionSite.GeneratedMission.Plot = SelectedPlotDef;

			if (BattleDataState.MapData.Biome != "")
				TQLMissionSite.GeneratedMission.Biome = `PARCELMGR.GetBiomeDefinition( BattleDataState.MapData.Biome );
		}

		if (BattleDataState.m_iMissionType < 0)
		{
			ValidCount = 0;

			TacticalMissionMgr = `TACTICALMISSIONMGR;

			// pick any random mission that supports the current plot
			for (Index = 0; Index < TacticalMissionMgr.arrMissions.Length; ++Index)
			{
				Mission = TacticalMissionMgr.arrMissions[Index];

				if(ParcelMgr.IsPlotValidForMission(SelectedPlotDef, Mission))
				{
					ValidCount++;
					if(`SYNC_RAND(ValidCount) == 0)
					{
						BattleDataState.m_iMissionType = Index;
						break;
					}
				}
			}
			`assert( BattleDataState.m_iMissionType > 0 );

			if ((TQLMissionSite != none) && (ChallengeMissionSite == none))
			{
				TQLMissionSite.GeneratedMission.Mission = TacticalMissionMgr.arrMissions[ BattleDataState.m_iMissionType ];

				if (BattleDataState.TQLEnemyForcesSelection != "")
				{
					ChallengeTemplateManager = class'X2ChallengeTemplateManager'.static.GetChallengeTemplateManager( );

					EnemyForcesTemplate = X2ChallengeEnemyForces( ChallengeTemplateManager.FindChallengeTemplate( name( BattleDataState.TQLEnemyForcesSelection ) ) );
					if (EnemyForcesTemplate != none)
					{
						// Add any tactical gameplay tags required by the enemy forces selector
						XComHQ = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
						if (EnemyForcesTemplate.AdditionalTacticalGameplayTags.Length > 0)
						{		
							for (Index = 0; Index < EnemyForcesTemplate.AdditionalTacticalGameplayTags.Length; ++Index)
							{
								XComHQ.TacticalGameplayTags.AddItem( EnemyForcesTemplate.AdditionalTacticalGameplayTags[Index] );
								XComHQ.CleanUpTacticalTags( );
							}
						}
						class'X2ChallengeEnemyForces'.static.SelectEnemyForces( EnemyForcesTemplate, TQLMissionSite, BattleDataState, BattleDataState.GetParentGameState() );
					}
				}
			}
		}

		if (Mission.ForcedTacticalTags.Length > 0)
		{
			XComHQ = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
			for (Index = 0; Index < Mission.ForcedTacticalTags.Length; ++Index)
			{
				XComHQ.TacticalGameplayTags.AddItem( Mission.ForcedTacticalTags[Index] );
				XComHQ.CleanUpTacticalTags( );
			}
		}

		if (History.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress', true ) != none)
		{
			`MAPS.RemoveAllStreamingMaps( );
			BattleDataState.m_strMapCommand = "open" @ BattleDataState.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";
			ConsoleCommand( BattleDataState.m_strMapCommand );
			GotoState('Idle');
		}
	}

	simulated event Tick( float fDeltaT )
	{
		local int Phase;
		if( ParcelManager.IsGeneratingMap() )
		{
			Phase = ParcelManager.GetGenerateMapPhase();
			if( Phase != LastPhase )
			{
				LastPhase = Phase;
				PhaseTime = 0.0f;
			}
		}

		PhaseTime += fDeltaT;
	}

	simulated function UpdatePhaseText(int Phase)
	{
		local int Index;
		local string TextAccumulator;

		//PhaseText will grow as new indices are assigned
		PhaseText[Phase] = ParcelManager.GetGenerateMapPhaseText()@":"@PhaseTime@" sec";

		for( Index = 1; Index < PhaseText.Length; ++Index )
		{
			TextAccumulator = TextAccumulator @ PhaseText[Index] @ "\n";
		}

		Text_InfoBoxText.SetText(TextAccumulator);
	}

Begin:

	// The last part of map generation expects the ruleset to be in a state that has these caches available to use
	`TACTICALRULES.CachedHistory = `XCOMHISTORY;
	
	PushState('ClearingMap');

	LoadPlot();

	bMapNeedsClear = true;

	//Wait for the plot to load
	while (!`MAPS.IsStreamingComplete())
	{
		Sleep(0.0f);
	}

	ProcLevelSeed = class'Engine'.static.GetEngine().GetARandomSeed();
	BattleDataState.iLevelSeed = ProcLevelSeed;
	ParcelManager.bBlockingLoadParcels = false; //Set the ParcelManager to operate in async mode
	ParcelManager.GenerateMap(ProcLevelSeed);
	
	Text_InfoBoxTitle.SetText("Generating Map");
	LastPhase = ParcelManager.GetGenerateMapPhase();
	PhaseTime = 0.0f;
	PhaseText.Length = 0;

	//Wait while the parcel mgr builds the map for us
	while( ParcelManager.IsGeneratingMap() )
	{
		UpdatePhaseText(ParcelManager.GetGenerateMapPhase());
		Sleep(0.1f);
	}

	// resave the profile so that the plot and parcel cards we've used will be saved to the bottom of the deck
	`ONLINEEVENTMGR.SaveProfileSettings();

	MapGenerated = true;

	Button_GenerateMap.SetText("Clear Map");
	Button_StartBattle.SetDisabled(false);
	Button_ChooseSquadLoadout.SetDisabled(false);
	Button_RerollSpawnPoint.SetDisabled(false);
	Button_StartChallenge.SetDisabled(false);
	
	if( !WorldInfo.IsPlayInEditor() )
	{
		//PIE cannot reload the quick launch map, so cannot be cleared
		Button_GenerateMap.SetDisabled(false);
		Button_ChooseMapData.SetDisabled(false);	
	}
	
	if(bAutoStartBattleAfterGeneration)
	{
		GotoState('GoingToBattle');
	}
	else
	{
		GotoState('Idle');
	}
}

static native function CacheLastUsedSquad( name SquadName );
static native function name GetLastUsedSquad( );
static native function ResetLastUsedSquad( );

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	bShouldInitCamera = true
	DefaultCameraPosition = (X=2968.12, Y=5473.12, Z=3072.99)
	DefaultCameraDirection = (X=-0.51, Y=-0.68, Z=-0.53)

	CanvasDrawScale = 4
}
