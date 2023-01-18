//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_LookAt.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Simple camera that just looks at a 3D location. Derive and override GetCameraLookat()
//           to use.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_LookAt extends X2Camera
	implements(X2VisualizationMgrObserverInterface)
	abstract
	config(Camera)
	native;

// basic configuration parameters
var protected const config float MaximumInterpolationDistancePerSecond;
var protected const config float MaximumInterpolationRotationPerSecond; // in degrees
var protected const config float MaximumInterpolationZoomPerSecond;   // in percent, where 1.0 is 100%
var protected const config float LocationInterpolationRampUpDuration; // in seconds, total time to go from standstill to full interpolation speed
var protected const config float RotationInterpolationRampUpDuration; // in seconds, total time to go from standstill to full interpolation speed
var protected const config float ZoomInterpolationRampUpDuration;
var protected const config float ZoomedDistanceFromCursor;
var protected const config float DistanceFromCursor;
var const config bool UseSwoopyCam;

// alien turn configuration parameters, all in degrees
var protected const config float AlienTurnPitch;
var protected const config float AlienTurnYaw;
var protected const config float AlienTurnRoll;
var protected const config float AlienTurnFOV;

// human turn configuration parameters, all in degrees
var protected const config float HumanTurnPitch;
var protected const config float HumanTurnYaw;
var protected const config float HumanTurnRoll;
var protected const config float HumanTurnFOV;

// runtime values
// these are the target values for the camera. We smoothly interpolate to them over time so there
// is not a sudden jar to the user when they rotate the camera, for example.
var protected Rotator TargetRotation;
var protected float TargetFOV;
var protected float TargetZoom;
var protected float PushInZoomTarget;
var protected float PushInZoomTime;
var protected float LocationInterpolationRampAlpha; // 0.0-1.0, smooth ramp up for interpolation speed
var protected float RotationInterpolationRampAlpha;    // 0.0-1.0
var protected float ZoomInterpolationRampAlpha;    // 0.0-1.0

// these values are the effective values. For example, Yaw may be set to 90 but if we are still interpolating it
// may draw a yaw of 23. This is the "CurrentYaw"
var protected Vector CurrentLookAt;
var protected Rotator CurrentRotation;
var protected float CurrentFOV;
var protected float CurrentZoom;

// percentage of fov to use as a tether border. i.e. with 25% tether, a 70 degree FOV camera will keep the lookat point within the center 52.5% of the screen
var config float TetherScreenPercentage;

// Number of tiles outside the level volume the camera is allowed to move before it gets clamped.
// Only applies to the horizontal, height is always clamped to the roof of the level volume
var config float MaxTilesCameraCanMoveOutsideLevelVolume;

var bool UserWantsToFreeLook;

// Is the camera currently moving (Interpolating between locations)
var bool bCameraIsMoving;
var bool bCameraIsRotating;
var bool bCameraIsZooming;

var bool TurnOffHidingAtTargetTile;
var Actor ActorAtTargetTile;

// Stores the Vis Focus points for the frame before the camera started moving.
var array<TFocusPoints> arrVisFocusFromBeforeMovement;

// Returns the new tethered lookat for the camera, given the desired point. I.e., returns the camera's lookat point
// that keeps the desired lookat within the screen tether.
protected native final function Vector GetTetheredLookatPoint(Vector LookatPoint, TPOV Camera);
protected native final function float GetCameraDistanceFromLookAtPoint(); 

// returns true if the given point lies within the screen tether
protected static native final function bool IsPointWithinTether(TPOV Camera, Vector LookatPoint);

cpptext
{
	// Utility function to prevent the camera from being zoomed into or dropped lower than the
	// ground floor
	static void MoveCameraUpIfEmbeddedInFloor(FVector& CameraLocation);
}

/// <summary>
/// Gets the current desired look at location. Override in derived classes
/// </summary>
protected function Vector GetCameraLookat();

function bool IsLookAtValid()
{
	return !class'Helpers'.static.VectorContainsNaNOrInfinite(GetCameraLookat());
}

function native TPOV GetCameraLocationAndOrientation();

