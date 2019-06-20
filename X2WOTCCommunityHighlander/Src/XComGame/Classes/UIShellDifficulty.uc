//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIShellDifficulty.uc
//  AUTHOR:  Brit Steiner       -- 01/25/12
//           Tronster           -- 04/13/12
//  PURPOSE: Controls the difficulty menu in the shell SP game. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIShellDifficulty extends UIScreen
	native(UI);

var localized string m_strSelectDifficulty;
var localized string m_strChangeDifficulty;

var localized array<string>  m_arrDifficultyTypeStrings;
var localized array<string>  m_arrDifficultyDescStrings;

var localized string m_strDifficultyEnableTutorial;
var localized string m_strDifficultyEnableProgeny;
var localized string m_strDifficultyEnableSlingshot;
var localized string m_strDifficultyEnableIronman;
var localized string m_strDifficultySuppressFirstTimeNarrativeVO;

var localized string m_strSecondWaveDesc;
var localized string m_strDifficultyTutorialDesc;
var localized string m_strDifficultyProgenyDesc;
var localized string m_strDifficultySlingshotDesc;
var localized string m_strDifficultyIronmanDesc;
var localized string m_strDifficultySuppressFirstTimeNarrativeVODesc;

var localized string m_strDifficulty_Back;
var localized string m_strDifficulty_ToggleAdvanced;
var localized string m_strDifficulty_ToggleAdvancedExit;
var localized string m_strDifficulty_Accept;
var localized string m_strDifficulty_SecondWaveButtonLabel;

var localized string m_strControlTitle;
var localized string m_strControlBody;
var localized string m_strControlOK;
var localized string m_strControlCancel;

var localized string m_strFirstTimeTutorialTitle;
var localized string m_strFirstTimeTutorialBody;
var localized string m_strFirstTimeTutorialYes;
var localized string m_strFirstTimeTutorialNo;

var localized string m_strChangeDifficultySettingTitle;
var localized string m_strChangeDifficultySettingBody;
var localized string m_strChangeDifficultySettingYes;
var localized string m_strChangeDifficultySettingNo;

var localized string m_strInvalidTutorialClassicDifficulty;

var localized string m_strIronmanTitle;
var localized string m_strIronmanBody;
var localized string m_strIronmanOK;
var localized string m_strIronmanCancel;

var localized string m_strIronmanLabel;
var localized string m_strTutorialLabel;

var localized string m_strTutorialOnImpossible;
var localized string m_strTutorialNoChangeToImpossible;
var localized string m_strNoChangeInGame;

var localized string m_strWaitingForSaveTitle;
var localized string m_strWaitingForSaveBody;


var localized string TacticalDifficultyString;
var localized string StrategyDifficultyString;
var localized string GameLengthString;

var localized string ImpossibleString;

var localized string GameLengthShortString;
var localized string GameLengthStandardString;
var localized string GameLengthLongString;
var localized string GameLengthRediculousString;

var localized string SecondWaveScoreString;
var localized string OverallScoreString;
var localized string SecondWavePanelTitle; 

struct native DifficultyConfiguration
{
	var float TacticalDifficulty;
	var float StrategyDifficulty;
	var float GameLength;
};

var config array<DifficultyConfiguration> DifficultyConfigurations;

// these arrays mark, for each array index, where the corresponding value threshold lies
// ex. if TacticalIndexThresholds[1] = 25, then any tactical slider value of 0.0-24.9 would correspond to Tactical Index 0
var config array<float> TacticalIndexThresholds;
var config array<float> StrategyIndexThresholds;
var config array<float> GameLengthIndexThresholds;

struct native SliderValueToDifficultyMap
{
	var float ThresholdValue;		// at this threshold value
	var float DifficultyValue;  // this difficulty value should be displayed
};

var config array<SliderValueToDifficultyMap> TacticalDifficultyMap;
var config array<SliderValueToDifficultyMap> StrategyDifficultyMap;
var config array<SliderValueToDifficultyMap> GameLengthDifficultyMap;

struct native SecondWaveOption
{
	var Name ID;
	var int DifficultyValue;
};

var config array<SecondWaveOption> SecondWaveOptions;
var localized array<string> SecondWaveDescriptions;
var localized array<string> SecondWaveToolTips;

// top panel - basic difficulty selection
var UIPanel			 m_TopPanel;
var UIMechaListItem  m_DifficultyRookieMechaItem;
var UIMechaListItem  m_DifficultyVeteranMechaItem;
var UIMechaListItem  m_DifficultyCommanderMechaItem;
var UIMechaListItem  m_DifficultyLegendMechaItem;

var UISlider		 m_TacticalDifficultySlider;
var UISlider		 m_StrategyDifficultySlider;
var UISlider		 m_GameLengthSlider;

// second wave panel
var UIMechaListItem  m_SecondWaveButton;
var UIPanel			 m_AdvancedOptions;
var UIList			 m_SecondWaveList;

// bottom panel - major options selection
var UIPanel			 m_BottomPanel;
var UIMechaListItem  m_TutorialMechaItem;
var UIMechaListItem  m_FirstTimeVOMechaItem;
var UIMechaListItem  m_SubtitlesMechaItem;
var UIMechaListItem  m_SoundtrackMechaItem;

// navigation
//var UIButton         m_CancelButton;
var UILargeButton	 m_StartButton;

// track if the second wave panel is open
var bool m_bSecondWaveOpen;

var bool bUpdatingSlidersFromDifficultySelection;

var int  m_iSelectedDifficulty;

var bool m_bControlledStart;
var bool m_bIntegratedDLC;
var bool m_bIronmanFromShell;
var bool m_bSuppressFirstTimeNarrative;

var bool m_bShowedFirstTimeTutorialNotice;
var bool m_bShowedFirstTimeChangeDifficultyWarning;
var bool m_bCompletedControlledGame;
var bool m_bReceivedIronmanWarning;

var bool m_bSaveInProgress;

var bool m_bIsPlayingGame;
var bool m_bViewingAdvancedOptions;

var int m_iOptIronMan;
var int m_iOptTutorial;
var int m_iOptProgeny;
var int m_iOptSlingshot;
var int m_iOptFirstTimeNarrative;

var array<name> EnabledOptionalNarrativeDLC;

var UIShellStrategy DevStrategyShell;
var UINavigationHelp NavHelp;

