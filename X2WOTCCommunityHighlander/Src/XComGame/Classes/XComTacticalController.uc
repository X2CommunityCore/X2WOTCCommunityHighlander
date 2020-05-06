//=============================================================================
// XComTacticalController
// XCom specific playercontroller
// PlayerControllers are used by human players to control pawns.
//
// Copyright 1998-2008 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class XComTacticalController extends XComPlayerController
	implements(X2VisualizationMgrObserverInterfaceNative)
	dependson(XComPathData)
	native(Core)
	config(Game);

// NOTE: make sure this stays in sync with XGAction_BeginMove::MAX_REPLICATED_PATH_POINTS -tsmith 
const MAX_REPLICATED_PATH_POINTS = 128;

//=======================================================================================
//X-Com 2 Refactoring
//
var StateObjectReference ControllingPlayer;
var XGPlayer ControllingPlayerVisualizer;

var StateObjectReference ControllingUnit;
var XGUnit ControllingUnitVisualizer;

//Cached values to avoid re-creating these objects for each pathing call
var array<PathingInputData> PathInput; 
//=======================================================================================

var XGPlayer      		                m_XGPlayer;
var protected XGUnit	                m_kActiveUnit;
var bool                                m_bCamIsMoving;
var bool                                m_bInCinematicMode;
var bool                                m_bShowLootVisuals;
var protectedwrite int                  m_iBloodlustMove;

var int iCurrentLevel;
var array<Actor> aLvl1;
var array<Actor> aLvl2;
var array<Actor> aLvl3;
var array<Actor> aLvl4;

struct native transient CoverCheck
{
	var array<Vector> aRaysHit;
	var array<Vector> aRaysMissed;
	var vector vSourcePoint;
};

var localized string                            m_strPsiInspired;
var localized string                            m_strBeenPsiInspired;

var transient bool                               m_bGridComponentHidden;
var transient bool                               m_bGridComponentDashingHidden;

//var float m_fAnalogAccel;
//var float m_fAnalogDecel;

var bool                                        m_bInputInShotHUD;
var bool                                        m_bInputSwitchingWeapons;

var privatewrite float                          m_fLastReplicateMoveSentTimeSeconds;
var const float                                 m_fThrottleReplicateMoveTimeSeconds;

var privatewrite bool           m_bRankedMatchStartedFlagWritten;
var privatewrite bool           m_bRoundEnded;
var bool                        m_bConnectionFailedDuringGame;
var bool                        m_bReturnToMPMainMenu;
var bool                        m_bIsCleaningUpGame;
var bool                        m_bHasCleanedUpGame;
var bool                        m_bHasEndedSession;
var bool                        m_bPingingMCP;
var bool                        m_bAttemptedGameInvite;

var XComPathingPawn             m_kPathingPawn;

// for locking position and orientation of debug camera
var TPOV vDebugStaticPOV;
var bool bLockDebugCamera;
var bool bDebugMode;

// Lets us know if we just manually switched units, in which case we may not want to focus the camera on the unit when the visualizer becomes idle
var bool bManuallySwitchedUnitsWhileVisualizerBusy;
var bool bJustSwitchedUnits;
var privatewrite float m_fLastMagAnalogInput;
var privatewrite int m_iNumFramesPressed;
var privatewrite int m_iNumFramesReleased;
var privatewrite TTile m_InitialCursorTile;
var privatewrite TTile m_TargetCursorTile;
var privatewrite bool m_bStartedWalking;
var privatewrite bool m_bQuickInterpolate;
var privatewrite bool m_bChangedUnitHasntMovedCursor; // If the Unit has changed (L1 or R1) but the cursor hasn't moved yet.  Hide the cursor until movement begins.
var config float TacticalCursorInitialStepAmount;
var config float TacticalCursorAccel;
var config float TacticalCursorDeadzone;
var config float TacticalCursorStickAccelPower;
var config float TacticalCursorTileAlignBlendFast;
var config float TacticalCursorTileAlignBlendSlow;
var config int TacticalCursorFramesBeforeAccel;

cpptext
{
	/** called on the server when the client sends a message indicating it was unable to initialize an Actor channel,
	 * most commonly because the desired Actor's archetype couldn't be serialized
	 * the default is to do nothing (Actor simply won't exist on the client), but this function gives the game code
	 * an opportunity to try to correct the problem
	 */
	virtual void NotifyActorChannelFailure(UActorChannel* ActorChan);

	virtual UBOOL IsInCinematicMode();

	/**
	 * In tactical matches, we will spawn an X2Camera_Matinee on the camera stack to handle
	 * matinee playback. The simplest (and most robust) way to prevent the normal matinee camera takeover
	 * is just to prevent the director track from ever being set.
	 */
	virtual void SetControllingDirector( UInterpTrackInstDirector* NewControllingDirector ) { ControllingDirTrackInst = NULL; }
}

//-----------------------------------------------------------
//-----------------------------------------------------------
replication
{
	if( bNetDirty && Role == Role_Authority )
		m_XGPlayer, m_iBloodlustMove;
}

native function XCom3DCursor GetCursor();
native function float GetCursorAccel();
native function float GetCursorDecel();

//=======================================================================================
//X-Com 2 Refactoring
//

/// <summary>
/// Sets the cached variables that associate this PlayerController object with a player
/// state-visualizer pair.
/// </summary>
function SetControllingPlayer( XComGameState_Player PlayerState )
{
	ControllingPlayer = PlayerState.GetReference();
	ControllingPlayerVisualizer = XGPlayer(PlayerState.GetVisualizer());

	//@TODO - rmcfall - remove this legacy variable and replace with ControllingPlayerVisualizer
	m_XGPlayer = ControllingPlayerVisualizer;
}

/// <summary>
/// This method invorms the controller that it needs to give up control over units. Usually done as a result
/// of a player finishing their unit actions phase.
/// </summary>
simulated function Visualizer_ReleaseControl()
{
	local array<XComGameState_Unit> Units;	
	local int CurrentSelectedIndex;
	local bool bAllowSelectAllActive;

	//Mark all units we control as inactive
	ControllingPlayerVisualizer.GetUnits(Units);
	for( CurrentSelectedIndex = 0; CurrentSelectedIndex < Units.Length; ++CurrentSelectedIndex )
	{
		XGUnit(Units[CurrentSelectedIndex].GetVisualizer()).GotoState('Inactive');
	}

	//Sets the state of XComTacticalInput, which maps mouse/kb/controller inputs to game engine methods
	bAllowSelectAllActive = `CHEATMGR != None && `CHEATMGR.bAllowSelectAll;
	if( !bAllowSelectAllActive )
	{
		SetInputState('Multiplayer_Inactive');
	}

	// Reseting this to 0 stops the ability containers getting updated for a unit that is just going to be switched off of again
	ControllingUnit.ObjectID = 0;

	GetPres().UpdateConcealmentShader(true);
}

function ClearActiveUnit()
{
	m_kActiveUnit = none;
}