function bool ShouldBlendFromCamera(X2Camera PreviousActiveCamera)
{
	return UseSwoopyCam && X2Camera_OTSTargeting(PreviousActiveCamera) != none;
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	local XComTacticalController LocalController;
	local TTile LookAtTile;
	local Vector FinalDestinationLookAt;
	local array<Actor> TileActors;

	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	// inherit values from the last active look at cam
	if(LastActiveLookAtCamera != none)
	{
		CurrentLookAt = LastActiveLookAtCamera.CurrentLookAt;
		CurrentRotation = LastActiveLookAtCamera.CurrentRotation;
		TargetRotation = LastActiveLookAtCamera.TargetRotation;
		CurrentFOV = LastActiveLookAtCamera.CurrentFOV;
		TargetFOV = LastActiveLookAtCamera.TargetFOV;

		CurrentZoom = LastActiveLookAtCamera.CurrentZoom;
		TargetZoom = LastActiveLookAtCamera.TargetZoom;

		UserWantsToFreeLook = LastActiveLookAtCamera.UserWantsToFreeLook;
	}
	else
	{
		// prime the camera with default values
		CurrentRotation.Pitch = HumanTurnPitch * DegToUnrRot;
		CurrentRotation.Yaw = HumanTurnYaw * DegToUnrRot;
		CurrentRotation.Roll = HumanTurnRoll * DegToUnrRot;
		TargetRotation = CurrentRotation;
		TargetFOV = HumanTurnFOV;
		CurrentFOV = TargetFOV;

		CurrentLookAt = GetCameraLookat();
	}

	// make sure cinematic mode is off (but only if the camera is not currently faded)
	LocalController = XComTacticalController(`BATTLE.GetALocalPlayerController());
	if(!LocalController.PlayerCamera.bEnableFading)
	{
		XComTacticalController(`BATTLE.GetALocalPlayerController()).SetCinematicMode(false, false, true, true, true, true, false);
	}

	// reset these on every activation
	LocationInterpolationRampAlpha = 0;
	RotationInterpolationRampAlpha = 0;
	ZoomInterpolationRampAlpha = 0;

	if (TurnOffHidingAtTargetTile)
	{
		FinalDestinationLookAt = GetCameraLookat();
		if (!`XWORLD.GetFloorTileForPosition(FinalDestinationLookAt, LookAtTile, true))
		{
			FinalDestinationLookAt.Z += class'XComWorldData'.const.WORLD_FloorHeight;
			LookAtTile = `XWORLD.GetTileCoordinatesFromPosition(FinalDestinationLookAt);
		}
		TileActors = `XWORLD.GetActorsOnTile(LookAtTile, true);
		ActorAtTargetTile = TileActors.Length > 0 ? TileActors[0] : none;

		if (XComLevelActor(ActorAtTargetTile) != none && XComLevelActor(ActorAtTargetTile).HideableWhenBlockingObjectOfInterest)
		{
			XComLevelActor(ActorAtTargetTile).HideableWhenBlockingObjectOfInterest = false;
		}
		else
		{
			// Set it to none here so we know we don't set the hideable flag to true on deactivate
			ActorAtTargetTile = none;
		}
	}
}

function Deactivated()
{
	super.Deactivated();

	if (ActorAtTargetTile != none)
	{
		XComLevelActor(ActorAtTargetTile).HideableWhenBlockingObjectOfInterest = true;
	}
}

function Added()
{
	super.Added();

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
}

function Removed()
{
	super.Removed();

	`XCOMVISUALIZATIONMGR.RemoveObserver(self);
}

function YawCamera(float Degrees)
{
	// always clamp the yaw to a maximum of one full rotation past the current rotation.
	// otherwise the user could cue up several seconds of rotation and have to wait for it.
	if(abs(TargetRotation.Yaw - CurrentRotation.Yaw) < (360 * DegToUnrRot))
	{
		TargetRotation.Yaw += Degrees * DegToUnrRot;
	}
}

function PitchCamera(float Degrees)
{
	// don't let them overdo the pitch
	TargetRotation.Pitch = FClamp(TargetRotation.Pitch + Degrees * DegToUnrRot, -90 * DegToUnrRot, -10 * DegToUnrRot);

	// only freelook messes with the pitch right now, so this is a good way to know if the user did it
	UserWantsToFreeLook = true;
}

