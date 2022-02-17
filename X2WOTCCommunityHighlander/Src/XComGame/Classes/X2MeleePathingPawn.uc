//---------------------------------------------------------------------------------------
//  FILE:    X2MeleePathingPawn.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Specialized pathing pawn for activated melee pathing. Draws tiles around every unit the 
//           currently selected ability can melee from, and allows the user to select one to move there.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2MeleePathingPawn extends XComPathingPawn
	native(Unit);

var /* private */ XComGameState_Unit UnitState; // The unit we are currently using
var /* private */ XComGameState_Ability AbilityState; // The ability we are currently using
var /* private */ Actor TargetVisualizer; // Visualizer of the current target 
var /* private */ X2TargetingMethod_MeleePath TargetingMethod; // targeting method that spawned this pathing pawn, if any

var /* private */ array<TTile> PossibleTiles; // list of possible tiles to melee from

// Instanced mesh component for the grapple target tile markup
var /* private */ InstancedStaticMeshComponent InstancedMeshComponent;

// adds tiles to the instance mesh component for every tile in the PossibileTiles array
/* private */ native function UpdatePossibleTilesVisuals();

function Init(XComGameState_Unit InUnitState, XComGameState_Ability InAbilityState, X2TargetingMethod_MeleePath InTargetingMethod)
{
	super.SetActive(XGUnitNativeBase(InUnitState.GetVisualizer()));

	UnitState = InUnitState;
	AbilityState = InAbilityState;
	TargetingMethod = InTargetingMethod;

	InstancedMeshComponent.SetStaticMesh(StaticMesh(DynamicLoadObject("UI_3D.Tile.AOETile", class'StaticMesh')));
	InstancedMeshComponent.SetAbsolute(true, true);
}

simulated function SetActive(XGUnitNativeBase kActiveXGUnit, optional bool bCanDash, optional bool bObeyMaxCost)
{
	`assert(false); // call Init() instead
}

// disable the built in pathing melee targeting.
simulated /* protected */ function bool CanUnitMeleeFromMove(XComGameState_BaseObject TargetObject, out XComGameState_Ability MeleeAbility)
{
	return false;
}

function GetTargetMeleePath(out array<TTile> OutPathTiles)
{
	OutPathTiles = PathTiles;
}

// overridden to always just show the slash UI, regardless of cursor location or other considerations
simulated /* protected */ function UpdatePuckVisuals(XComGameState_Unit ActiveUnitState, 
												const out TTile PathDestination, 
												Actor TargetActor,
												X2AbilityTemplate MeleeAbilityTemplate)
{
	local XComWorldData WorldData;
	local XGUnit Unit;
	local vector MeshTranslation;
	local Rotator MeshRotation;	
	local vector MeshScale;
	local vector FromTargetTile;
	local float UnitSize;

	WorldData = `XWORLD;

	// determine target puck size and location
	MeshTranslation = TargetActor.Location;

	Unit = XGUnit(TargetActor);
	if(Unit != none)
	{
		UnitSize = Unit.GetVisualizedGameState().UnitSize;
		MeshTranslation = Unit.GetPawn().CollisionComponent.Bounds.Origin;
	}
	else
	{
		UnitSize = 1.0f;
	}

	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;

	// when slashing, we will technically be out of range. 
	// hide the out of range mesh, show melee mesh
	OutOfRangeMeshComponent.SetHidden(true);
	SlashingMeshComponent.SetHidden(false);
	SlashingMeshComponent.SetTranslation(MeshTranslation);

	// rotate the mesh to face the thing we are slashing
	FromTargetTile = WorldData.GetPositionFromTileCoordinates(PathDestination) - MeshTranslation; 
	MeshRotation.Yaw = atan2(FromTargetTile.Y, FromTargetTile.X) * RadToUnrRot;
		
	SlashingMeshComponent.SetRotation(MeshRotation);
	SlashingMeshComponent.SetScale(UnitSize);
	
	// the normal puck is always visible, and located wherever the unit
	// will actually move to when he executes the move
	PuckMeshComponent.SetHidden(false);
	PuckMeshComponent.SetStaticMeshes(GetMeleePuckMeshForAbility(MeleeAbilityTemplate), PuckMeshConfirmed);
	//<workshop> SMOOTH_TACTICAL_CURSOR AMS 2016/01/22
	//INS:
	PuckMeshCircleComponent.SetHidden(false);
	PuckMeshCircleComponent.SetStaticMesh(GetMeleePuckMeshForAbility(MeleeAbilityTemplate));
	//</workshop>
	if (IsDashing() || ActiveUnitState.NumActionPointsForMoving() == 1)
	{
		RenderablePath.SetMaterial(PathMaterialDashing);
	}
		
	MeshTranslation = VisualPath.GetEndPoint(); // make sure we line up perfectly with the end of the path ribbon
	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;
	PuckMeshComponent.SetTranslation(MeshTranslation);
	//<workshop> SMOOTH_TACTICAL_CURSOR AMS 2016/01/22
	//INS:
	PuckMeshCircleComponent.SetTranslation(MeshTranslation);
	//</workshop>

	MeshScale.X = ActiveUnitState.UnitSize;
	MeshScale.Y = ActiveUnitState.UnitSize;
	MeshScale.Z = 1.0f;
	PuckMeshComponent.SetScale3D(MeshScale);
	//<workshop> SMOOTH_TACTICAL_CURSOR AMS 2016/01/22
	//INS:
	PuckMeshCircleComponent.SetScale3D(MeshScale);
	//</workshop>
}