/// <summary>
/// This method marks the indicated unit state's visualizer as 'active'. This is a purely visual designation,  
/// guiding the Unit's 3d UI, camera behavior, etc.
/// Returns true if the unit could be selected
/// </summary>
simulated function bool Visualizer_SelectUnit(XComGameState_Unit SelectedUnit)
{
	//local GameRulesCache_Unit OutCacheData;
	local XComGameState_Player PlayerState;
	local XGPlayer PlayerVisualizer;
	local XCom3DCursor kCursor;
	local bool bUnitWasAlreadySelected;

	if (SelectedUnit.GetMyTemplate().bNeverSelectable) //Somewhat special-case handling Mimic Beacons, which need (for gameplay) to appear alive and relevant
	{
		return false;
	}

	if( SelectedUnit.GetMyTemplate().bIsCosmetic ) //Cosmetic units are not allowed to be selected
	{
		return false;
	}

	if (SelectedUnit.ControllingPlayerIsAI())
	{
		// Update concealment markers when AI unit is selected because the PathingPawn is hidden and concealment tiles won't update so it remains visible
		m_kPathingPawn.UpdateConcealmentTiles();
	}

	if (SelectedUnit.bPanicked && !(`CHEATMGR != None && `CHEATMGR.bAllowSelectAll)) //Panicked units are not allowed to be selected
		return false;

	//Dead, unconscious, and bleeding-out units should not be selectable.
	if (SelectedUnit.IsDead() || SelectedUnit.IsIncapacitated())
		return false;

	if(!`TACTICALRULES.AllowVisualizerSelection())
		return false;

	/* jbouscher - allow free form clicks to select units with no moves remaining
	if( (`CHEATMGR == None || !`CHEATMGR.bAllowSelectAll) )
	{
		// verify that this unit has moves left
		`TACTICALRULES.GetGameRulesCache_Unit(SelectedUnit.GetReference(), OutCacheData);
		if(!OutCacheData.bAnyActionsAvailable)
		{
			return false;
		}
	}
	*/	
	bUnitWasAlreadySelected = (SelectedUnit.ObjectID == ControllingUnit.ObjectID);

	`PRES.ShowFriendlySquadStatistics();

	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(SelectedUnit.ControllingPlayer.ObjectID));
	PlayerVisualizer = XGPlayer(PlayerState.GetVisualizer());

	//@TODO - rmcfall - twiddling the old game play code to make it behave. Should the visualizer have this state?
	if( ControllingUnitVisualizer != none )
	{
		ControllingUnitVisualizer.Deactivate();
	}

	bJustSwitchedUnits = true;
	//Set our local cache variables for tracking what unit is selected
	ControllingUnit = SelectedUnit.GetReference();
	ControllingUnitVisualizer = XGUnit(SelectedUnit.GetVisualizer());

	//Support legacy variables
	m_kActiveUnit = ControllingUnitVisualizer;

	// Set the bFOWTextureBufferIsDirty to be true
	`XWORLD.bFOWTextureBufferIsDirty = true;

	//@TODO - rmcfall - evaluate whether XGPlayer should be involved with selection
	PlayerVisualizer.SetActiveUnit( XGUnit(SelectedUnit.GetVisualizer()) );

	//@TODO - rmcfall - the system here is twiddling the old game play code to make it behavior. Think about a better way to interact with the UI / Input.
	if(`XENGINE.IsMultiplayerGame())
	{ 
		// TTP#394: multiplayer games cannot pass true in as it will set the input state to active for the non controlling player.
		SetInputState('ActiveUnit_Moving', false); //Sets the state of XComTacticalInput, which maps mouse/kb/controller inputs to game engine methods		
	}
	else
	{
		SetInputState('ActiveUnit_Moving', true); //Sets the state of XComTacticalInput, which maps mouse/kb/controller inputs to game engine methods		
	}
	ControllingUnitVisualizer.GotoState('Active'); //The unit visualizer 'Active' state enables pathing ( adds an XGAction_Path ), displays cover icons, etc.	
	kCursor = XCom3DCursor( Pawn );
	kCursor.MoveToUnit( m_kActiveUnit.GetPawn() );
	m_bChangedUnitHasntMovedCursor = true;
	kCursor.SetPhysics( PHYS_Flying );
	//kCursor.SetCollision( false, false );
	kCursor.bCollideWorld = false;
	if(GetStateName() != 'PlayerWalking' && GetStateName() != 'PlayerDebugCamera')
	{   
		GotoState('PlayerWalking');
	}

	// notify the visualization manager that the unit changed so that UI etc. listeners can update themselves.
	// all of the logic above us should eventually be refactored to operate off of this callback
	`XCOMVISUALIZATIONMGR.NotifyActiveUnitChanged(SelectedUnit);
	
	// Check to trigger any tutorial moment events when selecting a new unit
	CheckForTutorialMoments(SelectedUnit);

	if( !bUnitWasAlreadySelected )
	{
		SelectedUnit.DisplayActionPointInfoFlyover();
	}

	return true;
}

simulated function CheckForTutorialMoments(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_CampaignSettings CampaignSettings;
	local XComGameState_Unit DazedUnit;
	local XComGameState_MissionSite MissionState;
	local StateObjectReference UnitRef, BondmateRef;
	local XComKeybindingData kKeyData;
	local string key, label;
	
	History = `XCOMHISTORY;
	CampaignSettings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	kKeyData = `PRES.m_kKeybindingData;
	if (CampaignSettings != none && !CampaignSettings.bSuppressFirstTimeNarrative)
	{
		if (`XENGINE.IsSinglePlayerGame() && !(`ONLINEEVENTMGR.bIsChallengeModeGame))
		{
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			if (XComHQ != none)
			{
				MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
				if (!XComHQ.bHasSeenTacticalTutorialTargetPreview && MissionState.GetMissionSource().DataName == 'MissionSource_GuerillaOp')
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tactical Tutorial Target Preview");
					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.bHasSeenTacticalTutorialTargetPreview = true;
					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
					
					if (`ISCONTROLLERACTIVE)
					{
						label = class'XLocalizedData'.default.TargetPreviewTutorialControllerText;
					}
					else
					{
						key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(PlayerInput, eTBC_ToggleEnemyPreview);
						label = Repl(class'XLocalizedData'.default.TargetPreviewTutorialText, "%TARGET_BINDING", key);
					}

					class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(
						class'XLocalizedData'.default.TargetPreviewTutorialTitle,
						label,
						class'UIUtilities_Image'.static.GetTutorialImage_TargetPreview());
				}

				if (!XComHQ.bHasSeenTacticalTutorialDazed)
				{
					foreach XComHQ.Squad(UnitRef)
					{
						DazedUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
						if (DazedUnit != none && DazedUnit.IsDazed())
						{
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tactical Tutorial Dazed");
							XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForDazedTutorial;

							XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
							XComHQ.bHasSeenTacticalTutorialDazed = true;

							`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

							class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(
								class'XLocalizedData'.default.DazedTutorialTitle,
								class'XLocalizedData'.default.DazedTutorialText,
								class'UIUtilities_Image'.static.GetTutorialImage_Dazed());

							break; // Only show the popup once
						}
					}
				}

				if (!XComHQ.bHasSeenTacticalTutorialSoldierBonds && UnitState.HasSoldierBond(BondmateRef))
				{
					foreach XComHQ.Squad(UnitRef)
					{
						if (UnitRef.ObjectID == BondmateRef.ObjectID)
						{
							// The bondmate is also in the squad, so trigger the tutorial event and flag XComHQ that the tutorial has been shown
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tactical Tutorial Soldier Bonds");
							XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForSoldierBondTutorial;

							XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
							XComHQ.bHasSeenTacticalTutorialSoldierBonds = true;

							`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

							class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(
								class'XLocalizedData'.default.SoldierBondTutorialTitle,
								class'XLocalizedData'.default.SoldierBondTutorialText,
								class'UIUtilities_Image'.static.GetTutorialImage_SoldierBonds());

							break;
						}
					}
				}

				if (!XComHQ.bHasSeenTacticalTutorialTrackingShot && UnitState.IsUnitAffectedByEffectName('TrackingShotMarkTargetEffect'))
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tactical Tutorial Chosen Hunter Tracking Shot");
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForTrackingShotTutorial;

					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.bHasSeenTacticalTutorialTrackingShot = true;

					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

					class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(
						class'XLocalizedData'.default.TrackingShotTutorialTitle,
						class'XLocalizedData'.default.TrackingShotTutorialText,
						class'UIUtilities_Image'.static.GetTutorialImage_TrackingShot());
				}

				if (!XComHQ.bHasSeenTacticalTutorialReaper && (UnitState.GetMyTemplateName() == 'ReaperSoldier' || UnitState.GetMyTemplateName() == 'LostAndAbandonedElena'))
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tactical Tutorial Reaper");
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForReaperTutorial;

					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.bHasSeenTacticalTutorialReaper = true;

					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

					class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(
						class'XLocalizedData'.default.ReaperTutorialTitle,
						class'XLocalizedData'.default.ReaperTutorialText,
						class'UIUtilities_Image'.static.GetTutorialImage_Reaper());
				}
				else if (!XComHQ.bHasSeenTacticalTutorialTemplar && UnitState.GetMyTemplateName() == 'TemplarSoldier')
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tactical Tutorial Templar");
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForTemplarTutorial;

					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.bHasSeenTacticalTutorialTemplar = true;

					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

					class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(
						class'XLocalizedData'.default.TemplarTutorialTitle,
						class'XLocalizedData'.default.TemplarTutorialText,
						class'UIUtilities_Image'.static.GetTutorialImage_Templar());
				}
				else if (!XComHQ.bHasSeenTacticalTutorialTemplarMomentum && UnitState.GetMyTemplateName() == 'TemplarSoldier' && UnitState.ActionPoints.Find('Momentum') != INDEX_NONE)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tactical Tutorial Templar");
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForTemplarMomentumTutorial;

					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.bHasSeenTacticalTutorialTemplarMomentum = true;

					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

					class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(
						class'XLocalizedData'.default.TemplarMomentumTutorialTitle,
						class'XLocalizedData'.default.TemplarMomentumTutorialText,
						class'UIUtilities_Image'.static.GetTutorialImage_TemplarMomentum());
				}
				else if (!XComHQ.bHasSeenTacticalTutorialSkirmisher && (UnitState.GetMyTemplateName() == 'SkirmisherSoldier' || UnitState.GetMyTemplateName() == 'LostAndAbandonedMox'))
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tactical Tutorial Skirmisher");
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForSkirmisherTutorial;

					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.bHasSeenTacticalTutorialSkirmisher = true;

					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

					class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(
						class'XLocalizedData'.default.SkirmisherTutorialTitle,
						class'XLocalizedData'.default.SkirmisherTutorialText,
						class'UIUtilities_Image'.static.GetTutorialImage_Skirmisher());
				}
			}
		}
	}
}

static function BuildVisualizationForSoldierBondTutorial(XComGameState VisualizeGameState)
{
	BuildVisualizationForTutorial(VisualizeGameState, XComNarrativeMoment'XPACK_NarrativeMoments.X2_XP_CEN_T_First_Bond_Zone');
}

static function BuildVisualizationForDazedTutorial(XComGameState VisualizeGameState)
{
	BuildVisualizationForTutorial(VisualizeGameState, XComNarrativeMoment'XPACK_NarrativeMoments.X2_XP_CEN_T_Tutorial_Dazed_And_Revived');
}

static function BuildVisualizationForTrackingShotTutorial(XComGameState VisualizeGameState)
{
	BuildVisualizationForTutorial(VisualizeGameState, XComNarrativeMoment'XPACK_NarrativeMoments.X2_XP_CEN_T_Tutorial_Hunter_Tracking_Shot');
}

static function BuildVisualizationForReaperTutorial(XComGameState VisualizeGameState)
{
	BuildVisualizationForTutorial(VisualizeGameState, XComNarrativeMoment'XPACK_NarrativeMoments.X2_XP_VLK_T_How_To_Use_Reaper');
}

static function BuildVisualizationForTemplarTutorial(XComGameState VisualizeGameState)
{
	BuildVisualizationForTutorial(VisualizeGameState, XComNarrativeMoment'XPACK_NarrativeMoments.X2_XP_KAL_T_How_To_Use_Templar');
}

static function BuildVisualizationForTemplarMomentumTutorial(XComGameState VisualizeGameState)
{
	BuildVisualizationForTutorial(VisualizeGameState, XComNarrativeMoment'XPACK_NarrativeMoments.X2_XP_KAL_T_First_Templar_Focus');
}

static function BuildVisualizationForSkirmisherTutorial(XComGameState VisualizeGameState)
{
	BuildVisualizationForTutorial(VisualizeGameState, XComNarrativeMoment'XPACK_NarrativeMoments.X2_XP_BET_T_How_To_Use_Skirmisher');
}

static function BuildVisualizationForTutorial(XComGameState VisualizeGameState, XComNarrativeMoment NarrMoment)
{
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlayNarrative NarrativeAction;

	NarrativeAction = X2Action_PlayNarrative(class'X2Action_PlayNarrative'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	NarrativeAction.Moment = NarrMoment;
	NarrativeAction.WaitForCompletion = false;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_BaseObject', ActionMetadata.StateObject_OldState)
	{
		break;
	}

	ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
}

/// <summary>
/// Out of a list of units eligible for selection, selects the one that is immediately next in the list to the currently selected unit in the specified direction
/// </summary>
simulated function bool Visualizer_CycleToNextAvailableUnit(int Direction)
{	
	local array<XComGameState_Unit> EligibleUnits;
	local XComGameState_Unit SelectNewUnit;	
	local XComGameState_Unit CurrentUnit;	
	local bool bActionsAvailable;
	local int NumGroupMembers, MemberIndex, CurrentUnitIndex;
	local X2TacticalGameRuleset TacticalRules;

	if (`TUTORIAL != none)
	{
		// Disable unit cycling in tutorial
		return false;
	}

	TacticalRules = `TACTICALRULES;

	if( (`CHEATMGR != None && `CHEATMGR.bAllowSelectAll) )
	{
		ControllingPlayerVisualizer.GetUnitsForAllPlayers(EligibleUnits);
	}
	else
	{
		ControllingPlayerVisualizer.GetUnits(EligibleUnits,,true);
	}

	//Not allowed to switch if the currently controlled unit is being forced to take an action next
	CurrentUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ControllingUnit.ObjectID));
	if (CurrentUnit != none && CurrentUnit.ReflexActionState == eReflexActionState_SelectAction )
	{
		return false;
	}

	NumGroupMembers = EligibleUnits.Length;

	CurrentUnitIndex = Clamp(EligibleUnits.Find(CurrentUnit), 0, NumGroupMembers - 1);

	for( MemberIndex = 1; MemberIndex < NumGroupMembers; ++MemberIndex )
	{
		SelectNewUnit = EligibleUnits[(NumGroupMembers + CurrentUnitIndex + MemberIndex * Direction) % NumGroupMembers];

		bActionsAvailable = TacticalRules.UnitHasActionsAvailable(SelectNewUnit);
		// Force all units to be selectable regardless of action points, if AllowSelectAll is on.
		if ((`CHEATMGR != None && `CHEATMGR.bAllowSelectAll))
		{
			bActionsAvailable = true;
		}

		if( bActionsAvailable && Visualizer_SelectUnit(SelectNewUnit) )
		{
			return true;
		}
	}

	return false;
}

/// <summary>
/// Out of a list of units eligible for selection, selects the one that is immediately next in the list to the currently selected unit
/// </summary>
simulated function bool Visualizer_SelectNextUnit()
{
	return Visualizer_CycleToNextAvailableUnit(1);
}

/// <summary>
/// Out of a list of units eligible for selection, selects the one that is immediately previous to the currently selected unit
/// </summary>
simulated function bool Visualizer_SelectPreviousUnit()
{
	return Visualizer_CycleToNextAvailableUnit(-1);
}

simulated function PlaceEvacZone()
{
	local int AbilityHudIndex;
	AbilityHudIndex = `Pres.GetTacticalHUD().m_kAbilityHUD.GetAbilityIndexByName(
			class'CHHelpers'.static.GetPlaceEvacZoneAbilityName());  // Issue #855
	if(AbilityHudIndex > -1)
	{
		`Pres.GetTacticalHUD().m_kAbilityHUD.SelectAbility( AbilityHudIndex );
	}
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationBlockComplete(XComGameState AssosciatedState);

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
event OnVisualizationIdle()
{	
	local XComGameStateHistory History;
	local XComGameState_Unit ControllingUnitState;
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit OutCacheData;	
	local int ActionIndex;
	local AvailableAction CheckAction;
	local bool bAvailableInputAction;

	Ruleset = `XCOMGAME.GameRuleset;
	History = `XCOMHISTORY;

	// if we're in tactical but it's not actually our turn, we shouldn't really bother
	if ((X2TacticalGameRuleset(Ruleset) != none) &&
		(X2TacticalGameRuleset(Ruleset).GetCachedUnitActionPlayerRef().ObjectID != ControllingPlayerVisualizer.ObjectID))
	{
		return;
	}

	// set the new active player, or reenable the current active player.
	bAvailableInputAction = false;
	if (ControllingUnit.ObjectID > 0)
	{
		ControllingUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ControllingUnit.ObjectID));
		if (ControllingUnitState != None && !ControllingUnitState.IsPanicked())
		{
			Ruleset.GetGameRulesCache_Unit(ControllingUnit, OutCacheData);
			for (ActionIndex = 0; ActionIndex < OutCacheData.AvailableActions.Length; ++ActionIndex)
			{
				CheckAction = OutCacheData.AvailableActions[ActionIndex];
				if (CheckAction.bInputTriggered && CheckAction.AvailableCode == 'AA_Success')
				{
					bAvailableInputAction = true;
					break;
				}
			}
		}
	}

	if (!`REPLAY.bInTutorial)
	{
		if (!bAvailableInputAction)
		{
			//Switch control to the next unit if the current one has no actions left
			Visualizer_SelectNextUnit();
		}
		else
		{
			if (!bManuallySwitchedUnitsWhileVisualizerBusy)
			{
				//Switch control to the next unit if the current one has no actions left
				Visualizer_SelectUnit(ControllingUnitState);
			}

			// Force the UI to update when a visualization block ends
			if( `PRES.m_kTacticalHUD != none )
				`PRES.m_kTacticalHUD.Update();
		}
	}

	bManuallySwitchedUnitsWhileVisualizerBusy = false;
}
//=======================================================================================

/**
 * Override this function to draw to the HUD after calling AddHUDOverlayActor(). 
 * Script function called by NativePostRenderFor().
*/
simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local Vector vScreenPos;
	
	if(CheatManager != none && XComTacticalCheatManager(CheatManager).bDebugInputState)
	{
		vScreenPos.X = kCanvas.ClipX * 0.1;
		vScreenPos.Y = kCanvas.ClipY * 0.8;
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
		kCanvas.SetDrawColor(0, 255, 0, 255);
		kCanvas.DrawText("Controller state: " $ GetStateName());
		vScreenPos.Y += 15.0f;
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
		kCanvas.DrawText("Input state: " $ PlayerInput.GetStateName());
		vScreenPos.Y += 15.0f;
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
		kCanvas.DrawText("Player state: " $ m_XGPlayer.GetStateName());
	}
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated function XComPresentationLayer GetPres()
{
	return XComPresentationLayer(Pres);
}


// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
/*  jbouscher - REFACTORING CHARACTERS
reliable client function ClientPHUDLevelUp(XGCharacter_soldier kSoldier)
{
	// NOTE: since this an RPC any data that will be shown for this unit that has been changed on the server
	// needs to be passed to this RPC as a parameter. this is because the data may not have replicated to the 
	// client's unit when this RPC executes on said client.-tsmith 
	XComPresentationLayer(Pres).PHUDLevelUp(kSoldier);
}
*/

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated function bool IsBusy()
{
	return Pres == none || XComPresentationLayer(Pres).UIIsBusy() /*|| XComPresentationLayer(Pres).CAMIsBusy()*/ || XComPresentationLayer(Pres).Get2DMovie().DialogBox.TopIsModal();
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated function XComUnitPawn GetActiveUnitPawn()
{
	if( m_kActiveUnit == none )
		return none;

	return m_kActiveUnit.GetPawn();
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------

function vector GetCursorPosition()
{
	return Pawn.Location;
}

reliable client function ClientSetCursorLocation(Vector vLocation)
{
	GetCursor().SetLocation(vLocation);
}

function bool IsControllerPressed()
{
	return m_iNumFramesPressed > 0;
}
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated function ActiveUnitChanged()
{
	PlayUnitSelectSound();

	if (m_kActiveUnit != none)
	{
		m_kActiveUnit.Activate();
	}

	XComTacticalInput(PlayerInput).CancelMousePathing();
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated function SetInputState( name nStateName, optional bool bForce )
{
	if( bForce || !`REPLAY.bInReplay || `REPLAY.bInTutorial )
	{
		XComTacticalInput( PlayerInput ).GotoState( nStateName,, true );
	}
}

simulated function name GetInputState()
{
	return XComTacticalInput( PlayerInput ).GetStateName();
}

/*
exec function AnimIdleState(int num)
{
	XComWeapon(GetActivePawn().Weapon).SetAnimIdleState(EWeaponAnimIdleState(num));
}*/

/** Inits online stats object */
simulated event PostBeginPlay()
{
	local XComGameStateVisualizationMgr VisualizationManager;
	Super.PostBeginPlay();

	m_kPathingPawn = Spawn(class'XComPathingPawn');

	VisualizationManager = `XCOMVISUALIZATIONMGR;
	VisualizationManager.RegisterObserver(self);
}

// this is called from PostBeginPlay of player controller.
// for now, we want it to use the camera mode that we specify in our
// default properties of XComCamera, so we just tell this to do nothing
event ResetCameraMode()
{

}

simulated function XComUnitPawn GetActivePawn()
{
	if (ControllingUnitVisualizer == none)
		return none;

	return ControllingUnitVisualizer.GetPawn();
}

simulated function XGUnit GetActiveUnit()
{
	return ControllingUnitVisualizer;
}

simulated function StateObjectReference GetActiveUnitStateRef()
{	
	return ControllingUnit;
}

/**
 * Unregisters any game specific datastores
 */
simulated function UnregisterPlayerDataStores()
{
	Super.UnregisterPlayerDataStores();
}

exec function PlayUnitOnMoveSound()
{
	if(IsLocalPlayerController())
	{
		Pawn.PlaySound(SoundCue'SoundUI.SelectLocationCue', true);
	}
}

exec function PlayUnitSelectSound()
{
	if(IsLocalPlayerController())
	{
		Pawn.PlaySound(SoundCue'SoundUI.SelectSingleUnitCue', true);
	}
}

exec function SetCameraYaw(float fDegrees)
{
}

exec function YawCamera(float fDegrees)
{
	XComCamera(PlayerCamera).YawCamera(fDegrees);
}

exec function ZoomCamera(float fAmount)
{
	XComCamera(PlayerCamera).ZoomCamera(fAmount);
}

event Possess(Pawn aPawn, bool bVehicleTransition)
{
	super.Possess(aPawn, bVehicleTransition);
}

exec function ToggleDramaticCameras()
{
	GetPres().ToggleDramaticCameras();
}

exec function ToggleDebugCamera()
{
	if( !class'Engine'.static.IsRetailGame() || class'Engine'.static.IsConsoleAllowed() )
	{	
		if (!IsInState('PlayerDebugCamera'))
		{
			PushState('PlayerDebugCamera');
			bDebugMode = true;
		}
	}
}

// lock camera position and orientation for debugging
exec function LockDebugCamera(float x, float y, float z, int pitch, int yaw, int roll)
{
	if( !class'Engine'.static.IsRetailGame() || class'Engine'.static.IsConsoleAllowed() )
	{	
		if (!IsInState('PlayerDebugCamera'))
		{
			PushState('PlayerDebugCamera');
			bDebugMode = false;
		}

		vDebugStaticPOV.Location.X = x;
		vDebugStaticPOV.Location.Y = y;
		vDebugStaticPOV.Location.Z = z;
		vDebugStaticPOV.Rotation.Pitch = pitch;
		vDebugStaticPOV.Rotation.Yaw = yaw;
		vDebugStaticPOV.Rotation.Roll = roll;
		bLockDebugCamera = true;
	}
}

exec function UnLockDebugCamera();

// output current camera position and orientation
exec function LogCamPOV()
{
	local TPOV CurrentPOV;

	if( !class'Engine'.static.IsRetailGame() || class'Engine'.static.IsConsoleAllowed() )
	{		
		CurrentPOV = XComCamera(PlayerCamera).CameraCache.POV;

		// can copy this output from the ouput console and paste in developer's console
		`log("LockDebugCamera" @ CurrentPOV.Location.X @ CurrentPOV.Location.Y @ CurrentPOV.Location.Z
								@ CurrentPOV.Rotation.Pitch @ CurrentPOV.Rotation.Yaw @ CurrentPOV.Rotation.Roll);
	}
}

function DrawDebugLabels(Canvas kCanvas)
{
	local XGUnit kUnit;
	local XGAIGroup DisplayGroup;
	local XComSpawnRestrictor Restrictor;
	local X2CharacterTemplate CharacterTemplate;
	local Name CharacterTemplateName;
//	local XGAbility_BullRush kAb;
	//local Actor tempActor;
	if (`BATTLE == none)
		return;

	if (CheatManager != none && `XCOMHISTORY.GetNumGameStates() > 0 )
	{
		`BATTLE.DrawDebugLabel(kCanvas);
				
		`XCOMGAME.GameRuleset.DrawDebugLabel(kCanvas);
		`XCOMHISTORY.DrawDebugLabel(kCanvas);		
		`CAMERASTACK.DrawDebugLabel(kCanvas);		

		if (XComTacticalCheatManager(CheatManager).bShowActions || 
			XComTacticalCheatManager(CheatManager).bShowShieldHP ||
			XComTacticalCheatManager(CheatManager).bDebugConcealment ||
			XComTacticalCheatManager(CheatManager).bShowAIVisRange
			)
		{
			foreach worldinfo.AllActors(class'XGUnit', kUnit) 
			{
				if (XComTacticalCheatManager(CheatManager).m_DebugAnims_TargetName == kUnit.Name
					|| XComTacticalCheatManager(CheatManager).m_DebugAnims_TargetName == '')
					kUnit.DrawDebugLabel(kCanvas);
			}
		}

		if( XComTacticalCheatManager(CheatManager).bDebugPatrols )
		{
			foreach WorldInfo.AllActors(class'XGAIGroup', DisplayGroup) 
			{
				DisplayGroup.DrawDebugLabel(kCanvas);
			}
		}

		if(XComTacticalCheatManager(CheatManager).bDebugPodReveals)
		{
			XComTacticalCheatManager(CheatManager).DrawPodRevealDecisionInformation(kCanvas);
		}

		if (`BATTLE.GetAIPlayer() != none)
			XGAIPlayer(`BATTLE.GetAIPlayer()).DrawDebugLabel(kCanvas);
		
		if( XComTacticalCheatManager(CheatManager).bDebugPatrols )
		{
			`SPAWNMGR.DrawDebugLabel(kCanvas);

			if( XComTacticalCheatManager(CheatManager).DebugSpawnIndex < 0 )
			{
				foreach WorldInfo.AllActors(class'XGUnit', kUnit) 
				{
					if( XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kUnit.ObjectID)).GetMyTemplate().bIsTurret )
					{
						kUnit.DrawSpawningDebug(kCanvas, (XComTacticalCheatManager(CheatManager).DebugSpawnIndex == -1) );
					}
				}
			}

			CharacterTemplateName = XComTacticalCheatManager(CheatManager).ShowRestrictorsForCharacterTemplate;
			if( CharacterTemplateName != '' )
			{
				CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CharacterTemplateName);
				foreach WorldInfo.AllActors(class'XComSpawnRestrictor', Restrictor)
				{
					// we only want to draw the spawn restrictors that restrict this template type
					if( Restrictor.TemplateRestricted(CharacterTemplate) )
					{
						Restrictor.DrawDebugVolume(kCanvas);
					}
				}
			}
		}
			
		// Start Issue #490
		//
		// Allow mods to draw their own debug labels to the screen.
		`XEVENTMGR.TriggerEvent('DrawDebugLabels', kCanvas, self);
		// End Issue #490
	}
}

function DrawDebugData( HUD H )
{
	local Vector vPos;
	local XComTacticalCheatManager kTacticalCheatManager;
	local XComBuildingVolume kBuilding;
	local TTile tTile;
	local Vector vScreenPos;
	local Actor A;
	local LightComponent L;

	kTacticalCheatManager = XComTacticalCheatManager(CheatManager);
	if(kTacticalCheatManager != none)
	{
		DrawDebugLabels(H.Canvas);
		if (kTacticalCheatManager.bShowDropship)
		{
			vPos = `LEVEL.GetDropship().Location;
			vPos.Z += `METERSTOUNITS(3);
			DrawDebugLine(`LEVEL.GetDropship().Location, vPos, 255,255,255 );
		}

		if (kTacticalCheatManager.bShowCursorLoc)
		{
			`SHAPEMGR.DrawSphere (GetCursorPosition(), Vect(10,10,10), MakeLinearColor(0,1.0f,0,1.0f));

			H.Canvas.SetPos(100, 690);
			H.Canvas.SetDrawColor(255,255,255);
			H.Canvas.DrawText("Cursor @ ("$GetCursorPosition()$")");
			H.Canvas.SetPos(100, 705);
			vPos = GetCursorPosition();
			tTile = `XWORLD.GetTileCoordinatesFromPosition(vPos);
			H.Canvas.DrawText("("$tTile.X$","$tTile.Y$","$tTile.Z$")");
		}

		if (kTacticalCheatManager.bShowCursorFloor)
		{
			vPos = GetCursorPosition();
			`XWORLD.GetFloorTileForPosition(vPos, tTile, true);
			vPos = `XWORLD.GetPositionFromTileCoordinates(tTile);
			`SHAPEMGR.DrawSphere (vPos, Vect(10,10,10), MakeLinearColor(0,1.0f,0,1.0f));

			H.Canvas.SetPos(100, 690);
			H.Canvas.SetDrawColor(255,255,255);

			if (`LEVEL.IsInsideBuilding(GetCursorPosition(), kBuilding))
				H.Canvas.DrawText("Cursor @ ("$GetCursorPosition()$")" @ "Inside : "@kBuilding);
			else
				H.Canvas.DrawText("Cursor @ ("$GetCursorPosition()$")" @ " - no building volume.");
		}

		if(CheatManager != none && XComCheatManager(CheatManager).bLightDebugMode && XComCheatManager(CheatManager).bLightDebugRealtime)
		{
			foreach AllActors(class'Actor', A)
			{
				vScreenPos = H.Canvas.Project(A.Location);
				foreach A.AllOwnedComponents(class'LightComponent', L)
				{	
					H.Canvas.SetPos(vScreenPos.X, vScreenPos.Y);
					if(L.bEnabled)
					{
						H.Canvas.SetDrawColor(255, 0, 0, 255);
						H.Canvas.DrawText(L @ "Owner:" @ A @ "Location:" @ L.GetOrigin().X @ L.GetOrigin().Y @ L.GetOrigin().Z @ "Enabled:" @ L.bEnabled);
						DrawDebugSphere(L.GetOrigin(), 25, 10, 255, 0, 0, false);
					}						
					else
					{
						H.Canvas.SetDrawColor(0, 0, 255, 255);
						H.Canvas.DrawText(L @ "Owner:" @ A @ "Location:" @ L.GetOrigin().X @ L.GetOrigin().Y @ L.GetOrigin().Z @ "Enabled:" @ L.bEnabled);
						DrawDebugSphere(L.GetOrigin(), 25, 10, 0, 0, 255, false);
					}
					vScreenPos.Y += 15.0f;
				}
			}
		}
	}
}

simulated function bool PerformPath(XGUnit kUnit, optional bool bUserCreated=false)
{
	local bool bSuccess;
	// Prevent adding a second move for a unit already in motion
	//if (`XCOMVISUALIZATIONMGR.IsSelectedActorMoving())
	if (kUnit.m_bIsMoving || (`TUTORIAL != none && !`TUTORIAL.IsInState('WaitForPlayerInput')))
	{
		return false;
	}

	if(m_kPathingPawn.PathTiles.Length > 1)
	{
		bSuccess = GameStateMoveUnitSingle(kUnit, m_kPathingPawn.PathTiles, bUserCreated, LatentSubmitGameStateContextCallback);
		if (bSuccess)
		{
			m_kPathingPawn.ClearAllWaypoints();
			m_kPathingPawn.ShowConfirmPuckAndHide();
			kUnit.m_bIsMoving = TRUE;
		}
	}
	else
	{
		return false;
	}

	return bSuccess;
}

function protected LatentSubmitGameStateContextCallback(XComGameState GameState)
{
}

simulated function vector GetStranglerLookAtPoint( XGUnit kTarget )
{
	local vector vLoc, vDir;
	vLoc = kTarget.Location;
	vDir = Normal(Vector(kTarget.GetPawn().Rotation));
	vLoc -= (vDir * 64);
	return vLoc;
}


/// <summary>
/// Utility method for moving just a single unit
/// </summary>
function bool GameStateMoveUnitSingle(XGUnit kUnit, 
	array<TTile> TilePath, 
	optional bool bUserCreated = false, 
	optional delegate<X2GameRuleset.LatentSubmitGameStateContextCallbackFn> ActivationCallback)
{
	local PathingInputData PathData;
	local StateObjectReference MovingUnitRef;
	local XComGameStateHistory History;
	local XComGameState_Unit MovingUnit;
	local TTile Destination;
	local int Index;
	local array<XComGameState_Unit> AttachedUnits;
	local XGUnit CosmeticUnitVisualizer;

	History = `XCOMHISTORY;

	MovingUnit = XComGameState_Unit(History.GetGameStateForObjectID(kUnit.ObjectID));

	PathInput.Length = 0;
	MovingUnitRef.ObjectID = kUnit.ObjectID;
	PathData.MovingUnitRef = MovingUnitRef;
	PathData.MovementTiles = TilePath;
	m_kPathingPawn.GetWaypointTiles(PathData.WaypointTiles);
	PathInput.AddItem(PathData);

	Destination = TilePath[TilePath.Length - 1];

	// Move gremlin if we have one (or two, specialist receieving aid protocol) attached to us 
	MovingUnit.GetAttachedUnits(AttachedUnits);

	for (Index = 0; Index < AttachedUnits.Length; Index++)
	{
		if (AttachedUnits[Index] != none)
		{
			TilePath.Remove(0, TilePath.Length);
			CosmeticUnitVisualizer = XGUnit(AttachedUnits[Index].GetVisualizer());
			CosmeticUnitVisualizer.bNextMoveIsFollow = true;

			Destination.Z += MovingUnit.GetDesiredZTileOffsetForAttachedCosmeticUnit();

			CosmeticUnitVisualizer.m_kReachableTilesCache.BuildPathToTile(Destination, TilePath);

			if (TilePath.Length == 0)
			{
				class'X2PathSolver'.static.BuildPath(AttachedUnits[Index], AttachedUnits[Index].TileLocation, Destination, TilePath);
			}

			PathData.MovementTiles = TilePath;
			PathData.MovingUnitRef.ObjectID = AttachedUnits[Index].ObjectID;
			PathInput.AddItem(PathData);
		}
	}

	return GameStateMoveUnit(kUnit, PathInput, bUserCreated, ActivationCallback);
}

static function CreatePathDataForPathTiles(out PathingInputData PathData)
{
	local XComGameStateHistory History;
	local XGUnit MovingUnit;
	local XComGameState_Unit UnitState;
	local XComWorldData WorldData;
	local XComDestructibleActor PathObject;
	local int i;
	local int Mobility, MoveCost;

	// TODO: Move values computed here to the result context. This is a halfway point while movement is being refactored to make
	// melee movement cleaner to implement

	//Cache whether this path was a dashing move or not
	History = `XCOMHISTORY;

	WorldData = class'XComWorldData'.static.GetWorldData();

	MovingUnit = XGUnit(History.GetVisualizer(PathData.MovingUnitRef.ObjectID));
	Mobility = MovingUnit.GetMobility();
	MoveCost = 1;
	PathData.Destructibles.Length = 0;
	PathData.CostIncreases.Length = 0;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(PathData.MovingUnitRef.ObjectID));

	for(i = 0; i < PathData.MovementTiles.Length; ++i)
	{
		if (MovingUnit.m_kReachableTilesCache.GetPathCostToTile(PathData.MovementTiles[i]) > Mobility * MoveCost)
		{
			PathData.CostIncreases.AddItem(i);
			MoveCost++;
		}

		if (i > 0)
		{
			PathObject = XComDestructibleActor(WorldData.GetPathObjectFromTraversalToNeighbor(PathData.MovementTiles[i - 1], PathData.MovementTiles[i], UnitState.GetMyTemplate().UnitSize > 1));
			//Only store objects that should be destroyed during movement.
			if (PathObject != none && PathObject.IsInState('_Pristine'))
			{
				PathData.Destructibles.AddItem(i);
			}
		}
	}

	//Convert path tiles into the path points
	class'X2PathSolver'.static.GetPathPointsFromPath(UnitState, PathData.MovementTiles, PathData.MovementData);

	//Run string pulling on the path points
	class'XComPath'.static.PerformStringPulling(MovingUnit, PathData.MovementData, PathData.WaypointTiles);
}

/// <summary>
/// Build a context for unit movement and send it off to the Rules Engine
/// </summary>
function bool GameStateMoveUnit(XGUnit kUnit, 
	array<PathingInputData> MovementPaths, 
	optional bool bUserCreated=false,
	optional delegate<X2GameRuleset.LatentSubmitGameStateContextCallbackFn> ActivationCallback,
	optional delegate<XComGameStateContext_Ability.MergeVisualizationDelegate> MergeVisualizationFn)
{	
	local XComGameStateContext_Ability StateChangeContainer;
	local X2GameRuleset RuleSet;	
	local XComGameState_Ability UnitAbility;
	local XComGameState_Unit UnitState;	
	local StateObjectReference AbilityRef;
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local PathingInputData PathData;
	local int PathIndex;
	local PathingResultData PathResultData;
	local int OutSimultaneousMoveIndex;
	local int OutInsertVisualizationFence;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kUnit.ObjectID));	
	AbilityRef = UnitState.FindAbility('StandardMove');
	UnitAbility = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

	`assert(UnitAbility != none);

	//Build the context for the move ability
	StateChangeContainer = XComGameStateContext_Ability(class'XComGameStateContext_Ability'.static.CreateXComGameStateContext());
	StateChangeContainer.InputContext.AbilityRef = UnitAbility.GetReference();
	StateChangeContainer.InputContext.AbilityTemplateName = UnitAbility.GetMyTemplateName();
	StateChangeContainer.InputContext.SourceObject = UnitState.GetReference();

	// Codex/avatar golden path narrative triggers
	if (UnitState.GetMyTemplate().CharacterGroupName == 'Cyberus')
	{
		`XEVENTMGR.TriggerEvent('CodexFirstAction', UnitAbility, UnitState, StateChangeContainer.AssociatedState);
	}
	else if (UnitState.GetMyTemplate().CharacterGroupName == 'AdvPsiWitchM3' || UnitState.GetMyTemplate().CharacterGroupName == 'AdvPsiWitchM2')
	{
		`XEVENTMGR.TriggerEvent('AvatarFirstAction', UnitAbility, UnitState, StateChangeContainer.AssociatedState);
	}

	for(PathIndex = 0; PathIndex < MovementPaths.Length; ++PathIndex)
	{
		//Copy to temp to satisfy UC reference rules		
		PathData = MovementPaths[PathIndex]; 

		// fill out extra input data
		CreatePathDataForPathTiles(PathData); 
		StateChangeContainer.InputContext.MovementPaths.AddItem(PathData);
				
		// fill out the result context for each movement path
		class'X2TacticalVisibilityHelpers'.static.FillPathTileData(MovementPaths[PathIndex].MovingUnitRef.ObjectID, MovementPaths[PathIndex].MovementTiles, PathResultData.PathTileData);
		StateChangeContainer.ResultContext.PathResults.AddItem(PathResultData);
	}

	//Set visualization scheduling vars. These allow the move to be performed simultaneously with other moves or actions.
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));
	if(PlayerState != none)
	{
		XGPlayer(PlayerState.GetVisualizer()).GetSimultaneousMoveVisualizeIndex(UnitState, kUnit, OutSimultaneousMoveIndex, OutInsertVisualizationFence);
		
		if(!PlayerState.IsAIPlayer() && XComGameInfo(WorldInfo.Game).MyAutoTestManager == none) //The autotest mgr submits moves like the AI, so check for it as well
		{
			//Indicate whether this ability's visualization can happen in an order independent way, unless there is an end move ability or the unit is panicking
			if(!UnitState.IsPanicked() && !UnitState.GetMyTemplate().bIsCosmetic)
			{
				StateChangeContainer.SetVisualizationOrderIndependent(true);
			}
		}

		StateChangeContainer.SetVisualizationStartIndex(OutSimultaneousMoveIndex);

		StateChangeContainer.MergeVisualizationFn = MergeVisualizationFn;
	}

	// Have the context sent across the network if the move was initiated by a user action
	if( bUserCreated )
	{
		StateChangeContainer.SetSendGameState(true);
	}

	RuleSet = `XCOMGAME.GameRuleset;
	`assert(RuleSet != none);

	if(ActivationCallback != none)
	{
		RuleSet.LatentSubmitGameStateContext(StateChangeContainer, ActivationCallback);
	}
	else
	{
		Ruleset.SubmitGameStateContext(StateChangeContainer);
	}

	StateChangeContainer.SetSendGameState(false);

	return true;
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated function bool PerformEndTurn(EPlayerEndTurnType eEndTurnType)
{
	// Aural feedback for player input
	if(eEndTurnType == ePlayerEndTurnType_PlayerInput)
	{
		PlaySound(SoundCue'SoundUI.PositiveUISelctionCue', true, true);
	}

	if(WorldInfo.NetMode == NM_Standalone || eEndTurnType != ePlayerEndTurnType_PlayerInput)
	{
		return InternalPerformEndTurn(eEndTurnType);
	}
	else
	{
		ShowEndTurnDialog();
		return true;
	}
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated private function bool InternalPerformEndTurn(EPlayerEndTurnType eEndTurnType)
{
	local bool bEndTurnResult;

	// MHU - Not safe to directly set the inputstate here, the game might not be ready to handle the endturn yet.
	//       Instead, allow the player to attempt an endturn, and if it succeeds, THEN clear our input state.
	// SetInputState('');

	bEndTurnResult = m_XGPlayer.EndTurn(eEndTurnType);

	if (bEndTurnResult)
	{
		//`CAMERAMGR.ClearLookAts();      //  don't let a lookat on the current unit get stuck
		// clear the input state so nothing can be done while the turn switches -tsmith 
		SetInputState('');		
	}

	return bEndTurnResult;
}


// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated function ShowEndTurnDialog()
{
	local TDialogueBoxData      kDialogData;
	
	kDialogData.eType       = eDialog_Normal;
	kDialogData.strTitle	= class'UIUtilities_Text'.default.m_strMPPlayerEndTurnDialog_Title;
	kDialogData.strText     = class'UIUtilities_Text'.default.m_strMPPlayerEndTurnDialog_Body; 
	kDialogData.strAccept   = class'UIUtilities_Text'.default.m_strGenericConfirm; 
	kDialogData.strCancel   = class'UIUtilities_Text'.default.m_strGenericCancel; 
	kDialogData.fnCallback  = EndTurnDialogueCallback;

	Pres.UIRaiseDialog( kDialogData );
}

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated private function EndTurnDialogueCallback(Name eAction)
{
	if(!`BATTLE.IsTurnTimerCloseToExpiring(2.0f))
	{
		if (eAction == 'eUIAction_Accept')
		{
			InternalPerformEndTurn(ePlayerEndTurnType_PlayerInput);
		}
	}
}
//-----------------------------------------------------------
//-----------------------------------------------------------
//@TODO - pmiller - delete this function
function PerformEquip(XGUnit kUnit, int iSlotFrom)	{}

//-----------------------------------------------------------
//-----------------------------------------------------------
//@TODO - pmiller - delete this function
function PerformUnequip(XGUnit kUnit)	{}

//------------------------------------------------------------------------------------------------
function Actor TestForCoverCollision( vector vStart, vector vDir, out vector HitLocation, out vector HitNormal, float fRange )
{
	local Actor				HitActor;
	local TraceHitInfo		HitInfo;

	// for now, we fire a trace along the direction to see where we should aim.
	HitActor = Trace(HitLocation, HitNormal, vStart + (vDir * fRange), vStart, TRUE, vect(0,0,0), HitInfo, TRACEFLAG_PhysicsVolumes | TRACEFLAG_Blocking);
	if ( (HitActor != None) && (!HitActor.IsA('XComUnitPawn')) )
		return HitActor;
	return None;
}
//------------------------------------------------------------------------------------------------
/*
simulated function int GetCoverBitsAt(vector vPoint)
{
	local ClimbOverPoint kPoint;
	return GetCover(vPoint, kPoint, m_kActiveUnit.GetPawn());
}


//------------------------------------------------------------------------------------------------
simulated function int CursorLocHasCover()
{
	return GetCoverBitsAt(GetCursor().Location);
}
*/

//------------------------------------------------------------------------------------------------
function Vector GetGroundPosition(Vector vPoint )
{
	local vector vHitLoc, vNormal;
	local float fDropRange;
	fDropRange = 128;

	if ( Trace( vHitLoc, vNormal, vPoint + vect(0,0,-1) * fDropRange, vPoint, false ) != none )
	{
		return vHitLoc;
	}
	return vPoint;
}
//------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------
// Checks if the unit animation to enter cover has just been performed.
simulated function bool IsInCover()
{
	// Check last action done.
	return m_kActiveUnit.IsInCover();
}


simulated function XComLadder FindLadder( optional int iRadius = 96, optional int iMaxHeightDiff = 100)
{
	return XComTacticalGRI(WorldInfo.GRI).FindLadder(GetCursor().Location, iRadius, iMaxHeightDiff);
}

/*
simulated function CoverInfo FindCover(optional float Radius = 256.0f)
{
	local array<CoverInfo> Infos;
	local CoverInfo Info;
	local int Index;
	local float BestDistance;
	local float Distance;

	`BATTLE.m_kLevel.GetCoverInfos(GetCursor().Location, Radius, Infos);

	BestDistance = 9999999.0;

	for (Index = 0; Index < Infos.Length; Index++)
	{
		Distance = VSizeSq2D(Infos[Index].Link.GetSlotLocation(Infos[Index].SlotIdx) - GetCursor().Location);
		if (Distance < BestDistance) 
		{
			BestDistance = Distance;
			Info = Infos[Index];
		}
	}

	return Info;
}
*/


//-----------------------------------------------------------
//-----------------------------------------------------------
reliable client function ClientFailedSwitchWeapon()
{
	m_bInputSwitchingWeapons = false;
}

event BeginState(Name PreviousStateName)
{
	//`log("XComTacticalController.uc, BeginState"@GetStateName()@"from"@PreviousStateName);
}

event EndState(Name NextStateName)
{
	//`log("XComTacticalController.uc, EndState"@GetStateName()@"to"@NextStateName);
}

//#################################################################################
//							STATE CODE
//#################################################################################

//--------------------------------- DEBUG CAM MODE ------------------------------
simulated state PlayerDebugCamera
{
	exec function ToggleDebugCamera()
	{
		PopState();
		bDebugMode = false;
	}

	event PushedState()
	{
		local float FOV;

		super.PushedState();

		PlayerCamera.ClearAllCameraShakes();

		// field of view before changing state may be different from debug cam
		FOV = XComCamera(PlayerCamera).GetFOVAngle();
		
		XComCamera(PlayerCamera).PushState('DebugView');

		// lock camera with previous camera's POV
		XComCamera(PlayerCamera).SetFOV(FOV);
		bLockDebugCamera = false;
	}

	event PoppedState()
	{
		super.PoppedState();

		`log("Jake's Debug Camera Direction" @ vector(XComCamera(PlayerCamera).CameraCache.POV.Rotation), , 'XComCameraMgr');

		XComCamera(PlayerCamera).SetFOV(0); // unlock the FOV
		XComCamera(PlayerCamera).PopState();
	}

	exec function UnLockDebugCamera() 
	{
		bLockDebugCamera = false;
		if(!bDebugMode) 
		{
			PopState();
		}
	}
}

//--------------------------------- MOVE MODE ------------------------------
simulated state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;

	event NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		if( Pawn == None )
		{
			return;
		}

		if (Role == ROLE_Authority)
		{
			// Update ViewPitch for remote clients
			Pawn.SetRemoteViewPitch( Rotation.Pitch );
		}

		Pawn.Acceleration = NewAccel;

		if(/*!IsZero(NewAccel) || !IsZero(Pawn.Velocity)*/ `BATTLE != None && !`BATTLE.IsAlienTurn() && (VSize(NewAccel) > 1 || VSize(Pawn.Velocity) > 1))
		{
			// The cursor moved, so it should be the focus of the camera
			if(Pres != none)
			{
				//`CAMERAMGR.OnCursorMoved();
				//XComPresentationLayer(Pres).CAMSetView( GetCursor().GetCurrentView() );
			}
		}
	}

	//INS:
	event BeginState(Name PreviousStateName)
	{
		m_bStartedWalking = true;
		
		super.BeginState(PreviousStateName);
	}
	function PlayerMove( float DeltaTime )
	{
		local vector X,Y,Z, NewAccel;//, vOldVel;
		local float fMagAnalogInput;
		local XCom3DCursor kCursor;
		local float StickPowerScale;
		local vector JustPressedDir;
		//local XComInputBase XComInput;
		local float LSAxisX;
		local float LSAxisY;
		//local float fAngle;
		local TTile CursorTile;
		local vector CursorTileCenter;
		local vector OffsetToCursorTileCenter;
		local UITacticalHUD_AbilityContainer kHUD;
		local bool bLog;
		local bool bSmooth; // Smooth movement, versus snappy movement.
		local Vector JustPressedDirNormalized;
		local Vector Offset;

		bLog = false;
		bSmooth = true;
		
		kCursor = XCom3DCursor( Pawn );

		if( Pawn == None )
		{
			GotoState('Dead');
		}
		else
		{

			// Dont scroll the "Move" cursor around the map while gameplay is paused (or currently active unit is panicked)
			if( IsBusy() || (m_kActiveUnit != none && m_kActiveUnit.IsPanicked()) ) // || GetActiveUnit().GetAction().BlocksInput()) // MHU - Uncomment the latter to block cursor movement if action is busy.
			{
				Pawn.Acceleration = vect(0,0,0);
				Pawn.Velocity = vect(0,0,0);
				return;
			}

			GetAxes(XComCamera(PlayerCamera).CameraStack.GetCameraLocationAndOrientation().Rotation, X, Y, Z);

			// make the XY vectors parallel to the ground
			X.Z = 0;
			Y.Z = 0;
			X = Normal(X);
			Y = Normal(Y);

		
			// We were using aForward and aStrafe.  We now use raw input values for platform independence, but 
			// correct for the amount the previous values were being scaled with 1.7573578512.
			LSAxisX = PlayerInput.RawJoyUp * 1.7573578512;
			LSAxisY = PlayerInput.RawJoyRight * 1.7573578512;

			JustPressedDir = LSAxisX*X + LSAxisY*Y;
			JustPressedDir.Z = 0;
			fMagAnalogInput = VSize(JustPressedDir);

			//`log("XXX fMagAnalogInput =" @ fMagAnalogInput @ "LSAxisX =" @ LSAxisX @ "LSAxisY =" @ LSAxisY);			

			if (`XWORLD != none)
				CursorTile = `XWORLD.GetTileCoordinatesFromPosition(kCursor.Location);
			
			// Tally the number of frames the L-analog stick has been pressed.
			if (fMagAnalogInput >= TacticalCursorDeadzone)
			{
				m_iNumFramesPressed++;
				m_iNumFramesReleased = 0;
			}
			else
			{
				m_iNumFramesPressed = 0;
				m_iNumFramesReleased++;
			}

			if (m_bStartedWalking)
			{
				if (bLog) `log("XXX PlayerWalking STARTED WALKING");

				m_bStartedWalking = false;

				m_TargetCursorTile = CursorTile;
			}

			//TODO(AMS): Move this to XComCursor.cpp

			kHUD = `Pres.GetTacticalHUD() != none ? `Pres.GetTacticalHUD().m_kAbilityHUD : none;

			// Use 'smooth' movement if bSmooth is true, or we're using a grenade.
			if(bSmooth || (kHUD.GetTargetingMethod() != none && kHUD != none && kHUD.GetTargetingMethod().Action.bFreeAim))
			{
				if (fMagAnalogInput >= TacticalCursorDeadzone) // When L-analog stick is pressed in some direction.
				{
					// Normalize.
					if( fMagAnalogInput != 0.0 )
						JustPressedDirNormalized = JustPressedDir / fMagAnalogInput;

					if (m_bChangedUnitHasntMovedCursor)
					{
						m_bChangedUnitHasntMovedCursor = false;
						
						// Move the cursor in the direction we just pressed.
						Offset = JustPressedDirNormalized * TacticalCursorInitialStepAmount;

						if(!`ISCONTROLLERACTIVE)
						{
							kCursor.MoveToUnitWithOffset( m_kActiveUnit.GetPawn(), Offset);
						}

						NewAccel.X = 0;
						NewAccel.Y = 0;
						NewAccel.Z = 0;
						Pawn.AccelRate = 0;

						Pawn.Velocity.X = 0;
						Pawn.Velocity.Y = 0;
						Pawn.Velocity.Z = 0;
					}
					else
					{
						// Correct for deadzone.
						JustPressedDir = JustPressedDirNormalized * ((fMagAnalogInput - TacticalCursorDeadzone) / (1.0 - TacticalCursorDeadzone));
						fMagAnalogInput = VSize(JustPressedDir);

						Pawn.AccelRate = TacticalCursorAccel;

						StickPowerScale = (abs(fMagAnalogInput) ** (TacticalCursorStickAccelPower - 1.0));

						NewAccel = JustPressedDir * StickPowerScale;
						NewAccel.Z = 0.0;
						NewAccel = Pawn.AccelRate * NewAccel;
					}
				}
				else // Slow when L-analog is released.
				{
					Pawn.AccelRate = 0;

					Pawn.Velocity.X = 0;
					Pawn.Velocity.Y = 0;
					Pawn.Velocity.Z = 0;
				}
			}
			else // Prototype the cursor smoothly returning to the center of the tile if analog stick is not pressed for one second.
			{
				if (fMagAnalogInput >= TacticalCursorDeadzone) // When L-analog stick is pressed in some direction.
				{
					// Correct for deadzone.
					JustPressedDir = JustPressedDir / fMagAnalogInput;
					JustPressedDir = JustPressedDir	* ((fMagAnalogInput - TacticalCursorDeadzone) / (1.0 - TacticalCursorDeadzone));
					fMagAnalogInput = VSize(JustPressedDir);

					Pawn.AccelRate = TacticalCursorAccel;

					StickPowerScale = (abs(fMagAnalogInput) ** (TacticalCursorStickAccelPower - 1.0));

					NewAccel = JustPressedDir * StickPowerScale;
					NewAccel.Z = 0.0;
					NewAccel = Pawn.AccelRate * NewAccel;
				}
				else // Slow when L-analog is released.
				{
					Pawn.AccelRate = 0;

					Pawn.Velocity = Pawn.Velocity * (1.0 - GetCursorDecel() * DeltaTime);
				}

				if (m_iNumFramesReleased >= 30)
				{
					CursorTileCenter = `XWORLD.GetPositionFromTileCoordinates(CursorTile);
					OffsetToCursorTileCenter = CursorTileCenter - kCursor.Location;

					Pawn.Velocity.X = 0;
					Pawn.Velocity.Y = 0;
					Pawn.Velocity.Z = 0;
					kCursor.m_vInitialCursorPressMovement = OffsetToCursorTileCenter * FMin(1.0, float(m_iNumFramesReleased - 30) * DeltaTime * TacticalCursorTileAlignBlendSlow);
				}
			}
			m_fLastMagAnalogInput = fMagAnalogInput;


			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DCLICK_None, rotator("0, 0, 0"));
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DCLICK_None, rotator("0, 0, 0"));
			}
		}
	}

	event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);

		if ( Pawn != None )
		{
			Pawn.SetRemoteViewPitch( 0 );
		}
	}
}

//--------------------------------- FIRING MODE ------------------------------

simulated state PlayerAiming
{
	event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
	}

	event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);
	}

	// In aiming state, the pawn can't move
	function PlayerMove( float DeltaTime )
	{
	}
}

//--------------------------------- CLOSE COMBAT MODE ---------------------------
simulated state CloseCombat
{
	event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
	}

	event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);
	}

	function PlayerMove(float DeltaTime)
	{
		// Player can't move
	}
}

simulated function OnToggleUnitFlags(SeqAct_ToggleUnitFlags inAction)
{
	if (inAction.InputLinks[0].bHasImpulse)
	{
		XComPresentationLayer(Pres).m_kUnitFlagManager.Show();
	}
	else if (inAction.InputLinks[1].bHasImpulse)
	{
		XComPresentationLayer(Pres).m_kUnitFlagManager.Hide();
	}
}

//--------------------------------- CINEMATIC MODE ------------------------------

function SetCinematicMode( bool bInCinematicMode, bool bHidePlayer, bool bAffectsHUD, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsButtons, optional bool bDoClientRPC, optional bool bOverrideUserMusic = false )
{
	super.SetCinematicMode( bInCinematicMode, bHidePlayer, bAffectsHUD, bAffectsMovement, bAffectsTurning, bAffectsButtons, bDoClientRPC, bOverrideUserMusic );

	CinematicModeToggled(bInCinematicMode, bAffectsMovement, bAffectsTurning, bAffectsHUD);
}

/** called by the server to synchronize cinematic transitions with the client */
reliable client function ClientSetCinematicMode(bool bInCinematicMode, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsHUD)
{
	super.ClientSetCinematicMode( bInCinematicMode, bAffectsMovement, bAffectsTurning, bAffectsHUD );

	CinematicModeToggled(bInCinematicMode, bAffectsMovement, bAffectsTurning, bAffectsHUD);
}

simulated native function ForceCursorUpdate();

simulated function CinematicModeToggled(bool bInCinematicMode, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsHUD, optional bool bAffectsCamera = true, optional bool bShowCursor = false)
{
	local XComWorldData WorldData;
	local XComLevelBorderManager LvlBorderMgr;

	m_bInCinematicMode = bInCinematicMode;

	if (GetCursor() != none)
		GetCursor().SetForceHidden(m_bInCinematicMode);

	if (Pres.m_kUIMouseCursor != none)
	{
		if(m_bInCinematicMode)
		{
			Pres.m_kUIMouseCursor.SetVisible(bShowCursor);
		}
		else
		{
			Pres.m_kUIMouseCursor.Show();
		}
	}

	WorldData = class'XComWorldData'.static.GetWorldData();
	if( WorldData != none )
	{
		WorldData.Volume.BorderComponent.SetCinematicHidden(m_bInCinematicMode);		
		WorldData.Volume.BorderComponentDashing.SetCinematicHidden(m_bInCinematicMode);
		WorldData.bCinematicMode = m_bInCinematicMode;
	}

	if (`PRES != none)
		LvlBorderMgr = `PRES.GetLevelBorderMgr();
	if( LvlBorderMgr != none )
	{
		LvlBorderMgr.SetBorderCinematicHidden(m_bInCinematicMode);
	}

	// If there's no XGPlayer, that means we're in the transition map and should
	// not be attempting to do anything with squads, units, or other gameplay stuff -- jboswell
	if (m_XGPlayer != none)
	{
		if (bInCinematicMode)
		{
			if (bAffectsHUD)
			{
				XComPresentationLayer(Pres).HideUIForCinematics();
				SetUnitVisibilityStates(bInCinematicMode);  // for misc. active unit and enemy items (unit discs, cover indicators, flashlight, etc.)

				//ConsoleCommand( "SetPPVignette "@string(!bInCinematicMode));
				Pres.EnablePostProcessEffect('Vignette', !bInCinematicMode);

				XComPresentationLayer(Pres).UpdateConcealmentShader(true);
			}

			if (!IsInState('CinematicMode'))
			{
				PushState('CinematicMode');
			}

			if(bAffectsCamera && !PlayerCamera.IsInState('DebugView'))
			{
				PlayerCamera.GotoState('CinematicView');
			}

			//`SOUNDMGR.StopAmbience();
		}
		else
		{
			if (bAffectsHUD)
			{
				XComPresentationLayer(Pres).ShowUIForCinematics();
				SetUnitVisibilityStates(bInCinematicMode);  // for misc. active unit and enemy items (unit discs, cover indicators, flashlight, etc.)

				//ConsoleCommand( "SetPPVignette "@string(!bInCinematicMode));
				Pres.EnablePostProcessEffect('Vignette', !bInCinematicMode);

				XComPresentationLayer(Pres).UpdateConcealmentShader();
			}

			if(IsInState('CinematicMode'))
			{
				PopState();
			}

			if(PlayerCamera.IsInState('CinematicView'))
			{
				PlayerCamera.GotoState('');
			}
		}
	}

	// Force the 2d mouse cursor update so that that mouse gets hidden
	ForceCursorUpdate();

	ShowLootVisuals(!m_bInCinematicMode);
}


function ShowLootVisuals(bool ShowLootVisuals)
{
	local XGUnit Unit;
	local XComInteractiveLevelActor InteractiveActor;

	if(ShowLootVisuals != m_bShowLootVisuals)
	{
		m_bShowLootVisuals = ShowLootVisuals;

		foreach AllActors(class'XGUnit', Unit)
		{
			Unit.UpdateLootSparkles();
		}

		foreach AllActors(class'XComInteractiveLevelActor', InteractiveActor)
		{
			InteractiveActor.UpdateLootSparkles();
		}
	}
}

state CinematicMode
{
	event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
	}

	event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);
	}

	// don't show menu in cenematic mode - the button skips the cinematic
	exec function ShowMenu();

	// dont playe selection sound
	exec function PlayUnitSelectSound();
}

function SetUnitVisibilityStates(bool bIsCinematic)
{
	local int i;

	if (bIsCinematic)
	{
		for(i = 0; i < m_XGPlayer.GetSquad().GetNumMembers(); ++i)
		{
			m_XGPlayer.GetSquad().GetMemberAt(i).SetDiscState(eDS_Hidden);
		}
		if (m_kActiveUnit != none)
		{
			m_kActiveUnit.SetDiscState(eDS_Hidden);
		}
	}
}

reliable server function ServerTeleportActiveUnitTo(Vector vLoc)
{
	if(CheatManager != none)
	{
		XComTacticalCheatManager(CheatManager).TeleportTo(vLoc);
		
		if(WorldInfo.NetMode != NM_Standalone)
		{
			// since we dont replicate unit locations we must tell the clients to set the location -tsmith 
			GetActiveUnit().GetPawn().m_vTeleportToLocation = GetActiveUnit().GetPawn().Location;
			ServerSay("CHEAT!!!! " @ PlayerReplicationInfo.PlayerName @ " teleported" @ GetActiveUnit().SafeGetCharacterLastName() @ "to" @ vLoc);
		}
	}
}


//-----------------------------------------------------------

//
// Replicate this client's desired movement to the server.
//
function ReplicateMove
(
	float DeltaTime,
	vector NewAccel,
	eDoubleClickDir DoubleClickMove,
	rotator DeltaRot
)
{
}

unreliable client function ClientUpdatePing(float fTimeStamp)
{
	UpdatePing(fTimeStamp);
}

unreliable client function ClientAdjustPosition
(
	float TimeStamp,
	name newState,
	EPhysics newPhysics,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	float NewVelX,
	float NewVelY,
	float NewVelZ,
	Actor NewBase
)
{
}

unreliable client function ShortClientAdjustPosition
(
	float TimeStamp,
	name newState,
	EPhysics newPhysics,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	Actor NewBase
)
{
}

unreliable client function VeryShortClientAdjustPosition
(
	float TimeStamp,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	Actor NewBase
)
{
}


unreliable client function LongClientAdjustPosition
(
	float TimeStamp,
	name newState,
	EPhysics newPhysics,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	float NewVelX,
	float NewVelY,
	float NewVelZ,
	Actor NewBase,
	float NewFloorX,
	float NewFloorY,
	float NewFloorZ
)
{
}

exec function SoldierSpeak(Name speechName)
{
	local XGUnit kUnit;
	kUnit = GetActiveUnit();
	kUnit.UnitSpeak(speechName);
}

exec function TestItemCard()
{
	XComTacticalGame(WorldInfo.Game).GetItemCard();
}


reliable client event Kismet_ClientPlaySound(SoundCue ASound, Actor SourceActor, float VolumeMultiplier, float PitchMultiplier, float FadeInTime, bool bSuppressSubtitles, bool bSuppressSpatialization)
{
	super.Kismet_ClientPlaySound(ASound, SourceActor, VolumeMultiplier, PitchMultiplier, FadeInTime, true, bSuppressSpatialization);
}

simulated function OnToggleHUDElements(SeqAct_ToggleHUDElements Action)
{
	 GetPres().GetTacticalHUD().OnToggleHUDElements(Action);
}

simulated function HideInputButtonRelatedHUDElements(bool bHide)
{
	GetPres().GetTacticalHUD().HideInputButtonRelatedHUDElements(bHide);
}
/**
 * Looks at the current game state and uses that to set the
 * rich presence strings
 *
 * Licensees (that's us!) should override this in their player controller derived class
 */
reliable client function ClientSetOnlineStatus()
{
	local XComOnlineGameSettings GameSettings;

	if( WorldInfo.NetMode == NM_StandAlone )
	{
		`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_InGameSP);
	}
	else
	{
		GameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
		if( GameSettings.GetIsRanked() )
		{
			`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_InRankedMP);
		}
		else
		{
			`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_InUnrankedMP);
		}
	}
}

simulated function bool IsInCinematicMode()
{
	return m_bInCinematicMode;
}
simulated function bool ShouldBlockPauseMenu()
{
	local bool bShouldBlock;

	bShouldBlock = super.ShouldBlockPauseMenu();
	bShouldBlock = bShouldBlock || m_XGPlayer.GetStateName() == 'EndingTurn';
	bShouldBlock = bShouldBlock || GetPres().GetTacticalHUD().IsMenuRaised(); // Do not allow pause menu while the shot hud is opening. -ttalley

	return bShouldBlock;
}

simulated function InitPres()
{
	local XGUnit kUnit;

	if(IsLocalPlayerController() && Pres == none)
	{
		Pres = spawn( PresentationLayerClass, self,,,,,, m_eTeam);
		Pres.Init();

		if (WorldInfo.NetMode == NM_Client)
		{
			foreach WorldInfo.DynamicActors(class'XGUnit', kUnit)
			{
				kUnit.NotifyPresentationLayersInitialized();
			}
		}
	}

	OnlineSub.SystemInterface.AddLinkStatusChangeDelegate(LinkStatusChange);
	OnlineSub.SystemInterface.AddConnectionStatusChangeDelegate(ConnectionStatusChange);
	`ONLINEEVENTMGR.AddLoginStatusChangeDelegate(LoginStatusChange);
	`ONLINEEVENTMGR.AddCheckReadyForGameInviteAcceptDelegate(OnCheckReadyForGameInviteAccept);
}

simulated function bool IsInitialReplicationComplete()
{
	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_XGPlayer) @ `ShowVar(m_XGPlayer.m_kPlayerController));
	return m_XGPlayer != none && m_XGPlayer.m_kPlayerController != none;
}