//----------------------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	//bsg-crobinson (5.15.17): Set correct navhelp based on what screen we're in
	// 1 - Main Menu. 2 - Tactical. 3 - Strategy
	if(Movie.Pres.m_eUIMode == eUIMode_Shell)
	{
		NavHelp = InitController.Pres.GetNavHelp();
	}
	else if (`PRES != none) //bsg-crobinson (5.16.17): Added the else to show navhelp in the main menu
	{
		NavHelp = Spawn(class'UINavigationHelp', Movie.Stack.GetScreen(class'UIMouseGuard')).InitNavHelp();
	}
	else
	{
		NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	}
	//bsg-crobinson (5.15.17): end

	InitChecboxValues();

	BuildMenu();

	//About to start a new campaign, start precaching city center maps
	`MAPS.PrecacheMapsForPlotType("CityCenter");

	// These player profile flags will change what options are defaulted when this menu comes up
	// SCOTT RAMSAY/RYAN BAKER: Has the player ever completed the strategy tutorial?
	m_bCompletedControlledGame = true; // `BATTLE.STAT_GetProfileStat(eProfile_TutorialComplete) > 0; // Ryan Baker - Hook up when we are ready.
	// SCOTT RAMSAY: Has the player ever received the ironman warning?
	m_bReceivedIronmanWarning = false;

	`XPROFILESETTINGS.Data.ClearGameplayOptions();

	//If we came from the dev strategy shell and opted for the cheat start, then just launch into the game after setting our settings
	DevStrategyShell = UIShellStrategy(Movie.Pres.ScreenStack.GetScreen(class'UIShellStrategy'));
	if(DevStrategyShell != none && DevStrategyShell.m_bCheatStart)
	{
		m_bControlledStart = false; // disable the tutorial
		OnDifficultyConfirm(m_StartButton);
	}

	UpdateNavHelp(); //bsg-crobinson (5.3.17): Update NavHelp when Initing the screen

	//bsg-jneal (1.25.17): fixing up controller input for difficulty screen
	if( `ISCONTROLLERACTIVE )
	{
		Navigator.SetSelected(m_TopPanel);
	}
	//bsg-jneal (1.25.17): fixing up controller input for difficulty screen
	
	m_TopPanel.Navigator.OnSelectedIndexChanged = OnSelectedIndexChanged;
	m_BottomPanel.Navigator.OnSelectedIndexChanged = OnSelectedIndexChanged;

	MC.FunctionVoid("AnimateIn");
	RefreshDescInfo();
}

//bsg-crobinson (5.3.17): Update NavHelp for difficulty screen
simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(OnUCancel);
	NavHelp.AddSelectNavHelp();
}
//bsg-crobinson (5.3.17): end

