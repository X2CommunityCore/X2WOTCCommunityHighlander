//---------------------------------------------------------------------------------------
//  FILE:    XComIdleAnimationStateMachine.uc
//  AUTHOR:  Ryan McFall  --  11/08/2012
//  PURPOSE: This actor manages the animation state of an XGUnit while it is not performing
//           an action. This class is native so that XGUnit native
//           functions can access its members / functions. This class replaces the
//           'ConstantCombat' system which was a large source of timing related
//           bugs and animation issues in X:EU
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComIdleAnimationStateMachine extends Actor native(Animation)
	config(Animation);

// Start Issue #15
// Deprivatise variables to protected to allow for subclassing overrides
//Cached values we receive when we are created
var protected XGUnit                  Unit;
var protected XGUnitNativeBase        UnitNative;
var protected XComUnitPawn            UnitPawn;
var protected XComUnitPawnNativeBase  UnitPawnNative;

//******** General Purpose Variables **********
var protected int                 NumVisibleEnemies;      //Temp var to hold the result from the visibility mgr in state code
var protected bool                bWaitingForStanceEval;  //This is set if the system gets a stance eval request but cannot fufill it immediately
var protected XGUnit              LastAttacker;           //Set by the targeting action, when a unit selects this unit as a target 
var protected Vector              TargetLocation;         //The location of the target for this unit
var protected Actor               TargetActor;            //The current target of the unit. Can be NULL if the target is just a location.
var protected bool                bDeferredGotoIdle;      //This is set to true if the Resume() function is called while the state machine is in a state that cannot be interrupted
var protected bool                bDeferredGotoDormant;   //This is set to true if the GoDormant() function is called while the state machine is in a state that cannot be interrupted
var protected Actor               kDormantLock;           //Actor that requests GoDormant() must also be the same to request Resume()
var protected bool                bInLatentTurn;          //This flag is true during the 'TurnTowardsPosition' latent function
var protected bool                bIsCivilian;            //This flat is true if the unit this state machine belongs to is using the civilian animation set
var			bool				bIsTurret;				//This flag is true if the unit this state machine belongs to is a turret
var protected float               fIdleAnimRate;          //A random scale to the idle animation speed so that our soldiers don't look like a vaudville routine when the map starts
var protected bool                bRestartIdle;           //If the idle state is entered and the unit is not already performing an idle, restart the idle anim
var         bool                bLoadInitStrangle;      //Resume strangle from load - skip initial strangle start-up animation
var         bool                bTargeting;             // Set this so we know to trigger targeting
var protected CustomAnimParams    AnimParams;             //Params to start animations with
var         AnimNodeSequence    TurningSequence;        //If we are turning this is the sequence doing it
var			Name				PersistentEffectIdleName; // Go to the Persistent state and play this idle anim
var protected XComGameStateVisualizationMgr VisualizationMgr;
var protected XGUnit				PodTalker;
var			bool				TalkerHasSomeoneToTalkTo;
var protected config float		PodIdleFidgetPercentage;
var protected config float		PodTalkFidgetPercentage;
var protectedwrite config float	LeftHandIKBlendTime;	//Length of time in seconds for the left hand to IK to its target position when left hand IK is turned on.
var protected XComGameState_Unit	UnitState;
var protected int					VisualizedHistoryIndex;
var			bool				bShowDebugInfo;			//Display debug information about the idle state machine
//****************************************

//******** Peek State Variables **********
var protected config float                PeekTimeoutMin;
var protected config float				PeekTimeoutMax;
var protected float						PeekTimeoutCurrent;
//****************************************

//******** Signal State Variables **********
var public Name							SignalAnimationName; // The animation to play in the signal state
var public vector						SignalFaceLocation; // Turn this direction before playing the animation
//*******************************************************

//******** EvaluateStance State Variables ****************
var protected CachedCoverAndPeekData		CurrentCoverPeekData;	//Stores information on the tile that the unit is standing in
var int									DesiredCoverIndex;	//The cover facing/direction that the unit should use (And sometimes the previous cover index)
var UnitPeekSide						DesiredPeekSide;	//The peek side that the unit should use (And sometimes the previous peek side)
var protected bool                        bForceDesiredCover;	//This flag is set by 'ForceStance', guides the end behavior for the EvalutateStance state
var protected bool                        bForceTurnTarget;	//This flag indicates that TempFaceLocation should be used for a turn target in place of TargetLocation.
var protected vector                      TempFaceLocation;	//Temporary used by the state code - holds the location the unit should face
var protected name                        ReturnToState;	    //This is the state that EvaluateStance will return to unless the bDeferredGotoXXX flags are set
var protected float                       ExitCoverAnimTimer; //We don't need to play the entire get out of cover anim, it can blend into the run anim
var protected float                       ExitCoverAnimTime;  //We don't need to play the entire get out of cover anim, it can blend into the run anim - Sets the timeout
var protected EIdleTurretState			CurrentTurretState; //State corresponding to currently-playing turret idle animation.
var protected bool						StoredUpdateSkelWhenNotRendered; // Store off the bUpdateSkelWhenNotRendered so we can restore it after evaluate stance
//****************************************

//******** Fire State Variables **************************
var protected float                       m_fAimTimer;
var protected bool                        m_bRecenterAim;
var protected Vector2D                    m_TmpAimOffset;
var protected float                       FireState_AimingTimeout;
//****************************************

//******** Crouch State Variables ********
var protected bool bContinueCrouching;
//****************************************

//******** Panicked State Variables ********
var bool bStartedPanick;
//****************************************
// End Issue #15

cpptext
{
	/* Latent Function Declarations */
	DECLARE_FUNCTION(execPollTurnTowardsPosition);
}

function OverwriteReturnState(name NewReturnToState)
{
	ReturnToState = NewReturnToState;
}

//******** Public Interface Functions **************
//Call immediately after spawning, or as soon as OwningUnit becomes available (MP)
function Initialize(XGUnit OwningUnit)
{
	Unit = OwningUnit;
	UnitNative = Unit;
	UnitPawn = UnitNative.GetPawn();
	UnitPawnNative = UnitPawn;

	bIsCivilian = Unit.IsCivilianChar();
	bIsTurret = Unit.IsTurret();
	
	fIdleAnimRate = GetNextIdleRate();
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	AddHUDOverlayActor();
}

function bool IsStateInterruptible()
{
	local name StateName;

	StateName = GetStateName();
	return StateName == 'Idle' || StateName == 'Dormant' || StateName == 'PeekStart' || StateName == 'TargetingStart' || StateName == 'TargetingHold' || StateName == 'Panicked' || StateName == 'TurretIdle' || StateName == 'Crouch';
}

