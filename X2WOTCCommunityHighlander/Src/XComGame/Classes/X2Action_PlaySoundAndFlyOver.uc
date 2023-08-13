//------------------------------------------------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//------------------------------------------------------------------------------------------------
class X2Action_PlaySoundAndFlyOver extends X2Action;

//Configuration Variables
//************************************************************************************************
var SoundCue							TheSoundCue;
var string								FlyOverMessage;
var string								FlyOverIcon;
var EWidgetColor						MessageColor; 
var name                                CharSpeech;
var float								LookAtDuration;
var float                               DelayDuration;
var bool								BlockUntilFinished;
var X2Camera_LookAtActorTimed			LookAtActorCamera;
var ETeam                               FlyoverVisibilityTeam;
var int									MessageBehavior;
//************************************************************************************************

var vector								ActorLocation;
var StateObjectReference				ActorObjectID;

event bool BlocksAbilityActivation()
{
	return false;
}

event HandleNewUnitSelection()
{
	if( LookAtActorCamera != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtActorCamera);
		LookAtActorCamera = None;
	}
}

function bool ShouldPlayFlyover()
{
	local XComGameState_Unit UnitState;

	// unit owned by local player
	if( Unit.IsMine() )
	{
		return true;
	}

	// enemy unit concealed
	UnitState = XComGameState_Unit(Metadata.StateObject_NewState);
	if( UnitState != None && UnitState.IsConcealed() )
	{
		return false;
	}
	
	return (!class'Engine'.static.GetEngine().IsMultiPlayerGame() || //Not MP - show the sound and flyover
		!UnitPawn.bHidden);					//MP, but the unit is visible
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:

	if( ShouldPlayFlyover() )
	{
		if(TheSoundCue != None)
		{
			PlaySound(TheSoundCue, true);
		}

		if(FlyOverMessage != "")
		{
			ActorLocation = (Unit != none) ? Unit.GetLocation() : Metadata.VisualizeActor.Location;
			ActorObjectID = (X2VisualizerInterface(Metadata.VisualizeActor) != none) ? Metadata.StateObject_NewState.GetReference() : ActorObjectID;

			if(FlyoverVisibilityTeam == eTeam_None)
			{
				`PRES.QueueWorldMessage(FlyOverMessage, ActorLocation, ActorObjectID, MessageColor, MessageBehavior, , Unit.m_eTeamVisibilityFlags, , , , , FlyOverIcon, , , , , , , , true );
			}
			else
			{
				`PRES.QueueWorldMessage(FlyOverMessage, ActorLocation, ActorObjectID, MessageColor, MessageBehavior, , FlyoverVisibilityTeam, , , , , FlyOverIcon, , , , , , , , true);
			}
		}

		if(CharSpeech != '')
		{
			Unit.UnitSpeak(CharSpeech);
		}

		if( !bNewUnitSelected && LookAtDuration > 0 && !ShouldSkipCameraLookat() )
		{
			LookAtActorCamera = new class'X2Camera_LookAtActorTimed';
			LookAtActorCamera.ActorToFollow = Unit;
			LookAtActorCamera.LookAtDuration = LookAtDuration;
			LookAtActorCamera.UseTether = false;
			LookAtActorCamera.Priority = eCameraPriority_LookAt;
			LookAtActorCamera.UpdateWhenInactive = true;
			`CAMERASTACK.AddCamera(LookAtActorCamera);
			`Pres.m_kUIMouseCursor.HideMouseCursor();

			if( BlockUntilFinished )
			{
				while( LookAtActorCamera != None && !LookAtActorCamera.HasTimerExpired )
				{
					Sleep(0.0);
				}
			}
		}

		if( !bNewUnitSelected && BlockUntilFinished )
		{
			Sleep(DelayDuration * GetDelayModifier());
		}
	}

	CompleteAction();
}

function bool ShouldSkipCameraLookat()
{
	local XComGameState_Unit VisualizedGameState;
	local XComGameStateContext_Ability ChainStartContext;

	if( !ShouldAddCameras() )
	{
		return true;
	}

	// if this flyover is being played on a unit that is in a framed ability, then skip the camera.
	// they are already guaranteed to be framed on screen, and the camera constantly jumping around
	// mid ability looks really bad. This is a systemic feature, please do not hack around it
	// unless design is okay with it!
	VisualizedGameState = Unit.GetVisualizedGameState();
	ChainStartContext = XComGameStateContext_Ability(VisualizedGameState.GetParentGameState().GetContext().GetFirstStateInEventChain().GetContext());

	if(ChainStartContext != none)
	{
		return ChainStartContext.ShouldFrameAbility();
	}

	return false;
}

//------------------------------------------------------------------------------------------------
simulated function SetSoundAndFlyOverParameters(SoundCue _Cue, string _FlyOverMessage, Name nSpeech, EWidgetColor _MessageColor, optional string _FlyOverIcon = "", optional float _LookAtDuration = 0.0f, optional bool _BlockUntilFinished = false, optional ETeam _VisibleTeam = eTeam_None, optional int _MessageBehavior = 0 /*class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT*/)
{
	TheSoundCue = _Cue;
	FlyOverMessage = _FlyOverMessage;
	MessageColor = _MessageColor;
	CharSpeech = nSpeech;
	FlyOverIcon = _FlyOverIcon;
	LookAtDuration = _LookAtDuration;
	BlockUntilFinished = _BlockUntilFinished;
	FlyoverVisibilityTeam = _VisibleTeam;
	MessageBehavior = _MessageBehavior;
}

defaultproperties
{
	LookAtDuration = 0.0f
	DelayDuration = 0.0f
	FlyoverVisibilityTeam = eTeam_None
}