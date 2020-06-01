//---------------------------------------------------------------------------------------
//  FILE:    XComPathingPawn.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Common interface for showing and building the pathing line that the user uses to select
//           a unit's destination.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComPathingPawn extends XComUnitPawnNativeBase
	native(Unit)
	config(GameCore);	

const PATH_SEGMENT_DISTANCE = 64;

var TTile LastCursorTile;
var Vector LastEndPoint;
var bool bMoved;
var int iFramesSinceMoved;    // number of frames since the cursor moved
var int iFramesSinceNotMoved; // number of frames since the cursor did not move
var vector LastCursorLocation;
var float fPuckMeshCircleOpacity; // opacity of the circular puck mesh
struct native HazardMarker
{
	var TTile Tile;     // the tile the marker sits on
	var array<name> HazardEffectNames; // the hazards effects that were entered on this tile

	structcpptext
	{
		FHazardMarker()
		{
			appMemzero(this, sizeof(FHazardMarker));
		}

		FHazardMarker(EEventParm)
		{
			appMemzero(this, sizeof(FHazardMarker));
		}
	}
};

struct native HazardousTilesCache
{
	// The tiles which break concealment
	var array<TTile> Tiles;
	var array<float> OpacityPerTile;

	// The ObjectID of the pawn for which this cache is relevent
	var int ActivePawnID;

	// True only if this cache is current with the existing game state
	var bool CacheIsCurrent;
	structcpptext
	{
		FHazardousTilesCache()
		{
			appMemzero(this, sizeof(FHazardousTilesCache));
		}

		FHazardousTilesCache(EEventParm)
		{
			appMemzero(this, sizeof(FHazardousTilesCache));
		}
	}
};

// Helper structure to associate a tile and cost to a waypoint
struct native WaypointTile
{
	var TTile Tile; // the tile this waypoint lies on
	var float Cost; // total cost to this waypoint
};

// ids for the world messages that pop up on the puck when the unit is dashing or suppressed
var private string DashLabel;
var private string SuppressedLabel;

// Map of active unit ObjectIDs to cached concealment info
var private{private} native Map_Mirror ConcealmentCache{TMap<INT, FHazardousTilesCache>};

// config values
var private const config string PuckMeshName; // name of the default pathing puck mesh
var private const config string PuckMeshCircleName; // name of the cursor mesh (blue)
var private const config string HeightCylinderName; // name of the height cylinder mesh
var private const config string PuckMeshCircleDashingName; // name of the cursor mesh, if it's in dashing range (yellow)
var private const config string PuckMeshConfirmedName; // name of the mesh that animates out when a move is confirmed
var private const config string PuckMeshDashingName; // name of the mesh that is swapped for the default when the unit will dash (or use their remaining action point)
var private const config string PuckMeshConfirmedDashingName; // same as PuckMeshConfirmedName, but for the dashing case
var private const config string PuckMeshSlashingName; // puck that highlights a targeted unit
var private const config string PuckMeshConfirmedSlashingName; // puck that animates out when a melee attack is confirmed
var private const config string PuckMeshOutOfRangeName; // puck that displays when the cursor is outside of pathing range
var private const config string PuckMeshUnitSelectName; // mesh to use when hovering over a selectable unit
var private const config string PuckMeshEnemySelectName; // mesh to use when hovering over a selectable enemy

var private const config string DefaultPuckMeshMeleePath; // mesh to use for the melee puck if there is no ability override

var private const config name NoiseMarkerIconName; // See X2WaypointStaticMeshComponent::HazardMarkerDefinitions
var private const config name ConcealmentMarkerIconName; // See X2WaypointStaticMeshComponent::HazardMarkerDefinitions
var private const config name LaserScopeMarkerIconName; // See X2WaypointStaticMeshComponent::HazardMarkerDefinitions
var private const config name KillZoneMarkerIconName; // See X2WaypointStaticMeshComponent::HazardMarkerDefinitions

var private const config string PathMaterialNormalName; // material for the ribbon that traces the movement path
var private const config string PathMaterialDashingName; // material for the ribbon that traces the movement path when dashing

var private const config string ConcealmentTilesVisibleMeshName; // mesh used when the concealment tiles are visible (to animate in)
var private const config string ConcealmentTilesHiddenMeshName; // mesh used when the concealment tiles are hidden (to animate out)

var private const config string ConcealmentBreakTilesVisibleMeshName; // mesh used when concealment break tiles are visible (to animate in)
var private const config string ConcealmentBreakTilesHiddenMeshName; // mesh used when concealment break tiles are hidden (to animate out)

var private const config bool ShowObjectiveTiles; // allows the objective tiles to be turned on and off with an ini switch
var private const config string ObjectiveTilesVisibleMeshName; // mesh used when the concealment tiles are visible (to animate in)
var private const config string ObjectiveTilesHiddenMeshName; // mesh used when the concealment tiles are hidden (to animate out)

var private const config string BondmateTilesVisibleMeshName; // mesh used when bondmate tiles are visible (to animate in)
var private const config string BondmateTilesHiddenMeshName; // mesh used when bondmate tiles are hidden (to animate out)

var private const config string ReviveTilesVisibleMeshName; // mesh used when bondmate tiles are visible (to animate in)
var private const config string ReviveTilesHiddenMeshName; // mesh used when bondmate tiles are hidden (to animate out)

var private const config string HuntersMarkTilesVisibleMeshName; // mesh used when HuntersMark tiles are visible (to animate in)
var private const config string HuntersMarkTilesHiddenMeshName; // mesh used when HuntersMark tiles are hidden (to animate out)

var private const config bool ShowSummaryMarker; // if true, collates all noise and hazards markers into a summary marker at the end of the path
var private const config bool ShowLOSPreview; // if true, updates enemy unit flags to show which units are visible from the pathing destination
var private const config bool ShowDashingLabel; // if true, will show the "Dashing!" label
var private const config bool ShowSuppressedLabel; // if true, will show the "Suppressed!" label

var private      const config int   PathLengthOffset;        // allows the path to be shortened to match breadcrumb
var privatewrite const config float PathHeightOffset;     // height above the ground to draw the ribbon and puck

var private const config linearcolor DashingBorderColor;
var private const config linearcolor NonDashingBorderColor;

var private XGUnitNativeBase LastActiveUnit; // the last unit to be active on this pawn
var protected X2ReachableTilesCache ActiveCache; // allows us to switch to a waypoint cache when placing waypoints
var private bool WaypointModifyMode; // toggle set by ui to show waypoint add/remove markers. doesn't change behavior, just looks
var private bool ForceUpdateNextTick; // set to true if some operation requires the path to update (waypoint added or removed, etc)

var privatewrite transient XComPath VisualPath; // the pulled path that traces the path tiles
var privatewrite array<TTile> PathTiles;    // the actual tiles the unit will traverse if the move is confirmed
var protectedwrite transient TTile LastDestinationTile; // the last tile the path would end at. can be different from LastCursorTile if the cursor is on an invalid tile

var privatewrite transient XComGameState_BaseObject LastTargetObject; // Last actor the cursor was over, allows us to path info on change in target
var private				   bool					WasDashing;
var private				   bool					WasInWarningZone;

var private				   bool					bConcealmentTilesNeedUpdate;

var private InterpCurveVector kSplineInfo; // the spline used to smooth out the path visuals

// puck status meshs. see the config variables for each for a description
var protected StaticMesh PuckMeshNormal; 
var protected StaticMesh PuckMeshCircle;          // cursor mesh (blue)
var protected StaticMesh PuckMeshCircleDashing;   // dashing cursor mesh (yellow)
var protected StaticMesh PuckMeshDashing;
var protected StaticMesh PuckMeshConfirmed;
var protected StaticMesh PuckMeshConfirmedDashing;
var protected StaticMesh PuckMeshSlashing; // the direction indicator for slashing attacks
var protected StaticMesh PuckMeshConfirmedSlashing; // confirmed direction indicator for slashing attack
var protected StaticMesh PuckMeshOutOfRange;
var protected StaticMesh PuckMeshUnitSelect;
var protected StaticMesh PuckMeshEnemySelect;

var protected StaticMesh PuckMeshMelee; // the ability specific melee mesh to show when hovering over a target

var protected MaterialInterface PathMaterialNormal;
var protected MaterialInterface PathMaterialDashing;

// Component for rendering the concealment markup tiles
var private X2FadingInstancedStaticMeshComponent ConcealmentRenderingComponent;

// Component for rendering the special concealment-breaking-path when concealment is broken
var private X2FadingInstancedStaticMeshComponent ConcealmentBreakRenderingComponent;

// Component for rendering the objective interaction tile markup
var private X2FadingInstancedStaticMeshComponent ObjectiveTilesRenderingComponent;

// Bondmate tile markup component
var private X2FadingInstancedStaticMeshComponent BondmateTilesRenderingComponent;

// Bondmate tile markup component
var private X2FadingInstancedStaticMeshComponent ReviveTilesRenderingComponent;

// Hunter's mark tile markup component
var private X2FadingInstancedStaticMeshComponent HuntersMarkTilesRenderingComponent;


// puck mesh components
var protected X2FadingStaticMeshComponent PuckMeshComponent; // mesh that shows at LastDestinationTile, for the normal movement puck
var protected X2FadingStaticMeshComponent PuckMeshCircleComponent; // cursor fading static mesh component
var protected X2FadingStaticMeshComponent SlashingMeshComponent; // mesh that shows when targeting a unit with the melee path targeting
var protected StaticMeshComponent OutOfRangeMeshComponent; // mesh that shows when LastCursorTile does not match LastDestinationTile