//This function allows external systems to request an examination of the present cover state 
//and facing of the unit. The 'EvaluateStance' state decides whether the unit should remain 
//in its present cover state or not. Examples of an events that could cause a unit to perform 
//this evaluation would be 1. the destruction of a piece of cover the unit was using and
//2. Changing a unit's target while in weapon aim mode
function CheckForStanceUpdate()
{
	if (IsStateInterruptible())
	{		
		`log("*********************** GOTO EvaluateStance ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name),'XCom_Anim');
		GotoState('EvaluateStance');
	}
	else
	{
		`log("*********************** CheckForStanceUpdate() bWaitingForStanceEval = true ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name),'XCom_Anim');
		bWaitingForStanceEval = true; //The system is otherwise occupied, the next time the idle state is entered the eval state will trigger
	}
}

//Instructs the state machine to do an automatic stance check the as soon as it returns to the idle state
native function CheckForStanceUpdateOnIdle();

//This is a specialized function that will orient the character towards their current cover direction. This may be necessary if the unit has been 
//oriented away during an action ( such as firing )
function ForceHeading(vector DesiredRotationVector)
{
		bForceTurnTarget = true;
		TempFaceLocation = Unit.Location + (DesiredRotationVector * 1000.0f);//TempFaceLocation will be the target location for our turn node animation
		UnitPawn.SetFocalPoint(TempFaceLocation);
		ForceStance(Unit.CurrentCoverDirectionIndex, eNoPeek); //This will lead to a latent turn
}

//This function is used to direct the unit into a particular stance (ignoring targeting information). An example of 
//when this might be used would be for when a unit is directed to open a door and is not facing the door.
function ForceStance(int ForceCoverIndex, UnitPeekSide ForcePeekSide)
{
	local name Statename;	

	//This function can only be called while the IdleStateMachine is dormant. If this rule needs to change talk to Ryan
	Statename = GetStateName();
	if( Statename == 'Dormant' )
	{
		bForceDesiredCover = true;
		DesiredCoverIndex = ForceCoverIndex;
		DesiredPeekSide = ForcePeekSide;
		`log("*********************** GOTO EvaluateStance ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		GotoState('EvaluateStance');
	}
	else
	{
		`log("ForceStance attemped on "@Unit@" in state "@Statename@"! ForceStance can only be called in the Dormant state!", , 'XCom_Anim');
	}
}

//Use to determine if the unit's stance is being evaluated ( this state should not be interrupted! )
function bool IsEvaluatingStance()
{
	local name Statename;

	Statename = GetStateName();
	if( bWaitingForStanceEval && Statename == 'Idle' )
	{
		`log("*********************** GOTO EvaluateStance ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		GotoState('EvaluateStance');
		return true;
	}

	return Statename == 'EvaluateStance';
}

simulated function bool IsDormant()
{
	return GetStateName() == 'Dormant';
}

function bool IsUnitSuppressing()
{
	return Unit.m_bSuppressing;
}

function bool IsUnitSuppressingArea()
{
	return Unit.m_bSuppressingArea;
}

//Activates the state machine, used when the unit returns to an idle action/state from a specialized one that overrides animations
//In some situations, actions may need to manually control the idle state machine. Use bForceDuringAction to signal this situation.
simulated function Resume(optional Actor UnlockResume=none, bool bForceDuringAction = false)
{
	local name Statename;
	local X2Action CurrentAction;

	CurrentAction = `XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(Unit);
	if (!bForceDuringAction && CurrentAction != none && !CurrentAction.bCompleted && X2Action_SyncVisualizer(CurrentAction) == none)
	{
		`redscreen("Idle state trying to resume while the visualization mgr is still running action" @ CurrentAction @ "for unit:" @ Unit @ "\nTrace:\n" @ GetScriptTrace());
	}

	if (kDormantLock != none && kDormantLock != UnlockResume)
	{
		`log("*********************** IdleStateMachine Resume() ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Locked by Actor" @ kDormantLock @ "but Resume request was made by" @ UnlockResume @ ", cannot Resume");
		return;     //  cannot resume with this actor
	}
	kDormantLock = none;

	Statename = GetStateName();
	
	if( Statename == 'Dormant' )
	{	
		`log("*********************** IdleStateMachine Resume() ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		if( ReturnToState == 'TargetingStart' || ReturnToState == 'TargetingHold' )
		{
			bWaitingForStanceEval = true;
			GotoState('TargetingStop');
		}
		else if( ReturnToState == 'PeekStart' )
		{
			bWaitingForStanceEval = true;
			GotoState('PeekStop');
		}
		else
		{
			GotoState('Idle');
		}			
	}
	else if( Statename != 'HunkeredDown' && Statename != 'NeuralDampingStunned' ) //These are equivalent to dormant - except that evaluate stance cannot be called from them
	{
		bDeferredGotoDormant = false;
		bDeferredGotoIdle = true;
	}
}

//De-activates the state machine, used when the unit intends to perform an action that will override the unit's animations. The force flag permits external users
//to make the system allow going dormant from states such as 'HunkeredDown'. In this situation, the caller is responsible for restoring the proper state when its business is done.
simulated function GoDormant(optional Actor LockResume=none, optional bool Force=false, optional bool bDisableWaitingForEval=false)
{
	local name Statename;	

	Statename = GetStateName();
	if (bDisableWaitingForEval)
		bWaitingForStanceEval = false;

	if (kDormantLock != none && kDormantLock != LockResume)
	{
		`log("*********************** IdleStateMachine GoDormant() ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Dormant state is locked by" @ kDormantLock @ "but new GoDormant request was made by" @ LockResume @ ", cannot GoDormant");
		return;     //  don't override existing lock
	}
	kDormantLock = LockResume;
	
	if( Statename != 'EvaluateStance' )
	{
		if( Force || (Statename != 'HunkeredDown' && Statename != 'Strangling' && Statename != 'Strangled' && Statename != 'NeuralDampingStunned')) //These are equivalent to dormant - except that evaluate stance cannot be called from them
		{			
			`log("*********************** IdleStateMachine GoDormant() ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("Dormant now locked by" @ LockResume,  `CHEATMGR.MatchesXComAnimUnitName(Unit.Name) && LockResume != none, 'XCom_Anim');
			`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			
			GotoState('Dormant');
		}
	}
	else
	{
		`log("*********************** IdleStateMachine Requested GoDormant() - bDeferredGotoDormant = true ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		bDeferredGotoIdle = false;
		bDeferredGotoDormant = true;
	}
}
//****************************************

//******** Private Functions **************
//Runs on a timer initiated by the Idle state.
function PerformPeek()
{
	local XComPresentationLayer Pres;
	local UITacticalHUD TacticalHUD;

	UnitState = UnitNative.GetVisualizedGameState();
	
	//Make sure the conditions for peeking are still valid
	if( !bIsCivilian &&
		GetStateName() == 'Idle' &&
		UnitState.GetNumVisibleEnemyUnits() > 0 && 
		UnitNative.m_eCoverState != eCS_None &&
		UnitPawn.bPlayedDeath == false )
	{
		// don't do normal peeks when somebody is being targeted. Otherwise they can bob their heads in front
		// of the user's view. Only the special hold peek on the target and shooter should be happening.
		Pres = `PRES;
		TacticalHUD = Pres != none ? Pres.GetTacticalHUD() : none;
		if(TacticalHUD == none || TacticalHUD.GetTargetingMethod() == none)
		{
			GotoState('PeekStart');
		}
	}
}

function PerformFlinch()
{
	if( IsStateInterruptible() && UnitPawnNative.GetAnimTreeController().GetAllowNewAnimations() )
	{
		GotoState('Flinch');
	}
}

function PerformCrouch()
{
	if( IsStateInterruptible() )
	{
		GotoState('Crouch');
	}
}

function EndCrouch()
{
	bContinueCrouching = false;
}

function SetPodTalker(XGUnit TalkingUnit)
{
	PodTalker = TalkingUnit;
}

function bool FacePod(out vector FacingTarget, optional XGAIGroup AIGroup = None)
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local XComGameState_Unit UnitStateToFace;
	local int ListenerIndex;
	local int ListenersChecked;
	local bool bFacesAwayFromPod;
	local bool bListenerFacesAwayFromPod;
	local vector AwayFromTarget;
	local int UseHistoryIndex;

	if( PodTalker == none )
	{
		return false;
	}
	
	if( (AIGroup == None) && (Unit.m_kBehavior != none) )
	{
		AIGroup = Unit.m_kBehavior.m_kPatrolGroup;
	}

	if( AIGroup == none || AIGroup.m_arrUnitIDs.Length <= 1 || Unit.GetAlertLevel() != eAL_Green )
	{
		return false;
	}

	History = `XCOMHISTORY;

	bFacesAwayFromPod = Unit.GetVisualizedGameState(UseHistoryIndex).GetMyTemplate().bFacesAwayFromPod;

	// face the location of the units. Since we might hit idle before the rest of our pod has arrived, we
	// need to be sure to face the location where they will end their move, and not where they actually are
	if(PodTalker.ObjectID != Unit.ObjectID)
	{
		// we are not the pod talker, so face the talkers location 
		UnitStateToFace = XComGameState_Unit(History.GetGameStateForObjectID(PodTalker.ObjectID,, UseHistoryIndex));
	}
	else
	{
		// we are the talker, select a random other person in this pod to talk to
		// pick a random index to start at, and then choose the first one that isn't us
		ListenerIndex = rand(AIGroup.m_arrUnitIDs.Length);
		for( ListenersChecked = 0; ListenersChecked < AIGroup.m_arrUnitIDs.Length; ListenersChecked++ )
		{
			if( AIGroup.m_arrUnitIDs[ListenerIndex] != Unit.ObjectID )
			{
				UnitStateToFace = XComGameState_Unit(History.GetGameStateForObjectID(AIGroup.m_arrUnitIDs[ListenerIndex], , UseHistoryIndex));
				if (UnitStateToFace != None )
				{
					bListenerFacesAwayFromPod = UnitStateToFace.GetMyTemplate().bFacesAwayFromPod;
					if (!bListenerFacesAwayFromPod || AIGroup.NumUnitsForPodTalking <= 1)
					{
						break;
					}
					else
					{
						UnitStateToFace = None;
					}
				}
			}
			
			ListenerIndex = (ListenerIndex + 1) % AIGroup.m_arrUnitIDs.Length;
		}
	}

	`assert(UnitStateToFace != none); // the only way this is possible is if the patrol unit array is bad, and is really serious (Or AdventMec logic is wrong)

	WorldData = `XWORLD;
	FacingTarget = WorldData.GetPositionFromTileCoordinates(UnitStateToFace.TileLocation);

	// If you face outward || you are the only unit to face inward
	if( bFacesAwayFromPod || AIGroup.NumUnitsForPodTalking == 1 )
	{
		// Face 180 from the talker
		AwayFromTarget = Unit.Location - FacingTarget;
		FacingTarget = Unit.Location + AwayFromTarget;
	}

	return true;
}

// Anywhere Idle should start call this instead
function PlayIdleAnim(bool ResetPodAnimation = false)
{
	local bool bAliensPresent;
	local EAlertLevel AlertLevel;
	local float PodRandom;
	local AnimNodeSequence PlayingSequence;
	local int UseHistoryIndex;
	UnitState = UnitNative.GetVisualizedGameState(UseHistoryIndex);

	bAliensPresent = UnitState.GetNumVisibleEnemyUnits(true, false, false, UseHistoryIndex) > 0;

	if(bIsTurret)
	{
		AnimParams.Looping = true;
		if( CurrentTurretState == eITS_None )
		{ 
			// Update turret state if this has never been set.  (For turrets dropped in via cheat command DropUnit)
			CurrentTurretState = UnitState.IdleTurretState;
		}
		GetTurretIdleAnim(AnimParams.AnimName, CurrentTurretState, bAliensPresent);
	}
	else
	{
		AlertLevel = Unit.GetVisualAlertLevel();

		AnimParams = default.AnimParams;
		AnimParams.PlayRate = fIdleAnimRate;
		AnimParams.Looping = true;
		if( AlertLevel == eAL_Green )
		{
			PodRandom = FRand();
			if( PodTalker != None && PodTalker == Unit && TalkerHasSomeoneToTalkTo )
			{
				if( PodRandom < PodTalkFidgetPercentage && UnitPawnNative.GetAnimTreeController().CanPlayAnimation('POD_TalkFidget') )
				{
					AnimParams.AnimName = 'POD_TalkFidget';
				}
				else
				{
					AnimParams.AnimName = 'POD_TalkIdle';
				}

				if( UnitPawnNative != None && UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
				{
					// If we are already playing a pod talk animation and we haven't finished it then let the animation play
					if( !UnitPawnNative.GetAnimTreeController().IsPlayingCurrentAnimation('POD_Talk') || ResetPodAnimation )
					{
						PlayingSequence = UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

						// Since we want to randomize how the green idle works set a timer to start this animation again
						SetTimer(PlayingSequence.AnimSeq.SequenceLength / fIdleAnimRate, false, nameof(ResetPodIdleAnimation), self);
					}
					
					return;
				}
			}
			
			if( PodRandom < PodIdleFidgetPercentage && UnitPawnNative.GetAnimTreeController().CanPlayAnimation('POD_Fidget') )
			{
				AnimParams.AnimName = 'POD_Fidget';
			}
			else
			{
				AnimParams.AnimName = 'POD_Idle';
			}
				
			if( UnitPawnNative != None && UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) == false )
			{
				// If you can't play pod anims you go yellow
				AlertLevel = eAL_Yellow;
			}
			else if(UnitPawnNative != None)
			{
				if( (!UnitPawnNative.GetAnimTreeController().IsPlayingCurrentAnimation('POD_Fidget') && !UnitPawnNative.GetAnimTreeController().IsPlayingCurrentAnimation('POD_Idle'))
				   || ResetPodAnimation )
				{
					// Since we want to randomize how the green idle works set a timer to start this animation again
					PlayingSequence = UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
					SetTimer(PlayingSequence.AnimSeq.SequenceLength / fIdleAnimRate, false, nameof(ResetPodIdleAnimation), self);
					
					if( UnitState.GetMyTemplate().bLockdownPodIdleUntilReveal )
					{
						UnitPawnNative.GetAnimTreeController().SetAllowNewAnimations(false);
					}
				}
				
				return;
			}
 		}

		// Anyone is red if they see an enemy
		if( bAliensPresent && !bIsCivilian )
		{
			AlertLevel = eAL_Red;
		}
		
		if( AlertLevel == eAL_Yellow )
		{
			switch( Unit.m_eCoverState )
			{
			case eCS_LowLeft:
			case eCS_LowRight:
				AnimParams.AnimName = 'LL_IdleAlert';
				break;
			case eCS_HighLeft:
			case eCS_HighRight:
				AnimParams.AnimName = 'HL_IdleAlert';
				break;
			case eCS_None:
				AnimParams.AnimName = 'NO_IdleAlertGunDwn';
				break;
			}
		}
		else if( AlertLevel == eAL_Red )
		{
			switch( Unit.m_eCoverState )
			{
			case eCS_LowLeft:
			case eCS_LowRight:
				AnimParams.AnimName = 'LL_Idle';
				break;
			case eCS_HighLeft:
			case eCS_HighRight:
				AnimParams.AnimName = 'HL_Idle';
				break;
			case eCS_None:
				AnimParams.AnimName = 'NO_IdleGunUp';
				break;
			}
		}
	}

	if( UnitPawnNative != None )
	{
		if(AnimParams.AnimName == '')
		{
			`Redscreen("No appropriate idle could be found! Falling back to a default. Visual Alert Level: " @ String(AlertLevel) @ ". Talk to Watson.");
			AnimParams.AnimName = 'NO_IdleAlertGunDwn';
		}

		UnitPawnNative.EnableFootIK(true);
		UnitPawnNative.EnableRMA(true, true);
		UnitPawnNative.EnableRMAInteractPhysics(true);
		UnitPawnNative.bSkipIK = false;
		AnimParams.BlendTime = UnitPawnNative.Into_Idle_Blend;
		UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}
}

function ResetPodIdleAnimation()
{
	if( GetStateName() != 'Dormant' && GetStateName() != 'Panicked')
	{
		PlayIdleAnim(true);
	}
}

function GetTurretIdleAnim(out name AnimName_out, EIdleTurretState eTurretState, bool bEnemiesVisible)
{
	`Assert(eTurretState != eITS_None);
	switch (eTurretState)
	{
		case eITS_AI_Inactive:				// Stunned state, on team AI
			AnimName_out = 'NO_StunnedIdle_Advent';
			break; 
		case eITS_XCom_Inactive:		// Stunned state, on team XCom.
			AnimName_out = 'NO_StunnedIdle_Xcom';
			break;
		case eITS_AI_ActiveTargeting:	// AI team active state, has targets visible.
		case eITS_AI_ActiveAlerted:		// AI team active state, has no targets visible.
			if(bEnemiesVisible)
			{
				AnimName_out = 'NO_IdleGunUp_Advent';
			}
			else
			{
				AnimName_out = 'NO_IdleAlertGunUpA_Advent';
			}
			break;
		case eITS_XCom_ActiveTargeting:	// XCom-controlled active state, has targets visible.
		case eITS_XCom_ActiveAlerted:	// XCom-controlled active state, has no targets visible.
			if(bEnemiesVisible)
			{
				AnimName_out = 'NO_IdleGunUp_Xcom';
			}
			else
			{
				AnimName_out = 'NO_IdleAlertGunUpA_Xcom';
			}
			break;
	}
}

function bool RequiresTurretTransitionAnim(EIdleTurretState NewTurretState)
{
	return GetTurretTransitionAnim(NewTurretState) != '';
}

// Only possible transition anims are now for stun.  All other hacking options transition directly from one team control to the next.
function name GetTurretTransitionAnim( EIdleTurretState NewTurretState )
{
	local name AnimName;
	if(CurrentTurretState != NewTurretState)
	{
		switch(CurrentTurretState)
		{
		// Turret down states to Turret Up states.
		case eITS_None:					// Initial state 
		case eITS_AI_Inactive:			// Stunned on team AI.
		case eITS_XCom_Inactive:		// Stunned on team XCom.
			if(NewTurretState == eITS_AI_ActiveAlerted
			   || NewTurretState == eITS_AI_ActiveTargeting)
			{
				AnimName = 'NO_StunnedStop_Advent';
			}
			else if( NewTurretState == eITS_XCom_ActiveAlerted
					|| NewTurretState == eITS_AI_ActiveTargeting )
			{
				AnimName = 'NO_StunnedStop_Xcom';
			}
			break;

			// Turret Up state to Turret Down states.
		case eITS_AI_ActiveTargeting:	// AI team active state, has targets visible.
		case eITS_AI_ActiveAlerted:		// AI team active state, has no targets visible.
		case eITS_XCom_ActiveTargeting:	// XCom-controlled active state, has targets visible.
		case eITS_XCom_ActiveAlerted:	// XCom-controlled active state, has no targets visible.
			if( NewTurretState == eITS_XCom_Inactive )
			{
				AnimName = 'NO_StunnedStart_Xcom';
			}
			else if( NewTurretState == eITS_AI_Inactive )
			{
				AnimName = 'NO_StunnedStart_Advent';
			}
			break;
		}
	}
	return AnimName;
}
//Returns true if a target has been found. Used by the EvaluateStance state
event bool SetTargetUnit()
{		
	local X2Action_ExitCover ExitCoverAction;
	local Vector NewTargetLocation;
	local Actor  NewTargetActor;
	local XGUnit TempUnit;
	local int CoverIndex;
	local int BestCoverIndex;
	local float CoverScore;
	local float BestCoverScore;	
	local bool bEnemiesVisible;
	local bool bFoundTarget;	
	local bool bCurrentlyTargeting;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;
	local XComGameStateHistory History;
	local X2TargetingMethod TargetingMethod;
	local UITacticalHUD TacticalHUD;
	local bool bActorFromTargetingMethod;
	local int HasEnemiesOnLeftPeek;
	local int HasEnemiesOnRightPeek;
	local UnitPeekSide PeekSide;
	local int CanSeeFromDefault;
	local int RequiresLean;
	local int UseHistoryIndex;
	// Variables for Issue #269
	local bool AimLocSet;
	local vector AimAtLocation;
	local array<vector> TargetLocations;

	History = `XCOMHISTORY;
	UnitState = UnitNative.GetVisualizedGameState(UseHistoryIndex);

	if( UnitState == None )
	{
		return false;
	}

	NewTargetActor = TargetActor;
	NewTargetLocation = TargetLocation;	
	bFoundTarget = false; //return value, indicates whether there were any targets for this unit, if there were none we clear the target info	
	bEnemiesVisible = UnitState.GetNumVisibleEnemyUnits() > 0;

	`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	`log("*** Processing SetTargetUnit ***", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

//******** Find the current values for NewTargetActor and NewTargetLocation **********	
	TacticalHUD = `PRES.GetTacticalHUD();
	if (TacticalHUD != none)
		TargetingMethod = TacticalHUD.GetTargetingMethod();
	else
		TargetingMethod = none;

	bCurrentlyTargeting = TargetingMethod != none;
	
	//If targeting is happening, and we are the shooter
	// Can also happen if the source unit is doing a multi turn ability
	bActorFromTargetingMethod = bCurrentlyTargeting && (TargetingMethod.Ability.OwnerStateObject.ObjectID == UnitState.ObjectID);
	if ( bActorFromTargetingMethod || (UnitState.m_MultiTurnTargetRef.ObjectID > 0) )
	{
		if( bActorFromTargetingMethod )
		{
			NewTargetActor = TargetingMethod.GetTargetedActor();
		}
		else
		{
			NewTargetActor = History.GetVisualizer(UnitState.m_MultiTurnTargetRef.ObjectID);
		}

		// can't Target yourself, so just early out to focus on the shooter
		if (NewTargetActor == Unit)
		{
			NewTargetActor = LastAttacker; 
			TargetActor = NewTargetActor;
			if( TargetActor != None )
			{
				TargetLocation = TargetActor.Location;
			}
			return TargetActor != none;
		}
		else if ( (bActorFromTargetingMethod && TargetingMethod.GetCurrentTargetFocus(NewTargetLocation)) || (NewTargetActor != None) )
		{
			if( NewTargetActor != None )
			{
				NewTargetLocation = NewTargetActor.Location;
			}
			// Begin Issue #269
			else
			{
				TargetingMethod.GetTargetLocations(TargetLocations);
				AimAtLocation = TargetLocations[0];
				AimLocSet = true;
			}
			// End Issue #269
			bFoundTarget = true;
		}
	}
	else if( Unit.CurrentExitAction != none ) //If we are performing a fire sequence
	{	
		`log("     Unit is performing a targeting action:", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		ExitCoverAction = Unit.CurrentExitAction;
			
		// Single line for Issue #269
		AimLocSet = true;
		bFoundTarget = true;
		NewTargetActor = ExitCoverAction.PrimaryTarget;
		if( ExitCoverAction.PrimaryTarget != none )
		{
			if( ExitCoverAction.PrimaryTarget == Unit )
			{
				`log("          *ExitCover action has a target, it is ourselves. Do Nothing.", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				bFoundTarget = false;
				// Begin Issue #269
				AimLocSet = false;
			}
			else
			{
				`log("          *ExitCover action has a target, aiming at"@NewTargetActor, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				// Issue #269 These two ExitCoverAction properties are the principle reason for introducing AimAtLocation
				AimAtLocation = ExitCoverAction.AimAtLocation;
				NewTargetLocation = ExitCoverAction.TargetLocation;
			}
		}
		else
		{
			`log("          *ExitCover action has no primary target, aiming at"@ExitCoverAction.TargetLocation, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			AimAtLocation = ExitCoverAction.AimAtLocation;
			NewTargetLocation = ExitCoverAction.TargetLocation;
			// End Issue #269
		}			
	}
	else if( bEnemiesVisible ) //If enemies are visible but we are not in a targeting action
	{
		`log("     Unit is idle and there are visible enemies:", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');		
		//Face enemies that are attacking us (and visible) first, but not if they are dead or dying
		if (LastAttacker != none && 
			LastAttacker.IsAlive() &&
			!LastAttacker.GetVisualizedGameState().IsIncapacitated() &&
			Unit.GetDirectionInfoForTarget(LastAttacker.GetVisualizedGameState(), OutVisibilityInfo, CoverIndex, PeekSide, CanSeeFromDefault, RequiresLean) )
		{			
			`log("          *LastAttacker is not none, aiming at LastAttacker:"@LastAttacker, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			NewTargetActor = LastAttacker;
		}
		else //Fall back to facing the closest enemy
		{
			TestEnemyUnitsForPeekSides(DesiredCoverIndex, HasEnemiesOnLeftPeek, HasEnemiesOnRightPeek, UseHistoryIndex);
			if( (DesiredPeekSide == ePeekLeft && HasEnemiesOnLeftPeek == 1) || (DesiredPeekSide == ePeekRight && HasEnemiesOnRightPeek == 1) )
			{
				NewTargetActor = GetClosestEnemyForPeekSide(DesiredCoverIndex, DesiredPeekSide);
			}
			else if( class'X2TacticalVisibilityHelpers'.static.GetClosestVisibleEnemy(UnitNative.ObjectID, OutVisibilityInfo, UseHistoryIndex) )
			{
				NewTargetActor = XGUnit( History.GetVisualizer(OutVisibilityInfo.TargetID) );
			}

			`log("          *LastAttacker is none, aiming at closest visible enemy:"@NewTargetActor, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		}

		if( NewTargetActor != none )
		{
			bFoundTarget = true;			
			NewTargetLocation = NewTargetActor.Location;
			TempUnit = XGUnit(NewTargetActor);
			if( TempUnit != None )
			{
				NewTargetLocation = TempUnit.GetPawn().GetHeadshotLocation();
			}
		}
	}
	else //In the absence of a valid target, we should choose a valid cover direction and use the cover
	{
		`log("     No targets were found, clearing targeting state", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		ClearTargetInformation();
		
		BestCoverScore = 0.0f;
		BestCoverIndex = -1;

		if( UnitNative.CanUseCover() )
		{
			CurrentCoverPeekData = UnitNative.GetCachedCoverAndPeekData(UseHistoryIndex);
			for (CoverIndex = 0; CoverIndex < 4; CoverIndex++)
			{
				if( CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].bHasCover == 1 )
				{
					CoverScore = 1.0f;
					if( CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].LeftPeek.bHasPeekaround == 1 ||
						CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].RightPeek.bHasPeekaround == 1 )
					{
						CoverScore += 1.0f;
					}

					if( DesiredCoverIndex == CoverIndex )
					{
						CoverScore += 0.1f;
					}

					if( CoverScore > BestCoverScore )
					{
						BestCoverIndex = CoverIndex;
						BestCoverScore = CoverScore;
					}
				}
			}		

			bFoundTarget = true;
			NewTargetActor = none;
			if( BestCoverIndex > -1 )
			{
				NewTargetLocation = Unit.Location + (CurrentCoverPeekData.CoverDirectionInfo[BestCoverIndex].CoverDirection * 1000.0f);
			}
			else
			{
				NewTargetLocation = Unit.Location + (Vector(Unit.Rotation) * 1000.0f); // Aim straight forward
			}
		}	
	}
//************************************************************************************
	
//******** Ascertain whether the target/target location, or our location, has changed **********
	if( bFoundTarget )
	{
		`log("     A target was found, processing the target:", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		`log("          *(NewTargetLocation != TargetLocation):"@(NewTargetLocation != TargetLocation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');			
		TargetLocation = NewTargetLocation;

		`log("          *(NewTargetActor != TargetActor):"@(NewTargetActor != TargetActor), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		// Check to see if we were previously targeting a unit and no longer are
		TempUnit = XGUnit(TargetActor);
		if( TempUnit != none && 
		    !bActorFromTargetingMethod &&
			TempUnit.IdleStateMachine.LastAttacker != none &&
			TempUnit.IdleStateMachine.LastAttacker == Unit) //In order for us clearing the last attacker to be valid, we must have been the last attacker
		{	
			TempUnit.IdleStateMachine.LastAttacker = none;
		}

		TargetActor = NewTargetActor;			

		//If the new target actor is an XGUnit, mark us as an attacker
		TempUnit = XGUnit(TargetActor);
		if(TempUnit != none && bActorFromTargetingMethod && TempUnit.IdleStateMachine.LastAttacker != Unit)
		{   
			TempUnit.IdleStateMachine.LastAttacker = Unit;
			TempUnit.IdleStateMachine.CheckForStanceUpdate(); //Tell the target that we are targeting them now
		}
	}
//**********************************************************************************************
	// Single line for Issue #269
	UnitPawn.TargetLoc = AimLocSet ? AimAtLocation : TargetLocation;

	`log("     SetTargetUnit returning:"@bFoundTarget, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	`log("*** End Processing SetTargetUnit ***", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

	`assert(TargetActor != Unit);
	return bFoundTarget;
}

//Clears TargetActor and notifies the target
simulated function ClearTargetInformation()
{
	local XGUnit TempUnit;

	//If we had a previous TargetActor, and they were a unit, notify them that we are no longer targeting them
	TempUnit = XGUnit(TargetActor);
	if( TempUnit != none && 
		TempUnit.IdleStateMachine.LastAttacker != none && 
		TempUnit.IdleStateMachine.LastAttacker == Unit)//In order for us clearing the last attacker to be valid, we must have been the last attacker		
	{   
		TempUnit.IdleStateMachine.LastAttacker = none;
	}

	TargetActor = none;
}

function TestEnemyUnitsForPeekSides(int CoverIndex, out int HasEnemiesOnLeftPeek, out int HasEnemiesOnRightPeek, optional int HistoryIndex = -1)
{
	local array<StateObjectReference> EnemyUnitArray;
	local StateObjectReference EnemyReference;
	local XGUnit EnemyUnit;
	local int bCanSeeDefaultFromDefault;
	local int RequiresLean;
	local int CoverIndexToEnemy;
	local UnitPeekSide PeekSide;
	local XComGameStateHistory History;
	local Vector TargetLoc;

	History = `XCOMHISTORY;

	HasEnemiesOnLeftPeek = 0;
	HasEnemiesOnRightPeek = 0;

	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(Unit.ObjectID, EnemyUnitArray, , HistoryIndex);
	foreach EnemyUnitArray(EnemyReference)
	{
		EnemyUnit = XGUnit(History.GetVisualizer(EnemyReference.ObjectID));
		if( EnemyUnit != none && EnemyUnit.IsAlive() )
		{
			Unit.GetStepOutCoverInfo(EnemyUnit.GetVisualizedGameState(), TargetLoc, CoverIndexToEnemy, PeekSide, RequiresLean, bCanSeeDefaultFromDefault, HistoryIndex);
			if( CoverIndex == CoverIndexToEnemy )
			{
				if( PeekSide == ePeekLeft )
				{
					HasEnemiesOnLeftPeek = 1;
				}
				else if( PeekSide == ePeekRight )
				{
					HasEnemiesOnRightPeek = 1;
				}
			}
		}
	}
}

function XGUnit GetClosestEnemyForPeekSide(int CoverIndex, UnitPeekSide PeekSide)
{
	local array<StateObjectReference> EnemyUnitArray;
	local StateObjectReference EnemyReference;
	local XGUnit EnemyUnit;
	local int CanSeeFromDefault;
	local int RequiresLean;
	local int CoverIndexToEnemy;
	local UnitPeekSide PeekSideToEnemy;
	local XComGameStateHistory History;
	local float BestDistanceSquared;
	local float DistanceSquared;
	local XGUnit TargetUnit;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;

	History = `XCOMHISTORY;

	BestDistanceSquared = -1.0f;
	TargetUnit = None;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(Unit.ObjectID, EnemyUnitArray);
	foreach EnemyUnitArray(EnemyReference)
	{
		EnemyUnit = XGUnit(History.GetVisualizer(EnemyReference.ObjectID));
		if( EnemyUnit.IsAlive() )
		{
			Unit.GetDirectionInfoForTarget(EnemyUnit.GetVisualizedGameState(), OutVisibilityInfo, CoverIndexToEnemy, PeekSideToEnemy, CanSeeFromDefault, RequiresLean);
			if( CoverIndex == CoverIndexToEnemy && PeekSideToEnemy == PeekSide )
			{
				// Determine Distance
				DistanceSquared = VSizeSq(Unit.Location - EnemyUnit.Location);
				if( DistanceSquared < BestDistanceSquared || BestDistanceSquared == -1.0f )
				{
					BestDistanceSquared = DistanceSquared;
					TargetUnit = EnemyUnit;
				}
			}
		}
	}

	return TargetUnit;
}

//This function should only be called if there is a current target. Reference params return the desired cover index and peek side for the current target.
event GetDesiredCoverState(out int CoverIndex, out UnitPeekSide PeekSide)
{
	local XGUnit TargetUnit;
	local Vector ToTarget;  //Used for special case below
	local Vector ToRight;   //Used for special case below
	local float TempDot;    //Used for special case below
	local int bCanSeeFromDefault;
	local int bRequiresLean;
	local UnitPeekSide PreviousPeekSide;
	local int PreviousCoverIndex;
	local int HasEnemiesOnLeftPeek;
	local int HasEnemiesOnRightPeek;
	local int VisualizationHistoryIndex;
	local XComGameState_Unit TargetUnitState;
	// New variables, and one removed, for Issue #269
	//local GameRulesCache_VisibilityInfo OutVisibilityInfo;
	local bool bShouldStepOut, bActorFromTargetingMethod;
	local actor TestActor;
	local X2TargetingMethod TargetingMethod;
	local UITacticalHUD TacticalHUD;
	local vector DummyVector;

	UnitState = UnitNative.GetVisualizedGameState(VisualizationHistoryIndex);

	PreviousPeekSide = PeekSide;
	PreviousCoverIndex = DesiredCoverIndex;

	if( Unit.CanUseCover()) //CoverIndex and PeekSide are only relevant from cover
	{
		if( Unit.CurrentExitAction != none && Unit.CurrentExitAction.bUsePreviousGameState )
		{
			VisualizationHistoryIndex = Unit.CurrentExitAction.CurrentHistoryIndex - 1;
		}

		if( TargetActor != none && TargetActor.IsA('XGUnit') )
		{
			TargetUnit = XGUnit(TargetActor);
			if( TargetUnit != None )
			{
				TargetUnitState = TargetUnit.GetVisualizedGameState();
			}
		// Start Issue #269
		}
		// Issue #269 GetSteoOutCoverInfo() calls GetDirectionInfoForTarget()/GetDirectionInfoForPosition() as appropriate
		// and performs logic as to whether a stepout should occur for X2Action_ExitCover
		/// HL-Docs: ref:Bugfixes; issue:269
		/// Fix some edge cases in `XComIdleAnimationStateMachine` regarding idle animations, targeting, and step-outs
		bShouldStepOut=Unit.GetStepOutCoverInfo(TargetUnitState, TargetLocation, CoverIndex, PeekSide, bRequiresLean, bCanSeeFromDefault);
		if(CoverIndex==0 && Unit.GetCoverType(0, VisualizationHistoryIndex)==CT_None)
		{
			//There's a bug in native code which means sometimes, CoverIndex 0 instead of -1 for "no cover direction"
			CoverIndex=-1;
		}
		// Issue #269 if we should match the stepout (ie are either targeting or have an active X2Action_ExitCover), and bShouldStepOut,
		// then no further manipulation of CoverIndex/PeekSide is wanted.
		// To avoid adding properties to a native class, must repeat some SetTargetUnit() logic.
		if (bShouldStepOut)
		{
			if (Unit.CurrentExitAction!=none && Unit.CurrentExitAction.PrimaryTarget!=Unit)
			{
				return;
			}

			TacticalHUD = `PRES.GetTacticalHUD();
			if (TacticalHUD != none)
			{
				TargetingMethod = TacticalHUD.GetTargetingMethod();
			}
	
			//If targeting is happening, and we are the shooter
			// Can also happen if the source unit is doing a multi turn ability
			bActorFromTargetingMethod = TargetingMethod != none && (TargetingMethod.Ability.OwnerStateObject.ObjectID == UnitState.ObjectID);
			if ( bActorFromTargetingMethod || (UnitState.m_MultiTurnTargetRef.ObjectID > 0) )
			{
				TestActor = bActorFromTargetingMethod ? TargetingMethod.GetTargetedActor() : `XCOMHISTORY.GetVisualizer(UnitState.m_MultiTurnTargetRef.ObjectID);
				if (TestActor != Unit && (TestActor!=none || (bActorFromTargetingMethod && TargetingMethod.GetCurrentTargetFocus(DummyVector))))
				{
					return;
				}
			}
		}
		// End Issue #269
		CurrentCoverPeekData = UnitNative.GetCachedCoverAndPeekData(VisualizationHistoryIndex);

		TestEnemyUnitsForPeekSides(CoverIndex, HasEnemiesOnLeftPeek, HasEnemiesOnRightPeek, VisualizationHistoryIndex);

		if( (DesiredCoverIndex > -1) && DesiredCoverIndex == PreviousCoverIndex && ((PreviousPeekSide == ePeekLeft && CurrentCoverPeekData.CoverDirectionInfo[DesiredCoverIndex].LeftPeek.bHasPeekaround == 1) ||
		   (PreviousPeekSide == ePeekRight && CurrentCoverPeekData.CoverDirectionInfo[DesiredCoverIndex].RightPeek.bHasPeekaround == 1)) )
		{
			if( HasEnemiesOnLeftPeek == 0 && HasEnemiesOnRightPeek == 0 )
			{
				PeekSide = PreviousPeekSide;
			}
			else if( Unit.GetCoverType(DesiredCoverIndex, VisualizationHistoryIndex) == CT_MidLevel && bCanSeeFromDefault == 1 && PreviousPeekSide != eNoPeek && PreviousPeekSide != PeekSide )
			{
				// Keep your peek side if you can see the target from your default tile
				// Don't keep it if we have enemies on the new peek side and none on the previous peek side.
				if( ((PreviousPeekSide == ePeekLeft && PeekSide == ePeekRight) && (HasEnemiesOnLeftPeek == 0 && HasEnemiesOnRightPeek == 1) ||
					(PreviousPeekSide == ePeekRight && PeekSide == ePeekLeft) && (HasEnemiesOnLeftPeek == 1 && HasEnemiesOnRightPeek == 0))
					== false )
				{
					PeekSide = PreviousPeekSide;
				}
			}
		}		

		//If we have a cover direction but no peek then it means we can see the enemy unit from our default tile (ie. the unit doesn't need to use a peek tile to see the target)	
		//We don't have animations to represent this state though, so pick a peek side for the sake of the animation system
		if( CoverIndex > -1 && PeekSide == eNoPeek )
		{	
			if( VSizeSq(TargetLocation - CurrentCoverPeekData.DefaultVisibilityCheckLocation) > 0.0f )
			{			
				ToTarget = Normal(TargetLocation - CurrentCoverPeekData.DefaultVisibilityCheckLocation);

				//Determine whether the target is even in the direction of our cover direction, if not then we don't use cover
				`assert( CoverIndex >= 0 );
				TempDot = NoZDot(CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].CoverDirection, ToTarget);
				if( TempDot > 0.01f ) //0.01f so that there is a little bit of give in our determination. This is mainly to handle adjacent or very close enemies
				{
					//Pick the cover side that is closest to facing the target
					ToRight = TransformVectorByRotation(rot(0,16384,0), CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].CoverDirection);
					TempDot = NoZDot(ToRight, ToTarget);
					// Begin Issue #269
					// If the previous cover direction is not the same, then peekside should be reestablished from scratch, no reliance on  PreviousPeekSide
					If (PreviousCoverIndex!=CoverIndex)
					{
						if(CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].RightPeek.bHasPeekaround > 0)
						{
							PreviousPeekSide = ePeekRight;
						}
						else if(CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].LeftPeek.bHasPeekaround > 0)
						{
							PreviousPeekSide = ePeekLeft;
						}
						else
						{
							PreviousPeekSide = eNoPeek;
						}
					}
					if(TempDot > 0.0f && (PreviousPeekSide == eNoPeek
						|| CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].RightPeek.bHasPeekaround > 0))
					{
						PeekSide = ePeekRight;
					}
					else if(PreviousPeekSide == eNoPeek || CurrentCoverPeekData.CoverDirectionInfo[CoverIndex].LeftPeek.bHasPeekaround > 0)
					 //End Issue #269
					{
						PeekSide = ePeekLeft;
					}
					else
					{
						//No peeks are possible, just keep our current peek side
						// Jwats: This should only happen when we don't actually have a target (we set a target loc in the direction of the cover)
						PeekSide = PreviousPeekSide;
					}
				}
				else
				{
					//The enemy unit is not in the direction of our cover, just turn to face them
					CoverIndex = -1;
					PeekSide = eNoPeek;
				}
			}
			else
			{
				//Fail through for cases where the target is on top of us. In this situation just face(?) the target, or spin like a helicopter TO VICTORY
				CoverIndex = -1;
				PeekSide = eNoPeek;
			}			
		}		
	}
	else
	{
		CoverIndex = -1;
		PeekSide = eNoPeek;
	}
}

function bool IsUnitPanicked()
{
	local bool ShouldPanick;
	UnitState = UnitNative.GetVisualizedGameState();

	ShouldPanick = UnitState.bPanicked;
	if( !bStartedPanick )
	{
		ShouldPanick = ShouldPanick && UnitState.ActionPoints.Length == 0;
	}

	return ShouldPanick;
}

function bool ShouldUseTargetingAnims()
{
	local bool ShouldHoldPeek;
	local int CoverDirection;
	local UnitPeekSide PeekSide;
	local int RequiresLean;
	local int SeeDefaultFromDefault;
	local XGUnit TargetUnit;
	local XComGameState_Unit TargetUnitState;

	TargetUnit = XGUnit(TargetActor);
	if( TargetUnit != None )
	{
		TargetUnitState = TargetUnit.GetVisualizedGameState();
	}

	ShouldHoldPeek = Unit.GetStepOutCoverInfo(TargetUnitState, TargetLocation, CoverDirection, PeekSide, RequiresLean, SeeDefaultFromDefault);
	if( Unit.m_eCoverState == eCS_LowLeft || Unit.m_eCoverState == eCS_LowRight )
	{
		// LowCover holds peek even if it isn't going to step out
		ShouldHoldPeek = true;
	}

	return bTargeting && Unit.m_eCoverState != eCS_None && ShouldHoldPeek;
}

native latent function TurnTowardsPosition(const out vector Position, optional bool AwayFromCover = false);
native static function float GetNextIdleRate(); //This function reads from a table of anim rates to ensure that units do not randomly choose the same rate
//****************************************

auto state Dormant
{	
	event BeginState(name PreviousStateName)
	{
		if (Unit != none)
		{
			`log("*********************** BEGIN Dormant ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		}

		ReturnToState = PreviousStateName;

		if (UnitPawn != None) UnitPawn.EnableLeftHandIK(false);
	}

	event EndState(name NewStateName)
	{		
		if (Unit != none)
		{
			`log("*********************** END Dormant ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		}
	}
begin:
}

state Idle
{
	event BeginState(name PreviousStateName)
	{
		`log("*********************** BEGIN Idle ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{		
		`log("*********************** END Idle ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
	}

begin:
	bDeferredGotoIdle = false;

	if( !Unit.IsAlive() || UnitNative.GetVisualizedGameState().IsIncapacitated() || !Unit.GetIsAliveInVisualizer() )
	{
		//In the case where the unit is dead, make the idle state machine dormant
		GotoState('Dormant');
	}

	if( bWaitingForStanceEval )
	{		
		`log("*********************** GOTO EvaluateStance ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		GotoState('EvaluateStance');
	}

	if( bIsTurret && Unit.IsAlive() )
	{
		GotoState('TurretIdle');
	}
	else if( IsUnitPanicked() ) 
	{
		GotoState('Panicked');
	}
	else if( Unit.IsHunkeredDown() )
	{
		GotoState('HunkeredDown');
	}
	else if( ShouldUseTargetingAnims() )
	{
		GotoState('TargetingStart');
	}
	else if( PersistentEffectIdleName != '' )
	{
		GotoState('PersistentEffect');
	}
	else
	{
		if(FacePod(TempFaceLocation))
		{
			// in AI patrols, have the pod members turn to have each other while talking
			TurnTowardsPosition(TempFaceLocation);
		}

		PlayIdleAnim();
	}
	
	PeekTimeoutCurrent = Lerp(PeekTimeoutMin, PeekTimeoutMax, FRand());
	SetTimer(PeekTimeoutCurrent, false, nameof(PerformPeek), self);
}

state PeekStart
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN PeekStart ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END PeekStart ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
	}

begin:

	if (!UnitPawn.bPlayedDeath)
	{
		//Play and finish the intro anim
		AnimParams = default.AnimParams;

		switch (Unit.m_eCoverState)
		{
		case eCS_LowLeft:
			AnimParams.AnimName = 'LL_Peek_Start';
			break;
		case eCS_LowRight:
			AnimParams.AnimName = 'LR_Peek_Start';
			break;
		case eCS_HighLeft:
			AnimParams.AnimName = 'HL_Peek_Start';
			break;
		case eCS_HighRight:
			AnimParams.AnimName = 'HR_Peek_Start';
			break;
		}
		if (Unit.m_eCoverState != eCS_None)
		{
			FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}

		//Play the loop anim once
		switch (Unit.m_eCoverState)
		{
		case eCS_LowLeft:
			AnimParams.AnimName = 'LL_Peek_Loop';
			break;
		case eCS_LowRight:
			AnimParams.AnimName = 'LR_Peek_Loop';
			break;
		case eCS_HighLeft:
			AnimParams.AnimName = 'HL_Peek_Loop';
			break;
		case eCS_HighRight:
			AnimParams.AnimName = 'HR_Peek_Loop';
			break;
		}

		if (Unit.m_eCoverState != eCS_None)
		{
			FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}

		GotoState('PeekStop');
	}
	else
	{
		GotoState('Dormant');
	}
}

state PeekStop
{
	event BeginState(name PreviousStateName)
	{
		`log("*********************** BEGIN PeekStop ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{
		`log("*********************** END PeekStop ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
	}

begin:

	if (!UnitPawn.bPlayedDeath)
	{
		//Play and finish the outro anim
		switch(Unit.m_eCoverState)
		{
			case eCS_LowLeft:
				AnimParams.AnimName = 'LL_Peek_Stop';
				break;
			case eCS_LowRight:
				AnimParams.AnimName = 'LR_Peek_Stop';
				break;
			case eCS_HighLeft:
				AnimParams.AnimName = 'HL_Peek_Stop';
				break;
			case eCS_HighRight:
				AnimParams.AnimName = 'HR_Peek_Stop';
				break;
		}
		if(Unit.m_eCoverState != eCS_None)
		{
			FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}
		GotoState('Idle');
	}
	else
	{
		GotoState('Dormant');
	}
}

state Flinch
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN Flinch ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		UnitPawn.EnableLeftHandIK(false);
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END Flinch ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
	}

begin:	
	AnimParams = default.AnimParams;
	switch (Unit.m_eCoverState)
	{
		case eCS_LowLeft:
		case eCS_HighLeft:
			AnimParams.AnimName = 'HL_Flinch';
			break;
		case eCS_LowRight:
		case eCS_HighRight:
			AnimParams.AnimName = 'HR_Flinch';
			break;
		case eCS_None:
			// Jwats: No cover randomizes between the 2 animations
			if (Rand(2) == 0)
			{
				AnimParams.AnimName = 'HL_Flinch';
			}
			else
			{
				AnimParams.AnimName = 'HR_Flinch';
			}
			break;
	}

	FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	
	GotoState('Idle');
}

state Crouch
{
	event BeginState(name PreviousStateName)
	{
		`log("*********************** BEGIN Crouch ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		bContinueCrouching = true;
	}

	event EndState(name NewStateName)
	{
		`log("*********************** END Crouch ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
	}

begin:
	if( UnitState.GetMyTemplate().CharacterGroupName != 'Sectopod' && Unit.m_eCoverState != eCS_LowLeft && Unit.m_eCoverState != eCS_LowRight )
	{
		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'HL_Stand2Crouch';
		if( UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
		{
			FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}

		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'LL_Idle';
		AnimParams.Looping = false;
		if( UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
		{
			UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
			while( bContinueCrouching )
			{
				Sleep(0.0f);
			}
		}

		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'LL_Crouch2StandA';
		if( UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
		{
			FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}
	}

	GotoState('Idle');
}


state TargetingStart
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN TargetingStart ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END TargetingStart ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
		// Aim at your target?
	}

begin:
	//Play and finish the intro anim
	AnimParams = default.AnimParams;
	
	switch (Unit.m_eCoverState)
	{
		case eCS_LowLeft:
			AnimParams.AnimName = 'LL_Peek_Start';
			break;
		case eCS_LowRight:
			AnimParams.AnimName = 'LR_Peek_Start'; 
			break;
		case eCS_HighLeft:
			AnimParams.AnimName = 'HL_Peek_Start';
			break;
		case eCS_HighRight:
			AnimParams.AnimName = 'HR_Peek_Start';
			break;
		case eCS_None:
			break;
	}

	if (Unit.m_eCoverState != eCS_None)
	{
		FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	}

	GotoState('TargetingHold');
}

state TargetingHold
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN TargetingHold ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END TargetingHold ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
		// Aim at your target?
	}

begin:
	//Play and sustain the loop anim
	AnimParams = default.AnimParams;
	AnimParams.Looping = true;

	switch( Unit.m_eCoverState )
	{
	case eCS_LowLeft:
		AnimParams.AnimName = 'LL_Peek_Targeting_Loop';
		break;
	case eCS_LowRight:
		AnimParams.AnimName = 'LR_Peek_Targeting_Loop';
		break;
	case eCS_HighLeft:
		AnimParams.AnimName = 'HL_Peek_Targeting_Loop';
		break;
	case eCS_HighRight:
		AnimParams.AnimName = 'HR_Peek_Targeting_Loop';
		break;
	}

	if( Unit.m_eCoverState != eCS_None && UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
	{
		UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}
	else
	{
		switch( Unit.m_eCoverState )
		{
		case eCS_LowLeft:
			AnimParams.AnimName = 'LL_Peek_Loop';
			break;
		case eCS_LowRight:
			AnimParams.AnimName = 'LR_Peek_Loop';
			break;
		case eCS_HighLeft:
			AnimParams.AnimName = 'HL_Peek_Loop';
			break;
		case eCS_HighRight:
			AnimParams.AnimName = 'HR_Peek_Loop';
			break;
		}

		if( Unit.m_eCoverState != eCS_None )
		{
			UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
		}
	}

	// Hold your peek until you aren't targeting or need a stance eval
	while( ShouldUseTargetingAnims() )
	{
		sleep(0.0f);
	}

	GotoState('TargetingStop');
}

state TargetingStop
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN TargetingStop ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END TargetingStop ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
		// Aim at your target?
	}

begin:	

	if (!UnitPawn.bPlayedDeath)
	{
		//Play and finish the outro anim
		AnimParams = default.AnimParams;
		switch(Unit.m_eCoverState)
		{
			case eCS_LowLeft:
				AnimParams.AnimName = 'LL_Peek_Stop';
				break;
			case eCS_LowRight:
				AnimParams.AnimName = 'LR_Peek_Stop';
				break;
			case eCS_HighLeft:
				AnimParams.AnimName = 'HL_Peek_Stop';
				break;
			case eCS_HighRight:
				AnimParams.AnimName = 'HR_Peek_Stop';
				break;
			case eCS_None:
				break;
		}

		if(Unit.m_eCoverState != eCS_None)
		{
			FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}

		GotoState('Idle');
	}
	else
	{
		GotoState('Dormant');
	}
}

state Signal
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN Signal ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		if( PreviousStateName == 'EvaluateStance' )
		{
			CheckForStanceUpdateOnIdle();
			// And keep whatever the return state is.  Go back to that.
		}
		else
		{
			ReturnToState = PreviousStateName;
		}
		
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END Signal ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

begin:
	TurnTowardsPosition(SignalFaceLocation);

	AnimParams = default.AnimParams;
	AnimParams.AnimName = SignalAnimationName;
	if( UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
	{
		FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	}

	GotoState(ReturnToState);
}

state Panicked
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN Panic ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END Panic ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{		
	}

begin:
	//Play and finish the intro anim
	if( !bStartedPanick )
	{
		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'HL_Panic_Start';
		AnimParams.PlayRate = fIdleAnimRate;
		bStartedPanick = true;
		FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	}
	
	
	//Play and sustain the loop anim
	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'HL_Panic_Loop';
	AnimParams.Looping = true;
	AnimParams.PlayRate = fIdleAnimRate;
	if( UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
	{
		UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}
	else
	{
		// Do regular idle when there is no panic animation.  (Zombies)
		UnitPawn.EnableLeftHandIK(false);
		PlayIdleAnim();
	}

	while( IsUnitPanicked() )
	{
		sleep(0.0f);
	}
	
	//Play and finish the outro anim
	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'HL_Panic_Stop';
	AnimParams.Looping = false;
	bStartedPanick = false;
	AnimParams.PlayRate = fIdleAnimRate;
	FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	GotoState('Idle');
}

state HunkeredDown
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN HunkeredDown ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END HunkeredDown ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{		
	}

begin:
	//Play and finish the intro anim
	AnimParams = default.AnimParams;
	switch (Unit.m_eCoverState)
	{
		case eCS_LowLeft:
		case eCS_LowRight:
			AnimParams.AnimName = 'LL_HunkerDwn_Start';
			break;
		case eCS_HighRight:
		case eCS_HighLeft:
		case eCS_None:
			AnimParams.AnimName = 'HL_HunkerDwn_Start';
			break;
	}
	FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	
	//Play and sustain the loop anim
	AnimParams = default.AnimParams;
	AnimParams.Looping = true;
	AnimParams.AnimName = 'HL_HunkerDwn_Loop';
	UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	while(Unit.IsHunkeredDown())
	{
		sleep(0.0f);
	}
	
	//Play and finish the outro anim
	AnimParams = default.AnimParams;
	AnimParams.PlayRate = -1.0f;
	switch (Unit.m_eCoverState)
	{
		case eCS_LowLeft:
		case eCS_LowRight:
			AnimParams.AnimName = 'LL_HunkerDwn_Start';
			break;
		case eCS_HighRight:
		case eCS_HighLeft:
		case eCS_None:
			AnimParams.AnimName = 'HL_HunkerDwn_Start';
			break;
	}
	FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	GotoState('Idle');
}

//This state is entered whenever this unit determines that it needs to
//change facing. The facing could change as a result of losing cover, 
//enemies moving, or similar external events. This is the ONLY state in
//this object that can run while the state machine is 'Dormant'
state EvaluateStance
{
	//This function verifies that the unit is facing in the direction it thinks is. Root motion animations can potentially
	//leave a unit in a state where it is not facing a direction that matches its CoverDirectionIndex
	function bool UnitFacingMatchesDesiredDirection()
	{
		return !UnitNeedsToRotate(GetDesiredFaceLocation());
	}

	function bool UnitNeedsToRotate(vector FaceLocation)
	{
		local vector CurrentFacing;
		local vector DesiredFacing;
		local float Dot;
		local float DegreesOff;

		CurrentFacing = Vector(UnitPawn.Rotation);
		DesiredFacing = Normal(FaceLocation - Unit.Location);
		Dot = NoZDot(CurrentFacing, DesiredFacing);
		DegreesOff = Acos(Dot) * RadToDeg;
		
		return DegreesOff > 5.0f;
	}

	function vector GetDesiredFaceLocation()
	{
		local vector DesiredFaceLocation;

		if( DesiredCoverIndex > -1 && !bForceTurnTarget )
		{
			//Reverse facings since the animations are named after shoulders against cover and not facing
			// Begin Issue #269
			// There may actually be no peekaround in the requested cover direction/peekside combination
			if( DesiredPeekSide == ePeekLeft && Unit.GetCoverType(DesiredCoverIndex)!=CT_None)
			{
				DesiredFaceLocation = Unit.Location + `XWORLD.GetPeekLeftDirection(`IDX_TO_DIR(DesiredCoverIndex) , false) * 1000.0f;
			}
			else if( DesiredPeekSide == ePeekRight && Unit.GetCoverType(DesiredCoverIndex)!=CT_None)
			{
				DesiredFaceLocation = Unit.Location + `XWORLD.GetPeekRightDirection(`IDX_TO_DIR(DesiredCoverIndex) , false) * 1000.0f;
			}
			// End Issue #269
			else
			{
				DesiredFaceLocation = Unit.Location + (Vector(Unit.Rotation) * 1000.0f); // Keep your current facing
			}
		}
		else
		{
			// Single line for Issue #269
			DesiredFaceLocation = bForceTurnTarget ? TempFaceLocation : UnitPawn.TargetLoc;
		}

		return DesiredFaceLocation;
	}

	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN EvaluateStance FROM"@ PreviousStateName @"************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		if (Unit.IsAlive() && UnitPawn.m_bInMatinee)
		{
			`Warn("Evaluating stance while in matinee may cause move-to-origin bugs!"$GetScriptTrace());
		}

		ReturnToState = PreviousStateName;
		StoredUpdateSkelWhenNotRendered = UnitPawn.GetUpdateSkelWhenNotRendered();
		UnitPawn.SetUpdateSkelWhenNotRendered(true);
	}

	event EndState( name NextStateName )
	{	
		`log("*********************** END EvaluateStance RETURN TO"@ NextStateName @"**********************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("     bDeferredGotoIdle: "@bDeferredGotoIdle, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("     bDeferredGotoDormant: "@bDeferredGotoDormant, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("     bForceDesiredCover: "@bForceDesiredCover, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("     bForceTurnTarget: "@bForceTurnTarget, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

		bDeferredGotoIdle = false;
		bDeferredGotoDormant = false;
		bForceDesiredCover = false;
		bForceTurnTarget = false;

		UnitPawn.SetUpdateSkelWhenNotRendered(StoredUpdateSkelWhenNotRendered);
	}

	simulated event Tick( float fDeltaT )
	{	
		if( bInLatentTurn )
		{
			UnitPawn.TargetLoc = UnitPawnNative.LatentTurnTarget;
		}

		ExitCoverAnimTimer += fDeltaT;
	}

begin:	
	if( bWaitingForStanceEval )
	{
		bWaitingForStanceEval = false;
	}

	`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	`log("Evaluating Unit States...", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

	if( bIsTurret )
	{
		if( RequiresTurretTransitionAnim(Unit.IdleTurretState) )
		{
			AnimParams.AnimName = GetTurretTransitionAnim(Unit.IdleTurretState);
			AnimParams.Looping = false;
			FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}
	}

	//If we are hunkered down, just go straight to back to idle
	`log("     Unit.IsHunkeredDown():"@Unit.IsHunkeredDown(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	if( Unit.IsHunkeredDown() )
	{
		GotoState('Idle');
	}

	//The unit has started suppressing, enter that state
	`log("     Unit.m_bSuppressing || Unit.m_bSuppressingArea :"@(Unit.m_bSuppressing || Unit.m_bSuppressingArea), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	if( Unit.m_bSuppressing || Unit.m_bSuppressingArea )
	{		
		GotoState('Fire');
	}

	`log("     Unit.IsDeadOrDying():"@(Unit.IsDeadOrDying()), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	if( Unit.IsDeadOrDying() || UnitNative.GetVisualizedGameState().IsIncapacitated() || UnitPawn.GetStateName() == 'RagDollBlend' )
	{
		`log("     Cannot manipulate animation state while dead, exiting...", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		goto('Exit');
	}

	//Units temporarily exit their cover while shooting, stance evaluations that occur when this is happening are only allowed to turn the unit
	//and even then only via bForceDesiredCover or bForceTurnTarget
	if( Unit.bSteppingOutOfCover ) 
	{
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("The unit is stepping out of cover :"@Unit.bSteppingOutOfCover, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit.CanUseCover()                :"@Unit.CanUseCover(), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		if( bForceDesiredCover || bForceTurnTarget )
		{
			// Begin Issue #269
			`log("Starting TurnTowardsPosition towards UnitPawn.TargetLoc"@UnitPawn.TargetLoc@" Rotator: "@Unit.Rotation@" Vector:"@vector(Unit.Rotation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			TurnTowardsPosition(bForceTurnTarget ? TempFaceLocation : UnitPawn.TargetLoc);//Latent turning function on XGUnit
			`log("Finished TurnTowardsPosition towards UnitPawn.TargetLoc"@UnitPawn.TargetLoc@" Rotator: "@Unit.Rotation@" Vector:"@vector(Unit.Rotation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			// End Issue #269
		}
	}
	else
	{
		//If we get here, then we just need to check whether our cover / enemies situation has changed
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Getting targeting information...", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		if( bForceDesiredCover || SetTargetUnit() )
		{	
			`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("Evaluating Cover States...", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("     bForceDesiredCover: "@bForceDesiredCover, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

			if( !bForceDesiredCover )
			{
				`log("     Calculating DesiredCoverState...", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				GetDesiredCoverState(DesiredCoverIndex, DesiredPeekSide);
			}

			`log("     DesiredCoverIndex: "@DesiredCoverIndex, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("     DesiredPeekSide: "@DesiredPeekSide, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("     CurrentCoverDirectionIndex: "@Unit.CurrentCoverDirectionIndex, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("     CurrentCoverState: "@Unit.m_eCoverState, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			
			if( (DesiredCoverIndex < 0 && Unit.m_eCoverState != eCS_None) || //The unit is getting out of cover
				(DesiredCoverIndex > -1 && Unit.m_eCoverState == eCS_None) || //The unit needs to get into cover from no cover
				(DesiredCoverIndex > -1 && DesiredCoverIndex != Unit.CurrentCoverDirectionIndex) || //The unit needs to change cover directions			
				(DesiredCoverIndex > -1 && !UnitFacingMatchesDesiredDirection()) ) //The unit thinks it is facing the right way, but really it isn't
			{	
				`log("Detected needs to change direction:", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				`log("     DesiredCoverIndex < 0                                                          :"@(DesiredCoverIndex < 0), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				`log("     DesiredCoverIndex > -1 && DesiredCoverIndex != Unit.CurrentCoverDirectionIndex :"@(DesiredCoverIndex > -1 && DesiredCoverIndex != Unit.CurrentCoverDirectionIndex), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				`log("     DesiredCoverIndex > -1 && Unit.m_eCoverState == eCS_None                       :"@(DesiredCoverIndex > -1 && Unit.m_eCoverState == eCS_None), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
				`log("     DesiredCoverIndex > -1 && !UnitFacingMatchesDesiredDirection()                 :"@(DesiredCoverIndex > -1 && !UnitFacingMatchesDesiredDirection())@"  ("@vector(Unit.Rotation)@"vs."@Unit.GetCoverDirection(DesiredCoverIndex)@")", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

				//TempFaceLocation will be the target location for our turn node animation. This will also guide which exit cover animation is used
				TempFaceLocation = GetDesiredFaceLocation();
				
				if( DesiredCoverIndex > -1 && !bForceTurnTarget ) //The unit needs to: turn, enter cover in the new direction
				{
					if (UnitNeedsToRotate(TempFaceLocation))
					{
						if (ReturnToState == 'TargetingStart' || ReturnToState == 'TargetingHold')
						{
							bWaitingForStanceEval = true;
							GotoState('TargetingStop');
						}

						if( ReturnToState == 'PeekStart' )
						{
							bWaitingForStanceEval = true;
							GotoState('PeekStop');
						}

						`log("Starting TurnTowardsPosition towards TargetLocation"@(TempFaceLocation)@" Rotator: "@Unit.Rotation@" Vector:"@vector(Unit.Rotation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
						TurnTowardsPosition(TempFaceLocation, true);//Latent turning function on XGUnit
						`log("Finished TurnTowardsPosition towards TargetLocation"@(TempFaceLocation)@" Rotator: "@Unit.Rotation@" Vector:"@vector(Unit.Rotation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
					}

					if( DesiredCoverIndex != -1 )
					{
						Unit.SetCoverDirectionIndex(DesiredCoverIndex);
					}
			
					//Enter the final cover state
					if( !UnitPawn.m_bInMatinee )
					{
						if( (bDeferredGotoDormant || ReturnToState == 'Dormant') && !`XCOMVISUALIZATIONMGR.IsActorBeingVisualized(Unit) )
						{
							PlayIdleAnim();
						}

						if( Unit.GetCoverType() == CT_Standing )
						{
							if( DesiredPeekSide == ePeekLeft )
							{
								Unit.SetUnitCoverState(eCS_HighRight);
							}
							else if( DesiredPeekSide == ePeekRight)
							{
								Unit.SetUnitCoverState(eCS_HighLeft);
							}
						}
						else if( Unit.GetCoverType() == CT_MidLevel )
						{
							if( DesiredPeekSide == ePeekLeft )
							{
								Unit.SetUnitCoverState(eCS_LowRight);
							}
							else if( DesiredPeekSide == ePeekRight)
							{
								Unit.SetUnitCoverState(eCS_LowLeft);
							}
						}
					}
				}
				else //The unit has gone from in cover, to no cover and needs to turn to face a target. 
				{
					if( ReturnToState == 'TargetingStart' || ReturnToState == 'TargetingHold' )
					{
						bWaitingForStanceEval = true;
						GotoState('TargetingStop');
					}

					if( ReturnToState == 'PeekStart' )
					{
						bWaitingForStanceEval = true;
						GotoState('PeekStop');
					}

					`log("Starting TurnTowardsPosition towards TargetLocation"@TempFaceLocation@" Rotator: "@Unit.Rotation@" Vector:"@vector(Unit.Rotation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
					TurnTowardsPosition(TempFaceLocation);//Latent turning function on XGUnit
					`log("Finished TurnTowardsPosition towards TargetLocation"@TempFaceLocation@" Rotator: "@Unit.Rotation@" Vector:"@vector(Unit.Rotation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');

					if( X2Action_ExitCover(`XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(Unit)) == None )
					{
						Unit.SetUnitCoverState(eCS_None);
					}

					// Don't play flanked during your turn
					UnitState = UnitNative.GetVisualizedGameState(VisualizedHistoryIndex);
					if( UnitState.IsFlanked(,true, VisualizedHistoryIndex) && UnitState.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID && ReturnToState != 'Dormant' )
					{
						Unit.UnitSpeak('SoldierFlanked');
						SignalAnimationName = 'HL_SignalNegative';
						SignalFaceLocation = TempFaceLocation;
						GotoState('Signal');
					}
				}				
			}
			else //If the unit did not need to change cover direction, check whether it needs to switch cover sides or turn
			{			
				if( Unit.m_eCoverState == eCS_None || bForceTurnTarget ) //The unit is not in cover, or is forcing a turn
				{
					// Begin Issue #269
					`log("Starting TurnTowardsPosition towards UnitPawn.TargetLoc"@(bForceTurnTarget ? TempFaceLocation : UnitPawn.TargetLoc)@" Rotator: "@Unit.Rotation@" Vector:"@vector(Unit.Rotation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
					TurnTowardsPosition(bForceTurnTarget ? TempFaceLocation : UnitPawn.TargetLoc, true);//Latent turning function on XGUnit
					`log("Finished TurnTowardsPosition towards UnitPawn.TargetLoc"@(bForceTurnTarget ? TempFaceLocation : UnitPawn.TargetLoc)@" Rotator: "@Unit.Rotation@" Vector:"@vector(Unit.Rotation), `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
					// End Issue #269
				}
			}
		}
		else
		{
			`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
			`log("No targets...", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		}
	}
	
Exit:
	if( bDeferredGotoIdle || bDeferredGotoDormant )
	{
		if( bDeferredGotoDormant )
		{
			bDeferredGotoDormant = false;
			GotoState('Dormant');
		}
		else if( bDeferredGotoIdle )
		{
			bDeferredGotoIdle = false;
			GotoState('Idle');
		}
	}
	else
	{
		// Returning to peek is awkward, if our peek was interupted just go to idle
		if( ReturnToState == 'PeekStart' )
		{
			GotoState('PeekStop');
		}

		GotoState(ReturnToState);
	}
}

simulated state Fire
{	
	simulated event BeginState(name PreviousStateName)
	{
		//`CONSTANTCOMBAT.iNumSuppressing += 1;
		//ResetNodes();
	}

	simulated event EndState(name NewStateName)
	{
		//`CONSTANTCOMBAT.iNumSuppressing -= 1;
		//ResetNodes();
		UnitPawn.StopSounds();
	}

	simulated event Tick(float DeltaTime)
	{
		
	}

	simulated function Name GetSuppressAnimName()
	{
		local XComWeapon Weapon;

		Weapon = XComWeapon(UnitPawn.Weapon);
		if( Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponSuppressionFireAnimSequenceName) )
		{
			return Weapon.WeaponSuppressionFireAnimSequenceName;
		}
		else if( UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponSuppressionFireAnimSequenceName) )
		{
			return class'XComWeapon'.default.WeaponSuppressionFireAnimSequenceName;
		}
	}

Begin:
	//Re-acquire the unit's target if it was lost ( for example, loading from a save )
	//if( TargetActor == none && Unit.GetNumberOfSuppressionTargets() > 0 )
	//{
	//	TargetActor = Unit.GetSuppressionTarget(0);
	//}
	XComWeapon(UnitPawn.Weapon).Spread[0] = 0.05f;

Firing:
	
	UnitPawn.TargetLoc = Unit.AdjustTargetForMiss(XGUnit(TargetActor), 3.0f);

	AnimParams = default.AnimParams;
	AnimParams.AnimName = GetSuppressAnimName();
	if( Unit.m_bSuppressing )
	{
		FinishAnim(UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	}

	AnimParams.AnimName = 'FF_FireSuppressIdle';
	AnimParams.Looping = true;
	if( Unit.m_bSuppressing )
	{
		// Start Issue #74
		// Try to find the normal out-of-cover idle anim if we can't play a suppression idle
		if (!UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName))
			AnimParams.AnimName = 'NO_IdleGunUp';

		// But only if we can play that one, if not, we'll just freeze for 1.5-3.5 seconds
		if (UnitPawnNative.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName))
		// End Issue #74
			UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams); // idle until we shoot again

		Sleep(((Rand(100) / 100.0f)*2.0f) + 1.5f); // only shoot every 1.5-3.5 seconds when supressing (an addition 0.5 after target peeks)
		goto('Firing');
	}

	GotoState('Dormant'); // We'll be in a visualizer when we decide to stop suppressing
}

state PersistentEffect
{
	event BeginState(name PreviousStateName)
	{		
		`log("*********************** BEGIN PersistentEffect ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{	
		`log("*********************** END PersistentEffect ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	function Vector GetWrathCannonTargetLoc()
	{
		local XComGameStateHistory History;
		local Vector TargetLoc;
		local int ScanHistory;
		local XComGameStateContext_TacticalGameRule GameRuleContext;
		local XComGameStateContext_Ability AbilityContext;
		local XComGameState GameState;

		History = `XCOMHISTORY;

		for( ScanHistory = History.GetCurrentHistoryIndex(); ScanHistory >= 0; --ScanHistory )
		{
			GameState = History.GetGameStateFromHistory(ScanHistory);
			GameRuleContext = XComGameStateContext_TacticalGameRule(GameState.GetContext());
			if( GameRuleContext != None && GameRuleContext.GameRuleType == eGameRule_PlayerTurnBegin
			   && GameRuleContext.PlayerRef.ObjectID == UnitState.ControllingPlayer.ObjectID )
			{
				break;
			}

			AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
			if( AbilityContext != None && AbilityContext.InputContext.AbilityTemplateName == class'X2Ability_Sectopod'.default.WrathCannonStage1AbilityName && AbilityContext.InputContext.SourceObject.ObjectID == UnitState.ObjectID )
			{
				TargetLoc = AbilityContext.InputContext.TargetLocations[0];
				break;
			}
		}

		// Update - always target the same Z level as the sectopod's head.
		TargetLoc.Z = UnitPawnNative.GetHeadLocation().Z;

		return TargetLoc;
	}

	function Rotator GetWrathCannonDesiredRotation(Vector WrathCannonTargetLoc)
	{
		local Rotator DesiredRotation;
		local Vector UnitLocation;

		UnitLocation = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);
		DesiredRotation = Rotator(WrathCannonTargetLoc - UnitLocation);
		DesiredRotation.Pitch = 0;

		return DesiredRotation;
	}

	event Tick(float DeltaTime)
	{		
	}
Begin:
	AnimParams = default.AnimParams;
	AnimParams.AnimName = PersistentEffectIdleName;
	AnimParams.Looping = true;
	UnitPawnNative.GetAnimTreeController().SetAllowNewAnimations(true);
	UnitPawnNative.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	UnitPawnNative.GetAnimTreeController().SetAllowNewAnimations(false);

	if( UnitState.GetMyTemplate().CharacterGroupName == 'Sectopod' )
	{
		TargetLocation = GetWrathCannonTargetLoc();
		UnitPawn.SetRotation(GetWrathCannonDesiredRotation(TargetLocation));
	}

	while( PersistentEffectIdleName != '' )
	{
		UnitState = UnitNative.GetVisualizedGameState();
		if( -1 != UnitState.AppliedEffectNames.Find(class'X2Ability_Sectopod'.default.WrathCannonStage1EffectName) )
		{
			UnitPawnNative.TargetLoc = TargetLocation;
		}
		Sleep(0.0f);
	}
	
	UnitPawnNative.GetAnimTreeController().SetAllowNewAnimations(true);
	GotoState('Idle');
}

static function name ChooseAnimationForCover( XGUnit kUnit, name NoCover, name LowCover, name HighCover )
{
	if (kUnit.IsInCover( ))
	{
		if (kUnit.GetCoverType( ) == CT_MidLevel)
			return LowCover;
		return HighCover;
	}
	return NoCover;
}

state TurretIdle
{
	event BeginState(name PreviousStateName)
	{
		`log("*********************** BEGIN TurretIdle ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("Unit : "@Unit, `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
		`log("", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event EndState(name NewStateName)
	{
		`log("*********************** END TurretIdle ************************************************", `CHEATMGR.MatchesXComAnimUnitName(Unit.Name), 'XCom_Anim');
	}

	event Tick(float DeltaTime)
	{
	}
Begin:

	CurrentTurretState = Unit.IdleTurretState;
	PlayIdleAnim();

	while(CurrentTurretState == Unit.IdleTurretState)
	{
		Sleep(0.1f);
	}

	GotoState('Idle');
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local string DebugString;
	local int UseCoverDirectionIndex;
	local UnitPeekSide UsePeekSide;  
	local int RequiresLean;			
	local int bCanSeeDefaultFromDefault;	
	local XGUnit ActiveUnit;	
	local bool bWillStepOut;
	local XGUnit TargetUnit;
	local XComGameState_Unit TargetUnitState;

	ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();

	if(ActiveUnit == Unit && (`CHEATMGR != None && `CHEATMGR.bDebugIdleAnimationStateMachines))
	{
		DebugString =  "===================================\n";
		DebugString $= "=======    Step Outs Debugger  ========\n";
		DebugString $= "===================================\n\n";

		TargetUnit = XGUnit(TargetActor);
		if( TargetUnit != None )
		{
			TargetUnitState = TargetUnit.GetVisualizedGameState();
		}
		bWillStepOut = Unit.GetStepOutCoverInfo(TargetUnitState, TargetLocation, UseCoverDirectionIndex, UsePeekSide, RequiresLean, bCanSeeDefaultFromDefault);
		DebugString $= "Target:  "$TargetActor$"\n";
		DebugString $= "UseCoverDirectionIndex:  "$UseCoverDirectionIndex$"\n";
		DebugString $= "UsePeekSide:  "$UsePeekSide$"\n";
		DebugString $= "RequiresLean:  "$RequiresLean$"\n";
		DebugString $= "bCanSeeDefaultFromDefault:  "$bCanSeeDefaultFromDefault$"\n";
		DebugString $= "\n\nWILL STEP OUT:  "$ (bWillStepOut ? "Yes" : "No") $"\n";
		
		// draw a background box so the text is readable
		kCanvas.SetPos(10, 150);
		kCanvas.SetDrawColor(0, 0, 0, 100);
		kCanvas.DrawRect(400, 200);

		// draw the text
		kCanvas.SetPos(10, 150);
		kCanvas.SetDrawColor(0, 255, 0);
		kCanvas.DrawText(DebugString);
	}
}


defaultproperties
{
	PeekTimeoutCurrent = 0.0f;
	bWaitingForStanceEval = false;	
	bDeferredGotoIdle = false;	
	TurningSequence = none;
	bTargeting = false;	
}