simulated function UpdateMeleeTarget(XComGameState_BaseObject Target)
{
	local X2AbilityTemplate AbilityTemplate;
	local vector TileLocation;

	//<workshop> Francois' Smooth Cursor AMS 2016/04/07
	//INS:
	local TTile InvalidTile;
	InvalidTile.X = -1;
	InvalidTile.Y = -1;
	InvalidTile.Z = -1;
	//</workshop>

	if(Target == none)
	{
		`Redscreen("X2MeleePathingPawn::UpdateMeleeTarget: Target is none!");
		return;
	}

	TargetVisualizer = Target.GetVisualizer();
	AbilityTemplate = AbilityState.GetMyTemplate();

	PossibleTiles.Length = 0;

	if(class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile(UnitState, Target, AbilityTemplate, PossibleTiles))
	{
		// Start Issue #1084
		// The native `class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile` function
		// gives only one possible attack tile for adjacent targets, so we use our own
		// script logic to add more possible attack tiles for adjacent targets.
		// If there's only one possible melee attack tile and the unit is standing on it,
		// then the target is directly adjacent.
		if (UnitState.UnitSize == 1 && PossibleTiles.Length == 1 && UnitState.TileLocation == PossibleTiles[0])
		{
			UpdatePossibleTilesForAdjacentTarget(Target);
		}
		// End Issue #1084

		// build a path to the default (best) tile
		//<workshop> Francois' Smooth Cursor AMS 2016/04/07
		//WAS:
		//RebuildPathingInformation(PossibleTiles[0], TargetVisualizer, AbilityTemplate);	
		RebuildPathingInformation(PossibleTiles[0], TargetVisualizer, AbilityTemplate, InvalidTile);
		//</workshop>

		// and update the tiles to reflect the new target options
		UpdatePossibleTilesVisuals();

		if(`ISCONTROLLERACTIVE)
		{
			// move the 3D cursor to the new target
			if(`XWORLD.GetFloorPositionForTile(PossibleTiles[0], TileLocation))
			{
				// Single Line for #520
				/// HL-Docs: ref:Bugfixes; issue:520
				/// Controller input now allows choosing melee attack destination tile despite floor differences
				`CURSOR.m_iRequestedFloor = `CURSOR.WorldZToFloor(TargetVisualizer.Location);
				`CURSOR.CursorSetLocation(TileLocation, true, true);
			}
		}
	}
	//<workshop> TACTICAL_CURSOR_PROTOTYPING AMS 2015/12/07
	//INS:
	DoUpdatePuckVisuals(PossibleTiles[0], Target.GetVisualizer(), AbilityTemplate);
	//</workshop>
}

