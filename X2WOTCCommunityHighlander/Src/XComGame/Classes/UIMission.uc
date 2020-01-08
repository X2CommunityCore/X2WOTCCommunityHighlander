
class UIMission extends UIX2SimpleScreen;

var StateObjectReference MissionRef;

var public localized String m_strUFOTitle;
var public localized String m_strInterceptionChance;
var public localized String m_strShadowChamberTitle;
var public localized String m_strEnemiesDetected;
var public localized String m_strMissionDifficulty;
var public localized String m_strMissionObjective;
var public localized String m_strMissionLabel;
var public localized String m_strFlavorText;
var public localized String m_strEasy;
var public localized String m_strModerate;
var public localized String m_strDifficult;
var public localized String m_strVeryDifficult;
var public localized String m_strControl;
var public localized String m_strLocked;
var public localized String m_strAvengerFlightDistance;
var public localized String m_strMiles;
var public localized String m_strLaunchMission;
var public localized String m_strSitrepTitle;
var public localized String m_strConfirmLabel;
var public localized String m_strChosenWarning;
var public localized String m_strChosenWarning2;
var public localized String m_strSitRepInfoButton;

var public bool				bInstantInterp;

var UIPanel LibraryPanel;
var UIAlertShadowChamberPanel ShadowChamber;
var UIAlertSitRepPanel SitrepPanel;
var UIPanel ChosenPanel;
var UIButton Button1, Button2, Button3, ConfirmButton;
var UIPanel ButtonGroup;

var UIPanel LockedPanel;
var UIButton LockedButton;

const LABEL_ALPHA = 0.75f;
const CAMERA_ZOOM = 0.5f;

delegate ActionCallback(Name eAction);
delegate OnClickedDelegate(UIButton Button);

// img:///UILibrary_ProtoImages.Proto_AdventControl
// img:///UILibrary_ProtoImages.Proto_AdventFacility
// img:///UILibrary_ProtoImages.Proto_AlienBase
// img:///UILibrary_ProtoImages.Proto_AlienFacility
// img:///UILibrary_ProtoImages.Proto_BuildOutpost
// img:///UILibrary_ProtoImages.Proto_Council
// img:///UILibrary_ProtoImages.Proto_DoomIcons
// img:///UILibrary_ProtoImages.Proto_GuerrillaOps
// img:///UILibrary_ProtoImages.Proto_MakeContact
// img:///UILibrary_ProtoImages.Proto_ObjectiveComplete
// img:///UILibrary_ProtoImages.Proto_Terror

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	//TODO: bsteiner: remove this when the strategy map handles it's own visibility
	if( Package != class'UIScreen'.default.Package )
		`HQPRES.StrategyMap2D.Hide();
}

simulated function FindMission(name MissionSource)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	if (MissionRef.ObjectID == 0)
	{
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if (MissionState.Source == MissionSource && MissionState.Available)
			{
				MissionRef = MissionState.GetReference();
				break;
			}
		}
	}
}

//overwritable for the children to initialize which mission is shown
simulated function SelectMission(XComGameState_MissionSite missionToSelect)
{
}


simulated function BindLibraryItem()
{
	local Name AlertLibID;

	AlertLibID = GetLibraryID();
	if( AlertLibID != '' )
	{
		LibraryPanel = Spawn(class'UIPanel', self);
		LibraryPanel.bAnimateOnInit = false;
		LibraryPanel.InitPanel('LibraryPanel', AlertLibID);

		ButtonGroup = Spawn(class'UIPanel', LibraryPanel);
		ButtonGroup.InitPanel('ButtonGroup', '');

		Button1 = Spawn(class'UIButton', ButtonGroup);
		Button2 = Spawn(class'UIButton', ButtonGroup);

		Button3 = Spawn(class'UIButton', ButtonGroup);
		Button3.SetResizeToText( false );
		Button3.InitButton('Button2', "",, eUIButtonStyle_NONE);
		Button3.OnSizeRealized = OnButtonSizeRealized;

		ConfirmButton = Spawn(class'UIButton', LibraryPanel);

		if( `ISCONTROLLERACTIVE == false )
		{
			ConfirmButton.InitButton('ConfirmButton', "", OnLaunchClicked);
			Button1.InitButton('Button0', "",, eUIButtonStyle_NONE);
			Button2.InitButton('Button1', "",, eUIButtonStyle_NONE);
			ConfirmButton.SetResizeToText(false);
			Button1.SetResizeToText( false );
			Button2.SetResizeToText(false);
			Button1.OnSizeRealized = OnButtonSizeRealized;
			Button2.OnSizeRealized = OnButtonSizeRealized;
		}
		else
		{	
			//bsg-jneal (5.11.17): fix buttons styles on UIMissions
			Button1.InitButton('Button0', "", OnLaunchClicked, eUIButtonStyle_NONE);
			Button1.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
			Button1.OnSizeRealized = OnButtonSizeRealized;
			Button1.SetResizeToText(false);
			
			Button2.InitButton('Button1', "", OnCancelClicked, eUIButtonStyle_NONE);
			Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetBackButtonIcon());
			Button2.OnSizeRealized = OnButtonSizeRealized;
			Button2.SetResizeToText(false);
			//bsg-jneal (5.11.17): end

			ConfirmButton.InitButton('ConfirmButton', "", OnLaunchClicked, eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
			ConfirmButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
			ConfirmButton.OnSizeRealized = OnButtonSizeRealized;
			ConfirmButton.SetX(1450.0);
			ConfirmButton.SetY(617.0);
			ConfirmButton.SetWidth(300);
		}

		ConfirmButton.DisableNavigation();

		ShadowChamber = Spawn(class'UIAlertShadowChamberPanel', LibraryPanel);
		ShadowChamber.InitPanel('UIAlertShadowChamberPanel', 'Alert_ShadowChamber');

		SitrepPanel = Spawn(class'UIAlertSitRepPanel', LibraryPanel);
		SitrepPanel.InitPanel('SitRep', 'Alert_SitRep');
		SitrepPanel.SetTitle(m_strSitrepTitle);

		ChosenPanel = Spawn(class'UIPanel', LibraryPanel).InitPanel(, 'Alert_ChosenRegionInfo');
		ChosenPanel.DisableNavigation();
	}
}
simulated function OnButtonSizeRealized()
{
	ConfirmButton.SetX(1450.0 - ConfirmButton.Width / 2.0);
}

