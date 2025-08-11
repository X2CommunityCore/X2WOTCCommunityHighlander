//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_FollowMouseCursor.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Simple camera that just tracks the 3d cursor in mouse mode. The default.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_FollowMouseCursor extends X2Camera_Lookat
	config(Camera);

// the location this camera currently wants to look at
var protected Vector LookAt;

// track scroll input separately, so we can apply it at a higher rate than the normal interpolation
var private Vector RemainingEdgeScroll;

// Is the camera in the process of centering on a unit.
var private bool IsCenteringOnUnit;

var private bool HasStoredMouseCoords;
var private Vector2D StoredMouseCoordsAfterCentering;
var private float EnablePathingDistance;
var private bool MoveAbilitySubmitted;	// Was a move ability just submitted
var private XComGameState_Unit LastPlayerControlledUnit;

// Holds the previous cameras vis focus points. Used during alien (non player) turns to prevent vis poping, as this camera is the default camera in between camera shots.
var private array<TFocusPoints> PreviousCamerasVisFocusPoints;

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	local XComGameStateHistory History;
	local XComTacticalController LocalController;
	local XComGameState_Unit ActiveUnit;
	local XCom3DCursor Cursor;
	local X2EventManager EventManager;
	local Object ThisObj;

	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	if (PreviousActiveCamera != none)
	{
		PreviousActiveCamera.GetCameraFocusPoints(PreviousCamerasVisFocusPoints);
	}
	else
	{
		PreviousCamerasVisFocusPoints.Length = 0;
	}

	// kill any leftover scroll amount
	RemainingEdgeScroll.X = 0;
	RemainingEdgeScroll.Y = 0;

	LocalController = XComTacticalController(`BATTLE.GetALocalPlayerController());

	if (LastActiveLookAtCamera != none && LocalController != none && LocalController.bManuallySwitchedUnitsWhileVisualizerBusy == false)
	{
		// make our desired look at the same as the previous look at point, we don't do this if have just manually switched units so the lookat tranitions to the new unit
		LookAt = LastActiveLookAtCamera.GetCameraLookat();
	}

	// scroll to the currently active unit if it is offscreen and it's the human player's turn and the visualizer is idle
	if(!class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
	{
		History = `XCOMHISTORY;
		ActiveUnit = XComGameState_Unit(History.GetGameStateForObjectID(LocalController.GetActiveUnitStateRef().ObjectID));
		if(ActiveUnit != none 
			&& !ActiveUnit.ControllingPlayerIsAI() 
			&& ActiveUnit.ControllingPlayer == GetActivePlayer())
		{
			CenterOnUnitIfOffscreen(ActiveUnit);
		}
	}

	if(X2Camera_OTSTargeting(PreviousActiveCamera) != none)
	{
		// when returning from a targeting camera, snap the camera to the unit lookat from
		// the get go so we don't blend and interpolate at the same time.
		CurrentLookAt = GetCameraLookat();
	}
	
	// whenever we get control back, set the 3D cursor's pathing floor to be the floor we are looking at
	Cursor = `CURSOR;
	Cursor.m_iRequestedFloor = Cursor.WorldZToFloor(LookAt);
	Cursor.m_iLastEffectiveFloorIndex = Cursor.m_iRequestedFloor;

	MoveAbilitySubmitted = false;

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'CameraFocusActiveUnit', OnCameraFocusUnit, ELD_Immediate);
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_Immediate, , );
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnEnded', OnTurnEnded, ELD_OnVisualizationBlockStarted, , );
}

function Deactivated()
{
 	local Object ThisObj;

 	ThisObj = self;
	`XEVENTMGR.UnRegisterFromAllEvents(ThisObj);
}

function EventListenerReturn OnCameraFocusUnit(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComTacticalController LocalController;
	local XComGameStateHistory History;
	local XComGameState_Unit ActiveUnit;

	LocalController = XComTacticalController(`BATTLE.GetALocalPlayerController());
	if(LocalController != none && !class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
	{
		History = `XCOMHISTORY;
		ActiveUnit = XComGameState_Unit(History.GetGameStateForObjectID(LocalController.GetActiveUnitStateRef().ObjectID));
		if(ActiveUnit != none 
			&& !ActiveUnit.ControllingPlayerIsAI() 
			&& ActiveUnit.ControllingPlayer == GetActivePlayer())
		{
			CenterOnUnitIfOffscreen(ActiveUnit);
		}
	}

	return ELR_NoInterrupt;
}

