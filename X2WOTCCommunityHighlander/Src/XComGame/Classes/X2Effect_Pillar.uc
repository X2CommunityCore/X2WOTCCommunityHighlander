class X2Effect_Pillar extends X2Effect_SpawnDestructible;

function int GetStartingNumTurns(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit SourceUnit;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	return SourceUnit.GetTemplarFocusLevel();
}

// Start Issue #1288
/// HL-Docs: ref:Bugfixes; issue:1288
/// Update tile data for all adjacent units when the Pillar is spawned or expires to make the cover change update immediately.
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local Vector Position;
	local TTile  TileLocation;	

	`LOG("Pillar effect applied to:" @ XComGameState_Unit(kNewTargetState).GetFullName() @ "num target locations:" @ ApplyEffectParameters.AbilityInputContext.TargetLocations.Length,, 'IRITEST');

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	if (ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0)
	{
		Position = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
		TileLocation = `XWORLD.GetTileCoordinatesFromPosition(Position);
		UpdateWorldDataForTile(TileLocation, NewGameState);
	}
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local Vector	Position;
	local TTile		TileLocation;	

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	if (ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0)
	{
		Position = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
		TileLocation = `XWORLD.GetTileCoordinatesFromPosition(Position);
		UpdateWorldDataForTile(TileLocation, NewGameState);
	}
}

static private function GetTilesAdjacentToTile(TTile Tile, out array<TTile> Tiles)
{
	Tiles.AddItem(Tile);

	Tile.X -= 1;
	Tiles.AddItem(Tile);

	Tile.X += 2;
	Tiles.AddItem(Tile);

	Tile.X -= 1;
	Tile.Y -= 1;
	Tiles.AddItem(Tile);

	Tile.Y += 2;
	Tiles.AddItem(Tile);
}

static private function UpdateWorldDataForTile(const out TTile PillarTile, XComGameState NewGameState)
{
	local XComGameStateHistory        History;
	local XComWorldData               WorldData;
	local TTile                       RebuildTile;
	local array<TTile>                AdjacentTiles;
	local array<StateObjectReference> UnitRefs;
	local StateObjectReference        UnitRef;
	local XComGameState_BaseObject    UnitOnTile;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	WorldData.UpdateTileDataCache(NewGameState,, true);
	//WorldData.FlushCachedVisibility();

	`LOG("Updating data for target tile:" @ PillarTile.X @ PillarTile.Y @ PillarTile.Z,, 'IRITEST');

	GetTilesAdjacentToTile(PillarTile, AdjacentTiles);

	`LOG("Got adjacent tiles:" @ AdjacentTiles.Length,, 'IRITEST');

	foreach AdjacentTiles(RebuildTile)
	{
		`LOG("Rebuilding tile:" @ RebuildTile.X @ RebuildTile.Y @ RebuildTile.Z,, 'IRITEST');

		WorldData.DebugRebuildTileData(RebuildTile);
		WorldData.ClearVisibilityDataAroundTile(RebuildTile);

		UnitRefs = WorldData.GetUnitsOnTile(RebuildTile);

		`LOG("Num units on tile:" @ UnitRefs.Length,, 'IRITEST');

		foreach UnitRefs(UnitRef)
		{
			UnitOnTile = History.GetGameStateForObjectID(UnitRef.ObjectID);
			`LOG("Unit on tile:" @ XComGameState_Unit(UnitOnTile).GetFullName(),, 'IRITEST');
			if (UnitOnTile == none)
				continue;

			UnitOnTile = NewGameState.ModifyStateObject(UnitOnTile.Class, UnitOnTile.ObjectID);
			UnitOnTile.bRequiresVisibilityUpdate = true;

			`LOG("Unit requires visibility update",, 'IRITEST');
		}
	}

	WorldData.FlushCachedVisibility();
	WorldData.ForceUpdateAllFOWViewers();
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle(); //Force all visualizers to update their visualization state
	`PRES.m_kTacticalHUD.ForceUpdate(-1);
}
// End Issue #1288

DefaultProperties
{
	EffectName = "Pillar"
	DuplicateResponse = eDupe_Allow
	bDestroyOnRemoval = true
}