//Override this in child classes. 
simulated function Name GetLibraryID()
{
	return '';
}

simulated function BuildScreen()
{
	BindLibraryItem();

	// Always cleanup HQs Tactical Tags
	class'XComGameState_HeadquartersXCom'.static.SortAndCleanUpTacticalTags();

	UpdateData();
	BuildMissionPanel();
	BuildOptionsPanel();

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
	RefreshNavHelp();
}

simulated function RefreshNavigation()
{
	if( ConfirmButton.bIsVisible )
	{
		ConfirmButton.EnableNavigation();
	}
	else
	{
		ConfirmButton.DisableNavigation();
	}

	if( Button1.bIsVisible )
	{
		Button1.EnableNavigation();
	}
	else
	{
		Button1.DisableNavigation();
		Button1.Hide();
		Button1.Remove();
	}

	if( Button2.bIsVisible )
	{
		Button2.EnableNavigation();
	}
	else
	{
		Button2.DisableNavigation();
		Button2.Hide();
		Button2.Remove();
	}

	if( Button3.bIsVisible )
	{
		Button3.EnableNavigation();
	}
	else
	{
		Button3.DisableNavigation();
		Button3.Hide();
		Button3.Remove();
	}

	if( LockedPanel != none && LockedPanel.bIsVisible )
	{
		ConfirmButton.DisableNavigation();
		Button1.DisableNavigation();
		Button2.DisableNavigation();
		Button3.DisableNavigation();
		Button1.Hide();
		Button2.Hide();
		Button3.Hide();
		Button1.Remove();
		Button2.Remove();
		Button3.Remove();
	}

	LibraryPanel.bCascadeFocus = false;
	LibraryPanel.SetSelectedNavigation();
	ButtonGroup.bCascadeFocus = false;
	ButtonGroup.SetSelectedNavigation();
	ConfirmButton.DisableNavigation();

	if( `ISCONTROLLERACTIVE == false )
	{
		if( Button1.bIsNavigable )
			Button1.SetSelectedNavigation();
		else if( Button2.bIsNavigable )
			Button2.SetSelectedNavigation();
		else if( Button3.bIsNavigable )
			Button3.SetSelectedNavigation();
		else if( LockedPanel != none && LockedPanel.IsVisible() )
			LockedButton.SetSelectedNavigation();
		else if( ConfirmButton.bIsNavigable )
			ConfirmButton.SetSelectedNavigation();
	}
	
	if( ShadowChamber != none )
		ShadowChamber.DisableNavigation();
		
	ButtonGroup.DisableNavigation();
	Navigator.Clear();
	if (Button1.bIsVisible)
	{
		Navigator.AddControl(Button1);
	}

	if (Button2.bIsVisible)
	{
		Navigator.AddControl(Button2);
	}

	if (Button3.bIsVisible)
	{
		Navigator.AddControl(Button3);
	}

	Navigator.LoopSelection = true;

	if(ChosenPanel != none)
		ChosenPanel.DisableNavigation();
}

function RefreshNavHelp()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function BuildOptionsPanel(); //Overwritten in child classes if applicable. 
simulated function BuildMissionPanel(); //Overwritten in child classes if applicable. 

simulated function BuildConfirmPanel(optional TRect rPanel, optional EUIState eColor)
{
	local TRect rPos;

	if( LibraryPanel == none )
	{
		AddBG(rPanel, eColor);

		// Launch Mission Button
		rPos = VSubRect(rPanel, 0.4f, 0.5f);
		AddButton(rPos, m_strLaunchMission, OnLaunchClicked);

		rPos.fTop += 35;
		rPos.fBottom += 35;
		AddButton(rPos, m_strIgnore, OnCancelClicked);
	}
}

simulated function BuildMissionRegion(TRect rPanel)
{
	local XComGameState_WorldRegion Region;
	local TRect rRegion, rPos;/*, rLabel, rControl;*/

	rRegion = MakeRect(rPanel.fLeft, rPanel.fTop, 400, 220);

	Region = GetRegion();

	// Region Name
	rPos = VSubRectPixels(rRegion, 0.0f, 55);
	AddTitle(rPos, Region.GetMyTemplate().DisplayName, GetLabelColor(), 50, 'Region');
}

//-------------- EVENT HANDLING --------------------------------------------------------

simulated public function OnLaunchClicked(UIButton button)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	HQPRES().CAMLookAtEarth( XComHQ.Get2DLocation() );

	CloseScreen();
	
	// Clear any popups that might be hiding underneath the mission blades
	Movie.Stack.PopUntilClass(class'UIStrategyMap');

	if(GetMission().Region == XComHQ.Region || GetMission().Region.ObjectID == 0)
	{
		GetMission().ConfirmSelection();
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Store cross continent mission reference");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.CrossContinentMission = MissionRef;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		GetMission().GetWorldRegion().AttemptSelection();
	}
}
simulated function OnCancelClickedNavHelp()
{
	if(CanBackOut())
	{
		OnCancelClicked(none);
	}
}
simulated public function OnCancelClicked(UIButton button)
{
	if(CanBackOut())
	{
		if(GetMission().GetMissionSource().DataName != 'MissionSource_Final' || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T5_M3_CompleteFinalMission') != eObjectiveState_InProgress)
		{
			//Restore the saved camera location
			XComHQPresentationLayer(Movie.Pres).CAMRestoreSavedLocation();
		}

		CloseScreen();
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if( LibraryPanel != none )
	{
		BuildConfirmPanel();
	}
	RefreshNavHelp();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	if( LibraryPanel != none )
	{
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	}
}



// Called when screen is removed from Stack
simulated function OnRemoved()
{
	super.OnRemoved();

	//Restore the saved camera location
	if(GetMission().GetMissionSource().DataName != 'MissionSource_Final' || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T5_M3_CompleteFinalMission') != eObjectiveState_InProgress)
	{
		HQPRES().CAMRestoreSavedLocation();
		`HQPRES.StrategyMap2D.ShowCursor();
	}

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	class'UIUtilities_Sound'.static.PlayCloseSound();
}

