//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComTacticalCheatManager extends XComCheatManager within XComTacticalController
	dependson(XComTacticalSoundManager)
	native(Core);

struct native ForcedAIMoveDestination
{
	var StateObjectReference UnitStateRef;
	var TTile MoveDestination;
};

var int DebugSpawnIndex;
var int m_iLastTeleportedAlien;
var bool bShowShotSummaryModifiers;
var bool bDebugDisableHitAdjustment;
var bool bDebugClimbOver;
var bool bDebugClimbOnto;
var bool bDebugCover;
var bool bShowActions;
var bool bAllUnits;
var bool bShowDestination;
var bool bInvincible;
var bool bUnlimitedAmmo;
var bool bUnlimitedActions;
var bool bMarker;
var bool bAIStates;
var bool bPlayerStates;
var bool bShowNamesOnly;
var bool bShowDropship;
var bool bShowTracking; // show AI tracking cue info, i.e. heard noises & alien death calls
var bool bShowVisibleEnemies;
var bool bMinimap;
var bool bShowCursorLoc;
var bool bShowCursorFloor;
var bool bShowLoot;
var bool bAllowFancyCameraStuff; // enables in development camera features
var Vector vDebugLoc;
var bool bTurning;
var bool bAITextSkipBase;
var bool bShowInteractMarkers;
var bool bShowFlankingMarkers;
var bool bForceGrenade;
var bool bShowAttackRange;
var bool bShowProjectilePath;
var bool bShowProjectiles;
var bool bDebugLoot;
var bool bDeadEye;
var bool bDeadEyeStats;
var bool bForceCritHits;
var bool bForceCriticalWound;
var bool bForceNoCriticalWound;
var bool bNoLuck;
var bool bNoLuckStats;
var bool bShowExposedCover;
var bool bShowAllBreadcrumbs;
var bool bShowTeamDestinations;
var bool bShowTerrorDestinations;
var bool bShowHiddenDestinations;
var bool bShowTeamDestinationScores;
var bool bShowTerrorDestinationScores;
var bool bShowCivTeamDestinations;
var bool bShowCivTeamDestinationScores;
var bool bAIUseReactionFireData;
var bool bRevealAllCivilians;
var bool bShowOrientation;
var int iTestHideableActors;
var bool bTestFlankingLocations;
var bool bDrawFracturedMeshEffectBoxes;
var bool bDebugInputState;
var bool bDebugPOI;
var bool bDebugDead;
var bool bSkipReactionFire;
var bool bAllGlamAlways;
var bool bForce3DHacking;
var bool DisableFirstEncounterVO;
var bool DebugStringPulling;
// Animation Debugging Variables END

// ToggleUnitVis Debugging Variables START
var Name m_ToggleUnitVis_UnitName;
// ToggleUnitVis Debugging Variables END

var bool bShowModifiers;
var bool bShowOverwatch;
var bool bVisualizeMove;

var bool bDebugCCState;

//var XComRandomList kRandList;

var bool bCloseCombatCheat;
var bool bCloseCombatDesiredResult;

var bool bThirdPersonAllTheTime;
var bool bForceOverheadView;

var Vector vReferencePoint;

var bool bShowPathFailures;

var bool bDebugTargeting; 
var bool bDebugFireActions;

var bool bDebugCoverActors;

var bool bDebugManeuvers;

var bool bDebugTimeDilation;

var bool bDebugWeaponSockets;

var bool bDebugOvermind;

//var array<int> arrAbilityForceEnable;
//var array<int> arrAbilityForceDisable;
var bool bAIGrenadeThrowingVis;
var bool bSkipNonMeleeAI;
var bool bDisableClosedMode;
var bool bDebugDestroyCover;
var bool bDebugPoison;

var bool bDisplayPathingFailures;
var Vector vLookAt;
var bool bDebugBeginMoveHang;
var bool bDebugFlight;

var bool bForceKillCivilians;
var bool bForceIntimidate;

var bool bShowUnitFlags;
var bool bDisableWorldMessages;
var bool bHideWorldMessagesInOTS; // Hide world messages in over the shoulder cam
var bool bWorldDebugMessagesEnabled;
var XComCoverPoint kDebugCover;
var bool bDebugLaunchCover;
var bool bDebugPathCover;
var bool m_bDebugPodValidation;  // Log tile search.
var bool m_bVisualPodValidationDebugging;
var bool bDisableTargetingOutline;
var bool bAlwaysRushCam;
var bool bDebugActiveAI;
var int  iRightSidePos;
var bool bShowShieldHP;
var name XCom_Anim_DebugUnitName;
var bool bShowMaterials;
var bool bTestAttackOnDropDown;
var bool bDebugBadAreaLog;
var bool bForcePodQuickMode;
var bool bDebugCameras;
var bool bForceAbilityOneTimeUse;
var bool bShowPatrolPaths;
var bool bDebugPatrols;
var bool bShowExplorationPoints;
var bool bShowAIVisRange;

var Name ShowRestrictorsForCharacterTemplate;

var bool bAllowSelectAll;
var bool bCombatLog;
var bool bGoldenPathHacks;
var bool bDebugAIDestinations;
var int  DebugMoveObjectID;
var bool bShowParcelNames;
var bool bShowObjectivesLocations;
var string strAIForcedAbility;
var bool bDebugReinforcementTriggers;
var bool bDebugSpawns;
var bool bDebugConcealment;
var bool bAIDisableIntent;
var bool bAIShowLastAction;
var bool bAbilitiesDoNotTriggerAlienRulerAction;

var array<string> strLastAIAbility;

var X2Camera_LookAtLocation kLookAtCamera;

var bool m_bEnableBuildingVisibility_Cheat;
var bool m_bEnableCutoutBox_Cheat;
var bool m_bEnablePeripheryHiding_Cheat;
var bool m_bShowPOILocations_Cheat;
var bool bEnableProximityDither_Cheat;
var float m_fCutoutBoxSize_Cheat;

var string m_strBTIntent;

var bool bAbortScampers;
var TPOV LastPOV;

var bool bForceAttackRollValue;
var int  iForcedRollValue;
var TTile kInspectTile; 

var Name OpenAllDoorsSocketName;
var int iAIBTOverrideID;
var Name strAIBTOverrideNode;

//Set next shot damage parameters
var bool NextShotDamageRigged;
var int  NextShotDamage;

//Like dead eye, but for seeing movement
var bool OverrideCanSeeMovement;
var bool CanSeeMovement;

var bool bDebugJobManager;

var bool bDebugFightManager; // Toggle on and off onscreen debug text displaying AI DownThrottling and UpThrottling values.
var bool bDisableFightManager;     // Disable fight manager from processing.  UpThrottling & DownThrottling disabled.
var bool bFightMgrForceUpThrottle; // Enable FightMgr UpThrottle testing.
var bool bFightMgrForceDownThrottle; // Enable FightMgr DownThrottle testing.

var bool bAllPodsConvergeOnMissionComplete;

var bool bDisablePanic;
var bool bAlwaysPanic;
var bool bDisableSecondaryFires;

var bool bShowCivilianLabels;

var bool bHidePathingPawn;

// allows the LDs to specify an exact level actor to hit with gun projectiles on a missed shot 
var privatewrite string ForceMissedProjectileHitActorTag;

var privatewrite bool UseForceMissedProjectileHitTile;
var privatewrite TTile ForceMissedProjectileHitTile;

var bool bDisplayAlertDataLabels;
var int DisplayAlertDataLabelID;

var bool ForceAllUnitsVisible; // force all unit models to be visible to all players, regardless of gameplay visibility

var array<ForcedAIMoveDestination> ForcedDestinationQueue;
var int AISetDestination;

var bool bDisableLookAtBackPenalty;
var bool bDisableTutorialPopups;
var bool bAlwaysBleedOut;

var bool bDebugIdleAnimationStateMachines;

var bool bDebugPodReveals;
var string PodRevealDecisionRecord;
var bool DisableCrosscutFail;
var bool DisableLookAtBackFail;
var bool DisablePodRevealLeaderCollisionFail;

// if set, will force the specified object to be the target of the next overwatch ability (when it moves)
var StateObjectReference ForcedOverwatchTarget;

var bool bShowEscapeOptions;
var bool bShowInitiative;
var bool bDebugLostSpawning;
var bool bDebugChosen;
var int ChosenID;
var bool bXComOnlyDeadEye;
var bool bSkipPreDeathCheckEffects;

var int CheatMaxFocus;

var bool bQuickTargetSelectEnabled;

var bool bShowActiveBTNode;
var bool bShowAoETargetResults;
var int SkipAllAIExceptUnitID;
exec function ProfileTileRebuild(int MinX, int MinY, int MinZ, int MaxX, int MaxY, int MaxZ)
{
	local XComWorldData WorldData;
	local TTile Min;
	local TTile Max;

	WorldData = `XWORLD;

	Min.X = MinX;
	Min.Y = MinY;
	Min.Z = MinZ;

	Max.X = MaxX;
	Max.Y = MaxY;
	Max.Z = MaxZ;

	WorldData.ProfileTileRebuild(Min, Max);
}

native function HideGFXUI(bool bEnable);

exec native function CheckForDuplicateLevelActors() const;

exec function DropProxy()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local XComGameState_Player PlayerState;
	local X2TacticalGameRuleset Rules;
	local XComGameState_Unit OriginalUnit;
	local XComGameState_Unit ProxyUnit;
	local XComGameStateContext_TacticalGameRule NewGameStateContext;
	local Vector CursorLocation;
	local TTile CursorTile;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;
	Rules = `TACTICALRULES;

	OriginalUnit = GetClosestUnitToCursor();

	NewGameStateContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitAdded);
	NewGameState = NewGameStateContext.ContextBuildGameState( );

	ProxyUnit = class'XComTacticalMissionManager'.static.CreateProxyRewardUnitIfNeeded(OriginalUnit, NewGameState);
	CursorLocation = GetCursorLoc();
	CursorTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);
	ProxyUnit.SetVisibilityLocation(CursorTile);
	Rules.InitializeUnitAbilities(NewGameStateContext.AssociatedState, ProxyUnit);
	
	NewGameStateContext.UnitRef = ProxyUnit.GetReference();

	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(OriginalUnit.GetAssociatedPlayerID()));
	class'XGUnit'.static.CreateVisualizer(NewGameState, ProxyUnit, PlayerState);

	if(!Rules.SubmitGameState(NewGameState))
	{
		`Redscreen("DropProxy(): Could not drop a proxy!");
	}
}

exec function ShowModalTutorialDialogBox(int TitleObjectiveTextIndex, int ObjectiveTextIndex)
{
	class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistory(TitleObjectiveTextIndex, ObjectiveTextIndex);
}

exec function ShowBladeTutorialDialogBox(string MessageID, int ObjectiveTextIndex)
{
	class'XComGameStateContext_TutorialBox'.static.AddBladeTutorialBoxToHistory(MessageID, ObjectiveTextIndex);
}

exec function RemoveBladeTutorialDialogBox(string MessageID)
{
	class'XComGameStateContext_TutorialBox'.static.RemoveBladeTutorialBoxFromHistory(MessageID);
}

exec function DisableBuildingVisibility(bool bEnable)
{
	BuildingVisEnable(bEnable);
	CutoutBoxEnable(bEnable);
}

exec function BuildingVisEnable(bool bEnable)
{
	m_bEnableBuildingVisibility_Cheat = bEnable;
}

exec function CutoutBoxEnable(bool bEnable)
{
	m_bEnableCutoutBox_Cheat = bEnable;
}

exec function PeripheryHidingEnable(bool bEnable)
{
	m_bEnablePeripheryHiding_Cheat = bEnable;
}

exec function ShowPOILocation(optional bool bEnable = true)
{
	m_bShowPOILocations_Cheat = bEnable;
}

exec function ProximityDitherEnable(bool bEnable)
{
	bEnableProximityDither_Cheat = bEnable;
}

exec function CutoutBoxSize(float fSize)
{
	m_fCutoutBoxSize_Cheat = fSize;
}

exec function X2DebugSoldierSpawns()
{
	`PARCELMGR.DebugSoldierSpawns();
}

exec function SetCrosscutFailDisabled(bool Disabled)
{
	DisableCrosscutFail = Disabled;
}

exec function SetLookAtBackFailDisabled(bool Disabled)
{
	DisableLookAtBackFail = Disabled;
}

exec function SetPodRevealLeaderCollisionFailDisabled(bool Disabled)
{
	DisablePodRevealLeaderCollisionFail = Disabled;
}

exec function SnapToGround()
{
	local XGUnit ActiveUnit;
	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if( ActiveUnit == none )
	{
		return;
	}

	ActiveUnit.SnapToGround();
}

exec function TestUnitPathSolver(optional bool LimitToUnitRange = false)
{
	local XComWorldData WorldData;
	local XGUnit ActiveUnit;
	local XComGameState_Unit UnitState;
	local array<TTile> Path;
	local Vector CursorLoc;
	local TTile CursorTile;
	local TTile Tile;
	local Vector PreviousNodePosition;
	local Vector NodePosition;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if(ActiveUnit == none) return;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.ObjectID));
	if(UnitState == none) return;

	// get the cursor's tile location
	WorldData = `XWORLD;
	CursorLoc = GetCursorLoc();
	WorldData.GetFloorTileForPosition(CursorLoc, CursorTile);

	// build a path to the cursor location
	class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, CursorTile, Path, LimitToUnitRange);

	// and draw it
	NodePosition = ActiveUnit.GetLocation();
	foreach Path(Tile)
	{
		PreviousNodePosition = NodePosition;
		NodePosition = WorldData.GetPositionFromTileCoordinates(Tile);
		`BATTLE.DrawDebugLine(PreviousNodePosition, NodePosition, 255, 255, 255, true);
	}
}

exec function TestNonUnitPathSolver()
{
	local XComWorldData WorldData;
	local XGUnit ActiveUnit;
	local XComGameState_Unit UnitState;
	local array<ETraversalType> ValidTraversals;
	local array<TTile> Path;
	local Vector CursorLoc;
	local TTile CursorTile;
	local TTile Tile;
	local Vector PreviousNodePosition;
	local Vector NodePosition;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if(ActiveUnit == none) return;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.ObjectID));
	if(UnitState == none) return;

	// get the cursor's tile location
	WorldData = `XWORLD;
	CursorLoc = GetCursorLoc();
	WorldData.GetFloorTileForPosition(CursorLoc, CursorTile);

	// build a path to the cursor location
	ValidTraversals.AddItem(eTraversal_Normal);
	ValidTraversals.AddItem(eTraversal_ClimbOver);
	class'X2PathSolver'.static.BuildNonUnitPath(UnitState.TileLocation, CursorTile, ValidTraversals, Path);

	// and draw it
	NodePosition = ActiveUnit.GetLocation();
	foreach Path(Tile)
	{
		PreviousNodePosition = NodePosition;
		NodePosition = WorldData.GetPositionFromTileCoordinates(Tile);
		`BATTLE.DrawDebugLine(PreviousNodePosition, NodePosition, 255, 255, 255, true);
	}
}

exec function StartRagdoll()
{
	local XGUnit ActiveUnit;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if( ActiveUnit == None )
	{
		return;
	}

	ActiveUnit.GetPawn().StartRagdoll();
}

exec function EndRagdoll()
{
	local XGUnit ActiveUnit;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if( ActiveUnit == None )
	{
		return;
	}

	ActiveUnit.GetPawn().EndRagdoll();
}

exec function ShowReachableTilesCache( bool bUseClosestUnitToCursor=false )
{
	local XGUnit ActiveUnit;

	if (bUseClosestUnitToCursor)
	{
		ActiveUnit = XGUnit(GetClosestUnitToCursor().GetVisualizer());
	}
	else
	{
		ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	}
	if(ActiveUnit == none) return;

	ActiveUnit.m_kReachableTilesCache.DebugDrawTiles();
}

exec function TestReachableTilesCache()
{
	local XComWorldData WorldData;
	local XGUnit ActiveUnit;
	local XComGameState_Unit UnitState;
	local array<TTile> Path;
	local Vector CursorLoc;
	local TTile CursorTile;
	local TTile Tile;
	local Vector PreviousNodePosition;
	local Vector NodePosition;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if(ActiveUnit == none) return;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.ObjectID));
	if(UnitState == none) return;

	// get the cursor's tile location
	WorldData = `XWORLD;
	CursorLoc = GetCursorLoc();
	WorldData.GetFloorTileForPosition(CursorLoc, CursorTile);

	// build a path to the cursor location
	ActiveUnit.m_kReachableTilesCache.BuildPathToTile(CursorTile, Path);

	// and draw it
	NodePosition = ActiveUnit.GetLocation();
	foreach Path(Tile)
	{
		PreviousNodePosition = NodePosition;
		NodePosition = WorldData.GetPositionFromTileCoordinates(Tile);
		`BATTLE.DrawDebugLine(PreviousNodePosition, NodePosition, 255, 255, 255, true);
	}
}

exec function ForceUpdateReachableTilesCache( bool bUseClosestUnitToCursor=false )
{
	local XGUnit ActiveUnit;

	if (bUseClosestUnitToCursor)
	{
		ActiveUnit = XGUnit(GetClosestUnitToCursor().GetVisualizer());
	}
	else
	{
		ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	}
	if(ActiveUnit == none) return;

	ActiveUnit.m_kReachableTilesCache.ForceCacheUpdate();
}

exec function ProfileReachableTilesCache()
{
	local XGUnit ActiveUnit;
	local TTile Origin;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();

	while(true)
	{
		ActiveUnit.m_kReachableTilesCache.ForceCacheUpdate();
		ActiveUnit.m_kReachableTilesCache.IsTileReachable(Origin);
	}
}

exec function PlaceSquadViewer(optional int TileRadius = 4)
{
	local XComGameState NewGameState;
	local XComGameState_SquadViewer SquadViewer;
	local XComWorldData WorldData;
	local X2TacticalGameRuleset Rules;
	local Vector CursorLocation;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Add SquadViewer object.");
	SquadViewer = XComGameState_SquadViewer(NewGameState.CreateNewStateObject(class'XComGameState_SquadViewer'));

	WorldData = `XWORLD;
	CursorLocation = GetCursorLoc();
	SquadViewer.ViewerTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);
	SquadViewer.ViewerRadius = TileRadius;

	Rules = `TACTICALRULES;
	if(!Rules.SubmitGameState(NewGameState))
	{
		`Redscreen("PlaceSquadViewer(): Could not submit state!");
	}

	SquadViewer.FindOrCreateVisualizer();
}

exec function X2CameraLookAtTarget(int TargetID, float LookAtDuration = 5.0, bool UseTether = false, float TargetZoomAfterArrival = 0.0, float ZoomTime = -1.0, bool SnapToFloor = false)
{
	local XComGameStateHistory History;
	local X2Camera_LookAtActorTimed LookAtActorCamera;

	if( ZoomTime < 0.0 )
	{
		ZoomTime = LookAtDuration;
	}

	History = `XCOMHISTORY;

	LookAtActorCamera = new class'X2Camera_LookAtActorTimed';
	LookAtActorCamera.ActorToFollow = History.GetVisualizer(TargetID);
	LookAtActorCamera.LookAtDuration = LookAtDuration;
	LookAtActorCamera.UseTether = UseTether;
	LookAtActorCamera.SnapToFloor = SnapToFloor;
	LookAtActorCamera.ZoomCameraPushIn(TargetZoomAfterArrival, ZoomTime);
	`CAMERASTACK.AddCamera(LookAtActorCamera);
}

exec function X2CreateFOWViewer(int TargetID, float ScanningRadius = 768.0)
{
	local XComGameStateHistory History;
	local DynamicPointInSpace Viewer;

	History = `XCOMHISTORY;
		
	Viewer = DynamicPointInSpace(`XWORLD.CreateFOWViewer(History.GetVisualizer(TargetID).Location, ScanningRadius));
	Viewer.SetObjectID(TargetID);

	`XWORLD.ForceFOWViewerUpdate(Viewer);
}

exec function X2DestroyFOWViewer(int TargetID)
{
	local DynamicPointInSpace Viewer;

	foreach `XWORLDINFO.AllActors(class'DynamicPointInSpace', Viewer)
	{
		if( Viewer.ObjectID == TargetID )
		{
			`XWORLD.DestroyFOWViewer(Viewer);
		}
	}
}

exec function X2DebugCameras()
{
	bDebugCameras = !bDebugCameras;
}

exec function X2ForceOTSCamera(int ForceCameraIndex)
{
	local X2Camera_OverTheShoulder OTSCamera;

	OTSCamera = X2Camera_OverTheShoulder(GetActiveUnit().TargetingCamera);
	if(OTSCamera != none)
	{
		OTSCamera.DebugForceCameraSelection(ForceCameraIndex);
	}
}

// Currently used in StatContest check, to force a specific MindSpin ability.
exec function ForceHitCalcAttackRollValue(int iValue)
{
	bForceAttackRollValue = !bForceAttackRollValue;
	if (bForceAttackRollValue)
	{
		iForcedRollValue = iValue;
	}
	`Log(`ShowVar(bForceAttackRollValue)@ `ShowVar(iForcedRollValue));

}

exec function GiveActionPoints(optional int ActionPoints=200, optional int UnitStateObjectID=0, optional name Type)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local int i;

	if (Type == '')
		Type = class'X2CharacterTemplateManager'.default.StandardActionPoint;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitStateObjectID == 0 ? GetActiveUnit().ObjectID : UnitStateObjectID));
	if (Unit == none)
	{
		`log("Could not get a unit for object ID" @ UnitStateObjectID);
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Give" @ ActionPoints @ "Action Points");
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(Unit.Class, Unit.ObjectID));
	for (i = 0; i < ActionPoints; ++i)
	{
		Unit.ActionPoints.AddItem(Type);
	}

	`TACTICALRULES.SubmitGameState(NewGameState);
}

//Maybe move to XComGameState_Unit? This has the basic elements necessary to support old-school inventory swapping
exec function GiveItem(string ItemTemplateName)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate ItemTemplate;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local XGUnit Visualizer;
	local XComGameState_Item Item;
	local XComGameState_Item OldItem;
	local XComGameStateHistory History;
	local XGItem OldItemVisualizer;
	local XComGameState_Player kPlayer;

	local XComGameState_Ability ItemAbility;	
	local int AbilityIndex;
	local array<AbilitySetupData> AbilityData;
	local X2TacticalGameRuleset TacticalRules;

	History = `XCOMHISTORY;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(name(ItemTemplateName)));
	if(ItemTemplate == none) return;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Give Item '" $ ItemTemplateName $ "'");

	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnit().ObjectID));
	Visualizer = XGUnit(Unit.GetVisualizer());

	Item = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

	//Take away the old item
	if (ItemTemplate.InventorySlot == eInvSlot_PrimaryWeapon ||
		ItemTemplate.InventorySlot == eInvSlot_SecondaryWeapon ||
		ItemTemplate.InventorySlot == eInvSlot_HeavyWeapon)
	{
		OldItem = Unit.GetItemInSlot(ItemTemplate.InventorySlot);
		Unit.RemoveItemFromInventory(OldItem, NewGameState);		

		//Remove abilities that were being granted by the old item
		for( AbilityIndex = Unit.Abilities.Length - 1; AbilityIndex > -1; --AbilityIndex )
		{
			ItemAbility = XComGameState_Ability(History.GetGameStateForObjectID(Unit.Abilities[AbilityIndex].ObjectID));
			if( ItemAbility.SourceWeapon.ObjectID == OldItem.ObjectID )
			{
				Unit.Abilities.Remove(AbilityIndex, 1);
			}
		}
	}

	Unit.bIgnoreItemEquipRestrictions = true; //Instruct the system that we don't care about item restrictions
	Unit.AddItemToInventory(Item, ItemTemplate.InventorySlot, NewGameState);	

	//Give the unit any abilities that this weapon confers
	kPlayer = XComGameState_Player(History.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));			
	AbilityData = Unit.GatherUnitAbilitiesForInit(NewGameState, kPlayer);
	TacticalRules = `TACTICALRULES;
	for (AbilityIndex = 0; AbilityIndex < AbilityData.Length; ++AbilityIndex)
	{
		if( AbilityData[AbilityIndex].SourceWeaponRef.ObjectID == Item.ObjectID )
		{
			TacticalRules.InitAbilityForUnit(AbilityData[AbilityIndex].Template, Unit, NewGameState, AbilityData[AbilityIndex].SourceWeaponRef);
		}
	}

	TacticalRules.SubmitGameState(NewGameState);

	if( OldItem.ObjectID > 0 )
	{
		//Destroy the visuals for the old item if we had one
		OldItemVisualizer = XGItem(History.GetVisualizer(OldItem.ObjectID));
		OldItemVisualizer.Destroy();
		History.SetVisualizer(OldItem.ObjectID, none);
	}
	
	//Create the visualizer for the new item, and attach it if needed
	Visualizer.ApplyLoadoutFromGameState(Unit, NewGameState);
}

exec function X2DebugPodReveals()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_AIGroup AIGroupState;	

	History = `XCOMHISTORY;

	Unit = XComGameState_Unit(History.GetGameStateForObjectID(GetActiveUnitStateRef().ObjectID));
	foreach History.IterateByClassType(class'XComGameState_AIGroup', AIGroupState)
	{
		AIGroupState.ApplyAlertAbilityToGroup(eAC_TakingFire);
		AIGroupState.InitiateReflexMoveActivate(Unit, eAC_SeesSpottedUnit);
	}
}

