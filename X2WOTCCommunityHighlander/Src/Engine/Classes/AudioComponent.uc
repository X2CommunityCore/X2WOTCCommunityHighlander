/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class AudioComponent extends ActorComponent
	native
	noexport
	collapsecategories
	hidecategories(Object,ActorComponent)
	dependson(ReverbVolume)
	editinlinenew;

var()					SoundCue			SoundCue;
var		native const	SoundNode			CueFirstNode; // This is just a pointer to the root node in SoundCue.

/**
 *	Struct used for storing one per-instance named paramter for this AudioComponent.
 *	Certain nodes in the SoundCue may reference parameters by name so they can be adjusted per-instance.
 */
struct native AudioComponentParam
{
	var()	name		ParamName;
	var()	float		FloatParam;
	var() SoundNodeWave WaveParam;
};

/** Array of per-instance parameters for this AudioComponent. */
var()	editinline array<AudioComponentParam>		InstanceParameters;

/** Spatialise to the owner's coordinates */
var						bool				bUseOwnerLocation;
/** Auto start this component on creation */
var						bool				bAutoPlay;
/** Auto destroy this component on completion */
var						bool				bAutoDestroy;
/** Stop sound when owner is destroyed */
var						bool				bStopWhenOwnerDestroyed;
/** Whether the wave instances should remain active if they're dropped by the prioritization code. Useful for e.g. vehicle sounds that shouldn't cut out. */
var						bool				bShouldRemainActiveIfDropped;
/** whether we were occluded the last time we checked */
var						bool				bWasOccluded;
/** If true, subtitles in the sound data will be ignored. */
var		transient		bool				bSuppressSubtitles;
/** Set to true when the component has resources that need cleanup */
var		transient		bool				bWasPlaying;
/** Is this audio component allowed to be spatialized? */
var						bool				bAllowSpatialization;
/** Whether the current component has finished playing */
var		transient		bool				bFinished;
/** If TRUE, this sound will not be stopped when flushing the audio device. */
var		transient		bool				bApplyRadioFilter;	
/** If TRUE, the decision on whether to apply the radio filter has been made. */
var		transient		bool				bRadioFilterSelected;

/** Whether this audio component is previewing a sound */
var		transient		bool				bPreviewComponent;
/** If TRUE, this sound will not be stopped when flushing the audio device. */
var		transient		bool				bIgnoreForFlushing;

/**
 * Properties of the audio component set by its owning sound class
 */

/** The amount of stereo sounds to bleed to the rear speakers */
var		transient		float				StereoBleed;
/** The amount of a sound to bleed to the LFE channel */
var		transient		float				LFEBleed;

/** Whether audio effects are applied */
var		transient		bool				bEQFilterApplied;
/** Whether to artificially prioritise the component to play */
var		transient		bool				bAlwaysPlay;
/** Whether or not this sound plays when the game is paused in the UI */
var		transient		bool				bIsUISound;
/** Whether or not this audio component is a music clip */
var		transient		bool				bIsMusic;
/** Whether or not the audio component should be excluded from reverb EQ processing */
var		transient		bool				bReverb;
/** Whether or not this sound class forces sounds to the center channel */
var		transient		bool				bCenterChannelOnly;
// FIRAXIS Begin
var     transient       bool                bToggleDontStartNewWaveAfterStart;
var     transient       bool                bDontStartNewWave;
var     transient       bool                bAllowCleanup;  // This is a hack to make sure that the audio component and wavs do not clean up for tentpoles until we are done. - Ryan Baker
var     native const    bool                bDurationIsSet; // An internal latch, for use in native code only.
var     transient       float               fDuration;  // Duration this audio component will play, in seconds. This is set via callback, once the sound system knows the correct value.
// FIRAXIS End

var	duplicatetransient native const	array<pointer>		WaveInstances{struct FWaveInstance};
var	duplicatetransient native const	array<byte>			SoundNodeData;

var	duplicatetransient native AkEvent					PlayingAkEvent;
var duplicatetransient native int						PlayingAkId;