simulated function InitChecboxValues()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	History = `XCOMHISTORY;

		CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));

	m_bShowedFirstTimeTutorialNotice = `XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting;

	if(CampaignSettingsStateObject != none && CampaignSettingsStateObject.bCheatStart)
	{
		m_bControlledStart = false;
	}
	else
	{
		m_bControlledStart = !`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting;
		m_bIronmanFromShell = false;
		m_bSuppressFirstTimeNarrative = false;  //RAM - TODO - enable / disable based on whether the campaign has been played before or not
	}
}

//----------------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local UIPanel CurrentSelection;

	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;

	if(m_bSaveInProgress)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return true;
	}

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
		//bsg-jneal (1.25.17): fixing up controller input for difficulty screen
		if( `ISCONTROLLERACTIVE && m_bSecondWaveOpen )
		{
			CurrentSelection = m_SecondWaveList.Navigator.GetSelected();
			if(CurrentSelection != None)
			{
				UIMechaListItem(CurrentSelection).OnClickDelegate();
			}
		}
		else
		{
			CurrentSelection = Navigator.GetSelected();
			if(CurrentSelection != None)
			{
				bHandled = CurrentSelection.OnUnrealCommand(cmd, arg);
			}
		}
		//bsg-jneal (1.25.17): end
		
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		//bsg-jneal (1.25.17): fixing up controller input for difficulty screen
		if( m_bSecondWaveOpen )
		{
			CloseSecondWave();
		}
		else
		{
			NavHelp.ClearButtonHelp(); //bsg-crobinson (3.24.17): be sure to clear the navhelp
			OnUCancel();
		}
		//bsg-jneal (1.25.17): end
		break;


	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
	case class'UIUtilities_Input'.const.FXS_ARROW_UP:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
	case class'UIUtilities_Input'.const.FXS_KEY_W:
		PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
	case class'UIUtilities_Input'.const.FXS_KEY_S:
		PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
		break;

	//bsg-jneal (1.25.17): fixing up controller input for difficulty screen
	case class'UIUtilities_Input'.const.FXS_BUTTON_X :
		if( `ISCONTROLLERACTIVE && !m_bSecondWaveOpen ) //bsg-jneal (5.19.17): do not allowing continue from second wave options
			UIIronMan(m_StartButton);
		break;
	//bsg-jneal (1.25.17): end

	default:
		bHandled = false;
	}

	//Refresh data as our selection may have changed
	RefreshDescInfo();

	return bHandled || super.OnUnrealCommand(cmd, arg);
}


//----------------------------------------------------------------------------

simulated function BuildMenu()
{
	local string strDifficultyTitle;
	local UIPanel LinkPanel;
	local UIMechaListItem LinkMechaList;
	local int OptionIndex;
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	History = `XCOMHISTORY;

		CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));

	// Title
	strDifficultyTitle = (m_bIsPlayingGame) ? m_strChangeDifficulty : m_strSelectDifficulty;
	
	AS_SetDifficultyMenu(
		strDifficultyTitle, 
		m_arrDifficultyTypeStrings[0],
		m_arrDifficultyTypeStrings[1],
		m_arrDifficultyTypeStrings[2],
		m_arrDifficultyTypeStrings[3],
		m_strDifficulty_SecondWaveButtonLabel,
		m_strDifficultyEnableTutorial,
		m_strDifficultySuppressFirstTimeNarrativeVO,
		class'UIOptionsPCScreen'.default.m_strInterfaceLabel_ShowSubtitles,
		GetDifficultyButtonText());

	if(Movie.Pres.m_eUIMode == eUIMode_Shell)
	{
		m_iSelectedDifficulty = 1; //Default to normal 
	}
	else
	{
		m_iSelectedDifficulty = `CAMPAIGNDIFFICULTYSETTING;  //Get the difficulty from the game
	}

	//////////////////
	// top panel
	LinkPanel = Spawn(class'UIPanel', self);
	LinkPanel.bAnimateOnInit = false;
	LinkPanel.bCascadeSelection = true;
	LinkPanel.bCascadeFocus = false;
	LinkPanel.InitPanel('topPanel');
	m_TopPanel = LinkPanel;

	m_DifficultyRookieMechaItem = Spawn(class'UIMechaListItem', LinkPanel);
	m_DifficultyRookieMechaItem.bAnimateOnInit = false;
	m_DifficultyRookieMechaItem.InitListItem('difficultyRookieButton');
	m_DifficultyRookieMechaItem.SetWidgetType(EUILineItemType_Checkbox);
	m_DifficultyRookieMechaItem.UpdateDataCheckbox(m_arrDifficultyTypeStrings[0], "", m_iSelectedDifficulty == 0, UpdateDifficulty, OnButtonDifficultyRookie);
	m_DifficultyRookieMechaItem.BG.SetTooltipText(m_arrDifficultyDescStrings[0], , , 10, , , , 0.0f);

	m_DifficultyVeteranMechaItem = Spawn(class'UIMechaListItem', LinkPanel);
	m_DifficultyVeteranMechaItem.bAnimateOnInit = false;
	m_DifficultyVeteranMechaItem.InitListItem('difficultyVeteranButton');
	m_DifficultyVeteranMechaItem.SetWidgetType(EUILineItemType_Checkbox);
	m_DifficultyVeteranMechaItem.UpdateDataCheckbox(m_arrDifficultyTypeStrings[1], "", m_iSelectedDifficulty == 1, UpdateDifficulty, OnButtonDifficultyVeteran);
	m_DifficultyVeteranMechaItem.BG.SetTooltipText(m_arrDifficultyDescStrings[1], , , 10, , , , 0.0f);

	m_DifficultyCommanderMechaItem = Spawn(class'UIMechaListItem', LinkPanel);
	m_DifficultyCommanderMechaItem.bAnimateOnInit = false;
	m_DifficultyCommanderMechaItem.InitListItem('difficultyCommanderButton');
	m_DifficultyCommanderMechaItem.SetWidgetType(EUILineItemType_Checkbox);
	m_DifficultyCommanderMechaItem.UpdateDataCheckbox(m_arrDifficultyTypeStrings[2], "", m_iSelectedDifficulty == 2, UpdateDifficulty, OnButtonDifficultyCommander);
	m_DifficultyCommanderMechaItem.BG.SetTooltipText(m_arrDifficultyDescStrings[2], , , 10, , , , 0.0f);

	m_DifficultyLegendMechaItem = Spawn(class'UIMechaListItem', LinkPanel);
	m_DifficultyLegendMechaItem.bAnimateOnInit = false;
	m_DifficultyLegendMechaItem.InitListItem('difficultyLegendButton');
	m_DifficultyLegendMechaItem.SetWidgetType(EUILineItemType_Checkbox);
	m_DifficultyLegendMechaItem.UpdateDataCheckbox(m_arrDifficultyTypeStrings[3], "", m_iSelectedDifficulty == 3, UpdateDifficulty, OnButtonDifficultyLegend);
	m_DifficultyLegendMechaItem.BG.SetTooltipText(m_arrDifficultyDescStrings[3], , , 10, , , , 0.0f);
	
	m_DifficultyLegendMechaItem.Checkbox.SetReadOnly(`REPLAY.bInTutorial);
	
	//////////////////
	// Second Wave panel
	LinkPanel = Spawn(class'UIPanel', self);
	LinkPanel.bAnimateOnInit = false;
	LinkPanel.bIsNavigable = false;
	LinkPanel.bCascadeSelection = true;
	LinkPanel.bCascadeFocus = false;
	LinkPanel.InitPanel('AdvancedOptions');
	LinkPanel.Hide();
	LinkPanel.MC.FunctionString("SetTitle", SecondWavePanelTitle);
	m_AdvancedOptions = LinkPanel;

	m_SecondWaveList = Spawn(class'UIList', LinkPanel);
	m_SecondWaveList.InitList('advancedListMC',,,846);
	//m_SecondWaveList.InitList('advancedListMC');
	m_SecondWaveList.Navigator.LoopSelection = false;
	m_SecondWaveList.Navigator.LoopOnReceiveFocus = true;
	m_SecondWaveList.OnItemClicked = OnSecondWaveOptionClicked;
	m_SecondWaveList.OnSelectionChanged = OnSecondWaveDescritionUpdate;

	`assert(SecondWaveOptions.Length == SecondWaveDescriptions.Length);

	for( OptionIndex = 0; OptionIndex < SecondWaveOptions.Length; ++OptionIndex )
	{
		LinkMechaList = Spawn(class'UIMechaListItem', m_SecondWaveList.ItemContainer);
		LinkMechaList.bAnimateOnInit = false;
		LinkMechaList.InitListItem();
		LinkMechaList.SetWidgetType(EUILineItemType_Checkbox);
		// bsg-jrebar (5/9/17): On controller, we do this by item, instead of by panel
		if(`ISCONTROLLERACTIVE)
			LinkMechaList.UpdateDataCheckbox(SecondWaveDescriptions[OptionIndex], "", CampaignSettingsStateObject.IsSecondWaveOptionEnabled(SecondWaveOptions[OptionIndex].ID), , OnAdvancedOptionsClicked);
		else
			LinkMechaList.UpdateDataCheckbox(SecondWaveDescriptions[OptionIndex], "", CampaignSettingsStateObject.IsSecondWaveOptionEnabled(SecondWaveOptions[OptionIndex].ID), );
		//bsg-jrebar (5/9/17): end
		
		// Set the checkbox ready only bool directly so that we still see the check mark box (actually, it's still enabled, but the m_SecondWaveList.OnItemClicked is what will toggle the checkbox
		// we disable the checkbox here so that we don't get double click feedback)
		LinkMechaList.Checkbox.bReadOnly = true;
	}

	//////////////////
	// bottom panel

	LinkPanel = Spawn(class'UIPanel', self);
	LinkPanel.bAnimateOnInit = false;
	LinkPanel.bCascadeSelection = true;
	LinkPanel.bCascadeFocus = false;
	LinkPanel.InitPanel('bottomPanel');
	m_BottomPanel = LinkPanel;

	m_SecondWaveButton = Spawn(class'UIMechaListItem', LinkPanel);
	m_SecondWaveButton.bAnimateOnInit = false;
	m_SecondWaveButton.InitListItem('difficultySecondWaveButton');
	m_SecondWaveButton.SetWidgetType(EUILineItemType_Description);
	m_SecondWaveButton.UpdateDataDescription(m_strDifficulty_SecondWaveButtonLabel,OnButtonSecondWave);
	m_SecondWaveButton.BG.SetTooltipText(m_strSecondWaveDesc, , , 10, , , , 0.0f); // We need a localized string setup for this

	if( Movie.Pres.m_eUIMode != eUIMode_Shell )
		m_SecondWaveButton.Hide();

	// this panel currently default to open:
	m_bSecondWaveOpen = true;
	CloseSecondWave();

	m_TutorialMechaItem = Spawn(class'UIMechaListItem', LinkPanel);
	m_TutorialMechaItem.bAnimateOnInit = false;
	m_TutorialMechaItem.InitListItem('difficultyTutorialButton');
	m_TutorialMechaItem.SetWidgetType(EUILineItemType_Checkbox);
	m_TutorialMechaItem.UpdateDataCheckbox(m_strDifficultyEnableTutorial, "", m_bControlledStart, ConfirmControlDialogue, OnClickedTutorial);
	m_TutorialMechaItem.Checkbox.SetReadOnly(m_bIsPlayingGame);
	m_TutorialMechaItem.BG.SetTooltipText(m_strDifficultyTutorialDesc, , , 10, , , , 0.0f);

	m_FirstTimeVOMechaItem = Spawn(class'UIMechaListItem', LinkPanel);
	m_FirstTimeVOMechaItem.bAnimateOnInit = false;
	m_FirstTimeVOMechaItem.InitListItem('difficultyReduceVOButton');
	m_FirstTimeVOMechaItem.SetWidgetType(EUILineItemType_Checkbox);
	m_FirstTimeVOMechaItem.UpdateDataCheckbox(m_strDifficultySuppressFirstTimeNarrativeVO, "", m_bSuppressFirstTimeNarrative, UpdateFirstTimeNarrative, OnClickFirstTimeVO);
	m_FirstTimeVOMechaItem.Checkbox.SetReadOnly(m_bIsPlayingGame);
	m_FirstTimeVOMechaItem.BG.SetTooltipText(m_strDifficultySuppressFirstTimeNarrativeVODesc, , , 10, , , , 0.0f);
	UpdateFirstTimeNarrative(m_FirstTimeVOMechaItem.Checkbox);
	
	m_SubtitlesMechaItem = Spawn(class'UIMechaListItem', LinkPanel);
	m_SubtitlesMechaItem.bAnimateOnInit = false;
	m_SubtitlesMechaItem.InitListItem('difficultySubtitlesButton');
	m_SubtitlesMechaItem.SetWidgetType(EUILineItemType_Checkbox);
	m_SubtitlesMechaItem.UpdateDataCheckbox(class'UIOptionsPCScreen'.default.m_strInterfaceLabel_ShowSubtitles, "", `XPROFILESETTINGS.Data.m_bSubtitles, UpdateSubtitles, OnClickSubtitles);
	m_SubtitlesMechaItem.BG.SetTooltipText(class'UIOptionsPCScreen'.default.m_strInterfaceLabel_ShowSubtitles_Desc, , , 10, , , , 0.0f);

	if( `ONLINEEVENTMGR.HasTLEEntitlement() )
	{
		m_SoundtrackMechaItem = Spawn(class'UIMechaListItem', LinkPanel);
		m_SoundtrackMechaItem.bAnimateOnInit = false;
		m_SoundtrackMechaItem.InitListItem('difficultySoundtrackButton');
		m_SoundtrackMechaItem.UpdateDataValue(class'UIOptionsPCScreen'.default.m_strAudioLabel_Soundtrack, "", OnClickSoundtrack);
		m_SoundtrackMechaItem.BG.SetTooltipText(class'UIOptionsPCScreen'.default.m_strAudioLabel_Soundtrack_Desc, , , 10, , , , 0.0f);
		m_SoundtrackMechaItem.SetPosition(20, 164);
	}

	if(m_bIsPlayingGame)
	{
		// bsg-jrebar (4/26/17): Disable all nav and hide all buttons
		m_FirstTimeVOMechaItem.Hide();
		m_FirstTimeVOMechaItem.DisableNavigation();
		m_TutorialMechaItem.Hide();
		m_TutorialMechaItem.DisableNavigation();
		m_SubtitlesMechaItem.Hide();
		m_SubtitlesMechaItem.DisableNavigation();
		m_SoundtrackMechaItem.Hide();
		m_SoundtrackMechaItem.DisableNavigation();
		m_SecondWaveButton.DisableNavigation();
		m_BottomPanel.DisableNavigation();
		// bsg-jrebar (4/26/17): end
	}

	m_StartButton = Spawn(class'UILargeButton', LinkPanel);
	
	m_StartButton.InitLargeButton('difficultyLaunchButton', GetDifficultyButtonText(), "", UIIronMan);
	m_StartButton.DisableNavigation();

	RefreshDescInfo();
}

