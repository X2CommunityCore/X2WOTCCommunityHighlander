//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2TargetingMethod_EvacZone.uc
//  AUTHOR:  Josh Bouscher
//  PURPOSE: Targeting method for placing an evac zone
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2TargetingMethod_EvacZone extends X2TargetingMethod native(Core) config(GameCore);

var config float NeededValidTileCoverage;

var private XCom3DCursor Cursor;
var private X2Actor_EvacZoneTarget EvacZoneTarget;
var private bool bRestrictToSquadsightRange;
var private XComGameState_Player AssociatedPlayerState;
var private bool EnoughTilesValid;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local XComGameStateHistory History;
	local float TargetingRange;
	local X2AbilityTarget_Cursor CursorTarget;

	super.Init(InAction, NewTargetIndex);

	History = `XCOMHISTORY;

	// get the firing unit
	AssociatedPlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
	`assert(AssociatedPlayerState != none);

	// determine our targeting range
	TargetingRange = Ability.GetAbilityCursorRangeMeters();

	// lock the cursor to that range
	Cursor = `Cursor;
	Cursor.m_fMaxChainedDistance = `METERSTOUNITS(TargetingRange);

	CursorTarget = X2AbilityTarget_Cursor(Ability.GetMyTemplate().AbilityTargetStyle);
	if (CursorTarget != none)
		bRestrictToSquadsightRange = CursorTarget.bRestrictToSquadsightRange;

	// setup the evac mesh
	EvacZoneTarget = `BATTLE.Spawn(class'X2Actor_EvacZoneTarget');
	EvacZoneTarget.ShowBadMesh();       //  show as bad until we verify a good location
	EnoughTilesValid = false;
}

function Canceled()
{
	// unlock the 3d cursor
	Cursor.m_fMaxChainedDistance = -1;

	EvacZoneTarget.Destroy();	
}

function Committed()
{
	Canceled();
}

function Update(float DeltaTime)
{
	local XComWorldData WorldData;
	local vector NewTargetLocation;
	local TTile CursorTile;

	WorldData = `XWORLD;

	// snap the evac origin to the tile the cursor is in
	NewTargetLocation = Cursor.GetCursorFeetLocation();
	WorldData.GetFloorTileForPosition(NewTargetLocation, CursorTile);
	NewTargetLocation = WorldData.GetPositionFromTileCoordinates(CursorTile);
	NewTargetLocation.Z = WorldData.GetFloorZForPosition(NewTargetLocation);

	if(NewTargetLocation != CachedTargetLocation)
	{
		EvacZoneTarget.SetLocation(NewTargetLocation);
		EvacZoneTarget.SetRotation( rot(0,0,1) );
		CachedTargetLocation = NewTargetLocation;

		EnoughTilesValid = ValidateEvacArea( CursorTile, true );
		if (EnoughTilesValid)
		{
			EvacZoneTarget.ShowGoodMesh( );
		}
		else
		{
			EvacZoneTarget.ShowBadMesh( );
		}
	}
}

static native function bool ValidateEvacTile(const out TTile EvacLoc, out int IsOnFloor, bool IgnoreVerticalClearance = false);

static function bool ValidateEvacArea( const out TTile EvacCenterLoc, bool IncludeSoldiers )
{
	local TTile EvacMin, EvacMax, TestTile;
	local int NumTiles, NumValidTiles;
	local int IsOnFloor;

	class'XComGameState_EvacZone'.static.GetEvacMinMax2D( EvacCenterLoc, EvacMin, EvacMax );

	if( IncludeSoldiers && EvacZoneContainsXComUnit(EvacMin, EvacMax) )
	{
		return false;
	}

	NumTiles = (EvacMax.X - EvacMin.X + 1) * (EvacMax.Y - EvacMin.Y + 1);

	TestTile = EvacMin;
	while (TestTile.X <= EvacMax.X)
	{
		while (TestTile.Y <= EvacMax.Y)
		{
			if (ValidateEvacTile( TestTile, IsOnFloor ))
			{
				NumValidTiles++;
			}
			else if(IsOnFloor == 0)
			{
				return false; // we can't have the evac zone floating in the air
			}

			TestTile.Y++;
		}

		TestTile.Y = EvacMin.Y;
		TestTile.X++;
	}

	return (NumValidTiles / float( NumTiles )) >= default.NeededValidTileCoverage;
}

static function bool EvacZoneContainsXComUnit(const out TTile EvacMin, const out TTile EvacMax)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference SquadRef;
	local XComGameState_Unit XComUnitState;
	local TTile UnitTileLocation;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach XComHQ.Squad(SquadRef)
	{
		XComUnitState = XComGameState_Unit(History.GetGameStateForObjectID(SquadRef.ObjectID));

		if( !XComUnitState.bRemovedFromPlay )
		{
			XComUnitState.GetKeystoneVisibilityLocation(UnitTileLocation);

			if( UnitTileLocation.X >= EvacMin.X &&
			   UnitTileLocation.Y >= EvacMin.Y &&
			   UnitTileLocation.Z >= EvacMin.Z &&
			   UnitTileLocation.X <= EvacMax.X &&
			   UnitTileLocation.Y <= EvacMax.Y &&
			   UnitTileLocation.Z <= EvacMax.Z )
			{
				return true;
			}
		}
	}

	return false;
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	TargetLocations.Length = 0;
	TargetLocations.AddItem(Cursor.GetCursorFeetLocation());
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	local TTile TestLoc;
	if (TargetLocations.Length == 1)
	{
		if (bRestrictToSquadsightRange)
		{
			TestLoc = `XWORLD.GetTileCoordinatesFromPosition(TargetLocations[0]);
			if (!class'X2TacticalVisibilityHelpers'.static.CanSquadSeeLocation(AssociatedPlayerState.ObjectID, TestLoc))
				return 'AA_NotVisible';
		}
		if (!EnoughTilesValid)
		{
			return 'AA_TileIsBlocked';
		}

		return 'AA_Success';			
	}
	return 'AA_NoTargets';
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	Focus = Cursor.GetCursorFeetLocation();
	return true;
}