/**
 * We explicitly disregard SoundNodeOffsetMap/WaveMap/ResetWaveMap for GC as all references are already
 * handled elsewhere and we can't NULL references anyways.
 */
var	duplicatetransient native const	Map{USoundNode*,UINT} SoundNodeOffsetMap;
var	duplicatetransient native const	multimap_mirror		SoundNodeResetWaveMap{TMultiMap<USoundNode*,FWaveInstance*>};

var duplicatetransient native const	pointer				Listener{struct FListener};

var	duplicatetransient native /*const*/	float			PlaybackTime; // FIRAXIS
var	duplicatetransient native		vector				Location;
var	duplicatetransient native const	vector				ComponentLocation;

/** Remember the last owner so we can remove it from the actor's component array even if it's already been detached */
var 	transient const	Actor							LastOwner;

/** Used by the subtitle manager to prioritize subtitles wave instances spawned by this component. */
var		native			float				SubtitlePriority;

var						float				FadeInStartTime;
var						float				FadeInStopTime;
/** This is the volume level we are fading to **/
var						float				FadeInTargetVolume;

var						float				FadeOutStartTime;
var						float				FadeOutStopTime;
/** This is the volume level we are fading to **/
var						float				FadeOutTargetVolume;

var						float				AdjustVolumeStartTime;
var						float				AdjustVolumeStopTime;
/** This is the volume level we are adjusting to **/
var						float				AdjustVolumeTargetVolume;
var						float				CurrAdjustVolumeTargetVolume;

// Temporary variables for node traversal.
var		native const	SoundNode			CurrentNotifyBufferFinishedHook;
var		native const	vector				CurrentLocation;
var		native const	float				CurrentVolume;
var		native const	float				CurrentPitch;
var		native const	float				CurrentHighFrequencyGain;
var		native const	int					CurrentUseSpatialization;
var		native const	int					CurrentNotifyOnLoop;

// Multipliers used before propagation to WaveInstance
var		native const	float				CurrentVolumeMultiplier;
var		native const	float				CurrentPitchMultiplier;
var		native const	float				CurrentHighFrequencyGainMultiplier;

var		native const	float				CurrentVoiceCenterChannelVolume;
var		native const	float				CurrentRadioFilterVolume;
var		native const	float				CurrentRadioFilterVolumeThreshold;

// To remember where the volumes are interpolating to and from
var		native const	double				LastUpdateTime;
var		native const	float				SourceInteriorVolume;
var		native const	float				SourceInteriorLPF;
var		native const	float				CurrentInteriorVolume;
var		native const	float				CurrentInteriorLPF;

/** location last time playback was updated */
var transient const vector LastLocation;

/** cache what volume settings we had last time so we don't have to search again if we didn't move */
var native const InteriorSettings LastInteriorSettings;
var native const int LastReverbVolumeIndex;

// Serialized multipliers used to e.g. override volume for ambient sound actors.
var()					float				VolumeMultiplier;
var()					float				PitchMultiplier;
var()					float				HighFrequencyGainMultiplier;

/** while playing, this component will check for occlusion from its closest listener every this many seconds and call OcclusionChanged() if the status changes */
var						float				OcclusionCheckInterval;
/** last time we checked for occlusion */
var		transient		float				LastOcclusionCheckTime;

var		const			DrawSoundRadiusComponent PreviewSoundRadius;

native final function Play();
native final function Stop();

/** @return TRUE if this component is currently playing a SoundCue. */
native final function bool IsPlaying();

/** @return TRUE if this component is currently fading in. */
native final function bool IsFadingIn();

/** @return TRUE if this component is currently fading out. */
native final function bool IsFadingOut();