simulated function string GetDifficultyButtonText()
{
	local String strDifficultyAccept;

	strDifficultyAccept = (m_bIsPlayingGame) ? m_strChangeDifficulty : m_strDifficulty_Accept;
	
	if (`ISCONTROLLERACTIVE)
	{
		strDifficultyAccept = class'UIUtilities_Text'.static.InjectImage( class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -10) @ strDifficultyAccept; //bsg-jneal (2.2.17): fix for InjectImage calls not using platform prefix for button icons
	}

	return strDifficultyAccept;
}

simulated function UpdateDifficulty(UICheckbox CheckboxControl)
{
	local array<X2DownloadableContentInfo> DLCInfos; // variable for Issue #148
	local X2DownloadableContentInfo DLCInfo;

	if( m_DifficultyRookieMechaItem.Checkbox.bChecked && m_DifficultyRookieMechaItem.Checkbox == CheckboxControl )
	{
		m_iSelectedDifficulty = 0;
	}
	else if( m_DifficultyVeteranMechaItem.Checkbox.bChecked && m_DifficultyVeteranMechaItem.Checkbox == CheckboxControl )
	{
		m_iSelectedDifficulty = 1;
	}
	else if( m_DifficultyCommanderMechaItem.Checkbox.bChecked && m_DifficultyCommanderMechaItem.Checkbox == CheckboxControl )
	{
		m_iSelectedDifficulty = 2;
	}
	else if( m_DifficultyLegendMechaItem.Checkbox.bChecked && m_DifficultyLegendMechaItem.Checkbox == CheckboxControl )
	{
		m_iSelectedDifficulty = 3;
	}

	m_DifficultyRookieMechaItem.Checkbox.SetChecked(m_iSelectedDifficulty == 0);
	m_DifficultyVeteranMechaItem.Checkbox.SetChecked(m_iSelectedDifficulty == 1);
	m_DifficultyCommanderMechaItem.Checkbox.SetChecked(m_iSelectedDifficulty == 2);
	m_DifficultyLegendMechaItem.Checkbox.SetChecked(m_iSelectedDifficulty == 3);

	if( m_iSelectedDifficulty >= 3 )
	{
		ForceTutorialOff();
	}
	else
	{
		GrantTutorialReadAccess();
	}

	//start Issue #148
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.UpdateUIOnDifficultyChange(self);
	}
	//end Issue #148

	RefreshDescInfo();
}

simulated function OnButtonDifficultyRookie()
{
	if( !m_DifficultyRookieMechaItem.Checkbox.bChecked )
	{
		m_DifficultyRookieMechaItem.Checkbox.SetChecked(!m_DifficultyRookieMechaItem.Checkbox.bChecked);
	}
}

simulated function OnButtonDifficultyVeteran()
{
	if( !m_DifficultyVeteranMechaItem.Checkbox.bChecked )
	{
		m_DifficultyVeteranMechaItem.Checkbox.SetChecked(!m_DifficultyVeteranMechaItem.Checkbox.bChecked);
	}
}

simulated function OnButtonDifficultyCommander()
{
	if( !m_DifficultyCommanderMechaItem.Checkbox.bChecked )
	{
		m_DifficultyCommanderMechaItem.Checkbox.SetChecked(!m_DifficultyCommanderMechaItem.Checkbox.bChecked);
	}
}

simulated function OnButtonDifficultyLegend()
{
	if( !m_DifficultyLegendMechaItem.Checkbox.bChecked )
	{
		m_DifficultyLegendMechaItem.Checkbox.SetChecked(!m_DifficultyLegendMechaItem.Checkbox.bChecked);
	}
}

simulated function CloseSecondWave()
{
	if( m_bSecondWaveOpen)
	{
		m_bSecondWaveOpen = false;

		Navigator.Clear();

		m_TopPanel.EnableNavigation();
		m_BottomPanel.EnableNavigation();
		
		m_AdvancedOptions.Hide();
		AS_ToggleAdvancedOptions(false);
	}
}

simulated function OpenSecondWave()
{
	if( !m_bSecondWaveOpen )
	{
		m_bSecondWaveOpen = true;

		Navigator.Clear();
		m_AdvancedOptions.EnableNavigation();
		m_AdvancedOptions.Navigator.SelectFirstAvailable();
		//m_AdvancedOptions.Navigator.GetSelected().SelectFirstAvailable();
		
		m_AdvancedOptions.Show();
		AS_ToggleAdvancedOptions(true);
	}
}

simulated function OnClickedTutorial()
{
	if(m_iSelectedDifficulty < eDifficulty_Classic)
	{
		m_TutorialMechaItem.Checkbox.SetChecked(!m_TutorialMechaItem.Checkbox.bChecked);
	}
}

simulated function OnClickFirstTimeVO()
{
	m_FirstTimeVOMechaItem.Checkbox.SetChecked(!m_FirstTimeVOMechaItem.Checkbox.bChecked);
}

simulated function OnClickSubtitles()
{
	m_SubtitlesMechaItem.Checkbox.SetChecked(!m_SubtitlesMechaItem.Checkbox.bChecked);
}

simulated function OnClickSoundtrack()
{
	Movie.Pres.UISoundtrackPicker();
}

// Lower pause screen
simulated public function OnUCancel()
{
	if(bIsInited && !IsTimerActive(nameof(StartIntroMovie)))
	{
		if (m_bSecondWaveOpen)
		{
			CloseSecondWave();
		}
		else
		{
			NavHelp.ClearButtonHelp();
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
			`XPROFILESETTINGS.Data.ClearGameplayOptions();  // These are set on the player profile, so we should clear them for next time...
			Movie.Stack.Pop(self);
		}
	}
}

