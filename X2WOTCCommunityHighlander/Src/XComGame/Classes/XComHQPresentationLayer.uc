class XComHQPresentationLayer extends XComPresentationLayerBase;

var XGHQCamera						m_kCamera;
var XComStrategyMap                 m_kXComStrategyMap;

// X2 Screens
var UIAvengerHUD					m_kAvengerHUD;
var UIFacilityGrid				    m_kFacilityGrid;

var UIStrategyMap	            StrategyMap2D;

var bool m_bCanPause;    // Can the user pause the game?
var bool m_bIsShuttling; // Are we currently shuttling from one location to another via the UI navigation? 
var bool m_bInstantTransition; // Cached var when promoting a gifted soldier that hasn't yet seen the psi-promote dialog
var bool m_bWasScanning; // Used for doom camera pan effect
var bool m_bBlockNarrative; // Flag to block narrative triggers when entering or exiting the Geoscape
var bool m_bEnableFlightModeAfterStrategyMapEnter; // Used to enable flight mode as soon as the Strategy Map is created
var bool m_bDelayGeoscapeEntryEvent; // Is the Geoscape entry event being delayed
var bool m_bShowSupplyDropReminder; // Show the Supply Drop reminder upon Geoscape entry?
var bool m_bRecentStaffAvailable; // Flag if staff were recently made available, so ignore warnings
var bool m_bExitFromSimCombat; // If ExitPostMissionSequence() is occuring from a Sim Combat
var bool m_bExitingFromPhotobooth; // Are we exiting from the photobooth

var private array<StateObjectReference> NewCrewMembers;
var private array<XGScreenMgr>  m_arrScreenMgrs;  // DEPRECATED - REMOVE

var private float ForceCameraInterpTime; //Designed to be used with Push/Pop Camera interp time methods so that instant camera cuts can be enforced. Too many independent systems call in to these methods.

// keep track of which avenger room we are currently zoomed into
var private StateObjectReference CurrentFacilityRef; // For triggering on enter events after a timer, not reliable to query current room
var private StateObjectReference CICRoomRef;
var private Vector2D DoomEntityLoc; // for doom panning
var private StateObjectReference FactionRef; // For triggering events and camera pans related to revealing Faction HQs
var private StateObjectReference CovertActionCompleteRef; // For triggering events and camera pans related to Covert Actions
var private bool bFactionRevealSequence; // Are we in the middle of a Faction reveal sequence
var private StateObjectReference AdventChosenRef; // For triggering events and camera pans related to revealing the Chosen

var localized string m_strPsiPromoteDialogTitle;
var localized string m_strPsiPromoteDialogText;
var localized string m_strPsiPromoteNoSpaceDialogTitle;
var localized string m_strPsiPromoteNoSpaceDialogText;
var localized string m_strResearchReportTitle;
var localized string m_strResearchCodenameLabel;
var localized string m_strNewResearchLabel;
var localized string m_strNewItemsLabel;
var localized string m_strNewFacilitiesLabel;
var localized string m_strPauseShadowProjectLabel;
var localized string m_strPauseShadowProjectText;
var localized string m_strShadowProjectInProgressLabel;
var localized string m_strShadowProjectInProgressText;
var localized string m_strRoomLockedLabel;
var localized string m_strRoomLockedText;
var localized string m_strBannerBondAvailable;

// Preview build strings
var localized string m_strPreviewBuildTitle;
var localized string m_strPreviewBuildText;

// ParabolicFacilityTransition means we are moving from one facility to another in a camera swoop,
// in a parabolic fashion, with the 'Base' camera position in the middle.  It is required to
// look up the second facility we are moving to, so we can pre-calculate our camera path.
var private bool					  m_bParabolic;						// Means we're in a facility-to-base-to-facility parabolic camera movement, as opposed to a linear movement (such 'base' to facility).
enum ParabolicFacilityTransitionType
{
	FTT_None,                                                           // Camera is not performing a parabolic transition.
	FTT_Parabolic_In,                                                   // Moving from facility to 'base' in a facility-to-base-to-facility camera movement.  (The first half of the parabola.)
	FTT_Parabolic_Out,                                                  // Moving from 'base' to facility in a facility-to-base-to-facility camera movement.
};
var private ParabolicFacilityTransitionType	m_eParabolicFacilityTransitionType;

var private bool m_bGeoscapeTransition; // Transitions from base to strategy map, or strategy map to base, require special camera transitions.

var private vector					  m_ParabolicFacilityTransition_Focus;
var private rotator				 	  m_ParabolicFacilityTransition_Rotation;
var private float				 	  m_ParabolicFacilityTransition_ViewDistance;
var private float				 	  m_ParabolicFacilityTransition_FOV;
var private PostProcessSettings  	  m_ParabolicFacilityTransition_PPSettings;
var private float				 	  m_ParabolicFacilityTransition_PPOverrideAlpha;

// We queue narrative events (that play trigger fades and movies) so they wait until a camera swoop is finished.
struct QueuedNarrative
{
	var XComGameState_Objective Objective;
	var Object EventData;
	var Object EventSource;
	var XComGameState GameState;
	var Name EventID;

};
var private array<QueuedNarrative> m_QueuedNarratives;

// We queue the expanding of the UIAvengerShortcuts list until the camera reaches the destination room.
struct QueuedListExpansion
{
	var int eCat;           // The index of the category tab.
	var bool bShow;         // If true, we are queuing a show; otherwise, we are queuing a hide.
	var bool bAllShortcuts; // If true, show or hide all shortcuts; if false, just show or hide the list.
};
var private array<QueuedListExpansion> m_QueuedListExpansions;
var private bool m_bQueueListExpansion; // Whether to queue list expansion or not - depends on whether the same or a different tab was selected.

										// We queue screen movies (UIScreens with the Flash movie) to not load and initialize until the camera transition finishes, to prevent camera transition hitches.
struct QueuedScreenMovie
{
	var UIFacility Facility;
	var UIMovie Movie;
};
var private array<QueuedScreenMovie> m_QueuedScreenMovies;
var bool m_bAvengerListExpansionDone; // Trigger when the Avenger shortcut list expansion is done.

var float fCameraSwoopDelayTime; // Delay after a bumper is pressed, before the parabolic camera swoop begins.

var StaticMesh m_overworldCursorMesh;

var transient X2Photobooth_StrategyAutoGen m_kPhotoboothAutoGen;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             INITIALIZATION
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function Init()
{
	local Object SelfObject;

	super.Init();

	m_kCamera = Spawn( class'XGHQCamera', Owner );
	m_kXComStrategyMap = Spawn( class'XComStrategyMap', Owner );

	Init3DDisplay();
	ScreenStack.Show();

	SelfObject = self;
	`XEVENTMGR.RegisterForEvent(SelfObject, 'NewCrewNotification', NewCrewAdded, ELD_OnStateSubmitted);

	// create music object	
	//`CONTENT.RequestObjectAsync("SoundStrategyCollection.HQSoundCollection", self, OnSoundCollectionLoaded);
}

function EventListenerReturn NewCrewAdded(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit CrewUnit;

	CrewUnit = XComGameState_Unit(EventData);
	if (CrewUnit != None)
		NewCrewMembers.AddItem(CrewUnit.GetReference());

	return ELR_NoInterrupt;
}
// Called from InterfaceMgr when it's ready to rock..
simulated function InitUIScreens()
{
	`log("XComHQPresentationLayer.InitUIScreens()",,'uixcom');

	// NO narrative manager in multiplayer games! -tsmith
	// Need this initialized immediately
	if(WorldInfo.NetMode == NM_Standalone)
	{
		m_kNarrativeUIMgr = new(self) class'UINarrativeMgr';
	}

	// Poll until game data is ready.
	SetTimer( 0.2, true, 'PollForUIScreensComplete');
}

simulated function PollForUIScreensComplete()
{
	local XGStrategy kStrategy;

	kStrategy = `Game;

	m_bIsGameDataReady = kStrategy != none && `XPROFILESETTINGS != none;

	if ( m_bIsGameDataReady  )
	{
		ClearTimer( 'PollForUIScreensComplete' );
		InitUIScreensComplete();
	}
}

simulated function InitUIScreensComplete()
{
	super.InitUIScreens();
	UIWorldMessages();
	m_bPresLayerReady = true;
}

simulated function bool IsBusy()
{
	return (CAMIsBusy() || !Get2DMovie().bIsInited || !IsPresentationLayerReady());
}

event Destroyed( )
{
	local Object SelfObject;

	if(m_kPhotoboothAutoGen != none)
		m_kPhotoboothAutoGen.Destroy();

	super.Destroyed( );

	SelfObject = self;
	`XEVENTMGR.UnRegisterFromEvent(SelfObject, 'NewCrewNotification');
}

simulated event OnCleanupWorld( )
{
	local Object SelfObject;

	if (m_kPhotoboothAutoGen != none)
		m_kPhotoboothAutoGen.Destroy();

	super.OnCleanupWorld( );

	SelfObject = self;
	`XEVENTMGR.UnRegisterFromEvent(SelfObject, 'NewCrewNotification');
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                              UI INTERFACE
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function ClearToFacilityMainMenu(optional bool bInstant = false)
{
	local UIFacilityGrid kScreen;
	m_kFacilityGrid.DeactivateGrid();
	m_kAvengerHUD.FacilityHeader.Hide();
	kScreen = UIFacilityGrid(ScreenStack.GetScreen(class'UIFacilityGrid'));
	kScreen.bInstantInterp = bInstant;
	ScreenStack.PopUntilClass(class'UIFacilityGrid', true);
}

simulated function ClearUIToHUD(optional bool bInstant = true)
{
	//Clear any screens, like alerts, off the strategy map first. 
	ScreenStack.PopUntilClass(class'UIStrategyMap', false);

	// Now let the map exit properly. 
	if(ScreenStack.IsInStack(class'UIStrategyMap'))
	{
		m_bBlockNarrative = true;
		ExitStrategyMap(false);
	}

	//And finish the clear. 
	ClearToFacilityMainMenu(bInstant);
}

simulated private function XComStrategySoundManager GetSoundMgr() 
{ 
	return `XSTRATEGYSOUNDMGR; 
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                                  X2 UI
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function ExitPostMissionSequence()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local X2EventManager EventManager;
	local XComOnlineEventMgr OnlineEventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local XComGameState_CampaignSettings SettingsState;
	local int i;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ResistanceHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Mission ID");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.MissionRef.ObjectID = 0;
	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent('PostMissionDone', XComHQ, XComHQ, NewGameState);
	XComHQ.ResetToDoWidgetWarnings();
	XComHQ.PlayedAmbientSpeakers.Length = 0; // Reset availability of ambient speaker lines
	
	// Clear rewards recap data
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	ResistanceHQ.ClearRewardsRecapData();	

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	//Communication with the matinee controlling the camera
	`XCOMGRI.DoRemoteEvent('PostMissionDone');
	
	// Hack to get around unnecessary actor (InterpActor_5) existing in CIN_PostMission1.umap, which pops into view for a few frames.
	// TODO KD: Revert this change and remove the actor from the map in a future patch.
	`GAME.GetGeoscape().m_kBase.SetPostMissionSequenceVisibility(false);
	if (m_bExitFromSimCombat)
	{
		m_bExitFromSimCombat = false;

		//Set a timer that will reset the post mission map. Used to avoid conflict with the PostMissionDone remote event.
		SetTimer(`HQINTERPTIME, false, nameof(ExitPostMission_ResetMap));
	}

	// Return to the Avenger
	`XSTRATEGYSOUNDMGR.PlayBaseViewMusic();
	ClearToFacilityMainMenu();

	DisplaySoldierCapturedIfNeeded();

	DisplayWarningPopups();

	// Queue new staff popup if any have been received
	DisplayNewStaffPopupIfNeeded();

	DisplayQueuedDynamicPopups();

	// If our force is understrength, warn the player
	if (!XComHQ.AnyTutorialObjectivesInProgress() && XComHQ.GetNumberOfDeployableSoldiers() < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
	{ 
		UIForceUnderstrength();
	}

	if (!XComHQ.bHasSeenSupplyDropReminder && XComHQ.IsSupplyDropAvailable())
	{
		m_bShowSupplyDropReminder = true;
	}
	
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshFacilityPatients();
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshMemorialPolaroids();
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshWantedCaptures();

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	`XENGINE.m_kPhotoManager.FillPropagandaTextureArray(ePWM_Campaign, SettingsState.GameIndex);

	OnlineEventManager = `ONLINEEVENTMGR;
	DLCInfos = OnlineEventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnExitPostMissionSequence();
	}

	PostMissionNegativeTraitNotifies();
	PostMissionBondNotifies();
	
	if( `CHEATMGR.bShouldAutosaveBeforeEveryAction )
	{
		`AUTOSAVEMGR.DoAutosave(, true, , true);
	}
}

private function PostMissionBondNotifies()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> AllSoldiers;
	local XComGameState_Unit UnitStateA, UnitStateB;
	local SoldierBond BondData;
	local int BondIndex, PartnerBondIndex, i, j, PopupCount;
	local StateObjectReference BondmateRefA, BondmateRefB;
	local string BondIconPath;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AllSoldiers = XComHQ.GetSoldiers();
	PopupCount = 0;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission Bond Notify Cleanup");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	for(i = 0; i < (AllSoldiers.Length-1); i++)
	{
		UnitStateA = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AllSoldiers[i].ObjectID));

		for(j = (i+1); j < AllSoldiers.Length; j++)
		{
			UnitStateB = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AllSoldiers[j].ObjectID));

			if(UnitStateA.GetBondData(UnitStateB.GetReference(), BondData) && BondData.bBondJustBecameAvailable)
			{
				switch( BondData.BondLevel + 1)
				{
				case 1:
					BondIconPath = "img:///UILibrary_XPACK_Common.SoldierBond_icon_1";
					break;
				case 2:
					BondIconPath = "img:///UILibrary_XPACK_Common.SoldierBond_icon_2";
					break;
				case 3:
					BondIconPath = "img:///UILibrary_XPACK_Common.SoldierBond_icon_3";
					break;
				default:
					BondIconPath = "";
				}

				if( BondIconPath != "" )
				{
					NotifyBanner(m_strBannerBondAvailable, BondIconPath, UnitStateA.GetName(eNameType_RankFull) $ "," @ UnitStateB.GetName(eNameType_RankFull), , eUIState_Good);
					BondIndex = UnitStateA.AllSoldierBonds.Find('Bondmate', UnitStateB.GetReference());
					PartnerBondIndex = UnitStateB.AllSoldierBonds.Find('Bondmate', UnitStateA.GetReference());
					UnitStateA.AllSoldierBonds[BondIndex].bBondJustBecameAvailable = false;
					UnitStateB.AllSoldierBonds[PartnerBondIndex].bBondJustBecameAvailable = false;

					if( PopupCount == 0 )
					{
						PopupCount++;
						BondmateRefA = UnitStateA.GetReference();
						BondmateRefB = UnitStateB.GetReference();
					}
				}
			}
		}
	}
	
	if(PopupCount > 0 && !XComHQ.bHasSeenSoldierBondPopup)
	{
		XComHQ.bHasSeenSoldierBondPopup = true;
		UISoldierBondAlert(BondmateRefA, BondmateRefB, NewGameState);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

private function PostMissionNegativeTraitNotifies()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> AllSoldiers;
	local X2EventListenerTemplateManager EventTemplateManager;
	local X2TraitTemplate TraitTemplate;
	local XComGameState_Unit UnitState, PopupUnit;
	local name TraitName, StoredTraitName;
	local int PopupCount;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();
	AllSoldiers = XComHQ.GetSoldiers();
	PopupCount = 0;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission Trait Notify Cleanup");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	foreach AllSoldiers(UnitState)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		foreach UnitState.WorldMessageTraits(TraitName)
		{
			TraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(TraitName));

			if(TraitTemplate != none)
			{
				NotifyBanner(UnitState.GetName(eNameType_Full), "img:///UILibrary_StrategyImages.X2StrategyMap.MapPin_Poi", class'UIAlert'.default.m_strNegativeTraitAcquiredTitle, TraitTemplate.TraitFriendlyName, eUIState_Bad);

				if(PopupCount == 0)
				{
					PopupCount++;
					PopupUnit = UnitState;
					StoredTraitName = TraitName;
				}
			}
		}

		UnitState.WorldMessageTraits.Length = 0;
	}

	if(PopupCount > 0 && !XComHQ.bHasSeenNegativeTraitPopup)
	{
		XComHQ.bHasSeenNegativeTraitPopup = true;
		UINegativeTraitAlert(NewGameState, PopupUnit, StoredTraitName);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

private function ExitPostMission_ResetMap()
{
	`GAME.GetGeoscape().m_kBase.ResetPostMissionMap(); //Reset the post mission map so that sim combat can run it over and over without issue
}

simulated function SetFacilityBuildPreviewVisibility(int MapIndex, name TemplateName, bool bVisible)
{
	`GAME.GetGeoscape().m_kBase.SetFacilityBuildPreviewVisibility(MapIndex, TemplateName, bVisible);
}

simulated function DisplayNewStaffPopupIfNeeded()
{
	local StateObjectReference NewCrewRef;
	
	foreach NewCrewMembers(NewCrewRef)
	{
		UINewStaffAvailable(NewCrewRef, true, false, false);
	}
	NewCrewMembers.Length = 0;
}

simulated function DisplaySoldierCapturedIfNeeded()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_AdventChosen ChosenState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if (XComHQ.LastMission.bChosenEncountered && AlienHQ.LastChosenEncounter.bCapturedSoldier)
	{
		ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(AlienHQ.LastAttackingChosen.ObjectID));
		if (ChosenState.CapturedSoldiers.Length > 0) // Make sure the Chosen has at least one captured soldier
		{
			// Grab the last captured soldier in the array, since they are the most recent addition
			UISoldierCaptured(ChosenState, ChosenState.CapturedSoldiers[ChosenState.CapturedSoldiers.Length - 1], true);
		}
	}
}

simulated function DisplayWarningPopups()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime StartDateTime, CurrentTime;
	local int MinStaffRequired, NumStaff, MonthsDifference;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (!XComHQ.bHasSeenLowSuppliesPopup && XComHQ.GetSupplies() < 50)
	{
		UILowSupplies();
	}

	if (!XComHQ.bHasSeenLowIntelPopup && XComHQ.GetIntel() < class'UIUtilities_Strategy'.static.GetMinimumContactCost() && XComHQ.IsContactResearched())
	{
		UILowIntel();
	}

	// Calculate how many months have passed
	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	MonthsDifference = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime);
	
	// Only give staff warnings after the first month
	if (MonthsDifference > 0)
	{
		// If the scientist or engineer numbers are below the minimum expected values for this point in the game, give a warning
		MinStaffRequired = `ScaleStrategyArrayFloat(XComHQ.StartingScientistMinCap) + (`ScaleStrategyArrayFloat(XComHQ.ScientistMinCapIncrease) * MonthsDifference);
		NumStaff = XComHQ.GetNumberOfScientists();
		if (NumStaff < `ScaleStrategyArrayInt(XComHQ.ScientistNeverWarnThreshold) && NumStaff < MinStaffRequired && class'X2StrategyGameRulesetDataStructures'.static.LessThan(XComHQ.LowScientistPopupTime, `STRATEGYRULES.GameTime))
		{
			// Reset the scientist popup timer
			XComHQ.ResetLowScientistsPopupTimer();

			if (!XComHQ.bHasSeenLowScientistsPopup)
			{
				UILowScientists();
			}
			else
			{
				UILowScientistsSmall();
			}
		}

		MinStaffRequired = `ScaleStrategyArrayFloat(XComHQ.StartingEngineerMinCap) + (`ScaleStrategyArrayFloat(XComHQ.EngineerMinCapIncrease) * MonthsDifference);
		NumStaff = XComHQ.GetNumberOfEngineers();
		if (NumStaff < `ScaleStrategyArrayInt(XComHQ.EngineerNeverWarnThreshold) && NumStaff < MinStaffRequired && class'X2StrategyGameRulesetDataStructures'.static.LessThan(XComHQ.LowEngineerPopupTime, `STRATEGYRULES.GameTime))
		{
			// Reset the engineer popup timer
			XComHQ.ResetLowEngineersPopupTimer();

			if (!XComHQ.bHasSeenLowEngineersPopup)
			{
				UILowEngineers();
			}
			else
			{
				UILowEngineersSmall();
			}
		}
	}
}

