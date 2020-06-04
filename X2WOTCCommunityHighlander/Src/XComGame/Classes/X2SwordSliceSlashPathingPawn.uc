//---------------------------------------------------------------------------------------
//  FILE:    X2SwordSliceSlashPathingPawn.uc
//  AUTHOR:  Kirk Martinez  --  2/12/2016
//  PURPOSE: Specialized pathing pawn for activated slash ability pathing. Allows slash tile
//           to draw on a spot where you can use the slash ability.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 The Workshop Entertainment. All rights reserved.
//---------------------------------------------------------------------------------------

class X2SwordSliceSlashPathingPawn extends XComPathingPawn
	native(Unit);

var /* private */ XComGameState_Unit UnitState; // The unit we are currently using
var /* private */ XComGameState_Ability AbilityState; // The ability we are currently using
var TTile CurrentlySelectedTile;
var array<TTile> DestinationTiles;
var array<TTile> TargetTiles;
var XComGameState_BaseObject CurrentTarget;

function Init(XComGameState_Unit InUnitState, XComGameState_Ability InAbilityState)
{
	super.SetActive(XGUnitNativeBase(InUnitState.GetVisualizer()));

	UnitState = InUnitState;
	AbilityState = InAbilityState;
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
	local vector MeshTranslation;
	local Rotator MeshRotation;	
	local vector MeshScale;
	local vector FromTargetTile;
	local vector PathDestinationPosition;
	local int i;
	//local vector GenUseCaseVector;
	local bool DoesNotMatchPathEndPoint;
	local bool IsValidSlashingSpot;
	local TTile GenUsecaseTile;

	WorldData = `XWORLD;

	RenderablePath.SetHidden(false);
	MeshTranslation = TargetActor.Location + TargetActor.WorldSpaceOffset;
	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;

	
	// when slashing, we will technically be out of range. 
	// hide the out of range mesh, show melee mesh
	// "SlashingMeshComponent" is the arrow that points towards the target
	OutOfRangeMeshComponent.SetHidden(true);
	
	SlashingMeshComponent.SetHidden(false);
	SlashingMeshComponent.SetTranslation(MeshTranslation);

	// rotate the mesh to face the thing we are slashing
	PathDestinationPosition = WorldData.GetPositionFromTileCoordinates(PathDestination);
	FromTargetTile = PathDestinationPosition - MeshTranslation;
	MeshRotation.Yaw = atan2(FromTargetTile.Y, FromTargetTile.X) * RadToUnrRot;
	SlashingMeshComponent.SetRotation(MeshRotation);

	// the normal puck is always visible, and located wherever the unit
	// will actually move to when he executes the move
	
	PuckMeshComponent.SetHidden(false);
	PuckMeshComponent.SetStaticMeshes(GetMeleePuckMeshForAbility(MeleeAbilityTemplate), PuckMeshConfirmed);
	
	if (IsDashing() || ActiveUnitState.NumActionPointsForMoving() == 1)
	{
		RenderablePath.SetMaterial(PathMaterialDashing);
	}
	
	MeshTranslation = VisualPath.GetEndPoint(); // make sure we line up perfectly with the end of the path ribbon
	GenUsecaseTile = WorldData.GetTileCoordinatesFromPosition(MeshTranslation);
	DoesNotMatchPathEndPoint = PathDestination.X != GenUsecaseTile.X || PathDestination.Y != GenUsecaseTile.Y;
	//I need to compare tile positions! :D

	if(!DoesNotMatchPathEndPoint)
	{
		IsValidSlashingSpot = false;
		GenUsecaseTile = WorldData.GetTileCoordinatesFromPosition(PathDestinationPosition);
		//I need to compare mesh cursor tile 
		for(i=0; i<DestinationTiles.Length; ++i)
		{
			if(GenUsecaseTile.X == DestinationTiles[i].X && GenUsecaseTile.Y == DestinationTiles[i].Y)
			{
				IsValidSlashingSpot = true;
				break;
			}
		}
	}

	if(DoesNotMatchPathEndPoint || !IsValidSlashingSpot)
	{
		PuckMeshCircleComponent.SetHidden(true);
		SlashingMeshComponent.SetHidden(true);
		RenderablePath.SetHidden(true);

		//we need to render some kind of
		PuckMeshComponent.SetStaticMeshes(StaticMesh(DynamicLoadObject("UI_3D.CursorSet.S_MovePuck_Blocked", class'StaticMesh'))/*GetMeleePuckMeshForAbility(MeleeAbilityTemplate)*/, PuckMeshConfirmed);
		PathDestinationPosition.Z = WorldData.GetFloorZForPosition(PathDestinationPosition) + PathHeightOffset;
		WorldData.GetFloorTileForPosition(PathDestinationPosition, GenUsecaseTile, true);
		PuckMeshComponent.SetTranslation(PathDestinationPosition);

		AbilityState.CustomCanActivateFlag = false;
	}
	else
	{
		MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;
		PuckMeshComponent.SetTranslation(MeshTranslation);
		AbilityState.CustomCanActivateFlag = true;
	}
	
	OutOfRangeMeshComponent.SetTranslation(MeshTranslation); //delete line
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

//for just moving the cursor/puck around
simulated function UpdateCurrentlySelectedTile(TTile newTile)
{
	local X2AbilityTemplate AbilityTemplate;
	local Actor TargetVisualizer;
	local int i;
	local bool IsInvalidSlashSpot;

	CurrentlySelectedTile = newTile;
	TargetVisualizer = CurrentTarget.GetVisualizer();
	AbilityTemplate = AbilityState.GetMyTemplate();
	IsInvalidSlashSpot = true;

	for(i=0; i<DestinationTiles.Length; ++i)
	{
		if(newTile.X == DestinationTiles[i].X && newTile.Y == DestinationTiles[i].Y)
		{
			IsInvalidSlashSpot = false;
			break;
		}
	}

	if(!IsInvalidSlashSpot)
	{
		DestinationTiles.Length = 0;
		if(class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile(UnitState, CurrentTarget, AbilityTemplate, DestinationTiles))
		{
			RebuildOnlySplinepathingInformation(CurrentlySelectedTile);
		}
	}
	DoUpdatePuckVisuals(CurrentlySelectedTile, TargetVisualizer, AbilityTemplate);
}

simulated function UpdateMoveZone()
{
	//local XComGameState_Unit ActiveUnitState;
	//local array<PathPoint> PathPoints;
	//local array<TTile> WaypointTiles;
	//local float OriginalOriginZ;
	//<workshop> 2K_TACTICAL_PROTOTYPING AMS 2016/02/04
	//INS:
	local XComTacticalController TheCursor;
	//</workshop>

	UpdatePathTileData();		
	UpdateRenderablePath(`CAMERASTACK.GetCameraLocationAndOrientation().Location);

	TheCursor = XComTacticalController(`BATTLE.GetALocalPlayerController());
	RenderablePath.SetHidden(TheCursor.m_bChangedUnitHasntMovedCursor);

	UpdateSpecialTileCacheVisuals(TargetTiles);
	//UpdateBorderHideHeights();
}

//when changing enemy target
simulated function UpdateMeleeTarget(XComGameState_BaseObject Target)
{
	local X2AbilityTemplate AbilityTemplate;
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

	CurrentTarget = Target;
	DestinationTiles.Length = 0;
	TargetTiles.Length = 0;
	AbilityTemplate = AbilityState.GetMyTemplate();
	if(class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile(UnitState, Target, AbilityTemplate, DestinationTiles))
	{
		TargetTiles = DestinationTiles;
		CurrentlySelectedTile = DestinationTiles[0];
		//<workshop> Francois' Smooth Cursor AMS 2016/04/07
		//WAS:
		//RebuildPathingInformation(CurrentlySelectedTile, Target.GetVisualizer(), AbilityTemplate);
		RebuildPathingInformation(CurrentlySelectedTile, Target.GetVisualizer(), AbilityTemplate, InvalidTile);
		//</workshop>
		UpdateMoveZone();
	}

	//<workshop> TACTICAL_CURSOR_PROTOTYPING AMS 2015/12/07
	//INS:
	DoUpdatePuckVisuals(CurrentlySelectedTile, Target.GetVisualizer(), AbilityTemplate);
	//</workshop>
}

simulated event Tick(float DeltaTime)
{
	// we don't need to tick, we'll update the pathing stuff manually with UpdateMeleeTarget when the target changes
}

// don't update objective tiles
function UpdateObjectiveTiles(XComGameState_Unit InActiveUnitState);

defaultproperties
{}