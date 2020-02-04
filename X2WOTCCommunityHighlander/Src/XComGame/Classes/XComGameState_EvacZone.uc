//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComGameState_EvacZone.uc
//  AUTHOR:  Josh Bouscher, David Burchanowski
//  PURPOSE: Game state object to track the evac zone
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComGameState_EvacZone extends XComGameState_BaseObject 
	implements(X2VisualizedInterface)
	native(Core) 
	config(GameCore);

var private const config string DefaultEvacBlueprintMapName;

var() const config int PositiveXDimension;
var() const config int PositiveYDimension;
var() const config int NegativeXDimension;
var() const config int NegativeYDimension;

// Start Issue #702
var() TTile CenterLocation;
var() ETeam Team;
// End Issue #702

// if specified, will use this map instead of the default evac zone map
var() string BlueprintMapOverride;

var() bool bMissionPlaced;

static function XComGameState_EvacZone PlaceEvacZone(XComGameState NewGameState, Vector SpawnLocation, optional ETeam InTeam = eTeam_XCom, optional string InBlueprintMapOverride)
{
	local XComWorldData WorldData;

	local XComGameState_EvacZone EvacState;
	local TTile SpawnTile;

	WorldData = `XWORLD;

	EvacState = GetEvacZone(InTeam);
	if (EvacState == none)
	{
		EvacState = XComGameState_EvacZone(NewGameState.CreateNewStateObject(class'XComGameState_EvacZone'));
		EvacState.Team = InTeam;
	}
	else
	{
		EvacState = XComGameState_EvacZone(NewGameState.ModifyStateObject(EvacState.Class, EvacState.ObjectID));
	}

	// try to put the zone squarely on the floor. If that isn't possible, then as a backup put it 
	// at the requested location
	if(!WorldData.GetFloorTileForPosition(SpawnLocation, SpawnTile))
	{
		`Redscreen("PlaceEvacZone(): Unable to place evac zone on the floor. It may not function");
		SpawnTile = WorldData.GetTileCoordinatesFromPosition(SpawnLocation);
	}

	EvacState.BlueprintMapOverride = InBlueprintMapOverride;
	EvacState.SetCenterLocation(SpawnTile);

	class'XComGameState_BattleData'.static.SetGlobalAbilityEnabled('Evac', true, NewGameState);

	`XEVENTMGR.TriggerEvent('EvacZonePlaced', EvacState, EvacState, NewGameState);

	return EvacState;
}

static function XComGameState_EvacZone GetEvacZone(optional ETeam InTeam = eTeam_XCom)
{
	local XComGameState_EvacZone EvacState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_EvacZone', EvacState)
	{
		if(EvacState.Team == InTeam)
		{
			return EvacState;
		}
	}

	return none;
}

function string GetEvacZoneBlueprintMap()
{
	return BlueprintMapOverride != "" ? BlueprintMapOverride : DefaultEvacBlueprintMapName;
}

function SetCenterLocation(TTile TileLoc)
{
	CenterLocation = TileLoc;
}

static function GetEvacMinMax2D( TTile CenterLoc, out TTile TileMin, out TTile TileMax )
{
	TileMin = CenterLoc;
	TileMax = CenterLoc;

	TileMin.X -= default.NegativeXDimension;
	TileMin.Y -= default.NegativeYDimension;

	TileMax.X += default.PositiveXDimension;
	TileMax.Y += default.PositiveYDimension;
}

static function GetEvacMinMax( TTile CenterLoc, out TTile TileMin, out TTile TileMax )
{
	GetEvacMinMax2D( CenterLoc, TileMin, TileMax );

	if (TileMin.Z > 0)
	{
		TileMin.Z--;
	}

	if (TileMax.Z < `XWORLD.NumZ - 1)
	{
		TileMax.Z++;
	}
}

function bool IsUnitInEvacZone(XComGameState_Unit UnitState)
{
	local TTile UnitTile, Min, Max;
	local int IsOnFloor;

	GetEvacMinMax( CenterLocation, Min, Max );
	UnitTile = UnitState.TileLocation;

	if (UnitTile.X < Min.X || UnitTile.X > Max.X)
		return false;
	if (UnitTile.Y < Min.Y || UnitTile.Y > Max.Y)
		return false;
	if (UnitTile.Z < Min.Z || UnitTile.Z > Max.Z)
		return false;

	if (!class'X2TargetingMethod_EvacZone'.static.ValidateEvacTile( UnitTile, IsOnFloor, bMissionPlaced ))
	{
		return false;
	}

	return true;
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	local X2Actor_EvacZone EvacZoneActor;

	// if the evac zone already exists. Destroy it. We need to rebuild the blueprint
	EvacZoneActor = X2Actor_EvacZone( GetVisualizer( ) );
	if (EvacZoneActor != none)
	{
		EvacZoneActor.Destroy( );
	}

	EvacZoneActor = `BATTLE.Spawn( class'X2Actor_EvacZone' );
	`XCOMHISTORY.SetVisualizer( ObjectID, EvacZoneActor );

	return EvacZoneActor;
}

function SyncVisualizer(optional XComGameState GameState = none)
{
	local X2Actor_EvacZone EvacZoneActor;

	EvacZoneActor = X2Actor_EvacZone( GetVisualizer( ) );

	// and then init it
	EvacZoneActor.InitEvacZone(self);
}

function AppendAdditionalSyncActions( out VisualizationActionMetadata ActionMetadata, const XComGameStateContext Context)
{
}

DefaultProperties
{
	bTacticalTransient=true
	Team=eTeam_XCom
}