simulated public function OnButtonCancel(UIButton ButtonControl)
{
	if(bIsInited && !IsTimerActive(nameof(StartIntroMovie)))
	{
		if (m_bSecondWaveOpen)
		{
			CloseSecondWave();
		}
		else
		{
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
			`XPROFILESETTINGS.Data.ClearGameplayOptions();  // These are set on the player profile, so we should clear them for next time...
			Movie.Stack.Pop(self);
		}
	}
}

simulated public function OnButtonSecondWave()
{
	if( m_bSecondWaveOpen )
	{
		CloseSecondWave();
	}
	else
	{
		OpenSecondWave();
	}
}


simulated function OnSecondWaveOptionClicked(UIList ContainerList, int ItemIndex)
{
	local UICheckbox CheckedBox;
	CheckedBox = UIMechaListItem(m_SecondWaveList.GetItem(ItemIndex)).Checkbox;
	CheckedBox.SetChecked(!CheckedBox.bChecked);
	
    // These are the 3 faction HQ options.  Only one of them can be active at a time.
	switch(ItemIndex)
	{
		case 1:
			UIMechaListItem(m_SecondWaveList.GetItem(2)).Checkbox.SetChecked(false);
			UIMechaListItem(m_SecondWaveList.GetItem(3)).Checkbox.SetChecked(false);
			break;
		case 2:
			UIMechaListItem(m_SecondWaveList.GetItem(1)).Checkbox.SetChecked(false);
			UIMechaListItem(m_SecondWaveList.GetItem(3)).Checkbox.SetChecked(false);
			break;
		case 3:
			UIMechaListItem(m_SecondWaveList.GetItem(1)).Checkbox.SetChecked(false);
			UIMechaListItem(m_SecondWaveList.GetItem(2)).Checkbox.SetChecked(false);
			break;
	}
}

simulated function OnSecondWaveDescritionUpdate(UIList ContainerList, int ItemIndex)
{
	if (ItemIndex <= SecondWaveToolTips.Length && SecondWaveToolTips.Length != 0)
	{
		AS_SetAdvancedDescription(SecondWaveToolTips[ItemIndex]);
	}
}


simulated public function OnDifficultyConfirm(UIButton ButtonControl)
{
	local TDialogueBoxData kDialogData;
	local XComGameStateHistory History;
	local XComGameState StrategyStartState, NewGameState;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_Objective ObjectiveState;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local bool EnableTutorial;
	local int idx;
	local int DifficultyToSet;
	local array<name> SWOptions;
	local float TacticalPercent, StrategyPercent, GameLengthPercent; 

	//BAIL if the save is in progress. 
	if(m_bSaveInProgress && Movie.Pres.m_kProgressDialogStatus == eProgressDialog_None)
	{
		WaitingForSaveToCompletepProgressDialog();
		return;
	}

	History = `XCOMHISTORY;
	EventManager = `ONLINEEVENTMGR;

	//This popup should only be triggered when you are in the shell == not playing the game, and difficulty set to less than classic. 
	if(!m_bIsPlayingGame && !m_bShowedFirstTimeTutorialNotice && !m_TutorialMechaItem.Checkbox.bChecked && !m_bIronmanFromShell  && m_iSelectedDifficulty < eDifficulty_Classic)
	{
		if(DevStrategyShell == none || !DevStrategyShell.m_bCheatStart)
		{
			PlaySound(SoundCue'SoundUI.HUDOnCue');

			kDialogData.eType = eDialog_Normal;
			kDialogData.strTitle = m_strFirstTimeTutorialTitle;
			kDialogData.strText = m_strFirstTimeTutorialBody;
			kDialogData.strAccept = m_strFirstTimeTutorialYes;
			kDialogData.strCancel = m_strFirstTimeTutorialNo;
			kDialogData.fnCallback = ConfirmFirstTimeTutorialCheckCallback;

			Movie.Pres.UIRaiseDialog(kDialogData);
			return;
		}
	}

	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));

	// Warn if the difficulty level is changing, that this could invalidate the ability to earn certain achievements.
	if(CampaignSettingsStateObject != none && m_bIsPlayingGame && !m_bShowedFirstTimeChangeDifficultyWarning &&
	   (CampaignSettingsStateObject.LowestDifficultySetting >= 2 && m_iSelectedDifficulty < 2)) // is Classic or will become Classic or higher difficulty (where achievements based on difficulty kick-in)
	{
		PlaySound(SoundCue'SoundUI.HUDOnCue');

		kDialogData.eType = eDialog_Warning;
		kDialogData.strTitle = m_strChangeDifficultySettingTitle;
		kDialogData.strText = m_strChangeDifficultySettingBody;
		kDialogData.strAccept = m_strChangeDifficultySettingYes;
		kDialogData.strCancel = m_strChangeDifficultySettingNo;
		kDialogData.fnCallback = ConfirmChangeDifficultySettingCallback;

		Movie.Pres.UIRaiseDialog(kDialogData);
		return;
	}

	DifficultyToSet = m_iSelectedDifficulty;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	TacticalPercent = DifficultyConfigurations[m_iSelectedDifficulty].TacticalDifficulty;
	StrategyPercent = DifficultyConfigurations[m_iSelectedDifficulty].StrategyDifficulty;
	GameLengthPercent = DifficultyConfigurations[m_iSelectedDifficulty].GameLength;

	if(m_bIsPlayingGame)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Changing User-Selected Difficulty to " $ m_iSelectedDifficulty);
		
		CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		CampaignSettingsStateObject = XComGameState_CampaignSettings(NewGameState.ModifyStateObject(class'XComGameState_CampaignSettings', CampaignSettingsStateObject.ObjectID));
		CampaignSettingsStateObject.SetDifficulty(
			m_iSelectedDifficulty, 
			TacticalPercent, 
			StrategyPercent, 
			GameLengthPercent, m_bIsPlayingGame);
		AddSecondWaveOptionsToCampaignSettings(CampaignSettingsStateObject);

		`GAMERULES.SubmitGameState(NewGameState);
		
		// Perform any DLC-specific difficulty updates
		DLCInfos = EventManager.GetDLCInfos(false);
		for (idx = 0; idx < DLCInfos.Length; ++idx)
		{
			DLCInfos[idx].OnDifficultyChanged();
		}

		Movie.Stack.Pop(self);
	}
	else
	{
		EnableTutorial = m_iSelectedDifficulty < eDifficulty_Classic && m_bControlledStart;

		//If we are NOT going to do the tutorial, we setup our campaign starting state here. If the tutorial has been selected, we wait until it is done
		//to create the strategy start state.
		if(!EnableTutorial || (DevStrategyShell != none && DevStrategyShell.m_bSkipFirstTactical))
		{
			SWOptions = GetSelectedSecondWaveOptionNames( );

			//We're starting a new campaign, set it up
			StrategyStartState = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(, 
																											 , 
																											 EnableTutorial, 
																											 (EnableTutorial || `XPROFILESETTINGS.Data.m_bXPackNarrative),
																											 m_bIntegratedDLC,
																											 m_iSelectedDifficulty, 
																											 TacticalPercent,
																											 StrategyPercent, 
																											 GameLengthPercent, 
																											 (!EnableTutorial && !`XPROFILESETTINGS.Data.m_bXPackNarrative && m_bSuppressFirstTimeNarrative),
																											 EnabledOptionalNarrativeDLC, 
																											 , 
																											 m_bIronmanFromShell,
																											 , 
																											 , 
																											 SWOptions);

			// The CampaignSettings are initialized in CreateStrategyGameStart, so we can pull it from the history here
			CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

			//Since we just created the start state above, the settings object is still writable so just update it with the settings from the new campaign dialog
			CampaignSettingsStateObject.SetStartTime(StrategyStartState.TimeStamp);

			//See if we came from the dev strategy shell. If so, set the dev shell options...		
			if(DevStrategyShell != none)
			{
				CampaignSettingsStateObject.bCheatStart = DevStrategyShell.m_bCheatStart;
				CampaignSettingsStateObject.bSkipFirstTactical = DevStrategyShell.m_bSkipFirstTactical;
			}

			CampaignSettingsStateObject.SetDifficulty(m_iSelectedDifficulty, TacticalPercent, StrategyPercent, GameLengthPercent);
			CampaignSettingsStateObject.SetIronmanEnabled(m_bIronmanFromShell);

			// on Debug Strategy Start, disable the intro movies on the first objective
			if(CampaignSettingsStateObject.bCheatStart)
			{
				foreach StrategyStartState.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
				{
					if(ObjectiveState.GetMyTemplateName() == 'T1_M0_FirstMission')
					{
						ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_GameIntro");
						ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_WelcomeToHQ");
						ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_WelcomeToTheResistance");
					}
				}
			}
		}

		//Let the screen fade into the intro
		SetTimer(0.6f, false, nameof(StartIntroMovie));
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.5);

		if(EnableTutorial && !((DevStrategyShell != none && DevStrategyShell.m_bSkipFirstTactical)))
		{
			//Controlled Start / Demo Direct
			`XCOMHISTORY.ResetHistory();
			EventManager.bTutorial = true;
			EventManager.bInitiateReplayAfterLoad = true;

			// Save campaign settings			
			EventManager.CampaignDifficultySetting = DifficultyToSet;
			EventManager.CampaignLowestDifficultySetting = DifficultyToSet;
			EventManager.CampaignTacticalDifficulty = TacticalPercent;
			EventManager.CampaignStrategyDifficulty = StrategyPercent;
			EventManager.CampaignGameLength = GameLengthPercent;
			EventManager.CampaignbIronmanEnabled = m_bIronmanFromShell;
			EventManager.CampaignbTutorialEnabled = true;
			EventManager.CampaignbXPackNarrativeEnabled = true; // Force XPack Narrative on if the player starts with the Tutorial
			EventManager.CampaignbIntegratedDLCEnabled = m_bIntegratedDLC;
			EventManager.CampaignbSuppressFirstTimeNarrative = false; // Do not allow beginner VO to be turned off in the tutorial
			EventManager.CampaignOptionalNarrativeDLC = EnabledOptionalNarrativeDLC;
			AddSecondWaveOptionsToOnlineEventManager(EventManager);

			for(idx = EventManager.GetNumDLC() - 1; idx >= 0; idx--)
			{
				EventManager.CampaignRequiredDLC.AddItem(EventManager.GetDLCNames(idx));
			}


			SetTimer(1.0f, false, nameof(LoadTutorialSave));
		}
		else
		{
			SetTimer(1.0f, false, nameof(DeferredConsoleCommand));
		}
	}
}

function array<name> GetSelectedSecondWaveOptionNames( )
{
	local int OptionIndex;
	local UICheckbox CheckedBox;
	local array<name> Options;

	for( OptionIndex = 0; OptionIndex < SecondWaveOptions.Length; ++OptionIndex )
	{
		CheckedBox = UIMechaListItem(m_SecondWaveList.GetItem(OptionIndex)).Checkbox;
		if( CheckedBox.bChecked )
		{
			Options.AddItem( SecondWaveOptions[OptionIndex].ID );
		}
	}

	return Options;
}

function AddSecondWaveOptionsToCampaignSettings(XComGameState_CampaignSettings CampaignSettingsStateObject)
{
	local int OptionIndex;
	local UICheckbox CheckedBox;

	for( OptionIndex = 0; OptionIndex < SecondWaveOptions.Length; ++OptionIndex )
	{
		CheckedBox = UIMechaListItem(m_SecondWaveList.GetItem(OptionIndex)).Checkbox;
		if( CheckedBox.bChecked )
		{
			CampaignSettingsStateObject.AddSecondWaveOption(SecondWaveOptions[OptionIndex].ID);
		}
		else
		{
			CampaignSettingsStateObject.RemoveSecondWaveOption(SecondWaveOptions[OptionIndex].ID);
		}
	}
}

function AddSecondWaveOptionsToOnlineEventManager(XComOnlineEventMgr EventManager)
{
	local int OptionIndex;
	local UICheckbox CheckedBox;
	local int RemoveIndex;

	for( OptionIndex = 0; OptionIndex < SecondWaveOptions.Length; ++OptionIndex )
	{
		CheckedBox = UIMechaListItem(m_SecondWaveList.GetItem(OptionIndex)).Checkbox;
		if( CheckedBox.bChecked )
		{
			EventManager.CampaignSecondWaveOptions.AddItem(SecondWaveOptions[OptionIndex].ID);
		}
		else
		{
			RemoveIndex = EventManager.CampaignSecondWaveOptions.Find(SecondWaveOptions[OptionIndex].ID);
			if( RemoveIndex != INDEX_NONE )
			{
				EventManager.CampaignSecondWaveOptions.Remove(RemoveIndex, 1);
			}
		}
	}
}

function StartIntroMovie()
{
	local XComEngine Engine;
	// Variable Issue #543
	local UIShellStrategy Shell;
	
	Engine = `XENGINE;

	// Start Issue #543
	Shell = UIShellStrategy(Movie.Pres.ScreenStack.GetScreen(class'UIShellStrategy'));
	if (!Shell.m_bSkipFirstTactical && !Shell.m_bCheatStart && !class'CHHelpers'.default.bSkipCampaignIntroMovies)
	{
	
		// Play the pre-intro bink for the XPack
		Engine.PlayMovie(false, "CIN_XP_PreIntro.bk2", "X2_XP_01_PreIntro");
		Engine.WaitForMovie();
		Engine.StopCurrentMovie();

		// Then play the normal intro and load the game
		Engine.PlaySpecificLoadingMovie("CIN_TP_Intro.bk2", "X2_001_Intro"); //Play the intro movie as a loading screen
		Engine.PlayLoadMapMovie(-1);
	}
	// End Issue #543
}

function DeferredConsoleCommand()
{
	ConsoleCommand("open Avenger_Root?game=XComGame.XComHeadQuartersGame");
}

function LoadTutorialSave()
{
	`ONLINEEVENTMGR.LoadSaveFromFile(class'UIShell'.default.strTutorialSave);
}

simulated function WaitingForSaveToCompletepProgressDialog()
{
	local TProgressDialogData kDialog;

	kDialog.strTitle = m_strWaitingForSaveTitle;
	kDialog.strDescription = m_strWaitingForSaveBody;
	Movie.Pres.UIProgressDialog(kDialog);
}

simulated function CloseSaveProgressDialog()
{
	Movie.Pres.UICloseProgressDialog();
	OnDifficultyConfirm(m_StartButton);
}


//------------------------------------------------------
function UIIronMan(UIButton ButtonControl)
{
	if( m_bIsPlayingGame )
	{
		OnDifficultyConfirm(ButtonControl);
	}
	else 
	{
		if( m_bControlledStart ) // Ironman and tutorial do not mix
		{
			Movie.Pres.UIShellNarrativeContent();
		}
		else
		{
			Movie.Pres.UIIronMan();
		}
	}
}


function ConfirmIronmanDialogue(UIButton ButtonControl)
{
	local TDialogueBoxData kDialogData;

	PlaySound(SoundCue'SoundUI.HUDOnCue');

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strIronmanTitle;
	kDialogData.strText = m_strIronmanBody;
	kDialogData.strAccept = m_strIronmanOK;
	kDialogData.strCancel = m_strIronmanCancel;
	kDialogData.fnCallback = ConfirmIronmanCallback;

	Movie.Pres.UIRaiseDialog(kDialogData);
	Show();
}

simulated public function ConfirmIronmanCallback(Name eAction)
{
	if(eAction == 'eUIAction_Accept')
	{
		PlaySound(SoundCue'SoundUI.OverWatchCue');

	}
	else if(eAction == 'eUIAction_Cancel')
	{
		PlaySound(SoundCue'SoundUI.HUDOffCue');
	}

	UpdateIronman(eAction == 'eUIAction_Accept');
	OnDifficultyConfirm(m_StartButton);
}

//------------------------------------------------------
function ConfirmControlDialogue(UICheckbox CheckboxControl)
{
	local TDialogueBoxData kDialogData;

	// Can't enable any of the tutorial options with classic difficulty selected
	if(m_iSelectedDifficulty >= eDifficulty_Classic)
	{
		ForceTutorialOff();
		ShowSimpleDialog(m_strInvalidTutorialClassicDifficulty);
		return;
	}
	else
	{
		GrantTutorialReadAccess();
	}

	//Only trigger the message when turning this off.
	if(!CheckboxControl.bChecked)
	{
		PlaySound(SoundCue'SoundUI.HUDOnCue');

		kDialogData.eType = eDialog_Normal;
		kDialogData.strTitle = m_strControlTitle;
		kDialogData.strText = m_strControlBody;
		kDialogData.strAccept = m_strControlOK;
		kDialogData.strCancel = m_strControlCancel;
		kDialogData.fnCallback = ConfirmControlCallback;

		Movie.Pres.UIRaiseDialog(kDialogData);
	}
	else
	{
		UpdateTutorial(CheckboxControl);
	}
}

simulated public function ConfirmControlCallback(Name eAction)
{
	local UICheckbox kCheckbox;
	local array<string> mouseOutArgs;

	PlaySound(SoundCue'SoundUI.HUDOffCue');
	kCheckBox = m_TutorialMechaItem.Checkbox;

	mouseOutArgs.AddItem("");

	kCheckbox.OnMouseEvent(class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT, mouseOutArgs);
	//Only trigger the message when turning this off.
	if(!kCheckBox.bChecked)
	{
		if(eAction == 'eUIAction_Cancel')
		{
			kCheckbox.SetChecked(true);
			`XPROFILESETTINGS.Data.SetGameplayOption(eGO_Marathon, false);    // Marathon and tutorial don't play nice
			Movie.Pres.m_kGameToggles.UpdateData();
		}

		UpdateTutorial(kCheckBox);
	}
	else
	{
		UpdateTutorial(kCheckBox);
	}
}