exec function GiveAbility(name AbilityName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local X2TacticalGameRuleset TacticalRules;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local bool UnitAlreadyHasAbility;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

	if( AbilityTemplate != None )
	{
		// give the ability to the current unit
		History = `XCOMHISTORY;
			TacticalRules = `TACTICALRULES;

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Give Ability '" $ AbilityName $ "'");

		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnitStateRef().ObjectID));

		// see if the unit already has this ability
		UnitAlreadyHasAbility = (Unit.FindAbility(AbilityName).ObjectID > 0);

		if( !UnitAlreadyHasAbility )
		{
			TacticalRules.InitAbilityForUnit(AbilityTemplate, Unit, NewGameState);
			TacticalRules.SubmitGameState(NewGameState);
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}
}

exec function X2GrantAbility(name AbilityName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local X2TacticalGameRuleset TacticalRules;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local bool UnitAlreadyHasAbility;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

	if (AbilityTemplate != None)
	{
		// give the ability to the current unit
		History = `XCOMHISTORY;
		TacticalRules = `TACTICALRULES;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Grant Ability '" $ AbilityName $ "'");

		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnitStateRef().ObjectID));

		// see if the unit already has this ability
		UnitAlreadyHasAbility = (Unit.FindAbility(AbilityName).ObjectID > 0);

		if (!UnitAlreadyHasAbility)
		{
			TacticalRules.InitAbilityForUnit(AbilityTemplate, Unit, NewGameState);
			TacticalRules.SubmitGameState(NewGameState);
			`log("Granted ability.");
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
			`log("Unit already has that ability.");
		}		
	}
}

exec function X2UseAbility(name AbilityName, int SpecificTargetID=-1)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local XComGameState_Ability ExistingAbility;
	local X2TacticalGameRuleset TacticalRules;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local bool UnitAlreadyHasAbility;
	local XComGameStateContext_Ability AbilityContext;
	local array<vector> TargetLocations;
	local bool bExistingAttackRollValueOverride;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);
	
	if( AbilityTemplate != None )
	{
		// give the ability to the current unit
		History = `XCOMHISTORY;
		TacticalRules = `TACTICALRULES;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Use Ability '" $ AbilityName $ "'");

		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnitStateRef().ObjectID));

		// see if the unit already has this ability
		UnitAlreadyHasAbility = (Unit.FindAbility(AbilityName).ObjectID > 0);

		if( !UnitAlreadyHasAbility )
		{
			TacticalRules.InitAbilityForUnit(AbilityTemplate, Unit, NewGameState);
			TacticalRules.SubmitGameState(NewGameState);
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}

		// choose the ability target
		if( SpecificTargetID < 0 )
		{
			SpecificTargetID = GetClosestUnitToCursor().ObjectID;
		}
		TargetLocations.AddItem(GetCursorLoc());

		// use the ability
		ExistingAbility = XComGameState_Ability(History.GetGameStateForObjectID(Unit.FindAbility(AbilityName).ObjectID));

		// force an attack roll value of 1 if none is already set
		bExistingAttackRollValueOverride = bForceAttackRollValue;
		if( !bForceAttackRollValue )
		{
			ForceHitCalcAttackRollValue(1);
		}

		AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(ExistingAbility, SpecificTargetID, , TargetLocations);

		// we explicitly do not want to validate this ability
		AbilityContext.bSkipValidation = true;

		// force the hit to be successful
		AbilityContext.ResultContext.HitResult = eHit_Success;

		TacticalRules.SubmitGameStateContext(AbilityContext);

		if( !bExistingAttackRollValueOverride )
		{
			// reset to previous state
			ForceHitCalcAttackRollValue(0);
		}
	}
}

exec function SwapBiomeType(string NewPlotType, optional string NewBiomeType, optional string NewMissionType)
{
	local XComParcelManager ParcelManager;

	ParcelManager = `PARCELMGR;

	if(ParcelManager != none)
	{
		class'XComPlotSwapData'.static.AdjustParcelsForBiomeType(NewBiomeType, NewPlotType, NewMissionType);
	}
}

//------------------------------------------------------------------------------------------------
exec function ShowParcelNames()
{
	bShowParcelNames = !bShowParcelNames;
}
exec function ShowObjectiveNames()
{
	bShowObjectivesLocations = !bShowObjectivesLocations;
}
//------------------------------------------------------------------------------------------------
exec function AIDebugDestinations( int ObjectID=0 )
{
	local XComGameState_Unit Unit;

	if( ObjectID == 0 )
	{
		Unit = GetClosestUnitToCursor(); // Use closest unit to cursor when no id is set.
		ObjectID = Unit.ObjectID;
	}

	// Toggle if same id.
	if( DebugMoveObjectID == ObjectID )
	{
		bDebugAIDestinations = !bDebugAIDestinations;
	}
	else
	{
		// Otherwise set new ID.
		DebugMoveObjectID = ObjectID;
		bDebugAIDestinations = true;
	}
	`Log("bDebugAIDestinations="$bDebugAIDestinations);
}
//------------------------------------------------------------------------------------------------
exec function AIDebugActiveList( int iRight=0 )
{
	if (iRight != 0)
	{
		iRightSidePos = iRight;
	}
	bDebugActiveAI = !bDebugActiveAI;
}
//------------------------------------------------------------------------------------------------
exec function PlayDeath()
{
	MakeCharacterSpeak( 'DeathScream' );
	PlaySound( SoundCue(DynamicLoadObject("SoundAmbience.DeathStingCue", class'SoundCue')), true );
}
//------------------------------------------------------------------------------------------------
exec function PlayStabilize()
{
	MakeCharacterSpeak( 'StabilizingAlly' );
	PlaySound( SoundCue(DynamicLoadObject("SoundAmbience.SoldierStabilizedCue", class'SoundCue')), true );
}
//------------------------------------------------------------------------------------------------
exec function PlayRevive()
{
	MakeCharacterSpeak( 'RevivingAlly' );
	PlaySound( SoundCue(DynamicLoadObject("SoundAmbience.SoldierRevivedCue", class'SoundCue')), true );
}

//------------------------------------------------------------------------------------------------
exec function ClearDebug()
{
	`SHAPEMGR.FlushPersistentShapes();
	FlushPersistentDebugLines();
	FlushDebugStrings();
}
//------------------------------------------------------------------------------------------------
exec function ShowEscapeOptions()
{
	bShowEscapeOptions = !bShowEscapeOptions;
	`Log(`ShowVar(bShowEscapeOptions));
}

//------------------------------------------------------------------------------------------------
exec function ShowInitiative()
{
	local UITurnOverlay TurnOverlay;

	bShowInitiative = !bShowInitiative;
	`Log(`ShowVar(bShowInitiative));

	foreach DynamicActors(class'UITurnOverlay', TurnOverlay)
	{
		TurnOverlay.ShowOrHideInitiative();
	}
}

//------------------------------------------------------------------------------------------------
exec function AIDebugPodValidation( bool bVisual = false )
{
	m_bDebugPodValidation = !m_bDebugPodValidation;
	if (m_bDebugPodValidation)
	{
		m_bVisualPodValidationDebugging=bVisual;
	}
	`Log("m_bDebugPodValidation="$m_bDebugPodValidation@"(Visual="$m_bVisualPodValidationDebugging$")");
}

//------------------------------------------------------------------------------------------------
exec function AIForceIntimidate()
{
	bForceIntimidate = !bForceIntimidate;
	`Log("bForceIntimidate = "$bForceIntimidate);
}
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
exec function AIShowPatrolPaths()
{
	bShowPatrolPaths = !bShowPatrolPaths;
	`Log("bShowPatrolPaths = "$bShowPatrolPaths);
}

//------------------------------------------------------------------------------------------------

exec function TestClosestPointToCursorOnAxis()
{
	local XGAIPlayer kAI;
	local vector vLoc;
	kAI = XGAIPlayer(`BATTLE.GetAIPlayer());
	vLoc = kAI.m_kNav.GetClosestPointAlongLineToTestPoint(kAI.m_kNav.m_kAxisOfPlay.v1, kAI.m_kNav.m_kAxisOfPlay.v2, GetCursorLoc());
	DrawSphereV(vLoc);
}
//------------------------------------------------------------------------------------------------

exec function EndBattle(optional bool XComWins = true)
{
	local X2TacticalGameRuleset Ruleset;
	local XGBattle_SP Battle;

	Ruleset = `TACTICALRULES;
	Battle = XGBattle_SP(`BATTLE);

	if(Battle != none && Ruleset != none)
	{
		Ruleset.EndBattle(XComWins ? Battle.GetHumanPlayer() : Battle.GetAIPlayer());
	}
}

exec function AIDebugFlight()
{
	bDebugFlight = !bDebugFlight;
}
//------------------------------------------------------------------------------------------------
exec function DebugPoison()
{
	bDebugPoison = !bDebugPoison; 
}
//------------------------------------------------------------------------------------------------
exec function DebugOvermind()
{
	bDebugOvermind = !bDebugOvermind;
}
//------------------------------------------------------------------------------------------------
exec function AIDisplayPathingFailures()
{
	bDisplayPathingFailures=!bDisplayPathingFailures;
}

//------------------------------------------------------------------------------------------------
exec function AISkipNonMeleeAI()
{
	bSkipNonMeleeAI = !bSkipNonMeleeAI;
	`Log("SkipNonMeleeAI = "$bSkipNonMeleeAI);
}
//------------------------------------------------------------------------------------------------
exec function AIGrenadeThrowing()
{
	bAIGrenadeThrowingVis = !bAIGrenadeThrowingVis;
}
//------------------------------------------------------------------------------------------------
//exec function AIAbilityForceEnable( string strAbility, bool bOneTimeUse=false )
//{
//	local int iType;
//	local eAbility eType;
//	local string strType;
//	local bool bFound;
//	arrAbilityForceDisable.Length = 0;
//	arrAbilityForceEnable.Length = 0;
//	// Set all disabled except ability.
//	for (iType=0; iType < eAbility_MAX; iType++)
//	{
//		eType = eAbility(iType);
//		strType = string(eType);
//		if (Caps(strType) == Caps(strAbility))
//		{
//			bFound = true;
//			arrAbilityForceEnable.AddItem(iType);
//		}
//		else
//		{
//			arrAbilityForceDisable.AddItem(iType);
//		}
//	}
//
//	if (bFound)
//	{
//		`Log("Force enable ability: "$strAbility);
//		bForceAbilityOneTimeUse=bOneTimeUse;
//	}
//	else
//	{
//		`Log(strAbility@" not found.  No abilities forced.");
//		arrAbilityForceDisable.Length = 0;
//	}
//}
//
exec function ToggleDebugWeaponSockets()
{
	bDebugWeaponSockets = !bDebugWeaponSockets;
}

exec function Toggle3DHackScreen()
{
	bForce3DHacking = !bForce3DHacking;
}

/*
 *  Aim Adjustment for too many misses from a unit
 *  giving them an adjusted handicap
 */
exec function DisableAimAdjust(bool shouldDisableAdjustedAim)
{
	bDebugDisableHitAdjustment = shouldDisableAdjustedAim;
	if (bDebugDisableHitAdjustment)
		`log("Disabled Aim Adjustment");
	else
		`log("Enabled Aim Adjustment");
}

exec function DebugFireActions(optional int iOn=-1)
{
	if(iOn == 1)
	{
		bDebugFireActions = true;
	}
	else if(iOn == 0)
	{
		bDebugFireActions = false;
	}
	else
	{
		bDebugFireActions = !bDebugFireActions;
	}

	`log("bDebugFireActions=" $ bDebugFireActions);
}

exec function ToggleThirdPersonAllTheTime()
{
	bThirdPersonAllTheTime = !bThirdPersonAllTheTime;
	bForceOverheadView = bThirdPersonAllTheTime;
	`log("bThirdPersonAllTheTime:"@bThirdPersonAllTheTime);
}

exec function ToggleThirdPerson()
{
	bForceOverheadView = !bForceOverheadView;
	`log("bForceOverheadView:"@bForceOverheadView);
}

exec function DEMOCams()
{
	bThirdPersonAllTheTime = true;
	bForceOverheadView = false;
}

exec function ToggleCutoutBoxVisibility ()
{
	local XComCutoutBox kCutoutBox;
	foreach AllActors(class'XComCutoutBox', kCutoutBox)
	{
		kCutoutBox.SetHidden(!kCutoutBox.bHidden);
	}
}

exec function LoadSavedCamera()
{
	local XComCamera kCamera;

	// A dodgey way of checking if a camera cache is available...
	// This command is for debugging so this is good enough for debugging.
	if (`BATTLE.m_kLevel.SavedCameraCache.POV.Location != vect(0,0,0))
	{
		kCamera = XComCamera( XComTacticalController(GetALocalPlayerController()).PlayerCamera );
		kCamera.GotoState('DebugView');
		kCamera.CameraCache = `BATTLE.m_kLevel.SavedCameraCache;
	}
}

exec function ToggleTargetingOutline()
{
	bDisableTargetingOutline = !bDisableTargetingOutline;
}

exec function CursorTraceExtent(float factor)
{
	local XCom3DCursor kCursor;

	foreach DynamicActors(class'XCom3DCursor', kCursor) 
	{
		break;
	}

	if (kCursor == none)
	{
		`log("Could not find XCom3DCursor");
	}

	kCursor.m_fCursorExtentFactor = factor;
}

exec function SetOutlineType(int mode)
{
	local XComVis Vis;

	foreach DynamicActors(class'XComVis', Vis) 
	{
		break;
	}

	if (Vis == none)
	{
		`log("Could not find XComVis actor");
	}

	Vis.SetOutlineType(mode);
}


exec function  Help(optional string tok)
{
	 super.Help(tok);

	 if(Len(tok) == 0)
	 {
		 HelpDESC( "AddSectoids(n)", "Drop n Sectoids");
		 HelpDESC( "AddUnits(n)",    "Drop n Units");
		 HelpDESC( "AddTime", "Max out current unit's time points");
		 HelpDESC( "AIMarkers", "show hidden AI units" );
		 HelpDESC( "teleportAlienToCursor",      "move an Alien to the cursor position");
		 HelpDESC( "AISkipAI", "Disable/Enable AI's turn" );
		 HelpDESC( "AIWatchAI", "Set camera over AI units on their turn, hidden or not." );
		 HelpDESC( "AbortCurrentAction", "Abort currently active unit's action");
		 HelpDESC( "TakeNoDamage", "Bypass any SetHitPoint calls, rendering all units invincible." );
		 HelpDESC( "PowerUp", "All units invincible, unlimited ammo." );
		 HelpDESC( "TogglePathUpdate", "Toggle whether to update the cursor path while the cursor is moving");
		 HelpDESC( "PsiLevel(n)", "0 = normal, 1 = All Psi All the Time, 2 = Psi Off");
		 HelpDESC( "UIToggleDisc", "Toggles the unit's Unreal-native selection disc on/off." );
		 HelpDESC( "UIEnableEnemyArrows", "Turns the enemy arrow hover indicators on/off." );
	 }
}


exec function Prop (int n)
{
	//local RenderChannelContainer R;
	local XComVis kVisTemp, kVis;

	iTestHideableActors = n;

	if (n == 1)
	{
		foreach AllActors(class'XComVis', kVisTemp)
		kVis = kVisTemp;
		if (kVis == none)
		{
			`log("Spawning XComVis");
			kVis = Spawn(class'XComVis', none);
			kVis.InitResources();
		}
	}
}

// Immediately set the post-process shader used for the alien turn.
exec function AlienTurnIntensity (float x)
{
	local MaterialInstanceConstant kMIC;
	kMIC = MaterialInstanceConstant'XComEngineMaterials.PPM_Vignette';
	kMIC.SetScalarParameterValue('Vignette_Intensity', x);
}

exec function ListAbilities( int ObjectID=0)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local StateObjectReference AbilityRef;

	History = `XCOMHISTORY;

	if ( ObjectID == 0 && GetActiveUnit() != none)
	{
		ObjectID == GetActiveUnit().ObjectID;
	}

	if (ObjectID > 0)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
		if (UnitState != none)
		{
			foreach UnitState.Abilities(AbilityRef)
			{
				AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
				`log(AbilityState.GetMyTemplateName() @ AbilityState.ToString());
			}
		}
	}	
}

exec function BuildingVis2 (int n)
{
`if (`notdefined(FINAL_RELEASE))
	local XComFracLevelActor kFrac;
	local RenderChannelContainer R;
	local int count;

	count = 0;
	foreach AllActors(class'XComFracLevelActor', kFrac)
	{
		R = kFrac.FracturedStaticMeshComponent.RenderChannels;
		R.Occluded = true;
		kFrac.FracturedStaticMeshComponent.SetRenderChannels(R);
		count++;
	}
	`log("count:" @ count);
`endif
}

// Turn off building cutdown, cutoff and hiding for debugging only
native function NativeSetBuildingToggle();

exec function BuildingVisToggle ()
{
`if (`notdefined(FINAL_RELEASE))
	NativeSetBuildingToggle();
`endif
}

exec function ToggleUnitVis(bool bEnable, bool bActiveUnitOnly, bool bVisualizeFOW)
{
	local XGUnit ActiveUnit;
	local XComTacticalController TacticalController;
	
	if( bVisualizeFOW )
	{
		bDebugFOW = true;
	}

	bDebugVisibility = bEnable;
	bShowOrientation = bDebugVisibility;		

	if( !bEnable )
	{
		bDebugFOW = false;
		`XWORLD.DisableUnitVisCleanup();
	}

	TacticalController = XComTacticalController(ViewTarget.Owner);
	if (TacticalController != none && XCom3DCursor(Pawn) != none && bActiveUnitOnly)
	{	
		foreach AllActors(class'XGUnit', ActiveUnit)
		{			
			ActiveUnit.m_bDebugUnitVis = false;
		}

		ActiveUnit = TacticalController.GetActiveUnit();
		ActiveUnit.m_bDebugUnitVis = bEnable;
		`Log("DebugVisibility="$bDebugVisibility@ActiveUnit.Name);
	}
	else
	{
		foreach AllActors(class'XGUnit', ActiveUnit)
		{			
			ActiveUnit.m_bDebugUnitVis = bEnable;
		}
	}
}

//------------------------------------------------------------------------------------------------
exec function ShowTacticalControllerState()
{
	XComTacticalController(GetALocalPlayerController()).DumpStateStack();
}

//------------------------------------------------------------------------------------------------

exec function AIDebugAI( optional Name unitName = '' )
{	
	local bool bOn;

	bOn = !bShowActions;
	if (unitName != '' && unitName != m_DebugAnims_TargetName)
	{
		bOn = true;
	}

	if (bOn)
	{
		bShowNamesOnly = false;
		bAITextSkipBase = false;
	}


	if (bDebugAnims && bOn)
		DebugAnims(false);


	m_DebugAnims_TargetName = unitName;
	bShowActions = bOn;
	bAllUnits = bOn;
	bAIStates = bOn;
//	ToggleShowDestination();
//	ShowSpawnPoints();
//	ToggleShowPaths();
//	AIShowMinimapAI();

	bShowModifiers = false;
}
exec function AIDebugDead()
{
	bDebugDead=!bDebugDead;
}

exec function AIShowExposedCover()
{
	bShowExposedCover=!bShowExposedCover;
}

exec function DebugAnims(optional bool bEnable = true, optional bool bEnableDisplay = false, optional Name unitName = '')
{
	if (bEnable && bShowActions) // turn off other debug text if already on.
		AIDebugAI();

	bDebugAnims = bEnable;              // Enables animation logging to internal memory buffer.

	bDisplayAnims = bEnableDisplay;      // Displays logged animations to screen.

	if (unitName == '')
	{
		m_DebugAnims_TargetName = GetActiveUnit().Name;
	}
	else if( unitName == 'all' )
	{
		m_DebugAnims_TargetName = '';
		bDebugAnimsPawn = false; // Make sure we don't show pawn debuganims on top of the unit debuganims
	}
	else
	{
		m_DebugAnims_TargetName = unitName;   // Debugs ONE unit only. Will write to screen && std-out.
	}

}

exec function ToggleForceWalk()
{
	GetActiveUnit().m_bForceWalk = !GetActiveUnit().m_bForceWalk;
}

exec function AIDebugModifiers()
{
	AIDebugAI();

	bShowModifiers = !bShowModifiers;
}

exec function ShowOverwatch()
{
	bShowOverwatch = !bShowOverwatch;
}

exec function AIShowAITracking()
{
	bShowTracking = !bShowTracking;
}
//exec function AIShowVisibleEnemies()
//{
//	bShowVisibleEnemies = !bShowVisibleEnemies;
//}

exec function AIDebugManeuvers()
{
	bDebugManeuvers = !bDebugManeuvers;
}

exec function TestManeuver_Attack()
{
	// To do...
}

exec function X2DebugNoImmortals()
{
	bSkipPreDeathCheckEffects = true;
}

exec function ShowCursorLoc()
{
	bShowCursorLoc = !bShowCursorLoc;
}

exec function ShowCursorFloor()
{
	bShowCursorFloor = !bShowCursorFloor;
}

exec function ViewLocationTimed( float fX, float fY, float fZ, optional float duration = 2.0 )
{
	local X2Camera_LookAtLocationTimed LookAtCameraTimed;

	LookAtCameraTimed = new class'X2Camera_LookAtLocationTimed';
	LookAtCameraTimed.LookAtDuration = duration;
	LookAtCameraTimed.LookAtLocation.X = fX;
	LookAtCameraTimed.LookAtLocation.Y = fY;
	LookAtCameraTimed.LookAtLocation.Z = fZ;

	`CAMERASTACK.AddCamera(LookAtCameraTimed);
}

exec function ViewLocation( float fX, float fY, float fZ, bool bZoomIn=false )
{
	RemoveLookAt();

	kLookAtCamera = new class'X2Camera_LookAtLocation';
	kLookAtCamera.LookAtLocation.X = fX;
	kLookAtCamera.LookAtLocation.Y = fY;
	kLookAtCamera.LookAtLocation.Z = fZ;

	if (bZoomIn)
	{
		kLookAtCamera.ZoomCamera(-0.5f);
	}
	`CAMERASTACK.AddCamera(kLookAtCamera);
}

exec function RemoveLookAt()
{
	if(kLookAtCamera != none)
	{
		`CAMERASTACK.RemoveCamera(kLookAtCamera);
		kLookAtCamera = none;
	}
}

exec function ResetCameraStack()
{
	`CAMERASTACK.DEBUGResetCameraStack();
}

exec function PrintCameraStack()
{
	`CAMERASTACK.DEBUGPrintCameraStack();
}

exec function ShowLoot()
{
	bShowLoot = !bShowLoot;
}
exec function AllowFancyCameraStuff()
{
	bAllowFancyCameraStuff = !bAllowFancyCameraStuff;
}
exec function DebugTurning()
{
	bTurning = !bTurning;
}
exec function AITextSkipBase()
{
	bAITextSkipBase=!bAITextSkipBase;
}

exec function AIForceGrenade()
{
	bForceGrenade = !bForceGrenade;
	`Log("ForceGrenade="$bForceGrenade);
}
exec function AIShowAttackRange()
{
	bShowAttackRange = !bShowAttackRange;
	`Log("ShowAttackRange="$bShowAttackRange);
}

exec function AIShowProjectilePath()
{
	bShowProjectilePath = !bShowProjectilePath;
	`Log("ShowProjectilePath="$bShowProjectilePath);
}

exec function ShowProjectiles()
{
	bShowProjectiles = !bShowProjectiles;
	`Log("ShowProjectiles="$bShowProjectiles);
}