/**
 * Called after this PlayerController's viewport/net connection is associated with this player controller.
 * It is valid to test for this player being a local player controller at this point.
 */
simulated event ReceivedPlayer()
{
	// NOTE: this function will be called multiple times for a given player login/connection -tsmith 
	super.ReceivedPlayer();

	// need to keep using the long timeout until the battle is fully initialized. -tsmith 
	bShortConnectTimeOut=false;
	ServerShortTimeout(false);
	ServerSetPlayerLanguage(GetLanguage());
}

reliable server function ServerSetPlayerLanguage(string strLanguage)
{
	if (XComMPTacticalPRI(PlayerReplicationInfo) != none)
	{
		`log(self $ "::" $ GetFuncName() @ "Player=" $ PlayerReplicationInfo.PlayerName @ `ShowVar(strLanguage), true, 'XCom_Net');
		XComMPTacticalPRI(PlayerReplicationInfo).m_strLanguage = strLanguage;
	}	
}

/**
 * Tells the clients to write the stats using the specified stats object
 *
 * @param OnlineStatsWriteClass the stats class to write with
 * @param bIsIncomplete TRUE if the match wasn't finished at the time of the write
 */
reliable client function ClientWriteLeaderboardStats(class<OnlineStatsWrite> OnlineStatsWriteClass, optional bool bIsIncomplete=false)
{
	local XComOnlineStatsWrite Stats;
	local XComPlayerReplicationInfo PRI;
	local XComGameReplicationInfo GRI;
	local int Index;
	local UniqueNetId ZeroId;
	local OnlineGameSettings GameSettings;

	// Only calc this if the subsystem can write stats
	if (OnlineSub != None &&
		OnlineSub.StatsInterface != None &&
		OnlineSub.GameInterface != None &&
		OnlineStatsWriteClass != None)
	{
		// Get the game setting so we can determine whether to write stats for none, one or all players
		GameSettings = OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName);
		if (GameSettings != None && (!GameSettings.bIsLanMatch)) // Only write leaderboard stats for online games -ttalley
		{
			// create the stats object that will write to the leaderboard -tsmith 
			Stats = XComOnlineStatsWrite(new OnlineStatsWriteClass);

			// Get the GRI so we can iterate players
			GRI = XComGameReplicationInfo(WorldInfo.GRI);

			// Arbitration requires us to report for everyone, whereas non-arbitrated is just for ourselves
			if (GameSettings.bUsesArbitration)
			{
				// Iterate through the active PRI list updating the stats
				for (Index = 0; Index < GRI.PRIArray.Length; Index++)
				{
					PRI = XComPlayerReplicationInfo(GRI.PRIArray[Index]);
					if (!PRI.bIsInactive &&
						PRI.UniqueId != ZeroId)
					{
						// Copy the stats from the PRI to the object
						`log(`location @ "Writing stats for " $ PRI.PlayerName, true, 'XCom_Net');
						Stats.UpdateFromPRI(PRI);
						// This will copy them into the online subsystem where they will be
						// sent via the network in EndOnlineGame()
						OnlineSub.StatsInterface.WriteOnlineStats(PRI.SessionName,PRI.UniqueId,Stats);
					}
				}
			}
			else
			{
				`log(`location @ "Writing stats for " $ PlayerReplicationInfo.PlayerName, true, 'XCom_Net');
				// if the server player disconnected it should not write any stats, the client disconnect code is handled in the LostConnection function.
				// the server does not always execute that if they or the client disconnect, they will go thru the Logout/Forfeit code and that detects the disconnect. -tsmith 
				if(XComMPTacticalGRI(WorldInfo.GRI).m_bGameDisconnected)
				{
					`log(`location @ "Game was disconnected, not writing stats, they are handled by the disconnect code", true, 'XCom_Net');
					return;
				}

				Stats.UpdateFromPRI(XComPlayerReplicationInfo(PlayerReplicationInfo));
				if(!OnlineSub.StatsInterface.WriteOnlineStats(PlayerReplicationInfo.SessionName,PlayerReplicationInfo.UniqueId,Stats))
				{
					`warn(`location @ "WriteOnlineStats failed, can't write leaderboard stats", true, 'XCom_Net');
				}
				else if(`ONLINEEVENTMGR.bOnlineSubIsSteamworks)
				{
					// steam needs to flush the stats so they get cached in the steam client and will eventually get written -tsmith 
					`log(`location @ "OnlineSubsystem is Steam, attempting to flush stats...", true, 'XCom_Net');
					if(!OnlineSub.StatsInterface.FlushOnlineStats(PlayerReplicationInfo.SessionName))
					{
						`warn("     FlushOnlineStats failed, can't write leaderboard stats", true, 'XCom_Net');
					}
					else
					{
						`log("      FlushOnlineStats successful", true, 'XCom_Net');
					}
				}
				// No longer flush the online stats, the XSessionEnd does this automatically and will wait for 20 seconds if a flush has already been done. -ttalley
				//else
				//{
				//	if(!OnlineSub.StatsInterface.FlushOnlineStats(PlayerReplicationInfo.SessionName))
				//	{
				//		`warn(`location @ "FlushOnlineStats failed, can't write leaderboard stats", true, 'XCom_Net');
				//	}
				//}
			}
		}
	}
}

/**
 * Writes the scores for all active players. Override this in your
 * playercontroller class to provide custom scoring
 *
 * @param LeaderboardId the leaderboard the scores are being written to
 */
reliable client function ClientWriteOnlinePlayerScores(int LeaderboardId)
{
	// we are not implementing this as our ClientWriteLeaderboardStats handles all the scoring. This is to make cross platform scoring easier as the PSN API
	// only has scoreboard/leaderboard functions and thus its much easier to handle thru one call. if we ever need to use True Skill or something like that
	// we may have to revisit making this code work on PSN. we may need to implement this code much like steam/gamespy with pending stat logic. -tsmith 
}


/**
 * Ends the online game using the session name in the PRI
 */
reliable client function ClientEndOnlineGame()
{
	local OnlineGameSettings kGameSettings;

	`log(`location @ `ShowVar(IsPrimaryPlayer()) @ `ShowVar(OnlineSub) @ `ShowVar(OnlineSub.GameInterface) @ `ShowVar(PlayerReplicationInfo.SessionName) @ "GameSettings=" $ OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName) @ "GameState=" $ OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName).GameState, true, 'XCom_Online');

	if( OnlineSub != none && OnlineSub.GameInterface != none && IsPrimaryPlayer() )
	{
		kGameSettings = OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName);
		if(kGameSettings != none)
		{
			// our game stops advertising once it has ended. prevents lan beacons and advertising to the backend from happening. -tsmith 
			kGameSettings.bShouldAdvertise = false;

			if ( kGameSettings.GameState == OGS_InProgress )
			{
				OnlineSub.GameInterface.AddEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
				if ( ! OnlineSub.GameInterface.EndOnlineGame(PlayerReplicationInfo.SessionName) )
				{
					OnlineSub.GameInterface.ClearEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
					CleanedUpOnlineGame();
				}
			}
			else
			{
				CleanedUpOnlineGame();
			}
		}		
	}
}

/**
 * Called when an arbitrated match has ended and we need to disconnect
 */
reliable client function ClientArbitratedMatchEnded()
{
	// NOTE: we dont call super.ClientArbitratedMatchEnded and that would cause a disconnect and not show the end game screen -tsmith 
}

/**
 * WriteRankedMatchStartedFlag
 * 
 * Writes the match started flag as well as the # of disconnects as this may have been incremented 
 * if the player did not finish the last match.
 * 
 * Only called for the local player
 * 
 */
reliable client function ClientWriteRankedMatchStartedFlag()
{
	local XComOnlineStatsWriteDeathmatchRankedGameStartedFlag kWriteMatchStartedFlag;
	local XComPlayerReplicationInfo XComPRI;

	`log(self $ "::" $ GetFuncName() @ "OnlineGameState=" $ OnlineSub.GameInterface.GetGameSettings('Game').GameState, true, 'XCom_Net');

	if(m_bRankedMatchStartedFlagWritten || !XComOnlineGameSettings(OnlineSub.GameInterface.GetGameSettings('Game')).GetIsRanked())
		return;

	XComPRI = XComPlayerReplicationInfo(PlayerReplicationInfo);
	if(XComPRI == none)
	{
		`log(`location @ "XComPRI is NULL, waiting for Server ...",,'XCom_Online');
		// Wait until it comes down from the server ...
		SetTimer(0.1f, false, nameof(ClientWriteRankedMatchStartedFlag));
	}
	else if(OnlineSub != none && OnlineSub.StatsInterface != none)
	{
		`log(self $ "::" $ GetFuncName() @ "BEFORE:" @ XComPRI.ToString(), true, 'XCom_Net');
		XComPlayerReplicationInfo(PlayerReplicationInfo).m_bRankedDeathmatchLastMatchStarted = true;
		ServerSetMatchStartedFlag(true);
		kWriteMatchStartedFlag = new class'XComOnlineStatsWriteDeathmatchRankedGameStartedFlag';
		kWriteMatchStartedFlag.UpdateFromPRI(XComPRI);
		if(!OnlineSub.StatsInterface.WriteOnlineStats('Game', XComPRI.UniqueId, kWriteMatchStartedFlag))
		{
			`warn(self $ "::" $ GetFuncName() @ "WriteOnlineStats failed, can't write match started flag", true, 'XCom_Net');
		}
		else
		{
			`log(self $ "::" $ GetFuncName() @ "WriteOnlineStats succeeded, calling FlushOnlineStats", true, 'XCom_Net');
			if(!OnlineSub.StatsInterface.FlushOnlineStats('Game'))
			{
				`warn(self $ "::" $ GetFuncName() @ "FlushOnlineStats failed, can't write match started flag", true, 'XCom_Net');
			}
			m_bRankedMatchStartedFlagWritten = true;
			`log(self $ "::" $ GetFuncName() @ "AFTER:" @ XComPRI.ToString(), true, 'XCom_Net');
		}
	}
	else
	{
		`warn(self $ "::" $ GetFuncName() @ "Missing online subsystem components, can't write match started flag", true, 'XCom_Net');
	}
}

reliable server function ServerSetMatchStartedFlag(bool bMatchStarted)
{
	XComMPTacticalPRI(PlayerReplicationInfo).m_bRankedDeathmatchLastMatchStarted = bMatchStarted;
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bMatchStarted) @ XComMPTacticalPRI(PlayerReplicationInfo).ToString(), true, 'XCom_Net');
}

