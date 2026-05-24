//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_Photobooth.uc
//  AUTHOR:  Scott Boeckmann  --  11/15/2016
//  PURPOSE: Camera that looks at a location but pivots around a second location.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_Photobooth extends X2Camera;

var private vector		m_vRotationPoint;
var private vector		m_vTargetRotationPoint;

var private Rotator		m_rRotationAroundPoint;
var private Rotator		m_rTargetRotationAroundPoint;

var private float		m_fDistanceFromPoint;
var private float		m_fTargetDistanceFromPoint;

var private float		m_fFOV;
var private float		m_fRotationSpeed;
var private float		m_fZoomSpeed;
var private float		m_fPanSpeed;

var private float m_fMinCameraDistance;
var private float m_fMaxCameraDistance;
var private float m_fSpringArmDistance;

var private bool		m_bUsePresetCamera;

var private Box		CameraBounds;
var private float	MinZ;

function InitCamera(CameraActor inCamActor, vector inRotationPoint)
{
	local vector CameraToRotation, BoundsOrigin, BoundsExtent;
	local float HalfMaxCameraDist;

	m_vRotationPoint = inRotationPoint;
	m_vTargetRotationPoint = m_vRotationPoint;

	CameraToRotation = m_vRotationPoint - inCamActor.Location;
	m_rRotationAroundPoint = Rotator(CameraToRotation);
	m_rTargetRotationAroundPoint = m_rRotationAroundPoint;

	m_fDistanceFromPoint = vsize(CameraToRotation);
	m_fTargetDistanceFromPoint = m_fDistanceFromPoint;
	m_fSpringArmDistance = m_fTargetDistanceFromPoint;

	// Setup bounds.
	MinZ = `XWORLD.GetFloorZForPosition(inRotationPoint) + 10.0; // Add slight offset to avoid seeing under roofs and other misc wonkiness.
	HalfMaxCameraDist = m_fMaxCameraDistance / 2;
	BoundsExtent.X = HalfMaxCameraDist;
	BoundsExtent.Y = HalfMaxCameraDist;
	BoundsExtent.Z = HalfMaxCameraDist;
	BoundsOrigin = inRotationPoint;
	BoundsOrigin.Z = MinZ + m_fMinCameraDistance + HalfMaxCameraDist;
	CameraBounds.Min = BoundsOrigin - BoundsExtent;
	CameraBounds.Max = BoundsOrigin + BoundsExtent;
	CameraBounds.IsValid = 1;
}

function UpdateCamera(float DeltaTime)
{
	super.UpdateCamera(DeltaTime);

	ClampToBounds();

	InterpolateRotationPoint(DeltaTime);
	InterpolateRotation(DeltaTime);
	InterpolateDistance(DeltaTime);
}

function MoveToFinal()
{
	m_rRotationAroundPoint = m_rTargetRotationAroundPoint;
	m_fDistanceFromPoint = m_fTargetDistanceFromPoint;
	m_vRotationPoint = m_vTargetRotationPoint;
}

function InterpolateRotation(float DeltaTime)
{
	m_rRotationAroundPoint += (m_rTargetRotationAroundPoint - m_rRotationAroundPoint) * DeltaTime * m_fRotationSpeed;
}

function InterpolateDistance(float DeltaTime)
{
	m_fDistanceFromPoint += ((m_fSpringArmDistance < m_fTargetDistanceFromPoint ? m_fSpringArmDistance : m_fTargetDistanceFromPoint) - m_fDistanceFromPoint) * DeltaTime * m_fZoomSpeed;
}

function InterpolateRotationPoint(float DeltaTime)
{
	m_vRotationPoint += (m_vTargetRotationPoint - m_vRotationPoint) * DeltaTime * m_fPanSpeed;
}

function Rotator GetCameraRotation()
{
	return m_rRotationAroundPoint;
}

function Rotator GetCameraTargetRotation()
{
	return m_rTargetRotationAroundPoint;
}

function Vector GetCameraOffset()
{
	return m_vTargetRotationPoint;
}

function TPOV GetCameraLocationAndOrientation()
{
	local TPOV OutPOV;

	OutPOV.Location = m_vRotationPoint - vector(m_rRotationAroundPoint) * m_fDistanceFromPoint;
	OutPOV.Rotation = m_rRotationAroundPoint;
	OutPOV.FOV = m_fFOV;

	return OutPOV;
}

function YawCamera(float Degrees)
{
	m_rTargetRotationAroundPoint.Yaw += Degrees * DegToUnrRot;
}

function PitchCamera(float Degrees)
{
	m_rTargetRotationAroundPoint.Pitch += Degrees * DegToUnrRot;
}

function ZoomCamera(float Amount)
{
	m_fTargetDistanceFromPoint += Amount;
	m_fTargetDistanceFromPoint = Clamp(m_fTargetDistanceFromPoint, m_fMinCameraDistance, m_fMaxCameraDistance);
}

function SetFOV(float FOV)
{
	m_fFOV = FOV;
}

function MoveFocusPoint(float X, float Y, float Z)
{
	m_vTargetRotationPoint.X += X;
	m_vTargetRotationPoint.Y += Y;
	m_vTargetRotationPoint.Z += Z;
}

function MoveFocusPointOnRotationAxes(float X, float Y, float Z)
{
	local Vector VecX, VecY, VecZ;

	GetAxes(m_rTargetRotationAroundPoint, VecX, VecY, VecZ);

	m_vTargetRotationPoint += X * VecX;
	m_vTargetRotationPoint += Y * VecY;
	m_vTargetRotationPoint += Z * VecZ;
}

function AddRotation(float Pitch, float Yaw, float Roll)
{
	local Rotator RotationAmount;

	RotationAmount.Pitch = Pitch * DegToUnrRot;
	RotationAmount.Yaw = Yaw * DegToUnrRot;
	RotationAmount.Roll = Roll * DegToUnrRot;

	m_rTargetRotationAroundPoint += RotationAmount;
}

function AddCameraRotation(Rotator newRot)
{
	m_rTargetRotationAroundPoint += newRot;
}

function float GetZoomPercentage()
{
	local float percentage;
	percentage = (m_fTargetDistanceFromPoint - m_fMinCameraDistance) / (m_fMaxCameraDistance - m_fMinCameraDistance);
	if (percentage < 0.2f)
		percentage = 0.2f;

	return percentage;
}

function SetFocusPoint(vector newRotationPoint)
{
	m_vTargetRotationPoint = newRotationPoint;
}

function SetCameraRotation(Rotator newRotation)
{
	m_rTargetRotationAroundPoint = newRotation;
}

function SetViewDistance(float newViewDistance)
{
	m_fTargetDistanceFromPoint = newViewDistance;
}

function float GetCameraDistance()
{
	return m_fTargetDistanceFromPoint;
}

function ClampToBounds()
{
	local vector Direction, OneOverDirection, HitLoc, NewLoc;
	local Plane BoundingPlane;

	if (!IsPointInBox(m_vTargetRotationPoint, CameraBounds))
	{
		// Fix up m_vTargetRotationPoint.
		// May want to revisit this as not all tactical locations have the formations axis-aligned.  In that case we can
		// transform m_vRotationPoint and m_vTargetRotationPoint to CameraBounds space and then transform the HitLoc back to world.
		Direction = m_vRotationPoint - m_vTargetRotationPoint;
		OneOverDirection.X = Direction.X == 0.0f ? Direction.X : 1.0f / Direction.X;
		OneOverDirection.Y = Direction.Y == 0.0f ? Direction.Y : 1.0f / Direction.Y;
		OneOverDirection.Z = Direction.Z == 0.0f ? Direction.Z : 1.0f / Direction.Z;
		if (LineBoxIntersection(CameraBounds, m_vTargetRotationPoint, m_vRotationPoint, Direction, OneOverDirection, HitLoc))
		{
			m_vTargetRotationPoint = HitLoc;
		}
	}

	// Check logical camera position.
	NewLoc = m_vTargetRotationPoint - vector(m_rTargetRotationAroundPoint) * m_fTargetDistanceFromPoint;
	if (NewLoc.Z < MinZ)
	{
		// Fix up virtual camera position via m_fSpringArmDistance.
		BoundingPlane.X = 0.0;
		BoundingPlane.Y = 0.0;
		BoundingPlane.Z = 1.0;
		BoundingPlane.W = MinZ;

		RayPlaneIntersection(m_vTargetRotationPoint, NewLoc - m_vTargetRotationPoint, BoundingPlane, HitLoc);

		m_fSpringArmDistance = VSize(m_vTargetRotationPoint - HitLoc);
	}
	else
	{
		m_fSpringArmDistance = m_fTargetDistanceFromPoint;
	}
}

defaultproperties
{
	Priority= eCameraPriority_Cinematic
	m_fFOV = 90
	m_fRotationSpeed=4
	m_fZoomSpeed=4
	m_fPanSpeed=8

	m_fMinCameraDistance = 40
	m_fMaxCameraDistance = 700
}