exec function ShowOrientation()
{
	bShowOrientation = !bShowOrientation;
	`Log("ShowOrientation="$bShowOrientation);
}

exec function DeadEye( bool bXComOnly=false )
{
	// shots always hit -tsmith 
	bDeadEye = !bDeadEye;
	bXComOnlyDeadEye = bXComOnly;
	`log("DeadEye="$bDeadEye@`ShowVar(bXComOnlyDeadEye));
	if(bDeadEye)
	{
		bNoLuck = false;
	}
}

exec function DeadEyeStats()
{
	bDeadEyeStats = !bDeadEyeStats;
	`log("bDeadEyeStats="$bDeadEyeStats);
}

exec function ForceCritHits()
{
	bForceCritHits = !bForceCritHits;
	`log("ForceCritHits=" $ bForceCritHits);
}

exec function ForceCriticalWound()
{
	// force all hits to wound critically -tsmith 
	bForceCriticalWound = !bForceCriticalWound;
	`log("ForceCriticalWound="$bForceCriticalWound);
}

exec function ForceNoCriticalWound()
{
	// force all hits to not wound critically 
	bForceNoCriticalWound = !bForceNoCriticalWound;
	`log("ForceNoCriticalWound="$bForceNoCriticalWound);
}

exec function NoLuck()
{
	// shots always miss -tsmith 
	bNoLuck = !bNoLuck;
	`log("NoLuck="$bNoLuck);
	if(bNoLuck)
	{
		bDeadEye = false;
	}
}

exec function NoLuckStats()
{
	bNoLuckStats = !bNoLuckStats;
	`log("bNoLuckStats="$bNoLuckStats);
}


exec function ToggleInvincibility()
{
	bInvincible = !bInvincible;
	`Log("Invincibility="$bInvincible);
}

exec function ToggleUnlimitedAmmo()
{
	bUnlimitedAmmo = !bUnlimitedAmmo;
	`Log("UnlimitedAmmo="$bUnlimitedAmmo);
}

exec function ToggleUnlimitedActions()
{
	bUnlimitedActions = !bUnlimitedActions;
	`Log("UnlimitedActions="$bUnlimitedActions);
}

exec function GotoDebugLoc()
{
	//`CAMERAMGR.RemoveLookAt(vLookAt);
	vLookAt = vDebugLoc;
	//`CAMERAMGR.AddLookAt(vLookAt);
}
function SetLastDebugPos( Vector vPos )
{
	vDebugLoc = vPos;
}

exec function AIShowDestination()
{
	bShowDestination = !bShowDestination;
}

exec function ShowActions()
{
	bShowActions = !bShowActions;
}
exec function ToggleDebugAllUnits()
{
	bAllUnits = !bAllUnits;
}
exec function AIShowAIStates()
{
	bAIStates = !bAIStates;
}
exec function ShowPlayerStates()
{
	bPlayerStates = !bPlayerStates;
}
exec function AIShowNames( bool bShowCivilians=false)
{
	if (!bShowNamesOnly && bShowActions)
		bShowActions = false;
	AIDebugAI();
	bShowNamesOnly = bShowActions;
	bAITextSkipBase = bShowActions;
	bShowCivilianLabels = bShowCivilians;
}
exec function ShowDropshipLoc( )
{
	bShowDropship = !bShowDropship;
}

exec function SetRainIntensity(int iLvl)
{
	
}

exec function TakeNoDamage()
{
	ToggleInvincibility();
}

exec function PowerUp()
{
	ToggleInvincibility();
	ToggleUnlimitedAmmo();
}

exec function CheatyFace()
{
	ToggleInvincibility();
	DeadEye(true);
}

exec function DebugClimbOver()
{
	Outer.FlushPersistentDebugLines();
	bDebugClimbOver = true;
}

exec function DebugClimbOnto()
{
	Outer.FlushPersistentDebugLines();
	bDebugClimbOnto = true;
}

exec function ForceMissedProjectileTargetActor(string ActorTag)
{
	ForceMissedProjectileHitActorTag = ActorTag;
}

exec function ForceMissedProjectileTargetTile(int X, int Y, int Z)
{
	UseForceMissedProjectileHitTile = true;
	ForceMissedProjectileHitTile.X = X;
	ForceMissedProjectileHitTile.Y = Y;
	ForceMissedProjectileHitTile.Z = Z;
}

exec function RemoveClosestUnitToCursorFromPlay()
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;

	Unit = self.GetClosestUnitToCursor();
	if(Unit != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Kill Unit Near Cursor (ID:"$Unit.ObjectID$")");

		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.RemoveUnitFromPlay();

		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}

exec function KillClosestUnitToCursor()
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;

	Unit = self.GetClosestUnitToCursor();
	if(Unit != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Kill Unit Near Cursor (ID:"$Unit.ObjectID$")");

		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetCurrentStat(eStat_HP, 0);

		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}

exec function KillAllAIExceptClosestUnitToCursor( bool bSaveClosestGroup=FALSE)
{
	local XComGameState NewGameState;
	local XComGameState_Unit ClosestUnit, UnitToKill, UnitState;
	local XComGameStateHistory History;
	local XGAIGroup kGroup;
	local XGAIPlayer kAI;
	local array<int> arrSavedIDs;

	ClosestUnit = self.GetClosestUnitToCursor(true); // Closest AI
	if(ClosestUnit != none)
	{
		if (bSaveClosestGroup)
		{
			kAI = XGAIPlayer(`BATTLE.GetAIPlayer());
			kAI.m_kNav.GetGroupInfo(ClosestUnit.ObjectID, kGroup);
			arrSavedIDs = kGroup.m_arrUnitIDs;
		}
		else
		{
			arrSavedIDs.AddItem(ClosestUnit.ObjectID);
		}
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Kill All But Unit Near Cursor (ID:"$ClosestUnit.ObjectID$")");

		History = `XCOMHistory;

		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if (arrSavedIDs.Find(UnitState.ObjectID) == -1
				&& (arrSavedIDs.Find(UnitState.OwningObjectId) == -1)
				&& UnitState.ControllingPlayerIsAI() 
				&& UnitState.IsAlive())
			{
				UnitToKill = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				UnitToKill.SetCurrentStat(eStat_HP, 0);
				`Log("Adding unit #"$UnitState.ObjectID@"to be killed.");
			}
		}

		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}

exec function KillAndImplantUnit()
{
	
}

exec function InjureUnit(optional int iDamage=3, optional Name unitName = '' )
{	
	
}

//------------------------------------------------------------------------------------------------
exec function TestMoraleEvent( int iMoraleEvent = 0 )
{
	
}

exec function DebugCover()
{
	bDebugCover = !bDebugCover;
}

exec function ShowShotMods(bool bShowShot)
{
	bShowShotSummaryModifiers = bShowShot;
}

exec function TestCoverPoint()
{
	local XGUnit kUnit;

	FlushPersistentDebugLines();

	if(Outer.GetActiveUnit() != none)
	{
		kUnit = Outer.GetActiveUnit();
		if (kUnit.IsInCover()) 
		{
			DrawDebugSphere(kUnit.GetShieldLocation(), 10, 10, 10, 255, 0, true);
		}
	}
}

//exec function TestCoverPoint( int TileX, int TileY, int TileZ )
//{
//	local TTile kTile;
//	local GameRulesCache_VisibilityInfo kVisInfo;
//	local XGAIPlayer kPlayer;
//	kPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
//	kTile.X = TileX; kTile.Y = TileY; kTile.Z = TileZ;
//
//	class'X2TacticalVisibilityHelpers'.static.GetAllEnemiesForLocation(kTile, kPlayer.ObjectID, kVisInfo);
//
//
//}

//exec function AddPathLength()
//{
//	if (Outer.GetActiveUnit() != none)
//	{
//		Outer.GetActiveUnit().ResetOffense();

//		// HACK, unselect and re-select to reset breadcrumbs
//		XComTacticalController(ViewTarget.Owner).Shoulder_Right_Press();
//		XComTacticalController(ViewTarget.Owner).Shoulder_Right_Release();
//		XComTacticalController(ViewTarget.Owner).Shoulder_Left_Press();
//		XComTacticalController(ViewTarget.Owner).Shoulder_Left_Release();
//	}
//}

exec function HackRegisterLocalTalker()
{
	local OnlineSubsystem	OnlineSubsystem;

	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if( OnlineSubsystem != none )
	{
		OnlineSubsystem.VoiceInterface.RegisterLocalTalker( LocalPlayer(Player).ControllerId );
		OnlineSubsystem.VoiceInterface.StartSpeechRecognition( LocalPlayer(Player).ControllerId );

		OnlineSubsystem.VoiceInterface.AddRecognitionCompleteDelegate( LocalPlayer(Player).ControllerId, OnRecognitionComplete );
	}
}

function OnRecognitionComplete()
{
	local OnlineSubsystem	OnlineSubsystem;
	local array<SpeechRecognizedWord> Words;
	local int i;

	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if( OnlineSubsystem != none )
	{
		OnlineSubsystem.VoiceInterface.GetRecognitionResults( LocalPlayer(Player).ControllerId, Words );
		for (i = 0; i < Words.length; i++)
		{
			`Log("Speech recognition got word:" @ Words[i].WordText);
		}
	}
}

exec function AddUIArrowPointingToClosestUnit()
{
	local XComGameState_Unit Unit;

	Unit = GetClosestUnitToCursor();
	class'XComGameState_IndicatorArrow'.static.CreateArrowPointingAtUnit(Unit);
}

exec function RemoveUIArrowPointingToClosestUnit()
{
	local XComGameState_Unit Unit;

	Unit = GetClosestUnitToCursor();
	class'XComGameState_IndicatorArrow'.static.RemoveArrowPointingAtUnit(Unit);
}

exec function DropBlueprint(String Blueprintname)
{
	local Rotator Orient;

	class'XComBlueprint'.static.ConstructGameplayBlueprint( Blueprintname, GetCursorLoc(), Orient, none );
}

exec function DropUnit(name CharacterTemplate, optional int TeamIndex=0, optional bool bAllowScamper=false, optional string CharacterPoolName)
{
	local XComWorldData WorldData;
	local Vector DropPosition;

	WorldData = `XWORLD;
	DropPosition = GetCursorLoc();
	DropPosition.Z = WorldData.GetFloorZForPosition(DropPosition);

	CharacterPoolName = Repl(CharacterPoolName, "\"", "", false);
	DropUnitAt(DropPosition, CharacterTemplate, TeamIndex, false, bAllowScamper, CharacterPoolName);
}

exec function InspectAllInteractLevelActors()
{
	local XComGameState_InteractiveObject kIObject;
	local XComGameStateHistory History;
	local XComInteractiveLevelActor kActor;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_InteractiveObject', kIObject)
	{
		kActor = XComInteractiveLevelActor(History.GetVisualizer(kIObject.ObjectID));
		`Log("InteractiveObject"$kIObject@"ID ="$kIObject.ObjectID@"Visualizer="$kActor@"ID="$kActor.ObjectID);
	}
}

exec function DebugTileSupportedSize(int InX, int InY, int InZ, int InHeight = 2, int IdealSize = 4)
{
	local int SupportedSize;
	SupportedSize = `SPAWNMGR.DEBUGFindTileSupportedSize(InX, InY, InZ, InHeight, IdealSize);
	`log("SupportedSize = " $ SupportedSize);
}

//  @TODO gameplay / someone: make this a function on the tactical ruleset 
function StateObjectReference DropUnitAt( vector Position, name CharacterTemplate, optional int TeamIndex, optional bool bAddToStartState=false, optional bool bAllowScamper=false, optional string CharacerPoolName)
{
	local ETeam Team;
	local StateObjectReference kNewUnit;
	local XComGameState_BattleData BattleData;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local XComGameState_Unit NewUnitState;
	local XComGameState_AIGroup	NewGroupState;
	local XComGameState NewGameState;
	local X2TacticalGameRuleset Rules;
	local int CurrentPlayerIndex;
	local UITurnOverlay TurnOverlay;

	Rules = `TACTICALRULES;
	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	CurrentPlayerIndex = -1;

	//Fall back to adding the new unit to the X-Com team
	Team = eTeam_XCom;

	foreach BattleData.PlayerTurnOrder(kNewUnit)
	{
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(kNewUnit.ObjectID));
		if( PlayerState != None )
		{
			++CurrentPlayerIndex;

			if( CurrentPlayerIndex == TeamIndex )
			{
				Team = PlayerState.TeamFlag;
				break;
			}
		}
	}

	if (!bAllowScamper)
	{
		bAbortScampers=true;
	}
	kNewUnit = `SPAWNMGR.CreateUnit( Position, CharacterTemplate, Team, bAddToStartState,,,, CharacerPoolName, !bAllowScamper );
	if (kNewUnit.ObjectID <= 0)
	{
		return kNewUnit;
	}

	// Prevent future scampering as well.
	if( !bAllowScamper )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Adding new unit to group");

		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', kNewUnit.ObjectID));
		NewGroupState = NewUnitState.GetGroupMembership();
		NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', NewGroupState.ObjectID));

		bAbortScampers = false;
		NewGroupState.bProcessedScamper = true;

		if( NewUnitState.IsChosen() )
		{
			NewGroupState.bSummoningSicknessCleared = true;
			Rules.RemoveGroupFromInitiativeOrder(NewGroupState, NewGameState);
			NewUnitState.SetUnitFloatValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ENGAGED);
		}

		Rules.SubmitGameState(NewGameState);
	}

	TurnOverlay = UITurnOverlay(Outer.Pres.ScreenStack.GetScreen(class'UITurnOverlay'));
	if( TurnOverlay != None )
	{
		TurnOverlay.m_kInitiativeOrder.UpdateInitiativeOrder();
	}

	// Initialize Chosen for dropped in units
	NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(kNewUnit.ObjectID));
	if (NewUnitState.IsChosen() && NewUnitState.ControllingPlayerIsAI())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Activate Chosen");
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', kNewUnit.ObjectID));

		if (class'X2TacticalVisibilityHelpers'.static.IsUnitVisibleToLocalPlayer(kNewUnit.ObjectID, -1))
		{
			NewUnitState.SetUnitFloatValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, 
											class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ENGAGED, 
											eCleanup_BeginTactical);
		}
		else
		{
			NewUnitState.SetUnitFloatValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue,
											class'XComGameState_AdventChosen'.const.CHOSEN_STATE_ACTIVATED,
											eCleanup_BeginTactical);

		}
		Rules.SubmitGameState(NewGameState);
	}

	return kNewUnit;
}

exec function AddLootToClosestUnitToCursor()
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;
	local XComGameState_Unit Unit;

	Unit = GetClosestUnitToCursor(true, false);
	if(Unit != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Enable Timed Loot on DropUnit ");
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		NewUnitState.RollForTimedLoot();
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}

exec function CreateAIGroup(string EncounterID)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData AIPlayerDataState;
	local XComGameState_AIGroup NewGroupState;
	local X2TacticalGameRuleset Rules;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Console: CreateAIGroup()");

	// create the new group state
	NewGroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
	NewGroupState.EncounterID = name(EncounterID);

	// add the group state to the ai data
	AIPlayerDataState = XComGameState_AIPlayerData(History.GetSingleGameStateObjectForClass(class'XComGameState_AIPlayerData', false));
	AIPlayerDataState = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', AIPlayerDataState.ObjectID));
	AIPlayerDataState.GroupList.AddItem(NewGroupState.GetReference());

	Rules = `TACTICALRULES;
	Rules.AddGroupToInitiativeOrder(NewGroupState, NewGameState);

	if(!Rules.SubmitGameState(NewGameState))
	{
		`RedScreen("Error creating new group state from console in CreateAIGroup()");
	}
}

exec function AssignClosestUnitToCursorToAIGroup(string EncounterID)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_AIPlayerData AIPlayerDataState;
	local StateObjectReference GroupReference;
	local XComGameState_AIGroup AIGroupState;
	local XComGameState_AIGroup PreviousAIGroupState;
	local X2TacticalGameRuleset Rules;

	// find the unit
	UnitState = GetClosestUnitToCursor(true);
	if(UnitState == none)
	{
		`RedScreen("Could not find a Unit to assign to group: " $ EncounterID);
	}

	History = `XCOMHISTORY;
	AIPlayerDataState = XComGameState_AIPlayerData(History.GetSingleGameStateObjectForClass(class'XComGameState_AIPlayerData', false));

	// find the grouop
	foreach AIPlayerDataState.GroupList(GroupReference)
	{
		AIGroupState = XComGameState_AIGroup(History.GetGameStateForObjectID(GroupReference.ObjectID));
		if(AIGroupState.EncounterID == name(EncounterID))
		{
			break;
		}
		else
		{
			AIGroupState = none;
		}
	}

	if(AIGroupState == none)
	{
		`RedScreen("Could not find a group with EncounterID: " $ EncounterID);
		return;
	}

	// create a the new state info
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Console: AssignNearestUnitToCursorToAIGroup() Step 1");
	AIGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', AIGroupState.ObjectID));

	// if the unit previous belonged to a different group, remove it from that group
	PreviousAIGroupState = UnitState.GetGroupMembership();
	if(PreviousAIGroupState != none)
	{
		PreviousAIGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', PreviousAIGroupState.ObjectID));
		PreviousAIGroupState.RemoveUnitFromGroup(UnitState.ObjectID, NewGameState);
	}

	// add the new mappings to associate this unit with the ai groups
	AIGroupState.AddUnitToGroup(UnitState.ObjectID, NewGameState);

	Rules = `TACTICALRULES;
	if(!Rules.SubmitGameState(NewGameState))
	{
		`RedScreen("Error creating new group state from console in AssignNearestUnitToCursorToAIGroup()");
	}

	// and update all the group associations.
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Console: AssignNearestUnitToCursorToAIGroup() Step 2");
	AIPlayerDataState = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', AIPlayerDataState.ObjectID));

	Rules = `TACTICALRULES;
	if(!Rules.SubmitGameState(NewGameState))
	{
		`RedScreen("Error creating new group associations from console in AssignNearestUnitToCursorToAIGroup()");
	}
}

//------------------------------------------------------------------------------------------------
exec function PrintGameStateHistory()
{
	`log("GameStateHistory: " $ class'XComGameStateHistory'.static.GetGameStateHistory().ToString());
}

exec function DropCivilian( Name CivilianTemplateName='' )
{
	if( CivilianTemplateName == '' )
	{ 
		CivilianTemplateName = 'Civilian';
	}
	`SPAWNMGR.CreateUnit( GetCursorLoc(false), CivilianTemplateName, eTeam_Neutral, false );
}

exec function AIMarkers()
{
	bMarker = !bMarker;
}
exec function AIRevealAllCivilians()
{
	bRevealAllCivilians=!bRevealAllCivilians;
}

exec function ToggleInteractMarkers()
{
	bShowInteractMarkers = !bShowInteractMarkers;
}

exec function ToggleFlankingMarkers()
{
	bShowFlankingMarkers = !bShowFlankingMarkers;
}

exec function AIDebugBadAreas()
{
	bDebugBadAreaLog=!bDebugBadAreaLog;
	`Log("bDebugBadAreaLog="$bDebugBadAreaLog);
}

exec function DrawClosestValidPoint( int iColor, bool bAllowFlying=false, bool bUseNone=false, bool bPrioritizeZ=true, float fZOffset=0 )
{
	local Vector vLoc, vCursorLoc;
	local int iRed, iGreen, iBlue;
	local XCom3DCursor kCursor;
	local bool bAvoidNoSpawnVolumes;
	bAvoidNoSpawnVolumes = true;
	// Pawn is the CURSOR in Combat
	kCursor = XCom3DCursor(Pawn);
	iRed = 255* (iColor&1);
	iGreen = 255 * (iColor&2);
	iBlue = 255 * (iColor&4);
	
	vCursorLoc = kCursor.Location;
	vCursorLoc.Z += fZOffset;
	vLoc = XComTacticalGRI(WorldInfo.GRI).GetClosestValidLocation(vCursorLoc, bUseNone?None:m_kActiveUnit, bAllowFlying, bPrioritizeZ, bAvoidNoSpawnVolumes);
	`Log("Closest valid point to "$vCursorLoc@"is at"@vLoc);

	DrawDebugLine(vLoc, vLoc+vect(0,0,400),iRed,iGreen,iBlue, true);
}

exec function DrawClosestCoverPointToCursor( float fMaxDist=0 )
{
	local vector vPos;
	if (fMaxDist <= 0)
	{
		fMaxDist=1280;
	}
	vPos = GetCursorPosition();
	DrawClosestCoverPoint( vPos.X, vPos.Y, vPos.Z, fMaxDist );
}
exec function DrawClosestCoverPoint( float fX, float fY, float fZ, float fMaxDist )
{
	local Vector vLoc;
	local XComCoverPoint kCover;
	vLoc.X=fX; vLoc.Y=fY; vLoc.Z=fZ;
	if (`XWORLD.GetClosestCoverPoint(vLoc, fMaxDist, kCover))
	{
		vLoc = kCover.ShieldLocation;
		DrawSphereV(vLoc);
	}
	else
	{
		`Log("No closest cover found!");
	}
}
function DrawSphereT(TTile TLoc, optional int iColor = 0, optional float fRadius = 0, optional bool bLookat = false)
{
	local Vector vLoc;
	vLoc = `XWORLD.GetPositionFromTileCoordinates(TLoc);

	DrawSphere(vLoc.X, vLoc.Y, vLoc.Z, iColor, fRadius, bLookat);
}

function DrawSphereV( vector vLoc, optional int iColor=0, optional float fRadius=0, optional bool bLookat=false)
{
	DrawSphere(vLoc.X, vLoc.Y, vLoc.Z, iColor, fRadius, bLookat);
}

exec function DrawSphere( float fX, float fY, float fZ , optional int ColorIndex=0, optional float Radius=0, optional bool bLookat=false)
{
	local Vector vLoc, vScale;
	local Color GREEN, RED;
	if (Radius == 0) Radius = 16;
	GREEN = MakeColor(0, 255, 0, 255);
	RED = MakeColor(255, 0, 0, 255);
	vLoc.X = fX; vLoc.Y = fY; vLoc.Z = fZ;
	vScale.X = Radius; vScale.Y = Radius; vScale.Z = Radius;

	
	`SHAPEMGR.DrawSphere(vLoc, vScale, ColorToLinearColor(LerpColor(GREEN, RED, ((ColorIndex % 17) / 16.0f))), true);
	if (bLookat)
		ViewLocation( fX, fY, fZ );
}

exec function AIDebugCursorCoverLocation( bool bLaunch=false )
{
	bDebugLaunchCover = false;
	bDebugPathCover = false;
	if (`XWORLD.GetClosestCoverPoint(GetCursorPosition(), 96, kDebugCover))
	{
		DrawSphereV(kDebugCover.TileLocation);
		if (bLaunch)
			bDebugLaunchCover = true;
		else
			bDebugPathCover = true;
		`Log("Logging failures on location:"$kDebugCover.TileLocation);
	}
	else
		`Log("Cover not found.");
}

//------------------------------------------------------------------------------------------------
function DrawAimLineV( Vector vStart, Vector vAim )
{
	DrawAimLine(vStart.X, vStart.Y, vStart.Z, vAim.X, vAim.Y, vAim.Z);
}
//------------------------------------------------------------------------------------------------
exec function DrawAimLine( float fX, float fY, float fZ, float dX, float dY, float dZ )
{
	local Vector vStart, vAim, vEnd;
	vStart.X = fX; vStart.Y = fY; vStart.Z = fZ;
	vAim.X = dX; vAim.Y = dY; vAim.Z = dZ;
	vEnd = vStart + vAim*640;
	`SHAPEMGR.DrawLine(vStart, vEnd, 1, , , true);
}

exec native function DebugFlankingWithCursor();

exec function SetDiscState(int iState)
{
	local XComTacticalController TacticalController;

	// Pawn is the CURSOR in Combat
	TacticalController = XComTacticalController(ViewTarget.Owner);
	TacticalController.m_kActiveUnit.SetDiscState(EDiscState(iState));
}
//------------------------------------------------------------------------------------------------
exec function TeleportUnitIDToCursor(int UnitID)
{	
	local XGUnit TargetUnit;
	local vector vLoc;
	TargetUnit = XGUnit(`XCOMHISTORY.GetVisualizer(UnitID));
	if( TargetUnit != None)
	{
		vLoc = GetCursorLoc();
		TeleportUnit(TargetUnit, vLoc);
	}
	else
	{
		`Log("TeleportUnitIDToCursor- No unit found with ObjectID "$UnitID);
	}
}

exec function SkipAI()
{
	XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer()).m_bSkipAI = true;
	XGBattle_SP(`BATTLE).GetTheLostPlayer().m_bSkipAI = true;
	`Log("AI turn disabled.");
}

exec function SkipAllAIExceptClosestToCursor()
{
	local XComGameState_Unit Unit;

	Unit = GetClosestUnitToCursor();
	if (SkipAllAIExceptUnitID != Unit.ObjectID) 
	{
		SkipAllAIExceptUnitID = Unit.ObjectID;
		`Log("AI turn disabled, except for unit #" @Unit.ObjectID);
	}
	else
	{
		SkipAllAIExceptUnitID = 0;
	}
}

exec function SkipCivilians()
{
	local XComGameStateContext_TacticalGameRule EndTurnContext;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XComHistory;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (UnitState.IsCivilian()
			&& UnitState.NumAllActionPoints() != 0)
		{
			EndTurnContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
			EndTurnContext.GameRuleType = eGameRule_SkipUnit;
			EndTurnContext.UnitRef = UnitState.GetReference();
			`XCOMGAME.GameRuleset.SubmitGameStateContext(EndTurnContext);
		}
	}

}

exec function SkipNonLostAI()
{
	local XGAIPlayer AIPlayer;
	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	AIPlayer.m_bSkipAI = true;
	XGBattle_SP(`BATTLE).GetTheLostPlayer().m_bSkipAI = false;
}

exec function AISkipAI()
{
	local XGAIPlayer AIPlayer;
	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	AIPlayer.m_bSkipAI = !AIPlayer.m_bSkipAI;
	XGBattle_SP(`BATTLE).GetTheLostPlayer().m_bSkipAI = AIPlayer.m_bSkipAI;
	if (!AIPlayer.m_bSkipAI)
	{
		`log("AI turn enabled.");
	}
	else
	{
		`Log("AI turn disabled.");
	}
}

exec function KillAllElse()
{
	local Pawn P;
	
	foreach WorldInfo.AllPawns( class'Pawn', P )
	{
		if ( P != Outer.GetCursor() && P != Outer.GetActiveUnitPawn() )
		{
			P.Destroy();
		}
	}
}

exec function UseController()
{
	`BATTLE.ProfileSettingsDebugUseController();
}

//------------------------------------------------------------------------------------------------
exec function TestNearestCoverDot()
{
`if (`notdefined(FINAL_RELEASE))
	local XComCoverPoint Point;
	local XGUnit kActive;
	local float fDot;
	local bool bExposed;

	kActive = Outer.m_kActiveUnit;

	if (`XWORLD.GetClosestCoverPoint(GetCursorPosition(), 128, Point))
	{
		if (Outer.GetActiveUnit() != none)
		{
			bExposed = kActive.IsCoverExposed(Point, kActive, fDot, true);
			`LOG("Dot from cover to unit"@kActive@"="@fDot@"bExposed="$bExposed);
		}
	}
`endif
}

exec function TestCoverPoints()
{
	local array<XComCoverPoint> CoverPoints;
	`XWORLD.GetCoverPoints(GetCursorPosition(), 5 * 96, 5 * 64, CoverPoints);
}

//------------------------------------------------------------------------------------------------

exec function VisualizeMove()
{
	bVisualizeMove = !bVisualizeMove;
}