var protected PointLightComponent PuckLightComponent;

// waypoint stuff
var privatewrite array<WaypointTile>			    Waypoints; // all tiles with a waypoint on them
var private array<X2WaypointStaticMeshComponent>    WaypointMeshPool; // pool to prevent needless waypoint allocations
var private array<TTile>						    WaypointsPath; // path from the unit to the last waypoint, cached
var private array<HazardMarker>					    HazardMarkers; // all tiles with a hazard on them
var private array<TTile>					    	NoiseMarkers; // all tiles with a noise marker on them
var private array<TTile>						    ConcealmentMarkers; // all tiles with a concealment marker on them
var private array<TTile>							LaserScopeMarkers; // End path tiles with a laser scope visible to them.
var private array<TTile>							KillZoneMarkers; // All tiles in path with killzone markers on them.


// renderable path
var protected XComRenderablePathComponent RenderablePath; // component that draws the path ribbon from the unit to the puck
var private array<GameplayTileData> PathTileData; // gameplay friendly extra info about the path

// switch for derived classes
var protected bool AllowSelectionOfActiveUnitTile; // if true, allows the puck to target the tile the unit is currently on

var int ActiveKillZoneAbilityID;					// If > 0, mark cursor upon entering / exiting killzone tiles.

native function protected BuildSpline();
native function protected MarkConcealmentCacheDirty(int UnitID);
native function MarkAllConcealmentCachesDirty(); // Need this non-private for replay/tutorial purposes
native function UpdateConcealmentMarkers();
native function UpdateConcealmentTiles();
native function UpdateLaserScopeMarkers();
native function UpdateKillZoneMarkers(XComGameState_Unit ActiveUnitState);
native function UpdateObjectiveTiles(XComGameState_Unit ActiveUnitState);
native function UpdateBondmateTiles(XComGameState_Unit ActiveUnitState);
native function UpdateReviveTiles(XComGameState_Unit ActiveUnitState);
native function UpdateHuntersMarkTiles(XComGameState_Unit ActiveUnitState);
native function protected UpdateConcealmentBreakingMarkerInfo();
native function protected UpdateHazardTileMarkerInfo();
native function protected UpdateHazardMarkerInfo(XComGameState_Unit ActiveUnitState);
native function protected UpdateNoiseMarkerInfo(XComGameState_Unit ActiveUnitState);
native function protected UpdatePathMarkers();
native function protected SetupPathMarker(X2WaypointStaticMeshComponent MarkerComponent, const out TTile Tile);
native function protected UpdateRenderablePath(vector CameraLocation);

native function DebugPathing();

native function public UpdateTileCacheVisuals(optional bool bGrappleMove = false);
native function public UpdateSpecialTileCacheVisuals(array<TTile> TargetTiles);

simulated function UpdateConcealmentTilesVisibility(optional bool ForceHidden = false)
{
	local X2TacticalGameRuleset Rules;
	local bool ShouldFadeOut;
	
	if(ForceHidden)
	{
		// only time we hard hide (without a fadeout) is when we are forced hidden
		ConcealmentRenderingComponent.SetHidden(true);
	}
	else
	{
		// if we aren't forcing the tiles to be hidden, fade them out if the human player is not
		// currently in control
		Rules = `TACTICALRULES;
		ShouldFadeOut = Rules != none && Rules.GetUnitActionTeam() != eTeam_XCom;
		if(ShouldFadeOut)
		{
			ConcealmentRenderingComponent.FadeOut();
		}
		else 
		{
			UpdateConcealmentTiles();
			ConcealmentRenderingComponent.SetHidden(false);
		}
	}
}

// returns true if the current path will use more than one movement point
simulated function bool IsDashing()
{
	// check if the current
	if(LastActiveUnit != none && ActiveCache != none)
	{
		return ActiveCache.GetPathCostToTile(LastDestinationTile) > LastActiveUnit.GetMobility();
	}
	else
	{
		return false;
	}
}

// returns true if the current path will use more than two movement points (so is always out of range)
simulated function bool IsOutOfRange(TTile Tile)
{
	local float pathCostToTile;
	//local float mobility;

	// check if the current
	if(LastActiveUnit != none && ActiveCache != none)
	{
		pathCostToTile = ActiveCache.GetPathCostToTile(Tile);
		//mobility = LastActiveUnit.GetMobility();
		return pathCostToTile > 2 * LastActiveUnit.GetMobility() || // will require more than two moves
			   pathCostToTile < 0; // invalid tile
	}
	else
	{
		return false;
	}
}
simulated function UpdatePathTileData()
{
	local XComPresentationLayer Pres;
	local array<StateObjectReference> ObjectsVisibleToPlayer;

	if( LastActiveUnit != none )
	{
		class'X2TacticalVisibilityHelpers'.static.FillPathTileDataAndVisibleObjects(LastActiveUnit.ObjectID, PathTiles, PathTileData, ObjectsVisibleToPlayer, true);
		if (ShowLOSPreview)
		{
			Pres = `PRES;
			UITacticalHUD_EnemyPreview(Pres.m_kTacticalHUD.m_kEnemyPreview).UpdatePreviewTargets(PathTileData[PathTileData.Length - 1], ObjectsVisibleToPlayer);
			Pres.m_kUnitFlagManager.RealizePreviewEndOfMoveLOS(PathTileData[PathTileData.Length - 1]);
		}
	}
}

simulated function vector GetPathDestinationLimitedByCost()
{
	if (VisualPath.IsValid())
	{
		return VisualPath.GetEndPoint();
	}
	
	return vect(0,0,0);
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();

	VisualPath = new(self) class'XComPath';
}

simulated event PostBeginPlay()
{
	local StaticMesh ConcealmentTilesVisibleMesh;
	local StaticMesh ConcealmentTilesHiddenMesh;
	local StaticMesh ConcealmentBreakTilesVisibleMesh;
	local StaticMesh ConcealmentBreakTilesHiddenMesh;
	local StaticMesh ObjectiveTilesVisibleMesh;
	local StaticMesh ObjectiveTilesHiddenMesh;
	local StaticMesh BondmateTilesVisibleMesh;
	local StaticMesh BondmateTilesHiddenMesh;
	local StaticMesh ReviveTilesVisibleMesh;
	local StaticMesh ReviveTilesHiddenMesh;
	local StaticMesh HuntersMarkTilesVisibleMesh;
	local StaticMesh HuntersMarkTilesHiddenMesh;

	// unreal physics, BEGONE!
	SetPhysics(PHYS_None);

	// setup the puck and its various states
	PuckMeshNormal = StaticMesh(DynamicLoadObject(PuckMeshName, class'StaticMesh'));

	if(`ISCONTROLLERACTIVE)
	{
		PuckMeshCircle = StaticMesh(DynamicLoadObject(PuckMeshCircleName, class'StaticMesh'));
		PuckMeshCircleDashing = StaticMesh(DynamicLoadObject(PuckMeshCircleDashingName, class'StaticMesh'));
	}
	PuckMeshDashing = StaticMesh(DynamicLoadObject(PuckMeshDashingName, class'StaticMesh'));
	PuckMeshConfirmed = StaticMesh(DynamicLoadObject(PuckMeshConfirmedName, class'StaticMesh'));
	PuckMeshConfirmedDashing = StaticMesh(DynamicLoadObject(PuckMeshConfirmedDashingName, class'StaticMesh'));
	PuckMeshSlashing = StaticMesh(DynamicLoadObject(PuckMeshSlashingName, class'StaticMesh'));
	PuckMeshConfirmedSlashing = StaticMesh(DynamicLoadObject(PuckMeshConfirmedSlashingName, class'StaticMesh'));
	PuckMeshOutOfRange = StaticMesh(DynamicLoadObject(PuckMeshOutOfRangeName, class'StaticMesh'));
	PuckMeshUnitSelect = StaticMesh(DynamicLoadObject(PuckMeshUnitSelectName, class'StaticMesh'));
	PuckMeshEnemySelect = StaticMesh(DynamicLoadObject(PuckMeshEnemySelectName, class'StaticMesh'));

	PuckMeshComponent.SetStaticMeshes(PuckMeshNormal, PuckMeshConfirmed);
	if(`ISCONTROLLERACTIVE)
	{
		PuckMeshCircleComponent.SetStaticMesh(PuckMeshCircle);
		OutOfRangeMeshComponent.SetStaticMesh(PuckMeshOutOfRange);		
	}

	SlashingMeshComponent.SetStaticMeshes(PuckMeshSlashing, PuckMeshConfirmedSlashing);

	ConcealmentTilesVisibleMesh = StaticMesh(DynamicLoadObject(ConcealmentTilesVisibleMeshName, class'StaticMesh'));
	ConcealmentTilesHiddenMesh = StaticMesh(DynamicLoadObject(ConcealmentTilesHiddenMeshName, class'StaticMesh'));
	ConcealmentRenderingComponent.SetStaticMeshes(ConcealmentTilesVisibleMesh, ConcealmentTilesHiddenMesh);

	ConcealmentBreakTilesVisibleMesh = StaticMesh(DynamicLoadObject(ConcealmentBreakTilesVisibleMeshName, class'StaticMesh'));
	ConcealmentBreakTilesHiddenMesh = StaticMesh(DynamicLoadObject(ConcealmentBreakTilesHiddenMeshName, class'StaticMesh'));
	ConcealmentBreakRenderingComponent.SetStaticMeshes(ConcealmentBreakTilesVisibleMesh, ConcealmentBreakTilesHiddenMesh);

	ObjectiveTilesVisibleMesh = StaticMesh(DynamicLoadObject(ObjectiveTilesVisibleMeshName, class'StaticMesh'));
	ObjectiveTilesHiddenMesh = StaticMesh(DynamicLoadObject(ObjectiveTilesHiddenMeshName, class'StaticMesh'));
	ObjectiveTilesRenderingComponent.SetStaticMeshes(ObjectiveTilesVisibleMesh, ObjectiveTilesHiddenMesh);

	BondmateTilesVisibleMesh = StaticMesh(DynamicLoadObject(BondmateTilesVisibleMeshName, class'StaticMesh'));
	BondmateTilesHiddenMesh = StaticMesh(DynamicLoadObject(BondmateTilesHiddenMeshName, class'StaticMesh'));
	BondmateTilesRenderingComponent.SetStaticMeshes(BondmateTilesVisibleMesh, BondmateTilesHiddenMesh);

	ReviveTilesVisibleMesh = StaticMesh(DynamicLoadObject(ReviveTilesVisibleMeshName, class'StaticMesh'));
	ReviveTilesHiddenMesh = StaticMesh(DynamicLoadObject(ReviveTilesHiddenMeshName, class'StaticMesh'));
	ReviveTilesRenderingComponent.SetStaticMeshes(ReviveTilesVisibleMesh, ReviveTilesHiddenMesh);

	HuntersMarkTilesVisibleMesh = StaticMesh(DynamicLoadObject(HuntersMarkTilesVisibleMeshName, class'StaticMesh'));
	HuntersMarkTilesHiddenMesh = StaticMesh(DynamicLoadObject(HuntersMarkTilesHiddenMeshName, class'StaticMesh'));
	HuntersMarkTilesRenderingComponent.SetStaticMeshes(HuntersMarkTilesVisibleMesh, HuntersMarkTilesHiddenMesh);

	// setup the ribbon
	PathMaterialNormal = MaterialInterface(DynamicLoadObject(PathMaterialNormalName, class'MaterialInterface'));
	PathMaterialDashing = MaterialInterface(DynamicLoadObject(PathMaterialDashingName, class'MaterialInterface'));
	RenderablePath.SetMaterial(PathMaterialNormal);
}