simulated function CloseScreen()
{
	RemoveMissionTacticalTags();
	super.CloseScreen();
}

simulated function UpdateData()
{
	// Region Panel
	if( LibraryPanel == none )
	{
		UpdateTitle('Region', GetRegion().GetMyTemplate().DisplayName, GetLabelColor(), 50);
	}
	
	UpdateMissionTacticalTags();
	AddMissionTacticalTags();
	UpdateMissionSchedules();
	UpdateShadowChamber();
	UpdateSitreps();
	UpdateChosen();
}

// Catch cases where Chosen should be guaranteed, but the mission tags are not set correctly
simulated function UpdateMissionTacticalTags()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionSite MissionState;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UIMission: UpdateMissionTacticalTags");
	MissionState = GetMission();
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ.AddChosenTacticalTagsToMission(MissionState, true);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// Add Mission tags to HQ
simulated function AddMissionTacticalTags()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UIMission: AddMissionTacticalTags");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.AddMissionTacticalTags(GetMission());
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function RemoveMissionTacticalTags()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UIMission: Update Chosen Spawning Tags");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.RemoveMissionTacticalTags(GetMission());
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function UpdateMissionSchedules()
{
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local bool bSpawnUpdateFromDLC;
	local int i;

	if (ShouldUpdateMissionSpawningInfo())
	{
		// Check for update to spawning from DLC
		EventManager = `ONLINEEVENTMGR;
		DLCInfos = EventManager.GetDLCInfos(false);
		bSpawnUpdateFromDLC = false;
		for (i = 0; i < DLCInfos.Length; ++i)
		{
			if (DLCInfos[i].UpdateMissionSpawningInfo(MissionRef))
			{
				bSpawnUpdateFromDLC = true;
			}
		}

		// If we have a spawning update, clear out the missions selected spawn data so that it regenerates
		if (bSpawnUpdateFromDLC)
		{
			MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionRef.ObjectID));

			if (MissionState.SelectedMissionData.SelectedMissionScheduleName != '')
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Cached Mission Data");
				MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
				MissionState.SelectedMissionData.SelectedMissionScheduleName = '';
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Cached Mission Data");
		MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionRef.ObjectID));
		if (MissionState.UpdateSelectedMissionData()) // This function also updates the Shadow Chamber strings
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			NewGameState.PurgeGameStateForObjectID(MissionState.ObjectID);
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}		
	}
}

simulated function bool ShouldUpdateMissionSpawningInfo()
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	// Check to see if any DLC requires schedule updates
	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		if (DLCInfos[i].ShouldUpdateMissionSpawningInfo(MissionRef))
		{
			return true;
		}
	}

	// Otherwise only update if the shadow chamber is built
	return IsShadowChamberConstructed();
}

simulated function UpdateShadowChamber()
{
	local XComGameState NewGameState;

	if( IsShadowChamberConstructed() )
	{
		if (CanTakeMission()) // Only trigger Shen's voice line when the mission is unlocked
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On Shadow Chamber UI Display");
			`XEVENTMGR.TriggerEvent('OnShadowChamberMissionUI', , , NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}

		ShadowChamber.MC.BeginFunctionOp("UpdateShadowChamber");
		ShadowChamber.MC.QueueString(m_strShadowChamberTitle);
		ShadowChamber.MC.QueueString(m_strEnemiesDetected);
		ShadowChamber.MC.QueueString(GetCrewString());
		ShadowChamber.MC.QueueString(GetCrewCount());
		ShadowChamber.MC.EndOp();
	}
	else
	{
		ShadowChamber.Hide();
	}
}

