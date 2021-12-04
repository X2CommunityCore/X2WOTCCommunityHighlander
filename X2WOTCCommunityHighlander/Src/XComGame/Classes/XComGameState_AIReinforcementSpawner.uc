
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComGameState_AIReinforcementSpawner.uc    
//  AUTHOR:  Dan Kaplan  --  2/16/2015
//  PURPOSE: Holds all state data relevant to a pending spawn of a reinforcement group of AIs.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AIReinforcementSpawner extends XComGameState_BaseObject
	implements(X2VisualizedInterface)
	native(AI);

// The list of unit IDs that were spawned from this spawner
var array<int> SpawnedUnitIDs;

// Tthe type of spawn visulaization to perform on this reinforcements group
var Name SpawnVisualizationType;

// If true, this Reinforcement spawner will not spawn units in LOS of XCom units
var bool bDontSpawnInLOSOfXCOM;

// If true, this Reinforcement spawner will only spawn units in LOS of XCom units
var bool bMustSpawnInLOSOfXCOM;

// If true, this Reinforcement spawner will not spawn units in hazards
var bool bDontSpawnInHazards;

// If true, this Reinforcement spawner will force the resulting group to scamper after spawning even though they may not be in LOS
var bool bForceScamper;

// The SpawnInfo for the group that will be created by this spawner
var PodSpawnInfo SpawnInfo;

// If using an ATT, this is the ref to the ATT unit that is created
var StateObjectReference TroopTransportRef;

// The number of AI turns remaining until the reinforcements are spawned
var int Countdown;

// If true, these reinforcements were initiated from kismet
var bool bKismetInitiatedReinforcements;

// wrappers for the string literals on the spawn's change container contexts. Allows us to easily ensure that 
// the names don't get out of sync from the various systems that need to use them.
var const string SpawnReinforcementsChangeDesc;
var const string SpawnReinforcementsCompleteChangeDesc;

function OnBeginTacticalPlay(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnBeginTacticalPlay(NewGameState);

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'ReinforcementSpawnerCreated', OnReinforcementSpawnerCreated, ELD_OnStateSubmitted, , ThisObj);
	EventManager.TriggerEvent('ReinforcementSpawnerCreated', ThisObj, ThisObj, NewGameState);
}

function OnEndTacticalPlay(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnEndTacticalPlay(NewGameState);

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.UnRegisterFromEvent(ThisObj, 'ReinforcementSpawnerCreated');
	EventManager.UnRegisterFromEvent(ThisObj, 'PlayerTurnBegun');
	EventManager.UnRegisterFromEvent(ThisObj, 'SpawnReinforcementsComplete');
}