simulated public function ConfirmFirstTimeTutorialCheckCallback(Name eAction)
{
	PlaySound(SoundCue'SoundUI.HUDOffCue');

	if(eAction == 'eUIAction_Accept')
	{
		if(!m_TutorialMechaItem.Checkbox.bChecked)
			OnClickedTutorial();

		m_bControlledStart = true;
		`XPROFILESETTINGS.Data.SetGameplayOption(eGO_Marathon, false);    // Marathon and tutorial don't play nice
		if(Movie.Pres.m_kGameToggles != none)
			Movie.Pres.m_kGameToggles.UpdateData();
	}
	else
	{
		m_bControlledStart = false;
	}
	// Don't need to set Checkbox to false, this popup won't show up if it's set to true - sbatista 6/26/13

	m_bShowedFirstTimeTutorialNotice = true;
	OnDifficultyConfirm(m_StartButton);
}

simulated public function ConfirmChangeDifficultySettingCallback(Name eAction)
{
	PlaySound(SoundCue'SoundUI.HUDOffCue');

	if(eAction == 'eUIAction_Accept')
	{
		m_bShowedFirstTimeChangeDifficultyWarning = true;
		OnDifficultyConfirm(m_StartButton);
	}
}

// UPDATE CHECKBOX FUNCTIONS

simulated function ForceTutorialOff()
{
	m_bControlledStart = false;

	//Refresh check this way, to not trigger the popups
	m_TutorialMechaItem.Checkbox.SetChecked(false);

	if(!m_bIsPlayingGame)
	{
		m_TutorialMechaItem.Checkbox.SetReadOnly(true);
	}
}

simulated function GrantTutorialReadAccess()
{
	if(!m_bIsPlayingGame)
	{
		m_TutorialMechaItem.Checkbox.SetReadOnly(false);
	}
}

simulated function UpdateTutorial(UICheckbox CheckboxControl)
{
	// Can't enable any of the tutorial options with classic difficulty selected
	if(m_iSelectedDifficulty >= eDifficulty_Classic)
	{
		if(CheckboxControl.bChecked && !m_bIsPlayingGame)
			ShowSimpleDialog(m_strInvalidTutorialClassicDifficulty);

		ForceTutorialOff();
		return;
	}
	else
	{
		GrantTutorialReadAccess();
	}

	m_bControlledStart = CheckboxControl.bChecked;
	if(m_bControlledStart)
	{
		`XPROFILESETTINGS.Data.SetGameplayOption(eGO_Marathon, false);    // Marathon and tutorial don't play nice
	}
	else
	{
		if(`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting == false)
		{
			`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting = true; //Only allow this to be activate for this profile, never toggled back. 
			SaveSettings();
		}
	}
}