function InitEvents()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	// listen for events that will invalidate concealment caches
	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockCompleted);
	EventManager.RegisterForEvent(ThisObj, 'UnitConcealmentEntered', OnUnitConcealmentChanged, ELD_OnStateSubmitted);
	EventManager.RegisterForEvent(ThisObj, 'UnitConcealmentBroken', OnUnitConcealmentChanged, ELD_OnStateSubmitted);
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	// for now, assume all abilities invalidate all caches
	MarkAllConcealmentCachesDirty();

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitConcealmentChanged(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(EventData);

	// dirty the concealment cache for the unit whose concealment status has changed
	MarkConcealmentCacheDirty(UnitState.ObjectID);

	if (LastActiveUnit != none && LastActiveUnit.ObjectID == UnitState.ObjectID)
	{
		bConcealmentTilesNeedUpdate = true;
	}

	return ELR_NoInterrupt;
}

// Activates a the pathing pawn for a unit.
// Don't use this for AI
simulated event SetActive(XGUnitNativeBase kActiveXGUnit, optional bool bCanDash=false, optional bool bObeyMaxCost=true)
{
	local bool ForceResetConcealment;
	local XComGameState_Unit VisualizedUnitState;

	`assert(kActiveXGUnit != none);

	//If we are selecting a unit for the first time, make sure the concealment shader gets reset fully.
	if (LastActiveUnit == None)
		ForceResetConcealment = true;
	else
		ForceResetConcealment = false;


	ForceUpdateNextTick = true;
	LastActiveUnit = kActiveXGUnit;
	ActiveCache = LastActiveUnit.m_kReachableTilesCache;

	VisualizedUnitState = kActiveXGUnit.GetVisualizedGameState();
	if (kActiveXGUnit.GetPawn() != None)
	{
		if (VisualizedUnitState.IsUnitAffectedByEffectName(class'X2Ability_ChosenSniper'.default.TrackingShotMarkTargetEffectName))
		{
			kActiveXGUnit.GetPawn().bLaserScopeTilesNeedUpdate = true;
		}
		else
		{
			kActiveXGUnit.GetPawn().LaserScopeVisibleTiles.Length = 0;
		}
	}
	LaserScopeMarkers.Length = 0;
	KillZoneMarkers.Length = 0;

	bConcealmentTilesNeedUpdate = true;
	SetWaypointModifyMode(false);
	ClearAllWaypoints();
	SetVisible(true);

	if (ForceResetConcealment)
		`PRES.UpdateConcealmentShader(false, true, true);
	else
		`PRES.UpdateConcealmentShader();
}

/// <summary>
/// Returns true if the currently active unit can finish this move with an attack on the specified TargetPawn.
/// i.e. slashing charge, etc.
/// </summary>
simulated protected function bool CanUnitMeleeFromMove(XComGameState_BaseObject TargetObject, out XComGameState_Ability MeleeAbility)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate MeleeAbilityTemplate;
	local bool bCanUnitMeleeFromMove;

	if(TargetObject == none || LastActiveUnit == none)
	{
		return false;
	}

	History = `XCOMHISTORY;

	// find the unit's default melee ability
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(LastActiveUnit.ObjectID));
	MeleeAbility = class'X2AbilityTrigger_EndOfMove'.static.GetAvailableEndOfMoveAbilityForUnit(UnitState);
	if(MeleeAbility == none)
	{
		return false;
	}

	if ( TargetObject != none )
	{
		MeleeAbilityTemplate = MeleeAbility.GetMyTemplate();

		// first check if the target is in range
		bCanUnitMeleeFromMove = MeleeAbilityTemplate.AbilityTargetStyle.ValidatePrimaryTargetOption(MeleeAbility, UnitState, TargetObject);

		// and then check specific target conditions
		bCanUnitMeleeFromMove = bCanUnitMeleeFromMove && MeleeAbilityTemplate.CheckTargetConditions(MeleeAbility, UnitState, TargetObject) == 'AA_Success';

		// and then check if the shooter is able to activate the ability
		bCanUnitMeleeFromMove = bCanUnitMeleeFromMove && MeleeAbility.CanActivateAbility(UnitState) == 'AA_Success';
	}

	if(!bCanUnitMeleeFromMove)
	{
		MeleeAbility = none;
		return false;
	}
	else
	{
		return true;
	}
}

simulated private native function UpdateBorderHideHeights();
simulated private native function UpdatePath(const out TTile PathDestination, out array<TTile> Path);

function SetWaypointModifyMode(bool ModifyingWaypoints)
{
	if(ModifyingWaypoints != WaypointModifyMode)
	{
		WaypointModifyMode = ModifyingWaypoints;

		UpdatePathMarkers();
	}
}