exec function DebugFracEffects(optional coerce bool bEnable=true)
{
	bDrawFracturedMeshEffectBoxes = bEnable;
}

exec function EndTurn()
{
	XComTacticalController(ViewTarget.Owner).PerformEndTurn(ePlayerEndTurnType_PlayerInput);
}

exec function UISetDiscState( bool bDiscOn )
{
	XComPresentationLayer(Outer.Pres).m_bIsDebugHideSelectedUnitDisc = !bDiscOn;

	if ( XComPresentationLayer(Outer.Pres).m_bIsDebugHideSelectedUnitDisc )
		XComTacticalController(ViewTarget.Owner).m_kActiveUnit.SetDiscState( eDS_None );
	else
		XComTacticalController(ViewTarget.Owner).m_kActiveUnit.SetDiscState( eDS_Good );
}

exec function UIToggleDisc()
{
	`log("Toggling selected unit's disc (aka: Unit Ring)");
	XComPresentationLayer(Outer.Pres).m_bIsDebugHideSelectedUnitDisc =
		!XComPresentationLayer(Outer.Pres).m_bIsDebugHideSelectedUnitDisc;

	if ( XComPresentationLayer(Outer.Pres).m_bIsDebugHideSelectedUnitDisc )
		XComTacticalController(ViewTarget.Owner).m_kActiveUnit.SetDiscState( eDS_None );
	else
		XComTacticalController(ViewTarget.Owner).m_kActiveUnit.SetDiscState( eDS_Good );
}

exec function UIEnableEnemyArrows( bool bEnable )
{
	`log("Turning the enemy arrow hover indicators to enabled = " $ string(bEnable));
	XComPresentationLayer(Outer.Pres).m_bAllowEnemyArrowSystem = bEnable; 
}

exec function DebugInteractionAnims()
{
`if (`notdefined(FINAL_RELEASE))
	local XComInteractiveLevelActor It;
	local AnimNodeSequence Seq;

	foreach AllActors(class'XComInteractiveLevelActor', It)
	{
		Seq = It.AnimNode.GetTerminalSequence();
		`log(It.Name $ ": ActiveSequence:" @ Seq.AnimSeqName);
	}
`endif
}

//------------------------------------------------------------------------------------------------
exec function DebugInputState()
{
	bDebugInputState = !bDebugInputState;
	`log("bDebugInputState=" $ bDebugInputState);
	if(bDebugInputState)
	{
		Outer.AddHUDOverlayActor();
	}
	else
	{
		Outer.RemoveHUDOverlayActor();
	}
		
}

exec function DebugPOI()
{
	local XComBuildingVisPOI kPOI;

	bDebugPOI = !bDebugPOI;

	foreach AllActors(class'XComBuildingVisPOI', kPOI)
	{
		if( bDebugPOI )
		{
			kPOI.AddHUDOverlayActor();
			kPOI.SetHidden(FALSE);
		}
		else
		{   
			kPOI.RemoveHUDOverlayActor();
			kPOI.SetHidden(TRUE);
		}
	}
}

exec function CloseCombatCheat(bool bEnable, optional bool bDesiredResult)
{
	bCloseCombatCheat = bEnable;
	bCloseCombatDesiredResult = bDesiredResult;

	`log("CloseCombatCheat Enabled:"@bCloseCombatCheat@"DesiredResult:"@bCloseCombatDesiredResult);
}

exec function ToggleGhostMode()
{
	bGhostMode=!bGhostMode;
	`Log("GhostMode="$bGhostMode);
}

exec function SkipReactionFire()
{
	bSkipReactionFire=!bSkipReactionFire;
	`Log("SkipReactionFire="$bSkipReactionFire);
}

exec function DebugCCState()
{
	bDebugCCState=!bDebugCCState;
	`Log("bDebugCCState="$bDebugCCState);
}

function XComGameState_Unit GetClosestUnitToCursor(bool bForceTeam=false, bool bConsiderDead=false, ETeam ForcedTeam=eTeam_None)
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local XComGameState_Unit Unit;
	local XComGameState_Unit ClosestUnit;
	local Vector UnitLocation;
	local float UnitDistance;
	local float ClosestUnitDistance;
	local TTile Tile; 
	local Vector CursorLocation;

	History = `XComHistory;
	WorldData = class'XComWorldData'.static.GetWorldData();
	CursorLocation = GetCursorLoc(false);

	if (bForceTeam && ForcedTeam == eTeam_None)
	{
		ForcedTeam = eTeam_Alien;
	}

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.m_bSubsystem || Unit.bRemovedFromPlay ||
			(bForceTeam && Unit.GetTeam() != ForcedTeam))
			continue;
		if( !bConsiderDead &&  Unit.IsDead() )
			continue;
		if (Unit.GetMyTemplate().bIsCosmetic)
			continue;
		Tile = Unit.TileLocation;
		UnitLocation = WorldData.GetPositionFromTileCoordinates(Tile);
		UnitDistance = VSize(CursorLocation - UnitLocation);
		if(ClosestUnit == none || UnitDistance < ClosestUnitDistance)
		{
			ClosestUnitDistance = UnitDistance;
			ClosestUnit = Unit;
		}
	}

	return ClosestUnit;
}

exec function SwapTeamsOnNearestUnitToCursor()
{
	local XComGameState_Unit Unit;
	local XGBattle Battle;
	local int TeamToggle, NewTeam;

	Battle = `BATTLE;
	Unit = GetClosestUnitToCursor();
	TeamToggle = eTeam_XCom | eTeam_Alien;

	NewTeam = Unit.GetTeam() ^ TeamToggle;
	Battle.SwapTeams(Unit, ETeam(NewTeam));
}

exec function SabotageAvenger()
{
	class'SeqAct_SabotageAvenger'.static.SabotageAvenger();
}

exec function SpawnReserveUnit()
{
	class'SeqAct_SpawnUnitFromAvenger'.static.SpawnUnitFromAvenger();
}

exec function SetReferencePoint()
{
	vReferencePoint = GetCursorPosition();
	DrawSphereV(vReferencePoint, 127, 5);
}
//function XComInteractiveLevelActor FindNearestDynamicAIDoor(vector vLoc)
//{
//	local XComAlienPathHandler kPath;
//	local XComInteractiveLevelActor kBest;
//	local XComAlienPathNode kNode;
//	local float fDist, fBest;
//	foreach AllActors(class'XComAlienPathHandler', kPath)
//	{
//		foreach kPath.m_kPod.PathNodes(kNode)
//		{
//			if (kNode.InteractActor != none)
//			{
//				fDist = VSizeSq(vLoc-kNode.InteractActor.Location);
//				if (kBest == none || fDist < fBest)
//				{
//					kBest = kNode.InteractActor;
//					fBest = fDist;
//				}
//			}
//		}
//	}
//	return kBest;
//}
//exec function TestBehindDoor()
//{
//	local XComInteractiveLevelActor kDoor;
//	local Vector vLoc;
//	vLoc = GetCursorPosition();
//	kDoor=FindNearestDynamicAIDoor(vLoc);
//	if ( class'XComAlienPathHandler'.static.IsBehindDoor(vLoc, kDoor, vReferencePoint) )
//		`Log("Cursor is behind the door.");
//	else
//		`Log("Cursor is outside the door.");
	
//}

exec function AIShowPathFailures()
{
	bShowPathFailures = !bShowPathFailures;
	`Log("bShowPathFailures="$bShowPathFailures);
}

exec function LogMapName()
{
	`Log("Map="$WorldInfo.GetMapName());
}

exec  function TestTileLocation(float fX, float fY, float fZ)
{
`if (`notdefined(FINAL_RELEASE))
	local bool bValid;
	local Vector vLoc;
	vLoc.X=fX; vLoc.Y=fY; vLoc.Z=fZ;
	bValid =XComTacticalGRI(WorldInfo.GRI).IsValidLocation(vLoc);
	`Log("Tile valid = "$bValid);
`endif
}

exec function ShowTileLocation(int TileX, int TileY, int TileZ, float fR=1,float fG=1, float fB=1, float fA=1, bool bSphere=false)
{
	local Vector vLoc, vSize;
	local TTile kTile;
	kTile.X = TileX; kTile.Y = TileY; kTile.Z = TileZ;
	if (fR==0&&fG==0&&fB==0&&fA==0)
	{
		fR=1;fG=1;fB=1;fA=1;
	}
	vSize.X = class'XComWorldData'.const.WORLD_StepSize; 
	vSize.Y = vSize.X;
	vSize.Z = class'XComWorldData'.const.WORLD_FloorHeight;
	vLoc = `XWORLD.GetPositionFromTileCoordinates(kTile);
	DrawSphereV(vLoc, 127, 10);
	if (!bSphere)
	{
		`SHAPEMGR.DrawBox(vLoc, vSize, MakeLinearColor(fR,fG,fB,fA),true);
	}
}

exec function DrawLine( float Z1, float Z2 )
{
	local vector v1,v2;
	v1= GetCursorLoc();
	v2=v1;
	v1.Z = Z1;
	v2.Z = Z2;
	DrawDebugLine(v1, v2, 255,255,255, TRUE);
}


exec function SetVolume( float fVolume )
{
	class'Engine'.Static.GetAudioDevice().TransientMasterVolume = fVolume;
}

// Test function for setting AkAudio switches on the WorldInfo object.
// This is useful for testing ambiance switches.  mdomowicz 2015_08_10
// Ambience now uses AkAudio states, so this won't work for testing ambience.	dprice 2016-03-10
exec function SetWorldInfoAkAudioSwitch( name nSwitchGroup, name nSwitchName )
{
	WorldInfo.SetSwitch( nSwitchGroup, nSwitchName );
}

// Test function for setting AkAudio states.
// This is useful for testing ambiance states.  dprice 2016-03-10
exec function SetAkAudioState( name nStateGroup, name nStateName )
{
	SetState( nStateGroup, nStateName );
}

exec function DebugExitCover( XGUnit kUnit, XGUnit kTarget )
{
	//kUnit.GetPawn().GetInfo_SelectExitCoverTypeToUse(kTarget);  RAM deprecated
}

exec function SpawnLevelExit()
{
	`PARCELMGR.SpawnLevelExit();
}

exec function DebugTargeting( bool bEnable)
{
	bDebugTargeting = bEnable;
	`log ("DebugTargeting:"@bDebugTargeting);
}

exec function DebugCoverActors()
{
	bDebugCoverActors = !bDebugCoverActors;
	`log("DebugCoverActors:"@bDebugCoverActors);
}

exec function DebugXDA()
{
	local XComDestructibleActor XDA;
	foreach AllActors(class'XComDestructibleActor', XDA)
	{
		XDA.bDebug = !XDA.bDebug;
	}
}

exec function DebugFLA()
{
	local XComFracLevelActor FLA;
	foreach AllActors(class'XComFracLevelActor', FLA)
	{
		FLA.bDebug = !FLA.bDebug;
	}
}

exec function DebugTimeDilation()
{
	bDebugTimeDilation = !bDebugTimeDilation;
	`log("DebugTimeDilation:"@bDebugTimeDilation);
}

//------------------------------------------------------------------------------------------------
exec function ExplodeIt(float fRadius, float fDamage, float fWorldDamage, optional name DamageTypeName, optional bool bInstigatorIsSelectedUnit)
{	
	local XComGameStateHistory History;
	local XCom3DCursor kCursor;	
	local XComGameState NewGameState;
	local XComGameState_EnvironmentDamage NewDamageEvent;
	local XComWorldData WorldData;
	local array<TilePosPair> Collection;
	local array<XComDestructibleActor> Destructibles;
	local XComDestructibleActor Destructible;
	local XComGameState_Destructible DestructibleGameState;
	local EffectAppliedData UnusedEffectData;

	foreach DynamicActors(class'XCom3DCursor', kCursor) 
	{
		break;
	}

	if (kCursor == none)
	{
		`log("Could not find XCom3DCursor");
		return;
	}

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	NewGameState = History.CreateNewGameState(true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext());

	NewDamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));

	NewDamageEvent.DamageAmount = fWorldDamage;
	NewDamageEvent.DamageTypeTemplateName = DamageTypeName == '' ? 'Explosion' : DamageTypeName;
	NewDamageEvent.HitLocation = kCursor.Location;
	NewDamageEvent.DamageRadius = fRadius;	
	NewDamageEvent.bRadialDamage = true;

	NewDamageEvent.HitLocation.Z = WorldData.GetFloorZForPosition( NewDamageEvent.HitLocation );

	WorldData.CollectTilesInSphere( Collection, NewDamageEvent.HitLocation, fRadius );

	WorldData.CollectDestructiblesInTiles( Collection, Destructibles );

	foreach Destructibles(Destructible)
	{
		if (Destructible.IsTargetable())
		{
			DestructibleGameState = XComGameState_Destructible( History.GetGameStateForObjectID( Destructible.ObjectID ) );
			DestructibleGameState.TakeEffectDamage( none, fDamage, 0, 0, UnusedEffectData, NewGameState );
		}
	}
	
	`TACTICALRULES.SubmitGameState(NewGameState);

	FlushPersistentDebugLines( );
	DrawDebugSphere( NewDamageEvent.HitLocation, NewDamageEvent.DamageRadius, 10, 255, 255, 255, true );
	DrawDebugStar( NewDamageEvent.HitLocation, 20, 255, 255, 255, true );
}

exec function DebugTrace(EXComTraceType eTraceType, float TargetX, float TargetY, float TargetZ, float SourceX, float SourceY, float SourceZ, float fExtentSize)
{
`if (`notdefined(FINAL_RELEASE))
	local vector vTarget, vSource, vHitLocation, vHitNormal, vExtent;
	local Actor kHitActor;

	vTarget.X = TargetX;
	vTarget.Y = TargetY;
	vTarget.Z = TargetZ;

	vSource.X = SourceX;
	vSource.Y = SourceY;
	vSource.Z = SourceZ;

	vExtent.X = fExtentSize;
	vExtent.Y = fExtentSize;
	vExtent.Z = fExtentSize;

	kHitActor = `XTRACEMGR.XTrace(eTraceType, vHitLocation, vHitNormal, vTarget, vSource, vExtent);

	`log("DebugTrace hit result:"@kHitActor);
`endif
}

exec function DamageUnit(int iDamageAmount)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local X2Effect_ApplyWeaponDamage DamageEffect;
	local EffectAppliedData ApplyData;

	Unit = self.GetClosestUnitToCursor();
	if (Unit != none)
	{
		//Use AreaDamage context because it doesn't ask too many questions
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext());

		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));

		DamageEffect = new class'X2Effect_ApplyWeaponDamage';
		DamageEffect.EffectDamageValue.Damage = iDamageAmount;

		ApplyData.AbilityResultContext.HitResult = eHit_Success;
		ApplyData.TargetStateObjectRef = Unit.GetReference();

		DamageEffect.ApplyEffect(ApplyData, Unit, NewGameState);
		
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}

exec function DamageWholeTeam(optional int iDamageAmt = 1, optional ETeam eTeamToDamage = eTeam_Alien, optional bool bIncludeCivilians = false)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local X2Effect_ApplyWeaponDamage DamageEffect;
	local EffectAppliedData ApplyData;
	local XComGameStateHistory History;
	local int DamageCount;

	History = `XCOMHISTORY;

	//Use AreaDamage context because it doesn't ask too many questions
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext());

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.EffectDamageValue.Damage = iDamageAmt;

	ApplyData.AbilityResultContext.HitResult = eHit_Success;

	DamageCount = 0;
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if ( (Unit.GetTeam() == eTeamToDamage) && (bIncludeCivilians || !Unit.IsCivilian()) )
		{
			Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));

			ApplyData.TargetStateObjectRef = Unit.GetReference();
			DamageEffect.ApplyEffect(ApplyData, Unit, NewGameState);
			
			DamageCount++;
		}
	}

	`log("Applied damage to" @ DamageCount @ "units.\n");

	`TACTICALRULES.SubmitGameState(NewGameState);
}

exec function TestAnimation(name strAnim, optional bool Additive = false, optional bool UpperBodyOnly = false)
{
	local XGUnit kUnit;
	local CustomAnimParams AnimParams;
	kUnit = GetActiveUnit();

	if (kUnit != None)
	{
		AnimParams.AnimName = strAnim;
		if( Additive )
		{
			kUnit.GetPawn().GetAnimTreeController().PlayAdditiveDynamicAnim(AnimParams);
		}
		else if (UpperBodyOnly)
		{
			kUnit.GetPawn().GetAnimTreeController().PlayUpperBodyDynamicAnim(AnimParams);
		}
		else
		{
			kUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
		}
	}
}

//------------------------------------------------------------------------------------------------
// Temp hack fix for grenade preview getting stuck <apc>
exec function ResetGrenadePreview()
{
	`PRECOMPUTEDPATH.iNumKeyframes = 0; 
}

//------------------------------------------------------------------------------------------------
exec function AIDebugDestroyCover()
{
	bDebugDestroyCover = !bDebugDestroyCover;
	`Log("bDebugDestroyCover = "$bDebugDestroyCover);
}

//------------------------------------------------------------------------------------------------
exec function SetHP( int iHealth, optional bool bAsPercent=false, int NewMaxHP=0 )
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local int MaxHP;
	local float NewHP;

	Unit = self.GetClosestUnitToCursor();
	if(Unit != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetHP (ID:"$Unit.ObjectID$")");

		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		if( NewMaxHP > 0 )
		{
			Unit.SetBaseMaxStat(eStat_HP, NewMaxHP);
		}
		if (!bAsPercent)
		{
			Unit.SetCurrentStat(eStat_HP, iHealth);
		}
		else
		{
			MaxHP = Unit.GetMaxStat(eStat_HP);
			NewHP = MaxHP * (iHealth / 100.0f);
			Unit.SetCurrentStat(eStat_HP, NewHP);
		}

		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}
//------------------------------------------------------------------------------------------------
exec function ShowShieldHP()
{
	bShowShieldHP=!bShowShieldHP;
	`Log("bShowShieldHP="$bShowShieldHP);
}
//------------------------------------------------------------------------------------------------
exec function DebugPrintBattleInfo()
{
	`log(GetFuncName(), true, 'XCom_Net');
	`log("      State=" $ XComTacticalGRI(WorldInfo.GRI).m_kBattle.GetStateName(), true, 'XCom_Net');
}
//------------------------------------------------------------------------------------------------

exec function DebugBeginMoveHang()
{
	bDebugBeginMoveHang = !bDebugBeginMoveHang;
	`log(GetFuncName() $ ":" @ `ShowVar(bDebugBeginMoveHang));
}
//------------------------------------------------------------------------------------------------
exec function TestValidLoc(float fX, float fY, float fZ, string strUnitName)
{
`if (`notdefined(FINAL_RELEASE))
	local XGUnit kUnit;
	local bool bFound, bValid;
	local vector vLoc;

	`log(GetFuncName() @ "UnitName=" $ strUnitName);
	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(kUnit.Name == name(strUnitName))
		{
			bFound=true;
			break;
		}
	}
	if (bFound && kUnit != None)
	{
		vLoc.X= fX;
		vLoc.Y = fY;
		vLoc.Z = fZ;
		bValid = XComTacticalGRI(WorldInfo.GRI).IsValidLocation(vLoc, kUnit);
		`Log("IsValidLocation returns :"@bValid);
	}
`endif
}
//------------------------------------------------------------------------------------------------
exec function ShowOccupiedTilesAroundCursor()
{
	local vector vLoc, vTilePos;
	local int iRangeX, iRangeY, iRangeZ, iX,iY,iZ, iPosX,iPosY,iPosZ;
	local TTile kTile, kCursor;
	FlushPersistentDebugLines();

	vLoc = GetCursorLoc();
	iRangeX=3;iRangeY=3;iRangeZ=3;
	kCursor = `XWORLD.GetTileCoordinatesFromPosition(vLoc);
	for (iZ=0;iZ<iRangeZ;iZ++)
	{
		for (iPosZ=0; iPosZ<2; iPosZ++)
		{
			if (iZ==0)
				iPosZ++;
			if (iPosZ == 0) 
				kTile.Z = kCursor.Z-iZ;
			else
				kTile.Z = kCursor.Z+iZ;
	for (iY=0;iY<iRangeY;iY++)
	{
		for (iPosY=0; iPosY<2; iPosY++)
		{
			if (iY==0)
				iPosY++;
			if (iPosY == 0) 
				kTile.Y = kCursor.Y-iY;
			else
				kTile.Y = kCursor.Y+iY;
	for (iX=0;iX<iRangeX;iX++)
	{
		for (iPosX=0; iPosX<2; iPosX++)
		{
			if (iX==0)
				iPosX++;
			if (iPosX == 0) 
				kTile.X = kCursor.X-iX;
			else
				kTile.X = kCursor.X+iX;
			
			vTilePos = `XWORLD.GetPositionFromTileCoordinates(kTile);
			if (`XWORLD.IsTileFullyOccupied(kTile))
				DrawDebugSphere(vTilePos, 10, 5, 255,0,0, true);
			else if( `XWORLD.IsTileBlockedByUnitFlag(kTile) )
				DrawDebugSphere(vTilePos, 10, 5, 0, 0, 255, true);
			else
				DrawDebugSphere(vTilePos, 10, 5, 0,255,0, true);
		}
	}
		}
	}
		}
	}
}

exec function SetCharacterVoice(name Voice)
{
	local XComHumanPawn Soldier;

	Soldier = XComHumanPawn(XComTacticalController(GetALocalPlayerController()).GetActivePawn());
	if (Soldier != none)
	{
		Soldier.SetVoice(Voice);
	}
}

exec function MakeCharacterSpeak(Name nEvent)
{
	local XComHumanPawn Soldier;
	local XComAlienPawn Alien;

	Soldier = XComHumanPawn(XComTacticalController(GetALocalPlayerController()).GetActivePawn());
	if (Soldier != none)
	{
		Soldier.UnitSpeak(nEvent);
	}

	Alien = XComAlienPawn(XComTacticalController(GetALocalPlayerController()).GetActivePawn());
	if (Alien != none)
	{
		Alien.UnitSpeak(nEvent);
	}
}

exec function RefreshAllUnitsVisibility()
{
	local XGUnit kUnit;

	`log(self $ "::" $ GetFuncName());
	foreach DynamicActors(class'XGUnit', kUnit)
	{
		`log("      Unit=" $ kUnit @ `ShowVar(kUnit.m_eTeam) @ `ShowVar(kUnit.m_eTeamVisibilityFlags) @ `ShowVar(GetALocalPlayerController().m_eTeam));
		kUnit.SetVisibleToTeams(kUnit.m_eTeamVisibilityFlags);
	}
}

exec function ForceUnitVisible(int ObjectID, bool bDisable=false )
{
	local XGUnit Unit;
	Unit = XGUnit(`XCOMHISTORY.GetVisualizer(ObjectID));
	if (Unit != None)
	{
		if ( bDisable )
		{
			Unit.SetForceVisibility(eForceNone);
		}
		else
		{
			Unit.SetForceVisibility(eForceVisible);
		}

		Unit.GetPawn().UpdatePawnVisibility();
	}
}

exec function ToggleUnitFlags()
{
	bShowUnitFlags = !bShowUnitFlags;
	`log("TOGGLEUNITFLAGS:" @ `ShowVar(bShowUnitFlags));

	if (bShowUnitFlags)
		XComPresentationLayer(Outer.Pres).m_kUnitFlagManager.Show();
	else XComPresentationLayer(Outer.Pres).m_kUnitFlagManager.Hide();
}

exec function ToggleTutorialPopups()
{
	bDisableTutorialPopups = !bDisableTutorialPopups;
	`log("TOGGLE TUTORIAL POPUPS:" @ `ShowVar(bDisableTutorialPopups));
}

exec function ToggleWorldMessages()
{
	bDisableWorldMessages = !bDisableWorldMessages;
	`log("TOGGLEWORLDMESSAGES:" @ `ShowVar(bDisableWorldMessages));
}

exec function ToggleWorldDebugMessages()
{
	bWorldDebugMessagesEnabled = !bWorldDebugMessagesEnabled;
	`log("TOGGLE WORLD DEBUG MESSAGES:" @ `ShowVar(bWorldDebugMessagesEnabled));
}

exec function ToggleAlienGlam()
{
	bAllGlamAlways = !bAllGlamAlways;
	if (bAllGlamAlways)
		`log("Alien glam enabled.");
	else
		`log("Alien glam disabled.");
}

exec function marketing()
{
	super.marketing();

	ToggleUnitFlags();
	ToggleWorldMessages();
	ToggleTutorialPopups();
	UIEnableEnemyArrows(false);

	Outer.SetAudioGroupVolume('Music', 0.0f);

	`XPROFILESETTINGS.Data.m_bEnableSoldierSpeech = false;
	`log("MARKETINGMODE:" @ `ShowVar(`XPROFILESETTINGS.Data.m_bEnableSoldierSpeech));

	`XTACTICALSOUNDMGR.StopAllAmbience();
}

exec function DebugVisTeams()
{
	local XGUnit kUnit;

	foreach AllActors(class'XGUnit', kUnit)
	{
		`log(kUnit @ "team:" $ kUnit.m_eTeam @ "xcomvis:" $ kUnit.IsVisibleToTeam(eTeam_XCom) @ "alienvis:" $ kUnit.IsVisibleToTeam(eTeam_Alien) @ "civilianvis:" $ kUnit.IsVisibleToTeam(eTeam_Neutral) );
	}
}


exec function AlwaysRushCam()
{
	bAlwaysRushCam = !bAlwaysRushCam;

	if (bAlwaysRushCam)
		`log("AlwaysRushCam enabled");
	else
		`log("AlwaysRushCam disabled");
}