/**
 * Triggered when the 'disconnect' console command is called, to allow cleanup before disconnecting (e.g. for the online subsystem)
 * NOTE: If you block disconnect, store the 'Command' parameter, and trigger ConsoleCommand(Command) when done; be careful to avoid recursion
 *
 * @param Command	The command which triggered disconnection, e.g. "disconnect" or "disconnect local" (can parse additional parameters here)
 * @return		Return True to block the disconnect command from going through, if cleanup can't be completed immediately
 */
event bool NotifyDisconnect(string Command)
{
	`log(self $ "::" $ GetStateName() $ "::" $ GetFuncName() @ `ShowVar(Command), true, 'XCom_Net');
	if(XComMPTacticalGame(WorldInfo.Game) != none && XComMPTacticalGame(WorldInfo.Game).m_bPingingMCP)
	{
	}
	`ONLINEEVENTMGR.bIsChallengeModeGame = false;
	return false;
}

simulated function AttemptExit()
{
	`log(`location @ `ShowVar(m_bReturnToMPMainMenu) @ `ShowVar(m_bConnectionFailedDuringGame) @ `ShowVar(m_bHasCleanedUpGame),,'XCom_Net');
	m_bReturnToMPMainMenu = true;
	if (m_bConnectionFailedDuringGame || m_bHasCleanedUpGame)
	{
		`ONLINEEVENTMGR.ReturnToMPMainMenu();
	}
	else if (m_bIsCleaningUpGame)
	{
		Pres.UIShutdownOnlineGame();
	}
	else
	{
		m_bIsCleaningUpGame = true;
		Pres.UIShutdownOnlineGame();
		`TACTICALRULES.LocalPlayerForfeitMatch();
	}
	SetTimer(15.0f, false, nameof(ForcedExit));
}

