//-----------------------------------------------------------
// Base class for headquarters camera state classes
//-----------------------------------------------------------
class XComCamState_HQ_Photobooth extends XComCamState_HQ;

var private vector m_vRotationPoint;
var private vector m_vTargetRotationPoint;

/************ Camera Distance Variables **************/

var private float m_fInitialCameraDistance;
var private float m_fTargetCameraDistance;

var private float m_fMinCameraDistance;
var private float m_fMaxCameraDistance;

/************ Camera Rotation Variables **************/

var private Rotator m_rInitialCameraRotation;
var private Rotator m_rTargetCameraRotation;

var private float m_fRotationSpeed;
var private float m_fZoomSpeed;
var private float m_fPanSpeed;

var private CameraActor CamActor;


var private bool		m_bUsePresetCamera;

var private Box		CameraBounds;
var private bool	bBoundsInitialized;

function Init( PlayerController ForPlayer, CameraActor inCameraActor, PointInSpace inFocusPoint )
{
	local vector CameraToRotation;

	CamActor = inCameraActor;

	m_vRotationPoint = inFocusPoint.Location;
	m_vTargetRotationPoint = m_vRotationPoint;

	CameraToRotation = m_vRotationPoint - inCameraActor.Location;
	m_rInitialCameraRotation = Rotator(CameraToRotation);
	m_rTargetCameraRotation = m_rInitialCameraRotation;

	m_fInitialCameraDistance = vsize(CameraToRotation);
	m_fTargetCameraDistance = m_fInitialCameraDistance;

	bBoundsInitialized = false;
	
	InitCameraState( ForPlayer );
}

function GetView(float DeltaTime, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha)
{
	UpdateBounds();
	ClampToBounds();

	out_ViewDistance = InterpViewDistance(DeltaTime);
	out_Rotation = InterpViewRotation(DeltaTime);
	out_Focus = InterpViewFocusPoint(DeltaTime);
	
	
	if(CamActor != none)
	{
		out_FOV = CamActor.FOVAngle;
		out_PPSettings = CamActor.CamOverridePostProcess;
		out_PPOverrideAlpha = CamActor.CamOverridePostProcessAlpha;
	}
	
	PCOwner.SetRotation( out_Rotation );
}

protected function float InterpViewDistance( float DeltaTime )
{
	m_fInitialCameraDistance += (m_fTargetCameraDistance - m_fInitialCameraDistance) * DeltaTime * m_fZoomSpeed;

	return m_fInitialCameraDistance;
}

protected function rotator InterpViewRotation(float DeltaTime)
{
	m_rInitialCameraRotation += (m_rTargetCameraRotation - m_rInitialCameraRotation) * DeltaTime * m_fRotationSpeed;

	return m_rInitialCameraRotation;
}

protected function vector InterpViewFocusPoint(float DeltaTime)
{
	m_vRotationPoint += (m_vTargetRotationPoint - m_vRotationPoint) * DeltaTime * m_fPanSpeed;

	return m_vRotationPoint;
}

function MoveToFinal()
{
	m_rInitialCameraRotation = m_rTargetCameraRotation;
	m_fInitialCameraDistance = m_fTargetCameraDistance;
	m_vRotationPoint = m_vTargetRotationPoint;
}

function GetFinalCameraViewPoint(out vector outViewLocation, out rotator outViewRotation)
{
	outViewRotation = m_rTargetCameraRotation;
	outViewLocation = m_vRotationPoint - vector(m_rTargetCameraRotation) * m_fTargetCameraDistance;
}

function MoveFocusPoint(float X, float Y, float Z)
{
	m_vTargetRotationPoint.X += X;
	m_vTargetRotationPoint.Y += Y;
	m_vTargetRotationPoint.Z += Z;
}

function SetFocusPoint(vector FocusPoint)
{
	m_vTargetRotationPoint = FocusPoint;
}

function MoveFocusPointOnRotationAxes(float X, float Y, float Z)
{
	local Vector VecX, VecY, VecZ;

	GetAxes(m_rTargetCameraRotation, VecX, VecY, VecZ);

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

	m_rTargetCameraRotation += RotationAmount;
}

function SetCameraRotation(Rotator Rotation)
{
	m_rTargetCameraRotation = Rotation;
}

function AddZoom(float inDistanceOffset)
{
	m_fTargetCameraDistance += inDistanceOffset;	
	m_fTargetCameraDistance = Clamp(m_fTargetCameraDistance, m_fMinCameraDistance, m_fMaxCameraDistance);
}

function float GetZoomPercentage()
{
	local float percentage;
	percentage =  (m_fTargetCameraDistance - m_fMinCameraDistance) / (m_fMaxCameraDistance - m_fMinCameraDistance);
	if (percentage < 0.2f)
		percentage = 0.2f;

	return percentage;
}

function SetViewDistance(float inViewDistance)
{
	m_fTargetCameraDistance = inViewDistance;
}

function SetUseCameraPreset(bool bUse)
{
	m_bUsePresetCamera = bUse;
}

function UpdateBounds()
{
	local LightInclusionVolume LIV;
	local BoxSphereBounds BoxSphere;

	if (!bBoundsInitialized)
	{
		foreach WorldInfo.AllActors(class'LightInclusionVolume', LIV)
		{
			if (LIV.Tag == Name("PhotoboothLIV"))
			{
				if (LIV.BrushComponent != none)
				{
					BoxSphere = LIV.BrushComponent.Bounds;
					CameraBounds.Min = BoxSphere.Origin - BoxSphere.BoxExtent;
					CameraBounds.Max = BoxSphere.Origin + BoxSphere.BoxExtent;
					CameraBounds.IsValid = 1;
					bBoundsInitialized = true;
					break;
				}
			}
		}
	}
}

function ClampToBounds()
{
	local vector Direction, OneOverDirection, HitLoc;

	if (bBoundsInitialized && !IsPointInBox(m_vTargetRotationPoint, CameraBounds))
	{
		// Fix up m_vTargetRotationPoint.
		Direction = m_vRotationPoint - m_vTargetRotationPoint;
		OneOverDirection.X = Direction.X == 0.0f ? Direction.X : 1.0f / Direction.X;
		OneOverDirection.Y = Direction.Y == 0.0f ? Direction.Y : 1.0f / Direction.Y;
		OneOverDirection.Z = Direction.Z == 0.0f ? Direction.Z : 1.0f / Direction.Z;
		if (LineBoxIntersection(CameraBounds, m_vTargetRotationPoint, m_vRotationPoint, Direction, OneOverDirection, HitLoc))
		{
			m_vTargetRotationPoint = HitLoc;
		}
	}
}

DefaultProperties
{
	m_bUsePresetCamera = true;
	m_fRotationSpeed = 4.0f
	m_fZoomSpeed = 4.0f
	m_fPanSpeed = 8.0f

	m_fMinCameraDistance = 40
	m_fMaxCameraDistance = 500
}