exec function UIBuildTacticalHUDAbilities()
{
	`PRES.m_kTacticalHUD.Update();
}

exec function UIUnitFlagsRealizeCover()
{
	local UIUnitFlag kUIUnitFlag;

	foreach DynamicActors(class'UIUnitFlag', kUIUnitFlag)
	{
		kUIUnitFlag.RealizeCover();
	}
}

exec function UISetAllUnitFlagHitPoints(bool bUseCurrentHP, optional int iHP, optional int iMaxHP)
{
	local UIUnitFlag kUIUnitFlag;
	local XComGameState_Unit CurrentUnitState;

	foreach DynamicActors(class'UIUnitFlag', kUIUnitFlag)
	{
		if(bUseCurrentHP)
		{
			CurrentUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kUIUnitFlag.StoredObjectID));
			kUIUnitFlag.SetHitPoints(CurrentUnitState.GetCurrentStat(eStat_HP), CurrentUnitState.GetMaxStat(eStat_HP));
		}
		else
		{
			kUIUnitFlag.SetHitPoints(iHP, iMaxHP);
		}
	}
}

exec function GetAllUnitHP()
{
	local XGUnit kUnit;

	foreach DynamicActors(class'XGUnit', kUnit)
	{
		`log("Unit=" $ kUnit.SafeGetCharacterFullName() @ "HP=" $ kUnit.GetUnitHP() @ "MaxHP=" $ kUnit.GetUnitMaxHP());
	}
}

exec function SetAmmo(int amount)
{
	local XGUnit Unit;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState;

	Unit = GetActiveUnit();
	if (Unit == none)
	{
		`log("SetAmmo: No active unit! Select a unit on your turn");
		return;
	}
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID));
	if (UnitState == none)
	{
		`log("No game state unit was found for" @ Unit.ObjectID);
		return;
	}
	ItemState = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon);
	if (ItemState == none)
	{
		`log("No primary weapon!");
		return;
	}
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SetAmmo cheat");
	ItemState = XComGameState_Item(NewGameState.ModifyStateObject(ItemState.Class, ItemState.ObjectID));
	amount = Clamp(amount,0,100);
	ItemState.Ammo = amount;
	`TACTICALRULES.SubmitGameState(NewGameState);
	
	`log("SetAmmo: setting primary weapon's ammo to: " @ amount);
}

//------------------------------------------------------------------------------------------------
exec function DoDeathOnOutsideOfBounds(optional name nmUnitName) 
{
	local XGUnit kUnit;

	if(nmUnitName == '')
	{
		kUnit = GetActiveUnit();
	}
	else
	{
		foreach DynamicActors(class'XGUnit', kUnit)
		{
			if(kUnit.name == nmUnitName)
			{
				break;
			}
		}
	}
	if(kUnit != none)
	{
		kUnit.GetPawn().DoDeathOnOutsideOfBounds();
	}
}

//------------------------------------------------------------------------------------------------
exec function ForceEvaluateStance(optional string strUnitName)
{
	local XGUnit kUnit;

	if(strUnitName == "")
	{
		strUnitName = string(GetClosestUnitToCursor().Name);
	}

	`log(GetFuncName() @ "UnitName=" $ strUnitName);
	foreach DynamicActors(class'XGUnit', kUnit)
	{
		if(strUnitName == "all")
		{
			kUnit.IdleStateMachine.GotoState('EvaluateStance');
		}
		else if(kUnit.Name == name(strUnitName))
		{
			kUnit.IdleStateMachine.GotoState('EvaluateStance');
			break;
		}
	}
}

//------------------------------------------------------------------------------------------------
exec function RestartLevelWithSameSeed()
{
	SetSeedOverride(class'Engine'.static.GetEngine().GetLastInitSeed());
	class'Engine'.static.GetEngine().SetRandomSeeds(`BATTLE.iLevelSeed);
	RestartLevel();
}

exec function RestartLevelWithSeed(int iSeed)
{
	SetSeedOverride(class'Engine'.static.GetEngine().GetLastInitSeed());
	class'Engine'.static.GetEngine().SetRandomSeeds(iSeed);
	RestartLevel();
}

exec function SetXComAnimUnitName(name SetName)
{
	XCom_Anim_DebugUnitName = SetName;
	NativeSetXComAnimUnitName(SetName);
}

function bool MatchesXComAnimUnitName(name CheckName)
{
	return CheckName == XCom_Anim_DebugUnitName || XCom_Anim_DebugUnitName == '';
}   

native function NativeSetXComAnimUnitName(name SetName);

exec function AIDebugMaterials()
{
	bShowMaterials = !bShowMaterials;
	if (bShowMaterials)
	{
		AIDebugAI();
		bShowNamesOnly = true;
		bAITextSkipBase = true;
	}
}

//------------------------------------------------------------------------------------------------;
exec function TestSoundCue( name strSoundCueClass, name strSoundCueName )
{
	local string strSoundCue;
	strSoundCue = strSoundCueClass$"."$strSoundCueName;
	PlaySound( SoundCue(DynamicLoadObject(strSoundCue, class'SoundCue')), true );
}

exec function AIForceSkipPodReveal()
{
	bForcePodQuickMode=true;
}

//------------------------------------------------------------------------------------------------
exec function TestTileBlocked(int TileX, int TileY, int TileZ)
{
	local TTile kTile;
	local bool bBlocked, bOccupied;
	kTile.X = TileX; kTile.Y = TileY; kTile.Z = TileZ;
	bBlocked = `XWORLD.IsTileBlockedByUnitFlag(kTile,None);
	bOccupied = `XWORLD.IsTileOccupied(kTile);
	`Log("Tile ("$kTile.X@kTile.Y@kTile.Z$") Blocked="$bBlocked@"Occupied="$bOccupied);
}

exec function ResetEnvLighting()
{
	`ENVLIGHTINGMGR.Reset(none);
}


exec function RebuildTileData()
{
	`XWORLD.BuildWorldData( none );
}

//------------------------------------------------------------------------------------------------

exec function DetonateAllDestructionSpheres()
{
	local XComDestructionSphere SphereActor;

	foreach AllActors(class'XComDestructionSphere', SphereActor)
	{
		SphereActor.Explode();
	}
}

exec function RadialImpulse(float fRadius, float fPower)
{
	local KAsset XDA;
	foreach AllActors(class'KAsset', XDA)
	{
		XDA.CollisionComponent.AddRadialImpulse(GetCursorPosition(), fRadius, fPower, RIF_Linear, false);
	}
}


//------------------------------------------------------------------------------------------------
exec function AISetAllToYellowAlert()
{
	local XGAIPlayer kAI;
	local XGAIGroup kGroup;
	kAI = XGAIPlayer(`BATTLE.GetAIPlayer());
	foreach AllActors(class'XGAIGroup', kGroup)
	{
		kAI.ForceAbility(kGroup.m_arrUnitIDs, 'YellowAlert');
	}
}

exec function AISetAllToRedAlert()
{
	local XGAIPlayer kAI;
	local XGAIGroup kGroup;
	kAI = XGAIPlayer(`BATTLE.GetAIPlayer());
	foreach AllActors(class'XGAIGroup', kGroup)
	{
		kAI.ForceAbility(kGroup.m_arrUnitIDs, 'RedAlert');
	}
}

//------------------------------------------------------------------------------------------------
exec function ForceAbilityOnAIGroup(name AbilityName)
{
	local XGAIPlayer kAI;
	local XComGameState_Unit kClosest;
	local XGAIGroup kGroup;

	kClosest = GetClosestUnitToCursor(true);
	if (kClosest != none)
	{
		kAI = XGAIPlayer(`BATTLE.GetAIPlayer());
		kAI.m_kNav.GetGroupInfo(kClosest.ObjectID, kGroup);
		kAI.ForceAbility(kGroup.m_arrUnitIDs, AbilityName);
	}
}
//------------------------------------------------------------------------------------------------
exec function ForceAbilityOnNearestUnit(name AbilityName)
{
	local XGAIPlayer kAI;
	local XComGameState_Unit kClosest;
	local array<int> UnitIDList;

	kClosest = GetClosestUnitToCursor();
	if (kClosest != none)
	{
		kAI = XGAIPlayer(`BATTLE.GetAIPlayer());
		UnitIDList.AddItem(kClosest.ObjectID);
		kAI.ForceAbility(UnitIDList, AbilityName);
	}
}

//------------------------------------------------------------------------------------------------

exec function LogCursorParcel()
{
	local vector vLoc;
	local XComParcel kParcel;
	vLoc = GetCursorLoc();
	kParcel = `PARCELMGR.GetContainingParcel(vLoc);
	`Log("Cursor is currently in parcel: "$kParcel @ kParcel.ParcelDef.MapName);
}
//------------------------------------------------------------------------------------------------

exec function ReplayStart()
{
	UIToggleVisibility();
	XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StartReplay(`XCOMHISTORY.FindStartStateIndex());
}

exec function ReplayStop()
{
	UIToggleVisibility();
	XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StopReplay();
}

exec function ReplayToggleUI()
{
	local UIReplay ReplayUI;

	// Cache the UIReplay screen so we can update it as we play through
	foreach AllActors(class'UIReplay', ReplayUI)
	{
		break;
	}

	if (ReplayUI == none)
	{
		// Create the replay UI if none exist
		Outer.Pres.UIReplayScreen("");
		// Toggle it back off, so the toggle below turns it back on and will have the UI updated as well
		`REPLAY.ToggleUI();	
	}

	`REPLAY.ToggleUI();
}

exec function ReplayToggleDebug()
{
	local UIReplay ReplayUI;

	// Cache the UIReplay screen so we can update it as we play through
	foreach AllActors(class'UIReplay', ReplayUI)
	{
		break;
	}

	if (ReplayUI != none)
	{
		ReplayUI.ToggleDebugPanels();
	}
}

exec function ReplayUpdateUI(int Frame)
{
	`REPLAY.UpdateUIWithFrame(Frame);
}

exec function TutorialToggleDemoMode()
{
	`TUTORIAL.ToggleDemoMode();
}


exec function ReplayStepForward()
{
	XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StepReplayForward();
}

exec function ReplayStepBack()
{
	XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StepReplayBackward();
}

exec function ReplayAutoplay()
{
	XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StepReplayAll();
}

exec function ReplayJumpToFrame(int Frame)
{
	XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.JumpReplayToFrame(Frame);
}


exec function CursorDamage( optional float Radius=256.0, optional int Damage=10 )
{
	local XComGameState NewGameState;
	local XComGameState_EnvironmentDamage NewDamageEvent;

	NewGameState = `XCOMHISTORY.CreateNewGameState( true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext( ) );

	NewDamageEvent = XComGameState_EnvironmentDamage( NewGameState.CreateNewStateObject( class'XComGameState_EnvironmentDamage' ) );

	NewDamageEvent.DamageAmount = Damage;
	NewDamageEvent.DamageTypeTemplateName = 'Explosion';
	NewDamageEvent.HitLocation = GetCursorPosition();
	NewDamageEvent.DamageRadius = Radius;
	NewDamageEvent.bRadialDamage = true;
	NewDamageEvent.bAffectFragileOnly = false;

	`TACTICALRULES.SubmitGameState( NewGameState );
}

exec function CheckAvailableActions(optional bool AllUnits=false)
{
	local XComTacticalController kController;
	local XComGameState_Unit kUnit;		

	if (AllUnits)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', kUnit, eReturnType_Reference)
		{
			ShowAvailableActions(kUnit);
		}
	}
	else
	{
		kController = XComTacticalController(GetALocalPlayerController());
		kUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID( kController.ControllingUnit.ObjectID ));
		if (kUnit == none)
		{
			`log("no active unit found");
		}
		else
		{
			ShowAvailableActions(kUnit);
		}
	}
}

function ShowAvailableActions(XComGameState_Unit kUnit)
{
	local GameRulesCache_Unit OutCacheData;
	local XComGameState_Ability kAbility;
	local int i, j, k;

	`TACTICALRULES.GetGameRulesCache_Unit(kUnit.GetReference(), OutCacheData);
	
	`log(kUnit.ToString());
	`log("  bAnyActionsAvailable=" $ OutCacheData.bAnyActionsAvailable);
	for (i = 0; i < OutCacheData.AvailableActions.Length; ++i)
	{
		kAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID( OutCacheData.AvailableActions[i].AbilityObjectRef.ObjectID ));
		`log("  " $ i @ kAbility.ToString(true));
		`log("      bFreeAim=" $ OutCacheData.AvailableActions[i].bFreeAim);
		`log("      AvailableCode=" $ OutCacheData.AvailableActions[i].AvailableCode);
		for (j = 0; j < OutCacheData.AvailableActions[i].AvailableTargets.Length; ++j)
		{
			`log("      PrimaryTarget" @ j $ "=" $ OutCacheData.AvailableActions[i].AvailableTargets[j].PrimaryTarget.ObjectID);
			for (k = 0; k < OutCacheData.AvailableActions[i].AvailableTargets[j].AdditionalTargets.Length; ++k)
			{
				`log("          AdditionalTarget" @ j @ k $ "=" $ OutCacheData.AvailableActions[i].AvailableTargets[j].AdditionalTargets[k].ObjectID);
			}
		}
	}
}

exec function ForceUpdateActionAvailability()
{
	CheckAvailableActions(true);
}

exec function SelectAvailableAction(int ActionIndex, optional int TargetIndex=0)
{
	local XComTacticalController kController;
	local XComGameState_Unit kUnit;		
	local XComGameState_Ability kAbility;
	local XComGameState_Item kItem, kWeapon;
	local GameRulesCache_Unit OutCacheData;
	local XComGameStateContext_Ability StateChangeContainer;
	local int i;

	kController = XComTacticalController(GetALocalPlayerController());
	kUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID( kController.ControllingUnit.ObjectID ));
	if (kUnit == none)
	{
		`log("no active unit found");
	}
	else
	{
		for (i = 0; i < kUnit.InventoryItems.Length; ++i)
		{
			kItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(kUnit.InventoryItems[i].ObjectID));
			if (kItem.ItemLocation == eSlot_RightHand)
			{
				kWeapon = kItem;
				break;
			}
		}
		if (kWeapon == none)
		{
			`log("Unable to find the unit's primary weapon.");
		}
		else
		{
			`TACTICALRULES.GetGameRulesCache_Unit(kUnit.GetReference(), OutCacheData);
			if (ActionIndex >= OutCacheData.AvailableActions.Length || ActionIndex < 0)
			{
				`log("ActionIndex" @ ActionIndex @ "is out of range (" $ OutCacheData.AvailableActions.Length $ ")");
			}
			else
			{
				if ((TargetIndex >= OutCacheData.AvailableActions[ActionIndex].AvailableTargets.Length && TargetIndex != 0) || TargetIndex < 0)
				{
					`log("TargetIndex" @ TargetIndex @ "is out of range (" $ OutCacheData.AvailableActions[ActionIndex].AvailableTargets.Length $ ")");
				}
				else
				{
					kAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(OutCacheData.AvailableActions[ActionIndex].AbilityObjectRef.ObjectID));
					`assert(kAbility != none);					
					StateChangeContainer = XComGameStateContext_Ability(class'XComGameStateContext_Ability'.static.CreateXComGameStateContext());
					StateChangeContainer.InputContext.AbilityRef = OutCacheData.AvailableActions[ActionIndex].AbilityObjectRef;
					StateChangeContainer.InputContext.AbilityTemplateName = kAbility.GetMyTemplateName();
					StateChangeContainer.InputContext.SourceObject = kUnit.GetReference();
					StateChangeContainer.InputContext.ItemObject = kWeapon.GetReference();

					if (OutCacheData.AvailableActions[ActionIndex].AvailableTargets.Length > 0)
					{
						StateChangeContainer.InputContext.PrimaryTarget = OutCacheData.AvailableActions[ActionIndex].AvailableTargets[TargetIndex].PrimaryTarget;
						StateChangeContainer.InputContext.MultiTargets = OutCacheData.AvailableActions[ActionIndex].AvailableTargets[TargetIndex].AdditionalTargets;
					}				
					`log("Submitting unit action...");
					`TACTICALRULES.SubmitGameStateContext(StateChangeContainer);
				}
			}
		}
	}
}

//------------------------------------------------------------------------------------------------

exec function AIDebugPatrols()
{
	XGAIPlayer(`BATTLE.GetAIPlayer()).m_kNav.RefreshGameState();
	bDebugPatrols = !bDebugPatrols;
	bShowPatrolPaths = bDebugPatrols;
	bGhostMode = bDebugPatrols;
	ToggleFow();
}

exec function AIDebugExploration()
{
	bShowExplorationPoints = !bShowExplorationPoints;
	`Log("bShowExplorationPoints="$bShowExplorationPoints);
}

exec function RefreshAIUnitGameState()
{
	local XGAIBehavior kAI;
	foreach worldinfo.AllActors(class'XGAIBehavior', kAI)
	{
		kAI.RefreshUnitCache();
	}

}

exec function X2AllowSelectAll(bool bSetting)
{
	bAllowSelectAll = bSetting;

	if( bSetting && `XWORLD.bDebugEnableFOW )
	{
		ToggleFOW();
	}
	else if ( bSetting && !`XWORLD.bDebugEnableFOW )
	{
		ToggleFOW();
	}
	
	//Force all units to be visible
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle();
}

exec function DebugEffects()
{
	local XComGameState_Effect EffectStateObject;
	local X2Effect_Persistent kEffect;
	local XComGameState_Unit TargetUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Effect', EffectStateObject)
	{
		kEffect = EffectStateObject.GetX2Effect();
		TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectStateObject.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

		`Log("Affected Unit="$TargetUnit.ObjectID@"EffectStateObject="$EffectStateObject@kEffect.EffectName@"EffectStateObjectID="$EffectStateObject.ObjectID@"TurnsLeft="$EffectStateObject.iTurnsRemaining);
	}

}

exec function AIForceAbility(string strAbilityName, bool bOneTimeUse=false)
{
	strAIForcedAbility = strAbilityName;
	bForceAbilityOneTimeUse = bOneTimeUse;
}

exec function AIDebugReinforcements()
{
	bDebugReinforcementTriggers=!bDebugReinforcementTriggers;
}

exec function AICallReinforcements(Name EncounterID, optional int IdealTileOffset, optional Name VisualizationType='ATT', optional bool bDontSpawnInXComLOS, optional bool bMustSpawnInXComLOS)
{
	local XComTacticalMissionManager MissionManager;
	local ConfigurableEncounter Encounter;
	local bool bFound;
	local string DebugText;
	MissionManager = `TACTICALMISSIONMGR;
	foreach MissionManager.ConfigurableEncounters(Encounter)
	{
		if( EncounterID == Encounter.EncounterID )
		{
			bFound = true;
			break;
		}
		DebugText = DebugText $ Encounter.EncounterID $ "\n";
	}
	if( bFound )
	{
		class'XComGameState_AIReinforcementSpawner'.static.InitiateReinforcements(EncounterID, , , , IdealTileOffset,,,VisualizationType, bDontSpawnInXComLOS, bMustSpawnInXComLOS);
	}
	else
	{
		`Log("Failed to find EncounterID:"@EncounterID@"\nValid EncounterIDs:\n"@DebugText);
	}
}

exec function UpgradeWeapon(string UpgradeName, optional bool bForce=false)
{
	local XComTacticalController kController;
	local XComGameState_Unit kUnit;		
	local XComGameState_Item kWeapon;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local XComGameState NewGameState;
	local X2AbilityTemplateManager AbilityTemplateMan;
	local X2AbilityTemplate AbilityTemplate;
	local int i;

	kController = XComTacticalController(GetALocalPlayerController());
	kUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID( kController.ControllingUnit.ObjectID ));
	if (kUnit == none)
	{
		`log("Active unit not found. Cannot apply upgrade.");
		return;
	}
	kWeapon = kUnit.GetItemInSlot(eInvSlot_PrimaryWeapon);
	if (kWeapon == none)
	{
		`log("No primary weapon found on unit. Cannot apply upgrade.");
		return;
	}
	UpgradeTemplate = X2WeaponUpgradeTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(UpgradeName)));
	if (UpgradeTemplate == none)
	{
		`log("No upgrade template named '" $ UpgradeName $ "' was found.");
		return;
	}
	if ((UpgradeTemplate.CanApplyUpgradeToWeapon(kWeapon) && kWeapon.CanWeaponApplyUpgrade(UpgradeTemplate)) || bForce) // Issue #260
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Applying Weapon Upgrade: " @ UpgradeTemplate.GetItemFriendlyName());
		kWeapon = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', kWeapon.ObjectID));
		//  Note this isn't really how you should apply things, but this is a cheat! Look at UIWeaponUpgradeScreen to see how it really works.
		kWeapon.ApplyWeaponUpgradeTemplate(UpgradeTemplate);

		if (UpgradeTemplate.BonusAbilities.Length > 0)
		{
			AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
			kUnit = XComGameState_Unit(NewGameState.ModifyStateObject(kUnit.Class, kUnit.ObjectID));
			for (i = 0; i < UpgradeTemplate.BonusAbilities.Length; ++i)
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(UpgradeTemplate.BonusAbilities[i]);
				if (AbilityTemplate == none) continue;

				`TACTICALRULES.InitAbilityForUnit(AbilityTemplate, kUnit, NewGameState, kWeapon.GetReference());
				`log("Adding ability to unit:" @ AbilityTemplate.LocFriendlyName);
			}
		}

		`GAMERULES.SubmitGameState(NewGameState);
		`log("Successfully applied upgrade!");
	}
	else
	{
		`log("Upgrade cannot be applied to the weapon (" $ kWeapon.GetMyTemplate().GetItemFriendlyName() $ "), per its usual application rules.");
		return;
	}
}

exec function ShowPathHistory(int iUnitID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit kUnitState, kLastUnitState;
	local int iHistoryIndex, iColor, iColorMax;
	local vector vPointA, vPointB;
	History = `XCOMHISTORY;
	iHistoryIndex = History.GetCurrentHistoryIndex();
	kLastUnitState = XComGameState_Unit(History.GetGameStateForObjectID(iUnitID,, iHistoryIndex--));
	iColor = 0;
	iColorMax = 225;
	while (iHistoryIndex > 0)
	{
		kUnitState = XComGameState_Unit(History.GetGameStateForObjectID(iUnitID,, iHistoryIndex--));

		if (kUnitState.TileLocation != kLastUnitState.TileLocation)
		{
			vPointA = `XWORLD.GetPositionFromTileCoordinates(kLastUnitState.TileLocation);
			vPointB = `XWORLD.GetPositionFromTileCoordinates(kUnitState.TileLocation);
			DrawDebugLine(vPointA, vPointB, iColor,iColor,255, TRUE);
			iColor += 8;
			iColor = Min(iColor, iColorMax);
		}
		kLastUnitState = kUnitState;
	}

}

exec function LogAIStat( name strStatName, bool AllUnits=false, bool bLatestState=false )
{
	local XComGameState_Unit UnitState, VisualizedState;
	local XComGameStateHistory History;
	local ECharStatType Stat;
	local string strType;
	local int iType;
	local bool bFound;
	local XGUnit UnitVisualizer;
	local XComReplayMgr kReplayMgr;

	kReplayMgr = XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr;

	for (iType=0; iType < eStat_MAX; iType++)
	{
		Stat = ECharStatType(iType);
		strType = string(Stat);
		if (Caps(strType) == Caps(strStatName))
		{
			bFound = true;
			break;
		}
	}

	if (bFound)
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState,,,)
		{
			if( UnitState.ControllingPlayerIsAI() || AllUnits )
			{
				if( bLatestState )
				{
					`Log(UnitState@"("$UnitState.ObjectID$")"@ strType $"="$ UnitState.GetCurrentStat(Stat));
				}
				else
				{
					if( kReplayMgr != None )
					{
						VisualizedState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID, , kReplayMgr.CurrentHistoryFrame));
					}
					else
					{
						UnitVisualizer = XGUnit(UnitState.GetVisualizer());
						if( UnitVisualizer != None )
						{
							VisualizedState = UnitVisualizer.GetVisualizedGameState();
						}
					}

					if( VisualizedState != None )
					{
						`Log(VisualizedState@"("$VisualizedState.ObjectID$")"@ strType $"="$ VisualizedState.GetCurrentStat(Stat));
					}
				}
			}
		}
	}
	else
	{
		`Log("No stat type found: "$strStatName$".  Available stats:");
		for (iType=0; iType < eStat_MAX; iType++)
		{
			Stat = ECharStatType(iType);
			strType = string(Stat);
			`Log(strType);
		}
	}
}