simulated function UpdateSitreps()
{
	local X2SitRepTemplateManager SitRepManager;
	local X2SitRepTemplate SitRepTemplate;
	local XComGameState_MissionSite MissionState;
	local GeneratedMissionData MissionData;
	local name SitRepName;
	local EUIState eState;
	
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionRef.ObjectID));
	MissionData = XCOMHQ().GetGeneratedMissionData(MissionRef.ObjectID);

	// Sitrep Panel
	if (MissionData.SitReps.Length > 0 && !MissionState.GetMissionSource().bBlockSitrepDisplay)
	{
		`assert( SitrepPanel != none ); //derived type didn't build one?

		`HQPRES.UISitrepIntro(); // Queue the SITREP tutorial popup

		// Reset the sitreps displayed in the panel
		SitrepPanel.MC.FunctionVoid("SitRepALertCLear");

		SitRepManager = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();
		foreach MissionData.SitReps(SitRepName)
		{
			SitRepTemplate = SitRepManager.FindSitRepTemplate(SitRepName);
			if (SitRepTemplate != none)
			{
				if(SitRepTemplate.bNegativeEffect)
				{
					eState = eUIState_Bad;
				}
				else
				{
					eState = eUIState_Normal;
				}

				SitrepPanel.MC.BeginFunctionOp("SitRepAlertAddItem");
				SitrepPanel.MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(SitRepTemplate.GetFriendlyName(), eState));
				SitrepPanel.MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(SitRepTemplate.GetDescriptionExpanded(), eState)); // Issue #566
				SitrepPanel.MC.EndOp();
			}
		}	

		SitrepPanel.Show(); // Re-show the panel in case it was hidden by another mission
	}
	else 
	{
		if (SitrepPanel != none)
		{
			SitrepPanel.Hide();
		}
	}
}