//----------------------------------------------------
// STRATEGY MAP + HUD
//----------------------------------------------------
//bTransitionFromSideView is TRUE when we want to perform a smooth fly-in from the side view to the map view
function UIEnterStrategyMap(bool bSmoothTransitionFromSideView = false)
{
	m_bCanPause = false; // Do not let the player pause the game during the map transition

	if (!bSmoothTransitionFromSideView)
	{
		StrategyMap_FinishTransitionEnter();
	}
	else
	{
		//Find the CIC facility and start the camera transitioning to the starting point for 
		//for the matinee driven smooth transition
		`HQPRES.CAMLookAtRoom(GetCICRoom(), `HQINTERPTIME);

		//Set a timer that will fire when the camera has finished moving to the CIC
		SetTimer(`HQINTERPTIME, false, nameof(StrategyMap_StartTransitionEnter));
	}
	
	m_kAvengerHUD.ClearResources();
	m_kAvengerHUD.HideEventQueue();
	m_kFacilityGrid.Hide();
	m_kAvengerHUD.Shortcuts.Hide();
	m_kAvengerHUD.ToDoWidget.Hide();
}

private function StrategyMap_StartTransitionEnter()
{
	//Register to be a listener for remote events - a remote event will let us know when the matinee is done
	WorldInfo.RemoteEventListeners.AddItem(self);

	//Now that we are in the reference position in front of the CIC, start the smooth transition matinee
	//This puts the camera into cinematic mode
	`XCOMGRI.DoRemoteEvent('CIN_TransitionToMap');	
}

event OnRemoteEvent(name RemoteEventName)
{
	super.OnRemoteEvent(RemoteEventName);

	//Watch for the signal that the transition matinee is finished
	if (RemoteEventName == 'FinishedTransitionIntoMap')
	{
		WorldInfo.RemoteEventListeners.RemoveItem(self);

		//The camera and transition effects are done, fire up the strategy map now
		StrategyMap_FinishTransitionEnter();
	}
	else if (RemoteEventName == 'FinishedTransitionFromMap')
	{
		WorldInfo.RemoteEventListeners.RemoveItem(self);

		//Make sure the strategy game UI is not showing at this point
		if (StrategyMap2D != none)
			StrategyMap2D.Hide();

		//Instantly set the camera position to the CIC room position, then run a normal transition back to the grid view
		`HQPRES.CAMLookAtRoom(GetCICRoom(), 0);

		//Let the game tick to set the camera position, then wrap it up
		SetTimer(0.1f, false, nameof(StrategyMap_StartTransitionExit));
	}
	else if( RemoteEventName == 'CIN_CouncilMovieComplete' )
	{
		ShowUIForCinematics();
		m_kUIMouseCursor.Show();
		m_kAvengerHUD.Movie.Stack.PopFirstInstanceOfClass(class'UIFacility', false);
		PlayUISound(eSUISound_MenuClose);
	}
}

private function StrategyMap_FinishTransitionEnter()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_MissionCalendar CalendarState;
	local XComGameState_MissionSite MissionState;

	//Load map first, underneath the HUD.
	StrategyMap2D = Spawn(class'UIStrategyMap', self);
	ScreenStack.Push(StrategyMap2D);
	

	GetCamera().ForceEarthViewImmediately(true);
	`XSTRATEGYSOUNDMGR.PlayGeoscapeMusic();

	`GAME.GetGeoscape().m_kBase.UpdateFacilityProps();

	//Trigger the base crew to update their positions now that we know we aren't looking at them
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.PopulateBaseRoomsWithCrew();

	m_kXComStrategyMap.EnterStrategyMap();
	m_kXComStrategyMap.UpdateVisuals();

	GetMgr(class'XGMissionControlUI').UpdateView();

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(XComHQ.bXComFullGameVictory || AlienHQ.bAlienFullGameVictory)
	{
		StrategyMap2D.SetUIState(eSMS_Flight);
		return;
	}

	if (!StrategyMap2D.HasLastSelectedMapItem())
	{
		StrategyMap2D.LookAtAvenger(0.0f);
	}

	if(XComHQ.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') == eObjectiveState_InProgress)
	{
		// Need to see GOp on the map
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Spawn First Tutorial GOP");
		CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
		CalendarState = XComGameState_MissionCalendar(NewGameState.ModifyStateObject(class'XComGameState_MissionCalendar', CalendarState.ObjectID));
		CalendarState.Update(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(XComHQ.StartingRegion.ObjectID));
		XComHQ.SetPendingPointOfTravel(RegionState, true);
	}
	else if (XComHQ.GetObjectiveStatus('XP0_M1_LostAndAbandonedComplete') == eObjectiveState_InProgress || XComHQ.GetObjectiveStatus('XP0_M1_TutorialLostAndAbandonedComplete') == eObjectiveState_InProgress)
	{
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if (MissionState.GetMissionSource().DataName == 'MissionSource_LostAndAbandoned')
			{
				OnMissionSelected(MissionState, true);
				break;
			}
		}
	}
	else if(XComHQ.bNeedsToSeeFinalMission)
	{
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.GetMissionSource().DataName == 'MissionSource_Final')
			{
				OnMissionSelected(MissionState, true);
				break;
			}
		}
	}
	else
	{
		if (StrategyMap2D.HasLastSelectedMapItem())
		{
			StrategyMap2D.SelectLastSelectedMapItem();
		}
	}
	
	if (m_bEnableFlightModeAfterStrategyMapEnter)
	{
		StrategyMap2D.SetUIState(eSMS_Flight);
		m_bEnableFlightModeAfterStrategyMapEnter = false;
	}

	//Set a timer that will fire when the camera has finished moving to the CIC
	SetTimer(`HQINTERPTIME, false, nameof(StrategyMap_TriggerGeoscapeEntryEvent));

	m_bCanPause = true; // The player can pause the game again
}

private function StrategyMap_TriggerGeoscapeEntryEvent()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XGGeoscape kGeoscape;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	kGeoscape = `GAME.GetGeoscape();
	
	if(!XComHQ.bNeedsToSeeFinalMission)
	{
		kGeoscape.Resume();

		// First check if we need to show doom stuff
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHQ.Update(true);
		History = `XCOMHISTORY;
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

		if(AlienHQ.PendingDoomData.Length > 0)
		{
			m_bDelayGeoscapeEntryEvent = true;
			AlienHQ.HandlePendingDoom();
		}
		else
		{
			GeoscapeEntryEvent();
		}
	}

	EndGeoscapeCameraTransition();
}

function DisableFlightModeAndTriggerGeoscapeEvent()
{
	StrategyMap2D.SetUIState(eSMS_Default);
	GeoscapeEntryEvent();
}

function GeoscapeEntryEvent()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_CampaignSettings CampaignState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState NewGameState;
	
	// Use this event if something should be triggered after the Geoscape finishes loading (Ex: Camera pans to reveal missions)
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Entered Geoscape Event");
	`XEVENTMGR.TriggerEvent('OnGeoscapeEntry', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	History = `XCOMHISTORY;
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	if (!ResHQ.bFirstPOISpawned)
	{
		// Only do this check in non-tutorial games, since a POI is spawned as part of that objective flow
		CampaignState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		if (!CampaignState.bTutorialEnabled)
		{
			if (CampaignState.bSuppressFirstTimeNarrative || ResHQ.bFirstPOIActivated)
			{
				// When beginner VO is turned off, trigger the event to spawn a POI the first time the player enters the Geoscape
				// When beginner VO is enabled, check to see if Central's dialogue has been completed, and spawn POI if it has, because it wasn't generated for some reason
				ResHQ.AttemptSpawnRandomPOI();
			}
			else
			{
				// Central's dialogue has not been completed yet, so flag ResHQ as activated so if the POI doesn't spawn, it will on the next Geoscape entry
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Flag ResHQ First POI Activated");
				ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
				ResHQ.bFirstPOIActivated = true;
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	if (AlienHQ.bChosenJustBecameFavored)
	{
		ChosenState = AlienHQ.GetFavoredChosen();
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Favored Chosen on Geoscape");
		`XEVENTMGR.TriggerEvent(ChosenState.GetFavoredGeoscapeEvent(), ChosenState, ChosenState, NewGameState);
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		AlienHQ.bChosenJustBecameFavored = false;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	m_bBlockNarrative = false; // Turn off the narrative block in case it never got reset
	m_bRecentStaffAvailable = false; // Turn off the recent staff available block
	m_bDelayGeoscapeEntryEvent = false;

	if (m_bShowSupplyDropReminder)
	{
		UISupplyDropReminder();
		m_bShowSupplyDropReminder = false;
	}
}

function ExitStrategyMap(bool bSmoothTransitionFromSideView = false)
{
	BeginGeoscapeCameraTransition();
	m_kXComStrategyMap.ExitStrategyMap();
	
	m_bCanPause = false; // Do not let the player cause the game during the exit transition

	if (!bSmoothTransitionFromSideView)
	{
		StrategyMap_FinishTransitionExit();
	}
	else
	{
		//Register to be a listener for remote events - a remote event will let us know when the matinee is done
		WorldInfo.RemoteEventListeners.AddItem(self);

		//Fire off the matinee transition out of the map view
		`XCOMGRI.DoRemoteEvent('CIN_TransitionFromMap');
	}
}

private function StrategyMap_StartTransitionExit()
{
	//Start the transition back to the base side view camera
	CAMLookAtNamedLocation("Base", `HQINTERPTIME);
	
	//The camera and transition effects are done, fire up the strategy map now
	SetTimer(`HQINTERPTIME, false, nameof(StrategyMap_FinishTransitionExit));
}

private function StrategyMap_FinishTransitionExit()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComWeatherControl WeatherActor;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStop");

	// We need to specifically show the elements hidden during the camera transition, because the stack changes already happened 
	// while the camera moved, and so the UI elements wouldn't get a trigger to update. 
	m_kFacilityGrid.Show();
	m_kAvengerHUD.Show();
	
	`GAME.GetGeoscape().Pause();

	m_bCanPause = true; // Allow the player to pause the game again

	// Need to update the static depth texture for the current weather actor to make sure the avenger gets rendered to it
	foreach `XWORLDINFO.AllActors(class'XComWeatherControl', WeatherActor)
	{
		WeatherActor.UpdateStaticRainDepth();
	}

	if (!m_bBlockNarrative)
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
		AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
		if(XComHQ.GetObjectiveStatus('T5_M3_CompleteFinalMission') != eObjectiveState_InProgress)
		{
			// Central nags to the player about hunting the Chosen. They're important so they live outside the normal if/else block.

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Hunt Chosen Nags");
			if (AlienHQ.HighestChosenKnowledgeLevel == eChosenKnowledge_Saboteur)
			{
				`XEVENTMGR.TriggerEvent('OnHuntChosenNag1', , , NewGameState);
			}
			else if (AlienHQ.HighestChosenKnowledgeLevel == eChosenKnowledge_Sentinel)
			{
				`XEVENTMGR.TriggerEvent('OnHuntChosenNag2', , , NewGameState);
			}
			else if (AlienHQ.HighestChosenKnowledgeLevel == eChosenKnowledge_Collector)
			{
				`XEVENTMGR.TriggerEvent('OnHuntChosenNag3', , , NewGameState);
			}
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			if (!XComHQ.bPlayedWarningNoResearch && !XComHQ.HasResearchProject() && !XComHQ.HasShadowProject() &&
				(XComHQ.HasTechsAvailableForResearchWithRequirementsMet() || XComHQ.HasTechsAvailableForResearchWithRequirementsMet(true)))
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: No Research");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.bPlayedWarningNoResearch = true;
				`XEVENTMGR.TriggerEvent('WarningNoResearch', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else if (!XComHQ.bPlayedWarningNoRing && ResHQ.HaveMetAnyFactions() && AlienHQ.HaveMetAnyChosen() && 
				!XComHQ.HasFacilityByName('ResistanceRing') && !XComHQ.IsBuildingFacilityByName('ResistanceRing'))
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: No Ring");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.bPlayedWarningNoRing = true;
				`XEVENTMGR.TriggerEvent('WarningNoRing', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else if (!XComHQ.bPlayedWarningNoCovertAction && XComHQ.HasFacilityByName('ResistanceRing') && !ResHQ.IsCovertActionInProgress())
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: No Covert Action");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.bPlayedWarningNoCovertAction = true;
				`XEVENTMGR.TriggerEvent('WarningNoCovertAction', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else if(!XComHQ.bPlayedWarningNoIncome && class'UIUtilities_Strategy'.static.GetResistanceHQ().GetSuppliesReward() <= 0)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: No Income");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.bPlayedWarningNoIncome = true;
				`XEVENTMGR.TriggerEvent('WarningNoIncome', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else if (!m_bRecentStaffAvailable && !XComHQ.bPlayedWarningUnstaffedEngineer && XComHQ.GetNumberOfUnstaffedEngineers() > 0 && XComHQ.HasEmptyEngineerSlotsAvailable())
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Unstaffed Engineer");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.bPlayedWarningUnstaffedEngineer = true;
				if(XComHQ.Facilities.Length >= 12 && XComHQ.Facilities.Length <= 19 && !XComHQ.HasActiveConstructionProject())
					`XEVENTMGR.TriggerEvent('OnFacilityNag', , , NewGameState);
				else
					`XEVENTMGR.TriggerEvent('WarningUnstaffedEngineer', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else if(!XComHQ.bPlayedWarningUnstaffedScientist && XComHQ.GetNumberOfUnstaffedScientists() > 0 && XComHQ.GetFacilityByNameWithOpenStaffSlots('Laboratory') != none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Unstaffed Scientist");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.bPlayedWarningUnstaffedScientist = true;
				`XEVENTMGR.TriggerEvent('WarningUnstaffedScientist', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}
	else
	{
		m_bBlockNarrative = false; // Turn off the block now that the transition is complete
	}

	EndGeoscapeCameraTransition();
}

function CameraTransitionToCIC ()
{
	`HQPRES.CAMLookAtRoom(GetCICRoom(), `HQINTERPTIME);
}

private function XComGameState_HeadquartersRoom GetCICRoom()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	if (CICRoomRef.ObjectID < 1)
	{
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if (FacilityState.GetMyTemplateName() == 'CIC')
			{
				CICRoomRef = FacilityState.GetRoom().GetReference();
				break;
			}
		}
	}

	return XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(CICRoomRef.ObjectID));
}

//----------------------------------------------------
// DOOM EFFECT
//----------------------------------------------------

function float GetDoomTimerVisModifiers()
{
	return `XPROFILESETTINGS.Data.bEnableZipMode ? class'X2TacticalGameRuleset'.default.ZipModeDoomVisModifier : 1.0;
}

//---------------------------------------------------------------------------------------
function NonPanClearDoom(bool bPositive)
{
	StrategyMap2D.SetUIState(eSMS_Flight);

	if(bPositive)
	{
		StrategyMap2D.StrategyMapHUD.StartDoomRemovedEffect();
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_DecreaseScreenTear_ON");
	}
	else
	{
		StrategyMap2D.StrategyMapHUD.StartDoomAddedEffect();
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_IncreasedScreenTear_ON");
	}

	SetTimer(3.0f * GetDoomTimerVisModifiers(), false, nameof(NoPanClearDoomPt2));
}

//---------------------------------------------------------------------------------------
function NoPanClearDoomPt2()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ.ClearPendingDoom();

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(AlienHQ.PendingDoomData.Length > 0)
	{
		SetTimer(4.0f * GetDoomTimerVisModifiers(), false, nameof(NoPanClearDoomPt2));
	}
	else
	{
		SetTimer(4.0f * GetDoomTimerVisModifiers(), false, nameof(UnPanDoomFinished));
	}
}

//---------------------------------------------------------------------------------------
function DoomCameraPan(XComGameState_GeoscapeEntity EntityState, bool bPositive, optional bool bFirstFacility = false)
{
	CAMSaveCurrentLocation();
	StrategyMap2D.SetUIState(eSMS_Flight);

	// Stop Scanning
	if(`GAME.GetGeoscape().IsScanning())
	{
		StrategyMap2D.ToggleScan();
	}

	if(bPositive)
	{
		StrategyMap2D.StrategyMapHUD.StartDoomRemovedEffect();
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_DecreaseScreenTear_ON");
	}
	else
	{
		StrategyMap2D.StrategyMapHUD.StartDoomAddedEffect();
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_IncreasedScreenTear_ON");
	}

	DoomEntityLoc = EntityState.Get2DLocation();

	if(bFirstFacility)
	{
		SetTimer(3.0f * GetDoomTimerVisModifiers(), false, nameof(StartFirstFacilityCameraPan));
	}
	else
	{
		SetTimer(3.0f * GetDoomTimerVisModifiers(), false, nameof(StartDoomCameraPan));
	}
}

//---------------------------------------------------------------------------------------
function StartDoomCameraPan()
{
	// Pan to the location
	CAMLookAtEarth(DoomEntityLoc, 0.5f, `HQINTERPTIME);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_Camera_Whoosh");
	SetTimer((`HQINTERPTIME + 3.0f * GetDoomTimerVisModifiers()), false, nameof(DoomCameraPanComplete));
}

//---------------------------------------------------------------------------------------
function StartFirstFacilityCameraPan()
{
	CAMLookAtEarth(DoomEntityLoc, 0.5f, `HQINTERPTIME);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_Camera_Whoosh");
	SetTimer((`HQINTERPTIME), false, nameof(FirstFacilityCameraPanComplete));
}

//---------------------------------------------------------------------------------------
function DoomCameraPanComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ.ClearPendingDoom();

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(AlienHQ.PendingDoomData.Length > 0)
	{
		SetTimer(4.0f * GetDoomTimerVisModifiers(), false, nameof(DoomCameraPanComplete));
	}
	else
	{
		SetTimer(4.0f * GetDoomTimerVisModifiers(), false, nameof(UnpanDoomCamera));
	}
}

//---------------------------------------------------------------------------------------
function FirstFacilityCameraPanComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState NewGameState;
	local StateObjectReference EmptyRef;
	local XComGameState_MissionSite MissionState;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fire First Facility Event");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));

	if(AlienHQ.PendingDoomEvent != '')
	{
		`XEVENTMGR.TriggerEvent(AlienHQ.PendingDoomEvent, , , NewGameState);
	}

	AlienHQ.PendingDoomEvent = '';
	AlienHQ.PendingDoomEntity = EmptyRef;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.GetMissionSource().bAlienNetwork)
		{
			break;
		}
	}

	StrategyMap2D.StrategyMapHUD.StopDoomAddedEffect();
	StrategyMap2D.SetUIState(eSMS_Default);
	OnMissionSelected(MissionState, false);

	// Once the first facility camera pan is completed and mission blades are displayed, queue up any DLC specific alerts
	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPostFacilityDoomVisualization();
	}
}

//---------------------------------------------------------------------------------------
function UnpanDoomCamera()
{
	CAMRestoreSavedLocation();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_Camera_Whoosh");
	SetTimer((`HQINTERPTIME + 3.0f * GetDoomTimerVisModifiers()), false, nameof(UnPanDoomFinished));
}

//---------------------------------------------------------------------------------------
function UnPanDoomFinished()
{
	StrategyMap2D.StrategyMapHUD.StopDoomRemovedEffect();
	StrategyMap2D.StrategyMapHUD.StopDoomAddedEffect();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_Increase_and_Decrease_Off");
	StrategyMap2D.SetUIState(eSMS_Default);

	if(m_bDelayGeoscapeEntryEvent)
	{
		GeoscapeEntryEvent();
	}
}

//----------------------------------------------------
// TOP LEVEL AVENGER
//----------------------------------------------------
function UIAvengerFacilityMenu()
{
	m_kAvengerHUD = Spawn( class'UIAvengerHUD', self );
	ScreenStack.Push( m_kAvengerHUD );

	m_kFacilityGrid = Spawn( class'UIFacilityGrid', self );
	ScreenStack.Push( m_kFacilityGrid );

	// TODO: This isn't used anymore, delete it -sbatista
	//ScreenStack.Push( Spawn( class'UIStrategyDebugMenu', self ) );

	//SOUND().PlayAmbience( eAmbience_HQ );
	XComHeadquartersController(Owner).SetInputState( 'HQ_FreeMovement' );
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_AvengerNoRoom");
}