simulated function ForcedExit()
{
	`log(`location @ "ERROR: We are forcing the exit back to the MP Main Menu because the exit timeout has been reached!");
	Pres.StartMPShellState();
}

/**
 * Notifies the player that an attempt to connect to a remote server failed, or an existing connection was dropped.
 *
 * @param	Message		a description of why the connection was lost
 * @param	Title		the title to use in the connection failure message.
 */
function NotifyConnectionError(EProgressMessageType MessageType, optional string Message, optional string Title)
{
	local EQuitReason Reason;
	`log(`location @ 
		"ProgressMessageType=" $ MessageType @
		"Player=" $ PlayerReplicationInfo.PlayerName @
		"RoundEnded=" $ m_bRoundEnded @
		"IsRankedGame=" $ XComOnlineGameSettings(OnlineSub.GameInterface.GetGameSettings('Game')).GetIsRanked() @
		"OnlineGameState=" $ OnlineSub.GameInterface.GetGameSettings('Game').GameState,
		true, 'XCom_Net');

	GetALocalPlayerController().bIgnoreNetworkMessages = true;

	Reason = ((MessageType == PMT_ConnectionFailure) || (MessageType == PMT_PeerConnectionFailure)) ? QuitReason_OpponentDisconnected : QuitReason_None;

	LostConnection(Reason);
}