// find the desired tile destination by determining where, relative to the center of this unit, 
// the mouse is pointing. This allows the user to adjust their desired pick location simply by
// moving the mouse over the target pawn in a given direction. Returns the melee ability to be used, or none if no
// valid attack is available
private function XComGameState_Ability SelectMeleeMovePathDestination(XComGameState_BaseObject TargetObject, XComTacticalHUD Hud, out TTile PathDestination)
{
	local XComWorldData WorldData;
	local X2GameRulesetVisibilityInterface TargetInterface;
	local XComGameState_Ability MeleeAbility;
	local Plane GroundPlane;
	local vector GroundPlaneMouseIntersect;
	local vector TargetLocation;
	local vector TilePosition;
	local vector ToIntersect;
	local Box VisibilityExtents;
	local XComGameState_Unit UnitState;
	local array<TTile> PossibleDestinations;
	local TTile IdealDestination;

	TargetInterface = X2GameRulesetVisibilityInterface(TargetObject);
	if(TargetInterface == none)
	{
		return none;
	}

	WorldData = `XWORLD;

	// Get the tile location of the target actor.
	TargetInterface.GetVisibilityExtents(VisibilityExtents);

	// get the world space location this target is sitting in
	TargetLocation = (VisibilityExtents.Max - VisibilityExtents.Min) * 0.5 + VisibilityExtents.Min;
	TargetLocation.Z = WorldData.GetFloorZForPosition(TargetLocation) + PathHeightOffset;

	// ground plane normal at the unit's feet, facing up
	GroundPlane.X = 0;
	GroundPlane.Y = 0;
	GroundPlane.Z = 1;
	GroundPlane.W = TargetLocation dot vect(0, 0, 1);

	if(`ISCONTROLLERACTIVE)
	{
		GroundPlaneMouseIntersect = `CURSOR.Location;
		GroundPlaneMouseIntersect.Z = TargetLocation.Z;
	}
	else
	{
		// find where the mouse intersects the ground plane under the unit
		if(!RayPlaneIntersection(Hud.CachedMouseWorldOrigin, Hud.CachedMouseWorldDirection, GroundPlane, GroundPlaneMouseIntersect))
		{
			return none; // no intersection with the ground plane, can't select a destination
		}
	}

	// and then get the closest tile along the line from the center of the target unit's tile to the mouse intersect.
	// this has the net effect of selecting the tile just above the unit when the mouse is near the top of his tile, etc
	ToIntersect = Normal(GroundPlaneMouseIntersect - TargetLocation) * class'XComWorldData'.const.WORLD_StepSize_2D_Diagonal;
	TilePosition = TargetLocation + ToIntersect;

	// this is our ideal destination, the one we want to attack from
	IdealDestination = WorldData.GetTileCoordinatesFromPosition(TilePosition);
	IdealDestination.Z = WorldData.GetFloorTileZ(IdealDestination);
	if(CanUnitMeleeFromMove(TargetObject, MeleeAbility) && ActiveCache.IsTileReachable(IdealDestination))
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LastActiveUnit.ObjectID));

		class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile(UnitState, 
			XComGameState_BaseObject(TargetInterface), 
			MeleeAbility.GetMyTemplate(), 
			PossibleDestinations,
			IdealDestination,
			true); // don't need to sort
		
		// if we can't attack from the requested tile, then simply disallow it. It feels bad to try to select a second best when
		// you're targeting a specific tile
		foreach PossibleDestinations(PathDestination)
		{
			if(PathDestination == IdealDestination)
			{
				return MeleeAbility;
			}
		}
	}

	return none;
}

// Determines whether the cursor is on the same tiles as the current unit.
simulated function bool CursorOnOriginalUnit()
{
	local Actor TargetActor;
	local TTile CursorTile;
	local vector CursorLocation;
	local XComGameState_Unit ActiveUnitState;
	local XComTacticalHUD Hud;
	local XComUnitPawn TargetPawn;
	local XComWorldData WorldData;	
	local array<Actor> TileActors;
	local Actor TileActor;
	
	WorldData = `XWORLD;
	CursorLocation = `CURSOR.Location;
	if(!WorldData.GetFloorTileForPosition(CursorLocation, CursorTile))
	{
		CursorTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);
	}

	Hud = XComTacticalHUD(GetALocalPlayerController().myHUD);
	TargetActor = Actor(Hud.CachedMouseInteractionInterface);
	if (TargetActor == none)
	{
		TileActors = WorldData.GetActorsOnTile(CursorTile);
		foreach TileActors( TileActor )
		{
			if (XGUnit(TileActor) != none)
			{
				TargetActor = XGUnit(TileActor).GetPawn();
				TargetPawn = XComUnitPawn(TargetActor);
				ActiveUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LastActiveUnit.ObjectID));

				if (TargetPawn != none && TargetPawn.GetGameUnit() != none && TargetPawn.GetGameUnit().ObjectID == ActiveUnitState.ObjectID)
					return true;
			}
		}
	}

	return false;
}

simulated protected function RebuildOnlySplinepathingInformation(TTile PathDestination)
{
	local XComGameState_Unit ActiveUnitState;
	local array<PathPoint> PathPoints;
	local array<TTile> WaypointTiles;
	local float OriginalOriginZ;

	ActiveUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LastActiveUnit.ObjectID));
	UpdatePath(PathDestination, PathTiles);

	class'X2PathSolver'.static.GetPathPointsFromPath(ActiveUnitState, PathTiles, PathPoints);

	OriginalOriginZ = PathPoints[0].Position.Z;
	PathPoints[0].Position = LastActiveUnit.GetPawn().GetFeetLocation();
	PathPoints[0].Position.Z = OriginalOriginZ;

	if(PathTiles[PathTiles.Length - 1] == ActiveUnitState.TileLocation)
	{
		PathPoints[PathPoints.Length - 1].Position = PathPoints[0].Position;
	}

	GetWaypointTiles(WaypointTiles);
	class'XComPath'.static.PerformStringPulling(LastActiveUnit, PathPoints, WaypointTiles);

	VisualPath.SetPathPointsDirect(PathPoints);
	BuildSpline();

	UpdateConcealmentMarkers();
	UpdateConcealmentBreakingMarkerInfo();
	UpdateLaserScopeMarkers();
	UpdateKillZoneMarkers(ActiveUnitState);
	UpdateObjectiveTiles(ActiveUnitState);
	UpdateBondmateTiles(ActiveUnitState);
	UpdateReviveTiles(ActiveUnitState);
	UpdateHuntersMarkTiles(ActiveUnitState);
	UpdateHazardMarkerInfo(ActiveUnitState);
	UpdateNoiseMarkerInfo(ActiveUnitState);
	UpdatePathMarkers();

	UpdateRenderablePath(`CAMERASTACK.GetCameraLocationAndOrientation().Location);
}

// this is the overarching function that rebuilds all of the pathing information when the destination or active unit changes.
// if you need to add some other information (markers, tiles, etc) that needs to be updated when the path does, you should add a 
// call to that update function to this function.