//----------------------------------------------------
// PERSONNEL MANAGEMENT
//----------------------------------------------------
function UIPersonnel(optional EUIPersonnelType eListType = eUIPersonnel_All, optional delegate<UIPersonnel.OnPersonnelSelected> onSelected = none, optional bool RemoveScreenAfterSelection = false, optional StateObjectReference SlotRef)
{
	local UIPersonnel kPersonnelList;
	
	if(ScreenStack.IsNotInStack(class'UIPersonnel'))
	{
		kPersonnelList = Spawn( class'UIPersonnel', self );
		kPersonnelList.m_eListType = eListType;
		kPersonnelList.onSelectedDelegate = onSelected;
		kPersonnelList.m_bRemoveWhenUnitSelected = RemoveScreenAfterSelection;
		kPersonnelList.SlotRef = SlotRef;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_Armory(optional delegate <UIPersonnel.OnPersonnelSelected> onSelected = none)
{
	local UIPersonnel_Armory kPersonnelList;

	if (ScreenStack.IsNotInStack(class'UIPersonnel_Armory'))
	{
		kPersonnelList = Spawn(class'UIPersonnel_Armory', self);
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push(kPersonnelList);
	}
}

function UIPersonnel_BuildFacility(optional delegate<UIPersonnel.OnPersonnelSelected> onSelected = none, optional X2FacilityTemplate FacilityTemplate = none, optional bool RemoveScreenAfterSelection = true, optional StateObjectReference RoomRef)
{
	local UIPersonnel_BuildFacility kPersonnelList;
	
	if(ScreenStack.IsNotInStack(class'UIPersonnel_BuildFacility'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_BuildFacility', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		kPersonnelList.m_bRemoveWhenUnitSelected = RemoveScreenAfterSelection;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_SquadSelect(delegate<UIPersonnel.OnPersonnelSelected> onSelected, XComGameState UpdateState, XComGameState_HeadquartersXCom HQState)
{
	local UIPersonnel_SquadSelect kPersonnelList;
	
	if(ScreenStack.IsNotInStack(class'UIPersonnel_SquadSelect'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_SquadSelect', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		kPersonnelList.GameState = UpdateState;
		kPersonnelList.HQState = HQState;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_BarMemorial(delegate<UIPersonnel.OnPersonnelSelected> onSelected)
{
	local UIPersonnel_BarMemorial kPersonnelList;

	if(ScreenStack.IsNotInStack(class'UIPersonnel_BarMemorial'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_BarMemorial', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_ChooseResearch(delegate<UIPersonnel.OnPersonnelSelected> onSelected, StateObjectReference StaffSlotRef)
{
	local UIPersonnel_ChooseResearch kPersonnelList;

	if(ScreenStack.IsNotInStack(class'UIPersonnel_ChooseResearch'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_ChooseResearch', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_SpecialFeature(delegate<UIPersonnel.OnPersonnelSelected> onSelected, StateObjectReference RoomRef)
{
	local UIPersonnel_SpecialFeature kPersonnelList;

	if(ScreenStack.IsNotInStack(class'UIPersonnel_SpecialFeature'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_SpecialFeature', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_LivingQuarters(delegate<UIPersonnel.OnPersonnelSelected> onSelected)
{
	local UIPersonnel_LivingQuarters kPersonnelList;

	if (ScreenStack.IsNotInStack(class'UIPersonnel_LivingQuarters'))
	{
		kPersonnelList = Spawn(class'UIPersonnel_LivingQuarters', self);
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push(kPersonnelList);
	}
}

//----------------------------------------------------
// Memorial Details
//----------------------------------------------------
function UIBarMemorial_Details(StateObjectReference UnitRef)
{
	if(ScreenStack.IsNotInStack(class'UIBarMemorial_Details'))
	{
		UIBarMemorial_Details(ScreenStack.Push(Spawn(class'UIBarMemorial_Details', self), Get3DMovie())).InitMemorial(UnitRef);
	}
}


//----------------------------------------------------
// ARMORY (Soldier / Weapon Management)
//----------------------------------------------------
function UISoldierIntroCinematic(name SoldierClassName, StateObjectReference SoldierRef, optional bool bNoCallback)
{
	if (ScreenStack.IsNotInStack(class'UISoldierIntroCinematic'))
	{
		if (bNoCallback)
		{
			UISoldierIntroCinematic(ScreenStack.Push(Spawn(class'UISoldierIntroCinematic', self), Get3DMovie())).InitCinematic(SoldierClassName, SoldierRef);
		}
		else if (bFactionRevealSequence) // If we are in the middle of a Covert Action Complete sequence, don't callback to the Armory
		{
			UISoldierIntroCinematic(ScreenStack.Push(Spawn(class'UISoldierIntroCinematic', self), Get3DMovie())).InitCinematic(SoldierClassName, SoldierRef, UIFactionRevealComplete);
		}
		else 
		{
			UISoldierIntroCinematic(ScreenStack.Push(Spawn(class'UISoldierIntroCinematic', self), Get3DMovie())).InitCinematic(SoldierClassName, SoldierRef, ShowPromotionUI);
		}
	}
}

function UIArmorIntroCinematic(name StartEventName, name StopEventName, StateObjectReference SoldierRef)
{
	local UISoldierIntroCinematic IntroCinematic;
	if (ScreenStack.IsNotInStack(class'UISoldierIntroCinematic'))
	{
		IntroCinematic = Spawn(class'UISoldierIntroCinematic', self);
		IntroCinematic.StartEventBase = string(StartEventName);
		IntroCinematic.FinishedEventName = StopEventName;
		IntroCinematic.InitCinematic('', SoldierRef);
		ScreenStack.Push(IntroCinematic);
	}
}

function UIArmory_MainMenu(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false)
{
	if(ScreenStack.IsNotInStack(class'UIArmory_MainMenu'))
		UIArmory_MainMenu(ScreenStack.Push(Spawn(class'UIArmory_MainMenu', self), Get3DMovie())).InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant);
}

function UIArmory_Loadout(StateObjectReference UnitRef, optional array<EInventorySlot> CannotEditSlots)
{
	local UIArmory_Loadout ArmoryScreen;

	if (ScreenStack.IsNotInStack(class'UIArmory_Loadout'))
	{
		ArmoryScreen = UIArmory_Loadout(ScreenStack.Push(Spawn(class'UIArmory_Loadout', self), Get3DMovie()));
		ArmoryScreen.CannotEditSlotsList = CannotEditSlots;
		ArmoryScreen.InitArmory(UnitRef);
	}
}

function UIArmory_Promotion(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	local XComGameState_Unit Unit;
	local int PreviousRank;
	local bool bValidRankUp;

	if (ScreenStack.IsNotInStack(class'UIArmory_Promotion'))
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		PreviousRank = Unit.GetSoldierRank();
		bValidRankUp = false;

		DoPromotionSequence(UnitRef, bInstantTransition);

		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

		// Check for rank up to Sergeant or Major
		bValidRankUp = (PreviousRank < 3 && Unit.GetSoldierRank() >= 3) || (PreviousRank < 6 && Unit.GetSoldierRank() >= 6);
		if (!Unit.bCaptured && Unit.IsAlive() && bValidRankUp)
		{
			`HQPRES.GetPhotoboothAutoGen().AddPromotedSoldier(Unit.GetReference());
			`HQPRES.GetPhotoboothAutoGen().RequestPhotos();
		}
	}
}

function UIArmory_Photobooth UIArmory_Photobooth(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	local XComGameState NewGameState;
	local UIArmory_Photobooth ArmoryScreen;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: View Photobooth");
	`XEVENTMGR.TriggerEvent('OnViewPhotobooth', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if (ScreenStack.IsNotInStack(class'UIArmory_Photobooth'))
	{
		ArmoryScreen = UIArmory_Photobooth(ScreenStack.Push(Spawn(class'UIArmory_Photobooth', self)));
		ArmoryScreen.InitPropaganda(UnitRef);
	}
	return ArmoryScreen;
}

function PhotoboothReview()
{
	if (ScreenStack.IsNotInStack(class'UIPhotoboothReview'))
	{
		UIPhotoboothReview(ScreenStack.Push(Spawn(class'UIPhotoboothReview', self)));
	}
}

private function DoPromotionSequence(StateObjectReference UnitRef, bool bInstantTransition)
{
	local XComGameState_Unit UnitState;
	local name SoldierClassName;

	SoldierClassName = class'X2StrategyGameRulesetDataStructures'.static.PromoteSoldier(UnitRef);
	if (SoldierClassName == '')
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		SoldierClassName = UnitState.GetSoldierClassTemplate().DataName;
	}
	
	// The ShowPromotionUI will get triggered at the end of the class movie if it plays, or...
	if (!class'X2StrategyGameRulesetDataStructures'.static.ShowClassMovie(SoldierClassName, UnitRef))
	{
		// ...this wasn't the first time we saw this unit's new class so just show the UI
		ShowPromotionUI(UnitRef, bInstantTransition);
	}
}

function ShowPromotionUI(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	local UIArmory_Promotion PromotionUI;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if (UnitState.IsResistanceHero() || ScreenStack.IsInStack(class'UIFacility_TrainingCenter'))
		PromotionUI = UIArmory_PromotionHero(ScreenStack.Push(Spawn(class'UIArmory_PromotionHero', self), Get3DMovie()));
	else if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
		PromotionUI = UIArmory_PromotionPsiOp(ScreenStack.Push(Spawn(class'UIArmory_PromotionPsiOp', self), Get3DMovie()));
	else
		PromotionUI = UIArmory_Promotion(ScreenStack.Push(Spawn(class'UIArmory_Promotion', self), Get3DMovie()));
	
	PromotionUI.InitPromotion(UnitRef, bInstantTransition);
}

function UIAbilityPopup(X2AbilityTemplate AbilityTemplate, StateObjectReference UnitRef)
{
	local UIAbilityPopup AbilityPopup;

	if (ScreenStack.IsNotInStack(class'UIAbilityPopup'))
	{
		AbilityPopup = Spawn(class'UIAbilityPopup', self);
		AbilityPopup.UnitRef = UnitRef;
		ScreenStack.Push(AbilityPopup);
		AbilityPopup.InitAbilityPopup(AbilityTemplate);
	}
}

function UIArmory_Implants(StateObjectReference UnitRef)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: View PCS");
	`XEVENTMGR.TriggerEvent('OnViewPCS', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if(ScreenStack.IsNotInStack(class'UIArmory_Implants'))
		UIArmory_Implants(ScreenStack.Push(Spawn(class'UIArmory_Implants', self), Get3DMovie())).InitImplants(UnitRef);
}

function UIArmory_WeaponUpgrade(StateObjectReference UnitOrWeaponRef)
{
	if(ScreenStack.IsNotInStack(class'UIArmory_WeaponUpgrade'))
		UIArmory_WeaponUpgrade(ScreenStack.Push(Spawn(class'UIArmory_WeaponUpgrade', self), Get3DMovie())).InitArmory(UnitOrWeaponRef);
}

reliable client function UIArmory_WeaponTrait(StateObjectReference UnitOrWeaponRef,
											  string _Title, 
											  array<string> _Data, 
											  delegate<UIArmory_WeaponTrait.OnItemSelectedCallback> _onSelectionChanged,
											  delegate<UIArmory_WeaponTrait.OnItemSelectedCallback> _onItemClicked,
											  optional delegate<UICustomize.IsSoldierEligible> _eligibilityCheck,
											  optional int startingIndex = -1,
											  optional string _ConfirmButtonLabel,
											  optional delegate<UIArmory_WeaponTrait.OnItemSelectedCallback> _onConfirmButtonClicked,
											  optional bool _bAllowedToCycleSoldiers = true)
{
	local UIArmory_WeaponTrait WeaponTraitScreen; 

	if(ScreenStack.IsNotInStack(class'UIArmory_WeaponTrait'))
	{
		WeaponTraitScreen = UIArmory_WeaponTrait(ScreenStack.Push(Spawn(class'UIArmory_WeaponTrait', self), Get3DMovie()));
		WeaponTraitScreen.bAllowedToCycleSoldiers = _bAllowedToCycleSoldiers; //Set this before init to allow nav help setup to use this value 
		WeaponTraitScreen.InitArmory(UnitOrWeaponRef);
		WeaponTraitScreen.UpdateTrait(_Title, _Data, _onSelectionChanged, _onItemClicked, _eligibilityCheck, startingIndex, _ConfirmButtonLabel, _onConfirmButtonClicked);
	}
}

function UISoldierBonds(StateObjectReference UnitRef, optional bool bSquadOnly)
{
	if (ScreenStack.IsNotInStack(class'UISoldierBondScreen'))
	{
		TempScreen = Spawn(class'UISoldierBondScreen', self);
		UISoldierBondScreen(TempScreen).UnitRef = UnitRef;
		UISoldierBondScreen(TempScreen).bSquadOnly = bSquadOnly;
		if( bSquadOnly ) 
			ScreenStack.Push(TempScreen);
		else
			ScreenStack.Push(TempScreen, Get3DMovie());
	}

	// Queue the Compatibility tutorial popup if it hasn't already been seen
	UISoldierCompatibilityIntro();
}

simulated function UISoldierBondAlertCallback(Name eAction, out DynamicPropertySet PropertySet, optional bool bInstant)
{
	local StateObjectReference UnitRef1, UnitRef2;
	local UISoldierBondAlert kScreen;
	local XComGameState_HeadquartersRoom RoomState1, RoomState2, RoomToUse;
	local Vector ForceLocation;
	local Rotator ForceRotation;
	local bool bSameRoom, bBothPawnsExist;
	local XGBaseCrewMgr CrewMgr;
	local XComUnitPawn Pawn1, Pawn2;
	local Vector Pawn1Loc, Pawn2Loc;

	UnitRef1.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'UnitRef1');
	UnitRef2.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'UnitRef2');

	CrewMgr = `GAME.GetGeoscape().m_kBase.m_kCrewMgr;
	RoomState1 = CrewMgr.GetRoomFromUnit(UnitRef1);
	RoomState2 = CrewMgr.GetRoomFromUnit(UnitRef2);
	Pawn1 = CrewMgr.GetPawnForUnit(UnitRef1);
	Pawn2 = CrewMgr.GetPawnForUnit(UnitRef2);
	bSameRoom = (RoomState1 != none && RoomState2 != none && RoomState1.ObjectID == RoomState2.ObjectID);
	bBothPawnsExist = (Pawn1 != none && Pawn2 != none);

	if(bSameRoom && bBothPawnsExist)
	{
		Pawn1Loc = Pawn1.GetHeadLocation();
		Pawn2Loc = Pawn2.GetHeadLocation();

		ForceLocation.X = (Pawn1Loc.X + Pawn2Loc.X) / 2.0f;
		ForceLocation.Y = (Pawn1Loc.Y + Pawn2Loc.Y) / 2.0f;
		ForceLocation.Z = (Pawn1Loc.Z + Pawn2Loc.Z) / 2.0f;
		RoomToUse = RoomState1;
	
		ForceLocation.X += 50;
		ForceLocation.Y -= 300;
		ForceRotation.Yaw = 16384;
		CAMLookAtRoom(RoomToUse, `HQINTERPTIME, ForceLocation, ForceRotation);
	}

	kScreen = Spawn(class'UISoldierBondAlert', self);
	kScreen.UnitRef1 = UnitRef1;
	kScreen.UnitRef2 = UnitRef2;
	ScreenStack.Push(kScreen);
}

function UISoldierBondAlert(StateObjectReference UnitRef1, StateObjectReference UnitRef2, optional XComGameState NewGameState)
{
	local DynamicPropertySet PropertySet;

	if( ScreenStack.IsNotInStack(class'UISoldierBondAlert') )
	{
		BuildUIScreen(PropertySet, 'SoldierBondAlert', UISoldierBondAlertCallback, true );
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef1', UnitRef1.ObjectID);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef2', UnitRef2.ObjectID);
		QueueDynamicPopup(PropertySet, NewGameState);
	}
}

function UISoldierBondConfirm(XComGameState_Unit UnitRef1, XComGameState_Unit UnitRef2, optional XComGameState_StaffSlot SlotState)
{
	if (ScreenStack.IsNotInStack(class'UISoldierBondConfirmScreen'))
	{
		TempScreen = Spawn(class'UISoldierBondConfirmScreen', self);
		UISoldierBondConfirmScreen(TempScreen).InitBondConfirm(UnitRef1, UnitRef2, SlotState);
		ScreenStack.Push(TempScreen);
	}
}

function UINegativeTraitAlert(XComGameState NewGameState, XComGameState_Unit UnitState, Name TraitTemplateName)
{
	local DynamicPropertySet PropertySet;

	UnitState.AlertTraits.RemoveItem(TraitTemplateName);
	UnitState.WorldMessageTraits.RemoveItem(TraitTemplateName);

	BuildUIAlert(PropertySet, 'eAlert_NegativeTraitAcquired', None, 'OnNegativeTraitAcquired', "Geoscape_CrewMemberLevelledUp", false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'PrimaryTraitTemplate', TraitTemplateName);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'SecondaryTraitTemplate', '');
	QueueDynamicPopup(PropertySet, NewGameState);
}

//----------------------------------------------------
// FACILITIES
//----------------------------------------------------

function UIRoom(optional StateObjectReference Room, optional bool bInstant = false)
{
	if (ScreenStack.IsNotInStack(class'UIRoom'))
	{
		TempScreen = Spawn(class'UIRoom', self);
		UIRoom(TempScreen).RoomRef = Room;
		UIRoom(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen);
	}
}

function UIFacility(class<UIFacility> UIClass, optional StateObjectReference Facility, optional bool bInstant = false)
{
	if(ScreenStack.IsNotInStack(UIClass))
	{
		TempScreen = Spawn(UIClass, self);
		UIFacility(TempScreen).FacilityRef = Facility;
		UIFacility(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen);
	}
}

function UIChooseResearch(optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(XComHQ.HasActiveShadowProject())
	{
		ShadowProjectInProgressPopup();
	}
	else if(ScreenStack.IsNotInStack(class'UIChooseResearch'))
	{
		TempScreen = Spawn(class'UIChooseResearch', self);
		UIChooseResearch(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIChooseShadowProject(optional bool bInstant = false)
{
	if(ScreenStack.IsNotInStack(class'UIChooseResearch'))
	{
		TempScreen = Spawn(class'UIChooseResearch', self);
		UIChooseResearch(TempScreen).SetShadowChamber();
		UIChooseResearch(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIChooseProject()
{
	if (ScreenStack.IsNotInStack(class'UIChooseProject'))
	{
		TempScreen = Spawn(class'UIChooseProject', self);
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIChooseClass(StateObjectReference UnitRef)
{
	if (ScreenStack.IsNotInStack(class'UIChooseClass'))
	{
		TempScreen = Spawn(class'UIChooseClass', self);
		UIChooseClass(TempScreen).m_UnitRef = UnitRef;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIChoosePsiAbility(StateObjectReference UnitRef, StateObjectReference StaffSlotRef)
{
	if (ScreenStack.IsNotInStack(class'UIChoosePsiAbility'))
	{
		TempScreen = Spawn(class'UIChoosePsiAbility', self);
		UIChoosePsiAbility(TempScreen).m_UnitRef = UnitRef;
		UIChoosePsiAbility(TempScreen).m_StaffSlotRef = StaffSlotRef;
		ScreenStack.Push(TempScreen);
	}
}

function UIOfficerTrainingSchool(optional StateObjectReference Facility)
{
	if(ScreenStack.IsNotInStack(class'UIOfficerTrainingSchool'))
	{
		TempScreen = Spawn(class'UIOfficerTrainingSchool', self);
		UIOfficerTrainingSchool(TempScreen).FacilityRef = Facility;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIBuildFacilities(optional bool bInstant = false)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entered Build Facilities");
	`XEVENTMGR.TriggerEvent('OnEnteredBuildFacilities', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if( ScreenStack.IsNotInStack(class'UIBuildFacilities') )
	{
		TempScreen = Spawn(class'UIBuildFacilities', self);
		UIBuildFacilities(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen);
	}
}

//----------------------------------------------------------------
//-------------------- RESEARCH ----------------------------------
//----------------------------------------------------------------
simulated static function PauseShadowProjectPopup()
{
	local TDialogueBoxData kDialogData;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGParamTag LocTag;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = XComHQ.GetCurrentShadowTech().GetDisplayName();

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = default.m_strPauseShadowProjectLabel;
	kDialogData.strText = `XEXPAND.ExpandString(default.m_strPauseShadowProjectText);
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

	kDialogData.fnPreCloseCallback = PauseShadowProjectPopupCallback;
	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated function PauseShadowProjectPopupCallback(Name eAction)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIFacility_ShadowChamber ShadowChamber;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if(eAction == 'eUIAction_Accept')
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pause Shadow Project");
		XComHQ.PauseShadowProject(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		XComHQ.HandlePowerOrStaffingChange();
		TempScreen = ScreenStack.GetCurrentScreen();

		ShadowChamber = UIFacility_ShadowChamber(TempScreen);
		if(ShadowChamber != none)
		{
			m_kAvengerHUD.Shortcuts.UpdateCategories();
			m_kAvengerHUD.Shortcuts.SelectCategoryForFacilityScreen(ShadowChamber, true);
			ShadowChamber.UpdateData();
			ShadowChamber.RealizeNavHelp();
		}
	}
}

simulated public function ShadowProjectInProgressPopup()
{
	local TDialogueBoxData kDialogData;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGParamTag LocTag;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = XComHQ.GetCurrentShadowTech().GetDisplayName();

	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strShadowProjectInProgressLabel;
	kDialogData.strText = `XEXPAND.ExpandString(m_strShadowProjectInProgressText);
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated public function RoomLockedPopup()
{
	local TDialogueBoxData kDialogData;
	
	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strRoomLockedLabel;
	kDialogData.strText = m_strRoomLockedText;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	`HQPRES.UIRaiseDialog(kDialogData);
}

function UIResearchUnlocked(array<StateObjectReference> UnlockedTechs)
{
	local UIResearchUnlocked ResearchUnlocked;

	if(ScreenStack.IsNotInStack(class'UIResearchUnlocked'))
	{
		ResearchUnlocked = Spawn(class'UIResearchUnlocked', self);
		ScreenStack.Push(ResearchUnlocked, Get3DMovie());
		ResearchUnlocked.PopulateData(UnlockedTechs);
	}
}


simulated function UIResearchComplete(StateObjectReference TechRef)
{
	local XComGameStateHistory History;
	//local DynamicPropertySet PropertySet;
	local XComGameState_Tech TechState;
	local X2TechTemplate TechTemplate;
	local DynamicPropertySet PropertySet;
	local name EventToTrigger;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
	TechTemplate = TechState.GetMyTemplate();

	if(TechTemplate.bShadowProject || TechTemplate.bJumpToLabs)
	{
		// Objectives handle the jump to facility after cinematics
		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
		`GAME.GetGeoscape().Pause();
	}
	else
	{
		if (TechState.bBreakthrough)
			EventToTrigger = 'BreakthroughComplete';
		else if (TechState.bInspired)
			EventToTrigger = 'InspirationComplete';
		else
			EventToTrigger = 'ResearchCompletePopup';

		BuildUIAlert(PropertySet, 'eAlert_ResearchComplete', ResearchCompletePopupCB, EventToTrigger, "Geoscape_ResearchComplete", true);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechRef.ObjectID);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function ResearchCompletePopupCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	if (eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('PowerCore');

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();

		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference(), true);
	}
	else if( eAction == 'eUIAction_Cancel' )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Research Complete Popup Closed");
		`XEVENTMGR.TriggerEvent('OnResearchCompletePopupClosed', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

simulated function ResearchReportPopup(StateObjectReference TechRef, optional bool bInstantInterp = false)
{
	local UIResearchReport ResearchReport;
	if(ScreenStack.IsNotInStack(class'UIResearchReport'))
	{
		ResearchReport = Spawn(class'UIResearchReport', self);
		ResearchReport.bInstantInterp = bInstantInterp;
		ScreenStack.Push(ResearchReport, Get3DMovie());
		ResearchReport.InitResearchReport(TechRef);
	}
}

function UIRewardsRecap(optional bool bForce = false)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Reward Recap Event Hook");
	`XEVENTMGR.TriggerEvent('MissionRewardRecap', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if(bForce || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M1_L1_RevealBlacksiteObjective') != eObjectiveState_InProgress)
	{
		if(ScreenStack.IsNotInStack(class'UIRewardsRecap'))
		{
			ScreenStack.Push(Spawn(class'UIRewardsRecap', self), Get3DMovie());
		}
	}
}

function UIResearchArchives()
{
	if(ScreenStack.IsNotInStack(class'UIResearchArchives'))
		ScreenStack.Push(Spawn(class'UIResearchArchives', self) , Get3DMovie());
}

function UIShadowChamberArchives()
{
	if( ScreenStack.IsNotInStack(class'UIShadowChamberArchives') )
		ScreenStack.Push(Spawn(class'UIShadowChamberArchives', self) /*, Get3DMovie()*/);
}

simulated function ShadowChamberResearchReportPopup(StateObjectReference TechRef)
{
	local UIResearchReport ResearchReport;
	if( ScreenStack.IsNotInStack(class'UIResearchReport') )
	{
		ResearchReport = Spawn(class'UIResearchReport', self);
		ScreenStack.Push(ResearchReport);
		ResearchReport.InitResearchReport(TechRef);
	}
}

function UISchematicArchives()
{
	if(ScreenStack.IsNotInStack(class'UISchematicArchives'))
		ScreenStack.Push(Spawn(class'UISchematicArchives', self) , Get3DMovie());
}

function UIBuildItem()
{
	if(ScreenStack.IsNotInStack(class'UIInventory_BuildItems'))
		ScreenStack.Push(Spawn( class'UIInventory_BuildItems', self), Get3DMovie());
}

function UIChooseFacility(StateObjectReference RoomRef)
{
	if(ScreenStack.IsNotInStack(class'UIChooseFacility'))
	{
		TempScreen = Spawn(class'UIChooseFacility', self);
		UIChooseFacility(TempScreen).m_RoomRef = RoomRef;
		ScreenStack.Push(TempScreen);
	}
}

function UIFacilityUpgrade(StateObjectReference FacilityRef)
{
	local UIChooseUpgrade ChooseUpgrade;

	if(ScreenStack.IsNotInStack(class'UIChooseUpgrade'))
	{
		ChooseUpgrade = Spawn(class'UIChooseUpgrade', self);
		ChooseUpgrade.SetFacility(FacilityRef);
		ScreenStack.Push(ChooseUpgrade);
	}
}

simulated function UIViewObjectives(optional float OverrideInterpTime = -1)
{
	if(ScreenStack.IsNotInStack(class'UIViewObjectives'))
	{
		TempScreen = Spawn(class'UIViewObjectives', self);
		UIViewObjectives(TempScreen).OverrideInterpTime = OverrideInterpTime;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

simulated function HotlinkToViewObjectives()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local UIFacility_CIC CurrentCICScreen;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('CommandersQuarters');

	if( `GAME.GetGeoscape().IsScanning() )
		StrategyMap2D.ToggleScan();

	`HQPRES.ClearUIToHUD();

	PushCameraInterpTime(0.0f);

	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference(), true);

	// get to view objectives screen, once we're on the CIC  screen. 
	CurrentCICScreen = UIFacility_CIC(ScreenStack.GetCurrentScreen());
	if( CurrentCICScreen != none )
	{
		CurrentCICScreen.ViewObjectives();
	}

	PopCameraInterpTime();
}


simulated function HotlinkToViewDarkEvents(optional bool bShowActiveDarkEvents = false)
{
	UIAdventOperations(false, bShowActiveDarkEvents);
}


//----------------------------------------------------
// PRE-MISSION SCREENS
//----------------------------------------------------
function UISquadSelect(optional bool bNoCancel=false)
{
	local UISquadSelect SquadSelectScreen;

	if(ScreenStack.IsNotInStack(class'UISquadSelect'))
	{
		SquadSelectScreen = Spawn( class'UISquadSelect', self);
		SquadSelectScreen.bNoCancel = bNoCancel;
		ScreenStack.Push(SquadSelectScreen);
	}
}

//----------------------------------------------------
// POST-MISSION SCREENS
//----------------------------------------------------
function UIMissionSummary(TSimCombatSummaryData SummaryData) // for SimCombat only
{
	if(ScreenStack.IsNotInStack(class'UIMissionSummary'))
	{
		ScreenStack.Push( Spawn( class'UIMissionSummary', self ) );
		UIMissionSummary(ScreenStack.GetScreen(class'UIMissionSummary')).SimCombatData = SummaryData;
	}
}

function UIAfterAction(optional bool bIsSimCombat)
{
	if(ScreenStack.IsNotInStack(class'UIAfterAction'))
	{
		ScreenStack.Push( Spawn( class'UIAfterAction', self ) );
		
		// TODO @rmcfall: Remove this once intro sequence is fixed for SimCombat
		if(bIsSimCombat)
			UIAfterAction(ScreenStack.GetScreen(class'UIAfterAction')).Show();

		`XSTRATEGYSOUNDMGR.PlayAfterActionMusic();
	}
}

function UIInventory_LootRecovered()
{
	if(ScreenStack.IsNotInStack(class'UIInventory_LootRecovered'))
	{
		ScreenStack.Push( Spawn( class'UIInventory_LootRecovered', self ), Get3DMovie() );
	}
}

//----------------------------------------------------
// AVENGER SCREENS
//----------------------------------------------------
function UIInventory_Storage()
{
	if(ScreenStack.IsNotInStack(class'UIInventory_Storage'))
		ScreenStack.Push( Spawn(class'UIInventory_Storage', self), Get3DMovie() );
}

function UIInventory_Implants()
{
	if(ScreenStack.IsNotInStack(class'UIInventory_Implants'))
		ScreenStack.Push( Spawn(class'UIInventory_Implants', self), Get3DMovie() );
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                   BEGIN DEPRECATED UI (TODO: CLEANUP)
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//----------------------------------------------------
simulated function UIStrategyShell()
{
	if(ScreenStack.IsNotInStack(class'UIShellStrategy'))
		ScreenStack.Push( Spawn( class'UIShellStrategy', self ) );
}


simulated function RemoveUIDropshipBriefingHUD()
{
	ScreenStack.PopFirstInstanceOfClass( class'UIDropshipHUD' );
}

//-------------------------------------------------------------------

simulated function UIEndGame()
{
	XComHeadquartersGame(WorldInfo.Game).Uninit();
}

//----------------------------------------------------
simulated function UIFocusOnEntity(XComGameState_GeoscapeEntity Entity, optional float fZoom = 1.0f, optional float fInterpTime = 0.75f)
{
	CAMLookAtEarth(Entity.Get2DLocation(), fZoom, fInterpTime);
}

simulated function UISkyrangerArrives()
{
	local UISkyrangerArrives kScreen;

	kScreen = Spawn(class'UISkyrangerArrives', self);
	ScreenStack.Push(kScreen);
}

simulated function UIUFOAttack(XComGameState_MissionSite MissionState)
{
	local UIUFOAttack kScreen;

	kScreen = Spawn(class'UIUFOAttack', self);
	kScreen.MissionRef = MissionState.GetReference();
	ScreenStack.Push(kScreen);
}

//-------------------------------------------------------------------
simulated function UIResistance(XComGameState_WorldRegion RegionState)
{
	local UIResistance kScreen;

	kScreen = Spawn(class'UIResistance', self);
	kScreen.RegionRef = RegionState.GetReference();
	ScreenStack.Push(kScreen);
}
simulated function UIMonthlyReport()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_CouncilComm', CouncilReportAlertCB, 'OnMonthlyReportAlert', "Geoscape_CouncilMonthlySummaryPopup");
	QueueDynamicPopup(PropertySet);
}
simulated function UIFortressReveal()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_CouncilComm', FortressRevealAlertCB, 'OnFortressRevealAlert', "Geoscape_CouncilMonthlySummaryPopup");
	QueueDynamicPopup(PropertySet);
}

simulated function UIResistanceReport_ChosenEvents(optional bool bSimpleView = false)
{
	local XComGameState NewGameState;
	local UIResistanceReport_ChosenEvents kScreen;

	//Check to not allow you in to this screen multiple times. 
	if (ScreenStack.GetScreen(class'UIResistanceReport_ChosenEvents') != none)
		return;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: View Chosen Events");
	`XEVENTMGR.TriggerEvent('OnViewChosenEvents', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	kScreen = Spawn(class'UIResistanceReport_ChosenEvents', self);
	kScreen.bSimpleView = bSimpleView;
	ScreenStack.Push(kScreen/*, Get3DMovie()*/);
}

simulated function UIResistanceReport_FactionEvents()
{
	local UIResistanceReport_FactionEvents kScreen;

	kScreen = Spawn(class'UIResistanceReport_FactionEvents', self);
	ScreenStack.Push(kScreen/*, Get3DMovie()*/);
}

simulated function UIAdventOperations(bool bResistanceReport, optional bool bShowActiveEvents = false)
{
	local UIAdventOperations kScreen;
	local XComGameState NewGameState;

	//Check to not allow you in to this screen multiple times. 
	if( ScreenStack.GetScreen(class'UIAdventOperations') != none ) 
		return; 

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: View Dark Events");
	`XEVENTMGR.TriggerEvent('OnViewDarkEvents', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	kScreen = Spawn(class'UIAdventOperations', self);
	kScreen.bResistanceReport = bResistanceReport;
	kScreen.bShowActiveEvents = bShowActiveEvents;
	ScreenStack.Push(kScreen/*, Get3DMovie()*/);
}
simulated function UIResistanceOps(StateObjectReference RegionRef)
{
	local UIResistanceOps kScreen;

	kScreen = Spawn(class'UIResistanceOps', self);
	kScreen.RegionRef = RegionRef;
	ScreenStack.Push(kScreen);
}
simulated function UIResistanceGoods()
{
	local UIResistanceGoods kScreen;

	kScreen = Spawn(class'UIResistanceGoods', self);
	ScreenStack.Push(kScreen);
}

simulated function UIBlackMarketAppearedAlert()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_BlackMarketAvailable', BMAppearedCB, '', "Geoscape_Black_Market_Found");
	QueueDynamicPopup(PropertySet);
}
simulated function UIBlackMarketAlert()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_BlackMarket', BMAlertCB, '', "Geoscape_POIReached");
	QueueDynamicPopup(PropertySet);
}
simulated function UIBlackMarket()
{
	local UIBlackMarket kScreen;

	kScreen = Spawn(class'UIBlackMarket', self);
	ScreenStack.Push(kScreen);
}
simulated function UIBlackMarketBuy()
{
	local UIBlackMarket_Buy kScreen;

	kScreen = Spawn(class'UIBlackMarket_Buy', self);
	ScreenStack.Push(kScreen);
}
simulated function UIBlackMarketSell()
{
	local XComGameStateHistory History;
	local UIBlackMarket_Sell kScreen;
	local XComGameState_BlackMarket BlackMarketState;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));

	kScreen = Spawn(class'UIBlackMarket_Sell', self);
	kScreen.BlackMarketReference = BlackMarketState.GetReference();
	ScreenStack.Push(kScreen);
}

simulated function UITimeSensitiveMission(XComGameState_MissionSite MissionState)
{
	//local DynamicPropertySet PropertySet;
	local XComGameState NewGameState;
	local DynamicPropertySet PropertySet;

	// Trigger the popup event and also save this mission as having seen the skip warning popup
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Time Sensitive Mission");
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	MissionState.bHasSeenSkipPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	BuildUIAlert(PropertySet, 'eAlert_TimeSensitiveMission', TimeSensitiveMissionCB, 'TimeSensitiveMission', "Geoscape_Time_Sensitive_Mission");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function TimeSensitiveMissionCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{	
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	if (eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'MissionRef')));
		OnMissionSelected(MissionState);

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
	else if( eAction == 'eUIAction_Cancel' )
	{
		StrategyMap2D.ToggleScan(true); // Force the scan to start
	}
}

simulated function UIMissionExpired(XComGameState_MissionSite MissionState)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_MissionExpired', None, '', "Geoscape_Mission_Expired");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function OnMissionSelected(XComGameState_MissionSite MissionSite, optional bool bInstant = false)
{
	local DynamicPropertySet PropertySet;
	// TODO: Associate ui with mission type in template

	if( MissionSite.Source == 'MissionSource_GuerillaOp' )
	{
		GOpsAlertCB('eUIAction_Accept', PropertySet, bInstant);

		// Guerilla ops have 2 or 3 choices, open up at the correct mission
		UIMission(ScreenStack.GetCurrentScreen()).SelectMission(MissionSite);
	}
	else if( MissionSite.Source == 'MissionSource_Retaliation' )
	{
		RetaliationAlertCB('eUIAction_Accept', PropertySet, bInstant);
	}
	else if( MissionSite.Source == 'MissionSource_Council' )
	{
		CouncilMissionAlertCB('eUIAction_Accept', PropertySet, bInstant);
	}
	else if (MissionSite.Source == 'MissionSource_SupplyRaid')
	{
		SupplyRaidAlertCB('eUIAction_Accept', PropertySet, bInstant);
	}
	else if (MissionSite.Source == 'MissionSource_LandedUFO')
	{
		LandedUFOAlertCB('eUIAction_Accept', PropertySet, bInstant);
	}
	else if( MissionSite.Source == 'MissionSource_AlienNetwork' )
	{
		UIMission_AlienFacility(MissionSite, bInstant);
	}
	else if ( MissionSite.Source == 'MissionSource_Broadcast' )
	{
		GPIntelOptionsCB('eUIAction_Accept', MissionSite.Source, PropertySet, bInstant);
	}
	else if( MissionSite.GetMissionSource().bGoldenPath )
	{
		GoldenPathCB('eUIAction_Accept', MissionSite.Source, PropertySet, bInstant );
	}
	else if (MissionSite.Source == 'MissionSource_ResistanceOp')
	{
		ResistanceOpsAlertCB('eUIAction_Accept', PropertySet, bInstant);
	}
	else if (MissionSite.Source == 'MissionSource_RescueSoldier')
	{
		RescueSoldierAlertCB('eUIAction_Accept', PropertySet, bInstant);
	}
	else if (MissionSite.Source == 'MissionSource_ChosenStronghold')
	{
		UIMission_ChosenStronghold(MissionSite, bInstant);
	}
	else if (MissionSite.Source == 'MissionSource_LostAndAbandoned')
	{
		LostAndAbandonedAlertCB('eUIAction_Accept', PropertySet, bInstant);
	}
}
simulated function UIGOpsMission(optional bool bInstant = false)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_GOps', GOpsAlertCB, 'OnGOpsPopup', "GeoscapeFanfares_GuerillaOps");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}
simulated function UICouncilMission(optional bool bInstant = false)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_CouncilMission', CouncilMissionAlertCB, 'OnCouncilPopup', "Geoscape_NewResistOpsMissions");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}
simulated function UIRetaliationMission(optional bool bInstant = false)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_Retaliation', RetaliationAlertCB, 'OnRetaliationPopup', "GeoscapeFanfares_Retaliation");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}
simulated function UISupplyRaidMission(optional bool bInstant = false)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_SupplyRaid', SupplyRaidAlertCB, 'OnSupplyRaidPopup', "Geoscape_Supply_Raid_Popup");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}
simulated function UILandedUFOMission(optional bool bInstant = false)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_LandedUFO', LandedUFOAlertCB, 'OnLandedUFOPopup', "Geoscape_UFO_Landed");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}
simulated function BMAppearedCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_BlackMarket BlackMarketState;
		
	if( eAction == 'eUIAction_Accept' )
	{
		BlackMarketState = XComGameState_BlackMarket(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));		
		BlackMarketState.AttemptSelectionCheckInterruption();

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}
simulated function BMAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	if (eAction == 'eUIAction_Accept')
	{
		UIBlackMarket(); // Open the Black Market screen since the scan just finished

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}
simulated function GOpsAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_GOps kScreen;

	if( eAction == 'eUIAction_Accept' )
	{
		if(!ScreenStack.GetCurrentScreen().IsA('UIMission_GOps'))
		{
			kScreen = Spawn(class'UIMission_GOps', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}
simulated function CouncilMissionAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_Council kScreen;

	if( eAction == 'eUIAction_Accept' )
	{
		if(!ScreenStack.GetCurrentScreen().IsA('UIMission_Council'))
		{
			kScreen = Spawn(class'UIMission_Council', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}

simulated function CouncilReportAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIResistanceReport kScreen;

	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIResistanceReport'))
		{
			kScreen = Spawn(class'UIResistanceReport', self);
			ScreenStack.Push(kScreen, Get3DMovie());
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function FortressRevealAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;

	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Avatar Project Reveal");
	`XEVENTMGR.TriggerEvent('AvatarProjectRevealed', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
}

simulated function RetaliationAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_Retaliation kScreen;

	if( eAction == 'eUIAction_Accept' )
	{
		if(!ScreenStack.GetCurrentScreen().IsA('UIMission_Retaliation'))
		{
			kScreen = Spawn(class'UIMission_Retaliation', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}

simulated function SupplyRaidAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_SupplyRaid kScreen;

	if (eAction == 'eUIAction_Accept')
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_SupplyRaid'))
		{
			kScreen = Spawn(class'UIMission_SupplyRaid', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function LandedUFOAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_LandedUFO kScreen;

	if (eAction == 'eUIAction_Accept')
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_LandedUFO'))
		{
			kScreen = Spawn(class'UIMission_LandedUFO', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIMission_AlienFacility(XComGameState_MissionSite Mission, optional bool bInstant = false)
{
	local UIMission_AlienFacility kScreen;

	// Show the alien facility
	if(!ScreenStack.GetCurrentScreen().IsA('UIMission_AlienFacility'))
	{
		kScreen = Spawn(class'UIMission_AlienFacility', self);
		kScreen.MissionRef = Mission.GetReference();
		kScreen.bInstantInterp = bInstant;
		ScreenStack.Push(kScreen);
	}

	if( `GAME.GetGeoscape().IsScanning() )
	{
		StrategyMap2D.ToggleScan();
	}
}

simulated static function DoomAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_MissionSite MissionSite;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	if( eAction == 'eUIAction_Accept' )
	{
		MissionSite = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'MissionRef')));
		`HQPRES.UIMission_AlienFacility(MissionSite, bInstant);
	}

	// Always push any DLC specific alerts, doesn't matter if the player views the facility mission blades or not
	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPostFacilityDoomVisualization();
	}
}
	
simulated function GPIntelOptionsCB(Name eAction, name GPMissionType, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_GPIntelOptions kScreen;

	if (eAction == 'eUIAction_Accept')
	{
		// Show the Golden Path mission with intel options
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_GPIntelOptions'))
		{
			kScreen = Spawn(class'UIMission_GPIntelOptions', self);
			kScreen.bInstantInterp = bInstant;
			kScreen.GPMissionSource = GPMissionType;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function GoldenPathCB(Name eAction, name GPMissionType, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_GoldenPath kScreen;

	if( eAction == 'eUIAction_Accept' )
	{
		// Show the Golden Path mission
		if(!ScreenStack.GetCurrentScreen().IsA('UIMission_GoldenPath'))
		{
			kScreen = Spawn(class'UIMission_GoldenPath', self);
			kScreen.bInstantInterp = bInstant;
			kScreen.GPMissionSource = GPMissionType;
			ScreenStack.Push(kScreen);
		}

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIMakeContact(XComGameState_WorldRegion Region)
{
	local DynamicPropertySet PropertySet;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local Name EventToTrigger;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Making Contact Event");
	`XEVENTMGR.TriggerEvent('MakingContact', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if (!XComHQ.CanAffordAllStrategyCosts(Region.CalcContactCost(), Region.ContactCostScalars))
	{
		EventToTrigger = 'MakingContactNoIntel';
	}
	else
	{
		EventToTrigger = '';
	}
	
	BuildUIAlert(PropertySet, 'eAlert_Contact', Region.MakeContactCallback, EventToTrigger, "Geoscape_POIReveal");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'RegionRef', Region.ObjectID);
	QueueDynamicPopup(PropertySet);
}
simulated function UIBuildOutpost(XComGameState_WorldRegion Region)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_Outpost', Region.BuildOutpostCallback, '', "Geoscape_POIReveal");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'RegionRef', Region.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UIInstantResearchAvailable(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;
	local DynamicPropertySet PropertySet;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Instant Tech Available Popup Seen");
	TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechRef.ObjectID));
	TechState.bSeenInstantPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	BuildUIAlert(PropertySet, 'eAlert_InstantResearchAvailable', None, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UIBreakthroughResearchAvailable(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;
	local DynamicPropertySet PropertySet;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Breakthrough Tech Available Popup Seen");
	TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechRef.ObjectID));
	TechState.bSeenBreakthroughPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	BuildUIAlert(PropertySet, 'eAlert_BreakthroughResearchAvailable', None, 'OnBreakthroughTech', "ResearchBreakthrough", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UIBreakthroughResearchComplete(StateObjectReference TechRef)
{
	local DynamicPropertySet PropertySet;
	
	BuildUIAlert(PropertySet, 'eAlert_BreakthroughResearchComplete', None, '', "ResearchBreakthrough", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UIInspiredResearchAvailable(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;
	local DynamicPropertySet PropertySet;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Inspired Tech Available Popup Seen");
	TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechRef.ObjectID));
	TechState.bSeenInspiredPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	BuildUIAlert(PropertySet, 'eAlert_InspiredResearchAvailable', None, 'OnInspiredTech', "ResearchInspiration", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UIItemAvailable(X2ItemTemplate ItemTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ItemAvailable', None, '', "Geoscape_CrewMemberLevelledUp");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', ItemTemplate.DataName);
	QueueDynamicPopup(PropertySet);
}

simulated function UIItemReceived(X2ItemTemplate ItemTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ItemReceived', None, '', "Geoscape_ItemComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', ItemTemplate.DataName);
	QueueDynamicPopup(PropertySet);
}

simulated function UIProvingGroundItemReceived(X2ItemTemplate ItemTemplate, StateObjectReference TechRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ItemReceivedProvingGround', None, '', "Geoscape_ItemComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', ItemTemplate.DataName);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}


simulated function UIItemUpgraded(X2ItemTemplate ItemTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ItemUpgraded', None, '', "Geoscape_ItemComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', ItemTemplate.DataName);
	QueueDynamicPopup(PropertySet);
}


simulated function UIItemComplete(X2ItemTemplate Template)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ItemComplete', ItemCompleteCB, '', "Geoscape_ItemComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', Template.DataName);
	QueueDynamicPopup(PropertySet);
}

simulated function ItemCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	if (eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('Storage');

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();

		`HQPRES.ClearUIToHUD();
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
		//TODO: Need to figure out how to select build item here. -bsteiner 
	}
}

simulated function UIProvingGroundProjectAvailable(StateObjectReference TechRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ProvingGroundProjectAvailable', None, '', "Geoscape_CrewMemberLevelledUp");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}


simulated function UIProvingGroundProjectComplete(StateObjectReference TechRef)
{
	local DynamicPropertySet PropertySet;
			
	BuildUIAlert(PropertySet, 'eAlert_ProvingGroundProjectComplete', ProvingGroundProjectCompleteCB, '', "Geoscape_ProjectComplete", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TechRef', TechRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function ProvingGroundProjectCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Tech TechState;
	
	History = `XCOMHISTORY;
	
	if (eAction == 'eUIAction_Accept')
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('ProvingGround');

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();

		`HQPRES.ClearUIToHUD();
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference(), true);
	}
	else if( eAction == 'eUIAction_Cancel' )
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'TechRef')));
		TechState.DisplayTechCompletePopups();
	}
}

simulated function UIFacilityAvailable(X2FacilityTemplate FacilityTemplate, optional bool bImmediateDisplay = true)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_FacilityAvailable', None, 'FacilityAvailablePopup', "Geoscape_CrewMemberLevelledUp", bImmediateDisplay);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'FacilityTemplate', FacilityTemplate.DataName);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventDataTemplate', FacilityTemplate.DataName);
	QueueDynamicPopup(PropertySet);
}


simulated function UIFacilityComplete(StateObjectReference FacilityRef, StaffUnitInfo BuilderInfo)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_FacilityComplete', FacilityCompleteCB, 'FacilityCompletePopup', "Geoscape_FacilityComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStaffUnitInfoProperties(PropertySet.DynamicProperties, BuilderInfo);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FacilityRef', FacilityRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'EventDataRef', FacilityRef.ObjectID);
	QueueDynamicPopup(PropertySet);

	if (BuilderInfo.UnitRef.ObjectID != 0)
	{
		m_bRecentStaffAvailable = true;
	}
}

simulated function FacilityCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local StateObjectReference FacilityRef;

	if (eAction == 'eUIAction_Accept')
	{
		FacilityRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'FacilityRef');
		class'UIUtilities_Strategy'.static.SelectFacility(FacilityRef);
	}
}

simulated function UIUpgradeAvailable(X2FacilityUpgradeTemplate UpgradeTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_UpgradeAvailable', None, '', "Geoscape_CrewMemberLevelledUp");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'UpgradeTemplate', UpgradeTemplate.DataName);
	QueueDynamicPopup(PropertySet);
}


simulated function UIUpgradeComplete(X2FacilityUpgradeTemplate Template)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_UpgradeComplete', UpgradeCompleteCB, '', "Geoscape_FacilityComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'UpgradeTemplate', Template.DataName);
	QueueDynamicPopup(PropertySet);
}

simulated function UpgradeCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	if (eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('Storage');
		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();

		`HQPRES.ClearUIToHUD();
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
	}
}

simulated function UINewStaffAvailable(StateObjectReference UnitRef, optional bool bIgnoreRemove = false, optional bool bWoundRecovery = false, optional bool bImmediateDisplay = true)
{
	local XComGameState_Unit UnitState;
	local DynamicPropertySet PropertySet;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	BuildUIAlert(PropertySet, UnitState.IsEngineer() ? 'eAlert_NewStaffAvailable' : 'eAlert_NewStaffAvailableSmall', NewStaffAvailableCB, 'StaffAdded', "Geoscape_CrewMemberLevelledUp", bImmediateDisplay);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'EventDataRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'WoundRecovery', bWoundRecovery);
	QueueDynamicPopup(PropertySet);
			
	if (!bIgnoreRemove)
	{
		NewCrewMembers.RemoveItem(UnitRef);
	}

	m_bRecentStaffAvailable = true;
}

simulated function NewStaffAvailableCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_Unit UnitState;
	local XComGameState_ResistanceFaction FactionState;
	local name ClassName;
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef')));
	
	if (UnitState.IsSoldier())
	{
		ClassName = UnitState.GetSoldierClassTemplate().DataName;
		
		FactionState = UnitState.GetResistanceFaction();
		if (FactionState != none)
		{
			ClassName = FactionState.GetChampionClassName();
		}
		
		if (ClassName != '')
		{
			class'X2StrategyGameRulesetDataStructures'.static.ShowClassMovie(ClassName, UnitState.GetReference(), true);
		}
	}
}

simulated function UIStaffInfo(StateObjectReference UnitRef, optional bool bIgnoreRemove = false)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_StaffInfo', None, '', "");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'EventDataRef', UnitRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UIClearRoomComplete(StateObjectReference RoomRef, X2SpecialRoomFeatureTemplate Template, array<StaffUnitInfo> BuilderInfoList)
{
	local DynamicPropertySet PropertySet;
	local DynamicProperty ArrayProperty, InnerProperty;
	local int Index;

	BuildUIAlert(PropertySet, 'eAlert_ClearRoomComplete', ClearRoomCompleteCB, '', "Geoscape_FacilityComplete");

	ArrayProperty.Key = 'StaffUnitArray';

	for( Index = 0; Index < BuilderInfoList.Length; ++Index )
{
		InnerProperty.ValueArray.Length = 0;
		InnerProperty.Key = 'StaffUnitArrayInner';
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStaffUnitInfoProperties(InnerProperty.ValueArray, BuilderInfoList[Index]);
		ArrayProperty.ValueArray.AddItem(InnerProperty);
}

	PropertySet.DynamicProperties.AddItem(ArrayProperty);

	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'SpecialRoomFeatureTemplate', Template.DataName);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'RoomRef', RoomRef.ObjectID);
	QueueDynamicPopup(PropertySet);

	m_bRecentStaffAvailable = true;
}

simulated function ClearRoomCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersRoom Room;

	if (eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'RoomRef')));
		
		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();

		// If "View Room" is selected, return to the Facility Grid and select the room for facility construction
		`HQPRES.ClearUIToHUD();
		`HQPRES.CAMLookAtRoom(Room, 0);
		`HQPRES.UIChooseFacility(Room.GetReference());
	}
}

simulated function UIClassEarned(StateObjectReference UnitRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ClassEarned', TrainingCompleteCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UITrainingComplete(StateObjectReference UnitRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_TrainingComplete', TrainingCompleteCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function TrainingCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	
	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		// Flag the new class popup as having been seen
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Promotion Callback");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit',
																	  class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef')));
		UnitState.bNeedsNewClassPopup = false;
		`XEVENTMGR.TriggerEvent('UnitPromoted', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);

		if (!m_kAvengerHUD.Movie.Stack.HasInstanceOf(class'UIArmory_Promotion')) // If we are already in the promotion screen, just close this popup
		{
			if( eAction == 'eUIAction_Accept' )
			{
				GoToArmoryPromotion(UnitState.GetReference(), true);
			}
		}
	}
}

simulated function GoToArmoryPromotion(StateObjectReference UnitRef, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom ArmoryState;
	
	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ArmoryState = XComHQ.GetFacilityByName('Hangar');
	ArmoryState.GetMyTemplate().SelectFacilityFn(ArmoryState.GetReference(), true);

	UIArmory_MainMenu(UnitRef,,,,,, bInstant);
	UIArmory_Promotion(UnitRef, bInstant);
}

simulated function UISoldierPromoted(StateObjectReference UnitRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_SoldierPromoted', None, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UIPsiTrainingComplete(StateObjectReference UnitRef, X2AbilityTemplate AbilityTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_PsiTrainingComplete', PsiTrainingCompleteCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'AbilityTemplate', AbilityTemplate.DataName);
	QueueDynamicPopup(PropertySet);
}

simulated function PsiTrainingCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef;

	if (eAction == 'eUIAction_Accept')
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		
		UnitRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef');

		if (XComHQ.bHasSeenFirstPsiOperative || XComHQ.SeenClassMovies.Find('PsiOperative') != INDEX_NONE)
		{
			GoToPsiChamber(UnitRef, true);
		}
		else
		{
			GoToArmoryPromotion(UnitRef, true);
		}
	}
}