// Start Issue #1084
private function UpdatePossibleTilesForAdjacentTarget(XComGameState_BaseObject Target)
{
	local array<TTile>               TargetTiles; // Array of tiles occupied by the target; these tiles can be attacked by melee.
	local TTile                      TargetTile;
	local array<TTile>               AdjacentTiles;	// Array of tiles adjacent to Target Tiles; the attacking unit can move to these tiles to attack.
	local TTile                      AdjacentTile;
	local XComGameState_Unit         TargetUnit;
	local XComGameState_Destructible TargetObject;
	local XComDestructibleActor      DestructibleActor;
	
	TargetUnit = XComGameState_Unit(Target);
	if (TargetUnit != none)
	{
		GatherTilesOccupiedByUnit(TargetUnit, TargetTiles);
	}
	else
	{
		TargetObject = XComGameState_Destructible(Target);
		if (TargetObject == none)
		{
			`LOG(self.Class.Name @ GetFuncName() @ ":: WARNING, target is not a unit and not a destructible object! Its class is:" @ Target.Class.Name @ ", unable to detect additional tiles to melee attack from. Attacking unit:" @ UnitState.GetFullName());
			return;
		}

		DestructibleActor = XComDestructibleActor(TargetObject.GetVisualizer());
		if (DestructibleActor == none)
		{
			`LOG(self.Class.Name @ GetFuncName() @ ":: WARNING, no visualizer found for destructible object with ID:" @ TargetObject.ObjectID @ ", unable to detect additional tiles to melee attack from. Attacking unit:" @ UnitState.GetFullName());
			return;
		}

		// AssociatedTiles is the array of tiles occupied by the destructible object.
	    // In theory, every tile from that array can be targeted by a melee attack.
		TargetTiles = DestructibleActor.AssociatedTiles;
	}

	// Collect non-duplicate tiles around every Target Tile to see which tiles we can attack from.
	GatherTilesAdjacentToTiles(TargetTiles, AdjacentTiles);

	foreach TargetTiles(TargetTile)
	{
		foreach AdjacentTiles(AdjacentTile)
		{
			if (class'Helpers'.static.FindTileInList(AdjacentTile, PossibleTiles) != INDEX_NONE)
				continue;		
				
			if (class'X2AbilityTarget_MovingMelee'.static.IsValidAttackTile(UnitState, AdjacentTile, TargetTile, ActiveCache))
			{	
				PossibleTiles.AddItem(AdjacentTile);
			}
		}
	}
}

private function GatherTilesOccupiedByUnit(const XComGameState_Unit TargetUnit, out array<TTile> OccupiedTiles)
{	
	local XComWorldData      WorldData;
	local array<TilePosPair> TilePosPairs;
	local TilePosPair        TilePair;
	local Box                VisibilityExtents;

	TargetUnit.GetVisibilityExtents(VisibilityExtents);
	
	WorldData = `XWORLD;
	WorldData.CollectTilesInBox(TilePosPairs, VisibilityExtents.Min, VisibilityExtents.Max);

	foreach TilePosPairs(TilePair)
	{
		OccupiedTiles.AddItem(TilePair.Tile);
	}
}

private function GatherTilesAdjacentToTiles(out array<TTile> TargetTiles, out array<TTile> AdjacentTiles)
{	
	local XComWorldData      WorldData;
	local array<TilePosPair> TilePosPairs;
	local TilePosPair        TilePair;
	local TTile              TargetTile;
	local vector             Minimum;
	local vector             Maximum;
	
	WorldData = `XWORLD;

	// Collect a 3x3 box of tiles around every target tile, excluding duplicates.
	// Melee attacks can happen diagonally upwards or downwards too,
	// so collecting tiles on the same Z level would not be enough.
	foreach TargetTiles(TargetTile)
	{
		Minimum = WorldData.GetPositionFromTileCoordinates(TargetTile);
		Maximum = Minimum;

		Minimum.X -= WorldData.WORLD_StepSize;
		Minimum.Y -= WorldData.WORLD_StepSize;
		Minimum.Z -= WorldData.WORLD_FloorHeight;

		Maximum.X += WorldData.WORLD_StepSize;
		Maximum.Y += WorldData.WORLD_StepSize;
		Maximum.Z += WorldData.WORLD_FloorHeight;

		WorldData.CollectTilesInBox(TilePosPairs, Minimum, Maximum);

		foreach TilePosPairs(TilePair)
		{
			if (class'Helpers'.static.FindTileInList(TilePair.Tile, AdjacentTiles) != INDEX_NONE)
				continue;

			AdjacentTiles.AddItem(TilePair.Tile);
		}
	}
}
// End Issue #1084