//------------------------------------------------------------------------------------------------
exec function SetStatOnClosestUnit(name strStatName, int StatVal )
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local ECharStatType Stat;
	local string strType;
	local int iType;
	local bool bFound;

	Unit = self.GetClosestUnitToCursor();
	if( Unit != none )
	{
		for( iType = 0; iType < eStat_MAX; iType++ )
		{
			Stat = ECharStatType(iType);
			strType = string(Stat);
			if( Caps(strType) == Caps(strStatName) )
			{
				bFound = true;
				break;
			}
		}

		if( bFound )
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetStatOnClosestUnit (Stat:"$strStatName@"ID:"$Unit.ObjectID$")");

			Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			if( Unit.GetMaxStat(Stat) < StatVal )
			{
				Unit.SetBaseMaxStat(Stat, StatVal);
			}
			Unit.SetCurrentStat(Stat, StatVal);

			`TACTICALRULES.SubmitGameState(NewGameState);
		}
		else
		{
			`Log("No stat type found: "$strStatName$".  Available stats:");
			for( iType = 0; iType < eStat_MAX; iType++ )
			{
				Stat = ECharStatType(iType);
				strType = string(Stat);
				`Log(strType);
			}
		}
	}
}


exec function ForceRebuildTiles()
{
	`PARCELMGR.RebuildWorldData();
}

exec function OpenAllDoors(Name InteractSocketName)
{
	local XComInteractiveLevelActor kDoor;
	local XGUnit Unit;
	local XComGameState_InteractiveObject ObjectState;
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContainer;

	Unit = GetActiveUnit();

	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("DEBUG Open All Doors");
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));

	OpenAllDoorsSocketName = InteractSocketName;
	foreach worldinfo.AllActors(class'XComInteractiveLevelActor', kDoor)
	{
		if (kDoor.IsDoor())
		{
			ObjectState = kDoor.GetInteractiveState();
			ObjectState = XComGameState_InteractiveObject(NewGameState.ModifyStateObject(class'XComGameState_InteractiveObject', ObjectState.ObjectID));
			ObjectState.Interacted(UnitState, NewGameState, InteractSocketName);

			kDoor.BeginInteraction(Unit, OpenAllDoorsSocketName);
			kDoor.PlayAnimations(Unit, OpenAllDoorsSocketName);
		}
	}

	`GAMERULES.SubmitGameState(NewGameState);

	// Wait 5 seconds then end all the interactions
	`BATTLE.SetTimer(5.0f, false, nameof(OpenAllDoorsEndInteraction), self);
}

function OpenAllDoorsEndInteraction()
{
	local XComInteractiveLevelActor kDoor;
	local XGUnit Unit;

	Unit = GetActiveUnit();
	foreach worldinfo.AllActors(class'XComInteractiveLevelActor', kDoor)
	{
		if (kDoor.IsDoor())
		{
			kDoor.EndInteraction(Unit, OpenAllDoorsSocketName);	
		}
	}	
}

function XComInteractiveLevelActor GetClosestDoor( vector vLoc )
{
	local float fDist, fClosest;
	local XComInteractiveLevelActor kDoor, kClosest;
	foreach worldinfo.AllActors(class'XComInteractiveLevelActor', kDoor)
	{
		if (kDoor.IsDoor())
		{
			fDist = VSizeSq(vLoc-kDoor.Location);
			if (kClosest == None || fDist < fClosest)
			{
				fClosest = fDist;
				kClosest = kDoor;
			}
		}
	}
	return kClosest;
}

exec function TestCanPathThroughNearestDoor()
{
	local vector vLoc;
	local XComInteractiveLevelActor kLevelActor;
	vLoc = GetCursorLoc();
	kLevelActor = GetClosestDoor(vLoc);
	`Log("Door at ("$vLoc$") CanPathThrough="@kLevelActor.CanPathThrough());
}

exec function CheckGameStateUnitVisualizerLocations()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local TTile kXGUnitTile;
	local XGUnit kUnit;
	local string strMatching;

	History = `XComHistory;

	`Log("*********** GameState_Unit Tile Location to Visualizer Location check **************");
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		kUnit = XGUnit(UnitState.GetVisualizer());
		if (kUnit != None)
		{
			kXGUnitTile = `XWORLD.GetTileCoordinatesFromPosition(kUnit.Location);
			if (kXGUnitTile.X == UnitState.TileLocation.X && kXGUnitTile.Y == UnitState.TileLocation.Y) // Ignore Z since it is usually off by one.
			{
				strMatching @= kUnit $"("$kUnit.ObjectID$") ";
			}
			else
			{
				`Log(" !!!! TileLocation Mismatch !!!!  "$kUnit@"("$kUnit.ObjectID$") @ "$kUnit.Location@ "("$kXGUnitTile.X@kXGUnitTile.Y@kXGUnitTile.Z$")" @ "UnitState.TileLocation @ ("$UnitState.TileLocation.X@UnitState.TileLocation.Y@UnitState.TileLocation.Z$")" );
			}
		}
	}
	`Log("Other units ok: "$strMatching);
	`Log("*********** check done **************");


}

exec function AIDebugSpawns()
{
	bDebugSpawns = !bDebugSpawns;
	`Log(`ShowVar(bDebugSpawns));
}
exec function X2PhysicsPoke(float Radius = 192.0f, int Magnitude = 100)
{
	local vector vLoc;
	local XComDestructibleActor PokeActor;
	
	vLoc = GetCursorLoc();
	foreach WorldInfo.CollidingActors(class'XComDestructibleActor', PokeActor, Radius, vLoc)
	{
		if( PokeActor.CollisionComponent != none && PokeActor.Physics == PHYS_RigidBody )
		{
			PokeActor.CollisionComponent.AddRadialImpulse(vLoc, Radius, Magnitude, RIF_Constant);
		}
	}
}

exec function LevelUpSoldier()
{
	local XComGameState UpdateState;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_ChangeContainer ChangeContainer;

	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("DEBUG Unit Level Up");
	UpdateState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
	UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnitStateRef().ObjectID));
	UnitState.AddXp(class'X2ExperienceConfig'.static.GetRequiredXp(`GET_MAX_RANK - 1)); // add a ton of XP
	`GAMERULES.SubmitGameState(UpdateState);
}

exec function ListInventory()
{
	local XComGameState_Unit UnitState;
	local array<XComGameState_Item> InventoryItems;
	local XComGameState_Item Item;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetActiveUnitStateRef().ObjectID));
	InventoryItems = UnitState.GetAllInventoryItems();

	`log("Unit" @ UnitState.ObjectID @ UnitState.GetName(eNameType_Full));
	`log("Inventory:");
	foreach InventoryItems(Item)
	{
		`log("  " $ Item.InventorySlot @ "-" @ Item.ObjectID @ Item.GetMyTemplate().GetItemFriendlyName() @ "(" $ Item.GetMyTemplateName() $ ")");
	}
}

exec function DumpUnitValues()
{
	local XComGameState_Unit UnitState;
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetActiveUnitStateRef().ObjectID));
	`log("Unit" @ UnitState.ObjectID @ UnitState.GetName(eNameType_Full));
	`log(UnitState.UnitValues_ToString());
}


exec function AIDebugConcealment()
{
	bDebugConcealment=!bDebugConcealment;
	bShowNamesOnly = true;
	`Log(`ShowVar(bDebugConcealment));
}

// output all AI logging for the past 2 turns to the log.
exec function AIDumpLogs()
{
	class'XGAIPlayer'.static.DumpAILog(true);
}

exec function WhoseTurnIsItAnyway()
{
	local XGBattle_SP Battle;
	local XGPlayer HumanPlayer;
	local StateObjectReference TurnRef;
	local X2TacticalGameRuleset Rules;

	Battle = XGBattle_SP(`BATTLE);
	HumanPlayer = Battle.GetHumanPlayer();
	Rules = `TACTICALRULES;
	TurnRef = Rules.GetCachedUnitActionPlayerRef();
	if (TurnRef.ObjectID == 0)
	{
		`log("The turn is currently processing in state" @ Rules.GetStateName() $ ".");
	}
	else
	{
		if (TurnRef.ObjectID == HumanPlayer.ObjectID)
			`log("It's your turn.");
		else
			`log("It's not your turn.");
	}
}

exec function EnableGlobalAbility(name AbilityName)
{
	if (class'XComGameState_BattleData'.static.SetGlobalAbilityEnabled(AbilityName, true))
	{
		`log("Enabled" @ AbilityName);
	}
	else
	{
		`log("Could not enable" @ AbilityName $ ". Perhaps you mistyped the name.");
	}
}

exec function EnableGlobalAbilityForUnit(name AbilityName)
{
	local XComGameState UpdateState;
	local XComGameState_Unit UnitState;

	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cheat - EnableGlobalAbilityForUnit");
	UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnitStateRef().ObjectID));
	UnitState.EnableGlobalAbilityForUnit(AbilityName);
	`GAMERULES.SubmitGameState(UpdateState);
}

exec function IncreaseSquadmateScore(int ObjectID_A, int ObjectID_B, int ScoreIncrease)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitStateA, UnitStateB;

	UnitStateA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID_A));
	UnitStateB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID_B));

	if(UnitStateA != none && UnitStateB != none && !UnitStateA.HasSpecialBond(UnitStateB))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Increase Squadmate Score");
		UnitStateA.AddToSquadmateScore(UnitStateB.ObjectID, ScoreIncrease);
		UnitStateB.AddToSquadmateScore(UnitStateA.ObjectID, ScoreIncrease);
		NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitStateA.ObjectID);
		NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitStateB.ObjectID);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

exec function ReplayToFrame( int iFrame )
{
	local UIReplay kReplay;
	foreach AllActors(class'UIReplay', kReplay)
	{
		break;
	}
	if (kReplay != None)
		kReplay.ReplayToFrame(iFrame);
}

exec function AIDisableIntentFlyoverText()
{
	bAIDisableIntent=!bAIDisableIntent;
	`Log(`ShowVar(bAIDisableIntent));
}

function AddIntent( name strName )
{
	if (!bAIDisableIntent)
	{
		m_strBTIntent @= strName;
	}
}

exec function AIShowLastAction()
{
	bAIShowLastAction = !bAIShowLastAction;
	`Log(`ShowVar(bAIShowLastAction));
}

function AIResetLastAbilityStrings()
{
	strLastAIAbility.Length = 0;
}

function int AIStringsFindUnitIndex( int iObjID )
{
	local string strID;
	local int iLine;
	strID = string(iObjID)$":";
	for (iLine=0; iLine<strLastAIAbility.Length; iLine++)
	{
		if (InStr(strLastAIAbility[iLine], strID) == 0)
			return iLine;
	}
	return -1;
}

function int AIStringsAddUnit( int iObjID, bool bDead=false )
{
	local string strID, strBegin;
	local int iLine, iSpot, iColon;
	strID = string(iObjID)$":";
	iSpot=-1;
	for (iLine=0; iLine<strLastAIAbility.Length; iLine++)
	{
		if (InStr(strLastAIAbility[iLine], strID) == 0)
			return iLine;
		// Find position for this.
		if (iSpot == -1)
		{
			iColon = InStr(strLastAIAbility[iLine], ":");
			if (iColon != -1)
			{
				strBegin = Left(strLastAIAbility[iLine], iColon);
				if (strID < strBegin)
				{
					iSpot = iLine;
				}

			}
			else
			{
				`Warn("Error- No colon found in AI string!");
			}
		}
	}

	if (iSpot == -1)
	{
		iSpot = strLastAIAbility.Length;
		strLastAIAbility.AddItem(strID);
		if (bDead)
		{
			strLastAIAbility[iSpot] @= "dead.";
		}
	}
	else
	{
		strLastAIAbility.InsertItem(iSpot, strID);
	}
	return iSpot;
}

function AIStringsUpdateString( int iObjID, string strUpdate )
{
	local int iIndex;
	iIndex = AIStringsFindUnitIndex(iObjID);
	if (iIndex == -1)
	{
		iIndex = AIStringsAddUnit(iObjID);
	}
	if (iIndex != -1 && iIndex < strLastAIAbility.Length)
	{
		// Prevent further updates after adding a Skipped Turn message.
		if (InStr(strLastAIAbility[iIndex], "SkippedTurn.") == -1 && InStr(strLastAIAbility[iIndex], "dead.") == -1)
		{
			if (InStr(strLastAIAbility[iIndex], strUpdate) == -1)
			{
				strLastAIAbility[iIndex] @= strUpdate;
			}
		}
	}
	else
	{
		`Warn("Error on AIStringUpdateString!");
	}
}

function ShowLastAIAction( Canvas kCanvas )
{
	local vector2d ViewportSize;
	local Engine                Engine;
	local int iX, iY;
	local string strAIString;
	Engine = class'Engine'.static.GetEngine();
	Engine.GameViewport.GetViewportSize(ViewportSize);

	iX=ViewportSize.X - 500;
	iY=50;

	kCanvas.SetDrawColor(255, 255, 255);
	kCanvas.SetPos(iX, iY);
	iY+= 15;
	kCanvas.DrawText("LastAIActions:");
	foreach strLastAIAbility(strAIString)
	{
		kCanvas.SetPos(iX, iY);
		iY+= 15;
		kCanvas.DrawText(strAIString);
	}
}

function DisplayAlertDataLabels(Canvas kCanvas)
{
	local AlertData Data;
	local vector ScreenPos;
	local XComWorldData XWorld;
	local int iAlert, AlertCount;

	local XComGameState_AIUnitData UnitData;
	UnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(DisplayAlertDataLabelID));
	if( UnitData != None )
	{
		XWorld = `XWorld;
		AlertCount = UnitData.GetAlertCount();
		for( iAlert=0; iAlert < AlertCount; ++iAlert )
		{
			Data = UnitData.GetAlertData(iAlert);
			if( Data.KismetTag != "" )
			{
				ScreenPos = kCanvas.Project(XWorld.GetPositionFromTileCoordinates(Data.AlertLocation));
				kCanvas.SetPos(ScreenPos.X, ScreenPos.Y);

				kCanvas.SetDrawColor(255, 255, 255);
				kCanvas.SetPos(ScreenPos.X, ScreenPos.Y);
				kCanvas.DrawText(Data.KismetTag);
			}
		}
	}
}

exec function KillAllAIs()
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitToKill, UnitState;
	local XComGameStateHistory History;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Kill All AIs");

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.ControllingPlayerIsAI() && UnitState.IsAlive() )
		{
			UnitToKill = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitToKill.SetCurrentStat(eStat_HP, 0);
			`Log("Adding unit #"$UnitState.ObjectID@"to be killed.");
		}
	}

	`TACTICALRULES.SubmitGameState(NewGameState);
}

exec function RemoveAllAIs()
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState;
	local XComGameState_Effect EffectState;
	local XComGameState_AIUnitData AIUnitDataState;
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local XGAIGroup AIGroup;
	local XComGameState_AIGroup GroupState;
	local XGUnit UnitVisualizer;

	// clean up the units
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Kill All AIs");

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.ControllingPlayerIsAI())
		{
			// TODO: clean up unit destruction!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			UnitVisualizer = XGUnit(History.GetVisualizer(UnitState.ObjectID));
			History.SetVisualizer(UnitState.ObjectID, None);
			UnitVisualizer.GetPawn().Destroy();
			UnitVisualizer.Destroy();

			// remove abilities for this unit
			foreach History.IterateByClassType(class'XComGameState_Ability', AbilityState)
			{
				if( AbilityState.OwnerStateObject.ObjectID == UnitState.ObjectID )
				{
					NewGameState.RemoveStateObject(AbilityState.ObjectID);
				}
			}

			// remove effects applied by or to this unit
			foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
			{
				if( EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == UnitState.ObjectID ||
					EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == UnitState.ObjectID )
				{
					NewGameState.RemoveStateObject(EffectState.ObjectID);
				}
			}

			// remove AI data associated with this unit
			foreach History.IterateByClassType(class'XComGameState_AIUnitData', AIUnitDataState)
			{
				if( AIUnitDataState.m_iUnitObjectID == UnitState.ObjectID )
				{
					NewGameState.RemoveStateObject(AIUnitDataState.ObjectID);
				}
			}

			// remove items applied to this unit
			foreach History.IterateByClassType(class'XComGameState_Item', ItemState)
			{
				if( ItemState.OwnerStateObject.ObjectID == UnitState.ObjectID )
				{
					NewGameState.RemoveStateObject(ItemState.ObjectID);
				}
			}

			NewGameState.RemoveStateObject(UnitState.ObjectID);
			`Log("Adding unit #"$UnitState.ObjectID@"to be removed.");
		}
	}

	// remove groups
	foreach History.IterateByClassType(class'XComGameState_AIGroup', GroupState)
	{
		NewGameState.RemoveStateObject(GroupState.ObjectID);
	}

	`TACTICALRULES.SubmitGameState(NewGameState);

	// clean up the group actors for those units
	foreach DynamicActors(class'XGAIGroup', AIGroup)
	{
		AIGroup.Destroy();
	}
}

exec function SpawnAllAIs( int OverrideCurrentForceLevel=0, int OverrideCurrentAlertLevel=0 )
{
	local XComGameState_BattleData BattleData;
	local XComGameState NewGameState;

	BattleData = `BATTLE.m_kDesc;

	if( OverrideCurrentForceLevel == 0 )
	{
		OverrideCurrentForceLevel = BattleData.GetForceLevel();
	}

	if( OverrideCurrentAlertLevel == 0 )
	{
		OverrideCurrentAlertLevel = BattleData.GetAlertLevel();
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Spawn All AIs");
	`SPAWNMGR.SpawnAllAliens(OverrideCurrentForceLevel, OverrideCurrentAlertLevel, NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

exec function RespawnAllAIs( int OverrideCurrentForceLevel=0, int OverrideCurrentAlertLevel=0 )
{
	RemoveAllAIs();
	SpawnAllAIs(OverrideCurrentForceLevel, OverrideCurrentAlertLevel);
}

exec function X2DebugStringPulling()
{
	DebugStringPulling = !DebugStringPulling;
}

exec function EnableTopDownCamera()
{
	local XComTacticalController TacticalController;
	local XComWorldData WorldData;
	local Vector WorldExtents, NewCameraLoc;
	local XComCamera DebugCamera;
	local Rotator NewCameraRot;

	WorldData = `XWORLD;

	TacticalController = XComTacticalController(ViewTarget.Owner);

	if( !TacticalController.IsInState('PlayerDebugCamera') )
	{
		TacticalController.ToggleDebugCamera();

		WorldExtents = (WorldData.WorldBounds.Max - WorldData.WorldBounds.Min) / 2;
		NewCameraLoc = WorldData.WorldBounds.Min + WorldExtents;
		NewCameraLoc.Z += 2.0 * Max(WorldExtents.X, WorldExtents.Y);

		if(WorldExtents.Y <= WorldExtents.X)
		{
			NewCameraRot.Yaw = 16384; // 90 degrees
		}
		NewCameraRot.Pitch = -16384;

		DebugCamera = XComCamera(TacticalController.PlayerCamera);
		LastPOV = DebugCamera.CameraCache.POV;
		DebugCamera.CameraCache.POV.Location = NewCameraLoc;
		DebugCamera.CameraCache.POV.Rotation = NewCameraRot;
	}
}

exec function DisableTopDownCamera()
{
	local XComTacticalController TacticalController;

	TacticalController = XComTacticalController(ViewTarget.Owner);

	if( TacticalController.IsInState('PlayerDebugCamera') )
	{
		XComCamera(TacticalController.PlayerCamera).CameraCache.POV = LastPOV;

		TacticalController.ToggleDebugCamera();
	}
}

exec function DebugSpawningToggle()
{
	if( !bDebugPatrols )
	{
		DebugSpawningSimple();
	}
	else if( DebugSpawnIndex < -1 )
	{
		DebugSpawningDetail(-1);
	}
	else
	{
		DebugSpawningDisable();
	}
}

exec function DebugSpawningDisable()
{
	if( bDebugPatrols )
	{
		DisableTopDownCamera();
		AIDebugPatrols();
	}
}

exec function DebugSpawningSimple()
{
	DebugSpawningDetail(-2);
}

exec function DebugSpawningDetail( int OverrideDebugIndex=-3 )
{
	local XGAIGroup AIGroup;
	local array<XGAIGroup> AIGroups;

	if( !bDebugPatrols )
	{
		EnableTopDownCamera();
		AIDebugPatrols();
		AIShowPatrolPaths();
	}

	if( OverrideDebugIndex >= -2 )
	{
		DebugSpawnIndex = OverrideDebugIndex;
	}
	else
	{
		++DebugSpawnIndex;
	}

	foreach DynamicActors(class'XGAIGroup', AIGroup)
	{
		AIGroup.bDetailedDebugging = (DebugSpawnIndex == -1);
		AIGroups.AddItem(AIGroup);
	}

	if( DebugSpawnIndex >= 0 )
	{
		DebugSpawnIndex = DebugSpawnIndex % AIGroups.Length;
		AIGroup = AIGroups[DebugSpawnIndex];
		AIGroup.bDetailedDebugging = true;
	}
}

// This only sets the cached popular support value in the Battle data.  Does not affect actual regional popular support value set in Strategy.
exec function SetPopularSupport(int iValue)
{
	XGBattle_SP(`BATTLE).SetPopularSupport(iValue);
	if (XGBattle_SP(`BATTLE).GetMaxPopularSupport() < iValue)
	{
		XGBattle_SP(`BATTLE).SetMaxPopularSupport(1000);
	}
}

exec function X2DebugBehavior()
{
	XComPresentationLayer(Outer.Pres).UIDebugBehaviorTree();
}

exec function ForceRefreshAbility(name strAbilityName)
{
	local XComGameState_Unit Unit;

	Unit = GetClosestUnitToCursor();
	`TACTICALRULES.UpdateUnitAbility(Unit, strAbilityName);

}

exec function AIDebugAlertData(int ObjectID)
{
	local XComGameState_Unit TargetUnit;
	local XComGameState_AIUnitData TargetAIUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
	if (TargetUnit.GetAIUnitDataID() > 0)
	{
		TargetAIUnit = XComGameState_AIUnitData(History.GetGameStateForObjectID(TargetUnit.GetAIUnitDataID()));
	}

	if (TargetAIUnit != none)
	{
		TargetAIUnit.bDoDebug = !TargetAIUnit.bDoDebug;

		bDisplayAlertDataLabels = TargetAIUnit.bDoDebug;
		if( TargetAIUnit.bDoDebug )
		{
			Outer.SetTimer(0.1f, false, 'Update', TargetAIUnit);
			DisplayAlertDataLabelID = TargetAIUnit.ObjectID;
		}
	}
}

exec function AIBTInspectTileDest()
{
	local vector CursorLoc;
	CursorLoc = GetCursorLoc();
	kInspectTile = `XWORLD.GetTileCoordinatesFromPosition(CursorLoc);
}

function bool DebugInspectTileDest(TTile kCurrTile)
{
	if (kCurrTile.X == kInspectTile.X && kCurrTile.Y == kInspectTile.Y && abs(kCurrTile.Z-kInspectTile.Z) < 2)
		return true;
	return false;
}

exec function AIBTTestNode( Name strNodeName, int iAIUnitObjectID )
{
	local X2AIBTBehavior kTestNode;
	local XComGameState_Unit kUnit;
	local bt_status kBTStatus;
	local XGAIBehavior kBehavior;
	kUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iAIUnitObjectID));
	kTestNode = `BEHAVIORTREEMGR.GenerateBehaviorTree(strNodeName, kUnit.GetMyTemplate().CharacterGroupName);
	if( kTestNode == None )
	{
		`Log("Error- No node found-"$strNodeName);
	}
	else if (kUnit == None)
	{
		`Log("Error- Invalid unit id-"$iAIUnitObjectID);
	}
	else
	{
		kBehavior = XGUnit(kUnit.GetVisualizer()).m_kBehavior;
		if (kBehavior != None)
		{
			kBehavior.InitBehaviorTree();
			kBTStatus = kTestNode.Run(iAIUnitObjectID, `XCOMHISTORY.GetCurrentHistoryIndex());
			while (kBTStatus == BTS_RUNNING)
			{
				kBTStatus = kTestNode.Run(iAIUnitObjectID, `XCOMHISTORY.GetCurrentHistoryIndex());
			}
			`Log("Ran node "$strNodeName$"."@`ShowVar(kBTStatus));
		}
	}
}

exec function AILogGroupStates()
{
	local XComGameStateHistory History;
	local XComGameState_AIGroup kGroup;
	local StateObjectReference UnitRef;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_AIGroup', kGroup)
	{
		`Log(kGroup@"("$kGroup.ObjectID$")"@ "NumMembers="$ kGroup.m_arrMembers.Length);
		foreach kGroup.m_arrMembers(UnitRef)
		{
			`Log("UnitID="$UnitRef.ObjectID);
		}
	}

}

exec function ToggleAIVisRange()
{
	bShowAIVisRange = !bShowAIVisRange;
}