simulated function GoToPsiChamber(StateObjectReference UnitRef, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom PsiChamberState;
	local StaffUnitInfo UnitInfo;
	local UIFacility CurrentFacilityScreen;
	local int emptyStaffSlotIndex;

	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	PsiChamberState = XComHQ.GetFacilityByName('PsiChamber');
	PsiChamberState.GetMyTemplate().SelectFacilityFn(PsiChamberState.GetReference(), true);

	if (PsiChamberState.GetNumEmptyStaffSlots() > 0) // First check if there are any open staff slots
	{
		// get to choose scientist screen (from staff slot)
		CurrentFacilityScreen = UIFacility(m_kAvengerHUD.Movie.Stack.GetCurrentScreen());
		emptyStaffSlotIndex = PsiChamberState.GetEmptySoldierStaffSlotIndex();
		if (CurrentFacilityScreen != none && emptyStaffSlotIndex > -1)
		{
			// Only allow the unit to be selected if they are valid
			UnitInfo.UnitRef = UnitRef;
			if (PsiChamberState.GetStaffSlot(emptyStaffSlotIndex).ValidUnitForSlot(UnitInfo))
			{
				CurrentFacilityScreen.SelectPersonnelInStaffSlot(emptyStaffSlotIndex, UnitInfo);
			}
		}
	}
}