function StateObjectReference GetActivePlayer()
{
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule Context;
	local  StateObjectReference NullReference;

	History = `XCOMHISTORY;

	foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
	{
		if(Context.GameRuleType == eGameRule_PlayerTurnBegin) 
		{
			return Context.PlayerRef;
		}
	}

	return NullReference;
}

private function bool ShouldScrollCamera()
{
	local XComGameStateVisualizationMgr VisManager;

	if(!`XENGINE.IsMultiplayerGame())
	{
		if((`TACTICALRULES.GetUnitActionTeam() != eTeam_XCom) && (`CHEATMGR == None || !`CHEATMGR.bAllowSelectAll) && (`REPLAY == none || !`REPLAY.bInReplay))
		{
			return false; // no scrolling during the alien turn
		}
	}

	VisManager = `XCOMVISUALIZATIONMGR;

	if( VisManager.VisualizerBusy() && 
		(VisManager.VisualizationTree == none || !VisManager.VisualizationTree.bNewUnitSelected) )
	{
		return false; // no scrolling during visualizations unless quick selecting (tab select) new unit
	}

	return true;
}

// Internal helper for normal and raw scrolling. Immediate == true will disable any smoothing
private function InternalScrollCamera(Vector2D Offset, bool Immediate)
{
	local float YawInRadians;
	local float CosYaw;
	local float SinYaw;
	local Vector Delta;

	if( !ShouldScrollCamera() )
	{
		return;
	}

	YawInRadians = UnrRotToRad * CurrentRotation.Yaw;
	CosYaw = Cos(YawInRadians);
	SinYaw = Sin(YawInRadians);

	// note that X and Y are flipped because the offset is in screen space and at yaw=0 degrees "up" 
	// in screen space looks down the world y axis
	Delta.X = Offset.Y * CosYaw + Offset.X * -SinYaw;
	Delta.Y = Offset.Y * SinYaw + Offset.X * CosYaw;
	LookAt += Delta;

	if(Immediate)
	{
		CurrentLookAt += Delta;
	}

	IsCenteringOnUnit = false;
}

function ScrollCamera(Vector2D Offset)
{
	InternalScrollCamera(Offset, false);
}

/// <summary>
/// Notifies the camera that the user is attempting to scroll without smoothing
/// </summary>
function RawScrollCamera(Vector2D Offset)
{
	InternalScrollCamera(Offset, true);
}

function EdgeScrollCamera(Vector2D Offset)
{
	local float YawInRadians;
	local float CosYaw;
	local float SinYaw;
	local Vector Delta;

	if( !ShouldScrollCamera() )
	{
		return;
	}

	YawInRadians = UnrRotToRad * CurrentRotation.Yaw;
	CosYaw = Cos(YawInRadians);
	SinYaw = Sin(YawInRadians);

	// note that X and Y are flipped because the offset is in screen space and at yaw=0 degrees "up" 
	// in screen space looks down the world y axis
	Delta.X = Offset.Y * CosYaw + Offset.X * -SinYaw;
	Delta.Y = Offset.Y * SinYaw + Offset.X * CosYaw;
	RemainingEdgeScroll += Delta;

	IsCenteringOnUnit = false;
}

function UpdateCamera(float DeltaTime)
{
	local float RemainingScrollBrakeAlpha;
	local Vector UsedScrollDelta;

	super.UpdateCamera(DeltaTime);

	// If we're close to our destination, store the current mouse coordinates so we can check how much the mouse has moved before enabling pathing line
	if (!HasStoredMouseCoords && bCameraIsMoving && CameraIsCloseToDestination(EnablePathingDistance))
	{
		`PRES.GetMouseCoords(StoredMouseCoordsAfterCentering);
		HasStoredMouseCoords = true;
	}

	if (bCameraIsMoving == false && IsCenteringOnUnit)
	{
		IsCenteringOnUnit = false;
		if (!HasStoredMouseCoords)
		{
			`PRES.GetMouseCoords(StoredMouseCoordsAfterCentering);
			HasStoredMouseCoords = true;
		}
	}

	// add in more of the edge scroll input if we have some. this allows us to skip ramp up on the edge scroll,
	// which is much more pc-esque
	RemainingScrollBrakeAlpha = ComputeLocationBrakeAlpha(VSize(RemainingEdgeScroll));
	if(RemainingScrollBrakeAlpha > 0.01f) // only until we are almost there, or we may never arrive due to numerical limits
	{
		UsedScrollDelta = RemainingScrollBrakeAlpha * RemainingEdgeScroll;

		LookAt += UsedScrollDelta;
		CurrentLookAt += UsedScrollDelta;
		RemainingEdgeScroll -= UsedScrollDelta;
	}

	ClampLookAtToWorldBounds();
}

protected function ClampLookAtToWorldBounds()
{
	local XComWorldData WorldData;
	local vector BoundsMin;
	local vector BoundsMax;
	local vector VerticalBuffer;

	// clamp the lookat point to the level bounds (with some vertical buffer to account for camera floor adjustments,
	// we just need to keep it from completely falling out of the level)
	WorldData = `XWORLD;
	VerticalBuffer.Z = class'XComWorldData'.const.WORLD_FloorHeight * 3;
	BoundsMin = WorldData.Volume.CollisionComponent.Bounds.Origin - WorldData.Volume.CollisionComponent.Bounds.BoxExtent - VerticalBuffer;
	BoundsMax = WorldData.Volume.CollisionComponent.Bounds.Origin + WorldData.Volume.CollisionComponent.Bounds.BoxExtent + VerticalBuffer;
	LookAt.X = FClamp(LookAt.X, BoundsMin.X, BoundsMax.X);
	LookAt.Y = FClamp(LookAt.Y, BoundsMin.Y, BoundsMax.Y);
	CurrentLookAt.X = FClamp(CurrentLookAt.X, BoundsMin.X, BoundsMax.X);
	CurrentLookAt.Y = FClamp(CurrentLookAt.Y, BoundsMin.Y, BoundsMax.Y);
}

protected function Vector GetCameraLookat()
{
	local Vector Result;
	local XCom3DCursor Cursor;

	Cursor = `CURSOR;

	Result = LookAt;
	Result.Z = Cursor.GetFloorMinZ(Cursor.m_iLastEffectiveFloorIndex);
	return Result;
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	super.OnActiveUnitChanged(NewActiveUnit);

	MoveAbilitySubmitted = false;

	if( NewActiveUnit.IsPlayerControlled() )
	{
		CenterOnUnitIfOffscreen(NewActiveUnit);
		LastPlayerControlledUnit = NewActiveUnit;
	}
	else
	{
		CenterOnUnitIfOffscreen(LastPlayerControlledUnit);
	}
}

function EventListenerReturn OnTurnEnded(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	CenterOnUnitIfOffscreen(LastPlayerControlledUnit);

	return ELR_NoInterrupt;
}

private function CenterOnUnitIfOffscreen(XComGameState_Unit Unit)
{
	local XComPresentationLayer Pres;
	local Vector UnitLocation;
	local XCom3DCursor Cursor;
	local int UnitFloor;

	if(Unit == none) return;

	Pres = `PRES;
	if(Pres.GetTacticalHUD().IsMenuRaised())
	{
		return;
	}

	if(Pres.m_kTacticalHUD.m_kAbilityHUD.TargetingMethod != none)
	{
		return;
	}

	Cursor = `CURSOR;

	// snap the lookat to the bottom of the current unit's floor. Smooths out small bumps
	// and vertical motions his root makes.
	UnitLocation = Unit.GetVisualizer().Location;
	UnitFloor = Cursor.WorldZToFloor(UnitLocation);
	UnitLocation.Z = Cursor.GetFloorMinZ(UnitFloor);

	LookAt = UnitLocation;
	IsCenteringOnUnit = true;
	HasStoredMouseCoords = false;
}

function bool DisableFocusPointExpiration()
{
	return !CameraIsCloseToDestination(EnablePathingDistance) || bCameraIsRotating || bCameraIsZooming || MoveAbilitySubmitted;
}

function bool HidePathing()
{
	local Vector2D CurrentMouseCoords, vDiff;

	return false; // Per Dan K we don't want to remove pathing information based on the camera and i couldn't think of a reason to refute

	if (HasStoredMouseCoords)
	{
		if (!IsCenteringOnUnit || (IsCenteringOnUnit && CameraIsCloseToDestination(EnablePathingDistance)))
		{
			`PRES.GetMouseCoords(CurrentMouseCoords);
			vDiff = CurrentMouseCoords - StoredMouseCoordsAfterCentering;

			if (vDiff.X*vDiff.X + vDiff.Y*vDiff.Y > 2)
			{
				return false;
			}

			return true;
		}
	}

	return true;
}

function bool HidePathingBorder()
{
	return false; // Per Dan K we don't want to remove pathing information based on the camera and i couldn't think of a reason to refute
	//return !CameraIsCloseToDestination(EnablePathingDistance);
}

function bool CameraIsCloseToDestination(float Dist)
{
	local Vector NewLookAt;
	local Vector LookAtDelta;
	local float DeltaLength;

	NewLookAt = GetCameraLookAt();
	LookAtDelta = NewLookAt - CurrentLookAt;
	DeltaLength = VSize(LookAtDelta);

	if (DeltaLength > Dist)
	{
		return false;
	}
	else
	{
		return true;
	}
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none) 
	{
		if (AbilityContext.InputContext.AbilityTemplateName == 'StandardMove')
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
			if (UnitState != none && !UnitState.ControllingPlayerIsAI() && UnitState.ControllingPlayer == GetActivePlayer())
			{
				// A move action was just submitted, will cause disabling of focuspointexpiry so building vis doesnt fluctuate
				//while we are waiting for the camera to switch to the follow moving unit camera
				MoveAbilitySubmitted = true;
			}
		}
	}
	return ELR_NoInterrupt;
}

function AddCameraFocusPoints()
{
	local XCom3DCursor Cursor;
	local XComTacticalController TacticalController;
	local XComPawn ActivePawn;
	local vector Offset;
	local TPOV CameraPOV;
	local bool bIgnoreCursor;
	local TFocusPoints FocusPoint;
	local Plane FloorPlane;
	local vector ProjectedPoint;
	local vector CameraToCursorNoZ;
	local vector CursorLocation;
	local bool bDisableExpiration;
	local Vector NewLookAt;
	local Vector LookAtDelta;
	local float FinalDistanceFromPoint;

	bDisableExpiration = DisableFocusPointExpiration();

	Cursor = `CURSOR;
	bIgnoreCursor = false;

	CameraPOV = GetCameraLocationAndOrientation();
	FocusPoint.vCameraLocation = CameraPOV.Location;

	TacticalController = XComTacticalController(`LEVEL.GetALocalPlayerController());
	ActivePawn = TacticalController.GetActivePawn();

	// the cursor location (the thing the user is pointing at) is of interest	
	if (Cursor != none && bIgnoreCursor == false)
	{
		FloorPlane.X = 0;
		FloorPlane.Y = 0;
		FloorPlane.Z = 1.0;
		FloorPlane.W = Cursor.m_fLogicalCameraFloorHeight + 1; // Offset to ensure in proper volume if needed;

		Offset = vect(0, 0, 0);
		Offset.Z = Cursor.CollisionComponent.Bounds.BoxExtent.Z;

		CursorLocation = Cursor.Location - Offset;

		NewLookAt = GetCameraLookAt();
		FinalDistanceFromPoint = Lerp(DistanceFromCursor, ZoomedDistanceFromCursor, TargetZoom);
		CameraPOV.Location = NewLookAt - (Vector(TargetRotation) * FinalDistanceFromPoint);

		if (bDisableExpiration)
		{

			LookAtDelta = NewLookAt - CurrentLookAt;
			CursorLocation += LookAtDelta;			
		}

		CameraToCursorNoZ = CursorLocation - CameraPOV.Location;
		CameraToCursorNoZ.Z = 0;
		CameraToCursorNoZ = Normal(CameraToCursorNoZ);

		//// Offset the projection ray X units towards the camera (NoZ)
		RayPlaneIntersection(CameraPOV.Location, (CursorLocation - (CameraToCursorNoZ * 25.0f)) - CameraPOV.Location, FloorPlane, ProjectedPoint);

		FocusPoint.vFocusPoint = ProjectedPoint;
		FocusPoint.vCameraLocation = CameraPOV.Location;
		VisFocusPoints.AddItem(FocusPoint);
	}

	// the active unit, if any, is of interest
	if (ActivePawn != none && bDisableExpiration == false)
	{
		FocusPoint.vFocusPoint = ActivePawn.Location;
		if (ActivePawn.CollisionComponent != none)
			FocusPoint.vFocusPoint.Z = ActivePawn.Location.Z - ActivePawn.CollisionComponent.Bounds.BoxExtent.Z;

		FocusPoint.vCameraLocation = CameraPOV.Location;
		VisFocusPoints.AddItem(FocusPoint);
	}

	Super.AddCameraFocusPoints();
}

function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local XComGameState_Player PlayerState;
	local X2TacticalGameRuleset RuleSet;
	local XComGameStateHistory History;		

	Super.GetCameraFocusPoints(OutFocusPoints);

	RuleSet = `TACTICALRULES;
	History = `XCOMHISTORY;
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(RuleSet.GetCachedUnitActionPlayerRef().ObjectID));

	if (PlayerState != none && PlayerState.IsLocalPlayer() == false)
	{
		OutFocusPoints = PreviousCamerasVisFocusPoints;
	}
}

function bool GetCameraIsPrimaryFocusOn()
{
	return true;
}

defaultproperties
{
	Priority = eCameraPriority_Default
	TurnOffHidingAtTargetTile = false
	IsCenteringOnUnit=false
	EnablePathingDistance = 150
}