simulated function UpdateEndOfGamePRIDueToDisconnect(bool bOtherPlayerDisconnected)
{
	local XComMPTacticalGRI kMPGRI;
	local XComMPTacticalPRI kOpponentPRI, kMPWinningPRI, kMPLosingPRI, kPRI;

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);
	`log(`location @ `ShowVar(kMPGRI) @ `ShowVar(bOtherPlayerDisconnected),,'XCom_Net');
	foreach DynamicActors(class'XComMPTacticalPRI', kPRI)
	{
		if((kPRI == none) || (kPRI == PlayerReplicationInfo))
		{
			continue;
		}
		if(kPRI != none)
		{
			`log(`location @ "Setting opponent PRI: " @ `ShowVar(kPRI),,'XCom_Net');
			kOpponentPRI = kPRI;
		}
	}

	if(bOtherPlayerDisconnected)
	{
		// i'm the winning player -tsmith 
		kMPWinningPRI = XComMPTacticalPRI(PlayerReplicationInfo);
		// mark other PRI as disconnected -tsmith 
		kOpponentPRI.m_bDisconnected = true;
		kMPLosingPRI = kOpponentPRI;
	}
	else
	{
		// other player is the winner -tsmith 
		kMPWinningPRI = kOpponentPRI;
		// mark my PRI as disconnected -tsmith 
		XComMPTacticalPRI(PlayerReplicationInfo).m_bDisconnected = true;
		kMPLosingPRI = XComMPTacticalPRI(PlayerReplicationInfo);
	}

	`log(`location @ `ShowVar(kMPWinningPRI) @ `ShowVar(kMPLosingPRI) @ `ShowVar(kMPLosingPRI.m_bDisconnected),,'XCom_Net');
	if ((kMPWinningPRI != none) && (kMPLosingPRI != none))
	{
		`log(`location @ `ShowVar(kMPWinningPRI.PlayerName, Winner) @ `ShowVar(kMPLosingPRI.PlayerName, Loser),,'XCom_Net');

		// Update the game info so the end of game summary will appear
		kMPGRI.m_kWinningPRI = kMPWinningPRI;
		kMPGRI.m_kLosingPRI = kMPLosingPRI;

		`log(kMPWinningPRI.PlayerName $ " has won!!", true, 'XCom_Net');

		//XGBattle_MP(XComMPTacticalGRI(WorldInfo.GRI).m_kBattle).GetResults().SetWinner( m_XGPlayer );
	}
}

simulated function StatsWriteWinDueToDisconnect()
{
	local XComOnlineStatsWriteDeathmatchClearGameStartedFlagDueToDisconnect kClearDeathmatchStartedFlag;

	`log(`location,,'XCom_Net');
	XComMPTacticalGRI(WorldInfo.GRI).m_bGameDisconnected = true;
	// clear ranked match flag if we are ranked, also write win because we have been disconnected by other player -tsmith 
	if(XComOnlineGameSettings(OnlineSub.GameInterface.GetGameSettings('Game')).GetIsRanked())
	{
		`log(`location @ "Attempting to clear game started flag", true, 'XCom_Net');
		kClearDeathmatchStartedFlag = new class'XComOnlineStatsWriteDeathmatchClearGameStartedFlagDueToDisconnect';
		kClearDeathmatchStartedFlag.UpdateFromPRI(XComPlayerReplicationInfo(PlayerReplicationInfo));
		if(!OnlineSub.StatsInterface.WriteOnlineStats('Game', PlayerReplicationInfo.UniqueId, kClearDeathmatchStartedFlag))
		{
			`warn(`location @ "WriteOnlineStats failed, can't clear match started flag", true, 'XCom_Net');
		}
		else if(`ONLINEEVENTMGR.bOnlineSubIsSteamworks)
		{
			// steam needs to flush the stats so they get cached in the steam client and will eventually get written -tsmith 
			`log(`location @ "OnlineSubsystem is Steam, attempting to flush stats...", true, 'XCom_Net');
			if(!OnlineSub.StatsInterface.FlushOnlineStats(PlayerReplicationInfo.SessionName))
			{
				`warn("     FlushOnlineStats failed, can't write leaderboard stats", true, 'XCom_Net');
			}
			else
			{
				`log("      FlushOnlineStats successful", true, 'XCom_Net');
			}
		}
	}
}

simulated function DisplayEndOfGameDialog()
{
	PlayerInput.GotoState('Multiplayer_GameOver');
	if(!m_XGPlayer.IsInState('GameOver'))
	{
		m_XGPlayer.GotoState('GameOver');
		return;
	}

	`log(`location,,'XCom_Net');
	if(  GetPres() != none )
	{
		//Close up any confirm dialogue that may be up
		if( GetPres().Get2DMovie().DialogBox.ShowingDialog() )
			GetPres().Get2DMovie().DialogBox.OnCancel();

		//Close the pause menu if it's up
		if( GetPres().IsInState( 'State_PauseMenu' ) )
			GetPres().PopState(); 

		//Close the shotHUD if it's open
		if( GetPres().GetTacticalHUD().IsMenuRaised() )
			GetPres().GetTacticalHUD().CancelTargetingAction();

		if ( ! IsReturningToMPMainMenu() )
			GetPres().UIMPShowGameOverScreen(XComMPTacticalPRI(PlayerReplicationInfo).m_bWinner);
	}
}