simulated function UIPsiLabIntro(X2FacilityTemplate Template)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the Psi Lab alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenPsiLabIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Psi Lab Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenPsiLabIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_PsiLabIntro', None, '', "Geoscape_CrewMemberLevelledUp", true);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'FacilityTemplate', Template.DataName);
		QueueDynamicPopup(PropertySet);
	}
}


simulated function UIPsiOperativeIntro(StateObjectReference UnitRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the customizations alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenPsiOperativeIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Psi Operative Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenPsiOperativeIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_PsiOperativeIntro', PsiTrainingCompleteCB, '', "", true);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function PsiOperativeIntroCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local StateObjectReference UnitRef;

	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		UnitRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef');
		GoToPsiChamber(UnitRef);
	}
}

simulated function UITrainingCenterIntro(X2FacilityTemplate Template)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the Psi Lab alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenTrainingCenterIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Training Center Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenTrainingCenterIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_TrainingCenterIntro', None, '', "Geoscape_CrewMemberLevelledUp", true);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'FacilityTemplate', Template.DataName);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function UIInfirmaryIntro(X2FacilityTemplate Template)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the Psi Lab alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenInfirmaryIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Infirmary Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenInfirmaryIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_InfirmaryIntro', None, '', "Geoscape_CrewMemberLevelledUp", true);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'FacilityTemplate', Template.DataName);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function UIBuildSlotOpen(StateObjectReference RoomRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_BuildSlotOpen', AssignBuildStaffCB, '', "Geoscape_FacilityComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'RoomRef', RoomRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UIClearRoomSlotOpen(StateObjectReference RoomRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ClearRoomSlotOpen', AssignBuildStaffCB, '', "Geoscape_FacilityComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'RoomRef', RoomRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function AssignBuildStaffCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_StaffSlot BuildSlotState;

	if (eAction == 'eUIAction_Accept')
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'RoomRef')));
		BuildSlotState = RoomState.GetBuildSlot(RoomState.GetEmptyBuildSlotIndex());
		BuildSlotState.AutoFillSlot();
	}
}

simulated function UIStaffSlotOpen(StateObjectReference FacilityRef, X2StaffSlotTemplate StaffSlotTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_StaffSlotOpen', AssignFacilityStaffCB, '', "Geoscape_FacilityComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FacilityRef', FacilityRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'StaffSlotTemplate', StaffSlotTemplate.DataName);
	QueueDynamicPopup(PropertySet);
}

simulated function AssignFacilityStaffCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;
	
	if (eAction == 'eUIAction_Accept')
	{		
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'FacilityRef')));
		StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());
		StaffSlotState.AutoFillSlot();
	}
}

simulated function UIClearRoomSlotFilled(StateObjectReference RoomRef, StaffUnitInfo UnitInfo)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ClearRoomSlotFilled', None, '', "StrategyUI_Staff_Assign");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'RoomRef', RoomRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStaffUnitInfoProperties(PropertySet.DynamicProperties, UnitInfo);
	QueueDynamicPopup(PropertySet);
}


simulated function UIConstructionSlotFilled(StateObjectReference RoomRef, StaffUnitInfo UnitInfo)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_BuildSlotFilled', None, '', "StrategyUI_Staff_Assign");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'RoomRef', RoomRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStaffUnitInfoProperties(PropertySet.DynamicProperties, UnitInfo);
	QueueDynamicPopup(PropertySet);
}


simulated function UIStaffSlotFilled(StateObjectReference FacilityRef, X2StaffSlotTemplate StaffSlotTemplate, StaffUnitInfo UnitInfo)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_StaffSlotFilled', None, '', "StrategyUI_Staff_Assign");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FacilityRef', FacilityRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'StaffSlotTemplate', StaffSlotTemplate.DataName);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStaffUnitInfoProperties(PropertySet.DynamicProperties, UnitInfo);
	QueueDynamicPopup(PropertySet);
}


simulated function SuperSoldierAlert(StateObjectReference UnitRef, delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction, string StaffPicture)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_SuperSoldier', CallbackFunction, '', "SuperSoldier");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'StaffPicture', StaffPicture);
	QueueDynamicPopup(PropertySet);
}


simulated function UISoldierShaken(XComGameState_Unit UnitState)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;
	local name ShakenEvent;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenShakenSoldierPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("First Tired Soldier alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenShakenSoldierPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		// Only trigger Central VO the first time the popup is seen
		ShakenEvent = 'OnSoldierShakenPopup';
	}

	BuildUIAlert(PropertySet, 'eAlert_SoldierShaken', None, ShakenEvent, "Geoscape_CrewMemberLevelledUp", false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitState.ObjectID);
	QueueDynamicPopup(PropertySet);
}


simulated function UIWeaponUpgradesAvailable()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	// Flag the customizations alert as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Weapon upgrades alert seen");
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.bHasSeenWeaponUpgradesPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	BuildUIAlert(PropertySet, 'eAlert_WeaponUpgradesAvailable', None, '', "Geoscape_CrewMemberLevelledUp", true);
	QueueDynamicPopup(PropertySet);
}

simulated function UIReinforcedUnderlayActive()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	// Flag the customizations alert as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Weapon upgrades alert seen");
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.bHasSeenReinforcedUnderlayPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	BuildUIAlert(PropertySet, 'eAlert_ReinforcedUnderlayActive', None, '', "Geoscape_CrewMemberLevelledUp", true);
	QueueDynamicPopup(PropertySet);
}


simulated function UISoldierCustomizationsAvailable()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;
	
	// Flag the customizations alert as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Soldier customizations alert seen");
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.bHasSeenCustomizationsPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	BuildUIAlert(PropertySet, 'eAlert_CustomizationsAvailable', None, '', "Geoscape_CrewMemberLevelledUp", true);
	QueueDynamicPopup(PropertySet);
}


simulated function UIForceUnderstrength()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;
	local Name EventToTrigger;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	if (XComHQ.GetNumberOfDeployableSoldiers() == 0)
	{
		EventToTrigger = 'WarningNoSoldiers';
	}
	else if (XComHQ.GetNumberOfDeployableSoldiers() < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
	{
		EventToTrigger = 'WarningNotEnoughSoldiers';
	}

	BuildUIAlert(PropertySet, 'eAlert_ForceUnderstrength', None, EventToTrigger, "Geoscape_CrewMemberLevelledUp", true);
	QueueDynamicPopup(PropertySet);
}


simulated function UIWoundedSoldiersAllowed()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_WoundedSoldiersAllowed', None, 'OnWoundedSoldiersAllowed', "Geoscape_CrewMemberLevelledUp", true);
	QueueDynamicPopup(PropertySet);
}

simulated function UIStrongholdMissionWarning()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_StrongholdMissionWarning', None, '', "Geoscape_CrewMemberLevelledUp", true);
	QueueDynamicPopup(PropertySet);
}


simulated function UILaunchMissionWarning(XComGameState_MissionSite MissionState)
{
	local XComGameState NewGameState;
	local DynamicPropertySet PropertySet;
	
	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!MissionState.bHasSeenLaunchMissionWarning)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Launch Mission Warning Seen");
		MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
		MissionState.bHasSeenLaunchMissionWarning = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	BuildUIAlert(PropertySet, 'eAlert_LaunchMissionWarning', None, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	QueueDynamicPopup(PropertySet);
}


simulated function UIDarkEventActivated(StateObjectReference DarkEventRef)
{
	local XComGameStateHistory History;
	local XComGameState_DarkEvent DarkEventState;
	local XComGameState_AdventChosen ChosenState;
	local DynamicPropertySet PropertySet;
	local name EventToTrigger;

	History = `XCOMHISTORY;
	DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(DarkEventRef.ObjectID));
	if (DarkEventState.bChosenActionEvent)
	{
		ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(DarkEventState.ChosenRef.ObjectID));
		EventToTrigger = ChosenState.GetDarkEventCompleteEvent();
	}

	BuildUIAlert(PropertySet, 'eAlert_DarkEvent', DarkEventActivatedCB, EventToTrigger, "GeoscapeAlerts_ADVENTControl");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'DarkEventRef', DarkEventRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function DarkEventActivatedCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;

	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event Dark Event Popup Closed");
	`XEVENTMGR.TriggerEvent('OnDarkEventPopupClosed', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}
}

simulated function UIPointOfInterestAlert(StateObjectReference POIRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_NewScanningSite', POIAlertCB, '', "Geoscape_POIReveal");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'POIRef', POIRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function POIAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_PointOfInterest POIState;
	local XComGameState NewGameState;
	
	if (eAction == 'eUIAction_Accept' || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M10_IntroToBlacksite') == eObjectiveState_InProgress)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event POI Selected");
		`XEVENTMGR.TriggerEvent('OnPOISelected', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);

		POIState = XComGameState_PointOfInterest(`XCOMHISTORY.GetGameStateForObjectID(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'POIRef')));
		POIState.AttemptSelectionCheckInterruption();

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIPointOfInterestCompleted(StateObjectReference POIRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ScanComplete', POICompleteCB, '', "Geoscape_POIReached");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'POIRef', POIRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function POICompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_PointOfInterest POIState;

	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("POI Complete Reset");
		ResHQ.AttemptSpawnRandomPOI(NewGameState); // Attempt to spawn a new random POI
	
		// Reset the POI that was just completed, prevents two of the same type in a row
		POIState = XComGameState_PointOfInterest(NewGameState.ModifyStateObject(class'XComGameState_PointOfInterest',
																				class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'POIRef')));
		POIState.ResetPOI(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		if (!XComHQ.bHasSeenSupplyDropReminder && XComHQ.IsSupplyDropAvailable())
		{
			UISupplyDropReminder();
		}

		if( eAction == 'eUIAction_Cancel' )
		{
			class'UIUtilities_Strategy'.static.GetXComHQ().ReturnToResistanceHQ();

			if (`GAME.GetGeoscape().IsScanning())
				StrategyMap2D.ToggleScan();
		}
	}
}

simulated function UIResourceCacheAppearedAlert()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ResourceCacheAvailable', ResourceCacheAlertCB, '', "Geoscape_POIReveal");
	QueueDynamicPopup(PropertySet);
}

simulated function ResourceCacheAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_ResourceCache CacheState;

	if (eAction == 'eUIAction_Accept')
	{
		CacheState = XComGameState_ResourceCache(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));
		CacheState.AttemptSelectionCheckInterruption();

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
	else if( eAction == 'eUIAction_Cancel' )
	{
		`GAME.GetGeoscape().Pause();
	}
}

simulated function UIInstantResourceCacheAlert()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_InstantResourceCache', InstantResourceCacheCB, '', "Geoscape_POIReveal");
	QueueDynamicPopup(PropertySet);
}

simulated function InstantResourceCacheCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_ResourceCache CacheState;

	History = `XCOMHISTORY;
	CacheState = XComGameState_ResourceCache(History.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Instant Resource Cache Scan Cleanup");
	CacheState = XComGameState_ResourceCache(NewGameState.ModifyStateObject(class'XComGameState_ResourceCache', CacheState.ObjectID));
	CacheState.ResourcesRemainingInCache = 0;
	CacheState.ResourcesToGiveNextScan = 0;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if(eAction == 'eUIAction_Accept')
	{
		if(`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIResourceCacheCompleteAlert()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ResourceCacheComplete', ResourceCacheCompleteCB, '', "Geoscape_POIReached");
	QueueDynamicPopup(PropertySet);
}

simulated function ResourceCacheCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	if (eAction == 'eUIAction_Accept')
	{
		class'UIUtilities_Strategy'.static.GetXComHQ().ReturnToResistanceHQ(false, true);

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIUFOInboundAlert(StateObjectReference UFORef)
{
	local DynamicPropertySet PropertySet;
	
	BuildUIAlert(PropertySet, 'eAlert_UFOInbound', UFOInboundCB, 'OnUFOEvasive', "Geoscape_UFO_Inbound");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UFORef', UFORef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UFOInboundCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local StateObjectReference UFORef;

	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		UFORef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UFORef');
		class'UIUtilities_Strategy'.static.GetXComHQ().StartUFOChase(UFORef);
	}
}

simulated function UIUFOEvadedAlert()
{
	local DynamicPropertySet PropertySet;
	
	BuildUIAlert(PropertySet, 'eAlert_UFOEvaded', ReturnToPreviousLocationCB, 'OnUFOEvaded', "Geoscape_UFO_Evaded");
	QueueDynamicPopup(PropertySet);
}

simulated function ReturnToPreviousLocationCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{	
	if (eAction == 'eUIAction_Accept')
	{
		class'UIUtilities_Strategy'.static.GetXComHQ().ReturnToSavedLocation();

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIContinentBonus(StateObjectReference ContinentRef)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_ContinentBonus', None, '', "Geoscape_Popup_Positive");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'ContinentRef', ContinentRef.ObjectID);
	QueueDynamicPopup(PropertySet);

	`GAME.GetGeoscape().Pause();
}

simulated function UINewResHQGoodsAvailable()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_HelpResHQGoods', NewResHQGoodsAvailableCB, 'OnHelpResHQ', "Geoscape_PopularSupportThreshold");
	QueueDynamicPopup(PropertySet);
}

simulated function NewResHQGoodsAvailableCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	if (eAction == 'eUIAction_Accept')
	{
		class'UIUtilities_Strategy'.static.GetXComHQ().ReturnToResistanceHQ(true, false);

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIBuildTheRing()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenBuildTheRingPopup && !XComHQ.HasFacilityByName('ResistanceRing'))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Build the Ring Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenBuildTheRingPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_BuildTheRing', LowWarningCB, '', "Geoscape_DoomIncrease");
		QueueDynamicPopup(PropertySet);
	}
}

simulated function UILowIntel()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenLowIntelPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Low Intel Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenLowIntelPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	
	BuildUIAlert(PropertySet, 'eAlert_LowIntel', LowWarningCB, '', "Geoscape_DoomIncrease");
	QueueDynamicPopup(PropertySet);
}

simulated function UILowSupplies()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenLowSuppliesPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Low Supplies Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenLowSuppliesPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	
	BuildUIAlert(PropertySet, 'eAlert_LowSupplies', LowWarningCB, '', "Geoscape_DoomIncrease");
	QueueDynamicPopup(PropertySet);
}

simulated function UILowScientists()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenLowScientistsPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Low Scientists Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenLowScientistsPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	BuildUIAlert(PropertySet, 'eAlert_LowScientists', LowWarningCB, '', "Geoscape_DoomIncrease");
	QueueDynamicPopup(PropertySet);
}

simulated function UILowEngineers()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenLowEngineersPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Low Engineers Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenLowEngineersPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		//Moved the spawn on the alert to inside the bHasSeenLowEngineersPopup check to avoid accidentally spawning double alerts
		BuildUIAlert(PropertySet, 'eAlert_LowEngineers', LowWarningCB, '', "Geoscape_DoomIncrease");
		QueueDynamicPopup(PropertySet);
	}
	
}

simulated function LowWarningCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
}

simulated function UILowScientistsSmall()
{
	local DynamicPropertySet PropertySet;
	
	BuildUIAlert(PropertySet, 'eAlert_LowScientistsSmall', LowScientistsSmallCB, 'WarningNeedMoreScientists', "Geoscape_DoomIncrease");
	QueueDynamicPopup(PropertySet);
}

simulated function LowScientistsSmallCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	if (eAction == 'eUIAction_Accept')
	{
		UILowScientists();
	}
}

simulated function UILowEngineersSmall()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_LowEngineers', LowEngineersSmallCB, 'WarningNeedMoreEngineers', "Geoscape_DoomIncrease");
	QueueDynamicPopup(PropertySet);
}

simulated function LowEngineersSmallCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	if (eAction == 'eUIAction_Accept')
	{
		UILowEngineers();
	}
}

simulated function UISupplyDropReminder()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (!XComHQ.bHasSeenSupplyDropReminder)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Supply Drop Reminder Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenSupplyDropReminder = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	BuildUIAlert(PropertySet, 'eAlert_SupplyDropReminder', None, '', "Geoscape_POIReveal");
	QueueDynamicPopup(PropertySet);
}

simulated function UIPowerCoilShielded()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (!XComHQ.bHasSeenPowerCoilShieldedPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Power Coil Shielded alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenPowerCoilShieldedPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_PowerCoilShielded', None, '', "Geoscape_CrewMemberLevelledUp");
		QueueDynamicPopup(PropertySet);
	}
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                   GAME ENDING POPUPS
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// Preview build functions
simulated function PreviewBuildComplete()
{
	local TDialogueBoxData kData;

	kData.strTitle = m_strPreviewBuildTitle;
	kData.strText = m_strPreviewBuildText;
	kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kData.eType = eDialog_Normal;
	kData.fnCallback = PreviewBuildCompleteCallback;

	UIRaiseDialog(kData);
}

simulated function PreviewBuildCompleteCallback(Name eAction)
{
	ClearUIToHUD();
	UIEndGame();
	`XCOMHISTORY.ResetHistory();
	ConsoleCommand("disconnect");
}

simulated public function UIDoomTimer()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_AlienVictoryImminent', DoomTimerCB, 'OnFinalCountdown', "Geoscape_DoomIncrease");
	QueueDynamicPopup(PropertySet);
}

simulated private function DoomTimerCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();
}
}

simulated public function UIYouLose()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlayLossMusic();	

	UIEndGameStats(false);
}

simulated public function UIYouWin()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlayCreditsMusic();
	
	UIEndGameStats(true);
}

simulated function UIEndGameStats(bool bWon)
{
	local UIEndGameStats StatsScreen;
	StatsScreen = Spawn(class'UIEndGameStats', self);
	StatsScreen.bGameWon = bWon;
	ScreenStack.Push(StatsScreen);
}

simulated private function Disconnect()
{
	`XCOMHISTORY.ResetHistory();
	ConsoleCommand("disconnect");
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                   EXPANSION POPUPS
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function UILostAndAbandonedMission(XComGameState_MissionSite MissionState, optional bool bInstant = false)
{
	local XComGameState_ResistanceFaction FactionState;
	local DynamicPropertySet PropertySet;

	FactionState = MissionState.GetResistanceFaction();

	BuildUIAlert(PropertySet, 'eAlert_LostAndAbandoned', LostAndAbandonedAlertCB, FactionState.GetResistanceOpSpawnedEvent(), "Geoscape_NewResistOpsMissions");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FactionRef', FactionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}

simulated function UIResistanceOpMission(XComGameState_MissionSite MissionState, optional bool bInstant = false)
{
	local XComGameState_ResistanceFaction FactionState;
	local DynamicPropertySet PropertySet;

	FactionState = MissionState.GetResistanceFaction();

	BuildUIAlert(PropertySet, 'eAlert_ResistanceOp', ResistanceOpsAlertCB, FactionState.GetResistanceOpSpawnedEvent(), FactionState.GetFanfareEvent());
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FactionRef', FactionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}

simulated function UIRescueSoldierMission(XComGameState_MissionSite MissionState, optional bool bInstant = false)
{
	local XComGameState_ResistanceFaction FactionState;
	local DynamicPropertySet PropertySet;

	FactionState = MissionState.GetResistanceFaction();

	BuildUIAlert(PropertySet, 'eAlert_RescueSoldier', RescueSoldierAlertCB, 'OnRescueSoldierPopup', FactionState.GetFanfareEvent());
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FactionRef', FactionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}

simulated function UIChosenAmbushMission(XComGameState_MissionSite MissionState, optional bool bInstant = false)
{
	local XComGameState_ResistanceFaction FactionState;
	local DynamicPropertySet PropertySet;
	local name AmbushEvent;

	FactionState = MissionState.GetResistanceFaction();
	if (class'X2StrategyGameRulesetDataStructures'.static.Roll(33))
	{
		AmbushEvent = 'CovertActionAmbush_Central';
	}
	else
	{
		AmbushEvent = FactionState.GetCovertActionAmbushEvent();
	}
	
	BuildUIAlert(PropertySet, 'eAlert_ChosenAmbush', ChosenAmbushAlertCB, AmbushEvent, "ChosenPopupOpen");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FactionRef', FactionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}

simulated function UIChosenStrongholdMission(XComGameState_MissionSite MissionState, optional bool bInstant = false)
{
	local XComGameState_ResistanceFaction FactionState;
	local DynamicPropertySet PropertySet;

	FactionState = MissionState.GetResistanceFaction();

	BuildUIAlert(PropertySet, 'eAlert_ChosenStronghold', ChosenStrongholdAlertCB, 'OnViewChosenStrongholdMission', "ChosenPopupOpen");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FactionRef', FactionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	QueueDynamicPopup(PropertySet);
}

simulated function UIChosenSabotage(StateObjectReference ActionRef)
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local DynamicPropertySet PropertySet;
	local name SabotageEvent;

	History = `XCOMHISTORY;
	ActionState = XComGameState_ChosenAction(History.GetGameStateForObjectID(ActionRef.ObjectID));
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ActionState.ChosenRef.ObjectID));
	SabotageEvent = ActionState.bActionFailed ? ChosenState.GetSabotageFailedEvent() : ChosenState.GetSabotageSuccessEvent();

	BuildUIAlert(PropertySet, 'eAlert_ChosenSabotage', ChosenSabotageCB, SabotageEvent, ChosenState.GetMyTemplate().FanfareEvent);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'ActionRef', ActionRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function ChosenSabotageCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_ChosenAction ActionState;
	
	ActionState = XComGameState_ChosenAction(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'ActionRef')));

	if (!ActionState.bActionFailed)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Post Chosen Sabotage");
		`XEVENTMGR.TriggerEvent('PostChosenSabotage', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

simulated function UIChosenRetribution(StateObjectReference ActionRef)
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local DynamicPropertySet PropertySet;

	History = `XCOMHISTORY;
	ActionState = XComGameState_ChosenAction(History.GetGameStateForObjectID(ActionRef.ObjectID));
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ActionState.ChosenRef.ObjectID));
	
	BuildUIAlert(PropertySet, 'eAlert_XPACK_Retribution', ChosenRetributionCB, ChosenState.GetRetributionEvent(), ChosenState.GetMyTemplate().FanfareEvent);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'ActionRef', ActionRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function ChosenRetributionCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Post Chosen Retribution");
	`XEVENTMGR.TriggerEvent('PostChosenRetribution', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ.NumChosenRetributions >= 2)
	{
		`HQPRES.UIBuildTheRing();
	}
}

simulated function UIChosenLevelUp(StateObjectReference ChosenRef)
{
	local UIChosenLevelUp kScreen;

	kScreen = Spawn(class'UIChosenLevelUp', self);
	kScreen.ChosenRef = ChosenRef;
	ScreenStack.Push(kScreen);
}

simulated function UIChosenAvengerAssaultMission(XComGameState_MissionSite MissionState)
{
	local UIMission_ChosenAvengerAssault kScreen;

	kScreen = Spawn(class'UIMission_ChosenAvengerAssault', self);
	kScreen.MissionRef = MissionState.GetReference();
	ScreenStack.Push(kScreen);
}

simulated function LostAndAbandonedAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_LostAndAbandoned kScreen;

	if (eAction == 'eUIAction_Accept')
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_LostAndAbandoned'))
		{
			kScreen = Spawn(class'UIMission_LostAndAbandoned', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function ResistanceOpsAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_ResOps kScreen;

	if (eAction == 'eUIAction_Accept')
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_ResOps'))
		{
			kScreen = Spawn(class'UIMission_ResOps', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function RescueSoldierAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_RescueSoldier kScreen;

	if (eAction == 'eUIAction_Accept')
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_RescueSoldier'))
		{
			kScreen = Spawn(class'UIMission_RescueSoldier', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function ChosenAmbushAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UIMission_ChosenAmbush kScreen;

	if (eAction == 'eUIAction_Accept')
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_ChosenAmbush'))
		{
			kScreen = Spawn(class'UIMission_ChosenAmbush', self);
			kScreen.MissionRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'MissionRef');
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}
simulated function ChosenStrongholdAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_MissionSite MissionSite;

	if( eAction == 'eUIAction_Accept' )
	{
		MissionSite = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'MissionRef')));
		UIMission_ChosenStronghold(MissionSite, bInstant);
	}
}

simulated function UIMission_ChosenStronghold(XComGameState_MissionSite Mission, optional bool bInstant = false)
{
	local UIMission_ChosenStronghold kScreen;

	// Show the alien facility
	if (!ScreenStack.GetCurrentScreen().IsA('UIMission_ChosenStronghold'))
	{
		kScreen = Spawn(class'UIMission_ChosenStronghold', self);
		kScreen.MissionRef = Mission.GetReference();
		kScreen.bInstantInterp = bInstant;
		ScreenStack.Push(kScreen);
	}

	if (`GAME.GetGeoscape().IsScanning())
	{
		StrategyMap2D.ToggleScan();
	}
}

simulated function CovertActionsCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local UICovertActions kScreen;
	
	if (eAction == 'eUIAction_Accept')
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UICovertActions'))
		{
			kScreen = Spawn(class'UICovertActions', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}


simulated function OnCovertActionSelected(XComGameState_CovertAction ActionSite, optional bool bInstant = false)
{
	local DynamicPropertySet PropertySet;
	CovertActionsCB('eUIAction_Accept', PropertySet, bInstant);

	// Guerilla ops have 2 or 3 choices, open up at the correct mission
	UICovertActions(ScreenStack.GetCurrentScreen()).SelectAction(ActionSite);
}

simulated function UICheckForPostCovertActionAmbush()
{
	local XComGameState_CovertAction ActionState;
	local XComGameState_HeadquartersXCom XComHQ;

	// If a covert action ambush just finished, automatically push the player into the geoscape to view the report
	ActionState = class'XComGameState_HeadquartersResistance'.static.GetCurrentCovertAction();
	if (ActionState != none && ActionState.bAmbushed)
	{
		// Check if XComHQ is not waiting for an ambush, meaning that it already happened
		// and that the mission ref is 0, which indicates that the post mission sequence has been finished
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (!XComHQ.bWaitingForChosenAmbush && XComHQ.MissionRef.ObjectID == 0)
		{
			UIEnterStrategyMap(true);
		}
	}
}

simulated function UIStartActionCompletedSequence(StateObjectReference ActionRef)
{
	local XComGameState_CovertAction ActionState;

	ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(ActionRef.ObjectID));
	CovertActionCompleteRef = ActionRef; // Save the Covert Action ref so we can access it when the camera pans complete
	
	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();

	// Start the pan to the Covert Action location
	StrategyMap2D.SetUIState(eSMS_Flight);
	CAMSaveCurrentLocation();	
	CAMLookAtEarth(ActionState.Get2DLocation(), 0.5f, `HQINTERPTIME);
	SetTimer((`HQINTERPTIME), false, nameof(CovertActionCameraPanComplete));
}

simulated function CovertActionCameraPanComplete()
{
	local XComGameState_CovertAction ActionState;

	ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(CovertActionCompleteRef.ObjectID));
	ActionState.ShowActionCompletePopups();
	
	StrategyMap2D.SetUIState(eSMS_Default); // Turn off flight mode
}

simulated function UIActionCompleted()
{
	local XComGameState NewGameState;
	local XComGameState_CovertAction ActionState;
	local XComGameState_ResistanceFaction FactionState;
	local UICovertActionReport kScreen;

	ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(CovertActionCompleteRef.ObjectID));
	FactionState = ActionState.GetFaction();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Covert Action Completed");
	if (ActionState.DidRiskOccur('CovertActionRisk_SoldierCaptured'))
	{
		`XEVENTMGR.TriggerEvent('CovertActionSoldierCaptured_Central', , , NewGameState);
	}
	else if (ActionState.DidRiskOccur('CovertActionRisk_SoldierWounded'))
	{
		`XEVENTMGR.TriggerEvent('CovertActionSoldierWounded_Central', , , NewGameState);
	}
	else if (ActionState.GetMyTemplateName() == 'CovertAction_CancelChosenActivity' && !FactionState.GetRivalChosen().bDefeated)
	{
		`XEVENTMGR.TriggerEvent(FactionState.GetRivalChosen().GetCancelledActivityEvent(), , , NewGameState);
	}
	else if (FactionState.bMetXCom && FactionState.bSeenFactionHQReveal)
	{
		`XEVENTMGR.TriggerEvent(ActionState.GetFaction().GetCovertActionCompletedEvent(), , , NewGameState);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if (!ScreenStack.GetCurrentScreen().IsA('UICovertActionReport'))
	{
		kScreen = Spawn(class'UICovertActionReport', self);
		kScreen.ActionRef = CovertActionCompleteRef;
		ScreenStack.Push(kScreen);
	}

	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();
}

simulated function UIActionCompleteRewards()
{
	local XComGameState NewGameState;
	local XComGameState_CovertAction ActionState;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_HeadquartersXCom XComHQ;
	
	ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(CovertActionCompleteRef.ObjectID));

	if (ActionState != none)
	{
		FactionState = ActionState.GetFaction();
		
		// This was the first Covert Action completed by this Faction, so we need to meet them now
		if (!FactionState.bSeenFactionHQReveal)
		{
			// Start the reveal Faction sequence, skip the rewards this time
			// This function will be called again from UIFactionPopup after they have been met
			BeginFactionRevealSequence(FactionState);
		}
		else
		{
			// First display any reward popups if this does not have a specific sequence
			ActionState.ActionRewardPopups();

			// Then delete the Action that was just completed
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Action Complete Removal");
			ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', CovertActionCompleteRef.ObjectID));
			ActionState.RemoveEntity(NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			// This is the end of the Action Complete sequence, so clear the Action ref
			CovertActionCompleteRef.ObjectID = 0;

			// Handle any HQ staffing updates for the soldiers returning from the Action (Ex: Psi Ops)
			XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
			XComHQ.HandlePowerOrStaffingChange();
		}
	}
}

simulated function UINextCovertAction()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_NextCovertAction', NextCovertActionPopupCB, '', "Geoscape_Popup_Positive");
	QueueDynamicPopup(PropertySet);
}

simulated function NextCovertActionPopupCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local UIFacility_CovertActions RingScreen;

	if (eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('ResistanceRing');

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();

		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference(), true);
		
		// get to view Covert Actions screen, once we're on the Ring screen. 
		RingScreen = UIFacility_CovertActions(ScreenStack.GetCurrentScreen());
		if (RingScreen != none)
		{
			RingScreen.OnViewActions();
		}
	}
	else
	{
		`HQPRES.CAMRestoreSavedLocation();
	}
}

simulated function UISoldierCapturedCallback(Name eAction, out DynamicPropertySet PropertySet, optional bool bInstant)
{
	local UISoldierCaptured kScreen;

	kScreen = Spawn(class'UISoldierCaptured', self);
	kScreen.ChosenRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'ChosenRef');
	kScreen.TargetRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(PropertySet, 'TargetRef');
	kScreen.bCapturedOnMission = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicBoolProperty(PropertySet, 'bCapturedOnMission');
	ScreenStack.Push(kScreen);
}

simulated function UISoldierCaptured(XComGameState_AdventChosen ChosenState, StateObjectReference TargetRef, optional bool bMission)
{
	local DynamicPropertySet PropertySet;

	BuildUIScreen(PropertySet, 'SoldierCaptured', UISoldierCapturedCallback, false );
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'ChosenRef', ChosenState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'TargetRef', TargetRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bCapturedOnMission', bMission);
	QueueDynamicPopup(PropertySet);
}

simulated function UIChosenEncountered(XComGameState_AdventChosen ChosenState)
{
	local UIChosenEncountered kScreen;

	kScreen = Spawn(class'UIChosenEncountered', self);
	kScreen.ChosenRef = ChosenState.GetReference();
	ScreenStack.Push(kScreen);
}

function UIPersonnel_CovertAction(delegate<UIPersonnel.OnPersonnelSelected> onSelected, StateObjectReference SlotRef)
{
	local UIPersonnel_CovertAction kPersonnelList;

	if (ScreenStack.IsNotInStack(class'UIPersonnel_CovertAction'))
	{
		kPersonnelList = Spawn(class'UIPersonnel_CovertAction', self);
		kPersonnelList.onSelectedDelegate = onSelected;
		kPersonnelList.SlotRef = SlotRef;
		ScreenStack.Push(kPersonnelList);
	}
}

function UIPersonnel_TrainingCenter(delegate<UIPersonnel.OnPersonnelSelected> onSelected)
{
	local UIPersonnel_TrainingCenter kPersonnelList;

	if (ScreenStack.IsNotInStack(class'UIPersonnel_TrainingCenter'))
	{
		kPersonnelList = Spawn(class'UIPersonnel_TrainingCenter', self);
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push(kPersonnelList);
	}
}

function UIPersonnel_BoostSoldier(delegate<UIPersonnel.OnPersonnelSelected> onSelected, XComGameState_HeadquartersXCom HQState)
{
	local UIPersonnel_BoostSoldier kPersonnelList;

	if (ScreenStack.IsNotInStack(class'UIPersonnel_BoostSoldier'))
	{
		kPersonnelList = Spawn(class'UIPersonnel_BoostSoldier', self);
		kPersonnelList.onSelectedDelegate = onSelected;
		kPersonnelList.HQState = HQState;
		ScreenStack.Push(kPersonnelList);
	}
}

function UICovertActions()
{
	if (ScreenStack.IsNotInStack(class'UICovertActions'))
	{
		TempScreen = Spawn(class'UICovertActions', self);
		ScreenStack.Push(TempScreen);
	}
}

function UISitRepInformation(StateObjectReference MissionRef)
{
	local UISitRepInformation kScreen;

	//Check to not allow you in to this screen multiple times. 
	if (ScreenStack.GetScreen(class'UISitRepInformation') != none)
		return;
	
	kScreen = Spawn(class'UISitRepInformation', self);
	kScreen.MissionRef = MissionRef;
	ScreenStack.Push(kScreen);
}

function UIStrategyPolicy(optional bool bResistanceReport, optional bool bInstantInterp)
{
	local XComGameState NewGameState;
	local UIStrategyPolicy kScreen;

	//Check to not allow you in to this screen multiple times. 
	if (ScreenStack.GetScreen(class'UIStrategyPolicy') != none)
		return;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: View Strategy Policies");
	`XEVENTMGR.TriggerEvent('OnViewStrategyPolicies', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	kScreen = Spawn(class'UIStrategyPolicy', self);
	kScreen.bResistanceReport = bResistanceReport;
	kScreen.bInstantInterp = bInstantInterp;
	ScreenStack.Push(kScreen);
}

simulated function UICombatIntelligenceIntro(StateObjectReference UnitRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the customizations alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenCombatIntelligenceIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Combat Intelligence Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenCombatIntelligenceIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_ComIntIntro', None, 'OnComIntIntro', "Geoscape_CrewMemberLevelledUp");
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function UISoldierTired(XComGameState_Unit UnitState)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenTiredSoldierPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("First Tired Soldier alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenTiredSoldierPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_SoldierTired', None, 'OnSoldierTiredPopup', "Geoscape_CrewMemberLevelledUp", false);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitState.ObjectID);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function UIResistanceOrdersIntro()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the alert as having been seen and show it, otherwise do nothing
	if(!XComHQ.bHasSeenResistanceOrdersIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("First Resistance Orders screen alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenResistanceOrdersIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_ResistanceOrdersIntro', None, 'OnResistanceOrdersIntroPopup', "Geoscape_CrewMemberLevelledUp", true);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function UIFactionPopup(XComGameState_ResistanceFaction FactionState, optional bool bInfluenceIncreased)
{
	local UIFactionPopup kScreen;

	kScreen = Spawn(class'UIFactionPopup', self);
	kScreen.FactionRef = FactionState.GetReference();
	kScreen.bInfluenceIncreased = bInfluenceIncreased;
	ScreenStack.Push(kScreen);
}

simulated function UIStrategyCardReceived(StateObjectReference CardRef, optional bool bAllowFactionLeaderVO = true)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;
	local XComGameState_StrategyCard CardState;
	local XComGameState_ResistanceFaction FactionState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasReceivedResistanceOrderPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Resistance Order Received");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		`XEVENTMGR.TriggerEvent('OnResistanceOrderReceived', , , NewGameState);
		XComHQ.bHasReceivedResistanceOrderPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	CardState = XComGameState_StrategyCard(`XCOMHISTORY.GetGameStateForObjectID(CardRef.ObjectID));
	FactionState = CardState.GetAssociatedFaction();
		
	BuildUIAlert(PropertySet, 'eAlert_StrategyCardReceived', None, bAllowFactionLeaderVO ? FactionState.GetNewResistanceOrderEvent() : '', FactionState.GetFanfareEvent());
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'CardRef', CardRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function UISitrepIntro()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the customizations alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenSitrepIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Sitrep Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenSitrepIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_SitrepIntro', None, 'OnSitrepIntro', "Geoscape_CrewMemberLevelledUp");
		QueueDynamicPopup(PropertySet);
	}
}

simulated function UISoldierCompatibilityIntro(optional bool bImmediate = true)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the customizations alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenSoldierCompatibilityIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Soldier Compatibility Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenSoldierCompatibilityIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_SoldierCompatibilityIntro', None, 'OnSoldierCompatibilityIntro', "Geoscape_CrewMemberLevelledUp", bImmediate);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function bool UICovertActionIntro()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the customizations alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenCovertActionIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Covert Action Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenCovertActionIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_CovertActionIntro', None, 'OnCovertActionIntro', "Geoscape_CrewMemberLevelledUp");
		QueueDynamicPopup(PropertySet);

		return true;
	}
	return false;
}

simulated function bool UICovertActionRiskIntro()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the customizations alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenCovertActionRiskIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Covert Action Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenCovertActionRiskIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_CovertActionRiskIntro', None, 'OnCovertActionRiskIntro', "Geoscape_CrewMemberLevelledUp");
		QueueDynamicPopup(PropertySet);

		return true;
	}
	return false;
}

function UIConfirmCovertAction(StateObjectReference ActionRef)
{
	local XComGameState_CovertAction ActionState;
	local DynamicPropertySet PropertySet;
	
	// Force the camera to look at the Action's location on the Geoscape
	if (!`SCREENSTACK.IsInStack(class'UIStrategyMap'))
	{		
		GetCamera().ForceEarthViewImmediately(true);
	}
	
	ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(ActionRef.ObjectID));
	CAMLookAtEarth(ActionState.GetWorldRegion().Get2DLocation(), 0.5, 0);

	BuildUIAlert(PropertySet, 'eAlert_ConfirmCovertAction', ConfirmCovertActionCB, '', "", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'ActionRef', ActionRef.ObjectID);
	QueueDynamicPopup(PropertySet);
}