// This is called after this reinforcement spawner has finished construction
function EventListenerReturn OnReinforcementSpawnerCreated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_AIReinforcementSpawner NewSpawnerState;
	local X2EventManager EventManager;
	local Object ThisObj;
	local X2CharacterTemplate SelectedTemplate;
	local XComGameState_Player PlayerState;
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionSiteState;
	local XComAISpawnManager SpawnManager;
	local int AlertLevel, ForceLevel;
	local XComGameStateHistory History;
	local Name CharTemplateName;
	local X2CharacterTemplateManager CharTemplateManager;
	// Variables for Issue #278
	local array<X2DownloadableContentInfo> DLCInfos; 
	local int i; 
	// Variables for Issue #278

	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	SpawnManager = `SPAWNMGR;
	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	ForceLevel = BattleData.GetForceLevel();
	AlertLevel = BattleData.GetAlertLevel();

	if( BattleData.m_iMissionID > 0 )
	{
		MissionSiteState = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));

		if( MissionSiteState != None && MissionSiteState.SelectedMissionData.SelectedMissionScheduleName != '' )
		{
			AlertLevel = MissionSiteState.SelectedMissionData.AlertLevel;
			ForceLevel = MissionSiteState.SelectedMissionData.ForceLevel;
		}
	}

	// Select the spawning visualization mechanism and build the persistent in-world visualization for this spawner
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));

	NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.ModifyStateObject(class'XComGameState_AIReinforcementSpawner', ObjectID));

	// choose reinforcement spawn location

	// build a character selection that will work at this location
	SpawnManager.SelectPodAtLocation(NewSpawnerState.SpawnInfo, ForceLevel, AlertLevel, BattleData.ActiveSitReps);

	// Start Issue #278
	//LWS: Added hook to allow post-creation adjustment of instantiated encounter info
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].PostReinforcementCreation(NewSpawnerState.SpawnInfo.EncounterID, NewSpawnerState.SpawnInfo, ForceLevel, AlertLevel, BattleData, self);
	}
	// End Issue #278

	if( NewSpawnerState.SpawnVisualizationType == 'ChosenSpecialNoReveal' ||
	   NewSpawnerState.SpawnVisualizationType == 'ChosenSpecialTopDownReveal' )
	{
		NewSpawnerState.SpawnInfo.bDisableScamper = true;
	}

	// explicitly disabled all timed loot from reinforcement groups
	NewSpawnerState.SpawnInfo.bGroupDoesNotAwardLoot = true;

	// fallback to 'PsiGate' visualization if the requested visualization is using 'ATT' but that cannot be supported
	if( NewSpawnerState.SpawnVisualizationType == 'ATT' )
	{
		// determine if the spawning mechanism will be via ATT or PsiGate
		//  A) ATT requires open sky above the reinforcement location
		//  B) ATT requires that none of the selected units are oversized (and thus don't make sense to be spawning from ATT)
		if( DoesLocationSupportATT(NewSpawnerState.SpawnInfo.SpawnLocation) )
		{
			// determine if we are going to be using psi gates or the ATT based on if the selected templates support it
			foreach NewSpawnerState.SpawnInfo.SelectedCharacterTemplateNames(CharTemplateName)
			{
				SelectedTemplate = CharTemplateManager.FindCharacterTemplate(CharTemplateName);

				if( !SelectedTemplate.bAllowSpawnFromATT )
				{
					NewSpawnerState.SpawnVisualizationType = 'PsiGate';
					break;
				}
			}
		}
		else
		{
			NewSpawnerState.SpawnVisualizationType = 'PsiGate';
		}
	}

	if( NewSpawnerState.SpawnVisualizationType != '' && 
	   NewSpawnerState.SpawnVisualizationType != 'TheLostSwarm' && 
	   NewSpawnerState.SpawnVisualizationType != 'ChosenSpecialNoReveal' &&
	   NewSpawnerState.SpawnVisualizationType != 'ChosenSpecialTopDownReveal' )
	{
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = NewSpawnerState.BuildVisualizationForSpawnerCreation;
		NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);
	}

	`TACTICALRULES.SubmitGameState(NewGameState);

	// no countdown specified, spawn reinforcements immediately
	if( Countdown <= 0 )
	{
		NewSpawnerState.SpawnReinforcements();
	}
	// countdown is active, need to listen for AI Turn Begun in order to tick down the countdown
	else
	{
		EventManager = `XEVENTMGR;
		ThisObj = self;

		PlayerState = class'XComGameState_Player'.static.GetPlayerState(NewSpawnerState.SpawnInfo.Team);
		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnTurnBegun, ELD_OnStateSubmitted, , PlayerState);
	}

	return ELR_NoInterrupt;
}

// TODO: update this function to better consider the space that an ATT requires
private function bool DoesLocationSupportATT(Vector TargetLocation)
{
	local TTile TargetLocationTile;
	local TTile AirCheckTile;
	local VoxelRaytraceCheckResult CheckResult;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

		TargetLocationTile = WorldData.GetTileCoordinatesFromPosition(TargetLocation);
	AirCheckTile = TargetLocationTile;
	AirCheckTile.Z = WorldData.NumZ - 1;

	// the space is free if the raytrace hits nothing
	return (WorldData.VoxelRaytrace_Tiles(TargetLocationTile, AirCheckTile, CheckResult) == false);
}


// This is called at the start of each AI turn
function EventListenerReturn OnTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_AIReinforcementSpawner NewSpawnerState;
	local X2GameRuleset Ruleset;

	Ruleset = `XCOMGAME.GameRuleset;

	if( Countdown > 0 )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UpdateReinforcementCountdown");
		NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.ModifyStateObject(class'XComGameState_AIReinforcementSpawner', ObjectID));
		--NewSpawnerState.Countdown;
		Ruleset.SubmitGameState(NewGameState);

		// we just hit zero? time to spawn reinforcements
		if( NewSpawnerState.Countdown == 0 )
		{
			SpawnReinforcements();
		}
	}

	return ELR_NoInterrupt;
}