auto state PlayerWaiting /* Overrides the parent class state -ttalley */
{
ignores SeePlayer, HearNoise, NotifyBump, TakeDamage, PhysicsVolumeChange, NextWeapon, PrevWeapon, SwitchToBestWeapon;

	/**
	 * Notifies the player that an attempt to connect to a remote server failed, or an existing connection was dropped.
	 *
	 * @param	Message		a description of why the connection was lost
	 * @param	Title		the title to use in the connection failure message.
	 */
	function NotifyConnectionError(EProgressMessageType MessageType, optional string Message, optional string Title)
	{
		// Game has timed out while waiting for the other player to join.
		`log(`location @ "Player=" $ PlayerReplicationInfo.PlayerName @
			"ProgressMessageType=" $ MessageType @
			"IsRankedGame=" $ XComOnlineGameSettings(OnlineSub.GameInterface.GetGameSettings('Game')).GetIsRanked() @
			"OnlineGameState=" $ OnlineSub.GameInterface.GetGameSettings('Game').GameState,
			true, 'XCom_Net');

		GetALocalPlayerController().bIgnoreNetworkMessages = true;

		LostConnection(QuitReason_OpponentDisconnected);
	}

	simulated function LostConnection(EQuitReason Reason)
	{
		// don't give a FAQ about network link changes unless its a multiplayer game. -tsmith
		if(!`XENGINE.IsMultiplayerGame())
			return;

		`ONLINEEVENTMGR.QueueQuitReasonMessage(Reason);

		m_bReturnToMPMainMenu = true;  // Head back to the MP Main Menu when done clearing the ranked stats and cleaning up the game

		// ping MCP to see if we disconnected or the other player disconnected that way we can record a win if it was the other player -tsmith 
		`log(self $ "::" $ GetStateName() $ "::" $ GetFuncName(), true, 'XCom_Net');
		if( `XENGINE.MCPManager != none )
		{
			if(`XENGINE.MCPManager.PingMCP(OnPingMCPCompleteFinishLostConnectionWhilePlayerWaiting))
			{
				`log("      started async task PingMCP", true, 'XCom_Net');
				m_bPingingMCP = true;
			}
			else
			{
				`warn("      failed to start async task PingMCP");
				FinishLostConnectionWhilePlayerWaiting(false);
			}
		}
		else
		{
			`warn("      MCP manager does not exist");
			FinishLostConnectionWhilePlayerWaiting(false);
		}
	}
}

/**
 *  Gets called via the end game sequence: 
 *      XGBattle_MP::CheckForVictory
 *          GameInfo::EndGame
 *              GameInfo::CheckEndGame
 *                  PlayerController::GameHasEnded 
 *                      PlayerController::ClientGameEnded
 *                      
 *   
 *   Copied from PlayerController and gutted for our pleasure.
 *   We need to override this state to stop certain things from happening.
 *   Specifically, the call TurnOff all the pawns was causing the game to hang because animations would not finish.
 *   
 */