simulated function UpdateIronman(bool bIronMan)
{
	m_bIronmanFromShell = bIronMan;
}

simulated function UpdateFirstTimeNarrative(UICheckbox CheckboxControl)
{
	m_bSuppressFirstTimeNarrative = CheckboxControl.bChecked; //bool(m_hAdvancedWidgetHelper.GetCurrentValue(m_iOptFirstTimeNarrative));
}

simulated function UpdateSubtitles(UICheckbox CheckboxControl)
{
	`XPROFILESETTINGS.Data.m_bSubtitles = CheckboxControl.bChecked;
	`XPROFILESETTINGS.ApplyUIOptions();
	Movie.Pres.GetUIComm().RefreshSubtitleVisibility();
}

// bsg-jrebar (5/9/17): On clicked function for use by controller on advanced options
simulated function OnAdvancedOptionsClicked()
{
	local UIPanel CurrentSelection;
	local UIMechaListItem item;
	CurrentSelection = m_SecondWaveList.Navigator.GetSelected();

	item = UIMechaListItem(CurrentSelection);

	if(item != none)
	{
		item.Checkbox.SetChecked(!item.Checkbox.bChecked);
	}
}
//bsg-jrebar (5/9/17): end

simulated function OnSelectedIndexChanged(int NewIndex)
{
	RefreshDescInfo();
}