function ZoomCamera(float Amount)
{
	// don't let them overdo the zoom
	TargetZoom = FClamp(TargetZoom + Amount, -0.75, 1.0);
}

function ZoomCameraPushIn(float Amount, float Time)
{
	PushInZoomTarget = Amount;
	PushInZoomTime = Time;
}

function UpdateCamera(float DeltaTime)
{
	local bool bOldIsMoving, bNewIsMoving;

	bOldIsMoving = bCameraIsMoving || bCameraIsRotating;	

	InterpolateRotation(DeltaTime);
	InterpolateLocation(DeltaTime);
	InterpolateZoom(DeltaTime);
	InterpolateFOV(DeltaTime);

	bNewIsMoving = bCameraIsMoving || bCameraIsRotating;

	if (bOldIsMoving != bNewIsMoving)
	{
		if (bNewIsMoving)
			arrVisFocusFromBeforeMovement = VisFocusPoints;
		else
			arrVisFocusFromBeforeMovement.Length = 0;
	}

	super.UpdateCamera(DeltaTime);
}

function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local int i;

	super.GetCameraFocusPoints(OutFocusPoints);

	for (i = 0; i < arrVisFocusFromBeforeMovement.Length; ++i)
	{
		OutFocusPoints.AddItem(arrVisFocusFromBeforeMovement[i]);
	}
}