function SpawnReinforcements()
{
	local XComGameState NewGameState;
	local XComGameState_AIReinforcementSpawner NewSpawnerState;
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComAISpawnManager SpawnManager;
	local XGAIGroup SpawnedGroup;
	local X2GameRuleset Ruleset;

	EventManager = `XEVENTMGR;
	SpawnManager = `SPAWNMGR;
	Ruleset = `XCOMGAME.GameRuleset;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(default.SpawnReinforcementsChangeDesc);
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForUnitSpawning;

	NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.ModifyStateObject(class'XComGameState_AIReinforcementSpawner', ObjectID));

	// spawn the units
	SpawnedGroup = SpawnManager.SpawnPodAtLocation(
		NewGameState,
		SpawnInfo,
		bMustSpawnInLOSOfXCOM,
		bDontSpawnInLOSOfXCOM,
		bDontSpawnInHazards);

	// clear the ref to this actor to prevent unnecessarily rooting the level
	SpawnInfo.SpawnedPod = None;

	// cache off the spawned unit IDs
	NewSpawnerState.SpawnedUnitIDs = SpawnedGroup.m_arrUnitIDs;

	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'SpawnReinforcementsComplete', OnSpawnReinforcementsComplete, ELD_OnStateSubmitted,, ThisObj);
	EventManager.TriggerEvent('SpawnReinforcementsComplete', ThisObj, ThisObj, NewGameState);

	NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);

	Ruleset.SubmitGameState(NewGameState);
}

// This is called after the reinforcement spawned
function EventListenerReturn OnSpawnReinforcementsComplete(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local array<XComGameState_Unit> AffectedUnits;
	local XComGameState_Unit AffectedUnit;
	local int i;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(default.SpawnReinforcementsCompleteChangeDesc);

	if( SpawnVisualizationType != '' && 
	   SpawnVisualizationType != 'TheLostSwarm' &&
	   SpawnVisualizationType != 'ChosenSpecialNoReveal' &&
	   SpawnVisualizationType != 'ChosenSpecialTopDownReveal' )
	{
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForSpawnerDestruction;
	}

	for( i = 0; i < SpawnedUnitIDs.Length; ++i )
	{
		AffectedUnits.AddItem(XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnitIDs[i])));

		if( SpawnVisualizationType == 'ChosenSpecialNoReveal' ||
		   SpawnVisualizationType == 'ChosenSpecialTopDownReveal' )
		{
			AffectedUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', SpawnedUnitIDs[i]));
			AffectedUnit.bTriggerRevealAI = true;
		}
	}

	// if there was an ATT, remove it now
	if( TroopTransportRef.ObjectID > 0 )
	{
		NewGameState.RemoveStateObject(TroopTransportRef.ObjectID);
	}

	// remove this state object, now that we are done with it
	NewGameState.RemoveStateObject(ObjectID);

	NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);

	AlertAndScamperUnits(NewGameState, AffectedUnits, bForceScamper, GameState.HistoryIndex, SpawnVisualizationType);

	return ELR_NoInterrupt;
}

static function AlertAndScamperUnits(XComGameState NewGameState, out array<XComGameState_Unit> AffectedUnits, bool bMustScamper, int HistoryIndex, optional name InSpawnVisualizationType)
{
	local XComWorldData World;
	local XComGameState_Unit ReinforcementUnit, InstigatingUnit;
	local XComGameState_AIUnitData NewAIUnitData;
	local int i;
	local AlertAbilityInfo AlertInfo;
	local XComGameStateHistory History;
	local XComAISpawnManager SpawnManager;
	local Vector PingLocation;
	local array<StateObjectReference> VisibleUnits;
	local XComGameState_AIGroup AIGroupState;
	local bool bDataChanged;
	local XGAIGroup Group;

	World = `XWORLD;
		History = `XCOMHISTORY;
		SpawnManager = `SPAWNMGR;

	PingLocation = SpawnManager.GetCurrentXComLocation();
	AlertInfo.AlertTileLocation = World.GetTileCoordinatesFromPosition(PingLocation);
	AlertInfo.AlertRadius = 500;
	AlertInfo.AlertUnitSourceID = 0;
	AlertInfo.AnalyzingHistoryIndex = HistoryIndex;

	// update the alert pings on all the spawned units
	for( i = 0; i < AffectedUnits.Length; ++i )
	{
		bDataChanged = false;
		ReinforcementUnit = AffectedUnits[i];

		if( !bMustScamper )
		{
			class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(ReinforcementUnit.ObjectID, VisibleUnits, class'X2TacticalVisibilityHelpers'.default.GameplayVisibleFilter);
		}

		if( ReinforcementUnit.GetAIUnitDataID() < 0 )
		{
			NewAIUnitData = XComGameState_AIUnitData(NewGameState.CreateNewStateObject(class'XComGameState_AIUnitData'));
		}
		else
		{
			NewAIUnitData = XComGameState_AIUnitData(NewGameState.ModifyStateObject(class'XComGameState_AIUnitData', ReinforcementUnit.GetAIUnitDataID()));
		}

		if( NewAIUnitData.m_iUnitObjectID != ReinforcementUnit.ObjectID )
		{
			NewAIUnitData.Init(ReinforcementUnit.ObjectID);
			bDataChanged = true;
		}
		if( NewAIUnitData.AddAlertData(ReinforcementUnit.ObjectID, eAC_MapwideAlert_Hostile, AlertInfo, NewGameState) )
		{
			bDataChanged = true;
		}

		if( !bDataChanged )
		{
			NewGameState.PurgeGameStateForObjectID(NewAIUnitData.ObjectID);
		}
	}

	`TACTICALRULES.SubmitGameState(NewGameState);

	if( bMustScamper /*&& VisibleUnits.Length == 0*/ )
	{
		foreach History.IterateByClassType(class'XComGameState_Unit', InstigatingUnit)
		{
			if( InstigatingUnit.GetTeam() == eTeam_XCom && InstigatingUnit.IsAlive() )
			{
				AIGroupState = ReinforcementUnit.GetGroupMembership();
				AIGroupState.InitiateReflexMoveActivate(InstigatingUnit, eAC_MapwideAlert_Hostile, InSpawnVisualizationType);
				break;
			}
		}
	}
	else if( VisibleUnits.Length > 0 )
	{
		InstigatingUnit = XComGameState_Unit(History.GetGameStateForObjectID(VisibleUnits[0].ObjectID));
		AIGroupState = ReinforcementUnit.GetGroupMembership();
		AIGroupState.InitiateReflexMoveActivate(InstigatingUnit, eAC_SeesSpottedUnit, InSpawnVisualizationType);
	}
	else
	{
		// If this group isn't starting out scampering, we need to initialize the group turn so it can move properly.
		XGAIPlayer(`BATTLE.GetAIPlayer()).m_kNav.GetGroupInfo(AffectedUnits[0].ObjectID, Group);
		Group.InitTurn();
	}
}