simulated function ConfirmCovertActionCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_CovertAction ActionState;
	local UIFacility_CovertActions FacilityScreen;
	local UICovertActions CovertActionsScreen;

	if (eAction == 'eUIAction_Accept')
	{
		ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'ActionRef')));
		ActionState.StartAction();

		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("UI_CovertOps_Confirm_Action");
		
		// The Action was started, so close the Actions screen. If it was canceled, we'll go back to the screen instead
		CovertActionsScreen = UICovertActions(ScreenStack.GetFirstInstanceOf(class'UICovertActions'));
		if (CovertActionsScreen != none)
		{
			CovertActionsScreen.CloseScreen();
					
			FacilityScreen = UIFacility_CovertActions(ScreenStack.GetLastInstanceOf(class'UIFacility_CovertActions'));
			if (FacilityScreen != none)
			{
				// Jump back to the facility immediately, no interp
				FacilityScreen.bInstantInterp = true;
				FacilityScreen.HQCamLookAtThisRoom();
			}
			else if (`SCREENSTACK.IsInStack(class'UIStrategyMap'))
			{
				`HQPRES.CAMRestoreSavedLocation(0.0);
			}
		}
	}
}

simulated function UICantChangeOrders(optional bool bImmediate = true)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local DynamicPropertySet PropertySet;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the customizations alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenCantChangeOrdersPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cant Change Orders alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenCantChangeOrdersPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		BuildUIAlert(PropertySet, 'eAlert_CantChangeOrders', None, '', "Geoscape_CrewMemberLevelledUp", bImmediate);
		QueueDynamicPopup(PropertySet);
	}
}

simulated function UIChosenFragmentRecovered(StateObjectReference ChosenRef, optional int ForceFragmentLevel = -1)
{
	local UIChosenFragmentRecovered kScreen;

	kScreen = Spawn(class'UIChosenFragmentRecovered', self);
	kScreen.ChosenRef = ChosenRef;
	kScreen.FragmentLevel = ForceFragmentLevel; 
	ScreenStack.Push(kScreen);
}

simulated function UITempPopup(string Title, string Header, string Body, optional bool bImmediate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_TempPopup', None, '', "", bImmediate);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Title', Title);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Header', Header);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Body', Body);
	QueueDynamicPopup(PropertySet);
}

///////////////////////////////////////////////////////////////
////////////// FACTION REVEAL SEQUENCE ////////////////////////
///////////////////////////////////////////////////////////////

//---------------------------------------------------------------------------------------
function BeginFactionRevealSequence(XComGameState_ResistanceFaction FactionState)
{
	local XComGameState_Haven FactionHQState;

	CAMSaveCurrentLocation();
	StrategyMap2D.SetUIState(eSMS_Flight);

	// Stop Scanning
	if (`GAME.GetGeoscape().IsScanning())
	{
		StrategyMap2D.ToggleScan();
	}

	// Save the Faction we're starting a reveal sequence for so we can access it in callback functions
	FactionRef = FactionState.GetReference();
	bFactionRevealSequence = true;
	
	// Start the pan to the HQ location
	FactionHQState = XComGameState_Haven(`XCOMHISTORY.GetGameStateForObjectID(FactionState.FactionHQ.ObjectID));
	CAMLookAtEarth(FactionHQState.Get2DLocation(), 0.5f, `HQINTERPTIME);
	SetTimer((`HQINTERPTIME), false, nameof(FactionRevealCameraPanComplete));
}

//---------------------------------------------------------------------------------------
function FactionRevealCameraPanComplete()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_CampaignSettings CampaignState;
	local XComGameState_ResistanceFaction FactionState;

	History = `XCOMHISTORY;
	FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(FactionRef.ObjectID));
	CampaignState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	if (CampaignState.bXPackNarrativeEnabled || !CampaignState.bSuppressFirstTimeNarrative)
	{
		// This only triggers when L&A is turned off, so trigger both faction-specific and generic events.
		// Objectives will handle which one is received and plays
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Begin Faction HQ Reveal Event");
		`XEVENTMGR.TriggerEvent(FactionState.GetRevealHQEvent(), , , NewGameState);
		`XEVENTMGR.TriggerEvent('FactionHQLocated', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		// If beginner VO is turned off, jump straight to the class intro movie, don't wait for Central's line to finish
		FactionRevealPlayClassIntroMovie();
	}
}

//---------------------------------------------------------------------------------------
function FactionRevealPlayClassIntroMovie()
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(FactionRef.ObjectID));
	UnitRef = XComHQ.GetSoldierRefOfTemplate(FactionState.GetChampionCharacterName());

	// If the player currently has a living Faction hero, display their class intro movie
	// UIFactionRevealComplete will be triggered when the class movie ends...
	if (UnitRef.ObjectID == 0 || !class'X2StrategyGameRulesetDataStructures'.static.ShowClassMovie(FactionState.GetChampionClassName(), UnitRef))
	{
		// ...this wasn't the first time we saw this unit's new class movie (or the player doesn't have the unit) so just jump straight to the UI
		UIFactionRevealComplete(UnitRef);
	}
}

//---------------------------------------------------------------------------------------
// Doesn't actually require these variables, needed to match the class intro movie callback delegate
function UIFactionRevealComplete(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	local XComGameState NewGameState;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_CampaignSettings CampaignState;

	CampaignState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Faction Met Event");
	FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionRef.ObjectID));
	FactionState.bNeedsFactionHQReveal = false;
	FactionState.bSeenFactionHQReveal = true;
	`XEVENTMGR.TriggerEvent('SpawnFirstPOI', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`HQPRES.UIFactionPopup(FactionState);

	bFactionRevealSequence = false;
	
	// Flight mode will be turned off by the objective after Volk's dialogue completes during Lost and Abandoned games
	if (!CampaignState.bXPackNarrativeEnabled || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M7_MeetTheReapersLA') != eObjectiveState_InProgress)
	{
		// Otherwise it will be turned off when the sequence is complete and all of the UI popups have been displayed
		StrategyMap2D.SetUIState(eSMS_Default);
	}
}

///////////////////////////////////////////////////////////////
////////////// CHOSEN REVEAL SEQUENCE ////////////////////////
///////////////////////////////////////////////////////////////

//---------------------------------------------------------------------------------------
function BeginChosenRevealSequence(XComGameState_AdventChosen ChosenState)
{
	CAMSaveCurrentLocation();
	StrategyMap2D.SetUIState(eSMS_Flight);

	// Stop Scanning
	if (`GAME.GetGeoscape().IsScanning())
	{
		StrategyMap2D.ToggleScan();
	}

	// Save the Chosen we're starting a reveal sequence for so we can access it in callback functions
	AdventChosenRef = ChosenState.GetReference();

	// Start the pan to the Chosen location
	CAMLookAtEarth(ChosenState.Get2DLocation(), 0.5f, `HQINTERPTIME);
	SetTimer((`HQINTERPTIME), false, nameof(ChosenRevealCameraPanComplete));
}

//---------------------------------------------------------------------------------------
function ChosenRevealCameraPanComplete()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_CampaignSettings CampaignState;

	History = `XCOMHISTORY;
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(AdventChosenRef.ObjectID));
	CampaignState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	
	if (!ChosenState.bForcedMet && (CampaignState.bXPackNarrativeEnabled || !CampaignState.bSuppressFirstTimeNarrative))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Begin Chosen Reveal Event");
		`XEVENTMGR.TriggerEvent(ChosenState.GetRevealLocationEvent(), , , NewGameState); // Fix for old playthroughs / objectives to unblock meet the Chosen sequence
		`XEVENTMGR.TriggerEvent('ChosenEncountered', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		// If beginner VO is turned off, jump straight to the chosen reveal screen, don't wait for Central's lines to finish
		UIChosenRevealComplete();
	}
}

//---------------------------------------------------------------------------------------
function UIChosenRevealComplete()
{
	local XComGameState NewGameState;
	local XComGameState_AdventChosen ChosenState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Chosen Encountered Event");
	ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', AdventChosenRef.ObjectID));
	ChosenState.bNeedsLocationReveal = false;
	ChosenState.bSeenLocationReveal = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`HQPRES.UIChosenEncountered(ChosenState);
	
	StrategyMap2D.SetUIState(eSMS_Default); // Turn off flight mode after triggering all of the UI popups
}

//----------------------------------------------------
//----------------------------------------------------
// DATA SCREEN MANAGER 
// Use this to access a manager. Automatically creates the manager if not already live. 
// This is the standard access for the managers, unless 
public function XGScreenMgr GetMgr( class<actor> kMgrClass, optional IScreenMgrInterface kInterface = none, optional int iView = -1, optional bool bIgnoreIfDoesNotExist = false )
{
	local XGScreenMgr kMgr; 

	// IF we find a manager already activated, use the live one. 
	foreach m_arrScreenMgrs(kMgr)
	{
		if( kMgr.Class != kMgrClass ) continue; 
		
		if( kInterface != none )
			kMgr.m_kInterface = kInterface; 

		if( iView != -1 )
			kMgr.GoToView( iView );

		return kMgr;
	}

	if (!bIgnoreIfDoesNotExist)
	{
		// ELSE the manager type was not found, 
		// so create the desired manager type before linking to it.
		kMgr = XGScreenMgr(Spawn( kMgrClass, self ));
		m_arrScreenMgrs.AddItem( kMgr );
		if( kInterface == none ) `log("HQPres.GetMgr() received kInterface == 'none' while trying to create a new manager '"$ kMgrClass $"'. This shouldn't happen.",,'uixcom');
		kMgr.m_kInterface = kInterface; 
		kMgr.Init( iView );
	}

	return kMgr; 	
}

// Use when you need to preform a manager and set particular information within the normal sequence, ex. before Init(). 
// - only use manager which has been spawned to this pres layer as Owner,
// - assigned an interface,
// - not a class type already in use,
// - already initted.
// Returns true if adding was successful. 
public function bool AddPreformedMgr( XGScreenMgr kMgr )
{
	local XGScreenMgr currentMgr;

	// Check that this type is not already in use 
	foreach m_arrScreenMgrs(currentMgr)
	{
		if( kMgr.Class == currentMgr.Class )
		{
			`log("XComHQPres:AddPreformedMgr(): Trying to add a pre-formed manager, but manager of that type has been found in the screen managers array. '" $kMgr.Class $"'. Removing old one and adding new one.",,'uixcom');
			m_arrScreenMgrs.RemoveItem( currentMgr );
		}
	}

	// Check that the mgr has been assigned an interface properly. 
	if( kMgr.m_kInterface == none )
	{
		`log("XComHQPres:AddPreformedMgr(): kMgr does not have an interface assigned. '" $kMgr $"'",,'uixcom');
		return false;
	}

	//CHeck that the mgr is owned by the HQPres.
	if( kMgr.Owner != self )
	{
		`log("XComHQPres:AddPreformedMgr(): kMgr isn't assigned to the HQPres layer as owner. '" $kMgr $"'",,'uixcom');
		return false;
	}

	// No way to currently verify is has been initted. 

	// Passed all checks, so add to the array and report success. 
	m_arrScreenMgrs.AddItem( kMgr );	
	return true; 	
}

public function bool RemoveMgr( class<actor> kMgrClass )
{
	local XGScreenMgr kMgr; 

	foreach m_arrScreenMgrs(kMgr)
	{
		if( kMgr.Class != kMgrClass ) continue; 

		// Remove the manager from array and destroy it cleanly.
		m_arrScreenMgrs.RemoveItem( kMgr ); 
		kMgr.Destroy();
		return true;
	}

	// ELSE: 
	`log( "UIScreenDataMgr attempted to remove a manager type '" $ string(kMgrClass) $"', but item was not found ",,'uixcom');
	return false; 
}

// Use to see if there's a valid mgr already in teh system. 
public function bool IsMgrRegistered( class<actor> kMgrClass )
{
	local XGScreenMgr kMgr;

		// IF we find a manager already activated, use the live one. 
	foreach m_arrScreenMgrs(kMgr)
	{
		if( kMgr.Class == kMgrClass )
			return true;
	}
	return false;
}
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             END DEPRECATED UI
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//----------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             GAME INTERFACE
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function bool IsGameplayOptionEnabled(int option) 
{
	return `GAME.m_arrSecondWave[option] > 0;
}

//----------------------------------------------------
//----------------------------------------------------

simulated function bool AllowSaving()
{
	return super.AllowSaving();
}

simulated function bool ISCONTROLLED()
{
	return `GAME.m_bControlledStart;
}

//----------------------------------------------------
//----------------------------------------------------
function PostFadeForBeginCombat()
{
}

simulated function OnPauseMenu(bool bOpened)
{
	
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             CAMERA INTERFACE
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function XComHeadquartersCamera GetCamera()
{
	return XComHeadquartersCamera(XComHeadquartersController(Owner).PlayerCamera);
}

simulated function bool CAMIsBusy()
{
	return m_kCamera != none && m_kCamera.IsBusy();
}

reliable client function CAMLookAtEarth( vector2d v2Location, optional float fZoom = 1.0f, optional float fInterpTime = 0.75f )
{
	XComHeadquartersCamera(XComHeadquartersController(Owner).PlayerCamera).NewEarthView(fInterpTime);
	`EARTH.SetViewLocation(v2Location);
	`EARTH.SetCurrentZoomLevel(fZoom);

	//m_kCamera.LookAtEarth( v2Location, fZoom, bCut );
	//GetCamera().FocusOnEarthLocation(v2Location, fZoom, fInterpTime);
}

reliable client function CAMSaveCurrentLocation()
{
	`EARTH.SaveViewLocation();
	`EARTH.SaveZoomLevel();
}

reliable client function CAMRestoreSavedLocation(optional float fInterpTime = 0.75f)
{
	`EARTH.RestoreSavedViewLocation();
	`EARTH.RestoreSavedZoomLevel(); //1.0f is the default zoom level
	if(ScreenStack.IsInStack(class'UIStrategyMap'))
	{
		XComHeadquartersCamera(XComHeadquartersController(Owner).PlayerCamera).NewEarthView(fInterpTime); //0.75 is the default interp time
	}
}

reliable client function CAMLookAt( vector vLocation, optional bool bCut )
{
	//m_kCamera.LookAt( vLocation, bCut );
}

// 1.0f is normal game zoom
reliable client function CAMZoom( float fZoom )
{
	m_kCamera.Zoom( fZoom );
}

reliable client function LookAtSelectedRoom(XComGameState_HeadquartersRoom RoomStateObject,
	optional float InterpTime = 2.0)
{
	local int GridIndex;
	local int RoomRow;
	local int RoomColumn;
	local string CameraName;
	local XComGameState_FacilityXCom FacilityStateObject;

	if (RoomStateObject.MapIndex >= 3 && RoomStateObject.MapIndex <= 14)
	{
		GridIndex = RoomStateObject.MapIndex - 3;
		RoomRow = (GridIndex / 3) + 1;
		RoomColumn = (GridIndex % 3) + 1;

		CameraName = "AddonCam" $ "_R" $ RoomRow $ "_C" $ RoomColumn;
	}
	else
	{
		FacilityStateObject =
			XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(RoomStateObject.Facility.ObjectID));
		CameraName = "UIDisplayCam_"$FacilityStateObject.GetMyTemplateName();
	}

	m_kFacilityGrid.LookAtSelectedRoom();
	GetCamera().SetInitialFocusToCamera(name(CameraName));
}
//<workshop> PARABOLIC_CAMERA_FACILITY_TRANSITION AMS 2015/11/05
//INS:
// NOTE_TO_INTEGRATOR: The sister function is CAMSetFacilityTransitionForRoom, all changes should be duplicated there.
//</workshop>

function CAMLookAtRoom(XComGameState_HeadquartersRoom RoomStateObject, optional float fInterpTime = 2, optional Vector ForceLocation, optional Rotator ForceRotation )
{	
	local int GridIndex;
	local int RoomRow;
	local int RoomColumn;
	local string CameraName;
	local XComGameState_FacilityXCom FacilityStateObject;
	local XComHeadquartersCheatManager CheatMgr;

	`log("CAMLookAtRoom" @ RoomStateObject @ fInterpTime, , 'DebugHQCamera');

	if( RoomStateObject.MapIndex >= 3 && RoomStateObject.MapIndex <= 14 )
	{
		//If this room is part of the build facilities grid, use the grid location
		//to look at it

		GridIndex = RoomStateObject.MapIndex - 3;
		RoomRow = (GridIndex / 3) + 1;
		RoomColumn = (GridIndex % 3) + 1;

		CAMLookAtHQTile( RoomColumn, RoomRow, fInterpTime, ForceLocation, ForceRotation );
	}
	else
	{
		FacilityStateObject = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(RoomStateObject.Facility.ObjectID));

		CheatMgr = XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager);
		if( CheatMgr != None && CheatMgr.bGamesComDemo && FacilityStateObject.GetMyTemplateName() == 'CommandersQuarters' )
		{
			CameraName = "UIDisplayCam_ResistanceScreen";
			`XCOMGRI.DoRemoteEvent('CIN_ShowCouncil');

			HideUIForCinematics();
			m_kUIMouseCursor.Hide();

			if( WorldInfo.RemoteEventListeners.Find(self) == INDEX_NONE )
			{
				WorldInfo.RemoteEventListeners.AddItem(self);
			}
		}
		else
		{
			CameraName = "UIDisplayCam_"$FacilityStateObject.GetMyTemplateName();
		}

		//This room is one of the default facilities, or special - use the custom named camera
		CAMLookAtNamedLocation(CameraName, ForceCameraInterpTime < 0.0f ? fInterpTime : ForceCameraInterpTime, , ForceLocation, ForceRotation);
	}
}

reliable client function CAMLookAtHorizon( vector2d v2LookAt )
{
	`log("CAMLookAtHorizon", , 'DebugHQCamera');
	m_kCamera.LookAtHorizon( v2LookAt );
}

// NOTE_TO_INTEGRATOR: The sister function is CAMSetFacilityTransitionForNamedLocation, all changes should be duplicated there.
reliable client function CAMLookAtNamedLocation( string strLocation, optional float fInterpTime = 2, optional bool bSkipBaseViewTransition, optional Vector ForceLocation, optional Rotator ForceRotation )
{
	// Pan Camera to active room
	`log("CAMLookAtNamedLocation" @ strLocation @ fInterpTime, , 'DebugHQCamera');
	GetCamera().StartRoomViewNamed(name(strLocation), ForceCameraInterpTime < 0.0f ? fInterpTime : ForceCameraInterpTime, bSkipBaseViewTransition, ForceLocation, ForceRotation);
}

//Use push/pop camera interp time within the same method, always
function PushCameraInterpTime(float NewValue)
{
	ForceCameraInterpTime = NewValue;
}

function PopCameraInterpTime()
{
	ForceCameraInterpTime = -1.0f;
}

// NOTE_TO_INTEGRATOR: The sister function is CAMSetFacilityTransitionForHQTile, all changes should be duplicated there.
// Look at an expansion tile
reliable client function CAMLookAtHQTile( int x, int y, optional float fInterpTime = 2, optional Vector ForceLocation, optional Rotator ForceRotation )
{
	local string strLocation, strRow, strColumn;
	`log("CAMLookAtHQTile" @ x @ y @ fInterpTime, , 'DebugHQCamera');

	strLocation = "AddonCam";

	strRow = "_R"$y;
	strColumn = "_C"$x;

	strLocation $= strRow;
	strLocation $= strColumn;

	// Pan Camera to specified base tile
	GetCamera().StartRoomViewNamed( name(strLocation), fInterpTime, ,ForceLocation, ForceRotation );
}