// the angle values are in unreal rotation units
protected function InterpolateRotation(float DeltaTime)
{
	local Rotator DeltaRotation;
	local int DeltaLength;
	local int LengthToMove;
	local int ReducedYawDelta;

	DeltaRotation = TargetRotation - CurrentRotation;

	// pythagorean distance of polar coordinates. We can't just take the angle distance between current and target
	// because it's possible the amount of rotation currently added is > 180 degress. If this is the case and we 
	// also need to convert angles to floating point or we will overflow the range limits of int fast with the squares
	DeltaLength = sqrt(float(DeltaRotation.Pitch) * DeltaRotation.Pitch + float(DeltaRotation.Yaw) * DeltaRotation.Yaw + float(DeltaRotation.Roll) * DeltaRotation.Roll);
	if(DeltaLength != 0)
	{
		`assert(RotationInterpolationRampUpDuration > 0);
		bCameraIsRotating = true;

		// ramp alpha is a value from 0.0-1.0 that takes ease-in/out into account for smoother motion
		RotationInterpolationRampAlpha = fMin(1.0, RotationInterpolationRampAlpha + DeltaTime / RotationInterpolationRampUpDuration);
		RotationInterpolationRampAlpha = fMin(RotationInterpolationRampAlpha, ComputeAngleBrakeAlpha(DeltaLength));

		LengthToMove = Min(DeltaLength, (MaximumInterpolationRotationPerSecond * DegToUnrRot) * DeltaTime * RotationInterpolationRampAlpha);

		if(LengthToMove == 0)
		{
			// we're too close to interpolate anymore. Yay integer math. Just snap to the target
			// and also reduce angles to prevent eventual overflows
			CurrentRotation.Pitch = CurrentRotation.Pitch % (360 * DegToUnrRot);
			CurrentRotation.Yaw = CurrentRotation.Yaw % (360 * DegToUnrRot);
			CurrentRotation.Roll = CurrentRotation.Roll % (360 * DegToUnrRot);
			CurrentRotation = TargetRotation;
		}
		else
		{ 
			// add in the offset. this is normal(rotation) * lengthtomove, but solved so that the division is last.
			// this allows us to keep it integer math (normalize yields fractional numbers).
			CurrentRotation.Pitch += DeltaRotation.Pitch * LengthToMove / DeltaLength;
			CurrentRotation.Yaw += DeltaRotation.Yaw * LengthToMove / DeltaLength;
			CurrentRotation.Roll += DeltaRotation.Roll * LengthToMove / DeltaLength;

			// do angle reduction on the yaw every frame. It's possible for a really dedicated user to continually
			// rotate the camera around and around until the values overflow, so prevent that by
			// constantly reducing them if possible
			ReducedYawDelta = TargetRotation.Yaw - CurrentRotation.Yaw;
			CurrentRotation.Yaw = CurrentRotation.Yaw % (360 * DegToUnrRot);
			TargetRotation.Yaw = CurrentRotation.Yaw + ReducedYawDelta;
		}
	}
	else
	{
		bCameraIsRotating = false;
		RotationInterpolationRampAlpha = 0; // make sure this is clear
	}
}

// AngularDistanceRemaining is in unreal rotation units
protected function float ComputeAngleBrakeAlpha(int AngularDistanceRemaining)
{
	local float BrakeStartDistance;
	local float BrakeAlpha;

	BrakeStartDistance = RotationInterpolationRampUpDuration * (MaximumInterpolationRotationPerSecond * DegToUnrRot) * 0.25;
	BrakeAlpha = AngularDistanceRemaining / BrakeStartDistance;

	// clamp. Never go all the way to 0, as then we will never arrive
	BrakeAlpha = FClamp(BrakeAlpha, 0.005f, 1.0f);
	
	return BrakeAlpha;
}

protected function InterpolateZoom(float DeltaTime)
{
	local float DeltaZoom;
	local float ZoomAdjustment;
	local float BrakeStartDistance;
	local float BrakeAlpha;
	local float ZoomSpeed;
	local float SelectedTargetZoom;

	if( PushInZoomTarget != 0.f )
	{
		SelectedTargetZoom = PushInZoomTarget;
		ZoomSpeed = abs(SelectedTargetZoom) / PushInZoomTime;
	}
	else
	{
		SelectedTargetZoom = TargetZoom;
		ZoomSpeed = MaximumInterpolationZoomPerSecond;
	}

	DeltaZoom = SelectedTargetZoom - CurrentZoom;

	if(DeltaZoom != 0.0f) // close enough
	{
		`assert(ZoomInterpolationRampUpDuration > 0);
		bCameraIsZooming = true;

		BrakeStartDistance = ZoomInterpolationRampUpDuration * ZoomSpeed * 0.4;
		BrakeAlpha = abs(DeltaZoom) / BrakeStartDistance;

		// clamp. Never go all the way to 0, as then we will never arrive
		BrakeAlpha = FClamp(BrakeAlpha, 0.001, 1.0f);

		// ramp alpha is a value from 0.0-1.0 that takes ease-in/out into account for smoother motion
		ZoomInterpolationRampAlpha = fMin(1.0, ZoomInterpolationRampAlpha + DeltaTime / ZoomInterpolationRampUpDuration);
		ZoomInterpolationRampAlpha = fMin(ZoomInterpolationRampAlpha, BrakeAlpha);

		ZoomAdjustment = ZoomSpeed * DeltaTime * ZoomInterpolationRampAlpha;

		if(ZoomAdjustment > abs(DeltaZoom))
		{
			// we can't get any closer without overshooting, so just lock to the target zoom
			CurrentZoom = SelectedTargetZoom;
		}
		else
		{
			CurrentZoom += ZoomAdjustment * Sgn(DeltaZoom);
		}
	}
	else
	{
		bCameraIsZooming = false;
	}
}

protected function InterpolateFOV(float DeltaTime)
{
	// no ease in/out for now
	CurrentFOV += ((TargetFOV > CurrentFOV) ? 1 : -1) * (fMin(abs(TargetFOV - CurrentFOV), DeltaTime));
}

