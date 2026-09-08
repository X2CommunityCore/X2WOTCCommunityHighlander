//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveClimbLadder extends X2Action_Move;

var vector  NewDirection;

var private Name m_StartAnim;
var private Name m_LoopAnim;
var private Name m_StopAnim;
var private CustomAnimParams AnimParams;
var private XComLadder m_kLadder;
var private Vector m_vFacing;
var private bool m_bAscending;
var private BoneAtom StartingAtom;
var private vector EndingPoint;
var EDiscState eDisc;
var transient float fLadderHeight;
var bool    bStoredSkipIK;

function Init()
{
	local Actor LadderActor;
	super.Init();

	if(FindActorByIdentifier(Unit.CurrentMoveData.MovementData[PathIndex].ActorId, LadderActor))
	{
		m_kLadder = XComLadder(LadderActor);
		m_kLadder.GetPath(Unit.Location.Z, StartingAtom.Translation, EndingPoint);
	}
	fLadderHeight = m_kLadder.GetHeight();

	m_bAscending = m_kLadder.IsAtBottom(UnitPawn.Location.Z);
	if (m_bAscending)
	{		
		m_vFacing = vect(1, 0, 0) >> m_kLadder.Rotation;
	}
	else
	{		
		m_vFacing = vect(-1, 0, 0) >> m_kLadder.Rotation;
	}

	PathTileIndex = FindPathTileIndex();
}

function ParsePathSetParameters(int InPathIndex, const out vector InDestination, float InDistance, const out vector InNewDirection)
{
	PathIndex = InPathIndex;	
	Destination = InDestination;
	Distance = InDistance;
	NewDirection = InNewDirection;
}

simulated function ChooseAnims()
{
	if (m_bAscending)
	{
		if (m_kLadder.nLadderType == 'Ladder' || m_kLadder.nLadderType == 'Vine')
		{
			m_StartAnim = 'MV_ClimbLadderUp_StartA';
			m_LoopAnim = 'MV_ClimbLadderUp_LoopA';
			m_StopAnim = 'MV_ClimbLadderUp_StopA';
		}
		else if (m_kLadder.nLadderType == 'Pipe')
		{
			m_StartAnim = 'MV_ClimbDrainUp_StartA';
			m_LoopAnim = 'MV_ClimbDrainUp_LoopA';
			m_StopAnim = 'MV_ClimbDrainUp_StopA';
		}
	}
	else
	{		
		if (m_kLadder.nLadderType == 'Ladder' || m_kLadder.nLadderType == 'Vine')
		{
			m_StartAnim = 'MV_ClimbLadderDwn_StartA';
			m_LoopAnim = 'MV_ClimbLadderDwn_LoopA';
			m_StopAnim = 'MV_ClimbLadderDwn_StopA';
		}
		else if (m_kLadder.nLadderType == 'Pipe')
		{
			m_StartAnim = 'MV_ClimbDrainDwn_StartA';
			m_LoopAnim = 'MV_ClimbDrainDwn_LoopA';
			m_StopAnim = 'MV_ClimbDrainDwn_StopA';
		}
	}
}

simulated function ChooseSoundEffects()
{
	switch (m_kLadder.nLadderType)
	{
		case 'Ladder':
			UnitPawn.SetSwitch('Climb_Grabs', 'Ladder');
			break;
		case 'Vine':
			UnitPawn.SetSwitch('Climb_Grabs', 'Vine');
			break;
		case 'Pipe':
			// Yes, the Pipes use the Ladder Audio switch.  mdomowicz 2015_08_05
			UnitPawn.SetSwitch('Climb_Grabs', 'Ladder');
			break;
	}
}

simulated state Executing
{
Begin:
	ChooseAnims();
	ChooseSoundEffects();

	eDisc = Unit.m_eDiscState;
	Unit.SetDiscState(eDS_None);

	bStoredSkipIK = UnitPawn.bSkipIK;
	UnitPawn.bSkipIK = true;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	// Start
	AnimParams.AnimName = m_StartAnim;
	AnimParams.PlayRate = GetMoveAnimationSpeed();
	StartingAtom.Rotation = QuatFromRotator(Rotator(m_vFacing));
	StartingAtom.Scale = 1.0f;
	StartingAtom.Translation.Z = Unit.GetDesiredZForLocation(StartingAtom.Translation);
	UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(AnimParams, StartingAtom);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	
	// Loop
	if (fLadderHeight > 400)
	{
		AnimParams = default.AnimParams;
		AnimParams.PlayRate = GetMoveAnimationSpeed();
		AnimParams.AnimName = m_LoopAnim;
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	}
	
	if( PredictedCoverState != eCS_None )
	{
		NewDirection = PredictedCoverDirection;
	}

	NewDirection.Z = 0.0f;
	if( abs(NewDirection.X) < 0.001f && abs(NewDirection.Y) < 0.001f )
	{
		NewDirection = vector(UnitPawn.Rotation);
	}

	// Stop
	AnimParams = default.AnimParams;
	AnimParams.PlayRate = GetMoveAnimationSpeed();
	AnimParams.AnimName = m_StopAnim;
	AnimParams.DesiredEndingAtoms.Add(1);
	AnimParams.DesiredEndingAtoms[0].Translation = Destination;
	AnimParams.DesiredEndingAtoms[0].Translation.Z = UnitPawn.GetDesiredZForLocation(Destination);
	AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(rotator(NewDirection));
	AnimParams.DesiredEndingAtoms[0].Scale = 1.0f;
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	UnitPawn.Acceleration = Vect(0, 0, 0);
	UnitPawn.vMoveDirection = Vect(0, 0, 0);
	UnitPawn.m_fDistanceMovedAlongPath = Distance;

	UnitPawn.bSkipIK = bStoredSkipIK;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.SnapToGround();

	Unit.SetDiscState(eDisc);
	CompleteAction();
}

function bool CheckInterrupted()
{
	//Do not allow interruptions while climbing a ladder. Interruptions like an AI reveal/scamper would break badly if this happened.
	//Nearly everything else will happen before the unit gets to the ladder, or can just wait until the unit is at the other end.
	//Some contrived cases will look wrong doing this (overwatching a unit that was briefly visible during a ladder climb) - but none are as bad as that.
	return false;
}

DefaultProperties
{
}