exec function OverrideBehaviorTreeOnNearestAI(Name OverrideBehaviorTreeNodeName)
{
	local XComGameState_Unit kUnit;
	if( `BEHAVIORTREEMGR.IsValidBehavior(OverrideBehaviorTreeNodeName) )
	{
		kUnit = GetClosestUnitToCursor(true);
		iAIBTOverrideID = kUnit.ObjectID;
		strAIBTOverrideNode = OverrideBehaviorTreeNodeName;
		`Log("Enabled OverrideBehaviorTreeNode on unit #"$iAIBTOverrideID@"Node:"$strAIBTOverrideNode);
	}
	else
	{
		iAIBTOverrideID = 0;
		strAIBTOverrideNode = '';
		if (OverrideBehaviorTreeNodeName != '')
		{
			`Log("Invalid node name: "$OverrideBehaviorTreeNodeName);
		}
		`Log("Disabled override behavior tree.");
	}
}

exec function AILogBTUpdateQueue()
{
	`BEHAVIORTREEMGR.bLogUpdateBTQueue = !`BEHAVIORTREEMGR.bLogUpdateBTQueue;
	`Log(`ShowVar(`BEHAVIORTREEMGR.bLogUpdateBTQueue));
}

exec function BT(Name OverrideBehaviorTreeNode, int RunCount=1, int ActionPointsToGive=1, bool bApplyPointsToGroup=true)
{
	RunBehaviorTreeOnNearestUnit(OverrideBehaviorTreeNode, RunCount, ActionPointsToGive, bApplyPointsToGroup);
}

exec function RunBehaviorTreeOnNearestUnit(Name OverrideBehaviorTreeNode, int RunCount=1, int ActionPointsToGive=1, bool bApplyPointsToGroup=true)
{
	local XGAIPlayer kAI;
	local XComGameState_Unit kUnit, MemberState;
	local XComGameState_AIGroup GroupState;
	local array<XComGameState_Unit> GroupMembers;
	local array<int> GroupIDs;
	kUnit = GetClosestUnitToCursor();
	// For some reason, the default argument is being ignored and set to 0.  Manually setting default value here.
	if( ActionPointsToGive == 0 ) 
	{
		ActionPointsToGive = 1;
	}
	if( bApplyPointsToGroup )
	{
		GroupState = kUnit.GetGroupMembership();
		if( GroupState.GetLivingMembers(GroupIDs, GroupMembers) )
		{
			foreach GroupMembers(MemberState)
			{
				if( MemberState.NumActionPoints() == 0 )
				{
					GiveActionPoints(ActionPointsToGive, MemberState.ObjectID);
				}
			}
		}
	}
	else
	{
		GiveActionPoints(ActionPointsToGive, kUnit.ObjectID);
	}

	// For purposes of Terrorist AI, we may need to update the player terror mission flag in AIPlayer.
	kAI = XGAIPlayer(`BATTLE.GetAIPlayer());
	kAI.UpdateTerror();
	kUnit.AutoRunBehaviorTree(OverrideBehaviorTreeNode, RunCount);
}

// Toggle on and off onscreen debug text displaying AI DownThrottling and UpThrottling values.
exec function AIDebugFightManager()
{
	bDebugFightManager = !bDebugFightManager;
	`Log(`ShowVar(bDebugFightManager));
}

exec function AIDisableFightManager()
{
	bDisableFightManager = !bDisableFightManager;
	`Log(`ShowVar(bDisableFightManager));
}

exec function AIFightMgrForceUpThrottle()
{
	bFightMgrForceUpThrottle = !bFightMgrForceUpThrottle;
	`Log(`ShowVar(bFightMgrForceUpThrottle));
}
exec function AIFightMgrForceDownThrottle()
{
	bFightMgrForceDownThrottle = !bFightMgrForceDownThrottle;
	`Log(`ShowVar(bFightMgrForceDownThrottle));
}

exec function X2DebugSetNextShotDamage(int Damage)
{
	NextShotDamageRigged = true;
	NextShotDamage = Damage;
}

exec function X2DebugSetCanSeeMovement(bool CheatActive, bool SetCanSeeMovement)
{
	OverrideCanSeeMovement = CheatActive;
	CanSeeMovement = SetCanSeeMovement;
}

exec function SetHiddenMovementIndicatorSuppressed(bool Suppressed)
{	
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Cheats CheatState;

	CheatState = class'XComGameState_Cheats'.static.GetCheatsObject();

	if(Suppressed != CheatState.SuppressHiddenMovementIndicator)
	{
		NewGameState = class'XComGameState_Cheats'.static.CreateCheatChangeState();
		CheatState = XComGameState_Cheats(NewGameState.ModifyStateObject(class'XComGameState_Cheats', CheatState.ObjectID));
		CheatState.SuppressHiddenMovementIndicator = Suppressed;

		Ruleset = `TACTICALRULES;
		if(!Ruleset.SubmitGameState(NewGameState))
		{
			`Redscreen("Error updating cheat object state while updating SuppressHiddenMovementIndicator!");
		}
	}
}

exec function SetFirstSeenVODisabled(bool Disabled)
{
	DisableFirstEncounterVO = Disabled;
}

exec function OverrideTacticalMusicSet(name NewMusicSet)
{	
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Cheats CheatState;

	CheatState = class'XComGameState_Cheats'.static.GetCheatsObject();

	if(NewMusicSet != CheatState.TacticalMusicSetOverride)
	{
		NewGameState = class'XComGameState_Cheats'.static.CreateCheatChangeState();
		CheatState = XComGameState_Cheats(NewGameState.ModifyStateObject(class'XComGameState_Cheats', CheatState.ObjectID));
		CheatState.TacticalMusicSetOverride = NewMusicSet;

		Ruleset = `TACTICALRULES;
		if(!Ruleset.SubmitGameState(NewGameState))
		{
			`Redscreen("Error updating cheat object state while updating SuppressHiddenMovementIndicator!");
		}
	}
}


exec function RemoveAllUnitLoot()
{
	local XComGameStateHistory History;
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local LootResults EmptyLoot;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cheat, RemoveAllUnitLoot");

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(Unit.Class, Unit.ObjectID));
		Unit.SetLoot(EmptyLoot);
	}

	Ruleset = `TACTICALRULES;
	if(!Ruleset.SubmitGameState(NewGameState))
	{
		`Redscreen("Error removing all loot!");
	}
}

exec function SetLootDisabled(bool Disabled)
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Cheats CheatState;

	CheatState = class'XComGameState_Cheats'.static.GetCheatsObject();

	if(Disabled != CheatState.DisableLooting)
	{
		NewGameState = class'XComGameState_Cheats'.static.CreateCheatChangeState();
		CheatState = XComGameState_Cheats(NewGameState.ModifyStateObject(class'XComGameState_Cheats', CheatState.ObjectID));
		CheatState.DisableLooting = Disabled;

		Ruleset = `TACTICALRULES;
		if(!Ruleset.SubmitGameState(NewGameState))
		{
			`Redscreen("Error updating cheat object state while updating DisableLooting!");
		}
	}
}

exec function X2OverrideConcealmentShader(bool ShouldOverride, bool ShaderOn)
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Cheats CheatState;
	local EConcealmentShaderOverride NewOverrideSetting;

	// first determine what the new setting should be
	if(ShouldOverride)
	{
		NewOverrideSetting = ShaderOn ? eConcealmentShaderOverride_On : eConcealmentShaderOverride_Off;
	}
	else
	{
		NewOverrideSetting = eConcealmentShaderOverride_None;
	}

	CheatState = class'XComGameState_Cheats'.static.GetCheatsObject();

	if(NewOverrideSetting != CheatState.ConcealmentShaderOverride)
	{
		NewGameState = class'XComGameState_Cheats'.static.CreateCheatChangeState();
		CheatState = XComGameState_Cheats(NewGameState.ModifyStateObject(class'XComGameState_Cheats', CheatState.ObjectID));
		CheatState.ConcealmentShaderOverride = NewOverrideSetting;

		Ruleset = `TACTICALRULES;
		if(!Ruleset.SubmitGameState(NewGameState))
		{
			`Redscreen("Error updating cheat object state while updating DisableLooting!");
		}
	}
}

exec function SetTurnOverlayDisabled(bool Disabled)
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Cheats CheatState;

	CheatState = class'XComGameState_Cheats'.static.GetCheatsObject();

	if(Disabled != CheatState.DisableTurnOverlay)
	{
		NewGameState = class'XComGameState_Cheats'.static.CreateCheatChangeState();
		CheatState = XComGameState_Cheats(NewGameState.ModifyStateObject(class'XComGameState_Cheats', CheatState.ObjectID));
		CheatState.DisableTurnOverlay = Disabled;

		Ruleset = `TACTICALRULES;
		if(!Ruleset.SubmitGameState(NewGameState))
		{
			`Redscreen("Error updating cheat object state while updating DisableLooting!");
		}
	}
}

exec function SetUnitSwitchingDisabled(bool Disabled)
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Cheats CheatState;

	CheatState = class'XComGameState_Cheats'.static.GetCheatsObject();

	if(Disabled != CheatState.DisableUnitSwitching)
	{
		NewGameState = class'XComGameState_Cheats'.static.CreateCheatChangeState();
		CheatState = XComGameState_Cheats(NewGameState.ModifyStateObject(class'XComGameState_Cheats', CheatState.ObjectID));
		CheatState.DisableUnitSwitching = Disabled;

		Ruleset = `TACTICALRULES;
		if(!Ruleset.SubmitGameState(NewGameState))
		{
			`Redscreen("Error updating cheat object state while updating DisableUnitSwitching!");
		}
	}
}

exec function SetRushCamsDisabled(bool Disabled)
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Cheats CheatState;

	CheatState = class'XComGameState_Cheats'.static.GetCheatsObject();

	if(Disabled != CheatState.DisableRushCams)
	{
		NewGameState = class'XComGameState_Cheats'.static.CreateCheatChangeState();
		CheatState = XComGameState_Cheats(NewGameState.ModifyStateObject(class'XComGameState_Cheats', CheatState.ObjectID));
		CheatState.DisableRushCams = Disabled;

		Ruleset = `TACTICALRULES;
		if(!Ruleset.SubmitGameState(NewGameState))
		{
			`Redscreen("Error updating cheat object state while updating DisableRushCams!");
		}
	}
}

exec function SetAlwaysDoCinescriptCut(bool AlwaysCut)
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameState NewGameState;
	local XComGameState_Cheats CheatState;

	CheatState = class'XComGameState_Cheats'.static.GetCheatsObject();

	if(AlwaysCut != CheatState.AlwaysDoCinescriptCut)
	{
		NewGameState = class'XComGameState_Cheats'.static.CreateCheatChangeState();
		CheatState = XComGameState_Cheats(NewGameState.ModifyStateObject(class'XComGameState_Cheats', CheatState.ObjectID));
		CheatState.AlwaysDoCinescriptCut = AlwaysCut;

		Ruleset = `TACTICALRULES;
		if(!Ruleset.SubmitGameState(NewGameState))
		{
			`Redscreen("Error updating cheat object state while updating AlwaysDoCinescriptCut!");
		}
	}
}

exec function X2ChaosLayerTest(optional int SphereCount = 20, optional int DamageRadiusTiles = 2)
{
	local XComWorldData WorldData;
	local XGBattle Battle;
	local int SphereIndex;
	local array<XComDestructionSphere> SpawnedSpheres;
	local XComDestructionSphere Sphere;
	local Vector SphereCenter;
	local Vector WorldSize;

	WorldData = `XWORLD;
	WorldSize = WorldData.WorldBounds.Max - WorldData.WorldBounds.Min;
	WorldSize.Z = class'XComWorldData'.const.WORLD_FloorHeight * 3; // don't cause explosions way up in the sky

	Battle = `Battle;

	if(DamageRadiusTiles == 0)
	{
		DamageRadiusTiles = 2; // yay compiler bug
	}

	// spawn a bunch of detruction spheres and detonate them
	for(SphereIndex = 0; SphereIndex < SphereCount; SphereIndex++)
	{
		SphereCenter.X = FRand() * WorldSize.X + WorldData.WorldBounds.Min.X;
		SphereCenter.Y = FRand() * WorldSize.Y + WorldData.WorldBounds.Min.Y;
		SphereCenter.Z = FRand() * WorldSize.Z + WorldData.WorldBounds.Min.Z;

		Sphere = Battle.Spawn(class'XComDestructionSphere', Battle,, SphereCenter);
		Sphere.DamageRadiusTiles = DamageRadiusTiles;

		SpawnedSpheres.AddItem(Sphere);
	}

	// and then detonate the spheres
	foreach SpawnedSpheres(Sphere)
	{
		Sphere.Explode();
	}
}

exec function X2ResetCooldowns(optional bool OnlyXComAbilities, optional name SpecificAbility, optional int NewCooldown=0)
{
	local XComGameState_Ability NewAbilityState;
	local XComGameState_Player NewPlayerState;
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local name CurrentAbilityName;

	History = `XCOMHISTORY;

	// Create the game state
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Reset Ability Cooldowns");

	foreach History.IterateByClassType(class'XComGameState_Ability', NewAbilityState)
	{
		CurrentAbilityName = NewAbilityState.GetMyTemplateName();
		if( (SpecificAbility == '' || SpecificAbility == CurrentAbilityName) &&
		   (NewAbilityState.IsCoolingDown() || NewCooldown > 0))
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(NewAbilityState.OwnerStateObject.ObjectID));

			// exclude non-XCom owned abilities
			if( OnlyXComAbilities )
			{
				if( UnitState.GetTeam() != eTeam_XCom )
				{
					continue;
				}
			}

			// update the cooldown on the ability itself
			NewAbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', NewAbilityState.ObjectID));
			NewAbilityState.iCooldown = NewCooldown;

			// update the cooldown on the player
			NewPlayerState = XComGameState_Player(NewGameState.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));
			if( NewPlayerState == None )
			{
				NewPlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));
			}
			if( NewPlayerState.GetCooldown(CurrentAbilityName) > 0 || NewCooldown > 0 )
			{
				NewPlayerState = XComGameState_Player(NewGameState.ModifyStateObject(class'XComGameState_Player', NewPlayerState.ObjectID));
				NewPlayerState.SetCooldown(CurrentAbilityName, NewCooldown);
			}
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function AISetAllPodsConvergeOnMissionComplete( bool bConverge=true)
{
	local XComGameState_BattleData BattleData;

	bAllPodsConvergeOnMissionComplete = bConverge;
	`Log(`ShowVar(bAllPodsConvergeOnMissionComplete));
	if( bAllPodsConvergeOnMissionComplete )
	{
		// Trigger the event if the mission is already complete.
		BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if( BattleData.AllStrategyObjectivesCompleted() )
		{
			`XEVENTMGR.TriggerEvent('OnMissionObjectiveComplete', BattleData, BattleData);
		}
	}
}

exec function DisablePanic( bool bDisabled=true )
{
	bDisablePanic = bDisabled;
	`Log(`ShowVar(bDisablePanic));
}

exec function AlwaysPanic()
{
	bAlwaysPanic = !bAlwaysPanic;
	`log(`ShowVar(bAlwaysPanic));
}

exec function PanicClosestUnit( Name AbilityName='')
{
	local XComGameState_Unit ClosestUnit, NewUnitState;
	local XComGameState NewGameState;

	if (AbilityName == '')
	{
		AbilityName = 'Panicked';  // default arg.
	}

	ClosestUnit = GetClosestUnitToCursor();
	if (ClosestUnit.ObjectID > 0)
	{
		if (!ActivateAbility(AbilityName, ClosestUnit.GetReference()))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Panic unit #"$ClosestUnit.ObjectID);
			NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(ClosestUnit.Class, ClosestUnit.ObjectID));
			NewUnitState.bPanicked = true;
			NewUnitState.SetCurrentStat(eStat_AlertLevel, `ALERT_LEVEL_RED);
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
		XGUnit(NewUnitState.GetVisualizer()).IdleStateMachine.CheckForStanceUpdate();
	}
}
exec function PanicClosestUnit_Obsessed()
{
	PanicClosestUnit('Obsessed');
}
exec function PanicClosestUnit_Shattered()
{
	PanicClosestUnit('Shattered');
}
exec function PanicClosestUnit_Berserk()
{
	PanicClosestUnit('Berserk');
}

exec function DisableSecondaryFires(bool bDisabled = true)
{
	bDisableSecondaryFires = bDisabled;
	`Log(`ShowVar(bDisableSecondaryFires));
}

exec function ToggleGodMode()
{
	ToggleUnlimitedActions();       //  Unlimited Actions
	ToggleUnlimitedAmmo();          //	Unlimited Ammo
	DeadEye();                      //  Dead Eye Aim
	if (!bGodMode)
	{
		X2ResetCooldowns(true,);        //	Resetting existing cooldown penalties
		bGodMode = true;
		ClientMessage("God Mode on");
	}
	else
	{
		bGodMode = false;
		ClientMessage("God Mode off");
	}
}

exec function EnableMarketingCamera(optional bool bHide = true, optional bool bDisableFOW = true)
{
`if(`notdefined(FINAL_RELEASE))
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local XComPathingPawn PathingPawn;
	local XGUnit Unit;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if (PlayerState.GetTeam() == eTeam_XCom)
		{
			break;
		}
	}

	/************** Squad Concealment *****************/
	if (bHide)
		PlayerState.SetSquadConcealment(!bHide);

	/************** FOW *****************/
	if (bDisableFOW && bHide)
		`BATTLE.SetFOW(false);
	else
		`BATTLE.SetFOW(true);

	/************** Building Visibility ****************/
	DisableBuildingVisibility(!bHide);

	/************** UI ****************/
	HideGFXUI(!bHide);
	
	//UIToggleVisibility();
	if (bHide)
	{
		Outer.Pres.Get2DMovie().Hide();
		Outer.Pres.Get3DMovie().Hide();
	}
	else
	{
		Outer.Pres.Get2DMovie().Show();
		Outer.Pres.Get3DMovie().Show();
	}

	//UIToggleShields();
	m_bAllowShields = !bHide;

	foreach Outer.AllActors(class'XComPathingPawn', PathingPawn)
	{
		PathingPawn.SetHidden(bHide);
	}

	//UIToggleMouseCursor();
	bHidePathingPawn = bHide;

	//UIToggleTether();
	m_bAllowTether = !bHide;

	WorldData = class'XComWorldData'.static.GetWorldData();
	if (WorldData != none && WorldData.Volume != none)
	{
		class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.SetCinematicHidden(!m_bAllowTether);
		class'XComWorldData'.static.GetWorldData().Volume.BorderComponentDashing.SetCinematicHidden(!m_bAllowTether);
	}

	//UIToggleDisc();
	UISetDiscState(bHide);

	foreach Outer.AllActors(class'XGUnit', Unit)
	{
		Unit.RefreshUnitDisc();
	}

`endif
}

exec function ToggleSquadConcealment()
{
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if( PlayerState.GetTeam() == eTeam_XCom )
		{
			break;
		}
	}

	PlayerState.SetSquadConcealment(!PlayerState.bSquadIsConcealed);
}

exec function ToggleIndividualConcealment()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(GetActiveUnit().ObjectID));
	if( UnitState.IsConcealed() )
	{
		UnitState.BreakConcealment();
	}
	else
	{
		UnitState.EnterConcealment();
	}
}


exec function GatekeeperOpenAll()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local UnitValue OpenCloseValue;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
			if( UnitState.GetMyTemplateName() == 'Gatekeeper' )
			{
				UnitState.GetUnitValue(class'X2Ability_Gatekeeper'.default.OpenCloseAbilityName, OpenCloseValue);
				if( OpenCloseValue.fValue != class'X2Ability_Gatekeeper'.const.GATEKEEPER_OPEN_VALUE )
				{
					ActivateAbility(class'X2Ability_Gatekeeper'.default.OpenCloseAbilityName, UnitState.GetReference());
				}
			}
		}
}

exec function GatekeeperCloseAll()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local UnitValue OpenCloseValue;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetMyTemplateName() == 'Gatekeeper' )
		{
			UnitState.GetUnitValue(class'X2Ability_Gatekeeper'.default.OpenCloseAbilityName, OpenCloseValue);
			if( OpenCloseValue.fValue != class'X2Ability_Gatekeeper'.const.GATEKEEPER_CLOSED_VALUE )
			{
				ActivateAbility(class'X2Ability_Gatekeeper'.default.OpenCloseAbilityName, UnitState.GetReference());
			}
		}
	}
}

// debug display current mission / job list / job assignments
exec function AIDebugJobs()
{
	bDebugJobManager = !bDebugJobManager;
	`Log(`ShowVar(bDebugJobManager));
}

// Test/Cheat function to reset all jobs.
exec function AIClearJobs()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Clear all AI Jobs");

	`AIJobMgr.ResetJobAssignments(0, NewGameState);

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

// Set job on closest unit.
exec function AIChangeJob(name NewJob, int ObjectID=0)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local int JobListingIndex;
	local XComGameStateHistory History;
	local X2AIJobManager AIJobMgr;
	History = `XCOMHISTORY;
	AIJobMgr = `AIJobMgr;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Change AI Job");
	JobListingIndex = AIJobMgr.GetJobIndex(NewJob);

	if( JobListingIndex != INDEX_NONE )
	{
		if( ObjectID <= 0 )
		{
			UnitState = GetClosestUnitToCursor(true);
			ObjectID = UnitState.ObjectID;
		}
		else
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
		}

		AIJobMgr.AssignUnitToJob(UnitState.GetAIUnitDataID(), JobListingIndex, AIJobMgr.JobAssignments.Length, NewGameState);
	}
	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

function bool ActivateAbility(name AbilityName, StateObjectReference UnitRef)
{
	local GameRulesCache_Unit UnitCache;
	local int i, j;
	local X2TacticalGameRuleset TacticalRules;
	local StateObjectReference AbilityRef;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
	AbilityRef = UnitState.FindAbility(AbilityName);

	TacticalRules = `TACTICALRULES;
	if( AbilityRef.ObjectID > 0 &&  TacticalRules.GetGameRulesCache_Unit(UnitRef, UnitCache) )
	{
		for( i = 0; i < UnitCache.AvailableActions.Length; ++i )
		{
			if( UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == AbilityRef.ObjectID )
			{
				for( j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; ++j )
				{
					if( UnitCache.AvailableActions[i].AvailableTargets[j].PrimaryTarget == UnitRef )
					{
						if( UnitCache.AvailableActions[i].AvailableCode == 'AA_Success' )
						{
							return class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j);
						}
						break;
					}
				}
				break;
			}
		}
	}
	return false;
}

exec function X2CombatLog()
{
	bCombatLog = !bCombatLog;
}

exec function X2GoldenPathHacks()
{
	bGoldenPathHacks = !bGoldenPathHacks;
}

exec function MarkDemoStart()
{
	// TO DO: Update GameState for AIUnitData to remove the 0th element of the alert tiles array.
	local XComGameStateContext_TacticalGameRule NewContext;
	local XComGameState NewGameState;

	NewContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_DemoStart);
	NewGameState = NewContext.ContextBuildGameState();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function X2ForceAllUnitsVisible()
{
	ForceAllUnitsVisible = !ForceAllUnitsVisible;
	if(ForceAllUnitsVisible && `XWORLD.bDebugEnableFOW)
	{
		ToggleFOW();
	}
	else if(!ForceAllUnitsVisible && !`XWORLD.bDebugEnableFOW)
	{
		ToggleFOW();
	}	
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle();
}

exec function SetWorldMessagesInOTS(bool bOn)
{
	bHideWorldMessagesInOTS = !bOn;
}

exec function AIForceUnitToCursorLoc(int ObjectID)
{
	local XComWorldData WorldData;
	local StateObjectReference UnitStateRef;
	local Ttile MoveDestination;
	local Vector CursorLocation;

	WorldData = `XWORLD;

	CursorLocation = GetCursorLoc();
	if(WorldData.GetFloorTileForPosition(CursorLocation, MoveDestination))
	{
		UnitStateRef.ObjectID = ObjectID;
		AddForcedAIMoveDestination(UnitStateRef, MoveDestination);
	}
}

exec function ListHumanPlayerUnits()
{
	local array<XComGameState_Unit> Units, OriginalUnits;
	local XComGameState_Unit UnitIter;
	local XGPlayer HumanPlayer;

	HumanPlayer = XGBattle_SP(`BATTLE).GetHumanPlayer();
	HumanPlayer.GetUnits(Units);
	HumanPlayer.GetOriginalUnits(OriginalUnits);

	`log("Units for Human Player:");
	foreach Units(UnitIter)
	{
		`log(UnitIter.GetName(eNameType_RankFull));
	}
	`log("Original Units:");
	foreach OriginalUnits(UnitIter)
	{
		`log(UnitIter.GetName(eNameType_RankFull));
	}
}

exec function AIDisableFallback()
{
	local XGAIPlayer AIPlayer;
	local XComGameState_AIPlayerData AIData;
	local XComGameState NewGameState;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Disable Fallback. (not retroactive)");
	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	AIData = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', AIPlayer.GetAIDataID()));
	AIData.RetreatCap = 0;
	if( !`TACTICALRULES.SubmitGameState(NewGameState) )
	{
		`Redscreen("AIDisableFallback(): Could not submit state!");
	}
}

exec function AIForceFallback()
{
	local XComGameState_AIGroup GroupState;
	local XComGameState NewGameState;
	local XComGameStateHistory	History;
	History = `XCOMHistory;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Force Fallback chance 100%.");
	foreach History.IterateByClassType(class'XComGameState_AIGroup', GroupState)
	{
		GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', GroupState.ObjectID));
		GroupState.FallbackChance = 1.0;
	}
	if( !`TACTICALRULES.SubmitGameState(NewGameState) )
	{
		`Redscreen("AIForceFallback(): Could not submit state!");
	}
}

exec function SwitchControllingPlayer(optional int PlayerIndex = -1)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local XComTacticalController kLocalPC;
	local X2TacticalGameRuleset TactialRuleset;

	History = `XCOMHISTORY;
	TactialRuleset = `TACTICALRULES;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if( PlayerIndex >= 0 && PlayerIndex < BattleData.PlayerTurnOrder.Length )
	{
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(BattleData.PlayerTurnOrder[PlayerIndex].ObjectID));

		kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
		kLocalPC.SetControllingPlayer( PlayerState );
		kLocalPC.SetTeamType( PlayerState.TeamFlag );
	}
	else
	{
		for( PlayerIndex = 0; PlayerIndex < BattleData.PlayerTurnOrder.Length; ++PlayerIndex )
		{
			PlayerState = XComGameState_Player(History.GetGameStateForObjectID(BattleData.PlayerTurnOrder[PlayerIndex].ObjectID));
			OutputMsg("  - ["$PlayerIndex$"]" @ PlayerState.PlayerName @ ((TactialRuleset.CachedUnitActionPlayerRef.ObjectID == PlayerState.ObjectID) ? "[Active Player]" : ""));
		}
	}
}

exec function GiveHackReward(Name HackRewardName)
{
	local X2TacticalGameRuleset TactialRuleset;
	local X2HackRewardTemplateManager TemplateMan;
	local X2HackRewardTemplate Template;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;

	TactialRuleset = `TACTICALRULES;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Gain Hack Reward '" $ HackRewardName $ "'");

	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnitStateRef().ObjectID));

	TemplateMan = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	Template = TemplateMan.FindHackRewardTemplate(HackRewardName);

	Template.OnHackRewardAcquired(Unit, None, NewGameState);

	TactialRuleset.SubmitGameState(NewGameState);
}