state RoundEnded
{
ignores SeePlayer, HearNoise, KilledBy, NotifyBump, HitWall, NotifyHeadVolumeChange, NotifyPhysicsVolumeChange, Falling, TakeDamage, Suicide;

	/**
	 * Notifies the player that an attempt to connect to a remote server failed, or an existing connection was dropped.
	 *
	 * @param	Message		a description of why the connection was lost
	 * @param	Title		the title to use in the connection failure message.
	 */
	function NotifyConnectionError(EProgressMessageType MessageType, optional string Message, optional string Title)
	{
		// game has ended properly in this state, unless we forfieted??? so we just clear our disconnect flag and dont try to give ourself a win -tsmith 
		`log(`location @ "Player=" $ PlayerReplicationInfo.PlayerName @
			"ProgressMessageType=" $ MessageType @
			"IsRankedGame=" $ XComOnlineGameSettings(OnlineSub.GameInterface.GetGameSettings('Game')).GetIsRanked() @
			"OnlineGameState=" $ OnlineSub.GameInterface.GetGameSettings('Game').GameState,
			true, 'XCom_Net');

		GetALocalPlayerController().bIgnoreNetworkMessages = true;
		LostConnection(QuitReason_None); // No problem if you time-out against the other player when in the round-ended state
	}

	simulated function LostConnection(EQuitReason Reason)
	{
		// don't give a FAQ about network link changes unless its a multiplayer game. -tsmith
		if(!`XENGINE.IsMultiplayerGame())
			return;
		`ONLINEEVENTMGR.QueueQuitReasonMessage(Reason);
	}

	reliable server function ServerReStartPlayer()
	{
	}

	function bool IsSpectating()
	{
		return true;
	}

	exec function ThrowWeapon() {}
	exec function Use() {}

	event Possess(Pawn aPawn, bool bVehicleTransition)
	{
	}

	reliable server function ServerReStartGame()
	{
	}

	exec function StartFire( optional byte FireModeNum )
	{
	}

	function PlayerMove(float DeltaTime)
	{
	}

	unreliable server function ServerMove
	(
		float TimeStamp,
		vector InAccel,
		vector ClientLoc,
		byte NewFlags,
		byte ClientRoll,
		int View
	)
	{
	}

	function FindGoodView()
	{
	}

	event Timer()
	{
		bFrozen = false;
	}

	unreliable client function LongClientAdjustPosition
	(
		float TimeStamp,
		name newState,
		EPhysics newPhysics,
		float NewLocX,
		float NewLocY,
		float NewLocZ,
		float NewVelX,
		float NewVelY,
		float NewVelZ,
		Actor NewBase,
		float NewFloorX,
		float NewFloorY,
		float NewFloorZ
	)
	{
	}

	event BeginState(Name PreviousStateName)
	{
		m_bRoundEnded = true;
	}

	event EndState(name NextStateName)
	{
		if (myHUD != None)
		{
			myHUD.SetShowScores(false);
		}
	}

Begin:
}

/* epic ===============================================
* ::GameHasEnded
*
* Called from game info upon end of the game, used to
* transition to proper state.
*
* =====================================================
*/
function GameHasEnded(optional Actor EndGameFocus, optional bool bIsWinner)
{
	m_bRoundEnded = true;
	super.GameHasEnded(EndGameFocus, bIsWinner);
}

/* epic ===============================================
* ::ClientGameEnded
*
* Replicated function called by GameHasEnded().
*
 * @param	EndGameFocus - actor to view with camera
 * @param	bIsWinner - true if this controller is on winning team
* =====================================================
*/
reliable client function ClientGameEnded(Actor EndGameFocus, bool bIsWinner)
{
	m_bRoundEnded = true;
	super.ClientGameEnded(EndGameFocus, bIsWinner);
}

state WaitingForGameInitialization
{
ignores SeePlayer, HearNoise, NotifyBump, TakeDamage, PhysicsVolumeChange, NextWeapon, PrevWeapon, SwitchToBestWeapon;

	event BeginState(name PreviousStateName)
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(PreviousStateName), true, 'XCom_Net');
		bShortConnectTimeOut=false;
		ServerShortTimeout(false);
	}

	event EndState(name NextStateName)
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(NextStateName), true, 'XCom_Net');
		bShortConnectTimeOut=true;
		ServerShortTimeout(true);
	}

	//event PlayerTick(float DeltaTime)
	//{
	//	`log(self $ "::" $ GetFuncName() @ "State=" $ GetStateName() @ `ShowVar(bShortConnectTimeOut), true, 'WTF');
	//}
}

simulated function bool IsReturningToMPMainMenu()
{
	`log(`location @ `ShowVar(m_bReturnToMPMainMenu));
	return m_bReturnToMPMainMenu;
}

function FinishGameOver()
{
	`log(`location);
	SetTimer(2.0f, true, nameof(ExitOrStay)); // Delayed on server to make sure that the client gets the replicated information (i.e. quit)
	m_bHasCleanedUpGame = true; // Server
	m_bIsCleaningUpGame = false;
}

reliable client function ClientFinishGameOver(bool bReturnToMPMainMenu)
{
	`log(`location @ `ShowVar(bReturnToMPMainMenu));
	if (bReturnToMPMainMenu)
	{
		`ONLINEEVENTMGR.ReturnToMPMainMenu();
	}
	else if (Role == ROLE_Authority)
	{
		ConsoleCommand("disconnect local"); // Close network connections without traveling home. -ttalley
	}
}

function ExitOrStay()
{
	local XGPlayer_MP kMPPlayer;

	foreach DynamicActors(class'XGPlayer_MP', kMPPlayer)
	{
		if(!kMPPlayer.m_bGameOver)
			return;
	}

	ClearTimer(nameof(ExitOrStay));

	`log(`location @ "State=" $ GetStateName() @ `ShowVar(m_bReturnToMPMainMenu));
	if (m_bReturnToMPMainMenu)
	{
		`ONLINEEVENTMGR.ReturnToMPMainMenu();
	}
	else if (Role == ROLE_Authority)
	{
		ConsoleCommand("disconnect local"); // Close network connections without traveling home. -ttalley
	}
}

////==============================================================================
// 		ONLINE CONNECTION STATUS
//==============================================================================

simulated function LinkStatusChange(bool bIsConnected)
{
	local OnlineGameSettings GameSettings;

	// don't give a FAQ about network link changes unless its a multiplayer game. -tsmith
	if(!`XENGINE.IsMultiplayerGame())
		return;

	GameSettings = OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName);

	`log(`location @ `ShowVar(bIsConnected), true, 'XCom_Online');
	if( (! bIsConnected) && (! GameSettings.bIsLanMatch))
	{
		LostConnection(QuitReason_LostLinkConnection);
	}
}

simulated function ConnectionStatusChange(EOnlineServerConnectionStatus ConnectionStatus)
{
	//local OnlineGameSettings GameSettings;
	//GameSettings = OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName);

	`log(`location @ `ShowVar(ConnectionStatus), true, 'XCom_Online');

	//switch(ConnectionStatus)
	//{
	//case OSCS_Connected:
	//	break;
	//case OSCS_NoNetworkConnection:
	//	LostConnection(QuitReason_LostLinkConnection);
	//	break;
	//case OSCS_ConnectionDropped:
	//case OSCS_NotConnected:
	//case OSCS_ServiceUnavailable:
	//case OSCS_UpdateRequired:
	//case OSCS_ServersTooBusy:
	//case OSCS_DuplicateLoginDetected:
	//case OSCS_InvalidUser:
	//default:
	//	if ( GameSettings != None && ! GameSettings.bIsLanMatch)
	//	{
	//		LostConnection(QuitReason_LostConnection);
	//	}
	//	break;
	//}
}

simulated function LoginStatusChange(ELoginStatus NewStatus,UniqueNetId NewId)
{
	local OnlineGameSettings GameSettings;
	GameSettings = OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName);

	`log(`location @ `ShowVar(NewStatus) @ "NewId:" @ NewId.Uid.A $ NewId.Uid.B, true, 'XCom_Online');
	if (NewStatus != LS_LoggedIn && ( ! GameSettings.bIsLanMatch) && !`ONLINEEVENTMGR.IsSystemMessageQueued(SystemMessage_QuitReasonLinkLost))
	{
		LostConnection(QuitReason_LostConnection);
	}
}

// This is called whenever an Invite has been accepted by the user, as part of the 
// TriggerInviteAccepted() train.
simulated function bool OnCheckReadyForGameInviteAccept()
{
	local bool bReadyForGameInvite;

	m_bAttemptedGameInvite = true;

	if(!`XENGINE.IsMultiplayerGame() || m_bConnectionFailedDuringGame || m_bHasCleanedUpGame || m_bRoundEnded)
	{
		bReadyForGameInvite = true;
	}
	else
	{
		// In this case, we want to stop processing the invite, cleanly end the match, 
		// then join the new game.
		bReadyForGameInvite = false;
		AttemptExit();
	}
	return bReadyForGameInvite;
}

simulated function LostConnection(EQuitReason Reason)
{
	`log(`location @ `ShowVar(Reason),, 'XCom_Net');

	// don't give a FAQ about network link changes unless its a multiplayer game. -tsmith
	if(!`XENGINE.IsMultiplayerGame())
		return;

	`ONLINEEVENTMGR.QueueQuitReasonMessage(Reason);

	// it's possible for some other code to switch states and would write this flag after the round has ended. -tsmith 
	if(m_bRoundEnded)
		return;

	m_bConnectionFailedDuringGame = (Reason != QuitReason_None);

	m_bRoundEnded = true;
	m_bIsCleaningUpGame = true;

	// ping MCP to see if we disconnected or the other player disconnected that way we can record a win if it was the other player -tsmith 
	if( `XENGINE.MCPManager != none )
	{
		if(`XENGINE.MCPManager.PingMCP(OnPingMCPCompleteFinishLostConnection))
		{
			`log("      started async task PingMCP", true, 'XCom_Net');
			m_bPingingMCP = true;
		}
		else
		{
			`warn("      failed to start async task PingMCP");
			FinishLostConnection(false);
		}
	}
	else
	{
		`warn("      MCP manager does not exist");
		FinishLostConnection(false);
	}
}

private function OnPingMCPCompleteFinishLostConnection(bool bWasSuccessful, EOnlineEventType EventType)
{
	FinishLostConnection(bWasSuccessful);
}

private function FinishLostConnection(bool bOtherPlayerDisconnected)
{
	m_bPingingMCP = false;
	`XENGINE.MCPManager.OnEventCompleted = none;
	if (Role == ROLE_Authority)
	{
		ConsoleCommand("disconnect local");
	}

	UpdateEndOfGamePRIDueToDisconnect(bOtherPlayerDisconnected);
	DisplayEndOfGameDialog();

	if(bOtherPlayerDisconnected)
	{
		StatsWriteWinDueToDisconnect();
	}

	ClientEndOnlineGame();
}

private function OnPingMCPCompleteFinishLostConnectionWhilePlayerWaiting(bool bWasSuccessful, EOnlineEventType EventType)
{
	FinishLostConnectionWhilePlayerWaiting(bWasSuccessful);
}

private function FinishLostConnectionWhilePlayerWaiting(bool bOtherPlayerDisconnected)
{
	`XENGINE.MCPManager.OnEventCompleted = none;
	if(bOtherPlayerDisconnected)
	{
		StatsWriteWinDueToDisconnect();
	}

	ClientEndOnlineGame();
}

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	SubscribeToOnCleanupWorld();
	`log(`location @ "Subscribed to OnCleanupWorld!", true, 'XCom_Online');
}

/**
* Called when the world is being cleaned up. Allows the actor to free any dynamic content it has created.
*/
simulated event OnCleanupWorld()
{
	OnlineSub.SystemInterface.ClearLinkStatusChangeDelegate(LinkStatusChange);
	OnlineSub.SystemInterface.ClearConnectionStatusChangeDelegate(ConnectionStatusChange);
	OnlineSub.GameInterface.ClearEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
	OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	`ONLINEEVENTMGR.ClearLoginStatusChangeDelegate(LoginStatusChange);
	`ONLINEEVENTMGR.ClearCheckReadyForGameInviteAcceptDelegate(OnCheckReadyForGameInviteAccept);
	if(m_bPingingMCP)
	{
		`XENGINE.MCPManager.OnEventCompleted = none;
	}
	super.OnCleanupWorld();
}

simulated event Destroyed()
{
	local XComGameStateVisualizationMgr VisualizationManager;

	VisualizationManager = `XCOMVISUALIZATIONMGR;
	VisualizationManager.RemoveObserver(self);

	OnlineSub.SystemInterface.ClearLinkStatusChangeDelegate(LinkStatusChange);
	OnlineSub.SystemInterface.ClearConnectionStatusChangeDelegate(ConnectionStatusChange);
	OnlineSub.GameInterface.ClearEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
	OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	`ONLINEEVENTMGR.ClearLoginStatusChangeDelegate(LoginStatusChange);
	`ONLINEEVENTMGR.ClearCheckReadyForGameInviteAcceptDelegate(OnCheckReadyForGameInviteAccept);
	super.Destroyed();
}

simulated function OnEndOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful));
	OnlineSub.GameInterface.ClearEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
	OnlineSub.GameInterface.AddDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	OnlineSub.GameInterface.DestroyOnlineGame(PlayerReplicationInfo.SessionName);
}

simulated function OnDestroyedOnlineGame(name SessionName,bool bWasSuccessful)
{
	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful) @ `ShowVar(m_bReturnToMPMainMenu));
	OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	CleanedUpOnlineGame();
}

simulated function CleanedUpOnlineGame()
{
	ClientFinishGameOver(m_bReturnToMPMainMenu);
	m_bHasCleanedUpGame = true; // Client
	m_bIsCleaningUpGame = false;
	ExitOrStay();
}

defaultproperties
{
	m_bCamIsMoving=false
	m_bInCinematicMode=false
	iCurrentLevel=4
	CameraClass=class'XComCamera'
	CheatClass=class'XComTacticalCheatManager'
	InputClass=class'XComGame.XComTacticalInput'
	PresentationLayerClass=class'XComPresentationLayer'
//  MHU - Not using the below, acceleration driven from C++ until 
//	m_fAnalogAccel=2560.0f.  // Regular Unreal acceleration handling.
//	m_fAnalogDecel=8.0f     // Higher the value, the stronger the braking effect.
	m_bGridComponentHidden=true;
	m_bGridComponentDashingHidden=true;
	m_fThrottleReplicateMoveTimeSeconds=0.20f;
	m_bReturnToMPMainMenu=false
	m_bHasCleanedUpGame=false
	m_bIsCleaningUpGame=false
	m_bHasEndedSession=false
	m_bStartedWalking=true
	m_bQuickInterpolate=true

	//This needs to be true by default, so that the loot visuals can get updated and shown when loading a saved game.
	//(Carries assumption that we won't start in cinematic mode.)
	m_bShowLootVisuals=true
}