function BuildVisualizationForUnitSpawning(XComGameState VisualizeGameState)
{
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local XComGameState_Unit SpawnedUnit;
	local TTile SpawnedUnitTile;
	local int i;
	local VisualizationActionMetadata ActionMetadata, EmptyBuildTrack;
	local X2Action_PlayAnimation SpawnEffectAnimation;
	local X2Action_PlayEffect SpawnEffectAction;
	local XComWorldData World;
	local XComContentManager ContentManager;
	local XComGameStateHistory History;
	local X2Action_ShowSpawnedUnit ShowSpawnedUnitAction;
	local X2Action_ATT ATTAction;
	local float ShowSpawnedUnitActionTimeout;
	local X2Action_Delay RandomDelay;
	local X2Action_MarkerNamed SyncAction;
	local XComGameStateContext Context;
	local float OffsetVisDuration;
	local X2Action_CameraLookAt LookAtAction;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local array<X2Action>					LeafNodes;

	OffsetVisDuration = 0.0;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;
	ContentManager = `CONTENT;
	World = `XWORLD;
	AISpawnerState = XComGameState_AIReinforcementSpawner(VisualizeGameState.GetGameStateForObjectID(ObjectID));

	Context = VisualizeGameState.GetContext();
	ActionMetadata.StateObject_OldState = AISpawnerState;
	ActionMetadata.StateObject_NewState = AISpawnerState;

	if( AISpawnerState.SpawnVisualizationType != 'TheLostSwarm' )
	{
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		LookAtAction.LookAtLocation = AISpawnerState.SpawnInfo.SpawnLocation;
		LookAtAction.BlockUntilActorOnScreen = true;
		LookAtAction.LookAtDuration = -1.0;
		LookAtAction.CameraTag = 'ReinforcementSpawningCamera';
	}

	ShowSpawnedUnitActionTimeout = 10.0f;
	if (AISpawnerState.SpawnVisualizationType == 'ATT' )
	{
		ATTAction = X2Action_ATT(class'X2Action_ATT'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		ShowSpawnedUnitActionTimeout = ATTAction.TimeoutSeconds;
	}

	if( AISpawnerState.SpawnVisualizationType == 'Dropdown' )
	{
		SpawnEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		SpawnEffectAction.EffectName = ContentManager.ReinforcementDropdownWarningEffectPathName;
		SpawnEffectAction.EffectLocation = AISpawnerState.SpawnInfo.SpawnLocation;
		SpawnEffectAction.bStopEffect = true;
	}

	SyncAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SyncAction.SetName("SpawningStart");

	for( i = AISpawnerState.SpawnedUnitIDs.Length - 1; i >= 0; --i )
	{
		SpawnedUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AISpawnerState.SpawnedUnitIDs[i]));

		if( SpawnedUnit.GetVisualizer() == none )
		{
			SpawnedUnit.FindOrCreateVisualizer();
			SpawnedUnit.SyncVisualizer();

			//Make sure they're hidden until ShowSpawnedUnit makes them visible (SyncVisualizer unhides them)
			XGUnit(SpawnedUnit.GetVisualizer()).m_bForceHidden = true;
		}

		if( AISpawnerState.SpawnVisualizationType != 'TheLostSwarm' )
		{
			ActionMetadata = EmptyBuildTrack;
			ActionMetadata.StateObject_OldState = SpawnedUnit;
			ActionMetadata.StateObject_NewState = SpawnedUnit;
			ActionMetadata.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

			// if multiple units are spawning, apply small random delays between each
			if( i > 0 )
			{
				RandomDelay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, SyncAction));
				OffsetVisDuration += `SYNC_FRAND() * 0.5f;
				RandomDelay.Duration = OffsetVisDuration;
			}

			if( (SpawnVisualizationType != 'Dropdown') && (SpawnVisualizationType != '') )
			{
				ShowSpawnedUnitAction = X2Action_ShowSpawnedUnit(class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				ShowSpawnedUnitAction.ChangeTimeoutLength(ShowSpawnedUnitActionTimeout + ShowSpawnedUnitAction.TimeoutSeconds);
			}

			// if spawning from PsiGates, need a warp in effect to play at each of the unit spawn locations
			if( SpawnVisualizationType == 'PsiGate' )
			{
				SpawnedUnit.GetKeystoneVisibilityLocation(SpawnedUnitTile);

				SpawnEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				SpawnEffectAction.EffectName = ContentManager.PsiWarpInEffectPathName;
				SpawnEffectAction.EffectLocation = World.GetPositionFromTileCoordinates(SpawnedUnitTile);
				SpawnEffectAction.bStopEffect = false;

				SpawnEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				SpawnEffectAction.EffectName = ContentManager.PsiGateEffectPathName;
				SpawnEffectAction.EffectLocation = World.GetPositionFromTileCoordinates(SpawnedUnitTile);
				SpawnEffectAction.bStopEffect = true;

				if( AISpawnerState.SpawnInfo.EncounterID == 'LoneCodex' || AISpawnerState.SpawnInfo.EncounterID == 'LoneAvatar' )
				{
					SpawnEffectAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
					SpawnEffectAnimation.Params.AnimName = 'HL_TeleportStop';
				}
			}

			// if spawning from PsiGates, need a warp in effect to play at each of the unit spawn locations
			if( SpawnVisualizationType == 'Dropdown' )
			{
				SpawnedUnit.GetKeystoneVisibilityLocation(SpawnedUnitTile);

				SpawnEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				SpawnEffectAction.EffectName = ContentManager.ReinforcementDropdownEffectPathName;
				SpawnEffectAction.EffectLocation = World.GetPositionFromTileCoordinates(SpawnedUnitTile);
				SpawnEffectAction.bStopEffect = false;

				RandomDelay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				RandomDelay.Duration = 1.0f;

				ShowSpawnedUnitAction = X2Action_ShowSpawnedUnit(class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				ShowSpawnedUnitAction.ChangeTimeoutLength(ShowSpawnedUnitActionTimeout + ShowSpawnedUnitAction.TimeoutSeconds);

				SpawnEffectAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				SpawnEffectAnimation.Params.AnimName = 'MV_ClimbDropHigh_StartA';
				SpawnEffectAnimation.Params.BlendTime = 0.0f;
				SpawnEffectAnimation.bFinishAnimationWait = true;
				SpawnEffectAnimation.bOffsetRMA = true;

				SpawnEffectAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, SpawnEffectAnimation));
				SpawnEffectAnimation.Params.AnimName = 'MV_ClimbDropHigh_StopA';
				SpawnEffectAnimation.bFinishAnimationWait = true;
				SpawnEffectAnimation.bOffsetRMA = true;
			}

			if( SpawnVisualizationType == 'ChosenSpecialTopDownReveal' )
			{
				SpawnedUnit.GetKeystoneVisibilityLocation(SpawnedUnitTile);

				SpawnEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				SpawnEffectAction.EffectName = ContentManager.ChosenTeleportInEffectPathName;
				SpawnEffectAction.EffectLocation = World.GetPositionFromTileCoordinates(SpawnedUnitTile);
				SpawnEffectAction.bStopEffect = false;

				SpawnEffectAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
				SpawnEffectAnimation.Params.AnimName = 'HL_TeleportStop';
			}
		}
	}

	//Add a join so that all hit reactions and other actions will complete before the visualization sequence moves on. In the case
	// of fire but no enter cover then we need to make sure to wait for the fire since it isn't a leaf node
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, none, LeafNodes));
	LookAtAction.CameraTag = 'ReinforcementSpawningCamera';
	LookAtAction.bRemoveTaggedCamera = true;
}

function BuildVisualizationForSpawnerCreation(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local X2Action_PlayEffect ReinforcementSpawnerEffectAction;
	local X2Action_RevealArea RevealAreaAction;
	local XComContentManager ContentManager;
	local XComGameState_Unit UnitIterator;
	local XGUnit TempXGUnit;
	local bool bUnitHasSpokenVeryRecently;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	ContentManager = `CONTENT;
	History = `XCOMHISTORY;
	AISpawnerState = XComGameState_AIReinforcementSpawner(History.GetGameStateForObjectID(ObjectID));

	if (!TriggerOverrideDisableReinforcementsFlare(AISpawnerState))  // Issue #448: added this condition
	{
		RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		RevealAreaAction.TargetLocation = AISpawnerState.SpawnInfo.SpawnLocation;
		RevealAreaAction.AssociatedObjectID = ObjectID;
		RevealAreaAction.bDestroyViewer = false;

		ReinforcementSpawnerEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

		if( SpawnVisualizationType == 'PsiGate' )
		{
			ReinforcementSpawnerEffectAction.EffectName = ContentManager.PsiGateEffectPathName;
		}
		else if( SpawnVisualizationType == 'ATT' )
		{
			ReinforcementSpawnerEffectAction.EffectName = ContentManager.ATTFlareEffectPathName;
		}
		else if( SpawnVisualizationType == 'Dropdown' )
		{
			ReinforcementSpawnerEffectAction.EffectName = ContentManager.ReinforcementDropdownWarningEffectPathName;
		}

		ReinforcementSpawnerEffectAction.EffectLocation = AISpawnerState.SpawnInfo.SpawnLocation;
		ReinforcementSpawnerEffectAction.CenterCameraOnEffectDuration = ContentManager.LookAtCamDuration;
		ReinforcementSpawnerEffectAction.bStopEffect = false;

		ActionMetadata.StateObject_OldState = AISpawnerState;
		ActionMetadata.StateObject_NewState = AISpawnerState;
	}

	// Add a track to one of the x-com soldiers, to say a line of VO (e.g. "Alien reinforcements inbound!").
	foreach History.IterateByClassType( class'XComGameState_Unit', UnitIterator )
	{
		TempXGUnit = XGUnit(UnitIterator.GetVisualizer());
		bUnitHasSpokenVeryRecently = ( TempXGUnit != none && TempXGUnit.m_fTimeSinceLastUnitSpeak < 3.0f );

		if (UnitIterator.GetTeam() == eTeam_XCom && !bUnitHasSpokenVeryRecently && !AISpawnerState.SpawnInfo.SkipSoldierVO)
		{
			ActionMetadata = EmptyTrack;
			ActionMetadata.StateObject_OldState = UnitIterator;
			ActionMetadata.StateObject_NewState = UnitIterator;
			ActionMetadata.VisualizeActor = UnitIterator.GetVisualizer();

			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(none, "", 'AlienReinforcements', eColor_Bad);

			break;
		}
	}

}

// Start Issue #448
/// HL-Docs: feature:OverrideDisableReinforcementsFlare; issue:448; tags:tactical
/// The `OverrideDisableReinforcementsFlare` event allows mods to disable the visuals
/// for the particle effects (red flare or purple psionic gate in base game)
/// that indicate the location of incoming enemy reinforcements,
/// as well as other visualization associated with it, such as camera panning.
///
/// Returns `true` if the reinforcements flare should be disabled.
///
///```event
/// EventID: OverrideDisableReinforcementsFlare,
/// EventData: [inout bool bDisableFlare],
/// EventSource: XComGameState_AIReinforcementSpawner (AISpawnerState),
/// NewGameState: none
///```
private function bool TriggerOverrideDisableReinforcementsFlare(XComGameState_AIReinforcementSpawner AISpawnerState)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideDisableReinforcementsFlare';
	OverrideTuple.Data.Add(1);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;  // Default to *not* disabling the flare (vanilla WOTC behavior)

	`XEVENTMGR.TriggerEvent(OverrideTuple.Id, OverrideTuple, AISpawnerState);

	return OverrideTuple.Data[0].b;
}
// End Issue #448

function BuildVisualizationForSpawnerDestruction(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local X2Action_PlayEffect ReinforcementSpawnerEffectAction;
	local X2Action_RevealArea RevealAreaAction;
	local XComContentManager ContentManager;

	ContentManager = `CONTENT;
	History = `XCOMHISTORY;
	AISpawnerState = XComGameState_AIReinforcementSpawner(History.GetGameStateForObjectID(ObjectID));

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	RevealAreaAction.AssociatedObjectID = ObjectID;
	RevealAreaAction.bDestroyViewer = true;

	ReinforcementSpawnerEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

	if( SpawnVisualizationType == 'PsiGate' )
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.PsiGateEffectPathName;
	}
	else if( SpawnVisualizationType == 'ATT' )
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.ATTFlareEffectPathName;
	}
	else if (SpawnVisualizationType == 'Dropdown')
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.ReinforcementDropdownWarningEffectPathName;
	}

	ReinforcementSpawnerEffectAction.EffectLocation = AISpawnerState.SpawnInfo.SpawnLocation;
	ReinforcementSpawnerEffectAction.bStopEffect = true;

	ActionMetadata.StateObject_OldState = AISpawnerState;
	ActionMetadata.StateObject_NewState = AISpawnerState;
	}


static function bool InitiateReinforcements(
	Name EncounterID, 
	optional int OverrideCountdown = -1, 
	optional bool OverrideTargetLocation,
	optional const out Vector TargetLocationOverride,
	optional int IdealSpawnTilesOffset,
	optional XComGameState IncomingGameState,
	optional bool InKismetInitiatedReinforcements,
	optional Name InSpawnVisualizationType = 'ATT',
	optional bool InDontSpawnInLOSOfXCOM,
	optional bool InMustSpawnInLOSOfXCOM,
	optional bool InDontSpawnInHazards,
	optional bool InForceScamper,
	optional bool bAlwaysOrientAlongLOP, 
	optional bool bIgnoreUnitCap)
{
	local XComGameState_AIReinforcementSpawner NewAIReinforcementSpawnerState;
	local XComGameState NewGameState;
	local XComTacticalMissionManager MissionManager;
	local ConfigurableEncounter Encounter;
	local XComAISpawnManager SpawnManager;
	local Vector DesiredSpawnLocation;

	if( !bIgnoreUnitCap && LivingUnitCapReached(InSpawnVisualizationType == 'TheLostSwarm') )
	{
		return false;
	}

	SpawnManager = `SPAWNMGR;

	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.GetConfigurableEncounter(EncounterID, Encounter);

	if (IncomingGameState == none)
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Creating Reinforcement Spawner");
	else
		NewGameState = IncomingGameState;

	// Update AIPlayerData with CallReinforcements data.
	NewAIReinforcementSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.CreateNewStateObject(class'XComGameState_AIReinforcementSpawner'));
	NewAIReinforcementSpawnerState.SpawnInfo.EncounterID = EncounterID;

	NewAIReinforcementSpawnerState.SpawnVisualizationType = InSpawnVisualizationType;
	NewAIReinforcementSpawnerState.bDontSpawnInLOSOfXCOM = InDontSpawnInLOSOfXCOM;
	NewAIReinforcementSpawnerState.bMustSpawnInLOSOfXCOM = InMustSpawnInLOSOfXCOM;
	NewAIReinforcementSpawnerState.bDontSpawnInHazards = InDontSpawnInHazards;
	NewAIReinforcementSpawnerState.bForceScamper = InForceScamper;

	if( OverrideCountdown >= 0 )
	{
		NewAIReinforcementSpawnerState.Countdown = OverrideCountdown;
	}
	else
	{
		NewAIReinforcementSpawnerState.Countdown = Encounter.ReinforcementCountdown;
	}

	if( OverrideTargetLocation )
	{
		DesiredSpawnLocation = TargetLocationOverride;
	}
	else
	{
		DesiredSpawnLocation = SpawnManager.GetCurrentXComLocation();
	}

	NewAIReinforcementSpawnerState.SpawnInfo.SpawnLocation = SpawnManager.SelectReinforcementsLocation(
		NewAIReinforcementSpawnerState, 
		DesiredSpawnLocation, 
		IdealSpawnTilesOffset, 
		InMustSpawnInLOSOfXCOM,
		InDontSpawnInLOSOfXCOM,
		InSpawnVisualizationType == 'ATT',
		bAlwaysOrientAlongLOP); // ATT vis type requires vertical clearance at the spawn location

	NewAIReinforcementSpawnerState.bKismetInitiatedReinforcements = InKismetInitiatedReinforcements;

	if (IncomingGameState == none)
		`TACTICALRULES.SubmitGameState(NewGameState);

	return true;
}

// When called, the visualized object must create it's visualizer if needed, 
function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	return none;
}

// Ensure that the visualizer visual state is an accurate reflection of the state of this object.
function SyncVisualizer( optional XComGameState GameState = none )
{
}

function AppendAdditionalSyncActions( out VisualizationActionMetadata ActionMetadata, const XComGameStateContext Context)
{
	local XComContentManager ContentManager;
	local X2Action_PlayEffect ReinforcementSpawnerEffectAction;
	local X2Action_RevealArea RevealAreaAction;

	if (Countdown <= 0)
	{
		return; // we've completed the reinforcement and the effect was stopped
	}

	// Start Issue #1097
	// This fixes the issue where reinforcement flares were still visible when
	// loading a save.
	if (TriggerOverrideDisableReinforcementsFlare(self))
	{
		return;
	}
	// End Issue #1097

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, GetParentGameState().GetContext() ) );
	RevealAreaAction.TargetLocation = SpawnInfo.SpawnLocation;
	RevealAreaAction.AssociatedObjectID = ObjectID;
	RevealAreaAction.bDestroyViewer = false;

	ContentManager = `CONTENT;

	ReinforcementSpawnerEffectAction = X2Action_PlayEffect( class'X2Action_PlayEffect'.static.AddToVisualizationTree( ActionMetadata, GetParentGameState().GetContext() ) );

	if( SpawnVisualizationType == 'PsiGate' )
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.PsiGateEffectPathName;
	}
	else if( SpawnVisualizationType == 'ATT' )
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.ATTFlareEffectPathName;
	}
	else if (SpawnVisualizationType == 'Dropdown')
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.ReinforcementDropdownWarningEffectPathName;
	}

	ReinforcementSpawnerEffectAction.EffectLocation = SpawnInfo.SpawnLocation;
	ReinforcementSpawnerEffectAction.CenterCameraOnEffectDuration = 0;
	ReinforcementSpawnerEffectAction.bStopEffect = false;
}

static function bool LivingUnitCapReached(bool bOnlyConsiderTheLost)
{
	local XComGameStateHistory History;
	local XComGameState_Unit kUnitState;
	local int LivingUnitCount;

	LivingUnitCount = 0;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', kUnitState)
	{
		if( kUnitState.IsAlive() && !kUnitState.bRemovedFromPlay )
		{
			if( !bOnlyConsiderTheLost || kUnitState.GetTeam() == eTeam_TheLost )
			{
			++LivingUnitCount;
		}
	}
	}

	if( bOnlyConsiderTheLost )
	{
		return LivingUnitCount >= class'XComAISpawnManager'.default.LostUnitCap;  // max lost units permitted to be alive at one time; can only spawn additional lost if below this number
	}

	return LivingUnitCount >= class'XComAISpawnManager'.default.UnitCap;
}


cpptext
{
	// UObject interface
	virtual void Serialize(FArchive& Ar);
}

defaultproperties
{
	bTacticalTransient=true
	SpawnReinforcementsChangeDesc="SpawnReinforcements"
	SpawnReinforcementsCompleteChangeDesc="OnSpawnReinforcementsComplete"
	Countdown = -1
	SpawnVisualizationType="ATT"
}

