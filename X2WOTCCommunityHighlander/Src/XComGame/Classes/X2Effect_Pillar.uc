class X2Effect_Pillar extends X2Effect_SpawnDestructible;

function int GetStartingNumTurns(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit SourceUnit;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	return SourceUnit.GetTemplarFocusLevel();
}

// Start Issue #1288
/// HL-Docs: ref:Bugfixes; issue:1288
/// Utilised updated OnEffectAdded and OnEffectRemoved functions to update unit data on all units in range of the spawend destructible
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local Vector	Position;
	local TTile		TileLocation;	

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	Position = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
	TileLocation = `XWORLD.GetTileCoordinatesFromPosition(Position);

	// After the destructible is spawned, perform an update to all of the units within range of the destructible
	UpdateWorldDataForTile(TileLocation, NewGameState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local Vector	Position;
	local TTile		TileLocation;	

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	Position = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
	TileLocation = `XWORLD.GetTileCoordinatesFromPosition(Position);

	// After the destructible is removed, perform an update to all of the units within range of the destructible
	UpdateWorldDataForTile(TileLocation, NewGameState);
}

// helper to get the 3x3 cross of tiles around the specified tile
protected static function GetUpdateTiles(TTile Tile, out array<TTile> Tiles)
{
	// center tile
	Tiles.AddItem(Tile);

	// adjacent x tiles
	Tile.X -= 1;
	Tiles.AddItem(Tile);
	Tile.X += 2;
	Tiles.AddItem(Tile);
	Tile.X -= 1;

	// adjacent y tiles
	Tile.Y -= 1;
	Tiles.AddItem(Tile);
	Tile.Y += 2;
	Tiles.AddItem(Tile);
}

protected static function UpdateWorldDataForTile(const out TTile OriginalTile, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local TTile RebuildTile;
	local array<TTile> ChangeTiles;
	local array<StateObjectReference> UnitRefs;
	local StateObjectReference UnitRef;
	local XComGameState_BaseObject UnitOnTile;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	GetUpdateTiles(OriginalTile, ChangeTiles);

	// update the world data for each tile touched
	foreach ChangeTiles(RebuildTile)
	{
		WorldData.DebugRebuildTileData( RebuildTile );
	}

	// add any units on the tiles to the new game state since they need to do a visibility update
	foreach ChangeTiles(RebuildTile)
	{
		UnitRefs = WorldData.GetUnitsOnTile( RebuildTile );
		foreach UnitRefs( UnitRef )
		{
			UnitOnTile = History.GetGameStateForObjectID(UnitRef.ObjectID);
			UnitOnTile = NewGameState.ModifyStateObject(UnitOnTile.Class, UnitOnTile.ObjectID);
			UnitOnTile.bRequiresVisibilityUpdate = true;
		}
	}
}

// End Issue #1288

DefaultProperties
{
	EffectName = "Pillar"
	DuplicateResponse = eDupe_Allow
	bDestroyOnRemoval = true
}
