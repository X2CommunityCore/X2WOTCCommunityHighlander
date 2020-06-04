//---------------------------------------------------------------------------------------
//  FILE:    X2TargetingMethod_PathTarget.uc
//  AUTHOR:  David Burchanowski  --  2/3/2016
//  PURPOSE: Targeting method for activated attacks against a path tile. Attacks against
//           a unit should use X2TargetingMethod_MeleePath.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_PathTarget extends X2TargetingMethod;

var /* private*/ X2PathTargetPathingPawn PathingPawn;
var privatewrite XComActionIconManager   IconManager;
var privatewrite XComLevelBorderManager  LevelBorderManager;
var privatewrite XCom3DCursor            Cursor;
var private X2Camera_Midpoint       TargetingCamera;
var private XGUnit					TargetUnit;

// the index of the last available target we were targeting
var private int LastTarget;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local XComPresentationLayer Pres;

	super.Init(InAction, NewTargetIndex);

	Pres = `PRES;

	Cursor = `CURSOR;
	PathingPawn = Cursor.Spawn(class'X2PathTargetPathingPawn', Cursor);
	PathingPawn.SetVisible(true);
	PathingPawn.SetActive(FiringUnit);
	IconManager = Pres.GetActionIconMgr();
	LevelBorderManager = Pres.GetLevelBorderMgr();

	// force the initial updates
	IconManager.ShowIcons(true);
	LevelBorderManager.ShowBorder(true);
	IconManager.UpdateCursorLocation(true);
	LevelBorderManager.UpdateCursorLocation(Cursor.Location, true);
}

function Canceled()
{
	super.Canceled();

	PathingPawn.Destroy();
	IconManager.ShowIcons(false);
	LevelBorderManager.ShowBorder(false);
	ClearTargetedActors();
}

function Committed()
{
	Canceled();
}

function Update(float DeltaTime)
{
	local array<Actor> CurrentlyMarkedTargets;
	local vector NewTargetLocation;
	local array<TTile> Tiles;

	IconManager.UpdateCursorLocation();
	LevelBorderManager.UpdateCursorLocation(Cursor.Location);

	NewTargetLocation = GetPathDestination();
	if(NewTargetLocation != CachedTargetLocation)
	{		
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
		DrawAOETiles(Tiles);
	}

	super.Update(DeltaTime);
}

function bool GetPreAbilityPath(out array<TTile> PathTiles)
{
	PathTiles = PathingPawn.PathTiles;
	return PathTiles.Length > 1;
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	return 'AA_Success';
}

protected function Vector GetPathDestination()
{
	local XComWorldData WorldData;
	local TTile Tile;

	WorldData = `XWORLD;
	if(PathingPawn.PathTiles.Length > 0)
	{
		Tile = PathingPawn.PathTiles[PathingPawn.PathTiles.Length - 1];
	}
	else
	{
		Tile = UnitState.TileLocation;
	}

	return WorldData.GetPositionFromTileCoordinates(Tile);
}

function int GetTargetIndex()
{
	// for some legacy reason this needs to be spcified as 0, even though we are only able to do
	// multi-target damage from a path ending move.
	return 0;
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	TargetLocations.AddItem(GetPathDestination());
}

function bool GetAdditionalTargets(out AvailableTarget AdditionalTargets)
{
	local Vector TargetLocation;

	TargetLocation = GetPathDestination();
	Ability.GatherAdditionalAbilityTargetsForLocation(TargetLocation, AdditionalTargets);

	return true;
}

defaultproperties
{
	ProvidesPath=true
}