protected function InterpolateLocation(float DeltaTime)
{
	local Vector NewLookAt;
	local Vector LookAtDelta;
	local float InterpolateDistance;
	local float DeltaLength;

	NewLookAt = GetCameraLookAt();
	LookAtDelta = NewLookAt - CurrentLookAt;
	DeltaLength = VSize(LookAtDelta);

	// only interpolate until we get "close enough". Prevents FP error from making us never arrive
	if(DeltaLength > 0.01)
	{
		`assert(LocationInterpolationRampUpDuration > 0);

		// ramp alpha is a value from 0.0-1.0 that takes ease-in/out into account for smoother motion
		LocationInterpolationRampAlpha = fMin(1.0, LocationInterpolationRampAlpha + DeltaTime / LocationInterpolationRampUpDuration);
		LocationInterpolationRampAlpha = fMin(LocationInterpolationRampAlpha, ComputeLocationBrakeAlpha(DeltaLength));

		InterpolateDistance = MaximumInterpolationDistancePerSecond * DeltaTime * LocationInterpolationRampAlpha;
		InterpolateDistance = fMin(DeltaLength, InterpolateDistance);
		
		LookAtDelta = Normal(LookAtDelta) * InterpolateDistance;

		if(VSizeSq(LookAtDelta) > 0)
		{
			CurrentLookAt = CurrentLookAt + LookAtDelta;
			bCameraIsMoving = true;
			return;
		}
	}

	CurrentLookAt = NewLookAt;
	LocationInterpolationRampAlpha = 0.0;
	bCameraIsMoving = false;
}

protected function float ComputeLocationBrakeAlpha(float DistanceFromDestination)
{
	local float BrakeStartDistance;
	local float BrakeAlpha;

	BrakeStartDistance = LocationInterpolationRampUpDuration * MaximumInterpolationDistancePerSecond * 0.4;
	BrakeAlpha = DistanceFromDestination / BrakeStartDistance;

	// clamp. Never go all the way to 0, as then we will never arrive
	BrakeAlpha = FClamp(BrakeAlpha, 0.01f, 1.0f);
	
	return BrakeAlpha;
}

function OnNewActivePlayer(XGPlayer NewPlayer)
{
	if(!`CHEATMGR.bAllowFancyCameraStuff) return;

	if(!UserWantsToFreeLook)
	{
		// these int casts are needed or else we'll upcast the rotator pitch to float
		if(!NewPlayer.IsHumanPlayer()  && TargetRotation.Pitch != int(AlienTurnPitch * DegToUnrRot))
		{
			// install the alien parameters
			TargetRotation.Pitch = AlienTurnPitch * DegToUnrRot;
			TargetRotation.Yaw += (AlienTurnYaw - HumanTurnYaw)  * DegToUnrRot;
			TargetRotation.Roll = AlienTurnRoll  * DegToUnrRot;
			TargetFOV = AlienTurnFOV;
		}
		else if(TargetRotation.Pitch != int(HumanTurnPitch * DegToUnrRot))
		{
			// still the alien setting, put it back
			TargetRotation.Pitch = HumanTurnPitch  * DegToUnrRot;
			TargetRotation.Yaw -= (AlienTurnYaw - HumanTurnYaw) * DegToUnrRot;
			TargetRotation.Roll = HumanTurnRoll  * DegToUnrRot;
			TargetFOV = HumanTurnFov;
		}
	}
}

function bool ShouldUnitUseScanline(XGUnitNativeBase Unit)
{
	return true;
}

function bool AllowBuildingCutdown()
{
	return true;
}

function bool DisableFocusPointExpiration()
{
	return bCameraIsRotating || bCameraIsMoving;
}

function AddCameraFocusPoints()
{
	local Vector LookAt;
	local XCom3DCursor Cursor;
	local TFocusPoints FocusPoint;

	LookAt = GetCameraLookat();
	
	Cursor = `CURSOR;
	if(Cursor != none)
	{
		// kick this up to the level of the cursor. The vis system expects that.
		LookAt.Z += CylinderComponent(Cursor.CollisionComponent).CollisionHeight;
	}

	FocusPoint.vFocusPoint = LookAt;
	FocusPoint.vCameraLocation = FocusPoint.vFocusPoint - (Vector(TargetRotation) * 9999.0f);
	VisFocusPoints.AddItem(FocusPoint);
}

// implementation of X2VisualizationMgrObserverInterface
event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameStateContext_TacticalGameRule Context;
	local XComGameStateHistory History;
	local XGPlayer NewPlayer;

	Context = XComGameStateContext_TacticalGameRule(AssociatedGameState.GetContext());
	if(Context != none && Context.GameRuleType == eGameRule_PlayerTurnBegin)
	{
		History = `XCOMHISTORY;
		NewPlayer = XGPlayer(History.GetVisualizer(Context.PlayerRef.ObjectID));
		OnNewActivePlayer(NewPlayer);
	}
}
event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle();

defaultproperties
{
	Priority=eCameraPriority_GameActions
	TurnOffHidingAtTargetTile = true
	bCameraIsMoving=false
	IgnoreSlomo=true
}