simulated function UpdateChosen()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_AdventChosen ChosenState;
	local StackedUIIconData IconInfo;
	local int idx;

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	RegionState = GetRegion();
	
	if(RegionState != none)
	{
		ChosenState = RegionState.GetControllingChosen();
	}

	if(AlienHQ.bChosenActive && ChosenState != none && ChosenState.bMetXCom && !ChosenState.bDefeated)
	{
		`assert(ChosenPanel != none);

		ChosenPanel.MC.BeginFunctionOp("SetChosenName");
		ChosenPanel.MC.QueueString(ChosenState.GetChosenClassName());
		ChosenPanel.MC.QueueString(ChosenState.GetChosenName());
		ChosenPanel.MC.QueueString(ChosenState.GetChosenNickname());
		ChosenPanel.MC.QueueString(m_strChosenWarning2);
		ChosenPanel.MC.QueueString(m_strChosenWarning);
		ChosenPanel.MC.EndOp();
		
		IconInfo = ChosenState.GetChosenIcon();

		ChosenPanel.MC.BeginFunctionOp("UpdateChosenIcon");
		ChosenPanel.MC.QueueBoolean(IconInfo.bInvert);
		for (idx = 0; idx < IconInfo.Images.Length; idx++)
		{
			ChosenPanel.MC.QueueString("img:///" $ IconInfo.Images[idx]);
		}
		ChosenPanel.MC.EndOp();

		ChosenPanel.Show();
		ChosenPanel.MC.FunctionVoid("AnimateIn");

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On Chosen Mission Blade UI");
		if (self.IsA('UIMission_GoldenPath') && CanTakeMission())
			`XEVENTMGR.TriggerEvent('OnChosenGoldenPathBlades', , , NewGameState);
		else
			`XEVENTMGR.TriggerEvent('OnChosenMissionBlades', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else if(ChosenPanel != none)
	{
		ChosenPanel.Hide();
	}
	
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function bool CanTakeMission()
{
	return true;
}
simulated function XComGameState_MissionSite GetMission()
{
	return XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionRef.ObjectID));
}
simulated function XComGameState_WorldRegion GetRegion()
{
	return GetMission().GetWorldRegion();
}
simulated function String GetRegionName()
{
	return GetMission().GetWorldRegion().GetMyTemplate().DisplayName;
}
simulated function String GetMissionTitle()
{
	return GetMission().GetMissionSource().MissionPinLabel;
}
simulated function String GetMissionImage()
{
	return GetMission().GetMissionImage(); // Issue #635
}
simulated function String GetOpName()
{
	local GeneratedMissionData MissionData;

	MissionData = XCOMHQ().GetGeneratedMissionData(MissionRef.ObjectID);

	return MissionData.BattleOpName;
}
simulated function String GetObjectiveString()
{
	return GetMission().GetMissionObjectiveText();
}

simulated function String GetMissionDescString()
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local string MissionDesc, AdditionalDesc;
	local int i;
	
	MissionDesc = m_strFlavorText;

	// Check to see if any DLC makes any modifications to 
	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		AdditionalDesc = DLCInfos[i].GetAdditionalMissionDesc(MissionRef);
		if (AdditionalDesc != "")
		{
			MissionDesc $= "\n\n";
			MissionDesc $= AdditionalDesc;
		}
	}

	return MissionDesc;
}

simulated function String GetRewardString()
{
	return GetMission().GetRewardAmountString();
}

simulated function String GetRewardIcon()
{
	return GetMission().GetRewardIcon();
}

simulated function String GetRegionString()
{
	return GetMission().GetWorldRegion().GetMyTemplate().DisplayName;
}

simulated function String GetDifficultyString()
{
	return Caps(GetMission().GetMissionDifficultyLabel());
}

simulated function String GetCrewCount()
{
	return GetMission().m_strShadowCount;
}

simulated function String GetCrewString()
{
	return GetMission().m_strShadowCrew;
}

simulated function bool IsShadowChamberConstructed()
{
	return XCOMHQ().GetFacilityByName('ShadowChamber') != none;
}

simulated function EUIState GetLabelColor()
{
	return eUIState_Normal;
}

simulated function bool CanBackOut()
{
	return (!GetMission().GetMissionSource().bCannotBackOutUI);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:



		if (ConfirmButton != none && ConfirmButton.bIsVisible && !ConfirmButton.IsDisabled)
		{
			ConfirmButton.OnClickedDelegate(ConfirmButton);
			return true;
		}
		else if (Button1 != none && Button1.bIsVisible && !Button1.IsDisabled)
		{
			Button1.OnClickedDelegate(Button1);
			return true;
		}

		//If you don't have a current button, fall down and hit the Navigation system. 
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		if(CanBackOut())
		{
			CloseScreen();
		}
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_L3 :
		if (`ISCONTROLLERACTIVE && SitrepPanel.bIsVisible)
		{
			SitrepPanel.OnInfoButtonMouseEvent(SitrepPanel.InfoButton);
		}
		return true;
		
	}

	return super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
	bAutoSelectFirstNavigable = false;
}