exec function StartGeneratingCover()
{
	local XGUnit ActiveUnit;
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if(ActiveUnit == none) return;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.ObjectID));
	if(UnitState == none) return;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = GeneratingCover_BuildVisualization;
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	UnitState.bGeneratesCover = true;
	UnitState.CoverForceFlag = CoverForce_High;
	`TACTICALRULES.SubmitGameState(NewGameState);
}

exec function StopGeneratingCover()
{
	local XGUnit ActiveUnit;
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if(ActiveUnit == none) return;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.ObjectID));
	if(UnitState == none) return;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = GeneratingCover_BuildVisualization;
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	UnitState.bGeneratesCover = false;
	UnitState.CoverForceFlag = CoverForce_Default;
	`TACTICALRULES.SubmitGameState(NewGameState);
}

function GeneratingCover_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local TTile RebuildTile;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		RebuildTile = UnitState.TileLocation;
		WorldData.DebugRebuildTileData(RebuildTile);
		RebuildTile.X -= 1;
		WorldData.DebugRebuildTileData(RebuildTile);
		RebuildTile.X += 2;
		WorldData.DebugRebuildTileData(RebuildTile);
		RebuildTile = UnitState.TileLocation;
		RebuildTile.Y -= 1;
		WorldData.DebugRebuildTileData(RebuildTile);
		RebuildTile.Y += 2;
		WorldData.DebugRebuildTileData(RebuildTile);
	}
}

exec function ForceRefreshAllUnitFlags()
{
	`PRES.m_kUnitFlagManager.ForceRefreshAllUnitFlags();
}

exec function SaveScum()
{
	class'Engine'.static.GetEngine().SetRandomSeeds(class'Engine'.static.GetEngine().GetARandomSeed());
}
exec function SetRandomSeed(int SeedNum)
{
	local int Seed;
	Seed = SeedNum;
	class'Engine'.static.GetEngine().SetRandomSeeds(Seed);
}

exec function AlwaysBleedOut()
{
	bAlwaysBleedOut = !bAlwaysBleedOut;
	`log(`ShowVar(bAlwaysBleedOut));
}

exec function DebugShowRestrictorsForCharacterTemplate(optional Name InTemplate)
{
	ShowRestrictorsForCharacterTemplate = InTemplate;
}

// Test function
exec function IsCursorInDisallowedPathingLocation()
{
	local vector TestLocation;
	TestLocation = GetCursorLoc();
	if( class'XComSpawnRestrictor'.static.IsInvalidPathLocation(TestLocation) )
	{
		`Log("CHEAT::IsCursorInSpawnRestrictor returns TRUE.");
	}
	else
	{
		`Log("CHEAT::IsCursorInSpawnRestrictor returns FALSE");
	}

}

exec function GiveAbilityCharges()
{
	local XComGameState_Ability AbilityState;
	local XComGameState NewGameState;
	local XComGameStateHistory	History;

	History = `XCOMHistory;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: GiveAbilityCharges.");
	foreach History.IterateByClassType(class'XComGameState_Ability', AbilityState)
	{
		AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', AbilityState.ObjectID));
		AbilityState.iCharges = 1000;
	}
	if( !`TACTICALRULES.SubmitGameState(NewGameState) )
	{
		`Redscreen("GiveAbilityCharges(): Could not submit state!");
	}

}

exec function X2DebugStepouts()
{
	bDebugIdleAnimationStateMachines = !bDebugIdleAnimationStateMachines;
}

exec function X2DebugPodrevealDecisions()
{
	bDebugPodReveals = !bDebugPodReveals;
}

function DrawPodRevealDecisionInformation(Canvas kCanvas)
{
	local string DebugString;	

	DebugString = "===================================\n";
	DebugString $= "=======    Matinee Selection Logic   ========\n";
	DebugString $= "===================================\n\n";

	DebugString $= PodRevealDecisionRecord;

	// draw a background box so the text is readable
	kCanvas.SetPos(10, 150);
	kCanvas.SetDrawColor(0, 0, 0, 100);
	kCanvas.DrawRect(700, 700);

	// draw the text
	kCanvas.SetPos(10, 150);
	kCanvas.SetDrawColor(0, 255, 0);
	kCanvas.DrawText(DebugString);
}

exec function ShowDestructibleVisibilityTiles()
{
	local WorldInfo Info;
	local XComWorldData WorldData;
	local XComGameStateHistory History;
	local XComGameState_Destructible Destructible;
	local array<TTile> Tiles;
	local TTile Tile;
	local Vector TileLocation;

	WorldData = `XWORLD;
	History = `XCOMHISTORY;
	Info = class'WorldInfo'.static.GetWorldInfo();

	foreach History.IterateByClassType(class'XComGameState_Destructible', Destructible)
	{
		Tiles.Length = 0;
		Destructible.GetVisibilityLocation(Tiles);
		foreach Tiles(Tile)
		{
			TileLocation = WorldData.GetPositionFromTileCoordinates(Tile);
			Info.DrawDebugSphere(TileLocation, class'XComWorldData'.const.WORLD_HalfFloorHeight, 4, 255, 255, 255, true);
		}
	}
}

function AddForcedAIMoveDestination(StateObjectReference UnitStateRef, TTile Destination)
{
	local ForcedAIMoveDestination ForcedAIMove;

	ForcedAIMove.UnitStateRef = UnitStateRef;
	ForcedAIMove.MoveDestination = Destination;
	ForcedDestinationQueue.AddItem(ForcedAIMove);
}

exec function ForceOverwatchTarget(int TargetId)
{
	ForcedOverwatchTarget.ObjectId = TargetID;
}

exec function ToggleAutoRun()
{
	`AUTOPLAYMGR.ToggleAutoRun();
}
exec function AIAlienRulersDoNotTrigger(bool bSetting)
{
	bAbilitiesDoNotTriggerAlienRulerAction = bSetting;
}

exec function PopulateAnalytics()
{
	local array<string> BaseMetrics;
	local string Metric, EndgameMetric;
	local int x, d;
	local X2FiraxisLiveClient LiveClient;

	LiveClient = `FXSLIVE;

/*	BaseMetrics.AddItem( "ARCHON_KING_KILLED" );
	BaseMetrics.AddItem( "SOLDIERS_KILLED_BY_ARCHON_KING" );
	BaseMetrics.AddItem( "VIPER_KING_KILLED" );
	BaseMetrics.AddItem( "SOLDIERS_KILLED_BY_VIPER_KING" );
	BaseMetrics.AddItem( "BERSERKER_QUEEN_KILLED" );
	BaseMetrics.AddItem( "SOLDIERS_KILLED_BY_BERSERKER_QUEEN" );
	BaseMetrics.AddItem( "TOTAL_CENTRAL_KILLS" );
	BaseMetrics.AddItem( "CENTRALS_KILLED" );
	BaseMetrics.AddItem( "KILLS_WITH_HUNTER_RIFLES" );
	BaseMetrics.AddItem( "KILLS_WITH_HUNTER_PISTOLS" );
	BaseMetrics.AddItem( "KILLS_WITH_HUNTER_AXES" );
	BaseMetrics.AddItem( "KILLS_WITH_ALIEN_ARMOR" );

	BaseMetrics.AddItem( "ANDROMEDON_ROBOT_KILLED" );
	BaseMetrics.AddItem( "SOLDIERS_KILLED_BY_ANDROMEDON_ROBOT" );
	BaseMetrics.AddItem( "UNKNOWN_ENEMY_TYPE_KILLED" );
	BaseMetrics.AddItem( "SOLDIERS_KILLED_BY_UNKNOWN_ENEMY_TYPE" );
	BaseMetrics.AddItem( "TOTAL_HACKED_ROBOTIC_KILLS" );
	BaseMetrics.AddItem( "TOTAL_CONTROLLED_ADVENT_KILLS" );
	BaseMetrics.AddItem( "TOTAL_CONTROLLED_ALIEN_KILLS" );
	BaseMetrics.AddItem( "TOTAL_UNKNOWN_KILLS" );
	BaseMetrics.AddItem( "TOTAL_UNKNOWN_SOLDIER_CLASS_KILLS" );
	BaseMetrics.AddItem( "KILLS_WITH_UNKNOWN_WEAPONS" );
	BaseMetrics.AddItem( "TOTAL_ROOKIE_KILLS" );
	BaseMetrics.AddItem( "UNKNOWN_SOLDIER_CLASS_KILLED" );
	BaseMetrics.AddItem( "ROOKIE_SOLIDER_KILLED" );
	BaseMetrics.AddItem( "UNKNOWN_RANK_KILLED" );
	BaseMetrics.AddItem( "SOLDIERS_KILLED_BY_ENVIRONMENT" );
	BaseMetrics.AddItem( "SOLDIERS_KILLED_BY_CONTROLLED_FRIENDLY" );
	BaseMetrics.AddItem( "TOTAL_COMMANDER_KILLS" );*/
	BaseMetrics.AddItem( "COMMANDERS_KILLED" );

	for(x = 0; x < BaseMetrics.Length; ++x)
	{
		Metric = BaseMetrics[x];
		EndgameMetric = "ENDGAME_"$Metric;

		LiveClient.StatAddValue( name( EndgameMetric ), 0, eKVPSCOPE_GLOBAL );

		for (d = 0; d < eDifficulty_MAX; ++d)
		{
			LiveClient.StatAddValue( name( Metric$"_"$d ), 0, eKVPSCOPE_GLOBAL );
			LiveClient.StatAddValue( name( EndgameMetric$"_"$d ), 0, eKVPSCOPE_GLOBAL );
		}
	}
}

exec function ForceRulerOverlayHidden()
{
	`PRES.UIHideSpecialTurnOverlay();
}

exec function AIDoGroupMoveToCursor(int GroupID)
{
	local XComGameState_AIGroup GroupState;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> GroupUnits;
	local array<int> GroupIDs;
	local Vector CursorLocation;
	local String FailText;

	History = `XCOMHISTORY;
	GroupState = XComGameState_AIGroup(History.GetGameStateForObjectID(GroupID));
	if( GroupState != None )
	{
		// Force all units in group to have at least one action point.
		GroupState.GetLivingMembers(GroupIDs, GroupUnits);
		foreach GroupUnits(UnitState)
		{
			if( UnitState.NumActionPointsForMoving() < 1 )
			{
				GiveActionPoints(1, UnitState.ObjectID);
			}
		}
		CursorLocation = GetCursorLoc();
		if( !GroupState.GroupMoveToPoint(CursorLocation, FailText) )
		{
			`Log(FailText);
		}
	}
}

exec function AITestMeleePointsAroundNearestUnit()
{
	local XComGameState_Unit ClosestUnit;
	local array<TTile> MeleeTiles;
	local TTile Tile;
	ClosestUnit = GetClosestUnitToCursor();
	if( class'Helpers'.static.FindTilesForMeleeAttack(ClosestUnit, MeleeTiles) )
	{
		foreach MeleeTiles(Tile)
		{
			DrawSphereT(Tile);
		}
	}
	`Log("Found"@MeleeTiles.Length@"melee tiles around target "$ClosestUnit.ObjectID);
}

exec function X2ShowFullObject(int ObjectID)
{
	local XComGameState_BaseObject Object;

	Object = `XCOMHISTORY.GetGameStateForObjectID(ObjectID);
	if (Object == none)
	{
		`log("No object with ID" @ ObjectID @ "found in the history.");
	}
	else
	{
		`log(Object.ToString(true));
	}
}

exec function DropTheLost()
{
	local XComGameState_BattleData BattleData;

	EnableLost();

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	class'XComGameState_AIReinforcementSpawner'.static.InitiateReinforcements('TheLost_FirstSpawn', 0, , , BattleData.LostSpawningDistance, , , 'TheLostSwarm', true, false, true, true, true);
}

exec function DebugLostSpawning()
{
	local XComGameState_BattleData BattleData;
	bDebugLostSpawning = !bDebugLostSpawning;
	if (bDebugLostSpawning)
	{
		BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		`log(`ShowVar(BattleData.LostSpawningLevel));
	}
	`log(`ShowVar(bDebugLostSpawning));
}
function DisplayLostSpawningInfo(Canvas kCanvas)
{
	local XComGameState_BattleData BattleData;
	local vector2d ViewportSize;
	local Engine                Engine;
	local int iX, iY;
	local String Text;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	Engine = class'Engine'.static.GetEngine();
	Engine.GameViewport.GetViewportSize(ViewportSize);
	iX = ViewportSize.X - 300;
	iY = ViewportSize.Y - 300;

	if (BattleData != None)
	{
		Text = "Lost Spawning Level:"@ BattleData.LostSpawningLevel;
		kCanvas.SetDrawColor(255, 255, 255);
		kCanvas.SetPos(iX, iY);
		iY += 15;
		kCanvas.DrawText(Text);
	}
}
exec function DebugChosen()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	bDebugChosen = !bDebugChosen;
	if( bDebugChosen && ChosenID <= 0 )
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.IsChosen() && UnitState.IsAlive() )
			{
				ChosenID = UnitState.ObjectID;
				break;
			}
		}
	}
	`log(`ShowVar(bDebugChosen));
}

function DisplayChosenInfo(Canvas kCanvas)
{
	local UnitValue ActivationState;
	local XComGameState_Unit ChosenState;
	local XComGameState_AIGroup GroupState;
	local vector2d ViewportSize;
	local Engine                Engine;
	local int iX, iY;
	local String Text;

	if( ChosenID > 0 )
	{
		ChosenState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenID));
	}
	Engine = class'Engine'.static.GetEngine();
	Engine.GameViewport.GetViewportSize(ViewportSize);
	iX = ViewportSize.X - 300;
	iY = ViewportSize.Y - 300;

	if( ChosenState != None )
	{
		ChosenState.GetUnitValue(class'XComGameState_AdventChosen'.default.ChosenActivatedStateUnitValue, ActivationState);
		if( ActivationState.fValue == 0 )
		{
			Text = "Chosen State = Unactivated";
			if( ChosenState.IsUnitAffectedByEffectName('ChosenActivated') )
			{
				Text = Text @ " with *Activated* effect";
			}
		}
		else if (ActivationState.fValue == 1 )
		{
			Text = "Chosen State = Activated";
		}
		else if( ActivationState.fValue == 2 )
		{
			Text = "Chosen State = Engaged";
		}
		kCanvas.SetDrawColor(255, 255, 255);
		kCanvas.SetPos(iX, iY);
		iY += 15;
		kCanvas.DrawText(Text);
		GroupState = ChosenState.GetGroupMembership();
		if( GroupState.bShouldRemoveFromInitiativeOrder )
		{
			kCanvas.SetPos(iX, iY);
			iY += 15;
			kCanvas.DrawText(" Removed from Initiative Order. ");
		}
	}
}

exec function GiveTrait(Name TraitTemplateName)
{
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState('Adding trait ' $ TraitTemplateName);

	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnitStateRef().ObjectID));
	Unit.AcquireTrait(NewGameState, TraitTemplateName, true);

	`TACTICALRULES.SubmitGameState(NewGameState);
}

exec function SetRevealChance(int Chance)
{
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetRevealChance");

	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', GetActiveUnitStateRef().ObjectID));
	Unit.SuperConcealmentLoss = Clamp(Chance, 0, 100);

	`TACTICALRULES.SubmitGameState(NewGameState);
}

exec function InitDynamicNarrativeManager()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: InitDynamicNarrativeManager");
	class'XComGameState_NarrativeManager'.static.SetUpNarrativeManager(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function AIToggleLostAssignment()
{
	local XComGameState_Unit LostUnit;
	local ETeam AssignedTeam, NewTeam;
	local XComGameState NewGameState;
	LostUnit = GetClosestUnitToCursor(true, , eTeam_TheLost);
	AssignedTeam = class'XGAIPlayer_TheLost'.static.GetTargetTeamForLostUnit(LostUnit);
	if (AssignedTeam == eTeam_Alien)
	{
		NewTeam = eTeam_XCom;
	}
	else
	{
		NewTeam = eTeam_Alien;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: ToggleLostAssignment");
	class'XGAIPlayer_TheLost'.static.SetTeamAssignment(LostUnit, NewTeam, NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

native function bool NativeUpdateAudioRadius();

exec function UpdateAudioRadius()
{
	if (!NativeUpdateAudioRadius())
	{
		`Redscreen("UpdateAudioRadius(): Must be in editor to display or update audio radii!");
	}
}

exec function ShowUIChosenReveal()
{
	`PRES.UIChosenRevealScreen();
}

/* Example calls: 
UIBannerMessage "LEVEL UP"	neutral		// blue message
UIBannerMessage "SOLDIER WOUNDED" good		// green message
UIBannerMessage "SOLDIER WOUNDED" bad		// red message
UIBannerMessage ""							// animate out
*/

exec function UIBannerMessage(string DisplayString, string Style)
{
	local UITacticalHUDMessageBanner Banner; 
	Banner = `PRES.m_kTacticalHUD.m_kMessageBanner; 

	if( DisplayString == "" )
	{
		Banner.AnimateOut();
	}
	else
	{
		switch( Style )
		{
		case "good":	Banner.SetStyleGood();		break;
		case "bad":		Banner.SetStyleBad();		break;
		case "neutral":	Banner.SetStyleNeutral();	break;
		case "":		Banner.SetStyleNeutral();	break;
		}

		Banner.SetBanner(DisplayString);
	}
}

exec function TestGatherSupplies(int ForceLevel, optional int ChestCount = 8)
{
	local array<string> Chests;

	class'SeqAct_GetGatherSuppliesChests'.static.SelectChests(ForceLevel, ChestCount, Chests);
	class'SeqAct_NotifyRecoveredSupplyChests'.static.RecoverChests(Chests);
}

exec function SetMaxFocus(int MaxFocus)
{
	CheatMaxFocus = MaxFocus;
}

exec function SetFocusLevel(int NewFocus, bool bUseClosestUnitToCursor=false)
{
	local XGUnit ActiveUnit;
	local XComGameState_Unit UnitState;
	local XComGameState_Effect_TemplarFocus FocusEffect;
	local XComGameState NewGameState;

	if (bUseClosestUnitToCursor)
	{
		UnitState = GetClosestUnitToCursor();
	}
	else
	{
		ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.GetVisualizedStateReference().ObjectID));
	}
	if (UnitState == none)
	{
		`log("No active unit state");
		return;
	}
	FocusEffect = UnitState.GetTemplarFocusEffectState();
	if (FocusEffect == none)
	{
		`log("Active unit is not a templar");
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetFocusLevel" @ NewFocus);
	FocusEffect = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusEffect.Class, FocusEffect.ObjectID));
	FocusEffect.SetFocusLevel(NewFocus, UnitState, NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

exec function TestSpawnAcid()
{
	class'SeqAct_FillMapWithAcid'.static.SpawnAcid();
}

exec function ToggleQuickTargetSelect()
{
	bQuickTargetSelectEnabled = !bQuickTargetSelectEnabled;
	`Log("bQuickTargetSelectEnabled =" $ bQuickTargetSelectEnabled);
}


exec function GiveUnitValueToClosestUnit(name UnitValueName, float Value)
{
	local XComGameState_Unit Closest;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Set UnitValue '" $ UnitValueName $ "' on unit");
	Closest = GetClosestUnitToCursor();
	Closest = XComGameState_Unit(NewGameState.ModifyStateObject(Closest.Class, Closest.ObjectID));
	Closest.SetUnitFloatValue(UnitValueName, Value, eCleanup_BeginTactical);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

// tear down all abilities and rebuild fresh - may be some extraneous event triggers left dangling
exec function ResetAbilities()
{
	local XComGameState NewGameState;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference AbilityRef;

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: ResetAbilities");

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		foreach UnitState.Abilities(AbilityRef)
		{
			NewGameState.PurgeGameStateForObjectID(AbilityRef.ObjectID);
		}

		UnitState.Abilities.Length = 0;

		// initialize the abilities for this unit
		TacticalRules.InitializeUnitAbilities(NewGameState, UnitState);
	}

	TacticalRules.SubmitGameState(NewGameState);
}

exec function PrintSoldierKillsInfo()
{
	local XComGameState_Unit UnitState;
	local string KillsInfo;

	KillsInfo = "PrintSoldierKillsInfo could not find valid soldier.";
	UnitState = self.GetClosestUnitToCursor();

	if(UnitState != none)
	{
		KillsInfo = "\n-----------------------------------------\nSOLDIER KILLS INFO:";
		KillsInfo $= "\nTotal Kills:           " $ UnitState.GetTotalNumKills();
		KillsInfo $= "\nUnit Kills:            " $ UnitState.GetNumKills();
		KillsInfo $= "\nUnit Kill Count:       " $ UnitState.KillCount;
		KillsInfo $= "\nKillsFromAssists:      " $ UnitState.GetNumKillsFromAssists();
		KillsInfo $= "\nStarting Rank Kills:   " $ class'X2ExperienceConfig'.static.GetRequiredKills(UnitState.StartingRank);
		KillsInfo $= "\nCovert Action Kills:   " $ UnitState.NonTacticalKills;
		KillsInfo $= "\nDeeper Learning Kills: " $ UnitState.BonusKills;
		KillsInfo $= "\n-----------------------------------------\n";
	}

	`log(KillsInfo);
}

exec function CreateDebugSaveXActionsAgo( int NumActionsIntoPast )
{
	local X2TacticalGameRuleset Ruleset;
	local int HistoryIndex;
	local bool OldAutoSaveEnabled;

	Ruleset = `TACTICALRULES;

	if (NumActionsIntoPast >= Ruleset.VisualizerActivationHistoryFrames.Length)
	{
		ClientMessage( NumActionsIntoPast @ "is too many actions into the past. We can go as many as " @ Ruleset.VisualizerActivationHistoryFrames.Length @ "actions." );
		return;
	}

	HistoryIndex = Ruleset.VisualizerActivationHistoryFrames.Length - 1 - NumActionsIntoPast;
	HistoryIndex = Ruleset.VisualizerActivationHistoryFrames[ HistoryIndex ];

	// Temporarily enable autosaves
	OldAutoSaveEnabled = `XPROFILESETTINGS.Data.m_bAutoSave;
	`XPROFILESETTINGS.Data.m_bAutoSave = true;

	`AUTOSAVEMGR.DoAutosave( , true, , , HistoryIndex );

	`XPROFILESETTINGS.Data.m_bAutoSave = OldAutoSaveEnabled;
}

exec function X2ListEffects()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	
	UnitState = GetClosestUnitToCursor();

	if (UnitState != none)
	{
		History = `XCOMHISTORY;
		`log("Affected by Effects for unit with object ID" @ UnitState.ObjectID);
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState != none)
			{
				`log("Effect" @ EffectState.GetX2Effect().EffectName @ "on state object ID" @ EffectState.ObjectID);
			}
		}
		`log("--end effects--");
	}
}

exec function ShowActiveBehaviorTreeNode()
{
	bShowActiveBTNode = !bShowActiveBTNode;
	`Log(`ShowVar(bShowActiveBTNode));
}

exec function AIShowAoETargetResults()
{
	bShowAoETargetResults = !bShowAoETargetResults;
	`Log(`ShowVar(bShowAoETargetResults));
}

exec function LogSoldierClassTemplateNames()
{
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit UnitIter;
	local XGPlayer HumanPlayer;

	HumanPlayer = XGBattle_SP(`BATTLE).GetHumanPlayer();
	HumanPlayer.GetUnits(Units);

	foreach Units(UnitIter)
	{
		`log(UnitIter.GetName(eNameType_RankFull) @ UnitIter.GetSoldierClassTemplateName());
	}
}

exec function X2MPPrintRulesetWaitingLocations()
{
	local X2TacticalMPGameRuleset MPRuleset;
	local int Idx;

	MPRuleset = X2TacticalMPGameRuleset(`TACTICALRULES);
	for (Idx = MPRuleset.WaitingLocations.Length - 1; Idx >= 0; --Idx)
	{
		`log("   ("$ Idx $") -->" @ MPRuleset.WaitingLocations[Idx]);
	}
}

exec function X2ToggleLadderNarratives( )
{
	`XPROFILESETTINGS.Data.m_bLadderNarrativesOn = !`XPROFILESETTINGS.Data.m_bLadderNarrativesOn;
}

DefaultProperties
{
	bGoldenPathHacks=false
	bCombatLog=false
	bDebugClimbOver=false
	bDebugClimbOnto=false
	bDebugCover=false
	bDebugPOI=false
	bVisualizeMove=false
	iTestHideableActors=1
	bDrawFracturedMeshEffectBoxes = false;

	bForceOverheadView=false
	bThirdPersonAllTheTime=false
	bDebugBeginMoveHang=false
	bShowUnitFlags=true
	bDisableTargetingOutline=false

	iRightSidePos=1600
	bShowShieldHP=false

	m_bEnableBuildingVisibility_Cheat=true
	m_bEnableCutoutBox_Cheat=true
	m_bEnablePeripheryHiding_Cheat = true
	m_bShowPOILocations_Cheat=false
	bEnableProximityDither_Cheat=true
	m_fCutoutBoxSize_Cheat=0
	DebugSpawnIndex=-2
	bAIDisableIntent=true
	bWorldDebugMessagesEnabled=false
	bHideWorldMessagesInOTS = false
}