// override the tick. Rather than do the normal path update stuff, we just want to see if the user has pointed the mouse
// at any of our other possible tiles
simulated event Tick(float DeltaTime)
{
	local XCom3DCursor Cursor;
	local XComWorldData WorldData;
	local vector CursorLocation;
	local TTile PossibleTile;
	local TTile CursorTile;
	local TTile ClosestTile;
	local X2AbilityTemplate AbilityTemplate;
	local float ClosestTileDistance;
	local float TileDistance;

	local TTile InvalidTile;
	InvalidTile.X = -1;
	InvalidTile.Y = -1;
	InvalidTile.Z = -1;
	
	if(TargetVisualizer == none) 
	{
		return;
	}

	Cursor = `CURSOR;
	WorldData = `XWORLD;

	CursorLocation = Cursor.GetCursorFeetLocation();
	CursorTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);

	// mouse needs to actually highlight a specific tile, controller tabs through them
	if(`ISCONTROLLERACTIVE)
	{
		ClosestTileDistance = -1;

		if(VSizeSq2D(CursorLocation - TargetVisualizer.Location) > 0.1f)
		{
			CursorLocation = TargetVisualizer.Location + (Normal(Cursor.Location - TargetVisualizer.Location) * class'XComWorldData'.const.WORLD_StepSize);
			foreach PossibleTiles(PossibleTile)
			{
				// Single line for #520
				TileDistance = VSizeSq2D(WorldData.GetPositionFromTileCoordinates(PossibleTile) - CursorLocation);
				if(ClosestTileDistance < 0 || TileDistance < ClosestTileDistance)
				{
					ClosestTile = PossibleTile;
					ClosestTileDistance = TileDistance;
				}
			}

			if(ClosestTile != LastDestinationTile)
			{
				AbilityTemplate = AbilityState.GetMyTemplate();
				RebuildPathingInformation(ClosestTile, TargetVisualizer, AbilityTemplate, InvalidTile);
				DoUpdatePuckVisuals(ClosestTile, TargetVisualizer, AbilityTemplate);
				LastDestinationTile = ClosestTile;
				TargetingMethod.TickUpdatedDestinationTile(LastDestinationTile);
			}

			// put the cursor back on the unit
			Cursor.CursorSetLocation(TargetVisualizer.Location, true);
		}
	}
	else
	{
		if(CursorTile != LastDestinationTile)
		{
			foreach PossibleTiles(PossibleTile)
			{
				if(PossibleTile == CursorTile || 
				   // Start Issue #1084
				   // If the cursor is hovering above the tile occupied by the unit, the CursorTile.Z is increased by 1,
				   // so the direct comparison "PossibleTile == CursorTile" will always fail.
				   // So for the possible attack tile occupied by the attacker unit, we compare to cursor's Z location - 1.
				   (PossibleTile == UnitState.TileLocation && CursorTile.X == PossibleTile.X && PossibleTile.Y == CursorTile.Y && PossibleTile.Z == CursorTile.Z - 1)
				   // End issue #1084
				   )
				{
					AbilityTemplate = AbilityState.GetMyTemplate();

					// Start Issue #1084
					// Use PossibleTile instead of CursorTile to properly handle the case 
					// when the cursor hovers over the tile occupied by the attacker unit.
					//RebuildPathingInformation(CursorTile, TargetVisualizer, AbilityTemplate, InvalidTile);
					//LastDestinationTile = CursorTile;
					RebuildPathingInformation(PossibleTile, TargetVisualizer, AbilityTemplate, InvalidTile);
					LastDestinationTile = PossibleTile;
					// End Issue #1084
					TargetingMethod.TickUpdatedDestinationTile(LastDestinationTile);
					break;
				}
			}
		}
	}
}

// don't update objective tiles
function UpdateObjectiveTiles(XComGameState_Unit InActiveUnitState);

defaultproperties
{
	Begin Object Class=InstancedStaticMeshComponent Name=InstancedMeshComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
	End object
	InstancedMeshComponent=InstancedMeshComponent0
	Components.Add(InstancedMeshComponent0)
}