simulated protected function RebuildPathingInformation(TTile PathDestination, Actor TargetActor, X2AbilityTemplate MeleeAbilityTemplate, TTile CursorTile)
{
	local XComWorldData WorldData;
	local XComGameState_Unit ActiveUnitState;
	local array<PathPoint> PathPoints;
	local array<TTile> WaypointTiles;
	local float OriginalOriginZ;
	local XComCoverPoint CoverPoint;
	local bool bCursorOnOriginalUnit;

	if(LastActiveUnit == none)
	{
		`Redscreen("RebuildPathingInformation(): Unable to update, no unit was set with SetActive()");
		return;
	}

	ActiveUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LastActiveUnit.ObjectID));
	bCursorOnOriginalUnit = CursorOnOriginalUnit();

	UpdatePath(PathDestination, PathTiles);

	// get the path points from the tile path. Path points are a visual representation of the path, for
	// running and drawing the cursor line.
	class'X2PathSolver'.static.GetPathPointsFromPath(ActiveUnitState, PathTiles, PathPoints);

	// the start of the ribbon should line up with the actor's feet (he may be offset if he's in cover)
	OriginalOriginZ = PathPoints[0].Position.Z;
	PathPoints[0].Position = LastActiveUnit.GetPawn().GetFeetLocation();
	PathPoints[0].Position.Z = OriginalOriginZ;

	// and if the path destination is also in the same tile as the unit, line that up too
	if(PathTiles[PathTiles.Length - 1] == ActiveUnitState.TileLocation)
	{
		PathPoints[PathPoints.Length - 1].Position = PathPoints[0].Position;
	}	
	// If cursor is in bounds, and is not being snapped to a cover shield location,
	// and the cursor is on a valid tile or on the current unit,
	// the path should lead to the exact cursor position.
	if (`ISCONTROLLERACTIVE && 
		`XPROFILESETTINGS.Data.m_bSmoothCursor && 
	    (CursorTile == PathDestination || bCursorOnOriginalUnit))
	{
		WorldData = `XWORLD;
		if(!WorldData.GetCoverPoint(PathPoints[PathPoints.Length - 1].Position, CoverPoint))
		{
			PathPoints[PathPoints.Length - 1].Position.X = `CURSOR.Location.X;
			PathPoints[PathPoints.Length - 1].Position.Y = `CURSOR.Location.Y;
		}
	}

	// pull the points. This smooths the points and removes unneeded angles in the line that result
	// from pathing through discrete tiles
	GetWaypointTiles(WaypointTiles);
	class'XComPath'.static.PerformStringPulling(LastActiveUnit, PathPoints, WaypointTiles);

	VisualPath.SetPathPointsDirect(PathPoints);
	BuildSpline();

	UpdateConcealmentTiles();
	UpdateHazardTileMarkerInfo();
	UpdateLaserScopeMarkers();
	UpdateKillZoneMarkers(ActiveUnitState);
	UpdateObjectiveTiles(ActiveUnitState);
	UpdateBondmateTiles(ActiveUnitState);
	UpdateReviveTiles(ActiveUnitState);
	UpdateHuntersMarkTiles(ActiveUnitState);
	UpdateHazardMarkerInfo(ActiveUnitState);
	UpdateNoiseMarkerInfo(ActiveUnitState);
	UpdatePathMarkers();

	UpdatePathTileData();		
	UpdateRenderablePath(`CAMERASTACK.GetCameraLocationAndOrientation().Location);
	if( `ISCONTROLLERACTIVE )
	{
		RenderablePath.SetHidden(bCursorOnOriginalUnit);
	}

	UpdateTileCacheVisuals();
	UpdateBorderHideHeights();

	if( `ISCONTROLLERACTIVE == FALSE )
		UpdatePuckVisuals(ActiveUnitState, PathDestination, TargetActor, MeleeAbilityTemplate);
	UpdatePuckFlyovers(ActiveUnitState);
	UpdatePuckAudio();
}

simulated protected function DoUpdatePuckVisuals(TTile PathDestination, Actor TargetActor, X2AbilityTemplate MeleeAbilityTemplate)
{
	local XComGameState_Unit ActiveUnitState;

	ActiveUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LastActiveUnit.ObjectID));

	UpdatePuckVisuals(ActiveUnitState, PathDestination, TargetActor, MeleeAbilityTemplate);
}

simulated function GetMaxTileZFromFloorLevel(XComBuildingVolume BuildingVolume, int FloorNum, out int MaxTileZ)
{
	local XComWorldData WorldData;
	local vector MaxPosition;
	local float Origin, Extent;

	WorldData = `XWORLD;

	Origin = BuildingVolume.Floors[FloorNum].fCenterZ;
	Extent = BuildingVolume.Floors[FloorNum].fExtent;

	MaxPosition = vect(0, 0, 0);
	MaxPosition.Z = Origin + Extent - WorldData.WORLD_HalfFloorHeight;

	MaxTileZ = WorldData.GetTileCoordinatesFromPosition(MaxPosition).Z;
}

simulated event Tick(float DeltaTime)
{
	local XComTacticalCheatManager TacticalCheatManager;
	local XComWorldData WorldData;
	local Actor TargetActor;
	local XCom3DCursor Cursor;
	local XComTacticalHUD Hud;
	local XComGameState_Ability MeleeAbility;
	local TTile PathDestination;
	local TTile CursorTile;
	local XGUnit ActiveUnit;
	local vector CursorLocation;
	local int TargetObjectId;
	local XComGameState_BaseObject TargetObject;
	local int MinZ, MaxZ;
	local vector RoundedPos;
	local TTile RoundedTile;
	local array<Actor> TileActors;
	local Actor TileActor;
	local array<TTile> AllTiles;

	super.Tick(DeltaTime);

	TacticalCheatManager = XComTacticalCheatManager(GetALocalPlayerController().CheatManager);
	if ((TacticalCheatManager != none && TacticalCheatManager.bHidePathingPawn) || (!`REPLAY.bInTutorial && `SCREENSTACK.IsInStack(class'UIReplay')))
	{
		PuckMeshComponent.SetHidden(true);
		if( `ISCONTROLLERACTIVE )
		{
			PuckMeshCircleComponent.SetHidden(true);
		}	
		SlashingMeshComponent.SetHidden(true);
		OutOfRangeMeshComponent.SetHidden(true);
		ConcealmentRenderingComponent.SetHidden(true);
		ConcealmentBreakRenderingComponent.SetHidden(true);
		RenderablePath.SetHidden(true);
		super.SetVisible(false);
		return;
	}

	//Only update the concealment tiles once the current visualizations are finished
	if (bConcealmentTilesNeedUpdate && !class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
	{
		UpdateConcealmentTiles();
		bConcealmentTilesNeedUpdate = false;
	}
	if (LastActiveUnit != None 
		&& LastActiveUnit.GetPawn() != None
		&& LastActiveUnit.GetPawn().bLaserScopeTilesNeedUpdate
		&& !class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
	{
		ActiveCache.GetAllPathableTiles(AllTiles);
		LastActiveUnit.GetPawn().UpdateLaserScopeTiles(AllTiles);
	}
	if(bHidden || LastActiveUnit == none)
	{
		// nothing to see, just clear the cached data out and return
		PathTiles.Length = 0;
		HazardMarkers.Length = 0;
		NoiseMarkers.Length = 0;
		LaserScopeMarkers.Length = 0;
		KillZoneMarkers.Length = 0;
		PathDestination.X = -1; // so that it will update the path the next time we don't hit this block

		if(LastActiveUnit == none)
		{
			// make sure we don't get any stale waypoint data when there is no active unit. This only happens in the no 
			// unit case so that we don't lose our waypoints every time we hide the puck when hovering over the UI
			ClearAllWaypoints();
		}

		// prevents "phantom" markers that will fade out on unit switch
		UpdatePathMarkers();

		return;
	}

	// safety catch for the active unit changing out from under us
	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	if(ActiveUnit != LastActiveUnit)
	{
		SetActive(ActiveUnit);
	}

	Cursor = `CURSOR;
	Hud = XComTacticalHUD(GetALocalPlayerController().myHUD);

	CursorLocation = Cursor.Location;
	TargetActor = Actor(Hud.CachedMouseInteractionInterface);

	// snap the cursor location to the ground
	WorldData = `XWORLD;
	if(!WorldData.GetFloorTileForPosition(CursorLocation, CursorTile, `ISCONTROLLERACTIVE))
	{
		CursorTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);
	}

	if(XComUnitPawn(Hud.CachedMouseInteractionInterface) != none)
	{
		TargetObjectId = XComUnitPawn(Hud.CachedMouseInteractionInterface).GetGameUnit().ObjectID;
	}
	else if(XComDestructibleActor(Hud.CachedMouseInteractionInterface) != none)
	{
		TargetObjectId = XComDestructibleActor(Hud.CachedMouseInteractionInterface).ObjectID;
	}

	if( `ISCONTROLLERACTIVE )
	{
		if (TargetActor == none)
		{
			TileActors = WorldData.GetActorsOnTile(CursorTile);
			foreach TileActors( TileActor )
			{
				if (XGUnit(TileActor) != none)
				{
					TargetActor = XGUnit(TileActor).GetPawn();
					break;
				}
			}
		}

		if (TargetObjectId <= 0)
		{
			if (XComUnitPawn(TargetActor) != none)
			{
				TargetObjectId = XComUnitPawn(TargetActor).GetGameUnit().ObjectID;
			}
			else if (XComDestructibleActor(TargetActor) != none)
			{
				TargetObjectId = XComDestructibleActor(TargetActor).ObjectID;
			}
		}
	}
	TargetObject = `XCOMHISTORY.GetGameStateForObjectID(TargetObjectId);

	// special case for melee attack moves. If we're targeting a unit, pick the destination tile based
	// on which side of the targeted unit the mouse cursor is closest to.
	MeleeAbility = SelectMeleeMovePathDestination(TargetObject, Hud, PathDestination);
	if(MeleeAbility == none)
	{
		MinZ = -1;
		MaxZ = 999;

		if (Cursor.IndoorInfo.CurrentBuildingVolume != none)
		{
			GetMaxTileZFromFloorLevel(Cursor.IndoorInfo.CurrentBuildingVolume, Min(Cursor.m_iRequestedFloor, Cursor.IndoorInfo.CurrentBuildingVolume.Floors.Length - 1), MaxZ);
		}

		// if not a melee move, just grab the closest valid path destination
		if(AllowSelectionOfActiveUnitTile && CursorTile == ActiveUnit.GetVisualizedGameState().TileLocation)
		{
			PathDestination = CursorTile;
		}
		else
		{
			if( `ISCONTROLLERACTIVE )
			{
				//Improve tactical UI when cursor is on original unit AMS 2016/05/05

				// jharries: have to round the z coord to stop the feet being stuck in the ground occasionally, thus causing a pathing fail
		       	RoundedTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);
				RoundedPos = WorldData.GetPositionFromTileCoordinates(RoundedTile);
				CursorLocation.Z = RoundedPos.Z;


				//TEMP bsteiner PathDestination = ActiveCache.GetClosestReachableDestinationToLocation(CursorTile, CursorLocation, , MinZ, MaxZ);
				PathDestination = ActiveCache.GetClosestReachableDestination(CursorTile, , MinZ, MaxZ); //TEMP bsteiner 
			}
			else
			{
		
				PathDestination = ActiveCache.GetClosestReachableDestination(CursorTile, , MinZ, MaxZ);
			}
		}
		TargetObject = none;
	}

	PuckLightComponent.SetTranslation(CursorLocation);
	PuckLightComponent.LightColor = `XENGINE.GetNonDirectionalAmbientCubeLighting();
	PuckLightComponent.UpdateColorAndBrightness();

	// only update the path if we have a new destination or are targeting a pawn
	if(ForceUpdateNextTick 
		|| PathDestination.X != LastDestinationTile.X 
		|| PathDestination.Y != LastDestinationTile.Y 
		|| PathDestination.Z != LastDestinationTile.Z
		|| ( `ISCONTROLLERACTIVE && ( CursorTile != LastCursorTile || (`XPROFILESETTINGS.Data.m_bSmoothCursor && CursorLocation != LastCursorLocation)))
		|| TargetObject != LastTargetObject)
	{
		LastDestinationTile = PathDestination;
		LastActiveUnit = ActiveUnit;

		RebuildPathingInformation(PathDestination, TargetActor, MeleeAbility != none ? MeleeAbility.GetMyTemplate() : none, CursorTile);

		UpdateMeleeDamagePreview(TargetObject, LastTargetObject, MeleeAbility);
		LastTargetObject = TargetObject;

		// Update Laser Scope markers.
		UpdateLaserScopeMarkers();

		bConcealmentTilesNeedUpdate = false;
		ForceUpdateNextTick = false;
	}
	if( `ISCONTROLLERACTIVE )
	{
		DoUpdatePuckVisuals(PathDestination, TargetActor, MeleeAbility != none ? MeleeAbility.GetMyTemplate() : none);
		LastCursorTile = CursorTile;
	}
}

function UpdateMeleeDamagePreview(XComGameState_BaseObject NewTargetObject, XComGameState_BaseObject OldTargetObject, XComGameState_Ability AbilityState)
{
	local XComPresentationLayer Pres;
	local UIUnitFlag UnitFlag;

	Pres = `PRES;

	if(OldTargetObject != NewTargetObject)
	{
		Pres.m_kUnitFlagManager.ClearAbilityDamagePreview();
	}

	if(NewTargetObject != none && AbilityState != none)
	{
		UnitFlag = Pres.m_kUnitFlagManager.GetFlagForObjectID(NewTargetObject.ObjectID);
		if(UnitFlag != none)
		{
			Pres.m_kUnitFlagManager.SetAbilityDamagePreview(UnitFlag, AbilityState, NewTargetObject.GetReference());
		}
	}
}

function OnMeleeAbilityActivated()
{
	`PRES.m_kUnitFlagManager.ClearAbilityDamagePreview();
}

simulated private function bool IsVisibleEnemyUnit(XComGameState_Unit ActiveUnitState, XComUnitPawn TargetPawn)
{
	local array<StateObjectReference> VisibleEnemies; 

	if(TargetPawn.GetGameUnit() == none || XGUnit(TargetPawn.GetGameUnit()).GetTeam() == ActiveUnitState.GetTeam())
	{
		return false;
	}

	// first check to see if this unit is within our normal visibility check 
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyTargetsForUnit(ActiveUnitState.ObjectID, VisibleEnemies);
	if(VisibleEnemies.Find('ObjectID', TargetPawn.ObjectID) != INDEX_NONE)
	{
		return true;
	}

	// if not, check for squadsight
	if(ActiveUnitState.HasSquadsight())
	{
		VisibleEnemies.Length = 0;
		class'X2TacticalVisibilityHelpers'.static.GetAllSquadsightEnemiesForUnit(ActiveUnitState.ObjectID, VisibleEnemies);
		if(VisibleEnemies.Find('ObjectID', TargetPawn.ObjectID) != INDEX_NONE)
		{
			return true;
		}
	}

	return false;
}

simulated protected function UpdatePuckVisuals(XComGameState_Unit ActiveUnitState, 
												const out TTile PathDestination, 
												Actor TargetActor,
												X2AbilityTemplate MeleeAbilityTemplate)
{
	local XComWorldData WorldData;
	local vector MeshTranslation;
	local Rotator MeshRotation;	
	local vector MeshScale;
	local vector FromTargetTile;
	local TTile CursorTile;
	local XComGameState_Unit TargetUnitState;
	local XGUnit TargetVisualizer;
	local XComUnitPawn TargetPawn;
	local float UnitSize;
	local vector VisualPathEndPoint;
	local float FadeProgress;
	local float kFocusedOpacity;
	local float kNonFocusedOpacity;
	local float kFNumFocusInterpFrames;
	local bool bOutOfRange;

	local XComTacticalController TheCursor;
	if (`ISCONTROLLERACTIVE)
	{
		if (VisualPath.IsValid())
		{
			VisualPathEndPoint = VisualPath.GetEndPoint();
		}
		else
		{
			VisualPathEndPoint = `CURSOR.Location;
		}
	}	

	WorldData = `XWORLD;
	TargetPawn = XComUnitPawn(TargetActor);

	if(!WorldData.GetFloorTileForPosition(`CURSOR.Location, CursorTile))
	{
		CursorTile = WorldData.GetTileCoordinatesFromPosition(`CURSOR.Location);
	}

	if(PathDestination != CursorTile)
	{
		MeshTranslation = WorldData.GetPositionFromTileCoordinates(CursorTile);
		if( `ISCONTROLLERACTIVE )
		{
			MeshTranslation.Z = VisualPathEndPoint.Z;
		}
		MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;

		if(MeleeAbilityTemplate != none)
		{
			// center the slashing puck on the thing we are slashing
			MeshTranslation = TargetActor.CollisionComponent.Bounds.Origin;
			MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;

			// when slashing, we will technically be out of range. 
			// hide the out of range mesh, show melee mesh
			OutOfRangeMeshComponent.SetHidden(true);
			SlashingMeshComponent.SetHidden(false);
			SlashingMeshComponent.SetTranslation(MeshTranslation);

			// rotate the mesh to face the thing we are slashing
			// note that cursor tile will be the tile the unit we are slashing is on, and
			// path destination is the tile we will slash from
			FromTargetTile = WorldData.GetPositionFromTileCoordinates(PathDestination) - MeshTranslation; 
			MeshRotation.Yaw = atan2(FromTargetTile.Y, FromTargetTile.X) * RadToUnrRot;
		
			// snap rotation to 45 degree increments
			SlashingMeshComponent.SetRotation(MeshRotation);

			// scale the targeting pip to the size of the target
			UnitSize = TargetPawn != none ? float(TargetPawn.GetGameUnit().GetVisualizedGameState().UnitSize) : 1.0f;
			SlashingMeshComponent.SetScale(UnitSize);
		}
		else if(TargetPawn != none && TargetPawn.GetGameUnit() != none && XGUnit(TargetPawn.GetGameUnit()).GetTeam() == ActiveUnitState.GetTeam() )
		{
			TargetUnitState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( TargetPawn.ObjectID ) );
			TargetVisualizer = XGUnit( TargetUnitState.GetVisualizer( ) );

			// show the unit selection mesh
			SlashingMeshComponent.SetHidden(true);
			OutOfRangeMeshComponent.SetHidden(false);
			OutOfRangeMeshComponent.SetStaticMesh(PuckMeshUnitSelect);

			MeshTranslation.X = TargetVisualizer.Location.X;
			MeshTranslation.Y = TargetVisualizer.Location.Y;
			OutOfRangeMeshComponent.SetTranslation( MeshTranslation );

			MeshScale.X = TargetUnitState.UnitSize;
			MeshScale.Y = TargetUnitState.UnitSize;
			MeshScale.Z = 1.0f;
			OutOfRangeMeshComponent.SetScale3D( MeshScale );
		}
		else if(TargetPawn != none && IsVisibleEnemyUnit(ActiveUnitState, TargetPawn))
		{
			TargetUnitState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( TargetPawn.ObjectID ) );
			TargetVisualizer = XGUnit(TargetUnitState.GetVisualizer());

			// show the unit selection mesh
			SlashingMeshComponent.SetHidden( true );
			OutOfRangeMeshComponent.SetHidden( false );
			OutOfRangeMeshComponent.SetStaticMesh( PuckMeshEnemySelect );

			MeshTranslation.X = TargetVisualizer.Location.X;
			MeshTranslation.Y = TargetVisualizer.Location.Y;
			OutOfRangeMeshComponent.SetTranslation( MeshTranslation );

			MeshScale.X = TargetUnitState.UnitSize;
			MeshScale.Y = TargetUnitState.UnitSize;
			MeshScale.Z = 1.0f;
			OutOfRangeMeshComponent.SetScale3D( MeshScale );
		}

		else if (`ISCONTROLLERACTIVE && (PathDestination.X != CursorTile.X || PathDestination.Y != CursorTile.Y))
		{
			// hide the melee mesh, show out of range mesh
			SlashingMeshComponent.SetHidden(true);
			OutOfRangeMeshComponent.SetHidden(false);
			OutOfRangeMeshComponent.SetStaticMesh(PuckMeshOutOfRange);
			OutOfRangeMeshComponent.SetTranslation(`CURSOR.GetCursorFeetLocation());


			bOutOfRange = true;
			MeshScale.X = 1.0f;
			MeshScale.Y = 1.0f;
			MeshScale.Z = 1.0f;
			OutOfRangeMeshComponent.SetScale3D( MeshScale );
		}	
		else
		{
			SlashingMeshComponent.SetHidden(true);
			OutOfRangeMeshComponent.SetHidden(true);
		}
	}
	else
	{
		SlashingMeshComponent.SetHidden(true);
		OutOfRangeMeshComponent.SetHidden(true);
	}

	// the normal puck is always visible, and located wherever the unit
	// will actually move to when he executes the move
	PuckMeshComponent.SetHidden(false);
	if( `ISCONTROLLERACTIVE )
		PuckMeshCircleComponent.SetHidden(bOutOfRange);
	if (SlashingMeshComponent.HiddenGame == false)
	{
		// update the slashing mesh to be correct for the currently targeted ability
		PuckMeshComponent.SetStaticMeshes(GetMeleePuckMeshForAbility(MeleeAbilityTemplate), PuckMeshConfirmed);
		if( `ISCONTROLLERACTIVE )
			PuckMeshCircleComponent.SetStaticMeshes(GetMeleePuckMeshForAbility(MeleeAbilityTemplate), PuckMeshConfirmed);		
			
		if (IsDashing() || ActiveUnitState.NumActionPointsForMoving() == 1)
		{
			RenderablePath.SetMaterial(PathMaterialDashing);
		}
	}
	else if(IsDashing() || ActiveUnitState.NumActionPointsForMoving() == 1)
	{
		PuckMeshComponent.SetStaticMeshes(PuckMeshDashing, PuckMeshConfirmedDashing);
		if( `ISCONTROLLERACTIVE )
			PuckMeshCircleComponent.SetStaticMeshes(PuckMeshCircleDashing, PuckMeshConfirmedDashing);
					
		RenderablePath.SetMaterial(PathMaterialDashing);
	}
	else
	{
		PuckMeshComponent.SetStaticMeshes(PuckMeshNormal, PuckMeshConfirmed);
		if( `ISCONTROLLERACTIVE )
			PuckMeshCircleComponent.SetStaticMeshes(PuckMeshCircle, PuckMeshConfirmed);	
				
		RenderablePath.SetMaterial(PathMaterialNormal);
	}
	if( `ISCONTROLLERACTIVE )
	{
		kNonFocusedOpacity = 0.3;
		kFocusedOpacity = 1.0;
		kFNumFocusInterpFrames = 15.0;
		bMoved = XComTacticalController(`BATTLE.GetALocalPlayerController()).IsControllerPressed();

		if (bMoved)
		{
			iFramesSinceMoved = 0;
			++iFramesSinceNotMoved;
			FadeProgress = FMin(1.0, float(iFramesSinceNotMoved) / kFNumFocusInterpFrames);
		
			PuckMeshComponent.SetOpacity(Lerp(kFocusedOpacity, kNonFocusedOpacity, FadeProgress));       // fade out the tile marker
			PuckMeshCircleComponent.SetOpacity(Lerp(kNonFocusedOpacity, kFocusedOpacity, FadeProgress)); // fade in the cursor
		}
		else
		{
			iFramesSinceNotMoved = 0;
			++iFramesSinceMoved;
			FadeProgress = FMin(1.0, float(iFramesSinceMoved) / kFNumFocusInterpFrames);
		
			PuckMeshComponent.SetOpacity(Lerp(kNonFocusedOpacity, kFocusedOpacity, FadeProgress));       // fade in the tile marker
			PuckMeshCircleComponent.SetOpacity(Lerp(kFocusedOpacity, kNonFocusedOpacity, FadeProgress)); // fade out the cursor
		}
	}
	if( `ISCONTROLLERACTIVE  == false)
		MeshTranslation = VisualPath.GetEndPoint(); // make sure we line up perfectly with the end of the path ribbon
	else
		MeshTranslation = VisualPathEndPoint; // Put a puck on the tile.
	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;
	PuckMeshComponent.SetTranslation(MeshTranslation);
	if( `ISCONTROLLERACTIVE )
	{
		// Put a puck where the cursor is.
		MeshTranslation = `CURSOR.Location;
		MeshTranslation.Z = VisualPathEndPoint.Z;
		MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;
		PuckMeshCircleComponent.SetTranslation(MeshTranslation);

		bMoved = LastEndPoint.X != VisualPathEndPoint.X || LastEndPoint.Y != VisualPathEndPoint.Y || LastEndPoint.Z != VisualPathEndPoint.Z;
		LastEndPoint = VisualPathEndPoint;
		MeshScale.X = ActiveUnitState.UnitSize;
		MeshScale.Y = ActiveUnitState.UnitSize;
		MeshScale.Z = 1.0f;
		PuckMeshComponent.SetScale3D(MeshScale);
		
		
		PuckMeshCircleComponent.SetScale3D(MeshScale);	
		
		// Hide the circle cursor always - 2k feedback.
		PuckMeshCircleComponent.SetHidden(true);
	
		// Hide the cursor until the unit moves - 2k feedback.
		TheCursor = XComTacticalController(`BATTLE.GetALocalPlayerController());
		PuckMeshComponent.SetHidden(TheCursor.m_bChangedUnitHasntMovedCursor);
	}
}

simulated function TogglePuckLight()
{
	PuckLightComponent.SetEnabled(!PuckLightComponent.bEnabled);
}

simulated private function UpdatePuckFlyovers(XComGameState_Unit ActiveUnitState)
{
	local XComPresentationLayer Pres;
	local XComWorldData WorldData;
	local Vector SuppressionLocation;
	local bool ShowingDash;
	local TTile PathEnd;

	Pres = `PRES;
	WorldData = `XWORLD;

	if(ShowDashingLabel)
	{
		PathEnd = PathTiles[PathTiles.Length - 1];
		if(ActiveCache.GetPathCostToTile(PathEnd) > ActiveUnitState.GetCurrentStat(eStat_Mobility))
		{ 
			Pres.QueueWorldMessage(class'UITacticalTutorialMgr'.default.m_strCursorHelpDashActive,
				WorldData.GetPositionFromTileCoordinates(PathEnd),,,
				class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_STEADY,
				DashLabel, , , , 0, , , , , , , , , , true);

			ShowingDash = true;
		}
		else
		{
			Pres.m_kWorldMessageManager.RemoveMessage(DashLabel);
		}
	}

	if(ShowSuppressedLabel && ActiveUnitState.IsUnitAffectedByEffectName(class'X2Effect_Suppression'.default.EffectName))
	{
		SuppressionLocation = WorldData.GetPositionFromTileCoordinates(PathEnd);
		if(ShowingDash)
		{
			// make sure it doesn't overlap the dash label
			SuppressionLocation.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight; 
		}

		Pres.QueueWorldMessage(class'XComPresentationLayer'.default.m_strSuppressed,
			SuppressionLocation,,,
			class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_STEADY,
			SuppressedLabel, , , , 0, , , , , , , , , , true);
	}
	else
	{
		Pres.m_kWorldMessageManager.RemoveMessage(SuppressedLabel);
	}
}

simulated private function UpdatePuckAudio()
{
	local bool IsDashingNow;
	local bool IsInWarningZone;

	IsDashingNow = IsDashing();
	IsInWarningZone = (HazardMarkers.length != 0 || NoiseMarkers.length != 0 || ConcealmentMarkers.Length != 0 || LaserScopeMarkers.Length != 0 || KillZoneMarkers.Length != 0);

	if(WasInWarningZone != IsInWarningZone)
	{
		if (IsInWarningZone)
		{
			PlayAKEvent(AkEvent'SoundTacticalUI.Concealment_Warning');
		}

		WasInWarningZone = IsInWarningZone;
	}

	if(WasDashing != IsDashingNow)
	{
		PlayAKEvent(AkEvent'SoundTacticalUI.TacticalUI_DashingOverlayClick');
		WasDashing = IsDashingNow;
	}
}

simulated protected function StaticMesh GetMeleePuckMeshForAbility(X2AbilityTemplate AbilityTemplate) 
{
	local StaticMesh PuckMesh;
	local string PuckMeshPath;

	if(AbilityTemplate == none || AbilityTemplate.MeleePuckMeshPath == "")
	{
		PuckMeshPath = DefaultPuckMeshMeleePath;
	}
	else
	{
		PuckMeshPath = AbilityTemplate.MeleePuckMeshPath;
	}

	PuckMesh = StaticMesh(DynamicLoadObject(PuckMeshPath, class'StaticMesh'));
	if(PuckMesh == none)
	{
		`Redscreen("Could not load melee puck mesh for ability " $ AbilityTemplate.DataName);
		PuckMesh = StaticMesh(DynamicLoadObject(DefaultPuckMeshMeleePath, class'StaticMesh'));
	}

	return PuckMesh;
}

// adds a waypoint at the given location if none exists, otherwise removes the existing waypoint
simulated function AddOrRemoveWaypoint(Vector Destination)
{
	local XComWorldData WorldData;
	local TTile Waypoint;
	local int Index;

	if(!IsVisible() || (`TUTORIAL != none)) //No waypoints in the on-rails tutorial
	{
		return;
	}

	WorldData = `XWORLD;
	Waypoint = WorldData.GetTileCoordinatesFromPosition(Destination);

	// first attempt a remove
	for(Index = 0; Index < Waypoints.Length; Index++)
	{
		if(Waypoint.X == Waypoints[Index].Tile.X
			&& Waypoint.Y == Waypoints[Index].Tile.Y
			&& Waypoint.Z == Waypoints[Index].Tile.Z)
		{
			RemoveWaypoint(Index);
			return;
		}
	}

	// no waypoint at this location, add one if possible
	if(ActiveCache.IsTileReachable(Waypoint))
	{
		PlayAKEvent(AkEvent'SoundTacticalUI.TacticalUI_Waypoint');
		AddWaypoint();
	}
}

// removes the last waypoint, if any
simulated function bool RemoveLastWaypoint()
{
	if(Waypoints.Length > 0)
	{
		// pop the top waypoint
		RemoveWaypoint(Waypoints.Length - 1);
		return true;
	}
	else
	{
		return false;
	}
}

// clears all waypoints, as advertised
simulated function bool ClearAllWaypoints()
{
	local bool HadWaypoints;
	
	HadWaypoints = Waypoints.Length > 0;
	Waypoints.Length = 0;
	WayPointsPath.Length = 0;

	ActiveCache = LastActiveUnit != none ? LastActiveUnit.m_kReachableTilesCache : none;

	ForceUpdateNextTick = true;

	return HadWaypoints;
}

// drops a waypoint at the end of the current path
simulated private function AddWaypoint()
{
	local XComGameState_Unit UnitState;
	local WaypointTile Waypoint;

	if( PathTiles.Length == 0 )
	{
		ClearAllWaypoints();
	}

	// get the info for the new waypoint
	Waypoint.Tile = PathTiles[PathTiles.Length - 1];
	Waypoint.Cost = ActiveCache.GetPathCostToTile(Waypoint.Tile);

	// copy the current path to the waypoint path
	WayPointsPath = PathTiles;
	WaypointsPath.Length = WayPointsPath.Length - 1; // pop the end of the path, since it is our new starting point
	Waypoints.AddItem(Waypoint);

	// create and fill out a new waypoint cache that starts from the newly added waypoint
	if(X2WaypointTilesCache(ActiveCache) == none) 
	{
		ActiveCache = new class'X2WaypointTilesCache';
	}

	UnitState = LastActiveUnit == none ? none : XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LastActiveUnit.ObjectID));

	ActiveCache.SetCacheUnit(UnitState);
	X2WaypointTilesCache(ActiveCache).WaypointTile = Waypoint.Tile;
	X2WaypointTilesCache(ActiveCache).CostToWaypoint = Waypoint.Cost;

	ForceUpdateNextTick = true;
}

// Removes the waypoint at the given index in the Waypoints array (and any waypoints after that)
simulated private function RemoveWaypoint(int WaypointIndex)
{
	local int WaypointPathIndex;
	local WaypointTile Waypoint;

	if(WaypointIndex >= Waypoints.Length)
	{
		// nothing to do!
		return;
	}
	else if(WaypointIndex == 0)
	{
		// clearing all the way to the start of the path, so get rid of all waypoints
		ClearAllWaypoints();
		return;
	}
	else
	{
		// remove the waypoints after and including the one we want to remove
		Waypoints.Remove(WaypointIndex, Waypoints.Length - WaypointIndex);

		// truncate the path to the new last waypoint
		WaypointIndex--;
		Waypoint = Waypoints[WaypointIndex];
		for(WaypointPathIndex = 0; WaypointPathIndex < WaypointsPath.Length; WaypointPathIndex++)
		{
			if(WaypointsPath[WaypointPathIndex] == Waypoint.Tile)
			{
				// remove all path points after this waypoint
				WayPointsPath.Remove(WaypointPathIndex, WayPointsPath.Length - WaypointPathIndex);
				break;
			}
		}

		// update the existing waypoint cache to reflect the the new waypoint.
		X2WaypointTilesCache(ActiveCache).WaypointTile = Waypoint.Tile;
		X2WaypointTilesCache(ActiveCache).CostToWaypoint = Waypoint.Cost;
		X2WaypointTilesCache(ActiveCache).ForceCacheUpdate();

		ForceUpdateNextTick = true;
	}
}

native function GetWaypointTiles(out array<TTile> Tiles);

simulated private function HideWorldMessages()
{
	local XComPresentationLayer Pres;

	Pres = `PRES;
	Pres.m_kWorldMessageManager.RemoveMessage(DashLabel);
	Pres.m_kWorldMessageManager.RemoveMessage(SuppressedLabel);
}

simulated function SetVisible(bool Visible)
{
	super.SetVisible(Visible);

	if(!Visible)
	{
		HideWorldMessages();
	}
}


function ShowConfirmPuckAndHide()
{
	GotoState('ConfirmAndHide');
}

state ConfirmAndHide
{
	function BeginState(name PreviousState)
	{
		// have the puck mesh and slashing visuals (if active) do the confirm/ fade out animation
		PuckMeshComponent.FadeOut(); 
		if( `ISCONTROLLERACTIVE )
			PuckMeshCircleComponent.FadeOut(); 		
		
		if(!SlashingMeshComponent.HiddenGame)
		{
			SlashingMeshComponent.FadeOut();
		}

		PlayAKEvent(AkEvent'SoundTacticalUI.TacticalUI_MoveClick');

		// hide everything else
		RenderablePath.SetHidden(true);
		OutOfRangeMeshComponent.SetHidden(true);
		ClearAllPathMarkers();
		HideWorldMessages();
	}

	function EndState(name NextState)
	{
		PuckMeshComponent.SetHidden(false);
		if( `ISCONTROLLERACTIVE )
			PuckMeshCircleComponent.SetHidden(false);		
		RenderablePath.SetHidden(false);
		OutOfRangeMeshComponent.SetHidden(false);
	}

	simulated function SetVisible(bool Visible)
	{
		// ignore further claims to hide (since we are animating to a hidden state)
		if(Visible)
		{
			super.SetVisible(true);
			GotoState('');
		}
	}

	simulated function ClearAllPathMarkers()
	{
		Waypoints.Length = 0;
		HazardMarkers.Length = 0;
		NoiseMarkers.Length = 0;
		ConcealmentMarkers.Length = 0;
		LaserScopeMarkers.Length = 0;
		KillZoneMarkers.Length = 0;

		UpdatePathMarkers();
	}

	// do no updates in the tick, just let the puck component animate
	simulated event Tick(float DeltaTime);

Begin:

	while(PuckMeshComponent.IsFading() || SlashingMeshComponent.IsFading())
	{
		Sleep(0);
	}
	super.SetVisible(false);
	
	GotoState('');
}

///////////////////////////////////////////////////////////////////////////////////////////

native function SetConcealmentBreakRenderTiles(const out Vector FromLocation, const out Vector ToLocation, float CapsuleRadius);
native function ClearConcealmentBreakRenderTiles();

///////////////////////////////////////////////////////////////////////////////////////////

cpptext
{
public:
	// get the concealment cache for the specified unit
	FHazardousTilesCache& GetConcealmentCache(INT UnitID);

private:
	// cache a list of tiles that will break concealment for the specified unit
	void CacheConcealmentTiles(INT UnitID);
}

defaultproperties
{
	Begin Object Class=X2FadingStaticMeshComponent Name=PuckMeshComponentObject
		StaticMesh=none
		HiddenGame=true
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		TranslucencySortPriority=1000
		bTranslucentIgnoreFOW=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		Scale=1.0
	End Object
	PuckMeshComponent=PuckMeshComponentObject
	Components.Add(PuckMeshComponentObject)

	Begin Object Class=X2FadingStaticMeshComponent Name=PuckMeshCircleComponentObject
		StaticMesh=none
		HiddenGame=true
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		TranslucencySortPriority=1000
		bTranslucentIgnoreFOW=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		Scale=0.8
	End Object
	PuckMeshCircleComponent=PuckMeshCircleComponentObject
	Components.Add(PuckMeshCircleComponentObject)	
	
	Begin Object Class=PointLightComponent Name=PuckLightComponentObject
		CastShadows=false
		bAbsoluteTranslation=true
		MinRoughness=1.0
		bEnabled=false
		Brightness=1.0
		LightColor = (R = 255,G = 255,B = 255)		
	End Object
	PuckLightComponent=PuckLightComponentObject
	Components.Add(PuckLightComponentObject)

	Begin Object Class=X2FadingStaticMeshComponent Name=SlashingMeshComponentObject
		StaticMesh=none
		HiddenGame=true
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		TranslucencySortPriority=1000
		bTranslucentIgnoreFOW=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		Scale=1.0
		FullHideDelay=2.0
	End Object
	SlashingMeshComponent=SlashingMeshComponentObject
	Components.Add(SlashingMeshComponentObject)

	Begin Object Class=StaticMeshComponent Name=OutOfRangeMeshComponentObject
		StaticMesh=none
		HiddenGame=true
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		TranslucencySortPriority=1000
		bTranslucentIgnoreFOW=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		Scale=1.0
	End Object
	OutOfRangeMeshComponent=OutOfRangeMeshComponentObject
	Components.Add(OutOfRangeMeshComponentObject)

	Begin Object Class=X2FadingInstancedStaticMeshComponent name=ConcealmentRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		AbsoluteTranslation=true
		AbsoluteRotation=true
		bIgnoreOwnerHidden=true
		TranslucencySortPriority=-1000
		HiddenGame = true
		HiddenEditor=true
		HideDuringCinematicView=true
	end object
	Components.Add(ConcealmentRenderingComponent0);
	ConcealmentRenderingComponent=ConcealmentRenderingComponent0;

	Begin Object Class=X2FadingInstancedStaticMeshComponent name=ConcealmentBreakRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		AbsoluteTranslation=true
		AbsoluteRotation=true
		bIgnoreOwnerHidden=true
		TranslucencySortPriority=-1000
		HiddenGame = true
		HiddenEditor=true
		HideDuringCinematicView=true
	end object
	Components.Add(ConcealmentBreakRenderingComponent0);
	ConcealmentBreakRenderingComponent=ConcealmentBreakRenderingComponent0

	Begin Object Class=X2FadingInstancedStaticMeshComponent name=ObjectiveTilesRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		AbsoluteTranslation=true
		AbsoluteRotation=true
		bIgnoreOwnerHidden=true
		TranslucencySortPriority=-1000
		HiddenGame = false
		HiddenEditor=true
		HideDuringCinematicView=true
	end object
	Components.Add(ObjectiveTilesRenderingComponent0);
	ObjectiveTilesRenderingComponent=ObjectiveTilesRenderingComponent0;

	Begin Object Class=X2FadingInstancedStaticMeshComponent name=BondmateTilesRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		AbsoluteTranslation=true
		AbsoluteRotation=true
		bIgnoreOwnerHidden=true
		TranslucencySortPriority=-1000
		HiddenGame = false
		HiddenEditor=true
		HideDuringCinematicView=true
	end object
	Components.Add(BondmateTilesRenderingComponent0);
	BondmateTilesRenderingComponent=BondmateTilesRenderingComponent0;

	Begin Object Class=X2FadingInstancedStaticMeshComponent name=ReviveTilesRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		AbsoluteTranslation=true
		AbsoluteRotation=true
		bIgnoreOwnerHidden=true
		TranslucencySortPriority=-1000
		HiddenGame=false
		HiddenEditor=true
		HideDuringCinematicView=true
	end object
	Components.Add(ReviveTilesRenderingComponent0);
	ReviveTilesRenderingComponent = ReviveTilesRenderingComponent0;

	Begin Object Class=X2FadingInstancedStaticMeshComponent name=HuntersMarkTilesRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		AbsoluteTranslation=true
		AbsoluteRotation=true
		bIgnoreOwnerHidden=true
		TranslucencySortPriority=-1000
		HiddenGame=false
		HiddenEditor=true
		HideDuringCinematicView=true
	end object
	Components.Add(HuntersMarkTilesRenderingComponent0);
	HuntersMarkTilesRenderingComponent = HuntersMarkTilesRenderingComponent0;

	Components.Remove(CollisionCylinder)

	Begin Object Class=CylinderComponent Name=UnitCollisionCylinder
		CollisionRadius=30.000000
		CollisionHeight=128.000000
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		CanBlockCamera=false
	End Object

	CollisionComponent=UnitCollisionCylinder
	CylinderComponent=UnitCollisionCylinder
	Components.Add(UnitCollisionCylinder)

	Begin Object Class=XComRenderablePathComponent Name=PathComponent
		iPathLengthOffset=-2
		fRibbonWidth=2
		fEmitterTimeStep=10
		TranslucencySortPriority=100
		bTranslucentIgnoreFOW=true
		PathType=eCU_WithConcealment
	End Object

	RenderablePath=PathComponent
	Components.Add(PathComponent)

	DashLabel="DashLabel"
	SuppressedLabel="SuppressionLabel"

	bCollideActors=FALSE
	bBlockActors=FALSE
	bCollideWorld=FALSE

	GroundSpeed=200
	AirSpeed=200
	MaxStepHeight=26.0f
	WalkableFloorZ=.10f

	ControllerClass=none

	RotationRate=(Pitch=65000,Yaw=65000,Roll=65000)

	Physics=PHYS_None
}