/**
 * This is called in place of "play".  So you will say AudioComponent->FadeIn().
 * This is useful for fading in music or some constant playing sound.
 *
 * If FadeTime is 0.0, this is the same as calling Play() but just modifying the volume by
 * FadeVolumeLevel. (e.g. you will play instantly but the FadeVolumeLevel will affect the AudioComponent)
 *
 * If FadeTime is > 0.0, this will call Play(), and then increase the volume level of this
 * AudioCompoenent to the passed in FadeVolumeLevel over FadeInTime seconds.
 *
 * The VolumeLevel is MODIFYING the AudioComponent's "base" volume.  (e.g.  if you have an
 * AudioComponent that is volume 1000 and you pass in .5 as your VolumeLevel then you will fade to 500 )
 *
 * @param FadeInDuration how long it should take to reach the FadeVolumeLevel
 * @param FadeVolumeLevel the percentage of the AudioComponents's calculated volume in which to fade to
 **/
native final function FadeIn( FLOAT FadeInDuration, FLOAT FadeVolumeLevel );

/**
 * This is called in place of "stop".  So you will say AudioComponent->FadeOut().
 * This is useful for fading out music or some constant playing sound.
 *
 * If FadeTime is 0.0, this is the same as calling Stop().
 *
 * If FadeTime is > 0.0, this will decrease the volume level of this
 * AudioCompoenent to the passed in FadeVolumeLevel over FadeInTime seconds.
 *
 * The VolumeLevel is MODIFYING the AudioComponent's "base" volume.  (e.g.  if you have an
 * AudioComponent that is volume 1000 and you pass in .5 as your VolumeLevel then you will fade to 500 )
 *
 * @param FadeOutDuration how long it should take to reach the FadeVolumeLevel
 * @param FadeVolumeLevel the percentage of the AudioComponents's calculated volume in which to fade to
 **/
native final function FadeOut( FLOAT FadeOutDuration, FLOAT FadeVolumeLevel );

/**
 * This will allow one to adjust the volume of an AudioComponent on the fly
 **/
native final function AdjustVolume( FLOAT AdjustVolumeDuration, FLOAT AdjustVolumeLevel );

native final function SetFloatParameter(name InName, float InFloat);

native final function SetWaveParameter(name InName, SoundNodeWave InWave);

/** stops the audio (if playing), detaches the component, and resets the component's properties to the values of its template */
native final function ResetToDefaults();

/** called when we finish playing audio, either because it played to completion or because a Stop() call turned it off early */
delegate OnAudioFinished(AudioComponent AC);

/** Called when subtitles are sent to the SubtitleManager.  Set this delegate if you want to hijack the subtitles for other purposes */
delegate OnQueueSubtitles(array<SubtitleCue> Subtitles, float CueDuration);

/** assign this delegate to get a notification when this AudioComponent knows its duration */
delegate OnAudioDurationSet(AudioComponent AC, float fSeconds);

/** assign this delegate to get a notification when this AudioComponent knows has failed to play a wise event */
delegate OnAudioFailedToPlay(AudioComponent AC);

/** called when OcclusionCheckInterval > 0.0 and the occlusion status changes */
event OcclusionChanged(bool bNowOccluded)
{
	VolumeMultiplier *= bNowOccluded ? 0.5 : 2.0;
}

/** called from native code when Wwise knows the duration of the currently playing event */
event AkCallbackSetDuration(float fSeconds)
{
	if (OnAudioDurationSet != none)
	{
		OnAudioDurationSet(self, fSeconds);
	}
}

/** called from native code when Wwise has failed to play an event */
event AkCallbackSetFailedToPlay()
{
	if (OnAudioFailedToPlay != none)
	{
		OnAudioFailedToPlay(self);
	}
}

defaultproperties
{
	bUseOwnerLocation=true
	bAutoDestroy=false
	bAutoPlay=false
	bAllowSpatialization=true
	bAllowCleanup=true

	VolumeMultiplier=1.0
	PitchMultiplier=1.0
	HighFrequencyGainMultiplier=1.0

	FadeInStopTime=-1.0f
	FadeOutStopTime=-1.0f
	AdjustVolumeStopTime=-1.0f

	FadeInTargetVolume=1.0f
	FadeOutTargetVolume=1.0f
	AdjustVolumeTargetVolume=1.0f
	CurrAdjustVolumeTargetVolume=1.0f

	LastLocation=(X=1.0,Y=2.0,Z=3.0) // so spawning at origin doesn't use cached values
	PlayingAkId=-1
}