simulated function RefreshDescInfo()
{
	local string sDesc;
	
	
	
	if( !`ISCONTROLLERACTIVE )
	{
		sDesc = m_arrDifficultyDescStrings[m_iSelectedDifficulty];

		if(m_iSelectedDifficulty >= eDifficulty_Classic)
		{
			if(m_bIsPlayingGame && Movie.Pres.ISCONTROLLED())
				sDesc = sDesc @ class'UIUtilities_Text'.static.GetColoredText(m_strTutorialNoChangeToImpossible, eUIState_Warning);
			else if(Movie.Pres.m_eUIMode == eUIMode_Shell && m_iSelectedDifficulty == eDifficulty_Classic)
				sDesc = sDesc @ class'UIUtilities_Text'.static.GetColoredText(m_strTutorialOnImpossible, eUIState_Warning);
		}
	}
	else
	{
		if(Navigator.GetSelected() == m_TopPanel)
		{
			sDesc = m_arrDifficultyDescStrings[m_TopPanel.Navigator.SelectedIndex];
			
			if(m_TopPanel.Navigator.SelectedIndex == 3)
			{
				if(m_bIsPlayingGame && Movie.Pres.ISCONTROLLED())
				sDesc = sDesc @ class'UIUtilities_Text'.static.GetColoredText(m_strTutorialNoChangeToImpossible, eUIState_Warning);
					else if(Movie.Pres.m_eUIMode == eUIMode_Shell && m_iSelectedDifficulty == eDifficulty_Classic)
				sDesc = sDesc @ class'UIUtilities_Text'.static.GetColoredText(m_strTutorialOnImpossible, eUIState_Warning);
			}
		}
		else
		{
			switch(m_BottomPanel.Navigator.SelectedIndex)
			{
				case 0:
					sDesc = m_strSecondWaveDesc;
					break;
				case 1:
					sDesc = m_strDifficultyTutorialDesc;
					break;
				case 2:
					sDesc = m_strDifficultySuppressFirstTimeNarrativeVODesc;
					break;
				case 3:
					sDesc = class'UIOptionsPCScreen'.default.m_strInterfaceLabel_ShowSubtitles_Desc;
					break;
			}
			
		}
	}
	
	AS_SetDifficultyDesc(sDesc);
}

simulated function CloseScreen()
{
	super.CloseScreen();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnUCancel);
	UpdateNavHelp(); //bsg-crobinson (5.3.17): Update navhelp when receiving focus
	Show();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	NavHelp.ClearButtonHelp(); //bsg-hlee (05.02.17): Removing extra bottom left b button.
	Hide();
}

simulated public function SaveSettings()
{
	m_bSaveInProgress = true;
	`ONLINEEVENTMGR.AddSaveProfileSettingsCompleteDelegate(SaveComplete);
	`ONLINEEVENTMGR.SaveProfileSettings(true);
}
simulated public function SaveComplete(bool bWasSuccessful)
{
	if(!bWasSuccessful)
	{
		SaveProfileFailedDialog();
	}

	`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate(SaveComplete);
	m_bSaveInProgress = false;

	if(Movie.Pres.m_kProgressDialogStatus != eProgressDialog_None)
	{
		CloseSaveProgressDialog();
	}
}

simulated public function SaveProfileFailedDialog()
{
	local TDialogueBoxData kDialogData;

	kDialogData.strText = (WorldInfo.IsConsoleBuild(CONSOLE_Xbox360)) ? class'UIOptionsPCScreen'.default.m_strSavingOptionsFailed360 : class'UIOptionsPCScreen'.default.m_strSavingOptionsFailed;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	XComPresentationLayerBase(Owner).UIRaiseDialog(kDialogData);
}

simulated function ShowSimpleDialog(string txt)
{
	local TDialogueBoxData kDialogData;

	kDialogData.strText = txt;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	XComPresentationLayerBase(Owner).UIRaiseDialog(kDialogData);
}

// FLASH COMMUNICATION
simulated function AS_SetDifficultyDesc(string desc)
{
	MC.FunctionString("SetDifficultyDesc", desc);
}
simulated function AS_ToggleAdvancedOptions( bool bOpen )
{
	MC.FunctionBool("ToggleAdvancedOptions", bOpen);
}

simulated function AS_SetDifficultyMenu(
	string title, 
	string Rookie,
	string Veteran,
	string Commander,
	string Legend,
	string AdvancedOptions,
	string tutorialLabel, 
	string ReduceVO, 
	string Subtitles,
	string launchLabel)
{
	MC.BeginFunctionOp("UpdateDifficultyMenu");
	MC.QueueString(title);
	MC.QueueString(Rookie);
	MC.QueueString(Veteran);
	MC.QueueString(Commander);
	MC.QueueString(Legend);
	MC.QueueString(AdvancedOptions);
	MC.QueueString(tutorialLabel);
	MC.QueueString(ReduceVO);
	MC.QueueString(Subtitles);
	MC.QueueString(launchLabel);
	MC.EndOp();
}

simulated function AS_SetSecondWaveScore(string SecondWaveHeader, string ValueString)
{
	MC.BeginFunctionOp("SetAdvancedScore");
	MC.QueueString(SecondWaveHeader);
	MC.QueueString(ValueString);
	MC.EndOp();
}

simulated function AS_SetOverallDifficultyScore(string SecondWaveHeader, string ValueString)
{
	MC.BeginFunctionOp("SetDifficultyScore");
	MC.QueueString(SecondWaveHeader);
	MC.QueueString(ValueString);
	MC.EndOp();
}

simulated function AS_SetAdvancedDescription(string AdvancedDescription)
{
	m_AdvancedOptions.MC.BeginFunctionOp("SetDescription");
	m_AdvancedOptions.MC.QueueString(AdvancedDescription);
	m_AdvancedOptions.MC.EndOp();
}


//==============================================================================
//		CLEANUP:
//==============================================================================

event Destroyed()
{
	super.Destroyed();
}

DefaultProperties
{
	Package = "/ package/gfxDifficultyMenu/DifficultyMenu";
	LibID = "DifficultyMenu_Options"

		InputState = eInputState_Consume;
	m_bSaveInProgress = false;
	bConsumeMouseEvents = true

}