// PARABOLIC_CAMERA_FACILITY_TRANSITION AMS 2015/11/05
// FacilityTransition means we are moving from one facility to another in a camera swoop,
// in a parabolic fashion, with the 'Base' camera position in the middle.  It is required to
// look up the second facility we are moving to, so we can pre-calculate our camera path.
//INS:

// Sets the facility destination, based on the FacilityRef of the room we are moving to, and
// tell the camera that we are moving from the first facility towards the 'Base' camera position.
reliable client function SetFacilityTransition(StateObjectReference FacilityRef, bool Parabolic)
{
	`log("SetFacilityTransition "$FacilityRef.ObjectID, , 'DebugHQCamera');

	CAMSetFacilityTransitionForRoom(GetFacilityAvenger(FacilityRef).GetRoom());

	m_eParabolicFacilityTransitionType = FTT_Parabolic_In;
	m_bParabolic = Parabolic;

}

// Transitions between base to strategy map, or strategy map to base, require two camera transitions, so we call these from the triggered events.
reliable client function BeginGeoscapeCameraTransition()
{
	`log("XComHQPresentationLayer::BeginGeoscapeCameraTransition", , 'DebugHQCamera');
	m_bGeoscapeTransition = true;
}

// Transitions between base to strategy map, or strategy map to base, require two camera transitions, so we call these from the triggered events.
reliable client function EndGeoscapeCameraTransition()
{
	`log("XComHQPresentationLayer::EndGeoscapeCameraTransition", , 'DebugHQCamera');
	m_bGeoscapeTransition = false;
	ReachedFacilityTransition();
}

reliable client function OnCameraInterpolationComplete()
{
	local XComHeadquartersCamera Camera;

	Camera = GetCamera();
	`log("XComHQPresentationLayer::OnCameraInterpolationComplete" @ `ShowVar(m_bParabolic) @ `ShowVar(m_bGeoscapeTransition) @ `ShowVar(Camera.CurrentRoom), , 'DebugHQCamera');

	if (m_bParabolic) // From facility to 'base' to facility.
	{
		if (EnteringParabolicFacilityTransition()) // Halfway through the parabolic camera transition.
		{
			`log("was EnteringParabolicFacilityTransition", , 'DebugHQCamera');

			m_eParabolicFacilityTransitionType = FTT_Parabolic_Out; // Finished the first half of the parabola, now onto the second.

			PlayQueuedNarrative(); // Start playing the queued narrative now that we're half-way through the parabolic camera transition.
		}
		else if (`HQPRES.ExitingParabolicFacilityTransition()) // Finished the parabolic camera transition.
		{
			`log("was ExitingParabolicFacilityTransition", , 'DebugHQCamera');

			// The .001 seconds allow any processor-heavy UI initialization triggered by ReachedFacilityTransition to happen
			// next frame, so the camera can fully-reach the destination before any hitches occur.
			SetTimer(0.001f, false, 'ReachedFacilityTransition');
		}
	}
	else if (m_bGeoscapeTransition) // Transitions between base to strategy map, or strategy map to base, require special camera transitions.
	{
		m_kCamera.Camera().bHasOldCameraState = false; // Tell the HQCamera to stop interpolating, because the camera transition is done.

													   // Note: The call to ReachedFacilityTransform happens in EndGeoscapeCameraTransition().
	}
	else // From 'base' to facility.
	{
		// The .001 seconds allow any processor-heavy UI initialization triggered by ReachedFacilityTransition to happen
		// next frame, so the camera can fully-reach the destination before any hitches occur.
		SetTimer(0.001f, false, 'ReachedFacilityTransition');
	}
}

// Tells the camera we have reached the end of the facility transition.
reliable client function ReachedFacilityTransition()
{
	`log("ReachedFacilityTransition", , 'DebugHQCamera');

	// If there is a queued fade-to-black or movie, play it. 
	PlayQueuedNarrative();
	PlayQueuedListExpansions();
	PlayQueuedScreenMovie();

	m_eParabolicFacilityTransitionType = FTT_None;
	m_bParabolic = false;
	m_bQueueListExpansion = false;

	m_kCamera.Camera().bHasOldCameraState = false; // Tell the HQCamera to stop interpolating, because the camera transition is done.

												   //<workshop> RESOURCE_HEADER_DISPLAYING_IN_GEOSCAPE_FIX kmartinez 2016-06-15
												   //INS:
												   // We're updating the resources here, because we don't display them unless we're done transitioning.(kmartinez)
	m_kAvengerHUD.UpdateResources();
	`HQPRES.GetUIComm().RefreshAnchorListener();
	//</workshop>
}

reliable client function XComGameState_FacilityXCom GetFacilityAvenger(StateObjectReference FacilityRef)
{
	return XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
}

// Means the camera is swooping from the first facility to the 'Base' camera position. (First half of the parabola.)
reliable client function bool EnteringParabolicFacilityTransition()
{
	return m_bParabolic && m_eParabolicFacilityTransitionType == FTT_Parabolic_In;
}

// Means the camera has reached the 'Base' camera position and is swooping to the second facility. (Second half of the parabola.)
reliable client function bool ExitingParabolicFacilityTransition()
{
	return m_bParabolic && m_eParabolicFacilityTransitionType == FTT_Parabolic_Out;
}


// Block user input when the camera is transitioning or fullscreen video is playing.
reliable client function bool NonInterruptiveEventsOccurring()
{
	local XComHeadquartersCamera Camera;

	Camera = GetCamera();

	return m_bParabolic ||                                   // handles transition between rooms
		m_bGeoscapeTransition ||                             // handles transition to / from strategy map
		(Camera != None && (Camera.IsMoving() && Camera.bHasOldCameraState) &&
			Camera.CurrentRoom != 'UIDisplayCam_CIC' &&
			Camera.CurrentRoom != 'UIBlueprint_CustomizeMenu' &&
			Camera.CurrentRoom != 'UIBlueprint_CustomizeHead' &&
			Camera.CurrentRoom != 'UIBlueprint_CustomizeLegs' &&
			Camera.CurrentRoom != 'FacilityBuildCam' &&
			Camera.CurrentRoom != 'PreM_UIDisplayCam_SquadSelect' &&
			Camera.CurrentRoom != 'UIDisplayCam_ResistanceScreen' &&
			Camera.CurrentRoom != 'Base') ||                    // handle any camera movement to / from rooms
			(`XENGINE.IsAnyMoviePlaying() &&
				!class'XComEngine'.static.IsLoadingMoviePlaying()); // blocks HQ and screen input while a movie (other than the loading screen) is playing
}

// Because the new strategy camera code is suspected of a bug, this will help diagnose, in that case, why
// non-interruptive events are occurring, if indeed this system is the one blocking events.
reliable client function DiagnoseWhyNonInterruptiveEventsAreOccurring()
{
	local XComHeadquartersCamera Camera;
	local bool bCameraIsMoving;
	local bool bIsAnyMoviePlaying;

	Camera = GetCamera();
	bCameraIsMoving = Camera.IsMoving();
	bIsAnyMoviePlaying = `XENGINE.IsAnyMoviePlaying();
	`log("XXX DiagnoseWhyNonInterruptiveEventsAreOccurring" @ `ShowVar(m_bParabolic) @ `ShowVar(m_bGeoscapeTransition) @ `ShowVar(bCameraIsMoving) @ `ShowVar(Camera.bHasOldCameraState) @ `ShowVar(Camera) @ `ShowVar(Camera.CurrentRoom) @ `ShowVar(bIsAnyMoviePlaying));
}

function EventListenerReturn OnNarrativeEventTrigger(XComGameState_Objective Objective, Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local QueuedNarrative NewQueuedNarrative;

	`log("XComHQPresentationLayer::OnNarrativeEventTrigger:" @ Objective @ EventData @ EventSource @ GameState @ EventID, , 'DebugHQCamera');

	// If the camera is moving between facilities, queue it to play after the transition.
	// Otherwise, just play the fade.
	if (m_bParabolic)
	{
		NewQueuedNarrative.Objective = Objective;
		NewQueuedNarrative.EventData = EventData;
		NewQueuedNarrative.EventSource = EventSource;
		NewQueuedNarrative.GameState = GameState;
		NewQueuedNarrative.EventID = EventID;
		m_QueuedNarratives.AddItem(NewQueuedNarrative);

		`log("Adding Queued Narrative", , 'DebugHQCamera');
		return ELR_NoInterrupt;
		//</workshop>
	}

	return Objective.DoNarrativeEventTrigger(EventData, EventSource, GameState, EventID);
}

// Play all queued movies, then empty the queue.
simulated function PlayQueuedNarrative()
{
	local int i;
	local QueuedNarrative NewQueuedNarrative;

	`log("PlayQueuedNarrative", , 'DebugHQCamera');

	for (i = 0; i < m_QueuedNarratives.Length; ++i)
	{
		NewQueuedNarrative = m_QueuedNarratives[i];

		NewQueuedNarrative.Objective.DoNarrativeEventTrigger(NewQueuedNarrative.EventData, NewQueuedNarrative.EventSource, NewQueuedNarrative.GameState, NewQueuedNarrative.EventID);
	}
	m_QueuedNarratives.Length = 0;
}

// Show or hide avenger shortcut list, or all shortcuts, according to the arguments we stored.
// eCat - the index of the category tab
// bShow - if true, we are queuing a show; otherwise, we are queuing a hide
// bAllShortcuts - if true, show or hide all shortcuts; if false, just show or hide the list
simulated private function DoAvengerListExpansion(int eCat, bool bShow, bool bAllShortcuts)
{
	if (bShow)
	{
		if (bAllShortcuts)
			m_kAvengerHUD.Shortcuts.DoShow();
		else
			m_kAvengerHUD.Shortcuts.DoShowList(eCat);
	}
	else
	{
		if (bAllShortcuts)
			m_kAvengerHUD.Shortcuts.DoHide();
		else
			m_kAvengerHUD.Shortcuts.DoHideList();
	}
}

// Show avenger shortcut list, or queue the list expansion of the camera is in transit.
// eCat - the index of the category tab
// bShow - if true, we are queuing a show; otherwise, we are queuing a hide
// bAllShortcuts - if true, show or hide all shortcuts; if false, just show or hide the list
simulated function ShowAvengerShortcutList(int eCat, bool bShow, bool bAllShortcuts)
{
	local QueuedListExpansion NewQueuedListExpansion;

	`log("XComHQPresentationLayer::ShowAvengerShortcutList:" @ eCat, , 'DebugHQCamera');

	if (!bShow)
	{
		// Do the hiding now, since hiding should always be immediate, even if there's a 
		// camera transition.  However, queue it as well, since hides and shows often come in sets
		// and it may need to be reapplied to the end of a show-hide queue.
		DoAvengerListExpansion(eCat, bShow, bAllShortcuts);
	}

	// If the camera is moving between facilities, queue it to play after the transition.
	// Also, note m_bQueueListExpansion handles the case in which we select a new category the frame before
	// the camera transition has started, and the events still need to be queued.
	// Otherwise, just do the list expansion event.
	if (m_bQueueListExpansion || NonInterruptiveEventsOccurring())
	{
		NewQueuedListExpansion.eCat = eCat;
		NewQueuedListExpansion.bShow = bShow;
		NewQueuedListExpansion.bAllShortcuts = bAllShortcuts;
		m_QueuedListExpansions.AddItem(NewQueuedListExpansion);

		// Testing: 
		//   bShow - so we can set m_bAvengerListExpansionDone when list expansions are waiting to be done.
		//   NonInterruptiveEventsOccurring() - so this does not trigger during the loading screen and prevent loading.     
		if (bShow) // && NonInterruptiveEventsOccurring())
			m_bAvengerListExpansionDone = false;

		`log("Adding Queued List Expansion" @ NewQueuedListExpansion.eCat @ NewQueuedListExpansion.bShow @ NewQueuedListExpansion.bAllShortcuts, , 'DebugHQCamera');
		return;
	}

	// If not queued, just show or hide the list immediately.
	`log("Showing avenger shortcut list (non-queued)", , 'DebugHQCamera');
	if (bShow)
	{
		DoAvengerListExpansion(eCat, bShow, bAllShortcuts);
	}
	
	// If we are hiding shortcuts, clear out queued list expansions and unhighlight any shortcuts.
	if(!bAllShortcuts)
	{
		m_kAvengerHUD.Shortcuts.UnHighlightAllShortcuts();
		ClearQueuedListExpansions();
	}
}

simulated function ClearQueuedListExpansions()
{
	m_QueuedListExpansions.Length = 0;
}

// Play all queued avenger shortcut list expansions, then empty the queue.
simulated function PlayQueuedListExpansions()
{
	local int i;
	local QueuedListExpansion NewQueuedListExpansion;
	local bool bDoShowListFound;
	local bool bDoShowFound;

	`log("PlayQueuedListExpansions", , 'DebugHQCamera');

	// Optimize the m_QueuedListExpansions by filtering out all but the last DoShowList,
	// as it is the most expensive, and the index it takes indicates the index of the list 
	// item to be selected - obviously no more than one can be selected.
	// Also Remove all but the last DoShow.
	for (i = m_QueuedListExpansions.Length - 1; i >= 0; --i)
	{
		NewQueuedListExpansion = m_QueuedListExpansions[i];

		if (NewQueuedListExpansion.bShow && !NewQueuedListExpansion.bAllShortcuts)
		{
			if (!bDoShowListFound)
			{
				bDoShowListFound = true; // The last DoShowList of the list has been encountered.
			}
			else
			{
				m_QueuedListExpansions.Remove(i, 1); // A redundant DoShowList has been found, remove it.
			}
		}
		else if (NewQueuedListExpansion.bShow && NewQueuedListExpansion.bAllShortcuts)
		{
			if (!bDoShowFound)
			{
				bDoShowFound = true; // The last DoShow of the list has been encountered.
			}
			else
			{
				m_QueuedListExpansions.Remove(i, 1); // A redundant DoShow has been found, remove it.
			}
		}
	}

	for (i = 0; i < m_QueuedListExpansions.Length; ++i)
	{
		NewQueuedListExpansion = m_QueuedListExpansions[i];

		`log("Playing queued list expansion" @ NewQueuedListExpansion.eCat, , 'DebugHQCamera');
		DoAvengerListExpansion(NewQueuedListExpansion.eCat, NewQueuedListExpansion.bShow, NewQueuedListExpansion.bAllShortcuts);
	}
	m_QueuedListExpansions.Length = 0;

	// Allow .5 seconds for the list expansion to complete before triggering that it is done.
	if (!m_bAvengerListExpansionDone)
		SetTimer(0.5, false, 'TriggerAvengerListExpansionDone');
}

function TriggerAvengerListExpansionDone()
{
	`log("TriggerAvengerListExpansionDone", , 'DebugHQCamera');
	m_bAvengerListExpansionDone = true;
}

function bool CrewSpawningShouldWaitForPendingListExpansion()
{
	return !m_bAvengerListExpansionDone && !`XENGINE.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying();
}

// Notifies us when an Avenger shortcut tab is selected, so we can know whether to queue Avenger list expansion or not.
function SelectAvengerShortcut(int NewShortcutTab, int CurrentShortcutTab)
{
	// Queue list expansion events in this case, since we will be transition from one room to another within a frame or two.
	m_bQueueListExpansion = (NewShortcutTab != CurrentShortcutTab);
}

// Load a UI screen, or queue its loading while the camera is in transit.
// Screen - the UIScreen
// Movie - the Flash movie
simulated function LoadUIScreen(UIScreen Screen, UIMovie Movie)
{
	local UIFacility Facility;
	//local QueuedScreenMovie ScreenMovie;

	`log("LoadUIScreen" @ `ShowVar(Screen) @ `ShowVar(Movie), , 'DebugHQCamera');

	Facility = UIFacility(Screen);
	/*if (Facility != None && !Facility.bInstantInterp) //Disabled this change for instant transitions, as it broke many UIAlert callbacks - BET 2016-06-28
	{
	// Queue the loading and initialization of the UIScreen and the associated Flash movie.
	ScreenMovie.Facility = Facility;
	ScreenMovie.Movie = Movie;
	m_QueuedScreenMovies.AddItem(ScreenMovie);
	}
	else
	{*/
	ScreenStack.LoadUIScreen(Screen, Movie);
	/*}*/
	if (Facility != None) // bsg-dforrest (7.15.16): null access warnings
	{
		// Play the camera transition right away.
		Facility.HQCamLookAtThisRoom();
	}
}

// Play all queued screen movies, then empty the queue.
simulated function PlayQueuedScreenMovie()
{
	local int i;
	local QueuedScreenMovie ScreenMovie;

	`log("PlayQueuedScreenMovie", , 'DebugHQCamera');

	for (i = 0; i < m_QueuedScreenMovies.Length; ++i)
	{
		ScreenMovie = m_QueuedScreenMovies[i];

		`log("Playing queued ScreenMovie:" @ `ShowVar(ScreenMovie.Facility) @ `ShowVar(ScreenMovie.Movie), , 'DebugHQCamera');
		ScreenStack.LoadUIScreen(ScreenMovie.Facility, ScreenMovie.Movie);
	}
	m_QueuedScreenMovies.Length = 0;
}

// Gets all the camera properties of the second facility we are moving toward.
function GetFacilityTransition(out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha)
{
	out_Focus = m_ParabolicFacilityTransition_Focus;
	out_Rotation = m_ParabolicFacilityTransition_Rotation;
	out_ViewDistance = m_ParabolicFacilityTransition_ViewDistance;
	out_FOV = m_ParabolicFacilityTransition_FOV;
	out_PPSettings = m_ParabolicFacilityTransition_PPSettings;
	out_PPOverrideAlpha = m_ParabolicFacilityTransition_PPOverrideAlpha;
}

function X2Photobooth_StrategyAutoGen GetPhotoboothAutoGen()
{
	if (m_kPhotoboothAutoGen == none)
	{
		m_kPhotoboothAutoGen = Spawn(class'X2Photobooth_StrategyAutoGen', self);
		m_kPhotoboothAutoGen.Init();
	}

	return m_kPhotoboothAutoGen;
}

// NOTE: The sister function to CAMLookAtNamedLocation, except it sets the second facility camera properties.
reliable client function private CAMSetFacilityTransitionForNamedLocation(string strLocation)
{
	`log("CAMSetFacilityTransitionForNamedLocation" @ strLocation, , 'DebugHQCamera');

	GetCamera().GetViewFromCameraName(none, name(strLocation), m_ParabolicFacilityTransition_Focus, m_ParabolicFacilityTransition_Rotation, m_ParabolicFacilityTransition_ViewDistance, m_ParabolicFacilityTransition_FOV, m_ParabolicFacilityTransition_PPSettings, m_ParabolicFacilityTransition_PPOverrideAlpha);
}

// NOTE: The sister function to CAMLookAtHQTile, except it sets the second facility camera properties.
reliable client function private CAMSetFacilityTransitionForHQTile(int x, int y)
{
	local string strLocation, strRow, strColumn;


	`log("CAMSetFacilityTransitionForHQTile" @ x @ y, , 'DebugHQCamera');

	strLocation = "AddonCam";

	strRow = "_R"$y;
	strColumn = "_C"$x;

	strLocation $= strRow;
	strLocation $= strColumn;

	// Pan Camera to specified base tile
	GetCamera().GetViewFromCameraName(none, name(strLocation), m_ParabolicFacilityTransition_Focus, m_ParabolicFacilityTransition_Rotation, m_ParabolicFacilityTransition_ViewDistance, m_ParabolicFacilityTransition_FOV, m_ParabolicFacilityTransition_PPSettings, m_ParabolicFacilityTransition_PPOverrideAlpha);
}

// NOTE: The sister function to CAMLookAtRoom, except it sets the second facility camera properties.
reliable client function private CAMSetFacilityTransitionForRoom(XComGameState_HeadquartersRoom RoomStateObject)
{
	local int GridIndex;
	local int RoomRow;
	local int RoomColumn;
	local string CameraName;
	local XComGameState_FacilityXCom FacilityStateObject;

	`log("CAMSetFacilityTransitionForRoom" @ RoomStateObject, , 'DebugHQCamera');

	if (RoomStateObject.MapIndex >= 3 && RoomStateObject.MapIndex <= 14)
	{
		//If this room is part of the build facilities grid, use the grid location
		//to look at it

		GridIndex = RoomStateObject.MapIndex - 3;
		RoomRow = (GridIndex / 3) + 1;
		RoomColumn = (GridIndex % 3) + 1;

		CAMSetFacilityTransitionForHQTile(RoomColumn, RoomRow);
	}
	else
	{
		FacilityStateObject = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(RoomStateObject.Facility.ObjectID));

		CameraName = "UIDisplayCam_"$FacilityStateObject.GetMyTemplateName();

		//This room is one of the default facilities, or special - use the custom named camera
		CAMSetFacilityTransitionForNamedLocation(CameraName);
	}
}
//</workshop>


defaultproperties
{
	m_eUIMode = eUIMode_Strategy;
	m_bIsShuttling = false;
	m_bCanPause = true;
	ForceCameraInterpTime = -1.0

	m_bExitFromSimCombat = false

	fCameraSwoopDelayTime = -1.0
	m_bAvengerListExpansionDone = true;

	// hack to prevent hitchiness in Geoscape view
	m_overworldCursorMesh = StaticMesh'XB0_XCOM2_OverworldIcons.IconSelection''

}
